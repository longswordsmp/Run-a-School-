-- StarterPlayer.StarterPlayerScripts.EventFX
-- What each server event looks like on this client (workspace attribute "Event"):
--   SnowDay: snow falling around you, a cold tint.       Halloween: dusk, orange tint, fog.
--   ScienceFair: green sparkles drifting up.             PictureDay: camera flashes.
--   SpaceCamp: night sky full of stars, a violet tint.
-- Everything is local to this client and put back when the event ends.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local saved = {
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	FogColor = Lighting.FogColor,
	Brightness = Lighting.Brightness,
}
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "EventTint"
cc.Parent = Lighting

-- a box of particles that follows the camera
local emitterPart = Instance.new("Part")
emitterPart.Name = "EventWeather"
emitterPart.Anchored, emitterPart.CanCollide, emitterPart.CanQuery, emitterPart.CanTouch = true, false, false, false
emitterPart.Transparency = 1
emitterPart.Size = Vector3.new(90, 1, 90)
emitterPart.Parent = workspace
local emitter = Instance.new("ParticleEmitter")
emitter.Enabled = false
emitter.Parent = emitterPart

local flashGui = Instance.new("ScreenGui")
flashGui.Name = "EventFlash"
flashGui.IgnoreGuiInset = true
flashGui.DisplayOrder = 40
flashGui.ResetOnSpawn = false
flashGui.Parent = player:WaitForChild("PlayerGui")
local flash = Instance.new("Frame")
flash.BackgroundColor3 = Color3.new(1, 1, 1)
flash.BackgroundTransparency = 1
flash.Size = UDim2.fromScale(1, 1)
flash.Parent = flashGui

local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local current

local function tween(obj, props, t)
	TweenService:Create(obj, TweenInfo.new(t or 2), props):Play()
end

local function reset()
	emitter.Enabled = false
	tween(cc, { TintColor = Color3.new(1, 1, 1), Saturation = 0, Brightness = 0 })
	tween(Lighting, { ClockTime = saved.ClockTime, FogEnd = saved.FogEnd, FogColor = saved.FogColor, Brightness = saved.Brightness })
end

local function apply(ev)
	reset()
	current = ev
	if ev == "SnowDay" then
		emitter.Texture = SPARKLE
		emitter.Color = ColorSequence.new(Color3.new(1, 1, 1))
		emitter.LightEmission = 0.2
		emitter.Size = NumberSequence.new(0.35)
		emitter.Rate = 120
		emitter.Lifetime = NumberRange.new(6, 8)
		emitter.Speed = NumberRange.new(5, 8)
		emitter.SpreadAngle = Vector2.new(15, 15)
		emitter.EmissionDirection = Enum.NormalId.Bottom
		emitter.Acceleration = Vector3.new(1, 0, 0.5)
		emitter.Enabled = true
		tween(cc, { TintColor = Color3.fromRGB(225, 238, 255), Saturation = -0.1 })
	elseif ev == "Halloween" then
		tween(Lighting, { ClockTime = 18.3, FogEnd = 500, FogColor = Color3.fromRGB(60, 30, 50) })
		tween(cc, { TintColor = Color3.fromRGB(255, 205, 170), Saturation = 0.1 })
	elseif ev == "ScienceFair" then
		emitter.Texture = SPARKLE
		emitter.Color = ColorSequence.new(Color3.fromRGB(120, 255, 120))
		emitter.LightEmission = 1
		emitter.Size = NumberSequence.new(0.5, 0)
		emitter.Rate = 30
		emitter.Lifetime = NumberRange.new(3, 5)
		emitter.Speed = NumberRange.new(1, 3)
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Acceleration = Vector3.zero
		emitter.Enabled = true
		tween(cc, { TintColor = Color3.fromRGB(230, 255, 230) })
	elseif ev == "SpaceCamp" then
		tween(Lighting, { ClockTime = 0.5, Brightness = 1.5 })
		tween(cc, { TintColor = Color3.fromRGB(225, 215, 255), Saturation = 0.15 })
	elseif ev == "PictureDay" then
		tween(cc, { Saturation = 0.2, Brightness = 0.03 })
	end
end

local function onEvent()
	local ev = workspace:GetAttribute("Event")
	if ev == current then return end
	if ev then apply(ev) else current = nil reset() end
end
workspace:GetAttributeChangedSignal("Event"):Connect(onEvent)
onEvent()

-- keep the weather over the camera; flash now and then on Picture Day
local nextFlash = 0
RunService.RenderStepped:Connect(function()
	local p = camera.CFrame.Position
	emitterPart.CFrame = CFrame.new(p.X, p.Y + (current == "SnowDay" and 35 or -6), p.Z)
	if current == "PictureDay" and os.clock() > nextFlash then
		nextFlash = os.clock() + 3 + math.random() * 4
		flash.BackgroundTransparency = 0.25
		tween(flash, { BackgroundTransparency = 1 }, 0.35)
	end
end)
