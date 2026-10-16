# Reel 28 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 6)": Parts 2-5's format on #2's track
# (every clip keeps #2's length, so the track's cuts and hits land). The story this time is the game's
# name: someone lives in our attic. Up the ladder into the attic, his nest, and him coming up after you.
#   hook (105)  the upstairs hall in the dark, the flashlight drifting up to the attic hatch, ajar
#   card (120)  up the ladder: rising through the hatch into the attic, a lantern burning at the far end
#   72          along the walkway: his nest (sleeping bag, bottles, wrappers) in the lantern light
#   33          the flashlight on the wall: tally marks, counting the days
#   90          the family's photos pinned up, then the family portrait with the faces scratched out
#   60          a creak: back at the hatch, his head rises through it, the mask glowing
#   60          hiding behind the boxes, light off: he crawls along the walkway towards the nest
#   60          he stands at the nest with his back to you, looking at the photos
#   75          his head slowly turns... and he lunges (the scare at 22.15 s)
#   30          RUN: down in the hall, looking back: he slides down the ladder after you
# python3 scene.py [preview]. Writes spec.json, frames_in.json, shots.json.
import json, math, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.6
A = 29.4            # the attic walkway's top
CROUCH = A + 3.1    # eye height crouched under the rafters
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
WARM = "#ffb766"
# the hatch: the hole is x 4..8, z 8..14 in the hall ceiling; the panel hinges down at z = 8
HATCH = {"near": [6.0, 28.0, 11.0], "r": 4.5, "names": ["HatchPanel"], "hinge": [6.0, 28.15, 8.05], "axis": "x"}
NO_CORD = ["Cord", "CordHandle"]   # (the pull cord stays on the closed panel in the game: hidden with the hatch open)
OPEN = math.pi / 2
# his lantern by the nest (the dump's Neon "Lantern" at (-19, 30.1, -4))
LANTERN = {"p": [-19.0, 31.2, -3.4], "col": WARM, "b": 3.6, "r": 26, "decay": 1.2}
ATTIC = [LANTERN, {"p": [6.0, 27.0, 11.0], "col": COLD, "b": 1.6, "r": 14},          # the hall's dark, up through the hatch
         {"p": [30.0, 36.0, 0.0], "col": "#2c3d6e", "b": 0.8, "r": 40, "decay": 1.0}]  # the gable vent, moonlight
SHOTS = {
    "hall": {"center": [5, U + 6, 12], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD,
             "lights": [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [6, 31, 11], "col": WARM, "b": 0.35, "r": 8}]},
    "climb": {"center": [-4, 30, 6], "radius": 46, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD,
              "lights": ATTIC + [{"p": [6, U + 8, 14], "col": COLD, "b": 1.2, "r": 14}]},
    "attic": {"center": [-14, 31, 2], "radius": 40, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD, "lights": ATTIC},
    "hiding": {"center": [-14, 31, 2], "radius": 40, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD,
               "lights": ATTIC + [{"p": [-8.0, 34.0, 9.0], "col": COLD, "b": 1.3, "r": 18},
                                  {"p": [-26.6, 34.5, 1.0], "col": WARM, "b": 1.6, "r": 7, "decay": 1.6}]},
    "hallRun": {"center": [5, U + 6, 14], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD,
                "lights": [{"p": [2, U + 11, 24], "col": MOON, "b": 1.8, "r": 30, "decay": 1.1}, {"p": [6, 30, 10], "col": WARM, "b": 0.6, "r": 10}]},
}
DARK = {"ambient": 0.02, "bg": 0x010102}

# props for the shoot: the folding ladder down from the hatch, and the stored boxes in the attic
WOOD, BOX, BOX2 = [150, 118, 80], [150, 116, 78], [128, 98, 66]
extras = []
TOP, BOT = [9.2, 28.2], [14.3, U]     # (z, y) of the ladder's top (on the hatch frame) and its feet
L = math.hypot(TOP[0] - BOT[0], TOP[1] - BOT[1])
RX = -math.atan2(BOT[0] - TOP[0], TOP[1] - BOT[1])
for x in (5.1, 6.9):
    extras.append({"pos": [x, (TOP[1] + BOT[1]) / 2, (TOP[0] + BOT[0]) / 2], "s": [0.22, L, 0.45], "rot": [RX, 0, 0], "col": WOOD})
for j in range(1, 12):
    k = j / 12
    extras.append({"pos": [6.0, BOT[1] + (TOP[1] - BOT[1]) * k, BOT[0] + (TOP[0] - BOT[0]) * k], "s": [1.8, 0.16, 0.5], "rot": [RX, 0, 0], "col": WOOD})
def box(x, z, w, h, d, yaw=0.0, col=BOX, y0=29.25):
    extras.append({"pos": [x, y0 + h / 2, z], "s": [w, h, d], "rot": [0, yaw, 0], "col": col, "rough": 0.95})
# the hiding place: a stack by the nest, between the walkway and the lantern
box(-14.2, -2.4, 3.0, 2.4, 2.6, 0.12)
# more stored stuff along the attic
box(-6.0, 3.0, 3.2, 2.2, 2.8, 0.25)
box(-3.0, 1.6, 2.4, 1.6, 2.2, -0.15, BOX2)
box(12.0, 4.0, 3.0, 2.4, 3.0, 0.1)
box(15.0, 5.5, 2.4, 1.6, 2.0, 0.4, BOX2)
box(-10.0, 17.0, 3.4, 2.4, 3.0, -0.2)
box(-34.0, 6.0, 3.0, 2.0, 2.6, 0.1, BOX2)

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

# 1. (hook) the upstairs hall: a slow push, the flashlight drifting up to the hatch: open, the ladder down
def s_hook(i, k):
    cam = add(lerp([3.0, U + EYE, 25.0], [5.0, U + EYE - 0.2, 17.0], ease(k)), hand(i))
    look = lerp([5.0, U + 4.5, 12.0], [6.0, 27.6, 11.0], ease(k))
    tgt = lerp([5.0, U + 2.0, 13.0], [6.0, 28.0, 11.0], ease(min(1.0, k * 1.25)))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 62},
                 flash={"i": 13.0, "pos": [cam[0] + 0.5, cam[1] - 0.6, cam[2]], "target": tgt, "angle": 0.34}, exposure=1.9, door=OPEN), None)
shot("hook", 105, s_hook)

# 2. (card) up the ladder: rising through the hatch, a lantern burning at the far end of the attic
def s_climb(i, k):
    up = ease(k / 0.75)
    cam = add([6.0, U + EYE + (CROUCH + 0.5 - U - EYE) * up, 12.6 - 1.4 * up], hand(i, 0.5))
    # straight up through the hole while climbing, then round to the lantern at the far end
    turn = ease((k - 0.55) / 0.4)
    look = lerp([cam[0] - 0.6, cam[1] + 10.0, cam[2] - 0.8], [-19.0, 30.6, -3.0], turn)
    fl = {"i": 11.0, "pos": [cam[0] + 0.4, cam[1] - 0.5, cam[2]], "target": lerp([cam[0] - 1.0, cam[1] + 8.0, cam[2] - 1.0], [-8.0, 30.0, 4.0], turn), "angle": 0.4}
    return (dict(DARK, shot="climb", cam={"pos": cam, "look": look, "fov": 62}, exposure=2.0, door=OPEN, flash=fl), None)
shot("card", 120, s_climb)

# 3. along the walkway, crouched: his nest in the lantern light
def s_nest(i, k):
    cam = add(lerp([-6.0, CROUCH, 9.5], [-12.0, CROUCH - 0.2, 7.0], ease(k)), hand(i, 0.8))
    tgt = lerp([-20.0, 29.6, 3.0], [-24.0, 29.8, 0.0], ease(k))
    return (dict(DARK, shot="attic", cam={"pos": cam, "look": [-23.0, 30.2, -0.5], "fov": 58}, exposure=2.0, door=OPEN,
                 flash={"i": 9.0, "pos": [cam[0] + 0.4, cam[1] - 0.5, cam[2]], "target": tgt, "angle": 0.36}), None)
shot("nest", 72, s_nest)

# 4. the wall: tally marks, counting the days
def s_tally(i, k):
    cam = add(lerp([-22.6, CROUCH + 0.1, 5.4], [-23.4, CROUCH, 5.0], k), hand(i, 0.4))
    return (dict(DARK, shot="attic", cam={"pos": cam, "look": [-28.3, 32.2, 4.4], "fov": 54}, exposure=2.1, door=OPEN,
                 flash={"i": 10.0, "pos": [cam[0] + 0.3, cam[1] - 0.4, cam[2]], "target": [-28.3, 32.3, 4.5], "angle": 0.3}), None)
shot("tally", 33, s_tally)

# 5. his photos of the family pinned up, then down to the portrait with the faces scratched out
def s_photos(i, k):
    a = ease(k / 0.55)
    b = ease((k - 0.55) / 0.35)
    cam = add(lerp(lerp([-23.0, CROUCH, 2.8], [-24.0, CROUCH - 0.1, 1.2], a), [-24.6, A + 2.0, -2.0], b), hand(i, 0.5))
    look = lerp(lerp([-28.3, 32.6, 2.2], [-28.3, 32.2, -0.4], a), [-27.9, 30.1, -3.3], b)
    return (dict(DARK, shot="attic", cam={"pos": cam, "look": look, "fov": 52 - 6 * b}, exposure=2.1, door=OPEN,
                 flash={"i": 10.0, "pos": [cam[0] + 0.3, cam[1] - 0.4, cam[2]], "target": look, "angle": 0.3}), None)
shot("photos", 90, s_photos)

# 6. a creak: back down the attic to the hatch, and his head rises through it
HOLE = [6.0, U, 12.6]
def s_rise(i, k):
    cam = add([-12.0, CROUCH - 0.5, 9.2], hand(i, 0.6))
    rise = ease(k / 0.8)
    p = [HOLE[0], U + 2.0 + 7.5 * rise, HOLE[2] - 1.2 * rise]
    fl = {"i": 9.0 * (1 - ease((k - 0.85) / 0.1)), "pos": [cam[0] + 0.3, cam[1] - 0.4, cam[2]], "target": [6.0, 30.5, 10.5], "angle": 0.2}
    return (dict(DARK, shot="climb", cam={"pos": cam, "look": [6.0, 31.0, 10.6], "fov": 34}, exposure=2.2, door=OPEN, glow=8, flash=fl),
            {"pos": p, "yaw": facing(p, cam), "gait": "Stare", "t": i / 30, "neck": [0.25, 0.0, 0.15]})
shot("rise", 60, s_rise)

# hiding behind the boxes by the nest, light off: only his lantern
HIDE = [-12.6, A + 2.7, -6.2]   # peeking over the box stack
def hide(i, look, extra=None):
    fr = dict(DARK, shot="hiding", cam={"pos": [HIDE[0], HIDE[1] + 0.03 * math.sin(i * 0.31), HIDE[2]], "look": look, "fov": 60},
              exposure=2.5, door=OPEN, glow=6)
    if extra: fr.update(extra)
    return fr

# 7. he comes along the walkway towards the nest, bent under the rafters
def s_crawl(i, k):
    w = ease(min(1.0, k * 1.05))
    p = lerp([3.5, A, 10.6], [-17.5, A, 7.6], w)
    return (hide(i, lerp([-4.0, A + 3.0, 8.0], [-18.0, A + 3.4, 6.0], ease(k))),
            {"pos": p, "yaw": facing(p, [-24.0, A, 1.0]), "gait": "Search", "phase": w * 16 * WALK, "t": i / 30, "duck": 0.85})
shot("crawl", 60, s_crawl)

# 8. at the nest, his back to you, looking at the photos
NEST = [-26.5, A, 2.6]   # in front of his photo wall, between two roof ties (x -28.4 / -24.6)
def s_back(i, k):
    w = ease(min(1.0, k / 0.45))
    p = lerp([-19.5, A, 5.0], NEST, w)
    return (hide(i, [-23.0, A + 4.8, 1.0]),
            {"pos": p, "yaw": facing(p, [-28.3, A, 1.0]) if w > 0.9 else facing(p, NEST), "gait": "Walk" if w < 0.9 else "Stare",
             "phase": w * 7 * WALK, "t": i / 30, "duck": 0.6, "neck": [0.0, 0.0, 0.35 + 0.15 * math.sin(i * 0.05)]})
shot("back", 60, s_back)

# 9. nothing... his head slowly turns towards you... and he lunges (22.15 s: frame 64 of this shot)
def s_lunge(i, k):
    if i < 64:
        turn = ease(i / 60)
        yaw = facing(NEST, [-28.3, A, 1.0]) + (facing(NEST, HIDE) - facing(NEST, [-28.3, A, 1.0])) * 0.45 * turn
        return (hide(i, [-23.0, A + 5.0, 1.0], {"exposure": 2.6}),
                {"pos": NEST, "yaw": yaw, "gait": "Stare", "t": i / 30, "duck": 0.6, "neck": [0.0, 1.0 * turn, 0.3]})
    j = i - 64
    p = lerp([-18.5, A, -2.0], [-15.6, A, -4.6], ease(j / 4.0))
    return (hide(i, [p[0], A + 6.2, p[2]], {"exposure": 2.8, "glow": 12}),
            {"pos": p, "yaw": facing(p, HIDE), "gait": "Reach", "t": i / 30, "duck": 0.9, "neck": [0.0, 0.0, 0.3 * math.sin(i * 0.9)]})
shot("lunge", 75, s_lunge)

# 10. RUN: down in the hall, looking back: he slides down the ladder after you
def s_run(i, k):
    cam = [3.0 + 0.25 * math.sin(i * 1.7), U + 4.8 + 0.2 * math.sin(i * 2.3), 19.0 + 3.0 * k]
    p = lerp([6.0, U + 7.5, 11.0], [6.0, U, 14.6], ease(min(1.0, k * 1.4)))
    return (dict(DARK, shot="hallRun", cam={"pos": cam, "look": [6.0, U + 6.0, 11.0], "fov": 62, "roll": 0.05 * math.sin(i * 0.9)},
                 flash={"i": 18.0, "pos": [cam[0] + 0.6, cam[1] - 0.6, cam[2]], "target": [p[0], p[1] + 4.0, p[2]], "angle": 0.36},
                 ambient=0.01, exposure=1.7, glow=8, door=OPEN),
            {"pos": p, "yaw": facing(p, cam), "gait": "Chase", "phase": k * 15 * RUN, "t": i / 30})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
