-- ServerScriptService.Server.TownDowntown
-- Downtown (docs/TOWN.md): south of the school area, through the DOWNTOWN gate. The avenue runs
-- south along x = 0 to Town Hall; Market Street crosses it at z = -390.
--   north of Market St   Fresh Mart Grocery (walk in: aisles, freezers, checkouts) and its parking
--                        lot, Recess Row Bank, Hammer & Nail Hardware, the Town Square (clock tower,
--                        fountain, bandstand), the Police Station, the Post Office
--   south of Market St   the Burger Diner, Pixel Palace Arcade, Scoops Ice Cream, the Library,
--                        Snip Snip Barber, the Toy Box
--   the south end        Town Hall and its plaza
local Downtown = {}

function Downtown.build(town, Kit)
	local rgb = Kit.rgb
	local part, C = Kit.part, Kit.C
	local m = Kit.folder(town, "Downtown")

	---------------------------------------------------------------------------
	-- streets
	---------------------------------------------------------------------------
	local streets = Kit.folder(m, "Streets")
	Kit.road(streets, 0, -270, 0, -490, 24, { sidewalk = 8 })
	Kit.road(streets, -420, -390, -12, -390, 24, { sidewalk = 8 })
	Kit.road(streets, 12, -390, 420, -390, 24, { sidewalk = 8 })
	Kit.pave(streets, -12, 12, -402, -378, C.asphalt, Enum.Material.Asphalt, 0.13)
	for _, z in { -372, -408 } do Kit.crosswalk(streets, 0, z, 24, true) end
	for _, x in { -18, 18 } do Kit.crosswalk(streets, x, -390, 24, false) end
	for z = -290, -480, -40 do
		Kit.lamp(streets, -17, z)
		Kit.lamp(streets, 17, z)
	end
	for x = -400, 400, 50 do
		if math.abs(x) > 30 then
			Kit.lamp(streets, x, -373)
			Kit.lamp(streets, x, -407)
		end
	end

	---------------------------------------------------------------------------
	-- Fresh Mart Grocery: a real store, with its car park in front (facing the avenue)
	---------------------------------------------------------------------------
	local store, at = Kit.hollow(m, {
		name = "FreshMart", x = -72, z = -300, w = 60, d = 40, h = 16, face = "+x",
		wall = rgb(238, 236, 228), trim = rgb(40, 150, 70), roof = rgb(80, 86, 96),
		floor = rgb(232, 228, 216), doorW = 10,
		sign = { text = "\u{1F34E} FRESH MART", bg = rgb(40, 150, 70), color = C.white, stroke = rgb(20, 60, 30), w = 34, h = 4.4 },
	})
	Kit.awning(store, at(0, 11, 20.2) * CFrame.Angles(0, math.rad(180), 0), 56, { rgb(40, 150, 70), C.white })
	-- the aisles: shelf units with rows of coloured products, and aisle signs hanging over them
	local products = { rgb(230, 60, 60), rgb(255, 200, 60), rgb(70, 140, 230), rgb(250, 140, 40), rgb(160, 90, 220), rgb(80, 190, 90), rgb(250, 250, 250) }
	local aisleNames = { "SNACKS", "CEREAL", "CANDY", "DRINKS" }
	for i, ax in { -18, -6, 6, 18 } do
		part(store, "Shelf", Vector3.new(3, 7, 22), at(ax, 3.6, -4), rgb(200, 200, 206), Enum.Material.Metal)
		for _, side in { -1, 1 } do
			for level = 0, 3 do
				for k = 0, 9 do
					local c = products[(i * 3 + level * 2 + k) % #products + 1]
					part(store, "Product", Vector3.new(0.6, 1.1, 1.6), at(ax + side * 1.8, 1.4 + level * 1.6, -13.5 + k * 2.1), c)
				end
			end
		end
		local sign = part(store, "AisleSign", Vector3.new(0.3, 1.4, 6), at(ax, 12.5, -4), rgb(40, 150, 70))
		Kit.sign(sign, Enum.NormalId.Right, aisleNames[i], C.white, rgb(40, 150, 70), Enum.Font.LuckiestGuy)
		Kit.sign(sign, Enum.NormalId.Left, aisleNames[i], C.white, rgb(40, 150, 70), Enum.Font.LuckiestGuy)
		part(store, "HangWire", Vector3.new(0.1, 3, 0.1), at(ax, 14.7, -4), C.iron)
	end
	-- freezers along the back wall, glass doors lit from inside
	for k = -26, 26, 6.5 do
		part(store, "Freezer", Vector3.new(6, 9, 3.2), at(k, 4.8, -18), rgb(225, 230, 238), Enum.Material.Metal)
		part(store, "FreezerGlass", Vector3.new(5.2, 7.4, 0.2), at(k, 5, -16.3), rgb(190, 230, 255), Enum.Material.Glass, { Transparency = 0.35 })
		part(store, "FreezerLight", Vector3.new(4.8, 0.2, 2.4), at(k, 8.6, -17.8), rgb(210, 240, 255), Enum.Material.Neon)
	end
	-- the checkouts by the door: counters, conveyors, registers
	for _, cx in { -20, 20 } do
		part(store, "Checkout", Vector3.new(4, 3.2, 10), at(cx, 1.9, 11), rgb(40, 150, 70))
		part(store, "Conveyor", Vector3.new(3, 0.2, 9), at(cx, 3.6, 11), rgb(30, 30, 34))
		part(store, "Register", Vector3.new(1.6, 1.4, 1.8), at(cx + 1, 4.3, 15), rgb(60, 60, 70), Enum.Material.Metal)
		part(store, "LaneLight", Vector3.new(0.4, 3, 0.4), at(cx - 1.6, 5.3, 15.5), C.iron, Enum.Material.Metal)
		local n = part(store, "LaneNumber", Vector3.new(1.2, 1.2, 0.3), at(cx - 1.6, 7.2, 15.5), rgb(255, 214, 60), Enum.Material.Neon)
		Kit.sign(n, Enum.NormalId.Back, cx < 0 and "1" or "2", rgb(30, 30, 30), nil, Enum.Font.LuckiestGuy)
	end
	local sale = part(store, "SaleBanner", Vector3.new(24, 2.8, 0.2), at(0, 11.6, -19.1), rgb(230, 50, 60))
	Kit.sign(sale, Enum.NormalId.Back, "BIG SALE! ALL CANDY 50% OFF", C.white, rgb(230, 50, 60), Enum.Font.LuckiestGuy)
	-- outside: produce stands either side of the door and a cart corral
	for _, side in { -1, 1 } do
		for k = 0, 2 do
			local cf = at(side * (8 + k * 5), 1.4, 23)
			part(store, "Crate", Vector3.new(4, 1.6, 3), cf, rgb(170, 120, 70), Enum.Material.WoodPlanks)
			for j = 0, 5 do
				local fruit = ({ rgb(230, 50, 50), rgb(255, 170, 30), rgb(110, 200, 60), rgb(255, 220, 60) })[(k + side + 2) % 4 + 1]
				Kit.ball(store, "Fruit", 0.9, (cf * CFrame.new(-1.3 + (j % 3) * 1.3, 1.1, -0.6 + math.floor(j / 3) * 1.2)).Position, fruit)
			end
		end
	end
	for k = 0, 3 do
		local cf = at(-24 + k * 1.4, 0, 30)
		part(store, "Cart", Vector3.new(1.2, 1.6, 2.6), cf * CFrame.new(0, 2.3, 0), rgb(200, 205, 215), Enum.Material.DiamondPlate, { Transparency = 0.3 })
		part(store, "CartHandle", Vector3.new(1.2, 0.2, 0.2), cf * CFrame.new(0, 3.3, 1.4), rgb(230, 50, 60))
	end
	-- the car park between the store and the avenue: stalls and a few cars
	Kit.pave(m, -52, -20, -330, -270, C.asphalt, Enum.Material.Asphalt, 0.14)
	for z = -326, -274, 8 do
		part(m, "Stall", Vector3.new(14, 0.05, 0.3), CFrame.new(-36, 0.37, z), C.white)
	end
	Kit.car(m, -40, -310, "-x", rgb(220, 60, 60))
	Kit.car(m, -40, -286, "-x", rgb(60, 130, 220))
	Kit.car(m, -32, -318, "+x", rgb(250, 250, 250))

	---------------------------------------------------------------------------
	-- along Market Street, north side (facing the street)
	---------------------------------------------------------------------------
	local bank = Kit.building(m, {
		name = "Bank", x = -200, z = -352, w = 36, d = 24, h = 20, face = "-z", floors = 2,
		wall = rgb(232, 226, 210), trim = rgb(200, 170, 90), roof = rgb(110, 110, 120), windows = { 4, 2 },
		door = { w = 6, h = 9, color = rgb(90, 60, 40), glass = true },
		sign = { text = "RECESS ROW BANK", bg = rgb(40, 60, 110), color = rgb(255, 225, 140), y = 12.5, w = 26 },
	})
	for _, dx in { -10, -4, 4, 10 } do
		Kit.cylY(bank, "Column", 1.6, 11, Vector3.new(-200 + dx, 6.9, -366), rgb(245, 242, 232), Enum.Material.Marble)
	end
	part(bank, "Portico", Vector3.new(26, 1, 5), CFrame.new(-200, 12.9, -366), rgb(245, 242, 232), Enum.Material.Marble)
	Kit.pediment(bank, -200, 13.4, -366, 26, 4, 2.5, rgb(245, 242, 232), Enum.Material.Marble)
	part(bank, "Steps", Vector3.new(24, 1.2, 4), CFrame.new(-200, 0.6, -368), C.stone, Enum.Material.Concrete)

	local hardware = Kit.building(m, {
		name = "Hardware", x = -320, z = -352, w = 40, d = 24, h = 14, face = "-z",
		wall = rgb(150, 80, 55), trim = rgb(245, 235, 210), roof = rgb(90, 70, 60), material = Enum.Material.Brick,
		windows = { 4, 2 }, door = { w = 6, h = 8, color = rgb(60, 80, 60), glass = true },
		awning = { rgb(220, 60, 50), rgb(245, 235, 210) },
		sign = { text = "\u{1F528} HAMMER & NAIL", bg = rgb(220, 60, 50), color = C.white, y = 12, w = 30 },
	})
	for k = 0, 4 do
		part(hardware, "Lumber", Vector3.new(0.8, 0.8, 12), CFrame.new(-342 + k * 0.9, 0.9 + (k % 2) * 0.8, -374), rgb(210, 170, 110), Enum.Material.Wood)
	end
	part(hardware, "Ladder", Vector3.new(0.3, 10, 2), CFrame.new(-302, 5, -365) * CFrame.Angles(math.rad(-12), 0, 0), rgb(200, 180, 60), Enum.Material.Metal)

	local police = Kit.building(m, {
		name = "Police", x = 190, z = -352, w = 44, d = 24, h = 16, face = "-z", floors = 2,
		wall = rgb(236, 240, 246), trim = rgb(40, 70, 160), roof = rgb(70, 80, 100),
		windows = { 5, 2 }, door = { w = 7, h = 9, color = rgb(40, 70, 160), glass = true },
		sign = { text = "\u{1F46E} POLICE", bg = rgb(40, 70, 160), color = C.white, y = 13, w = 22 },
	})
	for _, dx in { -1.2, 1.2 } do
		local bulb = part(police, "RoofLight", Vector3.new(2, 1, 1.4), CFrame.new(190 + dx, 17.6, -358), dx < 0 and rgb(240, 40, 40) or rgb(40, 90, 255), Enum.Material.Neon)
		Kit.light(bulb, 14, 1, bulb.Color)
	end
	Kit.car(police, 160, -374, "+x", rgb(250, 250, 250), { police = true })

	local post = Kit.building(m, {
		name = "PostOffice", x = 320, z = -352, w = 36, d = 24, h = 14, face = "-z",
		wall = rgb(214, 200, 176), trim = rgb(40, 60, 140), roof = rgb(100, 90, 80), material = Enum.Material.Brick,
		windows = { 4, 2 }, door = { w = 6, h = 8, color = rgb(40, 60, 140), glass = true },
		sign = { text = "\u{2709}\u{FE0F} POST OFFICE", bg = rgb(40, 60, 140), color = C.white, y = 11.5, w = 26 },
	})
	part(post, "Mailbox", Vector3.new(2.2, 3.2, 2), CFrame.new(304, 1.6, -370), rgb(40, 70, 170), Enum.Material.Metal)
	Kit.cylX(post, "MailboxTop", 2, 2.2, Vector3.new(304, 3.2, -370), rgb(40, 70, 170), Enum.Material.Metal)
	Kit.flagpole(post, 340, -370, rgb(220, 50, 50))

	---------------------------------------------------------------------------
	-- the Town Square: a clock tower, a fountain, a bandstand, paths, benches and flowers
	---------------------------------------------------------------------------
	local sq = Kit.folder(m, "TownSquare")
	part(sq, "Lawn", Vector3.new(130, 0.4, 100), CFrame.new(85, 0.2, -312), rgb(96, 186, 78), Enum.Material.Grass)
	part(sq, "PathX", Vector3.new(130, 0.45, 6), CFrame.new(85, 0.24, -312), rgb(220, 205, 175), Enum.Material.Pebble)
	part(sq, "PathZ", Vector3.new(6, 0.45, 100), CFrame.new(85, 0.24, -312), rgb(220, 205, 175), Enum.Material.Pebble)
	-- the clock tower
	part(sq, "TowerBase", Vector3.new(10, 3, 10), CFrame.new(85, 1.5, -312), C.stone, Enum.Material.Concrete)
	part(sq, "Tower", Vector3.new(7, 30, 7), CFrame.new(85, 18, -312), rgb(180, 110, 80), Enum.Material.Brick)
	part(sq, "TowerTop", Vector3.new(8.4, 7, 8.4), CFrame.new(85, 36, -312), rgb(232, 226, 210))
	for _, f in { 0, 90, 180, 270 } do
		local cf = CFrame.new(85, 36, -312) * CFrame.Angles(0, math.rad(f), 0) * CFrame.new(0, 0, -4.3)
		part(sq, "ClockFace", Vector3.new(0.2, 5, 5), cf * CFrame.Angles(0, math.rad(90), 0), C.white, nil, { Shape = Enum.PartType.Cylinder })
		part(sq, "ClockHand", Vector3.new(0.3, 2, 0.1), cf * CFrame.new(0, 0.8, -0.2), rgb(20, 20, 24))
		part(sq, "ClockHand", Vector3.new(1.4, 0.3, 0.1), cf * CFrame.new(0.6, 0, -0.25), rgb(20, 20, 24))
	end
	Kit.wedge(sq, "Spire", Vector3.new(9, 6, 4.5), Vector3.new(85, 42.5, -309.75), "+z", rgb(60, 110, 90), Enum.Material.Slate)
	Kit.wedge(sq, "Spire", Vector3.new(9, 6, 4.5), Vector3.new(85, 42.5, -314.25), "-z", rgb(60, 110, 90), Enum.Material.Slate)
	-- the fountain
	Kit.cylY(sq, "FountainBowl", 14, 1.6, Vector3.new(50, 1, -290), C.stone, Enum.Material.Marble)
	Kit.cylY(sq, "FountainWater", 12.6, 0.3, Vector3.new(50, 1.7, -290), rgb(90, 160, 220), Enum.Material.Glass, { Transparency = 0.2 })
	Kit.cylY(sq, "FountainPillar", 2, 5, Vector3.new(50, 3.5, -290), C.stone, Enum.Material.Marble)
	Kit.cylY(sq, "FountainTop", 5, 0.8, Vector3.new(50, 6, -290), C.stone, Enum.Material.Marble)
	local spray = part(sq, "Spray", Vector3.new(0.5, 0.5, 0.5), CFrame.new(50, 6.8, -290), rgb(180, 220, 255), nil, { Transparency = 1 })
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 30
	pe.Lifetime = NumberRange.new(0.8, 1.2)
	pe.Speed = NumberRange.new(8, 10)
	pe.SpreadAngle = Vector2.new(18, 18)
	pe.Acceleration = Vector3.new(0, -30, 0)
	pe.Size = NumberSequence.new(0.4, 0.1)
	pe.Color = ColorSequence.new(rgb(200, 235, 255))
	pe.Transparency = NumberSequence.new(0.2, 1)
	pe.Parent = spray
	-- the bandstand: an octagonal floor, posts and a roof
	Kit.cylY(sq, "BandFloor", 18, 1.4, Vector3.new(120, 0.9, -340), rgb(245, 242, 232))
	for i = 0, 7 do
		local a = math.rad(i * 45)
		part(sq, "BandPost", Vector3.new(0.6, 9, 0.6), CFrame.new(120 + math.cos(a) * 8, 6, -340 + math.sin(a) * 8), C.white)
	end
	Kit.cylY(sq, "BandRoof", 20, 0.8, Vector3.new(120, 10.8, -340), rgb(200, 60, 60))
	Kit.cylY(sq, "BandRoof", 12, 1.6, Vector3.new(120, 12, -340), rgb(200, 60, 60))
	Kit.ball(sq, "BandTop", 2, Vector3.new(120, 13.6, -340), rgb(245, 205, 80))
	for _, spot in { { 60, -335, "+z" }, { 110, -290, "-x" }, { 60, -318, "-z" }, { 140, -300, "-x" } } do Kit.bench(sq, spot[1], spot[2], spot[3]) end
	for _, spot in { { 40, -340 }, { 130, -290 }, { 40, -270 }, { 145, -355 } } do Kit.tree(sq, spot[1], spot[2], 1.1) end
	Kit.flowerBed(sq, 100, -300, 8, 4)
	Kit.flowerBed(sq, 70, -324, 8, 4)

	---------------------------------------------------------------------------
	-- along Market Street, south side
	---------------------------------------------------------------------------
	local diner = Kit.building(m, {
		name = "Diner", x = -100, z = -432, w = 40, d = 28, h = 12, face = "+z",
		wall = rgb(236, 64, 64), trim = rgb(220, 224, 232), roof = rgb(60, 60, 70), windows = { 6, 3 },
		door = { w = 6, h = 8, color = rgb(220, 224, 232), glass = true },
		sign = { text = "\u{1F354} BURGER DINER", bg = rgb(30, 30, 36), color = rgb(255, 90, 90), y = 10, w = 28 },
	})
	part(diner, "Chrome", Vector3.new(41, 0.8, 29), CFrame.new(-100, 3.2, -432), rgb(220, 224, 232), Enum.Material.Metal)
	-- a giant burger on the roof
	Kit.cylY(diner, "Bun", 8, 2, Vector3.new(-100, 13.6, -432), rgb(220, 150, 60))
	Kit.cylY(diner, "Patty", 8.6, 1.2, Vector3.new(-100, 15.2, -432), rgb(100, 60, 40))
	Kit.cylY(diner, "Cheese", 8.8, 0.3, Vector3.new(-100, 16, -432), rgb(255, 200, 40))
	Kit.cylY(diner, "Lettuce", 8.8, 0.4, Vector3.new(-100, 16.4, -432), rgb(100, 190, 60))
	part(diner, "TopBun", Vector3.new(8, 3, 8), CFrame.new(-100, 17.8, -432), rgb(220, 150, 60), nil, { Shape = Enum.PartType.Ball })

	local arcade = Kit.building(m, {
		name = "Arcade", x = -210, z = -433, w = 44, d = 30, h = 14, face = "+z",
		wall = rgb(60, 30, 100), trim = rgb(255, 60, 220), roof = rgb(40, 20, 60), windows = { 0, 0 },
		door = { w = 8, h = 9, color = rgb(20, 20, 30), glass = true },
		sign = { text = "\u{1F579}\u{FE0F} PIXEL PALACE", bg = rgb(20, 10, 40), color = rgb(90, 240, 255), y = 11.5, w = 32, h = 4 },
	})
	for i, c in { rgb(255, 60, 220), rgb(90, 240, 255), rgb(255, 230, 60) } do
		part(arcade, "Neon", Vector3.new(44.4, 0.3, 0.3), CFrame.new(-210, 2.5 + i * 2.6, -417.8), c, Enum.Material.Neon)
	end
	-- pixel invaders on the front
	for k, dx in { -16, 16 } do
		for py = 0, 2 do
			for px = 0, 4 do
				if (px + py + k) % 2 == 0 then
					part(arcade, "Pixel", Vector3.new(0.9, 0.9, 0.2), CFrame.new(-210 + dx - 2 + px, 5 + py, -417.9), k == 1 and rgb(120, 255, 90) or rgb(255, 120, 60), Enum.Material.Neon)
				end
			end
		end
	end

	local scoops = Kit.building(m, {
		name = "Scoops", x = -320, z = -429, w = 30, d = 22, h = 11, face = "+z",
		wall = rgb(255, 200, 220), trim = rgb(160, 230, 210), roof = rgb(230, 150, 180), windows = { 3, 2 },
		door = { w = 5, h = 8, color = rgb(160, 230, 210), glass = true },
		awning = { rgb(255, 150, 190), C.white },
		sign = { text = "\u{1F366} SCOOPS", bg = rgb(160, 230, 210), color = rgb(200, 40, 110), y = 9.5, w = 18 },
	})
	-- the giant cone on the roof
	for i = 0, 3 do
		part(scoops, "Cone", Vector3.new(3.4 - i * 0.8, 1.6, 3.4 - i * 0.8), CFrame.new(-320, 13 - i * 1.4, -429) * CFrame.Angles(0, math.rad(45), 0), rgb(220, 170, 100), Enum.Material.WoodPlanks)
	end
	Kit.ball(scoops, "Scoop", 4, Vector3.new(-320, 15.4, -429), rgb(255, 170, 200))
	Kit.ball(scoops, "Scoop", 3.4, Vector3.new(-320, 18.2, -429), rgb(150, 230, 180))
	Kit.ball(scoops, "Cherry", 1.2, Vector3.new(-320, 20.3, -429), rgb(220, 30, 40))

	local library = Kit.building(m, {
		name = "Library", x = 110, z = -434, w = 48, d = 32, h = 16, face = "+z", floors = 2,
		wall = rgb(190, 120, 90), trim = rgb(245, 240, 225), roof = rgb(80, 90, 100), material = Enum.Material.Brick,
		windows = { 6, 3 }, door = { w = 7, h = 10, color = rgb(90, 60, 40) },
		sign = { text = "\u{1F4DA} LIBRARY", bg = rgb(245, 240, 225), color = rgb(90, 50, 40), y = 13, w = 24 },
	})
	for _, dx in { -9, -4.5, 4.5, 9 } do
		Kit.cylY(library, "Column", 1.4, 11, Vector3.new(110 + dx, 6.9, -416.4), rgb(245, 240, 225), Enum.Material.Marble)
	end
	part(library, "Portico", Vector3.new(22, 1, 4.4), CFrame.new(110, 12.9, -416.6), rgb(245, 240, 225), Enum.Material.Marble)
	for i = 0, 2 do
		part(library, "Steps", Vector3.new(20 - i * 2, 0.5, 4 - i), CFrame.new(110, 0.25 + i * 0.5, -415 + i * 0.5), C.stone, Enum.Material.Concrete)
	end

	local barber = Kit.building(m, {
		name = "Barber", x = 215, z = -428, w = 26, d = 20, h = 11, face = "+z",
		wall = rgb(236, 236, 240), trim = rgb(200, 40, 50), roof = rgb(70, 70, 80), windows = { 3, 2 },
		door = { w = 5, h = 8, color = rgb(40, 60, 140), glass = true },
		sign = { text = "\u{2702}\u{FE0F} SNIP SNIP", bg = rgb(200, 40, 50), color = C.white, y = 9.3, w = 18 },
	})
	Kit.cylY(barber, "Pole", 1, 6, Vector3.new(205, 4, -417.4), C.white)
	for i = 0, 5 do
		part(barber, "PoleStripe", Vector3.new(1.05, 0.35, 0.3), CFrame.new(205, 1.6 + i, -417.4) * CFrame.Angles(0, 0, math.rad(25)), i % 2 == 0 and rgb(220, 40, 50) or rgb(40, 70, 170))
	end

	local toy = Kit.building(m, {
		name = "ToyBox", x = 320, z = -432, w = 40, d = 28, h = 13, face = "+z",
		wall = rgb(255, 220, 90), trim = rgb(60, 140, 230), roof = rgb(230, 80, 80), windows = { 4, 2 },
		door = { w = 6, h = 8, color = rgb(230, 80, 80), glass = true },
		sign = { text = "\u{1F9F8} THE TOY BOX", bg = rgb(60, 140, 230), color = C.white, y = 11, w = 28 },
	})
	-- a giant teddy bear sitting on the roof
	local bear = rgb(170, 110, 60)
	Kit.ball(toy, "TeddyBody", 7, Vector3.new(320, 17.5, -436), bear)
	Kit.ball(toy, "TeddyHead", 5.4, Vector3.new(320, 23, -436), bear)
	for _, dx in { -2.2, 2.2 } do
		Kit.ball(toy, "TeddyEar", 2, Vector3.new(320 + dx, 25.6, -436), bear)
		Kit.ball(toy, "TeddyPaw", 2.6, Vector3.new(320 + dx * 1.6, 15.6, -433.5), bear)
		Kit.ball(toy, "TeddyEye", 0.7, Vector3.new(320 + dx * 0.4, 23.6, -433.5), rgb(20, 20, 20))
	end
	Kit.ball(toy, "TeddyMuzzle", 2.2, Vector3.new(320, 22.4, -433.6), rgb(230, 190, 150))

	---------------------------------------------------------------------------
	-- Town Hall at the end of the avenue
	---------------------------------------------------------------------------
	local hall = Kit.building(m, {
		name = "TownHall", x = 0, z = -520, w = 64, d = 36, h = 24, face = "+z", floors = 2,
		wall = rgb(238, 234, 222), trim = rgb(200, 180, 120), roof = rgb(70, 110, 100), windows = { 8, 4 },
		door = { w = 8, h = 11, color = rgb(90, 60, 40) },
		sign = { text = "TOWN HALL", bg = rgb(40, 60, 110), color = rgb(255, 230, 150), y = 16.5, w = 22 },
	})
	for _, dx in { -14, -7, 7, 14 } do
		Kit.cylY(hall, "Column", 2, 14, Vector3.new(dx, 8.4, -500), rgb(250, 248, 240), Enum.Material.Marble)
	end
	part(hall, "Portico", Vector3.new(34, 1.4, 6), CFrame.new(0, 16, -500.5), rgb(250, 248, 240), Enum.Material.Marble)
	Kit.pediment(hall, 0, 16.7, -500.5, 34, 5, 3, rgb(250, 248, 240), Enum.Material.Marble)
	-- the dome with a clock drum under it
	Kit.cylY(hall, "Drum", 16, 6, Vector3.new(0, 27, -522), rgb(238, 234, 222))
	Kit.ball(hall, "Dome", 15, Vector3.new(0, 30, -522), rgb(70, 110, 100), Enum.Material.Metal)
	Kit.cylY(hall, "Lantern", 2.4, 3, Vector3.new(0, 38.5, -522), rgb(238, 234, 222))
	Kit.ball(hall, "Finial", 1.4, Vector3.new(0, 40.6, -522), rgb(240, 200, 90), Enum.Material.Metal)
	part(hall, "HallClock", Vector3.new(0.3, 4.4, 4.4), CFrame.new(0, 27, -513.9) * CFrame.Angles(0, math.rad(90), 0), C.white, nil, { Shape = Enum.PartType.Cylinder })
	for i = 0, 3 do
		part(hall, "Steps", Vector3.new(36 - i * 2, 0.5, 5 - i), CFrame.new(0, 0.25 + i * 0.5, -497 - i * 0.6), C.stone, Enum.Material.Concrete)
	end
	Kit.pave(m, -40, 40, -500, -490, rgb(220, 214, 200), Enum.Material.Pebble)
	for _, x in { -24, 24 } do Kit.flagpole(hall, x, -494, x < 0 and rgb(220, 50, 60) or rgb(60, 110, 220)) end
	for _, spot in { { -34, -492 }, { 34, -492 } } do Kit.flowerBed(hall, spot[1], spot[2], 8, 3) end

	-- trees along the back of the blocks
	for x = -400, 400, 40 do
		if math.abs(x) > 40 then
			Kit.tree(m, x, -262, 1)
			Kit.tree(m, x, -548, 1.1)
		end
	end
	return m
end

return Downtown
