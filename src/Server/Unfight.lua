-- ServerScriptService.Server.Unfight
-- Z-fighting, fixed after the fact. The builders put a lot of faces in exactly the same plane: a
-- house wall and its base band, a pilaster flush with a school wall, two road markings on the same
-- asphalt, a mullion flush with its window, a skirting board flush with a wall. Two surfaces in one
-- plane flicker between their colours as the camera moves ("parts inside of parts show 2 different
-- colors"). A scan of the live map found 10,802 such pairs.
-- For each pair of block parts with a face in the same plane, facing the same way, overlapping and
-- looking different, the smaller one grows 0.05 studs along that face's axis, so its face stands
-- just in front and wins cleanly. Undersides (faces pointing down) are left alone: nobody sees them.
-- Only anchored parts are touched (never a rig, a tool, a welded prop or anything that moves).
-- It also makes every surface smooth (Unfight.smooth: no stray studs or inlets), then puts the studs
-- back where the stud style wants them (StudStyle.run: the big blocks' tops and sides).
--   Unfight.run(root)   one pass over everything under root; returns how many parts it grew
--   Unfight.watch(root) run again on a child of root a moment after parts stop being added to it
--                       (the schools are rebuilt at runtime)
local StudStyle = require(script.Parent.StudStyle)

local Unfight = {}

local EPS = 0.012
local GROW = 0.05
local AX = { Vector3.xAxis, Vector3.yAxis, Vector3.zAxis }

local function eligible(p)
	return p:IsA("Part") and p.Shape == Enum.PartType.Block and p.Anchored and p.Transparency < 0.95
		and not p:FindFirstChildOfClass("SpecialMesh")
end

local function isRig(p)
	local m = p:FindFirstAncestorOfClass("Model")
	while m do
		if m:FindFirstChildOfClass("Humanoid") then return true end
		m = m:FindFirstAncestorOfClass("Model")
	end
	return false
end

-- the faces of a part: world normal, a point on the face, and which local axis it's on
local function faces(p)
	local cf, h = p.CFrame, p.Size / 2
	local out = {}
	for i, a in AX do
		local n = cf:VectorToWorldSpace(a)
		local ext = (i == 1 and h.X) or (i == 2 and h.Y) or h.Z
		for _, s in { 1, -1 } do
			table.insert(out, { n = n * s, c = cf.Position + n * s * ext, i = i })
		end
	end
	return out
end

-- the half-width of part b measured along a world direction
local function halfAlong(b, dir)
	local d = b.CFrame:VectorToObjectSpace(dir)
	local h = b.Size / 2
	return math.abs(d.X) * h.X + math.abs(d.Y) * h.Y + math.abs(d.Z) * h.Z
end

local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Include

local function pass(root)
	local list = {}
	for _, p in root:GetDescendants() do
		if eligible(p) and not isRig(p) then table.insert(list, p) end
	end
	params.FilterDescendantsInstances = { root }
	local grow = {} -- part -> Vector3 of extra size (local axes)
	local seen = {}
	for n, a in list do
		local fa = faces(a)
		for _, b in workspace:GetPartBoundsInBox(a.CFrame, a.Size + Vector3.one * 0.05, params) do
			-- (each pair once: seen[a][b], whichever of the two came first)
			if b ~= a and eligible(b) and not (seen[b] and seen[b][a]) and not (seen[a] and seen[a][b]) then
				seen[a] = seen[a] or {}
				seen[a][b] = true
				if a.Color ~= b.Color or a.Material ~= b.Material or math.abs(a.Transparency - b.Transparency) > 0.05 then
					for _, f in fa do
						if f.n.Y > -0.9 then -- (not an underside)
							for _, g in faces(b) do
								if f.n:Dot(g.n) > 0.999 and math.abs((g.c - f.c):Dot(f.n)) < EPS then
									-- do the two faces overlap in their plane?
									local rel = g.c - f.c
									local overlap = true
									for i, axis in AX do
										if i ~= f.i then
											local w = a.CFrame:VectorToWorldSpace(axis)
											local ha = (i == 1 and a.Size.X or i == 2 and a.Size.Y or a.Size.Z) / 2
											if math.abs(rel:Dot(w)) > ha + halfAlong(b, w) - 0.05 then overlap = false end
										end
									end
									if overlap then
										-- the smaller part grows along its own axis that lines up with the normal
										local small = (a.Size.X * a.Size.Y * a.Size.Z <= b.Size.X * b.Size.Y * b.Size.Z) and a or b
										local ln = small.CFrame:VectorToObjectSpace(f.n)
										local axisGrow = Vector3.new(math.abs(ln.X) > 0.9 and GROW or 0, math.abs(ln.Y) > 0.9 and GROW or 0, math.abs(ln.Z) > 0.9 and GROW or 0)
										local cur = grow[small] or Vector3.zero
										grow[small] = cur:Max(axisGrow)
									end
								end
							end
						end
					end
				end
			end
		end
		-- (small slices: a whole plot or the town in one go stalled frames for everyone)
		if n % 60 == 0 then task.wait() end
	end
	local count = 0
	for p, g in grow do
		if p.Parent and g.Magnitude > 0 then
			local cf = p.CFrame
			p.Size += g
			p.CFrame = cf
			count += 1
		end
	end
	return count
end

-- every surface smooth: the old studs and inlets (the default on parts made in the edit-time map and
-- by some builders) made floors, ceilings, sidewalks and the carpet look like a 2010 baseplate
local SURFACES = { "TopSurface", "BottomSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface" }
function Unfight.smooth(root)
	local n = 0
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") and not p:IsA("Terrain") then
			for _, f in SURFACES do
				if p[f] ~= Enum.SurfaceType.Smooth then
					p[f] = Enum.SurfaceType.Smooth
					n += 1
				end
			end
		end
	end
	return n
end

-- (a part that grew can land in a new neighbour's plane: go again until nothing moves, three times at most)
function Unfight.run(root)
	Unfight.smooth(root)
	StudStyle.run(root)
	local total = 0
	for _ = 1, 3 do
		local n = pass(root)
		total += n
		if n == 0 then break end
	end
	return total
end

-- re-run on a child of root (a plot) a moment after a burst of parts lands in it
function Unfight.watch(root)
	local pending = {}
	root.DescendantAdded:Connect(function(d)
		if not d:IsA("BasePart") then return end
		-- (kids sitting down, goons, anything with a Humanoid, at any depth: a kid's props sit in a
		-- "Props" model inside the rig, and each one seated used to rescan the whole school)
		if isRig(d) then return end
		if d:FindFirstAncestor("Students") then return end
		local top = d
		while top.Parent and top.Parent ~= root do top = top.Parent end
		if top.Parent ~= root or pending[top] then return end
		pending[top] = true
		task.delay(1.5, function()
			pending[top] = nil
			if top.Parent then pcall(Unfight.run, top) end
		end)
	end)
end

return Unfight
