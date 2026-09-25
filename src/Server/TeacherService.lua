-- ServerScriptService.Server.TeacherService
-- The teachers standing at each floor's chalkboard: builds them from the owner's hires, and keeps
-- them alive: pacing along the board, turning to point at it, and changing the lesson written on it.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local Factory = require(script.Parent.StudentFactory)
local Walkers = require(script.Parent.Walkers)

local TeacherService = {}
local active = {} -- [plot] = { [floor] = { model, running } }

-- what each teacher writes on the board
local LESSONS = {
	SubSteve = { "Uh... page 42?", "Quiet reading time", "Is this Room 12?", "Nap time? No?" },
	StudentTia = { "Today: FRACTIONS!", "Gold stars for all!", "Pop quiz? Kidding!" },
	MrChalk = { "2 + 2 = 4", "a\u{00B2} + b\u{00B2} = c\u{00B2}", "Show your work!", "7 x 8 = 56" },
	MsHoneycutt = { "Nouns & Verbs", "Spelling test Friday", "Read chapter 3", "Their / There / They're" },
	CoachRex = { "20 LAPS!", "Dodgeball rules", "Hustle hustle!", "Hydrate!" },
	DrBeaker = { "H\u{2082}O = water", "Goggles ON", "Volcano day!!", "Don't lick the lab" },
	MadameVerse = { "Roses are red...", "Haiku hour", "Rhyme time!", "Feel the words" },
	ProfTweed = { "The History of Everything", "In 1492...", "Footnotes matter", "Cite your sources" },
	DeanMaximus = { "Welcome, scholars", "Honor code", "Dean's List!", "Excellence!" },
	ArchmageQuill = { "Spells 101", "Potions: NO tasting", "Wand safety", "Levitation lab" },
	CommanderNova = { "Zero-G math", "Orbits & you", "T-minus 10...", "Moon rocks" },
	Omniteacher = { "Everything. All of it.", "E = mc\u{00B2} (easy)", "You're all geniuses", "\u{221E} + 1" },
}

local function boardLabel(plot, floor)
	local fm = PlotService.floorModel(plot, floor)
	local board = fm and fm.Classroom:FindFirstChild("Chalkboard")
	local g = board and board:FindFirstChildOfClass("SurfaceGui")
	return g and g:FindFirstChild("Lesson")
end

-- the nameplate on the front of the teacher's desk
local function nameplate(plot, floor, tdef)
	local fm = PlotService.floorModel(plot, floor)
	local desk = fm and fm.Classroom:FindFirstChild("TeacherDesk")
	if not desk then return end
	local g = desk:FindFirstChild("Nameplate")
	if not tdef then
		if g then g:Destroy() end
		return
	end
	if not g then
		g = Instance.new("SurfaceGui")
		g.Name = "Nameplate"
		g.Face = Enum.NormalId.Back
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 40
		g.LightInfluence = 0.3
		g.Parent = desk
		local list = Instance.new("UIListLayout")
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = g
		for i, spec in { { "Title", 0.26, Color3.fromRGB(255, 220, 110) }, { "TName", 0.34, Color3.new(1, 1, 1) }, { "Boost", 0.26, Color3.fromRGB(120, 255, 120) } } do
			local t = Instance.new("TextLabel")
			t.Name = spec[1]
			t.LayoutOrder = i
			t.BackgroundTransparency = 1
			t.Size = UDim2.fromScale(0.92, spec[2])
			t.Font = Enum.Font.FredokaOne
			t.TextScaled = true
			t.TextColor3 = spec[3]
			local s = Instance.new("UIStroke")
			s.Thickness = 2
			s.Parent = t
			t.Parent = g
		end
	end
	g.Title.Text = tdef.title
	g.TName.Text = tdef.name
	g.Boost.Text = ("+%d%% tuition on this floor"):format(math.floor((tdef.mult - 1) * 100 + 0.5))
end

local function spot(plot, floor)
	local fm = PlotService.floorModel(plot, floor)
	return fm and fm.Classroom:FindFirstChild("TeacherSpot")
end

-- raise the right arm toward the board and bring it back down
local function point(model, seconds)
	local upper = model:FindFirstChild("RightUpperArm")
	local target, prop = Factory.poseTarget(upper and upper:FindFirstChild("RightShoulder"))
	if not target then return end
	local base = target:GetAttribute("BasePose") or target[prop]
	target:SetAttribute("BasePose", base)
	TweenService:Create(target, TweenInfo.new(0.35, Enum.EasingStyle.Back), { [prop] = base * CFrame.Angles(math.rad(100), 0, math.rad(-10)) }):Play()
	task.wait(seconds)
	if target.Parent then
		TweenService:Create(target, TweenInfo.new(0.3), { [prop] = base }):Play()
	end
end

-- one teacher's loop: lecture, pace, point at the board with a new lesson
local function behave(plot, floor, entry, tdef)
	local model = entry.model
	local root = model.PrimaryPart
	local home = root.CFrame
	local lessons = LESSONS[tdef.id] or { "Welcome to class!" }
	local n = math.random(#lessons)
	local stand = Factory.standOffset(model)
	_ = stand
	while entry.running and model.Parent do
		-- lecture facing the class
		Factory.play(model, "idle")
		task.wait(3 + math.random() * 3)
		if not entry.running or not model.Parent then break end
		-- pace to one side of the board and back
		local side = math.random() < 0.5 and -1 or 1
		local target = (home * CFrame.new(side * (4 + math.random() * 6), 0, 0)).Position
		Factory.play(model, "walk")
		local done = false
		Walkers.walk(model, { target, home.Position }, 5, function() done = true end)
		local t0 = os.clock()
		while not done and os.clock() - t0 < 12 and entry.running do task.wait(0.2) end
		if not entry.running or not model.Parent then break end
		root.CFrame = home
		-- turn to the board, write the next lesson, point at it, turn back
		Factory.play(model, "idle")
		root.CFrame = home * CFrame.Angles(0, math.pi * 0.85, 0)
		n = n % #lessons + 1
		local label = boardLabel(plot, floor)
		if label then label.Text = lessons[n] end
		point(model, 1.6)
		if model.Parent then root.CFrame = home end
	end
end

function TeacherService.clear(plot)
	local list = active[plot]
	if not list then return end
	for _, entry in list do
		entry.running = false
		Walkers.stop(entry.model)
		entry.model:Destroy()
	end
	active[plot] = nil
end

-- (re)place the teachers the owner has hired, one per floor they have
function TeacherService.refresh(player)
	local plot = PlotService.getPlot(player)
	local p = Data.get(player)
	if not plot or not p then return end
	TeacherService.clear(plot)
	active[plot] = {}
	local folder = plot:FindFirstChild("Teachers")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Teachers"
		folder.Parent = plot
	end
	for floor = 1, PlotService.floorsOf(p) do
		local hired = p.teachers[floor]
		local tdef = hired and Config.TeacherById[hired.id]
		local s = spot(plot, floor)
		nameplate(plot, floor, tdef)
		if tdef and s then
			local model = Factory.buildTeacher(tdef, floor)
			local y = s.Position.Y + Factory.standOffset(model)
			model.PrimaryPart.CFrame = CFrame.new(s.Position.X, y, s.Position.Z) * s.CFrame.Rotation
			model.Parent = folder
			local entry = { model = model, running = true }
			active[plot][floor] = entry
			task.spawn(behave, plot, floor, entry, tdef)
		else
			local label = boardLabel(plot, floor)
			if label then label.Text = floor == 1 and "Welcome to class!" or ("Floor " .. floor) end
		end
	end
end

-- the School Board: five senior staff behind the table in the Board Room
local BOARD = {
	{ outfit = "kevin", title = "KEVIN, AGE 10", id = "Kevin", name = "Kevin", kid = true },
	{ outfit = "honey", title = "SECRETARY" },
	{ outfit = "dean", title = "CHAIR" },
	{ outfit = "beaker", title = "INSPECTOR" },
	{ outfit = "verse", title = "TREASURER" },
}
local function seatBoard()
	local room = workspace:FindFirstChild("BoardRoom")
	if room then pcall(function() room.ModelStreamingMode = Enum.ModelStreamingMode.Persistent end) end
	if not room or room:FindFirstChild("Members") then return end
	local folder = Instance.new("Folder")
	folder.Name = "Members"
	folder.Parent = room
	local seats, plates = {}, {}
	for _, c in room:GetChildren() do
		if c.Name == "BoardSeat" then table.insert(seats, c) end
		if c.Name == "Nameplate" then table.insert(plates, c) end
	end
	table.sort(seats, function(a, b) return a.Position.X < b.Position.X end)
	table.sort(plates, function(a, b) return a.Position.X < b.Position.X end)
	for i, seat in seats do
		local spec = BOARD[i]
		local tdef = spec.id and { id = spec.id, name = spec.name, title = spec.title, mult = 1, outfit = spec.outfit }
		if not tdef then
			for _, t in Config.Teachers do
				if t.outfit == spec.outfit then tdef = t end
			end
		end
		if tdef then
			local model = Factory.buildTeacher(tdef, 1)
			model.Name = spec.id and ("Board" .. spec.id) or ("Board" .. spec.title)
			local scale = spec.kid and 0.72 or 1
			if scale ~= 1 then model:ScaleTo(scale) end
			model.PrimaryPart.CFrame = CFrame.new(seat.Position + Vector3.new(0, 1.35 * scale + (1 - scale) * 0.4, 0)) * CFrame.Angles(0, math.pi, 0)
			model.Parent = folder
			Factory.play(model, "sit")
		end
		local plate = plates[i]
		if plate and not plate:FindFirstChildOfClass("SurfaceGui") then
			local g = Instance.new("SurfaceGui")
			g.Face = Enum.NormalId.Back
			g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			g.PixelsPerStud = 50
			g.Parent = plate
			local t = Instance.new("TextLabel")
			t.Size = UDim2.fromScale(1, 1)
			t.BackgroundTransparency = 1
			t.Font = Enum.Font.LuckiestGuy
			t.TextScaled = true
			t.TextColor3 = Color3.fromRGB(60, 40, 20)
			t.Text = spec.title
			t.Parent = g
		end
	end
end

function TeacherService.start()
	Factory.preloadTeachers()
	task.spawn(seatBoard)
	-- portraits for the Board-review story beats (the client frames these templates)
	task.spawn(function()
		for _, t in {
			{ id = "Vex", name = "Dr. Veronica Vex", title = "VexCorp CEO", mult = 1, outfit = "vex" },
			{ id = "Baron", name = "The Sugar Baron", title = "???", mult = 1, outfit = "baron" },
		} do
			pcall(function() Factory.buildTeacher(t, 1):Destroy() end)
		end
	end)
	table.insert(PlotService.rebuildHooks, function(player)
		TeacherService.refresh(player)
	end)
	-- an owner leaving takes their staff with them
	for _, plot in workspace:WaitForChild("Plots"):GetChildren() do
		plot:GetAttributeChangedSignal("OwnerId"):Connect(function()
			if plot:GetAttribute("OwnerId") == 0 then TeacherService.clear(plot) end
		end)
	end
end

return TeacherService
