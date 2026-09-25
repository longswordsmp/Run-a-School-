-- ServerScriptService.Server.RewardService
-- Reasons to come back and to stay:
--   Daily login streak (7-day cycle, UTC days): claim once a day from the Daily panel; missing a day
--     starts the streak over. Day 7 is a free Epic kid delivered to your Waiting Bench.
--   Playtime gifts: 5, 10, 20, 30, 45, 60, 90 and 120 minutes into a session. The HUD always shows
--     the next one.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)
local Actions = require(script.Parent.Actions)
local Signals = require(script.Parent.Signals)

local RewardService = {}

local function tuition(player, seconds, floor)
	return math.max(floor or 100, math.floor((player:GetAttribute("BaseIncome") or 0) * seconds))
end

local function addCandy(player, p, n)
	p.candy = (p.candy or 0) + n
	player:SetAttribute("Candy", p.candy)
end

local function letterNow(player, rarity, fraction)
	local L = require(script.Parent.LetterService)
	if fraction then
		local p = Data.get(player)
		if p and p.letters and p.letters[rarity] then
			p.letters[rarity] = math.floor(p.letters[rarity] * (1 - fraction))
		end
	else
		L.debugReady(player, rarity)
	end
end

---------------------------------------------------------------------------
-- daily streak
---------------------------------------------------------------------------
RewardService.Daily = {
	{ text = "10 min of tuition", give = function(player, p) local n = tuition(player, 600, 500) Data.addCash(player, n) return "+" .. Config.formatCash(n) end },
	{ text = "50 Candy", give = function(player, p) addCandy(player, p, 50) return "+50 candy" end },
	{ text = "Rare Letter, ready now", give = function(player) letterNow(player, "Rare") return "Rare Letter ready!" end },
	{ text = "15 min of tuition", give = function(player, p) local n = tuition(player, 900, 800) Data.addCash(player, n) return "+" .. Config.formatCash(n) end },
	{ text = "Epic Letter, ready now", give = function(player) letterNow(player, "Epic") return "Epic Letter ready!" end },
	{ text = "100 Candy", give = function(player, p) addCandy(player, p, 100) return "+100 candy" end },
	{ text = "A FREE Epic kid", give = function(player, p)
		local pool = {}
		for _, s in Config.Students do
			if s.rarity == "Epic" then table.insert(pool, s) end
		end
		local def = pool[math.random(#pool)]
		require(script.Parent.LetterService).deliver(player, def, true)
		return "Free " .. def.name .. " on your bench!"
	end },
}

local function today()
	return math.floor(os.time() / 86400)
end

-- where the player is in the cycle, and whether today's reward is waiting
function RewardService.dailyState(p)
	p.login = p.login or { day = 0, streak = 0 }
	local d = today()
	local claimed = p.login.day == d
	local streak = p.login.streak or 0
	if not claimed then
		-- yesterday keeps the streak going; anything older starts again
		streak = (p.login.day == d - 1) and streak + 1 or 1
	end
	local cycleDay = (streak - 1) % #RewardService.Daily + 1
	return { claimed = claimed, streak = streak, day = cycleDay }
end

Actions.register("daily", function(player, p)
	local s = RewardService.dailyState(p)
	local list = {}
	for i, r in RewardService.Daily do list[i] = r.text end
	return { ok = true, claimed = s.claimed, streak = s.streak, day = s.day, rewards = list }
end)

Actions.register("claimDaily", function(player, p)
	local s = RewardService.dailyState(p)
	if s.claimed then return { ok = false, err = "Come back tomorrow!" } end
	p.login.day = today()
	p.login.streak = s.streak
	local text = RewardService.Daily[s.day].give(player, p)
	Remotes.Announce:FireClient(player, ("DAY %d: %s"):format(s.streak, text:upper()), Color3.fromRGB(255, 200, 80))
	Remotes.Sfx:FireClient(player, "Rare")
	Signals.fire("daily", player, s.streak)
	return { ok = true, text = text, streak = s.streak }
end)

---------------------------------------------------------------------------
-- playtime gifts
---------------------------------------------------------------------------
RewardService.Gifts = {
	{ min = 5, text = "$1,000", give = function(player) Data.addCash(player, math.max(1000, tuition(player, 60))) end },
	{ min = 10, text = "A free teacher", give = function(player, p)
		if not p.teachers[1] then
			p.teachers[1] = { id = "SubSteve" }
			require(script.Parent.TeacherService).refresh(player)
			PlotService.updateIncome(player)
		else
			Data.addCash(player, tuition(player, 300, 1000))
		end
	end },
	{ min = 20, text = "Epic Letter ready", give = function(player) letterNow(player, "Epic") end },
	{ min = 30, text = "100 Candy", give = function(player, p) addCandy(player, p, 100) end },
	{ min = 45, text = "10 min of tuition", give = function(player) Data.addCash(player, tuition(player, 600, 2000)) end },
	{ min = 60, text = "15 min of tuition", give = function(player) Data.addCash(player, tuition(player, 900, 3000)) end },
	{ min = 90, text = "20 min of tuition", give = function(player) Data.addCash(player, tuition(player, 1200, 5000)) end },
	{ min = 120, text = "Legendary Letter +50%", give = function(player) letterNow(player, "Legendary", 0.5) end },
}

local session = {} -- [player] = { start, given }

function RewardService.start()
	Players.PlayerRemoving:Connect(function(player)
		session[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for player, p in Data.all() do
				local s = session[player]
				if not s then
					s = { start = os.clock(), given = 0 }
					session[player] = s
				end
				local mins = (os.clock() - s.start) / 60
				local nextGift = RewardService.Gifts[s.given + 1]
				if nextGift then
					if mins >= nextGift.min then
						s.given += 1
						local ok, err = pcall(nextGift.give, player, p)
						if not ok then warn("[Reward] gift failed", err) end
						Remotes.Announce:FireClient(player, "\u{1F381} PLAYTIME GIFT: " .. nextGift.text:upper(), Color3.fromRGB(255, 150, 220))
						Remotes.Sfx:FireClient(player, "Token")
						Signals.fire("gift", player, nextGift.min)
					end
					local following = RewardService.Gifts[s.given + 1]
					player:SetAttribute("NextGiftAt", following and (workspace:GetServerTimeNow() + (following.min - mins) * 60) or nil)
					player:SetAttribute("NextGiftText", following and following.text or nil)
				else
					player:SetAttribute("NextGiftAt", nil)
				end
			end
		end
	end)
end

-- test hook: jump the session clock forward
function RewardService.debugSkip(player, minutes)
	local s = session[player]
	if s then s.start -= minutes * 60 end
	return s ~= nil
end

return RewardService
