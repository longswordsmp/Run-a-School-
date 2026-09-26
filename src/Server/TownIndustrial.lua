-- ServerScriptService.Server.TownIndustrial
-- VexCorp Industrial (docs/TOWN.md): east of the school area, through the VEXCORP INDUSTRIAL gate,
-- and the Top Secret Lair underneath it.
--   the checkpoint (585, 0)       a guard booth and a boom barrier over the drive
--   VexCorp Tower (690, 0)        a purple glass tower, the lobby you can walk into (reception, a
--                                 statue of Dr. Vex, the EXECUTIVE ELEVATOR down to the Lair)
--   warehouses (660, ±260)        roll-up doors, stacks of homework crates, a forklift
--   the yards                     shipping containers (750, ±400), the loading dock and two VexCorp
--                                 trucks (610, 160), the van lot (610, -160), Mutagen X tanks (760, -150)
--   the Lair (y -160)             a cavern under the Tower: the elevator lobby, Vex's throne and her
--                                 wall of monitors, the Homework Machine's core over an acid pit on
--                                 catwalks, Mutagen X vats, laser grids, cages of captured kids, the
--                                 Tiny Professor's pod
-- The elevator itself (lobby <-> Lair) is TownService's (it checks the Lair is open for you).
local Industrial = {}

Industrial.LAIR_Y = -160
Industrial.ELEVATOR_TOP = Vector3.new(704, 3.5, 14) -- in front of the lobby elevator (where you arrive back)
Industrial.ELEVATOR_BOTTOM = Vector3.new(610, -157, 0) -- in front of the Lair's elevator, on its west wall

function Industrial.build(town, Kit)
	local rgb = Kit.rgb
	local part, C = Kit.part, Kit.C
	local m = Kit.folder(town, "Industrial")
	local PURPLE, DEEP, TOXIC = rgb(110, 48, 160), rgb(60, 26, 90), rgb(120, 255, 60)
	local CONCRETE = rgb(150, 150, 156)

	-- the yard is paved; the drive and the service road on top
	Kit.pave(m, 560, 790, -550, 550, rgb(120, 122, 128), Enum.Material.Concrete, 0.1)
	Kit.road(m, 570, 0, 660, 0, 24)
	Kit.road(m, 600, -470, 600, 470, 20)
	for z = -440, 440, 60 do Kit.lamp(m, 588, z, 12) end

	-- the checkpoint: a booth, a boom barrier (raised), a warning sign
	local cp = Kit.folder(m, "Checkpoint")
	part(cp, "Booth", Vector3.new(6, 8, 6), CFrame.new(585, 4, -18), rgb(230, 230, 235))
	part(cp, "BoothRoof", Vector3.new(7, 0.6, 7), CFrame.new(585, 8.3, -18), PURPLE)
	part(cp, "BoothWindow", Vector3.new(0.2, 3, 5), CFrame.new(581.9, 5, -18), C.glass, Enum.Material.Glass, { Transparency = 0.3 })
	local arm = part(cp, "Boom", Vector3.new(0.6, 0.6, 20), CFrame.new(585, 9, -3) * CFrame.Angles(math.rad(70), 0, 0), rgb(245, 245, 245))
	for k = 0, 4 do part(cp, "BoomStripe", Vector3.new(0.65, 0.65, 1.8), arm.CFrame * CFrame.new(0, 0, -8 + k * 4), rgb(220, 40, 50)) end
	local warn = part(cp, "Warning", Vector3.new(0.4, 5, 12), CFrame.new(578, 6, 22), rgb(250, 220, 60))
	Kit.sign(warn, Enum.NormalId.Left, "\u{26A0}\u{FE0F} VEXCORP\nAUTHORIZED PERSONNEL ONLY", rgb(30, 20, 20), rgb(250, 220, 60), Enum.Font.GothamBlack)
	for _, dz in { -5, 5 } do part(cp, "WarnPost", Vector3.new(0.5, 4, 0.5), CFrame.new(578, 2, 22 + dz), C.iron, Enum.Material.Metal) end

	---------------------------------------------------------------------------
	-- VexCorp Tower
	---------------------------------------------------------------------------
	local tw = Kit.folder(m, "VexCorpTower")
	local TX, TZ, TW, TH = 690, 0, 44, 150
	-- the glass curtain wall, floor bands, corner pillars, the crown and the helipad
	part(tw, "TowerGlass", Vector3.new(TW, TH - 20, TW), CFrame.new(TX, 20 + (TH - 20) / 2, TZ), rgb(70, 40, 110), Enum.Material.Glass, { Transparency = 0.05, Reflectance = 0.2 })
	for y = 26, TH, 8 do
		part(tw, "Band", Vector3.new(TW + 0.6, 0.8, TW + 0.6), CFrame.new(TX, y, TZ), DEEP, Enum.Material.Metal)
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			part(tw, "Pillar", Vector3.new(3, TH, 3), CFrame.new(TX + sx * TW / 2, TH / 2, TZ + sz * TW / 2), rgb(40, 30, 50), Enum.Material.Metal)
		end
	end
	part(tw, "Crown", Vector3.new(TW + 2, 8, TW + 2), CFrame.new(TX, TH + 4, TZ), DEEP, Enum.Material.Metal)
	for _, face in { { Enum.NormalId.Left, Vector3.new(-TW / 2 - 1.1, 0, 0) }, { Enum.NormalId.Front, Vector3.new(0, 0, -TW / 2 - 1.1) }, { Enum.NormalId.Back, Vector3.new(0, 0, TW / 2 + 1.1) } } do
		local logo = part(tw, "Logo", Vector3.new(TW - 4, 6, TW - 4), CFrame.new(Vector3.new(TX, TH + 4, TZ) + face[2] * 0.001), DEEP, nil, { Transparency = 1, CanCollide = false })
		Kit.sign(logo, face[1], "VEXCORP", TOXIC, nil, Enum.Font.LuckiestGuy, rgb(20, 60, 10))
	end
	Kit.cylY(tw, "Helipad", 30, 0.6, Vector3.new(TX, TH + 8.3, TZ), rgb(60, 60, 66))
	local h = part(tw, "HelipadH", Vector3.new(10, 0.1, 10), CFrame.new(TX, TH + 8.65, TZ), rgb(60, 60, 66), nil, { Transparency = 1 })
	Kit.sign(h, Enum.NormalId.Top, "H", C.white, nil, Enum.Font.GothamBlack)
	local beacon = part(tw, "Beacon", Vector3.new(1.4, 1.4, 1.4), CFrame.new(TX + 20, TH + 10, TZ + 20), rgb(255, 40, 60), Enum.Material.Neon)
	Kit.light(beacon, 40, 2, rgb(255, 40, 60))
	-- the lobby: two storeys you can walk into, the front facing the drive (-x)
	local lobby, at = Kit.hollow(tw, {
		name = "Lobby", x = TX, z = TZ, w = TW, d = TW, h = 20, face = "-x",
		wall = rgb(50, 36, 70), trim = rgb(200, 170, 240), roof = DEEP, floor = rgb(235, 232, 240), doorW = 10, doorH = 11,
		ceiling = rgb(60, 44, 84),
		sign = { text = "VEXCORP HEADQUARTERS", bg = DEEP, color = TOXIC, w = 30, h = 3.6 },
	})
	-- (in the lobby's frame the front is +z, the elevator wall at the back is -z)
	part(lobby, "Carpet", Vector3.new(8, 0.1, 30), at(0, 0.62, 2), rgb(120, 30, 60), Enum.Material.Fabric)
	-- the reception desk and ROBO-7's spot
	part(lobby, "Reception", Vector3.new(14, 4, 4), at(0, 2.6, 6), rgb(235, 235, 240), Enum.Material.Marble)
	part(lobby, "ReceptionTop", Vector3.new(15, 0.4, 5), at(0, 4.8, 6), PURPLE)
	local recSign = part(lobby, "ReceptionSign", Vector3.new(10, 1.6, 0.3), at(0, 3, 8.2) * CFrame.Angles(0, math.rad(180), 0), PURPLE)
	Kit.sign(recSign, Enum.NormalId.Front, "RECEPTION", C.white, PURPLE, Enum.Font.GothamBlack)
	-- the statue of Dr. Vex on a plinth
	part(lobby, "Plinth", Vector3.new(5, 3, 5), at(-14, 2, -6), rgb(235, 235, 240), Enum.Material.Marble)
	part(lobby, "StatueBody", Vector3.new(2.4, 5, 1.6), at(-14, 6, -6), rgb(200, 170, 90), Enum.Material.Metal)
	Kit.ball(lobby, "StatueHead", 1.6, (at(-14, 9.3, -6)).Position, rgb(200, 170, 90), Enum.Material.Metal)
	part(lobby, "StatueShoulders", Vector3.new(4, 0.9, 1.8), at(-14, 8.2, -6), rgb(200, 170, 90), Enum.Material.Metal)
	-- the portraits and the motto
	local motto = part(lobby, "Motto", Vector3.new(24, 2.4, 0.3), at(0, 15, -20.8), DEEP)
	Kit.sign(motto, Enum.NormalId.Back, "HOMEWORK IS THE FUTURE", TOXIC, DEEP, Enum.Font.LuckiestGuy)
	-- the EXECUTIVE ELEVATOR at the back wall
	local ELEV = part(lobby, "ElevatorDoors", Vector3.new(7, 10, 0.4), at(14, 5.6, -20.9), rgb(200, 190, 140), Enum.Material.Metal)
	part(lobby, "ElevatorFrame", Vector3.new(8.4, 11, 0.3), at(14, 5.9, -21.05), rgb(40, 30, 50), Enum.Material.Metal)
	local elevSign = part(lobby, "ElevatorSign", Vector3.new(7, 1.2, 0.3), at(14, 12, -20.8), rgb(20, 16, 26))
	Kit.sign(elevSign, Enum.NormalId.Back, "EXECUTIVE ELEVATOR", rgb(255, 80, 80), rgb(20, 16, 26), Enum.Font.GothamBlack)
	ELEV:SetAttribute("Elevator", "down")
	-- a queue of VexCorp homework on a conveyor in the lobby window
	for k = 0, 5 do
		part(lobby, "HomeworkPile", Vector3.new(2.4, 1.6 + (k % 3) * 0.6, 3), at(-16 + k * 2.6, 1.4, 17), rgb(250, 248, 240))
	end

	---------------------------------------------------------------------------
	-- warehouses of homework, north and south
	---------------------------------------------------------------------------
	for _, sz in { -1, 1 } do
		local wz = sz * 260
		local wh, wat = Kit.hollow(m, {
			name = "Warehouse", x = 670, z = wz, w = 70, d = 50, h = 22, face = "-x",
			wall = rgb(150, 156, 166), trim = PURPLE, roof = rgb(90, 94, 104), floor = rgb(140, 140, 146), doorW = 16, doorH = 14,
			material = Enum.Material.CorrodedMetal,
			sign = { text = sz > 0 and "WAREHOUSE A \u{2022} HOMEWORK" or "WAREHOUSE B \u{2022} HOMEWORK", bg = PURPLE, color = C.white, w = 40, h = 3.6 },
		})
		-- racks of crates stamped HOMEWORK
		for rx = -24, 24, 12 do
			part(wh, "Rack", Vector3.new(3, 14, 30), wat(rx, 7.6, -6), rgb(60, 70, 150), Enum.Material.Metal)
			for level = 0, 2 do
				for k = 0, 4 do
					local crate = part(wh, "Crate", Vector3.new(2.6, 3.4, 5), wat(rx, 2.6 + level * 4.6, -17 + k * 5.6), rgb(190, 150, 100), Enum.Material.WoodPlanks)
					if level == 0 and k % 2 == 0 then
						Kit.sign(crate, Enum.NormalId.Right, "HOMEWORK", rgb(90, 30, 30), nil, Enum.Font.Arcade)
					end
				end
			end
		end
		-- a forklift
		part(wh, "Forklift", Vector3.new(4, 3, 6), wat(0, 2.1, 14), rgb(250, 200, 50))
		part(wh, "ForkMast", Vector3.new(3.4, 7, 0.4), wat(0, 4.1, 17.2), C.iron, Enum.Material.Metal)
		for _, dx in { -1, 1 } do part(wh, "Fork", Vector3.new(0.4, 0.3, 4), wat(dx, 1.2, 19), C.iron, Enum.Material.Metal) end
		part(wh, "ForkCage", Vector3.new(3.6, 4, 0.2), wat(0, 5.6, 12.3), C.iron, Enum.Material.Metal)
	end

	-- the shipping containers, stacked
	local ccolors = { rgb(200, 60, 50), rgb(40, 110, 180), rgb(60, 150, 80), rgb(230, 170, 40), PURPLE }
	for _, sz in { -1, 1 } do
		for i = 0, 5 do
			for level = 0, (i % 3) do
				local c = part(m, "Container", Vector3.new(24, 8, 8.4), CFrame.new(740 + (i % 2) * 26, 4.1 + level * 8.1, sz * (370 + math.floor(i / 2) * 10)), ccolors[(i + level) % #ccolors + 1], Enum.Material.CorrodedMetal)
				for k = -10, 10, 2 do part(m, "Rib", Vector3.new(0.3, 7.6, 8.6), c.CFrame * CFrame.new(k, 0, 0), c.Color:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.CorrodedMetal) end
			end
		end
	end

	-- the loading dock and two VexCorp trucks
	part(m, "Dock", Vector3.new(14, 4, 60), CFrame.new(628, 2, 160), CONCRETE, Enum.Material.Concrete)
	for i, dz in { -12, 12 } do
		local t = Kit.folder(m, "Truck")
		-- (backed up to the dock, the cab to the east)
		local cf = CFrame.new(649, 0, 160 + dz) * CFrame.Angles(0, math.pi, 0)
		part(t, "Trailer", Vector3.new(22, 9, 8), cf * CFrame.new(3, 6.4, 0), rgb(240, 240, 245), Enum.Material.Metal)
		local side = part(t, "TrailerLogo", Vector3.new(16, 4, 0.2), cf * CFrame.new(3, 6.4, 4.12), PURPLE, nil, { Transparency = 1 })
		Kit.sign(side, Enum.NormalId.Back, "VEXCORP HOMEWORK", PURPLE, nil, Enum.Font.LuckiestGuy)
		part(t, "Cab", Vector3.new(6, 7, 7.6), cf * CFrame.new(-11, 4.6, 0), PURPLE, Enum.Material.Metal)
		part(t, "CabGlass", Vector3.new(0.2, 2.4, 6.4), cf * CFrame.new(-14.05, 6, 0), rgb(40, 50, 70), Enum.Material.Glass)
		for _, dx in { -12, -4, 8, 12 } do
			for _, s in { -1, 1 } do
				local w = part(t, "Wheel", Vector3.new(1, 2.6, 2.6), cf * CFrame.new(dx, 1.3, s * 3.7) * CFrame.Angles(0, math.rad(90), 0), rgb(24, 24, 26))
				w.Shape = Enum.PartType.Cylinder
			end
		end
		_ = i
	end

	-- the van lot
	Kit.pave(m, 612, 660, -200, -120, C.asphalt, Enum.Material.Asphalt, 0.14)
	for z = -196, -124, 12 do part(m, "Stall", Vector3.new(16, 0.05, 0.3), CFrame.new(636, 0.37, z), C.white) end
	for i, z in { -190, -166, -142 } do Kit.car(m, 636, z, "+x", PURPLE) _ = i end

	-- Mutagen X tanks, glowing
	for i, spot in { { 755, -140 }, { 775, -170 }, { 755, -200 } } do
		Kit.cylY(m, "Tank", 14, 20, Vector3.new(spot[1], 10, spot[2]), rgb(200, 205, 212), Enum.Material.Metal)
		Kit.cylY(m, "TankBand", 14.4, 1, Vector3.new(spot[1], 14, spot[2]), PURPLE, Enum.Material.Metal)
		local glow = Kit.cylY(m, "TankGlow", 14.3, 2, Vector3.new(spot[1], 8, spot[2]), TOXIC, Enum.Material.Neon)
		Kit.light(glow, 20, 1, TOXIC)
		local lbl = part(m, "TankLabel", Vector3.new(0.2, 3, 8), CFrame.new(spot[1] - 7.2, 16.5, spot[2]), rgb(250, 220, 60))
		Kit.sign(lbl, Enum.NormalId.Left, "MUTAGEN X", rgb(30, 20, 20), rgb(250, 220, 60), Enum.Font.GothamBlack)
		_ = i
	end
	for k = 0, 3 do Kit.cylX(m, "Pipe", 1.6, 30, Vector3.new(740, 3 + k * 0.1, -120 - k * 20), rgb(170, 175, 185), Enum.Material.Metal) end

	---------------------------------------------------------------------------
	-- the yard: painted lanes, hazard stripes, drums, pallets, cones, barriers, a guard tower and
	-- security cameras on poles (so the concrete isn't one empty field)
	---------------------------------------------------------------------------
	local yard = Kit.folder(m, "Yard")
	local rng2 = Random.new(9)
	for z = -520, 520, 40 do
		part(yard, "LaneLine", Vector3.new(0.4, 0.05, 20), CFrame.new(720, 0.33, z), rgb(250, 220, 60))
	end
	for _, spot in { { 640, 60 }, { 640, -60 }, { 720, 100 }, { 720, -100 }, { 650, 420 }, { 650, -420 }, { 700, 330 }, { 700, -330 } } do
		-- a pallet stack with drums
		for k = 0, 2 do
			part(yard, "Pallet", Vector3.new(5, 0.6, 5), CFrame.new(spot[1] + k * 6, 0.4, spot[2]), rgb(170, 130, 80), Enum.Material.WoodPlanks)
			for d = 0, 3 do
				local drum = ({ rgb(40, 90, 200), rgb(250, 200, 40), PURPLE })[(k + d) % 3 + 1]
				Kit.cylY(yard, "Drum", 2, 3.2, Vector3.new(spot[1] + k * 6 - 1.2 + (d % 2) * 2.4, 2.3, spot[2] - 1.2 + math.floor(d / 2) * 2.4), drum, Enum.Material.Metal)
			end
		end
		for c = 0, 2 do
			local cone = part(yard, "Cone", Vector3.new(1.2, 2, 1.2), CFrame.new(spot[1] - 5 + rng2:NextNumber(-2, 2), 1, spot[2] + 5 + c * 2), rgb(255, 120, 30))
			part(yard, "ConeStripe", Vector3.new(1.25, 0.35, 1.25), cone.CFrame * CFrame.new(0, 0.2, 0), rgb(250, 250, 250))
		end
	end
	-- jersey barriers along the drive
	for x = 612, 652, 8 do
		for _, s in { -1, 1 } do
			part(yard, "Barrier", Vector3.new(6.5, 2.6, 1.6), CFrame.new(x, 1.3, s * 16), rgb(215, 215, 220), Enum.Material.Concrete)
		end
	end
	-- hazard stripes in front of the warehouse doors
	for _, sz in { -1, 1 } do
		for k = -8, 8, 2 do
			part(yard, "Hazard", Vector3.new(4, 0.05, 1), CFrame.new(632, 0.33, sz * 260 + k) * CFrame.Angles(0, math.rad(45), 0), k % 4 == 0 and rgb(250, 210, 40) or rgb(30, 30, 30))
		end
	end
	-- a guard tower by the gate and cameras on poles round the yard
	local gt = Kit.folder(yard, "GuardTower")
	for _, dx in { -2.5, 2.5 } do for _, dz in { -2.5, 2.5 } do part(gt, "Leg", Vector3.new(0.8, 18, 0.8), CFrame.new(566 + dx, 9, 40 + dz), C.iron, Enum.Material.Metal) end end
	part(gt, "Cabin", Vector3.new(8, 6, 8), CFrame.new(566, 21, 40), rgb(60, 60, 70), Enum.Material.Metal)
	part(gt, "CabinGlass", Vector3.new(8.2, 2.4, 8.2), CFrame.new(566, 22, 40), rgb(40, 50, 70), Enum.Material.Glass, { Transparency = 0.2 })
	part(gt, "CabinRoof", Vector3.new(9, 0.6, 9), CFrame.new(566, 24.3, 40), PURPLE, Enum.Material.Metal)
	local spot = part(gt, "Spotlight", Vector3.new(1.4, 1.4, 2), CFrame.new(566, 25.4, 40) * CFrame.Angles(math.rad(-20), math.rad(200), 0), rgb(255, 250, 230), Enum.Material.Neon)
	local sl = Instance.new("SpotLight")
	sl.Range, sl.Angle, sl.Brightness, sl.Face = 60, 30, 2, Enum.NormalId.Front
	sl.Parent = spot
	for _, pos in { { 600, 120 }, { 600, -120 }, { 760, 260 }, { 760, -260 }, { 640, 480 }, { 640, -480 } } do
		part(yard, "CamPole", Vector3.new(0.5, 12, 0.5), CFrame.new(pos[1], 6, pos[2]), C.iron, Enum.Material.Metal)
		part(yard, "Camera", Vector3.new(1.2, 0.8, 1.8), CFrame.new(pos[1], 12.2, pos[2]) * CFrame.Angles(math.rad(-20), rng2:NextNumber(0, 6), 0), rgb(225, 225, 230))
		part(yard, "CamLight", Vector3.new(0.3, 0.3, 0.3), CFrame.new(pos[1], 12.6, pos[2]), rgb(255, 40, 40), Enum.Material.Neon)
	end
	-- a strip of grass and trees along the east fence
	part(yard, "Verge", Vector3.new(16, 0.3, 1080), CFrame.new(786, 0.26, 0), rgb(96, 186, 78), Enum.Material.Grass)
	for z = -520, 520, 30 do Kit.tree(yard, 786, z + rng2:NextNumber(-5, 5), rng2:NextNumber(0.9, 1.2)) end

	---------------------------------------------------------------------------
	-- the Top Secret Lair
	---------------------------------------------------------------------------
	local L = Industrial.LAIR_Y
	local lair = Kit.folder(m, "Lair")
	local ROCK, DARKROCK = rgb(56, 48, 62), rgb(36, 30, 42)
	local X0, X1, Z0, Z1 = 600, 780, -90, 90
	local CX, CZ = (X0 + X1) / 2, (Z0 + Z1) / 2
	-- the cavern: floor, rock walls, a ceiling with stalactites
	part(lair, "LairFloor", Vector3.new(X1 - X0, 2, Z1 - Z0), CFrame.new(CX, L - 1, CZ), rgb(46, 40, 52), Enum.Material.Slate)
	part(lair, "LairCeiling", Vector3.new(X1 - X0, 4, Z1 - Z0), CFrame.new(CX, L + 62, CZ), DARKROCK, Enum.Material.Rock)
	part(lair, "LairWall", Vector3.new(X1 - X0, 64, 4), CFrame.new(CX, L + 30, Z0), ROCK, Enum.Material.Rock)
	part(lair, "LairWall", Vector3.new(X1 - X0, 64, 4), CFrame.new(CX, L + 30, Z1), ROCK, Enum.Material.Rock)
	part(lair, "LairWall", Vector3.new(4, 64, Z1 - Z0), CFrame.new(X0, L + 30, CZ), ROCK, Enum.Material.Rock)
	part(lair, "LairWall", Vector3.new(4, 64, Z1 - Z0), CFrame.new(X1, L + 30, CZ), ROCK, Enum.Material.Rock)
	local rng = Random.new(3)
	for _ = 1, 40 do
		local x, z = rng:NextNumber(X0 + 8, X1 - 8), rng:NextNumber(Z0 + 8, Z1 - 8)
		local len = rng:NextNumber(4, 12)
		part(lair, "Stalactite", Vector3.new(2, len, 2), CFrame.new(x, L + 60 - len / 2, z) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), DARKROCK, Enum.Material.Rock)
	end
	for _ = 1, 24 do
		local a = rng:NextNumber(0, math.pi * 2)
		local x = rng:NextInteger(0, 1) == 0 and rng:NextNumber(X0 + 4, X0 + 10) or rng:NextNumber(X1 - 10, X1 - 4)
		local z = rng:NextNumber(Z0 + 6, Z1 - 6)
		part(lair, "Boulder", Vector3.new(rng:NextNumber(5, 10), rng:NextNumber(6, 16), rng:NextNumber(5, 10)), CFrame.new(x, L + 4, z) * CFrame.Angles(0, a, 0), ROCK, Enum.Material.Rock)
	end
	-- the acid pit in the middle, under the Machine, with catwalks across it
	part(lair, "AcidPit", Vector3.new(70, 1, 70), CFrame.new(CX, L + 0.2, CZ), TOXIC, Enum.Material.Neon, { Transparency = 0.1 })
	for _, s in { -1, 1 } do
		part(lair, "PitRim", Vector3.new(74, 2, 2), CFrame.new(CX, L + 1, CZ + s * 36), rgb(60, 60, 66), Enum.Material.DiamondPlate)
		part(lair, "PitRim", Vector3.new(2, 2, 74), CFrame.new(CX + s * 36, L + 1, CZ), rgb(60, 60, 66), Enum.Material.DiamondPlate)
	end
	for _, s in { -1, 1 } do
		part(lair, "Catwalk", Vector3.new(70, 1, 6), CFrame.new(CX, L + 8, CZ + s * 14), rgb(80, 80, 88), Enum.Material.DiamondPlate)
		part(lair, "CatwalkRail", Vector3.new(70, 2.6, 0.3), CFrame.new(CX, L + 9.8, CZ + s * 17), rgb(220, 60, 60), Enum.Material.Metal)
		part(lair, "CatwalkRail", Vector3.new(70, 2.6, 0.3), CFrame.new(CX, L + 9.8, CZ + s * 11), rgb(220, 60, 60), Enum.Material.Metal)
		for k = -30, 30, 15 do part(lair, "CatwalkPost", Vector3.new(1, 8, 1), CFrame.new(CX + k, L + 4, CZ + s * 14), rgb(60, 60, 66), Enum.Material.Metal) end
		-- ramps up to the catwalks at both ends
		Kit.wedge(lair, "Ramp", Vector3.new(6, 8, 16), Vector3.new(CX - 43, L + 4, CZ + s * 14), "-x", rgb(80, 80, 88), Enum.Material.DiamondPlate)
		Kit.wedge(lair, "Ramp", Vector3.new(6, 8, 16), Vector3.new(CX + 43, L + 4, CZ + s * 14), "+x", rgb(80, 80, 88), Enum.Material.DiamondPlate)
	end
	local acidLight = part(lair, "AcidGlow", Vector3.new(1, 1, 1), CFrame.new(CX, L + 3, CZ), TOXIC, nil, { Transparency = 1, CanCollide = false })
	Kit.light(acidLight, 60, 1.5, TOXIC)
	-- the Homework Machine's core: a column of rings round a glowing heart
	local core = Kit.folder(lair, "MachineCore")
	Kit.cylY(core, "CoreBase", 20, 6, Vector3.new(CX, L + 3, CZ), rgb(40, 36, 46), Enum.Material.Metal)
	Kit.cylY(core, "CoreColumn", 8, 40, Vector3.new(CX, L + 26, CZ), rgb(70, 60, 90), Enum.Material.Metal)
	local heart = Kit.ball(core, "CoreHeart", 10, Vector3.new(CX, L + 24, CZ), rgb(255, 60, 200), Enum.Material.Neon)
	Kit.light(heart, 50, 3, rgb(255, 80, 200))
	heart:SetAttribute("MachineHeart", true)
	for k = 0, 4 do
		Kit.cylY(core, "CoreRing", 16 - k, 1, Vector3.new(CX, L + 12 + k * 7, CZ), k % 2 == 0 and PURPLE or TOXIC, Enum.Material.Neon)
	end
	for k = 0, 5 do
		local a = math.rad(k * 60)
		Kit.cylX(core, "Cable", 1.4, 34, Vector3.new(CX + math.cos(a) * 17, L + 40, CZ + math.sin(a) * 17), rgb(30, 30, 36), Enum.Material.Metal)
	end
	-- Vex's throne on a dais at the east end, facing her wall of monitors across the pit... no,
	-- facing the elevator (west), with the monitor wall behind her
	local dais = Kit.folder(lair, "Throne")
	part(dais, "Dais", Vector3.new(22, 4, 30), CFrame.new(X1 - 20, L + 2, CZ), rgb(70, 30, 60), Enum.Material.Marble)
	for i = 0, 2 do part(dais, "DaisStep", Vector3.new(3, 1.3 * (i + 1), 16), CFrame.new(X1 - 32.5 + i * 1.5 - 3, L + 0.65 * (i + 1), CZ), rgb(70, 30, 60), Enum.Material.Marble) end
	part(dais, "ThroneSeat", Vector3.new(5, 2.4, 5), CFrame.new(X1 - 18, L + 5.2, CZ), PURPLE, Enum.Material.Fabric)
	part(dais, "ThroneBack", Vector3.new(1.6, 12, 7), CFrame.new(X1 - 15.6, L + 10, CZ), PURPLE, Enum.Material.Fabric)
	part(dais, "ThroneTrim", Vector3.new(1.8, 1.2, 8), CFrame.new(X1 - 15.6, L + 16.4, CZ), rgb(220, 190, 90), Enum.Material.Metal)
	for _, s in { -1, 1 } do part(dais, "ThroneArm", Vector3.new(5, 2.2, 1.2), CFrame.new(X1 - 18, L + 6.6, CZ + s * 3), PURPLE, Enum.Material.Fabric) end
	-- the monitor wall
	local screens = {
		"HOMEWORK LEVELS\n\u{2588}\u{2588}\u{2588}\u{2588}\u{2588}\u{2588}\u{2588}\u{2588}\u{2588}\u{2591} 99%",
		"RECESS REMAINING\n00:00:03",
		"TARGET: RECESS ROW\nALL SCHOOLS",
		"MUTAGEN X\nTANKS: FULL",
		"TINY PROFESSOR\nBRAIN LINK: 87%",
		"KICKBALL\nBANNED",
	}
	for i, text in screens do
		local row, col = math.floor((i - 1) / 3), (i - 1) % 3
		local s = part(dais, "Monitor", Vector3.new(1, 10, 16), CFrame.new(X1 - 4, L + 14 + row * 12, CZ - 18 + col * 18), rgb(20, 20, 26), Enum.Material.Metal)
		local glass = part(dais, "Screen", Vector3.new(0.2, 9, 15), CFrame.new(X1 - 4.6, L + 14 + row * 12, CZ - 18 + col * 18), rgb(10, 30, 20), Enum.Material.Neon, { Transparency = 0.1 })
		Kit.sign(glass, Enum.NormalId.Left, text, TOXIC, rgb(8, 22, 14), Enum.Font.Arcade)
		_ = s
	end
	-- Mutagen X vats along the north wall
	for k = 0, 5 do
		local x = X0 + 30 + k * 22
		Kit.cylY(lair, "VatBase", 8, 2, Vector3.new(x, L + 1, Z1 - 10), rgb(60, 60, 66), Enum.Material.Metal)
		local vat = Kit.cylY(lair, "Vat", 7, 14, Vector3.new(x, L + 9, Z1 - 10), TOXIC, Enum.Material.Glass, { Transparency = 0.35 })
		_ = vat
		Kit.cylY(lair, "VatCap", 8, 1.4, Vector3.new(x, L + 16.7, Z1 - 10), rgb(60, 60, 66), Enum.Material.Metal)
		local bubbles = part(lair, "Bubbles", Vector3.new(1, 1, 1), CFrame.new(x, L + 3, Z1 - 10), TOXIC, nil, { Transparency = 1, CanCollide = false })
		local pe = Instance.new("ParticleEmitter")
		pe.Rate = 6
		pe.Lifetime = NumberRange.new(2, 3)
		pe.Speed = NumberRange.new(3, 5)
		pe.Size = NumberSequence.new(0.5, 0.2)
		pe.Color = ColorSequence.new(rgb(200, 255, 160))
		pe.SpreadAngle = Vector2.new(20, 20)
		pe.Parent = bubbles
	end
	-- cages of captured kids along the south wall (the kids are placed by the story)
	for k = 0, 4 do
		local x = X0 + 36 + k * 24
		local cage = Kit.folder(lair, "Cage")
		cage:SetAttribute("Cage", k + 1)
		part(cage, "CageFloor", Vector3.new(10, 1, 10), CFrame.new(x, L + 0.5, Z0 + 10), rgb(60, 60, 66), Enum.Material.DiamondPlate)
		part(cage, "CageTop", Vector3.new(10, 1, 10), CFrame.new(x, L + 11.5, Z0 + 10), rgb(60, 60, 66), Enum.Material.DiamondPlate)
		for b = -4.5, 4.5, 1.5 do
			part(cage, "Bar", Vector3.new(0.3, 10, 0.3), CFrame.new(x + b, L + 6, Z0 + 15), rgb(170, 170, 180), Enum.Material.Metal)
			part(cage, "Bar", Vector3.new(0.3, 10, 0.3), CFrame.new(x - 5, L + 6, Z0 + 10 + b), rgb(170, 170, 180), Enum.Material.Metal)
			part(cage, "Bar", Vector3.new(0.3, 10, 0.3), CFrame.new(x + 5, L + 6, Z0 + 10 + b), rgb(170, 170, 180), Enum.Material.Metal)
		end
		local lock = part(cage, "CageLock", Vector3.new(1.4, 1.8, 0.6), CFrame.new(x, L + 5, Z0 + 15.4), rgb(220, 190, 60), Enum.Material.Metal)
		lock:SetAttribute("CageLock", k + 1)
	end
	-- the Tiny Professor's pod by the core
	local pod = Kit.folder(lair, "ProfessorPod")
	Kit.cylY(pod, "PodBase", 7, 2, Vector3.new(CX - 50, L + 1, CZ), rgb(60, 60, 66), Enum.Material.Metal)
	Kit.cylY(pod, "PodGlass", 6, 9, Vector3.new(CX - 50, L + 6.5, CZ), rgb(160, 220, 255), Enum.Material.Glass, { Transparency = 0.5 })
	Kit.cylY(pod, "PodCap", 7, 1.4, Vector3.new(CX - 50, L + 11.7, CZ), rgb(60, 60, 66), Enum.Material.Metal)
	for k = 0, 3 do Kit.cylX(pod, "PodCable", 0.6, 22, Vector3.new(CX - 39, L + 11 - k * 0.8, CZ - 1.5 + k), rgb(30, 30, 36), Enum.Material.Metal) end
	-- laser grids across the way from the elevator (red beams, decorative until the story arms them)
	local lasers = Kit.folder(lair, "LaserGrid")
	for k = 0, 3 do
		for y = 2, 8, 3 do
			local beam = part(lasers, "Laser", Vector3.new(0.2, 0.2, 20), CFrame.new(X0 + 14 + k * 6, L + y, 0), rgb(255, 30, 40), Enum.Material.Neon, { CanCollide = false })
			beam:SetAttribute("Laser", true)
		end
		part(lasers, "Emitter", Vector3.new(1, 10, 1), CFrame.new(X0 + 14 + k * 6, L + 5, -10.5), rgb(60, 60, 66), Enum.Material.Metal)
		part(lasers, "Emitter", Vector3.new(1, 10, 1), CFrame.new(X0 + 14 + k * 6, L + 5, 10.5), rgb(60, 60, 66), Enum.Material.Metal)
	end
	-- the elevator lobby on the west wall
	part(lair, "ElevatorPlatform", Vector3.new(12, 1, 20), CFrame.new(X0 + 8, L + 0.5, 0), rgb(80, 80, 88), Enum.Material.DiamondPlate)
	local down = part(lair, "LairElevator", Vector3.new(0.4, 10, 7), CFrame.new(X0 + 2.3, L + 5.5, 0), rgb(200, 190, 140), Enum.Material.Metal)
	down:SetAttribute("Elevator", "up")
	local upSign = part(lair, "LairElevatorSign", Vector3.new(0.3, 1.2, 7), CFrame.new(X0 + 2.4, L + 12, 0), rgb(20, 16, 26))
	Kit.sign(upSign, Enum.NormalId.Right, "\u{2B06}\u{FE0F} LOBBY", rgb(120, 255, 120), rgb(20, 16, 26), Enum.Font.GothamBlack)
	local welcome = part(lair, "LairBanner", Vector3.new(30, 4, 0.4), CFrame.new(CX, L + 30, Z1 - 2.4), DEEP)
	Kit.sign(welcome, Enum.NormalId.Front, "WELCOME TO MY LAIR, PRINCIPAL", rgb(255, 80, 200), DEEP, Enum.Font.LuckiestGuy)
	-- lights: the cavern is lit by the acid, the core and a string of work lamps
	for x = X0 + 20, X1 - 20, 30 do
		for _, z in { Z0 + 30, Z1 - 30 } do
			local lampPart = part(lair, "WorkLamp", Vector3.new(2, 1, 2), CFrame.new(x, L + 50, z), rgb(255, 230, 190), Enum.Material.Neon)
			Kit.light(lampPart, 45, 1.2, rgb(255, 225, 190))
		end
	end
	return m
end

return Industrial
