-- ServerScriptService.Server.SewerHeist
-- Chapter 1's way into Vex Prep: the storm sewer under Recess Row (TownSewer builds it).
--   the pothole      "Climb down" on the hole in the east road drops you at the bottom of its ladder;
--                    "Climb up" on that ladder puts you back on the road
--   the office ladder at the far end of the main tunnel, up to a grate in the Vex Prep headmaster's
--                    office floor. Bolted, except on the Vex Prep Job; you hear him snoring
--   "Down the pothole" (To-Do k11_pothole): reaching the office ladder sets p.sewerScouted. Janitor Stan's
--                    old hideout (the west dead end) has his stash: 3 Smoke Bombs, once
--   the Vex Prep Job (Config.Missions.k_heist, MissionService kind "sewer"):
--     1. down the pothole, through the tunnels, up the ladder into the office (VexPrepHeist lets you in)
--     2. Headmaster Grindle wakes up on his hoverboard: a boss (QuestGoons.boss); knocked out, he drops
--        the board: take it (GearService Hoverboard, yours to keep). He stays down for the rest of it
--     3. through the office door into the Great Hall: at Desk 5 sits one of the two stars you passed on
--        in the First Morning, now in a Vex Prep blazer. Hold E to take them. A monitor who spots you
--        gives chase; if one catches you, you're back in the office and they're back at the desk (the
--        monitors never come into the office)
--     4. out with them: back down the grate and up out of the pothole, or straight out of the grounds.
--        Won. Vex finds the empty desk ("PRINCIPAAAAL!"), and the kid waits on your bench until after the
--        School Board review
-- Every stage sets the player's MissionTarget, which the guide's arrow and trail point at.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Factory = require(script.Parent.StudentFactory)
local Sewer = require(script.Parent.TownSewer)

local SewerHeist = {}

local FLOOR = 0.9 -- (Vex Prep's floor)
local UP_ROAD = Vector3.new(Sewer.POTHOLE.X + 5, 3.5, Sewer.POTHOLE.Z) -- beside the pothole, on the road
-- (both landings are a camera's length from the ladder you came down, facing away from it, so the
-- camera behind you is in the tunnel, not squeezed behind the rungs)
local DOWN_POTHOLE = Vector3.new(Sewer.ENTRY.X, Sewer.Y + 3.2, Sewer.ENTRY.Z - 9) -- in the tunnel, off the ladder
local OFFICE_LADDER = Vector3.new(Sewer.EXIT.X, Sewer.Y + 3.2, Sewer.EXIT.Z + 10) -- in the tunnel, off the office ladder
local IN_OFFICE = Vector3.new(Sewer.GRATE.X, FLOOR + 3, Sewer.GRATE.Z + 2.5) -- standing by the grate
local BOSS_AT = Vector3.new(427, FLOOR, -150.5) -- in front of the office desk
local TARGET_DESK = 5 -- (Vex Prep's Desk 5: x 397, z -130)
-- where the guide points at each stage
local AT_POTHOLE = Vector3.new(Sewer.POTHOLE.X, 0.8, Sewer.POTHOLE.Z)
local AT_OFFICE_LADDER = Vector3.new(Sewer.EXIT.X, Sewer.Y + 1, Sewer.EXIT.Z - 4)
local AT_POTHOLE_LADDER = Vector3.new(Sewer.ENTRY.X, Sewer.Y + 1, Sewer.ENTRY.Z + 2)
local AT_GRATE = Vector3.new(Sewer.GRATE.X, FLOOR + 0.5, Sewer.GRATE.Z)
local AT_DESK = Vector3.new(397, FLOOR + 2, -127.6)

local jobs = {} -- [player] = the Vex Prep Job in progress
local rootOf = function(player)
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function prompt(parent, action, object, hold, color)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object or ""
	pp.HoldDuration = hold or 0
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = 9
	pp.KeyboardKeyCode = Enum.KeyCode.E
	if color then pp:SetAttribute("Color", color) end
	pp.Parent = parent
	return pp
end

local function tp(player, pos, look)
	local char = player.Character
	if not char then return end
	char:PivotTo(CFrame.lookAt(pos, pos + (look or Vector3.new(0, 0, -1))))
	Remotes.Sfx:FireClient(player, "Whoosh")
end

local function call(player, speaker, portrait, line)
	Remotes.Push:FireClient(player, "missionTalk", { call = true, lines = { { speaker, portrait, line } } })
end

local function phase(player, text)
	Remotes.Push:FireClient(player, "mission", { state = "phase", text = text })
end

---------------------------------------------------------------------------
-- the Job
---------------------------------------------------------------------------
local function clearKid(job)
	if job.carried then job.carried:Destroy() end
	job.carried = nil
end

-- the star at Desk 5, in a Vex Prep blazer and glowing
local function seatTarget(job)
	local RivalService = require(script.Parent.RivalService)
	local d = RivalService.desk(TARGET_DESK)
	if not d then return end
	job.desk = d
	if d.kid then d.kid:Destroy() d.kid = nil end
	d.prompt.Enabled = false
	local def = Config.StudentById[job.kidId] or Config.StudentById.ChessChampion
	local kid = Factory.build(def, "Normal")
	for _, x in kid:GetDescendants() do
		if x:IsA("BillboardGui") then x:Destroy() end
	end
	-- (the blazer: Vex Prep purple on the shirt)
	for _, x in kid:GetDescendants() do
		if x:IsA("BasePart") and (x.Name == "UpperTorso" or x.Name == "LowerTorso" or x.Name:find("Arm")) and not x.Name:find("Hand") then
			x.Color = Color3.fromRGB(92, 40, 132)
		end
	end
	local hum = kid:FindFirstChildOfClass("Humanoid")
	local seatTop = FLOOR + 2.3
	local y = seatTop + kid.PrimaryPart.Size.Y * 0.5 + (hum and hum.HipHeight * 0.1 or 0)
	kid.PrimaryPart.CFrame = CFrame.new(d.x, y, d.z + 2.4)
	kid.Name = "HeistStar"
	local glow = Instance.new("Highlight")
	glow.FillColor = Color3.fromRGB(255, 220, 120)
	glow.FillTransparency = 0.7
	glow.OutlineColor = Color3.new(1, 1, 1)
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.Parent = kid
	kid.Parent = d.model
	Factory.play(kid, "sit")
	job.seated = kid
	local pp = prompt(kid.PrimaryPart, "Take " .. def.name, "Hold still...", 2, Color3.fromRGB(255, 200, 90))
	pp.MaxActivationDistance = 7
	pp.Triggered:Connect(function(who)
		if who == job.player then SewerHeist.take(job) end
	end)
	job.seatedPrompt = pp
end

local function restoreDesk(job)
	if job.seated then job.seated:Destroy() job.seated = nil end
	local d = job.desk
	if d then
		local RivalService = require(script.Parent.RivalService)
		RivalService.reseat(d)
	end
end

function SewerHeist.take(job)
	local player = job.player
	if job.carried or not job.seated then return end
	local char = player.Character
	local root = rootOf(player)
	if not root then return end
	local def = Config.StudentById[job.kidId] or Config.StudentById.ChessChampion
	job.seated:Destroy()
	job.seated = nil
	local kid = Factory.build(def, "Normal")
	Factory.setMode(kid, "carried")
	local bb = kid:FindFirstChild("Head") and kid.Head:FindFirstChild("Tag")
	local price = bb and bb:FindFirstChild("Price")
	if price then price.Text = "YOU CAME BACK FOR ME?!" price.TextColor3 = Color3.fromRGB(255, 230, 120) end
	Factory.carryOverhead(char, kid)
	job.carried = kid
	player:SetAttribute("Heist", def.name)
	require(script.Parent.StealService).setSpeed(player)
	Remotes.Notify:FireClient(player, ("You've got %s! Get them out: back to the grate in the office, or out of the grounds!"):format(def.name), "good")
	phase(player, "Get them out! Back through the office door to the grate. Stay out of the monitors' sight!")
end

-- a monitor saw you (or caught you): back to the office, the kid back at the desk
local function caught(job, why)
	local player = job.player
	local had = job.carried ~= nil
	clearKid(job)
	player:SetAttribute("Heist", nil)
	require(script.Parent.StealService).setSpeed(player)
	if had then seatTarget(job) end
	Remotes.Sfx:FireClient(player, "Bell")
	Remotes.Notify:FireClient(player, why or "\u{1F514} A MONITOR SAW YOU! Back to the office...", "bad")
	tp(player, IN_OFFICE, Vector3.new(0, 0, 1))
	player:SetAttribute("Stunned", true)
	require(script.Parent.StealService).setSpeed(player)
	task.delay(1.5, function()
		if not player.Parent then return end
		player:SetAttribute("Stunned", nil)
		require(script.Parent.StealService).setSpeed(player)
	end)
end

local function endJob(player, won)
	local job = jobs[player]
	if not job then return end
	jobs[player] = nil
	clearKid(job)
	restoreDesk(job)
	if job.boss and job.boss.Parent then job.boss:Destroy() end
	if job.board and job.board.Parent then job.board:Destroy() end
	if player.Parent then
		player:SetAttribute("VexPrepHeist", nil)
		player:SetAttribute("Heist", nil)
		player:SetAttribute("MissionTarget", nil)
		require(script.Parent.StealService).setSpeed(player)
	end
	if job.done then job.done(won) end
end

-- the Headmaster's hoverboard, dropped where he went down
local function dropBoard(job, at)
	local GearService = require(script.Parent.GearService)
	-- (the same board you ride, hovering over the floor and turning slowly, so it reads as a prize)
	local board = GearService.buildBoard()
	board.Name = "DroppedHoverboard"
	for _, b in board:GetDescendants() do
		if b:IsA("BasePart") then b.Anchored = true end
	end
	local base = CFrame.new(at.X, FLOOR + 1.6, at.Z)
	board:PivotTo(base)
	board.Parent = workspace
	job.board = board
	local deck = board.PrimaryPart
	task.spawn(function()
		local t0 = os.clock()
		while board.Parent do
			local t = os.clock() - t0
			board:PivotTo(base * CFrame.new(0, math.sin(t * 2.4) * 0.25, 0) * CFrame.Angles(0, t * 1.2, 0))
			task.wait()
		end
	end)
	phase(job.player, "Grab the Headmaster's hoverboard!")
	local pp = prompt(deck, "Take the hoverboard", "Headmaster's Hoverboard", 0.5, Color3.fromRGB(150, 110, 255))
	pp.Triggered:Connect(function(who)
		if who ~= job.player then return end
		board:Destroy()
		GearService.give(who, "Hoverboard")
		Remotes.Announce:FireClient(who, "\u{1F6F9} HOVERBOARD!", Color3.fromRGB(150, 110, 255))
		Remotes.Notify:FireClient(who, "It's yours to keep: equip it to ride 60% faster. Now find that student!", "good")
		phase(who, "Sneak into the Great Hall: Desk 5, on the left. Monitors who see you give chase!")
		job.hasBoard = true
	end)
end

local function wakeBoss(job)
	if job.bossDown or job.bossUp then return end
	job.bossUp = true
	local player = job.player
	local QuestGoons = require(script.Parent.QuestGoons)
	QuestGoons.boss(player, {
		look = "headmaster", pos = BOSS_AT, hp = 4, speed = 13, name = "HEADMASTER GRINDLE",
		lines = { "WHO'S IN MY OFFICE?!", "Detention! FOREVER!", "Nobody touches my students!" },
		ouch = { "My BOARD!", "OW! My spectacles!", "That's a REFERRAL!" },
		surrender = "Fine! Take the silly thing!",
		keep = function() return jobs[player] == job end,
		onDone = function()
			job.bossDown = true
			local root = rootOf(player)
			dropBoard(job, root and (root.Position + (BOSS_AT - root.Position).Unit * 3) or BOSS_AT)
		end,
	})
	phase(player, "Knock out Headmaster Grindle!")
end

function SewerHeist.start(player, m, done)
	local p = Data.get(player)
	if not p then return end
	local others = p.scholarOthers or {}
	jobs[player] = { player = player, m = m, done = done, kidId = others[1] or "ChessChampion" }
	phase(player, "Down the pothole by Vex Prep, then up the ladder under the Headmaster's office")
end

-- the office ladder, climbed: on the Job you come up through the grate; otherwise it's bolted
local function officeLadder(player)
	local job = jobs[player]
	if not job then
		Remotes.Notify:FireClient(player, "The grate above is bolted shut. Somebody up there is snoring...", "info")
		return
	end
	player:SetAttribute("VexPrepHeist", true)
	if not job.seated and not job.carried then seatTarget(job) end
	tp(player, IN_OFFICE, Vector3.new(-1, 0, 0))
	if not job.bossDown then
		phase(player, "Shh... the Headmaster is asleep at his desk.")
		task.delay(1.6, function() if jobs[player] == job then wakeBoss(job) end end)
	elseif job.hasBoard then
		phase(player, "Sneak into the Great Hall. Desk 5, on the left.")
	end
end

-- the grate in the office floor: back down, with or without the kid
local function grateDown(player)
	local job = jobs[player]
	if not job then return end
	tp(player, OFFICE_LADDER, Vector3.new(0, 0, 1))
	if job.carried then
		phase(player, "Through the tunnels and out of the pothole with them!")
		job.below = true
	end
end

-- out with the kid: the Job is done
local function escape(job)
	local player = job.player
	local def = Config.StudentById[job.kidId] or Config.StudentById.ChessChampion
	clearKid(job)
	player:SetAttribute("Heist", nil)
	player:SetAttribute("VexPrepHeist", nil)
	require(script.Parent.StealService).setSpeed(player)
	local LetterService = require(script.Parent.LetterService)
	local host = Data.hostOf(player)
	local model = LetterService.deliver(host, def, true, "Normal", "NEW KID: after the Board!")
	if model then
		model:SetAttribute("HoldUntilTier", 2)
	else
		local p = Data.get(host)
		if p then
			p.pendingBench = p.pendingBench or {}
			table.insert(p.pendingBench, { id = def.id, grade = "Normal" })
		end
	end
	Remotes.Cutscene:FireClient(player, "VexPA", { name = def.name })
	endJob(player, true)
	task.delay(7, function()
		if player.Parent then
			Remotes.Announce:FireClient(player, "CHAPTER 1 COMPLETE!", Color3.fromRGB(255, 170, 60))
			Remotes.Notify:FireClient(player, "Now face the School Board: the Board button is waiting!", "good")
		end
	end)
end

local function potholeUp(player)
	tp(player, UP_ROAD, Vector3.new(0, 0, 1))
	local job = jobs[player]
	if job and job.carried then escape(job) end
end

local function potholeDown(player)
	local QuestService = require(script.Parent.QuestService)
	if not QuestService.atOrPast(player, "k11_pothole") and not jobs[player] then
		Remotes.Notify:FireClient(player, "\u{1F6A7} Looks deep... and it smells. Maybe later.", "info")
		return
	end
	tp(player, DOWN_POTHOLE, Vector3.new(0, 0, -1))
end

---------------------------------------------------------------------------
function SewerHeist.start_service()
	-- the prompts on what TownSewer built
	task.spawn(function()
		local town = workspace:WaitForChild("Town", 60)
		if not town then return end
		local found = { hole = false, pothole = false, office = false }
		for _ = 1, 60 do
			for _, d in town:GetDescendants() do
				if d:IsA("BasePart") then
					if d:GetAttribute("SewerDown") and not found.hole then
						found.hole = true
						prompt(d, "Climb down", "The pothole", 0.3, Color3.fromRGB(255, 150, 60)).Triggered:Connect(potholeDown)
					elseif d:GetAttribute("SewerLadder") == "Pothole" and not found.pothole then
						found.pothole = true
						prompt(d, "Climb up", "Ladder", 0.3).Triggered:Connect(potholeUp)
					elseif d:GetAttribute("SewerLadder") == "Office" and not found.office then
						found.office = true
						prompt(d, "Climb up", "Ladder to the grate", 0.3).Triggered:Connect(officeLadder)
					elseif d.Name == "StanCrate" and not found.stash then
						found.stash = true
						prompt(d, "Take Stan's stash", "Janitor Stan's hideout", 0.5, Color3.fromRGB(120, 200, 255)).Triggered:Connect(function(player)
							local p = Data.get(player)
							if not p then return end
							if p.stanStash then
								Remotes.Notify:FireClient(player, "Just an old sandwich left. Ew.", "info")
								return
							end
							p.stanStash = true
							require(script.Parent.GearService).give(player, "SmokeBomb", 3)
							Remotes.Notify:FireClient(player, "\u{1F4A8} Stan's stash: 3 Smoke Bombs! (Monitors lose you in the smoke)", "good")
						end)
					end
				end
			end
			if found.hole and found.pothole and found.office then break end
			task.wait(1)
		end
	end)
	-- the grate in the Headmaster's office floor (Vex Prep's floor has no hole: a grate over one)
	do
		local grate = Instance.new("Part")
		grate.Name = "OfficeGrate"
		grate.Size = Vector3.new(3.4, 0.12, 3.4)
		grate.CFrame = CFrame.new(Sewer.GRATE.X, FLOOR + 0.07, Sewer.GRATE.Z)
		grate.Color = Color3.fromRGB(40, 40, 46)
		grate.Material = Enum.Material.DiamondPlate
		grate.Anchored, grate.CanCollide = true, false
		grate.Parent = workspace
		for k = -1, 1 do
			local bar = Instance.new("Part")
			bar.Name = "GrateBar"
			bar.Size = Vector3.new(3.2, 0.14, 0.28)
			bar.CFrame = grate.CFrame * CFrame.new(0, 0.05, k * 1.05)
			bar.Color = Color3.fromRGB(70, 70, 78)
			bar.Material = Enum.Material.Metal
			bar.Anchored, bar.CanCollide = true, false
			bar.Parent = grate
		end
		local pp = prompt(grate, "Climb down", "The grate", 0.3, Color3.fromRGB(255, 150, 60))
		pp.Triggered:Connect(grateDown)
	end
	-- K11: reaching the office ladder counts as scouting the sewer; on the Job, a monitor seeing you
	-- with the kid sends you back
	local RivalService = require(script.Parent.RivalService)
	RivalService.heistCatch = function(player)
		local job = jobs[player]
		if not job then return false end
		caught(job, "\u{1F514} A monitor caught you! Back to the office...")
		return true
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then return end
		acc = 0
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if not root then continue end
			local pos = root.Position
			if pos.Y < -30 and (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(Sewer.EXIT.X, 0, Sewer.EXIT.Z)).Magnitude < 12 then
				local p = Data.own(player)
				if p and not p.sewerScouted then
					p.sewerScouted = true
					-- (not on the Job itself: "we go tonight" is old news by then)
					if not jobs[player] then
						call(player, "JANITOR STAN", "Stan", "Hear that? Snoring. Ha! Tell the old man. We go tonight.")
					end
					Signals.fire("sewerScouted", player)
					task.defer(function() pcall(require(script.Parent.QuestService).recheck, player) end)
				end
			end
			local job = jobs[player]
			if job then
				local above = pos.Y > -10
				-- out of the grounds with the kid (the front way): that's out
				if job.carried and above and not RivalService.inLot(pos) then
					escape(job)
					continue
				end
				-- a monitor has seen you with the kid: a warning, once per sighting (a catch sends you back)
				local spotted = job.carried and above and player:GetAttribute("Spotted") == true
				if spotted and not job.warned then
					job.warned = true
					Remotes.Sfx:FireClient(player, "Bell")
					Remotes.Notify:FireClient(player, "\u{1F514} A monitor spotted you! Run for the office: they can't follow you in there!", "bad")
				elseif not spotted then
					job.warned = nil
				end
				-- what the guide points at now
				local goal
				if job.carried then
					goal = above and AT_GRATE or AT_POTHOLE_LADDER
				elseif not player:GetAttribute("VexPrepHeist") then
					goal = above and AT_POTHOLE or AT_OFFICE_LADDER
				elseif not above then
					goal = AT_OFFICE_LADDER
				elseif not job.bossDown then
					goal = BOSS_AT + Vector3.new(0, 2, 0)
				elseif job.board and job.board.Parent then
					goal = job.board:GetPivot().Position
				else
					goal = AT_DESK
				end
				if player:GetAttribute("MissionTarget") ~= goal then player:SetAttribute("MissionTarget", goal) end
			end
		end
	end)
	local function watch(player)
		player.CharacterAdded:Connect(function()
			local job = jobs[player]
			if job and job.carried then
				-- (fainted with the kid: they go back to the desk; the Headmaster stays down)
				clearKid(job)
				player:SetAttribute("Heist", nil)
				seatTarget(job)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do watch(player) end
	Players.PlayerRemoving:Connect(function(player) endJob(player, false) end)
end

-- (MissionService.finish(false) or a leave: tidy up)
function SewerHeist.stop(player) endJob(player, false) end
function SewerHeist.debug(player)
	local job = jobs[player]
	return job and { boss = job.bossDown, board = job.hasBoard, carrying = job.carried ~= nil, kid = job.kidId } or nil
end
-- Studio: what the prompts do ("down", "up", "office", "grate", "take", "board", "state")
function SewerHeist.debugDo(player, what)
	local job = jobs[player]
	if what == "down" then potholeDown(player)
	elseif what == "up" then potholeUp(player)
	elseif what == "office" then officeLadder(player)
	elseif what == "grate" then grateDown(player)
	elseif what == "take" then
		if job then SewerHeist.take(job) end
	elseif what == "board" then
		if job and job.board and job.board.Parent then
			job.board:Destroy()
			require(script.Parent.GearService).give(player, "Hoverboard")
			job.hasBoard = true
		end
	end
	return SewerHeist.debug(player) or { job = false }
end

return SewerHeist
