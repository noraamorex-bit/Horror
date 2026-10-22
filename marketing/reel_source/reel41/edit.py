# Reel 41 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 6)": every rendered frame in order (#2's lengths,
# so #2's cuts and hits land), marked for tools/comp_peak.mjs, in reel 38's style (the hook, the tag with only the
# name, little text; the hotbar and the sprint bar). The TASER in your hand (bottom right) and its shot: the bolt
# drawn to where he is on screen (projected from the shot's camera), one charge gone from the slot. The heartbeat
# minigame's lane while he's at the cabinet (no words). Jolts: he comes out of the doorway, he lands on Riley;
# the scare on 22.15 s, the glitch line on RUN.
import json, math, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
D = f"{S}/reel41"
FPS = 30
G = 1.0
shots = json.load(open(f"{D}/shots.json"))
spec = json.load(open(f"{D}/spec.json"))
cams = {fr["f"]: fr["cam"] for fr in spec["frames"]}
him = {c["f"]: c for c in json.load(open(f"{D}/frames_in.json"))}
start = {s["name"]: s["start"] for s in shots}
SCARE = start["tear"] + 64          # 664: 22.15 s
GLITCH = (677, 691)
ZAP = start["taser"] + 24
JOLTS = [start["card"] + 92, start["chase"] + 66]
HB0 = start["back"] + 40            # the heartbeat starts as he turns to the cabinet
HB1 = start["tear"] + 44            # ...and stops as he goes
TASER_TIP = [797, 1528]

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
    return [p[0], G + 4.2, p[2]]

def frame(f, name, i):
    h = {"sel": 1, "cnt": {2: "3" if f < ZAP else "2"}}
    fr = {"hud": h}
    if name in ("taser", "stun"):
        h["sel"] = 2
        fr["vm"] = {"kick": max(0.0, 1 - (f - ZAP) / 6) if f >= ZAP else 0.0}
    if ZAP <= f < ZAP + 7:
        fr["zap"] = {"from": TASER_TIP, "to": project(f, chest(f)), "k": round(1 - (f - ZAP) / 7, 3)}
    if name == "chase" and i < 48:
        h["stam"] = max(0.35, 1.0 - 0.6 * i / 48)
    if name == "run":
        h["stam"] = 0.9 - 0.25 * i / 30
    if name in ("hide", "back", "tear"):
        h["sel"] = None                                  # (hiding: the hotbar's away)
        if not (name == "tear" and i >= 64):
            fr["bright"] = 1.6                           # (the cabinet's crack is dim: lift it so a phone shows it)
    if HB0 <= f < HB1:
        h["hb"] = (f - HB0) / FPS
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
print("cuts", cuts, "jolts", [round(j / FPS, 2) for j in JOLTS], "zap", round(ZAP / FPS, 2), project(ZAP, chest(ZAP)), "hb", round(HB0 / FPS, 2), round(HB1 / FPS, 2))
json.dump({"frames": out, "cuts": cuts, "jolts": [j / FPS for j in JOLTS], "zap": ZAP / FPS, "leap": (start["chase"] + 50) / FPS,
           "hb": [HB0 / FPS, HB1 / FPS],
           "text": {"part": "(Part 6)", "glitch": "he got back up", "hookTimes": [0.25, 0.7, 1.15, 1.6, 2.05, 2.6],
                    "items": [["flashlight", ""], ["taser", "3"]]}},
          open("edit.json", "w"))
