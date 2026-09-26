-- ServerScriptService.Server.Guards
-- A squad of patrolling guards for a secured place (the Mutation Lab, Vex Prep Academy); the same
-- brain the VexCorp Factory's guards have, in one reusable piece:
--   patrol        walk a loop of waypoints
--   notice        Stealth.canSee (sneaking, sprinting, the box, smoke all count); a "!" and a moment
--                 to react, then run at them
--   chase         straight at the player, never out of `area`; lose them after `loseAfter` seconds
--                 unseen (someone carrying loot is always tracked)
--   catch         within `catchRange`: onCatch(player) (throw them out, put the loot back)
--   Ruler         a bonk stuns a guard for a few seconds and knocks him back
--   smoke/noise   Heist Gear: smoke blinds guards nearby and loses the player; a noise draws them
-- opts: { name, outfit, folder, area(pos), grounds(pos), sight = { sight, angle, hear },
--         patrolSpeed, chaseSpeed, carrySpeed, catchRange, reaction, loseAfter, stun,
--         isCarrying(player), onCatch(player, g), tag color }
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Factory = require(script.Parent.StudentFactory)
local Walkers = require(script.Parent.Walkers)
local Stealth = require(script.Parent.Stealth)

local Guards = {}
Guards.__index = Guards

local function now() return os.clock() end
local rgb = Color3.fromRGB

function Guards.new(opts)
	local self = setmetatable({}, Guards)
	self.opts = opts
	self.list = {}
	self.patrolSpeed = opts.patrolSpeed or 7
	self.chaseSpeed = opts.chaseSpeed or 15
	self.carrySpeed = opts.carrySpeed or 13.5
	self.catchRange = opts.catchRange or 3.2
	self.reaction = opts.reaction or 0.7
	self.loseAfter = opts.loseAfter or 3
	self.stun = opts.stun or 3
	return self
end

local function tag(g, text, color)
	if g.label then
		g.label.Text = text
		g.label.TextColor3 = color or rgb(255, 255, 255)
	end
end
Guards.tag = tag

function Guards:add(route, at)
	local o = self.opts
	local spec = { id = o.id or "VexGuard", name = o.name or "Security", title = o.title or "Security", mult = 1, outfit = o.outfit or "guard" }
	local model = Factory.buildTeacher(spec, 1)
	model.Name = o.name or "Guard"
	model:SetAttribute("Guard", true)
	local so = Factory.standOffset(model)
	local start = at or route[1]
	model.PrimaryPart.CFrame = CFrame.new(start.X, start.Y + so, start.Z)
	-- the floating "!" / "?"
	local head = model:FindFirstChild("Head")
	local label
	if head then
		local bb = Instance.new("BillboardGui")
		bb.Name = "Alert"
		bb.Size = UDim2.fromOffset(160, 50)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 90
		bb.Parent = head
		label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.LuckiestGuy
		label.Text = ""
		label.TextColor3 = rgb(255, 255, 255)
		label.Parent = bb
		local s = Instance.new("UIStroke")
		s.Thickness = 3
		s.Parent = label
	end
	model.Parent = o.folder
	local g = { model = model, route = route, leg = 1, state = "patrol", stunUntil = 0, so = so, label = label, y = start.Y + so }
	table.insert(self.list, g)
	self:patrol(g)
	return g
end

function Guards:patrol(g)
	g.state = "patrol"
	g.target = nil
	tag(g, "")
	Factory.play(g.model, "walk")
	local speed = self.patrolSpeed
	local function nextLeg()
		if g.state ~= "patrol" or not g.model.Parent then return end
		g.leg = g.leg % #g.route + 1
		Walkers.walk(g.model, { g.route[g.leg] }, speed, nextLeg, { flat = true })
	end
	local root = g.model.PrimaryPart
	local best, bestD = 1, math.huge
	for i, p in g.route do
		local d = (p - root.Position).Magnitude
		if d < bestD then best, bestD = i, d end
	end
	g.leg = best
	Walkers.walk(g.model, { g.route[best] }, speed, nextLeg, { flat = true })
end

function Guards:chase(g, player, reaction)
	if g.state == "chase" and g.target == player then return end
	if now() < g.stunUntil then return end
	Walkers.stop(g.model)
	g.state = "chase"
	g.target = player
	g.seenAt = now()
	g.reactUntil = now() + (reaction or self.reaction)
	tag(g, "!", rgb(255, 70, 70))
	Factory.play(g.model, "idle")
end

-- everyone after this player (an alarm)
function Guards:alertAll(player)
	for _, g in self.list do
		if now() >= g.stunUntil then self:chase(g, player, 0.4) end
	end
end

function Guards:canSee(g, char)
	local o = self.opts
	return Stealth.canSee(g.model.PrimaryPart, char, o.sight or { sight = 26, angle = 100, hear = 5 }, { o.folder })
end

function Guards:isChasing(player)
	for _, g in self.list do
		if g.state == "chase" and g.target == player then return true end
	end
	return false
end

-- a noise at pos: the patrols near it jog over and look around
function Guards:noise(pos, radius)
	for _, g in self.list do
		local r = g.model.PrimaryPart
		if r and (g.state == "patrol" or g.state == "investigate") and (r.Position - pos).Magnitude < (radius or 45) then
			g.state = "investigate"
			g.target = nil
			tag(g, "?", rgb(255, 230, 90))
			Factory.play(g.model, "run")
			local to = Vector3.new(pos.X, g.y, pos.Z)
			if self.opts.area and not self.opts.area(to) then continue end
			Walkers.walk(g.model, { to }, 11, function()
				if g.state ~= "investigate" then return end
				Factory.play(g.model, "idle")
				tag(g, "Huh?", rgb(255, 230, 90))
				task.delay(3.5, function()
					if g.state == "investigate" then self:patrol(g) end
				end)
			end, { flat = true })
		end
	end
end

-- a smoke bomb: guards near it cough for 3 s, and everyone chasing that player loses them
function Guards:smoke(player, pos)
	for _, g in self.list do
		local r = g.model.PrimaryPart
		if r and (r.Position - pos).Magnitude < 18 then
			Walkers.stop(g.model)
			g.target = nil
			g.state = "stunned"
			g.stunUntil = now() + 3
			tag(g, "*cough cough*", rgb(220, 220, 230))
			Factory.play(g.model, "idle")
		elseif g.target == player then
			self:patrol(g)
		end
	end
end

-- the Ruler: stun and knock back
function Guards:onSwing(player, proot)
	local look = Vector3.new(proot.CFrame.LookVector.X, 0, proot.CFrame.LookVector.Z)
	look = look.Magnitude > 1e-3 and look.Unit or Vector3.new(0, 0, -1)
	for _, g in self.list do
		local root = g.model.PrimaryPart
		if root and now() >= g.stunUntil then
			local d = root.Position - proot.Position
			local flat = Vector3.new(d.X, 0, d.Z)
			if flat.Magnitude < 9 and math.abs(d.Y) < 7 and (flat.Magnitude < 5.5 or flat.Unit:Dot(look) > 0.1) then
				g.stunUntil = now() + self.stun
				Walkers.stop(g.model)
				g.state = "stunned"
				tag(g, "@#!", rgb(255, 230, 90))
				Factory.play(g.model, "fall")
				if self.opts.onBonk then task.spawn(self.opts.onBonk, player, root.Position) end
				local start = root.CFrame
				local dir = flat.Magnitude > 1e-3 and flat.Unit or look
				local t0 = now()
				local conn
				conn = RunService.Heartbeat:Connect(function()
					local a = math.min(1, (now() - t0) / 0.35)
					if not root.Parent then conn:Disconnect() return end
					local pos = start.Position + dir * 7 * a + Vector3.new(0, math.sin(a * math.pi) * 2.2, 0)
					if self.opts.area and not self.opts.area(pos) then pos = start.Position end
					root.CFrame = CFrame.new(pos) * (start - start.Position)
					if a >= 1 then conn:Disconnect() end
				end)
				return true
			end
		end
	end
	return false
end

-- every frame
function Guards:tick(dt)
	local o = self.opts
	for _, g in self.list do
		local root = g.model.PrimaryPart
		if not root then continue end
		if g.state == "stunned" then
			if now() >= g.stunUntil then
				tag(g, "")
				local target = g.target
				if target and o.isCarrying and o.isCarrying(target) then self:chase(g, target) else self:patrol(g) end
			end
			continue
		end
		if g.state == "patrol" or g.state == "investigate" then
			for _, player in Players:GetPlayers() do
				local char = player.Character
				local proot = char and char:FindFirstChild("HumanoidRootPart")
				if proot and (not o.area or o.area(proot.Position)) and not player:GetAttribute("Stunned") and self:canSee(g, char) then
					self:chase(g, player)
					break
				end
			end
		elseif g.state == "chase" then
			local player = g.target
			local char = player and player.Parent and player.Character
			local proot = char and char:FindFirstChild("HumanoidRootPart")
			local carrying = player and o.isCarrying and o.isCarrying(player)
			if not proot or (o.grounds and not o.grounds(proot.Position)) then
				self:patrol(g)
				continue
			end
			if carrying or self:canSee(g, char) then g.seenAt = now() end
			if now() - g.seenAt > self.loseAfter then
				tag(g, "?", rgb(255, 230, 90))
				task.delay(0.8, function() if g.state == "patrol" then tag(g, "") end end)
				self:patrol(g)
				continue
			end
			local d = proot.Position - root.Position
			local flat = Vector3.new(d.X, 0, d.Z)
			if g.reactUntil and now() < g.reactUntil then
				if flat.Magnitude > 1e-3 then root.CFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit) end
				continue
			end
			if g.reactUntil then
				g.reactUntil = nil
				Factory.play(g.model, "run")
			end
			if flat.Magnitude < self.catchRange then
				if o.onCatch then task.spawn(o.onCatch, player, g) end
				self:patrol(g)
				continue
			end
			local speed = carrying and self.carrySpeed or self.chaseSpeed
			local step = math.min(flat.Magnitude, speed * dt)
			local np = root.Position + flat.Unit * step
			np = Vector3.new(np.X, g.y, np.Z)
			if o.area and not o.area(np) then
				-- (stops at the edge of where it may go)
				root.CFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit)
				continue
			end
			root.CFrame = CFrame.lookAt(np, np + flat.Unit)
		end
	end
end

return Guards
