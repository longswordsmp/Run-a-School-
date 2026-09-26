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

-- prop: true (default) keeps the whole StudentProps prop; false drops it; "hands" keeps only what's
-- held; "head" keeps only what's on the head; "nohead" drops what's on the head
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
	-- Rare
	BandGeek = { body = "boy", head = F.grin, hair = "105034447346251", hat = "10293177181", shirt = 94509788673764, pants = 8741031594 },
}

return KidAvatars
