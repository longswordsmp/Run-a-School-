-- ServerScriptService.Server.QuestService
-- The Principal's To-Do: a tutorial chain for the first session (Config.Tutorial), then goals
-- in rotation (Config.Goals). Progress comes from Signals; the client gets
-- Remotes.Push("quest", state) and draws the card and the guide arrow.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)

local QuestService = {}

local function current(p)
	if p.tutorial and p.tutorial <= #Config.Tutorial then
		return Config.Tutorial[p.tutorial], "tutorial"
	end
	local alone = #game:GetService("Players"):GetPlayers() < 2
	for _ = 1, #Config.Goals do
		local i = ((p.quests.chain or 1) - 1) % #Config.Goals + 1
		local g = Config.Goals[i]
		if not (g.multi and alone) then return g, "goal" end
		p.quests.chain = (p.quests.chain or 1) + 1
		p.quests.progress = 0
	end
	return Config.Goals[1], "goal"
end

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
		step = kind == "tutorial" and p.tutorial or nil,
		steps = #Config.Tutorial,
		text = q.text,
		progress = p.quests.progress or 0,
		count = q.count,
		reward = rewardOf(player, q, kind),
		guide = q.guide,
	}
end

function QuestService.push(player)
	local s = QuestService.state(player)
	if s then Remotes.Push:FireClient(player, "quest", s) end
end

-- the client asks once its quest card is ready; a rejoin mid-tutorial replays the step's moment
local replayed = {}
Actions.register("quest", function(player, p)
	if not replayed[player] and p.tutorial and p.tutorial > 1 and Config.Tutorial[p.tutorial] then
		replayed[player] = true
		local id = Config.Tutorial[p.tutorial].id
		task.delay(3, function()
			if player.Parent then Signals.fire("questStep", player, id) end
		end)
	end
	return QuestService.state(player) or { ok = false }
end)
game:GetService("Players").PlayerRemoving:Connect(function(player)
	replayed[player] = nil
end)

local function advance(player, p, q, kind)
	local reward = rewardOf(player, q, kind)
	p.quests.progress = 0
	if kind == "tutorial" then
		p.tutorial += 1
		local nextStep = Config.Tutorial[p.tutorial]
		if nextStep then
			-- let scripted moments (the cheater, Crumpet, the letter, the smuggler) start
			task.delay(2, function()
				if player.Parent and p.tutorial <= #Config.Tutorial and Config.Tutorial[p.tutorial] == nextStep then
					Signals.fire("questStep", player, nextStep.id)
				end
			end)
		end
	else
		p.quests.chain = (p.quests.chain or 1) + 1
	end
	if reward > 0 then Data.addCash(player, reward) end
	Remotes.Push:FireClient(player, "questDone", { text = q.text, reward = reward, kind = kind })
	Remotes.Sfx:FireClient(player, "Token")
	Signals.fire("questDone", player, q, kind)
	task.delay(1.2, QuestService.push, player)
end

function QuestService.progress(player, signal, amount)
	local p = Data.get(player)
	if not p then return end
	local q, kind = current(p)
	if q.signal ~= signal then return end
	p.quests.progress = (p.quests.progress or 0) + (amount or 1)
	if p.quests.progress >= q.count then
		advance(player, p, q, kind)
	else
		QuestService.push(player)
	end
end

function QuestService.start()
	-- a step the player already satisfies (a gifted teacher, pencils bought early) completes on arrival
	Signals.on("questStep", function(player, id)
		local p = Data.get(player)
		if not p then return end
		-- (the tutorial gifts Curtains, so they don't count as having built something)
		local built = false
		for itemId in p.builds or {} do
			if itemId ~= "Curtains" then built = true end
		end
		local done = (id == "hire" and p.teachers[1] ~= nil) or (id == "pencils" and p.supplies and p.supplies.Pencils)
			or (id == "name" and p.schoolName ~= nil) or (id == "build" and built)
		if done then
			local step = Config.Tutorial[p.tutorial]
			if step and step.id == id then QuestService.progress(player, step.signal, step.count) end
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
	for _, name in { "supply", "hire", "build" } do
		Signals.on(name, function(player)
			QuestService.progress(player, "shopBuy")
		end)
	end
end

return QuestService
