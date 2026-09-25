-- ServerScriptService.Server.FactoryService
-- The VexCorp Homework Factory, across Recess Row from the Hub. Kids that raiders get away with sit in
-- its holding pens along the back wall, next to Vex's own prize captives. Sneak in past the security
-- guards (their flashlights show where they're looking), hold E at a pen, and run the kid out of the
-- factory grounds. Once you're carrying, every guard comes for you and they're a step faster than you:
-- bonk them with your Ruler to shake them off. Get caught and the kid goes back in the pen and you
-- get thrown out. Get out the gate and your kid walks home to your Waiting Bench.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local PlotService = require(script.Parent.PlotService)
local Factory = require(script.Parent.StudentFactory)
local Walkers = require(script.Parent.Walkers)
local StealService = require(script.Parent.StealService)

local FactoryService = {}

local H = Config.Heist
local rgb = Color3.fromRGB

-- the building and its grounds, world coordinates (the gap between the two middle schools, +Z side)
local B = { x0 = -30, x1 = 30, z0 = 46, z1 = 126, h = 26 } -- building shell
local LOT = { x0 = -33, x1 = 33, z0 = 34, z1 = 134 } -- fenced grounds; leaving them with a kid = safe
local PEN_Z = 115.5 -- pen centres
local PEN_XS = { -24.5, -17.5, -10.5, -3.5, 3.5, 10.5, 17.5, 24.5 }
local PRIZE_PENS = { [1] = true, [8] = true } -- the end pens hold Vex's own captives

local root -- workspace.VexFactory
local guardsFolder
local pens = {} -- [i] = { model, prompt, kidModel, kind = "captured"|"prize"|nil, owner, entry, restockAt }
local guards = {} -- list of guard state
local heists = {} -- [player] = { pen, kid, def, grade, prize }
local stunUntil = {} -- [player] = os.clock() they can move again after being thrown out

local function now() return os.clock() end

-- the tutorial's rescue: the guards don't spot you, and once you grab the kid only the nearest one
-- comes after you, slower than you can run
local function lenient(player)
	local p = Data.get(player)
	local step = p and p.tutorial and Config.Tutorial[p.tutorial]
	return step ~= nil and step.id == "rescue"
end

---------------------------------------------------------------------------
-- building
---------------------------------------------------------------------------
local SMOOTH = { [Enum.Material.Neon] = true, [Enum.Material.Glass] = true, [Enum.Material.Metal] = true, [Enum.Material.DiamondPlate] = true, [Enum.Material.SmoothPlastic] = true }
local function part(parent, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Concrete
	p.Anchored = true
	if SMOOTH[p.Material] then
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	end
	if props then
		for k, v in props do p[k] = v end
	end
	p.Parent = parent
	return p
end
local function cyl(parent, name, d, len, cf, color, material)
	return part(parent, name, Vector3.new(len, d, d), cf, color, material, { Shape = Enum.PartType.Cylinder })
end
local function sign(p, face, text, color, font, stroke)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.LightInfluence = 0
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 30
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Name = "Label"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = font or Enum.Font.LuckiestGuy
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color
	t.Parent = g
	if stroke then
		local s = Instance.new("UIStroke")
		s.Thickness = 4
		s.Color = stroke
		s.Parent = t
	end
	return t
end
local function light(p, range, brightness, color)
	local l = Instance.new("PointLight")
	l.Range = range
	l.Brightness = brightness
	l.Color = color or rgb(255, 244, 220)
	l.Parent = p
	return l
end

local CONCRETE = rgb(150, 150, 158)
local DARK = rgb(52, 50, 62)
local PURPLE = rgb(105, 45, 150)
local LILAC = rgb(200, 150, 255)
local STEEL = rgb(120, 124, 134)

local function buildShell(m)
	local cx, cz = (B.x0 + B.x1) / 2, (B.z0 + B.z1) / 2
	local W, D, Hh = B.x1 - B.x0, B.z1 - B.z0, B.h
	-- the grounds: asphalt, painted lines, and a chain-link fence with barbed wire
	part(m, "Yard", Vector3.new(LOT.x1 - LOT.x0, 0.3, LOT.z1 - LOT.z0), CFrame.new(0, 0.15, (LOT.z0 + LOT.z1) / 2), rgb(70, 70, 76), Enum.Material.Asphalt)
	for _, x in { -12, 12 } do
		part(m, "Line", Vector3.new(0.4, 0.32, 10), CFrame.new(x, 0.17, 40), rgb(240, 210, 60), Enum.Material.SmoothPlastic)
	end
	local function fence(x0, z0, x1, z1)
		local len = math.max(math.abs(x1 - x0), math.abs(z1 - z0))
		local along = x1 ~= x0
		local mid = Vector3.new((x0 + x1) / 2, 0, (z0 + z1) / 2)
		local size = along and Vector3.new(len, 7, 0.2) or Vector3.new(0.2, 7, len)
		part(m, "Mesh", size, CFrame.new(mid + Vector3.new(0, 3.5, 0)), rgb(170, 175, 185), Enum.Material.DiamondPlate, { Transparency = 0.55, CanCollide = true })
		local rail = along and Vector3.new(len, 0.25, 0.25) or Vector3.new(0.25, 0.25, len)
		part(m, "Rail", rail, CFrame.new(mid + Vector3.new(0, 7, 0)), STEEL, Enum.Material.Metal)
		-- barbed wire: a twisted pair of thin rails just above
		part(m, "Barbs", rail * Vector3.new(1, 0.4, 1), CFrame.new(mid + Vector3.new(0, 7.7, 0)) * CFrame.Angles(along and math.rad(20) or 0, 0, along and 0 or math.rad(20)), rgb(90, 90, 100), Enum.Material.Metal)
		for i = 0, math.floor(len / 6) do
			local t = i * 6 / len
			local pos = Vector3.new(x0 + (x1 - x0) * t, 4, z0 + (z1 - z0) * t)
			cyl(m, "Post", 0.4, 8, CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), STEEL, Enum.Material.Metal)
		end
	end
	fence(LOT.x0, LOT.z0, -9, LOT.z0)
	fence(9, LOT.z0, LOT.x1, LOT.z0)
	fence(LOT.x0, LOT.z0, LOT.x0, LOT.z1)
	fence(LOT.x1, LOT.z0, LOT.x1, LOT.z1)
	fence(LOT.x0, LOT.z1, LOT.x1, LOT.z1)
	-- the gate: two pillars, a sign arch, a striped barrier arm (raised), a guard booth
	for _, x in { -9.5, 9.5 } do
		part(m, "GatePillar", Vector3.new(2, 11, 2), CFrame.new(x, 5.5, LOT.z0), DARK)
		part(m, "PillarCap", Vector3.new(2.4, 0.6, 2.4), CFrame.new(x, 11.3, LOT.z0), PURPLE, Enum.Material.Metal)
	end
	local arch = part(m, "GateSign", Vector3.new(21, 3.2, 1), CFrame.new(0, 12.6, LOT.z0), DARK)
	sign(arch, Enum.NormalId.Front, "VEXCORP  \u{2022}  KEEP OUT", LILAC, Enum.Font.LuckiestGuy, rgb(30, 10, 45))
	sign(arch, Enum.NormalId.Back, "VEXCORP", LILAC, Enum.Font.LuckiestGuy, rgb(30, 10, 45))
	-- a boom barrier, raised: a post with a counterweight and a red-and-white arm pointing up
	part(m, "BarrierPost", Vector3.new(1.4, 3.2, 1.4), CFrame.new(8.2, 1.6, LOT.z0 - 1), DARK)
	part(m, "Counterweight", Vector3.new(1.2, 1.2, 1.6), CFrame.new(8.2, 2.6, LOT.z0 - 2.2), rgb(40, 40, 46), Enum.Material.Metal)
	for k = 0, 5 do
		part(m, "BarrierArm", Vector3.new(0.45, 1.5, 0.45), CFrame.new(8.2, 4 + k * 1.5, LOT.z0 - 1) * CFrame.Angles(0, 0, math.rad(4)), k % 2 == 0 and rgb(225, 40, 50) or rgb(245, 245, 245), Enum.Material.SmoothPlastic)
	end
	part(m, "Booth", Vector3.new(6, 7, 6), CFrame.new(-17, 3.5, 40), rgb(200, 200, 205), Enum.Material.SmoothPlastic)
	part(m, "BoothRoof", Vector3.new(7, 0.6, 7), CFrame.new(-17, 7.3, 40), PURPLE, Enum.Material.Metal)
	part(m, "BoothWindow", Vector3.new(4.4, 2.6, 0.2), CFrame.new(-17, 4.6, 36.95), rgb(120, 170, 220), Enum.Material.Glass, { Transparency = 0.3 })

	-- the shell: concrete walls with a steel plinth, a purple band, and a dark roof edge
	local wallC = { Transparency = 0 }
	part(m, "BackWall", Vector3.new(W, Hh, 1.5), CFrame.new(cx, Hh / 2, B.z1 - 0.75), CONCRETE, Enum.Material.Concrete, wallC)
	for _, x in { B.x0 + 0.75, B.x1 - 0.75 } do
		part(m, "SideWall", Vector3.new(1.5, Hh, D), CFrame.new(x, Hh / 2, cz), CONCRETE, Enum.Material.Concrete, wallC)
	end
	-- front wall with the loading-bay opening (x -8..8, 14 high)
	local doorW, doorH = 16, 14
	local sideW = (W - doorW) / 2
	for _, s in { -1, 1 } do
		part(m, "FrontWall", Vector3.new(sideW, Hh, 1.5), CFrame.new(s * (doorW / 2 + sideW / 2), Hh / 2, B.z0 + 0.75), CONCRETE, Enum.Material.Concrete, wallC)
	end
	part(m, "FrontLintel", Vector3.new(doorW, Hh - doorH, 1.5), CFrame.new(0, doorH + (Hh - doorH) / 2, B.z0 + 0.75), CONCRETE, Enum.Material.Concrete, wallC)
	-- the rolled-up shutter and hazard stripes round the opening
	part(m, "Shutter", Vector3.new(doorW, 1.4, 1.2), CFrame.new(0, doorH + 0.4, B.z0 - 0.4), STEEL, Enum.Material.DiamondPlate)
	for i = 0, 7 do
		for _, s in { -1, 1 } do
			part(m, "Hazard", Vector3.new(0.3, 1.75, 0.2), CFrame.new(s * (doorW / 2 + 0.2), 0.9 + i * 1.75, B.z0 - 0.02), i % 2 == 0 and rgb(245, 200, 40) or rgb(25, 25, 25), Enum.Material.SmoothPlastic)
		end
	end
	-- plinth, band, parapet: strips round the outside of the walls
	for _, spec in {
		{ "Plinth", 2, 1, DARK, Enum.Material.Concrete },
		{ "Band", 3, 18.5, PURPLE, Enum.Material.Metal },
		{ "Parapet", 1.4, Hh + 0.7, DARK, Enum.Material.Concrete },
	} do
		local name, h, y, col, mat = spec[1], spec[2], spec[3], spec[4], spec[5]
		if name == "Plinth" then
			-- the front strip stops at the loading door
			for _, s in { -1, 1 } do
				part(m, name, Vector3.new(sideW + 0.3, h, 0.4), CFrame.new(s * (doorW / 2 + sideW / 2 + 0.15), y, B.z0 - 0.1), col, mat)
			end
		else
			part(m, name, Vector3.new(W + 0.6, h, 0.4), CFrame.new(cx, y, B.z0 - 0.1), col, mat)
		end
		part(m, name, Vector3.new(W + 0.6, h, 0.4), CFrame.new(cx, y, B.z1 + 0.1), col, mat)
		for _, x in { B.x0 - 0.1, B.x1 + 0.1 } do
			part(m, name, Vector3.new(0.4, h, D + 0.6), CFrame.new(x, y, cz), col, mat)
		end
	end
	part(m, "Roof", Vector3.new(W, 1.2, D), CFrame.new(cx, Hh + 0.6, cz), rgb(80, 80, 88), Enum.Material.Concrete)
	-- a row of barred windows high on the front and sides
	local function window(cf)
		part(m, "Window", Vector3.new(5, 3.2, 0.3), cf, rgb(40, 50, 75), Enum.Material.Glass, { Transparency = 0.2 })
		part(m, "Sill", Vector3.new(5.6, 0.4, 0.8), cf * CFrame.new(0, -1.8, -0.1), DARK)
		for i = -2, 2 do
			part(m, "Bar", Vector3.new(0.18, 3.2, 0.18), cf * CFrame.new(i * 1, 0, -0.25), rgb(40, 40, 45), Enum.Material.Metal)
		end
	end
	for _, x in { -22, -14, 14, 22 } do
		window(CFrame.new(x, 22, B.z0 - 0.05))
	end
	for _, z in { 60, 76, 92, 108 } do
		window(CFrame.new(B.x0 - 0.05, 22, z) * CFrame.Angles(0, math.rad(-90), 0))
		window(CFrame.new(B.x1 + 0.05, 22, z) * CFrame.Angles(0, math.rad(90), 0))
	end
	-- the big front sign: a VEXCORP nameboard with a neon edge, and the V logo
	local board = part(m, "Nameboard", Vector3.new(34, 6, 0.8), CFrame.new(0, 21, B.z0 - 0.9), PURPLE, Enum.Material.SmoothPlastic)
	sign(board, Enum.NormalId.Front, "VEXCORP HOMEWORK FACTORY", rgb(255, 255, 255), Enum.Font.LuckiestGuy, rgb(60, 20, 90))
	for _, y in { 17.8, 24.2 } do
		part(m, "NeonEdge", Vector3.new(34.4, 0.3, 0.3), CFrame.new(0, y, B.z0 - 1.2), LILAC, Enum.Material.Neon)
	end
	for _, x in { -17.2, 17.2 } do
		part(m, "NeonEdge", Vector3.new(0.3, 6.6, 0.3), CFrame.new(x, 21, B.z0 - 1.2), LILAC, Enum.Material.Neon)
	end
	-- smokestacks with purple smoke, and roof vents
	for _, x in { -20, 20 } do
		local stack = cyl(m, "Smokestack", 5, 22, CFrame.new(x, Hh + 11, B.z1 - 10) * CFrame.Angles(0, 0, math.rad(90)), rgb(110, 105, 115), Enum.Material.Concrete)
		cyl(m, "StackBand", 5.4, 1.2, CFrame.new(x, Hh + 18, B.z1 - 10) * CFrame.Angles(0, 0, math.rad(90)), PURPLE, Enum.Material.Metal)
		cyl(m, "StackRim", 5.6, 0.8, CFrame.new(x, Hh + 22.2, B.z1 - 10) * CFrame.Angles(0, 0, math.rad(90)), DARK, Enum.Material.Metal)
		local puff = part(m, "SmokeSource", Vector3.new(1, 1, 1), CFrame.new(x, Hh + 23, B.z1 - 10), DARK, nil, { Transparency = 1, CanCollide = false })
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(rgb(150, 110, 190), rgb(90, 80, 100))
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 14) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime = NumberRange.new(5, 7)
		e.Speed = NumberRange.new(4, 6)
		e.SpreadAngle = Vector2.new(12, 12)
		e.Acceleration = Vector3.new(1.5, 1, 0)
		e.Rate = 3
		e.RotSpeed = NumberRange.new(-20, 20)
		e.Parent = puff
		_ = stack
	end
	for _, x in { -8, 8 } do
		part(m, "Vent", Vector3.new(6, 3, 6), CFrame.new(x, Hh + 2.7, 70), STEEL, Enum.Material.DiamondPlate)
	end
	-- floodlights on the front corners
	for _, x in { B.x0 + 2, B.x1 - 2 } do
		local lamp = part(m, "Floodlight", Vector3.new(2, 1.2, 1.4), CFrame.new(x, 15, B.z0 - 1.4) * CFrame.Angles(math.rad(-30), 0, 0), rgb(255, 250, 225), Enum.Material.Neon)
		local s = Instance.new("SpotLight")
		s.Face = Enum.NormalId.Front
		s.Angle = 80
		s.Range = 40
		s.Brightness = 2
		s.Parent = lamp
	end
end

-- a conveyor belt along X with rollers, a housing press in the middle, and homework on it
local function buildBelt(m, z)
	local len, y = 44, 2.4
	part(m, "BeltFrame", Vector3.new(len, 1.2, 4.2), CFrame.new(0, y - 0.8, z), DARK, Enum.Material.Metal)
	part(m, "Belt", Vector3.new(len, 0.25, 3.6), CFrame.new(0, y - 0.05, z), rgb(30, 30, 34), Enum.Material.Rubber)
	for _, s in { -1, 1 } do
		part(m, "BeltRail", Vector3.new(len, 0.5, 0.3), CFrame.new(0, y + 0.1, z + s * 2), rgb(245, 200, 40), Enum.Material.Metal)
	end
	for i = 0, 8 do
		local x = -len / 2 + 2 + i * 5
		part(m, "BeltLeg", Vector3.new(0.6, y - 1.4, 0.6), CFrame.new(x, (y - 1.4) / 2, z - 1.6), STEEL, Enum.Material.Metal)
		part(m, "BeltLeg", Vector3.new(0.6, y - 1.4, 0.6), CFrame.new(x, (y - 1.4) / 2, z + 1.6), STEEL, Enum.Material.Metal)
	end
	-- the Homework Press: a housing over the belt with a piston that stamps (animated by the client)
	part(m, "PressBeam", Vector3.new(6, 1.4, 5.2), CFrame.new(0, 9.1, z), PURPLE, Enum.Material.Metal)
	for _, s in { -1, 1 } do
		part(m, "PressLeg", Vector3.new(0.9, 9, 5.2), CFrame.new(s * 2.9, 5.5, z), PURPLE, Enum.Material.Metal)
	end
	part(m, "PressTop", Vector3.new(6.6, 1.6, 5.8), CFrame.new(0, 10.6, z), DARK, Enum.Material.Metal)
	local piston = part(m, "Piston", Vector3.new(3.6, 1, 3.2), CFrame.new(0, 7, z), rgb(200, 200, 210), Enum.Material.DiamondPlate)
	CollectionService:AddTag(piston, "Piston")
	piston:SetAttribute("BaseY", 7)
	local warn = part(m, "PressLamp", Vector3.new(0.8, 0.8, 0.8), CFrame.new(0, 11.8, z), rgb(255, 60, 60), Enum.Material.Neon)
	light(warn, 8, 1, rgb(255, 60, 60))
	-- homework sheets riding the belt (the client slides them along)
	for i = 0, 9 do
		local sheet = part(m, "Homework", Vector3.new(1.4, 0.12, 1.9), CFrame.new(-len / 2 + 2 + i * 4.3, y + 0.15, z) * CFrame.Angles(0, math.rad(math.random(-15, 15)), 0), rgb(250, 250, 245), Enum.Material.SmoothPlastic, { CanCollide = false })
		sheet:SetAttribute("BeltZ", z)
		sheet:SetAttribute("BeltLen", len - 4)
		sheet:SetAttribute("Offset", i * 4.3)
		CollectionService:AddTag(sheet, "BeltItem")
		sign(sheet, Enum.NormalId.Top, ({ "F", "D-", "SEE ME", "F", "C-" })[i % 5 + 1], rgb(210, 30, 30), Enum.Font.PermanentMarker)
	end
end

local function buildInterior(m)
	local cx, cz = (B.x0 + B.x1) / 2, (B.z0 + B.z1) / 2
	local W, D = B.x1 - B.x0, B.z1 - B.z0
	part(m, "Floor", Vector3.new(W - 3, 0.4, D - 3), CFrame.new(cx, 0.35, cz), rgb(125, 128, 135), Enum.Material.Concrete)
	-- painted walkways: yellow lines down the middle aisle and across the front
	for _, x in { -2.5, 2.5 } do
		part(m, "FloorLine", Vector3.new(0.35, 0.42, D - 6), CFrame.new(x, 0.37, cz), rgb(240, 200, 50), Enum.Material.SmoothPlastic)
	end
	-- hanging lamps in two rows
	for _, x in { -14, 14 } do
		for _, z in { 58, 80, 102 } do
			cyl(m, "LampCord", 0.12, 8, CFrame.new(x, B.h - 4, z) * CFrame.Angles(0, 0, math.rad(90)), rgb(30, 30, 30), Enum.Material.Metal)
			local shade = part(m, "LampShade", Vector3.new(3, 1, 3), CFrame.new(x, B.h - 8.5, z), DARK, Enum.Material.Metal)
			local bulb = part(m, "Bulb", Vector3.new(1.4, 0.5, 1.4), CFrame.new(x, B.h - 9.2, z), rgb(255, 240, 200), Enum.Material.Neon)
			light(bulb, 26, 1.3, rgb(255, 238, 205))
			_ = shade
		end
	end
	-- steel roof trusses
	for _, z in { 56, 70, 84, 98, 112 } do
		part(m, "Truss", Vector3.new(W - 3, 1, 1), CFrame.new(cx, B.h - 1.5, z), STEEL, Enum.Material.Metal)
	end
	buildBelt(m, 70)
	buildBelt(m, 92)
	-- crates of homework stacked by the side walls
	for _, spec in { { -25, 56 }, { -25, 60 }, { -21.5, 56 }, { 25, 84 }, { 25, 88 }, { 21.5, 84 } } do
		local c = part(m, "Crate", Vector3.new(3.4, 3.4, 3.4), CFrame.new(spec[1], 2.2, spec[2]), rgb(150, 110, 70), Enum.Material.WoodPlanks)
		sign(c, Enum.NormalId.Front, "HW", rgb(60, 30, 20), Enum.Font.Arcade)
	end
	part(m, "Crate", Vector3.new(3.4, 3.4, 3.4), CFrame.new(-23.2, 5.6, 57.6) * CFrame.Angles(0, math.rad(20), 0), rgb(150, 110, 70), Enum.Material.WoodPlanks)
	-- the back wall: a giant Vex poster over the pens
	local poster = part(m, "VexPoster", Vector3.new(30, 7, 0.3), CFrame.new(0, 17.5, B.z1 - 1.7), rgb(40, 20, 55))
	sign(poster, Enum.NormalId.Front, "HOMEWORK IS THE FUTURE.\n- Dr. V. Vex", LILAC, Enum.Font.LuckiestGuy, rgb(15, 5, 25))
	for _, x in { -15.2, 15.2 } do
		part(m, "PosterNeon", Vector3.new(0.3, 7.4, 0.3), CFrame.new(x, 17.5, B.z1 - 1.9), LILAC, Enum.Material.Neon)
	end
	-- the alarm beacons (they spin red while a kid is being taken)
	for _, x in { -18, 0, 18 } do
		local beacon = part(m, "Beacon", Vector3.new(1.2, 1.2, 1.2), CFrame.new(x, B.h - 3, 60), rgb(120, 30, 40), Enum.Material.SmoothPlastic)
		CollectionService:AddTag(beacon, "AlarmBeacon")
		local l = light(beacon, 30, 0, rgb(255, 40, 60))
		l.Name = "AlarmLight"
	end
end

-- a holding pen: floor plate, bars on three sides and a door, a nameplate, a spotlight, a prompt
local function buildPen(m, i)
	local x = PEN_XS[i]
	local pen = Instance.new("Model")
	pen.Name = "Pen" .. i
	pen.Parent = m
	local w, d, h = 6.4, 7, 8
	local z0 = PEN_Z - d / 2
	part(pen, "PenFloor", Vector3.new(w, 0.4, d), CFrame.new(x, 0.6, PEN_Z), rgb(70, 70, 78), Enum.Material.DiamondPlate)
	part(pen, "PenTop", Vector3.new(w, 0.4, d), CFrame.new(x, h + 0.6, PEN_Z), rgb(60, 60, 66), Enum.Material.Metal)
	local barC = rgb(55, 55, 62)
	for k = 0, 5 do
		local bx = x - w / 2 + 0.5 + k * ((w - 1) / 5)
		cyl(pen, "Bar", 0.26, h, CFrame.new(bx, h / 2 + 0.6, z0) * CFrame.Angles(0, 0, math.rad(90)), barC, Enum.Material.Metal)
	end
	for _, s in { -1, 1 } do
		for k = 0, 4 do
			local bz = z0 + 0.6 + k * ((d - 1.2) / 4)
			cyl(pen, "Bar", 0.26, h, CFrame.new(x + s * w / 2, h / 2 + 0.6, bz) * CFrame.Angles(0, 0, math.rad(90)), barC, Enum.Material.Metal)
		end
	end
	part(pen, "CrossBar", Vector3.new(w, 0.3, 0.3), CFrame.new(x, 4.6, z0), barC, Enum.Material.Metal)
	-- the lock box
	part(pen, "Lock", Vector3.new(0.9, 1.1, 0.5), CFrame.new(x + w / 2 - 1.2, 4, z0 - 0.3), rgb(230, 190, 60), Enum.Material.Metal)
	local plate = part(pen, "Nameplate", Vector3.new(w - 0.4, 1.3, 0.2), CFrame.new(x, h + 1.8, z0), rgb(250, 245, 230), Enum.Material.SmoothPlastic)
	local label = sign(plate, Enum.NormalId.Front, "", rgb(40, 30, 50), Enum.Font.FredokaOne)
	local lamp = part(pen, "PenLamp", Vector3.new(0.8, 0.3, 0.8), CFrame.new(x, h + 0.2, PEN_Z), rgb(255, 245, 215), Enum.Material.Neon)
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Bottom
	spot.Angle = 70
	spot.Range = 12
	spot.Brightness = 2
	spot.Parent = lamp
	local hold = part(pen, "PromptSpot", Vector3.new(1, 1, 1), CFrame.new(x, 3, z0 - 0.6), barC, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RescuePrompt"
	prompt.ActionText = "Rescue"
	prompt.ObjectText = ""
	prompt.HoldDuration = H.holdTime
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 7
	prompt.Enabled = false
	prompt:SetAttribute("Color", LILAC)
	prompt.Parent = hold
	pens[i] = { model = pen, prompt = prompt, label = label, x = x }
	return pen
end

---------------------------------------------------------------------------
-- what's in the pens
---------------------------------------------------------------------------
local function clearPenKid(pen)
	if pen.kidModel then pen.kidModel:Destroy() end
	pen.kidModel = nil
end

-- a mystery captive: a dark silhouette with a question mark instead of a nametag
local function silhouette(model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then d.Color = rgb(30, 25, 40) d.Material = Enum.Material.SmoothPlastic end
		if d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Decal") or d:IsA("Highlight") then d:Destroy() end
	end
end

local function placeKid(pen, def, grade, prize)
	clearPenKid(pen)
	local model = Factory.build(def, grade)
	Factory.setMode(model, "owned")
	local so = Factory.standOffset(model)
	model.PrimaryPart.CFrame = CFrame.lookAt(Vector3.new(pen.x, 0.8 + so, PEN_Z + 1), Vector3.new(pen.x, 0.8 + so, PEN_Z - 10))
	-- the nameplate says who's in here; the kid's own floating tag would just clutter the bars
	for _, d in model:GetDescendants() do
		if d:IsA("BillboardGui") then d:Destroy() end
	end
	if prize then
		silhouette(model)
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(60, 60)
		bb.StudsOffset = Vector3.new(0, 3, 0)
		bb.LightInfluence = 0
		bb.Parent = model.PrimaryPart
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.LuckiestGuy
		t.TextScaled = true
		t.Text = "?"
		t.TextColor3 = LILAC
		t.Parent = bb
		local s = Instance.new("UIStroke")
		s.Thickness = 3
		s.Parent = t
	end
	model.Parent = pen.model
	Factory.play(model, "idle")
	pen.kidModel = model
end

-- rebuild every pen from the players' captured kids and Vex's prizes
function FactoryService.refresh()
	-- captured kids of everyone in the server, oldest first, into the middle pens
	-- (a kid someone is carrying out right now keeps their pen, and isn't shown in another one)
	local inFlight = {}
	for _, hs in heists do
		if hs.pen.entry then inFlight[hs.pen.entry] = true end
	end
	-- fair shares: everyone's tutorial kid first, then each player's kids in turn (oldest first),
	-- so one player with a pile of captured kids can't take every pen
	local lists = {}
	local players = {}
	for player, p in Data.all() do
		local list = {}
		for idx, c in p.captured or {} do
			if not inFlight[c] then table.insert(list, { player = player, idx = idx, entry = c }) end
		end
		if #list > 0 then
			lists[player] = list
			table.insert(players, player)
		end
	end
	table.sort(players, function(a, b) return a.UserId < b.UserId end)
	local queue = {}
	for _, player in players do
		for i = #lists[player], 1, -1 do
			if lists[player][i].entry.story then table.insert(queue, table.remove(lists[player], i)) end
		end
	end
	local round = 1
	local more = true
	while more do
		more = false
		for _, player in players do
			local q = lists[player][round]
			if q then
				table.insert(queue, q)
				more = true
			end
		end
		round += 1
	end
	local qi = 1
	for i, pen in pens do
		if pen.takenBy then continue end
		if PRIZE_PENS[i] then
			if pen.kind ~= "prize" then
				if not pen.restockAt or now() >= pen.restockAt then
					pen.kind = "prize"
					pen.owner = nil
					pen.entry = nil
					local pool = {}
					for _, s in Config.Students do
						if s.rarity == "Rare" or s.rarity == "Epic" then table.insert(pool, s) end
					end
					placeKid(pen, pool[math.random(#pool)], "Normal", true)
					pen.label.Text = "VEX'S PRIZE \u{2022} ???"
					pen.prompt.ObjectText = "Vex's mystery captive"
					pen.prompt.ActionText = "Steal"
					pen.prompt.Enabled = true
					pen.model:SetAttribute("OwnerId", nil)
					pen.prompt:SetAttribute("OwnerOnly", nil)
				else
					pen.kind = nil
					clearPenKid(pen)
					pen.label.Text = "EMPTY"
					pen.prompt.Enabled = false
				end
			end
		else
			local q = queue[qi]
			qi += 1
			if q then
				local def = Config.StudentById[q.entry.id]
				local same = pen.kind == "captured" and pen.owner == q.player and pen.entry == q.entry
				if def and not same then
					pen.kind = "captured"
					pen.owner = q.player
					pen.entry = q.entry
					placeKid(pen, def, q.entry.grade or "Normal", false)
					pen.label.Text = (q.player.DisplayName .. "'s " .. def.name):upper()
					pen.prompt.ObjectText = def.name
					pen.prompt.ActionText = "Rescue"
					pen.prompt.Enabled = true
					pen.model:SetAttribute("OwnerId", q.player.UserId)
					pen.prompt:SetAttribute("OwnerOnly", true)
				end
			elseif pen.kind then
				pen.kind = nil
				pen.owner = nil
				pen.entry = nil
				clearPenKid(pen)
				pen.label.Text = ""
				pen.prompt.Enabled = false
				pen.model:SetAttribute("OwnerId", nil)
			end
		end
	end
end

---------------------------------------------------------------------------
-- guards
---------------------------------------------------------------------------
local GUARD = { id = "VexGuard", name = "Security", title = "VexCorp Security", mult = 1, outfit = "guard" }
local ROUTES = {
	{ Vector3.new(-26, 0, 63), Vector3.new(26, 0, 63), Vector3.new(26, 0, 79), Vector3.new(-26, 0, 79) },
	{ Vector3.new(26, 0, 85), Vector3.new(-26, 0, 85), Vector3.new(-26, 0, 101), Vector3.new(26, 0, 101) },
	{ Vector3.new(-26, 0, 107), Vector3.new(26, 0, 107) },
	{ Vector3.new(-18, 0, 53), Vector3.new(18, 0, 53) },
}

local function inBuilding(pos)
	return pos.X > B.x0 + 1 and pos.X < B.x1 - 1 and pos.Z > B.z0 + 1 and pos.Z < B.z1 - 1 and pos.Y < B.h
end
local function inLot(pos)
	return pos.X > LOT.x0 and pos.X < LOT.x1 and pos.Z > LOT.z0 and pos.Z < LOT.z1
end

local function guardTag(g, text, color)
	local label = g.label
	if label then
		label.Text = text
		label.TextColor3 = color or rgb(255, 255, 255)
	end
end

local function makeGuard(route)
	local model = Factory.buildTeacher(GUARD, 1)
	model.Name = "Guard"
	local so = Factory.standOffset(model)
	local pts = {}
	for _, p in route do table.insert(pts, Vector3.new(p.X, 0.55 + so, p.Z)) end
	-- a loop: out and back along the route
	local loop = table.clone(pts)
	if #route == 2 then loop = { pts[1], pts[2] } end
	model.PrimaryPart.CFrame = CFrame.lookAt(pts[1], pts[2])
	-- the "!" / "?" over the head
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(60, 60)
	bb.StudsOffset = Vector3.new(0, 3.4, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 80
	bb.Parent = model.Head
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.LuckiestGuy
	t.TextScaled = true
	t.Text = ""
	t.Parent = bb
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Parent = t
	model:SetAttribute("Guard", true)
	model.Parent = guardsFolder
	local g = { model = model, route = loop, leg = 1, state = "patrol", so = so, label = t, stunUntil = 0, seenAt = 0 }
	return g
end

local function patrol(g)
	g.state = "patrol"
	g.target = nil
	g.slow = nil
	guardTag(g, "")
	Factory.play(g.model, "walk")
	local function nextLeg()
		if g.state ~= "patrol" or not g.model.Parent then return end
		g.leg = g.leg % #g.route + 1
		Walkers.walk(g.model, { g.route[g.leg] }, H.patrolSpeed, nextLeg, { flat = true })
	end
	-- head for the nearest route point first
	local root = g.model.PrimaryPart
	local best, bestD = 1, math.huge
	for i, p in g.route do
		local d = (p - root.Position).Magnitude
		if d < bestD then best, bestD = i, d end
	end
	g.leg = best
	Walkers.walk(g.model, { g.route[best] }, H.patrolSpeed, nextLeg, { flat = true })
end

-- a guard who spots you (or hears the alarm) shows a "!" and takes a moment before he runs
local function chase(g, player, reaction)
	if g.state == "chase" and g.target == player then return end
	Walkers.stop(g.model)
	g.state = "chase"
	g.target = player
	g.slow = nil
	g.seenAt = now()
	g.reactUntil = now() + (reaction or H.reaction)
	guardTag(g, "!", rgb(255, 70, 70))
	Factory.play(g.model, "idle")
end

local function canSee(g, char)
	local root = g.model.PrimaryPart
	local proot = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not proot then return false end
	local d = proot.Position - root.Position
	local flat = Vector3.new(d.X, 0, d.Z)
	if flat.Magnitude < H.hearRange then return true end
	if flat.Magnitude > H.sightRange then return false end
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
	if flat.Unit:Dot(look) < math.cos(math.rad(H.sightAngle / 2)) then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { guardsFolder, char, root.Parent }
	local eye = root.Position + Vector3.new(0, 1.5, 0)
	local hit = workspace:Raycast(eye, (proot.Position + Vector3.new(0, 1, 0)) - eye, params)
	return hit == nil or hit.Instance:IsDescendantOf(char)
end

---------------------------------------------------------------------------
-- the heist
---------------------------------------------------------------------------
local function setCarrySpeed(player, on)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if on then
		hum.WalkSpeed = H.carrySpeed
	else
		StealService.setSpeed(player)
	end
end

local function alarm(on)
	for _, b in CollectionService:GetTagged("AlarmBeacon") do
		if b:IsDescendantOf(root) then
			b.Color = on and rgb(255, 40, 60) or rgb(120, 30, 40)
			b.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
			local l = b:FindFirstChild("AlarmLight")
			if l then l.Brightness = on and 3 or 0 end
		end
	end
	root:SetAttribute("Alarm", on or nil)
end

local function anyHeist()
	return next(heists) ~= nil
end

-- the kid goes back into their pen
local function dropHeist(player, why)
	local hs = heists[player]
	if not hs then return end
	heists[player] = nil
	if hs.kid then hs.kid:Destroy() end
	local pen = hs.pen
	pen.takenBy = nil
	if pen.kind == "prize" then
		placeKid(pen, hs.def, "Normal", true)
	elseif pen.kind == "captured" then
		placeKid(pen, hs.def, hs.grade, false)
		if pen.owner then pen.model:SetAttribute("OwnerId", pen.owner.UserId) end
	end
	pen.prompt.Enabled = pen.kind ~= nil
	player:SetAttribute("Heist", nil)
	if player.Parent then
		setCarrySpeed(player, false)
		if why then Remotes.Notify:FireClient(player, why, "bad") end
		Remotes.Push:FireClient(player, "heist", { state = "failed" })
	end
	if not anyHeist() then alarm(false) end
end

local function thrownOut(player)
	local char = player.Character
	local proot = char and char:FindFirstChild("HumanoidRootPart")
	if not proot then return end
	dropHeist(player, "Security caught you and threw you out!")
	char:PivotTo(CFrame.lookAt(Vector3.new(math.random(-5, 5), 3.5, LOT.z0 - 6), Vector3.new(0, 3.5, 0)))
	stunUntil[player] = now() + H.caughtStun
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = 0 end
	task.delay(H.caughtStun, function()
		if player.Parent then StealService.setSpeed(player) end
	end)
end

-- made it out of the grounds with a kid
local function escaped(player)
	local hs = heists[player]
	if not hs then return end
	heists[player] = nil
	if hs.kid then hs.kid:Destroy() end
	local pen = hs.pen
	pen.takenBy = nil
	player:SetAttribute("Heist", nil)
	setCarrySpeed(player, false)
	local p = Data.get(player)
	local LetterService = require(script.Parent.LetterService)
	if pen.kind == "captured" and p then
		-- your own kid: out of the captured list and back to your bench, free
		for i, c in p.captured or {} do
			if c == pen.entry then table.remove(p.captured, i) break end
		end
		pen.kind, pen.owner, pen.entry = nil, nil, nil
		clearPenKid(pen)
		pen.label.Text = ""
		pen.model:SetAttribute("OwnerId", nil)
		if not LetterService.deliver(player, hs.def, true, hs.grade) then
			-- the bench is full of gifts: they'll be there next time (as they were)
			p.pendingBench = p.pendingBench or {}
			table.insert(p.pendingBench, { id = hs.def.id, grade = hs.grade })
		end
		Remotes.Push:FireClient(player, "heist", { state = "rescued", name = hs.def.name })
		Remotes.Notify:FireClient(player, ("You rescued %s! They're walking home to your Waiting Bench."):format(hs.def.name), "good")
		Signals.fire("rescued", player, hs.def, false)
	elseif pen.kind == "prize" and p then
		-- Vex's mystery captive: a kid rolled for how far along your school is
		local band = H.prizeByTier[math.clamp(p.tier or 1, 1, #H.prizeByTier)]
		local rarity = band[math.random(#band)]
		local pool = {}
		for _, s in Config.Students do
			if s.rarity == rarity then table.insert(pool, s) end
		end
		local def = pool[math.random(#pool)]
		pen.kind = nil
		pen.restockAt = now() + H.prizeRestock
		clearPenKid(pen)
		pen.label.Text = "EMPTY"
		pen.prompt.Enabled = false
		if not LetterService.deliver(player, def, true) then
			p.pendingBench = p.pendingBench or {}
			table.insert(p.pendingBench, def.id)
		end
		Remotes.Push:FireClient(player, "heist", { state = "prize", name = def.name, rarity = rarity })
		Remotes.Notify:FireClient(player, ("You stole Vex's captive: %s (%s)! They're on your Waiting Bench."):format(def.name, rarity), "good")
		Signals.fire("rescued", player, def, true)
	end
	if not anyHeist() then alarm(false) end
	FactoryService.refresh()
	-- guards give up
	for _, g in guards do
		if g.target == player then patrol(g) end
	end
end

local function takeKid(player, i)
	local pen = pens[i]
	if not pen or not pen.kind or pen.takenBy or heists[player] then return end
	if pen.kind == "captured" and pen.owner ~= player then return end
	if player:GetAttribute("Carrying") then return end
	local char = player.Character
	local proot = char and char:FindFirstChild("HumanoidRootPart")
	if not proot or (stunUntil[player] or 0) > now() then return end
	local def = pen.kind == "captured" and Config.StudentById[pen.entry.id] or (pen.kidModel and Config.StudentById[pen.kidModel:GetAttribute("StudentId")])
	if not def then return end
	local grade = pen.kind == "captured" and (pen.entry.grade or "Normal") or "Normal"
	clearPenKid(pen)
	pen.takenBy = player
	pen.prompt.Enabled = false
	pen.model:SetAttribute("OwnerId", nil) -- (the owner's client would switch an owner-only prompt back on)
	-- the kid rides over your head
	local prize = pen.kind == "prize"
	local kid = Factory.build(def, grade)
	Factory.setMode(kid, "carried")
	if prize then silhouette(kid) end
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
	heists[player] = { pen = pen, kid = kid, def = def, grade = grade, lastPos = proot.Position, lastT = now() }
	local shown = prize and "Vex's captive" or def.name
	player:SetAttribute("Heist", shown)
	setCarrySpeed(player, true)
	alarm(true)
	Remotes.Push:FireClient(player, "heist", { state = "carrying", name = shown })
	-- every guard comes running (a first-timer only gets the farthest one, and he's slow)
	if lenient(player) then
		local best, bestD
		for _, g in guards do
			local r = g.model.PrimaryPart
			local d = r and (r.Position - proot.Position).Magnitude or 0
			if not best or d > bestD then best, bestD = g, d end
		end
		if best then
			chase(best, player, 1.5)
			best.slow = true
		end
		Remotes.Notify:FireClient(player, "A guard heard you! Run for the gate (bonk him if he gets close).", "steal")
	else
		for _, g in guards do
			if now() >= g.stunUntil then chase(g, player) end
		end
	end
end

-- the Ruler stuns a guard and knocks him back
local function onSwing(player, proot)
	local look = Vector3.new(proot.CFrame.LookVector.X, 0, proot.CFrame.LookVector.Z)
	look = look.Magnitude > 1e-3 and look.Unit or Vector3.new(0, 0, -1)
	for _, g in guards do
		local root = g.model.PrimaryPart
		if root and now() >= g.stunUntil then
			local d = root.Position - proot.Position
			local flat = Vector3.new(d.X, 0, d.Z)
			if flat.Magnitude < 9 and (flat.Magnitude < 3.5 or flat.Unit:Dot(look) > 0.25) then
				g.stunUntil = now() + H.guardStun
				Walkers.stop(g.model)
				g.state = "stunned"
				guardTag(g, "@#!", rgb(255, 230, 90))
				Factory.play(g.model, "fall")
				Remotes.Sfx:FireClient(player, "Bonk")
				Remotes.Push:FireClient(player, "hit", { pos = root.Position + Vector3.new(0, 2, 0) })
				-- knocked back along the swing, a little hop
				local start = root.CFrame
				local dir = flat.Magnitude > 1e-3 and flat.Unit or look
				local t0 = now()
				local conn
				conn = RunService.Heartbeat:Connect(function()
					local a = math.min(1, (now() - t0) / 0.35)
					if not root.Parent then conn:Disconnect() return end
					local pos = start.Position + dir * 7 * a + Vector3.new(0, math.sin(a * math.pi) * 2.2, 0)
					if not inBuilding(pos) then pos = Vector3.new(math.clamp(pos.X, B.x0 + 2, B.x1 - 2), pos.Y, math.clamp(pos.Z, B.z0 + 2, B.z1 - 2)) end
					root.CFrame = CFrame.new(pos) * (start - start.Position)
					if a >= 1 then conn:Disconnect() end
				end)
				return
			end
		end
	end
end

---------------------------------------------------------------------------
-- the loop: guards look, chase, catch; carriers escape
---------------------------------------------------------------------------
local function tick(dt)
	for _, g in guards do
		local root = g.model.PrimaryPart
		if not root then continue end
		if g.state == "stunned" then
			if now() >= g.stunUntil then
				guardTag(g, "")
				-- back after whoever is carrying, or back on patrol
				local target = g.target
				if target and heists[target] then chase(g, target) else patrol(g) end
			end
			continue
		end
		if g.state == "patrol" then
			for _, player in Players:GetPlayers() do
				local char = player.Character
				local proot = char and char:FindFirstChild("HumanoidRootPart")
				if proot and inBuilding(proot.Position) and (stunUntil[player] or 0) <= now() and not lenient(player) and canSee(g, char) then
					chase(g, player)
					break
				end
			end
		elseif g.state == "chase" then
			local player = g.target
			local char = player and player.Parent and player.Character
			local proot = char and char:FindFirstChild("HumanoidRootPart")
			local carrying = player and heists[player] ~= nil
			if not proot or not inLot(proot.Position) then
				patrol(g)
				continue
			end
			if canSee(g, char) or carrying then g.seenAt = now() end
			if now() - g.seenAt > H.loseAfter then
				guardTag(g, "?", rgb(255, 230, 90))
				task.delay(0.8, function() if g.state == "patrol" then guardTag(g, "") end end)
				patrol(g)
				continue
			end
			-- run straight at them, but never out of the building (after the moment to react)
			local d = proot.Position - root.Position
			local flat = Vector3.new(d.X, 0, d.Z)
			if g.reactUntil and now() < g.reactUntil then
				if flat.Magnitude > 1e-3 then root.CFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit) end
				continue
			end
			if g.reactUntil then
				g.reactUntil = nil
				Factory.play(g.model, "run")
			end
			if flat.Magnitude < H.catchRange then
				thrownOut(player)
				patrol(g)
				continue
			end
			local speed = carrying and (g.slow and H.tutorialChase or H.chaseSpeedCarry) or H.chaseSpeed
			local step = math.min(flat.Magnitude, speed * dt)
			local np = root.Position + flat.Unit * step
			np = Vector3.new(math.clamp(np.X, B.x0 + 2, B.x1 - 2), 0.55 + g.so, math.clamp(np.Z, B.z0 + 2, B.z1 - 2))
			root.CFrame = CFrame.lookAt(np, np + flat.Unit)
		end
	end
	-- carriers who got out of the grounds are safe; anyone inside a pen stays inside
	for player, hs in heists do
		local char = player.Character
		local proot = char and char:FindFirstChild("HumanoidRootPart")
		if not proot then
			dropHeist(player)
			continue
		end
		-- faster than a carrier can run (with some slack for lag) means a teleport: drop the kid
		local t = now()
		local moved = Vector3.new(proot.Position.X - hs.lastPos.X, 0, proot.Position.Z - hs.lastPos.Z).Magnitude
		local allowed = H.carrySpeed * 1.8 * (t - hs.lastT) + 6
		if moved > allowed then
			dropHeist(player, "You dropped them!")
			continue
		end
		if t - hs.lastT >= 0.25 then hs.lastPos, hs.lastT = proot.Position, t end
		if not inLot(proot.Position) then
			escaped(player)
		end
	end
end

---------------------------------------------------------------------------
function FactoryService.start()
	root = workspace:FindFirstChild("VexFactory")
	if root then root:Destroy() end
	root = Instance.new("Model")
	root.Name = "VexFactory"
	local shell = Instance.new("Model")
	shell.Name = "Shell"
	shell.Parent = root
	buildShell(shell)
	local inside = Instance.new("Model")
	inside.Name = "Inside"
	inside.Parent = root
	buildInterior(inside)
	local pensModel = Instance.new("Model")
	pensModel.Name = "Pens"
	pensModel.Parent = root
	for i = 1, #PEN_XS do buildPen(pensModel, i) end
	guardsFolder = Instance.new("Folder")
	guardsFolder.Name = "Guards"
	guardsFolder.Parent = root
	root.Parent = workspace
	pcall(function() root.ModelStreamingMode = Enum.ModelStreamingMode.Atomic end)

	for i, pen in pens do
		pen.prompt.Triggered:Connect(function(player)
			takeKid(player, i)
		end)
	end
	for i = 1, H.guards do
		local g = makeGuard(ROUTES[(i - 1) % #ROUTES + 1])
		table.insert(guards, g)
		patrol(g)
	end
	table.insert(StealService.swingHooks, onSwing)
	RunService.Heartbeat:Connect(function(dt)
		local ok, err = pcall(tick, dt)
		if not ok then warn("[Factory]", err) end
	end)
	-- the pens follow the captured lists
	Signals.on("kidCaptured", function() task.defer(FactoryService.refresh) end)
	Signals.on("questStep", function(player, id)
		if id == "rescue" then FactoryService.tutorialCapture(player) end
	end)
	local function watch(player)
		local function onChar(char)
			if heists[player] then dropHeist(player) end
			local hum = char:WaitForChild("Humanoid", 10)
			if hum then
				hum.Died:Connect(function()
					if heists[player] then dropHeist(player, "You fainted! The kid went back in the pen.") end
				end)
			end
		end
		player.CharacterAdded:Connect(onChar)
		if player.Character then task.spawn(onChar, player.Character) end
	end
	Players.PlayerAdded:Connect(function(player)
		task.delay(6, FactoryService.refresh)
		watch(player)
	end)
	for _, player in Players:GetPlayers() do watch(player) end
	Players.PlayerRemoving:Connect(function(player)
		dropHeist(player)
		stunUntil[player] = nil
		for _, g in guards do
			if g.target == player then patrol(g) end
		end
		task.defer(FactoryService.refresh)
	end)
	task.spawn(function()
		while true do
			task.wait(10)
			pcall(FactoryService.refresh)
		end
	end)
	task.delay(3, FactoryService.refresh)
end

-- the tutorial: Skater Kid is waiting in a pen with your name on it
function FactoryService.tutorialCapture(player)
	local p = Data.get(player)
	if not p then return end
	p.captured = p.captured or {}
	for _, c in p.captured do
		if c.story == "rescue" then return end
	end
	table.insert(p.captured, 1, { id = "SkaterKid", grade = "Normal", story = "rescue" })
	FactoryService.refresh()
end

-- Studio
function FactoryService.debugState()
	local out = { pens = {}, guards = {}, heists = {} }
	for i, pen in pens do
		out.pens[i] = { kind = pen.kind, label = pen.label.Text, enabled = pen.prompt.Enabled, taken = pen.takenBy and pen.takenBy.Name or nil }
	end
	for _, g in guards do
		local r = g.model.PrimaryPart
		table.insert(out.guards, { state = g.state, target = g.target and g.target.Name or nil, pos = r and { math.floor(r.Position.X), math.floor(r.Position.Z) } })
	end
	for player, hs in heists do out.heists[player.Name] = hs.def.name end
	return out
end
function FactoryService.debugTake(player, i)
	takeKid(player, i)
	return heists[player] ~= nil
end

return FactoryService
