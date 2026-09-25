-- StarterPlayer.StarterPlayerScripts.Chapters
-- Principal's Requests: the chapter checklist (right side, under the timers), the title card when a
-- new chapter starts, and a toast when a request is done. Server: ChapterService.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")
local bus = ReplicatedStorage:WaitForChild("ClientBus", 10)

local player = Players.LocalPlayer
local gui = UI.new("ScreenGui", {
	Name = "Chapters",
	ResetOnSpawn = false,
	DisplayOrder = 4,
	Parent = player:WaitForChild("PlayerGui"),
})
local uiRoot, uiScale = UI.autoScale(gui)

local W, ROW, TOP = 340, 30, 54
local LEFT = Enum.TextXAlignment.Left
local ORANGE = UI.C.orange

---------------------------------------------------------------------------
-- the checklist card
---------------------------------------------------------------------------
local card = UI.new("Frame", {
	Name = "Card",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 468),
	Size = UDim2.fromOffset(W, TOP + 5 * ROW + 30),
	BackgroundColor3 = UI.C.cream,
	Visible = false,
	ClipsDescendants = false,
	Parent = gui,
})
UI.corner(card, 14)
UI.stroke(card, 3)
local scale = Instance.new("UIScale")
scale.Parent = card
local fitScale = 1

local header = UI.new("TextButton", {
	Name = "Header",
	Text = "",
	AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = UI.C.white,
	Parent = card,
})
UI.corner(header, 14)
UI.gradient(header, UI.lighten(ORANGE, 0.3), ORANGE)
local title = UI.label(header, { Text = "", Font = UI.BIG, TextXAlignment = LEFT, Size = UDim2.new(1, -44, 1, -6), Position = UDim2.fromOffset(10, 3), stroke = 2 })
local chev = UI.label(header, { Text = "\u{25BE}", Font = UI.BIG, Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -32, 0, 2), stroke = 2 })
local sub = UI.label(card, { Text = "", TextColor3 = UI.C.ink, Font = UI.BIG, TextXAlignment = LEFT, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(12, 32), stroke = 0 })

local rows = {}
for i = 1, 5 do
	local r = UI.new("TextButton", {
		Name = "Row" .. i,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, ROW - 2),
		Position = UDim2.fromOffset(8, TOP + (i - 1) * ROW),
		Parent = card,
	})
	local box = UI.new("Frame", { Name = "Box", Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(2, 3), BackgroundColor3 = UI.C.white, Parent = r })
	UI.corner(box, 6)
	UI.stroke(box, 2)
	local tick = UI.label(box, { Text = "\u{2714}", TextColor3 = UI.C.green, Size = UDim2.fromScale(1, 1), stroke = 1, Visible = false })
	local text = UI.label(r, { Text = "", TextColor3 = UI.C.ink, TextXAlignment = LEFT, Size = UDim2.new(1, -106, 1, -4), Position = UDim2.fromOffset(32, 2), stroke = 0 })
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = 17
	cap.Parent = text
	local right = UI.label(r, { Text = "", TextColor3 = Color3.fromRGB(40, 150, 70), Size = UDim2.new(0, 70, 1, -8), Position = UDim2.new(1, -72, 0, 4), stroke = 0 })
	local line = UI.new("Frame", { Name = "Strike", BackgroundColor3 = UI.C.grey, BorderSizePixel = 0, Size = UDim2.new(1, -110, 0, 2), Position = UDim2.new(0, 32, 0.5, 0), Visible = false, Parent = r })
	rows[i] = { frame = r, box = box, tick = tick, text = text, right = right, strike = line }
end
local footer = UI.label(card, { Text = "", TextColor3 = UI.C.navy, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 1, -26), stroke = 0 })

local state
local collapsed = false
local userToggled = false -- the player folded or unfolded it; stop following the screen size

local function layout()
	if not state or state.hidden then
		card.Visible = false
		return
	end
	card.Visible = true
	local shown = 0
	for i, r in rows do
		local s = state.steps[i]
		-- collapsed: only the first request still open
		local visible = s ~= nil and (not collapsed or (not s.done and shown == 0))
		r.frame.Visible = visible
		if visible then
			r.frame.Position = UDim2.fromOffset(8, TOP + shown * ROW)
			shown += 1
		end
	end
	footer.Visible = not collapsed
	chev.Text = collapsed and "\u{25B8}" or "\u{25BE}"
	card.Size = UDim2.fromOffset(W, TOP + shown * ROW + (collapsed and 6 or 30))
end

local function fmtReward(s)
	if s.board then return "\u{1F3DB}" end
	if s.count then return ("%d/%d"):format(math.min(s.progress or 0, s.count), s.count) end
	return "+" .. Config.formatCash(s.reward or 0)
end

local function show(s)
	if type(s) ~= "table" then return end
	state = s
	if s.hidden then
		layout()
		return
	end
	title.Text = ("\u{1F4D6} CHAPTER %d/%d"):format(s.n, s.total)
	sub.Text = s.title
	for i, r in rows do
		local st = s.steps[i]
		if st then
			r.text.Text = st.text
			r.tick.Visible = st.done == true
			r.strike.Visible = st.done == true
			r.text.TextColor3 = st.done and UI.C.grey or UI.C.ink
			r.box.BackgroundColor3 = st.done and Color3.fromRGB(220, 255, 225) or UI.C.white
			r.right.Text = st.done and "" or fmtReward(st)
			r.right.TextColor3 = st.count and UI.C.navy or Color3.fromRGB(40, 150, 70)
		end
	end
	footer.Text = ("Finish them all: \u{1F4E8} %s Letter"):format(s.letter or "")
	layout()
end

header.Activated:Connect(function()
	userToggled = true
	collapsed = not collapsed
	layout()
end)

-- a request row opens the shop tab or panel it lives in
for i, r in rows do
	r.frame.Activated:Connect(function()
		local st = state and state.steps and state.steps[i]
		local openBus = bus and bus:FindFirstChild("OpenPanel")
		if not st or st.done or not st.guide or not openBus then return end
		local kind, arg = st.guide:match("^(%a+):(%w+)$")
		if kind == "shop" then
			openBus:Fire("Shop", tonumber(arg))
		elseif kind == "panel" then
			openBus:Fire(arg)
		end
	end)
end

-- sits under the HUD's letters column (which grows as letters unlock); small screens get a smaller
-- card folded to the next request, unless the player unfolded it
local function hudBottom()
	local hud = player.PlayerGui:FindFirstChild("HUD")
	local box = hud and hud:FindFirstChild("Letters", true)
	if not box then return 480 end
	local bottom = box.AbsolutePosition.Y
	for _, c in box:GetChildren() do
		if c:IsA("GuiObject") and c.Visible then
			bottom = math.max(bottom, c.AbsolutePosition.Y + c.AbsoluteSize.Y)
		end
	end
	return bottom
end
local function fit()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	-- the whole gui is scaled by uiScale (UI.autoScale); positions below are in its units
	local s = uiScale.Scale
	local top = hudBottom() / s + 10
	-- fold to the next request when the whole card won't fit under the letters (clear of the
	-- bottom bar); the card always sits under the letters, never over them
	local full = TOP + 5 * ROW + 30
	local fold = top + full > vp.Y / s - 110
	if not userToggled and collapsed ~= fold then
		collapsed = fold
		layout()
	end
	card.Position = UDim2.new(1, -12, 0, top)
end
task.spawn(function()
	while true do
		fit()
		task.wait(0.5)
	end
end)

---------------------------------------------------------------------------
-- toasts
---------------------------------------------------------------------------
local function fadeOut(obj, after)
	task.delay(after, function()
		for _, d in obj:GetDescendants() do
			if d:IsA("TextLabel") then TweenService:Create(d, TweenInfo.new(0.4), { TextTransparency = 1 }):Play() end
			if d:IsA("UIStroke") then TweenService:Create(d, TweenInfo.new(0.4), { Transparency = 1 }):Play() end
			if d:IsA("Frame") then TweenService:Create(d, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play() end
		end
		if obj:IsA("Frame") then TweenService:Create(obj, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play() end
		task.wait(0.45)
		obj:Destroy()
	end)
end

-- a request done: a strip that pops out to the left of the card; several at once (things you
-- already owned) stack downwards instead of on top of each other
local liveToasts, nextSlot = 0, 0
local function stepDone(d)
	local slot = nextSlot
	nextSlot += 1
	liveToasts += 1
	local t = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -(W + 24), 0, card.Position.Y.Offset + 20 + slot * 64),
		Size = UDim2.fromOffset(330, 58),
		BackgroundColor3 = UI.C.cream,
		Parent = gui,
	})
	UI.corner(t, 12)
	UI.stroke(t, 3)
	UI.label(t, { Text = "\u{2714} " .. d.text, TextColor3 = UI.C.ink, TextXAlignment = LEFT, Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(10, 4), stroke = 0 })
	UI.label(t, {
		Text = ("+%s   +%d \u{1F36C}"):format(Config.formatCash(d.reward or 0), d.candy or 0),
		Font = UI.BIG,
		TextColor3 = UI.C.green,
		TextXAlignment = LEFT,
		Size = UDim2.new(1, -16, 0, 26),
		Position = UDim2.fromOffset(10, 28),
		stroke = 2,
	})
	t.Destroying:Connect(function()
		liveToasts -= 1
		if liveToasts == 0 then nextSlot = 0 end
	end)
	UI.pop(t, 0.5)
	fadeOut(t, 2.6)
end

-- a new chapter: a title card in the middle of the screen with the host's line
local function chapterStart(d)
	-- after any cutscene (the Board review that opened this chapter hides this gui while it plays)
	local t0 = os.clock()
	while not gui.Enabled and os.clock() - t0 < 30 do task.wait(0.2) end
	task.wait(0.4)
	local f = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 120),
		Size = UDim2.fromOffset(560, 150),
		BackgroundColor3 = UI.C.cream,
		Parent = gui,
	})
	UI.corner(f, 18)
	UI.stroke(f, 4)
	local band = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = UI.C.white, Parent = f })
	UI.corner(band, 18)
	UI.gradient(band, UI.lighten(ORANGE, 0.3), ORANGE)
	UI.label(band, { Text = ("\u{1F4D6} CHAPTER %d"):format(d.n), Font = UI.BIG, Size = UDim2.new(1, -20, 1, -8), Position = UDim2.fromOffset(10, 4), stroke = 3 })
	UI.label(f, { Text = d.title, Font = UI.BIG, TextColor3 = UI.C.ink, Size = UDim2.new(1, -30, 0, 40), Position = UDim2.fromOffset(15, 50), stroke = 0 })
	UI.label(f, {
		Text = ("%s: \"%s\""):format(d.host, d.line),
		TextColor3 = UI.C.navy,
		TextWrapped = true,
		Size = UDim2.new(1, -40, 0, 48),
		Position = UDim2.fromOffset(20, 94),
		stroke = 0,
	})
	UI.pop(f, 0.4)
	fadeOut(f, 6)
end

Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
	if kind == "chapter" then
		show(data)
	elseif kind == "chapterStep" then
		stepDone(data)
		if state then
			scale.Scale = fitScale * 1.04
			TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = fitScale }):Play()
		end
	elseif kind == "chapterStart" then
		task.spawn(chapterStart, data)
	end
end)

task.spawn(function()
	for _ = 1, 10 do
		local ok, s = pcall(Action.InvokeServer, Action, "chapter")
		if ok and type(s) == "table" and s.ok ~= false then
			show(s)
			return
		end
		task.wait(2)
	end
end)
