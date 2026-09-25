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
	if GateService.isLocked(plot) then return false end
	if now < (plot:GetAttribute("CooldownUntil") or 0) then
		Remotes.Notify:FireClient(player, "The gate is cooling down...", "bad")
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

-- push a character back out through the gate
local function eject(plot, char)
	local out = plot.Entry.CFrame * CFrame.new(0, 0, 0)
	local away = (plot.Entry.Position - plot.Spawn.Position).Unit
	char:PivotTo(CFrame.lookAt(plot.Entry.Position + away * 6 + Vector3.new(0, 1, 0), plot.Entry.Position + away * 12 + Vector3.new(0, 1, 0)))
	return out
end

function GateService.start()
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
			if plot:GetAttribute("OwnerId") == player.UserId then
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
			if lockedUntil > now then
				label.Text = ("LOCKED %ds"):format(math.ceil(lockedUntil - now))
				label.TextColor3 = Color3.fromRGB(120, 255, 140)
				for _, other in Players:GetPlayers() do
					if other.UserId ~= owner then
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
						Remotes.Notify:FireClient(ownerPlayer, "Your gate is open again!", "bad")
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
