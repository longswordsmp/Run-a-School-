-- Builds the static map in Edit mode. Re-runnable: clears Workspace.Map, Workspace.Plots,
-- Workspace.BoardRoom and ServerStorage.FloorTemplates first.
--   Workspace.Map          ground, hallway, bus, detention, hub, trees, lamps
--   Workspace.Plots.PlotN  ground floor of each school (16 desks, rows 3-4 locked), gate, lock,
--                          elevator (hidden until floor 2), teacher spot
--   ServerStorage.FloorTemplates.Floor2/Floor3  upper floors, built around the origin; PlotService
--                          clones them onto a plot's Origin when the School Board grants a floor
--   Workspace.BoardRoom    the School Board's meeting room, high above the map, for the cutscene
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

for _, n in { "Map", "Plots", "BoardRoom" } do
	local old = workspace:FindFirstChild(n)
	if old then old:Destroy() end
end
if ServerStorage:FindFirstChild("FloorTemplates") then ServerStorage.FloorTemplates:Destroy() end
if workspace:FindFirstChild("Baseplate") then workspace.Baseplate:Destroy() end
if workspace:FindFirstChild("SpawnLocation") then workspace.SpawnLocation:Destroy() end

local function part(parent, name, size, cf, color, material, props)
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
local HIDDEN = { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false }

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
	s.Color = Color3.fromRGB(30, 20, 40)
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
	grass = Color3.fromRGB(104, 196, 84),
	sidewalk = Color3.fromRGB(214, 214, 222),
	carpet = Color3.fromRGB(214, 44, 58),
	trim = Color3.fromRGB(255, 196, 40),
	floor = Color3.fromRGB(240, 226, 196),
	tile = Color3.fromRGB(222, 204, 170),
	brick = Color3.fromRGB(196, 92, 68),
	wallIn = Color3.fromRGB(255, 244, 214),
	desk = Color3.fromRGB(196, 140, 84),
	deskLeg = Color3.fromRGB(90, 90, 100),
	chair = Color3.fromRGB(60, 132, 232),
	board = Color3.fromRGB(38, 74, 56),
	pad = Color3.fromRGB(70, 230, 110),
	bus = Color3.fromRGB(255, 190, 20),
	glass = Color3.fromRGB(150, 210, 255),
	leaf = Color3.fromRGB(60, 170, 70),
	trunk = Color3.fromRGB(120, 80, 50),
}

local map = Instance.new("Folder"); map.Name = "Map"; map.Parent = workspace
local plots = Instance.new("Folder"); plots.Name = "Plots"; plots.Parent = workspace
local templates = Instance.new("Folder"); templates.Name = "FloorTemplates"; templates.Parent = ServerStorage

---------------------------------------------------------------------------
-- ground and hallway
---------------------------------------------------------------------------
part(map, "Ground", Vector3.new(700, 2, 500), CFrame.new(0, -1, 0), C.grass, Enum.Material.Grass)
part(map, "Sidewalk", Vector3.new(500, 0.4, 36), CFrame.new(0, 0.2, 0), C.sidewalk, Enum.Material.Concrete)
part(map, "Carpet", Vector3.new(470, 0.3, 16), CFrame.new(0, 0.5, 0), C.carpet, Enum.Material.Fabric)
part(map, "TrimN", Vector3.new(470, 0.32, 1), CFrame.new(0, 0.5, 8.5), C.trim, Enum.Material.SmoothPlastic)
part(map, "TrimS", Vector3.new(470, 0.32, 1), CFrame.new(0, 0.5, -8.5), C.trim, Enum.Material.SmoothPlastic)

local path = Instance.new("Folder"); path.Name = "HallPath"; path.Parent = map
part(path, "Start", Vector3.new(1, 1, 1), CFrame.new(-228, 1, 0), C.trim, nil, HIDDEN)
part(path, "End", Vector3.new(1, 1, 1), CFrame.new(236, 1, 0), C.trim, nil, HIDDEN)

---------------------------------------------------------------------------
-- school bus (BusService drives it in and out; Body is the PrimaryPart)
---------------------------------------------------------------------------
local bus = Instance.new("Model"); bus.Name = "SchoolBus"; bus.Parent = map
local bx, bz = -250, 0
local body = part(bus, "Body", Vector3.new(34, 11, 12), CFrame.new(bx - 6, 7.5, bz + 2), C.bus)
bus.PrimaryPart = body
part(bus, "Hood", Vector3.new(6, 6, 11), CFrame.new(bx + 14, 5, bz + 2), C.bus)
part(bus, "Grille", Vector3.new(0.3, 3, 8), CFrame.new(bx + 17.1, 5, bz + 2), Color3.fromRGB(40, 40, 45))
for _, z in { bz - 1.5, bz + 5.5 } do
	part(bus, "Headlight", Vector3.new(0.4, 1.4, 1.4), CFrame.new(bx + 17.2, 6.2, z), Color3.fromRGB(255, 250, 220), Enum.Material.Neon)
end
part(bus, "Roof", Vector3.new(34, 1, 12.4), CFrame.new(bx - 6, 13.3, bz + 2), Color3.fromRGB(245, 245, 245))
part(bus, "StripeA", Vector3.new(34.2, 0.6, 12.2), CFrame.new(bx - 6, 6.5, bz + 2), Color3.fromRGB(20, 20, 20))
part(bus, "StripeB", Vector3.new(34.2, 0.6, 12.2), CFrame.new(bx - 6, 8, bz + 2), Color3.fromRGB(20, 20, 20))
for i = 0, 5 do
	part(bus, "Window", Vector3.new(4, 3, 12.3), CFrame.new(bx - 20 + i * 5, 10.5, bz + 2), Color3.fromRGB(120, 190, 240), Enum.Material.Glass, { Transparency = 0.2 })
end
part(bus, "Windshield", Vector3.new(0.3, 4, 10), CFrame.new(bx + 11.1, 10.5, bz + 2), Color3.fromRGB(120, 190, 240), Enum.Material.Glass, { Transparency = 0.2 })
part(bus, "Door", Vector3.new(3.4, 8, 0.4), CFrame.new(bx + 8, 6, bz - 4.1), Color3.fromRGB(40, 40, 40))
for _, wx in { bx - 16, bx + 12 } do
	for _, wz in { bz - 4.5, bz + 8.5 } do
		part(bus, "Wheel", Vector3.new(1.6, 5, 5), CFrame.new(wx, 2.5, wz) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(30, 30, 30), nil, { Shape = Enum.PartType.Cylinder })
		part(bus, "Hubcap", Vector3.new(1.7, 2, 2), CFrame.new(wx, 2.5, wz) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 200, 205), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	end
end
part(bus, "StopArm", Vector3.new(0.4, 2.4, 2.4), CFrame.new(bx - 10, 8, bz - 4.3) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(220, 30, 30), nil, { Shape = Enum.PartType.Cylinder })
local busSign = part(bus, "Sign", Vector3.new(20, 2.4, 0.2), CFrame.new(bx - 6, 12, bz - 4.1), C.bus)
signGui(busSign, Enum.NormalId.Front, "SCHOOL BUS", Color3.fromRGB(20, 20, 20), C.bus, Enum.Font.FredokaOne)
-- the bus's parking spot, used by BusService
part(map, "BusStop", Vector3.new(1, 1, 1), body.CFrame, C.bus, nil, HIDDEN)

---------------------------------------------------------------------------
-- detention at the far end
---------------------------------------------------------------------------
local det = Instance.new("Model"); det.Name = "Detention"; det.Parent = map
part(det, "Block", Vector3.new(24, 20, 34), CFrame.new(252, 10, 0), Color3.fromRGB(110, 110, 124), Enum.Material.Brick)
part(det, "Doorway", Vector3.new(0.4, 12, 12), CFrame.new(239.9, 6, 0), Color3.fromRGB(15, 15, 20))
for _, z in { -11, 11 } do
	part(det, "Bars", Vector3.new(0.4, 6, 6), CFrame.new(239.9, 12, z), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
end
local detSign = part(det, "Sign", Vector3.new(0.4, 4, 22), CFrame.new(239.8, 16, 0), Color3.fromRGB(40, 40, 50))
signGui(detSign, Enum.NormalId.Left, "DETENTION", Color3.fromRGB(255, 70, 70), Color3.fromRGB(40, 40, 50))

---------------------------------------------------------------------------
-- hub: spawn, flagpole, welcome arch
---------------------------------------------------------------------------
local spawn = Instance.new("SpawnLocation")
spawn.Name = "HubSpawn"; spawn.Size = Vector3.new(12, 0.4, 12); spawn.CFrame = CFrame.new(0, 0.3, -30)
spawn.Anchored = true; spawn.Transparency = 1; spawn.CanCollide = false; spawn.Neutral = true
spawn.Parent = map
for _, d in spawn:GetChildren() do d:Destroy() end

local hub = Instance.new("Model"); hub.Name = "Hub"; hub.Parent = map
part(hub, "FlagBase", Vector3.new(4, 1, 4), CFrame.new(0, 0.5, -40), Color3.fromRGB(200, 200, 205))
part(hub, "FlagPole", Vector3.new(0.6, 28, 0.6), CFrame.new(0, 14.5, -40), Color3.fromRGB(220, 220, 225), Enum.Material.Metal)
part(hub, "Flag", Vector3.new(0.2, 5, 8), CFrame.new(0, 25, -44), Color3.fromRGB(58, 160, 255))
part(hub, "FlagStripe", Vector3.new(0.25, 1.4, 8), CFrame.new(0, 25, -44), Color3.fromRGB(255, 255, 255))
for _, x in { -12, 12 } do
	part(hub, "ArchPost", Vector3.new(2.5, 20, 2.5), CFrame.new(x, 10, -12), C.wallIn)
end
local arch = part(hub, "ArchSign", Vector3.new(28, 5, 1.5), CFrame.new(0, 21, -12), Color3.fromRGB(214, 44, 58))
signGui(arch, Enum.NormalId.Front, "RUN A SCHOOL", Color3.new(1, 1, 1), Color3.fromRGB(214, 44, 58), Enum.Font.LuckiestGuy)
signGui(arch, Enum.NormalId.Back, "RUN A SCHOOL", Color3.new(1, 1, 1), Color3.fromRGB(214, 44, 58), Enum.Font.LuckiestGuy)
-- benches either side of the arch
for _, x in { -20, 20 } do
	part(hub, "BenchSeat", Vector3.new(8, 0.6, 2.4), CFrame.new(x, 2, -16), C.desk, Enum.Material.Wood)
	part(hub, "BenchBack", Vector3.new(8, 2, 0.5), CFrame.new(x, 3.2, -17.1), C.desk, Enum.Material.Wood)
	for _, lx in { -3.5, 3.5 } do
		part(hub, "BenchLeg", Vector3.new(0.5, 1.8, 2), CFrame.new(x + lx, 0.9, -16), C.deskLeg, Enum.Material.Metal)
	end
end

---------------------------------------------------------------------------
-- lamps and trees
---------------------------------------------------------------------------
local deco = Instance.new("Folder"); deco.Name = "Deco"; deco.Parent = map
for x = -200, 200, 50 do
	for _, z in { -14, 14 } do
		local lamp = Instance.new("Model"); lamp.Name = "Lamp"; lamp.Parent = deco
		part(lamp, "Pole", Vector3.new(0.8, 12, 0.8), CFrame.new(x + 25, 6, z), Color3.fromRGB(50, 50, 60), Enum.Material.Metal)
		local bulb = part(lamp, "Bulb", Vector3.new(2, 2, 2), CFrame.new(x + 25, 12.5, z), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
		local l = Instance.new("PointLight"); l.Range = 18; l.Brightness = 1.2; l.Color = Color3.fromRGB(255, 230, 180); l.Parent = bulb
	end
end
local function tree(x, z, s)
	local t = Instance.new("Model"); t.Name = "Tree"; t.Parent = deco
	part(t, "Trunk", Vector3.new(2, 8, 2) * s, CFrame.new(x, 4 * s, z), C.trunk)
	part(t, "Leaves", Vector3.new(10, 5, 10) * s, CFrame.new(x, 9 * s, z), C.leaf)
	part(t, "Leaves", Vector3.new(7, 4, 7) * s, CFrame.new(x, 12.5 * s, z), C.leaf:Lerp(Color3.new(1, 1, 1), 0.08))
	part(t, "Leaves", Vector3.new(4, 3, 4) * s, CFrame.new(x, 15 * s, z), C.leaf:Lerp(Color3.new(1, 1, 1), 0.15))
end
for _, x in { -200, -100, 0, 100, 200 } do
	for _, z in { -40, 40, -85, 85 } do
		if not (x == 0 and z == -40) then tree(x, z, 1 + ((x + z) % 3) * 0.1) end
	end
end
for x = -230, 230, 40 do
	for _, z in { -130, 130 } do
		tree(x + ((x // 40) % 2) * 12, z, 1.2)
	end
end

---------------------------------------------------------------------------
-- classrooms
---------------------------------------------------------------------------
local PLOT_W, PLOT_D, WALL_H, FLOOR_H = 70, 90, 14, 15
local DESK_COLS = { -24, -8, 8, 24 }
local DESK_ROWS = { 18, 4, -10, -24 } -- local z; row 1 nearest the gate
local GATE = 18
local ELEVATOR = Vector3.new(28, 0, 38) -- local x, z of the elevator pad on every floor

-- one desk with its chair, sit point and collect pad; y0 = floor offset
local function desk(parent, L, slot, row, dx, dz, y0, locked)
	local d = Instance.new("Model"); d.Name = "Desk" .. slot; d.Parent = parent
	d:SetAttribute("Slot", slot)
	d:SetAttribute("Row", row)
	local top = part(d, "Top", Vector3.new(6, 0.5, 3.2), L(dx, y0 + 3.4, dz), C.desk, Enum.Material.Wood)
	for _, lx in { -2.6, 2.6 } do
		for _, lz in { -1.3, 1.3 } do
			part(d, "Leg", Vector3.new(0.3, 2.8, 0.3), L(dx + lx, y0 + 1.9, dz + lz), C.deskLeg, Enum.Material.Metal)
		end
	end
	part(d, "Seat", Vector3.new(2.6, 0.4, 2.4), L(dx, y0 + 2.2, dz + 3.2), C.chair)
	part(d, "Backrest", Vector3.new(2.6, 2.4, 0.3), L(dx, y0 + 3.6, dz + 4.4), C.chair)
	for _, lx in { -1.1, 1.1 } do
		for _, lz in { 2.2, 4.2 } do
			part(d, "ChairLeg", Vector3.new(0.25, 1.8, 0.25), L(dx + lx, y0 + 1.3, dz + lz), C.deskLeg, Enum.Material.Metal)
		end
	end
	part(d, "SitPoint", Vector3.new(1, 1, 1), L(dx, y0 + 3.6, dz + 3.0), C.pad, nil, HIDDEN)
	local pad = part(d, "CollectPad", Vector3.new(3.6, 0.3, 3.6), L(dx + 5.2, y0 + 0.75, dz + 3.2), C.pad, Enum.Material.Neon)
	local bb = billboard(pad, "Cash", "", 1.8, UDim2.fromOffset(140, 36))
	bb.MaxDistance = 60
	bb.Label.TextColor3 = Color3.fromRGB(120, 255, 120)
	d.PrimaryPart = top
	if locked then
		d:SetAttribute("Locked", true)
		for _, bp in d:GetDescendants() do
			if bp:IsA("BasePart") and bp.Name ~= "SitPoint" then
				bp.Transparency = 0.8
				bp.CanCollide = false
			end
		end
		bb.Enabled = false
	end
	return d
end

-- the parts every floor shares: desks, chalkboard, teacher spot, elevator pad, windows
local function classroom(parent, L, floor, y0)
	local desks = Instance.new("Folder"); desks.Name = "Desks"; desks.Parent = parent
	local slot = (floor - 1) * 16
	for r, dz in DESK_ROWS do
		for _, dx in DESK_COLS do
			slot += 1
			desk(desks, L, slot, r, dx, dz, y0, r > 2)
		end
	end
	local board = part(parent, "Chalkboard", Vector3.new(40, 10, 0.6), L(0, y0 + 7.5, -PLOT_D / 2 + 1.3), C.board)
	part(parent, "BoardFrame", Vector3.new(41.5, 11.5, 0.4), L(0, y0 + 7.5, -PLOT_D / 2 + 1.05), C.desk, Enum.Material.Wood)
	signGui(board, Enum.NormalId.Back, floor == 1 and "Welcome to class!" or ("Floor " .. floor), Color3.fromRGB(245, 245, 235), C.board, Enum.Font.PermanentMarker)
	board.SurfaceGui.Label.UIStroke.Thickness = 0
	-- the teacher stands in front of the board, facing the class
	part(parent, "TeacherSpot", Vector3.new(1, 1, 1), L(0, y0 + 0.6, -PLOT_D / 2 + 6) * CFrame.Angles(0, math.pi, 0), C.pad, nil, HIDDEN)
	part(parent, "TeacherDesk", Vector3.new(8, 3, 3), L(-12, y0 + 2.1, -PLOT_D / 2 + 7), C.desk, Enum.Material.Wood)
	part(parent, "Apple", Vector3.new(1, 1, 1), L(-10, y0 + 4.1, -PLOT_D / 2 + 7), Color3.fromRGB(220, 30, 40), nil, { Shape = Enum.PartType.Ball })
	-- elevator pad (front right corner inside)
	local pad = part(parent, "ElevatorPad", Vector3.new(5, 0.4, 5), L(ELEVATOR.X, y0 + 0.8, ELEVATOR.Z), Color3.fromRGB(80, 170, 255), Enum.Material.Neon)
	pad:SetAttribute("Floor", floor)
	billboard(pad, "Info", "ELEVATOR", 3)
	-- windows on the side walls
	local windows = Instance.new("Folder"); windows.Name = "Windows"; windows.Parent = parent
	for _, sx in { -1, 1 } do
		for _, wz in { -25, 0, 25 } do
			part(windows, "Window", Vector3.new(2.3, 5, 10), L(sx * PLOT_W / 2, y0 + 8, wz), C.glass, Enum.Material.Glass, { Transparency = 0.35 })
			part(windows, "Sill", Vector3.new(2.6, 0.5, 11), L(sx * PLOT_W / 2, y0 + 5.3, wz), C.wallIn)
		end
	end
end

-- outer walls of one floor; the ground floor has the gate gap in front
local function walls(parent, L, y0, gate)
	local w = Instance.new("Folder"); w.Name = "Walls"; w.Parent = parent
	local caps = Instance.new("Folder"); caps.Name = "Caps"; caps.Parent = parent
	part(w, "Back", Vector3.new(PLOT_W, WALL_H, 2), L(0, y0 + WALL_H / 2, -PLOT_D / 2), C.brick, Enum.Material.Brick)
	part(w, "Left", Vector3.new(2, WALL_H, PLOT_D), L(-PLOT_W / 2, y0 + WALL_H / 2, 0), C.brick, Enum.Material.Brick)
	part(w, "Right", Vector3.new(2, WALL_H, PLOT_D), L(PLOT_W / 2, y0 + WALL_H / 2, 0), C.brick, Enum.Material.Brick)
	if gate then
		local seg = (PLOT_W - GATE) / 2
		part(w, "FrontL", Vector3.new(seg, WALL_H, 2), L(-(GATE / 2 + seg / 2), y0 + WALL_H / 2, PLOT_D / 2), C.brick, Enum.Material.Brick)
		part(w, "FrontR", Vector3.new(seg, WALL_H, 2), L(GATE / 2 + seg / 2, y0 + WALL_H / 2, PLOT_D / 2), C.brick, Enum.Material.Brick)
		part(caps, "CapFL", Vector3.new(seg, 1, 3), L(-(GATE / 2 + seg / 2), y0 + WALL_H + 0.5, PLOT_D / 2), C.wallIn)
		part(caps, "CapFR", Vector3.new(seg, 1, 3), L(GATE / 2 + seg / 2, y0 + WALL_H + 0.5, PLOT_D / 2), C.wallIn)
	else
		part(w, "Front", Vector3.new(PLOT_W, WALL_H, 2), L(0, y0 + WALL_H / 2, PLOT_D / 2), C.brick, Enum.Material.Brick)
		part(caps, "CapFront", Vector3.new(PLOT_W + 1, 1, 3), L(0, y0 + WALL_H + 0.5, PLOT_D / 2), C.wallIn)
		-- front windows upstairs
		for _, wx in { -22, 0, 22 } do
			part(w.Parent:FindFirstChild("Windows") or w, "Window", Vector3.new(10, 5, 2.3), L(wx, y0 + 8, PLOT_D / 2), C.glass, Enum.Material.Glass, { Transparency = 0.35 })
		end
	end
	part(caps, "CapBack", Vector3.new(PLOT_W + 1, 1, 3), L(0, y0 + WALL_H + 0.5, -PLOT_D / 2), C.wallIn)
	part(caps, "CapLeft", Vector3.new(3, 1, PLOT_D + 1), L(-PLOT_W / 2, y0 + WALL_H + 0.5, 0), C.wallIn)
	part(caps, "CapRight", Vector3.new(3, 1, PLOT_D + 1), L(PLOT_W / 2, y0 + WALL_H + 0.5, 0), C.wallIn)
end

local function floorTiles(parent, L, y0)
	local slab = part(parent, "Floor", Vector3.new(PLOT_W, 0.6, PLOT_D), L(0, y0 + 0.3, 0), C.floor)
	for tx = -PLOT_W / 2 + 5, PLOT_W / 2 - 5, 10 do
		for tz = -PLOT_D / 2 + 5, PLOT_D / 2 - 5, 10 do
			if ((tx + tz) / 10) % 2 == 0 then
				part(slab, "Tile", Vector3.new(10, 0.05, 10), L(tx, y0 + 0.62, tz), C.tile, nil, { CanCollide = false, CanQuery = false })
			end
		end
	end
	return slab
end

-- upper floor templates, built around the origin (identity base)
for f = 2, 3 do
	local y0 = FLOOR_H * (f - 1)
	local m = Instance.new("Model"); m.Name = "Floor" .. f; m.Parent = templates
	local function L(x, y, z) return CFrame.new(x, y, z) end
	-- the slab doubles as the ceiling of the floor below; a thicker underside hides the seam
	part(m, "Ceiling", Vector3.new(PLOT_W, 0.8, PLOT_D), L(0, y0 - 0.4, 0), C.wallIn)
	local slab = floorTiles(m, L, y0)
	m.PrimaryPart = slab
	classroom(m, L, f, y0)
	walls(m, L, y0, false)
	-- ceiling lights for the floor below
	for _, lz in { -25, 0, 25 } do
		for _, lx in { -18, 18 } do
			local lamp = part(m, "CeilingLight", Vector3.new(6, 0.3, 2), L(lx, y0 - 0.95, lz), Color3.fromRGB(255, 252, 235), Enum.Material.Neon)
			local pl = Instance.new("PointLight"); pl.Range = 20; pl.Brightness = 0.9; pl.Color = Color3.fromRGB(255, 245, 220); pl.Parent = lamp
		end
	end
	-- the floor number on the outside, above the gate side
	local plate = part(m, "FloorPlate", Vector3.new(10, 3, 0.6), L(-22, y0 + 11.5, PLOT_D / 2 + 1.2), Color3.fromRGB(40, 90, 200))
	signGui(plate, Enum.NormalId.Back, "FLOOR " .. f, Color3.new(1, 1, 1), Color3.fromRGB(40, 90, 200))
	signGui(plate, Enum.NormalId.Front, "FLOOR " .. f, Color3.new(1, 1, 1), Color3.fromRGB(40, 90, 200))
end

---------------------------------------------------------------------------
-- plots (ground floors)
---------------------------------------------------------------------------
local plotXs = { -150, -50, 50, 150 }
local idx = 0
for side = 1, 2 do
	for _, px in plotXs do
		idx += 1
		local pz = side == 1 and 63 or -63
		-- local +Z points at the hallway
		local base = CFrame.new(px, 0, pz) * (side == 1 and CFrame.Angles(0, math.pi, 0) or CFrame.new())
		local function L(x, y, z) return base * CFrame.new(x, y, z) end

		local plot = Instance.new("Model"); plot.Name = "Plot" .. idx; plot.Parent = plots
		plot:SetAttribute("Index", idx)
		plot:SetAttribute("OwnerId", 0)
		part(plot, "Origin", Vector3.new(1, 1, 1), base, C.pad, nil, HIDDEN)
		local slab = floorTiles(plot, L, 0)
		plot.PrimaryPart = slab
		classroom(plot, L, 1, 0)
		walls(plot, L, 0, true)
		-- the ground-floor elevator waits for floor 2
		plot.ElevatorPad.Transparency = 1
		plot.ElevatorPad.CanCollide = false
		plot.ElevatorPad.Info.Enabled = false

		local wf = plot.Walls
		part(wf, "PostL", Vector3.new(3, WALL_H + 6, 3), L(-GATE / 2 - 1, (WALL_H + 6) / 2, PLOT_D / 2), C.wallIn)
		part(wf, "PostR", Vector3.new(3, WALL_H + 6, 3), L(GATE / 2 + 1, (WALL_H + 6) / 2, PLOT_D / 2), C.wallIn)
		local sign = part(plot, "Sign", Vector3.new(GATE + 8, 5, 1.2), L(0, WALL_H + 3.5, PLOT_D / 2 + 0.2), Color3.fromRGB(40, 90, 200))
		signGui(sign, Enum.NormalId.Back, "Empty School", Color3.new(1, 1, 1), Color3.fromRGB(40, 90, 200))
		signGui(sign, Enum.NormalId.Front, "Empty School", Color3.new(1, 1, 1), Color3.fromRGB(40, 90, 200))
		-- tier and star plate under the sign
		local plate = part(plot, "TierPlate", Vector3.new(GATE + 2, 1.6, 1), L(0, WALL_H + 0.3, PLOT_D / 2 + 0.3), Color3.fromRGB(30, 30, 40))
		signGui(plate, Enum.NormalId.Back, "Kindergarten", Color3.fromRGB(255, 220, 90), Color3.fromRGB(30, 30, 40))
		signGui(plate, Enum.NormalId.Front, "Kindergarten", Color3.fromRGB(255, 220, 90), Color3.fromRGB(30, 30, 40))

		-- laser gate
		local gate = Instance.new("Folder"); gate.Name = "Gate"; gate.Parent = plot
		part(gate, "Barrier", Vector3.new(GATE, WALL_H, 1), L(0, WALL_H / 2, PLOT_D / 2), Color3.fromRGB(255, 40, 60), Enum.Material.ForceField, { Transparency = 1, CanCollide = false })
		for i = 1, 4 do
			part(gate, "Laser", Vector3.new(GATE, 0.3, 0.3), L(0, i * 2.8, PLOT_D / 2), Color3.fromRGB(255, 40, 60), Enum.Material.Neon, { Transparency = 1, CanCollide = false, CanQuery = false })
		end

		-- lock button just inside the gate
		local lock = Instance.new("Model"); lock.Name = "LockButton"; lock.Parent = plot
		part(lock, "Base", Vector3.new(5, 1, 5), L(GATE / 2 + 6, 1, PLOT_D / 2 - 6), Color3.fromRGB(60, 60, 70))
		local btn = part(lock, "Button", Vector3.new(1, 4, 4), L(GATE / 2 + 6, 1.8, PLOT_D / 2 - 6) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(230, 40, 50), Enum.Material.Neon, { Shape = Enum.PartType.Cylinder })
		lock.PrimaryPart = btn
		billboard(btn, "Info", "LOCK", 4)

		-- owner spawn, student entry, "inside my school" bounds, runtime floors
		part(plot, "Spawn", Vector3.new(1, 1, 1), L(0, 3, PLOT_D / 2 - 10), C.pad, nil, HIDDEN)
		part(plot, "Entry", Vector3.new(1, 1, 1), L(0, 3, PLOT_D / 2 + 4), C.pad, nil, HIDDEN)
		part(plot, "Bounds", Vector3.new(PLOT_W, 60, PLOT_D), L(0, 30, 0), C.pad, nil, HIDDEN)
		local floors = Instance.new("Folder"); floors.Name = "Floors"; floors.Parent = plot
	end
end

---------------------------------------------------------------------------
-- the Board Room, high above the map (School Board review cutscene)
---------------------------------------------------------------------------
local room = Instance.new("Model"); room.Name = "BoardRoom"; room.Parent = workspace
local R = CFrame.new(0, 400, 0)
local function RL(x, y, z) return R * CFrame.new(x, y, z) end
part(room, "Floor", Vector3.new(60, 1, 40), RL(0, 0, 0), Color3.fromRGB(120, 30, 40))
part(room, "Back", Vector3.new(60, 24, 1), RL(0, 12, -20), Color3.fromRGB(90, 60, 45), Enum.Material.Wood)
part(room, "Left", Vector3.new(1, 24, 40), RL(-30, 12, 0), Color3.fromRGB(90, 60, 45), Enum.Material.Wood)
part(room, "Right", Vector3.new(1, 24, 40), RL(30, 12, 0), Color3.fromRGB(90, 60, 45), Enum.Material.Wood)
part(room, "Ceiling", Vector3.new(60, 1, 40), RL(0, 24, 0), Color3.fromRGB(240, 235, 225))
part(room, "Table", Vector3.new(36, 1, 7), RL(0, 4, -8), Color3.fromRGB(110, 70, 40), Enum.Material.Wood)
part(room, "TableFront", Vector3.new(36, 3.5, 0.6), RL(0, 2, -4.8), Color3.fromRGB(95, 60, 35), Enum.Material.Wood)
local banner = part(room, "Banner", Vector3.new(30, 5, 0.4), RL(0, 17, -19.5), Color3.fromRGB(30, 50, 110))
signGui(banner, Enum.NormalId.Back, "THE SCHOOL BOARD", Color3.fromRGB(255, 220, 90), Color3.fromRGB(30, 50, 110), Enum.Font.LuckiestGuy)
for i = -2, 2 do
	part(room, "BoardSeat", Vector3.new(1, 1, 1), RL(i * 7, 3.2, -11) * CFrame.Angles(0, 0, 0), C.pad, nil, HIDDEN)
	part(room, "Chair", Vector3.new(3, 5, 0.6), RL(i * 7, 4.5, -13), Color3.fromRGB(60, 20, 30))
	part(room, "Nameplate", Vector3.new(4, 1, 0.4), RL(i * 7, 4.9, -5.2), Color3.fromRGB(255, 210, 80), Enum.Material.Metal)
end
part(room, "Podium", Vector3.new(4, 4, 3), RL(0, 2, 10), Color3.fromRGB(110, 70, 40), Enum.Material.Wood)
part(room, "PlayerMark", Vector3.new(1, 1, 1), RL(0, 3, 13) * CFrame.Angles(0, 0, 0), C.pad, nil, HIDDEN)
part(room, "CameraA", Vector3.new(1, 1, 1), CFrame.lookAt(RL(0, 9, 22).Position, RL(0, 5, -8).Position), C.pad, nil, HIDDEN)
part(room, "CameraB", Vector3.new(1, 1, 1), CFrame.lookAt(RL(-12, 7, 4).Position, RL(0, 5, -9).Position), C.pad, nil, HIDDEN)
part(room, "Gavel", Vector3.new(0.6, 0.6, 2.4), RL(3, 4.8, -8) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(90, 50, 25), Enum.Material.Wood)
for _, x in { -20, 20 } do
	local lamp = part(room, "Lamp", Vector3.new(2, 2, 2), RL(x, 20, 0), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
	local pl = Instance.new("PointLight"); pl.Range = 40; pl.Brightness = 2; pl.Parent = lamp
end

---------------------------------------------------------------------------
-- classic studded look (neon, glass and metal stay)
---------------------------------------------------------------------------
local KEEP = { [Enum.Material.Neon] = true, [Enum.Material.Glass] = true, [Enum.Material.Metal] = true, [Enum.Material.ForceField] = true }
for _, root in { map, plots, templates, room } do
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") and not p:IsA("SpawnLocation") and not KEEP[p.Material] and p.Transparency < 1 then
			p.Material = Enum.Material.Plastic
			p.TopSurface = Enum.SurfaceType.Studs
			p.BottomSurface = Enum.SurfaceType.Inlet
		end
	end
end

---------------------------------------------------------------------------
-- lighting: bright, saturated afternoon
---------------------------------------------------------------------------
Lighting.ClockTime = 14.5
Lighting.Brightness = 3
Lighting.GlobalShadows = true
Lighting.Ambient = Color3.fromRGB(110, 110, 130)
Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 170)
local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
cc.Saturation = 0.25; cc.Contrast = 0.08; cc.Brightness = 0.02
if Lighting:FindFirstChild("Atmosphere") then
	Lighting.Atmosphere.Density = 0.25; Lighting.Atmosphere.Haze = 0.5
	Lighting.Atmosphere.Color = Color3.fromRGB(200, 225, 255)
end
if Lighting:FindFirstChild("DepthOfField") then Lighting.DepthOfField.Enabled = false end

return ("map built: %d plots, %d floor templates"):format(idx, #templates:GetChildren())
