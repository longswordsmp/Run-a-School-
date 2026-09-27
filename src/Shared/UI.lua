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
	-- (every heading in the big type is in the pixel type now: tomas's reference, 2026-09-27)
	if props.Font == UI.BIG and UI.PIXEL then
		t.FontFace = UI.PIXEL
		if UI.registerPixel then UI.registerPixel(t) end
		local st = t:FindFirstChildOfClass("UIStroke")
		if st then st.LineJoinMode = Enum.LineJoinMode.Miter end
	end
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

---------------------------------------------------------------------------
-- THE PIXEL STYLE (2026-09-27, from tomas's reference: a TikTok gamepass shop): a chunky pixel font
-- with a thick dark outline and a drop shadow, a rainbow title bar with a pixel checker, dark slate
-- panels, bright cards with a diagonal lattice and a darker inner border, price tags tilted into the
-- corners, big 3D icons, and chunky buttons with a lip under them so they look like you can press them.
---------------------------------------------------------------------------
UI.PIXEL = Font.new("rbxasset://fonts/families/PressStart2P.json")
UI.P = {
	panel = Color3.fromRGB(52, 56, 68), -- the dark slate body
	panelLight = Color3.fromRGB(66, 71, 86),
	edge = Color3.fromRGB(24, 22, 32), -- every outline
	text = Color3.fromRGB(236, 238, 245), -- light text on the slate
	muted = Color3.fromRGB(160, 166, 184),
	orange = Color3.fromRGB(255, 150, 40),
	red = Color3.fromRGB(235, 60, 70),
	green = Color3.fromRGB(70, 205, 80),
	blue = Color3.fromRGB(70, 150, 255),
	purple = Color3.fromRGB(160, 90, 255),
	pink = Color3.fromRGB(255, 100, 180),
	yellow = Color3.fromRGB(255, 205, 50),
	teal = Color3.fromRGB(40, 190, 180),
	gold = Color3.fromRGB(255, 190, 40),
	inset = Color3.fromRGB(74, 80, 98), -- a row set into the slate (settings rows, requirements...)
}
local P = UI.P
local EDGE = P.edge
UI.RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 90)),
	ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 150, 40)),
	ColorSequenceKeypoint.new(0.34, Color3.fromRGB(255, 220, 50)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 215, 90)),
	ColorSequenceKeypoint.new(0.67, Color3.fromRGB(60, 200, 230)),
	ColorSequenceKeypoint.new(0.84, Color3.fromRGB(80, 120, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 90, 255)),
})

local function pstroke(obj, t, color)
	local s = Instance.new("UIStroke")
	s.Thickness = t or 3
	s.Color = color or EDGE
	s.LineJoinMode = Enum.LineJoinMode.Miter -- (square corners: it's pixel type)
	s.ApplyStrokeMode = obj:IsA("TextLabel") and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end
UI.pstroke = pstroke

-- every pixel label, so they can be measured again once the font has arrived: TextScaled measures
-- with whatever font is there when the label is made, and doesn't measure again when the real one
-- loads (the titles came out 8 px tall)
local pixelLabels = setmetatable({}, { __mode = "k" })
local ptextLabels = setmetatable({}, { __mode = "k" }) -- (the ones UI.ptext made: they pick their own colours)
-- pixel type is always in capitals (the reference's is; lower case in it reads badly)
local function caps(t)
	if t.RichText then return end
	local up = t.Text:upper()
	if up ~= t.Text then t.Text = up end
end
function UI.registerPixel(t)
	pixelLabels[t] = true
	caps(t)
	t:GetPropertyChangedSignal("Text"):Connect(function() caps(t) end)
end
function UI.refreshPixel(root)
	local list = {}
	for t in pixelLabels do
		if t.Parent and (not root or t:IsDescendantOf(root)) and t.TextScaled then
			t.TextScaled = false
			table.insert(list, t)
		end
	end
	task.defer(function()
		for _, t in list do t.TextScaled = true end
	end)
end
if game:GetService("RunService"):IsClient() then
	task.spawn(function()
		local probe = Instance.new("TextLabel")
		probe.FontFace = UI.PIXEL
		probe.Text = "PIXEL"
		pcall(function() game:GetService("ContentProvider"):PreloadAsync({ probe }) end)
		-- (measured again a few times: labels made while the font was still on its way, and ones made
		-- just after, all get their real size)
		for _, wait in { 0.2, 1.3, 2.5, 4, 8 } do
			task.wait(wait)
			UI.refreshPixel()
		end
		probe:Destroy()
	end)
end

-- pixel text: the face, an outline, and a dark copy under it, down and to the right (the 3D look).
-- props: Text, Size, Position, AnchorPoint, Rotation, TextColor3, ZIndex, TextXAlignment, Name,
-- depth (px, default 3), stroke (px, default 3), max (the largest text size), gradient (ColorSequence).
-- Returns the face label; setting its Text / TextColor3 / Visible keeps the shadow in step.
function UI.ptext(parent, props)
	local z = props.ZIndex or 12
	local holder = Instance.new("Frame")
	holder.Name = props.Name or "PText"
	holder.BackgroundTransparency = 1
	holder.Size = props.Size or UDim2.fromScale(1, 1)
	holder.Position = props.Position or UDim2.new()
	holder.AnchorPoint = props.AnchorPoint or Vector2.zero
	holder.Rotation = props.Rotation or 0
	holder.LayoutOrder = props.LayoutOrder or 0
	holder.ZIndex = z
	local depth = props.depth or 3
	local function mk(color, off, zz, name)
		local t = Instance.new("TextLabel")
		t.Name = name
		t.BackgroundTransparency = 1
		t.FontFace = UI.PIXEL
		t.TextScaled = true
		t.Text = props.Text or ""
		t.TextColor3 = color
		-- (the pixel font's lines are 1.8x as tall as its letters: a label the size of its box drew
		-- letters half the box's height. It's made 1.8x taller and centred, so the letters fill the box)
		t.Size = UDim2.fromScale(1, 1.8)
		t.Position = UDim2.new(0, off, -0.4, off)
		t.ZIndex = zz
		t.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center
		t.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
		-- (never TextWrapped = false: setting it switches TextScaled off, and every label drew at 8 px)
		UI.registerPixel(t)
		ptextLabels[t] = true
		if props.max then
			-- (max: the letters' height in px. This font draws its letters at 0.55 of its text size)
			local c = Instance.new("UITextSizeConstraint")
			c.MaxTextSize = math.floor(props.max * 1.8)
			c.Parent = t
		end
		if (props.stroke or 3) > 0 then pstroke(t, props.stroke or 3) end
		t.Parent = holder
		return t
	end
	local shadow = depth > 0 and mk(EDGE, depth, z, "Shadow") or nil
	local face = mk(props.TextColor3 or Color3.new(1, 1, 1), 0, z + 1, "Face")
	if props.gradient then
		local g = Instance.new("UIGradient")
		g.Color = props.gradient
		g.Rotation = 90
		g.Parent = face
	end
	if shadow then
		face:GetPropertyChangedSignal("Text"):Connect(function() shadow.Text = face.Text end)
		face:GetPropertyChangedSignal("Visible"):Connect(function() shadow.Visible = face.Visible end)
		face:GetPropertyChangedSignal("TextTransparency"):Connect(function() shadow.TextTransparency = face.TextTransparency end)
	end
	holder.Parent = parent
	return face, holder
end

-- the textures: tiled images (the thumbnails of two free decals: a white diagonal net and a white
-- checkerboard). (Drawn from rotated frames in CanvasGroups they looked right on one panel, but a store
-- full of cards ran over the CanvasGroup texture budget and they stopped clipping: lines across the
-- whole screen.)
UI.LATTICE_IMAGE = "rbxthumb://type=Asset&id=100611400436149&w=420&h=420"
UI.CHECKER_IMAGE = "rbxthumb://type=Asset&id=15456050349&w=420&h=420"
local function tiled(frame, name, image, tile, transparency, z)
	local img = Instance.new("ImageLabel")
	img.Name = name
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.Image = image
	img.ScaleType = Enum.ScaleType.Tile
	img.TileSize = UDim2.fromOffset(tile, tile)
	img.ImageTransparency = transparency
	img.ZIndex = z or frame.ZIndex
	local r = frame:FindFirstChildOfClass("UICorner")
	if r then r:Clone().Parent = img end
	img.Parent = frame
	return img
end

-- a diagonal lattice over a frame (the cards' texture), and a scatter of little pixels (the grain)
function UI.lattice(frame, opts)
	opts = opts or {}
	local img = tiled(frame, "Lattice", UI.LATTICE_IMAGE, opts.tile or 104, opts.transparency or 0.35, opts.ZIndex)
	local rng = Random.new(opts.seed or 7)
	for _ = 1, opts.speckles or 18 do
		local d = Instance.new("Frame")
		d.Name = "Grain"
		d.BorderSizePixel = 0
		local light = rng:NextNumber() < 0.6
		d.BackgroundColor3 = light and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
		d.BackgroundTransparency = light and 0.35 or 0.7
		local px = rng:NextInteger(1, 2) * 4
		d.Size = UDim2.fromOffset(px, px)
		d.Position = UDim2.new(rng:NextNumber(0.04, 0.94), 0, rng:NextNumber(0.05, 0.92), 0)
		d.ZIndex = img.ZIndex
		d.Parent = frame
	end
	return img
end

-- a pixel checkerboard over a frame (the title bar's texture)
function UI.checker(frame, opts)
	opts = opts or {}
	return tiled(frame, "Checker", UI.CHECKER_IMAGE, opts.cell and opts.cell * 4 or 56, opts.transparency or 0.8, opts.ZIndex)
end

-- a chunky pixel button: the body sits on a darker lip and dips onto it when pressed.
-- opts: text, color, size, position, anchor, name, onClick, textSize (max), layoutOrder, zindex
-- returns { button, label, setText, setColor, setEnabled }
function UI.pbutton(parent, opts)
	local color = opts.color or P.green
	local z = opts.zindex or 14
	local LIP = opts.lip or 5
	local b = Instance.new("TextButton")
	b.Name = opts.name or "PButton"
	b.AutoButtonColor = false
	b.Text = ""
	b.BackgroundTransparency = 1
	b.Size = opts.size or UDim2.fromOffset(160, 56)
	b.Position = opts.position or UDim2.new()
	b.AnchorPoint = opts.anchor or Vector2.zero
	b.LayoutOrder = opts.layoutOrder or 0
	b.ZIndex = z
	local lip = Instance.new("Frame")
	lip.Name = "Lip"
	lip.BackgroundColor3 = darken(color, 0.45)
	lip.Size = UDim2.new(1, 0, 1, -LIP)
	lip.Position = UDim2.fromOffset(0, LIP)
	lip.ZIndex = z
	UI.corner(lip, opts.radius or 10)
	pstroke(lip, 3)
	lip.Parent = b
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundColor3 = Color3.new(1, 1, 1)
	body.Size = UDim2.new(1, 0, 1, -LIP)
	body.ZIndex = z + 1
	UI.corner(body, opts.radius or 10)
	pstroke(body, 3)
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Parent = body
	body.Parent = b
	-- the shine along the top
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.BorderSizePixel = 0
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.55
	shine.Size = UDim2.new(1, -14, 0, 5)
	shine.Position = UDim2.fromOffset(7, 5)
	shine.ZIndex = z + 2
	UI.corner(shine, 3)
	shine.Parent = body
	local label = UI.ptext(body, {
		Name = "Label", Text = opts.text or "", Size = UDim2.new(1, -18, 1, -14), Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z + 3, depth = 2, stroke = 2.5, max = opts.textSize or 30,
	})
	local function paint(c)
		grad.Color = ColorSequence.new(lighten(c, 0.28), c)
		lip.BackgroundColor3 = darken(c, 0.45)
	end
	paint(color)
	local enabled = true
	local s = scaler(b)
	b.MouseEnter:Connect(function()
		if enabled then TweenService:Create(s, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1.05 }):Play() end
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(s, TweenInfo.new(0.15), { Scale = 1 }):Play()
		body.Position = UDim2.new()
	end)
	b.MouseButton1Down:Connect(function()
		if enabled then body.Position = UDim2.fromOffset(0, LIP - 1) end
	end)
	b.MouseButton1Up:Connect(function()
		body.Position = UDim2.new()
	end)
	if opts.onClick then b.Activated:Connect(opts.onClick) end
	b.Parent = parent
	local api = { button = b, label = label, body = body }
	function api.setText(t) label.Text = t end
	function api.setColor(c) color = c paint(c) end
	function api.setEnabled(on)
		enabled = on
		b.Active = on
		paint(on and color or Color3.fromRGB(120, 124, 138))
	end
	return api
end

-- a pixel card: a darker border, the colour inside with the lattice, an outline round it all.
-- opts: color, size, position, layoutOrder, name, zindex, button (true: a TextButton, hover pops)
-- returns outer, inner
function UI.pcard(parent, opts)
	local color = opts.color or P.blue
	local z = opts.zindex or 12
	local outer = Instance.new(opts.button and "TextButton" or "Frame")
	outer.Name = opts.name or "PCard"
	if opts.button then
		outer.Text = ""
		outer.AutoButtonColor = false
	end
	outer.BackgroundColor3 = darken(color, 0.3)
	outer.Size = opts.size or UDim2.fromOffset(240, 200)
	outer.Position = opts.position or UDim2.new()
	outer.AnchorPoint = opts.anchor or Vector2.zero
	outer.LayoutOrder = opts.layoutOrder or 0
	outer.ZIndex = z
	UI.corner(outer, 16)
	pstroke(outer, 4)
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.BackgroundColor3 = Color3.new(1, 1, 1)
	inner.Size = UDim2.new(1, -12, 1, -12)
	inner.Position = UDim2.fromOffset(6, 6)
	inner.ZIndex = z + 1
	UI.corner(inner, 11)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(lighten(color, 0.14), darken(color, 0.06))
	g.Rotation = 90
	g.Parent = inner
	inner.Parent = outer
	UI.lattice(inner, { ZIndex = z + 1, seed = opts.seed, w = opts.patternW, h = opts.patternH })
	if opts.button then
		local s = scaler(outer)
		outer.MouseEnter:Connect(function() TweenService:Create(s, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1.04 }):Play() end)
		outer.MouseLeave:Connect(function() TweenService:Create(s, TweenInfo.new(0.15), { Scale = 1 }):Play() end)
		outer.MouseButton1Down:Connect(function() TweenService:Create(s, TweenInfo.new(0.08), { Scale = 0.96 }):Play() end)
		outer.MouseButton1Up:Connect(function() TweenService:Create(s, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1.04 }):Play() end)
	end
	outer.Parent = parent
	return outer, inner
end

-- a price tag tilted into a card's corner ("119R")
function UI.ptag(parent, text, corner, z)
	local left = corner ~= "right"
	return UI.ptext(parent, {
		Name = "Tag", Text = text, Size = UDim2.fromOffset(92, 26), Rotation = 34,
		Position = left and UDim2.fromOffset(-16, 70) or UDim2.new(1, -78, 0, 70),
		ZIndex = z or 16, depth = 3, stroke = 3, max = 18,
	})
end

-- a section heading on the slate ("GAMEPASSES")
function UI.pheading(parent, text, order, z)
	local f = Instance.new("Frame")
	f.Name = "Heading"
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(1, 0, 0, 34)
	f.LayoutOrder = order or 0
	f.ZIndex = z or 12
	UI.ptext(f, { Text = text, Size = UDim2.new(1, -12, 0, 22), Position = UDim2.fromOffset(6, 6), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = P.text, ZIndex = (z or 12) + 1, depth = 2, stroke = 2, max = 20 })
	f.Parent = parent
	return f
end

-- a panel in the pixel style: the slate body, the rainbow title bar with the checker, a big pixel title
-- with its shadow, an icon hanging off the top-left corner (a function(holder) that fills it), and the red
-- X. Same api as UI.panel: { frame, body, header, open, close, toggle }.
-- opts: name, title, size, icon (function), headerColor (a ColorSequence; default the rainbow)
function UI.ppanel(gui, opts)
	local frame = UI.new("Frame", {
		Name = opts.name or "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = opts.size or UDim2.fromOffset(840, 580),
		BackgroundColor3 = P.panel,
		Visible = false,
		ZIndex = 10,
		Parent = gui,
	})
	UI.corner(frame, 20)
	pstroke(frame, 5)
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(1060, 800), Parent = frame })
	-- a lighter rim just inside the outline
	local rim = UI.new("Frame", { Name = "Rim", BackgroundTransparency = 1, Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), ZIndex = 10, Parent = frame })
	UI.corner(rim, 16)
	pstroke(rim, 3, P.panelLight)
	local HEADER = 92
	local header = UI.new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, HEADER),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 11,
		Parent = frame,
	})
	UI.corner(header, 20)
	pstroke(header, 5)
	local hg = Instance.new("UIGradient")
	if typeof(opts.headerColor) == "Color3" then
		hg.Color = ColorSequence.new(lighten(opts.headerColor, 0.32), darken(opts.headerColor, 0.06))
		hg.Rotation = 90
	else
		hg.Color = opts.headerColor or UI.RAINBOW
	end
	hg.Parent = header
	UI.checker(header, { ZIndex = 11, h = HEADER + 20 })
	-- a darker band along the bottom of the bar: depth
	local band = UI.new("Frame", { Name = "Band", BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.8, Size = UDim2.new(1, -10, 0, 10), Position = UDim2.new(0, 5, 1, -14), ZIndex = 12, Parent = header })
	UI.corner(band, 4)
	local title = UI.ptext(header, {
		Name = "Title", Text = opts.title or "", Size = UDim2.new(1, -300, 0, 70), Position = UDim2.new(0.5, 10, 0.5, -2),
		AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 13, depth = 6, stroke = 5, max = 66,
	})
	if opts.icon then
		local holder = UI.new("Frame", { Name = "Icon", BackgroundTransparency = 1, Size = UDim2.fromOffset(160, 160), Position = UDim2.fromOffset(-44, -50), ZIndex = 15, Parent = frame })
		opts.icon(holder)
	end
	local body = UI.new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 1, -HEADER - 26),
		Position = UDim2.fromOffset(16, HEADER + 12),
		ZIndex = 11,
		Parent = frame,
	})
	local api = { frame = frame, body = body, header = header, title = title }
	local close = UI.pbutton(header, {
		name = "Close", text = "X", color = P.red, size = UDim2.fromOffset(62, 62),
		position = UDim2.new(1, -16, 0.5, -2), anchor = Vector2.new(1, 0.5), textSize = 34, zindex = 16, radius = 12,
		onClick = function() api.close() end,
	})
	api.closeButton = close
	function api.open()
		if frame.Visible then return end
		if UI.current and UI.current ~= api then UI.current.close() end
		UI.current = api
		frame.Visible = true
		UI.pop(frame, 0.55)
		if api.onOpen then api.onOpen() end
		UI.refreshPixel(frame)
		task.defer(UI.fixContrast, frame)
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

-- dark text left on the slate (written for the old cream panels) turns light. Walks a panel's text:
-- anything whose nearest painted background is the panel itself (or nothing) and is darker than mid
-- grey gets the light text colour. Run when a panel opens (rows added since get it too).
local fixedText = setmetatable({}, { __mode = "k" })
local function lum(c) return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B end
function UI.fixContrast(root)
	for _, d in root:GetDescendants() do
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and not ptextLabels[d] and not fixedText[d] and lum(d.TextColor3) < 0.42 then
			local a, bg = d.Parent, nil
			while a and a ~= root do
				if a:IsA("GuiObject") and not a:IsA("ScrollingFrame") and a.BackgroundTransparency < 0.5 then bg = a break end
				a = a.Parent
			end
			-- (on the slate itself, or on anything dark painted on it: the inset rows)
			local dark = bg == nil or (lum(bg.BackgroundColor3) < 0.45 and not bg:FindFirstChildOfClass("UIGradient"))
			if dark then
				fixedText[d] = true
				d.TextColor3 = P.text
			end
		end
	end
end

-- the kit's classic calls, in the pixel style (every menu uses them). The old look stays reachable as
-- UI.panelClassic / UI.buttonClassic / UI.cardClassic.
UI.panelClassic, UI.buttonClassic, UI.cardClassic = UI.panel, UI.button, UI.card
local Icons
function UI.panel(gui, opts)
	Icons = Icons or require(script.Parent:WaitForChild("Icons"))
	local size = opts.size or UDim2.fromOffset(640, 440)
	-- (the pixel title bar is 34 taller than the old one: the body keeps its room; and a touch bigger all
	-- round, the reference's panels fill the screen)
	size = UDim2.new(size.X.Scale, math.floor(size.X.Offset * 1.1), size.Y.Scale, size.Y.Offset + 34 + 40)
	local key = Icons.PANEL[opts.name or ""]
	return UI.ppanel(gui, {
		name = opts.name, title = opts.title, size = size,
		headerColor = opts.color or P.blue,
		icon = key and function(holder) Icons.view(holder, key, { zindex = 16, sway = 10 }) end or nil,
	})
end
function UI.button(parent, opts)
	local api = UI.pbutton(parent, {
		name = opts.name or "Button", text = opts.text, color = opts.color or P.green, size = opts.size,
		position = opts.position, anchor = opts.anchor, layoutOrder = opts.layoutOrder, onClick = opts.onClick,
		radius = opts.radius, zindex = opts.zindex or 1, lip = opts.lip or 4, textSize = opts.textSize or 28,
	})
	return api
end
function UI.card(parent, opts)
	local color = opts.color or UI.C.grey
	local outer, inner = UI.pcard(parent, { name = opts.name or "Card", color = color, layoutOrder = opts.layoutOrder, zindex = 12, seed = opts.layoutOrder })
	if opts.model then
		UI.viewport(inner, opts.model, {
			size = UDim2.new(1, -4, 0.6, 0),
			position = UDim2.new(0, 2, 0, 2),
			silhouette = opts.silhouette,
			portrait = opts.portrait,
			zoom = opts.portrait and 0.92 or nil,
			zindex = 14,
		})
	end
	UI.label(outer, { Name = "Title", Text = opts.title or "", Font = UI.BIG, Size = UDim2.new(1, -14, 0.17, 0), Position = UDim2.new(0, 7, 0.62, 0), ZIndex = 15, stroke = 2.5 })
	UI.label(outer, { Name = "Subtitle", Text = opts.subtitle or "", TextColor3 = opts.subtitleColor or UI.C.white, Size = UDim2.new(1, -14, 0.14, 0), Position = UDim2.new(0, 7, 0.8, 0), ZIndex = 15, stroke = 2 })
	return outer
end

-- an existing cream HUD card (the To-Do card, the chapter checklist, the quest tracker) in the pixel
-- style: the slate body, a square outline, the checker over its title bar, and its dark text turned
-- light. Call once the card's labels exist; header: its coloured title bar (optional)
function UI.pixelCard(card, header)
	card.BackgroundColor3 = P.panel
	local st = card:FindFirstChildOfClass("UIStroke")
	if st then st.LineJoinMode = Enum.LineJoinMode.Miter st.Thickness = 4 st.Color = EDGE end
	if header then UI.checker(header, { ZIndex = header.ZIndex, cell = 10, transparency = 0.82 }) end
	UI.fixContrast(card)
end

-- a scrolling column for a pixel panel's body (sections, headings, card grids stacked)
function UI.pscroll(parent, z)
	local sf = UI.new("ScrollingFrame", {
		Name = "Scroll",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 10,
		ScrollBarImageColor3 = P.panelLight,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = z or 11,
		Parent = parent,
	})
	UI.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = sf })
	local pad = UI.new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 18), Parent = sf })
	_ = pad
	return sf
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
