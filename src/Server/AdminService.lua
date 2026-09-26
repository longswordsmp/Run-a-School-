-- ServerScriptService.Server.AdminService
-- The admin panel's commands (Menus.client "Admin", only for EventService.isAdmin players; every
-- command re-checks on the server). Action "admin" (cmd, a, b):
--   me        cash / setCash / candy / tickets (any amount: "250k", "3.5b", "1e12"), tier, skip the
--             tutorial, unlock everything (every area, every side-bar button, all gear), a student
--             onto your bench, max desks
--   move      speed, jump, fly and noclip (the client flies: AdminTools.client), teleport to a place
--             or a player, bring a player
--   players   kick, ban (Roblox's own ban, for the whole game; a saved list as a fallback), unban,
--             give someone cash
--   world     buses, events, spawns, money rain, server luck, recess, time of day, a server message
--   story     jump to a chapter, play a cutscene
-- Admins also walk into locked areas (AreaService skips the "AdminBypass" attribute).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local TextService = game:GetService("TextService")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage.Shared.Config)
local Places = require(ReplicatedStorage.Shared.Places)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Actions = require(script.Parent.Actions)

local AdminService = {}

local function svc(name) return require(script.Parent[name]) end

-- "250k", "3.5b", "1e12", "1,000,000" -> a number (nil if it isn't one)
local SUFFIX = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, qd = 1e15, qn = 1e18 }
function AdminService.amount(v)
	if type(v) == "number" then return v == v and v or nil end
	if type(v) ~= "string" then return nil end
	local s = v:lower():gsub("[,%s%$]", "")
	local num, suf = s:match("^([%d%.e%+%-]+)(%a*)$")
	local n = tonumber(num)
	if not n then return nil end
	if suf ~= "" then
		if not SUFFIX[suf] then return nil end
		n *= SUFFIX[suf]
	end
	return n
end

local function target(userId)
	userId = tonumber(userId)
	return userId and Players:GetPlayerByUserId(userId)
end

local function root(player)
	return player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function tell(player, text, kind)
	Remotes.Notify:FireClient(player, text, kind or "info")
end

-- the saved ban list (used when Roblox's own ban isn't available, e.g. in Studio without API access)
local banStore
pcall(function() banStore = DataStoreService:GetDataStore("AdminBans") end)
local function savedBan(userId)
	if not banStore then return nil end
	local ok, v = pcall(function() return banStore:GetAsync(tostring(userId)) end)
	return ok and v or nil
end

---------------------------------------------------------------------------
-- the commands: fn(admin, a, b) -> true / false, or a string to show
---------------------------------------------------------------------------
local CMD = {}

-- me
CMD.cash = function(player, a)
	local n = AdminService.amount(a)
	if not n then return "Not a number" end
	Data.addCash(player, math.clamp(n, -1e18, 1e18))
	return true
end
CMD.setCash = function(player, a)
	local n = AdminService.amount(a)
	local p = Data.get(player)
	if not n or not p then return "Not a number" end
	p.cash = math.clamp(n, 0, 1e18)
	Data.sync(player)
	return true
end
CMD.candy = function(player, a)
	local n = AdminService.amount(a)
	local p = Data.get(player)
	if not n or not p then return "Not a number" end
	p.candy = math.max(0, (p.candy or 0) + n)
	player:SetAttribute("Candy", p.candy)
	return true
end
CMD.tickets = function(player, a)
	local n = AdminService.amount(a)
	if not n then return "Not a number" end
	svc("TicketService").debugGive(player, math.floor(n))
	return true
end
CMD.tier = function(player, a)
	local n = math.clamp(math.floor(tonumber(a) or 1), 1, #Config.Tiers)
	local p = Data.get(player)
	if not p then return false end
	p.tier = n
	Data.sync(player)
	local PlotService = svc("PlotService")
	PlotService.applyFloors(player)
	PlotService.updateIncome(player)
	return true
end
CMD.skipTutorial = function(player)
	local p = Data.get(player)
	if not p then return false end
	p.tutorial = #Config.Tutorial + 1
	p.tutorialId = "done"
	p.quests.progress = 0
	svc("QuestService").push(player)
	svc("UnlockService").refresh(player)
	svc("Signals").fire("questDone", player)
	return true
end
CMD.unlockAll = function(player)
	CMD.skipTutorial(player)
	local AreaService = svc("AreaService")
	for _, area in Config.Areas do AreaService.open(player, area.id, true) end
	AreaService.refresh(player, true)
	local p = Data.get(player)
	p.unlocked = p.unlocked or {}
	for _, r in svc("UnlockService").Rules do
		p.unlocked[r.name] = true
		player:SetAttribute("UI_" .. r.name, true)
	end
	CMD.gearAll(player)
	return true
end
CMD.gearAll = function(player)
	local GearService = svc("GearService")
	for _, g in Config.Gear do
		pcall(GearService.give, player, g.id, g.kind == "use" and Config.GearUse.max or 1)
	end
	pcall(GearService.refreshTools, player)
	return true
end
CMD.student = function(player, a)
	local def = Config.StudentById[a]
	if not def then
		-- a rarity: any kid of it
		local pool = {}
		for _, s in Config.Students do
			if type(a) == "string" and s.rarity:lower() == a:lower() then table.insert(pool, s) end
		end
		def = pool[math.random(math.max(#pool, 1))]
	end
	if not def then return "No such student or rarity" end
	local ok = svc("LetterService").deliver(player, def, true)
	return ok and true or "Your Waiting Bench is full"
end
CMD.maxDesks = function(player)
	local p = Data.get(player)
	if not p then return false end
	local floors = svc("PlotService").floorsOf(p)
	for f = 1, 3 do p.rows[f] = f <= floors and 4 or 0 end
	svc("PlotService").rebuild(player)
	return true
end

-- move
CMD.speed = function(player, a)
	local n = tonumber(a)
	player:SetAttribute("AdminSpeed", n and n > 0 and math.clamp(n, 1, 400) or nil)
	svc("StealService").setSpeed(player)
	return true
end
CMD.jump = function(player, a)
	local n = tonumber(a)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return false end
	hum.UseJumpPower = true
	hum.JumpPower = n and math.clamp(n, 0, 500) or 50
	return true
end
CMD.fly = function(player)
	local on = not player:GetAttribute("AdminFly")
	player:SetAttribute("AdminFly", on or nil)
	player:SetAttribute("AdminBypass", (on or player:GetAttribute("AdminNoclip")) or nil)
	return true
end
CMD.noclip = function(player)
	local on = not player:GetAttribute("AdminNoclip")
	player:SetAttribute("AdminNoclip", on or nil)
	player:SetAttribute("AdminBypass", (on or player:GetAttribute("AdminFly")) or nil)
	return true
end
CMD.bypass = function(player)
	player:SetAttribute("AdminBypass", not player:GetAttribute("AdminBypass") or nil)
	return true
end
-- the places the panel lists (Places.spot names, plus a few by hand)
local SPOTS = {
	MySchool = function(player)
		local plot = svc("PlotService").getPlot(player)
		local spawn = plot and plot:FindFirstChild("Spawn")
		return spawn and spawn.Position + Vector3.new(0, 3, 0)
	end,
	BusStop = function() return Vector3.new(-330, 4, -12) end,
	Hub = function() return Vector3.new(-48, 4, -14) end,
	VexPrep = function() return Vector3.new(427, 4, -38) end,
	Pothole = function() return Vector3.new(470, 4, -2) end,
	Sewer = function() return Vector3.new(466, -44.5, -30) end,
	Factory = function() return Vector3.new(0, 4, 28) end,
	Lab = function() return Vector3.new(-190, 4, -250) end,
	HQLobby = function() return svc("TownIndustrial").ELEVATOR_TOP end,
	Industrial = function() return Vector3.new(575, 4, 0) end,
	Lair = function() return svc("TownIndustrial").ELEVATOR_BOTTOM end,
	BoardRoom = function()
		local room = workspace:FindFirstChild("BoardRoom")
		local mark = room and room:FindFirstChild("PlayerMark", true)
		return mark and mark.Position + Vector3.new(0, 3, 0)
	end,
}
AdminService.Spots = SPOTS
CMD.tp = function(player, a)
	local r = root(player)
	if not r then return false end
	local fn = SPOTS[a]
	local pos = fn and fn(player)
	if not pos then
		local place = Places.spot and Places.spot[a]
		pos = place and (typeof(place) == "Vector3" and place or place.pos)
		pos = pos and pos + Vector3.new(0, 4, 0)
	end
	if not pos then return "Unknown place" end
	player:SetAttribute("AdminBypass", true)
	player.Character:PivotTo(CFrame.new(pos))
	return true
end
CMD.tpTo = function(player, a)
	local other, r = target(a), root(player)
	local o = root(other)
	if not (r and o) then return "They're not here" end
	player:SetAttribute("AdminBypass", true)
	player.Character:PivotTo(o.CFrame * CFrame.new(0, 0, 4))
	return true
end
CMD.bring = function(player, a)
	local other, r = target(a), root(player)
	if not (other and r and root(other)) then return "They're not here" end
	other.Character:PivotTo(r.CFrame * CFrame.new(0, 0, -4))
	return true
end

-- players
CMD.kick = function(player, a, reason)
	local other = target(a)
	if not other then return "They're not here" end
	if other == player then return "That's you" end
	other:Kick(("Kicked by an admin%s"):format(reason and reason ~= "" and (": " .. tostring(reason)) or ""))
	return true
end
CMD.ban = function(player, a, reason)
	local userId = tonumber(a)
	if not userId then return "No such player" end
	if userId == player.UserId then return "That's you" end
	local why = reason and reason ~= "" and tostring(reason) or "Banned by an admin"
	local ok = pcall(function()
		Players:BanAsync({ UserIds = { userId }, ApplyToUniverse = true, Duration = -1, DisplayReason = why, PrivateReason = "Admin panel: " .. player.Name })
	end)
	if banStore then pcall(function() banStore:SetAsync(tostring(userId), { by = player.UserId, why = why, at = os.time() }) end) end
	local other = Players:GetPlayerByUserId(userId)
	if other then other:Kick(why) end
	return ok and true or "Banned (saved list: Roblox's ban isn't available here)"
end
CMD.unban = function(player, a)
	local userId = tonumber(a)
	if not userId then return "Not a user id" end
	pcall(function() Players:UnbanAsync({ UserIds = { userId }, ApplyToUniverse = true }) end)
	if banStore then pcall(function() banStore:RemoveAsync(tostring(userId)) end) end
	return true
end
CMD.giveCash = function(player, a, b)
	local other = target(a)
	local n = AdminService.amount(b)
	if not other or not n then return "Pick a player and an amount" end
	Data.addCash(other, math.clamp(n, -1e18, 1e18))
	tell(other, ("An admin gave you %s!"):format(Config.formatCash(n)), "good")
	return true
end

-- world
CMD.bus = function(player, a) return svc("EventService").admin.bus(player, a) end
CMD.event = function(player, a) return svc("EventService").admin.event(player, a) end
CMD.spawn = function(player, a) return svc("EventService").admin.spawn(player, a) end
CMD.money = function(player) return svc("EventService").admin.money(player) end
CMD.luck = function(player, a) return svc("EventService").admin.luck(player, a) end
CMD.recess = function(player) return svc("EventService").admin.recess(player) end
CMD.time = function(player, a)
	local n = tonumber(a)
	if not n then return "0-24" end
	Lighting.ClockTime = n % 24
	return true
end
CMD.say = function(player, a)
	if type(a) ~= "string" or a == "" then return "Type a message" end
	local ok, text = pcall(function()
		return TextService:FilterStringAsync(a:sub(1, 120), player.UserId):GetNonChatStringForBroadcastAsync()
	end)
	if not ok then return "Couldn't send that" end
	Remotes.Announce:FireAllClients(text, Color3.fromRGB(255, 255, 255))
	return true
end

-- story
CMD.chapter = function(player, a)
	local n = math.floor(tonumber(a) or 1)
	return svc("ChapterService").debugSet(player, n) ~= nil
end
CMD.cutscene = function(player, a)
	if type(a) ~= "string" then return false end
	if a == "Intro" then
		local spots = svc("HallService").welcomeSpots(svc("PlotService").getPlot(player))
		Remotes.Cutscene:FireClient(player, "Intro", {
			gate = spots and spots.gate, park = spots and spots.park.Position, side = spots and spots.side,
			stand = spots and spots.stand, row = spots and spots.wait[3]:Lerp(spots.wait[4], 0.5),
		})
		svc("HallService").welcomeBus(player)
	else
		Remotes.Cutscene:FireClient(player, a, {})
	end
	return true
end

Actions.register("admin", function(player, _, cmd, a, b)
	if not svc("EventService").isAdmin(player) then return { ok = false, err = "Admins only" } end
	local fn = type(cmd) == "string" and CMD[cmd]
	if not fn then return { ok = false, err = "Unknown command" } end
	local ok, res = pcall(fn, player, a, b)
	if not ok then
		warn("[Admin]", cmd, res)
		return { ok = false, err = "That failed" }
	end
	if type(res) == "string" then return { ok = false, err = res } end
	return { ok = res ~= false }
end)

-- the panel's player list
Actions.register("adminPlayers", function(player)
	if not svc("EventService").isAdmin(player) then return { ok = false } end
	local list = {}
	for _, pl in Players:GetPlayers() do
		local p = Data.get(pl)
		table.insert(list, { id = pl.UserId, name = pl.DisplayName, user = pl.Name, cash = p and p.cash or 0, tier = p and p.tier or 1 })
	end
	return { ok = true, players = list }
end)

function AdminService.start()
	-- the saved ban list, for games where Roblox's own ban isn't reachable
	Players.PlayerAdded:Connect(function(player)
		local ban = savedBan(player.UserId)
		if ban then player:Kick(type(ban) == "table" and ban.why or "You are banned from this game") end
	end)
	-- an admin's speed survives respawning
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.defer(function()
				if player:GetAttribute("AdminSpeed") then svc("StealService").setSpeed(player) end
			end)
		end)
	end)
end

return AdminService
