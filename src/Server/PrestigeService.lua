-- ServerScriptService.Server.PrestigeService
-- PRESTIGE (Config.Prestige): at Multiverse University the Board remakes your school in a new finish
-- (GOLD, then DIAMOND, then ALIEN, which needs the Close Encounters story). The school goes back to
-- Kindergarten: cash, students, tier and stars reset; upgrades, desks, supplies, builds, teachers,
-- gear, candy, diplomas, quests, the HQ and the town stay. The finish is forever and multiplies
-- tuition on top of the tier (PlotService.tierMult). Saved as p.prestige (0 = none .. 3 = Alien).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)
local Actions = require(script.Parent.Actions)
local Signals = require(script.Parent.Signals)

local PrestigeService = {}
local busy = {}

local function questDone(player, id)
	local own = Data.own(player)
	return own and own.tq and own.tq.done and own.tq.done[id] == true
end

-- the next finish and whether this school can take it: { finish, index, ok, why }
function PrestigeService.next(player, p)
	local i = (p.prestige or 0) + 1
	local f = Config.Prestige[i]
	if not f then return { done = true } end
	local why
	if p.tier < #Config.Tiers then
		why = ("Reach %s first"):format(Config.Tiers[#Config.Tiers].name)
	elseif p.cash < f.cash then
		why = ("Bring %s"):format(Config.formatCash(f.cash))
	elseif f.quest and not questDone(player, f.quest) then
		why = "Finish the Close Encounters story (strange lights over Pine Park...)"
	end
	return { finish = f, index = i, ok = why == nil, why = why }
end

local function info(player, p)
	local n = PrestigeService.next(player, p)
	local list = {}
	for i, f in Config.Prestige do
		table.insert(list, { id = f.id, name = f.name, icon = f.icon, mult = f.mult, cash = f.cash, desc = f.desc,
			owned = (p.prestige or 0) >= i, next = n.index == i, quest = f.quest ~= nil, questDone = f.quest and questDone(player, f.quest) or nil })
	end
	return { ok = true, prestige = p.prestige or 0, list = list, can = n.ok, why = n.why, done = n.done, tier = p.tier, top = #Config.Tiers,
		mult = PlotService.tierMult(p) }
end

Actions.register("prestigeInfo", function(player, p)
	return info(player, p)
end)

Actions.register("prestige", function(player, p)
	if Data.isMember(player) then return { ok = false, err = "Only " .. Data.hostOf(player).DisplayName .. " can prestige their school" } end
	local key = Data.hostOf(player)
	if busy[key] then return { ok = false, err = "The Board is already meeting" } end
	local n = PrestigeService.next(player, p)
	if not n.ok then return { ok = false, err = n.why or "Not yet" } end
	busy[key] = true
	p.reviewing = true
	Remotes.Cutscene:FireClient(player, "Prestige", { finish = n.finish.id, name = n.finish.name, mult = n.finish.mult, color = n.finish.color })
	task.wait(5)
	p.reviewing = nil
	if not player.Parent then
		busy[key] = nil
		return { ok = false }
	end
	n = PrestigeService.next(player, p)
	if not n.ok then
		busy[key] = nil
		return { ok = false, err = n.why }
	end
	PlotService.clearAll(player)
	p.prestige = n.index
	p.tier = 1
	p.stars = 0
	p.cash = Config.StartCash * PlotService.tierMult(p)
	p.stats.prestiges = (p.stats.prestiges or 0) + 1
	Data.sync(player)
	PlotService.applyFloors(player)
	PlotService.updateIncome(player)
	player:SetAttribute("Prestige", p.prestige)
	Remotes.announceAll(("%s IS NOW A %s SCHOOL!"):format(PlotService.schoolName(player):upper(), n.finish.name), n.finish.color)
	Signals.fire("prestige", player, p.prestige)
	Signals.fire("review", player, p.tier, p.stars)
	Data.saveSoon(player)
	busy[key] = nil
	return { ok = true, prestige = p.prestige }
end)

function PrestigeService.debugSet(player, n)
	local p = Data.get(player)
	p.prestige = n
	player:SetAttribute("Prestige", n)
	PlotService.applyFloors(player)
	PlotService.updateIncome(player)
	return { prestige = n, mult = PlotService.tierMult(p) }
end

function PrestigeService.start()
	local Players = game:GetService("Players")
	local function mirror(player)
		for _ = 1, 40 do
			local p = Data.get(player)
			if p then
				player:SetAttribute("Prestige", p.prestige or 0)
				return
			end
			task.wait(0.5)
		end
	end
	Players.PlayerAdded:Connect(function(player) task.spawn(mirror, player) end)
	for _, player in Players:GetPlayers() do task.spawn(mirror, player) end
end

return PrestigeService
