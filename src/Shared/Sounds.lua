-- ReplicatedStorage.Shared.Sounds
-- Every sound the game uses. All ids were loaded in Studio and report a real TimeLength
-- (see NIGHT-LOG.md); do not add an id here without loading it first.
local Sounds = {}

local function id(n)
	return "rbxassetid://" .. n
end

-- music: the main theme opens every session and comes back every other track
Sounds.MainTheme = { id = id(1848354536), name = "Relaxed Scene", volume = 0.42 }
Sounds.Playlist = {
	{ id = id(1837500112), name = "Tongue in Cheek", volume = 0.36 },
	{ id = id(1841134066), name = "Playful Twist", volume = 0.36 },
	{ id = id(1839578771), name = "Ukulele", volume = 0.38 },
	{ id = id(1839821481), name = "Optimistic Side", volume = 0.36 },
	{ id = id(1835450413), name = "Little Toys", volume = 0.36 },
	{ id = id(1842217520), name = "Giggle Wiggle", volume = 0.34 },
}
-- music that takes over while something is happening (highest priority first)
Sounds.Context = {
	board = { id = id(1845466486), name = "Brass Fanfare", volume = 0.5 },
	stealing = { id = id(9044658932), name = "Sketch Adventures", volume = 0.45 },
	alarm = { id = id(9041776401), name = "Pulsating Countdown", volume = 0.4 },
	recess = { id = id(1848294293), name = "Runaway Carousel", volume = 0.4 },
	heroes = { id = id(83315768373322), name = "Conquering Heroes", volume = 0.42 },
	snow = { id = id(1839303591), name = "Jingle Bells Kids", volume = 0.38 },
	halloween = { id = id(9041756048), name = "Horror Strings", volume = 0.38 },
}
Sounds.ContextOrder = { "board", "stealing", "alarm", "recess", "heroes", "snow", "halloween" }

-- effects: name -> { id, volume, max seconds (cut long files short), pitch range }
Sounds.Sfx = {
	Collect = { id = id(101396758527961), volume = 0.5, max = 1.2 },
	Coin = { id = id(1169806635), volume = 0.45, max = 1 },
	Enroll = { id = id(7527328153), volume = 0.55, max = 1.5 },
	Sell = { id = id(90531793028786), volume = 0.5, max = 1.5 },
	Upgrade = { id = id(3406813517), volume = 0.5, max = 2 },
	Buy = { id = id(120891770644830), volume = 0.5, max = 1.5 },
	Lock = { id = id(9119717529), volume = 0.7, max = 1 },
	Unlock = { id = id(18192219147), volume = 0.55, max = 1.5 },
	Error = { id = id(16903690359), volume = 0.35, max = 0.6 },
	BusHorn = { id = id(9114661198), volume = 0.6, max = 2.5 },
	SchoolBell = { id = id(2783281207), volume = 0.45, max = 4 },
	Bell = { id = id(1620077983), volume = 0.45, max = 3 },
	BrassBell = { id = id(9113583960), volume = 0.5, max = 2.5 },
	Choir = { id = id(89757312498953), volume = 0.6, max = 4 },
	Choir2 = { id = id(121538758381608), volume = 0.6, max = 4 },
	RecordScratch = { id = id(112792997660073), volume = 0.55, max = 1.5 },
	Scratch2 = { id = id(78519387192089), volume = 0.55, max = 1.5 },
	Alarm = { id = id(140176777321375), volume = 0.35, max = 4 },
	Siren = { id = id(7939429566), volume = 0.35, max = 4 },
	Gavel = { id = id(9125574353), volume = 0.7, max = 2 },
	GavelBig = { id = id(9114559389), volume = 0.7, max = 2 },
	Swing = { id = id(9120972321), volume = 0.6, max = 1 },
	Whoosh = { id = id(9125805579), volume = 0.5, max = 2 },
	Ding = { id = id(4462044869), volume = 0.5, max = 1.5 },
	Cheer = { id = id(100914187377996), volume = 0.5, max = 4 },
	Rare = { id = id(128460880879263), volume = 0.55, max = 4 },
	Token = { id = id(3416831713), volume = 0.5, max = 1.5 },
	Doom = { id = id(9039598193), volume = 0.5, max = 3 },
	-- comedy and world effects (loaded in Studio 2026-09-25, lengths in seconds)
	Whistle = { id = id(9117261163), volume = 0.5, max = 1 }, -- 0.62, Pro Sound Effects
	WhistleLong = { id = id(9118113825), volume = 0.45, max = 2 }, -- 1.85, PSE
	SlideWhistle = { id = id(9119198140), volume = 0.5, max = 1.5 }, -- 1.32, PSE
	Hammer = { id = id(9114756916), volume = 0.45, max = 1.8 }, -- 1.71, PSE
	Splash = { id = id(9117947974), volume = 0.4, max = 0.5 }, -- 0.36, PSE
	Bonk = { id = id(3765689841), volume = 0.6, max = 0.8 }, -- 0.73
	DogBark = { id = id(123024926216748), volume = 0.4, max = 0.8 }, -- 0.73
	SadTrombone = { id = id(190705984), volume = 0.45, max = 4 }, -- 3.92
	DrumRoll = { id = id(4718483268), volume = 0.45, max = 2.1 }, -- 2.00
	-- short musical stings for big moments
	StingParty = { id = id(9045119921), volume = 0.5, max = 6 },
	StingMorning = { id = id(9040476898), volume = 0.5, max = 6 },
	StingWhat = { id = id(9042807094), volume = 0.5, max = 5 },
	StingSitcom = { id = id(1846521568), volume = 0.5, max = 5 },
	StingWild = { id = id(9047214582), volume = 0.5, max = 5 },
	StingBang = { id = id(1841488866), volume = 0.5, max = 5 },
}

return Sounds
