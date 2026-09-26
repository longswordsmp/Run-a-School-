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
| 8 | Prestige: GOLD, DIAMOND, then ALIEN (the abduction questline + cutscenes), permanent multipliers | Gold/Diamond/Alien finishes + panel + cutscene done; alien questline (X01-X06) next |
| 9 | Town quests: 70 (Downtown 20, Maple 20, Park 14, Industrial 10, Lab/Vex Prep 6) | |
| 10 | 50 cutscenes | |
| 11 | House interiors (Maple Heights homes enterable and furnished) | |
| 12 | UI pass: spacing, sizing, custom panels, smoother animations, new loading screen | |
| 13 | Soundtrack: music per area / event / cutscene (Break In-style licensed tracks) | |
| 14 | Admin panel: cutscenes, areas, teleports, events, weather, quests, prestige | |
| 15 | Events and buses, Robux shortcuts, a progression check (econ_sim) | |

## Owed to tomas (things only he can do in Studio)

- File > Save after sessions that change the place: the bus, Detention, ServerStorage.TownAssets
  (the nature models), the swapped trees.
- Game Settings: Max Players 8. Create the passes and products and paste their ids into Config.
