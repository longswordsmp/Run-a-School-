-- ServerScriptService.Server.TicketService
-- Event Tickets. While an event runs, event tokens (a spinning coin in the event's colour with its
-- icon) pop up on the ground around every player; touching one is a ticket. Tickets buy letters and
-- candy (Config.EventShop) and each event's trophy while that event runs; trophies fill the trophy
-- case on your lawn (SchoolBuilder.trophyCase).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)
local PlotService = require(script.Parent.PlotService)
local SchoolBuilder = require(script.Parent.SchoolBuilder)

local TicketService = {}

local SPAWN_EVERY = 8 -- seconds between tokens per player
local MAX_LIVE = 4 -- per player
local LIFETIME = 45
local RING = { 12, 34 } -- studs from the player

local folder
local live = {} -- [player] = { token parts }

local EVENT_COLORS = {
	SnowDay = Color3.fromRGB(170, 220, 255), FieldDay = Color3.fromRGB(255, 205, 60), ScienceFair = Color3.fromRGB(90, 255, 90),
	PromNight = Color3.fromRGB(255, 120, 220), PictureDay = Color3.fromRGB(245, 245, 250), Throwback = Color3.fromRGB(230, 170, 90),
	Halloween = Color3.fromRGB(255, 130, 20), WizardWeek = Color3.fromRGB(170, 110, 255), CandyCarnival = Color3.fromRGB(255, 110, 190),
	SpaceCamp = Color3.fromRGB(140, 90, 255), HostileTakeover = Color3.fromRGB(80, 200, 120), Graduation = Color3.fromRGB(240, 240, 250),
}

local function syncTickets(player, p)
	player:SetAttribute("Tickets", p.tickets or 0)
end

local function refreshCase(player, p)
	local plot = PlotService.getPlot(player)
	if plot then SchoolBuilder.trophyCase(plot, p.trophies or {}) end
end

local function clearTokens()
	if folder then folder:ClearAllChildren() end
	table.clear(live)
end

-- somewhere on the ground near the player: street, lawn or sidewalk, not a roof
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function groundNear(root)
	local exclude = { folder }
	for _, pl in Players:GetPlayers() do
		if pl.Character then table.insert(exclude, pl.Character) end
	end
	for _, name in { "Hall", "StoryNPCs", "QuestGuide", "MoneyRain" } do
		local f = workspace:FindFirstChild(name)
		if f then table.insert(exclude, f) end
	end
	rayParams.FilterDescendantsInstances = exclude
	for _ = 1, 6 do
		local a = math.random() * math.pi * 2
		local r = RING[1] + math.random() * (RING[2] - RING[1])
		local at = root.Position + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local hit = workspace:Raycast(Vector3.new(at.X, 60, at.Z), Vector3.new(0, -120, 0), rayParams)
		if hit and hit.Position.Y < 4 and hit.Position.Y > -2 then return hit.Position end
	end
	return nil
end

local function spawnToken(player, eventId)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local pos = groundNear(root)
	if not pos then return end
	local color = EVENT_COLORS[eventId] or Color3.new(1, 1, 1)
	local info = Config.EventInfo[eventId]
	local t = Instance.new("Part")
	t.Name = "EventToken"
	t.Shape = Enum.PartType.Cylinder
	t.Size = Vector3.new(0.45, 2.8, 2.8)
	t.CFrame = CFrame.new(pos + Vector3.new(0, 2.4, 0))
	t.Color = color
	t.Material = Enum.Material.SmoothPlastic
	t.Reflectance = 0.15
	t.Anchored, t.CanCollide, t.CanQuery, t.CanTouch = true, false, false, true
	-- a coin you can read: solid colour, the event icon drawn on top, a few sparkles
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(64, 64)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 80
	bb.Parent = t
	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromScale(1, 1)
	icon.TextScaled = true
	icon.Text = info and info.icon or "?"
	icon.Font = Enum.Font.FredokaOne
	icon.Parent = bb
	local sp = Instance.new("ParticleEmitter")
	sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sp.Color = ColorSequence.new(color)
	sp.LightEmission = 1
	sp.Size = NumberSequence.new(0.35, 0)
	sp.Lifetime = NumberRange.new(0.6, 1)
	sp.Rate = 7
	sp.Speed = NumberRange.new(1, 2)
	sp.SpreadAngle = Vector2.new(180, 180)
	sp.Parent = t
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = 7
	l.Brightness = 0.8
	l.Parent = t
	CollectionService:AddTag(t, "EventToken")
	t.Parent = folder
	live[player] = live[player] or {}
	table.insert(live[player], t)
	local taken = false
	t.Touched:Connect(function(hit)
		if taken then return end
		local who = Players:GetPlayerFromCharacter(hit.Parent)
		local p = who and Data.get(who)
		if not p then return end
		taken = true
		p.tickets = (p.tickets or 0) + Config.TicketsPerToken
		syncTickets(who, p)
		Remotes.Sfx:FireClient(who, "Coin", t.Position)
		Signals.fire("ticket", who, eventId)
		t:Destroy()
	end)
	task.delay(LIFETIME, function()
		if t.Parent then t:Destroy() end
	end)
end

function TicketService.state(player)
	local p = Data.get(player)
	if not p then return { ok = false } end
	return { ok = true, tickets = p.tickets or 0, trophies = p.trophies or {}, event = workspace:GetAttribute("Event") }
end

Actions.register("tickets", function(player)
	return TicketService.state(player)
end)

-- buy from the Ticket shop: a Config.EventShop id, or "Trophy_<EventId>" while that event runs
Actions.register("buyTicket", function(player, p, id)
	if type(id) ~= "string" then return { ok = false } end
	local have = p.tickets or 0
	local trophy = id:match("^Trophy_(%w+)$")
	if trophy then
		if not Config.EventInfo[trophy] then return { ok = false, err = "Unknown trophy" } end
		p.trophies = p.trophies or {}
		if p.trophies[trophy] then return { ok = false, err = "You already have it" } end
		if workspace:GetAttribute("Event") ~= trophy then
			return { ok = false, err = "Only during " .. Config.EventInfo[trophy].name .. "!" }
		end
		if have < Config.TrophyTickets then return { ok = false, err = "Not enough tickets" } end
		p.tickets = have - Config.TrophyTickets
		p.trophies[trophy] = true
		syncTickets(player, p)
		refreshCase(player, p)
		local n = 0
		for _ in p.trophies do n += 1 end
		Remotes.Announce:FireClient(player, ("%s TROPHY! (%d/12)"):format(Config.EventInfo[trophy].name:upper(), n), EVENT_COLORS[trophy])
		Remotes.Sfx:FireClient(player, "Cheer")
		Signals.fire("trophy", player, trophy)
		return TicketService.state(player)
	end
	local item
	for _, it in Config.EventShop do
		if it.id == id then item = it end
	end
	if not item then return { ok = false, err = "Unknown item" } end
	if have < item.tickets then return { ok = false, err = "Not enough tickets" } end
	p.tickets = have - item.tickets
	syncTickets(player, p)
	if item.kind == "letter" then
		require(script.Parent.LetterService).fill(player, item.rarity)
		Remotes.Notify:FireClient(player, item.rarity .. " Letter ready to CALL!", "good")
	elseif item.kind == "candy" then
		p.candy = (p.candy or 0) + item.amount
		player:SetAttribute("Candy", p.candy)
	end
	Remotes.Sfx:FireClient(player, "Buy")
	return TicketService.state(player)
end)

function TicketService.start()
	folder = workspace:FindFirstChild("EventTokens") or Instance.new("Folder")
	folder.Name = "EventTokens"
	folder.Parent = workspace
	-- tickets and the trophy case once the profile is loaded
	local function onJoin(player)
		for _ = 1, 40 do
			local p = Data.get(player)
			if p and PlotService.getPlot(player) then
				syncTickets(player, p)
				refreshCase(player, p)
				return
			end
			task.wait(0.5)
		end
	end
	Players.PlayerAdded:Connect(onJoin)
	for _, pl in Players:GetPlayers() do task.spawn(onJoin, pl) end
	-- and whenever the school is (re)built: assigning a plot after a slow load, a Board review
	table.insert(PlotService.rebuildHooks, function(player)
		local p = Data.get(player)
		if p then
			syncTickets(player, p)
			refreshCase(player, p)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		for _, t in live[player] or {} do
			if t.Parent then t:Destroy() end
		end
		live[player] = nil
		local plot = PlotService.getPlot(player)
		local case = plot and plot:FindFirstChild("TrophyCase")
		if case then case:Destroy() end
	end)
	-- a school that gets rebuilt (Board review) keeps its case: it lives beside the School model
	task.spawn(function()
		local clock = 0
		while true do
			task.wait(1)
			clock += 1
			local ev = workspace:GetAttribute("Event")
			if not ev then
				if next(live) then clearTokens() end
			elseif clock % SPAWN_EVERY == 0 then
				for _, player in Players:GetPlayers() do
					local list = live[player] or {}
					for i = #list, 1, -1 do
						if not list[i].Parent then table.remove(list, i) end
					end
					live[player] = list
					if #list < MAX_LIVE then pcall(spawnToken, player, ev) end
				end
			end
		end
	end)
end

-- Studio: tickets for testing
function TicketService.debugGive(player, n)
	local p = Data.get(player)
	if not p then return false end
	p.tickets = (p.tickets or 0) + (n or 50)
	syncTickets(player, p)
	return p.tickets
end

return TicketService
