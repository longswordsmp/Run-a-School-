-- ServerScriptService.Server.StreetService
-- Recess Row changes as your story goes on. Every stage prop is built once, here, into
-- ReplicatedStorage.StreetStages; each client (Street.client) shows the ones its own chapter has
-- reached (player attribute "Chapter": 1-11, 12 once the story's done), so every player sees their
-- own story on the street.
--   Posters       ch 1-11   VexCorp posters on the lamp posts
--   ForSale       ch 5-11   Vex's limo parked at the plaza, a SOLD SOON sign, the fountain drained
--   Searchlights  ch 7-11   searchlights sweeping from the Factory roof
--   MachineBuild  ch 9      the Homework Machine going up on the Factory roof (scaffold, crane)
--   Machine       ch 10-11  the Homework Machine, awake (core, gears, a pencil arm, lightning)
--   Saved         ch 12     bunting down the street and a RECESS IS SAVED banner on the arch
-- Each model carries From / To attributes (shown while From <= chapter <= To). The client also does
-- the bits that are changes to the map rather than new props (billboard text, fountain water, sky).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StreetService = {}

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local PURPLE = rgb(105, 45, 150)
local DEEP = rgb(40, 18, 60)
local LILAC = rgb(200, 150, 255)
local STEEL = rgb(120, 124, 134)
local DARK = rgb(52, 50, 62)
local HAZARD = rgb(245, 200, 40)

local function part(parent, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props or {} do p[k] = v end
	p.Parent = parent
	return p
end
-- a cylinder standing up (Roblox cylinders lie along X)
local function column(parent, name, d, h, pos, color, material, props)
	return part(parent, name, Vector3.new(h, d, d), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, material, (function()
		local t = { Shape = Enum.PartType.Cylinder }
		for k, v in props or {} do t[k] = v end
		return t
	end)())
end
-- a disc facing along a direction (a cylinder whose axis points that way)
local function disc(parent, name, d, thick, pos, facing, color, material, props)
	local t = { Shape = Enum.PartType.Cylinder }
	for k, v in props or {} do t[k] = v end
	return part(parent, name, Vector3.new(thick, d, d), CFrame.lookAt(pos, pos + facing) * CFrame.Angles(0, math.rad(90), 0), color, material, t)
end
local function sign(p, face, text, color, bg, font, stroke)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.LightInfluence = 0.3
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -16, 1, -16)
	t.Position = UDim2.fromOffset(8, 8)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = font or Enum.Font.LuckiestGuy
	t.Text = text
	t.TextColor3 = color
	t.Parent = g
	if bg then
		g.Parent.Color = bg
	end
	if stroke then
		local s = Instance.new("UIStroke")
		s.Color = stroke
		s.Thickness = 3
		s.Parent = t
	end
	return t
end
local function light(p, kind, range, brightness, color)
	local l = Instance.new(kind or "PointLight")
	l.Range = range
	l.Brightness = brightness
	l.Color = color
	l.Parent = p
	return l
end
local function stage(folder, name, from, to)
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("From", from)
	m:SetAttribute("To", to)
	m.Parent = folder
	return m
end

---------------------------------------------------------------------------
-- VexCorp posters on the lamp posts (lamps every 50 studs at z = +-24; tools/build_map.lua)
---------------------------------------------------------------------------
local POSTERS = {
	{ "VEXCORP\nNOW HIRING:\nGOONS", LILAC, DEEP },
	{ "HOMEWORK\nIS THE\nFUTURE", rgb(255, 255, 255), PURPLE },
	{ "RECESS IS\nCANCELLED", rgb(255, 90, 110), rgb(24, 12, 34) },
	{ "WANTED:\nKIDS WHO\nLOVE TESTS", PURPLE, rgb(225, 205, 255) },
}
local function buildPosters(folder)
	local m = stage(folder, "Posters", 1, 11)
	local k = 0
	for x = -200, 200, 50 do
		for _, z in { -24, 24 } do
			if x == 0 and z == 24 then continue end
			k += 1
			local spec = POSTERS[k % #POSTERS + 1]
			-- on the pole's street side, a little crooked, taped at the corners
			local toStreet = z > 0 and -1 or 1
			local tilt = math.rad(((k * 37) % 9) - 4)
			local cf = CFrame.lookAt(Vector3.new(x, 5.2, z + toStreet * 0.47), Vector3.new(x, 5.2, z + toStreet * 5)) * CFrame.Angles(0, 0, tilt)
			local board = part(m, "Poster", Vector3.new(2.6, 3.4, 0.08), cf, spec[3], Enum.Material.SmoothPlastic)
			-- (text only up close: ~50 posters of scaled text would crowd the glyph cache)
			sign(board, Enum.NormalId.Front, spec[1], spec[2], nil, Enum.Font.LuckiestGuy).Parent.MaxDistance = 90
			-- a V in the corner
			local v = part(m, "PosterLogo", Vector3.new(0.7, 0.7, 0.02), cf * CFrame.new(0.8, -1.25, -0.05), LILAC, Enum.Material.Neon)
			sign(v, Enum.NormalId.Front, "V", DEEP, nil, Enum.Font.LuckiestGuy).Parent.MaxDistance = 60
			for _, c in { { -1.2, 1.6 }, { 1.2, 1.6 }, { -1.2, -1.6 }, { 1.2, -1.6 } } do
				part(m, "Tape", Vector3.new(0.45, 0.2, 0.02), cf * CFrame.new(c[1], c[2], -0.05) * CFrame.Angles(0, 0, math.rad(c[1] * c[2] > 0 and 35 or -35)), rgb(235, 235, 225))
			end
		end
	end
end

---------------------------------------------------------------------------
-- Vex's offer: the limo parked at the back of the plaza, and a SOLD SOON sign out front
---------------------------------------------------------------------------
local function buildForSale(folder)
	local m = stage(folder, "ForSale", 5, 11)
	local StoryService = require(script.Parent.StoryService)
	local limo = StoryService.buildLimo()
	-- (parked and empty: Vex is off buying things)
	local vex = limo:FindFirstChild("Vex")
	if vex then vex:Destroy() end
	for _, d in limo:GetDescendants() do
		if d:IsA("BasePart") then d.CanCollide = false d.Anchored = true end
	end
	limo:PivotTo(CFrame.new(0, 0.6, -104))
	limo.Parent = m
	-- the sign: two posts, a swinging board, a slapped-on SOLD SOON banner
	local base = Vector3.new(14, 0.6, -66)
	local face = CFrame.lookAt(base, base + Vector3.new(0, 0, 1))
	for _, x in { -2.6, 2.6 } do
		part(m, "SignPost", Vector3.new(0.45, 8, 0.45), face * CFrame.new(x, 4, 0), rgb(245, 245, 240), Enum.Material.Wood)
	end
	part(m, "SignBar", Vector3.new(6.2, 0.4, 0.45), face * CFrame.new(0, 7.6, 0), rgb(245, 245, 240), Enum.Material.Wood)
	for _, x in { -2, 2 } do
		part(m, "SignChain", Vector3.new(0.12, 1, 0.12), face * CFrame.new(x, 6.9, 0), STEEL, Enum.Material.Metal)
	end
	local board = part(m, "SignBoard", Vector3.new(5.4, 3.2, 0.2), face * CFrame.new(0, 4.9, 0), rgb(250, 248, 240))
	sign(board, Enum.NormalId.Front, "FOR SALE", PURPLE, nil, Enum.Font.LuckiestGuy)
	sign(board, Enum.NormalId.Back, "FOR SALE", PURPLE, nil, Enum.Font.LuckiestGuy)
	local band = part(m, "SoldBand", Vector3.new(6.4, 1.1, 0.06), face * CFrame.new(0, 4.9, -0.14) * CFrame.Angles(0, 0, math.rad(-16)), rgb(220, 40, 60))
	sign(band, Enum.NormalId.Front, "SOLD SOON!", rgb(255, 255, 255), nil, Enum.Font.LuckiestGuy)
	local small = part(m, "Realty", Vector3.new(5.4, 0.7, 0.2), face * CFrame.new(0, 2.9, 0), DEEP)
	sign(small, Enum.NormalId.Front, "VEXCORP REALTY", LILAC, nil, Enum.Font.FredokaOne)
	-- the drained fountain: dried sludge where the water was (the client hides the water)
	part(m, "Sludge", Vector3.new(0.12, 19.4, 19.4), CFrame.new(0, 3.12, -86) * CFrame.Angles(0, 0, math.rad(90)), rgb(92, 96, 70), Enum.Material.Slate, { Shape = Enum.PartType.Cylinder })
	for i, spec in { { -4, 3 }, { 3, -5 }, { 5, 4 } } do
		part(m, "Junk", Vector3.new(1.2, 0.08, 1.6), CFrame.new(spec[1], 3.22, -86 + spec[2]) * CFrame.Angles(0, math.rad(i * 50), 0), rgb(240, 240, 230))
	end
	column(m, "Can", 0.6, 0.9, Vector3.new(-2, 3.6, -80), PURPLE, Enum.Material.Metal)
end

---------------------------------------------------------------------------
-- searchlights on the Factory roof (the client sweeps the heads round)
---------------------------------------------------------------------------
local function buildSearchlights(folder)
	local m = stage(folder, "Searchlights", 7, 11)
	for i, x in { -25, 25 } do
		local pos = Vector3.new(x, 26.5, 50)
		part(m, "LightBase", Vector3.new(3, 1, 3), CFrame.new(pos + Vector3.new(0, 0.5, 0)), DARK, Enum.Material.Metal)
		column(m, "LightStand", 0.8, 2, pos + Vector3.new(0, 2, 0), STEEL, Enum.Material.Metal)
		local head = Instance.new("Model")
		head.Name = "SearchHead" .. i
		head.Parent = m
		local pivot = part(head, "Pivot", Vector3.new(0.4, 0.4, 0.4), CFrame.new(pos + Vector3.new(0, 3.4, 0)), DARK, nil, { Transparency = 1 })
		head.PrimaryPart = pivot
		-- yoke, drum, lens, and a long soft beam pointing up and out over the street
		for _, s in { -1, 1 } do
			part(head, "Yoke", Vector3.new(0.3, 2, 0.5), CFrame.new(pos + Vector3.new(s * 1.5, 3.8, 0)), DARK, Enum.Material.Metal)
		end
		local drum = disc(head, "Drum", 2.6, 3, pos + Vector3.new(0, 4.2, 0), Vector3.new(0, 0, -1), rgb(70, 68, 80), Enum.Material.Metal)
		disc(head, "Rim", 2.9, 0.4, pos + Vector3.new(0, 4.2, -1.6), Vector3.new(0, 0, -1), DARK, Enum.Material.Metal)
		local lens = disc(head, "Lens", 2.3, 0.2, pos + Vector3.new(0, 4.2, -1.75), Vector3.new(0, 0, -1), rgb(240, 225, 255), Enum.Material.Neon)
		local beamLen = 90
		disc(head, "Beam", 3.4, beamLen, pos + Vector3.new(0, 4.2, -1.8 - beamLen / 2), Vector3.new(0, 0, -1), rgb(215, 190, 255), Enum.Material.Neon, { Transparency = 0.86, CastShadow = false })
		disc(head, "BeamCore", 1.6, beamLen, pos + Vector3.new(0, 4.2, -1.8 - beamLen / 2), Vector3.new(0, 0, -1), rgb(245, 235, 255), Enum.Material.Neon, { Transparency = 0.8, CastShadow = false })
		local spot = light(lens, "SpotLight", 60, 3, rgb(225, 205, 255))
		spot.Face = Enum.NormalId.Left
		spot.Angle = 22
		_ = drum
		-- tipped up over the street to start; the client swings it round
		head:PivotTo(pivot.CFrame * CFrame.Angles(math.rad(25), 0, 0))
	end
end

---------------------------------------------------------------------------
-- the Homework Machine, rising out of the Factory's own roof (between the vents and the
-- smokestacks), so it towers over the street instead of hiding behind the building
---------------------------------------------------------------------------
local MX, MZ, ROOF = 0, 96, 27.2 -- (the roof slab's top: FactoryService, Hh + 1.2)
local SCAFFOLD = rgb(160, 165, 175)

-- plinth, housing, seams, rivets, girders; returns the housing's top y
local function machineBody(m, height)
	part(m, "Plinth", Vector3.new(26, 2, 20), CFrame.new(MX, ROOF + 1, MZ), DARK, Enum.Material.DiamondPlate)
	for i = 0, 12 do
		part(m, "Hazard", Vector3.new(2, 0.5, 0.2), CFrame.new(MX - 12 + i * 2, ROOF + 1.8, MZ - 10.05) * CFrame.Angles(0, 0, math.rad(45)), i % 2 == 0 and HAZARD or rgb(30, 30, 34))
	end
	local base = ROOF + 2
	part(m, "Body", Vector3.new(18, height, 14), CFrame.new(MX, base + height / 2, MZ), PURPLE, Enum.Material.Metal)
	for y = 7, height - 1, 7 do
		part(m, "Seam", Vector3.new(18.2, 0.45, 14.2), CFrame.new(MX, base + y, MZ), DEEP, Enum.Material.Metal)
	end
	for _, x in { -9.05, 9.05 } do
		for y = 4, height - 1, 3.5 do
			part(m, "Rivets", Vector3.new(0.2, 0.35, 12.4), CFrame.new(MX + x, base + y, MZ), STEEL, Enum.Material.Metal)
		end
	end
	for _, x in { -9, 9 } do
		for _, z in { -7, 7 } do
			part(m, "Girder", Vector3.new(1.3, height + 1, 1.3), CFrame.new(MX + x, base + height / 2, MZ + z), DARK, Enum.Material.Metal)
		end
	end
	return base + height
end

local function buildMachineBuild(folder)
	local m = stage(folder, "MachineBuild", 9, 9)
	local top = machineBody(m, 18)
	-- the unfinished top: bare girders sticking up, a stack of plates waiting
	for _, x in { -9, 9 } do
		for _, z in { -7, 7 } do
			part(m, "BareGirder", Vector3.new(1.1, 12, 1.1), CFrame.new(MX + x, top + 6, MZ + z), DARK, Enum.Material.Metal)
		end
	end
	part(m, "TopBeam", Vector3.new(19, 1, 1), CFrame.new(MX, top + 11.5, MZ - 7), DARK, Enum.Material.Metal)
	part(m, "TopBeam", Vector3.new(19, 1, 1), CFrame.new(MX, top + 11.5, MZ + 7), DARK, Enum.Material.Metal)
	for i = 0, 3 do
		part(m, "PlateStack", Vector3.new(7, 0.5, 5), CFrame.new(MX - 14, ROOF + 0.3 + i * 0.55, MZ + 8) * CFrame.Angles(0, math.rad(i * 4), 0), PURPLE, Enum.Material.Metal)
	end
	-- scaffolding round it, front and back
	for _, x in { -11, -5.5, 0, 5.5, 11 } do
		for _, z in { MZ - 9, MZ + 9 } do
			part(m, "Scaffold", Vector3.new(0.35, top - ROOF + 14, 0.35), CFrame.new(MX + x, (top + ROOF + 14) / 2, z), SCAFFOLD, Enum.Material.Metal)
		end
	end
	for y = ROOF + 5, top + 12, 5 do
		for _, z in { MZ - 9, MZ + 9 } do
			part(m, "ScaffoldBar", Vector3.new(22.4, 0.3, 0.3), CFrame.new(MX, y, z), SCAFFOLD, Enum.Material.Metal)
			part(m, "Plank", Vector3.new(22, 0.25, 1.6), CFrame.new(MX, y + 0.3, z + (z < MZ and -0.6 or 0.6)), rgb(170, 120, 70), Enum.Material.WoodPlanks)
		end
	end
	-- a tower crane on the roof lifting the next plate into place
	local cx, cz = MX + 17, MZ + 2
	for _, dx in { -1, 1 } do
		for _, dz in { -1, 1 } do
			part(m, "CraneLeg", Vector3.new(0.45, 44, 0.45), CFrame.new(cx + dx, ROOF + 22, cz + dz), HAZARD, Enum.Material.Metal)
		end
	end
	for y = ROOF + 3, ROOF + 42, 3.5 do
		part(m, "CraneBrace", Vector3.new(2.6, 0.25, 0.25), CFrame.new(cx, y, cz - 1) * CFrame.Angles(0, 0, math.rad(40)), HAZARD, Enum.Material.Metal)
		part(m, "CraneBrace", Vector3.new(2.6, 0.25, 0.25), CFrame.new(cx, y + 1.75, cz + 1) * CFrame.Angles(0, 0, math.rad(-40)), HAZARD, Enum.Material.Metal)
	end
	local jibY = ROOF + 45
	part(m, "CraneJib", Vector3.new(36, 1.4, 1.4), CFrame.new(cx - 13, jibY, cz), HAZARD, Enum.Material.Metal)
	part(m, "CraneJibTop", Vector3.new(36, 0.3, 0.3), CFrame.new(cx - 13, jibY + 1.6, cz), HAZARD, Enum.Material.Metal)
	part(m, "CraneCab", Vector3.new(3.2, 2.8, 2.8), CFrame.new(cx, jibY - 2.2, cz - 1.6), rgb(235, 235, 240), Enum.Material.SmoothPlastic)
	part(m, "CabWindow", Vector3.new(2.6, 1.4, 0.1), CFrame.new(cx, jibY - 1.9, cz - 3.05), rgb(120, 180, 230), Enum.Material.Glass)
	part(m, "Counterweight", Vector3.new(4.5, 3.2, 2.6), CFrame.new(cx + 6, jibY - 0.4, cz), DARK, Enum.Material.Concrete)
	part(m, "Cable", Vector3.new(0.12, 14, 0.12), CFrame.new(cx - 24, jibY - 7.5, cz), rgb(30, 30, 30), Enum.Material.Metal)
	part(m, "Hook", Vector3.new(0.8, 1, 0.8), CFrame.new(cx - 24, jibY - 15, cz), DARK, Enum.Material.Metal)
	part(m, "HangingPlate", Vector3.new(9, 6, 0.6), CFrame.new(cx - 24, jibY - 19, cz) * CFrame.Angles(0, math.rad(25), 0), PURPLE, Enum.Material.Metal)
	-- the sign the builders put up, high on the scaffold facing the street
	local board = part(m, "BuildSign", Vector3.new(22, 5, 0.4), CFrame.new(MX, top + 9, MZ - 11), rgb(250, 250, 245)) -- (in front of the planks)
	sign(board, Enum.NormalId.Front, "COMING SOON: THE HOMEWORK MACHINE", PURPLE, nil, Enum.Font.LuckiestGuy)
	for _, x in { -1, 1 } do
		local b = part(m, "Beacon", Vector3.new(0.9, 0.9, 0.9), CFrame.new(MX + x * 11, top + 12.4, MZ - 9), rgb(255, 140, 40), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
		b:SetAttribute("Blink", true)
	end
end

local function buildMachine(folder)
	local m = stage(folder, "Machine", 10, 11)
	local top = machineBody(m, 34)
	local front = MZ - 7
	-- the core: a round window in a heavy ring, glowing and pulsing
	local coreY = top - 16
	local ring = Instance.new("Model")
	ring.Name = "CoreRing"
	ring.Parent = m
	for a = 0, 345, 15 do
		local r = 5.6
		local p = Vector3.new(MX + math.cos(math.rad(a)) * r, coreY + math.sin(math.rad(a)) * r, front - 0.5)
		part(ring, "RingSeg", Vector3.new(1.6, 1.6, 1.4), CFrame.new(p) * CFrame.Angles(0, 0, math.rad(a)), DARK, Enum.Material.Metal)
	end
	for a = 0, 315, 45 do
		local p = Vector3.new(MX + math.cos(math.rad(a)) * 5.6, coreY + math.sin(math.rad(a)) * 5.6, front - 1.25)
		part(ring, "Bolt", Vector3.new(0.6, 0.6, 0.3), CFrame.new(p), STEEL, Enum.Material.Metal)
	end
	local core = disc(m, "Core", 10, 0.4, Vector3.new(MX, coreY, front - 0.25), Vector3.new(0, 0, -1), rgb(190, 90, 255), Enum.Material.Neon)
	core:SetAttribute("Pulse", true)
	light(core, "PointLight", 45, 3, rgb(190, 110, 255)):SetAttribute("Pulse", true)
	-- a spinning swirl of homework inside the glass
	local swirl = Instance.new("Model")
	swirl.Name = "Swirl"
	swirl.Parent = m
	local hub = part(swirl, "SwirlHub", Vector3.new(0.4, 0.4, 0.4), CFrame.new(MX, coreY, front - 0.6), DEEP, nil, { Transparency = 1 })
	for i = 0, 5 do
		local a = math.rad(i * 60)
		part(swirl, "Page", Vector3.new(1.4, 1.8, 0.05), CFrame.new(MX + math.cos(a) * 2.8, coreY + math.sin(a) * 2.8, front - 0.6) * CFrame.Angles(0, 0, a), rgb(255, 255, 250))
	end
	swirl.PrimaryPart = hub
	swirl:SetAttribute("Spin", 60)
	swirl:SetAttribute("Axis", "Z")
	-- gears on both sides (the client turns them)
	for _, s in { -1, 1 } do
		local gear = Instance.new("Model")
		gear.Name = "Gear"
		gear.Parent = m
		local c = Vector3.new(MX + s * 9.8, top - 18, MZ + 1)
		local gh = disc(gear, "GearHub", 9, 1, c, Vector3.new(s, 0, 0), STEEL, Enum.Material.Metal)
		disc(gear, "GearCap", 3, 1.3, c + Vector3.new(s * 0.2, 0, 0), Vector3.new(s, 0, 0), DARK, Enum.Material.Metal)
		for a = 0, 330, 30 do
			local dir = Vector3.new(0, math.sin(math.rad(a)), math.cos(math.rad(a)))
			part(gear, "Tooth", Vector3.new(0.9, 1.6, 1.4), CFrame.lookAt(c + dir * 5, c + dir * 10), STEEL, Enum.Material.Metal)
		end
		gear.PrimaryPart = gh
		gear:SetAttribute("Spin", s * 25)
	end
	-- exhaust pipes: out of each side, up, and capped with a glowing collar
	for _, s in { -1, 1 } do
		local x = MX + s * 10.6
		part(m, "Exhaust", Vector3.new(3.2, 1.8, 1.8), CFrame.new(x - s * 0.8, top - 6, MZ + 4), STEEL, Enum.Material.Metal)
		column(m, "ExhaustUp", 1.8, 14, Vector3.new(x + s * 0.6, top + 0.5, MZ + 4), STEEL, Enum.Material.Metal)
		column(m, "ExhaustGlow", 2.3, 0.7, Vector3.new(x + s * 0.6, top + 7.2, MZ + 4), LILAC, Enum.Material.Neon)
	end
	-- the arm: a shoulder on the front corner, two segments, and a giant red pencil for a hand,
	-- reaching out over the street (the client makes it tap)
	local arm = Instance.new("Model")
	arm.Name = "Arm"
	arm.Parent = m
	local shoulderPos = Vector3.new(MX + 10.5, top - 4, front + 1)
	local shoulder = part(arm, "Shoulder", Vector3.new(4, 4, 4), CFrame.new(shoulderPos), DARK, Enum.Material.Metal, { Shape = Enum.PartType.Ball })
	local elbowPos = shoulderPos + Vector3.new(4, 5, -10)
	local wristPos = elbowPos + Vector3.new(1, -9, -9)
	local function segment(a, b, w, color)
		part(arm, "ArmSeg", Vector3.new(w, w, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), color, Enum.Material.Metal)
	end
	segment(shoulderPos, elbowPos, 2.2, PURPLE)
	part(arm, "Elbow", Vector3.new(2.8, 2.8, 2.8), CFrame.new(elbowPos), DARK, Enum.Material.Metal, { Shape = Enum.PartType.Ball })
	segment(elbowPos, wristPos, 1.8, PURPLE)
	part(arm, "Wrist", Vector3.new(2.2, 2.2, 2.2), CFrame.new(wristPos), DARK, Enum.Material.Metal, { Shape = Enum.PartType.Ball })
	-- the pencil, point down
	local pc = wristPos + Vector3.new(0, -4.5, 0)
	part(arm, "PencilBody", Vector3.new(1.6, 7, 1.6), CFrame.new(pc), rgb(230, 60, 60), Enum.Material.SmoothPlastic)
	part(arm, "PencilBand", Vector3.new(1.7, 0.8, 1.7), CFrame.new(pc + Vector3.new(0, 3.1, 0)), rgb(200, 200, 205), Enum.Material.Metal)
	part(arm, "PencilEraser", Vector3.new(1.6, 1, 1.6), CFrame.new(pc + Vector3.new(0, 4, 0)), rgb(255, 150, 170))
	part(arm, "PencilWood", Vector3.new(1.4, 1.4, 1.4), CFrame.new(pc + Vector3.new(0, -4.2, 0)) * CFrame.Angles(0, math.rad(45), math.rad(45)), rgb(240, 210, 160))
	part(arm, "PencilLead", Vector3.new(0.5, 0.8, 0.5), CFrame.new(pc + Vector3.new(0, -5.1, 0)), rgb(40, 40, 45))
	arm.PrimaryPart = shoulder
	arm:SetAttribute("Tap", true)
	-- the hopper on top where the homework goes in
	local y = top
	for i, spec in { { 16, 2.5 }, { 19, 2.5 }, { 22, 2.5 } } do
		part(m, "Hopper", Vector3.new(spec[1], spec[2], spec[1] * 0.8), CFrame.new(MX, y + spec[2] / 2, MZ), i % 2 == 1 and DARK or PURPLE, Enum.Material.Metal)
		y += spec[2]
	end
	part(m, "HopperMouth", Vector3.new(20, 0.4, 15.6), CFrame.new(MX, y + 0.1, MZ), rgb(20, 12, 28))
	-- a catwalk with a railing round the top of the housing
	for _, z in { -8.6, 8.6 } do
		part(m, "Catwalk", Vector3.new(20.4, 0.3, 1.6), CFrame.new(MX, top - 2, MZ + z), STEEL, Enum.Material.DiamondPlate)
		part(m, "Rail", Vector3.new(20.4, 0.2, 0.2), CFrame.new(MX, top - 0.6, MZ + z + (z > 0 and 0.7 or -0.7)), HAZARD, Enum.Material.Metal)
		for x = -10, 10, 2.5 do
			part(m, "RailPost", Vector3.new(0.2, 1.4, 0.2), CFrame.new(MX + x, top - 1.3, MZ + z + (z > 0 and 0.7 or -0.7)), HAZARD, Enum.Material.Metal)
		end
	end
	-- smoke from a chimney at the back
	column(m, "Chimney", 3.2, 12, Vector3.new(MX - 6, y + 6, MZ + 5), rgb(70, 66, 80), Enum.Material.Concrete)
	column(m, "ChimneyBand", 3.6, 1, Vector3.new(MX - 6, y + 9, MZ + 5), PURPLE, Enum.Material.Metal)
	local puff = part(m, "SmokeSource", Vector3.new(1, 1, 1), CFrame.new(MX - 6, y + 12.5, MZ + 5), DARK, nil, { Transparency = 1 })
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(rgb(140, 80, 200), rgb(60, 40, 80))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 20) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(6, 9)
	e.Speed = NumberRange.new(5, 8)
	e.SpreadAngle = Vector2.new(15, 15)
	e.Acceleration = Vector3.new(2, 0.5, 0)
	e.Rate = 5
	e.RotSpeed = NumberRange.new(-20, 20)
	e.Parent = puff
	-- homework pages fluttering down into the hopper
	local feed = part(m, "PageSource", Vector3.new(14, 1, 10), CFrame.new(MX, y + 14, MZ), DARK, nil, { Transparency = 1 })
	local pages = Instance.new("ParticleEmitter")
	pages.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pages.Color = ColorSequence.new(rgb(255, 255, 250))
	pages.Size = NumberSequence.new(0.6)
	pages.Lifetime = NumberRange.new(2, 3)
	pages.Speed = NumberRange.new(2, 4)
	pages.EmissionDirection = Enum.NormalId.Bottom
	pages.Rotation = NumberRange.new(0, 360)
	pages.RotSpeed = NumberRange.new(-180, 180)
	pages.Rate = 14
	pages.Parent = feed
	-- the name, on a board across the front above the core
	-- (under the catwalk, over the core: nothing in front of it)
	local board = part(m, "NameBoard", Vector3.new(26, 5, 0.6), CFrame.new(MX, top - 5.4, front - 0.4), DEEP, Enum.Material.Metal)
	sign(board, Enum.NormalId.Front, "THE HOMEWORK MACHINE", LILAC, nil, Enum.Font.LuckiestGuy, rgb(20, 8, 30))
	for _, x in { -13.3, 13.3 } do
		part(m, "BoardNeon", Vector3.new(0.4, 5.4, 0.4), CFrame.new(MX + x, top - 5.4, front - 0.6), LILAC, Enum.Material.Neon)
	end
	-- warning beacons, and two lightning rods the client arcs between
	for _, x in { -9, 9 } do
		local b = part(m, "Beacon", Vector3.new(1.2, 1.2, 1.2), CFrame.new(MX + x, top + 0.8, front - 0.2), rgb(255, 50, 60), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
		b:SetAttribute("Blink", true)
		column(m, "Rod", 0.5, 10, Vector3.new(MX + x * 0.8, y + 5, MZ - 5), STEEL, Enum.Material.Metal)
		local tip = part(m, "RodTip", Vector3.new(1, 1, 1), CFrame.new(MX + x * 0.8, y + 10.4, MZ - 5), LILAC, Enum.Material.Neon, { Shape = Enum.PartType.Ball })
		tip:SetAttribute("ArcTip", true)
	end
end

---------------------------------------------------------------------------
-- the story's over: bunting down the street, a banner on the arch
---------------------------------------------------------------------------
local BUNTING = { rgb(255, 90, 90), rgb(255, 190, 60), rgb(90, 200, 110), rgb(80, 160, 255), rgb(190, 120, 255) }
local function buildSaved(folder)
	local m = stage(folder, "Saved", 12, 99)
	-- strings of flags between neighbouring lamp posts, both sides
	for x = -200, 150, 50 do
		for _, z in { -24, 24 } do
			if (x == 0 or x == 50) and z == 24 then continue end
			local a = Vector3.new(x, 10.5, z)
			local b = Vector3.new(x + 50, 10.5, z)
			local n = 16
			for i = 1, n - 1 do
				local t = i / n
				local p = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * 2.2, 0)
				local flag = part(m, "Flag", Vector3.new(1.4, 1.4, 0.1), CFrame.new(p) * CFrame.Angles(0, 0, math.rad(45)), BUNTING[i % #BUNTING + 1])
				_ = flag
			end
			local mid = a:Lerp(b, 0.5) - Vector3.new(0, 1.2, 0)
			part(m, "String", Vector3.new(50, 0.08, 0.08), CFrame.new(mid + Vector3.new(0, 0.9, 0)), rgb(250, 250, 250))
		end
	end
	-- the arch banner (the arch sign is at x -48, y 24, 50 long)
	local banner = part(m, "SavedBanner", Vector3.new(0.3, 5, 40), CFrame.new(-49.4, 17.5, 0), rgb(255, 255, 255))
	sign(banner, Enum.NormalId.Left, "RECESS IS SAVED!", rgb(214, 44, 58), nil, Enum.Font.LuckiestGuy)
	local back = part(m, "SavedBanner", Vector3.new(0.3, 5, 40), CFrame.new(-46.6, 17.5, 0), rgb(255, 255, 255))
	sign(back, Enum.NormalId.Right, "RECESS IS SAVED!", rgb(214, 44, 58), nil, Enum.Font.LuckiestGuy)
	for _, z in { -20, 20 } do
		part(m, "BannerRope", Vector3.new(0.1, 4, 0.1), CFrame.new(-48, 22, z), rgb(240, 240, 240))
	end
end

function StreetService.start()
	local folder = ReplicatedStorage:FindFirstChild("StreetStages")
	if folder then folder:Destroy() end
	folder = Instance.new("Folder")
	folder.Name = "StreetStages"
	for _, build in { buildPosters, buildForSale, buildSearchlights, buildMachineBuild, buildMachine, buildSaved } do
		local ok, err = pcall(build, folder)
		if not ok then warn("[Street]", err) end
	end
	folder.Parent = ReplicatedStorage
end

return StreetService
