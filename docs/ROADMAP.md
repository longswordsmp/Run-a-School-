# Run a School: the roadmap (2026-09-26)

tomas's asks, in his words, then the order they are built in. One piece at a time, each verified
in Studio (screenshot or measurement) and committed before the next. docs/TOWN.md is the spec for
the town, the quest engine and the cutscene engine; this file covers everything asked since.

## The asks

1. (09-26, earlier) Quests that lead through stealing mutations and kids from the VexCorp Lab, a top
   secret lair, the admin panel back with much more, more events, buses, animations, at least 50
   cutscenes and 100 quests, townspeople, houses, a grocery store, a whole town that is not huge but
   has a lot to explore, areas locked until unlocked, one main villain with a huge story line, Break
   In-style music, smoother UI and animations, progression so there is always something to do, Robux
   to get ahead.
2. (09-26) The scenery is crappy: no ring of ball rocks round the water, the water a blue block with a
   texture, not terrain water. DONE c077a94 (low-poly nature models, textured lake, sandy shore).
3. (09-26) Make the headquarters HUGE: several layers, and things you have to do to get past each one.
   Actual missions. Decor inside houses. NPCs. Better UI with good spacing and sizing. School upgrade
   options that are really good: a huge college, high school, middle school, the kids getting older
   as the school grows, better stuff. Then prestige: make the school GOLD, then DIAMOND, then an even
   rarer one from an ALIEN quest where you get abducted. A ton of gameplay (it is a 1 hour game now).
   Everything high quality: scenes, animations, cutscenes, loading screens, a soundtrack, full custom
   UI. Don't stop and don't ask to continue.

## What already exists (so it gets extended, not duplicated)

- 12 school tiers `Config.Tiers` (Kindergarten, Elementary, Middle, High, Prep, Private Academy,
  Community College, State University, Ivy League, Wizard School, Space Academy, Multiverse
  University), `p.tier`, advanced by the Board review (the rebirth). Past tier 12: `p.stars`.
- The school building: fixed footprint, 1-3 floors, colours and a tower per tier (`TierLooks`).
- Kids: no age. `Config.Grades` means mutations (Honor Roll, Mutated...), not school grade.
- Story: 11 chapters, 11 Wobblesworth missions (defend / chase / heist), Stan's secret jobs, the
  Principal's To-Do, daily and weekly quests. Stealth: guards with vision cones, sneak, sprint,
  cardboard box, smoke. Lab heist, Vex Prep heist, goon raids.
- Cutscenes: 4 hard-coded (Board, Intro, Finale, Rival). Music: one track.

## Build order

| # | Piece | State |
|---|---|---|
| 1 | Scenery: nature models, textured lake | done c077a94 |
| 2 | Townspeople: 29 NPCs, tags, chatter, talk prompt, walkers | done d5078d0 |
| 3 | Quest engine: `Shared/Quests.lua`, `TownQuestService`, Quest Log, tracker, beam, "!" markers, goons + chase steps | done d5078d0, f4a8f5b |
| 4 | Cutscene engine: `Shared/Cutscenes.lua`, data-driven player, place-based shots | done f4a8f5b |
| 5 | Story content: 30 story quests (Dr. Vex arc), district unlocks move to story quests | |
| 6 | VexCorp HQ, huge: 6 floors with a challenge each (cubicle stealth + keycard, laser vault, camera server farm, acid lab + pod rescue, goon arena + Crumpet boss, executive vault code), feeding the Lair | done 83f7279..(floor 7) |
| 7 | School growth: the building gets bigger per tier (wings, more floors, campus for college), kids age with the tier (size, clothes, props), better stuff per tier | building + size done (next: per-tier clothes/props, better stuff) |
| 8 | Prestige: GOLD, DIAMOND, then ALIEN (the abduction questline + cutscenes), permanent multipliers | done 8c08f8c + Close Encounters X01-X06 |
| 9 | Town quests: 70 (Downtown 20, Maple 20, Park 14, Industrial 10, Lab/Vex Prep 6) | |
| 10 | 50 cutscenes | |
| 11 | House interiors (Maple Heights homes enterable and furnished) | |
| 12 | UI pass: spacing, sizing, custom panels, smoother animations, new loading screen | |
| 13 | Soundtrack: music per area / event / cutscene (Break In-style licensed tracks) | |
| 14 | Admin panel: cutscenes, areas, teleports, events, weather, quests, prestige | |
| 15 | Events and buses, Robux shortcuts, a progression check (econ_sim) | |

## The 2026-09-27 asks (UI, Robux, world), in the order they are being built

Done (commits on main): side-button tiles + 3D icons (861ecb1, 60f0215); studs over the whole UI, one
stud size, the Global-ZIndex fix (every ScreenGui/BillboardGui not told otherwise is GLOBAL: an overlay
at zindex 0 draws under its frame) (35d006c); no "Unlock now" area purchases; rainbow Store title bar,
green Store button; no bursts behind store icons; Money Boost doubles x2..x1024, 25..12,800 R$
(5fc4c35); the WAIT! leave pop-up, Offline Tuition+ 199 R$ in the Store and a real 49 R$ deal pass
(b1c9879); stud-style world, rebuilt store icons (4c9a6ad).

| # | Piece | State |
|---|---|---|
| A | DONE c20752d. Side bar down to 5 (Home, Store, Shop, Upgrades, Settings; Admin for admins). Board -> the District Office (a prompt there); Yearbook -> a yearbook shelf at your school; Name -> your school's gate sign; Files -> a filing cabinet at your school (NOT VexCorp HQ: that's late game); Coop -> a noticeboard at your school; Daily -> pops up when a reward is ready; Quests -> click the quest card. Unlock toasts, the tutorial guide (panel:Board, panel:NameSchool), the Board lines in SewerHeist and Config (Wobblesworth) point at the places. | next |
| B | The Co-op window redesigned (tomas: "doesn't look good") | done 11d23d7 |
| C | Smart Robux deals: offers that pop up when the player needs them (short of cash for the next desk -> a tuition pack; gate on cooldown -> Lock Refresh; a letter waiting -> Express), never a fake price | done 987ae0a (card on screen still to be seen past the First Morning) |
| D | (tomas 09-27: 4 players a server -> 4 plots, each ~4x today's 120x175; the town is re-laid around them, with E) Bigger school plots; the gym, library, cafeteria, auditorium are NOT part of the school: an Architect (a mission) builds each room for cash, so the story makes sense | |
| E | The full map, building and model redo ("look like a whole different game"), in the stud style | |

## Owed to tomas (things only he can do in Studio)

- File > Save after sessions that change the place: the bus, Detention, ServerStorage.TownAssets
  (the nature models), the swapped trees.
- Game Settings: Max Players 4 (one school each; was 8). Create the passes and products and paste their ids into Config.
  New on 09-27: the four tuition packs (Cash8h 179, Cash16h 329, Cash24h 449, Cash1w 1999), the ten
  Money Boost doublings (MoneyBoost1..10: 25, 50 ... 12,800), Offline Tuition+ at 199 and the
  OfflinePlusDeal pass at 49.
