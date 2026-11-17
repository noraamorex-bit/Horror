# Reel 79 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #6" (17 Nov), #6 of the new run (74-78 = #1-#5): the closet door. Every
# night my wardrobe is open a little wider; I tape it shut; tonight the tape's on the floor and the closet's empty... so where is
# he? (beside my bed). An everyday fear turned, #2's exact format, look, music and slot lengths, cut fast; the v157 house and his
# v156 body (the gaunt man).
#   hook (105)  my room, the lamps on, cosy, the wardrobe in the corner
#   card (120)  the same room in the dark, a slow push to the wardrobe, one door open a crack
#   72  "night 19: my closet door was open."       from my pillow: the wardrobe, a crack | closer: the dark in the crack
#   33  "i shut it."                               close: the door pushed shut
#   90  "night 20: wider."                         from my pillow: open wider | the gap, close: black inside | my bedroom door
#                                                  open a crack too
#   60  "so i taped it shut."                      close: tape across the doors | from my pillow: the wardrobe, taped
#   60  "tonight the tape was on the floor."       close: torn strips on the floor | the wardrobe wide open
#   60  "the closet was empty."                    the torch into it: nothing inside | my door, shut
#   75  "so where was he?"                         the torch across my room: nothing | back in bed, turn: he's crouched right
#                                                  beside it... and comes at you on 22.15 s (slot frame 64)
#   30  "RUN."                                     out of my room and down the hall, looking back: him after you
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

COLD, MOON = "#3d4f7a", "#6f86c4"
NOCANDY = ["CandyWrap", "CandyBody"]
# my room (Jamie's): the bed x -39.15..-31.35, z 13.3..18.3; my door in the x = -8 wall at z 24 (hinged at z 21.57); my wardrobe
# x -19.35..-13.65, its front at z 26.47 facing -z; the left leaf hinged at x -19.4 (negative opens it into the room)
JDOOR = {"near": [-8.0, U + 4.7, 24.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, 21.57], "axis": "y"}
WARD = {"near": [-17.96, U + 4.5, 26.47], "r": 1.5, "names": ["WardrobeLeaf", "Handle", "DoorPanel", "PanelInset"], "hinge": [-19.4, 0, 26.47], "axis": "y"}
WFRONT = [-16.5, U + 4.5, 26.3]
MOONLIT = [{"p": [-24, U + 8.5, 28.6], "col": MOON, "b": 3.4, "r": 24, "decay": 1.0}, {"p": [-38.5, U + 8, 12], "col": MOON, "b": 2.2, "r": 18},
           {"p": [-14, U + 8, 14], "col": COLD, "b": 1.2, "r": 16}]
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [4, U + 8, 4], "col": COLD, "b": 1.2, "r": 16},
        {"p": [-3.5, U + 8, 24], "col": COLD, "b": 1.6, "r": 14, "decay": 1.2}]
SHOTS = {
    "jlit": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 30, "maxLamps": 8, "door": JDOOR, "door2": WARD},
    "room": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": JDOOR, "door2": WARD, "lights": MOONLIT},
    "roomHall": {"center": [-10, U + 5, 20], "radius": 34, "lampRadius": 0, "maxLamps": 0, "door": JDOOR, "door2": WARD, "lights": MOONLIT + HALL},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}

# --- props (film2 extras): the tape across the doors; the torn strips on the floor
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
TAPE, TORN = [], []
GREY = [118, 120, 126]
for y, rz in ((U + 2.6, 0.12), (U + 4.4, -0.08), (U + 6.2, 0.15), (U + 7.6, -0.1)):
    ex(TAPE, {"pos": [-16.5, y, 26.33], "s": [1.9, 0.22, 0.02], "rot": [0, 0, rz], "col": GREY, "rough": 0.6})
for x, z, ry, l in ((-17.6, 25.2, 0.6, 1.3), (-16.2, 24.6, -0.9, 1.0), (-15.1, 25.6, 1.8, 0.9), (-17.0, 24.0, 2.6, 0.7)):
    ex(TORN, {"pos": [x, U + 0.04, z], "s": [l, 0.02, 0.22], "rot": [0, ry, 0.0], "col": GREY, "rough": 0.6})
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
        fr.setdefault("hideIdx", only())
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}

BEDEYE = [-37.9, U + 4.7, 16.2]          # lying in bed, my head on the pillow
PILLOWLOOK = [-16.6, U + 4.4, 26.4]      # from there: the wardrobe
CRACK1, CRACK2 = -0.18, -0.5

def pillow(i, door2, hide=None, fov=34, door=0.0, extra=None):
    cam = add(BEDEYE, hand(i, 0.2))
    fr = dict(DARK, shot="room", cam={"pos": cam, "look": PILLOWLOOK, "fov": fov}, exposure=3.6, lamps=0, door=door, door2=door2)
    if hide is not None: fr["hideIdx"] = hide
    if extra: fr.update(extra)
    return fr

# hook: my room, the lamps on, cosy, the wardrobe in the corner
def s_hook(i, k):
    cam = add(lerp([-30.0, U + EYE, 18.0], [-28.0, U + EYE - 0.1, 19.0], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="jlit", cam={"pos": cam, "look": lerp([-17.0, U + 4.0, 26.0], [-16.5, U + 4.0, 26.0], ease(k)), "fov": 64}, door=0.0, door2=0.0), None)
shot("hook", 105, s_hook)
# card: the same room in the dark, a slow push to the wardrobe, its door open a crack
def s_card(i, k):
    cam = add(lerp([-28.0, U + EYE, 18.0], [-22.0, U + EYE - 0.2, 21.0], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-16.6, U + 4.4, 26.4], "fov": 58}, exposure=4.2, door=0.0, door2=CRACK1), None)
shot("card", 120, s_card)

# 1a. "night 19: my closet door was open." from my pillow: the wardrobe, a crack
def s_p1(i, k):
    return (pillow(i, CRACK1, fov=34 - 6 * ease(k)), None)
shot("p1", 36, s_p1)
# 1b. closer: the dark in the crack
def s_c1(i, k):
    cam = add(lerp([-20.0, U + 5.0, 21.0], [-19.2, U + 5.0, 22.4], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-16.8, U + 4.6, 26.4], "fov": 44}, exposure=3.4, door=0.0, door2=CRACK1,
                 flash=fl(cam, [-16.7, U + 4.6, 26.4], 0.6, 0.5)), None)
shot("c1", 36, s_c1)

# 2. "i shut it." close: the door pushed shut
def s_shut(i, k):
    cam = add(lerp([-18.6, U + 5.0, 22.6], [-18.2, U + 5.0, 23.0], ease(k)), shake(i, 0.02 * ease((i - 14) / 4) * (1 - ease((i - 18) / 6))))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-16.8, U + 4.6, 26.4], "fov": 46}, exposure=3.4, door=0.0,
                 door2=CRACK1 * (1 - ease((i - 6) / 10)), flash=fl(cam, [-16.7, U + 4.6, 26.4], 1.0, 0.5)), None)
shot("shut", 33, s_shut)

# 3a. "night 20: wider." from my pillow: open wider
def s_p2(i, k):
    return (pillow(i, CRACK2, fov=34 - 4 * ease(k)), None)
shot("p2", 30, s_p2)
# 3b. the gap, close: black inside
def s_c2(i, k):
    cam = add(lerp([-19.8, U + 5.0, 21.6], [-19.0, U + 5.0, 22.6], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-17.4, U + 4.6, 26.0], "fov": 46}, exposure=3.4, door=0.0, door2=CRACK2,
                 flash=fl(cam, [-17.4, U + 4.6, 26.2], 1.0, 0.5)), None)
shot("c2", 30, s_c2)
# 3c. my bedroom door, open a crack too, the hall dark
def s_bdoor(i, k):
    cam = add(BEDEYE, hand(i, 0.2))
    return (dict(DARK, shot="roomHall", cam={"pos": cam, "look": [-8.6, U + 4.8, 23.4], "fov": 40}, exposure=3.6, lamps=0, door=0.5, door2=CRACK2), None)
shot("bdoor", 30, s_bdoor)

# 4a. "so i taped it shut." close: tape across the doors
def s_tape(i, k):
    cam = add(lerp([-15.4, U + 4.9, 22.4], [-15.8, U + 4.8, 23.2], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-16.5, U + 4.6, 26.4], "fov": 48}, exposure=3.4, door=0.0, door2=0.0, hideIdx=only(TAPE),
                 flash=fl(cam, [-16.5, U + 4.6, 26.4], 1.4, 0.55)), None)
shot("tape", 30, s_tape)
# 4b. from my pillow: the wardrobe, taped
def s_ptape(i, k):
    return (pillow(i, 0.0, hide=only(TAPE), fov=30), None)
shot("ptape", 30, s_ptape)

# 5a. "tonight the tape was on the floor." close: torn strips on the floor in front of it
def s_torn(i, k):
    cam = add(lerp([-15.0, U + 3.2, 21.6], [-15.6, U + 3.0, 22.0], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-16.6, U + 0.2, 24.8], "fov": 50}, exposure=3.4, door=0.0, door2=-1.3, hideIdx=only(TORN),
                 flash=fl(cam, [-16.6, U + 0.2, 24.8], 1.6, 0.6)), None)
shot("torn", 30, s_torn)
# 5b. the wardrobe wide open
def s_wide(i, k):
    cam = add(lerp([-15.0, U + EYE, 19.2], [-15.6, U + EYE - 0.1, 20.2], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-17.8, U + 4.4, 27.0], "fov": 52}, exposure=3.4, door=0.0, door2=-1.3, hideIdx=only(TORN),
                 flash=fl(cam, [-17.6, U + 4.4, 26.8], 1.2, 0.55)), None)
shot("wide", 30, s_wide)

# 6a. "the closet was empty." the torch into it: nothing inside
def s_inside(i, k):
    cam = add(lerp([-17.9, U + 5.2, 20.6], [-17.9, U + 5.0, 22.0], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-17.9, U + 4.2, 27.6], "fov": 50}, exposure=3.2, door=0.0, door2=-1.3, hideIdx=only(TORN),
                 flash=fl(cam, [-18.2, U + 3.8, 28.0], 1.4, 0.45)), None)
shot("inside", 30, s_inside)
# 6b. my door, shut
def s_mydoor(i, k):
    cam = add(lerp([-18.0, U + EYE, 22.0], [-17.4, U + EYE, 22.2], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-8.0, U + 4.4, 23.6], "fov": 52}, exposure=3.4, door=0.0, door2=-1.3, hideIdx=only(TORN),
                 flash=fl(cam, [-8.2, U + 4.0, 23.6], 1.6, 0.4)), None)
shot("mydoor", 30, s_mydoor)

# 7a. "so where was he?" the torch across my room: nothing
def s_sweep(i, k):
    cam = add([-20.0, U + EYE, 20.0], hand(i, 0.6))
    tgt = lerp([-12.0, U + 2.0, 14.0], [-33.0, U + 2.0, 12.0], ease(k))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp([-12.0, U + 3.4, 14.0], [-33.0, U + 3.4, 13.0], ease(k)), "fov": 58}, exposure=3.0,
                 door=0.0, door2=-1.3, hideIdx=only(TORN), flash=fl(cam, tgt, 6.0, 0.36)), None)
shot("sweep", 25, s_sweep)
# 7b. back in bed: turn to the side of the bed: he's crouched right there, his face level with mine; he comes at me on frame 39
# of this shot (slot frame 64, 22.15 s)
SIDE = [-34.9, U, 23.6]
def s_turn(i, k):
    cam = add(BEDEYE, hand(i, 0.3))
    t = ease((i - 2) / 18)
    y0, y1 = facing(cam, PILLOWLOOK), facing(cam, SIDE)
    yaw = y0 + wrap(y1 - y0) * t
    ly = PILLOWLOOK[1] + ((U + 7.0) - PILLOWLOOK[1]) * ease((i - 6) / 16)
    dist = 8.0
    look = [cam[0] - math.sin(yaw) * dist, ly, cam[2] - math.cos(yaw) * dist]
    if i < 39:
        fr = dict(DARK, shot="room", cam={"pos": cam, "look": look, "fov": 52}, exposure=2.6, lamps=0, door=0.0, door2=-1.3, hideIdx=only(TORN),
                  glow=2.4 if t > 0.5 else 0.8, flash=fl(cam, look, 6.0 * t, 0.4))
        return (fr, him(SIDE, facing(SIDE, cam), "Stare", t=3.0 + stop(i), Duck=1.0, Look=[0.0, -0.2], Scream=0.2 * ease((i - 30) / 9)))
    w = ease((i - 39) / 4)
    near = [cam[0] + 1.6, U, cam[2] + 5.4]
    p = lerp(SIDE, near, w)
    camw = add(add(cam, [0, 1.1 * w, 0]), [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    fr = dict(DARK, shot="room", cam={"pos": camw, "look": lerp(look, [p[0], U + 8.0, p[2]], w), "fov": 52 + 6 * w}, exposure=2.6, lamps=0,
              door=0.0, door2=-1.3, hideIdx=only(TORN), glow=4.0, flash=fl(camw, [p[0], U + 6.0, p[2]], 6.0, 0.5))
    return (fr, him(p, facing(p, cam), "Stare", t=3.0 + stop(i), Duck=1.0 + 0.4 * w, Scream=1.0, Look=[0.0, -0.6]))
shot("turn", 50, s_turn)

# RUN: out of my room and down the hall, looking back: him after you on all fours
def s_run(i, k):
    cam = [-2.0 + 6.0 * k + 0.25 * math.sin(i * 1.7), U + 5.0 + 0.2 * math.sin(i * 2.3), 23.6 - 4.0 * k]
    hp = lerp([-14.5, U, 23.0], [-6.0, U, 23.0], k)
    return (dict(DARK, shot="roomHall", cam={"pos": cam, "look": [hp[0], U + 2.8, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)}, door=1.75,
                 door2=-1.3, flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), U + 3.2, hp[2]], 16.0, 0.36), ambient=0.01, exposure=2.0, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/propcache"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
