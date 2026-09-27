-- ServerScriptService.Server.SchoolAnnex
-- The campus behind every school: a single-storey block against the building's back wall with the
-- rooms a real school has, each one you can walk into.
--   CAFETERIA   (Elementary+)   a checkered floor, the lunch counter with trays of food, long tables
--   GYMNASIUM   (High School+)  a wooden court with its lines, a hoop and scoreboard, bleachers, a ball rack
--   AUDITORIUM  (Prep School+)  a raised stage with red curtains, footlights and a lighting bar, rows of
--                               red seats facing it: plays and assemblies
--   LIBRARY     (Middle School+) tall shelves of books, reading tables, bean bags, the librarian's desk
-- From the classrooms: floor 1's two back windows are doorways (x = +-24) into the gym and the
-- auditorium; the cafeteria and the library open off those, and each has its own door outside, in the
-- side strip beside the building. A room that isn't open yet has its doors shut and a sign on them
-- ("OPENS AT HIGH SCHOOL"): a goal you can see.
-- Plot-local frame as in SchoolBuilder: +Z faces the street; the annex spans x -60..60, z -66.75..-100
-- (the lot ends at z -100 now), its floor level with floor 1 (y 2).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local Annex = {}

Annex.Z0, Annex.Z1 = -66.75, -100 -- the front (the building's back face) and the back wall
Annex.X = 60
Annex.FLOOR = 2
Annex.TOP = 20 -- the walls' top
Annex.DOORS = { -24, 24 } -- floor 1's back-wall doorways (plot-local x)
-- the rooms, west to east, and the tier each opens at
Annex.ROOMS = {
	{ id = "Cafeteria", name = "CAFETERIA", icon = "\u{1F355}", x0 = -60, x1 = -36, tier = 2 },
	{ id = "Gym", name = "GYMNASIUM", icon = "\u{1F3C0}", x0 = -36, x1 = 0, tier = 4 },
	{ id = "Auditorium", name = "AUDITORIUM", icon = "\u{1F3AD}", x0 = 0, x1 = 36, tier = 5 },
	{ id = "Library", name = "LIBRARY", icon = "\u{1F4DA}", x0 = 36, x1 = 60, tier = 3 },
}

function Annex.isOpen(tier, id)
	for _, r in Annex.ROOMS do
		if r.id == id then return (tier or 1) >= r.tier end
	end
	return false
end

local rgb = Color3.fromRGB
local WHITE = rgb(250, 250, 250)

-- H: SchoolBuilder's helpers { part, cyl, ball, wedge, text, light, wallX, wallZ, windowsAt, dome }
function Annex.build(school, L, look, tier, g, H, roofY)
	local part, cyl, ball, text = H.part, H.cyl, H.ball, H.text
	local m = Instance.new("Model")
	m.Name = "Annex"
	m.Parent = school
	-- (as tall as the school where the school is a single storey: taller, it stood over the roofline)
	local Z0, Z1, X, F, TOP = Annex.Z0, Annex.Z1, Annex.X, Annex.FLOOR, math.min(Annex.TOP, roofY or Annex.TOP)
	-- the outside: walls, roof, parapets, foundation, signs (a prestige finish repaints this folder)
	local shell = Instance.new("Folder")
	shell.Name = "Shell"
	shell.Parent = m
	local wall, trim = look.wall, look.cap
	local inner = look.inner
	local WT = 1.5
	local midZ = (Z0 + Z1) / 2
	local open = {}
	for _, r in Annex.ROOMS do open[r.id] = tier >= r.tier end
	local tierName = function(t) return (Config.Tiers[t] and Config.Tiers[t].name or ""):upper() end

	-- the shell: foundation, floor, the outer walls (windows, and the two outside doors in the front
	-- faces beside the building), the partitions with their doorways, a flat roof with a parapet
	part(shell, "Foundation", Vector3.new(X * 2 + 1, F - 0.2, Z0 - Z1 + 1), L(0, (F - 0.2) / 2 + 0.2, midZ), look.foundation)
	local sill, wtop = F + 5, F + 13
	-- (windows only where nothing stands against the wall: the gym's back either side of the hoop and
	-- the cafeteria's end; the counter, the stage and the shelves have the rest)
	H.wallX(shell, L, Z1 + WT / 2, -X, X, F, TOP, H.windowsAt({ -27, -9 }, 6, sill, wtop), wall, trim)
	H.wallZ(shell, L, -(X - WT / 2), Z1 + WT, Z0, F, TOP, H.windowsAt({ -77, -91 }, 6, sill, wtop), wall, trim)
	H.wallZ(shell, L, X - WT / 2, Z1 + WT, Z0, F, TOP, {}, wall, trim)
	-- the front faces beside the building (|x| 40..60): the outside door of the cafeteria / library
	for _, s in { -1, 1 } do
		local door = { a = s < 0 and -53 or 47, b = s < 0 and -47 or 53, bottom = F, top = F + 10, kind = "door" }
		local x0, x1 = s < 0 and -X or 40.75, s < 0 and -40.75 or X
		H.wallX(shell, L, Z0 - WT / 2, x0, x1, F, TOP, { door }, wall, trim)
	end
	-- above the building's back wall the annex is only a storey: nothing to build there (the school's
	-- own back wall is its front wall)
	-- the partitions: cafeteria|gym at -36, gym|auditorium at 0, auditorium|library at 36
	local function partition(x, doorZ)
		local ops = doorZ and { { a = doorZ - 3, b = doorZ + 3, bottom = F, top = F + 10, kind = "door" } } or {}
		H.wallZ(m, L, x, Z1 + WT, Z0 - WT, F, TOP, ops, inner, trim, 1)
	end
	partition(-36, -84)
	partition(0, -90)
	partition(36, -84)
	-- the floor: each room its own (the cafeteria's is done as a checkerboard below)
	part(m, "Slab", Vector3.new(X * 2 - 1, 0.6, Z0 - Z1 - 1), L(0, F - 0.3, midZ), look.floor)
	-- the ceiling and the roof
	part(m, "Ceiling", Vector3.new(X * 2 - 2, 0.4, Z0 - Z1 - 2), L(0, TOP - 0.4, midZ), inner)
	-- (the roof stops at the building's face: past it, it cut into the school's back parapet)
	part(shell, "Roof", Vector3.new(X * 2 + 1.5, 1, Z0 - Z1 + 0.75), L(0, TOP + 0.5, (Z0 + Z1 - 0.75) / 2), look.roof)
	part(shell, "Parapet", Vector3.new(X * 2 + 2, 2.2, 1.2), L(0, TOP + 1.9, Z1 - 0.3), trim)
	for _, s in { -1, 1 } do
		part(shell, "Parapet", Vector3.new(1.2, 2.2, Z0 - Z1 + 1.2), L(s * (X + 0.3), TOP + 1.9, (Z0 + Z1 - 0.6) / 2), trim)
		part(shell, "Parapet", Vector3.new(X - 40.75 + 0.6, 2.2, 1.2), L(s * (40.75 + (X - 40.75 + 0.6) / 2), TOP + 1.9, Z0 - 0.6), trim)
	end
	-- ceiling lights down the middle of every room
	for _, r in Annex.ROOMS do
		local cx = (r.x0 + r.x1) / 2
		for _, z in { -76, -91 } do
			local lamp = part(m, "CeilingLight", Vector3.new(math.min(10, r.x1 - r.x0 - 8), 0.3, 2), L(cx, TOP - 0.8, z), rgb(255, 250, 235), Enum.Material.Neon)
			if z == -76 then H.light(lamp, 26, 0.9) end
		end
	end

	-- the signs on the back (facing the ring road) and over the two outside doors
	for _, r in Annex.ROOMS do
		local cx = (r.x0 + r.x1) / 2
		local board = part(shell, "RoomSign", Vector3.new(r.x1 - r.x0 - 5, 3, 0.4), L(cx, TOP - 3, Z1 - 0.2), look.sign)
		text(board, Enum.NormalId.Front, (open[r.id] and r.icon .. " " or "\u{1F512} ") .. r.name, WHITE, look.sign, Enum.Font.LuckiestGuy)
	end
	for _, spec in { { -50, "Cafeteria" }, { 50, "Library" } } do
		local r
		for _, q in Annex.ROOMS do if q.id == spec[2] then r = q end end
		local board = part(shell, "DoorSign", Vector3.new(16, 2.6, 0.4), L(spec[1], math.min(F + 12.6, TOP - 1.8), Z0 + 0.1), look.sign)
		text(board, Enum.NormalId.Back, (open[r.id] and r.icon .. " " or "\u{1F512} ") .. r.name, WHITE, look.sign, Enum.Font.LuckiestGuy)
		part(shell, "DoorStep", Vector3.new(8, F, 3), L(spec[1], F / 2, Z0 + 1.6), look.foundation)
	end

	-- a closed door with the sign saying when the room opens. at: CFrame of the doorway's middle at
	-- the floor, facing the side the sign is read from; w: its width
	local function shut(at, w, r)
		part(m, "ShutDoor", Vector3.new(w, 9, 0.5), at * CFrame.new(0, 4.5, 0), look.door or rgb(90, 90, 100))
		part(m, "ShutDoorBar", Vector3.new(w * 0.8, 0.4, 0.7), at * CFrame.new(0, 4.6, -0.1), rgb(200, 200, 206), Enum.Material.Metal)
		local s = part(m, "OpensSign", Vector3.new(w - 0.4, 2.6, 0.2), at * CFrame.new(0, 6.4, -0.35), rgb(255, 250, 235))
		text(s, Enum.NormalId.Front, ("\u{1F512} %s\nOPENS AT %s"):format(r.name, tierName(r.tier)), rgb(40, 40, 50), rgb(255, 250, 235), Enum.Font.GothamBlack)
	end
	local roomById = {}
	for _, r in Annex.ROOMS do roomById[r.id] = r end
	-- the doorways from the classrooms (the gym's at -24, the auditorium's at +24), read from inside
	-- the school (facing +Z)
	for _, spec in { { -24, "Gym" }, { 24, "Auditorium" } } do
		if not open[spec[2]] then shut(L(spec[1], F, Z0 - 0.4) * CFrame.Angles(0, math.pi, 0), 6, roomById[spec[2]]) end
	end
	-- the outside doors (read from outside, facing +Z)
	for _, spec in { { -50, "Cafeteria" }, { 50, "Library" } } do
		if not open[spec[2]] then shut(L(spec[1], F, Z0 - 0.2) * CFrame.Angles(0, math.pi, 0), 6, roomById[spec[2]]) end
	end
	-- the doorways between rooms (a: the room to the west, b: to the east): shut, the sign read from
	-- whichever side is open (a CFrame turned +90 about Y looks west, -90 east)
	local function between(x, z, a, b)
		if open[a] and not open[b] then
			shut(L(x, F, z) * CFrame.Angles(0, math.pi / 2, 0), 6, roomById[b])
		elseif open[b] and not open[a] then
			shut(L(x, F, z) * CFrame.Angles(0, -math.pi / 2, 0), 6, roomById[a])
		elseif not open[a] and not open[b] then
			part(m, "ShutDoor", Vector3.new(0.5, 10, 6), L(x, F + 5, z), look.door or rgb(90, 90, 100))
		end
	end
	between(-36, -84, "Cafeteria", "Gym")
	between(0, -90, "Gym", "Auditorium")
	between(36, -84, "Auditorium", "Library")

	---------------------------------------------------------------------------
	-- the rooms
	---------------------------------------------------------------------------
	local rng = Random.new(tier * 31 + 7)
	local function room(id) local f = Instance.new("Folder") f.Name = id f.Parent = m return f end

	-- CAFETERIA: a checkerboard floor, the lunch counter on the back wall, three long tables
	if open.Cafeteria then
		local r = room("Cafeteria")
		local c0, c1 = rgb(250, 250, 246), rgb(230, 80, 80)
		for ix = 0, 3 do
			for iz = 0, 5 do
				part(r, "Tile", Vector3.new(5.6, 0.1, 5.4), L(-57.2 + ix * 5.6, F + 0.05, -69.5 - iz * 5.4), (ix + iz) % 2 == 0 and c0 or c1, Enum.Material.SmoothPlastic)
			end
		end
		-- the counter, the sneeze guard, trays of food
		part(r, "Counter", Vector3.new(20, 3.4, 2.6), L(-48, F + 1.7, -96.5), rgb(200, 204, 212), Enum.Material.Metal)
		part(r, "CounterTop", Vector3.new(20.4, 0.3, 3), L(-48, F + 3.55, -96.5), rgb(235, 238, 242), Enum.Material.Metal)
		part(r, "SneezeGuard", Vector3.new(19, 1.8, 0.15), L(-48, F + 5.4, -95.4), rgb(200, 235, 255), Enum.Material.Glass, { Transparency = 0.4 })
		local FOOD = {
			{ "Pizza", rgb(250, 190, 70) }, { "Salad", rgb(110, 200, 90) }, { "Corn", rgb(255, 225, 80) },
			{ "Meatballs", rgb(150, 80, 50) }, { "Jello", rgb(240, 60, 90) }, { "Pudding", rgb(160, 110, 70) },
		}
		for i, f in FOOD do
			local x = -56.5 + i * 2.9
			part(r, "Pan", Vector3.new(2.6, 0.5, 1.8), L(x, F + 3.9, -96.5), rgb(170, 175, 185), Enum.Material.Metal)
			part(r, f[1], Vector3.new(2.2, 0.35, 1.4), L(x, F + 4.2, -96.5), f[2])
		end
		for k = 0, 4 do part(r, "Tray", Vector3.new(2.4, 0.2, 1.6), L(-58.2, F + 3.8 + k * 0.22, -96.5), rgb(255, 150, 60)) end
		local menu = part(r, "Menu", Vector3.new(14, 4, 0.2), L(-48, F + 10.5, Z1 + WT + 0.15), rgb(40, 45, 55))
		text(menu, Enum.NormalId.Back, "\u{1F355} TODAY: PIZZA DAY!\n\u{1F95B} milk \u{00B7} \u{1F34E} apple \u{00B7} \u{1F36E} pudding", rgb(255, 250, 230), rgb(40, 45, 55), Enum.Font.FredokaOne)
		-- the tables, with benches and a lunch tray or two each
		for i, z in { -74, -82, -90 } do
			part(r, "Table", Vector3.new(16, 0.5, 3.4), L(-47, F + 3, z), rgb(90, 160, 230))
			for _, dx in { -6.5, 6.5 } do part(r, "TableLeg", Vector3.new(0.5, 2.8, 2.8), L(-47 + dx, F + 1.4, z), rgb(200, 200, 206), Enum.Material.Metal) end
			for _, dz in { -2.6, 2.6 } do part(r, "Bench", Vector3.new(16, 0.4, 1.3), L(-47, F + 1.8, z + dz), rgb(60, 120, 200)) end
			for k = 0, 1 do
				local tx = -52 + k * 8 + rng:NextNumber(-1, 1)
				part(r, "LunchTray", Vector3.new(2.2, 0.15, 1.5), L(tx, F + 3.33, z), rgb(255, 150, 60))
				ball(r, "Apple", 0.6, L(tx - 0.6, F + 3.7, z), rgb(220, 40, 50))
				part(r, "Milk", Vector3.new(0.5, 0.8, 0.5), L(tx + 0.6, F + 3.8, z), rgb(250, 250, 250))
			end
		end
		-- (a trash can and a poster)
		cyl(r, "Bin", 1.8, 2.8, L(-58, F + 1.4, -70) * CFrame.Angles(0, 0, math.rad(90)), rgb(60, 150, 80))
	end

	-- GYMNASIUM: a wooden court, the lines, a hoop and a scoreboard on the back wall, bleachers along the
	-- front, a ball rack, banners
	if open.Gym then
		local r = room("Gym")
		local cx = -18
		part(r, "Court", Vector3.new(34.5, 0.12, 31.5), L(cx, F + 0.06, midZ - 0.25), rgb(222, 178, 118), Enum.Material.WoodPlanks)
		local LINE = WHITE
		local function line(size, x, z) part(r, "CourtLine", size, L(x, F + 0.14, z), LINE) end
		-- (a half court: its front line clear of the bleachers along the front wall)
		line(Vector3.new(32, 0.05, 0.3), cx, -74.5)
		line(Vector3.new(32, 0.05, 0.3), cx, -97.5)
		line(Vector3.new(0.3, 0.05, 23), cx - 16, -86)
		line(Vector3.new(0.3, 0.05, 23), cx + 16, -86)
		-- the key and the free-throw circle under the hoop
		part(r, "Key", Vector3.new(10, 0.1, 10), L(cx, F + 0.12, -92.5), rgb(200, 60, 60))
		line(Vector3.new(10, 0.05, 0.3), cx, -87.5)
		cyl(r, "FreeThrow", 8, 0.06, L(cx, F + 0.15, -87.5) * CFrame.Angles(0, 0, math.rad(90)), LINE)
		cyl(r, "FreeThrowInner", 7.4, 0.07, L(cx, F + 0.16, -87.5) * CFrame.Angles(0, 0, math.rad(90)), rgb(222, 178, 118), Enum.Material.WoodPlanks)
		-- the school's colour on the half-court line
		part(r, "HalfCourtStripe", Vector3.new(12, 0.06, 1.2), L(cx, F + 0.15, -75.6), look.sign)
		-- the hoop: backboard, rim, net, on an arm off the back wall
		part(r, "HoopArm", Vector3.new(0.6, 0.6, 3), L(cx, F + 11, Z1 + WT + 1.5), rgb(80, 80, 90), Enum.Material.Metal)
		part(r, "Backboard", Vector3.new(6, 3.6, 0.3), L(cx, F + 11.4, Z1 + WT + 3), WHITE, Enum.Material.Glass, { Transparency = 0.1 })
		part(r, "BackboardSquare", Vector3.new(2.2, 1.6, 0.32), L(cx, F + 10.9, Z1 + WT + 3), rgb(230, 60, 50))
		local rim = cyl(r, "Rim", 2.2, 0.15, L(cx, F + 9.9, Z1 + WT + 4.3) * CFrame.Angles(0, 0, math.rad(90)), rgb(240, 110, 30), Enum.Material.Metal)
		_ = rim
		part(r, "Net", Vector3.new(1.6, 1.4, 1.6), L(cx, F + 9.1, Z1 + WT + 4.3), WHITE, Enum.Material.Fabric, { Transparency = 0.35 })
		-- the scoreboard over the hoop
		local sb = part(r, "Scoreboard", Vector3.new(12, 4.2, 0.6), L(cx, F + 15.4, Z1 + WT + 0.35), rgb(25, 25, 32))
		text(sb, Enum.NormalId.Back, "HOME 21 \u{2022} AWAY 19", rgb(255, 90, 60), rgb(25, 25, 32), Enum.Font.Arcade)
		-- the bleachers along the front wall, either side of the doorway at -24
		for _, span in { { -35, -28 }, { -20, -2 } } do
			local w = span[2] - span[1]
			for k = 0, 2 do
				-- (the lowest row nearest the court, the highest against the wall)
				local bz = Z0 - 6.4 + k * 1.8
				part(r, "Bleacher", Vector3.new(w, 0.5, 1.8), L((span[1] + span[2]) / 2, F + 0.8 + k * 1.3, bz), rgb(200, 150, 90), Enum.Material.WoodPlanks)
				part(r, "BleacherRiser", Vector3.new(w, 0.8 + k * 1.3, 0.3), L((span[1] + span[2]) / 2, F + (0.8 + k * 1.3) / 2, bz - 0.9), rgb(90, 90, 100), Enum.Material.Metal)
			end
		end
		-- the ball rack and a few balls on the floor
		part(r, "BallRack", Vector3.new(1.2, 3.4, 5), L(-34.5, F + 1.7, -80), rgb(80, 80, 90), Enum.Material.Metal)
		for k = 0, 2 do ball(r, "Basketball", 1.2, L(-34.5, F + 1.6 + k * 1.2, -78.5 - k * 1.2), rgb(230, 120, 40)) end
		for k = 0, 2 do ball(r, "Basketball", 1.2, L(cx + rng:NextNumber(-10, 10), F + 0.6, rng:NextNumber(-94, -76)), rgb(230, 120, 40)) end
		-- banners in the school's colours on the side wall
		for k = 0, 2 do
			local b = part(r, "Banner", Vector3.new(0.2, 4.4, 3.2), L(-1.4, F + 13, -74 - k * 9), k % 2 == 0 and look.sign or look.cap, Enum.Material.Fabric)
			text(b, Enum.NormalId.Left, ({ "\u{1F3C6}\nCHAMPS", "GO\nTEAM!", "\u{2B50}\nMVP" })[k + 1], WHITE, nil, Enum.Font.LuckiestGuy)
		end
	end

	-- AUDITORIUM: the stage at the back, curtains, footlights, a lighting bar; seats facing it
	if open.Auditorium then
		local r = room("Auditorium")
		local cx = 18
		local STAGE_Z = -88
		local stageH = 3
		part(r, "Carpet", Vector3.new(34.5, 0.1, 20), L(cx, F + 0.05, -77.5), rgb(150, 40, 50), Enum.Material.Fabric)
		part(r, "Stage", Vector3.new(34.5, stageH, STAGE_Z - (Z1 + WT)), L(cx, F + stageH / 2, (STAGE_Z + Z1 + WT) / 2), rgb(120, 80, 50), Enum.Material.WoodPlanks)
		part(r, "StageLip", Vector3.new(34.5, 0.4, 0.8), L(cx, F + stageH + 0.1, STAGE_Z + 0.2), rgb(90, 60, 40), Enum.Material.Wood)
		for k = 0, 2 do part(r, "StageStep", Vector3.new(4, (k + 1) * stageH / 3, 1.2), L(cx - 13, F + (k + 1) * stageH / 6, STAGE_Z + 3.4 - k * 1.2), rgb(120, 80, 50), Enum.Material.WoodPlanks) end
		-- the curtains: a drape each side, the valance across the top, gold fringe
		local RED = rgb(200, 30, 45)
		for _, s in { -1, 1 } do
			for k = 0, 3 do
				part(r, "Curtain", Vector3.new(1.4, TOP - F - stageH - 2.6, 1), L(cx + s * (15.6 - k * 1.3), F + stageH + (TOP - F - stageH - 2.6) / 2, STAGE_Z - 0.8 - (k % 2) * 0.3), RED, Enum.Material.Fabric)
			end
		end
		part(r, "Valance", Vector3.new(34, 2.6, 1.2), L(cx, TOP - 1.9, STAGE_Z - 0.9), RED, Enum.Material.Fabric)
		part(r, "Fringe", Vector3.new(34, 0.4, 1.3), L(cx, TOP - 3.3, STAGE_Z - 0.9), rgb(255, 200, 60), Enum.Material.Fabric)
		-- the back curtain, the play's scenery (a painted sun and hills) and a banner
		part(r, "Backdrop", Vector3.new(30, TOP - F - stageH - 1, 0.3), L(cx, F + stageH + (TOP - F - stageH - 1) / 2, Z1 + WT + 0.3), rgb(110, 180, 240), Enum.Material.Fabric)
		-- (the scenery is painted flats: discs facing the seats, the hills' lower halves in the stage.
		-- Balls stuck out through the back wall onto the grass behind the school)
		local FLAT = CFrame.Angles(0, math.rad(90), 0)
		cyl(r, "PaintedSun", 5, 0.2, L(cx + 8, F + 13, Z1 + WT + 0.55) * FLAT, rgb(255, 214, 70))
		for i, h in { { -6, 16 }, { 5, 20 } } do
			cyl(r, "PaintedHill", h[2], 0.2, L(cx + h[1], F + stageH, Z1 + WT + 0.6 + i * 0.05) * FLAT, rgb(100, 190, 90))
		end
		local playSign = part(r, "PlaySign", Vector3.new(16, 2.4, 0.3), L(cx, TOP - 5, Z1 + WT + 0.9), rgb(255, 250, 235))
		text(playSign, Enum.NormalId.Back, "\u{2B50} THE SCHOOL PLAY \u{2B50}", RED, rgb(255, 250, 235), Enum.Font.LuckiestGuy)
		-- footlights along the stage edge, a bar of spotlights over it
		for k = 0, 7 do ball(r, "Footlight", 0.7, L(cx - 14 + k * 4, F + stageH + 0.3, STAGE_Z + 0.9), rgb(255, 240, 180), Enum.Material.Neon) end
		part(r, "LightBar", Vector3.new(30, 0.5, 0.5), L(cx, TOP - 1.2, STAGE_Z + 4), rgb(40, 40, 46), Enum.Material.Metal)
		for k = 0, 4 do
			local sx = cx - 12 + k * 6
			part(r, "Spotlight", Vector3.new(1.2, 1.4, 1.6), L(sx, TOP - 2.2, STAGE_Z + 4) * CFrame.Angles(math.rad(-35), 0, 0), rgb(30, 30, 36), Enum.Material.Metal)
			local lens = ball(r, "SpotLens", 0.9, L(sx, TOP - 2.6, STAGE_Z + 3.3), ({ rgb(255, 120, 120), rgb(255, 230, 150), rgb(150, 200, 255) })[k % 3 + 1], Enum.Material.Neon)
			if k == 2 then
				local spot = Instance.new("SpotLight")
				spot.Face = Enum.NormalId.Bottom
				spot.Angle = 70
				spot.Range = 24
				spot.Brightness = 2
				spot.Color = rgb(255, 240, 200)
				spot.Parent = lens
			end
		end
		-- the seats: five rows of seven, red, a centre aisle
		for row = 0, 4 do
			for k = 0, 6 do
				local sx = cx - 14.5 + k * 4.2 + (k >= 4 and 1.8 or 0) - 0.9
				local sz = -72 - row * 3.2
				part(r, "Seat", Vector3.new(3, 0.6, 2.2), L(sx, F + 1.6, sz), RED, Enum.Material.Fabric)
				part(r, "SeatBack", Vector3.new(3, 2.4, 0.5), L(sx, F + 2.9, sz + 1.1), RED, Enum.Material.Fabric)
				part(r, "SeatLeg", Vector3.new(2.4, 1.3, 1.8), L(sx, F + 0.65, sz), rgb(40, 40, 46), Enum.Material.Metal)
			end
		end
	end

	-- LIBRARY: shelves down both long walls and across the back, reading tables with lamps, bean bags,
	-- a globe, the librarian's desk
	if open.Library then
		local r = room("Library")
		local cx = 48
		local BOOK = { rgb(220, 60, 60), rgb(60, 120, 220), rgb(250, 200, 60), rgb(60, 180, 90), rgb(160, 80, 200), rgb(250, 140, 60), rgb(240, 240, 235) }
		local function shelf(cf, len)
			part(r, "Bookshelf", Vector3.new(len, 11, 2), cf * CFrame.new(0, 5.5, 0), rgb(150, 100, 60), Enum.Material.Wood)
			for s = 0, 3 do
				local y = 1.2 + s * 2.6
				local x = -len / 2 + 0.6
				while x < len / 2 - 0.8 do
					local w = rng:NextNumber(0.75, 1.25)
					local h = rng:NextNumber(1.4, 2.1)
					part(r, "Book", Vector3.new(w, h, 1.5), cf * CFrame.new(x + w / 2, y + h / 2, -0.3), BOOK[rng:NextInteger(1, #BOOK)])
					x += w + 0.05
				end
			end
		end
		-- (shelves: the far end wall, the back wall; the partition side keeps its doorway clear)
		-- (a shelf's books face its -Z: turned +90 about Y they face west, -90 east, 180 north)
		shelf(L(X - WT - 1.1, F, -83) * CFrame.Angles(0, math.pi / 2, 0), 24)
		shelf(L(cx + 2, F, Z1 + WT + 1.1) * CFrame.Angles(0, math.pi, 0), 18)
		shelf(L(37.6, F, -95) * CFrame.Angles(0, -math.pi / 2, 0), 7)
		shelf(L(37.6, F, -73) * CFrame.Angles(0, -math.pi / 2, 0), 8)
		-- a rug, two reading tables with green lamps, chairs
		part(r, "Rug", Vector3.new(14, 0.1, 18), L(cx - 1, F + 0.05, -83), rgb(60, 110, 170), Enum.Material.Fabric)
		for _, z in { -77, -89 } do
			part(r, "ReadingTable", Vector3.new(8, 0.5, 4), L(cx - 2, F + 3, z), rgb(140, 95, 55), Enum.Material.Wood)
			for _, dx in { -3.2, 3.2 } do part(r, "TableLeg", Vector3.new(0.5, 2.8, 0.5), L(cx - 2 + dx, F + 1.4, z), rgb(110, 75, 45), Enum.Material.Wood) end
			part(r, "LampBase", Vector3.new(0.4, 1.6, 0.4), L(cx - 2, F + 4, z), rgb(200, 170, 80), Enum.Material.Metal)
			local shade = part(r, "LampShade", Vector3.new(1.8, 0.7, 1.2), L(cx - 2, F + 4.9, z), rgb(40, 130, 70))
			H.light(shade, 10, 0.6, rgb(255, 235, 190))
			for _, dz in { -2.8, 2.8 } do
				part(r, "Chair", Vector3.new(2, 0.4, 2), L(cx - 2, F + 1.8, z + dz), rgb(90, 140, 200))
				part(r, "ChairBack", Vector3.new(2, 2.2, 0.3), L(cx - 2, F + 3, z + dz + (dz > 0 and 0.9 or -0.9)), rgb(90, 140, 200))
			end
		end
		-- bean bags in the reading nook, a globe, the librarian's desk and her sign
		for i, c in { rgb(255, 120, 170), rgb(255, 200, 60), rgb(120, 200, 255) } do
			ball(r, "BeanBag", 3, L(cx + 5 - i * 3.2, F + 1, -97 + (i % 2) * 1.5), c, Enum.Material.Fabric)
		end
		-- (the globe by the partition, the librarian's desk by the outside door, facing in)
		cyl(r, "GlobeStand", 0.5, 3, L(40.5, F + 1.5, -79.5) * CFrame.Angles(0, 0, math.rad(90)), rgb(150, 110, 60), Enum.Material.Wood)
		ball(r, "Globe", 2.2, L(40.5, F + 4, -79.5), rgb(60, 140, 230))
		part(r, "Desk", Vector3.new(3, 3.4, 7), L(56.5, F + 1.7, -72), rgb(140, 95, 55), Enum.Material.Wood)
		local quiet = part(r, "QuietSign", Vector3.new(0.2, 1.6, 4.4), L(54.9, F + 4.4, -72), rgb(255, 250, 235))
		text(quiet, Enum.NormalId.Left, "\u{1F92B} QUIET PLEASE", rgb(40, 40, 50), rgb(255, 250, 235), Enum.Font.FredokaOne)
		part(r, "BookStack", Vector3.new(1, 1.2, 1.4), L(56.5, F + 4, -69.5), rgb(220, 60, 60))
		if g and g.dome then H.dome(shell, L, cx, TOP + 1, midZ, 22, look) end
	end
	return m
end

return Annex
