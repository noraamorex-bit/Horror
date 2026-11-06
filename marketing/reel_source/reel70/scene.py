# Reel 70 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 8)": the PEAK run on #2's track, in the v145 house. Dad's
# office (navy damask over walnut panels, his desk, the bookcases). From the lit front hall, the office door; it creaks open
# on the dark room, his desk lamp on. Behind the desk something rises: his mask, then all of him. He comes over the desk.
# Backing out into the hall, him through the doorway after you. In the coat closet, watching through the crack: he comes out
# of the office, low, and stops; he turns to the closet and his mask comes right up to the crack. He backs off... the door
# is torn open (22.15 s). RUN.
#   hook (105)  the front hall, lit: the office door at the end of it
#   card (120)  the door creaks open: the dark office, the desk lamp (played at 0.64)
#   72          behind the desk, his mask rises into the lamplight, then all of him
#   33          he comes over the desk at you
#   90          backing out into the hall: him through the doorway after you
#   60          in the coat closet: the hall through the crack, the office door open
#   60          he comes out of the office, low, sniffing
#   60          he stops, turns to the closet; his mask comes right up to the crack
#   75          he backs off; silence... the door torn open, him there (22.15 s)
#   30          RUN down the hall, him after you
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau + mask.json), shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
TAU = math.tau
S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]
def wrap(a): return ((a + math.pi) % TAU) - math.pi
def stop(i, fps=13): return math.floor(i * fps / 30) / fps
def him(pos, yaw, gait="Stare", phase=0.0, t=0.0, **opts):
    return {"pos": {"x": pos[0], "y": pos[1], "z": pos[2]}, "yaw": yaw, "gait": gait, "phase": phase, "t": t, "seed": 4, "opts": opts}

COLD, MOON, LAMP = "#3d4f7a", "#6f86c4", "#ffc48a"
HIDE = ["CandyWrap", "CandyBody"]
# Dad's office: x 12..40, z -30..-10; its door in the x = 12 wall at z -20 (hinged at z -22.45, it swings into the office)
ODOOR = {"near": [12.0, G + 4.7, -20.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [12.0, 0, -22.45], "axis": "y"}
OPEN = -1.45
# the front hall's coat closet: x 9.2..11.35, z -17.1..-11.7, its doors face the hall (x 9.32); the south leaf hinged at z -17.0
CLEAF = {"near": [9.32, G + 4.5, -13.1], "r": 1.6, "names": ["WardrobeLeaf", "DoorPanel", "PanelInset", "Handle"], "hinge": [9.32, 0, -11.8], "axis": "y"}
OFFICE = [{"p": [32.0, G + 4.6, -23.6], "col": LAMP, "b": 2.2, "r": 16}, {"p": [43, G + 8, -20], "col": MOON, "b": 2.2, "r": 26, "decay": 1.0},
          {"p": [26, G + 8, -33], "col": MOON, "b": 1.8, "r": 22, "decay": 1.0}, {"p": [20, G + 7, -14], "col": COLD, "b": 0.8, "r": 14}]
HALL = [{"p": [2, G + 8, -33], "col": MOON, "b": 2.6, "r": 32, "decay": 1.0}, {"p": [16, G + 5, -21], "col": LAMP, "b": 1.3, "r": 14},
        {"p": [0, G + 7, -10], "col": COLD, "b": 1.2, "r": 18}, {"p": [4.5, G + 7, -16.5], "col": MOON, "b": 1.8, "r": 14},
        {"p": [7.0, G + 7, -21.5], "col": "#ffd8a8", "b": 1.0, "r": 10}, {"p": [10.8, G + 4, -20.0], "col": LAMP, "b": 1.2, "r": 9}]
SHOTS = {
    "lit": {"center": [4, G + 5, -16], "radius": 36, "lampRadius": 36, "maxLamps": 12, "door": ODOOR},
    "office": {"center": [24, G + 5, -20], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": OFFICE, "door": ODOOR},
    "hallO": {"center": [8, G + 5, -18], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": HALL + OFFICE[:1], "door": ODOOR},
    "closet": {"center": [6, G + 5, -16], "radius": 32, "lampRadius": 0, "maxLamps": 0, "lights": HALL, "door": CLEAF, "door2": ODOOR},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + HIDE
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.2, "lamps": 1}

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
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}

# 1. (hook) the front hall, lit; the office door at the end of it
def s_hook(i, k):
    cam = add(lerp([-1.5, G + 6.0, -27.0], [4.0, G + 5.6, -22.6], ease(k)), hand(i, 0.5))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([12.0, G + 5.8, -18.0], [12.0, G + 4.9, -20.0], ease(k)), "fov": 72}, door=0.0), None)
shot("hook", 105, s_hook)

# 2. (card) the door creaks open on the dark office, the desk lamp on
def s_card(i, k):
    cam = add(lerp([4.0, G + 5.6, -22.6], [9.6, G + 5.4, -20.2], ease(k)), hand(i, 0.4))
    d = OPEN * ease((i - 10) / 60)
    look = lerp([12.0, G + 4.6, -20.0], [32.0, G + 3.8, -22.0], ease((i - 30) / 70))
    return (dict(DARK, shot="hallO", cam={"pos": cam, "look": look, "fov": 58}, exposure=4.0, door=d), None)
shot("card", 120, s_card)

# 3. behind the desk, his mask rises into the lamplight, then the rest of him
BEHIND = [36.0, G, -18.8]
CAM3 = [14.0, G + 5.3, -20.2]
def s_far(i, k):
    cam = add(lerp(CAM3, [15.5, G + 5.3, -20.4], ease(k)), hand(i, 0.3))
    duck = 4.8 - 3.8 * ease((stop(i) * 30 - 8) / 50)
    return (dict(DARK, shot="office", cam={"pos": cam, "look": [33.5, G + 4.2, -20.0], "fov": 40 - 6 * ease(k)}, exposure=3.0, door=OPEN, glow=2.0),
            him(BEHIND, facing(BEHIND, cam), "Stare", t=2.0 + stop(i), Duck=duck, Look=[0.0, -0.2]))
shot("far", 72, s_far)

# 4. he comes over the desk at you
def s_comes(i, k):
    cam = add([15.5, G + 5.3, -20.4], [0.08 * math.sin(i * 1.9) * k, 0.06 * math.sin(i * 2.3) * k, 0])
    x = 36.0 - 16.0 * k
    lift = 2.8 * math.sin(math.pi * max(0.0, min(1.0, (36.0 - x) / 7.0)))
    p = [x, G + lift, -18.8 - 1.2 * k]
    return (dict(DARK, shot="office", cam={"pos": cam, "look": [p[0], p[1] + 2.6, p[2]], "fov": 46 + 10 * k}, exposure=2.8, door=OPEN, glow=3.0,
                 flash=fl(cam, [p[0], p[1] + 2.2, p[2]], 12.0, 0.24)),
            him(p, facing(p, cam), "Chase", phase=0.9 + k * 3.2 * TAU, t=4.0 + i / FPS))
shot("comes", 33, s_comes)

# 5. backing out of the doorway into the hall, looking back: he comes through the door after you
def s_chase(i, k):
    cx = 14.5 - 11.0 * k
    cam = [cx + 0.2 * math.sin(i * 1.7), G + 5.0 + 0.18 * math.sin(i * 2.3), -20.0 + 1.8 * k]
    hx = 21.0 - 13.5 * k
    hp = [hx, G, -20.6 + 1.0 * k]
    return (dict(DARK, shot="hallO", cam={"pos": cam, "look": [hp[0], G + 2.6, hp[2]], "fov": 66, "roll": 0.05 * math.sin(i * 0.9)}, exposure=2.6,
                 door=OPEN, glow=4.0, flash=fl(cam, [hp[0] + 0.5 * math.sin(i * 1.3), G + 2.6, hp[2]], 14.0, 0.36)),
            him(hp, facing(hp, cam), "Chase", phase=k * 9.0 * TAU, t=5.0 + i / FPS))
shot("chase", 90, s_chase)

# 6. in the coat closet: the hall through the crack, the office door open, its lamplight
CRACK = [9.62, G + 5.2, -14.0]
LOOK6 = [3.5, G + 4.0, -16.2]
CRACK_OPEN = 0.5
def s_corner(i, k):
    cam = add(CRACK, hand(i, 0.15 + 0.1 * math.sin(i * 0.3) ** 2))
    return (dict(DARK, shot="closet", cam={"pos": cam, "look": LOOK6, "fov": 56}, exposure=7.0, door=CRACK_OPEN, door2=OPEN), None)
shot("corner", 60, s_corner)

# 7. he comes out of the office, low, sniffing, into the hall
def s_door(i, k):
    cam = add(CRACK, hand(i, 0.2))
    w = ease(i / 59)
    p = lerp([7.8, G, -21.5], [4.4, G, -15.0], w)
    return (dict(DARK, shot="closet", cam={"pos": cam, "look": lerp(LOOK6, [p[0], G + 2.4, p[2]], 0.5), "fov": 56}, exposure=7.0, door=CRACK_OPEN, door2=OPEN, glow=1.6),
            him(p, facing(p, [p[0] - 4, G, p[2] + 1]), "Chase", phase=w * 1.6 * TAU, t=6.0 + stop(i)))
shot("door", 60, s_door)

# 8. he stops, turns to the closet; his mask comes right up to the crack
AT = [4.4, G, -15.0]
GAP = [4.0, G, -14.6]
def s_in(i, k):
    cam = add(CRACK, hand(i, 0.2))
    if i < 22:
        turn = ease((stop(i) * 30 - 4) / 14)
        y0, y1 = facing(AT, [AT[0] - 4, G, AT[2] + 1]), facing(AT, CRACK)
        cr = him(AT, y0 + wrap(y1 - y0) * turn, "Chase", phase=1.6 * TAU, t=7.0 + stop(i))
        look = lerp(LOOK6, [AT[0], G + 2.4, AT[2]], 0.6)
    else:
        w = ease((i - 22) / 30)
        p = lerp(AT, GAP, w)
        cr = him(p, facing(p, CRACK), "Stare", t=7.6 + stop(i), Duck=2.4 * w, Look=[0.0, -0.3 * w])
        look = lerp(lerp(LOOK6, [AT[0], G + 2.4, AT[2]], 0.6), [GAP[0], G + 4.4, GAP[2]], w)
    return (dict(DARK, shot="closet", cam={"pos": cam, "look": look, "fov": 56}, exposure=7.0, door=CRACK_OPEN, door2=OPEN, glow=1.8), cr)
shot("in", 60, s_in)

# 9. he backs off out of sight; silence at the crack... on 22.15 s (frame 65) the door is torn open: he's right there
def s_knew(i, k):
    cam = add(CRACK, hand(i, 0.2))
    if i < 65:
        w = ease(i / 26)
        p = lerp(GAP, [3.0, G, -18.5], w)
        cr = him(p, facing(p, CRACK), "Stare", t=9.0 + stop(i), Duck=2.4 * (1 - w)) if i < 30 else None
        return (dict(DARK, shot="closet", cam={"pos": cam, "look": [GAP[0], G + 4.4, GAP[2]], "fov": 56}, exposure=7.0, door=CRACK_OPEN, door2=OPEN, glow=1.4 if i < 30 else 0.0), cr)
    w = ease((i - 65) / 4)
    camw = add(cam, [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    p = [4.0, G, -14.6]
    return (dict(DARK, shot="closet", cam={"pos": camw, "look": [p[0] + 0.8 * w, G + 4.2 - 1.9 * w, p[2]], "fov": 60 + 10 * w}, exposure=4.0, door=CRACK_OPEN + (1.6 - CRACK_OPEN) * w, door2=OPEN, glow=6.0,
                 flash=fl(camw, [p[0], G + 4.6, p[2]], 2.0 * w, 0.5)),
            him(p, facing(p, CRACK), "Reach", t=3.0 + i / FPS, Scream=1.0, Duck=2.2, Look=[0.0, 0.45]))
shot("knew", 75, s_knew)

# 10. RUN: out of the closet and down the hall towards the front door, looking back: he comes after you
def s_run(i, k):
    c = lerp([7.5, 0, -18.5], [4.0, 0, -26.0], k)
    cam = [c[0] + 0.25 * math.sin(i * 1.7), G + 5.0 + 0.2 * math.sin(i * 2.3), c[2]]
    hp = lerp([8.0, G, -14.6], [6.0, G, -20.0], k)
    return (dict(DARK, shot="closet", cam={"pos": cam, "look": [hp[0], G + 2.6, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)}, door=1.6, door2=OPEN,
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), G + 2.8, hp[2]], 14.0, 0.36), exposure=2.4, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": [],
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
