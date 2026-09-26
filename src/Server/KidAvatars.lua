-- ServerScriptService.Server.KidAvatars
-- The students as real Roblox avatars (tomas, 2026-09-26: "the old characters, just more realistic",
-- avatar-style): the official ROBLOX Boy / ROBLOX Girl body, a dynamic head for an expressive face,
-- and catalog clothes, hair and accessories picked for each kid. StudentFactory builds them with
-- Players:CreateHumanoidModelFromDescription at kid scale, then adds the kid's signature prop from
-- StudentProps (the trumpet, the apple...) unless prop = false (the outfit already is the prop).
--   body   "boy" | "girl"
--   head   dynamic head asset id (the face)
--   shirt / pants / tshirt   classic clothing asset ids
--   hair / hat / face / neck / back / front / waist / shoulder   accessory asset ids ("a,b" for more)
--   skin   "light" | "tan" | "brown" | "dark" (else the kid's Config look.skin)
-- A student missing here keeps the old blocky kid.
local KidAvatars = {}

KidAvatars.Bodies = {
	boy = { Torso = 376532000, RightArm = 376531012, LeftArm = 376530220, LeftLeg = 376531300, RightLeg = 376531703 },
	girl = { Torso = 376547767, RightArm = 376547341, LeftArm = 376547633, LeftLeg = 376546668, RightLeg = 376547092 },
}
-- warmer than the blocky kids' tones: pale skin reads as white on these bodies in the sun
KidAvatars.Skin = {
	light = Color3.fromRGB(232, 182, 142),
	tan = Color3.fromRGB(214, 160, 118),
	brown = Color3.fromRGB(160, 106, 70),
	dark = Color3.fromRGB(100, 64, 44),
}
-- faces (dynamic heads, from the catalog's face bundles)
local F = {
	smile = 77970138736769, -- Classic :] Smile, with blush
	grin = 11163789916, -- The Winning Smile
	sweet = 106330973785235, -- Cutie Smile Blush (eyes closed)
	excited = 96355140573881, -- Cute Excited (>< and a big open mouth)
	silly = 71993263971199, -- Silly Smile
	anime = 14557487475, -- Cute Face (big shiny eyes)
	lashes = 105775425065711, -- Cute Smiling Face (lashes, cheeks)
	happy = 15170581959, -- Animated Cute Blush (eyes closed, happy)
	blush = 129797746530165, -- Cute Smile Blush
	endearing = 70740241650123, -- Blushing Endearing Smile
	tired = 126279174861332, -- Cute Tired Chibi
}
KidAvatars.Faces = F

-- prop: true (default) keeps the whole StudentProps prop; false drops it; otherwise the parts of it
-- to keep: "hands" (held), "head" (worn on the head), "body" (on the torso, legs, back), or a mix
-- like "hands,head"
KidAvatars.Kids = {
	-- Common
	UntiedTyler = { body = "boy", head = F.smile, hair = "90021773176242", shirt = 8128877497, pants = 382537806 },
	GlueStickGus = { body = "boy", head = F.grin, hair = "136263149107612", shirt = 13997655, pants = 125613357615715 },
	DoodleDot = { body = "girl", head = F.lashes, hair = "7154637981", shirt = 6054563541, pants = 8895550239 },
	LunchboxLucy = { body = "girl", head = F.sweet, hair = "93870350885383", shirt = 5130315808, pants = 6121139535 },
	PajamaPete = { body = "boy", head = F.tired, hair = "13433327568", shirt = 6308148710, pants = 14093332079, prop = "hands" },
	HiccupHank = { body = "boy", head = F.excited, hair = "123206510187743", shirt = 6815197887, pants = 11449940512 },
	SleepySam = { body = "boy", head = F.tired, hat = "6097029548", shirt = 18719568268, pants = 76760828751391, prop = "hands" },
	CrayonEater = { body = "boy", head = F.silly, hair = "8859470868", shirt = 13593212663, pants = 6257364134 },
	BackpackKid = { body = "boy", head = F.smile, hair = "110659518395165", back = "12443400086", shirt = 452273064, pants = 76760828751391, prop = false },
	JuiceBoxJake = { body = "boy", head = F.excited, hair = "11467052110", shirt = 12218806436, pants = 125613357615715 },
	BubbleGumBetty = { body = "girl", head = F.anime, hair = "109068013557163", shirt = 13664558957, pants = 7467330095 },
	PencilChewer = { body = "boy", head = F.endearing, hair = "110659518395165", shirt = 6815197887, pants = 11449940512 },
	SneezySid = { body = "boy", head = F.tired, hair = "13002823236", neck = "16467577188", shirt = 72255865367787, pants = 6209407218 },
	PuddlePip = { body = "girl", head = F.happy, hair = "120999006849762", shirt = 770018056, pants = 6958133488, prop = "head" },
	HomeworkDoug = { body = "boy", head = F.grin, hair = "13002823236", shirt = 3091483663, pants = 6209407218 },
	RecorderRosie = { body = "girl", head = F.blush, hair = "15858476919", shirt = 18880895215, pants = 8895550239 },
	FrogFran = { body = "girl", head = F.lashes, hair = "96281513956407", shirt = 5915335223, pants = 5964548864 },
	MimeMimi = { body = "girl", head = F.sweet, hat = "7084418627", shirt = 6481161589, pants = 105985411012275, prop = "hands" },
	-- Uncommon
	TattletaleTina = { body = "girl", head = F.endearing, hair = "13294832403", shirt = 8468223457, pants = 7375574053, prop = "hands" },
	LooseToothLou = { body = "boy", head = F.grin, hair = "12652803319", shirt = 8908361326, pants = 11449940512 },
	CardboardRudy = { body = "boy", head = F.happy, pants = 6257364134 },
	ClassClown = { body = "boy", head = F.silly, hair = "18580427723", shirt = 10725107524, pants = 10725108119 },
	NerdNed = { body = "boy", head = F.smile, hair = "13379434904", face = "13399898495", shirt = 12947706023, pants = 11449940512, prop = "hands,body" },
	FidgetFred = { body = "boy", head = F.excited, hair = "8966711821", shirt = 2254864067, pants = 76760828751391 },
	HallMonitor = { body = "boy", head = F.grin, hair = "6983912109", shirt = 6057960079, pants = 7322526269 },
	ShowAndTellSally = { body = "girl", head = F.anime, hair = "13947885238", shirt = 3151344528, pants = 16242385155 },
	GamerGabe = { body = "boy", head = F.grin, hair = "15681279767", hat = "16266380460", shirt = 1316269708, pants = 7322526269, prop = "hands" },
	TheaterKid = { body = "boy", head = F.endearing, hair = "83076646080446", shirt = 7520868412, pants = 7322526269 },
	-- Rare
	TeachersPet = { body = "girl", head = F.sweet, hair = "13865457865", shirt = 1383572886, pants = 7467330095 },
	SkaterKid = { body = "boy", head = F.grin, hair = "140529327476591", hat = "15300251849", shirt = 7521968242, pants = 6092090926 },
	Mathlete = { body = "boy", head = F.smile, hair = "100565153355098", shirt = 82600713548981, pants = 72395991071341 },
	BandGeek = { body = "boy", head = F.grin, hair = "105034447346251", hat = "10293177181", shirt = 94509788673764, pants = 8741031594 },
	CheerCaptain = { body = "girl", head = F.excited, hair = "128343067484017", shirt = 6266326685, pants = 6212699685, prop = "hands" },
	ArtsyAva = { body = "girl", head = F.lashes, hair = "11180024054", hat = "12344374178", shirt = 6176966134, pants = 6958133488, prop = "hands" },
	ChessChampion = { body = "boy", head = F.smile, hair = "13743108491", shirt = 14478025982, pants = 72395991071341 },
	-- Epic
	Quarterback = { body = "boy", head = F.grin, hair = "15815125864", shirt = 11687708434, pants = 14217454714 },
	ScienceFair = { body = "boy", head = F.excited, hair = "17414076900", shirt = 10181998281, pants = 7322526269, prop = "hands,head" },
	ExchangeStudent = { body = "boy", head = F.smile, hair = "110659518395165", shirt = 4900212722, pants = 9064494048 },
	SpellingBee = { body = "girl", head = F.happy, hair = "6983912109", hat = "138201526985230", shirt = 11983986409, pants = 14597528293, prop = "hands,body" },
	RoboticsKid = { body = "boy", head = F.smile, hair = "13002823236", face = "14449179297", shirt = 1039292284, pants = 7322526269 },
	Photographer = { body = "boy", head = F.grin, hat = "12469643606", shirt = 105523994682801, pants = 5280612505 },
	DramaQueen = { body = "girl", head = F.anime, hair = "138769057765455", hat = "86435951379557", shirt = 5909737521, pants = 2385359101, prop = "hands,body" },
	-- Legendary
	Valedictorian = { body = "boy", head = F.grin, hair = "6983912109", hat = "97903087712729", shirt = 6258506673, pants = 18759116737, prop = "hands" },
	CouncilPrez = { body = "boy", head = F.smile, hair = "120299782374101", shirt = 9432710249, pants = 15861408581 },
	SchoolMascot = { body = "boy", head = F.happy, hat = "85291267428496", shirt = 100152555526836, pants = 4985874534, prop = "hands" },
	LunchFavorite = { body = "boy", head = F.happy, hair = "12404376891", shirt = 5130315808, pants = 11449940512 },
	PromKing = { body = "boy", head = F.endearing, hair = "6983912109", hat = "74572527283532", shirt = 16582667785, pants = 7122094125, prop = "hands,body" },
	DanceDJ = { body = "boy", head = F.excited, hair = "15713643377", hat = "103285123438087", shirt = 1144081700, pants = 7322526269 },
	HallOfFame = { body = "boy", head = F.grin, hair = "110659518395165", shirt = 1668955071, pants = 72395991071341 },
	-- Mythic
	PrincipalsNephew = { body = "boy", head = F.smile, hair = "140240103586404", face = "136757413464863", shirt = 10720552553, pants = 7322526269, prop = false },
	MoustacheKid = { body = "boy", head = F.smile, hair = "123331943944936", shirt = 11707395941, pants = 11449940512, prop = "head" },
	KidGenius = { body = "boy", head = F.excited, shirt = 10139498722, pants = 7322526269, prop = "head" },
	Room13Ghost = { body = "boy", head = F.happy, shirt = 5665733125, pants = 72395991071341 },
	TimeTraveler = { body = "boy", head = F.grin, hair = "16199920539", hat = "131983131822675", shirt = 12001087457, pants = 7322526269, prop = "hands" },
	NewKid = { body = "boy", head = F.smile, hat = "91015760281855", shirt = 9521380145, pants = 7322526269, prop = false },
	-- Prodigy
	RocketKid = { body = "boy", head = F.excited, hat = "74331096073401", shirt = 18124796548, pants = 10725037192 },
	TinyProfessor = { body = "boy", head = F.smile, hair = "10323431381", face = "139884917225611", shirt = 188083526, pants = 11449940512, prop = "hands" },
	PopStarKid = { body = "girl", head = F.excited, hair = "132932997731038", face = "8098472402", shirt = 250538929, pants = 72395991071341, prop = "hands" },
	ChessGrandmaster = { body = "boy", head = F.smile, hair = "6983912109", shirt = 6273765763, pants = 7322526269, prop = "head" },
	ChildCEO = { body = "boy", head = F.grin, hair = "6323887109", shirt = 7903625295, pants = 16419869728, prop = "hands" },
	-- Secret
	WifiKid = { body = "boy", head = F.excited, hair = "81009844664966", shirt = 6778436319, pants = 76760828751391 },
	Substitute = { body = "boy", head = F.smile, hat = "6405198459", face = "124665474939580", shirt = 115405453729836, pants = 84712978021049, prop = false },
	SnowDayOracle = { body = "girl", head = F.happy, hat = "110925676972910", shirt = 144679886, pants = 76760828751391 },
	HomeworkReminder = { body = "boy", head = F.silly, hair = "91599957937820", back = "135190315724716", shirt = 2017232105, pants = 7322526269, prop = "hands" },
	Student404 = { body = "boy", head = F.silly, shirt = 83821615359457, pants = 1414800029 },
	-- Alumni
	GraduateGrandpa = { body = "boy", head = F.happy, hair = "5139189731", face = "461493477", shirt = 6924589820, pants = 6258511193, prop = "hands" },
	ClassOf99 = { body = "boy", head = F.grin, hair = "83550829948659", shirt = 7216186234, pants = 125613357615715, prop = "hands" },
	HeadPrefect = { body = "boy", head = F.smile, hair = "132484883569768", shirt = 10703031658, pants = 7322526269, prop = "hands" },
	TheFounder = { body = "boy", head = F.smile, hat = "70438438241040", face = "103970674901498", shirt = 91853454, pants = 6258511193 },
	TinyPrincipal = { body = "boy", head = F.smile, face = "78989566349825,139884917225611", shirt = 10244256843, pants = 9207102956, prop = "hands" },
}

return KidAvatars
