-- ReplicatedStorage.Shared.Config
local Config = {}

Config.Rarities = {
	{ id = "Common", color = Color3.fromRGB(215, 215, 215), weight = 55 },
	{ id = "Uncommon", color = Color3.fromRGB(90, 220, 90), weight = 25 },
	{ id = "Rare", color = Color3.fromRGB(70, 150, 255), weight = 12 },
	{ id = "Epic", color = Color3.fromRGB(180, 80, 255), weight = 5 },
	{ id = "Legendary", color = Color3.fromRGB(255, 180, 30), weight = 2.2 },
	{ id = "Mythic", color = Color3.fromRGB(255, 50, 90), weight = 0.7 },
	{ id = "Secret", color = Color3.fromRGB(20, 20, 20), weight = 0.1, rainbow = true },
}
Config.RarityById = {}
for i, r in Config.Rarities do
	r.order = i
	Config.RarityById[r.id] = r
end

-- look: skin, shirt (torso+arms), pants (legs), scale; prop is built by StudentFactory
Config.Students = {
	{ id = "SleepySam", name = "Sleepy Sam", rarity = "Common", price = 25, income = 1,
		look = { skin = "light", shirt = Color3.fromRGB(140, 170, 230), pants = Color3.fromRGB(80, 90, 140) }, prop = "Nightcap" },
	{ id = "CrayonEater", name = "Crayon Eater", rarity = "Common", price = 50, income = 2,
		look = { skin = "tan", shirt = Color3.fromRGB(255, 120, 60), pants = Color3.fromRGB(60, 60, 70) }, prop = "Crayon" },
	{ id = "BackpackKid", name = "Backpack Kid", rarity = "Common", price = 100, income = 4,
		look = { skin = "brown", shirt = Color3.fromRGB(90, 200, 120), pants = Color3.fromRGB(50, 70, 120) }, prop = "Backpack" },

	{ id = "ClassClown", name = "Class Clown", rarity = "Uncommon", price = 300, income = 9,
		look = { skin = "light", shirt = Color3.fromRGB(240, 60, 180), pants = Color3.fromRGB(60, 180, 240) }, prop = "ClownNose" },
	{ id = "NerdNed", name = "Nerd Ned", rarity = "Uncommon", price = 600, income = 14,
		look = { skin = "light", shirt = Color3.fromRGB(245, 245, 245), pants = Color3.fromRGB(150, 110, 70) }, prop = "Glasses" },
	{ id = "HallMonitor", name = "Hall Monitor", rarity = "Uncommon", price = 1000, income = 20,
		look = { skin = "dark", shirt = Color3.fromRGB(80, 120, 200), pants = Color3.fromRGB(40, 40, 50) }, prop = "Sash" },

	{ id = "TeachersPet", name = "Teacher's Pet", rarity = "Rare", price = 3000, income = 45,
		look = { skin = "tan", shirt = Color3.fromRGB(255, 190, 210), pants = Color3.fromRGB(90, 60, 110) }, prop = "Apple" },
	{ id = "SkaterKid", name = "Skater Kid", rarity = "Rare", price = 6000, income = 70,
		look = { skin = "light", shirt = Color3.fromRGB(40, 40, 45), pants = Color3.fromRGB(70, 110, 160) }, prop = "Skateboard" },
	{ id = "BandGeek", name = "Band Geek", rarity = "Rare", price = 10000, income = 100,
		look = { skin = "brown", shirt = Color3.fromRGB(150, 30, 40), pants = Color3.fromRGB(30, 30, 40) }, prop = "Trumpet" },

	{ id = "Quarterback", name = "Star Quarterback", rarity = "Epic", price = 30000, income = 260,
		look = { skin = "dark", shirt = Color3.fromRGB(230, 60, 40), pants = Color3.fromRGB(240, 240, 240), scale = 1.1 }, prop = "Football" },
	{ id = "ScienceFair", name = "Science Fair Winner", rarity = "Epic", price = 55000, income = 420,
		look = { skin = "light", shirt = Color3.fromRGB(250, 250, 250), pants = Color3.fromRGB(60, 60, 70) }, prop = "Goggles" },
	{ id = "ExchangeStudent", name = "Exchange Student", rarity = "Epic", price = 80000, income = 600,
		look = { skin = "tan", shirt = Color3.fromRGB(40, 150, 140), pants = Color3.fromRGB(230, 220, 190) }, prop = "Suitcase" },

	{ id = "Valedictorian", name = "Valedictorian", rarity = "Legendary", price = 300000, income = 1800,
		look = { skin = "brown", shirt = Color3.fromRGB(30, 30, 40), pants = Color3.fromRGB(30, 30, 40) }, prop = "GradCap" },
	{ id = "CouncilPrez", name = "Student Council Prez", rarity = "Legendary", price = 600000, income = 3200,
		look = { skin = "light", shirt = Color3.fromRGB(30, 60, 140), pants = Color3.fromRGB(120, 120, 130) }, prop = "Gavel" },
	{ id = "LunchFavorite", name = "Lunch Lady's Favorite", rarity = "Legendary", price = 1000000, income = 5000,
		look = { skin = "tan", shirt = Color3.fromRGB(250, 200, 80), pants = Color3.fromRGB(90, 70, 50), scale = 1.15 }, prop = "LunchTray" },

	{ id = "PrincipalsNephew", name = "Principal's Nephew", rarity = "Mythic", price = 5000000, income = 22000,
		look = { skin = "light", shirt = Color3.fromRGB(240, 240, 250), pants = Color3.fromRGB(20, 20, 30) }, prop = "ShadesTie" },
	{ id = "KidGenius", name = "Kid Genius", rarity = "Mythic", price = 12000000, income = 40000,
		look = { skin = "tan", shirt = Color3.fromRGB(120, 60, 220), pants = Color3.fromRGB(40, 30, 60), head = 1.6 }, prop = "Brain" },
	{ id = "NewKid", name = "The New Kid", rarity = "Mythic", price = 20000000, income = 60000,
		look = { skin = "dark", shirt = Color3.fromRGB(20, 20, 20), pants = Color3.fromRGB(20, 20, 20) }, prop = "Hoodie" },

	{ id = "WifiKid", name = "Kid Who Knows The WiFi Password", rarity = "Secret", price = 100000000, income = 500000,
		look = { skin = "light", shirt = Color3.fromRGB(0, 200, 255), pants = Color3.fromRGB(30, 30, 60) }, prop = "Router" },
	{ id = "Substitute", name = "Substitute Teacher?!", rarity = "Secret", price = 250000000, income = 1200000,
		look = { skin = "light", shirt = Color3.fromRGB(150, 110, 60), pants = Color3.fromRGB(150, 110, 60), scale = 1.35 }, prop = "Trenchcoat" },
}
Config.StudentById = {}
for i, s in Config.Students do
	s.order = i
	Config.StudentById[s.id] = s
end

-- grades (mutations), rolled on spawn
Config.Grades = {
	{ id = "Normal", mult = 1, weight = 90 },
	{ id = "Honor Roll", mult = 2, weight = 7, color = Color3.fromRGB(255, 200, 40) },
	{ id = "Gifted", mult = 3, weight = 2.5, color = Color3.fromRGB(120, 230, 255) },
	{ id = "Straight A+", mult = 5, weight = 0.5, color = Color3.fromRGB(255, 90, 200), rainbow = true },
}
Config.GradeById = {}
for _, g in Config.Grades do Config.GradeById[g.id] = g end

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
