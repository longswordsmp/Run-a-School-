-- StarterPlayer.StarterPlayerScripts.GearMoves
-- The moves that go with using gear, on everyone this client can see (GearService sets the character
-- attribute GearMove to "drink:<time>" and so on):
--   drink   Energy Drink: the can up to the mouth, head tipped back, a couple of gulps, and down
--   throw   Whoopee Cushion: wound up over the shoulder and hurled overarm (it leaves the hand)
--   slam    Smoke Bomb: raised high and slammed down at your feet, knees bending into it
-- Poses the body's own joints for a moment in Stepped, after the animations have run (like HoverRide:
-- Motor6D or AnimationConstraint joints, never an accessory's). Right arm; the tool is in the right hand.
-- (R15: turning a joint about +X swings a hanging limb forward, and tips the head back.)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local rad, clamp = math.rad, math.clamp

local LEN = { drink = 1.15, throw = 0.6, slam = 0.55 }
local RELEASE = { throw = 0.3, slam = 0.24 } -- (when it leaves the hand)

local active = {} -- [character] = { kind, t0, joints, hidden }

local function jointsOf(char)
	local m = {}
	for _, part in char:GetChildren() do
		if part:IsA("BasePart") then
			for _, d in part:GetChildren() do
				if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then m[d.Name] = d end
			end
		end
	end
	return m
end

local function ease(a) return a * a * (3 - 2 * a) end
local function seg(t, a, b) return ease(clamp((t - a) / (b - a), 0, 1)) end

-- each move at t seconds in: the pose (shoulder forward/up, shoulder out, elbow bend, head back, waist
-- turn, crouch) and how much of it to show over what the animations are doing (it eases in from the
-- tool-holding pose and back into it, rather than snapping)
local MOVES = {
	drink = function(t)
		local w = seg(t, 0, 0.3) * (1 - seg(t, 0.85, 1.15))
		local gulp = math.sin(t * 11) * 4 * seg(t, 0.35, 0.45) * (1 - seg(t, 0.75, 0.85))
		return 128, -14, 108 + gulp, 24 + gulp * 0.5, 0, 0, w
	end,
	throw = function(t)
		local wind, fling = seg(t, 0, 0.2), seg(t, 0.2, 0.34)
		local w = seg(t, 0, 0.06) * (1 - seg(t, 0.4, 0.6))
		-- up and back over the shoulder, then over the top and down in front
		return 165 * wind - 115 * fling, -10, 75 * wind - 75 * fling, 0, -28 * wind + 50 * fling, 0, w
	end,
	slam = function(t)
		local up, down = seg(t, 0, 0.18), seg(t, 0.18, 0.27)
		local w = seg(t, 0, 0.06) * (1 - seg(t, 0.35, 0.55))
		return 150 * up - 175 * down, -8, 35 * up * (1 - down), -14 * down, 0, down, w
	end,
}

local function heldParts(char)
	local tool = char:FindFirstChildOfClass("Tool")
	local list = {}
	for _, d in tool and tool:GetDescendants() or {} do
		if d:IsA("BasePart") then table.insert(list, d) end
	end
	return list
end

local function start(char, kind)
	if not MOVES[kind] then return end
	local old = active[char]
	if old and old.hidden then
		for _, p in old.hidden do p.LocalTransparencyModifier = 0 end
	end
	active[char] = { kind = kind, t0 = os.clock(), joints = jointsOf(char) }
end

local function watch(char)
	char:GetAttributeChangedSignal("GearMove"):Connect(function()
		local v = char:GetAttribute("GearMove")
		if type(v) == "string" then start(char, v:match("^(%a+)")) end
	end)
end
local function watchPlayer(player)
	player.CharacterAdded:Connect(watch)
	if player.Character then watch(player.Character) end
end
Players.PlayerAdded:Connect(watchPlayer)
for _, p in Players:GetPlayers() do watchPlayer(p) end

-- (in Stepped a joint's Transform still holds what the animations set this frame: blend from that)
local weight = 1
local function set(j, cf)
	if j then j.Transform = j.Transform:Lerp(cf, weight) end
end

RunService.Stepped:Connect(function()
	local now = os.clock()
	for char, a in active do
		local t = now - a.t0
		if not char.Parent or t > LEN[a.kind] then
			if a.hidden then
				for _, p in a.hidden do p.LocalTransparencyModifier = 0 end
			end
			active[char] = nil
			continue
		end
		-- what's thrown is out of the hand from the release to the end (another comes out after)
		if RELEASE[a.kind] and t >= RELEASE[a.kind] and not a.hidden then
			a.hidden = heldParts(char)
			for _, p in a.hidden do p.LocalTransparencyModifier = 1 end
		end
		local sh, shOut, elbow, head, waist, crouch, w = MOVES[a.kind](t)
		weight = w
		local j = a.joints
		set(j.RightShoulder, CFrame.Angles(rad(sh), 0, rad(shOut)))
		set(j.RightElbow, CFrame.Angles(rad(elbow), 0, 0))
		if head ~= 0 then set(j.Neck, CFrame.Angles(rad(head), 0, 0)) end
		if waist ~= 0 then set(j.Waist, CFrame.Angles(0, rad(waist), 0)) end
		if crouch > 0 then
			-- (knees bend into the slam, hips sinking with them)
			set(j.Root, CFrame.new(0, -0.55 * crouch, 0))
			for _, side in { "Left", "Right" } do
				set(j[side .. "Hip"], CFrame.Angles(rad(38 * crouch), 0, 0))
				set(j[side .. "Knee"], CFrame.Angles(rad(-66 * crouch), 0, 0))
				set(j[side .. "Ankle"], CFrame.Angles(rad(28 * crouch), 0, 0))
			end
		end
	end
end)
