-- ServerScriptService.Server.PatrolService
-- Running the school day to day:
--   Cheaters: now and then a seated kid starts cheating (cheat sheet out, earns nothing). Hold E
--     on them and they march to the Principal's Office bench for detention, then back to class,
--     and you collect a detention fee. Miss them for 40s and their desk's cash is gone. A good
--     teacher (Ms. Honeycutt and up) catches cheaters on their floor by themselves.
--   Dealers: Sweet Tooth Sal (candy) and Goo Gary (slime) sneak in through an unlocked gate and
--     deal at a desk; that row earns half. Bust them (hold E, or bonk with the Ruler) and you
--     confiscate the goods: candy = Sugar Rush (tuition x2 for 60s), slime = Slime Time (luck x2
--     for 90s). Ignore them and they leave with a cut of that row's cash.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local SchoolBuilder = require(script.Parent.SchoolBuilder)
local Factory = require(script.Parent.StudentFactory)
local Walkers = require(script.Parent.Walkers)
local StealService = require(script.Parent.StealService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)

local PatrolService = {}

local CHEAT_EVERY = { 90, 150 }
-- only strict teachers catch cheaters by themselves (the rest leave the fun to you)
local STRICT = { MrChalk = true, MsHoneycutt = true, DeanMaximus = true, Omniteacher = true }
local CHEAT_WINDOW = 40
local TEACHER_CATCH_AFTER = 12
local DETENTION = 20
local DEAL_EVERY = { 150, 260 }
local DEAL_WINDOW = 60

local bonkCrumpet -- defined with Crumpet below; the Ruler hook in start() calls it
local state = {} -- [player] = { nextCheat, nextDeal, cheating = { [slot] = info }, detention = { [slot] = info }, dealer = info }

local DEALERS = {
	{ id = "CandyDealer", name = "Sweet Tooth Sal", kind = "candy", rarity = "Common", price = 0, income = 0, prop = "CandyDealer",
		look = { skin = "tan", shirt = Color3.fromRGB(60, 60, 70), pants = Color3.fromRGB(40, 40, 50) } },
	{ id = "SlimeDealer", name = "Goo Gary", kind = "slime", rarity = "Common", price = 0, income = 0, prop = "SlimeDealer",
		look = { skin = "light", shirt = Color3.fromRGB(50, 170, 80), pants = Color3.fromRGB(30, 60, 40) } },
}

local function now()
	return os.clock()
end

local function st(player)
	local s = state[player]
	if not s and not player.Parent then
		-- a delayed callback for someone who has left: a throwaway, never stored
		return { cheating = {}, detention = {}, nextCheat = math.huge, nextDeal = math.huge }
	end
	if not s then
		s = { nextCheat = now() + math.random(CHEAT_EVERY[1], CHEAT_EVERY[2]) * 0.6, nextDeal = now() + math.random(DEAL_EVERY[1], DEAL_EVERY[2]) * 0.7, cheating = {}, detention = {}, lastMove = now() }
		state[player] = s
	end
	return s
end

-- a floating tag over a model's head
local function tag(model, name, text, color)
	local head = model:FindFirstChild("Head")
	if not head then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = name
	bb.Size = UDim2.new(7, 0, 1.6, 0)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 5.2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 80
	bb.LightInfluence = 0
	bb.Parent = head
	local t = Instance.new("TextLabel")
	t.Name = "Label"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.LuckiestGuy
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color
	t.Parent = bb
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Parent = t
	return t
end

local function prompt(parent, action, color, hold)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.HoldDuration = hold or 0.4
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = 10
	pp.KeyboardKeyCode = Enum.KeyCode.E
	pp:SetAttribute("OwnerOnly", true)
	pp:SetAttribute("Color", color)
	pp.Parent = parent
	return pp
end

---------------------------------------------------------------------------
-- cheaters and detention
---------------------------------------------------------------------------
local function endCheating(player, slot, s)
	local info = s.cheating[slot]
	if not info then return end
	s.cheating[slot] = nil
	if info.e then info.e.cheating = nil end
	for _, x in info.parts do
		if x.Parent then x:Destroy() end
	end
end

local function benchSeat(s)
	local used = {}
	for _, d in s.detention do used[d.seat] = true end
	for i = 1, #SchoolBuilder.BENCH_SEATS do
		if not used[i] then return i end
	end
	return nil
end

-- by: the teacher's name when a strict teacher made the catch (half fee, no Reformed)
function PatrolService.sendToOffice(player, slot, by)
	local s = st(player)
	local plot = PlotService.getPlot(player)
	local p = Data.get(player)
	local e = p and p.students[slot]
	if not plot or not e or e.away or e.carried or e.arriving then return end
	local info = s.cheating[slot]
	if by and (not info or info.e ~= e) then return end
	local seat = benchSeat(s)
	if not seat then return end
	local eagle = not by and info and now() - info.started < 10
	endCheating(player, slot, s)
	local def = Config.StudentById[e.id]
	-- the fee: 60 s of that kid's tuition, x1.5 for an Eagle Eye catch, half for a teacher's
	local fee = math.floor(PlotService.incomeOf(player, e, slot) * 60 * (eagle and 1.5 or 1) * (by and 0.5 or 1)) + 5
	p.stats.caught = (p.stats.caught or 0) + 1
	if p.stats.caught == 1 then
		fee += 100
		-- the Board is impressed: the boards come off the windows
		if not p.builds.Curtains then
			p.builds.Curtains = true
			task.delay(1.5, function()
				local pl = PlotService.getPlot(player)
				if pl then SchoolBuilder.setItems(pl, p.builds, "Curtains") end
				player:SetAttribute("Rep", (player:GetAttribute("Rep") or 0) + 1)
				PlotService.updateIncome(player)
				Remotes.Announce:FireClient(player, "THE BOARD SENT YOU WINDOWS!", Color3.fromRGB(120, 200, 255))
				Remotes.Sfx:FireClient(player, "Cheer")
			end)
		end
	end
	e.away = true
	PlotService.detachModel(plot, slot)
	PlotService.updateIncome(player)
	-- the walk of shame
	local model = Factory.build(def, e.grade)
	Factory.setMode(model, "owned")
	local so = Factory.standOffset(model)
	local pts = PlotService.worldPoints(plot, SchoolBuilder.officeRoute(slot, seat), so)
	model.PrimaryPart.CFrame = CFrame.new(pts[1])
	local folder = plot:FindFirstChild("Students")
	model.Parent = folder or plot
	tag(model, "Detention", "TO THE OFFICE!", Color3.fromRGB(255, 90, 90))
	Factory.play(model, "walk")
	local d = { model = model, seat = seat, e = e }
	s.detention[slot] = d
	Data.addCash(player, fee)
	Remotes.CashPop:FireClient(player, fee, model.PrimaryPart.Position)
	Remotes.Notify:FireClient(player, (by and (by .. " caught ") or (eagle and "EAGLE EYE! You caught " or "You caught ")) .. def.name .. " cheating! Detention fee +" .. Config.formatCash(fee), "good")
	Remotes.Sfx:FireClient(player, "WhistleLong")
	Signals.fire("catchCheater", player, def)
	Walkers.walk(model, pts, 10, function()
		if not model.Parent then return end
		-- sit on the bench facing the room
		local b = plot.Origin.CFrame:PointToWorldSpace(SchoolBuilder.BENCH_SEATS[seat])
		local hrp = model.PrimaryPart
		local y = b.Y + hrp.Size.Y * 0.5 + model:FindFirstChildOfClass("Humanoid").HipHeight * 0.1
		-- facing into the office, back to the wall
		hrp.CFrame = CFrame.new(b.X, y, b.Z) * plot.Origin.CFrame.Rotation * CFrame.Angles(0, math.pi, 0)
		Factory.play(model, "sit")
		local label = model.Head:FindFirstChild("Detention") and model.Head.Detention.Label
		for t = DETENTION, 1, -1 do
			if not model.Parent or s.detention[slot] ~= d then return end
			if label then label.Text = ("DETENTION %ds"):format(t) end
			task.wait(1)
		end
		if not model.Parent then return end
		if label then label.Text = "sorry..." end
		-- back to class
		local back = {}
		for i = #pts, 1, -1 do table.insert(back, pts[i]) end
		Factory.play(model, "walk")
		Walkers.walk(model, back, 10, function()
			model:Destroy()
			if s.detention[slot] == d then s.detention[slot] = nil end
			if p.students[slot] == e and PlotService.getPlot(player) == plot then
				e.away = nil
				if not by then e.reformedUntil = now() + 300 end
				local seatedModel = PlotService.place(player, slot)
				PlotService.updateIncome(player)
				-- reformed: a halo for five minutes (+10 % tuition while it lasts)
				if seatedModel and not by then
					local head = seatedModel:FindFirstChild("Head")
					if head then
						local halo = Instance.new("Part")
						halo.Name = "Halo"
						halo.Shape = Enum.PartType.Cylinder
						halo.Size = Vector3.new(0.12, head.Size.X * 1.1, head.Size.X * 1.1)
						halo.Color = Color3.fromRGB(255, 240, 150)
						halo.Material = Enum.Material.Neon
						halo.CanCollide, halo.CanQuery, halo.CanTouch, halo.Massless = false, false, false, true
						halo.CFrame = head.CFrame * CFrame.new(0, head.Size.Y * 0.95, 0) * CFrame.Angles(0, 0, math.rad(90))
						local w = Instance.new("WeldConstraint")
						w.Part0, w.Part1 = head, halo
						w.Parent = halo
						halo.Parent = seatedModel
						game:GetService("Debris"):AddItem(halo, 300)
					end
				end
			end
		end, { flat = false })
	end, { flat = false })
end

local function startCheating(player, forceSlot)
	local s = st(player)
	local plot = PlotService.getPlot(player)
	local p = Data.get(player)
	if not plot or not p or not benchSeat(s) then return end
	-- at most one cheater per floor
	local busyFloor = {}
	for slot in s.cheating do busyFloor[PlotService.slotFloor(slot)] = true end
	local candidates = {}
	for slot, e in p.students do
		if PlotService.earning(e) and not e.away and not s.cheating[slot] and not busyFloor[PlotService.slotFloor(slot)] and PlotService.seatedModel(plot, slot) then
			table.insert(candidates, slot)
		end
	end
	if #candidates < 2 and not forceSlot then return end
	local slot = candidates[math.random(#candidates)]
	if forceSlot then
		if not table.find(candidates, forceSlot) then return end
		slot = forceSlot
	end
	local e = p.students[slot]
	local model = PlotService.seatedModel(plot, slot)
	local def = Config.StudentById[e.id]
	e.cheating = true
	PlotService.updateIncome(player)
	local info = { e = e, started = now(), parts = {} }
	s.cheating[slot] = info
	-- the cheat sheet, held low, and a shifty look around
	local hand = model:FindFirstChild("RightHand")
	if hand then
		local paper = Instance.new("Part")
		paper.Name = "CheatSheet"
		paper.Size = Vector3.new(0.8, 0.05, 1)
		paper.Color = Color3.fromRGB(255, 255, 240)
		paper.CanCollide, paper.CanQuery, paper.CanTouch, paper.Massless = false, false, false, true
		paper.CFrame = hand.CFrame * CFrame.new(0, -0.1, -0.4)
		local w = Instance.new("WeldConstraint")
		w.Part0 = hand
		w.Part1 = paper
		w.Parent = paper
		paper.Parent = model
		table.insert(info.parts, paper)
	end
	local label = tag(model, "Cheating", "\u{2757} CHEATING!", Color3.fromRGB(255, 80, 80))
	if label then table.insert(info.parts, label.Parent) end
	local pp = prompt(model.PrimaryPart, "Catch Cheater!", Color3.fromRGB(255, 80, 80), 0.4)
	pp.ObjectText = def.name
	table.insert(info.parts, pp)
	pp.Triggered:Connect(function(who)
		if who == player then PatrolService.sendToOffice(player, slot) end
	end)
	-- shifty eyes: the head turns left and right
	local target, prop = Factory.poseTarget(model:FindFirstChild("Head") and model.Head:FindFirstChild("Neck"))
	if target then
		local base = target[prop]
		task.spawn(function()
			while s.cheating[slot] == info and target.Parent do
				TweenService:Create(target, TweenInfo.new(0.25), { [prop] = base * CFrame.Angles(0, math.rad(40), 0) }):Play()
				task.wait(0.7)
				TweenService:Create(target, TweenInfo.new(0.25), { [prop] = base * CFrame.Angles(0, math.rad(-40), 0) }):Play()
				task.wait(0.7)
			end
			if target.Parent then target[prop] = base end
		end)
	end
	Remotes.Notify:FireClient(player, "\u{1F440} " .. def.name .. " is cheating! Catch them before they get away with it.", "steal")
	Remotes.Sfx:FireClient(player, "Scratch2")
	Signals.fire("cheatStart", player, def)
end

function PatrolService.startCheatingAt(player, slot)
	startCheating(player, slot)
end

local function tickCheating(player, s)
	local p = Data.get(player)
	for slot, info in s.cheating do
		-- sold, stolen or moved: the cheating goes with them
		if not p or p.students[slot] ~= info.e or info.e.carried then
			endCheating(player, slot, s)
			if p then PlotService.updateIncome(player) end
			continue
		end
		local age = now() - info.started
		-- a good teacher on that floor spots it first
		if age > TEACHER_CATCH_AFTER and p then
			local t = p.teachers[PlotService.slotFloor(slot)]
			local tdef = t and Config.TeacherById[t.id]
			if tdef and STRICT[tdef.id] then
				PatrolService.sendToOffice(player, slot, tdef.name)
				continue
			end
		end
		if age > CHEAT_WINDOW then
			-- missed: an F for two minutes (earns half), and the cheating spreads next door
			local e = info.e
			local def = Config.StudentById[e.id]
			endCheating(player, slot, s)
			e.failUntil = now() + 120
			PlotService.updateIncome(player)
			local plot = PlotService.getPlot(player)
			local model = plot and PlotService.seatedModel(plot, slot)
			if model then
				local f = tag(model, "FailTag", "F", Color3.fromRGB(255, 60, 60))
				if f then game:GetService("Debris"):AddItem(f.Parent, 120) end
			end
			Remotes.Notify:FireClient(player, def.name .. " got away with cheating! F for 2 minutes, and it is spreading...", "bad")
			Remotes.Sfx:FireClient(player, "SadTrombone")
			for _, n in { slot - 1, slot + 1 } do
				local ne = p and p.students[n]
				if ne and PlotService.slotRow(n) == PlotService.slotRow(slot) and PlotService.slotFloor(n) == PlotService.slotFloor(slot) and PlotService.earning(ne) then
					task.delay(3, function() pcall(PatrolService.startCheatingAt, player, n) end)
					break
				end
			end
		end
	end
end

---------------------------------------------------------------------------
-- dealers
---------------------------------------------------------------------------
local function dealerRow(d)
	return d and d.slot and { floor = PlotService.slotFloor(d.slot), row = PlotService.slotRow(d.slot) }
end

local function dealerLeave(player, s, busted, by)
	local d = s.dealer
	if not d or d.leaving then return end
	d.leaving = true
	d.dealing = false
	if d.prompt then d.prompt:Destroy() end
	local plot = d.plot
	PlotService.updateIncome(player)
	local label = d.model.Head:FindFirstChild("DealerTag") and d.model.Head.DealerTag.Label
	if busted then
		if label then label.Text = "BUSTED!" end
		local p = Data.get(player)
		local until_ = workspace:GetServerTimeNow() + (d.def.kind == "candy" and 20 or 60)
		-- Confiscated Candy: the currency for Stan's Confiscation Closet
		local candy = d.def.kind == "candy" and 8 or 12
		if p then
			p.candy = (p.candy or 0) + candy
			player:SetAttribute("Candy", p.candy)
		end
		if d.def.kind == "candy" then
			player:SetAttribute("SugarUntil", until_)
			Remotes.Announce:FireClient(player, "SUGAR RUSH! TUITION x2 FOR 20s", Color3.fromRGB(255, 110, 190))
		else
			player:SetAttribute("SlimeUntil", until_)
			if p then p.luckMult = 2 end
			Remotes.Announce:FireClient(player, "SLIME TIME! LUCK x2 FOR 60s", Color3.fromRGB(110, 255, 130))
		end
		PlotService.updateIncome(player)
		Remotes.Sfx:FireClient(player, "StingWhat")
		Remotes.Notify:FireClient(player, ("%s busted %s! Contraband confiscated: +%d candy"):format(by or "You", d.def.name, candy), "good")
		if p then p.stats.busted = (p.stats.busted or 0) + 1 end
		Signals.fire("bustDealer", player, d.def)
	else
		-- skims a cut of that row's cash on the way out
		local p = Data.get(player)
		local row = dealerRow(d)
		local took = 0
		if p and row then
			for slot, e in p.students do
				if PlotService.slotFloor(slot) == row.floor and PlotService.slotRow(slot) == row.row then
					local cut = math.floor((e.stored or 0) * 0.2)
					e.stored = (e.stored or 0) - cut
					took += cut
					PlotService.updatePad(plot, slot, e.stored)
				end
			end
		end
		if label then label.Text = "SEE YA!" end
		Remotes.Notify:FireClient(player, ("%s got away with %s of your tuition!"):format(d.def.name, Config.formatCash(took)), "bad")
	end
	-- run back out the gate
	local back = {}
	for i = #d.path, 1, -1 do table.insert(back, d.path[i]) end
	Factory.play(d.model, "walk")
	Walkers.walk(d.model, back, busted and 20 or 10, function()
		d.model:Destroy()
		if s.dealer == d then s.dealer = nil end
	end, { flat = false })
end

local function sendDealer(player, s, scripted)
	local plot = PlotService.getPlot(player)
	local p = Data.get(player)
	if not plot or not p or s.dealer then return end
	if not scripted and (plot:GetAttribute("LockedUntil") or 0) > workspace:GetServerTimeNow() then return end -- the gate keeps them out
	local slots = {}
	for slot, e in p.students do
		if PlotService.earning(e) then table.insert(slots, slot) end
	end
	if #slots < (scripted and 1 or 4) then return end
	local slot = slots[math.random(#slots)]
	local def = DEALERS[math.random(#DEALERS)]
	local model = Factory.build(def, "Normal")
	model.Name = def.id
	-- the dealer's tag replaces the student one
	local old = model.Head:FindFirstChild("Tag")
	if old then old:Destroy() end
	local label = tag(model, "DealerTag", def.name:upper() .. (def.kind == "candy" and " \u{1F36C}" or " \u{1F7E2}"), def.kind == "candy" and Color3.fromRGB(255, 120, 200) or Color3.fromRGB(110, 255, 130))
	local so = Factory.standOffset(model)
	local entry = plot.Entry.Position
	local pts = { Vector3.new(entry.X, 0.4 + so, entry.Z) }
	for _, w in PlotService.worldPoints(plot, SchoolBuilder.aisleRoute(slot), so) do table.insert(pts, w) end
	model.PrimaryPart.CFrame = CFrame.new(pts[1])
	model.Parent = plot:FindFirstChild("Students") or plot
	Factory.play(model, "walk")
	local d = { model = model, def = def, slot = slot, plot = plot, path = pts, started = now() }
	s.dealer = d
	Remotes.Notify:FireClient(player, ("\u{1F6A8} %s snuck into your school! Bust them!"):format(def.name), "steal")
	Remotes.Sfx:FireClient(player, "StingSitcom")
	Walkers.walk(model, pts, 8, function()
		if s.dealer ~= d or d.leaving then return end
		d.dealing = true
		d.started = now()
		Factory.play(model, "idle")
		if label then label.Text = def.kind == "candy" and "SNEAKING CANDY!" or "SNEAKING SLIME!" end
		PlotService.updateIncome(player)
		local pp = prompt(model.PrimaryPart, "Bust!", Color3.fromRGB(255, 170, 40), 0.3)
		pp.ObjectText = def.name
		d.prompt = pp
		pp.Triggered:Connect(function(who)
			if who == player then dealerLeave(player, s, true) end
		end)
	end, { flat = false })
end

---------------------------------------------------------------------------
function PatrolService.start()
	-- a dealing dealer halves their row; a Sugar Rush doubles everything
	table.insert(PlotService.tempHooks, function(player, p, e, slot)
		local m = 1
		local s = state[player]
		local d = s and s.dealer
		if d and d.dealing and PlotService.slotFloor(slot) == PlotService.slotFloor(d.slot) and PlotService.slotRow(slot) == PlotService.slotRow(d.slot) then
			m *= 0.5
		end
		if (player:GetAttribute("SugarUntil") or 0) > workspace:GetServerTimeNow() then
			m *= 2
		end
		local t = now()
		if e.reformedUntil and e.reformedUntil > t then m *= 1.1 end
		if e.failUntil and e.failUntil > t then m *= 0.5 end
		return m
	end)

	-- the tutorial's scripted moments
	Signals.on("questStep", function(player, id)
		local s = st(player)
		if id == "catch" then
			pcall(startCheating, player)
		elseif id == "bonk" then
			task.delay(2, function() pcall(PatrolService.crumpet, player) end)
		elseif id == "bust" then
			pcall(sendDealer, player, s, true)
		end
	end)

	-- the Ruler busts dealers too
	table.insert(StealService.swingHooks, function(player, root)
		local s0 = state[player]
		local c = s0 and s0.crumpet
		if c and not c.done and c.model.PrimaryPart and (c.model.PrimaryPart.Position - root.Position).Magnitude < 9 then
			bonkCrumpet(player, s0)
		end
	end)
	table.insert(StealService.swingHooks, function(player, root)
		local s = state[player]
		local d = s and s.dealer
		if d and not d.leaving and d.model.PrimaryPart and (d.model.PrimaryPart.Position - root.Position).Magnitude < 9 then
			dealerLeave(player, s, true)
		end
	end)

	-- a rebuilt campus (School Board review) sends everyone home
	table.insert(PlotService.rebuildHooks, function(player)
		local s = state[player]
		if not s then return end
		for slot in s.cheating do endCheating(player, slot, s) end
		for slot, d in s.detention do
			d.model:Destroy()
			if d.e then d.e.away = nil end
			s.detention[slot] = nil
		end
		if s.dealer then
			s.dealer.model:Destroy()
			s.dealer = nil
		end
		if s.crumpet then
			s.crumpet.done = true
			s.crumpet.model:Destroy()
			s.crumpet = nil
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local s = state[player]
		if s then
			for _, d in s.detention do d.model:Destroy() end
			if s.dealer then s.dealer.model:Destroy() end
			if s.crumpet then s.crumpet.model:Destroy() end
		end
		state[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			local t = now()
			for player, p in Data.all() do
				local s = st(player)
				-- boosts running out
				if player:GetAttribute("SugarUntil") and player:GetAttribute("SugarUntil") <= workspace:GetServerTimeNow() then
					player:SetAttribute("SugarUntil", nil)
					PlotService.updateIncome(player)
				end
				if player:GetAttribute("SlimeUntil") and player:GetAttribute("SlimeUntil") <= workspace:GetServerTimeNow() then
					player:SetAttribute("SlimeUntil", nil)
				end
				if not player:GetAttribute("SlimeUntil") and p.luckMult then p.luckMult = nil end
				-- only while the owner is actually playing (moved in the last minute)
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root and (not s.lastPos or (root.Position - s.lastPos).Magnitude > 2) then
					s.lastPos = root.Position
					s.lastMove = t
				end
				local active = t - (s.lastMove or t) < 60
				if not active then
					s.nextCheat = math.max(s.nextCheat, t + 5)
					s.nextDeal = math.max(s.nextDeal, t + 5)
				end
				-- random cheaters once the tutorial has taught catching, smugglers once it taught busting
				if active and (p.tutorial or 1) >= 4 then
					if t >= s.nextCheat then
						s.nextCheat = t + math.random(CHEAT_EVERY[1], CHEAT_EVERY[2])
						pcall(startCheating, player)
					end
					if t >= s.nextDeal and (p.tutorial or 1) >= 11 then
						s.nextDeal = t + math.random(DEAL_EVERY[1], DEAL_EVERY[2])
						pcall(sendDealer, player, s)
					end
				end
				tickCheating(player, s)
				local d = s.dealer
				if d and d.dealing and not d.leaving and t - d.started > DEAL_WINDOW then
					dealerLeave(player, s, false)
				end
			end
		end
	end)
end

---------------------------------------------------------------------------
-- Crumpet, Vex's butler: the tutorial thief. He walks in, lifts a kid over his head and strolls
-- out; one Ruler bonk and the kid runs back to their desk. He never actually gets away with it.
---------------------------------------------------------------------------
local CRUMPET = { id = "Crumpet", name = "Crumpet", title = "Butler", mult = 1, outfit = "butler" }

local function crumpetSay(c, text)
	local label = c.model.Head:FindFirstChild("ThiefTag") and c.model.Head.ThiefTag.Label
	if label then label.Text = text end
end

local function crumpetGiveBack(player, s, c)
	if c.done then return end
	c.done = true
	local lifted = c.carried ~= nil
	if c.carried then c.carried:Destroy() end
	local p = Data.get(player)
	-- only the kid he actually lifted goes back to the desk
	if lifted and p and p.students[c.slot] == c.e then
		c.e.carried = nil
		PlotService.place(player, c.slot)
		PlotService.updateIncome(player)
	end
end

-- Crumpet walks off the lot and goes away; while the bonk step is still open he comes back later
local function crumpetLeave(player, s, c, path)
	local back = {}
	for i = #path, 1, -1 do table.insert(back, path[i]) end
	Factory.play(c.model, "walk")
	Walkers.walk(c.model, back, 12, function()
		c.model:Destroy()
		if s.crumpet == c then s.crumpet = nil end
		local pp = Data.get(player)
		local step = pp and pp.tutorial and Config.Tutorial[pp.tutorial]
		if player.Parent and step and step.id == "bonk" then task.delay(8, function() PatrolService.crumpet(player) end) end
	end, { flat = false })
end

function PatrolService.crumpet(player)
	local s = st(player)
	if s.crumpet then return end
	local plot = PlotService.getPlot(player)
	local p = Data.get(player)
	if not plot or not p then return end
	local slot
	for sl, e in p.students do
		if PlotService.earning(e) and not e.away and PlotService.seatedModel(plot, sl) and (not slot or sl < slot) then slot = sl end
	end
	if not slot then return end
	local model = Factory.buildTeacher(CRUMPET, 1)
	model.Name = "Crumpet"
	tag(model, "ThiefTag", "Terribly sorry...", Color3.fromRGB(255, 90, 90))
	local so = Factory.standOffset(model)
	local entry = plot.Entry.Position
	local path = { Vector3.new(entry.X, 0.4 + so, entry.Z) }
	for _, w in PlotService.worldPoints(plot, SchoolBuilder.aisleRoute(slot), so) do table.insert(path, w) end
	model.PrimaryPart.CFrame = CFrame.new(path[1])
	model.Parent = plot:FindFirstChild("Students") or plot
	Factory.play(model, "walk")
	local c = { model = model, slot = slot, e = p.students[slot], path = path }
	s.crumpet = c
	Remotes.Notify:FireClient(player, "\u{1F3A9} A butler just walked into your school...", "steal")
	Walkers.walk(model, path, 10, function()
		if c.done or not model.Parent then return end
		local e = p.students[slot]
		if e ~= c.e or not PlotService.earning(e) then
			crumpetGiveBack(player, s, c)
			crumpetSay(c, "Ah. Wrong child. Terribly sorry.")
			crumpetLeave(player, s, c, path)
			return
		end
		-- lift the kid over his head
		e.carried = true
		PlotService.detachModel(plot, slot)
		PlotService.updateIncome(player)
		local def = Config.StudentById[e.id]
		local kid = Factory.build(def, e.grade)
		Factory.setMode(kid, "carried")
		for _, bp in kid:GetDescendants() do
			if bp:IsA("BasePart") then
				bp.Anchored = false
				bp.Massless = true
				bp.CanCollide = false
			end
		end
		local off = 3.4 + Factory.standOffset(kid) * 0.9
		kid.PrimaryPart.CFrame = model.PrimaryPart.CFrame * CFrame.new(0, off, 0)
		local w = Instance.new("Weld")
		w.Part0, w.Part1 = model.PrimaryPart, kid.PrimaryPart
		w.C0 = CFrame.new(0, off, 0) * CFrame.Angles(0, 0, math.rad(8))
		w.Parent = kid.PrimaryPart
		kid.Parent = model
		Factory.play(kid, "sit")
		c.carried = kid
		crumpetSay(c, "I'm taking this child. BONK ME!")
		Remotes.Announce:FireClient(player, "CRUMPET IS STEALING " .. def.name:upper() .. "!", Color3.fromRGB(255, 90, 90))
		Remotes.Sfx:FireClient(player, "Alarm")
		Factory.play(model, "walk")
		local back = {}
		for i = #path, 1, -1 do table.insert(back, path[i]) end
		Walkers.walk(model, back, 5, function()
			if c.done then return end
			-- out on the street: he thinks better of it
			crumpetSay(c, "Madam says I must return this child.")
			crumpetGiveBack(player, s, c)
			task.delay(2, function()
				model:Destroy()
				if s.crumpet == c then s.crumpet = nil end
				local pp = Data.get(player)
				local step = pp and pp.tutorial and Config.Tutorial[pp.tutorial]
				if step and step.id == "bonk" then task.delay(8, function() PatrolService.crumpet(player) end) end
			end)
		end, { flat = false })
	end, { flat = false })
end

bonkCrumpet = function(player, s)
	local c = s.crumpet
	if not c or c.done or not c.carried then return end
	local had = c.carried ~= nil
	local def = Config.StudentById[c.e.id]
	crumpetGiveBack(player, s, c)
	Walkers.stop(c.model)
	crumpetSay(c, "Most irregular.")
	Remotes.Sfx:FireClient(player, "Bonk")
	task.delay(0.3, function() Remotes.Sfx:FireClient(player, "SlideWhistle") end)
	if had then
		Remotes.Notify:FireClient(player, "You saved " .. def.name .. "! +DEFENDED", "good")
		Signals.fire("bonkSave", player, nil, def, player)
	end
	-- a spin, then off he goes
	local root = c.model.PrimaryPart
	task.spawn(function()
		for i = 1, 12 do
			if not root.Parent then return end
			root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(60), 0)
			task.wait(0.03)
		end
		local back = {}
		for i = #c.path, 1, -1 do table.insert(back, c.path[i]) end
		Factory.play(c.model, "walk")
		Walkers.walk(c.model, back, 18, function()
			c.model:Destroy()
			if s.crumpet == c then s.crumpet = nil end
		end, { flat = false })
	end)
end

-- test hooks
PatrolService.debugCheat = startCheating
function PatrolService.debugDealer(player)
	local s = st(player)
	sendDealer(player, s)
	return s.dealer ~= nil
end
function PatrolService.debugBonkCrumpet(player)
	local s = st(player)
	if s.crumpet and s.crumpet.carried then bonkCrumpet(player, s) return true end
	return false
end
function PatrolService.debugBust(player)
	local s = st(player)
	if s.dealer then dealerLeave(player, s, true) return true end
	return false
end

return PatrolService
