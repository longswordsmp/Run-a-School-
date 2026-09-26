-- StarterPlayer.StarterPlayerScripts.Coop
-- The Co-op panel (side button "Co-op", ClientBus.OpenCoop) and the crew job tracker (CrewService).
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
local function lift(obj, z)
	if obj:IsA("GuiObject") then obj.ZIndex = math.max(obj.ZIndex, z) end
	for _, d in obj:GetDescendants() do
		if d:IsA("GuiObject") then d.ZIndex = math.max(d.ZIndex, z + 1) end
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

-- four role cards in a row; pick(id) highlights one
local function roleRow(parent, y, h, onPick)
	local cards = {}
	local row = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, h), ZIndex = 11, Parent = parent })
	for i, r in Config.Roles do
		local b = UI.new("TextButton", {
			Name = r.id, Text = "", AutoButtonColor = false,
			Position = UDim2.new((i - 1) / 4, i == 1 and 0 or 5, 0, 0), Size = UDim2.new(0.25, -8, 1, 0),
			BackgroundColor3 = UI.C.white, ZIndex = 12, Parent = row,
		})
		UI.corner(b, 14)
		local st = UI.stroke(b, 3)
		local band = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = r.color, BorderSizePixel = 0, ZIndex = 13, Parent = b })
		UI.corner(band, 14)
		UI.label(b, { Text = r.icon, Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(8, 14), ZIndex = 13, stroke = 0 })
		UI.label(b, { Text = r.name:upper(), Font = UI.BIG, TextColor3 = r.color:Lerp(UI.C.ink, 0.35), TextXAlignment = LEFT, Size = UDim2.new(1, -52, 0, 24), Position = UDim2.fromOffset(46, 18), ZIndex = 13, stroke = 1 })
		local perk = UI.label(b, { Text = r.perk, TextColor3 = Color3.fromRGB(70, 70, 100), TextScaled = false, TextSize = 15, TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, -16, 1, -54), Position = UDim2.fromOffset(8, 50), ZIndex = 13, stroke = 0 })
		perk.Visible = h >= 100
		cards[r.id] = { button = b, stroke = st, color = r.color }
		b.Activated:Connect(function()
			sfx("Ding")
			onPick(r.id)
		end)
	end
	local api = {}
	function api.set(id)
		for rid, c in cards do
			local on = rid == id
			c.stroke.Color = on and c.color or UI.C.ink
			c.stroke.Thickness = on and 5 or 3
			c.button.BackgroundColor3 = on and c.color:Lerp(UI.C.white, 0.8) or UI.C.white
		end
	end
	return api
end

---------------------------------------------------------------------------
-- solo: start or join
---------------------------------------------------------------------------
local solo = UI.new("Frame", { Name = "Solo", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 11, Parent = body })
UI.label(solo, { Text = "Run ONE school with up to 3 friends in this server. Share the cash, the kids and the fun!", TextColor3 = UI.C.navy, TextScaled = false, TextSize = 20, TextWrapped = true, Size = UDim2.new(1, 0, 0, 46), ZIndex = 12, stroke = 0 })
UI.label(solo, { Text = "YOUR ROLE", Font = UI.BIG, TextColor3 = PURPLE, TextXAlignment = LEFT, Size = UDim2.fromOffset(300, 26), Position = UDim2.fromOffset(0, 52), ZIndex = 12, stroke = 0 })
UI.label(solo, { Text = "(perks work with 2+ players; pick the same as a friend if you like)", TextColor3 = UI.C.grey, TextXAlignment = Enum.TextXAlignment.Right, TextScaled = false, TextSize = 15, Size = UDim2.new(1, -150, 0, 26), Position = UDim2.new(0, 150, 0, 52), ZIndex = 12, stroke = 0 })
local pickedRole = "President"
local soloRoles
soloRoles = roleRow(solo, 82, 116, function(id)
	pickedRole = id
	soloRoles.set(id)
end)
soloRoles.set(pickedRole)

local openBtn = UI.button(solo, { name = "Open", text = "\u{1F3EB} OPEN MY SCHOOL", color = UI.C.green, size = UDim2.new(0.5, -6, 0, 58), position = UDim2.fromOffset(0, 210), font = UI.BIG })
lift(openBtn.button, 12)
local inviteBtn = UI.button(solo, { name = "Invite", text = "\u{2709}\u{FE0F} INVITE FRIENDS", color = UI.C.blue, size = UDim2.new(0.5, -6, 0, 58), position = UDim2.new(0.5, 6, 0, 210), font = UI.BIG })
lift(inviteBtn.button, 12)
inviteBtn.button.Activated:Connect(invite)

UI.label(solo, { Text = "SCHOOLS IN THIS SERVER TAKING PLAYERS", Font = UI.BIG, TextColor3 = PURPLE, TextXAlignment = LEFT, Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 282), ZIndex = 12, stroke = 0 })
local listBox = UI.new("Frame", { Name = "ListBox", BackgroundColor3 = Color3.fromRGB(240, 234, 252), Position = UDim2.fromOffset(0, 312), Size = UDim2.new(1, 0, 1, -312), ZIndex = 11, Parent = solo })
UI.corner(listBox, 14)
UI.stroke(listBox, 3)
local list = UI.new("ScrollingFrame", { Name = "List", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -16), ScrollBarThickness = 8, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 12, Parent = listBox })
UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
local empty = UI.label(listBox, { Text = "No co-op schools here yet. Open yours and invite your friends!", TextColor3 = UI.C.grey, TextScaled = false, TextSize = 19, TextWrapped = true, Size = UDim2.new(1, -40, 0, 60), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 12, stroke = 0 })

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
	local r = UI.new("Frame", { Name = "School" .. order, BackgroundColor3 = UI.C.white, Size = UDim2.new(1, -8, 0, 58), LayoutOrder = order, ZIndex = 13, Parent = list })
	UI.corner(r, 12)
	UI.stroke(r, 2.5)
	UI.label(r, { Text = e.school, Font = UI.BIG, TextColor3 = UI.C.ink, TextXAlignment = LEFT, Size = UDim2.new(1, -150, 0, 26), Position = UDim2.fromOffset(12, 5), ZIndex = 14, stroke = 0 })
	local icons = ""
	for _, rid in e.roles or {} do
		local rr = Config.RoleById[rid]
		if rr then icons ..= rr.icon end
	end
	UI.label(r, { Text = ("%s  \u{2022}  %d/%d  %s"):format(e.hostName, e.size, e.max, icons), TextColor3 = UI.C.grey, TextXAlignment = LEFT, TextScaled = false, TextSize = 16, Size = UDim2.new(1, -150, 0, 20), Position = UDim2.fromOffset(12, 32), ZIndex = 14, stroke = 0 })
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
local jobIcon = UI.label(jobCard, { Text = "", Size = UDim2.fromOffset(56, 56), Position = UDim2.fromOffset(12, 18), ZIndex = 12, stroke = 0 })
local jobTitle = UI.label(jobCard, { Text = "", Font = UI.BIG, TextColor3 = UI.C.ink, TextXAlignment = LEFT, Size = UDim2.new(1, -190, 0, 26), Position = UDim2.fromOffset(78, 8), ZIndex = 12, stroke = 0 })
local jobText = UI.label(jobCard, { Text = "", TextColor3 = UI.C.navy, TextXAlignment = LEFT, TextScaled = false, TextSize = 17, TextWrapped = true, Size = UDim2.new(1, -190, 0, 22), Position = UDim2.fromOffset(78, 34), ZIndex = 12, stroke = 0 })
local jobBarBack = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(220, 210, 190), Position = UDim2.fromOffset(78, 62), Size = UDim2.new(1, -190, 0, 16), ZIndex = 12, Parent = jobCard })
UI.corner(jobBarBack, 8)
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
	local band = UI.new("Frame", { Size = UDim2.new(0, 8, 1, 0), BackgroundColor3 = r.color, BorderSizePixel = 0, ZIndex = 13, Parent = row })
	UI.corner(band, 12)
	UI.label(row, { Text = r.icon, Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(16, 7), ZIndex = 13, stroke = 0 })
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

-- the side button (Menus) and anything else opens it through the bus
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
