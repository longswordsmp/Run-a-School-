-- StarterPlayerScripts.Water
-- Water in town is a flat part with a water texture (TownPark's lake). This drifts every texture
-- tagged "WaterTex" slowly on two axes so the surface looks like it is moving.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local live = {}
local function add(t)
	if t:IsA("Texture") then live[t] = true end
end
for _, t in CollectionService:GetTagged("WaterTex") do add(t) end
CollectionService:GetInstanceAddedSignal("WaterTex"):Connect(add)
CollectionService:GetInstanceRemovedSignal("WaterTex"):Connect(function(t) live[t] = nil end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for tex in live do
		if tex.Parent then
			tex.OffsetStudsU = (t * 1.2) % tex.StudsPerTileU
			tex.OffsetStudsV = (math.sin(t * 0.35) * 2 + t * 0.5) % tex.StudsPerTileV
		end
	end
end)
