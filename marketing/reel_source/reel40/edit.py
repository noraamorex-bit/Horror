# Reel 40 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 5)": BECOME HIM. Every rendered frame in order
# (#2's lengths, so #2's cuts and hits land), marked for tools/comp_peak.mjs, in reel 38's style (the hook, the
# tag with only the name, little text). While you're him (hook .. closet): the game's YOU ARE HIM bar and its
# LUNGE / SEARCH buttons, his vision (MonsterVision's grade) and the red pings where a noise came from (Riley
# breathing behind the curtain, the linen closet's door). Jolts on the lunge and the curtain; then Jamie's
# eyes in the closet: the scare on 22.15 s, the glitch line on RUN.
import json, math, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
D = f"{S}/reel40"
FPS = 30
U = 15.0
shots = json.load(open(f"{D}/shots.json"))
spec = json.load(open(f"{D}/spec.json"))
cams = {fr["f"]: fr["cam"] for fr in spec["frames"]}
start = {s["name"]: s["start"] for s in shots}
SCARE = start["tear"] + 64          # 664: 22.15 s
GLITCH = (677, 691)
LUNGE, RIP = start["card"] + 56, start["curtain"] + 70
JOLTS = [LUNGE, RIP]
HIM = ("hook", "card", "bath", "ping", "curtain", "lift", "turn", "closet")
SHOWER = [36.2, U + 4.0, 5.3]
CLOSET = [9.4, U + 5.0, -5.7]
PINGS = [(start["ping"] + 4, SHOWER), (start["ping"] + 18, SHOWER), (start["curtain"] + 30, SHOWER),
         (start["turn"] + 30, CLOSET), (start["turn"] + 44, CLOSET), (start["closet"] + 46, CLOSET)]
PING_LEN = 26
BRIGHT = {"hook": 1.85, "card": 1.85, "turn": 1.8, "closet": 1.8}   # (the hall behind him is dark; the bathroom is moonlit)

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

def press(f, at, n=6):
    return round(max(0.0, 1 - (f - at) / n), 3) if at <= f < at + n else 0.0

def frame(f, name, i):
    if name in HIM:
        caught = 1 if f >= RIP else 0
        mon = {"caught": caught, "lunge": press(f, LUNGE) or press(f, RIP), "search": press(f, start["ping"] + 1)}
        fr = {"hud": {"sel": None, "mon": mon}, "mv": True, "bright": BRIGHT.get(name, 1.45)}
        pings = []
        for at, p in PINGS:
            if at <= f < at + PING_LEN:
                pings.append({"at": project(f, p), "k": round((f - at) / PING_LEN, 3)})
        if pings: fr["pings"] = pings
    elif name == "run":
        fr = {"hud": {"sel": 1, "stam": max(0.3, 0.9 - 0.1 * i / 30)}}
    else:
        fr = {}
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
print("cuts", cuts, "jolts", [round(j / FPS, 2) for j in JOLTS], "pings", [(round(a / FPS, 2), project(a, p)) for a, p in PINGS])
json.dump({"frames": out, "cuts": cuts, "jolts": [j / FPS for j in JOLTS], "pings": [a / FPS for a, _ in PINGS],
           "text": {"part": "(Part 5)", "glitch": "you are him", "hookTimes": [0.25, 0.7, 1.15, 1.6, 2.05, 2.6],
                    "items": [["flashlight", ""]]}},
          open("edit.json", "w"))
