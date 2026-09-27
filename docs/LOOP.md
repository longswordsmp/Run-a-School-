# The chapter loop

This is what `/loop` runs. Every wake-up reads this file first, then docs/chapters/STATUS.md.

tomas set it up on 2026-09-27: work the chapters in order (build, fix, polish, review, ship) and keep
going through Chapter 12, then keep writing new chapters: more story, map, buildings, quests,
cutscenes. The loop does not stop between chapters for his review. Each shipped chapter gets a report
with screenshots; anything he vetoes is fixed on the next pass, before new work.

Chapter N is school tier N (1 Kindergarten ... 12 Multiverse University). In the code, Chapter 1 is the
To-Do (`Config.Tutorial`, part `ch1`); Chapter N from 2 up is `Config.Chapters[N - 1]`
(`p.chapter.n = N - 1`), played at tier N.

## The chapter checklist (tomas's ten)

A chapter ships only when every line is YES, with the evidence written next to it in STATUS.md.
**A NO is not a note: it becomes work items at the top of that chapter's plan, built before anything
else in the chapter.** "Built, not verified" counts as NO.

| # | Check | YES means | Evidence |
|---|---|---|---|
| 1 | **Possible** | Every step can be done solo, in order, from a fresh save at the chapter's tier. Nothing can stall: no mission that needs a second player, no spawn that never comes, no door that won't open, no prompt off screen. | A playthrough in Studio with real inputs (the debug bridge only to set up the save): each step, how long it took, the reward received. |
| 2 | **Entertaining** | Something happens on screen at least every 3 minutes: a call, a reveal, a chase, a cutscene, a boss, a gag. No step is a bare "buy X": every step has a story reason, spoken to the player. | The playthrough timeline, with the longest gap measured. |
| 3 | **Fun** | The player *does* things, and different things: at least 4 kinds of play in the chapter (stealth, chase, defend, build, explore, puzzle, boss, ride). At least one set piece that is new to this chapter, not a reskin of an earlier mission. Harder than the chapter before. Failing puts you back near where you failed, not at the start. | The kinds of play per step; the new set piece named; a failed attempt, and where it put you back. |
| 4 | **Will it be successful** | 45-60 minutes of play. A reward at least every 5 minutes, and the finale pays big. A cliffhanger into the next chapter. Something new to show off, at your school or on you. The store has something that helps in this chapter, never required and never pushed. | econ_sim output for the tier, the reward timeline, the closing line. |
| 5 | **Cutscenes** | At least 2 new ones: an opening that sets the chapter up and a finale that pays it off. Every new character gets an entrance. SKIP works. | Every shot screenshotted and read: nothing clipping, nobody facing the wrong way, the text on screen and readable. |
| 6 | **Animations** | Everything new moves like it means it: new characters idle and walk (no sliding, no T-pose); a boss has a tell, an attack and a defeat; new gear has a use animation; props are held properly. | Screenshots mid-motion, plus a measurement (joint angles or positions over time). |
| 7 | **Quests** | 10-14 steps, like Chapter 1: the chapter's To-Do or Principal's Requests, at least 2 missions, and the town quests that belong to it. Each step is introduced by a call that says who, where and why. | The step list, with each step's call. |
| 8 | **New characters** | At least 2 new named characters (an ally, a villain, or a townsperson with a job in the story), introduced before they do anything. Each has a model, a portrait and a voice (lines in their style, STORY.md). | Screenshots. |
| 9 | **Items** | At least 1 new item earned by playing (gear like the hoverboard, a key item, a trophy), plus the tier's new school stuff (teachers, supplies, builds). | A screenshot of it in hand or in the shop. |
| 10 | **Areas unlocked** | At least 1 area opened or transformed: reachable on foot, on the town map, with a real interior and decor (not an empty box). | Screenshots inside and out, and of the map. |

The same way, the checks from tomas's earlier asks:

- **Story**: it follows from the chapter before and leads into the next; every event has a reason the
  player has already been shown (STORY.md).
- **The school**: it visibly grows at this tier (campus, stages for plays and events, gym, sports
  fields, the team), per BACKLOG.md P3.
- **Look**: vibrant and kid-friendly; nothing half-finished on screen (no "coming soon"); tomas's vetoes
  kept (below).
- **Performance**: no new errors in the output log; the fps near the new things measured, no drop.

## One wake-up

0. **Preflight.**
   - `list_roblox_studios`. If the studio id changed or Studio restarted, recover:
     - HttpService.HttpEnabled on;
     - redefine `_G.push` (tools/push.lua);
     - checksum every script against `python tools/checksum.py`, and push back any that differ.
   - The file server on 8765 is running.
   - If tomas is playing (any input in the last 5 s), don't start or stop Play: schedule the next
     wake-up in 30 min.
1. **Where are we.** Read STATUS.md. The current chapter is the first one not SHIPPED. tomas's
   vetoes and any messages from him come first, before anything in the plan.
2. **No plan yet?** Write docs/chapters/chNN.md:
   - the story beats and every step with its call;
   - the new characters, items, areas and set piece, the cutscenes, how the school grows;
   - every checklist line answered YES on paper, and how it will be shown.

   That design work is done here on the main thread, never by a sub-agent. Commit it. That is the
   whole wake-up.
3. **Build the next unticked item in the plan**, one only:
   - push it and match the checksum;
   - play-test it: read a screenshot, and take a measurement;
   - fix what it breaks, and replay whatever it touches;
   - commit and push to GitHub, then tick the item in the plan with its evidence.
4. **Plan all ticked?** Run the checklist for real: a playthrough from a fresh save at the chapter's
   tier. Write YES or NO and the evidence into STATUS.md. Every NO goes back into the plan as items
   (step 3).
5. **All YES?** Run an adversarial review over the whole chapter: a workflow, under 10 agents, that
   finds problems and then tries to refute each one. Fix what survives it, then replay what the fixes
   touched.
6. **Ship.**
   - Stop Play and unset SkipIntro.
   - Commit and push.
   - Write docs/chapters/chNN-report.md: what's in the chapter, with screenshots; anything
     unverified, named; what tomas owes.
   - Mark the chapter SHIPPED in STATUS.md.
   - Tell tomas: "Chapter N shipped. File > Save; the report is at ...". Then start the next chapter.
7. **After Chapter 12**, keep going:
   - write Chapter 13 and on into STORY.md (the next villain or threat, new districts, new school
     tiers or prestige content);
   - write a plan for each and ship it through the same checklist.

   Ideas go on the list at the bottom of this file first, so tomas can veto them.
8. **Schedule the next wake-up.** 60 s while there's work. 30 min when blocked (Studio closed, tomas
   playing, waiting on him for something that stops ALL other work, which should almost never happen).

## Rules

- One thing at a time. Nothing is done until it's been seen working: a screenshot that was read, or a
  measurement. Say "built, not verified" when that's the truth.
- Sub-agents never build or judge visuals, models, GUI or story. They only audit and review.
- tomas's vetoes:
  - no neon-blue guide (the yellow 3D arrow replaced it);
  - tuition pads bright neon green;
  - no "+ DESK" floor tape;
  - locked desks stay ghosts (0.85 transparency).
- Never publish the game, create products, spend money, or enter credentials. Those go on the Owed
  list, and the loop carries on with other work.
- Git is the source of truth. Studio must match git for every file touched before a wake-up ends.
- Never kill javaw.exe. PowerShell scripts are ASCII only.

## Owed to tomas (the loop never waits on these)

- File > Save in Studio after each chapter ships.
- Music: licensed stand-ins from the Creator Store, or tracks he uploads that he has the rights to.
- Robux: create the passes and products on the Creator Dashboard and paste their ids into Config
  (docs/ROBUX.md lists them).
- Publishing the game.

## Ideas for after Chapter 12 (tomas can strike any)

(The loop adds to this list before it builds any of it.)
