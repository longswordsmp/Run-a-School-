-- Builds the static world in Edit mode (re-runnable). The school buildings themselves are built at
-- runtime by ServerScriptService.Server.SchoolBuilder into each Plot's "School" model.
--   Workspace.Map        ground, main street with the red carpet, bus stop, detention, hub arch,
--                        lamps, trees
--   Workspace.Plots.PlotN  a 120 x 150 lot: lawn, curb, gate arch with the school sign, laser gate,
--                        lock button, Origin / Entry / Spawn / Bounds markers
--   Workspace.BoardRoom  the School Board's meeting room high above the map (cutscene set)
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

for _, n in { "Map", "Plots", "BoardRoom", "Hall" } do
	local old = workspace:FindFirstChild(n)
	if old then old:Destroy() end
end
if ServerStorage:FindFirstChild("FloorTemplates") then ServerStorage.FloorTemplates:Destroy() end
for _, n in { "Baseplate", "SpawnLocation" } do
	if workspace:FindFirstChild(n) then workspace[n]:Destroy() end
end

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

local function billboard(p, name, text, offsetY, size)
	local bb = Instance.new("BillboardGui")
	bb.Name = name
	bb.Size = size or UDim2.fromOffset(160, 50)
	bb.StudsOffset = Vector3.new(0, offsetY or 4, 0)
	bb.MaxDistance = 80
	bb.LightInfluence = 0
	bb.Parent = p
	local t = Instance.new("TextLabel")
	t.Name = "Label"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Parent = bb
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Parent = t
	return bb
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

local map = Instance.new("Folder"); map.Name = "Map"; map.Parent = workspace
local plots = Instance.new("Folder"); plots.Name = "Plots"; plots.Parent = workspace

---------------------------------------------------------------------------
-- ground and main street
---------------------------------------------------------------------------
part(map, "Ground", Vector3.new(980, 2, 520), CFrame.new(0, -1, 0), C.grass, Enum.Material.Grass)
part(map, "Sidewalk", Vector3.new(800, 0.4, 56), CFrame.new(0, 0.2, 0), C.sidewalk, Enum.Material.Concrete)
part(map, "Carpet", Vector3.new(660, 0.3, 16), CFrame.new(0, 0.5, 0), C.carpet, Enum.Material.Fabric)
part(map, "TrimN", Vector3.new(660, 0.32, 1), CFrame.new(0, 0.5, 8.5), C.trim)
part(map, "TrimS", Vector3.new(660, 0.32, 1), CFrame.new(0, 0.5, -8.5), C.trim)
for _, z in { -28.3, 28.3 } do
	part(map, "Curb", Vector3.new(800, 0.7, 0.8), CFrame.new(0, 0.35, z), C.curb, Enum.Material.Concrete)
end
local path = Instance.new("Folder"); path.Name = "HallPath"; path.Parent = map
part(path, "Start", Vector3.new(1, 1, 1), CFrame.new(-318, 1, 0), C.trim, nil, HIDDEN)
part(path, "End", Vector3.new(1, 1, 1), CFrame.new(346, 1, 0), C.trim, nil, HIDDEN)

---------------------------------------------------------------------------
-- school bus and shelter at the west end
---------------------------------------------------------------------------
-- a conventional yellow school bus, facing +X with the passenger door on -Z (the carpet side). Built
-- in bus space: x along the bus (front +X), y up from the road, z across (0 = the middle).
-- Other code relies on: PrimaryPart "Body" and the pivot (HallService parks clones by it), parts
-- named Body/Hood (special buses recolor them), every "Sign" (its SurfaceGui Label shows the bus's
-- name), "Door" (kids step off there) and "Windshield" with the open cab behind it (Otis's seat).
local bus = Instance.new("Model"); bus.Name = "SchoolBus"; bus.Parent = map
local bx, bz = -345, 0
local BUS = CFrame.new(bx, 0, bz + 2)
local function bp(name, size, cf, color, material, props)
	local p = part(bus, name, size, BUS * cf, color, material or Enum.Material.SmoothPlastic, props)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end
local function cylX(name, d, len, pos, color, material, props)
	-- a disc or drum whose round faces point along the bus (x)
	local p = bp(name, Vector3.new(len, d, d), CFrame.new(pos), color, material, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local function cylZ(name, d, len, pos, color, material, props)
	-- round faces pointing across the bus (z): wheels, wheel wells
	local p = bp(name, Vector3.new(len, d, d), CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0), color, material, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local YEL, BLACK, CHROME = C.bus, rgb(28, 28, 32), rgb(205, 208, 215)
local GLASS = rgb(150, 200, 235)

-- the body, the cab and the roof
local body = bp("Body", Vector3.new(30, 9.8, 12), CFrame.new(-8, 7.1, 0), YEL)
body.PivotOffset = CFrame.new(2, 0.4, 0) -- (the pivot where the first bus had it: parked buses line up)
bus.PrimaryPart = body
bp("Chassis", Vector3.new(41, 0.8, 11.2), CFrame.new(-3, 1.8, 0), BLACK)
bp("Body", Vector3.new(4, 4.8, 12), CFrame.new(9, 4.6, 0), YEL) -- cab floor (Otis sits on it)
bp("Body", Vector3.new(0.4, 1.5, 12), CFrame.new(10.9, 7.75, 0), YEL) -- under the windshield
for _, s in { -1, 1 } do
	bp("Body", Vector3.new(4, 1.8, 0.3), CFrame.new(9, 7.9, s * 5.85), YEL) -- cab sides, under the side windows
	bp("Body", Vector3.new(0.5, 5, 0.5), CFrame.new(10.9, 10.3, s * 5.75), YEL) -- windshield pillars
	bp("CabWindow", Vector3.new(3.4, 2.8, 0.1), CFrame.new(9, 10.3, s * 5.9), GLASS, Enum.Material.Glass, { Transparency = 0.45 })
end
bp("Windshield", Vector3.new(0.2, 3.8, 11), CFrame.new(11.05, 10.4, 0), rgb(175, 215, 240), Enum.Material.Glass, { Transparency = 0.6 })
bp("Roof", Vector3.new(34.6, 0.7, 10.8), CFrame.new(-6, 12.35, 0), rgb(248, 248, 244))
for _, s in { -1, 1 } do
	cylX("RoofEdge", 1.5, 34.6, Vector3.new(-6, 12.05, s * 5.35), rgb(248, 248, 244))
end
for _, x in { -15, -3 } do
	bp("RoofHatch", Vector3.new(2.4, 0.3, 2.4), CFrame.new(x, 12.85, 0), rgb(190, 192, 198))
end

-- the front: a raised cap with the SCHOOL BUS sign and the warning lights
bp("Body", Vector3.new(0.8, 1.6, 11.6), CFrame.new(11, 13.1, 0), YEL)
local front = bp("FrontSign", Vector3.new(0.1, 1.1, 5.8), CFrame.new(11.45, 13.1, 0), YEL)
signGui(front, Enum.NormalId.Right, "SCHOOL BUS", rgb(20, 20, 20), YEL, Enum.Font.FredokaOne)
for _, z in { -4.9, 4.9 } do cylX("WarnRed", 0.8, 0.2, Vector3.new(11.45, 13.1, z), rgb(230, 40, 40), Enum.Material.Neon) end
for _, z in { -3.7, 3.7 } do cylX("WarnAmber", 0.8, 0.2, Vector3.new(11.45, 13.1, z), rgb(255, 160, 30), Enum.Material.Neon) end

-- the hood, sloping down to a chrome-edged grille, round headlights, black fenders and bumper
bp("Hood", Vector3.new(5.4, 5, 9.2), CFrame.new(13.7, 4.7, 0), YEL)
local slope = Instance.new("WedgePart")
slope.Name = "Hood"
slope.Anchored = true
slope.Size = Vector3.new(9.2, 0.9, 5.4)
slope.CFrame = BUS * CFrame.new(13.7, 7.65, 0) * CFrame.Angles(0, math.rad(-90), 0)
slope.Color = YEL
slope.Material = Enum.Material.SmoothPlastic
slope.TopSurface, slope.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
slope.Parent = bus
cylZ("Fender", 5.6, 10.8, Vector3.new(14, 2.3, 0), BLACK)
bp("Grille", Vector3.new(0.2, 3.8, 6.4), CFrame.new(16.5, 4.7, 0), BLACK)
for _, y in { 3.4, 4.2, 5.0, 5.8 } do bp("GrilleBar", Vector3.new(0.12, 0.18, 6), CFrame.new(16.62, y, 0), CHROME, Enum.Material.Metal) end
for _, y in { 2.75, 6.65 } do bp("GrilleTrim", Vector3.new(0.18, 0.3, 6.8), CFrame.new(16.6, y, 0), CHROME, Enum.Material.Metal) end
for _, z in { -3.3, 3.3 } do bp("GrilleTrim", Vector3.new(0.18, 4.2, 0.3), CFrame.new(16.6, 4.7, z), CHROME, Enum.Material.Metal) end
for _, s in { -1, 1 } do
	cylX("HeadlightRim", 1.8, 0.15, Vector3.new(16.45, 5.3, s * 3.95), CHROME, Enum.Material.Metal)
	cylX("Headlight", 1.4, 0.2, Vector3.new(16.5, 5.3, s * 3.95), rgb(255, 250, 225), Enum.Material.Neon)
	bp("TurnLight", Vector3.new(0.15, 0.5, 0.9), CFrame.new(16.5, 3.9, s * 3.95), rgb(255, 160, 30), Enum.Material.Neon)
	-- the big mirrors on the front corners
	bp("MirrorArm", Vector3.new(0.25, 2.6, 0.25), CFrame.new(15.6, 8.4, s * 5.2), BLACK)
	bp("Mirror", Vector3.new(0.5, 1.6, 0.9), CFrame.new(15.7, 9.6, s * 5.45), BLACK)
end
bp("Bumper", Vector3.new(0.9, 1.2, 10.6), CFrame.new(17, 2.2, 0), BLACK)
local plate = bp("Plate", Vector3.new(0.1, 0.8, 1.8), CFrame.new(17.5, 2.2, 0), rgb(250, 250, 240))
signGui(plate, Enum.NormalId.Right, "RECESS", rgb(40, 60, 150), rgb(250, 250, 240), Enum.Font.Arcade)
bp("CrossingArm", Vector3.new(0.3, 0.3, 4.4), CFrame.new(17.5, 2.9, -2.8), YEL)

-- the sides: framed windows, black rub rails, wheel wells
for _, s in { -1, 1 } do
	for i = 0, 6 do
		local x = -19.5 + i * 4
		bp("WindowFrame", Vector3.new(3.5, 2.9, 0.08), CFrame.new(x, 9.95, s * 6.02), BLACK)
		bp("Window", Vector3.new(3.1, 2.5, 0.1), CFrame.new(x, 9.95, s * 6.05), GLASS, Enum.Material.Glass, { Transparency = 0.25 })
		bp("Sash", Vector3.new(3.1, 0.14, 0.12), CFrame.new(x, 10.35, s * 6.07), BLACK)
	end
	for _, y in { 2.8, 6.05, 7.7 } do
		bp("RubRail", Vector3.new(30.2, 0.3, 0.1), CFrame.new(-8, y, s * 6.05), BLACK)
	end
	cylZ("WheelWell", 5.4, 0.1, Vector3.new(-13, 2.2, s * 6.03), BLACK)
end

-- the passenger door (a folding glass door), the stop arm, the signs
bp("Door", Vector3.new(3.2, 8.4, 0.2), CFrame.new(9, 6.6, -6.1), BLACK)
for _, dx in { -0.75, 0.75 } do
	bp("DoorGlass", Vector3.new(1.3, 3.4, 0.1), CFrame.new(9 + dx, 8.6, -6.25), GLASS, Enum.Material.Glass, { Transparency = 0.3 })
	bp("DoorGlass", Vector3.new(1.3, 3, 0.1), CFrame.new(9 + dx, 4.6, -6.25), GLASS, Enum.Material.Glass, { Transparency = 0.3 })
end
bp("Step", Vector3.new(3, 0.4, 1.2), CFrame.new(9, 1.4, -6.4), BLACK)
-- (a round sign with a white rim: two squares would make a star, not an octagon)
cylZ("StopRim", 2.2, 0.08, Vector3.new(4.2, 6.9, -6.27), rgb(250, 250, 250))
local stop = cylZ("StopArm", 2, 0.1, Vector3.new(4.2, 6.9, -6.32), rgb(215, 30, 30))
signGui(stop, Enum.NormalId.Right, "STOP", rgb(255, 255, 255), nil, Enum.Font.GothamBlack)
bp("StopHinge", Vector3.new(0.5, 1.2, 0.3), CFrame.new(5.3, 6.9, -6.15), BLACK)
for _, s in { -1, 1 } do
	local sign = bp("Sign", Vector3.new(14, 2.1, 0.1), CFrame.new(-1.2, 4.45, s * 6.06), YEL)
	signGui(sign, s < 0 and Enum.NormalId.Front or Enum.NormalId.Back, "SCHOOL BUS", rgb(20, 20, 20), YEL, Enum.Font.FredokaOne)
end

-- the back: an emergency door, the rear sign and lights, the bumper
bp("EmergencyDoor", Vector3.new(0.1, 8, 4.4), CFrame.new(-23.05, 6.6, 0), BLACK)
bp("EmergencyGlass", Vector3.new(0.12, 3.2, 3.6), CFrame.new(-23.1, 8.8, 0), GLASS, Enum.Material.Glass, { Transparency = 0.25 })
for _, z in { -3.9, 3.9 } do
	bp("RearWindow", Vector3.new(0.1, 2.6, 2.6), CFrame.new(-23.05, 9.9, z), GLASS, Enum.Material.Glass, { Transparency = 0.25 })
	cylX("TailLight", 1, 0.2, Vector3.new(-23.1, 4, z * 1.2), rgb(220, 30, 40), Enum.Material.Neon)
end
bp("Body", Vector3.new(0.8, 1.6, 11.6), CFrame.new(-23.2, 13.1, 0), YEL)
local back = bp("RearSign", Vector3.new(0.1, 1.1, 5.8), CFrame.new(-23.65, 13.1, 0), YEL)
signGui(back, Enum.NormalId.Left, "SCHOOL BUS", rgb(20, 20, 20), YEL, Enum.Font.FredokaOne)
for _, z in { -4.9, 4.9 } do cylX("WarnRed", 0.8, 0.2, Vector3.new(-23.65, 13.1, z), rgb(230, 40, 40), Enum.Material.Neon) end
bp("RearBumper", Vector3.new(0.9, 1.2, 11), CFrame.new(-23.6, 2.2, 0), BLACK)

-- the wheels: singles at the front, dual wheels at the back
local function wheel(x, z)
	cylZ("Tire", 4.4, 1.3, Vector3.new(x, 2.2, z), rgb(24, 24, 26))
	cylZ("Hub", 2.3, 1.36, Vector3.new(x, 2.2, z), rgb(190, 192, 198), Enum.Material.Metal)
	cylZ("HubCap", 0.9, 1.42, Vector3.new(x, 2.2, z), rgb(70, 70, 76), Enum.Material.Metal)
end
for _, s in { -1, 1 } do
	wheel(14, s * 5.2)
	wheel(-13, s * 5.9) -- (the outer of the dual wheels: the inner one hides under the body)
end
for _, p in bus:GetDescendants() do
	if p:IsA("BasePart") then p.CanCollide = p.Name == "Body" or p.Name == "Hood" or p.Name == "Chassis" end
end
part(map, "BusStop", Vector3.new(1, 1, 1), CFrame.new(bx - 6, 7.5, bz + 2), C.bus, nil, HIDDEN)
-- bus shelter
local shelter = Instance.new("Model"); shelter.Name = "BusShelter"; shelter.Parent = map
part(shelter, "Roof", Vector3.new(14, 0.6, 6), CFrame.new(-318, 8, -20), rgb(60, 130, 220))
part(shelter, "Back", Vector3.new(14, 6, 0.3), CFrame.new(-318, 4.4, -22.8), rgb(190, 225, 255), Enum.Material.Glass, { Transparency = 0.4 })
for _, x in { -324.5, -311.5 } do
	part(shelter, "Post", Vector3.new(0.5, 7.6, 0.5), CFrame.new(x, 4.2, -22.6), rgb(80, 85, 95), Enum.Material.Metal)
end
part(shelter, "Bench", Vector3.new(10, 0.5, 1.8), CFrame.new(-318, 2, -21.5), rgb(150, 100, 60), Enum.Material.Wood)
local stopSign = part(shelter, "StopSign", Vector3.new(0.3, 2.4, 2.4), CFrame.new(-309, 8, -18), rgb(255, 255, 255))
signGui(stopSign, Enum.NormalId.Right, "BUS", rgb(40, 90, 200), rgb(255, 255, 255), Enum.Font.LuckiestGuy)
part(shelter, "StopPole", Vector3.new(0.3, 8, 0.3), CFrame.new(-309, 4, -18), rgb(120, 125, 135), Enum.Material.Metal)

---------------------------------------------------------------------------
-- detention at the east end
---------------------------------------------------------------------------
local det = Instance.new("Model"); det.Name = "Detention"; det.Parent = map
part(det, "Block", Vector3.new(24, 20, 34), CFrame.new(362, 10, 0), rgb(110, 110, 124), Enum.Material.Brick)
part(det, "Doorway", Vector3.new(0.4, 12, 12), CFrame.new(349.9, 6, 0), rgb(15, 15, 20))
for _, z in { -11, 11 } do
	part(det, "Bars", Vector3.new(0.4, 6, 6), CFrame.new(349.9, 12, z), rgb(60, 60, 70), Enum.Material.Metal)
end
local detSign = part(det, "Sign", Vector3.new(0.4, 4, 22), CFrame.new(349.8, 16, 0), rgb(40, 40, 50))
signGui(detSign, Enum.NormalId.Left, "DETENTION", rgb(255, 70, 70), rgb(40, 40, 50))

---------------------------------------------------------------------------
-- hub: arch over the street, spawn, flagpole
---------------------------------------------------------------------------
local spawn = Instance.new("SpawnLocation")
spawn.Name = "HubSpawn"; spawn.Size = Vector3.new(12, 0.4, 12); spawn.CFrame = CFrame.new(0, 0.3, -18)
spawn.Anchored = true; spawn.Transparency = 1; spawn.CanCollide = false; spawn.Neutral = true
spawn.Parent = map
for _, d in spawn:GetChildren() do d:Destroy() end
local hub = Instance.new("Model"); hub.Name = "Hub"; hub.Parent = map
-- the street arch stands west of the centre so it doesn't block the VexCorp Factory's gate
local ARCH_X = -48
for _, z in { -26, 26 } do
	part(hub, "ArchPost", Vector3.new(3, 22, 3), CFrame.new(ARCH_X, 11, z), C.white)
	part(hub, "ArchCap", Vector3.new(4, 1, 4), CFrame.new(ARCH_X, 22.5, z), C.trim)
end
local arch = part(hub, "ArchSign", Vector3.new(2, 6, 50), CFrame.new(ARCH_X, 24, 0), rgb(214, 44, 58))
signGui(arch, Enum.NormalId.Left, "RUN A SCHOOL", C.white, rgb(214, 44, 58), Enum.Font.LuckiestGuy)
signGui(arch, Enum.NormalId.Right, "RUN A SCHOOL", C.white, rgb(214, 44, 58), Enum.Font.LuckiestGuy)
part(hub, "FlagBase", Vector3.new(4, 1, 4), CFrame.new(0, 0.5, -48), rgb(200, 200, 205))
part(hub, "FlagPole", Vector3.new(0.6, 30, 0.6), CFrame.new(0, 15.5, -48), rgb(220, 220, 225), Enum.Material.Metal)
part(hub, "Flag", Vector3.new(0.2, 5, 8), CFrame.new(0, 27, -52), rgb(58, 160, 255))
part(hub, "FlagStripe", Vector3.new(0.25, 1.4, 8), CFrame.new(0, 27, -52), C.white)

---------------------------------------------------------------------------
-- lamps along the street, trees in the green gaps and around the edges
---------------------------------------------------------------------------
local deco = Instance.new("Folder"); deco.Name = "Deco"; deco.Parent = map
for x = -300, 300, 50 do
	for _, z in { -24, 24 } do
		if x == 0 and z == 24 then continue end -- the VexCorp Factory gate
		local lamp = Instance.new("Model"); lamp.Name = "Lamp"; lamp.Parent = deco
		part(lamp, "Pole", Vector3.new(0.8, 12, 0.8), CFrame.new(x, 6, z), rgb(50, 50, 60), Enum.Material.Metal)
		part(lamp, "Arm", Vector3.new(0.4, 0.4, 3), CFrame.new(x, 12, z - math.sign(z) * 1.3), rgb(50, 50, 60), Enum.Material.Metal)
		local bulb = part(lamp, "Bulb", Vector3.new(1.8, 1.2, 1.8), CFrame.new(x, 11.4, z - math.sign(z) * 2.6), rgb(255, 240, 200), Enum.Material.Neon)
		local l = Instance.new("PointLight"); l.Range = 20; l.Brightness = 1.2; l.Color = rgb(255, 230, 180); l.Parent = bulb
	end
end
local function tree(x, z, s, leaf)
	local t = Instance.new("Model"); t.Name = "Tree"; t.Parent = deco
	leaf = leaf or C.leaf
	part(t, "Trunk", Vector3.new(2, 8, 2) * s, CFrame.new(x, 4 * s, z), C.trunk)
	part(t, "Leaves", Vector3.new(10, 5, 10) * s, CFrame.new(x, 9 * s, z), leaf)
	part(t, "Leaves", Vector3.new(7, 4, 7) * s, CFrame.new(x, 12.5 * s, z), leaf:Lerp(C.white, 0.08))
	part(t, "Leaves", Vector3.new(4, 3, 4) * s, CFrame.new(x, 15 * s, z), leaf:Lerp(C.white, 0.15))
end
local leaves = { rgb(60, 170, 70), rgb(80, 180, 60), rgb(50, 150, 80), rgb(230, 140, 60) }
local n = 0
-- the gaps between schools hold landmarks (below); trees line their back edges
for _, gx in { -205, -175, -15, 15, 175, 205 } do
	for _, z in { 165, 190 } do
		for _, side in { -1, 1 } do
			n += 1
			tree(gx, side * z, 1 + (n % 3) * 0.12, leaves[n % #leaves + 1])
		end
	end
end

---------------------------------------------------------------------------
-- landmarks in the six gaps between schools (docs/DESIGN-v2.md 8.1)
---------------------------------------------------------------------------
local lm = Instance.new("Folder"); lm.Name = "Landmarks"; lm.Parent = map
local function walkway(x0, z0, x1, z1)
	local len = math.sqrt((x1 - x0) ^ 2 + (z1 - z0) ^ 2)
	part(lm, "Path", Vector3.new(8, 0.3, len), CFrame.lookAt(Vector3.new((x0 + x1) / 2, 0.45, (z0 + z1) / 2), Vector3.new(x1, 0.45, z1)), C.sidewalk, Enum.Material.Concrete)
end

-- centre, spawn side: Mr. Wobblesworth's Fountain
do
	local f = Instance.new("Model"); f.Name = "HubFountain"; f.Parent = lm
	local cx, cz = 0, -86
	walkway(0, -28, 0, -72)
	part(f, "Plaza", Vector3.new(44, 0.4, 44), CFrame.new(cx, 0.4, cz), rgb(225, 220, 205), Enum.Material.Concrete)
	part(f, "Basin", Vector3.new(3, 22, 22), CFrame.new(cx, 1.6, cz) * CFrame.Angles(0, 0, math.rad(90)), rgb(200, 200, 210), nil, { Shape = Enum.PartType.Cylinder })
	part(f, "Water", Vector3.new(3.1, 20, 20), CFrame.new(cx, 1.7, cz) * CFrame.Angles(0, 0, math.rad(90)), rgb(90, 170, 240), Enum.Material.Glass, { Shape = Enum.PartType.Cylinder, Transparency = 0.25 })
	part(f, "Tier1", Vector3.new(6, 3, 3), CFrame.new(cx, 4.5, cz) * CFrame.Angles(0, 0, math.rad(90)), rgb(210, 210, 220), nil, { Shape = Enum.PartType.Cylinder })
	part(f, "Bowl1", Vector3.new(1.4, 12, 12), CFrame.new(cx, 7.5, cz) * CFrame.Angles(0, 0, math.rad(90)), rgb(200, 200, 210), nil, { Shape = Enum.PartType.Cylinder })
	part(f, "Tier2", Vector3.new(4, 2, 2), CFrame.new(cx, 9.9, cz) * CFrame.Angles(0, 0, math.rad(90)), rgb(210, 210, 220), nil, { Shape = Enum.PartType.Cylinder })
	part(f, "Bowl2", Vector3.new(1.2, 6, 6), CFrame.new(cx, 12.2, cz) * CFrame.Angles(0, 0, math.rad(90)), rgb(200, 200, 210), nil, { Shape = Enum.PartType.Cylinder })
	-- the founder's pencil on top
	part(f, "Pencil", Vector3.new(1.4, 6, 1.4), CFrame.new(cx, 15.8, cz), rgb(255, 205, 50))
	part(f, "Eraser", Vector3.new(1.45, 1, 1.45), CFrame.new(cx, 19.2, cz), rgb(255, 150, 170))
	local spray = part(f, "Spray", Vector3.new(1, 1, 1), CFrame.new(cx, 13, cz), rgb(255, 255, 255), nil, HIDDEN)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(rgb(170, 220, 255))
	e.Size = NumberSequence.new(0.6, 0.2)
	e.Speed = NumberRange.new(8, 11)
	e.SpreadAngle = Vector2.new(25, 25)
	e.Acceleration = Vector3.new(0, -22, 0)
	e.Lifetime = NumberRange.new(1, 1.3)
	e.Rate = 60
	e.Parent = spray
	for _, a in { 0, 90, 180, 270 } do
		local bx, bz = cx + math.sin(math.rad(a)) * 16, cz + math.cos(math.rad(a)) * 16
		part(f, "Bench", Vector3.new(6, 0.5, 2), CFrame.new(bx, 1.8, bz) * CFrame.Angles(0, math.rad(a), 0), rgb(150, 100, 60), Enum.Material.Wood)
	end
	part(f, "NPCSpot", Vector3.new(1, 1, 1), CFrame.new(cx + 8, 0.6, cz + 12) * CFrame.Angles(0, math.rad(200), 0), C.white, nil, HIDDEN)
end

-- centre, far side: the VexCorp Factory stands here (built at runtime by FactoryService)

-- west, spawn side: Janitor Stan's Confiscation Closet
do
	local s = Instance.new("Model"); s.Name = "ConfiscationCloset"; s.Parent = lm
	local cx, cz = -190, -72
	walkway(-190, -28, -190, -62)
	local wood = rgb(140, 100, 70)
	part(s, "Floor", Vector3.new(22, 1, 18), CFrame.new(cx, 0.5, cz), rgb(120, 120, 125), Enum.Material.Concrete)
	part(s, "Back", Vector3.new(22, 12, 1), CFrame.new(cx, 6.5, cz - 8.5), wood, Enum.Material.WoodPlanks)
	for _, x in { -10.5, 10.5 } do part(s, "Side", Vector3.new(1, 12, 18), CFrame.new(cx + x, 6.5, cz), wood, Enum.Material.WoodPlanks) end
	for _, x in { -7, 7 } do part(s, "Front", Vector3.new(8, 12, 1), CFrame.new(cx + x, 6.5, cz + 8.5), wood, Enum.Material.WoodPlanks) end
	part(s, "Lintel", Vector3.new(6, 3, 1), CFrame.new(cx, 11, cz + 8.5), wood, Enum.Material.WoodPlanks)
	part(s, "Roof", Vector3.new(24, 1, 20), CFrame.new(cx, 13, cz) * CFrame.Angles(math.rad(8), 0, 0), rgb(90, 95, 105), Enum.Material.DiamondPlate)
	local sign = part(s, "Sign", Vector3.new(18, 3, 0.5), CFrame.new(cx, 15.5, cz + 9.5), rgb(255, 120, 190))
	signGui(sign, Enum.NormalId.Back, "CONFISCATION CLOSET", C.white, rgb(255, 120, 190), Enum.Font.LuckiestGuy)
	-- confiscated goods piled up inside
	local candy = { rgb(255, 80, 140), rgb(90, 200, 255), rgb(255, 210, 60), rgb(120, 230, 90) }
	for i = 1, 18 do
		part(s, "Candy", Vector3.new(1, 1, 1), CFrame.new(cx - 6 + (i % 6) * 2.2, 1.5 + (i // 6) * 1, cz - 5 + (i % 3)), candy[i % 4 + 1], nil, { Shape = Enum.PartType.Ball })
	end
	for i = 0, 2 do
		part(s, "SlimeJar", Vector3.new(1.4, 2, 1.4), CFrame.new(cx + 5 + i * 1.8, 2, cz - 6), rgb(90, 255, 110), Enum.Material.Neon)
	end
	part(s, "Bucket", Vector3.new(2, 2, 2), CFrame.new(cx + 7, 1.6, cz + 5), rgb(255, 215, 40))
	part(s, "NPCSpot", Vector3.new(1, 1, 1), CFrame.new(cx - 4, 0.6, cz + 12) * CFrame.Angles(0, math.rad(180), 0), C.white, nil, HIDDEN)
end

-- west, far side: Recess Commons (swings, slide, jungle gym, sandbox)
do
	local r = Instance.new("Model"); r.Name = "RecessCommons"; r.Parent = lm
	local cx, cz = -190, 90
	walkway(-190, 28, -190, 60)
	part(r, "Mulch", Vector3.new(60, 0.3, 70), CFrame.new(cx, 0.35, cz), rgb(170, 110, 70), Enum.Material.Sand)
	-- swings
	for _, x in { -22, -12 } do part(r, "SwingPost", Vector3.new(0.8, 10, 0.8), CFrame.new(cx + x, 5, cz - 12), rgb(230, 60, 60), Enum.Material.Metal) end
	part(r, "SwingBar", Vector3.new(11, 0.8, 0.8), CFrame.new(cx - 17, 10, cz - 12), rgb(230, 60, 60), Enum.Material.Metal)
	for _, x in { -19.5, -14.5 } do
		part(r, "Chain", Vector3.new(0.2, 7, 0.2), CFrame.new(cx + x, 6.4, cz - 12), rgb(120, 120, 130), Enum.Material.Metal)
		part(r, "Seat", Vector3.new(2.4, 0.3, 1.2), CFrame.new(cx + x, 2.8, cz - 12), rgb(40, 40, 50))
	end
	-- slide
	part(r, "Tower", Vector3.new(6, 8, 6), CFrame.new(cx + 12, 4, cz - 4), rgb(60, 140, 240))
	part(r, "TowerRoof", Vector3.new(7, 1, 7), CFrame.new(cx + 12, 12, cz - 4), rgb(255, 210, 50))
	for _, x in { -2.8, 2.8 } do part(r, "RoofPost", Vector3.new(0.6, 4, 0.6), CFrame.new(cx + 12 + x, 10, cz - 4), rgb(255, 210, 50)) end
	part(r, "Slide", Vector3.new(4, 0.6, 14), CFrame.new(cx + 12, 4.3, cz + 5.5) * CFrame.Angles(math.rad(-30), 0, 0), rgb(255, 120, 40))
	-- jungle gym
	for i = 0, 3 do
		for j = 0, 1 do
			part(r, "Bar", Vector3.new(0.5, 7, 0.5), CFrame.new(cx - 18 + i * 4, 3.5, cz + 12 + j * 8), rgb(90, 200, 90), Enum.Material.Metal)
		end
		part(r, "TopBar", Vector3.new(0.5, 0.5, 8), CFrame.new(cx - 18 + i * 4, 7, cz + 16), rgb(90, 200, 90), Enum.Material.Metal)
	end
	-- sandbox
	part(r, "SandboxRim", Vector3.new(12, 1, 12), CFrame.new(cx + 14, 0.8, cz + 20), rgb(150, 100, 60), Enum.Material.Wood)
	part(r, "Sand", Vector3.new(11, 1.05, 11), CFrame.new(cx + 14, 0.85, cz + 20), rgb(240, 220, 150), Enum.Material.Sand)
	local sign = part(r, "Sign", Vector3.new(14, 3, 0.5), CFrame.new(cx, 5, cz - 32), rgb(60, 180, 90))
	signGui(sign, Enum.NormalId.Front, "RECESS COMMONS", C.white, rgb(60, 180, 90), Enum.Font.LuckiestGuy)
	for _, x in { -6.5, 6.5 } do part(r, "SignPost", Vector3.new(0.6, 5, 0.6), CFrame.new(cx + x, 2.5, cz - 32), rgb(90, 60, 40), Enum.Material.Wood) end
end

-- east, spawn side: the District Office tower
do
	local d = Instance.new("Model"); d.Name = "DistrictOffice"; d.Parent = lm
	local cx, cz = 190, -92
	walkway(190, -28, 190, -72)
	local stone, glass = rgb(200, 200, 210), rgb(120, 170, 220)
	part(d, "Tower", Vector3.new(36, 56, 36), CFrame.new(cx, 28, cz), stone, Enum.Material.Concrete)
	for floor = 0, 5 do
		for i = -1, 1 do
			part(d, "Window", Vector3.new(8, 5, 0.4), CFrame.new(cx + i * 11, 8 + floor * 8.5, cz + 18.05), glass, Enum.Material.Glass, { Transparency = 0.2 })
		end
	end
	part(d, "Door", Vector3.new(8, 9, 0.5), CFrame.new(cx, 4.5, cz + 18.1), rgb(40, 50, 70))
	part(d, "Canopy", Vector3.new(14, 0.6, 5), CFrame.new(cx, 10, cz + 20.5), rgb(40, 50, 70))
	local sign = part(d, "Sign", Vector3.new(28, 4, 0.6), CFrame.new(cx, 52, cz + 18.2), rgb(40, 50, 70))
	signGui(sign, Enum.NormalId.Back, "DISTRICT OFFICE", C.white, rgb(40, 50, 70), Enum.Font.LuckiestGuy)
	part(d, "RoofTrim", Vector3.new(38, 2, 38), CFrame.new(cx, 57, cz), rgb(40, 50, 70))
	part(d, "Antenna", Vector3.new(0.6, 14, 0.6), CFrame.new(cx + 10, 64, cz - 8), rgb(160, 160, 170), Enum.Material.Metal)
	part(d, "Beacon", Vector3.new(1.4, 1.4, 1.4), CFrame.new(cx + 10, 71.5, cz - 8), rgb(255, 60, 60), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
end

-- east, far side: the boarded-up Sugar Shack and Vex's billboard
do
	local s = Instance.new("Model"); s.Name = "SugarShack"; s.Parent = lm
	local cx, cz = 190, 72
	local pink = rgb(240, 150, 190)
	part(s, "Body", Vector3.new(26, 14, 20), CFrame.new(cx, 7, cz), pink)
	part(s, "Roof", Vector3.new(28, 1.2, 22), CFrame.new(cx, 14.6, cz), rgb(120, 70, 90))
	-- a torn striped awning
	for i = -5, 4 do
		local c = i % 2 == 0 and C.white or rgb(230, 60, 110)
		part(s, "Awning", Vector3.new(2.4, 0.3, 4 + (i % 3)), CFrame.new(cx + i * 2.4 + 1.2, 10.5, cz - 12) * CFrame.Angles(math.rad(-20 - (i % 3) * 8), 0, 0), c)
	end
	-- boarded windows and door
	for _, x in { -8, 8 } do
		part(s, "Window", Vector3.new(6, 5, 0.3), CFrame.new(cx + x, 6.5, cz - 10.1), rgb(40, 30, 40))
		for _, a in { 25, -25 } do
			part(s, "Board", Vector3.new(7.5, 0.8, 0.3), CFrame.new(cx + x, 6.5, cz - 10.35) * CFrame.Angles(0, 0, math.rad(a)), rgb(150, 105, 60), Enum.Material.Wood)
		end
	end
	part(s, "Door", Vector3.new(5, 8, 0.3), CFrame.new(cx, 4, cz - 10.1), rgb(90, 50, 60))
	part(s, "DoorBoard", Vector3.new(6.5, 0.8, 0.3), CFrame.new(cx, 5, cz - 10.35), rgb(150, 105, 60), Enum.Material.Wood)
	local sign = part(s, "Sign", Vector3.new(18, 3.2, 0.5), CFrame.new(cx, 12.6, cz - 10.4) * CFrame.Angles(0, 0, math.rad(-4)), rgb(255, 230, 240))
	signGui(sign, Enum.NormalId.Front, "SUGAR SHACK", rgb(220, 40, 110), rgb(255, 230, 240), Enum.Font.LuckiestGuy)
	local neon = part(s, "FlickerSign", Vector3.new(6, 1.2, 0.3), CFrame.new(cx + 8, 12.6, cz - 10.5), rgb(255, 90, 180), Enum.Material.Neon)
	neon:SetAttribute("Flicker", true)
	part(s, "NPCSpot", Vector3.new(1, 1, 1), CFrame.new(cx, 15.4, cz + 2) * CFrame.Angles(0, math.rad(180), 0), C.white, nil, HIDDEN)
	-- Vex's billboard behind it
	for _, x in { -10, 10 } do part(s, "BillboardLeg", Vector3.new(1, 22, 1), CFrame.new(cx + x, 11, cz + 26), rgb(70, 70, 80), Enum.Material.Metal) end
	local bb = part(s, "VexBillboard", Vector3.new(30, 12, 1), CFrame.new(cx, 26, cz + 26), rgb(60, 20, 90))
	signGui(bb, Enum.NormalId.Front, "COMING SOON:\nVEX HOMEWORK FACTORY\n\"Recess is cancelled.\"", rgb(255, 255, 255), rgb(60, 20, 90), Enum.Font.LuckiestGuy)
end
for x = -456, 456, 38 do
	for _, z in { -225, 225 } do
		n += 1
		tree(x + (n % 2) * 9, z, 1.3, leaves[n % #leaves + 1])
	end
end
for _, x in { -392, 392 } do
	for z = 60, 200, 35 do
		for _, side in { -1, 1 } do
			n += 1
			-- (not where the VexCorp Mutation Lab (NW) and Vex Prep Academy (SE) stand)
			local zz = side * z
			local taken = (x < 0 and zz > 0 and zz < 160) or (x > 0 and zz < 0 and zz > -180)
			if not taken then tree(x, zz, 1.2, leaves[n % #leaves + 1]) end
		end
	end
end

---------------------------------------------------------------------------
-- plots: lots with a gate arch; the school is built at runtime
---------------------------------------------------------------------------
local LOT_W, LOT_D, GATE = 120, 150, 18
-- 70-stud gaps between lots (lot edges at +-35, +-155, +-225, +-345)
local plotXs = { -285, -95, 95, 285 }
local idx = 0
for side = 1, 2 do
	for _, px in plotXs do
		idx += 1
		local pz = side == 1 and 103 or -103
		-- local +Z points at the street
		local base = CFrame.new(px, 0, pz) * (side == 1 and CFrame.Angles(0, math.pi, 0) or CFrame.new())
		local function L(x, y, z) return base * CFrame.new(x, y, z) end

		local plot = Instance.new("Model"); plot.Name = "Plot" .. idx; plot.Parent = plots
		plot:SetAttribute("Index", idx)
		plot:SetAttribute("OwnerId", 0)
		part(plot, "Origin", Vector3.new(1, 1, 1), base, C.lawn, nil, HIDDEN)
		local lot = part(plot, "Lot", Vector3.new(LOT_W, 0.4, LOT_D), L(0, 0.2, 0), C.lawn, Enum.Material.Grass)
		plot.PrimaryPart = lot
		-- curb around the lot, open at the gate
		local seg = (LOT_W - GATE) / 2
		part(plot, "Curb", Vector3.new(seg, 0.7, 1), L(-(GATE / 2 + seg / 2), 0.35, LOT_D / 2 - 0.5), C.curb, Enum.Material.Concrete)
		part(plot, "Curb", Vector3.new(seg, 0.7, 1), L(GATE / 2 + seg / 2, 0.35, LOT_D / 2 - 0.5), C.curb, Enum.Material.Concrete)
		part(plot, "Curb", Vector3.new(1, 0.7, LOT_D), L(-LOT_W / 2 + 0.5, 0.35, 0), C.curb, Enum.Material.Concrete)
		part(plot, "Curb", Vector3.new(1, 0.7, LOT_D), L(LOT_W / 2 - 0.5, 0.35, 0), C.curb, Enum.Material.Concrete)
		part(plot, "Curb", Vector3.new(LOT_W, 0.7, 1), L(0, 0.35, -LOT_D / 2 + 0.5), C.curb, Enum.Material.Concrete)

		-- gate arch with the school's name
		local gateFolder = Instance.new("Folder"); gateFolder.Name = "GateArch"; gateFolder.Parent = plot
		for _, sx in { -1, 1 } do
			part(gateFolder, "Post", Vector3.new(2.6, 13, 2.6), L(sx * (GATE / 2 + 1.3), 6.5, LOT_D / 2 - 1), rgb(235, 230, 220))
			part(gateFolder, "PostCap", Vector3.new(3.4, 1, 3.4), L(sx * (GATE / 2 + 1.3), 13.5, LOT_D / 2 - 1), C.trim)
			part(gateFolder, "Lantern", Vector3.new(1.2, 1.4, 1.2), L(sx * (GATE / 2 + 1.3), 14.7, LOT_D / 2 - 1), rgb(255, 240, 200), Enum.Material.Neon)
		end
		local sign = part(plot, "Sign", Vector3.new(GATE + 6, 4, 1), L(0, 11.5, LOT_D / 2 - 1), rgb(40, 90, 200))
		signGui(sign, Enum.NormalId.Back, "Empty School", C.white, rgb(40, 90, 200))
		signGui(sign, Enum.NormalId.Front, "Empty School", C.white, rgb(40, 90, 200))
		local plate = part(plot, "TierPlate", Vector3.new(GATE, 1.4, 0.8), L(0, 8.8, LOT_D / 2 - 1), rgb(30, 30, 40))
		signGui(plate, Enum.NormalId.Back, "", rgb(255, 220, 90), rgb(30, 30, 40))
		signGui(plate, Enum.NormalId.Front, "", rgb(255, 220, 90), rgb(30, 30, 40))

		-- laser gate
		local gate = Instance.new("Folder"); gate.Name = "Gate"; gate.Parent = plot
		part(gate, "Barrier", Vector3.new(GATE, 8, 1), L(0, 4, LOT_D / 2 - 1), rgb(255, 40, 60), Enum.Material.ForceField, { Transparency = 1, CanCollide = false })
		for i = 1, 3 do
			part(gate, "Laser", Vector3.new(GATE, 0.3, 0.3), L(0, i * 2.2, LOT_D / 2 - 1), rgb(255, 40, 60), Enum.Material.Neon, { Transparency = 1, CanCollide = false, CanQuery = false })
		end

		-- lock button just inside the gate
		local lock = Instance.new("Model"); lock.Name = "LockButton"; lock.Parent = plot
		part(lock, "Base", Vector3.new(4, 2.4, 4), L(14, 1.6, LOT_D / 2 - 8), rgb(60, 60, 70))
		local btn = part(lock, "Button", Vector3.new(1, 3.4, 3.4), L(14, 3.1, LOT_D / 2 - 8) * CFrame.Angles(0, 0, math.rad(90)), rgb(230, 40, 50), Enum.Material.Neon, { Shape = Enum.PartType.Cylinder })
		lock.PrimaryPart = btn
		billboard(btn, "Info", "LOCK", 3.5)

		part(plot, "Spawn", Vector3.new(1, 1, 1), L(0, 3, LOT_D / 2 - 12), C.lawn, nil, HIDDEN)
		part(plot, "Entry", Vector3.new(1, 1, 1), L(0, 3, LOT_D / 2 + 5), C.lawn, nil, HIDDEN)
		part(plot, "Bounds", Vector3.new(LOT_W, 90, LOT_D), L(0, 45, 0), C.lawn, nil, HIDDEN)
	end
end

---------------------------------------------------------------------------
-- the Board Room, high above the map (School Board review cutscene)
---------------------------------------------------------------------------
local room = Instance.new("Model"); room.Name = "BoardRoom"; room.Parent = workspace
local R = CFrame.new(0, 400, 0)
local function RL(x, y, z) return R * CFrame.new(x, y, z) end
part(room, "Floor", Vector3.new(60, 1, 40), RL(0, 0, 0), rgb(120, 30, 40))
part(room, "Back", Vector3.new(60, 24, 1), RL(0, 12, -20), rgb(90, 60, 45), Enum.Material.Wood)
part(room, "Left", Vector3.new(1, 24, 40), RL(-30, 12, 0), rgb(90, 60, 45), Enum.Material.Wood)
part(room, "Right", Vector3.new(1, 24, 40), RL(30, 12, 0), rgb(90, 60, 45), Enum.Material.Wood)
part(room, "Ceiling", Vector3.new(60, 1, 40), RL(0, 24, 0), rgb(240, 235, 225))
part(room, "Table", Vector3.new(36, 1, 7), RL(0, 4, -8), rgb(110, 70, 40), Enum.Material.Wood)
part(room, "TableFront", Vector3.new(36, 3.5, 0.6), RL(0, 2, -4.8), rgb(95, 60, 35), Enum.Material.Wood)
local banner = part(room, "Banner", Vector3.new(30, 5, 0.4), RL(0, 17, -19.5), rgb(30, 50, 110))
signGui(banner, Enum.NormalId.Back, "THE SCHOOL BOARD", rgb(255, 220, 90), rgb(30, 50, 110), Enum.Font.LuckiestGuy)
for i = -2, 2 do
	part(room, "BoardSeat", Vector3.new(1, 1, 1), RL(i * 7, 3.2, -11), C.lawn, nil, HIDDEN)
	part(room, "Chair", Vector3.new(3, 5, 0.6), RL(i * 7, 4.5, -13), rgb(60, 20, 30))
	part(room, "Nameplate", Vector3.new(4, 1, 0.4), RL(i * 7, 4.9, -5.2), rgb(255, 210, 80), Enum.Material.Metal)
end
part(room, "Podium", Vector3.new(4, 4, 3), RL(0, 2, 10), rgb(110, 70, 40), Enum.Material.Wood)
part(room, "PlayerMark", Vector3.new(1, 1, 1), RL(0, 3, 13), C.lawn, nil, HIDDEN)
part(room, "CameraA", Vector3.new(1, 1, 1), CFrame.lookAt(RL(0, 9, 22).Position, RL(0, 5, -8).Position), C.lawn, nil, HIDDEN)
part(room, "CameraB", Vector3.new(1, 1, 1), CFrame.lookAt(RL(-12, 7, 4).Position, RL(0, 5, -9).Position), C.lawn, nil, HIDDEN)
part(room, "Gavel", Vector3.new(0.6, 0.6, 2.4), RL(3, 4.8, -8) * CFrame.Angles(0, math.rad(90), 0), rgb(90, 50, 25), Enum.Material.Wood)
for _, x in { -20, 20 } do
	local lamp = part(room, "Lamp", Vector3.new(2, 2, 2), RL(x, 20, 0), rgb(255, 240, 200), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
	local pl = Instance.new("PointLight"); pl.Range = 40; pl.Brightness = 2; pl.Parent = lamp
end

---------------------------------------------------------------------------
-- lighting: bright, saturated afternoon
---------------------------------------------------------------------------
Lighting.ClockTime = 14.5
Lighting.Brightness = 3
Lighting.GlobalShadows = true
Lighting.Ambient = rgb(120, 120, 135)
Lighting.OutdoorAmbient = rgb(150, 150, 170)
local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
cc.Saturation = 0.22; cc.Contrast = 0.08; cc.Brightness = 0.02
if Lighting:FindFirstChild("Atmosphere") then
	Lighting.Atmosphere.Density = 0.22; Lighting.Atmosphere.Haze = 0.4
	Lighting.Atmosphere.Color = rgb(200, 225, 255)
end
if Lighting:FindFirstChild("DepthOfField") then Lighting.DepthOfField.Enabled = false end

return ("map v2 built: %d plots"):format(idx)
