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
| **100 hours** | `tools/econ_sim.py 150 5`: median 98.1 h to Multiverse University (93-104), with supplies, teachers and builds in the sim. Adding the Principal's Pick dropped it to 89.5 h; tier cash 6-11 recalibrated (see the end of this log) |

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
| **Retention**: 7-day login streak (day 7 = free Epic), playtime gifts at 5-120 min | Claim, re-claim refused, streak reset after a gap, day-7 Epic on the bench, 5- and 10-minute gifts |
| **Candy Closet**: spend Confiscated Candy on a Jawbreaker Trap and candy decor | Trap tripped a carrier at the gate (6 -> 5 uses); decor screenshot |
| **Leaderboards** (this server + all-servers Hall of Fame) | Board screenshot; the Hall of Fame needs a published game |
| **9 more sound effects** (whistles, bonk, hammer, splash, bark, sad trombone, drum roll) | Every id loaded in Studio; heard in play |

## Not verified / known gaps
- Anything with two players: stealing from another player, Ruler hits on another player, the alarm.
- Mouse clicks from the test tool don't reach GUI buttons, so panels were opened through the
  ClientBus bindable and actions called directly. The buttons are wired to the same calls; clicking
  them by hand hasn't been checked.
- Real DataStore saves (Studio uses an in-memory stand-in on an unpublished place). The save/load
  round trip through that stand-in was verified earlier.
- Monetisation (game passes, products) is not built.
- docs/DESIGN-v2.md (written by the design workflow tonight) has more: story NPCs (Wobblesworth,
  Otis, Vex...), the Principal's Pick limo, the Confiscation Closet shop for candy, more events.
  Its build order is being followed; steps 1-5 are done.

## Things only you can do
- **File > Save in Studio** (and Publish when you're ready).
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
