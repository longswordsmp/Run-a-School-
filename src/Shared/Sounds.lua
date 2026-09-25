-- ReplicatedStorage.Shared.Sounds
-- Every sound the game plays. Deliberately few: one song, and a handful of effects that answer
-- something the player just did. A name that isn't here plays nothing, so the server can keep firing
-- Remotes.Sfx for moments that used to have a sound without any of it reaching the speakers.
-- All ids were loaded in Studio and report a real TimeLength; do not add one without loading it.
local Sounds = {}

local function id(n)
	return "rbxassetid://" .. n
end

-- the only music: "Relaxed Scene", looped
Sounds.MainTheme = { id = id(1848354536), name = "Relaxed Scene", volume = 0.4 }

-- effects: name -> { id, volume, max seconds (cut long files short), gap (min seconds between plays) }
Sounds.Sfx = {
	Enroll = { id = id(7527328153), volume = 0.32, max = 1.2, gap = 0.3 },
	Collect = { id = id(101396758527961), volume = 0.22, max = 0.8, gap = 0.35 },
	Buy = { id = id(120891770644830), volume = 0.3, max = 1.2, gap = 0.3 },
	Upgrade = { id = id(3406813517), volume = 0.3, max = 1.5, gap = 0.5 },
	Lock = { id = id(9119717529), volume = 0.35, max = 0.8, gap = 0.5 },
	Bonk = { id = id(3765689841), volume = 0.4, max = 0.8, gap = 0.2 },
	Error = { id = id(16903690359), volume = 0.2, max = 0.5, gap = 0.5 },
}

return Sounds
