-- ServerScriptService.Server.StreetLayout
-- Recess Row as a real street. It used to be one 56-stud concrete strip with a red carpet down the
-- middle: the kids walked the carpet, buses, vans and limos drove on the same concrete, and at the
-- east end the kids nobody picked walked in through the doors of Detention, which stood across the
-- end of the street where the town's roads carry on ("why is there a red carpet with a road under
-- it", "why are the kids off the bus going to detention"). Built at runtime over the edit-time map
-- (tools/build_map.lua), before HallService reads the bus stop:
--   the road        two lanes down the middle (|z| < 12), where the town's connector roads meet it at
--                   x = +-400; double yellow centre line, white edge lines
--   the sidewalks   raised either side (|z| 12.8 .. 28), curbs; the kids walk here, past the gates
--   crosswalks      at every school gate (x = +-95, +-285), the Hub (0) and both ends
--   the bus stop    the school bus parks in the south lane by the shelter, door to the curb
--   the Home Bus    parked at the east end: kids nobody enrolled get on it and go home
--   Detention       moved off the street onto the empty lot north of the east connector road, facing it
local StreetLayout = {}

StreetLayout.X0, StreetLayout.X1 = -400, 400
StreetLayout.ROAD = 12 -- half width of the road
StreetLayout.WALK_IN, StreetLayout.WALK_OUT = 12.8, 27.9 -- the sidewalks
StreetLayout.WALK_TOP = 0.65
StreetLayout.LANE = 6 -- lane centre (|z|)
StreetLayout.CROSS_WEST, StreetLayout.CROSS_EAST = -318, 330 -- the crosswalks at the ends
StreetLayout.CROSSINGS = { -318, -285, -95, 0, 95, 285, 330 }
-- where kids walk along a sidewalk (|z|): clear of the lamps (22) and the gate arches (23)
StreetLayout.KID_MIN, StreetLayout.KID_MAX = 14.8, 19.2

local rgb = Color3.fromRGB
local ASPHALT = rgb(58, 60, 68)
local WALK = rgb(214, 214, 222)
local CURB = rgb(178, 178, 188)
local WHITE = rgb(242, 242, 242)
local YELLOW = rgb(255, 200, 40)

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
	for k, v in props or {} do p[k] = v end
	p.Parent = parent
	return p
end

local function sign(p, face, text, color, bg)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 16
	g.LightInfluence = 0
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = bg or WHITE
	t.BackgroundTransparency = bg and 0 or 1
	t.TextScaled = true
	t.Font = Enum.Font.LuckiestGuy
	t.Text = text
	t.TextColor3 = color
	t.Parent = g
	return t
end

local built = false
function StreetLayout.build()
	if built then return end
	built = true
	local map = workspace:WaitForChild("Map")
	for _, n in { "Carpet", "TrimN", "TrimS" } do
		local p = map:FindFirstChild(n)
		if p then p:Destroy() end
	end
	local st = Instance.new("Folder")
	st.Name = "Street"
	st.Parent = map
	local X0, X1 = StreetLayout.X0, StreetLayout.X1
	local W, cx = X1 - X0, (X0 + X1) / 2
	local R = StreetLayout.ROAD

	-- the road (over the old concrete, top at 0.5)
	part(st, "Road", Vector3.new(W, 0.1, R * 2), CFrame.new(cx, 0.45, 0), ASPHALT, Enum.Material.Asphalt)
	-- raised sidewalks and their curbs
	for _, s in { -1, 1 } do
		local zin, zout = StreetLayout.WALK_IN, StreetLayout.WALK_OUT
		part(st, "Sidewalk", Vector3.new(W, 0.25, zout - zin), CFrame.new(cx, 0.4 + 0.125, s * (zin + zout) / 2), WALK, Enum.Material.Concrete)
		part(st, "Curb", Vector3.new(W, 0.3, zin - R), CFrame.new(cx, 0.55, s * (R + zin) / 2), CURB, Enum.Material.Concrete)
		-- the white edge line along the kerb
		part(st, "EdgeLine", Vector3.new(W, 0.04, 0.3), CFrame.new(cx, 0.52, s * (R - 0.7)), WHITE, nil, { CanCollide = false })
		-- the double yellow line
		part(st, "CentreLine", Vector3.new(W, 0.04, 0.22), CFrame.new(cx, 0.52, s * 0.3), YELLOW, nil, { CanCollide = false })
	end
	-- crosswalks: white bars across the road, and dropped curbs (level with the road) either end
	for _, x in StreetLayout.CROSSINGS do
		local cw = Instance.new("Model")
		cw.Name = "Crosswalk"
		cw.Parent = st
		-- (the centre line is broken where the crossing is)
		for z = -R + 1.2, R - 1.2, 2.4 do
			part(cw, "Stripe", Vector3.new(5.2, 0.05, 1.3), CFrame.new(x, 0.525, z), WHITE, nil, { CanCollide = false })
		end
	end

	-- the bus stop: the regular bus (the map's parked one: every bus stops here) moves into the south
	-- lane, door to the curb by the shelter
	local bus = map:FindFirstChild("SchoolBus")
	local lane = StreetLayout.LANE
	if bus then
		local pv = bus:GetPivot()
		bus:PivotTo(CFrame.new(pv.Position.X, pv.Position.Y, -lane) * pv.Rotation)
		local mark = map:FindFirstChild("BusStop")
		if mark then mark.CFrame = CFrame.new(mark.Position.X, mark.Position.Y, -lane) end
		-- the Home Bus: a copy parked at the east end with its door open and HOME on its signs
		local home = bus:Clone()
		home.Name = "HomeBus"
		local hp = CFrame.new(362, pv.Position.Y, -lane) * pv.Rotation
		home:PivotTo(hp)
		for _, s in home:GetChildren() do
			if s.Name == "Sign" then
				for _, g in s:GetChildren() do
					if g:IsA("SurfaceGui") and g:FindFirstChild("Label") then g.Label.Text = "HOME BUS" end
				end
			end
		end
		local door
		for _, p in home:GetChildren() do
			if p:IsA("BasePart") and (p.Name == "Door" or p.Name == "DoorGlass") then
				if p.Name == "Door" then door = door or p.Position end
				p.CFrame += Vector3.new(-3.3, 0, -0.35) -- (slid open, as HallService opens them)
			end
		end
		home.Parent = map
		door = door or (hp.Position + Vector3.new(10, 0, -4))
		StreetLayout.HOME_DOOR = Vector3.new(door.X, 0, door.Z - 1.4)
		-- a stop sign on the curb
		local pole = part(st, "HomeStopPole", Vector3.new(0.3, 8, 0.3), CFrame.new(door.X + 4, 4.4, -(StreetLayout.WALK_IN + 0.8)), rgb(120, 125, 135), Enum.Material.Metal)
		local plate = part(st, "HomeStopSign", Vector3.new(0.2, 2.6, 4.2), CFrame.new(door.X + 4, 8.2, -(StreetLayout.WALK_IN + 0.8)), rgb(255, 255, 255))
		sign(plate, Enum.NormalId.Right, "\u{1F3E0} HOME BUS", rgb(40, 90, 200), rgb(255, 255, 255))
		sign(plate, Enum.NormalId.Left, "\u{1F3E0} HOME BUS", rgb(40, 90, 200), rgb(255, 255, 255))
		_ = pole
		-- the kids' walk ends at its door
		local path = map:FindFirstChild("HallPath")
		local e = path and path:FindFirstChild("End")
		if e then e.CFrame = CFrame.new(StreetLayout.HOME_DOOR + Vector3.new(0, 1, 0)) end
	end

	-- Detention: off the street, onto the lot north of the east connector road, its doors facing it
	local det = map:FindFirstChild("Detention")
	if det then
		local F0 = Vector3.new(350, 0, 0) -- (its front door, facing -X)
		local F1 = Vector3.new(440, 0, 26)
		local T = CFrame.new(F1) * CFrame.Angles(0, math.rad(-90), 0) * CFrame.new(-F0)
		det:PivotTo(T * det:GetPivot())
		-- a paved forecourt from the road to the door
		part(st, "DetentionForecourt", Vector3.new(16, 0.3, 14.5), CFrame.new(440, 0.25, 19), rgb(160, 158, 164), Enum.Material.Concrete)
	end
end

-- the walk to the Home Bus from a sidewalk position z (|z| on either side): along the sidewalk to the
-- east crosswalk, over it if need be, then to the door
function StreetLayout.homeRoute(z)
	local d = StreetLayout.HOME_DOOR or Vector3.new(372, 0, -11.4)
	return {
		Vector3.new(StreetLayout.CROSS_EAST, 0, z),
		Vector3.new(StreetLayout.CROSS_EAST, 0, d.Z),
		Vector3.new(d.X, 0, d.Z),
	}
end

-- a random place to walk on a sidewalk: side (+1 north, -1 south) and z
function StreetLayout.kidLane(side)
	side = side or (math.random() < 0.5 and -1 or 1)
	return side, side * (StreetLayout.KID_MIN + math.random() * (StreetLayout.KID_MAX - StreetLayout.KID_MIN))
end

return StreetLayout
