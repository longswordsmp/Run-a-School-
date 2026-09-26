-- ServerScriptService.Server.MonetizationService
-- Game passes and developer products (Config.Passes / Config.Products).
--   Passes: ownership is checked on join and after an in-game purchase; each one sets a player
--     attribute "Pass_<key>" that the systems it affects read.
--   Products: MarketplaceService.ProcessReceipt grants them once per receipt (receipt ids are kept in
--     the saved profile so a retried receipt is never granted twice).
-- Nothing here ever opens a purchase prompt by itself; the client's Store panel asks via "buy".
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local HallService = require(script.Parent.HallService)
local Remotes = require(script.Parent.Remotes)
local Actions = require(script.Parent.Actions)
local Signals = require(script.Parent.Signals)

local MonetizationService = {}

local passByKey, passById, productByKey, productById = {}, {}, {}, {}
for _, x in Config.Passes do
	passByKey[x.key] = x
	if x.id ~= 0 then passById[x.id] = x end
end
for _, x in Config.Products do
	productByKey[x.key] = x
	if x.id ~= 0 then productById[x.id] = x end
end

---------------------------------------------------------------------------
-- passes
---------------------------------------------------------------------------
function MonetizationService.has(player, key)
	return player:GetAttribute("Pass_" .. key) == true
end

local function applyPass(player, key)
	-- (a pass is the buyer's, kept in their own save even while they play for a friend's school)
	local p = Data.own(player)
	player:SetAttribute("Pass_" .. key, true)
	if p then
		p.passes = p.passes or {}
		p.passes[key] = true
	end
	if key == "OfflinePlus" and p then
		p.offlineCapMult = 6 -- 12 h
		p.offlineRateMult = 2 -- 50 %
	end
	if key == "VIP" or key == "LongLock" then PlotService.updateIncome(player) end
	Signals.fire("pass", player, key)
end

-- the grant path, shared by real purchases and the Studio test hook
function MonetizationService.grantPass(player, key)
	local pass = passByKey[key]
	if not pass then return false end
	local p = Data.own(player)
	if p then
		p.passes = p.passes or {}
		p.passes[key] = true
	end
	applyPass(player, key)
	Remotes.Announce:FireClient(player, pass.name:upper() .. " UNLOCKED!", Color3.fromRGB(110, 230, 120))
	Remotes.Sfx:FireClient(player, "StingParty")
	return true
end

local function checkPasses(player)
	local p = Data.own(player)
	for _, pass in Config.Passes do
		local owned = p and p.passes and p.passes[pass.key]
		if pass.id ~= 0 then
			-- ask Roblox every time (a refunded pass goes away); the saved flag only covers an outage
			local ok, res = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.id)
			if ok then owned = res end
		end
		if owned then applyPass(player, pass.key) end
	end
end

---------------------------------------------------------------------------
-- products
---------------------------------------------------------------------------
local GRANTS = {}
local function cashFor(player, seconds)
	-- scales with you, so it can't skip tiers wildly; a small floor for brand-new schools
	return math.max(1000, math.floor((player:GetAttribute("BaseIncome") or 0) * seconds))
end
GRANTS.Cash10m = function(player) Data.addCash(player, cashFor(player, 600)) end
GRANTS.Cash1h = function(player) Data.addCash(player, cashFor(player, 3600)) end
GRANTS.Cash4h = function(player) Data.addCash(player, cashFor(player, 14400)) end
GRANTS.LuckyBus = function(player)
	task.spawn(HallService.specialBus, "Lucky", player.DisplayName)
end
GRANTS.ServerLuck = function(player)
	local ev = require(script.Parent.EventService)
	ev.serverLuck(2, 900, player.DisplayName)
end
GRANTS.ExpressRare = function(player)
	require(script.Parent.LetterService).debugReady(player, "Rare")
end
GRANTS.ExpressEpic = function(player)
	require(script.Parent.LetterService).debugReady(player, "Epic")
end
GRANTS.LockRefresh = function(player)
	local plot = PlotService.getPlot(player)
	if plot then plot:SetAttribute("CooldownUntil", 0) end
end
-- open a part of town early (AreaService; kept in the buyer's own save)
for _, product in Config.Products do
	if product.area then
		GRANTS[product.key] = function(player)
			require(script.Parent.AreaService).open(player, product.area)
		end
	end
end

function MonetizationService.grantProduct(player, key)
	local product = productByKey[key]
	local fn = GRANTS[key]
	if not product or not fn then return false end
	fn(player)
	local p = Data.get(player)
	if p then p.stats.robux = (p.stats.robux or 0) + product.robux end
	Remotes.Notify:FireClient(player, "Thank you! " .. product.name .. " delivered.", "good")
	Remotes.Sfx:FireClient(player, "Buy")
	Signals.fire("product", player, key)
	return true
end

MarketplaceService.ProcessReceipt = function(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local p = player and Data.get(player)
	if not player or not p then return Enum.ProductPurchaseDecision.NotProcessedYet end
	-- a Board review resets cash, and an unsaved profile can't remember the receipt: try again later
	if p.reviewing or p.unsaved then return Enum.ProductPurchaseDecision.NotProcessedYet end
	p.receipts = p.receipts or {}
	if p.receipts[info.PurchaseId] then
		-- granted before but maybe not saved yet: only report success once it is
		return Data.save(Data.hostOf(player)) and Enum.ProductPurchaseDecision.PurchaseGranted or Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local product = productById[info.ProductId]
	if not product then
		warn("[Store] unknown product", info.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, err = pcall(MonetizationService.grantProduct, player, product.key)
	if not ok then
		warn("[Store] grant failed", product.key, err)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	p.receipts[info.PurchaseId] = os.time()
	-- saved before we tell Roblox it's done; if the save fails, Roblox retries and the receipt above
	-- keeps it from being granted twice (co-op: products go to the school being played, so the receipt
	-- lives in that school's save)
	if Data.save(Data.hostOf(player)) then return Enum.ProductPurchaseDecision.PurchaseGranted end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
	local pass = passById[id]
	if not purchased or not pass then return end
	local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
	if ok and owns then MonetizationService.grantPass(player, pass.key) end
end)

-- the client's Store panel: what's for sale and what you own
Actions.register("store", function(player)
	local passes, products = {}, {}
	for _, x in Config.Passes do
		table.insert(passes, { key = x.key, owned = MonetizationService.has(player, x.key), ready = x.id ~= 0 })
	end
	for _, x in Config.Products do
		table.insert(products, { key = x.key, ready = x.id ~= 0 })
	end
	return { ok = true, passes = passes, products = products }
end)

-- the client asks to buy; the prompt only ever opens because the player pressed a button
Actions.register("buy", function(player, p, kind, key)
	if kind == "pass" then
		local pass = passByKey[key]
		if not pass or pass.id == 0 then return { ok = false, err = "Coming soon!" } end
		if MonetizationService.has(player, key) then return { ok = false, err = "You already own it" } end
		MarketplaceService:PromptGamePassPurchase(player, pass.id)
		return { ok = true }
	elseif kind == "product" then
		local product = productByKey[key]
		if not product or product.id == 0 then return { ok = false, err = "Coming soon!" } end
		if key == "LockRefresh" then
			local plot = PlotService.getPlot(player)
			if not plot or (plot:GetAttribute("CooldownUntil") or 0) <= workspace:GetServerTimeNow() then
				return { ok = false, err = "Your gate can already lock!" }
			end
		end
		MarketplaceService:PromptProductPurchase(player, product.id)
		return { ok = true }
	end
	return { ok = false }
end)

-- the Home button: free for everyone every HOME_COOLDOWN seconds; the pass makes it instant
local HOME_COOLDOWN = 10
local lastHome = {}
Players.PlayerRemoving:Connect(function(player) lastHome[player] = nil end)
Actions.register("teleportHome", function(player)
	if (player:GetAttribute("Carrying") or player:GetAttribute("Heist")) then return { ok = false, err = "Not while carrying a kid!" } end
	local wait = MonetizationService.has(player, "TeleportHome") and 0 or HOME_COOLDOWN
	local left = (lastHome[player] or -math.huge) + wait - os.clock()
	if left > 0 then return { ok = false, err = ("Home again in %ds"):format(math.ceil(left)), cooldown = left } end
	local cf = PlotService.spawnCFrame(player)
	if not cf or not player.Character then return { ok = false } end
	player.Character:PivotTo(cf)
	lastHome[player] = os.clock()
	return { ok = true, cooldown = wait }
end)

function MonetizationService.start()
	-- VIP doubles tuition (a permanent multiplier, so offline pay includes it)
	-- (co-op: one VIP in the crew doubles the whole school)
	table.insert(PlotService.multHooks, function(player)
		for _, pl in Data.schoolPlayers(player) do
			if pl:GetAttribute("Pass_VIP") then return 2 end
		end
		return 1
	end)
	-- 2x Luck while standing near the buses
	table.insert(HallService.playerLuckHooks, function(player)
		return player:GetAttribute("Pass_Luck") and 2 or 1
	end)
	Players.PlayerAdded:Connect(function(player)
		-- profiles load asynchronously; wait for this player's
		for _ = 1, 60 do
			if Data.get(player) then break end
			task.wait(0.5)
		end
		if player.Parent then checkPasses(player) end
	end)
	for _, player in Players:GetPlayers() do task.spawn(checkPasses, player) end
end

return MonetizationService
