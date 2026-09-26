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
	S("GraduateGrandpa", "Graduate Grandpa", "Alumni", 60e9, 18e6, "History", "Grandpa", "light", rgb(160, 30, 40), rgb(110, 100, 90)),
	S("ClassOf99", "Class of '99", "Alumni", 90e9, 26e6, "Tech", "Class99", "tan", rgb(60, 130, 220), rgb(60, 70, 110)),
	S("HeadPrefect", "Head Prefect", "Alumni", 130e9, 36e6, "English", "Prefect", "light", rgb(30, 30, 40), rgb(30, 30, 40)),
	S("TheFounder", "The Founder", "Alumni", 190e9, 50e6, "History", "Founder", "light", rgb(150, 110, 70), rgb(150, 110, 70)),
	S("TinyPrincipal", "Principal (as a kid)", "Alumni", 280e9, 70e6, "English", "TinyPrincipal", "brown", rgb(60, 60, 70), rgb(60, 60, 70)),
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
	{ id = "Gold Medal", mult = 3, weight = 0, event = "FieldDay", color = rgb(255, 205, 60) },
	{ id = "Prom Royalty", mult = 4, weight = 0, event = "PromNight", color = rgb(255, 120, 220) },
	{ id = "Retro", mult = 3, weight = 0, event = "Throwback", color = rgb(230, 170, 90) },
	{ id = "Enchanted", mult = 5, weight = 0, event = "WizardWeek", color = rgb(170, 110, 255) },
	{ id = "Sugar Rush", mult = 3, weight = 0, event = "CandyCarnival", color = rgb(255, 110, 190) },
	{ id = "Old Money", mult = 5, weight = 0, event = "HostileTakeover", color = rgb(40, 120, 70) },
	{ id = "Graduated", mult = 6, weight = 0, event = "Graduation", color = rgb(30, 30, 40) },
	-- VexCorp's experiments (the Mutation Lab): green, glowing, bigger, and x6 tuition
	{ id = "Mutated", mult = 6, weight = 0, color = rgb(120, 255, 60), mutant = true },
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
	{ name = "Middle School", cash = 67e6, needs = "BandGeek", mult = 2, floors = 2, lock = 75 },
	{ name = "High School", cash = 1.8e9, needs = "Quarterback", mult = 3, floors = 2, lock = 80 },
	{ name = "Prep School", cash = 100e9, needs = "Valedictorian", mult = 4.5, floors = 3, lock = 85 },
	{ name = "Private Academy", cash = 1.2e12, needs = "PromKing", mult = 6.5, floors = 3, lock = 90 },
	{ name = "Community College", cash = 100e12, needs = "KidGenius", mult = 9, floors = 3, lock = 95 },
	{ name = "State University", cash = 190e12, needs = "NewKid", mult = 13, floors = 3, lock = 100 },
	{ name = "Ivy League", cash = 600e12, needs = "TinyProfessor", mult = 18, floors = 3, lock = 105 },
	{ name = "Wizard School", cash = 6.6e15, needs = "PopStarKid", mult = 25, floors = 3, lock = 110 },
	{ name = "Space Academy", cash = 17e15, needs = "ChildCEO", mult = 35, floors = 3, lock = 115 },
	{ name = "Multiverse University", cash = 120e15, needs = "Secret", mult = 50, floors = 3, lock = 120 },
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
-- the story beat inside each Board review, before APPROVED: { speaker, portrait template id, line }
Config.BoardBeats = {
	[2] = { { "KEVIN, AGE 10", "Kevin", "Can we get a waterslide?" }, { "THE WHOLE BOARD", "DeanMaximus", "No." } },
	[3] = { { "KEVIN, AGE 10", "Kevin", "Okay, but a SMALL waterslide?" }, { "THE BOARD CHAIR", "DeanMaximus", "No." } },
	[4] = { { "???", "Baron", "Pssst... nice school. Shame if it had... SNACKS." } },
	[5] = { { "DR. VERONICA VEX", "Vex", "A fruit basket for the Board. No reason." }, { "KEVIN, AGE 10", "Kevin", "(mouth full) ...I vote yes." } },
	[6] = { { "DR. VERONICA VEX", "Vex", "MARBLE?! Fine. My Homework Factory goes RIGHT ACROSS THE STREET." } },
	[7] = { { "DR. VERONICA VEX", "Vex", "Homework Machine: twelve percent complete. Tick tock, Principal." } },
	[8] = { { "JANITOR STAN", "Stan", "That statue on your lawn... it blinked. I'm not joking." } },
	[9] = { { "KEVIN, AGE 10", "Kevin", "Fine, I'm the Sugar Baron! I just wanted a WATERSLIDE!" }, { "THE BOARD CHAIR", "DeanMaximus", "Detention." } },
	[10] = { { "MR. WOBBLESWORTH", "Wobblesworth", "I dropped out of wizard school, you know. Couldn't pronounce the spells." } },
	[11] = { { "OTIS", "Otis", "(looking at the stars) ...Home." } },
	[12] = { { "THE WHOLE BOARD", "DeanMaximus", "Motion... APPROVED... in EVERY universe." } },
}
-- Graduation Day: the finale, once, after the first promotion to Multiverse University
Config.FinaleLines = {
	{ "OTIS", "Otis", "Forty years I've been drivin' kids from every universe to this street, lookin' for a school big enough for all of 'em." },
	{ "OTIS", "Otis", "Took you long enough, Principal." },
	{ "DR. VERONICA VEX", "Vex", "If I can't have the multiverse, NOBODY gets recess! Homework Machine: FIRE!" },
	{ "JANITOR STAN", "Stan", "Told you that statue blinked. Look at it swing that ruler!" },
	{ "MR. WOBBLESWORTH", "Wobblesworth", "Oh my. The beam bounced right back. Veronica is... ten?" },
	{ "TINY VEX", "HomeworkReminder", "...Can I still enroll?" },
	{ "KEVIN, AGE 10", "Kevin", "Can SHE get a waterslide?" },
	{ "THE WHOLE BOARD", "DeanMaximus", "NO." },
	{ "MR. WOBBLESWORTH", "Wobblesworth", "Splendid, Principal. Simply splendid." },
	{ "OTIS", "Otis", "Doors closin'!" },
}
-- the Board Chair's welcome for a brand-new principal (the intro cutscene, and page 1 of the Scrapbook)
Config.IntroLines = {
	"Welcome, Principal! Your school has... zero students. ZERO.",
	"Kids step off the bus onto the red carpet. Grab them before the other schools do!",
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
-- The first session: nine steps, action from minute two. Scripted moments start on questStep:
-- bonk -> Crumpet raids your school (RaidService.tutorialRaid), rescue -> Skater Kid is waiting
-- in a VexCorp Factory pen and the guards go easy on you (FactoryService).
---------------------------------------------------------------------------
Config.Tutorial = {
	{ id = "enroll1", text = "Enroll a kid off the Welcome Bus (walk up and press E)", signal = "enroll", count = 1, reward = 40, guide = "carpet" },
	{ id = "collect", text = "Walk over the glowing pad to collect tuition", signal = "collect", count = 1, reward = 60, guide = "pad" },
	{ id = "enroll4", text = "Fill 3 more desks", signal = "enroll", count = 3, reward = 80, guide = "carpet" },
	{ id = "bonk", text = "Crumpet grabbed a kid! Chase him and click to bonk him with your Ruler", signal = "bonkSave", count = 1, reward = 150, guide = "thief" },
	{ id = "lock", text = "Vex will send more goons. Lock your gate (the red button) to keep them out", signal = "lock", count = 1, reward = 200, guide = "lock" },
	{ id = "rescue", text = "Vex snatched Skater Kid on your first morning! Sneak into the VexCorp Factory and bring him home", signal = "rescued", count = 1, reward = 300, guide = "factory" },
	{ id = "pencils", text = "Buy Sharpened Pencils in the Shop (smarter kids earn more)", signal = "supply", count = 1, reward = 120, guide = "shop:1" },
	{ id = "hire", text = "Hire a teacher for Floor 1", signal = "hire", count = 1, reward = 250, guide = "shop:2" },
	{ id = "board", text = "Impress the School Board: become an Elementary School", signal = "review", count = 1, reward = 0, guide = "panel:Board" },
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
	{ text = "Answer 2 Pop Quizzes right", signal = "quizRight", count = 2, secs = 240, min = 1000 },
}

---------------------------------------------------------------------------
-- Principal's Requests: the story spine after the First Day tutorial (which ends at the first Board
-- review). One chapter per tier from Elementary on. Each has 4 requests (any order) and then "Face the
-- Board"; each request pays 1 % of the next tier's cash (the tiers from Middle School up cost 5 % more
-- to pay for it; tools/econ_sim.py models both) plus candy, and a finished chapter fills a letter.
-- Kinds: supply/hire/build (own that item), iq (reach IQ n), own (n kids of that rarity or better
-- at once), builds (n Builder items), count (signal fired n times, optionally with a matching arg).
-- Every request can be done alone, so the chain never stalls on a solo server.
---------------------------------------------------------------------------
Config.Chapters = {
	{ title = "The New Building", host = "Wobblesworth", letter = "Rare",
		line = "Elementary! Real classrooms, Principal. Let's fill them properly.",
		steps = {
			{ kind = "hire", id = "MrChalk" },
			{ kind = "build", id = "Playground" },
			{ kind = "iq", n = 150 },
			{ kind = "mission", id = "crumpets_crew" },
		} },
	{ title = "Lockers and Lies", host = "Janitor Stan", letter = "Rare",
		line = "Middle schoolers. They cheat, they sneak candy, they lose their shoes. Stay sharp.",
		steps = {
			{ kind = "build", id = "MascotLockers" },
			{ kind = "hire", id = "MsHoneycutt" },
			{ kind = "mission", id = "sugar_run" },
			{ kind = "count", signal = "eagleEye", count = 1, text = "Make an EAGLE EYE catch" },
		} },
	{ title = "Friday Night Lights", host = "Hall Monitor Hector", letter = "Epic",
		line = "High school means a stadium, a coach, and a trophy case worth guarding.",
		steps = {
			{ kind = "build", id = "Bleachers" },
			{ kind = "hire", id = "CoachRex" },
			{ kind = "mission", id = "free_the_mascot" },
			{ kind = "own", rarity = "Legendary", n = 1 },
		} },
	{ title = "Blazers Required", host = "Wobblesworth", letter = "Epic",
		line = "Prep school parents inspect the windows. Personally. With a magnifying glass.",
		steps = {
			{ kind = "build", id = "ArchedWindows" },
			{ kind = "hire", id = "DrBeaker" },
			{ kind = "supply", id = "Laptops" },
			{ kind = "mission", id = "surprise_inspection" },
		} },
	{ title = "Vex Makes an Offer", host = "Dr. Veronica Vex", letter = "Legendary",
		line = "A fountain? How quaint. I'll be draining it when I buy this place.",
		steps = {
			{ kind = "build", id = "Fountain" },
			{ kind = "hire", id = "MadameVerse" },
			{ kind = "mission", id = "vex_blueprints" },
			{ kind = "count", signal = "rivalEscaped", count = 1, text = "Steal a kid from VEX PREP (across the street)" },
		} },
	{ title = "Campus Life", host = "Lunch Lady Loretta", letter = "Legendary",
		line = "College kids eat four lunches a day. I've done the math. Please help.",
		steps = {
			{ kind = "build", id = "Statue" },
			{ kind = "hire", id = "ProfTweed" },
			{ kind = "supply", id = "Smartboards" },
			{ kind = "mission", id = "recipe_chase" },
		} },
	{ title = "Iron and Glass", host = "Janitor Stan", letter = "Legendary",
		line = "University. The statue blinked at me last night. I'm not joking.",
		steps = {
			{ kind = "build", id = "StainedGlass" },
			{ kind = "mission", id = "night_raid" },
			{ kind = "hire", id = "DeanMaximus" },
			{ kind = "supply", id = "VRHeadsets" },
		} },
	{ title = "Old Money", host = "Wobblesworth", letter = "Mythic",
		line = "The Ivy League runs on reputation. And on catching every last cheater.",
		steps = {
			{ kind = "build", id = "SolarPanels" },
			{ kind = "supply", id = "RobotTutors" },
			{ kind = "mission", id = "unmask_baron" },
			{ kind = "own", rarity = "Mythic", n = 3 },
		} },
	{ title = "The Bell Tolls", host = "Archmage Quill", letter = "Mythic",
		line = "A school of wizards needs a bell tower. Tradition. Also, the owls insist.",
		steps = {
			{ kind = "build", id = "BellTower" },
			{ kind = "hire", id = "ArchmageQuill" },
			{ kind = "mission", id = "the_vault" },
			{ kind = "own", rarity = "Prodigy", n = 1 },
		} },
	{ title = "Countdown", host = "Otis", letter = "Prodigy",
		line = "Space Academy. I drove a bus to the moon once. Long story. Buckle up.",
		steps = {
			{ kind = "hire", id = "CommanderNova" },
			{ kind = "supply", id = "QuantumPCs" },
			{ kind = "mission", id = "machine_wakes" },
			{ kind = "own", rarity = "Prodigy", n = 2 },
		} },
	{ title = "Every School at Once", host = "Everyone", letter = "Prodigy",
		line = "The Multiverse. Every school you ever ran, all at the same time. Make it count.",
		steps = {
			{ kind = "hire", id = "Omniteacher" },
			{ kind = "supply", id = "ThinkingCaps" },
			{ kind = "mission", id = "final_stand" },
			{ kind = "own", rarity = "Secret", n = 1 },
		} },
}
-- Missions (MissionService): the playable story, one per chapter. Mr. Wobblesworth at the Hub fountain
-- hands them out ("!" over his head when you have one); talk to him to hear it and start.
--   defend: a VexCorp crew raids your school; knock them all out before any gets away with a kid
--   chase:  someone runs off down Recess Row; bonk them hp times before they reach the end
--   heist:  a story kid (kid) or Vex's blueprints (item) sit in the VexCorp Factory; get them out
-- lines: { speaker, portrait template id, text }
Config.Missions = {
	crumpets_crew = { title = "Crumpet's Crew", kind = "defend", goons = 3, hp = 1,
		lines = {
			{ "MR. WOBBLESWORTH", "Wobblesworth", "Principal! Vex has hired a whole crew of goons, and they're on their way to your school!" },
			{ "MR. WOBBLESWORTH", "Wobblesworth", "Get back there and knock out all three. Don't let a single one get away with a child!" },
		},
		objective = "Knock out all 3 goons at your school",
		win = "Three goons down! Back in MY day we had ONE goon, and we SHARED him!" },
	sugar_run = { title = "The Sugar Run", kind = "chase", runner = "courier", hp = 3, route = "factory_to_shack",
		lines = {
			{ "JANITOR STAN", "Stan", "Psst. See the courier sneaking out of VexCorp? That sack is full of smuggled candy." },
			{ "JANITOR STAN", "Stan", "He's making for the Sugar Shack. Catch him and bonk him three times before he gets there." },
		},
		objective = "Bonk the candy courier 3 times before he reaches the Sugar Shack",
		win = "Candy everywhere. I'll get the big broom." },
	free_the_mascot = { title = "Free the Mascot", kind = "heist", kid = "SchoolMascot",
		lines = {
			{ "MR. WOBBLESWORTH", "Wobblesworth", "Dreadful news! Vex has kidnapped the School Mascot for a VexCorp commercial!" },
			{ "MR. WOBBLESWORTH", "Wobblesworth", "Sneak into the Factory and bring the Mascot out. The guards are awake this time, mind!" },
		},
		objective = "Get the School Mascot out of the VexCorp Factory",
		win = "The Mascot is free, and wants to join YOUR school!" },
	surprise_inspection = { title = "Surprise Inspection", kind = "defend", goons = 4, hp = 2,
		lines = {
			{ "THE BOARD CHAIR", "DeanMaximus", "Principal, the Board has learned Vex is sending 'inspectors'. They are goons in clipboards." },
			{ "THE BOARD CHAIR", "DeanMaximus", "Four of them, and tougher than before. Knock them all out. The Board is watching." },
		},
		objective = "Knock out all 4 inspectors at your school",
		win = "Motion to keep your school... APPROVED!" },
	vex_blueprints = { title = "Vex's Blueprints", kind = "heist", item = "Blueprints",
		lines = {
			{ "MR. WOBBLESWORTH", "Wobblesworth", "Vex left her plans on her desk, at the back of the Factory. The plans for the HOMEWORK MACHINE!" },
			{ "MR. WOBBLESWORTH", "Wobblesworth", "Steal them and bring them out. Whatever she's building, we need to know." },
		},
		objective = "Steal the blueprints from Vex's desk and get out of the Factory",
		win = "A machine that makes homework... forever? Oh dear. Oh dear, oh dear." },
	recipe_chase = { title = "The Secret Recipe", kind = "chase", runner = "crumpet", hp = 4, route = "hub_to_bus",
		lines = {
			{ "LUNCH LADY LORETTA", "Loretta", "That BUTLER just swiped my secret mystery meat recipe! Forty years in the making!" },
			{ "LUNCH LADY LORETTA", "Loretta", "He's running for the bus stop. Bonk him four times, sweetie, and bring it back!" },
		},
		objective = "Bonk Crumpet 4 times before he reaches the bus stop",
		win = "My recipe! Eat your veggies, sweetie. And your mystery meat." },
	night_raid = { title = "Night Raid", kind = "defend", goons = 5, hp = 2,
		lines = {
			{ "JANITOR STAN", "Stan", "I've seen things under those bleachers, kid. Tonight I saw five goons in a van." },
			{ "JANITOR STAN", "Stan", "They're coming for your school. Knock out every last one." },
		},
		objective = "Knock out all 5 goons at your school",
		win = "Five goons. Not bad, kid. Not bad at all." },
	unmask_baron = { title = "Unmask the Sugar Baron", kind = "chase", runner = "baron", hp = 6, route = "shack_to_hub",
		lines = {
			{ "JANITOR STAN", "Stan", "The Sugar Baron himself just jumped off the Sugar Shack roof. He's running!" },
			{ "JANITOR STAN", "Stan", "Bonk him six times and we'll finally see who's under that cake hat." },
		},
		objective = "Bonk the Sugar Baron 6 times before he gets away",
		win = "It's KEVIN?! 'I just wanted a WATERSLIDE!'" },
	the_vault = { title = "The Vault", kind = "heist", kid = "TinyProfessor",
		lines = {
			{ "MR. WOBBLESWORTH", "Wobblesworth", "Vex has locked the Tiny Professor in her Factory. She wants his brain for the Homework Machine!" },
			{ "MR. WOBBLESWORTH", "Wobblesworth", "Get him out, Principal. Quickly now!" },
		},
		objective = "Get the Tiny Professor out of the VexCorp Factory",
		win = "The Professor is safe, and he'd like a desk at your school." },
	machine_wakes = { title = "The Machine Wakes", kind = "defend", goons = 6, hp = 3,
		lines = {
			{ "OTIS", "Otis", "Forty years driving this street. Never seen a van that big. Six goons, and they look mean." },
			{ "OTIS", "Otis", "Knock 'em all out, Principal. Doors closin'." },
		},
		objective = "Knock out all 6 goons at your school",
		win = "Next stop: wherever. Good work." },
	final_stand = { title = "The Final Stand", kind = "defend", goons = 8, hp = 3,
		lines = {
			{ "DR. VERONICA VEX", "Vex", "Tick tock, Principal. Eight of my finest are on their way to your little school." },
			{ "DR. VERONICA VEX", "Vex", "When they're done, the Multiverse is MINE. Recess is cancelled. Forever." },
		},
		objective = "Knock out all 8 of Vex's finest at your school",
		win = "No... NO! This isn't over, Principal!" },
}
-- the chase routes (world waypoints, ground level)
Config.ChaseRoutes = {
	factory_to_shack = { Vector3.new(0, 0, 30), Vector3.new(20, 0, 24), Vector3.new(80, 0, 22), Vector3.new(140, 0, 22), Vector3.new(190, 0, 26), Vector3.new(190, 0, 52) },
	hub_to_bus = { Vector3.new(-14, 0, -64), Vector3.new(-14, 0, -40), Vector3.new(-40, 0, -17), Vector3.new(-100, 0, -17), Vector3.new(-170, 0, -17), Vector3.new(-240, 0, -17), Vector3.new(-318, 0, -17) },
	shack_to_hub = { Vector3.new(190, 0, 60), Vector3.new(190, 0, 26), Vector3.new(150, 0, 17), Vector3.new(100, 0, -17), Vector3.new(40, 0, -17), Vector3.new(0, 0, -44), Vector3.new(-40, 0, -17), Vector3.new(-110, 0, 17), Vector3.new(-160, 0, 17), Vector3.new(-176, 0, 40) },
}
-- speed vs your 16: you close 2-3 studs a second, so keep swinging and you catch him; each hit makes him
-- dash away for dashTime seconds (and he can't be hit again for 1.6 s)
Config.ChaseRunners = {
	courier = { id = "VexGoon", name = "Candy Courier", title = "VexCorp", mult = 1, outfit = "goon", speed = 13, dash = 19, dashTime = 0.8 },
	crumpet = { id = "Crumpet", name = "Crumpet", title = "Butler", mult = 1, outfit = "butler", speed = 13.5, dash = 19.5, dashTime = 0.8 },
	baron = { id = "Baron", name = "The Sugar Baron", title = "???", mult = 1, outfit = "baron", speed = 14, dash = 20, dashTime = 0.9 },
}
Config.MissionRewardMult = 3 -- a mission step pays this many times a normal chapter request

-- chapter i is played at tier i + 1
Config.ChapterTier = function(i) return i + 1 end
Config.ChapterPct = 0.01
Config.ChapterCandy = { 10, 10, 20, 20 }

---------------------------------------------------------------------------
-- Daily Requests: 3 a day (UTC) from this pool, the same 3 for a player all day; one free reroll.
-- Each pays candy; all 3 open Loretta's Lunch Box. No cash rewards, so the 100-hour pacing
-- (tools/econ_sim.py) is untouched. Every request can be done alone at any tier.
-- signal = a Signals name; rarity = only enrolls of that rarity or rarer count.
---------------------------------------------------------------------------
Config.DailyPool = {
	{ id = "catch8", text = "Catch 8 cheaters", signal = "catchCheater", count = 8 },
	{ id = "catch15", text = "Catch 15 cheaters", signal = "catchCheater", count = 15 },
	{ id = "bust3", text = "Bust 3 Snack Smugglers", signal = "bustDealer", count = 3 },
	{ id = "bust6", text = "Bust 6 Snack Smugglers", signal = "bustDealer", count = 6 },
	{ id = "enroll20", text = "Enroll 20 kids", signal = "enroll", count = 20 },
	{ id = "enroll50", text = "Enroll 50 kids", signal = "enroll", count = 50 },
	{ id = "rare3", text = "Enroll 3 Rare kids (or rarer)", signal = "enroll", rarity = "Rare", count = 3 },
	{ id = "epic1", text = "Enroll an Epic kid (or rarer)", signal = "enroll", rarity = "Epic", count = 1 },
	{ id = "quiz3", text = "Answer 3 Pop Quizzes right", signal = "quizRight", count = 3 },
	{ id = "collect30", text = "Collect tuition 30 times", signal = "collect", count = 30 },
	{ id = "letter1", text = "Enroll a kid from an Admissions Letter", signal = "benchEnroll", group = "enroll", count = 1 },
	{ id = "lock5", text = "Lock your gate 5 times", signal = "lock", count = 5 },
	-- group: requests credited by the same action (a bus kid is also an enroll) are never dealt together
	{ id = "bus2", text = "Enroll 2 kids off special buses", signal = "busEnroll", group = "enroll", count = 2 },
	{ id = "eagle2", text = "Make 2 EAGLE EYE catches", signal = "eagleEye", group = "catchCheater", count = 2 },
	{ id = "grad3", text = "Graduate 3 kids (hold G at a desk)", signal = "graduate", count = 3 },
}
Config.DailyCandy = 25
-- Weekly Requests: 3 a week (weeks start Monday 00:00 UTC), bigger counts, 100 candy each; all 3 open
-- the Weekly Chest (a Legendary letter and 30 Event Tickets). No cash rewards.
Config.WeeklyPool = {
	{ id = "wcatch60", text = "Catch 60 cheaters", signal = "catchCheater", count = 60 },
	{ id = "wbust25", text = "Bust 25 Snack Smugglers", signal = "bustDealer", count = 25 },
	{ id = "wenroll300", text = "Enroll 300 kids", signal = "enroll", count = 300 },
	{ id = "wcollect300", text = "Collect tuition 300 times", signal = "collect", count = 300 },
	{ id = "wquiz15", text = "Answer 15 Pop Quizzes right", signal = "quizRight", count = 15 },
	{ id = "wgrad25", text = "Graduate 25 kids", signal = "graduate", count = 25 },
	{ id = "wtokens80", text = "Collect 80 event tokens", signal = "ticket", count = 80 },
	{ id = "wletter10", text = "Enroll 10 kids from Admissions Letters", signal = "benchEnroll", group = "enroll", count = 10 },
	{ id = "weagle10", text = "Make 10 EAGLE EYE catches", signal = "eagleEye", group = "catchCheater", count = 10 },
}
Config.WeeklyCandy = 100
Config.WeeklyChestTickets = 30
-- Loretta's Lunch Box, opened when all 3 are done. Odds are shown in the panel.
Config.LunchBox = {
	{ id = "candy", weight = 40, text = "80 Candy" },
	{ id = "Rare", weight = 30, text = "Rare Letter, ready now" },
	{ id = "Epic", weight = 18, text = "Epic Letter, ready now" },
	{ id = "Legendary", weight = 9, text = "Legendary Letter, ready now" },
	{ id = "Mythic", weight = 3, text = "Mythic Letter, ready now" },
}

---------------------------------------------------------------------------
-- Event Tickets: during an event, event tokens pop up around every player; each one is a ticket.
-- Tickets buy letters and candy any time, and each event's trophy only while that event runs
-- (12 trophies fill the trophy case on your lawn). tools/econ_sim.py models the letters.
---------------------------------------------------------------------------
Config.EventInfo = {
	SnowDay = { name = "Snow Day", icon = "\u{2744}\u{FE0F}" },
	FieldDay = { name = "Field Day", icon = "\u{1F3C5}" },
	ScienceFair = { name = "Science Fair", icon = "\u{1F9EA}" },
	PromNight = { name = "Prom Night", icon = "\u{1F483}" },
	PictureDay = { name = "Picture Day", icon = "\u{1F4F8}" },
	Throwback = { name = "Throwback Week", icon = "\u{1F4FC}" },
	Halloween = { name = "Halloween", icon = "\u{1F383}" },
	WizardWeek = { name = "Wizard Week", icon = "\u{2728}" },
	CandyCarnival = { name = "Candy Carnival", icon = "\u{1F36D}" },
	SpaceCamp = { name = "Space Camp", icon = "\u{1F680}" },
	HostileTakeover = { name = "Hostile Takeover", icon = "\u{1F4BC}" },
	Graduation = { name = "Graduation", icon = "\u{1F393}" },
}
Config.EventShop = {
	{ id = "LetterRare", name = "Rare Letter, ready now", icon = "\u{1F4E8}", tickets = 15, kind = "letter", rarity = "Rare" },
	{ id = "LetterEpic", name = "Epic Letter, ready now", icon = "\u{1F4E8}", tickets = 40, kind = "letter", rarity = "Epic" },
	{ id = "LetterLegendary", name = "Legendary Letter, ready now", icon = "\u{1F4E8}", tickets = 120, kind = "letter", rarity = "Legendary" },
	{ id = "Candy50", name = "50 Candy", icon = "\u{1F36C}", tickets = 10, kind = "candy", amount = 50 },
}
Config.TrophyTickets = 40
Config.TicketsPerToken = 1

---------------------------------------------------------------------------
-- Graduation: graduate a seated kid (hold G) and it leaves your school for Diplomas (by rarity,
-- x its grade). Diplomas buy Alumni letters in the Yearbook: an Alumni kid on your bench that you
-- still pay for. The Board review clears your desks, so graduating first is never wasted.
---------------------------------------------------------------------------
Config.Diplomas = { Common = 1, Uncommon = 3, Rare = 8, Epic = 20, Legendary = 50, Mythic = 150, Prodigy = 500, Secret = 2000 }
-- the Alumni Hall opens at Ivy League: Alumni kids out-earn whole schools earlier than that
Config.AlumniTier = 9
Config.AlumniShop = {
	{ id = "GraduateGrandpa", diplomas = 100000 },
	{ id = "ClassOf99", diplomas = 200000 },
	{ id = "HeadPrefect", diplomas = 400000 },
	{ id = "TheFounder", diplomas = 800000 },
	{ id = "TinyPrincipal", diplomas = 1600000 },
}

---------------------------------------------------------------------------
-- VexCorp raids (RaidService): the van pulls up, goons run in, grab kids and run for it.
-- Speeds are studs/second (players walk at 16): a goon outruns you going in, you outrun a goon
-- carrying a kid. Rewards are seconds of base tuition with a floor; the real prize is keeping the kid.
---------------------------------------------------------------------------
Config.Raids = {
	first = 150, -- after the tutorial
	every = { 180, 300 },
	minKids = 3,
	goonsByTier = { 1, 1, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3 },
	hpByTier = { 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3 },
	runSpeed = 17,
	carrySpeed = 11,
	fleeSpeed = 20,
	tutorialCarrySpeed = 7,
	stun = 1.4,
	hitRange = 9,
	lockWait = 15,
	saveSecs = 10, saveFloor = 60,
	koSecs = 5, koFloor = 30,
	defendSecs = 15, defendFloor = 120,
}

---------------------------------------------------------------------------
-- The VexCorp Factory heist (FactoryService). Speeds in studs/second; players walk at 16.
-- Empty-handed you outrun a guard (15); carrying a kid you're at 12 and they chase at 14, so you
-- need your Ruler (a bonk stuns a guard for guardStun seconds). Vex's prize captives are a mystery
-- kid rolled from the band for your tier when you get them out.
---------------------------------------------------------------------------
Config.Heist = {
	guards = 3,
	patrolSpeed = 7,
	chaseSpeed = 15,
	chaseSpeedCarry = 13.5,
	alerted = 2, -- guards who come running when you grab something (the rest join if they see you)
	carrySpeed = 12,
	sightRange = 26,
	sightAngle = 100,
	hearRange = 5,
	loseAfter = 3,
	catchRange = 3.2,
	tutorialChase = 10, -- the one guard who chases a first-timer (you carry at 12)
	reaction = 0.7, -- seconds a guard stands and stares ("!") before he runs
	caughtStun = 1.5,
	guardStun = 3,
	holdTime = 1.2,
	prizeRestock = 300,
	prizeByTier = {
		{ "Uncommon", "Rare" },
		{ "Rare", "Rare", "Epic" },
		{ "Rare", "Epic" },
		{ "Epic", "Epic", "Legendary" },
		{ "Epic", "Legendary" },
		{ "Legendary", "Legendary", "Mythic" },
		{ "Legendary", "Mythic" },
		{ "Legendary", "Mythic" },
		{ "Mythic", "Mythic", "Prodigy" },
		{ "Mythic", "Prodigy" },
		{ "Mythic", "Prodigy" },
		{ "Prodigy", "Prodigy", "Secret" },
	},
}

---------------------------------------------------------------------------
-- Janitor Stan's Confiscation Closet: what Confiscated Candy buys. Decor adds no Reputation (no income
-- effect); traps protect your school. Candy is never sold for Robux.
---------------------------------------------------------------------------
Config.CandyShop = {
	{ id = "JawbreakerTrap", name = "Jawbreaker Trap (3 uses)", icon = "\u{1F36C}", candy = 60, kind = "trap", desc = "A thief running out of your gate with your kid trips and drops them" },
	{ id = "LollipopLamps", name = "Lollipop Lamp Posts", icon = "\u{1F36D}", candy = 150, kind = "decor", desc = "Giant swirly lollipops light your front walk" },
	{ id = "GumballMachine", name = "Gumball Machine", icon = "\u{1F534}", candy = 300, kind = "decor", desc = "A huge gumball machine by the gate" },
	{ id = "CottonCandyTree", name = "Cotton Candy Tree", icon = "\u{1F338}", candy = 800, kind = "decor", desc = "A fluffy pink tree on your lawn" },
	{ id = "SlimeFountain", name = "Slime Fountain", icon = "\u{1F7E2}", candy = 1200, kind = "decor", desc = "A bubbling fountain of glowing slime" },
}
Config.CandyById = {}
for i, c in Config.CandyShop do
	c.order = i
	Config.CandyById[c.id] = c
end

---------------------------------------------------------------------------
-- Heist Gear (GearService): Janitor Stan sells it out of the back of his Closet, for cash. Prices are
-- "secs" seconds of your school's tuition (so they keep up with your school), never under "floor".
--   kind "perk"   kept forever, works on its own
--   kind "tool"   kept forever, a tool in your backpack
--   kind "use"    one use each, a tool in your backpack showing how many are left
---------------------------------------------------------------------------
Config.Gear = {
	{ id = "CardboardBox", name = "Cardboard Box", icon = "\u{1F4E6}", kind = "tool", secs = 240, floor = 300,
		desc = "Equip it and stand still: guards walk right past. Move slowly and they might not notice..." },
	{ id = "SmokeBomb", name = "Smoke Bomb", icon = "\u{1F4A8}", kind = "use", secs = 45, floor = 120,
		desc = "Poof! Guards nearby lose you and cough for 3 seconds" },
	{ id = "WhoopeeCushion", name = "Whoopee Cushion", icon = "\u{1F4A9}", kind = "use", secs = 30, floor = 80,
		desc = "Drop it and walk away: in 2 seconds it goes off and guards run over to check" },
	{ id = "EnergyDrink", name = "Energy Drink", icon = "\u{26A1}", kind = "use", secs = 30, floor = 90,
		desc = "20 seconds of sprinting that never runs out, a little faster too" },
	{ id = "SilentSneakers", name = "Silent Sneakers", icon = "\u{1F45F}", kind = "perk", secs = 480, floor = 600,
		desc = "Sneak 35% faster" },
	{ id = "RunningShoes", name = "Running Shoes", icon = "\u{1F3BD}", kind = "perk", secs = 420, floor = 500,
		desc = "50% more stamina, and it comes back faster" },
	{ id = "LockpickSet", name = "Lockpick Set", icon = "\u{1F511}", kind = "perk", secs = 600, floor = 800,
		desc = "Grab kids out of pens and desks twice as fast" },
}
Config.GearById = {}
for i, g in Config.Gear do
	g.order = i
	Config.GearById[g.id] = g
end
Config.GearUse = { max = 9 } -- the most of one kind of "use" gear you can carry

-- the VexCorp Mutation Lab (LabService): break a mutant out of its tube and get it off the grounds
Config.Lab = {
	holdTime = 2.5, -- seconds to break a tube open (the Lockpick Set halves it)
	restock = 600, -- seconds a broken tube stays empty
	cameraRange = 44,
	cameraHalfAngle = 17,
	-- the mutant you get, by your school's tier (then Mutated: x6 tuition)
	mutantByTier = {
		{ "Uncommon", "Rare", "Rare" },
		{ "Rare", "Rare", "Epic" },
		{ "Rare", "Epic" },
		{ "Epic", "Epic", "Legendary" },
		{ "Epic", "Legendary" },
		{ "Legendary", "Legendary", "Mythic" },
		{ "Legendary", "Mythic" },
		{ "Mythic", "Mythic", "Prodigy" },
		{ "Mythic", "Prodigy" },
		{ "Prodigy", "Prodigy", "Secret" },
		{ "Prodigy", "Secret" },
		{ "Secret" },
	},
}
-- The VexCorp Files (FilesService): sixteen documents hidden around Recess Row that tell how
-- Veronica Vex went from Mr. Wobblesworth's star pupil to the villain across the street. The easy
-- ones lie about town; the best ones are inside the Factory, the Lab and Vex Prep.
-- pos: world position of the folder; by: who wrote it (the paper's letterhead)
Config.Files = {
	{ id = "Diary1", title = "Wobblesworth's Diary, Day 1", by = "Mr. Wobblesworth", pos = Vector3.new(14, 1.6, -76),
		text = "Opened Recess Row Elementary today! Forty desks, one slide, a fountain that mostly works.\n\nMy star pupil, a little girl named Veronica, asked if recess could be \"optimized\". Odd child. Brilliant, but odd." },
	{ id = "ReportCard", title = "Report Card: V. Vex, Grade 5", by = "Recess Row Elementary", pos = Vector3.new(-205, 1.6, 72),
		text = "HOMEWORK: A++ (did everyone's)\nMATH: A++\nRECESS: F (refused to go outside)\n\nTeacher's comment: \"Veronica replaced the playground with a study hall while I was at lunch. Please speak to her.\"" },
	{ id = "Expelled", title = "A Letter to Veronica", by = "Principal Wobblesworth", pos = Vector3.new(-192, 1.8, -66),
		text = "Veronica,\n\nYou may NOT dig a moat around the library.\nYou may NOT cancel recess for the whole school.\nYou may NOT keep alligators in the moat.\n\nI'm sorry, but you are expelled.\n\n- Mr. W.\nP.S. The alligators must go." },
	{ id = "Founding", title = "VexCorp: Day One", by = "Dr. Veronica Vex", pos = Vector3.new(-312, 1.6, -24),
		text = "Today I founded VexCorp.\n\nOur mission: a world where recess is cancelled and homework never, ever ends.\n\nOur motto: HOMEWORK IS THE FUTURE.\n\nEmployees: me. And a butler named Crumpet, who came with the house." },
	{ id = "Crumpet", title = "Crumpet's Contract", by = "VexCorp Human Resources", pos = Vector3.new(196, 1.6, -72),
		text = "BUTLER DUTIES: tea, polishing, driving the van, light kidnapping.\nPAY: one (1) crumpet per day.\nHOLIDAYS: none.\n\nSigned with a very small, very sad \"C\"." },
	{ id = "Blueprint", title = "Factory Plans, Page 1", by = "Dr. Veronica Vex", pos = Vector3.new(-24, 1.6, 44),
		text = "Build the Homework Factory RIGHT ACROSS THE STREET from that old school.\n\nI want Wobblesworth to watch every truckload of homework roll out his window.\n\nPaint it purple. He hates purple." },
	{ id = "Goons", title = "The Goon Handbook, Rule 1", by = "VexCorp Security", pos = Vector3.new(24, 1.6, 64),
		text = "RULE 1: If bonked with a ruler, drop the child and run.\nRULE 2: Do not cry in the van.\nRULE 3: The butler is in charge. Yes, really.\nRULE 4: Never, ever go near the Waiting Bench." },
	{ id = "Baron", title = "An Invoice", by = "The Sugar Baron (NOT Kevin)", pos = Vector3.new(172, 1.6, 58),
		text = "For: one month of candy smuggling into Recess Row schools.\n\nPayment due: one (1) waterslide, to be built when VexCorp takes over.\n\n- The Sugar Baron\n(this is NOT Kevin. Kevin is ten.)" },
	{ id = "LabLog1", title = "Lab Log #1", by = "VexCorp Mutation Lab", pos = Vector3.new(-430, 1.6, 50),
		text = "MUTAGEN X WORKS!\n\nSubject 001 (a hamster) can now do calculus.\n\nSubject 001 is very angry about it." },
	{ id = "LabLog7", title = "Lab Log #7", by = "VexCorp Mutation Lab", pos = Vector3.new(-420, 1.8, 94),
		text = "Tested Mutagen X on a Band Geek.\n\nThe tuba grew. The kid glows. The kid is worth SIX TIMES the tuition.\n\nNote to self: mutate MORE children. Order more tubes." },
	{ id = "LabLog13", title = "Lab Log #13", by = "VexCorp Mutation Lab", pos = Vector3.new(-456, 1.8, 138),
		text = "Mutants keep escaping. Someone keeps breaking the tubes and RUNNING.\n\nInstalled lasers. Installed cameras. Hired guards in yellow suits.\n\nAlso, a cardboard box went missing from the store room. Probably unrelated." },
	{ id = "Hazmat", title = "Hazmat Safety Card", by = "VexCorp Mutation Lab", pos = Vector3.new(-384, 1.8, 132),
		text = "1. Do NOT drink the Mutagen.\n2. Do NOT pet the mutants.\n3. If you smell smoke, it's a smoke bomb. Run the other way.\n4. Do NOT tell Dr. Vex about rule 3." },
	{ id = "Machine", title = "The Homework Machine", by = "Dr. Veronica Vex", pos = Vector3.new(4, 1.6, 108),
		text = "Power source: Mutagen X, and one (1) Tiny Professor's brain.\nOutput: INFINITE homework.\nSide effect: recess ends. Forever. For everyone.\n\nPerfect." },
	{ id = "Otis", title = "A Letter from Otis", by = "Otis, bus driver", pos = Vector3.new(-340, 1.6, 16),
		text = "Wobblesworth,\n\nI drove Veronica to school every day for six years. She never once looked out the window.\n\nKeep the kids looking out the window.\n\n- Otis" },
	{ id = "Brochure", title = "Vex Prep Academy Brochure", by = "Vex Prep Academy", pos = Vector3.new(396, 1.6, -52),
		text = "VEX PREP ACADEMY\n\nNo recess! No lunch! No windows!\n\nOur students do homework 25 hours a day.\n\nENROLL NOW and never see the sun again!" },
	{ id = "Secret", title = "Veronica's Secret Diary", by = "Veronica, age 10", pos = Vector3.new(427, 1.8, -150),
		text = "Nobody ever picked me for kickball. Not once. Not EVER.\n\nSo if I can't play at recess...\nNOBODY can.\n\n...Don't read this." },
}
Config.FileById = {}
for i, f in Config.Files do
	f.order = i
	Config.FileById[f.id] = f
end
-- what collecting them earns: candy for each, and these at the milestones
Config.FileRewards = { candy = 25, milestones = {
	[4] = { gear = "SmokeBomb", n = 3, text = "3 Smoke Bombs" },
	[8] = { gear = "CardboardBox", n = 1, text = "a Cardboard Box" },
	[12] = { gear = "EnergyDrink", n = 3, text = "3 Energy Drinks" },
	[16] = { mutant = "Mythic", text = "a MUTATED MYTHIC kid" },
} }

-- Janitor Stan's secret missions (SecretService): repeatable jobs against VexCorp, one at a time,
-- a short breather between them. Reward: `secs` seconds of your tuition (at least `floor`), plus gear.
Config.SecretMissions = {
	{ id = "secret_ghost", title = "Ghost Protocol", secs = 360, floor = 2500, gear = "SmokeBomb", n = 2,
		objective = "Break a mutant out of the Lab and get it out WITHOUT setting off the alarm first",
		lines = { "Here's one for a real pro, kid.", "Get into that Lab and break a mutant out. But nobody sees you going in: no lasers, no cameras, no guards. Ghost." } },
	{ id = "secret_hack", title = "Hack Job", secs = 300, floor = 2000, gear = "EnergyDrink", n = 2,
		objective = "Hack both Lab terminals (hold E), then get out of the Lab",
		lines = { "VexCorp's got two computers in that Lab. Big green screens.", "Hack both of 'em for me, then get out. I want to see what she's been hiding." } },
	{ id = "secret_sample", title = "Sample Run", secs = 240, floor = 1500, vial = 1,
		objective = "Fill a vial at the Mutagen X Vat in the Lab (hold E), then get out",
		lines = { "Ever wondered what that green goop does to a kid?", "Sneak into the Lab, fill a vial at the big vat, and get out. Keep the vial. Use it on one of your own kids. Heh heh." } },
	{ id = "secret_snoop", title = "Snoop", secs = 200, floor = 1200, gear = "WhoopeeCushion", n = 2,
		objective = "Photograph Vex's desk in the VexCorp Factory (hold E), then get out",
		lines = { "Vex keeps her plans on her desk in the Factory. Right in front of the pens.", "Get a photo of that desk and get out. Guards'll be everywhere. Don't get caught." } },
}
Config.SecretById = {}
for i, s in Config.SecretMissions do
	s.order = i
	Config.SecretById[s.id] = s
end
Config.SecretCooldown = 150 -- seconds between Stan's jobs

-- Co-op schools (CrewService): up to four principals run one school, each with a role (any number
-- of them can pick the same one: a school of four Presidents is fine)
Config.CrewMax = 4
Config.Roles = {
	{ id = "President", icon = "\u{1F451}", name = "President", color = rgb(255, 184, 48),
		perk = "Runs the school. 10% off everything you buy for it" },
	{ id = "Teacher", icon = "\u{1F4DA}", name = "Teacher", color = rgb(80, 160, 255),
		perk = "+20% tuition for the whole school while you're inside it" },
	{ id = "Monitor", icon = "\u{1F6E1}\u{FE0F}", name = "Hall Monitor", color = rgb(240, 80, 80),
		perk = "Bonks stun twice as long and knock goons out in one hit" },
	{ id = "Recruiter", icon = "\u{1F392}", name = "Recruiter", color = rgb(70, 200, 110),
		perk = "Carry stolen kids 20% faster and sneak quieter" },
}
Config.RoleById = {}
for _, r in Config.Roles do Config.RoleById[r.id] = r end
Config.RolePerks = { discount = 0.9, teacher = 0.2, stun = 2, carry = 1.2 }

-- Roblox friends in the same server: +10% tuition each, up to 4 (CrewService)
Config.FriendsBonus = { each = 0.1, max = 4 }

-- crew jobs: one at a time while two or more run a school together (n grows with the crew)
Config.CrewJobs = {
	{ id = "assembly", icon = "\u{1F4E3}", title = "ASSEMBLY!", text = "Everyone inside the school at the same time", secs = 90 },
	{ id = "busRush", icon = "\u{1F68C}", title = "BUS RUSH", text = "Enroll %d kids as a crew", per = 2, secs = 240, signal = "enroll" },
	{ id = "vexRaid", icon = "\u{1F3EB}", title = "RAID VEX PREP", text = "Steal %d kids from Vex Prep as a crew", per = 1, secs = 300, signal = "rivalEscaped" },
	{ id = "payday", icon = "\u{1F4B5}", title = "PAYDAY", text = "Collect %s from the desks as a crew", secs = 180, signal = "collect", incomeSecs = 60 },
}
-- a finished job: cash for the school (this many seconds of its tuition, at least min) and a tuition
-- boost for everyone
Config.CrewJobReward = { incomeSecs = 150, min = 600, boost = 0.3, boostSecs = 120, gap = 25 }

-- Vex Prep Academy (RivalService): VexCorp's own school, full of kids to steal
Config.Rival = {
	restock = 75, -- seconds before a desk has a new kid
	revengeAfter = 70, -- after you steal from them, their goons raid your school within this many seconds
}

-- places with guards: the client shows the HIDDEN / SPOTTED eye and the sneak keys inside them
Config.SecureZones = {
	{ name = "factory", x0 = -33, x1 = 33, z0 = 34, z1 = 134 },
	{ name = "lab", x0 = -474, x1 = -366, z0 = 42, z1 = 150 },
	{ name = "rival", x0 = 372, x1 = 482, z0 = -170, z1 = -45 },
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
-- the Principal's Pick: one kid, Prodigy 95 % / Secret 5 %, at :30 on even UTC hours
Config.PrincipalsPick = { every = 7200, offset = 1800, count = 1, weights = { Prodigy = 95, Secret = 5 } }
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
