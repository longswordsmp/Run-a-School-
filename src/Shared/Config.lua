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
	-- Common (the first six are the starter kids: cheap enough to fill the first desks in a minute)
	S("UntiedTyler", "Untied Tyler", "Common", 9, 0.3, "Gym", "Shoelaces", "light", rgb(90, 160, 230), rgb(60, 60, 80)),
	S("GlueStickGus", "Glue Stick Gus", "Common", 12, 0.4, "Art", "GlueStick", "brown", rgb(250, 160, 60), rgb(70, 90, 140)),
	S("DoodleDot", "Doodle Dot", "Common", 15, 0.5, "Art", "Sketchbook", "tan", rgb(250, 220, 240), rgb(90, 80, 140)),
	S("LunchboxLucy", "Lunchbox Lucy", "Common", 18, 0.6, "Lunch", "Lunchbox", "dark", rgb(255, 210, 70), rgb(200, 60, 80)),
	S("PajamaPete", "Pajama Pete", "Common", 21, 0.7, "Music", "Pajamas", "light", rgb(120, 170, 240), rgb(120, 170, 240)),
	S("HiccupHank", "Hiccup Hank", "Common", 24, 0.8, "Science", "Hiccups", "tan", rgb(120, 200, 120), rgb(80, 70, 60)),
	S("SleepySam", "Sleepy Sam", "Common", 30, 1, "Music", "Nightcap", "light", rgb(140, 170, 230), rgb(80, 90, 140)),
	S("CrayonEater", "Crayon Eater", "Common", 60, 2, "Art", "Crayon", "tan", rgb(255, 120, 60), rgb(60, 60, 70)),
	S("BackpackKid", "Backpack Kid", "Common", 90, 3, "Gym", "Backpack", "brown", rgb(90, 200, 120), rgb(50, 70, 120)),
	S("JuiceBoxJake", "Juice Box Jake", "Common", 100, 3.5, "Lunch", "JuiceBox", "light", rgb(255, 200, 60), rgb(70, 110, 200)),
	S("BubbleGumBetty", "Bubble Gum Betty", "Common", 120, 4, "Music", "BubbleGum", "tan", rgb(255, 150, 200), rgb(120, 80, 160)),
	S("PencilChewer", "Pencil Chewer", "Common", 150, 5, "Math", "PencilChewer", "dark", rgb(120, 180, 90), rgb(90, 70, 50)),
	S("SneezySid", "Sneezy Sid", "Common", 180, 6, "Science", "Tissues", "light", rgb(200, 220, 240), rgb(60, 70, 90)),
	S("PuddlePip", "Puddle Jumper Pip", "Common", 45, 1.5, "Science", "RainCloud", "light", rgb(255, 215, 40), rgb(60, 110, 200)),
	S("HomeworkDoug", "Dog-Ate-My-Homework Doug", "Common", 75, 2.5, "English", "Puppy", "tan", rgb(220, 60, 60), rgb(70, 70, 80)),
	S("RecorderRosie", "Recorder Rosie", "Common", 210, 7, "Music", "Recorder", "brown", rgb(250, 130, 160), rgb(90, 60, 140)),
	S("FrogFran", "Frog-in-Pocket Fran", "Common", 240, 8, "Science", "Frog", "brown", rgb(250, 140, 170), rgb(60, 120, 80)),
	S("MimeMimi", "Mime Mimi", "Common", 270, 9, "Drama", "MimeBeret", "light", rgb(245, 245, 245), rgb(25, 25, 30)),

	-- Uncommon
	S("TattletaleTina", "Tattletale Tina", "Uncommon", 300, 5, "History", "Clipboard", "tan", rgb(150, 90, 200), rgb(60, 60, 80)),
	S("LooseToothLou", "Loose Tooth Lou", "Uncommon", 360, 6, "Math", "ToothDoor", "brown", rgb(90, 190, 110), rgb(70, 60, 50)),
	S("CardboardRudy", "Cardboard Robot Rudy", "Uncommon", 420, 7, "Tech", "CardboardBot", "light", rgb(170, 130, 85), rgb(80, 80, 90)),
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
	{ name = "Elementary School", cash = 680e3, needs = "HallMonitor", mult = 1.5, floors = 1, lock = 70 },
	{ name = "Middle School", cash = 59e6, needs = "BandGeek", mult = 2, floors = 2, lock = 75 },
	{ name = "High School", cash = 910e6, needs = "Quarterback", mult = 3, floors = 2, lock = 80 },
	{ name = "Prep School", cash = 47e9, needs = "Valedictorian", mult = 4.5, floors = 3, lock = 85 },
	{ name = "Private Academy", cash = 740e9, needs = "PromKing", mult = 6.5, floors = 3, lock = 90 },
	{ name = "Community College", cash = 9.6e12, needs = "KidGenius", mult = 9, floors = 3, lock = 95 },
	{ name = "State University", cash = 110e12, needs = "NewKid", mult = 13, floors = 3, lock = 100 },
	{ name = "Ivy League", cash = 410e12, needs = "TinyProfessor", mult = 18, floors = 3, lock = 105 },
	{ name = "Wizard School", cash = 2.3e15, needs = "PopStarKid", mult = 25, floors = 3, lock = 110 },
	{ name = "Space Academy", cash = 7.2e15, needs = "ChildCEO", mult = 35, floors = 3, lock = 115 },
	{ name = "Multiverse University", cash = 22e15, needs = "Secret", mult = 50, floors = 3, lock = 120 },
}
-- what the Board Chair says when approving each tier (the story so far, one line per promotion)
Config.BoardLines = {
	[2] = "Elementary! Don't let it go to your head, Principal.",
	[3] = "Middle School. The lunch lady called you 'tolerable'. High praise.",
	[4] = "High School! Keep the Quarterback out of the trophy case.",
	[5] = "Prep School. Blazers are mandatory. Even for the class hamster.",
	[6] = "A Private Academy. The Board has feelings. Good ones.",
	[7] = "College! Kid Genius says he built this room. We doubt it.",
	[8] = "A University. We ran out of gold stars. More are on order.",
	[9] = "Ivy League. The ivy is real. Somebody water it.",
	[10] = "A Wizard School?! Nobody on this Board can explain it.",
	[11] = "Space Academy. Please return the Board's chairs from orbit.",
	[12] = "Multiverse University. There are nine of me now. We ALL approve.",
	star = "Another star! The Board bows to you, Principal.",
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

-- how each tier's building looks. wall/cap: outside walls and trim; inner: interior walls;
-- floor/tile: classroom checker; lobby; locker; chair; door; roof; foundation; sign; column;
-- tower: nil | "clock" | "bell" | "spires" | "rocket" | "portal"
local function look(t)
	t.inner = t.inner or rgb(252, 244, 226)
	t.lobby = t.lobby or rgb(232, 224, 208)
	t.foundation = t.foundation or rgb(160, 160, 170)
	t.roof = t.roof or rgb(120, 120, 130)
	t.desk = t.desk or rgb(214, 160, 100)
	t.board = t.board or rgb(38, 74, 56)
	t.column = t.column or rgb(248, 246, 240)
	t.bush = t.bush or rgb(60, 160, 70)
	t.stair = t.stair or rgb(175, 175, 185)
	return t
end
Config.TierLooks = {
	look({ wall = rgb(120, 190, 255), cap = rgb(255, 214, 70), floor = rgb(255, 246, 222), tile = rgb(255, 214, 150), sign = rgb(235, 70, 70), locker = rgb(235, 80, 80), chair = rgb(255, 130, 60), door = rgb(230, 60, 60), roof = rgb(235, 110, 90), lobby = rgb(255, 236, 200) }), -- crayon Kindergarten
	look({ wall = rgb(196, 92, 68), cap = rgb(255, 244, 214), floor = rgb(240, 228, 200), tile = rgb(214, 196, 164), sign = rgb(40, 90, 200), locker = rgb(60, 120, 220), chair = rgb(60, 132, 232), door = rgb(40, 90, 200) }), -- red-brick Elementary
	look({ wall = rgb(226, 190, 140), cap = rgb(60, 170, 160), floor = rgb(236, 236, 226), tile = rgb(196, 214, 206), sign = rgb(40, 150, 140), locker = rgb(50, 160, 150), chair = rgb(240, 140, 60), door = rgb(40, 140, 130) }), -- Middle School
	look({ wall = rgb(126, 146, 180), cap = rgb(160, 36, 50), floor = rgb(228, 228, 232), tile = rgb(186, 192, 204), sign = rgb(150, 30, 45), locker = rgb(150, 40, 55), chair = rgb(90, 100, 120), door = rgb(140, 30, 45) }), -- High School
	look({ wall = rgb(52, 72, 128), cap = rgb(240, 200, 90), floor = rgb(232, 222, 202), tile = rgb(150, 44, 54), sign = rgb(30, 45, 90), locker = rgb(40, 60, 110), chair = rgb(120, 25, 35), door = rgb(110, 20, 30), lobby = rgb(214, 206, 190) }), -- Prep School
	look({ wall = rgb(236, 236, 242), cap = rgb(230, 190, 80), floor = rgb(246, 246, 250), tile = rgb(212, 212, 224), sign = rgb(200, 160, 60), locker = rgb(40, 50, 90), chair = rgb(30, 40, 80), door = rgb(30, 40, 80), roof = rgb(60, 70, 100), tower = "clock" }), -- marble Academy
	look({ wall = rgb(76, 136, 96), cap = rgb(250, 240, 210), floor = rgb(236, 230, 216), tile = rgb(198, 188, 158), sign = rgb(40, 90, 60), locker = rgb(60, 110, 70), chair = rgb(150, 100, 60), door = rgb(90, 60, 40), tower = "clock" }), -- College
	look({ wall = rgb(146, 44, 44), cap = rgb(250, 250, 250), floor = rgb(232, 226, 220), tile = rgb(170, 64, 64), sign = rgb(110, 25, 30), locker = rgb(110, 30, 35), chair = rgb(60, 60, 70), door = rgb(60, 30, 25), tower = "bell" }), -- University
	look({ wall = rgb(116, 122, 104), cap = rgb(76, 146, 64), floor = rgb(226, 226, 216), tile = rgb(168, 174, 158), sign = rgb(40, 90, 40), locker = rgb(70, 90, 60), chair = rgb(110, 70, 40), door = rgb(70, 45, 30), roof = rgb(70, 80, 70), tower = "bell" }), -- Ivy League
	look({ wall = rgb(96, 64, 146), cap = rgb(240, 200, 90), floor = rgb(70, 54, 100), tile = rgb(100, 78, 140), sign = rgb(60, 30, 110), locker = rgb(60, 40, 100), chair = rgb(140, 40, 60), door = rgb(50, 30, 80), lobby = rgb(80, 64, 110), inner = rgb(120, 100, 160), board = rgb(20, 20, 40), tower = "spires" }), -- Wizard School
	look({ wall = rgb(222, 228, 238), cap = rgb(60, 220, 255), floor = rgb(46, 52, 70), tile = rgb(66, 76, 98), sign = rgb(20, 30, 60), locker = rgb(200, 210, 225), chair = rgb(60, 200, 255), door = rgb(60, 70, 90), lobby = rgb(56, 64, 84), inner = rgb(200, 210, 225), board = rgb(20, 30, 50), tower = "rocket" }), -- Space Academy
	look({ wall = rgb(30, 24, 42), cap = rgb(255, 80, 220), floor = rgb(26, 20, 36), tile = rgb(66, 36, 100), sign = rgb(12, 10, 22), locker = rgb(120, 60, 200), chair = rgb(255, 80, 220), door = rgb(80, 220, 255), lobby = rgb(36, 28, 52), inner = rgb(60, 40, 90), board = rgb(10, 10, 20), tower = "portal" }), -- Multiverse
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

---------------------------------------------------------------------------
-- School Supplies: materials that make the school smarter. Each is bought once, kept on
-- review, shows up on every desk, and adds School IQ. Tuition x (IQ / 100); IQ starts at 100.
-- tools/econ_sim.py reads these lines; keep one per line.
---------------------------------------------------------------------------
Config.Supplies = {
	{ id = "Pencils", name = "Sharpened Pencils", icon = "\u{270F}\u{FE0F}", iq = 10, tier = 1, price = 250 },
	{ id = "Notebooks", name = "Spiral Notebooks", icon = "\u{1F4D2}", iq = 10, tier = 1, price = 2e3 },
	{ id = "Crayons", name = "Giant Crayon Boxes", icon = "\u{1F58D}\u{FE0F}", iq = 10, tier = 1, price = 12e3 },
	{ id = "Textbooks", name = "Textbooks", icon = "\u{1F4DA}", iq = 10, tier = 2, price = 90e3 },
	{ id = "Rulers", name = "Rulers & Protractors", icon = "\u{1F4D0}", iq = 10, tier = 2, price = 300e3 },
	{ id = "Calculators", name = "Calculators", icon = "\u{1F9EE}", iq = 15, tier = 3, price = 21e6 },
	{ id = "Globes", name = "Desk Globes", icon = "\u{1F30D}", iq = 15, tier = 3, price = 19e6 },
	{ id = "Microscopes", name = "Microscopes", icon = "\u{1F52C}", iq = 15, tier = 4, price = 540e6 },
	{ id = "Laptops", name = "Laptops", icon = "\u{1F4BB}", iq = 20, tier = 5, price = 9.2e9 },
	{ id = "Tablets", name = "Tablets", icon = "\u{1F4F1}", iq = 20, tier = 6, price = 54e9 },
	{ id = "Smartboards", name = "Smartboards", icon = "\u{1F5A5}\u{FE0F}", iq = 25, tier = 7, price = 240e9 },
	{ id = "VRHeadsets", name = "VR Headsets", icon = "\u{1F97D}", iq = 25, tier = 8, price = 580e9 },
	{ id = "RobotTutors", name = "Robot Tutors", icon = "\u{1F916}", iq = 30, tier = 9, price = 1.2e12 },
	{ id = "HoloDesks", name = "Hologram Desks", icon = "\u{2728}", iq = 30, tier = 10, price = 2.6e12 },
	{ id = "QuantumPCs", name = "Quantum Computers", icon = "\u{269B}\u{FE0F}", iq = 40, tier = 11, price = 7.7e12 },
	{ id = "ThinkingCaps", name = "Thinking Caps", icon = "\u{1F9E2}", iq = 50, tier = 12, price = 20e12 },
}
Config.SupplyById = {}
for i, s in Config.Supplies do
	s.order = i
	Config.SupplyById[s.id] = s
end

---------------------------------------------------------------------------
-- Teachers: one per floor, standing at the chalkboard. Hiring a better one replaces the old
-- one; each floor is hired separately. mult applies to the students on that floor. Kept on review.
-- tools/econ_sim.py reads these lines; keep one per line.
---------------------------------------------------------------------------
Config.Teachers = {
	{ id = "SubSteve", name = "Substitute Steve", title = "Substitute", mult = 1.1, tier = 1, price = 600, outfit = "sub" },
	{ id = "StudentTia", name = "Student Teacher Tia", title = "Student Teacher", mult = 1.2, tier = 1, price = 6e3, outfit = "tia" },
	{ id = "MrChalk", name = "Mr. Chalk", title = "Math Teacher", mult = 1.35, tier = 2, price = 150e3, outfit = "chalk" },
	{ id = "MsHoneycutt", name = "Ms. Honeycutt", title = "English Teacher", mult = 1.5, tier = 3, price = 12e6, outfit = "honey" },
	{ id = "CoachRex", name = "Coach Rex", title = "Gym Coach", mult = 1.7, tier = 4, price = 430e6, outfit = "coach" },
	{ id = "DrBeaker", name = "Dr. Beaker", title = "Science Teacher", mult = 1.9, tier = 5, price = 3.5e9, outfit = "beaker" },
	{ id = "MadameVerse", name = "Madame Verse", title = "Poetry Teacher", mult = 2.1, tier = 6, price = 20e9, outfit = "verse" },
	{ id = "ProfTweed", name = "Professor Tweed", title = "Professor", mult = 2.4, tier = 7, price = 110e9, outfit = "tweed" },
	{ id = "DeanMaximus", name = "Dean Maximus", title = "Dean", mult = 2.7, tier = 8, price = 250e9, outfit = "dean" },
	{ id = "ArchmageQuill", name = "Archmage Quill", title = "Wizard Teacher", mult = 3.0, tier = 10, price = 1e12, outfit = "mage" },
	{ id = "CommanderNova", name = "Commander Nova", title = "Space Instructor", mult = 3.4, tier = 11, price = 3e12, outfit = "nova" },
	{ id = "Omniteacher", name = "The Omniteacher", title = "Teaches Everything", mult = 4.0, tier = 12, price = 9.3e12, outfit = "omni" },
}
Config.TeacherById = {}
for i, t in Config.Teachers do
	t.order = i
	Config.TeacherById[t.id] = t
end

---------------------------------------------------------------------------
-- School Builder: things you add to the campus. Each adds Reputation; tuition x (1 + rep/100).
-- Kept on review. A better fence replaces the one before it (replaces = id).
-- tools/econ_sim.py reads these lines; keep one per line.
---------------------------------------------------------------------------
Config.Builds = {
	{ id = "Curtains", name = "Curtains & Flower Pots", icon = "\u{1FA9F}", rep = 1, tier = 1, price = 800 },
	{ id = "FlowerBeds", name = "Flower Beds", icon = "\u{1F337}", rep = 2, tier = 1, price = 1.5e3 },
	{ id = "Awning", name = "Striped Awning & Welcome Mat", icon = "\u{26F1}\u{FE0F}", rep = 1, tier = 1, price = 2.5e3 },
	{ id = "PicketFence", name = "Picket Fence", icon = "\u{1FAB5}", rep = 2, tier = 1, price = 5e3 },
	{ id = "Marquee", name = "Marquee Letter Board", icon = "\u{1FAA7}", rep = 1, tier = 2, price = 120e3 },
	{ id = "LowBrickWall", name = "Low Brick Wall", icon = "\u{1F9F1}", rep = 2, tier = 3, price = 3e6, replaces = "PicketFence" },
	{ id = "MascotLockers", name = "Mascot Lockers", icon = "\u{1F510}", rep = 1, tier = 3, price = 4e6 },
	{ id = "Cafeteria", name = "Cafeteria Corner", icon = "\u{1F37D}\u{FE0F}", rep = 2, tier = 3, price = 7e6 },
	{ id = "ArchedWindows", name = "Arched Windows & Shutters", icon = "\u{1F3DB}\u{FE0F}", rep = 2, tier = 5, price = 3e9, replaces = "WindowBoxes" },
	{ id = "StainedGlass", name = "Stained-Glass Windows", icon = "\u{1F308}", rep = 2, tier = 8, price = 300e9, replaces = "ArchedWindows" },
	{ id = "PathLights", name = "Path Lights", icon = "\u{1F4A1}", rep = 2, tier = 2, price = 50e3 },
	{ id = "WindowBoxes", name = "Window Boxes", icon = "\u{1F33C}", rep = 2, tier = 2, price = 150e3 },
	{ id = "Playground", name = "Playground", icon = "\u{1F6DD}", rep = 4, tier = 2, price = 350e3 },
	{ id = "VendingMachines", name = "Vending Machines", icon = "\u{1F964}", rep = 3, tier = 3, price = 5.6e6 },
	{ id = "Court", name = "Basketball Court", icon = "\u{1F3C0}", rep = 5, tier = 3, price = 9e6 },
	{ id = "Garden", name = "School Garden", icon = "\u{1F955}", rep = 3, tier = 4, price = 160e6 },
	{ id = "Bleachers", name = "Bleachers", icon = "\u{1F3DF}\u{FE0F}", rep = 3, tier = 4, price = 160e6 },
	{ id = "BrickWall", name = "Brick Wall", icon = "\u{1F9F1}", rep = 3, tier = 5, price = 2.1e9, replaces = "LowBrickWall" },
	{ id = "Fountain", name = "Fountain", icon = "\u{26F2}", rep = 6, tier = 5, price = 4.2e9 },
	{ id = "Banners", name = "School Banners", icon = "\u{1F6A9}", rep = 3, tier = 6, price = 13e9 },
	{ id = "Statue", name = "Founder's Statue", icon = "\u{1F5FF}", rep = 7, tier = 7, price = 120e9 },
	{ id = "IronFence", name = "Iron Gates", icon = "\u{1F3F0}", rep = 4, tier = 8, price = 170e9, replaces = "BrickWall" },
	{ id = "SolarPanels", name = "Solar Panels", icon = "\u{2600}\u{FE0F}", rep = 5, tier = 9, price = 370e9 },
	{ id = "BellTower", name = "Bell Tower", icon = "\u{1F514}", rep = 8, tier = 10, price = 1.4e12 },
}
Config.BuildById = {}
for i, b in Config.Builds do
	b.order = i
	Config.BuildById[b.id] = b
end

---------------------------------------------------------------------------
-- the Principal's To-Do: the first-session tutorial chain, then repeating goals
-- guide: "carpet" | "pad" | "lock" | "shop:<tab>" | "panel:<name>" (what the arrow points at)
---------------------------------------------------------------------------
-- steps with a scripted moment (QuestService fires "questStep" when one starts): catch -> a cheater
-- appears, bonk -> Crumpet steals a kid, scholarship -> the Rare letter is ready, bust -> a smuggler
Config.Tutorial = {
	{ id = "enroll1", text = "Enroll a kid off the Welcome Bus", signal = "enroll", count = 1, reward = 40, guide = "carpet" },
	{ id = "enroll4", text = "Fill 3 more desks", signal = "enroll", count = 3, reward = 80, guide = "carpet" },
	{ id = "collect", text = "Walk over a glowing desk pad to collect tuition", signal = "collect", count = 1, reward = 60, guide = "pad" },
	{ id = "catch", text = "A kid is CHEATING! Catch them (hold E)", signal = "catchCheater", count = 1, reward = 100, guide = "cheater" },
	{ id = "pencils", text = "Buy Sharpened Pencils in the Shop", signal = "supply", count = 1, reward = 120, guide = "shop:1" },
	{ id = "bonk", text = "Crumpet is stealing a kid! Bonk him with your Ruler", signal = "bonkSave", count = 1, reward = 150, guide = "thief" },
	{ id = "lock", text = "Lock your laser gate (red button by the gate)", signal = "lock", count = 1, reward = 400, guide = "lock" },
	{ id = "name", text = "Give your school a name", signal = "nameSchool", count = 1, reward = 300, guide = "panel:NameSchool" },
	{ id = "scholarship", text = "Your Rare letter is here! CALL it, then enroll the kid on your bench", signal = "benchEnroll", count = 1, reward = 200, guide = "bench" },
	{ id = "hire", text = "Hire a teacher for Floor 1", signal = "hire", count = 1, reward = 250, guide = "shop:2" },
	{ id = "bust", text = "A Snack Smuggler snuck in! BUST him (hold E or bonk)", signal = "bustDealer", count = 1, reward = 500, guide = "smuggler" },
	{ id = "build", text = "Build something in the School Builder", signal = "build", count = 1, reward = 600, guide = "shop:3" },
	{ id = "upgrade", text = "Buy an upgrade", signal = "upgrade", count = 1, reward = 2500, guide = "panel:Upgrades" },
	{ id = "board", text = "Impress the School Board", signal = "review", count = 1, reward = 0, guide = "panel:Board" },
}
-- after the tutorial: goals in rotation; reward = max(min, tuition per second x secs)
Config.Goals = {
	{ text = "Enroll 10 kids", signal = "enroll", count = 10, secs = 150, min = 500 },
	{ text = "Collect tuition 20 times", signal = "collect", count = 20, secs = 120, min = 400 },
	{ text = "Steal a kid from another school", signal = "stole", count = 1, secs = 300, min = 1000, multi = true },
	{ text = "Enroll an Epic kid or better", signal = "enrollEpic", count = 1, secs = 240, min = 1500 },
	{ text = "Buy something in the Shop", signal = "shopBuy", count = 1, secs = 180, min = 800 },
	{ text = "Bonk a thief with your Ruler", signal = "bonkSave", count = 1, secs = 300, min = 1000, multi = true },
	{ text = "Lock your gate 3 times", signal = "lock", count = 3, secs = 120, min = 500 },
	{ text = "Enroll 25 kids", signal = "enroll", count = 25, secs = 300, min = 2000 },
	{ text = "Catch 2 cheaters", signal = "catchCheater", count = 2, secs = 240, min = 1000 },
	{ text = "Bust a Snack Smuggler", signal = "bustDealer", count = 1, secs = 300, min = 1500 },
}

---------------------------------------------------------------------------
-- Robux store (docs/DESIGN-v2.md section 13). Create each pass/product on the Creator Dashboard and
-- paste its id here; id = 0 shows as "SOON" in the store and can't be bought.
-- Fairness: nothing is ever prompted automatically; paid random items show their odds.
---------------------------------------------------------------------------
Config.Passes = {
	{ key = "VIP", id = 0, name = "VIP Principal", robux = 499, icon = "\u{1F451}", desc = "x2 tuition forever, VIP tag" },
	{ key = "Luck", id = 0, name = "2x Luck", robux = 349, icon = "\u{1F340}", desc = "x2 luck on the buses you stand near" },
	{ key = "AutoCollect", id = 0, name = "Auto Collect", robux = 249, icon = "\u{1F9F9}", desc = "The Janitor's Cart at max level from the start" },
	{ key = "LongLock", id = 0, name = "Long Lock", robux = 149, icon = "\u{1F510}", desc = "+30s every time you lock your gate" },
	{ key = "TeleportHome", id = 0, name = "Teleport Home", robux = 99, icon = "\u{1F3E0}", desc = "A button that takes you home (not while carrying)" },
	{ key = "OfflinePlus", id = 0, name = "Offline Tuition+", robux = 149, icon = "\u{1F319}", desc = "Earn 50% for up to 12h while offline (was 25% for 2h)" },
}
Config.Products = {
	{ key = "Cash10m", id = 0, name = "Tuition Pack", robux = 49, icon = "\u{1F4B5}", desc = "10 minutes of your tuition", seconds = 600 },
	{ key = "Cash1h", id = 0, name = "Tuition Bag", robux = 149, icon = "\u{1F4B0}", desc = "1 hour of your tuition", seconds = 3600 },
	{ key = "Cash4h", id = 0, name = "Tuition Vault", robux = 399, icon = "\u{1F3E6}", desc = "4 hours of your tuition", seconds = 14400 },
	{ key = "LuckyBus", id = 0, name = "Lucky Bus", robux = 199, icon = "\u{1F68C}", desc = "A bus for the whole server with YOUR name on it. Legendary 70% / Mythic 24% / Prodigy 5% / Secret 1%" },
	{ key = "ServerLuck", id = 0, name = "Server Luck x2", robux = 99, icon = "\u{2728}", desc = "x2 luck for everyone for 15 minutes" },
	{ key = "ExpressRare", id = 0, name = "Express Rare Letter", robux = 25, icon = "\u{2709}\u{FE0F}", desc = "Your Rare letter, ready now (you still pay the kid's price)" },
	{ key = "ExpressEpic", id = 0, name = "Express Epic Letter", robux = 79, icon = "\u{1F48C}", desc = "Your Epic letter, ready now (you still pay the kid's price)" },
	{ key = "LockRefresh", id = 0, name = "Instant Lock Refresh", robux = 25, icon = "\u{1F504}", desc = "Your gate can lock again right now" },
}

-- special buses
Config.LateBus ={ every = 300, offset = 0, count = 6, minRarity = 3 } -- Rare+, :00 :05 :10 ...
-- the Honor Roll Bus: the first student off is guaranteed Legendary or better
Config.HonorBus = { every = 900, offset = 450, count = 5, first = { Legendary = 80, Mythic = 17, Prodigy = 2.5, Secret = 0.5 }, weights = { Epic = 70, Legendary = 25, Mythic = 5 } }
Config.FieldTrip = { every = 1800, offset = 750, count = 8, weights = { Epic = 60, Legendary = 30, Mythic = 8, Prodigy = 1.8, Secret = 0.2 } }

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
	-- small fractional amounts (starter students earn $0.3/s) keep one decimal
	if math.abs(n) < 100 and math.abs(n - math.floor(n)) >= 0.05 then
		local s = string.format("%.1f", n)
		return "$" .. (s:gsub("%.0$", ""))
	end
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
