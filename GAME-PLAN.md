# Run a School — game design

A Roblox tycoon in the Steal a Brainrot mould. Students step off the bus and walk the red carpet;
you enroll the good ones, they sit at your desks and pay tuition every second, and anyone can walk
into your school and steal them. You run the school: name it, hire teachers, decorate, add floors,
and face the School Board to grow from a one-room Kindergarten into a Space Academy.

Target: 100+ hours before a player has seen everything, with the first hour hooking hard.

---

## 1. Pillars
1. **The pull.** A Secret student strolling down the carpet stops the whole server. Rarity must be
   readable from 60 studs away (colour, glow, particles, sound).
2. **The heist.** Your best student is never safe. Stealing is fast, loud and funny; defending is
   a real choice (lock timing, teachers, gear), not a permanent wall.
3. **My school.** A named place you build up floor by floor, decorate, and show off. This is what
   brings people back after they have the rare pull.
4. **Always a next goal on screen.** Next student you can afford, next desk, next School Board
   review, next Yearbook page, next quest, next event.

---

## 2. Core loop (seconds to minutes)
1. **Bus** — a student steps off every 2.2 s and walks the carpet (about 50 s end to end). The
   billboard shows grade, rarity, name, $/s, price.
2. **Enroll** — press E. Cash is taken, the student walks to your school and sits at a free desk.
3. **Tuition** — each desk piles up cash on its green pad. Step on the pad to collect. A running
   total shows on the pad; the HUD shows total $/s.
4. **Steal** — walk into another school, hold E for 1.5 s on a seated student, carry them over
   your head (speed x0.75) back to your own gate. They are yours.
5. **Defend** — the owner hits the thief with the **Ruler** (knockback, thief drops the student,
   it walks home). The **Lock** button raises the laser gate for 60 s (upgradeable), then a
   cooldown. Nobody but the owner gets through while it is up.
6. **Sell** — hold F on your own student: 50 % of price plus whatever is on the pad.

Special buses: the **Late Bus** every 5 min (all Rare+), the **Field Trip Bus** every 30 min
(Epic+, 2 % Prodigy), and paid **Lucky Buses** (see Monetisation). A server-wide banner and bell
announce each one 10 s before it arrives.

---

## 3. Rarities
Nine tiers. Spawn weights are for the regular bus; luck multiplies everything above Rare.

| # | Rarity | Look | Weight | Price range | $/s range | Payback |
|---|---|---|---|---|---|---|
| 1 | Common | grey text | 50 | $25 – $250 | 1 – 6 | ~25–40 s |
| 2 | Uncommon | green | 25 | $400 – $2.5K | 8 – 30 | ~50–80 s |
| 3 | Rare | blue | 13 | $4K – $25K | 45 – 200 | ~90–125 s |
| 4 | Epic | purple, soft glow | 7 | $40K – $250K | 300 – 1.5K | ~130–170 s |
| 5 | Legendary | orange, point light | 3.5 | $400K – $3M | 2.5K – 12K | ~160–250 s |
| 6 | Mythic | red, sparkles | 1.2 | $5M – $40M | 25K – 120K | ~200–330 s |
| 7 | **Prodigy** | animated cyan-violet gradient, halo, choir sting | 0.25 | $80M – $600M | 250K – 1.5M | ~320–400 s |
| 8 | **Secret** | black + rainbow text, dark aura, record-scratch sting, server banner | 0.04 | $1B – $25B | 3M – 40M | ~330–625 s |
| 9 | **Alumni** | holographic gold, never on the regular bus | event / limited only | $100B+ | 250M+ | — |

Rules:
- Billboard size scales with rarity (Common 7 studs wide, Secret 12).
- Epic+ students leave a coloured footprint trail on the carpet.
- Mythic+ play a sound when they step off the bus; Secret+ trigger a server banner
  ("A SECRET STUDENT IS ON THE CARPET!") and a camera shake for everyone within 150 studs.

---

## 4. Student roster (56 at launch)
Each student: a kid-proportioned R15 rig (big head, short body), skin/shirt/pants colours, hair, and a
**signature prop** that makes it recognisable at a glance. Each has a **favourite subject**
(for the teacher bonus, section 7).

### Common
| Student | Prop | Subject | Price | $/s |
|---|---|---|---|---|
| Sleepy Sam | nightcap, pillow, closed eyes | Music | 25 | 1 |
| Crayon Eater | orange crayon, crayon on his mouth | Art | 50 | 2 |
| Backpack Kid | backpack twice his size | Gym | 75 | 3 |
| Juice Box Jake | juice box with straw, sticky hands | Lunch | 110 | 3.5 |
| Bubble Gum Betty | pink bubble mid-blow | Music | 150 | 4 |
| Pencil Chewer | chewed pencil behind the ear and in the mouth | Math | 200 | 5 |
| Sneezy Sid | tissue box, red nose | Science | 250 | 6 |

### Uncommon
| Class Clown | red nose, rainbow tufts, party hat | Drama | 400 | 8 |
| Nerd Ned | taped glasses, pocket protector | Math | 650 | 11 |
| Fidget Fred | giant fidget spinner that spins | Science | 900 | 14 |
| Hall Monitor | orange sash, badge, whistle | History | 1.2K | 17 |
| Show-and-Tell Sally | pet rock with googly eyes | Science | 1.6K | 21 |
| Gamer Gabe | headset, glowing handheld | Tech | 2K | 25 |
| Theater Kid | drama mask, spotlight follows him | Drama | 2.5K | 30 |

### Rare
| Teacher's Pet | apple, hair bow | History | 4K | 45 |
| Skater Kid | skateboard, backwards cap | Gym | 6K | 60 |
| Mathlete | giant calculator, number particles | Math | 8.5K | 80 |
| Band Geek | trumpet, marching hat with plume | Music | 11K | 100 |
| Cheer Captain | pom-poms that shake | Gym | 14K | 125 |
| Artsy Ava | palette, paint splats on clothes | Art | 19K | 160 |
| Chess Champion | king piece, tiny trophy | Math | 25K | 200 |

### Epic
| Star Quarterback | helmet, football | Gym | 40K | 300 |
| Science Fair Winner | goggles, bubbling flask, lab coat | Science | 60K | 420 |
| Exchange Student | suitcase with stickers, beret | History | 85K | 560 |
| Spelling Bee Champ | full bee costume, antennae | English | 110K | 720 |
| Robotics Kid | robot arm, antenna, blinking lights | Tech | 150K | 950 |
| Yearbook Photographer | camera that flashes | Art | 200K | 1.2K |
| Drama Queen | tiara, feather boa | Drama | 250K | 1.5K |

### Legendary
| Valedictorian | grad cap, diploma | English | 400K | 2.5K |
| Student Council Prez | gavel, badge, tie | History | 650K | 3.6K |
| School Mascot | giant eagle costume head | Gym | 900K | 4.8K |
| Lunch Lady's Favourite | loaded lunch tray, chef hat | Lunch | 1.3M | 6.5K |
| Prom King | crown, sash, rose | Drama | 1.8M | 8.2K |
| School Dance DJ | headphones, turntable, bass pulses | Music | 2.4M | 10K |
| Hall-of-Fame Athlete | gold trophy, medals | Gym | 3M | 12K |

### Mythic
| Principal's Nephew | shades, gold chain, blazer | History | 5M | 25K |
| Kid With A Moustache | full moustache at age 11, briefcase | English | 8M | 35K |
| Kid Genius | huge head, glowing brain | Science | 12M | 48K |
| Ghost of Room 13 | translucent, floats, chains | Drama | 18M | 65K |
| Time-Traveling Transfer | retro clothes, pocket clock, afterimages | History | 26M | 88K |
| The New Kid | hood up, only glowing eyes | Tech | 40M | 120K |

### Prodigy
| Rocket Science Kid | jetpack with flame | Science | 80M | 250K |
| Tiny Professor | tweed jacket, bubble pipe, chalk | English | 140M | 400K |
| Pop Star Kid | microphone, glitter, spotlights | Music | 220M | 620K |
| Chess Grandmaster (age 9) | floating chess pieces orbit him | Math | 350M | 950K |
| Child CEO | suit, briefcase leaking cash | Tech | 600M | 1.5M |

### Secret
| Kid Who Knows The WiFi Password | router on head, WiFi waves | Tech | 1B | 3M |
| Substitute Teacher?! | two kids in a trenchcoat, fedora, fake moustache | Drama | 2.5B | 6.5M |
| The Snow Day Oracle | snow globe, snowfall around her | Science | 5B | 12M |
| The Kid Who Reminded The Teacher About Homework | red glowing eyes, homework stack, villain music | English | 10B | 22M |
| Student #404 | glitching, pixel particles, name tag flickers | Tech | 25B | 40M |

### Alumni (events and limited)
| Graduate Grandpa | cane, 1950s letterman jacket | Snow Day event |
| Class of '99 | frosted tips, flip phone | Throwback event |
| Head Prefect | cape, wand | Wizard Week |
| The Founder | statue come to life, bronze | anniversary |
| Principal (as a kid) | tiny suit, tiny clipboard | Report Card season 1 finale |

Updates add 6–8 students every two weeks, always with at least one Prodigy or Secret.

---

## 5. Grades (mutations)
Rolled when a student steps off the bus. Shown as a coloured tag above the rarity, a tint or overlay on the model, and particles.

| Grade | Mult | Weight | Look |
|---|---|---|---|
| Normal | x1 | 88 | — |
| Honor Roll | x1.5 | 7 | gold outline, gold sparkles |
| Gifted | x2.5 | 3 | diamond-blue outline, crystal particles |
| Straight A+ | x5 | 0.8 | rainbow outline cycling, star particles |
| Detention | x4 | 0.6 | dark purple, ball and chain, grumpy face |
| Valedictorian's Pick | x8 | 0.1 | gold-white aura, floating laurel |
| *Event*: Snow Day | x3 | event | icy blue, snowflakes |
| *Event*: Radioactive (Science Fair) | x4 | event | green glow, bubbles |
| *Event*: Picture Perfect (Picture Day) | x2 | event | photo frame, flash |
| *Event*: Spooky (Halloween) | x3.5 | event | pumpkin head, bats |
| *Event*: Cosmic (Space Camp) | x7 | event | starfield skin, orbiting planets |

The Yearbook tracks every student x grade: 56 x 11 = 616 entries at launch.

---

## 6. The school (plot)
### School tiers (School Board reviews = rebirths)
Each review needs cash and one or two named students present at your desks. It resets cash,
students and desk cash; you keep Yearbook, teachers' levels, decor, gear and upgrades. Each tier
changes the building's look and adds a floor.

| Tier | School | Needs | Rewards |
|---|---|---|---|
| 0 | Kindergarten | — | 1 floor, 8→16 desks, crayon walls |
| 1 | Elementary School | $150K + Hall Monitor | x1.5 tuition, playground, lock 70 s |
| 2 | Middle School | $2M + Band Geek | x2, **floor 2**, lockers, gear tier 2 |
| 3 | High School | $25M + Star Quarterback | x3, football field decor, lock 80 s |
| 4 | Prep School | $300M + Valedictorian | x4.5, **floor 3**, uniforms, teacher slot 2 |
| 5 | Private Academy | $3B + Prom King | x6.5, marble and fountain, lock 90 s |
| 6 | Community College | $30B + Kid Genius | x9, gear tier 3 |
| 7 | State University | $250B + The New Kid | x13, **floor 4**, quad with statue |
| 8 | Ivy League | $2T + Tiny Professor | x18, library tower |
| 9 | Wizard School | $15T + Pop Star Kid | x25, floating candles, **floor 5** |
| 10 | Space Academy | $100T + Child CEO | x35, rooftop launch pad |
| 11 | Multiverse University | $1Qa + any Secret | x50, portal gate |
| 12+ | Prestige ranks (★) | x3 cash of the last tier each | +10 % each, gold name plate |

Each floor has 16 desks (rows of 4 unlock with cash) and one **classroom subject** the owner picks.
Floors connect by a staircase at the back; the Lock gate covers the ground-floor entrance, so thieves
have to carry a student down every flight (each floor is a long walk back under Ruler fire).

### Upgrades (cash sinks, kept on review)
| Upgrade | Levels | Effect |
|---|---|---|
| Desk rows | per floor, 4 rows | 4 desks each |
| Lock time | 10 | 60 s → 150 s |
| Lock cooldown | 5 | 10 s → 3 s |
| Tuition Office | 1 | a "Collect All" pad by the gate |
| Janitor's Cart | 5 | auto-collect every 60 s → 10 s |
| Security Camera | 3 | pings you when someone enters your school; level 3 marks the thief |
| Alarm Bell | 1 | rings server-wide when a student is stolen from you (thief is outlined red) |
| Hall Pass | 5 | +4 % walk speed per level while carrying |
| Recruitment Office | 10 | +2 % luck per level while you stand on the carpet |

### Decor and Prestige
Decor is placed on grid slots inside the plot and on the lawn (slots grow per tier). Every item has
Prestige points. Prestige rolls up into a **School Rating** (1–5 stars, then ★ ranks) shown on the
sign: +5 % tuition and +3 % luck per star.

Categories and examples (60 items at launch):
- Nature: oak, cherry blossom, hedge, flower bed, pond with ducks, school garden
- Playground: swings, slide, jungle gym, sandbox, tetherball, merry-go-round
- Sports: basketball hoop, soccer goal, running track, trophy case, bleachers
- Fancy: fountain, founder statue, chandelier, red carpet, grand piano, marble columns
- Tech: smart board, robot helper, server rack, hologram globe
- Spooky/Seasonal: pumpkins, snowman, graduation arch, prom balloons (event shops only)
- Signature: giant player statue (cast in bronze/silver/gold/diamond by Prestige)

### Customisation (free unless marked)
School name (TextService filtered), wall and floor paint (24 colours, 6 patterns), mascot
(Eagles, Tigers, Sharks, Llamas, Hot Dogs, Robots…), flag, bus livery (paid), chalkboard message.

---

## 7. Teachers
Hired in the **Staff Room shop** (restocks every 5 minutes, 4–6 teachers per restock, rarer ones
rare). One teacher slot per floor (two from Prep School). A teacher boosts the students on their
floor, gives a further x1.5 to students whose favourite subject matches the teacher's, and levels
up with cash (1–25, +4 % per level). Teachers can be stolen too; they are heavy (carry speed x0.55).

| Rarity | Teachers (subject — effect) |
|---|---|
| Common | Student Teacher (any — x1.1), Gym Coach (Gym — x1.15), Art Teacher (Art — x1.15), Music Teacher (Music — x1.15) |
| Uncommon | Librarian (English — x1.2, +10 s lock), Math Teacher (Math — x1.25), Science Teacher (Science — x1.25), History Teacher (History — x1.25) |
| Rare | Drama Teacher (Drama — x1.35), Computer Teacher (Tech — x1.35), **Janitor** (any — auto-collect this floor), **Lunch Lady** (Lunch — x1.3, offline tuition x1.5) |
| Epic | **Detention Supervisor** (any — thieves on this floor move x0.7), **School Nurse** (any — you shrug off Ruler hits for 3 s after one), Guidance Counselor (any — +10 % luck) |
| Legendary | Vice Principal (all floors x1.4), Coach Legend (Gym x2), Mad Scientist (Science x2 + Radioactive chance) |
| Mythic | Principal (all floors x1.8, lock +20 s), Robot Teacher (any x1.6 + auto-collect) |
| Prodigy | Superintendent (all floors x2.5), Wizard Professor (any x2, grade reroll once a day) |
| Secret | The Headmaster (all floors x3.5, gate cannot be opened by gear) |

---

## 8. Stealing, defending, gear
**Stealing rules**
- Hold E 1.5 s on a seated student in someone else's school. You can steal only when the owner is
  in the server. Stealing never works while their gate is up.
- Carrying: student above your head, speed x0.75 (Hall Pass helps), no jumping above 5 studs, gear
  locked except the Hall Pass. You drop it if you get hit, fall in the void, or 60 s runs out; a
  dropped student walks back to its desk.
- Reaching your own gate with a free desk makes it yours (grade and pad cash reset to 0). No free
  desk means it waits at your gate for 20 s, then walks home.
- Steal cooldown 10 s. The owner sees a red "THIEF!" arrow and hears an alarm.

**Gear shop** (cash; a few premium versions)
| Gear | Price | Effect |
|---|---|---|
| Ruler | free | melee knockback, makes a thief drop |
| Meter Stick | $50K | longer reach |
| Golden Ruler | $50M | stuns 1.5 s |
| Hall Pass | $5K | +30 % speed 15 s, 45 s cooldown |
| Spitball Straw | $250K | ranged, 1 s stun |
| Banana Peel | $1M | trap, slips the first thief |
| Whoopee Cushion | $2M | trap, outlines the thief for 10 s |
| Chalk Bomb | $15M | smoke cloud, breaks targeting |
| Jump Rope Grapple | $80M | swing onto roofs and floors |
| Paper Airplane | $300M | glide from floor 3+ |
| Invisibility Hoodie | $1B | invisible 8 s, not while carrying |
| Detention Slip | $5B | freezes a thief inside your school for 3 s |
| Fire Drill | 199 R$ | everyone who is not the owner is pushed out of your school, 60 s cooldown |

---

## 9. Progression and the 100 hours
Pacing targets, measured with a solo play test and tuned through Config:

| Time played | Where the player should be |
|---|---|
| 0–5 min | tutorial (below): first enrol, first collect, first lock, first steal on the tutorial dummy |
| 15 min | 8 desks full of Commons/Uncommons, first Rare seen |
| 45 min | 12 desks, first Rare owned, first School Board review (Elementary) |
| 2 h | first Epic, teachers on floor 1 |
| 5 h | Middle School, floor 2, first Legendary |
| 12 h | High School, several Legendaries, Janitor auto-collect |
| 25 h | Prep School, floor 3, first Mythic |
| 45 h | Academy/College, first Prodigy |
| 70 h | University, first Secret |
| 100 h | Ivy League / Wizard School, Yearbook 60 % |
| 100 h + | Space Academy, Multiverse, ★ ranks, full Yearbook with grades, Alumni collection, seasons |

Long-tail content: Yearbook (616 entries plus Alumni), 12 tiers plus endless ★ ranks, 24 teachers x
25 levels, 60 decor items per season, achievements, seasonal Report Card, weekly events,
leaderboards.

### Tutorial ("First Day")
1. The Principal NPC at your gate: "Welcome, new principal! Enroll a student." An arrow and beam
   point at a guaranteed Common walking past; it costs exactly your starting $100.
2. "They pay tuition every second — step on the green pad." (5 s later)
3. "Lock your gate when you leave." Press the button; lasers come up.
4. "Other principals will steal your students. Practise on this one." A tutorial dummy plot with a
   single student; steal it and carry it home.
5. "Name your school." Opens the Name School panel. Reward: $250 and the first quest chain.

### Quests
- **Principal's Requests**: 60-step story chain that doubles as guidance ("Own 3 Uncommons",
  "Hire a teacher", "Reach 2 stars", "Pass your first School Board review"…), each with cash, gear
  or decor rewards.
- **Dailies**: 3 per day (enroll 25, steal 2, collect $X, stand on the carpet for a Late Bus…),
  reroll 25 R$. Completing all 3 gives a Lunch Box (random cash, gear or Honor Roll token).
- **Weeklies**: 5 larger goals, reward Report Card XP.

### Report Card (season pass, 6 weeks)
50 tiers, XP from quests and playtime. Free track: cash, decor, gear. Premium track (399 R$): the
season's Alumni student, a bus livery, a Ruler skin, exclusive decor, x1.25 tuition for the season.
Tier skips 49 R$.

### Retention
Playtime gifts at 5/10/20/30/45/60/90/120 min; daily login streak (7-day cycle, day 7 = a random
Epic); offline tuition (base 2 h at 25 %, upgraded by Lunch Lady and a game pass); group reward
(+10 % tuition for group members); friends in server +5 % each up to +20 %.

### Minigames and moments
- **Pop Quiz**: every 10 minutes a 10-second quiz pops up for everyone (school trivia, maths); right
  answer = 60 s of tuition as a bonus.
- **Recess**: every 15 minutes the bell rings; the carpet speeds up and luck goes x2 for 60 s.
- **Lunch Rush**: food fight in the cafeteria square; hit people with food for Lunch Money tokens.
- **Field Day** (event): relay race around the map for event currency.

### Events (weekly rotation, plus admin events on update days)
Snow Day, Science Fair, Picture Day, Field Day, Halloween, Prom Night, Space Camp, Throwback Week,
Graduation (season finale). Each brings: map dressing, an event grade, an event currency and shop,
one or two event students, a limited decor set.

### Leaderboards and social
Global and server boards: richest school, most tuition/s, most steals, highest School Rating, most
School Board reviews. A **Most Wanted** poster in the hallway shows the server's top thief today.
Server banners for Secret pulls, Secret steals, and every School Board review.

---

## 10. UI (Steal-a-X grammar)
**Style**: thick 3–4 px black strokes on everything, rounded corners (12–18 px), vertical
gradients (light top, saturated bottom), fonts FredokaOne (UI) and LuckiestGuy (big numbers and
banners), bouncy Back-easing tweens, 1.05 hover scale, 0.92 press scale, a click sound on every
button.

**Palette**: cash green #3DDC6A, action blue #3AA0FF, danger red #FF4A4A, warning orange #FF9F1A,
purple #A45CFF, panel cream #FFF7E6 with dark text or panel navy #1E2240 with white text. Rarity
colours from section 3.

**HUD layout**
- Bottom centre: cash (big LuckiestGuy number), $/s underneath, count-up animation and punch on gain.
- Left edge, vertical: square buttons with icon and label — Shop, Staff Room, Upgrades, School
  Board, Yearbook, Decor, Quests. Red "!" badge when something is claimable or affordable.
- Top centre: event and bus timers ("Late Bus 2:31"), toasts under them.
- Top right: quest tracker (current Principal's Request with a progress bar), collapsible.
- Right edge: Report Card button and daily gift button with timers.
- Centre: big announcements ("YOU STOLE THE VALEDICTORIAN!", "SCHOOL BOARD APPROVED!") with scale
  punch, confetti and camera shake.

**Panels**: one shared frame: header ribbon in the panel colour with a title in LuckiestGuy, red X
close button top-right, tabs across the top, a scrolling grid of cards. Cards have a
rarity-coloured gradient background, the item's viewport render, name, stat line, and a price
button that goes grey when you cannot afford it.
- Shop (gear), Staff Room (teachers + restock timer), Upgrades (list with level pips),
  School Board (next tier card with requirement checklist and the new school rendered in a
  viewport), Yearbook (grid by rarity, silhouettes for unseen, grade tabs, completion % and
  row rewards), Decor (placement mode with a grid and rotate/confirm buttons), Quests, Report
  Card (horizontal track with free/premium rows), Settings (music, SFX, low graphics, hide
  others' billboards), Name School (text box + mascot + colours).

**World UI**: student billboards (section 3), desk pad totals, custom proximity prompts (rounded
pill with a key badge, rarity-coloured for students), school sign with name, stars and tier, a
lock countdown over the gate, THIEF arrow over carriers.

**Sound**: school bell for buses and recess, cash register on collect (pitch rises with amount),
alarm on steal, record scratch for Secrets, choir for Prodigy, cheering on School Board review,
chalkboard squeak on errors, lo-fi hallway music, cafeteria ambience.

---

## 11. Monetisation (fair: nothing sold that gear or skill cannot answer)
**Game passes**
| Pass | R$ | Effect |
|---|---|---|
| VIP Principal | 499 | x2 tuition, VIP tag, gold nameplate, VIP lounge on the map |
| 2x Luck | 349 | x2 luck on every bus you stand near |
| Auto Collect | 249 | Janitor's Cart level 5 from the start |
| Bigger Backpack | 299 | carry two students at once |
| Extra Floor Row | 199 | +4 desks on every floor |
| Long Lock | 149 | +30 s lock |
| Rainbow Ruler | 199 | cosmetic + slightly longer reach |
| Teleport Home | 99 | button that sends you to your school (not while carrying) |
| Offline Tuition+ | 149 | 12 h at 50 % |

**Developer products**
| Product | R$ | Effect |
|---|---|---|
| Cash packs | 49 / 149 / 399 / 999 | 10 min / 1 h / 4 h / 12 h of your current tuition |
| Lucky Bus | 199 | next bus for the whole server is Legendary+ (you get first dibs for 5 s) |
| Prodigy Bus | 699 | next bus is Prodigy+ |
| Server Luck x2 | 99 | 15 min for everyone (name shown in the banner) |
| Instant Lock Refresh | 25 | reset lock cooldown |
| Fire Drill | 199 | see gear |
| Grade Reroll | 79 | reroll one student's grade (never downgrades) |
| Report Card Premium / tier skip | 399 / 49 | section 9 |
| Limited Alumni | 799 | rotating, time-limited |
| Gifting | — | every pass and product can be gifted |

Also: Premium Payouts (keep Premium players playing: +10 % tuition for Premium), group rewards,
a starter pack at 99 R$ shown once after 20 minutes (Hall Pass, Honor Roll token, $5K).

---

## 12. Technical plan
- Server-authoritative everything: prices, steals, collects, locks. Remote calls rate-limited
  and validated (distance, ownership, cooldowns).
- DataStore with session locking (ProfileStore-style), autosave every 90 s and on leave; data
  versioning with migrations.
- One plot per player (8 per server). Floors are prefab models swapped per tier.
- Students are anchored rigs moved by one server Heartbeat; billboards and props built from
  Config; templates cached in ServerStorage.
- Config-driven content (students, grades, teachers, gear, decor, tiers, quests, events) so updates
  are data changes.
- Analytics events (AnalyticsService funnels: tutorial steps, first review, purchases) to tune
  pacing.

---

## 13. Build order
Each step ends with a play-test (screenshot + console) before the next starts.

1. **Map v1** — hallway, bus, detention, 8 plots. ✅ built, screenshot verified.
2. **Core loop** — bus spawner, enroll, walk home, sit, tuition, collect, sell, HUD cash.
3. **UI kit** — shared panel/button/card components, left button bar, toasts, announcements,
   custom prompts.
4. **Full roster** — 56 students with props (lineup screenshot per rarity), grades with visuals.
5. **Steal and defend** — steal prompt, carry, Ruler, drop/return, lock gate, alarm.
6. **Upgrades + desks + Tuition Office + Janitor.**
7. **School Board** — tiers 0–4 with building looks and floors 2–3.
8. **Teachers + Staff Room restock.**
9. **Yearbook + Principal's Requests + tutorial.**
10. **Decor + Prestige + customisation.**
11. **Gear shop.**
12. **DataStore with session locking, offline tuition.**
13. **Monetisation** — passes, products, Lucky Bus.
14. **Special buses, Recess, Pop Quiz, playtime gifts, dailies.**
15. **Events framework + Snow Day**; Report Card season 1.
16. Tiers 5–11, remaining events, leaderboards, polish, sound, performance pass.

## Status
- 2026-09-24 — Step 1 (map) built in Studio by `tools/build_map.lua`; verified by an Edit-mode
  screenshot (8 plots, desks, pads, gates, signs, bus, detention).
- 2026-09-24 — Step 2 (core loop) verified in a Studio play test: all scripts checksum-equal to
  disk; bus spawns students with walk animation and billboards (screenshot); a real E press
  enrolled a Crayon Eater ($100 -> $50), it walked to desk 1 and sat facing the chalkboard
  (screenshot); tuition $2/s piled on the pad; stepping on the pad collected ($50 -> $104);
  holding F sold it ($104 -> $151, desk cleared, income 0). Console clean.
  Test hook: ServerStorage.DebugBridge (Studio only) — see src/Server/DebugBridge.lua.
- 2026-09-24/25 (overnight) — see NIGHT-LOG.md for every feature built overnight with its evidence
  (play-test numbers, screenshots, econ sim). docs/DESIGN-v2.md supersedes this file where they
  disagree (teachers, prestige, tier cash); its build order steps 1-5 are done.
