-- ServerScriptService.Server.MapPlan
-- What the town map (TownMap.client) draws: the town as seen from straight above, as flat shapes. Rays
-- are cast down every few studs over the whole map; every part they land on (roofs, roads, lawns, tree
-- tops...) becomes one footprint: where it is, its size and turn seen from above, its colour, and
-- whether it's round. The footprints go into ReplicatedStorage.MapPlan as JSON text (not streamed:
-- every player's map shows the whole town however far away they are).
--   MapPlan.Town      everything but the schools, once, after the town is built
--   MapPlan.Schools   the school plots, again a moment after any school is rebuilt
-- (It used to copy the parts themselves, about 2,700 of them, and the client drew them in a 3D
-- ViewportFrame: that took the frame rate down to about 1 while the map was open. Flat shapes in a
-- 2D frame cost next to nothing.)
--   a footprint:  { x, z, width, depth, turn (degrees), colour (0xRRGGBB), round (0/1), top y }
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local MapPlan = {}

local MIN_X, MAX_X, MIN_Z, MAX_Z = -820, 820, -580, 580
local STEP = 5
local CHUNK = 60000 -- characters per StringValue

local folder
local function holder()
	if folder and folder.Parent then return folder end
	folder = ReplicatedStorage:FindFirstChild("MapPlan") or Instance.new("Folder")
	folder.Name = "MapPlan"
	folder.Parent = ReplicatedStorage
	return folder
end

local function r1(n) return math.floor(n * 10 + 0.5) / 10 end

-- a part seen from straight above
local function footprint(p)
	local cf, size = p.CFrame, p.Size
	local axes = { cf.RightVector, cf.UpVector, cf.LookVector }
	local sizes = { size.X, size.Y, size.Z }
	local top = p.Position.Y + 0.5 * (math.abs(axes[1].Y) * sizes[1] + math.abs(axes[2].Y) * sizes[2] + math.abs(axes[3].Y) * sizes[3])
	local c = p.Color
	local color = math.floor(c.R * 255 + 0.5) * 65536 + math.floor(c.G * 255 + 0.5) * 256 + math.floor(c.B * 255 + 0.5)
	local pos = p.Position
	local shape = p:IsA("Part") and p.Shape or nil
	local round = false
	local w, d, turn
	if shape == Enum.PartType.Ball then
		round, w, d, turn = true, size.X, size.X, 0
	elseif shape == Enum.PartType.Cylinder and math.abs(axes[1].Y) > 0.7 then
		-- (stood on end: a disc)
		round, w, d, turn = true, size.Y, size.Y, 0
	elseif p:IsA("MeshPart") or p:IsA("UnionOperation") then
		-- (tree tops, bushes, rocks: round blobs as wide as they are)
		local hx = math.abs(axes[1].X) * sizes[1] + math.abs(axes[2].X) * sizes[2] + math.abs(axes[3].X) * sizes[3]
		local hz = math.abs(axes[1].Z) * sizes[1] + math.abs(axes[2].Z) * sizes[2] + math.abs(axes[3].Z) * sizes[3]
		round, w, d, turn = true, math.max(hx, hz) * 0.9, math.max(hx, hz) * 0.9, 0
	else
		-- a box: its two most level axes make the rectangle, turned the way the first one points
		local upI, best = 1, -1
		for i = 1, 3 do
			local v = math.abs(axes[i].Y)
			if v > best then best, upI = v, i end
		end
		local a, b
		for i = 1, 3 do
			if i ~= upI then
				if not a then a = i else b = i end
			end
		end
		local ha = math.sqrt(math.max(0, 1 - axes[a].Y ^ 2))
		local hb = math.sqrt(math.max(0, 1 - axes[b].Y ^ 2))
		w, d = sizes[a] * ha, sizes[b] * hb
		turn = math.deg(math.atan2(axes[a].Z, axes[a].X))
	end
	return { r1(pos.X), r1(pos.Z), r1(w), r1(d), math.floor(turn + 0.5), color, round and 1 or 0, r1(top) }
end

local function roots(schools)
	local list = {}
	if schools then
		local p = workspace:FindFirstChild("Plots")
		if p then table.insert(list, p) end
	else
		for _, n in { "Map", "VexFactory", "VexPrep", "VexLab", "GearStall", "VexFiles" } do
			local r = workspace:FindFirstChild(n)
			if r then table.insert(list, r) end
		end
		local town = workspace:FindFirstChild("Town")
		-- (not the interiors, the mothership up in the sky or the sewer under the street)
		for _, c in town and town:GetChildren() or {} do
			if c.Name ~= "Interiors" and c.Name ~= "Mothership" and c.Name ~= "Sewer" then table.insert(list, c) end
		end
	end
	return list
end

local function scan(out, taken, schools, x0, x1, z0, z1)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = roots(schools)
	local n = 0
	for x = x0, x1, STEP do
		for z = z0, z1, STEP do
			local hit = workspace:Raycast(Vector3.new(x, 180, z), Vector3.new(0, -200, 0), params)
			local p = hit and hit.Instance
			if p and not taken[p] and p:IsA("BasePart") and p.Transparency < 0.9 then
				-- (not people: kids on the swings, NPCs on the pavement)
				local m = p:FindFirstAncestorOfClass("Model")
				if not (m and m:FindFirstChildOfClass("Humanoid")) then
					taken[p] = true
					table.insert(out, footprint(p))
				end
			end
			n += 1
			if n % 4000 == 0 then task.wait() end
		end
	end
end

-- the footprints as JSON in numbered StringValues under MapPlan[name] (lowest first: the client draws
-- them in this order, so roofs land on top of lawns)
local function publish(name, list)
	table.sort(list, function(a, b) return a[8] < b[8] end)
	local json = HttpService:JSONEncode(list)
	local f = Instance.new("Folder")
	f.Name = name
	local i = 0
	for s = 1, #json, CHUNK do
		i += 1
		local v = Instance.new("StringValue")
		v.Name = tostring(i)
		v.Value = json:sub(s, s + CHUNK - 1)
		v.Parent = f
	end
	f:SetAttribute("Chunks", i)
	f:SetAttribute("Count", #list)
	local old = holder():FindFirstChild(name)
	f.Parent = holder()
	if old then old:Destroy() end
end

function MapPlan.town()
	local list, taken = {}, {}
	scan(list, taken, false, MIN_X, MAX_X, MIN_Z, MAX_Z)
	publish("Town", list)
end

function MapPlan.schools()
	local list, taken = {}, {}
	local plots = workspace:FindFirstChild("Plots")
	for _, plot in plots and plots:GetChildren() or {} do
		local b = plot:FindFirstChild("Bounds")
		if b then
			local c, s = b.Position, b.Size
			scan(list, taken, true, c.X - s.X / 2, c.X + s.X / 2, c.Z - s.Z / 2, c.Z + s.Z / 2)
		end
	end
	publish("Schools", list)
	holder():SetAttribute("SchoolsVersion", (holder():GetAttribute("SchoolsVersion") or 0) + 1)
end

function MapPlan.start()
	holder()
	-- (after the town, the street and the schools are built, and the z-fight pass has run)
	task.delay(14, function()
		pcall(MapPlan.town)
		pcall(MapPlan.schools)
	end)
	-- a school rebuilt (a new owner, a Board review, a new wing): its roof changes
	local pending = false
	local PlotService = require(script.Parent.PlotService)
	table.insert(PlotService.rebuildHooks, function()
		if pending then return end
		pending = true
		task.delay(4, function()
			pending = false
			pcall(MapPlan.schools)
		end)
	end)
end

return MapPlan
