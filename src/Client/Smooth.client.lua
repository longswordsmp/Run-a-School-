-- StarterPlayer.StarterPlayerScripts.Smooth
-- NPCs look smooth. Every kid, teacher, goon and townsperson is moved on the server by setting its
-- root's CFrame, and those updates reach this client about 30 times a second while the screen draws
-- 60: each NPC hopped every other frame, and a street full of them read as lag (measured: a walking
-- carpet kid changed position on 95 of 179 frames). Here each moving NPC is drawn between its last
-- two server positions, a hair (INTERP_DELAY) behind, so it glides.
--   tracked   any Model with a Humanoid whose PrimaryPart is anchored and isn't a player's character
--   stills    an NPC whose position hasn't changed for a moment is left alone (no work for seated kids)
--   jumps     a teleport (more than JUMP studs between updates) snaps straight there
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local INTERP_DELAY = 0.05 -- seconds behind the newest update (a bit more than one update apart)
local JUMP = 12
local IDLE = 0.4 -- no update for this long: stop drawing, the server's position stands

local tracked = {} -- [root] = { snaps = { {t, cf} ... }, wrote = CFrame?, active = bool }

local function isPlayerChar(model)
	return Players:GetPlayerFromCharacter(model) ~= nil
end

local function track(model)
	local root = model.PrimaryPart
	if not root or tracked[root] or isPlayerChar(model) then return end
	tracked[root] = { snaps = {}, wrote = nil }
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
	for root, s in tracked do
		if not root.Anchored then continue end -- (carried or physics-driven: not ours to draw)
		local cf = root.CFrame
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
