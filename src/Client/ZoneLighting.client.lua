-- StarterPlayer.StarterPlayerScripts.ZoneLighting
-- The mood of a place: while you stand in a zone the lighting eases to that zone's profile, and
-- back to what it was when you leave. (Enclosed places deep underground are otherwise lit by the
-- sky's ambient like the street.)
--   Sewer   the storm sewer under Recess Row: dark, damp and green
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local ZONES = {
	{
		name = "Sewer",
		inside = function(p) return p.Y < -30 and p.Y > -70 and p.X > 380 and p.X < 500 and p.Z > -170 and p.Z < 5 end,
		lighting = { Ambient = rgb(34, 42, 34), OutdoorAmbient = rgb(26, 34, 28), Brightness = 0.3, ExposureCompensation = -0.35, EnvironmentDiffuseScale = 0.15, EnvironmentSpecularScale = 0.1 },
		cc = { TintColor = rgb(214, 236, 204), Saturation = -0.15, Contrast = 0.12 },
	},
}

local saved -- the lighting before we entered a zone
local current
local function cc()
	return Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
end

local function apply(zone)
	local ti = TweenInfo.new(0.8, Enum.EasingStyle.Sine)
	if zone then
		if not saved then
			saved = { lighting = {}, cc = {} }
			for k in zone.lighting do saved.lighting[k] = Lighting[k] end
			local c = cc()
			if c then for k in zone.cc do saved.cc[k] = c[k] end end
		end
		TweenService:Create(Lighting, ti, zone.lighting):Play()
		local c = cc()
		if c then TweenService:Create(c, ti, zone.cc):Play() end
	elseif saved then
		TweenService:Create(Lighting, ti, saved.lighting):Play()
		local c = cc()
		if c and next(saved.cc) then TweenService:Create(c, ti, saved.cc):Play() end
		saved = nil
	end
end

while true do
	task.wait(0.25)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local zone
	if root then
		for _, z in ZONES do
			if z.inside(root.Position) then zone = z break end
		end
	end
	if zone ~= current then
		current = zone
		apply(zone)
	end
end
