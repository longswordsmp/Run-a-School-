-- ServerScriptService.Server.TownKit
-- The building kit for the town around the schools (docs/TOWN.md): parts, wedges, cylinders, signs,
-- roads with markings, sidewalks, fences and hedges, trees, lamps, benches, and whole shop and house
-- shells (walls with windows, a door, an awning, a roof). Every builder takes a parent and plain
-- numbers, so the district files read like floor plans. Parts are anchored and smooth.
local Kit = {}

local rgb = Color3.fromRGB
Kit.rgb = rgb
Kit.C = {
	asphalt = rgb(58, 60, 68),
	line = rgb(255, 214, 70),
	white = rgb(248, 248, 244),
	sidewalk = rgb(214, 214, 222),
	curb = rgb(175, 175, 185),
	grass = rgb(104, 196, 84),
	dirt = rgb(150, 112, 72),
	iron = rgb(44, 46, 54),
	wood = rgb(150, 105, 62),
	glass = rgb(150, 200, 235),
	leaf = rgb(60, 170, 70),
	pine = rgb(40, 120, 70),
	trunk = rgb(120, 80, 50),
	stone = rgb(170, 166, 160),
	roof = rgb(120, 70, 60),
}

function Kit.part(parent, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props then for k, v in props do p[k] = v end end
	p.Parent = parent
	return p
end
local part = Kit.part

-- a wedge whose slope runs down towards `down` (a unit axis: "+x", "-x", "+z", "-z")
function Kit.wedge(parent, name, size, pos, down, color, material)
	-- size: (across, height, along the slope)
	local yaw = ({ ["-z"] = 0, ["+x"] = -90, ["+z"] = 180, ["-x"] = 90 })[down] or 0
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(yaw), 0)
	w.Color = color
	w.Material = material or Enum.Material.SmoothPlastic
	w.Anchored = true
	w.TopSurface, w.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	w.Parent = parent
	return w
end

-- cylinders: an upright one (a pole, a tank) and one lying along x or z (a wheel, a pipe)
function Kit.cylY(parent, name, d, h, pos, color, material, props)
	local p = part(parent, name, Vector3.new(h, d, d), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, material, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end
function Kit.cylX(parent, name, d, len, pos, color, material, props)
	local p = part(parent, name, Vector3.new(len, d, d), CFrame.new(pos), color, material, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end
function Kit.cylZ(parent, name, d, len, pos, color, material, props)
	local p = part(parent, name, Vector3.new(len, d, d), CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0), color, material, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end
function Kit.ball(parent, name, d, pos, color, material)
	local p = part(parent, name, Vector3.new(d, d, d), CFrame.new(pos), color, material)
	p.Shape = Enum.PartType.Ball
	return p
end

-- text on a face of a part
function Kit.sign(p, face, text, color, bg, font, stroke)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.LightInfluence = 0.15
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Name = "Label"
	t.Size = UDim2.new(1, -10, 1, -10)
	t.Position = UDim2.fromOffset(5, 5)
	t.BackgroundColor3 = bg or Color3.new(1, 1, 1)
	t.BackgroundTransparency = bg and 0 or 1
	t.Text = text
	t.TextScaled = true
	t.Font = font or Enum.Font.FredokaOne
	t.TextColor3 = color
	t.Parent = g
	if stroke then
		local s = Instance.new("UIStroke")
		s.Thickness = 3
		s.Color = stroke
		s.Parent = t
	end
	return t
end

function Kit.light(p, range, brightness, color)
	local l = Instance.new("PointLight")
	l.Range = range or 16
	l.Brightness = brightness or 1
	l.Color = color or rgb(255, 214, 160)
	l.Parent = p
	return l
end

function Kit.folder(parent, name)
	local f = Instance.new("Model")
	f.Name = name
	f.Parent = parent
	return f
end

---------------------------------------------------------------------------
-- ground, roads, sidewalks
---------------------------------------------------------------------------
function Kit.ground(parent, x0, x1, z0, z1, color, material)
	return part(parent, "Ground", Vector3.new(x1 - x0, 2, z1 - z0), CFrame.new((x0 + x1) / 2, -1, (z0 + z1) / 2), color or Kit.C.grass, material or Enum.Material.Grass)
end

-- a road from (x0,z0) to (x1,z1), axis-aligned, `w` wide, asphalt with a dashed centre line
function Kit.road(parent, x0, z0, x1, z1, w, opts)
	opts = opts or {}
	local along = math.abs(x1 - x0) > math.abs(z1 - z0)
	local len = along and math.abs(x1 - x0) or math.abs(z1 - z0)
	local mid = Vector3.new((x0 + x1) / 2, 0, (z0 + z1) / 2)
	local size = along and Vector3.new(len, 0.3, w) or Vector3.new(w, 0.3, len)
	part(parent, "Road", size, CFrame.new(mid + Vector3.new(0, 0.12, 0)), Kit.C.asphalt, Enum.Material.Asphalt)
	if not opts.noLines then
		local n = math.floor(len / 10)
		for i = 0, n - 1 do
			local t = (i + 0.5) / n
			local pos = Vector3.new(x0 + (x1 - x0) * t, 0.29, z0 + (z1 - z0) * t)
			part(parent, "Dash", along and Vector3.new(5, 0.05, 0.5) or Vector3.new(0.5, 0.05, 5), CFrame.new(pos), Kit.C.line)
		end
		for _, s in { -1, 1 } do
			local off = along and Vector3.new(0, 0, s * (w / 2 - 1)) or Vector3.new(s * (w / 2 - 1), 0, 0)
			part(parent, "EdgeLine", along and Vector3.new(len, 0.05, 0.35) or Vector3.new(0.35, 0.05, len), CFrame.new(mid + off + Vector3.new(0, 0.29, 0)), Kit.C.white)
		end
	end
	if opts.sidewalk then
		for _, s in { -1, 1 } do
			local off = along and Vector3.new(0, 0, s * (w / 2 + opts.sidewalk / 2)) or Vector3.new(s * (w / 2 + opts.sidewalk / 2), 0, 0)
			local sw = along and Vector3.new(len, 0.5, opts.sidewalk) or Vector3.new(opts.sidewalk, 0.5, len)
			part(parent, "Sidewalk", sw, CFrame.new(mid + off + Vector3.new(0, 0.25, 0)), Kit.C.sidewalk, Enum.Material.Concrete)
			local coff = along and Vector3.new(0, 0, s * (w / 2 + 0.2)) or Vector3.new(s * (w / 2 + 0.2), 0, 0)
			part(parent, "Curb", along and Vector3.new(len, 0.6, 0.4) or Vector3.new(0.4, 0.6, len), CFrame.new(mid + coff + Vector3.new(0, 0.3, 0)), Kit.C.curb, Enum.Material.Concrete)
		end
	end
end

-- zebra stripes across a road at (x, z); `acrossX` = the stripes run along x
function Kit.crosswalk(parent, x, z, w, acrossX)
	for i = -3, 3 do
		local off = acrossX and Vector3.new(0, 0, i * 2) or Vector3.new(i * 2, 0, 0)
		part(parent, "Zebra", acrossX and Vector3.new(w - 2, 0.05, 1) or Vector3.new(1, 0.05, w - 2), CFrame.new(Vector3.new(x, 0.3, z) + off), Kit.C.white)
	end
end

-- a flat paved area (a plaza, a parking lot)
function Kit.pave(parent, x0, x1, z0, z1, color, material, y)
	return part(parent, "Pave", Vector3.new(x1 - x0, 0.4, z1 - z0), CFrame.new((x0 + x1) / 2, (y or 0.2), (z0 + z1) / 2), color or Kit.C.sidewalk, material or Enum.Material.Concrete)
end

---------------------------------------------------------------------------
-- fences, hedges, walls
---------------------------------------------------------------------------
-- a picket fence along a line (axis-aligned)
function Kit.picket(parent, x0, z0, x1, z1, color)
	color = color or Kit.C.white
	local along = math.abs(x1 - x0) > math.abs(z1 - z0)
	local len = along and math.abs(x1 - x0) or math.abs(z1 - z0)
	local mid = Vector3.new((x0 + x1) / 2, 0, (z0 + z1) / 2)
	for _, y in { 1.2, 2.6 } do
		part(parent, "Rail", along and Vector3.new(len, 0.3, 0.2) or Vector3.new(0.2, 0.3, len), CFrame.new(mid + Vector3.new(0, y, 0)), color, Enum.Material.Wood)
	end
	local n = math.max(1, math.floor(len / 1.2))
	for i = 0, n do
		local t = i / n
		local pos = Vector3.new(x0 + (x1 - x0) * t, 1.7, z0 + (z1 - z0) * t)
		part(parent, "Picket", Vector3.new(0.45, 3.4, 0.2), CFrame.new(pos) * (along and CFrame.new() or CFrame.Angles(0, math.rad(90), 0)), color, Enum.Material.Wood)
	end
end

function Kit.hedge(parent, x0, z0, x1, z1, h, color)
	local along = math.abs(x1 - x0) > math.abs(z1 - z0)
	local len = along and math.abs(x1 - x0) or math.abs(z1 - z0)
	return part(parent, "Hedge", along and Vector3.new(len, h or 3.4, 2.4) or Vector3.new(2.4, h or 3.4, len), CFrame.new((x0 + x1) / 2, (h or 3.4) / 2, (z0 + z1) / 2), color or rgb(46, 130, 60), Enum.Material.Grass)
end

-- an iron fence with stone posts (district boundaries); the solid inner wall is invisible
function Kit.ironFence(parent, x0, z0, x1, z1, h)
	h = h or 9
	local along = math.abs(x1 - x0) > math.abs(z1 - z0)
	local len = along and math.abs(x1 - x0) or math.abs(z1 - z0)
	local mid = Vector3.new((x0 + x1) / 2, 0, (z0 + z1) / 2)
	part(parent, "FenceBase", along and Vector3.new(len, 1.4, 1.2) or Vector3.new(1.2, 1.4, len), CFrame.new(mid + Vector3.new(0, 0.7, 0)), Kit.C.stone, Enum.Material.Brick)
	for _, y in { 3.2, h - 0.6 } do
		part(parent, "FenceRail", along and Vector3.new(len, 0.25, 0.25) or Vector3.new(0.25, 0.25, len), CFrame.new(mid + Vector3.new(0, y, 0)), Kit.C.iron, Enum.Material.Metal)
	end
	local n = math.floor(len / 2)
	for i = 0, n do
		local t = i / n
		local pos = Vector3.new(x0 + (x1 - x0) * t, 0, z0 + (z1 - z0) * t)
		part(parent, "FenceBar", Vector3.new(0.18, h - 1.4, 0.18), CFrame.new(pos + Vector3.new(0, 1.4 + (h - 1.4) / 2, 0)), Kit.C.iron, Enum.Material.Metal, { CanCollide = false })
		if i % 10 == 0 then
			part(parent, "FencePost", Vector3.new(1.6, h + 1, 1.6), CFrame.new(pos + Vector3.new(0, (h + 1) / 2, 0)), Kit.C.stone, Enum.Material.Brick)
			part(parent, "PostCap", Vector3.new(2, 0.5, 2), CFrame.new(pos + Vector3.new(0, h + 1.25, 0)), rgb(140, 136, 130), Enum.Material.Concrete)
		end
	end
	part(parent, "FenceWall", along and Vector3.new(len, 40, 0.5) or Vector3.new(0.5, 40, len), CFrame.new(mid + Vector3.new(0, 20, 0)), rgb(0, 0, 0), nil, { Transparency = 1 })
end

-- an invisible wall (the edge of the world)
function Kit.wall(parent, x0, z0, x1, z1)
	local along = math.abs(x1 - x0) > math.abs(z1 - z0)
	local len = along and math.abs(x1 - x0) or math.abs(z1 - z0)
	return part(parent, "WorldEdge", along and Vector3.new(len, 120, 2) or Vector3.new(2, 120, len), CFrame.new((x0 + x1) / 2, 60, (z0 + z1) / 2), rgb(0, 0, 0), nil, { Transparency = 1 })
end

---------------------------------------------------------------------------
-- street furniture and nature
---------------------------------------------------------------------------
function Kit.tree(parent, x, z, s, leaf)
	s = s or 1
	leaf = leaf or Kit.C.leaf
	part(parent, "Trunk", Vector3.new(1.6, 7, 1.6) * s, CFrame.new(x, 3.5 * s, z), Kit.C.trunk, Enum.Material.Wood)
	part(parent, "Leaves", Vector3.new(9, 4.5, 9) * s, CFrame.new(x, 8 * s, z), leaf, Enum.Material.Grass)
	part(parent, "Leaves", Vector3.new(6.5, 3.5, 6.5) * s, CFrame.new(x, 11 * s, z), leaf:Lerp(Color3.new(1, 1, 1), 0.08), Enum.Material.Grass)
	part(parent, "Leaves", Vector3.new(3.5, 2.5, 3.5) * s, CFrame.new(x, 13.5 * s, z), leaf:Lerp(Color3.new(1, 1, 1), 0.16), Enum.Material.Grass)
end

function Kit.pine(parent, x, z, s)
	s = s or 1
	part(parent, "Trunk", Vector3.new(1.4, 6, 1.4) * s, CFrame.new(x, 3 * s, z), Kit.C.trunk, Enum.Material.Wood)
	for i, w in { 10, 8, 6, 4, 2.2 } do
		part(parent, "Needles", Vector3.new(w, 2.6, w) * s, CFrame.new(x, (4.5 + i * 2.4) * s, z) * CFrame.Angles(0, math.rad(i * 20), 0), Kit.C.pine:Lerp(Color3.new(1, 1, 1), i * 0.02), Enum.Material.Grass)
	end
end

function Kit.lamp(parent, x, z, h)
	h = h or 11
	part(parent, "LampBase", Vector3.new(1.4, 0.8, 1.4), CFrame.new(x, 0.6, z), Kit.C.iron, Enum.Material.Metal)
	part(parent, "LampPost", Vector3.new(0.45, h, 0.45), CFrame.new(x, h / 2 + 0.6, z), Kit.C.iron, Enum.Material.Metal)
	part(parent, "LampCap", Vector3.new(1.7, 0.4, 1.7), CFrame.new(x, h + 1.4, z), Kit.C.iron, Enum.Material.Metal)
	local lantern = part(parent, "Lantern", Vector3.new(1.2, 1.4, 1.2), CFrame.new(x, h + 0.5, z), rgb(255, 226, 170), Enum.Material.Neon)
	Kit.light(lantern, 22, 0.8, rgb(255, 214, 160))
	return lantern
end

-- a park bench facing `face` ("+x", "-x", "+z", "-z")
function Kit.bench(parent, x, z, face)
	local yaw = ({ ["-z"] = 0, ["+x"] = -90, ["+z"] = 180, ["-x"] = 90 })[face] or 0
	local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
	part(parent, "BenchSeat", Vector3.new(6, 0.35, 1.8), cf * CFrame.new(0, 1.9, 0), Kit.C.wood, Enum.Material.Wood)
	part(parent, "BenchBack", Vector3.new(6, 1.6, 0.3), cf * CFrame.new(0, 2.9, 0.85) * CFrame.Angles(math.rad(-10), 0, 0), Kit.C.wood, Enum.Material.Wood)
	for _, dx in { -2.5, 2.5 } do
		part(parent, "BenchLeg", Vector3.new(0.3, 1.9, 1.6), cf * CFrame.new(dx, 0.95, 0.1), Kit.C.iron, Enum.Material.Metal)
	end
end

-- a triangular pediment over a portico, seen from the front: two wedges sloping down to either side
-- (x, y at its base centre, z), `w` wide, `h` tall, `t` thick, on a wall facing along z
function Kit.pediment(parent, x, y, z, w, h, t, color, material)
	Kit.wedge(parent, "Pediment", Vector3.new(t, h, w / 2), Vector3.new(x + w / 4, y + h / 2, z), "+x", color, material)
	Kit.wedge(parent, "Pediment", Vector3.new(t, h, w / 2), Vector3.new(x - w / 4, y + h / 2, z), "-x", color, material)
end

function Kit.flagpole(parent, x, z, color)
	part(parent, "FlagBase", Vector3.new(2.4, 0.8, 2.4), CFrame.new(x, 0.4, z), Kit.C.stone, Enum.Material.Concrete)
	part(parent, "FlagPole", Vector3.new(0.35, 18, 0.35), CFrame.new(x, 9.4, z), rgb(225, 225, 230), Enum.Material.Metal)
	Kit.ball(parent, "Finial", 0.7, Vector3.new(x, 18.7, z), rgb(240, 200, 90), Enum.Material.Metal)
	part(parent, "Flag", Vector3.new(4.5, 2.8, 0.1), CFrame.new(x + 2.4, 16.6, z), color, Enum.Material.Fabric)
end

-- a parked car facing `face` ("+x", "-x", "+z", "-z"); opts.police adds a light bar and stripes
function Kit.car(parent, x, z, face, color, opts)
	opts = opts or {}
	local yaw = ({ ["+x"] = 0, ["-x"] = 180, ["+z"] = -90, ["-z"] = 90 })[face] or 0
	local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0) -- (the car's nose points along local +x)
	local car = Kit.folder(parent, "Car")
	part(car, "CarBody", Vector3.new(11, 2.2, 5.2), cf * CFrame.new(0, 1.9, 0), color, Enum.Material.Metal)
	part(car, "CarCabin", Vector3.new(5.6, 1.9, 4.8), cf * CFrame.new(-0.6, 3.9, 0), color, Enum.Material.Metal)
	part(car, "Windshield", Vector3.new(0.2, 1.6, 4.4), cf * CFrame.new(2.25, 3.9, 0) * CFrame.Angles(0, 0, math.rad(-25)), rgb(40, 50, 70), Enum.Material.Glass)
	for _, s in { -1, 1 } do
		part(car, "SideGlass", Vector3.new(4.6, 1.3, 0.1), cf * CFrame.new(-0.6, 4, s * 2.42), rgb(40, 50, 70), Enum.Material.Glass)
		part(car, "Headlight", Vector3.new(0.2, 0.6, 1), cf * CFrame.new(5.52, 2.2, s * 1.8), rgb(255, 250, 220), Enum.Material.Neon)
		part(car, "Taillight", Vector3.new(0.2, 0.6, 1), cf * CFrame.new(-5.52, 2.2, s * 1.8), rgb(230, 30, 40), Enum.Material.Neon)
		for _, dx in { -3.4, 3.4 } do
			local w = part(car, "Wheel", Vector3.new(0.9, 2.2, 2.2), cf * CFrame.new(dx, 1.1, s * 2.4) * CFrame.Angles(0, math.rad(90), 0), rgb(24, 24, 26))
			w.Shape = Enum.PartType.Cylinder
			local hub = part(car, "Hub", Vector3.new(0.95, 1.2, 1.2), cf * CFrame.new(dx, 1.1, s * 2.4) * CFrame.Angles(0, math.rad(90), 0), rgb(200, 200, 208), Enum.Material.Metal)
			hub.Shape = Enum.PartType.Cylinder
		end
	end
	part(car, "Bumper", Vector3.new(0.4, 0.6, 5.3), cf * CFrame.new(5.6, 1.3, 0), rgb(200, 200, 208), Enum.Material.Metal)
	part(car, "Bumper", Vector3.new(0.4, 0.6, 5.3), cf * CFrame.new(-5.6, 1.3, 0), rgb(200, 200, 208), Enum.Material.Metal)
	if opts.police then
		for _, s in { -1, 1 } do
			part(car, "PoliceStripe", Vector3.new(11.1, 0.6, 0.1), cf * CFrame.new(0, 2, s * 2.62), rgb(30, 50, 140))
			local bulb = part(car, "Siren", Vector3.new(1, 0.5, 1.6), cf * CFrame.new(-0.6, 5.1, s * 0.9), s < 0 and rgb(240, 40, 40) or rgb(40, 90, 255), Enum.Material.Neon)
			_ = bulb
		end
	end
	for _, p in car:GetChildren() do p.CanCollide = p.Name == "CarBody" or p.Name == "CarCabin" end
	return car
end

function Kit.flowerBed(parent, x, z, w, d, colors)
	part(parent, "Bed", Vector3.new(w, 0.8, d), CFrame.new(x, 0.4, z), rgb(110, 76, 50), Enum.Material.Ground)
	colors = colors or { rgb(240, 70, 90), rgb(255, 210, 60), rgb(160, 90, 230), rgb(255, 255, 255) }
	local n = 0
	for ix = -w / 2 + 1, w / 2 - 1, 1.6 do
		for iz = -d / 2 + 1, d / 2 - 1, 1.6 do
			n += 1
			Kit.ball(parent, "Flower", 0.9, Vector3.new(x + ix, 1.1, z + iz), colors[n % #colors + 1])
		end
	end
end

---------------------------------------------------------------------------
-- building shells
---------------------------------------------------------------------------
-- a window on a wall. cf: the window's centre on the wall's outer face, looking out
function Kit.window(parent, cf, w, h, opts)
	opts = opts or {}
	part(parent, "WindowFrame", Vector3.new(w + 0.6, h + 0.6, 0.25), cf * CFrame.new(0, 0, -0.1), opts.frame or Kit.C.white)
	part(parent, "Window", Vector3.new(w, h, 0.2), cf * CFrame.new(0, 0, -0.15), opts.glass or Kit.C.glass, Enum.Material.Glass, { Transparency = opts.transparency or 0.15 })
	if not opts.noCross then
		part(parent, "Mullion", Vector3.new(0.25, h, 0.3), cf * CFrame.new(0, 0, -0.2), opts.frame or Kit.C.white)
		part(parent, "Transom", Vector3.new(w, 0.25, 0.3), cf * CFrame.new(0, h * 0.1, -0.2), opts.frame or Kit.C.white)
	end
	if not opts.noSill then
		part(parent, "Sill", Vector3.new(w + 1, 0.35, 0.7), cf * CFrame.new(0, -h / 2 - 0.35, -0.35), opts.sill or Kit.C.stone, Enum.Material.Concrete)
	end
end

-- a door on a wall (cf as for window, at the bottom centre of the door)
function Kit.door(parent, cf, w, h, color, opts)
	opts = opts or {}
	part(parent, "DoorFrame", Vector3.new(w + 0.8, h + 0.4, 0.3), cf * CFrame.new(0, h / 2 + 0.2, -0.12), opts.frame or Kit.C.white)
	part(parent, "Door", Vector3.new(w, h, 0.25), cf * CFrame.new(0, h / 2, -0.2), color)
	if opts.glass then
		part(parent, "DoorGlass", Vector3.new(w * 0.6, h * 0.4, 0.3), cf * CFrame.new(0, h * 0.68, -0.25), Kit.C.glass, Enum.Material.Glass, { Transparency = 0.2 })
	end
	Kit.ball(parent, "Knob", 0.35, (cf * CFrame.new(w * 0.35, h * 0.45, -0.4)).Position, rgb(220, 190, 90))
end

-- a striped awning over a shopfront. cf: the wall face at the awning's centre top, looking out
function Kit.awning(parent, cf, w, colors)
	local n = math.max(2, math.floor(w / 2))
	for i = 1, n do
		local x = -w / 2 + (i - 0.5) * (w / n)
		local c = colors[(i - 1) % #colors + 1]
		part(parent, "Awning", Vector3.new(w / n, 0.2, 4.2), cf * CFrame.new(x, -0.8, -2) * CFrame.Angles(math.rad(22), 0, 0), c, Enum.Material.Fabric)
		part(parent, "AwningFlap", Vector3.new(w / n, 0.8, 0.12), cf * CFrame.new(x, -2.2, -3.95), c, Enum.Material.Fabric)
	end
end

-- a box building. spec: { x, z, w (along x), d (along z), h, face ("+z"...), wall, trim, roof,
-- roofKind ("flat" | "gable" | "hip"), floors, windows = per floor per side count, door = { w, h, color },
-- sign = { text, color, bg }, awning = { colors }, name }
-- Returns the model and the door's world position (the front walk).
function Kit.building(parent, spec)
	local m = Kit.folder(parent, spec.name or "Building")
	local face = spec.face or "+z"
	local yaw = ({ ["-z"] = 180, ["+x"] = 90, ["+z"] = 0, ["-x"] = -90 })[face]
	-- local frame: front faces local +z
	local base = CFrame.new(spec.x, 0, spec.z) * CFrame.Angles(0, math.rad(yaw), 0)
	local w, d, h = spec.w, spec.d, spec.h
	local wall, trim = spec.wall, spec.trim or Kit.C.white
	part(m, "Body", Vector3.new(w, h, d), base * CFrame.new(0, h / 2, 0), wall, spec.material or Enum.Material.SmoothPlastic)
	part(m, "Base", Vector3.new(w + 0.6, 1.4, d + 0.6), base * CFrame.new(0, 0.7, 0), spec.baseColor or Kit.C.stone, Enum.Material.Concrete)
	part(m, "Cornice", Vector3.new(w + 1, 0.8, d + 1), base * CFrame.new(0, h - 0.2, 0), trim)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			part(m, "Corner", Vector3.new(1.2, h, 1.2), base * CFrame.new(sx * (w / 2), h / 2, sz * (d / 2)), trim)
		end
	end
	local floors = spec.floors or 1
	local fh = h / floors
	-- windows: front (skipping the door bay), back, sides
	local function faceWindows(n, len, cfOf, skipMid)
		if n <= 0 then return end
		for f = 1, floors do
			local y = (f - 1) * fh + fh * 0.55
			for i = 1, n do
				local t = (i - 0.5) / n
				local off = -len / 2 + t * len
				if not (skipMid and f == 1 and math.abs(off) < (spec.door and spec.door.w or 6) * 0.9) then
					Kit.window(m, cfOf(off, y), spec.winW or 4, spec.winH or math.min(5, fh * 0.45), { frame = trim })
				end
			end
		end
	end
	local win = spec.windows or { 4, 2 }
	faceWindows(win[1], w - 4, function(off, y) return base * CFrame.new(off, y, d / 2) * CFrame.Angles(0, math.rad(180), 0) end, true)
	faceWindows(win[1], w - 4, function(off, y) return base * CFrame.new(off, y, -d / 2) end, false)
	faceWindows(win[2], d - 4, function(off, y) return base * CFrame.new(w / 2, y, off) * CFrame.Angles(0, math.rad(-90), 0) end, false)
	faceWindows(win[2], d - 4, function(off, y) return base * CFrame.new(-w / 2, y, off) * CFrame.Angles(0, math.rad(90), 0) end, false)
	-- the door, a step and the sign
	local frontCF = base * CFrame.new(0, 0, d / 2) * CFrame.Angles(0, math.rad(180), 0) -- looking out
	if spec.door then
		Kit.door(m, frontCF * CFrame.new(spec.door.x or 0, 1.4, 0), spec.door.w or 5, spec.door.h or 8, spec.door.color or rgb(120, 70, 45), { glass = spec.door.glass, frame = trim })
		part(m, "Step", Vector3.new((spec.door.w or 5) + 3, 1.4, 2.2), frontCF * CFrame.new(spec.door.x or 0, 0.7, -1.1), Kit.C.stone, Enum.Material.Concrete)
	end
	if spec.awning then
		Kit.awning(m, frontCF * CFrame.new(0, math.min(fh - 0.5, 11.5), -0.2), w - 3, spec.awning)
	end
	if spec.sign then
		local sy = spec.sign.y or math.min(h - 2.4, fh + 1.2)
		local board = part(m, "Sign", Vector3.new(spec.sign.w or math.min(w - 4, 30), spec.sign.h or 3.2, 0.4), frontCF * CFrame.new(0, sy, -0.3), spec.sign.bg or trim)
		-- (frontCF looks out of the building, so the outward face is the part's Front)
		Kit.sign(board, Enum.NormalId.Front, spec.sign.text, spec.sign.color or Kit.C.white, spec.sign.bg or trim, spec.sign.font or Enum.Font.LuckiestGuy, spec.sign.stroke)
	end
	-- the roof
	local roof = spec.roof or Kit.C.roof
	local kind = spec.roofKind or "flat"
	if kind == "flat" then
		part(m, "Roof", Vector3.new(w - 0.6, 0.4, d - 0.6), base * CFrame.new(0, h + 0.2, 0), roof, Enum.Material.Slate)
		part(m, "Parapet", Vector3.new(w + 1, 1.4, 0.8), base * CFrame.new(0, h + 0.7, d / 2), trim)
		part(m, "Parapet", Vector3.new(w + 1, 1.4, 0.8), base * CFrame.new(0, h + 0.7, -d / 2), trim)
		part(m, "Parapet", Vector3.new(0.8, 1.4, d + 1), base * CFrame.new(w / 2, h + 0.7, 0), trim)
		part(m, "Parapet", Vector3.new(0.8, 1.4, d + 1), base * CFrame.new(-w / 2, h + 0.7, 0), trim)
	elseif kind == "gable" then
		-- the ridge runs along x; two slopes down to the front and the back
		local rise = spec.rise or math.min(w, d) * 0.35
		for _, s in { -1, 1 } do
			local wg = Instance.new("WedgePart")
			wg.Name = "Roof"
			wg.Size = Vector3.new(w + 2, rise, d / 2 + 1)
			wg.CFrame = base * CFrame.new(0, h + rise / 2, s * (d / 4 + 0.5)) * CFrame.Angles(0, s > 0 and math.rad(180) or 0, 0)
			wg.Color = roof
			wg.Material = Enum.Material.Slate
			wg.Anchored = true
			wg.Parent = m
			-- (a wedge's slope falls towards its front, -Z: the two halves lean together into a ridge)
		end
		part(m, "Ridge", Vector3.new(w + 2.4, 0.5, 0.6), base * CFrame.new(0, h + rise, 0), roof:Lerp(Color3.new(0, 0, 0), 0.2), Enum.Material.Slate)
		-- the triangular gable ends
		for _, sx in { -1, 1 } do
			for _, s in { -1, 1 } do
				local g = Instance.new("WedgePart")
				g.Name = "Gable"
				g.Size = Vector3.new(0.6, rise, d / 2)
				g.CFrame = base * CFrame.new(sx * (w / 2 - 0.3), h + rise / 2, s * d / 4) * CFrame.Angles(0, s > 0 and math.rad(180) or 0, 0)
				g.Color = wall
				g.Material = spec.material or Enum.Material.SmoothPlastic
				g.Anchored = true
				g.Parent = m
			end
		end
	end
	if spec.chimney then
		part(m, "Chimney", Vector3.new(2.4, 6, 2.4), base * CFrame.new(w * 0.3, h + 3, -d * 0.2), rgb(150, 70, 55), Enum.Material.Brick)
	end
	m:SetAttribute("Door", (frontCF * CFrame.new(spec.door and spec.door.x or 0, 0, -4)).Position)
	return m, (frontCF * CFrame.new(spec.door and spec.door.x or 0, 0, -4)).Position
end

---------------------------------------------------------------------------
-- an enterable building: floor, four walls (the front one a glass shopfront with a door gap),
-- a ceiling with lights, a flat roof. Same local frame as Kit.building (front = local +z, `face`
-- turns it). Returns the model and a function at(x, y, z) that turns local positions into world
-- CFrames (for the fittings inside).
function Kit.hollow(parent, spec)
	local m = Kit.folder(parent, spec.name or "Store")
	local yaw = ({ ["-z"] = 180, ["+x"] = 90, ["+z"] = 0, ["-x"] = -90 })[spec.face or "+z"]
	local base = CFrame.new(spec.x, 0, spec.z) * CFrame.Angles(0, math.rad(yaw), 0)
	local function at(x, y, z) return base * CFrame.new(x, y, z) end
	local w, d, h, t = spec.w, spec.d, spec.h, 1.2
	local wall, trim = spec.wall, spec.trim or Kit.C.white
	local mat = spec.material or Enum.Material.SmoothPlastic
	part(m, "Floor", Vector3.new(w, 0.6, d), at(0, 0.3, 0), spec.floor or rgb(236, 232, 222), spec.floorMat or Enum.Material.SmoothPlastic)
	part(m, "Wall", Vector3.new(w, h, t), at(0, h / 2, -d / 2 + t / 2), wall, mat)
	part(m, "Wall", Vector3.new(t, h, d), at(-w / 2 + t / 2, h / 2, 0), wall, mat)
	part(m, "Wall", Vector3.new(t, h, d), at(w / 2 - t / 2, h / 2, 0), wall, mat)
	-- the front: a knee wall, big glass, a band above; the door gap in the middle
	local dw = spec.doorW or 8
	local dh = spec.doorH or 9
	local seg = (w - dw) / 2
	for _, s in { -1, 1 } do
		local cx = s * (dw / 2 + seg / 2)
		part(m, "KneeWall", Vector3.new(seg, 2.4, t), at(cx, 1.2, d / 2 - t / 2), wall, mat)
		part(m, "Shopfront", Vector3.new(seg - 0.4, dh - 2.4, 0.3), at(cx, 2.4 + (dh - 2.4) / 2, d / 2 - t / 2), Kit.C.glass, Enum.Material.Glass, { Transparency = 0.45 })
		for i = 0, math.floor(seg / 6) do
			part(m, "Mullion", Vector3.new(0.35, dh - 2.4, 0.5), at(cx - seg / 2 + i * (seg / math.max(1, math.floor(seg / 6))), 2.4 + (dh - 2.4) / 2, d / 2 - t / 2), trim)
		end
	end
	part(m, "Header", Vector3.new(w, h - dh, t), at(0, dh + (h - dh) / 2, d / 2 - t / 2), wall, mat)
	part(m, "DoorFrame", Vector3.new(dw + 1, 0.6, t + 0.3), at(0, dh + 0.3, d / 2 - t / 2), trim)
	for _, s in { -1, 1 } do
		part(m, "DoorFrame", Vector3.new(0.5, dh, t + 0.3), at(s * (dw / 2 + 0.25), dh / 2, d / 2 - t / 2), trim)
	end
	part(m, "Ceiling", Vector3.new(w, 0.5, d), at(0, h - 0.25, 0), spec.ceiling or rgb(245, 245, 240))
	part(m, "Roof", Vector3.new(w + 1, 0.6, d + 1), at(0, h + 0.3, 0), spec.roof or rgb(90, 90, 100), Enum.Material.Slate)
	for _, s in { -1, 1 } do
		part(m, "Parapet", Vector3.new(w + 1, 1.6, 0.8), at(0, h + 1.4, s * (d / 2 + 0.1)), trim)
		part(m, "Parapet", Vector3.new(0.8, 1.6, d + 1), at(s * (w / 2 + 0.1), h + 1.4, 0), trim)
	end
	-- ceiling lights in a grid
	for x = -w / 2 + 8, w / 2 - 8, 14 do
		for z = -d / 2 + 8, d / 2 - 8, 12 do
			local l = part(m, "CeilingLight", Vector3.new(5, 0.3, 1.4), at(x, h - 0.6, z), rgb(255, 250, 235), Enum.Material.Neon)
			Kit.light(l, 18, 0.6, rgb(255, 245, 225))
		end
	end
	if spec.sign then
		local board = part(m, "Sign", Vector3.new(spec.sign.w or math.min(w - 6, 36), spec.sign.h or 4, 0.5), at(0, dh + (h - dh) / 2, d / 2 + 0.2) * CFrame.Angles(0, math.rad(180), 0), spec.sign.bg or trim)
		Kit.sign(board, Enum.NormalId.Front, spec.sign.text, spec.sign.color or Kit.C.white, spec.sign.bg or trim, spec.sign.font or Enum.Font.LuckiestGuy, spec.sign.stroke)
	end
	return m, at
end

---------------------------------------------------------------------------
-- a gate arch over a road: two pillars, a name beam, lamps; `acrossX` = the road runs along z
function Kit.gateArch(parent, x, z, width, text, color, acrossX)
	local m = Kit.folder(parent, "Gate")
	local cf = CFrame.new(x, 0, z) * (acrossX and CFrame.new() or CFrame.Angles(0, math.rad(90), 0))
	for _, s in { -1, 1 } do
		part(m, "Pillar", Vector3.new(3.4, 20, 3.4), cf * CFrame.new(s * (width / 2 + 1.7), 10, 0), Kit.C.stone, Enum.Material.Brick)
		part(m, "PillarCap", Vector3.new(4.2, 1, 4.2), cf * CFrame.new(s * (width / 2 + 1.7), 20.5, 0), rgb(140, 136, 130), Enum.Material.Concrete)
		local lamp = part(m, "GateLamp", Vector3.new(1.4, 2, 1.4), cf * CFrame.new(s * (width / 2 + 1.7), 22, 0), rgb(255, 226, 170), Enum.Material.Neon)
		Kit.light(lamp, 24, 1, rgb(255, 214, 160))
	end
	local beam = part(m, "Beam", Vector3.new(width + 6.8, 4.2, 1.4), cf * CFrame.new(0, 17.4, 0), color)
	Kit.sign(beam, Enum.NormalId.Front, text, Kit.C.white, color, Enum.Font.LuckiestGuy, rgb(30, 20, 40))
	Kit.sign(beam, Enum.NormalId.Back, text, Kit.C.white, color, Enum.Font.LuckiestGuy, rgb(30, 20, 40))
	return m
end

return Kit
