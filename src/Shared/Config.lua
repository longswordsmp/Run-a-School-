-- ReplicatedStorage.Shared.Config
-- All content lives here so updates are data changes. See GAME-PLAN.md sections 3-5.
local Config = {}

local rgb = Color3.fromRGB

---------------------------------------------------------------------------
-- rarities (weights are for the regular bus)
---------------------------------------------------------------------------
Config.Rarities = {
	{ id = "Common", color = rgb(215, 215, 215), weight = 50 },
	{ id = "Uncommon", color = rgb(90, 220, 90), weight = 25 },
	{ id = "Rare", color = rgb(70, 150, 255), weight = 13 },
	{ id = "Epic", color = rgb(180, 80, 255), weight = 7 },
	{ id = "Legendary", color = rgb(255, 170, 30), weight = 3.5 },
	{ id = "Mythic", color = rgb(255, 50, 90), weight = 1.2 },
	{ id = "Prodigy", color = rgb(90, 230, 255), weight = 0.25, gradient = { rgb(90, 230, 255), rgb(190, 110, 255) } },
	{ id = "Secret", color = rgb(20, 20, 20), weight = 0.04, rainbow = true },
	{ id = "Alumni", color = rgb(255, 215, 120), weight = 0, gradient = { rgb(255, 240, 180), rgb(255, 170, 60) } },
}
Config.RarityById = {}
for i, r in Config.Rarities do
	r.order = i
	Config.RarityById[r.id] = r
end

-- colour for outlines and prompt accents (the black Secret tier reads as white)
function Config.rarityAccent(rarityId)
	local r = Config.RarityById[rarityId]
	return r.rainbow and Color3.new(1, 1, 1) or r.color
end

Config.Subjects = { "Math", "Science", "English", "History", "Art", "Music", "Drama", "Gym", "Tech", "Lunch" }

---------------------------------------------------------------------------
-- students
-- look: skin (light/tan/brown/dark), shirt (torso+arms), pants (legs), scale, head
-- prop: builder name in StudentProps
---------------------------------------------------------------------------
local function S(id, name, rarity, price, income, subject, prop, skin, shirt, pants, extra)
	local look = { skin = skin, shirt = shirt, pants = pants }
	for k, v in extra or {} do look[k] = v end
	return { id = id, name = name, rarity = rarity, price = price, income = income, subject = subject, prop = prop, look = look }
end

Config.Students = {
	-- Common
	S("SleepySam", "Sleepy Sam", "Common", 30, 1, "Music", "Nightcap", "light", rgb(140, 170, 230), rgb(80, 90, 140)),
	S("CrayonEater", "Crayon Eater", "Common", 60, 2, "Art", "Crayon", "tan", rgb(255, 120, 60), rgb(60, 60, 70)),
	S("BackpackKid", "Backpack Kid", "Common", 90, 3, "Gym", "Backpack", "brown", rgb(90, 200, 120), rgb(50, 70, 120)),
	S("JuiceBoxJake", "Juice Box Jake", "Common", 100, 3.5, "Lunch", "JuiceBox", "light", rgb(255, 200, 60), rgb(70, 110, 200)),
	S("BubbleGumBetty", "Bubble Gum Betty", "Common", 120, 4, "Music", "BubbleGum", "tan", rgb(255, 150, 200), rgb(120, 80, 160)),
	S("PencilChewer", "Pencil Chewer", "Common", 150, 5, "Math", "PencilChewer", "dark", rgb(120, 180, 90), rgb(90, 70, 50)),
	S("SneezySid", "Sneezy Sid", "Common", 180, 6, "Science", "Tissues", "light", rgb(200, 220, 240), rgb(60, 70, 90)),

	-- Uncommon
	S("ClassClown", "Class Clown", "Uncommon", 480, 8, "Drama", "ClownNose", "light", rgb(240, 60, 180), rgb(60, 180, 240)),
	S("NerdNed", "Nerd Ned", "Uncommon", 660, 11, "Math", "Glasses", "light", rgb(245, 245, 245), rgb(150, 110, 70)),
	S("FidgetFred", "Fidget Fred", "Uncommon", 840, 14, "Science", "FidgetSpinner", "brown", rgb(255, 110, 60), rgb(40, 50, 80)),
	S("HallMonitor", "Hall Monitor", "Uncommon", 1000, 17, "History", "Sash", "dark", rgb(80, 120, 200), rgb(40, 40, 50)),
	S("ShowAndTellSally", "Show-and-Tell Sally", "Uncommon", 1300, 21, "Science", "PetRock", "tan", rgb(120, 210, 200), rgb(200, 120, 60)),
	S("GamerGabe", "Gamer Gabe", "Uncommon", 1500, 25, "Tech", "GamerHeadset", "light", rgb(40, 40, 50), rgb(40, 40, 50)),
	S("TheaterKid", "Theater Kid", "Uncommon", 1800, 30, "Drama", "DramaMask", "brown", rgb(120, 30, 60), rgb(20, 20, 25)),

	-- Rare
	S("TeachersPet", "Teacher's Pet", "Rare", 5400, 45, "History", "Apple", "tan", rgb(255, 190, 210), rgb(90, 60, 110)),
	S("SkaterKid", "Skater Kid", "Rare", 7200, 60, "Gym", "Skateboard", "light", rgb(40, 40, 45), rgb(70, 110, 160)),
	S("Mathlete", "Mathlete", "Rare", 9600, 80, "Math", "Calculator", "dark", rgb(40, 90, 180), rgb(200, 200, 210)),
	S("BandGeek", "Band Geek", "Rare", 12000, 100, "Music", "Trumpet", "brown", rgb(150, 30, 40), rgb(30, 30, 40)),
	S("CheerCaptain", "Cheer Captain", "Rare", 15000, 125, "Gym", "PomPoms", "light", rgb(230, 40, 60), rgb(250, 250, 250)),
	S("ArtsyAva", "Artsy Ava", "Rare", 19000, 160, "Art", "Palette", "tan", rgb(250, 240, 220), rgb(60, 90, 160)),
	S("ChessChampion", "Chess Champion", "Rare", 24000, 200, "Math", "ChessKing", "light", rgb(30, 30, 35), rgb(230, 230, 230)),

	-- Epic
	S("Quarterback", "Star Quarterback", "Epic", 72000, 300, "Gym", "Football", "dark", rgb(230, 60, 40), rgb(240, 240, 240), { scale = 1.1 }),
	S("ScienceFair", "Science Fair Winner", "Epic", 100000, 420, "Science", "Goggles", "light", rgb(250, 250, 250), rgb(60, 60, 70)),
	S("ExchangeStudent", "Exchange Student", "Epic", 130000, 560, "History", "Suitcase", "tan", rgb(40, 150, 140), rgb(230, 220, 190)),
	S("SpellingBee", "Spelling Bee Champ", "Epic", 170000, 720, "English", "BeeCostume", "brown", rgb(255, 200, 30), rgb(30, 30, 30)),
	S("RoboticsKid", "Robotics Kid", "Epic", 230000, 950, "Tech", "RobotArm", "light", rgb(90, 100, 120), rgb(50, 55, 70)),
	S("Photographer", "Yearbook Photographer", "Epic", 290000, 1200, "Art", "Camera", "dark", rgb(70, 130, 90), rgb(160, 140, 110)),
	S("DramaQueen", "Drama Queen", "Epic", 360000, 1500, "Drama", "Tiara", "light", rgb(200, 60, 200), rgb(90, 20, 110)),

	-- Legendary
	S("Valedictorian", "Valedictorian", "Legendary", 1200000, 2500, "English", "GradCap", "brown", rgb(30, 30, 40), rgb(30, 30, 40)),
	S("CouncilPrez", "Student Council Prez", "Legendary", 1700000, 3600, "History", "Gavel", "light", rgb(30, 60, 140), rgb(120, 120, 130)),
	S("SchoolMascot", "School Mascot", "Legendary", 2300000, 4800, "Gym", "MascotHead", "light", rgb(120, 70, 30), rgb(120, 70, 30), { scale = 1.15 }),
	S("LunchFavorite", "Lunch Lady's Favorite", "Legendary", 3100000, 6500, "Lunch", "LunchTray", "tan", rgb(250, 200, 80), rgb(90, 70, 50), { scale = 1.15 }),
	S("PromKing", "Prom King", "Legendary", 3900000, 8200, "Drama", "Crown", "dark", rgb(20, 20, 30), rgb(20, 20, 30)),
	S("DanceDJ", "School Dance DJ", "Legendary", 4800000, 10000, "Music", "DJ", "brown", rgb(130, 40, 220), rgb(30, 30, 40)),
	S("HallOfFame", "Hall-of-Fame Athlete", "Legendary", 5800000, 12000, "Gym", "Trophy", "dark", rgb(30, 110, 60), rgb(240, 240, 240)),

	-- Mythic
	S("PrincipalsNephew", "Principal's Nephew", "Mythic", 22000000, 25000, "History", "ShadesTie", "light", rgb(240, 240, 250), rgb(20, 20, 30)),
	S("MoustacheKid", "Kid With A Moustache", "Mythic", 32000000, 35000, "English", "Moustache", "tan", rgb(110, 80, 60), rgb(60, 50, 45)),
	S("KidGenius", "Kid Genius", "Mythic", 43000000, 48000, "Science", "Brain", "tan", rgb(120, 60, 220), rgb(40, 30, 60), { head = 1.6 }),
	S("Room13Ghost", "Ghost of Room 13", "Mythic", 58000000, 65000, "Drama", "Ghost", "light", rgb(230, 240, 255), rgb(230, 240, 255)),
	S("TimeTraveler", "Time-Traveling Transfer", "Mythic", 79000000, 88000, "History", "PocketClock", "light", rgb(255, 120, 40), rgb(80, 60, 160)),
	S("NewKid", "The New Kid", "Mythic", 110000000, 120000, "Tech", "Hoodie", "dark", rgb(20, 20, 20), rgb(20, 20, 20)),

	-- Prodigy
	S("RocketKid", "Rocket Science Kid", "Prodigy", 450000000, 250000, "Science", "Jetpack", "light", rgb(240, 240, 245), rgb(230, 90, 30)),
	S("TinyProfessor", "Tiny Professor", "Prodigy", 720000000, 400000, "English", "Professor", "light", rgb(140, 110, 80), rgb(90, 70, 55)),
	S("PopStarKid", "Pop Star Kid", "Prodigy", 1.1e9, 620000, "Music", "PopStar", "brown", rgb(255, 80, 200), rgb(240, 240, 255)),
	S("ChessGrandmaster", "Chess Grandmaster (age 9)", "Prodigy", 1.7e9, 950000, "Math", "ChessOrbit", "dark", rgb(245, 245, 245), rgb(25, 25, 30)),
	S("ChildCEO", "Child CEO", "Prodigy", 2.7e9, 1500000, "Tech", "CEO", "light", rgb(30, 30, 40), rgb(30, 30, 40)),

	-- Secret
	S("WifiKid", "Kid Who Knows The WiFi Password", "Secret", 11e9, 3e6, "Tech", "Router", "light", rgb(0, 200, 255), rgb(30, 30, 60)),
	S("Substitute", "Substitute Teacher?!", "Secret", 23e9, 6.5e6, "Drama", "Trenchcoat", "light", rgb(150, 110, 60), rgb(150, 110, 60), { scale = 1.35 }),
	S("SnowDayOracle", "The Snow Day Oracle", "Secret", 43e9, 12e6, "Science", "SnowGlobe", "tan", rgb(160, 210, 255), rgb(230, 240, 255)),
	S("HomeworkReminder", "The Kid Who Reminded The Teacher About Homework", "Secret", 79e9, 22e6, "English", "HomeworkVillain", "light", rgb(90, 20, 20), rgb(30, 10, 10)),
	S("Student404", "Student #404", "Secret", 140e9, 40e6, "Tech", "Glitch", "light", rgb(255, 0, 200), rgb(0, 220, 255)),

	-- Alumni (never on the regular bus)
	S("GraduateGrandpa", "Graduate Grandpa", "Alumni", 1800e9, 250e6, "History", "Grandpa", "light", rgb(160, 30, 40), rgb(110, 100, 90)),
	S("ClassOf99", "Class of '99", "Alumni", 2700e9, 380e6, "Tech", "Class99", "tan", rgb(60, 130, 220), rgb(60, 70, 110)),
	S("HeadPrefect", "Head Prefect", "Alumni", 4000e9, 560e6, "English", "Prefect", "light", rgb(30, 30, 40), rgb(30, 30, 40)),
	S("TheFounder", "The Founder", "Alumni", 7200e9, 1e9, "History", "Founder", "light", rgb(150, 110, 70), rgb(150, 110, 70)),
	S("TinyPrincipal", "Principal (as a kid)", "Alumni", 11000e9, 1.5e9, "English", "TinyPrincipal", "brown", rgb(60, 60, 70), rgb(60, 60, 70)),
}
Config.StudentById = {}
for i, s in Config.Students do
	s.order = i
	Config.StudentById[s.id] = s
end

---------------------------------------------------------------------------
-- grades (mutations), rolled on the bus; event grades have weight 0 outside their event
---------------------------------------------------------------------------
Config.Grades = {
	{ id = "Normal", mult = 1, weight = 88 },
	{ id = "Honor Roll", mult = 1.5, weight = 7, color = rgb(255, 200, 40) },
	{ id = "Gifted", mult = 2.5, weight = 3, color = rgb(120, 230, 255) },
	{ id = "Straight A+", mult = 5, weight = 0.8, color = rgb(255, 90, 200), rainbow = true },
	{ id = "Detention", mult = 4, weight = 0.6, color = rgb(120, 50, 170) },
	{ id = "Valedictorian's Pick", mult = 8, weight = 0.1, color = rgb(255, 250, 220) },
	{ id = "Snow Day", mult = 3, weight = 0, event = "SnowDay", color = rgb(170, 220, 255) },
	{ id = "Radioactive", mult = 4, weight = 0, event = "ScienceFair", color = rgb(90, 255, 90) },
	{ id = "Picture Perfect", mult = 2, weight = 0, event = "PictureDay", color = rgb(255, 255, 255) },
	{ id = "Spooky", mult = 3.5, weight = 0, event = "Halloween", color = rgb(255, 130, 20) },
	{ id = "Cosmic", mult = 7, weight = 0, event = "SpaceCamp", color = rgb(140, 90, 255) },
}
Config.GradeById = {}
for _, g in Config.Grades do Config.GradeById[g.id] = g end

---------------------------------------------------------------------------
-- School Board tiers (rebirths). Index 1 is where everyone starts.
-- cash: what the Board wants to see; needs: a student id that must sit at one of your desks
-- ("Secret" = any Secret). mult: permanent tuition multiplier. floors: floors of desks.
-- tools/econ_sim.py reads these lines; keep one tier per line.
---------------------------------------------------------------------------
Config.Tiers = {
	{ name = "Kindergarten", cash = 0, needs = nil, mult = 1, floors = 1, lock = 60 },
	{ name = "Elementary School", cash = 450e3, needs = "HallMonitor", mult = 1.5, floors = 1, lock = 70 },
	{ name = "Middle School", cash = 20e6, needs = "BandGeek", mult = 2, floors = 2, lock = 75 },
	{ name = "High School", cash = 400e6, needs = "Quarterback", mult = 3, floors = 2, lock = 80 },
	{ name = "Prep School", cash = 17e9, needs = "Valedictorian", mult = 4.5, floors = 3, lock = 85 },
	{ name = "Private Academy", cash = 140e9, needs = "PromKing", mult = 6.5, floors = 3, lock = 90 },
	{ name = "Community College", cash = 3e12, needs = "KidGenius", mult = 9, floors = 3, lock = 95 },
	{ name = "State University", cash = 30e12, needs = "NewKid", mult = 13, floors = 3, lock = 100 },
	{ name = "Ivy League", cash = 100e12, needs = "TinyProfessor", mult = 18, floors = 3, lock = 105 },
	{ name = "Wizard School", cash = 360e12, needs = "PopStarKid", mult = 25, floors = 3, lock = 110 },
	{ name = "Space Academy", cash = 1.6e15, needs = "ChildCEO", mult = 35, floors = 3, lock = 115 },
	{ name = "Multiverse University", cash = 5.7e15, needs = "Secret", mult = 50, floors = 3, lock = 120 },
}
-- after the last tier, each Prestige star costs the previous requirement x3 and adds +10 %
Config.PrestigeStep = { cashMult = 3, bonus = 0.1 }

-- desk rows per floor (4 desks each); 0 = free with the floor. Rows are kept on review.
Config.DeskRows = {
	{ 0, 0, 5e3, 150e3 },
	{ 0, 0, 5e6, 50e6 },
	{ 0, 0, 5e9, 50e9 },
}
Config.DesksPerRow = 4

-- how each tier's building looks: walls, wall caps, floor, sign
Config.TierLooks = {
	{ wall = rgb(90, 170, 255), cap = rgb(255, 220, 70), floor = rgb(255, 245, 215), tile = rgb(255, 225, 160), sign = rgb(240, 70, 70) }, -- crayon Kindergarten
	{ wall = rgb(196, 92, 68), cap = rgb(255, 244, 214), floor = rgb(240, 226, 196), tile = rgb(222, 204, 170), sign = rgb(40, 90, 200) }, -- red-brick Elementary
	{ wall = rgb(226, 190, 140), cap = rgb(60, 170, 160), floor = rgb(235, 235, 225), tile = rgb(200, 215, 210), sign = rgb(40, 150, 140) }, -- Middle School
	{ wall = rgb(120, 140, 175), cap = rgb(150, 30, 45), floor = rgb(225, 225, 230), tile = rgb(190, 195, 205), sign = rgb(150, 30, 45) }, -- High School
	{ wall = rgb(45, 65, 120), cap = rgb(240, 200, 90), floor = rgb(230, 220, 200), tile = rgb(150, 40, 50), sign = rgb(30, 45, 90) }, -- Prep School
	{ wall = rgb(235, 235, 240), cap = rgb(240, 200, 90), floor = rgb(245, 245, 250), tile = rgb(215, 215, 225), sign = rgb(200, 160, 60) }, -- marble Academy
	{ wall = rgb(70, 130, 90), cap = rgb(250, 240, 210), floor = rgb(235, 230, 215), tile = rgb(200, 190, 160), sign = rgb(40, 90, 60) }, -- College
	{ wall = rgb(140, 40, 40), cap = rgb(250, 250, 250), floor = rgb(230, 225, 220), tile = rgb(170, 60, 60), sign = rgb(110, 25, 30) }, -- University
	{ wall = rgb(110, 118, 100), cap = rgb(70, 140, 60), floor = rgb(225, 225, 215), tile = rgb(170, 175, 160), sign = rgb(40, 90, 40) }, -- Ivy League
	{ wall = rgb(90, 60, 140), cap = rgb(240, 200, 90), floor = rgb(60, 45, 90), tile = rgb(90, 70, 130), sign = rgb(60, 30, 110) }, -- Wizard School
	{ wall = rgb(220, 226, 236), cap = rgb(60, 220, 255), floor = rgb(40, 45, 60), tile = rgb(60, 70, 90), sign = rgb(20, 30, 60) }, -- Space Academy
	{ wall = rgb(25, 20, 35), cap = rgb(255, 80, 220), floor = rgb(20, 15, 30), tile = rgb(60, 30, 90), sign = rgb(10, 10, 20) }, -- Multiverse
}

---------------------------------------------------------------------------
-- upgrades (kept on review). cost(level) = base * growth ^ level, level 0-based
---------------------------------------------------------------------------
Config.Upgrades = {
	{ id = "Recruitment", name = "Recruitment Office", icon = "\u{1F4E3}", max = 10, base = 10e3, growth = 4, desc = "+2% luck for rare students per level" },
	{ id = "Janitor", name = "Janitor's Cart", icon = "\u{1F9F9}", max = 5, base = 25e3, growth = 6, desc = "Auto-collects desk cash every 60s, 45s, 30s, 20s, 10s" },
	{ id = "TuitionOffice", name = "Tuition Office", icon = "\u{1F3E6}", max = 1, base = 50e3, growth = 1, desc = "A Collect All pad by your gate" },
	{ id = "LockTime", name = "Longer Lock", icon = "\u{1F512}", max = 10, base = 5e3, growth = 4, desc = "+8s of lock per level" },
	{ id = "LockCooldown", name = "Quick Re-lock", icon = "\u{23F1}\u{FE0F}", max = 5, base = 20e3, growth = 5, desc = "Lock cooldown 10s -> 2.5s" },
	{ id = "HallPass", name = "Hall Pass", icon = "\u{1F3C3}", max = 5, base = 100e3, growth = 6, desc = "+6% speed while carrying a student per level" },
	{ id = "Alarm", name = "Alarm Bell", icon = "\u{1F6A8}", max = 1, base = 15e3, growth = 1, desc = "Rings the whole server and outlines anyone stealing from you" },
}
Config.UpgradeById = {}
for i, u in Config.Upgrades do
	u.order = i
	Config.UpgradeById[u.id] = u
end
function Config.upgradeCost(id, level)
	local u = Config.UpgradeById[id]
	return math.floor(u.base * u.growth ^ level)
end
Config.JanitorIntervals = { 60, 45, 30, 20, 10 }

-- special buses
Config.LateBus = { every = 300, count = 6, minRarity = 3 } -- Rare+
Config.FieldTrip = { every = 1800, count = 8, weights = { Epic = 60, Legendary = 30, Mythic = 8, Prodigy = 1.8, Secret = 0.2 } }

---------------------------------------------------------------------------
-- tuning
---------------------------------------------------------------------------
Config.StartCash = 100
Config.SpawnInterval = 2.2 -- seconds between students off the bus
Config.WalkSpeed = 9 -- hallway walk speed
Config.MaxHallStudents = 40
Config.BaseDesks = 8
Config.DeskUpgrades = { { desks = 12, price = 5000 }, { desks = 16, price = 150000 } }
Config.LockTime = 60
Config.LockCooldown = 10
Config.SellFraction = 0.5
Config.CarrySpeed = 11

function Config.formatCash(n)
	n = math.floor(n)
	local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
	local i = 1
	local v = n
	while math.abs(v) >= 1000 and i < #suffixes do
		v /= 1000
		i += 1
	end
	if i == 1 then return "$" .. tostring(n) end
	local s = v >= 100 and string.format("%.0f", v) or v >= 10 and string.format("%.1f", v) or string.format("%.2f", v)
	if s:find("%.") then
		s = (s:gsub("0+$", ""))
		s = (s:gsub("%.$", ""))
	end
	return "$" .. s .. suffixes[i]
end

return Config
