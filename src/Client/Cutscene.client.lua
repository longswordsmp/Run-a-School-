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
		for _, name in { "HUD", "Menus", "NowPlaying", "Prompts", "Quests", "Chapters" } do
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
	TweenService:Create(camera, TweenInfo.new(1.6, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(room.CameraA.Position:Lerp(target, 0.35), target) }):Play()
	task.wait(1.5)
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
			camera.CFrame = CFrame.lookAt(head.Position + Vector3.new(0, 0.6, -5.5), head.Position)
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
	for i, line in Config.FinaleLines do
		local shot = shots[math.min(#shots, math.ceil(i / 4))]
		if i % 4 == 1 then
			camera.CFrame = CFrame.lookAt(shot.from, shot.to)
			TweenService:Create(camera, TweenInfo.new(10, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(shot.push, shot.to) }):Play()
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
	Lighting.ClockTime = clock0
	camera.CameraType = prevType
	camera.CFrame = prevCF
	letterbox(false)
	hideHud(false)
	player:SetAttribute("LocalMusic", nil)
	task.wait(0.4)
	fade(1, 0.6)
	busy = false
end

Remotes:WaitForChild("Cutscene").OnClientEvent:Connect(function(name, data)
	if name == "Finale" then
		task.spawn(safely, finale, data)
	elseif name == "Board" then
		task.spawn(safely, board, data)
	elseif name == "Intro" then
		task.spawn(safely, intro, data)
	end
end)
