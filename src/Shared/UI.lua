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
	b.MouseEnter:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1.06 }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.15), { Scale = 1 }):Play()
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

	local api = { button = b, label = lbl }
	function api.setColor(c)
		grad.Color = ColorSequence.new(lighten(c, 0.35), c)
	end
	function api.setText(t)
		lbl.Text = t
	end
	function api.setEnabled(on)
		b.Active = on
		b.AutoButtonColor = false
		grad.Color = on and ColorSequence.new(lighten(color, 0.35), color) or ColorSequence.new(Color3.fromRGB(190, 190, 195), Color3.fromRGB(130, 130, 140))
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
	UI.gradient(header, lighten(color, 0.3), color)
	-- square off the header's bottom corners
	local fill = UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 1, -20),
		BackgroundColor3 = UI.C.white,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = header,
	})
	UI.gradient(fill, color, color)
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
	local api = { frame = frame, body = body, header = header }
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
	closeBtn.button.ZIndex = 20
	for _, d in closeBtn.button:GetDescendants() do
		if d:IsA("GuiObject") then d.ZIndex = 21 end
	end

	function api.open()
		if frame.Visible then return end
		if UI.current and UI.current ~= api then UI.current.close() end
		UI.current = api
		frame.Visible = true
		UI.pop(frame, 0.5)
		if api.onOpen then api.onOpen() end
	end
	function api.close()
		if UI.current == api then UI.current = nil end
		frame.Visible = false
		if api.onClose then api.onClose() end
	end
	function api.toggle()
		if frame.Visible then api.close() else api.open() end
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
	if opts.model then
		UI.viewport(card, opts.model, {
			size = UDim2.new(1, -8, 0.62, 0),
			position = UDim2.new(0, 4, 0, 4),
			silhouette = opts.silhouette,
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
		local s = math.clamp(y / 1000, 0.5, 1)
		sc.Scale = s
		root.Size = UDim2.fromScale(1 / s, 1 / s)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
	if player then player:GetAttributeChangedSignal("DebugViewportY"):Connect(fit) end
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
