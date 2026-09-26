-- ReplicatedStorage.Shared.HQLasers
-- The Laser Vault's lasers (HQ floor 3) as pure functions of time, so the client can animate them
-- smoothly and the server can check hits with the same maths (t = workspace:GetServerTimeNow()).
-- A laser is a part with attributes:
--   Laser = "blink"   Period, Phase, On (fraction of the period it's lit)      a beam that flicks on/off
--   Laser = "tile"    Period, Phase, On                                          a floor tile that glows hot
--   Laser = "spin"    Period, Radius (the beam turns round its part's position)  a sweeping beam to jump over
local HQLasers = {}

function HQLasers.isOn(part, t)
	local period = part:GetAttribute("Period") or 3
	local phase = part:GetAttribute("Phase") or 0
	local on = part:GetAttribute("On") or 0.5
	return ((t + phase) % period) / period < on
end

-- the spinner's angle (radians) at time t
function HQLasers.angle(part, t)
	local period = part:GetAttribute("Period") or 6
	return ((t + (part:GetAttribute("Phase") or 0)) % period) / period * math.pi * 2
end

-- is a body (feet .. head, radius r) standing at pos touching this laser?
-- base: the laser's resting CFrame (blink beams and tiles don't move; the spinner turns about it)
function HQLasers.hits(part, base, t, pos, feetY, headY, r)
	local kind = part:GetAttribute("Laser")
	if kind == "blink" then
		if not HQLasers.isOn(part, t) then return false end
		-- a beam: a thin box; test the body's axis against it grown by r
		local lp = base:PointToObjectSpace(Vector3.new(pos.X, (base.Position.Y), pos.Z))
		local half = part.Size / 2
		local by = base.Position.Y
		if by < feetY - 0.2 or by > headY + 0.2 then return false end
		return math.abs(lp.X) <= half.X + r and math.abs(lp.Z) <= half.Z + r
	elseif kind == "tile" then
		if not HQLasers.isOn(part, t) then return false end
		local half = part.Size / 2
		local top = base.Position.Y + half.Y
		if feetY > top + 1.2 then return false end -- (jumping over a hot tile is fine)
		return math.abs(pos.X - base.Position.X) <= half.X - 0.3 and math.abs(pos.Z - base.Position.Z) <= half.Z - 0.3
	elseif kind == "spin" then
		local y = base.Position.Y
		if feetY > y + 0.4 or headY < y then return false end
		local a = HQLasers.angle(part, t)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local v = Vector3.new(pos.X - base.Position.X, 0, pos.Z - base.Position.Z)
		local along = v:Dot(dir)
		local radius = part:GetAttribute("Radius") or 16
		if along < 0 or along > radius then return false end
		local off = (v - dir * along).Magnitude
		return off <= r + 0.3
	end
	return false
end

-- where the spinner's beam part sits at time t (its middle is half a radius out from the hub)
function HQLasers.spinCF(part, base, t)
	local a = HQLasers.angle(part, t)
	local radius = part:GetAttribute("Radius") or 16
	local dir = Vector3.new(math.cos(a), 0, math.sin(a))
	local mid = base.Position + dir * (radius / 2)
	return CFrame.lookAt(mid, mid + dir)
end

return HQLasers
