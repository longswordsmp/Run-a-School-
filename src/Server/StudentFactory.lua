-- ServerScriptService.Server.StudentFactory
-- Builds student rigs (kid-proportioned R15) with the Steal-a-X style billboard.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Props = require(script.Parent.StudentProps)

local Factory = {}

local SKIN = {
	light = Color3.fromRGB(255, 214, 180),
	tan = Color3.fromRGB(226, 172, 128),
	brown = Color3.fromRGB(160, 106, 70),
	dark = Color3.fromRGB(100, 64, 44),
}

Factory.Anims = {
	walk = "rbxassetid://507777826",
	idle = "rbxassetid://507766388",
	sit = "rbxassetid://2506281703",
}

-- templates live in ReplicatedStorage so the client can render them in viewports (Yearbook, shop)
local templates = ReplicatedStorage:FindFirstChild("StudentTemplates")
if not templates then
	templates = Instance.new("Folder")
	templates.Name = "StudentTemplates"
	templates.Parent = ReplicatedStorage
end

local function makeTemplate(def)
	local look = def.look
	local skin = SKIN[look.skin] or SKIN.light
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = skin
	desc.LeftArmColor = look.shirt
	desc.RightArmColor = look.shirt
	desc.TorsoColor = look.shirt
	desc.LeftLegColor = look.pants
	desc.RightLegColor = look.pants
	local s = look.scale or 1
	desc.HeightScale = 0.82 * s
	desc.WidthScale = 0.9 * s
	desc.DepthScale = 0.9 * s
	desc.HeadScale = 1.25 * (look.head or 1) * math.sqrt(s)
	desc.BodyTypeScale = 0
	desc.ProportionScale = 0

	local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	model.Name = def.id
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.BreakJointsOnDeath = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	if not hum:FindFirstChildOfClass("Animator") then
		Instance.new("Animator").Parent = hum
	end
	-- hands in skin colour so the sleeves read as a shirt
	for _, n in { "LeftHand", "RightHand" } do
		local h = model:FindFirstChild(n)
		if h then h.Color = skin end
	end
	-- the kid face on the head decal comes with the default description
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
		end
	end
	model.PrimaryPart = model:FindFirstChild("HumanoidRootPart")
	model.PrimaryPart.Anchored = true
	model.PrimaryPart.CanQuery = true -- prompts and ruler hits need something queryable

	Props.hair(model, def)
	Props.add(model, def)
	model.Parent = templates
	return model
end

local function getTemplate(def)
	return templates:FindFirstChild(def.id) or makeTemplate(def)
end

-- warm the cache at boot so the first bus does not hitch
function Factory.preload()
	for _, def in Config.Students do
		local ok, err = pcall(getTemplate, def)
		if not ok then warn("[StudentFactory] template failed for", def.id, err) end
	end
end

local function label(parent, name, order, height, text, color)
	local t = Instance.new("TextLabel")
	t.Name = name
	t.LayoutOrder = order
	t.Size = UDim2.new(1, 0, height, 0)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color
	t.Parent = parent
	local s = Instance.new("UIStroke")
	s.Thickness = 2.5
	s.Color = Color3.fromRGB(0, 0, 0)
	s.Parent = t
	return t
end

local function rainbow(t)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
		ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 190, 40)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(80, 230, 90)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(60, 190, 255)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(170, 80, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 60)),
	})
	g:SetAttribute("Kind", "rainbow")
	g.Parent = t
	CollectionService:AddTag(g, "Rainbow")
	t.TextColor3 = Color3.new(1, 1, 1)
end

-- two-colour shimmer for Prodigy and Alumni (animated by the client like the rainbow)
local function shimmer(t, a, b)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, a),
		ColorSequenceKeypoint.new(0.5, b),
		ColorSequenceKeypoint.new(1, a),
	})
	g:SetAttribute("Kind", "shimmer")
	g.Parent = t
	CollectionService:AddTag(g, "Rainbow")
	t.TextColor3 = Color3.new(1, 1, 1)
end

local function buildBillboard(model, def, gradeId)
	local head = model:FindFirstChild("Head")
	local rarity = Config.RarityById[def.rarity]
	local grade = Config.GradeById[gradeId] or Config.Grades[1]
	local bb = Instance.new("BillboardGui")
	bb.Name = "Tag"
	-- rarer students get bigger tags so they read from across the hallway
	local w = 7.5 + (rarity.order - 1) * 0.7
	bb.Size = UDim2.new(w, 0, w * 0.58, 0)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)
	bb.MaxDistance = 90
	bb.LightInfluence = 0
	bb.Parent = head
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = bb

	if grade.id ~= "Normal" then
		local g = label(bb, "Grade", 1, 0.17, grade.id, grade.color)
		if grade.rainbow then rainbow(g) end
	end
	local r = label(bb, "Rarity", 2, 0.19, rarity.id, rarity.color)
	if rarity.rainbow then
		rainbow(r)
	elseif rarity.gradient then
		shimmer(r, rarity.gradient[1], rarity.gradient[2])
	end
	label(bb, "Name", 3, 0.22, def.name, Color3.new(1, 1, 1))
	local income = def.income * grade.mult
	label(bb, "Income", 4, 0.18, Config.formatCash(income) .. "/s", Color3.fromRGB(110, 255, 110))
	label(bb, "Price", 5, 0.2, Config.formatCash(def.price), Color3.fromRGB(255, 220, 60))
	return bb
end

-- mode: "hall" (price shown), "walking" (going to someone's school), "owned" (sitting at a desk)
function Factory.setMode(model, mode, extra)
	local bb = model.Head:FindFirstChild("Tag")
	if not bb then return end
	local price = bb:FindFirstChild("Price")
	if mode == "hall" then
		price.Visible = true
	elseif mode == "walking" then
		price.Visible = true
		price.Text = "-> " .. tostring(extra) .. "'s school"
		price.TextColor3 = Color3.new(1, 1, 1)
	elseif mode == "owned" then
		price.Visible = false
		bb.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		bb.MaxDistance = 45
	elseif mode == "carried" then
		price.Visible = true
		price.Text = "STOLEN!"
		price.TextColor3 = Color3.fromRGB(255, 70, 70)
	end
end

function Factory.play(model, which)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator then return end
	for _, tr in animator:GetPlayingAnimationTracks() do tr:Stop(0.15) end
	local a = Instance.new("Animation")
	a.AnimationId = Factory.Anims[which]
	local track = animator:LoadAnimation(a)
	track.Looped = true
	track.Priority = which == "sit" and Enum.AnimationPriority.Action or Enum.AnimationPriority.Movement
	track:Play(0.15)
	return track
end

-- height of the root part above the floor when standing
function Factory.standOffset(model)
	local hum = model:FindFirstChildOfClass("Humanoid")
	return hum.HipHeight + model.PrimaryPart.Size.Y / 2 + (model:GetAttribute("Hover") or 0)
end

-- teachers: adult proportions, their own template folder (the Shop renders them in viewports)
local teacherTemplates = ReplicatedStorage:FindFirstChild("TeacherTemplates")
if not teacherTemplates then
	teacherTemplates = Instance.new("Folder")
	teacherTemplates.Name = "TeacherTemplates"
	teacherTemplates.Parent = ReplicatedStorage
end

local function makeTeacherTemplate(tdef)
	local look = Props.TeacherLooks[tdef.outfit] or Props.TeacherLooks.sub
	local skin = SKIN[look.skin] or SKIN.light
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = skin
	desc.LeftArmColor = look.shirt
	desc.RightArmColor = look.shirt
	desc.TorsoColor = look.torso or look.shirt
	desc.LeftLegColor = look.pants
	desc.RightLegColor = look.pants
	desc.HeightScale = 1.08
	desc.WidthScale = 1
	desc.DepthScale = 1
	desc.HeadScale = 1.05
	desc.BodyTypeScale = 0.2
	desc.ProportionScale = 0
	local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	model.Name = tdef.id
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.BreakJointsOnDeath = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	if not hum:FindFirstChildOfClass("Animator") then
		Instance.new("Animator").Parent = hum
	end
	for _, n in { "LeftHand", "RightHand" } do
		local h = model:FindFirstChild(n)
		if h then h.Color = skin end
	end
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
		end
	end
	model.PrimaryPart = model:FindFirstChild("HumanoidRootPart")
	model.PrimaryPart.Anchored = true
	Props.teacher(model, tdef.outfit)
	model.Parent = teacherTemplates
	return model
end

-- withTag: a floating name tag (the Shop preview and lineups); in a classroom the teacher's
-- name sits on the desk nameplate instead so it never covers the chalkboard
function Factory.buildTeacher(tdef, floor, withTag)
	local template = teacherTemplates:FindFirstChild(tdef.id) or makeTeacherTemplate(tdef)
	local model = template:Clone()
	model:SetAttribute("TeacherId", tdef.id)
	if not withTag then return model end
	local bb = Instance.new("BillboardGui")
	bb.Name = "Tag"
	bb.Size = UDim2.new(9, 0, 3, 0)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	bb.MaxDistance = 70
	bb.LightInfluence = 0
	bb.Parent = model.Head
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = bb
	label(bb, "Title", 1, 0.28, tdef.title, Color3.fromRGB(255, 214, 90))
	label(bb, "Name", 2, 0.38, tdef.name, Color3.new(1, 1, 1))
	label(bb, "Boost", 3, 0.3, ("+%d%% tuition on floor %d"):format(math.floor((tdef.mult - 1) * 100 + 0.5), floor or 1), Color3.fromRGB(110, 255, 110))
	return model
end

function Factory.preloadTeachers()
	for _, t in Config.Teachers do
		if not teacherTemplates:FindFirstChild(t.id) then
			local ok, err = pcall(makeTeacherTemplate, t)
			if not ok then warn("[StudentFactory] teacher template failed for", t.id, err) end
		end
	end
end

function Factory.build(def, gradeId)
	local model = getTemplate(def):Clone()
	model:SetAttribute("StudentId", def.id)
	model:SetAttribute("Grade", gradeId)
	buildBillboard(model, def, gradeId)
	local grade = Config.GradeById[gradeId]
	if grade and grade.id ~= "Normal" then Props.gradeAura(model, grade) end
	Props.rarityAura(model, def)
	return model
end

return Factory
