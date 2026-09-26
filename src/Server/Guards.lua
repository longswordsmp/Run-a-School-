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

-- one clip at a time per guard, switched only when it changes (so a chase doesn't restart the run
-- every frame), and paced to the speed he is moving at
local function anim(g, which, speed)
	if g.anim ~= which then
		g.anim = which
		Factory.play(g.model, which, speed)
	elseif speed then
		Factory.pace(g.model, speed)
	end
end
Guards.anim = anim

-- turn a guard's root towards a flat direction at a capped rate (no one-frame about-turns)
local REACT_TURN, CHASE_TURN = 12, 9 -- radians a second
local function faceToward(root, dir, maxA)
	local lv = root.CFrame.LookVector
	local cur = Vector3.new(lv.X, 0, lv.Z)
	cur = cur.Magnitude > 1e-3 and cur.Unit or dir
	return Walkers.turn(cur, dir, maxA)
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
	g.blocked = nil
	tag(g, "")
	local speed = self.patrolSpeed
	anim(g, "walk", speed)
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
	g.blocked = nil
	tag(g, "!", rgb(255, 70, 70))
	anim(g, "idle")
end

-- stand every guard still for a while (Studio tests)
function Guards:calm(secs)
	for _, g in self.list do
		Walkers.stop(g.model)
		g.state = "stunned"
		g.target = nil
		g.stunUntil = now() + (secs or 30)
		anim(g, "idle")
	end
	return #self.list
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
			-- (a noise he may not go to leaves him on his patrol, not stuck jogging on the spot)
			local to = Vector3.new(pos.X, g.y, pos.Z)
			if self.opts.area and not self.opts.area(to) then continue end
			g.state = "investigate"
			g.target = nil
			tag(g, "?", rgb(255, 230, 90))
			anim(g, "run", 11)
			Walkers.walk(g.model, { to }, 11, function()
				if g.state ~= "investigate" then return end
				anim(g, "idle")
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
			anim(g, "idle")
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
				anim(g, "fall")
				if self.opts.onBonk then task.spawn(self.opts.onBonk, player, root.Position) end
				local start = root.CFrame
				local dir = flat.Magnitude > 1e-3 and flat.Unit or look
				-- a shorter shove where the full one would leave his area (no slide out and snap back)
				local dist = 7
				local area = self.opts.area
				while area and dist > 0 and not area(start.Position + dir * dist) do dist -= 0.5 end
				local t0 = now()
				local conn
				conn = RunService.Heartbeat:Connect(function()
					local a = math.min(1, (now() - t0) / 0.35)
					if not root.Parent then conn:Disconnect() return end
					local pos = start.Position + dir * dist * a + Vector3.new(0, math.sin(a * math.pi) * 2.2, 0)
					root.CFrame = CFrame.new(pos) * (start - start.Position)
					if a >= 1 then
						conn:Disconnect()
						-- landed: stand there dazed for the rest of the stun, not flailing on the floor
						if g.state == "stunned" then anim(g, "idle") end
					end
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
				if flat.Magnitude > 1e-3 then
					root.CFrame = CFrame.lookAt(root.Position, root.Position + faceToward(root, flat.Unit, REACT_TURN * dt))
				end
				continue
			end
			g.reactUntil = nil
			if flat.Magnitude < self.catchRange then
				if o.onCatch then task.spawn(o.onCatch, player, g) end
				self:patrol(g)
				continue
			end
			local speed = carrying and self.carrySpeed or self.chaseSpeed
			local step = math.min(flat.Magnitude, speed * dt)
			-- he turns towards the player at a capped rate and runs the way he faces
			local face = faceToward(root, flat.Unit, CHASE_TURN * dt)
			local pos = root.Position
			local np = Vector3.new(pos.X + face.X * step, g.y, pos.Z + face.Z * step)
			if o.area and not o.area(np) then
				-- at the edge of where he may go: slide along it if one axis is free, else stand and glare
				local alongX = Vector3.new(np.X, g.y, pos.Z)
				local alongZ = Vector3.new(pos.X, g.y, np.Z)
				if math.abs(face.X) * step > 0.01 and o.area(alongX) then
					np = alongX
				elseif math.abs(face.Z) * step > 0.01 and o.area(alongZ) then
					np = alongZ
				else
					np = nil
				end
			end
			if not np then
				anim(g, "idle")
				root.CFrame = CFrame.lookAt(pos, pos + face)
				continue
			end
			anim(g, "run", speed)
			local mv = Vector3.new(np.X - pos.X, 0, np.Z - pos.Z)
			root.CFrame = CFrame.lookAt(np, np + (mv.Magnitude > 1e-3 and mv.Unit or face))
		end
	end
end

return Guards
