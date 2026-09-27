-- ServerScriptService.Server.MonetizationService
-- Game passes and developer products (Config.Passes / Config.Products).
--   Passes: ownership is checked on join and after an in-game purchase; each one sets a player
--     attribute "Pass_<key>" that the systems it affects read.
--   Products: MarketplaceService.ProcessReceipt grants them once per receipt (receipt ids are kept in
--     the saved profile so a retried receipt is never granted twice).
-- Nothing here ever opens a purchase prompt by itself; the client's Store panel asks via "buy".
-- The MONEY BOOST (Config.MoneyBoost): one button; every purchase doubles all your tuition, x2 up to
-- x1024, forever (kept in the buyer's own save, attribute MoneyBoost). Each doubling is a product.
-- In Studio, anything without an id yet is a free test purchase; live, it stays out of the store.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local STUDIO = RunService:IsStudio()

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

local function applyPass(player, bought)
	-- (a pass is the buyer's, kept in their own save even while they play for a friend's school)
	local p = Data.own(player)
	if p then
		p.passes = p.passes or {}
		p.passes[bought] = true
	end
	-- (a deal pass counts as the pass it's a cheaper copy of: its effects are that one's)
	local key = passByKey[bought] and passByKey[bought].same or bought
	player:SetAttribute("Pass_" .. key, true)
	if key == "OfflinePlus" and p then
		p.offlineCapMult = 6 -- 12 h
		p.offlineRateMult = 2 -- 50 %
	end
	if key == "VIP" or key == "LongLock" then PlotService.updateIncome(player) end
	-- the Starter Pack pays out once per save
	if key == "StarterPack" and p and not p.starterPackGiven then
		p.starterPackGiven = true
		Data.addCash(player, 25000)
		local pool = {}
		for _, s in Config.Students do
			if s.rarity == "Rare" then table.insert(pool, s) end
		end
		local host = Data.hostOf(player)
		local LetterService = require(script.Parent.LetterService)
		if not LetterService.deliver(host, pool[math.random(#pool)], true) then
			local hp = Data.get(player)
			if hp then
				hp.pendingBench = hp.pendingBench or {}
				table.insert(hp.pendingBench, pool[math.random(#pool)].id)
			end
		end
		local GearService = require(script.Parent.GearService)
		for _, g in Config.Gear do
			if g.kind == "use" then GearService.give(player, g.id, 3) end
		end
	end
	-- the Golden Hoverboard comes with a hoverboard, whether or not you've won Grindle's yet
	if key == "GoldenBoard" or key == "DiamondBoard" then
		task.defer(function()
			local GearService = require(script.Parent.GearService)
			if GearService.has and not GearService.has(player, "Hoverboard") then GearService.give(player, "Hoverboard") end
		end)
	end
	if key == "SuperSpeed" or key == "GoldenBoard" or key == "DiamondBoard" then
		task.defer(function() require(script.Parent.StealService).setSpeed(player) end)
	end
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
GRANTS.Cash8h = function(player) Data.addCash(player, cashFor(player, 28800)) end
GRANTS.Cash16h = function(player) Data.addCash(player, cashFor(player, 57600)) end
GRANTS.Cash24h = function(player) Data.addCash(player, cashFor(player, 86400)) end
GRANTS.Cash1w = function(player) Data.addCash(player, cashFor(player, 604800)) end
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
-- the MONEY BOOST: double it, up to the max, in the buyer's own save
local function boostUp(player)
	local own = Data.own(player)
	if not own then return end
	own.moneyBoost = math.min(Config.MoneyBoost.max, 2 ^ (Config.boostSteps(own.moneyBoost or 1) + 1))
	player:SetAttribute("MoneyBoost", own.moneyBoost)
	PlotService.updateIncome(Data.hostOf(player))
	Remotes.Announce:FireClient(player, ("\u{1F4B0} MONEY BOOST x%d!"):format(own.moneyBoost), Color3.fromRGB(255, 205, 60))
	Remotes.Sfx:FireClient(player, "StingParty")
end
for _, x in Config.Products do
	if x.boost then GRANTS[x.key] = boostUp end
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
	local product = productById[info.ProductId]
	if not product then
		warn("[Store] unknown product", info.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- (the Money Boost and area unlocks go to the buyer's OWN save, even while helping a friend's
	-- school: the receipt goes in the same save as the thing bought, and that's the save we wait for)
	local ownSave = product.boost or product.area
	local rp = ownSave and Data.own(player) or p
	local saver = ownSave and player or Data.hostOf(player)
	if not rp then return Enum.ProductPurchaseDecision.NotProcessedYet end
	rp.receipts = rp.receipts or {}
	if rp.receipts[info.PurchaseId] then
		-- granted before but maybe not saved yet: only report success once it is
		return Data.save(saver) and Enum.ProductPurchaseDecision.PurchaseGranted or Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, err = pcall(MonetizationService.grantProduct, player, product.key)
	if not ok then
		warn("[Store] grant failed", product.key, err)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	rp.receipts[info.PurchaseId] = os.time()
	-- saved before we tell Roblox it's done; if the save fails, Roblox retries and the receipt above
	-- keeps it from being granted twice (co-op: school products go to the school being played, so their
	-- receipt lives in that school's save; your own things, in yours)
	if Data.save(saver) then return Enum.ProductPurchaseDecision.PurchaseGranted end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
	local pass = passById[id]
	if not purchased or not pass then return end
	local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
	if ok and owns then MonetizationService.grantPass(player, pass.key) end
end)

-- (an item is on sale once it has an id; in Studio everything is, as a free test purchase)
local function ready(x) return x.id ~= 0 or STUDIO end

-- the client's Store panel: what's for sale and what you own
Actions.register("store", function(player)
	local passes, products = {}, {}
	for _, x in Config.Passes do
		table.insert(passes, { key = x.key, owned = MonetizationService.has(player, x.key), ready = ready(x) })
	end
	for _, x in Config.Products do
		table.insert(products, { key = x.key, ready = ready(x) })
	end
	local own = Data.own(player)
	local level = own and own.moneyBoost or 1
	local nextProduct, nextLevel = Config.boostProductFor(level)
	return { ok = true, passes = passes, products = products,
		boost = { level = level, max = Config.MoneyBoost.max, nextLevel = nextLevel, robux = nextProduct and nextProduct.robux, ready = nextProduct ~= nil and ready(nextProduct),
			done = Config.boostSteps(level), steps = Config.MoneyBoost.steps } }
end)

-- the client asks to buy; the prompt only ever opens because the player pressed a button
Actions.register("buy", function(player, p, kind, key)
	if kind == "boost" then
		local own = Data.own(player)
		local product = Config.boostProductFor(own and own.moneyBoost or 1)
		if not product then return { ok = false, err = "You're at the max: x" .. Config.MoneyBoost.max .. "!" } end
		if product.id == 0 then
			if not STUDIO then return { ok = false, err = "Not on sale yet" } end
			MonetizationService.grantProduct(player, product.key)
			Remotes.Notify:FireClient(player, "(Studio test purchase: free)", "info")
			return { ok = true }
		end
		MarketplaceService:PromptProductPurchase(player, product.id)
		return { ok = true }
	elseif kind == "pass" then
		local pass = passByKey[key]
		if not pass or not ready(pass) then return { ok = false, err = "Not on sale yet" } end
		if MonetizationService.has(player, pass.same or key) then return { ok = false, err = "You already own it" } end
		if pass.id == 0 then
			MonetizationService.grantPass(player, key)
			Remotes.Notify:FireClient(player, "(Studio test purchase: free)", "info")
			return { ok = true }
		end
		MarketplaceService:PromptGamePassPurchase(player, pass.id)
		return { ok = true }
	elseif kind == "product" then
		local product = productByKey[key]
		if not product or not ready(product) then return { ok = false, err = "Not on sale yet" } end
		if key == "LockRefresh" then
			local plot = PlotService.getPlot(player)
			if not plot or (plot:GetAttribute("CooldownUntil") or 0) <= workspace:GetServerTimeNow() then
				return { ok = false, err = "Your gate can already lock!" }
			end
		end
		if product.id == 0 then
			MonetizationService.grantProduct(player, key)
			Remotes.Notify:FireClient(player, "(Studio test purchase: free)", "info")
			return { ok = true }
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
	-- the MONEY BOOST: the best one in the crew counts for the whole school (like VIP)
	table.insert(PlotService.multHooks, function(player)
		local best = 1
		for _, pl in Data.schoolPlayers(player) do
			best = math.max(best, pl:GetAttribute("MoneyBoost") or 1)
		end
		return best
	end)
	-- 2x Luck while standing near the buses
	table.insert(HallService.playerLuckHooks, function(player)
		return player:GetAttribute("Pass_Luck") and 2 or 1
	end)
	local function joined(player)
		-- profiles load asynchronously; wait for this player's
		for _ = 1, 60 do
			if Data.get(player) then break end
			task.wait(0.5)
		end
		if not player.Parent then return end
		local own = Data.own(player)
		player:SetAttribute("MoneyBoost", own and own.moneyBoost or 1)
		PlotService.updateIncome(Data.hostOf(player))
		checkPasses(player)
	end
	Players.PlayerAdded:Connect(joined)
	for _, player in Players:GetPlayers() do task.spawn(joined, player) end
end

return MonetizationService
