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

-- "Rat": scurries between its A and B attributes, pausing to sniff at each end
local rats = {}
local function addRat(m)
	if m:IsA("Model") and m:GetAttribute("A") then
		rats[m] = { base = m:GetPivot(), t0 = math.random() * 10 }
	end
end
for _, m in CollectionService:GetTagged("Rat") do addRat(m) end
CollectionService:GetInstanceAddedSignal("Rat"):Connect(addRat)
CollectionService:GetInstanceRemovedSignal("Rat"):Connect(function(m) rats[m] = nil end)

-- "Flicker": a light that stutters now and then (the sewer lamps)
local flickers = {}
local function addFlicker(l)
	if l:IsA("Light") then flickers[l] = { b = l.Brightness, next = os.clock() + math.random() * 4 } end
end
for _, l in CollectionService:GetTagged("Flicker") do addFlicker(l) end
CollectionService:GetInstanceAddedSignal("Flicker"):Connect(addFlicker)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for m, r in rats do
		if not m.Parent then rats[m] = nil continue end
		local a, b = m:GetAttribute("A"), m:GetAttribute("B")
		local speed = m:GetAttribute("Speed") or 6
		local len = (b - a).Magnitude
		local legT = len / speed
		local cycle = (legT + 1.2) * 2
		local u = ((t + r.t0) % cycle)
		local pos, dir
		if u < legT then
			pos, dir = a:Lerp(b, u / legT), (b - a).Unit
		elseif u < legT + 1.2 then
			pos, dir = b, (b - a).Unit
		elseif u < legT * 2 + 1.2 then
			pos, dir = b:Lerp(a, (u - legT - 1.2) / legT), (a - b).Unit
		else
			pos, dir = a, (a - b).Unit
		end
		-- (the model's +X is its nose)
		local hop = math.abs(math.sin(t * 22)) * 0.12
		m:PivotTo(CFrame.lookAt(pos + Vector3.new(0, 0.3 + hop, 0), pos + Vector3.new(0, 0.3 + hop, 0) + dir) * CFrame.Angles(0, math.rad(90), 0))
	end
	for l, f in flickers do
		if not l.Parent then flickers[l] = nil continue end
		if t > f.next then
			l.Brightness = (l.Brightness > 0.2) and 0.05 or f.b
			f.next = t + (l.Brightness < 0.2 and 0.06 + math.random() * 0.1 or 0.8 + math.random() * 5)
		end
	end
	for m, base in spinners do
		if m.Parent then
			local speed = m:GetAttribute("SpinSpeed") or 0.5
			m:PivotTo(base * CFrame.new(0, math.sin(t * 1.3) * 1.2, 0) * CFrame.Angles(0, t * speed, 0))
		else
			spinners[m] = nil
		end
	end
end)
