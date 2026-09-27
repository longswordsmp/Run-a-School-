-- StarterPlayer.StarterPlayerScripts.Smooth
-- NPCs look smooth. Every kid, teacher, goon and townsperson is moved on the server by setting its
-- root's CFrame, and those updates reach this client about 30 times a second while the screen draws
-- 60: each NPC hopped every other frame, and a street full of them read as lag (measured: a walking
-- carpet kid changed position on 95 of 179 frames). Here each moving NPC is drawn between its last
-- two server positions, a hair (INTERP_DELAY) behind, so it glides.
--   tracked   any Model with a Humanoid whose PrimaryPart is anchored and isn't a player's character
--   stills    an NPC whose position hasn't changed for a moment is left alone (no work for seated kids)
--   jumps     a teleport (more than JUMP studs between updates) snaps straight there
--   near      only NPCs within NEAR studs of the camera and in front of it: redrawing a rig is not
--             cheap (every part welded to the root moves with it), and doing it for every walker in
--             town cost 4-8 fps (measured: 58 walkers, 1,507 parts). Farther off, or behind you, the
--             server's own updates are drawn as they come; nobody can tell at that distance.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local INTERP_DELAY = 0.05 -- seconds behind the newest update (a bit more than one update apart)
local JUMP = 12
local IDLE = 0.4 -- no update for this long: stop drawing, the server's position stands
local NEAR = 110
local IN_VIEW = 0.2 -- (cosine: roughly the camera's field of view plus a margin)

local tracked = {} -- [root] = { snaps = { {t, cf} ... }, wrote = CFrame?, active = bool }

local function isPlayerChar(model)
	return Players:GetPlayerFromCharacter(model) ~= nil
end

-- the name tags ride on the body, not the head (tomas, 2026-09-27: "students names are like
-- stuttering while walking"; measured: a walking kid's head moves unevenly frame to frame, its speed
-- swinging between about half and double its root's, as the walk bobs it, and every tag hangs off the
-- head). The tag stays the head's child (a dozen scripts look for it there) but is drawn at the root,
-- raised by how far the head sits above it, so it glides with the body.
local function steadyTag(bb, head, root)
	if not bb:IsA("BillboardGui") or bb.Adornee then return end
	local lift = head.Position.Y - root.Position.Y
	if lift <= 0 or lift > 8 then return end
	local base = bb.StudsOffsetWorldSpace
	bb.Adornee = root
	bb.StudsOffsetWorldSpace = base + Vector3.new(0, lift, 0)
	-- (the server setting a new offset: lift it again)
	local mine = bb.StudsOffsetWorldSpace
	bb:GetPropertyChangedSignal("StudsOffsetWorldSpace"):Connect(function()
		if bb.StudsOffsetWorldSpace ~= mine then
			mine = bb.StudsOffsetWorldSpace + Vector3.new(0, lift, 0)
			bb.StudsOffsetWorldSpace = mine
		end
	end)
end
local function steadyTags(model, root)
	local head = model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then return end
	for _, c in head:GetChildren() do steadyTag(c, head, root) end
	head.ChildAdded:Connect(function(c) task.defer(steadyTag, c, head, root) end)
end

local function track(model)
	local root = model.PrimaryPart
	-- (Ambient: moved on this client, never by the server: kids who ride on what they sit on (Decor),
	-- the cutscenes' actors)
	if not root or tracked[root] or isPlayerChar(model) or model:GetAttribute("Ambient") then return end
	tracked[root] = { snaps = {}, wrote = nil }
	steadyTags(model, root)
	root.AncestryChanged:Connect(function()
		if not root:IsDescendantOf(workspace) then tracked[root] = nil end
	end)
end

-- (the world streams in: a model's Humanoid can arrive before its root part does, so a model without
-- its PrimaryPart yet waits in `pending` and is tried again every half second)
local pending = {} -- [model] = true
local function consider(inst)
	if inst:IsA("Humanoid") then
		local model = inst.Parent
		if model and model:IsA("Model") then
			if model.PrimaryPart then track(model) else pending[model] = true end
		end
	elseif inst:IsA("BasePart") and inst.Name == "HumanoidRootPart" then
		local model = inst.Parent
		if model and model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
			task.defer(function()
				if model.Parent and model.PrimaryPart then track(model) end
			end)
		end
	end
end
for _, d in workspace:GetDescendants() do consider(d) end
workspace.DescendantAdded:Connect(consider)
task.spawn(function()
	while true do
		task.wait(0.5)
		for model in pending do
			if not model.Parent then
				pending[model] = nil
			elseif model.PrimaryPart then
				pending[model] = nil
				track(model)
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local cam = workspace.CurrentCamera
	local camPos, camLook = cam.CFrame.Position, cam.CFrame.LookVector
	for root, s in tracked do
		if not root.Anchored then continue end -- (carried or physics-driven: not ours to draw)
		local cf = root.CFrame
		-- far away or behind the camera: leave it to the server's updates
		local off = cf.Position - camPos
		local dist = off.Magnitude
		if dist > NEAR or (dist > 12 and off:Dot(camLook) < IN_VIEW * dist) then
			if s.wrote ~= nil then
				local newest = s.snaps[#s.snaps]
				if newest and cf == s.wrote then root.CFrame = newest.cf end
				s.wrote = nil
			end
			table.clear(s.snaps)
			continue
		end
		-- a value we didn't write is a fresh update from the server
		if s.wrote == nil or cf ~= s.wrote then
			local last = s.snaps[#s.snaps]
			if not last or (last.cf.Position - cf.Position).Magnitude > 1e-4 or last.cf.Rotation ~= cf.Rotation then
				if last and (last.cf.Position - cf.Position).Magnitude > JUMP then table.clear(s.snaps) end
				table.insert(s.snaps, { t = now, cf = cf })
				if #s.snaps > 4 then table.remove(s.snaps, 1) end
			end
		end
		local snaps = s.snaps
		local newest = snaps[#snaps]
		if not newest or now - newest.t > IDLE or #snaps < 2 then
			-- still (or just started): the server's position stands (put it back exactly once: what we
			-- last drew was a moment behind it, and the server won't send an unchanged value again)
			if s.wrote ~= nil and newest then root.CFrame = newest.cf end
			s.wrote = nil
			continue
		end
		-- draw at INTERP_DELAY behind: between the two snapshots around that moment
		local rt = now - INTERP_DELAY
		local a, b = snaps[#snaps - 1], newest
		for i = #snaps - 1, 1, -1 do
			if snaps[i].t <= rt then
				a, b = snaps[i], snaps[i + 1]
				break
			end
		end
		local span = b.t - a.t
		local alpha = span > 1e-3 and math.clamp((rt - a.t) / span, 0, 1) or 1
		local draw = a.cf:Lerp(b.cf, alpha)
		root.CFrame = draw
		s.wrote = draw
	end
end)
