#!/usr/bin/env python3
"""Audio audit: every sound in src/shared/Sounds.luau, checked against Roblox.

For each entry: the asset's name and creator (economy details), whether our key can download it
(a private sound won't play in our game either: Roblox plays it as silence), and, downloaded, its
length and loudness (ffmpeg volumedetect), so a sound that's too quiet or too short to notice shows.
Usage: python3 tools/audio_audit.py <cacheDir> [--names Key1,Key2]
Prints one line per sound: key, id, ok/FAIL, seconds, mean dB, max dB, effective level
(mean dB + 20·log10(Volume): what the player actually gets before distance), creator, name.
"""
import json, math, os, re, subprocess, sys, time, urllib.request

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "assets"))
from fetch import fetch  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def details(aid):
    for i in range(5):
        try:
            with urllib.request.urlopen(f"https://economy.roblox.com/v2/assets/{aid}/details", timeout=30) as r:
                return json.loads(r.read())
        except urllib.error.HTTPError as e:
            if e.code == 429:
                time.sleep(3 * (i + 1))
                continue
            return {"error": e.code}
        except Exception as e:  # noqa: BLE001
            time.sleep(2)
    return {"error": "gave up"}


def level(path):
    p = subprocess.run(["ffmpeg", "-hide_banner", "-i", path, "-af", "volumedetect", "-f", "null", "-"], capture_output=True, text=True)
    mean = re.search(r"mean_volume: (-?[\d.]+) dB", p.stderr)
    mx = re.search(r"max_volume: (-?[\d.]+) dB", p.stderr)
    dur = re.search(r"Duration: (\d+):(\d+):([\d.]+)", p.stderr)
    secs = int(dur.group(1)) * 3600 + int(dur.group(2)) * 60 + float(dur.group(3)) if dur else None
    return secs, float(mean.group(1)) if mean else None, float(mx.group(1)) if mx else None


def main():
    cache = sys.argv[1]
    os.makedirs(cache, exist_ok=True)
    only = None
    if "--names" in sys.argv:
        only = set(sys.argv[sys.argv.index("--names") + 1].split(","))
    src = open(os.path.join(ROOT, "src/shared/Sounds.luau")).read()
    rows = []
    for m in re.finditer(r"^\s*(\w+)\s*=\s*\{([^\n]*)\}", src, re.M):
        key, body = m.group(1), m.group(2)
        idm = re.search(r'Id\s*=\s*"rbxassetid://(\d+)"', body)
        if not idm or (only and key not in only):
            continue
        vol = re.search(r"Volume\s*=\s*([\d.]+)", body)
        rows.append((key, idm.group(1), float(vol.group(1)) if vol else 0.5))
    for key, aid, vol in rows:
        d = details(aid)
        creator = (d.get("Creator") or {}).get("Name", "?")
        name = d.get("Name", d.get("error", "?"))
        try:
            p = fetch(cache, aid)
            ok = "ok"
            secs, mean, mx = level(p)
        except Exception as e:  # noqa: BLE001
            ok, secs, mean, mx = "FAIL", None, None, None
        eff = (mean + 20 * math.log10(max(vol, 1e-3))) if mean is not None else None
        f = lambda v, n=1: "-" if v is None else f"{v:.{n}f}"
        print(f"{key:22s} {aid:>16s} {ok:4s} {f(secs):>6s}s mean {f(mean):>6s} max {f(mx):>6s} vol {vol:<5} eff {f(eff):>6s}  {creator} | {name}", flush=True)


if __name__ == "__main__":
    main()
