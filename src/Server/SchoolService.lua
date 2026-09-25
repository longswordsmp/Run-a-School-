-- ServerScriptService.Server.SchoolService
-- The player's own school: profile snapshot for the UI, naming, settings.
local TextService = game:GetService("TextService")

local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)
local Actions = require(script.Parent.Actions)
local Signals = require(script.Parent.Signals)

local SchoolService = {}

function SchoolService.snapshot(player, p)
	local index = {}
	for key in p.index do table.insert(index, key) end
	local tier = PlotService.tierOf(p)
	-- floor numbers as strings: a remote drops sparse integer keys
	local teachers = {}
	for floor, t in p.teachers do teachers[tostring(floor)] = t.id end
	return {
		ok = true,
		cash = p.cash,
		tier = p.tier,
		tierName = tier.name,
		stars = p.stars,
		mult = PlotService.tierMult(p),
		rows = p.rows,
		floors = tier.floors,
		desks = PlotService.deskCount(p),
		upgrades = p.upgrades,
		index = index,
		schoolName = PlotService.schoolName(player),
		settings = p.settings,
		stats = p.stats,
		tutorial = p.tutorial,
		supplies = p.supplies,
		builds = p.builds,
		teachers = teachers,
		iq = player:GetAttribute("IQ") or 100,
		rep = player:GetAttribute("Rep") or 0,
	}
end

Actions.register("profile", function(player, p)
	return SchoolService.snapshot(player, p)
end)

Actions.register("nameSchool", function(player, p, name)
	if type(name) ~= "string" then return { ok = false, err = "Bad name" } end
	name = name:gsub("^%s+", ""):gsub("%s+$", "")
	if #name < 3 or #name > 28 then return { ok = false, err = "Use 3 to 28 characters" } end
	local ok, filtered = pcall(function()
		local result = TextService:FilterStringAsync(name, player.UserId)
		return result:GetNonChatStringForBroadcastAsync()
	end)
	if not ok then return { ok = false, err = "Could not check the name, try again" } end
	p.schoolName = filtered
	PlotService.refreshSign(player)
	Remotes.Notify:FireClient(player, "Your school is now " .. filtered .. "!", "good")
	Remotes.Sfx:FireClient(player, "DrumRoll")
	Signals.fire("nameSchool", player)
	return { ok = true, name = filtered }
end)

Actions.register("setting", function(player, p, key, value)
	if key ~= "music" and key ~= "sfx" then return { ok = false } end
	p.settings[key] = value == true
	return { ok = true }
end)

return SchoolService
