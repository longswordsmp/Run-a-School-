-- ServerScriptService.Server.BusDepotService
-- The BUS DEPOT (tomas, 2026-09-27, like Pet Simulator X's eggs): three buses, each with seven kids of
-- its own (Config.Buses / Config.BusStudents). Open 1, 10 or 100 of a bus for cash; each one rolls a
-- kid on the bus's odds (Config.BusOdds), and the client plays the bus pulling in and the kid getting
-- off (Menus: the Buses panel and the reveal).
-- Where a kid goes: an empty desk; with none left, it takes the seat of your weakest kid if it earns
-- more (that one is sold for half its price, as the Sell button would); otherwise it's sold for half
-- its price itself. So opening buses never loses a better kid.
-- The Robux extras (Config.Passes): Bus Luck (x2 on the three rarest), Triple Bus (OPEN 1 opens three),
-- Auto Bus (the client keeps opening one at a time).
-- A prompt at the bus shelter on Recess Row opens the panel too.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Actions = require(script.Parent.Actions)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)

local BusDepotService = {}

-- what n buses cost: a real bulk price (ten for the price of nine, a hundred for eighty-five), the
-- full price shown crossed out beside it
Config.BusBulk = Config.BusBulk or { [1] = 1, [3] = 3, [10] = 9, [100] = 85 }
function BusDepotService.cost(bus, n)
	return bus.price * (Config.BusBulk[n] or n)
end

local function has(player, pass)
	return player:GetAttribute("Pass_" .. pass) == true
end

-- the kid a bus drops off (lucky: the three rarest twice as likely)
local function roll(bus, lucky)
	local w = table.clone(Config.BusOdds)
	if lucky then
		for i = #w - 2, #w do w[i] *= 2 end
	end
	local total = 0
	for _, x in w do total += x end
	local r = math.random() * total
	for i, x in w do
		r -= x
		if r <= 0 then return Config.StudentById[bus.kids[i]], i end
	end
	return Config.StudentById[bus.kids[1]], 1
end

local function incomeOf(def, grade)
	local g = Config.GradeById[grade]
	return def.income * (g and g.mult or 1)
end

-- a desk for the kid (or the weakest kid's), else sold: -> fate, slot, replaced name, cash back
local function seat(host, p, def, grade)
	local slot = PlotService.freeSlot(host)
	if slot then
		p.students[slot] = { id = def.id, grade = grade, stored = 0 }
		PlotService.place(host, slot)
		return "desk", slot
	end
	local worst, worstInc
	for s, e in p.students do
		if not e.arriving and not e.carried and not e.away then
			local d = Config.StudentById[e.id]
			local inc = d and incomeOf(d, e.grade) or 0
			if not worst or inc < worstInc then worst, worstInc = s, inc end
		end
	end
	if worst and incomeOf(def, grade) > worstInc then
		local old = p.students[worst]
		local od = Config.StudentById[old.id]
		local gain = math.floor((od and od.price or 0) * Config.SellFraction) + math.floor(old.stored or 0)
		PlotService.remove(host, worst)
		Data.addCash(host, gain)
		p.students[worst] = { id = def.id, grade = grade, stored = 0 }
		PlotService.place(host, worst)
		return "replaced", worst, od and od.name, gain
	end
	local gain = math.floor(def.price * Config.SellFraction)
	Data.addCash(host, gain)
	return "sold", nil, nil, gain
end

local lastOpen = {}
Players.PlayerRemoving:Connect(function(player) lastOpen[player] = nil end)

Actions.register("openBus", function(player, p, busId, count)
	local bus = Config.BusById[busId]
	if not bus then return { ok = false, err = "No such bus" } end
	count = tonumber(count)
	if count ~= 1 and count ~= 10 and count ~= 100 then return { ok = false, err = "1, 10 or 100" } end
	-- (the Triple Bus pass: OPEN 1 opens three)
	if count == 1 and has(player, "TripleBus") then count = 3 end
	-- (a moment between opens: the reveal takes that long anyway)
	local now = os.clock()
	if lastOpen[player] and now - lastOpen[player] < 0.8 then return { ok = false, err = "Easy! One bus at a time" } end
	local host = Data.hostOf(player)
	local hp = Data.get(host)
	if not hp or not PlotService.getPlot(host) then return { ok = false, err = "You need a school first" } end
	local price = BusDepotService.cost(bus, count)
	if not Data.addCash(player, -price) then
		Remotes.Sfx:FireClient(player, "Error")
		return { ok = false, err = "Not enough cash", need = price }
	end
	lastOpen[player] = now
	local lucky = has(player, "BusLuck")
	local HallService = require(script.Parent.HallService)
	local results = {}
	for _ = 1, count do
		local def, tier = roll(bus, lucky)
		local _, grade = HallService.roll(nil, def.id)
		grade = grade or "Normal"
		local key = def.id .. "|" .. grade
		local first = not hp.index[key]
		hp.index[key] = true
		local fate, slot, oldName, gain = seat(host, hp, def, grade)
		table.insert(results, { id = def.id, grade = grade, tier = tier, fate = fate, slot = slot, old = oldName, gain = gain, first = first })
		if tier >= 5 then Signals.fire("busRare", host, def) end
	end
	PlotService.updateIncome(host)
	hp.stats.buses = (hp.stats.buses or 0) + count
	Remotes.Sfx:FireClient(player, "Buy")
	-- (the rarest ones are news for the whole server)
	for _, r in results do
		if r.tier >= 6 then
			local def = Config.StudentById[r.id]
			Remotes.Notify:FireAllClients(("%s got %s from the %s!"):format(player.DisplayName, def.name, bus.name), "good")
		end
	end
	return { ok = true, bus = bus.id, count = count, price = price, results = results }
end)

-- the Buses panel's odds (with Bus Luck if they have it)
Actions.register("busOdds", function(player)
	return { ok = true, lucky = has(player, "BusLuck"), triple = has(player, "TripleBus"), auto = has(player, "AutoBus") }
end)

---------------------------------------------------------------------------
-- a BUS DEPOT sign and a prompt at the bus shelter on Recess Row
---------------------------------------------------------------------------
local function depotSign()
	local map = workspace:FindFirstChild("Map")
	local shelter = map and map:FindFirstChild("BusShelter")
	if not shelter then return end
	local cf, size = shelter:GetBoundingBox()
	local board = Instance.new("Part")
	board.Name = "BusDepotSign"
	board.Anchored = true
	board.Size = Vector3.new(10, 3, 0.6)
	board.CFrame = CFrame.new(cf.Position + Vector3.new(0, size.Y / 2 + 2.2, 0))
	board.Color = Color3.fromRGB(255, 200, 40)
	board.Material = Enum.Material.SmoothPlastic
	board.Parent = shelter
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local g = Instance.new("SurfaceGui")
		g.Face = face
		g.PixelsPerStud = 40
		g.Parent = board
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.LuckiestGuy
		t.TextScaled = true
		t.Text = "\u{1F68C} BUS DEPOT"
		t.TextColor3 = Color3.fromRGB(40, 40, 50)
		t.Parent = g
	end
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Open buses"
	pp.ObjectText = "Bus Depot"
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 14
	pp.RequiresLineOfSight = false
	pp.Parent = board
	pp.Triggered:Connect(function(player)
		local p = Data.get(player)
		if not (p and p.unlocked and p.unlocked.Buses) then
			Remotes.Notify:FireClient(player, "The Bus Depot opens after your First Morning", "info")
			return
		end
		Remotes.Push:FireClient(player, "openPanel", { name = "Buses" })
	end)
end

function BusDepotService.start()
	task.spawn(depotSign)
end

return BusDepotService
