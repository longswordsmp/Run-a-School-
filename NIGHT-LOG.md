# Night log, 2026-09-24/25

What got built overnight, what was actually checked, and what is still open. Each "Verified"
line names its evidence: a play test in Studio with numbers from the server, a screenshot I looked
at, or a simulator run. "Not verified" means exactly that.

**Before anything else: Studio's place is unsaved. File > Save (or Publish) in Studio, or tonight's
work only lives in the repo.** Everything in Studio was pushed from `src/` and checksum-matched
(`tools/checksum.py` vs the push output), so the repo is the source of truth either way.

## How to see it
1. Open Studio, press Play. A new principal gets the intro cutscene (Board Chair dialogue over your
   school), then the Welcome Bus drops six starter kids.
   - To skip the intro while testing: in the command bar, run
     `game.ServerStorage:SetAttribute("SkipIntro", true)` (it is set right now; clear it to see the intro).
2. The left bar: Shop (Supplies / Teachers / Builder), Upgrades, Board, Yearbook, Name, Settings,
   and Admin (only for admins: you, anyone in Studio).
3. Top right: bus and event timers. Under them: your Admissions Letters.

## Built and verified

| Feature | Evidence |
|---|---|
| **Real school buildings** (SchoolBuilder): facade, framed windows, doors, lobby with lockers, Principal's Office, stairs, classrooms with chalkboard/clock/posters, 12 tier looks with towers | Screenshots of tier 1, 2, 5 and the whole street; a kid enrolled to floor 3 walked up both flights (position trace) |
| **Wider street**: 70-stud gaps between schools (was 30) | Map rebuilt; screenshot of the street |
| **Music**: "Relaxed Scene" main theme, then a shuffled playlist; context music for recess, stealing, board, events | Deck 2 playing 1848354536, 97 s long; recess switched to Runaway Carousel |
| **Sound effects** (40 verified ids) | Enroll sound played on the local bus (a Sound instance, 3.3 s) |
| **Upgrades to work for**: School Supplies (School IQ, shown on every desk), 12 Teachers (one per floor, at the chalkboard), School Builder (Reputation) | Buying Pencils + Notebooks + a teacher + 2 items took income from 3.00 to 4.4928/s, exactly 3 x 1.2 x 1.04 x 1.2; screenshots of desks with supplies and Mr. Chalk at the board |
| **Teachers animate**: pace, turn to the board, point, change the lesson text | Shoulder pose changed within 25 s (measured); board text changed ("7 x 8 = 56"); screenshot of the pointing pose |
| **Shop / Upgrades / School Board / Settings / Admin panels** | Screenshots of each |
| **Stealing**: carry a kid over your head, run home, it moves desks; Ruler bonk drops it | One-player test: carry speed 11, owner income drops while carried, delivery moves the kid, drop returns it. **A two-player test is still needed.** |
| **Cheaters -> Principal's Office**: catch with E, walk of shame, 20 s detention on the bench, walk back | Catching Mathlete paid 7,305 (80/s x 60 x 1.5 Eagle Eye + 5 + 100 first catch); income stayed 92/s during detention; screenshot of the office |
| **Snack Smugglers** (Sweet Tooth Sal, Goo Gary): halve a row until busted; bust gives Sugar Rush or Slime Time + Confiscated Candy | Row income 354 -> 352.5 while he was there; bust -> +8 candy, income x2 |
| **Board review cutscene** with 5 seated board members, gavel, story line per tier | Screenshots of the Board Room mid-cutscene; the school rebuilt underneath |
| **Intro cutscene** + **Welcome Bus** + **14-step tutorial** with scripted moments (a cheater, the Board's windows gift, Crumpet the butler stealing a kid, the Scholarship letter, a scripted smuggler) | Each step triggered and completed in play (numbers in commit 3d7fd84) |
| **Guaranteed rarity**: Admissions Letters (Rare every 6 min of play, Epic 30, Legendary 90, Mythic 5 h, Prodigy 20 h), Waiting Bench, free first Rare (Scholarship), Pocket Money Promise | Letter -> CALL -> reserved kid on the bench -> enrolled to desk 1 (walk trace); the second Rare correctly refused for lack of cash |
| **Honor Roll Bus** (Legendary+ first kid) every 15 min; all buses on the UTC clock | Timers landed on :35:00 (Late), :37:30 (Honor), :42:30 (Field Trip), :45:00 (Recess) |
| **Events**: Snow Day, Science Fair, Picture Day, Halloween, Space Camp (every 30 min, 10 min long) | Snow Day screenshot: falling snow, HUD row, Jingle Bells playing |
| **Admin panel**: call any bus, start/end events, spawn rare kids, Money Rain, server luck, recess | Panel screenshot; Money Rain dropped 80 bills and paid on touch |
| **6 cheap starter kids** ($9-$24) with props | Lineup screenshot |
| **NPC life**: seated kids wave, put a hand up, look around, laugh, nod, doze; hall kids wave/cheer; kids cheer arriving at a desk | 8 gestures counted in 16 s across 12 kids |
| **100 hours** | **Corrected later in the night, see "100 hours, corrected" below.** (The first figure, 103 h, left events and letters out of the sim.) |

### Later in the night
| Feature | Evidence |
|---|---|
| **Code review #1** (4 reviewers + fixes): Board-review cash exploit (3 reviewers found it), teleport-home steals, touch rewards from anywhere, offline pay including Sugar Rush, janitor loop crash, and 12 more | Re-tested: spending during a review is refused; teleporting home with a stolen kid drops it; walking home at carry speed delivers |
| **School Builder facade**: boarded-up windows until you buy Curtains (the tutorial gifts them on your first catch), awning + mat, marquee with live tuition, low brick wall, mascot lockers, cafeteria, arched windows + shutters, stained glass; items drop in with dust | Screenshots of a boarded Kindergarten and a decorated Prep School |
| **Wider street** with a landmark in every gap: fountain (Mr. Wobblesworth), Teachers' Lounge + Bell Schedule, Confiscation Closet, Recess Commons, District Office + leaderboards, Sugar Shack + Vex billboard | Screenshots |
| **Story NPCs**: Mr. Wobblesworth greets you by name, Janitor Stan mops, Lunch Lady Loretta at her cart, Hector patrols and whistles at thieves, the Sugar Baron appears on the Sugar Shack roof | Speech bubble "Ah, samot! Welcome to Recess Row!"; screenshots |
| **Guaranteed rarities**: Admissions Letters (Rare every 6 min, Epic 30, Legendary 90, Mythic 5 h, Prodigy 20 h) to your Waiting Bench; first Rare free; Honor Roll Bus every 15 min; **Principal's Pick** (Prodigy/Secret) every 2 h with dusk; everything on the UTC clock | Bench delivery and enroll traced; Pick dropped a Prodigy; timers on :35:00 / :37:30 / :42:30 |
| **First-session script (14 steps)**: Welcome Bus, a scripted cheater, the windows gift, Crumpet the butler stealing a kid to bonk, the Scholarship letter, a scripted smuggler | Each step triggered and completed in play; a **real E key press** enrolled a kid and advanced step 1 -> 2 |
| **8 more starter kids** (70 students) with signature gags (hops, hiccups, sneezes, barks, recorder, robot, mime, Tina pointing at cheaters) | Lineup screenshots; all 8 gags observed within 20 s |
| **12 events** (7 new: Field Day, Prom Night, Throwback, Wizard Week, Candy Carnival, Hostile Takeover, Graduation) with map dressing and the **event beam** (a seated kid gains the event grade) | Prom Night and Wizard Week screenshots; forced beams: 3 kids Enchanted, 4th refused (cap), income x5 |
| **Robux store**: 6 passes, 8 products, idempotent receipts | Grant paths tested (VIP x2 income, tuition pack, server luck). **Pass/product ids are 0 until you create them on the Creator Dashboard** (Config.Passes / Config.Products) |
| **Pop Quiz** every 10 min (30 questions, 10 s, pays 60 s of tuition) | Quiz card screenshot; right answer paid, second try refused |
| **Retention**: 7-day login streak (day 7 = free Epic), playtime gifts at 5-120 min | Claim, re-claim refused, streak reset after a gap, day-7 Epic on the bench, 5- and 10-minute gifts |
| **Candy Closet**: spend Confiscated Candy on a Jawbreaker Trap and candy decor | Trap tripped a carrier at the gate (6 -> 5 uses); decor screenshot |
| **Leaderboards** (this server + all-servers Hall of Fame) | Board screenshot; the Hall of Fame needs a published game |
| **9 more sound effects** (whistles, bonk, hammer, splash, bark, sad trombone, drum roll) | Every id loaded in Studio; heard in play |

### Last stretch (after the night log above)
| Feature | Evidence |
|---|---|
| **Dr. Vex's limo** drives the street every 15 min (UTC clock) and stops at the poorest school; she stands out of the sunroof, turns to the school and taunts it | Screenshot: limo on the school's side of the street, Vex in the sunroof, bubble "I'll buy it. I'll buy ALL of it." |
| **Otis drives every bus**: the bus got an open driver's cab (map rebuilt); special buses are clones, so he drives them all and the cab takes the bus colour | Screenshots: Otis (cap, shades, beard, hi-vis) behind the yellow bus windshield and at the wheel of the purple Field Trip bus |
| **Principal's Requests: 11 story chapters** (Elementary to the first Prestige star). Each has 4 requests (hire, build or stock that tier's items, reach IQ, own a rarity, catch/bust/quiz counts, enroll off a named bus), then Face the Board. Each request pays 1 % of the next Board review plus candy; a finished chapter fills a Rare-to-Prodigy letter. Checklist card under the HUD letters, a title card with the host's line, a toast per request | Real purchases tick requests and pay exactly (cash 1,000,000 -> 1,470,000 after a $150K hire = +$620K). Controls: IQ 140 does not tick "IQ 150", 150 does; a plain enroll does not count as a Late Bus enroll, a Late Bus kid does; an 11 s catch is not Eagle Eye, a 1 s catch is. The real tutorial-ending review opened chapter 1 and its title card. Screenshots of the card and the title card |
| **Chapter review** (3 reviewers + a verifier each): 10 confirmed findings, all fixed. The serious one: "Hire X" could become impossible once a better teacher held the floor, freezing the chain; it now counts X or better | Re-tested: with Ms. Honeycutt hired, "Hire Mr. Chalk (or better)" ticks and the shop does refuse Chalk |
| **Daily Requests**: 3 a day (UTC), one free reroll, 25 candy each; all 3 open **Loretta's Lunch Box** (odds shown: 80 candy, or a Rare/Epic/Legendary/Mythic letter). No cash rewards, so pacing is untouched. Red "!" on the Daily button when something is waiting | Real enrolls counted (3/20), a real letter CALL completed one (+25 candy); second reroll and early box refused; box paid 80 candy; second open refused; badge on and off; panel screenshot |
| **Event Tickets**: during every event, tokens (event colour, icon above, sparkles) pop up around each player; walking into one is a ticket. Shop > Event: letters (15/40/120 tickets), candy, and each event's trophy (40) only during that event. **Trophy case** on the lawn fills 12 slots | Tokens spawned 18-28 studs away and 2 were collected by walking in; trophy bought (102 -> 62), wrong-event and repeat trophies refused, Rare letter filled; screenshots of the tokens, the case (1/12 with ? placeholders) and the Event tab |
| **Announcements** no longer draw over each other (older ones slide up); the quest DONE toast moved beside the card; "IS NOW AN ELEMENTARY SCHOOL" | Seen in screenshots |
| **Scrapbook** (Yearbook tab): the story so far in 23 pages, the Board Chair's welcome, each Board promotion and each chapter opening, in order, unlocked by tier | Screenshot at tier 4: "7 / 23 pages of the story" |
| **Graduation**: hold G at one of your kids' desks and they graduate (cap toss) for Diplomas (Common 1 to Secret 2,000, x grade). **Alumni Hall** (Yearbook tab) opens at Ivy League: Diplomas invite the 5 Alumni back; they walk in and you pay their price. The Board panel now says to graduate before a review (it clears the desks) | Prompt reads "Graduate +125" for a Gifted Legendary (50 x 2.5); graduating removes the kid and banks it; the Hall refuses below Ivy League; an invite took 100,000 Diplomas and $60B and Grandpa took desk 1 ($324M/s at Ivy x18); repeat invite refused; Alumni tab screenshot |
| **Board reviews tell the story**: Kevin (age 10, propeller beanie, milk moustache, cereal bowl) sits on the Board; each promotion plays that tier's beat in the dialog box with the speaker's portrait (Kevin's waterslide and the Board's "No.", the Sugar Baron at the window, Vex's schemes, Stan's blinking statue, Kevin unmasked as the Sugar Baron, Otis's "...Home.") | Screenshot of Kevin at the Board table and of his portrait mid-line; camera sampled in the Board Room (y~407) during the beat |
| **Graduation Day finale**, once, after the first promotion to Multiverse University: dusk, three shots of your school, the whole cast (Otis explains the bus, Vex's machine backfires and shrinks her, Kevin's last waterslide), end card PRINCIPAL OF THE MULTIVERSE; Tiny Vex then waits on your bench for free | Every speaker played in order with the camera on the plot; Tiny Vex found on the bench (reserved, free); screenshot of the dusk shot with Otis's line |
| **Golden event token** every 90 s during an event: a big gold coin worth 10 tickets, announced to the server, first to touch it wins | Screenshot (gold coin with "x10" under Halloween dusk); walking in took tickets 0 -> 10 and removed it |
| **Weekly Requests** (Monday 00:00 UTC): 3 bigger requests, 100 candy each, all 3 open the **Weekly Chest** (a Legendary letter + 30 tickets); TODAY / THIS WEEK toggle in the Daily panel | Early chest refused; finishing paid 3 x 100 candy + the Daily candy; chest gave the Legendary letter (5387 s -> ready) and 30 tickets; second open refused; screenshot with real progress (Graduate 25 kids 3/25) |
| **Phones**: every ScreenGui scales with the screen height (0.5-1, desktop 1:1) so nothing overlaps on a short screen | Screenshots at 1152 px and at a faked 420 px (DebugViewportY): HUD, side bar, chapter card and the Shop all fit |
| **Review of Alumni + story** (2 reviewers + verifiers): 8 confirmed, all fixed. The serious one: the finale was marked seen before it played, so leaving mid-finale lost it and Tiny Vex for good; it now stays pending until she's delivered and replays on rejoin | Tested: pending=true while playing, seen=true after; invite during a real review refused with Diplomas intact |
| **Review of Daily + Tickets** (2 reviewers + verifiers): 6 confirmed, all fixed: an unopened Lunch Box was lost at midnight (now carried over), one action could pay two requests, a stale panel could waste the reroll, the trophy case stood partly on the public sidewalk with fences through it (moved inside the lot), and the case relied on a join poll that can time out | Re-tested: owed box opened the next day; stale reroll refused and kept; case screenshot inside the fence |

### 100 hours, corrected
The first figure (103 h) came from a sim that left out events and the Admissions Letters. Adding
them dropped the median to 73.7 h, so the model was extended with everything that gives kids or
cash on a schedule: event grades on buses and the event beam, all five letters, chapter letters and
rewards, the Lunch Box (one per 3 h of play) and ticket letters (30 tickets an event, trophies
first). Tier cash was then recalibrated: 8-seed median 110.9 h. Graduation and the Alumni Hall were
then added to the model (graduating every replaced kid and every kid before a review), and the
Alumni kids were scaled down to Secret-level earners after they made the endgame too fast.
**Latest 8-seed check: median 106.5 h to Multiverse University (98.2-112.0 h)**; the first Alumni
arrives around 32 h, the second around 49 h, the third near the end, the last two after.
With the VIP pass (x2 tuition, same model): median 67.8 h (60.9-81.1 h).
Not modelled, all of which make a real player faster: steals, smuggler buffs, quizzes, playtime
gifts, daily-streak tuition, Money Rain, offline pay. The sim plays like a strong, always-online
player; a typical player is slower.

## After your feedback (2026-09-25)
Your notes: too many sound effects, only Relaxed Scene was good, events/gift timers shouldn't be on
screen, models and UI need to be far better, the story should be a real story, the game isn't fun.
You picked: generated meshes for kids and props plus detailed parts for buildings; a better tutorial,
missions AND a street that changes; and "Action".

Done and checked in play (how each was checked in brackets):
- **Sound**: Relaxed Scene is the only music; SFX cut to 7 sounds with per-sound gaps and a
  4-per-second cap. The events/gift/letter timers are gone from the HUD. [played, read the HUD]
- **Action: VexCorp raids.** Goons in a purple van come for your seated kids; bonk them with the
  Ruler (knock-back, stars, K.O.). One that escapes takes the kid to the Factory. [real Ruler swings]
- **Action: the VexCorp Factory heist.** Your captured kids sit in pens behind guards with
  flashlights; sneak in, grab, run for the gate, bonk guards who catch up. Vex's "mystery captive"
  pens hold a random rarer kid. [on-foot runs through the real prompts]
- **Tutorial** rebuilt around that: enroll, collect, Crumpet steals a kid (bonk him), lock the gate,
  rescue a kid from the Factory (a slow, lenient guard the first time). [played start to end]
- **Story missions**: each chapter now has one mission from Mr. Wobblesworth (the "!" over him at the
  fountain; talk, read, START MISSION). Three kinds: defend your school from a story raid (the van
  waits till you're home), chase a runner down Recess Row and bonk him before he gets away, and
  Factory heists (the School Mascot, Vex's blueprints off her desk, the Tiny Professor). Missions pay
  3x a normal chapter request. [defend: won with Ruler swings and lost; chase: won on foot and lost;
  blueprints: full run through guards; kid heist: rescue hook-up]
- **The street changes with your chapter** (each player sees their own): VexCorp posters (ch 1),
  the billboard goes "NOW OPEN" (ch 3), Vex's limo + SOLD SOON sign + drained fountain (ch 5),
  searchlights on the Factory (ch 7), the Sugar Shack becomes Kevin's Waterslide and the Baron's gone
  (ch 9), the Homework Machine going up on the Factory roof (ch 9), then awake with a glowing core,
  a pencil arm, lightning and a purple sky (ch 10-11), and RECESS IS SAVED with bunting (after the
  finale). [screenshot of every stage]

Still to do from your list: the model pass (meshes for kids and props, detailed buildings) and the
UI rebuild.

## Second night (2026-09-25/26)
You rejected the mesh kids ("not at all what I wanted... more realistic") and picked avatar-style kids.
Then you asked for: a loading screen, PC/phone choice, autosave; a big VexCorp history; missions;
stealing VexCorp's mutated students; a rival school across the street; sprint and sneak past guards;
gear to buy; a Home button; side buttons that unlock when needed; better bus, VexCorp cars,
buildings and Detention; and co-op for 1-4 players with roles and co-op tasks.

Done and checked (how, in brackets):
- **70 avatar-style kids** from catalog clothes, hair and dynamic heads. [screenshots of every rarity row]
- **Loading screen**: doodles, waving kids, a bus loading bar, COMPUTER / PHONE, PLAY. It hides the
  hotbar and player list until you're in. **Autosave** every minute and after big moments, with a
  "Saved" chip. [screenshots; save pushes read on the client]
- **Side buttons unlock when you need them** (Home, Settings and Co-op from the start; Shop at the
  pencils step, and so on), with NEW! badges. **Home** button, H key, 10 s cooldown. [fresh player saw 3 buttons]
- **Sprint (Shift) and sneak (C)** with stamina; guards see you by distance, cone and noise.
  **Janitor Stan's gear stall**: Cardboard Box, Smoke Bomb, Whoopee Cushion, Energy Drink, Lockpick Set,
  Silent Sneakers, Running Shoes. [a table of seen/unseen distances measured against a guard]
- **VexCorp history**: 16 VexCorp Files hidden around town (the Files book on the left), telling
  Veronica Vex's story from Grade 5. [read and rewarded in play]
- **The Mutation Lab** (north-west): steal a Mutated kid out of a tube past lasers, cameras and hazmat
  guards; Mutated kids earn big early. **Janitor Stan's secret jobs** (hack, ghost, sample, snoop)
  pay Mutagen Vials; V mutates one of your own kids. [lab escape delivered a Mutated kid; a hack job
  run to JOB DONE; Skater Kid mutated to $360/s]
- **Vex Prep Academy**, the rival school at the south-east end: ONE campus for the whole server.
  Steal kids from its eight desks past three hall monitors; the bell brings them running; every theft
  raises your Rivalry (rarer, smarter kids) and brings a revenge raid sooner. It has a first-look
  cutscene the first time you walk up, and chapter 5 asks you to steal one. [steal, carry, escape
  (kid delivered to the bench, Rivalry 1), caught after 12 s standing still, cutscene screenshots]
- **Co-op schools, 1-4 players.** On the loading screen (or the Co-op button in game): pick a role,
  then START A CO-OP SCHOOL or JOIN one in the server. Everyone plays the host's school: shared cash,
  kids, income, prompts, raids, chapter and to-do card. Members' own schools keep earning and pay
  out when they go home (BACK TO MY SCHOOL). Roles, any number of each, perks with 2+ players:
  President (10% back on purchases), Teacher (+20% tuition while inside), Hall Monitor (one-hit goons,
  2x stun), Recruiter (carry 20% faster, quieter). **Crew jobs** (Assembly, Bus Rush, Raid Vex Prep,
  Payday) pay the school and give +30% tuition for 2 minutes. One VIP in the crew doubles the school.
  [A real 2-client local server: joined by real clicks on the loading screen and in the panel; both
  saw the same cash and income; the member collected a desk ($3.2K into the shared wallet); the
  member saw Sell but no Steal on their own school's kids; ASSEMBLY finished and paid $600;
  Teacher perk 87.5 x 1.2 x 1.3 = 136.5/s measured; Hall Monitor took a 3-HP goon out in one bonk;
  the raid banner reached the member; leaving and the host quitting both sent the member home
  with their own plot back]
- **Vehicles**: a real conventional school bus (hood and grille, framed windows, rub rails, folding
  door, stop sign, emergency door), the special buses show their name on both sides, a VexCorp panel
  van with a raked windshield and a light bar, a chrome-trimmed stretch limo. [screenshots]
- **Detention Hall** (east end): brick, barred windows, porch, neon sign, a clock stuck at 3:00,
  water tank, searchlight, fenced yard. **Every school** gets a detail pass: base course, corner
  pilasters, floor bands, sills and lintels, door lamps, walk lamp posts. [screenshots, tier 1 and 6]
- **Friends bonus**: +10% tuition for each Roblox friend in the server (up to +40%), shown next to
  the tuition on the HUD, with a toast when a friend arrives. A reason to invite. [with a Studio
  test hook standing in for friends: 60/s became 72 with 2 and 84 with 9 (capped); the HUD read
  "+40%". The real friend lookup (IsFriendsWith) can't run in Studio.]

## Not verified / known gaps
- Two players in different schools: stealing from another player, a Ruler hit on another player, the
  alarm. (Co-op WAS tested with two clients; see above.) Three and four-player crews weren't run.
- Stan's ghost, sample and snoop jobs weren't run end to end (the hack job was).
- The Friends invite window (Roblox's own) only works in a published game.
- Real DataStore saves (Studio uses an in-memory stand-in on an unpublished place). The save/load
  round trip through that stand-in was verified earlier.
- Game passes and products are built but have no ids yet (see below), so no real purchase has run.
- docs/DESIGN-v2.md still has unbuilt parts: per-event activities beyond tokens (snowball war etc.),
  Nemesis / Most Wanted / Gazette, the Yearbook Parade credits.
- Phone layout was checked by faking a short screen in Studio, not on a real phone or the
  device emulator; touch targets are about 39 px at the smallest scale.
- Studio's screenshot tool sometimes renders the player camera instead of a cutscene's scripted
  camera; where that happened the camera position was sampled on the client instead.
- Studio's screenshot tool doesn't draw always-on-top billboards, so the custom prompt pills were
  checked by reading them on the client (text and offsets), not by a screenshot.
- Event tokens on a crowded server: spawning is per player (4 live each), not tested with many players.

## Things only you can do
- **File > Save in Studio** (and Publish when you're ready). The new school bus and Detention Hall
  were rebuilt in the place itself (tools/rebuild_bus.lua, tools/rebuild_detention.lua), so they
  only stick once you save.
- **Set Max Players to 8** (Game Settings > Places): there are 8 school plots, and a ninth player
  would have no school (co-op members don't use a plot, but a solo newcomer does).
- Create the game passes and developer products on the Creator Dashboard and paste their ids into
  `Config.Passes` / `Config.Products` (they show "SOON" until then).
- The admin panel is open to anyone in Studio and to the place owner (or group rank 255) in live games,
  plus UserId 1331076401.

## Questions for you (from the design doc)
1. Is 1331076401 your Roblox UserId for the admin panel? Anyone else?
2. Keep Dr. Vex as the villain?
3. Should the 2-hourly Principal's Pick ever carry a Secret?
4. Smuggler bust reward size (now x2 tuition for 20 s + candy).
5. Weekly update / admin-abuse time: Saturday 15:00/17:00 UTC OK?
6. VIP (x2 tuition) takes the sim's median from 106.5 h to 67.8 h. Keep x2, or make VIP x1.5?
