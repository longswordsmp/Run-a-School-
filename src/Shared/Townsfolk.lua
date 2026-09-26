-- ReplicatedStorage.Shared.Townsfolk
-- The townspeople (docs/TOWN.md): who they are, what they wear (an outfit in StudentProps) and a few
-- idle lines for when they have nothing for you. Where they stand is Places.npc[id]. `scale` makes
-- the kids small; `walk` = a route of place names they stroll along.
local Townsfolk = {
	-- Downtown
	{ id = "MayorMaxine", name = "Mayor Maxine Goodwin", title = "Mayor", outfit = "mayor", color = Color3.fromRGB(120, 160, 255),
		lines = { "Recess Row has had a mayor for 90 years. I'm the first one who can do a cartwheel.", "Dr. Vex keeps sending me gift baskets. They're full of homework." } },
	{ id = "GrocerGus", name = "Grocer Gus", title = "Fresh Mart", outfit = "grocer", color = Color3.fromRGB(90, 200, 110),
		lines = { "Apples, bananas, gummy worms. The worms outsell the apples ten to one.", "VexCorp wants to buy my store. They'd only sell flashcards!" } },
	{ id = "OfficerPenny", name = "Officer Penny", title = "Police", outfit = "cop", color = Color3.fromRGB(90, 140, 255),
		lines = { "Crime in Recess Row: one stolen stapler. Case still open.", "If you see a purple van, call me. Or bonk it. Bonking works." } },
	{ id = "MrPage", name = "Mr. Page", title = "Librarian", outfit = "librarian", color = Color3.fromRGB(200, 150, 100),
		lines = { "Shhh. ...Sorry, habit. You can talk.", "Somebody keeps checking out every book on hypnosis. Purple library card." } },
	{ id = "PixelPete", name = "Pixel Pete", title = "Pixel Palace", outfit = "arcade", color = Color3.fromRGB(200, 90, 255),
		lines = { "High score on Space Recess: VEX. Every. Machine.", "Insert coin to continue. Or don't. I'm not your mom." } },
	{ id = "RosaCook", name = "Rosa", title = "Burger Diner", outfit = "cook", color = Color3.fromRGB(255, 110, 90),
		lines = { "Burgers so good, homework forgets itself.", "The Sugar Baron tried to put candy in my patties. I bonked him with a spatula." } },
	{ id = "MoMail", name = "Mo", title = "Mail Carrier", outfit = "mail", color = Color3.fromRGB(90, 140, 255), walk = { "MarketStreetWest", "MarketStreetEast" },
		lines = { "Can't stop, got letters! Every one of them says HOMEWORK IS THE FUTURE.", "VexCorp mails every house on Maple Lane twice a day." } },
	{ id = "Scoops", name = "Scoops", title = "Ice Cream", outfit = "scoops", color = Color3.fromRGB(255, 150, 200),
		lines = { "Today's flavour: Recess Ripple. Tomorrow: also Recess Ripple.", "Brain freeze is just your brain having fun." } },
	{ id = "MrPennington", name = "Mr. Pennington", title = "Banker", outfit = "banker", color = Color3.fromRGB(230, 200, 110),
		lines = { "A penny saved is a penny. I checked.", "VexCorp's account is enormous. And purple." } },
	{ id = "HankHardware", name = "Hank", title = "Hammer & Nail", outfit = "hank", color = Color3.fromRGB(240, 120, 70),
		lines = { "Need a hammer? A nail? A hammer made of nails? I've got it.", "VexCorp bought every lock in town last week. Every. Single. One." } },
	-- Maple Heights
	{ id = "GrandmaRose", name = "Grandma Rose", title = "Baker", outfit = "grandma", color = Color3.fromRGB(255, 150, 200),
		lines = { "Cookie, dear? They're fresh. Well, fresh-ish.", "I taught Veronica Vex to bake once. She burned the cookies ON PURPOSE." } },
	{ id = "MrPatel", name = "Mr. Patel", title = "Dad", outfit = "dad", color = Color3.fromRGB(120, 180, 255),
		lines = { "My kids used to love recess. Now they want to do MORE worksheets. Suspicious.", "Have you seen the purple flyers? They're on every door." } },
	{ id = "MrsPatel", name = "Mrs. Patel", title = "Mom", outfit = "mom", color = Color3.fromRGB(120, 220, 200),
		lines = { "I'm on the PTA. Which means I'm on EVERY committee.", "A school with a slide is a school I trust." } },
	{ id = "LilTimmy", name = "Lil' Timmy", title = "Kid", outfit = "timmy", scale = 0.72, color = Color3.fromRGB(255, 210, 90),
		lines = { "Mr. Whiskers is the best cat in the WORLD.", "When I grow up I want to go to YOUR school." } },
	{ id = "CoachDoug", name = "Coach Doug", title = "Dad", outfit = "coachdad", color = Color3.fromRGB(255, 120, 90),
		lines = { "Hustle! ...Sorry. I coach the under-8s. It never switches off.", "Nobody's played kickball in this town for weeks. Weeks!" } },
	{ id = "Skye", name = "Skye", title = "Skater", outfit = "skye", scale = 0.9, color = Color3.fromRGB(150, 110, 255),
		lines = { "Ramp's sick, right? Built it from VexCorp crates.", "Your school's got the best kids. Vex Prep kids don't even skate." } },
	{ id = "Grumbles", name = "Old Man Grumbles", title = "Neighbour", outfit = "grumbles", color = Color3.fromRGB(190, 170, 140),
		lines = { "GET OFF MY GRASS. ...Oh. You're on the path. Carry on.", "Back in my day recess was forty-five minutes and we LIKED it." } },
	{ id = "NurseNina", name = "Nurse Nina", title = "Clinic", outfit = "nurse", color = Color3.fromRGB(120, 210, 255),
		lines = { "Most common injury this month: paper cuts from VexCorp flyers.", "Remember: fresh air, snacks, and recess. Doctor's orders." } },
	{ id = "FirefighterFrank", name = "Firefighter Frank", title = "Fire Station", outfit = "firefighter", color = Color3.fromRGB(255, 90, 70),
		lines = { "I've rescued forty cats from trees. And one goon.", "The VexCorp Tower is a fire hazard. I've told them. They sent me homework." } },
	{ id = "MrsKim", name = "Mrs. Kim", title = "Gardener", outfit = "gardener", color = Color3.fromRGB(120, 220, 110),
		lines = { "Carrots, peppers, pumpkins. Talk to your plants! Mine tell me everything.", "Something purple is leaking into my compost. Plants are doing long division." } },
	-- Pine Park
	{ id = "RangerRick", name = "Ranger Rick", title = "Park Ranger", outfit = "ranger", color = Color3.fromRGB(120, 200, 110),
		lines = { "Pine Park: 400 pines, one lake, zero homework. Let's keep it that way.", "Stay on the trails. Unless something purple is chasing you. Then run." } },
	{ id = "FishermanFinn", name = "Fisherman Finn", title = "Angler", outfit = "fisher", color = Color3.fromRGB(255, 220, 90),
		lines = { "Caught a fish yesterday that could count to ten. Threw it back. Too smart.", "Something glows at the bottom of the lake at night." } },
	{ id = "BirdwatcherBea", name = "Birdwatcher Bea", title = "Bird Nerd", outfit = "bea", color = Color3.fromRGB(150, 210, 140),
		lines = { "Shh! A Lesser Spotted Hall Monitor. Very rare.", "The birds have stopped singing. They're humming the VexCorp jingle." } },
	{ id = "CounselorCody", name = "Counselor Cody", title = "Camp Wannaplaya", outfit = "counselor", color = Color3.fromRGB(255, 160, 70),
		lines = { "Camp Wannaplaya: where every day is recess!", "S'mores at the campfire. Bring your own marshmallow. And courage." } },
	{ id = "ScoutSam", name = "Scout Sam", title = "Scout", outfit = "scout", scale = 0.72, color = Color3.fromRGB(150, 200, 110),
		lines = { "Password? ...Okay, you can come up. Don't tell the grown-ups.", "I've got 27 badges. The 28th is for bonking a goon." } },
	-- VexCorp Industrial
	{ id = "GaryGoon", name = "Gary the Goon", title = "Goon (on a break)", outfit = "goon", color = Color3.fromRGB(190, 130, 255),
		lines = { "Psst. I'm not supposed to be out here. I'm supposed to be stealing kids. Not feeling it.", "The butler's in charge. Yeah. Really." } },
	{ id = "EngineerEllie", name = "Engineer Ellie", title = "VexCorp Engineer", outfit = "engineer", color = Color3.fromRGB(255, 170, 90),
		lines = { "I build Dr. Vex's machines. I'm... having doubts.", "Mutagen X in the tanks, Mutagen X in the pipes. It's in the COFFEE." } },
	{ id = "Robo7", name = "ROBO-7", title = "Reception", outfit = "robot", color = Color3.fromRGB(150, 220, 255),
		lines = { "WELCOME TO VEXCORP. HOMEWORK IS THE FUTURE. HAVE YOU DONE YOURS?", "DR. VEX IS IN A MEETING. SHE IS ALWAYS IN A MEETING." } },
	{ id = "ChiefBrick", name = "Security Chief Brick", title = "VexCorp Security", outfit = "guard", color = Color3.fromRGB(255, 110, 110),
		lines = { "Badge? No badge? ...I'm watching you, Principal.", "Thirty-one goons on my team. Thirty after Gary quits." } },
}

Townsfolk.byId = {}
for _, t in Townsfolk do
	if type(t) == "table" and t.id then Townsfolk.byId[t.id] = t end
end

return Townsfolk
