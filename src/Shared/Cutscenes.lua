-- ReplicatedStorage.Shared.Cutscenes
-- Data-driven cutscenes (docs/TOWN.md section 5), played by Client/Cutscene on
-- Remotes.Cutscene:FireClient(player, "Play", id, { quest = id? }). A scene:
--   clock = 14 (time of day while it plays), music = "heroes", letterbox = true (default)
--   actors = { { id, look = template id ("player" = a copy of you), at = Vector3 (the ground),
--               face = Vector3, anim = "idle" | "sit" | "dance" ..., scale } }
--   shots  = { { from, to, push?, pushTo?, time?, hold?, title?, titleColor?, caption?,
--               say = { SPEAKER, portraitId, line }?, sfx?, shake?, confetti?,
--               emotes = { { actorId, "wave" } }, moves = { { actorId, Vector3, speed } } } }
-- A shot with no from/to keeps the camera where it is. Each shot waits for its line (or `hold`
-- seconds); a click skips ahead.
-- Named places (Shared/Places) instead of coordinates:
--   actor { id, look, place = "OfficerPenny" }     at that post, facing the way it faces
--   shot  { place = "TownHall", cam = "close" | "wide" | "high" | "low" | "side" | "back", side = 1 | -1 }
--         (the camera sits in front of the place, relative to the way it faces, and pushes in slowly)
--   moves { { actorId, "PlaceName", speed } }
local V = Vector3.new
local Cutscenes = {}

-- every place and actor a scene names must exist (the content checks run this)
function Cutscenes.validate(Places, templates)
	local errs = {}
	for id, s in Cutscenes do
		if type(s) ~= "table" then continue end
		if not s.shots or #s.shots == 0 then table.insert(errs, id .. ": no shots") end
		for i, sh in s.shots or {} do
			if sh.place and not Places.get(sh.place) then table.insert(errs, ("%s shot %d: unknown place %s"):format(id, i, sh.place)) end
			for _, mv in sh.moves or {} do
				if type(mv[2]) == "string" and not Places.get(mv[2]) then table.insert(errs, ("%s shot %d: unknown move target %s"):format(id, i, mv[2])) end
			end
			if sh.say and (type(sh.say[3]) ~= "string" or #sh.say ~= 3) then table.insert(errs, ("%s shot %d: say needs speaker, portrait, line"):format(id, i)) end
		end
		for _, a in s.actors or {} do
			if a.place and not Places.get(a.place) then table.insert(errs, ("%s actor %s: unknown place %s"):format(id, a.id, a.place)) end
			if not a.place and not a.at then table.insert(errs, ("%s actor %s: no place or at"):format(id, a.id)) end
			if templates and a.look ~= "player" and not templates[a.look or a.id] then table.insert(errs, ("%s actor %s: no template %s"):format(id, a.id, tostring(a.look or a.id))) end
		end
	end
	return errs
end

Cutscenes.S01_Downtown = {
	clock = 13,
	music = "heroes",
	actors = {
		{ id = "MayorMaxine", look = "MayorMaxine", at = V(6, 2.2, -486), face = V(6, 2.2, -470) },
	},
	shots = {
		{ from = V(0, 70, -236), to = V(0, 8, -400), push = V(0, 40, -300), time = 6, hold = 3.2,
			title = "DOWNTOWN", caption = "Shops, the town square and Town Hall. Recess Row's beating heart." },
		{ from = V(60, 30, -330), to = V(85, 12, -312), push = V(70, 22, -322), time = 5, hold = 2.6,
			caption = "The clock tower has told recess time for ninety years." },
		{ from = V(12, 7.5, -470), to = V(6, 6, -486), push = V(9, 6.8, -476), time = 6,
			emotes = { { "MayorMaxine", "wave" } },
			say = { "MAYOR MAXINE", "MayorMaxine", "Welcome to Downtown, Principal! If anyone needs a hand, they'll have a \"!\" over their head." } },
		{ say = { "MAYOR MAXINE", "MayorMaxine", "Help my townsfolk and the town will help your school. That's how Recess Row works!" } },
	},
}

Cutscenes.S02_Flyer = {
	clock = 17.5,
	actors = {
		{ id = "OfficerPenny", look = "OfficerPenny", at = V(198, 0, -372), face = V(198, 0, -390) },
		{ id = "Vex", look = "Vex", at = V(208, 0, -400), face = V(198, 0, -372), scale = 1.05 },
	},
	shots = {
		{ from = V(198, 6, -386), to = V(198, 5, -372), push = V(198, 5.5, -381), time = 5,
			say = { "OFFICER PENNY", "OfficerPenny", "'Homework is the future. Enrol at Vex Prep.' Signed... Dr. Veronica Vex." } },
		{ from = V(220, 5, -410), to = V(208, 5, -400), push = V(214, 5, -405), time = 5, sfx = "GavelBig",
			title = "DR. VERONICA VEX", titleColor = Color3.fromRGB(205, 150, 255), titleTime = 3,
			emotes = { { "Vex", "laugh" } },
			say = { "DR. VERONICA VEX", "Vex", "Recess? A waste of perfectly good homework time. This town is MINE, little principal." } },
		{ moves = { { "Vex", V(260, 0, -410), 9 } }, hold = 2.5,
			caption = "The purple limo speeds off towards VexCorp Industrial...", captionColor = Color3.fromRGB(205, 150, 255) },
	},
}

return Cutscenes
