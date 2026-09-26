-- ServerScriptService.Server.TownQuestService
-- Runs Shared/Quests (docs/TOWN.md section 4) for each player, in their own save:
--   own.tq = { active = { [id] = { step, prog, got = { [i] = true } } }, done = { [id] = true }, tracked = id }
-- One story quest and up to three town quests at once. Talking to a townsperson (TownNPCService.onTalk)
-- hands a step in or offers their quest; visits are checked twice a second; collectibles are drawn by
-- the player's own client (only they see them) and picked up through the tqCollect action; signal
-- steps listen on Signals. The tracked quest's target goes on the player as QuestTarget (the guide
-- beam in Quests.client follows it).
--   pushes  "tq"      the whole state (the tracker, the log, the "!" and "?" markers)
--           "tqItems" { id, step, item, spots = { Vector3 }, got } the collectibles to draw
--           "tqDone"  { id, title, rewards = { text }, outro } the completion stamp
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Quests = require(ReplicatedStorage.Shared.Quests)
local Cutscenes = require(ReplicatedStorage.Shared.Cutscenes)
local Places = require(ReplicatedStorage.Shared.Places)
local Townsfolk = require(ReplicatedStorage.Shared.Townsfolk)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)
local AreaService = require(script.Parent.AreaService)
local TownNPCService = require(script.Parent.TownNPCService)

local TownQuestService = {}
local MAX_TOWN = 3
local PICKUP_RANGE = 9

-- the step-kind handlers some other service provides (goons, chase): kind -> fn(player, quest, step, state)
TownQuestService.starters = {}

local function tqOf(player)
	local own = Data.own(player)
	if not own then return nil end
	own.tq = own.tq or {}
	local t = own.tq
	t.active = t.active or {}
	t.done = t.done or {}
	return t
end

local function tutorialDone(p)
	return (p.tutorial or 1) > #Config.Tutorial
end

-- why a quest isn't open to this player yet (nil = it is)
local function blocked(player, q)
	local p = Data.get(player)
	local t = tqOf(player)
	if not p or not t then return "loading" end
	local n = q.needs or {}
	if (n.tutorial or n.chapter) and not tutorialDone(p) then return "Finish the Principal's To-Do" end
	if n.chapter then
		local ch = p.chapter and p.chapter.n or 1
		if p.finaleSeen then ch = 99 end
		if ch < n.chapter then return ("Reach Chapter %d"):format(n.chapter) end
	end
	if n.tier and (p.tier or 1) < n.tier then
		local tier = Config.Tiers[n.tier]
		return ("Grow your school to %s"):format(tier and tier.name or ("tier " .. n.tier))
	end
	for _, id in n.quests or {} do
		if not t.done[id] then
			local need = Quests.byId[id]
			return ("Finish \"%s\" first"):format(need and need.title or id)
		end
	end
	if q.area and not AreaService.isOpen(player, q.area) then
		local a = Config.AreaById[q.area]
		return ("Open %s first"):format(a and a.name or q.area)
	end
	return nil
end

local function counts(t)
	local story, town = 0, 0
	for id in t.active do
		local q = Quests.byId[id]
		if q and q.line == "story" then story += 1 else town += 1 end
	end
	return story, town
end

local function canStart(player, q)
	local t = tqOf(player)
	if not t or t.done[q.id] or t.active[q.id] then return false end
	if blocked(player, q) then return false end
	local story, town = counts(t)
	if q.line == "story" and story > 0 then return false end
	if q.line == "town" and town >= MAX_TOWN then return false, "full" end
	return true
end

local function stepOf(q, st)
	return q.steps[st.step]
end

local function stepN(s)
	if s.kind == "collect" then return s.n or #s.spots end
	if s.kind == "signal" or s.kind == "goons" then return s.n or 1 end
	return nil
end

-- where the step wants you (the guide beam)
local function targetOf(player, q, st)
	local s = stepOf(q, st)
	if not s then return nil end
	if s.kind == "talk" or s.kind == "deliver" then
		local m = TownNPCService.model(s.npc)
		return m and m.PrimaryPart and m.PrimaryPart.Position + Vector3.new(0, 4, 0)
	elseif s.kind == "visit" or s.kind == "goons" then
		local p = Places.get(s.place)
		return p and p.pos + Vector3.new(0, 3, 0)
	elseif s.kind == "collect" then
		-- the nearest one still to pick up
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local best, bestD
		for i, name in s.spots do
			if not (st.got and st.got[i]) then
				local p = Places.get(name)
				if p then
					local d = root and (root.Position - p.pos).Magnitude or 0
					if not best or d < bestD then best, bestD = p.pos, d end
				end
			end
		end
		return best and best + Vector3.new(0, 3, 0)
	elseif s.kind == "chase" then
		return player:GetAttribute("QuestRunnerAt")
	end
	return nil
end

local function refreshTarget(player)
	local t = tqOf(player)
	if not t then return end
	local id = t.tracked
	local st = id and t.active[id]
	local q = id and Quests.byId[id]
	local pos = (q and st) and targetOf(player, q, st) or nil
	if player:GetAttribute("QuestTarget") ~= pos then player:SetAttribute("QuestTarget", pos) end
end

-- the state the client draws
function TownQuestService.state(player)
	local t = tqOf(player)
	if not t then return nil end
	local out = { active = {}, marks = {}, avail = {}, locked = {}, tracked = t.tracked, done = 0, total = #Quests.list }
	for _ in t.done do out.done += 1 end
	for id, st in t.active do
		local q = Quests.byId[id]
		local s = q and stepOf(q, st)
		if s then
			table.insert(out.active, { id = id, step = st.step, prog = st.prog or 0, n = stepN(s), got = st.got })
			if (s.kind == "talk" or s.kind == "deliver") and s.npc then out.marks[s.npc] = "?" end
		end
	end
	local story, town = counts(t)
	for _, q in Quests.list do
		if not t.done[q.id] and not t.active[q.id] then
			local why = blocked(player, q)
			if not why then
				local room = (q.line == "story" and story == 0) or (q.line == "town" and town < MAX_TOWN)
				table.insert(out.avail, { id = q.id, room = room })
				if q.giver and room and not out.marks[q.giver] then out.marks[q.giver] = q.line == "story" and "!!" or "!" end
			elseif #out.locked < 12 then
				table.insert(out.locked, { id = q.id, why = why })
			end
		end
	end
	return out
end

local function push(player)
	-- always track something that's actually on (the story first)
	local t = tqOf(player)
	if t and (not t.tracked or not t.active[t.tracked]) then
		t.tracked = nil
		for id in t.active do
			local q = Quests.byId[id]
			if not t.tracked or (q and q.line == "story") then t.tracked = id end
		end
	end
	local s = TownQuestService.state(player)
	if s then Remotes.Push:FireClient(player, "tq", s) end
	refreshTarget(player)
end
TownQuestService.push = push

local function sendItems(player, q, st)
	local s = stepOf(q, st)
	if not s or s.kind ~= "collect" then return end
	local spots = {}
	for i, name in s.spots do spots[i] = Places.get(name).pos end
	Remotes.Push:FireClient(player, "tqItems", { id = q.id, step = st.step, item = s.item, spots = spots, got = st.got or {} })
end

local complete -- (forward)

local function advance(player, q, st)
	st.step += 1
	st.prog = 0
	st.got = nil
	if st.step > #q.steps then
		complete(player, q)
		return
	end
	local s = stepOf(q, st)
	sendItems(player, q, st)
	if s.kind == "scene" then
		-- the cutscene engine plays it and reports back; without one, it just passes
		Remotes.Cutscene:FireClient(player, "Play", s.scene, { quest = q.id })
		task.delay(40, function()
			local t = tqOf(player)
			if t and t.active[q.id] == st and stepOf(q, st) == s then advance(player, q, st) push(player) end
		end)
	end
	local starter = TownQuestService.starters[s.kind]
	if starter then task.spawn(starter, player, q, s, st) end
	Signals.fire("tqStep", player, q.id, st.step)
end

local function rewardText(player, r)
	local out = {}
	if not r then return out end
	local p = Data.get(player)
	if r.incomeSecs or r.min then
		local inc = player:GetAttribute("BaseIncome") or player:GetAttribute("IncomePerSec") or 0
		local cash = math.max(r.min or 0, math.floor(inc * (r.incomeSecs or 0)))
		if cash > 0 then
			Data.addCash(player, cash)
			table.insert(out, "+" .. Config.formatCash(cash))
		end
	end
	if r.candy and p then
		p.candy = (p.candy or 0) + r.candy
		player:SetAttribute("Candy", p.candy)
		table.insert(out, ("+%d Candy"):format(r.candy))
	end
	if r.vials and p then
		p.vials = (p.vials or 0) + r.vials
		player:SetAttribute("Vials", p.vials)
		table.insert(out, ("+%d Mutagen Vial%s"):format(r.vials, r.vials == 1 and "" or "s"))
	end
	for id, n in r.gear or {} do
		local ok = pcall(function() require(script.Parent.GearService).give(player, id, n) end)
		local g = Config.GearById and Config.GearById[id]
		if ok then table.insert(out, ("+%d %s"):format(n, g and g.name or id)) end
	end
	if r.unlock then
		AreaService.open(player, r.unlock)
		local a = Config.AreaById[r.unlock]
		table.insert(out, "Opened " .. (a and a.name or r.unlock) .. "!")
	end
	return out
end

complete = function(player, q)
	local t = tqOf(player)
	if not t then return end
	t.active[q.id] = nil
	t.done[q.id] = true
	if t.tracked == q.id then
		t.tracked = nil
		-- keep following something: the story first
		for id in t.active do
			local other = Quests.byId[id]
			if not t.tracked or (other and other.line == "story") then t.tracked = id end
		end
	end
	local rewards = rewardText(player, q.reward)
	Remotes.Push:FireClient(player, "tqDone", { id = q.id, title = q.title, line = q.line, rewards = rewards, outro = q.outro })
	if q.reward and q.reward.scene then Remotes.Cutscene:FireClient(player, "Play", q.reward.scene, { quest = q.id }) end
	Signals.fire("tqDone", player, q.id)
	AreaService.refresh(player)
	task.spawn(Data.save, player)
	Data.saveSoon(player) -- (the cash went to the school)
	-- a story quest that starts by itself may be next
	task.delay(2.5, function() TownQuestService.autoStart(player) end)
end

function TownQuestService.start(player, id, fromNpc)
	local q = Quests.byId[id]
	if not q then return false end
	local ok, why = canStart(player, q)
	if not ok then return false, why end
	local t = tqOf(player)
	local st = { step = 0, prog = 0 }
	t.active[id] = st
	if not t.tracked or q.line == "story" then t.tracked = id end
	Signals.fire("tqStart", player, id)
	advance(player, q, st)
	push(player)
	return true
end

-- story quests with no giver begin as soon as they can (a call, a letter)
function TownQuestService.autoStart(player)
	local t = tqOf(player)
	if not t then return end
	for _, q in Quests.list do
		if q.auto and not t.done[q.id] and not t.active[q.id] and canStart(player, q) then
			if q.intro then
				Remotes.Push:FireClient(player, "missionTalk", { lines = q.intro, bye = "LET'S GO!", call = true, title = "QUEST: " .. q.title })
			end
			TownQuestService.start(player, q.id)
			return
		end
	end
end

---------------------------------------------------------------------------
-- talking to townspeople
---------------------------------------------------------------------------
local function onTalk(player, npcId)
	local t = tqOf(player)
	if not t then return false end
	-- a step waiting on this person
	for id, st in t.active do
		local q = Quests.byId[id]
		local s = q and stepOf(q, st)
		if s and (s.kind == "talk" or s.kind == "deliver") and s.npc == npcId then
			local lines = s.lines
			if not lines then
				local def = Townsfolk.byId[npcId]
				lines = { { def.name:upper(), npcId, s.kind == "deliver" and ("For me? Thank you!") or "Oh, hello! Yes, I heard about that." } }
			end
			local last = st.step == #q.steps
			if last and q.outro then
				lines = table.clone(lines)
				for _, l in q.outro do table.insert(lines, l) end
			end
			Remotes.Push:FireClient(player, "missionTalk", { lines = lines, npc = npcId, title = "QUEST: " .. q.title })
			advance(player, q, st)
			push(player)
			return true
		end
	end
	-- their quest, if you can take it (the story first)
	local offer
	for _, q in Quests.list do
		if q.giver == npcId and not t.done[q.id] and not t.active[q.id] and not blocked(player, q) then
			if not offer or (q.line == "story" and offer.line ~= "story") then offer = q end
		end
	end
	if offer then
		local ok, why = canStart(player, offer)
		if not ok and why == "full" then
			local def = Townsfolk.byId[npcId]
			Remotes.Push:FireClient(player, "missionTalk", { npc = npcId, lines = { { def.name:upper(), npcId, "You look busy! Finish one of your other jobs and come back, I've got something for you." } } })
			return true
		end
		if ok then
			Remotes.Push:FireClient(player, "missionTalk", {
				id = offer.id, title = "QUEST: " .. offer.title, lines = offer.intro, action = "tqAccept", npc = npcId,
				accept = "ACCEPT QUEST", story = offer.line == "story",
			})
			return true
		end
	end
	return false
end

---------------------------------------------------------------------------
-- steps that tick on their own
---------------------------------------------------------------------------
local function visitTick()
	for _, player in Players:GetPlayers() do
		local t = tqOf(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if t and root then
			for id, st in t.active do
				local q = Quests.byId[id]
				local s = q and stepOf(q, st)
				if s and s.kind == "visit" then
					local p = Places.get(s.place)
					if p and (root.Position - p.pos).Magnitude <= (s.r or 12) then
						advance(player, q, st)
						push(player)
					end
				end
			end
			refreshTarget(player)
		end
	end
end

local function onSignal(name, player, amount, arg)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
	local t = tqOf(player)
	if not t then return end
	local changed = false
	for id, st in t.active do
		local q = Quests.byId[id]
		local s = q and stepOf(q, st)
		if s and s.kind == "signal" and s.signal == name and (s.arg == nil or s.arg == arg or s.arg == amount) then
			local add = s.sum and (tonumber(amount) or 0) or 1
			st.prog = (st.prog or 0) + add
			changed = true
			if st.prog >= s.n then advance(player, q, st) end
		end
	end
	if changed then push(player) end
end

-- a goon knocked out or a runner caught (the goons / chase starters report here)
function TownQuestService.progress(player, questId, add)
	local t = tqOf(player)
	local st = t and t.active[questId]
	local q = Quests.byId[questId]
	local s = st and q and stepOf(q, st)
	if not s then return end
	st.prog = (st.prog or 0) + (add or 1)
	if st.prog >= (stepN(s) or 1) then advance(player, q, st) end
	push(player)
end

---------------------------------------------------------------------------
-- actions from the client
---------------------------------------------------------------------------
Actions.register("tqAccept", function(player, _, id)
	if type(id) ~= "string" then return { ok = false } end
	local ok, why = TownQuestService.start(player, id)
	return { ok = ok, err = why }
end)

Actions.register("tqTrack", function(player, _, id)
	local t = tqOf(player)
	if not t or type(id) ~= "string" or not t.active[id] then return { ok = false } end
	t.tracked = id
	push(player)
	return { ok = true }
end)

Actions.register("tqAbandon", function(player, _, id)
	local t = tqOf(player)
	local q = type(id) == "string" and Quests.byId[id]
	if not t or not q or not t.active[id] or q.line == "story" then return { ok = false } end
	t.active[id] = nil
	if t.tracked == id then t.tracked = next(t.active) end
	push(player)
	return { ok = true }
end)

Actions.register("tqState", function(player)
	return { ok = true, state = TownQuestService.state(player) }
end)

Actions.register("tqCollect", function(player, _, id, index)
	local t = tqOf(player)
	local st = t and type(id) == "string" and t.active[id]
	local q = st and Quests.byId[id]
	local s = q and stepOf(q, st)
	if not s or s.kind ~= "collect" or type(index) ~= "number" then return { ok = false } end
	local name = s.spots[index]
	local place = name and Places.get(name)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not place or not root or (root.Position - place.pos).Magnitude > PICKUP_RANGE + 4 then return { ok = false } end
	st.got = st.got or {}
	if st.got[index] then return { ok = true } end
	st.got[index] = true
	st.prog = (st.prog or 0) + 1
	if st.prog >= stepN(s) then advance(player, q, st) end
	push(player)
	return { ok = true }
end)

-- the cutscene engine: a quest's scene finished playing
Actions.register("tqScene", function(player, _, id)
	local t = tqOf(player)
	local st = t and type(id) == "string" and t.active[id]
	local q = st and Quests.byId[id]
	local s = q and stepOf(q, st)
	if s and s.kind == "scene" then
		advance(player, q, st)
		push(player)
	end
	return { ok = true }
end)

---------------------------------------------------------------------------
function TownQuestService.debugState(player)
	local t = tqOf(player)
	return t and { active = t.active, done = t.done, tracked = t.tracked, target = player:GetAttribute("QuestTarget") }
end

-- mark quests done without playing them (tests)
function TownQuestService.debugMark(player, ids)
	local t = tqOf(player)
	if not t then return false end
	for _, id in ids do
		t.active[id] = nil
		t.done[id] = true
	end
	push(player)
	return true
end

function TownQuestService.debugReset(player)
	local own = Data.own(player)
	if own then own.tq = nil end
	push(player)
	return true
end

function TownQuestService.start_service()
	local errs = Quests.validate(Places, Townsfolk, Config.AreaById, Cutscenes)
	for _, e in errs do warn("[Quests] " .. e) end
	TownNPCService.onTalk = onTalk
	-- every signal a step listens for
	local names = {}
	for _, q in Quests.list do
		for _, s in q.steps do
			if s.kind == "signal" then names[s.signal] = true end
		end
	end
	for name in names do
		Signals.on(name, function(player, ...) onSignal(name, player, ...) end)
	end
	-- anything that can open a quest: re-send the markers
	for _, sig in { "questDone", "chapterDone", "review", "areaOpen", "tqDone", "questStep" } do
		Signals.on(sig, function(player)
			if typeof(player) == "Instance" and player:IsA("Player") then
				for _, pl in Data.schoolPlayers(player) do
					task.defer(push, pl)
					task.delay(1, TownQuestService.autoStart, pl)
				end
			end
		end)
	end
	local function joined(player)
		for _ = 1, 60 do
			if Data.own(player) then break end
			task.wait(0.5)
		end
		if not player.Parent then return end
		push(player)
		local t = tqOf(player)
		for id, st in t and t.active or {} do
			local q = Quests.byId[id]
			if q then
				if st.step < 1 then st.step = 1 end
				sendItems(player, q, st)
			end
		end
		task.delay(6, TownQuestService.autoStart, player)
	end
	Players.PlayerAdded:Connect(function(player) task.spawn(joined, player) end)
	for _, player in Players:GetPlayers() do task.spawn(joined, player) end
	task.spawn(function()
		while true do
			task.wait(0.5)
			local ok, err = pcall(visitTick)
			if not ok then warn("[TownQuests]", err) end
		end
	end)
end

return TownQuestService
