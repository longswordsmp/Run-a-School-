-- StarterPlayer.StarterPlayerScripts.EventFX
-- What each server event looks like on this client (workspace attribute "Event"):
--   SnowDay: snow falling around you, a cold tint.       Halloween: dusk, orange tint, fog.
--   ScienceFair: green sparkles drifting up.             PictureDay: camera flashes.
--   SpaceCamp: night sky full of stars, a violet tint.
-- Everything is local to this client and put back when the event ends.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local saved = {
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	FogColor = Lighting.FogColor,
	Brightness = Lighting.Brightness,
}
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "EventTint"
cc.Parent = Lighting

-- a box of particles that follows the camera
local emitterPart = Instance.new("Part")
emitterPart.Name = "EventWeather"
emitterPart.Anchored, emitterPart.CanCollide, emitterPart.CanQuery, emitterPart.CanTouch = true, false, false, false
emitterPart.Transparency = 1
emitterPart.Size = Vector3.new(90, 1, 90)
emitterPart.Parent = workspace
local emitter = Instance.new("ParticleEmitter")
emitter.Enabled = false
emitter.Parent = emitterPart

local flashGui = Instance.new("ScreenGui")
flashGui.Name = "EventFlash"
flashGui.IgnoreGuiInset = true
flashGui.DisplayOrder = 40
flashGui.ResetOnSpawn = false
flashGui.Parent = player:WaitForChild("PlayerGui")
local flash = Instance.new("Frame")
flash.BackgroundColor3 = Color3.new(1, 1, 1)
flash.BackgroundTransparency = 1
flash.Size = UDim2.fromScale(1, 1)
flash.Parent = flashGui

local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local current

local function tween(obj, props, t)
	TweenService:Create(obj, TweenInfo.new(t or 2), props):Play()
end

-- per-event props along the street (client-only, removed when the event ends)
local decorFolder = Instance.new("Folder")
decorFolder.Name = "EventDecor"
decorFolder.Parent = workspace
local function prop(name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.Parent = decorFolder
	return p
end
local spin = {}
local function decor(ev)
	decorFolder:ClearAllChildren()
	table.clear(spin)
	if ev == "FieldDay" then
		-- bunting over the carpet and a finish arch at the far end
		local colors = { Color3.fromRGB(230, 60, 60), Color3.fromRGB(255, 205, 60), Color3.fromRGB(60, 140, 240), Color3.fromRGB(80, 200, 110) }
		for x = -300, 300, 60 do
			prop("Line", Vector3.new(0.15, 0.15, 56), CFrame.new(x, 14, 0), Color3.fromRGB(240, 240, 240))
			for i = -6, 6 do
				local w = Instance.new("WedgePart")
				w.Anchored, w.CanCollide, w.CanQuery, w.CanTouch = true, false, false, false
				w.Size = Vector3.new(0.1, 1.6, 2)
				w.CFrame = CFrame.new(x, 13.1, i * 4) * CFrame.Angles(math.rad(180), 0, 0)
				w.Color = colors[(i + 7) % #colors + 1]
				w.Parent = decorFolder
			end
		end
		for _, z in { -12, 12 } do prop("ArchPost", Vector3.new(1.5, 14, 1.5), CFrame.new(320, 7, z), Color3.fromRGB(250, 250, 250)) end
		local banner = prop("FinishBanner", Vector3.new(1, 3, 26), CFrame.new(320, 13, 0), Color3.fromRGB(230, 60, 60))
		local g = Instance.new("SurfaceGui")
		g.Face = Enum.NormalId.Left
		g.Parent = banner
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.TextScaled = true
		t.Font = Enum.Font.LuckiestGuy
		t.Text = "FINISH"
		t.TextColor3 = Color3.new(1, 1, 1)
		t.Parent = g
	elseif ev == "PromNight" then
		-- a disco ball over the hub and string lights along the street
		local ball = prop("DiscoBall", Vector3.new(6, 6, 6), CFrame.new(0, 30, 0), Color3.fromRGB(220, 225, 235), Enum.Material.Foil, Enum.PartType.Ball)
		local l = Instance.new("PointLight")
		l.Range = 40
		l.Brightness = 2
		l.Color = Color3.fromRGB(255, 120, 220)
		l.Parent = ball
		table.insert(spin, ball)
		prop("Chain", Vector3.new(0.2, 6, 0.2), CFrame.new(0, 36, 0), Color3.fromRGB(150, 150, 160), Enum.Material.Metal)
		local bulbs = { Color3.fromRGB(255, 90, 220), Color3.fromRGB(90, 200, 255), Color3.fromRGB(255, 230, 90) }
		for x = -300, 300, 10 do
			for _, z in { -25, 25 } do
				prop("Bulb", Vector3.new(0.8, 0.8, 0.8), CFrame.new(x, 10.5 + math.sin(x / 10) * 0.6, z), bulbs[(x // 10) % 3 + 1], Enum.Material.Neon, Enum.PartType.Ball)
			end
		end
	elseif ev == "WizardWeek" then
		-- floating candles over the carpet
		for x = -300, 300, 25 do
			for _, z in { -10, 10 } do
				local c = prop("Candle", Vector3.new(1.2, 3.4, 1.2), CFrame.new(x + (z > 0 and 12 or 0), 11, z), Color3.fromRGB(250, 245, 230), nil, nil)
				local f = prop("Flame", Vector3.new(0.9, 1.3, 0.9), c.CFrame * CFrame.new(0, 2.2, 0), Color3.fromRGB(255, 200, 90), Enum.Material.Neon, Enum.PartType.Ball)
				local l = Instance.new("PointLight")
				l.Range = 12
				l.Brightness = 1.2
				l.Color = Color3.fromRGB(255, 200, 120)
				l.Parent = f
				c:SetAttribute("Bob", math.random() * 6)
				f:SetAttribute("Bob", c:GetAttribute("Bob"))
			end
		end
	elseif ev == "CandyCarnival" then
		-- striped tents in the gaps
		for _, x in { -190, 0, 190 } do
			for _, z in { -45, 45 } do
				for i = 0, 7 do
					local a = math.rad(i * 45)
					local w = Instance.new("WedgePart")
					w.Anchored, w.CanCollide, w.CanQuery, w.CanTouch = true, false, false, false
					w.Size = Vector3.new(4.2, 7, 5)
					w.CFrame = CFrame.new(x, 8, z) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 2.5)
					w.Color = i % 2 == 0 and Color3.fromRGB(255, 90, 150) or Color3.fromRGB(255, 255, 255)
					w.Parent = decorFolder
				end
				prop("TentBase", Vector3.new(10, 4.6, 10), CFrame.new(x, 2.3, z), Color3.fromRGB(255, 200, 225))
			end
		end
	elseif ev == "HostileTakeover" then
		-- Vex's banners on the lamp posts
		for x = -300, 300, 50 do
			for _, z in { -24, 24 } do
				local b = prop("VexBanner", Vector3.new(0.2, 5, 2.6), CFrame.new(x, 8, z - math.sign(z) * 1.2), Color3.fromRGB(60, 20, 90))
				local g = Instance.new("SurfaceGui")
				g.Face = z < 0 and Enum.NormalId.Right or Enum.NormalId.Left
				g.Parent = b
				local t = Instance.new("TextLabel")
				t.Size = UDim2.fromScale(1, 1)
				t.BackgroundTransparency = 1
				t.TextScaled = true
				t.Font = Enum.Font.LuckiestGuy
				t.Text = "VEX\nPROPERTY\nSOON"
				t.TextColor3 = Color3.fromRGB(255, 220, 90)
				t.Parent = g
			end
		end
	elseif ev == "Graduation" then
		-- a graduation arch over the carpet and caps floating in the sky
		for _, z in { -12, 12 } do prop("ArchPost", Vector3.new(2, 16, 2), CFrame.new(-120, 8, z), Color3.fromRGB(250, 250, 250)) end
		local banner = prop("GradBanner", Vector3.new(1.4, 3.4, 28), CFrame.new(-120, 15, 0), Color3.fromRGB(30, 30, 40))
		for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
			local g = Instance.new("SurfaceGui")
			g.Face = face
			g.Parent = banner
			local t = Instance.new("TextLabel")
			t.Size = UDim2.fromScale(1, 1)
			t.BackgroundTransparency = 1
			t.TextScaled = true
			t.Font = Enum.Font.LuckiestGuy
			t.Text = "CONGRATULATIONS GRADUATES!"
			t.TextColor3 = Color3.fromRGB(255, 215, 90)
			t.Parent = g
		end
		for i = 1, 30 do
			local cap = prop("Cap", Vector3.new(2.2, 0.2, 2.2), CFrame.new(math.random(-300, 300), 25 + math.random() * 20, math.random(-40, 40)) * CFrame.Angles(0, math.random() * 6, math.random() * 0.4), Color3.fromRGB(25, 25, 30))
			cap:SetAttribute("Bob", math.random() * 6)
		end
	end
end

local function reset()
	decorFolder:ClearAllChildren()
	table.clear(spin)
	emitter.Enabled = false
	tween(cc, { TintColor = Color3.new(1, 1, 1), Saturation = 0, Brightness = 0 })
	tween(Lighting, { ClockTime = saved.ClockTime, FogEnd = saved.FogEnd, FogColor = saved.FogColor, Brightness = saved.Brightness })
end

local function apply(ev)
	reset()
	current = ev
	if ev == "SnowDay" then
		emitter.Texture = SPARKLE
		emitter.Color = ColorSequence.new(Color3.new(1, 1, 1))
		emitter.LightEmission = 0.2
		emitter.Size = NumberSequence.new(0.35)
		emitter.Rate = 120
		emitter.Lifetime = NumberRange.new(6, 8)
		emitter.Speed = NumberRange.new(5, 8)
		emitter.SpreadAngle = Vector2.new(15, 15)
		emitter.EmissionDirection = Enum.NormalId.Bottom
		emitter.Acceleration = Vector3.new(1, 0, 0.5)
		emitter.Enabled = true
		tween(cc, { TintColor = Color3.fromRGB(225, 238, 255), Saturation = -0.1 })
	elseif ev == "Halloween" then
		tween(Lighting, { ClockTime = 18.3, FogEnd = 500, FogColor = Color3.fromRGB(60, 30, 50) })
		tween(cc, { TintColor = Color3.fromRGB(255, 205, 170), Saturation = 0.1 })
	elseif ev == "ScienceFair" then
		emitter.Texture = SPARKLE
		emitter.Color = ColorSequence.new(Color3.fromRGB(120, 255, 120))
		emitter.LightEmission = 1
		emitter.Size = NumberSequence.new(0.5, 0)
		emitter.Rate = 30
		emitter.Lifetime = NumberRange.new(3, 5)
		emitter.Speed = NumberRange.new(1, 3)
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Acceleration = Vector3.zero
		emitter.Enabled = true
		tween(cc, { TintColor = Color3.fromRGB(230, 255, 230) })
	elseif ev == "SpaceCamp" then
		tween(Lighting, { ClockTime = 0.5, Brightness = 1.5 })
		tween(cc, { TintColor = Color3.fromRGB(225, 215, 255), Saturation = 0.15 })
	elseif ev == "PictureDay" then
		tween(cc, { Saturation = 0.2, Brightness = 0.03 })
	elseif ev == "FieldDay" then
		tween(cc, { Saturation = 0.25, Brightness = 0.04 })
		decor(ev)
	elseif ev == "PromNight" then
		tween(Lighting, { ClockTime = 21, Brightness = 1.4 })
		tween(cc, { TintColor = Color3.fromRGB(255, 220, 245), Saturation = 0.3 })
		emitter.Texture = SPARKLE
		emitter.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 220)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 200, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 90)) })
		emitter.LightEmission = 1
		emitter.Size = NumberSequence.new(0.6, 0)
		emitter.Rate = 40
		emitter.Lifetime = NumberRange.new(2, 3)
		emitter.Speed = NumberRange.new(2, 4)
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Acceleration = Vector3.zero
		emitter.Enabled = true
		decor(ev)
	elseif ev == "Throwback" then
		-- the era flips every 60 s: sepia, then neon
		task.spawn(function()
			local sepia = true
			while current == "Throwback" do
				if sepia then
					tween(cc, { TintColor = Color3.fromRGB(255, 225, 180), Saturation = -0.6, Contrast = 0.1 }, 3)
				else
					tween(cc, { TintColor = Color3.fromRGB(230, 210, 255), Saturation = 0.5, Contrast = 0.15 }, 3)
				end
				sepia = not sepia
				task.wait(60)
			end
			tween(cc, { Contrast = 0 })
		end)
	elseif ev == "WizardWeek" then
		tween(Lighting, { ClockTime = 19.5 })
		tween(cc, { TintColor = Color3.fromRGB(225, 210, 255), Saturation = 0.15 })
		emitter.Texture = SPARKLE
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 220, 140))
		emitter.LightEmission = 1
		emitter.Size = NumberSequence.new(0.5, 0)
		emitter.Rate = 20
		emitter.Lifetime = NumberRange.new(4, 6)
		emitter.Speed = NumberRange.new(0.5, 1.5)
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Acceleration = Vector3.zero
		emitter.Enabled = true
		decor(ev)
	elseif ev == "CandyCarnival" then
		tween(cc, { TintColor = Color3.fromRGB(255, 225, 240), Saturation = 0.35 })
		decor(ev)
	elseif ev == "HostileTakeover" then
		tween(Lighting, { FogEnd = 700, FogColor = Color3.fromRGB(90, 80, 100) })
		tween(cc, { TintColor = Color3.fromRGB(225, 225, 235), Saturation = -0.25, Contrast = 0.1 })
		decor(ev)
	elseif ev == "Graduation" then
		tween(Lighting, { ClockTime = 17.2 })
		tween(cc, { TintColor = Color3.fromRGB(255, 240, 215), Saturation = 0.1 })
		decor(ev)
	end
end

local function onEvent()
	local ev = workspace:GetAttribute("Event")
	if ev == current then return end
	if ev then apply(ev) else current = nil reset() end
end
workspace:GetAttributeChangedSignal("Event"):Connect(onEvent)
onEvent()

-- the Principal's Pick: the street goes to dusk a minute before it arrives, back to day after
local pickDusk = false
task.spawn(function()
	while true do
		task.wait(1)
		local at = workspace:GetAttribute("PickAt")
		local now = workspace:GetServerTimeNow()
		-- PickAt moves on to the next one as soon as the bus comes, so remember when this one was due
		local want = at and (at - now <= 60) or false
		if want and not pickDusk then
			pickDusk = true
			tween(Lighting, { ClockTime = 18.6 }, 20)
			local due = at
			task.delay(math.max(0, due - now) + 90, function()
				pickDusk = false
				if not current then tween(Lighting, { ClockTime = saved.ClockTime }, 10) end
			end)
		end
	end
end)

-- event tokens (TicketService) spin and bob here; the server only places them
local CollectionService = game:GetService("CollectionService")
local tokens = {}
local function addToken(t)
	if t:IsA("BasePart") then tokens[t] = { base = t.CFrame, phase = math.random() * 6 } end
end
for _, t in CollectionService:GetTagged("EventToken") do addToken(t) end
CollectionService:GetInstanceAddedSignal("EventToken"):Connect(addToken)
CollectionService:GetInstanceRemovedSignal("EventToken"):Connect(function(t)
	tokens[t] = nil
end)

-- keep the weather over the camera; flash now and then on Picture Day
local nextFlash = 0
RunService.RenderStepped:Connect(function(dt)
	local now = os.clock()
	for t, s in tokens do
		if t.Parent then
			t.CFrame = s.base * CFrame.new(0, math.sin(now * 2 + s.phase) * 0.4, 0) * CFrame.Angles(0, now * 2.2 + s.phase, 0)
		else
			tokens[t] = nil
		end
	end
	for _, b in spin do
		if b.Parent then b.CFrame = b.CFrame * CFrame.Angles(0, dt * 0.8, 0) end
	end
	local clock = os.clock()
	for _, d in decorFolder:GetChildren() do
		local phase = d:GetAttribute("Bob")
		if phase then
			local base = d:GetAttribute("BaseY") or d.Position.Y
			d:SetAttribute("BaseY", base)
			d.Position = Vector3.new(d.Position.X, base + math.sin(clock * 1.5 + phase) * 0.5, d.Position.Z)
		end
	end
	local p = camera.CFrame.Position
	emitterPart.CFrame = CFrame.new(p.X, p.Y + (current == "SnowDay" and 35 or -6), p.Z)
	if current == "PictureDay" and os.clock() > nextFlash then
		nextFlash = os.clock() + 3 + math.random() * 4
		flash.BackgroundTransparency = 0.25
		tween(flash, { BackgroundTransparency = 1 }, 0.35)
	end
end)
