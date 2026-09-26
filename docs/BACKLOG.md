# Run a School: everything tomas has asked for

One list, in the order it gets worked. Each item is done by hand, one at a time, and only marked
done after it's been played in Studio and checked on screen. "Built, not verified" means exactly that.

## P0: broken (blocks play)

- [ ] The Vex Prep Job gets stuck after you steal the kid: it tells you to go back into the sewer and you can't progress.
- [ ] Carrying a kid gets you stuck in some places (the kid over your head is too big for doorways).
- [ ] The game is laggy. Measure first (server and client frame times, part counts, what runs every frame), then fix the worst.

## P1: first impressions

- [ ] The street doesn't make sense: a red carpet laid over a road, and the kids off the bus walk into Detention. Replace it with a proper drop-off: the bus stops at a stop, kids wait on a sidewalk plaza, unpicked kids go home or back on the bus. Nobody walks into Detention.
- [ ] An opening cutscene: how you get the school.
- [ ] The story has to make sense: introduce VexCorp, Dr. Vex and Crumpet BEFORE they do anything (not "some random dude named Crumpet stealing kids"); every event has a reason the player has been shown. Plan: you arrive on Otis's bus, Wobblesworth (retiring) hands you the keys to the empty old school; Vex's limo glides past with Crumpet driving and Wobblesworth explains who she is and what she wants; Crumpet's raid then opens with "Dr. Vex sends her compliments..."; Skater Kid is your first transfer student, snatched by Vex before he reached you.
- [ ] A tutorial that really teaches the game: earn tuition, buy better kids, sell old kids to make room for better ones, upgrades, the gate, the Board.
- [ ] A way to hide the GUI (and the guide arrow and trail) when you want to.
- [ ] Remove every leftover "coming soon" / unfinished thing (the Homework Factory sign, "Recess is cancelled", and the rest: find them all).
- [ ] Vex Prep is missing one side of its roof.
- [ ] A Vex Prep showcase cutscene that really shows the rival school off.
- [ ] More cutscenes, and better ones.

## P2: quality, one thing at a time

- [ ] Hoverboard: the board model and a proper riding pose and motion.
- [ ] Gear (Smoke Bomb, Whoopee Cushion, Energy Drink, Cardboard Box): models, held look, use animations.
- [ ] NPCs hold items weirdly (props through hands, wrong grips; the Ruler in your own hand too).
- [ ] Recess Commons: the sign blocks the path; the playground is awful.
- [ ] The Confiscation Closet is poorly made and makes no sense.
- [ ] Detention sits in the middle of the road (move it, make it make sense).
- [ ] Other buildings' interiors and decor.
- [ ] Schools built like real schools: hallways, classrooms, office, cafeteria, gym, library; less cluttered.
- [ ] Bigger plots, or a way to expand your plot.
- [ ] VexCorp HQ a lot bigger.
- [ ] UI / GUI pass across every screen.
- [ ] Animations (walks, sits, emotes, carrying).
- [ ] The storyline: make it hang together from the first minute.

## P3: new things

- [ ] Upgrading your school opens new areas you can walk into: gymnasium, library.
- [ ] A cafeteria where the kids are fed lunch.
- [ ] A field or playground that changes with your school level.
- [ ] A school sports team.
- [ ] Custom school-branded buses.
- [ ] "Everything a school would have", kept simple.
- [ ] The town: a lot more in it, like an actual town, every building detailed.
- [ ] Robux purchases that help gameplay, integrated sensibly.
- [ ] Hidden easter eggs.
- [ ] Chapter 2 and on (after Chapter 1 is perfect).

## Done and checked in Studio (screenshots or measurements)

- Ground coins removed; old neon arrow and beam removed.
- Guide: yellow 3D arrow over the target, a chevron trail on the ground along a walkable path, an edge-of-screen chevron. (tomas's "neon blue I hate it": the cyan guide is gone.)
- Tuition pads back to the original bright green; the "+ DESK" floor tape removed.
- Store and Daily always unlocked.
- Upgrades available from the First Morning's "Build 4 desks".
- Hall Monitor: Hector's chase gives you one. A strong student before the Board: the tiara chase gives the Drama Queen.
- First Morning + Chapter 1 quest chain, played end to end through the debug bridge (not by hand yet).
- Lock-the-gate bug (locking early): the step completes from state.
- Admin panel: fly, speed, cash, tier, unlock all, gear, teleport, kick, ban. (kick/ban not tested with a second player.)
- Talking makes mumble sounds (measured: 12 blips for a 37-letter line).
- Cheating mechanic removed. Window boards removed.
- Stolen kids are carried in your arms, not on your head.
- Shop unlocks at Chapter 1's first step.
- Classroom rebuilt (ceiling, bunting, clock, drawings, reading nook, cubbies, hamster).
- Z-fighting: 10,802 flickering pairs down to 42.
