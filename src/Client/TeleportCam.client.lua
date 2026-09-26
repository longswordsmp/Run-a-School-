-- StarterPlayerScripts.TeleportCam
-- After a teleport (down a ladder, up through a grate, sent back to the office, into a building) the
-- camera would keep looking wherever it looked before. In a small room that can be straight at the wall
-- behind you, with the camera squashed into the back of your head (the Headmaster's office did exactly
-- that: all you saw was your own hair, and the prompts in front of you never showed). So when you jump
-- more than 20 studs in one frame, the camera swings round behind you, looking the way the teleport
-- faced you. Only with the normal camera: cutscenes (Scriptable) are left alone.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local JUMP = 20
local PITCH = -0.3 -- (looking a little down, like the default camera)

local last
local function behind(root)
	local cam = workspace.CurrentCamera
	if not cam or cam.CameraType ~= Enum.CameraType.Custom then return end
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.1 then return end
	local dir = (flat.Unit + Vector3.new(0, PITCH, 0)).Unit
	local focus = root.Position + Vector3.new(0, 1.5, 0)
	-- (the camera module keeps this direction and puts its own zoom distance back on it)
	cam.CFrame = CFrame.lookAt(focus - dir * 12, focus)
end

RunService.RenderStepped:Connect(function()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		last = nil
		return
	end
	local pos = root.Position
	if last and (pos - last).Magnitude > JUMP then behind(root) end
	last = pos
end)

player.CharacterAdded:Connect(function() last = nil end)
