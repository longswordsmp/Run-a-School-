-- ServerScriptService.Server.TownPlayground
-- Recess Commons, the town playground on the west side of Recess Row (between the first two school
-- plots, x -222..-158, z 30..176). It replaces the box-built one baked into the place (a mulch pad,
-- two swings, a block tower, and a sign on posts right across the path at head height).
--   the gate      a picket fence all round, a brick arch with a rainbow over it and the name, the path
--                 under it (nothing across the way in), and a VexCorp notice somebody has corrected
--   the plaza     a round rubber pad with a drinking fountain, benches, bins, lamps and flower beds
--   swings        an A-frame set of three; two of the town's kids are swinging
--   play fort     two towers with pointed roofs and a rope bridge between them, a straight slide, a
--                 spiral slide round a pole, a climbing wall, a ladder, a fire pole, a steering wheel
--                 and a telescope
--   the rest      monkey bars, a merry-go-round (turning, a kid riding it), two see-saws (one going,
--                 a kid at each end), a sandbox with a sandcastle, bucket and spade (a kid building),
--                 a duck and a horse on springs (a kid on the horse)
-- Moving things are Models tagged for Decor.client: "Rock" (sways about its pivot's X or Z axis:
-- attributes Axis, Amp in degrees, Rate, Phase) and "Turn" (turns about its pivot's Y, SpinSpeed).
-- The kids are ordinary student rigs with no tag and no prompt, marked Ambient (Smooth.client leaves
-- them alone: they ride on what they're sitting on).
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.TownKit)
local Config = require(ReplicatedStorage.Shared.Config)

local TownPlayground = {}

local rgb = Kit.rgb
local part, wedge = Kit.part, Kit.wedge
local X0, X1, Z0, Z1 = -222, -158, 30, 176
local CX = -190
local G = 0 -- the ground's top (found when building)

local RED, ORANGE, YELLOW = rgb(230, 70, 60), rgb(250, 150, 40), rgb(255, 205, 50)
local GREEN, BLUE, PURPLE = rgb(80, 190, 90), rgb(60, 140, 235), rgb(150, 90, 220)
local STEEL = rgb(190, 194, 204)
local WOOD = rgb(160, 112, 66)
local rng = Random.new(2026)

local function at(x, y, z) return Vector3.new(x, G + y, z) end

-- a round bar from a to b
local function bar(parent, name, a, b, d, color, material)
	local len = (b - a).Magnitude
	local p = part(parent, name, Vector3.new(len, d, d), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0), color, material or Enum.Material.Metal)
	p.Shape = Enum.PartType.Cylinder
	return p
end
local function ballAt(parent, name, d, pos, color, material)
	return Kit.ball(parent, name, d, pos, color, material)
end
-- a disc lying flat (a cylinder stood on end)
local function disc(parent, name, d, h, pos, color, material)
	return Kit.cylY(parent, name, d, h, pos, color, material)
end
local function model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end
-- a moving thing: its pivot is the hinge (an invisible part); streamed in whole so the client's base
-- pivot is right
local function mover(parent, name, hinge, tag, attrs)
	local m = model(parent, name)
	local h = part(m, "Hinge", Vector3.new(0.2, 0.2, 0.2), hinge, rgb(0, 0, 0), nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	m.PrimaryPart = h
	for k, v in attrs do m:SetAttribute(k, v) end
	pcall(function() m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic end)
	CollectionService:AddTag(m, tag)
	return m
end

---------------------------------------------------------------------------
-- the kids who play here
---------------------------------------------------------------------------
local Factory
local KIDS = { "UntiedTyler", "DoodleDot", "LunchboxLucy", "PajamaPete", "HiccupHank", "JuiceBoxJake", "BubbleGumBetty", "PuddlePip" }
local nextKid = 0
local function kid(parent, cf, pose)
	Factory = Factory or require(script.Parent.StudentFactory)
	nextKid += 1
	local def = Config.StudentById[KIDS[(nextKid - 1) % #KIDS + 1]]
	if not def then return end
	local ok, m = pcall(Factory.build, def, "Normal")
	if not ok or not m then return end
	m.Name = "PlaygroundKid"
	m:SetAttribute("Ambient", true)
	m:SetAttribute("StudentId", nil)
	-- (a town kid: no price tag, no rarity glow)
	for _, d in m:GetDescendants() do
		if d:IsA("BillboardGui") or d:IsA("Highlight") or d:IsA("ParticleEmitter") then d:Destroy() end
	end
	local root = m.PrimaryPart
	root.CanQuery = false
	local hum = m:FindFirstChildOfClass("Humanoid")
	local up = pose == "sit" and (root.Size.Y * 0.5 + hum.HipHeight * 0.1) or Factory.standOffset(m)
	root.CFrame = cf * CFrame.new(0, up, 0)
	root.Anchored = true
	m.Parent = parent
	task.defer(function() if m.Parent then Factory.play(m, pose == "sit" and "sit" or "idle") end end)
	return m
end

---------------------------------------------------------------------------
-- the gate, the fence, the path, the plaza
---------------------------------------------------------------------------
local function buildGate(r)
	local g = model(r, "Gate")
	-- brick pillars either side of the path, a ball on each
	for _, s in { -1, 1 } do
		local x = CX + s * 8.6
		part(g, "Pillar", Vector3.new(2.4, 10, 2.4), CFrame.new(at(x, 5, 31)), rgb(190, 80, 60), Enum.Material.Brick)
		part(g, "PillarCap", Vector3.new(3, 0.6, 3), CFrame.new(at(x, 10.3, 31)), rgb(235, 230, 220), Enum.Material.Concrete)
		ballAt(g, "PillarBall", 1.6, at(x, 11.4, 31), s < 0 and BLUE or GREEN)
	end
	-- the rainbow: five bands of short segments in a half circle from pillar to pillar
	local bands = { RED, ORANGE, YELLOW, GREEN, BLUE }
	for i, c in bands do
		local rad = 9.6 - (i - 1) * 0.45
		local n = 18
		for k = 0, n - 1 do
			local a0, a1 = math.pi * k / n, math.pi * (k + 1) / n
			local p0 = at(CX + math.cos(a0) * rad, 10.6 + math.sin(a0) * rad * 0.62, 31)
			local p1 = at(CX + math.cos(a1) * rad, 10.6 + math.sin(a1) * rad * 0.62, 31)
			local len = (p1 - p0).Magnitude + 0.08
			part(g, "Rainbow", Vector3.new(len, 0.46, 0.7), CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.Angles(0, math.rad(90), 0), c, Enum.Material.SmoothPlastic, { CanCollide = false })
		end
	end
	-- the name on a board under the rainbow (bottom at 11: the way in stays clear)
	local board = part(g, "NameBoard", Vector3.new(13, 2.6, 0.5), CFrame.new(at(CX, 12.4, 31)), rgb(255, 250, 235))
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		Kit.sign(board, face, "RECESS COMMONS", rgb(60, 140, 235), nil, Enum.Font.LuckiestGuy, rgb(255, 255, 255))
	end
	for _, s in { -1, 1 } do
		bar(g, "BoardChain", at(CX + s * 5.5, 13.7, 31), at(CX + s * 5.5, 15.4, 31), 0.12, STEEL)
	end
	-- the fence: white pickets all round, the gap for the gate
	Kit.picket(r, X0, Z0, CX - 9.8, Z0)
	Kit.picket(r, CX + 9.8, Z0, X1, Z0)
	Kit.picket(r, X0, Z0, X0, Z1)
	Kit.picket(r, X1, Z0, X1, Z1)
	Kit.picket(r, X0, Z1, X1, Z1)
	-- VexCorp's notice on the fence by the gate, corrected in crayon
	local post = part(g, "NoticePost", Vector3.new(0.4, 5, 0.4), CFrame.new(at(CX - 14, 2.5, 31.4)), WOOD, Enum.Material.Wood)
	_ = post
	local notice = part(g, "Notice", Vector3.new(4.4, 3, 0.15), CFrame.new(at(CX - 14, 4.6, 31.2)) * CFrame.Angles(0, 0, math.rad(4)), rgb(245, 245, 250))
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50 -- (a small notice of close-set text: at 20 it was unreadable)
	gui.LightInfluence = 0.2
	gui.Parent = notice
	local head = Instance.new("TextLabel")
	head.BackgroundColor3 = rgb(92, 40, 132)
	head.Size = UDim2.new(1, 0, 0.26, 0)
	head.Font = Enum.Font.GothamBlack
	head.TextScaled = true
	head.TextColor3 = rgb(255, 255, 255)
	head.Text = "VEXCORP NOTICE"
	head.Parent = gui
	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromScale(0.05, 0.3)
	body.Size = UDim2.fromScale(0.9, 0.62)
	body.Font = Enum.Font.Gotham
	body.TextScaled = true
	body.TextColor3 = rgb(40, 40, 50)
	body.Text = "RECESS IS CANCELLED.\nThis playground will become\na Homework Zone.\n- Dr. V. Vex"
	body.Parent = gui
	local crayon = Instance.new("TextLabel")
	crayon.BackgroundTransparency = 1
	crayon.Position = UDim2.fromScale(0.08, 0.32)
	crayon.Size = UDim2.fromScale(0.85, 0.5)
	crayon.Rotation = -14
	crayon.Font = Enum.Font.PermanentMarker
	crayon.TextScaled = true
	crayon.TextColor3 = rgb(230, 40, 50)
	crayon.Text = "NOT HERE!!"
	crayon.ZIndex = 2
	crayon.Parent = gui
end

local function buildGrounds(r)
	local rubber = rgb(214, 118, 92)
	-- the path in from the street, and the plaza
	part(r, "PathIn", Vector3.new(7, 0.3, 30), CFrame.new(at(CX, 0.15, 44)), rubber, Enum.Material.Rubber)
	disc(r, "PlazaRim", 24, 0.32, at(CX, 0.16, 70), rgb(200, 190, 175), Enum.Material.Brick)
	disc(r, "Plaza", 22.4, 0.36, at(CX, 0.18, 70), rubber, Enum.Material.Rubber)
	-- paths from the plaza to each corner of play
	local function path(x0, z0, x1, z1)
		local a, b = at(x0, 0.15, z0), at(x1, 0.15, z1)
		part(r, "Path", Vector3.new(5, 0.3, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), rubber, Enum.Material.Rubber)
	end
	path(CX - 9, 76, -205, 90)
	path(CX + 9, 76, -178, 83)
	path(CX, 81, CX, 119)
	path(CX - 4, 128, -202, 140)
	path(CX + 4, 128, -176, 134)
	-- safety surfaces under the equipment
	part(r, "SwingRubber", Vector3.new(26, 0.3, 16), CFrame.new(at(-208, 0.15, 98)), rgb(70, 120, 200), Enum.Material.Rubber)
	part(r, "FortChips", Vector3.new(32, 0.32, 36), CFrame.new(at(-174, 0.16, 99)), rgb(170, 110, 70), Enum.Material.Sand)
	part(r, "BarsRubber", Vector3.new(20, 0.3, 9), CFrame.new(at(CX, 0.15, 124)), rgb(210, 70, 70), Enum.Material.Rubber)
	disc(r, "MerryRubber", 16, 0.3, at(-208, 0.15, 136), rgb(80, 170, 90), Enum.Material.Rubber)
	part(r, "SeesawRubber", Vector3.new(18, 0.3, 16), CFrame.new(at(-208, 0.15, 158)), rgb(240, 150, 60), Enum.Material.Rubber)
	part(r, "RiderRubber", Vector3.new(18, 0.3, 9), CFrame.new(at(-172, 0.15, 161)), rgb(150, 100, 210), Enum.Material.Rubber)
	-- the plaza: a drinking fountain in the middle, benches round it, bins, lamps, flowers
	disc(r, "FountainBase", 2.2, 0.4, at(CX, 0.5, 70), rgb(160, 160, 168), Enum.Material.Concrete)
	part(r, "FountainPillar", Vector3.new(1.2, 3, 1.2), CFrame.new(at(CX, 2, 70)), rgb(80, 150, 220), Enum.Material.SmoothPlastic)
	disc(r, "FountainBowl", 2.2, 0.5, at(CX, 3.6, 70), STEEL, Enum.Material.Metal)
	disc(r, "FountainWater", 1.7, 0.1, at(CX, 3.86, 70), rgb(120, 190, 240), Enum.Material.Glass).Transparency = 0.3
	bar(r, "FountainSpout", at(CX, 3.8, 70.4), at(CX, 4.3, 70.1), 0.18, STEEL)
	for _, spec in { { CX - 13, 70, "+x" }, { CX + 13, 70, "-x" }, { CX - 7, 60.5, "+z" }, { CX + 7, 60.5, "+z" } } do
		Kit.bench(r, spec[1], spec[2], spec[3])
	end
	for _, pos in { { CX - 5.5, 58.5 }, { CX + 12, 77 } } do
		local bin = Kit.cylY(r, "Bin", 1.6, 2.6, at(pos[1], 1.3, pos[2]), GREEN, Enum.Material.Metal)
		_ = bin
		Kit.cylY(r, "BinLid", 1.8, 0.25, at(pos[1], 2.7, pos[2]), rgb(40, 110, 60), Enum.Material.Metal)
	end
	for _, pos in { { CX - 6, 36 }, { CX + 6, 36 }, { CX - 12, 82 }, { CX + 12, 82 }, { CX - 6, 150 }, { CX + 6, 150 } } do
		Kit.lamp(r, pos[1], pos[2], 10)
	end
	Kit.flowerBed(r, CX - 12, 40, 8, 4, { RED, YELLOW, PURPLE })
	Kit.flowerBed(r, CX + 12, 40, 8, 4, { ORANGE, BLUE, RED })
	-- the playground rules
	local rules = part(r, "RulesBoard", Vector3.new(5, 3.4, 0.3), CFrame.new(at(CX + 6, 3.6, 57)) * CFrame.Angles(0, math.rad(180), 0), rgb(60, 140, 90))
	Kit.sign(rules, Enum.NormalId.Front, "PLAYGROUND RULES\n1. Take turns\n2. Feet first down the slide\n3. HAVE FUN", rgb(255, 255, 255), nil, Enum.Font.FredokaOne)
	for _, dx in { -2, 2 } do part(r, "RulesPost", Vector3.new(0.3, 2, 0.3), CFrame.new(at(CX + 6 + dx, 1, 57)), WOOD, Enum.Material.Wood) end
	-- trees round the edge and bushes along the fence
	for _, pos in { { -216, 40 }, { -164, 40 }, { -216, 70 }, { -164, 70 }, { -217, 118 }, { -163, 125 }, { -216, 170 }, { -164, 172 }, { CX, 168 }, { -200, 172 } } do
		Kit.tree(r, pos[1], pos[2], 0.9 + rng:NextNumber() * 0.25)
	end
	for z = 50, 165, 13 do
		Kit.bush(r, X0 + 2.2, z, 0.8)
		Kit.bush(r, X1 - 2.2, z + 6, 0.8)
	end
end

---------------------------------------------------------------------------
-- swings: an A-frame set of three along x at z 98, swinging along z
---------------------------------------------------------------------------
local function buildSwings(r)
	local s = model(r, "Swings")
	local z, top = 98, 11
	local xA, xB = -219, -197
	bar(s, "TopBar", at(xA - 0.4, top, z), at(xB + 0.4, top, z), 0.7, RED)
	for _, x in { xA, xB } do
		for _, dz in { -4.6, 4.6 } do
			bar(s, "Leg", at(x, top, z), at(x, 0.3, z + dz), 0.6, RED)
			part(s, "Foot", Vector3.new(1, 0.4, 1), CFrame.new(at(x, 0.35, z + dz)), rgb(90, 90, 100), Enum.Material.Metal)
		end
		bar(s, "Brace", at(x, 4, z - 2.9), at(x, 4, z + 2.9), 0.35, RED)
		ballAt(s, "Cap", 1.1, at(x, top, z), YELLOW)
	end
	local colors = { YELLOW, BLUE, GREEN }
	for i, x in { -214, -208, -202 } do
		local hinge = CFrame.new(at(x, top - 0.35, z))
		local sw = mover(s, "Swing", hinge, "Rock", { Axis = "X", Amp = i == 2 and 4 or 24, Rate = 2.2 + i * 0.13, Phase = i * 1.7 })
		for _, dx in { -0.95, 0.95 } do
			bar(sw, "Hanger", at(x + dx, top - 0.1, z), at(x + dx, top - 0.6, z), 0.25, STEEL)
			-- the chain: short links, alternating flat and edge-on
			local y0, y1 = top - 0.6, 3.5
			local n = 16
			for k = 0, n - 1 do
				local ya = y0 - (y0 - y1) * k / n
				local yb = y0 - (y0 - y1) * (k + 1) / n
				local link = part(sw, "Link", Vector3.new(0.12, (ya - yb) + 0.08, k % 2 == 0 and 0.22 or 0.1), CFrame.new(at(x + dx, (ya + yb) / 2, z)), rgb(150, 152, 160), Enum.Material.Metal, { CanCollide = false })
				_ = link
			end
		end
		-- a rubber strap seat, sagging in the middle
		part(sw, "Seat", Vector3.new(1.2, 0.22, 1.1), CFrame.new(at(x, 3.25, z)), colors[i], Enum.Material.Rubber)
		for _, dx in { -1, 1 } do
			part(sw, "Seat", Vector3.new(0.75, 0.22, 1.1), CFrame.new(at(x + dx * 0.9, 3.38, z)) * CFrame.Angles(0, 0, math.rad(dx * 14)), colors[i], Enum.Material.Rubber)
		end
		-- two of the three are taken
		if i ~= 2 then kid(sw, CFrame.new(at(x, 3.36, z)) * CFrame.Angles(0, math.rad(i == 1 and 180 or 0), 0), "sit") end
	end
end

---------------------------------------------------------------------------
-- the play fort: two towers and a bridge, slides, a climbing wall, a fire pole
---------------------------------------------------------------------------
local function roof(parent, x, y, z, w, color)
	-- a pointed roof: four wedges sloping down to the four sides
	local h = w * 0.45
	for _, down in { "-z", "+z", "-x", "+x" } do
		local off = ({ ["-z"] = Vector3.new(0, 0, -w / 4), ["+z"] = Vector3.new(0, 0, w / 4), ["-x"] = Vector3.new(-w / 4, 0, 0), ["+x"] = Vector3.new(w / 4, 0, 0) })[down]
		wedge(parent, "Roof", Vector3.new(w, h, w / 2), at(x, y + h / 2, z) + off, down, color)
	end
	ballAt(parent, "RoofBall", 0.8, at(x, y + h + 0.3, z), YELLOW)
end
local function tower(f, name, x, z, deck, colors, open)
	-- open: which sides have no rail ("n", "s", "e", "w")
	local t = model(f, name)
	local w = 6
	for _, dx in { -1, 1 } do
		for _, dz in { -1, 1 } do
			part(t, "Post", Vector3.new(0.7, deck + 5.2, 0.7), CFrame.new(at(x + dx * (w / 2 - 0.35), (deck + 5.2) / 2, z + dz * (w / 2 - 0.35))), colors.post, Enum.Material.Metal)
		end
	end
	part(t, "Deck", Vector3.new(w, 0.4, w), CFrame.new(at(x, deck - 0.2, z)), colors.deck, Enum.Material.DiamondPlate)
	local sides = {
		n = { cf = CFrame.new(at(x, deck + 1.4, z + w / 2 - 0.2)), size = Vector3.new(w - 1.4, 2.4, 0.25) },
		s = { cf = CFrame.new(at(x, deck + 1.4, z - w / 2 + 0.2)), size = Vector3.new(w - 1.4, 2.4, 0.25) },
		e = { cf = CFrame.new(at(x + w / 2 - 0.2, deck + 1.4, z)), size = Vector3.new(0.25, 2.4, w - 1.4) },
		w = { cf = CFrame.new(at(x - w / 2 + 0.2, deck + 1.4, z)), size = Vector3.new(0.25, 2.4, w - 1.4) },
	}
	for key, sd in sides do
		if open[key] then
			-- an opening (a slide, the bridge, a ladder): a short rail either side of a 2.6 gap
			local along = sd.size.X > sd.size.Z
			local stub = (w - 1.4 - 2.6) / 2
			for _, s in { -1, 1 } do
				local off = s * (1.3 + stub / 2)
				part(t, "Rail", along and Vector3.new(stub, 2.4, 0.25) or Vector3.new(0.25, 2.4, stub), sd.cf * CFrame.new(along and off or 0, 0, along and 0 or off), colors.panel, Enum.Material.SmoothPlastic)
			end
		else
			part(t, "Panel", sd.size, sd.cf, colors.panel, Enum.Material.SmoothPlastic)
			-- a round window in the panel
			local win = part(t, "PanelWindow", sd.size.X > sd.size.Z and Vector3.new(1.4, 1.4, 0.3) or Vector3.new(0.3, 1.4, 1.4), sd.cf, rgb(40, 40, 50), nil, { CanCollide = false })
			win.Shape = Enum.PartType.Cylinder
			win.Size = Vector3.new(0.3, 1.4, 1.4)
			win.CFrame = sd.cf * (sd.size.X > sd.size.Z and CFrame.Angles(0, math.rad(90), 0) or CFrame.new())
			win.Transparency = 0.2
		end
	end
	-- a canopy frame under the roof
	for _, dz in { -1, 1 } do
		part(t, "RoofBeam", Vector3.new(w, 0.4, 0.4), CFrame.new(at(x, deck + 5.2, z + dz * (w / 2 - 0.35))), colors.post, Enum.Material.Metal)
	end
	roof(t, x, deck + 5.4, z, w + 0.8, colors.roof)
	return t
end
local function buildFort(r)
	local f = model(r, "PlayFort")
	local ax, az, adeck = -182, 96, 5
	local bx, bz, bdeck = -166, 96, 6.5
	-- (tower A opens north onto the slide, east onto the bridge, west onto the ladder, south onto the
	-- climbing wall; tower B west onto the bridge, south onto the spiral, east onto the fire pole)
	tower(f, "TowerA", ax, az, adeck, { post = RED, deck = rgb(200, 200, 210), panel = YELLOW, roof = BLUE }, { e = true, n = true, w = true, s = true })
	tower(f, "TowerB", bx, bz, bdeck, { post = BLUE, deck = rgb(200, 200, 210), panel = GREEN, roof = RED }, { w = true, s = true, e = true })
	-- the bridge from A to B: slats on two ropes, rope rails with posts
	local x0, x1 = ax + 3, bx - 3
	local n = 9
	for k = 0, n - 1 do
		local t = (k + 0.5) / n
		local x = x0 + (x1 - x0) * t
		local y = adeck + (bdeck - adeck) * t - math.sin(t * math.pi) * 0.45
		part(f, "Slat", Vector3.new((x1 - x0) / n - 0.15, 0.25, 3.6), CFrame.new(at(x, y - 0.12, az)), WOOD, Enum.Material.WoodPlanks)
	end
	for _, dz in { -1.9, 1.9 } do
		for k = 0, n - 1 do
			local ta, tb = k / n, (k + 1) / n
			local ya = adeck + (bdeck - adeck) * ta - math.sin(ta * math.pi) * 0.45
			local yb = adeck + (bdeck - adeck) * tb - math.sin(tb * math.pi) * 0.45
			bar(f, "Rope", at(x0 + (x1 - x0) * ta, ya + 2.2, az + dz), at(x0 + (x1 - x0) * tb, yb + 2.2, az + dz), 0.16, rgb(200, 170, 110), Enum.Material.Fabric)
			bar(f, "Rope", at(x0 + (x1 - x0) * ta, ya - 0.2, az + dz), at(x0 + (x1 - x0) * tb, yb - 0.2, az + dz), 0.16, rgb(200, 170, 110), Enum.Material.Fabric)
			if k % 2 == 0 then bar(f, "Rope", at(x0 + (x1 - x0) * ta, ya - 0.2, az + dz), at(x0 + (x1 - x0) * ta, ya + 2.2, az + dz), 0.1, rgb(200, 170, 110), Enum.Material.Fabric) end
		end
	end
	-- the straight slide off A to the north, with side rails and a run-out
	local top, bottomZ = at(ax, adeck + 0.05, az + 3), az + 12.5
	local bottom = at(ax, 0.7, bottomZ)
	local len = (bottom - top).Magnitude
	local slide = part(f, "Slide", Vector3.new(2.6, 0.3, len), CFrame.lookAt((top + bottom) / 2, bottom), YELLOW, Enum.Material.SmoothPlastic)
	for _, dx in { -1.4, 1.4 } do
		part(f, "SlideSide", Vector3.new(0.25, 0.8, len), slide.CFrame * CFrame.new(dx, 0.4, 0), YELLOW, Enum.Material.SmoothPlastic)
	end
	part(f, "SlideRunout", Vector3.new(2.6, 0.3, 2.4), CFrame.new(at(ax, 0.6, bottomZ + 1.1)), YELLOW)
	for _, dx in { -1.4, 1.4 } do
		part(f, "SlideRunoutSide", Vector3.new(0.25, 0.7, 2.4), CFrame.new(at(ax + dx, 0.95, bottomZ + 1.1)), YELLOW)
		bar(f, "SlideHandle", at(ax + dx, adeck, az + 3), at(ax + dx, adeck + 2.2, az + 3), 0.25, RED)
	end
	-- the spiral slide round a pole south of B: 1.25 turns from the deck to the ground
	local c = Vector3.new(bx, 0, bz - 6)
	local rad, turns, segs = 2.6, 1.25, 18
	disc(f, "SpiralPole", 0.8, bdeck + 3, at(c.X, (bdeck + 3) / 2, c.Z), STEEL, Enum.Material.Metal)
	local y0, y1 = bdeck, 0.9
	local da = turns * math.pi * 2 / segs
	for k = 0, segs - 1 do
		local a = (k + 0.5) * da
		local y = y0 - (y0 - y1) * (k + 0.5) / segs
		local pos = at(c.X + math.sin(a) * rad, y, c.Z + math.cos(a) * rad)
		local tangent = Vector3.new(math.cos(a) * rad * da, -(y0 - y1) / segs, -math.sin(a) * rad * da)
		local seg = part(f, "Spiral", Vector3.new(2.3, 0.3, tangent.Magnitude + 0.2), CFrame.lookAt(pos, pos + tangent), ORANGE, Enum.Material.SmoothPlastic)
		part(f, "SpiralRail", Vector3.new(0.25, 0.9, tangent.Magnitude + 0.2), seg.CFrame * CFrame.new(1.2, 0.45, 0), ORANGE)
	end
	-- the climbing wall on A's south face, holds in all colours
	-- (leaning in against the deck's edge: +14 degrees tips its top towards the tower)
	local wall = part(f, "ClimbWall", Vector3.new(2.4, 5.6, 0.4), CFrame.new(at(ax, 2.5, az - 3.9)) * CFrame.Angles(math.rad(14), 0, 0), rgb(245, 245, 240), Enum.Material.SmoothPlastic)
	local holdColors = { RED, YELLOW, GREEN, BLUE, PURPLE, ORANGE }
	for k = 1, 12 do
		local hx = rng:NextNumber(-0.9, 0.9)
		local hy = rng:NextNumber(-2.4, 2.4)
		local h = part(f, "Hold", Vector3.new(0.5, 0.4, 0.35), wall.CFrame * CFrame.new(hx, hy, -0.3) * CFrame.Angles(0, 0, rng:NextNumber(0, 6)), holdColors[k % #holdColors + 1])
		_ = h
	end
	-- the ladder up A's west side
	for _, dz in { -1, 1 } do bar(f, "LadderRail", at(ax - 3.4, 0.2, az + dz), at(ax - 3.1, adeck + 2, az + dz), 0.3, RED) end
	for k = 1, 5 do
		local y = k * (adeck / 5.5)
		bar(f, "Rung", at(ax - 3.4 + y * 0.044, y, az - 1), at(ax - 3.4 + y * 0.044, y, az + 1), 0.22, STEEL)
	end
	-- the fire pole off B's east side, a steering wheel on B's rail, a telescope on A
	disc(f, "FirePole", 0.35, bdeck + 3.5, at(bx + 4.4, (bdeck + 3.5) / 2, bz + 1.5), STEEL, Enum.Material.Metal)
	bar(f, "PoleArm", at(bx + 3, bdeck + 3.4, bz + 1.5), at(bx + 4.45, bdeck + 3.4, bz + 1.5), 0.35, STEEL)
	local wheel = Kit.cylZ(f, "Wheel", 1.6, 0.2, at(bx, bdeck + 2.2, bz + 2.7), rgb(40, 40, 46), Enum.Material.SmoothPlastic)
	_ = wheel
	for k = 0, 2 do
		local a = k * math.pi / 3
		bar(f, "Spoke", at(bx - math.cos(a) * 0.75, bdeck + 2.2 - math.sin(a) * 0.75, bz + 2.6), at(bx + math.cos(a) * 0.75, bdeck + 2.2 + math.sin(a) * 0.75, bz + 2.6), 0.12, YELLOW)
	end
	bar(f, "Telescope", at(ax + 1.8, adeck + 2.3, az + 2.6), at(ax + 1.3, adeck + 2.9, az + 3.9), 0.35, PURPLE)
	-- a kid at the top of the straight slide, about to go (facing down it, north)
	kid(f, CFrame.new(at(ax, adeck + 0.05, az + 2.3)) * CFrame.Angles(0, math.rad(180), 0), "sit")
end

---------------------------------------------------------------------------
-- monkey bars, merry-go-round, see-saws, sandbox, spring riders
---------------------------------------------------------------------------
local function buildRest(r)
	-- monkey bars: a ladder at each end and rungs across the top
	local mb = model(r, "MonkeyBars")
	local xa, xb, z, h = CX - 8, CX + 8, 124, 7
	for _, x in { xa, xb } do
		for _, dz in { -1.1, 1.1 } do bar(mb, "Upright", at(x, 0.2, z + dz), at(x, h, z + dz), 0.35, GREEN) end
		for k = 1, 4 do bar(mb, "Step", at(x, k * 1.5, z - 1.1), at(x, k * 1.5, z + 1.1), 0.22, STEEL) end
	end
	for _, dz in { -1.1, 1.1 } do bar(mb, "TopRail", at(xa, h, z + dz), at(xb, h, z + dz), 0.35, GREEN) end
	for x = xa + 1.2, xb - 1.2, 1.2 do bar(mb, "Bar", at(x, h, z - 1.1), at(x, h, z + 1.1), 0.2, STEEL) end

	-- the merry-go-round: a turning deck in six colours, handrails, a centre hub (a kid on it)
	local cx, cz = -208, 136
	local mg = mover(r, "MerryGoRound", CFrame.new(at(cx, 0.9, cz)), "Turn", { SpinSpeed = 0.7 })
	disc(r, "MerryBase", 2.4, 0.9, at(cx, 0.45, cz), rgb(90, 90, 100), Enum.Material.Metal)
	disc(mg, "Deck", 10, 0.3, at(cx, 1.05, cz), rgb(200, 200, 210), Enum.Material.DiamondPlate)
	local segColors = { RED, YELLOW, BLUE, GREEN, ORANGE, PURPLE }
	for k = 0, 5 do
		local a = k * math.pi / 3 + math.pi / 6
		part(mg, "Stripe", Vector3.new(0.9, 0.08, 4.2), CFrame.new(at(cx + math.sin(a) * 2.6, 1.23, cz + math.cos(a) * 2.6)) * CFrame.Angles(0, a, 0), segColors[k + 1])
		local ra = k * math.pi / 3
		local outer = at(cx + math.sin(ra) * 4.5, 1.2, cz + math.cos(ra) * 4.5)
		local inner = at(cx + math.sin(ra) * 1, 3.1, cz + math.cos(ra) * 1)
		bar(mg, "Handrail", outer, outer + Vector3.new(0, 1.8, 0), 0.25, STEEL)
		bar(mg, "Handrail", outer + Vector3.new(0, 1.8, 0), inner, 0.25, STEEL)
	end
	disc(mg, "Hub", 2, 2.2, at(cx, 2.2, cz), RED, Enum.Material.SmoothPlastic)
	disc(mg, "HubCap", 2.3, 0.3, at(cx, 3.4, cz), YELLOW, Enum.Material.SmoothPlastic)
	kid(mg, CFrame.new(at(cx + 3.3, 1.2, cz)) * CFrame.Angles(0, math.rad(90), 0), "sit")

	-- two see-saws along x, rocking about z (the near one going, a kid at each end)
	for i, sz in { 153, 163 } do
		local sx = -208
		disc(r, "SeesawBase", 1.6, 0.5, at(sx, 0.4, sz), rgb(90, 90, 100), Enum.Material.Metal)
		for _, dz in { -0.6, 0.6 } do
			wedge(r, "SeesawStand", Vector3.new(0.4, 1.7, 1), at(sx - 0.5, 1.2, sz + dz), "-x", rgb(90, 90, 100), Enum.Material.Metal)
			wedge(r, "SeesawStand", Vector3.new(0.4, 1.7, 1), at(sx + 0.5, 1.2, sz + dz), "+x", rgb(90, 90, 100), Enum.Material.Metal)
		end
		local ss = mover(r, "Seesaw", CFrame.new(at(sx, 2.2, sz)), "Rock", { Axis = "Z", Amp = i == 1 and 13 or 0, Rate = 1.7, Phase = 0 })
		Kit.cylZ(ss, "Axle", 0.5, 1.8, at(sx, 2.2, sz), STEEL, Enum.Material.Metal)
		part(ss, "Plank", Vector3.new(13, 0.35, 1.1), CFrame.new(at(sx, 2.4, sz)), i == 1 and ORANGE or BLUE)
		for _, dx in { -1, 1 } do
			part(ss, "SeesawSeat", Vector3.new(1.6, 0.25, 1.3), CFrame.new(at(sx + dx * 5.7, 2.65, sz)), rgb(40, 40, 46), Enum.Material.Rubber)
			bar(ss, "Handle", at(sx + dx * 4.5, 2.6, sz), at(sx + dx * 4.5, 3.8, sz), 0.2, STEEL)
			bar(ss, "Handle", at(sx + dx * 4.5, 3.8, sz - 0.5), at(sx + dx * 4.5, 3.8, sz + 0.5), 0.2, STEEL)
			if i == 1 then kid(ss, CFrame.new(at(sx + dx * 5.7, 2.78, sz)) * CFrame.Angles(0, math.rad(dx > 0 and 90 or -90), 0), "sit") end
		end
		-- (a still see-saw rests one end down)
		if i == 2 then ss:PivotTo(ss:GetPivot() * CFrame.Angles(0, 0, math.rad(11))) end
	end

	-- the sandbox: a wooden frame with corner seats, a sandcastle, a bucket and spade, a kid digging
	local sb = model(r, "Sandbox")
	local bx, bz = -172, 140
	for _, spec in { { 0, -5.6, 12, 0.8 }, { 0, 5.6, 12, 0.8 }, { -5.6, 0, 0.8, 12 }, { 5.6, 0, 0.8, 12 } } do
		part(sb, "Frame", Vector3.new(spec[3], 1.2, spec[4]), CFrame.new(at(bx + spec[1], 0.6, bz + spec[2])), WOOD, Enum.Material.WoodPlanks)
	end
	part(sb, "Sand", Vector3.new(10.4, 0.8, 10.4), CFrame.new(at(bx, 0.45, bz)), rgb(240, 222, 160), Enum.Material.Sand)
	for _, c in { { -1, -1 }, { 1, 1 } } do
		wedge(sb, "CornerSeat", Vector3.new(2.4, 0.3, 2.4), at(bx + c[1] * 4.6, 1.3, bz + c[2] * 4.6), "+z", WOOD)
	end
	local castle = at(bx + 1.8, 0.85, bz + 1.5)
	part(sb, "CastleBase", Vector3.new(2.6, 0.8, 2.6), CFrame.new(castle + Vector3.new(0, 0.4, 0)), rgb(225, 200, 140), Enum.Material.Sand)
	for _, o in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		Kit.cylY(sb, "CastleTower", 0.8, 1.4, castle + Vector3.new(o[1] * 1.2, 0.9, o[2] * 1.2), rgb(225, 200, 140), Enum.Material.Sand)
		Kit.cylY(sb, "CastleTop", 1, 0.25, castle + Vector3.new(o[1] * 1.2, 1.7, o[2] * 1.2), rgb(215, 190, 130), Enum.Material.Sand)
	end
	part(sb, "CastleFlagPole", Vector3.new(0.08, 1.4, 0.08), CFrame.new(castle + Vector3.new(0, 1.5, 0)), WOOD)
	part(sb, "CastleFlag", Vector3.new(0.05, 0.4, 0.6), CFrame.new(castle + Vector3.new(0, 2, 0.3)), RED)
	Kit.cylY(sb, "Bucket", 0.9, 0.9, at(bx - 2.5, 1.3, bz + 2.4), BLUE, Enum.Material.SmoothPlastic)
	bar(sb, "BucketHandle", at(bx - 2.95, 1.9, bz + 2.4), at(bx - 2.05, 1.9, bz + 2.4), 0.06, STEEL)
	bar(sb, "Spade", at(bx - 1.5, 0.9, bz - 2), at(bx - 0.5, 2, bz - 2.5), 0.14, YELLOW)
	part(sb, "SpadeBlade", Vector3.new(0.5, 0.05, 0.6), CFrame.new(at(bx - 1.6, 0.9, bz - 1.95)), RED)
	kid(sb, CFrame.new(at(bx - 0.4, 0.85, bz + 0.6)) * CFrame.Angles(0, math.rad(-40), 0), "sit")

	-- spring riders: a duck and a horse (a kid on the horse)
	local function rider(x, z, build, withKid)
		part(r, "RiderBase", Vector3.new(1.4, 0.3, 1.4), CFrame.new(at(x, 0.45, z)), rgb(90, 90, 100), Enum.Material.Metal)
		local rd = mover(r, "SpringRider", CFrame.new(at(x, 0.6, z)), "Rock", { Axis = "X", Amp = withKid and 9 or 0, Rate = 3.1, Phase = x })
		for k = 0, 5 do
			local coil = Kit.cylY(rd, "Coil", 1.1, 0.18, at(x, 0.8 + k * 0.33, z), rgb(200, 60, 60), Enum.Material.Metal)
			coil.CFrame = coil.CFrame * CFrame.Angles(math.rad(k % 2 == 0 and 6 or -6), 0, 0)
		end
		build(rd, at(x, 2.9, z))
		-- (on the saddle, facing the head at -z)
		if withKid then kid(rd, CFrame.new(at(x, 3.65, z + 0.2)), "sit") end
	end
	rider(-178, 161, function(m, p)
		ballAt(m, "DuckBody", 2.2, p, YELLOW)
		ballAt(m, "DuckHead", 1.3, p + Vector3.new(0, 1.3, -1), YELLOW)
		part(m, "DuckBeak", Vector3.new(0.6, 0.25, 0.7), CFrame.new(p + Vector3.new(0, 1.2, -1.75)), ORANGE)
		for _, dx in { -0.4, 0.4 } do ballAt(m, "DuckEye", 0.22, p + Vector3.new(dx, 1.5, -1.55), rgb(20, 20, 20)) end
		bar(m, "DuckHandle", p + Vector3.new(-0.6, 1.4, -0.4), p + Vector3.new(0.6, 1.4, -0.4), 0.15, STEEL)
	end, false)
	rider(-166, 161, function(m, p)
		local brown = rgb(150, 90, 50)
		part(m, "HorseBody", Vector3.new(1.2, 1.2, 2.6), CFrame.new(p), brown)
		part(m, "HorseNeck", Vector3.new(0.9, 1.6, 0.9), CFrame.new(p + Vector3.new(0, 1, -1.2)) * CFrame.Angles(math.rad(-25), 0, 0), brown)
		part(m, "HorseHead", Vector3.new(0.9, 0.9, 1.5), CFrame.new(p + Vector3.new(0, 1.8, -1.9)), brown)
		part(m, "HorseMane", Vector3.new(0.3, 1.5, 0.5), CFrame.new(p + Vector3.new(0, 1.4, -1)) * CFrame.Angles(math.rad(-25), 0, 0), rgb(60, 35, 20))
		part(m, "HorseTail", Vector3.new(0.3, 1.2, 0.3), CFrame.new(p + Vector3.new(0, 0.1, 1.5)) * CFrame.Angles(math.rad(30), 0, 0), rgb(60, 35, 20))
		part(m, "HorseSaddle", Vector3.new(1.3, 0.2, 1.1), CFrame.new(p + Vector3.new(0, 0.65, 0.2)), RED)
		for _, dx in { -0.3, 0.3 } do ballAt(m, "HorseEye", 0.2, p + Vector3.new(dx * 1.5, 2, -2.4), rgb(20, 20, 20)) end
		bar(m, "HorseHandle", p + Vector3.new(-0.6, 1.8, -1.3), p + Vector3.new(0.6, 1.8, -1.3), 0.15, STEEL)
	end, true)
end

---------------------------------------------------------------------------
function TownPlayground.build()
	local map = workspace:FindFirstChild("Map")
	local lm = map and map:FindFirstChild("Landmarks")
	if not lm then return end
	-- the ground's top here
	local ground = map:FindFirstChild("Ground")
	if ground then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { ground }
		local hit = workspace:Raycast(Vector3.new(CX, 60, 100), Vector3.new(0, -120, 0), params)
		if hit then G = hit.Position.Y end
	end
	-- out with the old one, its path and any map trees on the lot
	local old = lm:FindFirstChild("RecessCommons")
	if old then old:Destroy() end
	for _, c in lm:GetChildren() do
		if c.Name == "Path" and c:IsA("BasePart") and math.abs(c.Position.X - CX) < 2 and c.Position.Z > 26 and c.Position.Z < 64 then c:Destroy() end
	end
	local deco = map:FindFirstChild("Deco")
	for _, m in deco and deco:GetChildren() or {} do
		local pos = m:IsA("Model") and m:GetPivot().Position or (m:IsA("BasePart") and m.Position)
		if pos and pos.X > X0 - 2 and pos.X < X1 + 2 and pos.Z > Z0 - 1 and pos.Z < Z1 + 2 then m:Destroy() end
	end
	-- (in the world first, built into after: the kids wait on their avatars loading, and the town map
	-- scans the town from above 14 s after the server starts)
	local r = Instance.new("Model")
	r.Name = "RecessCommons"
	r:SetAttribute("MapAt", Vector3.new(CX, G, (Z0 + Z1) / 2)) -- (where the town map writes the name)
	r.Parent = lm
	buildGrounds(r)
	buildGate(r)
	buildSwings(r)
	buildFort(r)
	buildRest(r)
end

return TownPlayground
