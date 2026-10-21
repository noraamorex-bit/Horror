# Reel 37 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 2)", the gameplay series. Every rendered
# frame in order (the clips keep #2's lengths, so #2's cuts and hits land), marked for tools/comp_peak.mjs:
# the hook word by word, the card's lines with the track's four pops after the drop, the brand tag, and the
# game's HUD as you'd see it playing: the 911 call bar at the window, "Police: 2:00" counting down once it
# goes through, his footsteps and his voice as captions, the taser in your hand and the shot (its bolt
# drawn to where he is on screen), "Taser: 2 left", the breath bar in the shower, "Riley was caught!",
# the "Cut free" prompt on Riley in the boiler room, then the scare (22.15 s), the glitch line on RUN,
# and the branded end card. Writes edit.json (and the cut times audio.py reads).
import json, math, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
D = f"{S}/reel37"
FPS = 30
shots = json.load(open(f"{D}/shots.json"))
spec = json.load(open(f"{D}/spec.json"))
cams = {fr["f"]: fr["cam"] for fr in spec["frames"]}
start = {s["name"]: s["start"] for s in shots}
CARD_POPS = [3.85, 4.55, 5.25, 5.95]
SCARE = start["turn"] + 64          # 664: 22.15 s
GLITCH = (677, 691)
RILEY, JAMIE = "#62b0ff", "#74de84"   # (the blue and the green hoodie)
CHAT = [(0.6, "Riley", RILEY, "is it ringing??"), (1.8, "Jamie", JAMIE, "hes not downstairs anymore"),
        (2.9, "Riley", RILEY, "WHATS ON THE ROOF"), (6.4, "Riley", RILEY, "RUNNN"), (7.7, "Jamie", JAMIE, "TASE HIM"),
        (12.6, "Jamie", JAMIE, "RILEY"), (14.2, "Jamie", JAMIE, "basement!! found them"), (20.4, "Riley", RILEY, "behind u")]
CALLED = start["card"] + 14         # the call goes through
U, B = 15.0, -13.0

def project(f, p):
    # where a world point lands on the 1080x1920 frame (film2's camera: lookAt, vertical fov, no roll)
    c = cams[f]
    pos, look = c["pos"], c["look"]
    fw = [look[j] - pos[j] for j in range(3)]
    n = math.sqrt(sum(v * v for v in fw)); fw = [v / n for v in fw]
    rt = [fw[1] * 0 - fw[2] * 1, fw[2] * 0 - fw[0] * 0, fw[0] * 1 - fw[1] * 0]   # fw x up
    n = math.sqrt(sum(v * v for v in rt)); rt = [v / n for v in rt]
    up = [rt[1] * fw[2] - rt[2] * fw[1], rt[2] * fw[0] - rt[0] * fw[2], rt[0] * fw[1] - rt[1] * fw[0]]
    d = [p[j] - pos[j] for j in range(3)]
    x, y, z = sum(d[j] * rt[j] for j in range(3)), sum(d[j] * up[j] for j in range(3)), sum(d[j] * fw[j] for j in range(3))
    th = math.tan(math.radians(c.get("fov", 60)) / 2)
    nx, ny = x / (z * th * 1080 / 1920), y / (z * th)
    return [round((nx + 1) / 2 * 1080), round((1 - ny) / 2 * 1920)]

def police(f):
    if f < CALLED: return None
    left = max(0, 120 - (f - CALLED) / FPS)
    return "Police: %d:%02d" % (int(left) // 60, int(left) % 60)

STUN_CHEST = [24.0, U + 6.4, 0.6]
RILEY_CHEST = [-37.2, B + 5.5, 19.0]
VOICE = "[A voice, close] "

def frame(f, name, i):
    t = f / FPS
    h = {"sel": 0 if name == "hook" else 2, "chat": [[n, c, m] for (tt, n, c, m) in CHAT if t >= tt][-3:]}
    fr = {}
    h["obj"] = "Call 911 (one bar here)" if f < CALLED else ("<b>!</b> Hide until the police come" if f < start["boiler"] else
               ("<b>!</b> Free Riley (boiler room)" if f < start["free"] + 8 else ("<b>!</b> Hide until the police come" if name != "run" else "<b>!</b> Get out of the house")))
    h["police"] = police(f)
    if f < CALLED:
        h["meter"] = {"label": "Calling 911 - keep the signal", "v": min(1.0, 0.1 + 0.9 * f / CALLED), "col": "#8fc8ff"}
    if name == "card":
        if 14 <= i < 36: h["notice"] = "Police are on the way"
        if 38 <= i < 70: h["cap"] = "[Running footsteps, in the hall]"
        if i >= 86: h["cap"] = VOICE + "There you are."
    if name == "taser":
        h["cnt"] = {2: "3" if i < 24 else "2"}
        fr["vm"] = {"kick": max(0.0, 1 - (i - 24) / 6) if i >= 24 else 0.0}
        if 24 <= i < 30:
            fr["zap"] = {"from": [797, 1528], "to": project(f, STUN_CHEST), "k": 1 - (i - 24) / 7}
        if i >= 30: h["cap"] = "Taser: 2 left"
    if name in ("in", "caught", "boiler", "cut", "free", "turn", "run"):
        h["cnt"] = {2: "2"}
    if name == "in":
        h["meter"] = {"label": "Breath", "v": 1.0, "col": "#dcdcd2"}
    if name == "caught":
        held = i >= 30
        h["meter"] = {"label": "Holding your breath" if held else "Breath", "v": 1.0 - 0.6 * max(0, i - 30) / 60, "col": "#8fc8ff" if held else "#dcdcd2"}
        if i >= 70: h["notice"] = "Riley was caught!"
    if name == "cut":
        p = min(1.0, max(0.0, (i - 4) / 46))
        if i < 54:
            h["prompt"] = {"action": "Cut free", "object": "Riley", "key": "E", "p": p}
            x, y = project(f, RILEY_CHEST)
            h["prompt"]["x"], h["prompt"]["y"] = x + 150, y
        else:
            h["notice"] = "You cut Riley free"
    if name == "free":
        if i < 20: h["notice"] = "You cut Riley free"
        if i >= 26: h["cap"] = VOICE + "We're a family now."
    if name == "run":
        h["stam"] = 0.95 - 0.3 * i / 30
    fr["hud"] = h
    return fr

out = []
for s in shots:
    for i in range(s["n"]):
        f = s["start"] + i
        t = f / FPS
        fr = {"src": f"{D}/raw/{f:04d}.png", "section": "hook" if s["name"] == "hook" else "clip", "i": i}
        fr.update(frame(f, s["name"], i))
        if s["name"] in ("hook", "card") and f < start["card"] + 24:
            fr["rain"] = True
        if s["name"] != "hook":
            fr["cardLines"] = sum(1 for p in CARD_POPS if t >= p)
        if SCARE <= f < SCARE + 12: fr.update(scare=True, scareI=f - SCARE)
        if GLITCH[0] <= f < GLITCH[1]: fr["glitchText"] = True
        out.append(fr)
# the end card: 6 s (black, a noise burst on the way in, then the name and the search bar)
for i in range(180):
    out.append({"src": None, "section": "end", "i": i})
print(len(out), "frames =", round(len(out) / FPS, 2), "s")
cuts, t = [], 0
for n in [105, 120, 72, 33, 90, 60, 60, 60, 75, 30, 180]:
    cuts.append(round(t / FPS, 3)); t += n
assert [s["n"] for s in shots] == [105, 120, 72, 33, 90, 60, 60, 60, 75, 30], "the clips keep #2's lengths"
assert SCARE == 664
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "text": {"part": "(Part 2)", "glitch": "he heard the call", "hookTimes": [0.25, 0.7, 1.15, 1.6, 2.05, 2.6]}},
          open("edit.json", "w"))
