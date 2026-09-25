# Run a School: Design v2

Written 2026-09-24. This is the design that the next builds follow. It merges three proposals using
the player, lead and engineer judges' keep and drop lists, and it is written against the code as it
stands tonight, not against the older GAME-PLAN snapshot.

**Status of everything in this file:** design only. Nothing here has been built or play-tested unless
it is tagged **[EXISTS]**, and [EXISTS] only means "I read it in the repo at about 21:10 tonight".
Several of those systems were committed or edited in the last hour, and some are uncommitted.
Whether they have been play-tested is recorded in GAME-PLAN.md Status, not here.

Tags used below:

| Tag | Meaning |
|---|---|
| **[EXISTS]** | In the repo now (file named). This doc keeps it. |
| **[CHANGE]** | Something in existing code this doc changes, with the reason. |
| **[NEW]** | Not in the repo. |
| **[SIM]** | Changes income or supply and has **not** been measured in `tools/econ_sim.py` yet. |

Where this doc and GAME-PLAN.md disagree (the 24-teacher gacha, the separate Prestige star system,
the tier cash table), this doc wins. The reasons are in the decision table below.

---

## 0.1 The owner's asks, and where each one is answered

| Ask | Answer | Section |
|---|---|---|
| "The schools look nothing like schools" | New players' school starts boarded up. At 1:20 the boards pop off and curtains go in (the Board's gift). There are 8 new facade and interior Builder items, and a build-in animation. | 2, 8 |
| "The area in between the schools is too little" | The gaps go from 30 to 70 studs. Every gap gets a landmark with a job in it (Hub fountain, Teachers' Lounge, Confiscation Closet, Recess Commons, District Office, Sugar Shack). | 8.1 |
| "Upgrade, add windows, walls outside" | A window ladder (Curtains, Window Boxes, Arched, Stained Glass) and a wall ladder (Picket, Low Brick, Brick and Lamp Pillars, Iron Gates), plus entrance, marquee, lockers and cafeteria. | 8.3 |
| "Hire teachers" | The 12 existing teachers stay. New: arrival by taxi, a real classroom routine, reactions, and strict teachers catching cheaters. | 7 |
| "Catch students cheating and send them to your office" | Keep PatrolService's catch and walk to the office. Changes: catching now pays instead of costing, 3 visible tells, a Wall of Shame. | 5 |
| "People dealing candy and slime" | Snack Smugglers: Sweet Tooth Sal and Goo Gary, with a masked boss (the Sugar Baron, secretly Kevin). Confiscated Candy currency and Stan's Closet. | 6 |
| "Really work on the visuals" | Sections 8 and 11, plus a prop spec for every new student (4). | 4, 8, 11 |
| "NPCs and animations" | 10 story characters, the ambient cast, and a full animation list: default emotes plus procedural Motor6D recipes in a client Puppet module. | 1, 11 |
| "More cheap students for when they start out" | Six $9-$24 starters already exist. 8 more fill the $30-$100 variety and the empty $180-$480 gap. | 4 |
| "A guaranteed rarity every X minutes" | Server bus schedule on the UTC clock: Rare+ every 5 min, Legendary+ every 15, Epic+ every 30, Prodigy every 2 h. Personal Admissions Letters: Rare every 6 min, Epic every 30, Legendary every 90. | 3 |
| "Events" | 12 rotating events, 5-minute Surges at :20 and :50, and event grades that can land on seated kids. | 9 |
| "An admin panel" | Owner-only panel with security rules, 40+ commands and 12 "admin abuse" events. | 10 |
| "Storyline and progression that instantly hook players in the first 5 minutes" | The Pencilvania story, 12 Board cutscene beats and a finale. A second-by-second first 5 minutes. A 60-step Principal's Requests chain. | 1, 2, 12 |
| "Best game on Roblox, 100+ hours" | Sim-checked pacing (about 100 h to Multiverse for the strong sim player), plus the hour-20, hour-50 and hour-100 hooks. | 0.3, 12 |
| "Makes a lot of Robux" | Passes and products with prices, the moments they sell at, and fairness rules. | 13 |
| "Music (Relaxed Scene main theme), sound effects" | Relaxed Scene is already wired as the main theme **[EXISTS]** (`Sounds.lua`, `Audio.client.lua`). New stings and effects are listed. | 11.6 |
| "Animations, cutscenes" | 12 Board beats, the intro, the finale, the Principal's Pick staging, and the event intros. | 1, 3, 11 |

## 0.2 Merge decisions

Where proposals disagreed, the option below is the one the judges scored higher. The reason is given in one line.

| Topic | Chosen | Over | Why |
|---|---|---|---|
| Story spine | P2: Pencilvania, Wobblesworth, Vex, Kevin's waterslide | P1 (Plum and Grimsby), P3 (Snootsworth) | P2 scored coherence 9 from all three judges. Lead and engineer both named it the spine. |
| Villain's henchman | P3's Crumpet, now Vex's butler | Vex-Bot (P2), Gloom Prefect (P1) | Player judge: "funniest NPC across the three". Lead and engineer keep the Crumpet steal-and-bonk beat. |
| Bus driver's name | "Otis" (P3's name, P2's personality and twist) | "Gus" (P2) | "Glue Stick Gus" is already a student in Config, so one name per character. |
| Candy boss | "The Sugar Baron" (P1's boss name) with P2's twist (it is Kevin) | "The Sweet Tooth" (P2) | "Sweet Tooth Sal" is already the candy smuggler in PatrolService. |
| First 5 minutes | P1's script skeleton + P3's windows gift + P3's steal-back-then-defend beat | Any single proposal | P1 and P3 both scored hook 9. All three verdicts ask for this merge. |
| New-player protection | P3's Freshman Shield (10 min, ends if you steal from a real player), drawn as P1's Grand Opening ribbon. Plus P1's Big-kid rule. | P1's 5-8 min ribbon | P3 fit 9 > P1 fit 8. All three judges keep the Big-kid rule. |
| The 2-hour spectacle bus | P3's Principal's Pick staging, carrying **Prodigy 95 % / Secret 5 %** | A guaranteed Secret every 2 h | Player and engineer both dropped it: +80 % Secret supply. This version adds about +4 %. |
| Personal guarantee | P1's affordability-gated Admissions Letters, delivered to P2's Waiting Bench, with P3's offline filling | P2's 3/15/60-min lanes, P3's 8-min letter | All three judges keep the P1 letters and the P2 bench. The player judge said P2's lane A every 3 min makes the carpet fight pointless. |
| Cheat window | 40 s with escalating tells (PatrolService already uses 40 s; P1 used 45) | P3's 12 s | Two judges said 12 s punishes players who are at the carpet. |
| Seller naming | "Snack Smugglers" in all player text; never "deal" or "dealer" | PatrolService's current "DEALING CANDY!" | All three judges flagged the moderation and parent risk. P3 (fit 9) named them Snack Smugglers. |
| Teachers | Keep the 12 `Config.Teachers` and add the visual layer | The 24-teacher Staff Room gacha in all three | All three judges: it conflicts with the shipped TeacherService and econ_sim. |
| Builder | Extend `Config.Builds` (Reputation) | Separate Prestige stars in all three | All three judges: separate stars would double-count Reputation. |
| Founder's Chime | Kept small: the bell plays N notes at the end of tier N's cutscene, with no counter UI | An 11-note progression system | Lead and engineer keep it. The player judge only objected to counting notes. |
| Gate Glitch admin event | Kept, with Heist Amnesty (everything stolen walks home when it ends) | Dropping it | Player and lead keep it. Amnesty removes the engineer's lost-Secret problem. |
| Dropped outright | Most Wanted bounty product, Rainbow Ruler reach bonus, Mystery Backpack, paid lane skips, the Snitch rule, the Gloom Blimp, the Valedictorian Express | | Each was dropped by at least two judges (harassment route, paid PvP edge, extra paid-random items, griefing, scope). |

## 0.3 What was measured

I ran `tools/econ_sim.py` on **scratch copies** of today's `Config.lua` and sim. The repo was not
touched. Settings: 150 h cap, 20 seeds, median (min to max).

The Config snapshot was taken at 21:11. It includes the six $9-$24 starters and the Honor Roll Bus.

Scratch folder:
`C:\Users\tomas\AppData\Local\Temp\claude\C--Users-tomas-dihcheeseclient\4a68965e-a4cf-4dc2-8c04-1f92af07e924\scratchpad\design3\`
(`make.py` builds every variant).

| Row | Variant | Elementary | Middle | Prep | State Univ. | Wizard | Multiverse (min to max) |
|---|---|---|---|---|---|---|---|
| A | Today's Config (62 students, Honor Roll Bus) | 29.1 m | 1.87 h | 4.76 h | 18.1 h | 45.2 h | **99.6 h** (89.7 to 110.7) |
| B | A + the 8 starters (section 4) | 26.9 m | 1.87 h | 4.47 h | 17.7 h | 46.2 h | 95.5 h (85.4 to 117.3) |
| C | B + Admissions Letters, the free Scholarship at 4:20, the Principal's Pick, cheater rewards (stand-in) | 26.1 m | 1.70 h | 4.81 h | 21.5 h | 47.5 h | 99.5 h (84.6 to 114.3) |
| D | C + the 8 new Builder items (section 8, +12 Rep) | 25.6 m | 1.63 h | 4.26 h | 17.6 h | 45.1 h | 95.8 h (81.5 to 109.6) |
| E | D + the smuggler bust buff **as built today** (x2 on the whole school for 60 s, about +29 %) | 17.3 m | 1.21 h | 3.39 h | 13.7 h | 37.4 h | **79.9 h** (70.1 to 99.6) |
| F | D + x2 on the whole school for 20 s (about +10 %) | 22.9 m | 1.38 h | 3.92 h | 15.7 h | 41.2 h | 88.7 h (77.8 to 102.6) |
| **G** | **D + this doc's buff: x2 on the targeted row only, for 20 s** (the full package) | 25.2 m | 1.59 h | 4.45 h | 16.8 h | 41.9 h | **92.4 h** (80.5 to 110.4) |

What the table shows:
- Rows B to D each stay inside the baseline's seed range.
- The whole package (G) moves the median 7 % faster (99.6 h to 92.4 h) **without touching any School
  Board cash value**.
- The one real problem is the smuggler buff as built (E). It removes 20 hours and brings Elementary down
  to 17 minutes. Section 6 changes it.
- If the strong player's median has to stay at 95 h or more, drop the row buff too (row D).

How to read the table:
- The sim player is strong: always online, always at the carpet, never robbed. Real players are
  roughly 2x slower (GAME-PLAN section 9).
- The cheater rewards are an income stand-in, `x (1 + 0.6 / desks)`. It assumes every cheater is
  caught in time with the section 5 rewards.
- "Sugar" is a flat income bonus that stands in for the smuggler bust buff.

**Also checked (not a sim):**
- `tools/retune.py` leaves all 8 new students unchanged.
- The same script **would reprice 5 of the 6 committed $9-$24 starters**: $9 to $10, $12 to $10,
  $18 to $20, $21 to $20, $24 to $25. Its `sig2()` rounds anything under $100 to a multiple of $5.
  - **[CHANGE] tools/retune.py:** round prices under $30 to whole dollars, so the next retune does
    not undo the starter prices.

**Not measured:**
- The first-5-minute feel, and 8 players competing for one carpet.
- Offline letter filling.
- Event grades landing on seated students, and event shops.
- The Freshman Shield.
- Friends and group bonuses.
- Everything visual.

Each one tagged [SIM] needs a sim hook before tuning.

**A note on the sim itself:**
- econ_sim assumes a student spends 50 s on the carpet.
- The real carpet is 664 studs (-318 to 346) at `Config.WalkSpeed` 9, which is 74 s.
- This doc does not change that, but it makes the sim slightly pessimistic about choice.

---

## 1. Storyline

### Premise
- **Pencilvania** is a town with one street, **Recess Row**. Every 2.2 seconds, for forty years, a
  yellow bus has dropped a kid onto its red carpet. Nobody knows where the bus comes from.
- The street's eight schools are falling apart, and old **Mr. Wobblesworth** is retiring.
- **Dr. Veronica Vex** of VexCorp Learning Solutions wants to bulldoze Recess Row and build one giant
  **Homework Factory**.
- The **School Board** will keep funding only the schools that pass its reviews.
- You step off the bus as the principal of a one-room Kindergarten. It is boarded up, and a CONDEMNED
  sign hangs on the door.

Three threads run through all 12 tiers:
1. **Vex's schemes.** She objects at reviews, runs the tutorial's recruitment tent, and is the villain
   of events.
2. **Who is the Sugar Baron?** A masked boss runs the Snack Smugglers. The Golden Wrapper clues lead
   to the reveal at Ivy League.
3. **Where does the bus come from?** Otis the driver knows. The finale answers it.

Running gag: **Kevin, age 10, sits on the School Board and wants a waterslide.** Every review, the whole room answers "No."

### Cast (10 recurring characters)
Rules for all characters:
- They are built from parts on R15 rigs. Adults use the teacher rig
  (`StudentFactory.buildTeacher`, scale 1.0 to 1.1, normal head). Kids use the student rig.
- Props use the existing `StudentProps` helpers (`block`, `ball`, `blob`, `cylY`, `cylZ`,
  `wireGlasses`, `sparkles`, `pivot`).
- No voice acting. Speech bubbles type out with a pitched blip per letter.

| Character | Look (parts) | Personality | Catchphrase | Gameplay role | Blip pitch |
|---|---|---|---|---|---|
| **Mr. Wobblesworth**, retired principal | Short (0.85 height). Bald with two white side-tuft blobs and a walrus moustache (two squashed blobs, 1.4 studs wide). Round `wireGlasses`, brown tweed cardigan, green bow tie (two wedges). Leans on a **giant yellow pencil cane**: a 0.4 x 4.5 cylinder with a pink eraser on top and a three-step tip. | Kind, rambling, easily delighted | "Back in MY day we had ONE desk, and we SHARED it!" / "Splendid! Simply splendid!" | Tutorial guide who walks beside you for the first 5 minutes. After that he stands at the Hub fountain with a "!" when a Principal's Request is ready. Introduces each chapter. | 0.8 |
| **Otis**, the bus driver | Big grey beard blob, flat cap, mirrored aviators (black Glass blocks with a Neon rim), orange hi-vis vest with white Neon stripes, steel thermos. Seen through the bus windscreen. | Unflappable. Forty years without a day off. | "Doors closin'!" / "Next stop: wherever." | Drives every bus: Late, Honor Roll, Field Trip, Welcome and the Principal's Pick limo. Delivers Admissions Letters. Voices the bus banners. His eyes are galaxies (finale). | 0.6 |
| **Chair Gavelina Grimm**, School Board Chair | Three stacked grey beehive blobs, cat-eye glasses (wedges), five pearls, gavel. | Stern, secretly soft | "Motion... APPROVED!" (bang) | **[EXISTS]** as the unnamed "THE BOARD CHAIR" in `Cutscene.client.lua` and `Config.BoardLines`. This doc names her. She speaks in every review beat. The other three Board seats are unnamed background members, one of them always asleep. | 0.9 |
| **Kevin**, age 10, Board member | Propeller beanie (the propeller spins), cereal bowl, milk moustache (white block). | Chaos | "Can we get a waterslide?" | Every review gag. Hands out Principal's Requests on event days. **He is secretly the Sugar Baron.** At Ivy League he says "I may have franchised", which is why smugglers keep coming after the reveal. | 1.5 |
| **The Sugar Baron** (Kevin in costume) | Trench coat, a top hat made of cake (a brown cylinder with white icing blob rings and a cherry ball), candy-cane cane, two pink Neon eyes, face in shadow. Vanishes in a puff of white "powdered sugar" particles. | Theatrical | (whispered) "Pssst... gummy worms?" | Boss of Sweet Tooth Sal and Goo Gary (section 6). Seen on rooftops. Drives the Ice-Cream Van raid (Candy Carnival event). Drops Golden Wrapper clues. | wrapper crinkle, no blips |
| **Dr. Veronica Vex** | Tall (1.1), purple power suit with huge wedge shoulder pads, a sharp silver bob (block), a tablet (black block with a Neon screen), a glinting monocle. Long black limo with VEX plates. | Corporate cartoon villain who hates recess. Never actually harmful. | "Tick tock, Principal. Tick. Tock." / "OBJECTION!" | Objects at reviews. Recruitment tent in the tutorial. Limo drive-by every 15 min, with a line to the poorest school. Villain of Snow Day and Hostile Takeover. In the finale she shrinks into the existing Secret, "The Kid Who Reminded The Teacher About Homework". | 1.05 with echo |
| **Crumpet**, Vex's butler | Tailcoat, silver tray, white gloves, feather duster. | Deadpan, excessively polite | "Terribly sorry. I'm taking this child." | Tutorial thief. You rescue a kid from him, then bonk him with the Ruler. Leads the raiders in Hostile Takeover. After the finale he polishes your Waiting Bench (cosmetic). | 0.7 |
| **Janitor Stan** | Blue overalls, grey cap, a key ring of six small Metal blocks, a mop (cylinder plus six thin white blocks), a yellow wheeled bucket. | Has seen everything. Talks in ominous hints. | "I've seen things under those bleachers, kid." | Runs the **Confiscation Closet** (section 6). Shows the "While you were out" card when you return (section 12). Drops Sugar Baron clues. | 0.75 |
| **Lunch Lady Loretta** | Pink apron, translucent hairnet over a purple beehive, giant ladle (cylinder plus a half-sunk ball), oven mitts. A Mystery Meat blob on her tray wiggles now and then. | Sweet, feeds everyone, terrifying about vegetables | "Eat your veggies, sweetie." / "Mystery meat? That's between me and the meat." | Daily Lunch Box. Hosts Lunch Rush. Her cart visits Cafeteria Corners. | 1.1 |
| **Reporter Riley** (kid) | Press hat with a card in the band, oversized camera (the flash is a PointLight), notepad. | Breathless | "STOP THE PRESSES!" | Live server news. Shouts Secret and Prodigy pulls, big steals, reviews, Kingpin busts, and bus countdowns. Keeps the Hub's Gazette board (today's top 5 headlines) and the Most Wanted poster. | 1.4 |
| **Head Hall Monitor Hector**, age 11 | A sash too big for him, a head-sized badge (yellow ball with a star), whistle, handheld STOP sign (flat red cylinder). | Takes rules extremely seriously. Wrote half of them. | "NO. RUNNING. IN. THE. HALLS!" | Patrols the carpet. Whistles at anyone carrying a stolen kid within 25 studs: the carrier gets a red outline for 3 s and Hector points. Marches busted smugglers into Detention. | 1.2 |

### Cutscene rules
**[EXISTS]** in `Cutscene.client.lua`:
- The Intro and the Board review cutscene. The review uses the Board Room at y = 400
  (`BoardRoom`, BoardSeat x5, Podium, PlayerMark, CameraA/B).
- `BoardService` swaps the school 4.2 s in, while the screen is covered.

**[CHANGE]** Each tier beat has **three shots, 8-12 s, at most three spoken lines**:
- Shot 1: the student the Board required (`Config.Tiers[n].needs`) gets their moment.
- Shot 2: the story line.
- Shot 3: the camera cuts to **your plot** as the new building finishes. Grimm reads that tier's
  existing `Config.BoardLines[n]` line over it.
- The payoff is always your school, not a menu.

Mechanics:
- Letterbox bars tween in over 0.3 s. Camera moves use Quad InOut.
- The dialogue box shows a ViewportFrame portrait and types at 40 characters per second.
- On the first viewing, Skip appears after 2 s. Every beat can be rewatched in a **Scrapbook** tab of the School Board panel.
- Other players see the Board's APPROVED stamp slam in the sky over your school, fireworks, and Riley's banner.
- Music: the existing context track `board` (Brass Fanfare) plays under the beat. Relaxed Scene ducks to 30 %.
- Founder's Chime: the end card rings the first N notes of a 12-note tune on one bell sample.
  - The sample is the existing `Sounds.Sfx.Bell`, repitched with `PlaybackSpeed = 2^(st/12)`.
  - Notes in semitones: 0 4 7 12 11 7 4 5 9 7 4 0.
  - There is no counter UI.

### One beat per tier

| # | Tier (needs) | Shot 1 | Shot 2 (story) | Shot 3 (your plot + Grimm reads the BoardLine) |
|---|---|---|---|---|
| 1 | **Kindergarten, "Day One"** (first join, 7 s) | Otis's bus hisses to a stop and you step off. Otis: "Doors closin'!" | Wobblesworth hurries up with a key the size of a surfboard: "New principal! Back in MY day we had ONE desk!" A plank falls off your boarded-up window. | Vex's limo glides past your gate and the window lowers: "Cute crayon box. Tick tock." Title card: KINDERGARTEN, DAY 1. |
| 2 | **Elementary** (Hall Monitor) | Your Hall Monitor kicks the Board Room door open, salutes and blows the whistle. | Kevin: "Can we get a waterslide?" The whole Board: "No." | Red brick sweeps across your walls and the clock gable pops up. "Elementary! Don't let it go to your head, Principal." |
| 3 | **Middle School** (Band Geek) | Band Geek plays a fanfare with one sour note, and the sleeping Board member jolts awake. | Kevin: "Okay, but a SMALL waterslide?" Grimm: "No." | Floor 2 drops onto your school like a toy brick (camera shake). The lobby lockers slam open in a domino wave. The BoardLine plays. Goo Gary starts visiting. |
| 4 | **High School** (Star Quarterback) | The Quarterback throws a spiral through the Board Room window (glass tinkle). The ball bonks the sleeper: "AYE!" | A pink-eyed silhouette on the window ledge: "Pssst... nice school." (first Sugar Baron sighting) | The portico columns rise at your entrance. The BoardLine plays. Golden Wrappers start dropping. |
| 5 | **Prep School** (Valedictorian) | The Valedictorian at the podium: "Thank. You. Board." Grimm dabs a tear. | Vex slides a fruit basket across the table: "For the Board. No reason." Kevin eats a banana and votes for you anyway. | Every seated kid tweens into a navy blazer (shirt recolour) and floor 3 lands. The BoardLine plays. |
| 6 | **Private Academy** (Prom King) | The Prom King makes his entrance under a spotlight and accidentally crowns Grimm. | Vex at the window: "MARBLE?! Fine. My Homework Factory goes RIGHT ACROSS THE STREET." | The walls turn marble and the clock tower rises. Across the road, Vex's billboard lights up. The BoardLine plays. |
| 7 | **Community College** (Kid Genius) | Grimm unveils a 40-bar chart. Kid Genius's brain glows and he explains it in 0.3 s. | Vex's tablet beeps: "Homework Machine: 12 % complete." | Green college walls. The plinth for the Founder's Statue appears on your lawn (Builder unlock). The BoardLine plays. |
| 8 | **State University** (The New Kid) | The Board turns around. The New Kid is already standing right behind them, eyes glowing. Everyone screams. | Stan, mopping in the corner: "That statue plinth on your lawn... it blinked." | The bell tower rises. The Chime rings 8 notes from your own belfry for the first time. The BoardLine plays. |
| 9 | **Ivy League** (Tiny Professor) | The Tiny Professor lectures from on top of a stack of 20 books. | The Sugar Baron crashes through the skylight and trips, and the cake hat rolls away. It's KEVIN: "I just wanted a WATERSLIDE!" Grimm: "Detention." | Ivy crawls up your walls (green blocks scaling in). Kevin, led past your gate: "...I may have franchised." |
| 10 | **Wizard School** (Pop Star Kid) | Pop Star Kid sings one note, and the Board Room starts to float (camera bob). | Wobblesworth, misty-eyed: "I dropped out of wizard school, you know. Couldn't pronounce the spells." | Spires with glowing orbs, and floating candles bobbing around them. The BoardLine plays. |
| 11 | **Space Academy** (Child CEO) | Child CEO signs a cheque, and a rocket blasts the Board Room into orbit. | Kevin, out of detention, finally gets his waterslide, in zero-g. Water blobs drift everywhere. Otis at the window, looking at the stars: "Home." | The rooftop rocket. "Space Academy. Please return the Board's chairs from orbit." |
| 12 | **Multiverse University** (any Secret) | Your Secret steps up and reality glitches (Student #404 particles). | All five Board members together: "Motion... APPROVED... in EVERY universe." | The portal ring on your roof ignites. Prompt: "Walk through the Portal to begin Graduation Day." |

### Finale: "Graduation Day"
It runs 55 s, once, when you walk through your Portal. It can be skipped on later viewings and is kept in the Scrapbook.
1. Dusk over your Multiverse University. Otis's bus pulls up, and for the first time ever Otis gets out.
   He takes off his aviators: his eyes are galaxies. "Forty years I've been drivin' kids from every
   universe to this street, lookin' for a school big enough for all of 'em. Took you long enough."
2. Vex's limo crashes through. The Homework Machine unfolds: a 30-stud grey part-built robot with a red Neon eye.
   Vex: "If I can't have the multiverse, NOBODY gets recess!" Your actual seated students line up beside you.
3. The bronze Founder's Statue cracks to life (the build from tier 7) and bonks the machine with a giant bronze Ruler.
   The machine's beam backfires and shrinks Vex into a kid with red glowing eyes and a homework stack: the existing
   Secret **The Kid Who Reminded The Teacher About Homework**.
   Tiny Vex: "...Can I still enroll?" Kevin: "Can SHE get a waterslide?" Everyone: "NO."
4. The Founder hands you the Golden Key. Wobblesworth: "Splendid. Simply splendid." Otis: "Doors closin'!"
5. Credits, the **Yearbook Parade**: every student you have owned walks the carpet in rarity order, 0.3 s
   apart, for at most 60 s, to Relaxed Scene at full volume. End card: "PRINCIPAL OF THE MULTIVERSE. ★ unlocked."

Rewards:
- Title "Principal of the Multiverse".
- Golden Key Ruler skin and Founder's Bench decor.
- Tiny Vex sits on your Waiting Bench for free: "I'll be good. Mostly."
  - She is worth $22M/s, against a strong player's roughly $300B/s at this point, so no pacing effect.
- ★ Prestige ranks unlock. These already exist in `Config.PrestigeStep`: x3 cash and +10 % each.

After the finale:
- Each ★ review plays a 6 s beat from a pool of 10. Kevin asks for ever sillier waterslides
  ("on the MOON", "made of pudding", "for the waterslide"), and Grimm now answers "Approved."

---

## 2. The first 5 minutes

### What already exists and what changes
**[EXISTS]**
- `Main.server.lua`: a brand-new principal gets the Intro cutscene. Then, **14 s later**, a shared
  **Welcome Bus** brings the six $9-$24 starters (total $99) onto the carpet.
- `QuestService` + `Config.Tutorial` run an 11-step To-Do chain: enroll1, enroll3, collect, pencils,
  hire, name, lock, build, rare, upgrade, board.
- `Quests.client.lua` draws the card and the guide beam and arrow.
- `PatrolService` sends the first cheater 42-78 s after joining and the first dealer 105-182 s after
  joining.

**[CHANGE]**
1. **Cut the Intro to 7 s and 3 lines** (beat 1 above). Today it is 5 lines plus a 14 s wait.
2. **The Welcome Bus parks at the new player's own gate** and its six kids wear **RESERVED: [name]**
   ribbons.
   - Server: `model:SetAttribute("ReservedFor", userId)` and `ReservedUntil = now + 120`.
     `HallService.enroll` refuses anyone else.
   - This fixes two problems. Other players can snipe the kids today, and two new players joining
     within 13 s would park two buses on the same `PARK` spot.
3. **PatrolService:** the first cheater is the scripted one below. **No dealer is sent before tutorial
   step 11.**
4. Replace `Config.Tutorial` with the 11 steps in the script below. The old pencils, hire, build, rare
   and upgrade steps move into Chapter 1 (section 12), after minute 5.

### Rules for the script
- A new verb or a reward every 10-15 s.
- At most 8 words per speech bubble.
- No menus before 3:20. **No purchase prompts** during the tutorial. No unsolicited offer before 20:00.
- **At most 3 goals on screen:** the To-Do card, the Letter envelope and the School Board button.
- One pop-up at a time. Tutorial beats wait behind server banners, except Secret banners.
- Idle for 8 s: the guide arrow pulses and Wobblesworth repeats a shorter line.
- Every step is saved in `p.tutorial` and resumes where it stopped. Returning players skip all of it.
- Each step logs `AnalyticsService:LogOnboardingFunnelStepEvent(player, step, name)` for steps 1-16.
- **Freshman Shield [NEW, in StealService]:**
  - For 10:00 nobody can steal from you. A striped "GRAND OPENING" ribbon hangs across your gate with
    a countdown: "FRESHMAN, PROTECTED 9:12".
  - It ends early if you steal from a real player. Scripted tutorial actors ignore it.
- **Big-kid rule [NEW, in StealService]:** a player at High School (tier 4) or above can never steal
  from a Kindergarten school. Prompt text: "Big kids don't steal from Kindergarten!"
- **Several new players at once:**
  - Every scripted actor is a server model spawned *for* that player and placed at *their* plot. That
    covers the Welcome Bus, the cheater, Vex's tent, Crumpet and the Scholarship.
  - The tent goes in the gap beside your plot (section 8.1).
  - Others can watch (it's a show), but every prompt carries `OnlyFor = userId`. `Prompts.client.lua`
    hides it for everyone else, and the server re-checks on `Triggered`.
  - Up to 8 tutorials can run at once without touching each other.

### The script (new player, first join)

| Time | What appears | Player does | Cash and state | Sound | Step |
|---|---|---|---|---|---|
| 0:00 | Fade from black. Beat 1 "Day One" (7 s, Skip at 0:02). | Watches | $100 | `BusHorn`, then Relaxed Scene fades in at 40 % | 1 intro |
| 0:07 | Control. You stand at your gate. Your school is a crayon Kindergarten with **plywood planks over every window** and a CONDEMNED sign on the door. Wobblesworth waves: "New principal! Your school's EMPTY!" | Walks | | `Ding`, blips | |
| 0:09 | The **Welcome Bus** pulls up at *your* gate curb. Six kids hop off with RESERVED ribbons. Untied Tyler trips on his laces stepping down: "oof!" (first laugh). Ground chevrons point at him. | | | `BusHorn`, new "cartoon oof" | 2 bus |
| 0:12 | Prompt "ENROLL $9" | Presses E | $91, then +$40 = **$131**. Tyler cheers and jogs in. | `Enroll` (pitch 1.0) | 3 enroll1 |
| 0:14 | To-Do: "Enroll the rest of the Welcome Bus" | Enrolls Gus, Dot, Lucy, Pete, Hank ($90) | $41, then +$80 = **$121**. Income $3.3/s. | `Enroll` rising 1.05 to 1.25 per kid | 4 enroll6 |
| 0:28 | The six sit down (sit plus a 0.1 s settle bounce). Pads glow and float "+$0.3". To-Do: "Walk over a glowing desk pad". | Steps on pads | About +$15, then +$60 = **~$196** | `Collect` (pitch rises with the amount) | 5 collect |
| 0:36 | The HUD slides in one element every 0.4 s: $/s under cash; the bus strip at top centre ("HONOR ROLL BUS 6:12 · LEGENDARY+"); the **Admissions Letter** envelope on the right edge: "RARE LETTER 3:44". | | | `Whoosh` x3 | |
| 0:40 | Wobblesworth: "Green outline means you can afford it." The **Pocket Money Promise** (section 3) guarantees Dog-Ate-My-Homework Doug ($75) walks past within 10 s. | Enrolls Doug (optional) | ~$121, $5.8/s, 7/8 desks | `Enroll` | |
| 0:58 | **Scripted cheat:** Glue Stick Gus squeezes glue onto a cheat sheet and slaps it on his desk. His eyes dart and a yellow "?" appears. | | | New "pencil scribble" (3D), `StingWhat` | 6 cheat seen |
| 1:02 | Wobblesworth: "Is Gus... COPYING?! Catch him!" | Walks in | | | |
| 1:05 | Prompt "CATCH!" (hold E 0.4 s). A red "CAUGHT!" stamp. Gus jumps. | Catches | Fee = 60 s of Gus ($24), plus a First Catch bonus of **$100** | New "referee whistle", `Gavel` | 7 catch |
| 1:07 | Walk of shame to the **Principal's Office** (the existing bench and route): head down, walk x0.55. His Polaroid flashes onto the **Wall of Shame**. Wobblesworth: "You have an OFFICE!" | Watches | | "dun dun DUNNN" sting (new) | |
| 1:20 | **"THE BOARD SENT YOU WINDOWS!"** The free `Curtains` build (section 8). The planks pop off one window at a time (0.05 s stagger: each plank unanchors, spins and fades over 1 s). Glass shines, curtains drop, and flower pots bounce onto the sills. CONDEMNED flips to OPEN. "+1 REPUTATION". The **Builder** tab gets a red "!". | Watches | +1 Rep | New "wood plank pop" x N, `Upgrade`, `Cheer` | 8 windows |
| 1:30 | Gus walks back with a halo: "REFORMED +10 %" (5 min). | Free play | ~$360 | Angelic chime (new) | |
| 2:10 | **Vex's limo** parks in the gap beside your plot. Crumpet unfolds a striped tent: **"VEX ACADEMY: RECRUITMENT TENT"**. **Tattletale Tina** ($300 Uncommon) sits inside with a "HELP I'M BORED" sign. Vex: "My school's first student! ...I borrowed her." | | | New "limo horn", `StingWhat` | 9 tent |
| 2:14 | Wobblesworth: "Bring her home! Hold E!" A red guide beam points to the tent. | Runs about 50 studs | | | |
| 2:25 | The **real Steal prompt** (StealService, hold E 1.5 s with a ring). Tina goes over your head and flails. You carry her at `Config.CarrySpeed` 11. Crumpet trails you at 8 studs/s, dusting you: "Terribly sorry, I must insist." **He can never catch you.** | Carries | | Context music `stealing` (Sketch Adventures) | 10 rescue |
| 2:40 | You cross your gate: **"RESCUED!"** If a desk is free, Tina sits down (free, $5/s). If the school is full, she sits on your **Waiting Bench** and Wobblesworth says "Full house! Hold F on a kid to send them home." That teaches Sell. | Sells Tyler if full | +$4.50 sell | `Cheer`, confetti | 11 rescued |
| 2:45 | The **Ruler** bounces into your hotbar. Crumpet steps through *your* gate: "Terribly sorry. I'm taking this child." He lifts Hiccup Hank and walks off at 6 studs/s. A red THIEF! arrow appears. Tina stands and points: "TEACHERRR!" | | | `Alarm` | |
| 2:52 | Wobblesworth: "Bonk him with your Ruler!" | Swings | A bonk (stars over Crumpet). Hank drops, sees dizzy stars for 1.5 s and walks back to his desk. Crumpet: "Most irregular." **+$100 DEFENDED!** | `Swing`, new "cartoon bonk" | 12 bonk |
| 3:02 | The red lock button at your gate pulses. | Presses it | Lasers rise and a 60 s countdown appears. Crumpet comes back with a fresh duster, bonks into the lasers, backflips and lands sitting: "I shall inform Madam." Wobblesworth: "Nobody can steal from you for 10 minutes. After that, LOCK it." **+$400** | `Lock`, new "slide whistle down" | 13 lock |
| 3:20 | The **Name Your School** panel opens (existing): name (TextService filtered), 6 mascots, 3 colours. The gate sign flips split-flap style and your mascot flag runs up the yard flagpole. Server toast: "Welcome Hilltop Hot Dogs to Recess Row!" | Names it | **+$300** | New "drumroll", `Cheer` | 14 name |
| 3:40 | To-Do: "Fill all 8 desks". The Pocket Money Promise shows Loose Tooth Lou ($360, dragging a door) and Cardboard Robot Rudy ($420). | Buys, sells | ~$11-15/s | `Enroll` | |
| 4:10 | The envelope bounces: "RARE LETTER 0:10". The **mailbox flag** at your gate flips up. | | | `Token` | |
| 4:20 | The Welcome Bus returns with a blue beam. Banner: "[Name], your SCHOLARSHIP STUDENT has arrived!" **Teacher's Pet** (Rare, $5,400, $45/s) steps off. Her $5,400 tag is struck through and replaced with **FREE**. She sits on your Waiting Bench. | Sells the cheapest kid (hold F), then presses E at the bench | **~$12/s to ~$57/s (x4.7)**. The $/s number punches three times. "RARE ENROLLED!" | `Rare`, `Choir2` | 15 scholarship |
| 4:40 | Kevin's face pops in a toast from the School Board button: "Hi! Bring $680K and a Hall Monitor and we'll make you an Elementary School! Also, can we get a waterslide?" | | | Blips | |
| 4:50 | The three goals lock in: (1) To-Do "Buy Sharpened Pencils ($250)"; (2) envelope "RARE LETTER 6:00"; (3) Board "Elementary: $680K + Hall Monitor". | | | | |
| 4:55 | **Cliffhanger.** The light dims 10 %. A pink-eyed silhouette with a cake hat stands on the Sugar Shack roof: "Pssst..." A trash-can lid by your gate pops up and Sweet Tooth Sal peeks out: "Sour worms? Fresh ones?" Stan leans on his mop beside you: "Snack Smugglers. Bonk 'em before they sugar up your class." | | | New "candy wrapper crinkle", "sneaky pizzicato" (APM search) | |
| 5:00 | "FIRST DAY COMPLETE!" The ribbon stays up (the Shield runs to 10:00). The 5-minute playtime gift pops: **$1,000**. | | ~$1,350, ~$57/s | `StingParty` | 16 done |

**The scripted smuggler:** Sweet Tooth Sal's first visit is at 6:00. It hands out the first 🍬 and
unlocks Stan's Confiscation Closet (section 6).

**State at 5:00:**
- 8/8 desks and about $57/s.
- One catch, one rescue, one defence.
- A named school that finally has windows.
- Three goals, a villain, a mystery, and a smuggler on the way.

**Funnel targets:**

| Step | Target | If it falls short |
|---|---|---|
| Step 4 by 0:30 | ≥ 90 % | |
| Step 11 (rescued) | ≥ 75 % | If the tent loses more than 10 %, move the tent within 40 studs of the gate. |
| Step 16 | ≥ 65 % | |

---

## 3. Guaranteed rarity timers

Natural supply per server, from the Config weights and one spawn every 2.2 s (1,636 spawns an hour):

| Rarity | Per hour, at luck 1 |
|---|---|
| Rare | about 213 |
| Epic | about 115 |
| Legendary | about 57 |
| Mythic | about 20 |
| Prodigy | 4.1 |
| Secret | 0.65 |

So the guarantees below are mostly about a known time, a ceremony, and not being sniped. They do not
add much supply.

### A. The Bell Schedule: server buses on the UTC clock
**[EXISTS]**
- `HallService.start` schedules the Late Bus (every 300 s), the Field Trip (1800 s), the Honor Roll
  Bus (900 s, offset 450, committed tonight) and Recess (900 s).
- It counts from **server start**, so every server is on a different schedule.
- The HUD already shows chips for them.

**[CHANGE]** Every timer moves to the wall clock:
- `next = offset + every * ceil((now - offset) / every)`, where `now = workspace:GetServerTimeNow()`
  (Unix time).
- Every server then agrees, and players can learn "Honor Roll at :07 and a half".
- Buses no longer share an arrival second, because they all park at the same `PARK` spot.

| Bus | UTC times | Guarantee | Config |
|---|---|---|---|
| **Late Bus** | Every 5 min at :00, :05 … :55 (skipped at :30 on even hours) | 6 kids, all Rare+. 98 % of buses carry at least one Epic+ (1 - 0.52^6). | [EXISTS] `LateBus`, add `offset = 0` |
| **Honor Roll Bus** | :07:30, :22:30, :37:30, :52:30 | 1st kid: Legendary 80 / Mythic 17 / Prodigy 2.5 / Secret 0.5. Then 4 kids from Epic 70 / Legendary 25 / Mythic 5. | [EXISTS] `HonorBus`, `offset = 450` now counts from the hour |
| **Field Trip** | :12:30 and :42:30 | 8 kids, Epic+ | [EXISTS] `FieldTrip`, add `offset = 750` |
| **Principal's Pick** | :30 on even UTC hours (00:30, 02:30 … 22:30) | 1 kid: **Prodigy 95 / Secret 5** | [NEW] |
| **Recess** | :00, :15, :30, :45 | Luck x2 for 60 s, bus 1.5x faster | [EXISTS] |

**Secret supply check:**
- Honor Roll adds 4 x 0.005 = 0.02 an hour.
- The Pick adds 0.5 x 0.05 = 0.025 an hour.
- That is **+7 %** on the natural 0.65 an hour. A guaranteed Secret every 2 h would be +77 %.
- Secret stays unguaranteed.

**Principal's Pick staging** (P3's sequence, capped at Prodigy):
- **T-5:00:** global toast. Riley: "STOP THE PRESSES! The Principal's Pick arrives in FIVE MINUTES!"
- **T-60 s:**
  - The music fades to a ticking clock (new APM search: "suspense ticking clock").
  - `Lighting.ClockTime` tweens to 19.5 (dusk) over 20 s.
  - The 26 street lamps (map `Deco/Lamp`) switch on one at a time from the bus end, 0.3 s apart.
- **T-10 s:** a giant countdown for everyone, with drum hits.
- **T-0:**
  - A black stretch limo pulls in: a 30-stud part-built body with rainbow Neon underglow strips and 2 PointLights.
  - Otis, in a chauffeur cap, opens the door.
  - The kid steps onto a gold Neon runner laid over the carpet.
  - Granny Stopsign raises a "PICK" paddle and Riley's flash fires.
  - Lighting tweens back to day after 90 s.

**How a guaranteed kid is shown** (every bus above):
- A gold "GUARANTEED" ribbon on the billboard, and the billboard at 1.5x size.
- A spotlight cone (Neon, transparency 0.75) follows the kid.
- The kid walks at 0.7x speed, so a crowd has time to form.

**HEIST ALERT [NEW, StealService]:** when anyone enrolls a Prodigy or Secret:
- A 60 s beam rises over the buyer's school, with the text "THE PRODIGY IS HERE" and a distance marker for everyone.
- At the same moment **the buyer's lock cooldown is reset**, and they get a toast: "LOCK NOW!"
- Buying becomes a defence story. The engineer's condition is met: the lock refresh is guaranteed.

### B. Personal Admissions Letters (the guarantee that is yours)

| Letter | Fills every (minutes in a server, active) | The first one |
|---|---|---|
| Rare | 6 min | The free Scholarship at 4:20 in your first session |
| Epic | 30 min | The 20-minute playtime gift fills it |
| Legendary | 90 min | |
| Mythic | 5 h | |
| Prodigy | 20 h | |
| Secret | never | Secret stays unguaranteed (player judge) |

Rules:
- **Filling:**
  - A letter fills while you are in a server and moved in the last 2 minutes.
  - **Offline it fills at 25 % speed**, counting at most 12 h.
  - A letter never overflows. It stops at **READY**, and the mailbox flag at your gate goes up. That is
    the return hook.
- **CALL:**
  - CALL works only if you can afford the cheapest kid of that rarity. Otherwise the card reads
    "Cheapest Epic: $72K. You have $41K." The wait becomes a saving goal, not a tease.
- **Who comes:**
  - A random kid of that rarity **that you can afford now**.
  - The kid the Board needs next (`Config.Tiers[p.tier + 1].needs`) gets **x3 weight** (the Board Candidate).
  - The grade rolls normally.
- **Delivery:**
  - The Welcome Bus drives to your gate within 10 s, and the kid walks to your **Waiting Bench**.
  - You pay the **list price** when you enroll them from the bench. Guaranteed means a reserved chance
    to buy, never a free kid (the only exception is the tutorial Scholarship).
- **Waiting Bench [NEW]:**
  - Three seats in your front yard at plot-local (-22, 0, 64), facing the walk and tinted in your school colour.
  - A kid holds a seat for **10:00** and **cannot be stolen** while seated there.
  - If a new delivery needs a seat and the bench is full, the oldest kid stands, waves, and walks onto
    the carpet as a normal public kid. Toast: "Nerd Ned got tired of waiting!"
  - Rescued tutorial kids and Alumni vouchers also use the bench.
- **HUD:**
  - One envelope stack on the right edge. The top card is the next letter to fill, or a READY one,
    with a wax seal in the rarity colour.
  - Tap it to see all five.
- **Server:**
  - Data: `p.letters = { Rare = secondsLeft, ... }`.
  - `model:SetAttribute("ReservedFor", userId)` and `ReservedUntil`, checked in `HallService.enroll`.
  - New `BenchService`, or bench slots in `PlotService`.

### C. Pocket Money Promise [NEW, HallService]
Keeps the carpet useful for new players.
- Every 20 s the server checks each active player at **Kindergarten or Elementary**.
- If no kid on the carpet costs no more than their cash, the next regular spawn is replaced by the most
  expensive Common or Uncommon they can afford. It is the Hall Monitor if that is affordable and needed.
- That kid wears a green "DEAL!" sticker.
- It is not reserved, so it cannot be farmed later.

### D. How the timers are shown and announced
- **Top centre** (the existing HUD chips): the next 3 events as pills. Each shows an icon, a name, a flip
  countdown, the rarity colour and the guarantee text ("RARE+", "LEGENDARY+", "EPIC+", "PRODIGY").
- **T-60 s:** the pill pulses and Riley shouts it.
- **T-30 s:** `SchoolBell`.
- **T-10 s:** the existing Announce banner ("THE HONOR ROLL BUS ARRIVES IN 10s!") and `BusHorn`.
  The carpet trim glows in the rarity colour.
- **The Bell Schedule board [NEW]:** a 12-stud split-flap board facing the street in the centre-north
  gap, and a small copy at the bus shelter.
  - Each character is a TextLabel that flips (UIScale Y 1 to 0 to 1 in 0.08 s) with a clack when the minute changes.

```lua
-- Config sketch (offsets are seconds after the UTC hour; every = period)
Config.LateBus = { every = 300, offset = 0, count = 6, minRarity = 3, skipFor = "PrincipalsPick" }
Config.HonorBus = { every = 900, offset = 450, count = 5, first = { Legendary = 80, Mythic = 17, Prodigy = 2.5, Secret = 0.5 }, weights = { Epic = 70, Legendary = 25, Mythic = 5 } }
Config.FieldTrip = { every = 1800, offset = 750, count = 8, weights = { Epic = 60, Legendary = 30, Mythic = 8, Prodigy = 1.8, Secret = 0.2 } }
Config.PrincipalsPick = { every = 7200, offset = 1800, count = 1, weights = { Prodigy = 95, Secret = 5 } }
Config.Recess = { every = 900, offset = 0, length = 60 }
Config.Letters = { Rare = 360, Epic = 1800, Legendary = 5400, Mythic = 18000, Prodigy = 72000 }
Config.LetterOffline = { rate = 0.25, capHours = 12, afkPause = 120 }
Config.Bench = { seats = 3, hold = 600 }
Config.PocketMoney = { every = 20, maxTier = 2 }
```

**Economy:** measured. See 0.3, rows C and D: letters, the free Scholarship and the Pick together.

---

## 4. New cheap starter students (8)

**[EXISTS]**
- Six starters at $9-$24 (committed tonight): Untied Tyler, Glue Stick Gus, Doodle Dot, Lunchbox Lucy,
  Pajama Pete, Hiccup Hank. They arrive on the Welcome Bus for $99 in total.
- `formatCash` already shows one decimal for small fractions.

These 8 do not repeat those gags or names. They fill the two places the ladder still stalls:
- Variety between $30 and $100 (there is nothing between Sleepy Sam at $30 and Crayon Eater at $60).
- The empty **$180 to $480** jump from the top Common (Sneezy Sid) to the first Uncommon (Class Clown).

Pricing:
- Every price is exactly income x payback: Common 30 s, Uncommon 60 s.
- `retune.py` leaves all 8 unchanged (checked).
- With these, the roster is 70 students.

| id | Name | Rarity | Price | $/s | Subject | Prop key | Gag | Role |
|---|---|---|---|---|---|---|---|---|
| `PuddlePip` | Puddle Jumper Pip | Common | $45 | 1.5 | Science | `RainCloud` | Dressed for rain in all weather, with a personal raincloud | First Pocket Money kid |
| `HomeworkDoug` | Dog-Ate-My-Homework Doug | Common | $75 | 2.5 | English | `Puppy` | Brought the dog as proof. The puppy barks when a stranger nears his desk. | A cute early alarm |
| `RecorderRosie` | Recorder Rosie | Common | $210 | 7 | Music | `Recorder` | Plays one wrong note every 12 s | Fills the $180-$480 gap |
| `FrogFran` | Frog-in-Pocket Fran | Common | $240 | 8 | Science | `Frog` | Her frog, Sir Hops, goes everywhere | Fills the gap |
| `MimeMimi` | Mime Mimi | Common | $270 | 9 | Drama | `MimeBeret` | Trapped in an invisible box. Her bubble only ever says "..." | Fills the gap |
| `TattletaleTina` | Tattletale Tina | Uncommon | $300 | 5 | History | `Clipboard` | "TEACHERRR!" Tells on cheaters and thieves. | Tutorial rescue kid, cheat spotter |
| `LooseToothLou` | Loose Tooth Lou | Uncommon | $360 | 6 | Math | `ToothDoor` | "Mom said just slam the door. So I brought the door." | Fills the gap |
| `CardboardRudy` | Cardboard Robot Rudy | Uncommon | $420 | 7 | Tech | `CardboardBot` | Believes he is a robot: "BEEP BOOP." | Fills the gap |

```lua
-- Common block, after SneezySid
S("PuddlePip", "Puddle Jumper Pip", "Common", 45, 1.5, "Science", "RainCloud", "light", rgb(255, 215, 40), rgb(60, 110, 200)),
S("HomeworkDoug", "Dog-Ate-My-Homework Doug", "Common", 75, 2.5, "English", "Puppy", "tan", rgb(220, 60, 60), rgb(70, 70, 80)),
S("RecorderRosie", "Recorder Rosie", "Common", 210, 7, "Music", "Recorder", "brown", rgb(250, 130, 160), rgb(90, 60, 140)),
S("FrogFran", "Frog-in-Pocket Fran", "Common", 240, 8, "Science", "Frog", "brown", rgb(250, 140, 170), rgb(60, 120, 80)),
S("MimeMimi", "Mime Mimi", "Common", 270, 9, "Drama", "MimeBeret", "light", rgb(245, 245, 245), rgb(25, 25, 30)),
-- Uncommon block, at the top
S("TattletaleTina", "Tattletale Tina", "Uncommon", 300, 5, "History", "Clipboard", "tan", rgb(150, 90, 200), rgb(60, 60, 80)),
S("LooseToothLou", "Loose Tooth Lou", "Uncommon", 360, 6, "Math", "ToothDoor", "brown", rgb(90, 190, 110), rgb(70, 60, 50)),
S("CardboardRudy", "Cardboard Robot Rudy", "Uncommon", 420, 7, "Tech", "CardboardBot", "light", rgb(170, 130, 85), rgb(80, 80, 90)),
```

**HAIR entries** (`StudentProps.HAIR`):

| Kid | Hair |
|---|---|
| Doug | rgb(120, 80, 50) |
| Rosie | pigtails, rgb(60, 40, 30) |
| Fran | rgb(30, 22, 18) |
| Tina | rgb(120, 60, 30) |
| Lou | rgb(20, 16, 14) |

Add `RainCloud`, `MimeBeret` and `CardboardBot` to `NO_HAIR`. Pip's hood covers his hair, so he gets
only a fringe blob.

### Prop builds
Conventions (the same as `StudentProps`):
- Offsets are in the body part's local space: +X right, +Y up, -Z forward.
- `hs` = head size, `ts` = UpperTorso size, `LT` = LowerTorso size.
- Idle gags run client-side in the Puppet module (section 11). The server only builds the parts.

**Puddle Jumper Pip (`RainCloud`)**
- **Clothes:**
  - Yellow hood: `blob(head, (hs.X*1.22, hs.Y*0.9, hs.Z*1.22), CF(0, hs.Y*0.12, hs.Z*0.08))`.
  - Brim: `blob(head, (hs.X, hs.Y*0.12, hs.Z*0.5), CF(0, hs.Y*0.38, -hs.Z*0.45))`.
  - Coat skirt: `cylY(LowerTorso, LT.X*1.45, 1.0, CF(0, -0.3, 0))` in yellow, with three dark toggle
    blocks 0.25 x 0.12 x 0.08 on the chest.
  - Red rain boots: `block(foot, (0.95, 1.1, 1.25), CF(0, 0.3, -0.05))` on each foot.
- **The cloud:**
  - Three grey balls (d 1.3, 1.0 and 0.9) on a `pivot` 2.2 x hs.Y above the head.
  - The middle ball has a ParticleEmitter: rate 25, lifetime 0.5, speed 6, size 0.12, direction Bottom,
    spread 20°, colour rgb(90, 170, 255).
- **Puddle:** a dark-blue Glass disc (cylinder 0.05 x 3, transparency 0.3) under his desk while seated.
- **Gag:**
  - On the carpet, every 8 s he does a puddle hop: the root arcs 1.2 studs over 0.4 s.
  - A splash ring of 8 small blue balls expands over 0.3 s.
  - Sound: new "water splash small".

**Dog-Ate-My-Homework Doug (`Puppy`)**
- **Homework in the left hand:**
  - Two white blocks in an L-shape, with one corner missing.
  - Three tiny white wedges along the missing edge as tooth marks.
  - SurfaceGui text "HOMEWORK" in blue.
- **Puppy:** on a hidden root welded to LowerTorso at `CF(1.5, -1.9, -0.3)`.
  - Body blob 0.9 x 0.8 x 1.4, rgb(185, 130, 75). Head ball 0.85. A lighter snout blob.
  - Black nose ball 0.18. Eyes are 0.13 balls.
  - Floppy ears: blocks 0.18 x 0.55 x 0.32, rgb(110, 70, 40), rolled ±20°.
  - Pink tongue: block 0.18 x 0.04 x 0.25. Four leg cylinders, d 0.22.
- **Tail:** a cylinder (d 0.14, length 0.55, angled 40°) on its own weld.
  - It wags ±25° at 6 Hz, and at 12 Hz for 1 s when Doug is enrolled.
- **Gag:** when a non-owner comes within 12 studs of Doug's desk, the puppy barks.
  - Only the owner hears it (10 s cooldown), with a "WOOF!" bubble. Cute, and an early warning.

**Recorder Rosie (`Recorder`)**
- Brown pigtails: two balls d hs.X*0.38 at ±hs.X*0.62, with pink band cylinders.
- **Recorder:** a cream cylinder, d 0.18 x 1.4, held diagonally at the mouth by the left hand.
  - Four 0.06 black balls along it as finger holes, and a brown bell end (d 0.26 x 0.2).
- **Gag:** every 12 s she plays a squeak at a random pitch (0.8-1.4) with a floating "♪" BillboardGui.
  - One in 5 squeaks is a terrible one: the kids either side cover their ears (shoulders -150°) for 1 s.
  - Sound: new "recorder squeak".

**Frog-in-Pocket Fran (`Frog`)**
- **The frog, on her head,** all on a hidden FrogRoot:
  - Green body blob (hs.X*0.62, hs.Y*0.36, hs.Z*0.58), rgb(90, 200, 80). A pale belly blob.
  - White eye balls (d hs.X*0.17) with black pupils. A dark-green mouth line. Folded back-leg blobs.
- **Glass jar in the right hand:** a red lid with four black air-hole dots, and a fly inside (black ball 0.1).
- **Gag:**
  - Every 6 s the frog hops: FrogRoot C0 arcs 0.8 studs over 0.35 s. 30 % of hops end in a croak (new "frog croak").
  - At her desk, every 20 s a pink tongue (0.08 x 0.04 x 1.0) flicks out and back in 0.1 s at the fly.

**Mime Mimi (`MimeBeret`)**
- Head colour rgb(245, 245, 245). Five thin black bands around the torso (striped shirt). Black pants.
- **Beret:** a black ball scaled (1.2, 0.3, 1.2), tilted 15°. A red scarf block 0.9 x 0.3 x 0.9 at the neck.
- **Invisible box:** a 2.2 cube at transparency 1, with a SelectionBox that flashes on for 0.2 s after each "push".
- **Gag:** every 15 s she presses on the invisible walls.
  - Both shoulders at -1.5, elbows at -0.3, with a 0.04 press at 3 Hz.
  - Her bubble only says "...".

**Tattletale Tina (`Clipboard`)**
- **Pigtails:** hair blobs 0.35 x 0.6 x 0.35 at (±hs.X*0.55, hs.Y*0.05, hs.Z*0.1), with red bobble balls (0.16).
- **Clipboard in the left hand,** tilted 20° toward her face:
  - Brown board 1.0 x 1.35 x 0.08, white paper 0.86 x 1.1 x 0.02, a silver Metal clip.
  - SurfaceGui list in red: "Gus: BAD / Dot: good / Pete: SUS".
- Yellow pencil behind her ear. A gold Neon star sticker on her chest.
- **Ability (hooks into section 5):**
  - When a cheat starts on her floor, she stands on her chair (+1.2 studs) and points at the cheater
    (a procedural shoulder aim): "TEACHERRR!"
  - Catching that cheater within 10 s counts as Eagle Eye (x1.5).
  - She also points at anyone carrying a kid past her: "THIEF! THIEF!"
  - She never cheats.

**Loose Tooth Lou (`ToothDoor`)**
- **Tooth:** a white block 0.12 x 0.16 x 0.06 at head `CF(hs.X*0.05, -hs.Y*0.18, -hs.Z*0.53)`, wiggling ±12° at 5 Hz.
- **Door:** 1.2 x 2.0 x 0.15 Wood, rgb(150, 95, 55).
  - A glass window 0.5 x 0.6 and a brass ball knob (0.16).
  - Welded to LowerTorso at `CF(0, -0.6, 3) * Angles(60°, 0, 0)`, so it scrapes along behind him.
- **String:** a white **Beam** (width 0.05) from an Attachment on the tooth to one on the knob. It follows automatically and needs no physics.
- **Gag:**
  - A scrape sound while he walks. Seated, the door leans against his desk.
  - When he is sold, the tooth pops out with a toast: "+$1 Tooth Fairy money".

**Cardboard Robot Rudy (`CardboardBot`)**
- **Body box:** Cardboard material, `block(UpperTorso, (ts.X*1.55, ts.Y + LT.Y + 0.2, ts.Z*1.7))`.
  - "RUDY-3000" in `Enum.Font.PermanentMarker` on the front.
  - Three bottle-cap buttons: red, blue and green `cylZ`, d 0.32.
- **Helmet:** an open-front box (top, back, two sides and a brow strip), so his face shows.
- **Antenna:** a bendy straw (four alternating red and white cylinder segments with a 30° bend) topped by a Foil ball (d 0.35).
- **Arms:** four Foil rings (d 0.55) on each arm, as dryer hose.
- **Gag:**
  - Every 5 s his head snaps 90° left, then right (new "servo short").
  - A "BEEP BOOP" bubble when enrolled.
  - At Recess he does the robot dance: arms snap between {0, ±π/2} every 0.25 s.

---

## 5. Catching cheaters

### What already exists and what changes
**[EXISTS]** `PatrolService` (uncommitted):
- Every 70-130 s one seated kid starts cheating. A cheat sheet appears in their hand, a "❗ CHEATING!" tag,
  a Neck look-around, and the kid earns nothing.
- The owner holds E for 0.4 s on "Catch Cheater!". The kid walks to the Office bench
  (`SchoolBuilder.officeRoute`, 3 `BENCH_SEATS`) for 20 s of DETENTION, then returns. The owner gets a
  **detention fee of 30 s of that kid's income + $5**.
- Missed for 40 s: that desk's stored cash is wiped.
- Any teacher with `mult >= 1.5` (Ms. Honeycutt and up) auto-catches after 12 s.

**Why it changes:**
- As built, a catch costs you money. The kid earns nothing while cheating (about 10 s), then nothing
  during the walk and detention (about 30 s). The fee repays only 30 s.
- That is roughly **-10 s of that kid's income per catch**, before any miss. At 8 desks that is about -1 %.
- Catching should feel like winning. So:

**[CHANGE]**
1. **A kid keeps paying tuition during the whole office trip** (P1). They cannot be stolen while in the office.
2. **The fee is 60 s of that kid's tuition** (all multipliers), x1.5 for an **Eagle Eye** catch (within
   10 s, or while Tina is pointing). There is a one-time First Catch bonus of $100.
3. **Reformed:** +10 % on that kid for 5:00, shown as a halo and a "REFORMED" line.
4. **Missed at 40 s:** the kid gets a red **F** tag and earns x0.5 for 2:00. The cheat spreads to the
   neighbouring desk. The desk cash is **no longer wiped**, because on a pad without the Janitor that
   could be many minutes of income.
5. **Auto-catch only by strict teachers:** Mr. Chalk, Ms. Honeycutt, Dean Maximus and The Omniteacher.
   It happens at 12 s and pays **half** the fee with no Reformed.
   - Today every teacher from Ms. Honeycutt up catches, which turns the minigame off for everyone past
     Middle School.
6. **Frequency:** every **90-150 s** per school instead of 70-130. Only while the owner is in the
   server and moved in the last 60 s, and halved if they are more than 150 studs from their gate.
   Never during the tutorial, except the scripted one.
7. **At most one active cheat per floor.** The office bench seats 3.

### What cheating looks like (3 tells at launch)
Every cheater, whatever the method, gets:
- A yellow "?" billboard, visible only to the owner from 60 studs.
- A desk pad that turns orange.

| Method | Tell |
|---|---|
| **Sleeve Sheet** | A 0.6 x 0.8 x 0.02 white paper tweens out of the sleeve. The eyes dart (pupil parts ±0.06 in X, 0.3 s holds). |
| **Neighbour Peek** | Waist rolls 25° toward the next desk and Neck yaws 30°. The neighbour covers their paper with an arm (shoulder -80°). |
| **Phone Under Desk** | A blue Neon 0.4 x 0.7 glow under the desk and a blue PointLight (range 4) on the face, with a faint "bzzt". |

Later updates add Paper Airplane (a wedge arcs between desks), Calculator Watch (Rare+), and the golden
Answer Key (x5, Exam Week).

**Escalation within the 40 s window:**

| Stage | Time | What you see and hear |
|---|---|---|
| Shifty | 0-12 s | Animation only. Tina reveals it. Eagle Eye pays x1.5. |
| Obvious | 12-30 s | The "?" appears. Pencil scribbling is audible within 40 studs. Strict teachers act at 12 s. |
| Brazen | 30-40 s | A red "!", the pad blinks red, and a HUD pip reads "Cheater on Floor 2!" |

**Link to stealing (P3):** a kid in the Obvious or Brazen stage is distracted. Stealing them takes 1.0 s instead of 1.5 s.

### The Principal's Office
**[EXISTS]** Built by `SchoolBuilder` at the right end of the ground-floor lobby:
- Door with a PRINCIPAL plaque, rug, desk, chair, gold nameplate, shelf, plant, diploma.
- A bench tagged `OfficeBench` with 3 seats.

**[NEW]**
- **The Wall of Shame:** a 6 x 4 cork board on the divider wall above the bench, at plot-local
  (30, F1 + 6, 2.6). Each Polaroid is a 0.8 x 1 white frame with a coloured block and the kid's name.
  - The first catch of each student type pins one (70 in total).
  - The last 5 are shown big.
  - A full rarity row earns a frame trophy for the shelf.
- **The walk of shame:**
  - Gasp: arms up for 0.3 s.
  - Then Neck pitched -0.35 and walk `AdjustSpeed(0.55)`, with "dun dun DUNNN".
- **On the bench:** 20 s, with an excuse bubble every 5 s:
  - "The glue told me the answers."
  - "My dog ate my integrity."
  - "I was reading the air."
  - "The paper was ALREADY there!"
  - "I only looked a LITTLE."
- **Leaving:** the principal's bubble from the desk says "Copying is for photocopiers." The kid walks
  back with a halo.

### Rewards and titles
- **Catch counter** (`p.stats.caught`). Titles at 10, 100, 1,000 and 10,000 catches: "Eagle Eye",
  "Human Lie Detector", "The Principal Sees All", "Legend of the Office".
- **Streak:** 5 catches in a row with no miss gives **Eagle Eye mode** for 10 min. Tells show from 90
  studs, and every catch counts as Eagle Eye.
- **After 3:00 with any cheater unresolved** on a floor, those kids stand up and do a victory dance (the
  dance emote) until you arrive. Embarrassing, and harmless.
- A kid is never lost.

**Economy (measured as a stand-in, row C):**
- Catching every cheat is worth about (60 + 30) s per 150 s spread over the desks.
- That is about +7.5 % at 8 desks, +3.75 % at 16, and under 2 % at 32.
- Cheating matters most early, which is where the hook is.

**Server:**
- `PatrolService` keeps ownership.
- The tells render client-side from model attributes (`CheatStage`, `CheatMethod`) in the Puppet module.
- Signals `cheatStart` and `catchCheater` already exist.

---

## 6. Candy and slime dealers ("Snack Smugglers")

**The naming rule:**
- Player-facing text never says "deal", "dealer" or "dealing".
- They are **Snack Smugglers**, their goods are **contraband candy** and **contraband slime**, and the
  verb is **BUST!**
- **[CHANGE] strings in PatrolService and Config.Goals:**

| Current | New |
|---|---|
| "DEALING CANDY!" | "SNEAKING CANDY!" |
| "DEALING SLIME!" | "SNEAKING SLIME!" |
| Goal "Bust a candy or slime dealer" | "Bust a Snack Smuggler" |

- Code names (`sendDealer`, `DEALERS`) can stay.

### What already exists and what changes
**[EXISTS]** `PatrolService` (uncommitted):
- Every 150-260 s, one smuggler per player: **Sweet Tooth Sal** (candy) or **Goo Gary** (slime).
- He enters that player's school through an unlocked gate. A locked gate keeps him out.
- He "deals" at a row, and that row earns half for up to 60 s.
- **Busting him** (hold E 0.3 s or a Ruler bonk) gives:
  - Candy: **Sugar Rush, tuition x2 for 60 s**.
  - Slime: **Slime Time, luck x2 for 90 s**.
- Ignored, he leaves with 20 % of that row's pad cash.

**Why it changes:**
- Sugar Rush as built is worth a lot. x2 for 60 s every ~205 s is about **+29 % income** for a player
  who busts every one.
- That was not in econ_sim. Row E in 0.3 measures it.

**[CHANGE]**
1. **The bust buff shrinks:** Sugar Rush becomes **x2 tuition for 20 s** (about +10 %, row F). Slime Time
   stays at luck x2, but for **60 s**, and luck only matters while you stand on the carpet.
2. **Busts also pay Confiscated Candy 🍬**, the currency below.
3. **The approach becomes a chase you can see:**
   - A smuggler now spawns at a **lurk spot** in the gap nearest your plot (section 8.1): a trash can,
     hedge, manhole, or the Sugar Shack door.
   - He sneaks 60-120 studs to your gate, so you can intercept him outside.
   - **Anyone can bust a smuggler on public ground** and gets **Good Samaritan x1.5 🍬**. Inside a school, only its owner can.
4. **Timing:** none before tutorial step 16. The first is the scripted Sweet Tooth Sal at 6:00. Goo Gary
   starts visiting at Middle School (tier 3).

### The NPCs

| Smuggler | Look (parts, kid rig) | Line | Effect on a seated kid |
|---|---|---|---|
| **Sweet Tooth Sal** (candy) | A tan trench coat three sizes too big (1.4 x 2.2 x 0.9). The halves are on hinges and swing open 70° to show 3 rows of 4 lollipops (stick cylinders + coloured balls) and gummy worms (chains of 4 small balls). Fedora, sunglasses, and a fake moustache on a stick that slips every 10 s. | "Psst. Sour worms. Your tongue will SCREAM." | Sugar High: 20 s bouncing in the seat at x1.5 (rainbow sparkles), then **Sugar Crash**: 20 s face-down on the desk with Zzz at x0. His row also earns half while he's there (EXISTS). |
| **Goo Gary** (slime) | Lab goggles. A backpack tank: a Glass cylinder 0.9 x 1.4 with a Neon-green inner cylinder and bubble particles. A 4-segment hose and green dripping gloves. Green drips fade behind him as he walks. | "It's not slime. It's ART." | **Slimed pad:** a green blob covers the pad. Cash keeps piling but can't be collected, and the Janitor skips it, until you hold E for 1.5 s to SCRUB (or 60 s pass). Nothing is lost. A thief carrying a slimed kid moves at x0.6 ("slime gets everywhere"). |
| **Golden Smuggler** (2 % of spawns) | Sal or Gary in a sparkling gold coat | "This is PREMIUM stuff, Principal." | The same effect. Drops 50 🍬 and a **Golden Wrapper** clue. |
| **The Sugar Baron** (boss; Candy Carnival and admin only) | See the cast. He rides the roof of a pink part-built Ice-Cream Van: a giant cone on top and a jingle. | "Sweets for my sweets!" | Parks in the Hub gap and throws candy for 3 min. Each volley sugar-crashes one kid somewhere. **Server co-op:** 30 Ruler bonks from anyone empty his bar. The van becomes a piñata and 200 🍬 pickups rain down, split among everyone who hit it. Unbeaten, every school gets one crashed kid and he drives off laughing. |

### Behaviour (server state machine, extends `PatrolService.sendDealer`)
1. **Lurk, 5-15 s:** pops out of the lurk spot (the lid clangs), crouched and looking around. A "psst" sound carries 40 studs.
2. **Sneak:**
   - Pose: Waist +0.35 rad, root -0.4, walk animation at x0.6, speed 8, head scanning ±40° every 1.5 s.
   - He heads for the target school's gate.
   - If a teacher is on the target floor, he re-targets 50 % of the time.
   - The **Vending Machines** build means 25 % fewer visits ("the competition").
3. **Freeze gag (P3, done server-side as the engineer asked):** if a player within 15 studs is *facing* him
   (their HumanoidRootPart LookVector · direction to him > 0.9), he freezes and pretends to read a
   newspaper part for up to 3 s.
4. **Locked gate:** he loiters outside tapping his foot for up to 30 s, then leaves. **[EXISTS]** the check.
5. **Deal (6 s):** leans to a seated kid ("Psst, kid"). A progress ring shows overhead, the coat opens,
   and a candy part passes between them over 3 s. Up to 3 per visit.
6. **Flee:**
   - When a player with line of sight comes within 20 studs: "!" and "SCRAM!"
   - He zigzags at 15 studs/s (players walk 16) and **trips over his own coat after 4 s** (a 1.5 s stumble).
     He is always catchable.
7. **Escape:** dives into a trash can after 20 s of fleeing (lid clang).

**Busting:**
- One Ruler bonk, or hold E 0.5 s within 6 studs.
- He spins 720° in 0.6 s with a line: "Aw, SUGAR!", "My GOOP!", "My MOM is gonna hear about this!"
- 8-12 wrapped-candy parts burst out (each a ball with two cone-like cylinder ends). They magnetise to
  the buster after 2 s; anyone can snatch them in those 2 s.
- Busting mid-deal cancels the effect. Within 10 s of a finished candy deal, the kid spits it out.
- **Hector** then marches the smuggler into the existing **Detention** building at the east end. He sits
  there for 60 s, and the room visibly fills up during Candy Carnival.

### Rewards and the Confiscated Candy currency

| Bust | 🍬 | Also |
|---|---|---|
| Sweet Tooth Sal | 8 | Sugar Rush x2 for 20 s (your school) |
| Goo Gary | 12 | Slime Time luck x2 for 60 s |
| Golden Smuggler | 50 | A Golden Wrapper |
| Public ground or someone else's school | x1.5 | |
| The Sugar Baron's van | 200 split + 50 to the finisher | |

The expected rate is about **60-100 🍬 per active hour**. 🍬 is never sold for Robux.

**The Confiscation Log** is a collection of 12. Each type appears as a small part-built trophy on your
Office shelf the first time you get it: Sour Worms, Jawbreaker, Rainbow Lollipop, Fizz Pop, Gummy Brain,
Mega Gumball, Chocolate Coin, Glow Slime, Galaxy Slime, Glitter Slime, Butter Slime, Golden Lollipop.
Completing it gives the "Confiscated!" nameplate.

**The Sugar Baron Clue Book:**
- 12 Golden Wrappers. At 2 % of spawns that is roughly one per 45 min of busting.
- Each unlocks a line: "The Sugar Baron is short." "...likes cereal." "...has a propeller?!"
- Completing it gives the title "Detective Principal".
- Players who reach Ivy League get the reveal anyway.

**Janitor Stan's Confiscation Closet** is a shed in the west-south gap. Rule: 🍬 buys only traps,
cosmetics and decor with **0 Reputation**, so it has no income effect. That was the lead judge's rule.

| Item | 🍬 | Effect |
|---|---|---|
| Jawbreaker Trap (3 uses) | 60 | The first thief to step on it spins for 1.5 s and drops what they carry |
| Slime Puddle Trap (3 uses) | 80 | Thieves at x0.5 speed for 4 s |
| Gummy Bear Guard (5 min) | 60 | A 3-stud wobbling gummy bear at your gate. Thieves who pass it are slowed x0.8 for 3 s. |
| Lollipop Lamp Posts | 150 | Decor |
| Gumball Machine | 300 | Decor. Dispenses a gumball emote. |
| Candy Cane Ruler | 400 | Skin |
| Slime Ruler | 600 | Skin: green drips on every hit |
| Cotton Candy Tree | 800 | Decor |
| "Confiscated!" title | 1,000 | Nameplate |
| Slime Fountain | 1,200 | Decor |
| Sugar Baron Trench Coat | 2,000 | Outfit |
| Ice-Cream Van | 3,000 | Decor that plays the jingle (about a 30-hour goal) |

Traps: at most 3 active per school.

---

## 7. Teachers

**[EXISTS]** `Config.Teachers`, `TeacherService` and `CampusService.hireTeacher`:
- 12 teachers, gated by tier, **one per floor**. Hiring a better one replaces the old one.
- The multiplier applies to that floor, and teachers are kept on review.
- The teacher stands at the floor's `TeacherSpot`, paces, turns, writes a lesson from `LESSONS` and
  points (the shoulder C0 tween runs on the server).
- There is a nameplate on the TeacherDesk.

This stays exactly as priced. econ_sim models it.

**Dropped:** GAME-PLAN section 7's 24-teacher Staff Room with rarities, restocks, stealing and levels.
All three judges said it conflicts with this system.

### Hiring flow [NEW visual layer]
1. **Where you hire:**
   - Shop > Teachers (EXISTS), or walk into the **Teachers' Lounge** in the centre-north gap.
   - The Lounge is a glass-front building with couches, a coffee machine and a newspaper rack.
   - The teachers you can hire at your tier sit there sipping coffee (client-side rigs). E on one opens the same card.
2. **HIRE, then pick a floor.** A "YOU'RE HIRED!" stamp appears.
3. **Six seconds later a yellow taxi pulls up at your gate.**
   - The taxi is part-built: a 12 x 5 x 6 body, a checker stripe and a roof sign.
   - The teacher steps out holding a cardboard box of supplies and waves at your students on the way in
     (the wave emote), walking via `PlotService.pathTo`.
   - They drop the box on the TeacherDesk (thud).
   - They write their name on the chalkboard letter by letter (MaxVisibleGraphemes).
   - They turn, say their catchphrase, and start the loop.
4. **The replaced teacher** waves, picks up a mug and walks out to the taxi.
5. **If you are more than 300 studs away,** the teacher appears in a puff at the desk instead.

### The cast
Looks are the existing `StudentProps.T.*` builds, read from the code.

| Teacher | Title | x / tier / price | Look | Catchphrase (new) | Signature action (new) | Strict? |
|---|---|---|---|---|---|---|
| Substitute Steve | Substitute | 1.1 / 1 / $600 | Rumpled beige cardigan, messy brown hair, tired eyes, a coffee he never puts down, SUB badge | "Uh... page 42?" | Falls asleep standing (neck droops for 2 s, then snaps awake) | |
| Student Teacher Tia | Student Teacher | 1.2 / 1 / $6K | Ponytail with a pink band, lanyard, clipboard of gold stars | "Gold stars for EVERYONE!" | Hands a gold Neon star to a random kid, who cheers | |
| Mr. Chalk | Math | 1.35 / 2 / $150K | Bald top with grey sides, round wire glasses, red bow tie, chalk dust on his vest, long pointer | "Show your work!" | Taps the board 3 times with the pointer (chalk puffs) | ✔ |
| Ms. Honeycutt | English | 1.5 / 3 / $12M | Bun with a pencil through it, red cat-eye glasses, pearls, a very large blue book | "Their. There. They're." | "SHHH!" (finger to lips). Rowdy particles on the floor vanish. | ✔ |
| Coach Rex | Gym Coach | 1.7 / 4 / $430M | Red tracksuit with white stripes, cap, whistle lanyard, clipboard | "Hustle hustle!" | Whistle blast, and the row does seated jumping jacks for 3 s | |
| Dr. Beaker | Science | 1.9 / 5 / $3.5B | Wild white hair, goggles up, lab coat, bubbling green beaker | "Goggles ON." | The beaker bubbles over with a small puff, and his hair stands up | |
| Madame Verse | Poetry | 2.1 / 6 / $20B | Beret, striped scarf, feather quill | "Feel the words, darlings." | Hand to forehead, spotlight flick | |
| Professor Tweed | Professor | 2.4 / 7 / $110B | White beard and side hair, bow tie, elbow patches, book stack | "In 1492... no, '93." | Spins a tiny globe (new prop), then points at it | |
| Dean Maximus | Dean | 2.7 / 8 / $250B | Black robe, mortarboard, gold chain of office | "Excellence. Always." | Walks the rows inspecting desks and nods | ✔ |
| Archmage Quill | Wizard Teacher | 3.0 / 10 / $1T | Tall starry hat, long beard, staff with a glowing orb | "Wand safety FIRST." | Levitates the chalk, which writes on its own | |
| Commander Nova | Space Instructor | 3.4 / 11 / $3T | Space suit, bubble helmet, jetpack, mission patch | "T-minus ten..." | Jetpack hop of 2 studs with a flame puff | |
| The Omniteacher | Teaches Everything | 4.0 / 12 / $9.3T | Cosmic robe, halo, four orbiting books | "You're ALL geniuses." | The orbiting books speed up, and one kid levitates 1 stud | ✔ |

### The classroom loop (extends `TeacherService.behave`, 40 s, desynced per teacher)
| Time | What happens |
|---|---|
| 0-10 s, Lecture | At the board with the **Write** recipe (section 11) and a chalk squeak. The next `LESSONS` line types out. |
| 10-14 s, Ask | Turns and plays the **point** emote. 2 random kids raise a hand for 1 s, and one Rare+ kid cheers ("answered!"). |
| 14-24 s, Patrol | Walks the aisle, stops at a random desk and leans 20° with a nod. That kid does a 0.3-stud "sit up straight" hop. |
| 24-32 s | The signature action from the table |
| 32-40 s, Coffee | At the desk, the mug arm lifts to the mouth |

**Reactions (interrupt the loop):**

| Event | Reaction |
|---|---|
| A kid on their floor is stolen | Hands on head, "HEY!", then points at the thief |
| A cheater is caught | Facepalm: shoulder -120°, elbow -130°, Neck -15° |
| A strict teacher catches one | Walks to the desk, taps it, points at the door |
| Review | Cheer |
| Recess | Waves out of the window |
| A kid is enrolled onto their floor | Cheer |
| The owner walks in after more than 60 s away | Wave |

**[CHANGE]** Move the shoulder C0 tweens from the server to the client Puppet module (section 11). Every
server-side C0 change replicates. The server keeps only the position and a `TeacherAction` attribute.

---

## 8. School Builder

### 8.1 The space between schools [CHANGE, `tools/build_map.lua`]
**Today** (read from build_map.lua):
- Lots are 120 x 150 at X = -225, -75, 75, 225 and Z = ±103.
- That leaves **30-stud gaps**. Buildings (80 wide) sit 70 studs apart.
- The carpet runs from -318 to 346 and the bus is at x = -345.

**New:**
- `plotXs = { -285, -95, 95, 285 }`. Lot edges move to ±35, ±155, ±225 and ±345.
- **Gaps of 70 studs**, and buildings 110 studs apart. Z is unchanged: every lot keeps its 59-stud front
  yard inside the lot.

Also:
- Move the edge tree columns from x = ±330 to ±390, and the gap trees from x = ±150 to ±190.
- Widen the ground to 900 and the sidewalk to 760.
- **[CHANGE] HallService.luck:** the hallway strip test `math.abs(X) < 250` becomes `< 335`, so standing
  at the outer schools' stretch of carpet still counts.
- The outer gates end up 285 studs from the Hub: 18 s at walk speed 16, against 14 s today.

**Every gap gets a landmark with a job** (each gap is 70 x 150):

| Gap | Landmark | What it's for |
|---|---|---|
| Centre-south (the Hub, spawn side) | Existing spawn and flagpole. **Mr. Wobblesworth's Fountain** at z -110. **Loretta's Lunch Cart** at z -80. **Riley's news crate** with the Gazette board and the Most Wanted poster. | Principal's Requests, daily Lunch Box, news |
| Centre-north | **Teachers' Lounge** (a glass-front 40 x 30 building) and the **Bell Schedule** split-flap board facing the street | Walk-in hiring, timers |
| West-south | **Janitor Stan's Confiscation Closet** (a 20 x 16 shed) | The 🍬 shop |
| West-north | **Recess Commons**: swings, slide and jungle gym, where the ambient Recess kids play | Recess, the Field Day start line |
| East-south | **District Office** (a 40 x 40 tower, 60 tall). The Hall of Fame leaderboards are on its wall, and a doorway "elevator" leads up to the Board Room. | Leaderboards, the Board |
| East-north | The **boarded-up Sugar Shack** (flickering lights, the Sugar Baron on its roof) and **Vex's billboard**: "COMING SOON: VEX HOMEWORK FACTORY" | Smuggler spawns, the story |

**Also placed in the gaps:**
- Lurk spots: trash cans every 50 studs along both sidewalks, 2 hedges and 1 manhole per gap.
- Tutorial tent spots: one per plot, at the street end of the gap beside it, about 50 studs from the gate.

### 8.2 The build moment [NEW, `SchoolBuilder.setItems` + client]
1. Scaffold: thin grey Metal poles around the item's footprint, over 0.5 s.
2. 2 s of hammer taps (new "hammer on wood").
3. The item's parts drop from +6 studs with Back easing, staggered 0.03 s apart.
4. A dust puff (a 20-particle grey burst), then a "+N REPUTATION" float and the existing "X BUILT!" Announce.

**Blueprint preview:** hover an item in the Builder tab and ghost parts (blue ForceField) show where it
goes on your plot, client-side only.

### 8.3 Items
There are 24 items: 16 exist, 8 are new, and 2 existing items change.

**[EXISTS]** `Config.Builds` and `CampusService.buyBuild`:
- Each item adds Reputation. Tuition is multiplied by (1 + rep/100). Items are kept on review.
- `replaces` hides the old item's parts, but its Rep still counts.

Tier is the `Config.Tiers` index.

| # | Item (id) | Status | Tier | Price | Rep | Looks and does |
|---|---|---|---|---|---|---|
| **Windows** | | | | | | |
| 1 | Curtains & Flower Pots (`Curtains`) | NEW | 1 Kindergarten | $800 (free in the tutorial) | 1 | Boards off. Two cloth curtain blocks per window in your school colour, tied back. A terracotta pot with a red flower on every sill. |
| 2 | Window Boxes (`WindowBoxes`) | EXISTS | 2 Elementary | $150K | 2 | Shutters and flower boxes |
| 3 | Arched Windows & Shutters (`ArchedWindows`) | NEW | 5 Prep | $3B | 2 | Replaces WindowBoxes. Wedge arches over the front windows and painted shutters. |
| 4 | Stained-Glass Windows (`StainedGlass`) | NEW | 8 University | $300B | 2 | Replaces ArchedWindows. 4-colour Glass panes per window, with a SurfaceLight glow at night. |
| **Walls outside** | | | | | | |
| 5 | Picket Fence (`PicketFence`) | EXISTS | 1 | $5K | 2 | |
| 6 | Low Brick Wall (`LowBrickWall`) | NEW | 3 Middle | $3M | 2 | Replaces Picket. A 3-stud brick wall with white caps along the lot curb. Lanterns on the gate posts. |
| 7 | Brick Wall & Lamp Pillars (`BrickWall`) | EXISTS, **[CHANGE]** | 5 | $2.1B | 3 | Now `replaces = "LowBrickWall"` |
| 8 | Iron Gates (`IronFence`) | EXISTS | 8 | $170B | 4 | |
| **Entrance, signs, roof** | | | | | | |
| 9 | Striped Awning & Welcome Mat (`Awning`) | NEW | 1 | $2.5K | 1 | A striped fabric canopy over the door and a mat with your mascot's initial |
| 10 | Marquee Letter Board (`Marquee`) | NEW | 2 | $120K | 1 | A letter board by the walk. It shows your chalkboard message and live $/s, plus automatic brags ("CONGRATS TO OUR NEW PRODIGY!"). |
| 11 | School Banners (`Banners`) | EXISTS | 6 | $13B | 3 | |
| 12 | Solar Panels (`SolarPanels`) | EXISTS | 9 | $370B | 5 | |
| 13 | Bell Tower (`BellTower`) | EXISTS | 10 | $1.4T | 8 | Rings the Founder's Chime at every Recess |
| **Yard** | | | | | | |
| 14 | Flower Beds (`FlowerBeds`) | EXISTS | 1 | $1.5K | 2 | |
| 15 | Path Lights (`PathLights`) | EXISTS | 2 | $50K | 2 | |
| 16 | Playground (`Playground`) | EXISTS | 2 | $350K | 4 | Up to 4 of your kids play here during Recess (section 11) |
| 17 | Basketball Court (`Court`) | EXISTS | 3 | $9M | 5 | |
| 18 | School Garden (`Garden`) | EXISTS | 4 | $160M | 3 | |
| 19 | Bleachers (`Bleachers`) | EXISTS | 4 | $160M | 3 | Used in the Picture Day class photo |
| 20 | Fountain (`Fountain`) | EXISTS | 5 | $4.2B | 6 | |
| 21 | Founder's Statue (`Statue`) | EXISTS | 7 | $120B | 7 | Its eyes flick toward the camera at dusk. It comes alive in the finale. |
| **Inside** | | | | | | |
| 22 | Mascot Lockers (`MascotLockers`) | NEW | 3 | $4M | 1 | Repaints the existing lobby lockers in school colours with your mascot's initial. Random doors slam as kids pass, and one kid is stuck inside, banging. |
| 23 | Cafeteria Corner (`Cafeteria`) | NEW | 3 | $7M | 2 | 2 lunch tables and a counter in the lobby. Loretta's cart stops here at Lunch Rush, and kids eat here at Recess. |
| 24 | Vending Machines (`VendingMachines`) | EXISTS | 3 | $5.6M | 3 | Also: 25 % fewer smuggler visits |

```lua
-- add to Config.Builds (one per line; econ_sim parses them)
{ id = "Curtains", name = "Curtains & Flower Pots", icon = "\u{1FA9F}", rep = 1, tier = 1, price = 800 },
{ id = "Awning", name = "Striped Awning & Welcome Mat", icon = "\u{26F1}\u{FE0F}", rep = 1, tier = 1, price = 2.5e3 },
{ id = "Marquee", name = "Marquee Letter Board", icon = "\u{1FAA7}", rep = 1, tier = 2, price = 120e3 },
{ id = "LowBrickWall", name = "Low Brick Wall", icon = "\u{1F9F1}", rep = 2, tier = 3, price = 3e6, replaces = "PicketFence" },
{ id = "MascotLockers", name = "Mascot Lockers", icon = "\u{1F510}", rep = 1, tier = 3, price = 4e6 },
{ id = "Cafeteria", name = "Cafeteria Corner", icon = "\u{1F37D}\u{FE0F}", rep = 2, tier = 3, price = 7e6 },
{ id = "ArchedWindows", name = "Arched Windows & Shutters", icon = "\u{1F3DB}\u{FE0F}", rep = 2, tier = 5, price = 3e9, replaces = "WindowBoxes" },
{ id = "StainedGlass", name = "Stained-Glass Windows", icon = "\u{1F308}", rep = 2, tier = 8, price = 300e9, replaces = "ArchedWindows" },
-- and change BrickWall to: replaces = "LowBrickWall"
```

**Reputation budget:**
- Rep at tier 10 goes from 62 to 74, so tuition from these items goes from x1.62 to x1.74.
- That is measured in row D of 0.3.

**Free customisation stays as it is** (the Name School panel): name, mascot flag and colours. The tier
look (`Config.TierLooks`, 12 buildings) is still the biggest visual upgrade. These items sit on top of it.

---

## 9. Events

### Structure
- **One featured event per week.** It starts with the weekly update on **Saturday 15:00 UTC** and runs
  until the next Saturday 14:00.
- **Pinned dates:**
  - Spooky Season: Oct 17 to Nov 1.
  - Snow Day: Dec 15 to Jan 5.
  - Prom Night: Feb 10 to 20.
  - Space Camp: July.
  - Graduation: the last week of each 6-week Report Card season.
  - Everything else rotates.
- **Surges:**
  - Every 30 min at **:20 and :50 UTC for 5 minutes**.
  - The map dressing peaks, the event mechanic runs, and currency drops x3.
  - The event grade rolls on the carpet at weight 4 (about 4 % of kids). Outside surges it is weight 0.5.
  - The existing hook is `HallService.eventGrades`.
- **Event beam [NEW] [SIM]:**
  - During each surge, each present owner's school has a **20 % chance** that one seated kid with a Normal
    grade is struck by a coloured beam and gains the event grade. It never replaces a better grade.
  - Cap: 5 beams per player per event week.
  - All three judges keep this (Grow-a-Garden weather). It is **not simulated**. Add a sim hook before
    raising the chance.
- **Currency:**
  - About 150-250 an active hour, from surges, event quests and 1 per minute of play.
  - Never sold for Robux. Leftovers turn into Report Card XP when the event ends.
- **Alumni rule (P1):**
  - Event and Limited Alumni go to your **Alumni Lounge**, a trophy bench in the side yard.
  - They sit at a desk and pay tuition **only from State University (tier 8) onward**.
  - Otherwise a 250M/s Alumni would break every early tier.
- **Always-on moments:**
  - Recess (EXISTS), every 15 min.
  - Pop Quiz every 10 min at :03, :13 and so on: a 10 s trivia pop-up, and the right answer pays 60 s of tuition.
  - **Lunch Rush** at :33 each hour for 3 min: a food fight in the Hub, where hits earn Lunch Money for Loretta's cart cosmetics.
  - Vex's limo drive-by every 15 min.

### The 12 events

| # | Event (story beat) | Map dressing | Surge mechanic | Event grade | Currency | Shop highlights |
|---|---|---|---|---|---|---|
| 1 | **Snow Day**. Vex wheels out her Anti-Snow Heater 3000. | Snow slabs on roofs and lamps, snowmen at the arch, falling-snow particles, icy blue carpet trim | **Snowball War.** Snowball piles give 5 each. Hitting a carrier makes them drop their kid. Hits on the Heater (HP scales with players) fill the Blizzard bar; at 100 %, luck x3 for 60 s. | Snow Day x3 (EXISTS) | ❄ Snowflakes | Graduate Grandpa (Alumni, EXISTS) 5,000 · Igloo Office skin 1,200 · Snowman 300 · grade token 2,500 |
| 2 | **Science Fair**. Dr. Beaker's volcano is "totally safe". | Tri-fold boards ("Does Slime Dream?"), a 20-stud volcano in the Hub with Neon lava | **Eruption.** Lava blobs rain down and harden into crystals, 8 per player. | Radioactive x4 (EXISTS) | 🧪 Beakers | Lava Lamp 400 · Beaker Ruler 1,000 · token 3,000 |
| 3 | **Picture Day**. Riley runs it and Vex photobombs. | Blue laser backdrops, a tripod camera on a Hub stage, a flash every 10 s | **Say Cheese!** Players on stage who hit Pose (wave, cheer or point) at the flash get Film. **Class Photo:** your kids line up on your Bleachers and it's saved as a Yearbook card. | Picture Perfect x2 (EXISTS) | 🎞 Film | Photo Booth 800 · gold frames 500 · token 1,500 |
| 4 | **Field Day**. Coach Rex against VexCorp Athletics. | Bunting, cones, a finish arch over the carpet, lanes painted through the gaps | **Relay:** a 600-stud checkpoint loop through the six gaps. The top 3 and every finisher score. Then **tug-of-war**, north side against south, by mashing E. | **Gold Medal x3** (NEW) | 🏅 Medals | Sprint trail 1,500 · Trophy decor 900 · token 2,500 |
| 5 | **Spooky Season**. The Ghost of Room 13 throws a party. | Fog, jack-o'-lanterns with Neon faces, flapping part-built bats, Detention lit green | **Trick-or-TP.** Knock on another school's gate (E). The owner has 5 s to hit Treat (5 Candy Corn). If not, their school is draped in toilet paper for 3 min (cosmetic only). Smugglers wear costumes and drop double 🍬. | Spooky x3.5 (EXISTS) | 🎃 Candy Corn | Pumpkins 300 · Haunted Office skin 2,500 · Broom Ruler 1,500 · token 3,000 |
| 6 | **Prom Night**. Kevin DJs, badly. | A disco ball over the carpet, string lights, a balloon arch, light-up dance tiles in the Hub | **Dance-Off.** The DJ calls wave, point, cheer or dance, and you hit it within 2 s from the emote wheel. **Best-Dressed School** vote. | **Prom Royalty x4** (NEW) | 🎟 Tickets | DJ Booth 1,800 · Disco Ball 1,200 · token 3,000 |
| 7 | **Space Camp**. The Rocket Science Kid launches the Board. | Planets hanging over the map, a night sky, a rocket gantry in the Hub gap | **Meteor Shower:** 40 meteors, each crater holding a Moon Rock. Plus low-gravity Recess (`workspace.Gravity` 60 for 60 s). | Cosmic x7 (EXISTS) | 🌙 Moon Rocks | Mini Rocket 1,500 · Cosmic token 5,000 |
| 8 | **Throwback Week** (the anniversary). The Time-Traveling Transfer breaks his pocket clock. | ColorCorrection flips the era every 60 s (sepia, then neon), a jukebox, arcade cabinets | **Time Rift:** 3 portals on the carpet. Kids who walk through can roll Retro, and players who step through get 30. | **Retro x3** (NEW) | 📼 Cassettes | Class of '99 (Alumni, EXISTS) 6,000 · The Founder (Alumni, EXISTS) 12,000 · Jukebox 1,000 |
| 9 | **Wizard Week**. Wobblesworth confesses he dropped out of wizard school. | Bobbing floating candles, owls on the lamps, glowing runes on the carpet | **Potion Class.** Collect a mushroom, a crystal and a feather in the gaps and brew at the Hub cauldron. Free potions, with odds shown: Speed 40 %, Luck +50 % for 5 min 30 %, Tiny 20 %, Giant 10 %. | **Enchanted x5** (NEW) | 📜 Scrolls | Head Prefect (Alumni, EXISTS) 7,000 · Wand Ruler 1,500 |
| 10 | **Candy Carnival**. The Sugar Baron's "totally legal" carnival; Stan is suspicious. | Striped tents in the gaps, cotton-candy trees, lollipop lamps, a Ferris wheel behind the District Office | **Sugar Rush Hour:** 12 smugglers at once, and the **Ice-Cream Van raid** every surge (section 6) | **Sugar Rush x3** (NEW) | 🍬 x2 + Golden Wrappers | Mini Ferris Wheel 2,500 🍬 · Cotton Candy Machine 800 🍬 |
| 11 | **Hostile Takeover**. Vex's final offer. | "SOON TO BE VEX PROPERTY" banners, an armoured Tuition Truck in the Hub | Each surge the truck bursts and **20 Golden Report Cards** spill out. Carry them home like kids (x0.75 speed), and anyone can bonk you to make you drop them. **Crumpet's raiders** try the 3 lowest-income schools, and defenders earn a coin per bonk. | **Old Money x5** (NEW) | 🪙 Crest Coins | Detention Slip Ruler 800 · Vex statue with a pigeon on it 5,000 |
| 12 | **Graduation** (the season finale). The Board holds commencement. | Folding chairs on the Hub lawn, a stage and podium, a graduation arch over the carpet | **Commencement.** During a surge, graduate a seated kid: it crosses the stage, Grimm reads its name, and it leaves your school for Diplomas. Common 1, Uncommon 3, Rare 8, Epic 20, Legendary 50, Mythic 150, Prodigy 500, Secret 2,000, all x grade mult. **The sink for duplicates.** Caps are tossed at the end. | **Graduated x6** (NEW) | 🎓 Diplomas | Principal (as a kid) (Alumni, EXISTS) 10,000 · Graduation Arch 1,500 · Cap Toss emote 1,000 |

```lua
-- new event grades (weight 0; HallService.eventGrades turns them on)
{ id = "Gold Medal", mult = 3, weight = 0, event = "FieldDay", color = rgb(255, 205, 60) },
{ id = "Prom Royalty", mult = 4, weight = 0, event = "PromNight", color = rgb(255, 120, 220) },
{ id = "Retro", mult = 3, weight = 0, event = "Throwback", color = rgb(230, 170, 90) },
{ id = "Enchanted", mult = 5, weight = 0, event = "WizardWeek", color = rgb(170, 110, 255) },
{ id = "Sugar Rush", mult = 3, weight = 0, event = "CandyCarnival", color = rgb(255, 110, 190) },
{ id = "Old Money", mult = 5, weight = 0, event = "HostileTakeover", color = rgb(40, 120, 70) },
{ id = "Graduated", mult = 6, weight = 0, event = "Graduation", color = rgb(30, 30, 40) },
```
That makes 18 grades. The Yearbook becomes 70 students x 18 grades = 1,260 entries, plus Alumni.

**Event music:**
- Existing context tracks: `snow` (Jingle Bells Kids) and `halloween` (Horror Strings).
- New ones by Creator Store APM search:

| Event | Search |
|---|---|
| Science Fair | "mad scientist comedy" |
| Field Day | "marching band sport" |
| Prom Night | "disco funk" |
| Space Camp | "space synth adventure" |
| Throwback Week | "90s arcade" |
| Wizard Week | "whimsical magic" |
| Candy Carnival | "carnival organ" |
| Hostile Takeover | "villain march comedy" |
| Graduation | "pomp and ceremony" |

- Load each in Studio and check its TimeLength before adding it to `Sounds.lua` (the rule in its header).

---

## 10. Admin panel

### Access and security
- `Config.Admins = { [<owner UserId>] = "Owner" }`, plus an optional group rank of 254 or higher.
- **The panel ScreenGui lives in ServerStorage** and is cloned into PlayerGui only for admins. Other
  players never receive its code.
- **One `AdminRequest` RemoteFunction:**
  - The server re-checks `Admin.is(player)` on every call.
  - It is rate-limited to 10 calls a second.
  - Arguments are validated like any other remote.
- **Opening it:** press F8, or type `;` commands. `TextChatCommand`s are registered only for admins.
- The Studio-only `DebugBridge` **[EXISTS]** stays separate.
- **Audit:** every command goes to an `AdminLog` DataStore (who, what, target, arguments, time) and is shown in the Logs tab.
- **Safety:**
  - Admin-granted cash and kids set `p.flags.adminGranted`, and leaderboards skip those profiles.
  - Destructive commands (reset, restore, ban) require typing "RESET <name>".
  - Broadcast text still goes through TextService filtering.
- **UI:** the existing `UI.lua` kit. Navy panel, tabs across the top.

### Tabs and commands

| Tab | Commands |
|---|---|
| Players | `;inspect <p>` (read-only profile) · `;cash <p> <amount>` · `;student <p> <id> [grade]` · `;bench <p> <id> [grade]` (support refunds onto the Waiting Bench) · `;tier <p> <n>` · `;letter <p> <rarity> fill` · `;tp` / `;bring` / `;freeze` / `;view <p>` · `;restore <p> <versionTime>` (DataStore version rollback) · `;reset <p>` |
| Spawn and buses | `;spawn <id> [grade] [count]` · `;bus Late\|HonorRoll\|FieldTrip\|Pick\|Lucky\|Prodigy\|Welcome` · `;clearcarpet` · `;smuggler Sal\|Gary\|Golden\|Van` · `;cheater <p>` (testing) |
| Events | `;event start <id> [minutes]` · `;event stop` · `;surge` · `;recess` · `;quiz` · `;lunchrush` |
| World | `;time <0-24>` · `;weather snow\|rain\|clear` · `;gravity <n>` · `;music <key>` · `;freezetimers` |
| Economy (temporary; expires and is never saved) | `;luck <x> <min>` (max x10 for 30 min) · `;tuition <x> <min>` · `;spawnrate <s>` |
| Broadcast | `;announce <text>` · `;global <command>` (MessagingService, runs in every server) · `;shutdown <min> <msg>` (countdown "School's out! Back in 60 s", then a soft shutdown that teleports everyone to a fresh server) |
| Moderation | `;kick <p> <reason>` · `;ban <p> <duration> <reason>` (`Players:BanAsync`) · `;unban <userId>` |
| Self | `;fly` · `;noclip` · `;invis` · `;size <n>` |
| Logs | The audit trail, plus the last 50 steals, purchases and reviews |

### "Admin abuse" events
**When:** weekly, **Saturday 17:00 UTC**, two hours after the update, for 60 minutes.

**Build-up:**
- A 24-hour countdown on the split-flap board and the HUD.
- The admin appears in **every** server as a 40-stud translucent hologram over the Hub.
  - Built with `Players:CreateHumanoidModelFromUserId` and `Model:ScaleTo(8)`, in ForceField material.

**Rules:**
- Every event is announced 30 s ahead, and the banner names the admin.
- **Nothing ever takes anyone's students or cash.**

| Event | Length | Effect |
|---|---|---|
| **Luck Tsunami** | 10 min | Server luck x10, and x25 in the last minute. The sky turns rainbow. |
| **Secret Shower** | 60 s | Every bus kid is Mythic+ with a 5 % Secret chance, at normal price. That is about 1-2 Secrets per server a week. |
| **Cash Rain** | 60 s | Part-built dollar bills fall. Each is worth 30 s of *the collector's* tuition, capped at 10 min per player. |
| **Giant Principal** | 3 min | The admin becomes 40 studs tall. Stomps knock players back cartoon-style and throw cash confetti (same cap). |
| **Everybody Dance** | 60 s | Every NPC and kid dances in sync under a disco ball. Tuition x2. |
| **Grade Storm** [SIM] | 2 min | Rainbow clouds. Every seated kid rolls a grade and keeps the better one. |
| **Gate Glitch Heist Hour** | 90 s | A "POWER OUTAGE": all laser gates are off, stealing takes 0.75 s, and everyone gets a free Golden Ruler. **Heist Amnesty:** everything stolen walks home when it ends, and the thief keeps 2 min of that kid's tuition as a prize. |
| **Mega Pop Quiz** | 5 min | The admin types questions. The first 3 correct answers win a Prodigy on their Waiting Bench (flagged `adminGranted`). Everyone else gets a Lunch Box. |
| **Zero-G Recess** | 2 min | `workspace.Gravity` 30 and luck x3. Kids float out of their seats and bob. |
| **Smuggler Invasion** | 3 min | 12 smugglers, plus the Sugar Baron on the roofs. 🍬 x3. |
| **Kevin's Waterslide** | 10 min | A giant part-built waterslide spirals down the District Office. Each ride pays event currency. |
| **Vex Attack** | 8 min | The Homework Machine boss in every server at once, with one global HP bar summed over MessagingService. Rewards are currency and decor. |

---

## 11. NPC life, animation and audio

### 11.1 How animation runs
**[EXISTS]**
- Students are **anchored rigs** that `Walkers` moves on the server, one Heartbeat for all of them.
- Base tracks are played by `Factory.play`: walk, idle, sit (`Factory.Anims`). GAME-PLAN Status records
  the walk animation as seen in a play test.

**[NEW] Client `Puppet` module** (StarterPlayerScripts):
- It reads attributes the server sets on models, for example `Emote = "Cheer"`, `Gag = "Trip"`,
  `CheatStage = 2`, `TeacherAction = "Point"`.
- It plays default emote tracks locally and applies procedural offsets to **Motor6D C0** in one
  RenderStepped loop.
- **Level of detail:**
  - Full procedural within 60 studs.
  - Emotes only from 60 to 150 studs.
  - Nothing beyond 150.
  - At most 60 student rigs and 30 ambient rigs animated at once.
- **Split between server and client:**
  - Gameplay NPCs are server models: students, teachers, smugglers, Crumpet, buses and taxis.
  - Ambient NPCs are spawned per client, so they cost no replication: Recess kids, parents, pigeons,
    Lounge teachers, and the crowd in cutscenes.

### 11.2 Default R15 animations
walk, idle and sit are the ids in `Factory.Anims`. The others are from memory of the default R15 Animate
script. **Copy them from a Play-mode character's Animate script before shipping.**

| Use | Id |
|---|---|
| walk | 507777826 |
| run | 507767714 |
| idle | 507766388 (alt 507766666) |
| jump | 507765000 |
| fall | 507767968 |
| climb | 507765644 |
| sit | 2506281703 |
| wave | 507770239 |
| point | 507770453 |
| cheer | 507770677 |
| laugh | 507770818 |
| dance / dance2 / dance3 | 507771019 / 507776043 / 507777268 |

### 11.3 Procedural recipes (offsets on C0, in radians unless stated)

| Name | Recipe | Used by |
|---|---|---|
| Write | RightShoulder pitch -1.3 + 0.12·sin(12t), roll 0.1·sin(6t) | Teachers at the board, seated kids |
| Shifty | Neck yaw 0.5·sin(1.8t) with 0.3 s holds; pupil parts ±0.06 X | Cheaters (Stage 1), smugglers |
| Peek | Waist roll 0.44, Neck yaw 0.52 | Neighbour Peek cheat |
| Hand raise | Shoulder -2.95 held 1-2 s, ±0.17 wiggle at 3 Hz | Kids answering |
| Settle | Root -0.1 stud bounce over 0.1 s | Sitting down |
| Enroll hop | Root +2 studs over 0.25 s (Back easing) + cheer | Enrolled kid |
| Trip | Root pitch +0.52 over 0.15 s, hold 0.3, recover 0.25 + dust puff | Untied Tyler, fleeing smugglers |
| Hiccup | Root +0.35 stud in 0.08 s, back in 0.15; Neck -0.14 | Hiccup Hank |
| Sugar bounce | Root +\|sin(9t)\|·0.5 stud, arms up 0.8 | Sugar High |
| Slump | Waist -0.6, Neck -0.4, Zzz particle | Sugar Crash, napping |
| Snore bob | Neck 0.1·sin(1.2t) | Sleepy Sam, the sleeping Board member |
| Flail | Shoulders ±1.1 at 10 Hz in opposite phase, hips ±0.6 | Carried kids ("PUT ME DOWN!") |
| Dizzy | Stars orbit the head for 1.5 s, Root yaw wobble ±0.1 | Dropped kids, bonked NPCs |
| Walk of shame | Neck -0.35, walk AdjustSpeed(0.55) | Caught cheaters |
| Sneak | Waist +0.35, Root -0.4 stud, arms forward 0.5, walk x0.6 | Smugglers, Crumpet |
| Seller spin | Root yaw +4π over 0.6 s | Busted smugglers |
| Laser bonk | Root pitch -2π over 0.5 s, pushed back 4 studs | Crumpet at the gate |
| Mop sweep | Shoulders yaw 0.6·sin(3t), torso 0.2·sin(3t) | Stan |
| Ladle | Right shoulder -0.4 to -1.6 arc over 0.8 s, every 3 s | Loretta |
| Whistle | Right shoulder -2.3 (hand to mouth), head scale 1.0 to 1.08 over 0.15 s | Hector, Coach Rex |
| Salute | Shoulder -2.6, elbow -1.75, held 1 s | Hector, the Hall Monitor in beat 2 |
| Facepalm | Shoulder -2.1, elbow -2.3, Neck -0.26 | Teachers |
| Gavel | Right shoulder 0 to -1.9 (0.25 s) to -0.7 impact (0.08 s) + 0.2 s camera shake | Grimm |
| Faint | Root pitch 0 to -1.4 over 0.4 s | The Board, at prices |
| Robot | Arm angles snap between {0, ±π/2} every 0.25 s | Rudy, Recess dance |
| Invisible box | Shoulders -1.5, elbows -0.3, 0.04 press at 3 Hz | Mime Mimi |
| Jumping jacks | Shoulders ±2.6 and hips ±0.35 at 1.5 Hz with a Root bob | Coach Rex's row |
| Tantrum | Hips alternating ±0.5 at 4 Hz | Smuggler on a bust |
| Hinge | A part's weld C0 rotates to a target angle | Coat flaps, locker doors, the bus door, the tent flap |
| Pendulum | ±angle·sin(ωt) on a weld | Swings, flags, the bell |
| Wing flap | ±1.05 at 10 Hz | Pigeons |

### 11.4 Students by state

| State | Animation |
|---|---|
| Stepping off the bus | Hops down 2 steps (Enroll hop at half height, twice). 30 % of kids wave at Otis. |
| On the carpet | Walk, with personality by rarity (see below). Every 8-15 s: look around, a wave at any player within 10 studs ("pick me!"), or their prop gag. |
| A Secret on the carpet | Every carpet kid within 60 studs turns and **points** at it |
| Enrolled | Enroll hop, cheer, then jogs home at 16 studs/s |
| Seated | Sit plus a personality loop on a random 4-10 s timer: Write, Hand raise, yawn, head on desk, look out of the window, whisper to a neighbour (laugh), stretch, their prop gag |
| Cheating | Section 5 tells |
| Caught | Gasp, then Walk of shame, bench, halo |
| Sugar High, Crash, Slimed | Sugar bounce, Slump, green drip particle |
| Carried | Flail |
| Dropped | Dizzy, then walks home |
| Sold | Wave emote, then walks to the bus |
| On the Waiting Bench | Hips swing ±0.35 at 1 Hz (legs swinging). Wave when the owner is within 15 studs. |
| Recess | Up to 4 of your kids stand up and play in your yard or on your Playground build for 60 s: tag (run), swings (Pendulum ±0.6 at 0.6 Hz), slide, or eating at the Cafeteria Corner. They keep paying and can't be stolen while they play. |
| Review | Everyone stands, throws caps (a cap part tweened up) and cheers |

**Walks by rarity:**

| Rarity | Walk |
|---|---|
| Common | Shuffle with a small bob |
| Rare | Normal walk |
| Epic | Strut (shoulder sway ±0.14) |
| Legendary | 0.85x speed with a Root bob and a trail |
| Mythic | Ghost floats (±0.3 bob). The others have a cape-like torso sway. |
| Prodigy | Short glide pauses with a halo |
| Secret | Glitch-teleports 0.5 studs every 2 s |

### 11.5 Ambient and story NPCs

| NPC | Where | Loop | Animations | Reacts to |
|---|---|---|---|---|
| Otis | Driver's seat of every bus | Bobs to music, sips from his thermos, honks at the stop | Neck sway ±0.1 at 0.5 Hz, sip (elbow -2.1), **wave** | Guaranteed buses: a horn and a line |
| Mr. Wobblesworth | Hub fountain; follows new players | Leans on his pencil, rocks on his heels, tells a story when you stand near | Waist lean 0.17, **wave**, **point**, talking nod ±0.09 at 3 Hz | New joiners (walks over), Secret pulls ("Oh my!") |
| Loretta | Lunch Cart in the Hub | Ladles, rings a triangle at Recess, hands out the Lunch Box | Ladle, **wave**, **laugh** | Lunch Rush (bangs the pot) |
| Stan | Carpet and his Closet | Mops at speed 4, leans on the mop, laughs when someone slips on slime | Mop sweep, **laugh** | Slime puddles, the "While you were out" card |
| Hector | Patrols the carpet | Marches, whistles at carriers, salutes schools with 5+ Builder items | Walk at 0.8x (stiff), Whistle, **point**, Salute | Thefts (whistle and outline), busts (marches the smuggler to Detention) |
| Riley | Hub crate; runs to big moments | Throws papers, shouts headlines, three camera flashes | **run**, **point**, PointLight flash | Secret or Prodigy pulls, big steals, reviews, Kingpin busts |
| Granny Stopsign | Bus stop | Raises her STOP sign as each bus parks, waves the kids on | Hinge arm -2.8, **wave** | Every bus; the "PICK" paddle |
| Crumpet | Tutorial tents; Hostile Takeover | Dusts things, walks too properly | Sneak (upright version), Laser bonk, Dizzy | Tutorial script |
| Vex | Limo every 15 min | Leans out of the window with a line for the poorest school | **point**, Waist lean | Reviews (objects) |
| The Sugar Baron | Sugar Shack roof, rooftops | Appears, rubs his hands, vanishes in powdered sugar | Elbows -1.75 with a ±0.17 rub at 4 Hz | Golden Smugglers, Candy Carnival |
| Teachers | Classrooms | Section 7 loop | Write, **point**, **cheer**, **wave**, Facepalm | Section 7 |
| Recess kids (6, client) | Recess Commons and yards | Tag, jump rope (two holders and a jumper; the rope is a Pendulum), hopscotch | **run**, jump, **laugh**, **point** | Recess floods the Commons |
| Parents (client) | Bus stop | "Bye sweetie!" | **wave** | Bus arrivals |
| Pigeons (client) | Roofs and lamps | Peck, then scatter when a player runs within 10 studs | Head bob, Wing flap | Players |
| The Board (5) | Board Room | Gavel, faint, snore, point, propeller | Gavel, Faint, Snore bob, **point**, **cheer** | Every cutscene |

**Budget:**
- Story NPCs: 9 on the server.
- Smugglers: at most 1 per player (8).
- Teachers: at most 3 per plot (24).
- Client ambient: 30 or fewer.

### 11.6 Audio
**[EXISTS]** `Sounds.lua` and `Audio.client.lua`:
- **Relaxed Scene** (1848354536) opens every session and comes back every other track.
- A shuffled playlist.
- Context tracks: board, stealing, alarm, recess, heroes, snow, halloween.
- About 30 named effects, every one checked in Studio.

**New effects** (Pro Sound Effects via Creator Store search; the ids are not checked yet). Load each one
and check its TimeLength before adding it to `Sounds.lua`:

| Effect | Search term |
|---|---|
| Whistle | "referee whistle" |
| Sad trombone | "sad trombone" |
| Dun dun DUNNN | "dramatic sting dun dun" |
| Bonk | "cartoon bonk" |
| Oof | "cartoon oof" |
| Slide whistle | "slide whistle down" |
| Plank pop | "wood plank pop" |
| Hammer | "hammer on wood" |
| Typewriter blip | "ui blip" |
| Drumroll | "drumroll short" |
| Dog bark | "small dog bark" |
| Frog | "frog croak" |
| Recorder | "recorder squeak" |
| Splash | "water splash small" |
| Servo | "servo short" |
| Wrapper | "candy wrapper crinkle" |
| Trash lid | "trash can lid" |
| Limo horn | "car horn luxury" |
| Clock tick | "clock ticking" |
| Chalk | "chalk on chalkboard" |
| Split-flap | "split flap clack" |
| Snoring | "snoring cartoon" |
| Jingle | "ice cream truck jingle" |

**New music (APM search):**
- "suspense ticking clock" for the Principal's Pick.
- "sneaky pizzicato" for smugglers and Crumpet.
- The event themes in section 9.

---

## 12. Retention loop to 100+ hours

### Session rhythm (never more than 5 minutes without something)

| Every | What |
|---|---|
| 2.2 s | A kid off the bus |
| 90-150 s | A cheater |
| ~3-4 min | A smuggler |
| 5 min | Late Bus (Rare+) |
| 6 min | Rare Letter |
| 10 min | Pop Quiz |
| 15 min | Honor Roll Bus (Legendary+), Recess, Vex's drive-by |
| 30 min | Field Trip, Epic Letter, a Surge (in event weeks) |
| 60 min | Lunch Rush |
| 90 min | Legendary Letter |
| 2 h | Principal's Pick |

**Playtime gifts** (GAME-PLAN; the timer for the next one is always on screen):

| Minute | Gift |
|---|---|
| 5 | $1,000 |
| 10 | Substitute Steve hired for free (he arrives by taxi) |
| 20 | Epic Letter filled |
| 30 | 🍬100 |
| 45 | Honor Roll token (upgrades a Normal kid to Honor Roll) |
| 60 | 15 min of tuition |
| 90 | Gifted token |
| 120 | Legendary Letter +50 % |

The target is a first session of 25+ minutes.

### Principal's Requests: the story chain
**[EXISTS]** `QuestService` runs the tutorial chain and then rotating `Config.Goals`, with rewards of
"max(min, tuition x secs)".

**[CHANGE]**
- After the 11-step First Day (section 2) come **12 chapters of 5 steps (60 steps)**.
- Each chapter is played at one tier and its step 5 is "Face the Board", which plays the next beat.
- Steps 1-4 pay 5, 5, 10 and 10 minutes of tuition respectively (so rewards scale), plus the item listed.
- **The rotating Goals keep running alongside** as the "extra credit" card.

| Ch. | At (host) | Step 1 | Step 2 | Step 3 | Step 4 | Step 5: Face the Board |
|---|---|---|---|---|---|---|
| 1 | Kindergarten (Wobblesworth) | Buy Sharpened Pencils | Hire a teacher for Floor 1 | Bust your first Snack Smuggler (opens the Closet) | Buy desk row 3 ($5K) + Honor Roll token | Hall Monitor + $680K, then beat 2 |
| 2 | Elementary (Loretta) | Build the Playground | Hire Mr. Chalk | Enroll a Rare off a Late Bus | Reach IQ 150 (Textbooks + Rulers) | Band Geek + $59M, then beat 3 |
| 3 | Middle (Stan) | Build Mascot Lockers | Bust 10 smugglers | Make an Eagle Eye catch | Hire Ms. Honeycutt | Star Quarterback + $910M, then beat 4 |
| 4 | High (Hector) | Build the Bleachers | Bonk 3 thieves carrying your kids | Enroll the first kid off an Honor Roll Bus | Own a Legendary | Valedictorian + $47B, then beat 5 |
| 5 | Prep (Grimm) | Build Arched Windows | Own a Mythic | Hire Dr. Beaker | Fill floor 3's first two rows | Prom King + $740B, then beat 6 |
| 6 | Academy (Vex's rivalry) | Build the Fountain | Be on the carpet for a Principal's Pick | Hire Madame Verse | Bust a Golden Smuggler | Kid Genius + $9.6T, then beat 7 |
| 7 | College (Riley) | Stock Smartboards | Keep a Prodigy for 10 min without it being stolen | Make a Gazette headline | Hire Professor Tweed | The New Kid + $110T, then beat 8 |
| 8 | University (Stan and the statue) | Build the Founder's Statue | Build Iron Gates | Collect 12 Golden Wrappers | Hire Dean Maximus | Tiny Professor + $410T, then beat 9 (the Kevin reveal) |
| 9 | Ivy League (Kevin, reformed) | Build Stained-Glass Windows | Catch 500 cheaters in total | Complete one Yearbook rarity row | Graduate 10 kids (Graduation) or stock Robot Tutors | Pop Star Kid + $2.3Qa, then beat 10 |
| 10 | Wizard (Wobblesworth) | Build the Bell Tower | Hire Archmage Quill | Own a Prodigy with a grade better than Normal | Complete the Confiscation Log | Child CEO + $7.2Qa, then beat 11 |
| 11 | Space (Otis) | Hire Commander Nova | Stock Quantum Computers | Own 3 Prodigies at once | Win a Field Day relay or a Dance-Off | Any Secret + $22Qa, then beat 12 |
| 12 | Multiverse (everyone) | Hire The Omniteacher | Stock Thinking Caps | Build 20 Builder items | Collect all 12 Kevin's Waterslide pieces, **or** reach 1 ★ | Walk through the Portal, then the Finale |

### Daily, weekly, login
- **Dailies:** 3 a day from a pool of 20, each paying 🍬20 and 5 min of tuition. Examples:
  - Catch 8 cheaters
  - Bust 3 smugglers
  - Enroll 20 kids
  - Steal 1 kid
  - Be on the carpet for an Honor Roll Bus
  - Answer 3 Pop Quizzes
  - Collect 20 times
  - Bonk 2 thieves
  - Build or stock 1 thing
  - CALL a letter

  Finishing all 3 opens **Loretta's Lunch Box**. It is free and its odds are shown: 50 % 15 min of
  tuition, 25 % 🍬60, 15 % Epic Letter +50 %, 8 % Honor Roll token, 2 % Gifted token.
  One free reroll a day; after that, 25 R$.
- **Weeklies:** 5 (for example 100 catches, 40 busts, pass a review, 3,000 event currency, 10 steals).
  They pay Report Card XP.
- **Login streak (7-day cycle):**

  | Day | Reward |
  |---|---|
  | 1 | 10 min of tuition |
  | 2 | 🍬50 |
  | 3 | Rare Letter filled |
  | 4 | Honor Roll token |
  | 5 | Epic Letter filled |
  | 6 | Attendance plaque decor (upgrades at 30 and 100 days) |
  | 7 | **Pick 1 of 3 Epic kids**, delivered free to your bench (a choice, not a random roll) |

  - Day 14: pick 1 of 3 Legendaries. Day 30: a Mythic Letter filled.
  - One free streak-freeze a week.
- **Coming back:**
  - Stan's **"While you were out"** card: the offline tuition that exists today (`DataService`), cheaters
    his team handled, and smugglers that got away.
  - READY letters in the mailbox.
  - Riley's 3-headline recap.
  - "Principal's Pick in 1:12:40."

### Collections

| Collection | Size |
|---|---|
| Yearbook | 70 kids x 18 grades = 1,260, plus 5 Alumni |
| Wall of Shame | 70 |
| Confiscation Log | 12 |
| Sugar Baron Clue Book | 12 |
| Staff Directory | 12 teachers, with a gold frame for each hired |
| Builder | 24 |
| **Kevin's Waterslide** | 12 pieces, one per event completed. Together they build a playable part-built waterslide on your lawn. Kevin: "FINALLY." |
| Scrapbook | 12 beats + intro + finale |
| Titles | Catches, busts, streaks, events |

### Social
- **Nemesis (P3):** the player who stole the most from you this session is pinned on your HUD. Stealing
  back from your Nemesis within 5 min of their steal gives +50 % carry speed.
- **Most Wanted poster** in the Hub: today's top thief, with a live ViewportFrame headshot.
  It is free and never a paid product.
- **Gazette board:** today's top 5 headlines.
- **Leaderboards on the District Office:** richest school, $/s, steals, busts, catches, Reputation.
- **Friends in the server:** +5 % each, up to +20 %. **Group:** +10 %. Both come from GAME-PLAN [SIM].

### Where players are at hour 20, 50 and 100
"Strong" is the measured sim player (0.3 row D). "Typical" is roughly half that pace (GAME-PLAN section 9).

| Hour | Strong player | Typical player | What pulls them forward |
|---|---|---|---|
| 20 | State University | Prep or Academy | Floor 3. Mythic hunting with Legendary Letters every 90 min and Honor Roll Buses. The Kevin mystery (Wrappers). Hostile Takeover and Candy Carnival weeks. The Wall of Shame Rare row. A Nemesis. |
| 50 | Wizard School | College or University | Prodigy from the Pick and Prodigy Letters. The Stained-Glass and Iron Gates facade. The Founder's Statue ("it blinked"). The first Alumni from events, sitting in the Lounge until tier 8. The Clue Book finishing. Ice-Cream Van goals. |
| 100 | Multiverse | Ivy or Wizard | Owning and *defending* Secrets (HEIST ALERT). The finale. ★ ranks, each with a new Kevin gag. The 1,260-entry Yearbook. Season Alumni every 6 weeks. 6-8 new kids every two weeks (GAME-PLAN). |

---

## 13. Monetization

### Fairness rules (the whole shop follows these)
1. Anything bought that helps you steal or defend has a counter you can play: the Ruler, traps, the gate, teachers.
2. No permanent invulnerability. Total lock time is capped at 150 s.
3. **Every paid random item shows its odds** on the button and on the purchase card. Paid random items are
   hidden where `PolicyService:GetPolicyInfoForPlayerAsync(p).ArePaidRandomItemsRestricted`.
4. **No purchase prompts in the first 5 minutes.** No unsolicited offer before 20:00, and at most one per
   session. Never right after the player was robbed. No fake countdowns.
5. Mythic+ supply is never sold directly (no Mythic or Prodigy letters for Robux). 🍬 and event currencies
   are never sold.
6. Paid kids can be stolen once they are seated.
7. Everything can be gifted, with a banner ("Sam gifted Ava VIP!").

### Game passes

| Pass | R$ | Effect | Notes |
|---|---|---|---|
| VIP Principal | 499 | x2 tuition, VIP tag, gold nameplate, VIP lounge on the District Office roof | The genre standard. Income, not combat. |
| 2x Luck | 349 | x2 luck on buses you stand near | |
| Auto Collect | 249 | Janitor's Cart level 5 from the start | Convenience |
| Extra Desk Row | 199 | +4 desks per floor | [SIM] |
| Long Lock | 149 | +30 s lock | Inside the 150 s cap |
| Bigger Backpack | 299 | Carry 2 kids | **x0.6 speed with two.** One bonk drops both. |
| Rainbow Ruler | 199 | **Cosmetic only** | The reach bonus is removed (paid PvP edge) |
| Teleport Home | 99 | A button that warps you home | Not while carrying |
| Offline Tuition+ | 149 | 12 h at 50 % | |
| **Bigger Bench** (new) | 149 | 5 bench seats, held 20 min instead of 10 | |
| **Cheater & Smuggler Radar** (new) | 129 | HUD arrows to cheaters on your floors and to smugglers heading for your school | Information only |
| **Candy Magnet** (new) | 99 | Candy auto-pickup within 25 studs, +25 % 🍬 | |
| **Custom Bus Livery** (new) | 149 | Your colours on your Welcome Bus and letter deliveries | Cosmetic, a social flex |
| **Event Pass** (per event, new) | 299 | x2 event currency and 1 exclusive decor | A time-saver. Nothing exclusive that adds power. |

### Developer products

| Product | R$ | Effect | Odds and notes |
|---|---|---|---|
| Cash packs | 49 / 149 / 399 / 999 | 10 min / 1 h / 4 h / 12 h of your current tuition | It scales with you, so it can't skip tiers wildly |
| **Lucky Bus** | 199 | The whole server's next bus. **The buyer's name is painted on it.** 5 s of first dibs. | **Legendary 70 / Mythic 24 / Prodigy 5 / Secret 1**, the real weights in `HallService.specialBus` |
| **Prodigy Bus** | 699 | 3 kids | **Prodigy 95 / Secret 5**, shown |
| Server Luck x2 | 99 | 15 min for everyone. The banner names the buyer. Stacks by duration. | Prosocial |
| **Express Letter** | 25 / 79 / 149 | Fills your Rare / Epic / Legendary letter now. **You still pay the cash price.** | The kid is random among the ones you can afford, so the list and odds are shown. Mythic+ is never sold. |
| Grade Reroll | 79 | Rerolls one kid's grade, never down | Odds = the grade weights, shown |
| Instant Lock Refresh | 25 | | |
| Fire Drill | 199 | A 3 s siren warning, then everyone except the owner is pushed out and carriers drop their kid | 3 min cooldown per school |
| Report Card Premium / tier skip | 399 / 49 | Season Alumni, livery, Ruler skin, x1.25 tuition for the season | |
| Limited Alumni | 799 | A specific rotating Alumni, not random | Alumni Lounge rule (pays from tier 8). Stealable once seated. |
| Starter Pack | 99 | **Offered once at 20:00:** $5K, Honor Roll token, Candy Cane Ruler skin, Bigger Bench for 24 h | |
| Daily reroll | 25 | Rerolls one daily | |

**Where the money moments are:**
- The Principal's Pick (every 2 h), the Honor Roll Bus (every 15 min) and admin abuse (Saturday) all pack
  the carpet.
- The **Lucky Bus with the buyer's name** and **Server Luck** sell to those crowds. They are generous
  purchases that everyone benefits from and sees.
- Event Passes and Report Card Premium carry the week-to-week income.
- VIP and 2x Luck are the evergreen passes.
- Nothing pay-to-win is sold at the moment someone was just robbed.

---

## Build order

Highest player impact first. **Each step ends with a play test: a screenshot plus console output, as
evidence, before the next one starts** (CLAUDE.md rule). Any step that touches income re-runs
`tools/econ_sim.py 150 20`.

1. **Kid-safety strings and the smuggler and cheater economics.**
   - Rename "DEALING", "dealer" and "Bust a candy or slime dealer".
   - Kids keep paying during detention, a 60 s fee, no pad wipe, strict-teacher auto-catch only.
   - Sugar Rush x2 for 20 s.
   - These are small edits to PatrolService and Config, and they fix the two things that feel bad
     today (catching costs money; the bust buff is +29 %).
2. **Map widening** (build_map.lua: `plotXs`, trees, ground, the luck strip) with blockout landmarks in
   the six gaps. This is the owner's complaint #1, and it has to land before anything gets placed in the gaps.
3. **Builder facade:** the 8 new `Config.Builds`, boarded windows until `Curtains`, the `BrickWall`
   replaces chain, and the build-in animation (scaffold, drop, dust). Owner's complaint #1.
4. **Guarantees:** UTC offsets in `HallService.start`, the Waiting Bench, Admissions Letters, the Pocket
   Money Promise, and the HUD envelope. Test with two players to prove the reservation works.
5. **The first-5-minute script:**
   - The Welcome Bus reserved and at your gate.
   - The scripted cheat, the windows gift, Vex's tent with Crumpet, the Scholarship.
   - The Freshman Shield and Big-kid rule in StealService.
   - The new `Config.Tutorial` and funnel analytics.
   - **Test with two new players joining 5 s apart.**
6. **The 8 new starters,** with props (a lineup screenshot) and HAIR/NO_HAIR entries. Plus the
   `retune.py` under-$30 rounding fix.
7. **The client Puppet module:** student gags, cheat tells, the teacher loop and reactions, and moving
   TeacherService's C0 tweens to the client. Then hiring by taxi.
8. **Story NPCs** (Wobblesworth, Otis, Stan, Loretta, Hector, Riley, Vex's limo) and **cutscene beats 1-4**
   on the existing Cutscene client, plus the Scrapbook tab.
9. **The Snack Smuggler chase:** lurk spots in the gaps, the freeze and trip gags, public busting, 🍬,
   Stan's Confiscation Closet, and the march to Detention.
10. **Admin panel,** security first (ServerStorage GUI, server re-check, AdminLog), then 4 abuse events.
11. **Principal's Requests chapters 1-4,** playtime gifts, dailies, the login streak.
12. **Events framework + Snow Day + Surges.** Then the seated-grade beam, once econ_sim has a hook for it.
13. **Monetization:** passes and products, with odds shown and PolicyService gating.
14. **Principal's Pick staging, HEIST ALERT, Nemesis.**
15. **The rest:** beats 5-12 and the finale, the other 11 events, the Ice-Cream Van raid, all collections.

## Open questions for the owner

1. **Your Roblox UserId** (and a group id, if you have one), for `Config.Admins`.
2. **The map rebuild:** widening the gaps from 30 to 70 studs moves every plot and means re-running
   `build_map.lua` in Studio. OK to do?
3. **Principal's Pick:** Prodigy 95 % / Secret 5 % (this doc, about +7 % Secret supply), or a guaranteed
   Secret every 2 hours (more hype, about +77 % Secret supply, so Secrets feel less rare)?
4. **Smuggler rewards:** this doc cuts the bust buff from x2 tuition for 60 s to x2 for 20 s and adds 🍬.
   Keep that, or keep the bigger buff and raise the School Board cash values to match? (Row E shows the pacing effect.)
5. **The weekly clock:** the update and featured event on Saturday 15:00 UTC, admin abuse at 17:00 UTC.
   Does that fit when you can be online?
