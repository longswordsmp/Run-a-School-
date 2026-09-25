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
part(map, "Ground", Vector3.new(860, 2, 520), CFrame.new(0, -1, 0), C.grass, Enum.Material.Grass)
part(map, "Sidewalk", Vector3.new(720, 0.4, 56), CFrame.new(0, 0.2, 0), C.sidewalk, Enum.Material.Concrete)
part(map, "Carpet", Vector3.new(660, 0.3, 16), CFrame.new(0, 0.5, 0), C.carpet, Enum.Material.Fabric)
part(map, "TrimN", Vector3.new(660, 0.32, 1), CFrame.new(0, 0.5, 8.5), C.trim)
part(map, "TrimS", Vector3.new(660, 0.32, 1), CFrame.new(0, 0.5, -8.5), C.trim)
for _, z in { -28.3, 28.3 } do
	part(map, "Curb", Vector3.new(720, 0.7, 0.8), CFrame.new(0, 0.35, z), C.curb, Enum.Material.Concrete)
end
local path = Instance.new("Folder"); path.Name = "HallPath"; path.Parent = map
part(path, "Start", Vector3.new(1, 1, 1), CFrame.new(-318, 1, 0), C.trim, nil, HIDDEN)
part(path, "End", Vector3.new(1, 1, 1), CFrame.new(346, 1, 0), C.trim, nil, HIDDEN)

---------------------------------------------------------------------------
-- school bus and shelter at the west end
---------------------------------------------------------------------------
local bus = Instance.new("Model"); bus.Name = "SchoolBus"; bus.Parent = map
local bx, bz = -345, 0
local body = part(bus, "Body", Vector3.new(34, 11, 12), CFrame.new(bx - 6, 7.5, bz + 2), C.bus)
bus.PrimaryPart = body
part(bus, "Hood", Vector3.new(6, 6, 11), CFrame.new(bx + 14, 5, bz + 2), C.bus)
part(bus, "Grille", Vector3.new(0.3, 3, 8), CFrame.new(bx + 17.1, 5, bz + 2), rgb(40, 40, 45))
for _, z in { bz - 1.5, bz + 5.5 } do
	part(bus, "Headlight", Vector3.new(0.4, 1.4, 1.4), CFrame.new(bx + 17.2, 6.2, z), rgb(255, 250, 220), Enum.Material.Neon)
end
part(bus, "Roof", Vector3.new(34, 1, 12.4), CFrame.new(bx - 6, 13.3, bz + 2), rgb(245, 245, 245))
part(bus, "StripeA", Vector3.new(34.2, 0.6, 12.2), CFrame.new(bx - 6, 6.5, bz + 2), rgb(20, 20, 20))
part(bus, "StripeB", Vector3.new(34.2, 0.6, 12.2), CFrame.new(bx - 6, 8, bz + 2), rgb(20, 20, 20))
for i = 0, 5 do
	part(bus, "Window", Vector3.new(4, 3, 12.3), CFrame.new(bx - 20 + i * 5, 10.5, bz + 2), rgb(120, 190, 240), Enum.Material.Glass, { Transparency = 0.2 })
end
part(bus, "Windshield", Vector3.new(0.3, 4, 10), CFrame.new(bx + 11.1, 10.5, bz + 2), rgb(120, 190, 240), Enum.Material.Glass, { Transparency = 0.2 })
part(bus, "Door", Vector3.new(3.4, 8, 0.4), CFrame.new(bx + 8, 6, bz - 4.1), rgb(40, 40, 40))
for _, wx in { bx - 16, bx + 12 } do
	for _, wz in { bz - 4.5, bz + 8.5 } do
		part(bus, "Wheel", Vector3.new(1.6, 5, 5), CFrame.new(wx, 2.5, wz) * CFrame.Angles(0, 0, math.rad(90)), rgb(30, 30, 30), nil, { Shape = Enum.PartType.Cylinder })
		part(bus, "Hubcap", Vector3.new(1.7, 2, 2), CFrame.new(wx, 2.5, wz) * CFrame.Angles(0, 0, math.rad(90)), rgb(200, 200, 205), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	end
end
part(bus, "StopArm", Vector3.new(0.4, 2.4, 2.4), CFrame.new(bx - 10, 8, bz - 4.3) * CFrame.Angles(0, math.rad(90), 0), rgb(220, 30, 30), nil, { Shape = Enum.PartType.Cylinder })
local busSign = part(bus, "Sign", Vector3.new(20, 2.4, 0.2), CFrame.new(bx - 6, 12, bz - 4.1), C.bus)
signGui(busSign, Enum.NormalId.Front, "SCHOOL BUS", rgb(20, 20, 20), C.bus, Enum.Font.FredokaOne)
part(map, "BusStop", Vector3.new(1, 1, 1), body.CFrame, C.bus, nil, HIDDEN)
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
for _, z in { -26, 26 } do
	part(hub, "ArchPost", Vector3.new(3, 22, 3), CFrame.new(0, 11, z), C.white)
	part(hub, "ArchCap", Vector3.new(4, 1, 4), CFrame.new(0, 22.5, z), C.trim)
end
local arch = part(hub, "ArchSign", Vector3.new(2, 6, 50), CFrame.new(0, 24, 0), rgb(214, 44, 58))
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
for _, gx in { -150, 0, 150 } do
	for _, z in { 45, 80, 115, 150, 185 } do
		for _, side in { -1, 1 } do
			n += 1
			if not (gx == 0 and side == -1 and z == 45) then
				tree(gx, side * z, 1 + (n % 3) * 0.12, leaves[n % #leaves + 1])
			end
		end
	end
end
for x = -380, 380, 38 do
	for _, z in { -225, 225 } do
		n += 1
		tree(x + (n % 2) * 9, z, 1.3, leaves[n % #leaves + 1])
	end
end
for _, x in { -330, 330 } do
	for z = 60, 200, 35 do
		for _, side in { -1, 1 } do
			n += 1
			tree(x, side * z, 1.2, leaves[n % #leaves + 1])
		end
	end
end

---------------------------------------------------------------------------
-- plots: lots with a gate arch; the school is built at runtime
---------------------------------------------------------------------------
local LOT_W, LOT_D, GATE = 120, 150, 18
local plotXs = { -225, -75, 75, 225 }
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
