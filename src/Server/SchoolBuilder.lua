-- ServerScriptService.Server.SchoolBuilder
-- Builds each plot's campus at runtime from parts: the school building (floors, windows, doors,
-- lobby with lockers, Principal's Office, stairs, classrooms), the roof and tier features, the
-- default yard, and the School Builder items the owner has bought.
--
-- Plot-local frame: origin at the plot centre on the ground, +Z faces the street.
--   lot: x -60..60, z -75..75       yard: z 16..75       building: x -40..40, z -66..16
-- Floors: floor f's walking surface is at floorTop(f) = 2 + 16 * (f - 1).
-- Slots: floor f holds desks (f-1)*16+1 .. f*16 in four rows of four; row 1 nearest the lobby.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local SchoolBuilder = {}

local FLOOR_H, F1 = 16, 2
local BX, ZF, ZB, WT = 40, 16, -66, 1.5
local DIVIDER_Z = 2
local DESK_COLS = { -24, -8, 8, 24 }
local DESK_ROWS = { -9, -23, -37, -51 }
local STAIR_Z0, STAIR_Z1 = 13, -13 -- stair bottom and top (z), rising toward -Z
local STAIR_X = { left = -35.5, right = 35.5 }

SchoolBuilder.FLOOR_H = FLOOR_H
SchoolBuilder.DESK_COLS = DESK_COLS
SchoolBuilder.DESK_ROWS = DESK_ROWS
SchoolBuilder.STAIR_X = STAIR_X
SchoolBuilder.STAIR_Z0 = STAIR_Z0
SchoolBuilder.STAIR_Z1 = STAIR_Z1

function SchoolBuilder.floorTop(f)
	return F1 + FLOOR_H * (f - 1)
end
local floorTop = SchoolBuilder.floorTop

-- which side the stair up from floor f is on (it alternates so flights never overlap)
function SchoolBuilder.stairSide(f)
	return f % 2 == 1 and "left" or "right"
end

local rgb = Color3.fromRGB
local WHITE = rgb(250, 250, 250)
local KEEP_SMOOTH = { [Enum.Material.Neon] = true, [Enum.Material.Glass] = true, [Enum.Material.Metal] = true, [Enum.Material.ForceField] = true }

---------------------------------------------------------------------------
-- part helpers
---------------------------------------------------------------------------
local function part(parent, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Plastic
	p.Anchored = true
	if KEEP_SMOOTH[p.Material] then
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
	else
		p.TopSurface = Enum.SurfaceType.Studs
		p.BottomSurface = Enum.SurfaceType.Inlet
	end
	if props then
		for k, v in props do p[k] = v end
	end
	p.Parent = parent
	return p
end

local function ball(parent, name, d, cf, color, material)
	return part(parent, name, Vector3.new(d, d, d), cf, color, material, { Shape = Enum.PartType.Ball })
end

local function cyl(parent, name, d, len, cf, color, material)
	-- cylinder along the CFrame's X axis
	return part(parent, name, Vector3.new(len, d, d), cf, color, material, { Shape = Enum.PartType.Cylinder })
end

local function wedge(parent, name, size, cf, color, material)
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.CFrame = cf
	w.Color = color
	w.Material = material or Enum.Material.Plastic
	w.Anchored = true
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.Parent = parent
	return w
end

local function surfaceText(p, face, text, color, bg, font)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.LightInfluence = 0.2
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Name = "Label"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = bg and 0 or 1
	t.BackgroundColor3 = bg or WHITE
	t.Text = text
	t.TextScaled = true
	t.Font = font or Enum.Font.FredokaOne
	t.TextColor3 = color
	t.Parent = g
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.08, 0)
	pad.PaddingBottom = UDim.new(0.08, 0)
	pad.PaddingLeft = UDim.new(0.03, 0)
	pad.PaddingRight = UDim.new(0.03, 0)
	pad.Parent = t
	return t
end

local function light(p, range, brightness, color)
	local l = Instance.new("PointLight")
	l.Range = range
	l.Brightness = brightness
	l.Color = color or rgb(255, 244, 220)
	l.Shadows = false
	l.Parent = p
	return l
end

---------------------------------------------------------------------------
-- walls with openings
---------------------------------------------------------------------------
-- A wall along X at z = zc from x0..x1, y0..y1. openings: { {a, b, bottom, top, kind} } sorted by a.
-- kind: "window" (glass + frame), "door" (frame, left open), "open" (nothing).
local function wallX(folder, L, zc, x0, x1, y0, y1, openings, color, trim, thick)
	thick = thick or WT
	local function seg(a, b, ya, yb)
		ya, yb = math.max(ya, y0), math.min(yb, y1)
		if b - a < 0.05 or yb - ya < 0.05 then return end
		part(folder, "Wall", Vector3.new(b - a, yb - ya, thick), L((a + b) / 2, (ya + yb) / 2, zc), color)
	end
	local x = x0
	for _, op in openings do
		seg(x, op.a, y0, y1)
		seg(op.a, op.b, y0, op.bottom)
		seg(op.a, op.b, op.top, y1)
		local w, h = op.b - op.a, op.top - op.bottom
		local cx, cy = (op.a + op.b) / 2, (op.bottom + op.top) / 2
		if op.kind == "window" then
			part(folder, "Glass", Vector3.new(w, h, 0.25), L(cx, cy, zc), rgb(190, 225, 255), Enum.Material.Glass, { Transparency = 0.45, CastShadow = false })
			part(folder, "Frame", Vector3.new(w + 0.8, 0.5, thick + 0.4), L(cx, op.top + 0.25, zc), trim)
			part(folder, "Sill", Vector3.new(w + 1.4, 0.5, thick + 1), L(cx, op.bottom - 0.25, zc), trim)
			part(folder, "Frame", Vector3.new(0.5, h, thick + 0.4), L(op.a - 0.25 + 0.25, cy, zc), trim)
			part(folder, "Frame", Vector3.new(0.5, h, thick + 0.4), L(op.b + 0.25 - 0.25, cy, zc), trim)
			part(folder, "Mullion", Vector3.new(0.3, h, 0.4), L(cx, cy, zc), trim)
			part(folder, "Mullion", Vector3.new(w, 0.3, 0.4), L(cx, cy + h * 0.1, zc), trim)
		elseif op.kind == "door" then
			part(folder, "Frame", Vector3.new(w + 1, 0.8, thick + 0.5), L(cx, op.top + 0.4, zc), trim)
			part(folder, "Frame", Vector3.new(0.6, h, thick + 0.5), L(op.a - 0.3, cy, zc), trim)
			part(folder, "Frame", Vector3.new(0.6, h, thick + 0.5), L(op.b + 0.3, cy, zc), trim)
		end
		x = op.b
	end
	seg(x, x1, y0, y1)
end

-- the same along Z at x = xc from z0..z1; openings use z for a/b
local function wallZ(folder, L, xc, z0, z1, y0, y1, openings, color, trim, thick)
	thick = thick or WT
	local function seg(a, b, ya, yb)
		ya, yb = math.max(ya, y0), math.min(yb, y1)
		if b - a < 0.05 or yb - ya < 0.05 then return end
		part(folder, "Wall", Vector3.new(thick, yb - ya, b - a), L(xc, (ya + yb) / 2, (a + b) / 2), color)
	end
	local z = z0
	for _, op in openings do
		seg(z, op.a, y0, y1)
		seg(op.a, op.b, y0, op.bottom)
		seg(op.a, op.b, op.top, y1)
		local w, h = op.b - op.a, op.top - op.bottom
		local cz, cy = (op.a + op.b) / 2, (op.bottom + op.top) / 2
		if op.kind == "window" then
			part(folder, "Glass", Vector3.new(0.25, h, w), L(xc, cy, cz), rgb(190, 225, 255), Enum.Material.Glass, { Transparency = 0.45, CastShadow = false })
			part(folder, "Frame", Vector3.new(thick + 0.4, 0.5, w + 0.8), L(xc, op.top + 0.25, cz), trim)
			part(folder, "Sill", Vector3.new(thick + 1, 0.5, w + 1.4), L(xc, op.bottom - 0.25, cz), trim)
			part(folder, "Frame", Vector3.new(thick + 0.4, h, 0.5), L(xc, cy, op.a), trim)
			part(folder, "Frame", Vector3.new(thick + 0.4, h, 0.5), L(xc, cy, op.b), trim)
			part(folder, "Mullion", Vector3.new(0.4, h, 0.3), L(xc, cy, cz), trim)
			part(folder, "Mullion", Vector3.new(0.4, 0.3, w), L(xc, cy + h * 0.1, cz), trim)
		elseif op.kind == "door" then
			part(folder, "Frame", Vector3.new(thick + 0.5, 0.8, w + 1), L(xc, op.top + 0.4, cz), trim)
		end
		z = op.b
	end
	seg(z, z1, y0, y1)
end

local function windowsAt(centers, width, bottom, top)
	local out = {}
	for _, c in centers do
		table.insert(out, { a = c - width / 2, b = c + width / 2, bottom = bottom, top = top, kind = "window" })
	end
	table.sort(out, function(p, q) return p.a < q.a end)
	return out
end

---------------------------------------------------------------------------
-- desks (same interface the rest of the game uses)
---------------------------------------------------------------------------
local function desk(parent, L, slot, row, dx, dz, y0, look)
	local d = Instance.new("Model")
	d.Name = "Desk" .. slot
	d:SetAttribute("Slot", slot)
	d:SetAttribute("Row", row)
	local wood, metal = look.desk or rgb(214, 160, 100), rgb(90, 95, 110)
	local top = part(d, "Top", Vector3.new(6, 0.5, 3.4), L(dx, y0 + 3.3, dz), wood, Enum.Material.Wood)
	-- two side panels instead of four legs, and a book cubby under the top
	for _, lx in { -2.7, 2.7 } do
		part(d, "Leg", Vector3.new(0.35, 3, 3), L(dx + lx, y0 + 1.55, dz), metal, Enum.Material.Metal)
	end
	part(d, "Cubby", Vector3.new(5.1, 0.25, 2.6), L(dx, y0 + 2.4, dz - 0.2), metal, Enum.Material.Metal)
	part(d, "Seat", Vector3.new(2.8, 0.45, 2.6), L(dx, y0 + 2.1, dz + 3.3), look.chair or rgb(60, 132, 232))
	part(d, "Backrest", Vector3.new(2.8, 2.4, 0.35), L(dx, y0 + 3.6, dz + 4.5), look.chair or rgb(60, 132, 232))
	part(d, "ChairLeg", Vector3.new(2.4, 1.85, 2.2), L(dx, y0 + 0.95, dz + 3.3), metal, Enum.Material.Metal, { Transparency = 0.55 })
	part(d, "SitPoint", Vector3.new(1, 1, 1), L(dx, y0 + 3.6, dz + 3.1), WHITE, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local pad = part(d, "CollectPad", Vector3.new(3.4, 0.3, 3.4), L(dx + 5.1, y0 + 0.2, dz + 3.2), rgb(70, 230, 110), Enum.Material.Neon)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Cash"
	bb.Size = UDim2.fromOffset(140, 36)
	bb.StudsOffset = Vector3.new(0, 1.8, 0)
	bb.MaxDistance = 60
	bb.LightInfluence = 0
	bb.Parent = pad
	local t = Instance.new("TextLabel")
	t.Name = "Label"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = ""
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = rgb(120, 255, 120)
	t.Parent = bb
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Parent = t
	d.PrimaryPart = top
	d.Parent = parent
	return d
end

---------------------------------------------------------------------------
-- one floor of the building
---------------------------------------------------------------------------
local POSTERS = {
	{ "READ!", rgb(255, 90, 90) }, { "MATH IS FUN", rgb(70, 150, 255) }, { "BE KIND", rgb(90, 200, 110) },
	{ "SCIENCE ROCKS", rgb(170, 90, 255) }, { "NO RUNNING", rgb(255, 170, 40) }, { "WORK HARD", rgb(40, 180, 200) },
}

local function buildFloor(school, L, f, floors, look, isRoof)
	local fm = Instance.new("Model")
	fm.Name = "Floor" .. f
	fm.Parent = school.Floors
	local walls = Instance.new("Folder")
	walls.Name = "Walls"
	walls.Parent = fm
	local interior = Instance.new("Folder")
	interior.Name = "Interior"
	interior.Parent = fm
	local ft = floorTop(f)
	local y0 = f == 1 and 0 or ft - 1
	local y1 = ft + 15
	local wall, trim, inner = look.wall, look.cap, look.inner or rgb(250, 240, 220)

	-- stairs touching this floor: one coming up from below, one going up from here
	local holeSide = f > 1 and SchoolBuilder.stairSide(f - 1) or nil
	local upSide = f < floors and SchoolBuilder.stairSide(f) or nil

	-- floor surface
	if f == 1 then
		part(fm, "Foundation", Vector3.new(BX * 2 + 1, F1 - 0.2, ZF - ZB + 1), L(0, (F1 - 0.2) / 2 + 0.2, (ZF + ZB) / 2), look.foundation or rgb(150, 150, 160))
	else
		-- slab with a hole over the stair from below (hole: side column, z STAIR_Z1..14)
		local hx0, hx1 = holeSide == "left" and -BX or 32, holeSide == "left" and -32 or BX
		local sy = ft - 0.5
		part(fm, "Slab", Vector3.new(BX * 2, 1, 14 - ZB - (14 - STAIR_Z1) + 0), L(0, sy, (ZB + STAIR_Z1) / 2), look.floor)
		part(fm, "Slab", Vector3.new(BX * 2, 1, ZF - 14), L(0, sy, (14 + ZF) / 2), look.floor)
		local w = BX * 2 - (hx1 - hx0)
		local cx = holeSide == "left" and (-32 + BX) / 2 or (-BX + 32) / 2
		part(fm, "Slab", Vector3.new(w, 1, 14 - STAIR_Z1), L(cx, sy, (STAIR_Z1 + 14) / 2), look.floor)
		-- railing around the hole
		local rx = holeSide == "left" and -32 or 32
		part(interior, "Railing", Vector3.new(0.4, 3.4, 14 - STAIR_Z1), L(rx, ft + 1.7, (STAIR_Z1 + 14) / 2), trim)
		part(interior, "Railing", Vector3.new(8, 3.4, 0.4), L((hx0 + hx1) / 2, ft + 1.7, 14), trim)
	end
	-- classroom tiles (checker) and lobby floor
	local tiles = Instance.new("Folder")
	tiles.Name = "Tiles"
	tiles.Parent = fm
	for tx = -BX + 5, BX - 5, 10 do
		for tz = ZB + 5, DIVIDER_Z - 5, 10 do
			local inHole = holeSide and ((holeSide == "left" and tx < -30) or (holeSide == "right" and tx > 30)) and tz > STAIR_Z1 - 2
			if not inHole then
				local dark = ((tx + tz + 1000) / 10) % 2 < 1
				part(tiles, "Tile", Vector3.new(10, 0.06, 10), L(tx, ft + 0.03, tz), dark and look.tile or look.floor, nil, { CanCollide = false, CanQuery = false })
			end
		end
	end
	do
		local lx0, lx1 = -BX + 0.5, BX - 0.5
		if holeSide == "left" then lx0 = -32 elseif holeSide == "right" then lx1 = 32 end
		part(tiles, "LobbyFloor", Vector3.new(lx1 - lx0, 0.06, ZF - DIVIDER_Z - 1), L((lx0 + lx1) / 2, ft + 0.03, (ZF + DIVIDER_Z) / 2), look.lobby or rgb(230, 222, 205), nil, { CanCollide = false, CanQuery = false })
	end

	-- exterior walls
	local sill, top = ft + 3.5, ft + 11
	local front
	if f == 1 then
		front = windowsAt({ -30, -18, 18, 30 }, 7, sill, top)
		table.insert(front, { a = -4, b = 4, bottom = ft, top = ft + 10, kind = "door" })
		table.sort(front, function(p, q) return p.a < q.a end)
	else
		front = windowsAt({ -30, -18, 0, 18, 30 }, 7, sill, top)
	end
	wallX(walls, L, ZF, -BX, BX, y0, y1, front, wall, trim)
	wallX(walls, L, ZB, -BX, BX, y0, y1, windowsAt({ -24, 24 }, 7, sill, top), wall, trim)
	wallZ(walls, L, -BX, ZB + WT / 2, ZF - WT / 2, y0, y1, windowsAt({ -55, -41, -27, 8 }, 8, sill, top), wall, trim)
	wallZ(walls, L, BX, ZB + WT / 2, ZF - WT / 2, y0, y1, windowsAt({ -55, -41, -27, 8 }, 8, sill, top), wall, trim)
	-- inside skin: pale plaster above a wainscot band, cut around the same openings
	do
		local function open(list)
			local out = {}
			for _, op in list do
				table.insert(out, { a = op.a, b = op.b, bottom = op.bottom, top = op.top, kind = "open" })
			end
			return out
		end
		local skin = Instance.new("Folder")
		skin.Name = "Skin"
		skin.Parent = walls
		local wains = look.wainscot or wall:Lerp(inner, 0.3)
		local cut = ft + 3.3
		local S, off = 0.15, WT / 2 + 0.075
		local sides = {
			{ "x", ZF - off, -BX + WT / 2, BX - WT / 2, front },
			{ "x", ZB + off, -BX + WT / 2, BX - WT / 2, windowsAt({ -24, 24 }, 7, sill, top) },
			{ "z", -BX + off, ZB + WT / 2, ZF - WT / 2, windowsAt({ -55, -41, -27, 8 }, 8, sill, top) },
			{ "z", BX - off, ZB + WT / 2, ZF - WT / 2, windowsAt({ -55, -41, -27, 8 }, 8, sill, top) },
		}
		for _, s in sides do
			local fn = s[1] == "x" and wallX or wallZ
			fn(skin, L, s[2], s[3], s[4], ft, cut, open(s[5]), wains, nil, S)
			fn(skin, L, s[2], s[3], s[4], cut, y1, open(s[5]), inner, nil, S)
		end
	end
	-- a band of trim between floors, outside
	local band = Instance.new("Folder")
	band.Name = "Caps"
	band.Parent = fm
	part(band, "Band", Vector3.new(BX * 2 + 1.2, 0.8, 0.6), L(0, y1 + 0.2, ZF + WT / 2 + 0.3), trim)
	part(band, "Band", Vector3.new(BX * 2 + 1.2, 0.8, 0.6), L(0, y1 + 0.2, ZB - WT / 2 - 0.3), trim)
	part(band, "Band", Vector3.new(0.6, 0.8, ZF - ZB + 1.2), L(-BX - WT / 2 - 0.3, y1 + 0.2, (ZF + ZB) / 2), trim)
	part(band, "Band", Vector3.new(0.6, 0.8, ZF - ZB + 1.2), L(BX + WT / 2 + 0.3, y1 + 0.2, (ZF + ZB) / 2), trim)

	-- lobby / classroom divider with a wide doorway; leave the stair column open
	local leftOpen = upSide == "left" or holeSide == "left"
	local rightOpen = upSide == "right" or holeSide == "right"
	local xa = leftOpen and -32 or -BX + WT / 2
	local xb = rightOpen and 32 or BX - WT / 2
	wallX(interior, L, DIVIDER_Z, xa, xb, ft, ft + 15, { { a = -6, b = 6, bottom = ft, top = ft + 10, kind = "door" } }, inner, trim, 0.8)

	-- stair up from this floor
	if upSide then
		local sx = STAIR_X[upSide]
		local inner_x = upSide == "left" and -32 or 32
		local steps = 16
		local run = (STAIR_Z0 - STAIR_Z1) / steps
		local stairs = Instance.new("Folder")
		stairs.Name = "Stairs"
		stairs.Parent = fm
		for k = 1, steps do
			local zc = STAIR_Z0 - (k - 0.5) * run
			part(stairs, "Step", Vector3.new(6, k, run), L(sx, ft + k / 2, zc), look.stair or rgb(170, 170, 180))
			part(stairs, "Nosing", Vector3.new(6.1, 0.2, 0.3), L(sx, ft + k + 0.05, zc + run / 2 - 0.15), trim)
			-- balustrade on the open side
			part(stairs, "Rail", Vector3.new(0.35, 3.2, run), L(inner_x, ft + k + 1.6, zc), trim)
		end
	end

	-- lockers along the lobby front wall
	local lockers = Instance.new("Folder")
	lockers.Name = "Lockers"
	lockers.Parent = fm
	local function lockerRun(xFrom, xTo)
		local n = math.floor((xTo - xFrom) / 2)
		for i = 0, n - 1 do
			local lx = xFrom + 1 + i * 2
			part(lockers, "Locker", Vector3.new(1.9, 6.5, 1.4), L(lx, ft + 3.25, ZF - WT / 2 - 0.75), look.locker or rgb(60, 120, 220), Enum.Material.Metal)
			part(lockers, "Vent", Vector3.new(1.2, 0.8, 0.1), L(lx, ft + 5.6, ZF - WT / 2 - 1.47), rgb(40, 40, 50))
			part(lockers, "Handle", Vector3.new(0.2, 0.6, 0.15), L(lx + 0.6, ft + 3.2, ZF - WT / 2 - 1.5), rgb(210, 210, 220), Enum.Material.Metal)
		end
	end
	local leftStart = (upSide == "left" or holeSide == "left") and -30 or -38
	lockerRun(leftStart, -7)
	if f == 1 then
		lockerRun(7, 19)
	else
		lockerRun(7, (upSide == "right" or holeSide == "right") and 30 or 38)
	end

	-- chalkboard wall: board, frame, tray, clock, alphabet strip
	local classroom = Instance.new("Folder")
	classroom.Name = "Classroom"
	classroom.Parent = fm
	local boardZ = ZB + WT / 2 + 0.35
	local board = part(classroom, "Chalkboard", Vector3.new(30, 7, 0.3), L(0, ft + 7, boardZ), look.board or rgb(38, 74, 56))
	part(classroom, "BoardFrame", Vector3.new(31.2, 8.2, 0.2), L(0, ft + 7, boardZ - 0.1), rgb(150, 100, 60), Enum.Material.Wood)
	part(classroom, "ChalkTray", Vector3.new(30, 0.3, 0.8), L(0, ft + 3.4, boardZ + 0.4), rgb(150, 100, 60), Enum.Material.Wood)
	local lesson = surfaceText(board, Enum.NormalId.Back, f == 1 and "Welcome to class!" or ("Floor " .. f), rgb(240, 240, 230), nil, Enum.Font.PermanentMarker)
	lesson.Name = "Lesson"
	local clock = cyl(classroom, "Clock", 2.6, 0.3, L(0, ft + 12.3, boardZ + 0.1) * CFrame.Angles(0, math.rad(90), 0), WHITE)
	cyl(classroom, "ClockRim", 2.9, 0.2, L(0, ft + 12.3, boardZ) * CFrame.Angles(0, math.rad(90), 0), rgb(40, 40, 45))
	part(classroom, "Hand", Vector3.new(0.12, 0.9, 0.05), L(0, ft + 12.65, boardZ + 0.3), rgb(20, 20, 20))
	part(classroom, "Hand", Vector3.new(0.7, 0.12, 0.05), L(0.3, ft + 12.3, boardZ + 0.3), rgb(20, 20, 20))
	local abc = part(classroom, "Alphabet", Vector3.new(34, 1.2, 0.1), L(0, ft + 10.9, boardZ), WHITE)
	surfaceText(abc, Enum.NormalId.Back, "Aa  Bb  Cc  Dd  Ee  Ff  Gg  Hh  Ii  Jj", rgb(60, 60, 80), WHITE)
	_ = clock
	-- teacher's desk with a globe and an apple, and the spot the teacher stands on
	part(classroom, "TeacherDesk", Vector3.new(9, 3.2, 3.5), L(-15, ft + 1.6, ZB + 9), rgb(150, 100, 60), Enum.Material.Wood)
	ball(classroom, "Globe", 1.6, L(-12.5, ft + 4.4, ZB + 9), rgb(60, 140, 230))
	part(classroom, "GlobeStand", Vector3.new(0.3, 0.8, 0.3), L(-12.5, ft + 3.6, ZB + 9), rgb(200, 160, 60), Enum.Material.Metal)
	ball(classroom, "Apple", 0.8, L(-17.5, ft + 3.6, ZB + 9), rgb(220, 30, 40))
	part(classroom, "TeacherSpot", Vector3.new(1, 1, 1), L(0, ft, ZB + 7) * CFrame.Angles(0, math.pi, 0), WHITE, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	-- bookshelf in the back corner
	part(classroom, "Bookshelf", Vector3.new(8, 7, 1.6), L(BX - 6, ft + 3.5, ZB + 1.8), rgb(140, 95, 55), Enum.Material.Wood)
	local bookColors = { rgb(220, 60, 60), rgb(60, 120, 220), rgb(250, 200, 60), rgb(60, 180, 90), rgb(160, 80, 200) }
	for shelf = 0, 2 do
		for i = 0, 9 do
			local c = bookColors[(i + shelf) % #bookColors + 1]
			part(classroom, "Book", Vector3.new(0.6, 1.5 + (i % 3) * 0.2, 1.1), L(BX - 9.2 + i * 0.7, ft + 1.3 + shelf * 2.2, ZB + 2.2), c)
		end
	end
	-- a flag in the other corner
	part(classroom, "FlagPole", Vector3.new(0.25, 7, 0.25), L(-BX + 3, ft + 3.5, ZB + 3), rgb(200, 200, 205), Enum.Material.Metal)
	part(classroom, "Flag", Vector3.new(0.1, 2.2, 3.2), L(-BX + 3, ft + 5.8, ZB + 4.7), look.sign)
	-- posters between the side windows
	local pi = (f - 1) * 2
	for _, side in { -1, 1 } do
		for _, pz in { -48, -34 } do
			pi += 1
			local ps = POSTERS[(pi - 1) % #POSTERS + 1]
			local poster = part(classroom, "Poster", Vector3.new(0.12, 4, 3.4), L(side * (BX - WT / 2 - 0.25), ft + 7, pz), ps[2])
			surfaceText(poster, side < 0 and Enum.NormalId.Right or Enum.NormalId.Left, ps[1], WHITE, nil, Enum.Font.LuckiestGuy)
		end
	end
	-- ceiling lights
	for _, lx in { -20, 0, 20 } do
		for _, lz in { -50, -28, -8 } do
			local lamp = part(classroom, "CeilingLight", Vector3.new(6, 0.25, 2), L(lx, ft + 14.8, lz), rgb(255, 252, 240), Enum.Material.Neon, { CastShadow = false })
			if lz == -28 then light(lamp, 24, 0.3) end
		end
	end
	for _, lx in { -22, 22 } do
		local lamp = part(classroom, "CeilingLight", Vector3.new(4, 0.25, 2), L(lx, ft + 14.8, 9), rgb(255, 252, 240), Enum.Material.Neon, { CastShadow = false })
		light(lamp, 18, 0.3)
	end

	-- desks
	local desks = Instance.new("Folder")
	desks.Name = "Desks"
	desks.Parent = fm
	local slot = (f - 1) * 16
	for r, dz in DESK_ROWS do
		for _, dx in DESK_COLS do
			slot += 1
			desk(desks, L, slot, r, dx, dz, ft, look)
		end
	end

	-- the Principal's Office (ground floor, right end of the lobby)
	if f == 1 then
		local office = Instance.new("Model")
		office.Name = "Office"
		office.Parent = fm
		wallZ(office, L, 20, DIVIDER_Z + 0.4, ZF - WT / 2, ft, ft + 15, { { a = 7, b = 11.5, bottom = ft, top = ft + 9, kind = "door" } }, inner, trim, 0.8)
		local plaque = part(office, "Plaque", Vector3.new(0.15, 1.2, 4.5), L(19.5, ft + 10.2, 9.25), rgb(40, 60, 120))
		surfaceText(plaque, Enum.NormalId.Left, "PRINCIPAL", rgb(255, 220, 90), rgb(40, 60, 120), Enum.Font.LuckiestGuy)
		part(office, "Rug", Vector3.new(14, 0.08, 9), L(30, ft + 0.05, 9), rgb(140, 40, 50), nil, { CanCollide = false })
		part(office, "Desk", Vector3.new(4, 3, 8), L(30, ft + 1.5, 9), rgb(110, 70, 40), Enum.Material.Wood)
		part(office, "Chair", Vector3.new(2.6, 2.2, 2.6), L(33.5, ft + 1.1, 9), rgb(60, 30, 30))
		part(office, "ChairBack", Vector3.new(0.4, 3.5, 2.6), L(34.8, ft + 3.2, 9), rgb(60, 30, 30))
		part(office, "Nameplate", Vector3.new(0.3, 0.6, 2.2), L(28.2, ft + 3.3, 9), rgb(255, 210, 80), Enum.Material.Metal)
		part(office, "Shelf", Vector3.new(1.4, 7, 7), L(BX - WT / 2 - 0.9, ft + 3.5, 9), rgb(140, 95, 55), Enum.Material.Wood)
		part(office, "Plant", Vector3.new(1.4, 1.6, 1.4), L(37, ft + 0.8, 14), rgb(170, 90, 60))
		ball(office, "Leaves", 2.6, L(37, ft + 2.8, 14), rgb(60, 160, 70))
		part(office, "Diploma", Vector3.new(0.1, 1.8, 2.4), L(BX - WT / 2 - 0.22, ft + 9, 4.5), rgb(250, 245, 225))
		-- where caught cheaters wait
		local bench = part(office, "Bench", Vector3.new(6, 0.6, 1.8), L(26, ft + 1.6, DIVIDER_Z + 1.5), rgb(150, 100, 60), Enum.Material.Wood)
		bench:SetAttribute("OfficeBench", true)
		part(office, "BenchLegs", Vector3.new(5.6, 1.3, 1.4), L(26, ft + 0.65, DIVIDER_Z + 1.5), rgb(90, 95, 110), Enum.Material.Metal)
		-- trophy case in the lobby
		part(fm, "TrophyCase", Vector3.new(6, 5, 1.6), L(12, ft + 2.5, DIVIDER_Z + 1.3), rgb(150, 100, 60), Enum.Material.Wood)
		part(fm, "TrophyGlass", Vector3.new(5.6, 3.4, 1.7), L(12, ft + 3.3, DIVIDER_Z + 1.3), rgb(200, 230, 255), Enum.Material.Glass, { Transparency = 0.6 })
		for i = -1, 1 do
			cyl(fm, "Trophy", 0.9, 1.1, L(12 + i * 1.6, ft + 2.4, DIVIDER_Z + 1.3) * CFrame.Angles(0, 0, math.rad(90)), rgb(255, 205, 60), Enum.Material.Metal)
		end
	end
	return fm
end

---------------------------------------------------------------------------
-- facade, roof and tier features
---------------------------------------------------------------------------
local function buildFacade(school, L, floors, look, tierIndex, name)
	local ext = Instance.new("Folder")
	ext.Name = "Exterior"
	ext.Parent = school
	local trim = look.cap
	-- entrance steps, canopy, open double doors
	for i = 1, 3 do
		local h = (F1 - 0.4) * i / 3
		part(ext, "Step", Vector3.new(15 - i, h, 1.4), L(0, 0.4 + h / 2, ZF + WT / 2 + 4.2 - i * 1.4), look.foundation or rgb(150, 150, 160))
	end
	for _, side in { -1, 1 } do
		local leaf = part(ext, "Door", Vector3.new(0.3, 9.5, 3.8), L(side * 4.1, F1 + 4.75, ZF + WT / 2 + 1.9), look.door or rgb(200, 60, 50))
		part(ext, "DoorWindow", Vector3.new(0.35, 3, 2), L(side * 4.1, F1 + 6.5, ZF + WT / 2 + 1.9), rgb(190, 225, 255), Enum.Material.Glass, { Transparency = 0.3 })
		_ = leaf
	end
	local canopyY = F1 + 11
	part(ext, "Canopy", Vector3.new(14, 0.6, 5.5), L(0, canopyY, ZF + WT / 2 + 2.75), trim)
	if tierIndex >= 4 then
		-- a portico: four columns up to the second band and a triangular pediment
		local topY = floors > 1 and floorTop(2) + 14 or F1 + 14
		for _, cx in { -9, -3, 3, 9 } do
			cyl(ext, "Column", 1.6, topY - F1, L(cx, (F1 + topY) / 2, ZF + WT / 2 + 5) * CFrame.Angles(0, 0, math.rad(90)), look.column or WHITE)
			part(ext, "ColumnBase", Vector3.new(2.2, 0.6, 2.2), L(cx, F1 + 0.3, ZF + WT / 2 + 5), look.column or WHITE)
		end
		-- the entablature carries the school's name, so the columns never hide it
		local beam = part(ext, "NameBand", Vector3.new(24, 3.2, 7.4), L(0, topY + 1.6, ZF + WT / 2 + 3.5), look.sign)
		local label = surfaceText(beam, Enum.NormalId.Back, name, WHITE, look.sign, Enum.Font.LuckiestGuy)
		label.Name = "SchoolName"
		part(ext, "Cornice", Vector3.new(25, 0.6, 8), L(0, topY + 3.5, ZF + WT / 2 + 3.5), trim)
		wedge(ext, "Pediment", Vector3.new(1, 4, 12), L(-6, topY + 5.8, ZF + WT / 2 + 3.5) * CFrame.Angles(0, math.rad(90), 0), trim)
		wedge(ext, "Pediment", Vector3.new(1, 4, 12), L(6, topY + 5.8, ZF + WT / 2 + 3.5) * CFrame.Angles(0, math.rad(-90), 0), trim)
	else
		for _, cx in { -6.5, 6.5 } do
			part(ext, "CanopyPost", Vector3.new(0.6, canopyY - F1, 0.6), L(cx, (F1 + canopyY) / 2, ZF + WT / 2 + 5.2), trim)
		end
	end
	-- the school's name over the entrance (on the portico beam when there is one)
	if tierIndex < 4 then
		local band = part(ext, "NameBand", Vector3.new(26, 2.8, 0.4), L(0, F1 + 12.9, ZF + WT / 2 + 0.25), look.sign)
		local label = surfaceText(band, Enum.NormalId.Back, name, WHITE, look.sign, Enum.Font.LuckiestGuy)
		label.Name = "SchoolName"
	end
	-- bushes along the front
	for _, bx in { -36, -30, -24, -14, 14, 24, 30, 36 } do
		ball(ext, "Bush", 3.4, L(bx, 1.4, ZF + WT / 2 + 2.2), look.bush or rgb(60, 160, 70))
	end

	-- roof: slab, parapet, rooftop units
	local roofY = floorTop(floors) + 15
	local roof = Instance.new("Folder")
	roof.Name = "Roof"
	roof.Parent = school
	part(roof, "RoofSlab", Vector3.new(BX * 2 + 1.5, 1, ZF - ZB + 1.5), L(0, roofY + 0.5, (ZF + ZB) / 2), look.roof or rgb(120, 120, 130))
	local caps = Instance.new("Folder")
	caps.Name = "Caps"
	caps.Parent = school
	part(caps, "Parapet", Vector3.new(BX * 2 + 2, 2.4, 1.2), L(0, roofY + 2.2, ZF + 0.3), trim)
	part(caps, "Parapet", Vector3.new(BX * 2 + 2, 2.4, 1.2), L(0, roofY + 2.2, ZB - 0.3), trim)
	part(caps, "Parapet", Vector3.new(1.2, 2.4, ZF - ZB + 2), L(-BX - 0.3, roofY + 2.2, (ZF + ZB) / 2), trim)
	part(caps, "Parapet", Vector3.new(1.2, 2.4, ZF - ZB + 2), L(BX + 0.3, roofY + 2.2, (ZF + ZB) / 2), trim)
	for _, ax in { -22, 20 } do
		part(roof, "ACUnit", Vector3.new(6, 3, 4), L(ax, roofY + 2.5, -40), rgb(185, 190, 200), Enum.Material.Metal)
		cyl(roof, "Fan", 2.8, 0.3, L(ax, roofY + 4.1, -40) * CFrame.Angles(0, 0, math.rad(90)), rgb(90, 95, 105), Enum.Material.Metal)
	end
	part(roof, "Hatch", Vector3.new(5, 3.5, 5), L(-30, roofY + 2.75, -58), rgb(150, 150, 160))

	-- clock over the entrance (Elementary and up)
	if tierIndex >= 2 then
		part(roof, "ClockGable", Vector3.new(10, 6, 1.5), L(0, roofY + 3.5, ZF + 0.3), trim)
		cyl(roof, "ClockFace", 4.4, 0.3, L(0, roofY + 3.8, ZF + 1.2) * CFrame.Angles(0, math.rad(90), 0), WHITE)
		cyl(roof, "ClockRim", 4.9, 0.2, L(0, roofY + 3.8, ZF + 1.05) * CFrame.Angles(0, math.rad(90), 0), rgb(40, 40, 45))
		part(roof, "Hand", Vector3.new(0.25, 1.7, 0.1), L(0, roofY + 4.5, ZF + 1.45), rgb(20, 20, 20))
		part(roof, "Hand", Vector3.new(1.3, 0.25, 0.1), L(0.55, roofY + 3.8, ZF + 1.45), rgb(20, 20, 20))
	end
	-- towers for the grand schools
	local style = look.tower
	if style == "clock" or style == "bell" then
		local tx, tz = 0, -8
		part(roof, "Tower", Vector3.new(10, 12, 10), L(tx, roofY + 7, tz), look.wall)
		for _, face in { 0, 90, 180, 270 } do
			local cf = L(tx, roofY + 9, tz) * CFrame.Angles(0, math.rad(face), 0) * CFrame.new(0, 0, 5.05)
			cyl(roof, "TowerClock", 5, 0.2, cf * CFrame.Angles(0, math.rad(90), 0), WHITE)
		end
		part(roof, "Belfry", Vector3.new(8, 5, 8), L(tx, roofY + 15.5, tz), trim)
		ball(roof, "Bell", 3, L(tx, roofY + 15.3, tz), rgb(255, 200, 60), Enum.Material.Metal)
		wedge(roof, "Spire", Vector3.new(9, 6, 4.5), L(tx, roofY + 21, tz + 2.25) * CFrame.Angles(0, math.pi, 0), look.roof or rgb(120, 60, 60))
		wedge(roof, "Spire", Vector3.new(9, 6, 4.5), L(tx, roofY + 21, tz - 2.25), look.roof or rgb(120, 60, 60))
	elseif style == "spires" then
		for _, sx in { -30, 30 } do
			cyl(roof, "Turret", 6, 14, L(sx, roofY + 7, -2) * CFrame.Angles(0, 0, math.rad(90)), look.wall)
			wedge(roof, "Cone", Vector3.new(6, 9, 3), L(sx, roofY + 18.5, -0.5) * CFrame.Angles(0, math.pi, 0), trim)
			wedge(roof, "Cone", Vector3.new(6, 9, 3), L(sx, roofY + 18.5, -3.5), trim)
			ball(roof, "Orb", 1.4, L(sx, roofY + 23.5, -2), rgb(255, 220, 90), Enum.Material.Neon)
		end
	elseif style == "rocket" then
		cyl(roof, "Rocket", 6, 20, L(0, roofY + 11, -20) * CFrame.Angles(0, 0, math.rad(90)), rgb(240, 240, 245), Enum.Material.Metal)
		wedge(roof, "Nose", Vector3.new(6, 6, 3), L(0, roofY + 24, -18.5) * CFrame.Angles(0, math.pi, 0), rgb(230, 60, 50))
		wedge(roof, "Nose", Vector3.new(6, 6, 3), L(0, roofY + 24, -21.5), rgb(230, 60, 50))
		for _, a in { 0, 120, 240 } do
			part(roof, "Fin", Vector3.new(0.6, 5, 4), L(0, roofY + 3.5, -20) * CFrame.Angles(0, math.rad(a), 0) * CFrame.new(0, 0, 3.5), rgb(230, 60, 50))
		end
		ball(roof, "Window", 2.2, L(0, roofY + 15, -17), rgb(120, 200, 255), Enum.Material.Glass)
	elseif style == "portal" then
		for i = 0, 11 do
			local a = math.rad(i * 30)
			part(roof, "PortalRing", Vector3.new(2.2, 2.2, 1.5), L(math.cos(a) * 9, roofY + 12 + math.sin(a) * 9, -20), i % 2 == 0 and rgb(255, 80, 220) or rgb(80, 220, 255), Enum.Material.Neon)
		end
		part(roof, "PortalCore", Vector3.new(15, 15, 0.4), L(0, roofY + 12, -20), rgb(120, 60, 255), Enum.Material.ForceField, { Transparency = 0.2 })
	end
	return roofY
end

---------------------------------------------------------------------------
-- yard
---------------------------------------------------------------------------
local function tree(parent, L, x, z, s, leaf)
	part(parent, "Trunk", Vector3.new(1.6, 7, 1.6) * s, L(x, 3.5 * s, z), rgb(120, 80, 50))
	part(parent, "Leaves", Vector3.new(9, 4.5, 9) * s, L(x, 8 * s, z), leaf or rgb(60, 170, 70))
	part(parent, "Leaves", Vector3.new(6.5, 3.5, 6.5) * s, L(x, 11 * s, z), (leaf or rgb(60, 170, 70)):Lerp(WHITE, 0.08))
	part(parent, "Leaves", Vector3.new(3.5, 2.5, 3.5) * s, L(x, 13.5 * s, z), (leaf or rgb(60, 170, 70)):Lerp(WHITE, 0.16))
end
SchoolBuilder.tree = tree

local function buildYard(school, L, look)
	local yard = Instance.new("Folder")
	yard.Name = "Yard"
	yard.Parent = school
	-- front walk from the gate to the steps
	part(yard, "Walk", Vector3.new(12, 0.2, 75 - ZF - 5), L(0, 0.5, (75 + ZF + 5) / 2), rgb(205, 205, 212))
	for _, side in { -1, 1 } do
		part(yard, "WalkEdge", Vector3.new(0.6, 0.35, 75 - ZF - 5), L(side * 6.3, 0.55, (75 + ZF + 5) / 2), rgb(170, 170, 178))
	end
	-- flagpole
	part(yard, "FlagBase", Vector3.new(3, 0.8, 3), L(46, 0.8, 62), rgb(190, 190, 198))
	part(yard, "FlagPole", Vector3.new(0.45, 22, 0.45), L(46, 11.6, 62), rgb(225, 225, 230), Enum.Material.Metal)
	ball(yard, "Finial", 0.9, L(46, 22.9, 62), rgb(255, 205, 60), Enum.Material.Metal)
	for i = 0, 2 do
		part(yard, "Flag", Vector3.new(0.12, 1.2, 6), L(46, 21.6 - i * 1.2, 58.8), i == 1 and WHITE or look.sign)
	end
	-- benches along the walk
	for _, side in { -1, 1 } do
		part(yard, "BenchSeat", Vector3.new(1.8, 0.4, 6), L(side * 9.5, 1.9, 45), rgb(150, 100, 60), Enum.Material.Wood)
		part(yard, "BenchBack", Vector3.new(0.4, 1.8, 6), L(side * 10.4, 2.8, 45), rgb(150, 100, 60), Enum.Material.Wood)
		part(yard, "BenchLegs", Vector3.new(1.4, 1.5, 5.4), L(side * 9.5, 1.1, 45), rgb(80, 85, 95), Enum.Material.Metal, { Transparency = 0.4 })
	end
	-- trees at the building corners
	tree(yard, L, -52, 24, 1)
	tree(yard, L, 52, 24, 1)
	-- a bike rack by the gate
	part(yard, "BikeRack", Vector3.new(8, 0.3, 1.6), L(-40, 0.55, 68), rgb(80, 85, 95), Enum.Material.Metal)
	for i = -3, 3 do
		cyl(yard, "Hoop", 2.2, 0.2, L(-40 + i * 1.1, 1.6, 68) * CFrame.Angles(0, math.rad(90), 0), rgb(120, 125, 135), Enum.Material.Metal)
	end
end

---------------------------------------------------------------------------
-- School Builder items (bought upgrades that appear on the campus)
---------------------------------------------------------------------------
local Items = {}
SchoolBuilder.Items = Items

local function fence(parent, L, style, look)
	local function run(ax, az, bx, bz)
		local len = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
		local cx, cz = (ax + bx) / 2, (az + bz) / 2
		local yaw = math.atan2(bx - ax, bz - az)
		local cf = function(y) return L(cx, y, cz) * CFrame.Angles(0, yaw, 0) end
		if style == "picket" then
			part(parent, "Rail", Vector3.new(0.3, 0.4, len), cf(1.6), WHITE)
			part(parent, "Rail", Vector3.new(0.3, 0.4, len), cf(3.0), WHITE)
			local n = math.floor(len / 1.4)
			for i = 0, n do
				local t = (i / math.max(n, 1)) - 0.5
				part(parent, "Picket", Vector3.new(0.45, 4, 0.9), L(cx + (bx - ax) * t, 2.4, cz + (bz - az) * t) * CFrame.Angles(0, yaw, 0), WHITE)
			end
		elseif style == "brick" then
			part(parent, "Wall", Vector3.new(1.2, 4.5, len), cf(2.65), rgb(180, 80, 60))
			part(parent, "WallCap", Vector3.new(1.6, 0.5, len), cf(5.1), rgb(230, 225, 215))
			local n = math.floor(len / 12)
			for i = 0, n do
				local t = (i / math.max(n, 1)) - 0.5
				part(parent, "Pillar", Vector3.new(2.2, 6, 2.2), L(cx + (bx - ax) * t, 3.4, cz + (bz - az) * t) * CFrame.Angles(0, yaw, 0), rgb(160, 70, 55))
			end
		elseif style == "iron" then
			part(parent, "Rail", Vector3.new(0.3, 0.3, len), cf(6.2), rgb(30, 30, 35), Enum.Material.Metal)
			part(parent, "Base", Vector3.new(1.4, 1.2, len), cf(1), rgb(200, 195, 185))
			local n = math.floor(len / 0.9)
			for i = 0, n do
				local t = (i / math.max(n, 1)) - 0.5
				part(parent, "Bar", Vector3.new(0.2, 5.4, 0.2), L(cx + (bx - ax) * t, 4.1, cz + (bz - az) * t), rgb(30, 30, 35), Enum.Material.Metal)
			end
		end
	end
	run(-59, 74, -11, 74)
	run(11, 74, 59, 74)
	run(-59, 74, -59, -74)
	run(59, 74, 59, -74)
	run(-59, -74, 59, -74)
end

Items.PicketFence = function(parent, L, look) fence(parent, L, "picket", look) end
Items.BrickWall = function(parent, L, look) fence(parent, L, "brick", look) end
Items.IronFence = function(parent, L, look) fence(parent, L, "iron", look) end

Items.FlowerBeds = function(parent, L)
	local colors = { rgb(255, 90, 120), rgb(255, 200, 60), rgb(170, 110, 255), rgb(255, 140, 60) }
	for _, side in { -1, 1 } do
		part(parent, "Bed", Vector3.new(3, 0.8, 40), L(side * 8.5, 0.8, 50), rgb(110, 75, 50))
		for i = 0, 12 do
			ball(parent, "Flower", 1.1, L(side * 8.5 + (i % 2 - 0.5) * 1.2, 1.6, 32 + i * 3), colors[i % #colors + 1])
		end
	end
end

Items.Playground = function(parent, L)
	-- swings
	local ox, oz = -38, 44
	for _, sx in { -7, 7 } do
		part(parent, "SwingLeg", Vector3.new(0.5, 9, 0.5), L(ox + sx, 4.5, oz - 2) * CFrame.Angles(math.rad(12), 0, 0), rgb(230, 60, 60), Enum.Material.Metal)
		part(parent, "SwingLeg", Vector3.new(0.5, 9, 0.5), L(ox + sx, 4.5, oz + 2) * CFrame.Angles(math.rad(-12), 0, 0), rgb(230, 60, 60), Enum.Material.Metal)
	end
	part(parent, "SwingBar", Vector3.new(14.5, 0.5, 0.5), L(ox, 8.9, oz), rgb(230, 60, 60), Enum.Material.Metal)
	for _, sx in { -3.5, 0, 3.5 } do
		for _, cz in { -0.6, 0.6 } do
			part(parent, "Chain", Vector3.new(0.12, 5.6, 0.12), L(ox + sx + cz, 6, oz), rgb(170, 170, 180), Enum.Material.Metal)
		end
		part(parent, "Seat", Vector3.new(1.8, 0.25, 1), L(ox + sx, 3.1, oz), rgb(40, 40, 50))
	end
	-- slide with a ladder platform
	local sx, sz = -44, 60
	part(parent, "Platform", Vector3.new(4, 0.5, 4), L(sx, 6, sz), rgb(60, 140, 240))
	for _, px in { -1.8, 1.8 } do
		for _, pz in { -1.8, 1.8 } do
			part(parent, "Post", Vector3.new(0.4, 6, 0.4), L(sx + px, 3, sz + pz), rgb(255, 200, 40), Enum.Material.Metal)
		end
	end
	for i = 1, 5 do
		part(parent, "Rung", Vector3.new(3.6, 0.25, 0.25), L(sx, i * 1.1, sz + 2.2), rgb(255, 200, 40), Enum.Material.Metal)
	end
	wedge(parent, "Slide", Vector3.new(3, 6, 9), L(sx, 3, sz - 6.5), rgb(255, 90, 60))
	-- seesaw
	part(parent, "Pivot", Vector3.new(1, 1.4, 1), L(-26, 1.1, 64), rgb(90, 90, 100), Enum.Material.Metal)
	part(parent, "Board", Vector3.new(10, 0.4, 1.2), L(-26, 1.9, 64) * CFrame.Angles(0, 0, math.rad(10)), rgb(90, 200, 110))
	-- sandbox
	part(parent, "Sandbox", Vector3.new(8, 0.8, 8), L(-26, 0.8, 34), rgb(150, 110, 70), Enum.Material.Wood)
	part(parent, "Sand", Vector3.new(7, 0.3, 7), L(-26, 1.25, 34), rgb(235, 215, 160), Enum.Material.Sand)
end

Items.Court = function(parent, L)
	local cx, cz = 36, 44
	part(parent, "Court", Vector3.new(30, 0.2, 22), L(cx, 0.55, cz), rgb(230, 140, 70))
	part(parent, "Line", Vector3.new(0.3, 0.22, 22), L(cx, 0.57, cz), WHITE)
	cyl(parent, "Circle", 6, 0.22, L(cx, 0.58, cz) * CFrame.Angles(0, 0, math.rad(90)), WHITE)
	cyl(parent, "CircleIn", 5.4, 0.24, L(cx, 0.59, cz) * CFrame.Angles(0, 0, math.rad(90)), rgb(230, 140, 70))
	for _, side in { -1, 1 } do
		local hx = cx + side * 14
		part(parent, "HoopPole", Vector3.new(0.5, 10, 0.5), L(hx + side * 1.2, 5, cz), rgb(80, 85, 95), Enum.Material.Metal)
		part(parent, "Backboard", Vector3.new(0.3, 3.5, 5), L(hx, 10, cz), WHITE)
		cyl(parent, "Rim", 2, 0.2, L(hx - side * 1, 9, cz) * CFrame.Angles(0, 0, math.rad(90)), rgb(255, 90, 30), Enum.Material.Metal)
	end
	ball(parent, "Basketball", 1.3, L(cx + 3, 1.3, cz + 4), rgb(230, 110, 40))
end

Items.Fountain = function(parent, L)
	local fx, fz = -24, 66
	cyl(parent, "Basin", 9, 1.6, L(fx, 1.1, fz) * CFrame.Angles(0, 0, math.rad(90)), rgb(200, 200, 210))
	cyl(parent, "Water", 8, 1.7, L(fx, 1.2, fz) * CFrame.Angles(0, 0, math.rad(90)), rgb(90, 170, 255), Enum.Material.Glass)
	cyl(parent, "Column", 1.5, 4, L(fx, 3, fz) * CFrame.Angles(0, 0, math.rad(90)), rgb(200, 200, 210))
	cyl(parent, "Bowl", 4, 0.8, L(fx, 5, fz) * CFrame.Angles(0, 0, math.rad(90)), rgb(200, 200, 210))
	local jet = part(parent, "Jet", Vector3.new(0.4, 0.4, 0.4), L(fx, 5.6, fz), rgb(150, 200, 255), nil, { Transparency = 1 })
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(rgb(170, 220, 255))
	e.Rate = 30
	e.Lifetime = NumberRange.new(0.8, 1.2)
	e.Speed = NumberRange.new(6, 8)
	e.SpreadAngle = Vector2.new(12, 12)
	e.Acceleration = Vector3.new(0, -16, 0)
	e.Size = NumberSequence.new(0.35, 0.1)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = jet
end

Items.Statue = function(parent, L, look)
	local sx, sz = 24, 66
	part(parent, "Plinth", Vector3.new(5, 3, 5), L(sx, 1.9, sz), rgb(200, 200, 210))
	local bronze = rgb(160, 110, 60)
	part(parent, "Legs", Vector3.new(2, 3, 1), L(sx, 4.9, sz), bronze, Enum.Material.Metal)
	part(parent, "Body", Vector3.new(2.4, 2.6, 1.2), L(sx, 7.7, sz), bronze, Enum.Material.Metal)
	ball(parent, "Head", 1.8, L(sx, 9.9, sz), bronze, Enum.Material.Metal)
	part(parent, "Arm", Vector3.new(0.8, 3, 0.8), L(sx + 1.7, 9.2, sz) * CFrame.Angles(0, 0, math.rad(-40)), bronze, Enum.Material.Metal)
	part(parent, "Book", Vector3.new(1.4, 1.8, 0.4), L(sx - 1.6, 7.6, sz + 0.6), bronze, Enum.Material.Metal)
	local plaque = part(parent, "Plaque", Vector3.new(3.5, 1, 0.2), L(sx, 2.2, sz + 2.55), rgb(255, 210, 80), Enum.Material.Metal)
	surfaceText(plaque, Enum.NormalId.Back, "OUR FOUNDER", rgb(60, 40, 20), nil, Enum.Font.FredokaOne)
	_ = look
end

Items.Garden = function(parent, L)
	for i = 0, 3 do
		local gx = 24 + i * 7
		part(parent, "Planter", Vector3.new(5, 1, 4), L(gx, 0.9, 30), rgb(120, 80, 50), Enum.Material.Wood)
		for j = -1, 1 do
			ball(parent, "Veg", 1.2, L(gx + j * 1.4, 1.7, 30), i % 2 == 0 and rgb(255, 120, 40) or rgb(90, 200, 70))
		end
	end
	part(parent, "Scarecrow", Vector3.new(0.4, 5, 0.4), L(52, 3, 30), rgb(140, 100, 60), Enum.Material.Wood)
	part(parent, "ScarecrowArms", Vector3.new(4, 0.4, 0.4), L(52, 4.2, 30), rgb(140, 100, 60), Enum.Material.Wood)
	ball(parent, "ScarecrowHead", 1.4, L(52, 5.8, 30), rgb(230, 200, 120))
end

Items.Bleachers = function(parent, L)
	for i = 0, 3 do
		part(parent, "Bench", Vector3.new(20, 0.6, 2), L(36, 1 + i * 1.2, 60 + i * 2), rgb(60, 110, 200))
		part(parent, "Riser", Vector3.new(20, 1 + i * 1.2, 0.3), L(36, (1 + i * 1.2) / 2, 59 + i * 2), rgb(180, 180, 190), Enum.Material.Metal)
	end
end

Items.PathLights = function(parent, L)
	for i = 0, 4 do
		for _, side in { -1, 1 } do
			part(parent, "LampPost", Vector3.new(0.3, 4, 0.3), L(side * 7, 2.4, 26 + i * 11), rgb(40, 40, 50), Enum.Material.Metal)
			local bulb = ball(parent, "Lamp", 0.9, L(side * 7, 4.7, 26 + i * 11), rgb(255, 240, 200), Enum.Material.Neon)
			light(bulb, 10, 0.8)
		end
	end
end

Items.WindowBoxes = function(parent, L)
	local colors = { rgb(255, 90, 120), rgb(255, 200, 60), rgb(170, 110, 255) }
	for i, wx in { -30, -18, 18, 30 } do
		part(parent, "Box", Vector3.new(7, 1, 1.2), L(wx, F1 + 3.1, ZF + WT / 2 + 0.8), rgb(120, 80, 50), Enum.Material.Wood)
		for j = -2, 2 do
			ball(parent, "Bloom", 0.9, L(wx + j * 1.3, F1 + 3.9, ZF + WT / 2 + 0.8), colors[(i + j) % #colors + 1])
		end
	end
end

Items.SolarPanels = function(parent, L, look, roofY)
	for ix = -1, 1 do
		for iz = 0, 2 do
			part(parent, "Panel", Vector3.new(8, 0.3, 5), L(ix * 12, roofY + 2.2, -20 - iz * 8) * CFrame.Angles(math.rad(-20), 0, 0), rgb(30, 50, 110), Enum.Material.Glass)
			part(parent, "Stand", Vector3.new(0.4, 1.6, 0.4), L(ix * 12, roofY + 1.6, -20 - iz * 8), rgb(160, 160, 170), Enum.Material.Metal)
		end
	end
end

Items.BellTower = function(parent, L, look, roofY)
	local tx, tz = 0, -30
	part(parent, "Tower", Vector3.new(8, 10, 8), L(tx, roofY + 6, tz), look.wall)
	part(parent, "Belfry", Vector3.new(7, 5, 7), L(tx, roofY + 13.5, tz), look.cap)
	ball(parent, "Bell", 2.6, L(tx, roofY + 13.3, tz), rgb(255, 200, 60), Enum.Material.Metal)
	wedge(parent, "Roof", Vector3.new(8, 5, 4), L(tx, roofY + 18.5, tz + 2) * CFrame.Angles(0, math.pi, 0), rgb(150, 50, 50))
	wedge(parent, "Roof", Vector3.new(8, 5, 4), L(tx, roofY + 18.5, tz - 2), rgb(150, 50, 50))
end

Items.Banners = function(parent, L, look)
	for _, bx in { -24, 24 } do
		part(parent, "Banner", Vector3.new(4, 9, 0.2), L(bx, F1 + 22, ZF + WT / 2 + 0.4), look.sign)
		part(parent, "BannerRod", Vector3.new(5, 0.3, 0.3), L(bx, F1 + 26.7, ZF + WT / 2 + 0.5), rgb(255, 210, 80), Enum.Material.Metal)
	end
end

Items.VendingMachines = function(parent, L)
	for i, c in { rgb(220, 40, 40), rgb(40, 110, 220) } do
		local vx = -20 + i * 4
		part(parent, "Vending", Vector3.new(3.4, 7, 2.4), L(vx, F1 + 3.5, DIVIDER_Z + 1.6), c)
		part(parent, "VendingGlass", Vector3.new(2.4, 4, 0.2), L(vx - 0.3, F1 + 4.5, DIVIDER_Z + 2.85), rgb(200, 230, 255), Enum.Material.Glass, { Transparency = 0.3 })
	end
end

---------------------------------------------------------------------------
-- School Supplies on the desks (the three best a desk can hold) and in the classrooms
---------------------------------------------------------------------------
-- slot: "small" items stand at the back corners of a desk, "flat"/"device" lie in the middle
local DESK_SUPPLY = {}

local function onDesk(folder, top, name, size, x, y, z, color, material, extra)
	local cf = top.CFrame * CFrame.new(x, top.Size.Y / 2 + size.Y / 2 + y, z)
	return part(folder, name, size, cf, color, material, extra)
end

DESK_SUPPLY.Pencils = { kind = "small", build = function(f, top, x, z)
	local cup = onDesk(f, top, "PencilCup", Vector3.new(0.6, 0.8, 0.6), x, 0, z, rgb(70, 130, 220))
	for i, dx in { -0.14, 0, 0.14 } do
		local p = part(f, "Pencil", Vector3.new(0.12, 1.1, 0.12), cup.CFrame * CFrame.new(dx, 0.55, (i - 2) * 0.1) * CFrame.Angles(math.rad((i - 2) * 10), 0, math.rad(dx * 60)), rgb(255, 200, 40))
		part(f, "Tip", Vector3.new(0.13, 0.12, 0.13), p.CFrame * CFrame.new(0, 0.6, 0), rgb(255, 140, 170))
	end
end }
DESK_SUPPLY.Crayons = { kind = "small", build = function(f, top, x, z)
	local box = onDesk(f, top, "CrayonBox", Vector3.new(0.9, 0.55, 0.4), x, 0, z, rgb(80, 190, 90))
	part(f, "Label", Vector3.new(0.92, 0.2, 0.42), box.CFrame * CFrame.new(0, -0.05, 0), rgb(255, 214, 60))
	for i, c in { rgb(230, 50, 50), rgb(50, 110, 230), rgb(250, 160, 30), rgb(160, 70, 220) } do
		part(f, "Crayon", Vector3.new(0.13, 0.25, 0.13), box.CFrame * CFrame.new(-0.33 + (i - 1) * 0.22, 0.38, 0), c)
	end
end }
DESK_SUPPLY.Calculators = { kind = "small", build = function(f, top, x, z)
	local c = onDesk(f, top, "Calculator", Vector3.new(0.7, 0.12, 1), x, 0, z, rgb(60, 64, 76))
	part(f, "Screen", Vector3.new(0.5, 0.03, 0.25), c.CFrame * CFrame.new(0, 0.07, -0.3), rgb(170, 210, 150))
	part(f, "Keys", Vector3.new(0.52, 0.03, 0.5), c.CFrame * CFrame.new(0, 0.07, 0.15), rgb(200, 200, 210))
end }
DESK_SUPPLY.Globes = { kind = "small", build = function(f, top, x, z)
	onDesk(f, top, "GlobeBase", Vector3.new(0.5, 0.1, 0.5), x, 0, z, rgb(200, 160, 60), Enum.Material.Metal)
	onDesk(f, top, "GlobeStem", Vector3.new(0.1, 0.5, 0.1), x, 0.1, z, rgb(200, 160, 60), Enum.Material.Metal)
	local g = ball(f, "Globe", 0.8, top.CFrame * CFrame.new(x, top.Size.Y / 2 + 1, z), rgb(60, 140, 230))
	ball(f, "Land", 0.45, g.CFrame * CFrame.new(0.18, 0.12, -0.12), rgb(90, 190, 90))
end }
DESK_SUPPLY.Microscopes = { kind = "small", build = function(f, top, x, z)
	onDesk(f, top, "ScopeBase", Vector3.new(0.7, 0.15, 0.8), x, 0, z, rgb(240, 240, 245))
	onDesk(f, top, "ScopeArm", Vector3.new(0.2, 1, 0.2), x, 0.15, z + 0.25, rgb(240, 240, 245))
	local tube = part(f, "ScopeTube", Vector3.new(0.22, 0.8, 0.22), top.CFrame * CFrame.new(x, top.Size.Y / 2 + 1.2, z) * CFrame.Angles(math.rad(-25), 0, 0), rgb(40, 40, 50))
	part(f, "Eyepiece", Vector3.new(0.26, 0.2, 0.26), tube.CFrame * CFrame.new(0, 0.45, 0), rgb(20, 20, 25))
end }
DESK_SUPPLY.VRHeadsets = { kind = "small", build = function(f, top, x, z)
	local h = onDesk(f, top, "Headset", Vector3.new(0.95, 0.45, 0.55), x, 0, z, rgb(30, 30, 38))
	part(f, "Visor", Vector3.new(0.85, 0.3, 0.05), h.CFrame * CFrame.new(0, 0, 0.29), rgb(80, 200, 255), Enum.Material.Neon)
	part(f, "Strap", Vector3.new(1.05, 0.12, 0.3), h.CFrame * CFrame.new(0, 0.1, -0.2), rgb(60, 60, 70))
end }
DESK_SUPPLY.RobotTutors = { kind = "small", build = function(f, top, x, z)
	local body = onDesk(f, top, "RobotBody", Vector3.new(0.6, 0.6, 0.5), x, 0, z, rgb(200, 205, 215), Enum.Material.Metal)
	local head = part(f, "RobotHead", Vector3.new(0.5, 0.42, 0.45), body.CFrame * CFrame.new(0, 0.53, 0), rgb(220, 225, 235), Enum.Material.Metal)
	for _, ex in { -0.12, 0.12 } do
		part(f, "Eye", Vector3.new(0.1, 0.1, 0.05), head.CFrame * CFrame.new(ex, 0.03, 0.23), rgb(80, 230, 255), Enum.Material.Neon)
	end
	part(f, "Antenna", Vector3.new(0.05, 0.3, 0.05), head.CFrame * CFrame.new(0, 0.35, 0), rgb(90, 90, 100))
	ball(f, "AntennaBall", 0.14, head.CFrame * CFrame.new(0, 0.52, 0), rgb(255, 80, 80), Enum.Material.Neon)
end }
DESK_SUPPLY.ThinkingCaps = { kind = "small", build = function(f, top, x, z)
	local cap = ball(f, "ThinkingCap", 0.8, top.CFrame * CFrame.new(x, top.Size.Y / 2 + 0.2, z), rgb(90, 60, 220))
	for i, c in { rgb(255, 80, 80), rgb(80, 220, 120), rgb(80, 160, 255) } do
		part(f, "CapStripe", Vector3.new(0.82, 0.08, 0.2), cap.CFrame * CFrame.new(0, 0.12, -0.25 + (i - 1) * 0.25), c)
	end
	part(f, "PropStem", Vector3.new(0.06, 0.3, 0.06), cap.CFrame * CFrame.new(0, 0.5, 0), rgb(60, 60, 70))
	part(f, "Propeller", Vector3.new(1, 0.05, 0.16), cap.CFrame * CFrame.new(0, 0.66, 0) * CFrame.Angles(0, math.rad(30), 0), rgb(255, 210, 60))
end }
DESK_SUPPLY.Notebooks = { kind = "flat", build = function(f, top, x, z)
	local n = onDesk(f, top, "Notebook", Vector3.new(1.4, 0.1, 1.8), x - 0.3, 0, z, rgb(60, 120, 230))
	part(f, "Pages", Vector3.new(1.3, 0.06, 1.7), n.CFrame * CFrame.new(0.03, 0.06, 0), rgb(250, 250, 245))
	part(f, "Spiral", Vector3.new(0.12, 0.14, 1.75), n.CFrame * CFrame.new(-0.68, 0.04, 0), rgb(180, 180, 190), Enum.Material.Metal)
end }
DESK_SUPPLY.Rulers = { kind = "flat", build = function(f, top, x, z)
	DESK_SUPPLY.Notebooks.build(f, top, x, z)
	onDesk(f, top, "Ruler", Vector3.new(0.35, 0.05, 2.4), x + 0.75, 0, z, rgb(255, 214, 60))
end }
DESK_SUPPLY.Textbooks = { kind = "flat", build = function(f, top, x, z)
	onDesk(f, top, "Textbook", Vector3.new(1.6, 0.32, 1.2), x, 0, z, rgb(200, 50, 50))
	onDesk(f, top, "Textbook", Vector3.new(1.5, 0.3, 1.1), x + 0.05, 0.32, z, rgb(50, 160, 90))
	onDesk(f, top, "Textbook", Vector3.new(1.4, 0.28, 1.05), x - 0.05, 0.62, z, rgb(250, 200, 60))
end }
DESK_SUPPLY.Laptops = { kind = "device", build = function(f, top, x, z)
	local base = onDesk(f, top, "Laptop", Vector3.new(1.9, 0.1, 1.3), x, 0, z + 0.2, rgb(200, 204, 212), Enum.Material.Metal)
	local lid = part(f, "LaptopLid", Vector3.new(1.9, 1.25, 0.08), base.CFrame * CFrame.new(0, 0.58, -0.62) * CFrame.Angles(math.rad(-12), 0, 0), rgb(200, 204, 212), Enum.Material.Metal)
	part(f, "LaptopScreen", Vector3.new(1.7, 1.05, 0.02), lid.CFrame * CFrame.new(0, 0, 0.05), rgb(90, 170, 255), Enum.Material.Neon)
end }
DESK_SUPPLY.Tablets = { kind = "device", build = function(f, top, x, z)
	local stand = onDesk(f, top, "TabletStand", Vector3.new(0.8, 0.15, 0.6), x, 0, z, rgb(60, 60, 70))
	local t = part(f, "Tablet", Vector3.new(1.7, 1.2, 0.1), stand.CFrame * CFrame.new(0, 0.6, -0.1) * CFrame.Angles(math.rad(-18), 0, 0), rgb(25, 25, 30))
	part(f, "TabletScreen", Vector3.new(1.5, 1.02, 0.02), t.CFrame * CFrame.new(0, 0, 0.06), rgb(120, 230, 170), Enum.Material.Neon)
end }
DESK_SUPPLY.HoloDesks = { kind = "device", build = function(f, top, x, z)
	onDesk(f, top, "HoloPad", Vector3.new(5.6, 0.04, 3), 0, 0, 0, rgb(80, 220, 255), Enum.Material.Neon, { Transparency = 0.55, CanCollide = false })
	local cube = part(f, "Hologram", Vector3.new(0.9, 0.9, 0.9), top.CFrame * CFrame.new(x, top.Size.Y / 2 + 1.6, z) * CFrame.Angles(math.rad(35), math.rad(45), 0), rgb(120, 230, 255), Enum.Material.ForceField, { CanCollide = false })
	light(cube, 6, 0.5, rgb(120, 230, 255))
end }

-- the three best supplies for one desk: the newest device (or flat item) in the middle and the
-- two newest small items at the back corners
local function deskPicks(owned)
	local small, device, flat = {}, nil, nil
	for i = #Config.Supplies, 1, -1 do
		local s = Config.Supplies[i]
		local d = DESK_SUPPLY[s.id]
		if owned[s.id] and d then
			if d.kind == "small" then
				if #small < 2 then table.insert(small, s.id) end
			elseif d.kind == "device" then
				device = device or s.id
			else
				flat = flat or s.id
			end
		end
	end
	return small, device or flat
end

-- (re)place supplies on every desk and the classroom-wide ones (Smartboards, Quantum Computers)
function SchoolBuilder.decorate(plot, owned)
	local school = plot:FindFirstChild("School")
	if not school then return end
	owned = owned or {}
	local small, center = deskPicks(owned)
	local base = plot.Origin.CFrame
	for _, fm in school.Floors:GetChildren() do
		local old = fm:FindFirstChild("Supplies")
		if old then old:Destroy() end
		local folder = Instance.new("Folder")
		folder.Name = "Supplies"
		folder.Parent = fm
		for _, d in fm.Desks:GetChildren() do
			local f = Instance.new("Folder")
			f.Name = d.Name
			f.Parent = folder
			local top = d.Top
			if center then DESK_SUPPLY[center].build(f, top, 0, 0) end
			if small[1] then DESK_SUPPLY[small[1]].build(f, top, 2.3, -1) end
			if small[2] then DESK_SUPPLY[small[2]].build(f, top, -2.3, -1) end
			local locked = d:GetAttribute("Locked")
			for _, p in f:GetDescendants() do
				if p:IsA("BasePart") then
					-- studs are too busy at this size
					if p.Material == Enum.Material.Plastic then p.Material = Enum.Material.SmoothPlastic end
					p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
					p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
					p.CastShadow = false
					-- locked desks show their supplies as ghosts like the desk itself
					if locked then p.Transparency = math.max(p.Transparency, 0.85) end
				end
			end
		end
		-- classroom upgrades
		local board = fm.Classroom:FindFirstChild("Chalkboard")
		local ft = board and (board.Position.Y - 7) or 0
		if board then
			if owned.Smartboards then
				board.Color = rgb(18, 30, 60)
				local L = function(x, y, z) return board.CFrame * CFrame.new(x, y, z) end
				for _, e in { { 0, 3.6, 30.4, 0.25 }, { 0, -3.6, 30.4, 0.25 }, { -15.1, 0, 0.25, 7.4 }, { 15.1, 0, 0.25, 7.4 } } do
					part(folder, "SmartFrame", Vector3.new(e[3], e[4], 0.1), L(e[1], e[2], 0.2), rgb(80, 220, 255), Enum.Material.Neon)
				end
			end
		end
		if owned.QuantumPCs then
			-- the golden "chandelier" quantum computer, hanging over the back corner
			local qx, qz = 24, -58
			local function Lq(y) return base * CFrame.new(qx, ft + y, qz) end
			part(folder, "QuantumRod", Vector3.new(0.3, 3, 0.3), Lq(13.3), rgb(230, 190, 90), Enum.Material.Metal)
			for i, y in { 11.6, 10.2, 8.8, 7.4 } do
				local d = 3.6 - i * 0.55
				cyl(folder, "QuantumDisc", d, 0.25, Lq(y) * CFrame.Angles(0, 0, math.rad(90)), rgb(240, 200, 100), Enum.Material.Metal)
				for k = 0, 5 do
					local a = math.rad(k * 60)
					part(folder, "QuantumWire", Vector3.new(0.12, 1.4, 0.12), Lq(y - 0.7) * CFrame.new(math.cos(a) * d * 0.35, 0, math.sin(a) * d * 0.35), rgb(200, 120, 60), Enum.Material.Metal)
				end
			end
			local core = ball(folder, "QuantumCore", 0.9, Lq(6.4), rgb(140, 120, 255), Enum.Material.Neon)
			light(core, 10, 0.6, rgb(140, 120, 255))
		end
	end
end

-- rebuild just the School Builder items (after a purchase), keeping the rest of the campus
local function ownedItems(items)
	local show = {}
	for id in items or {} do show[id] = true end
	-- a better fence replaces the one before it
	for id in items or {} do
		local def = Config.BuildById and Config.BuildById[id]
		local r = def and def.replaces
		while r do
			show[r] = nil
			local rd = Config.BuildById[r]
			r = rd and rd.replaces
		end
	end
	return show
end

---------------------------------------------------------------------------
-- build / rebuild a campus
---------------------------------------------------------------------------
-- opts: { tier = index, floors = n, name = string, items = { [itemId] = true } }
function SchoolBuilder.build(plot, opts)
	local old = plot:FindFirstChild("School")
	if old then old:Destroy() end
	local look = Config.TierLooks[opts.tier] or Config.TierLooks[2]
	local school = Instance.new("Model")
	school.Name = "School"
	local floorsFolder = Instance.new("Folder")
	floorsFolder.Name = "Floors"
	floorsFolder.Parent = school
	local base = plot.Origin.CFrame
	local function L(x, y, z) return base * CFrame.new(x, y, z) end

	for f = 1, opts.floors do
		buildFloor(school, L, f, opts.floors, look)
	end
	local roofY = buildFacade(school, L, opts.floors, look, opts.tier, opts.name or "Empty School")
	buildYard(school, L, look)
	school:SetAttribute("Floors", opts.floors)
	school:SetAttribute("RoofY", roofY)
	school:SetAttribute("Tier", opts.tier)
	school.Parent = plot
	SchoolBuilder.setItems(plot, opts.items)
	if opts.supplies then SchoolBuilder.decorate(plot, opts.supplies) end
	return school
end

-- (re)build the School Builder items on an existing campus
function SchoolBuilder.setItems(plot, owned)
	local school = plot:FindFirstChild("School")
	if not school then return end
	local old = school:FindFirstChild("Items")
	if old then old:Destroy() end
	local look = Config.TierLooks[school:GetAttribute("Tier") or 2] or Config.TierLooks[2]
	local roofY = school:GetAttribute("RoofY") or 17
	local base = plot.Origin.CFrame
	local function L(x, y, z) return base * CFrame.new(x, y, z) end
	local items = Instance.new("Folder")
	items.Name = "Items"
	for id in ownedItems(owned) do
		local fn = Items[id]
		if fn then
			local f = Instance.new("Folder")
			f.Name = id
			f.Parent = items
			local ok, err = pcall(fn, f, L, look, roofY)
			if not ok then warn("[SchoolBuilder] item", id, err) end
		end
	end
	items.Parent = school
end

function SchoolBuilder.setName(plot, name)
	local school = plot:FindFirstChild("School")
	local band = school and school:FindFirstChild("Exterior") and school.Exterior:FindFirstChild("NameBand")
	if band then
		for _, g in band:GetChildren() do
			if g:IsA("SurfaceGui") then g.SchoolName.Text = name end
		end
	end
end

function SchoolBuilder.floorModel(plot, f)
	local school = plot:FindFirstChild("School")
	return school and school.Floors:FindFirstChild("Floor" .. f)
end

function SchoolBuilder.desk(plot, slot)
	local fm = SchoolBuilder.floorModel(plot, math.ceil(slot / 16))
	return fm and fm.Desks:FindFirstChild("Desk" .. slot)
end

-- local-space waypoints (x, y, z at the walking surface) from the front walk to a desk's chair;
-- the caller adds the rig's stand height and converts to world space
function SchoolBuilder.route(slot)
	local f = math.ceil(slot / 16)
	local i = (slot - 1) % 16
	local row, col = math.floor(i / 4) + 1, i % 4 + 1
	local dx, dz = DESK_COLS[col], DESK_ROWS[row]
	local pts = {
		Vector3.new(0, 0.5, 70), -- through the gate
		Vector3.new(0, 0.5, ZF + 6), -- up the walk
		Vector3.new(0, F1, ZF - 2), -- in the doors
		Vector3.new(0, F1, DIVIDER_Z + 4), -- across the lobby
	}
	local ft = F1
	for level = 1, f - 1 do
		local side = SchoolBuilder.stairSide(level)
		local sx = STAIR_X[side]
		table.insert(pts, Vector3.new(sx * 0.55, ft, STAIR_Z0 - 1)) -- toward the stair foot
		table.insert(pts, Vector3.new(sx, ft, STAIR_Z0 + 0.5))
		ft += FLOOR_H
		table.insert(pts, Vector3.new(sx, ft, STAIR_Z1 - 0.5)) -- climb
		table.insert(pts, Vector3.new(sx, ft, STAIR_Z1 - 2.5))
		table.insert(pts, Vector3.new(sx * 0.82, ft, STAIR_Z1 - 2.5))
		if level < f - 1 then
			-- over to the next flight via the lobby
			table.insert(pts, Vector3.new(0, ft, STAIR_Z1 - 2.5))
			table.insert(pts, Vector3.new(0, ft, DIVIDER_Z + 4))
		end
	end
	local aisle = dx - 5.6
	if f == 1 then
		table.insert(pts, Vector3.new(0, ft, DIVIDER_Z - 2))
		table.insert(pts, Vector3.new(aisle, ft, DIVIDER_Z - 2))
	else
		table.insert(pts, Vector3.new(aisle, ft, STAIR_Z1 - 2.5))
	end
	table.insert(pts, Vector3.new(aisle, ft, dz + 3.4))
	table.insert(pts, Vector3.new(dx, ft, dz + 3.4))
	return pts
end

-- from a desk's chair to the bench in the Principal's Office (floor 1): back the way the kid
-- came in as far as the lobby, then through the office door
SchoolBuilder.BENCH_SEATS = { Vector3.new(24.2, F1 + 1.9, DIVIDER_Z + 1.5), Vector3.new(26, F1 + 1.9, DIVIDER_Z + 1.5), Vector3.new(27.8, F1 + 1.9, DIVIDER_Z + 1.5) }
function SchoolBuilder.officeRoute(slot, seat)
	local fwd = SchoolBuilder.route(slot)
	local pts = {}
	for i = #fwd, 4, -1 do
		table.insert(pts, fwd[i])
	end
	local b = SchoolBuilder.BENCH_SEATS[seat or 2]
	table.insert(pts, Vector3.new(14, F1, 9.25))
	table.insert(pts, Vector3.new(22.5, F1, 9.25))
	table.insert(pts, Vector3.new(b.X, F1, DIVIDER_Z + 3.6))
	return pts
end

-- from the gate to the aisle beside a desk (where a dealer stands to deal)
function SchoolBuilder.aisleRoute(slot)
	local pts = SchoolBuilder.route(slot)
	table.remove(pts) -- not into the chair
	return pts
end

return SchoolBuilder
