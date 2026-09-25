-- StarterPlayer.StarterPlayerScripts.HUD
-- Chunky Steal-a-X style HUD: cash, tuition per second, toasts, cash pops, rainbow text,
-- and owner/other visibility for the desk prompts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local FONT = Enum.Font.FredokaOne

local function stroke(obj, thickness, color)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 3
	s.Color = color or Color3.fromRGB(0, 0, 0)
	s.ApplyStrokeMode = obj:IsA("TextLabel") and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end

local function corner(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = obj
end

local function text(parent, props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = FONT
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	for k, v in props do
		if k ~= "strokeThickness" then t[k] = v end
	end
	t.Parent = parent
	stroke(t, props.strokeThickness or 3)
	return t
end

-- cash panel, bottom centre
local cashPanel = Instance.new("Frame")
cashPanel.Name = "Cash"
cashPanel.AnchorPoint = Vector2.new(0.5, 1)
cashPanel.Position = UDim2.new(0.5, 0, 1, -18)
cashPanel.Size = UDim2.fromOffset(300, 86)
cashPanel.BackgroundColor3 = Color3.fromRGB(46, 200, 90)
cashPanel.Parent = gui
corner(cashPanel, 18)
stroke(cashPanel, 4)
local g = Instance.new("UIGradient")
g.Color = ColorSequence.new(Color3.fromRGB(120, 255, 140), Color3.fromRGB(30, 170, 70))
g.Rotation = 90
g.Parent = cashPanel
local cashText = text(cashPanel, { Name = "Amount", Size = UDim2.new(1, -20, 0.62, 0), Position = UDim2.new(0, 10, 0, 4), Text = "$0" })
local incomeText = text(cashPanel, { Name = "Income", Size = UDim2.new(1, -20, 0.3, 0), Position = UDim2.new(0, 10, 0.64, 0), Text = "$0/s", TextColor3 = Color3.fromRGB(230, 255, 230), strokeThickness = 2 })

local shownCash = 0
local function refreshCash()
	local target = player:GetAttribute("Cash") or 0
	local from = shownCash
	shownCash = target
	-- count up quickly and punch the panel
	if target > from then
		local sc = cashPanel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", cashPanel)
		sc.Scale = 1.08
		TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	cashText.Text = Config.formatCash(target)
end
player:GetAttributeChangedSignal("Cash"):Connect(refreshCash)
player:GetAttributeChangedSignal("IncomePerSec"):Connect(function()
	incomeText.Text = Config.formatCash(player:GetAttribute("IncomePerSec") or 0) .. "/s tuition"
end)
refreshCash()
incomeText.Text = Config.formatCash(player:GetAttribute("IncomePerSec") or 0) .. "/s tuition"

-- School IQ and Reputation chips above the cash panel
local chips = Instance.new("Frame")
chips.Name = "Chips"
chips.AnchorPoint = Vector2.new(0.5, 1)
chips.Position = UDim2.new(0.5, 0, 1, -112)
chips.Size = UDim2.fromOffset(300, 34)
chips.BackgroundTransparency = 1
chips.Parent = gui
local cl = Instance.new("UIListLayout")
cl.FillDirection = Enum.FillDirection.Horizontal
cl.HorizontalAlignment = Enum.HorizontalAlignment.Center
cl.Padding = UDim.new(0, 8)
cl.Parent = chips
local function chip(name, color)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = UDim2.fromOffset(140, 34)
	f.BackgroundColor3 = color
	f.Parent = chips
	corner(f, 12)
	stroke(f, 3)
	local t = text(f, { Name = "Text", Size = UDim2.new(1, -12, 1, -8), Position = UDim2.fromOffset(6, 4), Text = "", strokeThickness = 2 })
	return t
end
local iqText = chip("IQ", Color3.fromRGB(70, 150, 255))
local repText = chip("Rep", Color3.fromRGB(255, 140, 60))
local candyText = chip("Candy", Color3.fromRGB(255, 110, 190))
chips.Size = UDim2.fromOffset(440, 34)
local function refreshCandy()
	candyText.Text = "\u{1F36C} " .. tostring(player:GetAttribute("Candy") or 0)
end
player:GetAttributeChangedSignal("Candy"):Connect(refreshCandy)
refreshCandy()
local function refreshChips()
	iqText.Text = "\u{1F9E0} IQ " .. tostring(player:GetAttribute("IQ") or 100)
	repText.Text = "\u{2B50} Rep " .. tostring(player:GetAttribute("Rep") or 0)
end
player:GetAttributeChangedSignal("IQ"):Connect(function()
	refreshChips()
	local sc = chips.IQ:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", chips.IQ)
	sc.Scale = 1.25
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end)
player:GetAttributeChangedSignal("Rep"):Connect(function()
	refreshChips()
	local sc = chips.Rep:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", chips.Rep)
	sc.Scale = 1.25
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end)
refreshChips()

-- event timers, top right: what's coming and when
local timers = Instance.new("Frame")
timers.Name = "Timers"
timers.AnchorPoint = Vector2.new(1, 0)
timers.Position = UDim2.new(1, -12, 0, 8)
timers.Size = UDim2.fromOffset(270, 330)
timers.BackgroundTransparency = 1
timers.Parent = gui
local tlist = Instance.new("UIListLayout")
tlist.Padding = UDim.new(0, 6)
tlist.SortOrder = Enum.SortOrder.LayoutOrder
tlist.Parent = timers
local TIMERS = {
	{ attr = "PickAt", icon = "\u{1F451}", label = "Principal's Pick", sub = "Prodigy or Secret", color = Color3.fromRGB(60, 50, 80) },
	{ attr = "HonorBusAt", icon = "\u{1F3C6}", label = "Honor Roll Bus", sub = "Legendary+", color = Color3.fromRGB(255, 190, 40) },
	{ attr = "LateBusAt", icon = "\u{1F68C}", label = "Late Bus", sub = "Rare+", color = Color3.fromRGB(255, 130, 40) },
	{ attr = "FieldTripAt", icon = "\u{1F392}", label = "Field Trip", sub = "Epic+", color = Color3.fromRGB(160, 90, 255) },
	{ attr = "RecessAt", icon = "\u{1F514}", label = "Recess", sub = "Luck x2", color = Color3.fromRGB(60, 200, 110) },
	{ attr = "NextEventAt", icon = "\u{1F389}", label = "Next Event", sub = "Special grades", color = Color3.fromRGB(255, 90, 170) },
}
local EVENT_NAMES = {
	SnowDay = { "\u{2744}\u{FE0F} SNOW DAY", "Snow Day kids x3" },
	ScienceFair = { "\u{1F9EA} SCIENCE FAIR", "Radioactive kids x4" },
	PictureDay = { "\u{1F4F8} PICTURE DAY", "Picture Perfect x2" },
	Halloween = { "\u{1F383} HALLOWEEN", "Spooky kids x3.5" },
	SpaceCamp = { "\u{1F680} SPACE CAMP", "Cosmic kids x7" },
	FieldDay = { "\u{1F3C5} FIELD DAY", "Gold Medal kids x3" },
	PromNight = { "\u{1FA69} PROM NIGHT", "Prom Royalty x4" },
	Throwback = { "\u{1F4FC} THROWBACK WEEK", "Retro kids x3" },
	WizardWeek = { "\u{1FA84} WIZARD WEEK", "Enchanted kids x5" },
	CandyCarnival = { "\u{1F36D} CANDY CARNIVAL", "Sugar Rush kids x3" },
	HostileTakeover = { "\u{1F3E2} HOSTILE TAKEOVER", "Old Money kids x5" },
	Graduation = { "\u{1F393} GRADUATION", "Graduated kids x6" },
}
local rows = {}
for i, spec in TIMERS do
	local f = Instance.new("Frame")
	f.Name = spec.attr
	f.LayoutOrder = i
	f.Size = UDim2.fromOffset(270, 48)
	f.BackgroundColor3 = spec.color
	f.Parent = timers
	corner(f, 12)
	stroke(f, 3)
	local g2 = Instance.new("UIGradient")
	g2.Color = ColorSequence.new(spec.color:Lerp(Color3.new(1, 1, 1), 0.3), spec.color)
	g2.Rotation = 90
	g2.Parent = f
	local name = text(f, { Name = "Name", Size = UDim2.new(0.66, -8, 0.56, 0), Position = UDim2.fromOffset(8, 3), TextXAlignment = Enum.TextXAlignment.Left, Text = spec.icon .. " " .. spec.label, strokeThickness = 2 })
	text(f, { Name = "Sub", Size = UDim2.new(0.66, -8, 0.34, 0), Position = UDim2.new(0, 30, 0.6, 0), TextXAlignment = Enum.TextXAlignment.Left, Text = spec.sub, TextColor3 = Color3.fromRGB(255, 255, 230), strokeThickness = 1.5 })
	local time = text(f, { Name = "Time", Size = UDim2.new(0.34, -10, 0.7, 0), Position = UDim2.new(0.66, 0, 0.15, 0), TextXAlignment = Enum.TextXAlignment.Right, Text = "", strokeThickness = 2 })
	rows[spec.attr] = { frame = f, name = name, time = time, spec = spec }
end
local function mmss(s)
	s = math.max(0, math.floor(s))
	if s >= 3600 then return ("%d:%02d:%02d"):format(s // 3600, (s % 3600) // 60, s % 60) end
	return ("%d:%02d"):format(s // 60, s % 60)
end
task.spawn(function()
	while true do
		local now = workspace:GetServerTimeNow()
		for attr, r in rows do
			local at = workspace:GetAttribute(attr)
			r.frame.Visible = at ~= nil
			if at then
				local ev = workspace:GetAttribute("Event")
				if attr == "NextEventAt" and ev and EVENT_NAMES[ev] then
					r.name.Text = EVENT_NAMES[ev][1]
					r.frame.Sub.Text = EVENT_NAMES[ev][2]
					r.time.Text = mmss((workspace:GetAttribute("EventUntil") or now) - now)
				elseif attr == "NextEventAt" then
					r.frame.Sub.Text = r.spec.sub
					r.name.Text = r.spec.icon .. " " .. r.spec.label
					r.time.Text = mmss(at - now)
				elseif attr == "RecessAt" and (workspace:GetAttribute("RecessUntil") or 0) > now then
					r.name.Text = "\u{1F514} RECESS! Luck x2"
					r.time.Text = mmss(workspace:GetAttribute("RecessUntil") - now)
				else
					local left = at - now
					r.name.Text = r.spec.icon .. " " .. r.spec.label
					r.time.Text = left <= 10 and "SOON!" or mmss(left)
				end
			end
		end
		task.wait(0.25)
	end
end)

-- Admissions Letters, right edge: time until each letter fills, CALL when it's ready
local Action = Remotes:WaitForChild("Action")
local letterBox = Instance.new("Frame")
letterBox.Name = "Letters"
letterBox.AnchorPoint = Vector2.new(1, 0)
letterBox.Position = UDim2.new(1, -12, 0, 350)
letterBox.Size = UDim2.fromOffset(230, 230)
letterBox.BackgroundTransparency = 1
letterBox.Parent = gui
local ll = Instance.new("UIListLayout")
ll.Padding = UDim.new(0, 5)
ll.SortOrder = Enum.SortOrder.LayoutOrder
ll.HorizontalAlignment = Enum.HorizontalAlignment.Right
ll.Parent = letterBox
local LETTERS = {
	{ "Rare", Color3.fromRGB(70, 150, 255) },
	{ "Epic", Color3.fromRGB(180, 80, 255) },
	{ "Legendary", Color3.fromRGB(255, 170, 30) },
	{ "Mythic", Color3.fromRGB(255, 50, 90) },
	{ "Prodigy", Color3.fromRGB(90, 230, 255) },
}
local letterRows = {}
for i, spec in LETTERS do
	local r, color = spec[1], spec[2]
	local b = Instance.new("TextButton")
	b.Name = r
	b.LayoutOrder = i
	b.Size = UDim2.fromOffset(210, 38)
	b.AutoButtonColor = false
	b.Text = ""
	b.BackgroundColor3 = Color3.fromRGB(255, 247, 230)
	b.Parent = letterBox
	corner(b, 12)
	stroke(b, 3)
	local seal = Instance.new("Frame")
	seal.Size = UDim2.fromOffset(26, 26)
	seal.Position = UDim2.new(0, 6, 0.5, 0)
	seal.AnchorPoint = Vector2.new(0, 0.5)
	seal.BackgroundColor3 = color
	seal.Parent = b
	corner(seal, 13)
	stroke(seal, 2)
	text(seal, { Size = UDim2.fromScale(1, 1), Text = "\u{2709}", strokeThickness = 1 })
	local name = text(b, { Name = "Name", Size = UDim2.new(0.5, -20, 0.8, 0), Position = UDim2.new(0, 38, 0.1, 0), TextXAlignment = Enum.TextXAlignment.Left, Text = r, TextColor3 = color, strokeThickness = 2 })
	local time = text(b, { Name = "Time", Size = UDim2.new(0.42, -8, 0.7, 0), Position = UDim2.new(0.58, 0, 0.15, 0), TextXAlignment = Enum.TextXAlignment.Right, Text = "", strokeThickness = 2 })
	letterRows[r] = { button = b, time = time, name = name, color = color }
	b.Activated:Connect(function()
		if (player:GetAttribute("Letter_" .. r) or 1) > 0 then return end
		-- the server answers with a toast either way
		pcall(Action.InvokeServer, Action, "callLetter", r)
	end)
end
-- the next playtime gift, under the letters
local gift = Instance.new("Frame")
gift.Name = "Gift"
gift.LayoutOrder = 99
gift.Size = UDim2.fromOffset(210, 44)
gift.BackgroundColor3 = Color3.fromRGB(255, 120, 200)
gift.Visible = false
gift.Parent = letterBox
corner(gift, 12)
stroke(gift, 3)
local giftGrad = Instance.new("UIGradient")
giftGrad.Color = ColorSequence.new(Color3.fromRGB(255, 170, 225), Color3.fromRGB(230, 80, 170))
giftGrad.Rotation = 90
giftGrad.Parent = gift
local giftName = text(gift, { Size = UDim2.new(0.66, -8, 0.55, 0), Position = UDim2.fromOffset(8, 3), TextXAlignment = Enum.TextXAlignment.Left, Text = "\u{1F381} Gift", strokeThickness = 2 })
local giftSub = text(gift, { Size = UDim2.new(0.66, -8, 0.36, 0), Position = UDim2.new(0, 8, 0.58, 0), TextXAlignment = Enum.TextXAlignment.Left, Text = "", TextColor3 = Color3.fromRGB(255, 250, 230), strokeThickness = 1.5 })
local giftTime = text(gift, { Size = UDim2.new(0.34, -8, 0.7, 0), Position = UDim2.new(0.66, 0, 0.15, 0), TextXAlignment = Enum.TextXAlignment.Right, Text = "", strokeThickness = 2 })
task.spawn(function()
	while true do
		local at = player:GetAttribute("NextGiftAt")
		gift.Visible = at ~= nil
		if at then
			local left = math.max(0, at - workspace:GetServerTimeNow())
			giftName.Text = "\u{1F381} Next gift"
			giftSub.Text = player:GetAttribute("NextGiftText") or ""
			giftTime.Text = ("%d:%02d"):format(left // 60, left % 60)
		end
		task.wait(0.5)
	end
end)

local function mmss2(s)
	s = math.max(0, math.floor(s))
	if s >= 3600 then return ("%dh %02dm"):format(s // 3600, (s % 3600) // 60) end
	return ("%d:%02d"):format(s // 60, s % 60)
end
task.spawn(function()
	while true do
		local tier = player:GetAttribute("Tier") or 1
		for i, spec in LETTERS do
			local r = spec[1]
			local row = letterRows[r]
			local left = player:GetAttribute("Letter_" .. r)
			-- the rarer letters show once they are within reach
			row.button.Visible = left ~= nil and (i <= 2 or tier >= i)
			if left then
				if left <= 0 then
					row.time.Text = "CALL!"
					row.time.TextColor3 = Color3.fromRGB(110, 255, 120)
					local pulse = 0.5 + 0.5 * math.sin(os.clock() * 6)
					row.button.BackgroundColor3 = Color3.fromRGB(255, 247, 230):Lerp(row.color, 0.25 + 0.25 * pulse)
				else
					row.time.Text = mmss2(left)
					row.time.TextColor3 = Color3.new(1, 1, 1)
					row.button.BackgroundColor3 = Color3.fromRGB(255, 247, 230)
				end
			end
		end
		task.wait(0.2)
	end
end)

-- toasts, top centre
local toastHolder = Instance.new("Frame")
toastHolder.Name = "Toasts"
toastHolder.AnchorPoint = Vector2.new(0.5, 0)
toastHolder.Position = UDim2.new(0.5, 0, 0, 10)
toastHolder.Size = UDim2.fromOffset(520, 200)
toastHolder.BackgroundTransparency = 1
toastHolder.Parent = gui
local tl = Instance.new("UIListLayout")
tl.HorizontalAlignment = Enum.HorizontalAlignment.Center
tl.Padding = UDim.new(0, 6)
tl.Parent = toastHolder

local KIND = {
	good = Color3.fromRGB(110, 255, 120),
	bad = Color3.fromRGB(255, 90, 90),
	info = Color3.fromRGB(255, 255, 255),
	steal = Color3.fromRGB(255, 170, 40),
}
Remotes.Notify.OnClientEvent:Connect(function(msg, kind)
	local t = text(toastHolder, { Size = UDim2.fromOffset(520, 38), Text = msg, TextColor3 = KIND[kind] or KIND.info })
	local sc = Instance.new("UIScale")
	sc.Scale = 0.4
	sc.Parent = t
	TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(2.6, function()
		TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		TweenService:Create(t.UIStroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		task.wait(0.45)
		t:Destroy()
	end)
end)

-- "+$123" floating up from the collect pad
Remotes.CashPop.OnClientEvent:Connect(function(amount, pos)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = pos + Vector3.new(0, 2, 0)
	anchor.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(200, 50)
	bb.AlwaysOnTop = true
	bb.Parent = anchor
	local t = text(bb, { Size = UDim2.fromScale(1, 1), Text = "+" .. Config.formatCash(amount), TextColor3 = Color3.fromRGB(120, 255, 120) })
	TweenService:Create(anchor, TweenInfo.new(1, Enum.EasingStyle.Quad), { Position = anchor.Position + Vector3.new(0, 5, 0) }):Play()
	TweenService:Create(t, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
	task.delay(1, function() anchor:Destroy() end)
end)

-- animated gradients: rainbow ones (Secret rarity, Straight A+) cycle their hues; two-colour
-- shimmers (Prodigy, Alumni) slide back and forth. Sliding a rainbow off its end parked it on red.
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local keys = {}
	for i = 0, 5 do
		keys[i + 1] = ColorSequenceKeypoint.new(i / 5, Color3.fromHSV((t * 0.25 + i / 5) % 1, 0.75, 1))
	end
	local rainbowSeq = ColorSequence.new(keys)
	local shimmer = Vector2.new(math.sin(t * 2) * 0.5, 0)
	for _, gr in CollectionService:GetTagged("Rainbow") do
		if gr:GetAttribute("Kind") == "shimmer" then
			gr.Offset = shimmer
		else
			gr.Color = rainbowSeq
		end
	end
end)

-- desk prompts: the owner sees Sell, everyone else sees Steal
local function fixPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") then return end
	local owner = prompt:FindFirstAncestorOfClass("Model")
	while owner and owner:GetAttribute("OwnerId") == nil do
		owner = owner:FindFirstAncestorOfClass("Model")
	end
	if not owner then return end
	local mine = owner:GetAttribute("OwnerId") == player.UserId
	if prompt:GetAttribute("OwnerOnly") then prompt.Enabled = mine end
	if prompt:GetAttribute("OthersOnly") then prompt.Enabled = not mine end
end
local plots = workspace:WaitForChild("Plots")
plots.DescendantAdded:Connect(function(d)
	if d:IsA("ProximityPrompt") then task.defer(fixPrompt, d) end
end)
for _, d in plots:GetDescendants() do fixPrompt(d) end
-- a plot changing hands re-checks its prompts (the lock button's prompt is made only once)
local function hookPlot(plot)
	plot:GetAttributeChangedSignal("OwnerId"):Connect(function()
		for _, d in plot:GetDescendants() do fixPrompt(d) end
	end)
end
for _, plot in plots:GetChildren() do hookPlot(plot) end
plots.ChildAdded:Connect(function(plot)
	hookPlot(plot)
	for _, d in plot:GetDescendants() do fixPrompt(d) end
end)
-- kids waiting on a bench are reserved for their owner
local hallFolder = workspace:WaitForChild("Hall", 10)
if hallFolder then
	hallFolder.DescendantAdded:Connect(function(d)
		if d:IsA("ProximityPrompt") then task.defer(fixPrompt, d) end
	end)
end
