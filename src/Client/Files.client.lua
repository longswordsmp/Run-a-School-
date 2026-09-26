-- StarterPlayer.StarterPlayerScripts.Files
-- The VexCorp Files on this client (FilesService):
--   the folders in the world bob and turn; the ones you've found fade out, for you only
--   reading one opens the document: a sheet of paper with a letterhead, a typed body and a stamp,
--     and the first time, what finding it earned
--   the Files book (the side button, ClientBus.OpenFiles): every document you've found, in order
--   and a camera flash for Stan's Snoop job (Push "flash")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")
local bus = ReplicatedStorage:WaitForChild("ClientBus", 10)

local player = Players.LocalPlayer
local PAPER = Color3.fromRGB(250, 246, 232)
local INK = Color3.fromRGB(40, 34, 30)
local VEX = Color3.fromRGB(105, 45, 150)

local gui = UI.new("ScreenGui", { Name = "Files", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 40, Parent = player:WaitForChild("PlayerGui") })
local root = UI.autoScale(gui)

---------------------------------------------------------------------------
-- the folders in the world
---------------------------------------------------------------------------
local function found()
	local set = {}
	for id in (player:GetAttribute("Files") or ""):gmatch("[^,]+") do set[id] = true end
	return set
end
local folders = {} -- [model] = base CFrame
local function refreshFolders()
	local set = found()
	local holder = workspace:FindFirstChild("VexFiles")
	for _, m in holder and holder:GetChildren() or {} do
		local have = set[m.Name] == true
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then d.LocalTransparencyModifier = have and 0.75 or 0 end
			if d:IsA("ParticleEmitter") or d:IsA("PointLight") then d.Enabled = not have end
		end
		local prompt = m:FindFirstChild("ReadPrompt", true)
		if prompt then prompt.ObjectText = have and "VexCorp File (read)" or "VexCorp File" end
		if m.PrimaryPart and not folders[m] then folders[m] = m:GetPivot() end
	end
end
player:GetAttributeChangedSignal("Files"):Connect(refreshFolders)
task.spawn(function()
	local holder = workspace:WaitForChild("VexFiles", 60)
	if not holder then return end
	holder.ChildAdded:Connect(function() task.defer(refreshFolders) end)
	refreshFolders()
end)
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local cam = workspace.CurrentCamera.CFrame.Position
	for m, base in folders do
		if not m.Parent then
			folders[m] = nil
		elseif (base.Position - cam).Magnitude < 120 then
			m:PivotTo(CFrame.new(base.Position + Vector3.new(0, math.sin(t * 2 + base.Position.X) * 0.25, 0)) * CFrame.Angles(0, t * 0.8, 0) * (base - base.Position))
		end
	end
end)

---------------------------------------------------------------------------
-- the document
---------------------------------------------------------------------------
local doc
local function closeDoc()
	if not doc then return end
	local d = doc
	doc = nil
	TweenService:Create(d, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 1.6, 0), Rotation = 8 }):Play()
	task.delay(0.27, function() d:Destroy() end)
end

local function openDoc(data)
	closeDoc()
	local sheet = UI.new("Frame", {
		Name = "Document",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 1.6, 0),
		Size = UDim2.fromOffset(560, 660),
		BackgroundColor3 = PAPER,
		Rotation = -6,
		ZIndex = 20,
		Parent = root,
	})
	doc = sheet
	UI.corner(sheet, 6)
	UI.stroke(sheet, 3, Color3.fromRGB(120, 100, 80))
	-- the shadow of a second sheet underneath
	local under = UI.new("Frame", { Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(10, 10), BackgroundColor3 = Color3.fromRGB(215, 205, 180), ZIndex = 19, Parent = sheet })
	UI.corner(under, 6)
	-- ruled lines
	for i = 0, 17 do
		UI.new("Frame", { Size = UDim2.new(1, -60, 0, 1), Position = UDim2.fromOffset(30, 190 + i * 24), BackgroundColor3 = Color3.fromRGB(190, 210, 235), BorderSizePixel = 0, ZIndex = 21, Parent = sheet })
	end
	UI.new("Frame", { Size = UDim2.new(0, 2, 1, -150), Position = UDim2.fromOffset(62, 150), BackgroundColor3 = Color3.fromRGB(240, 150, 150), BorderSizePixel = 0, ZIndex = 21, Parent = sheet })
	-- the letterhead, the title, the body
	UI.label(sheet, { Text = (data.by or ""):upper(), Font = UI.BIG, TextColor3 = VEX, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -60, 0, 26), Position = UDim2.fromOffset(30, 24), ZIndex = 22, stroke = 0 })
	UI.new("Frame", { Size = UDim2.new(1, -60, 0, 3), Position = UDim2.fromOffset(30, 56), BackgroundColor3 = VEX, BorderSizePixel = 0, ZIndex = 22, Parent = sheet })
	UI.label(sheet, { Text = data.title or "", Font = UI.BIG, TextColor3 = INK, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -60, 0, 44), Position = UDim2.fromOffset(30, 70), ZIndex = 22, stroke = 0 })
	UI.label(sheet, { Text = ("FILE %d OF %d"):format(data.n or 0, data.total or #Config.Files), TextColor3 = Color3.fromRGB(150, 130, 110), TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -60, 0, 20), Position = UDim2.fromOffset(30, 118), ZIndex = 22, stroke = 0 })
	UI.label(sheet, {
		Text = data.text or "",
		Font = Enum.Font.SpecialElite,
		TextScaled = false, TextSize = 22, TextWrapped = true,
		TextColor3 = INK,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = 1.08,
		Size = UDim2.new(1, -110, 0, 400),
		Position = UDim2.fromOffset(76, 176),
		ZIndex = 22,
		stroke = 0,
	})
	-- a red TOP SECRET stamp, crooked
	local stamp = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -140, 1, -118), Size = UDim2.fromOffset(200, 54), BackgroundTransparency = 1, Rotation = -12, ZIndex = 23, Parent = sheet })
	UI.stroke(stamp, 4, Color3.fromRGB(210, 40, 50))
	UI.corner(stamp, 8)
	UI.label(stamp, { Text = "TOP SECRET", Font = UI.BIG, TextColor3 = Color3.fromRGB(210, 40, 50), Size = UDim2.new(1, -16, 1, -12), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 24, stroke = 0 })
	-- what it earned
	if data.fresh then
		local reward = ("NEW FILE! +%d \u{1F36C}"):format(data.candy or 0) .. (data.reward and ("  \u{2022}  " .. data.n .. " found: " .. data.reward .. "!") or "")
		local band = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.new(1, -40, 0, 44), BackgroundColor3 = Color3.fromRGB(60, 190, 90), ZIndex = 24, Parent = sheet })
		UI.corner(band, 10)
		UI.stroke(band, 3)
		UI.label(band, { Text = reward, Font = UI.BIG, Size = UDim2.new(1, -16, 1, -10), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 25, stroke = 2 })
	end
	local x = UI.button(sheet, { text = "X", color = UI.C.red, size = UDim2.fromOffset(48, 48), position = UDim2.new(1, 14, 0, -14), anchor = Vector2.new(1, 0), font = UI.BIG })
	x.button.ZIndex = 26
	for _, d in x.button:GetDescendants() do if d:IsA("GuiObject") then d.ZIndex = 27 end end
	x.button.Activated:Connect(closeDoc)
	TweenService:Create(sheet, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.5), Rotation = -2 }):Play()
	-- walk away and it closes
	task.spawn(function()
		local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local at = r and r.Position
		while doc == sheet do
			task.wait(0.3)
			r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if at and r and (r.Position - at).Magnitude > 14 then closeDoc() end
		end
	end)
end

Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
	if kind == "file" and type(data) == "table" then
		openDoc(data)
	elseif kind == "flash" then
		-- *click*: a camera flash
		local f = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, ZIndex = 50, Parent = gui })
		TweenService:Create(f, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
		task.delay(0.65, function() f:Destroy() end)
	end
end)

---------------------------------------------------------------------------
-- the Files book
---------------------------------------------------------------------------
local book
local function openBook()
	if book then
		book:Destroy()
		book = nil
		return
	end
	local ok, res = pcall(Action.InvokeServer, Action, "files")
	if not ok or type(res) ~= "table" or res.ok == false then return end
	book = UI.new("Frame", {
		Name = "Book",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(760, 560),
		BackgroundColor3 = Color3.fromRGB(62, 40, 90),
		ZIndex = 15,
		Parent = root,
	})
	UI.corner(book, 18)
	UI.stroke(book, 4)
	UI.gradient(book, Color3.fromRGB(90, 56, 130), Color3.fromRGB(46, 28, 70))
	UI.label(book, { Text = "\u{1F5C2}\u{FE0F} THE VEXCORP FILES", Font = UI.BIG, Size = UDim2.new(1, -120, 0, 44), Position = UDim2.fromOffset(24, 16), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 16, stroke = 3 })
	UI.label(book, { Text = ("%d / %d found  \u{2022}  4, 8, 12 and 16 found earn a prize"):format(res.n, res.total), Size = UDim2.new(1, -48, 0, 24), Position = UDim2.fromOffset(24, 60), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(220, 200, 255), ZIndex = 16, stroke = 2 })
	local grid = UI.new("ScrollingFrame", { Size = UDim2.new(1, -40, 1, -110), Position = UDim2.fromOffset(20, 96), BackgroundTransparency = 1, ScrollBarThickness = 8, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 16, Parent = book })
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(170, 120), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	for i, f in res.files do
		local card = UI.new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = f.found and PAPER or Color3.fromRGB(40, 30, 55), LayoutOrder = i, ZIndex = 17, Parent = grid })
		UI.corner(card, 10)
		UI.stroke(card, 3)
		UI.label(card, { Text = f.found and "\u{1F4C4}" or "\u{2753}", Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(10, 8), ZIndex = 18, stroke = 0 })
		UI.label(card, { Text = ("#%d"):format(i), Font = UI.BIG, TextColor3 = f.found and VEX or Color3.fromRGB(150, 130, 180), TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(60, 26), Position = UDim2.new(1, -70, 0, 10), ZIndex = 18, stroke = 0 })
		UI.label(card, { Text = f.title, Font = UI.BIG, TextColor3 = f.found and INK or Color3.fromRGB(150, 130, 180), TextWrapped = true, Size = UDim2.new(1, -16, 0, 56), Position = UDim2.fromOffset(8, 56), ZIndex = 18, stroke = 0 })
		if f.found then
			card.Activated:Connect(function()
				openDoc({ title = f.title, by = f.by, text = f.text, n = i, total = res.total })
			end)
		end
	end
	local x = UI.button(book, { text = "X", color = UI.C.red, size = UDim2.fromOffset(48, 48), position = UDim2.new(1, -14, 0, 14), anchor = Vector2.new(1, 0), font = UI.BIG })
	x.button.ZIndex = 20
	for _, d in x.button:GetDescendants() do if d:IsA("GuiObject") then d.ZIndex = 21 end end
	x.button.Activated:Connect(function()
		if book then book:Destroy() book = nil end
	end)
	UI.pop(book, 0.85)
end

if bus then
	local e = bus:FindFirstChild("OpenFiles") or Instance.new("BindableEvent")
	e.Name = "OpenFiles"
	e.Parent = bus
	e.Event:Connect(openBook)
end
