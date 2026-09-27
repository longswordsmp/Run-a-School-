-- ServerScriptService.Server.DealsService
-- Robux offers that turn up when the player needs one (tomas, 2026-09-27: "smart robux integrations,
-- deals that pop up when people need it"), always at the Store's own price:
--   short of cash for something they pressed buy on -> the smallest tuition pack that covers the gap
--   their gate still cooling down when they press lock -> Instant Lock Refresh
-- At most one offer every 4 minutes a player, none in the First Morning, and "Not now" puts that kind
-- of offer away for 15 minutes (Action "dealDismiss"). Push "deal" to the client (Menus draws the
-- card); its BUY is the Store's own purchase path (Action "buy").
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)

local DealsService = {}

local GAP = 240 -- s between offers
local QUIET = 900 -- s a "Not now" lasts
local lastAt, quiet = {}, {} -- [player] = os.clock(); [player][kind] = until

local byKey = {}
for _, x in Config.Products do byKey[x.key] = x end
local function ready(x) return x ~= nil and (x.id ~= 0 or RunService:IsStudio()) end

-- the tuition packs, smallest first
local PACKS = {}
for _, x in Config.Products do
	if x.seconds then table.insert(PACKS, x) end
end
table.sort(PACKS, function(a, b) return a.seconds < b.seconds end)

local function offer(player, kind, key, title, text)
	local now = os.clock()
	if player:GetAttribute("InTutorial") then return end
	if lastAt[player] and now - lastAt[player] < GAP then return end
	local q = quiet[player]
	if q and q[kind] and now < q[kind] then return end
	local x = byKey[key]
	if not ready(x) then return end
	lastAt[player] = now
	Remotes.Push:FireClient(player, "deal", { kind = kind, key = key, title = title, text = text, robux = x.robux })
end

function DealsService.start()
	local Monetization = require(script.Parent.MonetizationService)
	-- (need: what the thing cost, when the refusal said)
	Signals.on("cashShort", function(player, need)
		local p = Data.get(player)
		if not p then return end
		local gap = need and math.max(0, need - p.cash) or 0
		local pick
		for _, x in PACKS do
			if ready(x) and Monetization.cashFor(player, x.seconds) >= gap then
				pick = x
				break
			end
		end
		pick = pick or PACKS[#PACKS]
		if not pick then return end
		local gets = Monetization.cashFor(player, pick.seconds)
		offer(player, "cash", pick.key, "SHORT ON CASH?",
			("The %s gives you %s right now%s."):format(pick.name, Config.formatCash(gets),
				gap > 0 and (" (you need " .. Config.formatCash(gap) .. " more)") or ""))
	end)
	Signals.on("lockCooldown", function(player, left)
		offer(player, "lock", "LockRefresh", "LOCK IT NOW?", ("Your gate is cooling down for %ds. Lock it again right away."):format(left or 0))
	end)
	Actions.register("dealDismiss", function(player, _, kind)
		if type(kind) ~= "string" then return { ok = false } end
		quiet[player] = quiet[player] or {}
		quiet[player][kind] = os.clock() + QUIET
		return { ok = true }
	end)
	Players.PlayerRemoving:Connect(function(pl)
		lastAt[pl] = nil
		quiet[pl] = nil
	end)
end

return DealsService
