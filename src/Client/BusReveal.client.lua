-- StarterPlayer.StarterPlayerScripts.BusReveal
-- What comes off the MAGIC BUS (tomas, 2026-09-27: "the animation has to feel rewarding, good after
-- buying ... so that they buy more, they need to be hyped up"). BusDepotService pushes "busOpen" with
-- the kids a purchase rolled; this plays them:
--   one bus    the screen darkens, rays turn behind, the bus screams in with its speed trail and
--              brakes (nose dipping), rocks harder and harder under a drum roll while a glow builds
--              (and, for the rare ones, turns their colour: the tease), a rising whoosh, then BANG:
--              a flash, a shockwave ring, confetti, the rays in the kid's colour, the kid popping out
--              big, its rarity slamming in, its name, its money counting up, NEW! if it's new
--   3 or 10    the buses in a row (two rows for ten), all rocking together, then popping one by one,
--              the rarest last; a Mythic or better then gets the full reveal of its own
--   50         fifty buses thunder past, then every kind of kid it brought counts up fast, the rarest
--              last with a bang; a Mythic or better gets its own reveal
-- The ??? (the twins) gets the lot: the screen goes black, the glow cycles the rainbow, SECRET.
-- Click (or wait) to go on.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Icons = require(Shared:WaitForChild("Icons"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local clientBus = ReplicatedStorage:WaitForChild("ClientBus", 10)
local TEMPLATES = ReplicatedStorage:WaitForChild("StudentTemplates", 10)

local rgb = Color3.fromRGB
local WHITE = Color3.new(1, 1, 1)

-- (a kid's template arrives on this client a piece at a time: copying it half-arrived gave a kid with
-- no head or legs. Ready = its head and both feet are there and it has stopped growing)
local function kidReady(t, timeout)
	local t0 = os.clock()
	local last = -1
	while os.clock() - t0 < (timeout or 20) do
		if t.Parent and t:FindFirstChild("Head") and t:FindFirstChild("LeftFoot") and t:FindFirstChild("RightFoot") then
			local n = #t:GetDescendants()
			if n == last then return true end
			last = n
		end
		task.wait(0.25)
	end
	return false
end

local function sfx(name)
	if clientBus and clientBus:FindFirstChild("Sfx") then clientBus.Sfx:Fire(name) end
end
local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

---------------------------------------------------------------------------
-- the screen
---------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "BusReveal"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 80
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
root.Parent = gui

local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.BackgroundColor3 = rgb(12, 4, 28)
backdrop.BackgroundTransparency = 1
backdrop.Size = UDim2.new(1, 40, 1, 40)
backdrop.Position = UDim2.fromOffset(-20, -20)
backdrop.ZIndex = 1
backdrop.Parent = root

local rays = Instance.new("Frame")
rays.Name = "Rays"
rays.BackgroundTransparency = 1
rays.Size = UDim2.fromScale(1, 1)
rays.ZIndex = 2
rays.Parent = root

local stage = Instance.new("Frame")
stage.Name = "Stage"
stage.BackgroundTransparency = 1
stage.Size = UDim2.fromScale(1, 1)
stage.ZIndex = 3
stage.Parent = root

local fx = Instance.new("Frame")
fx.Name = "FX"
fx.BackgroundTransparency = 1
fx.Size = UDim2.fromScale(1, 1)
fx.ZIndex = 5
fx.Parent = root

local texts = Instance.new("Frame")
texts.Name = "Texts"
texts.BackgroundTransparency = 1
texts.Size = UDim2.fromScale(1, 1)
texts.ZIndex = 6
texts.Parent = root

local flash = Instance.new("Frame")
flash.Name = "Flash"
flash.BackgroundColor3 = WHITE
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Size = UDim2.new(1, 40, 1, 40)
flash.Position = UDim2.fromOffset(-20, -20)
flash.ZIndex = 8
flash.Parent = root

local catcher = Instance.new("TextButton")
catcher.Name = "Catcher"
catcher.Text = ""
catcher.BackgroundTransparency = 1
catcher.Size = UDim2.fromScale(1, 1)
catcher.ZIndex = 10
catcher.Parent = gui

local clicked = false
catcher.Activated:Connect(function() clicked = true end)
local function waitClick(minT, maxT)
	task.wait(minT)
	clicked = false
	local t0 = os.clock()
	while not clicked and os.clock() - t0 < maxT do task.wait() end
end

local function label(parent, props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.LuckiestGuy
	t.TextScaled = true
	t.TextColor3 = WHITE
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	for k, v in props do
		if k ~= "stroke" then t[k] = v end
	end
	local s = Instance.new("UIStroke")
	s.Thickness = props.stroke or 4
	s.Color = rgb(20, 10, 30)
	s.Parent = t
	t.Parent = parent
	return t
end

-- the rarity's colours for its words: a gradient, the rainbow (animated) for the ???
local rainbowGrads = {}
local function rarityGradient(obj, def, secret)
	local rar = Config.RarityById[def.rarity]
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	if secret then
		rainbowGrads[g] = true
	elseif rar.gradient then
		g.Color = ColorSequence.new(rar.gradient[1], rar.gradient[2])
	else
		g.Color = ColorSequence.new(UI.lighten(rar.color, 0.45), rar.color)
	end
	g.Parent = obj
	return g
end
local function rarityColor(def, secret)
	if secret then return Color3.fromHSV((os.clock() * 0.6) % 1, 0.7, 1) end
	return Config.RarityById[def.rarity].color
end

---------------------------------------------------------------------------
-- effects: confetti, a shockwave ring, puffs of dust, the screen shaking
---------------------------------------------------------------------------
local confetti = {}
local function burst(x, y, colors, n, power)
	for _ = 1, n do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = UDim2.fromOffset(math.random(8, 16), math.random(5, 10))
		f.BackgroundColor3 = colors[math.random(#colors)]
		f.Rotation = math.random(0, 360)
		f.ZIndex = 5
		f.Position = UDim2.fromOffset(x, y)
		f.Parent = fx
		local a = math.random() * math.pi * 2
		local sp = power * (0.35 + math.random() * 0.9)
		table.insert(confetti, { f = f, x = x, y = y, vx = math.cos(a) * sp, vy = math.sin(a) * sp - power * 0.55, vr = math.random(-600, 600), t = 0, life = 1.3 + math.random() * 0.7 })
	end
end
local function ring(x, y, color, size, t)
	local r = Instance.new("Frame")
	r.BackgroundTransparency = 1
	r.AnchorPoint = Vector2.new(0.5, 0.5)
	r.Position = UDim2.fromOffset(x, y)
	r.Size = UDim2.fromOffset(10, 10)
	r.ZIndex = 5
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = r
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = 10
	s.Parent = r
	r.Parent = fx
	tween(r, t or 0.5, { Size = UDim2.fromOffset(size, size) }, Enum.EasingStyle.Quart)
	tween(s, t or 0.5, { Transparency = 1, Thickness = 2 })
	task.delay((t or 0.5) + 0.05, function() r:Destroy() end)
end
local function puff(x, y, n)
	for _ = 1, n do
		local p = Instance.new("Frame")
		p.BorderSizePixel = 0
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.BackgroundColor3 = rgb(235, 225, 255)
		p.BackgroundTransparency = 0.25
		local d = math.random(26, 46)
		p.Size = UDim2.fromOffset(d, d)
		p.Position = UDim2.fromOffset(x + math.random(-30, 30), y + math.random(-6, 6))
		p.ZIndex = 5
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = p
		p.Parent = fx
		tween(p, 0.6, { Size = UDim2.fromOffset(d * 2.2, d * 2.2), BackgroundTransparency = 1, Position = UDim2.fromOffset(x + math.random(-110, 110), y - math.random(10, 50)) })
		task.delay(0.65, function() p:Destroy() end)
	end
end
local shakeUntil, shakeMag = 0, 0
local function shake(mag, t)
	shakeUntil = math.max(shakeUntil, os.clock() + t)
	shakeMag = math.max(shakeMag, mag)
end
local function flashTo(color, t)
	flash.BackgroundColor3 = color or WHITE
	flash.BackgroundTransparency = 0
	tween(flash, t or 0.5, { BackgroundTransparency = 1 })
end

-- the rays behind everything: a turning burst in a colour
local raysHalo
local function setRays(color, size, speed)
	if raysHalo then raysHalo:Destroy() end
	raysHalo = UI.halo(rays, { size = size, position = UDim2.fromScale(0.5, 0.45), zindex = 2, color = color, speed = speed or 12, beamT = 0.3, coreT = 0.72 })
end

RunService.RenderStepped:Connect(function(dt)
	if not gui.Enabled then return end
	for i = #confetti, 1, -1 do
		local c = confetti[i]
		c.t += dt
		c.vy += 1500 * dt
		c.vx *= 0.99
		c.x += c.vx * dt
		c.y += c.vy * dt
		c.f.Position = UDim2.fromOffset(c.x, c.y)
		c.f.Rotation += c.vr * dt
		if c.t > c.life - 0.4 then c.f.BackgroundTransparency = math.clamp((c.t - (c.life - 0.4)) / 0.4, 0, 1) end
		if c.t > c.life then
			c.f:Destroy()
			table.remove(confetti, i)
		end
	end
	if os.clock() < shakeUntil then
		local m = shakeMag * math.clamp((shakeUntil - os.clock()) * 3, 0, 1)
		root.Position = UDim2.fromOffset(math.random(-m, m), math.random(-m, m))
	else
		root.Position = UDim2.new()
		shakeMag = 0
	end
	local h = (os.clock() * 0.6) % 1
	local keys = {}
	for k = 0, 6 do keys[k + 1] = ColorSequenceKeypoint.new(k / 6, Color3.fromHSV((h + k / 6) % 1, 0.65, 1)) end
	local seq = ColorSequence.new(keys)
	for g in rainbowGrads do
		if g.Parent then g.Color = seq else rainbowGrads[g] = nil end
	end
end)

---------------------------------------------------------------------------
-- a slot: a viewport the bus pulls into and the kid pops out of, a glow behind it
---------------------------------------------------------------------------
local VIS_H = 2 * 18 * math.tan(math.rad(15)) -- (what the slot camera sees, top to bottom, in studs)
local function makeSlot(pos, size)
	local s = {}
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = pos
	f.Size = size
	f.ZIndex = 3
	f.Parent = stage
	local glow = Instance.new("ImageLabel")
	glow.BackgroundTransparency = 1
	glow.Image = UI.GLOW
	glow.ImageTransparency = 1
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.Size = UDim2.fromScale(1.15, 1.25)
	glow.ZIndex = 1
	glow.Parent = f
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.ZIndex = 2
	vp.Ambient = rgb(180, 175, 190)
	vp.LightColor = rgb(255, 250, 240)
	vp.LightDirection = Vector3.new(-0.45, -1, 0.7)
	vp.Parent = f
	local wm = Instance.new("WorldModel")
	wm.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 0.6, -18), Vector3.new(0, 0.3, 0))
	cam.Parent = vp
	vp.CurrentCamera = cam
	s.frame, s.glow, s.vp, s.wm = f, glow, vp, wm
	local a = f.AbsoluteSize
	s.visW = VIS_H * ((a.Y > 0) and a.X / a.Y or 1.6)
	return s
end
local function center(slot)
	local p, a = slot.frame.AbsolutePosition, slot.frame.AbsoluteSize
	return p.X + a.X / 2, p.Y + a.Y / 2, a
end

-- the bus into a slot, off to the left of it (the left of the screen is +X here)
local function putBus(slot, fill)
	local b = Icons.build("magicbus")
	for _, d in b:GetDescendants() do
		if d:IsA("BasePart") and d.Material == Enum.Material.SmoothPlastic then d.Material = Enum.Material.Plastic end
	end
	b:PivotTo(CFrame.Angles(0, math.rad(-16), 0))
	local _, size = b:GetBoundingBox()
	local scale = math.min(slot.visW * (fill or 0.8) / size.X, VIS_H * 0.62 / size.Y)
	b:ScaleTo(scale)
	b:PivotTo(CFrame.Angles(0, math.rad(-16), 0))
	slot.rest = b:GetPivot()
	b:PivotTo(slot.rest + Vector3.new(slot.visW + 12, 0, 0))
	b.Parent = slot.wm
	slot.bus = b
	slot.scale = scale
end
local function dropBus(slot)
	local b = slot.bus
	if not b then return end
	slot.bus = nil
	for _, d in b:GetDescendants() do
		if d:IsA("BasePart") then d.Transparency = 1 end
	end
	b.Parent = nil
	b:Destroy()
end
local function moveBus(slot, to, t, style, dir)
	local b = slot.bus
	if not b then return end
	local v = Instance.new("CFrameValue")
	v.Value = b:GetPivot()
	v.Changed:Connect(function(x) if b.Parent then b:PivotTo(x) end end)
	local tw = tween(v, t, { Value = to }, style, dir)
	tw.Completed:Connect(function() v:Destroy() end)
	return tw
end
local function driveIn(slot, t)
	moveBus(slot, slot.rest * CFrame.Angles(0, 0, math.rad(-4)), t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	task.delay(t * 0.85, function()
		-- the brakes: the nose dips and comes back up
		moveBus(slot, slot.rest * CFrame.Angles(0, 0, math.rad(7)), 0.12)
		task.delay(0.12, function() moveBus(slot, slot.rest, 0.35, Enum.EasingStyle.Back) end)
		local x, y, a = center(slot)
		puff(x - a.X * 0.05, y + a.Y * 0.22, 5)
	end)
end
-- one rock of the bus: hop and tip, a bit harder each time
local function wobble(slot, deg, t)
	local up = slot.rest + Vector3.new(0, 0.12 * slot.scale * deg / 6, 0)
	moveBus(slot, up * CFrame.Angles(math.rad(deg * 0.3), 0, math.rad(deg)), t / 2)
	task.wait(t / 2)
	moveBus(slot, slot.rest * CFrame.Angles(math.rad(-deg * 0.3), 0, math.rad(-deg)), t / 2)
	task.wait(t / 2)
end

-- the kid into a slot (big: fills it), popping up from nothing; returns the model
local function putKid(slot, id, fill)
	local t = TEMPLATES and TEMPLATES:FindFirstChild(id)
	if not t then return nil end
	kidReady(t, 3)
	local m = t:Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("BillboardGui") then d:Destroy() end
	end
	m:PivotTo(CFrame.new())
	m.Parent = slot.wm
	local twin = m:FindFirstChild("Twin")
	local width = twin and 4.1 or 2.3
	local s = math.min(VIS_H * (fill or 0.7) / 4.6, slot.visW * 0.85 / width)
	local midX = twin and 0.85 or 0
	local at = Vector3.new(-midX * s, 0.15, 0)
	local v = Instance.new("NumberValue")
	v.Value = 0.05
	local turn = 0
	local function place()
		if not m.Parent then return end
		m:ScaleTo(math.max(0.02, s * v.Value))
		m:PivotTo(CFrame.new(Vector3.new(-midX * s * v.Value, 0.15, 0)) * CFrame.Angles(0, turn, 0))
	end
	v.Changed:Connect(place)
	place()
	tween(v, 0.45, { Value = 1 }, Enum.EasingStyle.Back)
	task.spawn(function()
		local t0 = os.clock()
		while m.Parent do
			turn = math.sin((os.clock() - t0) * 1.4) * 0.35
			place()
			task.wait()
		end
		v:Destroy()
	end)
	_ = at
	return m
end

---------------------------------------------------------------------------
-- clearing up between reveals
---------------------------------------------------------------------------
local function clear()
	for _, c in stage:GetChildren() do c:Destroy() end
	for _, c in texts:GetChildren() do c:Destroy() end
	for _, c in fx:GetChildren() do c:Destroy() end
	table.clear(confetti)
	if raysHalo then raysHalo:Destroy() raysHalo = nil end
end
local function hint()
	local h = label(texts, { Text = "TAP TO CONTINUE", Size = UDim2.fromOffset(420, 34), Position = UDim2.fromScale(0.5, 0.95), TextColor3 = rgb(230, 225, 255), ZIndex = 6, stroke = 3 })
	task.spawn(function()
		while h.Parent do
			tween(h, 0.5, { TextTransparency = 0.5 })
			task.wait(0.5)
			tween(h, 0.5, { TextTransparency = 0 })
			task.wait(0.5)
		end
	end)
	return h
end

-- the words for a kid: its rarity slamming in, its name, what it earns counting up, NEW!, where it went
local function kidWords(def, r, secret, big)
	local rar = Config.RarityById[def.rarity]
	local rarity = label(texts, { Text = secret and "SECRET!!" or (rar.id:upper() .. "!"), Size = UDim2.fromOffset(big and 760 or 500, big and 110 or 70), Position = UDim2.fromScale(0.5, big and 0.13 or 0.2), ZIndex = 6, stroke = big and 7 or 5 })
	rarityGradient(rarity, def, secret)
	local sc = Instance.new("UIScale")
	sc.Scale = 3
	sc.Parent = rarity
	rarity.TextTransparency = 1
	tween(rarity, 0.2, { TextTransparency = 0 })
	tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	local name = label(texts, { Text = def.name, Size = UDim2.fromOffset(big and 820 or 600, big and 70 or 50), Position = UDim2.fromScale(0.5, big and 0.77 or 0.74), ZIndex = 6, stroke = 5 })
	name.TextTransparency = 1
	task.delay(0.2, function() tween(name, 0.25, { TextTransparency = 0 }) end)
	local money = label(texts, { Text = "+$0/s", Size = UDim2.fromOffset(520, big and 56 or 42), Position = UDim2.fromScale(0.5, big and 0.845 or 0.81), TextColor3 = rgb(130, 255, 130), ZIndex = 6, stroke = 4 })
	local v = Instance.new("NumberValue")
	v.Changed:Connect(function(x) money.Text = "+" .. Config.formatCash(x) .. "/s" end)
	task.delay(0.3, function() tween(v, 0.9, { Value = def.income }, Enum.EasingStyle.Quart) end)
	task.delay(1.4, function() v:Destroy() end)
	if r.first then
		local new = label(texts, { Text = "NEW!", Size = UDim2.fromOffset(150, 52), Position = UDim2.new(0.5, big and 330 or 250, big and 0.77 or 0.74, -40), Rotation = 12, TextColor3 = rgb(255, 235, 80), ZIndex = 7, stroke = 5 })
		local ns = Instance.new("UIScale")
		ns.Scale = 0
		ns.Parent = new
		task.delay(0.55, function() tween(ns, 0.3, { Scale = 1 }, Enum.EasingStyle.Back) end)
	end
	local fate = r.fate == "desk" and ("Sat down at desk " .. tostring(r.slot))
		or r.fate == "replaced" and ("Took " .. tostring(r.old) .. "'s seat")
		or ("No room: sold for " .. Config.formatCash(r.gain or 0))
	label(texts, { Text = fate, Font = Enum.Font.FredokaOne, Size = UDim2.fromOffset(600, 28), Position = UDim2.fromScale(0.5, big and 0.895 or 0.86), TextColor3 = rgb(220, 215, 240), ZIndex = 6, stroke = 2.5 })
	_ = rar
end

---------------------------------------------------------------------------
-- ONE bus (direct: straight to the pop, for a rare kid out of a pack)
---------------------------------------------------------------------------
local function playOne(bus, r, direct)
	clear()
	local def = Config.StudentById[r.id]
	local n = #bus.kids
	local secret = r.tier == n
	local rare = r.tier >= 4
	local vs = workspace.CurrentCamera.ViewportSize
	local slot = makeSlot(UDim2.fromScale(0.5, 0.45), UDim2.fromScale(0.95, 0.56))
	task.wait()
	slot.visW = VIS_H * (slot.frame.AbsoluteSize.X / math.max(slot.frame.AbsoluteSize.Y, 1))
	setRays(UI.lighten(bus.color, 0.4), vs.Y * 1.5, 10)
	tween(backdrop, 0.3, { BackgroundTransparency = 0.08 })
	local x, y, a = center(slot)
	if not direct then
		putBus(slot, 0.6)
		sfx("BusWhoosh")
		driveIn(slot, 0.6)
		task.wait(0.6)
		shake(8, 0.25)
		task.wait(0.45)
		-- the build-up: rocking harder, the glow growing (and turning the kid's colour if it's rare)
		sfx("BusRoll")
		local rocks = secret and 7 or (r.tier >= 5 and 6 or (rare and 5 or 4))
		for k = 1, rocks do
			local tease = rare and k >= rocks - 1
			slot.glow.ImageColor3 = tease and rarityColor(def, secret) or rgb(255, 240, 255)
			tween(slot.glow, 0.2, { ImageTransparency = math.max(0.05, 0.75 - k * 0.14) })
			if tease then
				burst(x, y, { rarityColor(def, secret), WHITE }, 10, 500)
				shake(4 + k, 0.15)
			end
			if secret and k == rocks - 2 then
				-- the ???: the lights go out, the glow cycles the rainbow
				tween(backdrop, 0.2, { BackgroundTransparency = 0 })
				local q = label(texts, { Text = "? ? ?", Size = UDim2.fromOffset(600, 120), Position = UDim2.fromScale(0.5, 0.14), ZIndex = 6, stroke = 6 })
				rarityGradient(q, def, true)
				shake(12, 0.6)
			end
			wobble(slot, 5 + k * 3, math.max(0.16, 0.34 - k * 0.03))
		end
		sfx("BusRise")
		-- the bus swells, and pops
		local v = Instance.new("NumberValue")
		v.Value = 1
		v.Changed:Connect(function(s) if slot.bus and slot.bus.Parent then slot.bus:ScaleTo(slot.scale * s) end end)
		tween(v, 0.28, { Value = 1.35 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(0.3)
		v:Destroy()
		for _, c in texts:GetChildren() do c:Destroy() end
		dropBus(slot)
	end
	-- BANG
	local col = rarityColor(def, secret)
	flashTo(secret and rgb(255, 200, 255) or WHITE, rare and 0.8 or 0.5)
	shake(rare and 16 or 9, rare and 0.5 or 0.3)
	ring(x, y, col, math.max(vs.X, vs.Y) * 1.1, 0.6)
	task.delay(0.1, function() ring(x, y, WHITE, math.max(vs.X, vs.Y) * 0.8, 0.5) end)
	burst(x, y, { col, UI.lighten(col, 0.5), rgb(255, 230, 80), WHITE, rgb(120, 220, 255) }, rare and 110 or 60, rare and 1300 or 950)
	setRays(UI.lighten(col, 0.25), vs.Y * 1.7, rare and 28 or 18)
	tween(backdrop, 0.3, { BackgroundTransparency = 0.1 })
	slot.glow.ImageColor3 = col
	slot.glow.ImageTransparency = 0
	tween(slot.glow, 1.2, { ImageTransparency = 0.35 })
	putKid(slot, r.id, 0.72)
	kidWords(def, r, secret, true)
	if rare then UI.twinkle(slot.frame, { zindex = 4, every = 0.12, min = 16, max = 34 }) end
	sfx(r.tier >= 5 and "BusWow" or (r.tier >= 3 and "BusWin" or "Enroll"))
	task.delay(0.9, function() if gui.Enabled then burst(x, y - a.Y * 0.2, { col, WHITE, rgb(255, 230, 80) }, rare and 50 or 20, 700) end end)
	hint()
	waitClick(1.2, secret and 9 or 5)
end

---------------------------------------------------------------------------
-- 3 or 10 buses: in a row (two rows for ten), rocking together, popping one by one, rarest last
---------------------------------------------------------------------------
local function playRow(bus, results)
	clear()
	local vs = workspace.CurrentCamera.ViewportSize
	local count = #results
	local cols = count <= 3 and count or 5
	local rows = math.ceil(count / cols)
	local cellW, cellH = 0.92 / cols, (rows == 1 and 0.5 or 0.36)
	local slots = {}
	for i = 1, count do
		local c = (i - 1) % cols
		local rr = math.floor((i - 1) / cols)
		local cy = rows == 1 and 0.45 or (0.3 + rr * 0.38)
		slots[i] = makeSlot(UDim2.fromScale(0.04 + cellW * (c + 0.5), cy), UDim2.fromScale(cellW * 0.98, cellH))
	end
	task.wait()
	for _, s in slots do s.visW = VIS_H * (s.frame.AbsoluteSize.X / math.max(s.frame.AbsoluteSize.Y, 1)) end
	setRays(UI.lighten(bus.color, 0.4), vs.Y * 1.5, 10)
	tween(backdrop, 0.3, { BackgroundTransparency = 0.15 })
	label(texts, { Text = count .. " MAGIC BUSES!", Size = UDim2.fromOffset(700, 80), Position = UDim2.fromScale(0.5, 0.08), TextColor3 = rgb(255, 230, 90), ZIndex = 6, stroke = 5 })
	-- in they come, one after another
	for i, s in slots do
		putBus(s, 0.85)
		task.delay((i - 1) * 0.07, function()
			if i % 3 == 1 then sfx("BusWhoosh") end
			driveIn(s, 0.55)
		end)
	end
	task.wait(0.55 + count * 0.07 + 0.3)
	shake(7, 0.25)
	sfx("BusRoll")
	for k = 1, 4 do
		for _, s in slots do
			s.glow.ImageColor3 = rgb(255, 240, 255)
			tween(s.glow, 0.2, { ImageTransparency = 0.8 - k * 0.12 })
			task.spawn(wobble, s, 4 + k * 3, 0.26)
		end
		task.wait(0.28)
	end
	-- pop them, the rarest last
	local order = {}
	for i = 1, count do order[i] = i end
	table.sort(order, function(a, b) return results[a].tier < results[b].tier end)
	local best = results[order[#order]]
	sfx("BusRise")
	for _, i in order do
		local r, s = results[i], slots[i]
		local def = Config.StudentById[r.id]
		local secret = r.tier == #bus.kids
		local col = rarityColor(def, secret)
		local x, y, a = center(s)
		dropBus(s)
		ring(x, y, col, a.X * 1.6, 0.45)
		burst(x, y, { col, WHITE, rgb(255, 230, 80) }, r.tier >= 4 and 40 or 16, r.tier >= 4 and 900 or 600)
		s.glow.ImageColor3 = col
		s.glow.ImageTransparency = 0
		tween(s.glow, 0.8, { ImageTransparency = 0.3 })
		putKid(s, r.id, 0.72)
		local rl = label(s.frame, { Text = secret and "SECRET!!" or def.rarity:upper(), Size = UDim2.new(1, 0, 0, count <= 3 and 44 or 28), Position = UDim2.new(0.5, 0, 1, count <= 3 and -6 or -2), ZIndex = 3, stroke = 3.5 })
		rarityGradient(rl, def, secret)
		label(s.frame, { Text = def.name, Size = UDim2.new(1, 0, 0, count <= 3 and 30 or 20), Position = UDim2.new(0.5, 0, 1, count <= 3 and 26 or 20), ZIndex = 3, stroke = 3 })
		if r.first then label(s.frame, { Text = "NEW!", Size = UDim2.fromOffset(80, 30), Position = UDim2.new(0.8, 0, 0.12, 0), Rotation = 12, TextColor3 = rgb(255, 235, 80), ZIndex = 3, stroke = 3 }) end
		if r.tier >= 4 then
			flashTo(UI.lighten(col, 0.6), 0.35)
			shake(10, 0.3)
			sfx(r.tier >= 5 and "BusWow" or "BusWin")
			UI.twinkle(s.frame, { zindex = 4, every = 0.15 })
			task.wait(0.55)
		else
			sfx("Enroll")
			shake(3, 0.1)
			task.wait(count <= 3 and 0.45 or 0.22)
		end
	end
	local desk, took, sold, back = 0, 0, 0, 0
	for _, r in results do
		if r.fate == "desk" then desk += 1 elseif r.fate == "replaced" then took += 1 else sold += 1 end
		back += r.gain or 0
	end
	label(texts, { Text = ("%d to desks  \u{2022}  %d took a weaker kid's seat  \u{2022}  %d sold (+%s)"):format(desk, took, sold, Config.formatCash(back)), Font = Enum.Font.FredokaOne, Size = UDim2.fromOffset(900, 30), Position = UDim2.fromScale(0.5, 0.89), TextColor3 = rgb(220, 215, 240), ZIndex = 6, stroke = 2.5 })
	hint()
	waitClick(1, 7)
	return best
end

---------------------------------------------------------------------------
-- 50 buses: they thunder past, then every kind of kid counts up, the rarest last with a bang
---------------------------------------------------------------------------
local function portraitInto(frame, id)
	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.ZIndex = 2
	vp.Ambient = rgb(180, 175, 190)
	vp.LightDirection = Vector3.new(-0.45, -1, 0.7)
	vp.Parent = frame
	local t = TEMPLATES and TEMPLATES:FindFirstChild(id)
	if not t then return end
	kidReady(t, 3)
	local wm = Instance.new("WorldModel")
	wm.Parent = vp
	local m = t:Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("BillboardGui") then d:Destroy() end
	end
	m:PivotTo(CFrame.new())
	m.Parent = wm
	local twin = m:FindFirstChild("Twin")
	local focus = Vector3.new(twin and 0.85 or 0, 1.0, 0)
	local cam = Instance.new("Camera")
	cam.FieldOfView = 32
	cam.CFrame = CFrame.lookAt(focus + Vector3.new(0.35, 0.25, -(twin and 2.7 or 1.6) / math.tan(math.rad(16))), focus)
	cam.Parent = vp
	vp.CurrentCamera = cam
end
local function playMany(bus, results)
	clear()
	local vs = workspace.CurrentCamera.ViewportSize
	setRays(UI.lighten(bus.color, 0.4), vs.Y * 1.5, 14)
	tween(backdrop, 0.3, { BackgroundTransparency = 0.15 })
	local title = label(texts, { Text = #results .. " MAGIC BUSES!", Size = UDim2.fromOffset(820, 100), Position = UDim2.fromScale(0.5, 0.12), TextColor3 = rgb(255, 230, 90), ZIndex = 6, stroke = 6 })
	local ts = Instance.new("UIScale")
	ts.Scale = 2.5
	ts.Parent = title
	tween(ts, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	-- a stampede of buses across the screen
	local lane = makeSlot(UDim2.fromScale(0.5, 0.48), UDim2.fromScale(1, 0.55))
	task.wait()
	lane.visW = VIS_H * (lane.frame.AbsoluteSize.X / math.max(lane.frame.AbsoluteSize.Y, 1))
	for k = 1, 7 do
		task.delay((k - 1) * 0.16, function()
			local b = Icons.build("magicbus")
			b:PivotTo(CFrame.Angles(0, math.rad(-16), 0))
			local _, size = b:GetBoundingBox()
			b:ScaleTo(VIS_H * 0.3 / size.Y)
			local yy = ({ 1.8, -1.2, 0.3, -2.4, 2.6, -0.4, 1.0 })[k]
			local from = CFrame.new(lane.visW / 2 + 8, yy, 2 - k * 0.3) * CFrame.Angles(0, math.rad(-16), 0)
			local to = from - Vector3.new(lane.visW + 16, 0, 0)
			b:PivotTo(from)
			b.Parent = lane.wm
			sfx("BusWhoosh")
			local v = Instance.new("CFrameValue")
			v.Value = from
			v.Changed:Connect(function(x) if b.Parent then b:PivotTo(x) end end)
			tween(v, 0.7, { Value = to }, Enum.EasingStyle.Linear)
			task.delay(0.72, function() b:Destroy() v:Destroy() end)
			shake(5, 0.12)
		end)
	end
	task.wait(1.9)
	lane.frame:Destroy()
	flashTo(WHITE, 0.4)
	-- every kind of kid, counting up
	local groups, byId = {}, {}
	for _, r in results do
		if not byId[r.id] then
			byId[r.id] = { r = r, n = 0 }
			table.insert(groups, byId[r.id])
		end
		if r.first then byId[r.id].first = true end
	end
	table.sort(groups, function(a, b) return a.r.tier < b.r.tier end)
	local cellW = math.min(170, (vs.X * 0.9) / #groups - 12)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.fromScale(0.5, 0.5)
	row.Size = UDim2.fromOffset((cellW + 12) * #groups, cellW * 1.45)
	row.ZIndex = 3
	row.Parent = stage
	local cards = {}
	for i, g in groups do
		local def = Config.StudentById[g.r.id]
		local secret = g.r.tier == #bus.kids
		local rar = Config.RarityById[def.rarity]
		local card = Instance.new("Frame")
		card.AnchorPoint = Vector2.new(0.5, 0.5)
		card.Position = UDim2.fromOffset((i - 0.5) * (cellW + 12), cellW * 0.72)
		card.Size = UDim2.fromOffset(cellW, cellW * 1.4)
		card.BackgroundColor3 = WHITE
		card.ZIndex = 3
		card.Visible = false
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 14)
		cc.Parent = card
		local st = Instance.new("UIStroke")
		st.Thickness = 4
		st.Color = rgb(20, 10, 30)
		st.Parent = card
		local gg = Instance.new("UIGradient")
		gg.Rotation = 90
		gg.Color = secret and ColorSequence.new(rgb(255, 120, 230), rgb(60, 10, 110)) or ColorSequence.new(UI.lighten(rar.color, 0.5), rar.color)
		gg.Parent = card
		card.Parent = row
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.new(1, 0, 0.7, 0)
		holder.ZIndex = 3
		holder.Parent = card
		portraitInto(holder, g.r.id)
		local rl = label(card, { Text = secret and "SECRET!!" or def.rarity:upper(), Size = UDim2.new(1, -8, 0, 24), Position = UDim2.new(0.5, 0, 0.74, 0), ZIndex = 4, stroke = 3 })
		rarityGradient(rl, def, secret)
		label(card, { Text = def.name, Size = UDim2.new(1, -8, 0, 22), Position = UDim2.new(0.5, 0, 0.87, 0), ZIndex = 4, stroke = 2.5 })
		local cnt = label(card, { Text = "x0", Size = UDim2.fromOffset(90, 44), Position = UDim2.new(1, -30, 0, 14), Rotation = 8, TextColor3 = rgb(255, 235, 80), ZIndex = 5, stroke = 4 })
		local sc = Instance.new("UIScale")
		sc.Parent = card
		if g.first then label(card, { Text = "NEW!", Size = UDim2.fromOffset(80, 30), Position = UDim2.new(0, 34, 0, 14), Rotation = -10, TextColor3 = rgb(255, 90, 90), ZIndex = 5, stroke = 3 }) end
		cards[g.r.id] = { card = card, cnt = cnt, sc = sc, g = g, secret = secret, def = def }
	end
	-- count them in, the commoner first
	local sorted = table.clone(results)
	table.sort(sorted, function(a, b) return a.tier < b.tier end)
	for _, r in sorted do
		local c = cards[r.id]
		c.g.n += 1
		c.cnt.Text = "x" .. c.g.n
		if not c.card.Visible then
			c.card.Visible = true
			c.sc.Scale = 0
			local x = c.card.AbsolutePosition.X + c.card.AbsoluteSize.X / 2
			local y = c.card.AbsolutePosition.Y + c.card.AbsoluteSize.Y / 2
			tween(c.sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
			local col = rarityColor(c.def, c.secret)
			if r.tier >= 4 then
				task.wait(0.25)
				flashTo(UI.lighten(col, 0.6), 0.4)
				shake(12, 0.35)
				ring(x, y, col, vs.X * 0.8, 0.5)
				burst(x, y, { col, WHITE, rgb(255, 230, 80) }, 60, 1100)
				sfx(r.tier >= 5 and "BusWow" or "BusWin")
				UI.twinkle(c.card, { zindex = 6, every = 0.15 })
				task.wait(0.6)
			else
				burst(x, y, { col, WHITE }, 14, 500)
				sfx("Enroll")
				task.wait(0.2)
			end
		else
			c.sc.Scale = 1.12
			tween(c.sc, 0.12, { Scale = 1 })
			if c.g.n % 3 == 0 then sfx("Collect") end
			task.wait(0.05)
		end
	end
	local desk, took, sold, back = 0, 0, 0, 0
	for _, r in results do
		if r.fate == "desk" then desk += 1 elseif r.fate == "replaced" then took += 1 else sold += 1 end
		back += r.gain or 0
	end
	label(texts, { Text = ("%d to desks  \u{2022}  %d took a weaker kid's seat  \u{2022}  %d sold (+%s)"):format(desk, took, sold, Config.formatCash(back)), Font = Enum.Font.FredokaOne, Size = UDim2.fromOffset(900, 30), Position = UDim2.fromScale(0.5, 0.86), TextColor3 = rgb(220, 215, 240), ZIndex = 6, stroke = 2.5 })
	hint()
	waitClick(1, 8)
	return groups[#groups].r
end

---------------------------------------------------------------------------
-- the queue: one purchase after another
---------------------------------------------------------------------------
local queue, playing = {}, false
local function play(data)
	table.insert(queue, data)
	if playing then return end
	playing = true
	gui.Enabled = true
	backdrop.BackgroundTransparency = 1
	while #queue > 0 do
		local job = table.remove(queue, 1)
		local bus = Config.BusById[job.bus]
		local rs = job.results or {}
		if bus and #rs > 0 then
			local ok, err = pcall(function()
				if #rs == 1 then
					playOne(bus, rs[1], false)
				else
					local best = (#rs <= 10) and playRow(bus, rs) or playMany(bus, rs)
					-- (a Mythic or better gets the full reveal of its own)
					if best and best.tier >= 5 then playOne(bus, best, true) end
				end
			end)
			if not ok then warn("[BusReveal]", err) end
		end
	end
	tween(backdrop, 0.25, { BackgroundTransparency = 1 })
	task.wait(0.25)
	clear()
	gui.Enabled = false
	playing = false
end

Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
	if kind == "busOpen" and type(data) == "table" then task.spawn(play, data) end
end)
