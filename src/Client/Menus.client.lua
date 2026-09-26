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
local uiRoot, uiScale = UI.autoScale(gui)

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
local liveAnnounce = {}
local function announce(text, color)
	-- ones still on screen slide up to make room instead of drawing over each other
	for _, old in liveAnnounce do
		TweenService:Create(old, TweenInfo.new(0.2), { Position = old.Position - UDim2.fromOffset(0, 76) }):Play()
	end
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
	table.insert(liveAnnounce, t)
	task.delay(2.2, function()
		TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1, Position = t.Position - UDim2.fromScale(0, 0.06) }):Play()
		TweenService:Create(t.UIStroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		task.wait(0.45)
		table.remove(liveAnnounce, table.find(liveAnnounce, t))
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
	for i = 1, 6 do
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

	-- candy (Janitor Stan's Confiscation Closet)
	local candyList = scrollList(pages[4])
	local candyRows = {}
	for i, c in Config.CandyShop do
		candyRows[c.id] = shopRow(candyList, i, {
			name = c.id, icon = c.icon, title = c.name, desc = c.desc,
			sub = c.kind == "trap" and "Protects your school" or "Decor for your campus",
			iconBg = Color3.fromRGB(255, 225, 240),
		})
		candyRows[c.id].buy.button.Activated:Connect(function()
			if not candyRows[c.id].buy.button.Active then return end
			call("buyCandy", c.id)
			panel.refresh()
		end)
	end

	-- the Ticket shop (TicketService): letters and candy any time, each event's trophy during it
	local ticketList = scrollList(pages[5])
	local ticketRows = {}
	for i, it in Config.EventShop do
		ticketRows[it.id] = shopRow(ticketList, 10 + i, {
			name = it.id, icon = it.icon, title = it.name,
			desc = it.kind == "letter" and "A guaranteed " .. it.rarity .. " kid you can afford, on your bench" or "For Janitor Stan's Closet",
			sub = "Collect event tokens during events for tickets",
			iconBg = Color3.fromRGB(255, 235, 200),
		})
	end
	for i, id in { "SnowDay", "FieldDay", "ScienceFair", "PromNight", "PictureDay", "Throwback", "Halloween", "WizardWeek", "CandyCarnival", "SpaceCamp", "HostileTakeover", "Graduation" } do
		local info = Config.EventInfo[id]
		ticketRows["Trophy_" .. id] = shopRow(ticketList, 100 + i, {
			name = "Trophy_" .. id, icon = info.icon, title = info.name .. " Trophy",
			desc = "For the trophy case on your lawn",
			sub = "Only while " .. info.name .. " is on",
			iconBg = Color3.fromRGB(255, 245, 210),
		})
		ticketRows["Trophy_" .. id].frame:SetAttribute("Order", 100 + i)
	end
	for id, row in ticketRows do
		row.buy.button.Activated:Connect(function()
			if not row.buy.button.Active then return end
			local res = call("buyTicket", id)
			if res and res.ok == false then UI.punch(row.frame, 1.04) end
			panel.refresh()
		end)
	end

	-- Heist Gear (GearService): Janitor Stan's stall outside the Closet
	local gearList = scrollList(pages[6])
	local gearRows = {}
	for i, g in Config.Gear do
		gearRows[g.id] = shopRow(gearList, i, {
			name = g.id, icon = g.icon, title = g.name, desc = g.desc,
			sub = g.kind == "use" and "One use each, in your backpack" or (g.kind == "tool" and "Yours to keep, in your backpack" or "Yours to keep, always on"),
			iconBg = Color3.fromRGB(235, 225, 255),
		})
		gearRows[g.id].buy.button.Activated:Connect(function()
			if not gearRows[g.id].buy.button.Active then return end
			local res = call("buyGear", g.id)
			if res and res.ok == false then UI.punch(gearRows[g.id].frame, 1.04) end
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
		elseif current == 6 then
			local st = call("gearShop")
			if not st or st.ok == false then return end
			info.Text = "\u{1F977} Sneak past guards, grab the kid, get out. Hold SHIFT to sprint, C to sneak."
			for _, it in st.items do
				local row = gearRows[it.id]
				if row then
					if it.owned then
						show(row, "owned")
					elseif it.count and it.count >= st.max then
						show(row, "locked", nil, ("x%d FULL"):format(it.count))
					else
						show(row, "buy", it.price)
						if it.count and it.count > 0 then row.buy.setText(("%s (x%d)"):format(Config.formatCash(it.price), it.count)) end
					end
				end
			end
		elseif current == 5 then
			local st = call("tickets")
			if not st or st.ok == false then return end
			local ev = st.event
			info.Text = ev and ("\u{1F39F}\u{FE0F} %d tickets  \u{2022}  %s is on: grab the tokens around you!"):format(st.tickets, Config.EventInfo[ev].name)
				or ("\u{1F39F}\u{FE0F} %d tickets  \u{2022}  tokens appear during events"):format(st.tickets)
			for _, it in Config.EventShop do
				local row = ticketRows[it.id]
				setState(row, "buy", 0)
				row.buy.setText("\u{1F39F}\u{FE0F} " .. it.tickets)
				row.buy.setEnabled(st.tickets >= it.tickets)
				if st.tickets >= it.tickets then row.buy.setColor(UI.C.orange) end
			end
			for id, info in Config.EventInfo do
				local row = ticketRows["Trophy_" .. id]
				-- the running event's trophy goes to the top
				row.frame.LayoutOrder = id == ev and 0 or row.frame:GetAttribute("Order")
				if st.trophies[id] then
					setState(row, "owned")
				elseif id == ev then
					setState(row, "buy", 0)
					row.buy.setText("\u{1F39F}\u{FE0F} " .. Config.TrophyTickets)
					row.buy.setEnabled(st.tickets >= Config.TrophyTickets)
					if st.tickets >= Config.TrophyTickets then row.buy.setColor(UI.C.orange) end
				else
					setState(row, "locked", nil, info.name)
				end
			end
		elseif current == 4 then
			local candy = player:GetAttribute("Candy") or 0
			local traps = player:GetAttribute("Traps") or 0
			info.Text = ("\u{1F36C} %d candy  \u{2022}  %d trap uses set  (bust Snack Smugglers for more)"):format(candy, traps)
			for _, c in Config.CandyShop do
				local row = candyRows[c.id]
				if c.kind == "decor" and profile.builds[c.id] then
					setState(row, "owned")
				else
					row.buy.setText("\u{1F36C} " .. c.candy)
					row.buy.setEnabled(candy >= c.candy)
					if candy >= c.candy then row.buy.setColor(UI.C.pink) end
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
		{ "\u{270F}\u{FE0F} Supplies", UI.C.blue, 122 },
		{ "\u{1F9D1}\u{200D}\u{1F3EB} Teachers", UI.C.orange, 122 },
		{ "\u{1F3D7}\u{FE0F} Builder", UI.C.green, 122 },
		{ "\u{1F36C} Candy", UI.C.pink, 110 },
		{ "\u{1F39F}\u{FE0F} Event", Color3.fromRGB(255, 165, 40), 110 },
		{ "\u{1F392} Gear", UI.C.purple, 110 },
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
	local warn = UI.label(b, { Text = "Your cash and students go back to the start (graduate kids first for Diplomas: hold G). Supplies, teachers, builds, upgrades and desks stay.", TextWrapped = true, TextColor3 = Color3.fromRGB(150, 60, 60), Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 258), ZIndex = 12, stroke = 0 })
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
	local panel = UI.panel(gui, { name = "Yearbook", title = "YEARBOOK", color = UI.C.purple, size = UDim2.fromOffset(760, 560) })
	panels.Yearbook = panel
	local count = UI.label(panel.body, {
		Name = "Count",
		Text = "",
		TextColor3 = UI.C.navy,
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, 50),
		ZIndex = 12,
		stroke = 0,
	})
	local holder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -84), Position = UDim2.fromOffset(0, 84), ZIndex = 11, Parent = panel.body })
	-- the Scrapbook: the story so far, one page per moment, in the order they happen
	local scrapPage = UI.new("Frame", { Name = "Scrapbook", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -84), Position = UDim2.fromOffset(0, 84), Visible = false, ZIndex = 11, Parent = panel.body })
	local scrapList = scrollList(scrapPage)
	local pages = {}
	local function scrapEntry(order, kind, title, speaker, text, unlockAt)
		local color = kind == "intro" and UI.C.blue or kind == "board" and UI.C.purple or UI.C.orange
		local f = UI.new("Frame", { Name = "Page" .. order, Size = UDim2.new(1, -6, 0, 104), BackgroundColor3 = UI.C.white, LayoutOrder = order, ZIndex = 12, Parent = scrapList })
		UI.corner(f, 12)
		UI.stroke(f, 3)
		local bar = UI.new("Frame", { Size = UDim2.new(0, 12, 1, -12), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = color, ZIndex = 13, Parent = f })
		UI.corner(bar, 6)
		local t = UI.label(f, { Text = title, Font = UI.BIG, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -40, 0, 28), Position = UDim2.fromOffset(28, 6), ZIndex = 13, stroke = 1 })
		local q = UI.label(f, { Text = "", TextColor3 = UI.C.ink, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, -44, 0, 62), Position = UDim2.fromOffset(28, 36), ZIndex = 13, stroke = 0 })
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize = 20
		cap.Parent = q
		table.insert(pages, { title = t, quote = q, full = title, speaker = speaker, text = text, unlockAt = unlockAt })
	end
	scrapEntry(1, "intro", "Day One", "The Board Chair", table.concat(Config.IntroLines, " "), 1)
	for tier = 2, #Config.Tiers do
		local lines = {}
		for _, b in Config.BoardBeats[tier] or {} do
			local who = b[1]:gsub("(%a)([%w']*)", function(a, rest) return a:upper() .. rest:lower() end)
			table.insert(lines, ("%s: \"%s\""):format(who, b[3]))
		end
		table.insert(lines, ("The Board Chair: \"%s\""):format(Config.BoardLines[tier] or ""))
		scrapEntry(tier * 2, "board", Config.Tiers[tier].name .. "!", nil, table.concat(lines, "  "), tier)
		local i = tier - 1
		local ch = Config.Chapters[i]
		if ch then
			scrapEntry(tier * 2 + 1, "chapter", ("Chapter %d: %s"):format(i, ch.title), ch.host, ch.line, Config.ChapterTier(i))
		end
	end
	-- the Alumni Hall: Diplomas (from graduating kids) invite Alumni back
	local alumniPage = UI.new("Frame", { Name = "Alumni", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -84), Position = UDim2.fromOffset(0, 84), Visible = false, ZIndex = 11, Parent = panel.body })
	local alumniList = scrollList(alumniPage)
	local alumniRows = {}
	local refreshAlumni
	for i, a in Config.AlumniShop do
		local def = Config.StudentById[a.id]
		local row = shopRow(alumniList, i, {
			name = a.id, model = templates:FindFirstChild(a.id), icon = "\u{1F393}", title = def.name,
			desc = ("Earns %s/s \u{2022} enrolls for %s"):format(Config.formatCash(def.income), Config.formatCash(def.price)),
			sub = "Graduate kids (hold G at their desk) for Diplomas",
			iconBg = Color3.fromRGB(255, 240, 200),
		})
		row.buy.button.Activated:Connect(function()
			if not row.buy.button.Active then return end
			local res = call("inviteAlumni", a.id)
			refreshAlumni()
			if res and res.ok == false then
				UI.punch(row.frame, 1.04)
				if res.err then count.Text = "\u{26A0} " .. res.err end
				sfx("Error")
			end
		end)
		alumniRows[a.id] = row
	end
	refreshAlumni = function()
		local st = call("alumni")
		if not st or st.ok == false then return 0 end
		local open = st.tier >= st.openTier
		for _, it in st.shop do
			local row = alumniRows[it.id]
			if it.invited then
				setState(row, "owned")
				row.buy.setText("\u{2714} INVITED")
			elseif not open then
				setState(row, "locked", nil, Config.Tiers[st.openTier].name)
			else
				setState(row, "buy", 0)
				row.buy.setText("\u{1F393} " .. Config.formatCash(it.diplomas):gsub("%$", ""))
				row.buy.setEnabled(st.diplomas >= it.diplomas)
				if st.diplomas >= it.diplomas then row.buy.setColor(UI.C.purple) end
			end
		end
		count.Text = open and ("\u{1F393} %s Diplomas \u{2022} invite an Alumni back to your school"):format(Config.formatCash(st.diplomas):gsub("%$", ""))
			or ("\u{1F393} %s Diplomas \u{2022} the Alumni Hall opens at %s"):format(Config.formatCash(st.diplomas):gsub("%$", ""), Config.Tiers[st.openTier].name)
		return 1
	end

	do
		local lines = {}
		for _, l in Config.FinaleLines do
			local who = l[1]:gsub("(%a)([%w']*)", function(a, rest) return a:upper() .. rest:lower() end)
			table.insert(lines, ("%s: \"%s\""):format(who, l[3]))
		end
		scrapEntry(100, "intro", "Graduation Day", nil, table.concat(lines, "  "), #Config.Tiers)
	end
	local function refreshScrapbook(tier)
		local n = 0
		for _, pg in pages do
			local open = tier >= pg.unlockAt
			if open then n += 1 end
			pg.title.Text = open and pg.full or "???"
			pg.quote.Text = open and (pg.speaker and (pg.speaker .. ': "' .. pg.text .. '"') or pg.text) or "Keep growing your school to unlock this page."
			pg.quote.TextColor3 = open and UI.C.ink or UI.C.grey
		end
		return n
	end
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

	local yearTab = 1
	local refreshStudents
	local selectYearTab = tabs(panel.body, {
		{ "\u{1F4D6} Students", UI.C.purple, 220 },
		{ "\u{1F4DC} Scrapbook", UI.C.orange, 220 },
		{ "\u{1F393} Alumni", Color3.fromRGB(170, 110, 255), 220 },
	}, function(i)
		yearTab = i
		holder.Visible = i == 1
		scrapPage.Visible = i == 2
		alumniPage.Visible = i == 3
		if refreshStudents then refreshStudents() end
	end)
	panel.onOpen = function()
		selectYearTab(yearTab)
	end
	panel.select = function(i)
		selectYearTab(i)
	end
	refreshStudents = function()
		if not built then build() end
		if yearTab == 3 then
			refreshAlumni()
			return
		end
		local profile = call("profile")
		if yearTab == 2 then
			local n = refreshScrapbook(profile and profile.tier or 1)
			count.Text = ("%d / %d pages of the story"):format(n, #pages)
			return
		end
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
	local panel = UI.panel(gui, { name = "Daily", title = "DAILY", color = UI.C.orange, size = UDim2.fromOffset(780, 640) })
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
	local claim = UI.button(panel.body, { text = "CLAIM!", color = UI.C.green, size = UDim2.fromOffset(240, 50), position = UDim2.new(0.5, 0, 0, 204), anchor = Vector2.new(0.5, 0), font = UI.BIG })
	lift(claim.button, 12)

	-- Daily Requests (DailyService): three rows, one free reroll, then Loretta's Lunch Box
	local qMode = "daily"
	local modeButtons = {}
	for i, spec in { { "daily", "\u{1F4CB} TODAY" }, { "weekly", "\u{1F4C6} THIS WEEK" } } do
		local b = UI.button(panel.body, { text = spec[2], color = UI.C.orange, size = UDim2.fromOffset(170, 32), position = UDim2.fromOffset(4 + (i - 1) * 178, 262), font = UI.BIG, radius = 10 })
		lift(b.button, 12)
		modeButtons[spec[1]] = b
	end
	local resetText = UI.label(panel.body, { Text = "", TextColor3 = UI.C.grey, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0.4, -8, 0, 22), Position = UDim2.new(0.6, 0, 0, 270), ZIndex = 12, stroke = 0 })
	local qRows = {}
	for i = 1, 3 do
		local r = UI.new("Frame", { Name = "Request" .. i, Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 298 + (i - 1) * 50), BackgroundColor3 = UI.C.white, ZIndex = 12, Parent = panel.body })
		UI.corner(r, 12)
		UI.stroke(r, 3)
		local text = UI.label(r, { Text = "", TextColor3 = UI.C.ink, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0, 330, 0, 28), Position = UDim2.fromOffset(12, 8), ZIndex = 13, stroke = 0 })
		local barBg = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(70, 70, 80), Size = UDim2.fromOffset(200, 20), Position = UDim2.fromOffset(352, 12), ZIndex = 13, Parent = r })
		UI.corner(barBg, 10)
		local fill = UI.new("Frame", { BackgroundColor3 = UI.C.green, Size = UDim2.fromScale(0, 1), ZIndex = 14, Parent = barBg })
		UI.corner(fill, 10)
		local count = UI.label(barBg, { Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 15, stroke = 2 })
		local reward = UI.label(r, { Text = "", TextColor3 = UI.C.pink, Font = UI.BIG, Size = UDim2.fromOffset(80, 28), Position = UDim2.fromOffset(562, 8), ZIndex = 13, stroke = 1 })
		local reroll = UI.button(r, { text = "\u{1F504}", color = UI.C.blue, size = UDim2.fromOffset(84, 34), position = UDim2.new(1, -6, 0.5, 0), anchor = Vector2.new(1, 0.5), font = UI.BIG, radius = 10 })
		lift(reroll.button, 13)
		qRows[i] = { frame = r, text = text, fill = fill, count = count, reward = reward, reroll = reroll }
	end
	local box = UI.button(panel.body, { text = "\u{1F371} OPEN LUNCH BOX", color = UI.C.orange, size = UDim2.fromOffset(300, 60), position = UDim2.fromOffset(0, 456), font = UI.BIG })
	lift(box.button, 12)
	local boxNote = UI.label(panel.body, { Text = "Finish all 3 to open Loretta's Lunch Box", TextColor3 = UI.C.navy, TextWrapped = true, Size = UDim2.fromOffset(300, 34), Position = UDim2.fromOffset(0, 520), ZIndex = 12, stroke = 0 })
	local oddsText = UI.label(panel.body, { Text = "", TextColor3 = UI.C.navy, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextScaled = false, TextSize = 17, Size = UDim2.new(1, -330, 0, 100), Position = UDim2.fromOffset(322, 456), ZIndex = 12, stroke = 0 })
	local qState
	local function showRequests(q)
		if not q or q.ok == false then return end
		qState = q
		for i, r in qRows do
			local it = q.requests[i]
			r.frame.Visible = it ~= nil
			if it then
				r.text.Text = (it.done and "\u{2714} " or "") .. it.text
				r.text.TextColor3 = it.done and Color3.fromRGB(40, 150, 70) or UI.C.ink
				r.fill.Size = UDim2.fromScale(math.clamp(it.progress / it.count, 0, 1), 1)
				r.count.Text = ("%d / %d"):format(it.progress, it.count)
				r.reward.Text = it.done and "DONE" or ("+%d \u{1F36C}"):format(q.candy)
				r.reroll.button.Visible = q.canReroll and not it.done and it.progress == 0
			end
		end
		local weekly = q.kind == "weekly"
		box.setEnabled(q.boxReady == true)
		box.setText(q.boxOpened and (weekly and "OPENED THIS WEEK" or "OPENED TODAY") or (weekly and "\u{1F381} WEEKLY CHEST" or "\u{1F371} OPEN LUNCH BOX"))
		boxNote.Text = q.prize and ("You got: " .. q.prize .. "!") or (q.boxOpened and (weekly and "New requests on Monday" or "Come back tomorrow for 3 new requests"))
			or (q.boxReady and "Ready! Open it!" or (weekly and "Finish all 3 to open the Weekly Chest" or "Finish all 3 to open Loretta's Lunch Box"))
		local lines = { weekly and "The Weekly Chest holds:" or "Lunch Box odds:" }
		for _, o in q.odds do table.insert(lines, weekly and ("\u{2022} " .. o.text) or ("%s%%  %s"):format(tostring(o.pct), o.text)) end
		oddsText.Text = table.concat(lines, "\n")
		local h = math.floor(q.resetIn / 3600)
		resetText.Text = weekly and ("New requests in %dd %dh"):format(math.floor(h / 24), h % 24)
			or ("New requests in %dh %dm"):format(h, math.floor(q.resetIn % 3600 / 60))
		for mode, b in modeButtons do
			b.setColor(mode == qMode and UI.C.orange or Color3.fromRGB(150, 150, 165))
		end
	end
	for i, r in qRows do
		r.reroll.button.Activated:Connect(function()
			local seen = qState and qState.requests and qState.requests[i]
			local res = call("rerollDaily", i, seen and seen.id)
			if res and res.ok then
				sfx("Whoosh")
				showRequests(res)
			elseif res and res.requests then
				showRequests(res)
			end
		end)
	end
	for mode, b in modeButtons do
		b.button.Activated:Connect(function()
			qMode = mode
			sfx("Ding")
			showRequests(call(mode == "weekly" and "weeklyQ" or "dailyQ"))
		end)
	end
	-- OpenPanel("Daily", 2) opens straight on this week's requests
	panel.select = function(i)
		qMode = i == 2 and "weekly" or "daily"
		showRequests(call(qMode == "weekly" and "weeklyQ" or "dailyQ"))
	end
	box.button.Activated:Connect(function()
		if not box.button.Active then return end
		local res = call(qMode == "weekly" and "openWeeklyChest" or "openLunchBox")
		if res and res.ok ~= false then showRequests(res) end
	end)
	Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
		if (kind == "dailyQ" and qMode == "daily") or (kind == "weeklyQ" and qMode == "weekly") then showRequests(data) end
	end)
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
		showRequests(call(qMode == "weekly" and "weeklyQ" or "dailyQ"))
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
		-- six buttons fit on a row; the section grows with its rows
		local lines = math.ceil(#buttons / 6)
		local holder = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40 + lines * 64), LayoutOrder = order, ZIndex = 11, Parent = list })
		UI.label(holder, { Text = title, Font = UI.BIG, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.navy, Size = UDim2.new(1, 0, 0, 28), ZIndex = 12, stroke = 0 })
		local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, lines * 64), Position = UDim2.fromOffset(0, 32), ZIndex = 11, Parent = holder })
		UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(110, 56), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
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
		{ "The Pick", UI.C.navy, "bus", "Pick" },
	})
	section(2, "\u{1F389} EVENTS", {
		{ "Snow Day", Color3.fromRGB(120, 190, 255), "event", "SnowDay" },
		{ "Science Fair", UI.C.green, "event", "ScienceFair" },
		{ "Picture Day", UI.C.grey, "event", "PictureDay" },
		{ "Halloween", UI.C.orange, "event", "Halloween" },
		{ "Space Camp", UI.C.purple, "event", "SpaceCamp" },
		{ "Field Day", UI.C.yellow, "event", "FieldDay" },
		{ "Prom Night", UI.C.pink, "event", "PromNight" },
		{ "Throwback", UI.C.orange, "event", "Throwback" },
		{ "Wizard Week", UI.C.purple, "event", "WizardWeek" },
		{ "Candy Carnival", UI.C.pink, "event", "CandyCarnival" },
		{ "Takeover", UI.C.navy, "event", "HostileTakeover" },
		{ "Graduation", UI.C.grey, "event", "Graduation" },
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
-- Pop Quiz: a question from the server, three answers, ten seconds
---------------------------------------------------------------------------
do
	local card = UI.new("Frame", {
		Name = "PopQuiz",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 90),
		Size = UDim2.fromOffset(560, 210),
		BackgroundColor3 = UI.C.cream,
		Visible = false,
		ZIndex = 40,
		Parent = gui,
	})
	UI.corner(card, 18)
	UI.stroke(card, 4)
	local head = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = UI.C.white, ZIndex = 41, Parent = card })
	UI.corner(head, 18)
	UI.gradient(head, UI.lighten(UI.C.purple, 0.3), UI.C.purple)
	UI.label(head, { Text = "\u{1F514} POP QUIZ!", Font = UI.BIG, Size = UDim2.new(0.7, 0, 1, -8), Position = UDim2.fromOffset(12, 4), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42, stroke = 2 })
	local timer = UI.label(head, { Text = "10", Font = UI.BIG, Size = UDim2.new(0.25, 0, 1, -8), Position = UDim2.new(0.75, -12, 0, 4), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 42, stroke = 2 })
	local question = UI.label(card, { Text = "", TextColor3 = UI.C.ink, Size = UDim2.new(1, -24, 0, 50), Position = UDim2.fromOffset(12, 48), ZIndex = 41, stroke = 0 })
	local row = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 70), Position = UDim2.fromOffset(12, 110), ZIndex = 41, Parent = card })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = row })
	local buttons = {}
	local quiz
	local done = false
	local colors = { UI.C.blue, UI.C.orange, UI.C.green }
	for i = 1, 3 do
		local b = UI.button(row, { text = "", color = colors[i], size = UDim2.fromOffset(170, 64), layoutOrder = i })
		lift(b.button, 42)
		buttons[i] = b
		b.button.Activated:Connect(function()
			if done or not quiz then return end
			done = true
			local res = call("quizAnswer", quiz.id, i)
			if res and res.right then
				question.Text = "Correct! +" .. Config.formatCash(res.amount)
				question.TextColor3 = Color3.fromRGB(40, 160, 70)
				b.setColor(UI.C.green)
			elseif res and res.ok then
				question.Text = "Nope! It was: " .. quiz.options[res.answer]
				question.TextColor3 = UI.C.red
				b.setColor(UI.C.red)
			end
			task.delay(1.6, function() card.Visible = false end)
		end)
	end
	Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
		if kind ~= "quiz" then return end
		quiz = data
		done = false
		question.Text = data.question
		question.TextColor3 = UI.C.ink
		for i, b in buttons do
			b.setText(data.options[i] or "")
			b.setColor(colors[i])
			b.setEnabled(true)
		end
		card.Visible = true
		UI.pop(card, 0.5)
		task.spawn(function()
			while card.Visible and quiz == data do
				local left = math.max(0, math.ceil(data.closes - workspace:GetServerTimeNow()))
				timer.Text = tostring(left)
				if left <= 0 then
					task.wait(0.6)
					if quiz == data and not done then card.Visible = false end
					break
				end
				task.wait(0.2)
			end
		end)
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

-- each side button shows once the server unlocks it (UnlockService: player attribute UI_<caption>);
-- a fresh unlock pops in with a NEW! badge that stays until the button is used
local sideButtons = {}
local function newBadge(button)
	local badge = UI.new("Frame", { Name = "New", Size = UDim2.fromOffset(46, 22), Position = UDim2.new(1, 8, 0, -8), AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = UI.C.red, ZIndex = 6, Parent = button })
	UI.corner(badge, 8)
	UI.stroke(badge, 2)
	UI.label(badge, { Text = "NEW!", Font = UI.BIG, Size = UDim2.new(1, -6, 1, -4), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 7, stroke = 1.5 })
	task.spawn(function()
		while badge.Parent do
			UI.punch(badge, 1.2)
			task.wait(1.2)
		end
	end)
	return badge
end
local function watchUnlock(caption, b)
	local attr = "UI_" .. caption
	b.button.Visible = player:GetAttribute(attr) == true
	player:GetAttributeChangedSignal(attr):Connect(function()
		local on = player:GetAttribute(attr) == true
		if on and not b.button.Visible then
			b.button.Visible = true
			UI.pop(b.button, 0.3)
		end
		b.button.Visible = on
	end)
end

local function sideButton(order, icon, caption, color, panel)
	local b = UI.button(bar, { name = caption, text = "", color = color, size = UDim2.fromOffset(78, 78), radius = 18, layoutOrder = order })
	sideButtons[caption] = b
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
		local badge = b.button:FindFirstChild("New")
		if badge then badge:Destroy() end
		sfx("Ding")
		if panel then panel.toggle() end
	end)
	watchUnlock(caption, b)
	return b
end

sideButton(1, "\u{1F6D2}", "Shop", UI.C.green, panels.Shop)
sideButton(2, "\u{2B06}\u{FE0F}", "Upgrades", UI.C.orange, panels.Upgrades)
sideButton(3, "\u{1F3DB}\u{FE0F}", "Board", UI.C.purple, panels.Board)
sideButton(4, "\u{1F4D6}", "Yearbook", UI.C.pink, panels.Yearbook)
sideButton(5, "\u{270F}\u{FE0F}", "Name", UI.C.blue, panels.NameSchool)
sideButton(6, "\u{2699}\u{FE0F}", "Settings", UI.C.navy, panels.Settings)
sideButton(0, "\u{1F48E}", "Store", Color3.fromRGB(40, 190, 90), panels.Store)
local dailyButton = sideButton(9, "\u{1F4C5}", "Daily", UI.C.orange, panels.Daily)
-- the Co-op panel lives in Coop.client
sideButton(8, "\u{1F465}", "Coop", Color3.fromRGB(140, 80, 240), { toggle = function()
	local e = bus and bus:FindFirstChild("OpenCoop")
	if e then e:Fire() end
end })
-- the VexCorp Files book lives in Files.client
sideButton(10, "\u{1F5C2}\u{FE0F}", "Files", UI.C.purple, { toggle = function()
	local e = bus and bus:FindFirstChild("OpenFiles")
	if e then e:Fire() end
end })
-- a red "!" when today's streak reward or the Lunch Box is waiting (DailyService sets DailyReady)
do
	local badge = UI.new("Frame", { Name = "Badge", Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, 4, 0, -4), AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = UI.C.red, ZIndex = 6, Visible = false, Parent = dailyButton.button })
	UI.corner(badge, 13)
	UI.stroke(badge, 2)
	UI.label(badge, { Text = "!", Font = UI.BIG, Size = UDim2.fromScale(1, 1), ZIndex = 7, stroke = 2 })
	local function refresh()
		badge.Visible = player:GetAttribute("DailyReady") == true
	end
	player:GetAttributeChangedSignal("DailyReady"):Connect(refresh)
	refresh()
	task.spawn(function()
		while true do
			if badge.Visible then UI.punch(badge, 1.25) end
			task.wait(1.6)
		end
	end)
end
-- Home: back to your school in one press (H on a keyboard); a short cooldown shows as a dark sweep
do
	local home = sideButton(-1, "\u{1F3E0}", "Home", Color3.fromRGB(255, 120, 60), nil)
	local shade = UI.new("Frame", { Name = "Cooldown", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), ZIndex = 5, Parent = home.button })
	UI.corner(shade, 18)
	local busy = false
	local function goHome()
		if busy then return end
		busy = true
		local res = call("teleportHome")
		if res and res.ok then
			sfx("Whoosh")
			local cd = res.cooldown or 0
			if cd > 0 then
				shade.Size = UDim2.fromScale(1, 1)
				TweenService:Create(shade, TweenInfo.new(cd, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 0) }):Play()
			end
		else
			sfx("Error")
			if res and res.err and bus and bus:FindFirstChild("Toast") then bus.Toast:Fire(res.err, "bad") end
		end
		busy = false
	end
	home.button.Activated:Connect(goHome)
	game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == Enum.KeyCode.H and home.button.Visible then goHome() end
	end)
end
-- the server opens a panel (a prompt in the world, like Stan's gear stall)
Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
	if kind ~= "openPanel" or type(data) ~= "table" then return end
	local p = panels[data.name]
	if not p then return end
	p.open()
	if data.tab and p.select then p.select(data.tab) end
end)

-- a button unlocking gets a NEW! badge and a toast
Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
	if kind ~= "unlock" or type(data) ~= "table" then return end
	local b = sideButtons[data.name]
	if not b then return end
	task.defer(function()
		if not b.button:FindFirstChild("New") then newBadge(b.button) end
		sfx("Upgrade")
		if bus and bus:FindFirstChild("Toast") then bus.Toast:Fire(("\u{2728} %s unlocked! (left side)"):format(data.name), "good") end
	end)
end)

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
