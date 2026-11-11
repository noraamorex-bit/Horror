# Reel 74 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #1" (11 Nov; the owner: "Start from part 1 again with the original reel
# style. Make it high paced tension."). #2's exact format, look, music and slot lengths (314K: the attic mystery night by night),
# cut faster: every caption holds two or three quick shots, each cut a jolt. The v154 house and his v149 face (no mask, the
# textured body under Rig.SkinTint), and the game's new attic part: he comes up through the hatch after you.
#   hook (105)  the upstairs hall, lamps on, cosy, the hatch shut in the ceiling
#   card (120)  the same hall in the dark, a slow push under the hatch
#   72  "night 1: footsteps in the ceiling."   up at the ceiling, the torch chasing them | the hatch panel jumps in its frame
#   33  "night 4: the food went missing."      the fridge open: the dish licked clean
#   90  "night 9: the hatch was open."         the hatch down, the ladder out | from under it: him over the edge, pulling
#                                              back into the dark | up the ladder, fast
#   60  "so we went up."                       head up through the hatch: the sheeted chair, the dolls facing you | along the walkway
#   60  "photos. of us."                       his wall of the family's photos | the portrait, the faces scratched out
#   60  "he's been counting the days."         the tally marks | closer: the last one fresh
#   75  "then the ladder creaked."             a whip round to the hatch | his head and shoulders rise up through it... he
#                                              looks at you... and comes at you on 22.15 s (frame 64 of the slot)
#   30  "RUN."                                 crawling down the walkway, looking back: him scuttling after you
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau), shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.6
A = 29.4            # the attic walkway's top
CROUCH = A + 3.1    # eye height crouched under the rafters
TAU = math.tau
S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def shake(i, amt):
    return [amt * math.sin(i * 1.9), amt * 0.8 * math.sin(i * 2.7 + 1), amt * 0.6 * math.sin(i * 2.3 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]
def wrap(a): return ((a + math.pi) % TAU) - math.pi
def stop(i, fps=13): return math.floor(i * fps / 30) / fps
def him(pos, yaw, gait="Stare", phase=0.0, t=0.0, **opts):
    return {"pos": {"x": pos[0], "y": pos[1], "z": pos[2]}, "yaw": yaw, "gait": gait, "phase": phase, "t": t, "seed": 4, "opts": opts}

COLD, MOON, WARM = "#3d4f7a", "#6f86c4", "#ffb766"
FRIDGE_LIGHT = "#dfeaff"
# the hatch: the hole is x 4..8, z 8..14 in the hall ceiling (y 28.15); the panel hinges down at z = 8
HATCH = {"near": [6.0, 28.0, 11.0], "r": 4.5, "names": ["HatchPanel"], "hinge": [6.0, 28.15, 8.05], "axis": "x"}
NO_CORD = ["Cord", "CordHandle"]
NOCANDY = ["CandyWrap", "CandyBody"]
OPEN = math.pi / 2
FRIDGE = {"near": [-28.36, 7.8, 25.95], "r": 1.3, "names": ["FridgeDoor", "FridgeHandle"], "hinge": [-29.58, 0, 25.95], "axis": "y"}
FX = -28.36
LANTERN = {"p": [-19.0, 31.2, -3.4], "col": WARM, "b": 3.6, "r": 26, "decay": 1.2}
BELOWLIGHT = {"p": [6.0, 26.5, 11.5], "col": COLD, "b": 2.4, "r": 14, "decay": 1.1}     # the hall's moonlight up through the hole
ATTIC = [LANTERN, BELOWLIGHT, {"p": [30.0, 36.0, 0.0], "col": "#2c3d6e", "b": 0.8, "r": 40, "decay": 1.0}]
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [4, U + 8, 4], "col": COLD, "b": 1.2, "r": 16}]
KITCHEN = [{"p": [-38, 9, 14], "col": COLD, "b": 1.4, "r": 16}, {"p": [-24, 9, 29], "col": COLD, "b": 1.0, "r": 14},
           {"p": [-32, 9, 31], "col": MOON, "b": 2.2, "r": 18, "decay": 1.2}, {"p": [FX, 9.6, 25.0], "col": FRIDGE_LIGHT, "b": 3.2, "r": 12, "decay": 1.4}]
SHOTS = {
    "hallLit": {"center": [5, U + 6, 14], "radius": 30, "lampRadius": 30, "maxLamps": 6, "door": HATCH, "hide": NOCANDY},
    "hall": {"center": [5, U + 6, 14], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD + NOCANDY, "lights": HALL},
    "hallShut": {"center": [5, U + 6, 14], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NOCANDY, "lights": HALL},
    "below": {"center": [5, U + 6, 14], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD + NOCANDY,
              "lights": HALL + [{"p": [6, 31, 10], "col": WARM, "b": 0.7, "r": 10}]},
    "fridge": {"center": [-24, 6, 22], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": FRIDGE, "hide": NOCANDY, "lights": KITCHEN},
    "attic": {"center": [-8, 31, 3], "radius": 42, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD + NOCANDY, "lights": ATTIC},
}
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}

# --- props (film2 extras): the folding ladder down from the hatch; inside the fridge (the game hides its insides); the last tally
WOOD = [150, 118, 80]
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
LADDER, FRIDGEIN, FRESH = [], [], []
TOP, BOT = [9.2, 28.2], [14.3, U]     # (z, y) of the ladder's top (on the hatch frame) and its feet
L = math.hypot(TOP[0] - BOT[0], TOP[1] - BOT[1])
RX = -math.atan2(BOT[0] - TOP[0], TOP[1] - BOT[1])
for x in (5.1, 6.9):
    ex(LADDER, {"pos": [x, (TOP[1] + BOT[1]) / 2, (TOP[0] + BOT[0]) / 2], "s": [0.22, L, 0.45], "rot": [RX, 0, 0], "col": WOOD})
for j in range(1, 12):
    k = j / 12
    ex(LADDER, {"pos": [6.0, BOT[1] + (TOP[1] - BOT[1]) * k, BOT[0] + (TOP[0] - BOT[0]) * k], "s": [1.8, 0.16, 0.5], "rot": [RX, 0, 0], "col": WOOD})
WHITE, GLASS, FOIL = [232, 238, 240], [200, 222, 230], [196, 200, 206]
ex(FRIDGEIN, {"pos": [FX, 7.8, 26.12], "s": [2.3, 6.6, 0.05], "col": WHITE, "rough": 0.5})
for y in (5.9, 7.7, 9.4):
    ex(FRIDGEIN, {"pos": [FX, y, 25.75], "s": [2.2, 0.07, 0.75], "col": GLASS, "rough": 0.2})
ex(FRIDGEIN, {"pos": [FX + 0.1, 7.92, 25.72], "s": [1.6, 0.32, 0.72], "rot": [0, 0.08, 0], "col": FOIL, "rough": 0.3})         # the dish
ex(FRIDGEIN, {"pos": [FX + 0.1, 8.0, 25.72], "s": [1.4, 0.2, 0.6], "rot": [0, 0.08, 0], "col": [150, 60, 40], "rough": 0.6})    # what's left
ex(FRIDGEIN, {"pos": [FX + 0.7, 8.3, 25.6], "s": [0.07, 0.07, 1.0], "rot": [0.7, 0.4, 0], "col": [180, 184, 190], "rough": 0.2})  # the fork
ex(FRIDGEIN, {"pos": [FX - 0.8, 6.3, 25.75], "s": [0.6, 0.7, 0.5], "col": [245, 245, 240], "rough": 0.5})                       # milk
ex(FRIDGEIN, {"pos": [FX + 0.8, 9.75, 25.75], "s": [0.5, 0.65, 0.45], "col": [240, 150, 40], "rough": 0.5})                     # juice
# the newest tally mark: a pale fresh gouge across the last group
ex(FRESH, {"pos": [-28.17, 32.3, 5.74], "s": [0.04, 0.82, 0.07], "rot": [0.0, 0.0, 0.04], "col": [236, 222, 196], "rough": 0.7})
ALL = set(range(len(extras)))
def only(*groups):
    keep = set().union(*[set(g) for g in groups]) if groups else set()
    return sorted(ALL - keep)

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

# hook: the upstairs hall, lamps on: cosy; the hatch shut in the ceiling
def s_hook(i, k):
    cam = add(lerp([3.4, U + EYE, 25.0], [4.4, U + EYE - 0.1, 21.0], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="hallLit", cam={"pos": cam, "look": lerp([5.6, U + 6.0, 11.0], [5.8, U + 7.4, 11.0], ease(k)), "fov": 62}, door=0.0, hideIdx=only()), None)
shot("hook", 105, s_hook)

# card: the same hall in the dark, a push under the hatch
def s_card(i, k):
    cam = add(lerp([3.0, U + EYE, 25.5], [4.8, U + EYE - 0.2, 18.0], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="hallShut", cam={"pos": cam, "look": lerp([5.6, U + 6.4, 11.0], [6.0, U + 9.5, 11.0], ease(k)), "fov": 62}, exposure=4.4, door=0.0,
                 hideIdx=only()), None)
shot("card", 120, s_card)

# 1a. up at the ceiling, the torch chasing the footsteps across, fast
def s_steps(i, k):
    cam = add([5.4, U + EYE, 16.6], hand(i, 0.6))
    tgt = lerp([0.0, 28.0, 24.0], [6.5, 28.0, 10.0], ease(k))
    look = lerp([2.6, 28.0, 20.5], [6.0, 28.0, 12.0], ease(k))
    return (dict(DARK, shot="hallShut", cam={"pos": cam, "look": look, "fov": 64}, exposure=2.3, door=0.0, hideIdx=only(), flash=fl(cam, tgt, 8.0, 0.32)), None)
shot("steps", 36, s_steps)
# 1b. the hatch panel jumps in its frame (something stood on it)
def s_jump(i, k):
    cam = add(lerp([4.2, U + EYE - 0.3, 18.8], [4.6, U + EYE - 0.3, 17.6], ease(k)), hand(i, 0.8))
    bump = 0.0
    for t0 in (6, 17, 27):
        if t0 <= i < t0 + 4: bump = 0.12 * (1 - (i - t0) / 4)
    return (dict(DARK, shot="hallShut", cam={"pos": add(cam, shake(i, 0.04 if bump else 0)), "look": [6.0, 28.0, 11.0], "fov": 52}, exposure=2.4, door=bump,
                 hideIdx=only(), flash=fl(cam, [6.0, 28.1, 11.0], 9.0, 0.3)), None)
shot("jump", 36, s_jump)

# 2. the fridge open: the dish licked clean
def s_food(i, k):
    cam = add(lerp([-27.4, G + EYE + 0.9, 18.4], [-27.6, G + EYE + 0.9, 19.8], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="fridge", cam={"pos": cam, "look": [FX + 0.1, 7.6, 25.7], "fov": 46}, exposure=1.3, door=1.9, hideIdx=only(FRIDGEIN)), None)
shot("food", 33, s_food)

# 3a. the hatch down, the ladder out, the black hole above
def s_open(i, k):
    cam = add(lerp([3.2, U + EYE, 23.0], [4.8, U + EYE - 0.2, 18.5], ease(k)), hand(i))
    look = lerp([5.4, U + 6.6, 12.0], [6.0, 27.4, 11.0], ease(k))
    tgt = lerp([5.2, U + 3.0, 14.0], [6.0, 28.6, 10.8], ease(min(1.0, k * 1.2)))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 62}, exposure=2.0, door=OPEN, hideIdx=only(LADDER), flash=fl(cam, tgt, 12.0, 0.34)), None)
shot("open", 30, s_open)
# 3b. from under it, the torch up into the hole: him bent over the edge, looking down... he pulls back into the dark
EDGE = [6.0, A, 6.6]
CAMB = [5.9, U + 5.2, 15.0]
def s_edge(i, k):
    cam = add(CAMB, hand(i, 0.5))
    back = ease((i - 12) / 14)
    p = lerp(EDGE, [6.0, A, 4.6], back)
    cr = him(p, facing(p, cam), "Stare", t=2.0 + stop(i), Duck=1.5 - 1.2 * back, Look=[0.0, -1.0 + 0.6 * back])
    return (dict(DARK, shot="below", cam={"pos": cam, "look": [6.0, 28.4, 10.6], "fov": 58}, exposure=2.3, door=OPEN, hideIdx=only(LADDER),
                 flash=fl(cam, [6.0, 29.5, 9.6], 11.0, 0.32), glow=1.6 * (1 - back)), cr)
shot("edge", 30, s_edge)
# 3c. up the ladder, fast, the hole coming down at you
def s_climb(i, k):
    cam = add(lerp([6.0, U + 5.0, 15.6], [6.0, 26.6, 11.6], ease(k)), shake(i, 0.05))
    return (dict(DARK, shot="below", cam={"pos": cam, "look": add(cam, [0.0, 4.0, -1.4]), "fov": 64}, exposure=2.4, door=OPEN, hideIdx=only(LADDER),
                 flash=fl(cam, [6.0, 31.0, 10.0], 9.0, 0.36)), None)
shot("climb", 30, s_climb)

# 4a. head up through the hatch: the attic in the lantern's light, the torch across the sheeted chair and the dolls
def s_up(i, k):
    cam = add(lerp([6.0, 28.9, 11.4], [6.2, CROUCH, 10.8], ease(k)), hand(i, 0.6))
    look = lerp([8.0, 30.4, 3.0], [10.6, 31.6, -3.5], ease(k))
    return (dict(DARK, shot="attic", cam={"pos": cam, "look": look, "fov": 52 - 14 * ease(k)}, exposure=2.2, door=OPEN, hideIdx=only(LADDER),
                 flash=fl(cam, [10.6, 31.6, -3.5], 6.0, 0.22)), None)
shot("up", 30, s_up)
# 4b. along the walkway, crouched, towards his nest
def s_walk(i, k):
    cam = add(lerp([-2.0, CROUCH, 8.6], [-8.5, CROUCH - 0.2, 7.2], ease(k)), add(hand(i, 0.8), [0, 0.06 * math.sin(i * 0.9), 0]))
    tgt = lerp([-16.0, 29.8, 4.0], [-23.0, 29.8, 0.4], ease(k))
    return (dict(DARK, shot="attic", cam={"pos": cam, "look": [-22.0, 30.3, 0.0], "fov": 58}, exposure=2.0, door=OPEN, hideIdx=only(LADDER),
                 flash=fl(cam, tgt, 9.0, 0.36)), None)
shot("walk", 30, s_walk)

# 5a. his wall of the family's photos
def s_photos(i, k):
    cam = add(lerp([-23.0, CROUCH, 2.8], [-24.2, CROUCH - 0.1, 1.4], ease(k)), hand(i, 0.5))
    look = lerp([-28.3, 32.6, 2.2], [-28.3, 32.2, -0.2], ease(k))
    return (dict(DARK, shot="attic", cam={"pos": cam, "look": look, "fov": 52}, exposure=2.1, door=OPEN, hideIdx=only(LADDER), flash=fl(cam, look, 10.0, 0.3)), None)
shot("photos", 30, s_photos)
# 5b. the portrait, the faces scratched out: a hard push in
def s_portrait(i, k):
    cam = add(lerp([-24.6, CROUCH + 0.6, -0.2], [-26.6, 33.4, -1.2], ease(k)), hand(i, 0.4))
    look = [-28.2, 33.5, -1.4]
    return (dict(DARK, shot="attic", cam={"pos": cam, "look": look, "fov": 46 - 10 * ease(k)}, exposure=2.1, door=OPEN, hideIdx=only(LADDER),
                 flash=fl(cam, look, 10.0, 0.3)), None)
shot("portrait", 30, s_portrait)

# 6a. the tally marks
def s_tally(i, k):
    cam = add(lerp([-22.2, CROUCH + 0.1, 5.6], [-23.2, CROUCH, 5.1], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="attic", cam={"pos": cam, "look": [-28.3, 32.2, 4.4], "fov": 54}, exposure=2.1, door=OPEN, hideIdx=only(LADDER, FRESH),
                 flash=fl(cam, [-28.3, 32.3, 4.5], 10.0, 0.3)), None)
shot("tally", 30, s_tally)
# 6b. closer: the last one, fresh
def s_fresh(i, k):
    cam = add(lerp([-25.0, CROUCH - 0.4, 5.4], [-26.4, CROUCH - 0.6, 5.5], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="attic", cam={"pos": cam, "look": [-28.3, 32.0, 5.3], "fov": 40 - 6 * ease(k)}, exposure=2.1, door=OPEN, hideIdx=only(LADDER, FRESH),
                 flash=fl(cam, [-28.3, 32.0, 5.4], 9.0, 0.28)), None)
shot("fresh", 30, s_fresh)

# 7a. the ladder creaks: a whip round from the wall to the hatch
CAM7 = [-3.0, CROUCH - 0.3, 9.8]
def s_whip(i, k):
    w = ease(k * 1.3)
    look = lerp([-12.0, 30.6, 2.0], [6.0, 29.6, 11.2], w)
    return (dict(DARK, shot="attic", cam={"pos": add(CAM7, hand(i, 1.4)), "look": look, "fov": 60, "roll": 0.08 * math.sin(k * math.pi)}, exposure=2.3, door=OPEN,
                 hideIdx=only(LADDER), flash=fl(CAM7, look, 10.0, 0.34)), None)
shot("whip", 25, s_whip)
# 7b. his head and shoulders rise up through the hatch, lit from the hall below... he looks at you... still... and on
# frame 39 (slot frame 64, 22.15 s) he comes at you, jaw open
HOLE = [6.0, A, 11.4]
def s_rise(i, k):
    cam = add(CAM7, hand(i, 0.35 if i < 39 else 1.4))
    if i < 39:
        r = ease(i / 30)
        p = [HOLE[0], A - 10.5 + 7.0 * r, HOLE[2]]
        cr = him(p, facing(p, cam), "Stare", t=3.0 + stop(i), Look=[0.0, 0.1], Scream=0.15 * ease((i - 30) / 8))
        return (dict(DARK, shot="attic", cam={"pos": cam, "look": lerp([6.0, 30.0, 11.2], [6.0, 33.0, 11.4], r), "fov": 52}, exposure=2.3, door=OPEN,
                     hideIdx=only(LADDER), flash=fl(cam, [6.0, 31.5 + 2.0 * r, 11.4], 9.0, 0.3), glow=1.0 + 1.5 * r), cr)
    w = ease((i - 39) / 6)
    p = lerp([HOLE[0], A, HOLE[2] - 0.6], [-1.3, A, 9.9], w)
    cr = him(p, facing(p, cam), "Chase", phase=1.3 + 2.0 * w, t=3.0 + i / FPS, Scream=1.0)
    return (dict(DARK, shot="attic", cam={"pos": cam, "look": lerp([6.0, 33.0, 11.4], [p[0], A + 2.6, p[2]], w), "fov": 52 + 14 * w}, exposure=2.4, door=OPEN,
                 hideIdx=only(LADDER), flash=fl(cam, [p[0], A + 2.8, p[2]], 13.0, 0.45), glow=5.0), cr)
shot("rise", 50, s_rise)

# RUN: crawling down the walkway, looking back: him scuttling after you
def s_run(i, k):
    cam = [-6.0 - 6.0 * k + 0.25 * math.sin(i * 1.7), CROUCH - 0.4 + 0.2 * math.sin(i * 2.3), 7.8 - 0.8 * k]
    p = lerp([2.4, A, 9.6], [-4.6, A, 8.2], k)
    return (dict(DARK, shot="attic", cam={"pos": cam, "look": [p[0], A + 2.0, p[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [p[0] + 0.6 * math.sin(i * 1.3), A + 2.4, p[2]], 16.0, 0.36), ambient=0.01, exposure=2.0, glow=6, door=OPEN, hideIdx=only(LADDER)),
            him(p, facing(p, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/propcache"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
