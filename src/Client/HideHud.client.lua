-- StarterPlayer.StarterPlayerScripts.HideHud
-- Hide the whole interface when you want a clean view (screenshots, just looking around): press H,
-- or tap the little eye in the corner (it stays, so phones can bring everything back). While hidden:
-- every game screen, Roblox's own chat/leaderboard/backpack, and the quest guide (arrow, trail,
-- chevrons: Quests.client reads the HudHidden attribute) are off. The guide alone can also be
-- switched off in Settings (GuideOn).
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UI = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UI"))

-- (never hidden: the loading screen and cutscenes run their own show; this toggle itself)
local KEEP = { HideHud = true, Loading = true, Cutscene = true, Cutscenes = true }

local toggleGui = UI.new("ScreenGui", {
	Name = "HideHud",
	ResetOnSpawn = false,
	DisplayOrder = 50,
	IgnoreGuiInset = true,
	Parent = playerGui,
})
local eye = UI.new("TextButton", {
	Name = "Eye",
	Text = "\u{1F441}",
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	TextColor3 = Color3.new(1, 1, 1),
	AutoButtonColor = true,
	BackgroundColor3 = Color3.fromRGB(30, 30, 40),
	BackgroundTransparency = 0.35,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -10, 1, -10),
	Size = UDim2.fromOffset(40, 40),
	Parent = toggleGui,
})
UI.corner(eye, 20)
local hint = UI.new("TextLabel", {
	Text = "",
	Font = Enum.Font.FredokaOne,
	TextSize = 18,
	TextColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -58, 1, -18),
	Size = UDim2.fromOffset(260, 24),
	TextXAlignment = Enum.TextXAlignment.Right,
	Visible = false,
	Parent = toggleGui,
})
UI.stroke(hint, 2)

local was = {} -- [ScreenGui] = it was enabled before hiding
local hidden = false

local function setCore(on)
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, on) end)
end

local function apply()
	for _, g in playerGui:GetChildren() do
		if g:IsA("ScreenGui") and not KEEP[g.Name] then
			if hidden then
				if g.Enabled then
					was[g] = true
					g.Enabled = false
				end
			elseif was[g] then
				g.Enabled = true
			end
		end
	end
	if not hidden then table.clear(was) end
end

local function set(on)
	hidden = on
	player:SetAttribute("HudHidden", hidden or nil)
	setCore(not hidden)
	apply()
	eye.BackgroundTransparency = hidden and 0.6 or 0.35
	hint.Text = hidden and "Press H (or tap the eye) to show it again" or ""
	hint.Visible = hidden
	if hidden then
		task.delay(3, function() if hidden then hint.Visible = false end end)
	end
end

eye.Activated:Connect(function() set(not hidden) end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.H then return end
	if UserInputService:GetFocusedTextBox() then return end
	set(not hidden)
end)
-- (a screen that switches itself on while hidden, a menu or a cutscene ending, goes back off)
task.spawn(function()
	while true do
		task.wait(0.5)
		if hidden then apply() end
	end
end)
