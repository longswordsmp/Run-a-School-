# Recess Row: the town (design, 2026-09-26)

tomas asked for: quests that lead players through stealing mutations and students from the VexCorp
Lab; more buildings including a top-secret lair; the admin panel back with much more in it; more
events, buses, animations and at least 50 cutscenes and 100 quests; townspeople, houses and a grocery
store in a whole town around the schools (not huge, but lots to explore); areas locked until unlocked;
a huge story with one main villain; better music; smoother UI; progression where there's always
something to do, and Robux to get ahead.

This file is the spec every piece is built against. Coordinates are world studs; +Z is north.

## 1. The villain and the story

**One villain: Dr. Veronica Vex**, CEO of VexCorp. Expelled from Recess Row Elementary in Grade 5
(nobody ever picked her for kickball), she wants recess cancelled forever and homework never to end.
Her tools: the Homework Factory, Mutagen X (the Mutation Lab), Vex Prep Academy, her butler Crumpet,
the goons, the Sugar Baron, and the **Homework Machine**, built in her **Top Secret Lair** under
VexCorp Tower. Her plan: buy the whole town, power the Machine with Mutagen X and the Tiny
Professor's brain, and end recess for every kid in every universe.

The story runs in five acts across the 11 chapters (the chapters and Board reviews stay as they are;
the story quests and cutscenes are layered on top):

| Act | Chapters | What happens | Opens |
|---|---|---|---|
| 1 New Principal | tutorial, 1 | Vex's limo sizes up your school; the town learns a new principal is in | Downtown |
| 2 Neighbours | 2, 3 | VexCorp flyers and posters all over Maple Heights; parents worried; a lab tube truck crashes in Pine Park, a mutant kid runs loose; you learn about Mutagen X | Maple Heights, Pine Park, the Mutation Lab |
| 3 The Rival | 4, 5, 6 | Vex opens Vex Prep across the street and starts poaching kids; the town takes sides | Vex Prep |
| 4 The Corporation | 7, 8, 9 | You get inside VexCorp Industrial: warehouses of homework, Crumpet's doubts, the Machine's blueprints | VexCorp Industrial |
| 5 The Lair | 10, 11, finale | The Machine wakes; into the Top Secret Lair under the Tower; the showdown | the Top Secret Lair |

## 2. The map

```
                 z +560 ┌──────────────────────────────────────────────┐
                        │            MAPLE HEIGHTS (houses)            │
                 z +234 ├──────────────  ring road  ──────────────────┤
  PINE PARK      x -534 │   plots 1-4   RecessCommons Factory Shack    │ x +534   VEXCORP
  (pond, camp,          │   Lab(NW)       ─── Recess Row street ───    │          INDUSTRIAL
   treehouse)           │   plots 5-8   Closet  Fountain  DistrictOff  │          (Tower, lair
                        │                                 VexPrep(SE)  │           underneath)
                 z -234 ├──────────────  ring road  ──────────────────┤
                        │         DOWNTOWN (grocery, town hall...)     │
                 z -560 └──────────────────────────────────────────────┘
                     x -800                                         x +800
```

- **Main area** (open from the start): x -510..510, z -215..215, plus the ring road around it
  (24 wide, centre lines x = ±522 and z = ±222). The street connects to the ring road at both ends
  (west past the bus stop, east behind Detention along z = 0).
- **Downtown** (south, z -234..-560): the avenue runs south along x = 0; Market Street crosses it at
  z = -390. Fresh Mart Grocery, Town Hall, the Library, Pixel Palace Arcade, the Burger Diner, the
  Police Station, Scoops Ice Cream, the Post Office, Recess Row Bank, Hammer & Nail Hardware, the
  town square with a clock tower.
- **Maple Heights** (north, z 234..560): the road runs north along x = 0; Maple Lane (z = 330) and
  Oak Avenue (z = 450) cross it; about 12 houses with yards, a fire station, a clinic, a corner park.
- **Pine Park** (west, x -534..-800): a pond with a boathouse and bridge, the ranger station, a
  playground, the campground, the treehouse, pine forest trails. The Mutation Lab (x -474..-366,
  z 42..150) is fenced off from the main area and opens with Act 2.
- **VexCorp Industrial** (east, x 534..800): VexCorp Tower (the HQ), two warehouses of homework, a
  container yard, the loading dock, security booths. **The Top Secret Lair** is under the Tower,
  reached by the executive elevator (a cavern built underground at y -160).
- **Vex Prep** (x 372..482, z -170..-45) opens with Act 3.

### Locks
Each district has an arch gate on the ring road with a sign; while locked, the player's own client
draws a glowing barrier with "LOCKED: <how to open>" (other players' barriers are theirs), and the
server sends anyone found inside a locked zone back to the street. A locked district's gate also
offers **UNLOCK NOW** for Robux (a developer product per district). Unlocks are saved per player
(`p.areas`), co-op members use the host's school chapter but their own unlocks.

| Zone | Opens with |
|---|---|
| Downtown | story quest S02 (end of the tutorial) |
| Maple Heights | story quest S05 (chapter 2) |
| Pine Park | story quest S08 (chapter 3) |
| Mutation Lab | story quest S10 (chapter 3) |
| Vex Prep | story quest S15 (chapter 5) |
| VexCorp Industrial | story quest S21 (chapter 7) |
| Top Secret Lair | story quest S27 (chapter 10) |

## 3. Townspeople (NPC roster)

Rigs like the teachers (R15, colour + outfit props from StudentProps). Each has an id, a name, a
title, an outfit, a post (where they stand, facing) and optionally a patrol (points they wander
between). Quest givers show a gold "!" when they have a quest for you, "?" when you're due back.

- Main area: Mr. Wobblesworth (fountain), Janitor Stan (gear stall), Otis (bus), Lunch Lady Loretta
  (Recess Commons), Hall Monitor Hector, Crumpet (appears in story beats).
- Downtown: Mayor Maxine Goodwin (Town Hall), Grocer Gus (Fresh Mart), Officer Penny (Police),
  Mr. Page the librarian (Library), Pixel Pete (Arcade), Rosa the cook (Diner), Mo the mail carrier
  (walks Market St), Scoops (Ice Cream), Mr. Pennington the banker (Bank), Hank (Hardware).
- Maple Heights: Grandma Rose (bakes), Mr. and Mrs. Patel (parents), Lil' Timmy (lost cat),
  Coach Doug (a dad), Skye (teen skater), Old Man Grumbles (hates noise), Nurse Nina (clinic),
  Firefighter Frank (fire station), Mrs. Kim (gardener).
- Pine Park: Ranger Rick (ranger station), Fisherman Finn (dock), Birdwatcher Bea, Counselor Cody
  (campground), Scout Sam (treehouse).
- VexCorp Industrial: Gary the Goon (a goon who wants out), Engineer Ellie (a VexCorp engineer who
  secretly helps), Receptionist ROBO-7 (Tower lobby), Security Chief Brick.
- The Lair: Dr. Veronica Vex, Crumpet, lair guards.

## 4. Quests: the engine and the format

A quest is data (`Shared/Quests.lua`). The engine (`Server/TownQuestService.lua`) tracks progress per
player in their own save (`p.tq = { active = {}, done = {}, prog = {} }`). One story quest and up to
three town quests run at once; one is tracked (top-left card + the beam).

```lua
{ id = "D03", line = "town" | "story", title = "...", giver = "GrocerGus",
  area = "Downtown",            -- must be unlocked
  needs = { chapter = 1, quests = { "D02" } },
  intro = { { "GROCER GUS", "GrocerGus", "line" }, ... },   -- the conversation that offers it
  steps = { ...objectives, in order... },
  outro = { { speaker, portrait, line }, ... },              -- on hand-in (optional)
  reward = { incomeSecs = 120, min = 500, candy = 5, gear = { SmokeBomb = 2 }, kid = "Rare",
             vials = 1, unlock = "MapleHeights", cutscene = "S05_Reveal" },
  cutscene = "SceneId",          -- played when the quest starts (optional)
}
```

Objective kinds (`steps`), each `{ kind = ..., text = "shown on the tracker", ... }`:

| kind | fields | done when |
|---|---|---|
| talk | npc | you talk to that NPC (their prompt) |
| visit | place (a named spot), r | you stand within r studs of it |
| collect | item, n, spots = { place names } | you pick up n items (only you see them) |
| deliver | item, to (npc) | you talk to `to` while carrying item (given by the step before) |
| signal | signal, n, arg? | a game signal fires n times (see list) |
| chase | runner (npc look), route (place names) | you bonk the runner with the Ruler |
| goons | place, n | you knock out n goons spawned at place |
| cutscene | scene | the scene has played |

Signals available (the game fires these today): enroll, collect (amount), sell, stole, stealFailed,
bonkSave, goonKO, raidDefended, eagleEye, rescued, kidCaptured, labTake, mutantEscaped, mutateKid,
rivalTake, rivalEscaped, rivalCaught, fileFound, gearBuy, gearUse, hire, supply, desks, upgrade,
review, missionWon, secretWon, crewJob, crewJoin, quizRight, daily, letter, nameSchool, lock,
trophy, ticket, graduate, recess.

Named places (`Shared/Places.lua`): every NPC post plus landmarks (the grocery's back door, the
pond dock, the Lab's tube room, Vex Prep's gate, the Tower lobby...). Quests only reference places
and NPCs that exist in these tables.

**100 quests**: 30 story quests (S01-S30, the acts above, every district unlock and the finale) and
70 town quests (Downtown 20, Maple Heights 20, Pine Park 14, VexCorp Industrial 10, the Lab and
Vex Prep 6), including the mutation line tomas asked for: steal a mutant out of the Lab, rescue
kids from VexCorp, mutate your own kids with vials.

## 5. Cutscenes: the engine and the format

Data in `Shared/Cutscenes.lua`, played by `Client/Cutscene.client.lua` (`Remotes.Cutscene:FireClient
(player, "Play", id)`); each plays once per player unless replayed from the Quest Log.

```lua
Scene = { title = "optional big title", letterbox = true,
  actors = { { id = "Vex", look = "vex", at = Vector3, face = Vector3, anim = "point" } },
  shots = {
    { from = Vector3, to = Vector3, push = Vector3?, time = 4,
      caption = "text"?, say = { speaker, portrait, line }?, sfx = "..."?, shake = 0.3? },
  } }
```

**50 cutscenes**: act openers and closers (10), every district reveal (7), story quest moments
(18), the lair and the showdown (5), first sight of each special bus (6), first time of the big
events (4).

## 6. Build order

1. World: expanded ground, ring road, gates, AreaService (locks, client barriers, Robux unlock).
2. Districts one at a time: Downtown, Maple Heights, Pine Park, VexCorp Industrial, the Lair.
3. Townspeople: outfits, posts, patrols, talk prompts, markers.
4. Engines: TownQuestService, Quest Log + tracker, data-driven cutscenes.
5. Content: the 100 quests and 50 cutscenes, checked against the places and NPCs that exist.
6. Admin panel, events, buses, animations, music, UI polish, Robux shortcuts, a progression check.
