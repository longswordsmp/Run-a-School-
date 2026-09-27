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
local Stealth = require(script.Parent.Stealth)
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

-- a conveyor belt along X, from the HOMEWORK PRINTER at its head (-X) to the PACKER at its tail (+X),
-- with the Homework Press in the middle. Blank sheets come out of the printer's slot, ride the belt,
-- get a grade stamped on them under the press, and disappear into the packer's slot; the client slides
-- them along (Raid.client: BeltItem) and the loop back to the start happens inside the two machines,
-- where nobody can see it. (Before, the sheets popped out of thin air at one end of a bare belt.)
local SHEET_GAP = 4.3 -- studs between sheets; the run (BeltRun) is a whole number of gaps, so the press
local SHEET_RUN = 43 -- stamps every sheet as it passes, all the way round
local function machineBox(m, name, x0, x1, z, y0, h, body, trim)
	local cx, w = (x0 + x1) / 2, x1 - x0
	part(m, name, Vector3.new(w, h, 5.6), CFrame.new(cx, y0 + h / 2, z), body, Enum.Material.Metal)
	part(m, name .. "Trim", Vector3.new(w + 0.3, 0.4, 5.9), CFrame.new(cx, y0 + h + 0.2, z), trim, Enum.Material.Metal)
	part(m, name .. "Base", Vector3.new(w + 0.3, 0.5, 5.9), CFrame.new(cx, y0 + 0.25, z), DARK, Enum.Material.Metal)
	return cx, w
end
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
	-- the HOMEWORK PRINTER at the head: a purple box over the belt's end, a tray of blank paper feeding
	-- in on top, status lamps, and the slot the sheets come out of
	local px, pw = machineBox(m, "Printer", -24.2, -18, z, 1.1, 6.4, PURPLE, LILAC)
	part(m, "PrinterSlot", Vector3.new(0.2, 0.9, 3.4), CFrame.new(-17.95, y + 0.35, z), rgb(15, 12, 20), Enum.Material.SmoothPlastic)
	part(m, "PrinterLip", Vector3.new(0.6, 0.15, 3.8), CFrame.new(-17.7, y - 0.05, z), STEEL, Enum.Material.Metal)
	part(m, "PaperTray", Vector3.new(4.6, 0.3, 3.4), CFrame.new(px - 0.4, 8.1, z) * CFrame.Angles(0, 0, math.rad(-12)), STEEL, Enum.Material.Metal)
	for k = 0, 7 do
		part(m, "BlankPaper", Vector3.new(4.2, 0.1, 3), CFrame.new(px - 0.4, 8.3 + k * 0.11, z) * CFrame.Angles(0, 0, math.rad(-12)) * CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad((k % 3 - 1) * 2), 0), rgb(250, 250, 245), Enum.Material.SmoothPlastic)
	end
	for _, s in { -1, 1 } do
		local plate = part(m, "PrinterSign", Vector3.new(pw - 0.8, 1.6, 0.1), CFrame.new(px, 5.4, z + s * 2.85), rgb(28, 16, 40), Enum.Material.SmoothPlastic)
		sign(plate, s > 0 and Enum.NormalId.Back or Enum.NormalId.Front, "HOMEWORK PRINTER 3000", LILAC, Enum.Font.Arcade)
		for k, c in { rgb(80, 255, 120), rgb(255, 200, 60), rgb(255, 70, 70) } do
			part(m, "StatusLamp", Vector3.new(0.5, 0.5, 0.15), CFrame.new(px - 1.6 + k * 0.8, 3.4, z + s * 2.86), c, Enum.Material.Neon)
		end
	end
	-- the PACKER at the tail: it swallows the graded homework and boxes it up
	local kx, kw = machineBox(m, "Packer", 18, 24.2, z, 1.1, 5.2, DARK, rgb(245, 200, 40))
	part(m, "PackerSlot", Vector3.new(0.2, 0.9, 3.4), CFrame.new(17.95, y + 0.35, z), rgb(15, 12, 20), Enum.Material.SmoothPlastic)
	part(m, "PackerFlap", Vector3.new(0.12, 1.1, 3.4), CFrame.new(17.8, y + 0.55, z) * CFrame.Angles(0, 0, math.rad(-18)), rgb(40, 40, 46), Enum.Material.Rubber)
	for _, s in { -1, 1 } do
		local plate = part(m, "PackerSign", Vector3.new(kw - 0.8, 1.4, 0.1), CFrame.new(kx, 4.6, z + s * 2.85), rgb(245, 200, 40), Enum.Material.SmoothPlastic)
		sign(plate, s > 0 and Enum.NormalId.Back or Enum.NormalId.Front, "PACKING", rgb(30, 20, 20), Enum.Font.Arcade)
	end
	-- (a finished crate of homework sitting on top, waiting to go)
	local done = part(m, "PackedCrate", Vector3.new(3, 2.4, 3), CFrame.new(kx, 7.5, z), rgb(150, 110, 70), Enum.Material.WoodPlanks)
	sign(done, Enum.NormalId.Front, "HW", rgb(60, 30, 20), Enum.Font.Arcade)
	-- homework sheets riding the belt, printer to packer (the client slides them along). Blank until
	-- they pass under the press; then the grade shows (the client switches it on at x > 0).
	for i = 0, SHEET_RUN / SHEET_GAP - 1 do
		local sheet = part(m, "Homework", Vector3.new(1.4, 0.12, 1.9), CFrame.new(-SHEET_RUN / 2 + i * SHEET_GAP, y + 0.15, z) * CFrame.Angles(0, math.rad(math.random(-15, 15)), 0), rgb(228, 224, 210), Enum.Material.SmoothPlastic, { CanCollide = false })
		sheet:SetAttribute("BeltZ", z)
		sheet:SetAttribute("BeltLen", SHEET_RUN)
		sheet:SetAttribute("Offset", i * SHEET_GAP)
		CollectionService:AddTag(sheet, "BeltItem")
		local grade = sign(sheet, Enum.NormalId.Top, ({ "F", "D-", "SEE ME", "F", "C-" })[i % 5 + 1], rgb(210, 30, 30), Enum.Font.PermanentMarker)
		grade.Parent.Name = "Grade"
		grade.Parent.Enabled = false
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
	-- crates of homework either side of the way in: out of the side aisles (the way round the belts)
	-- and clear of the guards' beats, so they're somewhere to duck behind once you're through the door
	for _, spec in { { -18.5, 56.4 }, { -21.9, 56.4 }, { -18.5, 59.8 }, { 18.5, 56.4 }, { 21.9, 56.4 }, { 18.5, 59.8 } } do
		local c = part(m, "Crate", Vector3.new(3.4, 3.4, 3.4), CFrame.new(spec[1], 2.2, spec[2]), rgb(150, 110, 70), Enum.Material.WoodPlanks)
		sign(c, Enum.NormalId.Front, "HW", rgb(60, 30, 20), Enum.Font.Arcade)
	end
	for _, sx in { -1, 1 } do
		part(m, "Crate", Vector3.new(3.4, 3.4, 3.4), CFrame.new(sx * 19.6, 5.6, 57.4) * CFrame.Angles(0, math.rad(sx * 20), 0), rgb(150, 110, 70), Enum.Material.WoodPlanks)
	end
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

-- Vex's desk, in the aisle in front of the pens. A mission with an item (Config.Missions: "Vex's
-- Blueprints", Chapter 1's "Old Sewer Map") steals it off the desk; only a player on such a mission
-- sees the prompt (HUD's fixPrompt reads MissionOnly, a list of mission ids, and shows the item's
-- name). Everyone on the mission gets their own copy, so nobody waits on anyone.
local desk
local DESK_Z = 104
local BLUEPRINT = rgb(45, 110, 200)
local function buildDesk(m)
	local model = Instance.new("Model")
	model.Name = "VexDesk"
	model.Parent = m
	local z = DESK_Z
	local top = part(model, "DeskTop", Vector3.new(9, 0.5, 3.6), CFrame.new(0, 3.55, z), rgb(38, 30, 48), Enum.Material.SmoothPlastic)
	part(model, "DeskFront", Vector3.new(9, 3, 0.4), CFrame.new(0, 1.95, z - 1.6), PURPLE, Enum.Material.SmoothPlastic)
	for _, x in { -4.3, 4.3 } do
		part(model, "DeskSide", Vector3.new(0.4, 3, 3.6), CFrame.new(x, 1.95, z), PURPLE, Enum.Material.SmoothPlastic)
	end
	part(model, "DeskTrim", Vector3.new(9.05, 0.15, 0.1), CFrame.new(0, 3.25, z - 1.82), LILAC, Enum.Material.Neon)
	local logo = part(model, "DeskLogo", Vector3.new(2.2, 2.2, 0.1), CFrame.new(0, 1.9, z - 1.85), rgb(28, 16, 40), Enum.Material.SmoothPlastic)
	sign(logo, Enum.NormalId.Front, "V", LILAC, Enum.Font.LuckiestGuy, rgb(10, 5, 20))
	-- her chair: a tall purple throne of an office chair
	part(model, "ChairSeat", Vector3.new(2.6, 0.5, 2.4), CFrame.new(0, 2.2, z + 2.2), rgb(70, 35, 100), Enum.Material.Fabric)
	part(model, "ChairBack", Vector3.new(2.8, 4.2, 0.5), CFrame.new(0, 4.6, z + 3.1), rgb(70, 35, 100), Enum.Material.Fabric)
	part(model, "ChairTrim", Vector3.new(2.9, 0.2, 0.55), CFrame.new(0, 6.7, z + 3.1), LILAC, Enum.Material.Neon)
	cyl(model, "ChairPole", 0.35, 1.6, CFrame.new(0, 1.2, z + 2.2) * CFrame.Angles(0, 0, math.rad(90)), STEEL, Enum.Material.Metal)
	part(model, "ChairBase", Vector3.new(2.2, 0.3, 2.2), CFrame.new(0, 0.7, z + 2.2), DARK, Enum.Material.Metal)
	-- a nameplate, a lamp, a mug, homework piles
	local plate = part(model, "Nameplate", Vector3.new(2.6, 0.6, 0.3), CFrame.new(-2.6, 4.1, z - 1.2) * CFrame.Angles(math.rad(-20), 0, 0), rgb(20, 12, 30), Enum.Material.SmoothPlastic)
	sign(plate, Enum.NormalId.Front, "DR. V. VEX", LILAC, Enum.Font.FredokaOne)
	part(model, "LampBase", Vector3.new(0.9, 0.2, 0.9), CFrame.new(3.4, 3.9, z + 0.8), DARK, Enum.Material.Metal)
	cyl(model, "LampArm", 0.18, 1.8, CFrame.new(3.4, 4.8, z + 0.8) * CFrame.Angles(0, 0, math.rad(90)), DARK, Enum.Material.Metal)
	local shade = part(model, "LampShade", Vector3.new(1.2, 0.6, 1.2), CFrame.new(3.2, 5.7, z + 0.4) * CFrame.Angles(math.rad(-25), 0, 0), PURPLE, Enum.Material.Metal)
	local lampLight = light(shade, 10, 1.2, rgb(220, 190, 255))
	_ = lampLight
	cyl(model, "Mug", 0.6, 0.7, CFrame.new(-3.6, 4.15, z + 0.9) * CFrame.Angles(0, 0, math.rad(90)), rgb(240, 240, 245), Enum.Material.SmoothPlastic)
	for k, spec in { { -1.2, 0.8, 5 }, { -0.4, 1, 3 } } do
		for h = 1, spec[3] do
			part(model, "Homework", Vector3.new(1.1, 0.12, 1.4), CFrame.new(spec[1] - 1.4 * k, 3.8 + h * 0.13, z + spec[2]) * CFrame.Angles(0, math.rad(h * 7), 0), rgb(245, 245, 235), Enum.Material.SmoothPlastic)
		end
	end
	-- the plans: one spread out with a white grid, one rolled up
	local sheet = part(model, "PlansSheet", Vector3.new(3, 0.06, 2), CFrame.new(1, 3.83, z - 0.3) * CFrame.Angles(0, math.rad(-8), 0), BLUEPRINT, Enum.Material.SmoothPlastic)
	sign(sheet, Enum.NormalId.Top, "HOMEWORK\nMACHINE", rgb(235, 245, 255), Enum.Font.Arcade)
	local roll = cyl(model, "Blueprints", 0.6, 3, CFrame.new(1.2, 4.15, z + 1.1), BLUEPRINT, Enum.Material.SmoothPlastic)
	for _, dx in { -1.2, 1.2 } do
		cyl(model, "RollBand", 0.64, 0.12, CFrame.new(1.2 + dx, 4.15, z + 1.1), rgb(235, 245, 255), Enum.Material.SmoothPlastic)
	end
	local glow = Instance.new("Highlight")
	glow.Name = "PlansGlow"
	glow.FillTransparency = 1
	glow.OutlineColor = rgb(120, 200, 255)
	glow.Enabled = false
	glow.Parent = roll
	local hold = part(model, "PromptSpot", Vector3.new(1, 1, 1), CFrame.new(0, 3, z - 2.4), DARK, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PlansPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = "Vex's Blueprints"
	prompt.HoldDuration = H.holdTime
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 7
	local itemMissions = {}
	for id, def in Config.Missions do
		if def.item then table.insert(itemMissions, id) end
	end
	table.sort(itemMissions)
	prompt:SetAttribute("MissionOnly", table.concat(itemMissions, ","))
	prompt:SetAttribute("Color", rgb(120, 200, 255))
	prompt.Parent = hold
	desk = { model = model, prompt = prompt, kind = "item", mission = "vex_blueprints", roll = roll, glow = glow }
	_ = top
end

---------------------------------------------------------------------------
-- security round Vex's desk (not for the First Morning's rescue: lenient players pass untouched)
--   the office   glass walls round her desk (x -7..7, z 99..107.5), the door at the front
--   the lasers   three beams across the door that blink on and off together (Shared/HQLasers maths,
--                the same clock on both sides): wait for the gap, then walk through
--   the cameras  two on the side walls sweep the belt floor; being seen by one rings the alarm
-- Tripping a laser or being seen by a camera sends the nearest guards (H.alerted) after you.
---------------------------------------------------------------------------
local HQLasers = require(ReplicatedStorage.Shared.HQLasers)
-- (the back wall stops 4.5 studs short of the pens, so the corridor behind it is wide enough to walk,
-- carry a kid through, and for a guard to find his way along)
local OFFICE = { x0 = -7, x1 = 7, z0 = 99, z1 = 107.5, door = 2.6 }
local lasers = {} -- { part, base }
local cameras = {} -- { head, cone, pos, yaw0, sweep, t }
local CAM_RANGE, CAM_HALF = 34, 17
local function buildOffice(m)
	local o = Instance.new("Model")
	o.Name = "VexOffice"
	o.Parent = m
	local GLASS = rgb(190, 170, 230)
	local h = 7.5
	local function wall(x0, z0, x1, z1)
		local along = math.abs(x1 - x0) > math.abs(z1 - z0)
		local len = along and math.abs(x1 - x0) or math.abs(z1 - z0)
		local mid = Vector3.new((x0 + x1) / 2, 0, (z0 + z1) / 2)
		part(o, "OfficeGlass", along and Vector3.new(len, h, 0.25) or Vector3.new(0.25, h, len), CFrame.new(mid + Vector3.new(0, 0.55 + h / 2, 0)), GLASS, Enum.Material.Glass, { Transparency = 0.55 })
		part(o, "OfficeSill", along and Vector3.new(len, 0.6, 0.5) or Vector3.new(0.5, 0.6, len), CFrame.new(mid + Vector3.new(0, 0.85, 0)), PURPLE, Enum.Material.Metal)
		part(o, "OfficeHead", along and Vector3.new(len, 0.4, 0.5) or Vector3.new(0.5, 0.4, len), CFrame.new(mid + Vector3.new(0, 0.55 + h, 0)), PURPLE, Enum.Material.Metal)
	end
	local o0, o1, z0, z1, dw = OFFICE.x0, OFFICE.x1, OFFICE.z0, OFFICE.z1, OFFICE.door
	wall(o0, z0, -dw, z0)
	wall(dw, z0, o1, z0)
	wall(o0, z0, o0, z1)
	wall(o1, z0, o1, z1)
	wall(o0, z1, o1, z1)
	for _, c in { { o0, z0 }, { o1, z0 }, { o0, z1 }, { o1, z1 }, { -dw, z0 }, { dw, z0 } } do
		part(o, "OfficePost", Vector3.new(0.6, h + 0.6, 0.6), CFrame.new(c[1], 0.55 + (h + 0.6) / 2, c[2]), PURPLE, Enum.Material.Metal)
	end
	-- the purple carpet inside, and a sign over the door
	part(o, "OfficeCarpet", Vector3.new(o1 - o0 - 0.6, 0.06, z1 - z0 - 0.6), CFrame.new(0, 0.58, (z0 + z1) / 2), rgb(70, 35, 100), Enum.Material.Fabric, { CanCollide = false })
	local board = part(o, "OfficeSign", Vector3.new(7, 1.4, 0.3), CFrame.new(0, 0.55 + h + 1.1, z0 - 0.1), rgb(28, 16, 40), Enum.Material.SmoothPlastic)
	sign(board, Enum.NormalId.Front, "OFFICE OF DR. V. VEX", LILAC, Enum.Font.LuckiestGuy)
	part(o, "SignNeon", Vector3.new(7.3, 0.2, 0.2), CFrame.new(0, 0.55 + h + 0.35, z0 - 0.3), LILAC, Enum.Material.Neon)
	-- the laser gate: emitter posts either side of the door and three beams across it
	for _, s in { -1, 1 } do
		part(o, "LaserPost", Vector3.new(0.5, 5.2, 0.5), CFrame.new(s * (dw - 0.1), 3.15, z0 - 0.3), DARK, Enum.Material.Metal)
		for _, y in { 1.2, 2.7, 4.2 } do
			part(o, "Emitter", Vector3.new(0.3, 0.3, 0.3), CFrame.new(s * (dw - 0.35), y, z0 - 0.3), rgb(255, 60, 60), Enum.Material.Neon)
		end
	end
	local lf = Instance.new("Folder")
	lf.Name = "Lasers"
	lf.Parent = o
	for i, y in { 1.2, 2.7, 4.2 } do
		local beam = part(lf, "Laser", Vector3.new(dw * 2 - 0.7, 0.14, 0.14), CFrame.new(0, y, z0 - 0.3), rgb(255, 40, 40), Enum.Material.Neon, { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
		beam:SetAttribute("Laser", "blink")
		beam:SetAttribute("Period", 4.6)
		beam:SetAttribute("On", 0.62)
		beam:SetAttribute("Phase", (i - 1) * 0.12)
		table.insert(lasers, { part = beam, base = beam.CFrame })
	end
	-- cover either side of the office front: crates two high and two deep, so from the cameras' corners
	-- the whole gap between them and the office wall is in shadow (tested: a sneaking player at
	-- x -9, z 100..104 can't be seen by either camera or the office guard)
	for _, sx in { -1, 1 } do
		for _, cz in { 100.3, 103.7 } do
			for k = 0, 1 do
				local c = part(o, "CoverCrate", Vector3.new(3.4, 3.4, 3.4), CFrame.new(sx * 12, 2.2 + k * 3.4, cz) * CFrame.Angles(0, math.rad(k * 6 * sx), 0), rgb(150, 110, 70), Enum.Material.WoodPlanks)
				sign(c, sx < 0 and Enum.NormalId.Left or Enum.NormalId.Right, "HW", rgb(60, 30, 20), Enum.Font.Arcade)
			end
		end
	end
	local warnPlate = part(o, "LaserWarning", Vector3.new(2.4, 1, 0.1), CFrame.new(-dw - 1.6, 5.6, z0 - 0.2), rgb(255, 205, 40), Enum.Material.SmoothPlastic)
	sign(warnPlate, Enum.NormalId.Front, "\u{26A0} LASERS", rgb(30, 20, 20), Enum.Font.GothamBlack)
end

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
	local cone = part(cam, "Cone", Vector3.new(0.2, 1, 1), CFrame.new(), rgb(255, 250, 200), Enum.Material.Neon, { Transparency = 0.82, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	table.insert(cameras, { head = head, cone = cone, pos = pos, yaw0 = yaw0, sweep = sweep, t = 0 })
end
-- (an 8.4 s sweep: well off the office guard's 12 s beat, so a gap in one keeps coming round to a gap
-- in the other instead of the two staying in step for minutes)
local function cameraYaw(c) return c.yaw0 + math.sin(c.t * 0.75) * c.sweep end
local function updateCamera(c, dt)
	c.t += dt
	local look = CFrame.Angles(0, math.rad(cameraYaw(c)), 0).LookVector
	c.head.CFrame = CFrame.lookAt(c.pos, c.pos + look * 10 + Vector3.new(0, -6, 0))
	local len = CAM_RANGE * 0.8
	local mid = Vector3.new(c.pos.X, 0.62, c.pos.Z) + look * (len / 2 + 2)
	c.cone.Size = Vector3.new(2 * math.tan(math.rad(CAM_HALF)) * len, 0.05, len)
	c.cone.CFrame = CFrame.lookAt(mid, mid + look)
	c.cone.Color = root and root:GetAttribute("Alarm") and rgb(255, 60, 60) or rgb(255, 250, 200)
end
local function cameraSees(c, char)
	local proot = char and char:FindFirstChild("HumanoidRootPart")
	if not proot then return false end
	local who = Players:GetPlayerFromCharacter(char)
	if who and (who:GetAttribute("SmokeUntil") or 0) > workspace:GetServerTimeNow() then return false end
	if who and who:GetAttribute("Boxed") then
		local v = proot.AssemblyLinearVelocity
		if Vector3.new(v.X, 0, v.Z).Magnitude < 1.5 then return false end
	end
	local d = proot.Position - c.pos
	local flat = Vector3.new(d.X, 0, d.Z)
	-- (it looks out and down across the floor: the floor right under its wall mount is out of view,
	-- or the side aisle beneath it would catch people at random)
	if flat.Magnitude > CAM_RANGE or flat.Magnitude < 7 then return false end
	local look = CFrame.Angles(0, math.rad(cameraYaw(c)), 0).LookVector
	if flat.Unit:Dot(look) < math.cos(math.rad(CAM_HALF)) then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char, c.head.Parent, guardsFolder }
	return workspace:Raycast(c.pos, proot.Position - c.pos, params) == nil
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
		-- (an avatar kid's clothes and textures would show through the dark)
		if d:IsA("MeshPart") then d.TextureID = "" end
		if d:IsA("Clothing") or d:IsA("ShirtGraphic") or d:IsA("SurfaceAppearance") then d:Destroy() end
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
					local story = q.entry.story and Config.Missions[q.entry.story]
					pen.label.Text = story and ("\u{2605} " .. def.name:upper() .. " \u{2605}") or (q.player.DisplayName .. "'s " .. def.name):upper()
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
-- The heist in layers, one guard each: the door guard (slip in behind him), the belt guard (a U round
-- the east side of the first belt: the west aisle is the sneaky way up, and between the belts there is
-- a spot nobody can see), the office guard pacing the east half of the office front (wait behind the
-- west crates, out of his sight), then the cameras, the lasers and his back (time the dash through
-- the door). The fourth
-- walks the pens behind the office. A guard sweeps his eyes round as he turns at the end of his beat,
-- so every end is at least 13 studs from anywhere you'd wait.
local ROUTES = {
	{ Vector3.new(-14, 0, 63), Vector3.new(26, 0, 63), Vector3.new(26, 0, 79), Vector3.new(-14, 0, 79), Vector3.new(26, 0, 79), Vector3.new(26, 0, 63) },
	{ Vector3.new(3, 0, 96), Vector3.new(21, 0, 96) },
	{ Vector3.new(-26, 0, 110.6), Vector3.new(26, 0, 110.6) },
	-- (the door guard: his beat stops short of the side aisles, so a sneaking player can slip round
	-- the corner while his back is turned)
	{ Vector3.new(-12, 0, 53), Vector3.new(12, 0, 53) },
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

-- (one clip at a time, paced to his speed: the same helper the other squads use)
local anim = require(script.Parent.Guards).anim

-- a walking route round the belts, crates and Vex's glass office (guards used to cut straight through
-- them): nil when there's no path, or the waypoints after the start
local PathfindingService = game:GetService("PathfindingService")
local function pathPoints(from, to)
	local path = PathfindingService:CreatePath({ AgentRadius = 1.6, AgentHeight = 5.5, AgentCanJump = false, WaypointSpacing = 3 })
	local ok = pcall(function()
		path:ComputeAsync(Vector3.new(from.X, 3, from.Z), Vector3.new(to.X, 3, to.Z))
	end)
	if not ok or path.Status ~= Enum.PathStatus.Success then return nil end
	local out = {}
	for i, w in path:GetWaypoints() do
		if i > 1 then table.insert(out, w.Position) end
	end
	return out
end
-- a chasing guard's route to his target, refreshed in the background (at most twice a second, or when
-- the target has moved on)
local function repath(g, goal)
	if g.pathBusy then return end
	g.pathBusy = true
	task.spawn(function()
		local root = g.model.PrimaryPart
		g.path = root and pathPoints(root.Position, goal) or nil
		-- (no way to the exact spot, e.g. you're pressed against a belt: aim a step short of you)
		if root and not g.path then
			local back = Vector3.new(root.Position.X - goal.X, 0, root.Position.Z - goal.Z)
			if back.Magnitude > 3 then g.path = pathPoints(root.Position, goal + back.Unit * 2.5) end
		end
		if RunService:IsStudio() then
			g.model:SetAttribute(g.path and "PathOK" or "PathFail", (g.model:GetAttribute(g.path and "PathOK" or "PathFail") or 0) + 1)
		end
		g.pathAt = now()
		g.pathGoal = goal
		g.pathBusy = false
	end)
end

local function patrol(g)
	g.state = "patrol"
	g.target = nil
	g.slow = nil
	guardTag(g, "")
	anim(g, "walk", H.patrolSpeed)
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
	-- (back to his beat round the obstacles, not through them)
	local token = {}
	g.patrolToken = token
	task.spawn(function()
		local pts = pathPoints(root.Position, g.route[best])
		if g.patrolToken ~= token or g.state ~= "patrol" or not g.model.Parent then return end
		local legs = {}
		for _, p in pts or {} do table.insert(legs, Vector3.new(p.X, g.route[best].Y, p.Z)) end
		if #legs == 0 then legs = { g.route[best] } else legs[#legs] = g.route[best] end
		Walkers.walk(g.model, legs, H.patrolSpeed, nextLeg, { flat = true })
	end)
end

-- a guard who spots you (or hears the alarm) shows a "!" and takes a moment before he runs
local function chase(g, player, reaction)
	if g.state == "chase" and g.target == player then return end
	Walkers.stop(g.model)
	g.state = "chase"
	g.target = player
	g.slow = nil
	g.seenAt = now()
	g.grabAt = nil
	g.reactUntil = now() + (reaction or H.reaction)
	guardTag(g, "!", rgb(255, 70, 70))
	anim(g, "idle")
end

-- (the one rule every guard uses: sneaking, sprinting, the Cardboard Box, smoke; see Stealth)
local SIGHT = { sight = H.sightRange, angle = H.sightAngle, hear = H.hearRange }
local function canSee(g, char)
	return Stealth.canSee(g.model.PrimaryPart, char, SIGHT, { guardsFolder, g.model })
end

-- a noise (a Whoopee Cushion): the guard jogs over, looks around, and goes back to his rounds
local function investigate(g, pos)
	g.state = "investigate"
	g.target = nil
	guardTag(g, "?", rgb(255, 230, 90))
	anim(g, "run", 11)
	local to = Vector3.new(math.clamp(pos.X, B.x0 + 2, B.x1 - 2), 0.55 + g.so, math.clamp(pos.Z, B.z0 + 2, B.z1 - 2))
	Walkers.walk(g.model, { to }, 11, function()
		if g.state ~= "investigate" then return end
		anim(g, "idle")
		guardTag(g, "Huh?", rgb(255, 230, 90))
		task.delay(3.5, function()
			if g.state == "investigate" then patrol(g) end
		end)
	end, { flat = true })
end

---------------------------------------------------------------------------
-- the heist
---------------------------------------------------------------------------
-- (StealService.setSpeed knows the Factory carry speed from the Heist attribute, and adds sprint/sneak)
local function setCarrySpeed(player, on)
	_ = on
	StealService.setSpeed(player)
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
	-- (the desk's prompt is switched per player on the client)
	if pen.kind ~= "item" then pen.prompt.Enabled = pen.kind ~= nil end
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
	-- (caught empty-handed too: say so, or you'd just find yourself outside with no idea why)
	local why = "Security caught you and threw you out!"
	if heists[player] then dropHeist(player, why) else Remotes.Notify:FireClient(player, "\u{1F6A8} " .. why, "bad") end
	Signals.fire("factoryCaught", player)
	char:PivotTo(CFrame.lookAt(Vector3.new(math.random(-5, 5), 3.5, LOT.z0 - 6), Vector3.new(0, 3.5, 0)))
	stunUntil[player] = now() + H.caughtStun
	player:SetAttribute("Stunned", true)
	StealService.setSpeed(player)
	task.delay(H.caughtStun, function()
		if not player.Parent then return end
		player:SetAttribute("Stunned", nil)
		StealService.setSpeed(player)
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
		local story = pen.entry and pen.entry.story
		if story and Config.Missions[story] then task.defer(Signals.fire, "storyRescued", player, story) end
		for i, c in p.captured or {} do
			if c == pen.entry then table.remove(p.captured, i) break end
		end
		pen.kind, pen.owner, pen.entry = nil, nil, nil
		clearPenKid(pen)
		pen.label.Text = ""
		pen.model:SetAttribute("OwnerId", nil)
		local benchKid = LetterService.deliver(player, hs.def, true, hs.grade)
		if not benchKid then
			-- the bench is full of gifts: they'll be there next time (as they were)
			p.pendingBench = p.pendingBench or {}
			table.insert(p.pendingBench, { id = hs.def.id, grade = hs.grade })
		elseif story == "rescue" then
			-- the First Morning's Skater Kid doesn't wait on the bench: he heads straight for a desk
			-- (a free kid makes room in a full school: HallService.enroll)
			task.delay(1, function()
				if benchKid.Parent and benchKid:GetAttribute("State") == "Hall" then
					require(script.Parent.HallService).enroll(player, benchKid)
				end
			end)
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
	elseif pen.kind == "item" then
		Remotes.Push:FireClient(player, "heist", { state = "item", name = hs.itemName or "Vex's Blueprints" })
		task.defer(Signals.fire, "storyRescued", player, hs.mission or pen.mission)
	end
	if not anyHeist() then alarm(false) end
	FactoryService.refresh()
	-- guards give up
	for _, g in guards do
		if g.target == player then patrol(g) end
	end
end

-- the alarm: the nearest guards (Config.Heist.alerted) come running; the others keep to their rounds
-- and join in if they spot you
local function alertNearest(player, proot, count)
	local list = {}
	for _, g in guards do
		local r = g.model.PrimaryPart
		if r and now() >= g.stunUntil then table.insert(list, { g = g, d = (r.Position - proot.Position).Magnitude }) end
	end
	table.sort(list, function(a, b) return a.d < b.d end)
	for i = 1, math.min(count or H.alerted or #list, #list) do chase(list[i].g, player) end
end

local function takeKid(player, i)
	local pen = pens[i]
	if not pen or not pen.kind or pen.takenBy or heists[player] then return end
	if pen.kind == "captured" and pen.owner ~= Data.hostOf(player) then return end
	if player:GetAttribute("Carrying") then return end
	local char = player.Character
	local proot = char and char:FindFirstChild("HumanoidRootPart")
	if not proot or (stunUntil[player] or 0) > now() then return end
	-- (at the bars: the prompt's range, checked here too rather than trusted)
	local spot = pen.model:FindFirstChild("PromptSpot")
	if spot and (spot.Position - proot.Position).Magnitude > 12 then return end
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
	Factory.carryOverhead(char, kid)
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
		alertNearest(player, proot)
	end
end

local function takePlans(player)
	local mid = player:GetAttribute("Mission")
	local mdef = mid and Config.Missions[mid]
	if heists[player] or player:GetAttribute("Carrying") or not (mdef and mdef.item) then return end
	local itemName = mdef.itemName or "Vex's Blueprints"
	-- (the old sewer map is parchment; the plans are blueprint blue)
	local rollColor = mdef.item == "SewerMap" and rgb(222, 196, 140) or BLUEPRINT
	local char = player.Character
	local proot = char and char:FindFirstChild("HumanoidRootPart")
	if not proot or (stunUntil[player] or 0) > now() then return end
	if (desk.prompt.Parent.Position - proot.Position).Magnitude > 12 then return end
	-- a rolled copy rides over your head
	local roll = Instance.new("Part")
	roll.Name = "CarriedPlans"
	roll.Shape = Enum.PartType.Cylinder
	roll.Size = Vector3.new(3.4, 0.8, 0.8)
	roll.Color = rollColor
	roll.Material = Enum.Material.SmoothPlastic
	roll.Massless = true
	roll.CanCollide = false
	roll.CanQuery = false
	roll.CanTouch = false
	for _, dx in { -1.3, 1.3 } do
		local band = roll:Clone()
		band.Name = "Band"
		band.Size = Vector3.new(0.15, 0.85, 0.85)
		band.Color = rgb(235, 245, 255)
		band.CFrame = CFrame.new(dx, 0, 0)
		band.Parent = roll
		local bw = Instance.new("Weld")
		bw.Part0, bw.Part1 = roll, band
		bw.C0 = CFrame.new(dx, 0, 0)
		bw.Parent = band
	end
	local off = 3.6
	roll.CFrame = proot.CFrame * CFrame.new(0, off, 0)
	local w = Instance.new("Weld")
	w.Part0, w.Part1 = proot, roll
	w.C0 = CFrame.new(0, off, 0)
	w.Parent = roll
	local glow = Instance.new("Highlight")
	glow.FillTransparency = 1
	glow.OutlineColor = rgb(120, 200, 255)
	glow.Parent = roll
	roll.Parent = char
	heists[player] = { pen = desk, kid = roll, item = true, mission = mid, itemName = itemName, lastPos = proot.Position, lastT = now() }
	player:SetAttribute("Heist", itemName)
	setCarrySpeed(player, true)
	alarm(true)
	Remotes.Push:FireClient(player, "heist", { state = "carrying", name = itemName })
	alertNearest(player, proot, H.alertedDesk)
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
			-- (forgiving: he's running at you, and the server sees you a moment late; one charging at
			-- you is caught a little further out)
			local reach = g.state == "chase" and 10.5 or 9
			if flat.Magnitude < reach and (flat.Magnitude < 5.5 or flat.Unit:Dot(look) > 0.1) then
				g.stunUntil = now() + H.guardStun
				g.grabAt = nil
				Walkers.stop(g.model)
				g.state = "stunned"
				guardTag(g, "@#!", rgb(255, 230, 90))
				anim(g, "fall")
				Remotes.Sfx:FireClient(player, "Bonk")
				Remotes.Push:FireClient(player, "hit", { pos = root.Position + Vector3.new(0, 2, 0) })
				-- knocked back along the swing, a little hop (short of any wall, belt or crate behind him)
				local start = root.CFrame
				local dir = flat.Magnitude > 1e-3 and flat.Unit or look
				local push = 7
				do
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Exclude
					params.FilterDescendantsInstances = { guardsFolder, proot.Parent }
					local hit = workspace:Raycast(root.Position, dir * 8.6, params)
					if hit then push = math.max(0, hit.Distance - 1.6) end
				end
				local t0 = now()
				local conn
				conn = RunService.Heartbeat:Connect(function()
					local a = math.min(1, (now() - t0) / 0.35)
					if not root.Parent then conn:Disconnect() return end
					local pos = start.Position + dir * push * a + Vector3.new(0, math.sin(a * math.pi) * 2.2, 0)
					if not inBuilding(pos) then pos = Vector3.new(math.clamp(pos.X, B.x0 + 2, B.x1 - 2), pos.Y, math.clamp(pos.Z, B.z0 + 2, B.z1 - 2)) end
					root.CFrame = CFrame.new(pos) * (start - start.Position)
					if a >= 1 then
						conn:Disconnect()
						-- landed: dazed, not flailing on the floor for the rest of the stun
						if g.state == "stunned" then anim(g, "idle") end
					end
				end)
				return
			end
		end
	end
end

---------------------------------------------------------------------------
-- the loop: guards look, chase, catch; carriers escape
---------------------------------------------------------------------------
local factorySpotted = {}
local tripped = {} -- [player] = os.clock() of the last laser / camera alarm (one every few seconds)
local function securityAlarm(player, proot, why)
	if tripped[player] and now() - tripped[player] < 4 then return end
	tripped[player] = now()
	for _, g in guards do
		if g.state == "chase" and g.target == player then return end
	end
	alarm(true)
	task.delay(4, function() if not anyHeist() then alarm(false) end end)
	Remotes.Sfx:FireClient(player, "Bell")
	Remotes.Notify:FireClient(player, "\u{1F6A8} " .. why .. " Security's coming!", "bad")
	alertNearest(player, proot)
end
local function tick(dt)
	-- the cameras turn; the lasers and cameras catch anyone in the building (not a First Morning rescue)
	for _, c in cameras do updateCamera(c, dt) end
	local t = workspace:GetServerTimeNow()
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local proot = char and char:FindFirstChild("HumanoidRootPart")
		if proot and inBuilding(proot.Position) and not lenient(player) and (stunUntil[player] or 0) <= now() then
			local pos = proot.Position
			local feet = pos.Y - 3
			for _, l in lasers do
				if HQLasers.hits(l.part, l.base, t, pos, feet, feet + 5, 0.9) then
					securityAlarm(player, proot, "You tripped Vex's laser!")
					break
				end
			end
			for i, c in cameras do
				if cameraSees(c, char) then
					-- (Studio: which camera, where it was pointing and where you were, for tests)
					if RunService:IsStudio() then
						player:SetAttribute("DbgCamera", ("cam %d of %d yaw %.0f saw you at %.1f, %.1f"):format(i, #cameras, cameraYaw(c), pos.X, pos.Z))
					end
					securityAlarm(player, proot, "A camera saw you!")
					break
				end
			end
		end
	end
	-- who's being chased (the client shows SPOTTED / HIDDEN)
	local chased = {}
	for _, g in guards do
		if g.state == "chase" and g.target then chased[g.target] = true end
	end
	-- (only for players on the Factory grounds: the Lab and Vex Prep set it for theirs)
	for _, player in Players:GetPlayers() do
		local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local here = r and inLot(r.Position)
		if here or factorySpotted[player] then
			local want = here and chased[player] or nil
			if want ~= factorySpotted[player] then
				factorySpotted[player] = want
				player:SetAttribute("Spotted", want)
			end
		end
	end
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
		if g.state == "patrol" or g.state == "investigate" then
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
				if flat.Magnitude > 1e-3 then
					local lv = root.CFrame.LookVector
					local face = Walkers.turn(Vector3.new(lv.X, 0, lv.Z).Unit, flat.Unit, 12 * dt)
					root.CFrame = CFrame.lookAt(root.Position, root.Position + face)
				end
				continue
			end
			g.reactUntil = nil
			-- (a hand on your collar: close, and nothing between you, not through the office glass)
			local clear = true
			if flat.Magnitude < H.catchRange then
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { char, guardsFolder }
				local from = root.Position + Vector3.new(0, 1, 0)
				clear = workspace:Raycast(from, (proot.Position + Vector3.new(0, 1, 0)) - from, params) == nil
			end
			-- (he has to hold on for a moment: close for 0.3 s before he's got you, so there's time to
			-- bonk him or pull away, and a catch is never down to lag)
			if flat.Magnitude < H.catchRange and clear then
				g.grabAt = g.grabAt or now()
			else
				g.grabAt = nil
			end
			if g.grabAt and now() - g.grabAt >= 0.3 then
				g.grabAt = nil
				thrownOut(player)
				patrol(g)
				continue
			end
			local speed = carrying and (g.slow and H.tutorialChase or H.chaseSpeedCarry) or H.chaseSpeed
			-- aim at the nearest point to them inside the building: he runs where he faces, and when
			-- they're outside and he's pinned against the wall he stands and glares (no crab-walk,
			-- no running on the spot)
			local y = 0.55 + g.so
			local pos = root.Position
			local goal = Vector3.new(math.clamp(proot.Position.X, B.x0 + 2, B.x1 - 2), y, math.clamp(proot.Position.Z, B.z0 + 2, B.z1 - 2))
			local to = Vector3.new(goal.X - pos.X, 0, goal.Z - pos.Z)
			-- round the belts and the office, not through them: follow the path's next waypoint
			if not g.pathAt or now() - g.pathAt > 0.5 or (g.pathGoal and (g.pathGoal - goal).Magnitude > 4) then repath(g, goal) end
			if g.path and to.Magnitude > 2 then
				while g.path[1] and Vector3.new(g.path[1].X - pos.X, 0, g.path[1].Z - pos.Z).Magnitude < 1.4 do
					table.remove(g.path, 1)
				end
				local w = g.path[1]
				if w then to = Vector3.new(w.X - pos.X, 0, w.Z - pos.Z) end
			elseif to.Magnitude > 2 then
				-- no route yet: only step straight at them if nothing's in the way (knee high, so belts
				-- count); otherwise face them and wait for the next route
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { guardsFolder, char }
				if workspace:Raycast(Vector3.new(pos.X, 1.5, pos.Z), to.Unit * math.min(to.Magnitude, 3), params) then
					anim(g, "idle")
					local lv = root.CFrame.LookVector
					local face = Walkers.turn(Vector3.new(lv.X, 0, lv.Z).Unit, flat.Unit, 9 * dt)
					root.CFrame = CFrame.lookAt(pos, pos + face)
					continue
				end
			end
			if to.Magnitude < (g.anim == "idle" and 1.5 or 0.5) then
				anim(g, "idle")
				local lv = root.CFrame.LookVector
				local face = Walkers.turn(Vector3.new(lv.X, 0, lv.Z).Unit, flat.Unit, 9 * dt)
				root.CFrame = CFrame.lookAt(pos, pos + face)
				continue
			end
			anim(g, "run", speed)
			local lv = root.CFrame.LookVector
			local face = Walkers.turn(Vector3.new(lv.X, 0, lv.Z).Unit, to.Unit, 9 * dt)
			local step = math.min(to.Magnitude, speed * dt)
			local np = Vector3.new(math.clamp(pos.X + face.X * step, B.x0 + 2, B.x1 - 2), y, math.clamp(pos.Z + face.Z * step, B.z0 + 2, B.z1 - 2))
			root.CFrame = CFrame.lookAt(np, np + face)
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
	buildDesk(inside)
	buildOffice(inside)
	local camsModel = Instance.new("Model")
	camsModel.Name = "Cameras"
	camsModel.Parent = inside
	-- (high on the side walls, sweeping the floor between the belts and the office)
	-- (aimed at the floor in front of Vex's office, not the way in; they sweep in step, so both turn
	-- away from the office door at the same moment: watch the cones on the floor, then go)
	buildCamera(camsModel, Vector3.new(B.x0 + 2.4, 14, 82), -110, 30)
	buildCamera(camsModel, Vector3.new(B.x1 - 2.4, 14, 82), 110, -30)
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
	desk.prompt.Triggered:Connect(takePlans)
	for i = 1, H.guards do
		local g = makeGuard(ROUTES[(i - 1) % #ROUTES + 1])
		table.insert(guards, g)
		patrol(g)
	end
	table.insert(StealService.swingHooks, onSwing)
	-- Heist Gear: a smoke bomb blinds the guards around it (they cough) and every guard after that
	-- player loses them; a whoopee cushion in the Factory brings the patrols running
	local GearService = require(script.Parent.GearService)
	table.insert(GearService.smokeHooks, function(player, pos)
		for _, g in guards do
			local r = g.model.PrimaryPart
			if r and (r.Position - pos).Magnitude < 18 then
				Walkers.stop(g.model)
				g.target = nil
				g.state = "stunned"
				g.stunUntil = now() + 3
				guardTag(g, "*cough cough*", rgb(220, 220, 230))
				Factory.play(g.model, "idle")
			elseif g.target == player then
				patrol(g)
			end
		end
	end)
	table.insert(GearService.noiseHooks, function(pos)
		if not inLot(pos) then return end
		for _, g in guards do
			local r = g.model.PrimaryPart
			if r and (g.state == "patrol" or g.state == "investigate") and (r.Position - pos).Magnitude < 45 then
				investigate(g, pos)
			end
		end
	end)
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

-- a mission's kid (MissionService), waiting in a pen with a star on it
function FactoryService.storyCapture(player, missionId, kidId)
	local p = Data.get(player)
	if not p or not Config.StudentById[kidId] then return end
	p.captured = p.captured or {}
	for _, c in p.captured do
		if c.story == missionId then
			FactoryService.refresh()
			return
		end
	end
	table.insert(p.captured, 1, { id = kidId, grade = "Normal", story = missionId })
	FactoryService.refresh()
end

-- the blueprints glow on the desk while anyone is on that mission
function FactoryService.storyItem(player, missionId)
	local def = Config.Missions[missionId]
	if desk and def and def.item then desk.glow.Enabled = true end
end
function FactoryService.storyItemDone()
	if not desk then return end
	for _, pl in Players:GetPlayers() do
		local mid = pl:GetAttribute("Mission")
		if mid and Config.Missions[mid] and Config.Missions[mid].item then return end
	end
	desk.glow.Enabled = false
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
-- Studio: every guard stands dazed for a while (to test a carry path without being caught)
function FactoryService.debugCalm(secs)
	for _, g in guards do
		g.stunUntil = now() + (secs or 30)
		Walkers.stop(g.model)
		g.state = "stunned"
		g.target = nil
	end
	return #guards
end
function FactoryService.debugTakePlans(player)
	takePlans(player)
	return heists[player] ~= nil
end
function FactoryService.debugTake(player, i)
	takeKid(player, i)
	return heists[player] ~= nil
end

return FactoryService
