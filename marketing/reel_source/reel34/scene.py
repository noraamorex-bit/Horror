# Reel 34 — the "story" format, #2 (reel 33's look: typed lines over found footage on #2's track, every
# clip at #2's length), with the v100-102 creature (his mouth opens; charcoal, glowing, easy to see) and
# the brand banner throughout (NEW ROBLOX HORROR GAME + the name). The story: something's been eating
# our food.
#   hook (105)  the dark kitchen, the flashlight finding the fridge       "something has been / eating our food."
#   card (120)  the fridge door swings open: the lasagna dish licked clean "mom's lasagna was gone." / "the dish was licked clean."
#   72          the back door, wide open in the rain, lightning           "the back door was open."
#   33          wet prints across the kitchen floor, coming in            "it never left."
#   90          down the dark house: it stands in the living room         "it was standing in the dark."
#   60          closer: its mouth slowly opens                            "and it smiled."
#   60          behind the living-room curtains                           "so i hid."
#   60          past the gap: it creeps along, hunched, sniffing          "it could smell me."
#   75          it stops... leans in... the curtain torn away (22.15 s)   "i held my breath."
#   30          RUN: down the front hall, it comes on all fours           "RUN."
# python3 scene.py [preview]. Writes spec.json, frames_in.json, shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.6
WALK = math.tau / 6.2
RUN = math.tau / 8.5

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]
def stop(i, fps=13):
    return math.floor(i * fps / 30) / fps

COLD, MOON = "#3d4f7a", "#6f86c4"
FRIDGE_LIGHT = "#dfeaff"
# the fridge's right leaf (hinged at its outer edge) and the back door (hinged at x max, opens in)
FRIDGE = {"near": [-28.36, 7.8, 25.95], "r": 1.3, "names": ["FridgeDoor", "FridgeHandle"], "hinge": [-29.58, 0, 25.95], "axis": "y"}
FX = -28.36   # (the left leaf: the notes and the menu are on the right one)
BACKDOOR = {"near": [-20.0, 5.7, 30.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [-17.58, 0, 30.0], "axis": "y"}
# the living-room curtain you hide behind (front wall, x -38.4..-36.4), torn away from its far edge
CURTAIN = {"near": [-37.4, 7.3, -29.08], "r": 1.4, "names": ["Curtain"], "hinge": [-38.4, 0, -29.08], "axis": "y"}
PEEK_EYE = [-36.15, G + 5.0, -28.6]
PEEK_LOOK = [-33.5, G + 4.4, -15.0]
KITCHEN = [{"p": [-38, 9, 14], "col": COLD, "b": 1.4, "r": 16}, {"p": [-24, 9, 29], "col": COLD, "b": 1.0, "r": 14},
           {"p": [-32, 9, 31], "col": MOON, "b": 2.2, "r": 18, "decay": 1.2}]
LIVING = [{"p": [-24, 9, -28], "col": MOON, "b": 4.2, "r": 26, "decay": 1.1}, {"p": [-36, 8.5, -16], "col": COLD, "b": 2.6, "r": 18},
          {"p": [-30, 8.5, -4], "col": COLD, "b": 1.2, "r": 14}]
SHOTS = {
    "kitchen": {"center": [-22, 6, 18], "radius": 36, "lampRadius": 0, "maxLamps": 0, "door": FRIDGE, "lights": KITCHEN},
    "fridge": {"center": [-24, 6, 22], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": FRIDGE,
               "lights": KITCHEN + [{"p": [FX, 9.6, 25.0], "col": FRIDGE_LIGHT, "b": 3.2, "r": 12, "decay": 1.4}]},
    "back": {"center": [-20, 6, 22], "radius": 34, "lampRadius": 0, "maxLamps": 0, "door": BACKDOOR,
             "lights": KITCHEN + [{"p": [-20, 9, 36], "col": MOON, "b": 5.0, "r": 22, "decay": 1.1}]},
    "living": {"center": [-28, 6, -12], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": LIVING},
    "curtain": {"center": [-32, 6, -20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": CURTAIN, "lights": LIVING},
    "hall": {"center": [2, 6, -10], "radius": 40, "lampRadius": 0, "maxLamps": 0,
             "lights": [{"p": [2, 9, -31], "col": MOON, "b": 2.4, "r": 26, "decay": 1.1}, {"p": [2, 9, 6], "col": COLD, "b": 1.4, "r": 18}]},
}
DARK = {"ambient": 0.03, "bg": 0x010102}

extras = []
# inside the fridge (the game hides its insides while it's shut): a white liner, shelves, the empty dish
WHITE, GLASS, FOIL = [232, 238, 240], [200, 222, 230], [196, 200, 206]
extras.append({"pos": [FX, 7.8, 26.12], "s": [2.3, 6.6, 0.05], "rot": [0, 0, 0], "col": WHITE, "rough": 0.5})
for y in (5.9, 7.7, 9.4):
    extras.append({"pos": [FX, y, 25.75], "s": [2.2, 0.07, 0.75], "rot": [0, 0, 0], "col": GLASS, "rough": 0.2})
extras.append({"pos": [FX + 0.1, 7.92, 25.72], "s": [1.6, 0.32, 0.72], "rot": [0, 0.08, 0], "col": FOIL, "rough": 0.3})        # the dish
extras.append({"pos": [FX + 0.1, 8.0, 25.72], "s": [1.4, 0.2, 0.6], "rot": [0, 0.08, 0], "col": [150, 60, 40], "rough": 0.6})   # what's left of the sauce
extras.append({"pos": [FX + 0.7, 8.3, 25.6], "s": [0.07, 0.07, 1.0], "rot": [0.7, 0.4, 0], "col": [180, 184, 190], "rough": 0.2}) # the fork
extras.append({"pos": [FX - 0.8, 6.3, 25.75], "s": [0.6, 0.7, 0.5], "rot": [0, 0, 0], "col": [245, 245, 240], "rough": 0.5})       # milk
extras.append({"pos": [FX + 0.8, 9.75, 25.75], "s": [0.5, 0.65, 0.45], "rot": [0, 0, 0], "col": [240, 150, 40], "rough": 0.5})     # juice
# (all of it hidden while the door's shut: film2 hideExtras takes points)
SHUT = [[e["pos"][0], e["pos"][1] - 0.22, e["pos"][2]] for e in extras]
# wet prints: in at the back door, across the kitchen, out towards the front of the house
WET = [30, 25, 21]
FROM, TO, STRIDE = [-20.4, 27.4], [-20.8, 3.0], 2.3   # (between the island and the table)
dx, dz = TO[0] - FROM[0], TO[1] - FROM[1]
L = math.hypot(dx, dz); fx, fz = dx / L, dz / L
rx, rz = -fz, fx
yaw = math.atan2(-fx, -fz)
def rot(x, z, a):
    return [x * math.cos(a) + z * math.sin(a), -x * math.sin(a) + z * math.cos(a)]
d, n = 0.6, 0
while d < L - 0.3:
    side = -1 if n % 2 == 0 else 1
    cx, cz = FROM[0] + fx * d + rx * side * 0.38, FROM[1] + fz * d + rz * side * 0.38
    for (lx, lz, sx, sz) in [(0, 0.05, 0.32, 0.85), (0, 0.42, 0.38, 0.32)]:
        o = rot(lx, lz, yaw)
        extras.append({"pos": [cx + o[0], G + 0.011, cz + o[1]], "s": [sx, 0.02, sz], "rot": [0, yaw, 0], "col": WET, "rough": 0.3})
    for k2, a in enumerate([-0.32, 0.0, 0.32]):
        o = rot(0, -0.62 - (0.06 if k2 == 1 else 0), yaw - a)
        extras.append({"pos": [cx + o[0], G + 0.011, cz + o[1]], "s": [0.08, 0.02, 0.42], "rot": [0, yaw - a, 0], "col": WET, "rough": 0.3})
    d += STRIDE; n += 1
PRINTS = len(extras)

frames, crs, shots = [], [], []
f = 0
def shot(name, n, fn):
    global f
    shots.append({"name": name, "start": f, "n": n})
    dense = dict((d.split(":")[0], d.split(":")[1:]) for d in os.environ.get("DENSE", "").split(",") if d)
    if name in dense:
        a = dense[name]
        idx = list(range(int(a[1]) if len(a) > 1 else 0, n, int(a[0]) if a else 8))
    else:
        idx = [0, n // 2, n - 1]
    idx = idx if PREVIEW else range(n)
    for i in idx:
        k = i / max(1, n - 1)
        fr, cr = fn(i, k)
        fr["f"] = f + i
        fr["creature"] = cr is not None
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n

def fl(cam, tgt, i=12.0, angle=0.34):
    return {"i": i, "pos": [cam[0] + 0.5, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}

# 1. (hook) the dark kitchen: a slow push, the flashlight sliding along the counter to the fridge
def s_hook(i, k):
    cam = add(lerp([-17.5, G + EYE, 10.0], [-21.5, G + EYE - 0.2, 17.5], ease(k)), hand(i))
    tgt = lerp([-34.0, G + 4.2, 26.0], [-27.6, G + 6.6, 26.0], ease(min(1.0, k * 1.2)))
    look = lerp([-29.0, G + 4.6, 26.0], [-27.4, G + 6.4, 26.0], ease(k))
    return (dict(DARK, shot="kitchen", cam={"pos": cam, "look": look, "fov": 60}, flash=fl(cam, tgt, 13.0), exposure=1.9, door=0.0, hideExtras=SHUT), None)
shot("hook", 105, s_hook)

# 2. (card) the fridge door swings open: light spills out, and the lasagna dish is licked clean
def s_fridge(i, k):
    # (a step back, the whole fridge in frame: the left door swings open, the light falls out, and
    # the slow push in to the dish licked clean)
    z = ease((k - 0.35) / 0.6)
    cam = add(lerp([-27.6, G + EYE, 16.5], [-28.2, G + EYE + 0.6, 20.0], z), hand(i, 0.6))
    door = 1.9 * ease(min(1.0, (i - 8) / 26))
    look = lerp([-27.4, G + 6.0, 26.0], [FX + 0.1, G + 6.9, 25.7], z)
    return (dict(DARK, shot="fridge" if i >= 9 else "kitchen", cam={"pos": cam, "look": look, "fov": 48 - 10 * z}, exposure=1.8, door=door,
                 hideExtras=SHUT if i < 10 else []), None)
shot("card", 120, s_fridge)

# 3. the back door: wide open, swinging a little in the wind, the rain outside, lightning
def s_back(i, k):
    cam = add([-21.5, G + EYE, 19.0 + 1.5 * ease(k)], hand(i, 0.5))
    swing = -1.35 + 0.1 * math.sin(i * 0.13)
    lt = 1.0 if 24 <= i <= 26 else (0.45 if 40 <= i <= 41 else 0.0)
    return (dict(DARK, shot="back", cam={"pos": cam, "look": [-19.5, G + 4.6, 31.0], "fov": 56}, door=swing, exposure=1.9, lightning=lt,
                 flash=fl(cam, [-19.0, G + 4.0, 31.0], 10.0, 0.3)), None)
shot("out", 72, s_back)

# 4. the flashlight down on the floor: the wet prints, coming in
def s_prints(i, k):
    cam = add([-20.6, G + 5.3, 8.0], hand(i, 0.5))
    tgt = lerp([-20.6, G, 25.0], [-20.6, G, 13.0], ease(k))
    return (dict(DARK, shot="kitchen", cam={"pos": cam, "look": lerp([-20.6, G + 0.4, 24.0], [-20.6, G + 0.6, 14.0], ease(k)), "fov": 56},
                 flash=fl(cam, tgt, 15.0, 0.32), exposure=2.0, door=0.0, hideExtras=SHUT), None)
shot("prints", 33, s_prints)

# 5. through the dark house: it stands in the living room by the cold fireplace, head laid over
HIM = [-31.0, G, -16.0]
def s_far(i, k):
    cam = add([-21.0, G + EYE, 4.0 - 2.0 * ease(k)], hand(i, 0.5))
    lt = 1.0 if 30 <= i <= 32 else 0.0
    return (dict(DARK, shot="living", cam={"pos": cam, "look": [-30.6, G + 5.4, -16.0], "fov": 40},
                 flash=fl(cam, [-31.0, G + 4.0, -16.0], 8.0, 0.2), exposure=1.9, lightning=lt, glow=6),
            {"pos": HIM, "yaw": facing(HIM, cam), "gait": "Stare", "t": stop(i, 8) + 1.0, "jaw": 0.06})
shot("far", 90, s_far)

# 6. closer: its face in the light, and its mouth slowly opening
def s_smile(i, k):
    cam = add([-28.6, G + EYE + 0.4, -9.0], hand(i, 0.5))
    jaw = 0.05 + 0.95 * ease(min(1.0, max(0.0, (k - 0.15) / 0.75)))
    jaw = math.floor(jaw * 9) / 9  # (stop-motion)
    return (dict(DARK, shot="living", cam={"pos": cam, "look": [-31.0, G + 8.9, -16.2], "fov": 22},
                 flash=fl(cam, [-31.0, G + 8.9, -16.0], 11.0, 0.16), exposure=2.0, glow=7),
            {"pos": HIM, "yaw": facing(HIM, cam), "gait": "Stare", "t": stop(i, 8) + 4.0, "jaw": jaw, "neck": [-0.1, 0.0, -0.75]})
shot("smile", 60, s_smile)

# 7. behind the living-room curtain: step in, turn round, the fabric at the edge of the view
def s_in(i, k):
    a = ease(min(1.0, k / 0.5))
    cam = lerp([-33.0, G + EYE, -20.0], [-36.6, G + EYE - 0.4, -27.8], a)
    cam = lerp(cam, PEEK_EYE, ease((k - 0.5) / 0.35))
    turn = ease((k - 0.2) / 0.5)
    look = lerp([-37.0, G + 4.6, -32.0], PEEK_LOOK, turn)
    return (dict(DARK, shot="curtain", cam={"pos": add(cam, hand(i, 0.7)), "look": look, "fov": 64}, exposure=2.2, door=0.0,
                 flash=fl(cam, look, 10.0 * (1 - ease((k - 0.5) / 0.3)), 0.45)), None)
shot("in", 60, s_in)

def peek(i, extra=None, door=0.0):
    fr = dict(DARK, shot="curtain", cam={"pos": [PEEK_EYE[0], PEEK_EYE[1] + 0.03 * math.sin(i * 0.31), PEEK_EYE[2]], "look": PEEK_LOOK, "fov": 62},
              exposure=2.6, glow=5, door=door)
    if extra: fr.update(extra)
    return fr

# 8. past the gap: it creeps along the room, hunched low, sniffing the air
def s_past(i, k):
    x = -28.0 - 9.0 * ease(min(1.0, k * 1.05))
    p = [x, G, -20.0]
    return (peek(i), {"pos": p, "yaw": facing(p, [x - 10, G, -20.0]), "gait": "Search", "phase": (28 + x) * WALK, "t": stop(i),
                      "duck": 0.7, "jaw": 0.2})
shot("past", 60, s_past)

# 9. it stops. turns to the curtain. leans in close... and the curtain is torn away (frame 64: 22.15 s)
# (his feet ~9.5 studs out from the gap: tipped forward from them, his face comes down level with it)
VIEW = [PEEK_LOOK[0] - PEEK_EYE[0], 0, PEEK_LOOK[2] - PEEK_EYE[2]]
VL = math.hypot(VIEW[0], VIEW[2]); VD = [VIEW[0] / VL, VIEW[2] / VL]
STOPAT = [PEEK_EYE[0] + VD[0] * 11.5 - 1.5, G, PEEK_EYE[2] + VD[1] * 11.5]
LEAN = [PEEK_EYE[0] + VD[0] * 9.6, G, PEEK_EYE[2] + VD[1] * 9.6]
SCARE = [PEEK_EYE[0] + VD[0] * 9.0, G, PEEK_EYE[2] + VD[1] * 9.0]
def s_tear(i, k):
    if i < 64:
        if i < 18:
            t = ease(i / 12)
            y0 = facing(STOPAT, [STOPAT[0] - 10, G, STOPAT[2]])
            return (peek(i, {"glow": 5}), {"pos": STOPAT, "yaw": y0 + (facing(STOPAT, PEEK_EYE) - y0) * t, "gait": "Stare", "t": stop(i),
                                           "neck": [0.2 * t, 0.0, -0.6 * t], "jaw": 0.15})
        if i < 44:
            w = math.floor(ease((i - 18) / 20) * 9) / 9
            p = lerp(STOPAT, LEAN, w)
            return (peek(i, {"glow": 6}), {"pos": p, "yaw": facing(p, PEEK_EYE), "gait": "Stare", "t": stop(i), "pitch": -0.97 * w,
                                           "neck": [0.97 * w, 0.0, -0.55 * w - 0.3], "jaw": 0.15 + 0.35 * w})
        # (and then he's gone from the gap: nothing, for a second and a half)
        return (peek(i), None)
    d = ease((i - 64) / 2.0)
    fr = peek(i, {"glow": 10, "exposure": 2.4, "flash": {"i": 10.0, "pos": [PEEK_EYE[0], PEEK_EYE[1] - 0.6, PEEK_EYE[2] + 0.3], "target": [SCARE[0], G + 5.4, SCARE[2] - 6.5], "angle": 0.5}},
              door=-1.6 * d)
    face = [PEEK_EYE[0] + VD[0] * 1.8, G + 5.0, PEEK_EYE[2] + VD[1] * 1.8]
    fr["cam"]["look"] = face
    fr["cam"]["fov"] = 70
    return (fr, {"pos": SCARE, "yaw": facing(SCARE, PEEK_EYE), "gait": "Stare", "t": stop(i), "pitch": -0.97,
                 "neck": [0.97, 0.0, -0.5 + 0.35 * math.sin(i * 1.3)], "jaw": 1.0})
shot("tear", 75, s_tear)

# 10. RUN: down the front hall, looking back: it comes after you on all fours, mouth open
def s_run(i, k):
    cam = [0.6 + 0.25 * math.sin(i * 1.7), G + 3.6 + 0.2 * math.sin(i * 2.3), -22.0]
    z = 2.0 - 13.0 * k
    p = [3.0, G, z]
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [2.6, G + 2.8, z + 2.0], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [2.0 + 1.2 * math.sin(i * 1.3), G + 4.0, z], 18.0, 0.36), exposure=1.7, glow=8),
            {"pos": p, "yaw": facing(p, cam), "gait": "Chase", "phase": k * 14 * RUN, "t": stop(i), "jaw": 0.9})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
