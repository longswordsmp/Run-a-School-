# Chapter status

The loop's scorecard (docs/LOOP.md). A chapter is SHIPPED only when all fourteen checks are YES from a
playthrough in Studio, with the evidence written here. The first scores are a **code audit, not a
playthrough** (2026-09-27: 4 auditors read the code, 4 skeptics tried to refute each score; 19% of the
scores (32 of 168) were corrected). The full audit, with file:line evidence for every score, is
[audit-2026-09-27.md](audit-2026-09-27.md).

Y = yes, ~ = partly, N = no (from code; nothing is YES for shipping until played).

| Ch | Tier | State | Poss | Ent | Fun | Succ | Cut | Anim | Qst | Char | Item | Area | Story | Sch | Look | Perf |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Kindergarten | IN PROGRESS | ~ | ~ | ~ | ~ | ~ | ~ | ~ | Y | Y | ~ | ~ | ~ | ~ | ~ |
| 2 | Elementary | not started | ~ | ~ | ~ | ~ | ~ | ~ | ~ | Y | ~ | Y | ~ | ~ | ~ | ~ |
| 3 | Middle | not started | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | Y | ~ | ~ | ~ | ~ |
| 4 | High | not started | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ |
| 5 | Prep | not started | ~ | ~ | ~ | ~ | ~ | ~ | ~ | N | ~ | N | ~ | ~ | ~ | ~ |
| 6 | Private Academy | not started | ~ | ~ | ~ | ~ | ~ | ~ | ~ | N | ~ | Y | ~ | ~ | ~ | ~ |
| 7 | Community College | not started | ~ | ~ | ~ | ~ | ~ | ~ | ~ | N | ~ | N | ~ | ~ | ~ | ~ |
| 8 | State University | not started | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | Y | ~ | ~ | ~ | ~ |
| 9 | Ivy League | not started | ~ | ~ | ~ | ~ | ~ | ~ | ~ | N | ~ | N | ~ | ~ | ~ | N |
| 10 | Wizard School | not started | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | N |
| 11 | Space Academy | not started | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | N |
| 12 | Multiverse University | not started | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | ~ | N | ~ | ~ | ~ | N |

## What each chapter needs (the audit's to-add list; the loop turns these into plan items)

### Chapter 1: Down the Pothole (Kindergarten)

Chapter 1 is the To-Do list: the 7-step First Morning (Config.lua:429-435) and 13 Chapter 1 steps (Config.lua:437-451). Between them they run five missions: k_hallrun and k_tiara (chases), k_crew (defend), k_map (Factory item heist) and k_heist, the Vex Prep Job (SewerHeist.lua), which ends at the Board review for Elementary. Four hard-coded cutscenes are wired to it: Intro 'The Keys', the FirstMorning card, the Vex Prep showcase 'Rival' and the VexPA finale, plus the Board scene. Nothing here was play-tested by this audit; per BACKLOG.md:67 the whole chain has only been played through the debug bridge, and the Job was played by hand twice (BACKLOG.md:8). Auditor note: a what-if import of tools/econ_sim.py may have regenerated the tracked cache tools/__pycache__/econ_sim.cpython-312.pyc (git shows it modified, 24978 -> 36598 bytes); no source file was touched.

Length: About 40-60 min. This is an estimate, not a measurement. Unmodified, econ_sim puts Elementary at 1.64h median (1.26-1.95h) for a bot that gets none of the To-Do rewards. econ_sim does not model Config.Tutorial: it parses only Config.Chapters (econ_sim.py:104-114). The To-Do's minimum rewards add up to about $3.5M (Config.lua:429-451, k12 alone $2.5M) against the $5M Board price (Config.lua:178). A what-if run of econ_sim.simulate with Elementary's price cut to $1.5M gave a 42.2 min median (35.6-54.5 min over 5 seeds). Neither run counts mission travel, chases or cutscenes, or the free Hall Monitor and Drama Queen (Epic, 1500/s, Config.lua:95) gifts.

To add:
- Play-test k_map by hand against the new Factory office (laser gate, cameras, 4th guard) and check the First Morning rescue is still lenient, then commit FactoryService.lua and Raid.client.lua (ch01.md:27-34).
- Do a fresh-save solo playthrough by hand from first join to the Board. Log the time and reward of each step and the longest gap with nothing happening, to answer Possible, Entertaining and 45-60 min with evidence.
- Add StepCalls with a story reason for k03_name, k07_row4 and the morning's collect (Config.lua:455-471).
- Put an on-screen beat in the k01-k03 run of menu steps, for example Substitute Steve walking in, or the school sign being hung over the gate.
- If the Board's $5M wait after the Job runs over 3 minutes in the playthrough, add a beat or rotating goals while 'Face the Board' is on the card (QuestService.lua:93-107).
- Make the Quests.client 'weakest' guide skip the Hall Monitor, the same way HallService.lua:142 does.
- VexPA finale: spawn Vex at the empty Desk 5 with an angry emote and add a SKIP button (Cutscene.client.lua:1462-1500). Add SKIP to FirstMorning and the Board scene too.
- Add a Grindle wake-up scene when you come up through the grate: him asleep at his desk with snoring audio, jolting awake and getting on his hoverboard. It replaces the 1.6 s pop-in (SewerHeist.lua:273-275).
- Give the Grindle boss a hoverboard ride during the fight and a knock-down defeat (lie down or tumble) instead of idle and fade (QuestGoons.lua:346-358). Give him his own outfit instead of the 'dean' one shared with Dean Maximus (QuestGoons.lua:30, TownNPCService.lua:258).
- Give Hector (k04) and Stan (k09) short entrance shots the first time you talk to them.
- Screenshot the two Rival shots nobody has seen yet: the trophy case and Vex looking at your school (BACKLOG.md:22).
- Match the story: a snoring sound under the office grate (SewerHeist.lua:423) and night lighting for 'Tonight's the night' during the Job.
- Flag for Chapter 2: replace crumpets_crew (Config.lua:641-647), a word-for-word copy of Chapter 1's k_crew.
- Label the sewer and pothole on the town map once k11 is reached (TownMap.client.lua:225-237).
- Kindergarten's version of the real school: a show-and-tell stage and a small playground (ch01.md:46-51).
- Measure fps in the sewer, Grindle's office, the Great Hall and the new Factory office, and read the output log through a full Job.
- Extend tools/econ_sim.py to model Config.Tutorial: step rewards max(min, income x secs) and the free Hall Monitor and Drama Queen.
- Write docs/ROBUX.md so tomas can create the passes and products (every id in Config.lua:1125-1164 is 0, so the live store is empty).

Could stall (from code; check in the playthrough):
- k_map (k09) has not been re-tested since the uncommitted FactoryService.lua change, which adds a laser gate, 2 cameras and a 4th guard around Vex's desk where the map sits (git diff; ch01.md:27-34). Getting caught only throws you out (FactoryService.lua:943-949), so it is not a hard stall, but it has never been played.
- The k07_swap 'weakest' guide (Quests.client.lua:450-459) does not exclude the Hall Monitor, which the Board requires (Config.lua:178). HallService.lua:142 protects it, the guide doesn't. It is unlikely to be the weakest (17/s), but if sold, the Board waits for another Hall Monitor from the bus.
- After the Job, 'Face the Board' needs $5M (Config.lua:178). While it shows, no goals rotate (QuestService.lua:93-107), so any shortfall is a grind with nothing on the card.
- Grind gaps: $25K for the Janitor's Cart at k05 (Config.lua:301) and $150K for row 4 at k07_row4 (Config.lua:255). The Drama Queen gift at k06 eases the second.
- Once awake, the Grindle boss chases you anywhere by CFrame at office-floor height with no collision (QuestGoons.lua:436-446). If you leave the office mid-fight he slides through walls after you: a glitch, not a stall.
- The Job's Take prompt depends on RivalService.desk(5) existing (SewerHeist.lua:92-95). If it is nil, the kid is never seated and the guide points at Desk 5 forever.
- Chapter 1 has never been played by a fresh player by hand (BACKLOG.md:18, 67).
- The Hoverboard, the chapter's earned item, can be missed for good (lost reward, not a stall). Taking the Desk 5 kid does not require Grindle to be down or the board picked up, and neither does escaping. endJob destroys a board left on the floor. A won mission is never offered again. The only other source is the paid Golden Hoverboard pass.

### Chapter 2: The New Building (Elementary)

The chapter's checklist has four requests you can do in any order: hire Mr. Chalk, build the Playground, reach IQ 150, and the mission crumpets_crew (defend). Then Face the Board to reach Middle School, 5 steps in all. Finishing Chapter 1 also opens Downtown and the Mutation Lab at the same moment. It auto-starts story quests S01/S02, which carry the only two non-alien data-driven cutscenes, and unlocks Downtown town quests D01-D03. None of these are on the chapter list. The chapter's only mission is a line-for-line copy of Chapter 1's k_crew.

Length: ~59 min median (econ_sim: 'tier 1 Elementary School 1.64h' to 'tier 2 Middle School 2.62h'). The sim pays mission steps at 1x, not the real 3x (econ_sim.py:396-415 vs Config.lua:736), and assumes own/count steps are done 15 min into the tier (econ_sim.py:116).

To add:
- Play Chapter 2 from a fresh tier-2 save (ChapterService.debugSet(player, 1)) and log each step's time and reward. That is the Possible evidence LOOP.md asks for.
- Give each Config.Chapters step a call (who, where, why) when it becomes the next open request, e.g. a ChapterCalls table pushed as missionTalk from ChapterService.evaluate. Wobblesworth explains Mr. Chalk, the Playground and IQ.
- Replace crumpets_crew (a copy of k_crew, Config.lua:620-647) with a new, harder set piece tied to Chapter 1's ending, e.g. Crumpet's revenge raid for the stolen Vex Prep kid with 4 goons at hp 2 plus a new twist. Add a Lab step (signal labTake/mutantEscaped) so the chapter has 4+ kinds of play.
- Grow the list to 10-14 steps: put S01/S02 on it and implement S03 'Hall of Records' and S04 'A Principal's Promise' (STORY.md:34-35), making at least 2 missions.
- Add an opening cutscene for 'The New Building' (the red-brick school reveal with Wobblesworth), triggered by chapterStart n=1. Add a chapter-unique finale. Add a Lab reveal cutscene at the Areas.client.lua:243 hook.
- Add a SKIP button to the data-driven cutscene player (Cutscene.client.lua:1254) and to the Board scene.
- Give the chapter a finish that pays big (the requests are about 28 s of income each) and a cliffhanger Board beat in place of the waterslide gag (Config.lua:208).
- Add an item earned in the chapter, e.g. the Town Key from S04 (STORY.md:35) or a Lab keycard.
- Give Elementary a visible campus change beyond the clock gable (gym, stage or field, per BACKLOG P3), then screenshot the tier-2 school, the Lab and Downtown.
- Measure fps near the Lab and in Downtown and check the output log at Chapter 2.

Could stall (from code; check in the playthrough):
- The Board review checks only cash, the required kid and (tier 2 only) a story mission. You can promote with the requests undone, so p.chapter.n lags the tier and chapter-gated areas stay shut (Maple Heights needs chapter=2) (BoardService.lua:80-87, Config.lua:1083-1085).
- IQ 150 needs every tier-1 and tier-2 supply (100 + 5 x 10). Nothing tells you which one is missing (Config.lua:325-329, ChapterService.lua:92-98).
- crumpets_crew refuses to start with 0 seated kids, which is exactly the state right after the Board review clears the desks (MissionService.lua:132-137, Config.lua:819).
- Wobblesworth's '!' is hidden while you are on one of Stan's secret jobs (MissionService.lua:73-76).
- The Board to Middle School needs a seated Band Geek (Rare) off the bus or a letter (Config.lua:179).
- A silent dead-end while on one of Stan's secret jobs (chapters 2-4). Wobblesworth still offers the chapter mission: giverTalk checks only MissionService's own active table, and ready() ignores secret jobs. When the player presses START MISSION, MissionService.start returns false at once because onSecret(player) is true. The client ignores the result, so no message appears and nothing starts. The player is stuck until the secret job ends or fails. It bites hardest in Chapter 3, where the chapter card names Stan as host and talking to Stan hands out exactly such a job.
- crumpets_crew can be cancelled on arrival and send you back to the fountain. startDefend counts a kid as seated unless it is away or carried, so kids still walking to their desks ('arriving') pass its check. RaidService.targets keeps only PlotService.earning kids, which excludes arriving ones. If every kid is still arriving when you get within 70 studs of your gate, start_raid returns false and you get 'The goons turned back. Talk to Mr. Wobblesworth again.' This is most likely right after the Board review empties the desks.

### Chapter 3: Lockers and Lies (Middle)

Four requests: build Mascot Lockers, hire Ms. Honeycutt, the mission sugar_run (chase the candy courier from the Factory to the Sugar Shack), bust 2 Snack Smugglers. Then Face the Board to reach High School, 5 steps. Maple Heights opens here, with town quests M01/M02 and enterable furnished houses. There is no story quest and no cutscene apart from the shared Board review, whose beat teases the Sugar Baron.

Length: ~76 min median (econ_sim: 'tier 2 Middle School 2.62h' to 'tier 3 High School 3.88h'), which is 16 min over the 60 min bar.

To add:
- Give the bust step a call and a guide, and send a scripted smuggler when the step opens (sendDealer already takes a 'scripted' flag, PatrolService.lua:424-433).
- Set sugar_run's giver to JanitorStan (MissionService/SecretService already route a Stan-given mission first) so the host hands out his own mission.
- Add a set piece new to Chapter 3 in place of a Chapter 1 chase reskin, e.g. a lockers puzzle or stealth job, or the Sugar Shack itself. Reach 4+ kinds of play.
- Implement S05 'Flyers on Maple Lane' and S06 'Worksheets for Breakfast' (STORY.md:37-38) as chapter steps, with calls. Aim for 10-14 steps and 2 missions.
- Add an opening cutscene (Stan and the lockers), a chapter finale, a Maple Heights reveal (S05_Reveal, TOWN.md:116), and entrances for Mrs. Patel, Grandma Rose and Lil' Timmy.
- Add an item earned in the chapter (a trophy, gear, or a key item such as the Mutagen-stained worksheet from S06).
- Link the chapter to the Chapter 2 ending and carry the Baron hook into Chapter 4.
- Cut the econ time to 60 min or less, or add rewards every 5 min; replace the 29 s-of-income requests with a bigger finish.
- Make the Middle School grow visibly past floor 2 (a cafeteria room, a stage). Screenshot the school and Maple Heights; measure fps there.

Could stall (from code; check in the playthrough):
- 'Bust 2 Snack Smugglers' has no guide or call and depends on random smugglers: every 150-260 s, only with 4+ earning kids, the gate unlocked and a player who moved in the last minute. Busts made before Chapter 3 do not count (PatrolService.lua:428-433, 562-574; ChapterService.lua:251-266).
- sugar_run's lines are spoken as Janitor Stan, the chapter host, but the giver is Wobblesworth. Talking to Stan gives a secret job instead (Config.lua:648-654, SecretService.lua:129-157).
- Chapter/tier desync: you can promote to High School with Chapter 3 open, and Pine Park (chapter=3) stays shut (BoardService.lua:80-87).
- The Board to High School needs a seated Quarterback (Epic) (Config.lua:180).

### Chapter 4: Friday Night Lights (High)

Four requests: build Bleachers, hire Coach Rex, the mission free_the_mascot (carry the School Mascot out of the VexCorp Factory pens), own 1 Legendary kid. Then Face the Board to reach Prep School, 5 steps. Pine Park opens (town quest P01). The school gains a columned portico and a gym wing, but the gym is a solid shell. There is no story quest and no chapter cutscene; the Board beat has Vex bringing the Board a fruit basket.

Length: ~119 min median (econ_sim: 'tier 3 High School 3.88h' to 'tier 4 Prep School 5.86h'), about double the 60 min bar.

To add:
- Build a Chapter 4 set piece that fits 'Friday Night Lights', e.g. a stadium night defence of the trophy case or a Pine Park mutant chase (S09). Make the Factory heist scale with tier (more guards, faster chasers) so the chapter is harder than the last.
- Settle the chapter numbering between STORY.md (Act 3 = Chapters 4-6) and TOWN.md (11-chapter numbering, Act 2 = Chapters 3-4). Then implement that act's quests (S07-S10 or S11-S16) as chapter steps with calls, reaching 10-14 steps and 2 missions.
- Add an opening cutscene, a finale scene of Vex's fruit-basket bribe, S07_TruckCrash for Pine Park, and entrances for Coach Rex, Ranger Rick and Scout Sam.
- Give Hector a role in his own chapter (he hosts but does nothing).
- Make the gym wing enterable, with a court, bleachers and the team, so the school visibly grows at High School.
- Add enterable interiors for the Ranger Station and the Boathouse (both are currently solid boxes).
- Add an earned item: a trophy for the rescued Mascot, gear, or Glowing Vials from S08.
- Bring the chapter from about 119 min down to 45-60: lower Prep School's $100B (Config.lua:181) or add content and rewards; give a finish that pays big.
- Screenshot the High School, the gym wing and Pine Park; measure fps there and check the output log.

Could stall (from code; check in the playthrough):
- The heist is harder carrying: guards chase at 13.5 against your 12, so you must bonk. Not a fail state, but the only difficulty change from Chapter 1 is the line of dialogue (Config.lua:865-867).
- 'Own 1 Legendary' counts seated kids only; the rescued Mascot waits on the bench until enrolled (ChapterService.lua:99-108, FactoryService.lua:983).
- Chapter/tier desync: you can reach Prep School with Chapter 4 open (BoardService.lua:80-87).
- The Board to Prep School needs a seated Valedictorian (Legendary) (Config.lua:181).
- Latent: a quest gated on needs.chapter would show 'Reach Chapter k' using p.chapter.n, one below the UI's chapter number (TownQuestService.lua:57-60 vs Chapters.client.lua:126).

### Chapter 5: Blazers Required (Prep)

Four Principal's Requests in any order, then Face the Board. The requests are three shop purchases (Arched Windows, Dr. Beaker, Laptops) and one mission, Surprise Inspection: a story van raid of 4 goons with 2 hp each, called 'inspectors' by the Board Chair. The Board step needs $1.2T plus a seated Prom King to reach Private Academy. The chapter opens on the shared Board-room cutscene (beat [5], Vex's fruit basket) and a GUI title card, and ends on the same Board scene (beat [6]). No story quest, town quest, area or cutscene of its own is wired to chapter 4.

Length: About 175 min. Basis: tools/econ_sim.py (strong, always-present player, 5 seeds), median Prep School reached at 5.86 h and Private Academy at 8.78 h, a gap of 2.92 h. The LOOP bar is 45-60 min.

To add:
- Possible: play Chapter 5 through in Studio from a fresh tier-5 save (the debug bridge only to set up the save), time each step and log it in docs/chapters/STATUS.md. On a failed story raid, retry at the school gate instead of sending the player back to Wobblesworth.
- Entertaining: add chapter-step calls (a table like Config.StepCalls, pushed from ChapterService when a request becomes current) that say who, where and why for each of the 4 requests. Add a scripted beat at least every 3 min of the planned 45-60.
- Fun: replace the reskinned van raid with a set piece unique to Prep School, for example the inspection as a stealth run through your own 3 floors, dodging an inspector with a vision cone (Guards already supports this). Add 2 more kinds of play so the chapter has 4.
- Will it be successful: retune Chapter 5 to 45-60 min (econ_sim says about 175; lower Tiers[6].cash or raise this chapter's payouts), pay a reward at least every 5 min, make the finale pay big, and end on a cliffhanger that fits the story.
- Cutscenes: add an opening entry (the Board's warning that inspectors are coming) and a finale entry (the inspectors unmasked) to Cutscenes.lua, triggered for p.chapter.n = 4. Add a SKIP button to board() in Cutscene.client.lua.
- Animations: give the inspectors their own look (B.Clipboard already exists in StudentProps) and a 'writing you up' idle, then measure them mid-motion.
- Quests: grow the chapter to 10-14 steps with at least 2 missions. Build STORY.md Act 3 S11-S13 in Quests.lua with needs = { chapter = 4 }, and add the chapter's town quests.
- New characters: add 2 named characters (for example a Head Inspector villain and a Prep ally), each with a model, portrait, voice lines and an introductory call.
- Items: award an item on the mission win (a gadget, a key item or a trophy).
- Areas unlocked: make the tier-5 library wing a walk-in, furnished interior (it is a solid LibraryBody block now), or open a town area at chapter 4.
- Story: rewrite BoardBeats[6] (the Factory has existed since the First Morning), and settle STORY.md, TOWN.md and Config.Areas on when and how Vex Prep 'opens', given that Chapter 1 already goes inside.
- The school: add a walk-in space at Prep (library, gym or a stage).
- Look: take and read screenshots of the tier-5 campus, the raid and the Board beats; check the screen for unfinished text.
- Performance: measure fps and read the output log during the 4-goon story raid on a 3-floor school.

Could stall (from code; check in the playthrough):
- Surprise Inspection: 4 goons with 2 hp each target the most valuable kids across 3 floors, and one escape fails the mission. The retry restarts at Wobblesworth's fountain (RaidService.lua:630-649, MissionService.lua:159-161, 117).
- The defend mission will not start while an ordinary raid is on (MissionService.lua:132-137), and those raids come every 180-300 s (Config.lua:839). Starting it can take several tries.
- The Board needs a seated Prom King (Legendary) plus $1.2T (Config.lua:182). econ_sim puts it about 175 min in, so the chapter stalls on grind, not on code.
- No Studio playthrough exists for this chapter (docs/chapters/ is absent).
- Surprise Inspection can fail with no goon escaping. If the player sells or swaps a kid a goon is going for (the To-Do teaches selling as the core loop), lift() sees e ~= g.e and sends that goon back to the van empty-handed. removeGoon then ends the raid without a KO, and onEnd fails the mission because ko < count. The fail message gives no reason.

### Chapter 6: Vex Makes an Offer (Private Academy)

Dr. Vex hosts the chapter. The four requests are: build the Fountain, hire Madame Verse, the Vex's Blueprints mission (the Factory desk-item heist), and steal one kid out of Vex Prep (a counted request on rivalEscaped). Face the Board then needs $100T plus a seated Kid Genius. Vex Prep's front gate opens this chapter (Config.Areas needs chapter 5), though the player has been inside since Chapter 1. There is no cutscene or story quest of its own, and no offer is ever staged.

Length: About 709 min. Basis: tools/econ_sim.py medians, Private Academy reached at 8.78 h and Community College at 20.59 h (11.81 h). The LOOP bar is 45-60 min.

To add:
- Possible: play the chapter through in Studio from a fresh tier-6 save, including a caught-and-retry run at Vex Prep, and log the times in STATUS.md.
- Entertaining: add a call for each step (who, where, why), including one when Vex Prep's gate opens that sends the player there; add a beat at least every 3 min.
- Fun: add a set piece new to this chapter, for example Vex's offer as a playable scene or a Headmaster Grindle chase through Vex Prep, instead of the reused k_map desk heist. Reach 4 kinds of play and scale guard difficulty by tier.
- Will it be successful: retune the chapter to 45-60 min (econ_sim says about 709), swap the tier-5 Fountain for a tier-6 build, pay a reward every 5 min, and add a big finale payout.
- Cutscenes: add Cutscenes.lua entries for 'The Offer' (Vex at your gate with a briefcase) and a finale, plus a Vex Prep gate reveal hooked where Areas.client now shows only a toast; add SKIP to the Board scene.
- Animations: whatever new characters and boss are added need idle, walk, tell, attack and defeat animations, measured.
- Quests: grow to 10-14 steps with 2 missions and calls. Build Act 3 S12-S14 (Poached, The Sugar Baron, Town Hall Vote) and the planned Vex Prep town quests.
- New characters: introduce 2 named characters with a model, portrait and lines, for example a Vex Prep Head Prefect (villain) and a Vex Prep kid who wants out (ally).
- Items: award a key item or gadget, for example keep Vex's Blueprints as a Scrapbook item, or a Vex Prep blazer disguise.
- Story: stage the offer the chapter is named after; fix BoardBeats[6]; rewrite S11 so Vex Prep's 'opening' fits Chapter 1.
- The school: add a walk-in space at the Academy tier.
- Look: capture and read the missing Rival shots and a tier-6 campus pass.
- Performance: measure fps and read the output log during a full Vex Prep alarm plus the revenge raid.

Could stall (from code; check in the playthrough):
- Vex Prep escape: the bell alerts all 3 monitors (RivalService.lua:640), who chase at 13 while the player carries at 11 (Config.lua:1209, RivalService.lua:775). Solo, it depends on landing Ruler stuns, and getting caught loses the kid (RivalService.lua:604-617).
- The Fountain is a tier-5 build (Config.lua:397), so it usually completes on entry (ChapterService.lua:235-237) and the chapter shrinks to 3 requests plus the Board.
- The Board needs a seated Kid Genius (Mythic) plus $100T (Config.lua:183). econ_sim puts the chapter at about 709 min.
- No Studio playthrough exists.
- The Vex Prep steal step has no guide. guideOf returns nil for kind 'count', so there is no GO button. The post-tutorial arrow only ever points at Stan (secret job ready) or Wobblesworth (mission ready), never at Vex Prep. With the gate opening announced only by a toast, nothing leads the player to the step.

### Chapter 7: Campus Life (Community College)

Lunch Lady Loretta hosts. The requests are the Founder's Statue, Professor Tweed, Smartboards, and The Secret Recipe, a chase where Crumpet runs from the Hub to the bus stop and must be bonked 4 times. Face the Board then needs $190T plus a seated New Kid. No area opens, the school's structure does not change from tier 6 (only its colours), and no Act 3 story quest exists. The chapter ends on Board beat [8], Stan's 'the statue blinked'.

Length: About 578 min. Basis: tools/econ_sim.py medians, Community College reached at 20.59 h and State University at 30.23 h (9.64 h). The LOOP bar is 45-60 min.

To add:
- Possible: play the chapter through in Studio from a fresh tier-7 save; set giver = 'Loretta' on recipe_chase and give Loretta a talk prompt through MissionService.
- Entertaining: add a call for each step and a beat at least every 3 min.
- Fun: replace the k_tiara reskin with a set piece new to the chapter (for example a cafeteria food fight, or a chase through the college on a new route), and reach 4 kinds of play.
- Will it be successful: retune to 45-60 min (econ_sim says about 578), with a reward every 5 min and a big finale.
- Cutscenes: add an opening (Crumpet steals the recipe from Loretta's cart) and a finale to Cutscenes.lua, triggered for p.chapter.n = 6; add SKIP to the Board scene.
- Animations: animate and measure whatever new characters and set piece are added.
- Quests: grow to 10-14 steps with 2 missions and calls; build Act 3 S15 (Crumpet's Letter) and S16 (Defend the School) with needs chapter 6, plus town quests.
- New characters: add 2 named story characters with a model, portrait and lines, introduced by a call.
- Items: award an item for the chapter (for example Loretta's recipe card as a trophy, or a lunch-tray gadget).
- Areas unlocked: open or transform an area at chapter 6, for example a walk-in cafeteria or college quad (BACKLOG P3), and give GROWTH[7] its own structural growth.
- Story: tie the recipe theft to Vex's plan and close Act 3 (S15, S16) before Act 4 opens Industrial.
- The school: make the College visibly bigger than the Academy (a campus building or a walk-in space).
- Look: take and read a screenshot pass at tier 7.
- Performance: measure fps and read the output log at tier 7.

Could stall (from code; check in the playthrough):
- Giver mismatch: The Secret Recipe's lines are Loretta's but the mission is taken from Wobblesworth (Config.lua:676-682 has no giver field; MissionService.lua:79). The player may look for Loretta.
- The Board needs a seated New Kid (Mythic) plus $190T (Config.lua:184). econ_sim puts the chapter at about 578 min.
- No Studio playthrough exists.

### Chapter 8: Iron and Glass (State University)

Janitor Stan hosts. The requests are Stained-Glass Windows, Night Raid (a defend against 5 goons with 2 hp each), Dean Maximus and VR Headsets. Face the Board then needs $600T plus a seated Tiny Professor to reach Ivy League. VexCorp Industrial opens this chapter (needs chapter 7): the Tower lobby, two warehouses and the yard. The 6 built HQ floors cannot be entered because the Visitor Badge is granted only by story quest S18, which does not exist, or by a debug command. None of the Act 4 story quests (S17-S24) exist, and the closing Board beat reveals the Sugar Baron one chapter early.

Length: About 554 min. Basis: tools/econ_sim.py medians, State University reached at 30.23 h and Ivy League at 39.46 h (9.23 h). The LOOP bar is 45-60 min.

To add:
- Possible: build S17 (checkpoint, Gary, a burger from RosaCook, the Visitor Badge) and S18 (ROBO-7, the staff elevator) in Quests.lua with needs = { chapter = 7 }, so HQService.hasBadge becomes true in play. Then play the chapter through in Studio from a fresh tier-8 save.
- Entertaining: add a call for each step, and a call when Industrial opens that sends the player to the checkpoint; add a beat at least every 3 min.
- Fun: make HQ floors 2-3 (S19 Cubicle Farm, S20 Laser Vault, which fire hqFloor 2 and 3) this chapter's missions in place of the reskinned Night Raid, giving stealth, puzzle and chase for 4 kinds of play.
- Will it be successful: retune to 45-60 min (econ_sim says about 554), with a reward every 5 min and a big finale. Move the Sugar Baron reveal out of BoardBeats[9] and replace it with a cliffhanger into Chapter 9.
- Cutscenes: add an Industrial reveal cutscene and S18_StaffElevator (STORY.md) to Cutscenes.lua, triggered at p.chapter.n = 7; add SKIP to the Board scene.
- Animations: give Gary, Ellie, ROBO-7 and Brick walks and emotes in their story moments, and measure them; make the Crumpet boss reachable.
- Quests: grow to 10-14 steps with 2 or more missions (S17-S20) and calls; add the planned Industrial town quests.
- New characters: introduce Gary, Ellie, ROBO-7 and Chief Brick with a call or cutscene before they act, and give them story jobs through S17-S20.
- Items: grant the VexCorp Visitor Badge as a key item (it sets own.hq.badge) and show it in the inventory.
- Areas unlocked: wire the HQ floors into play through the badge quest, and replace the toast with a reveal.
- Story: add Act 4's opening; move Kevin's reveal after unmask_baron; resolve the Ivy League Board needing the Tiny Professor while the story has him captive (change Tiers[9].needs or move his rescue earlier); make Night Raid happen at night (set Lighting.ClockTime during the mission) or rename it.
- The school: add a walk-in space at the University tier.
- Look: take and read screenshots of Industrial, the lobby and the warehouses; remove or explain the dead-end staff elevator until the badge exists.
- Performance: measure fps in Industrial and on each HQ floor, read the output log, and stop the laser and acid Heartbeat checks when nobody is on floors 3 or 5.

Could stall (from code; check in the playthrough):
- HQ floors 2-7 cannot be reached in normal play: the only badge sources are story quest S18 (absent from Quests.lua) and the debug hqBadge (HQService.lua:43-49, Main.server.lua:426-427).
- Night Raid: 5 goons with 2 hp each target the most valuable kids on 3 floors. One escape fails it, and the retry restarts at Wobblesworth (MissionService.lua:159-161, RaidService.lua:630-649).
- The Board needs a seated Tiny Professor (Prodigy) plus $600T (Config.lua:185). econ_sim puts the chapter at about 554 min.
- No Studio playthrough exists.
- Night Raid has the same silent-fail path. Selling or swapping a kid a goon is going for sends him to the van empty-handed, the raid ends with ko < count, and the mission is failed with no explanation.
- Night Raid is voiced by Janitor Stan but handed out by Wobblesworth (no giver field). A player who goes to Stan triggers SecretService.talk: giverTalk(player, 'JanitorStan') returns false for a Wobblesworth mission, so Stan offers an unrelated secret job, or says 'Lie low' while one is cooling down. This is the same mismatch the auditor flagged for Loretta in Chapter 7, missed here.

### Chapter 9: Old Money (Ivy League)

Four Principal's Requests (build Solar Panels, stock Robot Tutors, mission 'Unmask the Sugar Baron', own 3 Mythic kids at once), then Face the Board for Wizard School ($6.6Qa plus Pop Star Kid seated) (Config.lua:562-569, 186). The only set piece is a chase on the same MissionService chase engine used since Chapter 1: the Baron, 6 hits. No town or story quest, data cutscene or area unlock is wired to this chapter. econ_sim puts it at about 20 hours.

Length: ~1,210 min (20.2 h). Basis: python tools/econ_sim.py (5 seeds, 150 h cap) median 'tier 8 Ivy League' 39.46 h to 'tier 9 Wizard School' 59.62 h. The LOOP bar is 45-60 min.

To add:
- Move Kevin's confession out of BoardBeats[9] (Config.lua:214) and give that beat a line that starts the Baron hunt. Play the reveal after the chase.
- Add an Ivy League opening cutscene (a Cutscenes.lua entry fired on chapterStart n=8) and an 'Unmasking' cutscene after unmask_baron: cake hat off, Kevin revealed, the shack sign swapping. Add a SKIP button to board() (Cutscene.client.lua:219-301).
- Expand Config.Chapters[8] to 10-14 steps and give each a call (ChapterService has no per-step calls; add e.g. Config.ChapterCalls[n][i] pushed as missionTalk on step start).
- Add a second mission that is a new set piece, not another chase reskin. Make a failed chase resume from the waypoint where you lost him.
- Build STORY.md Act 4 (S17-S24) as quests gated to chapters 7-9, so the Visitor Badge is earnable and HQ floors 2-7 become playable (HQService.lua:43-49).
- Add 2 new named characters with a model, portrait and lines, introduced by a call (for example an Ivy League dean, or Kevin as a townsperson with a quest).
- Add an item earned by playing (for example the Baron's cake hat as a trophy dropped on the unmask) and a tier-9 teacher (none exists at tier 9: Config.lua:362-363).
- Open or transform an area at chapter 8 (for example Kevin's Snack Shack interior, or the HQ).
- Give Ivy League its own tower or campus growth: it shares the 'bell' tower with tier 8 (Config.lua:289-290).
- Retune pacing to 45-60 min with a reward every 5 min (econ_sim: 20.2 h now).
- Explain why the Tiny Professor, required to enter Ivy (Config.lua:185), is Vex's captive next chapter.
- Take screenshots and an fps/log measurement at this chapter.

Could stall (from code; check in the playthrough):
- The Board promotion to Wizard School needs one specific Prodigy, PopStarKid, seated (Config.lua:186; BoardService.lua:43-53). It only comes from random buses and letters, with no guaranteed source.
- unmask_baron: the Baron runs at 20.3 and dashes at 29.0 for 0.9 s against your walk of 22, and takes 6 hits (Config.lua:690, 734). A miss restarts the whole route from its start (MissionService.lua:254, 278-285). Not played.
- The mission's '!' sits over Mr. Wobblesworth (MissionService.lua:79) while its lines are Janitor Stan's (Config.lua:691-694), so players may go looking for Stan.
- The build, supply and own steps complete from state (ChapterService.lua:235-238). No signal-based stall was found.
- Soft stall, and the same in Chapters 10, 11 and 12. While one of Janitor Stan's secret jobs is active, the chapter mission cannot start and Mr. Wobblesworth shows no '!'. Three of the four secret jobs (hack, sample, snoop) have no fail state and no way to abandon them. A player who took one must finish it or rejoin before the chapter mission can start.

### Chapter 10: The Bell Tolls (Wizard School)

Four requests (build Bell Tower, hire Archmage Quill, mission 'The Vault', own a Prodigy), then Face the Board for Space Academy ($17Qa plus Child CEO) (Config.lua:570-577, 187). 'The Vault' is the same Factory pen heist as Chapter 4's Free the Mascot, this time for the Tiny Professor. The street gains the Homework Machine under construction on the Factory roof. econ_sim: about 17 hours.

Length: ~1,025 min (17.1 h). Basis: econ_sim (5 seeds) median 'tier 9 Wizard School' 59.62 h to 'tier 10 Space Academy' 76.71 h. The bar is 45-60 min.

To add:
- Replace 'The Vault' with a real vault set piece, harder than Chapter 4's pen heist (new layout, locks or lasers, more guards). The Factory has 4 guards at every tier (FactoryService.lua:1385).
- Add an opening cutscene with Archmage Quill's entrance, and a vault payoff cutscene. Add a SKIP button to the Board scene.
- Give Archmage Quill and the Tiny Professor spoken lines, a call introducing each, and at least one more new named character.
- Expand to 10-14 steps, each with a call, with at least 2 missions and wizard-themed town quests.
- Add an item earned by playing (for example a wand gear with a use animation, or a key item from the vault).
- Open a walkable area (for example the Machine construction site on the Factory roof) and animate the MachineBuild crane.
- Fix the Tiny Professor contradictions: required seated to enter Ivy (Config.lua:185), then rescued here, then still in the Lair pod with 'BRAIN LINK 87%' (TownIndustrial.lua:315, 357-362).
- Keep a campus feature at Wizard School instead of dropping the ivy (SchoolBuilder.lua:1526), or add a new one.
- Retune pacing (17.1 h now) to 45-60 min with a reward every 5 min.
- Take screenshots and an fps/log measurement.

Could stall (from code; check in the playthrough):
- The Board promotion to Space Academy needs one specific Prodigy, ChildCEO, seated (Config.lua:187), with no guaranteed source.
- If the Waiting Bench is full, the rescued Tiny Professor goes to pendingBench (FactoryService.lua:986-989), which is only drained on the next join (LetterService.lua:303-316). 'Own a Prodigy' then waits unless you get another Prodigy.
- A heist has no fail state (MissionService.lua:181), so a player who keeps getting caught loops with no hint. It cannot hard-stall.

### Chapter 11: Countdown (Space Academy)

Four requests (hire Commander Nova, stock Quantum PCs, mission 'The Machine Wakes', own 2 Prodigy), then Face the Board for Multiverse University ($120Qa plus any Secret kid) (Config.lua:578-585, 188). The mission is a 6-goon, hp-3 story raid on your school. The Top Secret Lair opens at this chapter as a decorated but empty cavern (Config.lua:1095-1097). The Board promotion at the end plays the Graduation Day finale. econ_sim: about 43.6 hours.

Length: ~2,614 min (43.6 h). Basis: econ_sim (5 seeds) median 'tier 10 Space Academy' 76.71 h to 'tier 11 Multiverse University' 120.28 h. The bar is 45-60 min.

To add:
- Build Act 5 quests S25-S28 in the Lair: ride LairElevator, free kids from the cages (put kids in them; TownIndustrial.lua:342-356), the Tiny Professor's pod, goons at LairCore. Add cutscenes S25_TheLair and S27_Professor to Cutscenes.lua.
- Replace machine_wakes with a Machine set piece in the Lair: arm the laser grid (TownIndustrial.lua:363) and add a boss or Machine fight with a tell, attack and defeat.
- Put characters in the Lair (Vex, ROBO-7, Engineer Ellie). Give Commander Nova an introductory call and lines.
- Add the Lair to the town map (TownMap.client.lua:207) and a reveal cutscene when it opens (Areas.client.lua:243).
- Make the HQ reachable (grant the Visitor Badge through S17/S18), so the Executive Keycard is the story reason the Lair opens (HQService.lua:43-49, 832).
- Put actors, SKIP and a Machine-firing shot into the Graduation Day finale (Cutscene.client.lua:642-707).
- Fix the UnlockLair copy 'Face Dr. Vex right away' (Config.lua:1159).
- Add a tier-11 build and an item earned by playing. Keep or replace the dome that Space Academy loses (SchoolBuilder.lua:1527).
- Expand to 10-14 steps with a call each and at least 2 missions.
- Retune pacing: 43.6 h now.
- Measure fps near the Machine stage and in the Lair.

Could stall (from code; check in the playthrough):
- machine_wakes: 6 story goons with hp 3 spawn 0.6 s apart (RaidService.lua:741-742) and ignore the gate lock (RaidService.lua:499). A single goon reaching the van with a kid fails the mission (MissionService.lua:159-162). Solo feasibility has not been played.
- startDefend refuses to start with 0 seated kids (MissionService.lua:132-137), and the Board review that opens the chapter empties your desks (BoardService.lua:105).
- The Board promotion to Multiverse needs any Secret seated (Config.lua:188): Principal's Pick is 5% every 2 h (Config.lua:1193), and the Lab mutant band at tier 11 is Prodigy or Secret (Config.lua:963).
- The Lair opens with no objective, so a player may look for the 'Face Dr. Vex' promised by the store (Config.lua:1159) and find nothing.
- machine_wakes has no giver field, so the '!' and the GO button point at Mr. Wobblesworth, but every line is spoken by Otis. The chapter card's host is also Otis, so players may go looking for Otis. The same mismatch exists in Chapter 12: final_stand's lines are Dr. Vex's but it is handed out by Wobblesworth. This is the same issue the audit flagged for Chapter 9.

### Chapter 12: Every School at Once (Multiverse University)

Four requests (hire the Omniteacher, stock Thinking Caps, mission 'The Final Stand', own a Secret), then 'Face the Board: first Prestige star' ($360Qa plus a Secret seated) (Config.lua:586-593; ChapterService.lua:65, 121-124; BoardService.lua:25-35). The Graduation Day finale, in which Vex is beaten and de-aged, plays when you REACH Multiverse (BoardService.lua:122-125), so it opens this chapter rather than ending it, and Vex's 8-goon Final Stand comes after her defeat. Prestige (GOLD, DIAMOND, ALIEN) lives in a separate panel and is not a chapter step. The alien arc X01-X06 needs prestige 1. econ_sim does not model the star or Prestige.

Length: Not modelled: econ_sim has no star or prestige logic (no 'star' or 'prestige' in tools/econ_sim.py). Rough estimate only, not simulated: the star costs $360Qa (3 x Multiverse's $120Qa, which took 43.6 h to save). With income@10 = 1.37e12/s x 50/35 tier multiplier, about 2e12/s, that is about 50 h.

To add:
- Move Graduation Day from the Multiverse promotion (BoardService.lua:122-125) to after Chapter 12's final mission, so Vex is beaten last. Rewrite final_stand's lines (Config.lua:713-717) to match.
- Build S29 'Face Dr. Vex' (a showdown at LairThrone as a boss with a tell, attack and defeat) and S30 'Recess Forever' (the parade), with cutscenes S29_Showdown and S30_Parade in Cutscenes.lua.
- End the chapter on the Prestige panel's finish (GOLD), or make the last step 'Prestige OR a star'. Make Chapter 12 survive a Prestige: PrestigeService.lua:74-78 resets stars without touching p.chapter.
- Change the street state for chapter 12: the Machine should not still be awake with gloom after Vex is beaten (Street.client.lua:58, 90; StreetService.lua:10).
- Give the Omniteacher lines and an introduction, give Tiny Vex a proper entrance and a role in the chapter, and replace host 'Everyone' (Config.lua:586) with a speaker who has a portrait.
- Add a second mission that is a new set piece, 10-14 steps with a call each, and a hook into the alien arc (X01 needs prestige 1, Quests.lua:190).
- Add a tier-12 build and an item earned by playing (for example a Graduation trophy).
- Add SKIP to the Board, finale and Prestige cutscenes, and actors to the finale.
- Model the star and Prestige in tools/econ_sim.py and retune pacing.
- Measure fps during the finale, the 8-goon raid and the prestige rebuild.

Could stall (from code; check in the playthrough):
- Prestige vs the chapter's last step: GOLD costs $240Qa (Config.lua:245), less than the $360Qa star, and resets tier to 1 and stars to 0 without touching p.chapter (PrestigeService.lua:74-78). Chapter 12's Board step needs stars >= 1 (ChapterService.lua:122), so a player who prestiges first must climb all 12 tiers again to finish Chapter 12.
- final_stand: 8 story goons with hp 3 spawn 0.6 s apart (RaidService.lua:741-742) and ignore the lock (RaidService.lua:499). One escape with a kid fails the mission (MissionService.lua:159-162). The hardest defend in the game, not played solo.
- If the bench is full, Tiny Vex waits in pendingBench (BoardService.lua:140-144), which is only drained on the next join (LetterService.lua:303-316). Without another Secret, 'own a Secret' then waits for a rejoin.
- Two different things are both called 'Prestige': the Board 'Prestige star' the chapter asks for (ChapterService.lua:65) and the Prestige panel's finish (Menus.client.lua:632-670). A player can easily do the wrong one.
- Extends the audit's Prestige risk. Prestiging before the star also re-locks any Chapter 12 purchase not yet made. Omniteacher and Thinking Caps are tier-12 items, CampusService refuses items above your tier, and Prestige sets tier to 1. The hire and supply steps then wait for the full re-climb as well, not only the Board star.

