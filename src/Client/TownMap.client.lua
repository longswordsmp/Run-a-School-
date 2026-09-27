-- StarterPlayer.StarterPlayerScripts.TownMap
-- The town map: press M (or Tab), or tap the map button above the eye, bottom right. It is the town
-- itself seen from straight above: every part the server finds from overhead (roofs, roads, lawns,
-- tree tops, the fountain...: MapPlan) drawn as a flat shape in its real colour, so the map shows the
-- real buildings where they are. (Flat 2D shapes, drawn once: it used to be the parts themselves in a
-- 3D ViewportFrame, which took the frame rate down to about 1 while it was open.) On top of it:
--   your quest     a pulsing star where the guide points (Quests.client shares GuideTarget)
--   people         Mr. Wobblesworth, Janitor Stan, Hall Monitor Hector ("!" on whoever has a mission
--                  for you), other players
--   names          the places, and the areas (a lock on the ones you haven't opened)
--   you            an arrow pointing the way the camera looks
-- Mouse wheel (or + / -) zooms, drag to pan, the target button re-centres on you. -Z is up.
-- (The schools are copied again when they change: MapPlan re-scans them after a rebuild.)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Config = require(Shared:WaitForChild("Config"))

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local MIN_X, MAX_X, MIN_Z, MAX_Z = -820, 820, -580, 580
local W, H = 1000, 680
local WW, HH = MAX_X - MIN_X, MAX_Z - MIN_Z -- the town's size in studs

local gui = UI.new("ScreenGui", {
	Name = "TownMap",
	ResetOnSpawn = false,
	DisplayOrder = 40,
	IgnoreGuiInset = true,
	Enabled = false,
	Parent = player:WaitForChild("PlayerGui"),
})
local dim = UI.new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = rgb(10, 12, 20), BackgroundTransparency = 0.35, Size = UDim2.fromScale(1, 1), Parent = gui })
local holder = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.52),
	Size = UDim2.fromOffset(W + 24, H + 76),
	BackgroundColor3 = rgb(255, 244, 222),
	-- (it takes its own clicks: a drag on the map fell through to the dark backdrop, which closes it)
	Active = true,
	Parent = gui,
})
UI.corner(holder, 22)
UI.stroke(holder, 4)
local holderScale = Instance.new("UIScale")
holderScale.Parent = holder
local function fit()
	local vp = workspace.CurrentCamera.ViewportSize
	holderScale.Scale = math.min(1, (vp.X - 40) / (W + 24), (vp.Y - 40) / (H + 76))
end
fit()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

UI.label(holder, { Text = "\u{1F5FA}\u{FE0F} RECESS ROW", Font = UI.BIG, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.4, 0, 0, 40), Position = UDim2.fromOffset(20, 10), TextColor3 = UI.C.navy, stroke = 0 })
UI.label(holder, { Text = "scroll to zoom \u{2022} drag to move \u{2022} M to close", TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0.45, 0, 0, 26), Position = UDim2.new(0.55, -190, 0, 18), TextColor3 = rgb(110, 100, 120), stroke = 0 })

local map = UI.new("Frame", {
	Position = UDim2.fromOffset(12, 60),
	Size = UDim2.fromOffset(W, H),
	BackgroundColor3 = rgb(104, 180, 84),
	ClipsDescendants = true,
	Parent = holder,
})
UI.corner(map, 16)
-- the canvas: the whole town, one pixel per stud at 1:1; zoom and pan move and size this one frame
-- (its shapes are placed in fractions of it, so they follow on their own)
local canvas = UI.new("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(WW, HH),
	ZIndex = 1,
	Parent = map,
})
local overlay = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = map })
local loading = UI.label(map, { Text = "Drawing the map...", Font = UI.BIG, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromScale(0, 0.45), ZIndex = 9, stroke = 3, Visible = false })

---------------------------------------------------------------------------
-- the view: where the camera hangs over the town
---------------------------------------------------------------------------
local center = Vector3.new(0, 0, 0)
local span = 460 -- studs of town across the map's width
local follow = true
local lastView
local function applyView()
	-- (only when it moved: resizing the canvas re-lays out every shape on it)
	local s = W / span
	local x, y = math.floor(W / 2 - (center.X - MIN_X) * s + 0.5), math.floor(H / 2 - (center.Z - MIN_Z) * s + 0.5)
	local key = x .. "," .. y .. "," .. span
	if key == lastView then return end
	lastView = key
	canvas.Size = UDim2.fromOffset(WW * s, HH * s)
	canvas.Position = UDim2.fromOffset(x, y)
end
-- world point -> map pixel (straight down: -Z up, +X right)
local function project(p)
	local s = W / span
	return W / 2 + (p.X - center.X) * s, H / 2 + (p.Z - center.Z) * s
end

---------------------------------------------------------------------------
-- the town, as seen from above: the server's footprints (MapPlan: ReplicatedStorage.MapPlan, not
-- streamed, so the whole town is there however far away you are), each drawn once as a flat shape
---------------------------------------------------------------------------
local function readPlan(f)
	local n = f:GetAttribute("Chunks") or 0
	local parts = {}
	for i = 1, n do
		local v = f:FindFirstChild(tostring(i))
		if not v then return nil end
		parts[i] = v.Value
	end
	local ok, list = pcall(HttpService.JSONDecode, HttpService, table.concat(parts))
	return ok and list or nil
end
-- (lowest first, as the server sorted them: roofs over lawns; a tall thing a layer up as well)
local function drawShapes(list, into)
	for _, fp in list do
		local x, z, w, d, turn, color, round, top = fp[1], fp[2], fp[3], fp[4], fp[5], fp[6], fp[7], fp[8]
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale((x - MIN_X) / WW, (z - MIN_Z) / HH)
		f.Size = UDim2.fromScale(math.max(w, 0.6) / WW, math.max(d, 0.6) / HH)
		f.Rotation = turn
		f.BackgroundColor3 = Color3.fromRGB(color // 65536 % 256, color // 256 % 256, color % 256)
		f.ZIndex = top > 8 and 3 or (top > 1.5 and 2 or 1)
		if round == 1 then
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0.5, 0)
			c.Parent = f
		end
		f.Parent = into
	end
end
local townLayer, schoolsLayer, schoolsVersion
local function layer(name)
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromScale(1, 1)
	f.Parent = canvas
	return f
end
local function draw()
	local plan = ReplicatedStorage:FindFirstChild("MapPlan")
	local town = plan and plan:FindFirstChild("Town")
	local schools = plan and plan:FindFirstChild("Schools")
	loading.Visible = town == nil and townLayer == nil
	if town and not townLayer then
		local list = readPlan(town)
		if list then
			townLayer = layer("Town")
			drawShapes(list, townLayer)
		end
	end
	local v = plan and plan:GetAttribute("SchoolsVersion")
	if schools and v ~= schoolsVersion then
		local list = readPlan(schools)
		if list then
			schoolsVersion = v
			if schoolsLayer then schoolsLayer:Destroy() end
			schoolsLayer = layer("Schools")
			drawShapes(list, schoolsLayer)
		end
	end
end

---------------------------------------------------------------------------
-- the overlay: names, people, your quest, you
---------------------------------------------------------------------------
local function tag(text, color, size)
	return UI.label(overlay, { Text = text, Font = UI.BIG, TextScaled = false, TextSize = size or 15, TextColor3 = color or rgb(255, 255, 255), Size = UDim2.fromOffset(220, 20), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 6, stroke = 2.5 })
end
local function pin(icon, color, size)
	size = size or 28
	local f = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(size, size), BackgroundColor3 = color or UI.C.white, ZIndex = 7, Parent = overlay })
	UI.corner(f, size / 2)
	UI.stroke(f, 2.5)
	UI.label(f, { Text = icon, Size = UDim2.fromScale(0.78, 0.78), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 7, stroke = 0 })
	return f
end
local function put(g, pos, dy)
	if not pos then g.Visible = false return end
	local x, y = project(pos)
	g.Position = UDim2.fromOffset(x, y + (dy or 0))
	g.Visible = x > -60 and x < W + 60 and y > -30 and y < H + 30
end

local names = {} -- { label, pos }
local function nameAt(text, pos, color, size)
	if pos then table.insert(names, { tag(text, color, size), pos }) end
end
local areaTags = {}
local builtOverlay = false
local function buildOverlay()
	if builtOverlay then return end
	builtOverlay = true
	-- (Vex Prep and the Lab are named as places: no second label)
	for _, a in Config.Areas do
		if a.id ~= "Lair" and a.id ~= "VexPrep" and a.id ~= "Lab" then
			local b = a.box
			local t = tag("", rgb(255, 245, 210), 18)
			local pos = Vector3.new((b.x0 + b.x1) / 2, 0, (b.z0 + b.z1) / 2)
			areaTags[a.id] = { label = t, pos = pos, base = (a.icon or "") .. " " .. a.name:gsub("^the ", ""):upper() }
		end
	end
	local function lm(n)
		local l = workspace.Map:FindFirstChild("Landmarks")
		local m = l and l:FindFirstChild(n)
		-- (MapAt, set by whoever built it, beats the pivot: a streamed model's pivot on this client is
		-- the middle of whatever parts have arrived, which put Recess Commons' name over the next plot)
		return m and (m:GetAttribute("MapAt") or m:GetPivot().Position)
	end
	local function box(n)
		local m = workspace:FindFirstChild(n) or workspace.Map:FindFirstChild(n)
		return m and m:IsA("Model") and (m:GetBoundingBox()).Position or nil
	end
	nameAt("Hub Fountain", lm("HubFountain"))
	nameAt("VexCorp Factory", box("VexFactory"), rgb(225, 190, 255))
	nameAt("Confiscation Closet", lm("ConfiscationCloset"))
	nameAt("Recess Commons", lm("RecessCommons"))
	nameAt("District Office", lm("DistrictOffice"))
	nameAt("Sugar Shack", lm("SugarShack"), rgb(255, 190, 225))
	nameAt("Bus Stop", box("SchoolBus"), rgb(255, 230, 120))
	nameAt("Home Bus", box("HomeBus"), rgb(255, 230, 120))
	nameAt("Detention", box("Detention"), rgb(255, 150, 150))
	nameAt("Vex Prep Academy", box("VexPrep"), rgb(225, 190, 255))
	nameAt("Mutation Lab", box("VexLab"), rgb(170, 255, 200))
	local town = workspace:FindFirstChild("Town")
	if town and town:FindFirstChild("VexCorpHQ") then nameAt("VexCorp HQ", Vector3.new(690, 0, 0), rgb(225, 190, 255)) end
end

local npcPins = {}
for _, spec in { { "Wobblesworth", "\u{1F474}" }, { "JanitorStan", "\u{1F9F9}" }, { "Hector", "\u{1F4DB}" } } do
	local f = pin(spec[2], rgb(255, 250, 235), 26)
	local bang = UI.label(f, { Text = "!", Font = UI.BIG, TextColor3 = UI.C.white, Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, 2, 0, -8), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.orange, BackgroundTransparency = 0, ZIndex = 8, stroke = 2 })
	UI.corner(bang, 9)
	npcPins[spec[1]] = { frame = f, bang = bang }
end
local questPin = pin("\u{2B50}", rgb(255, 214, 60), 34)
local questTag = tag("", rgb(255, 230, 120), 16)
local yourTag = tag("\u{2B50} YOUR SCHOOL", rgb(255, 230, 120), 17)
local playerDots = {}
local me = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, ZIndex = 9, Parent = overlay })
UI.label(me, { Text = "\u{25B2}", TextScaled = true, Size = UDim2.fromScale(1, 1), TextColor3 = rgb(255, 70, 70), ZIndex = 9, stroke = 3 })

local t0 = 0
local function refresh(dt)
	t0 += dt
	if math.floor(t0) ~= math.floor(t0 - dt) then draw() end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if follow and root then center = Vector3.new(root.Position.X, 0, root.Position.Z) end
	center = Vector3.new(math.clamp(center.X, MIN_X, MAX_X), 0, math.clamp(center.Z, MIN_Z, MAX_Z))
	applyView()
	for id, a in areaTags do
		local open = player:GetAttribute("Area_" .. id) == true
		a.label.Text = open and a.base or ("\u{1F512} " .. a.base)
		-- (area names when zoomed out, the smaller places when zoomed in: never a pile of labels)
		put(a.label, span >= 520 and a.pos or nil)
	end
	for _, n in names do put(n[1], span <= 760 and n[2] or nil) end
	local mine = player:GetAttribute("Plot")
	local plot = mine and workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(mine)
	put(yourTag, plot and plot:FindFirstChild("Bounds") and plot.Bounds.Position)
	local story = workspace:FindFirstChild("StoryNPCs")
	local giver = player:GetAttribute("MissionReady") and player:GetAttribute("MissionGiver")
	for name, p in npcPins do
		local m = story and story:FindFirstChild(name)
		put(p.frame, m and m.PrimaryPart and m.PrimaryPart.Position * Vector3.new(1, 0, 1))
		p.bang.Visible = giver == name
	end
	local seen = {}
	for _, pl in Players:GetPlayers() do
		if pl ~= player then
			local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
			local d = playerDots[pl]
			if not d then
				d = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = rgb(80, 170, 255), ZIndex = 8, Parent = overlay })
				UI.corner(d, 6)
				UI.stroke(d, 2)
				playerDots[pl] = d
			end
			put(d, r and r.Position * Vector3.new(1, 0, 1))
			seen[pl] = true
		end
	end
	for pl, d in playerDots do
		if not seen[pl] then d:Destroy() playerDots[pl] = nil end
	end
	local target = player:GetAttribute("GuideTarget")
	local tp = typeof(target) == "Vector3" and target * Vector3.new(1, 0, 1) or nil
	put(questPin, tp)
	questTag.Text = player:GetAttribute("GuideLabel") or ""
	put(questTag, tp, 28)
	local pulse = 1 + math.abs(math.sin(t0 * 3)) * 0.25
	questPin.Size = UDim2.fromOffset(34 * pulse, 34 * pulse)
	put(me, root and root.Position * Vector3.new(1, 0, 1))
	local look = workspace.CurrentCamera.CFrame.LookVector
	me.Rotation = math.deg(math.atan2(look.X, -look.Z))
end

---------------------------------------------------------------------------
-- zoom and pan
---------------------------------------------------------------------------
local function zoom(by)
	span = math.clamp(span * by, 140, 1700)
end
local controls = UI.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(44, 150), ZIndex = 10, Parent = map })
UI.new("UIListLayout", { Padding = UDim.new(0, 6), Parent = controls })
for i, spec in { { "+", function() zoom(1 / 1.35) end }, { "\u{2212}", function() zoom(1.35) end }, { "\u{25CE}", function() follow = true end } } do
	local b = UI.new("TextButton", { Text = spec[1], Font = UI.BIG, TextScaled = true, TextColor3 = UI.C.white, BackgroundColor3 = rgb(40, 44, 60), Size = UDim2.fromOffset(44, 44), LayoutOrder = i, ZIndex = 10, Parent = controls })
	UI.corner(b, 10)
	UI.stroke(b, 2)
	b.Activated:Connect(spec[2])
end
local dragging, last
map.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, last = true, input.Position
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
	if not gui.Enabled then return end
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		zoom(input.Position.Z > 0 and 1 / 1.2 or 1.2)
	elseif dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - last
		last = input.Position
		local studsPerPixel = span / W / holderScale.Scale
		center -= Vector3.new(d.X * studsPerPixel, 0, d.Y * studsPerPixel)
		follow = false
	end
end)

---------------------------------------------------------------------------
-- open / close: M, Tab, the button, a click on the dark background
---------------------------------------------------------------------------
local conn
local playerListWas
local function setOpen(on)
	if on == gui.Enabled then return end
	if on then
		buildOverlay()
		gui.Enabled = true
		follow = true
		holder.Size = UDim2.fromOffset((W + 24) * 0.94, (H + 76) * 0.94)
		TweenService:Create(holder, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(W + 24, H + 76) }):Play()
		refresh(0)
		conn = RunService.RenderStepped:Connect(refresh)
		draw()
		-- (Tab also opens Roblox's player list: tuck it away while the map is up)
		pcall(function()
			playerListWas = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		end)
	else
		gui.Enabled = false
		dragging = false
		if conn then conn:Disconnect() conn = nil end
		if playerListWas ~= nil then
			pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, playerListWas) end)
			playerListWas = nil
		end
	end
end
-- a click on the dark backdrop outside the map closes it (not a click that lands on the map: the
-- backdrop's Activated also fired for those, so dragging the map shut it)
dim.Activated:Connect(function()
	local m = UserInputService:GetMouseLocation() - game:GetService("GuiService"):GetGuiInset()
	local p, s = holder.AbsolutePosition, holder.AbsoluteSize
	if m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y then return end
	setOpen(false)
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode ~= Enum.KeyCode.M and input.KeyCode ~= Enum.KeyCode.Tab then return end
	if UserInputService:GetFocusedTextBox() then return end
	-- (Tab is Roblox's own player-list key, so it arrives "processed": take it anyway)
	if processed and input.KeyCode ~= Enum.KeyCode.Tab then return end
	setOpen(not gui.Enabled)
end)

-- the button, above the eye in the bottom-right corner
local buttonGui = UI.new("ScreenGui", { Name = "TownMapButton", ResetOnSpawn = false, DisplayOrder = 49, IgnoreGuiInset = true, Parent = player.PlayerGui })
local btn = UI.new("TextButton", {
	Text = "",
	AutoButtonColor = true,
	BackgroundColor3 = rgb(60, 140, 90),
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -10, 1, -58),
	Size = UDim2.fromOffset(56, 56),
	Parent = buttonGui,
})
UI.corner(btn, 14)
UI.stroke(btn, 3)
UI.label(btn, { Text = "\u{1F5FA}\u{FE0F}", Size = UDim2.new(1, 0, 0.66, 0), stroke = 0 })
UI.label(btn, { Text = "MAP (M)", Font = UI.BIG, TextScaled = true, Size = UDim2.new(1, -6, 0.3, 0), Position = UDim2.new(0, 3, 0.66, 0), stroke = 2 })
btn.Activated:Connect(function() setOpen(not gui.Enabled) end)
