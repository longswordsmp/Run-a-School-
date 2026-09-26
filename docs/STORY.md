# The story of Recess Row (outline, 2026-09-26)

One villain: **Dr. Veronica Vex**, CEO of VexCorp, expelled from Recess Row Elementary in Grade 5
(nobody picked her for kickball). She wants recess cancelled forever and homework without end. Her
people: **Crumpet** the butler (loyal, secretly kind), the **goons** (mostly bored), **Security Chief
Brick**, the **Sugar Baron** (a hired candy smuggler, comic), **ROBO-7** the receptionist robot. Her
machine: the **Homework Machine**, in the **Top Secret Lair** under VexCorp Tower. Its fuel:
Mutagen X and the brain of the **Tiny Professor** (a genius kid Vex kidnapped).

The player's allies: **Mr. Wobblesworth** (retired principal, mentor), **Janitor Stan** (spy
master), **Mayor Maxine**, **Officer Penny**, and inside VexCorp **Engineer Ellie** (has doubts) and
**Gary the Goon** (wants out).

Tone: bright, silly, kid-friendly. Nobody gets hurt: goons are bonked and run off, kids are "kidnapped
to do homework", the worst threat is NO RECESS. Lines are short (one or two sentences each), every
character has a voice (the Mayor is peppy, Penny is dry, Gus is fussy, Vex is grand and petty,
Crumpet is very polite, Gary is lazy, Ellie is nervous, ROBO-7 SHOUTS IN CAPITALS).

## Places and people the quests may use

Every place is a name in `Shared/Places.lua` (`Places.npc` posts and `Places.spot`), every person a
townsperson in `Shared/Townsfolk.lua`. Quest givers and talk targets must be townspeople (the story
cast Wobblesworth/Stan/Vex speak in lines and cutscenes, not as quest givers). The HQ floors below are
reached through the staff elevator; their challenges fire the signal `hqFloor` with the floor number
when cleared (a step `{ kind = "signal", signal = "hqFloor", arg = 3, n = 1 }`).

## The five acts (30 story quests, S01-S30)

| # | Title | Giver | What happens (steps) | Reward / opens |
|---|---|---|---|---|
| **Act 1** | **New Principal** (after the tutorial) | | | |
| S01 | Welcome to Recess Row | auto (Mayor calls) | visit DowntownGate, scene S01_Downtown, talk MayorMaxine | cash, candy |
| S02 | The Purple Limo | OfficerPenny | collect 3 Purple Flyers (TownSquare, Bank, PostOffice), deliver to Penny, scene S02_Flyer, talk Penny | cash, candy |
| S03 | Hall of Records | MrPage | visit Library; collect 3 old yearbook pages (Library, TownHall, PostOffice); deliver to MrPage: Veronica Vex's Grade 5 yearbook: "Most Likely To Cancel Recess" | cash |
| S04 | A Principal's Promise | MayorMaxine | signal enroll 10; talk MayorMaxine (she gives you a town key); scene S04_TownKey | cash, candy |
| **Act 2** | **Neighbours** (chapter 2-3) | | | opens Maple Heights, Pine Park, the Lab |
| S05 | Flyers on Maple Lane | MrsPatel | visit MapleGate; collect 5 VexCorp flyers (MapleLane, OakAvenue, Playground, Clinic, FireStation); talk MrPatel | opens MapleHeights (if not yet) |
| S06 | Worksheets for Breakfast | NurseNina | talk LilTimmy (he wants MORE homework, suspicious); visit Playground (empty); deliver a "Mutagen-stained worksheet" to NurseNina | cash |
| S07 | The Crash in the Park | RangerRick | scene S07_TruckCrash (a VexCorp lab truck crashed in Pine Park); visit ParkPlaza; goons at PicnicGrounds n=3 | opens PinePark |
| S08 | Mutagen X | FishermanFinn | collect 3 Glowing Vials (LakeShore, Boathouse, BirdHide); deliver to FishermanFinn; talk BirdwatcherBea (the birds hum the VexCorp jingle) | 1 vial |
| S09 | The Runaway Mutant | ScoutSam | chase the goon carrying the mutant kid from TreehouseFoot along ParkSouthTrail to ParkPlaza; talk ScoutSam | opens Lab |
| S10 | Inside the Mutation Lab | RangerRick | visit LabGate; signal labTake 1 (steal a mutant kid from the Lab); talk RangerRick | 2 vials |
| **Act 3** | **The Rival** (chapter 4-6) | | | opens Vex Prep |
| S11 | Across the Street | MayorMaxine | scene S11_VexPrepOpens; visit VexPrepGate | opens VexPrep |
| S12 | Poached | MrsPatel | signal rivalTake 1 (take a kid back from Vex Prep) | cash |
| S13 | The Sugar Baron | Scoops | goons at IceCream n=2; chase the Sugar Baron's courier (goon) from IceCream along MarketStreetWest; talk Scoops | candy |
| S14 | Town Hall Vote | MayorMaxine | talk 3 townspeople for their vote (GrocerGus, HankHardware, MrPennington); talk MayorMaxine; scene S14_TheVote | cash |
| S15 | Crumpet's Letter | GrandmaRose | talk GrandmaRose (Crumpet left a letter at her bakery: "Help the Tiny Professor"); visit RosesPorch; scene S15_CrumpetLetter | cash |
| S16 | Defend the School | OfficerPenny | signal raidDefended 1 (beat a goon raid on your school) | cash, candy |
| **Act 4** | **The Corporation** (chapter 7-9) | | | opens VexCorp Industrial and the HQ |
| S17 | Through the Checkpoint | OfficerPenny | visit IndustrialGate; talk ChiefBrick (turned away); talk GaryGoon (he'll help if you get him a burger); deliver burger (from RosaCook) to GaryGoon -> Visitor Badge | opens Industrial |
| S18 | Welcome to VexCorp | GaryGoon | visit TowerLobby; talk Robo7 (VISITOR BADGE ACCEPTED); scene S18_StaffElevator | the staff elevator |
| S19 | The Cubicle Farm | GaryGoon | signal hqFloor 2 (sneak past the office guards, find the keycard) | cash |
| S20 | The Laser Vault | EngineerEllie | talk EngineerEllie (she tells you the switch order); signal hqFloor 3 | cash |
| S21 | Project H.M. | EngineerEllie | signal hqFloor 4 (hack three servers: the Homework Machine blueprints); scene S21_Blueprints | cash, vial |
| S22 | Mutagen Labs | NurseNina | signal hqFloor 5 (free the kids in the pods, steal the mutation sample) | 2 vials |
| S23 | The Barracks | GaryGoon | signal hqFloor 6 (waves of goons, then Crumpet) ; scene S23_CrumpetTurns (Crumpet switches sides) | cash, candy |
| S24 | The Executive Suite | EngineerEllie | signal hqFloor 7 (crack Vex's vault: the code from clues on the floors); scene S24_VexsOffice | opens the Lair |
| **Act 5** | **The Lair** (chapter 10-11, finale) | | | |
| S25 | Going Down | Robo7 | visit ExecutiveElevator; visit LairElevator; scene S25_TheLair | |
| S26 | Free the Kids | EngineerEllie | visit LairCages; signal rescued 3 | cash |
| S27 | The Tiny Professor | EngineerEllie | visit LairPod; scene S27_Professor | |
| S28 | Pull the Plug | EngineerEllie | visit LairVats; goons at LairCore n=5 | cash |
| S29 | Face Dr. Vex | MayorMaxine | visit LairThrone; scene S29_Showdown | |
| S30 | Recess Forever | MayorMaxine | talk MayorMaxine; scene S30_Parade (the town parade; Vex, rescued by her own kids, finally gets picked for kickball) | big cash, candy, a Legendary letter |

(The chapters and Board reviews stay as they are; the story quests sit on top. `needs` for each act:
Act 2 chapter 2, Act 3 chapter 4, Act 4 chapter 7, Act 5 chapter 10, each quest also needs the one
before it.)

## The alien arc (the rarest prestige)

After the first GOLD prestige, strange lights over Pine Park at night. Birdwatcher Bea sees them first.
A 6-quest side story (X01-X06): crop-circle patterns in the Community Garden, a humming lake, a
missing cow-shaped mailbox, a night watch at the Lookout, then the **abduction**: a UFO beams the
principal up (cutscene), a spaceship interior (a small level), the aliens want to see a REAL school
(they think Earth schools are all homework, thanks to VexCorp broadcasts). Win them over (a quiz and
a recess demo) and they turn your school **ALIEN** (the cosmic finish) on your next prestige.

## The HQ floors (VexCorp Tower, through the staff elevator)

| Floor | Name | The challenge |
|---|---|---|
| 1 | Lobby | ROBO-7 checks your Visitor Badge; the staff elevator |
| 2 | The Cubicle Farm | a maze of cubicles, patrolling office guards with vision cones; find the keycard in one of three managers' offices; caught = back to the elevator |
| 3 | The Laser Vault | sweeping and blinking laser walls; three switches in the right order to open the vault door |
| 4 | The Server Farm | dark aisles of glowing servers, rotating cameras; hack three terminals (hold) unseen |
| 5 | Mutagen Labs | vats and pods: free the kids from the pods, grab the mutation sample; acid floor, moving platforms, hazmat guards |
| 6 | The Barracks | a goon arena: three waves, then Crumpet himself |
| 7 | The Executive Suite | Vex's office: find the three code digits, open the vault, take the Executive Keycard (the Lair) |
