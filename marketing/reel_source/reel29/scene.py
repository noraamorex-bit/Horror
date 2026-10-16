# Reel 29 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 7)": Parts 2-6's format on #2's track
# (every clip keeps #2's length, so the track's cuts and hits land). Halloween (the v96 event): the
# candy hunt, and a trail of candy that leads somewhere it shouldn't.
#   hook (105)  outside: the front walk lined with glowing jack-o'-lanterns, a slow push to the porch
#   card (120)  inside, the dark hall: the flashlight finds a wrapped candy on the floor
#   72          the bottom of the stairs: a jack-o'-lantern glowing at the top, in a lightning flash
#   33          crouch and take the candy
#   90          up the stairs, a trail of candies on the treads, the jack-o'-lantern getting closer
#   60          the top: the last candy, right in front of the jack-o'-lantern
#   60          reaching for it... the pumpkin's glow is on two legs standing right behind it
#   60          slowly up: his body, his mask lit from below
#   75          his head tilts... and he lunges (the scare at 22.15 s)
#   30          RUN: down the stairs, looking back: he's coming down after you
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
WARM = "#ffa04a"
# the stairs: x -8..-2, treads from (y 2, z -5.3) up to (y 15, z 15.5); tread top = 0.15 above its centre
def tread(n):  # n = 0 (bottom) .. 13 (top)
    return [-5.0, 2.0 + n, -5.27 + n * 1.6]
TOP = [-5.0, U, 15.6]          # the jack-o'-lantern on the top step (in view from the bottom of the stairs)
HIM = [-5.0, U, 17.8]          # him, right behind it on the landing
CANDY_HALL = [-1.0, G + 0.02, -8.4]
CANDY_STAIRS = [[-4.3, tread(3)[1], tread(3)[2] + 0.1], [-5.6, tread(6)[1], tread(6)[2] - 0.1], [-4.6, tread(9)[1], tread(9)[2]]]
CANDY_LAST = [-4.3, tread(12)[1] + 0.02, tread(12)[2] - 0.1]  # the step below it
HIDE = ["CandyBody", "CandyWrap"]  # (tonight's random candies in the dump: ours are placed by hand)

# the jack-o'-lantern at the top of the stairs, and the candies, as extras
extras = []
def candy(at, yaw=0.3, wrap=(150, 60, 220)):
    c, s = math.cos(yaw), math.sin(yaw)
    extras.append({"pos": [at[0], at[1] + 0.22, at[2]], "s": [0.55, 0.38, 0.38], "rot": [0, yaw, 0], "shape": "ball", "col": [255, 122, 24], "emissive": [255, 110, 20], "ei": 0.7})
    for side in (-1, 1):
        extras.append({"pos": [at[0] + side * 0.4 * c, at[1] + 0.22, at[2] - side * 0.4 * s], "s": [0.22, 0.3, 0.3], "rot": [math.radians(45), yaw, 0], "col": list(wrap), "rough": 0.3})
def jack(at, face_dir_z=-1, d=1.5):
    h = d * 0.75
    extras.append({"pos": [at[0], at[1] + h / 2, at[2]], "s": [d, h, d * 0.92], "shape": "ball", "col": [214, 104, 26], "emissive": [120, 40, 0], "ei": 0.35})
    extras.append({"pos": [at[0], at[1] + h + 0.12, at[2]], "s": [0.18, 0.32, 0.18], "shape": "cyl", "col": [84, 104, 54]})
    zf = at[2] + face_dir_z * d * 0.455
    face = [255, 196, 80]
    for side in (-1, 1):   # eyes: diamonds
        extras.append({"pos": [at[0] + side * d * 0.2, at[1] + h * 0.62, zf], "s": [d * 0.17, d * 0.17, 0.06], "rot": [0, 0, math.pi / 4], "col": face, "emissive": face, "ei": 2.2})
    extras.append({"pos": [at[0], at[1] + h * 0.47, zf - face_dir_z * 0.02], "s": [d * 0.09, d * 0.09, 0.06], "rot": [0, 0, math.pi / 4], "col": face, "emissive": face, "ei": 2.2})
    for k in range(-3, 4):  # the grin
        if k == 0: continue
        extras.append({"pos": [at[0] + k * d * 0.075, at[1] + h * (0.27 + 0.012 * k * k), zf - face_dir_z * (0.01 * k * k)], "s": [d * 0.06, d * 0.08, 0.06], "col": face, "emissive": face, "ei": 2.2})
jack(TOP)
candy(CANDY_HALL, 0.4)
for i, c in enumerate(CANDY_STAIRS):
    candy(c, 0.3 + i, [(60, 190, 90), (230, 40, 60), (250, 200, 40)][i])
candy(CANDY_LAST, -0.2, (150, 60, 220))
JACK_LIGHT = {"p": [TOP[0], TOP[1] + 0.8, TOP[2] - 0.4], "col": WARM, "b": 3.0, "r": 16, "decay": 1.4}
HALL_DARK = [{"p": [2.0, G + 9, -20.0], "col": COLD, "b": 1.0, "r": 22}, {"p": [-5.0, U + 9, 8.0], "col": "#2c3d6e", "b": 0.8, "r": 26}]

SHOTS = {
    "walk": {"center": [2, 4, -48], "radius": 60, "lampRadius": 40, "maxLamps": 12, "hide": HIDE,
             "lights": [{"p": [2, 30, -70], "col": MOON, "b": 1.4, "r": 90, "decay": 0.6}]},
    "hall": {"center": [0, 6, -6], "radius": 34, "lampRadius": 0, "maxLamps": 0, "hide": HIDE, "lights": HALL_DARK},
    "stairs": {"center": [-4, 9, 6], "radius": 34, "lampRadius": 0, "maxLamps": 0, "hide": HIDE, "lights": HALL_DARK + [JACK_LIGHT]},
    "landing": {"center": [-5, U + 2, 14], "radius": 28, "lampRadius": 0, "maxLamps": 0, "hide": HIDE, "lights": [JACK_LIGHT, {"p": [-5.0, U + 9, 6.0], "col": "#2c3d6e", "b": 0.7, "r": 20}]},
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

# 1. (hook) outside: the front walk lined with glowing jack-o'-lanterns, a slow push to the porch
def s_hook(i, k):
    cam = add(lerp([2.0, 0.6 + EYE, -66.0], [2.0, 0.6 + EYE - 0.3, -50.0], ease(k)), hand(i))
    lt = 0.6 if 70 <= i <= 72 else 0.0
    return (dict(DARK, shot="walk", cam={"pos": cam, "look": lerp([2.0, 2.0, -40.0], [2.0, 3.6, -34.0], ease(k)), "fov": 60},
                 exposure=1.7, lamps=0.55, moon=0.25, lightning=lt), None)
shot("hook", 105, s_hook)

# 2. (card) inside, the dark hall: the flashlight sweeps and finds a wrapped candy on the floor
def s_hall(i, k):
    cam = add(lerp([2.0, G + EYE, -24.0], [1.2, G + EYE - 0.2, -15.5], ease(k)), hand(i, 0.8))
    tgt = lerp([4.0, G + 2.5, -8.0], CANDY_HALL, ease((k - 0.25) / 0.5))
    look = lerp([1.0, G + 3.5, -6.0], [CANDY_HALL[0], G + 1.2, CANDY_HALL[2]], ease((k - 0.3) / 0.6))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 60}, exposure=2.0,
                 flash={"i": 12.0, "pos": [cam[0] + 0.5, cam[1] - 0.6, cam[2]], "target": tgt, "angle": 0.32}), None)
shot("card", 120, s_hall)

# 3. the bottom of the stairs: up in the dark, a jack-o'-lantern glowing at the top (a lightning flash)
def s_far(i, k):
    cam = add([-5.0, G + EYE, -10.5], hand(i, 0.5))
    lt = 0.9 if 16 <= i <= 19 else (0.45 if 44 <= i <= 46 else 0.0)
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, U + 1.2, 17.4], "fov": 30}, exposure=2.2, lightning=lt), None)
shot("far", 72, s_far)

# 4. crouch and take the candy (it's gone on the last frames)
def s_take(i, k):
    cam = add(lerp([-0.4, G + EYE - 0.4, -11.5], [-0.8, G + 2.6, -9.9], ease(k / 0.6)), hand(i, 0.4))
    fr = dict(DARK, shot="hall", cam={"pos": cam, "look": [CANDY_HALL[0], G + 0.3, CANDY_HALL[2]], "fov": 56}, exposure=2.1,
              flash={"i": 10.0, "pos": [cam[0] + 0.4, cam[1] - 0.5, cam[2]], "target": CANDY_HALL, "angle": 0.3})
    if i >= 26:
        fr["hideExtras"] = [CANDY_HALL]
    return (fr, None)
shot("take", 33, s_take)

# 5. up the stairs: a trail of candies on the treads, the jack-o'-lantern coming closer
def s_climb(i, k):
    n = 1.0 + 7.0 * ease(k)
    t = [-5.0, 2.0 + n, -5.27 + n * 1.6]
    bob = 0.12 * abs(math.sin(i * 0.22))
    cam = add([t[0] + 0.4, t[1] + 0.15 + EYE - 0.3 + bob, t[2] - 2.6], hand(i, 0.6))
    look = [TOP[0], TOP[1] + 0.6, TOP[2]]
    tgt = lerp(CANDY_STAIRS[0], CANDY_STAIRS[2], ease(k))
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": lerp([-4.8, cam[1] - 1.5, cam[2] + 6], look, ease((k - 0.2) / 0.6)), "fov": 60}, exposure=2.1,
                 flash={"i": 10.0, "pos": [cam[0] + 0.4, cam[1] - 0.5, cam[2]], "target": tgt, "angle": 0.34}), None)
shot("climb", 90, s_climb)

# 6. the top: the last candy, right in front of the jack-o'-lantern
def s_top(i, k):
    cam = add(lerp([-4.7, tread(9)[1] + 0.15 + EYE - 0.4, tread(9)[2] - 1.0], [-4.6, tread(11)[1] + 0.15 + EYE - 1.2, tread(11)[2] - 0.6], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="landing", cam={"pos": cam, "look": [CANDY_LAST[0], CANDY_LAST[1] + 0.6, CANDY_LAST[2] + 0.6], "fov": 54}, exposure=2.2,
                 flash={"i": 6.0, "pos": [cam[0] + 0.3, cam[1] - 0.5, cam[2]], "target": CANDY_LAST, "angle": 0.3}), None)
shot("top", 60, s_top)

LOW = [-4.5, tread(11)[1] + 0.15 + 2.2, tread(11)[2] + 0.2]  # crouched two steps down, reaching for the candy
def him(i, extra=None):
    cr = {"pos": HIM, "yaw": facing(HIM, LOW), "gait": "Stare", "t": i / 30, "neck": [0.0, 0.0, 0.0]}
    if extra: cr.update(extra)
    return cr

# 7. reaching for it... the pumpkin's glow is on two legs standing right behind it
def s_legs(i, k):
    cam = add(lerp([-4.6, LOW[1] + 1.0, LOW[2] - 0.6], LOW, ease(k / 0.5)), hand(i, 0.4))
    look = lerp([CANDY_LAST[0], U + 0.2, CANDY_LAST[2]], [HIM[0], U + 1.6, HIM[2]], ease((k - 0.45) / 0.45))
    return (dict(DARK, shot="landing", cam={"pos": cam, "look": look, "fov": 56}, exposure=2.3, glow=0), him(i))
shot("legs", 60, s_legs)

# 8. slowly up: his body, his mask lit from below by the jack-o'-lantern
def s_up(i, k):
    cam = add(LOW, hand(i, 0.3))
    look = lerp([HIM[0], U + 1.8, HIM[2]], [HIM[0], U + 9.0, HIM[2]], ease(k))
    return (dict(DARK, shot="landing", cam={"pos": cam, "look": look, "fov": 56}, exposure=2.4, glow=2 + 5 * ease(k)), him(i, {"neck": [-0.45 * ease(k), 0.0, 0.0]}))
shot("up", 60, s_up)

# 9. his head tilts... nothing... and he lunges (22.15 s: frame 64 of this shot)
def s_lunge(i, k):
    if i < 64:
        tilt = ease(i / 50)
        return (dict(DARK, shot="landing", cam={"pos": add(LOW, hand(i, 0.25)), "look": [HIM[0], U + 8.4, HIM[2]], "fov": 56}, exposure=2.4, glow=7),
                him(i, {"neck": [-0.45, 0.0, 0.45 * tilt]}))
    j = i - 64
    p = lerp(HIM, [-4.6, U, 16.6], ease(j / 4.0))
    return (dict(DARK, shot="landing", cam={"pos": LOW, "look": [p[0], U + 6.0, p[2]], "fov": 62}, exposure=2.7, glow=12),
            {"pos": p, "yaw": facing(p, LOW), "gait": "Reach", "t": i / 30, "duck": 0.9, "neck": [0.0, 0.0, 0.3 * math.sin(i * 0.9)]})
shot("lunge", 75, s_lunge)

# 10. RUN: down the stairs, looking back: he's coming down after you
def s_run(i, k):
    n = 9.0 - 6.0 * k
    t = [-5.0, 2.0 + n, -5.27 + n * 1.6]
    cam = [t[0] + 0.25 * math.sin(i * 1.7), t[1] + 0.15 + EYE - 0.6 + 0.2 * math.sin(i * 2.3), t[2] - 0.8]
    m = 13.5 - 5.0 * k
    p = [-5.0, 2.0 + m - 0.15, -5.27 + m * 1.6]
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, p[1] + 4.5, p[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash={"i": 16.0, "pos": [cam[0] + 0.5, cam[1] - 0.5, cam[2]], "target": [p[0], p[1] + 4.0, p[2]], "angle": 0.38},
                 ambient=0.01, exposure=1.8, glow=8),
            {"pos": p, "yaw": facing(p, cam), "gait": "Chase", "phase": k * 15 * RUN, "t": i / 30})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
