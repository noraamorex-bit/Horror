# Reel 76 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #3" (14 Nov), #3 of the new run (74 = #1, 75 = #2): mom's texts (the 115K
# hook, #7 of the last run) meet the house's own camera. #2's exact format, look, music and slot lengths, cut fast (two or three
# shots a caption, each cut a jolt); the v157 house and his v156 body (the gaunt man).
#   hook (105)  the upstairs hall, lamps on, cosy, my door at the end of it
#   card (120)  the same hall in the dark, a slow push to my door
#   72  "night 13: mom texted "who's in the hall?""  the phone by my pillow lights up | from my door's crack: the hall, nobody
#   33  "nobody was."                                 out in the hall, the torch along it: empty
#   90  "night 14: "why is the hatch open?""          the hatch down, the ladder out | up under it: him over the edge, pulling back
#                                                     into the dark | back in my room, my door shut
#   60  "mom watches the cameras at work."            the hall camera up in its corner, its red light | its view: the hall, empty
#   60  "tonight: "he's outside your door.""          my phone in my hand, lit | my door, shut, the moonlight under it
#   60  ""don't open it.""                            the camera's view: him stooped at my door, his head against it | closer
#   75  ""he's not in the hall anymore.""             the camera's view: the hall empty, my door open | in bed, turn: he's
#                                                     crouched right there... and comes at you on 22.15 s (slot frame 64)
#   30  "RUN."                                        down the hall, looking back: him after you
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

COLD, MOON, WARM, SCREEN, RED = "#3d4f7a", "#6f86c4", "#ffb766", "#bcd0ff", "#ff2a2a"
NOCANDY = ["CandyWrap", "CandyBody"]
NO_CORD = ["Cord", "CordHandle"]
OPEN = math.pi / 2
HATCH = {"near": [6.0, 28.0, 11.0], "r": 4.5, "names": ["HatchPanel"], "hinge": [6.0, 28.15, 8.05], "axis": "x"}
JDOOR = {"near": [-8.0, U + 4.7, 24.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, 21.57], "axis": "y"}
BEDPHONE = [-36.6, U + 3.86, 15.2]
HCAM = [11.0, U + 12.4, 29.0]                # the house's camera, high in the hall's far corner
HLOOK = [-6.0, U + 3.0, 21.0]                # its view: down the hall to my door (and the hatch above)
def glowAt(p, b=1.4, r=5.0): return {"p": [p[0], p[1] + 0.5, p[2]], "col": SCREEN, "b": b, "r": r, "decay": 1.6}
MOONLIT = [{"p": [-24, U + 8.5, 28.6], "col": MOON, "b": 3.4, "r": 24, "decay": 1.0}, {"p": [-38.5, U + 8, 12], "col": MOON, "b": 2.2, "r": 18},
           {"p": [-14, U + 8, 14], "col": COLD, "b": 1.2, "r": 16}]
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [4, U + 8, 4], "col": COLD, "b": 1.2, "r": 16},
        {"p": [-3.5, U + 8, 24], "col": COLD, "b": 1.6, "r": 14, "decay": 1.2}]
REDDOT = [{"p": [HCAM[0] - 0.7, HCAM[1] - 0.1, HCAM[2] - 0.7], "col": RED, "b": 0.18, "r": 1.4, "decay": 2.0}]
UNDERDOOR = [{"p": [-6.6, U + 0.6, 22.9], "col": MOON, "b": 3.2, "r": 5.0, "decay": 1.6}]
SHOTS = {
    "hallLit": {"center": [0, U + 6, 18], "radius": 32, "lampRadius": 32, "maxLamps": 8, "door": JDOOR, "hide": NOCANDY},
    "hall": {"center": [0, U + 6, 18], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": JDOOR, "hide": NOCANDY, "lights": HALL},
    "hatch": {"center": [2, U + 6, 14], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD + NOCANDY,
              "lights": HALL + [{"p": [6, 31, 10], "col": WARM, "b": 0.35, "r": 8}]},
    "room": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + UNDERDOOR, "door": JDOOR, "hide": NOCANDY},
    "bedPhone": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + [glowAt(BEDPHONE, 0.8, 4)], "door": JDOOR,
                 "hide": NOCANDY},
    "roomHall": {"center": [-10, U + 5, 20], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + HALL, "door": JDOOR, "hide": NOCANDY},
}
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}

# --- props (film2 extras)
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
WOOD, BODY = [150, 118, 80], [18, 18, 20]
LADDER, PH_OFF, PH_ON, PH_HAND, CAMERA = [], [], [], [], []
TOP, BOT = [9.2, 28.2], [14.3, U]
L = math.hypot(TOP[0] - BOT[0], TOP[1] - BOT[1])
RX = -math.atan2(BOT[0] - TOP[0], TOP[1] - BOT[1])
for x in (5.1, 6.9):
    ex(LADDER, {"pos": [x, (TOP[1] + BOT[1]) / 2, (TOP[0] + BOT[0]) / 2], "s": [0.22, L, 0.45], "rot": [RX, 0, 0], "col": WOOD})
for j in range(1, 12):
    k = j / 12
    ex(LADDER, {"pos": [6.0, BOT[1] + (TOP[1] - BOT[1]) * k, BOT[0] + (TOP[0] - BOT[0]) * k], "s": [1.8, 0.16, 0.5], "rot": [RX, 0, 0], "col": WOOD})
def phone(group, p, rot, lit, bubbles=False):
    # a phone (~0.25 x 0.47 studs) and its screen; rot about x tilts it toward the camera; lit: a dim blue screen with two
    # message bubbles (a grey one in, a blue one out) or one grey bubble
    th = rot[0]
    n = [0.0, math.cos(th), math.sin(th)]
    zl = [0.0, -math.sin(th), math.cos(th)]
    def at(dx, dz, h): return [p[0] + dx + n[0] * h + zl[0] * dz, p[1] + n[1] * h + zl[1] * dz, p[2] + n[2] * h + zl[2] * dz]
    ex(group, {"pos": p, "s": [0.25, 0.03, 0.47], "rot": rot, "col": BODY, "rough": 0.3})
    if lit:
        ex(group, {"pos": at(0, 0, 0.017), "s": [0.22, 0.004, 0.42], "rot": rot, "col": [30, 44, 78], "emissive": [40, 62, 120], "ei": 0.55, "rough": 0.2})
        ex(group, {"pos": at(-0.03, -0.11, 0.021), "s": [0.13, 0.003, 0.05], "rot": rot, "col": [200, 204, 214], "emissive": [190, 196, 210], "ei": 0.7})
        if bubbles:
            ex(group, {"pos": at(-0.02, -0.02, 0.021), "s": [0.15, 0.003, 0.05], "rot": rot, "col": [200, 204, 214], "emissive": [190, 196, 210], "ei": 0.7})
            ex(group, {"pos": at(0.035, 0.07, 0.021), "s": [0.11, 0.003, 0.045], "rot": rot, "col": [60, 130, 255], "emissive": [60, 130, 255], "ei": 0.9})
    else:
        ex(group, {"pos": at(0, 0, 0.017), "s": [0.22, 0.004, 0.42], "rot": rot, "col": [8, 8, 10], "rough": 0.15})
phone(PH_OFF, BEDPHONE, [0.0, 0.0, 0.0], False)
phone(PH_ON, BEDPHONE, [0.0, 0.0, 0.0], True)
HANDCAM = [-26.0, U + 5.0, 22.6]               # sitting up in bed's foot, looking at the phone in my hand (toward -z)
HP = [HANDCAM[0] + 0.1, HANDCAM[1] - 0.3, HANDCAM[2] - 1.25]
phone(PH_HAND, HP, [math.atan2(HANDCAM[2] - HP[2], HANDCAM[1] - HP[1]), 0.0, 0.0], True, True)
# the camera up in the corner: a small white dome body on a bracket, a black lens, its red light
CY = math.atan2(HLOOK[0] - HCAM[0], HLOOK[2] - HCAM[2])
ex(CAMERA, {"pos": [HCAM[0] + 0.25, HCAM[1] + 0.35, HCAM[2] + 0.25], "s": [0.2, 0.7, 0.2], "col": [60, 60, 64], "rough": 0.5})
ex(CAMERA, {"pos": HCAM, "s": [0.7, 0.55, 1.0], "rot": [0.35, CY, 0], "col": [70, 70, 74], "rough": 0.45})
ex(CAMERA, {"pos": [HCAM[0] - 0.45 * math.sin(CY), HCAM[1] - 0.15, HCAM[2] - 0.45 * math.cos(CY)], "s": [0.38, 0.38, 0.2], "shape": "cyl",
            "rot": [math.pi / 2 + 0.35, CY, 0], "col": [10, 10, 12], "rough": 0.1})
ex(CAMERA, {"pos": [HCAM[0] - 0.42 * math.sin(CY) + 0.22 * math.cos(CY), HCAM[1] + 0.12, HCAM[2] - 0.42 * math.cos(CY) - 0.22 * math.sin(CY)],
            "s": [0.08, 0.08, 0.08], "col": [255, 30, 30], "emissive": [255, 30, 30], "ei": 1.4, "rough": 0.1})
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
        fr.setdefault("hideIdx", only(CAMERA))
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}
def cctv(extra=None, look=None, fov=78, ir=10.0):
    # the hall camera: perfectly still, wide, its own infrared light (the comp turns it grey night vision)
    lk = look or HLOOK
    fr = dict(DARK, shot="hall", cam={"pos": [HCAM[0] - 0.9, HCAM[1] - 0.4, HCAM[2] - 0.9], "look": lk, "fov": fov}, exposure=2.6, lamps=0,
              flash={"i": ir, "pos": [HCAM[0] - 1.0, HCAM[1] - 0.6, HCAM[2] - 1.0], "target": lk, "angle": 1.1}, hideIdx=only())
    if extra: fr.update(extra)
    return fr

# hook: the upstairs hall, lamps on, cosy, my door at the end of it
def s_hook(i, k):
    cam = add(lerp([10.0, U + EYE, 19.0], [7.0, U + EYE - 0.1, 20.6], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="hallLit", cam={"pos": cam, "look": lerp([-8.0, U + 4.6, 23.6], [-8.0, U + 4.4, 23.0], ease(k)), "fov": 68}, door=0.0), None)
shot("hook", 105, s_hook)
# card: the same hall in the dark, a push to my door
def s_card(i, k):
    cam = add(lerp([10.0, U + EYE, 19.4], [4.0, U + EYE - 0.2, 21.8], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [-8.0, U + 4.3, 22.8], "fov": 64}, exposure=4.2, door=0.0), None)
shot("card", 120, s_card)

# 1a. the phone by my pillow lights up in the dark
def s_txt(i, k):
    cam = add([-37.6, U + 5.0, 16.9], hand(i, 0.2))
    on = i >= 8
    return (dict(DARK, shot="bedPhone" if on else "room", cam={"pos": cam, "look": BEDPHONE, "fov": 40}, exposure=2.8, lamps=0, door=0.0,
                 hideIdx=only(PH_ON if on else PH_OFF)), None)
shot("txt", 36, s_txt)
# 1b. from my door's crack: the hall, dark, nobody
def s_crack(i, k):
    cam = add(lerp([-12.4, U + 5.4, 23.1], [-12.0, U + 5.4, 23.2], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="roomHall", cam={"pos": cam, "look": [4.0, U + 5.0, 24.6], "fov": 52}, exposure=4.6, door=1.0), None)
shot("crack", 36, s_crack)

# 2. "nobody was." out in the hall, the torch along it: empty
def s_empty(i, k):
    cam = add(lerp([-3.6, U + EYE, 23.0], [-2.4, U + EYE, 22.4], ease(k)), hand(i, 0.7))
    tgt = lerp([4.0, U + 3.0, 26.0], [6.0, U + 3.0, 6.0], ease(k))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": lerp([4.0, U + 4.0, 25.0], [6.0, U + 4.6, 8.0], ease(k)), "fov": 60}, exposure=2.4, door=1.75,
                 flash=fl(cam, tgt, 9.0, 0.36)), None)
shot("empty", 33, s_empty)

# 3a. the hatch down, the ladder out
def s_hopen(i, k):
    cam = add(lerp([3.0, U + EYE, 22.0], [4.6, U + EYE - 0.2, 18.4], ease(k)), hand(i))
    look = lerp([5.6, U + 7.0, 12.0], [6.0, 27.6, 11.0], ease(k))
    return (dict(DARK, shot="hatch", cam={"pos": cam, "look": look, "fov": 60}, exposure=2.0, door=OPEN, hideIdx=only(LADDER, CAMERA),
                 flash=fl(cam, [6.0, 28.6, 10.8], 12.0, 0.34)), None)
shot("hopen", 30, s_hopen)
# 3b. up under it: him over the edge of the hole, looking down... pulling back into the dark
def s_hole(i, k):
    cam = add([5.9, U + 5.2, 15.0], hand(i, 0.5))
    back = ease((i - 12) / 14)
    p = lerp([6.0, 29.4, 6.6], [6.0, 29.4, 4.6], back)
    cr = him(p, facing(p, cam), "Stare", t=2.0 + stop(i), Duck=1.5 - 1.2 * back, Look=[0.0, -1.0 + 0.6 * back])
    return (dict(DARK, shot="hatch", cam={"pos": cam, "look": [6.0, 28.4, 10.6], "fov": 58}, exposure=2.3, door=OPEN, hideIdx=only(LADDER, CAMERA),
                 flash=fl(cam, [6.0, 29.5, 9.6], 11.0, 0.32), glow=1.6 * (1 - back)), cr)
shot("hole", 30, s_hole)
# 3c. back in my room: my door pushed shut, from inside
def s_hshut(i, k):
    cam = add(lerp([-17.0, U + 5.2, 22.0], [-16.4, U + 5.2, 22.2], ease(k)), shake(i, 0.03 * (1 - k)))
    return (dict(DARK, shot="roomHall", cam={"pos": cam, "look": [-8.0, U + 4.4, 22.9], "fov": 60}, exposure=3.6, door=0.9 * (1 - ease(i / 9))), None)
shot("hshut", 30, s_hshut)

# 4a. "mom watches the cameras at work." the hall camera up in its corner, its red light
def s_hcam(i, k):
    cam = add(lerp([5.0, U + 7.6, 23.4], [6.4, U + 8.2, 24.6], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": HCAM, "fov": 40 - 6 * ease(k)}, exposure=2.6, door=0.0, hideIdx=only(CAMERA),
                 flash=fl(cam, HCAM, 1.6, 0.3)), None)
shot("hcam", 30, s_hcam)
# 4b. its view: the hall, empty, my door shut
def s_cview(i, k):
    return (cctv({"door": 0.0}), None)
shot("cview", 30, s_cview)

# 5a. "tonight: "he's outside your door."" my phone in my hand, lit
def s_txt2(i, k):
    cam = add(HANDCAM, hand(i, 0.35))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [HP[0], HP[1] - 0.05, HP[2]], "fov": 48}, exposure=2.6, lamps=0, door=0.0,
                 hideIdx=only(PH_HAND)), None)
shot("txt2", 30, s_txt2)
# 5b. my door, shut, the moonlight under it (a shadow crosses it)
def s_door(i, k):
    cam = add(lerp([-30.0, U + 4.8, 20.4], [-28.4, U + 4.7, 20.8], ease(k)), hand(i, 0.3))
    shadow = 14 <= i < 24
    lights = None
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-8.0, U + 3.0, 22.8], "fov": 46 - 6 * ease(k)}, exposure=4.6, door=0.0,
                 ambient=0.02 if not shadow else 0.012), None)
shot("door", 30, s_door)

# 6. ""don't open it."" the camera's view: him stooped at my door, his head against it... then closer (the camera's zoom)
ATDOOR = [-6.3, U, 22.8]
def s_atdoor(i, k):
    zoom = ease((i - 30) / 14)
    look = lerp(HLOOK, [-6.6, U + 8.4, 22.8], zoom)
    cr = him(ATDOOR, facing(ATDOOR, [-9.0, U, 22.8]), "Stare", t=3.0 + stop(i), Duck=0.75, Look=[0.0, -0.15])
    return (cctv({"door": 0.0, "glow": 3.4}, look=look, fov=78 - 40 * zoom, ir=20.0), cr)
shot("atdoor", 60, s_atdoor)

# 7a. ""he's not in the hall anymore."" the camera's view: the hall empty, my door open
def s_gone(i, k):
    return (cctv({"door": 1.75}), None)
shot("gone", 25, s_gone)
# 7b. in bed: turn to the side of the bed: he's crouched right there, his face level with mine; he comes at me on frame 39 of
# this shot (slot frame 64, 22.15 s)
BEDEYE = [-37.9, U + 4.7, 16.2]
SIDE = [-34.9, U, 23.6]
def s_turn(i, k):
    cam = add(BEDEYE, hand(i, 0.3))
    t = ease((i - 2) / 18)
    door = [-8.0, U + 4.0, 22.8]
    y0, y1 = facing(cam, door), facing(cam, SIDE)
    yaw = y0 + wrap(y1 - y0) * t
    ly = door[1] + ((U + 7.0) - door[1]) * ease((i - 6) / 16)
    dist = 8.0
    look = [cam[0] - math.sin(yaw) * dist, ly, cam[2] - math.cos(yaw) * dist]
    if i < 39:
        fr = dict(DARK, shot="room", cam={"pos": cam, "look": look, "fov": 52}, exposure=2.6, lamps=0, door=1.75, glow=2.4 if t > 0.5 else 0.8,
                  flash=fl(cam, look, 6.0 * t, 0.4))
        return (fr, him(SIDE, facing(SIDE, cam), "Stare", t=3.0 + stop(i), Duck=1.0, Look=[0.0, -0.2], Scream=0.2 * ease((i - 30) / 9)))
    w = ease((i - 39) / 4)
    near = [cam[0] + 0.9, U, cam[2] + 3.8]
    p = lerp(SIDE, near, w)
    camw = add(cam, [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    fr = dict(DARK, shot="room", cam={"pos": camw, "look": lerp(look, [p[0], U + 8.4, p[2]], w), "fov": 52 + 10 * w}, exposure=2.6, lamps=0,
              door=1.75, glow=7.0, flash=fl(camw, [p[0], U + 6.5, p[2]], 14.0, 0.5))
    return (fr, him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Look=[0.0, -0.3]))
shot("turn", 50, s_turn)

# RUN: out of my room and down the hall, looking back: him after you on all fours
def s_run(i, k):
    cam = [-2.0 + 6.0 * k + 0.25 * math.sin(i * 1.7), U + 5.0 + 0.2 * math.sin(i * 2.3), 23.6 - 4.0 * k]
    hp = lerp([-14.5, U, 23.0], [-6.0, U, 23.0], k)
    return (dict(DARK, shot="roomHall", cam={"pos": cam, "look": [hp[0], U + 2.8, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)}, door=1.75,
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), U + 3.2, hp[2]], 16.0, 0.36), ambient=0.01, exposure=2.0, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/propcache"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
