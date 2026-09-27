-- Run in Studio (Client, during Play). Test helpers for playing the VexCorp Factory with real movement
-- (Humanoid:MoveTo, the same as walking): the loop uses them for the "Possible" check.
--   _G.G()                  one line: every Factory guard (pos -> facing, "!" when chasing), the cameras, you
--   _G.mv(x, z, timeout)    walk straight to a point (jumps when stuck)
--   _G.unsafe(pos)          would a guard or a camera see a sneaking player at pos? (with margins)
--   _G.sneak(points, maxT)  walk waypoints 2.5 studs at a time, waiting while the next spot is unsafe,
--                           backing off when the spot you stand on turns unsafe
--   _G.byZ(z)               the guard whose patrol runs along that z
--   _G.notes                every Notify the server sends you (reset it before a run)
local lp = game.Players.LocalPlayer
local function flat(v) return Vector3.new(v.X, 0, v.Z) end

_G.notes = {}
if _G.noteConn then _G.noteConn:Disconnect() end
_G.noteConn = game.ReplicatedStorage.Remotes.Notify.OnClientEvent:Connect(function(msg)
	table.insert(_G.notes, string.format("%.1f %s", os.clock(), tostring(msg)))
end)

_G.byZ = function(z)
	for _, m in ipairs(workspace.VexFactory.Guards:GetChildren()) do
		local r = m.PrimaryPart
		if r and math.abs(r.Position.Z - z) < 1.5 then return r end
	end
end

_G.G = function()
	local out = {}
	for i, m in ipairs(workspace.VexFactory.Guards:GetChildren()) do
		local r = m.PrimaryPart
		if r then
			local lv = r.CFrame.LookVector
			local tag = ""
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("TextLabel") and (d.Text == "!" or d.Text == "?") then tag = d.Text end
			end
			table.insert(out, ("g%d(%.0f,%.0f)->(%.1f,%.1f)%s"):format(i, r.Position.X, r.Position.Z, lv.X, lv.Z, tag))
		end
	end
	for _, c in ipairs(workspace.VexFactory.Inside.Cameras:GetChildren()) do
		local h = c:FindFirstChild("Head")
		if h then
			local lv = h.CFrame.LookVector
			table.insert(out, ("cam(%.0f)->(%.1f,%.1f)"):format(h.Position.X, lv.X, lv.Z))
		end
	end
	local r = lp.Character.HumanoidRootPart
	table.insert(out, ("me(%.1f,%.1f) move=%s heist=%s"):format(r.Position.X, r.Position.Z, tostring(lp:GetAttribute("Move")), tostring(lp:GetAttribute("Heist"))))
	return table.concat(out, " ")
end

_G.mv = function(x, z, timeout)
	local hum = lp.Character.Humanoid
	local r = hum.RootPart
	local target = Vector3.new(x, r.Position.Y, z)
	local t0 = os.clock()
	local last, stuckT = r.Position, os.clock()
	while os.clock() - t0 < (timeout or 8) do
		hum:MoveTo(target)
		if flat(target - r.Position).Magnitude < 1.2 then break end
		if (r.Position - last).Magnitude > 0.5 then
			last, stuckT = r.Position, os.clock()
		elseif os.clock() - stuckT > 0.6 then
			hum.Jump = true
			stuckT = os.clock()
		end
		task.wait(0.05)
	end
	hum:Move(Vector3.zero)
	return _G.G()
end

_G.unsafe = function(pos)
	for _, m in ipairs(workspace.VexFactory.Guards:GetChildren()) do
		local r = m.PrimaryPart
		if r then
			local d = flat(pos - r.Position)
			local look = flat(r.CFrame.LookVector)
			-- (the game's rule for a sneaking player: seen within 11.7 studs in a 70-degree cone; this
			-- allows a little more, and keeps clear of a guard's elbows when he turns round)
			if d.Magnitude < 6 then return "guard near" end
			if d.Magnitude < 12.8 and look.Magnitude > 0 and d.Unit:Dot(look.Unit) > math.cos(math.rad(45)) then return "guard sees" end
		end
	end
	for _, c in ipairs(workspace.VexFactory.Inside.Cameras:GetChildren()) do
		local h = c:FindFirstChild("Head")
		if h then
			local d = flat(pos - h.Position)
			local look = flat(h.CFrame.LookVector)
			if d.Magnitude < 36 and d.Magnitude > 7 and d.Unit:Dot(look.Unit) > math.cos(math.rad(26)) then
				-- (behind cover? the same ray the server casts)
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { lp.Character, c, workspace.VexFactory.Guards }
				local to = Vector3.new(pos.X, 3, pos.Z)
				if not workspace:Raycast(h.Position, to - h.Position, params) then return "camera" end
			end
		end
	end
	return nil
end

_G.sneak = function(points, maxT)
	local hum = lp.Character.Humanoid
	local r = hum.RootPart
	local log = {}
	local t0 = os.clock()
	local i, waited, wasIn, backs = 1, 0, false, 0
	local reasons = {}
	while i <= #points and os.clock() - t0 < (maxT or 60) do
		if r.Position.Z > 48 then wasIn = true end
		if wasIn and r.Position.Z < 45 then
			table.insert(log, ("THROWN OUT (was near wp %d)"):format(i))
			break
		end
		local tgt = Vector3.new(points[i][1], r.Position.Y, points[i][2])
		local d = flat(tgt - r.Position)
		if d.Magnitude < 1.2 then
			i += 1
		else
			local here = _G.unsafe(r.Position)
			if false and here then
				backs += 1
				hum:MoveTo(Vector3.new(points[i - 1][1], r.Position.Y, points[i - 1][2]))
				task.wait(0.25)
			else
				local step = r.Position + d.Unit * math.min(2.5, d.Magnitude)
				local why = _G.unsafe(step)
				if why then
					hum:Move(Vector3.zero)
					local key = ("%s@wp%d"):format(why, i)
					reasons[key] = (reasons[key] or 0) + 1
					waited += 0.1
					if waited > 25 then
						table.insert(log, ("stuck@(%.0f,%.0f):%s"):format(r.Position.X, r.Position.Z, why))
						break
					end
					task.wait(0.1)
				else
					-- (keep walking: aim at the waypoint itself, only the look-ahead is checked)
					waited = 0
					hum:MoveTo(tgt)
					task.wait(0.05)
				end
			end
		end
	end
	hum:Move(Vector3.zero)
	table.insert(log, ("end wp %d/%d after %.0fs, %d back-offs"):format(math.min(i, #points), #points, os.clock() - t0, backs))
	for k, n in reasons do table.insert(log, ("waited %.1fs: %s"):format(n * 0.1, k)) end
	return table.concat(log, "; ") .. "\n" .. _G.G()
end
-- k_map, the Old Sewer Map, the way a careful player does it (sneaking; C toggles sneak):
--   phase "in"    wait for the door guard's back, slip round to the west aisle, wait for both aisle
--                 guards to be on the far side, go up the aisle and round to the crates by the office
--   phase "grab"  wait behind the crates until both cameras look away and the lasers are off, go in,
--                 steal the map (hold the prompt)
--   phase "out"   (call after switching sneak off / holding sprint) run out over the belts and off the lot
local HQLasers = require(game.ReplicatedStorage.Shared.HQLasers)
local function waitUntil(fn, maxT)
	local t0 = os.clock()
	while not fn() do
		if os.clock() - t0 > (maxT or 30) then return false, os.clock() - t0 end
		task.wait(0.05)
	end
	return true, os.clock() - t0
end
local function officeLasers()
	local out = {}
	for _, d in ipairs(workspace.VexFactory.Inside.VexOffice.Lasers:GetChildren()) do table.insert(out, d) end
	return out
end
-- seconds from now until any office laser is on (0 = one is on now)
local function laserGap()
	local ls = officeLasers()
	local t = workspace:GetServerTimeNow()
	for k = 0, 40 do
		for _, l in ls do
			if HQLasers.isOn(l, t + k * 0.05) then return k * 0.05 end
		end
	end
	return 2
end
-- are all the office lasers off for the whole of [now + a, now + b]?
local function lasersOffBetween(a, b)
	local ls = officeLasers()
	local t = workspace:GetServerTimeNow()
	for k = a, b, 0.05 do
		for _, l in ls do
			if HQLasers.isOn(l, t + k) then return false end
		end
	end
	return true
end
local function camsAway()
	for _, c in ipairs(workspace.VexFactory.Inside.Cameras:GetChildren()) do
		local h = c:FindFirstChild("Head")
		if h and h.CFrame.LookVector.Z > -0.12 then return false end
	end
	return true
end
-- the cameras are turning south (away from the office) and haven't got far yet: the whole away-swing
-- is still ahead (about 5 s)
local function camsSwingingSouth()
	local heads = {}
	for _, c in ipairs(workspace.VexFactory.Inside.Cameras:GetChildren()) do
		local h = c:FindFirstChild("Head")
		if h then table.insert(heads, { h = h, z = h.CFrame.LookVector.Z }) end
	end
	task.wait(0.15)
	for _, e in heads do
		local z = e.h.CFrame.LookVector.Z
		if not (z < e.z - 0.005 and z < 0.3 and z > -0.05) then return false end
	end
	return #heads > 0
end
local function guardOn(zLeg)
	for _, m in ipairs(workspace.VexFactory.Guards:GetChildren()) do
		local r = m.PrimaryPart
		if r and math.abs(r.Position.Z - zLeg) < 1.5 then return r end
	end
end
local function routeGuard(zs, xs)
	-- the guard whose position is on one of these legs (z lines or x lines within the loop's box)
	for _, m in ipairs(workspace.VexFactory.Guards:GetChildren()) do
		local r = m.PrimaryPart
		if r then
			local p = r.Position
			for _, z in zs do if math.abs(p.Z - z) < 1.5 and math.abs(p.X) <= 26.5 then return r end end
			for _, x in xs do if math.abs(p.X - x) < 1.5 and p.Z > zs[1] - 1 and p.Z < zs[2] + 1 then return r end end
		end
	end
end

_G.mapRun = function(phase)
	local log = {}
	local T0 = os.clock()
	local function note(s) table.insert(log, ("%.1f %s"):format(os.clock() - T0, s)) end
	if phase == "in" then
		_G.mv(0, 42, 8)
		-- wait outside for the door guard's back, slip round the corner and up the west aisle (nobody
		-- patrols it) to the spot between the belts, then wait there for the office guard to walk away
		-- east and the cameras to swing south, and go round into the gap behind the crates
		local ok, waited = waitUntil(function()
			local d = _G.byZ(53)
			return d and d.CFrame.LookVector.X > 0.5 and d.Position.X > 2
		end, 30)
		note(("door guard's back: %s after %.0fs"):format(tostring(ok), waited))
		if not ok then return table.concat(log, "\n") end
		_G.mv(-3, 49.5, 3)
		_G.mv(-27.2, 51, 5)
		_G.mv(-27.2, 97.5, 6)
		-- the top of the west aisle: no guard's eyes or camera reach it. Go the moment the cameras start
		-- swinging south (about 4.7 s before they're back on the gap's mouth; the walk is about 2 s)
		note("waiting at the top of the west aisle " .. _G.G())
		ok, waited = waitUntil(camsSwingingSouth, 45)
		note(("cameras turning south: %s after %.0fs"):format(tostring(ok), waited))
		note("to the crates: " .. _G.sneak({ { -16, 98.6 }, { -9.3, 98.6 }, { -9.0, 102.5, hold = true } }, 40))
	elseif phase == "grab" then
		local here = lp.Character.HumanoidRootPart.Position
		if (Vector3.new(here.X, 0, here.Z) - Vector3.new(-9, 0, 102.5)).Magnitude > 2.5 then
			return "not in the gap behind the crates: " .. _G.G()
		end
		local ok = waitUntil(function()
			-- the office guard at the far end of his beat, or walking away from the door
			local b = _G.byZ(96)
			local guardAway = not b or (b.CFrame.LookVector.X > 0.5 and b.Position.X > 6)
			-- (the beams are crossed about 1.1-1.4 s into the dash, out of the gap and along to the door)
			return guardAway and lasersOffBetween(0.9, 1.65) and camsSwingingSouth()
		end, 90)
		note("cameras away + lasers off: " .. tostring(ok))
		-- (line up just short of the beams: they catch a body within about a stud either side of them)
		_G.mv(-9.0, 97.3, 2)
		_G.mv(0, 97.2, 2)
		_G.mv(0, 100.6, 2)
		note("in the office " .. _G.G())
		local pr = workspace.VexFactory.Inside.VexDesk.PromptSpot.PlansPrompt
		note(("prompt enabled=%s hold=%.1f"):format(tostring(pr.Enabled), pr.HoldDuration))
		pr:InputHoldBegin()
		task.wait(pr.HoldDuration + 0.25)
		pr:InputHoldEnd()
		task.wait(0.3)
		note("after steal " .. _G.G())
	elseif phase == "out" then
		-- the steal sets off the alarm: Ruler out, bonk whoever gets close (a stunned guard is knocked
		-- back and sits dazed), and run: out of the office, down the west aisle, out of the door and
		-- off the lot
		local char = lp.Character
		local hum = char.Humanoid
		local ruler = lp.Backpack:FindFirstChild("Ruler") or char:FindFirstChild("Ruler")
		if ruler and ruler.Parent ~= char then hum:EquipTool(ruler) task.wait(0.2) end
		local swings = 0
		local stop = false
		local holding = false -- (standing to take a swing at an oncoming guard)
		local function chasers()
			local r = char.HumanoidRootPart
			local best, bestD
			for _, m in ipairs(workspace.VexFactory.Guards:GetChildren()) do
				local g = m.PrimaryPart
				if g then
					local stunned = false
					for _, x in ipairs(m:GetDescendants()) do if x:IsA("TextLabel") and x.Text:find("@") then stunned = true end end
					local d = flat(g.Position - r.Position).Magnitude
					if not stunned and d < 9.8 and (not bestD or d < bestD) then best, bestD = g, d end
				end
			end
			return best, bestD
		end
		task.spawn(function()
			while not stop do
				local g, d = chasers()
				local r = char.HumanoidRootPart
				if g and ruler and ruler.Parent == char then
					-- stop, turn round to face him (a player turns the camera and clicks)
					holding = true
					hum:MoveTo(r.Position)
					hum.AutoRotate = false
					r.CFrame = CFrame.lookAt(r.Position, Vector3.new(g.Position.X, r.Position.Y, g.Position.Z))
					if d < 8.3 then
						ruler:Activate()
						swings += 1
						task.wait(0.25)
						local hit = false
						for _, x in ipairs(g.Parent:GetDescendants()) do if x:IsA("TextLabel") and x.Text:find("@") then hit = true end end
						note(("swing at %.1f studs: %s (me %.0f,%.0f)"):format(d, hit and "HIT" or "miss", r.Position.X, r.Position.Z))
						task.wait(0.5)
					end
				else
					holding = false
					hum.AutoRotate = true
				end
				task.wait(0.03)
			end
		end)
		local catchConn = game.ReplicatedStorage.Remotes.Notify.OnClientEvent:Connect(function(msg)
			if tostring(msg):find("caught") then note("CAUGHT " .. _G.G()) end
		end)
		for _, p in { { 0, 97.6 }, { -9, 97.8 }, { -27.2, 97.5 }, { -27.2, 51 }, { -3, 49 }, { 0, 30 } } do
			local t0 = os.clock()
			while os.clock() - t0 < 12 do
				if holding then
					task.wait(0.05)
				else
					hum:MoveTo(Vector3.new(p[1], char.HumanoidRootPart.Position.Y, p[2]))
					if flat(Vector3.new(p[1], 0, p[2]) - char.HumanoidRootPart.Position).Magnitude < 1.5 then break end
					task.wait(0.05)
				end
			end
		end
		stop = true
		catchConn:Disconnect()
		note(("outside after %d swings %s"):format(swings, _G.G()))
	end
	note("notes: " .. table.concat(_G.notes, " / "))
	return table.concat(log, "\n")
end
return "factorybot ready"
