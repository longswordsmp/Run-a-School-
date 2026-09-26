-- ServerScriptService.Server.TownPark
-- Pine Park (docs/TOWN.md): the forest west of the school area, through the PINE PARK gate.
--   the entrance plaza (-590, 0) with the trail map; dirt trails north and south along x = -600
--   north    the Ranger Station (a log cabin, -650, 230), Camp Wannaplaya (tents, a campfire, logs
--            to sit on, -700, 390), the lookout tower (-740, 170)
--   south    Lake Wannaswim (real water you can swim in, -680, -170) with a dock, a boathouse and
--            rowboats; the picnic grounds (-600, -80); the treehouse (-650, -370) with a rope bridge
--            to its neighbour; Bea's bird hide (-760, -300)
--   and pines everywhere else
local Park = {}

function Park.build(town, Kit)
	local rgb = Kit.rgb
	local part, C = Kit.part, Kit.C
	local m = Kit.folder(town, "PinePark")
	local rng = Random.new(7)
	local DIRT = rgb(170, 130, 85)
	local LOG = rgb(130, 85, 50)

	local keepClear = {} -- rectangles pines must stay out of: { x0, x1, z0, z1 }
	local function clear(x0, x1, z0, z1) table.insert(keepClear, { x0, x1, z0, z1 }) end
	local function trail(x0, z0, x1, z1, w)
		w = w or 10
		local along = math.abs(x1 - x0) > math.abs(z1 - z0)
		local len = along and math.abs(x1 - x0) or math.abs(z1 - z0)
		part(m, "Trail", along and Vector3.new(len + w, 0.3, w) or Vector3.new(w, 0.3, len + w), CFrame.new((x0 + x1) / 2, 0.16, (z0 + z1) / 2), DIRT, Enum.Material.Ground)
		clear(math.min(x0, x1) - w, math.max(x0, x1) + w, math.min(z0, z1) - w, math.max(z0, z1) + w)
	end

	-- the entrance plaza and the trail map
	part(m, "Plaza", Vector3.new(34, 0.35, 34), CFrame.new(-590, 0.18, 0), rgb(200, 185, 160), Enum.Material.Pebble)
	clear(-610, -540, -20, 20)
	local board = part(m, "TrailMap", Vector3.new(10, 6, 0.4), CFrame.new(-590, 5, -14) * CFrame.Angles(0, math.rad(180), 0), rgb(110, 76, 45), Enum.Material.WoodPlanks)
	Kit.sign(board, Enum.NormalId.Front, "PINE PARK\n\u{2191} Ranger Station \u{2022} Camp Wannaplaya\n\u{2193} Lake Wannaswim \u{2022} Treehouse", rgb(250, 240, 210), rgb(90, 60, 35), Enum.Font.GothamBold)
	for _, dx in { -4, 4 } do part(m, "MapPost", Vector3.new(0.5, 8, 0.5), CFrame.new(-590 + dx, 4, -14), LOG, Enum.Material.Wood) end
	Kit.bench(m, -600, 12, "-z")
	Kit.bench(m, -580, 12, "-z")

	-- the trails
	trail(-600, 0, -600, 390)
	trail(-600, 0, -600, -390)
	trail(-600, 230, -640, 230)
	trail(-600, 390, -680, 390)
	trail(-600, -150, -640, -150)
	trail(-600, -370, -640, -370)
	trail(-600, 170, -725, 170, 8)
	trail(-600, -300, -745, -300, 8)
	for z = -360, 360, 60 do
		if math.abs(z) > 20 then Kit.lamp(m, -608, z, 9) end
	end

	-- the Ranger Station: a log cabin with a porch, a flag and a sign
	local cabin = Kit.building(m, {
		name = "RangerStation", x = -662, z = 230, w = 30, d = 24, h = 11, face = "+x",
		wall = rgb(140, 95, 55), trim = rgb(90, 60, 35), roof = rgb(60, 90, 60), roofKind = "gable", rise = 7,
		material = Enum.Material.WoodPlanks, windows = { 3, 2 }, winW = 3.4, winH = 3.4,
		door = { w = 4.6, h = 8, color = rgb(90, 60, 35) }, chimney = true,
		sign = { text = "\u{1F332} RANGER STATION", bg = rgb(60, 90, 60), color = rgb(250, 240, 210), y = 9.6, w = 20, h = 2.4 },
	})
	for k = 0, 5 do
		Kit.cylZ(cabin, "Log", 1, 24.4, Vector3.new(-677, 1 + k * 1.8, 230), LOG, Enum.Material.Wood)
		Kit.cylZ(cabin, "Log", 1, 24.4, Vector3.new(-647, 1 + k * 1.8, 230), LOG, Enum.Material.Wood)
	end
	part(cabin, "Porch", Vector3.new(6, 1.2, 18), CFrame.new(-644, 0.6, 230), rgb(150, 110, 70), Enum.Material.WoodPlanks)
	for _, dz in { -8, 8 } do part(cabin, "PorchPost", Vector3.new(0.6, 9, 0.6), CFrame.new(-641.6, 5.7, 230 + dz), LOG, Enum.Material.Wood) end
	part(cabin, "PorchRoof", Vector3.new(7, 0.5, 19), CFrame.new(-644, 10.4, 230), rgb(60, 90, 60), Enum.Material.Slate)
	Kit.flagpole(cabin, -640, 246, rgb(46, 130, 76))
	clear(-690, -630, 205, 255)

	-- Camp Wannaplaya: tents round a campfire, logs to sit on, picnic tables, the camp sign
	local camp = Kit.folder(m, "Campground")
	part(camp, "Clearing", Vector3.new(70, 0.3, 60), CFrame.new(-705, 0.15, 390), rgb(120, 170, 80), Enum.Material.Grass)
	clear(-745, -665, 355, 425)
	local tentColors = { rgb(230, 90, 60), rgb(60, 140, 220), rgb(80, 180, 90), rgb(240, 200, 60) }
	for i, spot in { { -725, 375 }, { -725, 405 }, { -690, 415 }, { -690, 365 } } do
		local c = tentColors[i]
		Kit.wedge(camp, "Tent", Vector3.new(8, 6, 4.5), Vector3.new(spot[1], 3, spot[2] - 2.25), "+z", c, Enum.Material.Fabric)
		Kit.wedge(camp, "Tent", Vector3.new(8, 6, 4.5), Vector3.new(spot[1], 3, spot[2] + 2.25), "-z", c, Enum.Material.Fabric)
		part(camp, "TentDoor", Vector3.new(0.2, 3.6, 2.4), CFrame.new(spot[1] + 4.05, 1.8, spot[2]), c:Lerp(Color3.new(0, 0, 0), 0.4), Enum.Material.Fabric)
	end
	-- the campfire
	for k = 0, 7 do
		local a = math.rad(k * 45)
		Kit.ball(camp, "FireStone", 1.2, Vector3.new(-706 + math.cos(a) * 2.6, 0.5, 390 + math.sin(a) * 2.6), rgb(120, 120, 126))
	end
	for k = 0, 2 do
		part(camp, "FireLog", Vector3.new(0.7, 0.7, 4), CFrame.new(-706, 0.7, 390) * CFrame.Angles(0, math.rad(k * 60), math.rad(20)), LOG, Enum.Material.Wood)
	end
	local fire = part(camp, "Fire", Vector3.new(1, 1, 1), CFrame.new(-706, 1.2, 390), rgb(255, 140, 40), nil, { Transparency = 1, CanCollide = false })
	local flames = Instance.new("Fire")
	flames.Size = 5
	flames.Heat = 8
	flames.Parent = fire
	Kit.light(fire, 22, 2, rgb(255, 150, 60))
	for k = 0, 3 do
		local a = math.rad(k * 90 + 45)
		Kit.cylZ(camp, "SitLog", 1.6, 5, Vector3.new(-706 + math.cos(a) * 7, 0.8, 390 + math.sin(a) * 7), LOG, Enum.Material.Wood)
	end
	for _, spot in { { -680, 395 }, { -735, 392 } } do
		part(camp, "Table", Vector3.new(4, 0.4, 8), CFrame.new(spot[1], 2.8, spot[2]), rgb(170, 120, 70), Enum.Material.WoodPlanks)
		for _, dx in { -3, 3 } do part(camp, "TableBench", Vector3.new(1.2, 0.4, 8), CFrame.new(spot[1] + dx, 1.8, spot[2]), rgb(170, 120, 70), Enum.Material.WoodPlanks) end
		part(camp, "TableLegs", Vector3.new(3, 2.6, 0.5), CFrame.new(spot[1], 1.4, spot[2]), LOG, Enum.Material.Wood)
	end
	local campSign = part(camp, "CampSign", Vector3.new(14, 3, 0.5), CFrame.new(-705, 8, 358), LOG, Enum.Material.WoodPlanks)
	Kit.sign(campSign, Enum.NormalId.Back, "\u{26FA} CAMP WANNAPLAYA", rgb(255, 230, 170), LOG, Enum.Font.LuckiestGuy)
	for _, dx in { -6.5, 6.5 } do part(camp, "SignLog", Vector3.new(1, 9, 1), CFrame.new(-705 + dx, 4.5, 358), LOG, Enum.Material.Wood) end

	-- the lookout tower: four legs, cross braces, a deck with rails, stairs going round
	local tower = Kit.folder(m, "Lookout")
	local tx, tz = -740, 170
	for _, dx in { -4, 4 } do
		for _, dz in { -4, 4 } do part(tower, "TowerLeg", Vector3.new(1.2, 30, 1.2), CFrame.new(tx + dx, 15, tz + dz), LOG, Enum.Material.Wood) end
	end
	for y = 6, 24, 9 do
		for _, dz in { -4, 4 } do part(tower, "Brace", Vector3.new(9.6, 0.6, 0.6), CFrame.new(tx, y, tz + dz), LOG, Enum.Material.Wood) end
		for _, dx in { -4, 4 } do part(tower, "Brace", Vector3.new(0.6, 0.6, 9.6), CFrame.new(tx + dx, y, tz), LOG, Enum.Material.Wood) end
	end
	part(tower, "Deck", Vector3.new(12, 0.8, 12), CFrame.new(tx, 30.4, tz), rgb(170, 120, 70), Enum.Material.WoodPlanks)
	for _, s in { -1, 1 } do
		part(tower, "Rail", Vector3.new(12, 3, 0.4), CFrame.new(tx, 32.3, tz + s * 5.8), LOG, Enum.Material.Wood)
		part(tower, "Rail", Vector3.new(0.4, 3, 12), CFrame.new(tx + s * 5.8, 32.3, tz), LOG, Enum.Material.Wood)
	end
	part(tower, "TowerRoof", Vector3.new(13, 0.6, 13), CFrame.new(tx, 38, tz), rgb(60, 90, 60), Enum.Material.Slate)
	for _, dx in { -5.5, 5.5 } do for _, dz in { -5.5, 5.5 } do part(tower, "RoofPost", Vector3.new(0.4, 6, 0.4), CFrame.new(tx + dx, 34.7, tz + dz), LOG, Enum.Material.Wood) end end
	-- a zig-zag stair up the east side
	for k = 0, 29 do
		local y = 0.5 + k
		local flight = math.floor(k / 10)
		local along = (k % 10) / 10
		local sx = flight % 2 == 0 and (-3 + along * 6) or (3 - along * 6)
		part(tower, "Stair", Vector3.new(1.2, 0.4, 3), CFrame.new(tx + sx, y, tz + 6.4), rgb(170, 120, 70), Enum.Material.WoodPlanks)
	end
	clear(tx - 12, tx + 14, tz - 12, tz + 14)

	-- Lake Wannaswim: real water in a stone rim, a dock, a boathouse, rowboats
	local lake = Kit.folder(m, "Lake")
	local lx, lz, lr = -690, -170, 42
	workspace.Terrain:FillCylinder(CFrame.new(lx, 1.5, lz), 3, lr, Enum.Material.Water)
	for k = 0, 47 do
		local a = math.rad(k * 7.5)
		local r = lr + 2 + rng:NextNumber(-0.5, 1.5)
		Kit.ball(lake, "Rock", rng:NextNumber(3, 5), Vector3.new(lx + math.cos(a) * r, 1, lz + math.sin(a) * r), rgb(140, 138, 134), Enum.Material.Slate)
	end
	clear(lx - lr - 8, lx + lr + 8, lz - lr - 8, lz + lr + 8)
	-- the dock from the east shore
	part(lake, "Dock", Vector3.new(26, 0.8, 7), CFrame.new(lx + lr - 8, 3.2, lz), rgb(170, 120, 70), Enum.Material.WoodPlanks)
	for k = 0, 4 do
		for _, dz in { -3, 3 } do Kit.cylY(lake, "DockPost", 0.8, 5, Vector3.new(lx + lr - 20 + k * 6, 1.2, lz + dz), LOG, Enum.Material.Wood) end
	end
	-- the boathouse on the north shore
	Kit.building(lake, {
		name = "Boathouse", x = lx, z = lz + lr + 10, w = 22, d = 14, h = 9, face = "-z",
		wall = rgb(90, 130, 170), trim = C.white, roof = rgb(150, 70, 60), roofKind = "gable", rise = 5, windows = { 2, 1 },
		door = { w = 6, h = 7, color = rgb(90, 60, 35) },
		sign = { text = "BOATHOUSE", bg = C.white, color = rgb(60, 90, 140), y = 7.8, w = 12, h = 1.8 },
	})
	-- rowboats: a hull, seats and oars, floating
	for i, spot in { { lx - 12, lz + 10, 20 }, { lx + 8, lz - 16, -35 } } do
		local cf = CFrame.new(spot[1], 3.9, spot[2]) * CFrame.Angles(0, math.rad(spot[3]), 0)
		local c = i == 1 and rgb(220, 70, 60) or rgb(240, 240, 235)
		part(lake, "Hull", Vector3.new(9, 1.4, 3.6), cf, c, Enum.Material.WoodPlanks)
		part(lake, "HullInside", Vector3.new(8.2, 0.4, 2.8), cf * CFrame.new(0, 0.5, 0), rgb(150, 110, 70), Enum.Material.WoodPlanks)
		part(lake, "BoatSeat", Vector3.new(1, 0.3, 3.4), cf * CFrame.new(-1.5, 0.9, 0), rgb(150, 110, 70), Enum.Material.WoodPlanks)
		part(lake, "Oar", Vector3.new(0.3, 0.3, 7), cf * CFrame.new(0.5, 1, 0) * CFrame.Angles(0, math.rad(12), 0), LOG, Enum.Material.Wood)
	end
	-- lily pads
	for k = 0, 9 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(8, lr - 8)
		Kit.cylY(lake, "LilyPad", rng:NextNumber(2, 3.4), 0.2, Vector3.new(lx + math.cos(a) * r, 3.7, lz + math.sin(a) * r), rgb(70, 160, 70))
	end

	-- the picnic grounds by the south trail
	local picnic = Kit.folder(m, "Picnic")
	for i, spot in { { -585, -60 }, { -585, -95 }, { -575, -125 } } do
		part(picnic, "Table", Vector3.new(8, 0.4, 4), CFrame.new(spot[1], 2.8, spot[2]), rgb(170, 120, 70), Enum.Material.WoodPlanks)
		for _, dz in { -3, 3 } do part(picnic, "TableBench", Vector3.new(8, 0.4, 1.2), CFrame.new(spot[1], 1.8, spot[2] + dz), rgb(170, 120, 70), Enum.Material.WoodPlanks) end
		part(picnic, "TableLegs", Vector3.new(0.5, 2.6, 3), CFrame.new(spot[1], 1.4, spot[2]), LOG, Enum.Material.Wood)
		if i == 2 then
			part(picnic, "Cloth", Vector3.new(8.2, 0.1, 4.2), CFrame.new(spot[1], 3.05, spot[2]), rgb(230, 70, 70), Enum.Material.Fabric)
			Kit.cylY(picnic, "PicnicBasket", 1.6, 1.2, Vector3.new(spot[1] + 1, 3.6, spot[2]), rgb(200, 150, 90), Enum.Material.Fabric)
		end
	end
	part(picnic, "Grill", Vector3.new(2.4, 1.6, 1.6), CFrame.new(-570, 3, -80), rgb(40, 40, 46), Enum.Material.Metal)
	part(picnic, "GrillLegs", Vector3.new(2, 2.2, 1.2), CFrame.new(-570, 1.1, -80), rgb(60, 60, 66), Enum.Material.Metal)
	clear(-595, -560, -135, -50)

	-- the treehouse: two big trees joined by a rope bridge, a hut in each, a rope ladder
	local th = Kit.folder(m, "Treehouse")
	local function bigTree(x, z)
		part(th, "BigTrunk", Vector3.new(3.4, 22, 3.4), CFrame.new(x, 11, z), C.trunk, Enum.Material.Wood)
		part(th, "Canopy", Vector3.new(20, 8, 20), CFrame.new(x, 25, z), C.leaf, Enum.Material.Grass)
		part(th, "Canopy", Vector3.new(14, 5, 14), CFrame.new(x, 30.5, z), C.leaf:Lerp(C.white, 0.08), Enum.Material.Grass)
		part(th, "Platform", Vector3.new(12, 0.8, 12), CFrame.new(x, 14, z), rgb(170, 120, 70), Enum.Material.WoodPlanks)
		part(th, "Hut", Vector3.new(8, 6, 8), CFrame.new(x, 17.4, z), rgb(200, 150, 90), Enum.Material.WoodPlanks)
		part(th, "HutDoor", Vector3.new(2.4, 4, 0.2), CFrame.new(x, 16.4, z - 4.05), rgb(90, 60, 35))
		for _, s in { -1, 1 } do
			part(th, "Railing", Vector3.new(12, 1.6, 0.4), CFrame.new(x, 15.2, z + s * 5.8), LOG, Enum.Material.Wood)
		end
	end
	bigTree(-650, -370)
	bigTree(-690, -370)
	-- the rope bridge between them
	for k = 0, 13 do
		part(th, "BridgePlank", Vector3.new(1.8, 0.3, 3.4), CFrame.new(-656.5 - k * 2, 14 - math.sin(k / 13 * math.pi) * 1.2, -370), rgb(180, 130, 80), Enum.Material.WoodPlanks)
	end
	for _, dz in { -1.8, 1.8 } do
		part(th, "Rope", Vector3.new(28, 0.2, 0.2), CFrame.new(-670, 15.6, -370 + dz), rgb(200, 170, 120), Enum.Material.Fabric)
	end
	-- the rope ladder up to the first platform (the side facing the trail)
	for k = 0, 7 do
		part(th, "Rung", Vector3.new(0.3, 0.3, 2.6), CFrame.new(-643.5, 1.2 + k * 1.7, -370), rgb(180, 130, 80), Enum.Material.Wood)
	end
	part(th, "LadderSide", Vector3.new(0.2, 14, 0.2), CFrame.new(-643.5, 7, -371.3), rgb(200, 170, 120), Enum.Material.Fabric)
	part(th, "LadderSide", Vector3.new(0.2, 14, 0.2), CFrame.new(-643.5, 7, -368.7), rgb(200, 170, 120), Enum.Material.Fabric)
	local keep = part(th, "ClubSign", Vector3.new(5, 1.4, 0.2), CFrame.new(-650, 19, -374.2) * CFrame.Angles(0, math.rad(180), 0), rgb(245, 240, 225))
	Kit.sign(keep, Enum.NormalId.Front, "SECRET CLUB", rgb(200, 40, 40), rgb(245, 240, 225), Enum.Font.PermanentMarker)
	clear(-702, -638, -386, -354)

	-- Bea's bird hide: a little shed with a slot window and a feeder
	local hide = Kit.building(m, {
		name = "BirdHide", x = -760, z = -300, w = 12, d = 8, h = 7, face = "+x",
		wall = rgb(110, 90, 60), trim = rgb(80, 60, 40), roof = rgb(60, 80, 50), roofKind = "gable", rise = 3,
		material = Enum.Material.WoodPlanks, windows = { 0, 0 }, door = { w = 3, h = 6, color = rgb(80, 60, 40) },
	})
	part(hide, "Slot", Vector3.new(0.3, 0.8, 8), CFrame.new(-753.9, 4.8, -300), rgb(20, 20, 20))
	part(hide, "FeederPost", Vector3.new(0.4, 6, 0.4), CFrame.new(-745, 3, -290), LOG, Enum.Material.Wood)
	part(hide, "Feeder", Vector3.new(2.4, 1.6, 2.4), CFrame.new(-745, 6.6, -290), rgb(200, 60, 50), Enum.Material.WoodPlanks)
	clear(-772, -740, -312, -285)

	-- the forest: pines wherever there's no trail, clearing or building
	local function free(x, z)
		for _, r in keepClear do
			if x > r[1] and x < r[2] and z > r[3] and z < r[4] then return false end
		end
		return true
	end
	for x = -785, -555, 18 do
		for z = -545, 545, 18 do
			local px, pz = x + rng:NextNumber(-6, 6), z + rng:NextNumber(-6, 6)
			if free(px, pz) and rng:NextNumber() < 0.55 then
				if rng:NextNumber() < 0.8 then Kit.pine(m, px, pz, rng:NextNumber(0.9, 1.5)) else Kit.tree(m, px, pz, rng:NextNumber(0.9, 1.2), rgb(70, 160, 70)) end
			end
		end
	end
	return m
end

return Park
