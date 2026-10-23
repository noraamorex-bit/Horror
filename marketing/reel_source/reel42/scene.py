# Reel 42 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #11": #2's format, look, music and slot lengths, built on
# what the numbers say. #2 (the attic story night by night, caption "he's still up there 👀") has 314K views and
# 26K sends; the gameplay montages with HUDs (reels 36-41) didn't reach 5K. So: #2's beat sheet again (the cosy
# house, the case file, "night N:" evidence that escalates, the reveal, the scare, the search-it end card) as
# its sequel: "he isn't up there anymore". All-new shots of the built game; no HUD, no friends on screen.
#   hook (105)  the living room, lamps on, cosy (the hook text over it)
#   card (120)  the dark upstairs hall, a slow push to the attic hatch in the ceiling (the case file over it)
#   72  "night 1: the hatch was open."           the flashlight up at it: a black gap
#   33  "night 3: wet footprints."                on the hall floor, from under the hatch
#   90  "night 6: my door opened. by itself."    from my bed: the bedroom door swings open on the dark hall
#   60  "night 8: someone stood by my bed."      turning my head: a tall shape right beside the bed
#   60  "so dad nailed the hatch shut."           morning, lights on: two boards across it
#   60  "night 9: the nails were on the floor."   the flashlight on the boards and nails... up to the open hatch
#   75  "he isn't up there anymore."              the black hole above... turn round: he's behind you (22.15 s)
#   30  "RUN."                                    down the stairs, him after you
# python3 scene.py [preview]. Writes spec.json, frames_in.json, shots.json (in the current directory).
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.5
SCALE = 1.2              # the avatars (taller players)
AV = 2.2 * SCALE         # an avatar's origin (its LowerTorso) above its feet
RUN = math.tau / 8.5
TAU = math.tau
S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
C = f"{S}/avcache"

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def clamp(k): return max(0.0, min(1.0, k))
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]
def stop(i, fps=13): return math.floor(i * fps / 30) / fps
def run_shake(i, amt=1.0): return [0.2 * amt * math.sin(i * 1.7), 0.2 * amt * math.sin(i * 2.3), 0.12 * amt * math.sin(i * 1.1)]
def wrap(a): return ((a + math.pi) % TAU) - math.pi

# --- your friends: real Roblox avatars (avatar_rbx.js; poses: avatar.js joint names)
RILEY = {"cache": C, "skin": "#f5cd30", "shirt": "144076357", "pants": "382537568", "faces": ["144080495", "8329421", "7074932"], "hats": ["63690008"]}
JAMIE = {"cache": C, "skin": "#9b6a48", "shirt": "398633582", "pants": "398633811", "faces": ["144080495", "7317691", "8329421"], "hats": ["1103003368"]}
AVS = [{"pos": [0, -200, 0], "yaw": 0, "rbx": RILEY, "scale": SCALE}, {"pos": [0, -200, 0], "yaw": 0, "rbx": JAMIE, "scale": SCALE}]
SMILE, SCARED, UHOH = 0, 1, 2

def gait(phase, run=False, look=(0, 0)):
    s, c = math.sin(phase), math.cos(phase)
    a = 0.85 if run else 0.45
    kn = 1.25 if run else 0.5
    return {"lHip": a * s, "rHip": -a * s,
            "lKnee": -kn * max(0.0, -c) - 0.1, "rKnee": -kn * max(0.0, c) - 0.1,
            "lShoulder": [-a * 0.9 * s + (0.3 if run else 0), 0, -0.05], "rShoulder": [a * 0.9 * s + (0.3 if run else 0), 0, 0.05],
            "lElbow": 1.2 if run else 0.2, "rElbow": 1.2 if run else 0.2,
            "waist": -0.2 if run else 0.0, "neckX": 0.1 if run else 0.0, "neckY": look[0], "neckZ": look[1]}
def player(i, pos, yaw, phase=0.0, run=False, pose=None, pitch=0.0, face=SMILE):
    bob = 0.14 * abs(math.sin(phase)) if run else 0.04 * abs(math.sin(phase))
    return {"i": i, "pos": [pos[0], pos[1] + AV + bob, pos[2]], "yaw": yaw, "pose": pose or gait(phase, run), "pitch": pitch, "face": face}
AFRAID = {"lShoulder": [0.55, 0, -0.35], "rShoulder": [0.55, 0, 0.35], "lElbow": 1.5, "rElbow": 1.5, "neckX": -0.1, "waist": 0.05}
FLAIL = {"lShoulder": [2.6, 0, -0.5], "rShoulder": [2.2, 0, 0.6], "lElbow": 0.4, "rElbow": 0.9, "neckX": -0.35, "lHip": 0.5, "rHip": -0.3, "lKnee": -0.9, "rKnee": -0.3}

WALK = math.tau / 6.2
COLD, MOON, WARM = "#3d4f7a", "#6f86c4", "#ffb766"

# --- the attic hatch: the hole is x 4..8, z 8..14 in the upstairs hall ceiling (y 28); its panel hinges down at z 8
HATCH = {"near": [6.0, 28.0, 11.0], "r": 4.5, "names": ["HatchPanel"], "hinge": [6.0, 28.15, 8.05], "axis": "x"}
NO_CORD = ["Cord", "CordHandle"]
OPEN = math.pi / 2
# --- the master bedroom: the bed's head against the west wall (x -39.15), its foot at x -30.15, z -18.25..-10.75;
# the door in the x = -8 wall, hinged at z -12.42, swings into the room
DOOR_RIG = {"near": [-8.0, U + 4.7, -10.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, -12.42], "axis": "y"}
ROOM = [{"p": [-24, U + 9, -33], "col": MOON, "b": 2.6, "r": 34, "decay": 1.1}, {"p": [-14, U + 6, -20], "col": COLD, "b": 1.1, "r": 18},
        {"p": [-4.5, U + 7, -10], "col": "#6f86c4", "b": 4.0, "r": 18}, {"p": [-26, U + 9, -14], "col": COLD, "b": 0.8, "r": 16}]
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [5, U + 8, 4], "col": COLD, "b": 1.2, "r": 16},
        {"p": [2.5, U + 9, -9], "col": "#5d72a8", "b": 1.6, "r": 18}]
SHOTS = {
    "living": {"center": [-26, G + 5, -10], "radius": 34, "lampRadius": 34, "maxLamps": 5},
    "hall": {"center": [5, U + 6, 10], "radius": 34, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD, "lights": HALL},
    "hallOn": {"center": [5, U + 6, 10], "radius": 34, "lampRadius": 34, "maxLamps": 4, "door": HATCH, "hide": NO_CORD,
               "lights": [{"p": [6, U + 9, 12], "col": "#fff1dc", "b": 1.2, "r": 16}]},
    "room": {"center": [-24, U + 5, -15], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": DOOR_RIG, "lights": ROOM},
    "stairs": {"center": [-5, G + 6, 4], "radius": 40, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [-5, U + 6, 22], "col": "#2c3d6e", "b": 1.3, "r": 26}, {"p": [-5, 8, -2], "col": COLD, "b": 1.4, "r": 18},
                          {"p": [-5, G + 7, -12], "col": COLD, "b": 1.0, "r": 16}]},
}
DARK = {"ambient": 0.02, "bg": 0x010102}

# --- props for the shoot (film2 extras): his wet footprints (World/Signs' layout), dad's boards across the hatch,
# and later the boards and the nails on the floor under it
WET, PLANK, NAIL = [30, 25, 21], [176, 140, 96], [150, 150, 156]
extras = []
FROM, TO, STRIDE = [6.0, 10.5], [4.0, -7.6], 2.3
dx, dz = TO[0] - FROM[0], TO[1] - FROM[1]
Lp = math.hypot(dx, dz); fx, fz = dx / Lp, dz / Lp
rx, rz = -fz, fx
pyaw = math.atan2(-fx, -fz)
def rot(x, z, a): return [x * math.cos(a) + z * math.sin(a), -x * math.sin(a) + z * math.cos(a)]
PRINTS = []
d, n = 0.6, 0
while d < Lp - 0.3:
    side = -1 if n % 2 == 0 else 1
    cx, cz = FROM[0] + fx * d + rx * side * 0.38, FROM[1] + fz * d + rz * side * 0.38
    for (lx, lz, sx, sz) in [(0, 0.05, 0.32, 0.85), (0, 0.42, 0.38, 0.32)]:
        o = rot(lx, lz, pyaw)
        PRINTS.append(len(extras))
        extras.append({"pos": [cx + o[0], U + 0.011, cz + o[1]], "s": [sx, 0.02, sz], "rot": [0, pyaw, 0], "col": WET, "rough": 0.35})
    d += STRIDE; n += 1
BOARDS_UP = []
for z in (9.4, 12.6):
    BOARDS_UP.append(len(extras))
    extras.append({"pos": [6.0, 27.82, z], "s": [5.6, 0.16, 0.75], "rot": [0, 0.04 * (z - 11), 0], "col": PLANK, "rough": 0.9})
    for x in (3.55, 8.45):
        BOARDS_UP.append(len(extras))
        extras.append({"pos": [x, 27.72, z], "s": [0.12, 0.05, 0.12], "shape": "cyl", "col": NAIL, "rough": 0.4})
BOARDS_DOWN = []
for (x, z, a) in [(5.2, 12.8, 0.5), (7.4, 10.2, -0.35)]:
    BOARDS_DOWN.append(len(extras))
    extras.append({"pos": [x, U + 0.09, z], "s": [5.6, 0.16, 0.75], "rot": [0, a, 0], "col": PLANK, "rough": 0.9})
import random
rng = random.Random(7)
for k in range(9):
    BOARDS_DOWN.append(len(extras))
    extras.append({"pos": [4.2 + rng.random() * 4.0, U + 0.05, 9.0 + rng.random() * 5.0], "s": [0.06, 0.6, 0.06], "shape": "cyl",
                   "rot": [math.pi / 2, rng.random() * math.tau, 0], "col": NAIL, "rough": 0.35})
ALL_EXTRAS = set(range(len(extras)))
def only(*groups):
    keep = set().union(*[set(g) for g in groups])
    return sorted(ALL_EXTRAS - keep)

frames, crs, shots = [], [], []
f = 0
def shot(name, n, fn):
    global f
    shots.append({"name": name, "start": f, "n": n})
    dense = dict((d_.split(":")[0], d_.split(":")[1:]) for d_ in os.environ.get("DENSE", "").split(",") if d_)
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

# 1. (hook) the living room, lamps on: cosy, a slow push
def s_hook(i, k):
    cam = add(lerp([-12.5, G + EYE + 0.6, -1.0], [-16.5, G + EYE + 0.2, -4.0], ease(k)), hand(i, 0.6))
    look = lerp([-30.0, G + 3.2, -13.0], [-31.0, G + 3.0, -14.0], ease(k))
    return ({"shot": "living", "cam": {"pos": cam, "look": look, "fov": 64}, "ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1,
             "hideIdx": only()}, None)
shot("hook", 105, s_hook)

# 2. (card) the dark upstairs hall: a slow push towards the hatch in the ceiling
def s_card(i, k):
    cam = add(lerp([2.6, U + EYE, 26.0], [4.6, U + EYE - 0.1, 19.0], ease(k)), hand(i, 0.5))
    look = lerp([4.5, U + 4.6, 10.0], [6.0, 27.0, 11.0], ease(k))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 62}, exposure=2.1, door=0.0, hideIdx=only(),
                 flash=fl(cam, lerp([5.0, U + 1.0, 14.0], [6.0, 28.0, 11.0], ease(k)), 10.0, 0.36)), None)
shot("card", 120, s_card)

# 3. "night 1: the hatch was open." the flashlight up at it: a black gap
def s_open(i, k):
    cam = add(lerp([4.6, U + EYE, 22.0], [5.0, U + EYE, 20.2], ease(k)), hand(i, 0.5))
    look = [6.0, 26.6, 11.2]
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 62}, exposure=2.1, door=0.42, hideIdx=only(),
                 flash=fl(cam, [6.0, 28.0, 11.0], 9.0, 0.34)), None)
shot("open", 72, s_open)

# 4. "night 3: wet footprints." on the hall floor, from under the hatch
def s_prints(i, k):
    cam = add([4.8, U + 5.3, -11.5], hand(i, 0.5))
    tgt = lerp([4.4, U, -6.0], [5.6, U, 5.0], ease(k))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": lerp([4.6, U + 0.4, -3.0], [5.2, U + 1.2, 6.0], ease(k)), "fov": 56}, exposure=2.0,
                 door=0.0, hideIdx=only(PRINTS), flash=fl(cam, tgt, 15.0, 0.32)), None)
shot("prints", 33, s_prints)

# 5. "night 6: my door opened. by itself." lying in bed: the bedroom door swings open on the dark hall
BEDEYE = [-36.4, U + 3.9, -14.0]
def s_door(i, k):
    cam = [BEDEYE[0], BEDEYE[1] + 0.02 * math.sin(i * 0.2), BEDEYE[2]]
    d = -1.35 * ease((i - 14) / 62)
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-8.0, U + 4.6, -11.0], "fov": 40}, exposure=2.6, door=d, hideIdx=only()), None)
shot("door", 90, s_door)

# 6. "night 8: someone stood by my bed." turning my head: a tall shape right beside the bed, dead still
BESIDE = [-31.5, U, -21.6]
def s_beside(i, k):
    turn = ease(i / 34)
    cam = [BEDEYE[0], BEDEYE[1] + 0.02 * math.sin(i * 0.2), BEDEYE[2]]
    look = lerp([-8.0, U + 4.6, -11.0], [BESIDE[0], U + 6.6, BESIDE[2]], turn)
    cr = {"pos": BESIDE, "yaw": facing(BESIDE, BEDEYE), "gait": "Stare", "t": stop(i), "neck": [0.35, 0.0, -0.5], "jaw": 0.1}
    return (dict(DARK, shot="room", cam={"pos": cam, "look": look, "fov": 52}, exposure=2.3, door=-1.35, glow=0.9, hideIdx=only()), cr)
shot("beside", 60, s_beside)

# 7. "so dad nailed the hatch shut." morning, the lights on: two boards across it
def s_nailed(i, k):
    cam = add(lerp([5.2, U + EYE, 17.8], [5.6, U + EYE, 16.8], ease(k)), hand(i, 0.4))
    return ({"shot": "hallOn", "cam": {"pos": cam, "look": [6.0, 28.0, 11.2], "fov": 58}, "ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.3, "lamps": 1,
             "door": 0.0, "hideIdx": only(BOARDS_UP)}, None)
shot("nailed", 60, s_nailed)

# 8. "night 9: the nails were on the floor." the flashlight on the boards and nails... up to the open hatch
def s_nails(i, k):
    up = ease((i - 26) / 26)
    cam = add(lerp([5.0, U + EYE, 19.0], [5.4, U + EYE, 17.6], ease(k)), hand(i, 0.6))
    look = lerp([5.8, U + 0.2, 11.6], [6.0, 28.4, 11.0], up)
    tgt = lerp([6.0, U, 11.4], [6.0, 28.4, 11.0], up)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 60}, exposure=2.1, door=OPEN, hideIdx=only(BOARDS_DOWN),
                 flash=fl(cam, tgt, 14.0, 0.34)), None)
shot("nails", 60, s_nails)

# 9. "he isn't up there anymore." the black hole above... turn round to the hall behind: he's right there (22.15 s:
# frame 64 of this shot)
CAM9 = [5.6, U + EYE, 16.4]
BEHIND = [4.6, U, 22.6]
def s_behind(i, k):
    cam = add(CAM9, hand(i, 0.4))
    if i < 30:
        look = [6.0, 28.6, 11.0]
        return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 58}, exposure=2.1, door=OPEN, hideIdx=only(BOARDS_DOWN),
                     flash=fl(cam, look, 13.0, 0.32)), None)
    t = ease((i - 30) / 26)
    y0, y1 = facing(CAM9, [6.0, U, 11.0]), facing(CAM9, BEHIND)
    yaw = y0 + wrap(y1 - y0) * t
    ly = 28.6 + (U + 8.4 - 28.6) * ease((i - 30) / 16)
    look = [cam[0] - math.sin(yaw) * 6.0, ly, cam[2] - math.cos(yaw) * 6.0]
    if i < 64:
        p = BEHIND
        cr = {"pos": p, "yaw": facing(p, CAM9), "gait": "Stare", "t": stop(i), "neck": [0.25, 0.0, -0.6], "jaw": 0.2 + 0.5 * ease((i - 56) / 8)}
        fr = dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 58}, exposure=2.2, door=OPEN, hideIdx=only(BOARDS_DOWN), glow=1.6,
                  flash=fl(cam, look if t < 0.98 else [p[0], U + 8.0, p[2]], 13.0, 0.4))
        return (fr, cr)
    w = ease((i - 64) / 3)
    p = lerp(BEHIND, [5.0, U, 21.3], w)
    cr = {"pos": p, "yaw": facing(p, CAM9), "gait": "Stare", "t": stop(i), "duck": 3.4 * w, "neck": [0.9 * w, 0.0, -0.4], "jaw": 1.0}
    fr = dict(DARK, shot="hall", cam={"pos": cam, "look": [5.0 - 1.6 * w, U + 5.8 + 2.6 * (1 - w), 21.3], "fov": 64}, exposure=2.6, door=OPEN,
              hideIdx=only(BOARDS_DOWN), glow=8.0, flash=fl(cam, [p[0], U + 5.5, p[2]], 13.0, 0.5))
    return (fr, cr)
shot("behind", 75, s_behind)

# 10. RUN: down the stairs, looking back: he comes down after you on all fours
def sy(z): return max(G, min(U, 2.05 + 0.625 * (z + 5.3) - 1.0))
def s_run(i, k):
    zc = 2.0 - 7.0 * k
    cam = [-5.0 + 0.25 * math.sin(i * 1.7), sy(zc) + 5.0 + 0.2 * math.sin(i * 2.3), zc]
    zh = 17.0 - 9.0 * k
    hy = sy(zh) if zh < 15.5 else U
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, hy + 3.0, zh], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [-5.0 + 1.2 * math.sin(i * 1.3), hy + 4.0, zh], 18.0, 0.36), ambient=0.01, exposure=1.8, glow=9, hideIdx=only()),
            {"pos": [-5.0, hy, zh], "yaw": facing([-5.0, hy, zh], [-5.0, hy, zh - 10]), "gait": "Chase", "phase": k * 15 * RUN, "t": stop(i),
             "pitch": 0.3 if zh < 15.5 else 0.0, "jaw": 0.9})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
