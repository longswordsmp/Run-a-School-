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
	S("SleepySam", "Sleepy Sam", "Common", 25, 1, "Music", "Nightcap", "light", rgb(140, 170, 230), rgb(80, 90, 140)),
	S("CrayonEater", "Crayon Eater", "Common", 50, 2, "Art", "Crayon", "tan", rgb(255, 120, 60), rgb(60, 60, 70)),
	S("BackpackKid", "Backpack Kid", "Common", 75, 3, "Gym", "Backpack", "brown", rgb(90, 200, 120), rgb(50, 70, 120)),
	S("JuiceBoxJake", "Juice Box Jake", "Common", 110, 3.5, "Lunch", "JuiceBox", "light", rgb(255, 200, 60), rgb(70, 110, 200)),
	S("BubbleGumBetty", "Bubble Gum Betty", "Common", 150, 4, "Music", "BubbleGum", "tan", rgb(255, 150, 200), rgb(120, 80, 160)),
	S("PencilChewer", "Pencil Chewer", "Common", 200, 5, "Math", "PencilChewer", "dark", rgb(120, 180, 90), rgb(90, 70, 50)),
	S("SneezySid", "Sneezy Sid", "Common", 250, 6, "Science", "Tissues", "light", rgb(200, 220, 240), rgb(60, 70, 90)),

	-- Uncommon
	S("ClassClown", "Class Clown", "Uncommon", 400, 8, "Drama", "ClownNose", "light", rgb(240, 60, 180), rgb(60, 180, 240)),
	S("NerdNed", "Nerd Ned", "Uncommon", 650, 11, "Math", "Glasses", "light", rgb(245, 245, 245), rgb(150, 110, 70)),
	S("FidgetFred", "Fidget Fred", "Uncommon", 900, 14, "Science", "FidgetSpinner", "brown", rgb(255, 110, 60), rgb(40, 50, 80)),
	S("HallMonitor", "Hall Monitor", "Uncommon", 1200, 17, "History", "Sash", "dark", rgb(80, 120, 200), rgb(40, 40, 50)),
	S("ShowAndTellSally", "Show-and-Tell Sally", "Uncommon", 1600, 21, "Science", "PetRock", "tan", rgb(120, 210, 200), rgb(200, 120, 60)),
	S("GamerGabe", "Gamer Gabe", "Uncommon", 2000, 25, "Tech", "GamerHeadset", "light", rgb(40, 40, 50), rgb(40, 40, 50)),
	S("TheaterKid", "Theater Kid", "Uncommon", 2500, 30, "Drama", "DramaMask", "brown", rgb(120, 30, 60), rgb(20, 20, 25)),

	-- Rare
	S("TeachersPet", "Teacher's Pet", "Rare", 4000, 45, "History", "Apple", "tan", rgb(255, 190, 210), rgb(90, 60, 110)),
	S("SkaterKid", "Skater Kid", "Rare", 6000, 60, "Gym", "Skateboard", "light", rgb(40, 40, 45), rgb(70, 110, 160)),
	S("Mathlete", "Mathlete", "Rare", 8500, 80, "Math", "Calculator", "dark", rgb(40, 90, 180), rgb(200, 200, 210)),
	S("BandGeek", "Band Geek", "Rare", 11000, 100, "Music", "Trumpet", "brown", rgb(150, 30, 40), rgb(30, 30, 40)),
	S("CheerCaptain", "Cheer Captain", "Rare", 14000, 125, "Gym", "PomPoms", "light", rgb(230, 40, 60), rgb(250, 250, 250)),
	S("ArtsyAva", "Artsy Ava", "Rare", 19000, 160, "Art", "Palette", "tan", rgb(250, 240, 220), rgb(60, 90, 160)),
	S("ChessChampion", "Chess Champion", "Rare", 25000, 200, "Math", "ChessKing", "light", rgb(30, 30, 35), rgb(230, 230, 230)),

	-- Epic
	S("Quarterback", "Star Quarterback", "Epic", 40000, 300, "Gym", "Football", "dark", rgb(230, 60, 40), rgb(240, 240, 240), { scale = 1.1 }),
	S("ScienceFair", "Science Fair Winner", "Epic", 60000, 420, "Science", "Goggles", "light", rgb(250, 250, 250), rgb(60, 60, 70)),
	S("ExchangeStudent", "Exchange Student", "Epic", 85000, 560, "History", "Suitcase", "tan", rgb(40, 150, 140), rgb(230, 220, 190)),
	S("SpellingBee", "Spelling Bee Champ", "Epic", 110000, 720, "English", "BeeCostume", "brown", rgb(255, 200, 30), rgb(30, 30, 30)),
	S("RoboticsKid", "Robotics Kid", "Epic", 150000, 950, "Tech", "RobotArm", "light", rgb(90, 100, 120), rgb(50, 55, 70)),
	S("Photographer", "Yearbook Photographer", "Epic", 200000, 1200, "Art", "Camera", "dark", rgb(70, 130, 90), rgb(160, 140, 110)),
	S("DramaQueen", "Drama Queen", "Epic", 250000, 1500, "Drama", "Tiara", "light", rgb(200, 60, 200), rgb(90, 20, 110)),

	-- Legendary
	S("Valedictorian", "Valedictorian", "Legendary", 400000, 2500, "English", "GradCap", "brown", rgb(30, 30, 40), rgb(30, 30, 40)),
	S("CouncilPrez", "Student Council Prez", "Legendary", 650000, 3600, "History", "Gavel", "light", rgb(30, 60, 140), rgb(120, 120, 130)),
	S("SchoolMascot", "School Mascot", "Legendary", 900000, 4800, "Gym", "MascotHead", "light", rgb(120, 70, 30), rgb(120, 70, 30), { scale = 1.15 }),
	S("LunchFavorite", "Lunch Lady's Favorite", "Legendary", 1300000, 6500, "Lunch", "LunchTray", "tan", rgb(250, 200, 80), rgb(90, 70, 50), { scale = 1.15 }),
	S("PromKing", "Prom King", "Legendary", 1800000, 8200, "Drama", "Crown", "dark", rgb(20, 20, 30), rgb(20, 20, 30)),
	S("DanceDJ", "School Dance DJ", "Legendary", 2400000, 10000, "Music", "DJ", "brown", rgb(130, 40, 220), rgb(30, 30, 40)),
	S("HallOfFame", "Hall-of-Fame Athlete", "Legendary", 3000000, 12000, "Gym", "Trophy", "dark", rgb(30, 110, 60), rgb(240, 240, 240)),

	-- Mythic
	S("PrincipalsNephew", "Principal's Nephew", "Mythic", 5000000, 25000, "History", "ShadesTie", "light", rgb(240, 240, 250), rgb(20, 20, 30)),
	S("MoustacheKid", "Kid With A Moustache", "Mythic", 8000000, 35000, "English", "Moustache", "tan", rgb(110, 80, 60), rgb(60, 50, 45)),
	S("KidGenius", "Kid Genius", "Mythic", 12000000, 48000, "Science", "Brain", "tan", rgb(120, 60, 220), rgb(40, 30, 60), { head = 1.6 }),
	S("Room13Ghost", "Ghost of Room 13", "Mythic", 18000000, 65000, "Drama", "Ghost", "light", rgb(230, 240, 255), rgb(230, 240, 255)),
	S("TimeTraveler", "Time-Traveling Transfer", "Mythic", 26000000, 88000, "History", "PocketClock", "light", rgb(255, 120, 40), rgb(80, 60, 160)),
	S("NewKid", "The New Kid", "Mythic", 40000000, 120000, "Tech", "Hoodie", "dark", rgb(20, 20, 20), rgb(20, 20, 20)),

	-- Prodigy
	S("RocketKid", "Rocket Science Kid", "Prodigy", 80000000, 250000, "Science", "Jetpack", "light", rgb(240, 240, 245), rgb(230, 90, 30)),
	S("TinyProfessor", "Tiny Professor", "Prodigy", 140000000, 400000, "English", "Professor", "light", rgb(140, 110, 80), rgb(90, 70, 55)),
	S("PopStarKid", "Pop Star Kid", "Prodigy", 220000000, 620000, "Music", "PopStar", "brown", rgb(255, 80, 200), rgb(240, 240, 255)),
	S("ChessGrandmaster", "Chess Grandmaster (age 9)", "Prodigy", 350000000, 950000, "Math", "ChessOrbit", "dark", rgb(245, 245, 245), rgb(25, 25, 30)),
	S("ChildCEO", "Child CEO", "Prodigy", 600000000, 1500000, "Tech", "CEO", "light", rgb(30, 30, 40), rgb(30, 30, 40)),

	-- Secret
	S("WifiKid", "Kid Who Knows The WiFi Password", "Secret", 1e9, 3e6, "Tech", "Router", "light", rgb(0, 200, 255), rgb(30, 30, 60)),
	S("Substitute", "Substitute Teacher?!", "Secret", 2.5e9, 6.5e6, "Drama", "Trenchcoat", "light", rgb(150, 110, 60), rgb(150, 110, 60), { scale = 1.35 }),
	S("SnowDayOracle", "The Snow Day Oracle", "Secret", 5e9, 12e6, "Science", "SnowGlobe", "tan", rgb(160, 210, 255), rgb(230, 240, 255)),
	S("HomeworkReminder", "The Kid Who Reminded The Teacher About Homework", "Secret", 10e9, 22e6, "English", "HomeworkVillain", "light", rgb(90, 20, 20), rgb(30, 10, 10)),
	S("Student404", "Student #404", "Secret", 25e9, 40e6, "Tech", "Glitch", "light", rgb(255, 0, 200), rgb(0, 220, 255)),

	-- Alumni (never on the regular bus)
	S("GraduateGrandpa", "Graduate Grandpa", "Alumni", 100e9, 250e6, "History", "Grandpa", "light", rgb(160, 30, 40), rgb(110, 100, 90)),
	S("ClassOf99", "Class of '99", "Alumni", 150e9, 380e6, "Tech", "Class99", "tan", rgb(60, 130, 220), rgb(60, 70, 110)),
	S("HeadPrefect", "Head Prefect", "Alumni", 220e9, 560e6, "English", "Prefect", "light", rgb(30, 30, 40), rgb(30, 30, 40)),
	S("TheFounder", "The Founder", "Alumni", 400e9, 1e9, "History", "Founder", "light", rgb(150, 110, 70), rgb(150, 110, 70)),
	S("TinyPrincipal", "Principal (as a kid)", "Alumni", 600e9, 1.5e9, "English", "TinyPrincipal", "brown", rgb(60, 60, 70), rgb(60, 60, 70)),
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
	local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi" }
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
