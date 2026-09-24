-- StarterPlayer.StarterPlayerScripts.Effects
-- Client-only motion for student props: parts tagged "Spin" (SpinPivot parts from StudentProps)
-- turn around their own Y axis by rewriting their weld's C0 locally.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local pivots = {}

local function add(p)
	local w = p:FindFirstChildOfClass("Weld")
	if not w then return end
	pivots[p] = { weld = w, base = w.C0, speed = math.rad(p:GetAttribute("SpinSpeed") or 90) }
end

for _, p in CollectionService:GetTagged("Spin") do add(p) end
CollectionService:GetInstanceAddedSignal("Spin"):Connect(add)
CollectionService:GetInstanceRemovedSignal("Spin"):Connect(function(p)
	pivots[p] = nil
end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for p, s in pivots do
		if p.Parent then
			s.weld.C0 = s.base * CFrame.Angles(0, (t * s.speed) % (math.pi * 2), 0)
		else
			pivots[p] = nil
		end
	end
end)
