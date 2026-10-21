# Reel 39 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 4)": every rendered frame in order (#2's
# lengths, so #2's cuts and hits land), marked for tools/comp_peak.mjs, in reel 38's style: the hook, the
# tag with only the name (cardLines 1), no chat / captions / notices / objective; the hotbar (flashlight,
# rocket launcher) and the stamina bar while you run. The rocket launcher on your shoulder for the shot:
# the rocket's trail drawn to where he is on screen (projected from the shot's camera), the blast there.
# Two jolts (he bursts out of the closet, he grabs Riley), the scare on 22.15 s, the glitch line on RUN.
import json, math, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
D = f"{S}/reel39"
FPS = 30
shots = json.load(open(f"{D}/shots.json"))
spec = json.load(open(f"{D}/spec.json"))
cams = {fr["f"]: fr["cam"] for fr in spec["frames"]}
him = {c["f"]: c for c in json.load(open(f"{D}/frames_in.json"))}
start = {s["name"]: s["start"] for s in shots}
SCARE = start["tear"] + 64          # 664: 22.15 s
GLITCH = (677, 691)
JOLTS = [start["card"] + 60, start["grab"] + 16]
FIRE, HIT = start["hall"] + 46, start["hall"] + 53
MUZZLE = [637, 1286]
RUNS = {"card": (96, 120), "hall": (0, 40), "down": (8, 33), "tent": (0, 30), "run": (0, 30)}

def project(f, p):
    # where a world point lands on the 1080x1920 frame (film2's camera: lookAt, vertical fov, roll ignored)
    c = cams[f]
    pos, look = c["pos"], c["look"]
    fw = [look[j] - pos[j] for j in range(3)]
    n = math.sqrt(sum(v * v for v in fw)); fw = [v / n for v in fw]
    rt = [-fw[2], 0.0, fw[0]]
    n = math.sqrt(sum(v * v for v in rt)); rt = [v / n for v in rt]
    up = [rt[1] * fw[2] - rt[2] * fw[1], rt[2] * fw[0] - rt[0] * fw[2], rt[0] * fw[1] - rt[1] * fw[0]]
    d = [p[j] - pos[j] for j in range(3)]
    x, y, z = sum(d[j] * rt[j] for j in range(3)), sum(d[j] * up[j] for j in range(3)), sum(d[j] * fw[j] for j in range(3))
    th = math.tan(math.radians(c.get("fov", 60)) / 2)
    nx, ny = x / (z * th * 1080 / 1920), y / (z * th)
    return [round((nx + 1) / 2 * 1080), round((1 - ny) / 2 * 1920)]

def chest(f):
    p = him[f]["pos"]
    return [p[0], p[1] + 5.4, p[2]]

def frame(f, name, i):
    h = {"sel": 1}
    if name in RUNS and RUNS[name][0] <= i < RUNS[name][1]:
        h["stam"] = max(0.3, 0.92 - 0.1 * (i - RUNS[name][0]) / 30)
    if name == "tent" and i >= 60 or name in ("in", "grab", "back", "tear"):
        h["sel"] = None                                  # (hiding: the hotbar's away)
    fr = {"hud": h}
    if (name == "hall" and i >= 36) or (name == "down" and i < 12):
        h["sel"] = 2
        fr["vm"] = {"item": "rocket", "loaded": f < FIRE, "kick": max(0.0, 1 - (f - FIRE) / 7) if f >= FIRE else 0.0}
        if name == "down":
            fr["vm"]["kick"] = 0.3 * (1 - i / 12)
    if FIRE <= f < HIT:
        fr["rocket"] = {"from": MUZZLE, "to": project(f, chest(f)), "k": round((f - FIRE + 1) / (HIT - FIRE), 3)}
    if HIT <= f < HIT + 11:
        fr["boom"] = {"at": project(f, chest(HIT)), "k": round(1 - (f - HIT) / 11, 3)}
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
print("cuts", cuts, "jolts", [round(j / FPS, 2) for j in JOLTS], "rocket", FIRE / FPS, HIT / FPS, "boom at", project(HIT, chest(HIT)))
json.dump({"frames": out, "cuts": cuts, "jolts": [j / FPS for j in JOLTS], "fire": FIRE / FPS, "hit": HIT / FPS,
           "text": {"part": "(Part 4)", "glitch": "he came back", "hookTimes": [0.25, 0.7, 1.15, 1.6, 2.05, 2.6],
                    "items": [["flashlight", ""], ["rocket", "2"]]}},
          open("edit.json", "w"))
