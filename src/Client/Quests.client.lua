-- StarterPlayer.StarterPlayerScripts.Quests
-- The Principal's To-Do card (top left) and the guide: the thing the step is about glows (an
-- outline, seen through walls when it's far), or the side-bar button pulses when the step
-- happens in a menu.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Config = require(Shared:WaitForChild("Config"))
local Crew = require(Shared:WaitForChild("Crew"))
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
-- the guide: what the step is about glows. The thing itself (the kid to grab, the pad, Crumpet,
-- the lock button, the pen) pulses with a warm glow, drawn through walls when it's hidden; a ring
-- of light pulses on the ground under it; and when it's more than a street away a soft pillar of
-- light rises from it, so you can spot it across the map. No arrows and no beam from you to it:
-- they were loud, and the owner wanted them gone. (A Highlight alone was too faint: its outline
-- is a pixel wide, and a white fill vanishes on a light shirt.)
---------------------------------------------------------------------------
local guideFolder = Instance.new("Folder")
guideFolder.Name = "QuestGuide"
guideFolder.Parent = workspace

local GLOW = Color3.fromRGB(70, 225, 255) -- (cyan: it reads on grass, the white sidewalk and the red carpet alike)
local glow = Instance.new("Highlight")
glow.Name = "QuestGlow"
glow.FillColor = GLOW
glow.OutlineColor = Color3.new(1, 1, 1)
glow.Enabled = false
glow.Parent = guideFolder

-- the pillar: a tall soft column of light, fading upward
local pillar = Instance.new("Part")
pillar.Name = "Pillar"
pillar.Shape = Enum.PartType.Cylinder
pillar.Size = Vector3.new(60, 2.2, 2.2)
pillar.Material = Enum.Material.Neon
pillar.Color = GLOW
pillar.Transparency = 1
pillar.Anchored, pillar.CanCollide, pillar.CanQuery, pillar.CanTouch, pillar.CastShadow = true, false, false, false, false
pillar.Parent = guideFolder

local ring = Instance.new("Part")
ring.Name = "Ring"
ring.Shape = Enum.PartType.Cylinder
ring.Size = Vector3.new(0.12, 7, 7)
ring.Material = Enum.Material.Neon
ring.Color = GLOW
ring.Transparency = 1
ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch, ring.CastShadow = true, false, false, false, false
ring.Parent = guideFolder

local function myPlot()
	local name = player:GetAttribute("Plot")
	return name and workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild(name)
end

local function story(name)
	local s = workspace:FindFirstChild("StoryNPCs")
	return s and s:FindFirstChild(name)
end

-- what the current step is about: an Instance to outline, or a Vector3 for the ground ring
-- (nil = it happens in a menu, or there's nothing to point at right now)
local function missionTarget()
	-- a secret job points where the server says (the Lab gate, the Factory gate)
	local t = player:GetAttribute("MissionTarget")
	if typeof(t) == "Vector3" then return t end
	local id = player:GetAttribute("Mission")
	local def = id and Config.Missions[id]
	if def then
		if def.kind == "defend" then
			if player:GetAttribute("Raid") then return nil, "thief" end
			local plot = myPlot()
			return plot and plot:FindFirstChild("LockButton")
		end
		if def.kind == "chase" then
			local folder = workspace:FindFirstChild("Runners")
			for _, m in folder and folder:GetChildren() or {} do
				if m:GetAttribute("Runner") == player.UserId then return m end
			end
			return nil
		end
		if def.item and not player:GetAttribute("Heist") then
			local fac = workspace:FindFirstChild("VexFactory")
			return fac and fac:FindFirstChild("VexDesk", true)
		end
		return nil, "factory"
	end
	-- the tracked town quest (TownQuestService sets QuestTarget), once the To-Do list is done
	local q = player:GetAttribute("QuestTarget")
	if typeof(q) == "Vector3" and (not state or state.kind ~= "tutorial") then return q end
	if not state or state.kind ~= "tutorial" then
		if player:GetAttribute("SecretReady") and not player:GetAttribute("MissionReady") and not player:GetAttribute("Talking") then
			return story("JanitorStan")
		end
		if player:GetAttribute("MissionReady") and not player:GetAttribute("Talking") then
			return story("Wobblesworth")
		end
	end
	return nil
end

local function nearest(list, root)
	local best, bestD
	for _, m in list do
		local pp = m:IsA("Model") and m.PrimaryPart or m
		if pp then
			local d = root and (pp.Position - root.Position).Magnitude or 0
			if not best or d < bestD then best, bestD = m, d end
		end
	end
	return best
end

local function worldTarget()
	if player:GetAttribute("Talking") then return nil end
	local mt, mguide = missionTarget()
	if mt then return mt end
	if not mguide and (not state or not state.guide) then return nil end
	local g = mguide or state.guide
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if g == "carpet" then
		local hall = workspace:FindFirstChild("Hall")
		local cash = player:GetAttribute("Cash") or 0
		local mine, others = {}, {}
		for _, m in hall and hall:GetChildren() or {} do
			if m:GetAttribute("State") == "Hall" and m.PrimaryPart then
				local reserved = m:GetAttribute("ReservedFor")
				local def = Config.StudentById[m:GetAttribute("StudentId")]
				local price = m:GetAttribute("Free") and 0 or (def and def.price or math.huge)
				if reserved then
					-- your own Welcome Bus / bench kids first
					if Crew.owns(player, reserved) and price <= cash then table.insert(mine, m) end
				elseif price <= cash then
					table.insert(others, m)
				end
			end
		end
		return nearest(#mine > 0 and mine or others, root)
	elseif g == "pad" then
		local plot = myPlot()
		local school = plot and plot:FindFirstChild("School")
		if not school then return nil end
		local pads, any = {}, nil
		for _, fm in school:FindFirstChild("Floors") and school.Floors:GetChildren() or {} do
			for _, d in fm:FindFirstChild("Desks") and fm.Desks:GetChildren() or {} do
				local pad = d:FindFirstChild("CollectPad")
				local label = pad and pad:FindFirstChild("Cash") and pad.Cash:FindFirstChild("Label")
				if label and label.Text ~= "" then table.insert(pads, pad) end
				any = any or pad
			end
		end
		return nearest(pads, root) or any
	elseif g == "factory" then
		local fac = workspace:FindFirstChild("VexFactory")
		if player:GetAttribute("Heist") then return myPlot() and myPlot():FindFirstChild("Entry") end
		local pens = fac and fac:FindFirstChild("Pens")
		for _, pen in pens and pens:GetChildren() or {} do
			if Crew.owns(player, pen:GetAttribute("OwnerId")) then return pen end
		end
		return Vector3.new(0, 1, 34)
	elseif g == "thief" then
		local raids = workspace:FindFirstChild("Raids")
		local best, bestScore
		for _, m in raids and raids:GetChildren() or {} do
			if m:GetAttribute("RaidGoon") and m:GetAttribute("PlotName") == player:GetAttribute("Plot") and m.PrimaryPart then
				local d = root and (m.PrimaryPart.Position - root.Position).Magnitude or 0
				local score = d - (m:GetAttribute("Carrying") and 1000 or 0)
				if not best or score < bestScore then best, bestScore = m, score end
			end
		end
		return best
	elseif g == "cheater" or g == "smuggler" then
		local plot = myPlot()
		local students = plot and plot:FindFirstChild("Students")
		for _, m in students and students:GetChildren() or {} do
			local head = m:FindFirstChild("Head")
			local hit = (g == "cheater" and head and head:FindFirstChild("Cheating"))
				or (g == "smuggler" and (m.Name == "CandyDealer" or m.Name == "SlimeDealer"))
			if hit then return m end
		end
		return nil
	elseif g == "bench" then
		local hall = workspace:FindFirstChild("Hall")
		for _, m in hall and hall:GetChildren() or {} do
			if Crew.owns(player, m:GetAttribute("ReservedFor")) and m:GetAttribute("OnBench") then return m end
		end
		return nil
	elseif g == "lock" then
		local plot = myPlot()
		return plot and plot:FindFirstChild("LockButton")
	elseif g == "npc" and state and state.npc then
		return story(state.npc)
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

-- (is the target hidden behind something, or far? then its outline is drawn through walls)
local seeParams = RaycastParams.new()
seeParams.FilterType = Enum.RaycastFilterType.Exclude
local lastSee, throughWalls = 0, true
local function checkVisible(target, pos)
	local cam = workspace.CurrentCamera
	local exclude = { guideFolder, target }
	if player.Character then table.insert(exclude, player.Character) end
	seeParams.FilterDescendantsInstances = exclude
	local from = cam.CFrame.Position
	local far = (pos - from).Magnitude > 70
	local hit = workspace:Raycast(from, pos - from, seeParams)
	return far or hit ~= nil
end

local pulseT = 0
local ringFor, ringY
RunService.RenderStepped:Connect(function(dt)
	pulseT += dt
	local target = gui.Enabled and card.Visible and worldTarget() or nil
	local pulse = (math.sin(pulseT * 3.2) + 1) / 2
	local spot -- where the ring and the pillar go
	if typeof(target) == "Instance" and target.Parent then
		local pos = target:IsA("Model") and target:GetPivot().Position or target.Position
		if glow.Adornee ~= target then
			glow.Adornee = target
			lastSee = 0
		end
		if os.clock() - lastSee > 0.25 then
			lastSee = os.clock()
			throughWalls = checkVisible(target, pos)
		end
		glow.DepthMode = throughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
		glow.FillTransparency = 0.3 + 0.4 * pulse
		glow.OutlineTransparency = 0
		glow.Enabled = true
		spot = pos
	elseif typeof(target) == "Vector3" then
		glow.Enabled = false
		glow.Adornee = nil
		spot = target
	else
		glow.Enabled = false
		glow.Adornee = nil
	end
	if spot then
		-- (on the ground under it; looked up again only when it moves)
		if not ringFor or (ringFor - spot).Magnitude > 0.5 then
			ringFor = spot
			local exclude = { guideFolder }
			if player.Character then table.insert(exclude, player.Character) end
			if typeof(target) == "Instance" then table.insert(exclude, target) end
			seeParams.FilterDescendantsInstances = exclude
			local hit = workspace:Raycast(spot + Vector3.new(0, 2, 0), Vector3.new(0, -30, 0), seeParams)
			ringY = hit and hit.Position.Y + 0.08 or spot.Y - 3
		end
		local s = 5.5 + pulse * 1.8
		ring.Size = Vector3.new(0.12, s, s)
		ring.CFrame = CFrame.new(spot.X, ringY, spot.Z) * CFrame.Angles(0, 0, math.rad(90))
		ring.Transparency = 0.25 + 0.4 * pulse
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local far = root and (Vector3.new(spot.X, 0, spot.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude > 25
		pillar.CFrame = CFrame.new(spot.X, ringY + 30, spot.Z) * CFrame.Angles(0, 0, math.rad(90))
		pillar.Transparency = far and (0.72 + 0.1 * pulse) or 1
	else
		ring.Transparency = 1
		pillar.Transparency = 1
	end
	-- pulse the side-bar button for menu steps
	local btn = gui.Enabled and card.Visible and menuTarget()
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
