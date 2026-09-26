-- Swaps the school bus on an existing map for the current design in build_map.lua (Edit mode).
return function()
local map = workspace.Map
for _, n in { "SchoolBus", "BusStop" } do
	local old = map:FindFirstChild(n)
	if old then old:Destroy() end
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

return #bus:GetChildren()
end
