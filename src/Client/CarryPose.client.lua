-- StarterPlayer.StarterPlayerScripts.CarryPose
-- Anyone carrying a kid overhead (a player stealing, a VexCorp goon, Crumpet) holds them up with both
-- hands: the server tags the carrier "CarryArms" (StudentFactory.raiseArms) and here, after the
-- animations have run each frame, the shoulders go up and the elbows bend a little, for every
-- tagged model on this client (so everyone sees the same thing). The legs keep walking.
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

-- joint -> the pose (in the joint's own space): arms up past the head, a little apart, elbows soft
local POSE = {
	RightShoulder = CFrame.Angles(math.rad(168), 0, math.rad(-14)),
	LeftShoulder = CFrame.Angles(math.rad(168), 0, math.rad(14)),
	RightElbow = CFrame.Angles(math.rad(22), 0, 0),
	LeftElbow = CFrame.Angles(math.rad(22), 0, 0),
}

local joints = {} -- model -> { joint instances }
local function jointsOf(m)
	local list = joints[m]
	if list then return list end
	list = {}
	for name in POSE do
		local j = m:FindFirstChild(name, true)
		if j and (j:IsA("Motor6D") or j.ClassName == "AnimationConstraint") then table.insert(list, j) end
	end
	joints[m] = list
	return list
end
CollectionService:GetInstanceRemovedSignal("CarryArms"):Connect(function(m) joints[m] = nil end)

RunService.Stepped:Connect(function()
	for _, m in CollectionService:GetTagged("CarryArms") do
		if m.Parent then
			for _, j in jointsOf(m) do
				local pose = POSE[j.Name]
				if pose then pcall(function() j.Transform = pose end) end
			end
		end
	end
end)
