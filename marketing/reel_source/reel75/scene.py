# Reel 75 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #2" (11 Nov), the sequel to reel 74's #1 (he came up through the hatch):
# now he comes down. #2's exact format, look, music and slot lengths, cut fast (two or three shots a caption, each cut a
# jolt); the v154 house and his v149 face.
#   hook (105)  my room (Jamie's), the lamps on, cosy
#   card (120)  the same room in the moonlight, a slow push to the bed
#   72  "night 10: scratching above my bed."   from my pillow, the torch up on the ceiling | the hall: the hatch jumps
#   33  "night 11: the hatch was open again."  the hatch down, the ladder out, the black hole
#   90  "night 12: wet footprints. to my room." the prints from under the ladder down the hall | at my door, ajar |
#                                               across my floor to my bed
#   60  "so we nailed it shut."                 the hatch with three boards across it | close: the nails
#   60  "tonight i heard the nails."            a board hanging off the hatch, swinging | the nails on the hall floor
#   60  "the hatch was open."                   the boards on the floor, the ladder down | a push up into the hole: empty
#   75  "he was already down here."             under the hatch, looking up | turn round: he's standing right behind you,
#                                               stooped under the ceiling... and comes at you on 22.15 s (slot frame 64)
#   30  "RUN."                                  down the hall, looking back: him after you on all fours
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau), shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.6
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
NOCANDY = ["CandyWrap", "CandyBody"]
NO_CORD = ["Cord", "CordHandle"]
OPEN = math.pi / 2
HATCH = {"near": [6.0, 28.0, 11.0], "r": 4.5, "names": ["HatchPanel"], "hinge": [6.0, 28.15, 8.05], "axis": "x"}
JDOOR = {"near": [-8.0, U + 4.7, 24.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, 21.57], "axis": "y"}
MOONLIT = [{"p": [-24, U + 8.5, 28.6], "col": MOON, "b": 3.4, "r": 24, "decay": 1.0}, {"p": [-38.5, U + 8, 12], "col": MOON, "b": 2.2, "r": 18},
           {"p": [-14, U + 8, 14], "col": COLD, "b": 1.2, "r": 16}]
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [4, U + 8, 4], "col": COLD, "b": 1.2, "r": 16},
        {"p": [-3.5, U + 8, 24], "col": COLD, "b": 1.6, "r": 14, "decay": 1.2}]
SHOTS = {
    "lit": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 30, "maxLamps": 8, "door": JDOOR, "hide": NOCANDY},
    "room": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + HALL, "door": JDOOR, "hide": NOCANDY},
    "hallShut": {"center": [2, U + 6, 14], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NOCANDY, "lights": HALL},
    "hall": {"center": [2, U + 6, 14], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD + NOCANDY, "lights": HALL},
    "door": {"center": [-6, U + 6, 20], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": JDOOR, "hide": NOCANDY, "lights": HALL + MOONLIT},
}
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}

# --- props (film2 extras)
WOOD, RAW, IRON, WET = [150, 118, 80], [176, 146, 104], [60, 60, 64], [24, 20, 18]
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
LADDER, PRINTS, BOARDS, NAILHEADS, LOOSE, NAILS, FLOOR = [], [], [], [], [], [], []
TOP, BOT = [9.2, 28.2], [14.3, U]
L = math.hypot(TOP[0] - BOT[0], TOP[1] - BOT[1])
RX = -math.atan2(BOT[0] - TOP[0], TOP[1] - BOT[1])
for x in (5.1, 6.9):
    ex(LADDER, {"pos": [x, (TOP[1] + BOT[1]) / 2, (TOP[0] + BOT[0]) / 2], "s": [0.22, L, 0.45], "rot": [RX, 0, 0], "col": WOOD})
for j in range(1, 12):
    k = j / 12
    ex(LADDER, {"pos": [6.0, BOT[1] + (TOP[1] - BOT[1]) * k, BOT[0] + (TOP[0] - BOT[0]) * k], "s": [1.8, 0.16, 0.5], "rot": [RX, 0, 0], "col": WOOD})
# the wet prints: from under the ladder, down the hall, through my door, across my floor to the bed
def rot(x, z, a): return [x * math.cos(a) + z * math.sin(a), -x * math.sin(a) + z * math.cos(a)]
PATH = [[5.6, 15.2], [4.6, 22.6], [-2.0, 24.2], [-9.6, 23.6], [-31.0, 19.0]]
side = 1
for (a, b) in zip(PATH, PATH[1:]):
    dx, dz = b[0] - a[0], b[1] - a[1]
    Lg = math.hypot(dx, dz); fx, fz = dx / Lg, dz / Lg
    rx, rz = -fz, fx
    pyaw = math.atan2(-fx, -fz)
    d_ = 0.8
    while d_ < Lg - 0.3:
        side = -side
        cx, cz = a[0] + fx * d_ + rx * side * 0.42, a[1] + fz * d_ + rz * side * 0.42
        for (lx, lz, sx, sz) in [(0, 0.05, 0.34, 0.9), (0, 0.45, 0.4, 0.34)]:
            o = rot(lx, lz, pyaw)
            ex(PRINTS, {"pos": [cx + o[0], U + 0.13, cz + o[1]], "s": [sx, 0.02, sz], "rot": [0, pyaw, 0], "col": WET, "rough": 0.25})
        for k2, aa in enumerate([-0.32, 0.0, 0.32]):
            o = rot(0, -0.66 - (0.06 if k2 == 1 else 0), pyaw - aa)
            ex(PRINTS, {"pos": [cx + o[0], U + 0.13, cz + o[1]], "s": [0.09, 0.02, 0.46], "rot": [0, pyaw - aa, 0], "col": WET, "rough": 0.25})
        d_ += 2.3
# three boards nailed across the hatch (just under the ceiling), with nail heads at their ends
for z in (8.9, 11.0, 13.1):
    ex(BOARDS, {"pos": [6.0, 27.9, z], "s": [7.2, 0.22, 0.95], "col": RAW, "rough": 0.8})
    for x in (2.8, 9.2):
        for dz in (-0.22, 0.22):
            ex(NAILHEADS, {"pos": [x, 27.77, z + dz], "s": [0.12, 0.04, 0.12], "col": IRON, "rough": 0.3})
# tonight: the middle board torn off at one end, hanging; the other two gone from the hatch
for z in (8.9, 13.1):
    ex(BOARDS, {"pos": [6.0, 27.9, z], "s": [7.2, 0.22, 0.95], "col": RAW, "rough": 0.8})
BOARDS_TWO = BOARDS[-2:]
BOARDS_ALL = BOARDS[:3]
def loose_board(a):
    return {"pos": [9.2 - 3.6 * math.cos(a), 27.9 - 3.6 * math.sin(a), 11.0], "s": [7.2, 0.22, 0.95], "rot": [0, 0, a], "col": RAW, "rough": 0.8}
ex(LOOSE, loose_board(1.2))
LOOSE_I = LOOSE[0]
# the nails, bent, on the hall floor under the hatch
for n_, (x, z, a) in enumerate([(5.1, 12.4, 0.3), (6.6, 11.6, 1.4), (7.2, 13.0, 2.2), (5.8, 10.6, 0.9), (4.6, 11.2, 2.8), (6.9, 9.8, 0.1)]):
    ex(NAILS, {"pos": [x, U + 0.06, z], "s": [0.05, 0.05, 0.62], "rot": [0, a, 0.2 * (n_ % 2)], "col": IRON, "rough": 0.3})
    ex(NAILS, {"pos": [x + 0.3 * math.sin(a), U + 0.07, z + 0.3 * math.cos(a)], "s": [0.13, 0.03, 0.13], "col": IRON, "rough": 0.3})
# the boards on the floor (6a)
ex(FLOOR, {"pos": [4.2, U + 0.12, 13.8], "s": [7.2, 0.22, 0.95], "rot": [0, 0.5, 0], "col": RAW, "rough": 0.8})
ex(FLOOR, {"pos": [7.6, U + 0.12, 9.6], "s": [7.2, 0.22, 0.95], "rot": [0, -0.3, 0], "col": RAW, "rough": 0.8})
ex(FLOOR, {"pos": [6.0, U + 0.34, 12.4], "s": [7.2, 0.22, 0.95], "rot": [0, 1.2, 0.04], "col": RAW, "rough": 0.8})
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

# hook: my room, lamps and fairy lights on
def s_hook(i, k):
    cam = add(lerp([-12.5, U + 6.2, 21.0], [-14.5, U + 6.0, 20.4], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([-34.0, U + 3.4, 17.0], [-34.5, U + 3.3, 16.8], ease(k)), "fov": 60}, door=0.0, hideIdx=only()), None)
shot("hook", 105, s_hook)
# card: the same room in the moonlight, a push to the bed
def s_card(i, k):
    cam = add(lerp([-12.0, U + 6.4, 21.5], [-17.0, U + 6.0, 20.0], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-35.0, U + 3.2, 16.4], "fov": 60}, exposure=4.2, lamps=0, door=0.0, hideIdx=only()), None)
shot("card", 120, s_card)

# 1a. from my pillow, the torch up on the ceiling, chasing the scratching
def s_ceil(i, k):
    cam = add([-36.6, U + 4.7, 15.6], hand(i, 0.5))
    tgt = lerp([-33.0, U + 13.0, 19.5], [-37.5, U + 13.0, 14.0], ease(k))
    for t0 in (10, 22):
        if t0 <= i < t0 + 5: tgt = add(tgt, [0.3 * math.sin(i * 3.1), 0, 0.3 * math.cos(i * 2.7)])
    look = lerp([-34.0, U + 12.0, 18.0], [-36.8, U + 12.5, 15.2], ease(k))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": look, "fov": 62}, exposure=2.6, door=0.0, hideIdx=only(), flash=fl(cam, tgt, 7.0, 0.3)), None)
shot("ceil", 36, s_ceil)
# 1b. the hall: the hatch jumps in its frame
def s_jump(i, k):
    cam = add(lerp([4.2, U + EYE - 0.3, 18.8], [4.6, U + EYE - 0.3, 17.4], ease(k)), hand(i, 0.8))
    bump = 0.0
    for t0 in (4, 13, 24):
        if t0 <= i < t0 + 4: bump = 0.14 * (1 - (i - t0) / 4)
    return (dict(DARK, shot="hallShut", cam={"pos": add(cam, shake(i, 0.04 if bump else 0)), "look": [6.0, 28.0, 11.0], "fov": 52}, exposure=2.4, door=bump,
                 hideIdx=only(), flash=fl(cam, [6.0, 28.1, 11.0], 9.0, 0.3)), None)
shot("jump", 36, s_jump)

# 2. the hatch down again, the ladder out
def s_open(i, k):
    cam = add(lerp([3.4, U + EYE, 22.0], [4.8, U + EYE - 0.2, 18.2], ease(k)), hand(i))
    look = lerp([5.6, U + 8.0, 12.0], [6.0, 27.6, 11.0], ease(k))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 60}, exposure=2.0, door=OPEN, hideIdx=only(LADDER), flash=fl(cam, [6.0, 28.6, 10.8], 12.0, 0.34)), None)
shot("open", 33, s_open)

# 3a. the prints from the foot of the ladder, down the hall (the torch following them)
def s_p1(i, k):
    cam = add(lerp([5.0, U + EYE, 11.0], [4.8, U + EYE, 12.6], ease(k)), hand(i, 0.5))
    tgt = lerp([5.4, U, 16.0], [3.0, U, 23.4], ease(k))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": lerp([5.0, U + 0.5, 17.0], [3.4, U + 0.5, 23.0], ease(k)), "fov": 58}, exposure=2.4, door=OPEN,
                 hideIdx=only(LADDER, PRINTS), flash=fl(cam, tgt, 8.0, 0.4)), None)
shot("p1", 30, s_p1)
# 3b. to my door, ajar
def s_p2(i, k):
    cam = add(lerp([2.6, U + EYE, 24.4], [0.4, U + EYE - 0.1, 24.2], ease(k)), hand(i, 0.6))
    tgt = lerp([-3.0, U + 0.2, 24.0], [-7.8, U + 3.0, 23.6], ease(k))
    return (dict(DARK, shot="door", cam={"pos": cam, "look": [-7.8, U + 2.4, 23.2], "fov": 56}, exposure=2.6, door=0.55, hideIdx=only(PRINTS),
                 flash=fl(cam, tgt, 8.0, 0.4)), None)
shot("p2", 30, s_p2)
# 3c. across my floor, to my bed
def s_p3(i, k):
    cam = add(lerp([-10.5, U + EYE, 23.6], [-14.0, U + EYE - 0.2, 22.8], ease(k)), hand(i, 0.6))
    tgt = lerp([-16.0, U, 22.0], [-31.0, U + 1.6, 18.6], ease(k))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp([-20.0, U + 0.6, 21.6], [-31.5, U + 2.0, 18.0], ease(k)), "fov": 56}, exposure=2.6, door=1.1,
                 hideIdx=only(PRINTS), flash=fl(cam, tgt, 8.0, 0.4)), None)
shot("p3", 30, s_p3)

# 4a. so we nailed it shut: the hatch with three boards across it
def s_nail(i, k):
    cam = add(lerp([3.4, U + EYE, 19.6], [4.4, U + EYE - 0.2, 17.0], ease(k)), hand(i, 0.6))
    return (dict(DARK, shot="hallShut", cam={"pos": cam, "look": [6.0, 27.8, 11.0], "fov": 56}, exposure=2.4, door=0.0, hideIdx=only(BOARDS_ALL, NAILHEADS),
                 flash=fl(cam, [6.0, 27.9, 11.0], 9.0, 0.36)), None)
shot("nail", 30, s_nail)
# 4b. close: the boards' ends, the nails
def s_nail2(i, k):
    cam = add(lerp([8.4, U + EYE + 1.6, 15.6], [8.8, U + EYE + 2.4, 14.4], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="hallShut", cam={"pos": cam, "look": [9.2, 27.8, 11.4], "fov": 44 - 8 * ease(k)}, exposure=2.4, door=0.0, hideIdx=only(BOARDS_ALL, NAILHEADS),
                 flash=fl(cam, [9.2, 27.8, 11.2], 7.0, 0.3)), None)
shot("nail2", 30, s_nail2)

# 5a. tonight: a board hanging off the hatch by one end, swinging
def s_loose(i, k):
    cam = add(lerp([3.2, U + EYE, 20.6], [4.0, U + EYE - 0.1, 18.6], ease(k)), hand(i, 0.7))
    a = 1.15 + 0.12 * math.sin(i * 0.32) * (1 - 0.5 * k)
    ex_over = {LOOSE_I: loose_board(a)}
    return (dict(DARK, shot="hallShut", cam={"pos": cam, "look": [7.0, 25.5, 11.0], "fov": 56}, exposure=2.4, door=0.0, hideIdx=only(BOARDS_TWO, LOOSE),
                 extrasOver={str(kk): v for kk, v in ex_over.items()}, flash=fl(cam, [7.6, 25.6, 11.0], 9.0, 0.34)), None)
shot("loose", 30, s_loose)
# 5b. the nails on the hall floor, bent
def s_nails(i, k):
    cam = add(lerp([3.4, U + 3.6, 15.2], [4.0, U + 3.2, 14.4], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="hallShut", cam={"pos": cam, "look": [6.0, U, 11.6], "fov": 48 - 6 * ease(k)}, exposure=2.4, door=0.0, hideIdx=only(BOARDS_TWO, NAILS),
                 flash=fl(cam, [6.0, U, 11.6], 6.0, 0.36)), None)
shot("nails", 30, s_nails)

# 6a. the hatch open, the boards on the floor, the ladder down
def s_open2(i, k):
    cam = add(lerp([3.0, U + EYE, 21.6], [4.2, U + EYE - 0.1, 19.4], ease(k)), hand(i, 0.8))
    look = lerp([5.6, U + 1.0, 13.0], [6.0, U + 9.0, 11.4], ease(k))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 58}, exposure=2.2, door=OPEN, hideIdx=only(LADDER, FLOOR, NAILS),
                 flash=fl(cam, lerp([5.4, U, 13.0], [6.0, 27.0, 11.0], ease(k)), 10.0, 0.36)), None)
shot("open2", 30, s_open2)
# 6b. a push up into the hole: empty
def s_hole(i, k):
    cam = add(lerp([5.8, U + 5.2, 15.6], [5.9, U + 6.4, 13.6], ease(k)), hand(i, 0.6))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [6.0, 30.0, 10.6], "fov": 60 - 10 * ease(k)}, exposure=2.4, door=OPEN, hideIdx=only(LADDER, FLOOR, NAILS),
                 flash=fl(cam, [6.0, 31.0, 10.4], 10.0, 0.3)), None)
shot("hole", 30, s_hole)

# 7a. under the hatch, looking up
CAM7 = [5.4, U + EYE, 14.6]
def s_up(i, k):
    cam = add(CAM7, hand(i, 0.4))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [6.0, 29.0, 11.0], "fov": 60}, exposure=2.4, door=OPEN, hideIdx=only(LADDER, FLOOR, NAILS),
                 flash=fl(cam, [6.0, 30.0, 10.8], 10.0, 0.3)), None)
shot("up7", 20, s_up)
# 7b. turn round: he's standing right behind you, stooped under the ceiling... and on frame 44 (slot frame 64, 22.15 s)
# he comes at you, jaw open
BEHIND = [4.8, U, 20.4]
def s_turn(i, k):
    w = ease(i / 9)
    look = lerp([6.0, 29.0, 11.0], [BEHIND[0], U + 8.4, BEHIND[2]], w)
    cam = add(CAM7, hand(i, 1.2 if i < 10 else (0.35 if i < 44 else 1.4)))
    if i < 44:
        cr = him(BEHIND, facing(BEHIND, cam), "Stare", t=4.0 + stop(i), Duck=0.6, Look=[0.0, -0.3], Scream=0.15 * ease((i - 36) / 8))
        return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 58, "roll": 0.06 * math.sin(w * math.pi)}, exposure=2.4, door=OPEN,
                     hideIdx=only(LADDER, FLOOR, NAILS), flash=fl(cam, [BEHIND[0], U + 8.2, BEHIND[2]], 10.0, 0.34), glow=2.4), cr)
    v = ease((i - 44) / 5)
    p = lerp(BEHIND, [5.2, U, 18.5], v)
    cr = him(p, facing(p, cam), "Reach", t=4.0 + i / FPS, Scream=1.0, Duck=0.6)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": lerp(look, [p[0], U + 10.3, p[2]], v), "fov": 58 + 12 * v}, exposure=2.4, door=OPEN,
                 hideIdx=only(LADDER, FLOOR, NAILS), flash=fl(cam, [p[0], U + 7.8, p[2]], 13.0, 0.45), glow=5.0), cr)
shot("turn", 55, s_turn)

# RUN: down the hall (away from him), looking back: him after you on all fours
def s_run(i, k):
    cam = [3.6 + 0.25 * math.sin(i * 1.7), U + 5.0 + 0.2 * math.sin(i * 2.3), 6.0 - 7.0 * k]
    p = lerp([4.6, U, 17.0], [4.2, U, 9.0], k)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [p[0], U + 2.8, p[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [p[0] + 0.6 * math.sin(i * 1.3), U + 3.2, p[2]], 16.0, 0.36), ambient=0.01, exposure=2.0, glow=6, door=OPEN,
                 hideIdx=only(LADDER, FLOOR, NAILS)),
            him(p, facing(p, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/propcache"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
