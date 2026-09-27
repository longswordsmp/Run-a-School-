-- ServerScriptService.Server.TownCloset
-- Janitor Stan's Confiscation Closet, across Recess Row from Recess Commons (x -208..-172, z -96..-70,
-- front facing the street). It replaces the plank shed baked into the place, which was a box with some
-- balls in it and nothing to do there.
-- What it is: everything VexCorp confiscates from the town's kids ends up here, and Stan (the old
-- janitor at Recess Row Elementary, and no friend of Vex's: "RECESS FOREVER! - S." in the sewer is his)
-- keeps it all safe. Confiscated Candy (from busting candy dealers) is traded at his counter for treats
-- for your school; his heist gear stall stands by the path outside (GearService).
--   outside   cream brick with a teal band, a marquee sign on the roof that lights up, a rolled-up
--             garage door you walk in through, a staff door, windows, RECESS FOREVER! painted on the
--             wall, a dumpster and recycling, planters, a bench
--   inside    shelves floor to ceiling of confiscated things (candy jars, yo-yos, comics, balls, water
--             guns, slingshots, phones, rubber ducks, consoles, robots, paper planes, skateboards), a
--             wire bin of bouncy balls, a janitor's cart, Stan's notice board, his tool pegboard, and
--             the counter: "Trade Candy" (the Shop's Candy tab)
local Kit = require(script.Parent.TownKit)

local TownCloset = {}

local rgb = Kit.rgb
local part = Kit.part
local X0, X1, Z0, Z1 = -208, -172, -96, -70 -- the building; the front wall is at Z1
local H = 14
local G = 0

local CREAM = rgb(226, 212, 184)
local TEAL = rgb(40, 150, 150)
local STEEL = rgb(150, 156, 168)
local WOOD = rgb(150, 105, 62)
local rng = Random.new(77)

local function at(x, y, z) return Vector3.new(x, G + y, z) end
local function cyl(parent, name, size, cf, color, material)
	local p = part(parent, name, size, cf, color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local function ball(parent, name, d, pos, color, material)
	local p = part(parent, name, Vector3.new(d, d, d), CFrame.new(pos), color, material)
	p.Shape = Enum.PartType.Ball
	return p
end
local function deco(p) p.CanCollide = false p.CanQuery = false p.CastShadow = false return p end
local function label(p, face, text, color, bg, font, ppu)
	local t = Kit.sign(p, face, text, color, bg, font)
	if ppu then t.Parent.PixelsPerStud = ppu end
	return t
end

---------------------------------------------------------------------------
-- confiscated things: each takes the CFrame of a spot on a shelf (its bottom centre)
---------------------------------------------------------------------------
local BRIGHT = { rgb(230, 70, 60), rgb(250, 150, 40), rgb(255, 205, 50), rgb(80, 190, 90), rgb(60, 140, 235), rgb(150, 90, 220), rgb(255, 110, 180) }
local function bright() return BRIGHT[rng:NextInteger(1, #BRIGHT)] end
local ITEMS = {
	function(m, cf) -- a jar of candy
		local jar = deco(cyl(m, "CandyJar", Vector3.new(1.3, 1, 1), cf * CFrame.new(0, 0.65, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(220, 240, 255), Enum.Material.Glass))
		jar.Transparency = 0.55
		for k = 1, 5 do deco(ball(m, "Candy", 0.32, (cf * CFrame.new(rng:NextNumber(-0.25, 0.25), 0.25 + k * 0.17, rng:NextNumber(-0.25, 0.25))).Position, bright())) end
		deco(cyl(m, "JarLid", Vector3.new(0.18, 1.05, 1.05), cf * CFrame.new(0, 1.38, 0) * CFrame.Angles(0, 0, math.rad(90)), bright(), Enum.Material.SmoothPlastic))
		return 1.3
	end,
	function(m, cf) -- yo-yos
		for k = 0, 1 do
			local c = bright()
			local p = cf * CFrame.new(-0.35 + k * 0.7, 0.4, 0)
			deco(cyl(m, "YoYo", Vector3.new(0.18, 0.8, 0.8), p * CFrame.new(-0.1, 0, 0), c))
			deco(cyl(m, "YoYo", Vector3.new(0.18, 0.8, 0.8), p * CFrame.new(0.1, 0, 0), c))
		end
		return 1.5
	end,
	function(m, cf) -- a stack of comics
		for k = 0, 3 do
			deco(part(m, "Comic", Vector3.new(1.1, 0.12, 1.5), cf * CFrame.new(0, 0.07 + k * 0.13, 0) * CFrame.Angles(0, math.rad(rng:NextNumber(-12, 12)), 0), bright()))
		end
		return 1.6
	end,
	function(m, cf) -- a ball
		local kinds = { rgb(240, 120, 40), rgb(245, 245, 245), rgb(230, 70, 60), rgb(60, 140, 235) }
		deco(ball(m, "Ball", 1.1, (cf * CFrame.new(0, 0.56, 0)).Position, kinds[rng:NextInteger(1, #kinds)], Enum.Material.SmoothPlastic))
		return 1.3
	end,
	function(m, cf) -- a water gun
		local c = bright()
		deco(part(m, "WaterGun", Vector3.new(0.5, 0.55, 1.4), cf * CFrame.new(0, 0.55, 0), c))
		deco(cyl(m, "WaterGunBarrel", Vector3.new(0.9, 0.22, 0.22), cf * CFrame.new(0, 0.65, -1.05) * CFrame.Angles(0, math.rad(90), 0), rgb(255, 205, 50)))
		deco(part(m, "WaterGunGrip", Vector3.new(0.35, 0.5, 0.35), cf * CFrame.new(0, 0.25, 0.35), c))
		deco(ball(m, "WaterGunTank", 0.55, (cf * CFrame.new(0, 1, 0.1)).Position, rgb(120, 200, 255), Enum.Material.Glass)).Transparency = 0.3
		return 1.2
	end,
	function(m, cf) -- a slingshot, lying down
		deco(part(m, "Slingshot", Vector3.new(0.2, 0.18, 0.8), cf * CFrame.new(0, 0.1, 0.3), WOOD, Enum.Material.Wood))
		for _, s in { -1, 1 } do
			deco(part(m, "Slingshot", Vector3.new(0.18, 0.18, 0.7), cf * CFrame.new(s * 0.2, 0.1, -0.35) * CFrame.Angles(0, math.rad(s * 25), 0), WOOD, Enum.Material.Wood))
		end
		deco(part(m, "SlingBand", Vector3.new(0.7, 0.06, 0.06), cf * CFrame.new(0, 0.14, -0.66), rgb(230, 70, 60)))
		return 1
	end,
	function(m, cf) -- a phone, propped up, screen lit
		deco(part(m, "Phone", Vector3.new(0.6, 1.1, 0.12), cf * CFrame.new(0, 0.55, 0) * CFrame.Angles(math.rad(-12), 0, 0), rgb(30, 30, 36)))
		deco(part(m, "PhoneScreen", Vector3.new(0.5, 0.95, 0.05), cf * CFrame.new(0, 0.56, -0.07) * CFrame.Angles(math.rad(-12), 0, 0), rgb(110, 200, 255), Enum.Material.Neon))
		return 0.9
	end,
	function(m, cf) -- a rubber duck
		local y = rgb(255, 215, 50)
		deco(ball(m, "Duck", 0.8, (cf * CFrame.new(0, 0.4, 0)).Position, y))
		deco(ball(m, "DuckHead", 0.5, (cf * CFrame.new(0, 0.85, -0.25)).Position, y))
		deco(part(m, "DuckBeak", Vector3.new(0.3, 0.12, 0.25), cf * CFrame.new(0, 0.82, -0.55), rgb(250, 140, 40)))
		return 1
	end,
	function(m, cf) -- a games console and its pad
		deco(part(m, "Console", Vector3.new(1.4, 0.35, 1), cf * CFrame.new(0, 0.18, 0), rgb(40, 40, 46)))
		deco(part(m, "ConsoleLight", Vector3.new(0.3, 0.05, 0.05), cf * CFrame.new(0.4, 0.2, -0.52), rgb(80, 255, 120), Enum.Material.Neon))
		deco(part(m, "Gamepad", Vector3.new(0.8, 0.2, 0.45), cf * CFrame.new(0, 0.45, 0.1) * CFrame.Angles(0, math.rad(15), 0), rgb(220, 220, 228)))
		return 1.6
	end,
	function(m, cf) -- a toy robot
		local c = bright()
		deco(part(m, "Robot", Vector3.new(0.6, 0.7, 0.45), cf * CFrame.new(0, 0.75, 0), c))
		deco(part(m, "RobotHead", Vector3.new(0.45, 0.4, 0.4), cf * CFrame.new(0, 1.3, 0), STEEL, Enum.Material.Metal))
		for _, s in { -1, 1 } do
			deco(part(m, "RobotLeg", Vector3.new(0.2, 0.4, 0.25), cf * CFrame.new(s * 0.16, 0.2, 0), STEEL, Enum.Material.Metal))
			deco(ball(m, "RobotEye", 0.1, (cf * CFrame.new(s * 0.1, 1.33, -0.21)).Position, rgb(255, 60, 60), Enum.Material.Neon))
		end
		return 1
	end,
	function(m, cf) -- a paper aeroplane
		local w = Instance.new("WedgePart")
		w.Name = "PaperPlane"
		w.Size = Vector3.new(1, 0.3, 1.4)
		w.CFrame = cf * CFrame.new(0, 0.15, 0)
		w.Color = rgb(250, 250, 250)
		w.Anchored = true
		w.Parent = m
		deco(w)
		return 1.2
	end,
}

-- one shelving unit: `w` wide, uprights and five shelves, loaded; cf: its front bottom centre, facing -Z
local function shelves(parent, cf, w, levels)
	local m = Instance.new("Model")
	m.Name = "Shelves"
	m.Parent = parent
	local d, h = 1.8, 11
	for _, s in { -1, 1 } do
		for _, dz in { 0, d } do
			part(m, "Upright", Vector3.new(0.25, h, 0.25), cf * CFrame.new(s * (w / 2 - 0.12), h / 2, dz - 0.12 + (dz > 0 and -0.12 or 0.24)), STEEL, Enum.Material.Metal)
		end
	end
	part(m, "Back", Vector3.new(w, h, 0.15), cf * CFrame.new(0, h / 2, d - 0.05), rgb(120, 126, 138), Enum.Material.DiamondPlate)
	for k = 0, levels - 1 do
		local y = 0.4 + k * (h - 1) / (levels - 1)
		local shelf = part(m, "Shelf", Vector3.new(w, 0.18, d), cf * CFrame.new(0, y, d / 2), STEEL, Enum.Material.Metal)
		-- load it: things side by side till the shelf is full (the top shelf a little emptier)
		local x = -w / 2 + 0.4
		while x < w / 2 - 0.6 do
			local spot = shelf.CFrame * CFrame.new(0, 0.09, 0) * CFrame.new(x + 0.7, 0, rng:NextNumber(-0.15, 0.15)) * CFrame.Angles(0, math.rad(rng:NextNumber(-20, 20)), 0)
			if k == levels - 1 and rng:NextNumber() < 0.35 then
				x += 1.2
			else
				local build = ITEMS[rng:NextInteger(1, #ITEMS)]
				local used = build(m, spot)
				x += used + 0.15
			end
		end
	end
	return m
end

---------------------------------------------------------------------------
local function buildShell(c)
	local front = Z1
	-- floor, apron and the path in from the street
	part(c, "Floor", Vector3.new(X1 - X0 - 1, 0.3, Z1 - Z0 - 1), CFrame.new(at((X0 + X1) / 2, 0.15, (Z0 + Z1) / 2)), rgb(170, 172, 176), Enum.Material.Concrete)
	part(c, "Apron", Vector3.new(20, 0.3, 8), CFrame.new(at(-190, 0.15, front + 4)), rgb(180, 180, 186), Enum.Material.Concrete)
	part(c, "PathIn", Vector3.new(7, 0.3, 32), CFrame.new(at(-190, 0.15, -46)), rgb(210, 210, 216), Enum.Material.Concrete)
	-- the walls: back, sides, and the front in pieces round the garage opening and the staff door
	local function wall(name, size, pos) return part(c, name, size, CFrame.new(pos), CREAM, Enum.Material.Brick) end
	wall("BackWall", Vector3.new(X1 - X0, H, 1), at((X0 + X1) / 2, H / 2, Z0 + 0.5))
	wall("SideWall", Vector3.new(1, H, Z1 - Z0), at(X0 + 0.5, H / 2, (Z0 + Z1) / 2))
	wall("SideWall", Vector3.new(1, H, Z1 - Z0), at(X1 - 0.5, H / 2, (Z0 + Z1) / 2))
	local gx0, gx1, gh = -196, -184, 10 -- the garage opening
	wall("FrontWall", Vector3.new(gx0 - X0, H, 1), at((X0 + gx0) / 2, H / 2, front - 0.5))
	wall("FrontWall", Vector3.new(gx1 - gx0, H - gh, 1), at((gx0 + gx1) / 2, gh + (H - gh) / 2, front - 0.5))
	local dx0, dx1, dh = -182, -178, 8 -- the staff door
	wall("FrontWall", Vector3.new(dx0 - gx1, H, 1), at((gx1 + dx0) / 2, H / 2, front - 0.5))
	wall("FrontWall", Vector3.new(dx1 - dx0, H - dh, 1), at((dx0 + dx1) / 2, dh + (H - dh) / 2, front - 0.5))
	wall("FrontWall", Vector3.new(X1 - dx1, H, 1), at((dx1 + X1) / 2, H / 2, front - 0.5))
	-- the teal band round the top, a parapet, and the roof
	-- (each band sits in its wall and stands 0.4 proud of the outside face, never through the inside)
	part(c, "Band", Vector3.new(X1 - X0 + 0.8, 1.2, 1.2), CFrame.new(at((X0 + X1) / 2, H - 1.6, front - 0.2)), TEAL, Enum.Material.SmoothPlastic)
	part(c, "Band", Vector3.new(X1 - X0 + 0.8, 1.2, 1.2), CFrame.new(at((X0 + X1) / 2, H - 1.6, Z0 + 0.2)), TEAL, Enum.Material.SmoothPlastic)
	for _, x in { X0 + 0.2, X1 - 0.2 } do
		part(c, "Band", Vector3.new(1.2, 1.2, Z1 - Z0), CFrame.new(at(x, H - 1.6, (Z0 + Z1) / 2)), TEAL, Enum.Material.SmoothPlastic)
	end
	part(c, "Roof", Vector3.new(X1 - X0, 0.8, Z1 - Z0), CFrame.new(at((X0 + X1) / 2, H + 0.4, (Z0 + Z1) / 2)), rgb(110, 112, 120), Enum.Material.Concrete)
	for _, spec in { { (X0 + X1) / 2, front - 0.5, X1 - X0, 1 }, { (X0 + X1) / 2, Z0 + 0.5, X1 - X0, 1 } } do
		part(c, "Parapet", Vector3.new(spec[3], 1.4, spec[4]), CFrame.new(at(spec[1], H + 1.5, spec[2])), CREAM, Enum.Material.Brick)
	end
	for _, x in { X0 + 0.5, X1 - 0.5 } do
		part(c, "Parapet", Vector3.new(1, 1.4, Z1 - Z0), CFrame.new(at(x, H + 1.5, (Z0 + Z1) / 2)), CREAM, Enum.Material.Brick)
	end
	-- on the roof: a boxy air-conditioner and a vent pipe
	part(c, "AirCon", Vector3.new(4, 2.4, 3), CFrame.new(at(-200, H + 2, -86)), rgb(190, 192, 198), Enum.Material.Metal)
	cyl(c, "Vent", Vector3.new(3, 1.2, 1.2), CFrame.new(at(-178, H + 2.3, -88)) * CFrame.Angles(0, 0, math.rad(90)), STEEL, Enum.Material.Metal)

	-- the rolled-up garage door: the roll in its housing over the opening, the guide rails
	part(c, "DoorHousing", Vector3.new(gx1 - gx0 + 0.8, 1.6, 1.6), CFrame.new(at((gx0 + gx1) / 2, gh + 0.8, front - 1.4)), rgb(120, 126, 138), Enum.Material.Metal)
	for _, x in { gx0 + 0.2, gx1 - 0.2 } do
		part(c, "DoorRail", Vector3.new(0.3, gh, 0.4), CFrame.new(at(x, gh / 2, front - 1.2)), rgb(120, 126, 138), Enum.Material.Metal)
	end
	part(c, "DoorEdge", Vector3.new(gx1 - gx0 - 0.4, 0.5, 0.25), CFrame.new(at((gx0 + gx1) / 2, gh - 0.2, front - 1.2)), rgb(200, 205, 215), Enum.Material.DiamondPlate)
	part(c, "Threshold", Vector3.new(gx1 - gx0, 0.06, 0.7), CFrame.new(at((gx0 + gx1) / 2, 0.33, front - 0.5)), rgb(255, 205, 50))
	-- the staff door, shut, and its sign
	part(c, "StaffDoor", Vector3.new(dx1 - dx0 - 0.2, dh - 0.1, 0.3), CFrame.new(at((dx0 + dx1) / 2, dh / 2, front - 0.5)), TEAL, Enum.Material.Metal)
	ball(c, "DoorKnob", 0.3, at(dx0 + 0.6, 3.6, front - 0.3), STEEL, Enum.Material.Metal)
	local staff = part(c, "StaffSign", Vector3.new(2.6, 1, 0.1), CFrame.new(at((dx0 + dx1) / 2, 6.3, front - 0.3)), rgb(250, 250, 250))
	label(staff, Enum.NormalId.Back, "STAFF ONLY\n(Stan)", rgb(40, 40, 50), nil, Enum.Font.GothamBold)
	-- windows on the wall face: dark glass with a white blind half down, a teal frame and a sill
	for _, x in { -202, -173.8 } do
		part(c, "Window", Vector3.new(4.2, 4, 0.1), CFrame.new(at(x, 6, front + 0.05)), rgb(60, 90, 120), Enum.Material.Glass, { Reflectance = 0.2 })
		part(c, "Blind", Vector3.new(4, 1.7, 0.05), CFrame.new(at(x, 7.05, front + 0.12)), rgb(240, 235, 220))
		for k = 0, 3 do part(c, "BlindSlat", Vector3.new(4, 0.06, 0.06), CFrame.new(at(x, 6.4 + k * 0.42, front + 0.16)), rgb(210, 205, 190)) end
		part(c, "WindowFrame", Vector3.new(4.8, 0.3, 0.3), CFrame.new(at(x, 8.15, front + 0.15)), TEAL)
		part(c, "WindowFrame", Vector3.new(0.3, 4.3, 0.3), CFrame.new(at(x - 2.25, 6, front + 0.15)), TEAL)
		part(c, "WindowFrame", Vector3.new(0.3, 4.3, 0.3), CFrame.new(at(x + 2.25, 6, front + 0.15)), TEAL)
		part(c, "WindowFrame", Vector3.new(0.2, 4, 0.25), CFrame.new(at(x, 6, front + 0.15)), TEAL)
		part(c, "Sill", Vector3.new(5.2, 0.35, 0.8), CFrame.new(at(x, 3.8, front + 0.35)), rgb(240, 240, 240), Enum.Material.Concrete)
	end
	-- RECESS FOREVER! sprayed on the wall left of the garage (the same hand as in the sewer)
	local mural = part(c, "Mural", Vector3.new(10, 2.6, 0.05), CFrame.new(at(-202, 10.3, front + 0.03)), CREAM, nil, { Transparency = 1, CanCollide = false })
	local t = label(mural, Enum.NormalId.Back, "RECESS FOREVER!", rgb(255, 255, 255), nil, Enum.Font.PermanentMarker)
	t.TextColor3 = rgb(255, 255, 255)
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(255, 90, 160)), ColorSequenceKeypoint.new(0.5, rgb(255, 205, 50)), ColorSequenceKeypoint.new(1, rgb(60, 180, 235)) })
	grad.Parent = t
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = rgb(40, 30, 60)
	stroke.Parent = t

	-- the marquee on the roof: CONFISCATION CLOSET on a board ringed with bulbs
	local mx, my, mw, mh = -190, H + 4.6, 26, 4.2
	for _, x in { mx - mw / 2 + 1, mx + mw / 2 - 1 } do
		part(c, "MarqueeLeg", Vector3.new(0.5, 3.2, 0.5), CFrame.new(at(x, H + 1.6, front - 1.4)), STEEL, Enum.Material.Metal)
	end
	local board = part(c, "Marquee", Vector3.new(mw, mh, 0.6), CFrame.new(at(mx, my, front - 1.4)), rgb(40, 60, 90))
	local mt = label(board, Enum.NormalId.Back, "CONFISCATION CLOSET", rgb(255, 255, 255), nil, Enum.Font.LuckiestGuy)
	local ms = Instance.new("UIStroke")
	ms.Thickness = 3
	ms.Color = rgb(255, 110, 180)
	ms.Parent = mt
	for k = 0, 25 do
		local x = mx - mw / 2 + 0.5 + k * (mw - 1) / 25
		ball(c, "Bulb", 0.4, at(x, my + mh / 2 - 0.2, front - 1.05), rgb(255, 235, 170), Enum.Material.Neon)
		ball(c, "Bulb", 0.4, at(x, my - mh / 2 + 0.2, front - 1.05), rgb(255, 235, 170), Enum.Material.Neon)
	end
	local glow = part(c, "MarqueeGlow", Vector3.new(1, 1, 1), CFrame.new(at(mx, my, front + 1)), rgb(0, 0, 0), nil, { Transparency = 1, CanCollide = false })
	Kit.light(glow, 20, 1.4, rgb(255, 225, 180))
	-- the LOST & FOUND sign hanging over the garage
	-- (on the wall between the top of the opening and the teal band)
	local lf = part(c, "LostFound", Vector3.new(6, 1.3, 0.2), CFrame.new(at(-190, 10.95, front + 0.2)), rgb(255, 205, 50))
	label(lf, Enum.NormalId.Back, "LOST & FOUND", rgb(40, 40, 50), nil, Enum.Font.FredokaOne)
	label(lf, Enum.NormalId.Front, "LOST & FOUND", rgb(40, 40, 50), nil, Enum.Font.FredokaOne)

	-- outside: the dumpster, recycling, planters, a bench, trees behind
	part(c, "Dumpster", Vector3.new(6, 4, 3.4), CFrame.new(at(-213, 2.2, -88)), rgb(50, 110, 70), Enum.Material.Metal)
	part(c, "DumpsterLid", Vector3.new(6.2, 0.3, 3.6), CFrame.new(at(-213, 4.35, -88.4)) * CFrame.Angles(math.rad(-12), 0, 0), rgb(40, 40, 46), Enum.Material.Plastic)
	for i, col in { rgb(60, 120, 220), rgb(80, 170, 90) } do
		cyl(c, "RecycleBin", Vector3.new(3, 2, 2), CFrame.new(at(-213, 1.5, -81 + i * 2.6)) * CFrame.Angles(0, 0, math.rad(90)), col, Enum.Material.Plastic)
	end
	for _, x in { -198.5, -170 } do
		part(c, "Planter", Vector3.new(3, 1.6, 2), CFrame.new(at(x, 0.8, front + 1.6)), rgb(120, 90, 70), Enum.Material.WoodPlanks)
		for k = 0, 3 do ball(c, "Flower", 0.7, at(x - 1 + k * 0.7, 1.9, front + 1.6), BRIGHT[k + 1]) end
	end
	Kit.bench(c, -166, -64, "+z")
	for _, x in { -214, -166 } do Kit.tree(c, x, -104, 1.1) end
end

local function buildInside(c)
	local front = Z1
	-- ceiling and strip lights
	part(c, "Ceiling", Vector3.new(X1 - X0 - 2, 0.3, Z1 - Z0 - 2), CFrame.new(at((X0 + X1) / 2, H - 0.3, (Z0 + Z1) / 2)), rgb(200, 202, 206), Enum.Material.Concrete)
	for _, x in { -198, -184 } do
		local strip = part(c, "CeilingLight", Vector3.new(0.8, 0.15, 14), CFrame.new(at(x, H - 0.5, -83)), rgb(255, 244, 220), Enum.Material.Neon)
		Kit.light(strip, 20, 0.55, rgb(255, 240, 215))
	end
	-- shelves: three along the back wall, two down the left wall
	for _, x in { -201.5, -190, -178.5 } do
		shelves(c, CFrame.new(at(x, 0.3, Z0 + 3)) * CFrame.Angles(0, math.rad(180), 0), 10, 5)
	end
	-- (turned -90: the unit's back, its +Z, against the wall at -X; its front faces into the room)
	for _, z in { -88.5, -80.5 } do
		shelves(c, CFrame.new(at(X0 + 3, 0.3, z)) * CFrame.Angles(0, math.rad(-90), 0), 7, 5)
	end
	-- skateboards leaning on the shelves
	for k = 0, 2 do
		local x = -196 + k * 1.2
		part(c, "Skateboard", Vector3.new(0.9, 3, 0.15), CFrame.new(at(x, 1.6, Z0 + 3.3)) * CFrame.Angles(math.rad(-15), 0, math.rad(k * 4)), BRIGHT[k + 3])
	end
	-- the wire bin of bouncy balls, stamped CONFISCATED, and a crate stack
	local binPos = at(-194, 0, -80)
	for _, s in { -1, 1 } do
		part(c, "BinSide", Vector3.new(0.2, 3, 5), CFrame.new(binPos + Vector3.new(s * 2.5, 1.5, 0)), STEEL, Enum.Material.DiamondPlate)
		part(c, "BinSide", Vector3.new(5, 3, 0.2), CFrame.new(binPos + Vector3.new(0, 1.5, s * 2.5)), STEEL, Enum.Material.DiamondPlate)
	end
	for k = 1, 34 do
		deco(ball(c, "BouncyBall", 0.9, binPos + Vector3.new(rng:NextNumber(-1.9, 1.9), 0.5 + rng:NextNumber(0, 2.4), rng:NextNumber(-1.9, 1.9)), bright(), Enum.Material.SmoothPlastic))
	end
	local stamp = part(c, "BinLabel", Vector3.new(3.4, 0.9, 0.05), CFrame.new(binPos + Vector3.new(0, 2.1, 2.62)), rgb(250, 250, 245))
	label(stamp, Enum.NormalId.Back, "CONFISCATED", rgb(210, 40, 40), nil, Enum.Font.SpecialElite)
	-- (the crates are out by the dumpster, waiting to come in)
	for k, spec in { { -214, -95, 0 }, { -214, -95, 1 }, { -211.4, -95, 0 } } do
		local crate = part(c, "Crate", Vector3.new(2.4, 2.4, 2.4), CFrame.new(at(spec[1], 1.2 + spec[3] * 2.4, spec[2])) * CFrame.Angles(0, math.rad(k * 7), 0), WOOD, Enum.Material.WoodPlanks)
		label(crate, Enum.NormalId.Back, "CONFISCATED", rgb(210, 40, 40), nil, Enum.Font.SpecialElite)
	end
	-- the janitor's cart: a mop bucket, a mop, a bin bag, spray bottles
	local cart = at(-199, 0, -76)
	part(c, "CartBase", Vector3.new(3.4, 0.4, 2), CFrame.new(cart + Vector3.new(0, 0.9, 0)), rgb(250, 205, 50), Enum.Material.Plastic)
	part(c, "CartShelf", Vector3.new(3.4, 0.3, 2), CFrame.new(cart + Vector3.new(0, 2.6, 0)), rgb(250, 205, 50), Enum.Material.Plastic)
	for _, dx in { -1.6, 1.6 } do part(c, "CartPost", Vector3.new(0.2, 2, 0.2), CFrame.new(cart + Vector3.new(dx, 1.8, 0)), STEEL, Enum.Material.Metal) end
	cyl(c, "MopBucket", Vector3.new(1.3, 1.5, 1.5), CFrame.new(cart + Vector3.new(-0.8, 1.75, 0)) * CFrame.Angles(0, 0, math.rad(90)), rgb(60, 140, 235), Enum.Material.Plastic)
	part(c, "MopHandle", Vector3.new(0.18, 5, 0.18), CFrame.new(cart + Vector3.new(-0.9, 3.6, 0.2)) * CFrame.Angles(math.rad(8), 0, math.rad(-6)), WOOD, Enum.Material.Wood)
	ball(c, "BinBag", 1.6, cart + Vector3.new(0.9, 3.4, 0), rgb(40, 40, 44), Enum.Material.Plastic)
	for k = 0, 1 do
		part(c, "SprayBottle", Vector3.new(0.35, 0.9, 0.35), CFrame.new(cart + Vector3.new(0.6 + k * 0.5, 1.55, 0.5)), k == 0 and rgb(80, 200, 255) or rgb(255, 120, 180), Enum.Material.Plastic)
	end
	-- Stan's notice board by the way in
	local board = part(c, "NoticeBoard", Vector3.new(0.2, 4, 5), CFrame.new(at(X0 + 1.1, 6, -74)), rgb(190, 140, 90), Enum.Material.Fabric)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Right
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0.3
	gui.Parent = board
	local notes = {
		{ "Everything VexCorp takes from a kid ends up in here. I keep it safe. Come and get it back.\n- Stan", rgb(255, 250, 200), UDim2.fromScale(0.04, 0.06), UDim2.fromScale(0.5, 0.52), -3 },
		{ "Busted a candy dealer? Bring me the candy. I'll trade you something nice for your school.", rgb(200, 240, 255), UDim2.fromScale(0.56, 0.08), UDim2.fromScale(0.4, 0.44), 4 },
		{ "RECESS FOREVER!", rgb(255, 200, 225), UDim2.fromScale(0.08, 0.64), UDim2.fromScale(0.5, 0.3), -6 },
		{ "Lost: 1 hamster. Answers to Professor.", rgb(220, 255, 210), UDim2.fromScale(0.6, 0.6), UDim2.fromScale(0.36, 0.34), 5 },
	}
	for _, n in notes do
		local note = Instance.new("TextLabel")
		note.BackgroundColor3 = n[2]
		note.Position = n[3]
		note.Size = n[4]
		note.Rotation = n[5]
		note.Font = Enum.Font.PermanentMarker
		note.TextScaled = true
		note.TextColor3 = rgb(40, 40, 50)
		note.Text = n[1]
		note.Parent = gui
	end

	-- the counter (along the right side), the till, and Stan's tool pegboard behind it
	local cz0, cz1, cx = -88, -74, -177
	part(c, "Counter", Vector3.new(2.2, 3.4, cz1 - cz0), CFrame.new(at(cx, 1.7, (cz0 + cz1) / 2)), TEAL, Enum.Material.WoodPlanks)
	part(c, "CounterTop", Vector3.new(2.8, 0.3, cz1 - cz0 + 0.4), CFrame.new(at(cx, 3.55, (cz0 + cz1) / 2)), rgb(90, 70, 50), Enum.Material.Wood)
	part(c, "CounterEnd", Vector3.new(4, 3.4, 2.2), CFrame.new(at(cx + 1.9, 1.7, cz1 + 1.1)), TEAL, Enum.Material.WoodPlanks)
	local till = part(c, "Till", Vector3.new(1.4, 1, 1.4), CFrame.new(at(cx, 4.2, -79)), rgb(60, 60, 68), Enum.Material.Metal)
	part(c, "TillScreen", Vector3.new(0.1, 0.6, 1), CFrame.new(at(cx - 0.72, 4.5, -79)), rgb(120, 255, 160), Enum.Material.Neon)
	_ = till
	for k = 0, 3 do
		local jar = deco(cyl(c, "CounterJar", Vector3.new(1.2, 0.9, 0.9), CFrame.new(at(cx, 4.3, -86 + k * 1.2)) * CFrame.Angles(0, 0, math.rad(90)), rgb(220, 240, 255), Enum.Material.Glass))
		jar.Transparency = 0.5
		for j = 1, 4 do deco(ball(c, "Candy", 0.3, at(cx + rng:NextNumber(-0.2, 0.2), 3.9 + j * 0.17, -86 + k * 1.2 + rng:NextNumber(-0.2, 0.2)), BRIGHT[(k + j) % #BRIGHT + 1])) end
	end
	local peg = part(c, "Pegboard", Vector3.new(0.2, 5, 10), CFrame.new(at(X1 - 1.2, 6.5, -81)), rgb(200, 170, 120), Enum.Material.Wood)
	_ = peg
	for k, tool in { { "Broom", rgb(230, 190, 90) }, { "Wrench", STEEL }, { "Plunger", rgb(230, 70, 60) }, { "Hammer", WOOD }, { "Spanner", STEEL } } do
		local z = -85 + k * 1.6
		part(c, tool[1], Vector3.new(0.2, 3.2, 0.3), CFrame.new(at(X1 - 1.45, 6.3, z)) * CFrame.Angles(math.rad(10), 0, 0), tool[2], Enum.Material.Metal)
	end
	-- (behind the counter, where Stan would stand) and the prompt: trade your candy
	local spot = part(c, "TradeSpot", Vector3.new(1, 1, 1), CFrame.new(at(cx - 1.8, 3, -80)), rgb(0, 0, 0), nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TradePrompt"
	prompt.ActionText = "Trade Candy"
	prompt.ObjectText = "Janitor Stan's Closet"
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Color", rgb(255, 120, 190))
	prompt.Parent = spot
	prompt.Triggered:Connect(function(player)
		local Remotes = require(script.Parent.Remotes)
		Remotes.Push:FireClient(player, "openPanel", { name = "Shop", tab = TownCloset.CANDY_TAB })
	end)
	-- a sign on the counter
	local cs = part(c, "CounterSign", Vector3.new(0.1, 1.2, 3.6), CFrame.new(at(cx - 1.12, 2.6, -81)), rgb(255, 250, 235))
	label(cs, Enum.NormalId.Left, "CANDY IN,\nTREATS OUT", rgb(210, 40, 90), nil, Enum.Font.FredokaOne)
	-- where Stan stands when he isn't mopping: out front by the garage
	part(c, "NPCSpot", Vector3.new(1, 1, 1), CFrame.new(at(-184, 0.6, front + 6)) * CFrame.Angles(0, math.rad(180), 0), rgb(255, 255, 255), nil, { Transparency = 1, CanCollide = false, CanQuery = false })
end

TownCloset.CANDY_TAB = 4 -- (the Shop panel's Candy page)

function TownCloset.build()
	local map = workspace:FindFirstChild("Map")
	local lm = map and map:FindFirstChild("Landmarks")
	if not lm then return end
	local ground = map:FindFirstChild("Ground")
	if ground then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { ground }
		local hit = workspace:Raycast(Vector3.new(-190, 60, -83), Vector3.new(0, -120, 0), params)
		if hit then G = hit.Position.Y end
	end
	local old = lm:FindFirstChild("ConfiscationCloset")
	if old then old:Destroy() end
	for _, p in lm:GetChildren() do
		if p.Name == "Path" and p:IsA("BasePart") and math.abs(p.Position.X + 190) < 2 and p.Position.Z < -26 and p.Position.Z > -66 then p:Destroy() end
	end
	local c = Instance.new("Model")
	c.Name = "ConfiscationCloset"
	c:SetAttribute("MapAt", Vector3.new(-190, G, (Z0 + Z1) / 2))
	buildShell(c)
	buildInside(c)
	c.Parent = lm
end

return TownCloset
