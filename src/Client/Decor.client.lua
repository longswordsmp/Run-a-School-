-- StarterPlayer.StarterPlayerScripts.Decor
-- Little client-side motions for decor the server tags:
--   "Spin"  a model turns slowly about its pivot (SpinSpeed attribute, radians a second) and bobs
--           (the Alien school's flying saucer)
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local spinners = {} -- model -> base pivot

local function add(m)
	if m:IsA("Model") then spinners[m] = m:GetPivot() end
end
for _, m in CollectionService:GetTagged("Spin") do add(m) end
CollectionService:GetInstanceAddedSignal("Spin"):Connect(add)
CollectionService:GetInstanceRemovedSignal("Spin"):Connect(function(m) spinners[m] = nil end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for m, base in spinners do
		if m.Parent then
			local speed = m:GetAttribute("SpinSpeed") or 0.5
			m:PivotTo(base * CFrame.new(0, math.sin(t * 1.3) * 1.2, 0) * CFrame.Angles(0, t * speed, 0))
		else
			spinners[m] = nil
		end
	end
end)
