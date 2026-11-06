# "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 9)": reel 25's format (tools/comp_peak.mjs) on #2's track, from this
# reel's own render (scene.py -> $S/reel71/raw). Every slot keeps #2's length; the scare on 22.15 s, the glitch line on RUN.
#   python3 edit.py  -> edit.json in the current folder
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
SH = {s["name"]: s["start"] for s in json.load(open(f"{S}/reel71/shots.json"))}
# (shot, first frame in it, speed, brightness lift)
SLOTS = [("hook", 0, 1.0, 1.1), ("card", 0, 1.0, 1.3), ("peek", 0, 1.0, 1.3), ("snap", 0, 1.0, 1.3), ("back", 0, 1.0, 1.3),
         ("empty", 0, 1.0, 1.3), ("door", 0, 1.0, 1.3), ("wait", 0, 1.0, 1.35), ("last", 0, 1.0, 1.3), ("run", 0, 1.0, 1.1)]
TEXT = {"part": "(Part 9)", "glitch": "he saw me peeking"}
LENS = [105, 120, 72, 33, 90, 60, 60, 60, 75, 30]
CARD_POPS = [3.85, 4.55, 5.25, 5.95]
SCARE = (665, 675)
GLITCH = (677, 691)
out, g = [], 0
for (name, first, speed, lift), n in zip(SLOTS, LENS):
    for i in range(n):
        src = SH[name] + first + int(i * speed)
        t = g / FPS
        fr = {"src": f"{S}/reel71/raw/{src:04d}.png", "section": "hook" if g < 105 else "clip", "i": i}
        if g >= 105:
            fr["cardLines"] = sum(1 for p in CARD_POPS if t >= p)
        if lift != 1.0:
            fr["bright"] = lift
        if SCARE[0] <= g < SCARE[1]: fr["scare"] = True
        if GLITCH[0] <= g < GLITCH[1]: fr["glitchText"] = True
        out.append(fr)
        g += 1
for i in range(180):
    out.append({"src": None, "section": "end", "i": i})
cuts, t = [], 0
for n in LENS + [180]:
    cuts.append(round(t / FPS, 3)); t += n
TEXT["hookTimes"] = [0.25, 0.7, 1.15, 1.6, 2.05, 2.6]
print(len(out), "frames =", round(len(out) / FPS, 2), "s")
json.dump({"frames": out, "cuts": cuts, "text": TEXT}, open("edit.json", "w"))
