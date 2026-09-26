-- ReplicatedStorage.Shared.Places
-- Named spots in town (docs/TOWN.md): where each townsperson stands (post + the point they face),
-- and the spots quests send you to. Quests and cutscenes only use names from here, so a typo is
-- caught by the checks instead of sending a player nowhere. y is the ground under the spot.
local Places = {}

local function P(x, y, z, lookX, lookZ, area)
	return { pos = Vector3.new(x, y, z), look = Vector3.new(lookX or x, y, lookZ or (z + 10)), area = area }
end

-- the townspeople's posts
Places.npc = {
	-- Downtown
	MayorMaxine = P(6, 2.2, -493, 6, -470, "Downtown"),
	GrocerGus = P(-58, 0.6, -306, -40, -306, "Downtown"),
	OfficerPenny = P(198, 0, -372, 198, -390, "Downtown"),
	MrPage = P(100, 0, -412, 100, -395, "Downtown"),
	PixelPete = P(-200, 0, -412, -200, -395, "Downtown"),
	RosaCook = P(-90, 0, -414, -90, -395, "Downtown"),
	MoMail = P(300, 0.5, -372, 300, -390, "Downtown"),
	Scoops = P(-310, 0, -414, -310, -395, "Downtown"),
	MrPennington = P(-192, 0, -371, -192, -390, "Downtown"),
	HankHardware = P(-310, 0, -370, -310, -390, "Downtown"),
	-- Maple Heights
	GrandmaRose = P(-274, 1.4, 306, -274, 330, "MapleHeights"),
	MrPatel = P(-366, 1.4, 306, -366, 330, "MapleHeights"),
	MrsPatel = P(-361.5, 1.4, 306, -361.5, 330, "MapleHeights"),
	LilTimmy = P(-266, 0, 352, -266, 330, "MapleHeights"),
	CoachDoug = P(100, 0, 312, 100, 330, "MapleHeights"),
	Skye = P(274, 0.45, 341, 280, 341, "MapleHeights"),
	Grumbles = P(86, 1.4, 427, 86, 450, "MapleHeights"),
	NurseNina = P(-84, 0, 354, -84, 330, "MapleHeights"),
	FirefighterFrank = P(-146, 0, 470, -146, 450, "MapleHeights"),
	MrsKim = P(150, 0, 476, 150, 450, "MapleHeights"),
	-- Pine Park
	RangerRick = P(-638, 1.2, 236, -600, 236, "PinePark"),
	FishermanFinn = P(-664, 1.4, -170, -690, -170, "PinePark"),
	BirdwatcherBea = P(-750, 0, -306, -700, -306, "PinePark"),
	CounselorCody = P(-700, 0, 372, -700, 358, "PinePark"),
	ScoutSam = P(-645, 14.4, -372.5, -600, -372.5, "PinePark"),
	-- VexCorp Industrial
	GaryGoon = P(636, 0, 300, 600, 300, "Industrial"),
	EngineerEllie = P(740, 0, -122, 700, -122, "Industrial"),
	Robo7 = P(688.2, 0.6, 0, 670, 0, "Industrial"),
	ChiefBrick = P(592, 0, -10, 570, -10, "Industrial"),
	-- the Mothership (TownUFO, high over the sea: only reached by being beamed up)
	CaptainZorp = P(0, 380, 746, 0, 800),
	Blip = P(-32, 380, 760, 0, 760),
	Glorb = P(40, 380, 760, 0, 760),
}

-- spots quests send you to (visit, collect, goons, chase routes)
Places.spot = {
	-- the school area
	HubFountain = P(0, 0, -86),
	BusStop = P(-330, 0, -12),
	Detention = P(346, 0, 0),
	FactoryGate = P(0, 0, 30),
	LabGate = P(-420, 0, 36),
	LabTubes = P(-420, 0, 110),
	VexPrepGate = P(427, 0, -40),
	RecessCommons = P(-190, 0, 60),
	SugarShack = P(190, 0, 56),
	-- Downtown
	DowntownGate = P(0, 0, -250),
	FreshMartDoor = P(-48, 0, -300),
	FreshMartAisles = P(-78, 0.6, -300),
	FreshMartBackDoor = P(-100, 0, -330),
	FreshMartLot = P(-36, 0, -300),
	TownSquare = P(85, 0, -312),
	ClockTower = P(85, 0, -306),
	Bandstand = P(120, 1.6, -340),
	TownSquareFountain = P(50, 0, -282),
	TownHall = P(0, 2.2, -490),
	PoliceStation = P(190, 0, -372),
	PostOffice = P(320, 0, -372),
	Bank = P(-200, 0, -372),
	Hardware = P(-320, 0, -372),
	Diner = P(-100, 0, -412),
	Arcade = P(-210, 0, -412),
	IceCream = P(-320, 0, -412),
	Library = P(110, 0, -410),
	Barber = P(215, 0, -412),
	ToyBox = P(320, 0, -412),
	MarketStreetWest = P(-400, 0, -390),
	MarketStreetEast = P(400, 0, -390),
	-- Maple Heights
	MapleGate = P(0, 0, 250),
	MapleLane = P(0, 0, 330),
	OakAvenue = P(0, 0, 450),
	Playground = P(90, 0, 370),
	Clinic = P(-90, 0, 352),
	FireStation = P(-150, 0, 468),
	CommunityGarden = P(150, 0, 490),
	TimmysTreehouse = P(-258, 0, 386),
	GrumblesHedge = P(90, 0, 434),
	RosesPorch = P(-274, 0, 306),
	MapleCulDeSacWest = P(-410, 0, 330),
	MapleCulDeSacEast = P(410, 0, 330),
	OakCulDeSacWest = P(-410, 0, 450),
	OakCulDeSacEast = P(410, 0, 450),
	-- Pine Park
	ParkGate = P(-560, 0, 0),
	ParkPlaza = P(-590, 0, 0),
	RangerStation = P(-638, 1.2, 230),
	Campfire = P(-706, 0, 382),
	Campground = P(-705, 0, 390),
	Lookout = P(-740, 30.8, 170),
	LookoutFoot = P(-734, 0, 176),
	LakeDock = P(-660, 1.4, -170),
	LakeShore = P(-640, 0, -150),
	Boathouse = P(-690, 0, -110),
	PicnicGrounds = P(-585, 0, -95),
	Treehouse = P(-650, 14.4, -370),
	TreehouseFoot = P(-640, 0, -370),
	BirdHide = P(-750, 0, -300),
	ParkNorthTrail = P(-600, 0, 330),
	ParkSouthTrail = P(-600, 0, -330),
	ParkSouthFork = P(-600, 0, -370), -- where the treehouse trail meets the south trail
	-- VexCorp Industrial
	IndustrialGate = P(560, 0, 0),
	Checkpoint = P(585, 0, 0),
	TowerLobby = P(676, 0.6, 0),
	ExecutiveElevator = P(704, 0.6, 14),
	WarehouseA = P(632, 0, 260),
	WarehouseAInside = P(660, 0.6, 260),
	WarehouseB = P(632, 0, -260),
	WarehouseBInside = P(660, 0.6, -260),
	LoadingDock = P(628, 4, 160),
	VanLot = P(636, 0, -160),
	MutagenTanks = P(740, 0, -150),
	ContainerYardN = P(730, 0, 360),
	ContainerYardS = P(730, 0, -360),
	-- the Lair
	LairElevator = P(610, -160, 0),
	LairCore = P(690, -160, 30),
	LairThrone = P(745, -160, 0),
	LairCages = P(690, -160, -74),
	LairVats = P(690, -160, 74),
	LairPod = P(640, -160, 8),
	-- the Mothership
	ShipPad = P(0, 380, 806, 0, 760),
	ShipBridge = P(0, 380, 748),
	ShipTubes = P(-36, 380, 760),
	ShipScreen = P(42, 380, 760),
	ShipStar1 = P(-30, 380, 728),
	ShipStar2 = P(30, 380, 728),
	ShipStar3 = P(-42, 380, 792),
	ShipStar4 = P(42, 380, 792),
	ShipStar5 = P(0, 380, 714),
}

-- a place by name (an NPC post or a spot)
function Places.get(name)
	return Places.spot[name] or Places.npc[name]
end

return Places
