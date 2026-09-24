# Run a School — game plan

A Roblox tycoon in the Steal a Brainrot mould: students walk down the hallway, you enroll the good
ones, they sit at your desks and pay tuition every second, and everyone else can walk into your
school and steal them. You run the school: name it, hire teachers, upgrade classrooms and scenery,
and face the School Board to rebirth.

Look: bright, saturated, chunky (Steal a Brainrot / Grow a Garden UI grammar: thick black strokes,
Fredoka-style font, gradient buttons, bouncy tweens, rarity colours with animated rainbow for the top
tiers). Yellow is fine here.

## Why it can work
Steal-a-X games win on three things: a readable rarity ladder, constant social tension (anyone can
take your best thing), and income that is visible (money piling up on each pedestal). The school
theme adds what brainrot games lack: *ownership of a place* — a named school you decorate and grow
floor by floor, which is what keeps people coming back after they have the rare pull.

## Core loop (phase 1–2)
1. **Hallway** — a red carpet runs from the **school bus** to **detention**. Students step off the
   bus every ~2 s and walk it. Each has a name, rarity, price and $/s shown on a billboard.
2. **Enroll** — hold the prompt to pay; the student walks to your school and sits at a free desk.
3. **Tuition** — each desk piles up cash ($ shown on the desk). Step on its green pad to collect.
4. **Steal** — walk into someone else's school, hold *Steal* on a desk, carry the student over your
   head (slower) back to your school. The owner can hit you with the **Ruler** to make you drop it.
5. **Lock doors** — the lock button at your entrance raises a laser gate for 60 s; non-owners are
   pushed out. Cooldown so it is a decision, not a permanent wall.
6. **Sell** — sell your own student for half price to free a desk.

## Students (the rarity ladder)
| Rarity | Students | Price | $/s |
|---|---|---|---|
| Common | Sleepy Sam, Crayon Eater, Backpack Kid | 25 – 100 | 1 – 4 |
| Uncommon | Class Clown, Nerd Ned, Hall Monitor | 300 – 1K | 9 – 20 |
| Rare | Teacher's Pet, Skater Kid, Band Geek | 3K – 10K | 45 – 100 |
| Epic | Star Quarterback, Science Fair Winner, Exchange Student | 30K – 80K | 260 – 600 |
| Legendary | Valedictorian, Student Council President, Lunch Lady's Favourite | 300K – 1M | 1.8K – 5K |
| Mythic | Principal's Nephew, Kid Genius, The New Kid | 5M – 20M | 22K – 60K |
| Secret | Kid Who Knows The WiFi Password, Substitute Teacher?! (two kids in a trenchcoat) | 100M – 250M | 500K – 1.2M |

Every student gets a recognisable prop (nightcap, crayon, giant backpack, clown nose, glasses, sash,
apple, skateboard, trumpet, helmet, goggles, suitcase, grad cap, gavel, lunch tray, shades + tie,
glowing brain, router with antennas, trenchcoat stack).

**Grades (mutations)**: Honor Roll (gold, x2), Gifted (diamond, x3), Straight A+ (rainbow, x5).
Rolled on spawn; shown as a coloured tag and a sparkle.

## Running the school (phase 3)
- **Name your school** — sign over the gate and the chalkboard (TextService-filtered).
- **Teachers** — hired in the Staff Room shop, one per classroom row; each boosts that row
  (Gym Coach x1.2 … Headmaster x2). Teachers can be stolen too, but they are heavier (slower carry).
- **Classroom upgrades** — 8 desks → 12 → 16, then a second floor.
- **Scenery** — paint, trees, fountain, trophy case, statue of the player. Each adds *Prestige*,
  which raises spawn luck for the owner (better students roll more often while you stand in the hallway).
- **School Board (rebirth)** — reach the cash target and present a required student; the board
  resets cash and students and grants a permanent tuition multiplier, a new school tier look, and a
  stronger lock time.
- **Index** — collection book of every student x grade; completion rewards.

## Retention and monetisation (phase 4)
- Offline tuition (capped), daily login gift (lunch box), timed events (Field Trip: all Epic+, Snow
  Day: double tuition, Exam Week: new mutation).
- Game passes: VIP (x2 tuition), Bigger Backpack (carry faster), Extra Lock Time. Dev products:
  lucky bus (next bus is Legendary+), cash packs. Nothing sold that the Ruler cannot answer.
- Leaderboards: richest school, most prestige.

## Build order
1. Map: hallway, bus, detention, 8 school plots with desks, pads, gate, sign. **Verify**: screenshot.
2. Server core: data, plot assignment, spawner + walking students, enroll, desks, tuition, collect.
   HUD with cash. **Verify**: play test, buy a student, see it sit, collect cash.
3. Steal, carry, Ruler, lock, sell. **Verify**: two-player test (Studio server + 2 clients).
4. Student props for all 20. **Verify**: lineup screenshot.
5. Naming, teachers, upgrades, scenery, School Board, index, DataStore save.
6. Polish: custom prompt UI, sounds, particles, events, passes.

## Status
- 2026-09-24 — Step 1 (map) built in Studio by `tools/build_map.lua`; verified by an Edit-mode
  screenshot (8 plots, desks, pads, gates, signs, bus, detention).
- Step 2 code written in `src/`. Pushed into Studio: Config, Walkers, Remotes, DataService,
  StudentProps, StudentFactory. NOT yet pushed: PlotService, HallService, Main, HUD.
  Nothing has been play-tested; the Studio copies have not been checksummed against disk.
