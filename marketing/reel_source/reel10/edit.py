# Reel 10 — the gameplay trailer, "I made a Roblox horror game where...": every beat is first-person
# gameplay with the game's own HUD, one mechanic per beat. Writes edit.json for comp9.mjs.
import json
S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
def rng(reel, a, n, step=1.0): return [f"{S}/{reel}/raw/{a + int(i * step):04d}.png" for i in range(n)]
SEGS = [
    ("hook",     rng("reel", 316, 90)),       # him coming down the hall at you
    ("sleep",    rng("reel10", 0, 90)),       # the sleepover
    ("clues",    rng("reel3", 400, 75)),      # the polaroids in his nest
    ("power",    rng("reel10", 90, 96)),      # lights flicker, out, flashlight on: him
    ("hunt",     rng("reel2", 150, 75)),      # he's hunting
    ("hide",     rng("reel2", 240, 90)),      # hiding, his legs go past
    ("caught",   rng("reel", 592, 30)),       # caught
    ("friends",  rng("reel8", 0, 60)),        # your friends come for you (and he's right behind them)
    ("endings",  [f"{S}/reel/raw/{96 + (i % 66):04d}.png" for i in range(105)]),
    ("cta",      [f"{S}/reel/raw/{96 + (i % 66):04d}.png" for i in range(150)]),
]
frames, cuts, t = [], [], 0
for name, srcs in SEGS:
    cuts.append(round(t / 30, 3))
    for i, s in enumerate(srcs):
        frames.append({"src": s, "seg": name, "i": i, "n": len(srcs)})
    t += len(srcs)
print(len(frames), "frames =", round(len(frames) / 30, 2), "s; cuts", cuts)
json.dump({"frames": frames, "cuts": cuts, "segs": [s[0] for s in SEGS], "icon": "/home/user/Horror/marketing/attic/icon_512.png"}, open("edit.json", "w"))
