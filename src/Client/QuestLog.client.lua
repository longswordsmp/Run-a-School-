-- StarterPlayer.StarterPlayerScripts.QuestLog
-- The town quests on the client (Server/TownQuestService, data in Shared/Quests):
--   the tracker    under the Principal's To-Do card: the tracked quest, its step, progress
--   the markers    "!" over a townsperson with a quest for you (orange for the story), "?" when
--                  they're waiting for you
--   collectibles   glowing things only you can see; walk into one to pick it up (tqCollect)
--   the stamps     NEW QUEST / QUEST COMPLETE! with what you got
--   the log        side button "Quests" (ClientBus.OpenQuests) or J: active quests with every step,
--                  TRACK and DROP; what's available and where; what's still locked and why
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Config = require(Shared:WaitForChild("Config"))
local Quests = require(Shared:WaitForChild("Quests"))
local Townsfolk = require(Shared:WaitForChild("Townsfolk"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")
local bus = ReplicatedStorage:WaitForChild("ClientBus", 10)

local player = Players.LocalPlayer
local gui = UI.new("ScreenGui", {
	Name = "QuestLog",
	ResetOnSpawn = false,
	DisplayOrder = 5,
	Parent = player:WaitForChild("PlayerGui"),
})
local root = UI.autoScale(gui)

local GREEN = Color3.fromRGB(40, 170, 110)
local STORY = Color3.fromRGB(255, 140, 40)
local function lineColor(q) return q and q.line == "story" and STORY or GREEN end

local function sfx(name)
	local e = bus and bus:FindFirstChild("Sfx")
	if e then e:Fire(name) end
end

local state -- the last "tq" push

local function areaName(id)
	local a = id and Config.AreaById[id]
	return a and a.name or id or ""
end

local function stepText(q, i)
	local s = q.steps[i]
	return s and s.text or ""
end

---------------------------------------------------------------------------
-- the tracker
---------------------------------------------------------------------------
local tracker = UI.new("TextButton", {
	Name = "Tracker",
	Text = "",
	AutoButtonColor = false,
	Position = UDim2.fromOffset(12, 128),
	Size = UDim2.fromOffset(360, 104),
	BackgroundColor3 = UI.C.cream,
	Visible = false,
	Parent = root,
})
UI.corner(tracker, 14)
UI.stroke(tracker, 3)
local tHead = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = UI.C.white, Parent = tracker })
UI.corner(tHead, 14)
local tHeadGrad = UI.gradient(tHead, UI.lighten(GREEN, 0.3), GREEN)
local tHeadFill = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = UI.C.white, BorderSizePixel = 0, Parent = tHead })
local tHeadFillGrad = UI.gradient(tHeadFill, GREEN, GREEN)
local tTitle = UI.label(tHead, { Text = "", Font = UI.BIG, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -86, 1, -8), Position = UDim2.fromOffset(10, 4), ZIndex = 2, stroke = 2 })
local tStepNo = UI.label(tHead, { Text = "", Font = UI.BIG, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0, 70, 1, -10), Position = UDim2.new(1, -78, 0, 5), ZIndex = 2, stroke = 2 })
local tText = UI.label(tracker, { Text = "", TextColor3 = UI.C.ink, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, TextScaled = false, TextSize = 19, Size = UDim2.new(1, -24, 0, 44), Position = UDim2.fromOffset(12, 36), stroke = 0 })
UI.pixelCard(tracker, tHead)
local tBar = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(70, 70, 80), Size = UDim2.new(1, -24, 0, 14), Position = UDim2.new(0, 12, 1, -22), Parent = tracker })
UI.corner(tBar, 7)
local tFill = UI.new("Frame", { BackgroundColor3 = UI.C.green, Size = UDim2.fromScale(0, 1), Parent = tBar })
UI.corner(tFill, 7)
local tCount = UI.label(tBar, { Text = "", Size = UDim2.new(1, 0, 1, 2), stroke = 1.5 })
local tHint = UI.label(tracker, { Text = "J = quest log", TextColor3 = UI.C.grey, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0, 120, 0, 14), Position = UDim2.new(1, -132, 1, -20), stroke = 0, Visible = false })

local shownKey
local function refreshTracker()
	local entry
	for _, a in state and state.active or {} do
		if a.id == state.tracked then entry = a end
	end
	entry = entry or (state and state.active[1])
	local q = entry and Quests.byId[entry.id]
	if not q then
		if tracker.Visible then
			TweenService:Create(tracker, TweenInfo.new(0.25), { Position = UDim2.fromOffset(-380, 128) }):Play()
			task.delay(0.26, function() if not (state and state.active[1]) then tracker.Visible = false end end)
		end
		shownKey = nil
		return
	end
	local color = lineColor(q)
	tHeadGrad.Color = ColorSequence.new(UI.lighten(color, 0.3), color)
	tHeadFillGrad.Color = ColorSequence.new(color, color)
	tTitle.Text = (q.line == "story" and "\u{2B50} " or "\u{1F4DC} ") .. q.title:upper()
	tStepNo.Text = ("%d/%d"):format(math.min(entry.step, #q.steps), #q.steps)
	tText.Text = stepText(q, entry.step)
	local hasCount = entry.n and entry.n > 1
	tBar.Visible = hasCount == true
	tracker.Size = UDim2.fromOffset(360, hasCount and 110 or 88)
	if hasCount then
		local f = math.clamp((entry.prog or 0) / entry.n, 0, 1)
		TweenService:Create(tFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(f, 1) }):Play()
		tCount.Text = ("%d / %d"):format(entry.prog or 0, entry.n)
	end
	local key = entry.id .. ":" .. entry.step .. ":" .. (entry.prog or 0)
	if not tracker.Visible then
		tracker.Visible = true
		tracker.Position = UDim2.fromOffset(-380, 128)
		TweenService:Create(tracker, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Position = UDim2.fromOffset(12, 128) }):Play()
	elseif key ~= shownKey then
		UI.punch(tracker, 1.05)
	end
	shownKey = key
end

---------------------------------------------------------------------------
-- the "!" and "?" over townspeople
---------------------------------------------------------------------------
local markers = {} -- npcId -> BillboardGui
local function markerFor(npcId)
	local m = markers[npcId]
	if m then return m end
	m = UI.new("BillboardGui", {
		Name = "QuestMarker_" .. npcId,
		Size = UDim2.fromOffset(64, 64),
		StudsOffsetWorldSpace = Vector3.new(0, 5.4, 0),
		LightInfluence = 0,
		MaxDistance = 250,
		ResetOnSpawn = false,
		Enabled = false,
		Parent = player.PlayerGui,
	})
	local disc = UI.new("Frame", { Name = "Disc", Size = UDim2.fromOffset(52, 52), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = UI.C.white, Parent = m })
	UI.corner(disc, 26)
	UI.stroke(disc, 3.5)
	UI.gradient(disc, UI.lighten(GREEN, 0.4), GREEN)
	UI.label(disc, { Name = "Mark", Text = "!", Font = UI.BIG, TextScaled = false, TextSize = 40, Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.56), AnchorPoint = Vector2.new(0.5, 0.5), stroke = 3 })
	markers[npcId] = m
	return m
end

local function npcModel(id)
	local town = workspace:FindFirstChild("Townsfolk")
	return town and town:FindFirstChild(id)
end

local function refreshMarkers()
	local marks = state and state.marks or {}
	for id, m in markers do
		if not marks[id] then m.Enabled = false end
	end
	for id, kind in marks do
		local m = markerFor(id)
		local model = npcModel(id)
		m.Adornee = model and model:FindFirstChild("Head")
		m.Enabled = m.Adornee ~= nil and not player:GetAttribute("Talking")
		local disc = m.Disc
		local c = kind == "?" and UI.C.yellow or (kind == "!!" and STORY or GREEN)
		disc:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new(UI.lighten(c, 0.4), c)
		disc.Mark.Text = kind == "?" and "?" or "!"
	end
end
-- (townspeople stream in and out: re-attach now and then)
task.spawn(function()
	while true do
		task.wait(1)
		if state then refreshMarkers() end
	end
end)
player:GetAttributeChangedSignal("Talking"):Connect(function() if state then refreshMarkers() end end)
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, m in markers do
		if m.Enabled then
			m.Disc.Position = UDim2.new(0.5, 0, 0.5, -math.abs(math.sin(t * 3)) * 8)
			m.Disc.Rotation = math.sin(t * 5) * 5
		end
	end
end)

---------------------------------------------------------------------------
-- collectibles (only this player sees them)
---------------------------------------------------------------------------
local itemFolder = Instance.new("Folder")
itemFolder.Name = "QuestItems"
itemFolder.Parent = workspace
local items = {} -- { part, questId, index, pos }

local ITEM_COLORS = { Apple = Color3.fromRGB(230, 60, 60), ["Purple Flyer"] = Color3.fromRGB(170, 90, 255), ["Glowing Vial"] = Color3.fromRGB(120, 255, 90) }

local function clearItems(questId)
	for i = #items, 1, -1 do
		local it = items[i]
		if not questId or it.questId == questId then
			it.part:Destroy()
			table.remove(items, i)
		end
	end
end

local function makeItem(questId, index, name, pos)
	local color = ITEM_COLORS[name] or Color3.fromRGB(255, 220, 90)
	local p = Instance.new("Part")
	p.Name = "QuestItem"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(1.6, 1.6, 1.6)
	p.Color = color
	p.Material = Enum.Material.Neon
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.CFrame = CFrame.new(pos + Vector3.new(0, 2.4, 0))
	p.Parent = itemFolder
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 10
	light.Brightness = 2
	light.Parent = p
	local att = Instance.new("Attachment")
	att.Parent = p
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(color)
	sparkle.Size = NumberSequence.new(0.5, 0)
	sparkle.Lifetime = NumberRange.new(0.6, 1)
	sparkle.Rate = 8
	sparkle.Speed = NumberRange.new(1, 2)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.LightEmission = 1
	sparkle.Parent = att
	local bb = UI.new("BillboardGui", { Size = UDim2.fromOffset(160, 30), StudsOffsetWorldSpace = Vector3.new(0, 2, 0), MaxDistance = 80, LightInfluence = 0, Parent = p })
	UI.label(bb, { Text = name, Size = UDim2.fromScale(1, 1), TextColor3 = UI.lighten(color, 0.4), stroke = 2.5 })
	table.insert(items, { part = p, questId = questId, index = index, pos = pos, base = p.Position, taking = false })
end

local function collected(it)
	it.taking = true
	sfx("Collect")
	local p = it.part
	TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Size = Vector3.new(0.1, 0.1, 0.1), CFrame = p.CFrame + Vector3.new(0, 3, 0) }):Play()
	task.delay(0.36, function() p:Destroy() end)
	for i, x in items do
		if x == it then table.remove(items, i) break end
	end
end

RunService.Heartbeat:Connect(function()
	if #items == 0 then return end
	local t = os.clock()
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for _, it in items do
		if not it.taking then
			it.part.CFrame = CFrame.new(it.base + Vector3.new(0, math.sin(t * 2 + it.index) * 0.4, 0)) * CFrame.Angles(0, t * 1.5, 0)
			if r and (r.Position - it.part.Position).Magnitude < 6 then
				it.taking = true
				task.spawn(function()
					local ok, res = pcall(Action.InvokeServer, Action, "tqCollect", it.questId, it.index)
					if ok and type(res) == "table" and res.ok then collected(it) else it.taking = false end
				end)
			end
		end
	end
end)

---------------------------------------------------------------------------
-- stamps
---------------------------------------------------------------------------
local function stamp(text, color, sub)
	local holder = UI.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.26), Size = UDim2.fromOffset(760, 150), ZIndex = 30, Parent = root })
	local t = UI.label(holder, { Text = text, Font = UI.BIG, TextColor3 = color, Size = UDim2.new(1, 0, 0, 80), Rotation = -3, ZIndex = 30, stroke = 5 })
	local s
	if sub and sub ~= "" then
		s = UI.label(holder, { Text = sub, TextColor3 = UI.C.white, Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 86), ZIndex = 30, stroke = 3 })
	end
	UI.pop(holder, 2)
	task.delay(3, function()
		for _, l in { t, s } do
			if l then
				TweenService:Create(l, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
				TweenService:Create(l:FindFirstChildOfClass("UIStroke"), TweenInfo.new(0.5), { Transparency = 1 }):Play()
			end
		end
		task.wait(0.55)
		holder:Destroy()
	end)
end

---------------------------------------------------------------------------
-- the log
---------------------------------------------------------------------------
local panel = UI.panel(root, { name = "QuestLogPanel", title = "\u{1F4DC} QUEST LOG", color = GREEN, size = UDim2.fromOffset(760, 520) })
local tabs = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), ZIndex = 12, Parent = panel.body })
UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), Parent = tabs })
local summary = UI.label(panel.body, { Text = "", TextColor3 = UI.C.ink, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0, 220, 0, 30), Position = UDim2.new(1, -224, 0, 8), ZIndex = 12, stroke = 0 })
local list = UI.new("ScrollingFrame", {
	Name = "List",
	Size = UDim2.new(1, 0, 1, -56),
	Position = UDim2.fromOffset(0, 56),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	ScrollBarImageColor3 = UI.C.ink,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ZIndex = 12,
	Parent = panel.body,
})
UI.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
UI.new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), Parent = list })

local tab = "active"
local tabButtons = {}

local function zify(obj, z)
	obj.ZIndex = z
	for _, d in obj:GetDescendants() do
		if d:IsA("GuiObject") then d.ZIndex = z + 1 end
	end
end

local function rewardLine(r)
	if not r then return "" end
	local out = {}
	if r.incomeSecs or r.min then table.insert(out, "\u{1F4B5} cash") end
	if r.candy then table.insert(out, ("\u{1F36C} %d candy"):format(r.candy)) end
	if r.vials then table.insert(out, ("\u{1F9EA} %d vial%s"):format(r.vials, r.vials == 1 and "" or "s")) end
	for id, n in r.gear or {} do
		local g = Config.GearById and Config.GearById[id]
		table.insert(out, ("%d %s"):format(n, g and g.name or id))
	end
	if r.unlock then table.insert(out, "\u{1F513} " .. areaName(r.unlock)) end
	return table.concat(out, "   ")
end

local function entryCard(q, order, height)
	local color = lineColor(q)
	local card = UI.new("Frame", { BackgroundColor3 = UI.C.white, Size = UDim2.new(1, 0, 0, height), LayoutOrder = order, ZIndex = 13, Parent = list })
	UI.corner(card, 14)
	UI.stroke(card, 3)
	UI.gradient(card, Color3.fromRGB(255, 253, 246), Color3.fromRGB(246, 238, 220))
	local tag = UI.new("Frame", { Size = UDim2.fromOffset(84, 24), Position = UDim2.fromOffset(12, 10), BackgroundColor3 = color, ZIndex = 14, Parent = card })
	UI.corner(tag, 8)
	UI.stroke(tag, 2)
	UI.label(tag, { Text = q.line == "story" and "STORY" or "TOWN", Font = UI.BIG, Size = UDim2.new(1, -8, 1, -4), Position = UDim2.fromOffset(4, 2), ZIndex = 15, stroke = 1.5 })
	UI.label(card, { Text = q.title, Font = UI.BIG, TextColor3 = UI.darken(color, 0.25), TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -250, 0, 28), Position = UDim2.fromOffset(106, 8), ZIndex = 14, stroke = 0 })
	local giver = q.giver and Townsfolk.byId[q.giver]
	UI.label(card, { Text = (giver and (giver.name .. " \u{2022} ") or "") .. areaName(q.area), TextColor3 = UI.C.grey, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -250, 0, 18), Position = UDim2.fromOffset(106, 36), ZIndex = 14, stroke = 0 })
	return card
end

local function redraw()
	for _, c in list:GetChildren() do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	for name, b in tabButtons do
		b.setColor(name == tab and GREEN or UI.C.grey)
	end
	if not state then return end
	summary.Text = ("%d / %d quests done"):format(state.done or 0, state.total or #Quests.list)
	local order = 0
	if tab == "active" then
		if #state.active == 0 then
			UI.label(list, { Text = "No quests yet. Look for a \"!\" over someone in town!", TextColor3 = UI.C.grey, Size = UDim2.new(1, 0, 0, 40), ZIndex = 13, stroke = 0 })
		end
		for i, a in state.active do
			local q = Quests.byId[a.id]
			if q then
				-- the tracked quest on top, then the story, then the rest
				order = (a.id == state.tracked) and 0 or (q.line == "story" and 1 or 1 + i)
				local h = 76 + #q.steps * 24 + 28
				local card = entryCard(q, order, h)
				for i, s in q.steps do
					local done, now = i < a.step, i == a.step
					local txt = (done and "\u{2714} " or now and "\u{25B6} " or "\u{2022} ") .. s.text
					if now and a.n and a.n > 1 then txt ..= ("  (%d/%d)"):format(a.prog or 0, a.n) end
					UI.label(card, { Text = txt, TextColor3 = done and Color3.fromRGB(60, 160, 90) or now and UI.C.ink or UI.C.grey, Font = now and UI.BIG or UI.FONT, TextXAlignment = Enum.TextXAlignment.Left, TextScaled = false, TextSize = 18, Size = UDim2.new(1, -40, 0, 22), Position = UDim2.fromOffset(20, 62 + (i - 1) * 24), ZIndex = 14, stroke = 0 })
				end
				UI.label(card, { Text = "Reward: " .. rewardLine(q.reward), TextColor3 = Color3.fromRGB(40, 140, 70), TextXAlignment = Enum.TextXAlignment.Left, TextScaled = false, TextSize = 17, Size = UDim2.new(1, -40, 0, 22), Position = UDim2.new(0, 20, 1, -30), ZIndex = 14, stroke = 0 })
				local tracked = a.id == state.tracked
				local tb = UI.button(card, { text = tracked and "TRACKING" or "TRACK", color = tracked and UI.C.orange or UI.C.blue, size = UDim2.fromOffset(118, 38), position = UDim2.new(1, -12, 0, 10), anchor = Vector2.new(1, 0), font = UI.BIG, onClick = function()
					pcall(Action.InvokeServer, Action, "tqTrack", a.id)
				end })
				zify(tb.button, 15)
				if q.line == "town" then
					local db = UI.button(card, { text = "DROP", color = UI.C.red, size = UDim2.fromOffset(74, 30), position = UDim2.new(1, -12, 0, 54), anchor = Vector2.new(1, 0), font = UI.BIG, onClick = function()
						pcall(Action.InvokeServer, Action, "tqAbandon", a.id)
					end })
					zify(db.button, 15)
				end
			end
		end
	elseif tab == "available" then
		for _, v in state.avail do
			local q = Quests.byId[v.id]
			if q then
				order += 1
				local card = entryCard(q, order, 96)
				local giver = q.giver and Townsfolk.byId[q.giver]
				local how = giver and ("Talk to %s in %s"):format(giver.name, areaName(q.area)) or "Starts by itself"
				if not v.room then how ..= "  (finish one of your quests first)" end
				UI.label(card, { Text = "\u{1F449} " .. how, TextColor3 = UI.C.ink, TextXAlignment = Enum.TextXAlignment.Left, TextScaled = false, TextSize = 18, Size = UDim2.new(1, -40, 0, 22), Position = UDim2.fromOffset(20, 62), ZIndex = 14, stroke = 0 })
			end
		end
		for _, v in state.locked do
			local q = Quests.byId[v.id]
			if q then
				order += 1
				local card = entryCard(q, order, 96)
				card.BackgroundTransparency = 0.3
				UI.label(card, { Text = "\u{1F512} " .. v.why, TextColor3 = UI.C.grey, TextXAlignment = Enum.TextXAlignment.Left, TextScaled = false, TextSize = 18, Size = UDim2.new(1, -40, 0, 22), Position = UDim2.fromOffset(20, 62), ZIndex = 14, stroke = 0 })
			end
		end
		if order == 0 then
			UI.label(list, { Text = "Nothing new right now. Grow your school to open more of the town!", TextColor3 = UI.C.grey, Size = UDim2.new(1, 0, 0, 40), ZIndex = 13, stroke = 0 })
		end
	end
end

for i, name in { "active", "available" } do
	local b = UI.button(tabs, { text = name:upper(), color = GREEN, size = UDim2.fromOffset(150, 42), layoutOrder = i, font = UI.BIG, onClick = function()
		tab = name
		sfx("Ding")
		redraw()
	end })
	zify(b.button, 12)
	tabButtons[name] = b
end
panel.onOpen = redraw

local function toggle()
	panel.toggle()
end
if bus then
	local e = bus:FindFirstChild("OpenQuests") or Instance.new("BindableEvent")
	e.Name = "OpenQuests"
	e.Parent = bus
	e.Event:Connect(toggle)
end
tracker.Activated:Connect(toggle)
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.J and player:GetAttribute("UI_Quests") then toggle() end
end)

---------------------------------------------------------------------------
-- pushes
---------------------------------------------------------------------------
local known -- active ids we've already announced
Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
	if kind == "tq" then
		local before = known
		known = {}
		for _, a in data.active do known[a.id] = true end
		state = data
		refreshTracker()
		refreshMarkers()
		if panel.frame.Visible then redraw() end
		-- a quest that wasn't there before: NEW QUEST
		if before then
			for id in known do
				if not before[id] then
					local q = Quests.byId[id]
					if q then
						sfx("Ding")
						stamp(q.line == "story" and "NEW STORY QUEST!" or "NEW QUEST!", lineColor(q), q.title)
					end
				end
			end
		end
		-- collectibles belong to the step that's on now
		for i = #items, 1, -1 do
			local it = items[i]
			if not known[it.questId] then
				it.part:Destroy()
				table.remove(items, i)
			end
		end
	elseif kind == "tqItems" then
		clearItems(data.id)
		for i, pos in data.spots do
			if not (data.got and (data.got[i] or data.got[tostring(i)])) then makeItem(data.id, i, data.item, pos) end
		end
	elseif kind == "tqDone" then
		clearItems(data.id)
		sfx("Cheer")
		stamp("QUEST COMPLETE!", UI.C.green, table.concat(data.rewards or {}, "   "))
	end
end)
