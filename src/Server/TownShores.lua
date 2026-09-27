-- ServerScriptService.Server.TownShores
-- Sunny Shores: the seaside north of Downtown, where the map used to stop at a row of pines. Through
-- the SUNNY SHORES gate at the end of Beach Road (x = 400, off Market Street).
--   Shore Drive     the road along the front (z = -600), lamps, a crossing at Beach Road
--   the boardwalk   a wide plank promenade (z -612..-642): snack kiosks (ice cream, lemonade, hot
--                   dogs, popcorn, slushies, fruit), benches, palms in planters, lamps, and railings
--                   on the beach side with steps down every so often
--   the beach       sand sloping into the sea (real, swimmable water): umbrellas and towels, sand-
--                   castles, beach balls, surfboards, a lifeguard tower, a volleyball net
--   the pier        out from the boardwalk on the Town Hall axis (x = 0), on piles, to a deck with
--                   the Ferris wheel (turned on each client by Decor: "Wheel")
--   the lighthouse  red and white, on the rocks at the east end
-- The world's north edge is at z -960 now (TownService.EDGE_NORTH); the sea runs on past it.
local CollectionService = game:GetService("CollectionService")

local Shores = {}

Shores.NORTH_EDGE = 960
local SHORE_Z = -600
local BOARD_Z0, BOARD_Z1 = -612, -642 -- the boardwalk, from the road side to the beach side
local SAND_Z = -700 -- about where the sand meets the sea
local WATER_Y = -0.8

function Shores.build(town, Kit)
	local rgb = Kit.rgb
	local part, C = Kit.part, Kit.C
	local m = Kit.folder(town, "SunnyShores")
	local rng = Random.new(77)
	local SAND = rgb(246, 224, 172)
	local PLANK = rgb(198, 152, 102)
	local RAIL = rgb(250, 250, 246)

	---------------------------------------------------------------------------
	-- the land behind the beach, the roads, the gate
	---------------------------------------------------------------------------
	-- (on under the boardwalk to the sand: past the boardwalk's ends there was nothing to stand on)
	Kit.ground(m, -800, 800, -642, -560)
	local streets = Kit.folder(m, "Streets")
	Kit.road(streets, -700, SHORE_Z, 700, SHORE_Z, 24, { sidewalk = 6 })
	Kit.road(streets, 400, -410, 400, SHORE_Z + 12, 20, { sidewalk = 6 })
	Kit.pave(streets, 390, 410, SHORE_Z - 12, SHORE_Z + 12, C.asphalt, Enum.Material.Asphalt, 0.13)
	Kit.crosswalk(streets, 400, SHORE_Z + 16, 20, true)
	Kit.gateArch(m, 400, -562, 20, "\u{2600}\u{FE0F} SUNNY SHORES", rgb(40, 170, 220), true)
	-- a footpath from behind Town Hall straight to the pier
	Kit.pave(streets, -5, 5, SHORE_Z + 12, -540, rgb(214, 208, 196), Enum.Material.Concrete, 0.2)
	for x = -660, 660, 60 do
		if math.abs(x - 400) > 20 and math.abs(x) > 12 then Kit.lamp(streets, x, SHORE_Z + 16) end
	end
	-- a low white fence along the back of Downtown's lots, open at the road and the footpath
	local fence = Kit.folder(m, "Fence")
	Kit.picket(fence, -790, -560, -8, -560, RAIL)
	Kit.picket(fence, 8, -560, 386, -560, RAIL)
	Kit.picket(fence, 414, -560, 790, -560, RAIL)

	---------------------------------------------------------------------------
	-- the sea: water from the sand out past the edge of the world, a sandy bottom under it
	---------------------------------------------------------------------------
	local sea = Kit.folder(m, "Sea")
	local terrain = workspace.Terrain
	pcall(function()
		terrain:FillBlock(CFrame.new(0, WATER_Y - 5, -1060), Vector3.new(2800, 10, 760), Enum.Material.Water)
	end)
	part(sea, "Seabed", Vector3.new(2800, 2, 760), CFrame.new(0, WATER_Y - 11, -1060), SAND:Lerp(rgb(120, 110, 90), 0.25), Enum.Material.Sand)

	---------------------------------------------------------------------------
	-- the beach: flat sand, then a slope down under the water
	---------------------------------------------------------------------------
	local beach = Kit.folder(m, "Beach")
	part(beach, "Sand", Vector3.new(1600, 2, 50), CFrame.new(0, -0.8, (BOARD_Z1 + SAND_Z + 8) / 2 + 0), SAND, Enum.Material.Sand)
	-- (the slope: its top edge at the sand, falling 5 studs to the sea floor over 60)
	Kit.wedge(beach, "SandSlope", Vector3.new(1600, 5, 60), Vector3.new(0, -2.3, SAND_Z - 22), "-z", SAND, Enum.Material.Sand)
	part(beach, "WetSand", Vector3.new(1600, 0.1, 6), CFrame.new(0, 0.21, SAND_Z + 2), SAND:Lerp(rgb(170, 140, 100), 0.35), Enum.Material.Sand)

	-- umbrellas and towels in little groups, sandcastles, beach balls, surfboards
	local UMBRELLA = { { rgb(255, 90, 90), rgb(255, 255, 255) }, { rgb(60, 160, 255), rgb(255, 255, 255) }, { rgb(255, 200, 60), rgb(255, 120, 60) }, { rgb(120, 220, 120), rgb(255, 255, 255) }, { rgb(200, 120, 255), rgb(255, 230, 250) } }
	local TOWEL = { rgb(255, 120, 170), rgb(90, 200, 255), rgb(255, 214, 90), rgb(140, 230, 160), rgb(255, 150, 90), rgb(190, 150, 255) }
	local function umbrella(x, z, colors)
		local u = Kit.folder(beach, "Umbrella")
		part(u, "Pole", Vector3.new(0.35, 8, 0.35), CFrame.new(x, 3.8, z) * CFrame.Angles(math.rad(6), 0, 0), rgb(240, 240, 240), Enum.Material.Metal)
		-- the canopy: eight wedge panels in two colours round the top of the pole
		for k = 0, 7 do
			local a = k * math.pi / 4
			local w = Instance.new("WedgePart")
			w.Name = "Canopy"
			w.Size = Vector3.new(3.6, 1.4, 4.2)
			w.CFrame = CFrame.new(x, 7.6, z) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -2.1) -- (tall side at the pole)
			w.Color = colors[k % 2 + 1]
			w.Material = Enum.Material.Fabric
			w.Anchored = true
			w.Parent = u
		end
		Kit.ball(u, "Finial", 0.6, Vector3.new(x, 8.5, z), rgb(255, 255, 255))
	end
	local function towel(x, z, yaw, c)
		part(beach, "Towel", Vector3.new(3.4, 0.12, 6.4), CFrame.new(x, 0.25, z) * CFrame.Angles(0, yaw, 0), c, Enum.Material.Fabric)
		part(beach, "TowelStripe", Vector3.new(3.4, 0.13, 0.6), CFrame.new(x, 0.26, z) * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 0, 2.2), rgb(255, 255, 255), Enum.Material.Fabric)
	end
	for x = -560, 560, 80 do
		if math.abs(x) > 40 and math.abs(x - 200) > 20 and math.abs(x + 200) > 20 then
			local z = -670 + rng:NextNumber(-8, 8)
			umbrella(x, z, UMBRELLA[rng:NextInteger(1, #UMBRELLA)])
			towel(x - 3, z + 4, rng:NextNumber(-0.3, 0.3), TOWEL[rng:NextInteger(1, #TOWEL)])
			towel(x + 3, z + 4, rng:NextNumber(-0.3, 0.3), TOWEL[rng:NextInteger(1, #TOWEL)])
			if rng:NextNumber() < 0.5 then Kit.ball(beach, "BeachBall", 1.8, Vector3.new(x + rng:NextNumber(-8, 8), 1.1, z - 6), ({ rgb(255, 80, 80), rgb(60, 160, 255), rgb(255, 210, 60) })[rng:NextInteger(1, 3)], Enum.Material.SmoothPlastic) end
		end
	end
	-- sandcastles: a keep and four towers with flags
	local function sandcastle(x, z)
		local s = Kit.folder(beach, "Sandcastle")
		part(s, "Keep", Vector3.new(3.2, 2.4, 3.2), CFrame.new(x, 1.4, z), SAND:Lerp(rgb(200, 170, 110), 0.2), Enum.Material.Sand)
		for _, dx in { -1, 1 } do
			for _, dz in { -1, 1 } do
				Kit.cylY(s, "Tower", 1.6, 3.2, Vector3.new(x + dx * 2, 1.8, z + dz * 2), SAND:Lerp(rgb(200, 170, 110), 0.2), Enum.Material.Sand)
			end
		end
		part(s, "FlagPole", Vector3.new(0.12, 2.2, 0.12), CFrame.new(x, 3.7, z), rgb(120, 90, 60), Enum.Material.Wood)
		part(s, "Flag", Vector3.new(0.9, 0.6, 0.05), CFrame.new(x + 0.45, 4.5, z), rgb(255, 80, 80), Enum.Material.Fabric)
		Kit.cylY(s, "Bucket", 1.2, 1.1, Vector3.new(x + 4, 0.8, z + 1), rgb(60, 160, 255), Enum.Material.SmoothPlastic)
	end
	for _, x in { -470, -130, 250, 520 } do sandcastle(x, -688) end
	-- surfboards stood up in the sand
	for i, x in { -330, -325, 330, 336 } do
		part(beach, "Surfboard", Vector3.new(1.8, 7, 0.3), CFrame.new(x, 3.2, -652) * CFrame.Angles(0, math.rad(20), math.rad(i % 2 == 0 and 8 or -6)), ({ rgb(255, 120, 60), rgb(60, 200, 220), rgb(255, 90, 170), rgb(255, 214, 70) })[i], Enum.Material.SmoothPlastic)
	end
	-- the lifeguard tower: legs, a hut, a ladder, a red cross flag
	do
		local x, z = -200, -672
		local lg = Kit.folder(beach, "LifeguardTower")
		for _, dx in { -2.2, 2.2 } do
			for _, dz in { -2.2, 2.2 } do part(lg, "Leg", Vector3.new(0.6, 8, 0.6), CFrame.new(x + dx, 4, z + dz), rgb(245, 245, 240), Enum.Material.Wood) end
		end
		part(lg, "Deck", Vector3.new(6, 0.6, 6), CFrame.new(x, 8.2, z), rgb(245, 245, 240), Enum.Material.WoodPlanks)
		part(lg, "Hut", Vector3.new(5, 4.4, 5), CFrame.new(x, 10.7, z + 0.4), rgb(240, 70, 60))
		part(lg, "HutWindow", Vector3.new(4, 1.8, 0.2), CFrame.new(x, 11.2, z - 2.15), rgb(160, 210, 240), Enum.Material.Glass, { Transparency = 0.2 })
		part(lg, "HutRoof", Vector3.new(6, 0.6, 6), CFrame.new(x, 13.2, z + 0.4), rgb(250, 250, 246))
		for k = 0, 6 do part(lg, "Rung", Vector3.new(2, 0.3, 0.3), CFrame.new(x, 1 + k * 1.1, z - 4.4) * CFrame.Angles(math.rad(-15), 0, 0), rgb(245, 245, 240), Enum.Material.Wood) end
		part(lg, "FlagPole", Vector3.new(0.2, 5, 0.2), CFrame.new(x + 2.4, 15.9, z + 2.4), rgb(240, 240, 240), Enum.Material.Metal)
		local flag = part(lg, "Flag", Vector3.new(2.6, 1.6, 0.1), CFrame.new(x + 3.8, 17.4, z + 2.4), rgb(255, 255, 255), Enum.Material.Fabric)
		Kit.sign(flag, Enum.NormalId.Front, "\u{271A}", rgb(230, 40, 40), rgb(255, 255, 255), Enum.Font.GothamBlack)
		Kit.sign(flag, Enum.NormalId.Back, "\u{271A}", rgb(230, 40, 40), rgb(255, 255, 255), Enum.Font.GothamBlack)
	end
	-- the volleyball net
	do
		local x, z = 200, -676
		for _, dx in { -9, 9 } do part(beach, "NetPost", Vector3.new(0.4, 7.4, 0.4), CFrame.new(x + dx, 3.5, z), rgb(240, 240, 240), Enum.Material.Metal) end
		part(beach, "Net", Vector3.new(18, 2.6, 0.1), CFrame.new(x, 5.6, z), rgb(250, 250, 250), Enum.Material.Fabric, { Transparency = 0.35 })
		part(beach, "NetTape", Vector3.new(18, 0.3, 0.15), CFrame.new(x, 7, z), rgb(60, 120, 230))
		Kit.ball(beach, "Volleyball", 1.4, Vector3.new(x + 4, 0.9, z - 6), rgb(255, 214, 70))
	end

	---------------------------------------------------------------------------
	-- the boardwalk: planks, railings on the beach side with steps down, kiosks, palms, benches
	---------------------------------------------------------------------------
	local bw = Kit.folder(m, "Boardwalk")
	local mid = (BOARD_Z0 + BOARD_Z1) / 2
	part(bw, "Deck", Vector3.new(1320, 1, BOARD_Z0 - BOARD_Z1), CFrame.new(0, 0.5, mid), PLANK, Enum.Material.WoodPlanks)
	part(bw, "Fascia", Vector3.new(1320, 1.8, 0.4), CFrame.new(0, 0.1, BOARD_Z1 + 0.2), PLANK:Lerp(rgb(0, 0, 0), 0.2), Enum.Material.WoodPlanks)
	-- the railing, with a gap for steps every 140 and at the pier
	local STEPS = { -560, -420, -280, -140, 140, 280, 420, 560 }
	local function gapAt(x)
		if math.abs(x) < 9 then return true end
		for _, s in STEPS do if math.abs(x - s) < 5 then return true end end
		return false
	end
	for x = -658, 658, 4 do
		if not gapAt(x) then part(bw, "Baluster", Vector3.new(0.3, 3, 0.3), CFrame.new(x, 2.5, BOARD_Z1 + 0.6), RAIL) end
	end
	local x0 = -660
	local function railRun(a, b)
		if b - a > 1 then part(bw, "Rail", Vector3.new(b - a, 0.35, 0.5), CFrame.new((a + b) / 2, 4.1, BOARD_Z1 + 0.6), RAIL) end
	end
	local cuts = { -9, 9 }
	for _, s in STEPS do table.insert(cuts, s - 5) table.insert(cuts, s + 5) end
	table.sort(cuts)
	local cursor = x0
	for i = 1, #cuts, 2 do
		railRun(cursor, cuts[i])
		cursor = cuts[i + 1]
	end
	railRun(cursor, 660)
	for _, s in STEPS do
		for k = 0, 2 do part(bw, "Step", Vector3.new(9, 0.4, 1.4), CFrame.new(s, 0.9 - k * 0.4, BOARD_Z1 - 0.6 - k * 1.4), PLANK, Enum.Material.WoodPlanks) end
	end
	-- lamps and palms along the beach side, benches facing the sea between them
	for x = -640, 640, 40 do
		if not gapAt(x) and math.abs(x) > 14 then
			if (x / 40) % 2 == 0 then
				Kit.lamp(bw, x, BOARD_Z1 + 2.2, 10)
			else
				part(bw, "PalmBox", Vector3.new(4, 1.6, 4), CFrame.new(x, 1.8, BOARD_Z1 + 3), PLANK:Lerp(rgb(255, 255, 255), 0.2), Enum.Material.WoodPlanks)
				Kit.asset(bw, "Palm", Vector3.new(x, 2.4, BOARD_Z1 + 3), rng:NextNumber(0.85, 1.1))
			end
		end
	end
	for x = -620, 620, 80 do
		if math.abs(x) > 30 then Kit.bench(bw, x, BOARD_Z1 + 6, "-z") end
	end
	-- the snack kiosks on the road side of the boardwalk
	local KIOSKS = {
		{ "\u{1F366} ICE CREAM", rgb(255, 150, 200), { rgb(255, 255, 255), rgb(255, 110, 170) } },
		{ "\u{1F34B} LEMONADE", rgb(255, 220, 80), { rgb(255, 255, 255), rgb(255, 190, 40) } },
		{ "\u{1F32D} HOT DOGS", rgb(255, 120, 90), { rgb(255, 230, 120), rgb(230, 70, 60) } },
		{ "\u{1F37F} POPCORN", rgb(255, 90, 90), { rgb(255, 255, 255), rgb(230, 50, 60) } },
		{ "\u{1F964} SLUSHIES", rgb(90, 190, 255), { rgb(255, 255, 255), rgb(40, 140, 230) } },
		{ "\u{1F349} FRUIT CUPS", rgb(120, 220, 130), { rgb(255, 255, 255), rgb(60, 180, 90) } },
	}
	local KX = { -500, -300, -100, 100, 300, 500 }
	for i, x in KX do
		local k = KIOSKS[i]
		local kz = BOARD_Z0 - 5
		local f = CFrame.lookAt(Vector3.new(x, 1, kz), Vector3.new(x, 1, kz - 10)) -- (the counter faces the sea)
		local kiosk = Kit.folder(bw, "Kiosk")
		part(kiosk, "Body", Vector3.new(10, 7, 7), f * CFrame.new(0, 3.5, 0), k[2])
		part(kiosk, "Counter", Vector3.new(10.4, 0.5, 1.6), f * CFrame.new(0, 3.4, -4), rgb(250, 250, 246))
		part(kiosk, "Window", Vector3.new(8, 3, 0.2), f * CFrame.new(0, 5.1, -3.55), rgb(40, 40, 50))
		part(kiosk, "Roof", Vector3.new(11, 0.6, 8), f * CFrame.new(0, 7.3, 0), rgb(250, 250, 246))
		for s = 0, 4 do
			part(kiosk, "Awning", Vector3.new(2.2, 0.2, 3), f * CFrame.new(-4.4 + s * 2.2, 6.9, -4.8) * CFrame.Angles(math.rad(22), 0, 0), k[3][s % 2 + 1], Enum.Material.Fabric)
		end
		local sign = part(kiosk, "Sign", Vector3.new(10, 2.6, 0.4), f * CFrame.new(0, 9, -1), rgb(255, 255, 255))
		Kit.sign(sign, Enum.NormalId.Front, k[1], rgb(40, 30, 50), rgb(255, 255, 255), Enum.Font.LuckiestGuy)
		Kit.sign(sign, Enum.NormalId.Back, k[1], rgb(40, 30, 50), rgb(255, 255, 255), Enum.Font.LuckiestGuy)
		-- a tall striped umbrella by each, two stools at the counter
		for _, dx in { -3, 3 } do
			Kit.cylY(kiosk, "Stool", 1.2, 0.3, (f * CFrame.new(dx, 2.6, -6)).Position, k[3][2], Enum.Material.SmoothPlastic)
			part(kiosk, "StoolLeg", Vector3.new(0.3, 1.6, 0.3), f * CFrame.new(dx, 1.8, -6), rgb(200, 200, 206), Enum.Material.Metal)
		end
	end

	---------------------------------------------------------------------------
	-- the pier and the Ferris wheel
	---------------------------------------------------------------------------
	local pier = Kit.folder(m, "Pier")
	local PZ0, PZ1 = BOARD_Z1, -800 -- the walk
	part(pier, "Walk", Vector3.new(14, 0.8, PZ0 - PZ1), CFrame.new(0, 1.1, (PZ0 + PZ1) / 2), PLANK, Enum.Material.WoodPlanks)
	for z = PZ0 - 6, PZ1, -12 do
		for _, sx in { -1, 1 } do
			Kit.cylY(pier, "Pile", 1.2, 14, Vector3.new(sx * 6.4, -5.5, z), rgb(120, 90, 60), Enum.Material.Wood)
			part(pier, "Post", Vector3.new(0.4, 3, 0.4), CFrame.new(sx * 6.6, 2.9, z), RAIL)
		end
	end
	for _, sx in { -1, 1 } do
		part(pier, "Rail", Vector3.new(0.4, 0.35, PZ0 - PZ1), CFrame.new(sx * 6.6, 4.3, (PZ0 + PZ1) / 2), RAIL)
	end
	-- the arch at the start of the pier
	do
		local a = Kit.folder(pier, "Arch")
		for _, sx in { -1, 1 } do
			part(a, "ArchPost", Vector3.new(1.6, 16, 1.6), CFrame.new(sx * 8.6, 8.8, PZ0 - 2), rgb(255, 255, 255))
			Kit.ball(a, "ArchBall", 2.2, Vector3.new(sx * 8.6, 17.4, PZ0 - 2), rgb(255, 200, 60), Enum.Material.SmoothPlastic)
		end
		local board = part(a, "ArchSign", Vector3.new(18, 3.6, 0.6), CFrame.new(0, 14.4, PZ0 - 2), rgb(40, 170, 220))
		Kit.sign(board, Enum.NormalId.Front, "\u{1F3A1} SUNNY SHORES PIER", rgb(255, 255, 255), rgb(40, 170, 220), Enum.Font.LuckiestGuy, rgb(20, 60, 100))
		Kit.sign(board, Enum.NormalId.Back, "\u{1F3A1} SUNNY SHORES PIER", rgb(255, 255, 255), rgb(40, 170, 220), Enum.Font.LuckiestGuy, rgb(20, 60, 100))
	end
	-- the end deck
	local DZ = -830
	part(pier, "EndDeck", Vector3.new(60, 0.8, 60), CFrame.new(0, 1.1, DZ), PLANK, Enum.Material.WoodPlanks)
	for x = -26, 26, 13 do
		for z = DZ - 26, DZ + 26, 13 do
			Kit.cylY(pier, "Pile", 1.4, 14, Vector3.new(x, -5.5, z), rgb(120, 90, 60), Enum.Material.Wood)
		end
	end
	for _, e in { { 0, DZ - 30, 60, 0.4 }, { -30, DZ, 0.4, 60 }, { 30, DZ, 0.4, 60 } } do
		part(pier, "Rail", Vector3.new(e[3], 0.35, e[4]), CFrame.new(e[1], 4.3, e[2]), RAIL)
	end
	-- the Ferris wheel: two rims of 24 segments, spokes, a hub on an A-frame, 10 gondolas.
	-- The model "Rim" turns about the hub's Z; the gondolas are kept hanging level (Decor: "Wheel").
	do
		local R, HUB_Y, N = 24, 30, 10
		local hub = CFrame.new(0, HUB_Y, DZ)
		local wheel = Instance.new("Model")
		wheel.Name = "FerrisWheel"
		wheel.Parent = pier
		local hubPart = part(wheel, "Hub", Vector3.new(3.6, 3.6, 3.6), hub, rgb(250, 250, 246), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball })
		wheel.PrimaryPart = hubPart
		-- the A-frame legs down to the deck, front and back
		for _, dz in { -3, 3 } do
			for _, sx in { -1, 1 } do
				local foot = Vector3.new(sx * 16, 1.5, DZ + dz)
				local top = Vector3.new(0, HUB_Y, DZ + dz)
				local len = (top - foot).Magnitude
				part(wheel, "Leg", Vector3.new(1.2, len, 1.2), CFrame.lookAt((foot + top) / 2, top) * CFrame.Angles(math.rad(90), 0, 0), rgb(250, 250, 246), Enum.Material.Metal)
			end
		end
		local rim = Instance.new("Model")
		rim.Name = "Rim"
		rim.Parent = wheel
		local rimHub = part(rim, "RimHub", Vector3.new(2.4, 2.4, 6.4), hub, rgb(255, 200, 60), Enum.Material.SmoothPlastic)
		rim.PrimaryPart = rimHub
		local RIM_COLORS = { rgb(255, 90, 90), rgb(255, 200, 60), rgb(90, 200, 255), rgb(140, 220, 120), rgb(200, 130, 255), rgb(255, 150, 60) }
		local SEG = 24
		for k = 0, SEG - 1 do
			local a0, a1 = k / SEG * math.pi * 2, (k + 1) / SEG * math.pi * 2
			local p0 = Vector3.new(math.cos(a0) * R, math.sin(a0) * R, 0)
			local p1 = Vector3.new(math.cos(a1) * R, math.sin(a1) * R, 0)
			local c = (p0 + p1) / 2
			local len = (p1 - p0).Magnitude + 0.4
			for _, dz in { -2.6, 2.6 } do
				part(rim, "RimBar", Vector3.new(len, 0.7, 0.7), hub * CFrame.new(c + Vector3.new(0, 0, dz)) * CFrame.Angles(0, 0, math.atan2(p1.Y - p0.Y, p1.X - p0.X)), RIM_COLORS[k % #RIM_COLORS + 1], Enum.Material.SmoothPlastic)
			end
			if k % 2 == 0 then
				-- a light bulb on the rim
				Kit.ball(rim, "Bulb", 0.6, (hub * CFrame.new(p0 * 1.02 + Vector3.new(0, 0, -3.1))).Position, rgb(255, 245, 200), Enum.Material.Neon)
			end
		end
		for k = 0, N - 1 do
			local a = k / N * math.pi * 2
			local tip = Vector3.new(math.cos(a) * R, math.sin(a) * R, 0)
			for _, dz in { -2.6, 2.6 } do
				part(rim, "Spoke", Vector3.new(R, 0.35, 0.35), hub * CFrame.new(tip / 2 + Vector3.new(0, 0, dz)) * CFrame.Angles(0, 0, a), rgb(250, 250, 246), Enum.Material.Metal)
			end
			-- the gondola: a cabin hanging from a bar, its pivot at the bar
			local g = Instance.new("Model")
			g.Name = "Gondola"
			g:SetAttribute("Index", k)
			g.Parent = wheel
			local hang = hub * CFrame.new(tip)
			local bar = part(g, "Hanger", Vector3.new(0.4, 0.4, 5.6), hang, rgb(250, 250, 246), Enum.Material.Metal)
			g.PrimaryPart = bar
			local col = RIM_COLORS[k % #RIM_COLORS + 1]
			part(g, "Arm", Vector3.new(0.3, 2.4, 0.3), hang * CFrame.new(0, -1.2, 0), rgb(250, 250, 246), Enum.Material.Metal)
			part(g, "Cabin", Vector3.new(3.6, 2.4, 3.6), hang * CFrame.new(0, -3.4, 0), col)
			part(g, "CabinRoof", Vector3.new(4, 0.5, 4), hang * CFrame.new(0, -2.2, 0), rgb(250, 250, 246))
			part(g, "CabinWindow", Vector3.new(3.7, 1, 3.7), hang * CFrame.new(0, -3.1, 0), rgb(170, 220, 250), Enum.Material.Glass, { Transparency = 0.3 })
		end
		wheel:SetAttribute("SpinSpeed", 0.12)
		wheel:SetAttribute("Radius", R)
		pcall(function() wheel.ModelStreamingMode = Enum.ModelStreamingMode.Atomic end)
		CollectionService:AddTag(wheel, "Wheel")
	end

	---------------------------------------------------------------------------
	-- the lighthouse on the rocks at the east end
	---------------------------------------------------------------------------
	do
		local lh = Kit.folder(m, "Lighthouse")
		local x, z = 600, -760
		Kit.rocks(lh, x, z, 14, rgb(130, 126, 120), -1)
		Kit.rocks(lh, x - 14, z + 10, 8, rgb(140, 136, 128), -1)
		Kit.rocks(lh, x + 12, z + 8, 9, rgb(140, 136, 128), -1)
		part(lh, "Base", Vector3.new(16, 4, 16), CFrame.new(x, 1, z), rgb(170, 166, 158), Enum.Material.Cobblestone)
		local h, d = 4, 10
		for i = 0, 7 do
			Kit.cylY(lh, "Tower", d - i * 0.5, h, Vector3.new(x, 3 + h / 2 + i * h, z), i % 2 == 0 and rgb(235, 60, 55) or rgb(250, 250, 246))
		end
		local topY = 3 + 8 * h
		Kit.cylY(lh, "Gallery", 9, 0.6, Vector3.new(x, topY + 0.3, z), rgb(40, 40, 46), Enum.Material.Metal)
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			part(lh, "GalleryRail", Vector3.new(0.25, 1.6, 0.25), CFrame.new(x + math.cos(a) * 4.3, topY + 1.4, z + math.sin(a) * 4.3), rgb(40, 40, 46), Enum.Material.Metal)
		end
		Kit.cylY(lh, "Lantern", 5, 4, Vector3.new(x, topY + 2.6, z), rgb(200, 235, 255), Enum.Material.Glass, { Transparency = 0.35 })
		local light = Kit.ball(lh, "Light", 2.4, Vector3.new(x, topY + 2.6, z), rgb(255, 245, 190), Enum.Material.Neon)
		Kit.light(light, 40, 1.4, rgb(255, 240, 190))
		Kit.cylY(lh, "Cap", 5.6, 1, Vector3.new(x, topY + 5, z), rgb(235, 60, 55))
		Kit.ball(lh, "Dome", 4.6, Vector3.new(x, topY + 5.6, z), rgb(235, 60, 55))
		part(lh, "Door", Vector3.new(2.6, 4.4, 0.4), CFrame.new(x, 5.2, z + 4.7), rgb(40, 110, 170))
	end

	---------------------------------------------------------------------------
	-- palms on the beach, and the side edges: rocks and pines where the land meets the sea
	---------------------------------------------------------------------------
	for x = -620, 620, 95 do
		if math.abs(x) > 30 then Kit.asset(beach, "Palm", Vector3.new(x + rng:NextNumber(-10, 10), -0.2, -652 + rng:NextNumber(-2, 4)), rng:NextNumber(0.9, 1.25)) end
	end
	for _, sx in { -1, 1 } do
		for z = -575, -640, -22 do Kit.pine(m, sx * 780 + rng:NextNumber(-4, 4), z, rng:NextNumber(1.1, 1.5)) end
		Kit.rocks(m, sx * 700, -690, 12, rgb(135, 130, 124), -1)
		Kit.rocks(m, sx * 760, -700, 16, rgb(135, 130, 124), -1)
	end
	return m
end

return Shores
