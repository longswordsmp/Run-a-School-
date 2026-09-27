-- ReplicatedStorage.Shared.Icons
-- The store's (and the menus') icons: small chunky 3D models, built from parts, shown in a
-- ViewportFrame with a dark silhouette just behind them (the outline the reference's icons have) and
-- a gentle sway and bob. Icons.view(parent, key, opts) -> the ViewportFrame.
-- Keys: basket crown gift sneaker goldboard gem clover broom padlock house moon cash moneybag vault
-- bus sparkle letter letterEpic refresh shop flask maple pine vexprep factory skull
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

local B = {}

-- a red shopping basket with things in it (the store's own icon)
function B.basket(m)
	local RED, RED_D, RED_L = rgb(235, 60, 70), rgb(170, 30, 45), rgb(255, 120, 125)
	p(m, V(4.4, 2.6, 3), CF(0, 0, 0), RED)
	p(m, V(4.8, 0.45, 3.4), CF(0, 1.4, 0), RED_L)
	for x = -1.6, 1.6, 0.8 do p(m, V(0.18, 2.2, 0.1), CF(x, -0.1, -1.53), RED_D) end
	for y = -0.8, 0.8, 0.8 do p(m, V(4.2, 0.18, 0.1), CF(0, y, -1.53), RED_D) end
	-- what's in it: a green ball, a yellow box, a blue bottle
	ball(m, 1.4, V(-1.1, 1.8, 0.3), rgb(90, 210, 90))
	p(m, V(1.2, 1.2, 1.2), CF(0.3, 1.9, 0.2) * CFrame.Angles(0, 0.4, 0.3), rgb(255, 210, 60))
	cyl(m, 0.8, 1.8, V(1.4, 2.1, 0.4), rgb(80, 150, 255), "y")
	-- the handle across the top
	for _, s in { -1, 1 } do p(m, V(0.3, 2.4, 0.3), CF(s * 1.9, 2.6, 0) * CFrame.Angles(0, 0, s * -0.25), rgb(200, 205, 215)) end
	p(m, V(3.2, 0.3, 0.3), CF(0, 3.8, 0), rgb(200, 205, 215))
end

function B.crown(m)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local cf = CF(math.sin(a) * 1.7, 0, -math.cos(a) * 1.7) * CFrame.Angles(0, -a, 0)
		p(m, V(1.45, 1.3, 0.45), cf, GOLD)
		local tall = k % 2 == 0
		p(m, V(0.55, tall and 1.5 or 0.9, 0.45), cf * CF(0, tall and 1.35 or 1.05, 0), GOLD)
		ball(m, 0.55, (cf * CF(0, tall and 2.2 or 1.6, 0)).Position, GOLD_D)
	end
	p(m, V(4.1, 0.3, 4.1), CF(0, -0.55, 0), GOLD_D)
	ball(m, 0.8, V(0, 0.05, -1.95), rgb(235, 40, 70))
	ball(m, 0.6, V(-1.4, 0.05, -1.45), rgb(70, 140, 255))
	ball(m, 0.6, V(1.4, 0.05, -1.45), rgb(80, 210, 110))
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

local function board(m, deck, trim, glow)
	-- a chunky deck turned up to face you, rails along its sides, a glow under it and a spark or two
	local tilt = CFrame.Angles(math.rad(-68), 0, math.rad(-20))
	p(m, V(4.4, 0.55, 2.2), tilt, deck)
	for _, s in { -1, 1 } do
		local tip = cyl(m, 2.2, 0.55, (tilt * CF(s * 2.2, 0, 0)).Position, deck, "y")
		tip.CFrame = tilt * CF(s * 2.2, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
		p(m, V(4.4, 0.6, 0.18), tilt * CF(0, 0, s * 1.12), trim)
	end
	p(m, V(3.8, 0.1, 0.45), tilt * CF(0, 0.3, 0), trim)
	p(m, V(3.6, 0.1, 1.6), tilt * CF(0, -0.33, 0), glow, nil, Enum.Material.Neon)
end
function B.goldboard(m) board(m, GOLD, rgb(255, 245, 200), rgb(255, 150, 40)) end

local GEM_MESH = "rbxassetid://9438591297"
function B.gem(m)
	local g = p(m, V(3.4, 3.4, 3.4), CF(), rgb(90, 190, 255))
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = GEM_MESH
	mesh.Scale = Vector3.one * (3.4 / 50)
	mesh.Parent = g
	g.CFrame = CFrame.Angles(math.rad(-15), 0, 0)
	ball(m, 0.45, V(0.9, 0.9, -1.1), rgb(255, 255, 255), Enum.Material.Neon)
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
	p(m, V(3.4, 2.4, 2.6) * s, at * CF(0, -0.4 * s, 0), wall)
	for _, side in { -1, 1 } do
		wedge(m, V(3.8 * s, 1.5 * s, 1.5 * s), at * CF(0, 1.55 * s, side * 0.72 * s) * CFrame.Angles(0, side > 0 and math.pi or 0, 0), roof)
	end
	p(m, V(0.9, 1.4, 0.1) * s, at * CF(-0.6 * s, -0.9 * s, -1.33 * s), rgb(150, 90, 50))
	p(m, V(0.9, 0.8, 0.1) * s, at * CF(0.8 * s, -0.2 * s, -1.33 * s), rgb(150, 210, 255))
	p(m, V(0.5, 1.2, 0.5) * s, at * CF(0.9 * s, 2 * s, 0.3 * s), rgb(200, 90, 70))
end
function B.house(m) houseAt(m, CF(), 1, rgb(255, 245, 225), rgb(235, 70, 70)) end

function B.moon(m)
	local Y = rgb(255, 225, 90)
	for k = -5, 5 do
		local a = math.rad(k * 17)
		local d = 1.7 - math.abs(k) * 0.12
		ball(m, d, V(-math.cos(a) * 1.3 + 0.4, math.sin(a) * 1.8, 0), Y)
	end
	for _, st in { { 1.6, 1.4, 0.7 }, { 2.0, -0.6, 0.5 }, { 1.2, 0.3, 0.4 } } do
		p(m, V(st[3], st[3], 0.2), CF(st[1], st[2], 0) * CFrame.Angles(0, 0, math.rad(45)), rgb(255, 250, 200), nil, Enum.Material.Neon)
	end
end

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
function B.cash(m) cashStack(m, CF(0, -0.8, 0), 4) end

function B.moneybag(m)
	local TAN = rgb(215, 170, 100)
	ball(m, 3.2, V(0, -0.4, 0), TAN)
	cyl(m, 1.2, 0.9, V(0, 1.4, 0), TAN, "y")
	cyl(m, 1.4, 0.3, V(0, 1.1, 0), GOLD, "y")
	for _, s in { -1, 1 } do ball(m, 0.9, V(s * 0.5, 2.1, 0), TAN) end
	cyl(m, 1.6, 0.3, V(1.1, -0.9, -1.4), GOLD, "z")
	cyl(m, 1.1, 0.32, V(1.1, -0.9, -1.4), GOLD_D, "z")
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

local function star(m, at, s, color)
	-- four spikes, each two wedges back to back (a thin triangle), round a small diamond
	for k = 0, 3 do
		local turn = at * CFrame.Angles(0, 0, k * math.pi / 2)
		for _, side in { -1, 1 } do
			local w = Instance.new("WedgePart")
			w.Anchored = true
			w.Size = V(0.3, 1.5, 0.45) * s
			-- (a wedge's slope faces +Z and -Y: turned so the pair meets in a point at the tip)
			w.CFrame = turn * CF(side * 0.22 * s, 0.95 * s, 0) * CFrame.Angles(0, side > 0 and math.rad(-90) or math.rad(90), 0) * CFrame.Angles(0, 0, 0)
			w.Color = color
			w.Material = Enum.Material.Neon
			w.Parent = m
		end
	end
	p(m, V(0.75, 0.75, 0.32) * s, at * CFrame.Angles(0, 0, math.rad(45)), color, nil, Enum.Material.Neon)
end
function B.sparkle(m)
	star(m, CF(-0.3, 0.2, 0), 1.3, rgb(255, 225, 80))
	star(m, CF(1.5, 1.5, 0.3), 0.6, rgb(255, 255, 255))
	star(m, CF(1.4, -1.3, 0.3), 0.5, rgb(255, 180, 230))
end

local function letter(m, paper, flap, seal)
	p(m, V(4, 2.6, 0.3), CF(), paper)
	for _, s in { -1, 1 } do
		p(m, V(2.35, 0.25, 0.1), CF(s * 1, 0.55, -0.18) * CFrame.Angles(0, 0, s * -0.55), flap)
	end
	ball(m, 0.9, V(0, 0, -0.3), seal)
end
function B.letter(m) letter(m, rgb(250, 248, 240), rgb(200, 196, 190), rgb(220, 40, 50)) end
function B.letterEpic(m) letter(m, rgb(255, 180, 220), rgb(220, 120, 180), rgb(150, 60, 220)) end

function B.refresh(m)
	local BL = rgb(70, 150, 255)
	for k = 0, 11 do
		local a = math.rad(40 + k * 24)
		p(m, V(0.75, 0.75, 0.6), CF(math.cos(a) * 1.7, math.sin(a) * 1.7, 0) * CFrame.Angles(0, 0, a), BL)
	end
	wedge(m, V(0.6, 1.4, 1.4), CF(1.55, 0.95, 0) * CFrame.Angles(0, math.rad(-90), math.rad(-60)), BL)
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

-- the panels' own icons (hanging off their title bars)
function B.apple(m)
	ball(m, 3, V(0, -0.2, 0), rgb(235, 50, 60))
	ball(m, 1.4, V(-0.6, 0.9, -0.2), rgb(255, 110, 110))
	p(m, V(0.3, 1, 0.3), CF(0, 1.6, 0) * CFrame.Angles(0, 0, 0.2), rgb(120, 80, 40))
	p(m, V(1.1, 0.25, 0.6), CF(0.6, 1.8, 0) * CFrame.Angles(0, 0, -0.5), rgb(80, 200, 80))
end
function B.upArrow(m)
	local G = rgb(80, 220, 110)
	p(m, V(1.4, 2.4, 0.9), CF(0, -0.8, 0), G)
	for k = 0, 3 do p(m, V(3.4 - k * 0.9, 0.55, 0.9), CF(0, 0.6 + k * 0.5, 0), G) end
	p(m, V(0.5, 1.2, 0.95), CF(-0.3, -0.6, -0.05), rgb(170, 255, 180))
end
function B.pillar(m)
	local W, T = rgb(245, 240, 230), rgb(200, 190, 175)
	p(m, V(4.2, 0.5, 2.2), CF(0, 2, 0), T)
	wedge(m, V(4.2, 0.9, 1.1), CF(0, 2.7, -0.55), W)
	wedge(m, V(4.2, 0.9, 1.1), CF(0, 2.7, 0.55) * CFrame.Angles(0, math.pi, 0), W)
	for _, x in { -1.4, 0, 1.4 } do cyl(m, 0.8, 3.2, V(x, 0.1, 0), W, "y") end
	p(m, V(4.4, 0.5, 2.3), CF(0, -1.7, 0), T)
end
function B.book(m)
	p(m, V(3.2, 4, 0.9), CF(0, 0, 0), rgb(235, 90, 150))
	p(m, V(3, 3.8, 0.7), CF(0.12, 0, -0.05), rgb(255, 250, 240))
	p(m, V(0.35, 4.05, 0.95), CF(-1.62, 0, 0), rgb(190, 50, 110))
	p(m, V(2, 0.7, 0.1), CF(0.2, 0.9, -0.47), rgb(255, 210, 60))
	ball(m, 0.6, V(0.2, -0.5, -0.47), rgb(255, 210, 60))
end
function B.pencil(m)
	local tilt = CFrame.Angles(0, 0, math.rad(-40))
	p(m, V(0.9, 3.6, 0.9), tilt, rgb(255, 205, 50))
	p(m, V(0.92, 0.6, 0.92), tilt * CF(0, 2, 0), rgb(200, 200, 210))
	p(m, V(0.9, 0.7, 0.9), tilt * CF(0, 2.6, 0), rgb(255, 130, 150))
	wedge(m, V(0.9, 1, 0.9), tilt * CF(0, -2.3, 0) * CFrame.Angles(math.pi, 0, 0), rgb(240, 210, 170))
end
function B.gear(m)
	local G = rgb(170, 176, 195)
	cyl(m, 3, 0.9, V(0, 0, 0), G, "z")
	for k = 0, 7 do p(m, V(0.8, 0.8, 0.9), CF(math.cos(k * math.pi / 4) * 1.7, math.sin(k * math.pi / 4) * 1.7, 0) * CFrame.Angles(0, 0, k * math.pi / 4), G) end
	cyl(m, 1.1, 1, V(0, 0, 0), rgb(90, 96, 115), "z")
end
function B.calendar(m)
	p(m, V(3.4, 3.2, 0.5), CF(0, -0.3, 0), rgb(250, 248, 240))
	p(m, V(3.4, 1, 0.55), CF(0, 1.5, 0), rgb(235, 60, 70))
	for _, x in { -0.9, 0.9 } do p(m, V(0.3, 0.8, 0.3), CF(x, 2.1, 0), rgb(120, 125, 140)) end
	for r = 0, 1 do for c = 0, 2 do p(m, V(0.6, 0.5, 0.1), CF(-0.9 + c * 0.9, 0.4 - r * 0.8, -0.28), (r == 1 and c == 1) and rgb(255, 200, 50) or rgb(200, 205, 220)) end end
end
function B.wrench(m)
	local tilt = CFrame.Angles(0, 0, math.rad(45))
	local S = rgb(190, 196, 210)
	p(m, V(0.8, 3.6, 0.5), tilt, S)
	for _, s in { -1, 1 } do p(m, V(0.55, 1, 0.5), tilt * CF(s * 0.6, 2.1, 0), S) end
	p(m, V(1.2, 0.5, 0.5), tilt * CF(0, 1.5, 0), S)
	p(m, V(0.9, 1.2, 0.55), tilt * CF(0, -1.2, 0), rgb(235, 70, 70))
end
function B.people(m)
	for i, c in { { -1, rgb(80, 150, 255) }, { 1, rgb(255, 120, 170) } } do
		ball(m, 1.5, V(c[1] * 1, 1.1, 0), rgb(255, 214, 180))
		p(m, V(1.6, 1.8, 1), CF(c[1] * 1, -0.6, 0), c[2])
		_ = i
	end
end
function B.scroll(m)
	p(m, V(3, 3.4, 0.2), CF(0, 0, 0), rgb(245, 225, 180))
	for _, y in { 1.8, -1.8 } do cyl(m, 0.8, 3.6, V(0, y, 0), rgb(200, 160, 100), "x") end
	for k = 0, 2 do p(m, V(2.2, 0.2, 0.1), CF(0, 0.7 - k * 0.6, -0.12), rgb(150, 110, 70)) end
end

-- a top-secret VexCorp file folder (the Files book)
function B.folder(m)
	p(m, V(3.8, 2.8, 0.25), CF(0, 0, 0.1), rgb(215, 170, 95))
	p(m, V(1.4, 0.5, 0.25), CF(-1.1, 1.6, 0.1), rgb(215, 170, 95))
	p(m, V(3.4, 2.5, 0.1), CF(0.1, -0.05, -0.08), rgb(250, 248, 240))
	p(m, V(3.9, 2.7, 0.25), CF(0.15, -0.1, -0.25) * CFrame.Angles(0, 0, math.rad(-3)), rgb(240, 195, 115))
	p(m, V(3.2, 0.7, 0.1), CF(0.2, 0.1, -0.42) * CFrame.Angles(0, 0, math.rad(-12)), rgb(210, 40, 50))
	ball(m, 0.7, V(1.2, -0.8, -0.45), rgb(140, 60, 210))
end

-- the keys the store uses for its passes and products (Config keys -> icon)
Icons.FOR = {
	StarterPack = "gift", VIP = "crown", SuperSpeed = "sneaker", GoldenBoard = "goldboard", DiamondBoard = "gem",
	Luck = "clover", AutoCollect = "broom", LongLock = "padlock", TeleportHome = "house", OfflinePlus = "moon",
	MoneyBoost = "cash", Cash10m = "cash", Cash1h = "moneybag", Cash4h = "vault", LuckyBus = "bus",
	ServerLuck = "sparkle", ExpressRare = "letter", ExpressEpic = "letterEpic", LockRefresh = "refresh",
	UnlockDowntown = "shop", UnlockLab = "flask", UnlockMapleHeights = "maple", UnlockPinePark = "pine",
	UnlockVexPrep = "vexprep", UnlockIndustrial = "factory", UnlockLair = "skull",
}

-- the panels (by their names) -> icon
Icons.PANEL = {
	Shop = "apple", Upgrades = "upArrow", Board = "pillar", Prestige = "crown", Yearbook = "book",
	NameSchool = "pencil", Settings = "gear", Daily = "calendar", Admin = "wrench", Welcome = "cash",
	Coop = "people", QuestLogPanel = "scroll", Store = "basket",
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

-- the ones on screen sway and bob (a few dozen at most, ~30 times a second)
local live = setmetatable({}, { __mode = "k" }) -- viewport -> { model, sil, base, phase }
local acc = 0
RunService.RenderStepped:Connect(function(dt)
	acc += dt
	if acc < 1 / 30 then return end
	acc = 0
	local t = os.clock()
	for vp, st in live do
		if not vp.Parent then
			live[vp] = nil
		elseif vp.Visible and vp.AbsoluteSize.X > 0 then
			local a = math.sin(t * 1.3 + st.phase) * math.rad(st.sway)
			local cf = st.base * CFrame.new(0, math.sin(t * 2 + st.phase) * st.bob, 0) * CFrame.Angles(0, a, 0)
			st.model:PivotTo(cf)
			if st.sil then st.sil:PivotTo(st.silOffset * cf) end
		end
	end
end)

-- opts: size, position, anchor, zindex, sway (degrees, default 18), bob (studs, default 0.12), turn (a fixed
-- yaw in degrees, default -22), tilt (degrees towards the camera, default 12), outline (default true),
-- still (no motion)
function Icons.view(parent, key, opts)
	opts = opts or {}
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Icon"
	vp.BackgroundTransparency = 1
	vp.Size = opts.size or UDim2.fromScale(1, 1)
	vp.Position = opts.position or UDim2.new()
	vp.AnchorPoint = opts.anchor or Vector2.zero
	vp.ZIndex = opts.zindex or 14
	vp.Ambient = rgb(185, 185, 190)
	vp.LightColor = rgb(255, 255, 255)
	vp.LightDirection = Vector3.new(-0.6, -1, 0.8)
	local model = Icons.build(key)
	local base = CFrame.Angles(math.rad(opts.tilt or 12), math.rad(opts.turn or -22), 0)
	model:PivotTo(base)
	local cf, size = model:GetBoundingBox()
	local sil
	local silOffset = CFrame.new()
	if opts.outline ~= false then
		-- a flat dark copy a little bigger, just behind: reads as a thick outline round the icon
		sil = model:Clone()
		for _, d in sil:GetDescendants() do
			if d:IsA("BasePart") then
				d.Color = rgb(20, 18, 28)
				d.Material = Enum.Material.SmoothPlastic
			end
		end
		pcall(function() sil:ScaleTo(1.24) end)
		-- (far enough back that it doesn't show through the icon's own parts, big enough to show round it)
		silOffset = CFrame.new(0, 0, size.Z * 0.55)
		sil:PivotTo(silOffset * base)
		sil.Parent = vp
	end
	model.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	local r = math.max(size.X, size.Y) * 0.5 + 0.35
	local dist = r / math.tan(math.rad(15)) + size.Z * 0.5
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, 0, -dist), cf.Position)
	cam.Parent = vp
	vp.CurrentCamera = cam
	-- (the light comes from the camera's side)
	vp.Parent = parent
	if not opts.still then
		live[vp] = { model = model, sil = sil, silOffset = silOffset, base = base, phase = math.random() * 6, sway = opts.sway or 18, bob = opts.bob or 0.12 }
	end
	return vp
end

return Icons
