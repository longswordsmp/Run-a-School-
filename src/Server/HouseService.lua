-- ServerScriptService.Server.HouseService
-- Going into the houses of Maple Heights (the rooms: TownInteriors). Every house's front door gets an
-- Enter prompt; it takes you into that house's room (the featured neighbours have their own; the
-- rest share three family rooms) and the door inside takes you back out to the house you came in
-- by. A few people live in the rooms: they turn to you and chat.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Factory = require(script.Parent.StudentFactory)
local Remotes = require(script.Parent.Remotes)
local Interiors = require(script.Parent.TownInteriors)

local HouseService = {}
local cameFrom = {} -- player -> CFrame outside the house they went into

local FEATURED = {
	["GRANDMA ROSE"] = "rose",
	["LIL' TIMMY"] = "timmy",
	["OLD MAN GRUMBLES"] = "grumbles",
	["COACH DOUG"] = "coach",
	["SKYE"] = "skye",
}

-- the people at home: style -> { { id, name, outfit, x, z (room-local), face yaw, lines, scale } }
local RESIDENTS = {
	family1 = {
		{ id = "ResMom1", name = "Mrs. Baker", outfit = "mom", x = 13, z = -3, lines = { "Oh! A visitor! Mind the homework on the table, it's EVERYWHERE.", "VexCorp sends my kids three worksheets a day. THREE." } },
		{ id = "ResKid1", name = "Benny Baker", outfit = "timmy", x = 11, z = 8, scale = 0.72, lines = { "I did all my homework. Now I have MORE homework. Help.", "Is it true your school has recess? Like, every day?" } },
	},
	family2 = {
		{ id = "ResDad2", name = "Mr. Nguyen", outfit = "dad", x = -12, z = 8, lines = { "Just watching the news. It's all VexCorp ads now.", "The Vex Prep flyer came again. I used it as a coaster." } },
		{ id = "ResKid2", name = "Nina Nguyen", outfit = "skye", x = 14, z = 8, scale = 0.8, lines = { "When I grow up I want to run a school with a waterslide.", "My friend goes to Vex Prep. She hasn't smiled since Tuesday." } },
	},
	family3 = {
		{ id = "ResGran3", name = "Grandpa Sato", outfit = "grumbles", x = -14, z = 9, lines = { "In my day we had recess AND a nap. Both!", "Sit down, sit down. Want a mint? It's from 1987." } },
		{ id = "ResMom3", name = "Mrs. Sato", outfit = "mom", x = 15, z = -4, lines = { "Supper's at six. You're welcome to stay!", "Your school's the talk of the PTA. The GOOD kind of talk." } },
	},
	rose = {
		{ id = "ResCat", name = "Biscuit the Cat's Owner", outfit = "grandma", x = 12, z = -8, lines = { "Fresh out of the oven! Well, fresh-ish. Take one.", "I'm teaching the Patel kids to bake on Sundays. Bring your students!" } },
	},
	timmy = {
		{ id = "ResTimmyMom", name = "Timmy's Mom", outfit = "mom", x = 14, z = -4, lines = { "Timmy's out looking for Mr. Whiskers again. He won't give up, bless him.", "If you see an orange cat, please send him home!" } },
	},
	grumbles = {
		{ id = "ResGrumblesCat", name = "Mrs. Grumbles", outfit = "grandma", x = -12, z = 8, lines = { "Don't mind him. He grumbles because he likes you.", "He's been polishing that clock for forty years." } },
	},
	coach = {
		{ id = "ResCoachKid", name = "Dougie Jr.", outfit = "coachdad", x = -6, z = 10, scale = 0.75, lines = { "Dad says I'm the best kicker in the under-8s. I'm the ONLY kicker.", "Wanna see me do a push-up? ...That was one." } },
	},
	skye = {
		{ id = "ResSkyeBro", name = "Skye's Brother", outfit = "arcade", x = -10, z = 10, lines = { "Skye's out skating. She's always out skating.", "I'm on level 99 of Space Recess. VEX has the high score. Of course." } },
	},
}

local function styleFor(family, i)
	return FEATURED[family] or ({ "family1", "family2", "family3" })[(i % 3) + 1]
end

local function prompt(parent, action, object)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = 0.25
	p.MaxActivationDistance = 9
	p.RequiresLineOfSight = false
	p:SetAttribute("Color", Color3.fromRGB(255, 220, 150))
	p.Parent = parent
	return p
end

local function go(player, cf, text)
	local char = player.Character
	if not char then return end
	Remotes.Push:FireClient(player, "elevator", { dir = "door", text = text })
	task.wait(0.55)
	if char.Parent then
		pcall(function() player:RequestStreamAroundAsync(cf.Position, 3) end)
		char:PivotTo(cf)
	end
end

local function spawnResidents(style)
	local list = RESIDENTS[style]
	if not list then return end
	local c = Interiors.center(style)
	local folder = workspace:FindFirstChild("Residents") or Instance.new("Folder")
	folder.Name = "Residents"
	folder.Parent = workspace
	for _, r in list do
		local ok, m = pcall(function()
			return Factory.buildTeacher({ id = r.id, name = r.name, title = "At home", mult = 1, outfit = r.outfit }, 1)
		end)
		if ok and m then
			if r.scale then m:ScaleTo(r.scale) end
			local so = Factory.standOffset(m)
			local pos = c + Vector3.new(r.x, so - 0.1, r.z)
			-- facing the door (where visitors come in)
			local door = c + Vector3.new(0, so - 0.1, Interiors.D / 2)
			m.PrimaryPart.CFrame = CFrame.lookAt(pos, Vector3.new(door.X, pos.Y, door.Z))
			m.Name = r.id
			m.Parent = folder
			Factory.play(m, "idle")
			local n = 0
			local p = prompt(m.PrimaryPart, "Talk", r.name)
			p.Triggered:Connect(function(player)
				n = n % #r.lines + 1
				Remotes.Push:FireClient(player, "missionTalk", { lines = { { r.name:upper(), r.id, r.lines[n] } }, npc = r.id })
				Factory.emote(m, n % 2 == 0 and "laugh" or "wave")
			end)
		end
	end
end

function HouseService.start()
	local town = workspace:FindFirstChild("Town")
	local maple = town and town:FindFirstChild("MapleHeights")
	local rooms = town and town:FindFirstChild("Interiors")
	if not maple or not rooms then
		warn("[Houses] no Maple Heights or no interiors")
		return
	end
	local i = 0
	for _, hm in maple:GetChildren() do
		local doorPos = hm:IsA("Model") and hm:GetAttribute("Door")
		local family = hm:GetAttribute("Family")
		if doorPos and family then
			i += 1
			local style = styleFor(family, i)
			local cf, size = hm:GetBoundingBox()
			local out = Vector3.new(doorPos.X - cf.X, 0, doorPos.Z - cf.Z)
			out = out.Magnitude > 0.1 and out.Unit or Vector3.new(0, 0, 1)
			local outside = CFrame.lookAt(doorPos + Vector3.new(0, 3.5, 0) + out * 2, doorPos + Vector3.new(0, 3.5, 0) + out * 10)
			-- the prompt sits on the door (4 studs in from the Door point)
			local spot = Instance.new("Part")
			spot.Name = "EnterSpot"
			spot.Size = Vector3.new(1, 1, 1)
			spot.Transparency = 1
			spot.Anchored, spot.CanCollide, spot.CanQuery, spot.CanTouch = true, false, false, false
			spot.Position = doorPos - out * 3.4 + Vector3.new(0, 3.8, 0)
			spot.Parent = hm
			local title = family:gsub("^THE ", ""):lower():gsub("^%l", string.upper):gsub(" %l", string.upper)
			local p = prompt(spot, "Go inside", family:find("^THE ") and ("The " .. title .. "' house") or (title .. "'s house"))
			p.Triggered:Connect(function(player)
				cameFrom[player] = outside
				go(player, Interiors.entry(style), family)
			end)
			_ = size
		end
	end
	-- the doors out
	for _, d in rooms:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("InteriorExit") then
			local p = prompt(d, "Go outside", "Front door")
			p.Triggered:Connect(function(player)
				local back = cameFrom[player] or CFrame.new(0, 4, 300)
				cameFrom[player] = nil
				go(player, back, "MAPLE HEIGHTS")
			end)
		end
	end
	for _, style in Interiors.STYLES do task.spawn(spawnResidents, style) end
	Players.PlayerRemoving:Connect(function(player) cameFrom[player] = nil end)
end

function HouseService.debugEnter(player, style)
	cameFrom[player] = CFrame.new(-270, 4, 320)
	go(player, Interiors.entry(style), style)
	return true
end

return HouseService
