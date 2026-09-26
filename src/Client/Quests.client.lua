-- StarterPlayer.StarterPlayerScripts.Quests
-- The Principal's To-Do card (top left) and the guide: an arrow bobs over the thing the step is
-- about (a chevron at the screen's edge when it's off-screen), or the side-bar button pulses when
-- the step happens in a menu.
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
-- the guide: a chunky arrow bobs over the thing the step is about (the kid to grab, the pad, Crumpet,
-- the lock button, the pen), turning slowly. When the thing is off-screen, a chevron at the edge of
-- the screen points the way and says how far it is; when it's on screen but behind a wall (a pad
-- inside the school), the chevron hangs over the spot, pointing down. Menu steps pulse their
-- side-bar button instead.
-- (It replaced a neon ring and a pillar of light, which the owner didn't like, and before that a
-- flat neon arrow with a beam from you to it.)
---------------------------------------------------------------------------
local guideFolder = Instance.new("Folder")
guideFolder.Name = "QuestGuide"
guideFolder.Parent = workspace

local ARROW = Color3.fromRGB(255, 196, 40) -- (warm yellow: reads on grass, sidewalk, the red carpet and the classroom floor)
local ARROW_DARK = Color3.fromRGB(230, 140, 20)
local OUTLINE = Color3.fromRGB(40, 32, 48) -- (the chevron's rim)

-- the 3D arrow: a square shaft over a pyramid head (four corner wedges, point down), solid plastic
local arrow = Instance.new("Model")
arrow.Name = "Arrow"
local function arrowPart(class, name, color)
	local p = Instance.new(class)
	p.Name = name
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Parent = arrow
	return p
end
local shaft = arrowPart("Part", "Shaft", ARROW)
local head = {}
for i = 1, 4 do
	-- (two opposite faces a shade darker, so the turning head reads as a solid point)
	head[i] = arrowPart("CornerWedgePart", "Head", i % 2 == 0 and ARROW_DARK or ARROW)
end

local HEAD_W, HEAD_H, SHAFT_W, SHAFT_H = 3.2, 2.3, 1.3, 2.3
-- each corner wedge's point is at its own (+X, +Y, -Z) corner; four of them turned 90 degrees apart,
-- one per quadrant, make a pyramid with the point in the middle
local QUAD = { { 0, -1, 1 }, { 90, 1, 1 }, { 180, 1, -1 }, { 270, -1, -1 } }
local function placeArrow(tip, scale, spin)
	local a, h = HEAD_W / 2 * scale, HEAD_H * scale
	local base = CFrame.new(tip) * CFrame.Angles(0, spin, 0)
	local headCf = base * CFrame.new(0, h / 2, 0) * CFrame.Angles(math.pi, 0, 0)
	for i, q in QUAD do
		head[i].Size = Vector3.new(a, h, a)
		head[i].CFrame = headCf * CFrame.new(q[2] * a / 2, 0, q[3] * a / 2) * CFrame.Angles(0, math.rad(q[1]), 0)
	end
	shaft.Size = Vector3.new(SHAFT_W, SHAFT_H, SHAFT_W) * scale
	shaft.CFrame = base * CFrame.new(0, h + SHAFT_H * scale / 2 - 0.02, 0)
end

-- the edge-of-screen chevron: a ">" of two rounded bars with a dark rim, turned toward the target
local edgeGui = UI.new("ScreenGui", {
	Name = "GuideEdge",
	ResetOnSpawn = false,
	IgnoreGuiInset = true, -- (so its pixels are the camera's viewport pixels)
	DisplayOrder = 3,
	Parent = player:WaitForChild("PlayerGui"),
})
local edge = UI.new("Frame", {
	Name = "Chevron",
	Size = UDim2.fromOffset(64, 64),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = edgeGui,
})
local edgeScale = Instance.new("UIScale")
edgeScale.Parent = edge
do
	local L, T = 34, 12
	local dx, dy = (L / 2 - T / 2) * math.cos(math.rad(40)), (L / 2 - T / 2) * math.sin(math.rad(40))
	for layer, grow in { 6, 0 } do
		for _, s in { -1, 1 } do
			local bar = UI.new("Frame", {
				Size = UDim2.fromOffset(L + grow, T + grow),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 14 - dx, 0.5, -s * dy),
				Rotation = s * 40,
				BackgroundColor3 = layer == 1 and OUTLINE or ARROW,
				ZIndex = layer,
				Parent = edge,
			})
			UI.corner(bar, (T + grow) / 2)
		end
	end
end
local edgeDist = UI.label(edgeGui, {
	Name = "Distance",
	Text = "",
	Size = UDim2.fromOffset(90, 26),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Visible = false,
	stroke = 2,
})

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

-- (is the arrow's spot hidden behind something? then the chevron marks it on screen)
local seeParams = RaycastParams.new()
seeParams.FilterType = Enum.RaycastFilterType.Exclude
local function hidden(target, pos)
	local cam = workspace.CurrentCamera
	-- (walls and roofs count; people walking past and see-through glass don't)
	local exclude = { guideFolder }
	for _, name in { "Hall", "Raids", "Runners" } do
		local f = workspace:FindFirstChild(name)
		if f then table.insert(exclude, f) end
	end
	if typeof(target) == "Instance" then table.insert(exclude, target) end
	for _, pl in Players:GetPlayers() do
		if pl.Character then table.insert(exclude, pl.Character) end
	end
	seeParams.FilterDescendantsInstances = exclude
	local from = cam.CFrame.Position
	local hit = workspace:Raycast(from, pos - from, seeParams)
	return hit ~= nil and hit.Instance.Transparency < 0.5
end

-- where the arrow's point goes: over a kid's name tag, else just over the top of the thing
local function tipAbove(target)
	if typeof(target) == "Vector3" then return target + Vector3.new(0, 3, 0) end
	if target:IsA("Model") then
		local tag = target:FindFirstChild("Tag", true)
		if tag and tag:IsA("BillboardGui") and tag.Enabled then
			local at = tag.Adornee or tag.Parent
			if at and at:IsA("BasePart") then
				return at.Position + tag.StudsOffsetWorldSpace + Vector3.new(0, tag.Size.Y.Scale / 2 + 0.6, 0)
			end
		end
		local cf, size = target:GetBoundingBox()
		return cf.Position + Vector3.new(0, size.Y / 2 + 1, 0)
	end
	return target.Position + Vector3.new(0, target.Size.Y / 2 + 1, 0)
end

local t0 = 0
local lastSee, isHidden = 0, false
local lastTarget
RunService.RenderStepped:Connect(function(dt)
	t0 += dt
	local target = gui.Enabled and card.Visible and worldTarget() or nil
	if typeof(target) == "Instance" and not target.Parent then target = nil end
	local cam = workspace.CurrentCamera
	if target then
		local tip = tipAbove(target)
		local dist = (tip - cam.CFrame.Position).Magnitude
		local scale = math.clamp(dist / 40, 1, 3.2)
		-- bob up and down, turn slowly
		local bob = (math.sin(t0 * 3.4) + 1) / 2 * 0.9 * scale
		placeArrow(tip + Vector3.new(0, bob, 0), scale, t0 * 1.7)
		if arrow.Parent ~= guideFolder then arrow.Parent = guideFolder end
		if target ~= lastTarget or os.clock() - lastSee > 0.25 then
			lastTarget, lastSee = target, os.clock()
			isHidden = hidden(target, tip)
		end

		local vp = cam.ViewportSize
		local v = cam:WorldToViewportPoint(tip)
		local m = 70
		local onScreen = v.Z > 0 and v.X > m and v.X < vp.X - m and v.Y > m and v.Y < vp.Y - m
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local away = root and math.floor((tip - root.Position).Magnitude + 0.5)
		if onScreen and not isHidden and dist < 160 then
			-- in plain sight: the arrow does the job
			edge.Visible, edgeDist.Visible = false, false
		elseif onScreen then
			-- behind a wall, or far: the chevron hangs over the spot, pointing down, with the distance
			edge.Position = UDim2.fromOffset(v.X, v.Y - 28)
			edge.Rotation = 90
			edgeScale.Scale = 1 + math.abs(math.sin(t0 * 4)) * 0.12
			edgeDist.Position = UDim2.fromOffset(v.X, v.Y - 74)
			edgeDist.Text = away and (away .. "m") or ""
			edge.Visible, edgeDist.Visible = true, away ~= nil
		else
			-- off-screen: the chevron at the edge, pointing the way
			local c = vp / 2
			local d = Vector2.new(v.X, v.Y) - c
			if v.Z < 0 then d = -d end
			if d.Magnitude < 1 then d = Vector2.new(0, 1) end
			local k = math.min((c.X - m) / math.max(math.abs(d.X), 1e-3), (c.Y - m) / math.max(math.abs(d.Y), 1e-3))
			local at = c + d * k
			edge.Position = UDim2.fromOffset(at.X, at.Y)
			edge.Rotation = math.deg(math.atan2(d.Y, d.X))
			edgeScale.Scale = 1 + math.abs(math.sin(t0 * 4)) * 0.12
			local inward = at - d.Unit * 50
			edgeDist.Position = UDim2.fromOffset(inward.X, inward.Y)
			edgeDist.Text = away and (away .. "m") or ""
			edge.Visible, edgeDist.Visible = true, away ~= nil
		end
	else
		if arrow.Parent then arrow.Parent = nil end
		lastTarget = nil
		edge.Visible, edgeDist.Visible = false, false
	end
	-- pulse the side-bar button for menu steps
	local btn = gui.Enabled and card.Visible and menuTarget()
	if btn then
		local sc = btn:FindFirstChildOfClass("UIScale")
		if sc then sc.Scale = 1 + math.abs(math.sin(t0 * 4)) * 0.14 end
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
