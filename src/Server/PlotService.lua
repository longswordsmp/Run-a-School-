-- ServerScriptService.Server.PlotService
-- Plot ownership, desks, seated students, tuition ticking, collect pads, sell.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Factory = require(script.Parent.StudentFactory)
local Remotes = require(script.Parent.Remotes)

local PlotService = {}
local plotOf = {} -- [player] = plot
local seated = {} -- [plot] = { [slot] = model }

local plotsFolder = workspace:WaitForChild("Plots")

local function setSign(plot, text)
	for _, g in plot.Sign:GetChildren() do
		if g:IsA("SurfaceGui") then g.Label.Text = text end
	end
end

function PlotService.getPlot(player)
	return plotOf[player]
end

function PlotService.ownerOf(plot)
	local id = plot:GetAttribute("OwnerId")
	return id and id ~= 0 and Players:GetPlayerByUserId(id) or nil
end

function PlotService.desk(plot, slot)
	return plot.Desks:FindFirstChild("Desk" .. slot)
end

function PlotService.schoolName(player)
	local p = Data.get(player)
	return (p and p.schoolName) or (player.DisplayName .. "'s School")
end

function PlotService.refreshSign(player)
	local plot = plotOf[player]
	if plot then setSign(plot, PlotService.schoolName(player)) end
end

-- show/hide desk rows according to how many desks the player owns
function PlotService.applyDesks(player)
	local plot = plotOf[player]
	local p = Data.get(player)
	if not plot or not p then return end
	for _, d in plot.Desks:GetChildren() do
		local slot = d:GetAttribute("Slot")
		local unlocked = slot <= p.desks
		d:SetAttribute("Locked", not unlocked)
		for _, bp in d:GetDescendants() do
			if bp:IsA("BasePart") and bp.Name ~= "SitPoint" then
				bp.Transparency = unlocked and 0 or 0.8
				bp.CanCollide = unlocked and bp.Name ~= "CollectPad"
			end
		end
		d.CollectPad.Cash.Enabled = unlocked
	end
end

function PlotService.freeSlot(player)
	local p = Data.get(player)
	if not p then return nil end
	for slot = 1, p.desks do
		if not p.students[slot] then return slot end
	end
	return nil
end

-- waypoints from a world position to the chair of a desk
function PlotService.pathTo(plot, slot, from)
	local desk = PlotService.desk(plot, slot)
	local sit = desk.SitPoint.CFrame
	local entry = plot.Entry.Position
	local inside = plot.Spawn.Position
	local base = plot.Floor.CFrame
	local lp = base:PointToObjectSpace(sit.Position) -- chair in plot space
	local aisleX = lp.X - 5.5
	local pts = {}
	if from then
		table.insert(pts, Vector3.new(entry.X, 0, from.Z)) -- along the hallway to our gate
	end
	table.insert(pts, entry)
	table.insert(pts, inside)
	table.insert(pts, base:PointToWorldSpace(Vector3.new(aisleX, 0, base:PointToObjectSpace(inside).Z)))
	table.insert(pts, base:PointToWorldSpace(Vector3.new(aisleX, 0, lp.Z + 3.5)))
	table.insert(pts, base:PointToWorldSpace(Vector3.new(lp.X, 0, lp.Z + 3.5)))
	return pts
end

local function sitCFrame(desk, model)
	local sit = desk.SitPoint.CFrame
	local seatTop = desk.Seat.Position.Y + desk.Seat.Size.Y / 2
	local hrp = model.PrimaryPart
	-- the R15 sit pose folds the legs forward; the root rides about half a root-height over the seat
	local y = seatTop + hrp.Size.Y * 0.5 + model:FindFirstChildOfClass("Humanoid").HipHeight * 0.1
	return CFrame.new(sit.Position.X, y, sit.Position.Z) * sit.Rotation
end

function PlotService.place(player, slot)
	local plot = plotOf[player]
	local p = Data.get(player)
	if not plot or not p then return end
	local e = p.students[slot]
	if not e then return end
	e.arriving = nil
	local def = Config.StudentById[e.id]
	if not def then
		p.students[slot] = nil
		return
	end
	seated[plot] = seated[plot] or {}
	if seated[plot][slot] then seated[plot][slot]:Destroy() end

	local desk = PlotService.desk(plot, slot)
	local model = Factory.build(def, e.grade)
	model.Name = "Slot" .. slot
	model:SetAttribute("OwnerId", player.UserId)
	model:SetAttribute("Slot", slot)
	Factory.setMode(model, "owned")
	model.PrimaryPart.CFrame = sitCFrame(desk, model)
	local folder = plot:FindFirstChild("Students") or Instance.new("Folder")
	folder.Name = "Students"
	folder.Parent = plot
	model.Parent = folder
	Factory.play(model, "sit")

	local sell = Instance.new("ProximityPrompt")
	sell.Name = "SellPrompt"
	sell.ActionText = "Sell " .. Config.formatCash(def.price * Config.SellFraction)
	sell.ObjectText = def.name
	sell.HoldDuration = 1
	sell.KeyboardKeyCode = Enum.KeyCode.F
	sell.RequiresLineOfSight = false
	sell.MaxActivationDistance = 8
	sell:SetAttribute("OwnerOnly", true)
	sell:SetAttribute("Color", Color3.fromRGB(255, 159, 26))
	sell.Parent = model.PrimaryPart
	sell.Triggered:Connect(function(who)
		PlotService.sell(who, plot, slot)
	end)

	local steal = Instance.new("ProximityPrompt")
	steal.Name = "StealPrompt"
	steal.ActionText = "Steal"
	steal.ObjectText = def.name
	steal.HoldDuration = 1.5
	steal.RequiresLineOfSight = false
	steal.MaxActivationDistance = 8
	steal:SetAttribute("OthersOnly", true)
	steal:SetAttribute("Color", Color3.fromRGB(255, 74, 74))
	steal.Parent = model.PrimaryPart
	steal.Triggered:Connect(function(who)
		if PlotService.onSteal then PlotService.onSteal(who, plot, slot) end
	end)

	seated[plot][slot] = model
	PlotService.updatePad(plot, slot, e.stored or 0)
	return model
end

function PlotService.seatedModel(plot, slot)
	return seated[plot] and seated[plot][slot]
end

-- remove a student from a player's school (sell / stolen); returns the entry
function PlotService.remove(player, slot)
	local plot = plotOf[player]
	local p = Data.get(player)
	if not p then return nil end
	local e = p.students[slot]
	p.students[slot] = nil
	if plot then
		local m = seated[plot] and seated[plot][slot]
		if m then m:Destroy() end
		if seated[plot] then seated[plot][slot] = nil end
		PlotService.updatePad(plot, slot, 0)
	end
	PlotService.updateIncome(player)
	return e
end

function PlotService.sell(player, plot, slot)
	if plotOf[player] ~= plot then return end
	local p = Data.get(player)
	local e = p and p.students[slot]
	if not e or e.arriving then return end
	local def = Config.StudentById[e.id]
	local stored = math.floor(e.stored or 0)
	PlotService.remove(player, slot)
	local gain = math.floor(def.price * Config.SellFraction) + stored
	Data.addCash(player, gain)
	Remotes.Notify:FireClient(player, "Sold " .. def.name .. " for " .. Config.formatCash(gain), "good")
end

function PlotService.updatePad(plot, slot, stored)
	local desk = PlotService.desk(plot, slot)
	if not desk then return end
	local lbl = desk.CollectPad.Cash.Label
	lbl.Text = stored >= 1 and Config.formatCash(stored) or ""
end

function PlotService.incomeOf(player, e)
	local p = Data.get(player)
	local def = Config.StudentById[e.id]
	local grade = Config.GradeById[e.grade] or Config.Grades[1]
	local mult = 1 + 0.5 * (p and p.rebirths or 0)
	return def.income * grade.mult * mult
end

function PlotService.updateIncome(player)
	local p = Data.get(player)
	if not p then return end
	local total = 0
	for _, e in p.students do
		if not e.arriving then total += PlotService.incomeOf(player, e) end
	end
	player:SetAttribute("IncomePerSec", total)
end

function PlotService.collect(player, slot)
	local plot = plotOf[player]
	local p = Data.get(player)
	local e = p and p.students[slot]
	if not e then return end
	local amount = math.floor(e.stored or 0)
	if amount < 1 then return end
	e.stored -= amount
	Data.addCash(player, amount)
	PlotService.updatePad(plot, slot, e.stored)
	Remotes.CashPop:FireClient(player, amount, PlotService.desk(plot, slot).CollectPad.Position)
end

function PlotService.assign(player)
	for _, plot in plotsFolder:GetChildren() do
		if plot:GetAttribute("OwnerId") == 0 then
			plot:SetAttribute("OwnerId", player.UserId)
			plotOf[player] = plot
			player:SetAttribute("Plot", plot.Name)
			PlotService.refreshSign(player)
			PlotService.applyDesks(player)
			local p = Data.get(player)
			for slot in p.students do
				PlotService.place(player, slot)
			end
			PlotService.updateIncome(player)
			return plot
		end
	end
	warn("[Plots] no free plot for", player.Name)
	return nil
end

function PlotService.release(player)
	local plot = plotOf[player]
	if not plot then return end
	plotOf[player] = nil
	if seated[plot] then
		for _, m in seated[plot] do m:Destroy() end
		seated[plot] = nil
	end
	for _, d in plot.Desks:GetChildren() do
		d.CollectPad.Cash.Label.Text = ""
	end
	plot:SetAttribute("OwnerId", 0)
	plot:SetAttribute("LockedUntil", 0)
	setSign(plot, "Empty School")
end

function PlotService.spawnCFrame(player)
	local plot = plotOf[player]
	if not plot then return nil end
	local sp = plot.Spawn
	-- face out toward the hallway
	return CFrame.lookAt(sp.Position, sp.Position + plot.Floor.CFrame.LookVector * -1) + Vector3.new(0, 2, 0)
end

function PlotService.start()
	-- collect pads
	for _, plot in plotsFolder:GetChildren() do
		for _, desk in plot.Desks:GetChildren() do
			local slot = desk:GetAttribute("Slot")
			desk.CollectPad.Touched:Connect(function(hit)
				local char = hit:FindFirstAncestorOfClass("Model")
				local player = char and Players:GetPlayerFromCharacter(char)
				if player and plotOf[player] == plot then
					PlotService.collect(player, slot)
				end
			end)
		end
	end
	-- tuition tick
	task.spawn(function()
		while true do
			task.wait(1)
			for player, p in Data.all() do
				local plot = plotOf[player]
				if plot then
					for slot, e in p.students do
						if not e.arriving and not e.carried then
							e.stored = (e.stored or 0) + PlotService.incomeOf(player, e)
							PlotService.updatePad(plot, slot, e.stored)
						end
					end
				end
			end
		end
	end)
end

return PlotService
