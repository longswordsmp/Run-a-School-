-- ServerScriptService.Server.StealService
-- Stealing, the heart of a Steal-a-X game:
--   hold the Steal prompt on someone else's seated student -> you carry them over your head,
--   slower; get them inside your own lot and they enrol at a free desk of yours.
--   Anyone who bonks you with a Ruler makes you drop them and they run back to their desk.
--   Carrying too long, dying, or leaving also sends them back. The owner's Alarm Bell rings the
--   server and outlines the thief.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local Factory = require(script.Parent.StudentFactory)
local UpgradeService = require(script.Parent.UpgradeService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)

local StealService = {}
local carrying = {} -- [thief] = { owner, plot, slot, entry, def, model, started, highlight }
local stunned = {} -- [player] = until (os.clock)
local CARRY_LIMIT = 90
local BASE_SPEED = 16

function StealService.isCarrying(player)
	return carrying[player] ~= nil
end

local function humanoid(player)
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid"), char and char:FindFirstChild("HumanoidRootPart")
end

-- every speed goes through here: stunned, carrying, the Factory carry, walking; then sprint or
-- sneak on top (MoveService)
local function setSpeed(player)
	local hum = humanoid(player)
	if not hum then return end
	if (stunned[player] and stunned[player] > os.clock()) or player:GetAttribute("Stunned") then
		hum.WalkSpeed = 0
		return
	end
	local c = carrying[player]
	local speed
	if c then
		local p = Data.get(player)
		speed = Config.CarrySpeed * (p and UpgradeService.carrySpeedMult(p) or 1)
	elseif player:GetAttribute("Heist") then
		speed = Config.Heist.carrySpeed -- carrying a kid out of the Factory
	else
		speed = BASE_SPEED
	end
	hum.WalkSpeed = speed * require(script.Parent.MoveService).mult(player)
end

-- put the carried student over the thief's head
local function carryModel(thief, def, grade)
	local _, root = humanoid(thief)
	if not root then return nil end
	local model = Factory.build(def, grade)
	model.Name = "Carried"
	Factory.setMode(model, "carried")
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.Massless = true
			p.CanCollide = false
			p.CanQuery = false
		end
	end
	local hrp = model.PrimaryPart
	local offset = 2.4 + Factory.standOffset(model) * 0.9
	hrp.CFrame = root.CFrame * CFrame.new(0, offset, 0)
	local w = Instance.new("Weld")
	w.Part0 = root
	w.Part1 = hrp
	w.C0 = CFrame.new(0, offset, 0) * CFrame.Angles(0, math.rad(8), math.rad(6))
	w.Parent = hrp
	model.Parent = thief.Character
	Factory.play(model, "sit")
	return model
end

local function cleanup(thief, c)
	carrying[thief] = nil
	if c.model then c.model:Destroy() end
	if c.highlight then c.highlight:Destroy() end
	thief:SetAttribute("Carrying", nil)
	setSpeed(thief)
end

-- the student goes back to their own desk
function StealService.drop(thief, why)
	local c = carrying[thief]
	if not c then return end
	cleanup(thief, c)
	local owner = c.owner
	if owner.Parent and c.entry and Data.get(owner) and Data.get(owner).students[c.slot] == c.entry then
		c.entry.carried = nil
		PlotService.place(owner, c.slot)
		PlotService.updateIncome(owner)
		Remotes.Notify:FireClient(owner, c.def.name .. " made it back to your school!", "good")
	end
	if thief.Parent then
		Remotes.Notify:FireClient(thief, why or ("You dropped " .. c.def.name .. "!"), "bad")
		Remotes.Sfx:FireClient(thief, "RecordScratch")
	end
	Signals.fire("stealFailed", thief, owner, c.def)
end

local function complete(thief)
	local c = carrying[thief]
	if not c then return end
	local owner = c.owner
	local tp = Data.get(thief)
	local op = Data.get(owner)
	if not tp or not op or op.students[c.slot] ~= c.entry then
		StealService.drop(thief, "They slipped away!")
		return
	end
	local slot = PlotService.freeSlot(thief)
	if not slot then
		StealService.drop(thief, "Your school is full! They ran home.")
		return
	end
	cleanup(thief, c)
	-- move the entry from the owner's school to the thief's
	c.entry.carried = nil
	PlotService.remove(owner, c.slot)
	tp.students[slot] = { id = c.entry.id, grade = c.entry.grade, stored = 0 }
	local key = c.entry.id .. "|" .. c.entry.grade
	local firstTime = not tp.index[key]
	tp.index[key] = true
	tp.stats.stolen += 1
	op.stats.lost += 1
	local seatedModel = PlotService.place(thief, slot)
	PlotService.updateIncome(thief)
	if seatedModel then Factory.emote(seatedModel, "cheer") end
	Remotes.Notify:FireClient(thief, "You stole " .. c.def.name .. "!", "good")
	Remotes.Sfx:FireClient(thief, "Cheer")
	Remotes.Notify:FireClient(owner, thief.DisplayName .. " stole your " .. c.def.name .. "!", "bad")
	Remotes.Sfx:FireClient(owner, "Doom")
	local rarity = Config.RarityById[c.def.rarity]
	if rarity.order >= 5 then
		Remotes.Announce:FireAllClients(("%s STOLE A %s FROM %s!"):format(thief.DisplayName:upper(), rarity.id:upper(), owner.DisplayName:upper()), Config.rarityAccent(c.def.rarity))
	end
	Signals.fire("stole", thief, owner, c.def, firstTime)
end

-- other systems that react to a Ruler swing (dealers): fn(player, root) -> nothing
StealService.swingHooks = {}

-- Studio tests have one player: this lets them steal from their own desk
StealService.debugAllowSelf = false

function StealService.begin(thief, plot, slot)
	local owner = PlotService.ownerOf(plot)
	if not owner or (owner == thief and not StealService.debugAllowSelf) then return end
	if carrying[thief] then
		Remotes.Notify:FireClient(thief, "You're already carrying someone!", "bad")
		return
	end
	if stunned[thief] and stunned[thief] > os.clock() then return end
	if (plot:GetAttribute("LockedUntil") or 0) > workspace:GetServerTimeNow() then
		Remotes.Notify:FireClient(thief, "That school is locked!", "bad")
		return
	end
	local op, tp = Data.get(owner), Data.get(thief)
	local e = op and op.students[slot]
	if not e or e.arriving or e.carried or e.away or not tp then return end
	if not PlotService.freeSlot(thief) then
		Remotes.Notify:FireClient(thief, "Your school is full! Sell a student first.", "bad")
		Remotes.Sfx:FireClient(thief, "Error")
		return
	end
	local def = Config.StudentById[e.id]
	e.carried = true
	e.cheating = nil
	PlotService.detachModel(plot, slot)
	PlotService.updatePad(plot, slot, e.stored or 0)
	PlotService.updateIncome(owner)
	local model = carryModel(thief, def, e.grade)
	local _, root0 = humanoid(thief)
	local c = { owner = owner, plot = plot, slot = slot, entry = e, def = def, model = model, started = os.clock(), lastPos = root0 and root0.Position, lastAt = os.clock() }
	carrying[thief] = c
	thief:SetAttribute("Carrying", def.id)
	setSpeed(thief)
	Remotes.Notify:FireClient(thief, "Run it back to your school!", "steal")
	Remotes.Sfx:FireClient(thief, "Whoosh")
	Remotes.Notify:FireClient(owner, "\u{26A0}\u{FE0F} " .. thief.DisplayName .. " is stealing your " .. def.name .. "! Bonk them with your Ruler!", "bad")
	Remotes.Sfx:FireClient(owner, "Alarm")
	-- Alarm Bell upgrade: the whole server hears it and the thief glows
	if UpgradeService.level(op, "Alarm") > 0 and thief.Character then
		local h = Instance.new("Highlight")
		h.FillColor = Color3.fromRGB(255, 60, 60)
		h.OutlineColor = Color3.fromRGB(255, 255, 255)
		h.FillTransparency = 0.6
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = thief.Character
		c.highlight = h
		Remotes.Sfx:FireAllClients("Siren")
		Remotes.Notify:FireAllClients(("ALARM! %s is stealing from %s!"):format(thief.DisplayName, owner.DisplayName), "steal")
		owner:SetAttribute("AlarmUntil", workspace:GetServerTimeNow() + 12)
	end
	Signals.fire("stealStart", thief, owner, def)
end

---------------------------------------------------------------------------
-- the Ruler
---------------------------------------------------------------------------
local function makeRuler()
	local tool = Instance.new("Tool")
	tool.Name = "Ruler"
	tool.ToolTip = "Bonk thieves (and friends)"
	tool.CanBeDropped = false
	tool.Grip = CFrame.new(0, -1.2, 0) * CFrame.Angles(0, math.rad(90), 0)
	local h = Instance.new("Part")
	h.Name = "Handle"
	h.Size = Vector3.new(0.18, 3.6, 0.6)
	h.Color = Color3.fromRGB(245, 205, 90)
	h.Material = Enum.Material.Wood
	h.CanCollide = false
	h.Massless = true
	h.Parent = tool
	-- inch marks along one face
	for i = 0, 11 do
		local m = Instance.new("Part")
		m.Name = "Mark"
		m.Size = Vector3.new(0.02, 0.04, (i % 4 == 0) and 0.3 or 0.18)
		m.Color = Color3.fromRGB(60, 40, 20)
		m.CanCollide = false
		m.Massless = true
		m.CFrame = h.CFrame * CFrame.new(0.1, -1.6 + i * 0.29, 0.3 - m.Size.Z / 2)
		local w = Instance.new("WeldConstraint")
		w.Part0 = h
		w.Part1 = m
		w.Parent = m
		m.Parent = tool
	end
	return tool
end

-- other systems that change a player's speed (the Factory heist) put it back through this
StealService.setSpeed = setSpeed

local lastSwing = {}
local function swing(player, tool)
	local now = os.clock()
	if lastSwing[player] and now - lastSwing[player] < 0.7 then return end
	lastSwing[player] = now
	if stunned[player] and stunned[player] > now then return end
	-- the default R15 Animate script plays its slash when the tool gets this value
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool
	game:GetService("Debris"):AddItem(anim, 1)
	local _, root = humanoid(player)
	if not root then return end
	Remotes.Sfx:FireAllClients("Swing", root.Position)
	for _, hook in StealService.swingHooks do
		task.spawn(hook, player, root)
	end
	-- whoever is in front and close gets bonked
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local hum, oroot = humanoid(other)
			if hum and oroot and hum.Health > 0 then
				local d = oroot.Position - root.Position
				local flat = Vector3.new(d.X, 0, d.Z)
				if flat.Magnitude < 8 and math.abs(d.Y) < 6 and (flat.Magnitude < 2 or flat.Unit:Dot(Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit) > 0.35) then
					stunned[other] = now + 1.2
					setSpeed(other)
					oroot.AssemblyLinearVelocity = flat.Unit * 40 + Vector3.new(0, 25, 0)
					Remotes.Sfx:FireAllClients("Bonk", oroot.Position)
					if carrying[other] then
						local c = carrying[other]
						StealService.drop(other, player.DisplayName .. " bonked you! " .. c.def.name .. " ran home.")
						Remotes.Notify:FireClient(player, "You saved " .. c.def.name .. "!", "good")
						Signals.fire("bonkSave", player, other, c.def, c.owner)
					end
					task.delay(1.25, function()
						if other.Parent then setSpeed(other) end
					end)
				end
			end
		end
	end
end

local function giveRuler(player)
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack or backpack:FindFirstChild("Ruler") then return end
	local tool = makeRuler()
	tool.Activated:Connect(function()
		swing(player, tool)
	end)
	tool.Parent = backpack
end

---------------------------------------------------------------------------
function StealService.start()
	PlotService.onSteal = StealService.begin

	local function onPlayer(player)
		player.CharacterAdded:Connect(function(char)
			if carrying[player] then StealService.drop(player, "You fell over! They ran home.") end
			giveRuler(player)
			local hum = char:WaitForChild("Humanoid", 10)
			if hum then
				hum.Died:Connect(function()
					if carrying[player] then StealService.drop(player, "You fainted! They ran home.") end
				end)
			end
			setSpeed(player)
		end)
		if player.Character then giveRuler(player) end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end

	Players.PlayerRemoving:Connect(function(player)
		if carrying[player] then StealService.drop(player) end
		-- an owner leaving takes their students home with them
		for thief, c in carrying do
			if c.owner == player then
				cleanup(thief, c)
				Remotes.Notify:FireClient(thief, "Their school closed, " .. c.def.name .. " went home.", "bad")
			end
		end
		stunned[player] = nil
		lastSwing[player] = nil
	end)

	-- carrying: home yet? too long?
	task.spawn(function()
		while true do
			task.wait(0.2)
			for thief, c in carrying do
				local _, root = humanoid(thief)
				local home = PlotService.getPlot(thief)
				-- nobody carries a kid faster than they can run (catches teleports home)
				if root and c.lastPos then
					local tp = Data.get(thief)
					local dt = math.max(0.05, os.clock() - (c.lastAt or os.clock()))
					local maxStep = Config.CarrySpeed * (tp and UpgradeService.carrySpeedMult(tp) or 1) * dt * 1.3 + 1.5
					local flat = (root.Position - c.lastPos) * Vector3.new(1, 0, 1)
					if flat.Magnitude > maxStep then
						-- two in a row (one can be a replication hiccup); either way this tick is not accepted:
						-- the position isn't taken and the delivery isn't checked, so a real teleport fails again next tick
						c.strikes = (c.strikes or 0) + 1
						if c.strikes >= 2 then
							StealService.drop(thief, "Whoa, too fast! They ran home.")
						end
						continue
					else
						c.strikes = 0
					end
				end
				if root then
					c.lastPos = root.Position
					c.lastAt = os.clock()
				end
				-- the owner's Jawbreaker Trap: leaving their gate with their kid trips you
				local op = root and Data.get(c.owner)
				local nowInside = root and PlotService.inside(c.plot, root.Position)
				local leaving = c.wasInside and not nowInside
				c.wasInside = nowInside
				if op and (op.traps or 0) > 0 and leaving then
					op.traps -= 1
					c.owner:SetAttribute("Traps", op.traps)
					Remotes.Sfx:FireAllClients("GavelBig", root.Position)
					Remotes.Notify:FireClient(c.owner, ("Your Jawbreaker Trap tripped %s! (%d left)"):format(thief.DisplayName, op.traps), "good")
					StealService.drop(thief, "You slipped on a JAWBREAKER! They ran home.")
					stunned[thief] = os.clock() + 1.5
					setSpeed(thief)
					task.delay(1.6, function() if thief.Parent then setSpeed(thief) end end)
					continue
				end
				if not root or not home then
					StealService.drop(thief)
				elseif PlotService.inside(home, root.Position) then
					complete(thief)
				elseif os.clock() - c.started > CARRY_LIMIT then
					StealService.drop(thief, c.def.name .. " got tired and walked home.")
				end
			end
		end
	end)
end

return StealService
