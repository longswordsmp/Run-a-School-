-- ServerScriptService.Server.Main
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = script.Parent
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

Factory.preload()
PlotService.start()
UpgradeService.start()
GateService.start()
HallService.start()
TeacherService.start()
CampusService.start()
StealService.start()
QuestService.start()
PatrolService.start()
EventService.startLoop()
LetterService.start()

local function onPlayer(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = ls
	ls.Parent = player

	local p = Data.load(player)
	if not p then return end
	PlotService.assign(player)
	UpgradeService.applyAll(player)
	if p.offlineEarned and p.offlineEarned > 0 then
		Remotes.Push:FireClient(player, "offline", { amount = p.offlineEarned, away = p.offlineAway })
	end

	-- a brand-new principal gets the intro and the Welcome Bus
	-- (Studio tests can skip it with the ServerStorage attribute SkipIntro)
	local skip = game:GetService("RunService"):IsStudio() and game.ServerStorage:GetAttribute("SkipIntro")
	if p.tutorial == 1 and p.stats.enrolled == 0 and not p.introSeen and not skip then
		p.introSeen = true
		task.delay(2.5, function()
			if not player.Parent then return end
			Remotes.Cutscene:FireClient(player, "Intro", { name = PlotService.schoolName(player) })
			task.wait(14)
			task.spawn(HallService.specialBus, "Welcome")
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

Players.PlayerRemoving:Connect(function(player)
	PlotService.release(player)
	Data.release(player)
end)

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
				p.quests.progress = 0
				require(Server.Signals).fire("questStep", player, id)
				require(Server.QuestService).push(player)
				return i
			end
		end
		return false
	end,
	bonkCrumpet = function(player)
		return PatrolService.debugBonkCrumpet(player)
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
