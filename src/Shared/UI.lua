-- ReplicatedStorage.Shared.UI
-- Steal-a-X style UI kit: thick black strokes, rounded corners, top-light gradients, bouncy tweens.
local TweenService = game:GetService("TweenService")

local UI = {}

UI.FONT = Enum.Font.FredokaOne
UI.BIG = Enum.Font.LuckiestGuy

UI.C = {
	green = Color3.fromRGB(61, 220, 106),
	blue = Color3.fromRGB(58, 160, 255),
	red = Color3.fromRGB(255, 74, 74),
	orange = Color3.fromRGB(255, 159, 26),
	purple = Color3.fromRGB(164, 92, 255),
	pink = Color3.fromRGB(255, 105, 180),
	yellow = Color3.fromRGB(255, 214, 51),
	cream = Color3.fromRGB(255, 247, 230),
	navy = Color3.fromRGB(30, 34, 64),
	grey = Color3.fromRGB(140, 140, 150),
	ink = Color3.fromRGB(20, 16, 30),
	white = Color3.new(1, 1, 1),
}

local function lighten(c, a)
	return c:Lerp(Color3.new(1, 1, 1), a)
end
local function darken(c, a)
	return c:Lerp(Color3.new(0, 0, 0), a)
end
UI.lighten, UI.darken = lighten, darken

function UI.new(class, props, children)
	local o = Instance.new(class)
	for k, v in props or {} do
		if k ~= "Parent" then o[k] = v end
	end
	for _, c in children or {} do c.Parent = o end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end

function UI.stroke(obj, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 3
	s.Color = color or UI.C.ink
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.ApplyStrokeMode = (obj:IsA("TextLabel") or obj:IsA("TextBox")) and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end

function UI.corner(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = obj
	return c
end

function UI.gradient(obj, top, bottom, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(top, bottom)
	g.Rotation = rotation or 90
	g.Parent = obj
	return g
end

function UI.padding(obj, px)
	local p = Instance.new("UIPadding")
	local u = UDim.new(0, px)
	p.PaddingLeft, p.PaddingRight, p.PaddingTop, p.PaddingBottom = u, u, u, u
	p.Parent = obj
	return p
end

-- text with the black outline every label in this style has
function UI.label(parent, props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = UI.FONT
	t.TextScaled = true
	t.TextColor3 = UI.C.white
	local strokeT = props.stroke or 3
	for k, v in props do
		if k ~= "stroke" then t[k] = v end
	end
	if strokeT > 0 then UI.stroke(t, strokeT) end
	t.Parent = parent
	return t
end

-- a bouncy scale that hover/press tweens drive
local function scaler(obj)
	local s = obj:FindFirstChildOfClass("UIScale")
	if not s then
		s = Instance.new("UIScale")
		s.Parent = obj
	end
	return s
end

function UI.pop(obj, from)
	local s = scaler(obj)
	s.Scale = from or 0.6
	TweenService:Create(s, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

function UI.punch(obj, amount)
	local s = scaler(obj)
	s.Scale = amount or 1.12
	TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

---------------------------------------------------------------------------
-- LIFE: glows, shines and bounces for the whole UI (tomas, 2026-09-27: "our original style is good,
-- but with animations and glow effects it could be SO much better").
---------------------------------------------------------------------------
-- a soft glow round a frame: a blurred halo of its colour behind it (an image: stacked rings banded,
-- tomas: "the glow ... needs to be on point"). A child drawn under its parent (Global ZIndex guis).
-- Returns it; UI.glowTo(it, alpha) fades it (0 = off, 1 = full); opts.spread widens it (default 5).
UI.GLOW = "rbxassetid://6150493168"
function UI.glow(obj, color, opts)
	opts = opts or {}
	local img = Instance.new("ImageLabel")
	img.Name = "Glow"
	img.BackgroundTransparency = 1
	img.Image = UI.GLOW
	img.ImageColor3 = color
	img.ScaleType = Enum.ScaleType.Stretch
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.fromScale(0.5, 0.5)
	local pad = (opts.spread or 5) * 18
	img.Size = UDim2.new(1, pad, 1, pad)
	img.ZIndex = math.max(0, obj.ZIndex - 1)
	img:SetAttribute("GlowAlpha", opts.alpha or 1)
	local function apply(a)
		-- (the halo's bright middle sits under its frame: what shows is its rim, so at full it's fully on)
		img.ImageTransparency = 1 - math.clamp(a or 0, 0, 1)
	end
	apply(opts.alpha or 1)
	img:GetAttributeChangedSignal("GlowAlpha"):Connect(function() apply(img:GetAttribute("GlowAlpha")) end)
	img.Parent = obj
	return img
end
function UI.glowTo(holder, alpha, t)
	if not holder then return end
	local v = Instance.new("NumberValue")
	v.Value = holder:GetAttribute("GlowAlpha") or 0
	v.Changed:Connect(function(x) holder:SetAttribute("GlowAlpha", x) end)
	local tw = TweenService:Create(v, TweenInfo.new(t or 0.2, Enum.EasingStyle.Quad), { Value = alpha })
	tw.Completed:Connect(function() v:Destroy() end)
	tw:Play()
end

-- a shine: a bright diagonal band that sweeps across a frame now and then (the glint on shiny
-- plastic). An overlay the frame's shape carries a UIGradient; its Offset is what moves. Sweeps are
-- dealt out by one scheduler to whichever shiny things are on screen, a few a second.
local shiners = setmetatable({}, { __mode = "k" }) -- overlay -> gradient
local function onScreen(g)
	local a = g
	while a and a:IsA("GuiObject") do
		if not a.Visible then return false end
		a = a.Parent
	end
	if a and a:IsA("LayerCollector") and not a.Enabled then return false end
	return g.AbsoluteSize.X > 0
end
function UI.shine(obj, opts)
	opts = opts or {}
	local o = Instance.new("Frame")
	o.Name = "Shine"
	o.BackgroundColor3 = Color3.new(1, 1, 1)
	o.BorderSizePixel = 0
	o.Size = UDim2.fromScale(1, 1)
	o.ZIndex = opts.zindex or (obj.ZIndex + 1)
	local c = obj:FindFirstChildOfClass("UICorner")
	if c then c:Clone().Parent = o end
	local g = Instance.new("UIGradient")
	g.Rotation = 20
	-- (a crisp line of light: a bright core, soft wings either side of it)
	local peak = math.min(0.6, (opts.strength or 0.55) * 1.4)
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.36, 1),
		NumberSequenceKeypoint.new(0.45, 1 - peak * 0.3), NumberSequenceKeypoint.new(0.5, 1 - peak),
		NumberSequenceKeypoint.new(0.55, 1 - peak * 0.3), NumberSequenceKeypoint.new(0.64, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Offset = Vector2.new(-1.2, 0)
	g.Parent = o
	o.Parent = obj
	shiners[o] = g
	return o
end
function UI.sweep(overlay, t)
	local g = shiners[overlay]
	if not g then return end
	g.Offset = Vector2.new(-1.2, 0)
	TweenService:Create(g, TweenInfo.new(t or 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Offset = Vector2.new(1.2, 0) }):Play()
end
if game:GetService("RunService"):IsClient() then
	task.spawn(function()
		-- (tomas: subtler, and less often: one glint every couple of seconds, whatever is on screen)
		while true do
			task.wait(2.2 + math.random() * 1.5)
			local live = {}
			for o in shiners do
				if o.Parent and onScreen(o) then table.insert(live, o) end
			end
			if #live > 0 then UI.sweep(live[math.random(#live)], 0.65) end
		end
	end)
end

-- a sunburst: bars of light turning slowly behind something (a prize, a 3D icon). size in px
local bursts = setmetatable({}, { __mode = "k" })
function UI.burst(parent, color, size, opts)
	opts = opts or {}
	local holder = Instance.new("Frame")
	holder.Name = "Burst"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = opts.position or UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromOffset(size, size)
	holder.ZIndex = opts.zindex or parent.ZIndex
	for k = 0, (opts.rays or 8) - 1 do
		local ray = Instance.new("Frame")
		ray.Name = "Ray"
		ray.BorderSizePixel = 0
		ray.BackgroundColor3 = color
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position = UDim2.fromScale(0.5, 0.5)
		ray.Size = UDim2.new(1, 0, 0, math.max(6, size * 0.11))
		ray.Rotation = k * 180 / (opts.rays or 8)
		ray.ZIndex = holder.ZIndex
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, opts.edge or 0.75),
			NumberSequenceKeypoint.new(0.5, opts.middle or 0.35), NumberSequenceKeypoint.new(0.7, opts.edge or 0.75),
			NumberSequenceKeypoint.new(1, 1),
		})
		g.Parent = ray
		ray.Parent = holder
	end
	-- a soft round glow in the middle
	local core = Instance.new("Frame")
	core.Name = "Core"
	core.BorderSizePixel = 0
	core.BackgroundColor3 = color
	core.BackgroundTransparency = opts.coreTransparency or 0.55
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.Position = UDim2.fromScale(0.5, 0.5)
	core.Size = UDim2.fromScale(0.5, 0.5)
	core.ZIndex = holder.ZIndex
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(1, 0)
	cc.Parent = core
	core.Parent = holder
	holder.Parent = parent
	bursts[holder] = opts.speed or 18 -- degrees a second
	return holder
end
if game:GetService("RunService"):IsClient() then
	local acc = 0
	game:GetService("RunService").RenderStepped:Connect(function(dt)
		acc += dt
		if acc < 1 / 30 then return end
		local step = acc
		acc = 0
		for h, speed in bursts do
			if h.Parent then
				if h.Visible and h.AbsoluteSize.X > 0 then h.Rotation = (h.Rotation + speed * step) % 360 end
			else
				bursts[h] = nil
			end
		end
	end)
end

-- a gentle pulse: a frame's glow (or its UIScale) breathing in and out forever
function UI.pulse(holder, lo, hi, period)
	task.spawn(function()
		local t0 = os.clock() + math.random() * 2
		while holder.Parent do
			local a = lo + (hi - lo) * (0.5 + 0.5 * math.sin((os.clock() - t0) * math.pi * 2 / (period or 1.8)))
			holder:SetAttribute("GlowAlpha", a)
			task.wait(1 / 20)
		end
	end)
end

-- the reference's diagonal lattice, laid lightly over a frame (a tiled image: a white net)
UI.LATTICE = "rbxthumb://type=Asset&id=100611400436149&w=420&h=420"
function UI.lattice(frame, opts)
	opts = opts or {}
	local img = Instance.new("ImageLabel")
	img.Name = "Lattice"
	img.BackgroundTransparency = 1
	img.Image = UI.LATTICE
	img.ScaleType = Enum.ScaleType.Tile
	img.TileSize = UDim2.fromOffset(opts.tile or 46, opts.tile or 46)
	img.ImageTransparency = opts.transparency or 0.78
	img.Size = UDim2.fromScale(1, 1)
	img.ZIndex = opts.zindex or frame.ZIndex
	local c = frame:FindFirstChildOfClass("UICorner")
	if c then c:Clone().Parent = img end
	img.Parent = frame
	return img
end

-- the classic Roblox stud texture behind the UI (tomas: "super popular for games with high player
-- counts"): a tiled image, strong on the colours, faint on the cream
UI.STUDS = "rbxthumb://type=Asset&id=15910695917&w=420&h=420"
-- one stud size everywhere (the texture is 4 x 4 studs a tile: 18 px studs), so every surface reads as
-- the same plastic (tomas, 2026-09-27: the buttons had studs the rest of the UI didn't)
UI.STUD_TILE = 72
-- how strong, by what it's on: the cream insides of windows faint, colours stronger, typing boxes and
-- speech faintest (the words on them come first)
UI.STUD = { panel = 0.84, header = 0.66, card = 0.72, button = 0.72, chip = 0.74, row = 0.8, hud = 0.8, textbox = 0.88, dialogue = 0.86, bar = 0.8 }
function UI.studs(frame, opts)
	opts = opts or {}
	-- (a list or grid inside would lay the texture out as one of its items, shoving the rest along)
	if frame:FindFirstChildWhichIsA("UIGridStyleLayout") then
		warn("[UI.studs] " .. frame:GetFullName() .. " lays out its children: no studs on it")
		return nil
	end
	local img = Instance.new("ImageLabel")
	img.Name = "Studs"
	img.BackgroundTransparency = 1
	img.Image = UI.STUDS
	img.ScaleType = Enum.ScaleType.Tile
	img.TileSize = UDim2.fromOffset(opts.tile or UI.STUD_TILE, opts.tile or UI.STUD_TILE)
	img.ImageTransparency = opts.transparency or 0.72
	img.Size = UDim2.fromScale(1, 1)
	-- (a padding insets children: undo it so the texture still covers the whole frame)
	local pad = frame:FindFirstChildOfClass("UIPadding")
	if pad then
		local l, r, t, b = pad.PaddingLeft.Offset, pad.PaddingRight.Offset, pad.PaddingTop.Offset, pad.PaddingBottom.Offset
		img.Position = UDim2.fromOffset(-l, -t)
		img.Size = UDim2.new(1, l + r, 1, t + b)
	end
	img.ZIndex = opts.zindex or frame.ZIndex
	local c = frame:FindFirstChildOfClass("UICorner")
	if c then c:Clone().Parent = img end
	-- (it fades with its frame: a toast fading out doesn't leave its studs hanging in the air)
	local base = img.ImageTransparency
	local function follow()
		img.ImageTransparency = 1 - (1 - base) * (1 - frame.BackgroundTransparency)
	end
	follow()
	frame:GetPropertyChangedSignal("BackgroundTransparency"):Connect(follow)
	img.Parent = frame
	return img
end

-- does this gui draw children under their parents (Global ZIndex)? The lip under a button and the
-- glow round it are children drawn underneath; in a Sibling gui they'd cover it instead
local function globalZ(obj)
	local g = obj:FindFirstAncestorWhichIsA("LayerCollector")
	return g ~= nil and g:IsA("ScreenGui") and g.ZIndexBehavior == Enum.ZIndexBehavior.Global
end
UI.globalZ = globalZ

-- studs under something that carries its own text (a typing box, a label with a fill): a child laid
-- over it would cover the words, so its fill (and gradient) moves onto a backing child drawn BENEATH it
-- (Global guis draw a lower-ZIndex child under its parent), the studs go on that, the words stay on
-- top. Needs a Global gui and the element parented into it.
function UI.studsUnderText(obj, opts)
	opts = opts or {}
	if not globalZ(obj) then
		warn("[UI.studsUnderText] " .. obj:GetFullName() .. " isn't in a Global gui: no studs on it")
		return nil
	end
	local back = Instance.new("Frame")
	back.Name = "Back"
	back.BorderSizePixel = 0
	back.BackgroundColor3 = obj.BackgroundColor3
	back.BackgroundTransparency = obj.BackgroundTransparency
	back.Size = UDim2.fromScale(1, 1)
	local pad = obj:FindFirstChildOfClass("UIPadding")
	if pad then
		local l, r, t, b = pad.PaddingLeft.Offset, pad.PaddingRight.Offset, pad.PaddingTop.Offset, pad.PaddingBottom.Offset
		back.Position = UDim2.fromOffset(-l, -t)
		back.Size = UDim2.new(1, l + r, 1, t + b)
	end
	back.ZIndex = math.max(0, obj.ZIndex - 1)
	local c = obj:FindFirstChildOfClass("UICorner")
	if c then c:Clone().Parent = back end
	local g = obj:FindFirstChildOfClass("UIGradient")
	if g then g:Clone().Parent = back end
	back.Parent = obj
	obj.BackgroundTransparency = 1
	-- (the backing keeps up if the element's fill colour changes later)
	obj:GetPropertyChangedSignal("BackgroundColor3"):Connect(function() back.BackgroundColor3 = obj.BackgroundColor3 end)
	UI.studs(back, { zindex = back.ZIndex, transparency = opts.transparency or UI.STUD.textbox, tile = opts.tile })
	return back
end

-- chunky gradient button
-- opts: text, color, size, position, anchor, font, onClick, textColor, radius, icon, layoutOrder
function UI.button(parent, opts)
	local color = opts.color or UI.C.green
	local b = Instance.new("TextButton")
	b.Name = opts.name or "Button"
	b.AutoButtonColor = false
	b.Text = ""
	b.Size = opts.size or UDim2.fromOffset(160, 50)
	b.Position = opts.position or UDim2.new()
	b.AnchorPoint = opts.anchor or Vector2.zero
	b.BackgroundColor3 = UI.C.white
	b.LayoutOrder = opts.layoutOrder or 0
	UI.corner(b, opts.radius or 12)
	UI.stroke(b, opts.strokeThickness or 3)
	local grad = UI.gradient(b, lighten(color, 0.35), color)
	-- glossy top highlight
	local shine = UI.new("Frame", {
		Name = "Shine",
		BackgroundColor3 = UI.C.white,
		BackgroundTransparency = 0.75,
		Size = UDim2.new(1, -10, 0.36, 0),
		Position = UDim2.new(0, 5, 0, 4),
		ZIndex = 2,
		Parent = b,
	})
	UI.corner(shine, (opts.radius or 12) - 4)
	UI.studs(b, { zindex = 2, transparency = UI.STUD.button })
	local shineOverlay = UI.shine(b, { zindex = 2, strength = 0.22 })
	shineOverlay.Name = "Glint"
	local lbl = UI.label(b, {
		Name = "Label",
		Size = UDim2.new(1, -16, 1, -12),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Text = opts.text or "",
		Font = opts.font or UI.FONT,
		TextColor3 = opts.textColor or UI.C.white,
		ZIndex = 3,
		stroke = opts.textStroke or 2.5,
	})
	local s = scaler(b)
	-- the lip (a darker edge under the button: it looks like you can press it) and the hover glow
	local lip, glow
	-- (the lip and the glow stay one and two layers under the button whatever sets the ZIndexes:
	-- several menus set a button's whole tree to one layer, which put the lip over the button)
	local function keepUnder()
		local z = b.ZIndex
		if lip and lip.ZIndex ~= math.max(0, z - 1) then lip.ZIndex = math.max(0, z - 1) end
		if glow then
			local gz = math.max(0, z - 2)
			if glow.ZIndex ~= gz then glow.ZIndex = gz end
			for _, r in glow:GetChildren() do
				if r:IsA("GuiObject") and r.ZIndex ~= gz then r.ZIndex = gz end
			end
		end
	end
	local function dress()
		if lip or not globalZ(b) then return end
		lip = Instance.new("Frame")
		lip.Name = "Lip"
		lip.BackgroundColor3 = darken(color, 0.45)
		lip.Size = UDim2.fromScale(1, 1)
		lip.Position = UDim2.fromOffset(0, 4)
		lip.ZIndex = math.max(0, b.ZIndex - 1)
		UI.corner(lip, opts.radius or 12)
		UI.stroke(lip, opts.strokeThickness or 3)
		lip:GetPropertyChangedSignal("ZIndex"):Connect(keepUnder)
		lip.Parent = b
	end
	b.AncestryChanged:Connect(dress)
	b:GetPropertyChangedSignal("ZIndex"):Connect(keepUnder)
	b.MouseEnter:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1.06 }):Play()
		if b.Active and globalZ(b) then
			if not glow then
				glow = UI.glow(b, lighten(color, 0.25), { alpha = 0, spread = 4 })
				glow:GetPropertyChangedSignal("ZIndex"):Connect(keepUnder)
				keepUnder()
			end
			UI.glowTo(glow, 1, 0.15)
			UI.sweep(shineOverlay, 0.4)
		end
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.15), { Scale = 1 }):Play()
		if glow then UI.glowTo(glow, 0, 0.2) end
	end)
	b.MouseButton1Down:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.08), { Scale = 0.92 }):Play()
	end)
	b.MouseButton1Up:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1.06 }):Play()
	end)
	if opts.onClick then
		b.Activated:Connect(opts.onClick)
	end
	b.Parent = parent
	dress()

	local api = { button = b, label = lbl }
	function api.setColor(c)
		grad.Color = ColorSequence.new(lighten(c, 0.35), c)
		if lip then lip.BackgroundColor3 = darken(c, 0.45) end
	end
	function api.setText(t)
		lbl.Text = t
	end
	function api.setEnabled(on)
		b.Active = on
		b.AutoButtonColor = false
		grad.Color = on and ColorSequence.new(lighten(color, 0.35), color) or ColorSequence.new(Color3.fromRGB(190, 190, 195), Color3.fromRGB(130, 130, 140))
		if lip then lip.BackgroundColor3 = on and darken(color, 0.45) or Color3.fromRGB(90, 90, 100) end
	end
	return api
end

-- viewport that frames a model and spins it slowly
function UI.viewport(parent, model, opts)
	opts = opts or {}
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Viewport"
	vp.BackgroundTransparency = 1
	vp.Size = opts.size or UDim2.fromScale(1, 1)
	vp.Position = opts.position or UDim2.new()
	vp.AnchorPoint = opts.anchor or Vector2.zero
	vp.Ambient = Color3.fromRGB(200, 200, 200)
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.LightDirection = Vector3.new(-1, -1, -1)
	vp.ZIndex = opts.zindex or 2
	local world = Instance.new("WorldModel")
	world.Parent = vp
	local m = model:Clone()
	m:PivotTo(CFrame.new())
	m.Parent = world
	local cf, size = m:GetBoundingBox()
	-- a rig is framed by its body, not its whole bounding box (a prop held out, a pet at its feet
	-- or a glow around it made the kid a speck in the middle of the photo); portrait = head and
	-- shoulders, like a school photo
	local head = m:FindFirstChild("Head")
	local lower = m:FindFirstChild("LowerTorso")
	if head and lower and m:FindFirstChildOfClass("Humanoid") then
		local top = head.Position.Y + head.Size.Y / 2 + 0.25
		local bottom
		if opts.portrait then
			local upper = m:FindFirstChild("UpperTorso")
			bottom = upper and (upper.Position.Y - upper.Size.Y * 0.35) or lower.Position.Y
		else
			local foot = m:FindFirstChild("LeftFoot") or m:FindFirstChild("RightFoot")
			bottom = foot and (foot.Position.Y - foot.Size.Y / 2 - 0.1) or (lower.Position.Y - 3)
		end
		local h = top - bottom
		cf = CFrame.new(head.Position.X, bottom + h / 2, head.Position.Z)
		size = Vector3.new(h * 0.8, h, 1.5)
	end
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	local dist = math.max(size.X, size.Y) / (2 * math.tan(math.rad(20))) * (opts.zoom or 1.05)
	-- look at the front of the model (rigs face -Z)
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, size.Y * 0.05, -dist - size.Z / 2), cf.Position)
	cam.Parent = vp
	vp.CurrentCamera = cam
	vp.Parent = parent
	if opts.silhouette then
		vp.ImageColor3 = Color3.new(0, 0, 0)
		vp.ImageTransparency = 0.35
	end
	return vp, m
end

-- centred panel with a ribbon header and a red close button
-- opts: title, color, size; returns { frame, body, open, close, isOpen }
function UI.panel(gui, opts)
	local color = opts.color or UI.C.blue
	local frame = UI.new("Frame", {
		Name = opts.name or "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = opts.size or UDim2.fromOffset(640, 440),
		BackgroundColor3 = UI.C.cream,
		Visible = false,
		ZIndex = 10,
		Parent = gui,
	})
	UI.corner(frame, 18)
	UI.stroke(frame, 4)
	UI.studs(frame, { zindex = 10, transparency = UI.STUD.panel })
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(900, 640), Parent = frame })
	local header = UI.new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundColor3 = UI.C.white,
		ZIndex = 11,
		Parent = frame,
	})
	UI.corner(header, 18)
	UI.stroke(header, 4)
	local headerGrad = UI.gradient(header, lighten(color, 0.3), color)
	-- square off the header's bottom corners
	local fill = UI.new("Frame", {
		Name = "Fill",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 1, -20),
		BackgroundColor3 = UI.C.white,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = header,
	})
	local fillGrad = UI.gradient(fill, color, color)
	UI.studs(header, { zindex = 11, transparency = UI.STUD.header })
	local headerShine = UI.shine(header, { zindex = 12, strength = 0.18 })
	-- the panel's 3D icon hanging off the title bar's corner (Shared/Icons)
	local okIcons, Icons = pcall(function() return require(script.Parent:WaitForChild("Icons", 5)) end)
	local iconKey = okIcons and Icons and Icons.PANEL and Icons.PANEL[opts.name or ""]
	if iconKey then
		local holder = UI.new("Frame", { Name = "Icon", BackgroundTransparency = 1, Size = UDim2.fromOffset(96, 96), Position = UDim2.fromOffset(-26, -32), ZIndex = 22, Parent = frame })
		Icons.view(holder, iconKey, { zindex = 22, sway = 10 })
	end
	UI.label(header, {
		Name = "Title",
		Text = opts.title or "",
		Font = UI.BIG,
		Size = UDim2.new(1, -140, 0, 40),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 12,
		stroke = 3,
	})
	local body = UI.new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -28, 1, -82),
		Position = UDim2.new(0, 14, 0, 70),
		ZIndex = 11,
		Parent = frame,
	})
	-- (headerGrad and fillGrad colour the title bar, for a panel that wants to dress it up)
	local api = { frame = frame, body = body, header = header, headerGrad = headerGrad, fillGrad = fillGrad }
	local closeBtn = UI.button(frame, {
		name = "Close",
		text = "X",
		color = UI.C.red,
		size = UDim2.fromOffset(52, 52),
		position = UDim2.new(1, 14, 0, -14),
		anchor = Vector2.new(1, 0),
		font = UI.BIG,
		radius = 14,
		onClick = function()
			api.close()
		end,
	})
	local shift = 20 - closeBtn.button.ZIndex
	closeBtn.button.ZIndex = 20
	for _, d in closeBtn.button:GetDescendants() do
		if d:IsA("GuiObject") and d.Name ~= "Lip" and d.Name ~= "Glow" and d.Name ~= "GlowRing" then d.ZIndex += shift end
	end

	local closing = 0
	function api.open()
		if frame.Visible and closing == 0 then return end
		closing = 0
		if UI.current and UI.current ~= api then UI.current.close() end
		UI.current = api
		frame.Visible = true
		UI.pop(frame, 0.55)
		task.delay(0.25, function() if frame.Visible then UI.sweep(headerShine, 0.6) end end)
		if api.onOpen then api.onOpen() end
	end
	function api.close()
		if UI.current == api then UI.current = nil end
		if api.onClose then api.onClose() end
		-- (a quick shrink, then gone)
		closing += 1
		local mine = closing
		local sc = scaler(frame)
		TweenService:Create(sc, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 }):Play()
		task.delay(0.1, function()
			if closing == mine then
				frame.Visible = false
				sc.Scale = 1
				closing = 0
			end
		end)
	end
	function api.toggle()
		if frame.Visible and closing == 0 then api.close() else api.open() end
	end
	return api
end

-- scrolling grid for cards
function UI.grid(parent, cellSize, padding)
	local sf = UI.new("ScrollingFrame", {
		Name = "Grid",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = UI.C.ink,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 11,
		Parent = parent,
	})
	UI.new("UIGridLayout", {
		CellSize = cellSize or UDim2.fromOffset(130, 170),
		CellPadding = padding or UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = sf,
	})
	UI.padding(sf, 6)
	return sf
end

-- rarity-coloured card: gradient background, title, subtitle, optional viewport
function UI.card(parent, opts)
	local color = opts.color or UI.C.grey
	local card = UI.new("Frame", {
		Name = opts.name or "Card",
		BackgroundColor3 = UI.C.white,
		LayoutOrder = opts.layoutOrder or 0,
		ZIndex = 12,
		Parent = parent,
	})
	UI.corner(card, 14)
	UI.stroke(card, 3)
	UI.gradient(card, lighten(color, 0.45), darken(color, 0.15))
	UI.studs(card, { zindex = 12, transparency = UI.STUD.card })
	if opts.model then
		UI.viewport(card, opts.model, {
			size = UDim2.new(1, -8, 0.62, 0),
			position = UDim2.new(0, 4, 0, 4),
			silhouette = opts.silhouette,
			portrait = opts.portrait,
			zoom = opts.portrait and 0.92 or nil,
			zindex = 13,
		})
	end
	UI.label(card, {
		Name = "Title",
		Text = opts.title or "",
		Size = UDim2.new(1, -8, 0.16, 0),
		Position = UDim2.new(0, 4, 0.63, 0),
		ZIndex = 14,
		stroke = 2,
	})
	UI.label(card, {
		Name = "Subtitle",
		Text = opts.subtitle or "",
		TextColor3 = opts.subtitleColor or UI.C.white,
		Size = UDim2.new(1, -8, 0.13, 0),
		Position = UDim2.new(0, 4, 0.8, 0),
		ZIndex = 14,
		stroke = 2,
	})
	return card
end

-- One scale for a whole ScreenGui, so the game fits a phone. Everything the script puts in the gui
-- is moved into a root frame that is 1/s the size of the screen and scaled by s: edge-anchored
-- layouts stay on their edges while everything shrinks on short screens (s = height / 1000,
-- between 0.5 and 1; desktops stay 1:1). Returns the root and its UIScale.
-- A player attribute DebugViewportY pretends the screen is that tall (Studio layout checks).
function UI.autoScale(gui)
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	local sc = Instance.new("UIScale")
	sc.Parent = root
	root.Parent = gui
	local player = game:GetService("Players").LocalPlayer
	local function fit()
		local cam = workspace.CurrentCamera
		local y = (player and player:GetAttribute("DebugViewportY")) or (cam and cam.ViewportSize.Y) or 1000
		-- a phone player gets a bigger UI (the loading screen's device choice)
		local mobile = player and player:GetAttribute("Device") == "mobile"
		local s = mobile and math.clamp(y / 780, 0.6, 1.1) or math.clamp(y / 1000, 0.5, 1)
		sc.Scale = s
		root.Size = UDim2.fromScale(1 / s, 1 / s)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
	if player then
		player:GetAttributeChangedSignal("DebugViewportY"):Connect(fit)
		player:GetAttributeChangedSignal("Device"):Connect(fit)
	end
	local function adopt(c)
		if c ~= root and c:IsA("GuiObject") and c.Parent == gui then c.Parent = root end
	end
	for _, c in gui:GetChildren() do adopt(c) end
	gui.ChildAdded:Connect(function(c)
		task.defer(adopt, c)
	end)
	return root, sc
end

return UI
