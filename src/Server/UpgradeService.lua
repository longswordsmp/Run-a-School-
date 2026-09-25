-- ServerScriptService.Server.UpgradeService
-- Buying upgrades and desk rows; the Janitor's auto-collect and the Tuition Office pad.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)
local Actions = require(script.Parent.Actions)
local Signals = require(script.Parent.Signals)

local UpgradeService = {}

function UpgradeService.level(p, id)
	return p.upgrades[id] or 0
end

-- luck that this player brings to the hallway
function UpgradeService.luck(p)
	return 1 + 0.02 * UpgradeService.level(p, "Recruitment")
end

function UpgradeService.lockTime(p)
	return PlotService.tierOf(p).lock + 8 * UpgradeService.level(p, "LockTime") + (p.lockBonus or 0)
end

function UpgradeService.lockTimeWithPass(p)
	return UpgradeService.lockTime(p) + ((p.passes and p.passes.LongLock) and 30 or 0)
end

function UpgradeService.lockCooldown(p)
	return Config.LockCooldown - 1.5 * UpgradeService.level(p, "LockCooldown")
end

function UpgradeService.carrySpeedMult(p)
	return 1 + 0.06 * UpgradeService.level(p, "HallPass")
end

-- the Collect All pad by the gate (Tuition Office)
local function ensureOfficePad(player)
	local plot = PlotService.getPlot(player)
	local p = Data.get(player)
	if not plot or not p then return end
	local existing = plot:FindFirstChild("TuitionOffice")
	if UpgradeService.level(p, "TuitionOffice") < 1 then
		if existing then existing:Destroy() end
		return
	end
	if existing then return end
	local pad = Instance.new("Part")
	pad.Name = "TuitionOffice"
	pad.Size = Vector3.new(6, 0.4, 6)
	pad.CFrame = plot.Origin.CFrame * CFrame.new(-18, 0.85, 37)
	pad.Anchored = true
	pad.CanCollide = false
	pad.Material = Enum.Material.Neon
	pad.Color = Color3.fromRGB(255, 200, 40)
	pad.Parent = plot
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(180, 50)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.MaxDistance = 80
	bb.Parent = pad
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = "COLLECT ALL"
	t.Font = Enum.Font.LuckiestGuy
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 230, 90)
	t.Parent = bb
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Parent = t
	local debounce = false
	pad.Touched:Connect(function(hit)
		if debounce then return end
		local char = hit:FindFirstAncestorOfClass("Model")
		if char ~= player.Character then return end
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - pad.Position).Magnitude > 10 then return end
		debounce = true
		PlotService.collectAll(player, pad.Position)
		task.delay(1, function() debounce = false end)
	end)
end

function UpgradeService.applyAll(player)
	ensureOfficePad(player)
	local p = Data.get(player)
	if p then player:SetAttribute("Luck", UpgradeService.luck(p)) end
end

Actions.register("upgrades", function(player, p)
	local list = {}
	for _, u in Config.Upgrades do
		local lvl = UpgradeService.level(p, u.id)
		table.insert(list, {
			id = u.id, name = u.name, icon = u.icon, desc = u.desc, level = lvl, max = u.max,
			cost = lvl < u.max and Config.upgradeCost(u.id, lvl) or nil,
		})
	end
	local rows = {}
	for f = 1, 3 do
		local owned = p.rows[f] or 0
		local costs = Config.DeskRows[f]
		rows[f] = {
			unlocked = f <= PlotService.floorsOf(p),
			owned = owned,
			max = #costs,
			cost = owned < #costs and costs[owned + 1] or nil,
		}
	end
	return { ok = true, upgrades = list, rows = rows }
end)

Actions.register("buyUpgrade", function(player, p, id)
	local u = Config.UpgradeById[id]
	if not u then return { ok = false, err = "Unknown upgrade" } end
	local lvl = UpgradeService.level(p, id)
	if lvl >= u.max then return { ok = false, err = "Maxed out" } end
	local cost = Config.upgradeCost(id, lvl)
	if not Data.addCash(player, -cost) then return { ok = false, err = "Not enough cash!" } end
	p.upgrades[id] = lvl + 1
	UpgradeService.applyAll(player)
	Remotes.Sfx:FireClient(player, "Upgrade")
	Remotes.Notify:FireClient(player, u.name .. " level " .. (lvl + 1) .. "!", "good")
	Signals.fire("upgrade", player, id, lvl + 1)
	return { ok = true }
end)

Actions.register("buyRow", function(player, p, floor)
	floor = tonumber(floor)
	if not floor or floor ~= math.floor(floor) or floor < 1 or floor > PlotService.floorsOf(p) then return { ok = false, err = "Locked floor" } end
	local owned = p.rows[floor] or 0
	local costs = Config.DeskRows[floor]
	if owned >= #costs then return { ok = false, err = "All desks unlocked" } end
	local cost = costs[owned + 1]
	if not Data.addCash(player, -cost) then return { ok = false, err = "Not enough cash!" } end
	p.rows[floor] = owned + 1
	PlotService.applyDesks(player)
	Remotes.Sfx:FireClient(player, "Upgrade")
	Remotes.Announce:FireClient(player, "NEW DESKS!", Color3.fromRGB(61, 220, 106))
	Signals.fire("desks", player, PlotService.deskCount(p))
	Signals.fire("upgrade", player, "Desks", p.rows[floor])
	return { ok = true }
end)

function UpgradeService.start()
	-- Janitor's Cart
	local last = {}
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			for player, p in Data.all() do
				local lvl = UpgradeService.level(p, "Janitor")
				if p.passes and p.passes.AutoCollect then lvl = #Config.JanitorIntervals end
				if lvl > 0 then
					local interval = Config.JanitorIntervals[lvl]
					if not last[player] or now - last[player] >= interval then
						last[player] = now
						pcall(function()
							local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
							local got = PlotService.collectAll(player, root and root.Position)
							if got > 0 then Remotes.Sfx:FireClient(player, "Collect") end
						end)
					end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
	end)
end

return UpgradeService
