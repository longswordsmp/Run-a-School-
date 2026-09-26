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
		if c % 3 == 0 then sfx("Coin") end
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
-- Intro: the Board Chair welcomes a brand-new principal to an empty school
---------------------------------------------------------------------------
local INTRO = Config.IntroLines

local function intro()
	if busy then return end
	busy = true
	local plotName = player:GetAttribute("Plot")
	local plot = plotName and workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(plotName)
	fade(0, 0.3)
	hideHud(true)
	letterbox(true)
	local prevType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	local origin = plot and plot:FindFirstChild("Origin")
	local ocf = origin and origin.CFrame or (plot and plot:GetAttribute("OriginCF")) or CFrame.new()
	local look = ocf.Position + Vector3.new(0, 12, 0)
	local front = ocf * CFrame.new(18, 34, 150)
	local near = ocf * CFrame.new(10, 16, 82)
	camera.CFrame = CFrame.lookAt(front.Position, look)
	fade(1, 0.5)
	player:SetAttribute("LocalMusic", "heroes")
	sfx("StingMorning")
	TweenService:Create(camera, TweenInfo.new(14, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(near.Position, look) }):Play()
	local box, text, hint = dialogBox()
	-- a full-screen button: click to finish the line / go to the next one
	local skip = UI.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = gui })
	local clicked = false
	skip.Activated:Connect(function() clicked = true end)
	for i, line in INTRO do
		clicked = false
		text.Text = ""
		hint.Visible = false
		local t0 = os.clock()
		-- typewriter
		for c = 1, #line do
			if clicked then break end
			text.Text = line:sub(1, c)
			if c % 3 == 0 then sfx("Coin") end
			task.wait(0.028)
		end
		text.Text = line
		clicked = false
		hint.Visible = true
		local hold = os.clock()
		while not clicked and os.clock() - hold < 2.2 do task.wait(0.05) end
		_ = t0
		if i == #INTRO - 1 then
			-- the bus arrives on the last line
			sfx("BusHorn")
		end
	end
	skip:Destroy()
	box:Destroy()
	fade(0, 0.35)
	camera.CameraType = prevType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or prevType
	letterbox(false)
	hideHud(false)
	player:SetAttribute("LocalMusic", nil)
	task.wait(0.2)
	fade(1, 0.5)
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
local function rival()
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
	sayLine("MR. WOBBLESWORTH", "Wobblesworth", "Psst! Sneak in, grab a kid, carry them out through the gate. Every kid you take, Vex sends smarter ones... and angrier goons.")
	local c3 = caption("ONE VEX PREP. EVERY SCHOOL ON THE STREET WANTS ITS KIDS.", Color3.fromRGB(255, 200, 140), 0.2, 40)
	task.wait(2.6)
	c3:Destroy()
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

-- glide an actor to a spot, walking
local function moveActor(m, lift, to, speed)
	local root = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local from = root.Position
	local goal = Vector3.new(to.X, to.Y + lift, to.Z)
	local dist = (goal - from).Magnitude
	if dist < 0.1 then return end
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

local function playScene(id, data)
	local scene = Cutscenes[id]
	if not scene then
		warn("[Cutscene] no scene", id)
		return
	end
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
			if act then moveActor(act.model, act.lift, mv[2], mv[3]) end
		end
		if s.confetti then confetti(s.confetti) end
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
				if c % 3 == 0 then sfx("Coin") end
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

Remotes:WaitForChild("Cutscene").OnClientEvent:Connect(function(name, data, extra)
	if name == "Play" then
		-- ("Play", sceneId, extras)
		task.spawn(safeScene, data, extra)
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
	end
end)
