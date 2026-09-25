-- ServerScriptService.Server.LeaderboardService
-- Two boards in front of the District Office:
--   RICHEST SCHOOLS RIGHT NOW  - everyone in this server by tuition per second (every 5 s)
--   HALL OF FAME               - the best tuition ever reached, across all servers (OrderedDataStore;
--                                unavailable in Studio on an unpublished place, where it says so)
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)

local LeaderboardService = {}

local ordered
pcall(function()
	if game.GameId ~= 0 then ordered = DataStoreService:GetOrderedDataStore("BestTuition_v1") end
end)

local function board(parent, name, cf, title, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(18, 14, 0.8)
	p.CFrame = cf
	p.Anchored = true
	p.Color = Color3.fromRGB(24, 26, 38)
	p.Parent = parent
	for _, x in { -7.5, 7.5 } do
		local post = Instance.new("Part")
		post.Size = Vector3.new(0.8, cf.Position.Y, 0.8)
		post.CFrame = cf * CFrame.new(x, -cf.Position.Y / 2, 0)
		post.Anchored = true
		post.Color = Color3.fromRGB(60, 60, 70)
		post.Material = Enum.Material.Metal
		post.Parent = parent
	end
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 30
	g.LightInfluence = 0
	g.Parent = p
	local head = Instance.new("TextLabel")
	head.Size = UDim2.new(1, 0, 0.14, 0)
	head.BackgroundColor3 = color
	head.Font = Enum.Font.LuckiestGuy
	head.TextScaled = true
	head.TextColor3 = Color3.new(1, 1, 1)
	head.Text = title
	head.Parent = g
	local list = Instance.new("Frame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromScale(0.03, 0.17)
	list.Size = UDim2.fromScale(0.94, 0.8)
	list.Parent = g
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.01, 0)
	layout.Parent = list
	local rows = {}
	for i = 1, 8 do
		local r = Instance.new("TextLabel")
		r.LayoutOrder = i
		r.Size = UDim2.new(1, 0, 0.115, 0)
		r.BackgroundTransparency = 1
		r.Font = Enum.Font.FredokaOne
		r.TextScaled = true
		r.TextXAlignment = Enum.TextXAlignment.Left
		r.TextColor3 = i == 1 and Color3.fromRGB(255, 215, 90) or i == 2 and Color3.fromRGB(220, 225, 235) or i == 3 and Color3.fromRGB(230, 160, 100) or Color3.new(1, 1, 1)
		r.Text = ""
		r.Parent = list
		rows[i] = r
	end
	return rows
end

function LeaderboardService.start()
	local lm = workspace:WaitForChild("Map"):FindFirstChild("Landmarks")
	local office = lm and lm:FindFirstChild("DistrictOffice")
	if not office then return end
	local folder = Instance.new("Folder")
	folder.Name = "Leaderboards"
	folder.Parent = office
	-- in front of the tower, facing the street (+Z)
	local faceStreet = CFrame.Angles(0, math.pi, 0)
	local nowRows = board(folder, "RichestNow", CFrame.new(175, 9, -58) * faceStreet, "RICHEST SCHOOLS RIGHT NOW", Color3.fromRGB(40, 150, 90))
	local fameRows = board(folder, "HallOfFame", CFrame.new(205, 9, -58) * faceStreet, "HALL OF FAME (ALL SERVERS)", Color3.fromRGB(150, 90, 30))

	local lastPublish = {}
	task.spawn(function()
		local tick = 0
		while true do
			-- this server
			local list = {}
			for player, p in Data.all() do
				table.insert(list, { name = PlotService.schoolName(player), who = player.DisplayName, inc = player:GetAttribute("BaseIncome") or 0, tier = PlotService.tierOf(p).name })
				-- remember each player's best
				local best = math.floor(player:GetAttribute("BaseIncome") or 0)
				if best > (p.bestIncome or 0) then p.bestIncome = best end
			end
			table.sort(list, function(a, b) return a.inc > b.inc end)
			for i, r in nowRows do
				local e = list[i]
				r.Text = e and ("%d. %s  %s/s  (%s)"):format(i, e.name, Config.formatCash(e.inc), e.who) or ""
			end
			-- all servers: publish each best every 2 minutes, read the top every minute
			tick += 1
			if ordered then
				for player, p in Data.all() do
					if (p.bestIncome or 0) > 0 and (not lastPublish[player] or os.clock() - lastPublish[player] > 120) then
						lastPublish[player] = os.clock()
						task.spawn(pcall, function() ordered:SetAsync(tostring(player.UserId), p.bestIncome) end)
					end
				end
				if tick % 12 == 1 then
					task.spawn(function()
						local ok, pages = pcall(function() return ordered:GetSortedAsync(false, 8) end)
						if not ok then return end
						local top = pages:GetCurrentPage()
						for i, r in fameRows do
							local e = top[i]
							if e then
								local okName, name = pcall(Players.GetNameFromUserIdAsync, Players, tonumber(e.key))
								r.Text = ("%d. %s  %s/s"):format(i, okName and name or ("#" .. e.key), Config.formatCash(e.value))
							else
								r.Text = ""
							end
						end
					end)
				end
			else
				fameRows[1].Text = "Opens when the game is published"
			end
			task.wait(5)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastPublish[player] = nil
	end)
end

return LeaderboardService
