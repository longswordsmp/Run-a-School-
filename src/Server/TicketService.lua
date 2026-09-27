-- ServerScriptService.Server.TicketService
-- Event Tickets. While an event runs you earn them by running your school: one every few seconds
-- while you're playing, and a bonus for every kid you enroll (more for the event's own kids).
-- (They used to be coins popping up on the ground around every player, which pulled people off
-- their schools to hoover the street.) Tickets buy letters and candy (Config.EventShop) and each
-- event's trophy while that event runs; trophies fill the trophy case on your lawn
-- (SchoolBuilder.trophyCase).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)
local PlotService = require(script.Parent.PlotService)
local SchoolBuilder = require(script.Parent.SchoolBuilder)

local TicketService = {}

local TRICKLE = 10 -- a ticket every this many seconds while you're playing through an event
local ACTIVE = 120 -- "playing": moved in the last two minutes
local ENROLL_BONUS, EVENT_KID_BONUS = 2, 5

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

-- tickets for a player (the goals count each one)
local function give(player, n)
	local p = Data.get(player)
	if not p or n <= 0 then return end
	-- (the 2x Event Tickets pass)
	if player:GetAttribute("Pass_DoubleTickets") then n *= 2 end
	p.tickets = (p.tickets or 0) + n
	syncTickets(player, p)
	local ev = workspace:GetAttribute("Event")
	for _ = 1, n do Signals.fire("ticket", player, ev) end
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
		Remotes.Notify:FireClient(player, "A " .. item.rarity .. " student is on the way to your Waiting Bench!", "good")
	elseif item.kind == "candy" then
		p.candy = (p.candy or 0) + item.amount
		player:SetAttribute("Candy", p.candy)
	end
	Remotes.Sfx:FireClient(player, "Buy")
	return TicketService.state(player)
end)

function TicketService.start()
	local old = workspace:FindFirstChild("EventTokens")
	if old then old:Destroy() end
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
	local lastPos, lastMove = {}, {}
	Players.PlayerRemoving:Connect(function(player)
		lastPos[player], lastMove[player] = nil, nil
		-- (a co-op crew member leaving: the case is their host's)
		if Data.isMember(player) or PlotService.isAlias(player) then return end
		local plot = PlotService.getPlot(player)
		local case = plot and plot:FindFirstChild("TrophyCase")
		if case then case:Destroy() end
	end)
	-- enrolling during an event: a bonus, bigger for the event's own kids
	Signals.on("enroll", function(player, def, grade)
		local ev = workspace:GetAttribute("Event")
		if not ev then return end
		local g = Config.GradeById[grade]
		give(player, (g and g.event == ev) and EVENT_KID_BONUS or ENROLL_BONUS)
	end)
	-- and a steady trickle while you're playing through it
	task.spawn(function()
		local clock = 0
		while true do
			task.wait(1)
			clock += 1
			local now = os.clock()
			for _, player in Players:GetPlayers() do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root then
					local last = lastPos[player]
					if not last or (root.Position - last).Magnitude > 3 then
						lastPos[player], lastMove[player] = root.Position, now
					end
				end
			end
			if workspace:GetAttribute("Event") and clock % TRICKLE == 0 then
				for _, player in Players:GetPlayers() do
					if lastMove[player] and now - lastMove[player] < ACTIVE then give(player, 1) end
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
