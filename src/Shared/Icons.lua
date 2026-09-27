-- ReplicatedStorage.Shared.Icons
-- The store's (and the menus') icons: small chunky 3D models, built from parts, each shown as a
-- sticker: the model lit in one ViewportFrame over a second one holding eight copies of it drawn flat
-- dark, nudged a little every way across the screen (a clean outline all round, like the reference's
-- icons), swaying and bobbing gently. Two viewports an icon: Roblox draws viewports blurrier the more
-- a gui has, and nine an icon (one per outline copy) made the Store's soft and cost 6 fps.
-- Icons.view(parent, key, opts) -> a Frame holding the viewports.
-- Keys: basket crown gift sneaker goldboard gem clover broom padlock house moon cash moneybag vault
-- bus sparkle letter letterEpic refresh shop flask maple pine vexprep factory skull apple upArrow
-- pillar book pencil gear calendar wrench people scroll folder
-- (a key it doesn't know falls back to a gift)
local RunService = game:GetService("RunService")

local Icons = {}

local rgb = Color3.fromRGB
local GOLD, GOLD_D = rgb(255, 200, 50), rgb(220, 150, 20)
local INK = rgb(24, 22, 32)

local function p(m, size, cf, color, shape, mat)
	local x = Instance.new("Part")
	x.Anchored = true
	x.CanCollide = false
	x.Size = size
	x.CFrame = typeof(cf) == "Vector3" and CFrame.new(cf) or cf
	x.Color = color
	x.Material = mat or Enum.Material.SmoothPlastic
	x.TopSurface, x.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then x.Shape = shape end
	x.Parent = m
	return x
end
local function ball(m, d, pos, color, mat) return p(m, Vector3.one * d, pos, color, Enum.PartType.Ball, mat) end
-- a cylinder whose round faces point along the given axis ("x", "y" or "z")
local function cyl(m, d, len, pos, color, axis)
	local r = axis == "y" and CFrame.Angles(0, 0, math.rad(90)) or axis == "z" and CFrame.Angles(0, math.rad(90), 0) or CFrame.new()
	return p(m, Vector3.new(len, d, d), CFrame.new(pos) * r, color, Enum.PartType.Cylinder)
end
local function wedge(m, size, cf, color)
	local w = Instance.new("WedgePart")
	w.Anchored = true
	w.Size = size
	w.CFrame = cf
	w.Color = color
	w.Material = Enum.Material.SmoothPlastic
	w.Parent = m
	return w
end
local V = Vector3.new
local CF = CFrame.new

-- a cylinder along cf's own Y axis
local function cylc(m, d, len, cf, color, mat)
	return p(m, V(len, d, d), cf * CFrame.Angles(0, 0, math.rad(90)), color, Enum.PartType.Cylinder, mat)
end
-- a disc facing the camera (its round faces along Z)
local function disc(m, d, t, cf, color, mat)
	return p(m, V(t, d, d), cf * CFrame.Angles(0, math.rad(90), 0), color, Enum.PartType.Cylinder, mat)
end
-- a flat triangle facing the camera, pointing up cf's Y: w wide at its base, h tall, t thick (two
-- wedges back to back; a wedge's tall face is its back, so each half turns its back to the middle)
local function tri(m, w, h, t, cf, color, mat)
	for _, s in { -1, 1 } do
		local x = wedge(m, V(t, h, w / 2), cf * CF(s * w / 4, 0, 0) * CFrame.Angles(0, s > 0 and math.rad(-90) or math.rad(90), 0), color)
		if mat then x.Material = mat end
	end
end
-- a five-pointed star facing the camera, about 2.5 * s across
local function star5(m, at, s, color, t, mat)
	t = t or 0.3
	disc(m, 1.0 * s, t, at, color, mat)
	for k = 0, 4 do
		tri(m, 0.588 * s, 0.845 * s, t, at * CFrame.Angles(0, 0, k * math.rad(72)) * CF(0, 0.8275 * s, 0), color, mat)
	end
end
-- a cone from stacked discs, from its base at cf out along cf's Y
local function cone(m, cf, d0, d1, len, n, color)
	for i = 0, n - 1 do
		local f = (i + 0.5) / n
		cylc(m, d0 + (d1 - d0) * f, len / n + 0.02, cf * CF(0, len * f, 0), color)
	end
end
-- a glinting four-point star (the sparkle)
local function star(m, at, s, color)
	-- four spikes, each two wedges back to back (a thin triangle), round a small diamond
	for k = 0, 3 do
		local turn = at * CFrame.Angles(0, 0, k * math.pi / 2)
		for _, side in { -1, 1 } do
			local w = Instance.new("WedgePart")
			w.Anchored = true
			w.Size = V(0.3, 1.5, 0.45) * s
			w.CFrame = turn * CF(side * 0.22 * s, 0.95 * s, 0) * CFrame.Angles(0, side > 0 and math.rad(-90) or math.rad(90), 0)
			w.Color = color
			w.Material = Enum.Material.Neon
			w.Parent = m
		end
	end
	p(m, V(0.75, 0.75, 0.32) * s, at * CFrame.Angles(0, 0, math.rad(45)), color, nil, Enum.Material.Neon)
end

-- classic Roblox studs on a part's top (the reference icons are stud plastic, like the world is)
local function studs(x)
	x.Material = Enum.Material.Plastic
	x.TopSurface = Enum.SurfaceType.Studs
	return x
end

local B = {}

-- the Shop's basket, after tomas's reference (2026-09-27): a pink-red stud-plastic basket seen corner on
-- from above, its sides solid with the stud weave all over them, a thick rim standing out over them, the
-- inside a shade darker, and a plain pale grey handle standing up across it from the middle of one long
-- side to the other
local ALL_STUDS = { "TopSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface" }
local function studded(x)
	x.Material = Enum.Material.Plastic
	for _, f in ALL_STUDS do x[f] = Enum.SurfaceType.Studs end
	return x
end
function B.basket(m)
	local RED, RIM, INNER = rgb(232, 48, 88), rgb(244, 78, 112), rgb(172, 26, 58)
	local W, D = 4.6, 3.8 -- the long sides run along x; the handle goes across, along z
	local T = 0.36 -- the walls' thickness
	local Y0, Y1 = -1.5, 1.0 -- the body, bottom to the rim
	studs(p(m, V(W, 0.4, D), CF(0, Y0 + 0.2, 0), INNER))
	for _, side in { -1, 1 } do
		studded(p(m, V(W, Y1 - Y0, T), CF(0, (Y0 + Y1) / 2, side * (D / 2 - T / 2)), RED))
		studded(p(m, V(T, Y1 - Y0, D - 2 * T), CF(side * (W / 2 - T / 2), (Y0 + Y1) / 2, 0), RED))
		-- (the inside faces a shade darker, as the photo's are)
		p(m, V(W - 2 * T, Y1 - Y0 - 0.4, 0.04), CF(0, (Y0 + Y1) / 2 + 0.2, side * (D / 2 - T - 0.02)), INNER)
		p(m, V(0.04, Y1 - Y0 - 0.4, D - 2 * T), CF(side * (W / 2 - T - 0.02), (Y0 + Y1) / 2 + 0.2, 0), INNER)
	end
	-- the rim: a thick band standing out past the sides all round
	local O, H = 0.3, 0.6 -- how far it stands out, how tall
	local RW = T + O + 0.06
	for _, side in { -1, 1 } do
		studded(p(m, V(W + 2 * O, H, RW), CF(0, Y1 + H / 2, side * (D / 2 + O - RW / 2)), RIM))
		studded(p(m, V(RW, H, D + 2 * O - 2 * RW), CF(side * (W / 2 + O - RW / 2), Y1 + H / 2, 0), RIM))
	end
	-- the handle: a square arch, pale grey, its feet in the rim at the middle of the long sides
	local GREY, GREY_L = rgb(212, 220, 234), rgb(240, 244, 250)
	local zf = D / 2 - 0.1
	local top = Y1 + H + 1.95
	for _, side in { -1, 1 } do
		p(m, V(0.5, top - Y1 + 0.1, 0.5), CF(0, (Y1 + top) / 2, side * zf), GREY)
	end
	p(m, V(0.5, 0.5, 2 * zf + 0.5), CF(0, top, 0), GREY)
	p(m, V(0.52, 0.08, 2 * zf + 0.42), CF(0, top + 0.26, 0), GREY_L)
end

-- a crown (VIP), front on like the emoji: a band with a gold rim, five points with a pearl on each
-- (the middle one tallest), red velvet showing between them, jewels along the band
function B.crown(m)
	local G, GD, GL = rgb(255, 200, 50), rgb(215, 150, 25), rgb(255, 235, 140)
	local T = 1.1
	-- (the velvet sits well behind the band: only its top shows, between the points)
	ball(m, 2.3, V(0, 1.05, 1.25), rgb(200, 30, 60))
	p(m, V(4.4, 1.2, T), CF(0, -0.6, 0), G)
	p(m, V(4.5, 0.24, T + 0.1), CF(0, -1.24, 0), GD)
	p(m, V(4.5, 0.22, T + 0.1), CF(0, 0.05, 0), GL)
	local H = { 1.5, 1.9, 2.3, 1.9, 1.5 }
	for i, x in { -1.75, -0.9, 0, 0.9, 1.75 } do
		tri(m, 1.05, H[i], T * 0.9, CF(x, 0.15 + H[i] / 2, 0), G)
		ball(m, 0.52, V(x, 0.15 + H[i] + 0.1, 0), rgb(255, 250, 235))
	end
	disc(m, 0.78, 0.2, CF(0, -0.6, -T / 2 - 0.05), rgb(235, 40, 70))
	disc(m, 0.5, 0.22, CF(1.35, -0.6, -T / 2 - 0.05), rgb(70, 140, 255))
	disc(m, 0.5, 0.22, CF(-1.35, -0.6, -T / 2 - 0.05), rgb(70, 210, 110))
	star(m, CF(2.2, 2.0, -0.8), 0.4, rgb(255, 255, 255))
end

function B.gift(m)
	local RED, YEL = rgb(235, 60, 90), rgb(255, 210, 60)
	p(m, V(3.2, 2.6, 3.2), CF(0, -0.3, 0), RED)
	p(m, V(3.6, 0.8, 3.6), CF(0, 1.3, 0), rgb(255, 100, 125))
	p(m, V(0.7, 3.5, 3.3), CF(0, 0, 0), YEL)
	p(m, V(3.3, 3.5, 0.7), CF(0, 0, 0), YEL)
	for _, s in { -1, 1 } do p(m, V(1.4, 0.9, 0.6), CF(s * 0.65, 2.05, 0) * CFrame.Angles(0, 0, s * 0.5), YEL) end
	ball(m, 0.7, V(0, 1.95, 0), rgb(255, 180, 30))
end

function B.sneaker(m)
	local RED, WHITE = rgb(235, 60, 60), rgb(250, 250, 250)
	p(m, V(4.6, 0.6, 1.8), CF(0, -0.9, 0), WHITE)
	p(m, V(4.6, 0.25, 1.8), CF(0, -1.25, 0), rgb(60, 60, 70))
	p(m, V(2.6, 1.6, 1.7), CF(-0.9, 0.2, 0), RED)
	wedge(m, V(1.7, 1.2, 2.2), CF(1.45, 0, 0) * CFrame.Angles(0, math.rad(-90), 0), RED)
	p(m, V(0.9, 0.5, 1.72), CF(2.05, -0.35, 0), WHITE)
	for k = 0, 2 do p(m, V(0.3, 0.15, 1.2), CF(0.3 + k * 0.45, 0.35 - k * 0.22, 0) * CFrame.Angles(0, 0, -0.45), WHITE) end
	p(m, V(2.2, 0.35, 0.1), CF(-0.6, -0.1, -0.87) * CFrame.Angles(0, 0, 0.25), rgb(255, 210, 60))
	p(m, V(0.6, 0.9, 1.4), CF(-2.1, 1.0, 0), RED)
end

-- a hoverboard on the move, seen three-quarters on with its nose up: a thick capsule deck, dark grip
-- with a lightning bolt, a glowing strip and two jets underneath, speed lines trailing off behind
local function board(m, deck, bolt, glow)
	local tilt = CFrame.Angles(0, math.rad(22), 0) * CFrame.Angles(math.rad(-18), 0, math.rad(24))
	local function at(x, y, z) return tilt * CF(x, y, z) end
	local GRIP = rgb(45, 45, 55)
	p(m, V(3.4, 0.7, 1.7), at(0, 0, 0), deck)
	for _, s in { -1, 1 } do cylc(m, 1.7, 0.7, at(s * 1.7, 0, 0), deck) end
	p(m, V(3.2, 0.06, 1.36), at(0, 0.37, 0), GRIP)
	for _, s in { -1, 1 } do cylc(m, 1.36, 0.06, at(s * 1.6, 0.37, 0), GRIP) end
	-- (the bolt: two slanted bars and the step between them)
	p(m, V(1.2, 0.07, 0.34), at(0.45, 0.41, 0.22) * CFrame.Angles(0, math.rad(22), 0), bolt)
	p(m, V(1.2, 0.07, 0.34), at(-0.45, 0.41, -0.22) * CFrame.Angles(0, math.rad(22), 0), bolt)
	p(m, V(0.34, 0.07, 0.62), at(0, 0.41, 0), bolt)
	p(m, V(3.4, 0.1, 1.5), at(0, -0.38, 0), glow, nil, Enum.Material.Neon)
	for _, s in { -1, 1 } do
		cylc(m, 0.95, 0.35, at(s * 1.2, -0.5, 0), rgb(150, 155, 170))
		cylc(m, 0.72, 0.12, at(s * 1.2, -0.72, 0), glow, Enum.Material.Neon)
	end
	-- (behind it: +X on the deck, which is the screen's left)
	for i, z in { -0.5, 0, 0.5 } do
		local len = i == 2 and 1.0 or 0.7
		p(m, V(len, 0.14, 0.14), at(2.75 + len / 2, -0.1, z), rgb(255, 255, 255), nil, Enum.Material.Neon)
	end
end
function B.goldboard(m) board(m, GOLD, rgb(255, 225, 90), rgb(255, 150, 40)) end

-- a cut gem (the Store; the Diamond Board): a crown with its corners cut over a pavilion coming to a
-- point, pale facets on the lit side, deep ones on the other, and a glint
function B.gem(m)
	local T = 1.3
	local MID, LIGHT, PALE, DEEP = rgb(60, 165, 255), rgb(130, 210, 255), rgb(205, 242, 255), rgb(30, 105, 220)
	local F = -T / 2 - 0.03
	p(m, V(2.2, 0.8, T), CF(0, 0.7, 0), MID)
	for _, s in { -1, 1 } do
		wedge(m, V(T, 0.8, 0.9), CF(s * 1.55, 0.7, 0) * CFrame.Angles(0, s > 0 and math.rad(-90) or math.rad(90), 0), MID)
		wedge(m, V(0.06, 0.62, 0.72), CF(s * 1.45, 0.66, F) * CFrame.Angles(0, s > 0 and math.rad(-90) or math.rad(90), 0), s > 0 and PALE or LIGHT)
	end
	tri(m, 4.0, 2.5, T, CF(0, -0.95, 0) * CFrame.Angles(0, 0, math.pi), MID)
	-- (on screen, +X is the left: the light's side)
	p(m, V(2.0, 0.6, 0.06), CF(0, 0.72, F), PALE)
	local pav = CF(0, -0.88, F) * CFrame.Angles(0, 0, math.pi)
	for _, s in { -1, 1 } do
		wedge(m, V(0.06, 2.2, 1.72), pav * CF(s * 0.86, 0, 0) * CFrame.Angles(0, s > 0 and math.rad(-90) or math.rad(90), 0), s > 0 and DEEP or LIGHT)
	end
	tri(m, 1.3, 1.9, 0.06, CF(0, -0.72, F - 0.03) * CFrame.Angles(0, 0, math.pi), PALE)
	star(m, CF(1.7, 1.25, F - 0.3), 0.42, rgb(255, 255, 255))
end

function B.clover(m)
	local G = rgb(70, 200, 90)
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		local c = V(math.cos(a) * 0.95, math.sin(a) * 0.95, 0)
		ball(m, 1.5, c + V(math.cos(a + 0.5) * 0.35, math.sin(a + 0.5) * 0.35, 0), G)
		ball(m, 1.5, c + V(math.cos(a - 0.5) * 0.35, math.sin(a - 0.5) * 0.35, 0), G)
	end
	ball(m, 0.8, V(0, 0, -0.3), rgb(40, 150, 60))
	p(m, V(0.3, 1.8, 0.3), CF(0.35, -1.9, 0) * CFrame.Angles(0, 0, 0.3), rgb(40, 150, 60))
end

function B.broom(m)
	local tilt = CFrame.Angles(0, 0, math.rad(35))
	p(m, V(0.35, 4.8, 0.35), tilt * CF(0, 1.1, 0), rgb(160, 110, 60))
	p(m, V(1.1, 0.5, 1.1), tilt * CF(0, -1.2, 0), rgb(235, 60, 60))
	p(m, V(1.9, 1.8, 0.8), tilt * CF(0, -2.3, 0), rgb(245, 200, 80))
	for k = -2, 2 do p(m, V(0.12, 1.6, 0.85), tilt * CF(k * 0.35, -2.4, 0), rgb(210, 160, 50)) end
	ball(m, 0.6, (tilt * CF(0, 3.6, 0)).Position, rgb(235, 60, 60))
end

function B.padlock(m)
	p(m, V(3.2, 2.6, 1.3), CF(0, -0.6, 0), GOLD)
	p(m, V(3.4, 0.3, 1.4), CF(0, 0.75, 0), GOLD_D)
	local STEEL = rgb(200, 205, 215)
	for _, s in { -1, 1 } do p(m, V(0.45, 1.4, 0.45), CF(s * 1, 1.35, 0), STEEL) end
	for k = 0, 6 do
		local a = math.pi * k / 6
		p(m, V(0.5, 0.5, 0.45), CF(-math.cos(a) * 1, 2.05 + math.sin(a) * 0.9, 0), STEEL)
	end
	ball(m, 0.6, V(0, -0.45, -0.62), INK)
	p(m, V(0.28, 0.8, 0.1), CF(0, -0.9, -0.66), INK)
end

local function houseAt(m, at, s, wall, roof)
	s = s or 1
	local function place(cf) return at * CFrame.new(cf.Position * s) * cf.Rotation end
	local function q(size, cf, color, shape, mat) return p(m, size * s, place(cf), color, shape, mat) end
	local WHITE, GLASS, WOOD = rgb(255, 255, 252), rgb(135, 205, 255), rgb(150, 90, 50)
	local roofD = roof:Lerp(Color3.new(0, 0, 0), 0.25)
	q(V(3.8, 0.35, 3.0), CF(0, -1.75, 0), rgb(165, 160, 155))
	q(V(3.4, 2.4, 2.6), CF(0, -0.35, 0), wall)
	local ang = math.atan2(1.5, 1.3)
	for _, side in { -1, 1 } do
		local wcf = CF(0, 1.6, side * 0.65) * CFrame.Angles(0, side > 0 and math.pi or 0, 0)
		wedge(m, V(3.4, 1.5, 1.3) * s, place(wcf), wall)
		-- (in the wedge's own frame the slope's normal is Y turned back by the slope's angle)
		q(V(4.1, 0.24, 2.55), wcf * CFrame.Angles(-ang, 0, 0) * CF(0, 0.12, -0.25), roof)
	end
	q(V(4.2, 0.42, 0.42), CF(0, 2.45, 0), roofD, Enum.PartType.Cylinder)
	q(V(0.6, 1.2, 0.6), CF(1.0, 2.2, 0.55), rgb(185, 90, 70))
	q(V(0.8, 0.2, 0.8), CF(1.0, 2.85, 0.55), rgb(120, 60, 50))
	-- the door
	q(V(1.15, 1.7, 0.1), CF(-0.6, -0.7, -1.33), WHITE)
	q(V(0.92, 1.52, 0.12), CF(-0.6, -0.79, -1.36), WOOD)
	q(V(0.5, 0.34, 0.05), CF(-0.6, -0.35, -1.43), GLASS)
	q(V(0.2, 0.2, 0.2), CF(-0.34, -0.9, -1.44), rgb(255, 200, 60), Enum.PartType.Ball)
	q(V(1.3, 0.2, 0.45), CF(-0.6, -1.66, -1.5), rgb(185, 180, 175))
	-- the front window, a side window and a round one up in the gable
	q(V(1.2, 1.05, 0.1), CF(0.8, -0.3, -1.33), WHITE)
	q(V(0.94, 0.8, 0.12), CF(0.8, -0.3, -1.35), GLASS)
	q(V(0.1, 0.8, 0.14), CF(0.8, -0.3, -1.37), WHITE)
	q(V(0.94, 0.1, 0.14), CF(0.8, -0.3, -1.37), WHITE)
	q(V(1.35, 0.14, 0.32), CF(0.8, -0.88, -1.42), WHITE)
	q(V(0.1, 0.95, 1.0), CF(-1.72, -0.3, 0.2), WHITE)
	q(V(0.12, 0.72, 0.76), CF(-1.73, -0.3, 0.2), GLASS)
	q(V(0.1, 0.72, 0.72), CF(-1.72, 1.3, 0), WHITE, Enum.PartType.Cylinder)
	q(V(0.12, 0.52, 0.52), CF(-1.73, 1.3, 0), GLASS, Enum.PartType.Cylinder)
	-- a bush by the window
	q(V(1, 1, 1), CF(1.75, -1.3, -1.2), rgb(70, 185, 80), Enum.PartType.Ball)
	q(V(0.75, 0.75, 0.75), CF(1.22, -1.48, -1.45), rgb(95, 205, 95), Enum.PartType.Ball)
end
function B.house(m) houseAt(m, CF(), 1, rgb(255, 242, 220), rgb(230, 65, 65)) end

-- a sleepy crescent moon (Offline Tuition+): slim, tapering to its horns, its back to the left of the
-- screen (+X here), a nightcap on its top horn and a Z z drifting off (no face: tomas, 2026-09-27)
function B.moon(m)
	local Y = rgb(255, 215, 80)
	local C, Rr = V(-0.3, 0, 0), 1.9
	for deg = -110, 110, 6 do
		local a = math.rad(deg)
		local d = 0.35 + 1.25 * math.cos(a * 0.82)
		-- (each disc touches the outer circle, so the back is one smooth curve)
		disc(m, d, 0.9, CF(C + V(math.cos(a), math.sin(a), 0) * (Rr - d / 2)), Y)
	end
	-- a nightcap on its top horn, drooping, with a white rim and a pom-pom
	local capAt = CF(-0.35, 1.55, 0) * CFrame.Angles(0, 0, math.rad(38))
	cone(m, capAt, 1.2, 0.2, 1.7, 8, rgb(70, 110, 230))
	cylc(m, 1.35, 0.28, capAt, rgb(250, 250, 255))
	ball(m, 0.5, (capAt * CF(0, 1.85, 0)).Position, rgb(250, 250, 255))
	-- Z z (on screen: top bar, a slash from top right to bottom left, bottom bar; right is -X here)
	for _, z in { { -1.55, 0.35, 0.55 }, { -2.05, 0.95, 0.4 } } do
		local at, sz = CF(z[1], z[2], -0.2), z[3]
		local ZC = rgb(205, 225, 255)
		p(m, V(sz, sz * 0.22, 0.14), at * CF(0, sz / 2, 0), ZC)
		p(m, V(sz, sz * 0.22, 0.14), at * CF(0, -sz / 2, 0), ZC)
		p(m, V(sz * 1.3, sz * 0.2, 0.14), at * CFrame.Angles(0, 0, math.rad(-45)), ZC)
	end
end

-- a brick of cash, after tomas's reference (2026-09-27, the Sell icon): green bills stacked square, a
-- pale edge between each so the sides read as paper, a lighter panel and studs on the top bill, and a
-- gold paper band round the middle
local function cashBrick(m, at, n)
	local G, G2, EDGE, PANEL = rgb(70, 190, 80), rgb(85, 205, 95), rgb(185, 240, 170), rgb(140, 225, 130)
	local W, D, T = 4.0, 2.4, 0.36 -- a bill's size (x, z) and a bundle's thickness
	for k = 0, n - 1 do
		-- (each bundle a hair off square, alternating shades)
		local cf = at * CF(((k * 3) % 5 - 2) * 0.03, (k + 0.5) * T, ((k * 2) % 5 - 2) * 0.03)
		p(m, V(W, T - 0.07, D), cf * CF(0, -0.035, 0), k % 2 == 0 and G or G2)
		p(m, V(W - 0.04, 0.07, D - 0.04), cf * CF(0, T / 2 - 0.035, 0), EDGE)
	end
	local top = at * CF(0, n * T, 0)
	studs(p(m, V(W, 0.08, D), top * CF(0, 0.04, 0), G))
	studs(p(m, V(W - 0.8, 0.08, D - 0.7), top * CF(0, 0.1, 0), PANEL))
	-- the band
	local h = n * T + 0.4
	studs(p(m, V(0.95, h, D + 0.12), at * CF(0.35, h / 2 - 0.08, 0), rgb(255, 205, 60)))
	for _, s in { -1, 1 } do p(m, V(0.1, h + 0.02, D + 0.14), at * CF(0.35 + s * 0.45, h / 2 - 0.08, 0), rgb(215, 150, 25)) end
end
function B.cash(m) cashBrick(m, CF(0, -1.2, 0), 5) end
-- (the older, flatter stack: the money mountain is piled from these)
local function cashStack(m, at, layers)
	local G, GL = rgb(70, 190, 80), rgb(150, 230, 140)
	for k = 0, layers - 1 do
		local cf = at * CF(0, k * 0.55, 0) * CFrame.Angles(0, math.rad((k % 2 == 0 and 1 or -1) * 4), 0)
		p(m, V(3.6, 0.5, 2), cf, G)
		p(m, V(3.1, 0.52, 1.5), cf, GL)
		p(m, V(0.9, 0.54, 0.9), cf, G)
	end
	p(m, V(0.7, layers * 0.55 + 0.1, 2.1), at * CF(0, (layers - 1) * 0.275, 0), rgb(255, 200, 50))
end

-- a sack of money (the Tuition Bag): round and full, cinched at the neck with a rope, its top flaring
-- out, a big green dollar sign on the front and coins spilt at its feet
function B.moneybag(m)
	local TAN, TAND, ROPE = rgb(215, 170, 100), rgb(185, 140, 75), rgb(140, 90, 45)
	ball(m, 3.4, V(0, -0.5, 0), TAN)
	ball(m, 2.7, V(0, -1.0, 0.25), TAN)
	cylc(m, 1.3, 0.8, CF(0, 1.35, 0), TAN)
	cylc(m, 1.48, 0.3, CF(0, 1.15, 0), ROPE)
	ball(m, 0.42, V(0.55, 1.1, -0.55), ROPE)
	for k = 0, 6 do
		local a = k / 7 * math.pi * 2
		ball(m, 0.62, V(math.cos(a) * 0.55, 1.85, math.sin(a) * 0.55), TAN)
	end
	ball(m, 0.7, V(0, 2.0, 0), TAND)
	-- the $ (an S of bars, drawn mirrored: the screen's left is +X), a bar through it
	local D, Z = rgb(40, 150, 70), -1.62
	local c = V(0, -0.45, Z)
	for _, y in { 0.5, 0, -0.5 } do p(m, V(0.85, 0.2, 0.3), CF(c + V(0, y, 0)), D) end
	p(m, V(0.2, 0.52, 0.3), CF(c + V(0.33, 0.25, 0)), D)
	p(m, V(0.2, 0.52, 0.3), CF(c + V(-0.33, -0.25, 0)), D)
	p(m, V(0.14, 1.55, 0.32), CF(c), D)
	for _, cn in { { 1.35, -2.1, -0.9 }, { -1.15, -2.15, -1.0 }, { 0.2, -2.2, -1.5 } } do
		cylc(m, 0.9, 0.16, CF(cn[1], cn[2], cn[3]), GOLD)
	end
	disc(m, 0.95, 0.16, CF(1.85, -1.55, -0.7) * CFrame.Angles(0, 0, math.rad(15)), GOLD)
end

function B.vault(m)
	local STEEL, DARK = rgb(170, 176, 190), rgb(110, 116, 130)
	p(m, V(3.8, 3.8, 1.6), CF(0, 0.3, 0), STEEL)
	cyl(m, 3, 0.3, V(0, 0.3, -0.85), DARK, "z")
	cyl(m, 1, 0.4, V(0, 0.3, -1.05), GOLD, "z")
	for k = 0, 2 do p(m, V(2.4, 0.25, 0.25), CF(0, 0.3, -1.15) * CFrame.Angles(0, 0, k * math.pi / 3), GOLD) end
	for i, x in { -0.9, 0.9 } do p(m, V(1.4, 0.7, 0.8), CF(x, -1.9, -0.9) * CFrame.Angles(0, (i - 1.5) * 0.4, 0), GOLD) end
end

function B.bus(m)
	local YEL = rgb(255, 200, 40)
	p(m, V(5, 2.2, 1.9), CF(0, 0.2, 0), YEL)
	p(m, V(1.2, 1.2, 1.9), CF(2.9, -0.3, 0), YEL)
	for k = 0, 3 do p(m, V(0.8, 0.7, 0.1), CF(-1.8 + k * 1.05, 0.6, -0.96), rgb(150, 210, 255)) end
	p(m, V(5, 0.25, 0.1), CF(0, -0.35, -0.96), INK)
	p(m, V(5, 0.25, 1.95), CF(0, 1.35, 0), rgb(250, 250, 245))
	for _, x in { -1.6, 1.9 } do
		cyl(m, 1.1, 0.4, V(x, -0.95, -0.85), INK, "z")
		cyl(m, 0.5, 0.42, V(x, -0.95, -0.87), rgb(200, 205, 215), "z")
	end
	ball(m, 0.4, V(3.5, -0.1, -0.7), rgb(255, 250, 220), Enum.Material.Neon)
end

function B.sparkle(m)
	star(m, CF(-0.3, 0.2, 0), 1.3, rgb(255, 225, 80))
	star(m, CF(1.5, 1.5, 0.3), 0.6, rgb(255, 255, 255))
	star(m, CF(1.4, -1.3, 0.3), 0.5, rgb(255, 180, 230))
end

-- a sealed letter: the envelope, its flap folded down to a point with the wax seal on it (a star
-- pressed in), the folds of its pocket, and the rarity's badge in the corner
local function letter(m, paper, flap, seal, sealDark, badge)
	p(m, V(4.2, 2.8, 0.35), CF(0, 0, 0), paper)
	-- the pocket's folds: from each bottom corner up to the middle
	for _, sx in { -1, 1 } do
		p(m, V(2.37, 0.1, 0.06), CF(sx * 1.05, -0.85, -0.2) * CFrame.Angles(0, 0, sx * math.rad(-27.6)), flap)
	end
	tri(m, 4.2, 1.6, 0.08, CF(0, 0.6, -0.21) * CFrame.Angles(0, 0, math.pi), flap)
	disc(m, 1.0, 0.18, CF(0, -0.15, -0.3), seal)
	star5(m, CF(0, -0.15, -0.41), 0.26, sealDark, 0.06)
	badge(m)
end
function B.letter(m)
	letter(m, rgb(248, 243, 230), rgb(222, 214, 196), rgb(60, 130, 240), rgb(30, 80, 180), function(m2)
		star5(m2, CF(1.55, 1.0, -0.25), 0.3, rgb(60, 130, 240), 0.1)
	end)
end
function B.letterEpic(m)
	letter(m, rgb(255, 190, 225), rgb(240, 150, 200), rgb(150, 60, 220), rgb(100, 30, 160), function(m2)
		star(m2, CF(1.6, 1.2, -0.4), 0.42, rgb(255, 255, 255))
		star(m2, CF(-1.7, -1.1, -0.4), 0.3, rgb(255, 230, 255))
	end)
end

-- Lock Refresh: a padlock inside a round arrow
function B.refresh(m)
	local BL = rgb(90, 160, 255)
	local R = 2.0
	for deg = 50, 320, 9 do
		local a = math.rad(deg)
		p(m, V(0.62, 0.44, 0.5), CF(math.cos(a) * R, math.sin(a) * R, 0) * CFrame.Angles(0, 0, a + math.pi / 2), BL)
	end
	-- the head at the ring's start, pointing on round
	local a = math.rad(50)
	local tangent = V(math.sin(a), -math.cos(a), 0)
	tri(m, 1.3, 1.0, 0.5, CF(V(math.cos(a) * R, math.sin(a) * R, 0) + tangent * 0.35) * CFrame.Angles(0, 0, a + math.pi), BL)
	-- the padlock
	p(m, V(1.5, 1.2, 0.7), CF(0, -0.35, 0), GOLD)
	p(m, V(1.56, 0.18, 0.74), CF(0, 0.2, 0), GOLD_D)
	for k = 0, 8 do
		local b = math.pi * k / 8
		p(m, V(0.26, 0.26, 0.3), CF(-math.cos(b) * 0.48, 0.3 + math.sin(b) * 0.6, 0), rgb(200, 205, 218))
	end
	disc(m, 0.34, 0.1, CF(0, -0.25, -0.38), INK)
	p(m, V(0.14, 0.34, 0.1), CF(0, -0.5, -0.38), INK)
end

function B.shop(m)
	p(m, V(4, 3, 2.4), CF(0, -0.3, 0), rgb(255, 245, 225))
	for k = 0, 4 do p(m, V(0.8, 0.3, 1.2), CF(-1.6 + k * 0.8, 1.2, -1.5) * CFrame.Angles(math.rad(25), 0, 0), k % 2 == 0 and rgb(235, 60, 70) or rgb(255, 255, 255)) end
	p(m, V(1.6, 1.4, 0.1), CF(-0.9, -0.8, -1.22), rgb(150, 210, 255))
	p(m, V(0.9, 1.8, 0.1), CF(1.1, -0.9, -1.22), rgb(150, 90, 50))
	p(m, V(3, 0.7, 0.2), CF(0, 1.75, -1.1), rgb(60, 140, 230))
end

function B.flask(m)
	cyl(m, 0.9, 1.6, V(0, 1.5, 0), rgb(200, 235, 255), "y")
	cyl(m, 1.2, 0.3, V(0, 2.35, 0), rgb(220, 220, 230), "y")
	ball(m, 3, V(0, -0.6, 0), rgb(120, 230, 70), Enum.Material.Neon)
	for i, b in { { -0.4, 0.4, 0.5 }, { 0.5, 1.2, 0.4 }, { 0.1, 2.9, 0.35 } } do
		ball(m, b[3], V(b[1], b[2], -1), rgb(220, 255, 200))
		_ = i
	end
end

local function pine(m, at, s)
	p(m, V(0.6, 1.2, 0.6) * s, at * CF(0, -1.9 * s, 0), rgb(140, 90, 50))
	for k, w in { 3.2, 2.4, 1.5 } do
		p(m, V(w, 1.2, w) * s, at * CF(0, (-1.1 + (k - 1) * 1) * s, 0) * CFrame.Angles(0, math.rad(45), 0), rgb(50, 150, 70))
	end
end
function B.pine(m) pine(m, CF(), 1.1) end
function B.maple(m)
	houseAt(m, CF(-0.7, 0, 0), 0.9, rgb(170, 205, 245), rgb(90, 90, 110))
	ball(m, 2, V(1.9, 0.4, 0.5), rgb(80, 180, 80))
	p(m, V(0.4, 1.4, 0.4), CF(1.9, -1, 0.5), rgb(140, 90, 50))
end

function B.vexprep(m)
	local PUR = rgb(130, 60, 200)
	p(m, V(4.2, 2.4, 2.2), CF(0, -0.6, 0), PUR)
	p(m, V(1.4, 2.2, 1.4), CF(0, 1.6, 0), rgb(160, 90, 230))
	wedge(m, V(1.6, 1, 0.8), CF(0, 3.2, -0.4), rgb(90, 40, 150))
	wedge(m, V(1.6, 1, 0.8), CF(0, 3.2, 0.4) * CFrame.Angles(0, math.pi, 0), rgb(90, 40, 150))
	for x = -1.5, 1.5, 1 do p(m, V(0.5, 0.7, 0.1), CF(x, -0.5, -1.12), rgb(220, 200, 255), nil, Enum.Material.Neon) end
	p(m, V(0.1, 1.2, 0.1), CF(0.5, 4.1, 0), INK)
	p(m, V(0.8, 0.5, 0.05), CF(0.9, 4.4, 0), rgb(255, 80, 180))
end

function B.factory(m)
	local GREY = rgb(150, 150, 165)
	p(m, V(4.4, 2.4, 2.4), CF(0, -0.8, 0), GREY)
	for k = 0, 2 do
		wedge(m, V(1.4, 0.9, 1.45), CF(-1.45 + k * 1.45, 0.85, 0) * CFrame.Angles(0, math.rad(-90), 0), rgb(120, 60, 170))
	end
	for _, x in { 1.2, 1.9 } do cyl(m, 0.7, 2.6, V(x, 1.5, 0.5), rgb(110, 110, 125), "y") end
	for i, sm in { { 1.2, 3.2, 0.9 }, { 1.7, 3.9, 1.1 }, { 2.4, 4.4, 0.8 } } do ball(m, sm[3], V(sm[1], sm[2], 0.5), rgb(200, 200, 215)) _ = i end
	p(m, V(1, 1.2, 0.1), CF(-1, -1.4, -1.22), rgb(60, 60, 70))
end

function B.skull(m)
	local W = rgb(245, 240, 230)
	ball(m, 3.2, V(0, 0.4, 0), W)
	p(m, V(1.8, 1, 1.6), CF(0, -1.3, -0.3), W)
	for _, s in { -1, 1 } do ball(m, 0.95, V(s * 0.65, 0.35, -1.3), INK) end
	p(m, V(0.4, 0.5, 0.2), CF(0, -0.4, -1.45) * CFrame.Angles(0, 0, math.rad(45)), INK)
	for k = -1, 1 do p(m, V(0.15, 0.6, 0.2), CF(k * 0.45, -1.4, -1.12), INK) end
end

-- the bigger tuition packs: a briefcase with bills sticking out, a treasure chest, a cash truck and a
-- mountain of cash
local BILL, BILL_L = rgb(95, 195, 100), rgb(165, 235, 150)
local function bill(m, cf)
	p(m, V(1.7, 1.2, 0.06), cf, BILL)
	p(m, V(1.2, 0.75, 0.07), cf, BILL_L)
	disc(m, 0.42, 0.08, cf, BILL)
end
function B.briefcase(m)
	local LEATHER, LD, GOLDL = rgb(130, 76, 42), rgb(92, 52, 28), rgb(255, 205, 70)
	for k = -1, 1 do bill(m, CF(k * 0.95, 1.45 + (k == 0 and 0.2 or 0), 0.15 + k * 0.05) * CFrame.Angles(0, 0, math.rad(-k * 14))) end
	p(m, V(4.4, 2.8, 1.4), CF(0, 0, 0), LEATHER)
	p(m, V(4.5, 0.32, 1.5), CF(0, 0.72, 0), LD)
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do p(m, V(0.42, 0.42, 1.5), CF(x * 2.05, y * 1.22, 0), GOLDL) end
		p(m, V(0.55, 0.5, 0.16), CF(x * 1.15, 0.72, -0.78), GOLDL)
		p(m, V(0.2, 0.18, 0.05), CF(x * 1.15, 0.7, -0.87), LD)
		p(m, V(0.26, 0.45, 0.32), CF(x * 0.8, 1.6, 0), LD)
	end
	cyl(m, 0.34, 1.9, V(0, 1.88, 0), LD, "x")
end
function B.chest(m)
	local WOOD, WD, GOLDL = rgb(170, 104, 52), rgb(120, 70, 35), rgb(255, 200, 60)
	p(m, V(4.2, 2.2, 2.6), CF(0, -0.9, 0), WOOD)
	for _, y in { -1.45, -0.75 } do p(m, V(4.22, 0.08, 2.62), CF(0, y, 0), WD) end
	for _, x in { -1.45, 1.45 } do p(m, V(0.34, 2.25, 2.65), CF(x, -0.9, 0), GOLDL) end
	p(m, V(4.26, 0.3, 2.66), CF(0, 0.12, 0), GOLDL)
	p(m, V(0.75, 0.85, 0.14), CF(0, -0.3, -1.36), GOLDL)
	p(m, V(0.18, 0.34, 0.05), CF(0, -0.38, -1.44), WD)
	-- the lid, swung open back past upright on its hinge along the back
	local lid = CF(0, 0.25, 1.3) * CFrame.Angles(math.rad(105), 0, 0)
	p(m, V(4.2, 0.8, 2.6), lid * CF(0, 0.4, -1.3), WOOD)
	for _, x in { -1.45, 1.45 } do p(m, V(0.34, 0.84, 2.65), lid * CF(x, 0.4, -1.3), GOLDL) end
	-- heaped full: gold coins, two bricks of cash, a sparkle
	local COIN = rgb(255, 205, 60)
	for _, c in { { -1.4, 0.35, -0.6 }, { -0.7, 0.55, -0.3 }, { 0.1, 0.5, -0.7 }, { 0.9, 0.45, -0.4 }, { 1.5, 0.3, -0.8 }, { -1.1, 0.4, 0.5 }, { 0.5, 0.6, 0.4 }, { 1.3, 0.4, 0.5 }, { -0.2, 0.75, 0.1 } } do
		ball(m, 0.75, V(c[1], c[2], c[3]), COIN)
	end
	for _, c in { { -0.9, 0.95, -0.55, 20 }, { 1.0, 0.85, -0.6, -25 } } do
		disc(m, 0.85, 0.16, CF(c[1], c[2], c[3]) * CFrame.Angles(0, 0, math.rad(c[4])), rgb(255, 225, 100))
	end
	p(m, V(1.6, 0.45, 0.9), CF(0.3, 0.95, 0.3) * CFrame.Angles(0, 0.3, 0.12), BILL)
	p(m, V(0.35, 0.47, 0.92), CF(0.3, 0.95, 0.3) * CFrame.Angles(0, 0.3, 0.12), COIN)
	star(m, CF(-1.6, 1.4, -1.2), 0.4, rgb(255, 255, 255))
end
function B.truck(m)
	-- an armoured cash truck, nose to the left of the screen (+X), a gold coin on its side
	local BODY, BODY_D, GLASS, STEEL = rgb(60, 150, 100), rgb(40, 110, 72), rgb(150, 215, 255), rgb(200, 205, 215)
	p(m, V(3.8, 2.6, 2.3), CF(-0.35, 0.2, 0), BODY)
	p(m, V(3.84, 0.3, 2.34), CF(-0.35, -0.55, 0), rgb(255, 200, 50))
	p(m, V(1.5, 1.9, 2.2), CF(2.3, -0.15, 0), BODY)
	p(m, V(1.5, 0.3, 2.24), CF(2.3, -0.75, 0), BODY_D)
	p(m, V(0.1, 0.8, 1.8), CF(3.06, 0.3, 0), GLASS)
	p(m, V(0.8, 0.7, 0.1), CF(2.35, 0.3, -1.12), GLASS)
	p(m, V(0.3, 0.45, 2.4), CF(3.1, -1.0, 0), STEEL)
	ball(m, 0.4, V(3.08, -0.45, -0.75), rgb(255, 250, 220), Enum.Material.Neon)
	-- the coin on its side
	disc(m, 1.5, 0.12, CF(-0.4, 0.45, -1.2), rgb(255, 200, 50))
	disc(m, 1.05, 0.14, CF(-0.4, 0.45, -1.21), rgb(255, 225, 110))
	p(m, V(0.18, 0.9, 0.16), CF(-0.4, 0.45, -1.28), rgb(210, 150, 20))
	-- the back doors' seam and the wheels
	p(m, V(0.08, 2.2, 0.08), CF(-2.26, 0.2, -0.6), BODY_D)
	for _, x in { -1.4, 2.2 } do
		disc(m, 1.2, 0.45, CF(x, -1.2, -1.0), INK)
		disc(m, 0.55, 0.47, CF(x, -1.2, -1.02), STEEL)
	end
end
function B.moneyMountain(m)
	-- a whole week: a pile of cash bricks, a giant gold coin standing on top, coins spilt round it
	cashStack(m, CF(-1.85, -1.6, 0), 2)
	cashStack(m, CF(1.85, -1.6, 0), 2)
	cashStack(m, CF(-0.95, -0.5, 0) * CFrame.Angles(0, math.rad(90), 0), 2)
	cashStack(m, CF(0.95, -0.5, 0) * CFrame.Angles(0, math.rad(90), 0), 2)
	cashStack(m, CF(0, 0.6, 0) * CFrame.Angles(0, math.rad(15), 0), 2)
	disc(m, 2.3, 0.4, CF(0, 2.75, 0), rgb(255, 195, 45))
	disc(m, 1.75, 0.44, CF(0, 2.75, 0), rgb(255, 225, 110))
	star5(m, CF(0, 2.75, -0.25), 0.5, rgb(255, 190, 40), 0.1)
	for _, c in { { -3.3, -1.75, -0.8 }, { 3.2, -1.8, -0.7 }, { -2.6, -1.85, -1.2 }, { 2.5, -1.85, -1.3 } } do
		cylc(m, 0.8, 0.18, CF(c[1], c[2], c[3]), rgb(255, 205, 60))
	end
	star(m, CF(2.2, 2.6, -0.6), 0.45, rgb(255, 255, 255))
	star(m, CF(-2.3, 1.2, -0.6), 0.35, rgb(255, 255, 255))
end

-- the Co-op roles' own: the Hall Monitor's shield (silver rim, red face, a gold star) and the
-- Recruiter's backpack (rounded top, a front pocket with its zip, a carry loop, a star patch)
function B.shield(m)
	local RIM, FACE, GOLDL = rgb(205, 210, 222), rgb(230, 70, 70), rgb(255, 205, 70)
	p(m, V(3.4, 2.0, 0.8), CF(0, 0.8, 0), RIM)
	tri(m, 3.4, 2.4, 0.8, CF(0, -1.4, 0) * CFrame.Angles(0, 0, math.pi), RIM)
	p(m, V(2.9, 1.8, 0.1), CF(0, 0.85, -0.42), FACE)
	tri(m, 2.9, 2.05, 0.1, CF(0, -1.2, -0.42) * CFrame.Angles(0, 0, math.pi), FACE)
	star5(m, CF(0, 0.3, -0.52), 0.55, GOLDL, 0.12)
end
function B.backpack(m)
	local BAG, BAGD, POCKET = rgb(240, 120, 50), rgb(190, 85, 30), rgb(255, 165, 90)
	p(m, V(3.0, 3.0, 1.6), CF(0, -0.5, 0), BAG)
	disc(m, 3.0, 1.6, CF(0, 1.0, 0), BAG)
	p(m, V(2.3, 1.4, 0.45), CF(0, -1.05, -0.95), POCKET)
	p(m, V(2.3, 0.1, 0.47), CF(0, -0.42, -0.97), BAGD)
	ball(m, 0.28, V(0.85, -0.42, -1.2), rgb(230, 230, 235))
	for k = 0, 8 do
		local b = math.pi * k / 8
		p(m, V(0.26, 0.26, 0.3), CF(-math.cos(b) * 0.5, 2.45 + math.sin(b) * 0.45, 0), BAGD)
	end
	star5(m, CF(0, 0.95, -0.84), 0.34, rgb(255, 225, 90), 0.08)
end

-- the panels' own icons (hanging off their title bars)
function B.apple(m)
	ball(m, 3, V(0, -0.2, 0), rgb(235, 50, 60))
	ball(m, 1.4, V(-0.6, 0.9, -0.2), rgb(255, 110, 110))
	p(m, V(0.3, 1, 0.3), CF(0, 1.6, 0) * CFrame.Angles(0, 0, 0.2), rgb(120, 80, 40))
	p(m, V(1.1, 0.25, 0.6), CF(0.6, 1.8, 0) * CFrame.Angles(0, 0, -0.5), rgb(80, 200, 80))
end
function B.upArrow(m)
	-- a chunky arrow, a lighter face set into it (a bevel), a shine and two glints
	local G, GL = rgb(70, 215, 100), rgb(160, 255, 170)
	p(m, V(1.6, 2.1, 1.1), CF(0, -1.05, 0), G)
	tri(m, 3.8, 2.0, 1.1, CF(0, 0.95, 0), G)
	p(m, V(1.05, 2.15, 0.06), CF(0, -0.92, -0.58), GL)
	tri(m, 2.5, 1.3, 0.06, CF(0, 0.78, -0.58), GL)
	p(m, V(0.22, 1.3, 0.07), CF(0.3, -1.05, -0.62), rgb(235, 255, 235))
	star(m, CF(1.75, 1.5, -0.5), 0.38, rgb(255, 255, 255))
	star(m, CF(-1.6, -1.6, -0.5), 0.3, rgb(255, 255, 255))
end
function B.pillar(m)
	-- the School Board's hall: steps, four columns with their bases and capitals, a hall behind, the
	-- beam with a gold band and the pediment with a gold star
	local W, T, GOLDL = rgb(250, 246, 238), rgb(205, 195, 180), rgb(255, 205, 70)
	p(m, V(4.8, 0.35, 2.7), CF(0, -2.0, 0), T)
	p(m, V(4.4, 0.35, 2.4), CF(0, -1.65, 0), W)
	p(m, V(4.0, 2.6, 1.2), CF(0, -0.15, 0.6), rgb(222, 212, 196))
	for _, x in { -1.5, -0.5, 0.5, 1.5 } do
		p(m, V(0.78, 0.22, 0.78), CF(x, -1.37, -0.2), T)
		cyl(m, 0.6, 2.4, V(x, -0.15, -0.2), W, "y")
		p(m, V(0.82, 0.24, 0.82), CF(x, 1.07, -0.2), T)
	end
	p(m, V(4.6, 0.5, 2.5), CF(0, 1.44, 0), W)
	p(m, V(4.62, 0.12, 2.52), CF(0, 1.3, 0), GOLDL)
	tri(m, 4.8, 1.15, 2.5, CF(0, 2.27, 0), W)
	tri(m, 3.6, 0.72, 0.06, CF(0, 2.17, -1.27), T)
	star5(m, CF(0, 2.08, -1.33), 0.3, GOLDL, 0.1)
end
-- the yearbook, after tomas's reference (2026-09-27, the Collection book): a fat blue book lying flat,
-- the pages showing white round three sides, a dark spine, a pale label on the studded cover and a
-- red ribbon hanging out of the bottom with a notch in its end
function B.book(m)
	local BL, BLD, BLL, PAGE, LINE = rgb(60, 130, 240), rgb(35, 85, 185), rgb(150, 200, 255), rgb(252, 250, 242), rgb(200, 202, 214)
	local W, L = 3.6, 4.6 -- across (x), top to bottom (z)
	-- (the spine on the +X side, which is the left of the screen)
	p(m, V(W, 0.32, L), CF(0, -0.62, 0), BL)
	studs(p(m, V(W, 0.32, L), CF(0, 0.62, 0), BL))
	p(m, V(W - 0.3, 0.92, L - 0.3), CF(-0.05, 0, 0), PAGE)
	p(m, V(0.5, 1.56, L + 0.02), CF(W / 2 - 0.15, 0, 0), BLD)
	for _, z in { -1, 1 } do p(m, V(0.54, 1.6, 0.26), CF(W / 2 - 0.15, 0, z * (L / 2 - 0.55)), BL) end
	-- the page edges: lines along the side and the bottom
	for _, y in { -0.25, 0, 0.25 } do
		p(m, V(0.03, 0.05, L - 0.5), CF(-W / 2 + 0.09, y, 0), LINE)
		p(m, V(W - 0.7, 0.05, 0.03), CF(-0.1, y, -L / 2 + 0.14), LINE)
	end
	-- the label: pale, studs on it, two lines of title
	studs(p(m, V(2.0, 0.08, 1.5), CF(-0.2, 0.82, 0.6), BLL))
	for k, w in { 1.3, 0.9 } do p(m, V(w, 0.1, 0.16), CF(-0.2, 0.84, 0.85 - k * 0.35), BLD) end
	-- the ribbon, out of the pages at the bottom and down over the edge
	local RIB = rgb(235, 55, 70)
	p(m, V(0.5, 0.08, 0.5), CF(-0.9, 0.1, -L / 2 - 0.1), RIB)
	p(m, V(0.5, 0.95, 0.08), CF(-0.9, -0.3, -L / 2 - 0.34), RIB)
	for _, x in { -0.16, 0.16 } do p(m, V(0.18, 0.28, 0.08), CF(-0.9 + x, -0.9, -L / 2 - 0.34), RIB) end
end
function B.pencil(m)
	-- a yellow pencil: a metal band with ridges, a pink eraser, a sharpened wooden end and its lead
	local tilt = CFrame.Angles(0, 0, math.rad(45))
	cylc(m, 1.0, 3.0, tilt * CF(0, 0.3, 0), rgb(255, 200, 40))
	cylc(m, 1.06, 0.6, tilt * CF(0, 2.1, 0), rgb(205, 210, 222))
	for _, y in { 1.92, 2.28 } do cylc(m, 1.12, 0.08, tilt * CF(0, y, 0), rgb(150, 155, 170)) end
	cylc(m, 1.0, 0.45, tilt * CF(0, 2.62, 0), rgb(255, 130, 160))
	ball(m, 1.0, (tilt * CF(0, 2.85, 0)).Position, rgb(255, 130, 160))
	cone(m, tilt * CF(0, -1.2, 0) * CFrame.Angles(math.pi, 0, 0), 1.0, 0.36, 1.1, 8, rgb(245, 210, 165))
	cone(m, tilt * CF(0, -2.3, 0) * CFrame.Angles(math.pi, 0, 0), 0.36, 0.06, 0.35, 4, rgb(55, 55, 65))
end
local function gearAt(m, at, r, teeth, t, color, light, dark)
	disc(m, r * 2, t, at, color)
	for k = 0, teeth - 1 do
		p(m, V(r * 0.5, r * 0.5, t), at * CFrame.Angles(0, 0, k * math.pi * 2 / teeth) * CF(0, r * 1.12, 0), color)
	end
	disc(m, r * 1.35, t + 0.1, at, light)
	disc(m, r * 0.55, t + 0.2, at, dark)
end
function B.gear(m)
	-- a steel gear with a raised ring and a hole, and a little orange one meshing with it
	gearAt(m, CF(-1.3, -1.35, 0.45) * CFrame.Angles(0, 0, math.rad(22)), 0.85, 6, 0.6, rgb(255, 160, 40), rgb(255, 200, 110), rgb(150, 80, 20))
	gearAt(m, CF(0.35, 0.35, 0), 1.55, 8, 0.8, rgb(175, 184, 205), rgb(215, 222, 238), rgb(55, 60, 80))
end
-- the Daily calendar, after tomas's reference (2026-09-27, Daily Gifts): a thick red studded top with
-- two rings through it, a white page with a big blocky 31 in navy, the pale blue pages under it
local DIGITS = {
	["3"] = { "###", "..#", "###", "..#", "###" },
	["1"] = { ".#.", "##.", ".#.", ".#.", "###" },
}
function B.calendar(m)
	local RED, REDD, PAPER, NAVY, SKY, RING = rgb(235, 60, 70), rgb(165, 30, 45), rgb(252, 252, 250), rgb(40, 62, 150), rgb(165, 205, 245), rgb(228, 232, 242)
	p(m, V(4.0, 3.0, 0.5), CF(0, -0.4, 0), PAPER)
	p(m, V(4.0, 0.42, 0.62), CF(0, -2.1, 0.02), SKY)
	studs(p(m, V(4.3, 1.2, 0.9), CF(0, 1.7, 0.05), RED))
	p(m, V(4.32, 0.18, 0.92), CF(0, 1.16, 0.05), REDD)
	-- the rings: loops standing up out of the top, front to back
	for _, x in { -1.1, 1.1 } do
		for _, z in { -0.28, 0.38 } do p(m, V(0.3, 0.8, 0.26), CF(x, 2.62, z), RING) end
		p(m, V(0.3, 0.26, 0.92), CF(x, 3.0, 0.05), RING)
	end
	-- 31, a pixel at a time (runs of pixels in a row as one part); screen-left is +X
	local PX, text = 0.44, "31"
	local cols = #text * 4 - 1
	for i = 1, #text do
		local glyph = DIGITS[text:sub(i, i)]
		for r, row in glyph do
			local c = 1
			while c <= #row do
				if row:sub(c, c) == "#" then
					local e = c
					while e < #row and row:sub(e + 1, e + 1) == "#" do e += 1 end
					local col0 = (i - 1) * 4 + (c - 1)
					local mid = col0 + (e - c + 1) / 2
					p(m, V((e - c + 1) * PX, PX, 0.14), CF(cols * PX / 2 - mid * PX, -0.4 + 2.5 * PX - (r - 0.5) * PX, -0.3), NAVY)
					c = e + 1
				else
					c += 1
				end
			end
		end
	end
end
function B.wrench(m)
	-- a spanner: an open end, a ring end with its hole, a blue grip with ridges
	local tilt = CFrame.Angles(0, 0, math.rad(-45))
	local S, SD = rgb(200, 207, 222), rgb(110, 116, 135)
	p(m, V(0.62, 3.2, 0.42), tilt, S)
	p(m, V(0.78, 1.5, 0.56), tilt * CF(0, -0.55, 0), rgb(60, 130, 255))
	for _, y in { -1.05, -0.55, -0.05 } do p(m, V(0.8, 0.1, 0.58), tilt * CF(0, y, 0), rgb(40, 95, 200)) end
	p(m, V(1.8, 0.7, 0.42), tilt * CF(0, 1.85, 0), S)
	for _, s in { -1, 1 } do
		p(m, V(0.55, 0.85, 0.42), tilt * CF(s * 0.62, 2.55, 0), S)
		disc(m, 0.55, 0.42, tilt * CF(s * 0.62, 2.98, 0), S)
	end
	disc(m, 1.35, 0.42, tilt * CF(0, -1.95, 0), S)
	disc(m, 0.62, 0.5, tilt * CF(0, -1.95, 0), SD)
end
local function kid(m, at, shirt, hair, pigtails)
	local SKIN = rgb(255, 214, 180)
	cylc(m, 1.6, 1.1, at * CF(0, -1.5, 0), shirt)
	ball(m, 1.6, (at * CF(0, -0.95, 0)).Position, shirt)
	ball(m, 1.7, (at * CF(0, 0.55, 0)).Position, SKIN)
	ball(m, 1.78, (at * CF(0, 0.75, 0.2)).Position, hair)
	if pigtails then
		for _, s in { -1, 1 } do ball(m, 0.65, (at * CF(s * 0.95, 0.55, 0.25)).Position, hair) end
	end
	for _, s in { -1, 1 } do
		ball(m, 0.26, (at * CF(s * 0.32, 0.5, -0.76)).Position, INK)
		ball(m, 0.28, (at * CF(s * 0.55, 0.22, -0.66)).Position, rgb(255, 165, 165))
	end
	p(m, V(0.26, 0.09, 0.1), at * CF(0, 0.13, -0.73), INK)
	for _, s in { -1, 1 } do p(m, V(0.16, 0.09, 0.1), at * CF(s * 0.18, 0.17, -0.71) * CFrame.Angles(0, 0, s * 0.5), INK) end
end
function B.people(m)
	-- two kids side by side (Co-op)
	kid(m, CF(-0.95, -0.15, 0.35) * CFrame.Angles(0, 0.25, 0), rgb(255, 110, 170), rgb(250, 200, 80), true)
	kid(m, CF(0.95, 0, -0.2) * CFrame.Angles(0, -0.25, 0), rgb(70, 150, 255), rgb(100, 65, 40), false)
end
function B.scroll(m)
	-- a quest scroll: parchment between two rolls with wooden knobs, the writing, a wax seal and ribbon
	local PARCH, ROLL, WOOD, INKL = rgb(250, 232, 190), rgb(238, 210, 155), rgb(150, 95, 50), rgb(165, 115, 70)
	p(m, V(3.0, 3.1, 0.14), CF(0, 0, 0), PARCH)
	for _, y in { 1.72, -1.72 } do
		cyl(m, 0.8, 3.3, V(0, y, 0), ROLL, "x")
		for _, s in { -1, 1 } do
			cyl(m, 0.42, 0.3, V(s * 1.8, y, 0), WOOD, "x")
			ball(m, 0.5, V(s * 2.05, y, 0), WOOD)
		end
	end
	-- (lined up on the left of the screen, which is +X)
	for k, w in { 2.2, 1.7, 2.2, 1.3 } do p(m, V(w, 0.16, 0.05), CF(1.1 - w / 2, 0.95 - (k - 1) * 0.45, -0.1), INKL) end
	for _, s in { -1, 1 } do p(m, V(0.24, 0.8, 0.05), CF(-0.75 + s * 0.2, -1.2, -0.14) * CFrame.Angles(0, 0, s * 0.3), rgb(200, 40, 55)) end
	disc(m, 0.85, 0.2, CF(-0.75, -0.8, -0.2), rgb(220, 45, 60))
	disc(m, 0.5, 0.22, CF(-0.75, -0.8, -0.22), rgb(170, 25, 40))
end

-- a top-secret VexCorp file (the Files book): the back with its tab, papers sticking out, the front
-- open a little with a TOP SECRET stamp and the VexCorp seal, a paper clip
function B.folder(m)
	local MAN, MANL = rgb(225, 172, 92), rgb(248, 205, 125)
	p(m, V(4.0, 2.9, 0.2), CF(0, -0.05, 0.2), MAN)
	p(m, V(1.5, 0.5, 0.2), CF(1.1, 1.6, 0.2), MAN)
	p(m, V(3.5, 2.6, 0.06), CF(-0.05, 0.25, 0.06) * CFrame.Angles(0, 0, math.rad(4)), rgb(245, 245, 240))
	p(m, V(3.5, 2.6, 0.06), CF(0.1, 0.35, -0.02) * CFrame.Angles(0, 0, math.rad(-3)), rgb(255, 255, 255))
	for k = 0, 1 do p(m, V(2.0 - k * 0.5, 0.1, 0.04), CF(0.45 + k * 0.25, 1.3 - k * 0.25, -0.06), rgb(150, 160, 180)) end
	local front = CF(0, -1.55, -0.14) * CFrame.Angles(math.rad(-10), 0, 0)
	p(m, V(4.1, 2.45, 0.2), front * CF(0, 1.22, 0), MANL)
	local stamp = front * CF(0, 1.25, -0.12) * CFrame.Angles(0, 0, math.rad(12))
	p(m, V(3.1, 0.7, 0.05), stamp, rgb(215, 40, 50))
	for k = -2, 2 do p(m, V(0.36, 0.2, 0.06), stamp * CF(k * 0.52, 0, -0.01), rgb(255, 235, 235)) end
	ball(m, 0.65, (front * CF(-1.3, 0.45, -0.15)).Position, rgb(140, 60, 210))
	p(m, V(0.18, 1.0, 0.08), CF(-1.25, 1.35, -0.2), rgb(200, 205, 215))
end

-- the keys the store uses for its passes and products (Config keys -> icon)
Icons.FOR = {
	StarterPack = "gift", VIP = "crown", SuperSpeed = "sneaker", GoldenBoard = "goldboard", DiamondBoard = "gem",
	Luck = "clover", AutoCollect = "broom", LongLock = "padlock", TeleportHome = "house", OfflinePlus = "moon",
	MoneyBoost = "cash", Cash10m = "cash", Cash1h = "moneybag", Cash4h = "vault", LuckyBus = "bus",
	Cash8h = "briefcase", Cash16h = "chest", Cash24h = "truck", Cash1w = "moneyMountain",
	ServerLuck = "sparkle", ExpressRare = "letter", ExpressEpic = "letterEpic", LockRefresh = "refresh",
}

-- how an icon is looked at, if not the usual (turn = its yaw, tilt = how far the camera looks down)
Icons.LOOK = {
	basket = { turn = -50, tilt = 16 },
	cash = { turn = -38, tilt = 30 },
	book = { turn = -28, tilt = 42 },
	calendar = { turn = -24, tilt = 14 },
}

-- the panels (by their names) -> icon
Icons.PANEL = {
	Shop = "basket", Upgrades = "upArrow", Board = "pillar", Prestige = "crown", Yearbook = "book",
	NameSchool = "pencil", Settings = "gear", Daily = "calendar", Admin = "wrench", Welcome = "cash",
	Coop = "people", QuestLogPanel = "scroll", Store = "gem", LeaveDeal = "moon",
}

function Icons.build(key)
	local m = Instance.new("Model")
	m.Name = "Icon_" .. tostring(key)
	;(B[key] or B.gift)(m)
	-- (turned and swayed about its own middle)
	local cf = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(cf.Position)
	return m
end

-- the ones on screen sway and bob (~30 times a second): the camera swings round the model, so one
-- CFrame write moves the icon and its outline together
local live = setmetatable({}, { __mode = "k" }) -- holder -> { cam, center, dist, pitch, phase, sway, bob }
local function shown(g)
	local a = g
	while a and a:IsA("GuiObject") do
		if not a.Visible then return false end
		a = a.Parent
	end
	if a and a:IsA("LayerCollector") and not a.Enabled then return false end
	return g.AbsoluteSize.X > 0
end
local function orbit(st, t)
	local a = t and math.sin(t * 1.3 + st.phase) * math.rad(st.sway) or 0
	local y = t and math.sin(t * 2 + st.phase) * st.bob or 0
	return CFrame.new(st.center - Vector3.new(0, y, 0)) * CFrame.Angles(0, -a, 0) * CFrame.Angles(st.pitch, 0, 0) * CFrame.new(0, 0, -st.dist) * CFrame.Angles(0, math.pi, 0)
end
local acc = 0
RunService.RenderStepped:Connect(function(dt)
	acc += dt
	if acc < 1 / 30 then return end
	acc = 0
	local t = os.clock()
	for holder, st in live do
		if not holder.Parent then
			live[holder] = nil
		elseif shown(holder) then
			st.cam.CFrame = orbit(st, t)
		end
	end
end)

-- opts: size, position, anchor, zindex (the outline's; the icon draws one above), sway (degrees,
-- default 18), bob (studs, default 0.12), turn (a fixed yaw in degrees, default -22), tilt (how far
-- the camera looks down on it, degrees, default 12), outline (default true), still (no motion)
local OUTLINE = rgb(22, 18, 32)
-- the framing: every part's corners as the camera sees them (turned, and looked down on), so one seen
-- from high up (the basket, the book) fits as snugly as one seen side on. -> its middle, the distance
local function fit(model, pitch)
	local rot = CFrame.Angles(pitch, 0, 0) * CFrame.Angles(0, math.pi, 0)
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local h = d.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local q = rot:PointToObjectSpace(d.CFrame:PointToWorldSpace(Vector3.new(sx * h.X, sy * h.Y, sz * h.Z)))
						lo, hi = lo:Min(q), hi:Max(q)
					end
				end
			end
		end
	end
	local mid = (lo + hi) / 2
	local r = math.max(hi.X - lo.X, hi.Y - lo.Y) * 0.5 + 0.45
	return rot:PointToWorldSpace(mid), r / math.tan(math.rad(15)) + (hi.Z - mid.Z)
end
local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 0.71, 0.71 }, { -0.71, 0.71 }, { 0.71, -0.71 }, { -0.71, -0.71 } }
function Icons.view(parent, key, opts)
	opts = opts or {}
	local z = opts.zindex or 14
	local holder = Instance.new("Frame")
	holder.Name = "Icon"
	holder.BackgroundTransparency = 1
	holder.Size = opts.size or UDim2.fromScale(1, 1)
	holder.Position = opts.position or UDim2.new()
	holder.AnchorPoint = opts.anchor or Vector2.zero
	holder.ZIndex = z
	local model = Icons.build(key)
	local look = Icons.LOOK[key] or {}
	local base = CFrame.Angles(0, math.rad(opts.turn or look.turn or -22), 0)
	model:PivotTo(base)
	local pitch = math.rad(opts.tilt or look.tilt or 12)
	local center, dist = fit(model, pitch)
	local st = {
		center = center,
		dist = dist,
		pitch = pitch,
		phase = math.random() * 6,
		sway = opts.sway or 18,
		bob = opts.bob or 0.12,
	}
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.CFrame = orbit(st)
	st.cam = cam
	local function layer(name, zi)
		local vp = Instance.new("ViewportFrame")
		vp.Name = name
		vp.BackgroundTransparency = 1
		vp.Size = UDim2.fromScale(1, 1)
		vp.ZIndex = zi
		vp.CurrentCamera = cam
		vp.Parent = holder
		return vp
	end
	-- the outline: eight copies, white under a white ambient and no light, the viewport tinting them
	-- to the outline colour (flat); each shifted across the camera's view (the camera only swings a
	-- few degrees, so they stay a near-even ring round the icon)
	local copies = {}
	if opts.outline ~= false then
		local vp = layer("Outline", z)
		vp.Ambient = Color3.new(1, 1, 1)
		vp.LightColor = Color3.new(0, 0, 0)
		vp.ImageColor3 = OUTLINE
		for i = 1, #DIRS do
			local copy = model:Clone()
			for _, d in copy:GetDescendants() do
				if d:IsA("BasePart") then
					d.Color = Color3.new(1, 1, 1)
					d.Material = Enum.Material.SmoothPlastic
					for _, f in { "TopSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface" } do d[f] = Enum.SurfaceType.Smooth end
				end
			end
			copy.Parent = vp
			copies[i] = copy
		end
	end
	-- the icon: a key light from the upper left, a soft fill, so its top, front and side read apart
	local main = layer("Model", z + 1)
	main.Ambient = rgb(150, 150, 158)
	main.LightColor = rgb(200, 196, 188)
	main.LightDirection = Vector3.new(-0.45, -1, 0.75)
	model.Parent = main
	cam.Parent = main
	-- the outline's thickness: 4.5% of the icon's shorter side (as a share of what the camera sees at
	-- the model's middle, so it grows and shrinks with the icon)
	local aspect
	local function place()
		local s = holder.AbsoluteSize
		if s.X < 1 or s.Y < 1 or #copies == 0 then return end
		local a = s.X / s.Y
		if aspect and math.abs(a - aspect) < 0.01 then return end
		aspect = a
		local h = 2 * st.dist * math.tan(math.rad(15))
		local k = math.min(h * a, h) * 0.045
		local rest = orbit(st)
		for i, copy in copies do
			copy:PivotTo(CFrame.new(rest.RightVector * DIRS[i][1] * k + rest.UpVector * DIRS[i][2] * k) * base)
		end
	end
	holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	holder.Parent = parent
	place()
	if not opts.still then live[holder] = st end
	return holder
end

return Icons
