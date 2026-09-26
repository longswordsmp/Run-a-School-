-- Swaps Detention on an existing map for the current design in build_map.lua (Edit mode).
return function()
local map = workspace.Map
local old = map:FindFirstChild("Detention")
if old then old:Destroy() end
local KEEP_SMOOTH = { [Enum.Material.Neon] = true, [Enum.Material.Glass] = true, [Enum.Material.Metal] = true, [Enum.Material.ForceField] = true }
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
	if props then for k, v in props do p[k] = v end end
	p.Parent = parent
	return p
end
local HIDDEN = { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false }
local rgb = Color3.fromRGB

local function signGui(p, face, text, textColor, bg, font)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.LightInfluence = 0
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Name = "Label"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = bg or Color3.new(1, 1, 1)
	t.BackgroundTransparency = bg and 0 or 1
	t.Text = text
	t.TextScaled = true
	t.Font = font or Enum.Font.FredokaOne
	t.TextColor3 = textColor
	t.Parent = g
	local s = Instance.new("UIStroke")
	s.Thickness = 4
	s.Color = rgb(30, 20, 40)
	s.Parent = t
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.04, 0); pad.PaddingRight = UDim.new(0.04, 0)
	pad.PaddingTop = UDim.new(0.08, 0); pad.PaddingBottom = UDim.new(0.08, 0)
	pad.Parent = t
	return g, t
end

local C = {
	grass = rgb(104, 196, 84),
	lawn = rgb(96, 186, 78),
	sidewalk = rgb(214, 214, 222),
	curb = rgb(175, 175, 185),
	carpet = rgb(214, 44, 58),
	trim = rgb(255, 196, 40),
	bus = rgb(255, 190, 20),
	leaf = rgb(60, 170, 70),
	trunk = rgb(120, 80, 50),
	white = rgb(250, 250, 250),
}
---------------------------------------------------------------------------
-- detention at the east end
---------------------------------------------------------------------------
-- Detention Hall: a grim little two-storey block where the street ends (kids who give up on waiting
-- walk in through its doors). Barred windows, a porch with lamps, a clock stuck at 3:00, a water
-- tank and a searchlight on the roof, and a fenced yard with a hoop that has no net.
local det = Instance.new("Model"); det.Name = "Detention"; det.Parent = map
local DX0, DX1, DZ = 350, 376, 17 -- front face (the street end), back face, half width
local DH = 20
local BRICK, TRIM, DARK, IRON = rgb(96, 92, 104), rgb(168, 164, 162), rgb(40, 40, 50), rgb(52, 52, 60)
local function dp(name, size, cf, color, material, props)
	local p = part(det, name, size, cf, color, material or Enum.Material.SmoothPlastic, props)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end
local cx = (DX0 + DX1) / 2
dp("Block", Vector3.new(DX1 - DX0, DH, DZ * 2), CFrame.new(cx, DH / 2, 0), BRICK, Enum.Material.Brick)
dp("Base", Vector3.new(DX1 - DX0 + 0.5, 2.4, DZ * 2 + 0.5), CFrame.new(cx, 1.2, 0), TRIM, Enum.Material.Concrete)
dp("Band", Vector3.new(DX1 - DX0 + 0.4, 0.6, DZ * 2 + 0.4), CFrame.new(cx, 10.3, 0), TRIM, Enum.Material.Concrete)
dp("Cornice", Vector3.new(DX1 - DX0 + 1, 1.2, DZ * 2 + 1), CFrame.new(cx, DH + 0.2, 0), rgb(70, 68, 78), Enum.Material.Concrete)
dp("Roof", Vector3.new(DX1 - DX0 - 1, 0.4, DZ * 2 - 1), CFrame.new(cx, DH + 0.9, 0), rgb(60, 60, 66), Enum.Material.Slate)
for _, x in { DX0, DX1 } do
	for _, z in { -DZ, DZ } do
		dp("Pilaster", Vector3.new(1.8, DH, 1.8), CFrame.new(x, DH / 2, z), TRIM, Enum.Material.Concrete)
	end
end

-- a barred window: frame, dark glass, iron bars, a sill. cf: the window centre on the wall, looking out
local function window(cf, w, h)
	dp("WindowFrame", Vector3.new(w + 0.6, h + 0.6, 0.2), cf * CFrame.new(0, 0, -0.1), TRIM, Enum.Material.Concrete)
	dp("Window", Vector3.new(w, h, 0.2), cf * CFrame.new(0, 0, -0.15), rgb(44, 52, 66), Enum.Material.Glass, { Transparency = 0.1 })
	local n = math.max(3, math.floor(w / 0.7))
	for i = 1, n do
		dp("Bar", Vector3.new(0.14, h + 0.2, 0.14), cf * CFrame.new(-w / 2 + i * w / (n + 1), 0, -0.4), IRON, Enum.Material.Metal)
	end
	dp("Bar", Vector3.new(w + 0.2, 0.14, 0.14), cf * CFrame.new(0, h * 0.2, -0.4), IRON, Enum.Material.Metal)
	dp("Sill", Vector3.new(w + 0.9, 0.3, 0.7), cf * CFrame.new(0, -h / 2 - 0.4, -0.35), TRIM, Enum.Material.Concrete)
end
local FRONT = CFrame.Angles(0, math.rad(90), 0) -- looking out of the front (-X)
local SIDE_N = CFrame.new() -- looking out along -Z
local SIDE_S = CFrame.Angles(0, math.rad(180), 0) -- looking out along +Z
for _, z in { -13.8, -9.6, 9.6, 13.8 } do window(CFrame.new(DX0, 5.8, z) * FRONT, 2.6, 3.6) end
for _, z in { -13.8, 13.8 } do window(CFrame.new(DX0, 15.6, z) * FRONT, 2.6, 3.6) end
for _, x in { 355.5, 362.5, 369.5 } do
	for _, y in { 5.8, 15.6 } do
		window(CFrame.new(x, y, -DZ) * SIDE_N, 3.2, 3.6)
		window(CFrame.new(x, y, DZ) * SIDE_S, 3.2, 3.6)
	end
end

-- the entrance: steps, a porch roof on posts with two lamps, heavy double doors
dp("DoorRecess", Vector3.new(0.3, 8, 7.4), CFrame.new(DX0 - 0.3, 5.5, 0), rgb(24, 24, 30))
for _, s in { -1, 1 } do
	-- (the doors start at the top step)
	dp("Door", Vector3.new(0.25, 7.4, 3.3), CFrame.new(DX0 - 0.55, 5.2, s * 1.7), rgb(70, 72, 82), Enum.Material.Metal)
	dp("DoorWindow", Vector3.new(0.3, 1.8, 1.3), CFrame.new(DX0 - 0.62, 7.2, s * 1.7), rgb(40, 50, 64), Enum.Material.Glass)
	dp("PushBar", Vector3.new(0.3, 0.25, 2.4), CFrame.new(DX0 - 0.75, 4.8, s * 1.7), rgb(200, 200, 208), Enum.Material.Metal)
	dp("PorchPost", Vector3.new(0.5, 9.6, 0.5), CFrame.new(DX0 - 4.2, 4.8, s * 5.6), TRIM, Enum.Material.Concrete)
	local lamp = dp("PorchLamp", Vector3.new(0.6, 0.9, 0.6), CFrame.new(DX0 - 0.6, 8.2, s * 4.6), rgb(255, 214, 150), Enum.Material.Neon)
	local l = Instance.new("PointLight")
	l.Range, l.Brightness, l.Color = 14, 1.2, rgb(255, 200, 140)
	l.Parent = lamp
end
dp("Porch", Vector3.new(4.8, 0.6, 12.4), CFrame.new(DX0 - 2.2, 9.9, 0), rgb(70, 68, 78), Enum.Material.Concrete)
for i, h in { 1.5, 1.0, 0.5 } do
	dp("Step", Vector3.new(1.3, h, 9), CFrame.new(DX0 - 0.65 - (i - 1) * 1.3, h / 2, 0), TRIM, Enum.Material.Concrete)
end
local rules = dp("Rules", Vector3.new(0.2, 1.3, 4), CFrame.new(DX0 - 0.3, 4.6, -5.9), rgb(245, 240, 225))
signGui(rules, Enum.NormalId.Left, "NO TALKING \u{2022} NO RECESS \u{2022} NO FUN", rgb(160, 30, 30), rgb(245, 240, 225), Enum.Font.GothamBold)

-- the big sign, with a red neon edge
local detSign = dp("Sign", Vector3.new(0.4, 3.6, 19), CFrame.new(DX0 - 0.25, 14.2, 0), DARK)
signGui(detSign, Enum.NormalId.Left, "DETENTION", rgb(255, 70, 70), DARK, Enum.Font.LuckiestGuy)
for _, y in { 12.3, 16.1 } do dp("SignNeon", Vector3.new(0.2, 0.2, 19.4), CFrame.new(DX0 - 0.5, y, 0), rgb(255, 60, 60), Enum.Material.Neon) end
for _, z in { -9.6, 9.6 } do dp("SignNeon", Vector3.new(0.2, 4, 0.2), CFrame.new(DX0 - 0.5, 14.2, z), rgb(255, 60, 60), Enum.Material.Neon) end

-- detention o'clock: a gable over the door with a clock stuck at 3:00
dp("Gable", Vector3.new(0.8, 5, 6.4), CFrame.new(DX0 + 0.3, DH + 3, 0), BRICK, Enum.Material.Brick)
dp("GableCap", Vector3.new(1.2, 0.5, 7), CFrame.new(DX0 + 0.3, DH + 5.6, 0), rgb(70, 68, 78), Enum.Material.Concrete)
local face = dp("ClockFace", Vector3.new(0.2, 3.8, 3.8), CFrame.new(DX0 - 0.2, DH + 3, 0), rgb(245, 240, 225), nil, { Shape = Enum.PartType.Cylinder })
dp("ClockRim", Vector3.new(0.15, 4.2, 4.2), CFrame.new(DX0 - 0.12, DH + 3, 0), IRON, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
dp("HourHand", Vector3.new(0.1, 0.25, 1.2), CFrame.new(DX0 - 0.35, DH + 3, 0.6), rgb(20, 20, 24))
dp("MinuteHand", Vector3.new(0.1, 1.6, 0.18), CFrame.new(DX0 - 0.37, DH + 3.8, 0), rgb(20, 20, 24))
_ = face

-- on the roof: a water tank on legs, a searchlight; a camera watching the door
local tx, tz = DX1 - 5, 9
for _, dx in { -1.8, 1.8 } do
	for _, dz in { -1.8, 1.8 } do
		dp("TankLeg", Vector3.new(0.35, 4, 0.35), CFrame.new(tx + dx, DH + 3, tz + dz), IRON, Enum.Material.Metal)
	end
end
dp("Tank", Vector3.new(5, 5.2, 5.2), CFrame.new(tx, DH + 7.5, tz) * CFrame.Angles(0, 0, math.rad(90)), rgb(120, 100, 84), Enum.Material.WoodPlanks, { Shape = Enum.PartType.Cylinder })
dp("TankTop", Vector3.new(1, 4, 4), CFrame.new(tx, DH + 10.4, tz) * CFrame.Angles(0, 0, math.rad(90)), rgb(90, 76, 64), Enum.Material.WoodPlanks, { Shape = Enum.PartType.Cylinder })
dp("TankTop", Vector3.new(0.8, 2, 2), CFrame.new(tx, DH + 11.2, tz) * CFrame.Angles(0, 0, math.rad(90)), rgb(90, 76, 64), Enum.Material.WoodPlanks, { Shape = Enum.PartType.Cylinder })
dp("SearchBase", Vector3.new(1.4, 1.2, 1.4), CFrame.new(DX0 + 3, DH + 1.7, -DZ + 3), IRON, Enum.Material.Metal)
local search = dp("Searchlight", Vector3.new(1.4, 1.8, 1.8), CFrame.new(DX0 + 3, DH + 3, -DZ + 3) * CFrame.Angles(0, 0, math.rad(120)), rgb(230, 230, 236), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
local lens = dp("SearchLens", Vector3.new(0.2, 1.5, 1.5), search.CFrame * CFrame.new(0.75, 0, 0), rgb(255, 250, 220), Enum.Material.Neon, { Shape = Enum.PartType.Cylinder })
local beam = Instance.new("SpotLight")
beam.Face, beam.Range, beam.Angle, beam.Brightness = Enum.NormalId.Right, 40, 30, 2
beam.Parent = lens
dp("CameraArm", Vector3.new(1.4, 0.2, 0.2), CFrame.new(DX0 - 0.7, 11.8, -DZ + 1.2), IRON, Enum.Material.Metal)
dp("Camera", Vector3.new(1.2, 0.7, 0.7), CFrame.new(DX0 - 1.4, 11.6, -DZ + 1.2) * CFrame.Angles(0, math.rad(-25), math.rad(-15)), rgb(225, 225, 230))
dp("CameraLight", Vector3.new(0.12, 0.2, 0.2), CFrame.new(DX0 - 2, 11.45, -DZ + 1.1), rgb(255, 40, 40), Enum.Material.Neon)

-- the yard on the south side: a fence of mesh panels, a hoop with no net, a sign
local YZ0, YZ1 = -DZ - 1, -DZ - 11
local function fence(x0, z0, x1, z1)
	local len = math.max(math.abs(x1 - x0), math.abs(z1 - z0))
	local along = x1 ~= x0
	local mid = Vector3.new((x0 + x1) / 2, 0, (z0 + z1) / 2)
	dp("Mesh", along and Vector3.new(len, 7, 0.1) or Vector3.new(0.1, 7, len), CFrame.new(mid + Vector3.new(0, 3.6, 0)), rgb(150, 155, 160), Enum.Material.DiamondPlate, { Transparency = 0.55 })
	dp("Rail", along and Vector3.new(len, 0.2, 0.2) or Vector3.new(0.2, 0.2, len), CFrame.new(mid + Vector3.new(0, 7.2, 0)), IRON, Enum.Material.Metal)
	local n = math.floor(len / 4)
	for i = 0, n do
		local t = i / n
		dp("FencePost", Vector3.new(0.3, 7.6, 0.3), CFrame.new(x0 + (x1 - x0) * t, 3.8, z0 + (z1 - z0) * t), IRON, Enum.Material.Metal)
	end
end
fence(DX0 + 4, YZ1, DX1, YZ1)
fence(DX0 + 4, YZ0, DX0 + 4, YZ1)
fence(DX1, YZ0, DX1, YZ1)
dp("YardFloor", Vector3.new(DX1 - DX0 - 4, 0.2, YZ0 - YZ1), CFrame.new((DX0 + 4 + DX1) / 2, 0.1, (YZ0 + YZ1) / 2), rgb(120, 120, 126), Enum.Material.Asphalt)
dp("HoopPole", Vector3.new(0.4, 9, 0.4), CFrame.new(DX1 - 2, 4.5, (YZ0 + YZ1) / 2), IRON, Enum.Material.Metal)
dp("Backboard", Vector3.new(0.2, 2.6, 3.6), CFrame.new(DX1 - 2.4, 9, (YZ0 + YZ1) / 2), rgb(240, 240, 240))
local hz = (YZ0 + YZ1) / 2
for _, e in { { 0, -0.7, 1.5, 0.12 }, { 0, 0.7, 1.5, 0.12 }, { -0.7, 0, 0.12, 1.5 }, { 0.7, 0, 0.12, 1.5 } } do
	dp("Hoop", Vector3.new(e[3], 0.12, e[4]), CFrame.new(DX1 - 3.3 + e[1], 8.2, hz + e[2]), rgb(230, 90, 30), Enum.Material.Metal)
end
local noBall = dp("YardSign", Vector3.new(4, 1.4, 0.15), CFrame.new(DX0 + 12, 5, YZ1 - 0.2), rgb(245, 240, 225))
signGui(noBall, Enum.NormalId.Front, "NO BALL GAMES", rgb(160, 30, 30), rgb(245, 240, 225), Enum.Font.GothamBold)

return #det:GetDescendants()
end
