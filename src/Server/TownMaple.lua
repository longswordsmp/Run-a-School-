-- ServerScriptService.Server.TownMaple
-- Maple Heights (docs/TOWN.md): the neighbourhood north of the school area, through the MAPLE
-- HEIGHTS gate. The road runs north along x = 0; Maple Lane (z = 330) and Oak Avenue (z = 450) cross
-- it. 26 houses in pastel colours (porches, garages, chimneys, picket fences, mailboxes with the
-- family's name), the Maple Heights Clinic, the fire station, a corner playground and a community
-- garden. A few houses belong to the townspeople the quests send you to (Grandma Rose's pink
-- cottage, Coach Doug's hoop, Skye's skate ramp, Old Man Grumbles' hedge, Lil' Timmy's treehouse).
local Maple = {}

-- who lives where (x, the street, the side): the mailbox name and a few extras
local HOUSES = {
	-- Maple Lane, south side (facing +z)
	{ x = -360, z = 292, face = "+z", name = "THE PATELS", extra = "patels" },
	{ x = -270, z = 292, face = "+z", name = "GRANDMA ROSE", extra = "rose" },
	{ x = -180, z = 292, face = "+z", name = "THE BAKERS" },
	{ x = -90, z = 292, face = "+z", name = "THE LOPEZES" },
	{ x = 90, z = 292, face = "+z", name = "COACH DOUG", extra = "hoop" },
	{ x = 180, z = 292, face = "+z", name = "THE NGUYENS" },
	{ x = 270, z = 292, face = "+z", name = "THE SMITHS" },
	{ x = 360, z = 292, face = "+z", name = "THE OKAFORS" },
	-- Maple Lane, north side (facing -z)
	{ x = -360, z = 368, face = "-z", name = "THE MILLERS" },
	{ x = -270, z = 368, face = "-z", name = "LIL' TIMMY", extra = "treehouse" },
	{ x = -180, z = 368, face = "-z", name = "THE GARCIAS" },
	{ x = 180, z = 368, face = "-z", name = "THE WONGS" },
	{ x = 270, z = 368, face = "-z", name = "SKYE", extra = "ramp" },
	{ x = 360, z = 368, face = "-z", name = "THE JOHNSONS" },
	-- Oak Avenue, south side (facing +z)
	{ x = -360, z = 412, face = "+z", name = "THE KIMS", extra = "garden" },
	{ x = -270, z = 412, face = "+z", name = "THE BROWNS" },
	{ x = -180, z = 412, face = "+z", name = "THE SATOS" },
	{ x = -90, z = 412, face = "+z", name = "THE ROSSIS" },
	{ x = 90, z = 412, face = "+z", name = "OLD MAN GRUMBLES", extra = "grumbles" },
	{ x = 180, z = 412, face = "+z", name = "THE HALLS" },
	{ x = 270, z = 412, face = "+z", name = "THE COHENS" },
	{ x = 360, z = 412, face = "+z", name = "THE DIAZES" },
	-- Oak Avenue, north side (facing -z)
	{ x = -360, z = 488, face = "-z", name = "THE WHITES" },
	{ x = -270, z = 488, face = "-z", name = "THE YOUNGS" },
	{ x = 270, z = 488, face = "-z", name = "THE ADAMSES" },
	{ x = 360, z = 488, face = "-z", name = "THE SILVAS" },
}

function Maple.build(town, Kit)
	local rgb = Kit.rgb
	local part, C = Kit.part, Kit.C
	local m = Kit.folder(town, "MapleHeights")
	local rng = Random.new(42)

	-- streets
	local streets = Kit.folder(m, "Streets")
	Kit.road(streets, 0, 270, 0, 510, 20, { sidewalk = 6 })
	for _, z in { 330, 450 } do
		Kit.road(streets, -410, z, -10, z, 20, { sidewalk = 6 })
		Kit.road(streets, 10, z, 410, z, 20, { sidewalk = 6 })
		Kit.pave(streets, -10, 10, z - 10, z + 10, C.asphalt, Enum.Material.Asphalt, 0.13)
		Kit.crosswalk(streets, 0, z - 14, 20, true)
		Kit.crosswalk(streets, 0, z + 14, 20, true)
		-- (the ends of the lanes: a turning circle each side)
		for _, sx in { -1, 1 } do
			Kit.cylY(streets, "CulDeSac", 28, 0.3, Vector3.new(sx * 410, 0.12, z), C.asphalt, Enum.Material.Asphalt)
			Kit.cylY(streets, "CulDeSacIsland", 8, 0.8, Vector3.new(sx * 410, 0.4, z), rgb(96, 186, 78), Enum.Material.Grass)
			Kit.tree(streets, sx * 410, z, 0.8)
		end
	end
	for z = 290, 500, 40 do
		Kit.lamp(streets, -14, z, 10)
		Kit.lamp(streets, 14, z, 10)
	end
	for x = -380, 380, 60 do
		if math.abs(x) > 30 then
			for _, z in { 330, 450 } do
				Kit.lamp(streets, x, z - 14, 10)
			end
		end
	end

	-- a house: walls, a gable roof, a porch, a walk to the sidewalk, a picket fence, a mailbox
	local WALLS = { rgb(170, 205, 235), rgb(250, 225, 150), rgb(180, 225, 190), rgb(245, 190, 200), rgb(250, 205, 165), rgb(205, 190, 235), rgb(245, 243, 235), rgb(190, 205, 170) }
	local ROOFS = { rgb(150, 70, 60), rgb(90, 94, 104), rgb(50, 90, 70), rgb(50, 60, 100), rgb(120, 80, 55) }
	local DOORS = { rgb(200, 50, 60), rgb(40, 80, 150), rgb(40, 110, 70), rgb(240, 200, 60), rgb(110, 60, 40) }
	local function house(h, i)
		local wall = WALLS[(i * 3) % #WALLS + 1]
		local roof = ROOFS[(i * 2) % #ROOFS + 1]
		if h.extra == "rose" then wall, roof = rgb(250, 190, 210), rgb(170, 70, 100) end
		if h.extra == "grumbles" then wall, roof = rgb(140, 120, 100), rgb(70, 60, 55) end
		local floors = (i % 3 == 0) and 2 or 1
		local hm, doorPos = Kit.building(m, {
			name = "House", x = h.x, z = h.z, w = 26, d = 20, h = floors == 2 and 18 or 11, face = h.face, floors = floors,
			wall = wall, trim = C.white, roof = roof, roofKind = "gable", rise = 7, windows = { 3, 2 },
			winW = 3.4, winH = 3.6, door = { w = 4.4, h = 7.5, color = DOORS[i % #DOORS + 1], x = h.face == "+z" and 4 or -4 }, chimney = i % 2 == 0,
		})
		hm:SetAttribute("Family", h.name)
		local out = h.face == "+z" and 1 or -1
		local front = h.z + out * 10 -- the front wall
		-- the porch: a deck, two posts, a little roof
		part(hm, "Porch", Vector3.new(10, 1.4, 6), CFrame.new(h.x - 4, 0.7, front + out * 3), rgb(200, 180, 150), Enum.Material.WoodPlanks)
		for _, dx in { -4.6, 4.6 } do
			part(hm, "PorchPost", Vector3.new(0.5, 8.4, 0.5), CFrame.new(h.x - 4 + dx, 5.6, front + out * 5.6), C.white)
		end
		part(hm, "PorchRoof", Vector3.new(11, 0.5, 7), CFrame.new(h.x - 4, 10, front + out * 3.2), roof, Enum.Material.Slate)
		-- the walk, the fence with a gap for it, the mailbox with the family's name
		local fenceZ = h.z + out * 21
		part(hm, "Walk", Vector3.new(3.4, 0.35, 10), CFrame.new(h.x - 4, 0.18, front + out * 11), rgb(200, 196, 190), Enum.Material.Concrete)
		if h.extra ~= "grumbles" then
			Kit.picket(hm, h.x - 15, fenceZ, h.x - 6, fenceZ)
			Kit.picket(hm, h.x - 2, fenceZ, h.x + 5.5, fenceZ)
		else
			-- Old Man Grumbles: a tall hedge all the way round and a sign
			Kit.hedge(hm, h.x - 15, fenceZ, h.x - 6, fenceZ, 5)
			Kit.hedge(hm, h.x - 2, fenceZ, h.x + 5.5, fenceZ, 5)
			local sign = part(hm, "GrumblesSign", Vector3.new(5, 2.4, 0.3), CFrame.new(h.x - 9, 3, fenceZ + out * 1.5) * CFrame.Angles(0, h.face == "+z" and math.rad(180) or 0, 0), rgb(245, 240, 225))
			Kit.sign(sign, Enum.NormalId.Front, "KEEP OFF MY GRASS!", rgb(170, 30, 30), rgb(245, 240, 225), Enum.Font.GothamBlack)
		end
		part(hm, "MailPost", Vector3.new(0.4, 3.4, 0.4), CFrame.new(h.x - 7.2, 1.7, fenceZ + out * 1.2), C.wood, Enum.Material.Wood)
		local box = part(hm, "Mailbox", Vector3.new(1.4, 1.2, 2.2), CFrame.new(h.x - 7.2, 3.9, fenceZ + out * 1.2), rgb(40, 40, 50), Enum.Material.Metal)
		local plate = part(hm, "NamePlate", Vector3.new(3.6, 0.9, 0.2), CFrame.new(h.x - 7.2, 2.6, fenceZ + out * 1.35) * CFrame.Angles(0, h.face == "+z" and math.rad(180) or 0, 0), C.white)
		Kit.sign(plate, Enum.NormalId.Front, h.name, rgb(40, 40, 50), C.white, Enum.Font.GothamBold)
		_ = box
		-- the driveway to the side, and a car in some of them
		part(hm, "Driveway", Vector3.new(7, 0.3, 21), CFrame.new(h.x + 9.5, 0.16, front + out * 10.5), rgb(120, 120, 128), Enum.Material.Asphalt)
		if i % 3 == 1 then Kit.car(hm, h.x + 9.5, front + out * 8, h.face == "+z" and "-z" or "+z", ({ rgb(220, 60, 60), rgb(60, 130, 220), rgb(250, 250, 250), rgb(80, 180, 90), rgb(40, 40, 46) })[i % 5 + 1]) end
		-- a tree in the front yard of most houses
		if i % 4 ~= 0 then Kit.tree(hm, h.x + rng:NextNumber(-12, -8), front + out * rng:NextNumber(14, 17), rng:NextNumber(0.8, 1.05)) end
		-- the extras
		if h.extra == "rose" then
			Kit.flowerBed(hm, h.x + 4, front + out * 3, 10, 3, { rgb(255, 120, 170), rgb(255, 255, 255), rgb(240, 70, 90) })
			-- a pie cooling on the windowsill, a garden gnome
			Kit.cylY(hm, "Pie", 1.8, 0.5, Vector3.new(h.x + 6, 4.2, front + out * 0.6), rgb(220, 150, 70))
			Kit.ball(hm, "GnomeBody", 1.2, Vector3.new(h.x + 2, 1, front + out * 8), rgb(60, 120, 220))
			part(hm, "GnomeHat", Vector3.new(0.8, 1.4, 0.8), CFrame.new(h.x + 2, 2.1, front + out * 8), rgb(220, 40, 40))
		elseif h.extra == "hoop" then
			part(hm, "HoopPole", Vector3.new(0.4, 10, 0.4), CFrame.new(h.x + 13.5, 5, front + out * 12), Kit.C.iron, Enum.Material.Metal)
			part(hm, "Backboard", Vector3.new(4, 2.8, 0.2), CFrame.new(h.x + 13.5, 10, front + out * 11.6), C.white)
			Kit.cylY(hm, "Hoop", 1.6, 0.15, Vector3.new(h.x + 13.5, 9.2, front + out * 10.8), rgb(230, 90, 30), Enum.Material.Metal)
			Kit.ball(hm, "Basketball", 1.2, Vector3.new(h.x + 11, 0.6, front + out * 14), rgb(230, 120, 40))
		elseif h.extra == "ramp" then
			Kit.wedge(hm, "SkateRamp", Vector3.new(6, 3, 6), Vector3.new(h.x + 9.5, 1.6, front + out * 14), h.face == "+z" and "+z" or "-z", rgb(200, 160, 110), Enum.Material.WoodPlanks)
			part(hm, "Skateboard", Vector3.new(3, 0.25, 0.9), CFrame.new(h.x + 6, 0.5, front + out * 16), rgb(255, 80, 180))
		elseif h.extra == "treehouse" then
			local tx, tz = h.x + 12, h.z - out * 18
			part(hm, "BigTrunk", Vector3.new(2.6, 16, 2.6), CFrame.new(tx, 8, tz), C.trunk, Enum.Material.Wood)
			part(hm, "Canopy", Vector3.new(16, 7, 16), CFrame.new(tx, 19, tz), C.leaf, Enum.Material.Grass)
			part(hm, "TreehouseFloor", Vector3.new(9, 0.6, 9), CFrame.new(tx, 12, tz), rgb(170, 120, 70), Enum.Material.WoodPlanks)
			part(hm, "TreehouseHut", Vector3.new(7, 5, 7), CFrame.new(tx, 14.8, tz), rgb(200, 150, 90), Enum.Material.WoodPlanks)
			local keep = part(hm, "TreehouseSign", Vector3.new(4, 1.2, 0.2), CFrame.new(tx, 16, tz + out * 3.6) * CFrame.Angles(0, h.face == "+z" and 0 or math.rad(180), 0), rgb(245, 240, 225))
			Kit.sign(keep, Enum.NormalId.Front, "NO GROWNUPS", rgb(200, 40, 40), rgb(245, 240, 225), Enum.Font.PermanentMarker)
			for k = 0, 5 do
				part(hm, "LadderRung", Vector3.new(2, 0.2, 0.3), CFrame.new(tx, 1.5 + k * 1.8, tz + out * 1.6), rgb(170, 120, 70), Enum.Material.Wood)
			end
		elseif h.extra == "garden" then
			for k = 0, 2 do
				Kit.flowerBed(hm, h.x - 10 + k * 10, h.z - out * 16, 7, 4, { rgb(255, 210, 60), rgb(240, 70, 90), rgb(255, 255, 255) })
			end
		elseif h.extra == "patels" then
			part(hm, "Swing", Vector3.new(0.3, 7, 0.3), CFrame.new(h.x + 4, 3.5, h.z - out * 16), C.iron, Enum.Material.Metal)
			part(hm, "Swing", Vector3.new(0.3, 7, 0.3), CFrame.new(h.x + 10, 3.5, h.z - out * 16), C.iron, Enum.Material.Metal)
			part(hm, "SwingBar", Vector3.new(6.6, 0.3, 0.3), CFrame.new(h.x + 7, 7, h.z - out * 16), C.iron, Enum.Material.Metal)
			part(hm, "SwingSeat", Vector3.new(2, 0.3, 1), CFrame.new(h.x + 7, 2, h.z - out * 16), rgb(230, 80, 80))
		end
		return hm, doorPos
	end
	for i, h in HOUSES do house(h, i) end

	-- Maple Heights Clinic (Nurse Nina) on the north side of Maple Lane
	local clinic = Kit.building(m, {
		name = "Clinic", x = -90, z = 370, w = 40, d = 24, h = 14, face = "-z",
		wall = rgb(245, 248, 250), trim = rgb(60, 170, 200), roof = rgb(80, 90, 100), windows = { 4, 2 },
		door = { w = 6, h = 8, color = rgb(60, 170, 200), glass = true },
		sign = { text = "\u{2795} CLINIC", bg = rgb(220, 50, 60), color = C.white, y = 11.5, w = 20 },
	})
	part(clinic, "Ramp", Vector3.new(10, 0.8, 5), CFrame.new(-90, 0.4, 356), C.stone, Enum.Material.Concrete)

	-- the corner playground on the north side of Maple Lane
	local play = Kit.folder(m, "Playground")
	part(play, "Mulch", Vector3.new(44, 0.4, 26), CFrame.new(90, 0.2, 370), rgb(150, 100, 60), Enum.Material.Ground)
	part(play, "SlideTower", Vector3.new(6, 6, 6), CFrame.new(80, 3, 372), rgb(240, 90, 60))
	part(play, "SlideRoof", Vector3.new(7, 0.6, 7), CFrame.new(80, 9.5, 372), rgb(60, 140, 230))
	for _, dx in { -2.8, 2.8 } do
		for _, dz in { -2.8, 2.8 } do part(play, "SlidePost", Vector3.new(0.4, 3.4, 0.4), CFrame.new(80 + dx, 7.7, 372 + dz), rgb(255, 214, 60)) end
	end
	part(play, "Slide", Vector3.new(3, 0.4, 10), CFrame.new(80, 3.4, 362) * CFrame.Angles(math.rad(-30), 0, 0), rgb(255, 214, 60))
	for k = 0, 1 do
		part(play, "SwingFrame", Vector3.new(0.4, 8, 0.4), CFrame.new(96 + k * 12, 4, 364), C.iron, Enum.Material.Metal)
		part(play, "SwingFrame", Vector3.new(0.4, 8, 0.4), CFrame.new(96 + k * 12, 4, 376), C.iron, Enum.Material.Metal)
	end
	part(play, "SwingBar", Vector3.new(12.6, 0.4, 0.4), CFrame.new(102, 8, 364), C.iron, Enum.Material.Metal)
	part(play, "SwingBar", Vector3.new(12.6, 0.4, 0.4), CFrame.new(102, 8, 376), C.iron, Enum.Material.Metal)
	for _, sx in { 98.5, 105.5 } do
		part(play, "SwingSeat", Vector3.new(2, 0.3, 1), CFrame.new(sx, 2.2, 370), rgb(60, 140, 230))
		for _, dz in { -0.4, 0.4 } do part(play, "SwingChain", Vector3.new(0.1, 5.8, 0.1), CFrame.new(sx + dz * 2, 5.1, 370), rgb(200, 200, 206), Enum.Material.Metal) end
	end
	Kit.bench(play, 72, 360, "+z")

	-- the fire station at the north end
	local fire = Kit.building(m, {
		name = "FireStation", x = -150, z = 494, w = 44, d = 30, h = 18, face = "-z", floors = 2,
		wall = rgb(200, 60, 50), trim = C.white, roof = rgb(70, 70, 80), material = Enum.Material.Brick, windows = { 4, 2 },
		door = { w = 5, h = 8, color = rgb(245, 245, 245), glass = true, x = 15 },
		sign = { text = "\u{1F692} FIRE STATION 1", bg = C.white, color = rgb(200, 40, 40), y = 15.5, w = 28 },
	})
	for _, dx in { -10, 1 } do
		part(fire, "GarageDoor", Vector3.new(9, 9.5, 0.3), CFrame.new(-150 + dx, 5.4, 478.8), rgb(235, 235, 240), Enum.Material.DiamondPlate)
		for k = 0, 3 do part(fire, "GarageWindow", Vector3.new(1.6, 0.9, 0.35), CFrame.new(-150 + dx - 3 + k * 2, 8.4, 478.7), Kit.C.glass, Enum.Material.Glass) end
	end
	part(fire, "Apron", Vector3.new(24, 0.3, 14), CFrame.new(-155, 0.16, 471), rgb(170, 170, 176), Enum.Material.Concrete)
	-- the fire engine parked out front
	local eng = Kit.folder(fire, "FireEngine")
	part(eng, "EngineBody", Vector3.new(6, 5, 16), CFrame.new(-161, 3.3, 466), rgb(210, 30, 30), Enum.Material.Metal)
	part(eng, "EngineCab", Vector3.new(6, 3, 5), CFrame.new(-161, 6.5, 461), rgb(210, 30, 30), Enum.Material.Metal)
	part(eng, "Ladder", Vector3.new(1.6, 0.6, 15), CFrame.new(-161, 6.4, 468.5), rgb(200, 200, 208), Enum.Material.Metal)
	for _, dz in { -5, 5 } do
		for _, dx in { -3.1, 3.1 } do
			local w = part(eng, "Wheel", Vector3.new(0.9, 2.6, 2.6), CFrame.new(-161 + dx, 1.3, 466 + dz) * CFrame.Angles(0, 0, math.rad(90)), rgb(24, 24, 26))
			w.Shape = Enum.PartType.Cylinder
		end
	end
	local beacon = part(eng, "Beacon", Vector3.new(4, 0.5, 1), CFrame.new(-161, 8.3, 461), rgb(255, 60, 60), Enum.Material.Neon)
	_ = beacon

	-- the community garden (Mrs. Kim) at the north end
	local garden = Kit.folder(m, "CommunityGarden")
	part(garden, "GardenGround", Vector3.new(40, 0.4, 28), CFrame.new(150, 0.2, 494), rgb(130, 95, 60), Enum.Material.Ground)
	for k = 0, 3 do
		part(garden, "Row", Vector3.new(34, 0.8, 2.4), CFrame.new(150, 0.6, 484 + k * 6), rgb(110, 76, 50), Enum.Material.Ground)
		for j = 0, 10 do
			local c = ({ rgb(240, 70, 60), rgb(255, 170, 40), rgb(90, 180, 70), rgb(255, 220, 60) })[k + 1]
			Kit.ball(garden, "Veg", 1, Vector3.new(135 + j * 3, 1.5, 484 + k * 6), c)
		end
	end
	Kit.picket(garden, 130, 480, 170, 480)
	part(garden, "Shed", Vector3.new(8, 7, 6), CFrame.new(165, 3.5, 505), rgb(160, 110, 70), Enum.Material.WoodPlanks)
	Kit.wedge(garden, "ShedRoof", Vector3.new(9, 2, 7), Vector3.new(165, 8, 505), "-z", rgb(90, 70, 50), Enum.Material.Slate)
	local gsign = part(garden, "GardenSign", Vector3.new(8, 2, 0.3), CFrame.new(150, 4, 479.5), rgb(245, 240, 225))
	Kit.sign(gsign, Enum.NormalId.Back, "\u{1F955} COMMUNITY GARDEN", rgb(40, 110, 50), rgb(245, 240, 225), Enum.Font.GothamBold)
	for _, x in { 146, 154 } do part(garden, "SignPost", Vector3.new(0.3, 4, 0.3), CFrame.new(x, 2, 479.5), C.wood, Enum.Material.Wood) end

	-- trees along the far edge and the fence lines
	for x = -520, 520, 34 do Kit.tree(m, x + rng:NextNumber(-6, 6), 530 + rng:NextNumber(-6, 6), rng:NextNumber(0.9, 1.3)) end
	for z = 270, 520, 36 do
		Kit.tree(m, -520 + rng:NextNumber(-4, 4), z, rng:NextNumber(0.9, 1.2))
		Kit.tree(m, 520 + rng:NextNumber(-4, 4), z, rng:NextNumber(0.9, 1.2))
	end
	return m
end

return Maple
