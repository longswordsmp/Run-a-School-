-- ServerScriptService.Server.GearService
-- Heist Gear (Config.Gear): Janitor Stan's stall outside his Confiscation Closet (and the Shop's Gear
-- tab). Bought with cash, priced in seconds of your school's tuition.
--   perks   Silent Sneakers, Running Shoes, Lockpick Set: player attributes the systems read
--   tools   Cardboard Box: equip it and stand still to be invisible to guards (attribute Boxed)
--   uses    Smoke Bomb, Whoopee Cushion, Energy Drink: backpack tools showing how many are left
-- What guards do about it lives with the guards (FactoryService; later the rival school): they
-- register in GearService.smokeHooks / noiseHooks.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)

local GearService = {}
GearService.smokeHooks = {} -- fn(player, position): guards near a smoke bomb lose the player
GearService.noiseHooks = {} -- fn(position): guards near a whoopee cushion come to look

local PERK_ATTR = { SilentSneakers = "SilentSneakers", RunningShoes = "RunningShoes", LockpickSet = "Lockpick" }

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

function GearService.price(player, def)
	local inc = player:GetAttribute("BaseIncome") or player:GetAttribute("IncomePerSec") or 0
	return math.max(def.floor, math.floor(inc * def.secs))
end

local function gearOf(p)
	p.gear = p.gear or { owned = { Ruler = true } }
	p.gear.owned = p.gear.owned or { Ruler = true }
	p.gear.uses = p.gear.uses or {}
	return p.gear
end

---------------------------------------------------------------------------
-- the tools in the backpack
---------------------------------------------------------------------------
local function toolName(def, n)
	if def.kind == "use" then return ("%s %s x%d"):format(def.icon, def.name, n) end
	return def.icon .. " " .. def.name
end

local function findTool(player, id)
	for _, c in { player:FindFirstChild("Backpack"), player.Character } do
		for _, t in c and c:GetChildren() or {} do
			if t:IsA("Tool") and t:GetAttribute("GearId") == id then return t end
		end
	end
	return nil
end

---------------------------------------------------------------------------
-- the gear itself, built from parts: the same model is the tool in your hand, the thing you throw
-- and the goods on Stan's counter. Returns a Model whose PrimaryPart is "Handle"; every other part is
-- welded to it. (They used to be one primitive each: a grey ball, a pink disc, a blue stub.)
---------------------------------------------------------------------------
local function gearPart(m, handleCF, name, size, offset, color, material, shape, mesh)
	local b = Instance.new("Part")
	b.Name = name
	b.Size = size
	b.Color = color
	b.Material = material or Enum.Material.SmoothPlastic
	b.CanCollide, b.CanQuery, b.CanTouch, b.Massless = false, false, false, true
	b.TopSurface, b.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then b.Shape = shape end
	if mesh then
		local sm = Instance.new("SpecialMesh")
		sm.MeshType = mesh
		sm.Parent = b
	end
	b.CFrame = handleCF * offset
	b.Parent = m
	if m.PrimaryPart and b ~= m.PrimaryPart then
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = m.PrimaryPart, b
		w.Parent = b
	end
	return b
end

function GearService.model(id, at)
	local m = Instance.new("Model")
	m.Name = id
	local cf = at or CFrame.new()
	local function add(...) return gearPart(m, cf, ...) end
	if id == "SmokeBomb" then
		-- a round black bomb with a purple band, a cap and a fizzing fuse
		m.PrimaryPart = add("Handle", Vector3.new(1, 1, 1), CFrame.new(), rgb(40, 40, 48), Enum.Material.Metal, Enum.PartType.Ball)
		add("Band", Vector3.new(0.3, 1.04, 1.04), CFrame.Angles(0, 0, math.rad(90)), rgb(120, 60, 200), Enum.Material.Metal, Enum.PartType.Cylinder)
		add("Cap", Vector3.new(0.22, 0.42, 0.42), CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(90, 90, 100), Enum.Material.Metal, Enum.PartType.Cylinder)
		add("Fuse", Vector3.new(0.5, 0.09, 0.09), CFrame.new(0.12, 0.85, 0) * CFrame.Angles(0, 0, math.rad(60)), rgb(150, 110, 70), Enum.Material.Fabric, Enum.PartType.Cylinder)
		local spark = add("Spark", Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.24, 1.07, 0), rgb(255, 170, 60), Enum.Material.Neon, Enum.PartType.Ball)
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(rgb(255, 200, 90), rgb(255, 110, 40))
		e.Size = NumberSequence.new(0.25, 0)
		e.Lifetime = NumberRange.new(0.2, 0.4)
		e.Rate = 22
		e.Speed = NumberRange.new(2, 4)
		e.SpreadAngle = Vector2.new(60, 60)
		e.LightEmission = 1
		e.Parent = spark
	elseif id == "WhoopeeCushion" then
		-- a squashy pink cushion with a nozzle
		m.PrimaryPart = add("Handle", Vector3.new(1.5, 0.5, 1.5), CFrame.new(), rgb(240, 90, 150), Enum.Material.SmoothPlastic, nil, Enum.MeshType.Sphere)
		add("Nozzle", Vector3.new(0.5, 0.26, 0.26), CFrame.new(0, -0.02, -0.85) * CFrame.Angles(0, math.rad(90), 0), rgb(220, 70, 130), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		add("Lip", Vector3.new(0.08, 0.32, 0.32), CFrame.new(0, -0.02, -1.1) * CFrame.Angles(0, math.rad(90), 0), rgb(250, 160, 200), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	elseif id == "EnergyDrink" then
		-- a can of ZAP!: blue with a yellow lightning stripe, silver top and bottom, a ring pull
		m.PrimaryPart = add("Handle", Vector3.new(1.15, 0.62, 0.62), CFrame.Angles(0, 0, math.rad(90)), rgb(40, 120, 230), Enum.Material.Metal, Enum.PartType.Cylinder)
		for _, y in { -0.6, 0.6 } do
			add("Rim", Vector3.new(0.08, 0.6, 0.6), CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(210, 214, 222), Enum.Material.Metal, Enum.PartType.Cylinder)
		end
		-- a yellow band round the middle (clear of the can's side, so the two never flicker)
		add("Band", Vector3.new(0.34, 0.68, 0.68), CFrame.Angles(0, 0, math.rad(90)), rgb(255, 215, 40), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		add("Pull", Vector3.new(0.2, 0.04, 0.3), CFrame.new(0, 0.65, 0.05), rgb(200, 204, 212), Enum.Material.Metal)
	else
		return nil
	end
	-- (sized for a hand)
	local scale = ({ SmokeBomb = 0.72, WhoopeeCushion = 0.8, EnergyDrink = 0.8 })[id]
	if scale then m:ScaleTo(scale) end
	return m
end

-- a gear model as a tool's handle (the parts move into the Tool; the welds hold)
local function toolHandle(tool, id)
	local m = GearService.model(id)
	if not m then return nil end
	for _, c in m:GetChildren() do c.Parent = tool end
	m:Destroy()
	return tool:FindFirstChild("Handle")
end

-- throw a copy of a gear model in an arc from the hand to where the player faces; calls land(pos)
local function throwArc(player, id, dist, land)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local from = root.Position + root.CFrame.LookVector * 1.5 + Vector3.new(0, 1.5, 0)
	local flat = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	flat = flat.Magnitude > 1e-3 and flat.Unit or Vector3.new(0, 0, -1)
	-- where it comes down: on whatever is there
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local ahead = root.Position + flat * dist
	local hit = workspace:Raycast(ahead + Vector3.new(0, 8, 0), Vector3.new(0, -30, 0), params)
	-- (a wall in the way: it stops short of it)
	local block = workspace:Raycast(from, flat * dist, params)
	if block then
		ahead = block.Position - flat * 1.5
		hit = workspace:Raycast(ahead + Vector3.new(0, 4, 0), Vector3.new(0, -30, 0), params)
	end
	local to = hit and hit.Position or (root.Position + flat * dist - Vector3.new(0, 2.8, 0))
	local m = GearService.model(id, CFrame.new(from))
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then p.Anchored = p == m.PrimaryPart end
	end
	m.Parent = workspace
	local t0, dur = os.clock(), 0.55
	local conn
	conn = game:GetService("RunService").Heartbeat:Connect(function()
		local a = math.min(1, (os.clock() - t0) / dur)
		local pos = from:Lerp(to + Vector3.new(0, 0.3, 0), a) + Vector3.new(0, math.sin(a * math.pi) * 5, 0)
		if m.PrimaryPart then m:PivotTo(CFrame.new(pos) * CFrame.Angles(a * 9, a * 4, 0)) end
		if a >= 1 then
			conn:Disconnect()
			if m.PrimaryPart then m:PivotTo(CFrame.new(to + Vector3.new(0, 0.3, 0))) end
			task.spawn(land, to, m)
		end
	end)
	return m
end

-- the cardboard box, worn over the whole player
local function wearBox(player, on)
	local char = player.Character
	if not char then return end
	local old = char:FindFirstChild("HidingBox")
	if old then old:Destroy() end
	player:SetAttribute("Boxed", on or nil)
	require(script.Parent.StealService).setSpeed(player)
	if not on then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local box = Instance.new("Model")
	box.Name = "HidingBox"
	local cardboard = rgb(186, 140, 90)
	local function p(name, size, cf, color)
		local b = Instance.new("Part")
		b.Name = name
		b.Size = size
		b.Color = color or cardboard
		b.Material = Enum.Material.Cardboard
		b.CanCollide = false
		b.CanQuery = false
		b.CanTouch = false
		b.Massless = true
		b.CFrame = root.CFrame * cf
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = root, b
		w.Parent = b
		b.Parent = box
		return b
	end
	-- a big box over the whole kid, flaps on top, a "FRAGILE" label and eye holes
	local y = -0.35
	p("Body", Vector3.new(3.6, 4.4, 3), CFrame.new(0, y, 0))
	p("FlapL", Vector3.new(1.8, 0.1, 3), CFrame.new(-1.4, y + 2.45, 0) * CFrame.Angles(0, 0, math.rad(35)))
	p("FlapR", Vector3.new(1.8, 0.1, 3), CFrame.new(1.4, y + 2.45, 0) * CFrame.Angles(0, 0, math.rad(-35)))
	p("Tape", Vector3.new(3.62, 0.3, 0.3), CFrame.new(0, y + 2.05, -1.36), rgb(210, 190, 150))
	local label = p("Label", Vector3.new(2, 0.7, 0.05), CFrame.new(0, y + 0.2, -1.53), rgb(230, 60, 60))
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.Parent = label
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.LuckiestGuy
	t.Text = "FRAGILE"
	t.TextColor3 = rgb(255, 255, 255)
	t.Parent = g
	for _, x in { -0.45, 0.45 } do
		p("EyeHole", Vector3.new(0.5, 0.22, 0.05), CFrame.new(x, y + 1.4, -1.53), rgb(20, 16, 12))
	end
	box.Parent = char
end

local function useGear(player, def, tool)
	local p = Data.get(player)
	if not p then return end
	local gear = gearOf(p)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if def.kind == "use" then
		if (gear.uses[def.id] or 0) <= 0 then return end
		gear.uses[def.id] -= 1
	end
	-- the move that goes with it, on every client (GearMoves.client): a swig, an overarm throw, a slam
	-- at your feet. What's thrown leaves the hand at the end of the wind-up.
	local move = ({ EnergyDrink = "drink", WhoopeeCushion = "throw", SmokeBomb = "slam" })[def.id]
	if move then
		char:SetAttribute("GearMove", ("%s:%.3f"):format(move, os.clock()))
		if move ~= "drink" then
			task.wait(0.2)
			root = char.Parent and char:FindFirstChild("HumanoidRootPart")
			if not root then return end
		end
	end
	if def.id == "SmokeBomb" then
		-- a big cloud right where you stand that hangs about, and you flicker out of sight in it
		local puff = Instance.new("Part")
		puff.Anchored, puff.CanCollide, puff.CanQuery, puff.CanTouch = true, false, false, false
		puff.Transparency = 1
		puff.Size = Vector3.one
		puff.Position = root.Position - Vector3.new(0, 1.5, 0)
		puff.Parent = workspace
		local function cloud(color1, color2, size, rate, speed, life)
			local e = Instance.new("ParticleEmitter")
			e.Texture = "rbxasset://textures/particles/smoke_main.dds"
			e.Color = ColorSequence.new(color1, color2)
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.5), NumberSequenceKeypoint.new(0.3, size), NumberSequenceKeypoint.new(1, size * 1.4) })
			e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.75, 0.25), NumberSequenceKeypoint.new(1, 1) })
			e.Lifetime = NumberRange.new(life, life + 1.5)
			e.Speed = NumberRange.new(speed * 0.5, speed)
			e.SpreadAngle = Vector2.new(180, 180)
			e.Drag = 3
			e.Rate = rate
			e.RotSpeed = NumberRange.new(-40, 40)
			e.Rotation = NumberRange.new(0, 360)
			e.LightInfluence = 0.5
			e.Parent = puff
			return e
		end
		local big = cloud(rgb(225, 222, 235), rgb(150, 140, 175), 11, 30, 14, 4)
		local low = cloud(rgb(190, 180, 215), rgb(120, 110, 150), 7, 20, 6, 5)
		big:Emit(120)
		low:Emit(60)
		local flash = Instance.new("PointLight")
		flash.Color = rgb(210, 190, 255)
		flash.Range = 24
		flash.Brightness = 4
		flash.Parent = puff
		game:GetService("TweenService"):Create(flash, TweenInfo.new(0.6), { Brightness = 0 }):Play()
		task.delay(4, function() big.Enabled = false low.Enabled = false end)
		Debris:AddItem(puff, 10)
		-- vanish: the character fades almost out for a couple of seconds
		local faded = {}
		for _, d in char:GetDescendants() do
			if (d:IsA("BasePart") or d:IsA("Decal")) and d.Name ~= "HumanoidRootPart" and d.Transparency < 1 then
				faded[d] = d.Transparency
				d.Transparency = 0.8
			end
		end
		task.delay(2.5, function()
			for d, t in faded do
				if d.Parent then d.Transparency = t end
			end
		end)
		player:SetAttribute("SmokeUntil", workspace:GetServerTimeNow() + 3)
		for _, hook in GearService.smokeHooks do task.spawn(hook, player, root.Position) end
		Remotes.Notify:FireClient(player, "\u{1F4A8} POOF! Now get out of here!", "good")
	elseif def.id == "WhoopeeCushion" then
		-- thrown ahead: it lands, sits there for two seconds, puffs up and goes off
		throwArc(player, "WhoopeeCushion", 22, function(at, m)
			task.wait(2)
			if not m.Parent or not m.PrimaryPart then return end
			local TweenService = game:GetService("TweenService")
			-- (it swells up...)
			local scale = Instance.new("NumberValue")
			scale.Value = 1
			scale.Changed:Connect(function(v) if m.Parent then m:ScaleTo(v) end end)
			TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = 1.5 }):Play()
			task.wait(0.25)
			-- (...and goes off: a ring across the floor, the word, the noise)
			local ring = Instance.new("Part")
			ring.Shape = Enum.PartType.Cylinder
			ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch = true, false, false, false
			ring.Material = Enum.Material.Neon
			ring.Color = rgb(255, 140, 200)
			ring.Size = Vector3.new(0.15, 2, 2)
			ring.CFrame = CFrame.new(at + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
			ring.Transparency = 0.2
			ring.Parent = workspace
			TweenService:Create(ring, TweenInfo.new(0.7, Enum.EasingStyle.Quad), { Size = Vector3.new(0.15, 34, 34), Transparency = 1 }):Play()
			Debris:AddItem(ring, 0.8)
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.fromOffset(220, 70)
			bb.StudsOffset = Vector3.new(0, 3, 0)
			bb.AlwaysOnTop = true
			bb.Parent = m.PrimaryPart
			local t = Instance.new("TextLabel")
			t.Size = UDim2.fromScale(1, 1)
			t.BackgroundTransparency = 1
			t.TextScaled = true
			t.Font = Enum.Font.LuckiestGuy
			t.Text = "PFFFFRT!"
			t.TextColor3 = rgb(255, 150, 200)
			local st = Instance.new("UIStroke")
			st.Thickness = 3
			st.Parent = t
			t.Parent = bb
			Remotes.Sfx:FireAllClients("Bonk", at)
			for _, hook in GearService.noiseHooks do task.spawn(hook, at) end
			-- then it goes flat and fades
			TweenService:Create(scale, TweenInfo.new(0.6), { Value = 0.7 }):Play()
			task.wait(3)
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then TweenService:Create(d, TweenInfo.new(0.5), { Transparency = 1 }):Play() end
			end
			Debris:AddItem(m, 0.6)
		end)
	elseif def.id == "EnergyDrink" then
		-- a swig (GearMoves: the can comes up to the mouth), then a streak of lightning behind you for 20 s
		player:SetAttribute("EnergyUntil", workspace:GetServerTimeNow() + 20)
		require(script.Parent.StealService).setSpeed(player)
		local old = root:FindFirstChild("EnergyTrail")
		if old then old:Destroy() end
		local a0 = Instance.new("Attachment")
		a0.Name = "EnergyA0"
		a0.Position = Vector3.new(0, 1.2, 0.4)
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Name = "EnergyA1"
		a1.Position = Vector3.new(0, -1.6, 0.4)
		a1.Parent = root
		local trail = Instance.new("Trail")
		trail.Name = "EnergyTrail"
		trail.Attachment0, trail.Attachment1 = a0, a1
		trail.Color = ColorSequence.new(rgb(255, 230, 60), rgb(60, 150, 255))
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.Lifetime = 0.35
		trail.LightEmission = 1
		trail.Parent = root
		task.delay(20.1, function()
			trail:Destroy()
			a0:Destroy()
			a1:Destroy()
			if player.Parent then require(script.Parent.StealService).setSpeed(player) end
		end)
		Remotes.Notify:FireClient(player, "\u{26A1} ZAP! 20 seconds of sprinting that never runs out", "good")
	end
	Signals.fire("gearUse", player, def.id)
	-- update the count on the tool (or take it away when it's the last one)
	if def.kind == "use" and tool then
		local n = gear.uses[def.id] or 0
		-- (the last one goes once its move is over, not out of your hand halfway through the swig)
		if n <= 0 then task.delay(move == "drink" and 1.1 or 0.4, function() tool:Destroy() end) else tool.Name = toolName(def, n) end
	end
end

---------------------------------------------------------------------------
-- the Hoverboard: equipped, you stand on a glowing board a little off the ground and ride 2.2x as fast
-- (MoveService reads the Hover attribute); unequipped, you step off. Off inside the secured places.
-- The board points the way you're going (its -Z is your front). HoverRide.client gives every rider a
-- surf stance and makes the board bob and bank into turns (through the weld HoverWeld's C0, locally).
---------------------------------------------------------------------------
local BOARD = rgb(120, 60, 200)
local GLOW = rgb(120, 230, 255)
-- golden: the Golden Hoverboard pass (gold deck and tips, white-gold glow, a sparkle trail)
local GOLD_DECK, GOLD_GLOW = rgb(245, 190, 40), rgb(255, 240, 170)
local function buildBoard(golden)
	local BOARD = golden and GOLD_DECK or BOARD
	local GLOW = golden and GOLD_GLOW or GLOW
	local m = Instance.new("Model")
	m.Name = "HoverboardRide"
	if golden then m:SetAttribute("Golden", true) end
	local function bp(name, size, cf, color, material, shape)
		local b = Instance.new("Part")
		b.Name = name
		b.Size = size
		b.CFrame = cf
		b.Color = color
		b.Material = material or Enum.Material.SmoothPlastic
		b.CanCollide, b.CanQuery, b.CanTouch, b.Massless = false, false, false, true
		b.CastShadow = name == "Deck"
		if shape then b.Shape = shape end
		b.Parent = m
		return b
	end
	-- the deck, and its rounded tips turned up a little at both ends (a flat disc each: a cylinder with
	-- its axis stood upright; X is its thickness)
	local deck = bp("Deck", Vector3.new(1.6, 0.24, 3.9), CFrame.new(), BOARD, golden and Enum.Material.Metal or nil)
	if golden then deck.Reflectance = 0.2 end
	m.PrimaryPart = deck
	for _, s in { -1, 1 } do
		bp("Tip", Vector3.new(0.24, 1.6, 1.6), CFrame.new(0, 0.1, s * 2.05) * CFrame.Angles(math.rad(s * 13), 0, 0) * CFrame.Angles(0, 0, math.rad(90)), BOARD, nil, Enum.PartType.Cylinder)
	end
	-- grip tape with a yellow centre line, and chrome rails down both edges (the golden board: gold
	-- tread plate, a white line, gold rails; it's what the rider sees, so it has to read as gold)
	local grip = bp("Grip", Vector3.new(1.36, 0.04, 3.7), CFrame.new(0, 0.14, 0), golden and rgb(200, 145, 30) or rgb(30, 30, 36), golden and Enum.Material.DiamondPlate or nil)
	if golden then grip.Reflectance = 0.15 end
	bp("Stripe", Vector3.new(0.22, 0.045, 3.4), CFrame.new(0, 0.15, 0), golden and rgb(255, 250, 225) or rgb(255, 200, 60), golden and Enum.Material.Neon or nil)
	for _, s in { -1, 1 } do
		local rail = bp("Rail", Vector3.new(0.1, 0.28, 3.9), CFrame.new(s * 0.82, 0, 0), golden and rgb(255, 215, 90) or rgb(205, 208, 220), Enum.Material.Metal)
		if golden then rail.Reflectance = 0.3 end
	end
	-- underneath: a glow strip and two thruster pods, a ring of light at the bottom of each
	local glow = bp("Glow", Vector3.new(1.1, 0.06, 2.4), CFrame.new(0, -0.15, 0), GLOW, Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = GLOW
	light.Range = 9
	light.Brightness = 1.6
	light.Parent = glow
	for _, s in { -1, 1 } do
		bp("Thruster", Vector3.new(0.4, 0.95, 0.95), CFrame.new(0, -0.32, s * 1.35) * CFrame.Angles(0, 0, math.rad(90)), golden and rgb(150, 105, 25) or rgb(60, 60, 72), Enum.Material.Metal, Enum.PartType.Cylinder)
		bp("ThrusterRing", Vector3.new(0.08, 0.78, 0.78), CFrame.new(0, -0.53, s * 1.35) * CFrame.Angles(0, 0, math.rad(90)), GLOW, Enum.Material.Neon, Enum.PartType.Cylinder)
		local a = Instance.new("Attachment")
		a.Name = "Exhaust"
		a.Position = Vector3.new(0, -0.6, s * 1.35) -- (just under the ring; the deck's -Y is down)
		a.Parent = deck
	end
	for _, b in m:GetChildren() do
		if b:IsA("BasePart") and b ~= deck then
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = deck, b
			w.Parent = b
		end
	end
	return m
end

-- the Diamond Hoverboard pass's glow (rideEffects: its trail and the thruster shimmer)
local DIAMOND_GLOW = rgb(200, 245, 255)
-- the Diamond Hoverboard: its own build, not the regular board recoloured. A crystal deck lit from
-- inside, diamond-cut bevelled edges with a bright ridge, pointed crystal tips, a row of glowing
-- diamond inlays down the middle, a cut gem on the nose, faceted crystal thrusters. Board space: the
-- deck's -Y is down, -Z is the nose (the trail streams off +Z).
local GEM_MESH = "rbxassetid://9438591297" -- (a brilliant-cut diamond, 44 x 38 x 50 in its own units)
local function buildDiamondBoard()
	local CRYSTAL = rgb(85, 185, 255)
	local ICE = rgb(215, 245, 255)
	local CORE = rgb(120, 225, 255)
	local PLATINUM = rgb(240, 246, 255)
	local m = Instance.new("Model")
	m.Name = "HoverboardRide"
	m:SetAttribute("Diamond", true)
	local function bp(name, size, cf, color, material, props, class)
		local b = Instance.new(class or "Part")
		b.Name = name
		b.Size = size
		b.CFrame = cf
		b.Color = color
		b.Material = material or Enum.Material.SmoothPlastic
		b.TopSurface, b.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		b.CanCollide, b.CanQuery, b.CanTouch, b.Massless = false, false, false, true
		b.CastShadow = false
		if props then for k, v in props do b[k] = v end end
		b.Parent = m
		return b
	end
	local glass = { Transparency = 0.06, Reflectance = 0.25 } -- (solid enough to read against white pavement)
	-- the deck: clear crystal, with a glowing core running through it (the light inside is what makes
	-- glass read as a gem rather than as blue plastic)
	local deck = bp("Deck", Vector3.new(1.3, 0.22, 3.6), CFrame.new(), CRYSTAL, Enum.Material.Glass, glass)
	m.PrimaryPart = deck
	local glow = bp("Glow", Vector3.new(0.9, 0.08, 3.1), CFrame.new(0, -0.02, 0), CORE, Enum.Material.Neon, { Transparency = 0.15 })
	local light = Instance.new("PointLight")
	light.Color = ICE
	light.Range = 7
	light.Brightness = 1
	light.Parent = glow
	-- diamond-cut edges: each long side is two bevels meeting in a sharp bright ridge
	for _, s in { -1, 1 } do
		local turn = CFrame.Angles(0, s * math.rad(-90), 0) -- (a wedge's tall side turned in to the deck)
		local x = s * (0.65 + 0.14)
		bp("Bevel", Vector3.new(3.6, 0.11, 0.28), CFrame.new(x, 0.055, 0) * turn, CRYSTAL, Enum.Material.Glass, glass, "WedgePart")
		bp("Bevel", Vector3.new(3.6, 0.11, 0.28), CFrame.new(x, -0.055, 0) * turn * CFrame.Angles(0, 0, math.pi), CRYSTAL, Enum.Material.Glass, glass, "WedgePart")
		bp("Ridge", Vector3.new(0.07, 0.07, 3.6), CFrame.new(s * 0.93, 0, 0), PLATINUM, Enum.Material.Metal, { Reflectance = 0.55 })
	end
	-- pointed crystal tips, turned up a little: a square on its corner, so the point leads
	for _, s in { -1, 1 } do
		local at = CFrame.new(0, 0.06, s * 1.8) * CFrame.Angles(math.rad(s * 12), 0, 0)
		bp("Tip", Vector3.new(1.3, 0.2, 1.3), at * CFrame.Angles(0, math.rad(45), 0), CRYSTAL, Enum.Material.Glass, glass)
	end
	-- cut diamonds (a brilliant-cut mesh, the table up): a big one on a platinum mount on the nose, and
	-- three set into the deck down the middle, each in a platinum ring
	local function diamond(name, width, cf, core)
		local g = bp(name, Vector3.new(width, width, width), cf, ICE, Enum.Material.Glass, { Transparency = 0.08, Reflectance = 0.45 })
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = GEM_MESH
		mesh.Scale = Vector3.one * (width / 50)
		mesh.Parent = g
		if core then
			bp(name .. "Core", Vector3.new(width * 0.36, width * 0.36, width * 0.36), cf * CFrame.new(0, -width * 0.05, 0), CORE, Enum.Material.Neon, { Shape = Enum.PartType.Ball })
		end
		return g
	end
	diamond("Gem", 0.8, CFrame.new(0, 0.55, -2.15), true)
	bp("GemSeat", Vector3.new(0.12, 0.5, 0.5), CFrame.new(0, 0.2, -2.15) * CFrame.Angles(0, 0, math.rad(90)), PLATINUM, Enum.Material.Metal, { Reflectance = 0.55, Shape = Enum.PartType.Cylinder })
	for _, z in { -0.95, 0, 0.95 } do
		diamond("Inlay", 0.46, CFrame.new(0, 0.1, z), false) -- (the tops just under the rider's soles)
		bp("Setting", Vector3.new(0.05, 0.6, 0.6), CFrame.new(0, 0.115, z) * CFrame.Angles(0, 0, math.rad(90)), PLATINUM, Enum.Material.Metal, { Reflectance = 0.55, Shape = Enum.PartType.Cylinder })
	end
	-- underneath: two faceted crystal pods, a ring of light under each
	for _, s in { -1, 1 } do
		local podAt = CFrame.new(0, -0.36, s * 1.3)
		bp("Thruster", Vector3.new(0.62, 0.62, 0.62), podAt * CFrame.Angles(0, math.rad(45), 0) * CFrame.Angles(math.rad(45), 0, 0), CRYSTAL, Enum.Material.Glass, glass)
		bp("ThrusterRing", Vector3.new(0.08, 0.8, 0.8), CFrame.new(0, -0.6, s * 1.3) * CFrame.Angles(0, 0, math.rad(90)), ICE, Enum.Material.Neon, { Shape = Enum.PartType.Cylinder })
		local a = Instance.new("Attachment")
		a.Name = "Exhaust"
		a.Position = Vector3.new(0, -0.66, s * 1.3)
		a.Parent = deck
	end
	for _, b in m:GetChildren() do
		if b:IsA("BasePart") and b ~= deck then
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = deck, b
			w.Parent = b
		end
	end
	return m
end

-- ridden only: a ribbon of light off the tail and a shimmer under the thrusters (and on a golden
-- board, sparkles streaming off it)
local function rideEffects(board)
	local golden = board:GetAttribute("Golden") == true
	local BOARD = golden and GOLD_DECK or BOARD
	local GLOW = golden and GOLD_GLOW or GLOW
	local diamond = board:GetAttribute("Diamond") == true
	if diamond then BOARD, GLOW = rgb(185, 238, 255), DIAMOND_GLOW end
	local deck = board.PrimaryPart
	if diamond then
		local sp = Instance.new("ParticleEmitter")
		sp.Name = "DiamondSparkles"
		sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sp.Color = ColorSequence.new(rgb(255, 255, 255), rgb(140, 225, 255))
		sp.LightEmission = 0.8
		sp.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
		sp.Lifetime = NumberRange.new(0.4, 0.8)
		sp.Rate = 18
		sp.Speed = NumberRange.new(0.5, 2)
		sp.SpreadAngle = Vector2.new(180, 180)
		sp.Parent = deck
	end
	if golden then
		local sp = Instance.new("ParticleEmitter")
		sp.Name = "GoldSparkles"
		sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sp.Color = ColorSequence.new(rgb(255, 230, 120), rgb(255, 255, 230))
		sp.LightEmission = 1
		sp.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		sp.Lifetime = NumberRange.new(0.5, 0.9)
		sp.Rate = 30
		sp.Speed = NumberRange.new(0.5, 1.5)
		sp.SpreadAngle = Vector2.new(180, 180)
		sp.Parent = deck
	end
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Name, a1.Name = "TrailL", "TrailR"
	a0.Position, a1.Position = Vector3.new(-0.7, -0.2, 2), Vector3.new(0.7, -0.2, 2)
	a0.Parent, a1.Parent = deck, deck
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Lifetime = 0.5
	trail.MinLength = 0.2
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.Color = ColorSequence.new(GLOW, BOARD)
	if board:GetAttribute("Secret") then
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rgb(255, 80, 80)), ColorSequenceKeypoint.new(0.2, rgb(255, 180, 60)),
			ColorSequenceKeypoint.new(0.4, rgb(255, 240, 80)), ColorSequenceKeypoint.new(0.6, rgb(90, 230, 120)),
			ColorSequenceKeypoint.new(0.8, rgb(80, 160, 255)), ColorSequenceKeypoint.new(1, rgb(190, 110, 255)),
		})
		trail.Lifetime = 0.9
	end
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1) })
	trail.WidthScale = NumberSequence.new(1, 0.2)
	trail.FaceCamera = true
	trail.Parent = deck
	for _, ex in deck:GetChildren() do
		if ex.Name == "Exhaust" then
			local e = Instance.new("ParticleEmitter")
			e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			e.Color = ColorSequence.new(GLOW)
			e.LightEmission = 0.9
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
			e.Transparency = NumberSequence.new(0.3, 1)
			e.Lifetime = NumberRange.new(0.25, 0.4)
			e.Rate = 18
			e.Speed = NumberRange.new(2, 3)
			e.EmissionDirection = Enum.NormalId.Bottom
			e.SpreadAngle = Vector2.new(20, 20)
			e.Parent = ex
		end
	end
end

GearService.buildBoard = buildBoard
local LIFT = 1.3
local function ride(player, on)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end
	local old = char:FindFirstChild("HoverboardRide")
	if old then old:Destroy() end
	if on and not player:GetAttribute("Hover") then
		hum.HipHeight += LIFT
		-- (the fastest board you own: Diamond, then the Secret Gold one, then Golden)
		local diamond = player:GetAttribute("Pass_DiamondBoard") == true
		local secret = not diamond and player:GetAttribute("CodeGoldBoard") == true
		local board = diamond and buildDiamondBoard() or buildBoard(player:GetAttribute("Pass_GoldenBoard") == true or secret)
		-- (the Secret Gold Hoverboard: gold, with a rainbow trail behind it)
		if secret then board:SetAttribute("Secret", true) end
		rideEffects(board)
		-- (under the feet, which are now LIFT off the ground, pointing the way you face)
		local feet = root.Size.Y / 2 + hum.HipHeight
		local deck = board.PrimaryPart
		board:PivotTo(root.CFrame * CFrame.new(0, -feet + 0.32, 0))
		-- (a Weld, not a WeldConstraint: the clients move its C0 to bob and bank the board)
		local w = Instance.new("Weld")
		w.Name = "HoverWeld"
		w.Part0, w.Part1 = root, deck
		w.C0 = root.CFrame:ToObjectSpace(deck.CFrame)
		w.Parent = deck
		board.Parent = char
		player:SetAttribute("Hover", true)
	elseif not on and player:GetAttribute("Hover") then
		hum.HipHeight = math.max(0, hum.HipHeight - LIFT)
		player:SetAttribute("Hover", nil)
	end
	require(script.Parent.StealService).setSpeed(player)
end
GearService.ride = ride

local function makeTool(player, def, n)
	local tool = Instance.new("Tool")
	tool.Name = toolName(def, n or 1)
	tool.ToolTip = def.desc
	tool.CanBeDropped = false
	tool:SetAttribute("GearId", def.id)
	if def.id == "Hoverboard" then
		tool.RequiresHandle = false
		tool.Equipped:Connect(function() ride(player, true) end)
		tool.Unequipped:Connect(function() ride(player, false) end)
		return tool
	end
	if def.id == "CardboardBox" then
		tool.RequiresHandle = false
		tool.Equipped:Connect(function() wearBox(player, true) end)
		tool.Unequipped:Connect(function() wearBox(player, false) end)
	else
		toolHandle(tool, def.id)
		if def.id == "EnergyDrink" then
			-- (the can's axis is its handle's X: stood upright in the fist)
			tool.Grip = CFrame.Angles(0, 0, math.rad(90))
		elseif def.id == "WhoopeeCushion" then
			-- (held by the edge, nozzle forward)
			tool.Grip = CFrame.new(0, 0, 0.55)
		end
		tool.Activated:Connect(function()
			useGear(player, def, tool)
		end)
	end
	return tool
end

-- the player's gear tools, in step with what they own
local function refreshOne(player)
	local p = Data.get(player)
	local backpack = player:FindFirstChild("Backpack")
	if not p or not backpack then return end
	local gear = gearOf(p)
	for _, def in Config.Gear do
		local n = def.kind == "use" and (gear.uses[def.id] or 0) or (gear.owned[def.id] and 1 or 0)
		local tool = findTool(player, def.id)
		if def.kind == "perk" then
			if PERK_ATTR[def.id] then player:SetAttribute(PERK_ATTR[def.id], gear.owned[def.id] or nil) end
		elseif n > 0 and not tool then
			makeTool(player, def, n).Parent = backpack
		elseif n > 0 and tool then
			tool.Name = toolName(def, n)
		elseif n <= 0 and tool then
			tool:Destroy()
		end
	end
end

-- (co-op: the school's gear cupboard is shared, so everyone in the crew gets the tools)
function GearService.refreshTools(player)
	for _, pl in Data.schoolPlayers(player) do refreshOne(pl) end
end

---------------------------------------------------------------------------
-- buying
---------------------------------------------------------------------------
Actions.register("gearShop", function(player, p)
	local gear = gearOf(p)
	local items = {}
	for _, def in Config.Gear do
		if def.notSold then continue end
		table.insert(items, {
			id = def.id,
			price = GearService.price(player, def),
			owned = def.kind ~= "use" and gear.owned[def.id] == true or nil,
			count = def.kind == "use" and (gear.uses[def.id] or 0) or nil,
		})
	end
	return { ok = true, items = items, max = Config.GearUse.max }
end)

function GearService.has(player, id)
	local p = Data.get(player)
	local gear = p and gearOf(p)
	return gear ~= nil and (gear.owned[id] == true or (gear.uses[id] or 0) > 0)
end

function GearService.give(player, id, n)
	local p = Data.get(player)
	local def = Config.GearById[id]
	if not p or not def then return false end
	local gear = gearOf(p)
	if def.kind == "use" then
		gear.uses[id] = math.min(Config.GearUse.max, (gear.uses[id] or 0) + (n or 1))
	else
		gear.owned[id] = true
	end
	GearService.refreshTools(player)
	return true
end

Actions.register("buyGear", function(player, p, id)
	local def = Config.GearById[id]
	if not def then return { ok = false, err = "Unknown gear" } end
	local gear = gearOf(p)
	if def.notSold then return { ok = false, err = "Not for sale" } end
	if def.kind ~= "use" and gear.owned[id] then return { ok = false, err = "You already have it" } end
	if def.kind == "use" and (gear.uses[id] or 0) >= Config.GearUse.max then return { ok = false, err = "Your pockets are full" } end
	local price = GearService.price(player, def)
	if not Data.addCash(player, -price) then
		Remotes.Sfx:FireClient(player, "Error")
		return { ok = false, err = "Not enough cash", need = price }
	end
	GearService.give(player, id, 1)
	Remotes.Sfx:FireClient(player, "Buy")
	Remotes.Announce:FireClient(player, (def.icon .. " " .. def.name):upper() .. "!", rgb(255, 170, 60))
	Signals.fire("gearBuy", player, def)
	return { ok = true }
end)

---------------------------------------------------------------------------
-- Stan's stall, outside the Closet
---------------------------------------------------------------------------
local function buildStall()
	local map = workspace:WaitForChild("Map", 30)
	if not map then return end
	local old = workspace:FindFirstChild("GearStall")
	if old then old:Destroy() end
	local m = Instance.new("Model")
	m.Name = "GearStall"
	-- beside the walkway up to the Closet (x -190, z -28..-62), facing the path
	local base = CFrame.new(-182.5, 0.5, -52) * CFrame.Angles(0, math.rad(90), 0)
	local function part(name, size, cf, color, material, shape)
		local b = Instance.new("Part")
		b.Name = name
		b.Size = size
		b.CFrame = base * cf
		b.Color = color
		b.Material = material or Enum.Material.SmoothPlastic
		b.Anchored = true
		b.TopSurface = Enum.SurfaceType.Smooth
		b.BottomSurface = Enum.SurfaceType.Smooth
		if shape then b.Shape = shape end
		b.Parent = m
		return b
	end
	local wood = rgb(120, 84, 56)
	-- a counter with a striped awning over it
	part("Counter", Vector3.new(8, 3.2, 2.4), CFrame.new(0, 1.6, 0), wood, Enum.Material.WoodPlanks)
	part("CounterTop", Vector3.new(8.4, 0.3, 2.8), CFrame.new(0, 3.35, 0), rgb(70, 50, 36), Enum.Material.Wood)
	for _, x in { -3.9, 3.9 } do
		part("Post", Vector3.new(0.4, 7.6, 0.4), CFrame.new(x, 3.8, 1.2), wood, Enum.Material.Wood)
	end
	for i = 0, 7 do
		part("Awning", Vector3.new(1.05, 0.2, 3.4), CFrame.new(-3.7 + i * 1.05, 7.7, 0.4) * CFrame.Angles(math.rad(-14), 0, 0), i % 2 == 0 and rgb(60, 60, 70) or rgb(240, 240, 245))
	end
	local sign = part("Sign", Vector3.new(6.4, 1.5, 0.3), CFrame.new(0, 8.9, -0.9), rgb(30, 30, 40))
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 20
	g.Parent = sign
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.LuckiestGuy
	t.Text = "HEIST GEAR"
	t.TextColor3 = rgb(255, 200, 80)
	t.Parent = g
	-- the goods on the counter: a box, smoke bombs, a cushion, cans, sneakers, a lockpick roll
	part("DisplayBox", Vector3.new(1.6, 1.4, 1.4), CFrame.new(-3, 4.2, 0), rgb(186, 140, 90), Enum.Material.Cardboard)
	-- (the real thing, as in your hand)
	local function display(id, cf)
		local g = GearService.model(id, base * cf)
		for _, d in g:GetDescendants() do
			if d:IsA("BasePart") then d.Anchored = true end
		end
		g.Parent = m
	end
	for i = 0, 2 do display("SmokeBomb", CFrame.new(-1.6 + i * 0.55, 4, 0.3 - (i % 2) * 0.5)) end
	display("WhoopeeCushion", CFrame.new(0.3, 3.75, 0))
	for i = 0, 2 do display("EnergyDrink", CFrame.new(1.5 + i * 0.6, 4.1, -0.2)) end
	part("Sneaker", Vector3.new(0.7, 0.5, 1.3), CFrame.new(3.3, 3.75, 0.2), rgb(240, 240, 250))
	part("SneakerSole", Vector3.new(0.72, 0.15, 1.32), CFrame.new(3.3, 3.55, 0.2), rgb(80, 180, 255))
	local lamp = part("Lamp", Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, 7.2, 0.4), rgb(255, 240, 200), Enum.Material.Neon, Enum.PartType.Ball)
	local l = Instance.new("PointLight")
	l.Range = 14
	l.Brightness = 1.4
	l.Color = rgb(255, 230, 190)
	l.Parent = lamp
	-- the prompt: open the Shop on the Gear tab
	local spot = part("PromptSpot", Vector3.new(1, 1, 1), CFrame.new(0, 3, 1.8), wood)
	spot.Transparency = 1
	spot.CanCollide = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy Gear"
	prompt.ObjectText = "Janitor Stan's Heist Gear"
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Color", rgb(255, 170, 60))
	prompt.Parent = spot
	prompt.Triggered:Connect(function(player)
		Remotes.Push:FireClient(player, "openPanel", { name = "Shop", tab = 6 })
	end)
	m.Parent = workspace
end

function GearService.start()
	-- the hoverboard: off inside the Factory and Vex Prep (except on the Vex Prep Job), and a new
	-- character starts on foot
	task.spawn(function()
		while true do
			task.wait(0.4)
			for _, player in Players:GetPlayers() do
				if player:GetAttribute("Hover") then
					local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					local pos = root and root.Position
					local RivalService = require(script.Parent.RivalService)
					local blocked = pos and pos.Y > -30 and (
						(pos.X > -33 and pos.X < 33 and pos.Z > 34 and pos.Z < 134) -- (the Factory grounds)
						or (RivalService.inLot(pos) and not player:GetAttribute("VexPrepHeist")))
					if blocked then
						local hum = player.Character:FindFirstChildOfClass("Humanoid")
						if hum then hum:UnequipTools() end
						Remotes.Notify:FireClient(player, "No hoverboards in here! You hop off.", "info")
					end
				end
			end
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function() player:SetAttribute("Hover", nil) end)
	end)
	task.spawn(buildStall)
	local function watch(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.3)
			player:SetAttribute("Boxed", nil)
			GearService.refreshTools(player)
		end)
		task.spawn(function()
			for _ = 1, 40 do
				if Data.get(player) and player:FindFirstChild("Backpack") then break end
				task.wait(0.5)
			end
			GearService.refreshTools(player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do watch(player) end
end

return GearService
