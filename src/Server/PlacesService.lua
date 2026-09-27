-- ServerScriptService.Server.PlacesService
-- The features that used to be side-bar buttons, out in the world (tomas, 2026-09-27: "do these all
-- have to be gui or can you go to a place or npc to see them"). Walk up and press E:
--   School Board  a desk on the path in front of the District Office, before its leaderboards (everyone)
--   Name          the sign over your gate (your school)
--   Yearbook      a bookcase with the yearbook on a lectern, in your front yard (your school)
--   Files         a filing cabinet next to it, the top drawer open (your school)
--   Co-op         a noticeboard next to that (anyone at that school)
-- A prompt opens its panel on the client (Push "openPanel") once the feature has unlocked
-- (UnlockService: p.unlocked); before that it says when it opens. The front-yard pieces stand in a row
-- on the right of the entrance path (plot-local x 24, z 66 / 73 / 80), facing the path.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crew = require(ReplicatedStorage.Shared.Crew)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)

local PlacesService = {}

local rgb = Color3.fromRGB
local V, CF = Vector3.new, CFrame.new
local INK = rgb(24, 22, 32)

-- when each place's feature opens (said at the place while it's still shut)
local LOCKED = {
	Board = "The School Board sees you once your First Morning is done.",
	Yearbook = "Your yearbook starts once you've enrolled 5 kids.",
	Name = "You'll name your school in Chapter 1.",
	Files = "Find your first VexCorp File round town, then read them here.",
	Coop = "",
}

local function part(parent, name, size, cf, color, mat, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- big cartoon words on a part's front (-Z) face
local function words(p, text, color, stroke)
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.LuckiestGuy
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color or Color3.new(1, 1, 1)
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Color = stroke or INK
	s.Parent = t
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0.06, 0), UDim.new(0.06, 0)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0.1, 0), UDim.new(0.1, 0)
	pad.Parent = t
	t.Parent = g
	g.Parent = p
end

local function prompt(p, action, object, ownerOnly)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 12
	pp.RequiresLineOfSight = false
	if ownerOnly then pp:SetAttribute("OwnerOnly", true) end
	pp.Parent = p
	return pp
end

-- open `feature`'s panel for `player`, or say when it opens
local function open(player, feature, panel)
	local p = Data.get(player)
	if not (p and p.unlocked and p.unlocked[feature]) then
		local msg = LOCKED[feature]
		if msg and msg ~= "" then Remotes.Notify:FireClient(player, msg, "info") end
		return
	end
	Remotes.Push:FireClient(player, "openPanel", { name = panel })
end

-- is this plot `player`'s school (theirs, or their co-op host's)?
local function mine(player, plot)
	return Crew.owns(player, plot:GetAttribute("OwnerId"))
end

---------------------------------------------------------------------------
-- the pieces (built in their own frame: standing on y = 0, the front facing -Z)
---------------------------------------------------------------------------
-- a bookcase full of books, the sign YEARBOOK on top, and the yearbook itself open on a lectern in front
local function yearbookShelf(parent, at)
	local m = Instance.new("Model")
	m.Name = "YearbookShelf"
	local WOOD, WOODD = rgb(150, 95, 55), rgb(110, 68, 38)
	local function q(name, size, cf, color, mat, shape) return part(m, name, size, at * cf, color, mat, shape) end
	for _, x in { -2.8, 2.8 } do q("Side", V(0.4, 7, 1.8), CF(x, 3.5, 0), WOOD) end
	q("Top", V(6, 0.4, 1.8), CF(0, 7, 0), WOODD)
	q("Base", V(6, 0.4, 1.8), CF(0, 0.2, 0), WOODD)
	q("Back", V(5.2, 6.6, 0.2), CF(0, 3.5, 0.8), WOODD)
	local COLORS = { rgb(220, 60, 70), rgb(60, 130, 235), rgb(80, 190, 90), rgb(250, 190, 50), rgb(160, 90, 220), rgb(240, 120, 60), rgb(70, 190, 190) }
	local n = 0
	for _, shelfY in { 0.4, 2.6, 4.8 } do
		if shelfY > 0.4 then q("Shelf", V(5.2, 0.25, 1.6), CF(0, shelfY, 0), WOOD) end
		local x = -2.4
		while x < 2.2 do
			n += 1
			local w = 0.3 + (n * 37 % 5) * 0.05
			local h = 1.3 + (n * 53 % 6) * 0.1
			q("Book", V(w, h, 1.2), CF(x + w / 2, shelfY + 0.13 + h / 2, -0.1), COLORS[n % #COLORS + 1])
			x += w + 0.04
		end
	end
	local sign = q("Sign", V(4.6, 1.1, 0.3), CF(0, 7.85, -0.2), rgb(65, 125, 235))
	words(sign, "YEARBOOK")
	-- the lectern, the yearbook open on it (blue cover, gold star), a soft light over it
	q("Post", V(0.45, 3, 0.45), CF(0, 1.5, -1.9), WOODD)
	local top = q("Lectern", V(2.4, 0.25, 1.7), CF(0, 3.1, -1.9) * CFrame.Angles(math.rad(-25), 0, 0), WOOD)
	for _, s in { -1, 1 } do
		q("Page", V(1.05, 0.12, 1.35), CF(0, 3.28, -1.9) * CFrame.Angles(math.rad(-25), 0, 0) * CF(s * 0.55, 0, 0) * CFrame.Angles(0, 0, s * math.rad(-6)), rgb(255, 250, 235))
	end
	q("Cover", V(2.25, 0.1, 1.5), CF(0, 3.2, -1.9) * CFrame.Angles(math.rad(-25), 0, 0), rgb(65, 125, 235))
	q("Star", V(0.45, 0.14, 0.45), CF(0.55, 3.38, -1.9) * CFrame.Angles(math.rad(-25), 0, 0) * CFrame.Angles(0, math.rad(45), 0), rgb(255, 205, 70), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 235, 190)
	light.Range = 8
	light.Brightness = 1.2
	light.Parent = top
	m.Parent = parent
	return m, top
end

-- a grey filing cabinet: three drawers, the top one pulled open with folders standing in it, FILES on top
local function filesCabinet(parent, at)
	local m = Instance.new("Model")
	m.Name = "FilesCabinet"
	local function q(name, size, cf, color, mat) return part(m, name, size, at * cf, color, mat) end
	local STEEL, STEELL = rgb(140, 148, 162), rgb(170, 178, 192)
	q("Body", V(2.6, 4.6, 2.2), CF(0, 2.3, 0), STEEL, Enum.Material.Metal)
	for i, y in { 0.85, 2.3 } do
		q("Drawer", V(2.3, 1.25, 0.1), CF(0, y, -1.12), STEELL, Enum.Material.Metal)
		q("Handle", V(0.9, 0.16, 0.22), CF(0, y + 0.2, -1.22), rgb(60, 62, 72), Enum.Material.Metal)
		q("Label", V(0.7, 0.35, 0.05), CF(0, y - 0.2, -1.18), rgb(245, 240, 225))
		_ = i
	end
	-- the top drawer, out
	q("OpenDrawer", V(2.3, 1.2, 1.5), CF(0, 3.75, -1.6), STEELL, Enum.Material.Metal)
	q("Handle", V(0.9, 0.16, 0.22), CF(0, 3.95, -2.42), rgb(60, 62, 72), Enum.Material.Metal)
	local MANILA = rgb(225, 175, 95)
	for i, z in { -1.1, -1.5, -1.9 } do
		local f = q("Folder", V(2.0, 1.1, 0.07), CF(0, 4.55, z) * CFrame.Angles(math.rad(-6 + i * 4), 0, 0), MANILA)
		if i == 2 then q("Stamp", V(1.2, 0.3, 0.08), f.CFrame * CF(0.2, 0.2, 0), rgb(150, 60, 220)) end
	end
	local sign = q("Sign", V(2.8, 0.9, 0.25), CF(0, 5.4, 0.4), rgb(150, 60, 220))
	words(sign, "FILES")
	m.Parent = parent
	return m, m.Body
end

-- a cork noticeboard on two posts, notes pinned to it, CO-OP across the top
local function coopBoard(parent, at)
	local m = Instance.new("Model")
	m.Name = "CoopBoard"
	local function q(name, size, cf, color, mat, shape) return part(m, name, size, at * cf, color, mat, shape) end
	local WOODD = rgb(110, 68, 38)
	for _, x in { -2.5, 2.5 } do q("Post", V(0.4, 5.6, 0.4), CF(x, 2.8, 0), WOODD) end
	local board = q("Board", V(5.2, 3.2, 0.3), CF(0, 3.6, 0), rgb(195, 145, 95))
	q("FrameTop", V(5.4, 0.25, 0.4), CF(0, 5.25, 0), WOODD)
	q("FrameBottom", V(5.4, 0.25, 0.4), CF(0, 1.95, 0), WOODD)
	local NOTES = {
		{ -1.6, 4.4, rgb(255, 255, 255), 8 }, { -0.3, 4.5, rgb(255, 235, 120), -6 }, { 1.1, 4.3, rgb(255, 180, 210), 5 },
		{ -1.1, 2.9, rgb(170, 220, 255), -4 }, { 0.5, 2.8, rgb(255, 255, 255), 7 }, { 1.8, 3.0, rgb(190, 255, 190), -8 },
	}
	for _, n in NOTES do
		local note = q("Note", V(1.0, 1.15, 0.05), CF(n[1], n[2], -0.18) * CFrame.Angles(0, 0, math.rad(n[4])), n[3])
		q("Pin", V(0.18, 0.18, 0.18), note.CFrame * CF(0, 0.45, -0.06), rgb(230, 50, 60), nil, Enum.PartType.Ball)
		for k = 0, 1 do q("Line", V(0.7, 0.07, 0.03), note.CFrame * CF(0, 0.05 - k * 0.25, -0.03), rgb(150, 160, 180)) end
	end
	local sign = q("Sign", V(5.4, 1.0, 0.3), CF(0, 5.9, 0), rgb(140, 80, 240))
	words(sign, "CO-OP")
	m.Parent = parent
	return m, board
end

-- the School Board's desk: a reception desk, a bell, a gold star, SCHOOL BOARD up on two posts
local function boardDesk(parent, at)
	local m = Instance.new("Model")
	m.Name = "SchoolBoardDesk"
	local function q(name, size, cf, color, mat, shape) return part(m, name, size, at * cf, color, mat, shape) end
	local WOOD, GOLDL, PURPLE = rgb(120, 78, 48), rgb(255, 205, 70), rgb(164, 92, 255)
	local desk = q("Desk", V(6, 3, 2), CF(0, 1.5, 0), WOOD)
	q("DeskTop", V(6.3, 0.3, 2.3), CF(0, 3.15, 0), rgb(90, 58, 35))
	q("Trim", V(6.02, 0.25, 2.02), CF(0, 2.6, 0), GOLDL)
	q("Panel", V(2.2, 1.6, 0.1), CF(0, 1.4, -1.03), rgb(140, 92, 58))
	q("Star", V(0.9, 0.9, 0.12), CF(0, 1.4, -1.1) * CFrame.Angles(0, 0, math.rad(45)), GOLDL, Enum.Material.Neon)
	q("Bell", V(0.6, 0.6, 0.6), CF(1.8, 3.55, -0.4), GOLDL, Enum.Material.Metal, Enum.PartType.Ball)
	q("BellBase", V(0.8, 0.12, 0.8), CF(1.8, 3.35, -0.4), rgb(60, 62, 72), Enum.Material.Metal)
	for _, x in { -3.3, 3.3 } do q("Post", V(0.4, 6.4, 0.4), CF(x, 3.2, 0.9), rgb(60, 62, 72), Enum.Material.Metal) end
	local sign = q("Sign", V(7, 1.4, 0.3), CF(0, 6.1, 0.9), PURPLE)
	words(sign, "SCHOOL BOARD")
	m.Parent = parent
	return m, desk
end

---------------------------------------------------------------------------
-- placing them
---------------------------------------------------------------------------
local function groundY(pos, ignore)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = ignore or {}
	local hit = workspace:Raycast(pos + V(0, 40, 0), V(0, -80, 0), rp)
	return hit and hit.Position.Y or pos.Y
end

local function dressPlot(plot)
	if plot:FindFirstChild("Places") then return end
	local folder = Instance.new("Model")
	folder.Name = "Places"
	folder.Parent = plot
	local pv = plot:GetPivot()
	-- (facing the entrance path: the pieces' front, -Z, turned to the plot's -X)
	local face = CFrame.Angles(0, math.rad(90), 0)
	local function spot(x, z)
		local p = (pv * CF(x, 0, z)).Position
		return CF(p.X, groundY(p, { folder }), p.Z) * pv.Rotation * face
	end
	local _, yTop = yearbookShelf(folder, spot(24, 66))
	prompt(yTop, "Open the Yearbook", "Yearbook", true).Triggered:Connect(function(player)
		if mine(player, plot) then open(player, "Yearbook", "Yearbook") end
	end)
	local _, fBody = filesCabinet(folder, spot(24, 73))
	prompt(fBody, "Read your Files", "VexCorp Files", true).Triggered:Connect(function(player)
		if mine(player, plot) then open(player, "Files", "Files") end
	end)
	local _, cBoard = coopBoard(folder, spot(24, 80))
	prompt(cBoard, "Co-op", "Run a school with friends", false).Triggered:Connect(function(player)
		open(player, "Coop", "Coop")
	end)
	-- the sign over the gate: name your school
	local sign = plot:FindFirstChild("Sign")
	if sign then
		local pp = prompt(sign, "Name your school", "Your school's sign", true)
		pp.MaxActivationDistance = 22
		pp.Triggered:Connect(function(player)
			if mine(player, plot) then open(player, "Name", "NameSchool") end
		end)
	end
end

function PlacesService.start()
	local plots = workspace:WaitForChild("Plots")
	for _, plot in plots:GetChildren() do
		if plot:IsA("Model") then dressPlot(plot) end
	end
	plots.ChildAdded:Connect(function(plot)
		if plot:IsA("Model") then task.defer(dressPlot, plot) end
	end)
	-- the School Board's desk, on the path between the District Office's two leaderboards
	local lm = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Landmarks")
	local office = lm and lm:FindFirstChild("DistrictOffice")
	if office then
		local door = office:FindFirstChild("Door", true)
		local at = door and door.Position or V(190, 4.5, -73.9)
		-- (in front of the two leaderboards, which stand 16 studs out from the door)
		local base = V(at.X, 0, at.Z + 21)
		local cf = CF(base.X, groundY(base, { office }), base.Z) * CFrame.Angles(0, math.pi, 0)
		local _, desk = boardDesk(office, cf)
		PlacesService.boardAt = desk.Position
		workspace:SetAttribute("BoardDeskAt", desk.Position)
		local pp = prompt(desk, "Face the Board", "School Board", false)
		pp.Triggered:Connect(function(player) open(player, "Board", "Board") end)
	end
end

return PlacesService
