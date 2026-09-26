-- ServerScriptService.Server.CrewService
-- Co-op schools: up to Config.CrewMax principals in one server run ONE school together. It is the
-- host's school (their plot, their save); crew members play for it (DataService/PlotService alias
-- them to the host), and go back to their own school, paid for the time away, when they leave.
-- A crew starts from the loading screen (START A CO-OP SCHOOL / JOIN) or the Co-op panel in game.
--   roles      Config.Roles, any number of the same (four Presidents is fine):
--              President  10% back on everything they buy for the school
--              Teacher    +20% tuition for the school while they're inside it
--              Monitor    bonks stun twice as long, goons go down in one hit (StealService, RaidService)
--              Recruiter  carry stolen kids 20% faster, sneak quieter (StealService, Stealth)
--   crew jobs  while two or more run a school: one shared job at a time (Config.CrewJobs), paid to
--              the school, with a tuition boost for everyone
-- Attributes: SchoolId (everyone: the school's owner's UserId), Role and CrewSize (crew players),
-- CrewOpen (a host taking joiners). The Co-op panel gets the "crew" push.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)

local CrewService = {}

local crews = {} -- [host] = { host, open, members = { player... }, job, nextJobAt, jobIndex, boostUntil, teacherMult }
local roleOf = {} -- [player in a crew] = role id
local function now() return os.clock() end

---------------------------------------------------------------------------
-- school attributes: the school's numbers the HUD and menus read off the local player (Candy, Rep,
-- the chapter, unlocked buttons...). Services set them on whoever acted; in a crew every change is
-- copied to the others. A member's own values are put back when they go home.
---------------------------------------------------------------------------
local SCHOOL_ATTRS = {}
for _, n in { "Diplomas", "IQ", "Rep", "Candy", "Traps", "Chapter", "DailyReady", "Tickets", "Files", "FilesFound",
	"Rivalry", "Vials", "Luck", "NextGiftAt", "NextGiftText", "Raid", "AlarmUntil", "SugarUntil", "SlimeUntil" } do
	SCHOOL_ATTRS[n] = true
end
local function schoolAttr(name)
	return SCHOOL_ATTRS[name] or name:sub(1, 3) == "UI_" or name:sub(1, 7) == "Letter_"
end
local watchers = {} -- [player] = RBXScriptConnection
local snapshots = {} -- [member] = { [attr] = their own value before joining }

local function copyAll(from, to)
	for name, value in from:GetAttributes() do
		if schoolAttr(name) and to:GetAttribute(name) ~= value then to:SetAttribute(name, value) end
	end
end

local function watch(player)
	if watchers[player] then return end
	watchers[player] = player.AttributeChanged:Connect(function(name)
		if not schoolAttr(name) then return end
		local value = player:GetAttribute(name)
		for _, pl in Data.schoolPlayers(player) do
			if pl ~= player and pl:GetAttribute(name) ~= value then pl:SetAttribute(name, value) end
		end
	end)
end

local function unwatch(player)
	if watchers[player] then
		watchers[player]:Disconnect()
		watchers[player] = nil
	end
end

local function snapshot(member)
	local s = {}
	for name, value in member:GetAttributes() do
		if schoolAttr(name) then s[name] = value end
	end
	snapshots[member] = s
end

local function restore(member)
	local s = snapshots[member]
	snapshots[member] = nil
	if not s then return end
	for name in member:GetAttributes() do
		if schoolAttr(name) and s[name] == nil then member:SetAttribute(name, nil) end
	end
	for name, value in s do member:SetAttribute(name, value) end
end

local function crewOf(player)
	return crews[Data.hostOf(player)]
end
CrewService.crewOf = crewOf

local function everyone(crew)
	local out = { crew.host }
	for _, m in crew.members do table.insert(out, m) end
	return out
end

function CrewService.role(player)
	return roleOf[player]
end

---------------------------------------------------------------------------
-- state for the clients
---------------------------------------------------------------------------
local function jobState(crew)
	local j = crew.job
	if not j then return nil end
	return {
		id = j.def.id, icon = j.def.icon, title = j.def.title, text = j.text,
		progress = j.progress, target = j.target, money = j.def.incomeSecs ~= nil or nil,
		endsIn = math.max(0, math.floor(j.endsAt - now())),
	}
end

local function stateFor(player)
	local crew = crewOf(player)
	if not crew then
		return { inCrew = false, you = player.UserId }
	end
	local members = {}
	for _, pl in everyone(crew) do
		table.insert(members, { id = pl.UserId, name = pl.DisplayName, role = roleOf[pl], host = pl == crew.host })
	end
	return {
		inCrew = true,
		you = player.UserId,
		host = crew.host.UserId,
		school = PlotService.schoolName(crew.host),
		open = crew.open,
		max = Config.CrewMax,
		members = members,
		job = jobState(crew),
		boostIn = crew.boostUntil and math.max(0, math.floor(crew.boostUntil - now())) or 0,
	}
end
CrewService.state = stateFor

local function push(crew)
	for _, pl in everyone(crew) do
		if pl.Parent then Remotes.Push:FireClient(pl, "crew", stateFor(pl)) end
	end
end

local function notifyAll(crew, text, kind)
	for _, pl in everyone(crew) do
		if pl.Parent then Remotes.Notify:FireClient(pl, text, kind) end
	end
end

local function setAttrs(crew)
	local n = 1 + #crew.members
	for _, pl in everyone(crew) do
		pl:SetAttribute("SchoolId", crew.host.UserId)
		pl:SetAttribute("Role", roleOf[pl])
		pl:SetAttribute("CrewSize", n)
	end
	crew.host:SetAttribute("CrewOpen", crew.open)
	-- (a crew counts everyone's friends: the Friends bonus changes with it)
	if CrewService.refreshFriends then task.defer(CrewService.refreshFriends) end
end

local function soloAttrs(player)
	player:SetAttribute("SchoolId", player.UserId)
	player:SetAttribute("Role", nil)
	player:SetAttribute("CrewSize", nil)
	player:SetAttribute("CrewOpen", nil)
	if CrewService.refreshFriends then task.defer(CrewService.refreshFriends) end
end

-- the school's screens (to-do card, chapter card, unlocked buttons, income) for someone who just
-- started or stopped playing for it
local function refreshScreens(player)
	local server = script.Parent
	pcall(function() require(server.UnlockService).refresh(player) end)
	pcall(function() require(server.QuestService).push(player) end)
	pcall(function() require(server.ChapterService).push(player) end)
	pcall(function() require(server.UpgradeService).applyAll(player) end)
	pcall(function() require(server.GearService).refreshTools(player) end)
	PlotService.updateIncome(player)
	Data.sync(player)
end

local function sendTo(player, cf)
	local char = player.Character
	if char and cf then char:PivotTo(cf) end
end

local function busy(player)
	if player:GetAttribute("Carrying") or player:GetAttribute("Heist") then return "Put down the kid you're carrying first!" end
	if player:GetAttribute("Mission") then return "Finish your mission first!" end
	if player:GetAttribute("Raid") then return "Your school is being raided! Deal with the goons first." end
	local p = Data.get(player)
	if p and p.reviewing then return "The School Board is meeting!" end
	return nil
end

---------------------------------------------------------------------------
-- start, join, leave
---------------------------------------------------------------------------
local function validRole(role)
	return Config.RoleById[role] and role or "President"
end

function CrewService.create(host, role)
	if Data.isMember(host) then return { ok = false, err = "You're already running a friend's school" } end
	if not Data.own(host) or not PlotService.getPlot(host) then return { ok = false, err = "Your school isn't ready yet" } end
	local crew = crews[host]
	if not crew then
		crew = { host = host, open = true, members = {}, nextJobAt = now() + Config.CrewJobReward.gap, jobIndex = 0, teacherMult = 1 }
		crews[host] = crew
	end
	crew.open = true
	roleOf[host] = validRole(role)
	watch(host)
	setAttrs(crew)
	push(crew)
	Remotes.Notify:FireClient(host, "\u{1F465} Your school is open for co-op! Friends in this server can join you (up to " .. Config.CrewMax .. ").", "good")
	return { ok = true, state = stateFor(host) }
end

function CrewService.join(member, hostId, role)
	local host = typeof(hostId) == "number" and Players:GetPlayerByUserId(hostId)
	local crew = host and crews[host]
	if not crew or not host.Parent then return { ok = false, err = "That school isn't taking co-op players" } end
	if member == host then return CrewService.create(host, role) end
	if not crew.open then return { ok = false, err = "That school closed its doors" } end
	if 1 + #crew.members >= Config.CrewMax then return { ok = false, err = "That school is full (" .. Config.CrewMax .. "/" .. Config.CrewMax .. ")" } end
	if Data.isMember(member) then return { ok = false, err = "Leave your co-op school first" } end
	local own = crews[member]
	if own and #own.members > 0 then return { ok = false, err = "Your own co-op school has players. End it first" } end
	local why = busy(member)
	if why then return { ok = false, err = why } end
	if not Data.own(member) or not Data.own(host) then return { ok = false, err = "Still loading, try again in a second" } end
	-- their own school closes for now (it keeps earning, paid when they come back)
	if own then crews[member] = nil end
	roleOf[member] = nil
	local plot = PlotService.getPlot(host)
	if not plot then return { ok = false, err = "That school isn't ready" } end
	snapshot(member)
	PlotService.release(member)
	Data.alias(member, host)
	PlotService.alias(member, plot)
	copyAll(host, member)
	watch(member)
	roleOf[member] = validRole(role)
	table.insert(crew.members, member)
	setAttrs(crew)
	for _, pl in everyone(crew) do refreshScreens(pl) end
	sendTo(member, PlotService.spawnCFrame(member))
	local r = Config.RoleById[roleOf[member]]
	notifyAll(crew, ("\u{1F465} %s joined %s as %s %s!"):format(member.DisplayName, PlotService.schoolName(host), r.icon, r.name), "good")
	Remotes.Sfx:FireClient(host, "Cheer")
	push(crew)
	Signals.fire("crewJoin", member, host)
	return { ok = true, state = stateFor(member) }
end

-- a member goes back to their own school (gone: they're leaving the game, no new plot)
local function leave(member, gone)
	local crew = crewOf(member)
	if not crew or crew.host == member then return end
	local i = table.find(crew.members, member)
	if i then table.remove(crew.members, i) end
	roleOf[member] = nil
	unwatch(member)
	PlotService.unalias(member)
	local paid = Data.unalias(member)
	if not gone then
		restore(member)
		soloAttrs(member)
		PlotService.assign(member)
		refreshScreens(member)
		sendTo(member, PlotService.spawnCFrame(member))
		local msg = "\u{1F3EB} Back at your own school!"
		if paid > 0 then msg ..= (" It earned %s while you were away."):format(Config.formatCash(paid)) end
		Remotes.Notify:FireClient(member, msg, "good")
		Remotes.Push:FireClient(member, "crew", stateFor(member))
	end
	if crew.host.Parent then
		setAttrs(crew)
		notifyAll(crew, ("%s left the co-op."):format(member.DisplayName), "info")
		if #crew.members == 0 then crew.job = nil end
		push(crew)
	end
end

-- the host ends it: everyone goes home
local function disband(host, gone)
	local crew = crews[host]
	if not crew then return end
	for _, m in table.clone(crew.members) do
		if m.Parent then Remotes.Notify:FireClient(m, gone and (host.DisplayName .. " left the game. The co-op is over.") or (host.DisplayName .. " ended the co-op."), "info") end
		leave(m, false)
	end
	crews[host] = nil
	roleOf[host] = nil
	unwatch(host)
	if not gone then
		soloAttrs(host)
		PlotService.updateIncome(host)
		Remotes.Push:FireClient(host, "crew", stateFor(host))
	end
end

function CrewService.leave(player)
	local crew = crewOf(player)
	if not crew then return { ok = false, err = "You're not in a co-op school" } end
	local why = busy(player)
	if why and not (player:GetAttribute("Raid") and crew.host ~= player) then return { ok = false, err = why } end
	if crew.host == player then disband(player, false) else leave(player, false) end
	return { ok = true, state = stateFor(player) }
end

-- Main calls this first when anyone leaves the game (before their plot and save are released)
function CrewService.onRemoving(player)
	if crews[player] then
		disband(player, true)
	elseif Data.isMember(player) then
		leave(player, true)
	end
	roleOf[player] = nil
	unwatch(player)
	snapshots[player] = nil
end

---------------------------------------------------------------------------
-- crew jobs
---------------------------------------------------------------------------
local function inside(crew, player)
	local plot = PlotService.getPlot(crew.host)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return plot and root and PlotService.inside(plot, root.Position)
end

local function finishJob(crew, won)
	local j = crew.job
	crew.job = nil
	crew.nextJobAt = now() + Config.CrewJobReward.gap
	if not won then
		notifyAll(crew, ("\u{23F0} Out of time: %s. Another job is coming!"):format(j.def.title), "info")
		push(crew)
		return
	end
	local R = Config.CrewJobReward
	local income = crew.host:GetAttribute("IncomePerSec") or 0
	local cash = math.max(R.min, math.floor(income * R.incomeSecs))
	Data.addCash(crew.host, cash)
	crew.boostUntil = now() + R.boostSecs
	PlotService.updateIncome(crew.host)
	notifyAll(crew, ("\u{1F389} CREW JOB DONE: %s! +%s and +%d%% tuition for %d minutes!"):format(j.def.title, Config.formatCash(cash), math.floor(R.boost * 100), math.floor(R.boostSecs / 60)), "good")
	for _, pl in everyone(crew) do
		if pl.Parent then Remotes.Sfx:FireClient(pl, "Cheer") end
	end
	Signals.fire("crewJob", crew.host, j.def.id)
	push(crew)
end

local function startJob(crew)
	local defs = Config.CrewJobs
	crew.jobIndex = crew.jobIndex % #defs + 1
	local def = defs[crew.jobIndex]
	local n = 1 + #crew.members
	local target, text
	if def.incomeSecs then
		local income = crew.host:GetAttribute("IncomePerSec") or 0
		target = math.max(200, math.floor(income * def.incomeSecs * n))
		text = def.text:format(Config.formatCash(target))
	elseif def.per then
		target = def.per * n
		text = def.text:format(target)
	else
		target = n
		text = def.text
	end
	crew.job = { def = def, target = target, progress = 0, text = text, endsAt = now() + def.secs }
	notifyAll(crew, ("%s NEW CREW JOB: %s"):format(def.icon, text), "info")
	push(crew)
end

local function progress(player, amount)
	local crew = crewOf(player)
	local j = crew and crew.job
	if not j then return end
	j.progress = math.min(j.target, j.progress + amount)
	if j.progress >= j.target then finishJob(crew, true) else push(crew) end
end

local function tick()
	for host, crew in crews do
		if not host.Parent then continue end
		-- Teachers in the building: +20% each while they're inside (perks need two or more)
		local teachers = 0
		for _, pl in everyone(crew) do
			if #crew.members > 0 and roleOf[pl] == "Teacher" and inside(crew, pl) then teachers += 1 end
		end
		local mult = 1 + teachers * Config.RolePerks.teacher
		local boosted = crew.boostUntil and crew.boostUntil > now()
		if mult ~= crew.teacherMult or boosted ~= crew.wasBoosted then
			crew.teacherMult = mult
			crew.wasBoosted = boosted
			PlotService.updateIncome(host)
		end
		-- jobs need two or more
		if #crew.members == 0 then
			crew.job = nil
			continue
		end
		local j = crew.job
		if not j and now() >= crew.nextJobAt then
			startJob(crew)
		elseif j then
			if j.def.id == "assembly" then
				local n = 0
				for _, pl in everyone(crew) do
					if inside(crew, pl) then n += 1 end
				end
				if n ~= j.progress then
					j.progress = n
					if n >= j.target then finishJob(crew, true) else push(crew) end
				end
			end
			if crew.job == j and now() >= j.endsAt then finishJob(crew, false) end
		end
	end
end

---------------------------------------------------------------------------
-- the Friends bonus: +10% tuition for each Roblox friend in the server with you (up to +40%); a
-- co-op school counts the friends of everyone running it. FriendsBonus (a percent) on each player.
---------------------------------------------------------------------------
local friendsOf = {} -- [player] = { [other] = true }
local fakeFriends = {} -- [player] = n (Studio test hook)

local function friendCount(player)
	local seen = {}
	local n = 0
	for _, pl in Data.schoolPlayers(player) do
		for other in friendsOf[pl] or {} do
			if other.Parent and not seen[other] then
				seen[other] = true
				n += 1
			end
		end
		n += fakeFriends[pl] or 0
	end
	return math.min(n, Config.FriendsBonus.max)
end

function CrewService.friendMult(player)
	return 1 + Config.FriendsBonus.each * friendCount(player)
end

local function refreshFriends()
	for _, pl in Players:GetPlayers() do
		local pct = math.floor(Config.FriendsBonus.each * friendCount(pl) * 100 + 0.5)
		if pl:GetAttribute("FriendsBonus") ~= (pct > 0 and pct or nil) then
			pl:SetAttribute("FriendsBonus", pct > 0 and pct or nil)
			PlotService.updateIncome(pl)
		end
	end
end

local function meetFriends(player)
	friendsOf[player] = friendsOf[player] or {}
	for _, other in Players:GetPlayers() do
		if other ~= player and other.Parent and player.Parent then
			local ok, yes = pcall(player.IsFriendsWith, player, other.UserId)
			if ok and yes then
				friendsOf[player][other] = true
				friendsOf[other] = friendsOf[other] or {}
				friendsOf[other][player] = true
				Remotes.Notify:FireClient(other, ("\u{1F44B} Your friend %s is here! +%d%% tuition while you play together."):format(player.DisplayName, math.floor(Config.FriendsBonus.each * 100)), "good")
				Remotes.Notify:FireClient(player, ("\u{1F44B} Your friend %s is here! +%d%% tuition while you play together."):format(other.DisplayName, math.floor(Config.FriendsBonus.each * 100)), "good")
			end
		end
	end
	refreshFriends()
end

CrewService.refreshFriends = refreshFriends

function CrewService.debugFriends(player, n)
	fakeFriends[player] = n
	refreshFriends()
	return CrewService.friendMult(player)
end

---------------------------------------------------------------------------
function CrewService.start()
	-- the Teacher bonus and a finished job's boost: short-lived, so offline pay ignores them
	table.insert(PlotService.tempHooks, function(player)
		local m = CrewService.friendMult(player)
		local crew = crews[player]
		if not crew then return m end
		m *= crew.teacherMult or 1
		if crew.boostUntil and crew.boostUntil > now() then m *= 1 + Config.CrewJobReward.boost end
		return m
	end)
	Players.PlayerAdded:Connect(function(player) task.spawn(meetFriends, player) end)
	for _, pl in Players:GetPlayers() do task.spawn(meetFriends, pl) end
	Players.PlayerRemoving:Connect(function(player)
		friendsOf[player] = nil
		fakeFriends[player] = nil
		for _, set in friendsOf do set[player] = nil end
		task.defer(refreshFriends)
	end)
	Signals.on("enroll", function(player)
		local crew = crewOf(player)
		if crew and crew.job and crew.job.def.signal == "enroll" then progress(player, 1) end
	end)
	Signals.on("rivalEscaped", function(player)
		local crew = crewOf(player)
		if crew and crew.job and crew.job.def.signal == "rivalEscaped" then progress(player, 1) end
	end)
	Signals.on("collect", function(player, amount)
		local crew = crewOf(player)
		if crew and crew.job and crew.job.def.signal == "collect" and type(amount) == "number" then progress(player, amount) end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			local ok, err = pcall(tick)
			if not ok then warn("[Crew]", err) end
		end
	end)
	Players.PlayerAdded:Connect(soloAttrs)
	for _, pl in Players:GetPlayers() do
		if not pl:GetAttribute("SchoolId") then soloAttrs(pl) end
	end
end

---------------------------------------------------------------------------
-- the client
---------------------------------------------------------------------------
-- every school in this server taking co-op players
Actions.register("crewList", function(player)
	local list = {}
	for host, crew in crews do
		if host.Parent and crew.open and host ~= Data.hostOf(player) then
			local roles = {}
			for _, pl in everyone(crew) do table.insert(roles, roleOf[pl]) end
			table.insert(list, {
				host = host.UserId, hostName = host.DisplayName, school = PlotService.schoolName(host),
				size = 1 + #crew.members, max = Config.CrewMax, roles = roles,
				tier = Data.get(host) and Data.get(host).tier or 1,
			})
		end
	end
	return { ok = true, list = list, state = stateFor(player) }
end)
Actions.register("crewCreate", function(player, _, role)
	return CrewService.create(player, role)
end)
Actions.register("crewJoin", function(player, _, hostId, role)
	return CrewService.join(player, hostId, role)
end)
Actions.register("crewLeave", function(player)
	return CrewService.leave(player)
end)
Actions.register("crewRole", function(player, _, role)
	local crew = crewOf(player)
	if not crew then return { ok = false, err = "You're not in a co-op school" } end
	roleOf[player] = validRole(role)
	setAttrs(crew)
	local r = Config.RoleById[roleOf[player]]
	notifyAll(crew, ("%s is now %s %s"):format(player.DisplayName, r.icon, r.name), "info")
	push(crew)
	return { ok = true, state = stateFor(player) }
end)
Actions.register("crewOpen", function(player, _, open)
	local crew = crews[player]
	if not crew then return { ok = false, err = "Only the school's owner can do that" } end
	crew.open = open == true
	setAttrs(crew)
	push(crew)
	return { ok = true, state = stateFor(player) }
end)
Actions.register("crewKick", function(player, _, userId)
	local crew = crews[player]
	if not crew then return { ok = false, err = "Only the school's owner can do that" } end
	for _, m in crew.members do
		if m.UserId == userId then
			Remotes.Notify:FireClient(m, player.DisplayName .. " sent you back to your own school.", "info")
			leave(m, false)
			return { ok = true, state = stateFor(player) }
		end
	end
	return { ok = false, err = "Not in your co-op" }
end)
Actions.register("crewState", function(player)
	return { ok = true, state = stateFor(player) }
end)

-- Studio: a crew job right now
function CrewService.debugJob(player)
	local crew = crewOf(player)
	if not crew then return false end
	crew.nextJobAt = 0
	crew.job = nil
	return true
end

return CrewService
