"""Economy simulator for Run a School.

Reads prices, incomes, rarity and grade weights, School Board tiers, desk rows and special buses
straight from src/Shared/Config.lua, then plays a strong, always-present player second by second:
stands at the carpet, buys the best student they can afford, sells the worst when the school is
full, buys desk rows and luck, and goes to the School Board as soon as the requirements are met.

Usage:  python tools/econ_sim.py [hours=150] [seeds=5]
Prints the median time of every milestone across seeds.
"""
import math
import pathlib
import random
import re
import statistics
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CFG = (ROOT / "src" / "Shared" / "Config.lua").read_text()

# ---------------------------------------------------------------- config parsing
RARITIES = []
for m in re.finditer(r'\{ id = "(\w+)", color = rgb\([^)]*\), weight = ([\d.]+)', CFG):
    RARITIES.append((m.group(1), float(m.group(2))))
RARITY_ORDER = {r: i + 1 for i, (r, _) in enumerate(RARITIES)}

STUDENTS = []
for m in re.finditer(r'S\("(\w+)", "([^"]+)", "(\w+)", ([\d.e]+), ([\d.e]+),', CFG):
    STUDENTS.append({"id": m.group(1), "rarity": m.group(3), "price": float(m.group(4)), "income": float(m.group(5))})
BY_RARITY = {}
for s in STUDENTS:
    BY_RARITY.setdefault(s["rarity"], []).append(s)
BY_ID = {s["id"]: s for s in STUDENTS}

GRADES = []
for m in re.finditer(r'\{ id = "([^"]+)", mult = ([\d.]+), weight = ([\d.]+)', CFG):
    if float(m.group(3)) > 0:
        GRADES.append((m.group(1), float(m.group(2)), float(m.group(3))))

TIERS = []
for m in re.finditer(r'\{ name = "([^"]+)", cash = ([\d.e]+), needs = (nil|"\w+"), mult = ([\d.]+), floors = (\d+)', CFG):
    TIERS.append({"name": m.group(1), "cash": float(m.group(2)), "needs": None if m.group(3) == "nil" else m.group(3).strip('"'),
                  "mult": float(m.group(4)), "floors": int(m.group(5))})

rows_block = re.search(r"Config\.DeskRows = \{(.*?)\n\}", CFG, re.S).group(1)
DESK_ROWS = [[float(x) for x in re.findall(r"[\d.e]+", line)] for line in rows_block.strip().splitlines() if "{" in line]
DESKS_PER_ROW = 4

def num(pattern, default):
    m = re.search(pattern, CFG)
    return float(m.group(1)) if m else default

SPAWN = num(r"Config\.SpawnInterval = ([\d.]+)", 2.2)
START_CASH = num(r"Config\.StartCash = ([\d.]+)", 100)
SELL = num(r"Config\.SellFraction = ([\d.]+)", 0.5)
LATE_EVERY = num(r"Config\.LateBus = \{ every = (\d+)", 300)
LATE_COUNT = int(num(r"Config\.LateBus = \{ every = \d+, count = (\d+)", 6))
TRIP_EVERY = num(r"Config\.FieldTrip = \{ every = (\d+)", 1800)
TRIP_COUNT = int(num(r"Config\.FieldTrip = \{ every = \d+, count = (\d+)", 8))
trip_w = re.search(r"Config\.FieldTrip = .*?weights = \{(.*?)\}", CFG).group(1)
TRIP_WEIGHTS = [(k, float(v)) for k, v in re.findall(r"(\w+) = ([\d.]+)", trip_w)]
HONOR_EVERY = num(r"Config\.HonorBus = \{ every = (\d+)", 900)
HONOR_OFFSET = num(r"Config\.HonorBus = \{ every = \d+, offset = (\d+)", 450)
HONOR_COUNT = int(num(r"Config\.HonorBus = \{ every = \d+, offset = \d+, count = (\d+)", 5))
hb = re.search(r"Config\.HonorBus = .*?first = \{(.*?)\}, weights = \{(.*?)\}", CFG)
HONOR_FIRST = [(k, float(v)) for k, v in re.findall(r"(\w+) = ([\d.]+)", hb.group(1))]
HONOR_WEIGHTS = [(k, float(v)) for k, v in re.findall(r"(\w+) = ([\d.]+)", hb.group(2))]
WALK = 50.0  # seconds a student spends on the carpet

# Supplies (School IQ), Teachers (per floor) and School Builder items (Reputation), all bought once
# and kept on review. A rational player buys one when it pays for itself within PAYBACK seconds.
SUPPLIES = [{"id": m.group(1), "gain": float(m.group(2)), "tier": int(m.group(3)), "price": float(m.group(4))}
            for m in re.finditer(r'\{ id = "(\w+)", name = "[^"]+", icon = "[^"]*", iq = ([\d.]+), tier = (\d+), price = ([\d.e]+)', CFG)]
TEACHERS = [{"id": m.group(1), "mult": float(m.group(2)), "tier": int(m.group(3)), "price": float(m.group(4))}
            for m in re.finditer(r'\{ id = "(\w+)", name = "[^"]+", title = "[^"]+", mult = ([\d.]+), tier = (\d+), price = ([\d.e]+)', CFG)]
BUILDS = [{"id": m.group(1), "gain": float(m.group(2)), "tier": int(m.group(3)), "price": float(m.group(4))}
          for m in re.finditer(r'\{ id = "(\w+)", name = "[^"]+", icon = "[^"]*", rep = ([\d.]+), tier = (\d+), price = ([\d.e]+)', CFG)]
PAYBACK = 3600.0

# luck upgrade (Recruitment Office): +2 % per level, 10 levels
LUCK_COSTS = [10e3 * 4 ** i for i in range(10)]
LUCK_STEP = 0.02


def weighted(rng, pairs):
    total = sum(w for _, w in pairs)
    r = rng.random() * total
    for k, w in pairs:
        r -= w
        if r <= 0:
            return k
    return pairs[-1][0]


def roll(rng, luck, weights=None):
    base = weights or RARITIES
    pairs = [(r, w * (luck if RARITY_ORDER[r] >= 3 else 1)) for r, w in base if w > 0]
    rarity = weighted(rng, pairs)
    s = rng.choice(BY_RARITY[rarity])
    g = weighted(rng, [(m, w) for _, m, w in GRADES])
    return s, g


def simulate(hours, seed, cash_override=None, stop_tier=None):
    rng = random.Random(seed)
    tier_cash = [t["cash"] for t in TIERS]
    if cash_override:
        for i, c in cash_override.items():
            tier_cash[i] = c
    t = 0.0
    tier = 0
    cash = START_CASH
    seated = []  # (value_per_sec_before_mult, student, grade_mult)
    rows_owned = [2, 0, 0]  # floor 1 starts with 2 rows
    luck_level = 0
    iq = 100.0
    rep = 0.0
    teacher = [1.0, 1.0, 1.0]  # mult per floor
    owned_items = set()
    hall = []  # (expires, student, grade)
    events = {}
    next_spawn = 0.0
    next_late = LATE_EVERY
    next_trip = TRIP_EVERY
    next_honor = HONOR_OFFSET

    def desks():
        floors = TIERS[tier]["floors"]
        return sum(rows_owned[f] for f in range(floors)) * DESKS_PER_ROW

    def teacher_avg():
        floors = TIERS[tier]["floors"]
        d = [rows_owned[f] * DESKS_PER_ROW for f in range(floors)]
        tot = sum(d)
        return sum(d[f] * teacher[f] for f in range(floors)) / tot if tot else 1.0

    def income():
        return sum(v for v, _, _ in seated) * TIERS[tier]["mult"] * teacher_avg() * (iq / 100) * (1 + rep / 100)

    def mark(key):
        if key not in events:
            events[key] = t

    end = hours * 3600
    step = 3.0  # decisions every 3 s; spawns stay exact
    while t < end:
        inc = income()
        cash += inc * step
        t += step

        # spawns
        luck = 1 + LUCK_STEP * luck_level
        # recess: luck x2 for 60 s every 15 min
        if t % 900 < 60:  # recess
            luck *= 2
        while next_spawn <= t:
            s, g = roll(rng, luck)
            hall.append((next_spawn + WALK, s, g))
            next_spawn += SPAWN
        if t >= next_late:
            base = [(r, w) for r, w in RARITIES if RARITY_ORDER[r] >= 3]
            for _ in range(LATE_COUNT):
                s, g = roll(rng, luck, base)
                hall.append((t + WALK, s, g))
            next_late += LATE_EVERY
        if t >= next_honor:
            for i in range(HONOR_COUNT):
                s, g = roll(rng, luck, HONOR_FIRST if i == 0 else HONOR_WEIGHTS)
                hall.append((t + WALK, s, g))
            next_honor += HONOR_EVERY
        if t >= next_trip:
            for _ in range(TRIP_COUNT):
                s, g = roll(rng, luck, TRIP_WEIGHTS)
                hall.append((t + WALK, s, g))
            next_trip += TRIP_EVERY
        hall = [h for h in hall if h[0] > t]

        # School Board review
        if tier + 1 < len(TIERS):
            nxt = TIERS[tier + 1]
            needs = nxt["needs"]
            has = needs is None or any(
                (s["rarity"] == "Secret") if needs == "Secret" else (s["id"] == needs) for _, s, _ in seated)
            if cash >= tier_cash[tier + 1] and has:
                events[f"income@{tier}"] = inc
                tier += 1
                mark(f"tier {tier} {nxt['name']}")
                if stop_tier is not None and tier >= stop_tier:
                    return events
                cash = START_CASH * nxt["mult"]
                seated = []
                continue

        # desk rows on unlocked floors
        for f in range(TIERS[tier]["floors"]):
            if f > 0 and rows_owned[f] < 2:
                rows_owned[f] = 2  # a new floor arrives with two free rows
            r = rows_owned[f]
            if r < len(DESK_ROWS[f]) and len(seated) >= desks() and cash >= DESK_ROWS[f][r]:
                cash -= DESK_ROWS[f][r]
                rows_owned[f] += 1

        # luck
        if luck_level < len(LUCK_COSTS) and cash >= LUCK_COSTS[luck_level] and LUCK_COSTS[luck_level] <= inc * 300:
            cash -= LUCK_COSTS[luck_level]
            luck_level += 1

        # supplies, builder items, teachers: best payback first
        if inc > 0:
            options = []
            for it in SUPPLIES:
                if it["id"] not in owned_items and tier + 1 >= it["tier"]:
                    options.append((it["price"] / (inc * it["gain"] / iq), "iq", it))
            for it in BUILDS:
                if it["id"] not in owned_items and tier + 1 >= it["tier"]:
                    options.append((it["price"] / (inc * it["gain"] / (100 + rep)), "rep", it))
            floors = TIERS[tier]["floors"]
            avg = teacher_avg()
            for f in range(floors):
                share = rows_owned[f] * DESKS_PER_ROW / max(1, sum(rows_owned[x] * DESKS_PER_ROW for x in range(floors)))
                for it in TEACHERS:
                    if tier + 1 >= it["tier"] and it["mult"] > teacher[f]:
                        gain = inc * share * (it["mult"] - teacher[f]) / avg
                        if gain > 0:
                            options.append((it["price"] / gain, ("t", f), it))
            options.sort(key=lambda o: o[0])
            for pay, kind, it in options[:1]:
                if pay <= PAYBACK and cash >= it["price"]:
                    cash -= it["price"]
                    if kind == "iq":
                        iq += it["gain"]; owned_items.add(it["id"])
                    elif kind == "rep":
                        rep += it["gain"]; owned_items.add(it["id"])
                    else:
                        teacher[kind[1]] = it["mult"]
                    mark(f"buy {it['id']}")

        # students
        needs = TIERS[tier + 1]["needs"] if tier + 1 < len(TIERS) else None
        saving = tier + 1 < len(TIERS) and cash >= 0.6 * tier_cash[tier + 1]
        best = None
        for h in hall:
            _, s, g = h
            if s["price"] > cash:
                continue
            v = s["income"] * g
            want = needs and ((s["rarity"] == "Secret") if needs == "Secret" else s["id"] == needs)
            score = math.inf if want and not any(x[1]["id"] == s["id"] for x in seated) else v
            if best is None or score > best[0]:
                best = (score, h)
        if best:
            score, h = best
            _, s, g = h
            v = s["income"] * g
            if len(seated) < desks():
                if not saving or score == math.inf:
                    cash -= s["price"]
                    seated.append((v, s, g))
                    hall.remove(h)
            else:
                seated.sort(key=lambda x: x[0])
                worst = seated[0]
                keep_needed = needs and worst[1]["id"] == needs
                if not keep_needed and (score == math.inf or (v > worst[0] * 1.25 and not saving)):
                    cash += worst[1]["price"] * SELL - s["price"]
                    seated[0] = (v, s, g)
                    hall.remove(h)
            mark(f"own {s['rarity']}")
    return events


def fmt(sec):
    if sec is None:
        return "   -   "
    h = sec / 3600
    return f"{h:7.2f}h" if h >= 1 else f"{sec / 60:6.1f}m "


def calibrate(targets, seeds=3, start=1):
    """Binary-search each tier's cash so the median strong player reaches it at targets[i] hours.
    Tiers before `start` keep the cash already in Config."""
    fixed = {}
    for i, target in enumerate(targets, start=1):
        if i < start:
            continue
        lo, hi = math.log10(max(TIERS[i - 1]["cash"], 1e3)), 22.0
        key = f"tier {i} {TIERS[i]['name']}"
        for _ in range(14):
            mid = (lo + hi) / 2
            trial = dict(fixed)
            trial[i] = 10 ** mid
            times = []
            for sd in range(seeds):
                ev = simulate(target * 2.2, sd, trial, stop_tier=i)
                times.append(ev.get(key, math.inf))
            med = statistics.median(times) / 3600
            if med < target:
                lo = mid
            else:
                hi = mid
        fixed[i] = 10 ** ((lo + hi) / 2)
        print(f"tier {i:2d} {TIERS[i]['name']:22s} target {target:6.1f}h  cash {fixed[i]:.3g}", flush=True)
    return fixed


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "calibrate":
        targets = [float(x) for x in sys.argv[2].split(",")]
        seeds = int(sys.argv[3]) if len(sys.argv) > 3 else 3
        start = int(sys.argv[4]) if len(sys.argv) > 4 else 1
        calibrate(targets, seeds, start)
        return
    hours = float(sys.argv[1]) if len(sys.argv) > 1 else 150
    seeds = int(sys.argv[2]) if len(sys.argv) > 2 else 5
    runs = [simulate(hours, s) for s in range(seeds)]
    keys = []
    for r in runs:
        for k in r:
            if k not in keys:
                keys.append(k)
    keys.sort(key=lambda k: statistics.median([r.get(k, math.inf) for r in runs]))
    print(f"{len(STUDENTS)} students, {len(TIERS)} tiers, {seeds} seeds, {hours:.0f} h cap")
    print(f"{'milestone':40s} {'median':>9s} {'min':>9s} {'max':>9s}  reached")
    for k in [k for k in keys if k.startswith("income@")]:
        vals = sorted(r[k] for r in runs if k in r)
        print(f"{k:40s} {statistics.median(vals):.3g}/s at the end of that tier")
    keys = [k for k in keys if not k.startswith("income@")]
    for k in keys:
        vals = [r[k] for r in runs if k in r]
        med = statistics.median(vals) if len(vals) == seeds else None
        print(f"{k:40s} {fmt(med):>9s} {fmt(min(vals)):>9s} {fmt(max(vals)):>9s}  {len(vals)}/{seeds}")


if __name__ == "__main__":
    main()
