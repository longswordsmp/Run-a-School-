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
local Factory = require(script.Parent.StudentFactory)
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
	elseif n == 3 then
		s.lever = 0
		s.zapUntil = os.clock() + 2
	elseif n == 4 then
		s.spotUntil = os.clock() + 2.5
	elseif n == 5 then
		s.zapUntil = os.clock() + 2
		s.freed = s.freed or {}
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

---------------------------------------------------------------------------
-- floor 3: the Laser Vault
---------------------------------------------------------------------------
local HQLasers = require(ReplicatedStorage.Shared.HQLasers)
local lasers3 = {} -- { part, base }
local ORDER = {} -- the lever order this server (the lamps blink it)
local vault3, gate3

local function toCheckpoint(player, n)
	local s = state[player]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local lx = root.Position.X - HQ.X
	local cps = HQ.CHECKPOINTS[n]
	local k = 1
	for i, cp in cps do
		if lx >= cp[1] - 2 then k = i end
	end
	local cp = cps[k]
	local y = HQ.FLOORS[n].y
	local pos = Vector3.new(HQ.X + cp[1], y + 3.5, HQ.Z + cp[2])
	player.Character:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(1, 0, 0)))
	if s then s.zapUntil = os.clock() + 1.2 end
end

local function zap(player, n)
	local s = state[player]
	if not s or (s.zapUntil or 0) > os.clock() then return end
	s.zapUntil = os.clock() + 1.5
	Remotes.Push:FireClient(player, "hqZap", { floor = n or 3 })
	Remotes.Sfx:FireClient(player, "Error")
	task.delay(0.25, function() toCheckpoint(player, n or 3) end)
end

local function pullLever(player, handle)
	local s = state[player]
	if not s or player:GetAttribute("HQFloor") ~= 3 then return end
	local color = handle:GetAttribute("HQLever")
	-- the handle swings down and back
	local home = handle:GetAttribute("Home")
	handle.CFrame = home * CFrame.Angles(math.rad(60), 0, 0)
	task.delay(0.8, function() handle.CFrame = home end)
	s.lever = s.lever or 0
	if ORDER[s.lever + 1] == color then
		s.lever += 1
		Remotes.Sfx:FireClient(player, "Collect")
		if s.lever >= #ORDER then
			s.lever = 0
			msg(player, "\u{2714} THE VAULT IS OPEN!", "good")
			if vault3 and not vault3:GetAttribute("Open") then
				vault3:SetAttribute("Open", true)
				local home3 = vault3.CFrame
				TweenService:Create(vault3, TweenInfo.new(1.6, Enum.EasingStyle.Quad), { CFrame = home3 + Vector3.new(0, 0, -14) }):Play()
				if gate3 then gate3.CanCollide = false gate3.Transparency = 1 end
				task.delay(10, function()
					TweenService:Create(vault3, TweenInfo.new(1.6, Enum.EasingStyle.Quad), { CFrame = home3 }):Play()
					if gate3 then gate3.CanCollide = true gate3.Transparency = 0 end
					vault3:SetAttribute("Open", nil)
				end)
			end
			HQService.clear(player, 3)
		else
			msg(player, ("\u{2714} %s! %d more."):format(color, #ORDER - s.lever), "good")
		end
	else
		s.lever = 0
		msg(player, "\u{1F6A8} WRONG ORDER! The alarm resets the levers. Watch the lamps!", "bad")
		zap(player)
	end
end

local function setupFloor3(folder)
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			if d:GetAttribute("Laser") then table.insert(lasers3, { part = d, base = d.CFrame }) end
			if d:GetAttribute("HQDoor") == 3 then vault3 = d end
			if d:GetAttribute("HQGate") == 3 then gate3 = d end
			if d:GetAttribute("HQLever") then
				local p = floorPrompt(d, "Pull", d:GetAttribute("HQLever") .. " LEVER", 0.25, Color3.fromRGB(255, 220, 120))
				p.MaxActivationDistance = 7
				p.Triggered:Connect(function(player) pullLever(player, d) end)
			end
		end
	end
	-- a random order for this server, blinked by the lamps over the vault
	local colors = { "RED", "BLUE", "GREEN" }
	for i = #colors, 2, -1 do
		local j = math.random(i)
		colors[i], colors[j] = colors[j], colors[i]
	end
	ORDER = colors
	local lamps = {}
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("HQLamp") then lamps[d:GetAttribute("HQLamp")] = d end
	end
	task.spawn(function()
		while true do
			for _, c in ORDER do
				local lamp = lamps[c]
				if lamp then
					lamp.Color = lamp:GetAttribute("Lit")
					task.wait(0.8)
					lamp.Color = Color3.fromRGB(40, 40, 46)
					task.wait(0.25)
				end
			end
			task.wait(1.8)
		end
	end)
end

local function laserTick()
	local t = workspace:GetServerTimeNow()
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("HQFloor") == 3 then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if root and hum then
				local pos = root.Position
				local feet = pos.Y - (hum.HipHeight + root.Size.Y / 2)
				local head = pos.Y + 1.6
				for _, l in lasers3 do
					if HQLasers.hits(l.part, l.base, t, pos, feet, head, 0.9) then
						zap(player)
						break
					end
				end
			end
		end
	end
end

---------------------------------------------------------------------------
-- floor 4: the Server Farm
---------------------------------------------------------------------------
local Stealth = require(script.Parent.Stealth)
local HQCams = require(ReplicatedStorage.Shared.HQCams)
local cams4 = {} -- { head, eye, eyePos }
local camFolder4, eyeFolder4
local terms4 = {} -- name -> screen part
local door4, download4

local function setScreen(screen, text, color)
	local label = screen:FindFirstChildWhichIsA("SurfaceGui", true)
	label = label and label:FindFirstChildWhichIsA("TextLabel")
	if label then
		label.Text = text
		label.TextColor3 = color
	end
end

local function spotted(player)
	local s = state[player]
	if not s or (s.spotUntil or 0) > os.clock() then return end
	s.spotUntil = os.clock() + 3
	Remotes.Push:FireClient(player, "hqSpotted", {})
	Remotes.Sfx:FireClient(player, "Error")
	task.wait(0.9)
	if player.Character and player:GetAttribute("HQFloor") == 4 then
		Remotes.Push:FireClient(player, "elevator", { dir = "caught" })
		task.wait(0.6)
		player.Character:PivotTo(HQ.arrival(4))
	end
end

local function hack(player, name)
	local s = state[player]
	if not s or player:GetAttribute("HQFloor") ~= 4 then return end
	s.hacked = s.hacked or {}
	if s.hacked[name] then
		msg(player, "Already hacked. Find the others!", "info")
		return
	end
	s.hacked[name] = true
	local n = 0
	for _ in s.hacked do n += 1 end
	Remotes.Sfx:FireClient(player, "Collect")
	if terms4[name] then setScreen(terms4[name], "PROJECT H.M.\nHACKED \u{2714}", Color3.fromRGB(90, 255, 160)) end
	if download4 then
		local bar = string.rep("\u{2588}", n * 3) .. string.rep(" ", 9 - n * 3)
		setScreen(download4, ("DOWNLOAD: HOMEWORK MACHINE BLUEPRINTS\n[%s] %d%%"):format(bar, math.floor(n / 3 * 100)), Color3.fromRGB(90, 255, 160))
	end
	if n >= 3 then
		msg(player, "\u{1F4BE} DOWNLOAD COMPLETE! The DATA CENTER door is open (east wall).", "good")
		if door4 then openDoor(door4) end
		HQService.clear(player, 4)
	else
		msg(player, ("\u{1F4BE} Terminal hacked! %d of 3."):format(n), "good")
	end
end

local function setupFloor4(folder)
	camFolder4 = folder:FindFirstChild("Cameras")
	eyeFolder4 = Instance.new("Folder")
	eyeFolder4.Name = "CamEyes"
	eyeFolder4.Parent = folder
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			if d:GetAttribute("Cam") then
				-- the eye sits below the head so the racks block its view across rows
				local eye = Instance.new("Part")
				eye.Name = "Eye"
				eye.Size = Vector3.new(0.2, 0.2, 0.2)
				eye.Transparency = 1
				eye.Anchored, eye.CanCollide, eye.CanQuery, eye.CanTouch = true, false, false, false
				eye.Parent = eyeFolder4
				table.insert(cams4, { head = d, eye = eye, eyePos = d.Position - Vector3.new(0, 4, 0) })
			elseif d:GetAttribute("HQTerminal") then
				local name = d:GetAttribute("HQTerminal")
				terms4[name] = d
				local p = floorPrompt(d, "Hack", "Terminal " .. name, 2.5, Color3.fromRGB(90, 255, 160))
				p.MaxActivationDistance = 9
				p.Triggered:Connect(function(player) hack(player, name) end)
			elseif d:GetAttribute("HQDoor") == 4 then
				door4 = d
			elseif d:GetAttribute("HQDownload") then
				download4 = d
			end
		end
	end
end

local function camTick()
	local anyone = false
	for _, pl in Players:GetPlayers() do
		if pl:GetAttribute("HQFloor") == 4 then anyone = true break end
	end
	if not anyone then return end
	local t = workspace:GetServerTimeNow()
	for _, c in cams4 do
		c.eye.CFrame = HQCams.cf(c.eyePos, c.head, t)
	end
	for _, player in Players:GetPlayers() do
		local char = player.Character
		if player:GetAttribute("HQFloor") == 4 and char then
			for _, c in cams4 do
				local range = c.head:GetAttribute("Range") or 44
				if Stealth.canSee(c.eye, char, { sight = range, angle = c.head:GetAttribute("Angle") or 34, hear = 0 }, { camFolder4, eyeFolder4 }) then
					task.spawn(spotted, player)
					break
				end
			end
		end
	end
end

---------------------------------------------------------------------------
-- floor 5: Mutagen Labs
---------------------------------------------------------------------------
local pods5 = {} -- i -> { glass, fluid, spot, home, kid }
local sample5, vial5, door5

local function podKid(pod)
	-- a kid from the student templates, floating in the tube
	if pod.kid then pod.kid:Destroy() pod.kid = nil end
	local st = ReplicatedStorage:FindFirstChild("StudentTemplates")
	local list = st and st:GetChildren() or {}
	if #list == 0 then return end
	local kid = list[math.random(#list)]:Clone()
	for _, d in kid:GetDescendants() do
		if d:IsA("BillboardGui") or d:IsA("ProximityPrompt") or d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
		if d:IsA("BasePart") then d.CanCollide = false d.CanQuery = false end
	end
	local root = kid:FindFirstChild("HumanoidRootPart") or kid.PrimaryPart
	if not root then kid:Destroy() return end
	kid.PrimaryPart = root
	root.Anchored = true
	local so = Factory.standOffset(kid)
	kid:PivotTo(CFrame.lookAt(pod.spot.Position + Vector3.new(0, so + 0.4, 0), pod.spot.Position + Vector3.new(0, so + 0.4, 0) + Vector3.new(0, 0, pod.spot.Position.Z > HQ.Z and -1 or 1)))
	kid.Parent = pod.spot.Parent
	Factory.play(kid, "idle")
	pod.kid = kid
end

local function checkExit5(player)
	local s = state[player]
	local n = 0
	for _ in s.freed do n += 1 end
	if n >= #pods5 and s.sample then
		msg(player, "\u{2622} ALL FIVE KIDS FREE AND THE SAMPLE IS YOURS! The lab door is open (east).", "good")
		if door5 then openDoor(door5) end
		HQService.clear(player, 5)
	end
end

local function freePod(player, i)
	local s = state[player]
	local pod = pods5[i]
	if not s or not pod or player:GetAttribute("HQFloor") ~= 5 then return end
	s.freed = s.freed or {}
	if s.freed[i] then
		msg(player, "You already freed this one. Find the others!", "info")
		return
	end
	s.freed[i] = true
	local n = 0
	for _ in s.freed do n += 1 end
	Signals.fire("rescued", player)
	Remotes.Sfx:FireClient(player, "Cheer")
	msg(player, ("\u{1F9D2} Kid freed! %d of %d."):format(n, #pods5), "good")
	-- the tube lifts, the fluid drains, the kid cheers and runs home (sparkles out)
	if not pod.open then
		pod.open = true
		TweenService:Create(pod.glass, TweenInfo.new(0.8, Enum.EasingStyle.Quad), { CFrame = pod.home + Vector3.new(0, 8.5, 0) }):Play()
		TweenService:Create(pod.fluid, TweenInfo.new(0.8), { Transparency = 1 }):Play()
		local kid = pod.kid
		if kid then
			Factory.emote(kid, "cheer")
			task.delay(1.6, function()
				if kid.Parent then
					for _, d in kid:GetDescendants() do
						if d:IsA("BasePart") or d:IsA("Decal") then TweenService:Create(d, TweenInfo.new(0.5), { Transparency = 1 }):Play() end
					end
				end
			end)
		end
		task.delay(15, function()
			TweenService:Create(pod.glass, TweenInfo.new(0.8, Enum.EasingStyle.Quad), { CFrame = pod.home }):Play()
			TweenService:Create(pod.fluid, TweenInfo.new(0.8), { Transparency = 0.7 }):Play()
			task.wait(0.9)
			podKid(pod)
			pod.open = false
		end)
	end
	checkExit5(player)
end

local function grabSample(player)
	local s = state[player]
	if not s or player:GetAttribute("HQFloor") ~= 5 then return end
	if s.sample then
		msg(player, "You've got the sample already!", "info")
		return
	end
	s.sample = true
	player:SetAttribute("HQSample", true)
	Remotes.Sfx:FireClient(player, "Collect")
	msg(player, "\u{2622} MUTATION SAMPLE GRABBED!", "good")
	if vial5 then
		vial5.Transparency = 1
		task.delay(15, function() vial5.Transparency = 0 end)
	end
	checkExit5(player)
end

local function setupFloor5(folder)
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			local i = d:GetAttribute("HQPod")
			if i then
				pods5[i] = pods5[i] or {}
				pods5[i].glass = d
				pods5[i].home = d.CFrame
				local p = floorPrompt(d, "Free the kid", "Pod", 1.5, Color3.fromRGB(140, 255, 120))
				p.MaxActivationDistance = 8
				p.Triggered:Connect(function(player) freePod(player, i) end)
			end
			local f = d:GetAttribute("HQPodFluid")
			if f then pods5[f] = pods5[f] or {} pods5[f].fluid = d end
			local sp = d:GetAttribute("HQPodSpot")
			if sp then pods5[sp] = pods5[sp] or {} pods5[sp].spot = d end
			if d:GetAttribute("HQSample") then
				sample5 = d
				local p = floorPrompt(d, "Grab the sample", "Mutagen X", 1, Color3.fromRGB(140, 255, 120))
				p.Triggered:Connect(grabSample)
			end
			if d:GetAttribute("HQSampleVial") then vial5 = d end
			if d:GetAttribute("HQDoor") == 5 then door5 = d end
		end
	end
	task.defer(function()
		for _, pod in pods5 do podKid(pod) end
	end)
	-- hazmat guards on the catwalk (they stay on it)
	local gfolder = Instance.new("Folder")
	gfolder.Name = "Guards"
	gfolder.Parent = folder
	local y = HQ.FLOORS[5].y
	local function onCatwalk(pos)
		return HQ.onFloor(pos, 5) and math.abs(pos.Z - HQ.Z) < 3.5 and pos.X > HQ.X - 52 and pos.X < HQ.X + 60
	end
	local squad = Guards.new({
		id = "LabGuard", name = "Hazmat", title = "Lab Security", outfit = "hazmat", folder = gfolder,
		area = onCatwalk,
		grounds = function(pos) return HQ.onFloor(pos, 5) end,
		sight = { sight = 26, angle = 100, hear = 5 },
		patrolSpeed = 6.5, chaseSpeed = 14, loseAfter = 2,
		onCatch = function(player)
			msg(player, "\u{1F6A8} The hazmat team caught you! Back to the lobby.", "bad")
			Remotes.Push:FireClient(player, "elevator", { dir = "caught" })
			task.wait(0.8)
			if player.Character then player.Character:PivotTo(HQ.arrival(5)) end
		end,
	})
	for _, route in HQ.GUARDS[5] do
		local pts = {}
		for _, p in route do table.insert(pts, Vector3.new(HQ.X + p[1], y, HQ.Z + p[2])) end
		squad:add(pts)
	end
	squads[5] = squad
end

local function acidTick()
	local a = HQ.ACID
	if not a then return end
	local y = HQ.FLOORS[5].y
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("HQFloor") == 5 then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if root and hum then
				local p = root.Position
				local lx, lz = p.X - HQ.X, p.Z - HQ.Z
				local feet = p.Y - (hum.HipHeight + root.Size.Y / 2)
				if lx > a.x0 and lx < a.x1 and lz > a.z0 and lz < a.z1 and feet < y + a.top + 0.6 then
					zap(player, 5)
				end
			end
		end
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
	if n == 5 then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local best, bestD
		for i, pod in pods5 do
			if not (s and s.freed and s.freed[i]) and pod.glass then
				local d = root and (root.Position - pod.glass.Position).Magnitude or 0
				if not best or d < bestD then best, bestD = pod.glass.Position + Vector3.new(0, 6, 0), d end
			end
		end
		if best then return best end
		if not (s and s.sample) and sample5 then return sample5.Position + Vector3.new(0, 3, 0) end
		return door5 and door5.Position + Vector3.new(-2, 2, 0)
	end
	if n == 4 then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local best, bestD
		for name, screen in terms4 do
			if not (s and s.hacked and s.hacked[name]) then
				local d = root and (root.Position - screen.Position).Magnitude or 0
				if not best or d < bestD then best, bestD = screen.Position + Vector3.new(0, 2, 0), d end
			end
		end
		return best or (door4 and door4.Position + Vector3.new(-2, 2, 0))
	end
	if n == 3 then
		-- through the course to the levers
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local lx = root and root.Position.X - HQ.X or -64
		local y = HQ.FLOORS[3].y
		if lx < -10 then return Vector3.new(HQ.X - 8, y + 4, HQ.Z) end
		if lx < 40 then return Vector3.new(HQ.X + 43, y + 4, HQ.Z) end
		return Vector3.new(HQ.X + 73, y + 17.5, HQ.Z)
	end
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

function HQService.debugPull(player, color)
	local folder = workspace.Town.VexCorpHQ.Floor3
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("HQLever") == color then pullLever(player, d) end
	end
	return { order = ORDER, step = state[player] and state[player].lever }
end

function HQService.debugHack(player, name)
	hack(player, name)
	return state[player] and state[player].hacked
end

function HQService.debugFree(player, i)
	if i == 0 then grabSample(player) else freePod(player, i) end
	local s = state[player]
	return { freed = s and s.freed, sample = s and s.sample }
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
	local f3 = hqRoot and hqRoot:FindFirstChild("Floor3")
	if f3 then setupFloor3(f3) end
	local f4 = hqRoot and hqRoot:FindFirstChild("Floor4")
	if f4 then setupFloor4(f4) end
	local f5 = hqRoot and hqRoot:FindFirstChild("Floor5")
	if f5 then setupFloor5(f5) end
	RunService.Heartbeat:Connect(function()
		local ok, err = pcall(acidTick)
		if not ok then warn("[HQ acid]", err) end
	end)
	task.spawn(function()
		while true do
			task.wait(0.1)
			local ok, err = pcall(camTick)
			if not ok then warn("[HQ cams]", err) end
		end
	end)
	RunService.Heartbeat:Connect(function()
		local ok, err = pcall(laserTick)
		if not ok then warn("[HQ lasers]", err) end
	end)
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
