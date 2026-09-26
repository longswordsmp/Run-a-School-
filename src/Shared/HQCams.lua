-- ReplicatedStorage.Shared.HQCams
-- The Server Farm's security cameras (HQ floor 4) as functions of the server clock: the client turns
-- the camera heads and their spotlights, the server turns an invisible eye the same way and asks
-- Stealth.canSee (so sneaking, the cardboard box and smoke work on cameras too).
-- A camera is a part with attributes: Yaw (degrees, 0 = +x), Sweep (degrees either side),
-- Period (seconds), Phase, Range (studs), Angle (the cone, degrees).
local HQCams = {}

function HQCams.yaw(part, t)
	local center = math.rad(part:GetAttribute("Yaw") or 0)
	local sweep = math.rad(part:GetAttribute("Sweep") or 35)
	local period = part:GetAttribute("Period") or 6
	local phase = part:GetAttribute("Phase") or 0
	return center + sweep * math.sin((t + phase) / period * math.pi * 2)
end

-- the camera's CFrame at time t: at pos, looking along the yaw and a little down
function HQCams.cf(pos, part, t)
	local a = HQCams.yaw(part, t)
	local dir = Vector3.new(math.cos(a), -0.35, math.sin(a)).Unit
	return CFrame.lookAt(pos, pos + dir)
end

return HQCams
