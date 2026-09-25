-- ServerScriptService.Server.EventService
-- Server-wide events and the admin panel's commands.
--   Events (10 minutes, one starts on its own every 30 minutes, or an admin starts one):
--     SnowDay, ScienceFair, PictureDay, Halloween, SpaceCamp - each unlocks its event grade on
--     the bus (Config.Grades[].event) and has its own look and music on the client
--     (workspace attributes Event / EventUntil).
--   Admin commands: buses, events, spawning rare kids, Money Rain, server luck, recess.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local HallService = require(script.Parent.HallService)
local Remotes = require(script.Parent.Remotes)
local Actions = require(script.Parent.Actions)
local Signals = require(script.Parent.Signals)

local EventService = {}

EventService.Events = {
	SnowDay = { name = "SNOW DAY", grade = "Snow Day", weight = 6, color = Color3.fromRGB(170, 220, 255), music = "snow" },
	ScienceFair = { name = "SCIENCE FAIR", grade = "Radioactive", weight = 4, color = Color3.fromRGB(90, 255, 90) },
	PictureDay = { name = "PICTURE DAY", grade = "Picture Perfect", weight = 10, color = Color3.fromRGB(255, 255, 255) },
	Halloween = { name = "HALLOWEEN", grade = "Spooky", weight = 5, color = Color3.fromRGB(255, 130, 20), music = "halloween" },
	SpaceCamp = { name = "SPACE CAMP", grade = "Cosmic", weight = 1.5, color = Color3.fromRGB(140, 90, 255) },
}
local ORDER = { "SnowDay", "ScienceFair", "PictureDay", "Halloween", "SpaceCamp" }
local EVENT_LEN = 600
local EVENT_EVERY = 1800

-- admins: the place owner, listed ids, and anyone testing in Studio
local ADMINS = { [1331076401] = true }
function EventService.isAdmin(player)
	if ADMINS[player.UserId] or RunService:IsStudio() then return true end
	if game.CreatorType == Enum.CreatorType.User then return player.UserId == game.CreatorId end
	local ok, rank = pcall(function() return player:GetRankInGroup(game.CreatorId) end)
	return ok and rank >= 255
end

local serverLuck = { mult = 1, untilT = 0 }

function EventService.start(id)
	local ev = EventService.Events[id]
	if not ev then return false end
	local now = workspace:GetServerTimeNow()
	workspace:SetAttribute("Event", id)
	workspace:SetAttribute("EventUntil", now + EVENT_LEN)
	table.clear(HallService.eventGrades)
	HallService.eventGrades[ev.grade] = ev.weight
	Remotes.Announce:FireAllClients(ev.name .. "! " .. ev.grade:upper() .. " KIDS ON THE BUS", ev.color)
	Remotes.Sfx:FireAllClients("StingWild")
	Signals.fire("eventStart", id)
	return true
end

function EventService.stop()
	if not workspace:GetAttribute("Event") then return end
	workspace:SetAttribute("Event", nil)
	workspace:SetAttribute("EventUntil", nil)
	table.clear(HallService.eventGrades)
	Remotes.Notify:FireAllClients("The event is over. See you next time!", "info")
end

-- Money Rain: bills float down over the street; touching one pays 15 seconds of your tuition
local TweenService = game:GetService("TweenService")
function EventService.moneyRain(count)
	local map = workspace:FindFirstChild("Map")
	local path = map and map:FindFirstChild("HallPath")
	local x0, x1 = -300, 320
	if path then x0, x1 = path.Start.Position.X, path.End.Position.X end
	Remotes.Announce:FireAllClients("MONEY RAIN!", Color3.fromRGB(110, 255, 120))
	Remotes.Sfx:FireAllClients("Buy")
	local folder = workspace:FindFirstChild("MoneyRain") or Instance.new("Folder")
	folder.Name = "MoneyRain"
	folder.Parent = workspace
	for _ = 1, count or 60 do
		local bill = Instance.new("Part")
		bill.Name = "Bill"
		bill.Size = Vector3.new(2.6, 0.12, 1.3)
		bill.Color = Color3.fromRGB(80, 190, 95)
		bill.Material = Enum.Material.SmoothPlastic
		bill.CanCollide = false
		bill.Anchored = true
		local ground = Vector3.new(x0 + math.random() * (x1 - x0), 1.2, (math.random() - 0.5) * 40)
		bill.CFrame = CFrame.new(ground + Vector3.new(0, 45 + math.random() * 25, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		local stripe = Instance.new("Part")
		stripe.Name = "Stripe"
		stripe.Size = Vector3.new(1, 0.14, 0.9)
		stripe.Color = Color3.fromRGB(190, 240, 190)
		stripe.Material = Enum.Material.SmoothPlastic
		stripe.CanCollide, stripe.CanQuery, stripe.CanTouch = false, false, false
		stripe.Anchored = true
		stripe.CFrame = bill.CFrame
		stripe.Parent = bill
		local claimed = false
		bill.Touched:Connect(function(hit)
			if claimed then return end
			local char = hit:FindFirstAncestorOfClass("Model")
			local player = char and Players:GetPlayerFromCharacter(char)
			if not player then return end
			local root = char:FindFirstChild("HumanoidRootPart")
			if not root or (root.Position - bill.Position).Magnitude > 12 then return end
			claimed = true
			local amount = math.max(50, math.floor((player:GetAttribute("BaseIncome") or 0) * 15))
			Data.addCash(player, amount)
			Remotes.CashPop:FireClient(player, amount, bill.Position)
			Remotes.Sfx:FireClient(player, "Coin")
			bill:Destroy()
		end)
		bill.Parent = folder
		-- flutter down
		local t = 4 + math.random() * 3
		local target = CFrame.new(ground) * CFrame.Angles(0, math.random() * 6, 0)
		TweenService:Create(bill, TweenInfo.new(t, Enum.EasingStyle.Sine), { CFrame = target }):Play()
		TweenService:Create(stripe, TweenInfo.new(t, Enum.EasingStyle.Sine), { CFrame = target * CFrame.new(0, 0.01, 0) }):Play()
		game:GetService("Debris"):AddItem(bill, 45)
		task.wait(0.05)
	end
end

---------------------------------------------------------------------------
-- admin panel commands
---------------------------------------------------------------------------
local ADMIN = {}
ADMIN.bus = function(player, kind)
	if kind ~= "LateBus" and kind ~= "HonorBus" and kind ~= "FieldTrip" and kind ~= "Lucky" and kind ~= "Welcome" then return false end
	task.spawn(HallService.specialBus, kind, player.DisplayName)
	return true
end
ADMIN.event = function(player, id)
	if id == "stop" then EventService.stop() return true end
	return EventService.start(id)
end
ADMIN.spawn = function(player, rarity)
	if not Config.RarityById[rarity] then return false end
	for _ = 1, 3 do
		HallService.spawnOne(rarity)
		task.wait(0.4)
	end
	Remotes.Notify:FireAllClients(player.DisplayName .. " spawned " .. rarity .. " kids!", "steal")
	return true
end
ADMIN.money = function(player)
	task.spawn(EventService.moneyRain, 80)
	return true
end
-- server-wide luck for a while (admin panel, the Server Luck product); more time stacks on
function EventService.serverLuck(mult, secs, byName)
	local now = workspace:GetServerTimeNow()
	serverLuck.mult = math.max(serverLuck.untilT > now and serverLuck.mult or 1, mult)
	serverLuck.untilT = math.max(serverLuck.untilT, now) + secs
	workspace:SetAttribute("ServerLuck", serverLuck.mult)
	workspace:SetAttribute("ServerLuckUntil", serverLuck.untilT)
	local who = byName and (byName .. " bought ") or ""
	Remotes.Announce:FireAllClients(("%sSERVER LUCK x%d FOR %d MINUTES!"):format(who:upper(), mult, math.floor(secs / 60)), Color3.fromRGB(110, 255, 160))
	Remotes.Sfx:FireAllClients("Upgrade")
end

ADMIN.luck = function(player, mult)
	mult = math.clamp(tonumber(mult) or 2, 1, 5)
	EventService.serverLuck(mult, 300)
	return true
end
ADMIN.recess = function(player)
	workspace:SetAttribute("RecessAt", workspace:GetServerTimeNow())
	return true
end
ADMIN.cash = function(player, amount)
	local p = Data.get(player)
	if not p then return false end
	local n = tonumber(amount) or 0
	if n ~= n then n = 0 end
	Data.addCash(player, math.clamp(n, 0, 1e15))
	return true
end

Actions.register("admin", function(player, p, cmd, arg)
	if not EventService.isAdmin(player) then return { ok = false, err = "Admins only" } end
	local fn = ADMIN[cmd]
	if not fn then return { ok = false, err = "Unknown command" } end
	return { ok = fn(player, arg) == true }
end)

function EventService.startLoop()
	-- server luck from the admin panel
	table.insert(HallService.luckHooks, function()
		if workspace:GetServerTimeNow() < serverLuck.untilT then return serverLuck.mult end
		return 1
	end)
	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("Admin", EventService.isAdmin(player))
	end)
	for _, player in Players:GetPlayers() do
		player:SetAttribute("Admin", EventService.isAdmin(player))
	end
	workspace:SetAttribute("NextEventAt", workspace:GetServerTimeNow() + EVENT_EVERY)
	task.spawn(function()
		local i = math.random(#ORDER)
		while true do
			task.wait(1)
			local now = workspace:GetServerTimeNow()
			local untilT = workspace:GetAttribute("EventUntil")
			if untilT and now >= untilT then EventService.stop() end
			if now >= (workspace:GetAttribute("NextEventAt") or math.huge) then
				workspace:SetAttribute("NextEventAt", now + EVENT_EVERY)
				if not workspace:GetAttribute("Event") then
					i = i % #ORDER + 1
					EventService.start(ORDER[i])
				end
			end
			if workspace:GetAttribute("ServerLuckUntil") and now >= workspace:GetAttribute("ServerLuckUntil") then
				workspace:SetAttribute("ServerLuck", nil)
				workspace:SetAttribute("ServerLuckUntil", nil)
			end
		end
	end)
end

return EventService
