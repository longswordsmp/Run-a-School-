-- ServerScriptService.Server.UnlockService
-- The side buttons appear when the player first needs them, not all at once on the first minute:
--   Home, Settings, Coop, Store, Daily   always
--   Upgrades         at the First Morning's "Build 4 desks" step
--   Shop, Board      when Chapter 1 starts (the First Morning is over)
--   Yearbook         after the First Morning, once 5 kids have been enrolled
--   Name             at Chapter 1's "Name your school" step
--   Quests           when Chapter 1 is done
-- Unlocks are kept in the profile (p.unlocked) so a button never disappears again, mirrored onto
-- player attributes UI_<Button> for the client, and a fresh unlock is pushed ("unlock") so the
-- client can pop the button in with a NEW! badge.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)

local UnlockService = {}

local function stepIndex(id)
	for i, s in Config.Tutorial do
		if s.id == id then return i end
	end
	return math.huge
end

local RULES = {
	{ name = "Home", ok = function() return true end },
	{ name = "Settings", ok = function() return true end },
	{ name = "Coop", ok = function() return true end }, -- (co-op is for the very first minute too)
	{ name = "Yearbook", ok = function(p) return (p.stats.enrolled or 0) >= 5 and (p.tutorial or 1) > stepIndex("desks") end },
	-- (one new button per beat: nothing in the First Morning but what its step needs)
	{ name = "Shop", ok = function(p) return (p.tutorial or 1) >= stepIndex("k01_pencils") end },
	{ name = "Board", ok = function(p) return (p.tutorial or 1) >= stepIndex("k01_pencils") end },
	-- (the Bus Depot, with the Shop)
	{ name = "Buses", ok = function(p) return (p.tutorial or 1) >= stepIndex("k01_pencils") end },
	-- (desk rows from the First Morning's last step: before, a Kindergarten was stuck on 8 desks until
	-- the first Board review, and to the owner "the upgrades gui is gone")
	{ name = "Upgrades", ok = function(p) return (p.tutorial or 1) >= stepIndex("desks") end },
	{ name = "Name", ok = function(p) return (p.tutorial or 1) >= stepIndex("k03_name") end },
	-- (the Store and the Daily rewards are always there: the owner wants them from the first minute)
	{ name = "Daily", ok = function() return true end },
	{ name = "Store", ok = function() return true end },
	{ name = "Files", ok = function(p) return p.files ~= nil and next(p.files) ~= nil end },
	{ name = "Quests", ok = function(p) return (p.tutorial or 1) > #Config.Tutorial end },
}
UnlockService.Rules = RULES

function UnlockService.refresh(player)
	local p = Data.get(player)
	if not p or not player.Parent then return end
	p.unlocked = p.unlocked or {}
	for _, r in RULES do
		local was = p.unlocked[r.name]
		if not was and r.ok(p) then
			p.unlocked[r.name] = true
			-- (a first join shows the always-on buttons quietly)
			if r.name ~= "Home" and r.name ~= "Settings" and r.name ~= "Coop" and r.name ~= "Store" and r.name ~= "Daily" then
				Remotes.Push:FireClient(player, "unlock", { name = r.name })
			end
		end
		if p.unlocked[r.name] and not player:GetAttribute("UI_" .. r.name) then
			player:SetAttribute("UI_" .. r.name, true)
		end
	end
end

function UnlockService.start()
	for _, name in { "questStep", "questDone", "enroll", "review", "chapterStep" } do
		Signals.on(name, function(player)
			if typeof(player) == "Instance" and player:IsA("Player") then task.defer(UnlockService.refresh, player) end
		end)
	end
	-- (and a slow sweep, for saves loading and Studio jumps)
	task.spawn(function()
		while true do
			task.wait(2)
			for _, player in Players:GetPlayers() do pcall(UnlockService.refresh, player) end
		end
	end)
end

return UnlockService
