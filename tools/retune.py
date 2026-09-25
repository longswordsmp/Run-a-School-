"""Rewrites every student's price in src/Shared/Config.lua from its income and a payback time
per rarity (seconds of that student's own tuition to earn its price back), rounded to two
significant figures. Incomes stay as authored.

Payback doubles per rarity: the ladder is quick at the bottom and a real climb at the top.
Run tools/econ_sim.py afterwards to see the pacing.
"""
import math
import pathlib
import re

PAYBACK = {
    "Common": 30,
    "Uncommon": 60,
    "Rare": 120,
    "Epic": 240,
    "Legendary": 480,
    "Mythic": 900,
    "Prodigy": 1800,
    "Secret": 3600,
    "Alumni": 7200,
}

path = pathlib.Path(__file__).resolve().parent.parent / "src" / "Shared" / "Config.lua"
src = path.read_text()


def sig2(x):
    if x < 100:
        return int(round(x / 5) * 5) or 5
    e = 10 ** (int(math.floor(math.log10(x))) - 1)
    return int(round(x / e) * e)


def lua_num(n):
    if n >= 1e9:
        s = f"{n / 1e9:g}e9"
    elif n >= 1e6:
        s = f"{n:.0f}"
    else:
        s = str(n)
    return s


def fix(m):
    sid, name, rarity, _price, income = m.group(1), m.group(2), m.group(3), m.group(4), m.group(5)
    price = sig2(float(income) * PAYBACK[rarity])
    return f'S("{sid}", "{name}", "{rarity}", {lua_num(price)}, {income},'


new = re.sub(r'S\("(\w+)", "([^"]+)", "(\w+)", ([\d.e]+), ([\d.e]+),', fix, src)
path.write_text(new)
for m in re.finditer(r'S\("(\w+)", "[^"]+", "(\w+)", ([\d.e]+), ([\d.e]+),', new):
    print(f"{m.group(1):18s} {m.group(2):10s} price {float(m.group(3)):>14,.0f}  income {float(m.group(4)):>12,.1f}")
