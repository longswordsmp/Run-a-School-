-- ServerScriptService.Server.FilesService
-- The VexCorp Files (Config.Files): sixteen glowing folders hidden around Recess Row. Walk up and read
-- one (E): the document opens on your screen, and the first time you read it you keep it: candy,
-- and at 4 / 8 / 12 / 16 found, Heist Gear and finally a Mutated Mythic kid.
-- Saved as p.files = { [id] = true }; mirrored for the client as the player attribute "Files" (a
-- comma list), so each player's found folders fade out for them only (Files.client).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)

local FilesService = {}

local rgb = Color3.fromRGB

local function count(p)
	local n = 0
	for id in p.files or {} do
		if Config.FileById[id] then n += 1 end
	end
	return n
end
FilesService.count = count

local function mirror(player, p)
	local ids = {}
	for id in p.files or {} do table.insert(ids, id) end
	table.sort(ids)
	player:SetAttribute("Files", table.concat(ids, ","))
	player:SetAttribute("FilesFound", #ids)
end

local function part(parent, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props or {} do p[k] = v end
	p.Parent = parent
	return p
end

-- a manila folder with a purple VexCorp stamp, a "TOP SECRET" band and a glow
local function buildFolder(parent, f)
	local m = Instance.new("Model")
	m.Name = f.id
	m:SetAttribute("FileId", f.id)
	local base = CFrame.new(f.pos) * CFrame.Angles(math.rad(-12), math.rad((f.order * 47) % 360), 0)
	local cover = part(m, "Cover", Vector3.new(1.8, 0.1, 2.3), base, rgb(232, 196, 120), Enum.Material.Cardboard)
	part(m, "Back", Vector3.new(1.8, 0.1, 2.3), base * CFrame.new(0, -0.12, 0.02), rgb(214, 176, 100), Enum.Material.Cardboard)
	part(m, "Tab", Vector3.new(0.7, 0.1, 0.3), base * CFrame.new(-0.45, -0.06, -1.25), rgb(214, 176, 100), Enum.Material.Cardboard)
	part(m, "Papers", Vector3.new(1.65, 0.08, 2.15), base * CFrame.new(0.06, -0.06, 0.04), rgb(250, 248, 240))
	local band = part(m, "Band", Vector3.new(1.82, 0.12, 0.45), base * CFrame.new(0, 0.01, 0.4), rgb(200, 30, 40))
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Top
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 60
	g.Parent = band
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.LuckiestGuy
	t.Text = "TOP SECRET"
	t.TextColor3 = rgb(255, 255, 255)
	t.Parent = g
	local stamp = part(m, "Stamp", Vector3.new(0.7, 0.12, 0.7), base * CFrame.new(0.35, 0.01, -0.5), rgb(105, 45, 150))
	local g2 = Instance.new("SurfaceGui")
	g2.Face = Enum.NormalId.Top
	g2.Parent = stamp
	local t2 = Instance.new("TextLabel")
	t2.Size = UDim2.fromScale(1, 1)
	t2.BackgroundTransparency = 1
	t2.TextScaled = true
	t2.Font = Enum.Font.LuckiestGuy
	t2.Text = "V"
	t2.TextColor3 = rgb(230, 200, 255)
	t2.Parent = g2
	local l = Instance.new("PointLight")
	l.Color = rgb(255, 220, 140)
	l.Range = 8
	l.Brightness = 1.5
	l.Parent = cover
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(rgb(255, 230, 150))
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new(0.3, 0)
	sparkle.Lifetime = NumberRange.new(0.8, 1.2)
	sparkle.Speed = NumberRange.new(0.3, 0.8)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Rate = 5
	sparkle.Parent = cover
	m.PrimaryPart = cover
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ReadPrompt"
	prompt.ActionText = "Read"
	prompt.ObjectText = "VexCorp File"
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Color", rgb(255, 210, 120))
	prompt.Parent = cover
	m.Parent = parent
	return m, prompt
end

local function read(player, f)
	local p = Data.get(player)
	if not p then return end
	p.files = p.files or {}
	local fresh = not p.files[f.id]
	local reward
	if fresh then
		p.files[f.id] = true
		p.candy = (p.candy or 0) + Config.FileRewards.candy
		player:SetAttribute("Candy", p.candy)
		mirror(player, p)
		local n = count(p)
		local m = Config.FileRewards.milestones[n]
		if m then
			reward = m.text
			if m.gear then
				require(script.Parent.GearService).give(player, m.gear, m.n)
			elseif m.mutant then
				local pool = {}
				for _, s in Config.Students do
					if s.rarity == m.mutant then table.insert(pool, s) end
				end
				local def = pool[math.random(#pool)]
				local LetterService = require(script.Parent.LetterService)
				if not LetterService.deliver(player, def, true, "Mutated") then
					p.pendingBench = p.pendingBench or {}
					table.insert(p.pendingBench, { id = def.id, grade = "Mutated" })
				end
				reward = ("a MUTATED %s (%s)"):format(def.name, def.rarity)
			end
		end
		Signals.fire("fileFound", player, f.id, n)
		Data.saveSoon(player)
	end
	Remotes.Push:FireClient(player, "file", {
		id = f.id, title = f.title, by = f.by, text = f.text,
		n = count(p), total = #Config.Files, fresh = fresh,
		candy = fresh and Config.FileRewards.candy or nil, reward = reward,
	})
end

Actions.register("files", function(player, p)
	local out = {}
	for _, f in Config.Files do
		local have = p.files and p.files[f.id]
		table.insert(out, { id = f.id, title = have and f.title or "???", by = have and f.by or nil, text = have and f.text or nil, found = have == true })
	end
	return { ok = true, files = out, n = count(p), total = #Config.Files }
end)

function FilesService.start()
	local folder = workspace:FindFirstChild("VexFiles") or Instance.new("Folder")
	folder.Name = "VexFiles"
	folder:ClearAllChildren()
	folder.Parent = workspace
	for _, f in Config.Files do
		local _, prompt = buildFolder(folder, f)
		prompt.Triggered:Connect(function(player) read(player, f) end)
	end
	local function watch(player)
		task.spawn(function()
			for _ = 1, 40 do
				local p = Data.get(player)
				if p then mirror(player, p) return end
				task.wait(0.5)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do watch(player) end
end

-- Studio
function FilesService.debugRead(player, id)
	local f = Config.FileById[id]
	if f then read(player, f) end
	return f ~= nil
end

return FilesService
