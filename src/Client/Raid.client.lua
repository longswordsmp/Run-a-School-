-- StarterPlayer.StarterPlayerScripts.Raid
-- The client side of VexCorp raids (RaidService): a banner while your school is being raided, the
-- hit feel when your Ruler connects (a short camera shake and a BONK! pop at the goon), and the
-- result when it's over.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local gui = UI.new("ScreenGui", {
	Name = "Raid",
	ResetOnSpawn = false,
	DisplayOrder = 6,
	Parent = player:WaitForChild("PlayerGui"),
})
UI.autoScale(gui)

---------------------------------------------------------------------------
-- the banner, top centre, only while a raid is on
---------------------------------------------------------------------------
local RED = Color3.fromRGB(235, 55, 75)
local banner = UI.new("Frame", {
	Name = "Banner",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(360, 46),
	BackgroundColor3 = UI.C.white,
	Visible = false,
	Parent = gui,
})
UI.corner(banner, 23)
UI.stroke(banner, 3)
local function tint(color)
	for _, g in banner:GetChildren() do
		if g:IsA("UIGradient") then g:Destroy() end
	end
	UI.gradient(banner, color:Lerp(Color3.new(1, 1, 1), 0.25), color)
end
tint(RED)
local bannerText = UI.label(banner, { Text = "", Font = UI.BIG, Size = UDim2.new(1, -24, 1, -10), Position = UDim2.fromOffset(12, 5), stroke = 2.5 })

local function goonsLeft()
	local plot = player:GetAttribute("Plot")
	local folder = workspace:FindFirstChild("Raids")
	local n, carrying, crumpet = 0, 0, false
	for _, m in folder and folder:GetChildren() or {} do
		if m:GetAttribute("RaidGoon") and m:GetAttribute("PlotName") == plot then
			n += 1
			if m:GetAttribute("Carrying") then
				carrying += 1
				if m.Name == "Crumpet" then crumpet = true end
			end
		end
	end
	return n, carrying, crumpet
end

local raidOn = false
local heistOn = false
task.spawn(function()
	while true do
		task.wait(0.25)
		if raidOn then
			local n, carrying, crumpet = goonsLeft()
			if carrying > 0 then
				bannerText.Text = crumpet and "\u{1F3A9} CRUMPET HAS YOUR KID! BONK HIM!"
					or carrying == 1 and "\u{1F6A8} A GOON HAS YOUR KID! BONK HIM!" or ("\u{1F6A8} %d GOONS HAVE YOUR KIDS!"):format(carrying)
				local pulse = 0.5 + 0.5 * math.sin(os.clock() * 8)
				banner.Size = UDim2.fromOffset(420 + pulse * 12, 46 + pulse * 3)
			elseif n > 0 then
				bannerText.Text = n == 1 and "\u{1F6A8} VEXCORP RAID!" or ("\u{1F6A8} VEXCORP RAID! %d GOONS"):format(n)
				banner.Size = UDim2.fromOffset(360, 46)
			end
		end
	end
end)

---------------------------------------------------------------------------
-- hit feel: a camera shake and a BONK! at the goon
---------------------------------------------------------------------------
local shakeUntil, shakeAmp = 0, 0
RunService:BindToRenderStep("RaidShake", Enum.RenderPriority.Camera.Value + 1, function()
	local t = os.clock()
	if t < shakeUntil then
		local a = shakeAmp * (shakeUntil - t) / 0.2
		camera.CFrame = camera.CFrame * CFrame.new((math.random() - 0.5) * a, (math.random() - 0.5) * a, 0)
	end
end)

local function pop(pos, text, color)
	local anchor = Instance.new("Part")
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.Position = pos
	anchor.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 90)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Parent = anchor
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = UI.BIG
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color
	t.Rotation = math.random(-12, 12)
	t.Parent = bb
	local s = Instance.new("UIStroke")
	s.Thickness = 4
	s.Parent = t
	local sc = Instance.new("UIScale")
	sc.Scale = 0.3
	sc.Parent = t
	TweenService:Create(sc, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.15 }):Play()
	TweenService:Create(bb, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = Vector3.new(0, 2.5, 0) }):Play()
	task.delay(0.35, function()
		TweenService:Create(t, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
		TweenService:Create(s, TweenInfo.new(0.35), { Transparency = 1 }):Play()
	end)
	game:GetService("Debris"):AddItem(anchor, 0.8)
end

---------------------------------------------------------------------------
-- server pushes
---------------------------------------------------------------------------
Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
	if kind == "raid" then
		raidOn = true
		banner.Visible = true
		bannerText.Text = data and data.tutorial and "\u{1F3A9} Someone's coming..." or "\u{1F6A8} VEXCORP RAID!"
		UI.pop(banner, 0.4)
	elseif kind == "raidOver" then
		raidOn = false
		if data and data.defended and data.cash then
			bannerText.Text = ("\u{1F6E1}\u{FE0F} RAID DEFENDED! +%s"):format(Config.formatCash(data.cash))
			tint(Color3.fromRGB(40, 170, 80))
		elseif data and data.lost and data.lost > 0 then
			bannerText.Text = data.lost == 1 and "They got one. Get them back from VexCorp!" or ("They got %d. Get them back from VexCorp!"):format(data.lost)
		else
			banner.Visible = false
			return
		end
		banner.Size = UDim2.fromOffset(460, 46)
		UI.punch(banner, 1.1)
		task.delay(3.5, function()
			if not raidOn then
				banner.Visible = false
				tint(RED)
			end
		end)
	elseif kind == "heist" and data then
		-- the Factory: carrying a kid out, and how it ended
		if data.state == "carrying" then
			heistOn = true
			tint(Color3.fromRGB(150, 70, 220))
			bannerText.Text = ("\u{1F3C3} GET %s OUT THE GATE!"):format(data.name:upper())
			banner.Size = UDim2.fromOffset(460, 46)
			banner.Visible = true
			UI.pop(banner, 0.4)
		else
			heistOn = false
			if data.state == "rescued" or data.state == "prize" then
				tint(Color3.fromRGB(40, 170, 80))
				bannerText.Text = data.state == "prize" and ("\u{1F389} YOU STOLE %s (%s)!"):format(data.name:upper(), (data.rarity or ""):upper())
					or ("\u{1F389} RESCUED %s!"):format(data.name:upper())
				UI.punch(banner, 1.1)
				task.delay(3.5, function()
					if not raidOn and not heistOn then
						banner.Visible = false
						tint(RED)
					end
				end)
			else
				banner.Visible = raidOn
				tint(RED)
			end
		end
	elseif kind == "hit" and data then
		shakeUntil, shakeAmp = os.clock() + 0.2, data.ko and 0.9 or 0.5
		pop(data.pos, data.ko and "K.O.!" or "BONK!", data.ko and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(255, 230, 90))
	end
end)

---------------------------------------------------------------------------
-- the Factory: homework slides along the belts, the presses stamp
---------------------------------------------------------------------------
local CollectionService = game:GetService("CollectionService")
local sheets, pistons = {}, {}
local function addSheet(p)
	if p:IsA("BasePart") then sheets[p] = { y = p.Position.Y, rot = p.CFrame - p.Position } end
end
local function addPiston(p)
	if p:IsA("BasePart") then pistons[p] = { base = p.CFrame, phase = math.random() * 2 } end
end
for _, p in CollectionService:GetTagged("BeltItem") do addSheet(p) end
for _, p in CollectionService:GetTagged("Piston") do addPiston(p) end
CollectionService:GetInstanceAddedSignal("BeltItem"):Connect(addSheet)
CollectionService:GetInstanceAddedSignal("Piston"):Connect(addPiston)
CollectionService:GetInstanceRemovedSignal("BeltItem"):Connect(function(p) sheets[p] = nil end)
CollectionService:GetInstanceRemovedSignal("Piston"):Connect(function(p) pistons[p] = nil end)
local BELT_SPEED = 3
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	-- only animate when you're near enough to see it
	if root and (root.Position - Vector3.new(0, 0, 86)).Magnitude > 160 then return end
	for p, s in sheets do
		if p.Parent then
			local len = p:GetAttribute("BeltLen") or 40
			local x = -len / 2 + ((p:GetAttribute("Offset") or 0) + t * BELT_SPEED) % len
			p.CFrame = CFrame.new(x, s.y, p:GetAttribute("BeltZ") or p.Position.Z) * s.rot
		else
			sheets[p] = nil
		end
	end
	for p, s in pistons do
		if p.Parent then
			-- a quick stamp every 2.2 s
			local k = ((t + s.phase) % 2.2) / 2.2
			local drop = k < 0.12 and (k / 0.12) or (k < 0.3 and 1 or math.max(0, 1 - (k - 0.3) / 0.4))
			p.CFrame = s.base * CFrame.new(0, -3.4 * drop, 0)
		else
			pistons[p] = nil
		end
	end
end)
