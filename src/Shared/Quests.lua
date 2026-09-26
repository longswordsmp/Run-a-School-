-- ReplicatedStorage.Shared.Quests
-- The town quests and the story (docs/TOWN.md section 4). Data only: Server/TownQuestService runs
-- them, Client/QuestLog shows them. A quest:
--   id, line ("story" | "town"), title, giver (a Townsfolk id; nil + auto = starts by itself),
--   area (must be open), needs = { tutorial, chapter, tier, quests = { ids } },
--   intro = { { SPEAKER, portraitId, line } ... }   the conversation that offers it
--   steps = { { kind, text, ... } ... }              in order (kinds below)
--   outro = { { SPEAKER, portraitId, line } ... }    on the last step (optional)
--   reward = { incomeSecs, min, candy, vials, gear = { id = n }, unlock = areaId, scene = cutsceneId }
-- Step kinds:
--   talk     npc, lines?          talk to them (lines = what they say when you do)
--   deliver  npc, item, lines?    talk to them with the item from an earlier step
--   visit    place, r?            stand within r studs (default 12) of the place
--   collect  item, spots = {places}, n?   pick up the items only you can see (n defaults to #spots)
--   signal   signal, n, arg?, sum?        a game signal fires n times (sum: add its amount instead)
--   goons    place, n              knock out n VexCorp goons that jump you there
--   chase    runner (outfit), from (place), route = {places}   bonk the runner before they get away
--   scene    scene                 a cutscene plays
local Quests = { list = {}, byId = {} }

local function Q(q)
	table.insert(Quests.list, q)
	Quests.byId[q.id] = q
end
local function say(speaker, portrait) return function(line) return { speaker, portrait, line } end end

local MAYOR = say("MAYOR MAXINE", "MayorMaxine")
local PENNY = say("OFFICER PENNY", "OfficerPenny")
local GUS = say("GROCER GUS", "GrocerGus")
local ROSE = say("GRANDMA ROSE", "GrandmaRose")
local TIMMY = say("LIL' TIMMY", "LilTimmy")
local FINN = say("FISHERMAN FINN", "FishermanFinn")

---------------------------------------------------------------------------
-- STORY, Act 1: New Principal
---------------------------------------------------------------------------
Q({ id = "S01", line = "story", title = "Welcome to Recess Row", auto = true, area = "Downtown",
	needs = { tutorial = true },
	intro = {
		MAYOR("Principal! Mayor Maxine here, calling from Town Hall. Welcome to Recess Row!"),
		MAYOR("The whole town's buzzing about the new school. Come downtown and say hello. Follow the arrow!"),
	},
	steps = {
		{ kind = "visit", place = "DowntownGate", r = 16, text = "Go through the DOWNTOWN gate (south)" },
		{ kind = "talk", npc = "MayorMaxine", text = "Meet Mayor Maxine at Town Hall",
			lines = {
				MAYOR("There you are! Welcome, welcome. Recess Row has had recess for ninety years."),
				MAYOR("But lately... a purple limo keeps circling the schools. I don't like it one bit."),
				MAYOR("Talk to Officer Penny at the police station. She's been keeping an eye on it."),
			} },
	},
	reward = { incomeSecs = 60, min = 300, candy = 5 },
})

Q({ id = "S02", line = "story", title = "The Purple Limo", giver = "OfficerPenny", area = "Downtown",
	needs = { quests = { "S01" } },
	intro = {
		PENNY("You're the new principal? Good. I need someone the limo won't suspect."),
		PENNY("It stopped in three places this week. Find what it left behind."),
	},
	steps = {
		{ kind = "collect", item = "Purple Flyer", spots = { "TownSquare", "Bank", "PostOffice" }, text = "Find what the limo left behind" },
		{ kind = "deliver", npc = "OfficerPenny", item = "Purple Flyer", text = "Bring the flyers to Officer Penny",
			lines = {
				PENNY("'HOMEWORK IS THE FUTURE. Enrol at VEX PREP.' Signed... Dr. Veronica Vex."),
				PENNY("VexCorp. They bought half of the industrial district last year. Now they want the schools."),
			} },
	},
	outro = { PENNY("Keep your gate locked, Principal. And keep your kids close.") },
	reward = { incomeSecs = 90, min = 500, candy = 5 },
})

---------------------------------------------------------------------------
-- TOWN: Downtown
---------------------------------------------------------------------------
Q({ id = "D01", line = "town", title = "Clean-Up on Aisle 3", giver = "GrocerGus", area = "Downtown",
	needs = { quests = { "S01" } },
	intro = {
		GUS("Oh thank goodness, a grown-up! A kid knocked over my whole apple pyramid."),
		GUS("Apples everywhere! Round up three for me, would you? I'll make it worth your while."),
	},
	steps = {
		{ kind = "collect", item = "Apple", spots = { "FreshMartAisles", "FreshMartLot", "FreshMartDoor" }, text = "Pick up the runaway apples" },
		{ kind = "deliver", npc = "GrocerGus", item = "Apple", text = "Give the apples back to Gus",
			lines = { GUS("Perfect! Not a bruise on them. Here, for your trouble.") } },
	},
	reward = { incomeSecs = 45, min = 250, candy = 3 },
})

Q({ id = "D02", line = "town", title = "Enrolment Drive", giver = "MayorMaxine", area = "Downtown",
	needs = { quests = { "S01" } },
	intro = {
		MAYOR("A town is only as good as its schools. Show me yours can grow!"),
		MAYOR("Enrol five new kids off the bus and I'll put your school in the town newsletter."),
	},
	steps = {
		{ kind = "signal", signal = "enroll", n = 5, text = "Enrol 5 kids off the Welcome Bus" },
		{ kind = "talk", npc = "MayorMaxine", text = "Tell Mayor Maxine",
			lines = { MAYOR("Five! The newsletter will say 'best principal since the last one'. That's high praise.") } },
	},
	reward = { incomeSecs = 120, min = 600, candy = 5 },
})

---------------------------------------------------------------------------
-- TOWN: Maple Heights
---------------------------------------------------------------------------
Q({ id = "M01", line = "town", title = "Cookie Delivery", giver = "GrandmaRose", area = "MapleHeights",
	intro = {
		ROSE("Oh, you must be the new principal! I baked far too many cookies again."),
		ROSE("Would you take a batch to Lil' Timmy down the lane? He's been sad since his cat went missing."),
	},
	steps = {
		{ kind = "deliver", npc = "LilTimmy", item = "Cookies", text = "Take Grandma Rose's cookies to Lil' Timmy",
			lines = {
				TIMMY("COOKIES! ...Grandma Rose is the best."),
				TIMMY("Mr. Whiskers ran off toward the park. Nobody believes me but he was chasing a PURPLE butterfly."),
			} },
	},
	reward = { incomeSecs = 45, min = 250, candy = 3 },
})

---------------------------------------------------------------------------
-- TOWN: Pine Park
---------------------------------------------------------------------------
Q({ id = "P01", line = "town", title = "Something in the Lake", giver = "FishermanFinn", area = "PinePark",
	intro = {
		FINN("Every night something glows at the bottom of the lake. Purple. Every night!"),
		FINN("Walk the shore for me, would you? Round the reeds on the far side. I'll mind the dock."),
	},
	steps = {
		{ kind = "visit", place = "LakeShore", r = 14, text = "Walk the shore of Lake Wannaswim" },
		{ kind = "collect", item = "Glowing Vial", spots = { "Boathouse" }, text = "Find the glowing thing by the boathouse" },
		{ kind = "deliver", npc = "FishermanFinn", item = "Glowing Vial", text = "Show Finn what you found",
			lines = {
				FINN("A vial. MUTAGEN X, it says. Property of VexCorp."),
				FINN("Keep it. Something tells me you'll need it more than the fish do."),
			} },
	},
	reward = { incomeSecs = 60, min = 400, vials = 1 },
})

---------------------------------------------------------------------------
-- checks (tests and the content workflow run these)
---------------------------------------------------------------------------
local KINDS = { talk = true, deliver = true, visit = true, collect = true, signal = true, goons = true, chase = true, scene = true }

-- returns a list of problems: unknown places or people, missing fields, needs that point nowhere
function Quests.validate(Places, Townsfolk, areas)
	local errs = {}
	local function err(q, msg) table.insert(errs, (q.id or "?") .. ": " .. msg) end
	local seen = {}
	for _, q in Quests.list do
		if seen[q.id] then err(q, "duplicate id") end
		seen[q.id] = true
		if q.line ~= "story" and q.line ~= "town" then err(q, "line must be story or town") end
		if not q.title then err(q, "no title") end
		if q.giver and not Townsfolk.byId[q.giver] then err(q, "giver " .. tostring(q.giver) .. " is not a townsperson") end
		if not q.giver and not q.auto then err(q, "no giver and not auto") end
		if q.area and areas and not areas[q.area] then err(q, "unknown area " .. q.area) end
		for _, need in (q.needs and q.needs.quests) or {} do
			if not Quests.byId[need] then err(q, "needs unknown quest " .. need) end
		end
		if not q.steps or #q.steps == 0 then err(q, "no steps") end
		for i, s in q.steps or {} do
			local where = "step " .. i .. " "
			if not KINDS[s.kind] then err(q, where .. "unknown kind " .. tostring(s.kind)) end
			if not s.text then err(q, where .. "no text") end
			if (s.kind == "talk" or s.kind == "deliver") and not Townsfolk.byId[s.npc or ""] then err(q, where .. "npc " .. tostring(s.npc) .. " is not a townsperson") end
			if s.kind == "visit" and not Places.get(s.place or "") then err(q, where .. "unknown place " .. tostring(s.place)) end
			if s.kind == "goons" and not Places.get(s.place or "") then err(q, where .. "unknown place " .. tostring(s.place)) end
			if s.kind == "collect" then
				if not s.spots or #s.spots == 0 then err(q, where .. "collect with no spots") end
				for _, sp in s.spots or {} do
					if not Places.get(sp) then err(q, where .. "unknown spot " .. sp) end
				end
			end
			if s.kind == "chase" then
				for _, sp in s.route or {} do
					if not Places.get(sp) then err(q, where .. "unknown route point " .. sp) end
				end
			end
			if s.kind == "signal" and (type(s.signal) ~= "string" or type(s.n) ~= "number") then err(q, where .. "signal needs signal and n") end
		end
	end
	return errs
end

return Quests
