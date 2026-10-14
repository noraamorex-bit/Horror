# Reel 25 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 3)": Part 2's format on #2's track
# again (every clip keeps #2's length, so the track's cuts and hits land). The story this time:
# hiding in the linen closet in the upstairs hall, watching him through the crack in the doors.
#   hook (105)  the upstairs hall in the dark, the flashlight finding the attic hatch and its cord
#   card (120)  Lily's room: the nightlight and the fairy lights, nobody in the bed
#   72          down the hall in a lightning flash: someone standing at the far end
#   33          the hall lights flicker and die
#   90          into the closet: the door pulled almost shut, a crack of the hall left
#   60          through the crack: he walks past
#   60          he stops, and turns to the closet
#   60          he leans in, his face at the crack
#   75          he backs away... silence... and the door is torn open (the scare at 22.15 s)
#   30          RUN: he comes up the stairs after you
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
# the linen closet: its left door (the one nearer the stairs) swings on a hinge at z = -3.6
# (the line of sight runs through the gap between the two doors' free edges)
CLOSET_EYE = [10.38, U + 4.9, -5.66]
CLOSET_LOOK = [2.0, U + 6.2, -6.8]
DOOR = {"near": [9.25, U + 4.5, -4.8], "r": 2.3, "names": ["WardrobeLeaf", "DoorPanel", "PanelInset"], "hinge": [9.32, 0, -3.6], "axis": "y"}
CRACK = 0.45
HALL_LIGHTS = [{"p": [2, U + 11, -29], "col": "#6f86c4", "b": 3.2, "r": 30, "decay": 1.1},          # moonlight, the hall window
               {"p": [2.5, U + 9, -9], "col": "#5d72a8", "b": 3.0, "r": 20},
               {"p": [5, U + 7, -3], "col": COLD, "b": 1.2, "r": 12}]
SHOTS = {
    "hall": {"center": [2, U + 6, 0], "radius": 40, "lampRadius": 0, "maxLamps": 0,
             "lights": [{"p": [2, U + 11, -29], "col": "#6f86c4", "b": 2.4, "r": 30, "decay": 1.1}]},
    "lily": {"center": [26, U + 6, 19], "radius": 30, "lampRadius": 0, "maxLamps": 0,
             "lights": [{"p": [31, U + 1.8, 28.4], "col": "#ffb46a", "b": 5.0, "r": 13, "decay": 1.3},   # the nightlight
                        {"p": [32, U + 9.5, 28.6], "col": "#ffcf8a", "b": 1.6, "r": 14},                 # the fairy lights
                        {"p": [26, U + 9, 10], "col": COLD, "b": 0.9, "r": 16}]},
    "hallFar": {"center": [2, U + 6, -4], "radius": 46, "lampRadius": 0, "maxLamps": 0,
                "lights": [{"p": [2, U + 11, -29], "col": "#6f86c4", "b": 1.8, "r": 26, "decay": 1.1}]},
    "hallOn": {"center": [2, U + 6, 0], "radius": 40, "lampRadius": 40, "maxLamps": 8, "lights": []},
    "closet": {"center": [6, U + 5, -6], "radius": 30, "lampRadius": 0, "maxLamps": 0, "hide": ["Handle"], "door": DOOR,
               "lights": HALL_LIGHTS},
    "stairs": {"center": [-5, U - 2, 8], "radius": 40, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [-5, U + 6, 22], "col": "#2c3d6e", "b": 1.3, "r": 26}, {"p": [-5, 8, -2], "col": COLD, "b": 1.2, "r": 18}]},
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

# 1. (hook) the upstairs hall: a slow push, the flashlight climbing to the attic hatch
def s_hook(i, k):
    cam = add(lerp([3.0, U + EYE, -14.0], [3.4, U + EYE - 0.2, -6.0], ease(k)), hand(i))
    tgt = lerp([2.0, U + 0.5, 2.0], [6.0, U + 12.6, 11.0], ease(min(1.0, k * 1.2)))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": lerp([3.0, U + 4.0, 8.0], [5.6, U + 9.5, 11.0], ease(k)), "fov": 62},
                 flash={"i": 13.0, "pos": [cam[0] + 0.5, cam[1] - 0.6, cam[2]], "target": tgt, "angle": 0.34}, exposure=1.9), None)
shot("hook", 105, s_hook)

# 2. (card) Lily's room: the nightlight, the fairy lights
def s_lily(i, k):
    cam = add(lerp([15.8, U + EYE, 12.6], [17.3, U + EYE - 0.3, 14.6], ease(k)), hand(i, 0.6))
    return (dict(DARK, shot="lily", cam={"pos": cam, "look": [29.0, U + 3.0, 27.0], "fov": 62}, exposure=2.3), None)
shot("card", 120, s_lily)

# 3. down the hall in a lightning flash: someone at the far end
HIM_FAR = [2.5, U, -25.5]
def s_far(i, k):
    cam = add([2.5, U + EYE, 16.0], hand(i, 0.5))
    lt = 1.0 if 18 <= i <= 21 else (0.55 if 50 <= i <= 52 else 0.0)
    return (dict(DARK, shot="hallFar", cam={"pos": cam, "look": [2.5, U + 4.4, -25.0], "fov": 48}, exposure=1.8, lightning=lt, glow=6),
            {"pos": HIM_FAR, "yaw": facing(HIM_FAR, cam), "gait": "Stare", "t": i / 30, "neck": [0.1, 0.0, 0.25]})
shot("far", 72, s_far)

# 4. the hall lights flicker and die
def s_out(i, k):
    on = i < 9 and (i * 7919) % 5 < 3
    return (dict(DARK, shot="hallOn" if on else "hall", cam={"pos": [3.0, U + EYE, 14.0], "look": [4.0, U + 4.0, -20.0], "fov": 62},
                 lamps=1 if on else 0, ambient=0.08 if on else 0.03, exposure=1.3 if on else 2.2, lightning=0.7 if 16 <= i <= 18 else 0), None)
shot("out", 33, s_out)

# 5. into the closet: the door open, step in, turn round, pull it almost shut
def s_in(i, k):
    a = ease(min(1.0, k / 0.5))
    cam = lerp([4.0, U + EYE, -4.8], [10.3, U + EYE - 0.5, -4.9], a)
    cam = lerp(cam, CLOSET_EYE, ease((k - 0.5) / 0.35))
    # facing in (+x), then turning round to the left (through the closet's side, not the doors)
    turn = ease((k - 0.3) / 0.4)
    ang = math.pi * turn                       # 0: looking +x, pi: looking -x
    look = [cam[0] + 6 * math.cos(ang), U + 4.4 + 1.6 * turn, cam[2] + 6 * math.sin(ang) - 1.1 * turn]
    door = 1.75 if k < 0.62 else 1.75 + (CRACK - 1.75) * ease((k - 0.62) / 0.3)
    fl = {"i": 11.0 * (1 - ease((k - 0.45) / 0.3)), "pos": [cam[0] + 0.4, cam[1] - 0.5, cam[2]], "target": [cam[0] + 6 * math.cos(ang), U + 3, cam[2] + 6 * math.sin(ang)], "angle": 0.45}
    return (dict(DARK, shot="closet", cam={"pos": add(cam, hand(i, 0.7)), "look": look, "fov": 64}, exposure=2.2, door=door, flash=fl), None)
shot("in", 90, s_in)

def crack(i, extra=None, door=CRACK):
    fr = dict(DARK, shot="closet", cam={"pos": [CLOSET_EYE[0], CLOSET_EYE[1] + 0.03 * math.sin(i * 0.31), CLOSET_EYE[2]], "look": CLOSET_LOOK, "fov": 58},
              exposure=2.3, glow=4, door=door)
    if extra: fr.update(extra)
    return fr

# 6. through the crack: he walks past, left to right (towards the stairs)
def s_past(i, k):
    z = -16.0 + 9.5 * ease(min(1.0, k * 1.05))
    p = [4.2, U, z]
    return (crack(i), {"pos": p, "yaw": facing(p, [4.2, U, z + 10]), "gait": "Walk" if k < 0.95 else "Stare", "phase": (z + 18) * WALK, "t": i / 30})
shot("past", 60, s_past)

# 7. he stops, and turns to the closet
STOP = [4.2, U, -6.5]
def s_stop(i, k):
    turn = ease(min(1.0, k / 0.45))
    yaw = facing(STOP, [4.2, U, 10]) + (facing(STOP, CLOSET_EYE) - facing(STOP, [4.2, U, 10])) * turn
    return (crack(i, {"glow": 5}), {"pos": STOP, "yaw": yaw, "gait": "Stare", "t": i / 30, "neck": [0.3 * turn, 0.0, 0.3 * turn]})
shot("stop", 60, s_stop)

# 8. he steps up and leans in to the crack
def s_lean(i, k):
    w = ease(k / 0.7)
    p = lerp(STOP, [6.4, U, -6.3], w)
    return (crack(i, {"glow": 6}), {"pos": p, "yaw": facing(p, CLOSET_EYE), "gait": "Stare" if k > 0.6 else "Walk", "phase": w * 3, "t": i / 30,
                                    "duck": 1.0 * w, "neck": [0.2 * w, 0.0, 0.4 * w]})
shot("lean", 60, s_lean)

# 9. he backs off into the dark... nothing... and the door is torn open (22.15 s: frame 64)
def s_tear(i, k):
    if i < 64:
        w = ease(i / 40)
        p = lerp([6.4, U, -6.3], [2.6, U, -13.0], w)
        cr = {"pos": p, "yaw": facing(p, CLOSET_EYE), "gait": "Walk" if 4 < i < 40 else "Stare", "phase": w * 4, "t": i / 30} if i < 46 else None
        return (crack(i), cr)
    d = ease((i - 64) / 2.0)
    p = [6.2, U, -6.4]
    fr = crack(i, {"glow": 10, "exposure": 2.6}, door=CRACK + (2.1 - CRACK) * d)
    fr["cam"]["look"] = [2.0, U + 8.6, -6.8]
    return (fr, {"pos": p, "yaw": facing(p, CLOSET_EYE), "gait": "Reach", "t": i / 30, "duck": 1.0, "neck": [0.0, 0.0, 0.3 * math.sin(i * 0.9)]})
shot("tear", 75, s_tear)

# 10. RUN: from the top of the stairs, and he's coming up them
def s_run(i, k):
    cam = [-5.0 + 0.25 * math.sin(i * 1.7), U + 4.6 + 0.2 * math.sin(i * 2.3), 21.5]
    z = -3.0 + 15.0 * k
    y = 2.05 + 0.625 * (z + 5.3)
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, U - 1.5 + 3.0 * k, 4.0], "fov": 62, "roll": 0.05 * math.sin(i * 0.9)},
                 flash={"i": 18.0, "pos": [cam[0] + 0.6, cam[1] - 0.6, cam[2]], "target": [-5.0 + 1.2 * math.sin(i * 1.3), y + 4.0, z], "angle": 0.36},
                 ambient=0.01, exposure=1.7, glow=8),
            {"pos": [-5.0, y, z], "yaw": facing([-5.0, y, z], [-5.0, y, z + 10]), "gait": "Chase", "phase": k * 15 * RUN, "t": i / 30})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": [],
           "props": {"cache": "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
