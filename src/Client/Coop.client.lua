-- StarterPlayer.StarterPlayerScripts.Coop
-- The Co-op panel (the noticeboard in your front yard, ClientBus.OpenCoop) and the crew job tracker
-- (CrewService). Laid out like the Store (tomas, 2026-09-27: "doesn't look good"): a banner, tall role
-- cards in their colours with 3D icons, school rows with the host's face and seat pips.
--   solo      pick a role, OPEN MY SCHOOL FOR CO-OP or JOIN a school in this server; INVITE FRIENDS
--   in a crew who's running the school and as what, change your role, the current crew job, invite
--             friends, and LEAVE (a member goes back to their own school) or END CO-OP (the host)
--   tracker   while a crew job runs: its progress and time left, on the right of the screen
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SocialService = game:GetService("SocialService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")
local bus = ReplicatedStorage:WaitForChild("ClientBus", 10)
local Icons = require(Shared:WaitForChild("Icons"))

local player = Players.LocalPlayer
local gui = UI.new("ScreenGui", {
	Name = "Coop",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
	DisplayOrder = 6,
	Parent = player:WaitForChild("PlayerGui"),
})
UI.autoScale(gui)

local PURPLE = Color3.fromRGB(140, 80, 240)
local LEFT = Enum.TextXAlignment.Left

local function call(action, ...)
	local ok, res = pcall(Action.InvokeServer, Action, action, ...)
	if not ok or type(res) ~= "table" then return { ok = false, err = "Connection hiccup" } end
	return res
end
local function toast(text, kind)
	if bus and bus:FindFirstChild("Toast") then bus.Toast:Fire(text, kind) end
end
local function sfx(name)
	if bus and bus:FindFirstChild("Sfx") then bus.Sfx:Fire(name) end
end
-- (shifts it and everything in it up together, keeping their order: flattening them all to one layer
-- put a button's lip over the button)
local function lift(obj, z)
	local shift = obj:IsA("GuiObject") and math.max(0, z - obj.ZIndex) or 0
	if shift == 0 then return end
	obj.ZIndex += shift
	for _, d in obj:GetDescendants() do
		if d:IsA("GuiObject") then d.ZIndex += shift end
	end
end
local function clock(s)
	s = math.max(0, math.floor(s))
	return ("%d:%02d"):format(s // 60, s % 60)
end

local function invite()
	local ok, can = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
	if ok and can then
		pcall(SocialService.PromptGameInvite, SocialService, player)
	else
		toast("Invites aren't available here. Tell your friends to join this server!", "info")
	end
end

---------------------------------------------------------------------------
-- the panel
---------------------------------------------------------------------------
local panel = UI.panel(gui, { name = "Coop", title = "\u{1F465} CO-OP SCHOOL", color = PURPLE, size = UDim2.fromOffset(780, 620) })
local body = panel.body

-- four role cards in a row, each in its role's colour with its 3D icon; pick(id) lifts one (a white
-- border and a tick). Tall (h >= 100): the icon, the name and the perk on a cream strip; short: the
-- icon and the name side by side.
local ROLE_ICON = { President = "crown", Teacher = "apple", Monitor = "shield", Recruiter = "backpack" }
local function roleRow(parent, y, h, onPick)
	local cards = {}
	local row = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, h), ZIndex = 11, Parent = parent })
	local tall = h >= 100
	for i, r in Config.Roles do
		local b = UI.new("TextButton", {
			Name = r.id, Text = "", AutoButtonColor = false,
			Position = UDim2.new((i - 1) / 4, i == 1 and 0 or 6, 0, 0), Size = UDim2.new(0.25, -9, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 12, Parent = row,
		})
		UI.corner(b, 16)
		local st = UI.stroke(b, 3)
		UI.gradient(b, UI.lighten(r.color, 0.35), r.color)
		UI.studs(b, { zindex = b.ZIndex, transparency = UI.STUD.card })
		local sc = Instance.new("UIScale")
		sc.Parent = b
		if tall then
			Icons.view(b, ROLE_ICON[r.id] or "gift", { size = UDim2.new(1, -20, 0, 72), position = UDim2.new(0.5, 0, 0, 4), anchor = Vector2.new(0.5, 0), zindex = 13, sway = 10 })
			UI.label(b, { Text = r.name:upper(), Font = UI.BIG, Size = UDim2.new(1, -12, 0, 26), Position = UDim2.new(0.5, 0, 0, 76), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 15, stroke = 2.5 })
			local strip = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 250, 238), Size = UDim2.new(1, -12, 0, h - 110), Position = UDim2.new(0.5, 0, 1, -6), AnchorPoint = Vector2.new(0.5, 1), ZIndex = 13, Parent = b })
			UI.corner(strip, 10)
			UI.label(strip, { Text = r.perk, TextColor3 = UI.C.navy, TextScaled = false, TextSize = 14, TextWrapped = true, Size = UDim2.new(1, -10, 1, -6), Position = UDim2.fromOffset(5, 3), ZIndex = 14, stroke = 0 })
		else
			Icons.view(b, ROLE_ICON[r.id] or "gift", { size = UDim2.fromOffset(54, 52), position = UDim2.new(0, 4, 0.5, 0), anchor = Vector2.new(0, 0.5), zindex = 13, sway = 8 })
			UI.label(b, { Text = r.name:upper(), Font = UI.BIG, TextXAlignment = LEFT, Size = UDim2.new(1, -66, 0, 24), Position = UDim2.new(0, 60, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), ZIndex = 15, stroke = 2 })
		end
		local tick = UI.new("Frame", { Name = "Tick", BackgroundColor3 = UI.C.green, Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, 6, 0, -6), AnchorPoint = Vector2.new(1, 0), Visible = false, ZIndex = 17, Parent = b })
		UI.corner(tick, 15)
		UI.stroke(tick, 2.5)
		UI.label(tick, { Text = "\u{2714}", Font = UI.BIG, Size = UDim2.fromScale(1, 1), ZIndex = 18, stroke = 1.5 })
		cards[r.id] = { button = b, stroke = st, tick = tick, scale = sc }
		b.Activated:Connect(function()
			sfx("Ding")
			onPick(r.id)
		end)
	end
	local api = {}
	function api.set(id)
		for rid, c in cards do
			local on = rid == id
			c.stroke.Color = on and Color3.new(1, 1, 1) or UI.C.ink
			c.stroke.Thickness = on and 5 or 3
			c.tick.Visible = on
			TweenService:Create(c.scale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = on and 1.04 or 0.96 }):Play()
		end
	end
	return api
end

-- a player's face (the Roblox headshot), round, into a frame
local function headshot(parent, userId, size, pos, z)
	local img = UI.new("ImageLabel", { Name = "Face", BackgroundColor3 = Color3.fromRGB(235, 225, 255), Image = "", Size = UDim2.fromOffset(size, size), Position = pos, AnchorPoint = Vector2.new(0, 0.5), ZIndex = z, Parent = parent })
	UI.corner(img, size // 2)
	UI.stroke(img, 2.5)
	task.spawn(function()
		local ok, url = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		if ok and img.Parent then img.Image = url end
	end)
	return img
end

---------------------------------------------------------------------------
-- solo: start or join
---------------------------------------------------------------------------
local solo = UI.new("Frame", { Name = "Solo", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 11, Parent = body })
-- the banner: the kids, what co-op is, in a line
local hero = UI.new("Frame", { Name = "Hero", BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(1, 0, 0, 92), ZIndex = 12, Parent = solo })
UI.corner(hero, 16)
UI.stroke(hero, 3)
UI.gradient(hero, Color3.fromRGB(195, 160, 255), PURPLE)
UI.studs(hero, { zindex = hero.ZIndex, transparency = UI.STUD.header })
Icons.view(hero, "people", { size = UDim2.fromOffset(124, 100), position = UDim2.new(0, 4, 0.5, -4), anchor = Vector2.new(0, 0.5), zindex = 13, sway = 12 })
UI.label(hero, { Text = "RUN A SCHOOL WITH FRIENDS", Font = UI.BIG, TextXAlignment = LEFT, Size = UDim2.new(1, -150, 0, 38), Position = UDim2.fromOffset(134, 10), ZIndex = 15, stroke = 3 })
UI.label(hero, { Text = ("Up to %d principals, ONE school: share the cash, the kids and the fun."):format(Config.CrewMax or 4), TextColor3 = Color3.fromRGB(248, 244, 255), TextXAlignment = LEFT, TextScaled = false, TextSize = 19, TextWrapped = true, Size = UDim2.new(1, -150, 0, 40), Position = UDim2.fromOffset(136, 48), ZIndex = 15, stroke = 1.5 })
UI.label(solo, { Text = "PICK YOUR ROLE", Font = UI.BIG, TextColor3 = PURPLE, TextXAlignment = LEFT, Size = UDim2.fromOffset(300, 26), Position = UDim2.fromOffset(2, 100), ZIndex = 12, stroke = 0 })
UI.label(solo, { Text = "perks work with 2+ players", TextColor3 = UI.C.grey, TextXAlignment = Enum.TextXAlignment.Right, TextScaled = false, TextSize = 15, Size = UDim2.new(1, -250, 0, 26), Position = UDim2.new(0, 250, 0, 100), ZIndex = 12, stroke = 0 })
local pickedRole = "President"
local soloRoles
soloRoles = roleRow(solo, 132, 160, function(id)
	pickedRole = id
	soloRoles.set(id)
end)
soloRoles.set(pickedRole)

local openBtn = UI.button(solo, { name = "Open", text = "\u{1F3EB} OPEN MY SCHOOL", color = UI.C.green, size = UDim2.new(0.5, -6, 0, 56), position = UDim2.fromOffset(0, 306), font = UI.BIG })
lift(openBtn.button, 12)
local inviteBtn = UI.button(solo, { name = "Invite", text = "\u{2709}\u{FE0F} INVITE FRIENDS", color = UI.C.blue, size = UDim2.new(0.5, -6, 0, 56), position = UDim2.new(0.5, 6, 0, 306), font = UI.BIG })
lift(inviteBtn.button, 12)
inviteBtn.button.Activated:Connect(invite)

UI.label(solo, { Text = "SCHOOLS YOU CAN JOIN", Font = UI.BIG, TextColor3 = PURPLE, TextXAlignment = LEFT, Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(2, 372), ZIndex = 12, stroke = 0 })
local listBox = UI.new("Frame", { Name = "ListBox", BackgroundColor3 = Color3.fromRGB(240, 234, 252), Position = UDim2.fromOffset(0, 400), Size = UDim2.new(1, 0, 1, -400), ZIndex = 11, Parent = solo })
UI.corner(listBox, 14)
UI.stroke(listBox, 3)
UI.studs(listBox, { zindex = listBox.ZIndex, transparency = UI.STUD.panel })
local list = UI.new("ScrollingFrame", { Name = "List", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -16), ScrollBarThickness = 8, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 12, Parent = listBox })
UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
-- (nobody's open yet: say so, with a picture, and what to do about it)
local empty = UI.new("Frame", { Name = "Empty", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 12, Parent = listBox })
Icons.view(empty, "people", { size = UDim2.fromOffset(110, 90), position = UDim2.new(0, 24, 0.5, 0), anchor = Vector2.new(0, 0.5), zindex = 13, sway = 14 })
UI.label(empty, { Text = "No co-op schools in this server yet", Font = UI.BIG, TextColor3 = PURPLE, TextXAlignment = LEFT, Size = UDim2.new(1, -170, 0, 30), Position = UDim2.new(0, 150, 0.5, -20), AnchorPoint = Vector2.new(0, 0.5), ZIndex = 14, stroke = 0 })
UI.label(empty, { Text = "Open yours and invite your friends: they'll show up here for everyone to join.", TextColor3 = UI.C.grey, TextXAlignment = LEFT, TextScaled = false, TextSize = 17, TextWrapped = true, Size = UDim2.new(1, -170, 0, 44), Position = UDim2.new(0, 150, 0.5, 18), AnchorPoint = Vector2.new(0, 0.5), ZIndex = 14, stroke = 0 })

local working = false
openBtn.button.Activated:Connect(function()
	if working then return end
	working = true
	local res = call("crewCreate", pickedRole)
	working = false
	if res.ok then
		sfx("Upgrade")
		toast("\u{1F465} Your school is open for co-op! Invite friends to this server.", "good")
	else
		sfx("Error")
		toast(res.err or "Couldn't open it", "bad")
	end
end)

local function schoolRow(e, order)
	local r = UI.new("Frame", { Name = "School" .. order, BackgroundColor3 = UI.C.white, Size = UDim2.new(1, -8, 0, 62), LayoutOrder = order, ZIndex = 13, Parent = list })
	UI.corner(r, 12)
	UI.stroke(r, 2.5)
	UI.studs(r, { zindex = r.ZIndex, transparency = UI.STUD.row })
	headshot(r, e.host, 48, UDim2.new(0, 8, 0.5, 0), 14)
	UI.label(r, { Text = e.school, Font = UI.BIG, TextColor3 = UI.C.ink, TextXAlignment = LEFT, Size = UDim2.new(1, -210, 0, 26), Position = UDim2.fromOffset(66, 6), ZIndex = 14, stroke = 0 })
	-- (a pip a seat: filled for each principal in it)
	local pips = ""
	for k = 1, e.max do pips ..= k <= e.size and "\u{25CF}" or "\u{25CB}" end
	local icons = ""
	for _, rid in e.roles or {} do
		local rr = Config.RoleById[rid]
		if rr then icons ..= rr.icon end
	end
	UI.label(r, { Text = ("%s's school  %s  %s"):format(e.hostName, pips, icons), TextColor3 = UI.C.grey, TextXAlignment = LEFT, TextScaled = false, TextSize = 16, Size = UDim2.new(1, -210, 0, 20), Position = UDim2.fromOffset(66, 34), ZIndex = 14, stroke = 0 })
	local full = e.size >= e.max
	local j = UI.button(r, { name = "Join", text = full and "FULL" or "JOIN", color = full and UI.C.grey or UI.C.green, size = UDim2.fromOffset(120, 44), position = UDim2.new(1, -8, 0.5, 0), anchor = Vector2.new(1, 0.5), font = UI.BIG })
	lift(j.button, 14)
	j.button.Activated:Connect(function()
		if full or working then return end
		working = true
		local res = call("crewJoin", e.host, pickedRole)
		working = false
		if res.ok then
			sfx("Cheer")
			panel.close()
		else
			sfx("Error")
			toast(res.err or "Couldn't join", "bad")
		end
	end)
end

local shownKey
local function refreshList()
	local res = call("crewList")
	local entries = res.ok and res.list or {}
	-- (rebuilt only when something changed: a rebuild under the cursor would eat a click)
	local key = {}
	for _, e in entries do table.insert(key, ("%s|%s|%d|%s"):format(e.host, e.school, e.size, table.concat(e.roles or {}, ","))) end
	key = table.concat(key, ";")
	if key == shownKey then return end
	shownKey = key
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then c:Destroy() end
	end
	empty.Visible = #entries == 0
	for i, e in entries do schoolRow(e, i) end
end

---------------------------------------------------------------------------
-- in a crew
---------------------------------------------------------------------------
local crew = UI.new("Frame", { Name = "Crew", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 11, Parent = body })
local schoolTitle = UI.label(crew, { Text = "", Font = UI.BIG, TextColor3 = UI.C.ink, TextXAlignment = LEFT, Size = UDim2.new(1, -200, 0, 32), ZIndex = 12, stroke = 0 })
local schoolSub = UI.label(crew, { Text = "", TextColor3 = UI.C.grey, TextXAlignment = LEFT, TextScaled = false, TextSize = 17, Size = UDim2.new(1, -200, 0, 20), Position = UDim2.fromOffset(0, 32), ZIndex = 12, stroke = 0 })
local openToggle = UI.button(crew, { text = "", color = UI.C.green, size = UDim2.fromOffset(190, 46), position = UDim2.new(1, 0, 0, 2), anchor = Vector2.new(1, 0), font = UI.BIG })
lift(openToggle.button, 12)

local members = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 60), Size = UDim2.new(1, 0, 0, 196), ZIndex = 11, Parent = crew })
UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = members })

UI.label(crew, { Text = "YOUR ROLE", Font = UI.BIG, TextColor3 = PURPLE, TextXAlignment = LEFT, Size = UDim2.fromOffset(300, 24), Position = UDim2.fromOffset(0, 262), ZIndex = 12, stroke = 0 })
local crewRoles
crewRoles = roleRow(crew, 290, 60, function(id)
	local res = call("crewRole", id)
	if not res.ok then toast(res.err or "Couldn't change role", "bad") end
end)

local jobCard = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 244, 214), Position = UDim2.fromOffset(0, 362), Size = UDim2.new(1, 0, 0, 92), ZIndex = 11, Parent = crew })
UI.corner(jobCard, 14)
UI.stroke(jobCard, 3)
UI.studs(jobCard, { zindex = jobCard.ZIndex, transparency = UI.STUD.card })
local jobIcon = UI.label(jobCard, { Text = "", Size = UDim2.fromOffset(56, 56), Position = UDim2.fromOffset(12, 18), ZIndex = 12, stroke = 0 })
local jobTitle = UI.label(jobCard, { Text = "", Font = UI.BIG, TextColor3 = UI.C.ink, TextXAlignment = LEFT, Size = UDim2.new(1, -190, 0, 26), Position = UDim2.fromOffset(78, 8), ZIndex = 12, stroke = 0 })
local jobText = UI.label(jobCard, { Text = "", TextColor3 = UI.C.navy, TextXAlignment = LEFT, TextScaled = false, TextSize = 17, TextWrapped = true, Size = UDim2.new(1, -190, 0, 22), Position = UDim2.fromOffset(78, 34), ZIndex = 12, stroke = 0 })
local jobBarBack = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(220, 210, 190), Position = UDim2.fromOffset(78, 62), Size = UDim2.new(1, -190, 0, 16), ZIndex = 12, Parent = jobCard })
UI.corner(jobBarBack, 8)
UI.studs(jobBarBack, { zindex = jobBarBack.ZIndex, transparency = UI.STUD.bar })
local jobBar = UI.new("Frame", { BackgroundColor3 = UI.C.green, Size = UDim2.fromScale(0, 1), ZIndex = 13, Parent = jobBarBack })
UI.corner(jobBar, 8)
local jobTime = UI.label(jobCard, { Text = "", Font = UI.BIG, TextColor3 = UI.C.orange, Size = UDim2.fromOffset(100, 34), Position = UDim2.new(1, -110, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), ZIndex = 12, stroke = 1 })

local inviteBtn2 = UI.button(crew, { text = "\u{2709}\u{FE0F} INVITE FRIENDS", color = UI.C.blue, size = UDim2.new(0.5, -6, 0, 58), position = UDim2.new(0, 0, 1, 0), anchor = Vector2.new(0, 1), font = UI.BIG })
lift(inviteBtn2.button, 12)
inviteBtn2.button.Activated:Connect(invite)
local leaveBtn = UI.button(crew, { name = "Leave", text = "", color = UI.C.red, size = UDim2.new(0.5, -6, 0, 58), position = UDim2.new(1, 0, 1, 0), anchor = Vector2.new(1, 1), font = UI.BIG })
lift(leaveBtn.button, 12)

---------------------------------------------------------------------------
-- state
---------------------------------------------------------------------------
local state = { inCrew = false }
local jobEndsAt, boostEndsAt = 0, 0

local function memberRow(m, order, amHost)
	local r = Config.RoleById[m.role] or Config.Roles[1]
	local row = UI.new("Frame", { BackgroundColor3 = m.id == player.UserId and Color3.fromRGB(236, 255, 240) or UI.C.white, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = order, ZIndex = 12, Parent = members })
	UI.corner(row, 12)
	UI.stroke(row, 2.5)
	UI.studs(row, { zindex = row.ZIndex, transparency = UI.STUD.row })
	local band = UI.new("Frame", { Size = UDim2.new(0, 8, 1, 0), BackgroundColor3 = r.color, BorderSizePixel = 0, ZIndex = 13, Parent = row })
	UI.corner(band, 12)
	headshot(row, m.id, 34, UDim2.new(0, 14, 0.5, 0), 13)
	UI.label(row, { Text = m.name .. (m.id == player.UserId and "  (you)" or ""), Font = UI.BIG, TextColor3 = UI.C.ink, TextXAlignment = LEFT, Size = UDim2.new(0.5, -60, 0, 26), Position = UDim2.fromOffset(54, 9), ZIndex = 13, stroke = 0 })
	UI.label(row, { Text = r.name .. (m.host and "  \u{2022}  OWNER" or ""), TextColor3 = r.color:Lerp(UI.C.ink, 0.3), TextXAlignment = LEFT, TextScaled = false, TextSize = 18, Size = UDim2.new(0.5, -120, 0, 26), Position = UDim2.new(0.5, 0, 0, 9), ZIndex = 13, stroke = 0 })
	if amHost and not m.host then
		local kick = UI.button(row, { text = "SEND HOME", color = UI.C.orange, size = UDim2.fromOffset(120, 34), position = UDim2.new(1, -6, 0.5, 0), anchor = Vector2.new(1, 0.5) })
		lift(kick.button, 13)
		kick.button.Activated:Connect(function()
			local res = call("crewKick", m.id)
			if not res.ok then toast(res.err or "Couldn't", "bad") end
		end)
	end
end

local function render()
	solo.Visible = not state.inCrew
	crew.Visible = state.inCrew == true
	if not state.inCrew then return end
	local amHost = state.host == player.UserId
	schoolTitle.Text = state.school or "Co-op school"
	schoolSub.Text = ("%d/%d principals running it together"):format(#(state.members or {}), state.max or Config.CrewMax)
	openToggle.button.Visible = amHost
	openToggle.setText(state.open and "\u{1F513} OPEN TO JOIN" or "\u{1F512} CLOSED")
	openToggle.setColor(state.open and UI.C.green or UI.C.grey)
	for _, c in members:GetChildren() do
		if c:IsA("Frame") then c:Destroy() end
	end
	local mine
	for i, m in state.members or {} do
		memberRow(m, i, amHost)
		if m.id == player.UserId then mine = m.role end
	end
	crewRoles.set(mine)
	leaveBtn.setText(amHost and "END CO-OP" or "\u{1F3EB} BACK TO MY SCHOOL")
	-- the job
	local j = state.job
	if j then
		jobIcon.Text = j.icon
		jobTitle.Text = "CREW JOB: " .. j.title
		jobText.Text = j.text
		local frac = (j.target or 1) > 0 and math.clamp((j.progress or 0) / j.target, 0, 1) or 0
		TweenService:Create(jobBar, TweenInfo.new(0.3), { Size = UDim2.fromScale(frac, 1) }):Play()
		jobBarBack.Visible = true
	elseif #(state.members or {}) < 2 then
		jobIcon.Text = "\u{1F465}"
		jobTitle.Text = "CREW JOBS"
		jobText.Text = "Get a friend in! Crew jobs start with 2 or more players."
		jobBarBack.Visible = false
	else
		jobIcon.Text = "\u{23F3}"
		jobTitle.Text = "NEXT CREW JOB"
		jobText.Text = state.boostIn and state.boostIn > 0 and "Crew bonus running: +30% tuition!" or "A new job is on its way..."
		jobBarBack.Visible = false
	end
end

openToggle.button.Activated:Connect(function()
	local res = call("crewOpen", not state.open)
	if res.ok and res.state then
		state = res.state
		render()
	end
end)
leaveBtn.button.Activated:Connect(function()
	local res = call("crewLeave")
	if res.ok then
		sfx("Whoosh")
		panel.close()
	else
		sfx("Error")
		toast(res.err or "Not right now", "bad")
	end
end)

---------------------------------------------------------------------------
-- the tracker (right side, while a job or a crew bonus runs)
---------------------------------------------------------------------------
local tracker = UI.new("Frame", {
	Name = "CrewJob", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0.3, 0), Size = UDim2.fromOffset(280, 86),
	BackgroundColor3 = UI.C.white, Visible = false, ZIndex = 3, Parent = gui,
})
UI.corner(tracker, 14)
UI.stroke(tracker, 3)
UI.gradient(tracker, Color3.fromRGB(250, 244, 255), Color3.fromRGB(226, 212, 255))
UI.studs(tracker, { zindex = tracker.ZIndex, transparency = UI.STUD.hud })
local tTitle = UI.label(tracker, { Text = "", Font = UI.BIG, TextColor3 = PURPLE, TextXAlignment = LEFT, Size = UDim2.new(1, -80, 0, 22), Position = UDim2.fromOffset(10, 6), ZIndex = 4, stroke = 0 })
local tTime = UI.label(tracker, { Text = "", Font = UI.BIG, TextColor3 = UI.C.orange, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(70, 22), Position = UDim2.new(1, -80, 0, 6), ZIndex = 4, stroke = 0 })
local tText = UI.label(tracker, { Text = "", TextColor3 = UI.C.navy, TextXAlignment = LEFT, TextScaled = false, TextSize = 15, TextWrapped = true, Size = UDim2.new(1, -20, 0, 32), Position = UDim2.fromOffset(10, 28), ZIndex = 4, stroke = 0 })
local tBarBack = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(210, 200, 230), Position = UDim2.new(0, 10, 1, -18), Size = UDim2.new(1, -20, 0, 10), ZIndex = 4, Parent = tracker })
UI.corner(tBarBack, 5)
local tBar = UI.new("Frame", { BackgroundColor3 = UI.C.green, Size = UDim2.fromScale(0, 1), ZIndex = 5, Parent = tBarBack })
UI.corner(tBar, 5)

local function renderTracker()
	local j = state.inCrew and state.job
	if j then
		tracker.Visible = true
		tTitle.Text = j.icon .. " " .. j.title
		local prog = j.money and (Config.formatCash(j.progress or 0) .. " / " .. Config.formatCash(j.target or 0)) or ((j.progress or 0) .. " / " .. (j.target or 0))
		tText.Text = j.text .. "  (" .. prog .. ")"
		tBarBack.Visible = true
		TweenService:Create(tBar, TweenInfo.new(0.3), { Size = UDim2.fromScale(math.clamp((j.progress or 0) / math.max(1, j.target or 1), 0, 1), 1) }):Play()
	elseif state.inCrew and os.clock() < boostEndsAt then
		tracker.Visible = true
		tTitle.Text = "\u{1F525} CREW BONUS"
		tText.Text = "+30% tuition for your whole school!"
		tBarBack.Visible = false
	else
		tracker.Visible = false
	end
end

local function apply(s)
	if type(s) ~= "table" then return end
	local wasJob = state.job and state.job.id
	state = s
	jobEndsAt = s.job and (os.clock() + (s.job.endsIn or 0)) or 0
	boostEndsAt = os.clock() + (s.boostIn or 0)
	if s.job and s.job.id ~= wasJob then UI.pop(tracker, 0.7) end
	render()
	renderTracker()
end

Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
	if kind == "crew" then apply(data) end
end)

-- clocks, and the list while the panel is open on the solo page
task.spawn(function()
	local n = 0
	while true do
		task.wait(1)
		n += 1
		if state.job then
			local left = jobEndsAt - os.clock()
			tTime.Text = clock(left)
			jobTime.Text = clock(left)
		else
			tTime.Text = os.clock() < boostEndsAt and clock(boostEndsAt - os.clock()) or ""
			jobTime.Text = ""
		end
		if not state.job and tracker.Visible and os.clock() >= boostEndsAt then renderTracker() end
		if panel.frame.Visible and not state.inCrew and n % 3 == 0 then task.spawn(refreshList) end
	end
end)

panel.onOpen = function()
	local res = call("crewState")
	if res.ok then apply(res.state) end
	shownKey = nil
	if not state.inCrew then task.spawn(refreshList) end
end

-- the noticeboard in the front yard (PlacesService, through Menus) and anything else opens it through the bus
if bus then
	local e = bus:FindFirstChild("OpenCoop") or Instance.new("BindableEvent")
	e.Name = "OpenCoop"
	e.Parent = bus
	e.Event:Connect(function() panel.toggle() end)
end

-- a crew already running when this script starts (joined from the loading screen)
task.defer(function()
	local res = call("crewState")
	if res.ok then apply(res.state) end
end)
