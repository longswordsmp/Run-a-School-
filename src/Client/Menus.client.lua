-- StarterPlayer.StarterPlayerScripts.Menus
-- Left button bar and its panels: Shop (School Supplies, Teachers, School Builder), Upgrades,
-- School Board, Yearbook, Name School, Settings; big centre announcements; welcome-back popup.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")
local templates = ReplicatedStorage:WaitForChild("StudentTemplates")
local bus = ReplicatedStorage:WaitForChild("ClientBus", 10)

local player = Players.LocalPlayer
local gui = UI.new("ScreenGui", {
	Name = "Menus",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
	DisplayOrder = 5,
	Parent = player:WaitForChild("PlayerGui"),
})

local function call(action, ...)
	local ok, res = pcall(Action.InvokeServer, Action, action, ...)
	if not ok then return { ok = false, err = "Connection hiccup" } end
	return res
end

local function sfx(name)
	if bus and bus:FindFirstChild("Sfx") then bus.Sfx:Fire(name) end
end

local function cash()
	return player:GetAttribute("Cash") or 0
end

-- raise a gui object and everything in it to at least z
local function lift(obj, z)
	if obj:IsA("GuiObject") then obj.ZIndex = math.max(obj.ZIndex, z) end
	for _, d in obj:GetDescendants() do
		if d:IsA("GuiObject") then d.ZIndex = math.max(d.ZIndex, z + 1) end
	end
end

---------------------------------------------------------------------------
-- big centre announcements
---------------------------------------------------------------------------
local function announce(text, color)
	local t = UI.label(gui, {
		Name = "Announce",
		Text = text,
		Font = UI.BIG,
		TextColor3 = color or UI.C.yellow,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.new(0.8, 0, 0, 70),
		ZIndex = 50,
		stroke = 4,
	})
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(900, 70), Parent = t })
	UI.pop(t, 0.2)
	task.delay(2.2, function()
		TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1, Position = UDim2.fromScale(0.5, 0.24) }):Play()
		TweenService:Create(t.UIStroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		task.wait(0.45)
		t:Destroy()
	end)
end
Remotes:WaitForChild("Announce").OnClientEvent:Connect(announce)

---------------------------------------------------------------------------
-- shared pieces
---------------------------------------------------------------------------
local panels = {}

local function scrollList(parent, padding)
	local sf = UI.new("ScrollingFrame", {
		Name = "List",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = UI.C.ink,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 11,
		Parent = parent,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, padding or 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sf })
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 6), Parent = sf })
	return sf
end

-- a shop row: icon (emoji or model), title, description, and a buy button on the right
local function shopRow(parent, order, opts)
	local r = UI.new("Frame", {
		Name = opts.name or "Row",
		BackgroundColor3 = opts.bg or Color3.fromRGB(255, 236, 206),
		Size = UDim2.new(1, 0, 0, opts.height or 86),
		LayoutOrder = order,
		ZIndex = 12,
		Parent = parent,
	})
	UI.corner(r, 14)
	UI.stroke(r, 3)
	local iconBox = UI.new("Frame", {
		Name = "IconBox",
		BackgroundColor3 = opts.iconBg or Color3.fromRGB(255, 255, 255),
		Size = UDim2.fromOffset(68, 68),
		Position = UDim2.new(0, 9, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = 13,
		Parent = r,
	})
	UI.corner(iconBox, 12)
	UI.stroke(iconBox, 2.5)
	if opts.model then
		UI.viewport(iconBox, opts.model, { zindex = 14, zoom = 0.95 })
	else
		UI.label(iconBox, { Name = "Icon", Text = opts.icon or "", Size = UDim2.new(1, -10, 1, -10), Position = UDim2.fromOffset(5, 5), ZIndex = 14, stroke = 0 })
	end
	local title = UI.label(r, { Name = "Title", Text = opts.title or "", Font = UI.BIG, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -280, 0, 30), Position = UDim2.new(0, 88, 0, 10), ZIndex = 13 })
	local desc = UI.label(r, { Name = "Desc", Text = opts.desc or "", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.navy, Size = UDim2.new(1, -280, 0, 20), Position = UDim2.new(0, 88, 0, 44), ZIndex = 13, stroke = 0 })
	local sub = UI.label(r, { Name = "Sub", Text = opts.sub or "", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(40, 150, 70), Size = UDim2.new(1, -280, 0, 16), Position = UDim2.new(0, 88, 0, 64), ZIndex = 13, stroke = 0 })
	local buy = UI.button(r, { text = "", color = UI.C.green, size = UDim2.fromOffset(170, 58), position = UDim2.new(1, -12, 0.5, 0), anchor = Vector2.new(1, 0.5) })
	lift(buy.button, 13)
	return { frame = r, title = title, desc = desc, sub = sub, buy = buy }
end

-- show a row's button as owned / locked / priced
local function setState(row, state, price, lockText)
	local b = row.buy
	b.button:SetAttribute("Price", price)
	if state == "owned" then
		b.setText("\u{2714} OWNED")
		b.setEnabled(false)
		b.setColor(Color3.fromRGB(120, 200, 130))
	elseif state == "locked" then
		b.setText("\u{1F512} " .. (lockText or "LOCKED"))
		b.setEnabled(false)
	else
		b.setText(Config.formatCash(price))
		local can = cash() >= price
		b.setEnabled(can)
		if can then b.setColor(UI.C.green) end
	end
end

-- keep priced buttons in sync with cash
local priced = {}
player:GetAttributeChangedSignal("Cash"):Connect(function()
	for row, info in priced do
		if row.frame.Parent and info.state == "buy" then setState(row, "buy", info.price) end
	end
end)

local function tabs(parent, names, onSelect)
	local bar = UI.new("Frame", { Name = "Tabs", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), ZIndex = 11, Parent = parent })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = bar })
	local buttons = {}
	local function select(i)
		for j, b in buttons do
			b.setColor(j == i and names[j][2] or Color3.fromRGB(150, 150, 165))
		end
		onSelect(i)
	end
	for i, spec in names do
		local b = UI.button(bar, { text = spec[1], color = spec[2], size = UDim2.fromOffset(spec[3] or 190, 42), layoutOrder = i, onClick = function()
			sfx("Ding")
			select(i)
		end })
		lift(b.button, 12)
		buttons[i] = b
	end
	return select
end

---------------------------------------------------------------------------
-- Shop: School Supplies / Teachers / School Builder
---------------------------------------------------------------------------
do
	local panel = UI.panel(gui, { name = "Shop", title = "SCHOOL SHOP", color = UI.C.green, size = UDim2.fromOffset(820, 560) })
	panels.Shop = panel
	local info = UI.label(panel.body, { Name = "Info", Text = "", TextColor3 = UI.C.navy, Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 52), ZIndex = 12, stroke = 0 })
	local pages = {}
	for i = 1, 3 do
		pages[i] = UI.new("Frame", { Name = "Page" .. i, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -86), Position = UDim2.fromOffset(0, 84), Visible = false, ZIndex = 11, Parent = panel.body })
	end
	local profile
	local current = 1
	local teacherFloor = 1

	-- supplies
	local supplyList = scrollList(pages[1])
	local supplyRows = {}
	for i, s in Config.Supplies do
		supplyRows[s.id] = shopRow(supplyList, i, {
			name = s.id, icon = s.icon, title = s.name,
			desc = ("+%d School IQ"):format(s.iq),
			sub = "Shows up on every desk. Kept forever.",
			iconBg = Color3.fromRGB(220, 240, 255),
		})
		supplyRows[s.id].buy.button.Activated:Connect(function()
			if not supplyRows[s.id].buy.button.Active then return end
			local res = call("buySupply", s.id)
			if res and res.ok == false then UI.punch(supplyRows[s.id].frame, 1.04) end
			panel.refresh()
		end)
	end

	-- teachers (one floor at a time)
	local floorBar = UI.new("Frame", { Name = "Floors", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), ZIndex = 11, Parent = pages[2] })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = floorBar })
	local floorButtons = {}
	local teacherHolder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -46), Position = UDim2.fromOffset(0, 46), ZIndex = 11, Parent = pages[2] })
	local teacherList = scrollList(teacherHolder)
	local teacherRows = {}
	local teacherTemplates = ReplicatedStorage:WaitForChild("TeacherTemplates", 10)
	for i, t in Config.Teachers do
		local model = teacherTemplates and teacherTemplates:WaitForChild(t.id, 5)
		teacherRows[t.id] = shopRow(teacherList, i, {
			name = t.id, model = model, icon = "\u{1F9D1}\u{200D}\u{1F3EB}", title = t.name,
			desc = ("%s \u{2022} +%d%% tuition on their floor"):format(t.title, math.floor((t.mult - 1) * 100 + 0.5)),
			sub = "Teaches at the chalkboard. Kept forever.",
			iconBg = Color3.fromRGB(255, 240, 210),
		})
		teacherRows[t.id].buy.button.Activated:Connect(function()
			if not teacherRows[t.id].buy.button.Active then return end
			call("hireTeacher", teacherFloor, t.id)
			panel.refresh()
		end)
	end
	for f = 1, 3 do
		local b = UI.button(floorBar, { text = "Floor " .. f, color = UI.C.orange, size = UDim2.fromOffset(130, 38), layoutOrder = f, onClick = function()
			teacherFloor = f
			sfx("Ding")
			panel.refresh()
		end })
		lift(b.button, 12)
		floorButtons[f] = b
	end

	-- builder
	local buildList = scrollList(pages[3])
	local buildRows = {}
	for i, b in Config.Builds do
		local replaces = b.replaces and Config.BuildById[b.replaces]
		buildRows[b.id] = shopRow(buildList, i, {
			name = b.id, icon = b.icon, title = b.name,
			desc = ("+%d Reputation"):format(b.rep),
			sub = replaces and ("Replaces the " .. replaces.name .. ". Kept forever.") or "Built on your campus. Kept forever.",
			iconBg = Color3.fromRGB(220, 255, 220),
		})
		buildRows[b.id].buy.button.Activated:Connect(function()
			if not buildRows[b.id].buy.button.Active then return end
			call("buyBuild", b.id)
			panel.refresh()
		end)
	end

	local function show(row, state, price, lockText)
		setState(row, state, price, lockText)
		priced[row] = { state = state, price = price }
	end

	function panel.refresh()
		profile = call("profile")
		if not profile or profile.ok == false then return end
		local tier = profile.tier
		if current == 1 then
			info.Text = ("School IQ %d  \u{2192}  tuition x%.2f"):format(profile.iq, profile.iq / 100)
			for _, s in Config.Supplies do
				local row = supplyRows[s.id]
				if profile.supplies[s.id] then
					show(row, "owned")
				elseif tier < s.tier then
					show(row, "locked", nil, Config.Tiers[s.tier].name)
				else
					show(row, "buy", s.price)
				end
			end
		elseif current == 2 then
			local floors = profile.floors
			local hired = profile.teachers[tostring(teacherFloor)]
			local hiredDef = hired and Config.TeacherById[hired]
			info.Text = hiredDef and ("Floor %d: %s (+%d%%)"):format(teacherFloor, hiredDef.name, math.floor((hiredDef.mult - 1) * 100 + 0.5))
				or ("Floor %d has no teacher yet"):format(teacherFloor)
			for f, b in floorButtons do
				b.setEnabled(f <= floors)
				if f <= floors then b.setColor(f == teacherFloor and UI.C.orange or Color3.fromRGB(150, 150, 165)) end
			end
			for _, t in Config.Teachers do
				local row = teacherRows[t.id]
				if hiredDef and t.id == hiredDef.id then
					show(row, "owned")
					row.buy.setText("\u{2714} TEACHING")
				elseif hiredDef and t.mult <= hiredDef.mult then
					show(row, "locked", nil, "WORSE")
				elseif tier < t.tier then
					show(row, "locked", nil, Config.Tiers[t.tier].name)
				else
					show(row, "buy", t.price)
					row.buy.setText("HIRE " .. Config.formatCash(t.price))
				end
			end
		else
			info.Text = ("Reputation %d  \u{2192}  tuition x%.2f"):format(profile.rep, 1 + profile.rep / 100)
			for _, b in Config.Builds do
				local row = buildRows[b.id]
				if profile.builds[b.id] then
					show(row, "owned")
				elseif tier < b.tier then
					show(row, "locked", nil, Config.Tiers[b.tier].name)
				else
					show(row, "buy", b.price)
				end
			end
		end
	end

	local selectTab = tabs(panel.body, {
		{ "\u{270F}\u{FE0F} Supplies", UI.C.blue },
		{ "\u{1F9D1}\u{200D}\u{1F3EB} Teachers", UI.C.orange },
		{ "\u{1F3D7}\u{FE0F} Builder", UI.C.green },
	}, function(i)
		current = i
		for j, pg in pages do pg.Visible = j == i end
		panel.refresh()
	end)
	panel.onOpen = function()
		selectTab(current)
	end
	panel.select = function(i)
		selectTab(i)
	end
end

---------------------------------------------------------------------------
-- Upgrades: school upgrades and desk rows
---------------------------------------------------------------------------
do
	local panel = UI.panel(gui, { name = "Upgrades", title = "UPGRADES", color = UI.C.orange, size = UDim2.fromOffset(760, 540) })
	panels.Upgrades = panel
	local list = scrollList(panel.body)
	local rows = {}
	for i, u in Config.Upgrades do
		rows[u.id] = shopRow(list, 10 + i, { name = u.id, icon = u.icon, title = u.name, desc = u.desc, iconBg = Color3.fromRGB(255, 230, 200) })
		rows[u.id].buy.button.Activated:Connect(function()
			if not rows[u.id].buy.button.Active then return end
			call("buyUpgrade", u.id)
			panel.onOpen()
		end)
	end
	local rowRows = {}
	for f = 1, 3 do
		rowRows[f] = shopRow(list, f, { name = "Desks" .. f, icon = "\u{1FA91}", title = "Desks: Floor " .. f, desc = "", iconBg = Color3.fromRGB(220, 240, 255) })
		rowRows[f].buy.button.Activated:Connect(function()
			if not rowRows[f].buy.button.Active then return end
			call("buyRow", f)
			panel.onOpen()
		end)
	end
	panel.onOpen = function()
		local res = call("upgrades")
		if not res or res.ok == false then return end
		for _, u in res.upgrades do
			local row = rows[u.id]
			row.sub.Text = ("Level %d / %d"):format(u.level, u.max)
			if u.cost then
				setState(row, "buy", u.cost)
				priced[row] = { state = "buy", price = u.cost }
			else
				setState(row, "owned")
				row.buy.setText("MAX")
				priced[row] = nil
			end
		end
		for f, r in res.rows do
			local row = rowRows[f]
			row.desc.Text = ("%d desks of %d"):format(r.owned * Config.DesksPerRow, r.max * Config.DesksPerRow)
			if not r.unlocked then
				setState(row, "locked", nil, "NEW FLOOR")
				row.sub.Text = "Opens when the School Board grants a new floor"
				priced[row] = nil
			elseif r.cost then
				setState(row, "buy", r.cost)
				row.buy.setText("+4 " .. Config.formatCash(r.cost))
				row.sub.Text = "Four more desks in this classroom"
				priced[row] = { state = "buy", price = r.cost }
			else
				setState(row, "owned")
				row.buy.setText("FULL")
				row.sub.Text = "Every desk on this floor is open"
				priced[row] = nil
			end
		end
	end
end

---------------------------------------------------------------------------
-- School Board
---------------------------------------------------------------------------
do
	local panel = UI.panel(gui, { name = "Board", title = "SCHOOL BOARD", color = UI.C.purple, size = UDim2.fromOffset(620, 470) })
	panels.Board = panel
	local b = panel.body
	local now = UI.label(b, { Text = "", TextColor3 = UI.C.navy, Size = UDim2.new(1, 0, 0, 24), ZIndex = 12, stroke = 0 })
	local nextName = UI.label(b, { Text = "", Font = UI.BIG, TextColor3 = UI.C.yellow, Size = UDim2.new(1, 0, 0, 46), Position = UDim2.fromOffset(0, 28), ZIndex = 12, stroke = 3 })
	-- requirements
	local function req(y)
		local f = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 236, 206), Size = UDim2.new(1, 0, 0, 64), Position = UDim2.fromOffset(0, y), ZIndex = 12, Parent = b })
		UI.corner(f, 12)
		UI.stroke(f, 3)
		local check = UI.label(f, { Text = "", Size = UDim2.fromOffset(44, 44), Position = UDim2.new(0, 10, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), ZIndex = 13, stroke = 0 })
		local text = UI.label(f, { Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.navy, Size = UDim2.new(1, -70, 0, 26), Position = UDim2.fromOffset(62, 6), ZIndex = 13, stroke = 0 })
		local barBg = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(60, 60, 70), Size = UDim2.new(1, -76, 0, 16), Position = UDim2.fromOffset(62, 38), ZIndex = 13, Parent = f })
		UI.corner(barBg, 8)
		local fill = UI.new("Frame", { BackgroundColor3 = UI.C.green, Size = UDim2.fromScale(0, 1), ZIndex = 14, Parent = barBg })
		UI.corner(fill, 8)
		return { check = check, text = text, fill = fill, bar = barBg }
	end
	local cashReq = req(84)
	local studentReq = req(156)
	local reward = UI.label(b, { Text = "", TextColor3 = Color3.fromRGB(40, 150, 70), Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 230), ZIndex = 12, stroke = 0 })
	local warn = UI.label(b, { Text = "Your cash and students go back to the start. Supplies, teachers, builds, upgrades and desks stay.", TextWrapped = true, TextColor3 = Color3.fromRGB(150, 60, 60), Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 258), ZIndex = 12, stroke = 0 })
	_ = warn
	local go = UI.button(b, { text = "REQUEST REVIEW", color = UI.C.purple, size = UDim2.fromOffset(300, 64), position = UDim2.new(0.5, 0, 1, -4), anchor = Vector2.new(0.5, 1), font = UI.BIG })
	lift(go.button, 12)
	local info
	local function refresh()
		info = call("boardInfo")
		if not info or info.ok == false then return end
		now.Text = ("Now: %s  (tuition x%s)"):format(info.current, tostring(math.floor(info.currentMult * 100 + 0.5) / 100))
		nextName.Text = "\u{2192} " .. info.name:upper()
		cashReq.check.Text = info.hasCash and "\u{2705}" or "\u{1F4B0}"
		cashReq.text.Text = ("Bring %s  (you have %s)"):format(Config.formatCash(info.cash), Config.formatCash(cash()))
		cashReq.fill.Size = UDim2.fromScale(math.clamp(cash() / info.cash, 0, 1), 1)
		if info.needs then
			studentReq.check.Text = info.hasNeeded and "\u{2705}" or "\u{1F393}"
			studentReq.text.Text = "Seat " .. info.needsName .. " at one of your desks"
			studentReq.fill.Size = UDim2.fromScale(info.hasNeeded and 1 or 0, 1)
		else
			studentReq.check.Text = "\u{2705}"
			studentReq.text.Text = "No special student needed"
			studentReq.fill.Size = UDim2.fromScale(1, 1)
		end
		reward.Text = ("Reward: tuition x%s%s"):format(tostring(info.mult), (info.floors and info.floors > 1) and ("  \u{2022}  " .. info.floors .. " floors") or "")
		go.setEnabled(info.hasCash and info.hasNeeded)
	end
	go.button.Activated:Connect(function()
		if not go.button.Active then return end
		go.setEnabled(false)
		panel.close()
		local res = call("review")
		if res and res.ok == false and res.err then announce(res.err, UI.C.red) end
	end)
	player:GetAttributeChangedSignal("Cash"):Connect(function()
		if panel.frame.Visible and info and info.ok ~= false then
			cashReq.fill.Size = UDim2.fromScale(math.clamp(cash() / info.cash, 0, 1), 1)
			local has = cash() >= info.cash
			if has ~= info.hasCash then refresh() end
		end
	end)
	panel.onOpen = refresh
end

---------------------------------------------------------------------------
-- Yearbook
---------------------------------------------------------------------------
do
	local panel = UI.panel(gui, { name = "Yearbook", title = "YEARBOOK", color = UI.C.purple, size = UDim2.fromOffset(760, 520) })
	panels.Yearbook = panel
	local count = UI.label(panel.body, {
		Name = "Count",
		Text = "",
		TextColor3 = UI.C.navy,
		Size = UDim2.new(1, 0, 0, 28),
		ZIndex = 12,
		stroke = 0,
	})
	local holder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -34), Position = UDim2.fromOffset(0, 34), ZIndex = 11, Parent = panel.body })
	local grid = UI.grid(holder, UDim2.fromOffset(128, 168), UDim2.fromOffset(10, 10))
	local built = false
	local cards = {}

	local function build()
		built = true
		for _, def in Config.Students do
			local rarity = Config.RarityById[def.rarity]
			local model = templates:FindFirstChild(def.id)
			local card = UI.card(grid, {
				name = def.id,
				color = rarity.color == Color3.fromRGB(20, 20, 20) and Color3.fromRGB(60, 60, 70) or rarity.color,
				title = def.name,
				subtitle = rarity.id,
				layoutOrder = def.order,
				model = model,
			})
			cards[def.id] = card
		end
	end

	panel.onOpen = function()
		if not built then build() end
		local profile = call("profile")
		local owned = {}
		for _, key in (profile and profile.index) or {} do
			owned[key:match("^[^|]+")] = true
		end
		local n = 0
		for id, card in cards do
			local has = owned[id] == true
			if has then n += 1 end
			local vp = card:FindFirstChild("Viewport")
			if vp then
				vp.ImageColor3 = has and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
				vp.ImageTransparency = has and 0 or 0.4
			end
			card.Title.Text = has and Config.StudentById[id].name or "???"
		end
		count.Text = ("%d / %d students enrolled at least once"):format(n, #Config.Students)
	end
end

---------------------------------------------------------------------------
-- Name School
---------------------------------------------------------------------------
do
	local panel = UI.panel(gui, { name = "NameSchool", title = "NAME YOUR SCHOOL", color = UI.C.blue, size = UDim2.fromOffset(520, 280) })
	panels.NameSchool = panel
	local current = UI.label(panel.body, { Text = "", TextColor3 = UI.C.navy, Size = UDim2.new(1, 0, 0, 30), ZIndex = 12, stroke = 0 })
	local box = UI.new("TextBox", {
		Name = "Input",
		Text = "",
		PlaceholderText = "Type a name...",
		Font = UI.FONT,
		TextScaled = true,
		TextColor3 = UI.C.ink,
		PlaceholderColor3 = UI.C.grey,
		BackgroundColor3 = UI.C.white,
		ClearTextOnFocus = false,
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.fromOffset(0, 40),
		ZIndex = 12,
		Parent = panel.body,
	})
	UI.corner(box, 12)
	UI.stroke(box, 3)
	UI.padding(box, 10)
	local err = UI.label(panel.body, { Text = "", TextColor3 = UI.C.red, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 106), ZIndex = 12, stroke = 0 })
	local save = UI.button(panel.body, { text = "SAVE NAME", color = UI.C.green, size = UDim2.fromOffset(220, 58), position = UDim2.new(0.5, 0, 1, -4), anchor = Vector2.new(0.5, 1) })
	lift(save.button, 12)
	save.button.Activated:Connect(function()
		err.Text = ""
		local res = call("nameSchool", box.Text)
		if res and res.ok then
			current.Text = "Now: " .. res.name
			announce(res.name:upper(), UI.C.blue)
			panel.close()
		else
			err.Text = (res and res.err) or "Try again"
		end
	end)
	panel.onOpen = function()
		local profile = call("profile")
		current.Text = "Now: " .. ((profile and profile.schoolName) or "")
		err.Text = ""
	end
end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
do
	local panel = UI.panel(gui, { name = "Settings", title = "SETTINGS", color = UI.C.navy, size = UDim2.fromOffset(460, 300) })
	panels.Settings = panel
	local list = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 11, Parent = panel.body })
	UI.new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local function toggle(order, label, attr, key)
		local r = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 236, 206), Size = UDim2.new(1, 0, 0, 70), LayoutOrder = order, ZIndex = 12, Parent = list })
		UI.corner(r, 14)
		UI.stroke(r, 3)
		UI.label(r, { Text = label, Font = UI.BIG, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -170, 0, 34), Position = UDim2.new(0, 16, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), ZIndex = 13 })
		local b = UI.button(r, { text = "", size = UDim2.fromOffset(130, 50), position = UDim2.new(1, -12, 0.5, 0), anchor = Vector2.new(1, 0.5) })
		lift(b.button, 13)
		local function show()
			local on = player:GetAttribute(attr) ~= false
			b.setText(on and "ON" or "OFF")
			b.setColor(on and UI.C.green or UI.C.red)
		end
		b.button.Activated:Connect(function()
			local on = not (player:GetAttribute(attr) ~= false)
			player:SetAttribute(attr, on)
			call("setting", key, on)
			show()
		end)
		player:GetAttributeChangedSignal(attr):Connect(show)
		show()
	end
	toggle(1, "\u{1F3B5} Music", "MusicOn", "music")
	toggle(2, "\u{1F50A} Sound effects", "SfxOn", "sfx")
end

---------------------------------------------------------------------------
-- Daily reward: a 7-day streak
---------------------------------------------------------------------------
do
	local panel = UI.panel(gui, { name = "Daily", title = "DAILY REWARD", color = UI.C.orange, size = UDim2.fromOffset(780, 380) })
	panels.Daily = panel
	local streakText = UI.label(panel.body, { Text = "", TextColor3 = UI.C.navy, Size = UDim2.new(1, 0, 0, 28), ZIndex = 12, stroke = 0 })
	local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 170), Position = UDim2.fromOffset(0, 36), ZIndex = 11, Parent = panel.body })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = row })
	local tiles = {}
	for i = 1, 7 do
		local t = UI.new("Frame", { Name = "Day" .. i, Size = UDim2.fromOffset(98, 160), BackgroundColor3 = UI.C.white, LayoutOrder = i, ZIndex = 12, Parent = row })
		UI.corner(t, 14)
		UI.stroke(t, 3)
		local grad = UI.gradient(t, Color3.fromRGB(255, 240, 210), Color3.fromRGB(255, 210, 150))
		UI.label(t, { Name = "Title", Text = "DAY " .. i, Font = UI.BIG, Size = UDim2.new(1, -8, 0, 30), Position = UDim2.fromOffset(4, 6), ZIndex = 13, stroke = 2 })
		UI.label(t, { Name = "Icon", Text = i == 7 and "\u{1F381}" or "\u{2B50}", Size = UDim2.new(1, -30, 0, 46), Position = UDim2.fromOffset(15, 38), ZIndex = 13, stroke = 0 })
		local txt = UI.label(t, { Name = "Text", Text = "", TextWrapped = true, TextColor3 = UI.C.navy, Size = UDim2.new(1, -10, 0, 60), Position = UDim2.fromOffset(5, 92), ZIndex = 13, stroke = 0 })
		tiles[i] = { frame = t, text = txt, grad = grad }
	end
	local claim = UI.button(panel.body, { text = "CLAIM!", color = UI.C.green, size = UDim2.fromOffset(260, 62), position = UDim2.new(0.5, 0, 1, -4), anchor = Vector2.new(0.5, 1), font = UI.BIG })
	lift(claim.button, 12)
	local state
	function panel.refresh()
		state = call("daily")
		if not state or state.ok == false then return end
		local days = state.streak == 1 and "1 day" or (state.streak .. " days")
		streakText.Text = state.claimed and ("Streak: %s. Come back tomorrow for day %d!"):format(days, state.day % 7 + 1)
			or ("Streak: %s. Today is day %d!"):format(days, state.day)
		for i, t in tiles do
			t.text.Text = state.rewards[i] or ""
			local isToday = i == state.day
			local done = i < state.day or (isToday and state.claimed)
			t.grad.Color = isToday and ColorSequence.new(Color3.fromRGB(180, 255, 180), Color3.fromRGB(70, 210, 110))
				or done and ColorSequence.new(Color3.fromRGB(220, 220, 225), Color3.fromRGB(170, 170, 180))
				or ColorSequence.new(Color3.fromRGB(255, 240, 210), Color3.fromRGB(255, 210, 150))
			if isToday then UI.punch(t.frame, 1.08) end
		end
		claim.setEnabled(not state.claimed)
		claim.setText(state.claimed and "CLAIMED" or "CLAIM!")
	end
	claim.button.Activated:Connect(function()
		if not claim.button.Active then return end
		local res = call("claimDaily")
		if res and res.ok then sfx("Cheer") end
		panel.refresh()
	end)
	panel.onOpen = panel.refresh
	-- returning principals see it once per session when today's reward is waiting
	task.delay(8, function()
		local s = call("daily")
		local prof = call("profile")
		if s and s.ok ~= false and not s.claimed and prof and prof.tutorial and prof.tutorial > 5 then
			panel.open()
		end
	end)
end

---------------------------------------------------------------------------
-- Robux store: passes and products (only opens when you press it)
---------------------------------------------------------------------------
do
	local panel = UI.panel(gui, { name = "Store", title = "STORE", color = Color3.fromRGB(40, 190, 90), size = UDim2.fromOffset(820, 560) })
	panels.Store = panel
	local pages = {}
	for i = 1, 2 do
		pages[i] = UI.new("Frame", { Name = "Page" .. i, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -56), Position = UDim2.fromOffset(0, 54), Visible = false, ZIndex = 11, Parent = panel.body })
	end
	local rows = { pass = {}, product = {} }
	local passList = scrollList(pages[1])
	for i, x in Config.Passes do
		local row = shopRow(passList, i, { name = x.key, icon = x.icon, title = x.name, desc = x.desc, sub = "Game pass \u{2022} yours forever", iconBg = Color3.fromRGB(230, 255, 230) })
		rows.pass[x.key] = row
		row.buy.button.Activated:Connect(function()
			if not row.buy.button.Active then return end
			call("buy", "pass", x.key)
		end)
	end
	local productList = scrollList(pages[2])
	for i, x in Config.Products do
		local row = shopRow(productList, i, { name = x.key, icon = x.icon, title = x.name, desc = x.desc, sub = "One-time purchase", iconBg = Color3.fromRGB(230, 245, 255), height = 96 })
		row.desc.TextWrapped = true
		row.desc.Size = UDim2.new(1, -280, 0, 34)
		row.sub.Position = UDim2.new(0, 88, 0, 76)
		rows.product[x.key] = row
		row.buy.button.Activated:Connect(function()
			if not row.buy.button.Active then return end
			call("buy", "product", x.key)
		end)
	end
	local function robuxText(n)
		return "R$ " .. n
	end
	local current = 1
	function panel.refresh()
		local res = call("store")
		if not res or res.ok == false then return end
		for _, s in res.passes do
			local row = rows.pass[s.key]
			local def
			for _, x in Config.Passes do if x.key == s.key then def = x end end
			if s.owned then
				row.buy.setText("\u{2714} OWNED")
				row.buy.setEnabled(false)
			elseif not s.ready then
				row.buy.setText("SOON")
				row.buy.setEnabled(false)
			else
				row.buy.setText(robuxText(def.robux))
				row.buy.setEnabled(true)
				row.buy.setColor(Color3.fromRGB(40, 190, 90))
			end
		end
		for _, s in res.products do
			local row = rows.product[s.key]
			local def
			for _, x in Config.Products do if x.key == s.key then def = x end end
			if not s.ready then
				row.buy.setText("SOON")
				row.buy.setEnabled(false)
			else
				row.buy.setText(robuxText(def.robux))
				row.buy.setEnabled(true)
				row.buy.setColor(Color3.fromRGB(40, 190, 90))
			end
		end
	end
	local selectTab = tabs(panel.body, {
		{ "\u{1F451} Passes", Color3.fromRGB(40, 190, 90), 220 },
		{ "\u{1F4B0} Boosts", UI.C.blue, 220 },
	}, function(i)
		current = i
		for j, pg in pages do pg.Visible = j == i end
		panel.refresh()
	end)
	panel.onOpen = function() selectTab(current) end
	panel.select = function(i) selectTab(i) end
	-- owning a pass changes what the store shows
	player.AttributeChanged:Connect(function(attr)
		if attr:sub(1, 5) == "Pass_" and panel.frame.Visible then panel.refresh() end
	end)
end

---------------------------------------------------------------------------
-- Admin (only for admins): buses, events, spawns, money rain, server luck
---------------------------------------------------------------------------
do
	local panel = UI.panel(gui, { name = "Admin", title = "ADMIN PANEL", color = UI.C.red, size = UDim2.fromOffset(760, 520) })
	panels.Admin = panel
	local list = scrollList(panel.body, 10)
	local function section(order, title, buttons)
		local holder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 110), LayoutOrder = order, ZIndex = 11, Parent = list })
		UI.label(holder, { Text = title, Font = UI.BIG, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.navy, Size = UDim2.new(1, 0, 0, 28), ZIndex = 12, stroke = 0 })
		local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 72), Position = UDim2.fromOffset(0, 32), ZIndex = 11, Parent = holder })
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Wraps = true, Parent = row })
		for i, spec in buttons do
			local b = UI.button(row, { text = spec[1], color = spec[2], size = UDim2.fromOffset(spec[5] or 110, 56), layoutOrder = i, onClick = function()
				local res = call("admin", spec[3], spec[4])
				sfx(res and res.ok and "Ding" or "Error")
			end })
			lift(b.button, 12)
		end
	end
	section(1, "\u{1F68C} BUSES", {
		{ "Late Bus", UI.C.orange, "bus", "LateBus" },
		{ "Honor Roll", UI.C.yellow, "bus", "HonorBus" },
		{ "Field Trip", UI.C.purple, "bus", "FieldTrip" },
		{ "Lucky Bus", UI.C.green, "bus", "Lucky" },
		{ "Welcome", UI.C.blue, "bus", "Welcome" },
	})
	section(2, "\u{1F389} EVENTS", {
		{ "Snow Day", Color3.fromRGB(120, 190, 255), "event", "SnowDay" },
		{ "Science Fair", UI.C.green, "event", "ScienceFair" },
		{ "Picture Day", UI.C.grey, "event", "PictureDay" },
		{ "Halloween", UI.C.orange, "event", "Halloween" },
		{ "Space Camp", UI.C.purple, "event", "SpaceCamp" },
		{ "End Event", UI.C.red, "event", "stop" },
	})
	section(3, "\u{2728} SPAWN 3 KIDS", {
		{ "Legendary", Color3.fromRGB(255, 170, 30), "spawn", "Legendary" },
		{ "Mythic", Color3.fromRGB(255, 50, 90), "spawn", "Mythic" },
		{ "Prodigy", Color3.fromRGB(90, 200, 255), "spawn", "Prodigy" },
		{ "Secret", Color3.fromRGB(40, 40, 50), "spawn", "Secret" },
	})
	section(4, "\u{1F4B8} SERVER", {
		{ "Money Rain", UI.C.green, "money" },
		{ "Luck x2", UI.C.blue, "luck", 2 },
		{ "Luck x3", UI.C.purple, "luck", 3 },
		{ "Recess Now", UI.C.orange, "recess" },
		{ "+$1B (me)", UI.C.grey, "cash", 1e9 },
	})
end

---------------------------------------------------------------------------
-- welcome back: what the school earned while you were away
---------------------------------------------------------------------------
do
	local panel = UI.panel(gui, { name = "Welcome", title = "WELCOME BACK!", color = UI.C.green, size = UDim2.fromOffset(500, 300) })
	local text = UI.label(panel.body, { Text = "", TextWrapped = true, TextColor3 = UI.C.navy, Size = UDim2.new(1, 0, 0, 60), ZIndex = 12, stroke = 0 })
	local amount = UI.label(panel.body, { Text = "", Font = UI.BIG, TextColor3 = UI.C.green, Size = UDim2.new(1, 0, 0, 60), Position = UDim2.fromOffset(0, 64), ZIndex = 12, stroke = 3 })
	local ok = UI.button(panel.body, { text = "COLLECT!", color = UI.C.green, size = UDim2.fromOffset(240, 60), position = UDim2.new(0.5, 0, 1, -4), anchor = Vector2.new(0.5, 1), font = UI.BIG, onClick = function()
		sfx("Collect")
		panel.close()
	end })
	lift(ok.button, 12)
	Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
		if kind ~= "offline" then return end
		local mins = math.floor((data.away or 0) / 60)
		local away = mins >= 60 and ("%dh %dm"):format(mins // 60, mins % 60) or (mins .. " minutes")
		text.Text = "Your teachers kept teaching for " .. away .. " while you were gone. The school earned:"
		amount.Text = "+" .. Config.formatCash(data.amount or 0)
		panel.open()
	end)
end

---------------------------------------------------------------------------
-- left button bar
---------------------------------------------------------------------------
local bar = UI.new("Frame", {
	Name = "SideBar",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 12, 0.5, 0),
	Size = UDim2.fromOffset(170, 520),
	Parent = gui,
})
UI.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(78, 78),
	CellPadding = UDim2.fromOffset(8, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Parent = bar,
})

local function sideButton(order, icon, caption, color, panel)
	local b = UI.button(bar, { name = caption, text = "", color = color, size = UDim2.fromOffset(78, 78), radius = 18, layoutOrder = order })
	UI.label(b.button, {
		Name = "Icon",
		Text = icon,
		Size = UDim2.new(1, -16, 0.56, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		AnchorPoint = Vector2.new(0.5, 0),
		ZIndex = 4,
		stroke = 0,
	})
	UI.label(b.button, {
		Name = "Caption",
		Text = caption,
		Size = UDim2.new(1, -6, 0.28, 0),
		Position = UDim2.new(0.5, 0, 1, -5),
		AnchorPoint = Vector2.new(0.5, 1),
		ZIndex = 4,
		stroke = 2,
	})
	b.button.Activated:Connect(function()
		sfx("Ding")
		panel.toggle()
	end)
	return b
end

sideButton(1, "\u{1F6D2}", "Shop", UI.C.green, panels.Shop)
sideButton(2, "\u{2B06}\u{FE0F}", "Upgrades", UI.C.orange, panels.Upgrades)
sideButton(3, "\u{1F3DB}\u{FE0F}", "Board", UI.C.purple, panels.Board)
sideButton(4, "\u{1F4D6}", "Yearbook", UI.C.pink, panels.Yearbook)
sideButton(5, "\u{270F}\u{FE0F}", "Name", UI.C.blue, panels.NameSchool)
sideButton(6, "\u{2699}\u{FE0F}", "Settings", UI.C.navy, panels.Settings)
sideButton(0, "\u{1F48E}", "Store", Color3.fromRGB(40, 190, 90), panels.Store)
sideButton(9, "\u{1F4C5}", "Daily", UI.C.orange, panels.Daily)
-- Teleport Home pass: a home button once you own it
local homeButton
local function refreshHome()
	if player:GetAttribute("Pass_TeleportHome") and not homeButton then
		homeButton = UI.button(bar, { name = "Home", text = "", color = UI.C.orange, size = UDim2.fromOffset(78, 78), radius = 18, layoutOrder = 8 })
		UI.label(homeButton.button, { Text = "\u{1F3E0}", Size = UDim2.new(1, -16, 0.56, 0), Position = UDim2.new(0.5, 0, 0, 6), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 4, stroke = 0 })
		UI.label(homeButton.button, { Text = "Home", Size = UDim2.new(1, -6, 0.28, 0), Position = UDim2.new(0.5, 0, 1, -5), AnchorPoint = Vector2.new(0.5, 1), ZIndex = 4, stroke = 2 })
		homeButton.button.Activated:Connect(function()
			local res = call("teleportHome")
			sfx(res and res.ok and "Whoosh" or "Error")
		end)
	end
end
player:GetAttributeChangedSignal("Pass_TeleportHome"):Connect(refreshHome)
refreshHome()
-- the admin button appears only for admins
local adminButton
local function refreshAdmin()
	if player:GetAttribute("Admin") and not adminButton then
		adminButton = sideButton(7, "\u{1F6E0}\u{FE0F}", "Admin", UI.C.red, panels.Admin)
	end
end
player:GetAttributeChangedSignal("Admin"):Connect(refreshAdmin)
refreshAdmin()

-- other scripts (tutorial, prompts) can open a panel by name
local openBus = bus and (bus:FindFirstChild("OpenPanel") or (function()
	local e = Instance.new("BindableEvent")
	e.Name = "OpenPanel"
	e.Parent = bus
	return e
end)())
if openBus then
	openBus.Event:Connect(function(name, tab)
		local p = panels[name]
		if not p then return end
		p.open()
		if tab and p.select then p.select(tab) end
	end)
end
