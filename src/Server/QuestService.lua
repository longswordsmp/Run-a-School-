-- ServerScriptService.Server.QuestService
-- The Principal's To-Do: the First Morning and Chapter 1 (Config.Tutorial, one list), then goals
-- in rotation (Config.Goals). The client gets Remotes.Push("quest", state) and draws the card
-- and the guide. "In the tutorial" below means anywhere on that list; the InTutorial player
-- attribute (which keeps server-wide news and pop quizzes away) covers only the First Morning.
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
-- index, which the unlock rules and other services read. Saves from the older lists land on the
-- nearest new step (the state checks then fast-forward whatever they had already done).
local MIGRATE = {
	enroll1 = "welcome", enroll4 = "welcome", fill = "welcome",
	pencils = "k01_pencils", hire = "k02_teacher", name = "k03_name",
	rows = "desks", upgrade = "desks", hallmonitor = "k04_hector",
}
local function syncIndex(p)
	if p.tutorialId == "done" then
		p.tutorial = #Config.Tutorial + 1
	elseif p.tutorialId then
		local i = stepIndex(p.tutorialId) or stepIndex(MIGRATE[p.tutorialId] or "")
		if not i then
			-- (an id no list knows: from the start; a finished school is past it anyway)
			i = (p.tier or 1) >= 2 and #Config.Tutorial + 1 or 1
		end
		p.tutorial = i
		local st = Config.Tutorial[i]
		p.tutorialId = st and st.id or "done"
	elseif p.tutorial then
		local s = Config.Tutorial[p.tutorial]
		p.tutorialId = s and s.id or "done"
	end
end
QuestService.syncIndex = syncIndex

local function inTutorial(p)
	return p.tutorial and p.tutorial <= #Config.Tutorial
end
-- the First Morning: the first steps, where nothing else is allowed to interrupt
local function inMorning(p)
	local last = stepIndex("desks")
	return p.tutorial ~= nil and last ~= nil and p.tutorial <= last
end
QuestService.inMorning = function(player)
	local p = Data.get(player)
	return p ~= nil and inMorning(p)
end
-- is this player's To-Do on (or past) a step
function QuestService.atOrPast(player, id)
	local p = Data.get(player)
	local i = stepIndex(id)
	if not p or not i then return false end
	syncIndex(p)
	return (p.tutorial or 1) >= i
end
function QuestService.pastStep(player, id)
	local p = Data.get(player)
	local i = stepIndex(id)
	if not p or not i then return false end
	syncIndex(p)
	return (p.tutorial or 1) > i
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

local function seatedKid(p, id)
	for _, e in p.students do
		if e.id == id and not e.arriving then return true end
	end
	return false
end
local function won(p, id) return p.missions ~= nil and p.missions[id] == true end
local function yes(v) return v and 1 or 0 end

local DONE = {
	-- the First Morning
	welcome = function(_, p) return seated(p) end,
	scholar = function(_, p) return yes(p.scholarPick ~= nil) end,
	collect = function(_, p) return did(p, "collect") end,
	bonk = function(_, p) return did(p, "bonkCrumpet") end,
	-- (locked right now: the goons are about to walk into it. An old lock that ran out doesn't count,
	-- but the step clears the cooldown when it starts, so the button always works)
	-- (and nobody's kid still in a goon's arms: locked too late, you bonk them first)
	-- (a lock made on this step counts even if it ran out while you chased the goons)
	lock = function(player, p)
		local plot = plotOf(player)
		local locked = plot and (plot:GetAttribute("LockedUntil") or 0) > workspace:GetServerTimeNow()
		return yes((locked or did(p, "lockOnStep") > 0) and require(script.Parent.RaidService).holding(player) == 0)
	end,
	rescue = function(_, p) return did(p, "rescued") end,
	desks = function(_, p) return yes((p.rows[1] or 0) >= 3) end,
	-- Chapter 1
	k01_pencils = function(_, p) return yes(p.supplies and p.supplies.Pencils) end,
	k02_teacher = function(_, p) return yes(p.teachers[1] ~= nil) end,
	k03_name = function(_, p) return yes(p.schoolName ~= nil) end,
	k04_hector = function(_, p) return yes(won(p, "k_hallrun") and seatedKid(p, "HallMonitor")) end,
	k05_janitor = function(_, p) return yes((p.upgrades and p.upgrades.Janitor or 0) >= 1) end,
	k06_thief = function(_, p) return yes(won(p, "k_tiara") and seatedKid(p, "DramaQueen")) end,
	k07_row4 = function(_, p) return yes((p.rows[1] or 0) >= 4) end,
	k07_swap = function(_, p) return did(p, "swapped") end,
	k08_crew = function(_, p) return yes(won(p, "k_crew")) end,
	-- (a gate that never broke, from a save before the First Morning's burnout, counts as fixed)
	k08_gate = function(_, p) return yes(not p.gateBroken or (p.upgrades and p.upgrades.LaserGate or 0) >= 1) end,
	k09_map = function(_, p) return yes(won(p, "k_map")) end,
	k10_peek = function(_, p) return yes(p.rivalSeen) end,
	k11_pothole = function(_, p) return yes(p.sewerScouted) end,
	k12_heist = function(_, p) return yes(won(p, "k_heist")) end,
	board = function(_, p) return yes((p.tier or 1) >= 2) end,
}
QuestService.Done = DONE

local function rewardOf(player, q, kind)
	if kind == "tutorial" and not q.secs then return q.reward or 0 end
	local inc = player:GetAttribute("BaseIncome") or 0
	return math.floor(math.max(q.min or 0, inc * (q.secs or 120)))
end

-- where the step is within its part ("3 of 7" in the First Morning, "5 of 13" in Chapter 1)
local function partPos(i)
	local q = Config.Tutorial[i]
	if not q then return nil end
	local n, total = 0, 0
	for j, s in Config.Tutorial do
		if s.part == q.part then
			total += 1
			if j <= i then n += 1 end
		end
	end
	return n, total
end

-- a gift from a won mission sits on your bench until you enroll it: the card says so, and the guide
-- points at the bench
local GIFT_STEP = { k04_hector = "k_hallrun", k06_thief = "k_tiara" }

function QuestService.state(player)
	local p = Data.get(player)
	if not p then return nil end
	local q, kind = current(p)
	local n, total
	if kind == "tutorial" then n, total = partPos(p.tutorial) end
	local short, text, guide = q.short, q.text, q.guide
	-- "Swap up!": first the weakest kid (sell), then the carpet (a better one)
	if q.id == "k07_swap" and kind == "tutorial" and did(p, "sold") > 0 then
		short = "Enroll a better kid"
		text = "Now pick a kid who earns more than the one you sold"
		guide = "carpet"
	end
	if q.id == "lock" and kind == "tutorial" then
		local ok, holding = pcall(function() return require(script.Parent.RaidService).holding(player) end)
		if ok and holding > 0 then
			short = "Bonk the goons!"
			text = "They grabbed kids before the gate was locked: bonk them to get the kids back"
			guide = "thief"
		end
	end
	local giftMission = GIFT_STEP[q.id]
	local benchKid
	if giftMission and won(p, giftMission) then
		local def = Config.StudentById[Config.Missions[giftMission].give]
		benchKid = def and def.id
		short = "Enroll " .. (def and def.name or "your new kid")
		text = "They're waiting on your bench by the gate (free)"
		guide = "bench"
	end
	return {
		kind = kind,
		id = q.id,
		part = q.part,
		icon = q.icon,
		step = n,
		steps = total,
		text = text,
		short = short,
		progress = p.quests.progress or 0,
		count = q.count,
		reward = rewardOf(player, q, kind),
		guide = guide,
		npc = q.guide and q.guide:match("^npc:(%w+)$") or nil,
		benchKid = benchKid, -- (the "bench" guide points at this kid)
	}
end

-- (Remotes.Push sends "quest" and "questDone" to everyone who plays for the school)
function QuestService.push(player)
	local s = QuestService.state(player)
	if s then Remotes.Push:FireClient(player, "quest", s) end
	-- (server-wide news and pop quizzes skip whoever is still in the First Morning: Remotes.announceAll)
	local p = Data.get(player)
	for _, pl in Data.schoolPlayers(player) do
		pl:SetAttribute("InTutorial", (p and inMorning(p)) or nil)
	end
end

-- the client asks once its quest card is ready; a rejoin mid-tutorial replays the step's moment
local replayed = {}
local lockHolding = {} -- [player] = the lock step's goons had kids at the last look
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
	lockHolding[player] = nil
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
			-- the last step of the First Morning: its stamp, and Chapter 1 begins
			if q.part == "morning" and nextStep.part ~= "morning" then
				task.defer(Signals.fire, "firstMorningDone", host)
			end
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
	Signals.on("questStep", function(player, id)
		task.defer(QuestService.recheck, player)
		-- the step's call: who, where and why, before you go (once per step; not if it's already done)
		local call = Config.StepCalls[id]
		local p = Data.get(player)
		if call and p then
			p.callsHeard = p.callsHeard or {}
			if not p.callsHeard[id] then
				task.delay(1.4, function()
					local pp = Data.get(player)
					if not player.Parent or not pp or pp.tutorialId ~= id then return end
					pp.callsHeard[id] = true
					for _, pl in Data.schoolPlayers(player) do
						Remotes.Push:FireClient(pl, "missionTalk", { call = true, lines = call })
					end
				end)
			end
		end
	end)
	-- the First Morning's stamp (Cutscene "FirstMorning"), with what you did in it
	Signals.on("firstMorningDone", function(player)
		local p = Data.get(player)
		if not p then return end
		local inc = player:GetAttribute("BaseIncome") or 0
		local summary = ("%d kids  \u{2022}  %s/s  \u{2022}  1 butler bonked  \u{2022}  1 kid freed"):format(seated(p), Config.formatCash(inc))
		for _, pl in Data.schoolPlayers(player) do
			Remotes.Cutscene:FireClient(pl, "FirstMorning", { summary = summary })
		end
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
	-- (swapping up: a sale, then an enroll after it)
	Signals.on("sell", function(player)
		if typeof(player) ~= "Instance" then return end
		remember(player, "sold")
		task.defer(QuestService.push, player)
	end)
	Signals.on("enroll", function(player)
		local p = Data.get(player)
		if p and p.tutDid and p.tutDid.sold then remember(player, "swapped") end
	end)
	Signals.on("lock", function(player)
		remember(player, "lock")
		local p = Data.get(player)
		local st = p and Config.Tutorial[p.tutorial or 1]
		if st and st.id == "lock" then remember(player, "lockOnStep") end
	end)
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
	for _, name in { "sell", "supply", "hire", "upgrade", "review", "nameSchool", "build", "missionWon", "desks", "enroll", "benchEnroll", "scholarPick" } do
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
					local morning = inMorning(p) or nil
					if player:GetAttribute("InTutorial") ~= morning then player:SetAttribute("InTutorial", morning) end
					if inTutorial(p) and not Data.isMember(player) then pcall(QuestService.recheck, player) end
					-- (the lock step's card turns into "Bonk the goons!" while they hold kids, and back)
					local st = Config.Tutorial[p.tutorial or 1]
					if st and st.id == "lock" then
						local ok, holding = pcall(function() return require(script.Parent.RaidService).holding(player) > 0 end)
						holding = ok and holding or false
						if holding ~= lockHolding[player] then
							lockHolding[player] = holding
							QuestService.push(player)
						end
					end
				end
			end
		end
	end)
end

return QuestService
