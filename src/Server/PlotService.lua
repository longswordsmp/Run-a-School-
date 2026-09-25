-- ServerScriptService.Server.PlotService
-- Plot ownership, floors, desks, seated students, tuition, collecting, selling, tier looks.
-- Slots are numbered across floors: floor f holds slots (f-1)*16+1 .. f*16, four rows of four.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Factory = require(script.Parent.StudentFactory)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)

local PlotService = {}
local plotOf = {} -- [player] = plot
local seated = {} -- [plot] = { [slot] = model }
local plotsFolder = workspace:WaitForChild("Plots")
local floorTemplates = ServerStorage:WaitForChild("FloorTemplates")

-- extra income multipliers from other systems: fn(player, profile, entry, slot, def) -> number
PlotService.multHooks = {}

---------------------------------------------------------------------------
-- slots, floors, desks
---------------------------------------------------------------------------
function PlotService.tierOf(p)
	return Config.Tiers[p.tier] or Config.Tiers[1]
end

function PlotService.floorsOf(p)
	return PlotService.tierOf(p).floors
end

function PlotService.slotFloor(slot)
	return math.ceil(slot / 16)
end

function PlotService.slotRow(slot)
	return math.ceil(((slot - 1) % 16 + 1) / 4)
end

function PlotService.floorModel(plot, f)
	if f == 1 then return plot end
	return plot.Floors:FindFirstChild("Floor" .. f)
end

function PlotService.desk(plot, slot)
	local fm = PlotService.floorModel(plot, PlotService.slotFloor(slot))
	return fm and fm.Desks:FindFirstChild("Desk" .. slot)
end

-- a newly granted floor arrives with its first two rows
function PlotService.normalizeRows(p)
	for f = 1, 3 do
		p.rows[f] = p.rows[f] or 0
		if f <= PlotService.floorsOf(p) and p.rows[f] < 2 then p.rows[f] = 2 end
	end
end

function PlotService.isUnlocked(p, slot)
	local f = PlotService.slotFloor(slot)
	if f > PlotService.floorsOf(p) then return false end
	return PlotService.slotRow(slot) <= (p.rows[f] or 0)
end

function PlotService.unlockedSlots(p)
	local out = {}
	for f = 1, PlotService.floorsOf(p) do
		for i = 1, (p.rows[f] or 0) * Config.DesksPerRow do
			table.insert(out, (f - 1) * 16 + i)
		end
	end
	return out
end

function PlotService.deskCount(p)
	return #PlotService.unlockedSlots(p)
end

function PlotService.getPlot(player)
	return plotOf[player]
end

function PlotService.plots()
	return plotOf
end

function PlotService.ownerOf(plot)
	for player, pl in plotOf do
		if pl == plot then return player end
	end
	return nil
end

function PlotService.schoolName(player)
	local p = Data.get(player)
	return (p and p.schoolName) or (player.DisplayName .. "'s School")
end

local function setSurfaceText(part, text, bg)
	for _, g in part:GetChildren() do
		if g:IsA("SurfaceGui") then
			g.Label.Text = text
			if bg then g.Label.BackgroundColor3 = bg end
		end
	end
end

function PlotService.refreshSign(player)
	local plot = plotOf[player]
	local p = Data.get(player)
	if not plot or not p then return end
	local look = Config.TierLooks[p.tier] or Config.TierLooks[#Config.TierLooks]
	setSurfaceText(plot.Sign, PlotService.schoolName(player), look.sign)
	local tierName = PlotService.tierOf(p).name
	if p.stars > 0 then
		tierName ..= "  " .. string.rep("\u{2605}", math.min(p.stars, 5)) .. (p.stars > 5 and (" x" .. p.stars) or "")
	end
	setSurfaceText(plot.TierPlate, tierName)
end

-- recolour a floor's walls, caps, floor and tiles
local function paint(root, look)
	if root:FindFirstChild("Walls") then
		for _, w in root.Walls:GetChildren() do
			if w:IsA("BasePart") then
				w.Color = w.Name:match("^Post") and look.cap or look.wall
			end
		end
	end
	if root:FindFirstChild("Caps") then
		for _, c in root.Caps:GetChildren() do
			if c:IsA("BasePart") then c.Color = look.cap end
		end
	end
	local slab = root:FindFirstChild("Floor")
	if slab then
		slab.Color = look.floor
		for _, t in slab:GetChildren() do
			if t:IsA("BasePart") then t.Color = look.tile end
		end
	end
end

function PlotService.applyLook(plot, tierIndex)
	local look = Config.TierLooks[tierIndex] or Config.TierLooks[#Config.TierLooks]
	paint(plot, look)
	for _, f in plot.Floors:GetChildren() do
		paint(f, look)
	end
end

---------------------------------------------------------------------------
-- collect pads
---------------------------------------------------------------------------
local function wirePads(plot, root)
	for _, desk in root.Desks:GetChildren() do
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

---------------------------------------------------------------------------
-- elevator
---------------------------------------------------------------------------
local function setupElevators(plot, floors)
	for f = 1, 3 do
		local fm = PlotService.floorModel(plot, f)
		if fm then
			local pad = fm.ElevatorPad
			for _, old in pad:GetChildren() do
				if old:IsA("ProximityPrompt") then old:Destroy() end
			end
			local function prompt(name, text, key, target)
				local pp = Instance.new("ProximityPrompt")
				pp.Name = name
				pp.ActionText = text
				pp.ObjectText = "Elevator"
				pp.KeyboardKeyCode = key
				pp.HoldDuration = 0
				pp.RequiresLineOfSight = false
				pp.MaxActivationDistance = 7
				pp:SetAttribute("Color", Color3.fromRGB(80, 170, 255))
				pp.Parent = pad
				pp.Triggered:Connect(function(who)
					local tm = PlotService.floorModel(plot, target)
					local char = who.Character
					if tm and char and char:FindFirstChild("HumanoidRootPart") then
						char:PivotTo(tm.ElevatorPad.CFrame * CFrame.new(0, 3.5, -4))
						Remotes.Sfx:FireClient(who, "Elevator")
					end
				end)
			end
			if f < floors then prompt("Up", "Floor " .. (f + 1) .. " \u{25B2}", Enum.KeyCode.E, f + 1) end
			if f > 1 then prompt("Down", "Floor " .. (f - 1) .. " \u{25BC}", Enum.KeyCode.Q, f - 1) end
		end
	end
end

---------------------------------------------------------------------------
-- floors, desks, looks for an owner
---------------------------------------------------------------------------
function PlotService.applyFloors(player)
	local plot = plotOf[player]
	local p = Data.get(player)
	if not plot or not p then return end
	PlotService.normalizeRows(p)
	local want = PlotService.floorsOf(p)
	for f = 2, 3 do
		local existing = plot.Floors:FindFirstChild("Floor" .. f)
		if f <= want and not existing then
			local m = floorTemplates["Floor" .. f]:Clone()
			m:PivotTo(plot.Origin.CFrame * m:GetPivot())
			m.Parent = plot.Floors
			wirePads(plot, m)
		elseif f > want and existing then
			existing:Destroy()
		end
	end
	local pad = plot.ElevatorPad
	pad.Transparency = want > 1 and 0 or 1
	pad.CanCollide = want > 1
	pad.Info.Enabled = want > 1
	setupElevators(plot, want)
	PlotService.applyLook(plot, p.tier)
	PlotService.applyDesks(player)
	PlotService.refreshSign(player)
end

-- show/hide desk rows according to what the owner has unlocked
function PlotService.applyDesks(player)
	local plot = plotOf[player]
	local p = Data.get(player)
	if not plot or not p then return end
	for f = 1, PlotService.floorsOf(p) do
		local fm = PlotService.floorModel(plot, f)
		if fm then
			for _, d in fm.Desks:GetChildren() do
				local unlocked = PlotService.isUnlocked(p, d:GetAttribute("Slot"))
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
	end
	player:SetAttribute("Desks", PlotService.deskCount(p))
end

function PlotService.freeSlot(player)
	local p = Data.get(player)
	if not p then return nil end
	for _, slot in PlotService.unlockedSlots(p) do
		if not p.students[slot] then return slot end
	end
	return nil
end

-- waypoints from a world position to a desk's chair. standOffset is the rig's root height above
-- the floor, used when the elevator carries it to an upper floor.
function PlotService.pathTo(plot, slot, from, standOffset)
	local base = plot.Origin.CFrame
	local function W(x, z)
		return base:PointToWorldSpace(Vector3.new(x, 0, z))
	end
	local desk = PlotService.desk(plot, slot)
	local lp = base:PointToObjectSpace(desk.SitPoint.Position)
	local aisleX = lp.X - 5.5
	local pts = {}
	local entry = plot.Entry.Position
	if from then
		table.insert(pts, Vector3.new(entry.X, 0, from.Z)) -- along the hallway to our gate
	end
	table.insert(pts, entry)
	table.insert(pts, plot.Spawn.Position)
	local floor = PlotService.slotFloor(slot)
	if floor > 1 then
		local groundPad = plot.ElevatorPad
		local upPad = PlotService.floorModel(plot, floor).ElevatorPad
		table.insert(pts, groundPad.Position)
		local top = upPad.Position.Y + upPad.Size.Y / 2
		table.insert(pts, { tp = Vector3.new(upPad.Position.X, top + (standOffset or 3), upPad.Position.Z) })
		table.insert(pts, W(aisleX, base:PointToObjectSpace(upPad.Position).Z - 4))
	else
		table.insert(pts, W(aisleX, base:PointToObjectSpace(plot.Spawn.Position).Z))
	end
	table.insert(pts, W(aisleX, lp.Z + 3.5))
	table.insert(pts, W(lp.X, lp.Z + 3.5))
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

---------------------------------------------------------------------------
-- seated students
---------------------------------------------------------------------------
function PlotService.place(player, slot)
	local plot = plotOf[player]
	local p = Data.get(player)
	if not plot or not p then return end
	local e = p.students[slot]
	if not e then return end
	e.arriving = nil
	local def = Config.StudentById[e.id]
	local desk = PlotService.desk(plot, slot)
	if not def or not desk then
		p.students[slot] = nil
		return
	end
	seated[plot] = seated[plot] or {}
	if seated[plot][slot] then seated[plot][slot]:Destroy() end

	local model = Factory.build(def, e.grade)
	model.Name = "Slot" .. slot
	model:SetAttribute("OwnerId", player.UserId)
	model:SetAttribute("Slot", slot)
	Factory.setMode(model, "owned")
	model.PrimaryPart.CFrame = sitCFrame(desk, model)
	local folder = plot:FindFirstChild("Students")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Students"
		folder.Parent = plot
	end
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

-- hide a seated student while it is being carried away (the entry stays until the steal resolves)
function PlotService.detachModel(plot, slot)
	local m = seated[plot] and seated[plot][slot]
	if m then
		seated[plot][slot] = nil
		m:Destroy()
	end
end

-- take a student out of a player's school (sold, stolen, reviewed); returns the entry
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

function PlotService.clearAll(player)
	local p = Data.get(player)
	if not p then return end
	for slot in p.students do
		PlotService.remove(player, slot)
	end
end

function PlotService.sell(player, plot, slot)
	if plotOf[player] ~= plot then return end
	local p = Data.get(player)
	local e = p and p.students[slot]
	if not e or e.arriving or e.carried then return end
	local def = Config.StudentById[e.id]
	local stored = math.floor(e.stored or 0)
	PlotService.remove(player, slot)
	local gain = math.floor(def.price * Config.SellFraction) + stored
	Data.addCash(player, gain)
	Remotes.Notify:FireClient(player, "Sold " .. def.name .. " for " .. Config.formatCash(gain), "good")
	Remotes.Sfx:FireClient(player, "Sell")
	Signals.fire("sell", player, def)
end

function PlotService.updatePad(plot, slot, stored)
	local desk = PlotService.desk(plot, slot)
	if not desk then return end
	desk.CollectPad.Cash.Label.Text = stored >= 1 and Config.formatCash(stored) or ""
end

---------------------------------------------------------------------------
-- income
---------------------------------------------------------------------------
function PlotService.tierMult(p)
	return PlotService.tierOf(p).mult * (1 + Config.PrestigeStep.bonus * (p.stars or 0))
end

function PlotService.incomeOf(player, e, slot)
	local p = Data.get(player)
	local def = Config.StudentById[e.id]
	local grade = Config.GradeById[e.grade] or Config.Grades[1]
	local mult = def.income * grade.mult * PlotService.tierMult(p)
	for _, hook in PlotService.multHooks do
		mult *= hook(player, p, e, slot, def)
	end
	return mult
end

function PlotService.updateIncome(player)
	local p = Data.get(player)
	if not p then return end
	local total = 0
	for slot, e in p.students do
		if not e.arriving and not e.carried then total += PlotService.incomeOf(player, e, slot) end
	end
	player:SetAttribute("IncomePerSec", total)
	return total
end

function PlotService.collect(player, slot, quiet)
	local plot = plotOf[player]
	local p = Data.get(player)
	local e = p and p.students[slot]
	if not e then return 0 end
	local amount = math.floor(e.stored or 0)
	if amount < 1 then return 0 end
	e.stored -= amount
	Data.addCash(player, amount)
	p.stats.collected += amount
	PlotService.updatePad(plot, slot, e.stored)
	if not quiet then
		Remotes.CashPop:FireClient(player, amount, PlotService.desk(plot, slot).CollectPad.Position)
	end
	Signals.fire("collect", player, amount)
	return amount
end

-- everything at once (Tuition Office pad, Janitor's Cart)
function PlotService.collectAll(player, where)
	local p = Data.get(player)
	if not p then return 0 end
	local total = 0
	for slot in p.students do
		total += PlotService.collect(player, slot, true)
	end
	if total > 0 and where then
		Remotes.CashPop:FireClient(player, total, where)
	end
	return total
end

---------------------------------------------------------------------------
-- ownership
---------------------------------------------------------------------------
function PlotService.assign(player)
	for _, plot in plotsFolder:GetChildren() do
		if plot:GetAttribute("OwnerId") == 0 then
			plot:SetAttribute("OwnerId", player.UserId)
			plotOf[player] = plot
			player:SetAttribute("Plot", plot.Name)
			PlotService.applyFloors(player)
			local p = Data.get(player)
			for slot in p.students do
				if PlotService.isUnlocked(p, slot) then
					PlotService.place(player, slot)
				else
					p.students[slot] = nil
				end
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
	for _, f in plot.Floors:GetChildren() do f:Destroy() end
	for _, d in plot.Desks:GetChildren() do
		d.CollectPad.Cash.Label.Text = ""
	end
	plot:SetAttribute("OwnerId", 0)
	plot:SetAttribute("LockedUntil", 0)
	setSurfaceText(plot.Sign, "Empty School", Config.TierLooks[2].sign)
	setSurfaceText(plot.TierPlate, "")
	plot.ElevatorPad.Transparency = 1
	plot.ElevatorPad.CanCollide = false
	plot.ElevatorPad.Info.Enabled = false
	PlotService.applyLook(plot, 2)
end

function PlotService.spawnCFrame(player)
	local plot = plotOf[player]
	if not plot then return nil end
	local sp = plot.Spawn
	-- face out toward the hallway
	return CFrame.lookAt(sp.Position, sp.Position - plot.Origin.CFrame.LookVector) + Vector3.new(0, 2, 0)
end

-- is a world position inside this plot's walls (any floor)?
function PlotService.inside(plot, pos)
	local b = plot.Bounds
	local lp = b.CFrame:PointToObjectSpace(pos)
	local h = b.Size / 2
	return math.abs(lp.X) <= h.X and math.abs(lp.Y) <= h.Y and math.abs(lp.Z) <= h.Z
end

function PlotService.start()
	for _, plot in plotsFolder:GetChildren() do
		wirePads(plot, plot)
		PlotService.applyLook(plot, 2)
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
							e.stored = (e.stored or 0) + PlotService.incomeOf(player, e, slot)
							PlotService.updatePad(plot, slot, e.stored)
						end
					end
				end
			end
		end
	end)
end

return PlotService
