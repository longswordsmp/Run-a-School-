# Run a School: everything tomas has asked for

One list, in the order it gets worked. Each item is done by hand, one at a time, and only marked
done after it's been played in Studio and checked on screen. "Built, not verified" means exactly that.

## P0: broken (blocks play)

- [x] The Vex Prep Job gets stuck after you steal the kid. Played by hand twice: walk, real prompts, real Ruler swings (12 to knock Grindle out), Desk 5, the grate, the tunnels, out of the pothole, VexPA cutscene, +$25K, To-Do on to "Face the Board". Second run with live monitors: timed the patrols, got in unseen, was spotted leaving and outran them to the office. Found and fixed on the way: the camera jammed into your head in the office (prompts off screen, so "Take the hoverboard" never showed); a stale phone call sitting over the whole job; a raid firing the instant the job ended; the tracker cutting off long objectives; the pothole ladder standing mid-tunnel in front of the camera; Stan's "we go tonight" call mid-heist; "her office" when it's Grindle's.
- [x] Grindle's office was a 90-by-14 corridor: now a real office (walls, records door, bookcases, his chair, desk things, Dr. Vex's portrait, confiscated rulers, coat stand, diploma, rug, pendant light). Screenshots.
- [x] Carrying a kid gets you stuck in doorways. Walked by hand with a kid overhead: Grindle's office door (twice), Vex Prep's front door (4.2 studs clear; steady 12-13 studs/s straight through, measured) and out of the front gate. Found on the way: on the Job, "get them out of the grounds" was impossible, Vex Prep's Chapter 6 lock barrier sat across the gate; it now lets you through while the Job is on (walked out, the Job completed). (The Factory pens only fill from lost raids, so that carry wasn't staged.)
- [x] The game is laggy. NPCs now move smoothly every frame (measured 43/43, was every other frame); steady 59.4 fps. The freeze after joining, found with a boot log and the script profiler: the server started nothing until every kid avatar had loaded (22 s cold), so the town, the schools, the NPCs and the services all landed at once just as the loading screen let you in; then Vex Prep's desks and the Lab's tubes each held the start up again (19 s, 21 s). Now the avatars load in the background: services up at 2.1 s (was 24 s), your school at 3.5 s (was 22-25 s); in the 20 s after PLAY appears, 3 frames over 100 ms, worst 164 ms (was 6, worst 1,190 ms; before that, a run of 0.4-0.7 s frames). First join re-checked: intro, then the six starter kids at the gate. (Studio only: ServerStorage attribute BootLog prints the boot timings.)

## P1: first impressions

- [x] The street doesn't make sense (red carpet over a road, kids into Detention): real road, sidewalks, crosswalks, Home Bus (screenshots; a kid boarded, measured).
- [x] An opening cutscene: how you get the school ("The Keys", screenshots of every shot).
- [x] (opening + step calls; keep checking every new beat) The story has to make sense: introduce VexCorp, Dr. Vex and Crumpet BEFORE they do anything (not "some random dude named Crumpet stealing kids"); every event has a reason the player has been shown. Plan: you arrive on Otis's bus, Wobblesworth (retiring) hands you the keys to the empty old school; Vex's limo glides past with Crumpet driving and Wobblesworth explains who she is and what she wants; Crumpet's raid then opens with "Dr. Vex sends her compliments..."; Skater Kid is your first transfer student, snatched by Vex before he reached you.
- [~] A tutorial that really teaches the game: "Swap up!" step (sell weakest, enroll better) and a call explaining each step. Not yet played by a fresh player end to end.
- [x] A way to hide the GUI: H or the eye button; Settings toggles the guide (screenshots).
- [x] Remove every leftover "coming soon" / unfinished thing (signs reworded; UNLOCK NOW only once the product exists). Missed one, found on screen: Vex's billboard behind the Sugar Shack still said "COMING SOON: VEX HOMEWORK FACTORY" (baked into the place); now "NOW OPEN". A search of every text in the running game finds no other "soon". Not re-checked on screen at chapters 3-9.
- [x] Vex Prep is missing one side of its roof (gable ends, screenshot).
- [ ] A Vex Prep showcase cutscene that really shows the rival school off.
- [ ] More cutscenes, and better ones.

- [x] Run faster by default, sprint even faster (walk 22, sprint 35, measured).
- [x] A map on M / Tab showing where quests and buildings are: the real town from above (screenshots).
- [x] After the tutorial, no line on the ground, just the arrow.
- [ ] Music: November Waltz, Almost Closing Time (Work at a Pizza Place), Night Theme (Adopt Me). Not on the Creator Store and not ours to use; waiting on tomas: licensed stand-ins, or he uploads copies he has the rights to.

## P2: quality, one thing at a time

- [x] Hoverboard: the board model and a proper riding pose and motion. New board (upturned tips, chrome rails, two thruster pods with glowing rings, underglow), mounted along the way you ride (it was across it); a surf stance instead of running on the spot (side-on, knees bent, leading arm up, head looking ahead), bobbing on the thrusters and banking into turns; a light trail and thruster sparkles while ridden. Screenshots standing, riding and carving. (Found on the way: this place's avatars use AnimationConstraint joints, and rigged accessories carry joints with the same names, so the pose code only touches the body's own joints.)
- [ ] Gear (Smoke Bomb, Whoopee Cushion, Energy Drink, Cardboard Box): models, held look, use animations.
- [ ] NPCs hold items weirdly (props through hands, wrong grips; the Ruler in your own hand too).
- [ ] Recess Commons: the sign blocks the path; the playground is awful.
- [ ] The Confiscation Closet is poorly made and makes no sense.
- [x] Detention sits in the middle of the road: moved onto its own lot facing the east road (screenshot).
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
