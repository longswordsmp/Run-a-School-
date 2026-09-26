-- ServerScriptService.Server.SecretService
-- Janitor Stan's secret missions (Config.SecretMissions): repeatable jobs against VexCorp, one at a
-- time with a short breather between. When Stan has a job for you a "!" floats over him (player
-- attribute SecretReady); talk to him, hear it, START. The jobs:
--   secret_ghost    break a mutant out of the Lab with no alarm before you grab it
--   secret_hack     hack both Lab terminals, then get out of the Lab
--   secret_sample   fill a vial at the Mutagen X Vat, then get out: keep the vial
--   secret_snoop    photograph Vex's desk in the Factory, then get out
-- Getting caught (thrown out) loses what you were carrying out (the photo, the vial, the hack) but
-- not the job: go back in. Rewards: `secs` seconds of tuition (at least `floor`), and gear.
-- Mutagen Vials: a hold-E "Mutate" prompt on your own seated kids turns one into a Mutated kid.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)

local SecretService = {}

local rgb = Color3.fromRGB
local active = {} -- [player] = { id, def, ... }
local FACTORY = { x0 = -33, x1 = 33, z0 = 34, z1 = 134 }
local STAN_LINES_WIN = {
	"Nice work, kid. Here's your cut. Don't spend it all on candy.",
	"Heh heh. Vex is gonna be SO mad. Here's your cut.",
	"Clean job. I've seen things, kid, and that was a clean job.",
}

local function inBox(pos, b) return pos.X > b.x0 and pos.X < b.x1 and pos.Z > b.z0 and pos.Z < b.z1 end
local function rootOf(player)
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function tutorialDone(p) return (p.tutorial or 1) > #Config.Tutorial end

function SecretService.ready(player)
	local p = Data.get(player)
	if not p or not tutorialDone(p) or active[player] then return false end
	if player:GetAttribute("Mission") then return false end -- a story mission is on
	return os.time() >= (p.secretNextAt or 0)
end

local function refreshReady(player)
	if not player.Parent then return end
	player:SetAttribute("SecretReady", SecretService.ready(player) or nil)
end

local function push(player, state, extra)
	local m = active[player]
	local data = { state = state, title = m and m.def.title, objective = m and m.def.objective, secret = true }
	for k, v in extra or {} do data[k] = v end
	Remotes.Push:FireClient(player, "mission", data)
end

local function target(player, pos)
	player:SetAttribute("MissionTarget", pos)
end

local function finish(player, won, why)
	local m = active[player]
	if not m then return end
	active[player] = nil
	player:SetAttribute("Mission", nil)
	player:SetAttribute("MissionTarget", nil)
	local p = Data.get(player)
	if p then
		p.secretNextAt = os.time() + (won and Config.SecretCooldown or 45)
		p.secretNext = (m.def.order % #Config.SecretMissions) + 1
	end
	if won and p then
		local inc = player:GetAttribute("BaseIncome") or player:GetAttribute("IncomePerSec") or 0
		local cash = math.max(m.def.floor, math.floor(inc * m.def.secs))
		Data.addCash(player, cash)
		local extra = {}
		if m.def.gear then
			require(script.Parent.GearService).give(player, m.def.gear, m.def.n or 1)
			local g = Config.GearById[m.def.gear]
			table.insert(extra, ("%d %s"):format(m.def.n or 1, g.name))
		end
		if m.def.vial then
			p.vials = (p.vials or 0) + m.def.vial
			player:SetAttribute("Vials", p.vials)
			table.insert(extra, "a Mutagen Vial (hold E on one of your kids to mutate them!)")
		end
		p.stats.secrets = (p.stats.secrets or 0) + 1
		Remotes.Push:FireClient(player, "mission", {
			state = "won", title = m.def.title, secret = true,
			line = STAN_LINES_WIN[math.random(#STAN_LINES_WIN)] .. (#extra > 0 and ("\n+" .. Config.formatCash(cash) .. ", " .. table.concat(extra, ", ")) or ("\n+" .. Config.formatCash(cash))),
			speaker = "JANITOR STAN", portrait = "Stan",
		})
		Signals.fire("secretWon", player, m.id)
		Data.saveSoon(player)
	elseif player.Parent then
		Remotes.Push:FireClient(player, "mission", { state = "failed", title = m.def.title, secret = true, why = why })
		Remotes.Notify:FireClient(player, (why or "Secret mission failed.") .. " Talk to Janitor Stan for another job.", "bad")
	end
	refreshReady(player)
end

---------------------------------------------------------------------------
-- starting
---------------------------------------------------------------------------
local LAB_GATE = Vector3.new(-420, 4, 40)
local FACTORY_GATE = Vector3.new(0, 4, 32)

function SecretService.start(player, id)
	local def = Config.SecretById[id]
	if not def or not SecretService.ready(player) then return false end
	local m = { id = id, def = def }
	active[player] = m
	player:SetAttribute("Mission", id)
	player:SetAttribute("SecretReady", nil)
	target(player, (id == "secret_snoop") and FACTORY_GATE or LAB_GATE)
	local count = id == "secret_hack" and 2 or nil
	push(player, "started", { progress = 0, count = count })
	return true
end

Actions.register("secretStart", function(player, p, id)
	if type(id) ~= "string" then return { ok = false } end
	return { ok = SecretService.start(player, id) }
end)

local function talk(player)
	local p = Data.get(player)
	if not p then return end
	local m = active[player]
	if m then
		Remotes.Notify:FireClient(player, "You're on a job: " .. m.def.objective, "info")
		return
	end
	if not tutorialDone(p) then
		Remotes.Push:FireClient(player, "missionTalk", { lines = { { "JANITOR STAN", "Stan", "Finish your first day, kid. Then come see me. I've got... jobs." } } })
		return
	end
	if player:GetAttribute("Mission") then
		Remotes.Push:FireClient(player, "missionTalk", { lines = { { "JANITOR STAN", "Stan", "You're busy with the old man's mission. Finish that first." } } })
		return
	end
	local wait = (p.secretNextAt or 0) - os.time()
	if wait > 0 then
		Remotes.Push:FireClient(player, "missionTalk", { lines = { { "JANITOR STAN", "Stan", ("Lie low for a bit, kid. Come back in %d seconds. They're watching."):format(wait) } } })
		return
	end
	local def = Config.SecretMissions[p.secretNext or 1] or Config.SecretMissions[1]
	local lines = {}
	for _, l in def.lines do table.insert(lines, { "JANITOR STAN", "Stan", l }) end
	local inc = player:GetAttribute("BaseIncome") or player:GetAttribute("IncomePerSec") or 0
	table.insert(lines, { "JANITOR STAN", "Stan", ("Pays %s. You in?"):format(Config.formatCash(math.max(def.floor, math.floor(inc * def.secs)))) })
	Remotes.Push:FireClient(player, "missionTalk", { id = def.id, title = "SECRET JOB: " .. def.title, lines = lines, action = "secretStart", npc = "JanitorStan" })
end

---------------------------------------------------------------------------
-- the job prompts: the Lab terminals, the Vat, Vex's desk (only for the player on that job:
-- MissionOnly, see HUD.client's fixPrompt)
---------------------------------------------------------------------------
local function jobPrompt(parent, name, action, object, mission, hold)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = hold
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("MissionOnly", mission)
	prompt:SetAttribute("Color", rgb(120, 200, 255))
	prompt.Parent = parent
	return prompt
end

local function setupPrompts()
	local LabService = require(script.Parent.LabService)
	for _, t in LabService.terminals() do
		local i = t:GetAttribute("Terminal")
		local spot = t:FindFirstChild("PromptSpot")
		local prompt = jobPrompt(spot, "HackPrompt", "Hack", "VexCorp Terminal", "secret_hack", 3)
		prompt.Triggered:Connect(function(player)
			local m = active[player]
			if not m or m.id ~= "secret_hack" then return end
			local r = rootOf(player)
			if not r or (r.Position - spot.Position).Magnitude > 12 then return end
			m.hacked = m.hacked or {}
			if m.hacked[i] then return end
			m.hacked[i] = true
			local n = 0
			for _ in m.hacked do n += 1 end
			push(player, "progress", { progress = n, count = 2 })
			Remotes.Notify:FireClient(player, ("\u{1F4BB} Terminal %d hacked!"):format(i), "good")
			if n >= 2 then
				push(player, "phase", { text = "Both hacked! Now get out of the Lab" })
				target(player, LAB_GATE)
			end
		end)
	end
	local vat = LabService.vat()
	if vat then
		local spot = Instance.new("Part")
		spot.Name = "VatSpot"
		spot.Anchored, spot.CanCollide, spot.CanQuery, spot.Transparency = true, false, false, 1
		spot.Size = Vector3.one
		spot.Position = vat.Position + Vector3.new(0, -2, -6.5)
		spot.Parent = vat.Parent
		local prompt = jobPrompt(spot, "VatPrompt", "Fill Vial", "Mutagen X", "secret_sample", 3)
		prompt.Triggered:Connect(function(player)
			local m = active[player]
			if not m or m.id ~= "secret_sample" or m.vial then return end
			local r = rootOf(player)
			if not r or (r.Position - spot.Position).Magnitude > 12 then return end
			m.vial = true
			push(player, "phase", { text = "Got the sample! Now get out of the Lab" })
			target(player, LAB_GATE)
			Remotes.Notify:FireClient(player, "\u{1F9EA} Vial filled! The guards heard the glugging. RUN!", "steal")
			-- (the glugging carries: every guard in the Lab comes to look)
			for _, hook in require(script.Parent.GearService).noiseHooks do task.spawn(hook, spot.Position) end
		end)
	end
	local fac = workspace:FindFirstChild("VexFactory")
	local desk = fac and fac:FindFirstChild("VexDesk", true)
	local dspot = desk and desk:FindFirstChild("PromptSpot")
	if dspot then
		local prompt = jobPrompt(dspot, "SnoopPrompt", "Photograph", "Vex's Desk", "secret_snoop", 2)
		prompt.Triggered:Connect(function(player)
			local m = active[player]
			if not m or m.id ~= "secret_snoop" or m.photo then return end
			local r = rootOf(player)
			if not r or (r.Position - dspot.Position).Magnitude > 12 then return end
			m.photo = true
			push(player, "phase", { text = "Got the photo! Now get out of the Factory" })
			target(player, FACTORY_GATE)
			Remotes.Push:FireClient(player, "flash", {})
			Remotes.Notify:FireClient(player, "\u{1F4F8} *CLICK* Got it! Now get out!", "good")
		end)
	end
end

---------------------------------------------------------------------------
-- Mutagen Vials: a Mutate prompt on your own seated kids while you have one
---------------------------------------------------------------------------
local function refreshVialPrompts(player)
	-- (a co-op school's prompts are the host's to build; any of the crew can use them)
	if Data.isMember(player) then return end
	local p = Data.get(player)
	if not p then return end
	local PlotService = require(script.Parent.PlotService)
	local plot = PlotService.getPlot(player)
	local students = plot and plot:FindFirstChild("Students")
	local have = (p.vials or 0) > 0
	for _, model in students and students:GetChildren() or {} do
		local slot = model:GetAttribute("Slot")
		if not slot or model:GetAttribute("OwnerId") ~= player.UserId then continue end
		local e = p.students[slot]
		local want = have and e and e.grade ~= "Mutated"
		local existing = model.PrimaryPart and model.PrimaryPart:FindFirstChild("MutatePrompt")
		if want and not existing and model.PrimaryPart then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "MutatePrompt"
			prompt.ActionText = "Mutate"
			prompt.ObjectText = "Use a Mutagen Vial"
			prompt.HoldDuration = 1.5
			prompt.KeyboardKeyCode = Enum.KeyCode.V -- (F sells, G graduates)
			prompt.MaxActivationDistance = 7
			prompt.RequiresLineOfSight = false
			prompt.UIOffset = Vector2.new(0, 60)
			prompt:SetAttribute("OwnerOnly", true)
			prompt:SetAttribute("Color", rgb(120, 255, 60))
			prompt.Parent = model.PrimaryPart
			prompt.Triggered:Connect(function(who)
				if Data.hostOf(who) ~= player then return end
				local pp = Data.get(player)
				local entry = pp and pp.students[slot]
				if not entry or entry.grade == "Mutated" or (pp.vials or 0) <= 0 then return end
				pp.vials -= 1
				player:SetAttribute("Vials", pp.vials)
				entry.grade = "Mutated"
				pp.index[entry.id .. "|Mutated"] = true
				PlotService.place(player, slot)
				PlotService.updateIncome(player)
				local def = Config.StudentById[entry.id]
				for _, pl in Data.schoolPlayers(player) do
					Remotes.Announce:FireClient(pl, ("%s MUTATED!"):format(def.name:upper()), rgb(120, 255, 60))
				end
				Remotes.Sfx:FireClient(who, "Upgrade")
				Signals.fire("mutateKid", player, def)
				Data.saveSoon(player)
				task.defer(refreshVialPrompts, player)
			end)
		elseif not want and existing then
			existing:Destroy()
		end
	end
end
SecretService.refreshVialPrompts = refreshVialPrompts

---------------------------------------------------------------------------
function SecretService.start_service()
	task.spawn(function()
		local npcs = workspace:WaitForChild("StoryNPCs", 30)
		local stan = npcs and npcs:WaitForChild("JanitorStan", 30)
		if not stan or not stan.PrimaryPart then return end
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TalkPrompt"
		prompt.ActionText = "Talk"
		prompt.ObjectText = "Janitor Stan (secret jobs)"
		prompt.HoldDuration = 0
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 10
		prompt:SetAttribute("Color", rgb(120, 200, 255))
		prompt.Parent = stan.PrimaryPart
		prompt.Triggered:Connect(talk)
	end)
	task.delay(4, function() pcall(setupPrompts) end)
	-- the Lab and the Factory report what happens there
	Signals.on("labAlarm", function(player)
		local m = active[player]
		if m and m.id == "secret_ghost" and not m.took then finish(player, false, "The alarm went off!") end
	end)
	Signals.on("labTake", function(player)
		local m = active[player]
		if m and m.id == "secret_ghost" then m.took = true end
	end)
	Signals.on("mutantEscaped", function(player)
		local m = active[player]
		if m and m.id == "secret_ghost" and m.took then finish(player, true) end
	end)
	for _, name in { "labCaught", "factoryCaught" } do
		Signals.on(name, function(player)
			local m = active[player]
			if not m then return end
			-- caught: whatever you were carrying out is gone, the job isn't
			if m.vial or m.photo or (m.hacked and next(m.hacked)) then
				m.vial, m.photo, m.hacked = nil, nil, nil
				push(player, "progress", { progress = 0, count = m.id == "secret_hack" and 2 or nil })
				push(player, "phase", { text = "Caught! You lost it. " .. m.def.objective })
			end
			if m.id == "secret_ghost" and m.took then m.took = nil end
		end)
	end
	-- getting out with the goods
	RunService.Heartbeat:Connect(function()
		for player, m in active do
			if not player.Parent then
				active[player] = nil
				continue
			end
			local r = rootOf(player)
			if not r then continue end
			local LabService = require(script.Parent.LabService)
			local inLab = LabService.inLot(r.Position)
			if m.id == "secret_hack" and m.hacked and m.hacked[1] and m.hacked[2] and not inLab then
				finish(player, true)
			elseif m.id == "secret_sample" and m.vial and not inLab then
				finish(player, true)
			elseif m.id == "secret_snoop" and m.photo and not inBox(r.Position, FACTORY) then
				finish(player, true)
			end
		end
	end)
	-- readiness and vial prompts, kept fresh
	task.spawn(function()
		while true do
			task.wait(2)
			for _, player in Players:GetPlayers() do
				pcall(refreshReady, player)
				pcall(refreshVialPrompts, player)
			end
		end
	end)
	local function watch(player)
		task.spawn(function()
			for _ = 1, 40 do
				local p = Data.get(player)
				if p then
					player:SetAttribute("Vials", p.vials or 0)
					return
				end
				task.wait(0.5)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do watch(player) end
	Players.PlayerRemoving:Connect(function(player) active[player] = nil end)
end

-- Studio
function SecretService.debugStart(player, id)
	local p = Data.get(player)
	if p then
		p.secretNextAt = 0
		p.tutorial = math.max(p.tutorial or 1, #Config.Tutorial + 1)
	end
	player:SetAttribute("Mission", nil)
	active[player] = nil
	return SecretService.start(player, id)
end
function SecretService.debugState(player)
	local m = active[player]
	return m and { id = m.id, took = m.took, vial = m.vial, photo = m.photo, hacked = m.hacked } or { ready = SecretService.ready(player) }
end
function SecretService.debugVials(player, n)
	local p = Data.get(player)
	p.vials = n
	player:SetAttribute("Vials", n)
	refreshVialPrompts(player)
	return true
end

return SecretService
