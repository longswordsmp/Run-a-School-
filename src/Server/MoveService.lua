-- ServerScriptService.Server.MoveService
-- Sprint and sneak, decided here (the client only asks):
--   sprint  x1.5 speed, drains stamina (about 5 s from full); noisy: guards hear you through walls
--   sneak   x0.55 speed; quiet and hard to spot: guards see half as far, in a narrower cone, and
--           don't hear you at all
-- Stamina refills once you stop sprinting; run it dry and you're winded until it's back to 30.
-- Mirrored for the client: player attributes "Move" ("sprint" / "sneak" / nil) and "Stamina" (0-100).
-- StealService.setSpeed multiplies every speed (walking, carrying, the Factory carry) by mult().
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Actions = require(script.Parent.Actions)

local MoveService = {}

local SPRINT, SNEAK = 1.5, 0.55
local DRAIN, REGEN, REGEN_DELAY, WINDED_UNTIL = 20, 26, 0.7, 30
MoveService.SPRINT, MoveService.SNEAK = SPRINT, SNEAK

local state = {} -- [player] = { mode, stamina, lastSprint, winded, lastSent }

local function st(player)
	local s = state[player]
	if not s then
		s = { mode = nil, stamina = 100, lastSprint = 0, winded = false, lastSent = 100 }
		state[player] = s
	end
	return s
end

local function apply(player)
	local s = st(player)
	player:SetAttribute("Move", s.mode)
	require(script.Parent.StealService).setSpeed(player)
end

-- the speed multiplier for whatever the player is doing right now
local function energized(player)
	return (player:GetAttribute("EnergyUntil") or 0) > workspace:GetServerTimeNow()
end

function MoveService.mult(player)
	local sneak = SNEAK * (player:GetAttribute("SilentSneakers") and 1.35 or 1)
	-- (a kid in a cardboard box shuffles)
	if player:GetAttribute("Boxed") then return sneak end
	local s = state[player]
	if not s or not s.mode then return 1 end
	if s.mode == "sprint" then return SPRINT * (energized(player) and 1.1 or 1) end
	return sneak
end

function MoveService.mode(player)
	local s = state[player]
	return s and s.mode
end

function MoveService.set(player, mode)
	local s = st(player)
	if mode ~= "sprint" and mode ~= "sneak" then mode = nil end
	if mode == "sprint" and (s.winded or s.stamina <= 1 or player:GetAttribute("Boxed")) then mode = nil end
	if s.mode == mode then return end
	s.mode = mode
	apply(player)
end

Actions.register("move", function(player, p, mode)
	MoveService.set(player, mode)
	return { ok = true, mode = st(player).mode }
end)

function MoveService.start()
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for player, s in state do
			if not player.Parent then
				state[player] = nil
				continue
			end
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local v = root and root.AssemblyLinearVelocity
			local moving = v and Vector3.new(v.X, 0, v.Z).Magnitude > 1.5
			local shoes = player:GetAttribute("RunningShoes")
			if s.mode == "sprint" and moving then
				local drain = energized(player) and 0 or DRAIN * (shoes and 0.66 or 1)
				s.stamina = math.max(0, s.stamina - drain * dt)
				s.lastSprint = now
				if s.stamina <= 0 then
					s.winded = true
					s.mode = nil
					apply(player)
				end
			elseif now - s.lastSprint > REGEN_DELAY then
				s.stamina = math.min(100, s.stamina + REGEN * (shoes and 1.4 or 1) * dt)
			end
			if s.winded and s.stamina >= WINDED_UNTIL then s.winded = false end
			-- (only when it has moved enough to matter: attributes replicate)
			if math.abs(s.stamina - s.lastSent) >= 2 or (s.stamina == 100 and s.lastSent ~= 100) or (s.stamina == 0 and s.lastSent ~= 0) then
				s.lastSent = s.stamina
				player:SetAttribute("Stamina", math.floor(s.stamina + 0.5))
			end
			player:SetAttribute("Winded", s.winded or nil)
		end
	end)
	local function watch(player)
		st(player)
		player:SetAttribute("Stamina", 100)
		-- a new character starts walking normally
		player.CharacterAdded:Connect(function()
			local s = st(player)
			s.mode = nil
			player:SetAttribute("Move", nil)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do watch(player) end
	Players.PlayerRemoving:Connect(function(player) state[player] = nil end)
end

return MoveService
