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

-- three distinct requests, picked from the player's id and the day (or week) so a rejoin gets the
-- same ones; one request per signal group, so a single catch or enroll never pays two requests
local wById = {}
for _, q in Config.WeeklyPool do wById[q.id] = q end
local function pickFrom(poolDef, lookup, seed, avoid)
	local rng = Random.new(seed + (avoid and 17 or 0))
	local pool = {}
	for _, q in poolDef do
		if not (avoid and (avoid[q.id] or avoid[q.group or q.signal])) then table.insert(pool, q.id) end
	end
	local out, used = {}, {}
	while #out < 3 and #pool > 0 do
		local id = table.remove(pool, rng:NextInteger(1, #pool))
		local sig = lookup[id].group or lookup[id].signal
		if not used[sig] then
			used[sig] = true
			table.insert(out, id)
		end
	end
	return out
end
local function pickFor(userId, day, avoid)
	return pickFrom(Config.DailyPool, byId, userId * 7 + day * 131, avoid)
end

-- weeks start on Monday 00:00 UTC (1 Jan 1970 was a Thursday)
local function weekNum()
	return math.floor((today() + 3) / 7)
end
local function recWeekly(player, p)
	local w = weekNum()
	if not p.weeklyQ or p.weeklyQ.week ~= w then
		local old = p.weeklyQ
		local owed = old ~= nil and (old.owedChest == true or (old.done[1] and old.done[2] and old.done[3] and not old.chest)) or false
		p.weeklyQ = { week = w, ids = pickFrom(Config.WeeklyPool, wById, player.UserId * 11 + w * 977), prog = { 0, 0, 0 }, done = { false, false, false }, chest = false, owedChest = owed }
	end
	return p.weeklyQ
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
	local w = recWeekly(player, p)
	box = box or (w.done[1] and w.done[2] and w.done[3] and not w.chest) or w.owedChest == true
	player:SetAttribute("DailyReady", (p.tutorial or 1) > 5 and (not streak.claimed or box) or false)
end

function DailyService.weeklyState(player)
	local p = Data.get(player)
	if not p then return { ok = false } end
	local r = recWeekly(player, p)
	local list = {}
	for i, id in r.ids do
		local q = wById[id]
		if q then
			list[i] = { id = id, text = q.text, progress = math.min(r.prog[i] or 0, q.count), count = q.count, done = r.done[i] }
		end
	end
	local allDone = r.done[1] and r.done[2] and r.done[3]
	local ready = (allDone and not r.chest) or r.owedChest == true
	local nextWeek = ((weekNum() + 1) * 7 - 3) * 86400
	return {
		ok = true,
		kind = "weekly",
		requests = list,
		candy = Config.WeeklyCandy,
		boxReady = ready,
		boxOpened = r.chest and not ready,
		canReroll = false,
		odds = { { pct = 100, text = "Legendary Letter, ready now" }, { pct = 100, text = Config.WeeklyChestTickets .. " Event Tickets" } },
		resetIn = nextWeek - os.time(),
	}
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
	-- the weekly requests count the same actions
	local w = recWeekly(player, p)
	local wchanged = false
	for i, id in w.ids do
		local q = wById[id]
		if q and not w.done[i] and q.signal == signal then
			w.prog[i] = (w.prog[i] or 0) + 1
			wchanged = true
			if w.prog[i] >= q.count then
				w.done[i] = true
				p.candy = (p.candy or 0) + Config.WeeklyCandy
				player:SetAttribute("Candy", p.candy)
				Remotes.Notify:FireClient(player, ("Weekly request done: %s  +%d candy"):format(q.text, Config.WeeklyCandy), "good")
				Remotes.Sfx:FireClient(player, "Rare")
				if w.done[1] and w.done[2] and w.done[3] then
					Remotes.Announce:FireClient(player, "WEEKLY CHEST READY! (Daily panel)", Color3.fromRGB(255, 159, 26))
				end
			end
		end
	end
	if wchanged then
		Remotes.Push:FireClient(player, "weeklyQ", DailyService.weeklyState(player))
		DailyService.badge(player)
	end
	if changed then push(player) end
end

Actions.register("dailyQ", function(player)
	return DailyService.state(player)
end)

Actions.register("weeklyQ", function(player)
	return DailyService.weeklyState(player)
end)

Actions.register("openWeeklyChest", function(player, p)
	local w = recWeekly(player, p)
	if w.owedChest then
		w.owedChest = false
	else
		if not (w.done[1] and w.done[2] and w.done[3]) then return { ok = false, err = "Finish all 3 weekly requests first" } end
		if w.chest then return { ok = false, err = "Already opened this week" } end
		w.chest = true
	end
	require(script.Parent.LetterService).fill(player, "Legendary")
	p.tickets = (p.tickets or 0) + Config.WeeklyChestTickets
	player:SetAttribute("Tickets", p.tickets)
	Remotes.Announce:FireClient(player, ("WEEKLY CHEST: LEGENDARY LETTER + %d TICKETS!"):format(Config.WeeklyChestTickets), Color3.fromRGB(255, 159, 26))
	Remotes.Sfx:FireClient(player, "Rare")
	local s = DailyService.weeklyState(player)
	s.prize = "a Legendary Letter and " .. Config.WeeklyChestTickets .. " tickets"
	Remotes.Push:FireClient(player, "weeklyQ", s)
	DailyService.badge(player)
	return s
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
	local all = {}
	for _, q in Config.DailyPool do table.insert(all, q) end
	for _, q in Config.WeeklyPool do table.insert(all, q) end
	for _, q in all do
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

-- Studio: finish today's requests (n of them); n = "weekly" finishes this week's
function DailyService.debugFinish(player, n)
	local p = Data.get(player)
	if not p then return false end
	if n == "weekly" then
		local w = recWeekly(player, p)
		for i = 1, 3 do
			local q = wById[w.ids[i]]
			local guard = 0
			while q and not w.done[i] and guard < 400 do
				progress(player, q.signal, { rarity = "Secret" })
				guard += 1
			end
		end
		return DailyService.weeklyState(player)
	end
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
