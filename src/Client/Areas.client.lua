-- StarterPlayer.StarterPlayerScripts.Areas
-- The locked parts of town, as this player sees them (AreaService, Config.Areas): a glowing barrier
-- across each locked gate, only in this client (so it stops only this player), with a sign saying
-- how to open it and UNLOCK NOW (the area's Robux shortcut). When an area opens (the Area_<id>
-- attribute), its barrier fades away and "<AREA> IS OPEN!" goes up.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local bus = ReplicatedStorage:WaitForChild("ClientBus", 10)

local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "AreaBarriers"
folder.Parent = workspace

local function toast(text, kind)
	if bus and bus:FindFirstChild("Toast") then bus.Toast:Fire(text, kind) end
end

local productOf = {}
for _, p in Config.Products do
	if p.area then productOf[p.area] = p end
end

local barriers = {} -- [area id] = model

local function makeBarrier(area)
	local g = area.gate
	local m = Instance.new("Model")
	m.Name = area.id
	-- a glowing field the height of the gate, and an invisible wall above it (no jumping over)
	local wall = Instance.new("Part")
	wall.Name = "Barrier"
	wall.Anchored = true
	wall.Size = g.alongX and Vector3.new(g.w, 16, 1) or Vector3.new(1, 16, g.w)
	wall.CFrame = CFrame.new(g.x, 8, g.z)
	wall.Material = Enum.Material.ForceField
	wall.Color = area.color
	wall.Transparency = 0.2
	wall.CanQuery = false
	wall.Parent = m
	local top = wall:Clone()
	top.Name = "BarrierTop"
	top.Size = g.alongX and Vector3.new(g.w, 40, 1) or Vector3.new(1, 40, g.w)
	top.CFrame = CFrame.new(g.x, 36, g.z)
	top.Transparency = 1
	top.Parent = m
	-- the sign: a board on a post in front of the gate, facing out of the area
	local b = area.box
	local cx, cz = (b.x0 + b.x1) / 2, (b.z0 + b.z1) / 2
	local out = g.alongX and Vector3.new(0, 0, (g.z > cz) and 1 or -1) or Vector3.new((g.x > cx) and 1 or -1, 0, 0)
	local at = Vector3.new(g.x, 0, g.z) + out * 5
	local board = Instance.new("Part")
	board.Name = "LockSign"
	board.Anchored = true
	board.Size = Vector3.new(12, 5, 0.4)
	board.CFrame = CFrame.lookAt(at + Vector3.new(0, 8.5, 0), at + Vector3.new(0, 8.5, 0) + out)
	board.Color = Color3.fromRGB(30, 26, 40)
	board.Material = Enum.Material.SmoothPlastic
	board.Parent = m
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = board
	local list = Instance.new("UIListLayout")
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Parent = gui
	local function line(text, h, color, font)
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, -20, h, 0)
		t.BackgroundTransparency = 1
		t.TextScaled = true
		t.Font = font or Enum.Font.LuckiestGuy
		t.Text = text
		t.TextColor3 = color
		t.Parent = gui
		return t
	end
	line("\u{1F512} " .. area.name:upper(), 0.42, Color3.new(1, 1, 1))
	line(area.hint .. " to open it", 0.28, Color3.fromRGB(255, 220, 140), Enum.Font.FredokaOne)
	line("or UNLOCK NOW", 0.22, Color3.fromRGB(120, 255, 140), Enum.Font.FredokaOne)
	for _, dx in { -5, 5 } do
		local post = Instance.new("Part")
		post.Anchored = true
		post.Size = Vector3.new(0.4, 6.5, 0.4)
		post.CFrame = board.CFrame * CFrame.new(dx, -5.5, 0.4)
		post.Color = Color3.fromRGB(44, 46, 54)
		post.Material = Enum.Material.Metal
		post.Parent = m
	end
	-- UNLOCK NOW: the Robux shortcut
	local product = productOf[area.id]
	if product then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "UnlockPrompt"
		prompt.ActionText = ("Unlock now (R$%d)"):format(product.robux)
		prompt.ObjectText = area.name
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Color", Color3.fromRGB(80, 220, 120))
		prompt.Parent = board
		prompt.Triggered:Connect(function()
			if product.id and product.id ~= 0 then
				MarketplaceService:PromptProductPurchase(player, product.id)
			else
				toast("Unlocking early is coming soon! " .. area.hint .. " to open it.", "info")
			end
		end)
	end
	m.Parent = folder
	return m
end

local function refresh(id)
	local area = Config.AreaById[id]
	if not area or not area.gate then return end
	local open = player:GetAttribute("Area_" .. id) == true
	if open and barriers[id] then
		local m = barriers[id]
		barriers[id] = nil
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.CanCollide = false
				TweenService:Create(d, TweenInfo.new(1.2), { Transparency = 1 }):Play()
			end
		end
		task.delay(1.3, function() m:Destroy() end)
	elseif not open and not barriers[id] then
		barriers[id] = makeBarrier(area)
	end
end

for _, area in Config.Areas do
	-- (wait for the server's first answer, so an open area never flashes a barrier)
	task.spawn(function()
		local t0 = os.clock()
		while not player:GetAttribute("AreasReady") and os.clock() - t0 < 30 do task.wait(0.25) end
		refresh(area.id)
		player:GetAttributeChangedSignal("Area_" .. area.id):Connect(function() refresh(area.id) end)
	end)
end

-- the executive elevator: a fade to black while the floors tick by
local fader
local function elevatorRide(dir)
	if not fader then
		local g = Instance.new("ScreenGui")
		g.Name = "ElevatorFade"
		g.IgnoreGuiInset = true
		g.DisplayOrder = 60
		g.ResetOnSpawn = false
		g.Parent = player:WaitForChild("PlayerGui")
		fader = Instance.new("Frame")
		fader.Size = UDim2.fromScale(1, 1)
		fader.BackgroundColor3 = Color3.new(0, 0, 0)
		fader.BackgroundTransparency = 1
		fader.Parent = g
		local t = Instance.new("TextLabel")
		t.Name = "Floor"
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.Position = UDim2.fromScale(0.5, 0.5)
		t.Size = UDim2.fromOffset(400, 80)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.Arcade
		t.TextScaled = true
		t.TextColor3 = Color3.fromRGB(255, 80, 80)
		t.TextTransparency = 1
		t.Parent = fader
	end
	local floor = fader.Floor
	TweenService:Create(fader, TweenInfo.new(0.5), { BackgroundTransparency = 0 }):Play()
	TweenService:Create(floor, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
	local seq = dir == "down" and { "L", "B1", "B2", "B3", "B13", "LAIR" } or { "LAIR", "B13", "B3", "B1", "L" }
	for _, f in seq do
		floor.Text = "\u{25BC} " .. f
		if dir ~= "down" then floor.Text = "\u{25B2} " .. f end
		task.wait(0.28)
	end
	if bus and bus:FindFirstChild("Sfx") then bus.Sfx:Fire("Ding") end
	TweenService:Create(fader, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(floor, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
end
Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
	if kind == "elevator" and type(data) == "table" then task.spawn(elevatorRide, data.dir) end
end)

-- an area just opened: the big announcement (the reveal cutscene hooks in here later)
Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
	if kind ~= "areaOpen" or type(data) ~= "table" then return end
	local area = Config.AreaById[data.id]
	if not area then return end
	local announce = Remotes:FindFirstChild("Announce")
	toast(("%s %s is open! Go explore."):format(area.icon, area.name:gsub("^%l", string.upper)), "good")
	if bus and bus:FindFirstChild("Sfx") then bus.Sfx:Fire("StingParty") end
	_ = announce
end)
