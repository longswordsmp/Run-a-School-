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

---------------------------------------------------------------------------
-- the School Shop (tomas, 2026-09-27: "the things in school shop all are 2d and not good like how the
-- store is"): a model for everything it sells, in the same chunky outlined style
---------------------------------------------------------------------------
local WHITE, DARK = rgb(250, 250, 248), rgb(40, 44, 58)

-- School Supplies
function B.notebook(m)
	-- a spiral notebook: a red cover with a white label, the pages' edge, coils down its side
	local COVER, BACK, PAGE, COIL = rgb(235, 70, 80), rgb(170, 40, 55), rgb(250, 248, 238), rgb(170, 176, 192)
	p(m, V(3.2, 4.2, 0.46), CF(-0.1, 0, 0.05), PAGE)
	studs(p(m, V(3.4, 4.4, 0.2), CF(-0.1, 0, -0.3), COVER))
	p(m, V(3.4, 4.4, 0.16), CF(-0.1, 0, 0.36), BACK)
	p(m, V(2.1, 1.0, 0.06), CF(-0.3, 1.0, -0.42), WHITE)
	for k, w in { 1.5, 1.0 } do p(m, V(w, 0.14, 0.07), CF(-0.3 + (1.5 - w) / 2, 1.18 - (k - 1) * 0.34, -0.46), rgb(110, 120, 150)) end
	-- (the coils down the left of the screen, which is +X)
	for k = 0, 7 do
		cyl(m, 0.34, 1.0, V(1.72, -1.75 + k * 0.5, 0.03), COIL, "z")
	end
end
function B.crayons(m)
	-- a big yellow crayon box, its green band, five crayons standing up out of it with pointed tips
	local BOX, BAND = rgb(255, 205, 50), rgb(60, 170, 95)
	studs(p(m, V(4.2, 3.0, 1.6), CF(0, -0.9, 0), BOX))
	p(m, V(4.24, 0.9, 1.64), CF(0, -1.0, 0), BAND)
	p(m, V(2.2, 0.36, 1.66), CF(0, -1.0, 0), rgb(255, 245, 210))
	for i, c in { rgb(235, 60, 60), rgb(255, 150, 40), rgb(60, 140, 255), rgb(160, 80, 220), rgb(60, 200, 90) } do
		local x = -1.64 + (i - 1) * 0.82
		local h = 1.3 + (i % 2) * 0.45
		cylc(m, 0.66, h, CF(x, 0.6 + h / 2, -0.1), c)
		cylc(m, 0.7, 0.16, CF(x, 0.65 + h * 0.75, -0.1), c:Lerp(rgb(0, 0, 0), 0.35))
		cone(m, CF(x, 0.6 + h, -0.1), 0.66, 0.14, 0.75, 6, c)
	end
end
function B.books(m)
	-- a stack of three textbooks, spines to the front with gold bands, the pages white at the sides
	local y = -1.4
	for i, b in { { rgb(60, 120, 230), 4.4, 0.95, 3.1, 4 }, { rgb(235, 70, 80), 4.0, 0.85, 2.9, -7 }, { rgb(70, 190, 100), 3.6, 0.8, 2.7, 9 } } do
		local cf = CF(0, y + b[3] / 2, 0) * CFrame.Angles(0, math.rad(b[5]), 0)
		studs(p(m, V(b[2], b[3], b[4]), cf, b[1]))
		p(m, V(b[2] + 0.04, b[3] - 0.26, b[4] - 0.34), cf * CF(0, 0, 0.18), rgb(252, 250, 240))
		for _, dx in { -1, 1 } do p(m, V(0.16, b[3] + 0.02, 0.06), cf * CF(dx * (b[2] / 2 - 0.5), 0, -b[4] / 2 - 0.02), rgb(255, 210, 70)) end
		y += b[3]
	end
end
function B.ruler(m)
	-- a yellow ruler with its marks, leaning across a blue protractor
	local PRO = rgb(110, 190, 255)
	local r = 1.9
	for a = 0, 165, 15 do
		local t = math.rad(a + 7.5)
		p(m, V(0.52, 0.36, 0.22), CF(math.cos(t) * r, -0.6 + math.sin(t) * r, 0.35) * CFrame.Angles(0, 0, t + math.pi / 2), PRO)
	end
	p(m, V(2 * r + 0.36, 0.36, 0.22), CF(0, -0.6, 0.35), PRO)
	disc(m, 0.4, 0.24, CF(0, -0.6, 0.3), rgb(40, 90, 200))
	local tilt = CF(0, 0, -0.1) * CFrame.Angles(0, 0, math.rad(28))
	studs(p(m, V(5.4, 1.0, 0.28), tilt, rgb(255, 205, 60)))
	for k = 0, 11 do
		local long = k % 2 == 0
		p(m, V(0.09, long and 0.45 or 0.28, 0.06), tilt * CF(-2.45 + k * 0.445, 0.5 - (long and 0.225 or 0.14), -0.16), rgb(70, 55, 40))
	end
end
function B.calculator(m)
	-- a calculator: a navy body, a green screen with its digits, grey keys, an orange column
	local BODY = rgb(55, 65, 100)
	p(m, V(3.1, 4.4, 0.6), CF(), BODY)
	p(m, V(2.6, 1.05, 0.1), CF(0, 1.45, -0.32), rgb(165, 225, 160))
	for k = 0, 2 do p(m, V(0.36, 0.6, 0.06), CF(-0.95 + k * 0.5, 1.45, -0.39), rgb(40, 70, 45)) end
	for r = 0, 3 do
		for c = 0, 3 do
			-- (the right-hand column on screen is -X)
			local col = c == 3 and rgb(255, 150, 40) or rgb(230, 232, 240)
			p(m, V(0.56, 0.5, 0.16), CF(0.9 - c * 0.6, 0.35 - r * 0.62, -0.34), col)
		end
	end
end
function B.globe(m)
	-- a desk globe: the blue world with green land, a gold ring round it, on a stand
	local SEA, LAND, GOLDL = rgb(60, 145, 240), rgb(80, 200, 90), rgb(255, 200, 60)
	ball(m, 3.2, V(0, 0.7, 0), SEA)
	for _, c in { { 0.7, 1.4, -1.0, 1.3 }, { -0.9, 0.2, -1.1, 1.1 }, { 0.2, -0.3, -1.25, 0.9 }, { -0.4, 1.9, -0.6, 0.9 }, { 1.3, 0.3, -0.5, 1.0 } } do
		ball(m, c[4], V(c[1], 0.7 + c[2] - 0.7, c[3]), LAND)
	end
	local tilt = CFrame.Angles(0, 0, math.rad(-23))
	for a = -114, 114, 12 do
		local t = math.rad(a)
		p(m, V(0.46, 0.24, 0.26), CF(0, 0.7, 0) * tilt * CF(math.sin(t) * 1.9, math.cos(t) * 1.9, 0) * CFrame.Angles(0, 0, -t), GOLDL)
	end
	cylc(m, 0.35, 1.2, CF(0, -1.2, 0), GOLDL)
	cylc(m, 2.2, 0.4, CF(0, -1.9, 0), rgb(150, 95, 55))
end
function B.microscope(m)
	-- a microscope side on: its base, the curved arm, the stage, the tube leaning up with its eyepiece
	local BODY, DARKG = rgb(245, 245, 250), rgb(60, 64, 80)
	studs(p(m, V(3.0, 0.5, 2.0), CF(0, -2.1, 0), BODY))
	p(m, V(0.7, 2.6, 0.8), CF(-0.9, -0.7, 0.2) * CFrame.Angles(0, 0, math.rad(-8)), BODY)
	p(m, V(2.0, 0.22, 1.6), CF(0.25, -0.9, 0), DARKG)
	p(m, V(1.2, 0.12, 0.7), CF(0.25, -0.76, -0.2), rgb(150, 210, 255))
	local tube = CF(0.2, 0.9, 0) * CFrame.Angles(0, 0, math.rad(22))
	cylc(m, 0.8, 2.6, tube, BODY)
	cylc(m, 0.6, 0.9, tube * CF(0, 1.6, 0), DARKG)
	cylc(m, 0.55, 0.6, tube * CF(0, -1.45, 0), DARKG)
	p(m, V(1.2, 0.8, 0.8), CF(-0.55, 0.55, 0.1) * CFrame.Angles(0, 0, math.rad(22)), BODY)
	disc(m, 0.9, 0.3, CF(-1.0, -0.2, -0.45), DARKG)
end
function B.laptop(m)
	-- an open laptop: the silver deck with its keys, the screen up at the back glowing blue
	local SILVER, KEY = rgb(205, 210, 222), rgb(60, 64, 78)
	studs(p(m, V(4.4, 0.28, 3.0), CF(0, -1.3, -0.5), SILVER))
	for r = 0, 2 do
		for c = 0, 6 do p(m, V(0.46, 0.08, 0.42), CF(-1.62 + c * 0.54, -1.12, -1.2 + r * 0.52), KEY) end
	end
	p(m, V(1.2, 0.06, 0.6), CF(0, -1.14, -1.75), rgb(175, 180, 195))
	local scr = CF(0, 0.15, 1.0) * CFrame.Angles(math.rad(-14), 0, 0)
	p(m, V(4.4, 3.0, 0.2), scr, SILVER)
	p(m, V(3.9, 2.5, 0.06), scr * CF(0, 0, -0.12), rgb(70, 150, 255))
	for k, w in { 2.6, 1.8, 2.2 } do p(m, V(w, 0.28, 0.06), scr * CF((2.6 - w) / 2, 0.6 - (k - 1) * 0.55, -0.16), rgb(220, 240, 255)) end
end
function B.tablet(m)
	-- a tablet standing up: a dark frame, a screen full of bright app tiles
	p(m, V(3.4, 4.4, 0.3), CF(), DARK)
	p(m, V(3.0, 3.9, 0.06), CF(0, 0.05, -0.17), rgb(120, 200, 255))
	local cols = { rgb(255, 90, 90), rgb(255, 200, 60), rgb(90, 210, 110), rgb(160, 110, 255), rgb(255, 140, 60), rgb(80, 170, 255) }
	for r = 0, 3 do
		for c = 0, 2 do p(m, V(0.66, 0.66, 0.08), CF(0.9 - c * 0.9, 1.3 - r * 0.88, -0.2), cols[(r * 3 + c) % #cols + 1]) end
	end
	disc(m, 0.2, 0.08, CF(0, 2.02, -0.17), rgb(90, 95, 110))
end
function B.smartboard(m)
	-- a smartboard on its stand: a white frame, a screen with a bar chart, a pen tray, wheels
	local FRAME = rgb(235, 238, 245)
	p(m, V(5.2, 3.2, 0.3), CF(0, 0.8, 0), FRAME)
	p(m, V(4.7, 2.7, 0.06), CF(0, 0.8, -0.17), rgb(40, 60, 110))
	for k, h in { 0.8, 1.4, 1.1, 1.9 } do
		p(m, V(0.6, h, 0.08), CF(1.5 - (k - 1) * 1.0, -0.4 + h / 2, -0.21), ({ rgb(255, 90, 90), rgb(255, 200, 60), rgb(90, 210, 110), rgb(80, 170, 255) })[k])
	end
	p(m, V(3.0, 0.2, 0.6), CF(0, -0.85, -0.3), FRAME)
	for _, x in { -1.9, 1.9 } do
		p(m, V(0.3, 2.0, 0.3), CF(x, -1.8, 0), rgb(150, 155, 170))
		p(m, V(0.3, 0.3, 1.6), CF(x, -2.75, 0), rgb(150, 155, 170))
		disc(m, 0.4, 0.3, CF(x, -2.95, -0.7), DARK)
	end
end
function B.vr(m)
	-- a VR headset: a wide white body, its glossy black visor with a blue light strip, the grey strap
	-- looping round behind (seen from above, so the loop shows)
	local BODY, STRAP = rgb(245, 245, 250), rgb(90, 95, 110)
	studs(p(m, V(4.2, 1.8, 1.3), CF(), BODY))
	p(m, V(3.9, 1.5, 0.2), CF(0, 0, -0.72), rgb(25, 28, 38))
	p(m, V(3.0, 0.16, 0.06), CF(0, -0.35, -0.84), rgb(90, 200, 255), nil, Enum.Material.Neon)
	p(m, V(3.6, 1.4, 0.3), CF(0, 0, 0.78), rgb(70, 74, 88))
	for _, dx in { -1, 1 } do p(m, V(0.28, 0.6, 2.8), CF(dx * 2.0, 0.1, 2.1), STRAP) end
	p(m, V(4.28, 0.6, 0.28), CF(0, 0.1, 3.4), STRAP)
	p(m, V(0.6, 0.28, 2.8), CF(0, 0.95, 2.1), STRAP)
end
function B.robot(m)
	-- a robot tutor: a round-cornered head with a screen face (eyes, a smile), an antenna, a body with
	-- a heart light, little arms, glasses
	local BODY, SCREEN = rgb(120, 190, 255), rgb(30, 40, 70)
	p(m, V(3.0, 2.4, 2.2), CF(0, 0.9, 0), BODY)
	p(m, V(2.5, 1.8, 0.1), CF(0, 0.9, -1.12), SCREEN)
	for _, dx in { -0.6, 0.6 } do
		disc(m, 0.5, 0.08, CF(dx, 1.2, -1.2), rgb(120, 255, 200), Enum.Material.Neon)
		p(m, V(0.8, 0.1, 0.06), CF(dx, 1.62, -1.2), rgb(255, 210, 70))
	end
	p(m, V(0.9, 0.14, 0.06), CF(0, 0.6, -1.2), rgb(120, 255, 200), nil, Enum.Material.Neon)
	cylc(m, 0.2, 0.9, CF(0, 2.5, 0), rgb(200, 205, 220))
	ball(m, 0.55, V(0, 3.0, 0), rgb(255, 80, 90), Enum.Material.Neon)
	studs(p(m, V(2.4, 1.8, 1.8), CF(0, -1.3, 0), BODY:Lerp(rgb(0, 0, 0), 0.12)))
	ball(m, 0.6, V(0, -1.1, -0.9), rgb(255, 90, 120), Enum.Material.Neon)
	for _, dx in { -1, 1 } do p(m, V(0.5, 1.3, 0.5), CF(dx * 1.5, -1.3, 0) * CFrame.Angles(0, 0, dx * math.rad(15)), rgb(200, 205, 220)) end
end
function B.holodesk(m)
	-- a hologram desk: a white desk, a projector on it, a cone of light, a glowing cube floating in it
	local HOLO = rgb(90, 230, 255)
	studs(p(m, V(4.4, 0.3, 2.2), CF(0, -1.2, 0), WHITE))
	for _, dx in { -1.9, 1.9 } do p(m, V(0.3, 1.5, 1.8), CF(dx, -2.1, 0), rgb(200, 205, 220)) end
	cylc(m, 1.0, 0.25, CF(0, -0.95, 0), DARK)
	local light = cone(m, CF(0, -0.85, 0), 0.9, 2.4, 1.6, 6, HOLO)
	for _, d in m:GetChildren() do
		if d.Position.Y > -0.9 and d.Position.Y < 0.8 and d.Color == HOLO then d.Material = Enum.Material.Neon d.Transparency = 0.55 end
	end
	local cube = CF(0, 1.5, 0) * CFrame.Angles(math.rad(35), math.rad(45), 0)
	local e = 1.3
	for _, a in { { V(e, 0.14, 0.14), { { 0, 1, 1 }, { 0, 1, -1 }, { 0, -1, 1 }, { 0, -1, -1 } } }, { V(0.14, e, 0.14), { { 1, 0, 1 }, { 1, 0, -1 }, { -1, 0, 1 }, { -1, 0, -1 } } }, { V(0.14, 0.14, e), { { 1, 1, 0 }, { 1, -1, 0 }, { -1, 1, 0 }, { -1, -1, 0 } } } } do
		for _, o in a[2] do p(m, a[1], cube * CF(o[1] * e / 2, o[2] * e / 2, o[3] * e / 2), HOLO, nil, Enum.Material.Neon) end
	end
	ball(m, 0.5, (cube).Position, rgb(200, 250, 255), Enum.Material.Neon)
end
function B.quantum(m)
	-- a quantum computer: three gold tiers hanging one under the next on rods, a glowing core below
	local GOLDL, GOLDD = rgb(255, 205, 70), rgb(215, 150, 30)
	local tiers = { { 3.8, 1.9 }, { 3.0, 0.6 }, { 2.2, -0.7 } }
	for i, t in tiers do
		cylc(m, t[1], 0.3, CF(0, t[2], 0), GOLDL, Enum.Material.Metal)
		cylc(m, t[1] - 0.4, 0.34, CF(0, t[2], 0), GOLDD, Enum.Material.Metal)
		if i < #tiers then
			for k = 0, 5 do
				local a = k / 6 * math.pi * 2
				local r = tiers[i + 1][1] / 2 - 0.25
				cylc(m, 0.16, t[2] - tiers[i + 1][2], CF(math.cos(a) * r, (t[2] + tiers[i + 1][2]) / 2, math.sin(a) * r), rgb(220, 150, 60), Enum.Material.Metal)
			end
		end
	end
	cylc(m, 0.4, 1.0, CF(0, 2.5, 0), GOLDD, Enum.Material.Metal)
	cylc(m, 0.5, 0.9, CF(0, -1.25, 0), GOLDD, Enum.Material.Metal)
	ball(m, 1.1, V(0, -1.9, 0), rgb(110, 230, 255), Enum.Material.Neon)
end
function B.thinkingcap(m)
	-- a propeller beanie: a red dome, a yellow band, a blue peak, a propeller turning on top
	ball(m, 3.4, V(0, 0, 0), rgb(235, 65, 75))
	cylc(m, 3.5, 0.9, CF(0, -0.95, 0), rgb(255, 205, 60))
	p(m, V(2.6, 0.22, 1.5), CF(0, -1.6, -1.9) * CFrame.Angles(math.rad(-8), 0, 0), rgb(60, 130, 240))
	cylc(m, 0.2, 0.7, CF(0, 1.95, 0), rgb(200, 205, 220))
	ball(m, 0.4, V(0, 2.3, 0), rgb(255, 205, 60))
	local prop = CF(0, 2.35, 0) * CFrame.Angles(0, math.rad(20), 0)
	for _, s in { -1, 1 } do p(m, V(1.9, 0.14, 0.7), prop * CF(s * 1.05, 0, 0) * CFrame.Angles(s * math.rad(28), 0, 0), s > 0 and rgb(60, 200, 110) or rgb(60, 130, 240)) end
end

-- School Builder
function B.curtains(m)
	-- a window with its curtains tied back, a pot with a red flower on the sill
	local FRAME, GLASS, CURT = rgb(250, 250, 248), rgb(150, 210, 255), rgb(235, 70, 90)
	studs(p(m, V(4.0, 4.2, 0.4), CF(0, 0.3, 0.2), FRAME))
	p(m, V(3.3, 3.5, 0.1), CF(0, 0.3, -0.02), GLASS)
	p(m, V(0.2, 3.5, 0.14), CF(0, 0.3, -0.05), FRAME)
	p(m, V(3.3, 0.2, 0.14), CF(0, 0.3, -0.05), FRAME)
	for _, s in { -1, 1 } do
		p(m, V(1.0, 3.6, 0.2), CF(s * 1.4, 0.35, -0.25), CURT)
		p(m, V(1.1, 0.3, 0.26), CF(s * 1.4, 0.0, -0.3), rgb(255, 205, 60))
	end
	p(m, V(4.0, 0.6, 0.3), CF(0, 2.2, -0.25), CURT:Lerp(WHITE, 0.2))
	p(m, V(4.4, 0.3, 1.0), CF(0, -1.9, -0.4), FRAME)
	cylc(m, 0.9, 0.8, CF(0.6, -1.35, -0.5), rgb(200, 100, 60))
	cylc(m, 0.12, 0.7, CF(0.6, -0.7, -0.5), rgb(60, 150, 60))
	ball(m, 0.8, V(0.6, -0.25, -0.5), rgb(230, 40, 60))
end
local function flower(m, at, color)
	cylc(m, 0.16, 1.4, at * CF(0, 0.7, 0), rgb(60, 160, 70))
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		ball(m, 0.55, (at * CF(math.cos(a) * 0.36, 1.5, math.sin(a) * 0.36)).Position, color)
	end
	ball(m, 0.4, (at * CF(0, 1.55, 0)).Position, rgb(255, 210, 60))
end
function B.flowerbed(m)
	-- a wooden planter full of soil with tulips and daisies in it
	local WOOD = rgb(170, 110, 60)
	studs(p(m, V(4.6, 1.2, 2.0), CF(0, -1.4, 0), WOOD))
	p(m, V(4.3, 0.2, 1.7), CF(0, -0.75, 0), rgb(95, 60, 40))
	for i, c in { rgb(235, 60, 90), rgb(255, 150, 200), rgb(250, 250, 250), rgb(255, 150, 40), rgb(170, 90, 230) } do
		flower(m, CF(-1.7 + (i - 1) * 0.85, -0.8, (i % 2 == 0) and 0.35 or -0.3), c)
	end
end
function B.awning(m)
	-- a striped awning over a door, a welcome mat under it
	local DOOR, WALL = rgb(60, 130, 230), rgb(240, 200, 150)
	studs(p(m, V(4.6, 4.6, 0.4), CF(0, 0, 0.5), WALL))
	p(m, V(2.0, 3.2, 0.2), CF(0, -0.7, 0.25), DOOR)
	ball(m, 0.3, V(-0.65, -0.8, 0.1), rgb(255, 210, 60))
	for i = -3, 3 do
		local c = i % 2 == 0 and WHITE or rgb(235, 60, 80)
		p(m, V(0.64, 0.2, 1.8), CF(i * 0.62, 1.45, -0.5) * CFrame.Angles(math.rad(-22), 0, 0), c)
		p(m, V(0.64, 0.4, 0.14), CF(i * 0.62, 1.05, -1.35), c)
	end
	p(m, V(2.6, 0.12, 1.0), CF(0, -2.3, -0.6), rgb(235, 60, 80))
end
function B.fence(m)
	-- a white picket fence: pointed pickets on two rails
	for i = 0, 5 do
		local x = -2.25 + i * 0.9
		p(m, V(0.6, 3.0, 0.24), CF(x, -0.4, 0), WHITE)
		tri(m, 0.6, 0.5, 0.24, CF(x, 1.35, 0), WHITE)
	end
	for _, y in { -1.2, 0.4 } do studs(p(m, V(5.4, 0.4, 0.26), CF(0, y, 0.24), rgb(230, 230, 226))) end
end
function B.marquee(m)
	-- a letter board on two posts: black board, white letters, bulbs along the top
	for _, x in { -1.8, 1.8 } do p(m, V(0.4, 4.6, 0.4), CF(x, -0.6, 0), rgb(60, 60, 70)) end
	studs(p(m, V(4.6, 2.8, 0.5), CF(0, 0.6, 0), rgb(40, 90, 200)))
	p(m, V(4.0, 2.2, 0.1), CF(0, 0.6, -0.28), rgb(20, 20, 26))
	for r = 0, 1 do
		for c = 0, 4 - r do p(m, V(0.5, 0.6, 0.06), CF(1.35 - c * 0.66 - r * 0.33, 1.05 - r * 0.85, -0.35), WHITE) end
	end
	for i = 0, 5 do ball(m, 0.34, V(-1.9 + i * 0.76, 2.1, -0.1), rgb(255, 235, 150), Enum.Material.Neon) end
end
function B.brickwall(m)
	-- a low brick wall with a white cap: staggered bricks with mortar showing between
	local BRICK, MORTAR = rgb(195, 85, 60), rgb(230, 220, 205)
	p(m, V(5.0, 2.9, 0.9), CF(0, -0.55, 0.05), MORTAR)
	for r = 0, 3 do
		local off = (r % 2) * 0.6
		for c = -1, 4 do
			local x = -2.2 + c * 1.2 + off
			local x0, x1 = math.max(x - 0.55, -2.5), math.min(x + 0.55, 2.5)
			if x1 - x0 > 0.2 then p(m, V(x1 - x0, 0.6, 0.96), CF((x0 + x1) / 2, -1.65 + r * 0.72, 0), BRICK) end
		end
	end
	studs(p(m, V(5.4, 0.45, 1.3), CF(0, 1.1, 0), WHITE))
end
function B.lockers(m)
	-- three school lockers side by side: vents, handles, a big letter on the middle one
	for i = -1, 1 do
		local c = i == 0 and rgb(235, 70, 80) or rgb(60, 130, 230)
		studs(p(m, V(1.4, 4.6, 1.2), CF(i * 1.45, 0, 0), c))
		for k = 0, 2 do p(m, V(0.9, 0.1, 0.06), CF(i * 1.45, 1.8 - k * 0.22, -0.62), c:Lerp(rgb(0, 0, 0), 0.4)) end
		p(m, V(0.16, 0.6, 0.16), CF(i * 1.45 - 0.45, 0, -0.66), rgb(210, 214, 225))
	end
	star5(m, CF(0, 0.6, -0.66), 0.32, rgb(255, 215, 70), 0.08)
end
function B.lunchtable(m)
	-- a lunch table: an orange top on white legs, benches either side, a tray with an apple and milk
	studs(p(m, V(4.8, 0.3, 2.4), CF(0, 0, 0), rgb(255, 150, 60)))
	for _, x in { -1.9, 1.9 } do p(m, V(0.3, 1.8, 2.0), CF(x, -1.05, 0), rgb(220, 224, 232)) end
	for _, z in { -1.9, 1.9 } do p(m, V(4.4, 0.3, 0.8), CF(0, -1.0, z), rgb(60, 130, 230)) end
	p(m, V(2.0, 0.12, 1.3), CF(0.3, 0.2, -0.1), rgb(200, 205, 220))
	ball(m, 0.7, V(0.8, 0.6, -0.1), rgb(230, 50, 60))
	p(m, V(0.5, 0.8, 0.5), CF(-0.2, 0.66, 0.1), WHITE)
	p(m, V(0.52, 0.3, 0.52), CF(-0.2, 0.55, 0.1), rgb(70, 150, 255))
end
function B.archwindow(m)
	-- an arched window with blue shutters open either side
	local FRAME, GLASS, SHUT = rgb(250, 250, 248), rgb(150, 210, 255), rgb(60, 110, 200)
	studs(p(m, V(3.0, 3.6, 0.4), CF(0, -0.6, 0), FRAME))
	p(m, V(2.4, 3.0, 0.1), CF(0, -0.6, -0.22), GLASS)
	disc(m, 3.0, 0.4, CF(0, 1.2, 0), FRAME)
	disc(m, 2.4, 0.1, CF(0, 1.2, -0.22), GLASS)
	p(m, V(0.2, 4.2, 0.14), CF(0, -0.3, -0.27), FRAME)
	for _, s in { -1, 1 } do
		p(m, V(1.2, 3.6, 0.2), CF(s * 2.2, -0.6, -0.1), SHUT)
		for k = 0, 5 do p(m, V(1.0, 0.1, 0.08), CF(s * 2.2, 0.8 - k * 0.55, -0.24), SHUT:Lerp(rgb(0, 0, 0), 0.3)) end
	end
end
function B.stainedglass(m)
	-- a pointed stained-glass window: bright panes in a dark frame
	local cols = { rgb(235, 60, 70), rgb(255, 200, 50), rgb(60, 140, 255), rgb(70, 200, 100), rgb(170, 90, 230), rgb(255, 140, 50) }
	p(m, V(3.2, 3.6, 0.3), CF(0, -0.8, 0.05), rgb(60, 60, 70))
	tri(m, 3.2, 1.8, 0.3, CF(0, 1.9, 0.05), rgb(60, 60, 70))
	for r = 0, 2 do
		for c = 0, 2 do p(m, V(0.9, 1.0, 0.1), CF(-1.0 + c * 1.0, -2.0 + r * 1.1, -0.14), cols[(r * 3 + c) % #cols + 1], nil, Enum.Material.Neon) end
	end
	tri(m, 2.4, 1.3, 0.1, CF(0, 1.75, -0.14), cols[5], Enum.Material.Neon)
	disc(m, 0.9, 0.12, CF(0, 1.3, -0.16), cols[2], Enum.Material.Neon)
end
function B.lamppost(m)
	-- a black lamp post with a glowing round lamp on top
	cylc(m, 1.2, 0.4, CF(0, -2.2, 0), rgb(40, 40, 48))
	cylc(m, 0.36, 4.0, CF(0, -0.2, 0), rgb(40, 40, 48))
	p(m, V(1.4, 0.3, 1.4), CF(0, 1.9, 0), rgb(40, 40, 48))
	p(m, V(1.1, 1.3, 1.1), CF(0, 2.7, 0), rgb(255, 235, 150), nil, Enum.Material.Neon)
	for _, dx in { -1, 1 } do for _, dz in { -1, 1 } do p(m, V(0.14, 1.3, 0.14), CF(dx * 0.6, 2.7, dz * 0.6), rgb(40, 40, 48)) end end
	cone(m, CF(0, 3.35, 0), 1.7, 0.3, 0.7, 4, rgb(40, 40, 48))
end
function B.windowbox(m)
	-- a window box under a window, full of flowers
	studs(p(m, V(4.0, 3.0, 0.4), CF(0, 0.9, 0.3), rgb(240, 200, 150)))
	p(m, V(2.8, 2.2, 0.1), CF(0, 1.0, 0.08), rgb(150, 210, 255))
	p(m, V(4.4, 1.0, 1.2), CF(0, -0.9, -0.4), rgb(60, 150, 90))
	for i, c in { rgb(255, 120, 180), rgb(255, 210, 60), rgb(250, 250, 250), rgb(235, 60, 90) } do
		flower(m, CF(-1.5 + (i - 1) * 1.0, -1.4, -0.4) * CFrame.new(0, 0, 0), c)
	end
end
function B.slide(m)
	-- a playground slide: a red ladder tower, a yellow slide curving down, a little blue roof
	local RED, YEL = rgb(235, 60, 60), rgb(255, 205, 50)
	for _, x in { -1.9, -0.7 } do for _, z in { -0.6, 0.6 } do p(m, V(0.3, 3.8, 0.3), CF(x, -0.4, z), RED) end end
	studs(p(m, V(1.6, 0.3, 1.5), CF(-1.3, 0.8, 0), RED))
	tri(m, 2.0, 1.1, 1.8, CF(-1.3, 2.4, 0), rgb(60, 130, 240))
	p(m, V(1.8, 0.2, 1.7), CF(-1.3, 1.85, 0), rgb(60, 130, 240))
	for k = 0, 3 do p(m, V(0.1, 0.1, 1.2), CF(-2.0, -1.8 + k * 0.7, 0), RED) end
	wedge(m, V(1.2, 3.0, 3.4), CF(0.8, -0.7, 0) * CFrame.Angles(0, math.rad(90), 0), YEL)
end
function B.vending(m)
	-- a vending machine: a red body, a window full of cans, a coin slot, the tray
	local BODY = rgb(230, 60, 70)
	studs(p(m, V(3.2, 5.0, 2.0), CF(), BODY))
	p(m, V(2.1, 3.6, 0.1), CF(0.35, 0.4, -1.02), rgb(170, 220, 255))
	local cans = { rgb(255, 200, 50), rgb(60, 140, 255), rgb(90, 210, 110), rgb(255, 120, 60) }
	for r = 0, 3 do for c = 0, 2 do
		cylc(m, 0.46, 0.6, CF(1.0 - c * 0.65, 1.7 - r * 0.85, -0.85), cans[(r + c) % 4 + 1])
	end end
	p(m, V(0.6, 1.0, 0.1), CF(-1.2, 0.6, -1.02), rgb(40, 40, 50))
	p(m, V(2.4, 0.5, 0.1), CF(0, -1.9, -1.02), rgb(30, 30, 38))
end
function B.basketball(m)
	-- a hoop: a white backboard on a pole, the orange rim and its net, a ball
	local ORANGE = rgb(255, 130, 40)
	cylc(m, 0.4, 4.2, CF(0.8, -0.9, 0.9), rgb(60, 64, 78))
	studs(p(m, V(3.4, 2.2, 0.2), CF(0, 1.5, 0.3), WHITE))
	p(m, V(1.3, 0.9, 0.06), CF(0, 1.2, 0.18), ORANGE)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		p(m, V(0.3, 0.1, 0.1), CF(math.cos(a) * 0.62, 0.5, -0.5 + math.sin(a) * 0.62) * CFrame.Angles(0, -a, 0), ORANGE)
	end
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		p(m, V(0.06, 0.8, 0.06), CF(math.cos(a) * 0.45, 0.05, -0.5 + math.sin(a) * 0.45), WHITE)
	end
	ball(m, 1.3, V(-1.3, -1.6, -0.6), ORANGE)
end
function B.carrot(m)
	-- a carrot with its green top, pulled from the school garden, and a mound of soil
	p(m, V(3.4, 0.5, 2.0), CF(0, -2.0, 0), rgb(110, 70, 45))
	local tilt = CF(0, 0, 0) * CFrame.Angles(0, 0, math.rad(-30))
	cone(m, tilt * CF(0, 1.0, 0) * CFrame.Angles(math.pi, 0, 0), 1.4, 0.2, 3.2, 8, rgb(255, 140, 40))
	for k = -1, 1 do p(m, V(0.3, 1.6, 0.3), tilt * CF(k * 0.3, 1.8, 0) * CFrame.Angles(0, 0, k * math.rad(22)), rgb(70, 190, 80)) end
end
function B.bleachers(m)
	-- three rows of blue and white bleacher seats stepping up
	for r = 0, 2 do
		studs(p(m, V(4.6, 0.8, 1.0), CF(0, -1.6 + r * 0.9, -1.0 + r * 1.0), r % 2 == 0 and rgb(60, 130, 230) or WHITE))
		p(m, V(4.4, 0.9 * (r + 1), 0.2), CF(0, -2.0 + r * 0.45, -0.5 + r * 1.0), rgb(170, 176, 192))
	end
end
function B.fountain(m)
	-- a round stone fountain: basin, a bowl up on a column, water spraying from the top
	local STONE, WATER = rgb(215, 215, 225), rgb(90, 190, 255)
	cylc(m, 4.6, 1.0, CF(0, -1.9, 0), STONE)
	cylc(m, 4.0, 0.2, CF(0, -1.35, 0), WATER)
	cylc(m, 0.6, 1.8, CF(0, -0.5, 0), STONE)
	cylc(m, 2.2, 0.5, CF(0, 0.5, 0), STONE)
	cylc(m, 1.8, 0.14, CF(0, 0.76, 0), WATER)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		p(m, V(0.18, 1.3, 0.18), CF(math.cos(a) * 0.5, 1.4, math.sin(a) * 0.5) * CFrame.Angles(math.sin(a) * 0.5, 0, -math.cos(a) * 0.5), WATER, nil, Enum.Material.Neon)
	end
	ball(m, 0.5, V(0, 1.9, 0), WATER, Enum.Material.Neon)
end
function B.banner(m)
	-- a flag pole with a school banner: a big star on it
	cylc(m, 0.26, 5.4, CF(-1.6, 0, 0), rgb(200, 205, 220))
	ball(m, 0.5, V(-1.6, 2.8, 0), rgb(255, 210, 60))
	studs(p(m, V(3.0, 2.0, 0.16), CF(0, 1.4, 0), rgb(40, 90, 200)))
	p(m, V(3.0, 0.3, 0.18), CF(0, 0.55, 0), rgb(255, 210, 60))
	star5(m, CF(0.1, 1.5, -0.12), 0.34, rgb(255, 210, 60), 0.06)
	p(m, V(1.6, 0.4, 0.4), CF(-1.6, -2.7, 0), rgb(120, 125, 140))
end
function B.statue(m)
	-- the founder's statue: a stone figure on a plinth, holding up a book
	local STONE = rgb(200, 200, 210)
	studs(p(m, V(2.6, 1.6, 2.6), CF(0, -2.0, 0), rgb(170, 170, 182)))
	p(m, V(2.2, 0.3, 2.2), CF(0, -1.05, 0), rgb(255, 210, 60))
	p(m, V(1.4, 1.8, 0.9), CF(0, 0.0, 0), STONE)
	p(m, V(1.4, 0.9, 0.9), CF(0, -0.9, 0), STONE:Lerp(rgb(0, 0, 0), 0.08))
	ball(m, 1.2, V(0, 1.5, 0), STONE)
	p(m, V(0.45, 1.4, 0.45), CF(0.95, 1.2, 0) * CFrame.Angles(0, 0, math.rad(-20)), STONE)
	p(m, V(0.9, 1.1, 0.25), CF(1.25, 2.15, 0), rgb(160, 110, 60))
	p(m, V(0.45, 1.2, 0.45), CF(-0.9, -0.1, 0), STONE)
end
function B.irongate(m)
	-- iron gates: black bars, gold spear tips, stone pillars with lamps
	for _, s in { -1, 1 } do
		studs(p(m, V(1.1, 4.8, 1.1), CF(s * 2.4, -0.2, 0), rgb(200, 195, 185)))
		ball(m, 0.7, V(s * 2.4, 2.6, 0), rgb(255, 235, 150), Enum.Material.Neon)
	end
	for i = 0, 6 do
		local x = -1.5 + i * 0.5
		p(m, V(0.18, 4.0, 0.18), CF(x, -0.4, 0), rgb(35, 35, 42), nil, Enum.Material.Metal)
		cone(m, CF(x, 1.6, 0), 0.34, 0.04, 0.5, 3, rgb(255, 205, 60))
	end
	for _, y in { -1.9, 0.9 } do p(m, V(3.8, 0.2, 0.2), CF(0, y, 0), rgb(35, 35, 42), nil, Enum.Material.Metal) end
end
function B.solar(m)
	-- a solar panel tilted to the sun on its stand, and the sun
	local panel = CF(0, -0.4, 0) * CFrame.Angles(math.rad(-35), 0, 0)
	p(m, V(4.4, 2.8, 0.2), panel, rgb(200, 205, 220))
	for r = 0, 2 do for c = 0, 3 do
		p(m, V(0.95, 0.78, 0.06), panel * CF(-1.5 + c * 1.0, -0.85 + r * 0.85, -0.12), rgb(40, 80, 170))
	end end
	p(m, V(0.4, 1.8, 0.4), CF(0, -1.9, 0.4), rgb(120, 125, 140))
	ball(m, 1.4, V(1.7, 1.9, 0.6), rgb(255, 205, 50), Enum.Material.Neon)
end
function B.bell(m)
	-- a brass school bell hanging in its little tower frame: a round dome, a flared lip, the clapper
	local BRASS, BRASS_D = rgb(240, 185, 60), rgb(200, 140, 40)
	for _, x in { -1.8, 1.8 } do p(m, V(0.5, 4.4, 0.5), CF(x, -0.4, 0), rgb(160, 110, 60)) end
	p(m, V(4.2, 0.4, 0.8), CF(0, 1.4, 0), rgb(160, 110, 60))
	studs(p(m, V(4.6, 0.4, 1.4), CF(0, 1.9, 0), rgb(200, 70, 60)))
	tri(m, 4.8, 1.2, 1.5, CF(0, 2.7, 0), rgb(200, 70, 60))
	cylc(m, 0.3, 0.5, CF(0, 1.0, 0), BRASS_D)
	ball(m, 1.7, V(0, 0.35, 0), BRASS)
	cylc(m, 1.7, 1.1, CF(0, -0.2, 0), BRASS)
	cone(m, CF(0, -0.75, 0), 1.7, 2.7, 0.6, 3, BRASS)
	cylc(m, 2.8, 0.2, CF(0, -1.4, 0), BRASS_D)
	ball(m, 0.6, V(0, -1.6, 0), rgb(110, 80, 45))
end

-- Janitor Stan's candy
function B.jawbreaker(m)
	-- a big striped jawbreaker in a wrapper twisted at both ends
	ball(m, 3.0, V(0, 0, 0), rgb(255, 90, 140))
	for k = 0, 3 do
		p(m, V(0.4, 3.02, 3.02), CF(0, 0, 0) * CFrame.Angles(0, k * math.pi / 4, 0), rgb(255, 255, 255), Enum.PartType.Cylinder)
	end
	for _, s in { -1, 1 } do cone(m, CF(s * 1.3, 0, 0) * CFrame.Angles(0, 0, s * -math.pi / 2), 0.4, 1.6, 1.0, 4, rgb(120, 200, 255)) end
end
function B.lollipop(m)
	-- a giant swirly lollipop on a white stick
	cylc(m, 0.3, 3.4, CF(0, -1.8, 0), WHITE)
	disc(m, 3.2, 0.5, CF(0, 0.9, 0), rgb(255, 90, 150))
	for k, c in { rgb(255, 220, 90), rgb(120, 200, 255), rgb(255, 255, 255), rgb(140, 230, 120) } do
		disc(m, 3.2 - k * 0.62, 0.52 + k * 0.02, CF(0, 0.9, 0), c)
	end
	disc(m, 0.4, 0.66, CF(0, 0.9, 0), rgb(255, 90, 150))
	p(m, V(0.3, 0.8, 0.1), CF(-0.7, 1.9, -0.3) * CFrame.Angles(0, 0, math.rad(35)), rgb(255, 255, 255))
end
function B.gumball(m)
	-- a gumball machine: a glass bowl full of gumballs on a red stand with its coin knob
	local RED = rgb(230, 50, 60)
	for i = 0, 17 do
		local a, h = i * 2.4, (i % 5) / 5
		ball(m, 0.7, V(math.cos(a) * 0.8 * (1 - h * 0.4), 0.2 + h * 1.6, math.sin(a) * 0.8 * (1 - h * 0.4)), ({ rgb(255, 90, 90), rgb(255, 210, 60), rgb(90, 180, 255), rgb(120, 220, 120), rgb(255, 140, 220) })[i % 5 + 1])
	end
	local glass = ball(m, 3.0, V(0, 0.9, 0), rgb(220, 240, 255))
	glass.Transparency = 0.6
	cylc(m, 1.0, 0.4, CF(0, 2.5, 0), RED)
	studs(p(m, V(2.2, 2.0, 2.2), CF(0, -1.5, 0), RED))
	disc(m, 0.9, 0.3, CF(0, -1.2, -1.15), rgb(210, 214, 225))
	p(m, V(0.9, 0.5, 0.3), CF(0, -2.1, -1.1), rgb(40, 40, 48))
end
function B.cottoncandy(m)
	-- a fluffy pink cotton-candy tree on a striped trunk
	for i = 0, 3 do cylc(m, 0.7, 0.5, CF(0, -2.3 + i * 0.5, 0), i % 2 == 0 and WHITE or rgb(255, 120, 180)) end
	for _, b in { { 0, 0.8, 0, 2.6 }, { -1.1, 0.3, 0.2, 1.8 }, { 1.1, 0.4, -0.2, 1.9 }, { 0.3, 1.9, 0.1, 1.8 }, { -0.6, 1.4, -0.6, 1.5 } } do
		ball(m, b[4], V(b[1], b[2], b[3]), rgb(255, 170, 215))
	end
	ball(m, 1.0, V(0.9, 1.4, -0.9), rgb(200, 170, 255))
end
function B.slime(m)
	-- a fountain of glowing green slime: a purple stone basin full of it, a bowl up top overflowing, the
	-- slime running down in drips, bubbles on the pool
	local SLIME, STONE = rgb(120, 255, 90), rgb(140, 100, 190)
	cylc(m, 4.6, 1.0, CF(0, -1.9, 0), STONE)
	cylc(m, 4.0, 0.2, CF(0, -1.35, 0), SLIME, Enum.Material.Neon)
	cylc(m, 0.8, 1.9, CF(0, -0.5, 0), STONE)
	cylc(m, 2.6, 0.6, CF(0, 0.6, 0), STONE)
	cylc(m, 2.2, 0.3, CF(0, 0.85, 0), SLIME, Enum.Material.Neon)
	ball(m, 1.0, V(0, 1.2, 0), SLIME, Enum.Material.Neon)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.3
		local len = 0.6 + (k % 3) * 0.35
		cylc(m, 0.34, len, CF(math.cos(a) * 1.3, 0.55 - len / 2, math.sin(a) * 1.3), SLIME, Enum.Material.Neon)
		ball(m, 0.44, V(math.cos(a) * 1.3, 0.55 - len, math.sin(a) * 1.3), SLIME, Enum.Material.Neon)
	end
	for _, b in { { 1.2, -0.7, 0.45 }, { -1.0, -0.6, 0.35 }, { 0.3, 1.0, 0.4 } } do ball(m, b[3], V(b[1], -1.2, b[2]), SLIME:Lerp(WHITE, 0.4), Enum.Material.Neon) end
end
function B.candy(m)
	-- a pile of wrapped sweets: three twisted candies in bright wrappers
	for i, c in { { -0.9, -0.6, 0, rgb(255, 90, 140), 20 }, { 0.9, -0.5, 0.2, rgb(90, 180, 255), -15 }, { 0, 0.6, -0.1, rgb(255, 200, 50), 5 } } do
		local cf = CF(c[1], c[2], c[3]) * CFrame.Angles(0, 0, math.rad(c[5]))
		ball(m, 1.6, cf.Position, c[4])
		ball(m, 0.5, (cf * CF(-0.3, 0.4, -0.55)).Position, WHITE)
		for _, s in { -1, 1 } do cone(m, cf * CF(s * 0.7, 0, 0) * CFrame.Angles(0, 0, s * -math.pi / 2), 0.25, 1.1, 0.8, 3, c[4]:Lerp(WHITE, 0.25)) end
	end
end

-- Heist Gear
function B.box(m)
	-- a cardboard box with its flaps open and a strip of tape
	local CARD = rgb(205, 150, 90)
	studs(p(m, V(4.0, 2.8, 3.0), CF(0, -0.6, 0), CARD))
	p(m, V(3.8, 0.1, 2.8), CF(0, 0.82, 0), CARD:Lerp(rgb(0, 0, 0), 0.4))
	for _, s in { -1, 1 } do
		p(m, V(3.9, 0.12, 1.4), CF(0, 1.15, s * 1.95) * CFrame.Angles(s * math.rad(35), 0, 0), CARD:Lerp(WHITE, 0.1))
	end
	p(m, V(0.7, 2.82, 3.02), CF(0, -0.6, 0), rgb(235, 200, 140))
	p(m, V(0.9, 0.5, 0.06), CF(-1.2, -0.2, -1.52), rgb(60, 60, 70))
end
function B.smokebomb(m)
	-- a round black bomb with its fuse lit, grey smoke puffing up
	ball(m, 2.8, V(-0.4, -0.8, 0), rgb(45, 45, 55))
	p(m, V(0.4, 0.9, 0.2), CF(-1.0, -0.2, -1.2) * CFrame.Angles(0, 0, math.rad(20)), WHITE)
	cylc(m, 0.9, 0.5, CF(0.4, 0.55, 0) * CFrame.Angles(0, 0, math.rad(-30)), rgb(90, 90, 100))
	cylc(m, 0.18, 0.8, CF(0.8, 1.1, 0) * CFrame.Angles(0, 0, math.rad(-30)), rgb(180, 150, 100))
	ball(m, 0.5, V(1.05, 1.5, 0), rgb(255, 170, 40), Enum.Material.Neon)
	for _, b in { { 1.3, 2.2, 1.1 }, { 0.5, 2.6, 1.3 }, { 1.9, 2.8, 0.9 } } do ball(m, b[3], V(b[1], b[2], 0.3), rgb(210, 210, 220)) end
end
function B.whoopee(m)
	-- a pink whoopee cushion, flat and round, its neck sticking out
	local PINK = rgb(255, 110, 150)
	p(m, V(1.0, 3.8, 3.8), CF(0, -0.8, 0) * CFrame.Angles(0, 0, math.rad(90)), PINK, Enum.PartType.Cylinder)
	ball(m, 3.4, V(0, -0.5, 0), PINK).Size = V(3.4, 1.4, 3.4)
	p(m, V(0.9, 0.5, 1.4), CF(0, -0.8, -2.2), PINK:Lerp(rgb(0, 0, 0), 0.15))
	disc(m, 0.9, 0.2, CF(0, -0.8, -2.95), PINK:Lerp(rgb(0, 0, 0), 0.25))
end
function B.energydrink(m)
	-- a can of energy drink: green, a lightning bolt on it, a ring pull on top
	local CAN = rgb(60, 220, 110)
	cylc(m, 2.0, 4.0, CF(), CAN)
	cylc(m, 1.8, 0.3, CF(0, 2.1, 0), rgb(200, 205, 220))
	cylc(m, 1.8, 0.3, CF(0, -2.1, 0), rgb(200, 205, 220))
	p(m, V(0.5, 0.1, 0.8), CF(0.1, 2.3, 0.2), rgb(170, 176, 192))
	local BOLT = rgb(255, 230, 60)
	p(m, V(0.5, 1.5, 0.1), CF(0.2, 0.5, -1.02) * CFrame.Angles(0, 0, math.rad(-20)), BOLT, nil, Enum.Material.Neon)
	p(m, V(0.5, 1.5, 0.1), CF(-0.1, -0.7, -1.02) * CFrame.Angles(0, 0, math.rad(-20)), BOLT, nil, Enum.Material.Neon)
	p(m, V(0.9, 0.3, 0.1), CF(0.05, -0.1, -1.02), BOLT, nil, Enum.Material.Neon)
end
local function shoe(m, at, body, sole, stripe)
	studs(p(m, V(3.8, 0.4, 1.7), at * CF(0, -0.8, 0), sole))
	p(m, V(3.4, 0.9, 1.5), at * CF(0.1, -0.2, 0), body)
	p(m, V(1.5, 1.4, 1.5), at * CF(1.05, 0.5, 0), body)
	wedge(m, V(1.5, 0.9, 1.3), at * CF(-0.9, -0.2, 0) * CFrame.Angles(0, math.rad(-90), 0), body)
	p(m, V(2.0, 0.2, 1.52), at * CF(0.2, -0.2, 0) * CFrame.Angles(0, 0, math.rad(15)), stripe)
	for k = 0, 2 do p(m, V(0.12, 0.08, 1.2), at * CF(-0.3 + k * 0.45, 0.28, 0), WHITE) end
end
function B.sneakers(m)
	-- quiet shoes: soft dark trainers on thick grey soles
	shoe(m, CF(), rgb(60, 70, 110), rgb(160, 165, 180), rgb(130, 150, 220))
end
function B.runningshoes(m)
	-- running shoes: bright orange with a white sole and a speed stripe
	shoe(m, CF(), rgb(255, 120, 40), WHITE, rgb(255, 215, 60))
	for k = 0, 2 do p(m, V(1.0, 0.12, 0.12), CF(2.9, -0.2 + k * 0.4, -0.2), rgb(255, 255, 255)) end
end
function B.lockpick(m)
	-- a lockpick set: a leather roll open with three picks and a key
	studs(p(m, V(4.6, 0.3, 2.6), CF(0, -1.2, 0), rgb(150, 95, 55)))
	for i = 0, 2 do
		local x = -1.2 + i * 0.9
		p(m, V(0.2, 0.1, 2.0), CF(x, -0.95, 0.1), rgb(200, 205, 220))
		p(m, V(0.5, 0.14, 0.6), CF(x, -0.95, 1.0), rgb(60, 60, 70))
	end
	local key = CF(1.4, -0.5, 0) * CFrame.Angles(math.rad(-50), 0, 0)
	disc(m, 1.1, 0.2, key * CF(0, 0, 0.8) * CFrame.Angles(math.rad(90), 0, 0), rgb(255, 205, 60))
	p(m, V(0.26, 0.2, 1.6), key, rgb(255, 205, 60))
	p(m, V(0.26, 0.2, 0.3), key * CF(0.2, 0, -0.6), rgb(255, 205, 60))
end
function B.hoverboard(m)
	-- the gear hoverboard (the Store's gold one's plainer cousin)
	board(m, rgb(60, 130, 240), rgb(160, 220, 255), rgb(80, 200, 255))
end

-- the Upgrades
function B.megaphone(m)
	-- a megaphone: a red cone, a white grip underneath
	local cf = CFrame.Angles(0, 0, math.rad(90))
	cone(m, CF(-1.4, 0, 0) * CFrame.Angles(0, 0, math.rad(-90)), 1.0, 3.0, 3.2, 8, rgb(235, 60, 70))
	cylc(m, 1.2, 0.5, CF(-1.6, 0, 0) * cf, rgb(250, 250, 248))
	cylc(m, 3.1, 0.2, CF(1.8, 0, 0) * cf, rgb(250, 250, 248))
	p(m, V(0.5, 1.4, 0.5), CF(-0.9, -1.0, 0), rgb(60, 60, 70))
	for k = 1, 2 do
		for a = -2, 2 do
			local t = math.rad(a * 18)
			p(m, V(0.2, 0.5, 0.2), CF(2.4 + k * 0.7 + math.cos(t) * 0, math.sin(t) * (1.4 + k * 0.5), 0) * CFrame.Angles(0, 0, t), rgb(255, 205, 60), nil, Enum.Material.Neon)
		end
	end
end
function B.janitorcart(m)
	-- a janitor's cart: a yellow bucket with a wringer, a mop, a spray bottle, wheels
	local YEL = rgb(255, 205, 50)
	studs(p(m, V(3.6, 2.0, 2.2), CF(0, -1.0, 0), YEL))
	p(m, V(1.6, 1.0, 2.0), CF(-0.8, 0.5, 0), rgb(120, 125, 140))
	p(m, V(1.4, 0.2, 1.8), CF(-0.8, 0.02, 0), rgb(90, 180, 255))
	for _, x in { -1.4, 1.4 } do for _, z in { -0.9, 0.9 } do disc(m, 0.6, 0.3, CF(x, -2.2, z) * CFrame.Angles(0, math.rad(90), 0), rgb(40, 40, 48)) end end
	cylc(m, 0.2, 4.0, CF(0.9, 1.2, 0.3) * CFrame.Angles(0, 0, math.rad(-10)), rgb(160, 110, 60))
	p(m, V(1.4, 0.4, 0.9), CF(1.2, 0.2, 0.3), rgb(240, 240, 235))
	cylc(m, 0.6, 1.2, CF(0.8, 0.6, -0.7), rgb(90, 180, 255))
	p(m, V(0.4, 0.3, 0.3), CF(0.8, 1.4, -0.7), WHITE)
end
function B.bank(m)
	-- the tuition office: a little bank building with columns and a $ on its roof
	local STONE = rgb(240, 236, 226)
	studs(p(m, V(4.6, 0.5, 3.0), CF(0, -2.0, 0), rgb(200, 196, 186)))
	for i = 0, 3 do cylc(m, 0.6, 2.6, CF(-1.5 + i * 1.0, -0.5, -1.0), STONE) end
	p(m, V(4.2, 2.6, 1.6), CF(0, -0.5, 0.4), rgb(215, 210, 198))
	p(m, V(4.8, 0.5, 3.2), CF(0, 1.0, 0), STONE)
	tri(m, 4.8, 1.3, 3.2, CF(0, 1.9, 0), STONE)
	disc(m, 1.0, 0.2, CF(0, 1.7, -1.62), rgb(70, 190, 80))
	p(m, V(0.2, 0.7, 0.1), CF(0, 1.7, -1.74), WHITE)
end
function B.laser(m)
	-- a laser gate: two posts, red beams between them
	for _, x in { -1.8, 1.8 } do
		studs(p(m, V(0.9, 4.8, 0.9), CF(x, -0.2, 0), rgb(70, 74, 90)))
		ball(m, 0.6, V(x, 2.3, 0), rgb(255, 60, 60), Enum.Material.Neon)
	end
	for k = 0, 3 do p(m, V(2.8, 0.14, 0.14), CF(0, -1.8 + k * 1.1, 0), rgb(255, 50, 60), nil, Enum.Material.Neon) end
end
function B.stopwatch(m)
	-- a stopwatch: silver, a white face with one hand, the button on top
	disc(m, 3.6, 0.8, CF(), rgb(200, 205, 220), Enum.Material.Metal)
	disc(m, 3.0, 0.84, CF(0, 0, -0.02), WHITE)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		p(m, V(0.12, k % 3 == 0 and 0.4 or 0.2, 0.06), CF(math.sin(a) * 1.25, math.cos(a) * 1.25, -0.45) * CFrame.Angles(0, 0, -a), rgb(60, 60, 70))
	end
	p(m, V(0.14, 1.1, 0.08), CF(0.25, 0.45, -0.48) * CFrame.Angles(0, 0, math.rad(-30)), rgb(235, 60, 70))
	cylc(m, 0.6, 0.6, CF(0, 2.1, 0), rgb(200, 205, 220), Enum.Material.Metal)
	p(m, V(1.0, 0.3, 0.6), CF(0, 2.5, 0), rgb(235, 60, 70))
end
function B.hallpass(m)
	-- a hall pass: a wooden paddle on a lanyard, HALL PASS on it
	studs(p(m, V(3.0, 3.6, 0.3), CF(0, -0.4, 0), rgb(200, 140, 80)))
	p(m, V(2.4, 0.5, 0.06), CF(0, 0.5, -0.18), rgb(235, 60, 70))
	p(m, V(2.0, 0.4, 0.06), CF(0, -0.3, -0.18), rgb(40, 90, 200))
	p(m, V(0.8, 1.6, 0.3), CF(0, -2.9, 0), rgb(160, 110, 60))
	disc(m, 0.5, 0.32, CF(0, 1.0, 0), rgb(120, 80, 45))
	for a = -150, 150, 30 do
		local t = math.rad(a)
		p(m, V(0.5, 0.18, 0.18), CF(math.sin(t) * 0.8, 1.9 + math.cos(t) * 0.9, 0) * CFrame.Angles(0, 0, -t + math.pi / 2), rgb(60, 130, 240))
	end
end
function B.alarm(m)
	-- an alarm bell: a red bell on a wall plate with its striker, flashing
	studs(p(m, V(3.4, 3.4, 0.4), CF(0, 0, 0.6), rgb(200, 205, 220)))
	disc(m, 3.0, 1.0, CF(0, 0.2, 0), rgb(235, 50, 60))
	disc(m, 1.0, 1.1, CF(0, 0.2, -0.05), rgb(200, 205, 220))
	ball(m, 0.7, V(0.9, -1.2, -0.4), rgb(60, 60, 70))
	for _, s in { -1, 1 } do
		for k = 0, 1 do p(m, V(0.2, 0.9, 0.2), CF(s * (2.1 + k * 0.5), 0.2, -0.3) * CFrame.Angles(0, 0, s * math.rad(-20 + k * 40)), rgb(255, 205, 60), nil, Enum.Material.Neon) end
	end
end
function B.trophy(m)
	-- a gold trophy cup on a black base
	local GOLDL = rgb(255, 205, 60)
	studs(p(m, V(2.4, 0.8, 1.6), CF(0, -2.2, 0), rgb(40, 40, 48)))
	cylc(m, 1.0, 0.4, CF(0, -1.6, 0), GOLDL, Enum.Material.Metal)
	cylc(m, 0.4, 1.0, CF(0, -1.0, 0), GOLDL, Enum.Material.Metal)
	cone(m, CF(0, -0.5, 0), 1.0, 2.6, 2.2, 7, GOLDL)
	for _, s in { -1, 1 } do
		for a = 20, 160, 35 do
			local t = math.rad(a)
			p(m, V(0.3, 0.4, 0.3), CF(s * (1.3 + math.sin(t) * 0.55), 0.6 + math.cos(t) * 0.55, 0), GOLDL)
		end
	end
	star5(m, CF(0, 0.6, -1.0), 0.26, rgb(255, 250, 230), 0.08)
end

-- the Store's newer things
function B.letterLegendary(m)
	-- a gold letter with a red seal and a crown on it, sparkling
	letter(m, rgb(255, 222, 120), rgb(235, 180, 60), rgb(220, 50, 60), rgb(150, 20, 35), function(m2)
		star(m2, CF(-1.9, 1.5, -0.3), 0.55, rgb(255, 255, 255))
		star(m2, CF(1.9, -1.2, -0.3), 0.4, rgb(255, 255, 255))
	end)
end
function B.fastletters(m)
	-- three letters fanned out flying, speed lines behind them
	for i, c in { { rgb(248, 243, 230), -0.9, -10 }, { rgb(255, 170, 200), 0, 0 }, { rgb(255, 222, 120), 0.9, 10 } } do
		local cf = CF(i * 0.35 - 0.7, c[2] * 0.6, -i * 0.15) * CFrame.Angles(0, 0, math.rad(c[3]))
		p(m, V(3.2, 2.1, 0.25), cf, c[1])
		tri(m, 3.2, 1.1, 0.06, cf * CF(0, 0.45, -0.15) * CFrame.Angles(0, 0, math.pi), c[1]:Lerp(rgb(0, 0, 0), 0.12))
	end
	disc(m, 0.7, 0.14, CF(0.35, -0.1, -0.7), rgb(220, 50, 60))
	for k = 0, 2 do p(m, V(1.3 - k * 0.3, 0.16, 0.1), CF(2.6 + k * 0.1, 0.9 - k * 0.8, 0), rgb(255, 255, 255)) end
end
function B.ticket(m)
	-- two carnival tickets, red and gold, with notched ends and a star
	for i, c in { { rgb(235, 60, 70), -12, V(-0.4, 0.4, 0.1) }, { rgb(255, 200, 50), 8, V(0.4, -0.4, -0.1) } } do
		local cf = CF(c[3]) * CFrame.Angles(0, 0, math.rad(c[2]))
		studs(p(m, V(4.2, 2.0, 0.2), cf, c[1]))
		for _, sx in { -1, 1 } do disc(m, 0.6, 0.24, cf * CF(sx * 2.1, 0, 0), rgb(220, 240, 255)) end
		p(m, V(0.1, 1.7, 0.22), cf * CF(1.2, 0, 0), c[1]:Lerp(rgb(0, 0, 0), 0.3))
		star5(m, cf * CF(-0.4, 0, -0.14), 0.28, rgb(255, 255, 255), 0.06)
	end
	p(m, V(0.9, 0.5, 0.08), CF(-2.4, 1.6, -0.2), rgb(255, 255, 255))
	p(m, V(0.5, 0.9, 0.08), CF(-2.4, 1.6, -0.2), rgb(255, 255, 255))
end
function B.candyjar(m)
	-- a big glass jar of sweets with a red lid
	for i = 0, 22 do
		local a, h = i * 2.3, (i % 6) / 6
		ball(m, 0.75, V(math.cos(a) * 0.9, -1.4 + h * 2.4, math.sin(a) * 0.9), ({ rgb(255, 90, 140), rgb(255, 210, 60), rgb(90, 180, 255), rgb(120, 220, 120), rgb(200, 120, 255) })[i % 5 + 1])
	end
	local glass = cylc(m, 3.0, 3.4, CF(0, -0.3, 0), rgb(220, 240, 255))
	glass.Transparency = 0.65
	cylc(m, 3.2, 0.6, CF(0, 1.7, 0), rgb(235, 60, 70))
	cylc(m, 1.0, 0.4, CF(0, 2.1, 0), rgb(235, 60, 70))
	p(m, V(1.6, 0.9, 0.08), CF(0, -0.4, -1.52), rgb(255, 245, 220))
end
function B.moneycloud(m)
	-- a fluffy cloud raining money: bills and coins falling out of it
	for _, b in { { 0, 1.4, 0, 2.4 }, { -1.3, 1.0, 0.1, 1.8 }, { 1.3, 1.0, -0.1, 1.9 }, { -0.5, 2.0, 0.2, 1.6 }, { 0.7, 1.9, -0.2, 1.7 } } do
		ball(m, b[4], V(b[1], b[2], b[3]), rgb(245, 248, 255))
	end
	for _, bl in { { -1.2, -0.6, 20 }, { 0.3, -1.4, -15 }, { 1.3, -0.5, 30 }, { -0.4, -2.3, 5 } } do
		local cf = CF(bl[1], bl[2], -0.3) * CFrame.Angles(math.rad(20), 0, math.rad(bl[3]))
		p(m, V(1.3, 0.7, 0.08), cf, rgb(90, 200, 100))
		p(m, V(1.0, 0.45, 0.09), cf, rgb(160, 235, 150))
	end
	for _, c in { { 0.9, -1.9 }, { -1.6, -1.7 }, { 1.8, -1.5 } } do disc(m, 0.6, 0.14, CF(c[1], c[2], -0.4), rgb(255, 205, 60)) end
end

-- the Bus Depot's buses (tomas, 2026-09-27: "a model of a bus with a speed trail behind it"): the
-- bonnet at -X (the right of the screen: it's driving right), the windows facing the camera, streaks
-- of light trailing off behind
local function busBody(m, c)
	p(m, V(5, 2.3, 2), CF(0.3, 0.25, 0), c.body)
	p(m, V(1.3, 1.25, 2), CF(-2.85, -0.28, 0), c.body)
	p(m, V(0.1, 0.9, 1.5), CF(-2.24, 0.78, 0) * CFrame.Angles(0, 0, math.rad(-12)), c.glass)
	for k = 0, 3 do p(m, V(0.82, 0.72, 0.1), CF(2.0 - k * 1.05, 0.66, -1.01), c.glass) end
	p(m, V(0.8, 1.5, 0.1), CF(-1.75, 0.15, -1.01), c.door)
	p(m, V(5.02, 0.28, 0.1), CF(0.3, -0.32, -1.01), c.trim)
	p(m, V(5.1, 0.3, 2.05), CF(0.3, 1.45, 0), c.roof)
	p(m, V(0.3, 0.5, 2.05), CF(-3.45, -0.55, 0), c.trim)
	for _, x in { -2.3, 1.9 } do
		cyl(m, 1.15, 0.42, V(x, -0.95, -0.9), INK, "z")
		cyl(m, 0.52, 0.44, V(x, -0.95, -0.92), c.hub or rgb(200, 205, 215), "z")
	end
	ball(m, 0.42, V(-3.55, -0.1, -0.7), rgb(255, 250, 220), Enum.Material.Neon)
end
local function speedTrail(m, colors)
	for i, y in { 1.05, 0.25, -0.55 } do
		for k = 0, 3 do
			local s = p(m, V(1.25 - k * 0.18, 0.2 - k * 0.02, 0.2), CF(3.55 + k * 1.2 + (i % 2) * 0.35, y, -0.35), colors[(i + k) % #colors + 1], nil, Enum.Material.Neon)
			s.Transparency = 0.05 + k * 0.22
		end
	end
end
function B.schoolbus(m)
	busBody(m, { body = rgb(255, 200, 40), glass = rgb(150, 210, 255), door = rgb(120, 180, 240), trim = INK, roof = rgb(250, 250, 245) })
	speedTrail(m, { rgb(90, 200, 255), rgb(255, 120, 60), rgb(255, 255, 255) })
end
-- the MAGIC BUS (tomas, 2026-09-27: "not just a different colour: a completely different bus, a magic
-- bus that rides on clouds"): a rounded enchanted coach in midnight purple, glowing arched windows, a
-- gold crescent moon and stars down its side, a lantern for a headlamp, a big wizard's hat for a roof
-- with a star on its tip, and no wheels: it floats on a bank of clouds, a trail of little clouds and
-- sparkles streaming out behind (the front at -X, the right of the screen)
function B.magicbus(m)
	local BODY, BODY_D, ROOF, HAT = rgb(115, 60, 210), rgb(70, 35, 150), rgb(175, 135, 255), rgb(60, 30, 130)
	local GOLDL, GLOW = rgb(255, 205, 70), rgb(255, 222, 120)
	local CLOUD, CLOUD_S = rgb(252, 252, 255), rgb(214, 220, 248)
	-- the coach: a box with round ends (a cylinder across each end)
	p(m, V(4.4, 2.3, 2.0), CF(0.5, 0.35, 0), BODY)
	cyl(m, 2.3, 2.0, V(2.7, 0.35, 0), BODY, "z")
	p(m, V(1.3, 1.4, 2.0), CF(-2.25, -0.1, 0), BODY)
	cyl(m, 1.4, 2.0, V(-2.9, -0.1, 0), BODY, "z")
	p(m, V(6.0, 0.34, 2.04), CF(-0.05, -0.62, 0), BODY_D)
	p(m, V(6.1, 0.16, 2.06), CF(-0.05, -0.25, 0), GOLDL)
	-- the roof, lighter, with a gold edge
	p(m, V(4.7, 0.3, 2.14), CF(0.45, 1.58, 0), ROOF)
	p(m, V(4.72, 0.1, 2.16), CF(0.45, 1.4, 0), GOLDL)
	-- four arched windows, glowing warm
	for k = 0, 3 do
		local x = 2.15 - k * 1.02
		p(m, V(0.74, 0.66, 0.1), CF(x, 0.72, -1.01), GLOW, nil, Enum.Material.Neon)
		disc(m, 0.74, 0.1, CF(x, 1.05, -1.01), GLOW, Enum.Material.Neon)
		p(m, V(0.06, 1.0, 0.12), CF(x, 0.85, -1.03), BODY_D)
	end
	-- the windscreen and the driver's glow
	p(m, V(0.1, 1.0, 1.6), CF(-1.72, 0.8, 0) * CFrame.Angles(0, 0, math.rad(-14)), rgb(180, 205, 255), nil, Enum.Material.Glass)
	-- a lantern for a headlamp, a gold crescent moon and stars on the side
	ball(m, 0.5, V(-3.55, -0.05, -0.6), GLOW, Enum.Material.Neon)
	p(m, V(0.14, 0.62, 0.14), CF(-3.55, 0.35, -0.6), GOLDL)
	disc(m, 0.95, 0.08, CF(-1.15, 0.05, -1.03), GOLDL)
	disc(m, 0.78, 0.1, CF(-0.98, 0.14, -1.04), BODY)
	star5(m, CF(1.55, -0.02, -1.06), 0.13, GOLDL, 0.05)
	star5(m, CF(0.35, 0.02, -1.06), 0.1, GOLDL, 0.05)
	star5(m, CF(2.65, 0.12, -1.06), 0.08, GOLDL, 0.05)
	-- the wizard's hat roof, tipped back, a gold band and a star on its tip
	cylc(m, 2.6, 0.16, CF(0.7, 1.78, 0), HAT)
	cone(m, CF(0.7, 1.84, 0) * CFrame.Angles(0, 0, math.rad(-14)), 1.45, 0.12, 2.2, 8, HAT)
	cylc(m, 1.5, 0.22, CF(0.7, 1.97, 0), GOLDL)
	star(m, CF(1.25, 4.15, 0), 0.32, GOLDL)
	-- the cloud bank it rides on
	for _, c in { { -2.7, -1.0, 0, 1.3 }, { -1.6, -1.2, 0.15, 1.6 }, { -0.3, -1.15, -0.1, 1.7 }, { 1.0, -1.2, 0.15, 1.6 }, { 2.2, -1.05, 0, 1.5 }, { 3.2, -0.9, 0.05, 1.1 } } do
		ball(m, c[4], V(c[1], c[2], c[3] - 0.45), CLOUD)
		ball(m, c[4] * 0.85, V(c[1] + 0.35, c[2] - 0.2, c[3] + 0.5), CLOUD_S)
	end
	-- the trail behind (+X): little clouds getting smaller, and sparkles
	for _, c in { { 4.1, -0.75, 0.95 }, { 4.95, -0.55, 0.72 }, { 5.65, -0.35, 0.52 }, { 6.2, -0.2, 0.36 } } do
		ball(m, c[3], V(c[1], c[2], -0.1), CLOUD)
	end
	star(m, CF(4.4, 0.55, -0.4), 0.3, rgb(255, 170, 255))
	star(m, CF(5.3, 1.1, -0.2), 0.22, GOLDL)
	star(m, CF(5.9, 0.35, -0.3), 0.16, rgb(170, 225, 255))
end

function B.galaxybus(m)
	local NAVY, CYAN = rgb(35, 45, 120), rgb(90, 230, 255)
	busBody(m, { body = NAVY, glass = rgb(120, 210, 255), door = rgb(60, 80, 170), trim = CYAN, roof = rgb(20, 25, 70), hub = CYAN })
	-- a glass dome and a little antenna on the roof, fins and a rocket flame at the back, stars
	local dome = ball(m, 1.3, V(0.7, 1.7, 0), rgb(170, 230, 255), Enum.Material.Glass)
	dome.Transparency = 0.35
	cylc(m, 0.1, 0.8, CF(-1.3, 2.0, 0), rgb(200, 205, 215))
	ball(m, 0.3, V(-1.3, 2.45, 0), rgb(255, 90, 120), Enum.Material.Neon)
	for _, s in { -1, 1 } do wedge(m, V(0.2, 1.0, 1.2), CF(2.75, 1.85, s * 0.7) * CFrame.Angles(0, math.rad(90), 0), CYAN) end
	cylc(m, 1.0, 0.4, CF(2.95, 0.25, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(90, 95, 120))
	for _, st in { { 1.6, 0.9 }, { 0.5, -0.1 }, { -0.7, 0.95 } } do ball(m, 0.18, V(st[1], st[2], -1.07), rgb(255, 255, 255), Enum.Material.Neon) end
	speedTrail(m, { CYAN, rgb(180, 120, 255), rgb(255, 255, 255) })
end

-- the keys the store uses for its passes and products (Config keys -> icon)
Icons.FOR = {
	StarterPack = "gift", VIP = "crown", SuperSpeed = "sneaker", GoldenBoard = "goldboard", DiamondBoard = "gem",
	Luck = "clover", AutoCollect = "broom", LongLock = "padlock", TeleportHome = "house", OfflinePlus = "moon",
	MoneyBoost = "cash", Cash10m = "cash", Cash1h = "moneybag", Cash4h = "vault", LuckyBus = "bus",
	Cash8h = "briefcase", Cash16h = "chest", Cash24h = "truck", Cash1w = "moneyMountain",
	ServerLuck = "sparkle", ExpressRare = "letter", ExpressEpic = "letterEpic", LockRefresh = "refresh",
	BusLuck = "clover", TripleBus = "schoolbus", AutoBus = "refresh",
	FastLetters = "fastletters", DoubleTickets = "ticket", ExpressLegendary = "letterLegendary", SchoolShield = "shield",
	MoneyRain = "moneycloud", CandyBag = "candy", CandyJar = "candyjar",
}

-- how each icon stands (tomas, 2026-09-27: "all the models ... are facing the same way but just tilted
-- ... make them all in the best stance"): each picked by eye from a row of candidates; turn = its yaw,
-- tilt = how far the camera looks down on it, roll = how far it leans across the screen (+ leans it
-- right, clockwise), all in degrees. Leans go both ways so a row of them doesn't all tip one way.
local A = { turn = -35, tilt = 20 } -- three quarters, a little from above
local R = { turn = -35, tilt = 20, roll = 12 } -- the same, leaning right
local L = { turn = -35, tilt = 20, roll = -12 } -- the same, leaning left
local HIGH = { turn = -50, tilt = 28 } -- turned further, from higher: vehicles coming at you
Icons.LOOK = {
	-- the four after tomas's reference
	basket = { turn = -50, tilt = 16 },
	cash = { turn = -38, tilt = 30 },
	book = { turn = -28, tilt = 42 },
	calendar = { turn = -24, tilt = 14 },
	-- straight up: buildings, people, round things
	backpack = A, gear = A, gem = A, house = A, moneyMountain = A, people = A, pillar = A,
	bus = HIGH, truck = HIGH,
	apple = R, briefcase = R, broom = R, chest = R, letter = R, moon = R, padlock = R, scroll = R,
	sparkle = R, upArrow = R,
	clover = L, crown = L, folder = L, gift = L, letterEpic = L, moneybag = L, pencil = L, refresh = L,
	shield = L, vault = L, wrench = L,
	-- the hoverboard flying up across, its deck and bolt showing; the sneaker toe first, from above
	goldboard = { turn = -50, tilt = 40, roll = 20 },
	sneaker = { turn = -40, tilt = 35, roll = -20 },
}

-- the School Shop's items (Config.Supplies / Builds / CandyShop / EventShop / Gear, the event trophies,
-- Config.Upgrades) -> icon
Icons.SHOP = {
	Pencils = "pencil", Notebooks = "notebook", Crayons = "crayons", Textbooks = "books", Rulers = "ruler",
	Calculators = "calculator", Globes = "globe", Microscopes = "microscope", Laptops = "laptop", Tablets = "tablet",
	Smartboards = "smartboard", VRHeadsets = "vr", RobotTutors = "robot", HoloDesks = "holodesk",
	QuantumPCs = "quantum", ThinkingCaps = "thinkingcap",
	-- the School Builder
	Curtains = "curtains", FlowerBeds = "flowerbed", Awning = "awning", PicketFence = "fence", Marquee = "marquee",
	LowBrickWall = "brickwall", MascotLockers = "lockers", Cafeteria = "lunchtable", ArchedWindows = "archwindow",
	StainedGlass = "stainedglass", PathLights = "lamppost", WindowBoxes = "windowbox", Playground = "slide",
	VendingMachines = "vending", Court = "basketball", Garden = "carrot", Bleachers = "bleachers", BrickWall = "brickwall",
	Fountain = "fountain", Banners = "banner", Statue = "statue", IronFence = "irongate", SolarPanels = "solar",
	BellTower = "bell",
	-- Janitor Stan's candy, the Ticket shop
	JawbreakerTrap = "jawbreaker", LollipopLamps = "lollipop", GumballMachine = "gumball", CottonCandyTree = "cottoncandy",
	SlimeFountain = "slime", LetterRare = "letter", LetterEpic = "letterEpic", LetterLegendary = "letterLegendary", Candy50 = "candy",
	-- Heist Gear
	CardboardBox = "box", SmokeBomb = "smokebomb", WhoopeeCushion = "whoopee", EnergyDrink = "energydrink",
	SilentSneakers = "sneakers", RunningShoes = "runningshoes", LockpickSet = "lockpick", Hoverboard = "hoverboard",
	-- the Upgrades
	Recruitment = "megaphone", Janitor = "janitorcart", TuitionOffice = "bank", LaserGate = "laser", LockTime = "padlock",
	LockCooldown = "stopwatch", HallPass = "hallpass", Alarm = "alarm",
}
-- (an event's trophy)
Icons.SHOP_TROPHY = "trophy"
for k, v in {
	notebook = R, crayons = A, books = HIGH, ruler = L, calculator = R, globe = L, microscope = A, laptop = { turn = -30, tilt = 28 },
	tablet = L, smartboard = A, vr = { turn = -24, tilt = 38, roll = 8 }, robot = R, holodesk = { turn = -30, tilt = 24 }, quantum = A,
	thinkingcap = { turn = -30, tilt = 20, roll = -10 },
	curtains = A, flowerbed = HIGH, awning = A, fence = L, marquee = A, brickwall = A, lockers = A, lunchtable = HIGH,
	archwindow = A, stainedglass = A, lamppost = R, windowbox = A, slide = A, vending = A, basketball = A, carrot = A,
	bleachers = HIGH, fountain = HIGH, banner = R, statue = A, irongate = A, solar = A, bell = A,
	jawbreaker = R, lollipop = L, gumball = A, cottoncandy = A, slime = A, candy = HIGH,
	box = HIGH, smokebomb = R, whoopee = HIGH, energydrink = L, sneakers = { turn = -40, tilt = 30, roll = -12 },
	runningshoes = { turn = -40, tilt = 30, roll = -12 }, lockpick = HIGH, hoverboard = { turn = -50, tilt = 40, roll = 20 },
	megaphone = L, janitorcart = A, bank = A, laser = A, stopwatch = R, hallpass = R, alarm = A, trophy = A,
	letterLegendary = R, fastletters = R, ticket = L, candyjar = A, moneycloud = A,
	schoolbus = { turn = -24, tilt = 14 }, magicbus = { turn = -26, tilt = 16 }, galaxybus = { turn = -24, tilt = 14 },
} do Icons.LOOK[k] = v end

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

-- Built only when seen (tomas, 2026-09-27: "the game is so incredibly laggy"; measured: 288 viewports and
-- 26,392 parts in the player's gui, every panel's icons built at the start whether it was ever opened, at
-- 4.6 GB): an icon is an empty frame until it's on screen (its panel open, its row scrolled into view),
-- builds then (a few a frame, so opening a big panel doesn't hitch), sways only while it's in view, and
-- gives its model back after a while out of sight.
-- (a plain table, cleaned when its thing is gone: a weak-keyed one loses a gui object whose script
-- handle the engine lets go of while the object is still on screen, and it silently stops)
local views = {} -- holder -> { key, opts, st?, built, hiddenAt }
local function shown(g)
	local a = g
	while a and a:IsA("GuiObject") do
		if not a.Visible then return false end
		a = a.Parent
	end
	if a and a:IsA("LayerCollector") and not a.Enabled then return false end
	return g.AbsoluteSize.X > 0
end
-- (inside every scrolling list and clipping frame it's in, and on the screen)
local function inView(g)
	local p, s = g.AbsolutePosition, g.AbsoluteSize
	local a = g.Parent
	while a and a:IsA("GuiObject") do
		if a:IsA("ScrollingFrame") or a.ClipsDescendants then
			local ap, as = a.AbsolutePosition, a.AbsoluteSize
			if p.X > ap.X + as.X or p.Y > ap.Y + as.Y or p.X + s.X < ap.X or p.Y + s.Y < ap.Y then return false end
		end
		a = a.Parent
	end
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or Vector2.new(1e4, 1e4)
	return p.X < vs.X and p.Y < vs.Y + 60 and p.X + s.X > 0 and p.Y + s.Y > -60
end
local function orbit(st, t)
	local a = t and math.sin(t * 1.3 + st.phase) * math.rad(st.sway) or 0
	local y = t and math.sin(t * 2 + st.phase) * st.bob or 0
	return CFrame.new(st.center - Vector3.new(0, y, 0)) * CFrame.Angles(0, -a, 0) * CFrame.Angles(st.pitch, 0, 0) * CFrame.new(0, 0, -st.dist) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(0, 0, st.roll)
end

-- opts: size, position, anchor, zindex (the outline's; the icon draws one above), sway (degrees,
-- default 18), bob (studs, default 0.12), turn (a fixed yaw in degrees, default -22), tilt (how far
-- the camera looks down on it, degrees, default 12), outline (default true), still (no motion)
local OUTLINE = rgb(22, 18, 32)
-- the framing: every part's corners as the camera sees them (turned, and looked down on), so one seen
-- from high up (the basket, the book) fits as snugly as one seen side on. -> its middle, the distance
local function fit(model, pitch, roll)
	local rot = CFrame.Angles(pitch, 0, 0) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(0, 0, roll)
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

-- the viewports and the model, into an icon's frame
local function build(holder, v)
	local key, opts = v.key, v.opts
	local z = opts.zindex or 14
	local model = Icons.build(key)
	local look = Icons.LOOK[key] or {}
	local base = CFrame.Angles(0, math.rad(opts.turn or look.turn or -22), 0)
	model:PivotTo(base)
	local pitch = math.rad(opts.tilt or look.tilt or 12)
	local roll = math.rad(opts.roll or look.roll or 0)
	local center, dist = fit(model, pitch, roll)
	local st = {
		center = center, dist = dist, pitch = pitch, roll = roll,
		phase = v.phase, sway = opts.sway or 18, bob = opts.bob or 0.12,
	}
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.CFrame = orbit(st)
	st.cam = cam
	local layers = {}
	local function layer(name, zi)
		local vp = Instance.new("ViewportFrame")
		vp.Name = name
		vp.BackgroundTransparency = 1
		vp.Size = UDim2.fromScale(1, 1)
		vp.ZIndex = zi
		vp.CurrentCamera = cam
		vp.Parent = holder
		table.insert(layers, vp)
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
		local flat = model:Clone()
		for _, d in flat:GetDescendants() do
			if d:IsA("BasePart") then
				d.Color = Color3.new(1, 1, 1)
				d.Material = Enum.Material.SmoothPlastic
				for _, f in { "TopSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface" } do d[f] = Enum.SurfaceType.Smooth end
			end
		end
		for i = 1, #DIRS do
			local copy = i == 1 and flat or flat:Clone()
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
	v.conn = holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	place()
	v.st, v.layers, v.built = st, layers, true
end
local function unbuild(v)
	if v.conn then v.conn:Disconnect() end
	for _, vp in v.layers or {} do vp:Destroy() end
	v.st, v.layers, v.conn, v.built = nil, nil, nil, false
end

local FREE_AFTER = 20 -- (seconds out of sight before an icon gives its model back)
local BUILDS_PER_TICK = 4
local acc = 0
RunService.RenderStepped:Connect(function(dt)
	acc += dt
	if acc < 1 / 30 then return end
	acc = 0
	local now = os.clock()
	local budget = BUILDS_PER_TICK
	for holder, v in views do
		if not holder.Parent then
			if v.built then unbuild(v) end
			views[holder] = nil
		elseif shown(holder) and inView(holder) then
			v.hiddenAt = nil
			if not v.built then
				if budget > 0 then
					budget -= 1
					build(holder, v)
				end
			elseif not v.opts.still then
				v.st.cam.CFrame = orbit(v.st, now)
			end
		elseif v.built then
			v.hiddenAt = v.hiddenAt or now
			if now - v.hiddenAt > FREE_AFTER then unbuild(v) end
		end
	end
end)

function Icons.view(parent, key, opts)
	opts = opts or {}
	local holder = Instance.new("Frame")
	holder.Name = "Icon"
	holder.BackgroundTransparency = 1
	holder.Size = opts.size or UDim2.fromScale(1, 1)
	holder.Position = opts.position or UDim2.new()
	holder.AnchorPoint = opts.anchor or Vector2.zero
	holder.ZIndex = opts.zindex or 14
	holder.Parent = parent
	local v = { key = key, opts = opts, phase = math.random() * 6, built = false }
	views[holder] = v
	-- (one somewhere visible already is built now, so it doesn't pop in a frame late)
	if shown(holder) and inView(holder) then build(holder, v) end
	return holder
end

return Icons
