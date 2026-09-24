-- ServerScriptService.Server.Main
local Players = game:GetService("Players")

local Server = script.Parent
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

Remotes.Action.OnServerInvoke = function(player, action, ...)
	return nil
end
