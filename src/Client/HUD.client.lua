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
-- scales down on phones (UI.autoScale)
require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UI")).autoScale(gui)

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
local ticketText = chip("Tickets", Color3.fromRGB(255, 165, 40))
chips.Size = UDim2.fromOffset(440, 34)
local lastTickets = player:GetAttribute("Tickets") or 0
local function refreshTickets()
	local n = player:GetAttribute("Tickets") or 0
	ticketText.Text = "\u{1F39F}\u{FE0F} " .. tostring(n)
	local show = n > 0 or workspace:GetAttribute("Event") ~= nil
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
workspace:GetAttributeChangedSignal("Event"):Connect(refreshTickets)
refreshTickets()
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
