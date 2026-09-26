-- StarterPlayer.StarterPlayerScripts.AdminTools
-- The admin panel's fly and noclip (AdminService sets the player attributes; only admins can).
--   AdminFly     fly where the camera looks: WASD / the thumbstick, Space up, Ctrl or Q down,
--                Shift three times as fast
--   AdminNoclip  walk through walls
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local FLY_SPEED = 70

-- the movement stick, when the game has Roblox's PlayerModule (else WASD straight from the keyboard)
local controls
task.spawn(function()
	local pm = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10)
	if not pm then return end
	local ok, mod = pcall(function() return require(pm):GetControls() end)
	if ok then controls = mod end
end)
local function keyboardMove()
	local x, z = 0, 0
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then z -= 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then z += 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then x -= 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then x += 1 end
	return Vector3.new(x, 0, z)
end

local flying -- { lv, ao, att }
local function stopFly()
	if not flying then return end
	for _, x in flying do
		if typeof(x) == "Instance" then x:Destroy() end
	end
	flying = nil
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
	end
end

local function startFly()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (root and hum) then return end
	stopFly()
	local att = Instance.new("Attachment")
	att.Name = "AdminFly"
	att.Parent = root
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.MaxForce = math.huge
	lv.VectorVelocity = Vector3.zero
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Parent = root
	local ao = Instance.new("AlignOrientation")
	ao.Attachment0 = att
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.MaxTorque = math.huge
	ao.Responsiveness = 60
	ao.CFrame = root.CFrame.Rotation
	ao.Parent = root
	hum.PlatformStand = true
	flying = { att, lv, ao }
end

local function held(...)
	for _, k in { ... } do
		if UserInputService:IsKeyDown(k) then return true end
	end
	return false
end

RunService.RenderStepped:Connect(function()
	local want = player:GetAttribute("AdminFly") == true
	if want and not flying then startFly() elseif not want and flying then stopFly() end
	if flying then
		local cam = workspace.CurrentCamera
		local move = controls and controls:GetMoveVector() or keyboardMove()
		-- (the move vector is camera-relative: x right, z back)
		local dir = cam.CFrame.RightVector * move.X - cam.CFrame.LookVector * move.Z
		if held(Enum.KeyCode.Space) then dir += Vector3.yAxis end
		if held(Enum.KeyCode.LeftControl, Enum.KeyCode.Q) then dir -= Vector3.yAxis end
		local speed = FLY_SPEED * (held(Enum.KeyCode.LeftShift) and 3 or 1)
		flying[2].VectorVelocity = dir.Magnitude > 0.01 and dir.Unit * speed or Vector3.zero
		local look = cam.CFrame.LookVector
		flying[3].CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(look.X, 0, look.Z).Magnitude > 0.01 and Vector3.new(look.X, 0, look.Z) or Vector3.new(0, 0, -1))
	end
end)

-- noclip: the character's parts stop colliding, every physics step (and collide again after)
local solid = {} -- parts that collided before noclip went on
RunService.Stepped:Connect(function()
	local char = player.Character
	if not char then return end
	if not player:GetAttribute("AdminNoclip") then
		if next(solid) then
			for p in solid do
				if p.Parent then p.CanCollide = true end
			end
			table.clear(solid)
		end
		return
	end
	for _, p in char:GetDescendants() do
		if p:IsA("BasePart") and p.CanCollide then
			solid[p] = true
			p.CanCollide = false
		end
	end
end)

player.CharacterAdded:Connect(function()
	flying = nil
	table.clear(solid)
end)
