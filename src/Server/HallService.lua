-- ServerScriptService.Server.HallService
-- Students step off the bus and walk the red carpet to detention unless someone enrolls them.
-- Also: luck (players standing in the hallway bring their Recruitment Office luck), special buses
-- that drive in with a batch of rarer students, and Recess (luck x2, busier bus) every 15 minutes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Factory = require(script.Parent.StudentFactory)
local Walkers = require(script.Parent.Walkers)
local PlotService = require(script.Parent.PlotService)
local UpgradeService = require(script.Parent.UpgradeService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)

local HallService = {}

local hall = workspace:FindFirstChild("Hall") or Instance.new("Folder")
hall.Name = "Hall"
hall.Parent = workspace

local map = workspace:WaitForChild("Map")
local path = map.HallPath
local FLOOR_Y = 0.65
local RECESS_EVERY, RECESS_LEN = 900, 60

-- extra luck multipliers (game passes, server luck products): fn() -> number
HallService.luckHooks = {}
-- event grades that can roll right now, set by EventService: { [gradeId] = weight }
HallService.eventGrades = {}

local function weighted(list)
	local total = 0
	for _, x in list do total += x.weight end
	local r = math.random() * total
	for _, x in list do
		r -= x.weight
		if r <= 0 then return x end
	end
	return list[#list]
end

function HallService.recessActive()
	return workspace:GetServerTimeNow() < (workspace:GetAttribute("RecessUntil") or 0)
end

-- the best luck of anyone standing on the hallway strip, times recess and boosts
function HallService.luck()
	local best = 1
	for player, p in Data.all() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and math.abs(root.Position.Z) < 20 and math.abs(root.Position.X) < 335 then
			best = math.max(best, UpgradeService.luck(p) * (p.luckMult or 1))
		end
	end
	if HallService.recessActive() then best *= 2 end
	for _, hook in HallService.luckHooks do
		best *= hook()
	end
	return best
end

local function rollGrade()
	local list = {}
	for _, g in Config.Grades do
		local w = g.weight
		if g.event then w = HallService.eventGrades[g.id] or 0 end
		if w > 0 then table.insert(list, { id = g.id, weight = w }) end
	end
	return weighted(list).id
end

-- weights: optional { [rarityId] = weight } overriding the regular bus
function HallService.roll(forceRarity, forceId, weights, luck)
	if forceId and Config.StudentById[forceId] then
		return Config.StudentById[forceId], rollGrade()
	end
	local rarity
	if forceRarity then
		rarity = Config.RarityById[forceRarity]
	else
		luck = luck or HallService.luck()
		local list = {}
		for _, r in Config.Rarities do
			local w = weights and (weights[r.id] or 0) or r.weight
			if w > 0 then
				if r.order >= 3 then w *= luck end
				table.insert(list, { id = r.id, weight = w, r = r })
			end
		end
		rarity = weighted(list).r
	end
	local pool = {}
	for _, s in Config.Students do
		if s.rarity == rarity.id then table.insert(pool, s) end
	end
	return pool[math.random(1, #pool)], rollGrade()
end

function HallService.enroll(player, model)
	if model:GetAttribute("State") ~= "Hall" then return end
	local p = Data.get(player)
	local plot = PlotService.getPlot(player)
	if not p or not plot then return end
	local def = Config.StudentById[model:GetAttribute("StudentId")]
	local grade = model:GetAttribute("Grade")
	if p.cash < def.price then
		Remotes.Notify:FireClient(player, "Not enough cash!", "bad")
		Remotes.Sfx:FireClient(player, "Error")
		return
	end
	local slot = PlotService.freeSlot(player)
	if not slot then
		Remotes.Notify:FireClient(player, "Your school is full! Sell a student or add desks.", "bad")
		Remotes.Sfx:FireClient(player, "Error")
		return
	end
	if not Data.addCash(player, -def.price) then return end
	model:SetAttribute("State", "Enrolled")
	local prompt = model.PrimaryPart:FindFirstChild("EnrollPrompt")
	if prompt then prompt:Destroy() end

	p.students[slot] = { id = def.id, grade = grade, stored = 0, arriving = true }
	local key = def.id .. "|" .. grade
	local firstTime = not p.index[key]
	p.index[key] = true
	p.stats.enrolled += 1
	Remotes.Notify:FireClient(player, "Enrolled " .. def.name .. "!", "good")
	Remotes.Sfx:FireClient(player, "Enroll")
	local rarity = Config.RarityById[def.rarity]
	if rarity.order >= 4 then
		Remotes.Announce:FireClient(player, rarity.id:upper() .. " ENROLLED!", Config.rarityAccent(def.rarity))
	end
	Signals.fire("enroll", player, def, grade, firstTime)

	Factory.setMode(model, "walking", player.DisplayName)
	Walkers.stop(model)
	Factory.play(model, "walk")
	local points = PlotService.pathTo(plot, slot, model.PrimaryPart.Position, Factory.standOffset(model))
	Walkers.walk(model, points, 16, function()
		model:Destroy()
		local e = p.students[slot]
		if e and e.arriving and PlotService.getPlot(player) == plot then
			local seatedModel = PlotService.place(player, slot)
			PlotService.updateIncome(player)
			if seatedModel then Factory.emote(seatedModel, "cheer") end
		end
	end, { flat = false })
end

-- put one student on the carpet; from = optional start position (a special bus door)
function HallService.spawnOne(forceRarity, forceId, weights, from)
	if not forceRarity and not forceId and not weights and #hall:GetChildren() >= Config.MaxHallStudents then return end
	local def, grade = HallService.roll(forceRarity, forceId, weights)
	local model = Factory.build(def, grade)
	model:SetAttribute("State", "Hall")
	local hrp = model.PrimaryPart
	local start = path.Start.Position
	local y = FLOOR_Y + Factory.standOffset(model)
	-- a little sideways jitter so the line does not look like a conveyor belt
	local z = (math.random() - 0.5) * 6
	local origin = from or Vector3.new(start.X, 0, z)
	hrp.CFrame = CFrame.lookAt(Vector3.new(origin.X, y, origin.Z), Vector3.new(start.X + 1, y, z))
	model.Parent = hall
	Factory.play(model, "walk")

	-- the whole server hears about the rare ones
	local rarity = Config.RarityById[def.rarity]
	if rarity.order >= 7 then
		Remotes.Announce:FireAllClients(("A %s STUDENT IS ON THE CARPET!"):format(rarity.id:upper()), Config.rarityAccent(def.rarity))
		Remotes.Sfx:FireAllClients(rarity.id == "Prodigy" and "Choir" or "RecordScratch")
	elseif rarity.order == 6 then
		Remotes.Notify:FireAllClients("A Mythic student just stepped off the bus!", "steal")
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EnrollPrompt"
	prompt.ActionText = "Enroll " .. Config.formatCash(def.price)
	prompt.ObjectText = def.name
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt:SetAttribute("Color", Config.rarityAccent(def.rarity))
	prompt.Parent = hrp
	prompt.Triggered:Connect(function(player)
		HallService.enroll(player, model)
	end)

	local finish = path.End.Position
	local pts = {}
	if from then table.insert(pts, Vector3.new(from.X, 0, z)) end -- step down onto the carpet
	table.insert(pts, Vector3.new(finish.X, 0, z))
	Walkers.walk(model, pts, Config.WalkSpeed, function()
		model:Destroy()
	end)
	return model
end

---------------------------------------------------------------------------
-- special buses
---------------------------------------------------------------------------
local busTemplate = map.SchoolBus
local PARK = CFrame.new(-305, 0, 26) -- ahead of the regular bus, door facing the carpet
local function makeBus(label, color)
	local bus = busTemplate:Clone()
	bus.Name = label:gsub(" ", "")
	for _, n in { "Body", "Hood" } do
		for _, part in bus:GetChildren() do
			if part.Name == n then part.Color = color end
		end
	end
	for _, g in bus.Sign:GetChildren() do
		if g:IsA("SurfaceGui") then
			g.Label.Text = label
			g.Label.BackgroundColor3 = color
		end
	end
	bus.Sign.Color = color
	return bus
end

-- drive a model's pivot from a to b over t seconds (server side, smooth enough for a bus)
local function drive(model, from, to, t)
	local start = os.clock()
	while true do
		local a = math.min(1, (os.clock() - start) / t)
		local e = a < 0.5 and 2 * a * a or 1 - (-2 * a + 2) ^ 2 / 2
		model:PivotTo(from:Lerp(to, e))
		if a >= 1 then break end
		RunService.Heartbeat:Wait()
	end
end

local BUSES = {
	LateBus = { label = "LATE BUS", color = Color3.fromRGB(255, 120, 30) },
	FieldTrip = { label = "FIELD TRIP", color = Color3.fromRGB(150, 80, 255) },
	Lucky = { label = "LUCKY BUS", color = Color3.fromRGB(60, 220, 110) },
	HonorBus = { label = "HONOR ROLL", color = Color3.fromRGB(255, 200, 40) },
	Welcome = { label = "WELCOME BUS", color = Color3.fromRGB(80, 190, 255) },
}
-- the Welcome Bus brings the six starter kids when a new principal arrives
local WELCOME = { count = 6, ids = { "UntiedTyler", "GlueStickGus", "DoodleDot", "LunchboxLucy", "PajamaPete", "HiccupHank" } }

function HallService.specialBus(kind, byName)
	local spec = kind == "FieldTrip" and Config.FieldTrip or kind == "HonorBus" and Config.HonorBus or kind == "Welcome" and WELCOME or Config.LateBus
	local style = BUSES[kind] or BUSES.LateBus
	local label, color = style.label, style.color
	local weights = spec.weights
	if not weights then
		weights = {}
		for _, r in Config.Rarities do
			if r.order >= (spec.minRarity or 3) and r.weight > 0 then weights[r.id] = r.weight end
		end
	end
	if kind == "Lucky" then
		weights = { Legendary = 70, Mythic = 24, Prodigy = 5, Secret = 1 }
	end
	local bus = makeBus(label, color)
	-- the template faces +X with its door on -Z; park it with the same orientation
	local pivot0 = busTemplate:GetPivot()
	local parked = PARK * pivot0.Rotation + Vector3.new(0, pivot0.Position.Y, 0)
	local away = parked - Vector3.new(160, 0, 0)
	bus:PivotTo(away)
	bus.Parent = workspace
	Remotes.Sfx:FireAllClients("BusHorn")
	drive(bus, away, parked, 4)
	local door = bus.Door.Position
	for i = 1, spec.count or 6 do
		local w = (i == 1 and spec.first) or weights
		if spec.ids then
			HallService.spawnOne(nil, spec.ids[i], nil, Vector3.new(door.X, 0, door.Z - 3))
		else
			HallService.spawnOne(nil, nil, w, Vector3.new(door.X, 0, door.Z - 3))
		end
		task.wait(0.6)
	end
	task.wait(1.5)
	-- reverse back out the way it came
	drive(bus, parked, parked - Vector3.new(200, 0, 0), 4)
	bus:Destroy()
	if byName then
		Remotes.Notify:FireAllClients(byName .. " called a " .. label .. "!", "steal")
	end
end

function HallService.start()
	-- regular bus
	task.spawn(function()
		while true do
			local ok, err = pcall(HallService.spawnOne)
			if not ok then warn("[Hall] spawn failed:", err) end
			task.wait(Config.SpawnInterval / (HallService.recessActive() and 1.5 or 1))
		end
	end)

	-- schedule: late bus, field trip, recess (times published for the HUD)
	local now = workspace:GetServerTimeNow()
	workspace:SetAttribute("LateBusAt", now + Config.LateBus.every)
	workspace:SetAttribute("FieldTripAt", now + Config.FieldTrip.every)
	workspace:SetAttribute("HonorBusAt", now + Config.HonorBus.offset)
	workspace:SetAttribute("RecessAt", now + RECESS_EVERY)
	workspace:SetAttribute("RecessUntil", 0)
	task.spawn(function()
		local warned = {}
		while true do
			task.wait(0.5)
			local t = workspace:GetServerTimeNow()
			for _, kind in { "LateBus", "FieldTrip", "HonorBus" } do
				local at = workspace:GetAttribute(kind .. "At")
				local label = "THE " .. BUSES[kind].label .. " BUS"
				if kind == "LateBus" then label = "THE LATE BUS" end
				if at - t <= 10 and not warned[kind] then
					warned[kind] = true
					Remotes.Announce:FireAllClients(label .. " ARRIVES IN 10s!", BUSES[kind].color)
				end
				if t >= at then
					warned[kind] = nil
					local every = (kind == "FieldTrip" and Config.FieldTrip or kind == "HonorBus" and Config.HonorBus or Config.LateBus).every
					workspace:SetAttribute(kind .. "At", at + every)
					task.spawn(HallService.specialBus, kind)
				end
			end
			local recessAt = workspace:GetAttribute("RecessAt")
			if t >= recessAt then
				workspace:SetAttribute("RecessUntil", recessAt + RECESS_LEN)
				workspace:SetAttribute("RecessAt", recessAt + RECESS_EVERY)
				Remotes.Announce:FireAllClients("RECESS! LUCK x2 FOR 60s", Color3.fromRGB(61, 220, 106))
				Remotes.Sfx:FireAllClients("SchoolBell")
				Signals.fire("recess")
			end
		end
	end)
end

return HallService
