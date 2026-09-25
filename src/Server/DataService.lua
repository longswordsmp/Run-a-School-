-- ServerScriptService.Server.DataService
-- Player profiles: session-locked DataStore saves, schema versioning, offline tuition.
-- In Studio on an unpublished place (GameId 0) the DataStore is unavailable, so an in-memory
-- stand-in with the same API is used; save/load round trips still run through the same code.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}
local profiles = {}
local SCHEMA = 2
local LOCK_TIMEOUT = 30 * 60 -- a lock older than this belongs to a dead server
local OFFLINE_CAP = 2 * 3600
local OFFLINE_RATE = 0.25

---------------------------------------------------------------------------
-- store (real or stand-in)
---------------------------------------------------------------------------
local MockStore = {}
MockStore.__index = MockStore
function MockStore.new()
	return setmetatable({ data = {} }, MockStore)
end
function MockStore:GetAsync(key)
	local raw = self.data[key]
	return raw and HttpService:JSONDecode(raw) or nil
end
function MockStore:UpdateAsync(key, fn)
	local old = self:GetAsync(key)
	local new = fn(old)
	if new ~= nil then self.data[key] = HttpService:JSONEncode(new) end
	return new
end

local store
local usingMock = false
if RunService:IsStudio() and game.GameId == 0 then
	store = MockStore.new()
	usingMock = true
else
	local ok = pcall(function()
		store = DataStoreService:GetDataStore("RunASchool_v2")
	end)
	if not ok then
		store = MockStore.new()
		usingMock = true
	end
end
DataService.usingMock = usingMock

---------------------------------------------------------------------------
-- schema
---------------------------------------------------------------------------
local function default()
	return {
		v = SCHEMA,
		cash = Config.StartCash,
		tier = 1, -- index into Config.Tiers
		stars = 0, -- prestige ranks after the last tier
		rows = { 2, 0, 0 }, -- desk rows owned per floor
		students = {}, -- [slot] = { id, grade, stored }
		index = {}, -- ["id|grade"] = true
		upgrades = {}, -- [upgradeId] = level
		builds = {}, -- School Builder items owned: [itemId] = true
		supplies = {}, -- school supplies owned: [supplyId] = true
		teachers = {}, -- [floor] = { id, level }
		staffRoom = nil, -- current restock, see TeacherService
		gear = { owned = { Ruler = true } },
		quests = { chain = 1, progress = 0, daily = nil },
		stats = { enrolled = 0, stolen = 0, lost = 0, collected = 0, played = 0, reviews = 0 },
		login = { day = 0, streak = 0 },
		gifts = {},
		settings = { music = true, sfx = true },
		tutorial = 1,
		schoolName = nil,
		mascot = nil,
		lastOnline = os.time(),
		lastIncome = 0,
		receipts = {},
	}
end

-- bring an older save up to the current schema
local function migrate(p)
	if (p.v or 1) < 2 then
		-- v1 kept a flat desk count
		local desks = p.desks or 8
		p.rows = { math.clamp(math.ceil(desks / 4), 2, 4), 0, 0 }
		p.desks = nil
		p.tier = (p.rebirths or 0) + 1
		p.rebirths = nil
	end
	p.v = SCHEMA
	return p
end

local function fill(p)
	local d = default()
	for k, v in d do
		if p[k] == nil then p[k] = v end
	end
	for k, v in d.stats do
		if p.stats[k] == nil then p.stats[k] = v end
	end
	return p
end

-- JSON can't hold sparse integer keys, so slot maps are saved with string keys
local function toSave(p)
	local out = table.clone(p)
	out.students = {}
	for slot, e in p.students do
		out.students[tostring(slot)] = { id = e.id, grade = e.grade, stored = math.floor(e.stored or 0) }
	end
	out.teachers = {}
	for floor, t in p.teachers do
		out.teachers[tostring(floor)] = t
	end
	out.lock = nil
	out.reviewing = nil
	return out
end

local function fromSave(p)
	local students = {}
	for k, v in p.students or {} do
		local n = tonumber(k)
		if n then students[n] = v end
	end
	p.students = students
	local teachers = {}
	for k, v in p.teachers or {} do
		local n = tonumber(k)
		if n then teachers[n] = v end
	end
	p.teachers = teachers
	return p
end

---------------------------------------------------------------------------
-- load / save
---------------------------------------------------------------------------
local function key(player)
	return "p_" .. player.UserId
end

function DataService.load(player)
	local data
	for attempt = 1, 4 do
		local ok, res = pcall(function()
			return store:UpdateAsync(key(player), function(old)
				old = old or default()
				local lock = old.lock
				if lock and lock.job ~= game.JobId and os.time() - (lock.time or 0) < LOCK_TIMEOUT and attempt < 4 then
					return nil -- someone else holds it; retry
				end
				old.lock = { job = game.JobId, time = os.time() }
				return old
			end)
		end)
		if ok and res and res.lock and res.lock.job == game.JobId then
			data = res
			break
		end
		if not ok then warn("[Data] load attempt", attempt, "failed:", res) end
		task.wait(attempt * 2)
	end
	if not player.Parent then return nil end
	if not data then
		warn("[Data] could not lock profile for", player.Name, "- playing on a fresh, unsaved profile")
		data = default()
		data.unsaved = true
	end
	local p = fill(migrate(fromSave(data)))
	p.lock = nil
	p.reviewing = nil

	-- offline tuition, paid from the income they had when they left
	local away = math.max(0, os.time() - (p.lastOnline or os.time()))
	if away > 60 and (p.lastIncome or 0) > 0 then
		local cap = OFFLINE_CAP * (p.offlineCapMult or 1)
		local rate = OFFLINE_RATE * (p.offlineRateMult or 1)
		p.offlineEarned = math.floor(p.lastIncome * math.min(away, cap) * rate)
		p.offlineAway = away
		p.cash += p.offlineEarned
	end
	p.sessionStart = os.time()
	profiles[player] = p
	DataService.sync(player)
	return p
end

function DataService.get(player)
	return profiles[player]
end

function DataService.save(player, releasing)
	local p = profiles[player]
	if not p or p.unsaved then return end
	p.lastOnline = os.time()
	p.lastIncome = player:GetAttribute("BaseIncome") or player:GetAttribute("IncomePerSec") or 0
	local out = toSave(p)
	out.sessionStart, out.offlineEarned, out.offlineAway = nil, nil, nil
	local ok, err = pcall(function()
		store:UpdateAsync(key(player), function(old)
			if old and old.lock and old.lock.job ~= game.JobId then
				return nil -- another server took over this profile; never overwrite it
			end
			if not releasing then out.lock = { job = game.JobId, time = os.time() } end
			return out
		end)
	end)
	if not ok then warn("[Data] save failed for", player.Name, err) end
	return ok
end

function DataService.release(player)
	DataService.save(player, true)
	profiles[player] = nil
end

-- mirror what the HUD needs onto player attributes
function DataService.sync(player)
	local p = profiles[player]
	if not p then return end
	player:SetAttribute("Cash", p.cash)
	player:SetAttribute("Tier", p.tier)
	player:SetAttribute("Stars", p.stars)
	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Cash") then
		ls.Cash.Value = Config.formatCash(p.cash)
	end
end

function DataService.addCash(player, amount)
	local p = profiles[player]
	if not p then return false end
	if amount < 0 and p.cash < -amount then return false end
	p.cash += amount
	DataService.sync(player)
	return true
end

function DataService.all()
	return profiles
end

-- test hook: save, forget and reload a profile through the store (round-trip check)
function DataService.roundTrip(player)
	DataService.save(player, true)
	profiles[player] = nil
	return DataService.load(player)
end

task.spawn(function()
	while true do
		task.wait(60)
		for player in profiles do
			task.spawn(DataService.save, player)
		end
	end
end)

game:BindToClose(function()
	local threads = {}
	for player in profiles do
		table.insert(threads, task.spawn(DataService.save, player, true))
	end
	task.wait(3)
end)

return DataService
