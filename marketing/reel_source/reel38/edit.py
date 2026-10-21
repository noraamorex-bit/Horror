# Reel 38 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 3)". Every rendered frame in order (#2's
# lengths, so #2's cuts and hits land), marked for tools/comp_peak.mjs. The owner on Part 2: "too much
# text". So: the hook, the brand tag with only the name under it (cardLines 1: no GAMEPLAY / GENRE /
# OUT NOW), no chat, captions, notices, objective or prompts: only the hotbar (the flashlight in your
# hand) and the stamina bar while you run. Four scares: three jolts (he pounces off the island, he grabs
# Riley, he grabs Jamie) and the big one on 22.15 s, then the glitch line on RUN and the end card.
# Writes edit.json (and the cut times audio.py reads).
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
D = f"{S}/reel38"
FPS = 30
shots = json.load(open(f"{D}/shots.json"))
start = {s["name"]: s["start"] for s in shots}
SCARE = start["turn"] + 64          # 664: 22.15 s
GLITCH = (677, 691)
JOLTS = [start["card"] + 84, start["hall"] + 46, start["grab"] + 14]
RUNS = {"card": (84, 120), "hall": (0, 72), "stairs": (0, 33), "bed": (0, 30), "run": (0, 30)}

def frame(f, name, i):
    h = {"sel": 1}
    if name in RUNS and RUNS[name][0] <= i < RUNS[name][1]:
        r = (i - RUNS[name][0]) / 30
        h["stam"] = max(0.25, 0.95 - 0.12 * r) if name != "run" else 0.55 - 0.2 * i / 30
    if name in ("bed", "legs", "grab", "empty"):
        h["sel"] = 1 if name == "bed" and i < 30 else None    # (hiding: the hotbar's away)
    fr = {"hud": h}
    for j in JOLTS:
        if j <= f < j + 8:
            fr["jolt"] = round(1 - (f - j) / 8, 3)
    return fr

out = []
for s in shots:
    for i in range(s["n"]):
        f = s["start"] + i
        fr = {"src": f"{D}/raw/{f:04d}.png", "section": "hook" if s["name"] == "hook" else "clip", "i": i}
        fr.update(frame(f, s["name"], i))
        if s["name"] != "hook":
            fr["cardLines"] = 1
        if SCARE <= f < SCARE + 12: fr.update(scare=True, scareI=f - SCARE)
        if GLITCH[0] <= f < GLITCH[1]: fr["glitchText"] = True
        out.append(fr)
for i in range(180):
    out.append({"src": None, "section": "end", "i": i})
print(len(out), "frames =", round(len(out) / FPS, 2), "s")
cuts, t = [], 0
for n in [105, 120, 72, 33, 90, 60, 60, 60, 75, 30, 180]:
    cuts.append(round(t / FPS, 3)); t += n
assert [s["n"] for s in shots] == [105, 120, 72, 33, 90, 60, 60, 60, 75, 30], "the clips keep #2's lengths"
assert SCARE == 664
print("cuts", cuts, "jolts", [round(j / FPS, 2) for j in JOLTS])
json.dump({"frames": out, "cuts": cuts, "jolts": [j / FPS for j in JOLTS],
           "text": {"part": "(Part 3)", "glitch": "he saw you", "hookTimes": [0.25, 0.7, 1.15, 1.6, 2.05, 2.6]}},
          open("edit.json", "w"))
