-- ServerScriptService.Server.RaidService
-- VexCorp raids, the game's solo action. Every few minutes a purple VexCorp van screeches up at your
-- gate and 1-3 goons run into your school. Each grabs a kid and runs for the van, slower now than you
-- are. Bonk a goon with your Ruler: a carrier drops the kid (it's back at its desk), gets knocked
-- flying and flees; tougher goons take more hits before they're out cold. A goon who makes it back
-- to the van takes the kid to the VexCorp Factory, where you can break in and rescue them.
-- A locked laser gate keeps goons out: they bang on it and give up.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Crew = require(game:GetService("ReplicatedStorage").Shared.Crew)

local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local PlotService = require(script.Parent.PlotService)
local SchoolBuilder = require(script.Parent.SchoolBuilder)
local Factory = require(script.Parent.StudentFactory)
local Walkers = require(script.Parent.Walkers)
local StealService = require(script.Parent.StealService)

local RaidService = {}

local R = Config.Raids
local GOON = { id = "VexGoon", name = "VexCorp Goon", title = "Goon", mult = 1, outfit = "goon" }
local CRUMPET = { id = "Crumpet", name = "Crumpet", title = "Butler", mult = 1, outfit = "butler" }

local folder
local raids = {} -- [player] = raid
local nextRaid = {} -- [player] = os.clock() of the next raid
local lastMove = {} -- [player] = os.clock() they last moved (no raids on someone who's away)
local lastPos = {}

local function now() return os.clock() end

---------------------------------------------------------------------------
-- small helpers
---------------------------------------------------------------------------
local function tierOf(p)
	return math.clamp(p.tier or 1, 1, #R.goonsByTier)
end

local function reward(player, secs, floor)
	local inc = player:GetAttribute("BaseIncome") or 0
	return math.floor(math.max(floor, inc * secs))
end

local function goonSay(g, text)
	local label = g.model:FindFirstChild("Head") and g.model.Head:FindFirstChild("GoonTag") and g.model.Head.GoonTag.Label
	if not label then return end
	label.Text = text
	g.said = (g.said or 0) + 1
	local n = g.said
	task.delay(2.5, function()
		if label.Parent and g.said == n then label.Text = "" end
	end)
end

local function tagGoon(model, text, color)
	local head = model:FindFirstChild("Head")
	if not head then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "GoonTag"
	bb.Size = UDim2.fromOffset(220, 40)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	bb.MaxDistance = 90
	bb.LightInfluence = 0
	bb.Parent = head
	local t = Instance.new("TextLabel")
	t.Name = "Label"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = color
	t.Text = text
	t.Parent = bb
	local s = Instance.new("UIStroke")
	s.Thickness = 2.5
	s.Parent = t
end

-- the outline you can see through walls, so a goon carrying your kid is never lost
local function outline(model, color, fill)
	local h = model:FindFirstChild("RaidOutline") or Instance.new("Highlight")
	h.Name = "RaidOutline"
	h.OutlineColor = color
	h.FillColor = color
	h.FillTransparency = fill or 1
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = model
	return h
end

local function burst(pos, color, n)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Transparency = 1
	p.Size = Vector3.one * 0.2
	p.Position = pos
	p.Parent = folder
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.LightEmission = 0.8
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	e.Speed = NumberRange.new(10, 18)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Lifetime = NumberRange.new(0.35, 0.6)
	e.Drag = 4
	e.Rate = 0
	e.Parent = p
	e:Emit(n or 24)
	game:GetService("Debris"):AddItem(p, 1)
end

---------------------------------------------------------------------------
-- the van
---------------------------------------------------------------------------
-- parked alongside the curb in front of the plot; its length runs along the street (lot X)
local VAN_PARK = Vector3.new(18, 0, 89)
local function buildVan()
	-- a purple VexCorp panel van: front +X, the sliding door on -Z (the school side), built around the
	-- road point under its middle (the pivot, so PivotTo puts the wheels on the ground)
	local van = Instance.new("Model")
	van.Name = "VexVan"
	local function p(name, size, cf, color, mat, shape)
		local x = Instance.new(shape == "wedge" and "WedgePart" or "Part")
		x.Name = name
		x.Size = size
		x.CFrame = cf
		x.Color = color
		x.Material = mat or Enum.Material.SmoothPlastic
		x.Anchored, x.CanCollide, x.CanQuery = true, false, false
		x.TopSurface, x.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if shape and shape ~= "wedge" then x.Shape = shape end
		x.Parent = van
		return x
	end
	local function acrossZ(name, d, len, pos, color, mat)
		return p(name, Vector3.new(len, d, d), CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0), color, mat, Enum.PartType.Cylinder)
	end
	local function alongX(name, d, len, pos, color, mat)
		return p(name, Vector3.new(len, d, d), CFrame.new(pos), color, mat, Enum.PartType.Cylinder)
	end
	local function text(part, face, str, color, font, stroke)
		local g = Instance.new("SurfaceGui")
		g.Face = face
		g.LightInfluence = 0.2
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 40
		g.Parent = part
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = font or Enum.Font.LuckiestGuy
		t.TextScaled = true
		t.Text = str
		t.TextColor3 = color
		t.Parent = g
		if stroke then
			local st = Instance.new("UIStroke")
			st.Thickness = 3
			st.Color = stroke
			st.Parent = t
		end
		return t
	end
	local purple, deep, dark = Color3.fromRGB(110, 48, 160), Color3.fromRGB(80, 32, 118), Color3.fromRGB(30, 26, 38)
	local tint, chrome = Color3.fromRGB(28, 26, 44), Color3.fromRGB(205, 205, 215)
	local neon = Color3.fromRGB(205, 150, 255)
	local front = CFrame.Angles(0, math.rad(-90), 0) -- (a wedge that slopes down towards +X)

	-- the body: a lower and an upper box, a darker roof with rounded edges
	p("Body", Vector3.new(17, 3, 7.6), CFrame.new(-0.5, 3.2, 0), purple, Enum.Material.Metal)
	p("Body", Vector3.new(15.2, 3, 7.6), CFrame.new(-1.4, 6.2, 0), purple, Enum.Material.Metal)
	p("Roof", Vector3.new(15.2, 0.3, 7), CFrame.new(-1.4, 7.85, 0), deep, Enum.Material.Metal)
	for _, z in { -3.45, 3.45 } do alongX("RoofEdge", 0.8, 15.2, Vector3.new(-1.4, 7.6, z), purple, Enum.Material.Metal) end
	p("Skirt", Vector3.new(19.4, 0.5, 7.7), CFrame.new(0.6, 1.65, 0), dark)
	-- the cab: a raked, tinted windshield and a short sloping hood
	p("Windshield", Vector3.new(7.4, 3, 2.2), CFrame.new(7.3, 6.1, 0) * front, tint, Enum.Material.Glass, "wedge")
	p("Hood", Vector3.new(2.3, 2.6, 7.4), CFrame.new(9.15, 3.1, 0), purple, Enum.Material.Metal)
	p("HoodTop", Vector3.new(7.4, 0.6, 2.3), CFrame.new(9.15, 4.7, 0) * front, purple, Enum.Material.Metal, "wedge")
	p("Grille", Vector3.new(0.15, 1.6, 4.8), CFrame.new(10.35, 3.0, 0), dark)
	for _, y in { 2.4, 3.0, 3.6 } do p("GrilleBar", Vector3.new(0.1, 0.12, 4.6), CFrame.new(10.45, y, 0), chrome, Enum.Material.Metal) end
	local badge = alongX("Emblem", 1.1, 0.12, Vector3.new(10.5, 3.0, 0), chrome, Enum.Material.Metal)
	text(badge, Enum.NormalId.Right, "V", Color3.fromRGB(120, 40, 170), Enum.Font.LuckiestGuy)
	for _, s in { -1, 1 } do
		p("Headlight", Vector3.new(0.2, 0.5, 1.5), CFrame.new(10.35, 3.95, s * 2.95), Color3.fromRGB(255, 250, 225), Enum.Material.Neon)
		alongX("FogLight", 0.5, 0.15, Vector3.new(10.9, 1.95, s * 3.1), Color3.fromRGB(255, 240, 200), Enum.Material.Neon)
		p("Mirror", Vector3.new(0.5, 0.9, 0.3), CFrame.new(6.6, 5.4, s * 4.05), dark)
		p("MirrorArm", Vector3.new(0.5, 0.15, 0.4), CFrame.new(6.6, 5.2, s * 3.85), dark)
		-- the cab's side window and the neon stripe down each side
		p("SideWindow", Vector3.new(2.6, 1.8, 0.1), CFrame.new(4.6, 6.2, s * 3.83), tint, Enum.Material.Glass)
		p("Stripe", Vector3.new(19, 0.3, 0.1), CFrame.new(0.4, 2.35, s * 3.86), neon, Enum.Material.SmoothPlastic)
	end
	p("Bumper", Vector3.new(0.6, 0.9, 7.8), CFrame.new(10.65, 1.75, 0), dark, Enum.Material.Metal)
	p("RearBumper", Vector3.new(0.6, 0.9, 7.8), CFrame.new(-9.3, 1.75, 0), dark, Enum.Material.Metal)
	-- the back: two doors, dark little windows, tall tail lights and a plate
	p("RearDoor", Vector3.new(0.1, 5.4, 7.2), CFrame.new(-9.05, 4.6, 0), deep, Enum.Material.Metal)
	p("RearSeam", Vector3.new(0.12, 5.4, 0.12), CFrame.new(-9.08, 4.6, 0), dark)
	for _, s in { -1, 1 } do
		p("RearWindow", Vector3.new(0.12, 1.4, 2.4), CFrame.new(-9.1, 6.2, s * 1.7), tint, Enum.Material.Glass)
		p("Taillight", Vector3.new(0.15, 2.6, 0.5), CFrame.new(-9.1, 4, s * 3.5), Color3.fromRGB(230, 30, 50), Enum.Material.Neon)
	end
	local plate = p("Plate", Vector3.new(0.1, 0.8, 2), CFrame.new(-9.65, 1.75, 0), Color3.fromRGB(250, 248, 240))
	text(plate, Enum.NormalId.Left, "VEX 666", Color3.fromRGB(90, 30, 130), Enum.Font.Arcade)
	-- the sliding door on the school side, with a seam and a chrome handle
	p("Door", Vector3.new(4.2, 5.4, 0.12), CFrame.new(1.4, 4.6, -3.86), deep, Enum.Material.Metal)
	for _, x in { -0.7, 3.5 } do p("DoorSeam", Vector3.new(0.1, 5.4, 0.14), CFrame.new(x, 4.6, -3.87), dark) end
	p("Handle", Vector3.new(0.9, 0.2, 0.2), CFrame.new(3, 4.4, -3.95), chrome, Enum.Material.Metal)
	-- the wheels in black arches, with chrome hubs
	for _, x in { -5.8, 7.2 } do
		for _, s in { -1, 1 } do
			acrossZ("WheelArch", 3.7, 0.1, Vector3.new(x, 1.5, s * 3.82), dark)
			acrossZ("Wheel", 2.9, 1.1, Vector3.new(x, 1.45, s * 3.6), Color3.fromRGB(20, 20, 22))
			acrossZ("Hub", 1.6, 1.16, Vector3.new(x, 1.45, s * 3.6), chrome, Enum.Material.Metal)
			acrossZ("HubCap", 0.6, 1.2, Vector3.new(x, 1.45, s * 3.6), purple, Enum.Material.Metal)
		end
	end
	-- VEXCORP on both sides of the cargo box
	for _, face in { { z = -3.87, n = Enum.NormalId.Front }, { z = 3.87, n = Enum.NormalId.Back } } do
		local logo = p("Logo", Vector3.new(6.4, 2.2, 0.08), CFrame.new(-5.4, 5.9, face.z), purple, Enum.Material.Metal)
		logo.Transparency = 1
		text(logo, face.n, "VEXCORP", Color3.fromRGB(250, 245, 255), Enum.Font.LuckiestGuy, Color3.fromRGB(40, 15, 60))
		local sub = p("Logo", Vector3.new(6.4, 0.7, 0.08), CFrame.new(-5.4, 4.4, face.z), purple, Enum.Material.Metal)
		sub.Transparency = 1
		text(sub, face.n, "educational solutions", neon, Enum.Font.GothamBold)
	end
	-- a light bar on the roof: red and blue, flashing while the raid is on
	p("LightBarBase", Vector3.new(1.3, 0.3, 4.6), CFrame.new(2.4, 8.15, 0), dark)
	local bar = p("Siren", Vector3.new(1, 0.45, 2.1), CFrame.new(2.4, 8.5, -1.1), Color3.fromRGB(255, 50, 80), Enum.Material.Neon)
	p("SirenBlue", Vector3.new(1, 0.45, 2.1), CFrame.new(2.4, 8.5, 1.1), Color3.fromRGB(60, 120, 255), Enum.Material.Neon)
	p("Antenna", Vector3.new(0.08, 2.4, 0.08), CFrame.new(-7.5, 9.1, 2.8), dark)
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 60, 90)
	l.Range = 16
	l.Brightness = 2
	l.Parent = bar
	van.WorldPivot = CFrame.new()
	return van
end

local function vanCF(plot, x)
	-- facing along the street toward -X of the lot (drives in from +X)
	return plot.Origin.CFrame * CFrame.new(x, 0, VAN_PARK.Z) * CFrame.Angles(0, math.pi, 0)
end

local function driveVan(van, from, to, dur)
	local v = Instance.new("CFrameValue")
	v.Value = from
	v.Changed:Connect(function(cf)
		if van.Parent then van:PivotTo(cf) end
	end)
	local tw = TweenService:Create(v, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = to })
	tw:Play()
	tw.Completed:Wait()
	v:Destroy()
end

---------------------------------------------------------------------------
-- goons
---------------------------------------------------------------------------
local raidEnded -- forward

local function spinStars(g)
	-- three little stars circling the head while stunned
	local head = g.model:FindFirstChild("Head")
	if not head then return end
	local stars = {}
	for i = 1, 3 do
		local s = Instance.new("Part")
		s.Name = "Star"
		s.Shape = Enum.PartType.Ball
		s.Size = Vector3.one * 0.45
		s.Color = Color3.fromRGB(255, 225, 80)
		s.Material = Enum.Material.Neon
		s.Anchored, s.CanCollide, s.CanQuery, s.CanTouch = true, false, false, false
		s.Parent = g.model
		stars[i] = s
	end
	local t0 = now()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not head.Parent or now() > g.stunUntil then
			conn:Disconnect()
			for _, s in stars do s:Destroy() end
			return
		end
		local t = (now() - t0) * 7
		for i, s in stars do
			local a = t + i * (math.pi * 2 / 3)
			s.Position = head.Position + Vector3.new(math.cos(a) * 1.3, 1.2 + math.sin(t * 1.5 + i) * 0.15, math.sin(a) * 1.3)
		end
	end)
end

-- knocked flying: along dir, a hop, a spin, landing on the ground
local function knockback(g, dir, dist, height, dur)
	local root = g.model.PrimaryPart
	if not root then return end
	Walkers.stop(g.model)
	Factory.play(g.model, "fall")
	local start = root.CFrame
	local y0 = start.Position.Y
	local flat = Vector3.new(dir.X, 0, dir.Z)
	flat = flat.Magnitude > 1e-3 and flat.Unit or -start.LookVector
	local t0 = now()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local a = math.min(1, (now() - t0) / dur)
		if not root.Parent then conn:Disconnect() return end
		local pos = start.Position + flat * dist * a + Vector3.new(0, math.sin(a * math.pi) * height, 0)
		root.CFrame = CFrame.new(pos.X, math.max(y0, pos.Y), pos.Z) * (start - start.Position) * CFrame.Angles(0, a * math.pi * 2, 0)
		if a >= 1 then conn:Disconnect() end
	end)
	task.wait(dur)
end

-- the kid goes back to their desk
local function giveBack(player, g)
	if not g.kid then return end
	g.kid:Destroy()
	g.kid = nil
	local p = Data.get(player)
	if p and p.students[g.slot] == g.e then
		g.e.carried = nil
		PlotService.place(player, g.slot)
		PlotService.updateIncome(player)
		local plot = PlotService.getPlot(player)
		local desk = plot and PlotService.seatedModel(plot, g.slot)
		if desk and desk.PrimaryPart then burst(desk.PrimaryPart.Position, Color3.fromRGB(120, 255, 140), 20) end
	end
end

local function removeGoon(raid, g)
	g.gone = true
	if g.kid then g.kid:Destroy() g.kid = nil end
	if g.model.Parent then g.model:Destroy() end
	local left = false
	for _, o in raid.goons do
		if not o.gone then left = true end
	end
	if not left then task.spawn(raidEnded, raid) end
end

-- run back to the van (with or without a kid) and get in
local function runToVan(raid, g, speed)
	local root = g.model.PrimaryPart
	if not root then return end
	local back = {}
	-- retrace the way in from wherever along it we are
	local best, bestD = #g.path, math.huge
	for i, pt in g.path do
		local d = (pt - root.Position).Magnitude
		if d < bestD then best, bestD = i, d end
	end
	for i = best, 1, -1 do table.insert(back, g.path[i]) end
	Factory.play(g.model, "run")
	Walkers.walk(g.model, back, speed, function()
		if g.gone then return end
		if g.kid and raid.tutorial then
			-- the tutorial thief waits at the van, daring you to stop him
			goonSay(g, "Well? Aren't you going to stop me?")
			g.waiting = true
			Factory.play(g.model, "idle")
			return
		end
		if g.kid then
			-- got away: the kid goes to the VexCorp Factory
			local player = raid.player
			local p = Data.get(player)
			local def = Config.StudentById[g.e.id]
			g.kid:Destroy()
			g.kid = nil
			if p and p.students[g.slot] == g.e then
				PlotService.remove(player, g.slot)
				p.captured = p.captured or {}
				table.insert(p.captured, { id = g.e.id, grade = g.e.grade })
				raid.lost += 1
				Remotes.Notify:FireClient(player, ("\u{1F6A8} They got away with %s! Rescue them from the VexCorp Factory."):format(def.name), "bad")
				Signals.fire("kidCaptured", player, def)
				if raid.onLost then task.spawn(raid.onLost, raid) end
			end
		end
		removeGoon(raid, g)
	end, { flat = false })
end

local sendGoon -- (below: a story goon who finds no kid goes round again)

local function lift(raid, g)
	local player = raid.player
	local p = Data.get(player)
	local plot = PlotService.getPlot(player)
	local e = p and p.students[g.slot]
	if raid.story and e == g.e and e and (e.carried or e.away) then
		-- a story crew doesn't give up: he hangs about and tries again until you knock him out
		goonSay(g, "Where'd the kid go?!")
		Factory.play(g.model, "idle")
		task.delay(2.5, function()
			if not g.gone and not raid.ended and g.model.Parent and not g.kid then sendGoon(raid, g) end
		end)
		return
	end
	if not plot or e ~= g.e or not PlotService.earning(e) or e.away or e.carried then
		-- the kid moved, was sold or is already gone: go home empty-handed
		goonSay(g, "Huh. Nobody here.")
		runToVan(raid, g, R.fleeSpeed)
		return
	end
	e.carried = true
	PlotService.detachModel(plot, g.slot)
	PlotService.updateIncome(player)
	local def = Config.StudentById[e.id]
	local kid = Factory.build(def, e.grade)
	Factory.setMode(kid, "carried")
	for _, bp in kid:GetDescendants() do
		if bp:IsA("BasePart") then
			bp.Anchored = false
			bp.Massless = true
			bp.CanCollide = false
		end
	end
	local root = g.model.PrimaryPart
	local off = 3.4 + Factory.standOffset(kid) * 0.9
	kid.PrimaryPart.CFrame = root.CFrame * CFrame.new(0, off, 0)
	local w = Instance.new("Weld")
	w.Part0, w.Part1 = root, kid.PrimaryPart
	w.C0 = CFrame.new(0, off, 0) * CFrame.Angles(0, 0, math.rad(8))
	w.Parent = kid.PrimaryPart
	kid.Parent = g.model
	Factory.play(kid, "sit")
	g.kid = kid
	outline(g.model, Color3.fromRGB(255, 60, 80))
	goonSay(g, "Got one! Run!")
	g.model:SetAttribute("Carrying", true)
	Remotes.Notify:FireClient(player, ("\u{1F6A8} A goon grabbed %s! Chase him down and bonk him!"):format(def.name), "bad")
	runToVan(raid, g, raid.tutorial and R.tutorialCarrySpeed or R.carrySpeed)
end

-- into the school from wherever the goon is: to the gate first if he's still outside (a locked
-- laser keeps him out), then down the aisle to the kid
sendGoon = function(raid, g)
	local plot = raid.plot
	local root = g.model.PrimaryPart
	if not root then return end
	g.lockToken = nil
	local inside = PlotService.inside(plot, root.Position) and (root.Position - g.path[2]).Magnitude > 2
	local function goIn()
		-- the rest of the way from the nearest point on the path
		local best, bestD = 2, math.huge
		for i = 2, #g.path do
			local d = (g.path[i] - root.Position).Magnitude
			if d < bestD then best, bestD = i, d end
		end
		local rest = {}
		for i = best, #g.path do table.insert(rest, g.path[i]) end
		Factory.play(g.model, "run")
		Walkers.walk(g.model, rest, R.runSpeed, function()
			if g.gone then return end
			lift(raid, g)
		end, { flat = false })
	end
	if inside then
		goIn()
		return
	end
	Factory.play(g.model, "run")
	Walkers.walk(g.model, { g.path[2] }, R.runSpeed, function()
		if g.gone then return end
		local lockedUntil = plot:GetAttribute("LockedUntil") or 0
		-- (the tutorial's Crumpet has a key: the lock is the step after him)
		if not raid.tutorial and not raid.story and lockedUntil > workspace:GetServerTimeNow() then
			goonSay(g, "It's LOCKED?! Ugh.")
			Factory.play(g.model, "idle")
			Factory.emote(g.model, "point")
			local token = {}
			g.lockToken = token
			task.delay(math.min(R.lockWait, lockedUntil - workspace:GetServerTimeNow()), function()
				-- (a bonk or anything else that moved him on since then cancels this)
				if g.gone or not g.model.Parent or g.lockToken ~= token then return end
				g.lockToken = nil
				if (plot:GetAttribute("LockedUntil") or 0) > workspace:GetServerTimeNow() then
					goonSay(g, "Forget it. We'll be back!")
					raid.repelled += 1
					runToVan(raid, g, R.fleeSpeed)
				else
					sendGoon(raid, g) -- the lock ran out while he waited
				end
			end)
			return
		end
		goIn()
	end, { flat = false })
end

---------------------------------------------------------------------------
-- the Ruler
---------------------------------------------------------------------------
local function hitGoon(player, raid, g, root)
	local groot = g.model.PrimaryPart
	if not groot or g.gone or now() < g.stunUntil then return end
	local dir = groot.Position - root.Position
	-- the tutorial's Crumpet can't be knocked out before he's grabbed a kid (the step is to save one)
	if not (raid.tutorial and not g.kid) then
		g.hp -= Crew.perk(player, "Monitor") and g.hp or 1
	end
	Remotes.Sfx:FireClient(player, "Bonk")
	Remotes.Push:FireClient(player, "hit", { pos = groot.Position + Vector3.new(0, 2, 0), ko = g.hp <= 0 })
	burst(groot.Position + Vector3.new(0, 1.5, 0), Color3.fromRGB(255, 230, 120), 26)
	-- a white flash on the whole goon
	local flash = outline(g.model, Color3.new(1, 1, 1), 0.2)
	task.delay(0.12, function()
		if flash.Parent then
			if g.kid then outline(g.model, Color3.fromRGB(255, 60, 80)) else outline(g.model, Color3.fromRGB(170, 90, 255)) end
		end
	end)
	local hadKid = g.kid ~= nil
	local def = hadKid and Config.StudentById[g.e.id]
	g.lockToken = nil
	if hadKid then
		giveBack(raid.player, g)
		if raid.player ~= player and raid.player.Parent then
			Remotes.Notify:FireClient(raid.player, ("%s bonked a goon and saved your %s!"):format(player.DisplayName, def.name), "good")
		end
		g.model:SetAttribute("Carrying", nil)
		raid.saved += 1
		local cash = reward(player, R.saveSecs, R.saveFloor)
		Data.addCash(player, cash)
		Remotes.CashPop:FireClient(player, cash, groot.Position)
		Remotes.Notify:FireClient(player, ("You saved %s! +%s"):format(def.name, Config.formatCash(cash)), "good")
		Signals.fire("bonkSave", player, nil, def, raid.player)
	end
	g.waiting = nil
	task.spawn(function()
		if g.hp <= 0 then
			-- out cold: a big tumble, lie there, then off to Detention in a puff
			goonSay(g, "Ow ow OW...")
			knockback(g, dir, 9, 4, 0.5)
			if g.gone or not groot.Parent then return end
			groot.CFrame = groot.CFrame * CFrame.Angles(math.rad(-80), 0, 0)
			g.stunUntil = now() + 1.4
			spinStars(g)
			task.wait(1.4)
			if g.gone then return end
			burst(groot.Position, Color3.fromRGB(230, 230, 240), 40)
			raid.ko += 1
			if raid.onKO then task.spawn(raid.onKO, raid) end
			local cash = reward(player, R.koSecs, R.koFloor)
			Data.addCash(player, cash)
			Remotes.CashPop:FireClient(player, cash, groot.Position)
			Signals.fire("goonKO", player)
			removeGoon(raid, g)
			return
		end
		goonSay(g, hadKid and "OW! Fine, keep it!" or "OW!")
		knockback(g, dir, 6, 2.5, 0.35)
		if g.gone or not groot.Parent then return end
		g.stunUntil = now() + R.stun
		spinStars(g)
		Factory.play(g.model, "idle")
		task.wait(R.stun)
		if g.gone or not groot.Parent then return end
		if (hadKid or g.fleeing) and not raid.story then
			g.fleeing = true
			goonSay(g, "RUN!")
			runToVan(raid, g, R.fleeSpeed)
		else
			-- he shakes it off and tries again
			goonSay(g, "You'll have to do better than that!")
			sendGoon(raid, g)
		end
	end)
end

local function onSwing(player, root)
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	look = look.Magnitude > 1e-3 and look.Unit or Vector3.new(0, 0, -1)
	-- your own raid's goons, and anyone else's (helping a friend counts)
	for _, raid in raids do
		for _, g in raid.goons do
			local groot = not g.gone and g.model.PrimaryPart
			if groot then
				local d = groot.Position - root.Position
				local flat = Vector3.new(d.X, 0, d.Z)
				if flat.Magnitude < R.hitRange and math.abs(d.Y) < 7 and (flat.Magnitude < 3.5 or flat.Unit:Dot(look) > 0.25) then
					hitGoon(player, raid, g, root)
					return -- one goon per swing
				end
			end
		end
	end
end

---------------------------------------------------------------------------
-- a raid
---------------------------------------------------------------------------
local function targets(player, plot, p, n)
	local list = {}
	for slot, e in p.students do
		if PlotService.earning(e) and not e.away and not e.carried and PlotService.seatedModel(plot, slot) then
			table.insert(list, slot)
		end
	end
	-- the most valuable kids first, but not always the same ones
	table.sort(list, function(a, b)
		return PlotService.incomeOf(player, p.students[a], a) > PlotService.incomeOf(player, p.students[b], b)
	end)
	local out = {}
	for i = 1, math.min(n, #list) do
		local pickFrom = math.min(#list, i + 2)
		local k = math.random(i, pickFrom)
		list[i], list[k] = list[k], list[i]
		table.insert(out, list[i])
	end
	return out
end

raidEnded = function(raid)
	if raid.ended then return end
	raid.ended = true
	local player = raid.player
	task.wait(0.8)
	if raid.van.Parent then
		local plot = raid.plot
		driveVan(raid.van, raid.van:GetPivot(), vanCF(plot, -150), 2.2)
		raid.van:Destroy()
	end
	raids[player] = nil
	nextRaid[player] = now() + math.random(R.every[1], R.every[2])
	player:SetAttribute("Raid", nil)
	if not player.Parent then return end
	if raid.tutorial then
		local p = Data.get(player)
		local step = p and p.tutorial and Config.Tutorial[p.tutorial]
		if step and step.id == "bonk" then
			-- he got away without being bonked (or never found a kid): he'll try again
			task.delay(6, function()
				local pp = Data.get(player)
				local st = pp and pp.tutorial and Config.Tutorial[pp.tutorial]
				if player.Parent and st and st.id == "bonk" then RaidService.tutorialRaid(player) end
			end)
		end
	end
	if raid.lost == 0 and not raid.tutorial and (raid.saved > 0 or raid.ko > 0 or raid.repelled > 0) then
		local cash = reward(player, R.defendSecs, R.defendFloor)
		Data.addCash(player, cash)
		Remotes.Push:FireClient(player, "raidOver", { defended = true, cash = cash, saved = raid.saved, ko = raid.ko })
		Signals.fire("raidDefended", player)
	else
		Remotes.Push:FireClient(player, "raidOver", { defended = raid.lost == 0, lost = raid.lost })
	end
	if raid.onEnd then task.spawn(raid.onEnd, raid) end
end

function RaidService.start_raid(player, opts)
	opts = opts or {}
	player = Data.hostOf(player)
	if raids[player] then return false end
	local plot = PlotService.getPlot(player)
	local p = Data.get(player)
	if not plot or not p or p.reviewing then return false end
	local n = opts.goons or R.goonsByTier[tierOf(p)]
	local slots = targets(player, plot, p, n)
	if #slots == 0 then return false end
	-- a story crew is always its full size: short of kids, two goons go for the same one
	local k = 1
	while opts.story and #slots < n do
		table.insert(slots, slots[k])
		k += 1
	end
	local raid = {
		player = player, plot = plot, goons = {}, van = buildVan(),
		saved = 0, lost = 0, ko = 0, repelled = 0, tutorial = opts.tutorial,
		-- a story raid (MissionService): the gate lock doesn't stop them, a goon who loses his kid comes
		-- back for more instead of fleeing, and the mission hears about every KO, loss and the end
		story = opts.story, onEnd = opts.onEnd, onKO = opts.onKO, onLost = opts.onLost, count = #slots,
	}
	raids[player] = raid
	player:SetAttribute("Raid", #slots)
	if opts.onStart then task.spawn(opts.onStart, raid) end
	raid.van:PivotTo(vanCF(plot, 150))
	raid.van.Parent = folder
	Remotes.Push:FireClient(player, "raid", { goons = #slots, tutorial = opts.tutorial })
	driveVan(raid.van, vanCF(plot, 150), vanCF(plot, VAN_PARK.X), 2.4)
	if not player.Parent or raids[player] ~= raid then
		raid.van:Destroy()
		return false
	end
	local hp = opts.hp or R.hpByTier[tierOf(p)]
	local base = plot.Origin.CFrame
	raid.pending = #slots
	local function spawned()
		raid.pending -= 1
		-- every goon's kid vanished before he could set off: nothing to do, the van leaves
		if raid.pending <= 0 and #raid.goons == 0 and not raid.ended then task.spawn(raidEnded, raid) end
	end
	for i, slot in slots do
		task.delay((i - 1) * 0.6, function()
			if raid.ended or not player.Parent then return end
			local e = p.students[slot]
			if not e or ((e.away or e.carried) and not opts.story) then spawned() return end
			local spec = opts.tutorial and CRUMPET or GOON
			local model = Factory.buildTeacher(spec, 1)
			model.Name = opts.tutorial and "Crumpet" or "Goon"
			model:SetAttribute("RaidGoon", true)
			model:SetAttribute("PlotName", plot.Name)
			tagGoon(model, "", Color3.fromRGB(230, 200, 255))
			outline(model, Color3.fromRGB(170, 90, 255))
			local so = Factory.standOffset(model)
			local door = base:PointToWorldSpace(Vector3.new(VAN_PARK.X - 2 + (i - 1) * 1.5, so, VAN_PARK.Z - 5))
			local entry = plot.Entry.Position
			local path = { door, Vector3.new(entry.X, 0.4 + so, entry.Z) }
			for _, w in PlotService.worldPoints(plot, SchoolBuilder.aisleRoute(slot), so) do table.insert(path, w) end
			model.PrimaryPart.CFrame = CFrame.lookAt(door, path[2])
			model.Parent = folder
			local g = { model = model, slot = slot, e = e, path = path, hp = hp, stunUntil = 0 }
			table.insert(raid.goons, g)
			if opts.tutorial then goonSay(g, "Terribly sorry. Just passing through.") end
			sendGoon(raid, g)
			spawned()
		end)
	end
	return true
end

-- the tutorial's thief: Crumpet, slow, and he never actually leaves with the kid
-- someone just stole from Vex Prep: their goons come for this player's school soon
function RaidService.soon(player, secs)
	player = Data.hostOf(player)
	local at = now() + secs
	if not nextRaid[player] or nextRaid[player] > at then nextRaid[player] = at end
end

function RaidService.tutorialRaid(player)
	return RaidService.start_raid(player, { goons = 1, hp = 1, tutorial = true })
end

local function cleanup(player)
	local raid = raids[player]
	if not raid then return end
	raid.ended = true
	for _, g in raid.goons do
		if g.kid then
			g.kid:Destroy()
			g.kid = nil
			if g.e then g.e.carried = nil end
		end
		if g.model.Parent then g.model:Destroy() end
		g.gone = true
	end
	if raid.van.Parent then raid.van:Destroy() end
	raids[player] = nil
	if player.Parent then
		player:SetAttribute("Raid", nil)
		Remotes.Push:FireClient(player, "raidOver", { defended = false, lost = 0 })
	end
end

function RaidService.start()
	folder = workspace:FindFirstChild("Raids") or Instance.new("Folder")
	folder.Name = "Raids"
	folder.Parent = workspace
	table.insert(StealService.swingHooks, onSwing)
	-- a School Board review rebuilds the school: the goons leave (kids come back via the rebuild)
	table.insert(PlotService.rebuildHooks, function(player)
		player = Data.hostOf(player)
		local raid = raids[player]
		if raid then
			cleanup(player)
			nextRaid[player] = now() + math.random(R.every[1], R.every[2])
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		cleanup(player)
		nextRaid[player], lastMove[player], lastPos[player] = nil, nil, nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for player, p in Data.all() do
				-- (a co-op crew: anyone playing for the school keeps the raids coming)
				for _, pl in Data.schoolPlayers(player) do
					local root = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
					if root and (not lastPos[pl] or (root.Position - lastPos[pl]).Magnitude > 3) then
						lastPos[pl] = root.Position
						lastMove[player] = now()
					end
				end
				local tutorialDone = (p.tutorial or 1) > #Config.Tutorial
				if not nextRaid[player] then nextRaid[player] = now() + R.first end
				if tutorialDone and not raids[player] and now() >= nextRaid[player] and not p.reviewing and not p.finalePending
					and lastMove[player] and now() - lastMove[player] < 90 then
					local kids = 0
					for _, e in p.students do
						if PlotService.earning(e) then kids += 1 end
					end
					if kids >= R.minKids then
						task.spawn(RaidService.start_raid, player)
					else
						nextRaid[player] = now() + 30
					end
				end
			end
		end
	end)
end

-- Studio
function RaidService.debugRaid(player, goons, hp)
	nextRaid[player] = nil
	return RaidService.start_raid(player, { goons = goons, hp = hp })
end
function RaidService.debugState(player)
	local raid = raids[player]
	if not raid then return { active = false } end
	local out = { active = true, saved = raid.saved, lost = raid.lost, ko = raid.ko, repelled = raid.repelled, goons = {} }
	for _, g in raid.goons do
		local root = g.model.PrimaryPart
		table.insert(out.goons, { gone = g.gone == true, carrying = g.kid ~= nil, hp = g.hp, pos = root and { math.floor(root.Position.X), math.floor(root.Position.Z) } or nil })
	end
	return out
end
-- hit the nearest goon as if the player swung at it from right behind
function RaidService.debugHit(player)
	local raid = raids[player]
	if not raid then return false end
	for _, g in raid.goons do
		local groot = not g.gone and g.model.PrimaryPart
		if groot then
			local fake = { Position = groot.Position - groot.CFrame.LookVector * 3, CFrame = groot.CFrame }
			hitGoon(player, raid, g, fake)
			return true
		end
	end
	return false
end

return RaidService
