-- ServerScriptService.Server.LetterService
-- Guarantees that belong to you:
--   Admissions Letters: a Rare letter fills every 6 min of play, Epic every 30, Legendary every 90,
--     Mythic every 5 h, Prodigy every 20 h (a quarter speed while offline, up to 12 h counted).
--     A READY letter waits until you CALL it; the kid walks to your Waiting Bench and waits 10 min,
--     reserved for you (you pay the list price to enroll them; your very first Rare is free).
--   Pocket Money Promise: at Kindergarten and Elementary, if nothing on the carpet is affordable, the
--     next kid off the bus is the best Common/Uncommon you can afford.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local HallService = require(script.Parent.HallService)
local Factory = require(script.Parent.StudentFactory)
local Walkers = require(script.Parent.Walkers)
local Remotes = require(script.Parent.Remotes)
local Actions = require(script.Parent.Actions)
local Signals = require(script.Parent.Signals)

local LetterService = {}

LetterService.Letters = {
	{ rarity = "Rare", every = 360, first = 240 },
	{ rarity = "Epic", every = 1800 },
	{ rarity = "Legendary", every = 5400 },
	{ rarity = "Mythic", every = 18000 },
	{ rarity = "Prodigy", every = 72000 },
}
local OFFLINE_RATE, OFFLINE_CAP = 0.25, 12 * 3600
local BENCH_HOLD = 600

local seen = {} -- players whose offline filling has been applied this session
local lastMove = {} -- [player] = os.clock()
local lastPos = {}
local benches = {} -- [player] = { [seat] = model }

local function cheapest(rarity)
	local best
	for _, s in Config.Students do
		if s.rarity == rarity and (not best or s.price < best.price) then best = s end
	end
	return best
end

local function letters(p)
	p.letters = p.letters or {}
	for _, L in LetterService.Letters do
		if p.letters[L.rarity] == nil then p.letters[L.rarity] = L.first or L.every end
	end
	return p.letters
end

local function sync(player, p)
	for r, t in letters(p) do
		player:SetAttribute("Letter_" .. r, math.max(0, math.floor(t)))
	end
end

-- a kid of that rarity you can afford (the Board's next pick counts three times)
local function pick(p, rarity, free)
	local needs = Config.Tiers[p.tier + 1] and Config.Tiers[p.tier + 1].needs
	local pool = {}
	for _, s in Config.Students do
		if s.rarity == rarity and (free or s.price <= p.cash) then
			table.insert(pool, { s = s, w = s.id == needs and 3 or 1 })
		end
	end
	if #pool == 0 then return nil end
	local total = 0
	for _, x in pool do total += x.w end
	local r = math.random() * total
	for _, x in pool do
		r -= x.w
		if r <= 0 then return x.s end
	end
	return pool[#pool].s
end

local function benchSpot(plot, seat)
	local school = plot:FindFirstChild("School")
	local wb = school and school:FindFirstChild("Yard") and school.Yard:FindFirstChild("WaitingBench")
	if not wb then return nil end
	for _, c in wb:GetChildren() do
		if c.Name == "BenchSpot" and c:GetAttribute("Seat") == seat then return c end
	end
	return nil
end

local function freeSeat(player)
	benches[player] = benches[player] or {}
	for seat = 1, 3 do
		local m = benches[player][seat]
		if not m or not m.Parent or m:GetAttribute("State") ~= "Hall" then
			benches[player][seat] = nil
			return seat
		end
	end
	return nil
end

-- let a bench kid give up and wander onto the carpet like any other kid
local function release(player, model)
	if not model.Parent or model:GetAttribute("State") ~= "Hall" then return end
	model:SetAttribute("ReservedFor", nil)
	model:SetAttribute("OwnerId", nil)
	model:SetAttribute("OnBench", nil)
	local plot = PlotService.getPlot(player)
	local def = Config.StudentById[model:GetAttribute("StudentId")]
	if player.Parent then
		Remotes.Notify:FireClient(player, def.name .. " got tired of waiting!", "bad")
	end
	local so = Factory.standOffset(model)
	local pts = {}
	if plot then
		for _, w in PlotService.worldPoints(plot, { Vector3.new(-12.5, 0.5, 64), Vector3.new(0, 0.5, 66), Vector3.new(0, 0.5, 72) }, so) do table.insert(pts, w) end
		table.insert(pts, Vector3.new(plot.Entry.Position.X, 0.65 + so, plot.Entry.Position.Z))
	end
	local finish = workspace.Map.HallPath.End.Position
	table.insert(pts, Vector3.new(pts[#pts] and pts[#pts].X or finish.X, 0.65 + so, 0))
	table.insert(pts, Vector3.new(finish.X, 0.65 + so, 0))
	Factory.play(model, "walk")
	Walkers.walk(model, pts, Config.WalkSpeed, function() model:Destroy() end, { flat = false })
end

-- deliver a reserved kid to the owner's Waiting Bench
function LetterService.deliver(player, def, free, gradeOverride)
	local plot = PlotService.getPlot(player)
	if not plot then return nil end
	local seat = freeSeat(player)
	if not seat then
		-- the oldest kid on the bench gives up their seat
		local oldest, oldestT
		for s, m in benches[player] do
			local t = m:GetAttribute("BenchSince") or 0
			-- free kids (scholarship, daily reward) are never the ones sent away
			if not m:GetAttribute("Free") and (not oldest or t < oldestT) then oldest, oldestT = s, t end
		end
		if not oldest then return nil end
		release(player, benches[player][oldest])
		benches[player][oldest] = nil
		seat = oldest
	end
	local _, grade = HallService.roll(nil, def.id)
	grade = gradeOverride or grade
	local model = Factory.build(def, grade)
	model:SetAttribute("State", "Hall")
	model:SetAttribute("ReservedFor", player.UserId)
	model:SetAttribute("OwnerId", player.UserId) -- the client shows owner-only prompts from this
	model:SetAttribute("OnBench", true)
	model:SetAttribute("BenchSince", os.clock())
	if free then model:SetAttribute("Free", true) end
	Factory.setMode(model, "walking", player.DisplayName)
	local bb = model.Head:FindFirstChild("Tag")
	local price = bb and bb:FindFirstChild("Price")
	if price then
		price.Text = free and "FREE! (Scholarship)" or ("RESERVED \u{2022} " .. Config.formatCash(def.price))
		price.TextColor3 = free and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(255, 220, 90)
	end
	local so = Factory.standOffset(model)
	local spot = benchSpot(plot, seat)
	local entry = plot.Entry.Position
	local pts = { Vector3.new(entry.X, 0.65 + so, entry.Z) }
	for _, w in PlotService.worldPoints(plot, { Vector3.new(0, 0.5, 70), Vector3.new(0, 0.5, 62), Vector3.new(-12.5, 0.5, spot and plot.Origin.CFrame:PointToObjectSpace(spot.Position).Z or 56) }, so) do
		table.insert(pts, w)
	end
	model.PrimaryPart.CFrame = CFrame.new(pts[1] + Vector3.new(0, 0, 0))
	model.Parent = workspace:FindFirstChild("Hall")
	benches[player][seat] = model
	Factory.play(model, "walk")

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EnrollPrompt"
	prompt.ActionText = free and "Enroll FREE" or ("Enroll " .. Config.formatCash(def.price))
	prompt.ObjectText = def.name .. " (reserved for you)"
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt:SetAttribute("OwnerOnly", true)
	prompt:SetAttribute("Color", Config.rarityAccent(def.rarity))
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(who)
		if who == player then HallService.enroll(player, model) end
	end)

	Walkers.walk(model, pts, 12, function()
		if not model.Parent or model:GetAttribute("State") ~= "Hall" then return end
		if spot then
			local hrp = model.PrimaryPart
			local seatTop = spot.Position.Y - 0.25
			local y = seatTop + hrp.Size.Y * 0.5 + model:FindFirstChildOfClass("Humanoid").HipHeight * 0.1
			hrp.CFrame = CFrame.new(spot.Position.X, y, spot.Position.Z) * spot.CFrame.Rotation
		end
		Factory.play(model, "sit")
		Factory.emote(model, "wave")
		-- a gift (scholarship, daily Epic, Tiny Vex) waits until it's enrolled
		if not model:GetAttribute("Free") then
			task.delay(BENCH_HOLD, function() release(player, model) end)
		end
	end, { flat = false })
	return model
end

-- a ready letter sends its kid to the Waiting Bench. quiet: the automatic delivery, which says
-- nothing when it can't happen yet (no free desk, can't afford one) and just tries again later
local function callLetter(player, p, rarity, quiet)
	local L
	for _, x in LetterService.Letters do
		if x.rarity == rarity then L = x end
	end
	if not L then return { ok = false, err = "Unknown letter" } end
	local left = letters(p)[rarity]
	if left > 0 then return { ok = false, err = "Not ready yet" } end
	if not PlotService.freeSlot(player) then
		if not quiet then Remotes.Notify:FireClient(player, "Your school is full! Sell a kid or add desks.", "bad") end
		return { ok = false, err = "School is full" }
	end
	local free = rarity == "Rare" and not p.scholarshipUsed
	local def = pick(p, rarity, free)
	if not def then
		local c = cheapest(rarity)
		local err = ("Cheapest %s: %s. You have %s. Save up!"):format(rarity, Config.formatCash(c.price), Config.formatCash(p.cash))
		if not quiet then Remotes.Notify:FireClient(player, err, "bad") end
		return { ok = false, err = err }
	end
	if free then p.scholarshipUsed = true end
	-- a banked letter keeps this one ready
	local credits = p.letterCredits and p.letterCredits[rarity] or 0
	if credits > 0 then
		p.letterCredits[rarity] = credits - 1
	else
		p.letters[rarity] = L.every
	end
	sync(player, p)
	LetterService.deliver(player, def, free)
	Remotes.Notify:FireClient(player, free and ("\u{2709}\u{FE0F} A Scholarship student is on your Waiting Bench! (free)")
		or ("\u{2709}\u{FE0F} A %s student arrived on your Waiting Bench!"):format(rarity), "good")
	Signals.fire("letter", player, rarity)
	return { ok = true, id = def.id }
end
Actions.register("callLetter", function(player, p, rarity)
	return callLetter(player, p, rarity, false)
end)

-- the Pocket Money Promise: someone you can afford always turns up early on
local function pocketMoney()
	local hall = workspace:FindFirstChild("Hall")
	for player, p in Data.all() do
		if p.tier <= 2 and lastMove[player] and os.clock() - lastMove[player] < 60 then
			local affordable = false
			for _, m in hall and hall:GetChildren() or {} do
				local def = m:GetAttribute("State") == "Hall" and not m:GetAttribute("ReservedFor") and Config.StudentById[m:GetAttribute("StudentId")]
				if def and def.price <= p.cash then affordable = true break end
			end
			if not affordable and PlotService.freeSlot(player) then
				local best
				for _, s in Config.Students do
					if (s.rarity == "Common" or s.rarity == "Uncommon") and s.price <= p.cash and (not best or s.price > best.price) then best = s end
				end
				if best then
					local m = HallService.spawnOne(nil, best.id)
					local price = m and m.Head:FindFirstChild("Tag") and m.Head.Tag:FindFirstChild("Price")
					if price then
						price.Text = "BARGAIN! " .. Config.formatCash(best.price)
						price.TextColor3 = Color3.fromRGB(120, 255, 120)
					end
				end
			end
		end
	end
end

function LetterService.start()
	Signals.on("questStep", function(player, id)
		local p = Data.get(player)
		if id == "scholarship" and p and p.scholarshipUsed then
			-- they called it early: if the free kid isn't still waiting on the bench, make it free again
			local waiting = false
			for _, m in benches[player] or {} do
				if m.Parent and m:GetAttribute("State") == "Hall" and m:GetAttribute("Free") then waiting = true end
			end
			if not waiting then p.scholarshipUsed = nil end
		end
		if id == "scholarship" and p and not p.scholarshipUsed then
			letters(p).Rare = 0
			sync(player, p)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local p = Data.get(player)
		for _, m in benches[player] or {} do
			if m.Parent and m:GetAttribute("State") == "Hall" then
				-- a free kid (scholarship, daily reward) waits for next time
				if p and m:GetAttribute("Free") then
					p.pendingBench = p.pendingBench or {}
					table.insert(p.pendingBench, m:GetAttribute("StudentId"))
				end
				m:Destroy()
			end
		end
		benches[player], seen[player], lastMove[player], lastPos[player] = nil, nil, nil, nil
	end)
	-- letters fill while you play (moved in the last 2 minutes)
	task.spawn(function()
		local tick = 0
		while true do
			task.wait(1)
			tick += 1
			for player, p in Data.all() do
				local ls = letters(p)
				if not seen[player] then
					seen[player] = true
					-- free kids left waiting last time come back to the bench
					if type(p.pendingBench) == "table" and #p.pendingBench > 0 then
						local list = p.pendingBench
						p.pendingBench = nil
						task.delay(6, function()
							for _, id in list do
								local def = Config.StudentById[id]
								if def and player.Parent then LetterService.deliver(player, def, true) end
							end
						end)
					end
					local away = math.clamp((p.sessionStart or os.time()) - (p.lastOnline or os.time()), 0, OFFLINE_CAP)
					if away > 60 then
						for r, t in ls do ls[r] = math.max(0, t - away * OFFLINE_RATE) end
					end
				end
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root and (not lastPos[player] or (root.Position - lastPos[player]).Magnitude > 2) then
					lastPos[player] = root.Position
					lastMove[player] = os.clock()
				end
				if lastMove[player] and os.clock() - lastMove[player] < 120 then
					for r, t in ls do
						if t > 0 then
							ls[r] = t - 1
							if ls[r] <= 0 then
								ls[r] = 0
							end
						end
					end
				end
				sync(player, p)
				-- ready letters deliver themselves every few seconds, once there's a desk and a kid
				-- they can afford (rarest first)
				if tick % 3 == 0 and not p.reviewing then
					for i = #LetterService.Letters, 1, -1 do
						local r = LetterService.Letters[i].rarity
						if ls[r] and ls[r] <= 0 and (i <= 2 or (p.tier or 1) >= i) then
							callLetter(player, p, r, true)
						end
					end
				end
			end
			if tick % 20 == 0 then pcall(pocketMoney) end
		end
	end)
end

-- make a letter ready now; if it already is, bank a second one (rewards, Express products)
function LetterService.fill(player, rarity)
	local p = Data.get(player)
	if not p then return false end
	local ls = letters(p)
	if ls[rarity] == 0 then
		p.letterCredits = p.letterCredits or {}
		p.letterCredits[rarity] = (p.letterCredits[rarity] or 0) + 1
	end
	ls[rarity] = 0
	sync(player, p)
	return true
end
LetterService.debugReady = LetterService.fill

return LetterService
