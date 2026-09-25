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

-- thin wire glasses: round rims built from short segments, a clear lens, a bridge.
-- (a solid disc behind a lens reads as sunglasses or black eyes from any distance)
local function wireGlasses(model, head, hs, y, radius, color)
	local frame = color or Color3.fromRGB(25, 25, 30)
	local r = hs.X * (radius or 0.15)
	for _, x in { -0.21, 0.21 } do
		local c = CFrame.new(hs.X * x, hs.Y * (y or 0.05), -hs.Z * 0.53)
		for i = 0, 9 do
			local a = math.rad(i * 36)
			block(model, head, Vector3.new(r * 0.66, 0.05, 0.05), c * CFrame.Angles(0, 0, a) * CFrame.new(0, r, 0), frame)
		end
		local lens = cylZ(model, head, r * 1.9, 0.02, c, Color3.fromRGB(225, 240, 255), Enum.Material.Glass)
		lens.Transparency = 0.8
	end
	block(model, head, Vector3.new(hs.X * 0.12, 0.05, 0.05), CFrame.new(0, hs.Y * (y or 0.05), -hs.Z * 0.54), frame)
end

local HAIR = {
	UntiedTyler = Color3.fromRGB(230, 180, 90),
	GlueStickGus = Color3.fromRGB(30, 22, 18),
	DoodleDot = Color3.fromRGB(200, 90, 60),
	LunchboxLucy = Color3.fromRGB(25, 20, 18),
	PajamaPete = Color3.fromRGB(150, 100, 60),
	HiccupHank = Color3.fromRGB(90, 60, 40),
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
	JuiceBoxJake = Color3.fromRGB(200, 120, 50),
	BubbleGumBetty = Color3.fromRGB(255, 120, 190),
	PencilChewer = Color3.fromRGB(20, 16, 14),
	SneezySid = Color3.fromRGB(150, 100, 60),
	FidgetFred = Color3.fromRGB(25, 20, 18),
	ShowAndTellSally = Color3.fromRGB(230, 140, 40),
	GamerGabe = Color3.fromRGB(60, 200, 120),
	TheaterKid = Color3.fromRGB(30, 22, 18),
	Mathlete = Color3.fromRGB(20, 16, 14),
	CheerCaptain = Color3.fromRGB(250, 220, 120),
	ArtsyAva = Color3.fromRGB(80, 50, 160),
	ChessChampion = Color3.fromRGB(110, 70, 40),
	SpellingBee = Color3.fromRGB(25, 20, 18),
	RoboticsKid = Color3.fromRGB(200, 90, 40),
	Photographer = Color3.fromRGB(25, 20, 18),
	DramaQueen = Color3.fromRGB(250, 200, 90),
	PromKing = Color3.fromRGB(25, 20, 18),
	DanceDJ = Color3.fromRGB(150, 60, 230),
	HallOfFame = Color3.fromRGB(25, 20, 18),
	MoustacheKid = Color3.fromRGB(90, 60, 40),
	Room13Ghost = Color3.fromRGB(240, 245, 255),
	TimeTraveler = Color3.fromRGB(240, 200, 120),
	RocketKid = Color3.fromRGB(200, 90, 40),
	TinyProfessor = Color3.fromRGB(235, 235, 240),
	PopStarKid = Color3.fromRGB(255, 90, 200),
	ChessGrandmaster = Color3.fromRGB(20, 16, 14),
	ChildCEO = Color3.fromRGB(250, 225, 140),
	SnowDayOracle = Color3.fromRGB(240, 240, 255),
	HomeworkReminder = Color3.fromRGB(20, 16, 14),
	Student404 = Color3.fromRGB(30, 30, 30),
	GraduateGrandpa = Color3.fromRGB(210, 210, 215),
	ClassOf99 = Color3.fromRGB(90, 60, 40),
	HeadPrefect = Color3.fromRGB(60, 40, 30),
	TheFounder = Color3.fromRGB(150, 110, 70),
	TinyPrincipal = Color3.fromRGB(40, 30, 25),
}
-- props that replace the hair entirely
local NO_HAIR = { ClownNose = true, Football = true, Hoodie = true, Brain = true, MascotHead = true, SlimeDealer = true }

function Props.hair(model, def)
	if NO_HAIR[def.prop] then return end
	local head = model:FindFirstChild("Head")
	local hs = head.Size
	local c = HAIR[def.id] or Color3.fromRGB(70, 50, 35)
	-- a cap of hair over the crown and the back of the head
	blob(model, head, Vector3.new(hs.X * 1.1, hs.Y * 0.72, hs.Z * 1.14), CFrame.new(0, hs.Y * 0.2, hs.Z * 0.06), c)
	-- fringe: a squashed sphere hugging the forehead (a flat block read as a cap brim)
	blob(model, head, Vector3.new(hs.X * 1.0, hs.Y * 0.3, hs.Z * 0.45), CFrame.new(0, hs.Y * 0.32, -hs.Z * 0.3), c)
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
	local w, h = hs.X * 0.34, hs.Y * 0.26
	for _, x in { -0.21, 0.21 } do
		local c = CFrame.new(hs.X * x, hs.Y * 0.05, -hs.Z * 0.53)
		block(model, head, Vector3.new(w, 0.06, 0.06), c * CFrame.new(0, h / 2, 0), black)
		block(model, head, Vector3.new(w, 0.06, 0.06), c * CFrame.new(0, -h / 2, 0), black)
		block(model, head, Vector3.new(0.06, h, 0.06), c * CFrame.new(w / 2, 0, 0), black)
		block(model, head, Vector3.new(0.06, h, 0.06), c * CFrame.new(-w / 2, 0, 0), black)
		block(model, head, Vector3.new(w, h, 0.02), c, Color3.fromRGB(220, 240, 255), Enum.Material.Glass).Transparency = 0.75
	end
	-- the famous tape on the bridge
	block(model, head, Vector3.new(hs.X * 0.1, 0.12, 0.09), CFrame.new(0, hs.Y * 0.05, -hs.Z * 0.54), Color3.fromRGB(245, 245, 245))
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
	local pink, fold = Color3.fromRGB(255, 140, 185), Color3.fromRGB(215, 85, 140)
	-- one dome over the whole top of his head: the skull is open and the brain is showing
	local dome = Vector3.new(hs.X * 1.14, hs.Y * 0.78, hs.Z * 1.16)
	local centre = CFrame.new(0, hs.Y * 0.36, hs.Z * 0.02)
	local b1 = blob(model, head, dome, centre, pink)
	-- folds: small darker lumps pressed into the dome's surface in two rows per side
	for _, x in { -1, 1 } do
		for row = 0, 1 do
			for i = 0, 3 do
				local lat = math.rad(25 + row * 30) -- angle down from the top
				local lon = math.rad(-60 + i * 40) -- front to back
				local dir = Vector3.new(x * math.sin(lat), math.cos(lat), math.sin(lon) * 0.9)
				local pos = Vector3.new(dir.X * dome.X / 2, dir.Y * dome.Y / 2, dir.Z * dome.Z / 2) * 0.93
				blob(model, head, Vector3.new(hs.X * 0.3, hs.Y * 0.12, hs.Z * 0.22), centre * CFrame.lookAt(pos, pos + dir) * CFrame.Angles(math.rad(90), 0, 0), fold)
			end
		end
	end
	-- the groove down the middle
	block(model, head, Vector3.new(0.1, hs.Y * 0.12, hs.Z * 1.05), centre * CFrame.new(0, dome.Y / 2 - hs.Y * 0.03, 0), fold)
	local light = Instance.new("PointLight")
	light.Color = pink
	light.Range = 6
	light.Brightness = 0.5
	light.Parent = b1
	wireGlasses(model, head, hs, 0.02, 0.15)
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

---------------------------------------------------------------------------
-- roster v2 (GAME-PLAN section 4)
---------------------------------------------------------------------------
local CollectionService = game:GetService("CollectionService")
local rgb = Color3.fromRGB

-- cylinder along the offset's X (the Cylinder shape's own axis)
local function cylX(model, to, d, len, offset, color, material)
	return weld(mk(model, Enum.PartType.Cylinder, Vector3.new(len, d, d), color, material), to, offset)
end
-- an invisible part welded to `to`; parts welded to it turn with it when the client Effects script
-- spins it around its own Y axis (tag "Spin", attribute SpinSpeed in degrees per second)
local function pivot(model, to, offset, speed)
	local p = weld(mk(model, Enum.PartType.Block, Vector3.new(0.1, 0.1, 0.1), rgb(255, 255, 255)), to, offset)
	p.Name = "SpinPivot"
	p.Transparency = 1
	p:SetAttribute("SpinSpeed", speed)
	CollectionService:AddTag(p, "Spin")
	return p
end
local function part(model, name)
	return model:FindFirstChild(name)
end
local function sparkles(p, color, rate)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Rate = rate or 8
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Speed = NumberRange.new(0.5, 1.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new(0.4, 0)
	e.LightEmission = 1
	e.Color = ColorSequence.new(color)
	e.Parent = p
	return e
end

-- Dealers (NPCs that sneak into schools) --------------------------------
B.CandyDealer = function(model, head, hs)
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	local coat = rgb(130, 95, 60)
	-- trench coat hanging open, candy pinned to the lining
	for _, x in { -1, 1 } do
		block(model, torso, Vector3.new(ts.X * 0.34, ts.Y * 1.05, ts.Z * 1.12), CFrame.new(x * ts.X * 0.36, 0, 0.02), coat)
		local lower = part(model, "LowerTorso")
		block(model, lower, Vector3.new(ts.X * 0.34, ts.Y * 1.5, ts.Z * 1.1), CFrame.new(x * ts.X * 0.36, -ts.Y * 0.55, 0.02), coat)
		for i = 0, 3 do
			local c = ({ rgb(255, 60, 90), rgb(90, 200, 255), rgb(255, 210, 60), rgb(130, 230, 90) })[(i + (x > 0 and 2 or 0)) % 4 + 1]
			ball(model, torso, 0.28, CFrame.new(x * ts.X * 0.26, ts.Y * (0.3 - i * 0.28), -ts.Z * 0.6), c)
		end
	end
	block(model, torso, Vector3.new(ts.X * 0.9, ts.Y * 0.14, ts.Z * 1.14), CFrame.new(0, ts.Y * 0.45, 0.02), coat:Lerp(Color3.new(0, 0, 0), 0.2))
	-- fedora and shades
	cylY(model, head, hs.X * 1.5, 0.12, CFrame.new(0, hs.Y * 0.42, 0), rgb(50, 40, 35))
	cylY(model, head, hs.X * 0.95, hs.Y * 0.4, CFrame.new(0, hs.Y * 0.62, 0), rgb(50, 40, 35))
	cylY(model, head, hs.X * 0.97, hs.Y * 0.1, CFrame.new(0, hs.Y * 0.48, 0), rgb(200, 40, 60))
	block(model, head, Vector3.new(hs.X * 0.8, hs.Y * 0.16, 0.08), CFrame.new(0, hs.Y * 0.07, -hs.Z * 0.52), rgb(20, 20, 25))
	-- a giant lollipop
	local hand = part(model, "RightHand")
	cylY(model, hand, 0.1, 1.4, CFrame.new(0, 0.6, -0.2), rgb(250, 250, 250))
	local pop = cylZ(model, hand, 1.1, 0.2, CFrame.new(0, 1.5, -0.2), rgb(255, 80, 170))
	cylZ(model, hand, 0.6, 0.22, CFrame.new(0, 1.5, -0.2), rgb(255, 255, 255))
	_ = pop
end

B.SlimeDealer = function(model, head, hs)
	local green = rgb(90, 255, 120)
	-- hoodie up
	blob(model, head, Vector3.new(hs.X * 1.25, hs.Y * 1.05, hs.Z * 1.25), CFrame.new(0, hs.Y * 0.12, hs.Z * 0.12), rgb(50, 170, 80))
	block(model, head, Vector3.new(hs.X * 0.3, hs.Y * 0.08, 0.06), CFrame.new(hs.X * 0.05, -hs.Y * 0.22, -hs.Z * 0.5), rgb(40, 40, 40))
	-- jar of glowing slime
	local hand = part(model, "RightHand")
	local jar = cylY(model, hand, 1, 1.1, CFrame.new(0, 0.25, -0.5), rgb(220, 255, 230), Enum.Material.Glass)
	jar.Transparency = 0.45
	cylY(model, hand, 0.9, 0.7, CFrame.new(0, 0.1, -0.5), green, Enum.Material.Neon)
	cylY(model, hand, 1.05, 0.2, CFrame.new(0, 0.85, -0.5), rgb(80, 80, 90))
	sparkles(jar, rgb(150, 255, 150), 5)
	-- slime drips on the shoes and a splat on the head
	for _, side in { "LeftFoot", "RightFoot" } do
		local f = part(model, side)
		if f then blob(model, f, Vector3.new(f.Size.X * 0.9, 0.2, f.Size.Z * 0.6), CFrame.new(0, f.Size.Y * 0.45, -f.Size.Z * 0.2), green, Enum.Material.Neon) end
	end
	blob(model, head, Vector3.new(hs.X * 0.6, hs.Y * 0.25, hs.X * 0.6), CFrame.new(-hs.X * 0.15, hs.Y * 0.62, 0), green, Enum.Material.Neon)
end

-- Common ----------------------------------------------------------------
-- starter students (the cheapest on the bus)
B.Shoelaces = function(model, head, hs)
	-- bright sneakers with long untied laces trailing on the floor
	for _, side in { "Left", "Right" } do
		local foot = part(model, side .. "Foot")
		if foot then
			local fs = foot.Size
			block(model, foot, Vector3.new(fs.X * 1.1, fs.Y * 0.6, fs.Z * 1.15), CFrame.new(0, -fs.Y * 0.2, -fs.Z * 0.05), rgb(250, 250, 250))
			block(model, foot, Vector3.new(fs.X * 1.12, fs.Y * 0.2, fs.Z * 1.17), CFrame.new(0, -fs.Y * 0.42, -fs.Z * 0.05), rgb(230, 60, 60))
			local x = side == "Left" and -1 or 1
			for i = 0, 1 do
				block(model, foot, Vector3.new(0.05, 0.05, 0.9), CFrame.new(x * fs.X * (0.2 + i * 0.25), -fs.Y * 0.45, -fs.Z * 0.9) * CFrame.Angles(0, math.rad(x * (10 + i * 25)), 0), rgb(255, 255, 255))
			end
		end
	end
	-- a plaster on the knee from the last trip
	local leg = part(model, "RightLowerLeg")
	if leg then block(model, leg, Vector3.new(leg.Size.X * 0.6, leg.Size.Y * 0.2, 0.06), CFrame.new(0, leg.Size.Y * 0.3, -leg.Size.Z * 0.52), rgb(245, 200, 160)) end
end

B.GlueStick = function(model, head, hs)
	local hand = part(model, "RightHand")
	cylY(model, hand, 0.45, 1.3, CFrame.new(0, 0.35, -0.25), rgb(150, 70, 220))
	cylY(model, hand, 0.47, 0.35, CFrame.new(0, 1.1, -0.25), rgb(250, 250, 250))
	cylY(model, hand, 0.38, 0.15, CFrame.new(0, 1.33, -0.25), rgb(240, 240, 230))
	-- glue on his fingers and his chin
	blob(model, hand, Vector3.new(0.5, 0.2, 0.5), CFrame.new(0, -0.3, 0), rgb(245, 245, 235))
	blob(model, head, Vector3.new(hs.X * 0.25, hs.Y * 0.1, 0.08), CFrame.new(-hs.X * 0.1, -hs.Y * 0.3, -hs.Z * 0.5), rgb(245, 245, 235))
end

B.Sketchbook = function(model, head, hs)
	local hand = part(model, "LeftHand")
	block(model, hand, Vector3.new(1.1, 1.3, 0.1), CFrame.new(0, 0.2, -0.3), rgb(40, 40, 50))
	block(model, hand, Vector3.new(1, 1.2, 0.11), CFrame.new(0, 0.2, -0.32), rgb(252, 250, 240))
	for i = 0, 2 do
		block(model, hand, Vector3.new(0.6 - i * 0.12, 0.05, 0.12), CFrame.new(0, 0.5 - i * 0.25, -0.34) * CFrame.Angles(0, 0, math.rad(i * 20 - 15)), ({ rgb(230, 60, 60), rgb(60, 120, 230), rgb(60, 180, 90) })[i + 1])
	end
	-- pencil tucked behind the ear
	cylY(model, head, 0.1, hs.Y * 0.5, CFrame.new(hs.X * 0.52, hs.Y * 0.05, hs.Z * 0.1) * CFrame.Angles(math.rad(60), 0, 0), rgb(255, 200, 40))
	-- doodles up her arm
	local arm = part(model, "LeftLowerArm")
	if arm then
		for i = 0, 2 do
			ball(model, arm, 0.14, CFrame.new(arm.Size.X * 0.2 * (i - 1), arm.Size.Y * (0.25 - i * 0.2), -arm.Size.Z * 0.5), rgb(40, 90, 200))
		end
	end
end

B.Lunchbox = function(model, head, hs)
	local hand = part(model, "RightHand")
	local box = block(model, hand, Vector3.new(0.5, 1, 1.3), CFrame.new(0, -0.75, 0), rgb(220, 50, 50))
	block(model, hand, Vector3.new(0.52, 0.12, 1.32), CFrame.new(0, -0.45, 0), rgb(250, 210, 60))
	block(model, hand, Vector3.new(0.12, 0.35, 0.7), CFrame.new(0, -0.15, 0), rgb(40, 40, 45))
	-- a sandwich poking out of her pocket, crusts cut off
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	block(model, torso, Vector3.new(0.45, 0.45, 0.12), CFrame.new(ts.X * 0.25, -ts.Y * 0.2, -ts.Z * 0.55) * CFrame.Angles(0, 0, math.rad(45)), rgb(250, 230, 180))
	_ = box
end

B.Pajamas = function(model, head, hs)
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	for i = 0, 3 do
		block(model, torso, Vector3.new(ts.X * 1.02, ts.Y * 0.08, ts.Z * 1.02), CFrame.new(0, ts.Y * (0.35 - i * 0.25), 0), rgb(250, 250, 255))
	end
	for _, s in { "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" } do
		local l = part(model, s)
		if l then block(model, l, Vector3.new(l.Size.X * 1.02, l.Size.Y * 0.12, l.Size.Z * 1.02), CFrame.new(0, 0, 0), rgb(250, 250, 255)) end
	end
	-- teddy bear under the arm
	local hand = part(model, "LeftHand")
	local body = ball(model, hand, 0.8, CFrame.new(0.1, 0.35, -0.35), rgb(170, 110, 60))
	ball(model, hand, 0.6, CFrame.new(0.1, 0.95, -0.35), rgb(170, 110, 60))
	for _, x in { -0.22, 0.22 } do
		ball(model, hand, 0.24, CFrame.new(0.1 + x, 1.22, -0.35), rgb(150, 95, 50))
	end
	ball(model, hand, 0.2, CFrame.new(0.1, 0.9, -0.64), rgb(230, 190, 150))
	_ = body
	-- bed hair
	blob(model, head, Vector3.new(hs.X * 0.4, hs.Y * 0.35, hs.X * 0.4), CFrame.new(hs.X * 0.2, hs.Y * 0.62, 0) * CFrame.Angles(0, 0, math.rad(-35)), HAIR.PajamaPete or rgb(120, 80, 50))
end

B.Hiccups = function(model, head, hs)
	local hand = part(model, "RightHand")
	cylY(model, hand, 0.45, 0.8, CFrame.new(0, 0.2, -0.25), rgb(40, 170, 90), Enum.Material.Metal)
	cylY(model, hand, 0.4, 0.06, CFrame.new(0, 0.62, -0.25), rgb(200, 200, 210), Enum.Material.Metal)
	-- "hic!" bubbles rising off his head
	for i = 1, 3 do
		local b = ball(model, head, 0.2 + i * 0.1, CFrame.new(hs.X * (0.35 + i * 0.12), hs.Y * (0.4 + i * 0.25), -hs.Z * 0.2), rgb(200, 240, 255), Enum.Material.Glass)
		b.Transparency = 0.45
	end
	-- puffed cheeks
	for _, x in { -1, 1 } do
		ball(model, head, hs.X * 0.28, CFrame.new(x * hs.X * 0.33, -hs.Y * 0.12, -hs.Z * 0.36), rgb(255, 170, 170))
	end
end

B.JuiceBox = function(model, head, hs)
	local hand = part(model, "RightHand")
	local box = block(model, hand, Vector3.new(0.5, 0.75, 0.32), CFrame.new(0, 0.05, -0.3), rgb(255, 150, 30))
	block(model, hand, Vector3.new(0.52, 0.3, 0.2), CFrame.new(0, 0.1, -0.42), rgb(250, 250, 240))
	ball(model, hand, 0.18, CFrame.new(0, 0.12, -0.53), rgb(220, 40, 40))
	cylY(model, hand, 0.07, 0.6, CFrame.new(0.1, 0.62, -0.3) * CFrame.Angles(0, 0, math.rad(-18)), rgb(255, 255, 255))
	-- juice down his shirt
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	blob(model, torso, Vector3.new(ts.X * 0.35, ts.Y * 0.3, 0.08), CFrame.new(-ts.X * 0.1, -ts.Y * 0.1, -ts.Z * 0.52), rgb(255, 140, 20))
	return box
end

B.BubbleGum = function(model, head, hs)
	local b = ball(model, head, hs.X * 0.75, CFrame.new(0, -hs.Y * 0.2, -hs.Z * 0.5 - hs.X * 0.33), rgb(255, 130, 200))
	b.Transparency = 0.15
	-- pigtails
	for _, x in { -1, 1 } do
		blob(model, head, Vector3.new(hs.X * 0.3, hs.Y * 0.55, hs.X * 0.3), CFrame.new(x * hs.X * 0.6, hs.Y * 0.1, hs.Z * 0.1) * CFrame.Angles(0, 0, math.rad(x * 25)), rgb(255, 120, 190))
		ball(model, head, hs.X * 0.14, CFrame.new(x * hs.X * 0.52, hs.Y * 0.35, hs.Z * 0.1), rgb(120, 220, 255))
	end
end

B.PencilChewer = function(model, head, hs)
	-- pencil clenched sideways in his teeth
	cylX(model, head, 0.12, hs.X * 1.3, CFrame.new(0, -hs.Y * 0.22, -hs.Z * 0.55), rgb(255, 205, 40))
	cylX(model, head, 0.125, 0.18, CFrame.new(hs.X * 0.7, -hs.Y * 0.22, -hs.Z * 0.55), rgb(255, 150, 170))
	cylX(model, head, 0.08, 0.14, CFrame.new(-hs.X * 0.72, -hs.Y * 0.22, -hs.Z * 0.55), rgb(40, 40, 40))
	-- and a spare behind the ear
	cylY(model, head, 0.1, hs.Y * 0.9, CFrame.new(hs.X * 0.56, hs.Y * 0.05, 0) * CFrame.Angles(math.rad(35), 0, 0), rgb(255, 205, 40))
end

B.Tissues = function(model, head, hs)
	ball(model, head, hs.X * 0.22, CFrame.new(0, -hs.Y * 0.03, -hs.Z * 0.54), rgb(240, 80, 80))
	local hand = part(model, "LeftHand")
	block(model, hand, Vector3.new(0.7, 0.55, 0.55), CFrame.new(0, -0.1, -0.2), rgb(120, 180, 240))
	blob(model, hand, Vector3.new(0.35, 0.45, 0.2), CFrame.new(0, 0.32, -0.2), rgb(255, 255, 255))
	-- a used one in the other hand
	ball(model, part(model, "RightHand"), 0.4, CFrame.new(0, -0.1, -0.25), rgb(245, 245, 245))
end

-- Uncommon --------------------------------------------------------------
B.FidgetSpinner = function(model, head, hs)
	local hand = part(model, "RightHand")
	local hub = pivot(model, hand, CFrame.new(0, 0.25, -0.5), 720)
	cylY(model, hub, 0.3, 0.12, CFrame.new(), rgb(40, 40, 50))
	for i = 0, 2 do
		local a = math.rad(i * 120)
		cylY(model, hub, 0.42, 0.1, CFrame.new(math.cos(a) * 0.4, 0, math.sin(a) * 0.4), rgb(40, 150, 255))
		cylY(model, hub, 0.2, 0.12, CFrame.new(math.cos(a) * 0.4, 0, math.sin(a) * 0.4), rgb(230, 230, 240), Enum.Material.Metal)
	end
end

B.PetRock = function(model, head, hs)
	local hand = part(model, "RightHand")
	local rock = blob(model, hand, Vector3.new(0.9, 0.7, 0.8), CFrame.new(-0.3, 0.1, -0.5), rgb(130, 130, 135))
	for _, x in { -0.18, 0.18 } do
		ball(model, hand, 0.24, CFrame.new(-0.3 + x, 0.25, -0.88), rgb(255, 255, 255))
		ball(model, hand, 0.1, CFrame.new(-0.3 + x, 0.23, -0.99), rgb(10, 10, 10))
	end
	block(model, hand, Vector3.new(0.3, 0.12, 0.08), CFrame.new(-0.3, 0.52, -0.6), rgb(255, 80, 120))
	-- her own hair bow
	block(model, head, Vector3.new(hs.X * 0.5, hs.Y * 0.18, hs.Z * 0.12), CFrame.new(0, hs.Y * 0.55, hs.Z * 0.1), rgb(255, 80, 120))
	return rock
end

B.GamerHeadset = function(model, head, hs)
	local dark = rgb(30, 30, 35)
	block(model, head, Vector3.new(hs.X * 1.2, 0.14, hs.Z * 0.3), CFrame.new(0, hs.Y * 0.62, 0), dark)
	for _, x in { -1, 1 } do
		block(model, head, Vector3.new(0.14, hs.Y * 0.45, hs.Z * 0.3), CFrame.new(x * hs.X * 0.58, hs.Y * 0.35, 0), dark)
		cylX(model, head, hs.Y * 0.55, 0.25, CFrame.new(x * hs.X * 0.6, 0, 0), dark)
		cylX(model, head, hs.Y * 0.4, 0.27, CFrame.new(x * hs.X * 0.6, 0, 0), rgb(60, 255, 140), Enum.Material.Neon)
	end
	cylZ(model, head, 0.07, hs.Z * 0.7, CFrame.new(-hs.X * 0.45, -hs.Y * 0.25, -hs.Z * 0.35) * CFrame.Angles(0, math.rad(-25), 0), dark)
	ball(model, head, 0.15, CFrame.new(-hs.X * 0.25, -hs.Y * 0.28, -hs.Z * 0.65), dark)
	-- handheld console
	local hand = part(model, "RightHand")
	block(model, hand, Vector3.new(1.0, 0.5, 0.12), CFrame.new(-0.2, 0.1, -0.35) * CFrame.Angles(math.rad(-30), 0, 0), rgb(200, 40, 60))
	block(model, hand, Vector3.new(0.5, 0.36, 0.13), CFrame.new(-0.2, 0.1, -0.35) * CFrame.Angles(math.rad(-30), 0, 0), rgb(80, 200, 255), Enum.Material.Neon)
end

B.DramaMask = function(model, head, hs)
	local mc = CFrame.new(hs.X * 0.75, 0, -hs.Z * 0.35) * CFrame.Angles(0, math.rad(-20), math.rad(-12))
	local mask = blob(model, head, Vector3.new(hs.X * 0.7, hs.Y * 0.85, 0.2), mc, rgb(255, 225, 120))
	for _, x in { -0.15, 0.15 } do
		ball(model, head, hs.X * 0.14, mc * CFrame.new(hs.X * x, hs.Y * 0.1, -0.1), rgb(20, 20, 20))
	end
	-- the comedy grin
	block(model, head, Vector3.new(hs.X * 0.35, 0.07, 0.05), mc * CFrame.new(0, -hs.Y * 0.18, -0.1), rgb(20, 20, 20))
	cylY(model, head, 0.06, hs.Y * 0.8, mc * CFrame.new(0, -hs.Y * 0.8, 0), rgb(120, 70, 30))
	-- long scarf
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	cylY(model, torso, ts.X * 0.75, ts.Y * 0.2, CFrame.new(0, ts.Y * 0.45, 0), rgb(200, 30, 50))
	block(model, torso, Vector3.new(ts.X * 0.22, ts.Y * 1.1, 0.1), CFrame.new(ts.X * 0.2, -ts.Y * 0.1, -ts.Z * 0.58), rgb(200, 30, 50))
	-- his personal spotlight
	local lamp = block(model, head, Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, hs.Y * 3, 0), rgb(255, 255, 255))
	lamp.Transparency = 1
	local sl = Instance.new("SpotLight")
	sl.Face = Enum.NormalId.Bottom
	sl.Angle = 50
	sl.Range = 14
	sl.Brightness = 4
	sl.Color = rgb(255, 245, 210)
	sl.Parent = lamp
	return mask
end

-- Rare ------------------------------------------------------------------
B.Calculator = function(model, head, hs)
	local hand = part(model, "RightHand")
	local calc = block(model, hand, Vector3.new(0.9, 1.3, 0.16), CFrame.new(0, 0.3, -0.35), rgb(70, 75, 85))
	block(model, hand, Vector3.new(0.7, 0.3, 0.17), CFrame.new(0, 0.72, -0.35), rgb(150, 230, 150), Enum.Material.Neon)
	for r = 0, 3 do
		for c = 0, 2 do
			block(model, hand, Vector3.new(0.16, 0.14, 0.18), CFrame.new(-0.24 + c * 0.24, 0.42 - r * 0.2, -0.35), c == 2 and rgb(255, 140, 40) or rgb(220, 220, 225))
		end
	end
	cylY(model, head, 0.09, hs.Y * 0.8, CFrame.new(hs.X * 0.56, hs.Y * 0.05, 0) * CFrame.Angles(math.rad(35), 0, 0), rgb(255, 205, 40))
	return calc
end

B.PomPoms = function(model, head, hs)
	for _, side in { "RightHand", "LeftHand" } do
		local hand = part(model, side)
		for i = 0, 6 do
			local a = i * 0.9
			ball(model, hand, 0.42, CFrame.new(math.cos(a) * 0.22, 0.1 + (i % 3) * 0.12, -0.2 + math.sin(a) * 0.22), i % 2 == 0 and rgb(230, 40, 60) or rgb(255, 255, 255))
		end
	end
	-- skirt and a high ponytail with a bow
	local lower = part(model, "LowerTorso")
	local ls = lower.Size
	block(model, lower, Vector3.new(ls.X * 1.3, ls.Y * 1.3, ls.Z * 1.35), CFrame.new(0, -ls.Y * 0.35, 0), rgb(230, 40, 60))
	blob(model, head, Vector3.new(hs.X * 0.35, hs.Y * 0.7, hs.X * 0.35), CFrame.new(0, hs.Y * 0.45, hs.Z * 0.55) * CFrame.Angles(math.rad(30), 0, 0), rgb(250, 220, 120))
	block(model, head, Vector3.new(hs.X * 0.5, hs.Y * 0.18, hs.Z * 0.1), CFrame.new(0, hs.Y * 0.62, hs.Z * 0.42), rgb(230, 40, 60))
end

B.Palette = function(model, head, hs)
	local left = part(model, "LeftHand")
	local pal = blob(model, left, Vector3.new(1.2, 0.12, 0.9), CFrame.new(0, 0.1, -0.35), rgb(200, 150, 90))
	local dots = { rgb(230, 40, 40), rgb(40, 120, 230), rgb(255, 210, 40), rgb(60, 200, 90), rgb(250, 250, 250) }
	for i, c in dots do
		local a = i * 1.1
		ball(model, left, 0.2, CFrame.new(math.cos(a) * 0.35, 0.16, -0.35 + math.sin(a) * 0.25), c)
	end
	local right = part(model, "RightHand")
	cylY(model, right, 0.08, 1.1, CFrame.new(0, 0.3, -0.25) * CFrame.Angles(math.rad(-20), 0, 0), rgb(150, 100, 50), Enum.Material.Wood)
	ball(model, right, 0.14, CFrame.new(0, 0.82, -0.44), rgb(40, 120, 230))
	-- paint splats on the smock
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	for i, c in dots do
		blob(model, torso, Vector3.new(0.3, 0.25, 0.06), CFrame.new(ts.X * (-0.35 + 0.17 * i), ts.Y * (0.25 - 0.13 * (i % 3)), -ts.Z * 0.52), c)
	end
	return pal
end

B.ChessKing = function(model, head, hs)
	local hand = part(model, "RightHand")
	local black = rgb(25, 25, 30)
	cylY(model, hand, 0.7, 0.2, CFrame.new(0, -0.1, -0.35), black)
	cylY(model, hand, 0.45, 0.9, CFrame.new(0, 0.45, -0.35), black)
	cylY(model, hand, 0.6, 0.12, CFrame.new(0, 0.95, -0.35), black)
	blob(model, hand, Vector3.new(0.5, 0.35, 0.5), CFrame.new(0, 1.15, -0.35), black)
	block(model, hand, Vector3.new(0.1, 0.4, 0.1), CFrame.new(0, 1.5, -0.35), black)
	block(model, hand, Vector3.new(0.3, 0.1, 0.1), CFrame.new(0, 1.55, -0.35), black)
	-- medal
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	cylZ(model, torso, ts.X * 0.25, 0.08, CFrame.new(0, ts.Y * 0.05, -ts.Z * 0.56), rgb(255, 200, 40), Enum.Material.Metal)
	block(model, torso, Vector3.new(0.08, ts.Y * 0.4, 0.05), CFrame.new(-ts.X * 0.12, ts.Y * 0.3, -ts.Z * 0.53) * CFrame.Angles(0, 0, math.rad(-20)), rgb(40, 90, 200))
	block(model, torso, Vector3.new(0.08, ts.Y * 0.4, 0.05), CFrame.new(ts.X * 0.12, ts.Y * 0.3, -ts.Z * 0.53) * CFrame.Angles(0, 0, math.rad(20)), rgb(40, 90, 200))
end

-- Epic ------------------------------------------------------------------
B.BeeCostume = function(model, head, hs)
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	local black = rgb(25, 25, 25)
	for _, y in { 0.15, -0.25 } do
		block(model, torso, Vector3.new(ts.X * 1.04, ts.Y * 0.16, ts.Z * 1.06), CFrame.new(0, ts.Y * y, 0), black)
	end
	for _, x in { -1, 1 } do
		local w = blob(model, torso, Vector3.new(0.12, ts.Y * 1.3, ts.X * 0.9), CFrame.new(x * ts.X * 0.35, ts.Y * 0.25, ts.Z * 0.75) * CFrame.Angles(0, math.rad(x * 30), math.rad(x * -20)), rgb(230, 245, 255), Enum.Material.Glass)
		w.Transparency = 0.35
		cylY(model, head, 0.07, hs.Y * 0.6, CFrame.new(x * hs.X * 0.22, hs.Y * 0.75, 0) * CFrame.Angles(0, 0, math.rad(x * -20)), black)
		ball(model, head, 0.2, CFrame.new(x * hs.X * 0.33, hs.Y * 1.02, 0), black)
	end
	local lower = part(model, "LowerTorso")
	block(model, lower, Vector3.new(0.18, 0.18, 0.5), CFrame.new(0, 0, lower.Size.Z * 0.7), black)
	-- the winning word, on a card
	block(model, part(model, "RightHand"), Vector3.new(0.9, 0.6, 0.06), CFrame.new(0, 0.3, -0.3), rgb(255, 255, 255))
end

B.RobotArm = function(model, head, hs)
	local hand = part(model, "RightHand")
	local metal = rgb(170, 175, 185)
	block(model, hand, Vector3.new(0.5, 0.35, 0.5), CFrame.new(0, -0.05, 0), metal, Enum.Material.Metal)
	for _, x in { -0.16, 0.16 } do
		block(model, hand, Vector3.new(0.1, 0.5, 0.2), CFrame.new(x, -0.4, 0) * CFrame.Angles(0, 0, math.rad(x > 0 and 15 or -15)), metal, Enum.Material.Metal)
	end
	local arm = part(model, "RightLowerArm")
	block(model, arm, arm.Size * Vector3.new(1.15, 0.9, 1.15), CFrame.new(), metal, Enum.Material.Metal)
	-- antenna with a blinking tip
	cylY(model, head, 0.07, hs.Y * 0.7, CFrame.new(hs.X * 0.2, hs.Y * 0.8, 0), rgb(60, 60, 70))
	ball(model, head, 0.2, CFrame.new(hs.X * 0.2, hs.Y * 1.18, 0), rgb(255, 40, 40), Enum.Material.Neon)
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	block(model, torso, Vector3.new(ts.X * 0.5, ts.Y * 0.35, 0.08), CFrame.new(0, ts.Y * 0.05, -ts.Z * 0.53), rgb(40, 45, 55))
	for i = -1, 1 do
		ball(model, torso, 0.12, CFrame.new(ts.X * 0.12 * i, ts.Y * 0.05, -ts.Z * 0.58), i == 0 and rgb(60, 255, 120) or rgb(80, 180, 255), Enum.Material.Neon)
	end
end

B.Camera = function(model, head, hs)
	local hand = part(model, "RightHand")
	local cam = block(model, hand, Vector3.new(0.9, 0.6, 0.45), CFrame.new(0, 0.35, -0.4), rgb(30, 30, 35))
	cylZ(model, hand, 0.42, 0.4, CFrame.new(0, 0.33, -0.8), rgb(50, 50, 55))
	cylZ(model, hand, 0.3, 0.42, CFrame.new(0, 0.33, -0.8), rgb(120, 170, 230), Enum.Material.Glass)
	block(model, hand, Vector3.new(0.3, 0.18, 0.2), CFrame.new(0.25, 0.75, -0.4), rgb(255, 255, 255), Enum.Material.Neon)
	-- press badge
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	block(model, torso, Vector3.new(ts.X * 0.3, ts.Y * 0.22, 0.05), CFrame.new(-ts.X * 0.22, ts.Y * 0.1, -ts.Z * 0.53), rgb(255, 255, 255))
	block(model, torso, Vector3.new(ts.X * 0.3, ts.Y * 0.07, 0.06), CFrame.new(-ts.X * 0.22, ts.Y * 0.18, -ts.Z * 0.53), rgb(220, 40, 40))
	-- backwards cap
	blob(model, head, Vector3.new(hs.X * 1.1, hs.Y * 0.6, hs.Z * 1.12), CFrame.new(0, hs.Y * 0.28, 0), rgb(40, 80, 60))
	block(model, head, Vector3.new(hs.X * 0.7, 0.08, hs.Z * 0.45), CFrame.new(0, hs.Y * 0.32, hs.Z * 0.62), rgb(40, 80, 60))
	return cam
end

B.Tiara = function(model, head, hs)
	local silver = rgb(220, 225, 235)
	cylY(model, head, hs.X * 1.02, 0.1, CFrame.new(0, hs.Y * 0.42, 0), silver, Enum.Material.Metal)
	for i = -2, 2 do
		local h = (3 - math.abs(i)) * 0.12
		block(model, head, Vector3.new(0.1, h, 0.08), CFrame.new(hs.X * 0.16 * i, hs.Y * 0.45 + h / 2, -hs.Z * 0.46), silver, Enum.Material.Metal)
		ball(model, head, 0.13, CFrame.new(hs.X * 0.16 * i, hs.Y * 0.45 + h, -hs.Z * 0.47), rgb(255, 80, 200), Enum.Material.Neon)
	end
	-- feather boa
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	for i = 0, 9 do
		local a = math.rad(i * 36)
		ball(model, torso, 0.36, CFrame.new(math.cos(a) * ts.X * 0.42, ts.Y * 0.45, math.sin(a) * ts.Z * 0.62), rgb(255, 120, 220))
	end
	for i = 1, 4 do
		ball(model, torso, 0.34, CFrame.new(ts.X * 0.35, ts.Y * (0.45 - i * 0.2), -ts.Z * 0.6), rgb(255, 120, 220))
	end
	sparkles(part(model, "HumanoidRootPart"), rgb(255, 150, 230), 5)
end

-- Legendary -------------------------------------------------------------
B.MascotHead = function(model, head, hs)
	local face = head:FindFirstChildOfClass("Decal")
	if face then face.Transparency = 1 end
	local brown, white = rgb(120, 70, 30), rgb(250, 250, 250)
	local h = blob(model, head, Vector3.new(hs.X * 1.9, hs.Y * 1.8, hs.Z * 1.9), CFrame.new(0, hs.Y * 0.35, 0), brown)
	blob(model, head, Vector3.new(hs.X * 1.6, hs.Y * 1.0, hs.Z * 1.5), CFrame.new(0, hs.Y * 0.85, hs.Z * 0.05), white)
	-- beak
	block(model, head, Vector3.new(hs.X * 0.5, hs.Y * 0.3, hs.Z * 0.9), CFrame.new(0, hs.Y * 0.1, -hs.Z * 1.05), rgb(255, 190, 30))
	block(model, head, Vector3.new(hs.X * 0.4, hs.Y * 0.2, hs.Z * 0.4), CFrame.new(0, -hs.Y * 0.02, -hs.Z * 1.4) * CFrame.Angles(math.rad(35), 0, 0), rgb(255, 190, 30))
	for _, x in { -0.4, 0.4 } do
		ball(model, head, hs.X * 0.55, CFrame.new(hs.X * x, hs.Y * 0.55, -hs.Z * 0.8), white)
		ball(model, head, hs.X * 0.25, CFrame.new(hs.X * x, hs.Y * 0.52, -hs.Z * 1.02), rgb(20, 20, 20))
	end
	-- foam finger
	local hand = part(model, "RightHand")
	block(model, hand, Vector3.new(0.7, 0.8, 0.3), CFrame.new(0, 0.2, -0.2), rgb(255, 210, 40))
	block(model, hand, Vector3.new(0.22, 0.8, 0.28), CFrame.new(0, 0.95, -0.2), rgb(255, 210, 40))
	return h
end

B.Crown = function(model, head, hs)
	local gold = rgb(255, 200, 40)
	cylY(model, head, hs.X * 0.95, hs.Y * 0.2, CFrame.new(0, hs.Y * 0.55, 0), gold, Enum.Material.Metal)
	for i = 0, 5 do
		local a = math.rad(i * 60)
		block(model, head, Vector3.new(0.15, hs.Y * 0.28, 0.15), CFrame.new(math.cos(a) * hs.X * 0.44, hs.Y * 0.74, math.sin(a) * hs.X * 0.44), gold, Enum.Material.Metal)
		ball(model, head, 0.13, CFrame.new(math.cos(a) * hs.X * 0.44, hs.Y * 0.9, math.sin(a) * hs.X * 0.44), i % 2 == 0 and rgb(220, 30, 50) or rgb(60, 120, 255), Enum.Material.Neon)
	end
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	local len = math.sqrt(ts.X ^ 2 + ts.Y ^ 2) * 1.05
	block(model, torso, Vector3.new(ts.X * 0.26, len, 0.06), CFrame.new(0, 0, -ts.Z * 0.54) * CFrame.Angles(0, 0, math.rad(-38)), rgb(200, 20, 40))
	-- white shirt V and bow tie
	block(model, torso, Vector3.new(ts.X * 0.3, ts.Y * 0.5, 0.04), CFrame.new(0, ts.Y * 0.2, -ts.Z * 0.52), rgb(250, 250, 250))
	block(model, torso, Vector3.new(ts.X * 0.3, ts.Y * 0.1, 0.1), CFrame.new(0, ts.Y * 0.42, -ts.Z * 0.56), rgb(20, 20, 20))
	-- rose
	local hand = part(model, "RightHand")
	cylY(model, hand, 0.06, 0.9, CFrame.new(0, 0.3, -0.25), rgb(40, 150, 50))
	ball(model, hand, 0.3, CFrame.new(0, 0.8, -0.25), rgb(220, 20, 50))
	sparkles(part(model, "HumanoidRootPart"), gold, 4)
end

B.DJ = function(model, head, hs)
	local purple = rgb(150, 60, 230)
	block(model, head, Vector3.new(hs.X * 1.25, 0.18, hs.Z * 0.35), CFrame.new(0, hs.Y * 0.62, 0), rgb(30, 30, 35))
	for _, x in { -1, 1 } do
		cylX(model, head, hs.Y * 0.7, 0.35, CFrame.new(x * hs.X * 0.65, 0, 0), rgb(30, 30, 35))
		cylX(model, head, hs.Y * 0.5, 0.37, CFrame.new(x * hs.X * 0.65, 0, 0), purple, Enum.Material.Neon)
	end
	-- turntable held in front
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	local deck = block(model, torso, Vector3.new(ts.X * 1.6, 0.25, ts.Z * 1.6), CFrame.new(0, -ts.Y * 0.4, -ts.Z * 1.3), rgb(40, 40, 48))
	for _, x in { -0.4, 0.4 } do
		local rec = pivot(model, torso, CFrame.new(ts.X * x, -ts.Y * 0.4 + 0.15, -ts.Z * 1.3), 200)
		cylY(model, rec, ts.X * 0.6, 0.06, CFrame.new(), rgb(15, 15, 15))
		cylY(model, rec, ts.X * 0.15, 0.08, CFrame.new(0, 0.01, 0), purple, Enum.Material.Neon)
		-- a white mark so the spin reads
		block(model, rec, Vector3.new(ts.X * 0.2, 0.08, 0.06), CFrame.new(ts.X * 0.17, 0.01, 0), rgb(255, 255, 255))
	end
	local light = Instance.new("PointLight")
	light.Color = purple
	light.Range = 12
	light.Brightness = 2
	light.Parent = deck
end

B.Trophy = function(model, head, hs)
	local gold = rgb(255, 200, 40)
	local hand = part(model, "RightHand")
	cylY(model, hand, 0.5, 0.15, CFrame.new(0, -0.1, -0.3), rgb(60, 40, 30), Enum.Material.Wood)
	cylY(model, hand, 0.15, 0.4, CFrame.new(0, 0.15, -0.3), gold, Enum.Material.Metal)
	local cup = cylY(model, hand, 0.7, 0.7, CFrame.new(0, 0.65, -0.3), gold, Enum.Material.Metal)
	for _, x in { -1, 1 } do
		cylZ(model, hand, 0.3, 0.08, CFrame.new(x * 0.42, 0.7, -0.3), gold, Enum.Material.Metal)
	end
	-- medals and a sweatband
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	for i, x in { -0.25, 0, 0.25 } do
		cylZ(model, torso, ts.X * 0.18, 0.06, CFrame.new(ts.X * x, ts.Y * (0.0 - 0.05 * (i % 2)), -ts.Z * 0.56), i == 2 and gold or rgb(200, 205, 215), Enum.Material.Metal)
	end
	cylY(model, head, hs.X * 1.03, hs.Y * 0.14, CFrame.new(0, hs.Y * 0.25, 0), rgb(250, 250, 250))
	sparkles(cup, gold, 6)
end

-- Mythic ----------------------------------------------------------------
B.Moustache = function(model, head, hs)
	local brown = rgb(70, 45, 30)
	for _, x in { -1, 1 } do
		blob(model, head, Vector3.new(hs.X * 0.45, hs.Y * 0.18, 0.2), CFrame.new(x * hs.X * 0.2, -hs.Y * 0.12, -hs.Z * 0.52) * CFrame.Angles(0, 0, math.rad(x * -12)), brown)
	end
	local hand = part(model, "RightHand")
	block(model, hand, Vector3.new(0.4, 1.1, 1.5), CFrame.new(0.15, -0.65, 0), rgb(30, 25, 25))
	block(model, hand, Vector3.new(0.12, 0.22, 0.5), CFrame.new(0.15, -0.05, 0), rgb(20, 20, 20))
	-- newspaper under the other arm
	block(model, part(model, "LeftUpperArm"), Vector3.new(0.2, 0.9, 0.7), CFrame.new(0.1, -0.1, 0.2), rgb(235, 235, 225))
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	block(model, torso, Vector3.new(ts.X * 0.15, ts.Y * 0.75, 0.06), CFrame.new(0, -ts.Y * 0.05, -ts.Z * 0.53), rgb(30, 60, 140))
end

B.Ghost = function(model, head, hs)
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			p.Transparency = 0.35
			p.Color = rgb(225, 235, 255)
		end
	end
	model:SetAttribute("Hover", 1.2)
	local grey = rgb(110, 110, 120)
	for _, side in { "LeftHand", "RightHand" } do
		local h = part(model, side)
		cylY(model, h, 0.5, 0.18, CFrame.new(0, 0.15, 0), grey, Enum.Material.Metal)
		for i = 1, 3 do
			cylX(model, h, 0.14, 0.24, CFrame.new(0, -0.1 - i * 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)), grey, Enum.Material.Metal)
		end
	end
	-- a tail instead of feet
	local lower = part(model, "LowerTorso")
	local t = blob(model, lower, Vector3.new(lower.Size.X * 1.1, lower.Size.Y * 3, lower.Size.Z * 1.1), CFrame.new(0, -lower.Size.Y * 1.5, 0), rgb(225, 235, 255))
	t.Transparency = 0.45
	local light = Instance.new("PointLight")
	light.Color = rgb(180, 210, 255)
	light.Range = 8
	light.Brightness = 0.5
	light.Parent = head
end

B.PocketClock = function(model, head, hs)
	local gold = rgb(255, 200, 40)
	local hand = part(model, "RightHand")
	local clock = cylZ(model, hand, 0.6, 0.12, CFrame.new(0, 0.1, -0.35), gold, Enum.Material.Metal)
	cylZ(model, hand, 0.5, 0.13, CFrame.new(0, 0.1, -0.36), rgb(250, 250, 240))
	block(model, hand, Vector3.new(0.04, 0.2, 0.14), CFrame.new(0, 0.18, -0.36), rgb(20, 20, 20))
	block(model, hand, Vector3.new(0.14, 0.04, 0.14), CFrame.new(0.05, 0.1, -0.36), rgb(20, 20, 20))
	-- time machine on his back
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	block(model, torso, Vector3.new(ts.X * 0.9, ts.Y * 0.9, ts.Z * 0.6), CFrame.new(0, 0, ts.Z * 0.75), rgb(90, 90, 100), Enum.Material.Metal)
	for i = -1, 1 do
		cylZ(model, torso, ts.X * 0.5, 0.1, CFrame.new(0, ts.Y * 0.25 * i, ts.Z * 1.06), rgb(60, 200, 255), Enum.Material.Neon)
	end
	-- 80s shades
	block(model, head, Vector3.new(hs.X * 0.95, hs.Y * 0.18, 0.08), CFrame.new(0, hs.Y * 0.06, -hs.Z * 0.53), rgb(255, 60, 160), Enum.Material.Neon)
	return clock
end

-- Prodigy ---------------------------------------------------------------
B.Jetpack = function(model, head, hs)
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	local silver = rgb(200, 205, 215)
	for _, x in { -0.28, 0.28 } do
		cylY(model, torso, ts.X * 0.45, ts.Y * 1.1, CFrame.new(ts.X * x, 0, ts.Z * 0.85), silver, Enum.Material.Metal)
		cylY(model, torso, ts.X * 0.3, ts.Y * 0.2, CFrame.new(ts.X * x, -ts.Y * 0.62, ts.Z * 0.85), rgb(60, 60, 70), Enum.Material.Metal)
		local flame = blob(model, torso, Vector3.new(ts.X * 0.28, ts.Y * 0.7, ts.X * 0.28), CFrame.new(ts.X * x, -ts.Y * 1.05, ts.Z * 0.85), rgb(255, 140, 30), Enum.Material.Neon)
		local fire = Instance.new("Fire")
		fire.Size = 2
		fire.Heat = 4
		fire.Color = rgb(255, 150, 40)
		fire.SecondaryColor = rgb(255, 60, 20)
		fire.Parent = flame
	end
	block(model, torso, Vector3.new(ts.X * 0.8, 0.15, 0.1), CFrame.new(0, ts.Y * 0.3, -ts.Z * 0.54), rgb(230, 90, 30))
	local helmet = ball(model, head, hs.X * 1.55, CFrame.new(0, hs.Y * 0.1, 0), rgb(200, 230, 255), Enum.Material.Glass)
	helmet.Transparency = 0.7
end

B.Professor = function(model, head, hs)
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	-- tweed jacket over the shirt, elbow patches
	block(model, torso, Vector3.new(ts.X * 1.06, ts.Y * 1.02, ts.Z * 1.06), CFrame.new(0, 0, 0.02), rgb(130, 100, 70))
	block(model, torso, Vector3.new(ts.X * 0.34, ts.Y * 0.9, 0.04), CFrame.new(0, 0, -ts.Z * 0.54), rgb(245, 240, 230))
	block(model, torso, Vector3.new(ts.X * 0.35, ts.Y * 0.12, 0.1), CFrame.new(0, ts.Y * 0.4, -ts.Z * 0.57), rgb(160, 20, 40))
	for _, s in { "LeftLowerArm", "RightLowerArm" } do
		local a = part(model, s)
		blob(model, a, Vector3.new(a.Size.X * 0.7, a.Size.Y * 0.4, 0.1), CFrame.new(0, 0, a.Size.Z * 0.5), rgb(90, 60, 40))
	end
	wireGlasses(model, head, hs, 0.04, 0.14)
	-- bushy white eyebrows and a bubble pipe
	for _, x in { -0.2, 0.2 } do
		blob(model, head, Vector3.new(hs.X * 0.3, hs.Y * 0.1, 0.12), CFrame.new(hs.X * x, hs.Y * 0.2, -hs.Z * 0.52), rgb(245, 245, 245))
	end
	cylZ(model, head, 0.08, hs.Z * 0.5, CFrame.new(hs.X * 0.1, -hs.Y * 0.22, -hs.Z * 0.7), rgb(90, 50, 25))
	cylY(model, head, 0.22, 0.25, CFrame.new(hs.X * 0.1, -hs.Y * 0.14, -hs.Z * 0.95), rgb(90, 50, 25))
	for i = 1, 3 do
		local bub = ball(model, head, 0.12 + i * 0.05, CFrame.new(hs.X * (0.15 + 0.1 * i), hs.Y * (0.05 + 0.25 * i), -hs.Z * 0.95), rgb(200, 240, 255), Enum.Material.Glass)
		bub.Transparency = 0.5
	end
	-- chalk
	block(model, part(model, "RightHand"), Vector3.new(0.1, 0.4, 0.1), CFrame.new(0, 0.2, -0.2), rgb(255, 255, 255))
end

B.PopStar = function(model, head, hs)
	local hand = part(model, "RightHand")
	cylY(model, hand, 0.16, 0.7, CFrame.new(0, 0.3, -0.25), rgb(40, 40, 45))
	ball(model, hand, 0.35, CFrame.new(0, 0.75, -0.25), rgb(200, 200, 210), Enum.Material.Metal)
	-- sequin jacket
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	block(model, torso, Vector3.new(ts.X * 1.07, ts.Y * 1.03, ts.Z * 1.07), CFrame.new(0, 0, 0.02), rgb(255, 80, 200), Enum.Material.Foil)
	block(model, torso, Vector3.new(ts.X * 0.3, ts.Y * 0.9, 0.04), CFrame.new(0, 0, -ts.Z * 0.55), rgb(250, 250, 255))
	-- star shades
	for _, x in { -0.2, 0.2 } do
		for r = 0, 4 do
			block(model, head, Vector3.new(0.08, hs.Y * 0.22, 0.06), CFrame.new(hs.X * x, hs.Y * 0.06, -hs.Z * 0.53) * CFrame.Angles(0, 0, math.rad(r * 72)), rgb(255, 220, 40), Enum.Material.Neon)
		end
	end
	sparkles(part(model, "HumanoidRootPart"), rgb(255, 200, 255), 14)
end

B.ChessOrbit = function(model, head, hs)
	local black, white = rgb(25, 25, 30), rgb(245, 245, 245)
	local ring = pivot(model, head, CFrame.new(0, hs.Y * 0.8, 0), 60)
	for i = 0, 3 do
		local a = math.rad(i * 90)
		local c = i % 2 == 0 and white or black
		local base = CFrame.new(math.cos(a) * hs.X * 1.1, 0, math.sin(a) * hs.X * 1.1)
		cylY(model, ring, 0.35, 0.12, base, c)
		cylY(model, ring, 0.2, 0.35, base * CFrame.new(0, 0.2, 0), c)
		ball(model, ring, 0.24, base * CFrame.new(0, 0.45, 0), c)
	end
	-- sweater vest
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	block(model, torso, Vector3.new(ts.X * 1.05, ts.Y * 0.8, ts.Z * 1.06), CFrame.new(0, -ts.Y * 0.1, 0), rgb(60, 60, 140))
	wireGlasses(model, head, hs, 0.04, 0.14)
end

B.CEO = function(model, head, hs)
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	block(model, torso, Vector3.new(ts.X * 0.3, ts.Y * 0.9, 0.04), CFrame.new(0, 0, -ts.Z * 0.53), rgb(250, 250, 250))
	block(model, torso, Vector3.new(ts.X * 0.14, ts.Y * 0.75, 0.06), CFrame.new(0, -ts.Y * 0.05, -ts.Z * 0.56), rgb(200, 20, 30))
	local hand = part(model, "RightHand")
	local case = block(model, hand, Vector3.new(0.4, 1.1, 1.5), CFrame.new(0.15, -0.65, 0), rgb(40, 30, 25))
	for i = 0, 3 do
		block(model, hand, Vector3.new(0.3, 0.12, 0.6), CFrame.new(0.15, -0.05 + i * 0.03, -0.4 + i * 0.25) * CFrame.Angles(0, 0, math.rad(i * 8)), rgb(80, 200, 90))
	end
	-- phone to the ear
	block(model, part(model, "LeftHand"), Vector3.new(0.1, 0.6, 0.3), CFrame.new(0, 0.3, 0), rgb(20, 20, 20))
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(rgb(80, 220, 90))
	e.Rate = 6
	e.Lifetime = NumberRange.new(1, 1.5)
	e.Speed = NumberRange.new(0.5, 1)
	e.Acceleration = Vector3.new(0, -3, 0)
	e.Size = NumberSequence.new(0.35, 0.2)
	e.Parent = case
end

-- Secret ----------------------------------------------------------------
B.SnowGlobe = function(model, head, hs)
	local hand = part(model, "RightHand")
	block(model, hand, Vector3.new(0.8, 0.3, 0.8), CFrame.new(-0.3, 0.1, -0.5), rgb(120, 80, 40), Enum.Material.Wood)
	local globe = ball(model, hand, 1.1, CFrame.new(-0.3, 0.8, -0.5), rgb(210, 235, 255), Enum.Material.Glass)
	globe.Transparency = 0.6
	block(model, hand, Vector3.new(0.3, 0.3, 0.3), CFrame.new(-0.3, 0.45, -0.5), rgb(200, 60, 60))
	block(model, hand, Vector3.new(0.34, 0.12, 0.34), CFrame.new(-0.3, 0.64, -0.5) * CFrame.Angles(0, math.rad(45), 0), rgb(250, 250, 250))
	-- beanie and a snowfall that follows her
	cylY(model, head, hs.X * 1.05, hs.Y * 0.35, CFrame.new(0, hs.Y * 0.4, 0), rgb(90, 140, 230))
	blob(model, head, Vector3.new(hs.X * 1.05, hs.Y * 0.5, hs.Z * 1.05), CFrame.new(0, hs.Y * 0.58, 0), rgb(90, 140, 230))
	ball(model, head, hs.X * 0.35, CFrame.new(0, hs.Y * 0.95, 0), rgb(255, 255, 255))
	local snow = Instance.new("ParticleEmitter")
	snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	snow.Color = ColorSequence.new(rgb(255, 255, 255))
	snow.Rate = 20
	snow.Lifetime = NumberRange.new(2, 3)
	snow.Speed = NumberRange.new(1, 2)
	snow.SpreadAngle = Vector2.new(60, 60)
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.Size = NumberSequence.new(0.3)
	local cloud = block(model, head, Vector3.new(5, 0.2, 5), CFrame.new(0, hs.Y * 3, 0), rgb(255, 255, 255))
	cloud.Transparency = 1
	snow.Parent = cloud
	return globe
end

B.HomeworkVillain = function(model, head, hs)
	for _, x in { -0.2, 0.2 } do
		ball(model, head, hs.X * 0.16, CFrame.new(hs.X * x, hs.Y * 0.06, -hs.Z * 0.5), rgb(255, 30, 30), Enum.Material.Neon)
	end
	-- the stack of homework he reminded everyone about
	local hand = part(model, "RightHand")
	for i = 0, 9 do
		block(model, hand, Vector3.new(0.9, 0.08, 1.2), CFrame.new(-0.3 + (i % 3) * 0.04, 0.2 + i * 0.09, -0.5) * CFrame.Angles(0, math.rad((i * 37) % 11 - 5), 0), rgb(250, 250, 245))
	end
	-- villain cape
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	block(model, torso, Vector3.new(ts.X * 1.3, ts.Y * 2.4, 0.12), CFrame.new(0, -ts.Y * 0.65, ts.Z * 0.62), rgb(120, 10, 20))
	block(model, torso, Vector3.new(ts.X * 1.2, ts.Y * 0.25, ts.Z * 0.3), CFrame.new(0, ts.Y * 0.5, ts.Z * 0.3), rgb(40, 5, 10))
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(rgb(180, 0, 20))
	e.Rate = 10
	e.Lifetime = NumberRange.new(1, 1.6)
	e.Speed = NumberRange.new(0.5, 1.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new(0.6, 0)
	e.Parent = part(model, "HumanoidRootPart")
end

B.Glitch = function(model, head, hs)
	-- the missing-texture checkerboard over half his face
	local magenta, black = rgb(255, 0, 220), rgb(10, 10, 10)
	for r = 0, 1 do
		for c = 0, 1 do
			block(model, head, Vector3.new(hs.X * 0.28, hs.Y * 0.28, 0.08), CFrame.new(hs.X * (0.08 + 0.28 * c), hs.Y * (0.14 - 0.28 * r), -hs.Z * 0.53), (r + c) % 2 == 0 and magenta or black, Enum.Material.Neon)
		end
	end
	-- stray pixels orbiting his body
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	local ring = pivot(model, torso, CFrame.new(), 90)
	for i = 0, 7 do
		local a = math.rad(i * 45)
		block(model, ring, Vector3.new(0.3, 0.3, 0.3), CFrame.new(math.cos(a) * ts.X * 1.1, ts.Y * (-0.6 + (i % 4) * 0.4), math.sin(a) * ts.X * 1.1), i % 2 == 0 and magenta or rgb(0, 230, 255), Enum.Material.Neon)
	end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(2.5, 0, 1, 0)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 50
	bb.Parent = torso
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = "404"
	t.Font = Enum.Font.Code
	t.TextScaled = true
	t.TextColor3 = rgb(0, 255, 200)
	t.Parent = bb
end

-- Alumni ----------------------------------------------------------------
B.Grandpa = function(model, head, hs)
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	block(model, torso, Vector3.new(ts.X * 0.3, ts.Y * 0.4, 0.06), CFrame.new(-ts.X * 0.22, ts.Y * 0.1, -ts.Z * 0.54), rgb(250, 250, 250))
	block(model, torso, Vector3.new(ts.X * 0.08, ts.Y * 0.3, 0.07), CFrame.new(-ts.X * 0.28, ts.Y * 0.1, -ts.Z * 0.56), rgb(160, 30, 40))
	block(model, torso, Vector3.new(ts.X * 0.18, ts.Y * 0.07, 0.07), CFrame.new(-ts.X * 0.22, -ts.Y * 0.02, -ts.Z * 0.56), rgb(160, 30, 40))
	local hand = part(model, "RightHand")
	cylY(model, hand, 0.12, 2.4, CFrame.new(0, -0.9, -0.2), rgb(120, 70, 30), Enum.Material.Wood)
	cylX(model, hand, 0.12, 0.4, CFrame.new(-0.15, 0.3, -0.2), rgb(120, 70, 30), Enum.Material.Wood)
	wireGlasses(model, head, hs, 0.04, 0.14, rgb(170, 170, 180))
	blob(model, head, Vector3.new(hs.X * 0.6, hs.Y * 0.14, 0.15), CFrame.new(0, -hs.Y * 0.12, -hs.Z * 0.52), rgb(235, 235, 240))
end

B.Class99 = function(model, head, hs)
	-- frosted tips
	for i = 0, 6 do
		local a = math.rad(-60 + i * 20)
		block(model, head, Vector3.new(0.14, hs.Y * 0.3, 0.14), CFrame.new(math.sin(a) * hs.X * 0.35, hs.Y * 0.58, -math.cos(a) * hs.Z * 0.15) * CFrame.Angles(math.rad(-20), 0, math.rad(-math.deg(a) * 0.4)), rgb(250, 235, 170))
	end
	-- flip phone and a chain wallet
	block(model, part(model, "RightHand"), Vector3.new(0.25, 0.5, 0.1), CFrame.new(0, 0.2, -0.2), rgb(190, 195, 205), Enum.Material.Metal)
	local lower = part(model, "LowerTorso")
	cylX(model, lower, 0.06, lower.Size.X * 0.9, CFrame.new(0, -lower.Size.Y * 0.4, -lower.Size.Z * 0.55) * CFrame.Angles(0, 0, math.rad(-10)), rgb(200, 200, 210), Enum.Material.Metal)
	for _, x in { -0.2, 0.2 } do
		block(model, head, Vector3.new(hs.X * 0.34, hs.Y * 0.14, 0.08), CFrame.new(hs.X * x, hs.Y * 0.06, -hs.Z * 0.53), rgb(255, 150, 40), Enum.Material.Glass)
	end
end

B.Prefect = function(model, head, hs)
	local torso = part(model, "UpperTorso")
	local lower = part(model, "LowerTorso")
	local ts, ls = torso.Size, lower.Size
	block(model, torso, Vector3.new(ts.X * 1.12, ts.Y * 1.05, ts.Z * 1.15), CFrame.new(), rgb(25, 25, 35))
	block(model, lower, Vector3.new(ls.X * 1.2, ls.Y * 4, ls.Z * 1.25), CFrame.new(0, -ls.Y * 1.45, 0), rgb(25, 25, 35))
	-- striped scarf
	for i = 0, 3 do
		block(model, torso, Vector3.new(ts.X * 0.2, ts.Y * 0.18, 0.1), CFrame.new(ts.X * 0.18, ts.Y * (0.35 - i * 0.18), -ts.Z * 0.6), i % 2 == 0 and rgb(140, 20, 30) or rgb(230, 180, 40))
	end
	local hand = part(model, "RightHand")
	cylY(model, hand, 0.08, 1.1, CFrame.new(0, 0.4, -0.3) * CFrame.Angles(math.rad(-30), 0, 0), rgb(90, 55, 30), Enum.Material.Wood)
	local tip = ball(model, hand, 0.18, CFrame.new(0, 0.9, -0.62), rgb(180, 220, 255), Enum.Material.Neon)
	sparkles(tip, rgb(180, 220, 255), 10)
	cylZ(model, torso, ts.X * 0.22, 0.08, CFrame.new(-ts.X * 0.22, ts.Y * 0.2, -ts.Z * 0.6), rgb(230, 180, 40), Enum.Material.Metal)
end

B.Founder = function(model, head, hs)
	-- a bronze statue that walked off its plinth
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			p.Color = rgb(150, 105, 60)
			p.Material = Enum.Material.Metal
		end
	end
	local face = head:FindFirstChildOfClass("Decal")
	if face then face.Color3 = rgb(80, 50, 25) end
	for i = 0, 7 do
		local a = math.rad(-150 + i * 20)
		blob(model, head, Vector3.new(0.3, 0.14, 0.18), CFrame.new(math.cos(a) * hs.X * 0.5, hs.Y * 0.35, math.sin(a) * hs.Z * 0.5) * CFrame.Angles(0, -a, 0), rgb(90, 140, 70), Enum.Material.Metal)
	end
	cylY(model, part(model, "RightHand"), 0.3, 1.1, CFrame.new(0, 0, -0.2) * CFrame.Angles(math.rad(90), 0, 0), rgb(150, 105, 60), Enum.Material.Metal)
	sparkles(part(model, "HumanoidRootPart"), rgb(255, 220, 150), 6)
end

B.TinyPrincipal = function(model, head, hs)
	local torso = part(model, "UpperTorso")
	local ts = torso.Size
	block(model, torso, Vector3.new(ts.X * 0.3, ts.Y * 0.9, 0.04), CFrame.new(0, 0, -ts.Z * 0.53), rgb(250, 250, 250))
	block(model, torso, Vector3.new(ts.X * 0.14, ts.Y * 0.75, 0.06), CFrame.new(0, -ts.Y * 0.05, -ts.Z * 0.56), rgb(30, 60, 150))
	block(model, torso, Vector3.new(ts.X * 0.3, ts.Y * 0.14, 0.05), CFrame.new(ts.X * 0.24, ts.Y * 0.22, -ts.Z * 0.54), rgb(255, 210, 60))
	local left = part(model, "LeftHand")
	block(model, left, Vector3.new(0.8, 1.1, 0.08), CFrame.new(0, 0.2, -0.3), rgb(150, 100, 50), Enum.Material.Wood)
	block(model, left, Vector3.new(0.65, 0.85, 0.09), CFrame.new(0, 0.15, -0.31), rgb(250, 250, 245))
	block(model, left, Vector3.new(0.3, 0.1, 0.12), CFrame.new(0, 0.72, -0.32), rgb(180, 180, 190), Enum.Material.Metal)
	wireGlasses(model, head, hs, 0.05, 0.17)
	-- whistle on a lanyard
	block(model, torso, Vector3.new(0.14, 0.14, 0.3), CFrame.new(-ts.X * 0.15, -ts.Y * 0.05, -ts.Z * 0.62), rgb(200, 200, 210), Enum.Material.Metal)
end

function Props.add(model, def)
	local build = B[def.prop]
	if not build then return end
	local head = model:FindFirstChild("Head")
	build(model, head, head.Size)
end

---------------------------------------------------------------------------
-- teachers: adult rigs, one recognisable outfit each (Config.Teachers[].outfit)
---------------------------------------------------------------------------
local T = {}
Props.TeacherLooks = {
	sub = { skin = "light", shirt = rgb(196, 176, 136), pants = rgb(105, 88, 70) },
	tia = { skin = "tan", shirt = rgb(60, 180, 170), pants = rgb(40, 50, 90) },
	chalk = { skin = "light", shirt = rgb(245, 245, 240), torso = rgb(120, 80, 50), pants = rgb(90, 92, 100) },
	honey = { skin = "brown", shirt = rgb(240, 190, 70), pants = rgb(120, 30, 50) },
	coach = { skin = "dark", shirt = rgb(210, 40, 40), pants = rgb(210, 40, 40) },
	beaker = { skin = "light", shirt = rgb(250, 250, 250), pants = rgb(50, 55, 70) },
	verse = { skin = "tan", shirt = rgb(130, 60, 170), pants = rgb(30, 30, 36) },
	tweed = { skin = "light", shirt = rgb(140, 110, 80), pants = rgb(95, 75, 55) },
	dean = { skin = "brown", shirt = rgb(30, 30, 40), pants = rgb(30, 30, 40) },
	mage = { skin = "light", shirt = rgb(90, 50, 170), pants = rgb(90, 50, 170) },
	nova = { skin = "tan", shirt = rgb(236, 238, 244), pants = rgb(236, 238, 244) },
	omni = { skin = "light", shirt = rgb(40, 30, 90), pants = rgb(40, 30, 90) },
}

local function hairCap(model, head, hs, c, height)
	blob(model, head, Vector3.new(hs.X * 1.08, hs.Y * (height or 0.66), hs.Z * 1.12), CFrame.new(0, hs.Y * 0.22, hs.Z * 0.06), c)
	blob(model, head, Vector3.new(hs.X * 0.98, hs.Y * 0.26, hs.Z * 0.42), CFrame.new(0, hs.Y * 0.33, -hs.Z * 0.3), c)
end

local function lanyard(model, torso, ts, color)
	for _, x in { -1, 1 } do
		block(model, torso, Vector3.new(0.06, ts.Y * 0.5, 0.05), CFrame.new(x * ts.X * 0.12, ts.Y * 0.2, -ts.Z * 0.53) * CFrame.Angles(0, 0, math.rad(x * -14)), color)
	end
end

-- Substitute Steve: rumpled cardigan, messy hair, a coffee he never puts down, a SUB badge
T.sub = function(model, head, hs, torso, ts)
	local brown = rgb(110, 75, 45)
	hairCap(model, head, hs, brown)
	for i, a in { -30, 10, 40 } do
		blob(model, head, Vector3.new(hs.X * 0.35, hs.Y * 0.3, hs.X * 0.35), CFrame.new(hs.X * (i - 2) * 0.25, hs.Y * 0.55, 0) * CFrame.Angles(0, 0, math.rad(a)), brown)
	end
	-- tired eyes
	for _, x in { -0.2, 0.2 } do
		block(model, head, Vector3.new(hs.X * 0.2, hs.Y * 0.04, 0.05), CFrame.new(hs.X * x, hs.Y * 0.02, -hs.Z * 0.5), rgb(120, 90, 110))
	end
	local hand = part(model, "RightHand")
	cylY(model, hand, 0.55, 0.65, CFrame.new(0, 0.1, -0.35), rgb(250, 250, 250))
	cylY(model, hand, 0.5, 0.05, CFrame.new(0, 0.44, -0.35), rgb(90, 55, 30))
	block(model, torso, Vector3.new(ts.X * 0.28, ts.Y * 0.16, 0.06), CFrame.new(ts.X * 0.22, ts.Y * 0.2, -ts.Z * 0.54), rgb(255, 255, 255))
	block(model, torso, Vector3.new(ts.X * 0.2, ts.Y * 0.05, 0.07), CFrame.new(ts.X * 0.22, ts.Y * 0.2, -ts.Z * 0.56), rgb(220, 40, 40))
end

-- Student Teacher Tia: ponytail, lanyard and a clipboard full of gold stars
T.tia = function(model, head, hs, torso, ts)
	local c = rgb(90, 50, 30)
	hairCap(model, head, hs, c, 0.8)
	-- long hair falling past the shoulders, and a high ponytail with a pink band
	for _, x in { -1, 1 } do
		blob(model, head, Vector3.new(hs.X * 0.28, hs.Y * 1.1, hs.Z * 0.7), CFrame.new(x * hs.X * 0.5, -hs.Y * 0.2, hs.Z * 0.1), c)
	end
	blob(model, head, Vector3.new(hs.X * 0.9, hs.Y * 1.1, hs.Z * 0.3), CFrame.new(0, -hs.Y * 0.2, hs.Z * 0.5), c)
	blob(model, head, Vector3.new(hs.X * 0.35, hs.Y * 0.9, hs.X * 0.35), CFrame.new(0, hs.Y * 0.35, hs.Z * 0.75) * CFrame.Angles(math.rad(35), 0, 0), c)
	ball(model, head, hs.X * 0.2, CFrame.new(0, hs.Y * 0.5, hs.Z * 0.55), rgb(255, 120, 170))
	lanyard(model, torso, ts, rgb(255, 120, 170))
	local hand = part(model, "LeftHand")
	block(model, hand, Vector3.new(0.95, 1.25, 0.08), CFrame.new(0, 0.25, -0.3), rgb(150, 100, 60))
	block(model, hand, Vector3.new(0.8, 1.05, 0.1), CFrame.new(0, 0.2, -0.32), rgb(250, 250, 245))
	for i = 0, 2 do
		block(model, hand, Vector3.new(0.16, 0.16, 0.11), CFrame.new(-0.2 + i * 0.2, 0.5, -0.38), rgb(255, 200, 40), Enum.Material.Neon)
	end
end

-- Mr. Chalk: bald on top with grey sides, round glasses, red bow tie, a long pointer stick
T.chalk = function(model, head, hs, torso, ts)
	local grey = rgb(170, 170, 175)
	for _, x in { -1, 1 } do
		blob(model, head, Vector3.new(hs.X * 0.25, hs.Y * 0.45, hs.Z * 0.9), CFrame.new(x * hs.X * 0.48, hs.Y * 0.05, hs.Z * 0.1), grey)
	end
	blob(model, head, Vector3.new(hs.X * 0.9, hs.Y * 0.35, hs.Z * 0.25), CFrame.new(0, 0, hs.Z * 0.48), grey)
	wireGlasses(model, head, hs, 0.05, 0.15)
	for _, x in { -1, 1 } do
		block(model, torso, Vector3.new(ts.X * 0.14, ts.Y * 0.12, 0.08), CFrame.new(x * ts.X * 0.08, ts.Y * 0.42, -ts.Z * 0.54) * CFrame.Angles(0, 0, math.rad(x * 20)), rgb(210, 30, 40))
	end
	ball(model, torso, 0.12, CFrame.new(0, ts.Y * 0.42, -ts.Z * 0.56), rgb(170, 20, 30))
	-- chalk dust on the vest
	for i = 1, 3 do
		blob(model, torso, Vector3.new(0.25, 0.18, 0.05), CFrame.new(ts.X * (0.25 - i * 0.12), -ts.Y * (0.1 + i * 0.08), -ts.Z * 0.53), rgb(250, 250, 250))
	end
	local hand = part(model, "RightHand")
	cylY(model, hand, 0.1, 2.4, CFrame.new(0, -1.1, -0.15), rgb(120, 80, 40), Enum.Material.Wood)
	ball(model, hand, 0.16, CFrame.new(0, -2.3, -0.15), rgb(30, 30, 30))
end

-- Ms. Honeycutt: bun with a pencil through it, red cat-eye glasses, a very large book
T.honey = function(model, head, hs, torso, ts)
	local c = rgb(35, 25, 20)
	hairCap(model, head, hs, c)
	local bun = ball(model, head, hs.X * 0.55, CFrame.new(0, hs.Y * 0.62, hs.Z * 0.2), c)
	block(model, head, Vector3.new(hs.X * 1.1, 0.1, 0.1), CFrame.new(0, hs.Y * 0.66, hs.Z * 0.2) * CFrame.Angles(0, 0, math.rad(25)), rgb(255, 200, 40))
	_ = bun
	for _, x in { -1, 1 } do
		block(model, head, Vector3.new(hs.X * 0.34, hs.Y * 0.18, 0.06), CFrame.new(x * hs.X * 0.21, hs.Y * 0.07, -hs.Z * 0.53) * CFrame.Angles(0, 0, math.rad(x * -12)), rgb(200, 30, 50))
		local lens = block(model, head, Vector3.new(hs.X * 0.24, hs.Y * 0.1, 0.07), CFrame.new(x * hs.X * 0.21, hs.Y * 0.07, -hs.Z * 0.55), rgb(230, 240, 255), Enum.Material.Glass)
		lens.Transparency = 0.5
	end
	local hand = part(model, "LeftHand")
	block(model, hand, Vector3.new(0.5, 1.5, 1.2), CFrame.new(0, 0.3, -0.3), rgb(40, 90, 170))
	block(model, hand, Vector3.new(0.52, 1.4, 1.05), CFrame.new(0, 0.3, -0.36), rgb(250, 245, 225))
	-- pearls
	for i = -3, 3 do
		ball(model, torso, 0.16, CFrame.new(i * ts.X * 0.07, ts.Y * (0.38 - math.abs(i) * -0.02 - 0.06), -ts.Z * 0.55), rgb(250, 250, 245))
	end
end

-- Coach Rex: cap, whistle, sweatband, clipboard
T.coach = function(model, head, hs, torso, ts)
	local red, white = rgb(210, 40, 40), rgb(250, 250, 250)
	blob(model, head, Vector3.new(hs.X * 1.1, hs.Y * 0.55, hs.Z * 1.12), CFrame.new(0, hs.Y * 0.32, hs.Z * 0.02), red)
	block(model, head, Vector3.new(hs.X * 0.95, 0.12, hs.Z * 0.6), CFrame.new(0, hs.Y * 0.28, -hs.Z * 0.62), red)
	block(model, head, Vector3.new(hs.X * 1.1, hs.Y * 0.1, hs.Z * 1.1), CFrame.new(0, hs.Y * 0.12, 0), white)
	lanyard(model, torso, ts, white)
	block(model, torso, Vector3.new(0.3, 0.18, 0.35), CFrame.new(0, -ts.Y * 0.05, -ts.Z * 0.62), rgb(200, 200, 210), Enum.Material.Metal)
	-- stripes down the tracksuit
	for _, s in { "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg" } do
		local a = part(model, s)
		if a then
			local x = s:find("Left") and -1 or 1
			block(model, a, Vector3.new(0.06, a.Size.Y * 1.01, a.Size.Z * 0.3), CFrame.new(x * a.Size.X * 0.51, 0, 0), white)
		end
	end
	local hand = part(model, "LeftHand")
	block(model, hand, Vector3.new(0.95, 1.25, 0.08), CFrame.new(0, 0.25, -0.3), rgb(60, 60, 70))
	block(model, hand, Vector3.new(0.8, 1.05, 0.1), CFrame.new(0, 0.2, -0.32), white)
	for i = 0, 2 do
		block(model, hand, Vector3.new(0.6, 0.05, 0.11), CFrame.new(0, 0.5 - i * 0.25, -0.38), rgb(40, 40, 50))
	end
end

-- Dr. Beaker: lab coat, wild white hair, goggles up, a bubbling green beaker
T.beaker = function(model, head, hs, torso, ts)
	local white = rgb(245, 245, 245)
	for i = 0, 6 do
		local a = math.rad(i * 51)
		ball(model, head, hs.X * 0.45, CFrame.new(math.cos(a) * hs.X * 0.42, hs.Y * (0.3 + (i % 2) * 0.12), math.sin(a) * hs.Z * 0.42), white)
	end
	block(model, head, Vector3.new(hs.X * 1.12, hs.Y * 0.12, hs.Z * 1.12), CFrame.new(0, hs.Y * 0.32, 0), rgb(40, 40, 45))
	for _, x in { -0.22, 0.22 } do
		local g = cylZ(model, head, hs.X * 0.3, 0.12, CFrame.new(hs.X * x, hs.Y * 0.34, -hs.Z * 0.55), rgb(120, 220, 255), Enum.Material.Glass)
		g.Transparency = 0.3
	end
	-- coat lapels and a pocket of pens
	for _, x in { -1, 1 } do
		block(model, torso, Vector3.new(ts.X * 0.18, ts.Y * 0.8, 0.05), CFrame.new(x * ts.X * 0.12, 0, -ts.Z * 0.53) * CFrame.Angles(0, 0, math.rad(x * 8)), rgb(225, 225, 230))
	end
	for i, c in { rgb(220, 40, 40), rgb(40, 90, 220), rgb(40, 40, 40) } do
		block(model, torso, Vector3.new(0.06, 0.35, 0.06), CFrame.new(-ts.X * (0.2 + i * 0.06), ts.Y * 0.28, -ts.Z * 0.56), c)
	end
	local hand = part(model, "RightHand")
	local glass = cylY(model, hand, 0.95, 1.2, CFrame.new(0, 0.35, -0.55), rgb(220, 240, 255), Enum.Material.Glass)
	glass.Transparency = 0.45
	cylY(model, hand, 0.85, 0.75, CFrame.new(0, 0.15, -0.55), rgb(90, 255, 90), Enum.Material.Neon)
	cylY(model, hand, 0.4, 0.5, CFrame.new(0, 1.1, -0.55), rgb(220, 240, 255), Enum.Material.Glass).Transparency = 0.45
	sparkles(glass, rgb(140, 255, 140), 6)
end

-- Madame Verse: beret, striped scarf, a feather quill
T.verse = function(model, head, hs, torso, ts)
	hairCap(model, head, hs, rgb(20, 16, 14))
	blob(model, head, Vector3.new(hs.X * 1.2, hs.Y * 0.28, hs.Z * 1.2), CFrame.new(-hs.X * 0.1, hs.Y * 0.55, 0) * CFrame.Angles(0, 0, math.rad(12)), rgb(170, 30, 50))
	ball(model, head, 0.2, CFrame.new(-hs.X * 0.05, hs.Y * 0.72, 0), rgb(170, 30, 50))
	for i = 0, 3 do
		block(model, torso, Vector3.new(ts.X * 0.95, 0.18, ts.Z * 1.08), CFrame.new(0, ts.Y * 0.44 - i * 0.02, 0) * CFrame.Angles(0, math.rad(i * 3), 0), i % 2 == 0 and rgb(250, 200, 60) or rgb(220, 60, 90))
	end
	block(model, torso, Vector3.new(0.35, ts.Y * 0.7, 0.1), CFrame.new(ts.X * 0.18, ts.Y * 0.05, -ts.Z * 0.56), rgb(250, 200, 60))
	local hand = part(model, "RightHand")
	cylY(model, hand, 0.07, 1.6, CFrame.new(0, 0.7, -0.25) * CFrame.Angles(math.rad(-20), 0, 0), rgb(40, 30, 30))
	blob(model, hand, Vector3.new(0.12, 1.5, 0.6), CFrame.new(0, 1.3, -0.5) * CFrame.Angles(math.rad(-20), 0, 0), rgb(200, 90, 255))
	blob(model, hand, Vector3.new(0.13, 0.9, 0.3), CFrame.new(0, 1.3, -0.52) * CFrame.Angles(math.rad(-20), 0, 0), rgb(255, 170, 230))
end

-- Professor Tweed: white beard and side hair, bow tie, elbow patches, a stack of books
T.tweed = function(model, head, hs, torso, ts)
	local white = rgb(240, 240, 242)
	for _, x in { -1, 1 } do
		blob(model, head, Vector3.new(hs.X * 0.25, hs.Y * 0.45, hs.Z * 0.9), CFrame.new(x * hs.X * 0.48, hs.Y * 0.1, hs.Z * 0.1), white)
	end
	blob(model, head, Vector3.new(hs.X * 0.85, hs.Y * 0.5, hs.Z * 0.4), CFrame.new(0, -hs.Y * 0.35, -hs.Z * 0.3), white)
	wireGlasses(model, head, hs, 0.05, 0.14)
	block(model, torso, Vector3.new(ts.X * 0.3, ts.Y * 0.12, 0.08), CFrame.new(0, ts.Y * 0.42, -ts.Z * 0.54), rgb(40, 90, 60))
	for _, s in { "LeftLowerArm", "RightLowerArm" } do
		local a = part(model, s)
		blob(model, a, Vector3.new(a.Size.X * 0.7, a.Size.Y * 0.4, 0.1), CFrame.new(0, 0, a.Size.Z * 0.5), rgb(90, 60, 40))
	end
	local hand = part(model, "LeftHand")
	for i, c in { rgb(150, 40, 40), rgb(40, 70, 130), rgb(60, 110, 60) } do
		block(model, hand, Vector3.new(0.9, 0.28, 1.2), CFrame.new(0, 0.1 + i * 0.28, -0.3), c)
	end
end

-- Dean Maximus: black robe, mortarboard, gold chain of office
T.dean = function(model, head, hs, torso, ts)
	local black, gold = rgb(25, 25, 30), rgb(255, 200, 60)
	cylY(model, head, hs.X * 1.05, hs.Y * 0.3, CFrame.new(0, hs.Y * 0.42, 0), black)
	block(model, head, Vector3.new(hs.X * 1.7, 0.1, hs.X * 1.7), CFrame.new(0, hs.Y * 0.6, 0) * CFrame.Angles(0, math.rad(45), 0), black)
	ball(model, head, 0.18, CFrame.new(0, hs.Y * 0.66, 0), gold)
	block(model, head, Vector3.new(0.1, hs.Y * 0.45, 0.1), CFrame.new(hs.X * 0.6, hs.Y * 0.4, -hs.X * 0.6), gold)
	for i = -4, 4 do
		ball(model, torso, 0.16, CFrame.new(i * ts.X * 0.08, ts.Y * (0.4 - (4 - math.abs(i)) * 0.07), -ts.Z * 0.56), gold, Enum.Material.Metal)
	end
	cylZ(model, torso, 0.55, 0.1, CFrame.new(0, ts.Y * 0.05, -ts.Z * 0.58), gold, Enum.Material.Metal)
	-- robe sleeves
	for _, s in { "LeftUpperArm", "RightUpperArm" } do
		local a = part(model, s)
		blob(model, a, Vector3.new(a.Size.X * 1.5, a.Size.Y * 1.1, a.Size.Z * 1.5), CFrame.new(0, -a.Size.Y * 0.1, 0), black)
	end
	blob(model, part(model, "LowerTorso"), Vector3.new(ts.X * 1.25, ts.Y * 1.6, ts.Z * 1.4), CFrame.new(0, -ts.Y * 0.6, 0), black)
end

-- Archmage Quill: tall starry hat, long beard, a staff with a glowing orb
T.mage = function(model, head, hs, torso, ts)
	local purple = rgb(90, 50, 170)
	cylY(model, head, hs.X * 1.5, 0.15, CFrame.new(0, hs.Y * 0.4, 0), purple)
	local cf = CFrame.new(0, hs.Y * 0.5, 0)
	local d = hs.X * 1.05
	for i = 1, 5 do
		local len = hs.Y * 0.35
		cf = cf * CFrame.Angles(math.rad(i == 5 and 25 or 5), 0, 0) * CFrame.new(0, len * 0.5, 0)
		cylY(model, head, d, len, cf, purple)
		cf = cf * CFrame.new(0, len * 0.45, 0)
		d *= 0.75
	end
	for i = 1, 3 do
		ball(model, head, 0.2, CFrame.new(hs.X * (0.2 - i * 0.15), hs.Y * (0.6 + i * 0.25), -hs.Z * 0.3), rgb(255, 230, 90), Enum.Material.Neon)
	end
	blob(model, head, Vector3.new(hs.X * 0.8, hs.Y * 1.1, hs.Z * 0.4), CFrame.new(0, -hs.Y * 0.6, -hs.Z * 0.3), rgb(240, 240, 245))
	local hand = part(model, "RightHand")
	cylY(model, hand, 0.18, 4.2, CFrame.new(0, 0.9, -0.2), rgb(110, 70, 40), Enum.Material.Wood)
	local orb = ball(model, hand, 0.7, CFrame.new(0, 3.2, -0.2), rgb(120, 200, 255), Enum.Material.Neon)
	sparkles(orb, rgb(170, 220, 255), 10)
	blob(model, part(model, "LowerTorso"), Vector3.new(ts.X * 1.25, ts.Y * 1.6, ts.Z * 1.4), CFrame.new(0, -ts.Y * 0.6, 0), purple)
end

-- Commander Nova: space suit, bubble helmet, jetpack, mission patch
T.nova = function(model, head, hs, torso, ts)
	hairCap(model, head, hs, rgb(30, 22, 18))
	local bubble = ball(model, head, hs.X * 1.55, CFrame.new(0, hs.Y * 0.05, 0), rgb(200, 230, 255), Enum.Material.Glass)
	bubble.Transparency = 0.7
	block(model, torso, Vector3.new(ts.X * 1.2, 0.3, ts.Z * 1.2), CFrame.new(0, ts.Y * 0.5, 0), rgb(200, 205, 215), Enum.Material.Metal)
	for _, x in { -1, 1 } do
		cylY(model, torso, ts.X * 0.3, ts.Y * 0.9, CFrame.new(x * ts.X * 0.2, 0, ts.Z * 0.75), rgb(200, 205, 215), Enum.Material.Metal)
		cylY(model, torso, ts.X * 0.18, 0.3, CFrame.new(x * ts.X * 0.2, -ts.Y * 0.55, ts.Z * 0.75), rgb(255, 140, 40), Enum.Material.Neon)
	end
	cylZ(model, torso, ts.X * 0.3, 0.08, CFrame.new(-ts.X * 0.22, ts.Y * 0.2, -ts.Z * 0.54), rgb(40, 80, 200))
	ball(model, torso, 0.14, CFrame.new(-ts.X * 0.22, ts.Y * 0.2, -ts.Z * 0.6), rgb(255, 255, 255), Enum.Material.Neon)
end

-- The Omniteacher: cosmic robe, a halo, books orbiting around them
T.omni = function(model, head, hs, torso, ts)
	hairCap(model, head, hs, rgb(240, 240, 255))
	local halo = cylY(model, head, hs.X * 1.3, 0.08, CFrame.new(0, hs.Y * 0.95, 0), rgb(255, 240, 150), Enum.Material.Neon)
	_ = halo
	for i = 0, 5 do
		ball(model, torso, 0.18, CFrame.new(math.cos(i) * ts.X * 0.3, ts.Y * (0.3 - i * 0.12), -ts.Z * 0.55), rgb(255, 255, 255), Enum.Material.Neon)
	end
	local piv = pivot(model, part(model, "HumanoidRootPart"), CFrame.new(0, 1.2, 0), 60)
	for i = 0, 3 do
		local a = math.rad(i * 90)
		local c = ({ rgb(230, 60, 60), rgb(60, 140, 230), rgb(250, 200, 60), rgb(80, 200, 110) })[i + 1]
		block(model, piv, Vector3.new(0.9, 1.2, 0.3), CFrame.new(math.cos(a) * 3, math.sin(i) * 0.4, math.sin(a) * 3) * CFrame.Angles(0, -a, 0), c)
	end
	blob(model, part(model, "LowerTorso"), Vector3.new(ts.X * 1.25, ts.Y * 1.6, ts.Z * 1.4), CFrame.new(0, -ts.Y * 0.6, 0), rgb(40, 30, 90))
	sparkles(part(model, "HumanoidRootPart"), rgb(200, 180, 255), 10)
end

-- Crumpet, Vex's butler: tailcoat, white gloves, slicked hair, a silver tray and a feather duster
Props.TeacherLooks.butler = { skin = "light", shirt = Color3.fromRGB(30, 30, 36), pants = Color3.fromRGB(30, 30, 36) }
T.butler = function(model, head, hs, torso, ts)
	hairCap(model, head, hs, rgb(25, 22, 20), 0.5)
	-- white shirt front and a bow tie
	block(model, torso, Vector3.new(ts.X * 0.32, ts.Y * 0.85, 0.05), CFrame.new(0, 0, -ts.Z * 0.53), rgb(250, 250, 250))
	for _, x in { -1, 1 } do
		block(model, torso, Vector3.new(ts.X * 0.12, ts.Y * 0.1, 0.08), CFrame.new(x * ts.X * 0.07, ts.Y * 0.4, -ts.Z * 0.56) * CFrame.Angles(0, 0, math.rad(x * 20)), rgb(20, 20, 20))
	end
	-- coat tails
	local lower = part(model, "LowerTorso")
	for _, x in { -1, 1 } do
		block(model, lower, Vector3.new(ts.X * 0.3, ts.Y * 1.1, 0.12), CFrame.new(x * ts.X * 0.18, -ts.Y * 0.6, ts.Z * 0.52) * CFrame.Angles(math.rad(8), 0, 0), rgb(30, 30, 36))
	end
	for _, h in { "LeftHand", "RightHand" } do
		local hand = part(model, h)
		if hand then hand.Color = rgb(250, 250, 250) end
	end
	-- a very thin moustache
	block(model, head, Vector3.new(hs.X * 0.4, hs.Y * 0.04, 0.05), CFrame.new(0, -hs.Y * 0.14, -hs.Z * 0.51), rgb(25, 22, 20))
	local left = part(model, "LeftHand")
	cylY(model, left, 1.6, 0.08, CFrame.new(0, 0.1, -0.5), rgb(200, 205, 215), Enum.Material.Metal)
	local right = part(model, "RightHand")
	cylY(model, right, 0.1, 1.2, CFrame.new(0, 0.5, -0.2), rgb(120, 80, 40), Enum.Material.Wood)
	for i = 0, 4 do
		blob(model, right, Vector3.new(0.25, 0.8, 0.12), CFrame.new(0, 1.3, -0.2) * CFrame.Angles(0, math.rad(i * 36), math.rad(18)), ({ rgb(255, 120, 180), rgb(255, 200, 80), rgb(120, 200, 255) })[i % 3 + 1])
	end
end

function Props.teacher(model, outfit)
	local build = T[outfit]
	if not build then return end
	local head = model:FindFirstChild("Head")
	local torso = model:FindFirstChild("UpperTorso")
	build(model, head, head.Size, torso, torso.Size)
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
	local color = ({ Legendary = Color3.fromRGB(255, 190, 40), Mythic = Color3.fromRGB(255, 60, 100), Secret = Color3.fromRGB(190, 110, 255) })[def.rarity]
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 8
	light.Brightness = 0.6
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
