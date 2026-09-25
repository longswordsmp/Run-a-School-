-- ServerScriptService.Server.DailyService
-- Daily Requests (Config.DailyPool): three a day on the UTC clock, the same three for a player all day,
-- one free reroll. Each pays candy; finishing all three opens Loretta's Lunch Box (Config.LunchBox).
-- Shown in the Daily panel under the login streak.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)

local DailyService = {}

local byId = {}
for _, q in Config.DailyPool do byId[q.id] = q end

local function today()
	return math.floor(os.time() / 86400)
end

-- three distinct requests, picked from the player's id and the day so a rejoin gets the same ones
local function pickFor(userId, day, avoid)
	local rng = Random.new(userId * 7 + day * 131 + (avoid and 17 or 0))
	local pool = {}
	for _, q in Config.DailyPool do
		if not (avoid and (avoid[q.id] or avoid[q.group or q.signal])) then table.insert(pool, q.id) end
	end
	-- one request per signal, so a single catch or enroll never pays two requests
	local out, used = {}, {}
	while #out < 3 and #pool > 0 do
		local id = table.remove(pool, rng:NextInteger(1, #pool))
		local sig = byId[id].group or byId[id].signal
		if not used[sig] then
			used[sig] = true
			table.insert(out, id)
		end
	end
	return out
end

-- today's record, rolled over when the UTC day changes
local function rec(player, p)
	local d = today()
	if not p.dailyQ or p.dailyQ.day ~= d then
		local old = p.dailyQ
		-- a Lunch Box earned yesterday and not opened is kept
		local owed = old ~= nil and (old.owedBox == true or (old.done[1] and old.done[2] and old.done[3] and not old.box)) or false
		p.dailyQ = { day = d, ids = pickFor(player.UserId, d), prog = { 0, 0, 0 }, done = { false, false, false }, box = false, rerolled = false, owedBox = owed }
	end
	return p.dailyQ
end

function DailyService.state(player)
	local p = Data.get(player)
	if not p then return { ok = false } end
	local r = rec(player, p)
	local list = {}
	for i, id in r.ids do
		local q = byId[id]
		if q then
			list[i] = { id = id, text = q.text, progress = math.min(r.prog[i] or 0, q.count), count = q.count, done = r.done[i] }
		end
	end
	local allDone = r.done[1] and r.done[2] and r.done[3]
	local ready = (allDone and not r.box) or r.owedBox == true
	local odds = {}
	local total = 0
	for _, b in Config.LunchBox do total += b.weight end
	for i, b in Config.LunchBox do odds[i] = { text = b.text, pct = math.floor(b.weight / total * 1000 + 0.5) / 10 } end
	-- seconds until the next UTC day
	local resetIn = (today() + 1) * 86400 - os.time()
	return {
		ok = true,
		requests = list,
		candy = Config.DailyCandy,
		boxReady = ready,
		boxOpened = r.box and not ready,
		canReroll = not r.rerolled,
		odds = odds,
		resetIn = resetIn,
	}
end

-- the red "!" on the Daily button: today's streak reward or the Lunch Box is waiting
-- (not during the first tutorial steps, same as the panel's auto-open)
function DailyService.badge(player)
	local p = Data.get(player)
	if not p then return end
	local r = rec(player, p)
	local streak = require(script.Parent.RewardService).dailyState(p)
	local box = (r.done[1] and r.done[2] and r.done[3] and not r.box) or r.owedBox == true
	player:SetAttribute("DailyReady", (p.tutorial or 1) > 5 and (not streak.claimed or box) or false)
end

local function push(player)
	Remotes.Push:FireClient(player, "dailyQ", DailyService.state(player))
	DailyService.badge(player)
end

local function progress(player, signal, def)
	local p = Data.get(player)
	if not p then return end
	local r = rec(player, p)
	local changed = false
	for i, id in r.ids do
		local q = byId[id]
		if q and not r.done[i] and q.signal == signal then
			local counts = true
			if q.rarity then
				local want = Config.RarityById[q.rarity].order
				local got = def and def.rarity and Config.RarityById[def.rarity] and Config.RarityById[def.rarity].order or 0
				counts = got >= want and got <= Config.RarityById.Secret.order
			end
			if counts then
				r.prog[i] = (r.prog[i] or 0) + 1
				changed = true
				if r.prog[i] >= q.count then
					r.done[i] = true
					p.candy = (p.candy or 0) + Config.DailyCandy
					player:SetAttribute("Candy", p.candy)
					Remotes.Notify:FireClient(player, ("Daily request done: %s  +%d candy"):format(q.text, Config.DailyCandy), "good")
					Remotes.Sfx:FireClient(player, "Token")
					if r.done[1] and r.done[2] and r.done[3] then
						Remotes.Announce:FireClient(player, "LUNCH BOX READY! (Daily panel)", Color3.fromRGB(255, 159, 26))
					end
				end
			end
		end
	end
	if changed then push(player) end
end

Actions.register("dailyQ", function(player)
	return DailyService.state(player)
end)

-- swap one unfinished request for another one (once a day)
Actions.register("rerollDaily", function(player, p, index, seenId)
	if type(index) ~= "number" then return { ok = false } end
	local r = rec(player, p)
	index = math.floor(index)
	if seenId ~= nil and r.ids[index] ~= seenId then
		-- the panel was showing yesterday's requests: send today's instead of spending the reroll
		local s = DailyService.state(player)
		s.ok = false
		s.err = "New day, new requests!"
		Remotes.Push:FireClient(player, "dailyQ", DailyService.state(player))
		return s
	end
	if r.rerolled then return { ok = false, err = "One reroll a day!" } end
	if not r.ids[index] or r.done[index] or (r.prog[index] or 0) > 0 then
		return { ok = false, err = "Only a request you haven't started" }
	end
	local avoid = {}
	for i, id in r.ids do
		avoid[id] = true
		if i ~= index then avoid[byId[id].group or byId[id].signal] = true end
	end
	r.ids[index] = pickFor(player.UserId, r.day, avoid)[1]
	r.prog[index] = 0
	r.rerolled = true
	return DailyService.state(player)
end)

Actions.register("openLunchBox", function(player, p)
	local r = rec(player, p)
	if r.owedBox then
		r.owedBox = false -- yesterday's box first
	else
		if not (r.done[1] and r.done[2] and r.done[3]) then return { ok = false, err = "Finish all 3 requests first" } end
		if r.box then return { ok = false, err = "Already opened today" } end
		r.box = true
	end
	local total = 0
	for _, b in Config.LunchBox do total += b.weight end
	local roll = math.random() * total
	local prize = Config.LunchBox[1]
	for _, b in Config.LunchBox do
		roll -= b.weight
		if roll <= 0 then
			prize = b
			break
		end
	end
	if prize.id == "candy" then
		p.candy = (p.candy or 0) + 80
		player:SetAttribute("Candy", p.candy)
	else
		require(script.Parent.LetterService).fill(player, prize.id)
	end
	Remotes.Announce:FireClient(player, "LUNCH BOX: " .. prize.text:upper() .. "!", Color3.fromRGB(255, 159, 26))
	Remotes.Sfx:FireClient(player, prize.id == "candy" and "Cheer" or "Rare")
	Signals.fire("lunchBox", player, prize.id)
	local s = DailyService.state(player)
	s.prize = prize.text
	Remotes.Push:FireClient(player, "dailyQ", s)
	DailyService.badge(player)
	return s
end)

function DailyService.start()
	-- the badge: after a claim, a tutorial step, and every minute (the UTC day rolls over)
	for _, name in { "daily", "questDone" } do
		Signals.on(name, function(player)
			if typeof(player) == "Instance" and player:IsA("Player") then DailyService.badge(player) end
		end)
	end
	task.spawn(function()
		local lastDay = today()
		while true do
			local rolled = today() ~= lastDay
			lastDay = today()
			for _, player in Players:GetPlayers() do
				if rolled then pcall(push, player) else pcall(DailyService.badge, player) end
			end
			task.wait(60)
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		task.delay(5, function()
			if player.Parent then pcall(DailyService.badge, player) end
		end)
	end)
	local listening = {}
	for _, q in Config.DailyPool do
		if not listening[q.signal] then
			listening[q.signal] = true
			Signals.on(q.signal, function(player, a1)
				if typeof(player) == "Instance" and player:IsA("Player") then
					-- enroll passes the student def first; everything else just counts
					progress(player, q.signal, type(a1) == "table" and a1 or nil)
				end
			end)
		end
	end
end

-- Studio: finish today's requests (n of them)
function DailyService.debugFinish(player, n)
	local p = Data.get(player)
	if not p then return false end
	local r = rec(player, p)
	for i = 1, math.min(n or 3, 3) do
		local q = byId[r.ids[i]]
		local guard = 0
		while not r.done[i] and guard < 100 do
			progress(player, q.signal, { rarity = "Secret" })
			guard += 1
		end
	end
	return DailyService.state(player)
end

return DailyService
