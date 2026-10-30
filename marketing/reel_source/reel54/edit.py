# Reel 54: the comp's frame list (tools/comp_find.mjs). python3 edit.py -> $S/reel54/comp/edit.json
# Each level: `search` frames of the timer running out, then the reveal (the ring + the punch-in on targets.json's point);
# level 4's mask drops at 195 (the scare); then the end card over level 4's hatch, blurred.
import json, os
S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
W = f"{S}/reel54"
shots = json.load(open(f"{W}/shots.json"))
tg = json.load(open(f"{W}/targets.json"))
LEVELS = [{"name": "EASY", "col": "#3ddc5a"}, {"name": "MEDIUM", "col": "#ffd23f"}, {"name": "HARD", "col": "#ff8a1f"},
          {"name": "IMPOSSIBLE", "col": "#ff2a2a"}]
SEARCH = [105, 120, 135, 165]
ZOOM = [1.7, 1.9, 2.1, 2.5]
RING = [1.0, 0.95, 0.9, 0.75]
BRIGHT = [1.25, 1.3, 1.35, 1.25]
DROP = 195
frames = []
for L, sh in enumerate(shots):
    for i in range(sh["n"]):
        f = sh["start"] + i
        fr = {"src": f"{W}/raw/{f:04d}.png", "sec": "lvl", "lvl": L, "i": i, "n": sh["n"], "search": SEARCH[L],
              "target": tg.get(str(f)), "zoom": ZOOM[L], "ring": RING[L], "bright": BRIGHT[L],
              "lift": "liftLow" if L == 3 else "lift"}     # (level 4 stays darker: it's the hardest)
        if L == 3 and i >= DROP:
            fr["scare"] = i - DROP
            fr["target"] = None
        frames.append(fr)
END = 75
last = shots[-1]["start"] + 30
for i in range(END):
    frames.append({"src": f"{W}/raw/{last:04d}.png", "sec": "end", "lvl": 3, "i": i, "search": 0, "target": None})
os.makedirs(f"{W}/comp", exist_ok=True)
json.dump({"frames": frames, "levels": LEVELS}, open(f"{W}/comp/edit.json", "w"))
print("frames", len(frames), round(len(frames) / 30, 2), "s")
