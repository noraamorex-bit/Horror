# Reel 35 — the "story" format, #3 (typed lines over found footage on #2's track, every clip at #2's
# length, branded throughout). The story is Lily's room and its tea party (the v101 lived-in layer):
#   hook (105)  her dark room, the flashlight over the tea party: two bears, an empty chair
#                 "my little sister / set a place for a guest."
#   card (120)  low and close on the empty chair                       "we thought he was" / "imaginary."
#   72          her music box: the lid lifts by itself, lightning      "her music box opened."
#   33          the bedroom door creaks open on the dark hall          "the door creaked."
#   90          across the room: he's sitting at her tea party, folded up on the floor   "he came for tea."
#   60          close: his head turns to you, the mouth opening        "and he saw me."
#   60          into her play tent, turning to the flap                "so i hid in her tent."
#   60          through the flap: he unfolds and comes across the rug  "he knew i was there."
#   75          he crouches to the flap... his face at the gap (22.15 s)    "don't. move."
#   30          RUN: out in the hall, he comes through her door on all fours   "RUN."
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

COLD, MOON, PINK = "#3d4f7a", "#6f86c4", "#ff9fc4"
TABLE = [24.0, U, 15.2]
SEAT = [24.0, U, 12.3]              # (behind the empty chair, facing the table)
TENT = [20.2, U, 10.6]
TENT_EYE = [20.25, U + 1.75, 11.7]
TENT_LOOK = [22.8, U + 1.9, 16.5]
MUSICBOX = {"near": [18.9, U + 3.09, 28.1], "r": 0.8, "names": ["MusicBoxLid"], "hinge": [0, U + 3.09, 28.53], "axis": "x"}
LILYDOOR = {"near": [12.0, U + 4.7, 20.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [12.0, 0, 17.55], "axis": "y"}
ROOM = [{"p": [13.6, U + 2.2, 27.5], "col": PINK, "b": 1.6, "r": 16, "decay": 1.3},          # her night light
        {"p": [26.0, U + 8.0, 31.5], "col": MOON, "b": 3.4, "r": 24, "decay": 1.1},           # the open window
        {"p": [30.0, U + 8.0, 12.0], "col": COLD, "b": 1.2, "r": 16}]
SHOTS = {
    "room": {"center": [26, U + 5, 19], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": ROOM},
    "box": {"center": [20, U + 4, 26], "radius": 26, "lampRadius": 0, "maxLamps": 0, "door": MUSICBOX, "lights": ROOM},
    "door": {"center": [18, U + 5, 20], "radius": 28, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR,
             "lights": ROOM + [{"p": [6, U + 8, 20], "col": COLD, "b": 1.0, "r": 14}]},
    "hall": {"center": [6, U + 5, 14], "radius": 34, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR,
             "lights": [{"p": [2, U + 11, -10], "col": MOON, "b": 1.8, "r": 26, "decay": 1.1}, {"p": [6, U + 8, 18], "col": COLD, "b": 1.6, "r": 16},
                        {"p": [18, U + 3, 20], "col": PINK, "b": 1.4, "r": 14}]},
}
DARK = {"ambient": 0.04, "bg": 0x010102}

# the flap of her tent, from inside (the store tipi's walls are one-sided: seen from inside they'd vanish)
CANVAS = [226, 214, 190]
extras = []
for sx in (-1, 1):
    extras.append({"pos": [TENT[0] + sx * 1.05, U + 1.8, TENT[2] + 1.75], "s": [0.9, 3.6, 0.05], "rot": [0.0, sx * 0.25, sx * 0.16], "col": CANVAS, "rough": 0.95})

# folded up on the floor at her table: knees by his ears, long arms on the table top
SIT = {"Root": [-0.25, 0, 0, 0, -3.7, 0], "Waist": [-0.35, 0, 0], "LeftHip": [2.0, 0, -0.3], "RightHip": [2.0, 0, 0.3],
       "LeftKnee": [-2.5, 0, 0], "RightKnee": [-2.5, 0, 0], "LeftAnkle": [0.4, 0, 0], "RightAnkle": [0.4, 0, 0],
       "LeftShoulder": [1.35, 0, -0.15], "RightShoulder": [1.45, 0, 0.15], "LeftElbow": [0.8, 0, 0], "RightElbow": [0.95, 0, 0],
       "LeftWrist": [-0.35, 0, 0], "RightWrist": [-0.2, 0, 0]}
def sitting(neck, jaw=0.08, t=1.0):
    j = dict(SIT)
    j["Neck"] = neck
    return {"pos": SEAT, "yaw": facing(SEAT, TABLE), "gait": "Stare", "t": t, "joints": j, "jaw": jaw}

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

# 1. (hook) her dark room from the doorway: the flashlight over the tea party to the empty chair
def s_hook(i, k):
    cam = add(lerp([13.6, U + EYE - 0.2, 21.0], [18.0, U + EYE - 0.6, 19.6], ease(k)), hand(i))
    tgt = lerp([22.3, U + 1.8, 15.2], [24.0, U + 1.4, 13.6], ease(min(1.0, k * 1.25)))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp([22.0, U + 2.0, 15.0], [24.0, U + 1.8, 14.0], ease(k)), "fov": 56},
                 flash=fl(cam, tgt, 11.0), exposure=1.9), None)
shot("hook", 105, s_hook)

# 2. (card) low and close: the empty chair, the little cup set out in front of it
def s_card(i, k):
    cam = add(lerp([25.2, U + 4.2, 19.4], [24.5, U + 3.6, 17.8], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [24.0, U + 1.2, 13.4], "fov": 42},
                 flash=fl(cam, [24.0, U + 1.2, 13.6], 6.0, 0.4), exposure=1.9), None)
shot("card", 120, s_card)

# 3. her music box on the dresser: the lid lifts on its own; lightning
def s_box(i, k):
    cam = add([20.6, U + 4.8, 23.4], hand(i, 0.4))
    lid = 1.4 * ease(min(1.0, max(0.0, (i - 10) / 30)))
    lt = 0.9 if 46 <= i <= 48 else 0.0
    return (dict(DARK, shot="box", cam={"pos": cam, "look": [18.9, U + 2.6, 28.1], "fov": 44}, door=lid, lightning=lt,
                 flash=fl(cam, [18.9, U + 2.8, 28.1], 7.0, 0.3), exposure=1.9), None)
shot("out", 72, s_box)

# 4. her door creaks open on the dark hall
def s_door(i, k):
    cam = add([22.0, U + EYE - 0.4, 22.5], hand(i, 0.4))
    return (dict(DARK, shot="door", cam={"pos": cam, "look": [12.0, U + 4.4, 19.6], "fov": 48}, door=1.2 * ease(k * 1.3),
                 exposure=2.0), None)
shot("prints", 33, s_door)

# 5. across the room, from the foot of her bed: he's sitting at her tea party
def s_far(i, k):
    cam = add([31.0, U + EYE - 0.2, 21.4 - 1.0 * ease(k)], hand(i, 0.5))
    lt = 1.0 if 40 <= i <= 42 else 0.0
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [24.0, U + 2.6, 13.4], "fov": 44}, exposure=1.9, lightning=lt, glow=6,
                 flash=fl(cam, [24.0, U + 2.6, 12.8], 7.0, 0.22)),
            sitting([0.35, 0.0, 0.95], 0.06, stop(i, 8) + 1.0))
shot("far", 90, s_far)

# 6. close: his head turns round to you, and the mouth opens
def s_smile(i, k):
    cam = add([27.6, U + 3.6, 17.6], hand(i, 0.4))
    turn = math.floor(ease(min(1.0, k / 0.6)) * 7) / 7
    jaw = math.floor(ease(max(0.0, (k - 0.45) / 0.5)) * 8) / 8
    # (turning from the table to the camera: the head swings round on the long neck, in jerks)
    ny = 1.25 * turn
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [24.0, U + 4.6, 12.7], "fov": 30}, exposure=2.0, glow=7,
                 flash=fl(cam, [24.0, U + 4.8, 12.6], 9.0, 0.18)),
            sitting([0.35 - 0.2 * turn, ny, 0.95 - 0.6 * turn], 0.06 + 0.94 * jaw, stop(i, 8) + 3.0))
shot("smile", 60, s_smile)

# 7. into her tent: duck in and turn round to the flap
def s_in(i, k):
    a = ease(min(1.0, k / 0.55))
    cam = lerp([22.4, U + EYE - 0.6, 15.0], [20.4, U + 2.2, 11.2], a)
    cam = lerp(cam, TENT_EYE, ease((k - 0.55) / 0.3))
    turn = ease((k - 0.25) / 0.5)
    look = lerp([19.6, U + 1.4, 8.0], TENT_LOOK, turn)
    return (dict(DARK, shot="room", cam={"pos": add(cam, hand(i, 0.7)), "look": look, "fov": 64}, exposure=2.1,
                 flash=fl(cam, look, 9.0 * (1 - ease((k - 0.5) / 0.3)), 0.45)), None)
shot("in", 60, s_in)

def tent(i, extra=None):
    fr = dict(DARK, shot="room", cam={"pos": [TENT_EYE[0], TENT_EYE[1] + 0.03 * math.sin(i * 0.31), TENT_EYE[2]], "look": TENT_LOOK, "fov": 66},
              exposure=2.5, glow=5)
    if extra: fr.update(extra)
    return fr

# 8. through the flap: he unfolds from the table and comes across the rug, hunched, sniffing
def s_past(i, k):
    if i < 16:
        return (tent(i), sitting([0.3, -0.6, 0.6], 0.2, stop(i) + 4.0))
    w = ease((i - 16) / 44)
    p = lerp([24.0, U, 13.0], [22.6, U, 15.6], w)
    return (tent(i), {"pos": p, "yaw": facing(p, TENT), "gait": "Search", "phase": w * 6 * WALK, "t": stop(i), "duck": 0.5, "jaw": 0.25})
shot("past", 60, s_past)

# 9. he folds down to the flap... his face at the gap; gone; and there on the hit (frame 64: 22.15 s)
VIEW = [TENT_LOOK[0] - TENT_EYE[0], 0, TENT_LOOK[2] - TENT_EYE[2]]
VL = math.hypot(VIEW[0], VIEW[2]); VD = [VIEW[0] / VL, VIEW[2] / VL]
# (folded right down to a tent flap, his face is ~9 studs out from his feet: he stands well back)
STOPAT = [TENT_EYE[0] + VD[0] * 12.0, U, TENT_EYE[2] + VD[1] * 12.0]
LEAN = [TENT_EYE[0] + VD[0] * 11.0, U, TENT_EYE[2] + VD[1] * 11.0]
def s_tear(i, k):
    if i < 64:
        if i < 18:
            return (tent(i, {"glow": 5}), {"pos": STOPAT, "yaw": facing(STOPAT, TENT_EYE), "gait": "Stare", "t": stop(i),
                                           "neck": [0.2, 0.0, -0.6 * ease(i / 12)], "jaw": 0.2})
        if i < 44:
            # (folded down from the hips to the flap, the mask coming level with your eyes, in jerks)
            w = math.floor(ease((i - 18) / 20) * 9) / 9
            p = lerp(STOPAT, LEAN, w)
            return (tent(i, {"glow": 6}), {"pos": p, "yaw": facing(p, TENT_EYE), "gait": "Stare", "t": stop(i), "pitch": -1.33 * w,
                                           "neck": [1.33 * w, 0.0, -0.5 * w - 0.2], "jaw": 0.2 + 0.4 * w})
        return (tent(i), None)
    face = [TENT_EYE[0] + VD[0] * 1.6, U + 1.9, TENT_EYE[2] + VD[1] * 1.6]
    fr = tent(i, {"glow": 10, "exposure": 2.6, "flash": {"i": 10.0, "pos": [TENT_EYE[0], TENT_EYE[1] - 0.4, TENT_EYE[2] + 0.2], "target": face, "angle": 0.5}})
    fr["cam"]["look"] = face
    fr["cam"]["fov"] = 72
    near = [TENT_EYE[0] + VD[0] * 10.5, U, TENT_EYE[2] + VD[1] * 10.5]
    return (fr, {"pos": near, "yaw": facing(near, TENT_EYE), "gait": "Stare", "t": stop(i), "pitch": -1.36,
                 "neck": [1.36, 0.0, -0.4 + 0.35 * math.sin(i * 1.3)], "jaw": 1.0})
shot("tear", 75, s_tear)

# 10. RUN: out in the hall, looking back: he comes through her door after you on all fours
def s_run(i, k):
    cam = [3.0 + 0.25 * math.sin(i * 1.7), U + 4.2 + 0.2 * math.sin(i * 2.3), 6.0 - 2.0 * k]
    p = lerp([14.5, U, 20.0], [7.5, U, 15.0], ease(min(1.0, k * 1.2)))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [p[0], U + 3.0, p[2]], "fov": 62, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [p[0], U + 3.5, p[2]], 18.0, 0.36), exposure=1.8, glow=8, door=1.6),
            {"pos": p, "yaw": facing(p, cam), "gait": "Chase", "phase": k * 14 * RUN, "t": stop(i), "jaw": 0.9})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
