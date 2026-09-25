-- ServerScriptService.Server.BoardService
-- School Board reviews (rebirths): bring the cash and the student the Board asks for, and your
-- school becomes the next kind of school. Past the last tier, Prestige stars.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)
local Actions = require(script.Parent.Actions)
local Signals = require(script.Parent.Signals)

local BoardService = {}
local busy = {}

-- what the Board wants next: { name, cash, needs (id or "Secret"), needsName, mult, floors, star }
function BoardService.next(p)
	local nxt = Config.Tiers[p.tier + 1]
	if nxt then
		return {
			name = nxt.name, cash = nxt.cash, needs = nxt.needs, mult = nxt.mult, floors = nxt.floors, lock = nxt.lock,
		}
	end
	local last = Config.Tiers[#Config.Tiers]
	local star = p.stars + 1
	return {
		name = last.name .. " " .. string.rep("\u{2605}", math.min(star, 5)),
		cash = last.cash * Config.PrestigeStep.cashMult ^ star,
		needs = "Secret",
		mult = last.mult,
		floors = last.floors,
		lock = last.lock,
		star = star,
	}
end

local function hasNeeded(p, needs)
	if not needs then return true end
	for _, e in p.students do
		if not e.arriving and not e.carried then
			local def = Config.StudentById[e.id]
			if needs == "Secret" and def.rarity == "Secret" then return true end
			if e.id == needs then return true end
		end
	end
	return false
end

Actions.register("boardInfo", function(player, p)
	local n = BoardService.next(p)
	local def = n.needs and Config.StudentById[n.needs]
	return {
		ok = true,
		current = PlotService.tierOf(p).name,
		currentMult = PlotService.tierMult(p),
		tier = p.tier,
		stars = p.stars,
		name = n.name,
		cash = n.cash,
		needs = n.needs,
		needsName = n.needs == "Secret" and "any Secret student" or (def and def.name) or nil,
		hasNeeded = hasNeeded(p, n.needs),
		hasCash = p.cash >= n.cash,
		mult = n.star and (PlotService.tierOf(p).mult * (1 + Config.PrestigeStep.bonus * n.star)) or n.mult,
		floors = n.floors,
		star = n.star,
	}
end)

Actions.register("review", function(player, p)
	if busy[player] then return { ok = false, err = "The Board is already meeting" } end
	local n = BoardService.next(p)
	if p.cash < n.cash then return { ok = false, err = "The Board wants " .. Config.formatCash(n.cash) } end
	if not hasNeeded(p, n.needs) then return { ok = false, err = "Bring the student the Board asked for" } end
	busy[player] = true
	-- nothing can be bought or sold while the Board meets (Actions refuses spending while this is set)
	p.reviewing = true
	-- the client plays the Board Room cutscene; the school changes while the screen is covered
	Remotes.Cutscene:FireClient(player, "Board", { name = n.name, star = n.star, tier = not n.star and p.tier + 1 or nil })
	task.wait(4.2)
	p.reviewing = nil
	if not player.Parent then
		busy[player] = nil
		return { ok = false }
	end
	-- still qualified? (a steal during the cutscene can take the required student)
	if p.cash < n.cash or not hasNeeded(p, n.needs) then
		busy[player] = nil
		Remotes.Notify:FireClient(player, "The Board changed its mind: you no longer meet the requirements.", "bad")
		return { ok = false, err = "Requirements no longer met" }
	end
	PlotService.clearAll(player)
	if n.star then
		p.stars = n.star
	else
		p.tier += 1
	end
	p.cash = Config.StartCash * PlotService.tierMult(p)
	p.stats.reviews += 1
	Data.sync(player)
	PlotService.applyFloors(player)
	PlotService.updateIncome(player)
	local an = n.name:match("^[AEIOUaeiou]") and "AN" or "A"
	Remotes.Announce:FireAllClients(("%s IS NOW %s %s!"):format(PlotService.schoolName(player):upper(), an, n.name:upper()), Color3.fromRGB(255, 214, 51))
	Signals.fire("review", player, p.tier, p.stars)
	busy[player] = nil
	return { ok = true, tier = p.tier, stars = p.stars }
end)

return BoardService
