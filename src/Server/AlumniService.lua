-- ServerScriptService.Server.AlumniService
-- Graduation and the Alumni Hall. Hold G on one of your seated kids to graduate them: they leave
-- your school with a cap toss and you get Diplomas (Config.Diplomas by rarity, x their grade), plus
-- any tuition they were holding. Diplomas invite Alumni (Config.AlumniShop) from Ivy League on:
-- the Alumni kid walks in and takes a desk, and you pay their price like any enroll.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)
local Actions = require(script.Parent.Actions)
local PlotService = require(script.Parent.PlotService)

local AlumniService = {}

function AlumniService.diplomasFor(e)
	local def = e and Config.StudentById[e.id]
	local base = def and Config.Diplomas[def.rarity]
	if not base then return 0 end
	local g = Config.GradeById[e.grade]
	return math.floor(base * (g and g.mult or 1))
end

local function syncDiplomas(player, p)
	player:SetAttribute("Diplomas", p.diplomas or 0)
end

-- a mortarboard spins up out of the desk and a burst of confetti
local function capToss(pos)
	local cap = Instance.new("Part")
	cap.Name = "GradCap"
	cap.Size = Vector3.new(2.2, 0.2, 2.2)
	cap.Color = Color3.fromRGB(25, 25, 30)
	cap.Anchored, cap.CanCollide, cap.CanQuery, cap.CanTouch = true, false, false, false
	cap.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
	local tassel = Instance.new("Part")
	tassel.Name = "Tassel"
	tassel.Size = Vector3.new(0.2, 0.9, 0.2)
	tassel.Color = Color3.fromRGB(255, 205, 60)
	tassel.Material = Enum.Material.Neon
	tassel.Anchored, tassel.CanCollide, tassel.CanQuery, tassel.CanTouch = true, false, false, false
	local confetti = Instance.new("ParticleEmitter")
	confetti.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	confetti.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 120)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 220, 80)),
	})
	confetti.Size = NumberSequence.new(0.5, 0.2)
	confetti.Speed = NumberRange.new(8, 14)
	confetti.SpreadAngle = Vector2.new(60, 60)
	confetti.Acceleration = Vector3.new(0, -20, 0)
	confetti.Lifetime = NumberRange.new(1, 1.6)
	confetti.Rate = 0
	confetti.Parent = cap
	cap.Parent = workspace
	tassel.CFrame = cap.CFrame * CFrame.new(0.9, -0.45, 0.9)
	tassel.Parent = cap
	confetti:Emit(40)
	local goal = cap.CFrame * CFrame.new(0, 12, 0) * CFrame.Angles(0, math.rad(540), math.rad(25))
	TweenService:Create(cap, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = goal }):Play()
	TweenService:Create(tassel, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = goal * CFrame.new(0.9, -0.45, 0.9) }):Play()
	task.delay(1.6, function() cap:Destroy() end)
end

function AlumniService.graduate(player, plot, slot)
	if PlotService.getPlot(player) ~= plot then return end
	local p = Data.get(player)
	local e = p and p.students[slot]
	if not e or e.arriving or e.carried or e.away or p.reviewing then return end
	local n = AlumniService.diplomasFor(e)
	if n <= 0 then return end
	local def = Config.StudentById[e.id]
	local model = PlotService.seatedModel(plot, slot)
	local pos = model and model.PrimaryPart and model.PrimaryPart.Position
	local stored = math.floor(e.stored or 0)
	PlotService.remove(player, slot)
	if stored > 0 then Data.addCash(player, stored) end
	p.diplomas = (p.diplomas or 0) + n
	syncDiplomas(player, p)
	if pos then capToss(pos) end
	Remotes.Notify:FireClient(player, ("%s graduated! +%d \u{1F393} Diplomas"):format(def.name, n), "good")
	Remotes.Sfx:FireClient(player, "Cheer")
	Signals.fire("graduate", player, def, n)
end

function AlumniService.state(player)
	local p = Data.get(player)
	if not p then return { ok = false } end
	local shop = {}
	for i, a in Config.AlumniShop do
		local def = Config.StudentById[a.id]
		shop[i] = { id = a.id, name = def.name, diplomas = a.diplomas, price = def.price, income = def.income, invited = (p.alumni or {})[a.id] == true }
	end
	return { ok = true, diplomas = p.diplomas or 0, tier = p.tier, openTier = Config.AlumniTier, shop = shop }
end

Actions.register("alumni", function(player)
	return AlumniService.state(player)
end)

-- invite an Alumni: they walk in from the bus stop and take a desk (you pay their price on enroll)
Actions.register("inviteAlumni", function(player, p, id)
	if type(id) ~= "string" then return { ok = false } end
	local item
	for _, a in Config.AlumniShop do
		if a.id == id then item = a end
	end
	if not item then return { ok = false, err = "Unknown Alumni" } end
	p.alumni = p.alumni or {}
	if p.alumni[id] then return { ok = false, err = "Already invited" } end
	if (p.tier or 1) < Config.AlumniTier then
		return { ok = false, err = "The Alumni Hall opens at " .. Config.Tiers[Config.AlumniTier].name }
	end
	if (p.diplomas or 0) < item.diplomas then return { ok = false, err = "Not enough Diplomas" } end
	local def = Config.StudentById[id]
	if p.cash < def.price then return { ok = false, err = "You need " .. Config.formatCash(def.price) .. " to enroll them" } end
	if not PlotService.freeSlot(player) then return { ok = false, err = "Free a desk first" } end
	local HallService = require(script.Parent.HallService)
	local model = HallService.spawnOne(nil, id, nil, nil, true)
	if model then
		model:SetAttribute("ReservedFor", player.UserId)
		HallService.enroll(player, model)
	end
	if not model or model:GetAttribute("State") ~= "Enrolled" then
		if model and model.Parent then model:Destroy() end
		return { ok = false, err = "They couldn't enroll right now. Try again!" }
	end
	p.diplomas -= item.diplomas
	p.alumni[id] = true
	syncDiplomas(player, p)
	Remotes.Announce:FireClient(player, ("%s IS BACK!"):format(def.name:upper()), Color3.fromRGB(255, 200, 90))
	Remotes.Sfx:FireClient(player, "Rare")
	return AlumniService.state(player)
end)

function AlumniService.start()
	PlotService.onGraduate = AlumniService.graduate
	local function onJoin(player)
		for _ = 1, 40 do
			local p = Data.get(player)
			if p then
				syncDiplomas(player, p)
				return
			end
			task.wait(0.5)
		end
	end
	Players.PlayerAdded:Connect(onJoin)
	for _, pl in Players:GetPlayers() do task.spawn(onJoin, pl) end
end

-- Studio: diplomas for testing
function AlumniService.debugGive(player, n)
	local p = Data.get(player)
	if not p then return false end
	p.diplomas = (p.diplomas or 0) + (n or 1000)
	syncDiplomas(player, p)
	return p.diplomas
end

return AlumniService
