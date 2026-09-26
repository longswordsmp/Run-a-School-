-- ServerScriptService.Server.StoryService
-- The recurring characters who live on Recess Row (docs/DESIGN-v2.md sections 1 and 11.5):
--   Mr. Wobblesworth  at the Hub fountain: tells stories, waves at anyone who comes close
--   Janitor Stan      mops the sidewalk by his Confiscation Closet, drops ominous hints
--   Lunch Lady Loretta at her lunch cart by the fountain
--   Hall Monitor Hector patrols the carpet; whistles at anyone carrying a stolen kid
--   The Sugar Baron   appears on the Sugar Shack roof now and then, rubs his hands, vanishes
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Factory = require(script.Parent.StudentFactory)
local Walkers = require(script.Parent.Walkers)
local Remotes = require(script.Parent.Remotes)

local StoryService = {}
local folder

local LINES = {
	Wobblesworth = {
		"Back in MY day we had ONE desk, and we SHARED it!",
		"Splendid! Simply splendid!",
		"A kid steps off that bus every 2.2 seconds. Every! Single! One!",
		"Catch a cheater and the Board sends you windows. True story.",
		"The Honor Roll Bus comes at half past seven. Every quarter hour!",
		"Lock your gate, young principal. Thieves everywhere.",
		"I founded this street with one pencil. That pencil, in fact.",
	},
	Stan = {
		"I've seen things under those bleachers, kid.",
		"Bust a Snack Smuggler, bring me the candy. I'll build you something nice.",
		"Mop's been in the family three generations.",
		"Somebody's been sneaking slime past the Hall Monitor...",
		"The Sugar Baron? Never met him. Nobody has.",
	},
	Loretta = {
		"Eat your veggies, sweetie.",
		"Mystery meat? That's between me and the meat.",
		"Lunch is at noon. It's always noon somewhere.",
		"You look hungry. Everyone looks hungry.",
	},
	Hector = {
		"NO. RUNNING. IN. THE. HALLS!",
		"Hall pass, please. Hall pass. HALL PASS.",
		"I wrote half the rules. The good half.",
		"This carpet is a PUBLIC hallway.",
	},
	Baron = {
		"Pssst... nice school.",
		"Sweets for my sweets!",
		"Your kids look... HUNGRY.",
	},
}

local function speech(model)
	local head = model:FindFirstChild("Head")
	local bb = Instance.new("BillboardGui")
	bb.Name = "Speech"
	bb.Size = UDim2.fromOffset(260, 70)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 4.4, 0)
	bb.MaxDistance = 70
	bb.LightInfluence = 0
	bb.Enabled = false
	bb.Parent = head
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.fromRGB(255, 252, 240)
	f.Parent = bb
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 14)
	c.Parent = f
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Parent = f
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.Size = UDim2.new(1, -16, 1, -10)
	t.Position = UDim2.fromOffset(8, 5)
	t.BackgroundTransparency = 1
	t.TextWrapped = true
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = Color3.fromRGB(30, 25, 40)
	t.Parent = f
	return bb, t
end

local function nameTag(model, name, title, color)
	local head = model:FindFirstChild("Head")
	local old = head:FindFirstChild("Tag")
	if old then old:Destroy() end
	local bb = Instance.new("BillboardGui")
	bb.Name = "NameTag"
	bb.Size = UDim2.new(8, 0, 1.6, 0)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	bb.MaxDistance = 60
	bb.LightInfluence = 0
	bb.Parent = head
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.RichText = true
	t.Text = ("<font color=\"#%s\">%s</font>\n%s"):format(color:ToHex(), title, name)
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Parent = bb
	local s = Instance.new("UIStroke")
	s.Thickness = 2.5
	s.Parent = t
end

local function say(npc, lines)
	if not npc.bubble then return end
	npc.line = (npc.line or math.random(#lines)) % #lines + 1
	npc.text.Text = lines[npc.line]
	npc.bubble.Enabled = true
	task.delay(5, function()
		if npc.bubble then npc.bubble.Enabled = false end
	end)
end

local function place(model, cf)
	local so = Factory.standOffset(model)
	model.PrimaryPart.CFrame = CFrame.new(cf.Position + Vector3.new(0, so - 0.1, 0)) * cf.Rotation
	model.Parent = folder
	Factory.play(model, "idle")
end

local function nearestPlayer(pos, range)
	local best, bestD
	for _, pl in Players:GetPlayers() do
		local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
		if r then
			local d = (r.Position - pos).Magnitude
			if d < range and (not best or d < bestD) then best, bestD = pl, d end
		end
	end
	return best, bestD
end

local function turnTo(model, pos)
	local root = model.PrimaryPart
	local p = root.Position
	root.CFrame = CFrame.lookAt(p, Vector3.new(pos.X, p.Y, pos.Z))
end

---------------------------------------------------------------------------
local function wobblesworth(spot)
	local m = Factory.buildTeacher({ id = "Wobblesworth", name = "Mr. Wobblesworth", title = "Retired Principal", mult = 1, outfit = "wobble" }, 1)
	m.Name = "Wobblesworth"
	nameTag(m, "Mr. Wobblesworth", "Retired Principal", Color3.fromRGB(255, 210, 90))
	place(m, spot.CFrame)
	local npc = { model = m }
	npc.bubble, npc.text = speech(m)
	local greeted = setmetatable({}, { __mode = "k" })
	task.spawn(function()
		while m.Parent do
			local pl = nearestPlayer(m.PrimaryPart.Position, 16)
			if pl then
				turnTo(m, pl.Character.HumanoidRootPart.Position)
				if not greeted[pl] or os.clock() - greeted[pl] > 60 then
					greeted[pl] = os.clock()
					Factory.emote(m, "wave")
					npc.text.Text = "Ah, " .. pl.DisplayName .. "! Welcome to Recess Row!"
					npc.bubble.Enabled = true
					task.delay(4, function() npc.bubble.Enabled = false end)
					task.wait(5)
				elseif (m:GetAttribute("QuietUntil") or 0) > os.clock() then
					npc.bubble.Enabled = false -- (he's talking someone through a mission)
					task.wait(1)
				else
					say(npc, LINES.Wobblesworth)
					if math.random() < 0.4 then Factory.emote(m, math.random() < 0.5 and "point" or "laugh") end
					task.wait(9 + math.random() * 5)
				end
			else
				m.PrimaryPart.CFrame = spot.CFrame + Vector3.new(0, m.PrimaryPart.Position.Y - spot.Position.Y, 0)
				task.wait(3)
			end
		end
	end)
end

local function stan(spot)
	local m = Factory.buildTeacher({ id = "Stan", name = "Janitor Stan", title = "Janitor", mult = 1, outfit = "stan" }, 1)
	m.Name = "JanitorStan"
	nameTag(m, "Janitor Stan", "Keeper of the Closet", Color3.fromRGB(120, 200, 255))
	place(m, spot.CFrame)
	local npc = { model = m }
	npc.bubble, npc.text = speech(m)
	local y = m.PrimaryPart.Position.Y
	local a = Vector3.new(spot.Position.X - 30, y, -19)
	local b = Vector3.new(spot.Position.X + 30, y, -19)
	task.spawn(function()
		while m.Parent do
			-- mop along the sidewalk, stop, lean, mutter
			for _, target in { a, b } do
				Factory.play(m, "walk")
				local done = false
				Walkers.walk(m, { target }, 4, function() done = true end)
				while not done and m.Parent do task.wait(0.3) end
				Factory.play(m, "idle")
				if math.random() < 0.6 then
					say(npc, LINES.Stan)
					if math.random() < 0.3 then Factory.emote(m, "laugh") end
				end
				task.wait(4 + math.random() * 4)
			end
		end
	end)
end

local function loretta(spot)
	-- her lunch cart
	local cart = Instance.new("Model")
	cart.Name = "LunchCart"
	cart.Parent = folder
	local function p(name, size, cf, color, mat)
		local x = Instance.new("Part")
		x.Name = name
		x.Size = size
		x.CFrame = cf
		x.Color = color
		x.Material = mat or Enum.Material.Plastic
		x.Anchored = true
		x.Parent = cart
		return x
	end
	local base = spot.CFrame * CFrame.new(0, 0, -3.5)
	p("Cart", Vector3.new(7, 3.4, 3.4), base * CFrame.new(0, 2.2, 0), Color3.fromRGB(200, 205, 215), Enum.Material.Metal)
	p("Top", Vector3.new(7.4, 0.3, 3.8), base * CFrame.new(0, 4, 0), Color3.fromRGB(230, 230, 235), Enum.Material.Metal)
	for i, c in { Color3.fromRGB(200, 120, 60), Color3.fromRGB(120, 200, 90), Color3.fromRGB(240, 220, 150) } do
		p("Tray", Vector3.new(1.8, 0.5, 2.4), base * CFrame.new(-2.4 + (i - 1) * 2.4, 4.4, 0), c)
	end
	for _, x in { -3, 3 } do
		p("Post", Vector3.new(0.3, 4, 0.3), base * CFrame.new(x, 6, -1.6), Color3.fromRGB(120, 120, 130), Enum.Material.Metal)
	end
	p("Umbrella", Vector3.new(8, 0.4, 5), base * CFrame.new(0, 8.1, -0.8), Color3.fromRGB(255, 150, 190))
	local m = Factory.buildTeacher({ id = "Loretta", name = "Lunch Lady Loretta", title = "Lunch Lady", mult = 1, outfit = "loretta" }, 1)
	m.Name = "Loretta"
	nameTag(m, "Lunch Lady Loretta", "Cafeteria Legend", Color3.fromRGB(255, 150, 190))
	place(m, spot.CFrame)
	local npc = { model = m }
	npc.bubble, npc.text = speech(m)
	task.spawn(function()
		while m.Parent do
			local pl = nearestPlayer(m.PrimaryPart.Position, 18)
			if pl then
				say(npc, LINES.Loretta)
				if math.random() < 0.5 then Factory.emote(m, math.random() < 0.5 and "wave" or "laugh") end
			end
			task.wait(10 + math.random() * 6)
		end
	end)
end

local function hector()
	local def = { id = "Hector", name = "Hall Monitor Hector", rarity = "Common", price = 0, income = 0, prop = "HectorSash",
		look = { skin = "brown", shirt = Color3.fromRGB(240, 240, 245), pants = Color3.fromRGB(40, 50, 80) } }
	local m = Factory.build(def, "Normal")
	m.Name = "Hector"
	nameTag(m, "Hector", "Head Hall Monitor", Color3.fromRGB(255, 160, 40))
	local so = Factory.standOffset(m)
	local y = 0.4 + so
	m.PrimaryPart.CFrame = CFrame.new(-250, y, -13)
	m.Parent = folder
	local npc = { model = m }
	npc.bubble, npc.text = speech(m)
	local lastWhistle = 0
	-- whistle at carriers
	task.spawn(function()
		while m.Parent do
			task.wait(0.5)
			if os.clock() - lastWhistle > 6 then
				for _, pl in Players:GetPlayers() do
					local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
					if r and pl:GetAttribute("Carrying") and (r.Position - m.PrimaryPart.Position).Magnitude < 25 then
						lastWhistle = os.clock()
						npc.text.Text = "THIEF! NO. RUNNING. IN. THE. HALLS!"
						npc.bubble.Enabled = true
						task.delay(3, function() npc.bubble.Enabled = false end)
						Factory.emote(m, "point")
						Remotes.Sfx:FireAllClients("Whistle", m.PrimaryPart.Position)
						local h = Instance.new("Highlight")
						h.FillColor = Color3.fromRGB(255, 60, 60)
						h.FillTransparency = 0.6
						h.OutlineColor = Color3.new(1, 1, 1)
						h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						h.Parent = pl.Character
						game:GetService("Debris"):AddItem(h, 3)
						break
					end
				end
			end
		end
	end)
	-- patrol the sidewalk
	task.spawn(function()
		while m.Parent do
			for _, x in { 250, -250 } do
				Factory.play(m, "walk")
				local done = false
				Walkers.walk(m, { Vector3.new(x, y, -13) }, 7, function() done = true end)
				local t0 = os.clock()
				while not done and m.Parent do
					task.wait(0.5)
					if os.clock() - t0 > 18 and math.random() < 0.15 then
						t0 = os.clock()
						say(npc, LINES.Hector)
					end
				end
				Factory.play(m, "idle")
				task.wait(3)
			end
		end
	end)
end

local function baron(spot)
	local m = Factory.buildTeacher({ id = "Baron", name = "The Sugar Baron", title = "???", mult = 1, outfit = "baron" }, 1)
	m.Name = "SugarBaron"
	nameTag(m, "The Sugar Baron", "???", Color3.fromRGB(255, 80, 200))
	local npc = { model = m }
	npc.bubble, npc.text = speech(m)
	local function puff(at)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.Transparency = 1
		p.Size = Vector3.one
		p.Position = at
		p.Parent = folder
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(255, 250, 250))
		e.Size = NumberSequence.new(2, 5)
		e.Transparency = NumberSequence.new(0.2, 1)
		e.Speed = NumberRange.new(4, 8)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Lifetime = NumberRange.new(0.8, 1.2)
		e.Rate = 0
		e.Parent = p
		e:Emit(30)
		game:GetService("Debris"):AddItem(p, 2)
	end
	task.spawn(function()
		while true do
			task.wait(50 + math.random() * 40)
			place(m, spot.CFrame)
			puff(spot.Position + Vector3.new(0, 3, 0))
			say(npc, LINES.Baron)
			Factory.emote(m, "laugh")
			task.wait(15)
			puff(m.PrimaryPart.Position)
			m.Parent = nil
		end
	end)
end

---------------------------------------------------------------------------
-- Otis drives every bus: he sits in the parked bus, so every special bus (a clone of it) has him too
---------------------------------------------------------------------------
local function otis()
	local bus = workspace:WaitForChild("Map"):FindFirstChild("SchoolBus")
	if not bus or bus:FindFirstChild("Otis") then return end
	local m = Factory.buildTeacher({ id = "Otis", name = "Otis", title = "Bus Driver", mult = 1, outfit = "otis" }, 1)
	m.Name = "Otis"
	local ws = bus:FindFirstChild("Windshield")
	local body = bus.PrimaryPart
	if not ws or not body then m:Destroy() return end
	-- in the driver's seat behind the windshield, facing out along the bus; high enough that his
	-- head and shoulders clear the hood and show through the glass
	local seat = Vector3.new(ws.Position.X - 2.4, ws.Position.Y - ws.Size.Y / 2 - 0.3, body.Position.Z + 2.6)
	local hrp = m.PrimaryPart
	hrp.CFrame = CFrame.lookAt(seat, seat + Vector3.new(1, 0, 0))
	m.Parent = bus
	Factory.play(m, "sit")
end

---------------------------------------------------------------------------
-- Dr. Vex's limo: every 15 minutes it cruises the street and stops at the poorest school
---------------------------------------------------------------------------
local VEX_LINES = {
	"Cute school. Shame about... everything.",
	"Tick tock, Principal. Tick. Tock.",
	"My Homework Factory will go RIGHT THERE.",
	"Recess is a waste of good homework time.",
	"Is that a school or a shoebox?",
	"I'll buy it. I'll buy ALL of it.",
}
local function buildLimo()
	local limo = Instance.new("Model")
	limo.Name = "VexLimo"
	local function p(name, size, cf, color, mat, shape)
		local x = Instance.new("Part")
		x.Name = name
		x.Size = size
		x.CFrame = cf
		x.Color = color
		x.Material = mat or Enum.Material.SmoothPlastic
		x.Anchored = true
		x.CanCollide = false
		if shape then x.Shape = shape end
		x.Parent = limo
		return x
	end
	-- a long black stretch limo: front +X, chrome everywhere, purple underglow and flags
	local black = Color3.fromRGB(20, 20, 26)
	local chrome = Color3.fromRGB(210, 212, 222)
	local tint = Color3.fromRGB(34, 30, 48)
	local front = CFrame.Angles(0, math.rad(-90), 0) -- (wedges sloping down towards +X)
	local back = CFrame.Angles(0, math.rad(90), 0) -- (wedges sloping down towards -X)
	local function wedge(name, size, cf, color, mat)
		local w = Instance.new("WedgePart")
		w.Name = name
		w.Size = size
		w.CFrame = cf
		w.Color = color
		w.Material = mat or Enum.Material.Metal
		w.Anchored, w.CanCollide = true, false
		w.Parent = limo
		return w
	end
	local function wheel(x, z)
		local r = CFrame.new(x, 1.5, z) * CFrame.Angles(0, math.rad(90), 0) -- (round faces across the car)
		p("Wheel", Vector3.new(1.2, 3, 3), r, Color3.fromRGB(15, 15, 17), nil, Enum.PartType.Cylinder)
		p("Rim", Vector3.new(1.26, 1.8, 1.8), r, chrome, Enum.Material.Metal, Enum.PartType.Cylinder)
		p("RimCap", Vector3.new(1.3, 0.6, 0.6), r, Color3.fromRGB(120, 50, 170), Enum.Material.Metal, Enum.PartType.Cylinder)
	end
	local body = p("Body", Vector3.new(30, 3, 8), CFrame.new(0, 2.5, 0), black, Enum.Material.Metal)
	limo.PrimaryPart = body
	-- the long cabin with a raked windshield and a sloping back window
	p("Cabin", Vector3.new(19, 2.6, 7.4), CFrame.new(-1.5, 5.3, 0), black, Enum.Material.Metal)
	wedge("Windshield", Vector3.new(7.2, 2.6, 2.4), CFrame.new(9.2, 5.3, 0) * front, tint, Enum.Material.Glass)
	wedge("BackWindow", Vector3.new(7.2, 2.6, 2), CFrame.new(-12, 5.3, 0) * back, tint, Enum.Material.Glass)
	wedge("Hood", Vector3.new(7.8, 0.5, 4.6), CFrame.new(12.7, 4.25, 0) * front, black)
	for _, z in { -3.72, 3.72 } do
		-- tinted windows in chrome frames, a chrome belt line and a sill
		p("WindowFrame", Vector3.new(17.4, 2, 0.06), CFrame.new(-1.5, 5.35, z), chrome, Enum.Material.Metal)
		for i = 0, 3 do
			p("Windows", Vector3.new(3.9, 1.7, 0.06), CFrame.new(-8.7 + i * 4.3, 5.35, z * 1.016), tint, Enum.Material.Glass)
		end
		p("Chrome", Vector3.new(30, 0.2, 0.1), CFrame.new(0, 3.95, z * 1.077), chrome, Enum.Material.Metal)
		p("Sill", Vector3.new(22, 0.3, 0.1), CFrame.new(0, 1.3, z * 1.077), chrome, Enum.Material.Metal)
	end
	-- the front: a tall chrome grille, rectangular lights, a bumper; flags on the fenders
	p("Grille", Vector3.new(0.2, 2, 3.6), CFrame.new(15.05, 2.6, 0), chrome, Enum.Material.Metal)
	for i = -3, 3 do p("GrilleBar", Vector3.new(0.12, 1.8, 0.12), CFrame.new(15.2, 2.6, i * 0.45), Color3.fromRGB(40, 40, 50), Enum.Material.Metal) end
	for _, z in { -2.9, 2.9 } do
		p("Headlight", Vector3.new(0.3, 0.6, 1.6), CFrame.new(15.1, 3.1, z), Color3.fromRGB(255, 250, 220), Enum.Material.Neon)
		p("Taillight", Vector3.new(0.3, 0.7, 1.6), CFrame.new(-15.1, 3.1, z), Color3.fromRGB(220, 30, 40), Enum.Material.Neon)
		p("FlagPole", Vector3.new(0.12, 2, 0.12), CFrame.new(13.8, 5, z * 1.2), chrome, Enum.Material.Metal)
		p("Flag", Vector3.new(1.4, 0.9, 0.05), CFrame.new(13.1, 5.5, z * 1.2), Color3.fromRGB(140, 50, 210), Enum.Material.Fabric)
	end
	p("Bumper", Vector3.new(0.6, 0.7, 8.2), CFrame.new(15.3, 1.4, 0), chrome, Enum.Material.Metal)
	p("RearBumper", Vector3.new(0.6, 0.7, 8.2), CFrame.new(-15.3, 1.4, 0), chrome, Enum.Material.Metal)
	for _, x in { -11, 11 } do
		for _, z in { -3.75, 3.75 } do wheel(x, z) end
	end
	local plate = p("Plate", Vector3.new(0.2, 1, 3), CFrame.new(-15.2, 2.3, 0), Color3.fromRGB(250, 250, 240))
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Left
	g.Parent = plate
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.Arcade
	t.Text = "VEX 1"
	t.TextColor3 = Color3.fromRGB(90, 30, 130)
	t.Parent = g
	-- underglow
	p("Underglow", Vector3.new(28, 0.2, 7), CFrame.new(0, 0.7, 0), Color3.fromRGB(170, 60, 255), Enum.Material.Neon)
	-- Vex stands up through the sunroof
	local vex = Factory.buildTeacher({ id = "Vex", name = "Dr. Veronica Vex", title = "VexCorp CEO", mult = 1, outfit = "vex" }, 1)
	vex.Name = "Vex"
	local so = Factory.standOffset(vex)
	-- feet just under the roof line (cabin top is y 6.7), so she stands out of the sunroof from the knees up
	vex.PrimaryPart.CFrame = CFrame.new(3, 5.2 + so, 0) * CFrame.Angles(0, math.rad(-90), 0)
	p("Sunroof", Vector3.new(3.2, 0.3, 3.2), CFrame.new(3, 6.8, 0), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
	vex.Parent = limo
	nameTag(vex, "Dr. Veronica Vex", "VexCorp CEO", Color3.fromRGB(190, 110, 255))
	return limo, vex
end

local function vexDriveBy()
	local PlotService = require(script.Parent.PlotService)
	local Data = require(script.Parent.DataService)
	-- the poorest school with an owner
	local target, lowest
	for player in Data.all() do
		local plot = PlotService.getPlot(player)
		local inc = player:GetAttribute("BaseIncome") or 0
		if plot and (not lowest or inc < lowest) then target, lowest = plot, inc end
	end
	local limo, vex = buildLimo()
	-- the sidewalk on the target school's side of the street, clear of the carpet
	local z = (target and target.Origin.Position.Z < 0) and -19 or 19
	-- facing along the street; Vex turns to the school when the limo stops
	local function at(x) return CFrame.new(x, 0, z) end
	limo:PivotTo(at(-460))
	limo.Parent = folder
	local npc = { model = vex }
	npc.bubble, npc.text = speech(vex)
	Remotes.Sfx:FireAllClients("BusHorn")
	local stopX = target and target.Origin.Position.X or 0
	local function drive(fromX, toX, speed)
		local dist = math.abs(toX - fromX)
		local t0, dur = os.clock(), dist / speed
		while true do
			local a = math.min(1, (os.clock() - t0) / dur)
			limo:PivotTo(at(fromX + (toX - fromX) * a))
			if a >= 1 then break end
			task.wait()
		end
	end
	drive(-460, stopX, 40)
	-- stop, turn to the school, deliver a line
	if target then
		local vr = vex.PrimaryPart
		vr.CFrame = CFrame.lookAt(vr.Position, Vector3.new(target.Origin.Position.X, vr.Position.Y, target.Origin.Position.Z))
	end
	npc.text.Text = VEX_LINES[math.random(#VEX_LINES)]
	npc.bubble.Enabled = true
	Factory.emote(vex, "point")
	task.wait(6)
	npc.bubble.Enabled = false
	drive(stopX, 460, 40)
	limo:Destroy()
end

StoryService.buildLimo = buildLimo -- (StreetService parks one at the plaza)

function StoryService.start()
	folder = workspace:FindFirstChild("StoryNPCs") or Instance.new("Folder")
	folder.Name = "StoryNPCs"
	folder.Parent = workspace
	local lm = workspace:WaitForChild("Map"):FindFirstChild("Landmarks")
	if not lm then return end
	local function spotOf(name)
		local model = lm:FindFirstChild(name)
		return model and model:FindFirstChild("NPCSpot")
	end
	local function run(fn, ...)
		local ok, err = pcall(fn, ...)
		if not ok then warn("[Story]", err) end
	end
	local fountain = spotOf("HubFountain")
	if fountain then
		run(wobblesworth, fountain)
		-- Loretta's cart on the far side of the fountain
		local lspot = Instance.new("Part")
		lspot.Anchored, lspot.CanCollide, lspot.Transparency = true, false, 1
		lspot.Size = Vector3.one
		lspot.CFrame = CFrame.new(-14, 0.6, -70) * CFrame.Angles(0, math.rad(200), 0)
		lspot.Parent = folder
		run(loretta, lspot)
	end
	local closet = spotOf("ConfiscationCloset")
	if closet then run(stan, closet) end
	run(hector)
	local shack = spotOf("SugarShack")
	if shack then run(baron, shack) end
	run(otis)
	-- Vex every 15 minutes, on the clock (:05, :20, :35, :50 UTC)
	task.spawn(function()
		local now = workspace:GetServerTimeNow()
		local nextAt = 300 + 900 * math.ceil((now - 300) / 900)
		while true do
			task.wait(1)
			if workspace:GetServerTimeNow() >= nextAt then
				nextAt += 900
				if #Players:GetPlayers() > 0 then run(vexDriveBy) end
			end
		end
	end)
end

-- test hook
function StoryService.debugVex()
	task.spawn(vexDriveBy)
	return true
end

return StoryService
