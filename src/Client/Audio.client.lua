-- StarterPlayer.StarterPlayerScripts.Audio
-- Music and sound effects.
--   Music: "Relaxed Scene" opens every session and returns every other track; the rest of the
--   playlist shuffles. Context tracks (board review, stealing, alarm, recess, events) take over
--   while they apply and crossfade back.
--   Effects: the server fires Remotes.Sfx(name, worldPos?); other client scripts fire the local
--   ReplicatedStorage.ClientBus.Sfx bindable with the same arguments.
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
local function bindable(name)
	local b = bus:FindFirstChild(name)
	if not b then
		b = Instance.new("BindableEvent")
		b.Name = name
		b.Parent = bus
	end
	return b
end
local sfxBus = bindable("Sfx")

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
local lastPlayed = {}
local function playSfx(name, pos)
	local def = Sounds.Sfx[name]
	if not def then return end
	-- the same effect at most every 60 ms, so a burst of collects doesn't stack into noise
	local now = os.clock()
	if lastPlayed[name] and now - lastPlayed[name] < 0.06 then return end
	lastPlayed[name] = now
	local s = Instance.new("Sound")
	s.SoundId = def.id
	s.Volume = def.volume or 0.5
	s.PlaybackSpeed = (name == "Collect" or name == "Coin") and (0.95 + math.random() * 0.13) or 1
	s.SoundGroup = sfxGroup
	local holder
	if typeof(pos) == "Vector3" then
		holder = Instance.new("Part")
		holder.Anchored, holder.CanCollide, holder.CanQuery, holder.CanTouch = true, false, false, false
		holder.Transparency = 1
		holder.Size = Vector3.one * 0.2
		holder.Position = pos
		holder.Parent = workspace
		s.RollOffMaxDistance = 160
		s.RollOffMinDistance = 12
		s.Parent = holder
	else
		s.Parent = SoundService
	end
	s:Play()
	local max = def.max or 3
	task.delay(max, function()
		if s.Parent and s.IsPlaying then
			TweenService:Create(s, TweenInfo.new(0.25), { Volume = 0 }):Play()
			task.wait(0.3)
		end
		if holder then holder:Destroy() else s:Destroy() end
	end)
end
Remotes:WaitForChild("Sfx").OnClientEvent:Connect(playSfx)
sfxBus.Event:Connect(playSfx)

---------------------------------------------------------------------------
-- music
---------------------------------------------------------------------------
local decks = {}
for i = 1, 2 do
	local s = Instance.new("Sound")
	s.Name = "MusicDeck" .. i
	s.Looped = false
	s.Volume = 0
	s.SoundGroup = musicGroup
	s.Parent = SoundService
	decks[i] = s
end
local active = 1
local currentTrack
local playingContext = nil
local mainNext = false -- the main theme plays first, then every other track
local order, orderPos = {}, 0

-- small "now playing" tag, bottom left, fades out
local gui = Instance.new("ScreenGui")
gui.Name = "NowPlaying"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local tag = Instance.new("TextLabel")
tag.BackgroundTransparency = 1
tag.AnchorPoint = Vector2.new(0, 1)
tag.Position = UDim2.new(0, 16, 1, -14)
tag.Size = UDim2.fromOffset(300, 26)
tag.Font = Enum.Font.FredokaOne
tag.TextScaled = true
tag.TextXAlignment = Enum.TextXAlignment.Left
tag.TextColor3 = Color3.new(1, 1, 1)
tag.TextTransparency = 1
tag.Parent = gui
local tagStroke = Instance.new("UIStroke")
tagStroke.Thickness = 2
tagStroke.Transparency = 1
tagStroke.Parent = tag
local function showTag(name)
	tag.Text = "\u{266A} " .. name
	TweenService:Create(tag, TweenInfo.new(0.4), { TextTransparency = 0.1 }):Play()
	TweenService:Create(tagStroke, TweenInfo.new(0.4), { Transparency = 0.2 }):Play()
	task.delay(4, function()
		if tag.Text == "\u{266A} " .. name then
			TweenService:Create(tag, TweenInfo.new(1), { TextTransparency = 1 }):Play()
			TweenService:Create(tagStroke, TweenInfo.new(1), { Transparency = 1 }):Play()
		end
	end)
end

local function shuffle()
	order = {}
	for i = 1, #Sounds.Playlist do order[i] = i end
	for i = #order, 2, -1 do
		local j = math.random(i)
		order[i], order[j] = order[j], order[i]
	end
	orderPos = 0
end

local function musicOn()
	return player:GetAttribute("MusicOn") ~= false
end

local function play(track, looped)
	if currentTrack == track then return end
	currentTrack = track
	local old = decks[active]
	active = 3 - active
	local new = decks[active]
	TweenService:Create(old, TweenInfo.new(1.5), { Volume = 0 }):Play()
	task.delay(1.6, function()
		if decks[3 - active] == old then old:Stop() end
	end)
	new.SoundId = track.id
	new.Looped = looped == true
	new.TimePosition = 0
	new.Volume = 0
	new:Play()
	TweenService:Create(new, TweenInfo.new(1.5), { Volume = musicOn() and track.volume or 0 }):Play()
	showTag(track.name)
end

local function nextPlaylistTrack()
	if not mainNext then
		mainNext = true
		return Sounds.MainTheme
	end
	mainNext = false
	orderPos += 1
	if orderPos > #order then shuffle() orderPos = 1 end
	return Sounds.Playlist[order[orderPos]]
end

-- which context applies right now (nil = the normal playlist)
local function wantedContext()
	local now = workspace:GetServerTimeNow()
	local local_ = player:GetAttribute("LocalMusic") -- set by client scripts (cutscenes)
	local candidates = {
		board = local_ == "board",
		stealing = player:GetAttribute("Carrying") ~= nil,
		alarm = player:GetAttribute("AlarmUntil") ~= nil and player:GetAttribute("AlarmUntil") > now,
		recess = (workspace:GetAttribute("RecessUntil") or 0) > now,
		heroes = local_ == "heroes",
		snow = workspace:GetAttribute("Event") == "snow",
		halloween = workspace:GetAttribute("Event") == "halloween",
	}
	for _, key in Sounds.ContextOrder do
		if candidates[key] then return key end
	end
	return nil
end

shuffle()
task.spawn(function()
	task.wait(1)
	play(nextPlaylistTrack())
	while true do
		task.wait(0.5)
		local ctx = wantedContext()
		if ctx ~= playingContext then
			playingContext = ctx
			if ctx then
				play(Sounds.Context[ctx], true)
			else
				currentTrack = nil
				play(nextPlaylistTrack())
			end
		elseif not ctx then
			local deck = decks[active]
			-- the track ended (or failed to load): move on
			if not deck.IsPlaying or (deck.TimeLength > 0 and deck.TimePosition >= deck.TimeLength - 1.6) then
				play(nextPlaylistTrack())
			end
		end
	end
end)

-- settings: MusicOn / SfxOn are local attributes the Settings panel flips
local function applySettings()
	local track = currentTrack
	local deck = decks[active]
	if track then
		TweenService:Create(deck, TweenInfo.new(0.5), { Volume = musicOn() and track.volume or 0 }):Play()
	end
	sfxGroup.Volume = player:GetAttribute("SfxOn") == false and 0 or 1
end
player:GetAttributeChangedSignal("MusicOn"):Connect(applySettings)
player:GetAttributeChangedSignal("SfxOn"):Connect(applySettings)

-- start from the saved settings
task.spawn(function()
	local Action = Remotes:WaitForChild("Action")
	local ok, profile = pcall(Action.InvokeServer, Action, "profile")
	if ok and type(profile) == "table" and profile.settings then
		player:SetAttribute("MusicOn", profile.settings.music ~= false)
		player:SetAttribute("SfxOn", profile.settings.sfx ~= false)
	end
end)
