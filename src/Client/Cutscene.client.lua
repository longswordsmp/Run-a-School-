-- StarterPlayer.StarterPlayerScripts.Cutscene
-- Client cutscenes fired by Remotes.Cutscene(name, data).
--   Board: the School Board meets in the Board Room (workspace.BoardRoom, high above the map),
--          bangs the gavel and approves your school while the server rebuilds it underneath.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local bus = ReplicatedStorage:WaitForChild("ClientBus", 10)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local gui = UI.new("ScreenGui", {
	Name = "Cutscene",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 50,
	Parent = player:WaitForChild("PlayerGui"),
})
local black = UI.new("Frame", {
	Name = "Black",
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 1,
	Parent = gui,
})
-- letterbox bars
local bars = {}
for i, y in { 0, 1 } do
	bars[i] = UI.new("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		AnchorPoint = Vector2.new(0, y),
		Position = UDim2.fromScale(0, y),
		Size = UDim2.new(1, 0, 0, 0),
		ZIndex = 2,
		Parent = gui,
	})
end

local function sfx(name, pos)
	if bus and bus:FindFirstChild("Sfx") then bus.Sfx:Fire(name, pos) end
end

local function fade(to, t)
	local tw = TweenService:Create(black, TweenInfo.new(t or 0.35), { BackgroundTransparency = to })
	tw:Play()
	tw.Completed:Wait()
end

local function letterbox(on)
	for _, b in bars do
		TweenService:Create(b, TweenInfo.new(0.4), { Size = UDim2.new(1, 0, on and 0.11 or 0, 0) }):Play()
	end
end

local function caption(text, color, y, size)
	local t = UI.label(gui, {
		Text = text,
		Font = UI.BIG,
		TextColor3 = color or Color3.new(1, 1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, y or 0.8),
		Size = UDim2.new(0.8, 0, 0, size or 60),
		ZIndex = 5,
		stroke = 4,
	})
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(1000, size or 60), Parent = t })
	UI.pop(t, 0.3)
	return t
end

-- confetti: small coloured squares falling over the screen
local function confetti(n)
	local colors = { UI.C.red, UI.C.blue, UI.C.green, UI.C.yellow, UI.C.pink, UI.C.purple, UI.C.orange }
	for _ = 1, n do
		local s = math.random(8, 16)
		local f = UI.new("Frame", {
			BackgroundColor3 = colors[math.random(#colors)],
			Size = UDim2.fromOffset(s, s * 0.6),
			Position = UDim2.new(math.random(), 0, -0.05, 0),
			Rotation = math.random(0, 360),
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = gui,
		})
		local t = 1.6 + math.random() * 1.4
		TweenService:Create(f, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(f.Position.X.Scale + (math.random() - 0.5) * 0.2, 0, 1.05, 0),
			Rotation = f.Rotation + math.random(-360, 360),
		}):Play()
		task.delay(t, function() f:Destroy() end)
	end
end

-- a stand-in of the player at the podium (a local clone of their character)
local function standIn(at)
	local char = player.Character
	if not char then return nil end
	char.Archivable = true
	local ok, clone = pcall(function() return char:Clone() end)
	if not ok or not clone then return nil end
	for _, d in clone:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
		if d:IsA("BasePart") then d.Anchored = true end
	end
	local hum = clone:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
	clone:PivotTo(at)
	clone.Parent = workspace
	return clone
end

-- hide the game's own HUD and menus while a cutscene plays
local hidden = {}
local function hideHud(on)
	local pg = player:FindFirstChild("PlayerGui")
	if not pg then return end
	if on then
		for _, name in { "HUD", "Menus", "NowPlaying", "Prompts" } do
			local g = pg:FindFirstChild(name)
			if g and g.Enabled then
				g.Enabled = false
				hidden[g] = true
			end
		end
	else
		for g in hidden do
			if g.Parent then g.Enabled = true end
		end
		hidden = {}
	end
end

local busy = false
local function board(data)
	if busy then return end
	busy = true
	local room = workspace:FindFirstChild("BoardRoom")
	if not room then busy = false return end
	player:SetAttribute("LocalMusic", "board")
	fade(0, 0.35)
	hideHud(true)
	letterbox(true)
	local mark = room.PlayerMark
	local podiumLook = CFrame.lookAt(mark.Position + Vector3.new(0, 0.1, 0), room.Table.Position * Vector3.new(1, 0, 1) + Vector3.new(0, mark.Position.Y + 0.1, 0))
	local double = standIn(podiumLook)
	local prevType, prevCF = camera.CameraType, camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	local target = room.Table.Position + Vector3.new(0, 1.5, 0)
	camera.CFrame = CFrame.lookAt(room.CameraA.Position, target)
	fade(1, 0.35)
	local c1 = caption("THE SCHOOL BOARD IS IN SESSION", Color3.fromRGB(255, 225, 120), 0.8, 54)
	sfx("Gavel")
	-- slow push toward the table
	TweenService:Create(camera, TweenInfo.new(1.6, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(room.CameraA.Position:Lerp(target, 0.35), target) }):Play()
	task.wait(1.5)
	c1:Destroy()
	-- close on the chair and the gavel
	camera.CFrame = CFrame.lookAt(room.CameraB.Position, room.Gavel.Position + Vector3.new(-2, 1.5, 0))
	local gavel = room.Gavel
	local g0 = gavel.CFrame
	TweenService:Create(gavel, TweenInfo.new(0.15), { CFrame = g0 * CFrame.new(0, 1.2, 0) * CFrame.Angles(math.rad(-40), 0, 0) }):Play()
	task.wait(0.2)
	TweenService:Create(gavel, TweenInfo.new(0.08), { CFrame = g0 }):Play()
	task.wait(0.08)
	sfx("GavelBig")
	-- a quick camera shake on the bang
	local shakeUntil = os.clock() + 0.25
	local base = camera.CFrame
	local conn = RunService.RenderStepped:Connect(function()
		if os.clock() < shakeUntil then
			camera.CFrame = base * CFrame.new((math.random() - 0.5) * 0.3, (math.random() - 0.5) * 0.3, 0)
		end
	end)
	task.wait(0.3)
	conn:Disconnect()
	-- approved!
	camera.CFrame = CFrame.lookAt(room.CameraA.Position:Lerp(target, 0.5), mark.Position + Vector3.new(0, 2, 0))
	sfx("StingParty")
	local c2 = caption("APPROVED!", UI.C.green, 0.42, 96)
	local c3 = caption(("Welcome to %s!"):format((data and data.name) or "your new school"), Color3.new(1, 1, 1), 0.56, 48)
	confetti(90)
	task.wait(1.9)
	fade(0, 0.35)
	c2:Destroy()
	c3:Destroy()
	if double then double:Destroy() end
	camera.CameraType = prevType
	camera.CFrame = prevCF
	letterbox(false)
	hideHud(false)
	player:SetAttribute("LocalMusic", nil)
	task.wait(0.4)
	fade(1, 0.5)
	sfx("Cheer")
	busy = false
end

Remotes:WaitForChild("Cutscene").OnClientEvent:Connect(function(name, data)
	if name == "Board" then
		task.spawn(board, data)
	end
end)
