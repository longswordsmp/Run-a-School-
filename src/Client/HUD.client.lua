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

-- rainbow gradients (Secret rarity, Straight A+ grade)
RunService.RenderStepped:Connect(function()
	local off = (os.clock() * 0.35) % 1
	for _, gr in CollectionService:GetTagged("Rainbow") do
		gr.Offset = Vector2.new(off * 2 - 1, 0)
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
