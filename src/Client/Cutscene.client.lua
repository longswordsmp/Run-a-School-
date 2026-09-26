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
	local tt = ReplicatedStorage:FindFirstChild("TeacherTemplates")
	local st = ReplicatedStorage:FindFirstChild("StudentTemplates")
	local chair = (tt and tt:FindFirstChild(templateId or "DeanMaximus")) or (st and templateId and st:FindFirstChild(templateId))
	if chair then
		local vp, m = UI.viewport(portrait, chair, { zindex = 8, zoom = 0.55 })
		-- frame the head and shoulders
		local cam = vp.CurrentCamera
		local head = m and m:FindFirstChild("Head")
		if head and cam then
			cam.CFrame = CFrame.lookAt(head.Position + Vector3.new(0, 0.1, -4.2), head.Position + Vector3.new(0, -0.3, 0))
		end
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
-- Intro: a brand-new principal's first eight seconds. High over the street onto your empty school,
-- then down at your gate as YOUR Welcome Bus pulls up; two short lines; then you're standing at
-- the gate facing it while six kids step off. (The server starts the bus as this starts: it pulls
-- up during the second line.) data: { gate = your gate, park = where the bus stops, side = +1 for
-- the north row of schools, -1 for the south }
---------------------------------------------------------------------------
local INTRO = Config.IntroLines

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

	fade(0, 0.25)
	hideHud(true)
	letterbox(true)
	camera.CameraType = Enum.CameraType.Scriptable
	-- shot 1: high over the street, pushing in on your school
	local high = gate + Vector3.new(-46, 58, -side * 62)
	local closer = gate + Vector3.new(-26, 30, -side * 40)
	camera.CFrame = CFrame.lookAt(high, school)
	fade(1, 0.5)
	sfx("StingMorning")
	TweenService:Create(camera, TweenInfo.new(4.2, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(closer, school) }):Play()

	local box, text, hint = dialogBox()
	local skip = UI.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = gui })
	local clicked = false
	skip.Activated:Connect(function() clicked = true end)
	local function say(line, hold)
		clicked = false
		text.Text = ""
		hint.Visible = false
		for c = 1, #line do
			if clicked then break end
			text.Text = line:sub(1, c)
			if c % 2 == 0 and line:sub(c, c) ~= " " then talk("THE BOARD CHAIR") end
			task.wait(0.026)
		end
		text.Text = line
		clicked = false
		hint.Visible = true
		local t0 = os.clock()
		while not clicked and os.clock() - t0 < hold do task.wait(0.05) end
	end
	say(INTRO[1], 1.4)

	-- shot 2: down at your gate, looking down the street as the bus pulls up
	local curb = gate + Vector3.new(16, 6.5, -side * 2)
	local busLook = park + Vector3.new(0, 5, 0)
	TweenService:Create(camera, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { CFrame = CFrame.lookAt(curb, busLook) }):Play()
	sfx("BusHorn")
	say(INTRO[2], 2.4)
	skip:Destroy()
	box:Destroy()

	-- hand over: you on your front walk looking out through your gate at the six new kids, the
	-- camera behind you
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	fade(0, 0.3)
	if root then
		local s = typeof(data.stand) == "Vector3" and data.stand or Vector3.new(gate.X, 0, gate.Z + side * 10)
		local row = typeof(data.row) == "Vector3" and data.row or Vector3.new(gate.X, 0, gate.Z - side * 5)
		local stand = Vector3.new(s.X, root.Position.Y, s.Z)
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
-- Rival: the first look at Vex Prep Academy (one campus for the whole server, across the street)
---------------------------------------------------------------------------
local function rival(data)
	if busy then return end
	busy = true
	pcall(function() player:RequestStreamAroundAsync(Vector3.new(427, 5, -100), 4) end)
	fade(0, 0.35)
	hideHud(true)
	letterbox(true)
	local prevType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	local hall = Vector3.new(427, 14, -100)
	-- over the street: the gate, the fountains and the hall behind them
	camera.CFrame = CFrame.lookAt(Vector3.new(372, 44, 18), hall)
	fade(1, 0.5)
	local move = TweenService:Create(camera, TweenInfo.new(10, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(Vector3.new(427, 18, -20), hall) })
	move:Play()
	local c1 = caption("MEANWHILE, ACROSS THE STREET...", Color3.new(1, 1, 1), 0.2, 44)
	task.wait(2.2)
	c1:Destroy()
	local c2 = caption("VEX PREP ACADEMY", Color3.fromRGB(205, 150, 255), 0.2, 84)
	sfx("GavelBig")
	sayLine("DR. VERONICA VEX", "Vex", "Welcome to Vex Prep Academy. MY school. The only school on Recess Row that matters.")
	c2:Destroy()
	-- inside the Great Hall: the desks, the kids, a hall monitor
	move:Cancel()
	camera.CFrame = CFrame.lookAt(Vector3.new(452, 15, -99), Vector3.new(420, 3, -128))
	move = TweenService:Create(camera, TweenInfo.new(9, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(Vector3.new(440, 10, -104), Vector3.new(415, 3, -128)) })
	move:Play()
	sayLine("DR. VERONICA VEX", "Vex", "Eight of the smartest kids in town, at MY desks, doing homework twenty-five hours a day.")
	sayLine("DR. VERONICA VEX", "Vex", "And my hall monitors never blink. Touch one of my students and the bell rings. Everybody comes running.")
	-- back at the gate: Wobblesworth's tip
	move:Cancel()
	camera.CFrame = CFrame.lookAt(Vector3.new(446, 8, -28), Vector3.new(427, 9, -60))
	move = TweenService:Create(camera, TweenInfo.new(8, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(Vector3.new(438, 7, -34), Vector3.new(427, 9, -60)) })
	move:Play()
	if data and data.chapter1 then
		-- Chapter 1: the front door is no good; Stan's map says there's a way in from below
		sayLine("MR. WOBBLESWORTH", "Wobblesworth", "The front door is guarded day and night. But Stan's map says there's a way in... from BELOW.")
		move:Cancel()
		camera.CFrame = CFrame.lookAt(Vector3.new(452, 9, 14), Vector3.new(466, 0.5, -7))
		move = TweenService:Create(camera, TweenInfo.new(5, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(Vector3.new(459, 4.5, 4), Vector3.new(466, 0.3, -7)) })
		move:Play()
		local c3 = caption("THE POTHOLE", Color3.fromRGB(255, 200, 140), 0.2, 56)
		task.wait(2.6)
		c3:Destroy()
	else
		sayLine("MR. WOBBLESWORTH", "Wobblesworth", "Psst! Sneak in, grab a kid, carry them out through the gate. Every kid you take, Vex sends smarter ones... and angrier goons.")
		local c3 = caption("ONE VEX PREP. EVERY SCHOOL ON THE STREET WANTS ITS KIDS.", Color3.fromRGB(255, 200, 140), 0.2, 40)
		task.wait(2.6)
		c3:Destroy()
	end
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
