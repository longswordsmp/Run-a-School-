-- StarterPlayer.StarterPlayerScripts.Mission
-- The story missions on the client (MissionService):
--   a "!" over Mr. Wobblesworth while he has a mission for you (player attribute MissionReady)
--   the conversation when you talk to him (Push "missionTalk"): click through it, then Start
--   the objective tracker while a mission is on (Push "mission"), with an escape meter on chases
--   the win line and a MISSION COMPLETE stamp at the end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")

local player = Players.LocalPlayer

local gui = UI.new("ScreenGui", {
	Name = "Mission",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 30,
	Parent = player:WaitForChild("PlayerGui"),
})
local root = UI.autoScale(gui)

local MISSION = Color3.fromRGB(255, 120, 60)

---------------------------------------------------------------------------
-- the "!" over Mr. Wobblesworth
---------------------------------------------------------------------------
-- (not AlwaysOnTop: those don't draw in Studio's capture, and the head is never hidden at the fountain)
local marker = UI.new("BillboardGui", {
	Name = "MissionMarker",
	Size = UDim2.fromOffset(96, 118),
	StudsOffsetWorldSpace = Vector3.new(0, 6.2, 0),
	AlwaysOnTop = false,
	LightInfluence = 0,
	MaxDistance = 400,
	Enabled = false,
	ResetOnSpawn = false,
	Parent = player.PlayerGui, -- (a BillboardGui inside a ScreenGui never draws)
})
local bang = UI.new("Frame", {
	Size = UDim2.fromOffset(76, 76),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 0),
	BackgroundColor3 = MISSION,
	Parent = marker,
})
UI.corner(bang, 38)
UI.stroke(bang, 4)
UI.gradient(bang, Color3.fromRGB(255, 190, 110), MISSION)
UI.label(bang, { Text = "!", Font = Enum.Font.FredokaOne, TextScaled = false, TextSize = 60, Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), stroke = 3.5 })
UI.label(marker, { Text = "MISSION", Font = UI.BIG, Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 86), TextColor3 = Color3.fromRGB(255, 225, 200), stroke = 3 })

-- the same "!" over Janitor Stan when he has a secret job (SecretReady), in spy blue
local SECRET = Color3.fromRGB(70, 140, 255)
local stanMarker = marker:Clone()
stanMarker.Name = "SecretMarker"
stanMarker.Parent = player.PlayerGui
local stanBang = stanMarker:FindFirstChildWhichIsA("Frame")
stanBang.BackgroundColor3 = SECRET
stanBang:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new(Color3.fromRGB(140, 190, 255), SECRET)
stanMarker:FindFirstChildWhichIsA("TextLabel").Text = "SECRET JOB"

local talking = false
local function talkingNow() return talking end

local function npcHead(name)
	local story = workspace:FindFirstChild("StoryNPCs")
	local npc = story and story:FindFirstChild(name)
	return npc and (npc:FindFirstChild("Head") or npc.PrimaryPart)
end
local function wobbleHead() return npcHead("Wobblesworth") end

local function refreshMarker()
	local head = wobbleHead()
	marker.Adornee = head
	marker.Enabled = head ~= nil and player:GetAttribute("MissionReady") ~= nil and player:GetAttribute("Mission") == nil and not talkingNow()
	local stan = npcHead("JanitorStan")
	stanMarker.Adornee = stan
	stanMarker.Enabled = stan ~= nil and player:GetAttribute("SecretReady") ~= nil and player:GetAttribute("Mission") == nil and not talkingNow()
end
player:GetAttributeChangedSignal("MissionReady"):Connect(refreshMarker)
player:GetAttributeChangedSignal("SecretReady"):Connect(refreshMarker)
player:GetAttributeChangedSignal("Mission"):Connect(refreshMarker)
task.spawn(function()
	local story = workspace:WaitForChild("StoryNPCs", 60)
	if story then
		story:WaitForChild("Wobblesworth", 60)
		refreshMarker()
		story.ChildAdded:Connect(function() task.defer(refreshMarker) end)
	end
end)
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	if marker.Enabled then
		bang.Position = UDim2.new(0.5, 0, 0, math.abs(math.sin(t * 3)) * -10 + 6)
		bang.Rotation = math.sin(t * 6) * 6
	end
	if stanMarker.Enabled then
		stanBang.Position = UDim2.new(0.5, 0, 0, math.abs(math.sin(t * 3 + 1)) * -10 + 6)
		stanBang.Rotation = math.sin(t * 6 + 1) * 6
	end
end)

---------------------------------------------------------------------------
-- the conversation
---------------------------------------------------------------------------

local function portraitOf(parent, templateId)
	local frame = UI.new("Frame", {
		Size = UDim2.fromOffset(124, 124),
		Position = UDim2.fromOffset(16, -30),
		BackgroundColor3 = Color3.fromRGB(70, 55, 120),
		ZIndex = 7,
		Parent = parent,
	})
	UI.corner(frame, 16)
	UI.stroke(frame, 4)
	UI.gradient(frame, Color3.fromRGB(120, 95, 190), Color3.fromRGB(55, 40, 100))
	local tt = ReplicatedStorage:FindFirstChild("TeacherTemplates")
	local st = ReplicatedStorage:FindFirstChild("StudentTemplates")
	local tmpl = (tt and tt:FindFirstChild(templateId)) or (st and st:FindFirstChild(templateId))
	if tmpl then
		local vp, m = UI.viewport(frame, tmpl, { zindex = 8, zoom = 0.55 })
		local cam = vp.CurrentCamera
		local head = m and m:FindFirstChild("Head")
		if head and cam then
			cam.CFrame = CFrame.lookAt(head.Position + Vector3.new(0, 0.1, -4.2), head.Position + Vector3.new(0, -0.3, 0))
		end
	end
	return frame
end

-- lines: { { speaker, portrait, text } ... }; buttons on the last line: { { text, color, fn } ... }
-- nearWob: the talk ends if you walk away from that NPC (true = Mr. Wobblesworth, or an NPC's name)
local function conversation(lines, buttons, title, nearWob)
	if talking then return end
	talking = true
	player:SetAttribute("Talking", true) -- (the guide arrow and the "!" step aside)
	refreshMarker()
	local box = UI.new("Frame", {
		Name = "Dialog",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -160), -- above the cash bar and its pills
		Size = UDim2.new(0.72, 0, 0, 168),
		BackgroundColor3 = UI.C.cream,
		ZIndex = 6,
		Parent = root,
	})
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(920, 168), Parent = box })
	UI.corner(box, 20)
	UI.stroke(box, 4)
	UI.gradient(box, Color3.fromRGB(255, 252, 244), Color3.fromRGB(246, 236, 214))
	if title then
		local tag = UI.new("Frame", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -24, 0, 14),
			Size = UDim2.fromOffset(300, 34),
			BackgroundColor3 = MISSION,
			ZIndex = 7,
			Parent = box,
		})
		UI.corner(tag, 10)
		UI.stroke(tag, 3)
		UI.gradient(tag, Color3.fromRGB(255, 180, 110), MISSION)
		UI.label(tag, { Text = (title:find("^SECRET") and title or ("MISSION: " .. title)):upper(), Font = UI.BIG, Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 8, stroke = 2 })
	end
	local speaker = UI.label(box, { Text = "", Font = UI.BIG, TextColor3 = UI.C.purple, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -190, 0, 30), Position = UDim2.fromOffset(160, 14), ZIndex = 7, stroke = 2 })
	local text = UI.label(box, { Text = "", TextColor3 = UI.C.ink, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, TextScaled = false, TextSize = 25, Size = UDim2.new(1, -190, 0, 80), Position = UDim2.fromOffset(160, 50), ZIndex = 7, stroke = 0 })
	local hint = UI.label(box, { Text = "click to continue \u{25B6}", TextColor3 = UI.C.grey, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0, 240, 0, 18), Position = UDim2.new(1, -258, 1, -28), ZIndex = 7, stroke = 0 })
	local row = UI.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, -12),
		Size = UDim2.fromOffset(420, 46),
		ZIndex = 7,
		Visible = false,
		Parent = box,
	})
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 10), Parent = row })
	UI.pop(box, 0.7)

	local portrait
	local advance = Instance.new("BindableEvent")
	local skipTyping = false
	local click = UI.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 6, Parent = box })
	click.Activated:Connect(function() advance:Fire() end)
	local keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA then
			advance:Fire()
		end
	end)
	local closed = false
	local function close()
		if closed then return end
		closed = true
		keyConn:Disconnect()
		talking = false
		player:SetAttribute("Talking", nil)
		refreshMarker()
		TweenService:Create(box, TweenInfo.new(0.2), { Position = UDim2.new(0.5, 0, 1, 200) }):Play()
		task.delay(0.22, function() box:Destroy() end)
	end
	-- walk away and he stops talking
	task.spawn(function()
		local head = type(nearWob) == "string" and npcHead(nearWob) or wobbleHead()
		while not closed and nearWob do
			local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if r and head and head.Parent and (r.Position - head.Position).Magnitude > 26 then
				close()
				return
			end
			task.wait(0.3)
		end
	end)
	task.spawn(function()
		for i, line in lines do
			if closed then return end
			local who, tmpl, words = line[1], line[2], line[3]
			speaker.Text = who
			if portrait then portrait:Destroy() end
			portrait = portraitOf(box, tmpl)
			UI.pop(portrait, 0.85)
			hint.Visible = false
			row.Visible = false
			-- typed out; a click fills the line in at once
			skipTyping = false
			local conn = advance.Event:Connect(function() skipTyping = true end)
			for c = 1, #words do
				if skipTyping or closed then break end
				text.Text = words:sub(1, c)
				task.wait(0.022)
			end
			conn:Disconnect()
			text.Text = words
			if closed then return end
			if i < #lines then
				hint.Visible = true
				advance.Event:Wait()
			else
				-- the last line: the choice
				for _, c in row:GetChildren() do
					if c:IsA("GuiObject") then c:Destroy() end
				end
				for k, b in buttons do
					local btn = UI.button(row, { text = b[1], color = b[2], size = UDim2.fromOffset(k == 1 and 200 or 130, 44), layoutOrder = k, font = UI.BIG })
					btn.button.ZIndex = 8
					for _, d in btn.button:GetDescendants() do
						if d:IsA("GuiObject") then d.ZIndex = 9 end
					end
					btn.button.Activated:Connect(function()
						close()
						if b[3] then b[3]() end
					end)
				end
				row.Visible = true
				UI.pop(row, 0.8)
			end
		end
	end)
	return close
end

Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
	if kind ~= "missionTalk" then return end
	local near = data.npc or true
	if data.id then
		conversation(data.lines, {
			{ data.action == "secretStart" and "TAKE THE JOB" or "START MISSION", data.action == "secretStart" and SECRET or MISSION, function()
				pcall(Action.InvokeServer, Action, data.action or "missionStart", data.id)
			end },
			{ "LATER", UI.C.grey },
		}, data.title, near)
	else
		conversation(data.lines, { { "BYE!", UI.C.blue } }, nil, near)
	end
end)

---------------------------------------------------------------------------
-- the objective tracker
---------------------------------------------------------------------------
local card = UI.new("Frame", {
	Name = "Tracker",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 250),
	Size = UDim2.fromOffset(300, 150),
	BackgroundColor3 = UI.C.cream,
	Visible = false,
	Parent = root,
})
UI.corner(card, 16)
UI.stroke(card, 4)
local head = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = MISSION, Parent = card })
UI.corner(head, 16)
local headGrad = UI.gradient(head, Color3.fromRGB(255, 180, 110), MISSION)
-- square off the header's bottom corners
local headFill = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), BackgroundColor3 = MISSION, BorderSizePixel = 0, Parent = head })
UI.gradient(headFill, Color3.fromRGB(255, 140, 75), MISSION)
local headText = UI.label(head, { Text = "\u{1F3AF} MISSION", Font = UI.BIG, Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 5), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, stroke = 2 })
local titleL = UI.label(card, { Text = "", Font = UI.BIG, TextColor3 = UI.C.ink, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -24, 0, 26), Position = UDim2.fromOffset(12, 40), stroke = 0 })
local objL = UI.label(card, { Text = "", TextColor3 = Color3.fromRGB(70, 60, 90), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextScaled = false, TextSize = 17, TextWrapped = true, Size = UDim2.new(1, -24, 0, 40), Position = UDim2.fromOffset(12, 68), stroke = 0 })
local pips = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(12, 114), Parent = card })
UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, Parent = pips })
-- chases: how close he is to getting away
local meter = UI.new("Frame", { Size = UDim2.new(1, -24, 0, 12), Position = UDim2.fromOffset(12, 160), BackgroundColor3 = Color3.fromRGB(225, 215, 200), Visible = false, Parent = card })
UI.corner(meter, 6)
UI.stroke(meter, 2)
local meterFill = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = UI.C.red, Parent = meter })
UI.corner(meterFill, 6)
local meterL = UI.label(card, { Text = "ESCAPING", Font = UI.BIG, TextColor3 = UI.C.red, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0, 160, 0, 16), Position = UDim2.fromOffset(12, 141), Visible = false, stroke = 0 })

local cur -- { id, def, progress, count }

local function setPips(progress, count)
	for _, c in pips:GetChildren() do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	if not count or count <= 0 then return end
	for i = 1, count do
		local on = i <= (progress or 0)
		local pip = UI.new("Frame", {
			Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = on and UI.C.green or Color3.fromRGB(215, 205, 190),
			LayoutOrder = i,
			Parent = pips,
		})
		UI.corner(pip, 10)
		UI.stroke(pip, 2)
		if on then UI.label(pip, { Text = "\u{2714}", Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), stroke = 1.5 }) end
		if on and i == progress then UI.pop(pip, 1.6) end
	end
end

-- the tracker sits under the chapter card on the right (which folds and grows)
local function trackerY()
	local ch = player.PlayerGui:FindFirstChild("Chapters")
	local bottom = 0
	-- (this gui ignores the top bar inset; the chapter card's doesn't)
	local inset = ch and not ch.IgnoreGuiInset and game:GetService("GuiService"):GetGuiInset().Y or 0
	if ch and ch.Enabled then
		for _, d in ch:GetDescendants() do
			if d:IsA("Frame") and d.Visible and d.AbsoluteSize.X > 150 and d.AbsolutePosition.X > workspace.CurrentCamera.ViewportSize.X * 0.5 then
				bottom = math.max(bottom, d.AbsolutePosition.Y + d.AbsoluteSize.Y + inset)
			end
		end
	end
	return math.max(80, bottom / root.UIScale.Scale + 14)
end
local function showTracker(on)
	local y = trackerY()
	if on and not card.Visible then
		card.Visible = true
		card.Position = UDim2.new(1, 340, 0, y)
		TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0, y) }):Play()
	elseif not on and card.Visible then
		TweenService:Create(card, TweenInfo.new(0.3), { Position = UDim2.new(1, 340, 0, y) }):Play()
		task.delay(0.32, function()
			if not cur then card.Visible = false end
		end)
	end
end

local function stamp(text, color)
	local t = UI.label(root, {
		Text = text,
		Font = UI.BIG,
		TextColor3 = color,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromOffset(760, 90),
		Rotation = -4,
		stroke = 5,
		ZIndex = 20,
	})
	UI.pop(t, 2.2)
	task.delay(2.6, function()
		TweenService:Create(t, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		TweenService:Create(t.UIStroke, TweenInfo.new(0.5), { Transparency = 1 }):Play()
		task.wait(0.55)
		t:Destroy()
	end)
end

Remotes.Push.OnClientEvent:Connect(function(kind, data)
	if kind ~= "mission" then return end
	if data.state == "started" then
		local id = player:GetAttribute("Mission")
		local def = id and Config.Missions[id]
		cur = { def = def, count = data.count, progress = data.progress or 0, secret = data.secret }
		headGrad.Color = data.secret and ColorSequence.new(Color3.fromRGB(140, 190, 255), SECRET) or ColorSequence.new(Color3.fromRGB(255, 180, 110), MISSION)
		headText.Text = data.secret and "\u{1F575}\u{FE0F} SECRET JOB" or "\u{1F3AF} MISSION"
		titleL.Text = data.title or (def and def.title) or ""
		objL.Text = data.phase or data.objective or (def and def.objective) or ""
		local chase = def and def.kind == "chase"
		meter.Visible = chase
		meterL.Visible = chase
		card.Size = UDim2.fromOffset(300, chase and 184 or 150)
		meterFill.Size = UDim2.fromScale(0, 1)
		setPips(cur.progress, cur.count)
		showTracker(true)
		UI.punch(card, 1.08)
		stamp(data.secret and "SECRET JOB!" or "MISSION START!", data.secret and SECRET or MISSION)
	elseif data.state == "phase" and cur then
		objL.Text = data.text
		UI.punch(card, 1.06)
	elseif data.state == "progress" and cur then
		cur.progress, cur.count = data.progress, data.count
		setPips(cur.progress, cur.count)
		UI.punch(card, 1.06)
	elseif data.state == "won" then
		cur = nil
		stamp(data.secret and "JOB DONE!" or "MISSION COMPLETE!", UI.C.green)
		showTracker(false)
		if data.line then
			task.delay(1.2, function()
				local close = conversation({ { data.speaker or "MR. WOBBLESWORTH", data.portrait or "Wobblesworth", data.line } }, { { "NICE!", UI.C.green } })
				-- it closes itself after a while
				if close then task.delay(9, close) end
			end)
		end
	elseif data.state == "failed" then
		cur = nil
		headGrad.Color = ColorSequence.new(Color3.fromRGB(255, 130, 130), UI.C.red)
		headText.Text = "\u{2716} MISSION FAILED"
		objL.Text = (data.why and (data.why .. " ") or "") .. (data.secret and "Talk to Janitor Stan for another job." or "Talk to Mr. Wobblesworth to try again.")
		meter.Visible = false
		meterL.Visible = false
		stamp("MISSION FAILED", UI.C.red)
		task.delay(3.5, function()
			if not cur then showTracker(false) end
		end)
	elseif data.state == "cancelled" then
		cur = nil
		showTracker(false)
	end
end)

-- a chase's escape meter: how far along his route the runner is
local function routeFraction(route, pos)
	local total, best, bestD, along = 0, 0, math.huge, 0
	local lens = {}
	for i = 1, #route - 1 do
		lens[i] = (Vector3.new(route[i + 1].X, 0, route[i + 1].Z) - Vector3.new(route[i].X, 0, route[i].Z)).Magnitude
		total += lens[i]
	end
	local p = Vector3.new(pos.X, 0, pos.Z)
	for i = 1, #route - 1 do
		local a = Vector3.new(route[i].X, 0, route[i].Z)
		local b = Vector3.new(route[i + 1].X, 0, route[i + 1].Z)
		local ab = b - a
		local t = ab.Magnitude > 0 and math.clamp((p - a):Dot(ab) / ab.Magnitude ^ 2, 0, 1) or 0
		local d = (a + ab * t - p).Magnitude
		if d < bestD then
			bestD = d
			best = along + lens[i] * t
		end
		along += lens[i]
	end
	return total > 0 and best / total or 0
end

-- follow the chapter card as it folds
task.spawn(function()
	while true do
		task.wait(0.5)
		if card.Visible and cur then
			local y = trackerY()
			if math.abs(card.Position.Y.Offset - y) > 2 then card.Position = UDim2.new(1, -16, 0, y) end
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if not cur or not cur.def or cur.def.kind ~= "chase" then return end
	local folder = workspace:FindFirstChild("Runners")
	for _, m in folder and folder:GetChildren() or {} do
		if m:GetAttribute("Runner") == player.UserId and m.PrimaryPart then
			local f = routeFraction(Config.ChaseRoutes[cur.def.route], m.PrimaryPart.Position)
			meterFill.Size = UDim2.fromScale(f, 1)
			meterL.Text = f > 0.75 and "ALMOST GONE!" or "ESCAPING"
			return
		end
	end
end)

-- a rejoin mid-mission (a respawn keeps the gui; this is for a fresh client)
task.defer(function()
	local id = player:GetAttribute("Mission")
	if id and Config.Missions[id] then
		cur = { def = Config.Missions[id], progress = 0 }
		titleL.Text = Config.Missions[id].title
		objL.Text = Config.Missions[id].objective
		showTracker(true)
	end
end)
