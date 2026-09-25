-- ServerScriptService.Server.CampusService
-- The upgrades players work for, all kept on review:
--   School Supplies  -> School IQ (tuition x IQ/100), shown on every desk
--   Teachers         -> a tuition boost for the students on their floor, standing at the board
--   School Builder   -> Reputation (tuition x (1 + rep/100)), built around the campus
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local SchoolBuilder = require(script.Parent.SchoolBuilder)
local TeacherService = require(script.Parent.TeacherService)
local Remotes = require(script.Parent.Remotes)
local Actions = require(script.Parent.Actions)
local Signals = require(script.Parent.Signals)

local CampusService = {}

function CampusService.iq(p)
	local iq = 100
	for id in p.supplies or {} do
		local s = Config.SupplyById[id]
		if s then iq += s.iq end
	end
	return iq
end

function CampusService.rep(p)
	local rep = 0
	for id in p.builds or {} do
		local b = Config.BuildById[id]
		if b then rep += b.rep end
	end
	return rep
end

function CampusService.teacherMult(p, floor)
	local t = p.teachers and p.teachers[floor]
	local def = t and Config.TeacherById[t.id]
	return def and def.mult or 1
end

local function sync(player, p)
	player:SetAttribute("IQ", CampusService.iq(p))
	player:SetAttribute("Rep", CampusService.rep(p))
end

local function pay(player, p, price)
	if p.cash < price then
		Remotes.Sfx:FireClient(player, "Error")
		return false
	end
	return Data.addCash(player, -price)
end

Actions.register("buySupply", function(player, p, id)
	local def = Config.SupplyById[id]
	if not def then return { ok = false, err = "Unknown supply" } end
	if p.supplies[id] then return { ok = false, err = "Already stocked" } end
	if p.tier < def.tier then return { ok = false, err = "Unlocks at " .. Config.Tiers[def.tier].name } end
	if not pay(player, p, def.price) then return { ok = false, err = "Not enough cash" } end
	p.supplies[id] = true
	local plot = PlotService.getPlot(player)
	if plot then SchoolBuilder.decorate(plot, p.supplies) end
	sync(player, p)
	PlotService.updateIncome(player)
	Remotes.Sfx:FireClient(player, "Upgrade")
	Remotes.Announce:FireClient(player, ("SCHOOL IQ %d!"):format(CampusService.iq(p)), Color3.fromRGB(120, 200, 255))
	Signals.fire("supply", player, def)
	return { ok = true, iq = CampusService.iq(p) }
end)

Actions.register("buyBuild", function(player, p, id)
	local def = Config.BuildById[id]
	if not def then return { ok = false, err = "Unknown item" } end
	if p.builds[id] then return { ok = false, err = "Already built" } end
	if p.tier < def.tier then return { ok = false, err = "Unlocks at " .. Config.Tiers[def.tier].name } end
	if not pay(player, p, def.price) then return { ok = false, err = "Not enough cash" } end
	p.builds[id] = true
	local plot = PlotService.getPlot(player)
	if plot then SchoolBuilder.setItems(plot, p.builds, id) end
	sync(player, p)
	PlotService.updateIncome(player)
	Remotes.Sfx:FireClient(player, "Buy")
	Remotes.Announce:FireClient(player, def.name:upper() .. " BUILT!", Color3.fromRGB(110, 230, 120))
	Signals.fire("build", player, def)
	return { ok = true, rep = CampusService.rep(p) }
end)

Actions.register("hireTeacher", function(player, p, floor, id)
	local def = Config.TeacherById[id]
	floor = tonumber(floor)
	if not def or not floor or floor ~= math.floor(floor) then return { ok = false, err = "Unknown teacher" } end
	if floor < 1 or floor > PlotService.floorsOf(p) then return { ok = false, err = "You don't have that floor yet" } end
	if p.tier < def.tier then return { ok = false, err = "Unlocks at " .. Config.Tiers[def.tier].name } end
	if CampusService.teacherMult(p, floor) >= def.mult then return { ok = false, err = "Floor " .. floor .. " already has a better teacher" } end
	if not pay(player, p, def.price) then return { ok = false, err = "Not enough cash" } end
	p.teachers[floor] = { id = id }
	TeacherService.refresh(player)
	PlotService.updateIncome(player)
	Remotes.Sfx:FireClient(player, "BrassBell")
	Remotes.Announce:FireClient(player, def.name:upper() .. " HIRED!", Color3.fromRGB(255, 190, 90))
	Signals.fire("hire", player, def, floor)
	return { ok = true }
end)

-- the Marquee letter board shows the school's name, live tuition and the latest brag
local brag = {}
Signals.on("enroll", function(player, def)
	local order = Config.RarityById[def.rarity].order
	if order >= 5 then brag[player] = ("CONGRATS TO OUR NEW %s!"):format(def.rarity:upper()) end
end)
local function refreshMarquees()
	for player, p in Data.all() do
		if p.builds and p.builds.Marquee then
			local plot = PlotService.getPlot(player)
			local school = plot and plot:FindFirstChild("School")
			local items = school and school:FindFirstChild("Items")
			local m = items and items:FindFirstChild("Marquee")
			local board = m and m:FindFirstChild("Board")
			local g = board and board:FindFirstChildOfClass("SurfaceGui")
			local label = g and g:FindFirstChild("MarqueeText")
			if label then
				label.Text = ("%s\n%s/s TUITION\n%s"):format(PlotService.schoolName(player):upper(), Config.formatCash(player:GetAttribute("IncomePerSec") or 0), brag[player] or "ENROLL TODAY!")
			end
		end
	end
end

function CampusService.start()
	task.spawn(function()
		while true do
			task.wait(5)
			pcall(refreshMarquees)
		end
	end)
	table.insert(PlotService.multHooks, function(player, p, e, slot)
		return CampusService.iq(p) / 100 * (1 + CampusService.rep(p) / 100) * CampusService.teacherMult(p, PlotService.slotFloor(slot))
	end)
	table.insert(PlotService.rebuildHooks, function(player)
		local p = Data.get(player)
		if p then sync(player, p) end
	end)
end

return CampusService
