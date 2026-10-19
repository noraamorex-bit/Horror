#!/usr/bin/env python3
"""Creator Store search → a labelled contact sheet of thumbnails, to shortlist models by eye.

Usage: python3 tools/assets/search.py <outDir> "<keyword>" [count=24] [category=10]
(category 10 = models, 13 = decals/images, 3 = audio)
Writes <outDir>/<keyword>.png (thumbnails with their asset ids) and <keyword>.json (id, name,
creator, favourites). Free models only (the marketplace search returns those).
"""
import json
import os
import subprocess
import sys
import urllib.parse
import urllib.request


def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"}), timeout=30) as r:
        return r.read()


def main():
    out, kw = sys.argv[1], sys.argv[2]
    n = int(sys.argv[3]) if len(sys.argv) > 3 else 24
    cat = int(sys.argv[4]) if len(sys.argv) > 4 else 10
    os.makedirs(out, exist_ok=True)
    q = urllib.parse.quote(kw)
    ids = [str(x["id"]) for x in json.loads(get(f"https://apis.roblox.com/toolbox-service/v1/marketplace/{cat}?keyword={q}&num={n}&sortDirection=Descending"))["data"]][:n]
    det = json.loads(get("https://apis.roblox.com/toolbox-service/v1/items/details?assetIds=" + ",".join(ids)))
    info = {}
    for it in det.get("data", []):
        a, c, v = it.get("asset", {}), it.get("creator", {}), it.get("voting", {})
        info[str(a.get("id"))] = {"name": a.get("name"), "creator": c.get("name"), "up": v.get("upVotes"), "down": v.get("downVotes")}
    th = json.loads(get("https://thumbnails.roblox.com/v1/assets?assetIds=" + ",".join(ids) + "&size=250x250&format=Png"))
    tdir = os.path.join(out, "thumbs")
    os.makedirs(tdir, exist_ok=True)
    files = []
    for t in th.get("data", []):
        if t.get("imageUrl"):
            f = os.path.join(tdir, f"{t['targetId']}.png")
            if not os.path.exists(f):
                open(f, "wb").write(get(t["imageUrl"]))
            files.append((str(t["targetId"]), f))
    order = {i: k for k, i in enumerate(ids)}
    files.sort(key=lambda x: order.get(x[0], 999))
    slug = "".join(ch if ch.isalnum() else "_" for ch in kw)
    json.dump([{"id": i, **info.get(i, {})} for i, _ in files], open(os.path.join(out, slug + ".json"), "w"), indent=1)
    # contact sheet: 6 per row, the id under each
    args = []
    for i, f in files:
        args += ["-i", f]
    if not files:
        print("nothing found")
        return
    labels = []
    for k, (i, _) in enumerate(files):
        nm = (info.get(i, {}).get("name") or "")[:22].replace(":", " ").replace("'", " ").replace(",", " ")
        labels.append(f"[{k}]scale=250:250,drawtext=text='{i}':x=4:y=4:fontsize=16:fontcolor=white:box=1:boxcolor=black@0.6,"
                      f"drawtext=text='{nm}':x=4:y=228:fontsize=13:fontcolor=white:box=1:boxcolor=black@0.6[v{k}]")
    cols = 6
    rows = (len(files) + cols - 1) // cols
    layout = "|".join(f"{(k % cols) * 250}_{(k // cols) * 250}" for k in range(len(files)))
    fc = ";".join(labels) + ";" + "".join(f"[v{k}]" for k in range(len(files))) + f"xstack=inputs={len(files)}:layout={layout}:fill=gray"
    if len(files) == 1:
        fc = labels[0].replace(f"[v0]", "")
    sheet = os.path.join(out, slug + ".png")
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", *args, "-filter_complex", fc, "-frames:v", "1", sheet], check=True)
    print(sheet, len(files))


if __name__ == "__main__":
    main()
