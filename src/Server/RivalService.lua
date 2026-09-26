-- ServerScriptService.Server.RivalService
-- Vex Prep Academy: VexCorp's own school, at the far east end of Recess Row (south side). Its
-- students sit at eight desks in the Great Hall; steal one (hold E at their desk) and get off the
-- grounds with them over your head, and they walk to your Waiting Bench. Three hall monitors patrol
-- (Guards: the same eyes and ears as every guard); grabbing a kid rings the bell and brings them
-- running. Keep going at it:
--   Rivalry   every kid you steal from Vex Prep raises your Rivalry (saved); the higher it is, the
--             rarer their kids come out for you (and more of them are Gifted or better)
--   revenge   Vex Prep doesn't take it lying down: after you steal, their goons raid you sooner
-- Also here: the last two VexCorp Files (the brochure on the lawn, Veronica's diary in the office).
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

local RivalService = {}

local rgb = Color3.fromRGB
local function now() return os.clock() end

local LOT = { x0 = 372, x1 = 482, z0 = -170, z1 = -45 }
local B = { x0 = 382, x1 = 472, z0 = -160, z1 = -95, h = 26 } -- the building (front wall at z1)
local CX = 427
local FLOOR = 0.9
RivalService.LOT = LOT

local STONE = rgb(170, 164, 156)
local STONE_DARK = rgb(120, 114, 110)
local SLATE = rgb(58, 56, 72)
local PURPLE = rgb(92, 40, 132)
local GOLD = rgb(220, 180, 80)
local WOOD = rgb(110, 72, 44)

local root
local guards
local desks = {} -- { model, x, z, kid, def, grade, prompt, emptyUntil }
local carrying = {} -- [player] = { desk, kid, def, grade, lastPos, lastT }
local stunUntil = {}
local lastSpotted = {}
local seen = {} -- [player] = true once the first-look cutscene was checked this session

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
	g.LightInfluence = 0.2
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -12, 1, -12)
	t.Position = UDim2.fromOffset(6, 6)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = font or Enum.Font.Fantasy
	t.Text = text
	t.TextColor3 = color
	t.Parent = g
	if stroke then
		local s = Instance.new("UIStroke")
		s.Color = stroke
		s.Thickness = 2
		s.Parent = t
	end
	return t
end
local function inBox(pos, b) return pos.X > b.x0 and pos.X < b.x1 and pos.Z > b.z0 and pos.Z < b.z1 end
local function inLot(pos) return inBox(pos, LOT) end
local function guardArea(pos)
	return pos.X > B.x0 + 2 and pos.X < B.x1 - 2 and pos.Z > B.z0 + 2 and pos.Z < B.z1 - 2
end

---------------------------------------------------------------------------
-- the campus
---------------------------------------------------------------------------
local function buildGrounds(m)
	-- a clipped lawn, a gravel path, hedges, iron railings, a gate with stone pillars and an arch
	part(m, "Lawn", Vector3.new(LOT.x1 - LOT.x0, 0.3, LOT.z1 - LOT.z0), CFrame.new((LOT.x0 + LOT.x1) / 2, 0.45, (LOT.z0 + LOT.z1) / 2), rgb(70, 140, 70), Enum.Material.Grass)
	part(m, "Path", Vector3.new(10, 0.34, LOT.z1 - B.z1), CFrame.new(CX, 0.62, (B.z1 + LOT.z1) / 2), rgb(200, 190, 170), Enum.Material.Pebble)
	part(m, "Drive", Vector3.new(14, 0.3, 14), CFrame.new(CX, 0.5, LOT.z1 + 7), rgb(190, 180, 160), Enum.Material.Pebble)
	for _, x in { -7.5, 7.5 } do
		for z = LOT.z1 - 6, B.z1 + 6, -6 do
			part(m, "Hedge", Vector3.new(2.4, 2.6, 5.4), CFrame.new(CX + x, 1.9, z), rgb(40, 100, 50), Enum.Material.Grass)
		end
	end
	-- the fountain with a statue of Dr. Vex pointing at the sky (in grey stone)
	local fz = (B.z1 + LOT.z1) / 2
	for _, x in { -1, 1 } do
		local fx = CX + x * 24
		cyl(m, "FountainBasin", 12, 1.6, Vector3.new(fx, 1.4, fz), STONE, Enum.Material.Marble)
		cyl(m, "FountainWater", 11, 0.2, Vector3.new(fx, 2.2, fz), rgb(90, 150, 210), Enum.Material.Glass, { Transparency = 0.2 })
		cyl(m, "Plinth", 3, 4, Vector3.new(fx, 4, fz), STONE_DARK, Enum.Material.Marble)
		-- the statue: robe, head, bun, an arm raised with a pointer
		part(m, "StatueRobe", Vector3.new(2.2, 4, 1.6), CFrame.new(fx, 8, fz), STONE, Enum.Material.Marble)
		part(m, "StatueHead", Vector3.new(1.3, 1.4, 1.3), CFrame.new(fx, 10.7, fz), STONE, Enum.Material.Marble, { Shape = Enum.PartType.Ball })
		part(m, "StatueBun", Vector3.new(0.8, 0.8, 0.8), CFrame.new(fx, 11.6, fz + 0.3), STONE, Enum.Material.Marble, { Shape = Enum.PartType.Ball })
		part(m, "StatueArm", Vector3.new(0.5, 3, 0.5), CFrame.new(fx + x * 1.4, 10.8, fz) * CFrame.Angles(0, 0, math.rad(-x * 30)), STONE, Enum.Material.Marble)
	end
	-- iron railings on stone plinths, with spear-top posts
	local function railing(x0, z0, x1, z1)
		local along = x1 ~= x0
		local len = math.max(math.abs(x1 - x0), math.abs(z1 - z0))
		local mid = Vector3.new((x0 + x1) / 2, 0, (z0 + z1) / 2)
		part(m, "RailPlinth", along and Vector3.new(len, 1.4, 1) or Vector3.new(1, 1.4, len), CFrame.new(mid + Vector3.new(0, 1.2, 0)), STONE_DARK, Enum.Material.Brick)
		part(m, "RailTop", along and Vector3.new(len, 0.25, 0.25) or Vector3.new(0.25, 0.25, len), CFrame.new(mid + Vector3.new(0, 7, 0)), rgb(30, 30, 36), Enum.Material.Metal)
		part(m, "RailMid", along and Vector3.new(len, 0.2, 0.2) or Vector3.new(0.2, 0.2, len), CFrame.new(mid + Vector3.new(0, 3.2, 0)), rgb(30, 30, 36), Enum.Material.Metal)
		local n = math.floor(len / 1.6)
		for i = 0, n do
			local t = i / n
			local pos = Vector3.new(x0 + (x1 - x0) * t, 0, z0 + (z1 - z0) * t)
			part(m, "Bar", Vector3.new(0.16, 5.6, 0.16), CFrame.new(pos + Vector3.new(0, 4.6, 0)), rgb(30, 30, 36), Enum.Material.Metal, { CanCollide = false })
			if i % 5 == 0 then
				part(m, "Spear", Vector3.new(0.4, 0.8, 0.4), CFrame.new(pos + Vector3.new(0, 7.6, 0)) * CFrame.Angles(0, math.rad(45), 0), GOLD, Enum.Material.Metal)
			end
		end
		-- (the bars are for looks; one invisible wall keeps people out)
		part(m, "RailWall", along and Vector3.new(len, 8, 0.4) or Vector3.new(0.4, 8, len), CFrame.new(mid + Vector3.new(0, 4.4, 0)), rgb(0, 0, 0), nil, { Transparency = 1 })
	end
	railing(LOT.x0, LOT.z1, CX - 7, LOT.z1)
	railing(CX + 7, LOT.z1, LOT.x1, LOT.z1)
	railing(LOT.x0, LOT.z0, LOT.x0, LOT.z1)
	railing(LOT.x1, LOT.z0, LOT.x1, LOT.z1)
	railing(LOT.x0, LOT.z0, LOT.x1, LOT.z0)
	-- the gate: two stone pillars with lanterns and a wrought-iron arch with the school's name
	for _, x in { -7.8, 7.8 } do
		part(m, "GatePillar", Vector3.new(2.6, 12, 2.6), CFrame.new(CX + x, 6, LOT.z1), STONE, Enum.Material.Brick)
		part(m, "PillarCap", Vector3.new(3.2, 0.8, 3.2), CFrame.new(CX + x, 12.4, LOT.z1), STONE_DARK, Enum.Material.Marble)
		local lamp = part(m, "Lantern", Vector3.new(1.2, 1.8, 1.2), CFrame.new(CX + x, 13.7, LOT.z1), rgb(255, 220, 150), Enum.Material.Neon)
		local l = Instance.new("PointLight")
		l.Range = 18
		l.Brightness = 1.2
		l.Color = rgb(255, 210, 150)
		l.Parent = lamp
	end
	local arch = part(m, "GateArch", Vector3.new(10.6, 2.4, 0.5), CFrame.new(CX, 11.5, LOT.z1), rgb(30, 30, 36), Enum.Material.Metal)
	sign(arch, Enum.NormalId.Back, "VEX PREP ACADEMY", GOLD, Enum.Font.Fantasy)
	sign(arch, Enum.NormalId.Front, "VEX PREP ACADEMY", GOLD, Enum.Font.Fantasy)
	local motto = part(m, "Motto", Vector3.new(10.6, 1.2, 0.3), CFrame.new(CX, 9.6, LOT.z1), rgb(30, 30, 36), Enum.Material.Metal)
	sign(motto, Enum.NormalId.Back, "Excellence Through Homework", rgb(230, 220, 200), Enum.Font.Fantasy)
	-- iron ties from the sign to the pillars (the sign stays clear of them so the name reads whole)
	for _, x in { -5.9, 5.9 } do
		for _, y in { 12.5, 10.5, 9.2 } do
			part(m, "ArchTie", Vector3.new(1.3, 0.22, 0.22), CFrame.new(CX + x, y, LOT.z1), rgb(30, 30, 36), Enum.Material.Metal)
		end
	end
	sign(motto, Enum.NormalId.Front, "Excellence Through Homework", rgb(230, 220, 200), Enum.Font.Fantasy)
	-- a noticeboard on the lawn (a VexCorp File sits by it)
	part(m, "BoardPost", Vector3.new(0.4, 5, 0.4), CFrame.new(LOT.x0 + 22, 2.5, LOT.z1 - 8), WOOD, Enum.Material.Wood)
	local nb = part(m, "Noticeboard", Vector3.new(5, 3, 0.3), CFrame.new(LOT.x0 + 22, 5, LOT.z1 - 8), rgb(160, 120, 80), Enum.Material.Wood)
	sign(nb, Enum.NormalId.Back, "NO RECESS\nNO LUNCH\nNO WINDOWS*\n*except these", rgb(40, 20, 20), Enum.Font.SpecialElite)
end

local function buildHall(m)
	local W, D, H = B.x1 - B.x0, B.z1 - B.z0, B.h
	local cx, cz = (B.x0 + B.x1) / 2, (B.z0 + B.z1) / 2
	-- stone walls with a darker base, a string course, and quoins at the corners
	local function wall(x0, z0, x1, z1, skip)
		local along = x1 ~= x0
		local len = math.max(math.abs(x1 - x0), math.abs(z1 - z0))
		local mid = Vector3.new((x0 + x1) / 2, 0, (z0 + z1) / 2)
		local size = along and Vector3.new(len, H, 1.6) or Vector3.new(1.6, H, len)
		part(m, "Wall", size, CFrame.new(mid + Vector3.new(0, FLOOR + H / 2, 0)), STONE, Enum.Material.Brick)
		part(m, "Base", size + Vector3.new(0.4, -H + 3, 0.4), CFrame.new(mid + Vector3.new(0, FLOOR + 1.5, 0)), STONE_DARK, Enum.Material.Brick)
		part(m, "Course", size + Vector3.new(0.4, -H + 0.8, 0.4), CFrame.new(mid + Vector3.new(0, FLOOR + H * 0.55, 0)), STONE_DARK, Enum.Material.Marble)
		part(m, "Cornice", size + Vector3.new(0.8, -H + 1.2, 0.8), CFrame.new(mid + Vector3.new(0, FLOOR + H - 0.6, 0)), STONE_DARK, Enum.Material.Marble)
		_ = skip
	end
	wall(B.x0, B.z0, B.x1, B.z0)
	wall(B.x0, B.z0, B.x0, B.z1)
	wall(B.x1, B.z0, B.x1, B.z1)
	wall(B.x0, B.z1, CX - 4, B.z1)
	wall(CX + 4, B.z1, B.x1, B.z1)
	part(m, "Lintel", Vector3.new(8, H - 11, 1.6), CFrame.new(CX, FLOOR + 11 + (H - 11) / 2, B.z1), STONE, Enum.Material.Brick)
	for _, spec in { { B.x0, B.z0 }, { B.x1, B.z0 }, { B.x0, B.z1 }, { B.x1, B.z1 } } do
		for y = 0, H - 3, 3 do
			part(m, "Quoin", Vector3.new(2.2, 1.4, 2.2), CFrame.new(spec[1], FLOOR + 1 + y, spec[2]), rgb(200, 195, 186), Enum.Material.Marble)
		end
	end
	-- the entrance: a pediment on columns and two tall doors, one open
	for _, x in { -6, 6 } do
		cyl(m, "Column", 1.6, 13, Vector3.new(CX + x, FLOOR + 6.5, B.z1 + 4), rgb(225, 220, 210), Enum.Material.Marble)
		part(m, "ColumnBase", Vector3.new(2.4, 0.8, 2.4), CFrame.new(CX + x, FLOOR + 0.4, B.z1 + 4), rgb(200, 195, 186), Enum.Material.Marble)
	end
	part(m, "Porch", Vector3.new(16, 0.6, 7), CFrame.new(CX, FLOOR + 0.1, B.z1 + 3.5), rgb(200, 195, 186), Enum.Material.Marble)
	part(m, "Entablature", Vector3.new(16, 1.6, 8), CFrame.new(CX, FLOOR + 13.8, B.z1 + 3.8), rgb(225, 220, 210), Enum.Material.Marble)
	-- the triangular pediment: two wedges, tall sides meeting in the middle
	for _, s in { -1, 1 } do
		local w = Instance.new("WedgePart")
		w.Name = "Pediment"
		w.Anchored = true
		w.Size = Vector3.new(2, 5, 8)
		w.CFrame = CFrame.new(CX + s * 4, FLOOR + 17.1, B.z1 + 3.8) * CFrame.Angles(0, math.rad(s < 0 and 90 or -90), 0)
		w.Color = rgb(225, 220, 210)
		w.Material = Enum.Material.Marble
		w.Parent = m
	end
	local crest = part(m, "Crest", Vector3.new(3, 3, 0.4), CFrame.new(CX, FLOOR + 16.4, B.z1 + 7.9), PURPLE, Enum.Material.SmoothPlastic)
	sign(crest, Enum.NormalId.Back, "VP", GOLD, Enum.Font.Fantasy)
	part(m, "DoorLeft", Vector3.new(3.6, 10, 0.4), CFrame.new(CX - 2, FLOOR + 5, B.z1 - 0.2), rgb(70, 40, 30), Enum.Material.Wood)
	part(m, "DoorRight", Vector3.new(3.6, 10, 0.4), CFrame.new(CX + 5.4, FLOOR + 5, B.z1 - 2) * CFrame.Angles(0, math.rad(-75), 0), rgb(70, 40, 30), Enum.Material.Wood)
	-- windows: tall sash windows with stone surrounds, on the front and both sides, glazed both ways
	local function window(cf)
		-- cf: the window's centre on the wall's middle plane, looking out of the building
		for _, side in { 1, -1 } do
			-- (1.15 out from the wall's middle: clear of the plaster and panelling inside)
			local o = cf * CFrame.new(0, 0, -side * 1.15)
			part(m, "Window", Vector3.new(4, 6, 0.1), o, rgb(150, 190, 220), Enum.Material.Glass, { Transparency = 0.1, Reflectance = 0.15 })
			part(m, "Mullion", Vector3.new(0.3, 6, 0.2), o * CFrame.new(0, 0, -side * 0.08), rgb(245, 242, 235))
			part(m, "Transom", Vector3.new(4, 0.3, 0.2), o * CFrame.new(0, 0.6, -side * 0.08), rgb(245, 242, 235))
			for _, dx in { -2.1, 2.1 } do
				part(m, "Frame", Vector3.new(0.3, 6.4, 0.3), o * CFrame.new(dx, 0, -side * 0.08), rgb(245, 242, 235))
			end
		end
		part(m, "Surround", Vector3.new(5.2, 0.7, 2.6), cf * CFrame.new(0, 3.4, 0), rgb(210, 205, 196), Enum.Material.Marble)
		part(m, "Keystone", Vector3.new(1, 1.2, 2.7), cf * CFrame.new(0, 3.7, 0), rgb(225, 220, 210), Enum.Material.Marble)
		part(m, "Sill", Vector3.new(5.2, 0.5, 2.8), cf * CFrame.new(0, -3.25, 0), rgb(210, 205, 196), Enum.Material.Marble)
	end
	-- (rows at 8 and 18.5: above the panelling inside, clear of the string course outside)
	for _, x in { -38, -28, -18, 18, 28, 38 } do
		for _, y in { 8, 18.5 } do
			window(CFrame.new(CX + x, FLOOR + y, B.z1))
		end
	end
	for _, z in { -101, -114, -127, -140 } do
		for _, y in { 8, 18.5 } do
			window(CFrame.new(B.x0, FLOOR + y, z) * CFrame.Angles(0, math.rad(90), 0))
			window(CFrame.new(B.x1, FLOOR + y, z) * CFrame.Angles(0, math.rad(-90), 0))
		end
	end
	-- the slate roof, pitched, with dormers and a clock tower over the door
	part(m, "RoofSlab", Vector3.new(W + 2, 1, D + 2), CFrame.new(cx, FLOOR + H + 0.5, cz), SLATE, Enum.Material.Slate)
	for _, s in { -1, 1 } do
		local r = part(m, "Roof", Vector3.new(W + 3, 1, D / 2 + 3), CFrame.new(cx, FLOOR + H + 5, cz + s * (D / 4)) * CFrame.Angles(math.rad(s * 22), 0, 0), SLATE, Enum.Material.Slate)
		_ = r
	end
	part(m, "Ridge", Vector3.new(W + 3, 1, 1.2), CFrame.new(cx, FLOOR + H + 11.6, cz), rgb(40, 40, 50), Enum.Material.Metal)
	-- the clock tower
	local tx, tz = CX, B.z1 - 6
	part(m, "Tower", Vector3.new(10, 22, 10), CFrame.new(tx, FLOOR + H + 11, tz), STONE, Enum.Material.Brick)
	part(m, "TowerCourse", Vector3.new(10.8, 1, 10.8), CFrame.new(tx, FLOOR + H + 21.5, tz), STONE_DARK, Enum.Material.Marble)
	local face = cyl(m, "ClockFace", 7, 0.4, Vector3.new(tx, FLOOR + H + 15, tz + 5.1), rgb(245, 240, 225), Enum.Material.SmoothPlastic)
	face.CFrame = CFrame.new(tx, FLOOR + H + 15, tz + 5.1) * CFrame.Angles(0, math.rad(90), 0)
	part(m, "ClockRim", Vector3.new(7.6, 7.6, 0.2), CFrame.new(tx, FLOOR + H + 15, tz + 5.05), rgb(40, 40, 46), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 7.6, 7.6), CFrame = CFrame.new(tx, FLOOR + H + 15, tz + 5.05) * CFrame.Angles(0, math.rad(90), 0) })
	local hour = part(m, "HourHand", Vector3.new(0.3, 2.2, 0.1), CFrame.new(tx, FLOOR + H + 15.9, tz + 5.4), rgb(20, 20, 24))
	local minute = part(m, "MinuteHand", Vector3.new(0.2, 3.2, 0.1), CFrame.new(tx, FLOOR + H + 16.4, tz + 5.45), rgb(20, 20, 24))
	minute:SetAttribute("ClockHand", 1)
	hour:SetAttribute("ClockHand", 2)
	-- a stepped slate spire and a gold finial
	for k, w in { 11.4, 9, 6.8, 4.6, 2.6 } do
		part(m, "Spire", Vector3.new(w, 1.8, w), CFrame.new(tx, FLOOR + H + 22.4 + (k - 1) * 1.8, tz), SLATE, Enum.Material.Slate)
	end
	part(m, "Finial", Vector3.new(0.5, 4, 0.5), CFrame.new(tx, FLOOR + H + 33, tz), GOLD, Enum.Material.Metal)
	-- purple banners either side of the door
	for _, x in { -11, 11 } do
		part(m, "BannerPole", Vector3.new(4, 0.3, 0.3), CFrame.new(CX + x, FLOOR + 18.5, B.z1 + 1.2), GOLD, Enum.Material.Metal)
		local banner = part(m, "Banner", Vector3.new(3.4, 7, 0.1), CFrame.new(CX + x, FLOOR + 14.9, B.z1 + 1.3), PURPLE, Enum.Material.Fabric)
		sign(banner, Enum.NormalId.Back, "V\nP", GOLD, Enum.Font.Fantasy)
	end

	-- inside: a polished wood floor, a long carpet, oak panelling, chandeliers
	part(m, "Floor", Vector3.new(W - 1.6, 0.4, D - 1.6), CFrame.new(cx, FLOOR - 0.2, cz), rgb(112, 76, 50), Enum.Material.WoodPlanks)
	local PLASTER = rgb(226, 216, 196)
	part(m, "Plaster", Vector3.new(0.2, H - 6, D - 2), CFrame.new(B.x0 + 0.9, FLOOR + 5 + (H - 6) / 2, cz), PLASTER, Enum.Material.Plaster)
	part(m, "Plaster", Vector3.new(0.2, H - 6, D - 2), CFrame.new(B.x1 - 0.9, FLOOR + 5 + (H - 6) / 2, cz), PLASTER, Enum.Material.Plaster)
	for _, span in { { B.x0 + 1, CX - 4 }, { CX + 4, B.x1 - 1 } } do
		part(m, "Plaster", Vector3.new(span[2] - span[1], H - 6, 0.2), CFrame.new((span[1] + span[2]) / 2, FLOOR + 5 + (H - 6) / 2, B.z1 - 0.9), PLASTER, Enum.Material.Plaster)
		part(m, "Panelling", Vector3.new(span[2] - span[1], 5, 0.3), CFrame.new((span[1] + span[2]) / 2, FLOOR + 2.5, B.z1 - 0.95), rgb(100, 64, 40), Enum.Material.Wood)
	end
	part(m, "Ceiling", Vector3.new(W - 1.6, 0.4, D - 1.6), CFrame.new(cx, FLOOR + H - 0.3, cz), rgb(240, 234, 220), Enum.Material.Plaster)
	part(m, "Carpet", Vector3.new(12, 0.06, D - 4), CFrame.new(CX, FLOOR + 0.03, cz), rgb(110, 30, 50), Enum.Material.Fabric, { CanCollide = false })
	for _, x in { B.x0 + 0.9, B.x1 - 0.9 } do
		part(m, "Panelling", Vector3.new(0.3, 5, D - 2), CFrame.new(x + (x < cx and 0.2 or -0.2), FLOOR + 2.5, cz), rgb(100, 64, 40), Enum.Material.Wood)
	end
	for _, z in { -110, -140 } do
		for _, x in { 405, 449 } do
			local c = part(m, "Chandelier", Vector3.new(2.5, 1.4, 2.5), CFrame.new(x, FLOOR + H - 6, z), GOLD, Enum.Material.Metal)
			local bulb = part(m, "ChandelierLight", Vector3.new(2, 0.8, 2), CFrame.new(x, FLOOR + H - 7, z), rgb(255, 230, 180), Enum.Material.Neon)
			local l = Instance.new("PointLight")
			l.Range = 30
			l.Brightness = 1.4
			l.Color = rgb(255, 225, 175)
			l.Parent = bulb
			part(m, "Chain", Vector3.new(0.2, 5, 0.2), CFrame.new(x, FLOOR + H - 2.8, z), GOLD, Enum.Material.Metal)
			_ = c
		end
	end
	-- a big blackboard on the back wall: HOMEWORK IS THE FUTURE, and the office behind a partition
	for _, x in { -21, 21 } do
		part(m, "BoardFrame", Vector3.new(21, 8.2, 0.3), CFrame.new(CX + x, FLOOR + 8.5, -145.35), rgb(70, 44, 28), Enum.Material.Wood)
		local bb = part(m, "Blackboard", Vector3.new(20, 7.2, 0.3), CFrame.new(CX + x, FLOOR + 8.5, -145.2), rgb(34, 56, 44), Enum.Material.Slate)
		sign(bb, Enum.NormalId.Back, x < 0 and "HOMEWORK IS THE FUTURE\nHOMEWORK IS THE FUTURE\nHOMEWORK IS THE FUTURE" or "RECESS: CANCELLED\nLUNCH: 4 MINUTES\nFUN: SEE HEADMISTRESS", rgb(235, 235, 225), Enum.Font.PermanentMarker)
		part(m, "ChalkTray", Vector3.new(20, 0.3, 0.6), CFrame.new(CX + x, FLOOR + 4.8, -144.9), rgb(70, 44, 28), Enum.Material.Wood)
	end
	-- portraits along the side walls: the founder and her friends
	local portraits = { { "DR. VEX\nFounder", -107.5 }, { "CRUMPET\nButler of the Year", -120.5 }, { "THE SUGAR BARON\nGenerous Donor", -133.5 } }
	for _, pr in portraits do
		for _, x in { B.x0 + 1.1, B.x1 - 1.1 } do
			local rot = CFrame.Angles(0, math.rad(x < cx and -90 or 90), 0)
			part(m, "PortraitFrame", Vector3.new(4.6, 5.6, 0.3), CFrame.new(x, FLOOR + 11.5, pr[2]) * rot, GOLD, Enum.Material.Metal)
			local canvas = part(m, "Portrait", Vector3.new(3.8, 4.8, 0.2), CFrame.new(x + (x < cx and 0.15 or -0.15), FLOOR + 11.5, pr[2]) * rot, rgb(60, 30, 70), Enum.Material.Fabric)
			sign(canvas, Enum.NormalId.Front, pr[1], rgb(240, 225, 180), Enum.Font.Fantasy)
		end
	end
	part(m, "Partition", Vector3.new(W - 3, H - 1, 1), CFrame.new(cx - 9, FLOOR + (H - 1) / 2, -146), rgb(100, 64, 40), Enum.Material.Wood, { Size = Vector3.new(CX - 4 - B.x0 - 1, H - 1, 1), CFrame = CFrame.new((B.x0 + 1 + CX - 4) / 2, FLOOR + (H - 1) / 2, -146) })
	part(m, "Partition", Vector3.new(1, 1, 1), CFrame.new(), rgb(100, 64, 40), Enum.Material.Wood, { Size = Vector3.new(B.x1 - 1 - (CX + 4), H - 1, 1), CFrame = CFrame.new((B.x1 - 1 + CX + 4) / 2, FLOOR + (H - 1) / 2, -146) })
	part(m, "OfficeLintel", Vector3.new(8, H - 10, 1), CFrame.new(CX, FLOOR + 10 + (H - 10) / 2, -146), rgb(100, 64, 40), Enum.Material.Wood)
	local plate = part(m, "OfficeSign", Vector3.new(6, 1.2, 0.2), CFrame.new(CX, FLOOR + 11, -145.4), GOLD, Enum.Material.Metal)
	sign(plate, Enum.NormalId.Back, "HEADMISTRESS", rgb(40, 20, 20), Enum.Font.Fantasy)
	-- the office: a desk, a globe, a trophy case
	part(m, "OfficeDesk", Vector3.new(8, 3.2, 3), CFrame.new(CX, FLOOR + 1.6, -154), rgb(80, 48, 30), Enum.Material.Wood)
	cyl(m, "Globe", 1.6, 1.6, Vector3.new(CX + 3, FLOOR + 4, -154), rgb(90, 150, 210), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6) })
	part(m, "TrophyCase", Vector3.new(10, 7, 1.6), CFrame.new(CX, FLOOR + 3.5, -158.6), rgb(80, 48, 30), Enum.Material.Wood)
	part(m, "CaseGlass", Vector3.new(9, 6, 0.2), CFrame.new(CX, FLOOR + 3.8, -157.7), rgb(200, 230, 255), Enum.Material.Glass, { Transparency = 0.6 })
	for i = 0, 3 do
		cyl(m, "Trophy", 0.8, 1.4, Vector3.new(CX - 3 + i * 2, FLOOR + 5.2, -158.4), GOLD, Enum.Material.Metal)
	end
end

---------------------------------------------------------------------------
-- the desks and the kids at them
---------------------------------------------------------------------------
local DESK_X = { 397, 409, 445, 457 }
local DESK_Z = { -114, -130 }

local function rollKid(player)
	local p = Data.get(player)
	local lvl = p and p.rival and p.rival.level or 0
	local tier = math.clamp((p and p.tier or 1) + math.floor(lvl / 6), 1, #Config.Heist.prizeByTier)
	local band = Config.Heist.prizeByTier[tier]
	local rarity = band[math.random(#band)]
	local pool = {}
	for _, s in Config.Students do
		if s.rarity == rarity then table.insert(pool, s) end
	end
	-- the grade: better the higher your Rivalry
	local roll = math.random()
	local grade = "Normal"
	if roll < math.min(0.5, 0.08 + lvl * 0.02) then grade = "Gifted"
	elseif roll < math.min(0.8, 0.25 + lvl * 0.03) then grade = "Honor Roll" end
	return pool[math.random(#pool)], grade
end

local function seatKid(d)
	if d.kid then d.kid:Destroy() end
	-- what sits there to look at: a Vex Prep kid (what you actually carry out is rolled for you)
	local pool = {}
	for _, s in Config.Students do
		if s.rarity == "Uncommon" or s.rarity == "Rare" or s.rarity == "Epic" then table.insert(pool, s) end
	end
	local def = pool[math.random(#pool)]
	local kid = Factory.build(def, "Normal")
	for _, x in kid:GetDescendants() do
		if x:IsA("BillboardGui") then x:Destroy() end
	end
	-- seated like at a player's desk: the root half a root-height over the seat (PlotService)
	local hum = kid:FindFirstChildOfClass("Humanoid")
	local seatTop = FLOOR + 2.3
	local y = seatTop + kid.PrimaryPart.Size.Y * 0.5 + (hum and hum.HipHeight * 0.1 or 0)
	kid.PrimaryPart.CFrame = CFrame.new(d.x, y, d.z + 2.4) -- (facing -Z: the blackboard)
	kid.Parent = d.model
	Factory.play(kid, "sit")
	d.kid = kid
	d.prompt.Enabled = true
	d.emptyUntil = nil
end

local function buildDesk(m, x, z, i)
	local d = Instance.new("Model")
	d.Name = "Desk" .. i
	d.Parent = m
	-- a heavy oak desk with a brass lamp, and a chair behind it (facing the blackboard at -Z)
	part(d, "Top", Vector3.new(5, 0.4, 3), CFrame.new(x, FLOOR + 3, z), rgb(90, 56, 34), Enum.Material.Wood)
	for _, dx in { -2.2, 2.2 } do
		part(d, "Side", Vector3.new(0.4, 3, 2.8), CFrame.new(x + dx, FLOOR + 1.5, z), rgb(80, 48, 30), Enum.Material.Wood)
	end
	part(d, "Books", Vector3.new(1.2, 0.8, 1.6), CFrame.new(x - 1.4, FLOOR + 3.6, z - 0.3), rgb(120, 30, 40))
	part(d, "Homework", Vector3.new(1.6, 0.1, 1.2), CFrame.new(x + 0.6, FLOOR + 3.25, z), rgb(250, 248, 240))
	part(d, "Seat", Vector3.new(2.6, 0.4, 2.4), CFrame.new(x, FLOOR + 2.1, z + 2.6), rgb(60, 30, 50), Enum.Material.Fabric)
	part(d, "Back", Vector3.new(2.6, 3, 0.4), CFrame.new(x, FLOOR + 3.6, z + 3.8), rgb(60, 30, 50), Enum.Material.Fabric)
	local spot = part(d, "PromptSpot", Vector3.new(1, 1, 1), CFrame.new(x + 2.8, FLOOR + 3, z + 2.4), rgb(0, 0, 0), nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = "Vex Prep student"
	prompt.HoldDuration = 2
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Color", rgb(255, 150, 60))
	prompt.Parent = spot
	local desk = { model = d, x = x, z = z, prompt = prompt, index = i }
	table.insert(desks, desk)
	return desk
end

---------------------------------------------------------------------------
-- stealing, carrying, escaping, getting caught
---------------------------------------------------------------------------
local function dropCarry(player, why)
	local c = carrying[player]
	if not c then return end
	carrying[player] = nil
	if c.kid then c.kid:Destroy() end
	player:SetAttribute("Heist", nil)
	StealService.setSpeed(player)
	if c.desk and not c.desk.kid then seatKid(c.desk) end
	if why and player.Parent then
		Remotes.Notify:FireClient(player, why, "bad")
		Remotes.Push:FireClient(player, "heist", { state = "failed" })
	end
end

local function thrownOut(player)
	local char = player.Character
	if not char then return end
	dropCarry(player, "A hall monitor caught you! Detention... just kidding. OUT!")
	char:PivotTo(CFrame.lookAt(Vector3.new(CX + math.random(-4, 4), 3.5, LOT.z1 + 8), Vector3.new(CX, 3.5, 0)))
	stunUntil[player] = now() + 1.5
	player:SetAttribute("Stunned", true)
	StealService.setSpeed(player)
	task.delay(1.5, function()
		if not player.Parent then return end
		player:SetAttribute("Stunned", nil)
		StealService.setSpeed(player)
	end)
	Signals.fire("rivalCaught", player)
end

local function takeKid(player, d)
	if carrying[player] or not d.kid or player:GetAttribute("Carrying") or player:GetAttribute("Heist") then return end
	local char = player.Character
	local proot = char and char:FindFirstChild("HumanoidRootPart")
	if not proot or (stunUntil[player] or 0) > now() then return end
	if (d.prompt.Parent.Position - proot.Position).Magnitude > 12 then return end
	local def, grade = rollKid(player)
	d.kid:Destroy()
	d.kid = nil
	d.prompt.Enabled = false
	d.emptyUntil = now() + Config.Rival.restock
	local kid = Factory.build(def, grade)
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
	carrying[player] = { desk = d, kid = kid, def = def, grade = grade, lastPos = proot.Position, lastT = now() }
	player:SetAttribute("Heist", def.name)
	StealService.setSpeed(player)
	Remotes.Push:FireClient(player, "heist", { state = "carrying", name = def.name })
	Remotes.Notify:FireClient(player, "\u{1F514} RIIING! The school bell! The hall monitors are coming!", "steal")
	-- the bell: every monitor after you
	guards:alertAll(player)
	Signals.fire("rivalTake", player, def)
end

local function escaped(player)
	local c = carrying[player]
	if not c then return end
	carrying[player] = nil
	if c.kid then c.kid:Destroy() end
	player:SetAttribute("Heist", nil)
	StealService.setSpeed(player)
	local p = Data.get(player)
	if not p then return end
	local LetterService = require(script.Parent.LetterService)
	if not LetterService.deliver(player, c.def, true, c.grade, "STOLEN from Vex Prep!") then
		p.pendingBench = p.pendingBench or {}
		table.insert(p.pendingBench, { id = c.def.id, grade = c.grade })
	end
	p.rival = p.rival or { level = 0, stolen = 0 }
	p.rival.stolen += 1
	p.rival.level += 1
	player:SetAttribute("Rivalry", p.rival.level)
	Remotes.Push:FireClient(player, "heist", { state = "prize", name = c.def.name, rarity = c.def.rarity })
	Remotes.Notify:FireClient(player, ("\u{1F3C6} You stole %s (%s%s) from Vex Prep! Rivalry Lv.%d: their kids get rarer... and they WILL get you back."):format(c.def.name, c.grade ~= "Normal" and (c.grade .. " ") or "", c.def.rarity, p.rival.level), "good")
	-- revenge: Vex Prep's goons come for your school sooner
	local RaidService = require(script.Parent.RaidService)
	if RaidService.soon then RaidService.soon(player, Config.Rival.revengeAfter) end
	Signals.fire("rivalEscaped", player, c.def)
	Data.saveSoon(player)
end

local function tick(dt)
	guards:tick(dt)
	local t = now()
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local proot = char and char:FindFirstChild("HumanoidRootPart")
		if not proot then
			if carrying[player] then dropCarry(player) end
			continue
		end
		local pos = proot.Position
		local inside = inLot(pos)
		-- the first time someone walks up to the gate: the Vex Prep cutscene (once per save)
		if not seen[player] then
			local dx, dz = pos.X - CX, pos.Z - LOT.z1
			if dx * dx + dz * dz < 75 * 75 and player:GetAttribute("Ready") and not player:GetAttribute("Mission") then
				local p = Data.get(player)
				if p then
					seen[player] = true
					if not p.rivalSeen then
						p.rivalSeen = true
						Remotes.Cutscene:FireClient(player, "Rival")
					end
				end
			end
		end
		if inside or lastSpotted[player] ~= nil then
			local spotted = inside and guards:isChasing(player) or nil
			if spotted ~= lastSpotted[player] then
				lastSpotted[player] = spotted
				player:SetAttribute("Spotted", spotted)
			end
		end
		local c = carrying[player]
		if c then
			if not inside then
				escaped(player)
				continue
			end
			local moved = Vector3.new(pos.X - c.lastPos.X, 0, pos.Z - c.lastPos.Z).Magnitude
			if moved > Config.Heist.carrySpeed * 1.8 * (t - c.lastT) + 6 then
				dropCarry(player, "You dropped them!")
				continue
			end
			if t - c.lastT >= 0.25 then c.lastPos, c.lastT = pos, t end
		end
	end
	for _, d in desks do
		if d.emptyUntil and t >= d.emptyUntil and not d.kid then
			local held = false
			for _, c in carrying do
				if c.desk == d then held = true end
			end
			if not held then seatKid(d) end
		end
	end
end

function RivalService.start()
	local old = workspace:FindFirstChild("VexPrep")
	if old then old:Destroy() end
	local deco = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Deco")
	for _, m in deco and deco:GetChildren() or {} do
		if m:IsA("Model") then
			local cf = m:GetBoundingBox()
			if cf.Position.X > LOT.x0 - 6 and cf.Position.X < LOT.x1 + 6 and cf.Position.Z > LOT.z0 - 6 and cf.Position.Z < LOT.z1 + 6 then m:Destroy() end
		end
	end
	root = Instance.new("Model")
	root.Name = "VexPrep"
	local grounds = Instance.new("Model")
	grounds.Name = "Grounds"
	grounds.Parent = root
	buildGrounds(grounds)
	local hall = Instance.new("Model")
	hall.Name = "Hall"
	hall.Parent = root
	buildHall(hall)
	local desksModel = Instance.new("Model")
	desksModel.Name = "Desks"
	desksModel.Parent = root
	local i = 0
	for _, z in DESK_Z do
		for _, x in DESK_X do
			i += 1
			buildDesk(desksModel, x, z, i)
		end
	end
	local guardsFolder = Instance.new("Folder")
	guardsFolder.Name = "Monitors"
	guardsFolder.Parent = root
	root.Parent = workspace
	pcall(function() root.ModelStreamingMode = Enum.ModelStreamingMode.Atomic end)

	guards = Guards.new({
		id = "HallMonitor", name = "Hall Monitor", title = "Vex Prep", outfit = "prefect",
		folder = guardsFolder,
		area = guardArea,
		grounds = inLot,
		sight = { sight = 26, angle = 100, hear = 5 },
		patrolSpeed = 7, chaseSpeed = 14.5, carrySpeed = 13,
		isCarrying = function(player) return carrying[player] ~= nil end,
		onCatch = function(player) thrownOut(player) end,
	})
	guards:add({ Vector3.new(389, FLOOR, -104), Vector3.new(418, FLOOR, -104), Vector3.new(418, FLOOR, -140), Vector3.new(389, FLOOR, -140) })
	guards:add({ Vector3.new(465, FLOOR, -140), Vector3.new(436, FLOOR, -140), Vector3.new(436, FLOOR, -104), Vector3.new(465, FLOOR, -104) })
	guards:add({ Vector3.new(CX, FLOOR, -100), Vector3.new(CX, FLOOR, -142) })

	for _, d in desks do
		seatKid(d)
		d.prompt.Triggered:Connect(function(player) takeKid(player, d) end)
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
		if not ok then warn("[VexPrep]", err) end
	end)
	local function watch(player)
		local function onChar(char)
			if carrying[player] then dropCarry(player) end
			local hum = char:WaitForChild("Humanoid", 10)
			if hum then
				hum.Died:Connect(function()
					if carrying[player] then dropCarry(player, "You fainted! The kid ran back to class.") end
				end)
			end
		end
		player.CharacterAdded:Connect(onChar)
		if player.Character then task.spawn(onChar, player.Character) end
		task.spawn(function()
			for _ = 1, 40 do
				local p = Data.get(player)
				if p then
					player:SetAttribute("Rivalry", p.rival and p.rival.level or 0)
					return
				end
				task.wait(0.5)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do watch(player) end
	Players.PlayerRemoving:Connect(function(player)
		dropCarry(player)
		stunUntil[player] = nil
		lastSpotted[player] = nil
		seen[player] = nil
	end)
end

function RivalService.inLot(pos) return inLot(pos) end
function RivalService.debugTake(player, i)
	local d = desks[i or 1]
	if not d then return false end
	local char = player.Character
	if char then char:PivotTo(CFrame.new(d.x + 2.8, FLOOR + 3.5, d.z + 3.4)) end
	task.wait(0.2)
	takeKid(player, d)
	return carrying[player] ~= nil
end
function RivalService.debugCalm(secs)
	for _, g in guards.list do
		g.state = "stunned"
		g.target = nil
		g.stunUntil = now() + (secs or 30)
		require(script.Parent.Walkers).stop(g.model)
	end
	return #guards.list
end

return RivalService
