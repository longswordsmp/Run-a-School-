-- ServerScriptService.Server.BusDepotService
-- The MAGIC BUS (tomas, 2026-09-27: "like Pet Simulator X's eggs ... bought with Robux, below the boost
-- in the Store ... the Magic Bus just for now, which has really good students: the worst does 1M a
-- second and the ??? 1B, and super rare"). Its seven kids (Config.Buses / Config.BusStudents) come
-- only from it. Buying 1, 3, 10 or 50 (Config.Products MagicBus1 .. MagicBus50) rolls a kid per bus on
-- the bus's odds and the client plays the reveal (BusReveal.client, Push "busOpen").
-- Where a kid goes: an empty desk; with none left, the seat of your weakest kid if it earns more
-- (that one sold for half its price, as the Sell button would); otherwise it's sold for half its own.
-- A Bus Luck pass doubles the three rarest. A prompt at the bus shelter opens the Store on the bus.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Actions = require(script.Parent.Actions)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)

local BusDepotService = {}

local function has(player, pass)
	return player:GetAttribute("Pass_" .. pass) == true
end

-- the kid a bus drops off (lucky: the three rarest twice as likely)
local function roll(bus, lucky)
	local w = table.clone(bus.odds or Config.BusOdds)
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

-- open `count` of a bus for `player` (paid for already: MonetizationService) -> the results
function BusDepotService.open(player, busId, count)
	local bus = Config.BusById[busId]
	if not bus then return nil end
	local host = Data.hostOf(player)
	local hp = Data.get(host)
	if not hp or not PlotService.getPlot(host) then return nil end
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
	-- (the rarest are news for the whole server, once the reveal has had time to play)
	task.delay(4, function()
		for _, r in results do
			if r.tier >= #bus.kids - 1 then
				local def = Config.StudentById[r.id]
				Remotes.Notify:FireAllClients(("\u{1F68C} %s got %s from the %s!"):format(player.DisplayName, def.name, bus.name), "good")
			end
		end
	end)
	return { bus = bus.id, count = count, results = results }
end

-- the odds the Store shows (with Bus Luck if they have it)
Actions.register("busOdds", function(player)
	return { ok = true, lucky = has(player, "BusLuck") }
end)

---------------------------------------------------------------------------
-- a MAGIC BUS sign and a prompt at the bus shelter on Recess Row: opens the Store on the bus
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
	board.Color = Color3.fromRGB(150, 80, 235)
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
		t.Text = "\u{2728} MAGIC BUS"
		t.TextColor3 = Color3.fromRGB(255, 230, 90)
		t.Parent = g
		local s = Instance.new("UIStroke")
		s.Thickness = 3
		s.Parent = t
	end
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "See the Magic Bus"
	pp.ObjectText = "Magic Bus"
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 14
	pp.RequiresLineOfSight = false
	pp.Parent = board
	pp.Triggered:Connect(function(player)
		Remotes.Push:FireClient(player, "openPanel", { name = "Store", tab = 4 })
	end)
end

function BusDepotService.start()
	task.spawn(depotSign)
end

return BusDepotService
