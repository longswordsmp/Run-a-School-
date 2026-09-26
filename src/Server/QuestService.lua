-- ServerScriptService.Server.QuestService
-- The Principal's To-Do: a tutorial chain for the first session (Config.Tutorial), then goals
-- in rotation (Config.Goals). The client gets Remotes.Push("quest", state) and draws the card
-- and the guide.
--
-- A To-Do step completes from STATE, not only from the moment it happens: every step id can have
-- a check (DONE below) that reads the save (desks filled, gate locked, pencils owned...), plus a
-- record of what the player already did during the tutorial (p.tutDid). Checked when the step
-- arrives, after anything relevant happens, and once a second while the tutorial runs. Before
-- this a step only counted its signal while it was the current step, so doing things early was
-- lost: lock the gate before "Lock your gate" and the step waited out the whole lock; grab all six
-- Welcome kids during "collect" and "Fill 3 more desks" needed desks the school didn't have.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)

local QuestService = {}

local function stepIndex(id)
	for i, s in Config.Tutorial do
		if s.id == id then return i end
	end
	return nil
end
QuestService.stepIndex = stepIndex

-- the step is stored by id (so a reordered list resumes on the right step); p.tutorial stays the
-- index, which the unlock rules and other services read
local function syncIndex(p)
	if p.tutorialId == "done" then
		p.tutorial = #Config.Tutorial + 1
	elseif p.tutorialId then
		p.tutorial = stepIndex(p.tutorialId) or p.tutorial
	elseif p.tutorial then
		local s = Config.Tutorial[p.tutorial]
		p.tutorialId = s and s.id or "done"
	end
end

local function inTutorial(p)
	return p.tutorial and p.tutorial <= #Config.Tutorial
end
QuestService.inTutorial = function(player)
	local p = Data.get(player)
	return p ~= nil and inTutorial(p)
end

local function current(p)
	syncIndex(p)
	if inTutorial(p) then
		return Config.Tutorial[p.tutorial], "tutorial"
	end
	local alone = #Players:GetPlayers() < 2
	for _ = 1, #Config.Goals do
		local i = ((p.quests.chain or 1) - 1) % #Config.Goals + 1
		local g = Config.Goals[i]
		if not (g.multi and alone) then return g, "goal" end
		p.quests.chain = (p.quests.chain or 1) + 1
		p.quests.progress = 0
	end
	return Config.Goals[1], "goal"
end

---------------------------------------------------------------------------
-- what counts as done, per step id (a number: the progress towards the step's count)
---------------------------------------------------------------------------
local function seated(p)
	local n = 0
	for _ in p.students do n += 1 end
	return n
end
local function did(p, what) return p.tutDid and p.tutDid[what] and 1 or 0 end
local function plotOf(player)
	local PlotService = require(script.Parent.PlotService)
	return PlotService.getPlot(Data.hostOf(player))
end

local DONE = {
	welcome = function(_, p) return seated(p) end,
	enroll1 = function(_, p) return seated(p) end,
	enroll4 = function(_, p) return seated(p) end,
	fill = function(_, p) return seated(p) end,
	collect = function(_, p) return did(p, "collect") end,
	lock = function(player, p)
		local plot = plotOf(player)
		local locked = plot and (plot:GetAttribute("LockedUntil") or 0) > workspace:GetServerTimeNow()
		return (locked or did(p, "lock") > 0) and 1 or 0
	end,
	bonk = function(_, p) return did(p, "bonkCrumpet") end,
	rescue = function(_, p) return did(p, "rescued") end,
	pencils = function(_, p) return (p.supplies and p.supplies.Pencils) and 1 or 0 end,
	hire = function(_, p) return p.teachers[1] ~= nil and 1 or 0 end,
	rows = function(_, p) return (p.rows[1] or 0) >= 3 and 1 or 0 end,
	upgrade = function(_, p) return (p.rows[1] or 0) >= 3 and 1 or 0 end,
	name = function(_, p) return p.schoolName ~= nil and 1 or 0 end,
	hallmonitor = function(_, p)
		for _, e in p.students do
			if e.id == "HallMonitor" and not e.arriving then return 1 end
		end
		return 0
	end,
	board = function(_, p) return (p.tier or 1) >= 2 and 1 or 0 end,
}
QuestService.Done = DONE

local function rewardOf(player, q, kind)
	if kind == "tutorial" then return q.reward end
	local inc = player:GetAttribute("BaseIncome") or 0
	return math.floor(math.max(q.min or 0, inc * (q.secs or 120)))
end

function QuestService.state(player)
	local p = Data.get(player)
	if not p then return nil end
	local q, kind = current(p)
	return {
		kind = kind,
		id = q.id,
		step = kind == "tutorial" and p.tutorial or nil,
		steps = #Config.Tutorial,
		text = q.text,
		short = q.short,
		progress = p.quests.progress or 0,
		count = q.count,
		reward = rewardOf(player, q, kind),
		guide = q.guide,
	}
end

-- (Remotes.Push sends "quest" and "questDone" to everyone who plays for the school)
function QuestService.push(player)
	local s = QuestService.state(player)
	if s then Remotes.Push:FireClient(player, "quest", s) end
	-- (server-wide news and pop quizzes skip whoever is still on the To-Do list: Remotes.announceAll)
	local p = Data.get(player)
	for _, pl in Data.schoolPlayers(player) do
		pl:SetAttribute("InTutorial", (p and inTutorial(p)) or nil)
	end
end

-- the client asks once its quest card is ready; a rejoin mid-tutorial replays the step's moment
local replayed = {}
Actions.register("quest", function(player, p)
	syncIndex(p)
	if not replayed[player] and not Data.isMember(player) and p.tutorial and p.tutorial > 1 and Config.Tutorial[p.tutorial] then
		replayed[player] = true
		local id = Config.Tutorial[p.tutorial].id
		task.delay(3, function()
			if player.Parent then Signals.fire("questStep", player, id) end
		end)
	end
	return QuestService.state(player) or { ok = false }
end)
Players.PlayerRemoving:Connect(function(player)
	replayed[player] = nil
end)

-- onboarding funnel (Creator Hub > Analytics): one event per To-Do step reached
local function funnel(player, index, id)
	pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, index, id)
	end)
end

local advancing = {}
local function advance(player, p, q, kind)
	local host = Data.hostOf(player)
	if advancing[host] then return end
	advancing[host] = true
	local reward = rewardOf(player, q, kind)
	p.quests.progress = 0
	if kind == "tutorial" then
		p.tutorial += 1
		local nextStep = Config.Tutorial[p.tutorial]
		p.tutorialId = nextStep and nextStep.id or "done"
		funnel(host, p.tutorial + 1, nextStep and nextStep.id or "done")
		if nextStep then
			-- let scripted moments (Crumpet, the rescue, the scholarship...) start
			task.delay(2, function()
				if host.Parent and p.tutorialId == nextStep.id then
					Signals.fire("questStep", host, nextStep.id)
				end
			end)
		end
	else
		p.quests.chain = (p.quests.chain or 1) + 1
	end
	if reward > 0 then Data.addCash(player, reward) end
	Remotes.Push:FireClient(player, "questDone", { text = q.text, reward = reward, kind = kind })
	for _, pl in Data.schoolPlayers(player) do Remotes.Sfx:FireClient(pl, "Token") end
	Signals.fire("questDone", host, q, kind)
	task.delay(1.2, function()
		advancing[host] = nil
		QuestService.push(host)
		-- the next step may already be done (it's checked again when it arrives, too)
		QuestService.recheck(host)
	end)
end

-- a step with a state check: set its progress from the check, finish it when it's there
function QuestService.recheck(player)
	local p = Data.get(player)
	if not p or advancing[Data.hostOf(player)] then return end
	local q, kind = current(p)
	if kind ~= "tutorial" then return end
	local check = DONE[q.id]
	if not check then return end
	local ok, value = pcall(check, player, p)
	if not ok or type(value) ~= "number" then return end
	value = math.min(value, q.count)
	if value ~= (p.quests.progress or 0) then
		p.quests.progress = value
		if value >= q.count then
			advance(player, p, q, kind)
		else
			QuestService.push(player)
		end
	end
end

-- a signal towards the current step (goals, and tutorial steps without a state check)
function QuestService.progress(player, signal, amount)
	local p = Data.get(player)
	if not p then return end
	local q, kind = current(p)
	if kind == "tutorial" and DONE[q.id] then
		QuestService.recheck(player)
		return
	end
	if q.signal ~= signal then return end
	p.quests.progress = (p.quests.progress or 0) + (amount or 1)
	if p.quests.progress >= q.count then
		advance(player, p, q, kind)
	else
		QuestService.push(player)
	end
end

-- remember a tutorial-relevant thing the player did, whatever step they're on
local function remember(player, what)
	local p = Data.get(player)
	if not p or not inTutorial(p) then return end
	p.tutDid = p.tutDid or {}
	p.tutDid[what] = true
	task.defer(QuestService.recheck, player)
end
QuestService.remember = remember

function QuestService.start()
	Signals.on("questStep", function(player)
		task.defer(QuestService.recheck, player)
	end)
	local function on(name, map)
		Signals.on(name, function(player, ...)
			if typeof(player) ~= "Instance" then return end
			local sig, amount = name, 1
			if map then sig, amount = map(...) end
			if sig then QuestService.progress(player, sig, amount) end
		end)
	end
	-- enrolls count for "enroll", and for the rarity goals when the kid is rare enough
	Signals.on("enroll", function(player, def)
		QuestService.progress(player, "enroll")
		local order = Config.RarityById[def.rarity].order
		if order >= 3 then QuestService.progress(player, "enrollRare") end
		if order >= 4 then QuestService.progress(player, "enrollEpic") end
	end)
	-- what the tutorial remembers
	Signals.on("collect", function(player) remember(player, "collect") end)
	Signals.on("lock", function(player) remember(player, "lock") end)
	Signals.on("rescued", function(player, _, prize)
		if not prize then remember(player, "rescued") end
	end)
	-- (only bonking your own tutorial Crumpet counts for "Bonk Crumpet", not someone else's goon)
	Signals.on("bonkSave", function(player, _, _, owner, tutorialRaid)
		if tutorialRaid and owner and Data.hostOf(player) == Data.hostOf(owner) then remember(player, "bonkCrumpet") end
	end)
	-- (Crumpet bonked before he got his hands on anyone)
	Signals.on("tutorialBonk", function(player, owner)
		if owner and Data.hostOf(player) == Data.hostOf(owner) then remember(player, "bonkCrumpet") end
	end)
	for _, name in { "sell", "supply", "hire", "upgrade", "review", "nameSchool", "build" } do
		Signals.on(name, function(player)
			if typeof(player) == "Instance" then task.defer(QuestService.recheck, player) end
		end)
	end
	on("collect")
	on("supply")
	on("hire")
	on("build")
	on("nameSchool")
	on("lock")
	on("upgrade")
	on("review")
	on("stole")
	on("bonkSave")
	on("catchCheater")
	on("benchEnroll")
	on("bustDealer")
	on("quizRight")
	on("rescued")
	for _, name in { "supply", "hire", "build" } do
		Signals.on(name, function(player)
			QuestService.progress(player, "shopBuy")
		end)
	end
	-- and once a second while anyone is in the tutorial (gifts, co-op, a gate still locked...)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				local p = Data.get(player)
				if p then
					local on = inTutorial(p) or nil
					if player:GetAttribute("InTutorial") ~= on then player:SetAttribute("InTutorial", on) end
					if on and not Data.isMember(player) then pcall(QuestService.recheck, player) end
				end
			end
		end
	end)
end

return QuestService
