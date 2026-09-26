"""Search the Roblox avatar catalog and fetch thumbnails, for picking kids' clothes, hair and faces.

  python tools/catalog.py search <assetType> <keyword...>     -> id, favourites, price, name (top 12)
  python tools/catalog.py thumbs <outdir> <id> [<id> ...]     -> <outdir>/<id>.png (420x420)

assetType: shirt(11) pants(12) hat(8) hair(41) face(18) faceacc(42) neck(43) shoulder(44)
           front(45) back(46) waist(47) tshirt3d(64) shirt3d(65) pants3d(66) jacket(67)
           sweater(68) shorts(69) lshoe(70) rshoe(71) dress(72) head(17) dynhead(79)
Only items the catalog lists as on sale anywhere; sorted by favourites.
"""
import json, os, sys, time, urllib.parse, urllib.request

TYPES = {"shirt": 11, "pants": 12, "hat": 8, "hair": 41, "face": 18, "faceacc": 42, "neck": 43,
         "shoulder": 44, "front": 45, "back": 46, "waist": 47, "tshirt3d": 64, "shirt3d": 65,
         "pants3d": 66, "jacket": 67, "sweater": 68, "shorts": 69, "lshoe": 70, "rshoe": 71,
         "dress": 72, "head": 17, "dynhead": 79}
# catalog category for each asset type's search
CATEGORY = {11: 3, 12: 3, 64: 3, 65: 3, 66: 3, 67: 3, 68: 3, 69: 3, 72: 3, 70: 3, 71: 3,
            8: 11, 41: 4, 42: 11, 43: 11, 44: 11, 45: 11, 46: 11, 47: 11, 18: 13, 17: 13, 79: 13}


_last = [0.0]


def get(url):
    # the catalog allows only a trickle: at most one request every 2.5 s, and a long wait on a 429
    err = None
    for attempt in range(6):
        wait = _last[0] + 2.5 - time.time()
        if wait > 0:
            time.sleep(wait)
        _last[0] = time.time()
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=25) as r:
                return json.loads(r.read().decode())
        except Exception as e:
            err = e
            time.sleep(10 * (attempt + 1) if "429" in str(e) else 2)
    raise err


def search(asset_type, keyword):
    cat = CATEGORY.get(asset_type, 1)
    items = []
    cursor = ""
    for _ in range(2):
        q = {"Category": cat, "Keyword": keyword, "Limit": 30}
        if cursor:
            q["Cursor"] = cursor
        data = get("https://catalog.roblox.com/v1/search/items/details?" + urllib.parse.urlencode(q))
        for it in data.get("data", []):
            if it.get("itemType") == "Asset" and it.get("assetType") == asset_type:
                items.append(it)
        cursor = data.get("nextPageCursor")
        if not cursor or len(items) >= 12:
            break
    items.sort(key=lambda it: -(it.get("favoriteCount") or 0))
    return items[:12]


def thumbs(outdir, ids):
    os.makedirs(outdir, exist_ok=True)
    q = urllib.parse.urlencode({"assetIds": ",".join(ids), "size": "420x420", "format": "Png"})
    data = get("https://thumbnails.roblox.com/v1/assets?" + q)
    for d in data.get("data", []):
        if d.get("imageUrl"):
            req = urllib.request.Request(d["imageUrl"], headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=25) as r:
                open(os.path.join(outdir, f"{d['targetId']}.png"), "wb").write(r.read())
        else:
            print("no thumb yet:", d.get("targetId"), d.get("state"))


def sheet(out_png, ids, cols=6, cell=220):
    """A labelled contact sheet of asset thumbnails (fetched into a cache next to out_png)."""
    from PIL import Image, ImageDraw
    cache = os.path.join(os.path.dirname(out_png) or ".", "thumbcache")
    need = [i for i in ids if not os.path.exists(os.path.join(cache, f"{i}.png"))]
    for k in range(0, len(need), 30):
        thumbs(cache, need[k:k + 30])
    rows = (len(ids) + cols - 1) // cols
    img = Image.new("RGB", (cols * cell, rows * (cell + 22)), (235, 235, 240))
    d = ImageDraw.Draw(img)
    for n, i in enumerate(ids):
        x, y = (n % cols) * cell, (n // cols) * (cell + 22)
        p = os.path.join(cache, f"{i}.png")
        if os.path.exists(p):
            t = Image.open(p).convert("RGBA").resize((cell - 8, cell - 8))
            bg = Image.new("RGBA", t.size, (235, 235, 240, 255))
            img.paste(Image.alpha_composite(bg, t).convert("RGB"), (x + 4, y + 4))
        d.text((x + 6, y + cell + 4), f"{n + 1}: {i}", fill=(20, 20, 30))
    img.save(out_png)

def rows_sheet(out_png, rows_json, cell=150):
    """Contact sheet with one labelled row per (label, [ids]) in a JSON list: pick-by-eye for outfits."""
    from PIL import Image, ImageDraw
    rows = json.load(open(rows_json, encoding="utf-8"))
    cache = os.path.join(os.path.dirname(out_png) or ".", "thumbcache")
    allids = [str(i) for _, ids in rows for i in ids]
    need = [i for i in dict.fromkeys(allids) if not os.path.exists(os.path.join(cache, f"{i}.png"))]
    for k in range(0, len(need), 30):
        thumbs(cache, need[k:k + 30])
    cols = max((len(ids) for _, ids in rows), default=1)
    lw = 170
    img = Image.new("RGB", (lw + cols * cell, len(rows) * (cell + 16)), (235, 235, 240))
    d = ImageDraw.Draw(img)
    for r, (label, ids) in enumerate(rows):
        y = r * (cell + 16)
        d.rectangle([0, y, lw - 4, y + cell], fill=(215, 215, 225))
        d.text((6, y + cell // 2 - 6), label, fill=(10, 10, 20))
        for c, i in enumerate(ids):
            x = lw + c * cell
            p = os.path.join(cache, f"{i}.png")
            if os.path.exists(p):
                t = Image.open(p).convert("RGBA").resize((cell - 6, cell - 6))
                bg = Image.new("RGBA", t.size, (235, 235, 240, 255))
                img.paste(Image.alpha_composite(bg, t).convert("RGB"), (x + 3, y + 3))
            d.text((x + 4, y + cell + 1), f"{c + 1}:{i}", fill=(20, 20, 30))
    img.save(out_png)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    if sys.argv[1] == "search":
        t = TYPES[sys.argv[2]] if sys.argv[2] in TYPES else int(sys.argv[2])
        for it in search(t, " ".join(sys.argv[3:])):
            print(f"{it['id']}\t{it.get('favoriteCount', 0)}\t{it.get('price')}\t{it['name']}")
    elif sys.argv[1] == "thumbs":
        thumbs(sys.argv[2], sys.argv[3:])
    elif sys.argv[1] == "sheet":
        sheet(sys.argv[2], sys.argv[3:])
    elif sys.argv[1] == "rows":
        rows_sheet(sys.argv[2], sys.argv[3])
