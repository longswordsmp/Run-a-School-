"""Writes docs/ROBUX.md from Config.Passes and Config.Products (src/Shared/Config.lua).
Usage: python tools/robux_doc.py"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
s = (ROOT / "src" / "Shared" / "Config.lua").read_text(encoding="utf-8")


def items(block):
    out = []
    for m in re.finditer(r'\{ key = "(\w+)", id = (\d+), name = "([^"]*)", robux = (\d+), icon = "[^"]*", desc = "([^"]*)"', block):
        out.append(dict(key=m.group(1), id=m.group(2), name=m.group(3), robux=int(m.group(4)), desc=m.group(5)))
    return out


passes = items(s[s.index("Config.Passes = {"):s.index("Config.Products = {")])
prods = items(s[s.index("Config.Products = {"):s.index("Config.MoneyBoost = {")])
L = ["# Robux: what to create on the Creator Dashboard", "",
     "Everything the game sells, generated from `Config.Passes` and `Config.Products` (src/Shared/Config.lua)",
     "by tools/robux_doc.py. Nothing is on sale until it has an id: while an id is 0, the store hides it in a",
     "live game (in Studio it works as a free test purchase).", "",
     "**How:** Creator Dashboard, then Run A School!, then Monetization.",
     "1. Create each **pass** under Passes, and each **product** under Developer Products, with the name,",
     "   price and description below.",
     "2. Copy its id into the line with the same `key` in Config.lua (`id = 0` becomes `id = <the number>`).",
     "3. Tell me when that's done and I'll check every id in Studio.", "",
     "## Game passes (one-time, yours forever)", "", "| key | Name | R$ | Description |", "|---|---|---|---|"]
for x in passes:
    L.append("| %s | %s | %d | %s |" % (x["key"], x["name"], x["robux"], x["desc"]))
L += ["", "## Developer products (can be bought again)", "", "| key | Name | R$ | Description |", "|---|---|---|---|"]
for x in prods:
    L.append("| %s | %s | %d | %s |" % (x["key"], x["name"], x["robux"], x["desc"]))
L += ["", "## The Money Boost ladder", "",
      "One button in the store. Every purchase adds +1x to all your tuition, forever, up to x100. The price",
      "depends on the level you're buying, so it is five products (MoneyBoostA-E above) and the store picks",
      "the right one.", "", "| Levels | Product | R$ each | Purchases | R$ for the band |", "|---|---|---|---|---|"]
bands = [(2, 5, "MoneyBoostA"), (6, 10, "MoneyBoostB"), (11, 25, "MoneyBoostC"), (26, 50, "MoneyBoostD"), (51, 100, "MoneyBoostE")]
price = {x["key"]: x["robux"] for x in prods}
tot = 0
for a, b, k in bands:
    n = b - a + 1
    tot += n * price[k]
    L.append("| x%d to x%d | %s | %d | %d | %s |" % (a, b, k, price[k], n, format(n * price[k], ",")))
L += ["", "The whole ladder, x1 to x100: **%s R$**." % format(tot, ","), "",
      "Nothing is ever prompted automatically, and the Lucky Bus shows its odds before you buy.", ""]
(ROOT / "docs" / "ROBUX.md").write_text("\n".join(L), encoding="utf-8", newline="\n")
print(len(passes), "passes,", len(prods), "products, ladder", tot)
