-- StarterPlayer.StarterPlayerScripts.Quests
-- The Principal's To-Do card (top left) and the guide that points at what to do next:
-- a glowing band from you to the target plus a bouncing arrow over it, or a pulse on the
-- side-bar button when the step happens in a menu.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")
local bus = ReplicatedStorage:WaitForChild("ClientBus", 10)

local player = Players.LocalPlayer
local gui = UI.new("ScreenGui", {
	Name = "Quests",
	ResetOnSpawn = false,
	DisplayOrder = 4,
	Parent = player:WaitForChild("PlayerGui"),
})
local uiRoot, uiScale = UI.autoScale(gui)

---------------------------------------------------------------------------
-- the card
---------------------------------------------------------------------------
local card = UI.new("Frame", {
	Name = "Card",
	Position = UDim2.fromOffset(12, 8),
	Size = UDim2.fromOffset(360, 112),
	BackgroundColor3 = UI.C.cream,
	Visible = false,
	Parent = gui,
})
UI.corner(card, 14)
UI.stroke(card, 3)
local header = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = UI.C.white, Parent = card })
UI.corner(header, 14)
local headerGrad = UI.gradient(header, UI.lighten(UI.C.blue, 0.3), UI.C.blue)
local title = UI.label(header, { Text = "", Font = UI.BIG, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -20, 1, -6), Position = UDim2.fromOffset(10, 3), stroke = 2 })
local text = UI.label(card, { Text = "", TextColor3 = UI.C.ink, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Size = UDim2.new(1, -110, 0, 40), Position = UDim2.fromOffset(12, 34), stroke = 0 })
local barBg = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(70, 70, 80), Size = UDim2.new(1, -110, 0, 18), Position = UDim2.fromOffset(12, 82), Parent = card })
UI.corner(barBg, 9)
local fill = UI.new("Frame", { BackgroundColor3 = UI.C.green, Size = UDim2.fromScale(0, 1), Parent = barBg })
UI.corner(fill, 9)
local count = UI.label(barBg, { Text = "", Size = UDim2.fromScale(1, 1), stroke = 2 })
local reward = UI.label(card, { Text = "", TextColor3 = Color3.fromRGB(40, 150, 70), Size = UDim2.new(0, 90, 0, 24), Position = UDim2.new(1, -96, 0, 36), stroke = 0 })
local go = UI.button(card, { text = "GO!", color = UI.C.orange, size = UDim2.fromOffset(84, 36), position = UDim2.new(1, -8, 1, -8), anchor = Vector2.new(1, 1), font = UI.BIG })

local state

---------------------------------------------------------------------------
-- the guide
---------------------------------------------------------------------------
local guideFolder = Instance.new("Folder")
guideFolder.Name = "QuestGuide"
guideFolder.Parent = workspace

local targetPart = Instance.new("Part")
targetPart.Name = "Target"
targetPart.Anchored, targetPart.CanCollide, targetPart.CanQuery, targetPart.CanTouch = true, false, false, false
targetPart.Transparency = 1
targetPart.Size = Vector3.one * 0.2
targetPart.Parent = guideFolder
local a1 = Instance.new("Attachment")
a1.Parent = targetPart

-- a bouncing down-arrow made of two wedges
local arrow = Instance.new("Model")
arrow.Name = "Arrow"
local shaft = Instance.new("Part")
shaft.Name = "Shaft"
shaft.Size = Vector3.new(0.9, 2.2, 0.9)
shaft.Color = Color3.fromRGB(255, 214, 51)
shaft.Material = Enum.Material.Neon
shaft.Anchored, shaft.CanCollide, shaft.CanQuery, shaft.CanTouch = true, false, false, false
shaft.Parent = arrow
for _, side in { -1, 1 } do
	local w = Instance.new("WedgePart")
	w.Name = "Head"
	w.Size = Vector3.new(0.9, 1.6, 1.1)
	w.Color = shaft.Color
	w.Material = Enum.Material.Neon
	w.Anchored, w.CanCollide, w.CanQuery, w.CanTouch = true, false, false, false
	w:SetAttribute("Side", side)
	w.Parent = arrow
end
arrow.Parent = guideFolder

local beam = Instance.new("Beam")
beam.Attachment1 = a1
beam.Color = ColorSequence.new(Color3.fromRGB(255, 230, 90))
beam.LightEmission = 1
beam.Width0, beam.Width1 = 0.5, 0.5
beam.FaceCamera = true
beam.Segments = 12
beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.3, 0.35), NumberSequenceKeypoint.new(1, 0.25) })
beam.Parent = guideFolder

local function myPlot()
	local name = player:GetAttribute("Plot")
	return name and workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(name)
end

-- where the current step wants you to go (nil = it happens in a menu)
local function worldTarget()
	if not state or not state.guide then return nil end
	local g = state.guide
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if g == "carpet" then
		local hall = workspace:FindFirstChild("Hall")
		local best, bestD
		local cash = player:GetAttribute("Cash") or 0
		for _, m in hall and hall:GetChildren() or {} do
			if m:GetAttribute("State") == "Hall" and m.PrimaryPart then
				local def = Config.StudentById[m:GetAttribute("StudentId")]
				local ok = def and def.price <= cash
				if state.guide == "carpet" and state.text:find("Rare") then
					ok = ok and Config.RarityById[def.rarity].order >= 3
				end
				if ok then
					local d = root and (m.PrimaryPart.Position - root.Position).Magnitude or 0
					if not best or d < bestD then best, bestD = m.PrimaryPart.Position, d end
				end
			end
		end
		if best then return best + Vector3.new(0, 3.5, 0) end
		local plot = myPlot()
		local entry = plot and plot:FindFirstChild("Entry")
		return entry and Vector3.new(entry.Position.X, 4, 0) or nil
	elseif g == "pad" then
		local plot = myPlot()
		local school = plot and plot:FindFirstChild("School")
		if not school then return nil end
		local bestPad, bestD
		for _, fm in school:FindFirstChild("Floors") and school.Floors:GetChildren() or {} do
			for _, d in fm:FindFirstChild("Desks") and fm.Desks:GetChildren() or {} do
				local pad = d:FindFirstChild("CollectPad")
				local label = pad and pad:FindFirstChild("Cash") and pad.Cash:FindFirstChild("Label")
				if label and label.Text ~= "" then
					local dist = root and (pad.Position - root.Position).Magnitude or 0
					if not bestPad or dist < bestD then bestPad, bestD = pad, dist end
				end
			end
		end
		return bestPad and bestPad.Position + Vector3.new(0, 1.5, 0) or nil
	elseif g == "cheater" or g == "thief" or g == "smuggler" then
		local plot = myPlot()
		local students = plot and plot:FindFirstChild("Students")
		for _, m in students and students:GetChildren() or {} do
			local head = m:FindFirstChild("Head")
			local hit = (g == "cheater" and head and head:FindFirstChild("Cheating"))
				or (g == "thief" and m.Name == "Crumpet")
				or (g == "smuggler" and (m.Name == "CandyDealer" or m.Name == "SlimeDealer"))
			if hit and m.PrimaryPart then return m.PrimaryPart.Position + Vector3.new(0, 4, 0) end
		end
		return nil
	elseif g == "bench" then
		local hall = workspace:FindFirstChild("Hall")
		for _, m in hall and hall:GetChildren() or {} do
			if m:GetAttribute("ReservedFor") == player.UserId and m.PrimaryPart then
				return m.PrimaryPart.Position + Vector3.new(0, 3.5, 0)
			end
		end
		return nil
	elseif g == "lock" then
		local plot = myPlot()
		local lock = plot and plot:FindFirstChild("LockButton")
		local btn = lock and lock:FindFirstChild("Button")
		return btn and btn.Position + Vector3.new(0, 2, 0) or nil
	end
	return nil
end

-- the side-bar button a menu step lives behind
local function menuTarget()
	if not state or not state.guide then return nil end
	local kind, arg = state.guide:match("^(%a+):(%w+)$")
	if not kind then return nil end
	local caption = ({ Shop = "Shop", Upgrades = "Upgrades", Board = "Board", NameSchool = "Name" })[kind == "shop" and "Shop" or arg]
	local menus = player.PlayerGui:FindFirstChild("Menus")
	local bar = menus and menus:FindFirstChild("SideBar", true)
	return bar and bar:FindFirstChild(caption), kind, arg
end

go.button.Activated:Connect(function()
	local _, kind, arg = menuTarget()
	local openBus = bus and bus:FindFirstChild("OpenPanel")
	if kind == "shop" and openBus then
		openBus:Fire("Shop", tonumber(arg))
	elseif kind == "panel" and openBus then
		openBus:Fire(arg)
	end
end)

local pulseT = 0
RunService.RenderStepped:Connect(function(dt)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local pos = gui.Enabled and card.Visible and worldTarget() or nil
	if pos and root then
		targetPart.Position = pos
		local a0 = root:FindFirstChild("QuestGuide")
		if not a0 then
			a0 = Instance.new("Attachment")
			a0.Name = "QuestGuide"
			a0.Position = Vector3.new(0, -1.5, 0)
			a0.Parent = root
		end
		beam.Attachment0 = a0
		beam.Enabled = (pos - root.Position).Magnitude > 6
		local bob = math.sin(os.clock() * 5) * 0.6
		local top = pos + Vector3.new(0, 3.2 + bob, 0)
		local spin = CFrame.Angles(0, os.clock() * 2, 0)
		shaft.CFrame = CFrame.new(top + Vector3.new(0, 1.1, 0)) * spin
		for _, w in arrow:GetChildren() do
			if w:IsA("WedgePart") then
				-- two wedges back to back make a downward triangle
				local s = w:GetAttribute("Side")
				w.CFrame = CFrame.new(top) * spin * CFrame.new(0, -0.8, s * 0.55) * CFrame.Angles(math.rad(180), s > 0 and 0 or math.pi, 0)
			end
		end
		for _, p in arrow:GetChildren() do p.Transparency = 0 end
	else
		beam.Enabled = false
		for _, p in arrow:GetChildren() do p.Transparency = 1 end
	end
	-- pulse the side-bar button for menu steps
	local btn = gui.Enabled and card.Visible and menuTarget()
	pulseT += dt
	if btn then
		local sc = btn:FindFirstChildOfClass("UIScale")
		if sc then sc.Scale = 1 + math.abs(math.sin(pulseT * 4)) * 0.14 end
	end
	go.button.Visible = btn ~= nil
end)

---------------------------------------------------------------------------
-- state from the server
---------------------------------------------------------------------------
local function show(s)
	if not s or s.ok == false then return end
	-- stop pulsing the old button
	local old = menuTarget()
	if old and old:FindFirstChildOfClass("UIScale") then old:FindFirstChildOfClass("UIScale").Scale = 1 end
	state = s
	card.Visible = true
	if s.kind == "tutorial" then
		title.Text = ("\u{1F4CB} PRINCIPAL'S TO-DO  %d/%d"):format(s.step, s.steps)
		headerGrad.Color = ColorSequence.new(UI.lighten(UI.C.blue, 0.3), UI.C.blue)
	else
		title.Text = "\u{1F3AF} GOAL"
		headerGrad.Color = ColorSequence.new(UI.lighten(UI.C.purple, 0.3), UI.C.purple)
	end
	text.Text = s.text
	local p = math.clamp(s.progress / s.count, 0, 1)
	TweenService:Create(fill, TweenInfo.new(0.3), { Size = UDim2.fromScale(p, 1) }):Play()
	count.Text = ("%d / %d"):format(math.min(s.progress, s.count), s.count)
	reward.Text = s.reward > 0 and ("+" .. Config.formatCash(s.reward)) or "\u{2B50}"
	UI.punch(card, 1.05)
end

local function done(d)
	local t = UI.label(gui, {
		Text = "\u{2714} DONE!  " .. (d.reward > 0 and ("+" .. Config.formatCash(d.reward)) or ""),
		Font = UI.BIG,
		TextColor3 = UI.C.green,
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(384, 40),
		Size = UDim2.fromOffset(360, 44),
		stroke = 3,
	})
	UI.pop(t, 0.3)
	task.delay(1.8, function()
		TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		TweenService:Create(t.UIStroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		task.wait(0.45)
		t:Destroy()
	end)
end

Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
	if kind == "quest" then
		show(data)
	elseif kind == "questDone" then
		done(data)
	end
end)

task.spawn(function()
	for _ = 1, 10 do
		local ok, s = pcall(Action.InvokeServer, Action, "quest")
		if ok and type(s) == "table" and s.ok ~= false then
			show(s)
			return
		end
		task.wait(2)
	end
end)
