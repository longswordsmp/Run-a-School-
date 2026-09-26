-- StarterPlayer.StarterPlayerScripts.Voices
-- The people of Recess Row mumble when they speak: whenever a speech bubble near you says something
-- new (a townsperson, Wobblesworth, Stan, a goon's taunt, a runner's quip), a short string of blips in
-- that character's voice plays (Audio.client's ClientBus.Talk), quieter the further away they are.
-- Never words: just the sound of talking.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local bus = ReplicatedStorage:WaitForChild("ClientBus", 30)
local talk = bus and bus:WaitForChild("Talk", 30)
if not talk then return end

local BUBBLES = { Speech = true, Taunt = true, GoonTag = true, RunnerTag = true }
local RANGE = 45

local function speakerOf(gui)
	local m = gui:FindFirstAncestorOfClass("Model")
	return m and m.Name or "someone"
end

local function mumble(gui, text)
	if not gui.Enabled then return end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local adornee = gui.Parent
	if not (root and adornee and adornee:IsA("BasePart")) then return end
	local d = (adornee.Position - root.Position).Magnitude
	if d > RANGE then return end
	local vol = math.clamp(1.1 - d / RANGE, 0.25, 1)
	local who = speakerOf(gui)
	local n = math.clamp(math.floor(#text / 3), 3, 14)
	task.spawn(function()
		for _ = 1, n do
			talk:Fire(who, vol)
			task.wait(0.075 + math.random() * 0.03)
		end
	end)
end

local watched = {}
local function watch(gui)
	if watched[gui] or not (gui:IsA("BillboardGui") and BUBBLES[gui.Name]) then return end
	watched[gui] = true
	local function hook(label)
		if not label:IsA("TextLabel") then return end
		local last = label.Text
		label:GetPropertyChangedSignal("Text"):Connect(function()
			local t = label.Text
			if t ~= "" and t ~= last then mumble(gui, t) end
			last = t
		end)
	end
	for _, d in gui:GetDescendants() do hook(d) end
	gui.DescendantAdded:Connect(hook)
	-- a bubble shown again with the same words still talks
	gui:GetPropertyChangedSignal("Enabled"):Connect(function()
		if gui.Enabled then
			local label = gui:FindFirstChildWhichIsA("TextLabel", true)
			if label and label.Text ~= "" then mumble(gui, label.Text) end
		end
	end)
	-- a new bubble that arrives already saying something
	task.defer(function()
		local label = gui:FindFirstChildWhichIsA("TextLabel", true)
		if gui.Enabled and label and label.Text ~= "" then mumble(gui, label.Text) end
	end)
	gui.AncestryChanged:Connect(function()
		if not gui:IsDescendantOf(game) then watched[gui] = nil end
	end)
end

for _, d in workspace:GetDescendants() do watch(d) end
workspace.DescendantAdded:Connect(watch)
