-- StarterPlayer.StarterPlayerScripts.Prompts
-- Replaces the default ProximityPrompt look with a chunky pill: key badge, object text in the
-- rarity colour, action text, and a hold bar. Works for touch (tap the pill).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")

local UI = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UI"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- switch every prompt to the custom style (if this script failed, the default UI would still show)
local function claim(p)
	if p:IsA("ProximityPrompt") then p.Style = Enum.ProximityPromptStyle.Custom end
end
for _, d in workspace:GetDescendants() do claim(d) end
workspace.DescendantAdded:Connect(claim)

local KEY_TEXT = {
	[Enum.KeyCode.E] = "E",
	[Enum.KeyCode.F] = "F",
	[Enum.KeyCode.R] = "R",
}

local function build(prompt, inputType)
	local accent = prompt:GetAttribute("Color") or UI.C.white
	local bb = UI.new("BillboardGui", {
		Name = "Prompt",
		AlwaysOnTop = true,
		Size = UDim2.fromOffset(250, 74),
		StudsOffsetWorldSpace = Vector3.new(0, prompt:GetAttribute("OffsetY") or 0, 0),
		Adornee = prompt.Parent,
		Active = true,
		ResetOnSpawn = false,
		Parent = playerGui,
	})
	local pill = UI.new("TextButton", {
		Name = "Pill",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = UI.C.ink,
		BackgroundTransparency = 0.1,
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.fromOffset(4, 4),
		Parent = bb,
	})
	UI.corner(pill, 16)
	local st = UI.stroke(pill, 3, accent)
	-- hold bar along the bottom
	local barBack = UI.new("Frame", {
		BackgroundColor3 = Color3.fromRGB(60, 60, 70),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -24, 0, 6),
		Position = UDim2.new(0, 12, 1, -10),
		Visible = prompt.HoldDuration > 0,
		Parent = pill,
	})
	UI.corner(barBack, 3)
	local bar = UI.new("Frame", { BackgroundColor3 = UI.C.green, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), Parent = barBack })
	UI.corner(bar, 3)
	-- key badge
	local key = UI.new("Frame", {
		BackgroundColor3 = UI.C.white,
		Size = UDim2.fromOffset(46, 46),
		Position = UDim2.new(0, 10, 0.5, -4),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = pill,
	})
	UI.corner(key, 10)
	UI.stroke(key, 3)
	local keyText = inputType == Enum.ProximityPromptInputType.Touch and "TAP"
		or KEY_TEXT[prompt.KeyboardKeyCode] or prompt.KeyboardKeyCode.Name
	UI.label(key, { Text = keyText, Font = UI.BIG, TextColor3 = UI.C.ink, Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), stroke = 0 })
	UI.label(pill, {
		Text = prompt.ObjectText,
		TextColor3 = accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -78, 0, 22),
		Position = UDim2.fromOffset(66, 6),
		stroke = 2,
	})
	UI.label(pill, {
		Text = prompt.ActionText,
		Font = UI.BIG,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -78, 0, 30),
		Position = UDim2.fromOffset(66, 28),
		stroke = 2.5,
	})
	UI.pop(pill, 0.6)

	local conns = {}
	local holdTween
	table.insert(conns, prompt.PromptButtonHoldBegan:Connect(function()
		bar.Size = UDim2.fromScale(0, 1)
		holdTween = TweenService:Create(bar, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) })
		holdTween:Play()
		st.Color = UI.C.green
	end))
	table.insert(conns, prompt.PromptButtonHoldEnded:Connect(function()
		if holdTween then holdTween:Cancel() end
		bar.Size = UDim2.fromScale(0, 1)
		st.Color = accent
	end))
	table.insert(conns, prompt.Triggered:Connect(function()
		UI.punch(pill, 1.15)
	end))
	-- touch / click support
	table.insert(conns, pill.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldBegin()
		end
	end))
	table.insert(conns, pill.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldEnd()
		end
	end))
	return function()
		for _, c in conns do c:Disconnect() end
		bb:Destroy()
	end
end

ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then return end
	local cleanup = build(prompt, inputType)
	prompt.PromptHidden:Wait()
	cleanup()
end)
