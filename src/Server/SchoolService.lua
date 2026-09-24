-- ServerScriptService.Server.SchoolService
-- Client requests about the player's own school: profile snapshot, naming, desk upgrades.
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)

local SchoolService = {}
local lastCall = {}

local function snapshot(player)
	local p = Data.get(player)
	local index = {}
	for key in p.index do table.insert(index, key) end
	local nextDesk
	for _, up in Config.DeskUpgrades do
		if up.desks > p.desks then
			nextDesk = up
			break
		end
	end
	return {
		cash = p.cash,
		desks = p.desks,
		nextDesk = nextDesk,
		schoolName = PlotService.schoolName(player),
		rebirths = p.rebirths,
		index = index,
	}
end

local handlers = {}

function handlers.profile(player)
	return snapshot(player)
end

function handlers.nameSchool(player, name)
	if type(name) ~= "string" then return { ok = false, err = "Bad name" } end
	name = name:gsub("^%s+", ""):gsub("%s+$", "")
	if #name < 3 or #name > 28 then return { ok = false, err = "Use 3 to 28 characters" } end
	local ok, filtered = pcall(function()
		local result = TextService:FilterStringAsync(name, player.UserId)
		return result:GetNonChatStringForBroadcastAsync()
	end)
	if not ok then return { ok = false, err = "Could not check the name, try again" } end
	local p = Data.get(player)
	p.schoolName = filtered
	PlotService.refreshSign(player)
	Remotes.Notify:FireClient(player, "Your school is now " .. filtered .. "!", "good")
	return { ok = true, name = filtered }
end

function handlers.buyDesks(player)
	local p = Data.get(player)
	local nextDesk
	for _, up in Config.DeskUpgrades do
		if up.desks > p.desks then
			nextDesk = up
			break
		end
	end
	if not nextDesk then return { ok = false, err = "All desks unlocked" } end
	if not Data.addCash(player, -nextDesk.price) then return { ok = false, err = "Not enough cash!" } end
	p.desks = nextDesk.desks
	Data.sync(player)
	PlotService.applyDesks(player)
	Remotes.Notify:FireClient(player, "New desks! You now have " .. p.desks .. ".", "good")
	return { ok = true, profile = snapshot(player) }
end

function SchoolService.handle(player, action, ...)
	-- light rate limit: 10 calls per second per player
	local now = os.clock()
	local t = lastCall[player] or { n = 0, at = now }
	if now - t.at > 1 then
		t.n, t.at = 0, now
	end
	t.n += 1
	lastCall[player] = t
	if t.n > 10 then return { ok = false, err = "Slow down" } end
	local h = handlers[action]
	if not h or not Data.get(player) then return { ok = false, err = "Unknown action" } end
	return h(player, ...)
end

return SchoolService
