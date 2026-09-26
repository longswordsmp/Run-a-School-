-- ServerScriptService.Server.StudentFactory
-- Builds student rigs (kid-proportioned R15) with the Steal-a-X style billboard.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Props = require(script.Parent.StudentProps)
local KidAvatars = require(script.Parent.KidAvatars)

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
	-- default R15 run and fall (loaded in Studio: run 0.625 s, fall 0.79 s)
	run = "rbxassetid://913376220",
	fall = "rbxassetid://507767968",
	-- default R15 emotes (loaded in Studio: wave 1.75s, point 1.79s, cheer 2.5s, laugh 3.29s, dance 1.08s)
	wave = "rbxassetid://507770239",
	point = "rbxassetid://507770453",
	cheer = "rbxassetid://507770677",
	laugh = "rbxassetid://507770818",
	dance = "rbxassetid://507771019",
}

-- templates live in ReplicatedStorage so the client can render them in viewports (Yearbook, shop)
local templates = ReplicatedStorage:FindFirstChild("StudentTemplates")
if not templates then
	templates = Instance.new("Folder")
	templates.Name = "StudentTemplates"
	templates.Parent = ReplicatedStorage
end

-- a real avatar (KidAvatars): the ROBLOX Boy / Girl body, a dynamic head, catalog clothes and hair
local ACCESSORY_FIELDS = {
	hair = "HairAccessory", hat = "HatAccessory", face = "FaceAccessory", neck = "NeckAccessory",
	back = "BackAccessory", front = "FrontAccessory", waist = "WaistAccessory", shoulder = "ShouldersAccessory",
}
local function avatarDescription(def, av)
	local look = def.look
	local skin = KidAvatars.Skin[av.skin or look.skin] or KidAvatars.Skin.light
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor, desc.TorsoColor = skin, skin
	desc.LeftArmColor, desc.RightArmColor, desc.LeftLegColor, desc.RightLegColor = skin, skin, skin, skin
	for part, id in KidAvatars.Bodies[av.body or "boy"] do desc[part] = id end
	desc.Head = av.head or KidAvatars.Faces.smile
	desc.Shirt = av.shirt or 0
	desc.Pants = av.pants or 0
	desc.GraphicTShirt = av.tshirt or 0
	for key, field in ACCESSORY_FIELDS do
		if av[key] then desc[field] = av[key] end
	end
	-- kid-sized: a bit shorter and slimmer than a player, head a touch big
	local s = look.scale or 1
	desc.HeightScale = 0.85 * s
	desc.WidthScale = 0.9 * s
	desc.DepthScale = 0.9 * s
	desc.HeadScale = 1.05 * (look.head or 1) * math.sqrt(s)
	desc.BodyTypeScale = 0
	desc.ProportionScale = 0
	return desc
end

-- the old blocky kid: body parts coloured as shirt and pants, blocky hair from StudentProps
local function blockyDescription(def)
	local look = def.look
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = SKIN[look.skin] or SKIN.light
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
	return desc
end

-- keep only part of a signature prop (KidAvatars prop = "hands", "head", "body" or a mix like
-- "hands,head"): every prop part is welded to a body part, or to another prop part that is
local HELD = { RightHand = true, LeftHand = true, RightLowerArm = true, LeftLowerArm = true }
local function groupOf(at)
	if at == "Head" then return "head" end
	if HELD[at] then return "hands" end
	return "body"
end
local function trimProp(model, mode)
	local keep = {}
	for g in mode:gmatch("%a+") do keep[g] = true end
	local folder = model:FindFirstChild("Props")
	if not folder then return end
	local function anchorOf(part, depth)
		local w = part:FindFirstChildOfClass("Weld")
		local to = w and w.Part0
		if not to or depth > 8 then return nil end
		if to:IsDescendantOf(folder) then return anchorOf(to, depth + 1) end
		return to.Name
	end
	local drop = {}
	for _, part in folder:GetDescendants() do
		if part:IsA("BasePart") then
			local at = anchorOf(part, 0)
			if not keep[groupOf(at)] then table.insert(drop, part) end
		end
	end
	for _, part in drop do part:Destroy() end
end

local function makeTemplate(def)
	local look = def.look
	local av = KidAvatars.Kids[def.id]
	local skin = av and (KidAvatars.Skin[av.skin or look.skin] or KidAvatars.Skin.light) or SKIN[look.skin] or SKIN.light
	local model
	if av then
		-- (the catalog can fail to load: then this kid stays blocky rather than not existing)
		local ok, m = pcall(Players.CreateHumanoidModelFromDescription, Players, avatarDescription(def, av), Enum.HumanoidRigType.R15)
		if ok then
			model = m
		else
			warn("[StudentFactory] avatar failed, blocky instead:", def.id, m)
			av = nil
			skin = SKIN[look.skin] or SKIN.light
		end
	end
	model = model or Players:CreateHumanoidModelFromDescription(blockyDescription(def), Enum.HumanoidRigType.R15)
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

	-- an avatar kid has real hair; its signature prop stays, or the part of it the outfit doesn't cover
	if not av then Props.hair(model, def) end
	if not av or av.prop ~= false then Props.add(model, def) end
	if av and type(av.prop) == "string" then trimProp(model, av.prop) end
	if av then
		model:SetAttribute("Avatar", true)
		-- the floating tag clears a tall hat
		if av.hat then model:SetAttribute("TagLift", 0.9) end
	end
	model.Parent = templates
	return model
end

-- one build per kid, even when the preload and a bus ask at the same moment
local building = {}
local function getTemplate(def)
	local t = templates:FindFirstChild(def.id)
	if t then return t end
	if building[def.id] then
		while building[def.id] do task.wait() end
		return templates:FindFirstChild(def.id) or getTemplate(def)
	end
	building[def.id] = true
	local ok, m = pcall(makeTemplate, def)
	building[def.id] = nil
	if not ok then error(m) end
	return m
end

-- warm the cache at boot so the first bus does not hitch
function Factory.preload()
	-- (six at a time: an avatar kid waits on its catalog assets loading)
	local queue = table.clone(Config.Students)
	local running = 0
	while #queue > 0 or running > 0 do
		while running < 6 and #queue > 0 do
			local def = table.remove(queue, 1)
			running += 1
			task.spawn(function()
				local ok, err = pcall(getTemplate, def)
				if not ok then warn("[StudentFactory] template failed for", def.id, err) end
				running -= 1
			end)
		end
		task.wait()
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
	bb.StudsOffsetWorldSpace = Vector3.new(0, 3.6 + (model:GetAttribute("TagLift") or 0), 0)
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
		bb.StudsOffsetWorldSpace = Vector3.new(0, 3 + (model:GetAttribute("TagLift") or 0), 0)
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

-- what to rotate for a procedural pose on a joint: Motor6D.C0, or on the newer AnimationConstraint
-- rigs (what CreateHumanoidModelFromDescription builds now) the joint's parent-side attachment
function Factory.poseTarget(joint)
	if not joint then return nil end
	if joint:IsA("Motor6D") then return joint, "C0" end
	if joint.ClassName == "AnimationConstraint" and joint.Attachment0 then return joint.Attachment0, "CFrame" end
	return nil
end

-- a one-shot gesture over whatever the rig is doing (wave, cheer, laugh, point, dance)
function Factory.emote(model, which)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator or not Factory.Anims[which] then return end
	local a = Instance.new("Animation")
	a.AnimationId = Factory.Anims[which]
	local track = animator:LoadAnimation(a)
	track.Looped = false
	track.Priority = Enum.AnimationPriority.Action2
	track:Play(0.2)
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
