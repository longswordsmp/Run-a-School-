-- ServerScriptService.Server.HQService
-- Getting through VexCorp HQ (TownHQ builds the floors; docs/STORY.md "The HQ floors"):
--   the elevators  every part tagged HQElevator (the lobby's staff elevator, each floor's bank and
--                  service elevator) opens the floor panel (Push "hqElevator"); the ride is the fade
--                  in Areas.client; you can go to the lobby, any floor you've reached, and the next one
--   access         floor 2 needs your VexCorp Visitor Badge (story quest S18, or own.hq.badge); each
--                  floor after that needs the one below cleared
--   progress       own.hq = { badge, cleared = { [n] = true } }; clearing a floor fires the signal
--                  "hqFloor" (n) for the story quests
--   floor 2        the keycard is in one of three managers' offices (a different one each visit);
--                  office security patrols the aisles (Guards: sight cones, the Ruler stuns them);
--                  caught = walked back to the elevators without the keycard; the keycard opens the
--                  security door, which clears the floor
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)
local HQ = require(script.Parent.TownHQ)
local Guards = require(script.Parent.Guards)
local StealService = require(script.Parent.StealService)
local Industrial = require(script.Parent.TownIndustrial)

local HQService = {}
local state = {} -- player -> { keycard = bool, office = name }
local squads = {} -- floor -> Guards

local LOBBY = Industrial.ELEVATOR_TOP + Vector3.new(0, 0, -24) -- in front of the staff elevator

local function hqOf(player)
	local own = Data.own(player)
	if not own then return nil end
	own.hq = own.hq or {}
	own.hq.cleared = own.hq.cleared or {}
	return own.hq
end

function HQService.hasBadge(player)
	local hq = hqOf(player)
	if not hq then return false end
	if hq.badge then return true end
	local own = Data.own(player)
	return own and own.tq and own.tq.done and own.tq.done.S18 == true
end

function HQService.cleared(player, n)
	local hq = hqOf(player)
	return hq and hq.cleared[n] == true
end

-- may this player ride to floor n?
function HQService.canGo(player, n)
	if n == 1 then return true end
	if not HQ.FLOORS[n] then return false end
	if not HQService.hasBadge(player) then return false, "You need a VexCorp Visitor Badge." end
	if n == 2 then return true end
	if HQService.cleared(player, n - 1) then return true end
	return false, ("Clear floor %d first."):format(n - 1)
end

local function floorList(player)
	local out = { { n = 1, name = "LOBBY", open = true } }
	for n = 2, 7 do
		local ok, why = HQService.canGo(player, n)
		table.insert(out, { n = n, name = HQ.FLOORS[n].name, open = ok, why = why, cleared = HQService.cleared(player, n) })
	end
	return out
end

local function msg(player, text, kind)
	Remotes.Push:FireClient(player, "hqMsg", { text = text, kind = kind })
end

local function ride(player, n)
	local char = player.Character
	if not char then return end
	Remotes.Push:FireClient(player, "elevator", { dir = "hq", floor = n, name = n == 1 and "LOBBY" or HQ.FLOORS[n].name })
	task.wait(0.9)
	if not player.Parent or not char.Parent then return end
	if n == 1 then
		char:PivotTo(CFrame.lookAt(LOBBY + Vector3.new(0, 0.5, 0), LOBBY + Vector3.new(-10, 0.5, 0)))
	else
		char:PivotTo(HQ.arrival(n))
		HQService.arrive(player, n)
	end
end

-- arriving on a floor sets up that player's run of it
function HQService.arrive(player, n)
	local s = state[player] or {}
	state[player] = s
	if n == 2 then
		s.keycard = false
		player:SetAttribute("HQKeycard", nil)
		local offices = { "REGIONAL MANAGER", "ASSISTANT TO THE MANAGER", "VP OF WORKSHEETS" }
		s.office = offices[math.random(#offices)]
		s.searched = {}
	end
	player:SetAttribute("HQFloor", n)
	Remotes.Push:FireClient(player, "hqArrive", { floor = n, name = HQ.FLOORS[n].name, cleared = HQService.cleared(player, n) })
end

function HQService.clear(player, n)
	local hq = hqOf(player)
	if not hq then return end
	local first = not hq.cleared[n]
	hq.cleared[n] = true
	Signals.fire("hqFloor", player, n)
	Remotes.Push:FireClient(player, "hqCleared", { floor = n, name = HQ.FLOORS[n].name, first = first, next = HQ.FLOORS[n + 1] and HQ.FLOORS[n + 1].name })
	Remotes.Sfx:FireClient(player, "StingParty")
	task.spawn(Data.save, player)
end

---------------------------------------------------------------------------
-- floor 2
---------------------------------------------------------------------------
local QUIPS = {
	"Just staples, a stress ball and half a tuna sandwich.",
	"A mug that says WORLD'S OKAYEST MANAGER. No keycard.",
	"A drawer full of red pens. Hundreds of them.",
	"A framed photo of Dr. Vex. She's frowning in it too.",
}

local function openDoor(door)
	if door:GetAttribute("Open") then return end
	door:SetAttribute("Open", true)
	local home = door.CFrame
	door.CanCollide = false
	TweenService:Create(door, TweenInfo.new(1.2, Enum.EasingStyle.Quad), { CFrame = home + Vector3.new(0, 9.6, 0) }):Play()
	task.delay(7, function()
		TweenService:Create(door, TweenInfo.new(1.2, Enum.EasingStyle.Quad), { CFrame = home }):Play()
		task.wait(1.2)
		door.CanCollide = true
		door:SetAttribute("Open", nil)
	end)
end

local function floorPrompt(parent, action, object, hold, color)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = 8
	p.RequiresLineOfSight = false
	p.KeyboardKeyCode = Enum.KeyCode.E
	p:SetAttribute("Color", color or Color3.fromRGB(140, 255, 120))
	p.Parent = parent
	return p
end

local function setupFloor2(folder)
	-- the managers' desks
	for _, spot in folder:GetDescendants() do
		local office = spot:IsA("BasePart") and spot:GetAttribute("HQSearch")
		if office then
			local p = floorPrompt(spot, "Search the desk", office, 1.2)
			p.Triggered:Connect(function(player) HQService.search(player, office) end)
		end
	end
	-- the keycard reader
	local reader, door
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("HQReader") == 2 then reader = d end
		if d:IsA("BasePart") and d:GetAttribute("HQDoor") == 2 then door = d end
	end
	HQService.door2 = door
	if reader then
		local p = floorPrompt(reader, "Swipe keycard", "Security Door", 0.5, Color3.fromRGB(255, 90, 90))
		p.Triggered:Connect(function(player) HQService.swipe(player) end)
	end
	-- office security
	local gfolder = Instance.new("Folder")
	gfolder.Name = "Guards"
	gfolder.Parent = folder
	local y = HQ.FLOORS[2].y
	local squad = Guards.new({
		name = "Office Security", title = "VexCorp Security", outfit = "guard", folder = gfolder,
		area = function(pos) return HQ.onFloor(pos, 2) end,
		grounds = function(pos) return HQ.onFloor(pos, 2) end,
		sight = { sight = 30, angle = 105, hear = 6 },
		patrolSpeed = 7, chaseSpeed = 15.5, loseAfter = 2.5,
		isCarrying = function(player) return state[player] and state[player].keycard end,
		onCatch = function(player)
			if not HQ.onFloor((player.Character and player.Character:GetPivot().Position) or Vector3.zero, 2) then return end
			msg(player, "\u{1F6A8} CAUGHT! Security walked you back to the elevators.", "bad")
			Remotes.Push:FireClient(player, "elevator", { dir = "caught" })
			task.wait(0.8)
			if player.Character then player.Character:PivotTo(HQ.arrival(2)) end
			HQService.arrive(player, 2)
		end,
	})
	for _, route in HQ.GUARDS[2] do
		local pts = {}
		for _, p in route do table.insert(pts, Vector3.new(HQ.X + p[1], y, HQ.Z + p[2])) end
		squad:add(pts)
	end
	squads[2] = squad
end

function HQService.swipe(player)
	local s = state[player]
	if not (s and s.keycard) then
		msg(player, "\u{1F512} ACCESS DENIED. Find a manager's keycard!", "bad")
		Remotes.Sfx:FireClient(player, "Error")
		return false
	end
	s.keycard = false
	player:SetAttribute("HQKeycard", nil)
	Remotes.Sfx:FireClient(player, "Unlock")
	if HQService.door2 then openDoor(HQService.door2) end
	HQService.clear(player, 2)
	return true
end

function HQService.search(player, office)
	local s = state[player]
	if not s or player:GetAttribute("HQFloor") ~= 2 then return end
	if s.keycard then
		msg(player, "You already have the keycard. The SECURITY DOOR is on the north wall!", "info")
		return
	end
	if s.office == office then
		s.keycard = true
		player:SetAttribute("HQKeycard", true)
		Remotes.Sfx:FireClient(player, "Collect")
		msg(player, "\u{1F4B3} KEYCARD FOUND! Get it to the SECURITY DOOR (north wall). Don't get caught!", "good")
	else
		s.searched[office] = true
		msg(player, QUIPS[math.random(#QUIPS)], "info")
	end
end

-- where the story quest's beam should point while you work on floor n
function HQService.target(player, n)
	local on = player:GetAttribute("HQFloor")
	if on ~= n then
		-- go to the staff elevator (in the lobby, or on the floor you're on)
		if on and HQ.FLOORS[on] then return HQ.arrival(on).Position + Vector3.new(-8, 2, 0) end
		return LOBBY + Vector3.new(-3, 3, 0)
	end
	local s = state[player]
	if n == 2 then
		local y = HQ.FLOORS[2].y
		if s and s.keycard then return Vector3.new(HQ.X + 36, y + 6, HQ.Z + 72) end
		-- the next office not searched yet
		local spots = { ["REGIONAL MANAGER"] = { 60, 60 }, ["ASSISTANT TO THE MANAGER"] = { 60, -60 }, ["VP OF WORKSHEETS"] = { 60, 0 } }
		for _, name in { "VP OF WORKSHEETS", "REGIONAL MANAGER", "ASSISTANT TO THE MANAGER" } do
			if not (s and s.searched and s.searched[name]) then
				local p = spots[name]
				return Vector3.new(HQ.X + p[1], y + 4, HQ.Z + p[2])
			end
		end
	end
	return nil
end

---------------------------------------------------------------------------
Actions.register("hqGo", function(player, _, n)
	if type(n) ~= "number" then return { ok = false } end
	local ok, why = HQService.canGo(player, n)
	if not ok then return { ok = false, err = why } end
	task.spawn(ride, player, n)
	return { ok = true }
end)

function HQService.debugBadge(player, on)
	local hq = hqOf(player)
	hq.badge = on ~= false
	return true
end

function HQService.debugState(player)
	local s = state[player]
	return { office = s and s.office, keycard = s and s.keycard, floor = player:GetAttribute("HQFloor"), cleared = hqOf(player).cleared }
end

function HQService.debugClear(player, n)
	HQService.clear(player, n)
	return true
end

function HQService.start(townRoot)
	-- every elevator: the floor panel
	for _, d in townRoot:GetDescendants() do
		local n = d:IsA("BasePart") and d:GetAttribute("HQElevator")
		if n then
			local p = Instance.new("ProximityPrompt")
			p.Name = "HQElevatorPrompt"
			p.ActionText = "Call elevator"
			p.ObjectText = n == 1 and "Staff Elevator" or "VexCorp Elevator"
			p.HoldDuration = 0.3
			p.MaxActivationDistance = 10
			p.RequiresLineOfSight = false
			p:SetAttribute("Color", Color3.fromRGB(140, 255, 120))
			p.Parent = d
			p.Triggered:Connect(function(player)
				if n == 1 and not HQService.hasBadge(player) then
					msg(player, "\u{1F916} ROBO-7: VISITOR BADGE REQUIRED. NO BADGE, NO ELEVATOR. HAVE A PRODUCTIVE DAY.", "bad")
					Remotes.Sfx:FireClient(player, "Error")
					return
				end
				Remotes.Push:FireClient(player, "hqElevator", { floors = floorList(player), here = n })
			end)
		end
	end
	local hqRoot = townRoot:FindFirstChild("VexCorpHQ")
	local f2 = hqRoot and hqRoot:FindFirstChild("Floor2")
	if f2 then setupFloor2(f2) end
	-- the guards only think while someone's on their floor
	RunService.Heartbeat:Connect(function(dt)
		for n, squad in squads do
			local anyone = false
			for _, pl in Players:GetPlayers() do
				if pl:GetAttribute("HQFloor") == n then anyone = true break end
			end
			if anyone then
				local ok, err = pcall(squad.tick, squad, dt)
				if not ok then warn("[HQ]", err) end
			end
		end
	end)
	table.insert(StealService.swingHooks, function(player, proot)
		local n = HQ.floorAt(proot.Position)
		local squad = n and squads[n]
		if squad then squad:onSwing(player, proot) end
	end)
	-- leaving the HQ (a teleport home, a respawn) clears HQFloor
	task.spawn(function()
		while true do
			task.wait(1)
			for _, pl in Players:GetPlayers() do
				local on = pl:GetAttribute("HQFloor")
				local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
				if on and r and not HQ.onFloor(r.Position, on) then
					pl:SetAttribute("HQFloor", HQ.floorAt(r.Position))
					if not HQ.floorAt(r.Position) then pl:SetAttribute("HQKeycard", nil) end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player) state[player] = nil end)
end

return HQService
