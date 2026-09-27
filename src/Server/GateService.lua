-- ServerScriptService.Server.GateService
-- The laser gate: the owner locks it with the button inside the entrance; while it is up nobody
-- else can be inside the school (they are pushed back out through the gate) and nothing can be
-- stolen. Then a cooldown before it can be locked again.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local UpgradeService = require(script.Parent.UpgradeService)
local Remotes = require(script.Parent.Remotes)
local Signals = require(script.Parent.Signals)

local GateService = {}
local plotsFolder = workspace:WaitForChild("Plots")

function GateService.isLocked(plot)
	return (plot:GetAttribute("LockedUntil") or 0) > workspace:GetServerTimeNow()
end

local function setVisual(plot, locked)
	for _, p in plot.Gate:GetChildren() do
		if p.Name == "Laser" then
			p.Transparency = locked and 0.1 or 1
		elseif p.Name == "Barrier" then
			p.Transparency = locked and 0.6 or 1
		end
	end
	plot.LockButton.Button.Color = locked and Color3.fromRGB(80, 220, 110) or Color3.fromRGB(230, 40, 50)
end

function GateService.lock(player)
	local plot = PlotService.getPlot(player)
	local p = Data.get(player)
	if not plot or not p then return false end
	local now = workspace:GetServerTimeNow()
	if not UpgradeService.gateWorks(p) then
		Remotes.Notify:FireClient(player, "Your laser gate is broken! Fix it in Upgrades (Laser Gate Repair).", "bad")
		return false
	end
	if GateService.isLocked(plot) then
		Remotes.Notify:FireClient(player, ("Your gate is already locked (%ds left)."):format(math.ceil((plot:GetAttribute("LockedUntil") or now) - now)), "info")
		return false
	end
	if now < (plot:GetAttribute("CooldownUntil") or 0) then
		local left = math.ceil(plot:GetAttribute("CooldownUntil") - now)
		Remotes.Notify:FireClient(player, ("The gate is cooling down (%ds)..."):format(left), "bad")
		Signals.fire("lockCooldown", player, left)
		return false
	end
	local dur = UpgradeService.lockTimeWithPass(p)
	plot:SetAttribute("LockedUntil", now + dur)
	plot:SetAttribute("CooldownUntil", now + dur + UpgradeService.lockCooldown(p))
	setVisual(plot, true)
	Remotes.Sfx:FireClient(player, "Lock")
	Remotes.Notify:FireClient(player, ("Gate locked for %ds!"):format(dur), "good")
	Signals.fire("lock", player)
	return true
end

-- the old lasers' last zap (the First Morning): they spit sparks and go dark, lock or no lock
function GateService.fizzle(plot)
	local now = workspace:GetServerTimeNow()
	plot:SetAttribute("LockedUntil", now)
	plot:SetAttribute("CooldownUntil", now)
	for _, p in plot.Gate:GetChildren() do
		if p.Name == "Laser" and p:IsA("BasePart") then
			local a = Instance.new("Attachment")
			a.Parent = p
			local sp = Instance.new("ParticleEmitter")
			sp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sp.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 90, 60))
			sp.LightEmission = 1
			sp.Size = NumberSequence.new(0.6, 0)
			sp.Lifetime = NumberRange.new(0.3, 0.7)
			sp.Speed = NumberRange.new(8, 16)
			sp.SpreadAngle = Vector2.new(180, 180)
			sp.Rate = 0
			sp.Parent = a
			sp:Emit(40)
			game:GetService("Debris"):AddItem(a, 2)
		end
	end
	setVisual(plot, false)
end

-- push a character back out through the gate
local function eject(plot, char)
	local out = plot.Entry.CFrame * CFrame.new(0, 0, 0)
	local away = (plot.Entry.Position - plot.Spawn.Position).Unit
	char:PivotTo(CFrame.lookAt(plot.Entry.Position + away * 6 + Vector3.new(0, 1, 0), plot.Entry.Position + away * 12 + Vector3.new(0, 1, 0)))
	return out
end

function GateService.start()
	-- the First Morning's "LOCK YOUR GATE!": whatever you did before, the button works right now
	Signals.on("questStep", function(player, id)
		if id ~= "lock" then return end
		local plot = PlotService.getPlot(player)
		if plot and not GateService.isLocked(plot) then plot:SetAttribute("CooldownUntil", 0) end
	end)
	for _, plot in plotsFolder:GetChildren() do
		local btn = plot.LockButton.Button
		local pp = Instance.new("ProximityPrompt")
		pp.Name = "LockPrompt"
		pp.ActionText = "Lock Gate"
		pp.ObjectText = "Laser Gate"
		pp.HoldDuration = 0
		pp.RequiresLineOfSight = false
		pp.MaxActivationDistance = 9
		pp:SetAttribute("Color", Color3.fromRGB(255, 74, 74))
		pp:SetAttribute("OwnerOnly", true)
		pp.Parent = btn
		-- prompts check ownership through the plot model's OwnerId (see the client Prompts script)
		pp.Triggered:Connect(function(player)
			-- (anyone in the school's co-op crew can lock it)
			if plot:GetAttribute("OwnerId") == Data.hostOf(player).UserId then
				GateService.lock(player)
			end
		end)
		setVisual(plot, false)
	end

	-- countdown text, unlock, and pushing intruders out
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.2 then return end
		acc = 0
		local now = workspace:GetServerTimeNow()
		for _, plot in plotsFolder:GetChildren() do
			local owner = plot:GetAttribute("OwnerId")
			local label = plot.LockButton.Button.Info.Label
			if owner == 0 then
				label.Text = ""
				if plot.Gate.Laser.Transparency < 1 then setVisual(plot, false) end
				continue
			end
			local lockedUntil = plot:GetAttribute("LockedUntil") or 0
			local cooldown = plot:GetAttribute("CooldownUntil") or 0
			-- (broken: dark lasers, and the button says what to do about it)
			local ownerPlayer = Players:GetPlayerByUserId(owner)
			local op = ownerPlayer and Data.get(ownerPlayer)
			local broken = op and not UpgradeService.gateWorks(op)
			local prompt = plot.LockButton.Button:FindFirstChild("LockPrompt")
			if prompt then prompt.ActionText = broken and "Broken!" or "Lock Gate" end
			if broken and lockedUntil <= now then
				label.Text = "BROKEN: FIX IN UPGRADES"
				label.TextColor3 = Color3.fromRGB(255, 120, 90)
				if plot.Gate.Laser.Transparency < 1 then setVisual(plot, false) end
				continue
			end
			if lockedUntil > now then
				label.Text = ("LOCKED %ds"):format(math.ceil(lockedUntil - now))
				label.TextColor3 = Color3.fromRGB(120, 255, 140)
				for _, other in Players:GetPlayers() do
					if Data.hostOf(other).UserId ~= owner then
						local char = other.Character
						local root = char and char:FindFirstChild("HumanoidRootPart")
						if root and PlotService.inside(plot, root.Position) then
							eject(plot, char)
							Remotes.Notify:FireClient(other, "That school is locked!", "bad")
							Signals.fire("ejected", other, plot)
						end
					end
				end
			else
				if plot.Gate.Laser.Transparency < 1 then
					setVisual(plot, false)
					local ownerPlayer = Players:GetPlayerByUserId(owner)
					if ownerPlayer then
						Remotes.notifySchool(ownerPlayer, "Your gate is open again!", "bad")
						Remotes.Sfx:FireClient(ownerPlayer, "Unlock")
					end
				end
				if cooldown > now then
					label.Text = ("COOLDOWN %ds"):format(math.ceil(cooldown - now))
					label.TextColor3 = Color3.fromRGB(255, 200, 80)
				else
					label.Text = "LOCK READY"
					label.TextColor3 = Color3.new(1, 1, 1)
				end
			end
		end
	end)
end

return GateService
