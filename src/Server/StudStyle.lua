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

function StudStyle.run(root)
	local n = 0
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") and StudStyle.qualifies(p) then
			stud(p)
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
			if d.Parent and StudStyle.qualifies(d) then stud(d) end
		end)
	end)
end

return StudStyle
