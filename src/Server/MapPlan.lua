-- ServerScriptService.Server.MapPlan
-- What the town map (TownMap.client) draws: the town as seen from straight above. Rays are cast down
-- every few studs over the whole map; every part they land on (roofs, roads, lawns, tree tops...) is
-- copied into ReplicatedStorage.MapPlan, which isn't streamed, so every player's map shows the whole
-- town however far away they are. About 2,700 parts, found in a third of a second.
--   MapPlan.Town      everything but the schools, once, after the town is built
--   MapPlan.Schools   the school plots, again a moment after any school is rebuilt
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapPlan = {}

local MIN_X, MAX_X, MIN_Z, MAX_Z = -820, 820, -580, 580
local STEP = 5
local KEEP = { Decal = true, Texture = true, SurfaceAppearance = true }

local folder
local function holder()
	if folder and folder.Parent then return folder end
	folder = ReplicatedStorage:FindFirstChild("MapPlan") or Instance.new("Folder")
	folder.Name = "MapPlan"
	folder.Parent = ReplicatedStorage
	return folder
end

local function copy(part, into)
	local ok, c = pcall(function()
		local was = part.Archivable
		part.Archivable = true
		local cl = part:Clone()
		part.Archivable = was
		return cl
	end)
	if not ok or not c then return end
	for _, d in c:GetDescendants() do
		if not (KEEP[d.ClassName] or d:IsA("DataModelMesh")) then d:Destroy() end
	end
	c.Anchored = true
	c.CanCollide, c.CanQuery, c.CanTouch, c.CastShadow = false, false, false, false
	c.Parent = into
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

local function scan(into, schools, x0, x1, z0, z1)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = roots(schools)
	local taken = {}
	local n = 0
	for x = x0, x1, STEP do
		for z = z0, z1, STEP do
			local hit = workspace:Raycast(Vector3.new(x, 180, z), Vector3.new(0, -200, 0), params)
			local p = hit and hit.Instance
			if p and not taken[p] and p:IsA("BasePart") and p.Transparency < 0.9 then
				taken[p] = true
				copy(p, into)
			end
			n += 1
			if n % 4000 == 0 then task.wait() end
		end
	end
end

function MapPlan.town()
	local f = Instance.new("Model")
	f.Name = "Town"
	scan(f, false, MIN_X, MAX_X, MIN_Z, MAX_Z)
	local old = holder():FindFirstChild("Town")
	f.Parent = holder()
	if old then old:Destroy() end
end

function MapPlan.schools()
	local f = Instance.new("Model")
	f.Name = "Schools"
	local plots = workspace:FindFirstChild("Plots")
	for _, plot in plots and plots:GetChildren() or {} do
		local b = plot:FindFirstChild("Bounds")
		if b then
			local c, s = b.Position, b.Size
			scan(f, true, c.X - s.X / 2, c.X + s.X / 2, c.Z - s.Z / 2, c.Z + s.Z / 2)
		end
	end
	local old = holder():FindFirstChild("Schools")
	f.Parent = holder()
	if old then old:Destroy() end
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
