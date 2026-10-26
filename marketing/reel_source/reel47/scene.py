# Reel 47 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #2" (the new run, after #1 = reel 46): #2's exact format, look,
# music and slot lengths. The chapter after "tonight he's coming down": he comes into my room at night. My door open,
# wet footprints to my bed, a photo of me sleeping on my pillow; so we set up a camera; 3:12 am on the footage, the
# door opens, he stands over the bed all night... and he knew about the camera (he turns to it and comes at the lens).
#   hook (105)  Jamie's room, lamps and fairy lights on, cosy
#   card (120)  the same room in the moonlight, a slow push to the bed
#   72  "night 10: my door was open."                 from the bed: the bedroom door ajar on the dark hall
#   33  "night 11: wet footprints. to my bed."        the flashlight on the floor: prints from the door to the bed
#   90  "night 12: a photo on my pillow."             the flashlight on the pillow: a polaroid, face down... of me asleep
#   60  "so we set up a camera."                      the little camera on the bookcase, its red light on
#   60  "3:12 am."                                    the camera's view (high, in the corner): the door swings open
#   60  "he stood there all night."                   the camera's view: him bent over the bed
#   75  "he knew about the camera."                   his head turns up to the lens... he comes at it (22.15 s)
#   30  "RUN."                                        out the door into the hall, him after you
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau), shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.5
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

COLD, MOON, RED = "#3d4f7a", "#6f86c4", "#ff2a2a"
# --- Jamie's room (World/Interior): x -40..-8, z ~10..30, floor U; the bed x -39.15..-31.35, z 13.3..18.3 (headboard at
# -x, pillows at x -38.1); the door in the x = -8 wall at z 24 (hinge z 21.57, it swings into the room); the bookcase
# in the corner at x -38.55, z 27.4 (7 high); the desk at x -31.5, z 27.6
JDOOR = {"near": [-8.0, U + 4.7, 24.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, 21.57], "axis": "y"}
PILLOW = [-37.9, U + 4.15, 15.8]
CAMPROP = [-38.35, U + 7.28, 27.0]          # the little camera on the bookcase
CCTV = [-38.4, U + 10.2, 28.6]               # its view: high in the corner
MOONLIT = [{"p": [-24, U + 8.5, 28.6], "col": MOON, "b": 3.4, "r": 24, "decay": 1.0}, {"p": [-38.5, U + 8, 12], "col": MOON, "b": 2.2, "r": 18},
           {"p": [-14, U + 8, 14], "col": COLD, "b": 1.2, "r": 16}]
HALL = [{"p": [-3.5, U + 8, 24], "col": COLD, "b": 2.0, "r": 14, "decay": 1.2}]
BEDMOON = [{"p": [-35.5, U + 8.0, 21.5], "col": MOON, "b": 3.0, "r": 14, "decay": 1.0}, {"p": [-30.0, U + 7.0, 14.0], "col": COLD, "b": 1.6, "r": 12}]
REDDOT = [{"p": [CAMPROP[0] + 0.3, CAMPROP[1] + 0.2, CAMPROP[2] - 0.5], "col": RED, "b": 0.6, "r": 2.5, "decay": 2.0}]
SHOTS = {
    "lit": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 30, "maxLamps": 8, "door": JDOOR},
    "dark": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + HALL, "door": JDOOR},
    "cam": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + HALL + REDDOT + BEDMOON, "door": JDOOR},
    "hall": {"center": [-10, U + 5, 20], "radius": 32, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + HALL + [{"p": [2, U + 9, 10], "col": MOON, "b": 2.0, "r": 22}], "door": JDOOR},
}
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}

# --- props (film2 extras): the wet prints, the photo on the pillow, the camera on the bookcase
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
PRINTS, PHOTO, CAMERA = [], [], []
WET = [24, 20, 18]
FROM, TO, STRIDE = [-9.6, 23.4], [-31.0, 19.0], 2.3
dx, dz = TO[0] - FROM[0], TO[1] - FROM[1]
L = math.hypot(dx, dz); fx, fz = dx / L, dz / L
rx, rz = -fz, fx
pyaw = math.atan2(-fx, -fz)
def rot(x, z, a): return [x * math.cos(a) + z * math.sin(a), -x * math.sin(a) + z * math.cos(a)]
d_, n_ = 0.8, 0
while d_ < L - 0.3:
    side = -1 if n_ % 2 == 0 else 1
    cx, cz = FROM[0] + fx * d_ + rx * side * 0.42, FROM[1] + fz * d_ + rz * side * 0.42
    for (lx, lz, sx, sz) in [(0, 0.05, 0.34, 0.9), (0, 0.45, 0.4, 0.34)]:
        o = rot(lx, lz, pyaw)
        ex(PRINTS, {"pos": [cx + o[0], U + 0.13, cz + o[1]], "s": [sx, 0.02, sz], "rot": [0, pyaw, 0], "col": WET, "rough": 0.25})
    for k2, a in enumerate([-0.32, 0.0, 0.32]):
        o = rot(0, -0.66 - (0.06 if k2 == 1 else 0), pyaw - a)
        ex(PRINTS, {"pos": [cx + o[0], U + 0.13, cz + o[1]], "s": [0.09, 0.02, 0.46], "rot": [0, pyaw - a, 0], "col": WET, "rough": 0.25})
    d_ += STRIDE; n_ += 1
# the polaroid on the pillow: a white card, the dark photo of the bed (me, asleep) on it
ex(PHOTO, {"pos": [PILLOW[0] + 0.55, PILLOW[1] + 0.06, PILLOW[2] - 0.3], "s": [0.6, 0.03, 0.72], "rot": [0.05, 0.5, 0.0], "col": [244, 242, 236], "rough": 0.6})
ex(PHOTO, {"pos": [PILLOW[0] + 0.57, PILLOW[1] + 0.08, PILLOW[2] - 0.33], "s": [0.5, 0.02, 0.48], "rot": [0.05, 0.5, 0.0], "col": [38, 44, 62], "rough": 0.3})
ex(PHOTO, {"pos": [PILLOW[0] + 0.55, PILLOW[1] + 0.095, PILLOW[2] - 0.36], "s": [0.26, 0.01, 0.14], "rot": [0.05, 0.5, 0.0], "col": [120, 128, 150], "rough": 0.3})
# the camera: a small black body, a lens, the red light
ex(CAMERA, {"pos": CAMPROP, "s": [0.7, 0.5, 0.9], "rot": [0, 0.75, 0], "col": [20, 20, 22], "rough": 0.4})
ex(CAMERA, {"pos": [CAMPROP[0] + 0.32, CAMPROP[1], CAMPROP[2] - 0.38], "s": [0.32, 0.32, 0.25], "shape": "cyl", "rot": [math.pi / 2, 0.75, 0], "col": [10, 10, 12], "rough": 0.1})
ex(CAMERA, {"pos": [CAMPROP[0] + 0.12, CAMPROP[1] + 0.2, CAMPROP[2] - 0.42], "s": [0.07, 0.07, 0.07], "col": [255, 30, 30], "rough": 0.1})
ALL = set(range(len(extras)))
def only(*groups):
    keep = set().union(*[set(g) for g in groups]) if groups else set()
    return sorted(ALL - keep)

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

# 1. (hook) Jamie's room, lamps and fairy lights on: cosy
def s_hook(i, k):
    cam = add(lerp([-12.5, U + 6.2, 21.0], [-14.0, U + 6.0, 20.6], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([-34.0, U + 3.4, 17.0], [-34.5, U + 3.3, 16.8], ease(k)), "fov": 60}, door=0.0, hideIdx=only()), None)
shot("hook", 105, s_hook)

# 2. (card) the same room in the moonlight, a slow push to the bed
def s_card(i, k):
    cam = add(lerp([-12.0, U + 6.4, 21.5], [-16.0, U + 6.0, 20.2], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="dark", cam={"pos": cam, "look": [-35.0, U + 3.2, 16.4], "fov": 60}, exposure=3.6, lamps=0, door=0.0, hideIdx=only()), None)
shot("card", 120, s_card)

# 3. "night 10: my door was open." from the bed (lying down): the door ajar on the dark hall
def s_door(i, k):
    cam = add([-37.2, U + 4.6, 15.4], hand(i, 0.25))
    look = lerp([-9.0, U + 4.6, 22.6], [-9.0, U + 4.8, 23.2], ease(k))
    return (dict(DARK, shot="dark", cam={"pos": cam, "look": look, "fov": 42}, exposure=3.2, lamps=0, door=0.55, hideIdx=only()), None)
shot("door", 72, s_door)

# 4. "night 11: wet footprints. to my bed." the flashlight on the floor: the prints from the door to the bed
def s_prints(i, k):
    cam = add(lerp([-33.0, U + 5.4, 20.6], [-32.4, U + 5.3, 20.6], ease(k)), hand(i, 0.4))
    tgt = lerp([-17.0, U, 22.3], [-28.0, U, 20.0], ease(k))
    return (dict(DARK, shot="dark", cam={"pos": cam, "look": [-21.0, U + 0.4, 21.6], "fov": 56}, exposure=2.6, lamps=0, door=0.55, hideIdx=only(PRINTS),
                 flash=fl(cam, tgt, 6.0, 0.45)), None)
shot("prints", 33, s_prints)

# 5. "night 12: a photo on my pillow." sitting up: the flashlight finds it on the pillow... and closer
def s_photo(i, k):
    cam = add(lerp([-34.6, U + 5.6, 15.6], [-35.9, U + 5.3, 15.5], ease(k)), hand(i, 0.4))
    look = lerp([-37.6, U + 4.0, 15.6], [-37.4, U + 4.1, 15.5], ease(k))
    return (dict(DARK, shot="dark", cam={"pos": cam, "look": look, "fov": 50 - 8 * ease(k)}, exposure=2.4, lamps=0, door=0.55, hideIdx=only(PHOTO),
                 flash=fl(cam, look, 3.6, 0.4)), None)
shot("photo", 90, s_photo)

# 6. "so we set up a camera." the little camera on the bookcase, its red light on
def s_setup(i, k):
    cam = add(lerp([-34.0, U + 6.8, 23.4], [-34.8, U + 6.9, 24.2], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="cam", cam={"pos": cam, "look": CAMPROP, "fov": 44}, exposure=2.8, lamps=0, door=0.0, hideIdx=only(CAMERA),
                 flash=fl(cam, CAMPROP, 5.0, 0.4)), None)
shot("setup", 60, s_setup)

# the camera's view: high in the corner, still, a little wide
CCLOOK = [-31.5, U + 1.2, 18.0]
def cctv(extra=None):
    fr = dict(DARK, shot="cam", cam={"pos": CCTV, "look": CCLOOK, "fov": 88}, exposure=4.6, lamps=0, door=0.0, hideIdx=only(CAMERA))
    if extra: fr.update(extra)
    return fr

# 7. "3:12 am." the camera's view: the door swings open, slowly. nobody there
def s_312(i, k):
    # (the camera's other view: the door, across the room)
    return (cctv({"door": 1.25 * ease(k * 1.4), "cam": {"pos": CCTV, "look": [-12.0, U + 2.6, 23.0], "fov": 70}}), None)
shot("open", 60, s_312)

# 8. "he stood there all night." the camera's view: him bent over the bed, still (now and then a twitch)
OVER = [-35.4, U, 20.0]
def s_stood(i, k):
    return (cctv({"door": 1.25, "glow": 1.4}), him(OVER, facing(OVER, [-38.0, U, 16.0]), "Stare", t=4.0 + stop(i), Duck=1.0, Look=[0.0, -0.55]))
shot("stood", 60, s_stood)

# 9. "he knew about the camera." his head turns up to the lens... still... then he comes at it, jaw open, on 22.15 s
# (frame 64)
NEAR = [-37.4, U, 25.2]
def s_knew(i, k):
    if i < 64:
        turn = ease((i - 8) / 26)
        y0, y1 = facing(OVER, [-38.0, U, 16.0]), facing(OVER, CCTV)
        cr = him(OVER, y0 + wrap(y1 - y0) * turn, "Stare", t=4.0 + stop(i), Duck=1.0 - 0.6 * turn, Look=[0.0, -0.55 + 1.0 * turn],
                 Scream=0.12 * ease((i - 54) / 10))
        return (cctv({"door": 1.25, "glow": 1.4 + 1.0 * turn}), cr)
    w = ease((i - 64) / 5)
    p = lerp(OVER, NEAR, w)
    cr = him(p, facing(p, CCTV), "Reach", t=4.0 + i / FPS, Scream=1.0, Look=[0.0, 0.5])
    return (cctv({"door": 1.25, "glow": 5.0, "cam": {"pos": add(CCTV, [0.03 * math.sin(i * 2.1), 0.03 * math.sin(i * 1.7), 0]), "look": lerp(CCLOOK, [p[0], U + 8.0, p[2]], w), "fov": 88 - 20 * w}}), cr)
shot("knew", 75, s_knew)

# 10. RUN: out the bedroom door into the hall, looking back: he comes after you on all fours
def s_run(i, k):
    cam = [-14.0 + 10.0 * k + 0.25 * math.sin(i * 1.7), U + 5.0 + 0.2 * math.sin(i * 2.3), 24.0]
    hp = lerp([-27.0, U, 21.5], [-17.5, U, 23.5], k)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [hp[0], U + 2.8, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)}, door=1.3,
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), U + 3.2, hp[2]], 16.0, 0.36), ambient=0.01, exposure=2.0, glow=6, hideIdx=only()),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
