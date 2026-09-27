-- ServerScriptService.Server.StudStyle
-- The classic Roblox look on the world (tomas, 2026-09-27: "make everything stud style ... buildings,
-- walls, ground ... not models"; kept after a live trial): every big block of the town and the schools
-- (walls, floors, roofs, the ground, roads, paths) is plastic with studs on its top and sides, like the
-- stud texture on the UI. Engine surfaces: nothing added, nothing to load.
-- Left alone: anything under 4 studs long or a stud across, balls and cylinders, glass, neon and see-through
-- parts, signs (a SurfaceGui on them), and anything in a character (a Humanoid), a tree, a bush or a
-- vehicle.
-- Unfight.run smooths every surface first (the old stray studs and inlets) and then calls
-- StudStyle.run on the same root, so a rebuilt school gets its studs back.
--   StudStyle.qualifies(part)  should this part be studded?
--   StudStyle.run(root)        stud everything under root that qualifies; returns how many
--   StudStyle.watch(root)      and whatever is added under root later
--   StudStyle.disc(part)       redraw a flat round piece as studded strips (see below)
local StudStyle = {}

local SKIP_MODELS = { "Tree", "Bush", "Car", "Bus", "Limo", "Leaves", "Hoverboard" }
local SKIP_MATERIALS = {
	[Enum.Material.Neon] = true, [Enum.Material.Glass] = true, [Enum.Material.ForceField] = true,
}
local SIDES = { "TopSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface" }

local function inSkippedModel(p)
	local a = p.Parent
	while a and a ~= workspace do
		if a:IsA("Model") then
			if a:FindFirstChildOfClass("Humanoid") then return true end
			for _, k in SKIP_MODELS do
				if a.Name:find(k) then return true end
			end
		end
		a = a.Parent
	end
	return false
end

function StudStyle.qualifies(p)
	if not (p:IsA("WedgePart") or p:IsA("CornerWedgePart") or (p:IsA("Part") and p.Shape == Enum.PartType.Block)) then
		return false
	end
	if p.Transparency >= 0.3 or SKIP_MATERIALS[p.Material] or p.Name:find("Leaves") then return false end
	-- (a sign or a board with words on it stays smooth: the studs would show through its text)
	if p:FindFirstChildOfClass("SurfaceGui") then return false end
	-- (anything at least 4 studs long and a stud across: walls, floors, roofs, the ground, trim, steps,
	-- awnings, beams, posts; tomas, 2026-09-27: "there's still a lot of un-studded stuff")
	local s = p.Size
	local d = { s.X, s.Y, s.Z }
	table.sort(d)
	if d[3] < 4 or d[2] < 1 then return false end
	return not inSkippedModel(p)
end

local function stud(p)
	p.Material = Enum.Material.Plastic
	for _, f in SIDES do p[f] = Enum.SurfaceType.Studs end
end

-- round things lying flat on the ground (the Commons plaza, Maple's cul-de-sacs, the sand round the lake,
-- round mats): engine studs don't draw on a cylinder and nor does a texture (tried, 2026-09-27), so the
-- disc is redrawn as strips a stud wide on the stud grid, a stepped circle like the rest of the stud
-- world. The disc stays, invisible, to walk on and for anything that points at it.
local function discShaped(p)
	return p:IsA("Part") and p.Shape == Enum.PartType.Cylinder and p.Size.X <= 1.5
		and math.min(p.Size.Y, p.Size.Z) >= 8 and math.abs(p.CFrame.RightVector.Y) >= 0.95
end
-- (lying on a floor: a block right under its middle, or another disc that is: so a plaza on its rim on
-- the ground counts, and a burger's patty on its bun, a vat's cap, a spinning ride's deck don't)
local down = RaycastParams.new()
down.FilterType = Enum.RaycastFilterType.Exclude
local function onFloor(p, depth)
	if depth > 4 then return false end
	down.FilterDescendantsInstances = { p }
	-- (from its middle: a disc sunk a hair into the ground would start the ray inside the ground)
	local hit = workspace:Raycast(p.Position, Vector3.new(0, -(p.Size.X / 2 + 1.5), 0), down)
	if not hit then return false end
	local h = hit.Instance
	if h:IsA("Terrain") then return true end
	if h:IsA("Part") and h.Shape == Enum.PartType.Block then return true end
	return discShaped(h) and onFloor(h, depth + 1)
end
local function flatDisc(p)
	if not discShaped(p) or p:GetAttribute("Strips") then return false end
	if p.Transparency >= 0.3 or SKIP_MATERIALS[p.Material] or p.Name:find("Water") then return false end
	return not inSkippedModel(p) and onFloor(p, 0)
end
function StudStyle.disc(p)
	p:SetAttribute("Strips", true)
	local r = math.min(p.Size.Y, p.Size.Z) / 2
	local c, h = p.Position, p.Size.X
	-- (strips along x, one a stud of z; each as long as the circle is wide there, in whole studs)
	for z = -r + 0.5, r - 0.5 do
		local len = math.floor(2 * math.sqrt(math.max(0, r * r - z * z)) + 0.5)
		if len >= 1 then
			local s = Instance.new("Part")
			s.Name = p.Name .. "Strip"
			s.Anchored = true
			s.CanCollide, s.CanQuery, s.CanTouch = false, false, false
			s.Size = Vector3.new(len, h, 1)
			s.CFrame = CFrame.new(c.X, c.Y, c.Z + z)
			s.Color = p.Color
			stud(s)
			s.Parent = p.Parent
		end
	end
	p.Transparency = 1
end

function StudStyle.run(root)
	local n = 0
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") and StudStyle.qualifies(p) then
			stud(p)
			n += 1
		elseif p:IsA("BasePart") and flatDisc(p) then
			StudStyle.disc(p)
			n += 1
		end
	end
	return n
end

-- and everything built later (houses, barriers, event decor...): a moment after it appears
function StudStyle.watch(root)
	root.DescendantAdded:Connect(function(d)
		if not d:IsA("BasePart") then return end
		task.defer(function()
			if not d.Parent then return end
			if StudStyle.qualifies(d) then
				stud(d)
			elseif flatDisc(d) then
				StudStyle.disc(d)
			end
		end)
	end)
end

return StudStyle
