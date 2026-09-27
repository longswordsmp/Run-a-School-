-- ServerScriptService.Server.TownInfill
-- Downtown's empty frontage, filled with shops. The districts place their named buildings (the
-- grocery, the diner, the library...) with grass between; walked along, Downtown read as an empty
-- suburb. This runs once the town is in the world and walks both sides of the avenue and of Market
-- Street, putting up a row of two- and three-storey shopfronts wherever the lot behind the sidewalk
-- is clear: nothing standing there, no paving (car parks, paths, plazas), no townsperson's post and
-- clear of Mo's mail round. Neighbours abut, so they make a street wall.
--   a shopfront   a coloured front with pilasters and a cornice, a big shop window and a glass door,
--                 a striped awning, the shop's sign, upper windows (some with flower boxes), a
--                 parapet and a rooftop unit. ~30 parts.
-- Deterministic (a seeded Random): every server builds the same street.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Places = require(ReplicatedStorage.Shared.Places)

local Infill = {}

local rgb = Color3.fromRGB
local WHITE = rgb(250, 250, 246)
-- vibrant, kid-friendly fronts: wall, trim, awning stripes, sign board
local STYLES = {
	{ wall = rgb(255, 128, 110), trim = WHITE, awning = { WHITE, rgb(240, 80, 80) }, sign = rgb(200, 50, 60) },
	{ wall = rgb(120, 222, 182), trim = WHITE, awning = { WHITE, rgb(40, 170, 130) }, sign = rgb(30, 140, 110) },
	{ wall = rgb(110, 182, 255), trim = WHITE, awning = { WHITE, rgb(50, 120, 230) }, sign = rgb(40, 90, 200) },
	{ wall = rgb(255, 214, 110), trim = WHITE, awning = { WHITE, rgb(255, 150, 40) }, sign = rgb(230, 120, 30) },
	{ wall = rgb(192, 152, 255), trim = WHITE, awning = { WHITE, rgb(140, 90, 230) }, sign = rgb(110, 60, 200) },
	{ wall = rgb(255, 182, 142), trim = rgb(125, 72, 52), awning = { rgb(255, 242, 222), rgb(230, 110, 70) }, sign = rgb(180, 80, 50) },
	{ wall = rgb(196, 92, 72), trim = rgb(250, 240, 220), awning = { rgb(250, 240, 220), rgb(40, 140, 90) }, sign = rgb(30, 110, 70), brick = true },
	{ wall = rgb(72, 192, 204), trim = WHITE, awning = { WHITE, rgb(255, 196, 60) }, sign = rgb(20, 120, 140) },
	{ wall = rgb(255, 150, 200), trim = WHITE, awning = { WHITE, rgb(230, 70, 150) }, sign = rgb(200, 50, 130) },
}
local NAMES = {
	"\u{1F36C} CANDY CORNER", "\u{1F4DA} BOOK NOOK", "\u{1F9C1} CUPCAKE CAFE", "\u{1F436} PET PALS",
	"\u{1F355} PIZZA PALACE", "\u{1F6B2} BIKE BARN", "\u{1F3B8} MUSIC BOX", "\u{1F3A8} ART ATTIC",
	"\u{1F45F} SNEAKER SHACK", "\u{1F369} DONUT DEN", "\u{1F52C} SCIENCE SHOP", "\u{1F9CB} BUBBLE TEA",
	"\u{1F338} FLOWER POWER", "\u{1F995} DINO DIG", "\u{1F916} ROBOT REPAIR", "\u{1FA81} KITE KINGDOM",
	"\u{1FA80} YO-YO YARD", "\u{1FA84} MAGIC MARKET", "\u{1F9C3} JUICE JUNGLE", "\u{1F9C7} WAFFLE WAGON",
	"\u{26BD} SPORTS SPOT", "\u{1F58D} CRAYON CORNER", "\u{1F7E2} SLIME LAB", "\u{1F9E9} PUZZLE PLACE",
	"\u{1F3AE} GAME GARAGE", "\u{1F4F7} PHOTO FUN", "\u{1F9F8} TEDDY TOWN", "\u{1F3B2} BOARD GAME BAY",
	"\u{1F370} SLICE OF CAKE", "\u{1F32E} TACO TRUCK STOP", "\u{1F9E6} SOCK SHOP", "\u{1F3AA} PARTY PALACE",
}

local DEPTH = 18
local GROUND = 11 -- the shop floor's height (the awning and the sign above it)
local UPPER = 8.5 -- each floor above

-- a shopfront. front: CFrame on the ground at the front's centre, looking out to the street
local function shopfront(parent, Kit, front, w, floors, style, name, rng)
	local part = Kit.part
	local m = Instance.new("Model")
	m.Name = "Shop"
	m.Parent = parent
	local h = GROUND + UPPER * (floors - 1)
	local wall, trim = style.wall, style.trim
	local body = front * CFrame.new(0, 0, DEPTH / 2) -- (the middle of the footprint: behind the front)
	part(m, "Body", Vector3.new(w, h, DEPTH), body * CFrame.new(0, h / 2, 0), wall, style.brick and Enum.Material.Brick or Enum.Material.SmoothPlastic)
	part(m, "Base", Vector3.new(w + 0.4, 1, DEPTH + 0.4), body * CFrame.new(0, 0.5, 0), Kit.C.stone, Enum.Material.Concrete)
	-- (front-face helpers: x across, y up, the face itself at z 0, out = -z)
	local function F(x, y, z) return front * CFrame.new(x, y, z or 0) * CFrame.Angles(0, math.rad(180), 0) end
	-- pilasters at the two front corners, a cornice along the top, a band between the floors
	for _, s in { -1, 1 } do
		part(m, "Pilaster", Vector3.new(1.2, h, 1.2), F(s * (w / 2 - 0.6), h / 2, -0.35), trim)
	end
	part(m, "Cornice", Vector3.new(w + 0.8, 1, 1.8), F(0, h + 0.1, -0.5), trim)
	part(m, "Parapet", Vector3.new(w, 1.6, 0.8), F(0, h + 1.2, -0.1), wall, style.brick and Enum.Material.Brick or nil)
	-- the shop: a big window and a glass door, a kickplate under the window
	local door = rng:NextNumber() < 0.5 and -1 or 1
	local doorX = door * (w / 2 - 3.6)
	local winW = w - 10.5
	local winX = -door * 2.4
	part(m, "Kickplate", Vector3.new(winW + 1, 2, 0.6), F(winX, 1.6, -0.3), trim)
	part(m, "ShopFrame", Vector3.new(winW + 1, 6, 0.3), F(winX, 5.5, -0.15), trim)
	part(m, "ShopWindow", Vector3.new(winW, 5.4, 0.3), F(winX, 5.5, -0.2), rgb(170, 215, 245), Enum.Material.Glass, { Transparency = 0.25 })
	part(m, "DoorFrame", Vector3.new(4.4, 7.8, 0.3), F(doorX, 4.9, -0.15), trim)
	part(m, "Door", Vector3.new(3.6, 7.2, 0.3), F(doorX, 4.6, -0.2), rgb(170, 215, 245), Enum.Material.Glass, { Transparency = 0.2 })
	part(m, "DoorBar", Vector3.new(3.4, 0.3, 0.4), F(doorX, 4.6, -0.35), trim)
	part(m, "Step", Vector3.new(5, 1, 1.6), F(doorX, 0.5, -0.8), Kit.C.stone, Enum.Material.Concrete)
	-- a planter of flowers on the pavement beside the door
	local px = doorX - door * 3.8
	part(m, "Planter", Vector3.new(2.6, 1.3, 1.3), F(px, 0.65, -1.2), trim, Enum.Material.SmoothPlastic)
	for k = -1, 1 do
		Kit.ball(m, "Flowers", 0.8, (F(px + k * 0.75, 1.55, -1.2)).Position, ({ rgb(255, 90, 120), rgb(255, 220, 70), rgb(190, 110, 255), rgb(255, 150, 60) })[rng:NextInteger(1, 4)])
	end
	-- the sign board above the shop, the awning under it
	local board = part(m, "Sign", Vector3.new(w - 3, 2.6, 0.5), F(0, GROUND - 1.3, -0.4), style.sign)
	Kit.sign(board, Enum.NormalId.Back, name, WHITE, style.sign, Enum.Font.LuckiestGuy, rgb(30, 30, 40))
	local stripes = math.max(3, math.floor((w - 3) / 3))
	local sw = (w - 3) / stripes
	for i = 1, stripes do
		local c = style.awning[(i - 1) % #style.awning + 1]
		part(m, "Awning", Vector3.new(sw, 0.2, 3.6), F(-(w - 3) / 2 + (i - 0.5) * sw, GROUND - 3.2, -1.7) * CFrame.Angles(math.rad(24), 0, 0), c, Enum.Material.Fabric) -- (down towards the street)
	end
	part(m, "AwningFlap", Vector3.new(w - 3, 0.7, 0.14), F(0, GROUND - 4.35, -3.35), style.awning[2], Enum.Material.Fabric)
	-- the floors above: windows in white frames, a band under each floor, flower boxes on some
	local perFloor = w >= 20 and 3 or 2
	local boxes = rng:NextNumber() < 0.55
	for f = 1, floors - 1 do
		local y = GROUND + (f - 1) * UPPER
		part(m, "Band", Vector3.new(w, 0.6, 0.8), F(0, y + 0.3, -0.2), trim)
		for i = 1, perFloor do
			local x = -w / 2 + (i - 0.5) * (w / perFloor)
			part(m, "WindowFrame", Vector3.new(3.6, 4.8, 0.3), F(x, y + 4.4, -0.12), trim)
			part(m, "Window", Vector3.new(3, 4.2, 0.3), F(x, y + 4.4, -0.18), rgb(160, 205, 240), Enum.Material.Glass, { Transparency = 0.2 })
			if boxes then
				part(m, "FlowerBox", Vector3.new(3.6, 0.8, 0.9), F(x, y + 1.7, -0.6), rgb(150, 100, 60), Enum.Material.Wood)
				Kit.ball(m, "Flowers", 0.9, (F(x - 0.9, y + 2.3, -0.6)).Position, ({ rgb(255, 90, 120), rgb(255, 220, 70), rgb(190, 110, 255) })[i % 3 + 1])
				Kit.ball(m, "Flowers", 0.9, (F(x + 0.9, y + 2.3, -0.6)).Position, ({ rgb(255, 150, 60), rgb(255, 120, 190), rgb(120, 200, 255) })[i % 3 + 1])
			end
		end
	end
	-- on the roof: an air-conditioning unit or a little water tank
	local roofY = h + 0.1
	if rng:NextNumber() < 0.5 then
		part(m, "RoofUnit", Vector3.new(4, 2.4, 3.2), body * CFrame.new(rng:NextNumber(-w / 4, w / 4), roofY + 1.2, 3), rgb(200, 204, 212), Enum.Material.Metal)
	else
		Kit.cylY(m, "Tank", 3.4, 4, (body * CFrame.new(rng:NextNumber(-w / 4, w / 4), roofY + 3, 4)).Position, rgb(165, 120, 80), Enum.Material.Wood)
		Kit.cylY(m, "TankLegs", 2.4, 1.4, (body * CFrame.new(0, roofY + 0.7, 4)).Position, rgb(60, 60, 68), Enum.Material.Metal)
	end
	return m
end

-- is the footprint free? (cf: the box's centre, size: its extent). Blocked by anything standing
-- there (above the ground) and by any paving on the ground (a car park, a path, a plaza): only
-- grass is built on. Parts of `ignore` (the town's frame ground) don't count.
local function free(cf, size)
	local params = OverlapParams.new()
	params.RespectCanCollide = false
	for _, p in workspace:GetPartBoundsInBox(cf, size, params) do
		if p.Material ~= Enum.Material.Grass and p.Material ~= Enum.Material.LeafyGrass and not p:IsDescendantOf(workspace.Terrain) then
			-- (ground-level grass-coloured plates count as grass)
			local flat = p.Size.Y <= 1.2 and p.Position.Y < 1.2
			if not (flat and p.Color.G > p.Color.R * 1.3 and p.Color.G > p.Color.B * 1.3) then return false end
		end
	end
	return true
end

-- near a townsperson's post (they stand in front of their buildings)?
local posts = {}
for _, group in Places do
	if type(group) == "table" then
		if group.pos then table.insert(posts, group.pos) end
		for _, p in group do
			if type(p) == "table" and typeof(p.pos) == "Vector3" then table.insert(posts, p.pos) end
		end
	end
end
local function nearPost(center, half)
	for _, pos in posts do
		local d = center - Vector3.new(pos.X, center.Y, pos.Z)
		if math.abs(d.X) < half.X + 8 and math.abs(d.Z) < half.Z + 8 then return true end
	end
	return false
end

-- one side of a street: shops from `a` to `b` along it. line(t) -> the ground point on the frontage
-- (the shop fronts' line) at distance t, out: the unit vector from the lot to the street
local function row(parent, Kit, rng, line, a, b, out, used)
	local t = a
	while t < b - 14 do
		local w = ({ 16, 18, 20, 22, 24 })[rng:NextInteger(1, 5)]
		if t + w > b then w = math.max(16, b - t) end
		local mid = line(t + w / 2)
		local look = CFrame.lookAt(mid, mid + out)
		local center = (look * CFrame.new(0, 12, DEPTH / 2 + 0.5)).Position
		local size = Vector3.new(w + 1, 22, DEPTH + 1)
		local boxCF = CFrame.lookAt(center, center + out)
		local halfWorld = Vector3.new(math.abs(out.Z) * (w / 2) + math.abs(out.X) * (DEPTH / 2), 0, math.abs(out.X) * (w / 2) + math.abs(out.Z) * (DEPTH / 2))
		-- (the ground check: a thin box just over the ground, for paving)
		local groundOK = free(CFrame.lookAt(center - Vector3.new(0, 11.6, 0), center - Vector3.new(0, 11.6, 0) + out), Vector3.new(w + 1, 0.8, DEPTH + 1))
		if groundOK and free(boxCF * CFrame.new(0, 1, 0), size) and not nearPost(center, halfWorld) then
			local style = STYLES[rng:NextInteger(1, #STYLES)]
			local name = table.remove(used, rng:NextInteger(1, #used)) or "SHOP"
			shopfront(parent, Kit, look, w, rng:NextNumber() < 0.45 and 3 or 2, style, name, rng)
			t += w
		else
			t += 4
		end
	end
end

-- street trees: a tree in a stone planter at the kerb, midway between the lamps, clear of the
-- crossings at the junction. at(t) -> the point on the kerb line, t from -1 to 1 across the street
local function streetTrees(parent, Kit, spots)
	for _, pos in spots do
		-- (the box starts over the sidewalk: the paving itself isn't in the way)
		local c = CFrame.new(pos + Vector3.new(0, 3.6, 0))
		if free(c, Vector3.new(4.6, 4, 4.6)) then
			Kit.cylY(parent, "Planter", 4.4, 1.2, pos + Vector3.new(0, 0.6, 0), Kit.C.stone, Enum.Material.Concrete)
			Kit.cylY(parent, "PlanterSoil", 3.8, 0.2, pos + Vector3.new(0, 1.2, 0), Kit.C.dirt, Enum.Material.Ground)
			local tree = Kit.tree(parent, pos.X, pos.Z, 0.72)
			-- (Kit.tree plants at the ground; on a raised sidewalk lift it onto the planter)
			if tree and pos.Y > 0.05 then tree:PivotTo(tree:GetPivot() + Vector3.new(0, pos.Y, 0)) end
		end
	end
end

-- Maple Heights: the houses stand every 90 studs, 64 of lawn between them. Another house (Maple's
-- own: porch, fence, mailbox, driveway, yard tree) goes on each clear lot halfway along.
local FAMILIES = {
	"THE PARKS", "THE MARTINS", "THE BELLS", "THE FOXES", "THE REYESES", "THE KHANS", "THE O'BRIENS",
	"THE FISHERS", "THE LEES", "THE NOVAKS", "THE HAYESES", "THE OSEIS", "THE CARTERS", "THE MORENOS",
	"THE BAILEYS", "THE PATELS JR.", "THE BROOKS", "THE SHAHS", "THE WARDS", "THE DUBOISES",
	"THE HILLS", "THE GRANTS", "THE SANTOSES", "THE TANAKAS", "THE WEBERS", "THE ALIS",
	"THE COOPERS", "THE RIVERAS", "THE MURPHYS", "THE KOWALSKIS", "THE BERGS", "THE NAKAMURAS",
}
local function maple(Kit)
	local Maple = require(script.Parent.TownMaple)
	if not Maple.addHouse then return 0 end
	local rows = { { z = 292, face = "+z" }, { z = 368, face = "-z" }, { z = 412, face = "+z" }, { z = 488, face = "-z" } }
	local n = 0
	for r, row in rows do
		local out = row.face == "+z" and 1 or -1
		for k, x in { -315, -225, -135, -45, 45, 135, 225, 315 } do
			-- the lot: from behind the house to the fence, the driveway side included
			local zBack, zFence = row.z - out * 11, row.z + out * 21.5
			local center = Vector3.new(x - 1, 0, (zBack + zFence) / 2)
			local size = Vector3.new(31, 0, math.abs(zFence - zBack))
			local tall = free(CFrame.new(center + Vector3.new(0, 8, 0)), Vector3.new(size.X, 13, size.Z))
			local ground = free(CFrame.new(center + Vector3.new(0, 0.35, 0)), Vector3.new(size.X, 0.5, size.Z))
			if tall and ground and not nearPost(center, size / 2) then
				local i = 100 + r * 10 + k
				local ok = pcall(Maple.addHouse, { x = x, z = row.z, face = row.face, name = FAMILIES[(r - 1) * 8 + k] }, i)
				if ok then n += 1 end
			end
		end
	end
	return n
end

-- Recess Row: its lamps stand every 50 along both sidewalks (|z| 22) and there wasn't a tree on
-- the street. A tree in a planter halfway between each pair, out by the lots (|z| 25.5: the kids walk
-- at 14.8..19.2), none at a crossing or a school gate (StreetLayout.CROSSINGS)
local function recessRow(town, Kit)
	local Street = require(script.Parent.StreetLayout)
	local spots = {}
	for x = -275, 275, 50 do
		local near = false
		for _, c in Street.CROSSINGS do if math.abs(x - c) < 14 then near = true end end
		if not near then
			table.insert(spots, Vector3.new(x, Street.WALK_TOP, -25.5))
			table.insert(spots, Vector3.new(x, Street.WALK_TOP, 25.5))
		end
	end
	streetTrees(Kit.folder(town, "RecessRowTrees"), Kit, spots)
end

function Infill.build(town, Kit)
	local downtown = town:FindFirstChild("Downtown")
	if not downtown then return end
	local m = Kit.folder(downtown, "Shops")
	local rng = Random.new(2026)
	local names = table.clone(NAMES)
	local SET = 25 -- (the shop fronts: 5 studs behind the sidewalk, room to stand in front)
	-- the avenue (x = 0, from the gate at z -270 down to Town Hall), both sides
	row(m, Kit, rng, function(t) return Vector3.new(SET, 0, -280 - t) end, 0, 200, Vector3.new(-1, 0, 0), names)
	row(m, Kit, rng, function(t) return Vector3.new(-SET, 0, -280 - t) end, 0, 200, Vector3.new(1, 0, 0), names)
	-- Market Street (z -390, x -420..420), both sides, west and east of the avenue
	for _, side in { -1, 1 } do
		row(m, Kit, rng, function(t) return Vector3.new(-420 + t, 0, -390 + side * SET) end, 0, 395, Vector3.new(0, 0, -side), names)
		row(m, Kit, rng, function(t) return Vector3.new(25 + t, 0, -390 + side * SET) end, 0, 395, Vector3.new(0, 0, -side), names)
	end
	-- the trees: the avenue's lamps stand every 40 from z -290, Market Street's every 50 from x -400;
	-- the trees go halfway between, 14 out from the middle (the kerb side of the sidewalk)
	local trees = Kit.folder(m, "StreetTrees")
	local spots = {}
	for z = -310, -470, -40 do
		if math.abs(z + 390) > 26 then
			table.insert(spots, Vector3.new(-14.5, 0, z))
			table.insert(spots, Vector3.new(14.5, 0, z))
		end
	end
	for x = -375, 375, 50 do
		if math.abs(x) > 30 then
			table.insert(spots, Vector3.new(x, 0, -390 - 14.5))
			-- (not in Mo the mail carrier's way: from his post at the Post Office he cuts across there)
			if x ~= 325 then table.insert(spots, Vector3.new(x, 0, -390 + 14.5)) end
		end
	end
	streetTrees(trees, Kit, spots)
	recessRow(town, Kit)
	local n = 0
	for _, s in m:GetChildren() do if s.Name == "Shop" then n += 1 end end
	return n, maple(Kit)
end

return Infill
