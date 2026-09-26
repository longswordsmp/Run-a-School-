-- ServerScriptService.Server.TownService
-- Builds the town around the schools at server start (docs/TOWN.md): the ground past the old map,
-- the ring road around the school area with its connections to Recess Row, the fences that separate
-- the districts (one arch gate each), the edge of the world, and then each district (Town*.lua).
-- Everything lands in workspace.Town. Built at runtime like the schools, so the repo is the source
-- of truth and nothing needs saving in Studio.
local Kit = require(script.Parent.TownKit)

local TownService = {}

local rgb = Kit.rgb
local RING = 522 -- the ring road's centre line (x = ±RING along the sides, z = ±222 along the top and bottom)
local RING_Z = 222
local ROAD_W = 24
local FENCE_X, FENCE_Z = 540, 240 -- the district fences
local EDGE_X, EDGE_Z = 800, 560 -- the edge of the world

-- the old map's trees and lamps that would stand on a new road
local function clearRoads(roads)
	local deco = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Deco")
	if not deco then return end
	for _, m in deco:GetChildren() do
		local ok, cf = pcall(function() return (m:GetBoundingBox()) end)
		if ok and cf then
			local p = cf.Position
			for _, r in roads do
				if p.X > r[1] - 8 and p.X < r[2] + 8 and p.Z > r[3] - 8 and p.Z < r[4] + 8 then
					m:Destroy()
					break
				end
			end
		end
	end
end

local function buildFrame(town)
	local frame = Kit.folder(town, "Frame")
	-- the ground past the old map (which covers x -490..490, z -260..260)
	Kit.ground(frame, -EDGE_X, EDGE_X, 260, EDGE_Z)
	Kit.ground(frame, -EDGE_X, EDGE_X, -EDGE_Z, -260)
	Kit.ground(frame, -EDGE_X, -490, -260, 260)
	Kit.ground(frame, 490, EDGE_X, -260, 260)

	-- the ring road and its sidewalks (inside edge only: the fences run just outside)
	local roads = Kit.folder(frame, "Roads")
	Kit.road(roads, -RING - ROAD_W / 2, RING_Z, RING + ROAD_W / 2, RING_Z, ROAD_W)
	Kit.road(roads, -RING - ROAD_W / 2, -RING_Z, RING + ROAD_W / 2, -RING_Z, ROAD_W)
	Kit.road(roads, RING, -RING_Z + ROAD_W / 2, RING, RING_Z - ROAD_W / 2, ROAD_W)
	Kit.road(roads, -RING, -RING_Z + ROAD_W / 2, -RING, RING_Z - ROAD_W / 2, ROAD_W)
	-- the corners
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Kit.pave(roads, sx * RING - ROAD_W / 2, sx * RING + ROAD_W / 2, sz * RING_Z - ROAD_W / 2, sz * RING_Z + ROAD_W / 2, Kit.C.asphalt, Enum.Material.Asphalt, 0.12)
		end
	end
	-- Recess Row to the ring road, at both ends of the street
	Kit.road(roads, -RING + ROAD_W / 2, 0, -400, 0, ROAD_W)
	Kit.road(roads, 400, 0, RING - ROAD_W / 2, 0, ROAD_W)
	Kit.crosswalk(roads, -410, 0, ROAD_W, false)
	Kit.crosswalk(roads, 410, 0, ROAD_W, false)
	-- through each gate into its district
	Kit.road(roads, 0, RING_Z + ROAD_W / 2, 0, FENCE_Z + 30, ROAD_W)
	Kit.road(roads, 0, -RING_Z - ROAD_W / 2, 0, -FENCE_Z - 30, ROAD_W)
	Kit.road(roads, -RING - ROAD_W / 2, 0, -FENCE_X - 30, 0, ROAD_W)
	Kit.road(roads, RING + ROAD_W / 2, 0, FENCE_X + 30, 0, ROAD_W)
	clearRoads({
		{ -RING - 14, RING + 14, RING_Z - 14, RING_Z + 14 }, { -RING - 14, RING + 14, -RING_Z - 14, -RING_Z + 14 },
		{ RING - 14, RING + 14, -RING_Z, RING_Z }, { -RING - 14, -RING + 14, -RING_Z, RING_Z },
		{ -RING, -400, -14, 14 }, { 400, RING, -14, 14 },
	})
	-- street lamps along the ring road
	for x = -480, 480, 80 do
		Kit.lamp(roads, x, RING_Z - ROAD_W / 2 - 2)
		Kit.lamp(roads, x, -RING_Z + ROAD_W / 2 + 2)
	end
	for z = -160, 160, 80 do
		Kit.lamp(roads, RING - ROAD_W / 2 - 2, z)
		Kit.lamp(roads, -RING + ROAD_W / 2 + 2, z)
	end

	-- the district fences: two long lines along x = ±FENCE_X and two along z = ±FENCE_Z, each with
	-- a gap for its gate
	local fences = Kit.folder(frame, "Fences")
	local gap = ROAD_W / 2 + 2
	for _, sx in { -1, 1 } do
		Kit.ironFence(fences, sx * FENCE_X, -EDGE_Z, sx * FENCE_X, -gap)
		Kit.ironFence(fences, sx * FENCE_X, gap, sx * FENCE_X, EDGE_Z)
	end
	for _, sz in { -1, 1 } do
		Kit.ironFence(fences, -FENCE_X, sz * FENCE_Z, -gap, sz * FENCE_Z)
		Kit.ironFence(fences, gap, sz * FENCE_Z, FENCE_X, sz * FENCE_Z)
	end
	-- the gates
	Kit.gateArch(frame, 0, FENCE_Z, ROAD_W, "\u{1F3E1} MAPLE HEIGHTS", rgb(80, 160, 90), true)
	Kit.gateArch(frame, 0, -FENCE_Z, ROAD_W, "\u{1F3EA} DOWNTOWN", rgb(220, 90, 60), true)
	Kit.gateArch(frame, -FENCE_X, 0, ROAD_W, "\u{1F332} PINE PARK", rgb(46, 130, 76), false)
	Kit.gateArch(frame, FENCE_X, 0, ROAD_W, "\u{1F3ED} VEXCORP INDUSTRIAL", rgb(110, 50, 160), false)

	-- the edge of the world: an invisible wall behind a double row of pines
	local edge = Kit.folder(frame, "Edge")
	Kit.wall(edge, -EDGE_X, EDGE_Z, EDGE_X, EDGE_Z)
	Kit.wall(edge, -EDGE_X, -EDGE_Z, EDGE_X, -EDGE_Z)
	Kit.wall(edge, EDGE_X, -EDGE_Z, EDGE_X, EDGE_Z)
	Kit.wall(edge, -EDGE_X, -EDGE_Z, -EDGE_X, EDGE_Z)
	local rng = Random.new(11)
	for x = -EDGE_X + 10, EDGE_X - 10, 22 do
		Kit.pine(edge, x + rng:NextNumber(-4, 4), EDGE_Z - 10, rng:NextNumber(1.1, 1.6))
		Kit.pine(edge, x + rng:NextNumber(-4, 4), -EDGE_Z + 10, rng:NextNumber(1.1, 1.6))
	end
	for z = -EDGE_Z + 32, EDGE_Z - 32, 22 do
		Kit.pine(edge, EDGE_X - 10, z + rng:NextNumber(-4, 4), rng:NextNumber(1.1, 1.6))
		Kit.pine(edge, -EDGE_X + 10, z + rng:NextNumber(-4, 4), rng:NextNumber(1.1, 1.6))
	end
end

function TownService.start()
	local old = workspace:FindFirstChild("Town")
	if old then old:Destroy() end
	local town = Instance.new("Folder")
	town.Name = "Town"
	buildFrame(town)
	-- the districts (each file builds into its own model)
	for _, name in { "TownDowntown", "TownMaple", "TownPark", "TownIndustrial" } do
		local mod = script.Parent:FindFirstChild(name)
		if mod then
			local ok, err = pcall(function() require(mod).build(town, Kit) end)
			if not ok then warn("[Town]", name, err) end
		end
	end
	town.Parent = workspace
	TownService.root = town
	TownService.wireElevator(town)
end

-- the EXECUTIVE ELEVATOR: the Tower lobby <-> the Lair (only once the Lair is open for you)
function TownService.wireElevator(town)
	local Industrial = require(script.Parent.TownIndustrial)
	local AreaService = require(script.Parent.AreaService)
	local Remotes = require(script.Parent.Remotes)
	for _, d in town:GetDescendants() do
		local dir = d:IsA("BasePart") and d:GetAttribute("Elevator")
		if dir then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "ElevatorPrompt"
			prompt.ActionText = dir == "down" and "Go down" or "Go up"
			prompt.ObjectText = dir == "down" and "Executive Elevator" or "Elevator to the lobby"
			prompt.HoldDuration = 0.6
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt:SetAttribute("Color", Color3.fromRGB(200, 120, 255))
			prompt.Parent = d
			prompt.Triggered:Connect(function(player)
				local char = player.Character
				if not char then return end
				if dir == "down" and not AreaService.isOpen(player, "Lair") then
					Remotes.Notify:FireClient(player, "\u{1F512} ACCESS DENIED. Only Dr. Vex goes down there... for now.", "bad")
					Remotes.Sfx:FireClient(player, "Error")
					return
				end
				Remotes.Push:FireClient(player, "elevator", { dir = dir })
				task.wait(0.8)
				if not player.Parent or not char.Parent then return end
				char:PivotTo(CFrame.new(dir == "down" and Industrial.ELEVATOR_BOTTOM or Industrial.ELEVATOR_TOP) * CFrame.Angles(0, dir == "down" and math.rad(-90) or math.rad(90), 0))
			end)
		end
	end
end

return TownService
