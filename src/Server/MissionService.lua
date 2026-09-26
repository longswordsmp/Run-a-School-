-- ServerScriptService.Server.MissionService
-- The playable story (Config.Missions): one mission per chapter, handed out by Mr. Wobblesworth at the
-- Hub fountain. When your current chapter has a mission you haven't finished, you're marked
-- MissionReady and a "!" floats over him; talk to him (E), hear the story in the dialog box, and the
-- mission starts:
--   defend: a VexCorp crew raids your school (RaidService); knock every goon out
--   chase:  a runner sets off down Recess Row; bonk them hp times before the end of the route
--   heist:  a story kid or Vex's blueprints wait in the VexCorp Factory (FactoryService); get them out
-- Fail a mission and you can talk to him again to retry. Winning completes the chapter's mission step.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)
local Factory = require(script.Parent.StudentFactory)
local Walkers = require(script.Parent.Walkers)
local StealService = require(script.Parent.StealService)

local MissionService = {}

local active = {} -- [player] = { id, def, ...engine state }
local runnersFolder

local function now() return os.clock() end

-- the mission your current chapter is waiting on (nil if none, or it's done)
function MissionService.ready(player)
	local p = Data.get(player)
	if not p or (p.tutorial or 1) <= #Config.Tutorial then return nil end
	local c = p.chapter
	local ch = c and Config.Chapters[c.n]
	if not ch then return nil end
	for i, step in ch.steps do
		if step.kind == "mission" and not c.done[i] and not (p.missions and p.missions[step.id]) then
			return step.id
		end
	end
	return nil
end

-- (Stan's secret jobs use the same Mission attribute, prefixed "secret_": never touch theirs)
local function onSecret(player)
	local id = player:GetAttribute("Mission")
	return type(id) == "string" and id:sub(1, 7) == "secret_"
end

local function refreshReady(player)
	if not player.Parent then return end
	if onSecret(player) then
		player:SetAttribute("MissionReady", nil)
		return
	end
	player:SetAttribute("MissionReady", (not active[player]) and MissionService.ready(player) or nil)
	player:SetAttribute("Mission", active[player] and active[player].id or nil)
end
MissionService.refreshReady = refreshReady

local function push(player, state, extra)
	local m = active[player]
	local def = m and m.def
	local data = { state = state, title = def and def.title, objective = def and def.objective }
	for k, v in extra or {} do data[k] = v end
	Remotes.Push:FireClient(player, "mission", data)
end

local function finish(player, won)
	local m = active[player]
	if not m then return end
	active[player] = nil
	if m.cleanup then pcall(m.cleanup) end
	local p = Data.get(player)
	if won and p then
		p.missions = p.missions or {}
		p.missions[m.id] = true
		Remotes.Push:FireClient(player, "mission", { state = "won", title = m.def.title, line = m.def.win, speaker = m.def.lines[1][1], portrait = m.def.lines[1][2] })
		Signals.fire("missionWon", player, m.id)
	elseif player.Parent then
		Remotes.Push:FireClient(player, "mission", { state = "failed", title = m.def.title })
		Remotes.Notify:FireClient(player, "Mission failed. Talk to Mr. Wobblesworth to try again.", "bad")
	end
	refreshReady(player)
end

---------------------------------------------------------------------------
-- defend: a story raid on your school
---------------------------------------------------------------------------
local function startDefend(player, m)
	local RaidService = require(script.Parent.RaidService)
	local p = Data.get(player)
	local seated = 0
	for _, e in p and p.students or {} do
		if not e.away and not e.carried then seated += 1 end
	end
	if player:GetAttribute("Raid") or seated == 0 then
		active[player] = nil
		Remotes.Notify:FireClient(player, seated == 0 and "Seat some kids first: the goons need something to come for!"
			or "Deal with the raid at your school first!", "bad")
		refreshReady(player)
		return
	end
	push(player, "started", { progress = 0, count = math.min(m.def.goons, seated), phase = "Get back to your school!" })
	task.spawn(function()
		-- the van waits until you're back at your school: a fair fight, not a walk home to an empty school
		local PlotService = require(script.Parent.PlotService)
		local plot = PlotService.getPlot(player)
		while active[player] == m do
			local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not plot or (r and (r.Position - plot.Entry.Position).Magnitude < 70) then break end
			task.wait(0.3)
		end
		if active[player] ~= m then return end
		push(player, "phase", { text = m.def.objective })
		local ok = RaidService.start_raid(player, {
			goons = m.def.goons, hp = m.def.hp, story = true,
			onStart = function(raid)
				if active[player] == m then push(player, "progress", { progress = 0, count = raid.count }) end
			end,
			onKO = function(raid)
				if active[player] == m then push(player, "progress", { progress = raid.ko, count = raid.count }) end
			end,
			onLost = function()
				-- a goon got away with a kid: the mission's lost (the raid itself plays out)
				if active[player] == m then finish(player, false) end
			end,
			onEnd = function(raid)
				if active[player] == m then finish(player, raid.lost == 0 and raid.ko >= raid.count) end
			end,
		})
		if not ok and active[player] == m then
			active[player] = nil
			Remotes.Push:FireClient(player, "mission", { state = "cancelled" })
			Remotes.Notify:FireClient(player, "The goons turned back. Talk to Mr. Wobblesworth again.", "info")
			refreshReady(player)
		end
	end)
end

---------------------------------------------------------------------------
-- heist: a story kid or Vex's blueprints in the Factory
---------------------------------------------------------------------------
local function startHeist(player, m)
	local FactoryService = require(script.Parent.FactoryService)
	-- (no failing a heist: get thrown out and the kid or the plans are still there to try again)
	if m.def.item then
		FactoryService.storyItem(player, m.id)
		m.cleanup = function() task.defer(FactoryService.storyItemDone) end
	else
		FactoryService.storyCapture(player, m.id, m.def.kid)
	end
	push(player, "started", { guide = m.def.item and "plans" or "factory" })
end

---------------------------------------------------------------------------
-- chase: a runner down Recess Row
---------------------------------------------------------------------------
local function runnerTag(model, text)
	local head = model:FindFirstChild("Head")
	if not head then return end
	local bb = head:FindFirstChild("RunnerTag")
	if not bb then
		bb = Instance.new("BillboardGui")
		bb.Name = "RunnerTag"
		bb.Size = UDim2.fromOffset(240, 40)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 120
		bb.Parent = head
		local t = Instance.new("TextLabel")
		t.Name = "Label"
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = Color3.fromRGB(255, 230, 120)
		t.Parent = bb
		local s = Instance.new("UIStroke")
		s.Thickness = 2.5
		s.Parent = t
	end
	bb.Label.Text = text
end

-- the ground under a route point (roads, the plaza), ignoring anything that walks
local function groundY(x, z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip = { runnersFolder }
	for _, name in { "StoryNPCs", "Raids", "QuestGuide", "Hall" } do
		local f = workspace:FindFirstChild(name)
		if f then table.insert(skip, f) end
	end
	for _, pl in Players:GetPlayers() do
		if pl.Character then table.insert(skip, pl.Character) end
	end
	params.FilterDescendantsInstances = skip
	-- (from knee height, so lamp arms, awnings and the bus stop roof don't count)
	local hit = workspace:Raycast(Vector3.new(x, 4, z), Vector3.new(0, -12, 0), params)
	return hit and hit.Position.Y or 0.4
end

local function startChase(player, m)
	local spec = Config.ChaseRunners[m.def.runner]
	local route = Config.ChaseRoutes[m.def.route]
	local model = Factory.buildTeacher(spec, 1)
	model.Name = "Runner"
	model:SetAttribute("Runner", player.UserId)
	local so = Factory.standOffset(model)
	local pts = {}
	for _, p in route do table.insert(pts, Vector3.new(p.X, groundY(p.X, p.Z) + so, p.Z)) end
	model.PrimaryPart.CFrame = CFrame.lookAt(pts[1], pts[2])
	-- a sack of loot, and an outline you can see through anything
	local h = Instance.new("Highlight")
	h.OutlineColor = Color3.fromRGB(255, 200, 60)
	h.FillTransparency = 1
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = model
	model.Parent = runnersFolder
	runnerTag(model, ("%s  \u{2665}%d"):format(spec.name, m.def.hp))
	local r = { model = model, pts = pts, hp = m.def.hp, safeUntil = 0, stunUntil = 0, spec = spec }
	m.runner = r
	m.cleanup = function()
		if model.Parent then model:Destroy() end
	end
	local function runFrom(speed)
		local root = model.PrimaryPart
		local best, bestD = 1, math.huge
		for i, p in pts do
			local d = (p - root.Position).Magnitude
			if d < bestD then best, bestD = i, d end
		end
		local rest = {}
		for i = math.min(best + 1, #pts), #pts do table.insert(rest, pts[i]) end
		Factory.play(model, "run")
		Walkers.walk(model, rest, speed, function()
			if active[player] ~= m then return end
			-- made it: the mission is lost
			runnerTag(model, "Too slow!")
			task.delay(1, function() finish(player, false) end)
		end, { flat = false })
	end
	r.runFrom = runFrom
	-- he waits at the start of his route (the guide arrow points at him) until you get close,
	-- taunts you, then runs
	runnerTag(model, spec.name)
	Factory.play(model, "idle")
	task.spawn(function()
		while active[player] == m and model.Parent do
			local char = player.Character
			local proot = char and char:FindFirstChild("HumanoidRootPart")
			if proot and (proot.Position - model.PrimaryPart.Position).Magnitude < 28 then break end
			task.wait(0.2)
		end
		if active[player] ~= m or not model.Parent then return end
		runnerTag(model, spec.name .. ": Catch me if you can!")
		Factory.emote(model, "laugh")
		task.wait(1.4)
		if active[player] ~= m or not model.Parent then return end
		runnerTag(model, ("%s  \u{2665}%d"):format(spec.name, r.hp))
		r.running = true
		runFrom(spec.speed)
	end)
	push(player, "started", { progress = 0, count = m.def.hp })
end

-- a Ruler hit on a runner: a stagger, then a dash to get away (he can't be hit again right away)
local function hitRunner(player, m, root)
	local r = m.runner
	local model = r.model
	local mroot = model.PrimaryPart
	if not mroot or now() < r.safeUntil then return end
	r.hp -= 1
	r.safeUntil = now() + 1.6
	r.running = true
	r.hits = (r.hits or 0) + 1
	Walkers.stop(model)
	Remotes.Sfx:FireClient(player, "Bonk")
	Remotes.Push:FireClient(player, "hit", { pos = mroot.Position + Vector3.new(0, 2, 0), ko = r.hp <= 0 })
	push(player, "progress", { progress = m.def.hp - r.hp, count = m.def.hp })
	if r.hp <= 0 then
		runnerTag(model, "OOF!")
		Factory.play(model, "fall")
		mroot.CFrame = mroot.CFrame * CFrame.Angles(math.rad(-80), 0, 0)
		task.delay(1.2, function() finish(player, true) end)
		return
	end
	runnerTag(model, ("%s  \u{2665}%d"):format(r.spec.name, r.hp))
	-- stagger back a few studs
	local dir = Vector3.new(mroot.Position.X - root.Position.X, 0, mroot.Position.Z - root.Position.Z)
	dir = dir.Magnitude > 1e-3 and dir.Unit or -mroot.CFrame.LookVector
	local start = mroot.CFrame
	Factory.play(model, "fall")
	local t0 = now()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local a = math.min(1, (now() - t0) / 0.3)
		if not mroot.Parent then conn:Disconnect() return end
		mroot.CFrame = start + dir * 5 * a + Vector3.new(0, math.sin(a * math.pi) * 1.8, 0)
		if a >= 1 then conn:Disconnect() end
	end)
	task.delay(0.6, function()
		if active[player] ~= m or not model.Parent then return end
		-- a dash, then back to his normal pace
		r.runFrom(r.spec.dash)
		task.delay(r.spec.dashTime or 0.8, function()
			if active[player] == m and model.Parent and Walkers.isWalking(model) then r.runFrom(r.spec.speed) end
		end)
	end)
end

local function onSwing(player, root)
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	look = look.Magnitude > 1e-3 and look.Unit or Vector3.new(0, 0, -1)
	local m = active[player]
	if not m or not m.runner then return end
	local mroot = m.runner.model.PrimaryPart
	if not mroot then return end
	local d = mroot.Position - root.Position
	local flat = Vector3.new(d.X, 0, d.Z)
	-- (forgiving: he's moving, and the server sees you a moment late)
	if flat.Magnitude < 9 and math.abs(d.Y) < 7 and (flat.Magnitude < 5.5 or flat.Unit:Dot(look) > 0.1) then
		hitRunner(player, m, root)
	end
end

---------------------------------------------------------------------------
-- starting a mission
---------------------------------------------------------------------------
function MissionService.start(player, id)
	if active[player] or onSecret(player) then return false end
	local def = Config.Missions[id]
	if not def or MissionService.ready(player) ~= id then return false end
	local m = { id = id, def = def }
	active[player] = m
	refreshReady(player)
	if def.kind == "defend" then
		startDefend(player, m)
	elseif def.kind == "heist" then
		startHeist(player, m)
	elseif def.kind == "chase" then
		startChase(player, m)
	end
	return active[player] == m
end

-- the client asks to begin once the story lines have played
Actions.register("missionStart", function(player, p, id)
	if type(id) ~= "string" then return { ok = false } end
	return { ok = MissionService.start(player, id) }
end)

-- talking to Mr. Wobblesworth
local function talk(player)
	if active[player] then
		Remotes.Notify:FireClient(player, "You're already on a mission: " .. active[player].def.objective, "info")
		return
	end
	local id = MissionService.ready(player)
	if not id then
		local p = Data.get(player)
		local line = (p and (p.tutorial or 1) <= #Config.Tutorial) and "Finish your first day, then come and see me!"
			or "Nothing for now. Grow your school and face the Board, and I'll have news."
		Remotes.Push:FireClient(player, "missionTalk", { lines = { { "MR. WOBBLESWORTH", "Wobblesworth", line } } })
		return
	end
	Remotes.Push:FireClient(player, "missionTalk", { id = id, title = Config.Missions[id].title, lines = Config.Missions[id].lines })
end
local talkRaw = talk
talk = function(player)
	local wob = workspace:FindFirstChild("StoryNPCs") and workspace.StoryNPCs:FindFirstChild("Wobblesworth")
	if wob then wob:SetAttribute("QuietUntil", os.clock() + 20) end
	talkRaw(player)
end

function MissionService.start_service()
	runnersFolder = workspace:FindFirstChild("Runners") or Instance.new("Folder")
	runnersFolder.Name = "Runners"
	runnersFolder.Parent = workspace
	table.insert(StealService.swingHooks, onSwing)
	-- the talk prompt on Mr. Wobblesworth (he's built by StoryService)
	task.spawn(function()
		local story = workspace:WaitForChild("StoryNPCs", 30)
		local wob = story and story:WaitForChild("Wobblesworth", 30)
		if not wob or not wob.PrimaryPart then return end
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TalkPrompt"
		prompt.ActionText = "Talk"
		prompt.ObjectText = "Mr. Wobblesworth"
		prompt.HoldDuration = 0
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 10
		prompt:SetAttribute("Color", Color3.fromRGB(255, 210, 90))
		prompt.Parent = wob.PrimaryPart
		prompt.Triggered:Connect(talk)
	end)
	-- heists: the Factory reports a story kid or the blueprints getting out
	Signals.on("storyRescued", function(player, id)
		local m = active[player]
		if m and m.id == id then
			finish(player, true)
		elseif not m and MissionService.ready(player) == id then
			-- the kid was still waiting from before a rejoin: that counts
			active[player] = { id = id, def = Config.Missions[id] }
			finish(player, true)
		end
	end)
	-- anything that can change which mission is ready
	for _, name in { "chapterStep", "chapterDone", "questDone", "review" } do
		Signals.on(name, function(player)
			if typeof(player) == "Instance" and player:IsA("Player") then task.defer(refreshReady, player) end
		end)
	end
	-- and a slow sweep for everything else (a save loading, Studio jumps)
	task.spawn(function()
		while true do
			task.wait(3)
			for _, player in Players:GetPlayers() do pcall(refreshReady, player) end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local m = active[player]
		active[player] = nil
		if m and m.cleanup then pcall(m.cleanup) end
	end)
end

-- Studio
function MissionService.debugStart(player, id)
	local p = Data.get(player)
	local cur = active[player]
	if cur then
		active[player] = nil
		if cur.cleanup then pcall(cur.cleanup) end
	end
	-- jump straight to the chapter that has this mission
	for n, ch in Config.Chapters do
		for _, step in ch.steps do
			if step.kind == "mission" and step.id == id then
				p.tutorial = math.max(p.tutorial or 1, #Config.Tutorial + 1)
				p.chapter = { n = n, done = { false, false, false, false, false }, prog = { 0, 0, 0, 0 } }
				if p.missions then p.missions[id] = nil end
			end
		end
	end
	return MissionService.start(player, id)
end
function MissionService.debugHitRunner(player)
	local m = active[player]
	if not m or not m.runner then return false end
	local mroot = m.runner.model.PrimaryPart
	hitRunner(player, m, { Position = mroot.Position - mroot.CFrame.LookVector * 3 })
	return m.runner and m.runner.hp
end
function MissionService.debugState(player)
	local m = active[player]
	return { active = m and m.id or nil, ready = MissionService.ready(player), runnerHp = m and m.runner and m.runner.hp or nil }
end

return MissionService
