-- ServerScriptService.Server.Walkers
-- Moves anchored rigs along waypoint lists on the server (one Heartbeat for all of them).
--   flat walks (the carpet): waypoints are Vector3, Y ignored, the rig keeps its height
--   3D walks (into a school): waypoints are root positions, Y included (stairs, steps)
--   { tp = Vector3 } in either kind: appear there instantly
local RunService = game:GetService("RunService")

local Walkers = {}
local active = {}

-- opts: { flat = true (default) | false }; onDone(model) runs at the last waypoint
function Walkers.walk(model, points, speed, onDone, opts)
	local flat = not (opts and opts.flat == false)
	active[model] = { hrp = model.PrimaryPart, points = points, i = 1, speed = speed, onDone = onDone, flat = flat }
end

function Walkers.stop(model)
	active[model] = nil
end

function Walkers.isWalking(model)
	return active[model] ~= nil
end

local function finish(model, w)
	active[model] = nil
	if w.onDone then task.spawn(w.onDone, model) end
end

RunService.Heartbeat:Connect(function(dt)
	for model, w in active do
		if not model.Parent or not w.hrp.Parent then
			active[model] = nil
			continue
		end
		local target = w.points[w.i]
		if type(target) == "table" then
			local look = w.hrp.CFrame.LookVector
			w.hrp.CFrame = CFrame.lookAt(target.tp, target.tp + Vector3.new(look.X, 0, look.Z))
			w.i += 1
			if w.i > #w.points then finish(model, w) end
			continue
		end
		local pos = w.hrp.Position
		local goal = w.flat and Vector3.new(target.X, pos.Y, target.Z) or target
		local delta = goal - pos
		local dist = delta.Magnitude
		local step = w.speed * dt
		-- face along the ground, even on stairs
		local ground = Vector3.new(delta.X, 0, delta.Z)
		if dist <= step then
			local look = ground.Magnitude > 1e-3 and ground.Unit or w.hrp.CFrame.LookVector
			w.hrp.CFrame = CFrame.lookAt(goal, goal + Vector3.new(look.X, 0, look.Z))
			w.i += 1
			if w.i > #w.points then finish(model, w) end
		else
			local np = pos + delta.Unit * step
			local cur = w.hrp.CFrame.LookVector
			local dir = ground.Magnitude > 1e-3 and ground.Unit or Vector3.new(cur.X, 0, cur.Z)
			local blended = cur:Lerp(dir, math.min(1, dt * 12))
			blended = Vector3.new(blended.X, 0, blended.Z)
			if blended.Magnitude < 1e-3 then blended = dir end
			w.hrp.CFrame = CFrame.lookAt(np, np + blended)
		end
	end
end)

return Walkers
