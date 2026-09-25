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
	local i = ((p.quests.chain or 1) - 1) % #Config.Goals + 1
	return Config.Goals[i], "goal"
end

local function rewardOf(player, q, kind)
	if kind == "tutorial" then return q.reward end
	local inc = player:GetAttribute("IncomePerSec") or 0
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

-- the client asks once its quest card is ready
Actions.register("quest", function(player)
	return QuestService.state(player) or { ok = false }
end)

local function advance(player, p, q, kind)
	local reward = rewardOf(player, q, kind)
	p.quests.progress = 0
	if kind == "tutorial" then
		p.tutorial += 1
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
	for _, name in { "supply", "hire", "build" } do
		Signals.on(name, function(player)
			QuestService.progress(player, "shopBuy")
		end)
	end
end

return QuestService
