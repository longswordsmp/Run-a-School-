-- StarterPlayer.StarterPlayerScripts.HUD
-- Chunky Steal-a-X style HUD: cash, tuition per second, toasts, cash pops, rainbow text,
-- and owner/other visibility for the desk prompts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Crew = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Crew"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
-- scales down on phones (UI.autoScale)
local UI = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UI"))
UI.autoScale(gui)

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
-- the stud texture on the cash panel, and a glint across it now and then
UI.studs(cashPanel, { zindex = 0, transparency = UI.STUD.card })
UI.shine(cashPanel, { zindex = 0, strength = 0.18 })
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
-- (with friends in the server, their bonus shows next to it)
local function refreshIncome()
	local friends = player:GetAttribute("FriendsBonus")
	incomeText.Text = Config.formatCash(player:GetAttribute("IncomePerSec") or 0) .. "/s tuition"
		.. (friends and ("  \u{1F465}+" .. friends .. "%") or "")
end
player:GetAttributeChangedSignal("IncomePerSec"):Connect(refreshIncome)
player:GetAttributeChangedSignal("FriendsBonus"):Connect(refreshIncome)
refreshCash()
refreshIncome()

-- the Money Boost badge on the cash panel's corner (only once you have one)
local boostBadge = Instance.new("TextLabel")
boostBadge.Name = "Boost"
-- (out to the right of the panel, level with it: the chips above cover its top corner)
boostBadge.AnchorPoint = Vector2.new(0, 0.5)
boostBadge.Position = UDim2.new(1, 10, 0.5, 0)
boostBadge.Size = UDim2.fromOffset(82, 40)
boostBadge.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
boostBadge.Font = Enum.Font.LuckiestGuy
boostBadge.TextScaled = true
boostBadge.TextColor3 = Color3.new(1, 1, 1)
boostBadge.Rotation = 8
boostBadge.Visible = false
boostBadge.ZIndex = 5
boostBadge.Parent = cashPanel
corner(boostBadge, 10)
stroke(boostBadge, 3)
local badgeText = Instance.new("UIPadding")
badgeText.PaddingLeft, badgeText.PaddingRight = UDim.new(0, 6), UDim.new(0, 6)
badgeText.Parent = boostBadge
local function refreshBoost()
	local n = player:GetAttribute("MoneyBoost") or 1
	boostBadge.Visible = n > 1
	boostBadge.Text = "x" .. n
	if n > 1 then
		local sc = boostBadge:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", boostBadge)
		sc.Scale = 1.4
		TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end
player:GetAttributeChangedSignal("MoneyBoost"):Connect(refreshBoost)
refreshBoost()

-- School IQ, Reputation and Candy chips above the cash panel: hidden (tomas, 2026-09-27: they
-- don't need to be on screen all the time), each popping up for a few seconds when it changes. IQ and
-- Rep live on the School Board panel, Candy in the Shop's candy tab.
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
	UI.studs(f, { zindex = 0, transparency = UI.STUD.chip })
	local t = text(f, { Name = "Text", Size = UDim2.new(1, -12, 1, -8), Position = UDim2.fromOffset(6, 4), Text = "", strokeThickness = 2 })
	return t
end
local iqText = chip("IQ", Color3.fromRGB(70, 150, 255))
local repText = chip("Rep", Color3.fromRGB(255, 140, 60))
local candyText = chip("Candy", Color3.fromRGB(255, 110, 190))
local ticketText = chip("Tickets", Color3.fromRGB(255, 165, 40))
chips.Size = UDim2.fromOffset(440, 34)
local lastTickets = player:GetAttribute("Tickets") or 0
local function refreshTickets()
	local n = player:GetAttribute("Tickets") or 0
	ticketText.Text = "\u{1F39F}\u{FE0F} " .. tostring(n)
	local show = (n > 0 or workspace:GetAttribute("Event") ~= nil) and not player:GetAttribute("InTutorial")
	ticketText.Parent.Visible = show
	chips.Size = UDim2.fromOffset(show and 590 or 440, 34)
	if n > lastTickets then
		local sc = ticketText.Parent:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", ticketText.Parent)
		sc.Scale = 1.2
		TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	lastTickets = n
end
player:GetAttributeChangedSignal("Tickets"):Connect(refreshTickets)
player:GetAttributeChangedSignal("InTutorial"):Connect(refreshTickets)
workspace:GetAttributeChangedSignal("Event"):Connect(refreshTickets)
refreshTickets()
local function refreshCandy()
	candyText.Text = "\u{1F36C} " .. tostring(player:GetAttribute("Candy") or 0)
end
refreshCandy()
local function refreshChips()
	iqText.Text = "\u{1F9E0} IQ " .. tostring(player:GetAttribute("IQ") or 100)
	repText.Text = "\u{2B50} Rep " .. tostring(player:GetAttribute("Rep") or 0)
end
refreshChips()
-- a chip shows for a moment when its number changes (not when the save first loads it)
local flashes = {}
local function flash(name)
	local c = chips[name]
	c.Visible = true
	flashes[name] = (flashes[name] or 0) + 1
	local mine = flashes[name]
	local sc = c:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", c)
	sc.Scale = 1.25
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(3, function()
		if flashes[name] == mine then c.Visible = false end
	end)
end
for _, name in { "IQ", "Rep", "Candy" } do
	chips[name].Visible = false
	local last = player:GetAttribute(name)
	player:GetAttributeChangedSignal(name):Connect(function()
		local now = player:GetAttribute(name)
		if name == "Candy" then refreshCandy() else refreshChips() end
		if last ~= nil and now ~= last then flash(name) end
		last = now
	end)
end

-- toasts, top centre
local toastHolder = Instance.new("Frame")
toastHolder.Name = "Toasts"
toastHolder.AnchorPoint = Vector2.new(0.5, 0)
toastHolder.Position = UDim2.new(0.5, 0, 0, 62)
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
local function toast(msg, kind)
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
end
Remotes.Notify.OnClientEvent:Connect(toast)
-- other client scripts toast through ClientBus.Toast (Menus: Home cooldown, a button unlocking)
do
	local bus = ReplicatedStorage:FindFirstChild("ClientBus") or ReplicatedStorage:WaitForChild("ClientBus", 10)
	if bus and not bus:FindFirstChild("Toast") then
		local e = Instance.new("BindableEvent")
		e.Name = "Toast"
		e.Parent = bus
		e.Event:Connect(toast)
	end
end

-- "Saved" in the bottom-left corner each time the school is saved
do
	local chip = Instance.new("Frame")
	chip.Name = "Saved"
	chip.AnchorPoint = Vector2.new(0, 1)
	chip.Position = UDim2.new(0, 14, 1, -14)
	chip.Size = UDim2.fromOffset(118, 34)
	chip.BackgroundColor3 = Color3.fromRGB(30, 34, 64)
	chip.BackgroundTransparency = 1
	chip.Parent = gui
	corner(chip, 17)
	local st = stroke(chip, 2)
	st.Transparency = 1
	UI.studs(chip, { zindex = 0, transparency = UI.STUD.chip })
	local t = text(chip, { Size = UDim2.new(1, -16, 1, -10), Position = UDim2.fromOffset(8, 5), Text = "\u{2714} Saved", TextColor3 = Color3.fromRGB(140, 255, 150), TextTransparency = 1 })
	t.UIStroke.Transparency = 1
	Remotes.Push.OnClientEvent:Connect(function(kind)
		if kind ~= "saved" then return end
		local show = TweenInfo.new(0.25)
		TweenService:Create(chip, show, { BackgroundTransparency = 0.25 }):Play()
		TweenService:Create(st, show, { Transparency = 0 }):Play()
		TweenService:Create(t, show, { TextTransparency = 0 }):Play()
		TweenService:Create(t.UIStroke, show, { Transparency = 0 }):Play()
		task.delay(2.2, function()
			local hide = TweenInfo.new(0.6)
			TweenService:Create(chip, hide, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(st, hide, { Transparency = 1 }):Play()
			TweenService:Create(t, hide, { TextTransparency = 1 }):Play()
			TweenService:Create(t.UIStroke, hide, { Transparency = 1 }):Play()
		end)
	end)
end

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
-- (a kept set, 20 times a second, and only tags near enough to be drawn: GetTagged and a write to
-- every gradient in the server on every frame grew with every rare kid in every school)
local rainbowSet = {}
for _, gr in CollectionService:GetTagged("Rainbow") do rainbowSet[gr] = true end
CollectionService:GetInstanceAddedSignal("Rainbow"):Connect(function(gr) rainbowSet[gr] = true end)
CollectionService:GetInstanceRemovedSignal("Rainbow"):Connect(function(gr) rainbowSet[gr] = nil end)
local rainbowAcc = 0
RunService.RenderStepped:Connect(function(dt)
	rainbowAcc += dt
	if rainbowAcc < 0.05 then return end
	rainbowAcc = 0
	local t = os.clock()
	local keys = {}
	for i = 0, 5 do
		keys[i + 1] = ColorSequenceKeypoint.new(i / 5, Color3.fromHSV((t * 0.25 + i / 5) % 1, 0.75, 1))
	end
	local rainbowSeq = ColorSequence.new(keys)
	local shimmer = Vector2.new(math.sin(t * 2) * 0.5, 0)
	local camPos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position
	for gr in rainbowSet do
		local bb = gr:FindFirstAncestorWhichIsA("BillboardGui")
		local at = bb and bb.Parent
		local far = camPos and at and at:IsA("BasePart") and (at.Position - camPos).Magnitude > (bb.MaxDistance > 0 and bb.MaxDistance or 200)
		if not far then
			if gr:GetAttribute("Kind") == "shimmer" then
				gr.Offset = shimmer
			else
				gr.Color = rainbowSeq
			end
		end
	end
end)

-- desk prompts: the owner (and their co-op crew) sees Sell, everyone else sees Steal
local function fixPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") then return end
	-- a mission's own prompt (Vex's desk): only while you're on one of those missions (a list of
	-- ids), showing that mission's item
	local mission = prompt:GetAttribute("MissionOnly")
	if mission then
		local mine = player:GetAttribute("Mission")
		local on = false
		for id in string.gmatch(mission, "[^,]+") do
			if id == mine then on = true end
		end
		prompt.Enabled = on
		local def = on and Config.Missions[mine]
		if def and def.itemName then prompt.ObjectText = def.itemName end
		return
	end
	local owner = prompt:FindFirstAncestorOfClass("Model")
	while owner and owner:GetAttribute("OwnerId") == nil do
		owner = owner:FindFirstAncestorOfClass("Model")
	end
	if not owner then return end
	local mine = Crew.owns(player, owner:GetAttribute("OwnerId"))
	if prompt:GetAttribute("OwnerOnly") then prompt.Enabled = mine end
	if prompt:GetAttribute("OthersOnly") then prompt.Enabled = not mine end
end
-- a prompt meant for one principal (their Welcome Bus kids): nobody else sees it
task.spawn(function()
	local hallFolder = workspace:WaitForChild("Hall", 30)
	if not hallFolder then return end
	local function fixOnlyFor(d)
		local who = d:IsA("ProximityPrompt") and d:GetAttribute("OnlyFor")
		if who then d.Enabled = Crew.owns(player, who) end
	end
	hallFolder.DescendantAdded:Connect(function(d) task.defer(fixOnlyFor, d) end)
	for _, d in hallFolder:GetDescendants() do fixOnlyFor(d) end
end)
local plots = workspace:WaitForChild("Plots")
plots.DescendantAdded:Connect(function(d)
	if d:IsA("ProximityPrompt") then task.defer(fixPrompt, d) end
end)
for _, d in plots:GetDescendants() do fixPrompt(d) end
-- the Factory's pens: only a kid's owner can open their pen
task.spawn(function()
	local fac = workspace:WaitForChild("VexFactory", 30)
	if not fac then return end
	local function watch(d)
		if d:IsA("ProximityPrompt") then
			task.defer(fixPrompt, d)
			d:GetAttributeChangedSignal("OwnerOnly"):Connect(function() fixPrompt(d) end)
		elseif d:IsA("Model") and d.Name:match("^Pen%d") then
			d:GetAttributeChangedSignal("OwnerId"):Connect(function()
				for _, x in d:GetDescendants() do fixPrompt(x) end
			end)
		end
	end
	fac.DescendantAdded:Connect(watch)
	for _, d in fac:GetDescendants() do watch(d) end
	player:GetAttributeChangedSignal("Mission"):Connect(function()
		for _, d in fac:GetDescendants() do
			if d:IsA("ProximityPrompt") and d:GetAttribute("MissionOnly") then fixPrompt(d) end
		end
	end)
end)
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
-- joining or leaving a co-op school changes what's "mine": every prompt looks again
player:GetAttributeChangedSignal("SchoolId"):Connect(function()
	for _, folder in { plots, hallFolder, workspace:FindFirstChild("VexFactory") } do
		for _, d in folder and folder:GetDescendants() or {} do fixPrompt(d) end
	end
end)
