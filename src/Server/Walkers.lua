-- ServerScriptService.Server.Walkers
-- Moves anchored student rigs along waypoint lists on the server (one Heartbeat for all of them).
local RunService = game:GetService("RunService")

local Walkers = {}
local active = {}

-- points: array of Vector3 (Y is ignored, the rig keeps its height); onDone(model) when finished
function Walkers.walk(model, points, speed, onDone)
	active[model] = { hrp = model.PrimaryPart, points = points, i = 1, speed = speed, onDone = onDone }
end

function Walkers.stop(model)
	active[model] = nil
end

function Walkers.isWalking(model)
	return active[model] ~= nil
end

RunService.Heartbeat:Connect(function(dt)
	for model, w in active do
		if not model.Parent or not w.hrp.Parent then
			active[model] = nil
			continue
		end
		local pos = w.hrp.Position
		local target = w.points[w.i]
		local flat = Vector3.new(target.X, pos.Y, target.Z)
		local delta = flat - pos
		local dist = delta.Magnitude
		local step = w.speed * dt
		if dist <= step then
			local look = dist > 1e-3 and delta.Unit or w.hrp.CFrame.LookVector
			w.hrp.CFrame = CFrame.lookAt(flat, flat + look)
			w.i += 1
			if w.i > #w.points then
				active[model] = nil
				if w.onDone then task.spawn(w.onDone, model) end
			end
		else
			local dir = delta.Unit
			local np = pos + dir * step
			-- turn smoothly toward the walking direction
			local cur = w.hrp.CFrame.LookVector
			local blended = cur:Lerp(dir, math.min(1, dt * 12))
			blended = Vector3.new(blended.X, 0, blended.Z)
			if blended.Magnitude < 1e-3 then blended = dir end
			w.hrp.CFrame = CFrame.lookAt(np, np + blended)
		end
	end
end)

return Walkers
