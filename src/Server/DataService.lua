-- ServerScriptService.Server.DataService
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}
local profiles = {}
local store
pcall(function()
	store = DataStoreService:GetDataStore("RunASchool_v1")
end)

local function default()
	return {
		cash = Config.StartCash,
		rebirths = 0,
		desks = Config.BaseDesks,
		schoolName = nil,
		students = {}, -- [slot] = { id, grade, stored }
		index = {}, -- ["id|grade"] = true
		lastOnline = os.time(),
	}
end

function DataService.load(player)
	local data
	if store then
		local ok, res = pcall(function()
			return store:GetAsync("p_" .. player.UserId)
		end)
		if ok then data = res else warn("[Data] load failed:", res) end
	end
	local p = default()
	if type(data) == "table" then
		for k, v in data do p[k] = v end
	end
	-- slots are saved with string keys
	local students = {}
	for k, v in p.students do
		local n = tonumber(k)
		if n then students[n] = v end
	end
	p.students = students
	profiles[player] = p
	DataService.sync(player)
	return p
end

function DataService.get(player)
	return profiles[player]
end

function DataService.save(player)
	local p = profiles[player]
	if not p or not store then return end
	local out = table.clone(p)
	out.lastOnline = os.time()
	out.students = {}
	for slot, e in p.students do
		out.students[tostring(slot)] = { id = e.id, grade = e.grade, stored = math.floor(e.stored or 0) }
	end
	local ok, err = pcall(function()
		store:SetAsync("p_" .. player.UserId, out)
	end)
	if not ok then warn("[Data] save failed:", err) end
end

function DataService.release(player)
	DataService.save(player)
	profiles[player] = nil
end

-- mirror what the HUD needs onto player attributes
function DataService.sync(player)
	local p = profiles[player]
	if not p then return end
	player:SetAttribute("Cash", p.cash)
	player:SetAttribute("Rebirths", p.rebirths)
	player:SetAttribute("Desks", p.desks)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
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

task.spawn(function()
	while true do
		task.wait(90)
		for player in profiles do
			task.spawn(DataService.save, player)
		end
	end
end)

game:BindToClose(function()
	for player in profiles do
		DataService.save(player)
	end
end)

return DataService
