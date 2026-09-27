-- StarterPlayer.StarterPlayerScripts.Cutscene
-- Client cutscenes fired by Remotes.Cutscene(name, data).
--   Board: the School Board meets in the Board Room (workspace.BoardRoom, high above the map),
--          bangs the gavel and approves your school while the server rebuilds it underneath.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Config = require(Shared:WaitForChild("Config"))
local Limo = require(Shared:WaitForChild("Limo"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local bus = ReplicatedStorage:WaitForChild("ClientBus", 10)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local gui = UI.new("ScreenGui", {
	Name = "Cutscene",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 50,
	Parent = player:WaitForChild("PlayerGui"),
})
local uiRoot, uiScale = UI.autoScale(gui)
local black = UI.new("Frame", {
	Name = "Black",
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 1,
	Parent = gui,
})
-- letterbox bars
local bars = {}
for i, y in { 0, 1 } do
	bars[i] = UI.new("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		AnchorPoint = Vector2.new(0, y),
		Position = UDim2.fromScale(0, y),
		Size = UDim2.new(1, 0, 0, 0),
		ZIndex = 2,
		Parent = gui,
	})
end

local function sfx(name, pos)
	if bus and bus:FindFirstChild("Sfx") then bus.Sfx:Fire(name, pos) end
end

-- a mumble blip in this speaker's voice (Audio.client)
local function talk(speaker)
	if bus and bus:FindFirstChild("Talk") then bus.Talk:Fire(speaker) end
end

local function fade(to, t)
	local tw = TweenService:Create(black, TweenInfo.new(t or 0.35), { BackgroundTransparency = to })
	tw:Play()
	tw.Completed:Wait()
end

local function letterbox(on)
	for _, b in bars do
		TweenService:Create(b, TweenInfo.new(0.4), { Size = UDim2.new(1, 0, on and 0.11 or 0, 0) }):Play()
	end
end

local function caption(text, color, y, size)
	local t = UI.label(gui, {
		Text = text,
		Font = UI.BIG,
		TextColor3 = color or Color3.new(1, 1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, y or 0.8),
		Size = UDim2.new(0.8, 0, 0, size or 60),
		ZIndex = 5,
		stroke = 4,
	})
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(1000, size or 60), Parent = t })
	UI.pop(t, 0.3)
	return t
end

-- confetti: small coloured squares falling over the screen
local function confetti(n)
	local colors = { UI.C.red, UI.C.blue, UI.C.green, UI.C.yellow, UI.C.pink, UI.C.purple, UI.C.orange }
	for _ = 1, n do
		local s = math.random(8, 16)
		local f = UI.new("Frame", {
			BackgroundColor3 = colors[math.random(#colors)],
			Size = UDim2.fromOffset(s, s * 0.6),
			Position = UDim2.new(math.random(), 0, -0.05, 0),
			Rotation = math.random(0, 360),
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = gui,
		})
		local t = 1.6 + math.random() * 1.4
		TweenService:Create(f, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(f.Position.X.Scale + (math.random() - 0.5) * 0.2, 0, 1.05, 0),
			Rotation = f.Rotation + math.random(-360, 360),
		}):Play()
		task.delay(t, function() f:Destroy() end)
	end
end

-- a stand-in of the player at the podium (a local clone of their character)
local function standIn(at)
	local char = player.Character
	if not char then return nil end
	char.Archivable = true
	local ok, clone = pcall(function() return char:Clone() end)
	if not ok or not clone then return nil end
	for _, d in clone:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
		if d:IsA("BasePart") then d.Anchored = true end
	end
	local hum = clone:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
	clone:PivotTo(at)
	clone:SetAttribute("Ambient", true) -- (moved here, not by the server: Smooth leaves it alone)
	clone.Parent = workspace
	return clone
end

-- hide the game's own HUD and menus while a cutscene plays
local hidden = {}
local function hideHud(on)
	local pg = player:FindFirstChild("PlayerGui")
	if not pg then return end
	if on then
		for _, name in { "HUD", "Menus", "NowPlaying", "Prompts", "Quests", "Chapters", "QuestLog", "Mission" } do
			local g = pg:FindFirstChild(name)
			if g and g.Enabled then
				g.Enabled = false
				hidden[g] = true
			end
		end
	else
		for g in hidden do
			if g.Parent then g.Enabled = true end
		end
		hidden = {}
	end
end

local function dialogBox(speaker, templateId)
	local box = UI.new("Frame", {
		Name = "Dialog",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.new(0.7, 0, 0, 150),
		BackgroundColor3 = UI.C.cream,
		ZIndex = 6,
		Parent = gui,
	})
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(900, 150), Parent = box })
	UI.corner(box, 18)
	UI.stroke(box, 4)
	local portrait = UI.new("Frame", {
		Size = UDim2.fromOffset(120, 120),
		Position = UDim2.fromOffset(14, 15),
		BackgroundColor3 = Color3.fromRGB(80, 60, 140),
		ZIndex = 7,
		Parent = box,
	})
	UI.corner(portrait, 14)
	UI.stroke(portrait, 3)
	local function fill(chair)
		if not chair or not portrait.Parent then return end
		local vp, m = UI.viewport(portrait, chair, { zindex = 8, zoom = 0.55 })
		-- frame the head and shoulders
		local cam = vp.CurrentCamera
		local head = m and m:FindFirstChild("Head")
		if head and cam then
			cam.CFrame = CFrame.lookAt(head.Position + Vector3.new(0, 0.1, -4.2), head.Position + Vector3.new(0, -0.3, 0))
		end
	end
	local tt = ReplicatedStorage:FindFirstChild("TeacherTemplates")
	local st = ReplicatedStorage:FindFirstChild("StudentTemplates")
	local chair = (tt and tt:FindFirstChild(templateId or "DeanMaximus")) or (st and templateId and st:FindFirstChild(templateId))
	if chair then
		fill(chair)
	else
		-- (the very first cutscene can beat the templates to the client: fill in when they land)
		task.spawn(function()
			local id = templateId or "DeanMaximus"
			local tf = ReplicatedStorage:WaitForChild("TeacherTemplates", 8)
			local found = tf and tf:WaitForChild(id, templateId and 2 or 8)
			if not found then
				local sf = ReplicatedStorage:WaitForChild("StudentTemplates", 4)
				found = sf and sf:FindFirstChild(id)
			end
			fill(found)
		end)
	end
	UI.label(box, { Text = speaker or "THE BOARD CHAIR", Font = UI.BIG, TextColor3 = UI.C.purple, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -170, 0, 30), Position = UDim2.fromOffset(150, 12), ZIndex = 7, stroke = 2 })
	local text = UI.label(box, { Text = "", TextColor3 = UI.C.ink, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, TextScaled = false, TextSize = 26, Size = UDim2.new(1, -170, 0, 80), Position = UDim2.fromOffset(150, 48), ZIndex = 7, stroke = 0 })
	local hint = UI.label(box, { Text = "click to continue", TextColor3 = UI.C.grey, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0, 200, 0, 18), Position = UDim2.new(1, -212, 1, -24), ZIndex = 7, stroke = 0 })
	UI.pop(box, 0.6)
	return box, text, hint
end

-- one story line in the dialog box: typed at 40 characters a second, held, then gone
local function sayLine(speaker, templateId, line)
	local box, text, hint = dialogBox(speaker, templateId)
	hint.Visible = false
	for c = 1, #line do
		text.Text = line:sub(1, c)
		if c % 2 == 0 and line:sub(c, c) ~= " " then talk(speaker) end
		task.wait(0.025)
	end
	task.wait(math.clamp(#line * 0.03, 1.1, 2.2))
	box:Destroy()
end

local busy = false
local lastDouble
local function board(data)
	if busy then return end
	busy = true
	local room = workspace:FindFirstChild("BoardRoom")
	if not room then busy = false return end
	player:SetAttribute("LocalMusic", "board")
	fade(0, 0.35)
	hideHud(true)
	letterbox(true)
	local mark = room.PlayerMark
	local podiumLook = CFrame.lookAt(mark.Position + Vector3.new(0, 0.1, 0), room.Table.Position * Vector3.new(1, 0, 1) + Vector3.new(0, mark.Position.Y + 0.1, 0))
	local double = standIn(podiumLook)
	lastDouble = double
	local prevType, prevCF = camera.CameraType, camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	local target = room.Table.Position + Vector3.new(0, 1.5, 0)
	camera.CFrame = CFrame.lookAt(room.CameraA.Position, target)
	fade(1, 0.35)
	local c1 = caption("THE SCHOOL BOARD IS IN SESSION", Color3.fromRGB(255, 225, 120), 0.8, 54)
	sfx("Gavel")
	-- slow push toward the table
	local push = TweenService:Create(camera, TweenInfo.new(1.6, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(room.CameraA.Position:Lerp(target, 0.35), target) })
	push:Play()
	task.wait(1.5)
	push:Cancel()
	c1:Destroy()
	-- close on the chair and the gavel
	camera.CFrame = CFrame.lookAt(room.CameraB.Position, room.Gavel.Position + Vector3.new(-2, 1.5, 0))
	local gavel = room.Gavel
	local g0 = gavel.CFrame
	TweenService:Create(gavel, TweenInfo.new(0.15), { CFrame = g0 * CFrame.new(0, 1.2, 0) * CFrame.Angles(math.rad(-40), 0, 0) }):Play()
	task.wait(0.2)
	TweenService:Create(gavel, TweenInfo.new(0.08), { CFrame = g0 }):Play()
	task.wait(0.08)
	sfx("GavelBig")
	-- a quick camera shake on the bang
	local shakeUntil = os.clock() + 0.25
	local base = camera.CFrame
	local conn = RunService.RenderStepped:Connect(function()
		if os.clock() < shakeUntil then
			camera.CFrame = base * CFrame.new((math.random() - 0.5) * 0.3, (math.random() - 0.5) * 0.3, 0)
		end
	end)
	task.wait(0.3)
	conn:Disconnect()
	-- the story beat for this promotion (Kevin gets a close-up for his lines)
	local beat = data and not data.star and Config.BoardBeats[data.tier]
	for _, b in beat or {} do
		local kevin = room:FindFirstChild("Members") and room.Members:FindFirstChild("BoardKevin")
		local head = kevin and kevin:FindFirstChild("Head")
		if b[2] == "Kevin" and head then
			-- in front of him, across the table
			camera.CFrame = CFrame.lookAt(head.Position + head.CFrame.LookVector * 5.5 + Vector3.new(0, 0.6, 0), head.Position)
		else
			camera.CFrame = CFrame.lookAt(room.CameraA.Position:Lerp(target, 0.25), target)
		end
		sayLine(b[1], b[2], b[3])
		if b[3] == "No." then sfx("SadTrombone") end
	end
	-- approved!
	camera.CFrame = CFrame.lookAt(room.CameraA.Position:Lerp(target, 0.5), mark.Position + Vector3.new(0, 2, 0))
	sfx("StingParty")
	local c2 = caption("APPROVED!", UI.C.green, 0.42, 96)
	local c3 = caption(("Welcome to %s!"):format((data and data.name) or "your new school"), Color3.new(1, 1, 1), 0.56, 48)
	local line = data and (data.star and Config.BoardLines.star or Config.BoardLines[data.tier])
	local c4 = line and caption("\"" .. line .. "\"", Color3.fromRGB(255, 230, 150), 0.68, 34)
	confetti(90)
	task.wait(2.6)
	if c4 then c4:Destroy() end
	fade(0, 0.35)
	c2:Destroy()
	c3:Destroy()
	if double then double:Destroy() end
	camera.CameraType = prevType
	camera.CFrame = prevCF
	letterbox(false)
	hideHud(false)
	player:SetAttribute("LocalMusic", nil)
	task.wait(0.4)
	fade(1, 0.5)
	sfx("Cheer")
	busy = false
end

---------------------------------------------------------------------------
-- Intro, "The Keys": a brand-new principal's first half minute, so nothing that happens after it comes
-- out of nowhere.
--   1  high over Recess Row, pushing in on your empty school
--   2  at your gate: Mr. Wobblesworth, retiring after forty years, hands you the keys
--   3  Dr. Vex's limo glides up (her butler Crumpet riding on the back): every kid on the street
--      will be at HER school by summer
--   4  Wobblesworth: who she is, and that Crumpet does her dirty work
--   5  Otis's Welcome Bus honks up with your first kids; you take over
-- The server sends the Welcome Bus when this asks (Action "introBus"), so it pulls up on cue.
-- Click to hurry a line along; SKIP ends the whole thing. data: { gate, park, side, stand, row }
---------------------------------------------------------------------------
local ANIM = {
	idle = "rbxassetid://507766388", wave = "rbxassetid://507770239", point = "rbxassetid://507770453",
	laugh = "rbxassetid://507770818", sit = "rbxassetid://2506281703",
}

-- a local stand-in of a cast member, standing with its feet at `at` and facing `face`
local function actor(templateId, at, face)
	local tt = ReplicatedStorage:FindFirstChild("TeacherTemplates")
	local t = tt and tt:FindFirstChild(templateId)
	if not t then return nil end
	local m = t:Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
		if d:IsA("BasePart") then d.CanCollide = false d.CanQuery = false end
	end
	local root = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart")
	local hum = m:FindFirstChildOfClass("Humanoid")
	if not root or not hum then m:Destroy() return nil end
	root.Anchored = true
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	if not hum:FindFirstChildOfClass("Animator") then Instance.new("Animator").Parent = hum end
	local so = hum.HipHeight + root.Size.Y / 2
	local pos = at + Vector3.new(0, so, 0)
	m:PivotTo(CFrame.lookAt(pos, Vector3.new(face.X, pos.Y, face.Z)))
	-- (moved by this scene, not by the server: Smooth, which redraws server NPCs a moment behind, left
	-- Vex and Crumpet stranded in the road when the limo carried them off)
	m:SetAttribute("Ambient", true)
	m.Parent = workspace
	return m
end

local function pose(m, which, looped)
	local hum = m and m:FindFirstChildOfClass("Humanoid")
	local an = hum and hum:FindFirstChildOfClass("Animator")
	if not an or not ANIM[which] then return end
	local a = Instance.new("Animation")
	a.AnimationId = ANIM[which]
	local ok, track = pcall(function() return an:LoadAnimation(a) end)
	if ok and track then
		track.Looped = looped == true
		track:Play(0.2)
	end
	return track
end

-- the big brass key Wobblesworth hands over
local function makeKey()
	local m = Instance.new("Model")
	m.Name = "IntroKey"
	local gold = Color3.fromRGB(240, 196, 70)
	local function kp(name, size, cf, shape, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color or gold
		p.Material = Enum.Material.Metal
		p.Reflectance = 0.15
		p.Anchored, p.CanCollide, p.CanQuery, p.CastShadow = true, false, false, false
		if shape then p.Shape = shape end
		p.Parent = m
		return p
	end
	local bow = kp("Bow", Vector3.new(0.18, 1, 1), CFrame.new(0, 0.9, 0) * CFrame.Angles(0, math.rad(90), 0), Enum.PartType.Cylinder)
	kp("Hole", Vector3.new(0.2, 0.45, 0.45), CFrame.new(0, 0.9, 0) * CFrame.Angles(0, math.rad(90), 0), Enum.PartType.Cylinder, Color3.fromRGB(60, 45, 20))
	kp("Shaft", Vector3.new(0.18, 1.4, 0.18), CFrame.new(0, -0.2, 0))
	kp("Tooth", Vector3.new(0.14, 0.18, 0.4), CFrame.new(0, -0.7, 0.2))
	kp("Tooth2", Vector3.new(0.14, 0.18, 0.28), CFrame.new(0, -0.45, 0.14))
	m.PrimaryPart = bow
	return m
end

local function intro(data)
	if busy then return end
	busy = true
	data = type(data) == "table" and data or {}
	local plotName = player:GetAttribute("Plot")
	local plot = plotName and workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(plotName)
	local origin = plot and plot:FindFirstChild("Origin")
	local ocf = origin and origin.CFrame or CFrame.new()
	local side = data.side or (ocf.Position.Z >= 0 and 1 or -1)
	local gate = typeof(data.gate) == "Vector3" and data.gate or Vector3.new(ocf.Position.X, 0, side * 23)
	local park = typeof(data.park) == "Vector3" and data.park or gate - Vector3.new(20, 0, side * 8)
	local school = ocf.Position + Vector3.new(0, 12, 0)
	local ground = 0.4
	local cast = {} -- everything this scene put in the world
	local skipped = false

	fade(0, 0.25)
	hideHud(true)
	letterbox(true)
	camera.CameraType = Enum.CameraType.Scriptable
	pcall(function() player:RequestStreamAroundAsync(gate, 3) end)

	-- the SKIP button, and a click anywhere hurries the current line
	local skipBtn = UI.button(gui, { text = "SKIP \u{25B6}\u{25B6}", color = Color3.fromRGB(60, 60, 75), size = UDim2.fromOffset(150, 46), position = UDim2.new(1, -24, 0, 24), anchor = Vector2.new(1, 0) })
	skipBtn.button.ZIndex = 30
	for _, d in skipBtn.button:GetDescendants() do if d:IsA("GuiObject") then d.ZIndex = 31 end end
	local clickLayer = UI.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = gui })
	local clicked = false
	clickLayer.Activated:Connect(function() clicked = true end)
	skipBtn.button.Activated:Connect(function() skipped = true clicked = true end)

	-- one line in the dialog box: typed in the speaker's voice, then held (a click hurries both)
	local function say(speaker, template, line, hold)
		if skipped then return end
		local box, text, hint = dialogBox(speaker, template)
		clicked = false
		hint.Visible = false
		for c = 1, #line do
			if clicked or skipped then break end
			text.Text = line:sub(1, c)
			if c % 2 == 0 and line:sub(c, c) ~= " " then talk(speaker) end
			task.wait(0.026)
		end
		text.Text = line
		clicked = false
		hint.Visible = true
		local t0 = os.clock()
		while not clicked and not skipped and os.clock() - t0 < (hold or 1.6) do task.wait(0.05) end
		box:Destroy()
	end
	local function wait(t)
		local t0 = os.clock()
		while not skipped and os.clock() - t0 < t do task.wait(0.05) end
	end

	-- where everyone stands: you just inside your gate, Mr. Wobblesworth between you and the street
	local inward = Vector3.new(0, 0, side)
	-- (well inside the gate: nearer, the arch and its posts cut through the two-shot)
	local youAt = Vector3.new(gate.X, ground, gate.Z) + inward * 11
	local wobAt = Vector3.new(gate.X, ground, gate.Z) + inward * 6.4
	local wob = actor("Wobblesworth", wobAt, youAt)
	table.insert(cast, wob)
	pose(wob, "idle", true)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		local so = hum and (hum.HipHeight + root.Size.Y / 2) or 3
		player.Character:PivotTo(CFrame.lookAt(youAt + Vector3.new(0, so, 0), Vector3.new(wobAt.X, youAt.Y + so, wobAt.Z)))
	end
	-- the key, in his hand
	local key = makeKey()
	table.insert(cast, key)
	local hand = wob and (wob:FindFirstChild("RightHand") or wob:FindFirstChild("Right Arm"))
	if hand then key:PivotTo(hand.CFrame * CFrame.new(0, -0.6, -0.3)) end
	key.Parent = workspace

	-- 1: over Recess Row, onto your empty school
	camera.CFrame = CFrame.lookAt(gate + Vector3.new(-46, 58, -side * 62), school)
	fade(1, 0.5)
	sfx("StingMorning")
	local push = TweenService:Create(camera, TweenInfo.new(3.6, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(gate + Vector3.new(-22, 26, -side * 36), school) })
	push:Play()
	local c1 = caption("RECESS ROW", Color3.new(1, 1, 1), 0.22, 64)
	local c2 = caption("Your first day as Principal", Color3.fromRGB(255, 225, 140), 0.31, 34)
	wait(3.2)
	-- (stop the push before cutting away, or it keeps pulling the camera back to the sky)
	push:Cancel()
	c1:Destroy()
	c2:Destroy()

	-- 2: at the gate, the keys
	local mid = (wobAt + youAt) / 2 + Vector3.new(0, 4.2, 0)
	local sideways = Vector3.new(1, 0, 0)
	-- (over Mr. Wobblesworth's shoulder at you, your school behind you; the gate is behind the camera)
	local twoShot = CFrame.lookAt(wobAt + sideways * 4.5 - inward * 2.5 + Vector3.new(0, 5.6, 0),
		(youAt + Vector3.new(0, 4.4, 0)):Lerp(wobAt + Vector3.new(0, 4.4, 0), 0.35))
	camera.CFrame = twoShot
	pose(wob, "wave")
	say("MR. WOBBLESWORTH", "Wobblesworth", "Ah, the new Principal! Mr. Wobblesworth. I ran this old school for forty years.", 1.8)
	say("MR. WOBBLESWORTH", "Wobblesworth", "It's yours now. Empty, I'm afraid... but every great school starts with one kid.", 1.4)
	say("MR. WOBBLESWORTH", "Wobblesworth", "I'm retiring. But the School Board gave me one last job: train my replacement. That's you!", 1.8)
	say("MR. WOBBLESWORTH", "Wobblesworth", "I'll coach you until your first Board review. After that, the school is all yours.", 1.6)
	-- the key goes from his hand to yours
	local yourHand = player.Character and (player.Character:FindFirstChild("RightHand") or player.Character:FindFirstChild("Right Arm"))
	if yourHand and key.PrimaryPart then
		local to = yourHand.CFrame * CFrame.new(0, -0.6, -0.3)
		local t0 = os.clock()
		local from = key:GetPivot()
		while os.clock() - t0 < 0.6 and not skipped do
			local a = (os.clock() - t0) / 0.6
			key:PivotTo(from:Lerp(to, a) + Vector3.new(0, math.sin(a * math.pi) * 1.2, 0))
			task.wait()
		end
		key:PivotTo(to)
		sfx("Coin")
	end
	wait(0.6)

	-- 3: the limo glides up the street and stops at your gate, Crumpet at the wheel and Vex in the back.
	-- Her door swings open and she's out on the pavement beside it; after her piece she's back in, the
	-- door shuts, and they're away. (Shared/Limo: she used to stand up out of a sunroof from the knees,
	-- and Crumpet stood on nothing behind the boot.)
	local limo
	local laneZ = side * 6 -- (your side's lane of the road)
	-- (the limo's pivot is its body's middle, 2.5 above its wheels' contact)
	local function limoAt(x) return CFrame.new(x, ground + 2.4, laneZ) end
	local function stopAll(m)
		local hum = m and m:FindFirstChildOfClass("Humanoid")
		local an = hum and hum:FindFirstChildOfClass("Animator")
		if an then for _, tr in an:GetPlayingAnimationTracks() do tr:Stop(0.1) end end
	end
	local vex, crumpet
	if not skipped then
		limo = Limo.build(side)
		limo:PivotTo(limoAt(gate.X - 90))
		limo.Parent = workspace
		table.insert(cast, limo)
		vex = actor("Vex", youAt, youAt)
		crumpet = actor("Crumpet", youAt, youAt)
		for _, rider in { { vex, "VexSeat" }, { crumpet, "DriverSeat" } } do
			if rider[1] then
				table.insert(cast, rider[1])
				Limo.seat(limo, rider[1], rider[2])
				pose(rider[1], "sit", true)
			end
		end
		-- over your shoulder, looking out through the gate at the street
		local behind = youAt + inward * 9 + Vector3.new(4, 7, 0)
		camera.CFrame = CFrame.lookAt(behind, Vector3.new(gate.X, 3, laneZ))
		sfx("BusHorn")
		local t0 = os.clock()
		local dur = 3.2
		while os.clock() - t0 < dur and not skipped do
			local a = (os.clock() - t0) / dur
			local e = 1 - (1 - a) * (1 - a) -- (easing to a stop)
			limo:PivotTo(limoAt(gate.X - 90 + 90 * e))
			task.wait()
		end
		local stop = limoAt(gate.X)
		limo:PivotTo(stop)
		-- her door swings open (from the pavement, down the side of the car)
		local doorAt = (stop * CFrame.new(-3, 1.2, side * 4)).Position
		camera.CFrame = CFrame.lookAt(doorAt + Vector3.new(9, 2.2, side * 8), doorAt)
		wait(0.35)
		Limo.door(limo, side, true, 0.45)
		wait(0.8)
		-- cut: she's out, on the pavement behind the open door, facing your school
		local outAt = Vector3.new((stop * CFrame.new(-5.4, 0, 0)).Position.X, ground, laneZ + side * 6.6)
		if vex and vex.PrimaryPart then
			stopAll(vex)
			local hum = vex:FindFirstChildOfClass("Humanoid")
			local so = hum.HipHeight + vex.PrimaryPart.Size.Y / 2
			vex.PrimaryPart.CFrame = CFrame.lookAt(outAt + Vector3.new(0, so, 0), Vector3.new(youAt.X, outAt.Y + so, youAt.Z))
			pose(vex, "idle", true)
		end
		-- Vex face on, her limo and its open door behind her
		local vexHead = outAt + Vector3.new(0, 5.2, 0)
		local vexShot = CFrame.lookAt(outAt + Vector3.new(4.5, 5.6, side * 8.5), vexHead)
		camera.CFrame = vexShot
		pose(vex, "point")
		say("DR. VERONICA VEX", "Vex", "Enjoy your little school while it lasts, Principal.", 1.2)
		say("DR. VERONICA VEX", "Vex", "By summer, every kid on Recess Row will be at MY school.", 1.6)
		-- Crumpet at the wheel, through his open window
		local crumpetHead = crumpet and crumpet:FindFirstChild("Head") and crumpet.Head.Position or (stop * CFrame.new(4.1, 3.4, side * 1.8)).Position
		camera.CFrame = CFrame.lookAt(crumpetHead + Vector3.new(3.2, 0.8, side * 6.5), crumpetHead)
		pose(crumpet, "wave")
		say("CRUMPET", "Crumpet", "Shall I fetch one of their students now, Madam?", 1.2)
		camera.CFrame = vexShot
		pose(vex, "laugh")
		say("DR. VERONICA VEX", "Vex", "Patience, Crumpet. Soon.", 1.0)
		-- (cut: from inside your gate, she's back in and the door is shut as they pull away)
		if vex then
			stopAll(vex)
			Limo.seat(limo, vex, "VexSeat")
			pose(vex, "sit", true)
		end
		Limo.door(limo, side, false)
		camera.CFrame = CFrame.lookAt(youAt + inward * 9 + Vector3.new(4, 7, 0), Vector3.new(gate.X, 3, laneZ))
		local t1 = os.clock()
		while os.clock() - t1 < 2.2 and not skipped do
			local a = (os.clock() - t1) / 2.2
			limo:PivotTo(limoAt(gate.X + 140 * a * a))
			task.wait()
		end
	end

	-- the Welcome Bus sets off now, so it pulls up while he talks
	pcall(function() Remotes.Action:InvokeServer("introBus") end)

	-- 4: who that was
	camera.CFrame = twoShot
	if wob and wob.PrimaryPart then
		wob:PivotTo(CFrame.lookAt(wob.PrimaryPart.Position, Vector3.new(youAt.X, wob.PrimaryPart.Position.Y, youAt.Z)))
	end
	say("MR. WOBBLESWORTH", "Wobblesworth", "That was Dr. Veronica Vex. VexCorp, the Homework Factory, Vex Prep across the street: all hers.", 2)
	say("MR. WOBBLESWORTH", "Wobblesworth", "She thinks recess is a waste of homework time. And Crumpet does her dirty work. Keep an eye on your kids!", 2)
	say("MR. WOBBLESWORTH", "Wobblesworth", "That's why I picked you. Somebody has to stand up to her, and my knees aren't what they were.", 1.8)

	-- 5: here comes the Welcome Bus
	local rowAt = typeof(data.row) == "Vector3" and data.row or Vector3.new(gate.X, 0, gate.Z - side * 5)
	camera.CFrame = CFrame.lookAt(youAt + inward * 8 + Vector3.new(-3, 8, 0), Vector3.new(rowAt.X, 3, rowAt.Z))
	pose(wob, "point")
	say("MR. WOBBLESWORTH", "Wobblesworth", "Ah! Here comes Otis with your Welcome Bus. Go on, Principal: grab those kids!", 2.2)

	-- hand over: you on your front walk looking out through your gate at the new kids, the camera
	-- behind you
	fade(0, 0.3)
	for _, m in cast do
		if m and m.Parent then m:Destroy() end
	end
	skipBtn.button:Destroy()
	clickLayer:Destroy()
	local d = gui:FindFirstChild("Dialog", true)
	if d then d:Destroy() end
	if skipped then pcall(function() Remotes.Action:InvokeServer("introBus") end) end
	root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local s0 = typeof(data.stand) == "Vector3" and data.stand or Vector3.new(gate.X, 0, gate.Z + side * 10)
		local row = typeof(data.row) == "Vector3" and data.row or Vector3.new(gate.X, 0, gate.Z - side * 5)
		local stand = Vector3.new(s0.X, root.Position.Y, s0.Z)
		local face = Vector3.new(row.X, stand.Y, row.Z)
		player.Character:PivotTo(CFrame.lookAt(stand, face))
		local look = (face - stand).Unit
		camera.CFrame = CFrame.lookAt(stand - look * 13 + Vector3.new(0, 6, 0), face)
	end
	camera.CameraType = Enum.CameraType.Custom
	letterbox(false)
	hideHud(false)
	player:SetAttribute("LocalMusic", nil)
	task.wait(0.1)
	fade(1, 0.45)
	busy = false
end

-- a cutscene that errors (a part not streamed in, say) must never leave the screen black
local function safely(fn, data)
	local ok, err = pcall(fn, data)
	if ok then return end
	warn("[Cutscene]", err)
	if lastDouble then lastDouble:Destroy() lastDouble = nil end
	camera.CameraType = Enum.CameraType.Custom
	letterbox(false)
	hideHud(false)
	player:SetAttribute("LocalMusic", nil)
	local d = gui:FindFirstChild("Dialog", true)
	if d then d:Destroy() end
	fade(1, 0.3)
	busy = false
end

-- Graduation Day: dusk over your own school, the whole cast, then the end card
local function finale(data)
	-- after the Board's own cutscene, however long it ran
	local t0 = os.clock()
	while busy and os.clock() - t0 < 30 do task.wait(0.2) end
	if busy then return end
	busy = true
	local plotName = player:GetAttribute("Plot")
	local plot = plotName and workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(plotName)
	local origin = plot and plot:FindFirstChild("Origin")
	if not origin then busy = false return end
	local o = origin.CFrame
	local function at(x, y, z) return o:PointToWorldSpace(Vector3.new(x, y, z)) end
	fade(0, 0.5)
	hideHud(true)
	letterbox(true)
	player:SetAttribute("LocalMusic", "heroes")
	local Lighting = game:GetService("Lighting")
	local clock0 = Lighting.ClockTime
	Lighting.ClockTime = 17.9
	local prevType, prevCF = camera.CameraType, camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	-- three slow shots of your Multiverse University
	local shots = {
		{ from = at(0, 14, 120), to = at(0, 22, 0), push = at(0, 12, 95) },
		{ from = at(-70, 20, 95), to = at(0, 12, 30), push = at(-55, 16, 80) },
		{ from = at(8, 7, 60), to = at(0, 9, 12), push = at(4, 7, 45) },
	}
	fade(1, 0.8)
	local title = caption("GRADUATION DAY", Color3.fromRGB(255, 215, 90), 0.2, 72)
	task.wait(1.6)
	title:Destroy()
	local move
	for i, line in Config.FinaleLines do
		local shot = shots[math.min(#shots, math.ceil(i / 4))]
		if i % 4 == 1 then
			if move then move:Cancel() end
			camera.CFrame = CFrame.lookAt(shot.from, shot.to)
			move = TweenService:Create(camera, TweenInfo.new(10, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(shot.push, shot.to) })
			move:Play()
		end
		if line[3] == "NO." then sfx("GavelBig") end
		sayLine(line[1], line[2], line[3])
	end
	-- the end card
	sfx("StingParty")
	local c1 = caption("PRINCIPAL OF THE MULTIVERSE", Color3.fromRGB(255, 215, 90), 0.4, 72)
	local c2 = caption((data and data.name or "Your school") .. " is the greatest school in every universe.", Color3.new(1, 1, 1), 0.52, 34)
	local c3 = caption("Tiny Vex is waiting on your bench. Prestige stars are open.", Color3.fromRGB(200, 255, 200), 0.6, 28)
	confetti(140)
	task.wait(4)
	fade(0, 0.5)
	c1:Destroy()
	c2:Destroy()
	c3:Destroy()
	if move then move:Cancel() end
	-- put the time of day back unless an event changed it meanwhile
	if math.abs(Lighting.ClockTime - 17.9) < 0.01 then Lighting.ClockTime = clock0 end
	camera.CameraType = prevType
	camera.CFrame = prevCF
	letterbox(false)
	hideHud(false)
	player:SetAttribute("LocalMusic", nil)
	task.wait(0.4)
	fade(1, 0.6)
	busy = false
end

---------------------------------------------------------------------------
-- Rival: Vex Prep Academy shows itself off (the first time you walk up to its gate). Dr. Vex gives the
-- tour herself: round the clock tower, her on the front steps with two monitors, down the Great Hall
-- past the desks, the blackboard, Headmaster Grindle asleep in his office, the trophy case, and her
-- at the gate looking across the street at your school. SKIP in the corner; a click hurries a line.
-- (Vex Prep: gate at z -45, the hall's front wall at z -95, the office behind the partition at z -146.)
---------------------------------------------------------------------------
local function rival(data)
	if busy then return end
	busy = true
	local cast = {}
	local skipped, clicked = false, false
	pcall(function() player:RequestStreamAroundAsync(Vector3.new(427, 5, -110), 4) end)
	fade(0, 0.35)
	hideHud(true)
	letterbox(true)
	local prevType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	local skipBtn = UI.button(gui, { text = "SKIP \u{25B6}\u{25B6}", color = Color3.fromRGB(60, 60, 75), size = UDim2.fromOffset(150, 46), position = UDim2.new(1, -24, 0, 24), anchor = Vector2.new(1, 0) })
	skipBtn.button.ZIndex = 30
	for _, d in skipBtn.button:GetDescendants() do if d:IsA("GuiObject") then d.ZIndex = 31 end end
	local clickLayer = UI.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = gui })
	clickLayer.Activated:Connect(function() clicked = true end)
	skipBtn.button.Activated:Connect(function() skipped = true clicked = true end)
	local function say(speaker, template, line, hold)
		if skipped then return end
		local box, text, hint = dialogBox(speaker, template)
		clicked = false
		hint.Visible = false
		for c = 1, #line do
			if clicked or skipped then break end
			text.Text = line:sub(1, c)
			if c % 2 == 0 and line:sub(c, c) ~= " " then talk(speaker) end
			task.wait(0.026)
		end
		text.Text = line
		clicked = false
		hint.Visible = true
		local t0 = os.clock()
		while not clicked and not skipped and os.clock() - t0 < (hold or 1.8) do task.wait(0.05) end
		box:Destroy()
	end
	local function wait(t)
		local t0 = os.clock()
		while not skipped and os.clock() - t0 < t do task.wait(0.05) end
	end
	-- the camera from a to b (CFrames) over t seconds, eased; returns at once (the move carries on)
	local move
	local function glide(a, b, t)
		if move then move:Cancel() end
		camera.CFrame = a
		move = TweenService:Create(camera, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = b })
		move:Play()
	end
	local function cut() fade(0, 0.18) end
	local function reveal() fade(1, 0.3) end

	-- the lock sign across Vex Prep's gate is this client's own: out of the picture while this plays
	local barrierParts = {}
	local barriers = workspace:FindFirstChild("AreaBarriers")
	for _, d in barriers and barriers:GetDescendants() or {} do
		if d:IsA("BasePart") and d.LocalTransparencyModifier < 1 then
			barrierParts[d] = d.LocalTransparencyModifier
			d.LocalTransparencyModifier = 1
		elseif d:IsA("SurfaceGui") and d.Enabled then
			barrierParts[d] = true
			d.Enabled = false
		end
	end

	local CX, FLOOR = 427, 0.9
	-- the cast: Dr. Vex on the steps with a monitor either side, Grindle asleep at his desk
	local vex = actor("Vex", Vector3.new(CX, FLOOR + 0.4, -90.5), Vector3.new(CX, 0, -40))
	table.insert(cast, vex)
	pose(vex, "idle", true)
	for _, s in { -1, 1 } do
		local mon = actor("HallMonitor", Vector3.new(CX + s * 4.4, FLOOR + 0.4, -92), Vector3.new(CX + s * 4.4, 0, -40))
		table.insert(cast, mon)
		pose(mon, "idle", true)
	end
	local grindle = actor("Headmaster", Vector3.new(CX, FLOOR, -156.2), Vector3.new(CX, 0, -140))
	if grindle then
		table.insert(cast, grindle)
		-- (in his chair: the seat's top is 2.35 up; a sitting rig's root sits half its height plus a
		-- tenth of its hip height above the seat)
		local root = grindle.PrimaryPart
		local hum = grindle:FindFirstChildOfClass("Humanoid")
		local y = FLOOR + 2.35 + root.Size.Y * 0.5 + hum.HipHeight * 0.1
		grindle:PivotTo(CFrame.lookAt(Vector3.new(CX, y, -156.2), Vector3.new(CX, y, -140)) * CFrame.Angles(math.rad(-8), 0, 0))
		pose(grindle, "sit", true)
		local head = grindle:FindFirstChild("Head")
		-- asleep: eyelids down over the eyes (a patch of skin with a dark lash line), and his head
		-- slumped forward and to one side
		if head then
			local hs = head.Size
			for _, x in { -0.2, 0.2 } do
				for k, spec in { { Vector3.new(hs.X * 0.2, hs.Y * 0.14, 0.04), 0.1, head.Color }, { Vector3.new(hs.X * 0.2, 0.05, 0.045), 0.04, Color3.fromRGB(30, 22, 18) } } do
					local lid = Instance.new("Part")
					lid.Name = k == 1 and "Eyelid" or "Lash"
					lid.Size = spec[1]
					lid.Color = spec[3]
					lid.Material = Enum.Material.SmoothPlastic
					lid.CanCollide, lid.CanQuery, lid.CanTouch, lid.Massless, lid.CastShadow = false, false, false, true, false
					lid.CFrame = head.CFrame * CFrame.new(hs.X * x, hs.Y * spec[2], -hs.Z * 0.5 - (k == 1 and 0.02 or 0.045))
					local w = Instance.new("WeldConstraint")
					w.Part0, w.Part1 = head, lid
					w.Parent = lid
					lid.Parent = grindle
				end
			end
			local neck
			for _, part in grindle:GetChildren() do
				local j = part:IsA("BasePart") and part:FindFirstChild("Neck")
				if j and (j:IsA("Motor6D") or j:IsA("AnimationConstraint")) then neck = j end
			end
			if neck then
				local slump = RunService.Stepped:Connect(function()
					local t = os.clock()
					neck.Transform = CFrame.Angles(math.rad(-28 + math.sin(t * 1.6) * 3), 0, math.rad(12))
				end)
				grindle.Destroying:Connect(function() slump:Disconnect() end)
			end
		end
		-- snoring: a Z drifts up off his head every second or so. (Drawn on the cutscene's own screen
		-- layer at the point above his head: BillboardGuis on this local stand-in never showed.)
		if head then
			task.spawn(function()
				while grindle.Parent do
					local born = os.clock()
					local z = UI.label(gui, { Text = "Z", Font = UI.BIG, TextColor3 = Color3.fromRGB(210, 225, 255), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(56, 56), ZIndex = 6, stroke = 3 })
					local conn
					conn = RunService.RenderStepped:Connect(function()
						local a = (os.clock() - born) / 1.8
						if a >= 1 or not head.Parent then
							conn:Disconnect()
							z:Destroy()
							return
						end
						local p = head.Position + Vector3.new(0.6 + a * 1.4, 1.2 + a * 3, 0)
						local v, on = camera:WorldToViewportPoint(p)
						-- (not up in the letterbox bars)
						local h = camera.ViewportSize.Y
						z.Visible = on and v.Y > h * 0.13 and v.Y < h * 0.87
						z.Position = UDim2.fromOffset(v.X, v.Y)
						z.Size = UDim2.fromOffset(36 + a * 34, 36 + a * 34)
						z.Rotation = a * 20
						z.TextTransparency = a * a
						local st = z:FindFirstChildOfClass("UIStroke")
						if st then st.Transparency = a * a end
					end)
					task.wait(1.1)
				end
			end)
		end
	end

	-- 1. round the clock tower, high over the campus
	local tower = Vector3.new(CX, 40, -101)
	local orbit = { t = 0 }
	local orbitConn = RunService.RenderStepped:Connect(function(dt)
		orbit.t += dt
		local a = math.rad(-70 + math.min(orbit.t / 7, 1) * 80)
		local pos = tower + Vector3.new(math.sin(a) * 62, 14 - math.min(orbit.t / 7, 1) * 6, math.cos(a) * 62)
		camera.CFrame = CFrame.lookAt(pos, tower - Vector3.new(0, 6, 0))
	end)
	reveal()
	local c1 = caption("MEANWHILE, ACROSS THE STREET...", Color3.new(1, 1, 1), 0.2, 44)
	wait(3.2)
	c1:Destroy()
	sfx("Bell")
	wait(3)
	orbitConn:Disconnect()

	-- 2. down at the gate, looking up the path at the hall: the name
	cut()
	-- (starting just inside the gate: from outside it, the gate's own name board cut across the title)
	glide(CFrame.lookAt(Vector3.new(CX, 3.5, -50), Vector3.new(CX, 15, -95)), CFrame.lookAt(Vector3.new(CX, 4.5, -62), Vector3.new(CX, 12, -95)), 6)
	reveal()
	local title = caption("VEX PREP ACADEMY", Color3.fromRGB(205, 150, 255), 0.2, 84)
	sfx("GavelBig")
	wait(1.2)
	local sub = caption("EXCELLENCE THROUGH HOMEWORK", Color3.fromRGB(255, 230, 170), 0.3, 34)
	wait(2)
	title:Destroy()
	sub:Destroy()

	-- 3. Dr. Vex herself, on her front steps
	cut()
	glide(CFrame.lookAt(Vector3.new(CX + 7, 3, -74), Vector3.new(CX, 5.2, -90.5)), CFrame.lookAt(Vector3.new(CX + 3.5, 4.2, -81), Vector3.new(CX, 5.6, -90.5)), 7)
	reveal()
	if vex then pose(vex, "wave") end
	say("DR. VERONICA VEX", "Vex", "Welcome to Vex Prep Academy. MY school. The only school on Recess Row that matters.")
	if vex then pose(vex, "point") end
	say("DR. VERONICA VEX", "Vex", "The finest children in town. Straight A's. No recess. Homework twenty-five hours a day.")

	-- 4. the Great Hall: down the carpet between the desks
	cut()
	glide(CFrame.lookAt(Vector3.new(CX, 9, -98), Vector3.new(CX, 4, -140)), CFrame.lookAt(Vector3.new(CX, 7, -118), Vector3.new(CX, 4, -145)), 7)
	reveal()
	say("DR. VERONICA VEX", "Vex", "Eight of the smartest kids on Recess Row, at MY desks. And they are never, EVER leaving.")

	-- 5. the blackboard and a hall monitor on his rounds
	cut()
	glide(CFrame.lookAt(Vector3.new(CX + 6, 7, -118), Vector3.new(CX + 21, 8.5, -145)), CFrame.lookAt(Vector3.new(CX + 12, 7, -124), Vector3.new(CX + 21, 8.5, -145)), 6)
	reveal()
	say("DR. VERONICA VEX", "Vex", "My hall monitors never blink. Touch one of my students and the bell rings... and EVERYBODY comes running.")
	sfx("Bell")

	-- 6. the Headmaster's office: Grindle, "on guard"
	cut()
	glide(CFrame.lookAt(Vector3.new(CX - 2, 8, -145.8), Vector3.new(CX, 4.2, -156)), CFrame.lookAt(Vector3.new(CX - 1, 6.6, -150), Vector3.new(CX, 4.6, -156.2)), 7)
	reveal()
	local c6 = caption("HEADMASTER GRINDLE", Color3.fromRGB(255, 200, 140), 0.2, 50)
	say("DR. VERONICA VEX", "Vex", "And my Headmaster, Grindle, guards this school day and night. Nothing gets past Grindle.")
	c6:Destroy()
	say("HEADMASTER GRINDLE", "Headmaster", "Zzzz... no recess... EVER... zzzz... mmm, homework...")

	-- 7. the trophy case behind him
	cut()
	-- (from beside the end of his desk: the case, with Grindle snoring at the edge of the frame; head
	-- on, the camera went straight through him)
	glide(CFrame.lookAt(Vector3.new(CX + 7, 6.4, -152.6), Vector3.new(CX + 2.5, 5.5, -158.6)), CFrame.lookAt(Vector3.new(CX + 5.5, 6.2, -153.4), Vector3.new(CX + 2.5, 5.5, -158.6)), 5)
	reveal()
	say("DR. VERONICA VEX", "Vex", "Best School on Recess Row. Four years running.")

	-- 8. at the gate, looking across the street at your school
	cut()
	local plotName = player:GetAttribute("Plot")
	local plot = plotName and workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(plotName)
	local mine = plot and plot:FindFirstChild("Origin") and plot.Origin.Position or Vector3.new(CX, 0, 100)
	-- (out on her drive, past the gate, so neither the gate nor its sign is in the shot)
	local stand = Vector3.new(CX + 3, 0.65, -35)
	local toSchool = (Vector3.new(mine.X, 0, mine.Z) - Vector3.new(stand.X, 0, stand.Z)).Unit
	if vex then
		local root = vex.PrimaryPart
		local hum = vex:FindFirstChildOfClass("Humanoid")
		local y = stand.Y + hum.HipHeight + root.Size.Y / 2
		vex:PivotTo(CFrame.lookAt(Vector3.new(stand.X, y, stand.Z), Vector3.new(mine.X, y, mine.Z)))
		pose(vex, "idle", true)
	end
	-- over her right shoulder from well back: her on the left of the frame, your school beyond
	-- (side: her right, facing toSchool; the camera there puts her on the left of the frame)
	local side = Vector3.new(-toSchool.Z, 0, toSchool.X)
	local over = Vector3.new(stand.X, 7, stand.Z) - toSchool * 11 + side * 3.2
	local aim = Vector3.new(mine.X, 6, mine.Z)
	glide(CFrame.lookAt(over, aim), CFrame.lookAt(over + toSchool * 3, aim), 7)
	reveal()
	-- (your school is across the street from Vex Prep, or down the street on her own side)
	local where = mine.Z > 0 and "across the street" or "down the street"
	say("DR. VERONICA VEX", "Vex", ("And that sad little school %s? Give it a month. Its kids will be MY kids."):format(where))
	if vex then pose(vex, "laugh") end
	wait(1.4)

	-- 9. Wobblesworth's tip (in Chapter 1: the way in from below)
	cut()
	if data and data.chapter1 then
		glide(CFrame.lookAt(Vector3.new(446, 8, -28), Vector3.new(CX, 9, -60)), CFrame.lookAt(Vector3.new(438, 7, -34), Vector3.new(CX, 9, -60)), 6)
		reveal()
		say("MR. WOBBLESWORTH", "Wobblesworth", "Guarded day and night, is it? Ha! Stan's map says there's a way in... from BELOW. And old Grindle sleeps right on top of it.")
		cut()
		glide(CFrame.lookAt(Vector3.new(452, 9, 14), Vector3.new(466, 0.5, -7)), CFrame.lookAt(Vector3.new(459, 4.5, 4), Vector3.new(466, 0.3, -7)), 5)
		reveal()
		local c3 = caption("THE POTHOLE", Color3.fromRGB(255, 200, 140), 0.2, 56)
		wait(2.6)
		c3:Destroy()
	else
		glide(CFrame.lookAt(Vector3.new(446, 8, -28), Vector3.new(CX, 9, -60)), CFrame.lookAt(Vector3.new(438, 7, -34), Vector3.new(CX, 9, -60)), 8)
		reveal()
		say("MR. WOBBLESWORTH", "Wobblesworth", "Psst! Sneak in, grab a kid, carry them out through the gate. Every kid you take, Vex sends smarter ones... and angrier goons.")
		local c3 = caption("ONE VEX PREP. EVERY SCHOOL ON THE STREET WANTS ITS KIDS.", Color3.fromRGB(255, 200, 140), 0.2, 40)
		wait(2.6)
		c3:Destroy()
	end

	fade(0, 0.35)
	if move then move:Cancel() end
	for _, m in cast do if m then m:Destroy() end end
	for d, v in barrierParts do
		if d.Parent then
			if d:IsA("BasePart") then d.LocalTransparencyModifier = v else d.Enabled = true end
		end
	end
	skipBtn.button:Destroy()
	clickLayer:Destroy()
	for _, g in gui:GetChildren() do
		if g:IsA("TextLabel") and g.ZIndex == 5 then g:Destroy() end
	end
	camera.CameraType = prevType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or prevType
	letterbox(false)
	hideHud(false)
	task.wait(0.2)
	fade(1, 0.5)
	busy = false
end

---------------------------------------------------------------------------
-- data-driven scenes (Shared/Cutscenes): actors, camera shots, captions, lines, emotes
---------------------------------------------------------------------------
local Cutscenes = require(Shared:WaitForChild("Cutscenes"))
local Action = Remotes:WaitForChild("Action")

local ANIMS = {
	idle = "rbxassetid://507766388", walk = "rbxassetid://507777826", wave = "rbxassetid://507770239",
	point = "rbxassetid://507770453", cheer = "rbxassetid://507770677", laugh = "rbxassetid://507770818",
	dance = "rbxassetid://507771019", sit = "rbxassetid://2506281703",
}

local function playAnim(model, which, looped)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local animator = hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum))
	if not animator or not ANIMS[which] then return end
	local a = Instance.new("Animation")
	a.AnimationId = ANIMS[which]
	local track = animator:LoadAnimation(a)
	track.Looped = looped ~= false and (which == "idle" or which == "walk" or which == "sit" or which == "dance")
	track.Priority = looped == false and Enum.AnimationPriority.Action2 or Enum.AnimationPriority.Movement
	track:Play(0.2)
	return track
end

-- an actor: a local copy of a character template, standing on the ground at `at`, facing `face`
local function spawnActor(a, folder)
	local tt = ReplicatedStorage:FindFirstChild("TeacherTemplates")
	local st = ReplicatedStorage:FindFirstChild("StudentTemplates")
	local tmpl = (tt and tt:FindFirstChild(a.look or a.id)) or (st and st:FindFirstChild(a.look or a.id))
	local m
	if a.look == "player" then
		m = standIn(CFrame.new(a.at))
		if m then m.Parent = folder end
	elseif tmpl then
		m = tmpl:Clone()
		m:SetAttribute("Ambient", true) -- (moved by the scene: Smooth leaves it alone)
		m.Parent = folder
	end
	if not m then return nil end
	m.Name = a.id
	if a.scale and a.scale ~= 1 then m:ScaleTo(a.scale) end
	local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
	local hum = m:FindFirstChildOfClass("Humanoid")
	local lift = hum and root and (hum.HipHeight + root.Size.Y / 2) or 3
	local face = a.face or (a.at + Vector3.new(0, 0, -1))
	local base = Vector3.new(a.at.X, a.at.Y + lift, a.at.Z)
	m:PivotTo(CFrame.lookAt(base, Vector3.new(face.X, base.Y, face.Z)))
	-- only the root is anchored: the joints place the limbs and the animations move them
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = d == root
			d.CanCollide = false
		end
		if d:IsA("BillboardGui") or d:IsA("ProximityPrompt") then d:Destroy() end
	end
	playAnim(m, a.anim or "idle")
	return m, lift
end

-- glide an actor to a spot, walking (float = drift there without walking, e.g. a beam-up)
local function moveActor(m, lift, to, speed, float)
	local root = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local from = root.Position
	local goal = Vector3.new(to.X, to.Y + lift, to.Z)
	local dist = (goal - from).Magnitude
	if dist < 0.1 then return end
	if float then
		local v = Instance.new("CFrameValue")
		v.Value = m:GetPivot()
		v.Changed:Connect(function(cf) m:PivotTo(cf) end)
		local tw = TweenService:Create(v, TweenInfo.new(dist / (speed or 10), Enum.EasingStyle.Sine), { Value = m:GetPivot() + (goal - from) })
		tw:Play()
		tw.Completed:Connect(function() v:Destroy() end)
		return
	end
	local walk = playAnim(m, "walk")
	local look = CFrame.lookAt(goal, goal + (goal - from).Unit * Vector3.new(1, 0, 1))
	local v = Instance.new("CFrameValue")
	v.Value = m:GetPivot()
	v.Changed:Connect(function(cf) m:PivotTo(cf) end)
	local tw = TweenService:Create(v, TweenInfo.new(dist / (speed or 10), Enum.EasingStyle.Linear), { Value = look })
	tw:Play()
	tw.Completed:Connect(function()
		v:Destroy()
		if walk then walk:Stop(0.2) end
		playAnim(m, "idle")
	end)
end

local function shake(power, secs)
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = 1 - (os.clock() - t0) / secs
		if k <= 0 then conn:Disconnect() return end
		camera.CFrame *= CFrame.new((math.random() - 0.5) * power * k, (math.random() - 0.5) * power * k, 0)
	end)
end

-- shots and actors can name a place (Shared/Places) instead of giving coordinates:
--   actor { id, look, place = "OfficerPenny" }        stands at that post, facing its way
--   shot  { place = "TownHall", cam = "close" | "wide" | "high" | "low" | "side" | "back", side = 1|-1 }
local Places = require(Shared:WaitForChild("Places"))
local CAMS = {
	-- { distance in front, height of the camera, height looked at, sideways }
	close = { 9, 5, 4.2, 0.35 },
	wide = { 42, 22, 3, 0.2 },
	high = { 12, 70, 0, 0 },
	low = { 12, 1.6, 6, 0.25 },
	side = { 16, 6, 4, 1 },
	back = { -14, 7, 4, 0.2 },
}
local function resolveShot(s)
	if not s.place then return s end
	local p = Places.get(s.place)
	if not p then return s end
	local fwd = Vector3.new(p.look.X - p.pos.X, 0, p.look.Z - p.pos.Z)
	fwd = fwd.Magnitude > 0.01 and fwd.Unit or Vector3.new(0, 0, 1)
	local right = fwd:Cross(Vector3.yAxis)
	local c = CAMS[s.cam or "close"] or CAMS.close
	local side = (s.side or 1) * c[4]
	local dir = (fwd + right * side).Unit
	local focus = p.pos + Vector3.new(0, c[3], 0)
	local out = table.clone(s)
	out.from = p.pos + dir * c[1] + Vector3.new(0, c[2], 0)
	out.to = focus
	if not s.push then
		-- a slow push in: a quarter of the way closer
		out.push = out.from:Lerp(focus, 0.25)
	end
	return out
end
local function resolveActor(a)
	if not a.place then return a end
	local p = Places.get(a.place)
	if not p then return a end
	local out = table.clone(a)
	out.at = out.at or p.pos
	out.face = out.face or p.look
	return out
end

-- a flying saucer prop (the Close Encounters scenes); the beam starts off
local function buildSaucer(parent, cf, scale)
	scale = scale or 1
	local m = Instance.new("Model")
	m.Name = "Saucer"
	local function p(name, shape, size, offset, color, material, props)
		local x = Instance.new("Part")
		x.Name = name
		x.Shape = shape
		x.Size = size * scale
		x.CFrame = cf * CFrame.new(offset * scale)
		x.Color = color
		x.Material = material or Enum.Material.Metal
		x.Anchored, x.CanCollide, x.CanQuery, x.CanTouch = true, false, false, false
		for k, v in props or {} do x[k] = v end
		x.Parent = m
		return x
	end
	local up = CFrame.Angles(0, 0, math.rad(90))
	local body = p("Body", Enum.PartType.Cylinder, Vector3.new(3, 30, 30), Vector3.zero, Color3.fromRGB(170, 176, 190))
	body.CFrame = cf * up
	body.Reflectance = 0.2
	local rim = p("Rim", Enum.PartType.Cylinder, Vector3.new(1.2, 34, 34), Vector3.zero, Color3.fromRGB(120, 126, 140))
	rim.CFrame = cf * up
	p("Dome", Enum.PartType.Ball, Vector3.new(13, 13, 13), Vector3.new(0, 2.5, 0), Color3.fromRGB(120, 255, 90), Enum.Material.Glass, { Transparency = 0.35 })
	local belly = p("Belly", Enum.PartType.Cylinder, Vector3.new(2, 16, 16), Vector3.new(0, -2, 0), Color3.fromRGB(90, 96, 110))
	belly.CFrame = cf * CFrame.new(0, -2 * scale, 0) * up
	for k = 0, 11 do
		local a = math.rad(k * 30)
		p("Light", Enum.PartType.Ball, Vector3.new(1.6, 1.6, 1.6), Vector3.new(math.cos(a) * 15.5, 0, math.sin(a) * 15.5), k % 2 == 0 and Color3.fromRGB(120, 255, 90) or Color3.fromRGB(255, 240, 120), Enum.Material.Neon)
	end
	local beam = p("TractorBeam", Enum.PartType.Cylinder, Vector3.new(60, 12, 12), Vector3.new(0, -32, 0), Color3.fromRGB(150, 255, 120), Enum.Material.Neon, { Transparency = 1, CastShadow = false })
	beam.CFrame = cf * CFrame.new(0, -32 * scale, 0) * up
	local l = Instance.new("PointLight")
	l.Range = 50
	l.Brightness = 2
	l.Color = Color3.fromRGB(120, 255, 90)
	l.Parent = body
	m.WorldPivot = cf
	m.Parent = parent
	return m
end

local function playScene(id, data)
	local scene = Cutscenes[id]
	if not scene then
		warn("[Cutscene] no scene", id)
		return
	end
	-- (named places become coordinates)
	local shots = {}
	for i, s in scene.shots do shots[i] = resolveShot(s) end
	local cast = {}
	for i, a in scene.actors or {} do cast[i] = resolveActor(a) end
	scene = table.clone(scene)
	scene.shots, scene.actors = shots, cast
	-- wait for another scene to finish rather than dropping this one
	local t0 = os.clock()
	while busy and os.clock() - t0 < 30 do task.wait(0.2) end
	if busy then return end
	busy = true
	local first = scene.shots[1]
	pcall(function() player:RequestStreamAroundAsync(first.to or first.from, 4) end)
	fade(0, 0.35)
	hideHud(true)
	if scene.letterbox ~= false then letterbox(true) end
	local Lighting = game:GetService("Lighting")
	local clock0 = Lighting.ClockTime
	if scene.clock then Lighting.ClockTime = scene.clock end
	player:SetAttribute("LocalMusic", scene.music)
	local prevType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	local folder = Instance.new("Folder")
	folder.Name = "CutsceneActors"
	folder.Parent = workspace
	local actors = {}
	-- the real townsperson (or story NPC) steps aside while their actor plays them
	local hiddenReal = {}
	local function hideReal(id)
		for _, fname in { "Townsfolk", "StoryNPCs" } do
			local f = workspace:FindFirstChild(fname)
			local real = f and f:FindFirstChild(id)
			if real then
				for _, d in real:GetDescendants() do
					if d:IsA("BasePart") or d:IsA("Decal") then
						hiddenReal[d] = d.LocalTransparencyModifier
						d.LocalTransparencyModifier = 1
					elseif d:IsA("BillboardGui") and d.Enabled then
						hiddenReal[d] = true
						d.Enabled = false
					end
				end
			end
		end
	end
	for _, a in scene.actors or {} do
		local m, lift = spawnActor(a, folder)
		if m then
			actors[a.id] = { model = m, lift = lift }
			hideReal(a.id)
		end
	end
	local props = {}
	for _, pr in scene.props or {} do
		if pr.kind == "saucer" then props[pr.id] = buildSaucer(folder, CFrame.new(pr.at), pr.scale) end
	end
	-- a click skips the line being typed and the wait after it
	local skip = UI.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = gui })
	local clicked = false
	skip.Activated:Connect(function() clicked = true end)
	local move
	for i, s in scene.shots do
		if s.from and s.to then
			if move then move:Cancel() end
			camera.CFrame = CFrame.lookAt(s.from, s.to)
			if i == 1 then fade(1, 0.5) end
			if s.push then
				move = TweenService:Create(camera, TweenInfo.new(s.time or 5, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(s.push, s.pushTo or s.to) })
				move:Play()
			end
		elseif i == 1 then
			fade(1, 0.5)
		end
		if s.title then
			local c = caption(s.title, s.titleColor or Color3.fromRGB(255, 215, 90), 0.2, s.titleSize or 72)
			task.delay(s.titleTime or 2.4, function() c:Destroy() end)
		end
		if s.sfx then sfx(s.sfx) end
		if s.shake then shake(s.shake, 0.8) end
		for _, e in s.emotes or {} do
			local act = actors[e[1]]
			if act then playAnim(act.model, e[2], false) end
		end
		for _, mv in s.moves or {} do
			local act = actors[mv[1]]
			local to = mv[2]
			if type(to) == "string" then
				local p = Places.get(to)
				to = p and p.pos
			end
			if act and typeof(to) == "Vector3" then moveActor(act.model, act.lift, to, mv[3], mv[4] == "float") end
		end
		if s.confetti then confetti(s.confetti) end
		for _, pm in s.propMoves or {} do
			local pr = props[pm[1]]
			if pr then
				local v = Instance.new("CFrameValue")
				v.Value = pr:GetPivot()
				v.Changed:Connect(function(cf) pr:PivotTo(cf) end)
				local tw = TweenService:Create(v, TweenInfo.new(pm[3] or 3, Enum.EasingStyle.Sine), { Value = CFrame.new(pm[2]) })
				tw:Play()
				tw.Completed:Connect(function() v:Destroy() end)
			end
		end
		for _, bm in s.beams or {} do
			local pr = props[bm[1]]
			local beam = pr and pr:FindFirstChild("TractorBeam")
			if beam then TweenService:Create(beam, TweenInfo.new(0.5), { Transparency = bm[2] and 0.55 or 1 }):Play() end
		end
		local cap
		if s.caption then cap = caption(s.caption, s.captionColor or Color3.new(1, 1, 1), 0.8, 40) end
		if s.say then
			local box, text, hint = dialogBox(s.say[1], s.say[2])
			hint.Visible = false
			local line = s.say[3]
			clicked = false
			for c = 1, #line do
				if clicked then break end
				text.Text = line:sub(1, c)
				if c % 2 == 0 and line:sub(c, c) ~= " " then talk(s.say[1]) end
				task.wait(0.025)
			end
			text.Text = line
			clicked = false
			hint.Visible = true
			local hold = os.clock()
			while not clicked and os.clock() - hold < math.clamp(#line * 0.035, 1.4, 3) do task.wait(0.05) end
			box:Destroy()
		else
			clicked = false
			local hold = os.clock()
			while not clicked and os.clock() - hold < (s.hold or s.time or 3) do task.wait(0.05) end
		end
		if cap then cap:Destroy() end
	end
	skip:Destroy()
	fade(0, 0.35)
	if move then move:Cancel() end
	folder:Destroy()
	for d, v in hiddenReal do
		if d.Parent then
			if d:IsA("BillboardGui") then d.Enabled = true else d.LocalTransparencyModifier = v end
		end
	end
	if scene.clock and math.abs(Lighting.ClockTime - scene.clock) < 0.01 then Lighting.ClockTime = clock0 end
	camera.CameraType = prevType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or prevType
	letterbox(false)
	hideHud(false)
	player:SetAttribute("LocalMusic", nil)
	task.wait(0.2)
	fade(1, 0.5)
	busy = false
	if data and data.quest then pcall(Action.InvokeServer, Action, "tqScene", data.quest) end
end

local function safeScene(id, data)
	local ok, err = pcall(playScene, id, data)
	if ok then return end
	warn("[Cutscene]", id, err)
	local f = workspace:FindFirstChild("CutsceneActors")
	if f then f:Destroy() end
	camera.CameraType = Enum.CameraType.Custom
	letterbox(false)
	hideHud(false)
	player:SetAttribute("LocalMusic", nil)
	local d = gui:FindFirstChild("Dialog", true)
	if d then d:Destroy() end
	fade(1, 0.3)
	busy = false
	if data and data.quest then pcall(Action.InvokeServer, Action, "tqScene", data.quest) end
end

---------------------------------------------------------------------------
-- Prestige: the Board remakes your school in its new finish (PrestigeService rebuilds it while the
-- flash covers the screen)
---------------------------------------------------------------------------
local function prestige(data)
	local t0 = os.clock()
	while busy and os.clock() - t0 < 20 do task.wait(0.2) end
	if busy then return end
	busy = true
	local plotName = player:GetAttribute("Plot")
	local plot = plotName and workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(plotName)
	local origin = plot and plot:FindFirstChild("Origin")
	if not origin then busy = false return end
	local o = origin.CFrame
	local function at(x, y, z) return o:PointToWorldSpace(Vector3.new(x, y, z)) end
	fade(0, 0.35)
	hideHud(true)
	letterbox(true)
	player:SetAttribute("LocalMusic", "heroes")
	local prevType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(at(-70, 40, 130), at(0, 20, 0))
	fade(1, 0.5)
	local move = TweenService:Create(camera, TweenInfo.new(9, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(at(60, 34, 120), at(0, 22, 0)) })
	move:Play()
	local c1 = caption("THE BOARD HAS DECIDED...", Color3.new(1, 1, 1), 0.2, 50)
	sfx("GavelBig")
	task.wait(2.2)
	c1:Destroy()
	-- the flash in the finish's colour (the school is rebuilt behind it)
	black.BackgroundColor3 = data.color or Color3.new(1, 1, 1)
	TweenService:Create(black, TweenInfo.new(0.35), { BackgroundTransparency = 0 }):Play()
	sfx("StingParty")
	task.wait(2.6)
	TweenService:Create(black, TweenInfo.new(1.2), { BackgroundTransparency = 1 }):Play()
	task.wait(0.4)
	local c2 = caption(("%s SCHOOL!"):format(data.name or ""), data.color or Color3.fromRGB(255, 215, 90), 0.2, 84)
	local c3 = caption(("x%d tuition forever. Back to Kindergarten, better than ever."):format(data.mult or 2), Color3.new(1, 1, 1), 0.3, 32)
	confetti(160)
	task.wait(4.2)
	fade(0, 0.4)
	c2:Destroy()
	c3:Destroy()
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	move:Cancel()
	camera.CameraType = prevType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or prevType
	letterbox(false)
	hideHud(false)
	player:SetAttribute("LocalMusic", nil)
	task.wait(0.2)
	fade(1, 0.5)
	busy = false
end

---------------------------------------------------------------------------
-- the First Morning is done: a stamp and what you did, then Chapter 1 opens on the pothole by Vex Prep
---------------------------------------------------------------------------
local function firstMorning(data)
	if busy then return end
	busy = true
	sfx("Cheer")
	local stamp = caption("\u{2714} FIRST MORNING DONE!", Color3.fromRGB(120, 255, 140), 0.3, 72)
	local sub = caption(data and data.summary or "", Color3.new(1, 1, 1), 0.42, 30)
	task.wait(2.8)
	stamp:Destroy()
	sub:Destroy()
	pcall(function() player:RequestStreamAroundAsync(Vector3.new(466, 2, -7), 3) end)
	fade(0, 0.35)
	hideHud(true)
	letterbox(true)
	local prevType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(Vector3.new(440, 16, 26), Vector3.new(466, 0.5, -7))
	fade(1, 0.45)
	local move = TweenService:Create(camera, TweenInfo.new(6, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(Vector3.new(458, 5, 5), Vector3.new(466, 0.3, -7)) })
	move:Play()
	local c = caption("CHAPTER 1: DOWN THE POTHOLE", Color3.fromRGB(255, 170, 70), 0.2, 64)
	sayLine("MR. WOBBLESWORTH", "Wobblesworth", "Splendid first morning, Principal! She'll be back, you know. So we grow BIGGER.")
	c:Destroy()
	fade(0, 0.35)
	move:Cancel()
	camera.CameraType = prevType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or prevType
	letterbox(false)
	hideHud(false)
	task.wait(0.2)
	fade(1, 0.5)
	busy = false
end

---------------------------------------------------------------------------
-- the Vex Prep Job is done: Vex finds the empty desk
---------------------------------------------------------------------------
local function vexPA(data)
	if busy then return end
	busy = true
	pcall(function() player:RequestStreamAroundAsync(Vector3.new(397, 5, -130), 3) end)
	fade(0, 0.35)
	hideHud(true)
	letterbox(true)
	local prevType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	local desk = Vector3.new(397, 3, -130)
	camera.CFrame = CFrame.lookAt(Vector3.new(412, 12, -112), desk)
	fade(1, 0.4)
	local c1 = caption("MEANWHILE, AT VEX PREP...", Color3.new(1, 1, 1), 0.2, 44)
	task.wait(1.6)
	c1:Destroy()
	sfx("GavelBig")
	-- the shout: the camera shakes
	local shake = true
	task.spawn(function()
		local base = camera.CFrame
		local t0 = os.clock()
		while shake and os.clock() - t0 < 2.5 do
			camera.CFrame = base * CFrame.new((math.random() - 0.5) * 0.6, (math.random() - 0.5) * 0.6, 0)
			task.wait()
		end
		camera.CFrame = base
	end)
	local c2 = caption("PRINCIPAAAAL!", Color3.fromRGB(205, 150, 255), 0.35, 96)
	sayLine("DR. VERONICA VEX", "Vex", ("Where is %s?! Who took my student?! PRINCIPAAAAL!"):format(data and data.name or "my student"))
	shake = false
	c2:Destroy()
	fade(0, 0.35)
	camera.CameraType = prevType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or prevType
	letterbox(false)
	hideHud(false)
	task.wait(0.2)
	fade(1, 0.5)
	busy = false
end

Remotes:WaitForChild("Cutscene").OnClientEvent:Connect(function(name, data, extra)
	if name == "Play" then
		-- ("Play", sceneId, extras)
		task.spawn(safeScene, data, extra)
		return
	end
	if name == "Prestige" then
		task.spawn(safely, prestige, data)
		return
	end
	if name == "Rival" then
		task.spawn(safely, rival, data)
	elseif name == "Finale" then
		task.spawn(safely, finale, data)
	elseif name == "Board" then
		task.spawn(safely, board, data)
	elseif name == "Intro" then
		task.spawn(safely, intro, data)
	elseif name == "FirstMorning" then
		task.spawn(safely, firstMorning, data)
	elseif name == "VexPA" then
		task.spawn(safely, vexPA, data)
	end
end)
