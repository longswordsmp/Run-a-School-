-- StarterPlayer.StarterPlayerScripts.Movement
-- Sprint and sneak on this client (the server decides: MoveService).
--   keyboard  hold SHIFT to sprint, press C to sneak (again to stand)
--   gamepad   hold L3 to sprint, press R3 to sneak
--   phone     SPRINT (hold) and SNEAK (tap) buttons above the jump button
-- Shows the stamina bar when it isn't full, a SNEAKING tag and dark screen edges while sneaking, and
-- in the VexCorp Factory a HIDDEN / SPOTTED! eye. Everyone sneaking crouches (posed on every client).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")

local player = Players.LocalPlayer

---------------------------------------------------------------------------
-- asking the server
---------------------------------------------------------------------------
local want = nil -- what the player is asking for: "sprint" / "sneak" / nil
local sneakToggled = false
local sprintHeld = false
local function send()
	local mode = sprintHeld and "sprint" or (sneakToggled and "sneak" or nil)
	if mode == want then return end
	want = mode
	task.spawn(function() pcall(Action.InvokeServer, Action, "move", mode) end)
end
local function setSprint(on)
	sprintHeld = on
	if on then sneakToggled = false end
	send()
end
local function toggleSneak()
	sneakToggled = not sneakToggled
	if sneakToggled then sprintHeld = false end
	send()
end
-- the server can drop a sprint (out of stamina): stop asking for it until the key is pressed again
player:GetAttributeChangedSignal("Move"):Connect(function()
	local m = player:GetAttribute("Move")
	if want == "sprint" and m ~= "sprint" and player:GetAttribute("Winded") then
		sprintHeld = false
		want = nil
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.LeftShift or k == Enum.KeyCode.RightShift or k == Enum.KeyCode.ButtonL3 then
		setSprint(true)
	elseif k == Enum.KeyCode.C or k == Enum.KeyCode.ButtonR3 then
		toggleSneak()
	end
end)
UserInputService.InputEnded:Connect(function(input)
	local k = input.KeyCode
	if k == Enum.KeyCode.LeftShift or k == Enum.KeyCode.RightShift or k == Enum.KeyCode.ButtonL3 then
		setSprint(false)
	end
end)
player.CharacterAdded:Connect(function()
	sprintHeld, sneakToggled, want = false, false, nil
end)

---------------------------------------------------------------------------
-- the HUD bits
---------------------------------------------------------------------------
local gui = UI.new("ScreenGui", { Name = "Movement", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 5, Parent = player:WaitForChild("PlayerGui") })
local root = UI.autoScale(gui)

-- dark edges while sneaking: four strips fading in from the screen edges
local vignette = UI.new("Frame", { Name = "Vignette", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 0, Parent = gui })
local edges = {}
for _, e in {
	{ UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0), 90 },
	{ UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0.78), -90 },
	{ UDim2.fromScale(0.16, 1), UDim2.fromScale(0, 0), 0 },
	{ UDim2.fromScale(0.16, 1), UDim2.fromScale(0.84, 0), 180 },
} do
	local f = UI.new("Frame", { Size = e[1], Position = e[2], BackgroundColor3 = Color3.fromRGB(12, 6, 34), BorderSizePixel = 0, BackgroundTransparency = 1, Parent = vignette })
	UI.new("UIGradient", {
		Rotation = e[3],
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) }),
		Parent = f,
	})
	table.insert(edges, f)
end

-- stamina, just above the cash chips
local stamina = UI.new("Frame", { Name = "Stamina", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -142), Size = UDim2.fromOffset(250, 34), BackgroundTransparency = 1, Parent = root })
local icon = UI.label(stamina, { Text = "\u{1F3C3}", Size = UDim2.fromOffset(34, 34), stroke = 0 })
local back = UI.new("Frame", { Position = UDim2.fromOffset(40, 9), Size = UDim2.new(1, -40, 0, 16), BackgroundColor3 = Color3.fromRGB(30, 34, 64), BackgroundTransparency = 0.2, Parent = stamina })
UI.corner(back, 8)
local backStroke = UI.stroke(back, 2.5)
local fill = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.C.green, Parent = back })
UI.corner(fill, 8)
local winded = UI.label(stamina, { Text = "WINDED", Font = UI.BIG, TextColor3 = UI.C.red, Size = UDim2.fromOffset(120, 22), Position = UDim2.new(0.5, 20, 0, -22), AnchorPoint = Vector2.new(0.5, 0), Visible = false, stroke = 2 })

-- SNEAKING tag
local sneakTag = UI.new("Frame", { Name = "Sneak", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -182), Size = UDim2.fromOffset(170, 34), BackgroundColor3 = Color3.fromRGB(40, 28, 80), Visible = false, Parent = root })
UI.corner(sneakTag, 17)
UI.stroke(sneakTag, 2.5)
UI.label(sneakTag, { Text = "\u{1F977} SNEAKING", Font = UI.BIG, Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), TextColor3 = Color3.fromRGB(210, 190, 255), stroke = 2 })

-- the Factory eye: HIDDEN / SPOTTED!
local eye = UI.new("Frame", { Name = "Eye", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -224), Size = UDim2.fromOffset(210, 44), BackgroundColor3 = Color3.fromRGB(40, 40, 60), Visible = false, Parent = root })
UI.corner(eye, 22)
local eyeStroke = UI.stroke(eye, 3)
local eyeText = UI.label(eye, { Text = "", Font = UI.BIG, Size = UDim2.new(1, -20, 1, -10), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), stroke = 2 })
local keys = UI.label(root, { Name = "Keys", Text = "Hold SHIFT to sprint  \u{2022}  press C to sneak", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -272), Size = UDim2.fromOffset(460, 26), TextColor3 = Color3.fromRGB(230, 230, 245), Visible = false, stroke = 2 })

-- phone buttons: SPRINT (hold) and SNEAK (tap), left of the jump button
local mobileFrame = UI.new("Frame", { Name = "TouchButtons", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -150, 1, -30), Size = UDim2.fromOffset(250, 230), Visible = false, Parent = gui })
local function roundButton(name, icon, caption, color, pos)
	local b = UI.new("TextButton", { Name = name, Text = "", AutoButtonColor = false, BackgroundColor3 = color, BackgroundTransparency = 0.1, Position = pos, Size = UDim2.fromOffset(96, 96), Parent = mobileFrame })
	UI.corner(b, 48)
	UI.stroke(b, 3.5)
	UI.gradient(b, UI.lighten and UI.lighten(color, 0.3) or color, color)
	UI.label(b, { Text = icon, Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0.5, 0, 0, 12), AnchorPoint = Vector2.new(0.5, 0), stroke = 0 })
	UI.label(b, { Text = caption, Font = UI.BIG, Size = UDim2.new(1, -12, 0, 22), Position = UDim2.new(0.5, 0, 1, -30), AnchorPoint = Vector2.new(0.5, 0), stroke = 2 })
	return b
end
local sprintBtn = roundButton("Sprint", "\u{1F3C3}", "SPRINT", Color3.fromRGB(255, 140, 50), UDim2.fromOffset(140, 0))
local sneakBtn = roundButton("Sneak", "\u{1F977}", "SNEAK", Color3.fromRGB(120, 80, 220), UDim2.fromOffset(20, 110))
sprintBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then setSprint(true) end
end)
sprintBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then setSprint(false) end
end)
sneakBtn.Activated:Connect(toggleSneak)
local function refreshDevice()
	local mobile = player:GetAttribute("Device") == "mobile" or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
	mobileFrame.Visible = mobile
	keys.Text = mobile and "SPRINT to run  \u{2022}  SNEAK to creep past guards" or "Hold SHIFT to sprint  \u{2022}  press C to sneak"
end
player:GetAttributeChangedSignal("Device"):Connect(refreshDevice)
refreshDevice()

---------------------------------------------------------------------------
-- every frame: the bars, the tags, the crouch
---------------------------------------------------------------------------
local ZONES = require(Shared:WaitForChild("Config")).SecureZones -- the Factory, the Lab, Vex Prep
local staminaShown = 0
local camOffset = 0
local vig = 1

-- a crouch on top of whatever the walk/idle animation is doing (every sneaking character)
local function crouch(char, k)
	local function j(part, name)
		local p = char:FindFirstChild(part)
		return p and p:FindFirstChild(name)
	end
	local rootJ, waist = j("LowerTorso", "Root"), j("UpperTorso", "Waist")
	local lh, rh, lk, rk = j("LeftUpperLeg", "LeftHip"), j("RightUpperLeg", "RightHip"), j("LeftLowerLeg", "LeftKnee"), j("RightLowerLeg", "RightKnee")
	if not (rootJ and waist and lh and rh and lk and rk) then return end
	-- (Motor6D on classic rigs, AnimationConstraint on newer avatars: both have a Transform)
	rootJ.Transform = CFrame.new(0, -0.75 * k, 0) * rootJ.Transform
	waist.Transform = waist.Transform * CFrame.Angles(math.rad(-22) * k, 0, 0)
	lh.Transform = lh.Transform * CFrame.Angles(math.rad(62) * k, 0, 0)
	rh.Transform = rh.Transform * CFrame.Angles(math.rad(62) * k, 0, 0)
	lk.Transform = lk.Transform * CFrame.Angles(math.rad(-78) * k, 0, 0)
	rk.Transform = rk.Transform * CFrame.Angles(math.rad(-78) * k, 0, 0)
end
local crouchK = setmetatable({}, { __mode = "k" })

RunService.Stepped:Connect(function(_, dt)
	for _, pl in Players:GetPlayers() do
		local char = pl.Character
		if char then
			local target = pl:GetAttribute("Move") == "sneak" and 1 or 0
			local k = crouchK[char] or 0
			k += (target - k) * math.min(1, dt * 10)
			crouchK[char] = k
			if k > 0.01 then crouch(char, k) end
		end
	end
end)

RunService.RenderStepped:Connect(function(dt)
	local st = player:GetAttribute("Stamina") or 100
	local mode = player:GetAttribute("Move")
	local isWinded = player:GetAttribute("Winded") == true
	-- stamina bar: shown while it isn't full
	local show = (st < 99 or mode == "sprint") and 1 or 0
	staminaShown += (show - staminaShown) * math.min(1, dt * 8)
	stamina.Visible = staminaShown > 0.02
	for _, o in { back, fill } do o.BackgroundTransparency = 1 - staminaShown * (o == back and 0.8 or 1) end
	backStroke.Transparency = 1 - staminaShown
	icon.TextTransparency = 1 - staminaShown
	fill.Size = UDim2.fromScale(math.clamp(st / 100, 0, 1), 1)
	fill.BackgroundColor3 = isWinded and UI.C.red or (st < 35 and UI.C.orange or UI.C.green)
	winded.Visible = isWinded and staminaShown > 0.5
	-- sneaking: tag, dark edges, the camera lower
	local sneaking = mode == "sneak"
	sneakTag.Visible = sneaking
	vig += ((sneaking and 0.25 or 1) - vig) * math.min(1, dt * 6)
	for _, f in edges do f.BackgroundTransparency = vig end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		camOffset += ((sneaking and -1.1 or 0) - camOffset) * math.min(1, dt * 8)
		hum.CameraOffset = Vector3.new(0, camOffset, 0)
	end
	-- in the Factory grounds: the eye, and the keys to press
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local p = r and r.Position
	local inLot = false
	if p then
		for _, z in ZONES do
			if p.X > z.x0 and p.X < z.x1 and p.Z > z.z0 and p.Z < z.z1 then inLot = true break end
		end
	end
	eye.Visible = inLot == true
	keys.Visible = inLot == true and not sneaking
	if inLot then
		local spotted = player:GetAttribute("Spotted") == true
		eyeText.Text = spotted and "\u{1F441}\u{FE0F} SPOTTED!" or "\u{1F441}\u{FE0F} HIDDEN"
		eye.BackgroundColor3 = spotted and Color3.fromRGB(200, 40, 50) or Color3.fromRGB(40, 40, 60)
		eyeStroke.Color = spotted and Color3.fromRGB(255, 220, 220) or Color3.fromRGB(0, 0, 0)
		local sc = eye:FindFirstChildOfClass("UIScale") or UI.new("UIScale", { Parent = eye })
		sc.Scale = spotted and (1 + math.abs(math.sin(os.clock() * 8)) * 0.08) or 1
	end
end)

---------------------------------------------------------------------------
-- the Lockpick Set: grab kids (pens, desks, Vex's desk) in half the hold time
---------------------------------------------------------------------------
local GRAB = { RescuePrompt = true, PlansPrompt = true, StealPrompt = true }
local function fixHold(prompt)
	if not prompt:IsA("ProximityPrompt") or not GRAB[prompt.Name] then return end
	local base = prompt:GetAttribute("BaseHold")
	if not base then
		base = prompt.HoldDuration
		prompt:SetAttribute("BaseHold", base)
	end
	prompt.HoldDuration = player:GetAttribute("Lockpick") and base * 0.5 or base
end
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("ProximityPrompt") then task.defer(fixHold, d) end
end)
local function fixAll()
	for _, d in workspace:GetDescendants() do
		if d:IsA("ProximityPrompt") then fixHold(d) end
	end
end
player:GetAttributeChangedSignal("Lockpick"):Connect(fixAll)
task.defer(fixAll)

_ = TweenService
