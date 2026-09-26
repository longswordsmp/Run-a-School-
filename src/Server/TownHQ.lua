-- ServerScriptService.Server.TownHQ
-- Inside VexCorp HQ (docs/STORY.md, "The HQ floors"): the floors you reach with the staff elevator
-- in the Tower lobby. The tower's outside is only 44 studs wide, so the floors are built as closed
-- levels of their own (150 x 150) far below the east edge of the map, stacked; the elevator ride
-- hides the jump. Each floor: a slab, walls with windows onto a skyline, lights, the elevator bank
-- on the west wall (where you arrive), and the floor's own challenge running east.
--   floor 2  THE CUBICLE FARM     a maze of cubicles, office security, three managers' offices
--                                  (the keycard is in one), the security door on the east wall
-- (floors 3-7 follow)
local HQ = {}

HQ.X, HQ.Z = 925, 0 -- the middle of every floor
HQ.SIZE = 150
HQ.HEIGHT = 30
HQ.FLOORS = {
	[2] = { name = "THE CUBICLE FARM", y = -300 },
	[3] = { name = "THE LASER VAULT", y = -350 },
	[4] = { name = "THE SERVER FARM", y = -400 },
	[5] = { name = "MUTAGEN LABS", y = -450 },
	[6] = { name = "THE BARRACKS", y = -500 },
	[7] = { name = "THE EXECUTIVE SUITE", y = -550 },
}

-- where you arrive on a floor (in front of its elevators), facing east
function HQ.arrival(n)
	local f = HQ.FLOORS[n]
	return CFrame.lookAt(Vector3.new(HQ.X - 64, f.y + 3.5, HQ.Z), Vector3.new(HQ.X, f.y + 3.5, HQ.Z))
end

-- is a position on floor n?
function HQ.onFloor(pos, n)
	local f = HQ.FLOORS[n]
	local h = HQ.SIZE / 2
	return pos.X > HQ.X - h and pos.X < HQ.X + h and pos.Z > HQ.Z - h and pos.Z < HQ.Z + h and pos.Y > f.y - 4 and pos.Y < f.y + HQ.HEIGHT
end

function HQ.floorAt(pos)
	for n in HQ.FLOORS do
		if HQ.onFloor(pos, n) then return n end
	end
	return nil
end

function HQ.build(town, Kit)
	local rgb = Kit.rgb
	local part, C = Kit.part, Kit.C
	local root = Kit.folder(town, "VexCorpHQ")
	local PURPLE, DEEP, TOXIC = rgb(110, 48, 160), rgb(60, 26, 90), rgb(120, 255, 60)
	local H = HQ.SIZE / 2

	---------------------------------------------------------------------------
	-- the shell every floor shares
	---------------------------------------------------------------------------
	local function skyline(parent, cf, w, h, seed)
		-- a window onto the city below: a sky gradient and building silhouettes, glowing
		local pane = part(parent, "Window", Vector3.new(w, h, 0.2), cf, rgb(40, 40, 60), Enum.Material.SmoothPlastic, { CanCollide = false })
		local g = Instance.new("SurfaceGui")
		g.Face = Enum.NormalId.Front
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 20
		g.LightInfluence = 0
		g.Parent = pane
		local sky = Instance.new("Frame")
		sky.Size = UDim2.fromScale(1, 1)
		sky.BorderSizePixel = 0
		sky.BackgroundColor3 = Color3.new(1, 1, 1)
		sky.Parent = g
		local grad = Instance.new("UIGradient")
		grad.Rotation = 90
		grad.Color = ColorSequence.new(rgb(120, 180, 240), rgb(230, 200, 240))
		grad.Parent = sky
		local rng = Random.new(seed)
		local x = 0
		while x < 1 do
			local bw = rng:NextNumber(0.05, 0.14)
			local bh = rng:NextNumber(0.15, 0.55)
			local b = Instance.new("Frame")
			b.AnchorPoint = Vector2.new(0, 1)
			b.Position = UDim2.fromScale(x, 1)
			b.Size = UDim2.fromScale(bw, bh)
			b.BorderSizePixel = 0
			b.BackgroundColor3 = rgb(70, 60, 110):Lerp(rgb(110, 100, 150), rng:NextNumber())
			b.Parent = sky
			-- lit windows
			for k = 1, rng:NextInteger(2, 6) do
				local lw = Instance.new("Frame")
				lw.Size = UDim2.fromScale(0.18, 0.05)
				lw.Position = UDim2.fromScale(rng:NextNumber(0.1, 0.7), rng:NextNumber(0.1, 0.85))
				lw.BorderSizePixel = 0
				lw.BackgroundColor3 = rgb(255, 230, 160)
				lw.Parent = b
			end
			x += bw + rng:NextNumber(0, 0.03)
		end
		-- mullions
		for k = 1, math.floor(w / 6) do
			part(parent, "Mullion", Vector3.new(0.4, h, 0.5), cf * CFrame.new(-w / 2 + k * (w / (math.floor(w / 6) + 1)), 0, -0.2), rgb(40, 34, 56), Enum.Material.Metal)
		end
		return pane
	end

	local function shell(n, opts)
		local f = HQ.FLOORS[n]
		local y = f.y
		local m = Kit.folder(root, "Floor" .. n)
		m:SetAttribute("HQFloor", n)
		local function at(x, yy, z) return CFrame.new(HQ.X + x, y + yy, HQ.Z + z) end
		part(m, "Slab", Vector3.new(HQ.SIZE + 2, 2, HQ.SIZE + 2), at(0, -1, 0), opts.floor or rgb(90, 96, 120), opts.floorMat or Enum.Material.Carpet)
		local ceil = part(m, "Ceiling", Vector3.new(HQ.SIZE + 2, 1, HQ.SIZE + 2), at(0, HQ.HEIGHT + 0.5, 0), opts.ceiling or rgb(235, 235, 240), Enum.Material.SmoothPlastic)
		-- (the ceiling and walls cast shadows so the sun doesn't wash the floor out; the lights do the work)
		local wall = opts.wall or rgb(225, 222, 232)
		-- walls: north and south carry the windows, east and west are solid
		for _, s in { -1, 1 } do
			part(m, "Wall", Vector3.new(HQ.SIZE + 2, HQ.HEIGHT, 1), at(0, HQ.HEIGHT / 2, s * (H + 0.5)), wall, Enum.Material.SmoothPlastic)
			part(m, "Wall", Vector3.new(1, HQ.HEIGHT, HQ.SIZE + 2), at(s * (H + 0.5), HQ.HEIGHT / 2, 0), wall, Enum.Material.SmoothPlastic)
			part(m, "Skirting", Vector3.new(HQ.SIZE, 1, 0.4), at(0, 0.5, s * (H - 0.2)), DEEP)
			part(m, "Skirting", Vector3.new(0.4, 1, HQ.SIZE), at(s * (H - 0.2), 0.5, 0), DEEP)
			if not opts.noWindows then
				for k = -3, 3 do
					local x = k * 20
					if math.abs(x) < 70 and not (opts.skipWindow and opts.skipWindow(s, x)) then
						skyline(m, at(x, 15, s * (H - 0.15)) * CFrame.Angles(0, s < 0 and math.rad(180) or 0, 0), 16, 16, n * 100 + k * 7 + s)
					end
				end
			end
		end
		-- ceiling lights: a grid of glowing panels
		if not opts.noLights then
			for x = -60, 60, 20 do
				for z = -60, 60, 20 do
					local lp = part(m, "CeilingLight", Vector3.new(8, 0.3, 3), at(x, HQ.HEIGHT - 0.15, z), opts.lightColor or rgb(250, 250, 255), Enum.Material.Neon, { CanCollide = false })
					if (x + z) % 40 == 0 then
						local l = Instance.new("SurfaceLight")
						l.Face = Enum.NormalId.Bottom
						l.Range = 32
						l.Brightness = opts.dark and 2.2 or 1
						l.Angle = 120
						l.Color = opts.lightColor or rgb(255, 250, 240)
						l.Parent = lp
					end
				end
			end
		end
		-- the elevator bank on the west wall: two doors, a panel, the floor sign
		for _, dz in { -9, 9 } do
			part(m, "ElevatorFrame", Vector3.new(0.4, 12, 9.4), at(-H + 0.3, 6, dz), rgb(40, 34, 56), Enum.Material.Metal)
			local door = part(m, "ElevatorDoors", Vector3.new(0.4, 10.5, 7.4), at(-H + 0.6, 5.25, dz), rgb(200, 190, 140), Enum.Material.Metal)
			door:SetAttribute("HQElevator", n)
			part(m, "DoorSeam", Vector3.new(0.45, 10.5, 0.12), at(-H + 0.6, 5.25, dz), rgb(120, 110, 80), Enum.Material.Metal)
		end
		part(m, "CallPanel", Vector3.new(0.3, 2, 1.2), at(-H + 0.6, 4.5, 0), rgb(30, 26, 40), Enum.Material.Metal)
		part(m, "CallButton", Vector3.new(0.35, 0.5, 0.5), at(-H + 0.7, 4.7, 0), rgb(255, 80, 80), Enum.Material.Neon)
		local sign = part(m, "FloorSign", Vector3.new(0.3, 3.2, 26), at(-H + 0.7, 14, 0), DEEP)
		Kit.sign(sign, Enum.NormalId.Right, ("FLOOR %d \u{2022} %s"):format(n, f.name), TOXIC, DEEP, Enum.Font.GothamBlack)
		-- a mat where you arrive
		part(m, "ElevatorMat", Vector3.new(10, 0.1, 30), at(-H + 7, 0.05, 0), rgb(60, 50, 80), Enum.Material.Fabric)
		return m, at
	end
	HQ.shell = shell

	---------------------------------------------------------------------------
	-- office furniture
	---------------------------------------------------------------------------
	local MONITOR_GLOW = { rgb(120, 200, 255), rgb(140, 255, 170), rgb(255, 200, 120), rgb(200, 150, 255) }
	local function deskSet(parent, cf, rng, fancy)
		-- a desk facing -z in cf's frame, a monitor, a keyboard, a chair, and some clutter
		part(parent, "Desk", Vector3.new(6, 0.4, 3), cf * CFrame.new(0, 2.8, 0), fancy and rgb(110, 70, 40) or rgb(200, 200, 205), fancy and Enum.Material.Wood or Enum.Material.SmoothPlastic)
		for _, dx in { -2.7, 2.7 } do part(parent, "DeskLeg", Vector3.new(0.4, 2.6, 2.6), cf * CFrame.new(dx, 1.3, 0), rgb(120, 120, 130), Enum.Material.Metal) end
		part(parent, "Monitor", Vector3.new(2.4, 1.6, 0.2), cf * CFrame.new(0, 4.1, 0.9), rgb(25, 25, 30))
		part(parent, "Screen", Vector3.new(2.1, 1.3, 0.05), cf * CFrame.new(0, 4.1, 0.78), MONITOR_GLOW[rng:NextInteger(1, #MONITOR_GLOW)], Enum.Material.Neon)
		part(parent, "MonitorStand", Vector3.new(0.3, 0.9, 0.3), cf * CFrame.new(0, 3.3, 1), rgb(25, 25, 30))
		part(parent, "Keyboard", Vector3.new(1.8, 0.1, 0.6), cf * CFrame.new(0, 3.05, -0.3), rgb(40, 40, 46))
		-- the chair
		part(parent, "ChairSeat", Vector3.new(1.8, 0.3, 1.8), cf * CFrame.new(0, 1.7, -2.3), rgb(40, 40, 60), Enum.Material.Fabric)
		part(parent, "ChairBack", Vector3.new(1.8, 2, 0.3), cf * CFrame.new(0, 2.9, -3.1), rgb(40, 40, 60), Enum.Material.Fabric)
		part(parent, "ChairPost", Vector3.new(0.3, 1.4, 0.3), cf * CFrame.new(0, 0.8, -2.3), rgb(120, 120, 130), Enum.Material.Metal)
		-- clutter
		local roll = rng:NextNumber()
		if roll < 0.35 then
			Kit.cylY(parent, "Mug", 0.5, 0.6, (cf * CFrame.new(2.2, 3.3, -0.5)).Position, ({ rgb(230, 70, 70), rgb(70, 140, 230), rgb(250, 250, 250) })[rng:NextInteger(1, 3)])
		elseif roll < 0.65 then
			for k = 0, rng:NextInteger(1, 4) do
				part(parent, "Paper", Vector3.new(1.1, 0.12, 1.5), cf * CFrame.new(-2, 3.08 + k * 0.12, -0.4) * CFrame.Angles(0, math.rad(rng:NextNumber(-12, 12)), 0), rgb(250, 250, 245))
			end
		else
			Kit.cylY(parent, "PlantPot", 0.7, 0.6, (cf * CFrame.new(2.3, 3.3, 0.6)).Position, rgb(200, 110, 70))
			Kit.ball(parent, "PlantLeaves", 1, (cf * CFrame.new(2.3, 3.9, 0.6)).Position, rgb(70, 160, 70), Enum.Material.Grass)
		end
	end

	local function poster(parent, cf, text, bg, fg)
		local p = part(parent, "Poster", Vector3.new(6, 4, 0.1), cf, bg)
		Kit.sign(p, Enum.NormalId.Front, text, fg, bg, Enum.Font.GothamBlack)
		return p
	end

	---------------------------------------------------------------------------
	-- FLOOR 2: THE CUBICLE FARM
	---------------------------------------------------------------------------
	do
		local m, at = shell(2, { floor = rgb(92, 104, 130), wall = rgb(226, 224, 234),
			skipWindow = function(side, x) return side > 0 and x == 40 end }) -- (the security door)
		local rng = Random.new(22)
		local f2y = HQ.FLOORS[2].y
		local PART = rgb(150, 160, 180) -- the partition fabric
		local cubes = Kit.folder(m, "Cubicles")
		-- 3 x 4 pods of four cubicles; aisles 8 wide between them (guards patrol the aisles)
		local PODX = { -38, -10, 18 }
		local PODZ = { -42, -14, 14, 42 }
		for _, px in PODX do
			for _, pz in PODZ do
				local pod = Kit.folder(cubes, "Pod")
				-- the cross in the middle and the outer walls, with a gap into each cubicle
				part(pod, "Partition", Vector3.new(20, 6.5, 0.4), at(px, 3.25, pz), PART, Enum.Material.Fabric)
				part(pod, "Partition", Vector3.new(0.4, 6.5, 20), at(px, 3.25, pz), PART, Enum.Material.Fabric)
				for _, s in { -1, 1 } do
					-- outer walls along x (north/south sides): solid
					part(pod, "Partition", Vector3.new(20, 6.5, 0.4), at(px, 3.25, pz + s * 10), PART, Enum.Material.Fabric)
					-- outer walls along z (east/west sides): an opening into each cubicle
					for _, h in { -1, 1 } do
						part(pod, "Partition", Vector3.new(0.4, 6.5, 5), at(px + s * 10, 3.25, pz + h * 7.5), PART, Enum.Material.Fabric)
					end
				end
				-- trim caps on top
				part(pod, "PartitionCap", Vector3.new(20.4, 0.3, 0.6), at(px, 6.6, pz), rgb(80, 80, 96), Enum.Material.Metal)
				part(pod, "PartitionCap", Vector3.new(0.6, 0.3, 20.4), at(px, 6.6, pz), rgb(80, 80, 96), Enum.Material.Metal)
				-- a desk in each cubicle, against the middle cross, facing the opening
				for _, sx in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local cf = at(px + sx * 5, 0, pz + sz * 6.8) * CFrame.Angles(0, sz > 0 and math.rad(180) or 0, 0)
						deskSet(pod, cf, rng)
						-- a name plate on the partition
						if rng:NextNumber() < 0.5 then
							local names = { "HOMEWORK DEPT.", "WORKSHEETS", "POP QUIZZES", "DETENTION PLANNING", "SPELLING TESTS", "FLASHCARDS", "LONG DIVISION", "BOOK REPORTS" }
							local np = part(pod, "NamePlate", Vector3.new(3, 0.7, 0.1), at(px + sx * 5, 5.6, pz + sz * 0.3) * CFrame.Angles(0, sz > 0 and 0 or math.rad(180), 0), rgb(250, 250, 250))
							Kit.sign(np, Enum.NormalId.Front, names[rng:NextInteger(1, #names)], rgb(60, 40, 90), rgb(250, 250, 250), Enum.Font.GothamBold)
						end
					end
				end
			end
		end
		-- the water cooler, the photocopier, filing cabinets in the aisles' ends
		local function cooler(x, z)
			part(m, "CoolerBase", Vector3.new(1.6, 3.4, 1.6), at(x, 1.7, z), rgb(240, 240, 245))
			Kit.cylY(m, "CoolerJug", 1.4, 1.8, (at(x, 4.3, z)).Position, rgb(150, 210, 255), Enum.Material.Glass, { Transparency = 0.3 })
		end
		cooler(-60, 30)
		cooler(30, -64)
		local function copier(x, z)
			part(m, "Copier", Vector3.new(3.4, 3.2, 2.6), at(x, 1.6, z), rgb(210, 210, 215))
			part(m, "CopierTop", Vector3.new(3, 0.3, 2.2), at(x, 3.35, z), rgb(60, 60, 70))
			part(m, "CopierLight", Vector3.new(0.8, 0.2, 0.3), at(x + 1, 3.55, z - 0.7), rgb(120, 255, 120), Enum.Material.Neon)
			for k = 0, 3 do part(m, "CopyStack", Vector3.new(2.2, 0.15, 1.6), at(x, 3.6 + k * 0.15, z + 0.1), rgb(250, 250, 245)) end
		end
		copier(-60, -30)
		copier(30, 64)
		for k = 0, 5 do
			local fx = -50 + k * 16
			part(m, "FilingCabinet", Vector3.new(2.4, 5, 2.2), at(fx, 2.5, 72.5), rgb(130, 130, 140), Enum.Material.Metal)
			part(m, "FilingCabinet", Vector3.new(2.4, 5, 2.2), at(fx, 2.5, -72.5), rgb(130, 130, 140), Enum.Material.Metal)
		end
		-- posters on the solid walls
		poster(m, at(-10, 12, 74.3) * CFrame.Angles(0, math.rad(180), 0), "HOMEWORK\nIS THE\nFUTURE", PURPLE, TOXIC)
		poster(m, at(-10, 12, -74.3), "SMILE!\nIT'S MONDAY\nFOREVER", rgb(250, 220, 90), rgb(60, 40, 20))
		-- the arrival area: plants, a bench, the floor map
		for _, z in { -24, 24 } do
			Kit.plant(m, "Bush", HQ.X - 70, HQ.Z + z, 0.9, f2y)
		end
		-- the break room (south, middle): vending machine, fridge, table, microwave
		local brk = Kit.folder(m, "BreakRoom")
		part(brk, "BreakWall", Vector3.new(28, 7, 0.4), at(2, 3.5, -60), rgb(200, 200, 215))
		part(brk, "Vending", Vector3.new(4, 7, 2.6), at(-8, 3.5, -72.5), rgb(200, 40, 50))
		part(brk, "VendingGlass", Vector3.new(2.6, 5, 0.1), at(-8.6, 4, -71.15), rgb(180, 220, 255), Enum.Material.Glass, { Transparency = 0.3 })
		part(brk, "Fridge", Vector3.new(3.4, 7, 3), at(-2, 3.5, -72.5), rgb(240, 240, 245))
		part(brk, "Counter", Vector3.new(12, 3.2, 3), at(9, 1.6, -72.5), rgb(120, 90, 70), Enum.Material.Wood)
		part(brk, "Microwave", Vector3.new(2.4, 1.4, 1.8), at(12, 3.9, -72.5), rgb(40, 40, 46))
		part(brk, "CoffeeMachine", Vector3.new(1.4, 2, 1.4), at(6, 4.2, -72.5), rgb(30, 30, 30))
		Kit.cylY(brk, "BreakTable", 5, 0.3, (at(2, 3, -66)).Position, rgb(250, 250, 250))
		Kit.cylY(brk, "TableLeg", 0.5, 2.8, (at(2, 1.4, -66)).Position, rgb(120, 120, 130), Enum.Material.Metal)
		poster(brk, at(2, 5.5, -59.75), "BREAKS ARE\n5 SECONDS", rgb(240, 240, 245), rgb(200, 40, 40))

		-- the three managers' offices: glass walls, a big desk, a nameplate; the keycard is in one
		local offices = Kit.folder(m, "Offices")
		local function office(name, x0, x1, z0, z1, doorSide)
			local o = Kit.folder(offices, name)
			local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
			local w, d = x1 - x0, z1 - z0
			part(o, "OfficeFloor", Vector3.new(w, 0.1, d), at(cx, 0.06, cz), rgb(150, 110, 80), Enum.Material.WoodPlanks)
			-- glass on the sides that face the room; the door gap on doorSide ("-x" or "+z"/"-z")
			local function glass(size, cf)
				part(o, "GlassWall", size, cf, rgb(190, 225, 255), Enum.Material.Glass, { Transparency = 0.55 })
			end
			if doorSide == "-x" then
				glass(Vector3.new(0.3, 9, (d - 6) / 2), at(x0, 4.5, z0 + (d - 6) / 4))
				glass(Vector3.new(0.3, 9, (d - 6) / 2), at(x0, 4.5, z1 - (d - 6) / 4))
				part(o, "GlassFrame", Vector3.new(0.5, 0.5, d), at(x0, 9.2, cz), rgb(40, 34, 56), Enum.Material.Metal)
			end
			for _, zz in { z0, z1 } do
				if math.abs(zz) < H - 2 then
					glass(Vector3.new(w, 9, 0.3), at(cx, 4.5, zz))
					part(o, "GlassFrame", Vector3.new(w, 0.5, 0.5), at(cx, 9.2, zz), rgb(40, 34, 56), Enum.Material.Metal)
				end
			end
			-- the manager's desk, facing the door (-x)
			local deskCF = at(cx + 4, 0, cz) * CFrame.Angles(0, math.rad(-90), 0)
			deskSet(o, deskCF, rng, true)
			local drawer = part(o, "SearchSpot", Vector3.new(1, 1, 1), at(cx + 2.4, 3.2, cz), rgb(0, 0, 0), nil, { Transparency = 1, CanCollide = false })
			drawer:SetAttribute("HQSearch", name)
			local plate = part(o, "DeskPlate", Vector3.new(0.1, 0.6, 2.4), at(cx + 1.8, 3.35, cz - 1.8), rgb(220, 190, 90), Enum.Material.Metal)
			Kit.sign(plate, Enum.NormalId.Left, name, rgb(40, 30, 20), nil, Enum.Font.GothamBold)
			Kit.plant(o, "Bush", HQ.X + x1 - 2.5, HQ.Z + z0 + 2.5, 0.6, f2y)
			part(o, "Bookshelf", Vector3.new(1.4, 7, 6), at(x1 - 1.2, 3.5, cz + 5), rgb(110, 70, 40), Enum.Material.Wood)
			for k = 0, 2 do
				part(o, "Books", Vector3.new(1, 1.2, 5), at(x1 - 1.2, 1.6 + k * 2.2, cz + 5), ({ rgb(200, 60, 60), rgb(60, 110, 200), rgb(90, 170, 90) })[k + 1])
			end
			return o
		end
		office("REGIONAL MANAGER", 46, 74, 46, 74, "-x")
		office("ASSISTANT TO THE MANAGER", 46, 74, -74, -46, "-x")
		office("VP OF WORKSHEETS", 46, 74, -14, 14, "-x")
		-- the security door: on the north wall behind the east offices' aisle
		local sec = Kit.folder(m, "SecurityDoor")
		part(sec, "DoorFrame", Vector3.new(12, 12, 1.2), at(36, 6, 74.4), rgb(40, 34, 56), Enum.Material.Metal)
		local door = part(sec, "VaultDoor", Vector3.new(9, 10, 0.8), at(36, 5, 73.6), rgb(150, 155, 165), Enum.Material.DiamondPlate)
		door:SetAttribute("HQDoor", 2)
		for k = -1, 1 do part(sec, "DoorStripe", Vector3.new(9, 0.6, 0.85), at(36, 5 + k * 3, 73.6), rgb(250, 200, 40)) end
		local reader = part(sec, "KeycardReader", Vector3.new(1, 1.6, 0.4), at(42, 4.5, 73.8), rgb(30, 26, 40), Enum.Material.Metal)
		reader:SetAttribute("HQReader", 2)
		part(sec, "ReaderLight", Vector3.new(0.6, 0.3, 0.1), at(42, 5, 73.55), rgb(255, 60, 60), Enum.Material.Neon)
		local ss = part(sec, "DoorSign", Vector3.new(12, 1.8, 0.2), at(36, 13, 73.8), DEEP)
		Kit.sign(ss, Enum.NormalId.Back, "\u{1F512} SECURITY: KEYCARD ONLY", rgb(255, 80, 80), DEEP, Enum.Font.GothamBlack)
		-- behind the door: the service elevator up
		local svc = part(sec, "ServiceElevator", Vector3.new(8, 9.6, 0.3), at(36, 4.8, 74.9), rgb(255, 240, 200), Enum.Material.Neon)
		svc:SetAttribute("HQElevator", 2)
		local up = part(sec, "UpSign", Vector3.new(4, 1.4, 0.1), at(36, 8.4, 74.7), rgb(30, 26, 40))
		Kit.sign(up, Enum.NormalId.Back, "\u{25B2} UP", TOXIC, rgb(30, 26, 40), Enum.Font.GothamBlack)
		-- the guards' patrol routes (floor-local x, z; HQService turns them into guards)
		HQ.GUARDS = HQ.GUARDS or {}
		HQ.GUARDS[2] = {
			{ { -52, 56 }, { 36, 56 } },                 -- the north aisle
			{ { 36, -56 }, { -52, -56 } },               -- the south aisle
			{ { -24, -56 }, { -24, 56 } },               -- the west cross aisle
			{ { 4, 56 }, { 4, -56 } },                   -- the east cross aisle
			{ { 36, -40 }, { 36, 40 }, { 40, 60 } },     -- outside the offices
		}
	end

	return root
end

return HQ
