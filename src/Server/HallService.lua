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
local function SchoolBuilderRoute(slot)
	return require(script.Parent.SchoolBuilder).route(slot)
end

local hall = workspace:FindFirstChild("Hall") or Instance.new("Folder")
hall.Name = "Hall"
hall.Parent = workspace

local map = workspace:WaitForChild("Map")
local path = map.HallPath
local FLOOR_Y = 0.65
local RECESS_EVERY, RECESS_LEN = 900, 60

-- extra luck multipliers (server luck products, admin luck): fn() -> number
HallService.luckHooks = {}
-- per-player luck multipliers (the 2x Luck pass): fn(player) -> number
HallService.playerLuckHooks = {}
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
		if root and math.abs(root.Position.Z) < 20 and root.Position.X > path.Start.Position.X - 30 and root.Position.X < path.End.Position.X + 5 then
			local mine = UpgradeService.luck(p) * (p.luckMult or 1)
			for _, hook in HallService.playerLuckHooks do
				mine *= hook(player)
			end
			best = math.max(best, mine)
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
	local reserved = model:GetAttribute("ReservedFor")
	if reserved and reserved ~= Data.hostOf(player).UserId then
		Remotes.Notify:FireClient(player, "That kid is reserved for someone else!", "bad")
		return
	end
	local price = model:GetAttribute("Free") and 0 or def.price
	if p.cash < price then
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
	if price > 0 and not Data.addCash(player, -price) then return end
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
	if model:GetAttribute("OnBench") then Signals.fire("benchEnroll", player, def) end
	if model:GetAttribute("Bus") then Signals.fire("busEnroll", player, model:GetAttribute("Bus"), def) end

	Factory.setMode(model, "walking", Data.hostOf(player).DisplayName)
	Walkers.stop(model)
	Factory.play(model, "walk")
	local points
	if model:GetAttribute("OnBench") then
		-- from the Waiting Bench: onto the front walk, then the normal route in
		local so = Factory.standOffset(model)
		local route = SchoolBuilderRoute(slot)
		table.remove(route, 1) -- (the gate: we are already inside)
		table.insert(route, 1, Vector3.new(-12.5, 0.5, plot.Origin.CFrame:PointToObjectSpace(model.PrimaryPart.Position).Z))
		table.insert(route, 2, Vector3.new(0, 0.5, 56))
		points = PlotService.worldPoints(plot, route, so)
	else
		points = PlotService.pathTo(plot, slot, model.PrimaryPart.Position, Factory.standOffset(model))
	end
	local entry = p.students[slot]
	Walkers.walk(model, points, 16, function()
		model:Destroy()
		local e = p.students[slot]
		if e and e == entry and e.arriving and PlotService.getPlot(player) == plot then
			local seatedModel = PlotService.place(player, slot)
			PlotService.updateIncome(player)
			if seatedModel then Factory.emote(seatedModel, "cheer") end
		end
	end, { flat = false })
end

-- put one student on the carpet; from = optional start position (a special bus door)
function HallService.spawnOne(forceRarity, forceId, weights, from, quiet)
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
	if from then
		-- off a bus: out of the door, facing away from the bus
		hrp.CFrame = CFrame.lookAt(Vector3.new(origin.X, y, origin.Z), Vector3.new(origin.X, y, origin.Z - 5))
	else
		hrp.CFrame = CFrame.lookAt(Vector3.new(origin.X, y, origin.Z), Vector3.new(start.X + 1, y, z))
	end
	model.Parent = hall
	Factory.play(model, "walk")

	-- the whole server hears about the rare ones
	local rarity = Config.RarityById[def.rarity]
	if quiet then
		-- an invited kid (Alumni Hall): nobody else can enroll them, so no server-wide alert
	elseif rarity.order >= 7 then
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
	if from then
		-- clear of the bus, round its front, then into the carpet lane (the bus stands on the lane)
		table.insert(pts, Vector3.new(from.X, 0, from.Z - 3.2))
		table.insert(pts, Vector3.new(start.X - 4, 0, from.Z - 3.2))
		table.insert(pts, Vector3.new(start.X + 2, 0, z))
	end
	table.insert(pts, Vector3.new(finish.X, 0, z))
	Walkers.walk(model, pts, Config.WalkSpeed, function()
		model:Destroy()
	end)
	return model
end

---------------------------------------------------------------------------
-- the bus stop: every bus pulls into the same spot (where the regular bus is parked in the map),
-- door towards the shelter, kids step off onto the carpet.
--   the regular bus  pulls in, drops at most Config.BusCapacity kids (72), backs out; the next one
--                    comes a few seconds later
--   event buses      (Late, Field Trip, Honor Roll, Principal's Pick, Lucky, Welcome) queue for the
--                    stop: the regular bus leaves early to make room, the event bus pulls in, drops
--                    its kids and backs out, then the regular bus comes back
---------------------------------------------------------------------------
local regularBus = map.SchoolBus
local busTemplate = regularBus
local STOP = regularBus:GetPivot() -- (the map's parked bus: this is the stop)
local OFFSTAGE = STOP - Vector3.new(190, 0, 0) -- down the street to the west, where buses come from
local HIDDEN = STOP - Vector3.new(0, 400, 0)
local CAPACITY = Config.BusCapacity or 72
local BUS_GAP = 6 -- seconds between one regular bus leaving and the next pulling in
local queue = {} -- event buses waiting for the stop: { kind, byName }
local holdUntil = 0 -- an event bus is due: the regular bus clears the stop
HallService.CAPACITY = CAPACITY

local function makeBus(label, color, textColor)
	local bus = busTemplate:Clone()
	bus.Name = label:gsub(" ", "")
	local counter = bus:FindFirstChild("KidsLeft", true)
	if counter then counter:Destroy() end
	for _, n in { "Body", "Hood" } do
		for _, part in bus:GetChildren() do
			if part.Name == n then part.Color = color end
		end
	end
	-- the name on both sides (and the front and back signs keep saying SCHOOL BUS)
	for _, sign in bus:GetChildren() do
		if sign.Name == "Sign" then
			sign.Color = color
			for _, g in sign:GetChildren() do
				if g:IsA("SurfaceGui") then
					g.Label.Text = label
					g.Label.BackgroundColor3 = color
					if textColor then g.Label.TextColor3 = textColor end
				end
			end
		end
	end
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

-- where a kid steps off a bus parked at the stop: just outside its front door, on the step
local function doorSpot(bus)
	local door = bus:FindFirstChild("Door")
	-- (the doorway, not the panel: once the door slides open the panel sits 3 studs further back)
	local rel = door and door:GetAttribute("ClosedRel")
	local p = rel and (bus:GetPivot() * rel).Position or door and door.Position or STOP.Position
	return Vector3.new(p.X, 0, p.Z - 1.4)
end

-- the front door slides open (towards the back of the bus) while it unloads, and shuts to leave
local TweenService = game:GetService("TweenService")
local DOOR_SLIDE = Vector3.new(-3.3, 0, -0.35)
local function setDoor(bus, open)
	local pivot = bus:GetPivot()
	for _, p in bus:GetChildren() do
		if p:IsA("BasePart") and (p.Name == "Door" or p.Name == "DoorGlass") then
			local rel = p:GetAttribute("ClosedRel")
			if not rel then
				rel = pivot:ToObjectSpace(p.CFrame)
				p:SetAttribute("ClosedRel", rel)
			end
			local shut = pivot * rel
			TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { CFrame = open and (shut + DOOR_SLIDE) or shut }):Play()
		end
	end
	task.wait(0.4)
end

-- the counter over the regular bus: how many kids are still on board
local counterLabel
do
	local roof = regularBus.PrimaryPart or regularBus:FindFirstChildWhichIsA("BasePart")
	local bb = Instance.new("BillboardGui")
	bb.Name = "KidsLeft"
	bb.Size = UDim2.fromOffset(210, 44)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 9, 0)
	bb.MaxDistance = 140
	bb.LightInfluence = 0
	bb.Parent = roof
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = Color3.fromRGB(255, 214, 51)
	t.Font = Enum.Font.LuckiestGuy
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(30, 26, 40)
	t.Text = ""
	t.Parent = bb
	Instance.new("UICorner", t).CornerRadius = UDim.new(0, 12)
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = t
	counterLabel = t
end
local function setCounter(n)
	if counterLabel then
		counterLabel.Parent.Enabled = n ~= nil
		counterLabel.Text = n and ("\u{1F68C} %d KIDS ON BOARD"):format(n) or ""
	end
end

local BUSES = {
	LateBus = { label = "LATE BUS", color = Color3.fromRGB(255, 120, 30) },
	FieldTrip = { label = "FIELD TRIP", color = Color3.fromRGB(150, 80, 255) },
	Lucky = { label = "LUCKY BUS", color = Color3.fromRGB(60, 220, 110) },
	HonorBus = { label = "HONOR ROLL", color = Color3.fromRGB(255, 200, 40) },
	Welcome = { label = "WELCOME BUS", color = Color3.fromRGB(80, 190, 255) },
	Pick = { label = "PRINCIPAL'S PICK", color = Color3.fromRGB(30, 30, 36), text = Color3.fromRGB(255, 215, 90) },
}
-- the Welcome Bus brings the six starter kids when a new principal arrives
local WELCOME = { count = 6, ids = { "UntiedTyler", "GlueStickGus", "DoodleDot", "LunchboxLucy", "PajamaPete", "HiccupHank" } }

-- an event bus at the stop: in, its kids off, out (the stop is free when this runs)
local function runEventBus(kind, byName)
	local spec = kind == "FieldTrip" and Config.FieldTrip or kind == "HonorBus" and Config.HonorBus or kind == "Welcome" and WELCOME
		or kind == "Pick" and Config.PrincipalsPick or Config.LateBus
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
	local bus = makeBus(label, color, style.text)
	bus:PivotTo(OFFSTAGE)
	bus.Parent = workspace
	Remotes.Sfx:FireAllClients("BusHorn")
	drive(bus, OFFSTAGE, STOP, 4)
	if byName then
		Remotes.Notify:FireAllClients(byName .. " called a " .. label .. "!", "steal")
	end
	local from = doorSpot(bus)
	setDoor(bus, true)
	for i = 1, spec.count or 6 do
		local w = (i == 1 and spec.first) or weights
		local kid
		if spec.ids then
			kid = HallService.spawnOne(nil, spec.ids[i], nil, from)
		else
			kid = HallService.spawnOne(nil, nil, w, from)
		end
		-- which bus they came off (chapter requests like "enroll a kid off the Honor Roll Bus")
		if kid then kid:SetAttribute("Bus", kind) end
		task.wait(0.6)
	end
	task.wait(1.5)
	setDoor(bus, false)
	-- back out the way it came
	drive(bus, STOP, OFFSTAGE, 4)
	bus:Destroy()
end

-- call an event bus: it queues for the stop (the regular bus makes room)
function HallService.specialBus(kind, byName)
	table.insert(queue, { kind = kind, byName = byName })
	holdUntil = math.max(holdUntil, os.clock() + 20)
end

-- an event bus is due soon (the 10 s warning): the regular bus starts clearing the stop now
function HallService.clearStop(secs)
	holdUntil = math.max(holdUntil, os.clock() + (secs or 15))
end

local function stopWanted()
	return #queue > 0 or os.clock() < holdUntil
end

-- the stop's loop: event buses first, then the regular bus with up to CAPACITY kids
local function busLoop()
	local parked = true -- (the map starts with the regular bus at the stop)
	while true do
		-- event buses, one at a time
		if #queue > 0 then
			if parked then
				setCounter(nil)
				Remotes.Sfx:FireAllClients("BusHorn")
				drive(regularBus, STOP, OFFSTAGE, 4)
				regularBus:PivotTo(HIDDEN)
				parked = false
			end
			local ev = table.remove(queue, 1)
			local ok, err = pcall(runEventBus, ev.kind, ev.byName)
			if not ok then warn("[Hall] event bus failed:", err) end
			if #queue == 0 then holdUntil = 0 end
			continue
		end
		if os.clock() < holdUntil then
			-- waiting for the event bus that was announced
			if parked then
				setCounter(nil)
				drive(regularBus, STOP, OFFSTAGE, 4)
				regularBus:PivotTo(HIDDEN)
				parked = false
			end
			task.wait(0.3)
			continue
		end
		-- the regular bus
		if not parked then
			regularBus:PivotTo(OFFSTAGE)
			Remotes.Sfx:FireAllClients("BusHorn")
			drive(regularBus, OFFSTAGE, STOP, 4)
			parked = true
		end
		local left = CAPACITY
		setCounter(left)
		setDoor(regularBus, true)
		while left > 0 and not stopWanted() do
			if #hall:GetChildren() < Config.MaxHallStudents then
				local ok, m = pcall(HallService.spawnOne, nil, nil, nil, doorSpot(regularBus))
				if not ok then warn("[Hall] spawn failed:", m) end
				if ok and m then
					left -= 1
					setCounter(left)
				end
			end
			task.wait(Config.SpawnInterval / (HallService.recessActive() and 1.5 or 1))
		end
		-- empty (or making room): back out, and the next one comes after a short gap
		setCounter(nil)
		task.wait(0.8)
		setDoor(regularBus, false)
		Remotes.Sfx:FireAllClients("BusHorn")
		drive(regularBus, STOP, OFFSTAGE, 4)
		regularBus:PivotTo(HIDDEN)
		parked = false
		if not stopWanted() then task.wait(BUS_GAP) end
	end
end

function HallService.start()
	-- the bus stop (the regular bus and the event buses)
	task.spawn(function()
		while true do
			local ok, err = pcall(busLoop)
			warn("[Hall] bus loop stopped:", err)
			task.wait(2)
			if not ok then
				-- (put the regular bus back at the stop and start again)
				pcall(function() regularBus:PivotTo(STOP) end)
			end
		end
	end)

	-- schedule: late bus, field trip, recess (times published for the HUD)
	-- every schedule runs on the wall clock, so every server agrees ("Honor Roll at :07:30")
	local now = workspace:GetServerTimeNow()
	local function nextAt(every, offset)
		return offset + every * math.ceil((now - offset) / every)
	end
	workspace:SetAttribute("LateBusAt", nextAt(Config.LateBus.every, Config.LateBus.offset or 0))
	workspace:SetAttribute("FieldTripAt", nextAt(Config.FieldTrip.every, Config.FieldTrip.offset or 750))
	workspace:SetAttribute("HonorBusAt", nextAt(Config.HonorBus.every, Config.HonorBus.offset))
	workspace:SetAttribute("PickAt", nextAt(Config.PrincipalsPick.every, Config.PrincipalsPick.offset))
	workspace:SetAttribute("RecessAt", nextAt(RECESS_EVERY, 0))
	workspace:SetAttribute("RecessUntil", 0)
	task.spawn(function()
		local warned = {}
		while true do
			task.wait(0.5)
			local t = workspace:GetServerTimeNow()
			-- the Pick gets a five-minute warning for the whole server
			local pickAt = workspace:GetAttribute("PickAt")
			if pickAt - t <= 300 and not warned.Pick5 then
				warned.Pick5 = true
				Remotes.Announce:FireAllClients("THE PRINCIPAL'S PICK ARRIVES IN 5 MINUTES! (PRODIGY OR SECRET)", Color3.fromRGB(255, 215, 90))
				Remotes.Sfx:FireAllClients("BrassBell")
			end
			for _, kind in { "LateBus", "FieldTrip", "HonorBus", "Pick" } do
				local at = workspace:GetAttribute(kind .. "At")
				local label = "THE " .. BUSES[kind].label .. " BUS"
				if kind == "LateBus" then label = "THE LATE BUS" end
				if at - t <= 10 and not warned[kind] then
					warned[kind] = true
					Remotes.Announce:FireAllClients(label .. " ARRIVES IN 10s!", BUSES[kind].text or BUSES[kind].color)
					-- the regular bus makes room at the stop
					HallService.clearStop(16)
				end
				if t >= at then
					warned[kind] = nil
					local every = (kind == "FieldTrip" and Config.FieldTrip or kind == "HonorBus" and Config.HonorBus
						or kind == "Pick" and Config.PrincipalsPick or Config.LateBus).every
					if kind == "Pick" then warned.Pick5 = nil end
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
