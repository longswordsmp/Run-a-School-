-- ServerScriptService.Server.TownNPCService
-- The townspeople (Shared/Townsfolk, posts in Shared/Places.npc) standing around the town in
-- workspace.Townsfolk: a name tag, an idle, a speech bubble with their own lines when someone
-- walks past, a wave for people they haven't seen in a while, and a Talk prompt. Walkers (Mo the
-- mail carrier) stroll between the places on their route. What Talk does is up to the quest engine
-- (TownNPCService.onTalk); with nothing to hand out they just chat.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Townsfolk = require(ReplicatedStorage.Shared.Townsfolk)
local Places = require(ReplicatedStorage.Shared.Places)
local Factory = require(script.Parent.StudentFactory)
local Walkers = require(script.Parent.Walkers)
local Remotes = require(script.Parent.Remotes)

local TownNPCService = {}
local folder
local npcs = {} -- id -> { def, model, bubble, text, home (CFrame), greeted = { [player] = clock } }

-- the quest engine sets this: (player, id) -> true if it handled the talk
TownNPCService.onTalk = nil

local function speech(model)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Speech"
	bb.Size = UDim2.fromOffset(250, 66)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0)
	bb.MaxDistance = 60
	bb.LightInfluence = 0
	bb.Enabled = false
	bb.Parent = model.Head
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.fromRGB(255, 252, 240)
	f.Parent = bb
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 14)
	c.Parent = f
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Parent = f
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.Size = UDim2.new(1, -16, 1, -10)
	t.Position = UDim2.fromOffset(8, 5)
	t.BackgroundTransparency = 1
	t.TextWrapped = true
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = Color3.fromRGB(30, 25, 40)
	t.Parent = f
	return bb, t
end

local function nameTag(model, def)
	local bb = Instance.new("BillboardGui")
	bb.Name = "NameTag"
	bb.Size = UDim2.new(8, 0, 1.6, 0)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
	bb.MaxDistance = 55
	bb.LightInfluence = 0
	bb.Parent = model.Head
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.RichText = true
	t.Text = ("<font color=\"#%s\">%s</font>\n%s"):format(def.color:ToHex(), def.title, def.name)
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Parent = bb
	local s = Instance.new("UIStroke")
	s.Thickness = 2.5
	s.Parent = t
end

local function say(npc, text, secs)
	npc.text.Text = text
	npc.bubble.Enabled = true
	npc.saidAt = os.clock()
	task.delay(secs or 5, function()
		if os.clock() - npc.saidAt >= (secs or 5) - 0.05 then npc.bubble.Enabled = false end
	end)
end

local function nearestPlayer(pos, range)
	local best, bestD
	for _, pl in Players:GetPlayers() do
		local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
		if r then
			local d = (r.Position - pos).Magnitude
			if d < range and (not best or d < bestD) then best, bestD = pl, d end
		end
	end
	return best, bestD
end

local function faceCF(post)
	local flatLook = Vector3.new(post.look.X, post.pos.Y, post.look.Z)
	if (flatLook - post.pos).Magnitude < 0.1 then return CFrame.new(post.pos) end
	return CFrame.lookAt(post.pos, flatLook)
end

local function spawnOne(def)
	local post = Places.npc[def.id]
	if not post then
		warn("[TownNPCService] no post for", def.id)
		return
	end
	local m = Factory.buildTeacher({ id = def.id, name = def.name, title = def.title, mult = 1, outfit = def.outfit }, 1)
	m.Name = def.id
	if def.scale and def.scale ~= 1 then m:ScaleTo(def.scale) end
	nameTag(m, def)
	local home = faceCF(post)
	local so = Factory.standOffset(m)
	m.PrimaryPart.CFrame = home + Vector3.new(0, so - 0.1, 0)
	m:SetAttribute("Townsperson", def.id)
	m:SetAttribute("Area", post.area)
	m.Parent = folder
	Factory.play(m, "idle")

	local npc = { def = def, model = m, home = home, so = so, greeted = setmetatable({}, { __mode = "k" }) }
	npc.bubble, npc.text = speech(m)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = "Talk"
	prompt.ObjectText = def.name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Color", def.color)
	prompt.Parent = m.PrimaryPart
	prompt.Triggered:Connect(function(player)
		TownNPCService.talk(player, def.id)
	end)
	npcs[def.id] = npc
	return npc
end

-- a conversation: the quest engine first; otherwise a line of chat
function TownNPCService.talk(player, id)
	local npc = npcs[id]
	if not npc then return end
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not r or (r.Position - npc.model.PrimaryPart.Position).Magnitude > 16 then return end
	npc.talkingTo = player
	npc.quietUntil = os.clock() + 12
	npc.bubble.Enabled = false
	local root = npc.model.PrimaryPart
	root.CFrame = CFrame.lookAt(root.Position, Vector3.new(r.Position.X, root.Position.Y, r.Position.Z))
	if TownNPCService.onTalk and TownNPCService.onTalk(player, id) then return end
	local lines = npc.def.lines
	npc.lineN = ((npc.lineN or math.random(#lines)) % #lines) + 1
	Remotes.Push:FireClient(player, "missionTalk", { lines = { { npc.def.name:upper(), id, lines[npc.lineN] } }, npc = id })
end

-- the townspeople's heads, for the quest engine's markers and cutscenes
function TownNPCService.model(id)
	local npc = npcs[id]
	return npc and npc.model
end

-- say something out loud (quest beats, cutscenes)
function TownNPCService.say(id, text, secs)
	local npc = npcs[id]
	if npc then say(npc, text, secs) end
end

function TownNPCService.emote(id, which)
	local npc = npcs[id]
	if npc then Factory.emote(npc.model, which) end
end

-- the walkers: along their route and back, pausing at each end
local function walkLoop(npc)
	local pts = {}
	for _, name in npc.def.walk do
		local p = Places.get(name)
		if p then table.insert(pts, p.pos) end
	end
	if #pts < 2 then return end
	local root = npc.model.PrimaryPart
	local i = 1
	while npc.model.Parent do
		if (npc.quietUntil or 0) > os.clock() then
			task.wait(1)
			continue
		end
		i = i % #pts + 1
		local goal = pts[i] + Vector3.new(0, npc.so - 0.1, 0)
		Factory.play(npc.model, "walk")
		local done = false
		Walkers.walk(npc.model, { goal }, 6, function() done = true end)
		while not done and npc.model.Parent do
			-- stop to chat
			if (npc.quietUntil or 0) > os.clock() then
				Walkers.stop(npc.model)
				Factory.play(npc.model, "idle")
				while (npc.quietUntil or 0) > os.clock() do task.wait(0.5) end
				Factory.play(npc.model, "walk")
				Walkers.walk(npc.model, { goal }, 6, function() done = true end)
			end
			task.wait(0.3)
		end
		Factory.play(npc.model, "idle")
		npc.home = root.CFrame - Vector3.new(0, npc.so - 0.1, 0)
		task.wait(5 + math.random() * 5)
	end
end

-- one loop for everyone standing still: turn to the nearest passer-by, greet, chat
local function idleLoop()
	while true do
		for _, npc in npcs do
			local m = npc.model
			if not m.Parent or npc.def.walk then continue end
			local root = m.PrimaryPart
			local pl = nearestPlayer(root.Position, 18)
			if pl then
				local r = pl.Character.HumanoidRootPart
				root.CFrame = CFrame.lookAt(root.Position, Vector3.new(r.Position.X, root.Position.Y, r.Position.Z))
				if (npc.quietUntil or 0) < os.clock() then
					if not npc.greeted[pl] or os.clock() - npc.greeted[pl] > 90 then
						npc.greeted[pl] = os.clock()
						Factory.emote(m, "wave")
						say(npc, ("Oh! Hi there, %s!"):format(pl.DisplayName), 3.5)
						npc.nextChat = os.clock() + 6
					elseif os.clock() > (npc.nextChat or 0) then
						local lines = npc.def.lines
						npc.lineN = ((npc.lineN or math.random(#lines)) % #lines) + 1
						say(npc, lines[npc.lineN], 5)
						if math.random() < 0.3 then Factory.emote(m, math.random() < 0.5 and "laugh" or "point") end
						npc.nextChat = os.clock() + 10 + math.random() * 6
					end
				end
			elseif (root.Position - (npc.home.Position + Vector3.new(0, npc.so - 0.1, 0))).Magnitude < 0.5 then
				-- nobody about: back to facing their post
				root.CFrame = npc.home + Vector3.new(0, npc.so - 0.1, 0)
			end
		end
		task.wait(0.5)
	end
end

-- the story cast's templates (cutscene actors and dialog portraits need them before the story
-- has spawned them anywhere)
local CAST = {
	{ id = "Vex", name = "Dr. Veronica Vex", title = "VexCorp CEO", outfit = "vex" },
	{ id = "Crumpet", name = "Crumpet", title = "Butler", outfit = "butler" },
	{ id = "VexGoon", name = "VexCorp Goon", title = "Goon", outfit = "goon" },
	{ id = "VexGuard", name = "Security", title = "VexCorp Security", outfit = "guard" },
	{ id = "LabGuard", name = "Hazmat", title = "Lab Security", outfit = "hazmat" },
	{ id = "Baron", name = "The Sugar Baron", title = "???", outfit = "baron" },
	{ id = "Wobblesworth", name = "Mr. Wobblesworth", title = "Retired Principal", outfit = "wobble" },
	{ id = "Stan", name = "Janitor Stan", title = "Janitor", outfit = "stan" },
	-- (Vex Prep's showcase cutscene has Grindle asleep at his desk before you ever fight him)
	{ id = "Headmaster", name = "Headmaster Grindle", title = "Vex Prep", outfit = "dean" },
}

function TownNPCService.start()
	folder = workspace:FindFirstChild("Townsfolk") or Instance.new("Folder")
	folder.Name = "Townsfolk"
	folder.Parent = workspace
	task.spawn(function()
		for _, c in CAST do
			pcall(function()
				Factory.buildTeacher({ id = c.id, name = c.name, title = c.title, mult = 1, outfit = c.outfit }, 1):Destroy()
			end)
		end
	end)
	task.spawn(function()
		for _, def in ipairs(Townsfolk) do
			local ok, err = pcall(spawnOne, def)
			if not ok then warn("[TownNPCService] failed to spawn", def.id, err) end
			task.wait() -- (a rig per frame: no hitch at start)
		end
		for _, npc in npcs do
			if npc.def.walk then task.spawn(walkLoop, npc) end
		end
		idleLoop()
	end)
end

function TownNPCService.count()
	local n = 0
	for _ in npcs do n += 1 end
	return n
end

return TownNPCService
