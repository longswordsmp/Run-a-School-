-- StarterPlayer.StarterPlayerScripts.HQ
-- VexCorp HQ on the client (Server/HQService):
--   the elevator panel  a brass-and-steel button panel, one button per floor (lit = open, a lock
--                       and the reason = not yet, a check = cleared); pick one and ride (hqGo)
--   the floor banner    FLOOR 2 / THE CUBICLE FARM when you step out, then a small objective card at
--                       the top while you're on the floor (it follows HQKeycard)
--   messages            ACCESS DENIED, KEYCARD FOUND..., FLOOR CLEARED!
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = require(Shared:WaitForChild("UI"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")
local bus = ReplicatedStorage:WaitForChild("ClientBus", 10)

local player = Players.LocalPlayer
local gui = UI.new("ScreenGui", { Name = "HQ", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 40, Parent = player:WaitForChild("PlayerGui") })
local root = UI.autoScale(gui)

local STEEL = Color3.fromRGB(58, 60, 72)
local BRASS = Color3.fromRGB(214, 176, 92)
local TOXIC = Color3.fromRGB(120, 255, 60)
local RED = Color3.fromRGB(255, 80, 80)

local function sfx(name)
	local e = bus and bus:FindFirstChild("Sfx")
	if e then e:Fire(name) end
end

-- what to do on each floor (the objective card)
local OBJECTIVES = {
	[2] = { "Find the keycard in one of the three managers' offices (east side).", "\u{1F4B3} You have the keycard! Get to the SECURITY DOOR on the north wall." },
	[3] = { "Hit the three switches in the right order to open the vault." },
	[4] = { "Hack the three terminals without the cameras seeing you." },
	[5] = { "Free the kids from the pods and grab the mutation sample." },
	[6] = { "Survive the goon waves. Then face Crumpet." },
	[7] = { "Find the three code digits and open Dr. Vex's vault." },
}

---------------------------------------------------------------------------
-- the elevator panel
---------------------------------------------------------------------------
local panel = UI.new("Frame", {
	Name = "ElevatorPanel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(440, 560),
	BackgroundColor3 = STEEL,
	Visible = false,
	ZIndex = 10,
	Parent = root,
})
UI.corner(panel, 18)
UI.stroke(panel, 5, BRASS)
UI.gradient(panel, Color3.fromRGB(96, 98, 112), Color3.fromRGB(44, 46, 56))
-- brushed-metal lines
for i = 1, 26 do
	UI.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.94, BorderSizePixel = 0, Size = UDim2.new(1, -20, 0, 1), Position = UDim2.fromOffset(10, 8 + i * 21), ZIndex = 10, Parent = panel })
end
local head = UI.new("Frame", { Size = UDim2.new(1, -24, 0, 64), Position = UDim2.fromOffset(12, 12), BackgroundColor3 = Color3.fromRGB(16, 14, 22), ZIndex = 11, Parent = panel })
UI.corner(head, 10)
UI.stroke(head, 3, BRASS)
local display = UI.label(head, { Text = "L", Font = Enum.Font.Arcade, TextColor3 = RED, Size = UDim2.new(0, 90, 1, -12), Position = UDim2.fromOffset(12, 6), ZIndex = 12, stroke = 0 })
UI.label(head, { Text = "VEXCORP HQ", Font = UI.BIG, TextColor3 = TOXIC, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(1, -120, 0, 30), Position = UDim2.fromOffset(104, 6), ZIndex = 12, stroke = 0 })
local sub = UI.label(head, { Text = "SELECT A FLOOR", Font = Enum.Font.Arcade, TextColor3 = Color3.fromRGB(200, 200, 210), TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(1, -120, 0, 18), Position = UDim2.fromOffset(104, 38), ZIndex = 12, stroke = 0 })
local list = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -24, 1, -150), Position = UDim2.fromOffset(12, 88), ZIndex = 11, Parent = panel })
UI.new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
local closeBtn = UI.button(panel, { text = "CLOSE", color = RED, size = UDim2.fromOffset(160, 44), position = UDim2.new(0.5, 0, 1, -12), anchor = Vector2.new(0.5, 1), font = UI.BIG, onClick = function()
	panel.Visible = false
end })
closeBtn.button.ZIndex = 12
for _, d in closeBtn.button:GetDescendants() do if d:IsA("GuiObject") then d.ZIndex = 13 end end

local function floorButton(f, here)
	local open, current = f.open, f.n == here
	local b = UI.new("TextButton", {
		Name = "Floor" .. f.n,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 52),
		LayoutOrder = 10 - f.n,
		BackgroundColor3 = Color3.fromRGB(30, 30, 38),
		ZIndex = 11,
		Parent = list,
	})
	UI.corner(b, 12)
	UI.stroke(b, 2.5, current and TOXIC or Color3.fromRGB(20, 20, 26))
	-- the round button
	local knob = UI.new("Frame", { Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = open and BRASS or Color3.fromRGB(90, 90, 96), ZIndex = 12, Parent = b })
	UI.corner(knob, 20)
	UI.stroke(knob, 2.5, Color3.fromRGB(20, 20, 26))
	UI.gradient(knob, open and Color3.fromRGB(255, 230, 160) or Color3.fromRGB(150, 150, 156), open and BRASS or Color3.fromRGB(80, 80, 86))
	UI.label(knob, { Text = f.n == 1 and "L" or tostring(f.n), Font = UI.BIG, TextColor3 = open and Color3.fromRGB(60, 40, 10) or Color3.fromRGB(50, 50, 56), Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 13, stroke = 0 })
	UI.label(b, { Text = f.name, Font = UI.BIG, TextColor3 = open and Color3.new(1, 1, 1) or Color3.fromRGB(130, 130, 140), TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -110, 0, 24), Position = UDim2.fromOffset(56, open and 13 or 5), ZIndex = 12, stroke = 2 })
	if not open then
		UI.label(b, { Text = "\u{1F512} " .. (f.why or "Locked"), TextColor3 = Color3.fromRGB(255, 150, 150), TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -110, 0, 16), Position = UDim2.fromOffset(56, 30), ZIndex = 12, stroke = 0 })
	end
	local tag = f.cleared and "\u{2714}" or current and "YOU" or ""
	UI.label(b, { Text = tag, Font = UI.BIG, TextColor3 = f.cleared and TOXIC or Color3.fromRGB(255, 220, 120), Size = UDim2.new(0, 48, 0, 26), Position = UDim2.new(1, -54, 0, 13), ZIndex = 12, stroke = 2 })
	b.MouseEnter:Connect(function() if open then TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(48, 50, 62) }):Play() end end)
	b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(30, 30, 38) }):Play() end)
	b.Activated:Connect(function()
		if not open then
			sfx("Error")
			UI.punch(b, 1.04)
			return
		end
		if current then
			panel.Visible = false
			return
		end
		sfx("Ding")
		UI.punch(knob, 1.25)
		display.Text = f.n == 1 and "L" or tostring(f.n)
		task.delay(0.15, function() panel.Visible = false end)
		pcall(Action.InvokeServer, Action, "hqGo", f.n)
	end)
end

local function openPanel(data)
	for _, c in list:GetChildren() do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	local here = player:GetAttribute("HQFloor") or 1
	display.Text = here == 1 and "L" or tostring(here)
	sub.Text = "SELECT A FLOOR"
	for _, f in data.floors do floorButton(f, here) end
	panel.Visible = true
	UI.pop(panel, 0.6)
	sfx("Ding")
end
UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and panel.Visible and input.KeyCode == Enum.KeyCode.Escape then panel.Visible = false end
end)

---------------------------------------------------------------------------
-- the floor banner and the objective card
---------------------------------------------------------------------------
local card = UI.new("Frame", {
	Name = "Objective",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 70),
	Size = UDim2.fromOffset(560, 64),
	BackgroundColor3 = Color3.fromRGB(24, 20, 34),
	Visible = false,
	Parent = root,
})
UI.corner(card, 14)
UI.stroke(card, 3, TOXIC)
local cardTitle = UI.label(card, { Text = "", Font = UI.BIG, TextColor3 = TOXIC, Size = UDim2.new(1, -24, 0, 24), Position = UDim2.fromOffset(12, 5), stroke = 2 })
local cardText = UI.label(card, { Text = "", TextColor3 = Color3.new(1, 1, 1), TextScaled = false, TextSize = 18, TextWrapped = true, Size = UDim2.new(1, -24, 0, 26), Position = UDim2.fromOffset(12, 32), stroke = 1.5 })

local clearedFloors = {} -- (from hqArrive / hqCleared)
local function refreshCard()
	local n = player:GetAttribute("HQFloor")
	local obj = n and OBJECTIVES[n]
	if not obj then
		card.Visible = false
		return
	end
	card.Visible = true
	cardTitle.Text = ("FLOOR %d"):format(n) .. (clearedFloors[n] and "  \u{2714} CLEARED" or "")
	if clearedFloors[n] and not player:GetAttribute("HQKeycard") then
		cardText.Text = n < 7 and "Floor cleared! Take an elevator UP to the next floor." or "The whole tower is yours. The Lair is next!"
	else
		cardText.Text = (player:GetAttribute("HQKeycard") and obj[2]) or obj[1]
	end
end
player:GetAttributeChangedSignal("HQFloor"):Connect(refreshCard)
player:GetAttributeChangedSignal("HQKeycard"):Connect(function()
	refreshCard()
	if player:GetAttribute("HQKeycard") then UI.punch(card, 1.1) end
end)

local function banner(top, big, color)
	local holder = UI.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(900, 160), ZIndex = 30, Parent = root })
	local a = UI.label(holder, { Text = top, Font = Enum.Font.Arcade, TextColor3 = Color3.fromRGB(230, 230, 240), Size = UDim2.new(1, 0, 0, 36), ZIndex = 30, stroke = 3 })
	local b = UI.label(holder, { Text = big, Font = UI.BIG, TextColor3 = color, Size = UDim2.new(1, 0, 0, 86), Position = UDim2.fromOffset(0, 44), ZIndex = 30, stroke = 5 })
	UI.pop(holder, 1.8)
	task.delay(2.8, function()
		for _, l in { a, b } do
			TweenService:Create(l, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
			TweenService:Create(l:FindFirstChildOfClass("UIStroke"), TweenInfo.new(0.5), { Transparency = 1 }):Play()
		end
		task.wait(0.55)
		holder:Destroy()
	end)
end

-- messages stack down from under the objective card and slide up as older ones go
local live = {}
local function restack()
	for i, m in live do
		TweenService:Create(m, TweenInfo.new(0.2), { Position = UDim2.new(0.5, 0, 0, 146 + (i - 1) * 52) }):Play()
	end
end
local function message(text, kind)
	local color = kind == "bad" and RED or kind == "good" and TOXIC or Color3.fromRGB(255, 240, 200)
	local m = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 146 + #live * 52), Size = UDim2.fromOffset(640, 46), BackgroundColor3 = Color3.fromRGB(24, 20, 34), ZIndex = 25, Parent = root })
	table.insert(live, m)
	if #live > 3 then
		local old = table.remove(live, 1)
		old:Destroy()
		restack()
	end
	UI.corner(m, 12)
	UI.stroke(m, 3, color)
	UI.label(m, { Text = text, TextColor3 = color, TextScaled = false, TextSize = 19, TextWrapped = true, Size = UDim2.new(1, -20, 1, -8), Position = UDim2.fromOffset(10, 4), ZIndex = 26, stroke = 1.5 })
	UI.pop(m, 0.7)
	if kind == "bad" then sfx("Error") end
	task.delay(3.4, function()
		if not m.Parent then return end
		for i, x in live do
			if x == m then table.remove(live, i) break end
		end
		for _, d in m:GetDescendants() do
			if d:IsA("TextLabel") then TweenService:Create(d, TweenInfo.new(0.3), { TextTransparency = 1 }):Play() end
		end
		TweenService:Create(m, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		task.wait(0.3)
		m:Destroy()
		restack()
	end)
end

---------------------------------------------------------------------------
-- the Laser Vault's lasers (floor 3): animated here from the server clock (Shared/HQLasers);
-- the server checks the hits with the same maths
---------------------------------------------------------------------------
local RunService = game:GetService("RunService")
local HQLasers = require(Shared:WaitForChild("HQLasers"))
local laserParts -- { part, base }
local HOT = Color3.fromRGB(255, 50, 40)
local WARM = Color3.fromRGB(150, 60, 30)
local COLD = Color3.fromRGB(40, 38, 50)
local function findLasers()
	local town = workspace:FindFirstChild("Town")
	local f = town and town:FindFirstChild("VexCorpHQ")
	f = f and f:FindFirstChild("Floor3")
	f = f and f:FindFirstChild("Lasers")
	if not f then return nil end
	local list = {}
	for _, p in f:GetChildren() do
		if p:IsA("BasePart") then table.insert(list, { part = p, base = p.CFrame }) end
	end
	return #list > 0 and list or nil
end
---------------------------------------------------------------------------
-- Mutagen Labs (floor 5): the bridges fade in and out (solid only while lit, for this player's
-- own physics); they flash orange just before they go
---------------------------------------------------------------------------
local bridgeParts
local function findBridges()
	local town = workspace:FindFirstChild("Town")
	local f = town and town:FindFirstChild("VexCorpHQ")
	f = f and f:FindFirstChild("Floor5")
	f = f and f:FindFirstChild("Bridges")
	if not f then return nil end
	local list = {}
	for _, p in f:GetChildren() do
		if p:IsA("BasePart") then table.insert(list, p) end
	end
	return #list > 0 and list or nil
end
local BRIDGE = Color3.fromRGB(120, 230, 255)
local WARN = Color3.fromRGB(255, 160, 60)
RunService.RenderStepped:Connect(function()
	if player:GetAttribute("HQFloor") ~= 5 then return end
	bridgeParts = bridgeParts or findBridges()
	if not bridgeParts then return end
	local t = workspace:GetServerTimeNow()
	for _, p in bridgeParts do
		if not p.Parent then bridgeParts = nil return end
		local on = HQLasers.isOn(p, t)
		p.CanCollide = on
		if on then
			local soon = not HQLasers.isOn(p, t + 0.7)
			p.Transparency = 0.2
			p.Color = soon and ((math.floor(t * 8) % 2 == 0) and WARN or BRIDGE) or BRIDGE
		else
			p.Transparency = 0.88
			p.Color = BRIDGE
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if player:GetAttribute("HQFloor") ~= 3 then return end
	laserParts = laserParts or findLasers()
	if not laserParts then return end
	local t = workspace:GetServerTimeNow()
	for _, l in laserParts do
		local p = l.part
		if not p.Parent then laserParts = nil return end
		local kind = p:GetAttribute("Laser")
		if kind == "blink" then
			p.Transparency = HQLasers.isOn(p, t) and 0 or 0.88
		elseif kind == "tile" then
			if HQLasers.isOn(p, t) then
				p.Color, p.Material = HOT, Enum.Material.Neon
			elseif HQLasers.isOn(p, t + 0.5) then
				p.Color, p.Material = WARM, Enum.Material.Neon -- (about to heat up)
			else
				p.Color, p.Material = COLD, Enum.Material.SmoothPlastic
			end
		elseif kind == "spin" then
			p.CFrame = HQLasers.spinCF(p, l.base, t)
		end
	end
end)

---------------------------------------------------------------------------
-- the Server Farm (floor 4): the cameras turn (Shared/HQCams, the same clock as the server's eyes)
-- and the rack LEDs twinkle
---------------------------------------------------------------------------
local HQCams = require(Shared:WaitForChild("HQCams"))
local camHeads, leds
local function findFloor4()
	local town = workspace:FindFirstChild("Town")
	local f = town and town:FindFirstChild("VexCorpHQ")
	f = f and f:FindFirstChild("Floor4")
	if not f then return end
	camHeads, leds = {}, {}
	for _, d in f:GetDescendants() do
		if d:IsA("BasePart") then
			if d:GetAttribute("Cam") then table.insert(camHeads, { part = d, pos = d.Position }) end
			if d:GetAttribute("HQLed") then table.insert(leds, { part = d, color = d.Color }) end
		end
	end
end
local ledClock = 0
RunService.RenderStepped:Connect(function(dt)
	if player:GetAttribute("HQFloor") ~= 4 then return end
	if not camHeads or #camHeads == 0 then findFloor4() end
	if not camHeads then return end
	local t = workspace:GetServerTimeNow()
	for _, c in camHeads do
		if c.part.Parent then c.part.CFrame = HQCams.cf(c.pos, c.part, t) end
	end
	ledClock += dt
	if ledClock > 0.25 then
		ledClock = 0
		for _ = 1, 24 do
			local l = leds[math.random(#leds)]
			if l and l.part.Parent then
				l.part.Color = l.part.Color == l.color and Color3.fromRGB(20, 22, 28) or l.color
			end
		end
	end
end)

-- a zap: a red flash
local flash = UI.new("Frame", { BackgroundColor3 = RED, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 50, Parent = gui })

Remotes:WaitForChild("Push").OnClientEvent:Connect(function(kind, data)
	if kind == "hqSpotted" then
		flash.BackgroundTransparency = 0.35
		TweenService:Create(flash, TweenInfo.new(0.9), { BackgroundTransparency = 1 }):Play()
		banner("\u{1F4F7} SPOTTED!", "SECURITY IS ON ITS WAY", RED)
	elseif kind == "hqZap" then
		flash.BackgroundTransparency = 0.25
		TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
		message(data.floor == 5 and "\u{2622} SPLASH! The acid sends you back to the lobby." or "\u{26A1} ZAPPED! Back to the start of this section.", "bad")
	elseif kind == "hqElevator" then
		openPanel(data)
	elseif kind == "elevator" then
		panel.Visible = false
	elseif kind == "hqArrive" then
		panel.Visible = false
		clearedFloors[data.floor] = data.cleared or nil
		task.delay(1.2, function()
			banner(("FLOOR %d"):format(data.floor), data.name, data.cleared and TOXIC or Color3.fromRGB(205, 150, 255))
			refreshCard()
		end)
	elseif kind == "hqMsg" then
		message(data.text, data.kind)
	elseif kind == "hqCleared" then
		clearedFloors[data.floor] = true
		refreshCard()
		banner(("FLOOR %d CLEARED!"):format(data.floor), data.next and ("NEXT: " .. data.next) or "THE EXECUTIVE KEYCARD IS YOURS", TOXIC)
	end
end)
