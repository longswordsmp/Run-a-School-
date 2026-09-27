-- ReplicatedStorage.Shared.Limo
-- Dr. Vex's limo, part-built in the style of the school bus: a long, low, deep-purple stretch car with
-- a rounded nose and tail, chrome trim, a VexCorp pinstripe and underglow. Built by the server
-- (StoryService: the drive-by, the First Morning at your gate; StreetService: parked at the plaza) and
-- by the intro cutscene on the client.
-- Limo space: x along the car (front +X), y up from the road (the tyres touch y 0), z across (0 = the
-- middle). The pivot is the old limo's: the body's middle, y 2.5, so CFrame.new(x, 2.8, z) sets it on
-- the road.
-- side (+1 / -1): the side of the car facing the school. Vex rides INSIDE, sitting on a velvet bench
-- along the far side and facing out of the open window on this side; Crumpet drives, his window on
-- this side open too. (She used to stand up out of a sunroof from the knees, and Crumpet stood on
-- nothing behind the boot: both looked stuck half in and half out of the car.)
local Limo = {}

function Limo.build(side)
	side = side or -1
	local rgb = Color3.fromRGB
	local limo = Instance.new("Model")
	limo.Name = "VexLimo"
	limo:SetAttribute("Side", side)
	local PAINT = rgb(42, 24, 60) -- (a deep aubergine black: plain black with a shine read as navy, the sky in it)
	local CHROME = rgb(222, 224, 232)
	local GLASS = rgb(70, 58, 100)
	local PURPLE = rgb(165, 70, 255)
	local VELVET = rgb(110, 44, 150)
	local CARPET = rgb(48, 26, 70)
	local function p(name, size, cf, color, mat, props)
		local x = Instance.new("Part")
		x.Name = name
		x.Size = size
		x.CFrame = cf
		x.Color = color
		x.Material = mat or Enum.Material.SmoothPlastic
		x.TopSurface, x.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		x.Anchored, x.CanCollide, x.CanQuery, x.CanTouch = true, false, false, false
		if props then for k, v in props do x[k] = v end end
		x.Parent = limo
		return x
	end
	local function paint(name, size, cf) return p(name, size, cf, PAINT, Enum.Material.SmoothPlastic, { Reflectance = 0.04 }) end
	local function chrome(name, size, cf) return p(name, size, cf, CHROME, Enum.Material.Metal, { Reflectance = 0.25 }) end
	local function cyl(name, d, len, cf, color, mat, props)
		local x = p(name, Vector3.new(len, d, d), cf, color, mat, props)
		x.Shape = Enum.PartType.Cylinder
		return x
	end
	local ACROSS = CFrame.Angles(0, math.rad(90), 0) -- (a cylinder's round faces pointing across the car)
	local ALONG = CFrame.new() -- (round faces pointing along it)
	local function wedge(name, size, cf, color, mat, props)
		local w = Instance.new("WedgePart")
		w.Name = name
		w.Size = size
		w.CFrame = cf
		w.Color = color
		w.Material = mat or Enum.Material.SmoothPlastic
		w.TopSurface, w.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		w.Anchored, w.CanCollide, w.CanQuery, w.CanTouch = true, false, false, false
		if props then for k, v in props do w[k] = v end end
		w.Parent = limo
		return w
	end
	local SLOPE_FWD = CFrame.Angles(0, math.rad(-90), 0) -- (a wedge whose slope runs down towards +X)
	local SLOPE_BACK = CFrame.Angles(0, math.rad(90), 0) -- (down towards -X)

	-- the hull: a long low body with a hollow passenger bay in the middle (x -7..1)
	local floor = paint("Body", Vector3.new(30, 0.8, 8), CFrame.new(0, 1.5, 0))
	limo.PrimaryPart = floor
	floor.PivotOffset = CFrame.new(0, 1, 0) -- (the pivot: y 2.5, where the old limo had it)
	paint("Body", Vector3.new(14, 2, 8), CFrame.new(8, 2.9, 0)) -- the front (engine, driver)
	paint("Body", Vector3.new(8, 2, 8), CFrame.new(-11, 2.9, 0)) -- the back (the boot)
	-- rounded nose and tail
	for _, x in { 15, -15 } do
		cyl("Body", 2.8, 8, CFrame.new(x, 2.5, 0) * ACROSS, PAINT, Enum.Material.SmoothPlastic, { Reflectance = 0.04 })
	end
	-- the passenger bay's fixed wall panels either side of the doors
	for _, s in { -1, 1 } do
		paint("Body", Vector3.new(2, 2, 0.3), CFrame.new(-6, 2.9, s * 3.85))
		paint("Body", Vector3.new(2, 2, 0.3), CFrame.new(0, 2.9, s * 3.85))
	end
	p("Carpet", Vector3.new(8, 0.08, 7.4), CFrame.new(-3, 1.94, 0), CARPET, Enum.Material.Fabric)

	-- the cabin: pillars, a roof with rounded edges, tinted glass (open on the school side where Vex
	-- and Crumpet sit, so they're seen clearly)
	local ROOF_Y = 6.8 -- (tall enough for a grown-up sitting inside: Vex, seated, is 3.9 from seat to hair)
	paint("Roof", Vector3.new(19, 0.4, 7.4), CFrame.new(-2.5, ROOF_Y, 0))
	for _, s in { -1, 1 } do
		cyl("RoofEdge", 0.7, 19, CFrame.new(-2.5, ROOF_Y - 0.05, s * 3.55), PAINT, Enum.Material.SmoothPlastic, { Reflectance = 0.04 })
		for _, x in { 6.8, 1, -7, -12 } do
			paint("Pillar", Vector3.new(0.45, ROOF_Y - 3.9, 0.3), CFrame.new(x, (ROOF_Y + 3.9) / 2, s * 3.75))
		end
		chrome("Chrome", Vector3.new(19.2, 0.14, 0.12), CFrame.new(-2.5, ROOF_Y - 0.28, s * 3.92)) -- window tops
		chrome("Chrome", Vector3.new(30, 0.18, 0.12), CFrame.new(0, 3.95, s * 4.04)) -- the belt line
		p("Pinstripe", Vector3.new(29, 0.12, 0.06), CFrame.new(0, 2.25, s * 4.03), PURPLE, Enum.Material.Neon)
		chrome("Sill", Vector3.new(22, 0.3, 0.14), CFrame.new(-1, 1.25, s * 4.03))
		-- the windows: front (the driver), the rear quarter; the door windows ride on the doors
		local open = s == side
		if not open then
			p("Window", Vector3.new(5.4, 2.5, 0.1), CFrame.new(3.9, 5.3, s * 3.72), GLASS, Enum.Material.SmoothPlastic, { Transparency = 0.45 })
		end
		p("Window", Vector3.new(4.6, 2.5, 0.1), CFrame.new(-9.5, 5.3, s * 3.72), GLASS, Enum.Material.SmoothPlastic, { Transparency = 0.45 })
		p("Window", Vector3.new(1.6, 2.5, 0.1), CFrame.new(-6, 5.3, s * 3.72), GLASS, Enum.Material.SmoothPlastic, { Transparency = 0.45 })
		p("Window", Vector3.new(1.6, 2.5, 0.1), CFrame.new(0, 5.3, s * 3.72), GLASS, Enum.Material.SmoothPlastic, { Transparency = 0.45 })
		-- the rear door: a panel and a window frame that swing out together (hinged at the front)
		local door = paint("Door", Vector3.new(4, 2.6, 0.25), CFrame.new(-3, 2.6, s * 4))
		door:SetAttribute("DoorSide", s)
		local frame = chrome("Door", Vector3.new(4, 0.14, 0.12), CFrame.new(-3, ROOF_Y - 0.28, s * 3.95))
		frame:SetAttribute("DoorSide", s)
		for _, x in { -4.9, -1.1 } do
			local post = paint("Door", Vector3.new(0.2, ROOF_Y - 4.2, 0.2), CFrame.new(x, (ROOF_Y + 3.6) / 2 - 0.15, s * 3.9))
			post:SetAttribute("DoorSide", s)
		end
		if not open then
			local g = p("Door", Vector3.new(3.6, 2.5, 0.1), CFrame.new(-3, 5.3, s * 3.9), GLASS, Enum.Material.SmoothPlastic, { Transparency = 0.45 })
			g:SetAttribute("DoorSide", s)
		end
		local handle = chrome("Door", Vector3.new(0.7, 0.18, 0.12), CFrame.new(-4.3, 3.4, s * 4.15))
		handle:SetAttribute("DoorSide", s)
		-- a mirror, the wheel arches
		chrome("Mirror", Vector3.new(0.5, 0.7, 0.9), CFrame.new(6.3, 4.5, s * 4.35))
		paint("MirrorArm", Vector3.new(0.25, 0.2, 0.6), CFrame.new(6.4, 4.2, s * 4.05))
		for _, x in { -10.5, 10.5 } do
			cyl("WheelArch", 4, 0.1, CFrame.new(x, 1.7, s * 4.05) * ACROSS, rgb(12, 12, 16))
		end
		-- VexCorp flags on the front wings
		chrome("FlagPole", Vector3.new(0.12, 1.8, 0.12), CFrame.new(13.2, 4.8, s * 3.3))
		p("Flag", Vector3.new(1.3, 0.8, 0.05), CFrame.new(12.55, 5.3, s * 3.3), rgb(140, 50, 210), Enum.Material.Fabric)
	end
	-- the windscreen and the back window
	wedge("Windshield", Vector3.new(7.2, ROOF_Y - 3.9, 2.8), CFrame.new(8.2, (ROOF_Y + 3.9) / 2, 0) * SLOPE_FWD, GLASS, Enum.Material.SmoothPlastic, { Transparency = 0.45 })
	wedge("BackWindow", Vector3.new(7.2, ROOF_Y - 3.9, 2.4), CFrame.new(-13.2, (ROOF_Y + 3.9) / 2, 0) * SLOPE_BACK, GLASS, Enum.Material.SmoothPlastic, { Transparency = 0.45 })
	-- (a partition between Crumpet and the back)
	p("Partition", Vector3.new(0.15, ROOF_Y - 3.9, 7.2), CFrame.new(1.2, (ROOF_Y + 3.9) / 2, 0), GLASS, Enum.Material.SmoothPlastic, { Transparency = 0.55 })

	-- the front: a tall chrome grille, round headlights, a V on the bonnet, the bumper
	chrome("Grille", Vector3.new(0.2, 2, 3.4), CFrame.new(16.35, 2.6, 0))
	for i = -3, 3 do p("GrilleBar", Vector3.new(0.12, 1.8, 0.14), CFrame.new(16.45, 2.6, i * 0.45), rgb(30, 30, 40), Enum.Material.Metal) end
	for _, z in { -2.9, 2.9 } do
		cyl("HeadlightRim", 1.5, 0.3, CFrame.new(16.2, 2.95, z) * ALONG, CHROME, Enum.Material.Metal)
		cyl("Headlight", 1.2, 0.36, CFrame.new(16.26, 2.95, z) * ALONG, rgb(255, 250, 225), Enum.Material.Neon)
		cyl("FogLight", 0.5, 0.2, CFrame.new(16.05, 1.9, z * 0.85) * ALONG, PURPLE, Enum.Material.Neon)
		p("Taillight", Vector3.new(0.3, 0.6, 1.8), CFrame.new(-16.3, 3.1, z), rgb(225, 30, 45), Enum.Material.Neon)
	end
	for _, a in { -1, 1 } do
		chrome("Ornament", Vector3.new(0.12, 0.8, 0.12), CFrame.new(15.4, 4.35, a * 0.18) * CFrame.Angles(a * math.rad(20), 0, 0))
	end
	chrome("Bumper", Vector3.new(0.6, 0.6, 8.2), CFrame.new(16.5, 1.4, 0))
	chrome("RearBumper", Vector3.new(0.6, 0.6, 8.2), CFrame.new(-16.5, 1.4, 0))
	local plate = p("Plate", Vector3.new(0.12, 0.8, 2.6), CFrame.new(-16.45, 2.3, 0), rgb(250, 250, 240))
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Left
	g.Parent = plate
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.Arcade
	t.Text = "VEX 1"
	t.TextColor3 = rgb(90, 30, 130)
	t.Parent = g

	-- the wheels: fat tyres, chrome rims, purple caps
	for _, x in { -10.5, 10.5 } do
		for _, z in { -3.7, 3.7 } do
			local r = CFrame.new(x, 1.6, z) * ACROSS
			cyl("Wheel", 3.2, 1.3, r, rgb(16, 16, 18))
			cyl("Rim", 2, 1.36, r, CHROME, Enum.Material.Metal, { Reflectance = 0.25 })
			cyl("RimCap", 0.7, 1.42, r, rgb(130, 50, 190), Enum.Material.Metal)
		end
	end
	p("Underglow", Vector3.new(26, 0.2, 6.6), CFrame.new(0, 0.85, 0), PURPLE, Enum.Material.Neon)

	-- inside: Vex's velvet bench along the far side, a little bar with a purple glow, Crumpet's seat.
	-- (the seats are low, 0.6 over the floor: a seated grown-up needs 3.9 above the seat)
	local far = -side
	p("Bench", Vector3.new(5.6, 0.6, 1.7), CFrame.new(-3.2, 2.2, far * 2.8), VELVET, Enum.Material.Fabric)
	p("BenchBack", Vector3.new(5.6, 2.6, 0.5), CFrame.new(-3.2, 3.8, far * 3.45), VELVET, Enum.Material.Fabric)
	p("Bar", Vector3.new(0.9, 1.6, 2.4), CFrame.new(0.3, 2.7, far * 1.2), rgb(40, 34, 52), Enum.Material.SmoothPlastic)
	p("BarGlow", Vector3.new(0.92, 0.12, 2.42), CFrame.new(0.3, 3.2, far * 1.2), PURPLE, Enum.Material.Neon)
	p("DriverSeatBack", Vector3.new(0.5, 1.8, 1.8), CFrame.new(3.1, 4.8, side * 1.8), rgb(40, 34, 52))
	cyl("SteeringWheel", 1.3, 0.12, CFrame.new(5.9, 4.7, side * 1.8) * CFrame.Angles(0, 0, math.rad(-35)), rgb(30, 30, 36), Enum.Material.SmoothPlastic)
	-- where the riders' roots go, sitting (Limo.seat): 1.5 over the seat. Vex on the bench
	-- facing out of the open window; Crumpet behind the wheel (his legs are in the front of the car)
	local hidden = { Transparency = 1 }
	p("VexSeat", Vector3.new(1, 1, 1), CFrame.lookAt(Vector3.new(-3.2, 4.0, far * 2.75), Vector3.new(-3.2, 4.0, side * 10)), rgb(255, 0, 0), nil, hidden)
	p("DriverSeat", Vector3.new(1, 1, 1), CFrame.lookAt(Vector3.new(4.1, 4.0, side * 1.8), Vector3.new(20, 4.0, side * 1.8)), rgb(0, 255, 0), nil, hidden)
	-- (the doors' shut places, from the pivot, for Limo.door)
	local pivot = limo:GetPivot()
	for _, d in limo:GetChildren() do
		if d.Name == "Door" then d:SetAttribute("ClosedRel", pivot:ToObjectSpace(d.CFrame)) end
	end
	return limo
end

-- a rider (a rig) sitting at "VexSeat" or "DriverSeat": its root goes there, anchored. The caller plays
-- the sit animation. (Measured on the grown-up rigs sitting: 1.5 from the root down to the seat, 2.44
-- up to the top of the head.)
function Limo.seat(limo, rig, marker)
	local at = limo:FindFirstChild(marker)
	local root = rig.PrimaryPart or rig:FindFirstChild("HumanoidRootPart")
	if not (at and root) then return end
	for _, d in rig:GetDescendants() do
		if d:IsA("BasePart") then d.CanCollide = false d.CanQuery = false d.CanTouch = false end
	end
	root.Anchored = true
	root.CFrame = at.CFrame
	-- (welded into a moving car the Humanoid thinks it's falling, and FallingDown stops its animations)
	local hum = rig:FindFirstChildOfClass("Humanoid")
	if hum then hum.EvaluateStateMachine = false end
	rig.Parent = limo
end

-- the rear door on `side` swings out on its front hinge (open) or shut, over `secs` (0: at once)
local TweenService = game:GetService("TweenService")
local SWING = math.rad(65)
function Limo.door(limo, side, open, secs)
	local pivot = limo:GetPivot()
	local hinge = CFrame.new(-1, 0, side * 4) -- (the door's front edge, from the pivot)
	local swing = hinge * CFrame.Angles(0, side * SWING, 0) * hinge:Inverse()
	for _, d in limo:GetChildren() do
		local rel = d.Name == "Door" and d:GetAttribute("DoorSide") == side and d:GetAttribute("ClosedRel")
		if rel then
			local cf = pivot * (open and swing * rel or rel)
			if secs and secs > 0 then
				TweenService:Create(d, TweenInfo.new(secs, Enum.EasingStyle.Quad), { CFrame = cf }):Play()
			else
				d.CFrame = cf
			end
		end
	end
end

-- one welded car (the server moves it every frame: ~110 anchored parts sent ~110 CFrames a frame to
-- everyone; welded, it's one). Riders already seated come along.
function Limo.weld(limo)
	local floor = limo.PrimaryPart
	for _, d in limo:GetDescendants() do
		if d:IsA("BasePart") and d ~= floor and d.Anchored then
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = floor, d
			w.Parent = d
			d.Anchored = false
		end
	end
	floor.Anchored = true
	limo:SetAttribute("Welded", true)
end

-- put the pivot at cf (a welded limo in the world moves its floor; the rest follows). Out of the
-- world welds don't hold, so every part is moved: moving only the floor there, the welds then took hold
-- at the wrong offset and Vex, Crumpet and the caged kid rode 50 studs from the car.
function Limo.moveTo(limo, cf)
	local floor = limo.PrimaryPart
	if limo:GetAttribute("Welded") and floor and limo:IsDescendantOf(workspace) then
		floor.CFrame = cf * floor.PivotOffset:Inverse()
	else
		limo:PivotTo(cf)
	end
end

return Limo
