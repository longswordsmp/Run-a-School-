-- Builds the static map in Edit mode. Re-runnable: clears Workspace.Map and Workspace.Plots first.
local Lighting = game:GetService("Lighting")

for _, n in { "Map", "Plots" } do
	local old = workspace:FindFirstChild(n)
	if old then old:Destroy() end
end
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

local C = {
	grass = Color3.fromRGB(104, 196, 84),
	sidewalk = Color3.fromRGB(214, 214, 222),
	carpet = Color3.fromRGB(214, 44, 58),
	trim = Color3.fromRGB(255, 196, 40),
	floor = Color3.fromRGB(240, 226, 196),
	brick = Color3.fromRGB(196, 92, 68),
	wallIn = Color3.fromRGB(255, 244, 214),
	desk = Color3.fromRGB(196, 140, 84),
	deskLeg = Color3.fromRGB(90, 90, 100),
	chair = Color3.fromRGB(60, 132, 232),
	board = Color3.fromRGB(38, 74, 56),
	pad = Color3.fromRGB(70, 230, 110),
	bus = Color3.fromRGB(255, 190, 20),
}

local map = Instance.new("Folder"); map.Name = "Map"; map.Parent = workspace
local plots = Instance.new("Folder"); plots.Name = "Plots"; plots.Parent = workspace

-- ground and hallway
part(map, "Ground", Vector3.new(700, 2, 500), CFrame.new(0, -1, 0), C.grass, Enum.Material.Grass)
part(map, "Sidewalk", Vector3.new(500, 0.4, 36), CFrame.new(0, 0.2, 0), C.sidewalk, Enum.Material.Concrete)
local carpet = part(map, "Carpet", Vector3.new(470, 0.3, 16), CFrame.new(0, 0.5, 0), C.carpet, Enum.Material.Fabric)
part(map, "TrimN", Vector3.new(470, 0.32, 1), CFrame.new(0, 0.5, 8.5), C.trim, Enum.Material.SmoothPlastic)
part(map, "TrimS", Vector3.new(470, 0.32, 1), CFrame.new(0, 0.5, -8.5), C.trim, Enum.Material.SmoothPlastic)

-- path markers the spawner walks along
local path = Instance.new("Folder"); path.Name = "HallPath"; path.Parent = map
part(path, "Start", Vector3.new(1, 1, 1), CFrame.new(-228, 1, 0), C.trim, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
part(path, "End", Vector3.new(1, 1, 1), CFrame.new(236, 1, 0), C.trim, nil, { Transparency = 1, CanCollide = false, CanQuery = false })

-- school bus at the start
local bus = Instance.new("Model"); bus.Name = "SchoolBus"; bus.Parent = map
local bx, bz = -250, 0
part(bus, "Body", Vector3.new(34, 11, 12), CFrame.new(bx - 6, 7.5, bz + 2), C.bus)
part(bus, "Hood", Vector3.new(6, 6, 11), CFrame.new(bx + 14, 5, bz + 2), C.bus)
part(bus, "Roof", Vector3.new(34, 1, 12.4), CFrame.new(bx - 6, 13.3, bz + 2), Color3.fromRGB(245, 245, 245))
part(bus, "StripeA", Vector3.new(34.2, 0.6, 12.2), CFrame.new(bx - 6, 6.5, bz + 2), Color3.fromRGB(20, 20, 20))
part(bus, "StripeB", Vector3.new(34.2, 0.6, 12.2), CFrame.new(bx - 6, 8, bz + 2), Color3.fromRGB(20, 20, 20))
for i = 0, 5 do
	part(bus, "WinS" .. i, Vector3.new(4, 3, 12.3), CFrame.new(bx - 20 + i * 5, 10.5, bz + 2), Color3.fromRGB(120, 190, 240), Enum.Material.Glass, { Transparency = 0.2 })
end
part(bus, "Windshield", Vector3.new(0.3, 4, 10), CFrame.new(bx + 11.1, 10.5, bz + 2), Color3.fromRGB(120, 190, 240), Enum.Material.Glass, { Transparency = 0.2 })
part(bus, "Door", Vector3.new(3.4, 8, 0.4), CFrame.new(bx + 8, 6, bz - 4.1), Color3.fromRGB(40, 40, 40))
for _, wx in { bx - 16, bx + 12 } do
	for _, wz in { bz - 4.5, bz + 8.5 } do
		part(bus, "Wheel", Vector3.new(1.6, 5, 5), CFrame.new(wx, 2.5, wz) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(30, 30, 30), nil, { Shape = Enum.PartType.Cylinder })
	end
end
part(bus, "StopArm", Vector3.new(0.4, 2.4, 2.4), CFrame.new(bx - 10, 8, bz - 4.3) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(220, 30, 30), nil, { Shape = Enum.PartType.Cylinder })
local busSign = part(bus, "Sign", Vector3.new(20, 2.4, 0.2), CFrame.new(bx - 6, 12, bz - 4.1), C.bus)
signGui(busSign, Enum.NormalId.Front, "SCHOOL BUS", Color3.fromRGB(20, 20, 20), C.bus, Enum.Font.FredokaOne)

-- detention building at the end (students nobody enrolled go here)
local det = Instance.new("Model"); det.Name = "Detention"; det.Parent = map
part(det, "Block", Vector3.new(24, 20, 34), CFrame.new(252, 10, 0), Color3.fromRGB(110, 110, 124), Enum.Material.Brick)
part(det, "Doorway", Vector3.new(0.4, 12, 12), CFrame.new(239.9, 6, 0), Color3.fromRGB(15, 15, 20))
local detSign = part(det, "Sign", Vector3.new(0.4, 4, 22), CFrame.new(239.8, 16, 0), Color3.fromRGB(40, 40, 50))
signGui(detSign, Enum.NormalId.Left, "DETENTION", Color3.fromRGB(255, 70, 70), Color3.fromRGB(40, 40, 50))

-- hub spawn in the middle of the hallway
local spawn = Instance.new("SpawnLocation")
spawn.Name = "HubSpawn"; spawn.Size = Vector3.new(12, 0.4, 12); spawn.CFrame = CFrame.new(0, 0.3, -30)
spawn.Anchored = true; spawn.Transparency = 1; spawn.CanCollide = false; spawn.Neutral = true
spawn.Parent = map
for _, d in spawn:GetChildren() do d:Destroy() end

-- street lamps and trees along the sidewalk
local deco = Instance.new("Folder"); deco.Name = "Deco"; deco.Parent = map
for x = -200, 200, 50 do
	for _, z in { -14, 14 } do
		local lamp = Instance.new("Model"); lamp.Name = "Lamp"; lamp.Parent = deco
		part(lamp, "Pole", Vector3.new(0.8, 12, 0.8), CFrame.new(x + 25, 6, z), Color3.fromRGB(50, 50, 60), Enum.Material.Metal)
		local bulb = part(lamp, "Bulb", Vector3.new(2, 2, 2), CFrame.new(x + 25, 12.5, z), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
		local l = Instance.new("PointLight"); l.Range = 18; l.Brightness = 1.2; l.Color = Color3.fromRGB(255, 230, 180); l.Parent = bulb
	end
end

-- plots
local PLOT_W, PLOT_D, WALL_H = 70, 90, 14
local DESK_COLS = { -24, -8, 8, 24 }
local DESK_ROWS = { 18, 4, -10, -24 } -- local z; row 1 nearest the gate
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
		local floor = part(plot, "Floor", Vector3.new(PLOT_W, 0.6, PLOT_D), L(0, 0.3, 0), C.floor, Enum.Material.SmoothPlastic)
		-- checker tiles: darker squares laid on the floor
		for tx = -PLOT_W / 2 + 5, PLOT_W / 2 - 5, 10 do
			for tz = -PLOT_D / 2 + 5, PLOT_D / 2 - 5, 10 do
				if ((tx + tz) / 10) % 2 == 0 then
					part(floor, "Tile", Vector3.new(10, 0.05, 10), L(tx, 0.62, tz), Color3.fromRGB(222, 204, 170), Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false })
				end
			end
		end
		plot.PrimaryPart = floor

		local walls = Instance.new("Folder"); walls.Name = "Walls"; walls.Parent = plot
		part(walls, "Back", Vector3.new(PLOT_W, WALL_H, 2), L(0, WALL_H / 2, -PLOT_D / 2), C.brick, Enum.Material.Brick)
		part(walls, "Left", Vector3.new(2, WALL_H, PLOT_D), L(-PLOT_W / 2, WALL_H / 2, 0), C.brick, Enum.Material.Brick)
		part(walls, "Right", Vector3.new(2, WALL_H, PLOT_D), L(PLOT_W / 2, WALL_H / 2, 0), C.brick, Enum.Material.Brick)
		local GATE = 18
		local seg = (PLOT_W - GATE) / 2
		part(walls, "FrontL", Vector3.new(seg, WALL_H, 2), L(-(GATE / 2 + seg / 2), WALL_H / 2, PLOT_D / 2), C.brick, Enum.Material.Brick)
		part(walls, "FrontR", Vector3.new(seg, WALL_H, 2), L(GATE / 2 + seg / 2, WALL_H / 2, PLOT_D / 2), C.brick, Enum.Material.Brick)
		-- white cap along the wall tops
		part(walls, "CapBack", Vector3.new(PLOT_W + 1, 1, 3), L(0, WALL_H + 0.5, -PLOT_D / 2), C.wallIn)
		part(walls, "CapLeft", Vector3.new(3, 1, PLOT_D + 1), L(-PLOT_W / 2, WALL_H + 0.5, 0), C.wallIn)
		part(walls, "CapRight", Vector3.new(3, 1, PLOT_D + 1), L(PLOT_W / 2, WALL_H + 0.5, 0), C.wallIn)
		part(walls, "CapFL", Vector3.new(seg, 1, 3), L(-(GATE / 2 + seg / 2), WALL_H + 0.5, PLOT_D / 2), C.wallIn)
		part(walls, "CapFR", Vector3.new(seg, 1, 3), L(GATE / 2 + seg / 2, WALL_H + 0.5, PLOT_D / 2), C.wallIn)
		-- gate posts + arch with the school sign
		part(walls, "PostL", Vector3.new(3, WALL_H + 6, 3), L(-GATE / 2 - 1, (WALL_H + 6) / 2, PLOT_D / 2), C.wallIn)
		part(walls, "PostR", Vector3.new(3, WALL_H + 6, 3), L(GATE / 2 + 1, (WALL_H + 6) / 2, PLOT_D / 2), C.wallIn)
		local sign = part(plot, "Sign", Vector3.new(GATE + 8, 5, 1.2), L(0, WALL_H + 3.5, PLOT_D / 2 + 0.2), Color3.fromRGB(40, 90, 200))
		signGui(sign, Enum.NormalId.Back, "Empty School", Color3.new(1, 1, 1), Color3.fromRGB(40, 90, 200))
		signGui(sign, Enum.NormalId.Front, "Empty School", Color3.new(1, 1, 1), Color3.fromRGB(40, 90, 200))

		-- laser gate (server toggles it)
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
		local lbb = Instance.new("BillboardGui"); lbb.Name = "Info"; lbb.Size = UDim2.fromOffset(160, 50)
		lbb.StudsOffset = Vector3.new(0, 4, 0); lbb.AlwaysOnTop = false; lbb.MaxDistance = 80; lbb.Parent = btn
		local lt = Instance.new("TextLabel"); lt.Name = "Label"; lt.Size = UDim2.fromScale(1, 1); lt.BackgroundTransparency = 1
		lt.Text = "LOCK"; lt.TextScaled = true; lt.Font = Enum.Font.FredokaOne; lt.TextColor3 = Color3.new(1, 1, 1); lt.Parent = lbb
		local ls = Instance.new("UIStroke"); ls.Thickness = 3; ls.Parent = lt

		-- chalkboard on the back wall
		local board = part(plot, "Chalkboard", Vector3.new(40, 10, 0.6), L(0, 7.5, -PLOT_D / 2 + 1.3), C.board)
		part(plot, "BoardFrame", Vector3.new(41.5, 11.5, 0.4), L(0, 7.5, -PLOT_D / 2 + 1.05), C.desk, Enum.Material.Wood)
		signGui(board, Enum.NormalId.Back, "Welcome to class!", Color3.fromRGB(245, 245, 235), C.board, Enum.Font.PermanentMarker)
		board.SurfaceGui.Label.UIStroke.Thickness = 0

		-- desks
		local desks = Instance.new("Folder"); desks.Name = "Desks"; desks.Parent = plot
		local slot = 0
		for r, dz in DESK_ROWS do
			for _, dx in DESK_COLS do
				slot += 1
				local d = Instance.new("Model"); d.Name = "Desk" .. slot; d.Parent = desks
				d:SetAttribute("Slot", slot)
				d:SetAttribute("Row", r)
				local top = part(d, "Top", Vector3.new(6, 0.5, 3.2), L(dx, 3.4, dz), C.desk, Enum.Material.Wood)
				for _, lx in { -2.6, 2.6 } do
					for _, lz in { -1.3, 1.3 } do
						part(d, "Leg", Vector3.new(0.3, 2.8, 0.3), L(dx + lx, 1.9, dz + lz), C.deskLeg, Enum.Material.Metal)
					end
				end
				-- chair behind the desk (student faces the chalkboard, -Z local)
				part(d, "Seat", Vector3.new(2.6, 0.4, 2.4), L(dx, 2.2, dz + 3.2), C.chair)
				part(d, "Backrest", Vector3.new(2.6, 2.4, 0.3), L(dx, 3.6, dz + 4.4), C.chair)
				for _, lx in { -1.1, 1.1 } do
					for _, lz in { 2.2, 4.2 } do
						part(d, "ChairLeg", Vector3.new(0.25, 1.8, 0.25), L(dx + lx, 1.3, dz + lz), C.deskLeg, Enum.Material.Metal)
					end
				end
				-- where the student sits: HumanoidRootPart CFrame target (faces -Z local)
				part(d, "SitPoint", Vector3.new(1, 1, 1), L(dx, 3.6, dz + 3.0), C.pad, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
				-- collect pad in the aisle beside the desk
				local pad = part(d, "CollectPad", Vector3.new(3.6, 0.3, 3.6), L(dx + 5.2, 0.75, dz + 3.2), C.pad, Enum.Material.Neon)
				local bb = Instance.new("BillboardGui"); bb.Name = "Cash"; bb.Size = UDim2.fromOffset(140, 36)
				bb.StudsOffset = Vector3.new(0, 1.8, 0); bb.MaxDistance = 60; bb.Parent = pad
				local ct = Instance.new("TextLabel"); ct.Name = "Label"; ct.Size = UDim2.fromScale(1, 1); ct.BackgroundTransparency = 1
				ct.Text = ""; ct.TextScaled = true; ct.Font = Enum.Font.FredokaOne; ct.TextColor3 = Color3.fromRGB(120, 255, 120); ct.Parent = bb
				local cs = Instance.new("UIStroke"); cs.Thickness = 3; cs.Parent = ct
				d.PrimaryPart = top
				-- rows 3 and 4 are locked until the classroom upgrade
				if r > 2 then
					d:SetAttribute("Locked", true)
					for _, bp in d:GetDescendants() do
						if bp:IsA("BasePart") and bp.Name ~= "SitPoint" then
							bp.Transparency = 0.8
							bp.CanCollide = false
						end
					end
					bb.Enabled = false
				end
			end
		end

		-- spawn point for the owner, just inside the gate
		part(plot, "Spawn", Vector3.new(1, 1, 1), L(0, 3, PLOT_D / 2 - 10), C.pad, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
		-- where enrolled students enter (outside the gate, on the sidewalk)
		part(plot, "Entry", Vector3.new(1, 1, 1), L(0, 3, PLOT_D / 2 + 4), C.pad, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
		-- bounds used for "inside my school" checks
		part(plot, "Bounds", Vector3.new(PLOT_W, 40, PLOT_D), L(0, 20, 0), C.pad, nil, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	end
end

-- lighting: bright, saturated afternoon
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

return ("map built: %d plots"):format(idx)
