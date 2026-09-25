-- StarterPlayer.StarterPlayerScripts.Ambient
-- Little bits of life on the NPCs near you, played on this client only (the server just walks and
-- seats them): seated kids wave, put their hands up, look around, laugh, nod while they write, and
-- the sleepy ones doze off; kids on the carpet wave at you or cheer; a kid whose desk you just
-- collected from cheers; kids in detention hang their heads.
-- Emotes are the default R15 ones (ids loaded and timed in Studio, see NIGHT-LOG.md).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local EMOTES = {
	wave = "rbxassetid://507770239",
	point = "rbxassetid://507770453",
	cheer = "rbxassetid://507770677",
	laugh = "rbxassetid://507770818",
	dance = "rbxassetid://507771019",
}
local SLEEPY = { SleepySam = true, PajamaPete = true }
local RANGE = 70

local nextAct = setmetatable({}, { __mode = "k" }) -- [model] = os.clock() when it may act again
local tracks = setmetatable({}, { __mode = "k" }) -- [model] = { [name] = track }

local function emote(model, name)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator then return end
	tracks[model] = tracks[model] or {}
	local tr = tracks[model][name]
	if not tr then
		local a = Instance.new("Animation")
		a.AnimationId = EMOTES[name]
		local ok, t = pcall(function() return animator:LoadAnimation(a) end)
		if not ok then return end
		tr = t
		tr.Priority = Enum.AnimationPriority.Action2
		tr.Looped = false
		tracks[model][name] = tr
	end
	tr:Play(0.2)
end

-- turn a joint for a moment (AnimationConstraint rigs: rotate the parent-side attachment)
local function pose(model, partName, jointName, angles, hold)
	local p = model:FindFirstChild(partName)
	local joint = p and p:FindFirstChild(jointName)
	if not joint then return end
	local target, prop
	if joint:IsA("Motor6D") then
		target, prop = joint, "C0"
	elseif joint.ClassName == "AnimationConstraint" and joint.Attachment0 then
		target, prop = joint.Attachment0, "CFrame"
	end
	if not target or target:GetAttribute("Posing") then return end
	target:SetAttribute("Posing", true)
	local base = target[prop]
	TweenService:Create(target, TweenInfo.new(0.3, Enum.EasingStyle.Sine), { [prop] = base * angles }):Play()
	task.delay(hold, function()
		if target.Parent then
			local tw = TweenService:Create(target, TweenInfo.new(0.35, Enum.EasingStyle.Sine), { [prop] = base })
			tw:Play()
			tw.Completed:Wait()
			target:SetAttribute("Posing", nil)
		end
	end)
end

local function seatedAct(model)
	local id = model:GetAttribute("StudentId")
	local r = math.random()
	if SLEEPY[id] and r < 0.5 then
		pose(model, "Head", "Neck", CFrame.Angles(math.rad(-28), 0, math.rad(8)), 5)
	elseif r < 0.2 then
		emote(model, "wave")
	elseif r < 0.4 then
		-- hand up: "I know the answer!"
		pose(model, "RightUpperArm", "RightShoulder", CFrame.Angles(math.rad(165), 0, 0), 2.2)
	elseif r < 0.6 then
		pose(model, "Head", "Neck", CFrame.Angles(0, math.rad(math.random() < 0.5 and -45 or 45), 0), 1.4)
	elseif r < 0.75 then
		emote(model, "laugh")
	else
		-- writing: a couple of little nods toward the desk
		pose(model, "Head", "Neck", CFrame.Angles(math.rad(-18), 0, 0), 1.2)
	end
end

local function hallAct(model, dist)
	local r = math.random()
	if dist < 22 and r < 0.35 then
		emote(model, "wave")
	elseif r < 0.5 then
		emote(model, "cheer")
	end
end

-- a kid whose desk you collect from cheers
Remotes:WaitForChild("CashPop").OnClientEvent:Connect(function(_, pos)
	if typeof(pos) ~= "Vector3" then return end
	local plotName = player:GetAttribute("Plot")
	local plots = workspace:FindFirstChild("Plots")
	local plot = plotName and plots and plots:FindFirstChild(plotName)
	local students = plot and plot:FindFirstChild("Students")
	if not students then return end
	local best, bestD
	for _, m in students:GetChildren() do
		local root = m.PrimaryPart
		if root and m:GetAttribute("Slot") then
			local d = (root.Position - pos).Magnitude
			if d < 8 and (not best or d < bestD) then best, bestD = m, d end
		end
	end
	if best then emote(best, "cheer") end
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		local camPos = camera.CFrame.Position
		local now = os.clock()
		local plots = workspace:FindFirstChild("Plots")
		for _, plot in plots and plots:GetChildren() or {} do
			local students = plot:FindFirstChild("Students")
			for _, m in students and students:GetChildren() or {} do
				local root = m.PrimaryPart
				if root and (root.Position - camPos).Magnitude < RANGE then
					local t = nextAct[m]
					if not t then
						nextAct[m] = now + 2 + math.random() * 10
					elseif now >= t then
						nextAct[m] = now + 7 + math.random() * 14
						local head = m:FindFirstChild("Head")
						if head and head:FindFirstChild("Detention") then
							pose(m, "Head", "Neck", CFrame.Angles(math.rad(-30), 0, 0), 4)
						elseif m:GetAttribute("Slot") and not (head and head:FindFirstChild("Cheating")) then
							seatedAct(m)
						end
					end
				end
			end
		end
		local hall = workspace:FindFirstChild("Hall")
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		for _, m in hall and hall:GetChildren() or {} do
			local r = m.PrimaryPart
			if r and root and m:GetAttribute("State") == "Hall" then
				local d = (r.Position - root.Position).Magnitude
				if d < 45 then
					local t = nextAct[m]
					if not t then
						nextAct[m] = now + math.random() * 6
					elseif now >= t then
						nextAct[m] = now + 8 + math.random() * 10
						hallAct(m, d)
					end
				end
			end
		end
	end
end)
