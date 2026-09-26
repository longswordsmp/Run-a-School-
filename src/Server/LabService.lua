-- ServerScriptService.Server.LabService
-- VexCorp Mutation Lab (the far west end of Recess Row, north side): where Vex's Homework Machine
-- turns kids into Mutants. Break one out of its tube and get it off the grounds: it's yours, as a
-- Mutated kid (x6 tuition, green, glowing). The Lab is the hardest place on the street:
--   the laser hall   three laser curtains: one blinks, one sits at knee height (jump it), one sweeps
--   cameras          two security cameras sweep the lab floor; being seen by one sets off the alarm
--   hazmat guards    two, patrolling, with the same eyes and ears as every guard (Guards / Stealth)
--   the alarm        everyone chases you; red lights; the tube you broke is empty for 10 minutes
-- Also here: two terminals and the Mutagen Vat (Stan's secret missions: SecretService), and a few of
-- the VexCorp Files (FilesService).
-- Stolen mutants: carried over your head (Heist attribute: the carry speed), dropped if caught,
-- teleported, killed; escaping the fence delivers them to your Waiting Bench.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Factory = require(script.Parent.StudentFactory)
local StealService = require(script.Parent.StealService)
local Guards = require(script.Parent.Guards)

local LabService = {}

local rgb = Color3.fromRGB
local function now() return os.clock() end

-- the compound (world space; the street runs along X at z = 0)
local LOT = { x0 = -474, x1 = -366, z0 = 42, z1 = 150 }
local B = { x0 = -462, x1 = -378, z0 = 72, z1 = 142, h = 22 } -- the building
local CX = -420 -- the centre line (gate, doorway, corridor)
local HALL = { x0 = -427, x1 = -413, z0 = 72, z1 = 96 } -- the laser corridor
local FLOOR = 0.9 -- top of the floor slab
LabService.LOT = LOT

local CONCRETE = rgb(92, 96, 104)
local DARK = rgb(36, 38, 46)
local STEEL = rgb(130, 136, 148)
local TOXIC = rgb(110, 255, 70)
local PURPLE = rgb(105, 45, 150)
local LILAC = rgb(200, 150, 255)
local HAZARD = rgb(245, 200, 40)

local root -- the Lab model
local guards -- Guards squad
local tubes = {} -- { model, glass, liquid, kidModel, prompt, def, emptyUntil, x, z }
local lasers = {} -- { parts = {}, kind, z, on }
local cameras = {} -- { head, cone, yaw0, sweep, pos, alarmed }
local carrying = {} -- [player] = { tube, kid, def, lastPos, lastT }
local stunUntil = {}
local alarmUntil = 0

---------------------------------------------------------------------------
-- building helpers
---------------------------------------------------------------------------
local function part(parent, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props or {} do p[k] = v end
	p.Parent = parent
	return p
end
local function cyl(parent, name, d, h, pos, color, material, props)
	local t = { Shape = Enum.PartType.Cylinder }
	for k, v in props or {} do t[k] = v end
	return part(parent, name, Vector3.new(h, d, d), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, material, t)
end
local function sign(p, face, text, color, font, stroke)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.LightInfluence = 0
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -12, 1, -12)
	t.Position = UDim2.fromOffset(6, 6)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = font or Enum.Font.LuckiestGuy
	t.Text = text
	t.TextColor3 = color
	t.Parent = g
	if stroke then
		local s = Instance.new("UIStroke")
		s.Color = stroke
		s.Thickness = 3
		s.Parent = t
	end
	return t
end
local function light(p, kind, range, brightness, color)
	local l = Instance.new(kind)
	l.Range = range
	l.Brightness = brightness
	l.Color = color
	l.Parent = p
	return l
end
local function inBox(pos, b)
	return pos.X > b.x0 and pos.X < b.x1 and pos.Z > b.z0 and pos.Z < b.z1
end
local function inLot(pos) return inBox(pos, LOT) end
local function inBuilding(pos)
	return pos.X > B.x0 + 1 and pos.X < B.x1 - 1 and pos.Z > B.z0 + 1 and pos.Z < B.z1 - 1 and pos.Y < B.h
end
-- guards may walk the lab floor and the corridor, never out of the building
local function guardArea(pos)
	return pos.X > B.x0 + 2 and pos.X < B.x1 - 2 and pos.Z > 97 and pos.Z < B.z1 - 2
end

---------------------------------------------------------------------------
-- the compound: yard, fence, gate, the building's shell
---------------------------------------------------------------------------
local function buildShell(m)
	-- the yard: dark asphalt, a painted path to the door
	part(m, "Yard", Vector3.new(LOT.x1 - LOT.x0, 0.3, LOT.z1 - LOT.z0), CFrame.new((LOT.x0 + LOT.x1) / 2, 0.55, (LOT.z0 + LOT.z1) / 2), rgb(58, 60, 66), Enum.Material.Asphalt)
	part(m, "Walk", Vector3.new(8, 0.32, B.z0 - LOT.z0), CFrame.new(CX, 0.57, (LOT.z0 + B.z0) / 2), rgb(90, 96, 104), Enum.Material.Concrete)
	for _, x in { -4.2, 4.2 } do
		part(m, "WalkLine", Vector3.new(0.4, 0.34, B.z0 - LOT.z0), CFrame.new(CX + x, 0.58, (LOT.z0 + B.z0) / 2), HAZARD, Enum.Material.SmoothPlastic)
	end
	-- a driveway down to the sidewalk
	part(m, "Drive", Vector3.new(14, 0.3, 18), CFrame.new(CX, 0.5, LOT.z0 - 9), rgb(70, 72, 78), Enum.Material.Asphalt)
	-- the fence: chain-link panels, posts, barbed wire; the gate gap in front
	local function fence(x0, z0, x1, z1)
		local len = math.max(math.abs(x1 - x0), math.abs(z1 - z0))
		local along = x1 ~= x0
		local mid = Vector3.new((x0 + x1) / 2, 0, (z0 + z1) / 2)
		local size = along and Vector3.new(len, 8, 0.2) or Vector3.new(0.2, 8, len)
		part(m, "Mesh", size, CFrame.new(mid + Vector3.new(0, 4.6, 0)), rgb(150, 156, 166), Enum.Material.DiamondPlate, { Transparency = 0.55 })
		local rail = along and Vector3.new(len, 0.25, 0.25) or Vector3.new(0.25, 0.25, len)
		part(m, "Rail", rail, CFrame.new(mid + Vector3.new(0, 8.6, 0)), STEEL, Enum.Material.Metal)
		part(m, "Barbs", rail * Vector3.new(1, 0.4, 1), CFrame.new(mid + Vector3.new(0, 9.3, 0)) * CFrame.Angles(along and math.rad(20) or 0, 0, along and 0 or math.rad(20)), rgb(80, 80, 90), Enum.Material.Metal)
		for i = 0, math.floor(len / 6) do
			local t = i * 6 / len
			cyl(m, "Post", 0.4, 9, Vector3.new(x0 + (x1 - x0) * t, 5, z0 + (z1 - z0) * t), STEEL, Enum.Material.Metal)
		end
	end
	fence(LOT.x0, LOT.z0, CX - 6, LOT.z0)
	fence(CX + 6, LOT.z0, LOT.x1, LOT.z0)
	fence(LOT.x0, LOT.z0, LOT.x0, LOT.z1)
	fence(LOT.x1, LOT.z0, LOT.x1, LOT.z1)
	fence(LOT.x0, LOT.z1, LOT.x1, LOT.z1)
	-- the gate: two pillars, a sign across, a striped barrier arm (raised) and a guard booth
	for _, x in { -6.6, 6.6 } do
		part(m, "GatePillar", Vector3.new(1.6, 11, 1.6), CFrame.new(CX + x, 6, LOT.z0), DARK, Enum.Material.Concrete)
		part(m, "PillarLamp", Vector3.new(1.2, 0.8, 1.2), CFrame.new(CX + x, 12, LOT.z0), TOXIC, Enum.Material.Neon)
	end
	local gateSign = part(m, "GateSign", Vector3.new(14.8, 2.6, 0.6), CFrame.new(CX, 10.2, LOT.z0), rgb(22, 18, 30))
	sign(gateSign, Enum.NormalId.Front, "VEXCORP LABS \u{2022} RESTRICTED", TOXIC, Enum.Font.LuckiestGuy, rgb(10, 30, 10))
	sign(gateSign, Enum.NormalId.Back, "VEXCORP LABS \u{2022} RESTRICTED", TOXIC, Enum.Font.LuckiestGuy, rgb(10, 30, 10))
	local arm = part(m, "BarrierArm", Vector3.new(0.4, 9, 0.4), CFrame.new(CX - 5.4, 5.5, LOT.z0 - 1.2) * CFrame.Angles(0, 0, math.rad(-8)), rgb(250, 250, 250))
	for i = 0, 3 do
		part(m, "ArmStripe", Vector3.new(0.45, 1, 0.45), arm.CFrame * CFrame.new(0, -3.5 + i * 2.2, 0), rgb(220, 40, 50))
	end
	part(m, "Booth", Vector3.new(5, 7, 5), CFrame.new(CX + 11, 4, LOT.z0 + 4), rgb(210, 214, 220))
	part(m, "BoothRoof", Vector3.new(6, 0.5, 6), CFrame.new(CX + 11, 7.7, LOT.z0 + 4), PURPLE, Enum.Material.Metal)
	part(m, "BoothWindow", Vector3.new(4, 2.4, 0.2), CFrame.new(CX + 11, 5, LOT.z0 + 1.45), rgb(120, 200, 180), Enum.Material.Glass, { Transparency = 0.4 })
	-- warning signs on the fence
	for i, x in { CX - 30, CX + 30 } do
		local s = part(m, "Warning", Vector3.new(5, 3.2, 0.2), CFrame.new(x, 5, LOT.z0 - 0.25), HAZARD)
		sign(s, Enum.NormalId.Front, i == 1 and "\u{2623} DANGER\nMUTAGEN" or "NO KIDS\nALLOWED", rgb(20, 20, 20), Enum.Font.LuckiestGuy)
	end

	-- the building: walls with a darker plinth and a lighter band, the doorway, windows
	local W, D, H = B.x1 - B.x0, B.z1 - B.z0, B.h
	local cx, cz = (B.x0 + B.x1) / 2, (B.z0 + B.z1) / 2
	local function wall(x0, z0, x1, z1)
		local along = x1 ~= x0
		local len = math.max(math.abs(x1 - x0), math.abs(z1 - z0))
		local mid = Vector3.new((x0 + x1) / 2, 0, (z0 + z1) / 2)
		local size = along and Vector3.new(len, H, 1.4) or Vector3.new(1.4, H, len)
		part(m, "Wall", size, CFrame.new(mid + Vector3.new(0, H / 2 + FLOOR, 0)), CONCRETE, Enum.Material.Concrete)
		part(m, "Plinth", size + Vector3.new(0.3, -H + 2.4, 0.3), CFrame.new(mid + Vector3.new(0, FLOOR + 1.2, 0)), DARK, Enum.Material.Concrete)
		part(m, "Band", size + Vector3.new(0.3, -H + 1.2, 0.3), CFrame.new(mid + Vector3.new(0, FLOOR + H - 3, 0)), PURPLE, Enum.Material.Metal)
	end
	wall(B.x0, B.z1, B.x1, B.z1)
	wall(B.x0, B.z0, B.x0, B.z1)
	wall(B.x1, B.z0, B.x1, B.z1)
	-- the front, with the doorway in the middle
	wall(B.x0, B.z0, CX - 3.5, B.z0)
	wall(CX + 3.5, B.z0, B.x1, B.z0)
	part(m, "Lintel", Vector3.new(7, H - 9, 1.4), CFrame.new(CX, FLOOR + 9 + (H - 9) / 2, B.z0), CONCRETE, Enum.Material.Concrete)
	part(m, "DoorFrame", Vector3.new(8, 0.8, 1.8), CFrame.new(CX, FLOOR + 9.2, B.z0), DARK, Enum.Material.Metal)
	part(m, "Band", Vector3.new(7.3, 1.2, 1.7), CFrame.new(CX, FLOOR + H - 3, B.z0), PURPLE, Enum.Material.Metal)
	for _, x in { -3.7, 3.7 } do
		part(m, "DoorPost", Vector3.new(0.6, 9, 1.8), CFrame.new(CX + x, FLOOR + 4.5, B.z0), DARK, Enum.Material.Metal)
	end
	-- the sign over the door
	local big = part(m, "BigSign", Vector3.new(34, 5, 0.8), CFrame.new(CX, FLOOR + H - 7.5, B.z0 - 1), rgb(24, 20, 34))
	sign(big, Enum.NormalId.Front, "VEXCORP MUTATION LAB", TOXIC, Enum.Font.LuckiestGuy, rgb(10, 40, 10))
	for _, x in { -17.4, 17.4 } do
		part(m, "SignNeon", Vector3.new(0.4, 5.4, 0.4), CFrame.new(CX + x, FLOOR + H - 7.5, B.z0 - 1.2), TOXIC, Enum.Material.Neon)
	end
	-- windows: a row of green-lit glass on the front, both sides of the door
	for _, x in { -36, -26, -16, 16, 26, 36 } do
		part(m, "Window", Vector3.new(6, 4, 0.3), CFrame.new(CX + x, FLOOR + 10, B.z0 - 0.62), rgb(90, 200, 120), Enum.Material.Glass, { Transparency = 0.35 })
		part(m, "WindowGlow", Vector3.new(5.6, 3.6, 0.1), CFrame.new(CX + x, FLOOR + 10, B.z0 - 0.4), rgb(120, 255, 100), Enum.Material.Neon, { Transparency = 0.7 })
		part(m, "Sill", Vector3.new(6.6, 0.4, 0.8), CFrame.new(CX + x, FLOOR + 7.8, B.z0 - 0.8), DARK, Enum.Material.Concrete)
		part(m, "FrameTop", Vector3.new(6.4, 0.35, 0.5), CFrame.new(CX + x, FLOOR + 12.1, B.z0 - 0.75), DARK, Enum.Material.Metal)
		for _, dx in { -3.05, 0, 3.05 } do
			part(m, "FrameBar", Vector3.new(0.3, 4.2, 0.5), CFrame.new(CX + x + dx, FLOOR + 10, B.z0 - 0.75), DARK, Enum.Material.Metal)
		end
		part(m, "FrameMid", Vector3.new(6.2, 0.25, 0.5), CFrame.new(CX + x, FLOOR + 10, B.z0 - 0.75), DARK, Enum.Material.Metal)
	end
	-- the roof: slab, parapet, vents, a satellite dish, two chimneys puffing green smoke
	part(m, "Roof", Vector3.new(W, 1.2, D), CFrame.new(cx, FLOOR + H + 0.6, cz), rgb(70, 72, 80), Enum.Material.Concrete)
	for _, spec in { { 0, D / 2 }, { 0, -D / 2 }, { W / 2, 0 }, { -W / 2, 0 } } do
		local sz = spec[1] == 0 and Vector3.new(W, 1.6, 0.8) or Vector3.new(0.8, 1.6, D)
		part(m, "Parapet", sz, CFrame.new(cx + spec[1], FLOOR + H + 2, cz + spec[2]), DARK, Enum.Material.Concrete)
	end
	for i, x in { -26, 26 } do
		cyl(m, "Stack", 4, 14, Vector3.new(cx + x, FLOOR + H + 8, cz + 20), rgb(90, 88, 98), Enum.Material.Concrete)
		cyl(m, "StackBand", 4.4, 1, Vector3.new(cx + x, FLOOR + H + 12, cz + 20), TOXIC, Enum.Material.Neon)
		local puff = part(m, "Puff" .. i, Vector3.new(1, 1, 1), CFrame.new(cx + x, FLOOR + H + 15.5, cz + 20), DARK, nil, { Transparency = 1, CanCollide = false })
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(rgb(130, 255, 90), rgb(60, 110, 60))
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 12) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime = NumberRange.new(4, 6)
		e.Speed = NumberRange.new(4, 6)
		e.SpreadAngle = Vector2.new(10, 10)
		e.Rate = 3
		e.Parent = puff
	end
	for i = 0, 2 do
		part(m, "Vent", Vector3.new(5, 2.4, 4), CFrame.new(cx - 10 + i * 10, FLOOR + H + 2.4, cz - 14), STEEL, Enum.Material.DiamondPlate)
	end
	cyl(m, "DishPole", 0.6, 5, Vector3.new(cx + 30, FLOOR + H + 3.7, cz - 20), STEEL, Enum.Material.Metal)
	part(m, "Dish", Vector3.new(1, 7, 7), CFrame.new(cx + 30, FLOOR + H + 7, cz - 20) * CFrame.Angles(0, math.rad(30), math.rad(-35)), rgb(225, 228, 235), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	-- pipes running along the outside walls
	for _, z in { B.z0 + 10, B.z0 + 30, B.z0 + 50 } do
		for _, x in { B.x0 - 1, B.x1 + 1 } do
			cyl(m, "Pipe", 1.2, H - 2, Vector3.new(x, FLOOR + (H - 2) / 2, z), STEEL, Enum.Material.Metal)
		end
	end
	-- the alarm lights on the front corners (they spin red during an alarm; the client animates)
	for _, x in { B.x0 + 2, B.x1 - 2 } do
		local b = part(m, "Beacon", Vector3.new(1.6, 1.6, 1.6), CFrame.new(x, FLOOR + H + 2, B.z0 + 1), rgb(120, 30, 40), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball })
		CollectionService:AddTag(b, "LabBeacon")
		light(b, "PointLight", 30, 0, rgb(255, 40, 60)).Name = "AlarmLight"
	end
end

---------------------------------------------------------------------------
-- inside: the floor, the laser hall, the lab
---------------------------------------------------------------------------
local function buildInside(m)
	local W, D = B.x1 - B.x0, B.z1 - B.z0
	local cx, cz = (B.x0 + B.x1) / 2, (B.z0 + B.z1) / 2
	-- a tiled floor: light and dark checks
	part(m, "Floor", Vector3.new(W - 1.4, 0.4, D - 1.4), CFrame.new(cx, FLOOR - 0.2, cz), rgb(200, 204, 210), Enum.Material.SmoothPlastic)
	for i = 0, math.floor((W - 4) / 6) do
		for j = 0, math.floor((D - 4) / 6) do
			if (i + j) % 2 == 0 then
				part(m, "Tile", Vector3.new(5.9, 0.05, 5.9), CFrame.new(B.x0 + 3 + i * 6, FLOOR + 0.01, B.z0 + 3 + j * 6), rgb(170, 176, 184), Enum.Material.SmoothPlastic, { CanCollide = false })
			end
		end
	end
	-- ceiling lights (cold white, a green tint by the tubes)
	for _, z in { 104, 118, 132 } do
		for _, x in { -448, -434, -406, -392 } do
			local l = part(m, "CeilingLight", Vector3.new(6, 0.4, 1.4), CFrame.new(x, FLOOR + B.h - 0.4, z), rgb(235, 245, 255), Enum.Material.Neon)
			light(l, "SurfaceLight", 22, 1.2, z > 125 and rgb(200, 255, 190) or rgb(230, 240, 255)).Face = Enum.NormalId.Bottom
		end
	end

	-- the laser hall: walls, a warning at the start, the laser emitters on both walls
	for _, x in { HALL.x0, HALL.x1 } do
		part(m, "HallWall", Vector3.new(1, B.h - 1, HALL.z1 - HALL.z0), CFrame.new(x, FLOOR + (B.h - 1) / 2, (HALL.z0 + HALL.z1) / 2), rgb(120, 124, 132), Enum.Material.Concrete)
		part(m, "HallStripe", Vector3.new(1.05, 0.6, HALL.z1 - HALL.z0), CFrame.new(x, FLOOR + 1, (HALL.z0 + HALL.z1) / 2), HAZARD, Enum.Material.SmoothPlastic)
	end
	-- the dark rooms either side of the hall (walled off, not playable)
	for _, x0 in { B.x0, HALL.x1 } do
		local x1 = x0 == B.x0 and HALL.x0 or B.x1
		part(m, "SideRoomWall", Vector3.new(x1 - x0, B.h - 1, 1), CFrame.new((x0 + x1) / 2, FLOOR + (B.h - 1) / 2, HALL.z1), rgb(120, 124, 132), Enum.Material.Concrete)
	end
	local hallSign = part(m, "HallSign", Vector3.new(12, 2, 0.3), CFrame.new(CX, FLOOR + 8, HALL.z0 + 1.2), rgb(200, 30, 40))
	sign(hallSign, Enum.NormalId.Back, "\u{26A0} LASER SECURITY \u{26A0}", rgb(255, 255, 255), Enum.Font.LuckiestGuy)

	-- the laser curtains: blinking (z 78), low (z 84: jump it), sweeping (z 90)
	local function emitter(z)
		for _, x in { HALL.x0 + 0.6, HALL.x1 - 0.6 } do
			part(m, "Emitter", Vector3.new(0.4, 6, 0.8), CFrame.new(x, FLOOR + 3, z), DARK, Enum.Material.Metal)
		end
	end
	local width = HALL.x1 - HALL.x0 - 1.4
	-- 1: three beams across, blinking
	emitter(78)
	local blink = { kind = "blink", parts = {}, on = true, z = 78 }
	for _, y in { 1.1, 2.9, 4.7 } do
		table.insert(blink.parts, part(m, "Laser", Vector3.new(width, 0.16, 0.16), CFrame.new(CX, FLOOR + y, 78), rgb(255, 30, 40), Enum.Material.Neon, { CanCollide = false, CanQuery = false, CanTouch = false }))
	end
	table.insert(lasers, blink)
	-- 2: one low beam, always on: jump it
	emitter(84)
	local low = { kind = "low", parts = {}, on = true, z = 84 }
	table.insert(low.parts, part(m, "Laser", Vector3.new(width, 0.16, 0.16), CFrame.new(CX, FLOOR + 1.2, 84), rgb(255, 30, 40), Enum.Material.Neon, { CanCollide = false, CanQuery = false, CanTouch = false }))
	table.insert(lasers, low)
	-- 3: a vertical beam sweeping side to side
	part(m, "SweepRail", Vector3.new(width, 0.3, 0.5), CFrame.new(CX, FLOOR + 7, 90), DARK, Enum.Material.Metal)
	local sweep = { kind = "sweep", parts = {}, on = true, z = 90 }
	table.insert(sweep.parts, part(m, "Laser", Vector3.new(0.16, 6.6, 0.16), CFrame.new(CX, FLOOR + 3.4, 90), rgb(255, 30, 40), Enum.Material.Neon, { CanCollide = false, CanQuery = false, CanTouch = false }))
	table.insert(lasers, sweep)

	-- the lab floor: benches with beakers, cages, pipes, the Vat and the tubes at the back
	for i, x in { -446, -394 } do
		part(m, "Bench", Vector3.new(10, 3.4, 3.4), CFrame.new(x, FLOOR + 1.7, 112), rgb(220, 222, 228), Enum.Material.SmoothPlastic)
		part(m, "BenchTop", Vector3.new(10.4, 0.3, 3.8), CFrame.new(x, FLOOR + 3.55, 112), DARK, Enum.Material.Slate)
		for k = 0, 3 do
			local c = ({ TOXIC, LILAC, rgb(90, 200, 255), rgb(255, 120, 60) })[k + 1]
			cyl(m, "Beaker", 0.7, 1.2 + (k % 2) * 0.5, Vector3.new(x - 3.5 + k * 2.3, FLOOR + 4.3 + (k % 2) * 0.25, 112), c, Enum.Material.Neon, { Transparency = 0.25, CanCollide = false })
		end
		part(m, "Monitor", Vector3.new(2.4, 1.6, 0.2), CFrame.new(x + 3, FLOOR + 4.7, 112.9), rgb(20, 20, 26))
		local scr = part(m, "Screen", Vector3.new(2.1, 1.3, 0.05), CFrame.new(x + 3, FLOOR + 4.7, 112.78), rgb(60, 220, 90), Enum.Material.Neon)
		sign(scr, Enum.NormalId.Front, i == 1 and "DNA\n>>>" or "HW 99%", rgb(10, 40, 10), Enum.Font.Arcade)
	end
	-- the Mutagen Vat: a huge glass drum of bubbling green, pipes into the ceiling
	local vat = cyl(m, "Vat", 11, 12, Vector3.new(CX, FLOOR + 6, 130), TOXIC, Enum.Material.Neon, { Transparency = 0.35 })
	vat:SetAttribute("Vat", true)
	cyl(m, "VatGlass", 11.8, 12.4, Vector3.new(CX, FLOOR + 6.1, 130), rgb(210, 255, 220), Enum.Material.Glass, { Transparency = 0.8, CanCollide = false })
	cyl(m, "VatBase", 13, 1.2, Vector3.new(CX, FLOOR + 0.6, 130), DARK, Enum.Material.DiamondPlate)
	cyl(m, "VatCap", 12.4, 1, Vector3.new(CX, FLOOR + 12.5, 130), DARK, Enum.Material.Metal)
	for _, x in { -3, 3 } do
		cyl(m, "VatPipe", 1.2, B.h - 13, Vector3.new(CX + x, FLOOR + 13 + (B.h - 13) / 2, 130), STEEL, Enum.Material.Metal)
	end
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	bubbles.Color = ColorSequence.new(rgb(220, 255, 200))
	bubbles.Size = NumberSequence.new(0.5)
	bubbles.Speed = NumberRange.new(2, 4)
	bubbles.Lifetime = NumberRange.new(2, 3)
	bubbles.Rate = 18
	bubbles.EmissionDirection = Enum.NormalId.Right
	bubbles.Parent = vat
	light(vat, "PointLight", 26, 2.2, TOXIC)
	local vatSign = part(m, "VatSign", Vector3.new(8, 1.6, 0.3), CFrame.new(CX, FLOOR + 14.6, 124.5), rgb(24, 20, 34))
	sign(vatSign, Enum.NormalId.Front, "MUTAGEN X", TOXIC, Enum.Font.LuckiestGuy)
	-- terminals (Stan's secret missions hack these)
	for i, spec in { { -459, 104, 90 }, { -381, 104, -90 } } do
		local t = Instance.new("Model")
		t.Name = "Terminal" .. i
		t.Parent = m
		local cf = CFrame.new(spec[1], FLOOR, spec[2]) * CFrame.Angles(0, math.rad(spec[3]), 0)
		part(t, "Desk", Vector3.new(4, 3.2, 2), cf * CFrame.new(0, 1.6, 0), DARK, Enum.Material.Metal)
		part(t, "Screen", Vector3.new(3.4, 2.2, 0.2), cf * CFrame.new(0, 4.4, 0.6) * CFrame.Angles(math.rad(-12), 0, 0), rgb(20, 20, 24))
		local glow = part(t, "Glow", Vector3.new(3, 1.8, 0.05), cf * CFrame.new(0, 4.4, 0.47) * CFrame.Angles(math.rad(-12), 0, 0), rgb(120, 255, 100), Enum.Material.Neon)
		sign(glow, Enum.NormalId.Front, "VEXCORP\nSECURE", rgb(10, 40, 10), Enum.Font.Arcade)
		part(t, "Keyboard", Vector3.new(2.6, 0.15, 0.9), cf * CFrame.new(0, 3.3, -0.3), rgb(60, 60, 66))
		local spot = part(t, "PromptSpot", Vector3.new(1, 1, 1), cf * CFrame.new(0, 3, -1.5), DARK, nil, { Transparency = 1, CanCollide = false })
		t:SetAttribute("Terminal", i)
		_ = spot
	end
	-- lab clutter: crates of homework, a cage, gas cylinders, hazard stripes on the floor
	for i, spec in { { -456, 100 }, { -456, 103.6 }, { -452.4, 100 }, { -384, 138 }, { -387.6, 138 } } do
		local c = part(m, "Crate", Vector3.new(3.4, 3.4, 3.4), CFrame.new(spec[1], FLOOR + 1.7, spec[2]) * CFrame.Angles(0, math.rad(i * 9), 0), rgb(150, 110, 70), Enum.Material.WoodPlanks)
		sign(c, Enum.NormalId.Front, "HW", rgb(60, 30, 20), Enum.Font.Arcade)
	end
	for i = 0, 2 do
		cyl(m, "GasTank", 1.1, 4, Vector3.new(-384 + i * 1.3, FLOOR + 2, 100), i == 1 and TOXIC or rgb(200, 200, 210), Enum.Material.Metal)
	end
	for i = 0, 9 do
		part(m, "FloorHazard", Vector3.new(1.6, 0.06, 0.5), CFrame.new(-432 + i * 2.6, FLOOR + 0.03, 124) * CFrame.Angles(0, math.rad(40), 0), i % 2 == 0 and HAZARD or rgb(24, 24, 28), Enum.Material.SmoothPlastic, { CanCollide = false })
	end
end

---------------------------------------------------------------------------
-- the mutation tubes
---------------------------------------------------------------------------
local TUBE_X = { -452, -438, -402, -388 }
local TUBE_Z = 136

local function rollMutant(player)
	local p = Data.get(player)
	local band = Config.Lab.mutantByTier[math.clamp(p and p.tier or 1, 1, #Config.Lab.mutantByTier)]
	local rarity = band[math.random(#band)]
	local pool = {}
	for _, s in Config.Students do
		if s.rarity == rarity then table.insert(pool, s) end
	end
	return pool[math.random(#pool)]
end

-- what floats in a tube: a mutant from a random band (the one you carry out is rolled for you)
local function fillTube(t)
	if t.kidModel then t.kidModel:Destroy() end
	local pool = {}
	for _, s in Config.Students do
		if s.rarity == "Rare" or s.rarity == "Epic" then table.insert(pool, s) end
	end
	local def = pool[math.random(#pool)]
	local kid = Factory.build(def, "Mutated")
	for _, d in kid:GetDescendants() do
		if d:IsA("BillboardGui") then d:Destroy() end
	end
	local so = Factory.standOffset(kid)
	kid.PrimaryPart.CFrame = CFrame.new(t.x, FLOOR + 1.6 + so, TUBE_Z) -- (facing -Z: out at the room)
	kid:SetAttribute("Floating", true)
	kid.Parent = t.model
	Factory.play(kid, "idle")
	t.kidModel = kid
	t.glass.Transparency = 0.7
	t.liquid.Transparency = 0.55
	t.label.Text = "SUBJECT " .. ("%03d"):format(math.random(1, 999))
	t.prompt.Enabled = true
	t.emptyUntil = nil
end

local function buildTube(m, i, x)
	local tube = Instance.new("Model")
	tube.Name = "Tube" .. i
	tube.Parent = m
	cyl(tube, "Base", 5.4, 1.4, Vector3.new(x, FLOOR + 0.7, TUBE_Z), DARK, Enum.Material.DiamondPlate)
	cyl(tube, "BaseRing", 5.6, 0.4, Vector3.new(x, FLOOR + 1.45, TUBE_Z), TOXIC, Enum.Material.Neon)
	local liquid = cyl(tube, "Liquid", 4.2, 9, Vector3.new(x, FLOOR + 6, TUBE_Z), TOXIC, Enum.Material.Neon, { Transparency = 0.55, CanCollide = false, CanQuery = false })
	local glass = cyl(tube, "Glass", 4.6, 9.6, Vector3.new(x, FLOOR + 6.2, TUBE_Z), rgb(210, 255, 230), Enum.Material.Glass, { Transparency = 0.7 })
	cyl(tube, "Top", 5.2, 1.4, Vector3.new(x, FLOOR + 11.6, TUBE_Z), DARK, Enum.Material.Metal)
	cyl(tube, "Hose", 0.8, B.h - 12.3, Vector3.new(x, FLOOR + 12.3 + (B.h - 12.3) / 2, TUBE_Z), STEEL, Enum.Material.Metal)
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	bubbles.Color = ColorSequence.new(rgb(220, 255, 210))
	bubbles.Size = NumberSequence.new(0.3)
	bubbles.Speed = NumberRange.new(1.5, 3)
	bubbles.Lifetime = NumberRange.new(2, 3)
	bubbles.Rate = 6
	bubbles.EmissionDirection = Enum.NormalId.Right
	bubbles.Parent = liquid
	light(liquid, "PointLight", 12, 1.3, TOXIC)
	local plate = part(tube, "Plate", Vector3.new(4, 0.9, 0.2), CFrame.new(x, FLOOR + 13, TUBE_Z - 2.7), rgb(24, 20, 34))
	local label = sign(plate, Enum.NormalId.Front, "", TOXIC, Enum.Font.Arcade)
	local spot = part(tube, "PromptSpot", Vector3.new(1, 1, 1), CFrame.new(x, FLOOR + 3, TUBE_Z - 3.2), DARK, nil, { Transparency = 1, CanCollide = false })
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RescuePrompt"
	prompt.ActionText = "Break Out"
	prompt.ObjectText = "Mutant Kid"
	prompt.HoldDuration = Config.Lab.holdTime
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 7
	prompt:SetAttribute("Color", TOXIC)
	prompt.Parent = spot
	local t = { model = tube, glass = glass, liquid = liquid, label = label, prompt = prompt, x = x, index = i }
	tubes[i] = t
	return t
end

---------------------------------------------------------------------------
-- the security cameras
---------------------------------------------------------------------------
local function buildCamera(m, pos, yaw0, sweep)
	local cam = Instance.new("Model")
	cam.Name = "Camera"
	cam.Parent = m
	part(cam, "Mount", Vector3.new(1, 1, 1.4), CFrame.new(pos + Vector3.new(0, 0.9, 0)), DARK, Enum.Material.Metal)
	local head = part(cam, "Head", Vector3.new(1.3, 1.1, 2.4), CFrame.new(pos) * CFrame.Angles(0, math.rad(yaw0), 0), rgb(230, 232, 238), Enum.Material.SmoothPlastic)
	local lens = part(cam, "Lens", Vector3.new(0.7, 0.7, 0.2), head.CFrame * CFrame.new(0, 0, -1.25), rgb(255, 40, 40), Enum.Material.Neon)
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = head, lens
	weld.Parent = lens
	lens.Anchored = false
	-- the view cone: a long thin wedge of light on the floor
	local cone = part(cam, "Cone", Vector3.new(0.2, 1, 1), CFrame.new(), rgb(255, 250, 200), Enum.Material.Neon, { Transparency = 0.82, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	local c = { head = head, cone = cone, pos = pos, yaw0 = yaw0, sweep = sweep, range = Config.Lab.cameraRange, half = Config.Lab.cameraHalfAngle, t = math.random() * 10 }
	table.insert(cameras, c)
	return c
end

local function cameraYaw(c)
	return c.yaw0 + math.sin(c.t * 0.55) * c.sweep
end

-- where a camera looks on the floor: its cone drawn as a flat wedge from below it
local function updateCamera(c, dt)
	c.t += dt
	local yaw = cameraYaw(c)
	local look = CFrame.Angles(0, math.rad(yaw), 0).LookVector
	c.head.CFrame = CFrame.lookAt(c.pos, c.pos + look * 10 + Vector3.new(0, -6, 0))
	local len = c.range * 0.8
	local mid = Vector3.new(c.pos.X, FLOOR + 0.08, c.pos.Z) + look * (len / 2 + 2)
	local width = 2 * math.tan(math.rad(c.half)) * len
	c.cone.Size = Vector3.new(width, 0.05, len)
	c.cone.CFrame = CFrame.lookAt(mid, mid + look)
	c.cone.Color = alarmUntil > now() and rgb(255, 60, 60) or rgb(255, 250, 200)
end

local function cameraSees(c, char)
	local proot = char and char:FindFirstChild("HumanoidRootPart")
	if not proot then return false end
	local who = Players:GetPlayerFromCharacter(char)
	if who and (who:GetAttribute("SmokeUntil") or 0) > workspace:GetServerTimeNow() then return false end
	-- a box standing still is just a box
	if who and who:GetAttribute("Boxed") then
		local v = proot.AssemblyLinearVelocity
		if Vector3.new(v.X, 0, v.Z).Magnitude < 1.5 then return false end
	end
	local d = proot.Position - c.pos
	local flat = Vector3.new(d.X, 0, d.Z)
	if flat.Magnitude > c.range or flat.Magnitude < 1 then return false end
	local look = CFrame.Angles(0, math.rad(cameraYaw(c)), 0).LookVector
	if flat.Unit:Dot(look) < math.cos(math.rad(c.half)) then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char, c.head.Parent }
	local hit = workspace:Raycast(c.pos, (proot.Position - c.pos), params)
	return hit == nil
end

---------------------------------------------------------------------------
-- alarm, carrying, catching
---------------------------------------------------------------------------
local function setAlarm(on)
	for _, b in CollectionService:GetTagged("LabBeacon") do
		b.Color = on and rgb(255, 40, 60) or rgb(120, 30, 40)
		b.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
		local l = b:FindFirstChild("AlarmLight")
		if l then l.Brightness = on and 3 or 0 end
	end
	if root then root:SetAttribute("Alarm", on or nil) end
end

local function alarm(player, why)
	local fresh = alarmUntil < now()
	alarmUntil = now() + 12
	setAlarm(true)
	guards:alertAll(player)
	if fresh and player.Parent then
		Remotes.Notify:FireClient(player, "\u{1F6A8} " .. (why or "ALARM!") .. " Security is coming!", "bad")
	end
	Signals.fire("labAlarm", player)
end
LabService.alarm = alarm

local function dropCarry(player, why, keepTube)
	local c = carrying[player]
	if not c then return end
	carrying[player] = nil
	if c.kid then c.kid:Destroy() end
	player:SetAttribute("Heist", nil)
	StealService.setSpeed(player)
	-- the mutant goes back in its tube
	if not keepTube and c.tube and not c.tube.kidModel then fillTube(c.tube) end
	if why and player.Parent then
		Remotes.Notify:FireClient(player, why, "bad")
		Remotes.Push:FireClient(player, "heist", { state = "failed" })
	end
end

local function thrownOut(player)
	local char = player.Character
	if not char then return end
	dropCarry(player, "Lab security caught you and threw you out!")
	char:PivotTo(CFrame.lookAt(Vector3.new(CX + math.random(-4, 4), 3.5, LOT.z0 - 8), Vector3.new(CX, 3.5, 0)))
	stunUntil[player] = now() + 1.5
	player:SetAttribute("Stunned", true)
	StealService.setSpeed(player)
	task.delay(1.5, function()
		if not player.Parent then return end
		player:SetAttribute("Stunned", nil)
		StealService.setSpeed(player)
	end)
	Signals.fire("labCaught", player)
end

local function takeMutant(player, t)
	if carrying[player] or not t.kidModel or player:GetAttribute("Carrying") or player:GetAttribute("Heist") then return end
	local char = player.Character
	local proot = char and char:FindFirstChild("HumanoidRootPart")
	if not proot or (stunUntil[player] or 0) > now() then return end
	if (t.prompt.Parent.Position - proot.Position).Magnitude > 12 then return end
	local def = rollMutant(player)
	t.kidModel:Destroy()
	t.kidModel = nil
	t.prompt.Enabled = false
	t.glass.Transparency = 1
	t.liquid.Transparency = 1
	t.label.Text = "EMPTY"
	t.emptyUntil = now() + Config.Lab.restock
	-- the mutant over your head
	local kid = Factory.build(def, "Mutated")
	Factory.setMode(kid, "carried")
	for _, bp in kid:GetDescendants() do
		if bp:IsA("BasePart") then
			bp.Anchored = false
			bp.Massless = true
			bp.CanCollide = false
			bp.CanQuery = false
		end
	end
	local off = 3.4 + Factory.standOffset(kid) * 0.9
	kid.PrimaryPart.CFrame = proot.CFrame * CFrame.new(0, off, 0)
	local w = Instance.new("Weld")
	w.Part0, w.Part1 = proot, kid.PrimaryPart
	w.C0 = CFrame.new(0, off, 0)
	w.Parent = kid.PrimaryPart
	kid.Parent = char
	Factory.play(kid, "sit")
	carrying[player] = { tube = t, kid = kid, def = def, lastPos = proot.Position, lastT = now() }
	player:SetAttribute("Heist", "Mutant " .. def.name)
	StealService.setSpeed(player)
	Remotes.Push:FireClient(player, "heist", { state = "carrying", name = "Mutant " .. def.name })
	-- (the grab first, then the alarm it sets off: Stan's Ghost Protocol counts alarms before the grab)
	Signals.fire("labTake", player, def)
	alarm(player, "You broke a tube!")
end

local function escaped(player)
	local c = carrying[player]
	if not c then return end
	carrying[player] = nil
	if c.kid then c.kid:Destroy() end
	player:SetAttribute("Heist", nil)
	StealService.setSpeed(player)
	local p = Data.get(player)
	local LetterService = require(script.Parent.LetterService)
	if p and not LetterService.deliver(player, c.def, true, "Mutated") then
		p.pendingBench = p.pendingBench or {}
		table.insert(p.pendingBench, { id = c.def.id, grade = "Mutated" })
	end
	p.stats.mutants = (p.stats.mutants or 0) + 1
	Remotes.Push:FireClient(player, "heist", { state = "prize", name = "Mutant " .. c.def.name, rarity = c.def.rarity })
	Remotes.Announce:FireClient(player, "MUTANT " .. c.def.name:upper() .. "!", TOXIC)
	Remotes.Notify:FireClient(player, ("\u{1F9EC} You broke out a MUTATED %s (%s, x6 tuition)! They're on your Waiting Bench."):format(c.def.name, c.def.rarity), "good")
	Signals.fire("mutantEscaped", player, c.def)
	Data.saveSoon(player)
end

---------------------------------------------------------------------------
-- every frame
---------------------------------------------------------------------------
local lastSpotted = {}
local function tick(dt)
	local t = now()
	-- the lasers: the blinker (2 s on, 1.4 s off), the sweeper
	for _, L in lasers do
		if L.kind == "blink" then
			local on = (t % 3.4) < 2
			if on ~= L.on then
				L.on = on
				for _, p in L.parts do p.Transparency = on and 0 or 1 end
			end
		elseif L.kind == "sweep" then
			local x = CX + math.sin(t * 1.1) * ((HALL.x1 - HALL.x0) / 2 - 1.2)
			L.parts[1].CFrame = CFrame.new(x, FLOOR + 3.4, L.z)
		end
	end
	for _, c in cameras do updateCamera(c, dt) end
	if alarmUntil > 0 and alarmUntil < t then
		alarmUntil = 0
		setAlarm(false)
	end
	guards:tick(dt)

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local proot = char and char:FindFirstChild("HumanoidRootPart")
		if not proot then
			if carrying[player] then dropCarry(player) end
			continue
		end
		local pos = proot.Position
		local inside = inLot(pos)
		-- the eye: spotted while any lab guard is after you
		if inside or lastSpotted[player] ~= nil then
			local spotted = inside and guards:isChasing(player) or nil
			if spotted ~= lastSpotted[player] then
				lastSpotted[player] = spotted
				player:SetAttribute("Spotted", spotted)
			end
		end
		if not inside then
			if carrying[player] then escaped(player) end
			continue
		end
		if (stunUntil[player] or 0) > t then continue end
		-- touching a laser that's on
		if inBox(pos, HALL) then
			params.FilterDescendantsInstances = { char }
			for _, L in lasers do
				if L.on then
					for _, p in L.parts do
						if #workspace:GetPartsInPart(p, params) > 0 then
							alarm(player, "You tripped a laser!")
							break
						end
					end
				end
			end
		end
		-- cameras
		if inBuilding(pos) then
			for _, c in cameras do
				if cameraSees(c, char) then
					if not guards:isChasing(player) then alarm(player, "A camera saw you!") end
					break
				end
			end
		end
		-- the carrier: no teleporting out
		local c = carrying[player]
		if c then
			local moved = Vector3.new(pos.X - c.lastPos.X, 0, pos.Z - c.lastPos.Z).Magnitude
			if moved > Config.Heist.carrySpeed * 1.8 * (t - c.lastT) + 6 then
				dropCarry(player, "You dropped the mutant!")
				continue
			end
			if t - c.lastT >= 0.25 then c.lastPos, c.lastT = pos, t end
		end
	end
	-- empty tubes refill
	for _, tb in tubes do
		if tb.emptyUntil and t >= tb.emptyUntil and not tb.kidModel then
			local takenBy = false
			for _, c in carrying do
				if c.tube == tb then takenBy = true end
			end
			if not takenBy then fillTube(tb) end
		end
	end
end

---------------------------------------------------------------------------
function LabService.start()
	local old = workspace:FindFirstChild("VexLab")
	if old then old:Destroy() end
	-- (no map trees growing through the Lab: the map builder skips them, this catches an older map)
	local deco = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Deco")
	for _, m in deco and deco:GetChildren() or {} do
		if m:IsA("Model") then
			local cf = m:GetBoundingBox()
			if cf.Position.X > LOT.x0 - 6 and cf.Position.X < LOT.x1 + 6 and cf.Position.Z > LOT.z0 - 6 and cf.Position.Z < LOT.z1 + 6 then m:Destroy() end
		end
	end
	root = Instance.new("Model")
	root.Name = "VexLab"
	local shell = Instance.new("Model")
	shell.Name = "Shell"
	shell.Parent = root
	buildShell(shell)
	local inside = Instance.new("Model")
	inside.Name = "Inside"
	inside.Parent = root
	buildInside(inside)
	local tubesModel = Instance.new("Model")
	tubesModel.Name = "Tubes"
	tubesModel.Parent = root
	for i, x in TUBE_X do buildTube(tubesModel, i, x) end
	local camsModel = Instance.new("Model")
	camsModel.Name = "Cameras"
	camsModel.Parent = root
	buildCamera(camsModel, Vector3.new(B.x0 + 2.5, FLOOR + 16, 98.5), 150, 38)
	buildCamera(camsModel, Vector3.new(B.x1 - 2.5, FLOOR + 16, 98.5), 210, 38)
	local guardsFolder = Instance.new("Folder")
	guardsFolder.Name = "Guards"
	guardsFolder.Parent = root
	root.Parent = workspace
	pcall(function() root.ModelStreamingMode = Enum.ModelStreamingMode.Atomic end)

	guards = Guards.new({
		id = "LabGuard", name = "Hazmat", title = "Lab Security", outfit = "hazmat",
		folder = guardsFolder,
		area = guardArea,
		grounds = inLot,
		sight = { sight = 24, angle = 100, hear = 5 },
		patrolSpeed = 6.5, chaseSpeed = 14.5, carrySpeed = 13.2,
		isCarrying = function(player) return carrying[player] ~= nil end,
		onCatch = function(player) thrownOut(player) end,
	})
	guards:add({ Vector3.new(-452, FLOOR, 104), Vector3.new(-430, FLOOR, 104), Vector3.new(-430, FLOOR, 122), Vector3.new(-452, FLOOR, 122) })
	guards:add({ Vector3.new(-388, FLOOR, 122), Vector3.new(-410, FLOOR, 122), Vector3.new(-410, FLOOR, 104), Vector3.new(-388, FLOOR, 104) })

	for _, tb in tubes do
		fillTube(tb)
		tb.prompt.Triggered:Connect(function(player) takeMutant(player, tb) end)
	end
	table.insert(StealService.swingHooks, function(player, proot)
		if inLot(proot.Position) then guards:onSwing(player, proot) end
	end)
	local GearService = require(script.Parent.GearService)
	table.insert(GearService.smokeHooks, function(player, pos)
		if inLot(pos) then guards:smoke(player, pos) end
	end)
	table.insert(GearService.noiseHooks, function(pos)
		if inLot(pos) then guards:noise(pos) end
	end)
	RunService.Heartbeat:Connect(function(dt)
		local ok, err = pcall(tick, dt)
		if not ok then warn("[Lab]", err) end
	end)
	local function watch(player)
		local function onChar(char)
			if carrying[player] then dropCarry(player) end
			local hum = char:WaitForChild("Humanoid", 10)
			if hum then
				hum.Died:Connect(function()
					if carrying[player] then dropCarry(player, "You fainted! The mutant got away.") end
				end)
			end
		end
		player.CharacterAdded:Connect(onChar)
		if player.Character then task.spawn(onChar, player.Character) end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do watch(player) end
	Players.PlayerRemoving:Connect(function(player)
		dropCarry(player)
		stunUntil[player] = nil
		lastSpotted[player] = nil
	end)
end

-- for SecretService / FilesService / tests
function LabService.inLot(pos) return inLot(pos) end
function LabService.isCarrying(player) return carrying[player] ~= nil end
function LabService.terminals()
	local out = {}
	for _, t in root:FindFirstChild("Inside"):GetChildren() do
		if t:GetAttribute("Terminal") then table.insert(out, t) end
	end
	return out
end
function LabService.vat()
	for _, p in root:FindFirstChild("Inside"):GetChildren() do
		if p:GetAttribute("Vat") then return p end
	end
	return nil
end
function LabService.debugTake(player, i)
	local t = tubes[i or 1]
	if not t then return false end
	local char = player.Character
	if char then char:PivotTo(CFrame.new(t.x, FLOOR + 3.5, TUBE_Z - 4.5)) end
	task.wait(0.2)
	takeMutant(player, t)
	return carrying[player] ~= nil
end
-- Studio: every Lab guard out cold for `secs` (to test a job without the guards)
function LabService.debugCalm(secs)
	for _, g in guards.list do
		g.state = "stunned"
		g.target = nil
		g.stunUntil = now() + (secs or 30)
		require(script.Parent.Walkers).stop(g.model)
	end
	return #guards.list
end
function LabService.debugState()
	local out = { alarm = alarmUntil > now(), tubes = {}, guards = {} }
	for i, t in tubes do out.tubes[i] = t.kidModel and "full" or ("empty " .. math.floor((t.emptyUntil or 0) - now())) end
	for i, g in guards.list do
		local r = g.model.PrimaryPart
		out.guards[i] = ("%s (%d,%d)"):format(g.state, r.Position.X, r.Position.Z)
	end
	return out
end

return LabService
