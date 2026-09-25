-- ServerScriptService.Server.ChapterService
-- Principal's Requests (Config.Chapters): the story spine after the First Day tutorial. One chapter
-- per tier from Elementary on: four requests in any order, then "Face the Board". Requests about owning
-- something complete the moment you own it (bought earlier counts); counted ones advance on Signals.
-- The client gets Remotes.Push("chapter", state) and draws the checklist.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)
local LetterService = require(script.Parent.LetterService)

local ChapterService = {}

local STEPS = 5 -- four requests and the Board

local function tutorialDone(p)
	return (p.tutorial or 1) > #Config.Tutorial
end

-- the saved record, made on first use; a save from before chapters existed starts at its own tier
local function rec(p)
	if not p.chapter then
		local n = math.clamp((p.tier or 1) - 1, 1, #Config.Chapters)
		p.chapter = { n = n, done = { false, false, false, false, false }, prog = { 0, 0, 0, 0 }, intro = true }
	end
	return p.chapter
end

-- after a chapter finishes, its successor waits a moment so the title card comes first
local holdUntil = {}
Players.PlayerRemoving:Connect(function(player)
	holdUntil[player] = nil
end)

local function article(word)
	return word:match("^[AEIOUaeiou]") and "an" or "a"
end

local function stepText(step)
	if step.text then return step.text end
	if step.kind == "supply" then
		return "Stock " .. Config.SupplyById[step.id].name
	elseif step.kind == "hire" then
		return "Hire " .. Config.TeacherById[step.id].name .. " (or better)"
	elseif step.kind == "build" then
		return "Build the " .. Config.BuildById[step.id].name
	elseif step.kind == "iq" then
		return ("Reach IQ %d (stock supplies)"):format(step.n)
	elseif step.kind == "own" then
		if step.n == 1 then return ("Own %s %s kid"):format(article(step.rarity), step.rarity) end
		return ("Own %d %s kids at once"):format(step.n, step.rarity)
	elseif step.kind == "builds" then
		return ("Own %d School Builder items"):format(step.n)
	elseif step.kind == "mission" then
		return "Mission: " .. Config.Missions[step.id].title
	end
	return "?"
end

local function boardText(n)
	if n >= #Config.Chapters then return "Face the Board: first Prestige star" end
	return "Face the Board: " .. Config.Tiers[Config.ChapterTier(n) + 1].name
end

-- which shop tab or panel a request lives behind (the client's GO button)
local function guideOf(step)
	if step.kind == "supply" or step.kind == "iq" then return "shop:1" end
	if step.kind == "hire" then return "shop:2" end
	if step.kind == "build" or step.kind == "builds" then return "shop:3" end
	if step.kind == "mission" then return "npc:Wobblesworth" end
	return nil
end

local function owns(p, step)
	if step.kind == "supply" then
		return p.supplies ~= nil and p.supplies[step.id] ~= nil
	elseif step.kind == "hire" then
		-- that teacher or a better one: the shop won't put a worse teacher on a floor, so an exact
		-- match could become impossible once the player has moved past it
		local want = Config.TeacherById[step.id].mult
		for _, t in p.teachers or {} do
			local def = Config.TeacherById[t.id]
			if def and def.mult >= want then return true end
		end
		return false
	elseif step.kind == "build" then
		return p.builds ~= nil and p.builds[step.id] ~= nil
	elseif step.kind == "iq" then
		local iq = 100
		for id in p.supplies or {} do
			local s = Config.SupplyById[id]
			if s then iq += s.iq end
		end
		return iq >= step.n
	elseif step.kind == "own" then
		local want = Config.RarityById[step.rarity].order
		local top = Config.RarityById.Secret.order -- Alumni don't count as "rarer"
		local n = 0
		for _, e in p.students do
			local def = Config.StudentById[e.id]
			local order = def and Config.RarityById[def.rarity].order or 0
			if order >= want and order <= top then n += 1 end
		end
		return n >= step.n
	elseif step.kind == "builds" then
		local n = 0
		for id in p.builds or {} do
			if Config.BuildById[id] then n += 1 end
		end
		return n >= step.n
	elseif step.kind == "mission" then
		return p.missions ~= nil and p.missions[step.id] == true
	end
	return false
end

local function boardDone(p, n)
	if n >= #Config.Chapters then return (p.stars or 0) >= 1 end
	return (p.tier or 1) > Config.ChapterTier(n)
end

-- a request pays a slice of what the next Board review costs, so it always means the same step forward
local function rewardOf(player, n, i)
	local tier = Config.ChapterTier(n)
	local nxt = Config.Tiers[math.min(tier + 1, #Config.Tiers)]
	local step = Config.Chapters[n] and Config.Chapters[n].steps[i]
	local mult = step and step.kind == "mission" and Config.MissionRewardMult or 1
	return math.floor(nxt.cash * Config.ChapterPct * mult)
end

function ChapterService.state(player)
	local p = Data.get(player)
	if not p or not tutorialDone(p) then return { hidden = true } end
	local c = rec(p)
	local ch = Config.Chapters[c.n]
	if not ch then return { hidden = true, finished = true } end
	local steps = {}
	for i, step in ch.steps do
		steps[i] = {
			text = stepText(step),
			done = c.done[i],
			progress = step.kind == "count" and (c.prog[i] or 0) or nil,
			count = step.kind == "count" and step.count or nil,
			reward = rewardOf(player, c.n, i),
			candy = Config.ChapterCandy[i],
			guide = guideOf(step),
			mission = step.kind == "mission" or nil,
		}
	end
	steps[STEPS] = { text = boardText(c.n), done = c.done[STEPS], guide = "panel:Board", board = true }
	return {
		n = c.n,
		total = #Config.Chapters,
		title = ch.title,
		host = ch.host,
		letter = ch.letter,
		steps = steps,
	}
end

function ChapterService.push(player)
	Remotes.Push:FireClient(player, "chapter", ChapterService.state(player))
end

local evaluate

local function complete(player, p, c, i)
	c.done[i] = true
	local ch = Config.Chapters[c.n]
	if i == STEPS then return end
	local cash = rewardOf(player, c.n, i)
	local candy = Config.ChapterCandy[i]
	if p.reviewing then
		-- the Board is about to reset cash (BoardService): pay once the review is over
		task.spawn(function()
			while p.reviewing do task.wait(0.25) end
			if player.Parent and Data.get(player) == p then Data.addCash(player, cash) end
		end)
	else
		Data.addCash(player, cash)
	end
	p.candy = (p.candy or 0) + candy
	player:SetAttribute("Candy", p.candy)
	Remotes.Push:FireClient(player, "chapterStep", { text = stepText(ch.steps[i]), reward = cash, candy = candy })
	Remotes.Sfx:FireClient(player, "Token")
	Signals.fire("chapterStep", player, c.n, i)
end

-- all five done: fill the chapter's letter and open the next chapter
local function finish(player, p, c)
	local ch = Config.Chapters[c.n]
	LetterService.fill(player, ch.letter)
	Remotes.Announce:FireClient(player, ("CHAPTER %d COMPLETE!"):format(c.n), Color3.fromRGB(255, 159, 26))
	Remotes.Sfx:FireClient(player, "Cheer")
	Remotes.Notify:FireClient(player, ("A %s student is on the way to your Waiting Bench!"):format(ch.letter), "good")
	Signals.fire("chapterDone", player, c.n)
	p.chapter = { n = c.n + 1, done = { false, false, false, false, false }, prog = { 0, 0, 0, 0 } }
	local nxt = Config.Chapters[c.n + 1]
	holdUntil[player] = os.clock() + 2.9
	task.delay(3, function()
		if not player.Parent or Data.get(player) ~= p then return end
		if nxt then
			Remotes.Push:FireClient(player, "chapterStart", { n = c.n + 1, title = nxt.title, host = nxt.host, line = nxt.line })
		end
		evaluate(player)
	end)
end

-- complete whatever the player already satisfies, then send the checklist
evaluate = function(player)
	local p = Data.get(player)
	if not p or not tutorialDone(p) then return end
	local c = rec(p)
	local ch = Config.Chapters[c.n]
	if not ch then return end
	if c.intro then
		c.intro = nil
		Remotes.Push:FireClient(player, "chapterStart", { n = c.n, title = ch.title, host = ch.host, line = ch.line })
	end
	if holdUntil[player] and os.clock() < holdUntil[player] then
		ChapterService.push(player)
		return
	end
	for i, step in ch.steps do
		if not c.done[i] and step.kind ~= "count" and owns(p, step) then complete(player, p, c, i) end
	end
	if not c.done[STEPS] and boardDone(p, c.n) then complete(player, p, c, STEPS) end
	local all = true
	for i = 1, STEPS do
		if not c.done[i] then all = false end
	end
	if all then
		finish(player, p, c)
	end
	ChapterService.push(player)
end
ChapterService.evaluate = evaluate

-- a counted request: signal fired, and when the request names an arg, the first arg matches it
local function counted(player, signal, arg)
	local p = Data.get(player)
	if not p or not tutorialDone(p) then return end
	local c = rec(p)
	local ch = Config.Chapters[c.n]
	if not ch then return end
	local hit = false
	for i, step in ch.steps do
		if not c.done[i] and step.kind == "count" and step.signal == signal and (step.arg == nil or step.arg == arg) then
			c.prog[i] = (c.prog[i] or 0) + 1
			if c.prog[i] >= step.count then complete(player, p, c, i) end
			hit = true
		end
	end
	if hit then evaluate(player) end
end

Actions.register("chapter", function(player)
	evaluate(player)
	return ChapterService.state(player)
end)

function ChapterService.start()
	Signals.on("questDone", function(player, _, kind)
		if kind ~= "tutorial" or typeof(player) ~= "Instance" or not player:IsA("Player") then return end
		local p = Data.get(player)
		if p and tutorialDone(p) and not p.chapter then
			p.chapter = { n = 1, done = { false, false, false, false, false }, prog = { 0, 0, 0, 0 }, intro = true }
		end
	end)
	-- signals the counted requests listen for
	local listening = {}
	for _, ch in Config.Chapters do
		for _, step in ch.steps do
			if step.kind == "count" and not listening[step.signal] then
				listening[step.signal] = true
				Signals.on(step.signal, function(player, arg)
					if typeof(player) == "Instance" and player:IsA("Player") then counted(player, step.signal, arg) end
				end)
			end
		end
	end
	-- anything that can change what you own, your tier, or finish the tutorial
	for _, name in { "supply", "hire", "build", "enroll", "review", "questDone", "sell", "missionWon" } do
		Signals.on(name, function(player)
			if typeof(player) == "Instance" and player:IsA("Player") then
				task.defer(evaluate, player)
			end
		end)
	end
end

-- Studio: jump to a chapter (n) with nothing done
function ChapterService.debugSet(player, n)
	local p = Data.get(player)
	if not p then return false end
	p.tutorial = math.max(p.tutorial or 1, #Config.Tutorial + 1)
	p.chapter = { n = n, done = { false, false, false, false, false }, prog = { 0, 0, 0, 0 } }
	require(script.Parent.QuestService).push(player)
	evaluate(player)
	return ChapterService.state(player)
end

return ChapterService
