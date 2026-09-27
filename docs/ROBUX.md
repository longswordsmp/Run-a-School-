# Robux: what to create on the Creator Dashboard

Everything the game sells, generated from `Config.Passes` and `Config.Products` (src/Shared/Config.lua)
by tools/robux_doc.py. Nothing is on sale until it has an id: while an id is 0, the store hides it in a
live game (in Studio it works as a free test purchase).

**How:** Creator Dashboard, then Run A School!, then Monetization.
1. Create each **pass** under Passes, and each **product** under Developer Products, with the name,
   price and description below.
2. Copy its id into the line with the same `key` in Config.lua (`id = 0` becomes `id = <the number>`).
3. Tell me when that's done and I'll check every id in Studio.

## Game passes (one-time, yours forever)

| key | Name | R$ | Description |
|---|---|---|---|
| StarterPack | Starter Pack | 29 | $25K, a Rare kid on your bench and 3 of every gadget, once |
| VIP | VIP Principal | 149 | x2 tuition forever, VIP tag |
| SuperSpeed | Super Sneakers | 49 | Run 25% faster, forever |
| GoldenBoard | Golden Hoverboard | 79 | Ride a golden board: 30% faster, with a sparkle trail (and get one right away) |
| DiamondBoard | Diamond Hoverboard | 149 | The fastest board there is: 3x a regular hoverboard, crystal clear, with a diamond sparkle trail (and get one right away) |
| Luck | 2x Luck | 99 | x2 luck on the buses you stand near |
| AutoCollect | Auto Collect | 79 | The Janitor's Cart at max level from the start |
| LongLock | Long Lock | 39 | +30s every time you lock your gate |
| TeleportHome | Teleport Home | 29 | A button that takes you home (not while carrying) |
| OfflinePlus | Offline Tuition+ | 49 | Earn 50% for up to 12h while offline (was 25% for 2h) |

## Developer products (can be bought again)

| key | Name | R$ | Description |
|---|---|---|---|
| MoneyBoostA | Money Boost | 9 | x2 to x5 tuition |
| MoneyBoostB | Money Boost | 19 | x6 to x10 tuition |
| MoneyBoostC | Money Boost | 39 | x11 to x25 tuition |
| MoneyBoostD | Money Boost | 79 | x26 to x50 tuition |
| MoneyBoostE | Money Boost | 149 | x51 to x100 tuition |
| Cash10m | Tuition Pack | 15 | 10 minutes of your tuition |
| Cash1h | Tuition Bag | 39 | 1 hour of your tuition |
| Cash4h | Tuition Vault | 99 | 4 hours of your tuition |
| LuckyBus | Lucky Bus | 59 | A bus for the whole server with YOUR name on it. Legendary 70% / Mythic 24% / Prodigy 5% / Secret 1% |
| ServerLuck | Server Luck x2 | 29 | x2 luck for everyone for 15 minutes |
| ExpressRare | Express Rare Letter | 9 | Your Rare letter, ready now (you still pay the kid's price) |
| ExpressEpic | Express Epic Letter | 19 | Your Epic letter, ready now (you still pay the kid's price) |
| LockRefresh | Instant Lock Refresh | 9 | Your gate can lock again right now |
| UnlockDowntown | Open Downtown Now | 9 | Explore Downtown right away |
| UnlockLab | Open the Mutation Lab Now | 25 | Steal mutant kids right away |
| UnlockMapleHeights | Open Maple Heights Now | 15 | Meet the neighbours right away |
| UnlockPinePark | Open Pine Park Now | 19 | Explore the park right away |
| UnlockVexPrep | Open Vex Prep Now | 29 | Raid the rival school right away |
| UnlockIndustrial | Open VexCorp Industrial Now | 39 | Sneak into VexCorp right away |
| UnlockLair | Open the Lair Now | 49 | Face Dr. Vex right away |

## The Money Boost ladder

One button in the store. Every purchase adds +1x to all your tuition, forever, up to x100. The price
depends on the level you're buying, so it is five products (MoneyBoostA-E above) and the store picks
the right one.

| Levels | Product | R$ each | Purchases | R$ for the band |
|---|---|---|---|---|
| x2 to x5 | MoneyBoostA | 9 | 4 | 36 |
| x6 to x10 | MoneyBoostB | 19 | 5 | 95 |
| x11 to x25 | MoneyBoostC | 39 | 15 | 585 |
| x26 to x50 | MoneyBoostD | 79 | 25 | 1,975 |
| x51 to x100 | MoneyBoostE | 149 | 50 | 7,450 |

The whole ladder, x1 to x100: **10,141 R$**.

Nothing is ever prompted automatically, and the Lucky Bus shows its odds before you buy.
