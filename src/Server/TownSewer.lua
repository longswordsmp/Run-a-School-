-- ServerScriptService.Server.TownSewer
-- The old storm sewer under Recess Row (Chapter 1's heist): a pothole in the east road by Vex Prep
-- drops into brick tunnels that run south under Vex Prep to a ladder up through a grate in the
-- headmaster's office. Below y -40, so it's outside every area's lock box; getting up the ladder
-- into Vex Prep is the heist's business (HeistService).
--   tunnels   14 wide, 12 high; walkways either side of a slimy water channel; brick, moss, pipes,
--             valve wheels, caged lamps (some flicker), drips, rats scurrying along the walls
--   branches  the main line (pothole -> the office ladder), a dead end east (a rat nest round a huge
--             wedge of cheese) and a dead end west (Janitor Stan's old hideout)
local Sewer = {}

Sewer.Y = -48 -- the walkways' top
Sewer.POTHOLE = Vector3.new(466, 0.3, -7) -- in the east road, by the Vex Prep corner
Sewer.ENTRY = Vector3.new(466, -48, -14) -- the bottom of the ladder under the pothole
Sewer.EXIT = Vector3.new(440, -48, -152) -- the bottom of the ladder up to the office grate
Sewer.GRATE = Vector3.new(440, 0.9, -151.5) -- the grate in the Vex Prep headmaster's office floor

local W, H = 14, 12
-- the tunnels' centrelines (x, z); every endpoint used once is a dead end
local SEGS = {
	{ { 466, -14 }, { 466, -70 } },
	{ { 488, -70 }, { 440, -70 } },
	{ { 440, -70 }, { 440, -152 } },
	{ { 440, -118 }, { 398, -118 } },
}
Sewer.SEGS = SEGS

function Sewer.build(town, Kit)
	local rgb = Kit.rgb
	local part = Kit.part
	local m = Kit.folder(town, "Sewer")
	local Y = Sewer.Y
	local BRICK = rgb(74, 68, 62)
	local BRICK_DARK = rgb(52, 48, 46)
	local FLOORC = rgb(62, 62, 58)
	local WATER = rgb(52, 74, 46)
	local rng = Random.new(31)

	-- the corridors as rectangles (inner bounds), so walls can open where corridors meet
	local rects = {}
	for _, s in SEGS do
		local a, b = s[1], s[2]
		table.insert(rects, {
			x0 = math.min(a[1], b[1]) - W / 2, x1 = math.max(a[1], b[1]) + W / 2,
			z0 = math.min(a[2], b[2]) - W / 2, z1 = math.max(a[2], b[2]) + W / 2,
			alongX = a[1] ~= b[1], a = a, b = b,
		})
	end
	-- a wall line minus the stretches other corridors open onto. A side wall opens only where
	-- another corridor passes right through its line (strict); an end wall is left out wherever
	-- another corridor's side covers that line (touching counts), so every seam has one wall.
	local function openings(fixed, isX, from, to, self, isEnd)
		local cuts = {}
		for _, r in rects do
			if r ~= self then
				local lo, hi, c0, c1
				if isX then lo, hi, c0, c1 = r.x0, r.x1, r.z0, r.z1 else lo, hi, c0, c1 = r.z0, r.z1, r.x0, r.x1 end
				local crosses
				if isEnd then crosses = fixed > lo - 0.01 and fixed < hi + 0.01 else crosses = fixed > lo + 0.01 and fixed < hi - 0.01 end
				if crosses then
					table.insert(cuts, { math.max(from, c0), math.min(to, c1) })
				end
			end
		end
		table.sort(cuts, function(p, q) return p[1] < q[1] end)
		local pieces, at = {}, from
		for _, c in cuts do
			if c[2] > c[1] then
				if c[1] > at then table.insert(pieces, { at, c[1] }) end
				at = math.max(at, c[2])
			end
		end
		if at < to then table.insert(pieces, { at, to }) end
		return pieces
	end
	local function wallPiece(isX, fixed, a, b, side)
		-- isX: the wall runs along x at z = fixed; else along z at x = fixed
		local len = b - a
		if len < 0.2 then return end
		local mid = (a + b) / 2
		local size = isX and Vector3.new(len, H, 1.4) or Vector3.new(1.4, H, len)
		local pos = isX and Vector3.new(mid, Y + H / 2, fixed + side * 0.7) or Vector3.new(fixed + side * 0.7, Y + H / 2, mid)
		part(m, "Wall", size, CFrame.new(pos), BRICK, Enum.Material.Brick)
		-- a darker base course and moss here and there
		local base = isX and Vector3.new(len, 1.6, 1.5) or Vector3.new(1.5, 1.6, len)
		part(m, "WallBase", base, CFrame.new(pos + Vector3.new(0, -H / 2 + 0.8, 0)), BRICK_DARK, Enum.Material.Brick)
		if len > 8 and rng:NextNumber() < 0.7 then
			local ml = rng:NextNumber(3, math.min(10, len - 2))
			local mo = rng:NextNumber(a + ml / 2 + 0.5, b - ml / 2 - 0.5)
			local msize = isX and Vector3.new(ml, rng:NextNumber(1.2, 3), 0.2) or Vector3.new(0.2, rng:NextNumber(1.2, 3), ml)
			local mpos = isX and Vector3.new(mo, Y + 1.8, fixed - side * 0.1) or Vector3.new(fixed - side * 0.1, Y + 1.8, mo)
			part(m, "Moss", msize, CFrame.new(mpos), rgb(70, 110, 50), Enum.Material.Grass, { CanCollide = false })
		end
	end
	for i, r in rects do
		local eps = i * 0.004
		-- floor and ceiling
		part(m, "Floor", Vector3.new(r.x1 - r.x0, 1, r.z1 - r.z0), CFrame.new((r.x0 + r.x1) / 2, Y - 0.5 + eps, (r.z0 + r.z1) / 2), FLOORC, Enum.Material.Slate)
		part(m, "Ceiling", Vector3.new(r.x1 - r.x0 + 2.8, 1, r.z1 - r.z0 + 2.8), CFrame.new((r.x0 + r.x1) / 2, Y + H + 0.5 + eps, (r.z0 + r.z1) / 2), BRICK_DARK, Enum.Material.Brick)
		-- the four walls, opened where other corridors join
		for _, side in { -1, 1 } do
			if r.alongX then
				local z = side < 0 and r.z0 or r.z1
				for _, pc in openings(z, false, r.x0, r.x1, r) do wallPiece(true, z, pc[1], pc[2], side) end
			else
				local x = side < 0 and r.x0 or r.x1
				for _, pc in openings(x, true, r.z0, r.z1, r) do wallPiece(false, x, pc[1], pc[2], side) end
			end
		end
		-- the ends: a wall unless another corridor continues from there
		for _, side in { -1, 1 } do
			if r.alongX then
				local x = side < 0 and r.x0 or r.x1
				for _, pc in openings(x, true, r.z0, r.z1, r, true) do wallPiece(false, x, pc[1], pc[2], side) end
			else
				local z = side < 0 and r.z0 or r.z1
				for _, pc in openings(z, false, r.x0, r.x1, r, true) do wallPiece(true, z, pc[1], pc[2], side) end
			end
		end
		-- the vault: sloped slabs in the top corners
		for _, side in { -1, 1 } do
			local len = r.alongX and (r.x1 - r.x0) or (r.z1 - r.z0)
			local cf
			if r.alongX then
				cf = CFrame.new((r.x0 + r.x1) / 2, Y + H - 1.2, (side < 0 and r.z0 or r.z1) - side * 1.6) * CFrame.Angles(math.rad(side * 45), 0, 0)
				part(m, "Vault", Vector3.new(len, 4.5, 1), cf, BRICK_DARK, Enum.Material.Brick)
			else
				cf = CFrame.new((side < 0 and r.x0 or r.x1) - side * 1.6, Y + H - 1.2, (r.z0 + r.z1) / 2) * CFrame.Angles(0, 0, math.rad(-side * 45))
				part(m, "Vault", Vector3.new(1, 4.5, len), cf, BRICK_DARK, Enum.Material.Brick)
			end
		end
		-- the water channel between the junctions, with low curbs and a drifting texture
		local a, b = r.a, r.b
		local len = math.abs((r.alongX and (b[1] - a[1]) or (b[2] - a[2]))) - W
		if len > 2 then
			local mid = Vector3.new((a[1] + b[1]) / 2, Y + 0.06, (a[2] + b[2]) / 2)
			local wsize = r.alongX and Vector3.new(len, 0.12, 5) or Vector3.new(5, 0.12, len)
			local water = part(m, "Water", wsize, CFrame.new(mid), WATER, Enum.Material.SmoothPlastic, { CanCollide = false })
			local tex = Instance.new("Texture")
			tex.Texture = "rbxassetid://80572692344324"
			tex.Face = Enum.NormalId.Top
			tex.StudsPerTileU, tex.StudsPerTileV = 10, 10
			tex.Transparency = 0.55
			tex.Color3 = rgb(160, 200, 140)
			tex.Parent = water
			game:GetService("CollectionService"):AddTag(tex, "WaterTex")
			for _, s in { -1, 1 } do
				local csize = r.alongX and Vector3.new(len, 0.35, 0.5) or Vector3.new(0.5, 0.35, len)
				local cpos = r.alongX and mid + Vector3.new(0, 0.12, s * 2.75) or mid + Vector3.new(s * 2.75, 0.12, 0)
				part(m, "Curb", csize, CFrame.new(cpos), rgb(120, 116, 110), Enum.Material.Concrete)
			end
		end
		-- a pipe along one wall and a thinner one along the other, valve wheels on the big one
		for _, s in { -1, 1 } do
			local d = s < 0 and 1.4 or 0.7
			local len2 = r.alongX and (r.x1 - r.x0) or (r.z1 - r.z0)
			local pos
			if r.alongX then
				pos = Vector3.new((r.x0 + r.x1) / 2, Y + 8.4 + s * 0.6, (s < 0 and r.z0 or r.z1) - s * 1.2)
				Kit.cylX(m, "Pipe", d, len2 - 1, pos, s < 0 and rgb(120, 90, 70) or rgb(110, 116, 124), Enum.Material.Metal)
			else
				pos = Vector3.new((s < 0 and r.x0 or r.x1) - s * 1.2, Y + 8.4 + s * 0.6, (r.z0 + r.z1) / 2)
				Kit.cylZ(m, "Pipe", d, len2 - 1, pos, s < 0 and rgb(120, 90, 70) or rgb(110, 116, 124), Enum.Material.Metal)
			end
		end
		-- caged lamps down the middle; every third one flickers
		local n = 0
		local axisLen = r.alongX and (r.x1 - r.x0) or (r.z1 - r.z0)
		for t = 8, axisLen - 8, 18 do
			n += 1
			local p = r.alongX and Vector3.new(r.x0 + t, Y + H - 1.2, (r.z0 + r.z1) / 2) or Vector3.new((r.x0 + r.x1) / 2, Y + H - 1.2, r.z0 + t)
			part(m, "LampCage", Vector3.new(1.4, 1.4, 1.4), CFrame.new(p), rgb(40, 40, 44), Enum.Material.DiamondPlate, { Transparency = 0.4 })
			local bulb = Kit.ball(m, "LampBulb", 0.9, p, rgb(255, 226, 150), Enum.Material.Neon)
			bulb.CanCollide = false
			local l = Kit.light(bulb, 26, 1.1, rgb(255, 220, 150))
			if n % 3 == 0 then game:GetService("CollectionService"):AddTag(l, "Flicker") end
			-- a drip from the ceiling now and then
			if rng:NextNumber() < 0.5 then
				local dp = p + (r.alongX and Vector3.new(4, 0.8, rng:NextNumber(-4, 4)) or Vector3.new(rng:NextNumber(-4, 4), 0.8, 4))
				local drip = part(m, "Drip", Vector3.new(0.3, 0.3, 0.3), CFrame.new(dp), rgb(150, 190, 210), nil, { Transparency = 1, CanCollide = false })
				local e = Instance.new("ParticleEmitter")
				e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				e.Color = ColorSequence.new(rgb(170, 210, 230))
				e.Size = NumberSequence.new(0.25)
				e.Lifetime = NumberRange.new(0.9, 1.1)
				e.Rate = 1.2
				e.Speed = NumberRange.new(0)
				e.Acceleration = Vector3.new(0, -14, 0)
				e.LightEmission = 0.3
				e.Parent = drip
			end
		end
	end

	-- the ladder up to the pothole, against the tunnel's end wall under it. w: the foot of that wall;
	-- dir: the way the wall faces, into the tunnel. (It used to stand out in the middle of the tunnel,
	-- so the camera behind you ended up on the far side of it, looking through the rungs.)
	local function ladder(w, dir, name)
		for k = 0, 11 do
			part(m, name .. "Rung", Vector3.new(2.4, 0.25, 0.25), CFrame.new(w + Vector3.new(0, 1 + k * 1, dir * 1.2)), rgb(150, 150, 156), Enum.Material.Metal)
		end
		for _, s in { -1, 1 } do
			part(m, name .. "Rail", Vector3.new(0.3, 12.5, 0.3), CFrame.new(w + Vector3.new(s * 1.2, 6.2, dir * 1.2)), rgb(120, 120, 126), Enum.Material.Metal)
		end
		local shaft = part(m, name .. "Shaft", Vector3.new(4, 0.4, 4), CFrame.new(w + Vector3.new(0, H + 0.8, dir * 2)), rgb(20, 20, 24))
		local spot = part(m, name .. "Spot", Vector3.new(2, 4, 2), CFrame.new(w + Vector3.new(0, 3, dir * 2.4)), rgb(0, 0, 0), nil, { Transparency = 1, CanCollide = false })
		spot:SetAttribute("SewerLadder", name)
		-- a shaft of light from above
		local beam = part(m, name .. "LightShaft", Vector3.new(3, H, 3), CFrame.new(w + Vector3.new(0, H / 2, dir * 2)), rgb(255, 250, 220), Enum.Material.Neon, { Transparency = 0.9, CanCollide = false, CastShadow = false })
		Kit.light(beam, 14, 0.8, rgb(255, 245, 210))
		_ = shaft
		return spot
	end
	ladder(Vector3.new(Sewer.ENTRY.X, Sewer.Y, Sewer.ENTRY.Z + W / 2), -1, "Pothole")
	-- (the office ladder: at the far end of the main line, on its south wall)
	do
		local p = Sewer.EXIT
		for k = 0, 11 do
			part(m, "OfficeRung", Vector3.new(2.4, 0.25, 0.25), CFrame.new(p + Vector3.new(0, 1 + k, -W / 2 + 1.2)), rgb(150, 150, 156), Enum.Material.Metal)
		end
		for _, s in { -1, 1 } do
			part(m, "OfficeRail", Vector3.new(0.3, 12.5, 0.3), CFrame.new(p + Vector3.new(s * 1.2, 6.2, -W / 2 + 1.2)), rgb(120, 120, 126), Enum.Material.Metal)
		end
		local spot = part(m, "OfficeSpot", Vector3.new(2, 4, 2), CFrame.new(p + Vector3.new(0, 3, -W / 2 + 2.4)), rgb(0, 0, 0), nil, { Transparency = 1, CanCollide = false })
		spot:SetAttribute("SewerLadder", "Office")
		local grateLight = part(m, "GrateLight", Vector3.new(3, 0.2, 3), CFrame.new(p + Vector3.new(0, H - 0.1, -W / 2 + 2)), rgb(255, 230, 170), Enum.Material.Neon, { CanCollide = false })
		-- light through the grate bars
		for k = -1, 1 do part(m, "GrateBar", Vector3.new(3, 0.3, 0.3), CFrame.new(p + Vector3.new(0, H - 0.3, -W / 2 + 2 + k)), rgb(30, 30, 34), Enum.Material.Metal) end
		Kit.light(grateLight, 16, 1.2, rgb(255, 225, 170))
	end

	-- signs and graffiti
	local function paint(pos, face, text, color, size)
		local p = part(m, "Graffiti", size or Vector3.new(8, 3, 0.1), CFrame.new(pos), rgb(0, 0, 0), nil, { Transparency = 1, CanCollide = false })
		Kit.sign(p, face, text, color, nil, Enum.Font.PermanentMarker)
		return p
	end
	local warn = part(m, "Sign", Vector3.new(0.2, 2.6, 6), CFrame.new(466 - W / 2 + 0.2, Y + 6, -24), rgb(250, 210, 50))
	Kit.sign(warn, Enum.NormalId.Right, "\u{26A0} STORM SEWER\nAUTHORISED PERSONNEL ONLY", rgb(30, 20, 20), rgb(250, 210, 50), Enum.Font.GothamBlack)
	paint(Vector3.new(466 + W / 2 - 0.1, Y + 5, -42), Enum.NormalId.Left, "RECESS FOREVER!\n- S.", rgb(255, 120, 200), Vector3.new(0.1, 3, 9))
	paint(Vector3.new(452, Y + 6, -70 - W / 2 + 0.1), Enum.NormalId.Back, "VEX PREP \u{2192}\u{2193}", rgb(200, 150, 255), Vector3.new(9, 3, 0.1))
	paint(Vector3.new(440 + W / 2 - 0.1, Y + 5, -100), Enum.NormalId.Left, "THIS WAY TO THE\nHEADMASTER'S OFFICE\n(shh!)", rgb(120, 255, 140), Vector3.new(0.1, 4, 10))
	paint(Vector3.new(398 - W / 2 + 0.1, Y + 5, -118), Enum.NormalId.Right, "STAN'S SPOT\nKEEP OUT (except you)", rgb(120, 200, 255), Vector3.new(0.1, 3, 9))
	paint(Vector3.new(488 + W / 2 - 0.1, Y + 5, -70), Enum.NormalId.Left, "DEAD END\n(the rats say hi)", rgb(255, 200, 80), Vector3.new(0.1, 3, 9))

	-- the east dead end: a rat nest round an enormous wedge of cheese
	local cheese = Instance.new("WedgePart")
	cheese.Name = "Cheese"
	cheese.Size = Vector3.new(4, 3, 5)
	cheese.CFrame = CFrame.new(488, Y + 1.5, -70) * CFrame.Angles(0, math.rad(30), 0)
	cheese.Color = rgb(250, 210, 70)
	cheese.Anchored = true
	cheese.Parent = m
	for k = 0, 5 do Kit.ball(m, "CheeseHole", 0.6 + rng:NextNumber(0, 0.5), cheese.Position + Vector3.new(rng:NextNumber(-1.5, 1.5), rng:NextNumber(-0.8, 0.8), rng:NextNumber(-2, 2)), rgb(220, 170, 50)) end
	for k = 0, 6 do part(m, "Straw", Vector3.new(2, 0.2, 0.4), CFrame.new(486 + rng:NextNumber(-3, 3), Y + 0.1, -70 + rng:NextNumber(-4, 4)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), rgb(200, 170, 110)) end

	-- the west dead end: Janitor Stan's old hideout (a crate table, a lantern, a mop, a sleeping bag)
	part(m, "StanCrate", Vector3.new(3, 2.4, 3), CFrame.new(396, Y + 1.2, -114), rgb(150, 110, 70), Enum.Material.WoodPlanks)
	local lantern = part(m, "StanLantern", Vector3.new(0.8, 1.2, 0.8), CFrame.new(396, Y + 3, -114), rgb(255, 200, 110), Enum.Material.Neon)
	Kit.light(lantern, 18, 1.2, rgb(255, 190, 110))
	part(m, "MopHandle", Vector3.new(0.3, 6, 0.3), CFrame.new(393, Y + 3, -123) * CFrame.Angles(0, 0, math.rad(12)), rgb(150, 110, 70), Enum.Material.Wood)
	Kit.ball(m, "MopHead", 1.4, Vector3.new(392.4, Y + 0.6, -123), rgb(220, 220, 210), Enum.Material.Fabric)
	part(m, "SleepingBag", Vector3.new(2.4, 0.5, 6), CFrame.new(400, Y + 0.25, -123), rgb(60, 110, 160), Enum.Material.Fabric)
	part(m, "Pillow", Vector3.new(2, 0.5, 1.2), CFrame.new(400, Y + 0.6, -125.6), rgb(240, 240, 235), Enum.Material.Fabric)

	-- a green leak: Mutagen X seeping from a VexCorp pipe (the story's foreshadowing)
	local leak = part(m, "Leak", Vector3.new(5, 0.1, 4), CFrame.new(440 + 4, Y + 0.08, -95), rgb(110, 255, 70), Enum.Material.Neon, { CanCollide = false, Transparency = 0.3 })
	Kit.light(leak, 14, 1, rgb(120, 255, 80))
	local vpipe = Kit.cylX(m, "VexPipe", 1.2, 6, Vector3.new(440 + 4.5, Y + 4, -95), rgb(110, 50, 165), Enum.Material.Metal)
	local vlabel = part(m, "VexPipeLabel", Vector3.new(0.1, 1, 3), CFrame.new(440 + W / 2 - 0.2, Y + 5.4, -95), rgb(110, 50, 165))
	Kit.sign(vlabel, Enum.NormalId.Left, "VEXCORP \u{2622}", rgb(255, 255, 255), rgb(110, 50, 165), Enum.Font.GothamBlack)
	_ = vpipe

	-- rats: little grey models the clients make scurry between two points (Decor.client, tag "Rat")
	local function rat(a, b)
		local r = Instance.new("Model")
		r.Name = "Rat"
		local body = part(r, "RatBody", Vector3.new(1.2, 0.6, 0.6), CFrame.new(a + Vector3.new(0, 0.3, 0)), rgb(110, 105, 110), Enum.Material.SmoothPlastic, { CanCollide = false })
		part(r, "RatHead", Vector3.new(0.5, 0.45, 0.45), CFrame.new(a + Vector3.new(0.75, 0.35, 0)), rgb(120, 115, 120), nil, { CanCollide = false })
		part(r, "RatNose", Vector3.new(0.12, 0.12, 0.12), CFrame.new(a + Vector3.new(1.02, 0.35, 0)), rgb(255, 150, 170), nil, { CanCollide = false })
		for _, s in { -1, 1 } do part(r, "RatEar", Vector3.new(0.1, 0.25, 0.25), CFrame.new(a + Vector3.new(0.6, 0.66, s * 0.18)), rgb(255, 170, 190), nil, { CanCollide = false }) end
		part(r, "RatTail", Vector3.new(1.2, 0.08, 0.08), CFrame.new(a + Vector3.new(-1.1, 0.25, 0)), rgb(230, 170, 180), nil, { CanCollide = false })
		r.PrimaryPart = body
		r.Parent = m
		r:SetAttribute("A", a)
		r:SetAttribute("B", b)
		r:SetAttribute("Speed", rng:NextNumber(5, 9))
		game:GetService("CollectionService"):AddTag(r, "Rat")
	end
	rat(Vector3.new(466 - 5, Y, -20), Vector3.new(466 - 5, Y, -64))
	rat(Vector3.new(470, Y, -70 + 5), Vector3.new(446, Y, -70 + 5))
	rat(Vector3.new(440 + 5, Y, -80), Vector3.new(440 + 5, Y, -112))
	rat(Vector3.new(432, Y, -118 - 5), Vector3.new(404, Y, -118 - 5))
	rat(Vector3.new(482, Y, -66), Vector3.new(488, Y, -74))

	-- up on the road: the pothole (broken asphalt round a black hole with a ladder top showing),
	-- chunks of road, cones and a ROAD WORK sign that's fallen over
	local ph = Kit.folder(m, "Pothole")
	local P = Sewer.POTHOLE
	Kit.cylY(ph, "HoleRim", 7.5, 0.12, P + Vector3.new(0, 0.02, 0), rgb(46, 46, 52), Enum.Material.Asphalt)
	local hole = Kit.cylY(ph, "Hole", 5.2, 0.14, P + Vector3.new(0, 0.05, 0), rgb(8, 8, 10), Enum.Material.SmoothPlastic)
	hole:SetAttribute("SewerDown", true)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local r = rng:NextNumber(2.4, 3.4)
		part(ph, "Crack", Vector3.new(rng:NextNumber(1.4, 2.6), 0.1, 0.25), CFrame.new(P + Vector3.new(math.cos(a) * r, 0.03, math.sin(a) * r)) * CFrame.Angles(0, -a + rng:NextNumber(-0.5, 0.5), 0), rgb(30, 30, 34))
	end
	for k = 0, 4 do
		local a = rng:NextNumber(0, math.pi * 2)
		part(ph, "Chunk", Vector3.new(rng:NextNumber(0.8, 1.6), 0.4, rng:NextNumber(0.6, 1.2)), CFrame.new(P + Vector3.new(math.cos(a) * rng:NextNumber(4, 6), 0.2, math.sin(a) * rng:NextNumber(4, 6))) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)), rgb(64, 64, 70), Enum.Material.Asphalt)
	end
	-- the top of the ladder, just visible in the hole
	for _, s in { -1, 1 } do part(ph, "LadderTop", Vector3.new(0.25, 1.2, 0.25), CFrame.new(P + Vector3.new(s * 1, -0.3, -1.6)), rgb(150, 150, 156), Enum.Material.Metal) end
	for _, c in { { -4.6, -3 }, { 4.4, -3.4 }, { 3.8, 3.6 }, { -4.2, 3.4 } } do
		local cone = P + Vector3.new(c[1], 0, c[2])
		Kit.cylY(ph, "Cone", 1.3, 2.4, cone + Vector3.new(0, 1.2, 0), rgb(255, 120, 30))
		Kit.cylY(ph, "ConeStripe", 1.1, 0.35, cone + Vector3.new(0, 1.5, 0), rgb(250, 250, 250))
		part(ph, "ConeBase", Vector3.new(1.8, 0.2, 1.8), CFrame.new(cone + Vector3.new(0, 0.1, 0)), rgb(255, 120, 30))
	end
	local roadwork = part(ph, "RoadWork", Vector3.new(4, 3, 0.2), CFrame.new(P + Vector3.new(6.5, 0.6, 1)) * CFrame.Angles(math.rad(-80), math.rad(20), 0), rgb(255, 150, 30))
	Kit.sign(roadwork, Enum.NormalId.Back, "ROAD WORK\n(since 1987)", rgb(20, 20, 20), rgb(255, 150, 30), Enum.Font.GothamBlack)
	return m
end

return Sewer
