-- StarterPlayer.StarterPlayerScripts.HoverRide
-- Everyone on a hoverboard (GearService puts the model HoverboardRide in their character), as this
-- client sees them. Instead of running on the spot on the board: a surf stance, the body side-on with
-- the right foot forward, knees bent, arms out for balance, head turned to look ahead. The board bobs on
-- its thrusters and banks into turns, and the rider leans with it. All of it is local (Motor6D.Transform
-- and a weld's C0 set here don't replicate), so every client does it for every rider it can see.
-- (R15 joints: the character faces -Z; turning a joint about +Z swings a hanging limb towards +X, the
-- character's right; about +X swings it forward.)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local rad, sin, clamp = math.rad, math.sin, math.clamp

local STANCE = rad(72) -- the body turned side-on (counterclockwise: the right side leads)
local DROP = 0.5 -- how far the hips sink as the knees bend
local FLEX = 30 -- hip flex in degrees (the knees bend 1.7 times that)
local LEAD, TRAIL = 70, 38 -- the leading arm up and out, the trailing one low
local BOB = 0.07 -- the board rides up and down on its thrusters this much
local BANK = 0.16 -- lean per radian a second of turning
local MAX_BANK = rad(20)
local TRICK = 0.6 -- seconds a jump's spin takes

local riders = {} -- [character] = { motors, weld, base, yaw, roll, t }

-- the body's own joints only: rigged accessories (animated heads, little figures) carry joints with the
-- same names (Root, Neck, LeftShoulder...), and posing those left the body running on the board. A
-- joint is a Motor6D, or with Roblox's avatar joint upgrade an AnimationConstraint (both have Transform).
local function motorsOf(char)
	local m = {}
	for _, part in char:GetChildren() do
		if part:IsA("BasePart") then
			for _, d in part:GetChildren() do
				if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then m[d.Name] = d end
			end
		end
	end
	return m
end

local function yawOf(cf)
	local look = cf.LookVector
	return math.atan2(-look.X, -look.Z)
end

local function pose(m, name, cf)
	local j = m[name]
	if j then j.Transform = cf end
end

RunService.Stepped:Connect(function(_, dt)
	dt = math.max(dt, 1 / 240)
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local board = char and char:FindFirstChild("HoverboardRide")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local weld = board and board.PrimaryPart and board.PrimaryPart:FindFirstChild("HoverWeld")
		if not (board and root and weld) then
			if char then riders[char] = nil end
			continue
		end
		local r = riders[char]
		if not r or r.weld ~= weld then
			r = { motors = motorsOf(char), weld = weld, base = weld.C0, yaw = yawOf(root.CFrame), roll = 0, pitch = 0, t = math.random() * 6 }
			riders[char] = r
		end
		r.t += dt

		-- banking: how fast they're turning (counterclockwise is a left turn: lean left, into it)
		local yaw = yawOf(root.CFrame)
		local dyaw = (yaw - r.yaw + math.pi) % (2 * math.pi) - math.pi
		r.yaw = yaw
		local roll = clamp(dyaw / dt * BANK, -MAX_BANK, MAX_BANK)
		local v = root.AssemblyLinearVelocity
		local speed = Vector3.new(v.X, 0, v.Z).Magnitude
		-- (nose up a touch at speed, like it's riding a cushion of air)
		local pitch = clamp(speed / 40, 0, 1) * rad(5)
		local k = math.min(1, dt * 6)
		r.roll += (roll - r.roll) * k
		r.pitch += (pitch - r.pitch) * k
		local bob = sin(r.t * 2.6) * BOB

		-- a jump is a trick: the board and the rider spin a full turn together while in the air, with a
		-- tuck of the knees (a rising root is a jump: nothing else lifts a rider that fast)
		if not r.trick and v.Y > 9 and (not r.trickEnd or r.t - r.trickEnd > 0.4) then r.trick = 0 end
		local spin, tuck = 0, 0
		if r.trick then
			r.trick += dt
			local a = math.min(1, r.trick / TRICK)
			spin = (a * a * (3 - 2 * a)) * math.pi * 2
			tuck = sin(a * math.pi)
			if a >= 1 then
				r.trick = nil
				r.trickEnd = r.t
			end
		end

		-- the board: bob, bank, nose up (its -Z is the front, so rolling is about Z)
		-- (+ about Z tips the top towards -X, the left: a left turn banks left)
		weld.C0 = r.base * CFrame.new(0, bob, 0) * CFrame.Angles(0, spin, 0) * CFrame.Angles(r.pitch, 0, r.roll)

		-- the rider: sunk into bent knees, turned side-on, banked with the board
		local m = r.motors
		local flex = FLEX + sin(r.t * 2.6) * 4 + tuck * 30 -- (the knees soak up the bob, and tuck in a trick)
		pose(m, "Root", CFrame.new(0, -DROP + bob - tuck * 0.3, 0) * CFrame.Angles(0, spin, 0) * CFrame.Angles(0, 0, r.roll) * CFrame.Angles(0, STANCE, 0))
		pose(m, "Waist", CFrame.Angles(rad(8), rad(-14), 0))
		pose(m, "Neck", CFrame.Angles(rad(-6), rad(-52), 0))
		-- legs apart along the board (which runs across the body now), knees bent, feet flat
		for _, side in { { "Left", -1, TRAIL }, { "Right", 1, LEAD } } do
			local n, s, arm = side[1], side[2], side[3]
			pose(m, n .. "Hip", CFrame.Angles(rad(flex), 0, s * rad(17)))
			pose(m, n .. "Knee", CFrame.Angles(rad(-flex * 1.7), 0, 0))
			pose(m, n .. "Ankle", CFrame.Angles(rad(flex * 0.7), 0, -s * rad(17)))
			-- arms out for balance (the leading one higher), elbows soft, swaying a little
			local sway = sin(r.t * 1.3 + s) * 4
			pose(m, n .. "Shoulder", CFrame.Angles(rad(12), 0, s * rad(arm + sway)))
			pose(m, n .. "Elbow", CFrame.Angles(rad(28), 0, 0))
			pose(m, n .. "Wrist", CFrame.identity)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if player.Character then riders[player.Character] = nil end
end)

-- the rush: while you ride fast, the camera's view widens a little (and settles back when you stop or
-- step off). Only for your own board, and never while a cutscene has the camera.
local me = Players.LocalPlayer
local baseFov
RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if not cam or cam.CameraType ~= Enum.CameraType.Custom then return end
	local char = me.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local riding = root and char:FindFirstChild("HoverboardRide") ~= nil
	if riding and not baseFov then baseFov = cam.FieldOfView end
	if not baseFov then return end
	local target = baseFov
	if riding then
		local v = root.AssemblyLinearVelocity
		target = baseFov + clamp((Vector3.new(v.X, 0, v.Z).Magnitude - 20) / 40, 0, 1) * 12
	end
	cam.FieldOfView += (target - cam.FieldOfView) * math.min(1, dt * 4)
	if not riding and math.abs(cam.FieldOfView - baseFov) < 0.05 then
		cam.FieldOfView = baseFov
		baseFov = nil
	end
end)
