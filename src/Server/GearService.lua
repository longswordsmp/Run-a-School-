-- ServerScriptService.Server.GearService
-- Heist Gear (Config.Gear): Janitor Stan's stall outside his Confiscation Closet (and the Shop's Gear
-- tab). Bought with cash, priced in seconds of your school's tuition.
--   perks   Silent Sneakers, Running Shoes, Lockpick Set: player attributes the systems read
--   tools   Cardboard Box: equip it and stand still to be invisible to guards (attribute Boxed)
--   uses    Smoke Bomb, Whoopee Cushion, Energy Drink: backpack tools showing how many are left
-- What guards do about it lives with the guards (FactoryService; later the rival school): they
-- register in GearService.smokeHooks / noiseHooks.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)

local GearService = {}
GearService.smokeHooks = {} -- fn(player, position): guards near a smoke bomb lose the player
GearService.noiseHooks = {} -- fn(position): guards near a whoopee cushion come to look

local PERK_ATTR = { SilentSneakers = "SilentSneakers", RunningShoes = "RunningShoes", LockpickSet = "Lockpick" }

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

function GearService.price(player, def)
	local inc = player:GetAttribute("BaseIncome") or player:GetAttribute("IncomePerSec") or 0
	return math.max(def.floor, math.floor(inc * def.secs))
end

local function gearOf(p)
	p.gear = p.gear or { owned = { Ruler = true } }
	p.gear.owned = p.gear.owned or { Ruler = true }
	p.gear.uses = p.gear.uses or {}
	return p.gear
end

---------------------------------------------------------------------------
-- the tools in the backpack
---------------------------------------------------------------------------
local function toolName(def, n)
	if def.kind == "use" then return ("%s %s x%d"):format(def.icon, def.name, n) end
	return def.icon .. " " .. def.name
end

local function findTool(player, id)
	for _, c in { player:FindFirstChild("Backpack"), player.Character } do
		for _, t in c and c:GetChildren() or {} do
			if t:IsA("Tool") and t:GetAttribute("GearId") == id then return t end
		end
	end
	return nil
end

local function handle(tool, size, color, material)
	local h = Instance.new("Part")
	h.Name = "Handle"
	h.Size = size
	h.Color = color
	h.Material = material or Enum.Material.SmoothPlastic
	h.CanCollide = false
	h.CanQuery = false
	h.Massless = true
	h.Parent = tool
	return h
end

-- the cardboard box, worn over the whole player
local function wearBox(player, on)
	local char = player.Character
	if not char then return end
	local old = char:FindFirstChild("HidingBox")
	if old then old:Destroy() end
	player:SetAttribute("Boxed", on or nil)
	require(script.Parent.StealService).setSpeed(player)
	if not on then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local box = Instance.new("Model")
	box.Name = "HidingBox"
	local cardboard = rgb(186, 140, 90)
	local function p(name, size, cf, color)
		local b = Instance.new("Part")
		b.Name = name
		b.Size = size
		b.Color = color or cardboard
		b.Material = Enum.Material.Cardboard
		b.CanCollide = false
		b.CanQuery = false
		b.CanTouch = false
		b.Massless = true
		b.CFrame = root.CFrame * cf
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = root, b
		w.Parent = b
		b.Parent = box
		return b
	end
	-- a big box over the whole kid, flaps on top, a "FRAGILE" label and eye holes
	local y = -0.35
	p("Body", Vector3.new(3.6, 4.4, 3), CFrame.new(0, y, 0))
	p("FlapL", Vector3.new(1.8, 0.1, 3), CFrame.new(-1.4, y + 2.45, 0) * CFrame.Angles(0, 0, math.rad(35)))
	p("FlapR", Vector3.new(1.8, 0.1, 3), CFrame.new(1.4, y + 2.45, 0) * CFrame.Angles(0, 0, math.rad(-35)))
	p("Tape", Vector3.new(3.62, 0.3, 0.3), CFrame.new(0, y + 2.05, -1.36), rgb(210, 190, 150))
	local label = p("Label", Vector3.new(2, 0.7, 0.05), CFrame.new(0, y + 0.2, -1.53), rgb(230, 60, 60))
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.Parent = label
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.LuckiestGuy
	t.Text = "FRAGILE"
	t.TextColor3 = rgb(255, 255, 255)
	t.Parent = g
	for _, x in { -0.45, 0.45 } do
		p("EyeHole", Vector3.new(0.5, 0.22, 0.05), CFrame.new(x, y + 1.4, -1.53), rgb(20, 16, 12))
	end
	box.Parent = char
end

local function useGear(player, def, tool)
	local p = Data.get(player)
	if not p then return end
	local gear = gearOf(p)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if def.kind == "use" then
		if (gear.uses[def.id] or 0) <= 0 then return end
		gear.uses[def.id] -= 1
	end
	if def.id == "SmokeBomb" then
		local puff = Instance.new("Part")
		puff.Anchored, puff.CanCollide, puff.CanQuery, puff.CanTouch = true, false, false, false
		puff.Transparency = 1
		puff.Size = Vector3.one
		puff.Position = root.Position
		puff.Parent = workspace
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(rgb(235, 235, 245), rgb(170, 170, 185))
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(0.3, 12), NumberSequenceKeypoint.new(1, 16) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime = NumberRange.new(3, 4)
		e.Speed = NumberRange.new(5, 10)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Drag = 2.5
		e.Rate = 25
		e.LightInfluence = 0.4
		e.Parent = puff
		e:Emit(90)
		task.delay(1.5, function() e.Enabled = false end)
		Debris:AddItem(puff, 5)
		player:SetAttribute("SmokeUntil", workspace:GetServerTimeNow() + 3)
		Remotes.Sfx:FireAllClients("Error", root.Position)
		for _, hook in GearService.smokeHooks do task.spawn(hook, player, root.Position) end
		Remotes.Notify:FireClient(player, "\u{1F4A8} POOF! Now get out of here!", "good")
	elseif def.id == "WhoopeeCushion" then
		local at = root.Position + root.CFrame.LookVector * 3 - Vector3.new(0, 2.6, 0)
		local c = Instance.new("Part")
		c.Name = "WhoopeeCushion"
		c.Shape = Enum.PartType.Cylinder
		c.Size = Vector3.new(0.35, 2, 2)
		c.Color = rgb(235, 80, 140)
		c.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
		c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch = true, false, false, false
		c.Parent = workspace
		task.delay(2, function()
			if not c.Parent then return end
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.fromOffset(200, 60)
			bb.StudsOffset = Vector3.new(0, 3, 0)
			bb.AlwaysOnTop = true
			bb.Parent = c
			local t = Instance.new("TextLabel")
			t.Size = UDim2.fromScale(1, 1)
			t.BackgroundTransparency = 1
			t.TextScaled = true
			t.Font = Enum.Font.LuckiestGuy
			t.Text = "PFFFFRT!"
			t.TextColor3 = rgb(255, 150, 200)
			local s = Instance.new("UIStroke")
			s.Thickness = 3
			s.Parent = t
			t.Parent = bb
			Remotes.Sfx:FireAllClients("Error", c.Position)
			for _, hook in GearService.noiseHooks do task.spawn(hook, c.Position) end
			Debris:AddItem(c, 6)
		end)
	elseif def.id == "EnergyDrink" then
		player:SetAttribute("EnergyUntil", workspace:GetServerTimeNow() + 20)
		require(script.Parent.StealService).setSpeed(player)
		task.delay(20.1, function()
			if player.Parent then require(script.Parent.StealService).setSpeed(player) end
		end)
		Remotes.Notify:FireClient(player, "\u{26A1} ENERGY! 20 seconds of sprinting that never runs out", "good")
	end
	Signals.fire("gearUse", player, def.id)
	-- update the count on the tool (or take it away when it's the last one)
	if def.kind == "use" and tool then
		local n = gear.uses[def.id] or 0
		if n <= 0 then tool:Destroy() else tool.Name = toolName(def, n) end
	end
end

local function makeTool(player, def, n)
	local tool = Instance.new("Tool")
	tool.Name = toolName(def, n or 1)
	tool.ToolTip = def.desc
	tool.CanBeDropped = false
	tool:SetAttribute("GearId", def.id)
	if def.id == "CardboardBox" then
		tool.RequiresHandle = false
		tool.Equipped:Connect(function() wearBox(player, true) end)
		tool.Unequipped:Connect(function() wearBox(player, false) end)
	else
		local h
		if def.id == "SmokeBomb" then
			h = handle(tool, Vector3.new(0.9, 0.9, 0.9), rgb(60, 60, 70), Enum.Material.Metal)
			h.Shape = Enum.PartType.Ball
		elseif def.id == "WhoopeeCushion" then
			h = handle(tool, Vector3.new(0.3, 1.4, 1.4), rgb(235, 80, 140))
			h.Shape = Enum.PartType.Cylinder
		else
			h = handle(tool, Vector3.new(0.6, 1.1, 0.6), rgb(60, 200, 255), Enum.Material.Metal)
			h.Shape = Enum.PartType.Cylinder
			tool.Grip = CFrame.Angles(0, 0, math.rad(90))
		end
		tool.Activated:Connect(function()
			useGear(player, def, tool)
		end)
	end
	return tool
end

-- the player's gear tools, in step with what they own
function GearService.refreshTools(player)
	local p = Data.get(player)
	local backpack = player:FindFirstChild("Backpack")
	if not p or not backpack then return end
	local gear = gearOf(p)
	for _, def in Config.Gear do
		local n = def.kind == "use" and (gear.uses[def.id] or 0) or (gear.owned[def.id] and 1 or 0)
		local tool = findTool(player, def.id)
		if def.kind == "perk" then
			if PERK_ATTR[def.id] then player:SetAttribute(PERK_ATTR[def.id], gear.owned[def.id] or nil) end
		elseif n > 0 and not tool then
			makeTool(player, def, n).Parent = backpack
		elseif n > 0 and tool then
			tool.Name = toolName(def, n)
		elseif n <= 0 and tool then
			tool:Destroy()
		end
	end
end

---------------------------------------------------------------------------
-- buying
---------------------------------------------------------------------------
Actions.register("gearShop", function(player, p)
	local gear = gearOf(p)
	local items = {}
	for _, def in Config.Gear do
		table.insert(items, {
			id = def.id,
			price = GearService.price(player, def),
			owned = def.kind ~= "use" and gear.owned[def.id] == true or nil,
			count = def.kind == "use" and (gear.uses[def.id] or 0) or nil,
		})
	end
	return { ok = true, items = items, max = Config.GearUse.max }
end)

function GearService.give(player, id, n)
	local p = Data.get(player)
	local def = Config.GearById[id]
	if not p or not def then return false end
	local gear = gearOf(p)
	if def.kind == "use" then
		gear.uses[id] = math.min(Config.GearUse.max, (gear.uses[id] or 0) + (n or 1))
	else
		gear.owned[id] = true
	end
	GearService.refreshTools(player)
	return true
end

Actions.register("buyGear", function(player, p, id)
	local def = Config.GearById[id]
	if not def then return { ok = false, err = "Unknown gear" } end
	local gear = gearOf(p)
	if def.kind ~= "use" and gear.owned[id] then return { ok = false, err = "You already have it" } end
	if def.kind == "use" and (gear.uses[id] or 0) >= Config.GearUse.max then return { ok = false, err = "Your pockets are full" } end
	local price = GearService.price(player, def)
	if not Data.addCash(player, -price) then
		Remotes.Sfx:FireClient(player, "Error")
		return { ok = false, err = "Not enough cash" }
	end
	GearService.give(player, id, 1)
	Remotes.Sfx:FireClient(player, "Buy")
	Remotes.Announce:FireClient(player, (def.icon .. " " .. def.name):upper() .. "!", rgb(255, 170, 60))
	Signals.fire("gearBuy", player, def)
	return { ok = true }
end)

---------------------------------------------------------------------------
-- Stan's stall, outside the Closet
---------------------------------------------------------------------------
local function buildStall()
	local map = workspace:WaitForChild("Map", 30)
	if not map then return end
	local old = workspace:FindFirstChild("GearStall")
	if old then old:Destroy() end
	local m = Instance.new("Model")
	m.Name = "GearStall"
	-- beside the walkway up to the Closet (x -190, z -28..-62), facing the path
	local base = CFrame.new(-182.5, 0.5, -52) * CFrame.Angles(0, math.rad(90), 0)
	local function part(name, size, cf, color, material, shape)
		local b = Instance.new("Part")
		b.Name = name
		b.Size = size
		b.CFrame = base * cf
		b.Color = color
		b.Material = material or Enum.Material.SmoothPlastic
		b.Anchored = true
		b.TopSurface = Enum.SurfaceType.Smooth
		b.BottomSurface = Enum.SurfaceType.Smooth
		if shape then b.Shape = shape end
		b.Parent = m
		return b
	end
	local wood = rgb(120, 84, 56)
	-- a counter with a striped awning over it
	part("Counter", Vector3.new(8, 3.2, 2.4), CFrame.new(0, 1.6, 0), wood, Enum.Material.WoodPlanks)
	part("CounterTop", Vector3.new(8.4, 0.3, 2.8), CFrame.new(0, 3.35, 0), rgb(70, 50, 36), Enum.Material.Wood)
	for _, x in { -3.9, 3.9 } do
		part("Post", Vector3.new(0.4, 7.6, 0.4), CFrame.new(x, 3.8, 1.2), wood, Enum.Material.Wood)
	end
	for i = 0, 7 do
		part("Awning", Vector3.new(1.05, 0.2, 3.4), CFrame.new(-3.7 + i * 1.05, 7.7, 0.4) * CFrame.Angles(math.rad(-14), 0, 0), i % 2 == 0 and rgb(60, 60, 70) or rgb(240, 240, 245))
	end
	local sign = part("Sign", Vector3.new(6.4, 1.5, 0.3), CFrame.new(0, 8.9, -0.9), rgb(30, 30, 40))
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.Parent = sign
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.LuckiestGuy
	t.Text = "HEIST GEAR"
	t.TextColor3 = rgb(255, 200, 80)
	t.Parent = g
	-- the goods on the counter: a box, smoke bombs, a cushion, cans, sneakers, a lockpick roll
	part("DisplayBox", Vector3.new(1.6, 1.4, 1.4), CFrame.new(-3, 4.2, 0), rgb(186, 140, 90), Enum.Material.Cardboard)
	for i = 0, 2 do
		part("Bomb", Vector3.new(0.7, 0.7, 0.7), CFrame.new(-1.6 + i * 0.5, 3.85, 0.3 - (i % 2) * 0.5), rgb(60, 60, 70), Enum.Material.Metal, Enum.PartType.Ball)
	end
	part("Cushion", Vector3.new(0.3, 1.2, 1.2), CFrame.new(0.2, 3.65, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(235, 80, 140), nil, Enum.PartType.Cylinder)
	for i = 0, 2 do
		part("Can", Vector3.new(0.9, 0.5, 0.5), CFrame.new(1.4 + i * 0.55, 3.95, -0.2) * CFrame.Angles(0, 0, math.rad(90)), rgb(60, 200, 255), Enum.Material.Metal, Enum.PartType.Cylinder)
	end
	part("Sneaker", Vector3.new(0.7, 0.5, 1.3), CFrame.new(3.3, 3.75, 0.2), rgb(240, 240, 250))
	part("SneakerSole", Vector3.new(0.72, 0.15, 1.32), CFrame.new(3.3, 3.55, 0.2), rgb(80, 180, 255))
	local lamp = part("Lamp", Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, 7.2, 0.4), rgb(255, 240, 200), Enum.Material.Neon, Enum.PartType.Ball)
	local l = Instance.new("PointLight")
	l.Range = 14
	l.Brightness = 1.4
	l.Color = rgb(255, 230, 190)
	l.Parent = lamp
	-- the prompt: open the Shop on the Gear tab
	local spot = part("PromptSpot", Vector3.new(1, 1, 1), CFrame.new(0, 3, 1.8), wood)
	spot.Transparency = 1
	spot.CanCollide = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy Gear"
	prompt.ObjectText = "Janitor Stan's Heist Gear"
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Color", rgb(255, 170, 60))
	prompt.Parent = spot
	prompt.Triggered:Connect(function(player)
		Remotes.Push:FireClient(player, "openPanel", { name = "Shop", tab = 6 })
	end)
	m.Parent = workspace
end

function GearService.start()
	task.spawn(buildStall)
	local function watch(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.3)
			player:SetAttribute("Boxed", nil)
			GearService.refreshTools(player)
		end)
		task.spawn(function()
			for _ = 1, 40 do
				if Data.get(player) and player:FindFirstChild("Backpack") then break end
				task.wait(0.5)
			end
			GearService.refreshTools(player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do watch(player) end
end

return GearService
