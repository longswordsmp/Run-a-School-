-- ServerScriptService.Server.QuestGoons
-- The action steps of town quests (TownQuestService.starters):
--   goons  VexCorp goons jump the player at a place; they run in and shove, two Ruler bonks knock one
--          out (a tumble, then gone). The step counts knockouts. Leave and they give up; come back
--          and the ones left jump you again.
--   chase  a runner (a goon, Crumpet...) legs it along a route of places; bonk them before they reach
--          the end. If they get away they're back at the start a moment later.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Places = require(ReplicatedStorage.Shared.Places)
local Factory = require(script.Parent.StudentFactory)
local Remotes = require(script.Parent.Remotes)
local StealService = require(script.Parent.StealService)

local QuestGoons = {}
local folder
local gangs = {} -- player -> { questId, place, left, goons = { {model, hp, nextShove, gone} } }
local runners = {} -- player -> { questId, model, route, i, speed, gone }

local LOOKS = {
	goon = { id = "VexGoon", name = "VexCorp Goon", title = "Goon", mult = 1, outfit = "goon" },
	crumpet = { id = "Crumpet", name = "Crumpet", title = "Butler", mult = 1, outfit = "butler" },
	guard = { id = "VexGuard", name = "Security", title = "VexCorp Security", mult = 1, outfit = "guard" },
	hazmat = { id = "LabGuard", name = "Hazmat", title = "Lab Security", mult = 1, outfit = "hazmat" },
}
local TAUNTS = { "Get 'em!", "Homework time!", "Dr. Vex says hi!", "No recess for YOU!", "Get back here!" }

local function rootOf(player)
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function build(look, pos)
	local m = Factory.buildTeacher(LOOKS[look] or LOOKS.goon, 1)
	local so = Factory.standOffset(m)
	m.PrimaryPart.CFrame = CFrame.new(pos + Vector3.new(0, so - 0.1, 0))
	m:SetAttribute("StandOffset", so)
	m.Parent = folder
	return m, so
end

local function bubble(m, text)
	local head = m:FindFirstChild("Head")
	if not head then return end
	local old = head:FindFirstChild("Taunt")
	if old then old:Destroy() end
	local bb = Instance.new("BillboardGui")
	bb.Name = "Taunt"
	bb.Size = UDim2.fromOffset(200, 44)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	bb.MaxDistance = 60
	bb.LightInfluence = 0
	bb.Parent = head
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = Color3.fromRGB(255, 250, 240)
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.Text = text
	t.Parent = bb
	Instance.new("UICorner", t).CornerRadius = UDim.new(0, 12)
	local s = Instance.new("UIStroke")
	s.Thickness = 2.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = t
	task.delay(2.2, function() if bb.Parent then bb:Destroy() end end)
end

-- a knocked-out goon: spin over, lie there a moment, fade away
local function tumble(m, away)
	local root = m.PrimaryPart
	if not root then m:Destroy() return end
	for _, tr in m:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator"):GetPlayingAnimationTracks() do tr:Stop(0.1) end
	local flat = Vector3.new(away.X, 0, away.Z)
	flat = flat.Magnitude > 1e-3 and flat.Unit or Vector3.new(1, 0, 0)
	local startCF = root.CFrame
	local landed = CFrame.new(startCF.Position + flat * 6 - Vector3.new(0, (m:GetAttribute("StandOffset") or 3) - 0.8, 0)) * CFrame.lookAt(Vector3.zero, flat).Rotation * CFrame.Angles(math.rad(-90), 0, 0)
	local v = Instance.new("CFrameValue")
	v.Value = startCF
	v.Changed:Connect(function(cf) if root.Parent then root.CFrame = cf end end)
	TweenService:Create(v, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = landed }):Play()
	task.delay(1.8, function()
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then
				TweenService:Create(d, TweenInfo.new(0.5), { Transparency = 1 }):Play()
			end
		end
		task.wait(0.55)
		v:Destroy()
		m:Destroy()
	end)
end

---------------------------------------------------------------------------
-- goons
---------------------------------------------------------------------------
local function spawnGang(player, gang)
	local place = Places.get(gang.place)
	for i = 1, gang.left do
		local a = (i / gang.left) * math.pi * 2
		local pos = place.pos + Vector3.new(math.cos(a) * 14, 0, math.sin(a) * 14)
		local m, so = build(gang.look, pos)
		m:SetAttribute("QuestGoon", player.UserId)
		table.insert(gang.goons, { model = m, hp = 2, so = so, y = place.pos.Y, nextShove = 0, stunUntil = 0 })
		Factory.play(m, "run")
		if i == 1 then bubble(m, TAUNTS[math.random(#TAUNTS)]) end
	end
	gang.spawned = true
	Remotes.Notify:FireClient(player, "\u{1F4A5} Goons! Swing your Ruler (click) to bonk them!", "bad")
end

local function clearGang(gang)
	for _, g in gang.goons do
		if not g.gone and g.model.Parent then g.model:Destroy() end
	end
	gang.goons = {}
	gang.spawned = false
end

function QuestGoons.goons(player, q, s, st)
	local old = gangs[player]
	if old then clearGang(old) end
	local left = (s.n or 3) - (st.prog or 0)
	gangs[player] = { questId = q.id, step = st.step, place = s.place, left = left, goons = {}, look = s.look or "goon" }
end

---------------------------------------------------------------------------
-- chase
---------------------------------------------------------------------------
local function spawnRunner(player, r)
	local start = Places.get(r.route[1]).pos
	local m, so = build(r.look, start)
	m:SetAttribute("QuestRunner", player.UserId)
	r.model, r.so, r.i, r.gone = m, so, 2, false
	Factory.play(m, "run")
	bubble(m, "Catch me if you can!")
end

function QuestGoons.chase(player, q, s, st)
	local old = runners[player]
	if old and old.model and old.model.Parent then old.model:Destroy() end
	local route = { s.from or s.route[1] }
	for _, name in s.route do
		if name ~= route[1] then table.insert(route, name) end
	end
	local r = { questId = q.id, step = st.step, route = route, look = s.runner or "goon", speed = s.speed or 15, waitNear = true }
	runners[player] = r
end

---------------------------------------------------------------------------
-- the loop
---------------------------------------------------------------------------
local TownQuestService -- (set by QuestGoons.start: the two modules know each other)

local function stepStillOn(player, questId, step)
	local st = TownQuestService.debugState(player)
	local a = st and st.active and st.active[questId]
	return a and a.step == step
end

local function tick(dt)
	local now = os.clock()
	for player, gang in gangs do
		if not player.Parent or not stepStillOn(player, gang.questId, gang.step) then
			clearGang(gang)
			gangs[player] = nil
			continue
		end
		local root = rootOf(player)
		local place = Places.get(gang.place)
		local near = root and (root.Position - place.pos).Magnitude < 45
		if near and not gang.spawned then spawnGang(player, gang) end
		if not near and gang.spawned and root and (root.Position - place.pos).Magnitude > 120 then clearGang(gang) end
		for _, g in gang.goons do
			local groot = not g.gone and g.model.PrimaryPart
			if groot and root and now > g.stunUntil then
				local to = Vector3.new(root.Position.X, g.y + g.so - 0.1, root.Position.Z)
				local d = to - groot.Position
				local flat = Vector3.new(d.X, 0, d.Z)
				if flat.Magnitude > 3.2 then
					local step = math.min(flat.Magnitude - 3, 11 * dt)
					local p = groot.Position + flat.Unit * step
					groot.CFrame = CFrame.lookAt(Vector3.new(p.X, to.Y, p.Z), Vector3.new(root.Position.X, to.Y, root.Position.Z))
				elseif now > g.nextShove then
					-- a shove: the player gets knocked back a little
					g.nextShove = now + 1.6
					Factory.emote(g.model, "point")
					root.AssemblyLinearVelocity = flat.Magnitude > 0.01 and (flat.Unit * 45 + Vector3.new(0, 18, 0)) or Vector3.new(0, 20, 0)
					if math.random() < 0.4 then bubble(g.model, TAUNTS[math.random(#TAUNTS)]) end
				end
			end
		end
	end
	for player, r in runners do
		if not player.Parent or not stepStillOn(player, r.questId, r.step) then
			if r.model and r.model.Parent then r.model:Destroy() end
			runners[player] = nil
			player:SetAttribute("QuestRunnerAt", nil)
			continue
		end
		local root = rootOf(player)
		local start = Places.get(r.route[1]).pos
		if not r.model then
			-- waits at the start until you come close
			player:SetAttribute("QuestRunnerAt", start + Vector3.new(0, 4, 0))
			if root and (root.Position - start).Magnitude < 40 then spawnRunner(player, r) end
			continue
		end
		local groot = r.model.PrimaryPart
		if r.gone or not groot then continue end
		player:SetAttribute("QuestRunnerAt", groot.Position + Vector3.new(0, 4, 0))
		local target = Places.get(r.route[r.i]).pos + Vector3.new(0, r.so - 0.1, 0)
		local d = target - groot.Position
		local dist = d.Magnitude
		-- runs flat out once you're close, jogs when you fall behind (so it stays a chase)
		local pd = root and (root.Position - groot.Position).Magnitude or 99
		local speed = pd < 30 and r.speed or r.speed * 0.6
		if dist <= speed * dt then
			r.i += 1
			if r.i > #r.route then
				-- got away: back to the start
				r.gone = true
				Remotes.Notify:FireClient(player, "They got away! They're back where they started. Try again!", "bad")
				r.model:Destroy()
				r.model = nil
				r.gone = false
			end
		else
			local p = groot.Position + d.Unit * speed * dt
			groot.CFrame = CFrame.lookAt(p, p + Vector3.new(d.X, 0, d.Z))
		end
	end
end

local function onSwing(player, root)
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	look = look.Magnitude > 1e-3 and look.Unit or Vector3.new(0, 0, -1)
	local function inReach(groot)
		local d = groot.Position - root.Position
		local flat = Vector3.new(d.X, 0, d.Z)
		return flat.Magnitude < 8 and math.abs(d.Y) < 7 and (flat.Magnitude < 3.5 or flat.Unit:Dot(look) > 0.25), d
	end
	local gang = gangs[player]
	for _, g in gang and gang.goons or {} do
		local groot = not g.gone and g.model.PrimaryPart
		local ok, d = false, nil
		if groot then ok, d = inReach(groot) end
		if ok then
			g.hp -= 1
			g.stunUntil = os.clock() + 0.6
			Remotes.Sfx:FireClient(player, "Bonk")
			Remotes.Push:FireClient(player, "hit", { pos = groot.Position + Vector3.new(0, 2, 0), ko = g.hp <= 0 })
			if g.hp <= 0 then
				g.gone = true
				bubble(g.model, "Ow ow OW...")
				tumble(g.model, d)
				gang.left -= 1
				TownQuestService.progress(player, gang.questId, 1)
			else
				groot.CFrame += Vector3.new(d.X, 0, d.Z).Unit * 3
			end
			return
		end
	end
	local r = runners[player]
	local rroot = r and r.model and not r.gone and r.model.PrimaryPart
	if rroot then
		local ok, d = inReach(rroot)
		if ok then
			r.gone = true
			Remotes.Sfx:FireClient(player, "Bonk")
			Remotes.Push:FireClient(player, "hit", { pos = rroot.Position + Vector3.new(0, 2, 0), ko = true })
			bubble(r.model, "Oof! Okay, okay, you got me!")
			tumble(r.model, d)
			player:SetAttribute("QuestRunnerAt", nil)
			local qid = r.questId
			runners[player] = nil
			TownQuestService.progress(player, qid, 1)
		end
	end
end

function QuestGoons.start(tqs)
	TownQuestService = tqs
	folder = workspace:FindFirstChild("QuestGoons") or Instance.new("Folder")
	folder.Name = "QuestGoons"
	folder.Parent = workspace
	tqs.starters.goons = QuestGoons.goons
	tqs.starters.chase = QuestGoons.chase
	table.insert(StealService.swingHooks, onSwing)
	RunService.Heartbeat:Connect(function(dt)
		local ok, err = pcall(tick, dt)
		if not ok then warn("[QuestGoons]", err) end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local g = gangs[player]
		if g then clearGang(g) gangs[player] = nil end
		local r = runners[player]
		if r and r.model then r.model:Destroy() end
		runners[player] = nil
	end)
end

return QuestGoons
