-- ServerScriptService.Server.HallService
-- Students step off the bus, walk the red carpet and head to detention unless someone enrolls them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Factory = require(script.Parent.StudentFactory)
local Walkers = require(script.Parent.Walkers)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)

local HallService = {}

local hall = workspace:FindFirstChild("Hall") or Instance.new("Folder")
hall.Name = "Hall"
hall.Parent = workspace

local path = workspace.Map.HallPath
local FLOOR_Y = 0.65

local function weighted(list)
	local total = 0
	for _, x in list do total += x.weight end
	local r = math.random() * total
	for _, x in list do
		r -= x.weight
		if r <= 0 then return x end
	end
	return list[#list]
end

function HallService.roll(forceRarity, forceId)
	if forceId and Config.StudentById[forceId] then
		return Config.StudentById[forceId], weighted(Config.Grades).id
	end
	local rarity = forceRarity and Config.RarityById[forceRarity] or weighted(Config.Rarities)
	local pool = {}
	for _, s in Config.Students do
		if s.rarity == rarity.id then table.insert(pool, s) end
	end
	local def = pool[math.random(1, #pool)]
	local grade = weighted(Config.Grades)
	return def, grade.id
end

function HallService.enroll(player, model)
	if model:GetAttribute("State") ~= "Hall" then return end
	local p = Data.get(player)
	local plot = PlotService.getPlot(player)
	if not p or not plot then return end
	local def = Config.StudentById[model:GetAttribute("StudentId")]
	local grade = model:GetAttribute("Grade")
	if p.cash < def.price then
		Remotes.Notify:FireClient(player, "Not enough cash!", "bad")
		return
	end
	local slot = PlotService.freeSlot(player)
	if not slot then
		Remotes.Notify:FireClient(player, "Your school is full! Sell a student or add desks.", "bad")
		return
	end
	if not Data.addCash(player, -def.price) then return end
	model:SetAttribute("State", "Enrolled")
	local prompt = model.PrimaryPart:FindFirstChild("EnrollPrompt")
	if prompt then prompt:Destroy() end

	p.students[slot] = { id = def.id, grade = grade, stored = 0, arriving = true }
	p.index[def.id .. "|" .. grade] = true
	Remotes.Notify:FireClient(player, "Enrolled " .. def.name .. "!", "good")

	Factory.setMode(model, "walking", player.DisplayName)
	Walkers.stop(model)
	Walkers.walk(model, PlotService.pathTo(plot, slot, model.PrimaryPart.Position), 16, function()
		model:Destroy()
		local e = p.students[slot]
		if e and e.arriving and PlotService.getPlot(player) == plot then
			PlotService.place(player, slot)
			PlotService.updateIncome(player)
		end
	end)
end

function HallService.spawnOne(forceRarity, forceId)
	if not forceRarity and not forceId and #hall:GetChildren() >= Config.MaxHallStudents then return end
	local def, grade = HallService.roll(forceRarity, forceId)
	local model = Factory.build(def, grade)
	model:SetAttribute("State", "Hall")
	local hrp = model.PrimaryPart
	local start = path.Start.Position
	local y = FLOOR_Y + Factory.standOffset(model)
	-- a little sideways jitter so the line does not look like a conveyor belt
	local z = (math.random() - 0.5) * 6
	hrp.CFrame = CFrame.lookAt(Vector3.new(start.X, y, z), Vector3.new(start.X + 1, y, z))
	model.Parent = hall
	Factory.play(model, "walk")

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EnrollPrompt"
	prompt.ActionText = "Enroll " .. Config.formatCash(def.price)
	prompt.ObjectText = def.name
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.Parent = hrp
	prompt.Triggered:Connect(function(player)
		HallService.enroll(player, model)
	end)

	local finish = path.End.Position
	Walkers.walk(model, { Vector3.new(finish.X, y, z) }, Config.WalkSpeed, function()
		model:Destroy()
	end)
	return model
end

function HallService.start()
	task.spawn(function()
		while true do
			local ok, err = pcall(HallService.spawnOne)
			if not ok then warn("[Hall] spawn failed:", err) end
			task.wait(Config.SpawnInterval)
		end
	end)
end

return HallService
