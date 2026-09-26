-- ServerScriptService.Server.Stealth
-- Can a guard see (or hear) a player? One rule for every guard in the game (the VexCorp Factory's
-- security, the rival school's hall monitors), so sneaking and gear work the same everywhere:
--   walking      seen within `sight` studs in a `angle` degree cone (line of sight), heard within `hear`
--   sneaking     seen at 45% of the distance in a 70% cone, never heard
--   sprinting    heard 3.5x as far, through walls
--   in a box     invisible standing still; moving, seen only very close; never heard (Cardboard Box)
--   in smoke     invisible until it clears (Smoke Bomb: player attribute SmokeUntil, server time)
local Players = game:GetService("Players")

local Stealth = {}

local function moving(char)
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local v = root.AssemblyLinearVelocity
	return Vector3.new(v.X, 0, v.Z).Magnitude > 1.5
end
Stealth.moving = moving

-- eye: the guard's root part; base: { sight, angle, hear }; ignore: instances the sight ray skips
function Stealth.canSee(eye, char, base, ignore)
	local proot = char and char:FindFirstChild("HumanoidRootPart")
	if not eye or not proot then return false end
	local who = Players:GetPlayerFromCharacter(char)
	local mode = who and who:GetAttribute("Move")
	if who and (who:GetAttribute("SmokeUntil") or 0) > workspace:GetServerTimeNow() then return false end
	local boxed = who and who:GetAttribute("Boxed")
	if boxed and not moving(char) then return false end
	local d = proot.Position - eye.Position
	local flat = Vector3.new(d.X, 0, d.Z)
	local hear = (boxed or mode == "sneak") and 0 or (mode == "sprint" and base.hear * 3.5 or base.hear)
	local sight = base.sight * (boxed and 0.3 or mode == "sneak" and 0.45 or 1)
	local cone = base.angle * ((boxed or mode == "sneak") and 0.7 or 1)
	if flat.Magnitude < hear then return true end
	if flat.Magnitude > sight or flat.Magnitude < 1e-3 then return flat.Magnitude < 1e-3 end
	local look = Vector3.new(eye.CFrame.LookVector.X, 0, eye.CFrame.LookVector.Z)
	if look.Magnitude < 1e-3 then return false end
	if flat.Unit:Dot(look.Unit) < math.cos(math.rad(cone / 2)) then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip = { char }
	for _, i in ignore or {} do table.insert(skip, i) end
	params.FilterDescendantsInstances = skip
	local from = eye.Position + Vector3.new(0, 1.5, 0)
	local hit = workspace:Raycast(from, (proot.Position + Vector3.new(0, 1, 0)) - from, params)
	return hit == nil
end

return Stealth
