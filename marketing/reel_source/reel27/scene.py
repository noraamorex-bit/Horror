# Reel 27 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 5)": Parts 2-4's format on #2's track
# (every clip keeps #2's length, so the track's cuts and hits land). The story this time: the game's
# own big moment. The one bar of signal at the upstairs bathroom window, the 911 call, and hiding in
# the shower: his shape through the curtain, and the curtain ripped open.
#   hook (105)  the upstairs hall in the dark, the flashlight on the bathroom door, ajar
#   card (120)  the bathroom window in the rain: the one place the phone gets a bar
#   72          from the top of the stairs, a lightning flash: him at the bottom, looking up
#   33          the bathroom light flickers and dies
#   90          into the shower, turn round, pull the curtain shut
#   60          through the curtain: the bathroom door swings open, a shape in the doorway
#   60          the shape crosses the bathroom towards the shower
#   60          it stops right outside the curtain, a dark shape against it, head turning
#   75          nothing... and the curtain is ripped open (the scare at 22.15 s)
#   30          RUN: out in the hall, and he's coming out of the bathroom after you
# python3 scene.py [preview]. Writes spec.json, frames_in.json, shots.json.
import json, math, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.6
WALK = math.tau / 5.2
RUN = math.tau / 7.5

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]

COLD = "#3d4f7a"
MOON = "#6f86c4"
# the shower: base x 33.4..39.1, z 3.0..7.6; the curtain hangs at x = 33.3 across it (z 3.05..7.55),
# hinged here at its far end (z = 7.55) so it can be pulled shut and ripped open
CURTAIN_NAMES = ["ShowerCurtain", "CurtainFold"]
CURTAIN = {"near": [33.3, U + 5.5, 5.3], "r": 3.6, "names": CURTAIN_NAMES, "hinge": [33.3, 0, 7.6], "axis": "y"}
SEE_THROUGH = {"names": CURTAIN_NAMES, "near": [33.3, U + 5.5, 5.3], "r": 3.6, "opacity": 0.5}
# the bathroom door: in the hall wall (x = 12) at z = 1, hinged at z = -1.42, swings into the bathroom
BATH_DOOR = {"near": [12.0, U + 4.7, 1.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [12.0, 0, -1.42], "axis": "y"}
SHOWER_EYE = [37.4, U + 5.0, 5.3]
SHOWER_LOOK = [20.0, U + 4.6, 3.0]
BATH_DARK = [{"p": [41.5, U + 7, 1.0], "col": MOON, "b": 2.6, "r": 30, "decay": 1.1},     # moonlight through the window
             {"p": [14.0, U + 7, 1.0], "col": "#5d72a8", "b": 1.8, "r": 16}]               # the hall, through the door
SHOTS = {
    "hall": {"center": [3, U + 6, 6], "radius": 34, "lampRadius": 0, "maxLamps": 0, "door": BATH_DOOR,
             "lights": [{"p": [2, U + 11, 24], "col": MOON, "b": 2.2, "r": 30, "decay": 1.1}, {"p": [20, U + 8, 1], "col": COLD, "b": 1.4, "r": 18}]},
    "window": {"center": [34, U + 5, 1], "radius": 28, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [44, U + 9, 1], "col": MOON, "b": 2.4, "r": 30, "decay": 1.0}, {"p": [30, U + 6, 4], "col": COLD, "b": 0.7, "r": 14}]},
    "stairs": {"center": [-5, G + 6, 4], "radius": 36, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [-5, G + 7, -8], "col": COLD, "b": 1.2, "r": 18}, {"p": [-5, U + 6, 16], "col": "#2c3d6e", "b": 1.0, "r": 20}]},
    "bathOn": {"center": [26, U + 5, 2], "radius": 28, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [25, U + 10, 1.5], "col": "#ffd9a0", "b": 4.0, "r": 30, "decay": 1.0}] + BATH_DARK},
    "bath": {"center": [26, U + 5, 2], "radius": 28, "lampRadius": 0, "maxLamps": 0, "lights": BATH_DARK},
    "shower": {"center": [26, U + 5, 3], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": CURTAIN, "lights": BATH_DARK},
    "behind": {"center": [24, U + 5, 2], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": BATH_DOOR, "translucent": SEE_THROUGH,
               "lights": BATH_DARK + [{"p": [30, U + 8, 3], "col": COLD, "b": 1.4, "r": 12}]},
    "ripped": {"center": [26, U + 5, 3], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": CURTAIN, "translucent": SEE_THROUGH,
               "lights": BATH_DARK + [{"p": [35, U + 9, 5], "col": "#8094cc", "b": 1.6, "r": 14}]},
    "hallRun": {"center": [4, U + 6, 6], "radius": 34, "lampRadius": 0, "maxLamps": 0,
                "lights": [{"p": [2, U + 11, 24], "col": MOON, "b": 1.8, "r": 30, "decay": 1.1}, {"p": [14, U + 7, 1], "col": COLD, "b": 1.6, "r": 16}]},
}
DARK = {"ambient": 0.02, "bg": 0x010102}
frames, crs, shots = [], [], []
f = 0
def shot(name, n, fn):
    global f
    shots.append({"name": name, "start": f, "n": n})
    idx = [0, n // 2, n - 1] if PREVIEW else range(n)
    for i in idx:
        k = i / max(1, n - 1)
        fr, cr = fn(i, k)
        fr["f"] = f + i
        fr["creature"] = cr is not None
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n

# 1. (hook) the upstairs hall: a slow push, the flashlight finding the bathroom door, ajar
def s_hook(i, k):
    cam = add(lerp([2.5, U + EYE, 20.0], [5.0, U + EYE - 0.2, 9.0], ease(k)), hand(i))
    tgt = lerp([6.0, U + 1.5, 8.0], [12.0, U + 4.5, 1.6], ease(min(1.0, k * 1.2)))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": lerp([6.0, U + 3.0, 4.0], [12.0, U + 4.6, 1.0], ease(k)), "fov": 62},
                 flash={"i": 13.0, "pos": [cam[0] + 0.5, cam[1] - 0.6, cam[2]], "target": tgt, "angle": 0.34}, exposure=1.9, door=0.35), None)
shot("hook", 105, s_hook)

# 2. (card) the bathroom window in the rain: the one place the phone gets a bar
def s_window(i, k):
    cam = add(lerp([31.0, U + EYE, -1.5], [34.5, U + EYE - 0.2, 0.0], ease(k)), hand(i, 0.6))
    lt = 0.7 if 30 <= i <= 32 else (0.45 if 88 <= i <= 90 else 0.0)
    return (dict(DARK, shot="window", cam={"pos": cam, "look": [40.0, U + 6.5, 1.0], "fov": 58}, exposure=2.2, lightning=lt, moon=0.22), None)
shot("card", 120, s_window)

# 3. from the top of the stairs, a lightning flash: him at the bottom, looking up
HIM_FOOT = [-5.0, G, -8.5]
def s_far(i, k):
    cam = add([-5.0, U + EYE - 0.4, 17.5], hand(i, 0.5))
    lt = 1.0 if 18 <= i <= 21 else (0.55 if 50 <= i <= 52 else 0.0)
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, G + 4.0, -8.0], "fov": 50}, exposure=1.8, lightning=lt, glow=6),
            {"pos": HIM_FOOT, "yaw": facing(HIM_FOOT, cam), "gait": "Stare", "t": i / 30, "neck": [-0.3, 0.0, 0.2]})
shot("far", 72, s_far)

# 4. the bathroom light flickers and dies
def s_out(i, k):
    on = i < 9 and (i * 7919) % 5 < 3
    return (dict(DARK, shot="bathOn" if on else "bath", cam={"pos": [16.0, U + EYE, -3.5], "look": [36.0, U + 4.0, 5.0], "fov": 62},
                 ambient=0.07 if on else 0.03, exposure=1.4 if on else 2.1), None)
shot("out", 33, s_out)

# 5. into the shower, turn round, pull the curtain shut
def s_in(i, k):
    a = ease(min(1.0, k / 0.5))
    cam = lerp([26.0, U + EYE, 2.6], [36.6, U + EYE - 0.4, 5.3], a)
    turn = ease((k - 0.3) / 0.38)
    ang = math.pi * turn                    # 0: looking +x (into the shower), pi: looking back out (-x)
    look = [cam[0] + 6 * math.cos(ang), U + 4.6, cam[2] + 6 * math.sin(ang) * 0.4]
    curtain = 1.35 if k < 0.66 else 1.35 * (1 - ease((k - 0.66) / 0.28))
    fl = {"i": 10.0 * (1 - ease((k - 0.32) / 0.3)), "pos": [cam[0] + 0.3, cam[1] - 0.5, cam[2] + 0.3], "target": [cam[0] + 6 * math.cos(ang), U + 3.5, cam[2]], "angle": 0.45}
    return (dict(DARK, shot="shower", cam={"pos": add(cam, hand(i, 0.7)), "look": look, "fov": 64}, exposure=2.2, door=curtain, flash=fl), None)
shot("in", 90, s_in)

def behind(i, extra=None, door=1.4):
    fr = dict(DARK, shot="behind", cam={"pos": [SHOWER_EYE[0], SHOWER_EYE[1] + 0.03 * math.sin(i * 0.31), SHOWER_EYE[2]], "look": SHOWER_LOOK, "fov": 60},
              exposure=2.4, glow=4, door=door)
    if extra: fr.update(extra)
    return fr

# 6. through the curtain: the bathroom door swings open, a shape in the doorway
DOORWAY = [13.6, U, 1.0]
def s_door(i, k):
    d = 1.4 * ease(min(1.0, k / 0.55))
    cr = {"pos": DOORWAY, "yaw": facing(DOORWAY, SHOWER_EYE), "gait": "Stare", "t": i / 30, "neck": [0.1, 0.0, 0.25]} if k > 0.4 else None
    return (behind(i, {"glow": 5}, door=d), cr)
shot("door", 60, s_door)

# 7. the shape crosses the bathroom towards the shower
OUTSIDE = [31.6, U, 4.9]
def s_cross(i, k):
    w = ease(min(1.0, k * 1.05))
    p = lerp(DOORWAY, OUTSIDE, w)
    return (behind(i, {"glow": 5}), {"pos": p, "yaw": facing(p, OUTSIDE if w < 0.97 else SHOWER_EYE), "gait": "Walk" if w < 0.97 else "Stare",
                                     "phase": w * 18 * WALK, "t": i / 30})
shot("cross", 60, s_cross)

# 8. right outside the curtain: a dark shape against it, the head slowly turning
def s_stand(i, k):
    lean = ease(k)
    return (behind(i, {"glow": 5}), {"pos": lerp(OUTSIDE, [32.4, U, 5.1], lean), "yaw": facing(OUTSIDE, SHOWER_EYE), "gait": "Stare", "t": i / 30,
                                     "duck": 0.5 * lean, "neck": [0.35 * math.sin(i * 0.06), 0.0, 0.3 + 0.15 * lean]})
shot("stand", 60, s_stand)

# 9. nothing (he's gone quiet)... and the curtain is ripped open (22.15 s: frame 64 of this shot)
REVEAL = [32.6, U, 5.2]
def s_rip(i, k):
    if i < 64:
        fr = behind(i, {"glow": 4, "exposure": 2.5})
        return (fr, {"pos": [32.4, U, 5.1], "yaw": facing(OUTSIDE, SHOWER_EYE), "gait": "Stare", "t": i / 30, "duck": 0.5, "neck": [0.0, 0.0, 0.45]})
    j = i - 64
    rip = 1.6 * ease(j / 2.0)
    fr = dict(DARK, shot="ripped", cam={"pos": SHOWER_EYE, "look": [33.2, U + 6.4, 5.2], "fov": 62}, exposure=2.6, glow=10, door=rip)
    return (fr, {"pos": REVEAL, "yaw": facing(REVEAL, SHOWER_EYE), "gait": "Reach", "t": i / 30, "duck": 1.0, "neck": [0.0, 0.0, 0.3 * math.sin(i * 0.9)]})
shot("rip", 75, s_rip)

# 10. RUN: down the hall, looking back: he's coming out of the bathroom after you
def s_run(i, k):
    cam = [3.0 + 0.25 * math.sin(i * 1.7), U + 4.8 + 0.2 * math.sin(i * 2.3), 16.0 + 3.0 * k]
    p = lerp([12.5, U, 1.0], [5.0, U, 10.0], k)
    return (dict(DARK, shot="hallRun", cam={"pos": cam, "look": [8.0, U + 4.2, 2.0], "fov": 62, "roll": 0.05 * math.sin(i * 0.9)},
                 flash={"i": 18.0, "pos": [cam[0] + 0.6, cam[1] - 0.6, cam[2]], "target": [p[0], U + 4.0, p[2]], "angle": 0.36},
                 ambient=0.01, exposure=1.7, glow=8),
            {"pos": p, "yaw": facing(p, cam), "gait": "Chase", "phase": k * 15 * RUN, "t": i / 30})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": [],
           "props": {"cache": "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
