-- ServerScriptService.Server.Main
-- The boot log (Studio, with the ServerStorage attribute BootLog on): how long each service takes to
-- start, when your school is assigned, when the kid templates are ready, and every frame over 150 ms.
-- It found the join freeze: everything waited on the kid preload (22 s cold), then the town, the
-- schools and the NPCs all landed at once just as the loading screen let you in.
local BOOT_T0 = os.clock()
local BOOT_LOG = game:GetService("RunService"):IsStudio() and game:GetService("ServerStorage"):GetAttribute("BootLog") == true
if BOOT_LOG then
	local last = os.clock()
	game:GetService("RunService").Heartbeat:Connect(function()
		local now = os.clock()
		if now - last > 0.15 then print(("[Boot] frame %.0f ms ending at %.1f s"):format((now - last) * 1000, now - BOOT_T0)) end
		last = now
	end)
end
local function timed(name, f, ...)
	local t = os.clock()
	f(...)
	local d = os.clock() - t
	if BOOT_LOG and d > 0.05 then print(("[Boot] %s %.0f ms (from %.1f s)"):format(name, d * 1000, t - BOOT_T0)) end
end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = script.Parent
-- the street first: HallService reads the bus stop and the kids' walk from it
timed("StreetLayout", require(Server.StreetLayout).build)
-- Janitor Stan's Confiscation Closet (replaces the shed baked into the place; before StoryService,
-- which stands Stan at its NPCSpot)
timed("TownCloset", require(Server.TownCloset).build)
-- Recess Commons, the town playground (it replaces the one baked into the place)
task.spawn(function() timed("TownPlayground", require(Server.TownPlayground).build) end)
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(Server.Remotes)
local Data = require(Server.DataService)
local Factory = require(Server.StudentFactory)
local Walkers = require(Server.Walkers)
local Actions = require(Server.Actions)
local PlotService = require(Server.PlotService)
local UpgradeService = require(Server.UpgradeService)
local GateService = require(Server.GateService)
local HallService = require(Server.HallService)
require(Server.SchoolService)
require(Server.BoardService)
local TeacherService = require(Server.TeacherService)
local CampusService = require(Server.CampusService)
local StealService = require(Server.StealService)
local QuestService = require(Server.QuestService)
local PatrolService = require(Server.PatrolService)
local EventService = require(Server.EventService)
local LetterService = require(Server.LetterService)
local MonetizationService = require(Server.MonetizationService)
local RewardService = require(Server.RewardService)
local StoryService = require(Server.StoryService)
local LeaderboardService = require(Server.LeaderboardService)
local QuizService = require(Server.QuizService)
local ChapterService = require(Server.ChapterService)
local DailyService = require(Server.DailyService)
local TicketService = require(Server.TicketService)
local AlumniService = require(Server.AlumniService)
local RaidService = require(Server.RaidService)
local FactoryService = require(Server.FactoryService)
local MissionService = require(Server.MissionService)
local StreetService = require(Server.StreetService)
local UnlockService = require(Server.UnlockService)
local MoveService = require(Server.MoveService)
local GearService = require(Server.GearService)
local LabService = require(Server.LabService)
local FilesService = require(Server.FilesService)
local SecretService = require(Server.SecretService)
local RivalService = require(Server.RivalService)
local CrewService = require(Server.CrewService)
local TownService = require(Server.TownService)
local AreaService = require(Server.AreaService)
local TownNPCService = require(Server.TownNPCService)
local TownQuestService = require(Server.TownQuestService)

-- (the kid templates build in the background: the loading screen waits for them, and the town, the
-- schools and the services come up meanwhile, behind it; anything that needs a kid first builds it then)
task.spawn(function()
	local t = os.clock()
	Factory.preload()
	if BOOT_LOG then print(("[Boot] kid templates ready %.1f s .. %.1f s"):format(t - BOOT_T0, os.clock() - BOOT_T0)) end
end)
timed("PlotService.start", PlotService.start)
timed("UpgradeService.start", UpgradeService.start)
timed("GateService.start", GateService.start)
timed("HallService.start", HallService.start)
timed("TeacherService.start", TeacherService.start)
timed("CampusService.start", CampusService.start)
timed("StealService.start", StealService.start)
timed("QuestService.start", QuestService.start)
timed("PatrolService.start", PatrolService.start)
timed("EventService.startLoop", EventService.startLoop)
timed("Server.AdminService", require(Server.AdminService).start)
timed("LetterService.start", LetterService.start)
timed("MonetizationService.start", MonetizationService.start)
timed("EasterEggService.start", require(Server.EasterEggService).start)
timed("RewardService.start", RewardService.start)
timed("StoryService.start", StoryService.start)
timed("LeaderboardService.start", LeaderboardService.start)
timed("QuizService.start", QuizService.start)
timed("ChapterService.start", ChapterService.start)
timed("DailyService.start", DailyService.start)
timed("TicketService.start", TicketService.start)
timed("AlumniService.start", AlumniService.start)
timed("RaidService.start", RaidService.start)
timed("FactoryService.start", FactoryService.start)
timed("MissionService.start_service", MissionService.start_service)
timed("StreetService.start", StreetService.start)
timed("UnlockService.start", UnlockService.start)
timed("MoveService.start", MoveService.start)
timed("GearService.start", GearService.start)
timed("LabService.start", LabService.start)
timed("FilesService.start", FilesService.start)
timed("SecretService.start_service", SecretService.start_service)
timed("RivalService.start", RivalService.start)
timed("CrewService.start", CrewService.start)
timed("TownService.start", TownService.start)
timed("AreaService.start", AreaService.start)
local HQService = require(Server.HQService)
local PrestigeService = require(Server.PrestigeService)
timed("PrestigeService.start", PrestigeService.start)
timed("Server.HouseService", require(Server.HouseService).start)
timed("HQService.start", HQService.start, TownService.root)
timed("TownNPCService.start", TownNPCService.start)
timed("TownQuestService.start_service", TownQuestService.start_service)
timed("Server.SewerHeist", require(Server.SewerHeist).start_service) -- (Chapter 1: the pothole, the sewer, the Vex Prep Job)
TownQuestService.targets.hqFloor = function(player, s) return HQService.target(player, s.arg) end
require(Server.QuestGoons).start(TownQuestService)
-- (the Board, the Yearbook, the Files, Co-op and the school's name: places in the world, not side buttons)
timed("PlacesService.start", require(Server.PlacesService).start)

if BOOT_LOG then print(("[Boot] services up at %.1f s"):format(os.clock() - BOOT_T0)) end

local introBusFor = {} -- [player] = "waiting" / "sent": the intro's Welcome Bus

local function onPlayer(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = ls
	ls.Parent = player

	local p = Data.load(player)
	if not p then return end
	timed("PlotService.assign", PlotService.assign, player)
	if BOOT_LOG then print(("[Boot] %s's school assigned at %.1f s"):format(player.Name, os.clock() - BOOT_T0)) end
	UpgradeService.applyAll(player)
	if p.offlineEarned and p.offlineEarned > 0 then
		Remotes.Push:FireClient(player, "offline", { amount = p.offlineEarned, away = p.offlineAway })
	end

	-- a finale that was cut short (they left) plays again
	if p.finalePending then require(Server.BoardService).finale(player, 12) end

	-- a brand-new principal gets the intro and the Welcome Bus
	-- (Studio tests can skip it with the ServerStorage attribute SkipIntro)
	local skip = game:GetService("RunService"):IsStudio() and game.ServerStorage:GetAttribute("SkipIntro")
	-- (a principal whose school is still empty on the first step gets it again when they come back:
	-- the bus, not the intro)
	if p.tutorial == 1 and next(p.students) == nil and not skip then
		task.spawn(function()
			-- after the loading screen's PLAY, however long that takes
			while player.Parent and not player:GetAttribute("Ready") do task.wait(0.2) end
			task.wait(0.4)
			if not player.Parent then return end
			-- (joined a friend's co-op school from the loading screen: that school is already running)
			if Data.isMember(player) then return end
			if not p.introSeen then
				-- "The Keys" (Cutscene.client): the Welcome Bus sets off when the scene asks for it
				-- (Action "introBus"), or after a while whatever happens
				p.introSeen = true
				local spots = HallService.welcomeSpots(PlotService.getPlot(player))
				Remotes.Cutscene:FireClient(player, "Intro", {
					name = PlotService.schoolName(player),
					gate = spots and spots.gate, park = spots and spots.park.Position, side = spots and spots.side,
					stand = spots and spots.stand, row = spots and spots.wait[3]:Lerp(spots.wait[4], 0.5),
				})
				introBusFor[player] = "waiting"
				task.delay(75, function()
					if player.Parent and introBusFor[player] == "waiting" then
						introBusFor[player] = "sent"
						HallService.welcomeBus(player)
					end
				end)
			else
				HallService.welcomeBus(player)
			end
		end)
	end

	local function onChar(char)
		local cf = PlotService.spawnCFrame(player)
		if cf then
			task.defer(function()
				char:PivotTo(cf)
			end)
		end
	end
	player.CharacterAdded:Connect(onChar)
	if player.Character then onChar(player.Character) end
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end

-- no two surfaces in one plane (they flicker between colours): once the town is up, and again on a
-- school each time it's rebuilt
do
	local Unfight = require(Server.Unfight)
	task.delay(8, function()
		local t = os.clock()
		local n = Unfight.run(workspace)
		print(("[Unfight] %d parts nudged clear of a coplanar neighbour (%.1f s .. %.1f s)"):format(n, t - BOOT_T0, os.clock() - BOOT_T0))
	end)
	Unfight.watch(workspace:WaitForChild("Plots"))
end

Players.PlayerRemoving:Connect(function(player)
	-- a co-op crew first: members go home (or out), a host's crew goes back to their own schools
	CrewService.onRemoving(player)
	PlotService.release(player)
	Data.release(player)
end)

-- the intro's cue for the Welcome Bus (once)
Actions.register("introBus", function(player)
	if introBusFor[player] ~= "waiting" then return { ok = false } end
	introBusFor[player] = "sent"
	HallService.welcomeBus(player)
	return { ok = true }
end)
Players.PlayerRemoving:Connect(function(player) introBusFor[player] = nil end)

-- Studio-only test commands (see DebugBridge)
require(Server.DebugBridge).start({
	state = function(player)
		local p = Data.get(player)
		local students = {}
		for slot, e in p.students do
			students[tostring(slot)] = { id = e.id, grade = e.grade, stored = math.floor(e.stored or 0), arriving = e.arriving }
		end
		return {
			cash = p.cash, income = player:GetAttribute("IncomePerSec"), plot = player:GetAttribute("Plot"),
			tier = p.tier, stars = p.stars, rows = p.rows, desks = PlotService.deskCount(p), upgrades = p.upgrades,
			students = students, mock = Data.usingMock,
		}
	end,
	cash = function(player, amount)
		local p = Data.get(player)
		p.cash = amount
		Data.sync(player)
		return p.cash
	end,
	-- spawn a student of a rarity, parked in front of the player, facing them
	spawnNear = function(player, rarity, studentId)
		local model = HallService.spawnOne(rarity, studentId)
		Walkers.stop(model)
		local root = player.Character.HumanoidRootPart
		local pos = root.Position + root.CFrame.LookVector * 5
		local y = model.PrimaryPart.Position.Y
		model.PrimaryPart.CFrame = CFrame.lookAt(Vector3.new(pos.X, y, pos.Z), Vector3.new(root.Position.X, y, root.Position.Z))
		Factory.play(model, "idle")
		return model.Name
	end,
	-- every student of a rarity standing in a row along +X from (x, z), facing -Z
	lineup = function(player, rarity, x, z, spacing)
		local n = 0
		for _, def in Config.Students do
			if def.rarity == rarity then
				local model = HallService.spawnOne(nil, def.id)
				Walkers.stop(model)
				model:SetAttribute("State", "Lineup")
				local y = model.PrimaryPart.Position.Y
				local at = Vector3.new(x + n * (spacing or 6), y, z)
				model.PrimaryPart.CFrame = CFrame.lookAt(at, at - Vector3.zAxis)
				Factory.play(model, "idle")
				n += 1
			end
		end
		return n
	end,
	-- named students in a row along +X from (x, z), facing -Z (ids: comma-separated): a photo booth
	booth = function(player, ids, x, z, spacing)
		local n = 0
		for id in string.gmatch(ids, "[^,]+") do
			if Config.StudentById[id] then
				local model = HallService.spawnOne(nil, id)
				Walkers.stop(model)
				model:SetAttribute("State", "Lineup")
				local y = model.PrimaryPart.Position.Y
				local at = Vector3.new(x + n * (spacing or 4), y, z)
				model.PrimaryPart.CFrame = CFrame.lookAt(at, at - Vector3.zAxis)
				Factory.play(model, "idle")
				n += 1
			end
		end
		return n
	end,
	clearHall = function()
		for _, m in workspace.Hall:GetChildren() do m:Destroy() end
		return true
	end,
	-- spawn a hall student and enroll it through the normal walk-to-desk path
	enroll = function(player, studentId)
		local model = HallService.spawnOne(nil, studentId)
		HallService.enroll(player, model)
		return model.Name
	end,
	-- steal one of your own students (one-player test of the carry / deliver / drop paths)
	stealSelf = function(player, slot)
		StealService.debugAllowSelf = true
		StealService.begin(player, PlotService.getPlot(player), slot)
		StealService.debugAllowSelf = false
		return { carrying = StealService.isCarrying(player), attr = player:GetAttribute("Carrying"), speed = player.Character.Humanoid.WalkSpeed }
	end,
	cheat = function(player)
		PatrolService.debugCheat(player)
		local p = Data.get(player)
		for slot, e in p.students do
			if e.cheating then return slot end
		end
		return false
	end,
	catch = function(player, slot)
		PatrolService.sendToOffice(player, slot)
		return Data.get(player).students[slot].away == true
	end,
	dealer = function(player)
		return PatrolService.debugDealer(player)
	end,
	bust = function(player)
		return PatrolService.debugBust(player)
	end,
	-- enroll the kid waiting on your bench (reserved for you)
	enrollBench = function(player)
		for _, m in workspace.Hall:GetChildren() do
			if m:GetAttribute("ReservedFor") == player.UserId and m:GetAttribute("State") == "Hall" then
				HallService.enroll(player, m)
				return m:GetAttribute("StudentId")
			end
		end
		return false
	end,
	-- jump the tutorial to a step (by id) and play its scripted moment
	tutorialStep = function(player, id)
		local p = Data.get(player)
		for i, q in Config.Tutorial do
			if q.id == id then
				p.tutorial = i
				p.tutorialId = q.id -- (the save keeps the id: without it the step snaps back)
				p.quests.progress = 0
				require(Server.Signals).fire("questStep", player, id)
				require(Server.QuestService).push(player)
				return i
			end
		end
		return false
	end,
	bonkCrumpet = function(player)
		return RaidService.debugHit(player)
	end,
	raid = function(player, goons, hp)
		return RaidService.debugRaid(player, goons, hp)
	end,
	raidState = function(player)
		return RaidService.debugState(player)
	end,
	raidHit = function(player)
		return RaidService.debugHit(player)
	end,
	factory = function(player)
		return FactoryService.debugState()
	end,
	factoryTake = function(player, i)
		return FactoryService.debugTake(player, i)
	end,
	-- the street at a chapter, without touching the save (nil = back to your real chapter)
	street = function(player, n)
		player:SetAttribute("DebugChapter", n)
		return true
	end,
	secret = function(player, id)
		return SecretService.debugStart(player, id)
	end,
	secretState = function(player)
		return SecretService.debugState(player)
	end,
	vials = function(player, n)
		return SecretService.debugVials(player, n)
	end,
	file = function(player, id)
		return FilesService.debugRead(player, id)
	end,
	lab = function(player)
		return LabService.debugState()
	end,
	openArea = function(player, id)
		return AreaService.open(player, id)
	end,
	areas = function(player)
		local out = {}
		for _, a in Config.Areas do out[a.id] = AreaService.isOpen(player, a.id) end
		return out
	end,
	npcTalk = function(player, id)
		TownNPCService.talk(player, id)
		return TownNPCService.count()
	end,
	tq = function(player)
		return TownQuestService.debugState(player)
	end,
	tqReset = function(player)
		return TownQuestService.debugReset(player)
	end,
	enterHouse = function(player, style)
		return require(Server.HouseService).debugEnter(player, style)
	end,
	teleport = function(player, where)
		require(Server.TownQuestService).teleport(player, where)
		return true
	end,
	setPrestige = function(player, n)
		return require(Server.PrestigeService).debugSet(player, n)
	end,
	hqBadge = function(player)
		return HQService.debugBadge(player, true)
	end,
	hqClear = function(player, n)
		return HQService.debugClear(player, n)
	end,
	hqSearch = function(player, office)
		HQService.search(player, office)
		return HQService.debugState(player)
	end,
	hqSwipe = function(player)
		return HQService.swipe(player)
	end,
	hqPull = function(player, color)
		return HQService.debugPull(player, color)
	end,
	hqHack = function(player, name)
		return HQService.debugHack(player, name)
	end,
	hqFree = function(player, i)
		return HQService.debugFree(player, i)
	end,
	hqVault = function(player)
		return HQService.debugVault(player)
	end,
	hqState = function(player)
		return HQService.debugState(player)
	end,
	hqGo = function(player, n)
		return Actions.invoke(player, "hqGo", n)
	end,
	tqMark = function(player, ...)
		return TownQuestService.debugMark(player, { ... })
	end,
	scene = function(player, id)
		Remotes.Cutscene:FireClient(player, "Play", id)
		return true
	end,
	tqAccept = function(player, id)
		return Actions.invoke(player, "tqAccept", id)
	end,
	tutorialDone = function(player)
		local p = Data.get(player)
		p.tutorial = #Config.Tutorial + 1
		p.tutorialId = "done"
		p.quests.progress = 0
		require(Server.QuestService).push(player)
		require(Server.UnlockService).refresh(player)
		require(Server.Signals).fire("questDone", player)
		return p.tutorial
	end,
	tqAuto = function(player)
		TownQuestService.autoStart(player)
		return TownQuestService.debugState(player)
	end,
	friends = function(player, n)
		return CrewService.debugFriends(player, n)
	end,
	crewJob = function(player)
		return CrewService.debugJob(player)
	end,
	crewState = function(player)
		return CrewService.state(player)
	end,
	rivalScene = function(player)
		Remotes.Cutscene:FireClient(player, "Rival")
		return true
	end,
	rivalTake = function(player, i)
		return RivalService.debugTake(player, i)
	end,
	rivalCalm = function(player, secs)
		return RivalService.debugCalm(secs)
	end,
	labCalm = function(player, secs)
		return LabService.debugCalm(secs)
	end,
	labTake = function(player, i)
		return LabService.debugTake(player, i)
	end,
	gear = function(player, id, n)
		return GearService.give(player, id, n or 1)
	end,
	mission = function(player, id)
		return MissionService.debugStart(player, id)
	end,
	missionState = function(player)
		return MissionService.debugState(player)
	end,
	runnerHit = function(player)
		return MissionService.debugHitRunner(player)
	end,
	-- send one of your seated kids straight to the Factory, as if a goon got away with them
	capture = function(player, slot)
		local p = Data.get(player)
		local e = p.students[slot]
		if not e then return false end
		PlotService.remove(player, slot)
		p.captured = p.captured or {}
		table.insert(p.captured, { id = e.id, grade = e.grade })
		require(Server.Signals).fire("kidCaptured", player, Config.StudentById[e.id])
		return #p.captured
	end,
	-- the purchase grant paths without Robux (Studio only)
	vex = function(player)
		return StoryService.debugVex()
	end,
	-- jump to a chapter of the Principal's Requests with nothing done
	chapter = function(player, n)
		return ChapterService.debugSet(player, n)
	end,
	chapterState = function(player)
		return ChapterService.state(player)
	end,
	dailyFinish = function(player, n)
		return DailyService.debugFinish(player, n)
	end,
	tickets = function(player, n)
		return TicketService.debugGive(player, n)
	end,
	diplomas = function(player, n)
		return AlumniService.debugGive(player, n)
	end,
	finale = function(player)
		require(Server.BoardService).finale(player)
		return true
	end,
	-- the finale as a promotion starts it (pending until Tiny Vex is on the bench)
	finalePending = function(player, delay)
		local p = Data.get(player)
		p.finaleSeen = nil
		p.finalePending = true
		require(Server.BoardService).finale(player, delay or 0)
		return true
	end,
	flags = function(player)
		local p = Data.get(player)
		return { finalePending = p.finalePending, finaleSeen = p.finaleSeen, diplomas = p.diplomas, alumni = p.alumni, reviewing = p.reviewing, pendingBench = p.pendingBench }
	end,
	graduate = function(player, slot)
		AlumniService.graduate(player, PlotService.getPlot(player), slot)
		return { diplomas = player:GetAttribute("Diplomas"), still = Data.get(player).students[slot] ~= nil }
	end,
	-- pretend today's Daily Requests were dealt yesterday (tests the UTC rollover)
	dailyAge = function(player)
		local p = Data.get(player)
		if p.dailyQ then p.dailyQ.day -= 1 end
		return p.dailyQ ~= nil
	end,
	-- enroll a kid who came off a named special bus (still in the hall)
	enrollBus = function(player, kind)
		for _, m in workspace.Hall:GetChildren() do
			if m:GetAttribute("Bus") == kind and m:GetAttribute("State") == "Hall" then
				HallService.enroll(player, m)
				return m:GetAttribute("StudentId")
			end
		end
		return false
	end,
	quiz = function(player)
		QuizService.ask()
		return true
	end,
	beam = function(player)
		require(Server.EventService).beamTick(true)
		task.wait(1)
		local out = {}
		for slot, e in Data.get(player).students do out[tostring(slot)] = e.id .. ":" .. e.grade end
		return out
	end,
	candy = function(player, amount)
		local p = Data.get(player)
		p.candy = amount
		player:SetAttribute("Candy", amount)
		return amount
	end,
	skipPlaytime = function(player, minutes)
		return RewardService.debugSkip(player, minutes)
	end,
	resetDaily = function(player, dayOffset, streak)
		local p = Data.get(player)
		p.login = { day = math.floor(os.time() / 86400) + (dayOffset or -1), streak = streak or 0 }
		return p.login
	end,
	grantPass = function(player, key)
		return MonetizationService.grantPass(player, key)
	end,
	grantProduct = function(player, key)
		return MonetizationService.grantProduct(player, key)
	end,
	letterReady = function(player, rarity)
		return LetterService.debugReady(player, rarity)
	end,
	dropCarry = function(player)
		StealService.drop(player, "debug drop")
		return StealService.isCarrying(player)
	end,
	rows = function(player, a, b, c)
		local p = Data.get(player)
		p.rows = { a, b, c }
		PlotService.rebuild(player)
		return PlotService.deskCount(p)
	end,
	-- where a model is right now (x, y, z) and whether it is still walking
	where = function(player, name)
		local m = workspace.Hall:FindFirstChild(name) or workspace:FindFirstChild(name, true)
		if not m or not m.PrimaryPart then return "gone" end
		local p = m.PrimaryPart.Position
		return { math.floor(p.X * 10) / 10, math.floor(p.Y * 10) / 10, math.floor(p.Z * 10) / 10, Walkers.isWalking(m) }
	end,
	tp = function(player, x, y, z, lookX, lookZ)
		local at = Vector3.new(x, y, z)
		player.Character:PivotTo(CFrame.lookAt(at, Vector3.new(lookX or x, y, lookZ or z - 1)))
		return true
	end,
	-- give the player a student straight into a free desk
	give = function(player, studentId, grade)
		local p = Data.get(player)
		local slot = PlotService.freeSlot(player)
		if not slot then return "full" end
		p.students[slot] = { id = studentId, grade = grade or "Normal", stored = 0 }
		p.index[studentId .. "|" .. (grade or "Normal")] = true
		PlotService.place(player, slot)
		PlotService.updateIncome(player)
		return slot
	end,
	action = function(player, name, ...)
		return Actions.invoke(player, name, ...)
	end,
	-- the First Morning and Chapter 1, one step at a time (what the prompts would do)
	ch1 = function(player, what, arg)
		local QuestService = require(Server.QuestService)
		local p = Data.get(player)
		if what == "state" then
			local s = QuestService.state(player)
			local seated = 0
			for _ in p.students do seated += 1 end
			return {
				id = p.tutorialId, step = s and s.step, steps = s and s.steps, part = s and s.part, short = s and s.short,
				progress = s and s.progress, count = s and s.count, guide = s and s.guide, reward = s and s.reward,
				cash = math.floor(p.cash), seated = seated, desks = PlotService.deskCount(p), pick = p.scholarPick,
				others = p.scholarOthers, missions = p.missions, inTut = player:GetAttribute("InTutorial"),
				giver = player:GetAttribute("MissionGiver"), ready = player:GetAttribute("MissionReady"),
				mission = player:GetAttribute("Mission"), raid = player:GetAttribute("Raid"),
				ui = { Shop = player:GetAttribute("UI_Shop"), Upgrades = player:GetAttribute("UI_Upgrades"), Board = player:GetAttribute("UI_Board"), Name = player:GetAttribute("UI_Name") },
			}
		elseif what == "welcome" then
			local n = 0
			for _, m in workspace.Hall:GetChildren() do
				if n < (arg or 6) and m:GetAttribute("ReservedFor") == player.UserId and m:GetAttribute("Welcome") and not m:GetAttribute("Pick") and m:GetAttribute("State") == "Hall" then
					HallService.enroll(player, m)
					n += 1
				end
			end
			return n
		elseif what == "picks" then
			local out = {}
			for _, m in workspace.Hall:GetChildren() do
				if m:GetAttribute("Pick") and m:GetAttribute("State") == "Hall" then table.insert(out, m:GetAttribute("StudentId")) end
			end
			return out
		elseif what == "pick" then
			for _, m in workspace.Hall:GetChildren() do
				if m:GetAttribute("Pick") and m:GetAttribute("State") == "Hall" and (not arg or m:GetAttribute("StudentId") == arg) then
					HallService.enroll(player, m)
					return m:GetAttribute("StudentId")
				end
			end
			return false
		elseif what == "collect" then
			for slot in p.students do PlotService.collect(player, slot) end
			return true
		elseif what == "lock" then
			return require(Server.GateService).lock(player)
		elseif what == "row" then
			return require(Server.UpgradeService).buyRow(player, arg or 1)
		elseif what == "talk" then
			return require(Server.MissionService).giverTalk(player, arg)
		elseif what == "start" then
			return require(Server.MissionService).start(player, arg)
		elseif what == "sewer" then
			return require(Server.SewerHeist).debugDo(player, arg)
		elseif what == "boss" then
			return require(Server.QuestGoons).debugHitBoss(player)
		elseif what == "demo" then
			return RaidService.lockDemo(player)
		elseif what == "plans" then
			return FactoryService.debugTakePlans(player)
		elseif what == "calm" then
			return { factory = FactoryService.debugCalm(arg or 40), vexprep = RivalService.debugCalm(arg or 40) }
		elseif what == "bench" then
			for _, m in workspace.Hall:GetChildren() do
				if m:GetAttribute("ReservedFor") == player.UserId and m:GetAttribute("OnBench") and m:GetAttribute("State") == "Hall" and (not arg or m:GetAttribute("StudentId") == arg) then
					HallService.enroll(player, m)
					return m:GetAttribute("StudentId")
				end
			end
			return false
		end
		return "unknown: " .. tostring(what)
	end,
	roundTrip = function(player)
		local before = Data.get(player)
		local cashBefore, tierBefore, n = before.cash, before.tier, 0
		for _ in before.students do n += 1 end
		local after = Data.roundTrip(player)
		local m = 0
		for _ in after.students do m += 1 end
		return { cashBefore = cashBefore, cashAfter = after.cash, tierBefore = tierBefore, tierAfter = after.tier, studentsBefore = n, studentsAfter = m }
	end,
	specialBus = function(player, kind)
		task.spawn(HallService.specialBus, kind)
		return true
	end,
	setTier = function(player, tier, stars)
		local p = Data.get(player)
		p.tier = tier
		p.stars = stars or 0
		Data.sync(player)
		PlotService.applyFloors(player)
		PlotService.updateIncome(player)
		return { tier = p.tier, floors = PlotService.floorsOf(p), desks = PlotService.deskCount(p) }
	end,
	recessNow = function()
		workspace:SetAttribute("RecessAt", workspace:GetServerTimeNow())
		return true
	end,
})
