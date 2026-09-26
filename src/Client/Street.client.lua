-- StarterPlayer.StarterPlayerScripts.Street
-- Recess Row follows your story (StreetService builds the props into ReplicatedStorage.StreetStages).
-- This shows the stages your chapter has reached (player attribute "Chapter", or "DebugChapter" in
-- Studio), makes the map edits that go with them (the Vex billboard, the drained fountain, Kevin's
-- sign, the sky), and animates them: searchlights sweep, gears turn, the core pulses, lightning.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local stages = ReplicatedStorage:WaitForChild("StreetStages", 60)
if not stages then return end

local localFolder = Instance.new("Folder")
localFolder.Name = "StreetLocal"
localFolder.Parent = workspace

local shown = {} -- [stage name] = clone

local function chapter()
	return player:GetAttribute("DebugChapter") or player:GetAttribute("Chapter")
end

---------------------------------------------------------------------------
-- map edits
---------------------------------------------------------------------------
-- (looked up fresh every time: far landmarks stream in and out, so nothing here is cached)
local map = workspace:WaitForChild("Map", 30)
local function landmark(name)
	local lm = map and map:FindFirstChild("Landmarks")
	return lm and lm:FindFirstChild(name)
end

-- a sign's label, remembering what it said before the story changed it
local function textOf(part)
	local g = part and part:FindFirstChildWhichIsA("SurfaceGui")
	local t = g and g:FindFirstChildWhichIsA("TextLabel")
	if t and t:GetAttribute("Orig") == nil then t:SetAttribute("Orig", t.Text) end
	return t
end
local function setText(part, text)
	local t = textOf(part)
	if t then t.Text = text or t:GetAttribute("Orig") end
end

local gloom = Instance.new("ColorCorrectionEffect")
gloom.Name = "StreetGloom"
gloom.Enabled = false
gloom.Parent = Lighting

local function mapEdits(n)
	n = n or 0
	local shack = landmark("SugarShack")
	-- the Vex billboard behind the Sugar Shack
	setText(shack and shack:FindFirstChild("VexBillboard"), (n >= 12 and "CLOSED!\nRECESS IS BACK.\n(thanks, Principal)")
		or (n >= 10 and "THE MACHINE IS AWAKE.\nHOMEWORK. FOREVER.\n- Dr. V. Vex")
		or (n >= 3 and "NOW OPEN:\nVEX HOMEWORK FACTORY\n\"Recess is cancelled.\"")
		or nil)
	-- the Sugar Baron was Kevin all along (chapter 8's mission): the shack's his now, and the Baron
	-- is gone from its roof (hidden for you only: he's everyone's NPC)
	setText(shack and shack:FindFirstChild("Sign"), n >= 9 and "KEVIN'S WATERSLIDE (SOON)" or nil)
	local npcs = workspace:FindFirstChild("StoryNPCs")
	local baron = npcs and npcs:FindFirstChild("SugarBaron")
	if baron then
		local gone = n >= 9
		for _, d in baron:GetDescendants() do
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = gone and 1 or 0
			elseif d:IsA("BillboardGui") then
				-- (the server switches his speech bubble on and off; a zero size keeps it unseen)
				if d:GetAttribute("OrigSize") == nil then d:SetAttribute("OrigSize", d.Size) end
				d.Size = gone and UDim2.new() or d:GetAttribute("OrigSize")
			end
		end
	end
	-- Vex drains the fountain when she "buys" the place (chapter 5); it's back when she's beaten
	local drained = n >= 5 and n <= 11
	local fountain = landmark("HubFountain")
	if fountain then
		local water = fountain:FindFirstChild("Water")
		if water then water.LocalTransparencyModifier = drained and 1 or 0 end
		for _, d in fountain:GetDescendants() do
			if d:IsA("ParticleEmitter") then d.Enabled = not drained end
		end
	end
	-- the sky dims as the Machine wakes
	local target = (n == 11 and { TintColor = Color3.fromRGB(205, 185, 240), Saturation = -0.35, Brightness = -0.07, Contrast = 0.08 })
		or (n == 10 and { TintColor = Color3.fromRGB(226, 210, 252), Saturation = -0.18, Brightness = -0.03, Contrast = 0.04 })
		or nil
	if target then
		gloom.Enabled = true
		TweenService:Create(gloom, TweenInfo.new(3), target):Play()
	else
		TweenService:Create(gloom, TweenInfo.new(3), { TintColor = Color3.new(1, 1, 1), Saturation = 0, Brightness = 0, Contrast = 0 }):Play()
	end
end

---------------------------------------------------------------------------
-- the stages
---------------------------------------------------------------------------
local anim = { heads = {}, gears = {}, pulses = {}, blinks = {}, tips = {}, arms = {} }

local function index(clone)
	for _, d in clone:GetDescendants() do
		if d:IsA("Model") and d.Name:match("^SearchHead") and d.PrimaryPart then
			-- sweep round from where it was built (tipped up over the street)
			table.insert(anim.heads, { model = d, base = CFrame.new(d.PrimaryPart.Position), phase = #anim.heads * 2.1 })
		elseif d:IsA("Model") and d:GetAttribute("Spin") and d.PrimaryPart then
			-- gears turn on their hub's axis (X); the core's swirl of pages on Z
			table.insert(anim.gears, { model = d, base = d:GetPivot(), speed = d:GetAttribute("Spin"), z = d:GetAttribute("Axis") == "Z" })
		elseif d:IsA("Model") and d:GetAttribute("Tap") and d.PrimaryPart then
			table.insert(anim.arms, { model = d, base = d:GetPivot() })
		elseif d:GetAttribute("Pulse") then
			table.insert(anim.pulses, d)
		elseif d:GetAttribute("Blink") then
			table.insert(anim.blinks, d)
		elseif d:GetAttribute("ArcTip") then
			table.insert(anim.tips, d)
		end
	end
end

local function reindex()
	anim = { heads = {}, gears = {}, pulses = {}, blinks = {}, tips = {}, arms = {} }
	for _, clone in shown do index(clone) end
end

local lastN
local function apply()
	local n = chapter()
	for _, st in stages:GetChildren() do
		local from, to = st:GetAttribute("From") or 1, st:GetAttribute("To") or 99
		local want = n ~= nil and n >= from and n <= to
		if want and not shown[st.Name] then
			local c = st:Clone()
			c.Parent = localFolder
			shown[st.Name] = c
		elseif not want and shown[st.Name] then
			shown[st.Name]:Destroy()
			shown[st.Name] = nil
		end
	end
	reindex()
	mapEdits(n)
	lastN = n
end

-- far landmarks (and NPCs) streaming in get the story's edits too
local pending = false
local function onStreamed(d)
	if pending or not (d:IsA("SurfaceGui") or d:IsA("BillboardGui") or d.Name == "Water" or d:IsA("ParticleEmitter")) then return end
	pending = true
	task.delay(0.5, function()
		pending = false
		mapEdits(chapter())
	end)
end
if map then map.DescendantAdded:Connect(onStreamed) end
task.spawn(function()
	local npcs = workspace:WaitForChild("StoryNPCs", 60)
	if npcs then
		npcs.DescendantAdded:Connect(onStreamed)
		mapEdits(chapter())
	end
end)
player:GetAttributeChangedSignal("Chapter"):Connect(apply)
player:GetAttributeChangedSignal("DebugChapter"):Connect(apply)
stages.ChildAdded:Connect(function() task.defer(apply) end)
apply()

---------------------------------------------------------------------------
-- animation
---------------------------------------------------------------------------
local function arc(a, b)
	-- a jagged purple bolt between the Machine's two rods, gone in a blink
	local bolt = Instance.new("Model")
	bolt.Name = "Bolt"
	local pts = { a }
	local segs = 7
	for i = 1, segs - 1 do
		local p = a:Lerp(b, i / segs)
		table.insert(pts, p + Vector3.new(0, math.random() * 3 - 0.5, (math.random() - 0.5) * 3))
	end
	table.insert(pts, b)
	for i = 1, #pts - 1 do
		local p0, p1 = pts[i], pts[i + 1]
		local seg = Instance.new("Part")
		seg.Anchored = true
		seg.CanCollide = false
		seg.CanQuery = false
		seg.CanTouch = false
		seg.CastShadow = false
		seg.Material = Enum.Material.Neon
		seg.Color = Color3.fromRGB(225, 190, 255)
		seg.Size = Vector3.new(0.35, 0.35, (p1 - p0).Magnitude)
		seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
		seg.Parent = bolt
	end
	local flash = Instance.new("PointLight")
	flash.Range = 50
	flash.Brightness = 6
	flash.Color = Color3.fromRGB(200, 140, 255)
	flash.Parent = bolt:FindFirstChildWhichIsA("Part")
	bolt.Parent = localFolder
	task.delay(0.12, function() bolt:Destroy() end)
end

local t = 0
local nextArc = 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	for _, h in anim.heads do
		if h.model.Parent then
			local yaw = math.sin(t * 0.45 + h.phase) * math.rad(55)
			local pitch = math.rad(22 + math.sin(t * 0.7 + h.phase) * 8)
			h.model:PivotTo(h.base * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0))
		end
	end
	for _, g in anim.gears do
		if g.model.Parent then
			local a = math.rad(g.speed) * t
			g.model:PivotTo(g.base * (g.z and CFrame.Angles(0, 0, a) or CFrame.Angles(a, 0, 0)))
		end
	end
	-- the pencil arm stamps the street twice every few seconds
	for _, a in anim.arms do
		if a.model.Parent then
			local ph = t % 2.8
			local dip = (ph < 0.3 and math.sin(ph / 0.3 * math.pi)) or ((ph > 0.45 and ph < 0.75) and math.sin((ph - 0.45) / 0.3 * math.pi)) or 0
			a.model:PivotTo(a.base * CFrame.Angles(-math.rad(9) * dip, 0, 0))
		end
	end
	local pulse = 0.5 + 0.5 * math.sin(t * 2.2)
	for _, p in anim.pulses do
		if p:IsA("BasePart") then
			p.Color = Color3.fromRGB(150, 60, 230):Lerp(Color3.fromRGB(235, 170, 255), pulse)
		elseif p:IsA("PointLight") then
			p.Brightness = 1.5 + pulse * 3
		end
	end
	local on = (t % 1) < 0.5
	for _, b in anim.blinks do
		b.Transparency = on and 0 or 0.7
	end
	if #anim.tips >= 2 and t >= nextArc then
		nextArc = t + 1.5 + math.random() * 2.5
		arc(anim.tips[1].Position, anim.tips[2].Position)
	end
end)
