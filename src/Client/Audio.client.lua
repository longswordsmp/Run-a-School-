-- StarterPlayer.StarterPlayerScripts.Audio
-- Music and sound effects.
--   Music: "Relaxed Scene", looped, the whole time.
--   Effects: the server fires Remotes.Sfx(name, worldPos?); other client scripts fire the local
--   ReplicatedStorage.ClientBus.Sfx bindable with the same arguments. Only names in Sounds.Sfx play,
--   each at most once per its gap, and at most a few effects a second overall.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sounds = require(Shared:WaitForChild("Sounds"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

-- a local bus other client scripts use (instances made on the client stay on this client)
local bus = ReplicatedStorage:FindFirstChild("ClientBus")
if not bus then
	bus = Instance.new("Folder")
	bus.Name = "ClientBus"
	bus.Parent = ReplicatedStorage
end
local sfxBus = bus:FindFirstChild("Sfx")
if not sfxBus then
	sfxBus = Instance.new("BindableEvent")
	sfxBus.Name = "Sfx"
	sfxBus.Parent = bus
end

local musicGroup = Instance.new("SoundGroup")
musicGroup.Name = "Music"
musicGroup.Volume = 1
musicGroup.Parent = SoundService
local sfxGroup = Instance.new("SoundGroup")
sfxGroup.Name = "Effects"
sfxGroup.Volume = 1
sfxGroup.Parent = SoundService

---------------------------------------------------------------------------
-- effects
---------------------------------------------------------------------------
local HEAR_RANGE = 45 -- a sound placed in the world further away than this isn't played
local BURST = 4 -- at most this many effects in any one second
local lastPlayed = {}
local recent = {}
local function playSfx(name, pos)
	local def = Sounds.Sfx[name]
	if not def then return end
	local now = os.clock()
	if lastPlayed[name] and now - lastPlayed[name] < (def.gap or 0.2) then return end
	for i = #recent, 1, -1 do
		if now - recent[i] > 1 then table.remove(recent, i) end
	end
	if #recent >= BURST then return end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if typeof(pos) == "Vector3" and root and (root.Position - pos).Magnitude > HEAR_RANGE then return end
	lastPlayed[name] = now
	table.insert(recent, now)
	local s = Instance.new("Sound")
	s.SoundId = def.id
	s.Volume = def.volume or 0.3
	s.PlaybackSpeed = name == "Collect" and (0.96 + math.random() * 0.08) or 1
	s.SoundGroup = sfxGroup
	s.Parent = SoundService
	s:Play()
	task.delay(def.max or 1.5, function()
		if s.Parent and s.IsPlaying then
			TweenService:Create(s, TweenInfo.new(0.2), { Volume = 0 }):Play()
			task.wait(0.25)
		end
		s:Destroy()
	end)
end
Remotes:WaitForChild("Sfx").OnClientEvent:Connect(playSfx)
sfxBus.Event:Connect(playSfx)

---------------------------------------------------------------------------
-- music: Relaxed Scene, on a loop
---------------------------------------------------------------------------
local music = Instance.new("Sound")
music.Name = "Music"
music.SoundId = Sounds.MainTheme.id
music.Looped = true
music.Volume = 0
music.SoundGroup = musicGroup
music.Parent = SoundService

local function musicOn()
	return player:GetAttribute("MusicOn") ~= false
end

local function applySettings()
	TweenService:Create(music, TweenInfo.new(0.6), { Volume = musicOn() and Sounds.MainTheme.volume or 0 }):Play()
	sfxGroup.Volume = player:GetAttribute("SfxOn") == false and 0 or 1
end
player:GetAttributeChangedSignal("MusicOn"):Connect(applySettings)
player:GetAttributeChangedSignal("SfxOn"):Connect(applySettings)

task.spawn(function()
	task.wait(1)
	music:Play()
	applySettings()
	-- the loop can stall if the asset reloads; restart it rather than go silent
	while true do
		task.wait(5)
		if not music.IsPlaying then music:Play() end
	end
end)

-- start from the saved settings
task.spawn(function()
	local Action = Remotes:WaitForChild("Action")
	local ok, profile = pcall(Action.InvokeServer, Action, "profile")
	if ok and type(profile) == "table" and profile.settings then
		player:SetAttribute("MusicOn", profile.settings.music ~= false)
		player:SetAttribute("SfxOn", profile.settings.sfx ~= false)
	end
end)
