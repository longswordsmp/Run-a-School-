-- ReplicatedFirst.Loading
-- The first thing a player sees: the RUN A SCHOOL title over a sky of school doodles, a row of the
-- school's kids waving, and a bus driving along the loading bar while the game loads. Then: "How are
-- you playing?" (computer or phone/tablet, the one this device looks like already picked; a
-- returning player's last choice is remembered) and a big PLAY button. Pressing it tells the server
-- the player is ready (the new-principal intro waits for that), sets the Device attribute (bigger UI
-- and touch buttons on phones) and fades into the game. Under it, CO-OP opens the co-op screen: pick
-- a role, then start a co-op school (friends join you) or join one running in this server
-- (CrewService); a new host gets Roblox's invite-friends window once in the game.
-- Built from plain Instances: it runs before ReplicatedStorage (and the shared UI module) arrives.
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local BIG = Enum.Font.LuckiestGuy
local FONT = Enum.Font.FredokaOne
local INK = Color3.fromRGB(24, 26, 52)
local WHITE = Color3.new(1, 1, 1)
local GREEN = Color3.fromRGB(61, 200, 96)
local RED = Color3.fromRGB(226, 52, 64)

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end
local function corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function stroke(o, t, c) return new("UIStroke", { Thickness = t, Color = c or INK, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o) end
local function textStroke(o, t, c) return new("UIStroke", { Thickness = t, Color = c or INK }, o) end
local function grad(o, a, b, rot)
	return new("UIGradient", { Color = ColorSequence.new(a, b), Rotation = rot or 90 }, o)
end
local function label(parent, props)
	local t = new("TextLabel", { BackgroundTransparency = 1, Font = FONT, TextScaled = true, TextColor3 = WHITE }, parent)
	for k, v in props do t[k] = v end
	return t
end

---------------------------------------------------------------------------
-- the screen
---------------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "Loading",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	DisplayOrder = 200,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)
ReplicatedFirst:RemoveDefaultLoadingScreen()
-- (the hotbar and the player list would sit on top of the buttons until we're in)
local StarterGui = game:GetService("StarterGui")
local function coreGui(on)
	for _, t in { Enum.CoreGuiType.Backpack, Enum.CoreGuiType.PlayerList } do
		pcall(StarterGui.SetCoreGuiEnabled, StarterGui, t, on)
	end
end
coreGui(false)

local sky = new("Frame", { Name = "Sky", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, gui)
local skyGrad = grad(sky, Color3.fromRGB(104, 196, 255), Color3.fromRGB(38, 112, 222))

-- doodles drifting up the sky
local DOODLES = { "\u{270F}\u{FE0F}", "\u{1F4DA}", "\u{1F34E}", "\u{1F68C}", "\u{1F392}", "\u{1F4D0}", "\u{1F514}", "\u{2B50}", "\u{1F3EB}", "\u{1F58D}\u{FE0F}" }
local doodles = {}
local rng = Random.new(7)
for i = 1, 26 do
	local d = label(sky, {
		Text = DOODLES[(i - 1) % #DOODLES + 1],
		Size = UDim2.fromOffset(64, 64),
		AnchorPoint = Vector2.new(0.5, 0.5),
		TextTransparency = 0.55,
		Rotation = rng:NextNumber(-25, 25),
		ZIndex = 1,
	})
	doodles[i] = { label = d, x = rng:NextNumber(0.02, 0.98), y = rng:NextNumber(0, 1.1), speed = rng:NextNumber(0.012, 0.03), size = rng:NextNumber(40, 78), spin = rng:NextNumber(-12, 12) }
	d.Size = UDim2.fromOffset(doodles[i].size, doodles[i].size)
end

-- everything else lives in a 1000-tall virtual screen, scaled to fit
local root = new("Frame", { Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, gui)
local scale = new("UIScale", {}, root)
local function fit()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1600, 900)
	local s = math.clamp(math.min(vp.Y / 1000, vp.X / 1300), 0.35, 1.4)
	scale.Scale = s
	root.Size = UDim2.fromScale(1 / s, 1 / s)
end
fit()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end

-- the title
local logo = new("Frame", { Name = "Logo", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 60), Size = UDim2.fromOffset(900, 230), ZIndex = 3 }, root)
local title = label(logo, { Text = "RUN A SCHOOL", Font = BIG, Size = UDim2.new(1, 0, 0, 150), Rotation = -3, ZIndex = 4 })
textStroke(title, 9, INK)
grad(title, WHITE, Color3.fromRGB(255, 236, 170))
local ribbon = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 150), Size = UDim2.fromOffset(470, 58), BackgroundColor3 = RED, Rotation = -3, ZIndex = 4 }, logo)
corner(ribbon, 14)
stroke(ribbon, 5)
grad(ribbon, Color3.fromRGB(255, 96, 104), RED)
label(ribbon, { Text = "RECESS IS ON THE LINE!", Font = BIG, Size = UDim2.new(1, -30, 1, -14), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 5 })

-- the kids, waving from the middle of the screen
local stage = new("ViewportFrame", {
	Name = "Kids",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 290),
	Size = UDim2.fromOffset(980, 380),
	BackgroundTransparency = 1,
	Ambient = Color3.fromRGB(170, 170, 185),
	LightColor = Color3.fromRGB(255, 250, 240),
	LightDirection = Vector3.new(-0.4, -1, -0.6),
	ZIndex = 3,
}, root)
local world = new("WorldModel", {}, stage)
local vcam = new("Camera", { FieldOfView = 30 }, stage)
stage.CurrentCamera = vcam

-- the bottom area: the loading bar, then the device choice
local bottom = new("Frame", { Name = "Bottom", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -40), Size = UDim2.fromOffset(900, 250), ZIndex = 3 }, root)

local barBack = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 120), Size = UDim2.fromOffset(760, 44), BackgroundColor3 = Color3.fromRGB(20, 40, 90), BackgroundTransparency = 0.25, ZIndex = 4 }, bottom)
corner(barBack, 22)
stroke(barBack, 4)
local barFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GREEN, ZIndex = 5 }, barBack)
corner(barFill, 22)
grad(barFill, Color3.fromRGB(130, 240, 140), Color3.fromRGB(40, 176, 80))
local bus = label(barBack, { Text = "\u{1F68C}", Size = UDim2.fromOffset(70, 70), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0, 0, 0, 12), ZIndex = 6 })
local status = label(bottom, { Text = "Unlocking the front doors...", Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 176), ZIndex = 4 })
textStroke(status, 3)
local tip = label(bottom, { Text = "", Font = FONT, Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 218), TextColor3 = Color3.fromRGB(225, 240, 255), ZIndex = 4 })
textStroke(tip, 2)
local TIPS = {
	"TIP: Bonk thieves with your Ruler before they reach the van!",
	"TIP: Sneak past VexCorp guards... or run for it!",
	"TIP: Lock your gate when goons are coming.",
	"TIP: Mr. Wobblesworth at the fountain has missions for you.",
	"TIP: Rarer kids earn way more tuition. Watch the buses!",
	"TIP: Your school saves by itself. Just keep playing!",
}

---------------------------------------------------------------------------
-- the kids on stage
---------------------------------------------------------------------------
local STARS = { "BandGeek", "CheerCaptain", "ClassClown", "SchoolMascot", "RocketKid" }
local WAVE = "rbxassetid://507770239"
local IDLE = "rbxassetid://507766388"
local CHEER = "rbxassetid://507770677"
local staged = false
local function stageKids()
	if staged then return end
	local templates = ReplicatedStorage:FindFirstChild("StudentTemplates")
	if not templates then return end
	local picks = {}
	for _, id in STARS do
		local t = templates:FindFirstChild(id)
		if t then table.insert(picks, t) end
	end
	if #picks < 3 then return end
	staged = true
	local n = #picks
	for i, t in picks do
		local m = t:Clone()
		for _, d in m:GetDescendants() do
			if d:IsA("BillboardGui") or d:IsA("ProximityPrompt") or d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
		end
		local root = m.PrimaryPart
		if root then
			root.Anchored = true
			local x = (i - (n + 1) / 2) * 3.4
			local z = math.abs(i - (n + 1) / 2) * 0.9
			-- (facing -Z, towards the camera; the outer ones turned in a little)
			m:PivotTo(CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad((i - (n + 1) / 2) * 8), 0))
			m.Parent = world
			local hum = m:FindFirstChildOfClass("Humanoid")
			local animator = hum and (hum:FindFirstChildOfClass("Animator") or new("Animator", {}, hum))
			if animator then
				task.spawn(function()
					local idle = animator:LoadAnimation(new("Animation", { AnimationId = IDLE }))
					idle.Looped = true
					idle:Play()
					-- a wave now and then, out of step with each other
					task.wait(0.3 + i * 0.45)
					while m.Parent do
						local a = animator:LoadAnimation(new("Animation", { AnimationId = (i % 2 == 0) and CHEER or WAVE }))
						a.Priority = Enum.AnimationPriority.Action
						a:Play(0.2)
						task.wait(4 + (i % 3))
					end
				end)
			end
		end
	end
	vcam.CFrame = CFrame.lookAt(Vector3.new(0, 3.2, -17.5), Vector3.new(0, 2.4, 0))
	stage.ImageTransparency = 1
	TweenService:Create(stage, TweenInfo.new(0.6), { ImageTransparency = 0 }):Play()
end

---------------------------------------------------------------------------
-- animation: drifting doodles, a bobbing title, the bus bumping along
---------------------------------------------------------------------------
local t0 = os.clock()
local progress, shown = 0, 0
local conn = RunService.RenderStepped:Connect(function(dt)
	local t = os.clock() - t0
	for _, d in doodles do
		d.y -= d.speed * dt
		if d.y < -0.08 then d.y = 1.08 end
		d.label.Position = UDim2.fromScale(d.x + math.sin(t * 0.6 + d.x * 9) * 0.01, d.y)
		d.label.Rotation += d.spin * dt
	end
	title.Rotation = -3 + math.sin(t * 1.6) * 1.2
	title.Position = UDim2.fromOffset(0, math.sin(t * 2.1) * 5)
	shown += (progress - shown) * math.min(1, dt * 6)
	barFill.Size = UDim2.fromScale(math.clamp(shown, 0.03, 1), 1)
	bus.Position = UDim2.new(math.clamp(shown, 0.03, 1), 0, 0, 12 + math.abs(math.sin(t * 9)) * -3)
end)

---------------------------------------------------------------------------
-- loading
---------------------------------------------------------------------------
task.spawn(function()
	local i = 0
	while gui.Parent do
		i += 1
		tip.Text = TIPS[(i - 1) % #TIPS + 1]
		task.wait(3.5)
	end
end)

if not game:IsLoaded() then game.Loaded:Wait() end
progress = 0.25
status.Text = "Waking up the teachers..."
local templates = ReplicatedStorage:WaitForChild("StudentTemplates", 30)
local students = 70
local waited = os.clock()
while templates and #templates:GetChildren() < students and os.clock() - waited < 25 do
	progress = 0.25 + 0.4 * (#templates:GetChildren() / students)
	status.Text = ("Kids arriving by bus... %d/%d"):format(#templates:GetChildren(), students)
	task.wait(0.1)
end
stageKids()
progress = 0.7
status.Text = "Sharpening pencils..."
-- the kids' clothes, hair and faces, so nobody pops in bald
do
	local list = {}
	for _, t in templates and templates:GetChildren() or {} do table.insert(list, t) end
	local done = 0
	local total = #list
	for k = 1, total, 10 do
		local chunk = {}
		for j = k, math.min(total, k + 9) do table.insert(chunk, list[j]) end
		pcall(function() ContentProvider:PreloadAsync(chunk) end)
		done = math.min(total, k + 9)
		progress = 0.7 + 0.28 * (done / math.max(1, total))
		status.Text = ("Handing out uniforms... %d%%"):format(math.floor(progress * 100))
		if os.clock() - t0 > 30 then break end
	end
end
-- (never faster than a moment: a flash of a loading screen looks broken)
while os.clock() - t0 < 2.5 do task.wait(0.1) end
progress = 1
status.Text = "Ready!"
task.wait(0.4)

---------------------------------------------------------------------------
-- how are you playing?
---------------------------------------------------------------------------
local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local choice = player:GetAttribute("Device") or (touchOnly and "mobile" or "pc")

TweenService:Create(barBack, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
for _, o in { barBack, status, tip } do o.Visible = false end

local ask = label(bottom, { Text = "HOW ARE YOU PLAYING?", Font = BIG, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, -6), ZIndex = 4 })
textStroke(ask, 4)
local cards = {}
local function card(key, icon, name, sub, x)
	local b = new("TextButton", {
		Name = key, Text = "", AutoButtonColor = false,
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, x, 0, 44), Size = UDim2.fromOffset(250, 128),
		BackgroundColor3 = WHITE, ZIndex = 4,
	}, bottom)
	corner(b, 22)
	local st = stroke(b, 5)
	label(b, { Text = icon, Size = UDim2.fromOffset(70, 70), Position = UDim2.fromOffset(18, 29), ZIndex = 5 })
	local n = label(b, { Text = name, Font = BIG, TextColor3 = INK, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(150, 38), Position = UDim2.fromOffset(94, 30), ZIndex = 5 })
	label(b, { Text = sub, TextColor3 = Color3.fromRGB(90, 96, 130), TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(150, 26), Position = UDim2.fromOffset(94, 70), ZIndex = 5 })
	local tick = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = GREEN, ZIndex = 6, Visible = false }, b)
	corner(tick, 20)
	stroke(tick, 4)
	label(tick, { Text = "\u{2714}", Font = BIG, Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.5, 0.52), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 7 })
	local sc = new("UIScale", {}, b)
	cards[key] = { button = b, stroke = st, tick = tick, scale = sc, name = n }
	b.MouseEnter:Connect(function() TweenService:Create(sc, TweenInfo.new(0.12), { Scale = 1.05 }):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(sc, TweenInfo.new(0.12), { Scale = 1 }):Play() end)
	return b
end
local function select(key)
	choice = key
	for k, c in cards do
		local on = k == key
		c.tick.Visible = on
		c.stroke.Color = on and Color3.fromRGB(40, 176, 80) or INK
		c.stroke.Thickness = on and 7 or 5
		c.button.BackgroundColor3 = on and Color3.fromRGB(236, 255, 240) or WHITE
	end
	TweenService:Create(cards[key].scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1.08 }):Play()
	task.delay(0.25, function()
		if cards[key] then TweenService:Create(cards[key].scale, TweenInfo.new(0.2), { Scale = 1 }):Play() end
	end)
end
card("pc", "\u{1F4BB}", "COMPUTER", "Keyboard & mouse", -290).Activated:Connect(function() select("pc") end)
card("mobile", "\u{1F4F1}", "PHONE", "Tablet & touch", 0).Activated:Connect(function() select("mobile") end)

local play = new("TextButton", {
	Name = "Play", Text = "", AutoButtonColor = false,
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 290, 0, 44), Size = UDim2.fromOffset(250, 128),
	BackgroundColor3 = WHITE, ZIndex = 4,
}, bottom)
corner(play, 22)
stroke(play, 5)
grad(play, Color3.fromRGB(130, 240, 140), Color3.fromRGB(34, 164, 72))
local playLabel = label(play, { Text = "PLAY!", Font = BIG, Size = UDim2.new(1, -30, 0, 70), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 5 })
textStroke(playLabel, 5)
local playScale = new("UIScale", {}, play)
select(choice)
-- the PLAY button breathes
task.spawn(function()
	while play.Parent do
		TweenService:Create(playScale, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { Scale = 1.06 }):Play()
		task.wait(0.6)
		TweenService:Create(playScale, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { Scale = 1 }):Play()
		task.wait(0.6)
	end
end)
-- a returning player's saved choice arrives with their profile
player:GetAttributeChangedSignal("Device"):Connect(function()
	local d = player:GetAttribute("Device")
	if d and cards[d] and not gui:GetAttribute("Chosen") then select(d) end
end)

local pressed = Instance.new("BindableEvent")
local coopOpen = false
local coopHost = false -- started a co-op school here: offer the friend invite once in the game
play.Activated:Connect(function() pressed:Fire() end)
UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and not coopOpen and (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA) then pressed:Fire() end
end)

---------------------------------------------------------------------------
-- co-op: run ONE school with up to three friends in this server, each with a role
---------------------------------------------------------------------------
local PURPLE = Color3.fromRGB(128, 72, 232)
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes", 20)
local actionRF = remotes and remotes:WaitForChild("Action", 20)
local function ask(...)
	if not actionRF then return { ok = false, err = "Not connected" } end
	local ok, res = pcall(actionRF.InvokeServer, actionRF, ...)
	if not ok or type(res) ~= "table" then return { ok = false, err = "Try again in a second" } end
	if res.err == "Not ready" then res.err = "Still opening your locker... try again in a second" end
	return res
end

local coopBtn = new("TextButton", {
	Name = "Coop", Text = "", AutoButtonColor = false,
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 186), Size = UDim2.fromOffset(830, 58),
	BackgroundColor3 = WHITE, ZIndex = 4,
}, bottom)
corner(coopBtn, 18)
stroke(coopBtn, 5)
grad(coopBtn, Color3.fromRGB(176, 128, 255), PURPLE)
local coopText = label(coopBtn, { Text = "\u{1F465}  CO-OP: RUN ONE SCHOOL WITH FRIENDS (UP TO 4)", Font = BIG, Size = UDim2.new(1, -40, 0, 34), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 5 })
textStroke(coopText, 3)
local coopScale = new("UIScale", {}, coopBtn)
coopBtn.MouseEnter:Connect(function() TweenService:Create(coopScale, TweenInfo.new(0.12), { Scale = 1.03 }):Play() end)
coopBtn.MouseLeave:Connect(function() TweenService:Create(coopScale, TweenInfo.new(0.12), { Scale = 1 }):Play() end)

local panel = new("Frame", {
	Name = "CoopPanel", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 282), Size = UDim2.fromOffset(1120, 690),
	BackgroundColor3 = Color3.fromRGB(250, 248, 255), Visible = false, ZIndex = 10,
}, root)
corner(panel, 28)
stroke(panel, 6)
local head = new("Frame", { Size = UDim2.new(1, 0, 0, 76), BackgroundColor3 = WHITE, ZIndex = 11 }, panel)
corner(head, 28)
grad(head, Color3.fromRGB(176, 128, 255), PURPLE)
new("Frame", { Position = UDim2.new(0, 0, 1, -28), Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = PURPLE, BorderSizePixel = 0, ZIndex = 11 }, head)
local headTitle = label(head, { Text = "\u{1F465} CO-OP SCHOOL", Font = BIG, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(520, 46), Position = UDim2.fromOffset(26, 16), ZIndex = 12 })
textStroke(headTitle, 4)
local headSub = label(head, { Text = "Up to 4 principals, ONE school. Everyone earns together.", TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(540, 28), Position = UDim2.new(1, -566, 0, 26), ZIndex = 12 })
textStroke(headSub, 2)

local function step(n, text, y)
	local badge = new("Frame", { Position = UDim2.fromOffset(24, y), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = PURPLE, ZIndex = 11 }, panel)
	corner(badge, 20)
	stroke(badge, 3)
	local bn = label(badge, { Text = tostring(n), Font = BIG, Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.5, 0.54), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 12 })
	textStroke(bn, 2)
	label(panel, { Text = text, Font = BIG, TextColor3 = INK, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(600, 34), Position = UDim2.fromOffset(74, y + 3), ZIndex = 11 })
end
step(1, "PICK YOUR ROLE", 90)
label(panel, { Text = "Perks work with 2+ players. Any number can pick the same role!", TextColor3 = Color3.fromRGB(110, 100, 150), TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.fromOffset(520, 24), Position = UDim2.new(1, -546, 0, 100), ZIndex = 11 })

local role = "President"
local roleCards = {}
local function pickRole(id)
	role = id
	for rid, c in roleCards do
		local on = rid == id
		c.stroke.Color = on and c.color or INK
		c.stroke.Thickness = on and 7 or 4
		c.button.BackgroundColor3 = on and c.color:Lerp(WHITE, 0.82) or WHITE
		c.tick.Visible = on
	end
end
for i, r in Config.Roles do
	local b = new("TextButton", {
		Name = r.id, Text = "", AutoButtonColor = false,
		Position = UDim2.fromOffset(24 + (i - 1) * 272, 138), Size = UDim2.fromOffset(256, 178),
		BackgroundColor3 = WHITE, ZIndex = 11,
	}, panel)
	corner(b, 20)
	local st = stroke(b, 4)
	local band = new("Frame", { Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = r.color, BorderSizePixel = 0, ZIndex = 12 }, b)
	corner(band, 20)
	label(b, { Text = r.icon, Size = UDim2.fromOffset(58, 58), Position = UDim2.new(0.5, 0, 0, 16), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 12 })
	local nm = label(b, { Text = r.name:upper(), Font = BIG, TextColor3 = r.color:Lerp(INK, 0.35), Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0.5, 0, 0, 78), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 12 })
	textStroke(nm, 1.5, INK)
	local perk = label(b, { Text = r.perk, TextColor3 = Color3.fromRGB(70, 70, 100), TextScaled = false, TextSize = 19, TextWrapped = true, Size = UDim2.new(1, -24, 0, 62), Position = UDim2.new(0.5, 0, 0, 110), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 12 })
	perk.TextYAlignment = Enum.TextYAlignment.Top
	local tick = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = GREEN, ZIndex = 14, Visible = false }, b)
	corner(tick, 18)
	stroke(tick, 3)
	label(tick, { Text = "\u{2714}", Font = BIG, Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.5, 0.52), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 15 })
	roleCards[r.id] = { button = b, stroke = st, tick = tick, color = r.color }
	b.Activated:Connect(function() pickRole(r.id) end)
end
pickRole(role)

step(2, "START ONE, OR JOIN ONE", 334)
local startBtn = new("TextButton", {
	Name = "Start", Text = "", AutoButtonColor = false,
	Position = UDim2.fromOffset(24, 384), Size = UDim2.fromOffset(440, 214), BackgroundColor3 = WHITE, ZIndex = 11,
}, panel)
corner(startBtn, 22)
stroke(startBtn, 5)
grad(startBtn, Color3.fromRGB(130, 240, 140), Color3.fromRGB(34, 164, 72))
label(startBtn, { Text = "\u{1F3EB}", Size = UDim2.fromOffset(64, 64), Position = UDim2.new(0.5, 0, 0, 16), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 12 })
local startTitle = label(startBtn, { Text = "START A CO-OP SCHOOL", Font = BIG, Size = UDim2.new(1, -30, 0, 40), Position = UDim2.new(0.5, 0, 0, 86), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 12 })
textStroke(startTitle, 4)
local startSub = label(startBtn, { Text = "Your school. Friends in this server join YOU.", TextScaled = false, TextSize = 21, TextWrapped = true, Size = UDim2.new(1, -40, 0, 56), Position = UDim2.new(0.5, 0, 0, 134), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 12 })
textStroke(startSub, 2)

local listBox = new("Frame", { Position = UDim2.fromOffset(484, 384), Size = UDim2.fromOffset(612, 214), BackgroundColor3 = Color3.fromRGB(236, 232, 250), ZIndex = 11 }, panel)
corner(listBox, 22)
stroke(listBox, 4)
label(listBox, { Text = "SCHOOLS IN THIS SERVER TAKING PLAYERS", Font = BIG, TextColor3 = PURPLE, Size = UDim2.new(1, -30, 0, 26), Position = UDim2.fromOffset(15, 10), ZIndex = 12 })
local list = new("ScrollingFrame", {
	Position = UDim2.fromOffset(12, 44), Size = UDim2.new(1, -24, 1, -54), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 8, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 12,
}, listBox)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)
local empty = label(listBox, { Text = "No co-op schools here yet.\nStart one, then invite your friends!", TextColor3 = Color3.fromRGB(120, 110, 160), TextScaled = false, TextSize = 24, Size = UDim2.new(1, -40, 0, 70), Position = UDim2.new(0.5, 0, 0.5, 18), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 12 })

local back = new("TextButton", { Name = "Back", Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(24, 614), Size = UDim2.fromOffset(180, 56), BackgroundColor3 = WHITE, ZIndex = 11 }, panel)
corner(back, 18)
stroke(back, 4)
label(back, { Text = "\u{25C0} BACK", Font = BIG, TextColor3 = INK, Size = UDim2.new(1, -30, 0, 30), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 12 })
local coopStatus = label(panel, { Text = "", TextColor3 = RED, TextXAlignment = Enum.TextXAlignment.Left, TextScaled = false, TextSize = 24, Size = UDim2.fromOffset(870, 56), Position = UDim2.fromOffset(222, 614), ZIndex = 11 })

local working = false
local function joined(asHost)
	coopHost = asHost
	coopOpen = false
	panel.Visible = false
	pressed:Fire()
end

local function row(entry, order)
	local r = new("Frame", { Size = UDim2.new(1, -10, 0, 66), BackgroundColor3 = WHITE, LayoutOrder = order, ZIndex = 13 }, list)
	corner(r, 14)
	stroke(r, 3)
	label(r, { Text = entry.school, Font = BIG, TextColor3 = INK, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -160, 0, 28), Position = UDim2.fromOffset(14, 7), ZIndex = 14 })
	local icons = ""
	for _, rid in entry.roles or {} do
		local rr = Config.RoleById[rid]
		if rr then icons ..= rr.icon end
	end
	label(r, { Text = ("%s's school  \u{2022}  %d/%d  %s"):format(entry.hostName, entry.size, entry.max, icons), TextColor3 = Color3.fromRGB(100, 96, 140), TextXAlignment = Enum.TextXAlignment.Left, TextScaled = false, TextSize = 19, Size = UDim2.new(1, -160, 0, 22), Position = UDim2.fromOffset(14, 38), ZIndex = 14 })
	local full = entry.size >= entry.max
	local j = new("TextButton", { Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(130, 48), BackgroundColor3 = WHITE, ZIndex = 14 }, r)
	corner(j, 14)
	stroke(j, 3)
	grad(j, full and Color3.fromRGB(200, 200, 210) or Color3.fromRGB(130, 240, 140), full and Color3.fromRGB(150, 150, 165) or Color3.fromRGB(34, 164, 72))
	local jl = label(j, { Text = full and "FULL" or "JOIN", Font = BIG, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 15 })
	textStroke(jl, 2)
	j.Activated:Connect(function()
		if full or working then return end
		working = true
		coopStatus.TextColor3 = INK
		coopStatus.Text = "Walking over to " .. entry.school .. "..."
		local res = ask("crewJoin", entry.host, role)
		working = false
		if res.ok then
			joined(false)
		else
			coopStatus.TextColor3 = RED
			coopStatus.Text = res.err or "Couldn't join"
		end
	end)
end

local function refreshList()
	local res = ask("crewList")
	if not coopOpen then return end
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then c:Destroy() end
	end
	local entries = res.ok and res.list or {}
	empty.Visible = #entries == 0
	for i, e in entries do row(e, i) end
end

startBtn.Activated:Connect(function()
	if working then return end
	working = true
	coopStatus.TextColor3 = INK
	coopStatus.Text = "Unlocking the doors for your friends..."
	local res = ask("crewCreate", role)
	working = false
	if res.ok then
		joined(true)
	else
		coopStatus.TextColor3 = RED
		coopStatus.Text = res.err or "Couldn't start it"
	end
end)

local function showCoop(on)
	coopOpen = on
	panel.Visible = on
	stage.Visible = not on
	bottom.Visible = not on
	coopStatus.Text = ""
	if on then
		panel.Position = UDim2.new(0.5, 0, 0, 320)
		TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, 282) }):Play()
		task.spawn(function()
			while coopOpen and gui.Parent do
				refreshList()
				task.wait(2)
			end
		end)
	end
end
coopBtn.Activated:Connect(function() showCoop(true) end)
back.Activated:Connect(function() showCoop(false) end)

pressed.Event:Wait()
gui:SetAttribute("Chosen", true)

-- tell the server: the device (remembered) and that we're ready to play
player:SetAttribute("Device", choice)
task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 20)
	local action = remotes and remotes:WaitForChild("Action", 20)
	if action then
		pcall(action.InvokeServer, action, "setting", "device", choice)
		pcall(action.InvokeServer, action, "clientReady")
	end
end)

---------------------------------------------------------------------------
-- into the game
---------------------------------------------------------------------------
local out = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
TweenService:Create(logo, out, { Position = UDim2.new(0.5, 0, 0, -300) }):Play()
TweenService:Create(bottom, out, { Position = UDim2.new(0.5, 0, 1, 300) }):Play()
TweenService:Create(stage, out, { ImageTransparency = 1 }):Play()
task.wait(0.3)
for _, d in doodles do TweenService:Create(d.label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play() end
TweenService:Create(sky, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
task.wait(0.55)
conn:Disconnect()
gui:Destroy()
coreGui(true)

-- a brand-new co-op school: bring friends in (Roblox's own invite window)
if coopHost then
	task.wait(2)
	pcall(function() game:GetService("SocialService"):PromptGameInvite(player) end)
end
