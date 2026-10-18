# Reel 32 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 10)": Part 2's format on #2's track.
# Every rendered frame in order (the clips have #2's lengths, so #2's cuts and hits land), marked for
# tools/comp_peak.mjs: the hook word by word on the music box notes (0-3.5 s), the card's lines popping
# in with the track's four pops from the beat drop (3.85 / 4.55 / 5.25 / 5.95 s), the pixelated scare
# when he comes round the back of the car at you (22.15 s), the glitch line on RUN, and the black end card (23.5-29.5 s).
# Writes edit.json (and the cut times audio.py reads).
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
shots = json.load(open(f"{S}/reel32/shots.json"))
total = sum(s["n"] for s in shots)
CARD_POPS = [3.85, 4.55, 5.25, 5.95]
SCARE = (665, 675)
GLITCH = (677, 691)
out = []
for s in shots:
    for i in range(s["n"]):
        f = s["start"] + i
        t = f / FPS
        fr = {"src": f"{S}/reel32/raw/{f:04d}.png", "section": "hook" if s["name"] == "hook" else "clip", "i": i}
        if s["name"] != "hook":
            fr["cardLines"] = sum(1 for p in CARD_POPS if t >= p)
        if SCARE[0] <= f < SCARE[1]: fr["scare"] = True
        if GLITCH[0] <= f < GLITCH[1]: fr["glitchText"] = True
        out.append(fr)
# the end card: 6 s (black, a noise burst on the way in)
for i in range(180):
    out.append({"src": None, "section": "end", "i": i})
print(len(out), "frames =", round(len(out) / FPS, 2), "s")
cuts, t = [], 0
for n in [105, 120, 72, 33, 90, 60, 60, 60, 75, 30, 180]:
    cuts.append(round(t / FPS, 3)); t += n
assert [s["n"] for s in shots] == [105, 120, 72, 33, 90, 60, 60, 60, 75, 30], "the clips keep #2's lengths"
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "text": {"part": "(Part 10)", "glitch": "he's in here", "hookTimes": [0.25, 0.7, 1.15, 1.6, 2.05, 2.6]}},
          open("edit.json", "w"))
