-- StarterPlayer.StarterPlayerScripts.Celebrate
-- Money raining down when you buy a Money Boost or a tuition pack (tomas, 2026-09-27: "effects like
-- falling money models for the money boost"): bills and gold coins fluttering down over the screen,
-- and 3D bills and coins tumbling out of the sky round your character, landing and fading away.
-- Push "celebrate" { kind = "money", big = a Money Boost } from MonetizationService.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local GREEN, GREEN_L, GREEN_D = Color3.fromRGB(95, 195, 100), Color3.fromRGB(165, 235, 150), Color3.fromRGB(40, 120, 55)
local GOLD, GOLD_L, GOLD_D = Color3.fromRGB(255, 200, 50), Color3.fromRGB(255, 230, 120), Color3.fromRGB(190, 130, 20)

---------------------------------------------------------------------------
-- the screen
---------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "Celebrate"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 60
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = r
	c.Parent = o
end
local function stroke(o, t, col)
	local s = Instance.new("UIStroke")
	s.Thickness = t
	s.Color = col
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = o
end

-- a bill: green, a lighter panel in it, a $ in the middle
local function bill()
	local f = Instance.new("Frame")
	f.Name = "Bill"
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = GREEN
	f.BorderSizePixel = 0
	corner(f, UDim.new(0, 5))
	stroke(f, 2, GREEN_D)
	local inner = Instance.new("Frame")
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.new(1, -12, 1, -10)
	inner.BackgroundColor3 = GREEN_L
	inner.BorderSizePixel = 0
	corner(inner, UDim.new(0, 4))
	inner.Parent = f
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5, 0.5)
	t.Size = UDim2.fromScale(0.7, 1.1)
	t.Font = Enum.Font.LuckiestGuy
	t.TextScaled = true
	t.Text = "$"
	t.TextColor3 = GREEN_D
	t.TextStrokeTransparency = 0.4
	t.TextStrokeColor3 = Color3.new(1, 1, 1)
	t.Parent = f
	return f, Vector2.new(84, 42)
end
-- a coin: gold, a lighter face, a $ on it
local function coin()
	local f = Instance.new("Frame")
	f.Name = "Coin"
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = GOLD
	f.BorderSizePixel = 0
	corner(f, UDim.new(1, 0))
	stroke(f, 2, GOLD_D)
	local inner = Instance.new("Frame")
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.fromScale(0.7, 0.7)
	inner.BackgroundColor3 = GOLD_L
	inner.BorderSizePixel = 0
	corner(inner, UDim.new(1, 0))
	inner.Parent = f
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.LuckiestGuy
	t.TextScaled = true
	t.Text = "$"
	t.TextColor3 = GOLD_D
	t.Parent = inner
	return f, Vector2.new(36, 36)
end

local flutter = {} -- screen pieces falling
local function rainScreen(n)
	local vs = gui.AbsoluteSize
	for i = 1, n do
		task.delay((i / n) * 1.3, function()
			local f, size
			if math.random() < 0.25 then f, size = coin() else f, size = bill() end
			local scale = 0.8 + math.random() * 0.6
			f.Size = UDim2.fromOffset(size.X * scale, size.Y * scale)
			f.ZIndex = 5
			f.Parent = gui
			table.insert(flutter, {
				obj = f, base = f.Size, x0 = math.random() * vs.X, y = -40 - math.random() * 60,
				vy = 360 + math.random() * 280, sway = 18 + math.random() * 40, freq = 1.6 + math.random() * 2,
				spin = (math.random() - 0.5) * 240, rot = math.random() * 360, flip = 3 + math.random() * 4,
				phase = math.random() * 6, t = 0, h = vs.Y,
			})
		end)
	end
end

---------------------------------------------------------------------------
-- the world: bills and coins tumbling down round the character (client-side parts, anchored, moved
-- here: a flutter, not physics), landing flat on whatever's under them and fading away
---------------------------------------------------------------------------
local folder = Instance.new("Folder")
folder.Name = "MoneyRain"
folder.Parent = workspace
local drops = {}

local function piece(isCoin)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if isCoin then
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(0.18, 1.1, 1.1)
		p.Color = GOLD
		p.Material = Enum.Material.Metal
	else
		p.Size = Vector3.new(2.2, 0.06, 1.1)
		p.Color = GREEN
		p.Material = Enum.Material.SmoothPlastic
	end
	p.Parent = folder
	-- (the bill's lighter panel rides on it)
	local top
	if not isCoin then
		top = p:Clone()
		top.Size = Vector3.new(1.6, 0.07, 0.6)
		top.Color = GREEN_L
		top.Parent = folder
	end
	return p, top
end

local function rainWorld(n)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { char, folder }
	for i = 1, n do
		task.delay((i / n) * 1.6, function()
			if not root.Parent then return end
			local a = math.random() * math.pi * 2
			local r = 3 + math.random() * 16
			local at = root.Position + Vector3.new(math.cos(a) * r, 22 + math.random() * 18, math.sin(a) * r)
			local hit = workspace:Raycast(at, Vector3.new(0, -80, 0), rp)
			local ground = hit and hit.Position.Y or (root.Position.Y - 3)
			local isCoin = math.random() < 0.3
			local p, top = piece(isCoin)
			table.insert(drops, {
				part = p, top = top, coin = isCoin, pos = at, ground = ground + (isCoin and 0.55 or 0.05),
				vy = 11 + math.random() * 7, sway = 1 + math.random() * 1.5, freq = 1.5 + math.random() * 1.5,
				phase = math.random() * 6, spin = Vector3.new(math.random() * 4 - 2, math.random() * 6 - 3, math.random() * 4 - 2),
				rot = CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6), t = 0,
			})
		end)
	end
end

local function fade(d)
	for _, x in { d.part, d.top } do
		if x then TweenService:Create(x, TweenInfo.new(0.8), { Transparency = 1 }):Play() end
	end
	task.delay(0.9, function()
		d.part:Destroy()
		if d.top then d.top:Destroy() end
	end)
end

RunService.RenderStepped:Connect(function(dt)
	for i = #flutter, 1, -1 do
		local f = flutter[i]
		f.t += dt
		f.y += f.vy * dt
		f.rot += f.spin * dt
		local x = f.x0 + math.sin(f.t * f.freq + f.phase) * f.sway
		f.obj.Position = UDim2.fromOffset(x, f.y)
		f.obj.Rotation = f.rot
		-- (turning over as it falls: squashed across)
		f.obj.Size = UDim2.fromOffset(f.base.X.Offset * (0.25 + 0.75 * math.abs(math.cos(f.t * f.flip))), f.base.Y.Offset)
		if f.y > f.h + 60 then
			f.obj:Destroy()
			table.remove(flutter, i)
		end
	end
	for i = #drops, 1, -1 do
		local d = drops[i]
		if not d.landed then
			d.t += dt
			d.pos -= Vector3.new(0, d.vy * dt, 0)
			local sway = Vector3.new(math.sin(d.t * d.freq + d.phase), 0, math.cos(d.t * d.freq * 0.8 + d.phase)) * d.sway
			d.rot = d.rot * CFrame.Angles(d.spin.X * dt, d.spin.Y * dt, d.spin.Z * dt)
			local cf
			if d.pos.Y <= d.ground then
				-- (down: flat on the ground, a random turn, then gone)
				d.landed = true
				local yaw = math.random() * 6
				cf = d.coin and CFrame.new(d.pos.X, d.ground, d.pos.Z) * CFrame.Angles(0, yaw, math.rad(90)) or CFrame.new(d.pos.X, d.ground, d.pos.Z) * CFrame.Angles(0, yaw, 0)
				task.delay(1.6, function() fade(d) end)
				table.remove(drops, i)
			else
				cf = CFrame.new(d.pos + sway) * d.rot
			end
			d.part.CFrame = cf
			if d.top then d.top.CFrame = cf * CFrame.new(0, 0.01, 0) end
		end
	end
end)

Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
	if kind ~= "celebrate" or type(data) ~= "table" then return end
	if data.kind == "money" then
		rainScreen(data.big and 60 or 40)
		rainWorld(data.big and 44 or 30)
	end
end)
