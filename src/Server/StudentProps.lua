-- ServerScriptService.Server.StudentProps
-- Part-built props that make each student recognisable. Everything is welded to a body part so it
-- follows the walk and sit animations.
local Props = {}

local function mk(model, shape, size, color, material)
	local p = Instance.new("Part")
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.Parent = model:FindFirstChild("Props") or (function()
		local f = Instance.new("Model")
		f.Name = "Props"
		f.Parent = model
		return f
	end)()
	return p
end

local function weld(p, to, offset)
	p.CFrame = to.CFrame * offset
	local w = Instance.new("Weld")
	w.Part0 = to
	w.Part1 = p
	w.C0 = offset
	w.Parent = p
	return p
end

-- block-ish helpers in the body part's space
local function block(model, to, size, offset, color, material)
	return weld(mk(model, Enum.PartType.Block, size, color, material), to, offset)
end
local function ball(model, to, d, offset, color, material)
	return weld(mk(model, Enum.PartType.Ball, Vector3.new(d, d, d), color, material), to, offset)
end
-- stretched sphere (SpecialMesh) for caps, hoods, footballs
local function blob(model, to, size, offset, color, material)
	local p = mk(model, Enum.PartType.Block, size, color, material)
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Sphere
	m.Parent = p
	return weld(p, to, offset)
end
-- cylinder whose axis runs along the offset's Y
local function cylY(model, to, d, len, offset, color, material)
	return weld(mk(model, Enum.PartType.Cylinder, Vector3.new(len, d, d), color, material), to, offset * CFrame.Angles(0, 0, math.rad(90)))
end
-- cylinder whose axis runs along the offset's Z (pointing forward/back)
local function cylZ(model, to, d, len, offset, color, material)
	return weld(mk(model, Enum.PartType.Cylinder, Vector3.new(len, d, d), color, material), to, offset * CFrame.Angles(0, math.rad(90), 0))
end

local HAIR = {
	SleepySam = Color3.fromRGB(120, 80, 50),
	CrayonEater = Color3.fromRGB(230, 170, 80),
	BackpackKid = Color3.fromRGB(30, 22, 18),
	NerdNed = Color3.fromRGB(110, 70, 40),
	HallMonitor = Color3.fromRGB(25, 20, 18),
	TeachersPet = Color3.fromRGB(200, 90, 40),
	SkaterKid = Color3.fromRGB(240, 210, 120),
	BandGeek = Color3.fromRGB(30, 22, 18),
	ScienceFair = Color3.fromRGB(240, 240, 240),
	ExchangeStudent = Color3.fromRGB(50, 35, 25),
	Valedictorian = Color3.fromRGB(30, 22, 18),
	CouncilPrez = Color3.fromRGB(160, 100, 50),
	LunchFavorite = Color3.fromRGB(200, 70, 50),
	PrincipalsNephew = Color3.fromRGB(250, 225, 140),
	KidGenius = Color3.fromRGB(90, 60, 40),
	WifiKid = Color3.fromRGB(60, 40, 30),
	Substitute = Color3.fromRGB(40, 30, 25),
}
-- props that replace the hair entirely
local NO_HAIR = { ClownNose = true, Football = true, Hoodie = true, Brain = true }

function Props.hair(model, def)
	if NO_HAIR[def.prop] then return end
	local head = model:FindFirstChild("Head")
	local hs = head.Size
	local c = HAIR[def.id] or Color3.fromRGB(70, 50, 35)
	-- a cap of hair over the crown and the back of the head
	blob(model, head, Vector3.new(hs.X * 1.1, hs.Y * 0.72, hs.Z * 1.14), CFrame.new(0, hs.Y * 0.2, hs.Z * 0.06), c)
	-- fringe
	block(model, head, Vector3.new(hs.X * 0.9, hs.Y * 0.14, hs.Z * 0.2), CFrame.new(0, hs.Y * 0.33, -hs.Z * 0.46) * CFrame.Angles(math.rad(-20), 0, 0), c)
end

local B = {}

B.Nightcap = function(model, head, hs)
	local blue, white = Color3.fromRGB(110, 150, 240), Color3.fromRGB(250, 250, 250)
	cylY(model, head, hs.X * 1.12, hs.Y * 0.22, CFrame.new(0, hs.Y * 0.36, 0.02), white)
	local cf = CFrame.new(0, hs.Y * 0.5, 0.05)
	local d = hs.X * 1.02
	for i = 1, 5 do
		local len = hs.Y * 0.28
		cf = cf * CFrame.Angles(math.rad(12), 0, math.rad(-6)) * CFrame.new(0, len * 0.5, 0)
		cylY(model, head, d, len, cf, blue)
		cf = cf * CFrame.new(0, len * 0.45, 0)
		d *= 0.74
	end
	ball(model, head, hs.X * 0.3, cf * CFrame.new(0, hs.X * 0.08, 0), white)
	-- closed sleepy eyes: two dark lines over the face decal
	for _, x in { -0.2, 0.2 } do
		block(model, head, Vector3.new(hs.X * 0.18, hs.Y * 0.035, 0.05), CFrame.new(hs.X * x, hs.Y * 0.06, -hs.Z * 0.5), Color3.fromRGB(40, 30, 30))
	end
	-- the pillow he carries
	local hand = model:FindFirstChild("RightHand")
	blob(model, hand, Vector3.new(0.5, 1.2, 1.7), CFrame.new(0.35, 0, 0), white)
end

B.Crayon = function(model, head, hs)
	local hand = model:FindFirstChild("RightHand")
	local orange = Color3.fromRGB(255, 120, 30)
	local c = cylY(model, hand, 0.32, 1.3, CFrame.new(0, 0.2, -0.2), orange)
	cylY(model, hand, 0.34, 0.6, CFrame.new(0, 0.2, -0.2), Color3.fromRGB(250, 250, 240))
	ball(model, hand, 0.26, CFrame.new(0, 0.9, -0.2), orange)
	-- the evidence: crayon smudge on his mouth
	block(model, head, Vector3.new(hs.X * 0.3, hs.Y * 0.08, 0.05), CFrame.new(hs.X * 0.05, -hs.Y * 0.22, -hs.Z * 0.5), orange)
	return c
end

B.Backpack = function(model, head, hs)
	local torso = model:FindFirstChild("UpperTorso")
	local ts = torso.Size
	local red, dark = Color3.fromRGB(220, 50, 50), Color3.fromRGB(140, 30, 30)
	-- comically big
	block(model, torso, Vector3.new(ts.X * 1.25, ts.Y * 1.6, ts.Z * 1.4), CFrame.new(0, ts.Y * 0.1, ts.Z * 1.15), red)
	block(model, torso, Vector3.new(ts.X * 0.9, ts.Y * 0.6, ts.Z * 0.35), CFrame.new(0, -ts.Y * 0.2, ts.Z * 1.95), dark)
	block(model, torso, Vector3.new(ts.X * 1.27, ts.Y * 0.1, ts.Z * 1.42), CFrame.new(0, ts.Y * 0.55, ts.Z * 1.15), Color3.fromRGB(255, 210, 60))
	for _, x in { -0.28, 0.28 } do
		block(model, torso, Vector3.new(ts.X * 0.14, ts.Y * 1.02, 0.08), CFrame.new(ts.X * x, 0, -ts.Z * 0.52), dark)
	end
end

B.ClownNose = function(model, head, hs)
	ball(model, head, hs.X * 0.3, CFrame.new(0, -hs.Y * 0.02, -hs.Z * 0.56), Color3.fromRGB(240, 30, 40))
	local colors = { Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 200, 40), Color3.fromRGB(60, 200, 255), Color3.fromRGB(90, 230, 90) }
	for side = -1, 1, 2 do
		for i, c in colors do
			ball(model, head, hs.X * 0.42, CFrame.new(side * hs.X * (0.5 + 0.06 * i), hs.Y * (0.35 - 0.1 * i), hs.Z * 0.05 * i), c)
		end
	end
	-- tiny party hat
	local hat = cylY(model, head, hs.X * 0.35, hs.Y * 0.45, CFrame.new(0, hs.Y * 0.68, 0) * CFrame.Angles(0, 0, math.rad(-10)), Color3.fromRGB(255, 80, 200))
	ball(model, head, hs.X * 0.16, CFrame.new(hs.X * 0.04, hs.Y * 0.95, 0), Color3.fromRGB(255, 240, 80))
	return hat
end

B.Glasses = function(model, head, hs)
	local black = Color3.fromRGB(20, 20, 25)
	for _, x in { -0.21, 0.21 } do
		cylZ(model, head, hs.X * 0.36, 0.08, CFrame.new(hs.X * x, hs.Y * 0.05, -hs.Z * 0.52), black)
		cylZ(model, head, hs.X * 0.28, 0.1, CFrame.new(hs.X * x, hs.Y * 0.05, -hs.Z * 0.52), Color3.fromRGB(220, 240, 255), Enum.Material.Glass).Transparency = 0.4
	end
	block(model, head, Vector3.new(hs.X * 0.12, 0.08, 0.08), CFrame.new(0, hs.Y * 0.06, -hs.Z * 0.53), Color3.fromRGB(245, 245, 245))
	-- pocket protector with pens
	local torso = model:FindFirstChild("UpperTorso")
	local ts = torso.Size
	block(model, torso, Vector3.new(ts.X * 0.28, ts.Y * 0.3, 0.06), CFrame.new(ts.X * 0.22, ts.Y * 0.12, -ts.Z * 0.52), Color3.fromRGB(230, 230, 240))
	for i, c in { Color3.fromRGB(30, 60, 200), Color3.fromRGB(220, 40, 40), Color3.fromRGB(30, 30, 30) } do
		block(model, torso, Vector3.new(0.06, ts.Y * 0.28, 0.06), CFrame.new(ts.X * (0.14 + 0.07 * i), ts.Y * 0.3, -ts.Z * 0.55), c)
	end
end

B.Sash = function(model, head, hs)
	local torso = model:FindFirstChild("UpperTorso")
	local ts = torso.Size
	local orange = Color3.fromRGB(255, 140, 20)
	local len = math.sqrt(ts.X ^ 2 + ts.Y ^ 2) * 1.05
	block(model, torso, Vector3.new(ts.X * 0.24, len, 0.06), CFrame.new(0, 0, -ts.Z * 0.53) * CFrame.Angles(0, 0, math.rad(-38)), orange, Enum.Material.Neon)
	block(model, torso, Vector3.new(ts.X * 0.24, len, 0.06), CFrame.new(0, 0, ts.Z * 0.53) * CFrame.Angles(0, 0, math.rad(38)), orange, Enum.Material.Neon)
	cylZ(model, torso, ts.X * 0.24, 0.1, CFrame.new(-ts.X * 0.22, ts.Y * 0.2, -ts.Z * 0.58), Color3.fromRGB(200, 200, 210), Enum.Material.Metal)
	-- whistle
	block(model, torso, Vector3.new(0.14, 0.14, 0.3), CFrame.new(ts.X * 0.12, -ts.Y * 0.05, -ts.Z * 0.62), Color3.fromRGB(200, 200, 210), Enum.Material.Metal)
end

B.Apple = function(model, head, hs)
	local hand = model:FindFirstChild("RightHand")
	ball(model, hand, 0.75, CFrame.new(0, -0.1, -0.45), Color3.fromRGB(220, 30, 40))
	block(model, hand, Vector3.new(0.06, 0.22, 0.06), CFrame.new(0, 0.33, -0.45), Color3.fromRGB(90, 60, 30))
	block(model, hand, Vector3.new(0.22, 0.04, 0.12), CFrame.new(0.1, 0.36, -0.45) * CFrame.Angles(0, 0, math.rad(25)), Color3.fromRGB(60, 190, 60))
	-- teacher's-pet bow in the hair
	local pink = Color3.fromRGB(255, 110, 170)
	for _, x in { -0.14, 0.14 } do
		block(model, head, Vector3.new(hs.X * 0.24, hs.Y * 0.2, hs.Z * 0.1), CFrame.new(hs.X * (0.3 + x), hs.Y * 0.5, 0) * CFrame.Angles(0, 0, math.rad(x > 0 and -20 or 20)), pink)
	end
	ball(model, head, hs.X * 0.12, CFrame.new(hs.X * 0.3, hs.Y * 0.5, 0), pink)
end

B.Skateboard = function(model, head, hs)
	local hand = model:FindFirstChild("RightHand")
	local board = block(model, hand, Vector3.new(0.14, 2.6, 0.8), CFrame.new(0.3, 0.4, 0), Color3.fromRGB(60, 60, 70))
	block(model, hand, Vector3.new(0.15, 1.2, 0.6), CFrame.new(0.3, 0.4, 0), Color3.fromRGB(255, 90, 40))
	for _, y in { -0.7, 1.5 } do
		for _, z in { -0.3, 0.3 } do
			cylZ(model, hand, 0.2, 0.12, CFrame.new(0.45, y, z) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(240, 240, 240))
		end
	end
	-- backwards cap
	local red = Color3.fromRGB(230, 50, 50)
	blob(model, head, Vector3.new(hs.X * 1.1, hs.Y * 0.62, hs.Z * 1.12), CFrame.new(0, hs.Y * 0.27, 0), red)
	block(model, head, Vector3.new(hs.X * 0.75, 0.08, hs.Z * 0.5), CFrame.new(0, hs.Y * 0.32, hs.Z * 0.65), red)
	return board
end

B.Trumpet = function(model, head, hs)
	local hand = model:FindFirstChild("RightHand")
	local gold = Color3.fromRGB(240, 190, 60)
	cylZ(model, hand, 0.14, 1.6, CFrame.new(0, 0, -0.7), gold, Enum.Material.Metal)
	cylZ(model, hand, 0.55, 0.3, CFrame.new(0, 0, -1.55), gold, Enum.Material.Metal)
	for i = -1, 1 do
		cylY(model, hand, 0.1, 0.35, CFrame.new(0, 0.2, -0.6 + i * 0.16), gold, Enum.Material.Metal)
	end
	-- marching-band hat with plume
	cylY(model, head, hs.X * 0.95, hs.Y * 0.6, CFrame.new(0, hs.Y * 0.62, 0), Color3.fromRGB(150, 30, 40))
	block(model, head, Vector3.new(hs.X * 0.5, 0.06, hs.Z * 0.3), CFrame.new(0, hs.Y * 0.36, -hs.Z * 0.55), Color3.fromRGB(20, 20, 20))
	blob(model, head, Vector3.new(hs.X * 0.25, hs.Y * 0.6, hs.Z * 0.25), CFrame.new(0, hs.Y * 1.15, 0), Color3.fromRGB(250, 250, 250))
end

B.Football = function(model, head, hs)
	local red, grey = Color3.fromRGB(220, 50, 40), Color3.fromRGB(200, 200, 200)
	blob(model, head, Vector3.new(hs.X * 1.25, hs.Y * 1.15, hs.Z * 1.3), CFrame.new(0, hs.Y * 0.12, hs.Z * 0.05), red)
	block(model, head, Vector3.new(hs.X * 0.12, hs.Y * 0.1, hs.Z * 1.2), CFrame.new(0, hs.Y * 0.62, hs.Z * 0.05), Color3.fromRGB(250, 250, 250))
	for _, y in { -0.05, -0.25 } do
		cylY(model, head, 0.08, hs.X * 0.9, CFrame.new(0, hs.Y * y, -hs.Z * 0.66) * CFrame.Angles(0, 0, math.rad(90)), grey, Enum.Material.Metal)
	end
	local hand = model:FindFirstChild("RightHand")
	blob(model, hand, Vector3.new(0.65, 0.65, 1.1), CFrame.new(0.1, 0, -0.35), Color3.fromRGB(130, 70, 35))
	block(model, hand, Vector3.new(0.05, 0.05, 0.45), CFrame.new(0.1, 0.32, -0.35), Color3.fromRGB(250, 250, 250))
end

B.Goggles = function(model, head, hs)
	cylY(model, head, hs.X * 1.08, hs.Y * 0.14, CFrame.new(0, hs.Y * 0.28, 0), Color3.fromRGB(30, 30, 35))
	for _, x in { -0.2, 0.2 } do
		cylZ(model, head, hs.X * 0.36, 0.22, CFrame.new(hs.X * x, hs.Y * 0.3, -hs.Z * 0.54), Color3.fromRGB(60, 60, 70))
		cylZ(model, head, hs.X * 0.28, 0.24, CFrame.new(hs.X * x, hs.Y * 0.3, -hs.Z * 0.54), Color3.fromRGB(120, 255, 170), Enum.Material.Glass).Transparency = 0.3
	end
	-- bubbling flask
	local hand = model:FindFirstChild("RightHand")
	cylY(model, hand, 0.5, 0.7, CFrame.new(0, 0.15, -0.35), Color3.fromRGB(220, 240, 255), Enum.Material.Glass).Transparency = 0.5
	cylY(model, hand, 0.44, 0.45, CFrame.new(0, 0.05, -0.35), Color3.fromRGB(80, 255, 120), Enum.Material.Neon)
	cylY(model, hand, 0.2, 0.4, CFrame.new(0, 0.65, -0.35), Color3.fromRGB(220, 240, 255), Enum.Material.Glass).Transparency = 0.5
	-- lab coat tails
	local lower = model:FindFirstChild("LowerTorso")
	local ls = lower.Size
	block(model, lower, Vector3.new(ls.X * 1.12, ls.Y * 2.6, ls.Z * 1.15), CFrame.new(0, -ls.Y * 0.8, ls.Z * 0.05), Color3.fromRGB(250, 250, 250))
end

B.Suitcase = function(model, head, hs)
	local hand = model:FindFirstChild("RightHand")
	local brown = Color3.fromRGB(140, 90, 50)
	block(model, hand, Vector3.new(0.45, 1.2, 1.7), CFrame.new(0.2, -0.75, 0), brown)
	block(model, hand, Vector3.new(0.12, 0.25, 0.6), CFrame.new(0.2, -0.05, 0), Color3.fromRGB(60, 40, 25))
	for i, c in { Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 160, 255), Color3.fromRGB(255, 220, 60) } do
		block(model, hand, Vector3.new(0.47, 0.28, 0.35), CFrame.new(0.2, -0.5 - 0.25 * (i % 2), -0.55 + 0.4 * i), c)
	end
	-- beret
	blob(model, head, Vector3.new(hs.X * 1.15, hs.Y * 0.3, hs.Z * 1.15), CFrame.new(hs.X * 0.08, hs.Y * 0.48, 0) * CFrame.Angles(0, 0, math.rad(-12)), Color3.fromRGB(200, 30, 50))
end

B.GradCap = function(model, head, hs)
	local black = Color3.fromRGB(25, 25, 30)
	cylY(model, head, hs.X * 1.05, hs.Y * 0.3, CFrame.new(0, hs.Y * 0.42, 0), black)
	block(model, head, Vector3.new(hs.X * 1.6, 0.1, hs.X * 1.6), CFrame.new(0, hs.Y * 0.6, 0) * CFrame.Angles(0, math.rad(45), 0), black)
	ball(model, head, 0.16, CFrame.new(0, hs.Y * 0.66, 0), Color3.fromRGB(255, 200, 40))
	block(model, head, Vector3.new(0.06, 0.06, hs.X * 0.6), CFrame.new(hs.X * 0.3, hs.Y * 0.64, -hs.X * 0.3) * CFrame.Angles(0, math.rad(45), 0), Color3.fromRGB(255, 200, 40))
	block(model, head, Vector3.new(0.1, hs.Y * 0.4, 0.1), CFrame.new(hs.X * 0.55, hs.Y * 0.42, -hs.X * 0.55), Color3.fromRGB(255, 200, 40))
	-- diploma
	local hand = model:FindFirstChild("RightHand")
	cylZ(model, hand, 0.3, 1.2, CFrame.new(0, -0.1, -0.2), Color3.fromRGB(250, 245, 225))
	cylZ(model, hand, 0.32, 0.12, CFrame.new(0, -0.1, -0.2), Color3.fromRGB(220, 30, 40))
end

B.Gavel = function(model, head, hs)
	local hand = model:FindFirstChild("RightHand")
	local wood = Color3.fromRGB(120, 70, 35)
	cylY(model, hand, 0.14, 1.1, CFrame.new(0, 0.35, -0.1), wood, Enum.Material.Wood)
	cylZ(model, hand, 0.42, 0.85, CFrame.new(0, 0.95, -0.1), wood, Enum.Material.Wood)
	-- PREZ badge
	local torso = model:FindFirstChild("UpperTorso")
	local ts = torso.Size
	cylZ(model, torso, ts.X * 0.3, 0.08, CFrame.new(-ts.X * 0.22, ts.Y * 0.18, -ts.Z * 0.54), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
	-- tie
	block(model, torso, Vector3.new(ts.X * 0.14, ts.Y * 0.75, 0.06), CFrame.new(0, -ts.Y * 0.05, -ts.Z * 0.53), Color3.fromRGB(200, 30, 40))
end

B.LunchTray = function(model, head, hs)
	local torso = model:FindFirstChild("UpperTorso")
	local ts = torso.Size
	local tray = block(model, torso, Vector3.new(ts.X * 1.3, 0.12, ts.Z * 2.2), CFrame.new(0, -ts.Y * 0.35, -ts.Z * 1.5), Color3.fromRGB(170, 175, 185), Enum.Material.Metal)
	local top = -ts.Y * 0.35 + 0.06
	for i = 0, 4 do
		ball(model, torso, 0.2, CFrame.new(-ts.X * 0.35 + (i % 3) * 0.16, top + 0.1, -ts.Z * 1.2 - math.floor(i / 3) * 0.16), Color3.fromRGB(90, 190, 60))
	end
	block(model, torso, Vector3.new(0.6, 0.3, 0.45), CFrame.new(ts.X * 0.2, top + 0.15, -ts.Z * 1.25), Color3.fromRGB(130, 75, 40))
	blob(model, torso, Vector3.new(0.5, 0.35, 0.5), CFrame.new(-ts.X * 0.25, top + 0.16, -ts.Z * 1.85), Color3.fromRGB(250, 240, 200))
	block(model, torso, Vector3.new(0.3, 0.5, 0.3), CFrame.new(ts.X * 0.35, top + 0.25, -ts.Z * 1.85), Color3.fromRGB(250, 250, 250))
	weld(mk(model, Enum.PartType.Block, Vector3.new(0.3, 0.2, 0.3), Color3.fromRGB(60, 120, 230)), torso, CFrame.new(ts.X * 0.35, top + 0.58, -ts.Z * 1.85))
	-- hairnet-adjacent chef hat, lunch-lady approved
	cylY(model, head, hs.X * 0.9, hs.Y * 0.35, CFrame.new(0, hs.Y * 0.55, 0), Color3.fromRGB(250, 250, 250))
	blob(model, head, Vector3.new(hs.X * 1.2, hs.Y * 0.55, hs.Z * 1.2), CFrame.new(0, hs.Y * 0.85, 0), Color3.fromRGB(250, 250, 250))
	return tray
end

B.ShadesTie = function(model, head, hs)
	local black = Color3.fromRGB(15, 15, 20)
	for _, x in { -0.21, 0.21 } do
		block(model, head, Vector3.new(hs.X * 0.34, hs.Y * 0.2, 0.08), CFrame.new(hs.X * x, hs.Y * 0.06, -hs.Z * 0.53), black, Enum.Material.Glass).Reflectance = 0.3
	end
	block(model, head, Vector3.new(hs.X * 0.95, 0.07, 0.08), CFrame.new(0, hs.Y * 0.15, -hs.Z * 0.53), black)
	local torso = model:FindFirstChild("UpperTorso")
	local ts = torso.Size
	block(model, torso, Vector3.new(ts.X * 0.18, ts.Y * 0.8, 0.06), CFrame.new(0, -ts.Y * 0.08, -ts.Z * 0.53), Color3.fromRGB(200, 20, 30))
	block(model, torso, Vector3.new(ts.X * 0.22, ts.Y * 0.14, 0.1), CFrame.new(0, ts.Y * 0.36, -ts.Z * 0.55), Color3.fromRGB(160, 10, 20))
	-- the gold chain he definitely did not earn
	local len = ts.X * 0.55
	for _, a in { -35, 35 } do
		block(model, torso, Vector3.new(0.08, len, 0.08), CFrame.new(ts.X * (a > 0 and 0.18 or -0.18), ts.Y * 0.18, -ts.Z * 0.56) * CFrame.Angles(0, 0, math.rad(a)), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
	end
	-- blazer
	block(model, torso, Vector3.new(ts.X * 1.06, ts.Y * 1.02, ts.Z * 1.06), CFrame.new(0, 0, 0.02), Color3.fromRGB(30, 30, 60)).Transparency = 0
	-- shirt V visible in front of the blazer
	block(model, torso, Vector3.new(ts.X * 0.34, ts.Y * 0.9, 0.04), CFrame.new(0, 0, -ts.Z * 0.54), Color3.fromRGB(245, 245, 250))
end

B.Brain = function(model, head, hs)
	local pink = Color3.fromRGB(255, 130, 180)
	local b1 = blob(model, head, Vector3.new(hs.X * 0.62, hs.Y * 0.45, hs.Z * 0.95), CFrame.new(-hs.X * 0.2, hs.Y * 0.45, 0), pink, Enum.Material.Neon)
	blob(model, head, Vector3.new(hs.X * 0.62, hs.Y * 0.45, hs.Z * 0.95), CFrame.new(hs.X * 0.2, hs.Y * 0.45, 0), pink, Enum.Material.Neon)
	block(model, head, Vector3.new(hs.X * 0.04, hs.Y * 0.3, hs.Z * 0.8), CFrame.new(0, hs.Y * 0.52, 0), Color3.fromRGB(200, 60, 120))
	local light = Instance.new("PointLight")
	light.Color = pink
	light.Range = 10
	light.Brightness = 2
	light.Parent = b1
	-- round glasses too, obviously
	for _, x in { -0.2, 0.2 } do
		cylZ(model, head, hs.X * 0.3, 0.06, CFrame.new(hs.X * x, hs.Y * 0.0, -hs.Z * 0.52), Color3.fromRGB(30, 30, 30))
	end
end

B.Hoodie = function(model, head, hs)
	local black = Color3.fromRGB(22, 22, 26)
	blob(model, head, Vector3.new(hs.X * 1.3, hs.Y * 1.25, hs.Z * 1.25), CFrame.new(0, hs.Y * 0.08, hs.Z * 0.14), black)
	-- face in shadow, only the eyes
	local face = head:FindFirstChildOfClass("Decal")
	if face then face.Transparency = 1 end
	block(model, head, Vector3.new(hs.X * 0.9, hs.Y * 0.8, 0.05), CFrame.new(0, -hs.Y * 0.02, -hs.Z * 0.5), Color3.fromRGB(10, 10, 12))
	for _, x in { -0.18, 0.18 } do
		ball(model, head, hs.X * 0.13, CFrame.new(hs.X * x, hs.Y * 0.05, -hs.Z * 0.54), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
	end
	local torso = model:FindFirstChild("UpperTorso")
	local ts = torso.Size
	block(model, torso, Vector3.new(ts.X * 0.5, ts.Y * 0.3, 0.06), CFrame.new(0, -ts.Y * 0.2, -ts.Z * 0.53), Color3.fromRGB(35, 35, 40))
end

B.Router = function(model, head, hs)
	local black = Color3.fromRGB(25, 25, 30)
	block(model, head, Vector3.new(hs.X * 1.1, hs.Y * 0.28, hs.Z * 0.8), CFrame.new(0, hs.Y * 0.64, 0), black)
	for _, x in { -0.38, 0.38 } do
		cylY(model, head, 0.1, hs.Y * 0.9, CFrame.new(hs.X * x, hs.Y * 1.1, hs.Z * 0.2) * CFrame.Angles(0, 0, math.rad(x > 0 and -12 or 12)), black)
	end
	for i = -2, 2 do
		ball(model, head, 0.1, CFrame.new(hs.X * 0.16 * i, hs.Y * 0.62, -hs.Z * 0.41), i == 2 and Color3.fromRGB(80, 170, 255) or Color3.fromRGB(80, 255, 110), Enum.Material.Neon)
	end
	-- the sticky note with the password
	block(model, head, Vector3.new(hs.X * 0.3, hs.Y * 0.2, 0.04), CFrame.new(-hs.X * 0.28, hs.Y * 0.64, -hs.Z * 0.42), Color3.fromRGB(255, 240, 90))
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(2.2, 0, 1.2, 0)
	bb.StudsOffsetWorldSpace = Vector3.new(0, hs.Y * 1.8, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 60
	bb.Parent = head
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = "WiFi"
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(80, 200, 255)
	t.Parent = bb
end

B.Trenchcoat = function(model, head, hs)
	local coat = Color3.fromRGB(150, 110, 60)
	local torso = model:FindFirstChild("UpperTorso")
	local lower = model:FindFirstChild("LowerTorso")
	local ts, ls = torso.Size, lower.Size
	block(model, torso, Vector3.new(ts.X * 1.12, ts.Y * 1.05, ts.Z * 1.2), CFrame.new(0, 0, 0), coat)
	block(model, lower, Vector3.new(ls.X * 1.18, ls.Y * 4.2, ls.Z * 1.25), CFrame.new(0, -ls.Y * 1.5, 0), coat)
	-- collar
	for _, x in { -0.3, 0.3 } do
		block(model, torso, Vector3.new(ts.X * 0.3, ts.Y * 0.3, 0.12), CFrame.new(ts.X * x, ts.Y * 0.42, -ts.Z * 0.62) * CFrame.Angles(math.rad(-15), 0, 0), Color3.fromRGB(120, 85, 45))
	end
	block(model, lower, Vector3.new(ls.X * 1.2, ls.Y * 0.3, ls.Z * 1.27), CFrame.new(0, 0, 0), Color3.fromRGB(60, 40, 20))
	-- the second kid, peeking out between the buttons
	for _, x in { -0.13, 0.13 } do
		ball(model, lower, ls.X * 0.2, CFrame.new(ls.X * x, -ls.Y * 1.1, -ls.Z * 0.63), Color3.fromRGB(250, 250, 250))
		ball(model, lower, ls.X * 0.09, CFrame.new(ls.X * x, -ls.Y * 1.1, -ls.Z * 0.72), Color3.fromRGB(10, 10, 10))
	end
	-- fedora and a very fake moustache
	cylY(model, head, hs.X * 1.6, 0.1, CFrame.new(0, hs.Y * 0.42, 0), Color3.fromRGB(90, 60, 30))
	cylY(model, head, hs.X * 0.95, hs.Y * 0.45, CFrame.new(0, hs.Y * 0.62, 0), Color3.fromRGB(90, 60, 30))
	block(model, head, Vector3.new(hs.X * 1.0, hs.Y * 0.06, hs.Z * 1.0), CFrame.new(0, hs.Y * 0.5, 0), Color3.fromRGB(30, 20, 15))
	block(model, head, Vector3.new(hs.X * 0.5, hs.Y * 0.1, 0.1), CFrame.new(0, -hs.Y * 0.12, -hs.Z * 0.53), Color3.fromRGB(30, 20, 15))
end

function Props.add(model, def)
	local build = B[def.prop]
	if not build then return end
	local head = model:FindFirstChild("Head")
	build(model, head, head.Size)
end

local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"

function Props.gradeAura(model, grade)
	local hrp = model.PrimaryPart
	local e = Instance.new("ParticleEmitter")
	e.Name = "GradeAura"
	e.Texture = SPARKLE
	e.Rate = 6
	e.Lifetime = NumberRange.new(0.8, 1.4)
	e.Speed = NumberRange.new(0.5, 1.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new(0.5, 0)
	e.LightEmission = 1
	e.Color = grade.rainbow and ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 220)),
	}) or ColorSequence.new(grade.color)
	e.Parent = hrp
	local h = Instance.new("Highlight")
	h.Name = "GradeGlow"
	h.FillTransparency = 0.75
	h.FillColor = grade.color
	h.OutlineColor = grade.color
	h.OutlineTransparency = 0.2
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = model
end

function Props.rarityAura(model, def)
	local order = ({ Legendary = 5, Mythic = 6, Secret = 7 })[def.rarity]
	if not order then return end
	local hrp = model.PrimaryPart
	local color = ({ Legendary = Color3.fromRGB(255, 190, 40), Mythic = Color3.fromRGB(255, 60, 100), Secret = Color3.fromRGB(255, 255, 255) })[def.rarity]
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 12
	light.Brightness = 1.5
	light.Parent = hrp
	if order >= 6 then
		local e = Instance.new("ParticleEmitter")
		e.Name = "RarityAura"
		e.Texture = SPARKLE
		e.Rate = 12
		e.Lifetime = NumberRange.new(1, 1.6)
		e.Speed = NumberRange.new(1, 2)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Size = NumberSequence.new(0.7, 0)
		e.LightEmission = 1
		e.Color = ColorSequence.new(color)
		e.Parent = hrp
	end
end

return Props
