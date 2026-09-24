-- ServerScriptService.Server.Main
local Players = game:GetService("Players")

local Server = script.Parent
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Remotes = require(Server.Remotes)
local Data = require(Server.DataService)
local Factory = require(Server.StudentFactory)
local PlotService = require(Server.PlotService)
local HallService = require(Server.HallService)

Factory.preload()
PlotService.start()
HallService.start()

local function onPlayer(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = ls
	ls.Parent = player

	Data.load(player)
	PlotService.assign(player)

	local function onChar(char)
		local cf = PlotService.spawnCFrame(player)
		if cf then
			task.defer(function()
				char:PivotTo(cf)
			end)
		end
	end
	player.CharacterAdded:Connect(onChar)
	if player.Character then onChar(player.Character) end
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end

Players.PlayerRemoving:Connect(function(player)
	PlotService.release(player)
	Data.release(player)
end)

local SchoolService = require(Server.SchoolService)
Remotes.Action.OnServerInvoke = function(player, action, ...)
	return SchoolService.handle(player, action, ...)
end

-- Studio-only test commands (see DebugBridge)
local Walkers = require(Server.Walkers)
require(Server.DebugBridge).start({
	state = function(player)
		local p = Data.get(player)
		local students = {}
		for slot, e in p.students do
			students[tostring(slot)] = { id = e.id, grade = e.grade, stored = math.floor(e.stored or 0), arriving = e.arriving }
		end
		return { cash = p.cash, income = player:GetAttribute("IncomePerSec"), plot = player:GetAttribute("Plot"), students = students }
	end,
	cash = function(player, amount)
		local p = Data.get(player)
		p.cash = amount
		Data.sync(player)
		return p.cash
	end,
	-- spawn a student of a rarity, parked in front of the player, facing them
	spawnNear = function(player, rarity, studentId)
		local model = HallService.spawnOne(rarity, studentId)
		Walkers.stop(model)
		local root = player.Character.HumanoidRootPart
		local pos = root.Position + root.CFrame.LookVector * 5
		local y = model.PrimaryPart.Position.Y
		model.PrimaryPart.CFrame = CFrame.lookAt(Vector3.new(pos.X, y, pos.Z), Vector3.new(root.Position.X, y, root.Position.Z))
		Factory.play(model, "idle")
		return model.Name
	end,
	-- every student of a rarity standing in a row along +X from (x, z), facing -Z
	lineup = function(player, rarity, x, z, spacing)
		local n = 0
		for _, def in Config.Students do
			if def.rarity == rarity then
				local model = HallService.spawnOne(nil, def.id)
				Walkers.stop(model)
				model:SetAttribute("State", "Lineup")
				local y = model.PrimaryPart.Position.Y
				local at = Vector3.new(x + n * (spacing or 6), y, z)
				model.PrimaryPart.CFrame = CFrame.lookAt(at, at - Vector3.zAxis)
				Factory.play(model, "idle")
				n += 1
			end
		end
		return n
	end,
	clearHall = function()
		for _, m in workspace.Hall:GetChildren() do m:Destroy() end
		return true
	end,
	tp = function(player, x, y, z, lookX, lookZ)
		local at = Vector3.new(x, y, z)
		player.Character:PivotTo(CFrame.lookAt(at, Vector3.new(lookX or x, y, lookZ or z - 1)))
		return true
	end,
})
