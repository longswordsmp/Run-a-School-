-- StarterPlayer.StarterPlayerScripts.Menus
-- Left button bar, panels (Upgrades, Yearbook, Name School) and big centre announcements.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")
local templates = ReplicatedStorage:WaitForChild("StudentTemplates")

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
-- panels
---------------------------------------------------------------------------
local panels = {}

-- Upgrades
do
	local panel = UI.panel(gui, { name = "Upgrades", title = "UPGRADES", color = UI.C.orange, size = UDim2.fromOffset(560, 360) })
	panels.Upgrades = panel
	local list = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 11, Parent = panel.body })
	UI.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	local function row(order, icon, title)
		local r = UI.new("Frame", {
			Name = title,
			BackgroundColor3 = Color3.fromRGB(255, 232, 196),
			Size = UDim2.new(1, 0, 0, 84),
			LayoutOrder = order,
			ZIndex = 12,
			Parent = list,
		})
		UI.corner(r, 14)
		UI.stroke(r, 3)
		UI.label(r, { Name = "Icon", Text = icon, Size = UDim2.fromOffset(64, 64), Position = UDim2.new(0, 10, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), ZIndex = 13, stroke = 0 })
		UI.label(r, { Name = "Title", Text = title, Font = UI.BIG, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -270, 0, 32), Position = UDim2.new(0, 84, 0, 10), ZIndex = 13 })
		local desc = UI.label(r, { Name = "Desc", Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.C.navy, Size = UDim2.new(1, -270, 0, 24), Position = UDim2.new(0, 84, 0, 48), ZIndex = 13, stroke = 0 })
		local buy = UI.button(r, { text = "", color = UI.C.green, size = UDim2.fromOffset(160, 56), position = UDim2.new(1, -12, 0.5, 0), anchor = Vector2.new(1, 0.5) })
		for _, d in buy.button:GetDescendants() do
			if d:IsA("GuiObject") then d.ZIndex = 14 end
		end
		buy.button.ZIndex = 13
		return desc, buy
	end

	local deskDesc, deskBuy = row(1, "\u{1FA91}", "More Desks")
	local profile
	local function refresh()
		profile = call("profile")
		if not profile or profile.ok == false then return end
		if profile.nextDesk then
			deskDesc.Text = ("%d desks now -> %d desks"):format(profile.desks, profile.nextDesk.desks)
			deskBuy.setText(Config.formatCash(profile.nextDesk.price))
			deskBuy.setEnabled((player:GetAttribute("Cash") or 0) >= profile.nextDesk.price)
		else
			deskDesc.Text = ("All %d desks unlocked"):format(profile.desks)
			deskBuy.setText("MAX")
			deskBuy.setEnabled(false)
		end
	end
	deskBuy.button.Activated:Connect(function()
		if not deskBuy.button.Active then return end
		local res = call("buyDesks")
		if res and res.ok then
			announce("NEW DESKS!", UI.C.green)
		end
		refresh()
	end)
	player:GetAttributeChangedSignal("Cash"):Connect(function()
		if panel.frame.Visible and profile and profile.nextDesk then
			deskBuy.setEnabled((player:GetAttribute("Cash") or 0) >= profile.nextDesk.price)
		end
	end)
	panel.onOpen = refresh
end

-- Yearbook
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

-- Name School
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
	save.button.ZIndex = 12
	for _, d in save.button:GetDescendants() do
		if d:IsA("GuiObject") then d.ZIndex = 13 end
	end
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
-- left button bar
---------------------------------------------------------------------------
local bar = UI.new("Frame", {
	Name = "SideBar",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.5, 0),
	Size = UDim2.fromOffset(92, 420),
	Parent = gui,
})
UI.new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center, Parent = bar })

local function sideButton(order, icon, caption, color, panel)
	local b = UI.button(bar, { name = caption, text = "", color = color, size = UDim2.fromOffset(88, 88), radius = 18, layoutOrder = order })
	UI.label(b.button, {
		Name = "Icon",
		Text = icon,
		Size = UDim2.new(1, -16, 0.58, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		AnchorPoint = Vector2.new(0.5, 0),
		ZIndex = 4,
		stroke = 0,
	})
	UI.label(b.button, {
		Name = "Caption",
		Text = caption,
		Size = UDim2.new(1, -8, 0.28, 0),
		Position = UDim2.new(0.5, 0, 1, -6),
		AnchorPoint = Vector2.new(0.5, 1),
		ZIndex = 4,
		stroke = 2,
	})
	b.button.Activated:Connect(panel.toggle)
	return b
end

sideButton(1, "\u{2B06}\u{FE0F}", "Upgrades", UI.C.orange, panels.Upgrades)
sideButton(2, "\u{1F4D6}", "Yearbook", UI.C.purple, panels.Yearbook)
sideButton(3, "\u{270F}\u{FE0F}", "Name", UI.C.blue, panels.NameSchool)
