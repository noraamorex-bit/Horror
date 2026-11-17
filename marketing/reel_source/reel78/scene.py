# Reel 78 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #5" (17 Nov), #5 of the new run (74-77 = #1-#4): hide and seek. An everyday
# game turned: Lily always hides in her closet; one night she says someone else is playing too; tonight it's my turn to hide, in my
# wardrobe, and someone starts counting... but Lily's asleep. #2's exact format, look, music and slot lengths, cut fast; the v157
# house and his v156 body (the gaunt man). The hiding view through the wardrobe's crack is the game's own.
#   hook (105)  Lily's room, the lamp on, cosy
#   card (120)  the same room in the dark, a slow push to her wardrobe
#   72  "night 17: lily wanted to play hide and seek."  her room by moonlight | the upstairs hall, the torch along it (counting)
#   33  "she always hid in her closet."                 her wardrobe, one door ajar, the dark inside
#   90  "night 18: "someone else is playing too.""       her wardrobe ajar again | from her doorway: him in her far corner, his back
#                                                       to the room | the hall, empty
#   60  "tonight it was my turn to hide."               my wardrobe, its door open | from inside it, through the crack: my dark room
#   60  "someone started counting."                     through the crack: my dark room | a shadow crosses the floor by the bed
#   60  "but lily was asleep."                          her door ajar, her bed, the duvet over her | through the crack: nothing
#   75  "so who was counting?"                          through the crack: his legs go past, close | the crack, nothing... the door
#                                                       torn open: him stooped in it, at you on 22.15 s (slot frame 64)
#   30  "RUN."                                          out of my room and down the hall, looking back: him after you
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
def stop(i, fps=13): return math.floor(i * fps / 30) / fps
def him(pos, yaw, gait="Stare", phase=0.0, t=0.0, **opts):
    return {"pos": {"x": pos[0], "y": pos[1], "z": pos[2]}, "yaw": yaw, "gait": gait, "phase": phase, "t": t, "seed": 4, "opts": opts}

COLD, MOON, WARM, PINK = "#3d4f7a", "#6f86c4", "#ffb766", "#ff9fc4"
NOCANDY = ["CandyWrap", "CandyBody"]
# my room (Jamie's): the bed x -39.15..-31.35, z 13.3..18.3; my door in the x = -8 wall at z 24 (hinged at z 21.57); my wardrobe
# x -19.35..-13.65, its front at z 26.47 facing -z, two leaves: the left one hinged at x -19.4 (negative opens it into the room)
JDOOR = {"near": [-8.0, U + 4.7, 24.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, 21.57], "axis": "y"}
WARD = {"near": [-17.96, U + 4.5, 26.47], "r": 1.5, "names": ["WardrobeLeaf", "Handle", "DoorPanel", "PanelInset"], "hinge": [-19.4, 0, 26.47], "axis": "y"}
# Lily's room: her door in the x = 12 wall at z 20 (hinged at z 17.55); her bed x ~29..41 at z ~25.7; her wardrobe x 13.3..18.1,
# its front at z 11.33 facing +z, the left leaf hinged at x 13.3
LILYDOOR = {"near": [12.0, U + 4.7, 20.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [12.0, 0, 17.55], "axis": "y"}
LWARD = {"near": [14.49, U + 4.5, 11.33], "r": 1.3, "names": ["WardrobeLeaf", "Handle", "DoorPanel", "PanelInset"], "hinge": [13.3, 0, 11.33], "axis": "y"}
MOONLIT = [{"p": [-24, U + 8.5, 28.6], "col": MOON, "b": 3.4, "r": 24, "decay": 1.0}, {"p": [-38.5, U + 8, 12], "col": MOON, "b": 2.2, "r": 18},
           {"p": [-14, U + 8, 14], "col": COLD, "b": 1.2, "r": 16}]
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [4, U + 8, 4], "col": COLD, "b": 1.2, "r": 16},
        {"p": [-3.5, U + 8, 24], "col": COLD, "b": 1.6, "r": 14, "decay": 1.2}]
LROOM = [{"p": [13.6, U + 2.2, 27.5], "col": PINK, "b": 1.4, "r": 16, "decay": 1.3},
         {"p": [26.0, U + 8.0, 31.5], "col": MOON, "b": 3.4, "r": 24, "decay": 1.1},
         {"p": [30.0, U + 8.0, 12.0], "col": COLD, "b": 1.2, "r": 16}]
SHOTS = {
    "lilyLit": {"center": [26, U + 5, 19], "radius": 30, "lampRadius": 30, "maxLamps": 8, "door": LILYDOOR, "door2": LWARD},
    "lily": {"center": [26, U + 5, 19], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR, "door2": LWARD,
             "lights": LROOM + [{"p": [6, U + 8, 18], "col": COLD, "b": 1.6, "r": 16}]},
    "lilyHall": {"center": [14, U + 6, 19], "radius": 34, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR, "door2": LWARD, "lights": LROOM + HALL},
    "hall": {"center": [0, U + 6, 18], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": JDOOR, "lights": HALL},
    "room": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": JDOOR, "door2": WARD, "lights": MOONLIT},
    "roomHall": {"center": [-10, U + 5, 20], "radius": 34, "lampRadius": 0, "maxLamps": 0, "door": JDOOR, "door2": WARD, "lights": MOONLIT + HALL},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}
extras = []
def only(*groups): return []

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
        fr.setdefault("hideIdx", [])
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}

AJAR = float(os.environ.get("AJAR", "0.95"))      # Lily's wardrobe door, ajar
CRACK = float(os.environ.get("CRACK", "-0.5"))    # my wardrobe's left door, the crack I watch through

# hook: Lily's room, the lamp on, cosy
def s_hook(i, k):
    cam = add(lerp([13.4, U + EYE, 19.8], [15.4, U + EYE - 0.1, 20.6], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="lilyLit", cam={"pos": cam, "look": lerp([34.0, U + 3.4, 26.0], [32.0, U + 3.2, 24.0], ease(k)), "fov": 66}, door=1.4, door2=0.0), None)
shot("hook", 105, s_hook)
# card: the same room in the dark, a slow push to her wardrobe
def s_card(i, k):
    cam = add(lerp([24.0, U + EYE, 24.0], [20.0, U + EYE - 0.2, 20.0], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="lily", cam={"pos": cam, "look": [15.7, U + 4.2, 11.4], "fov": 60}, exposure=5.0, door=1.4, door2=AJAR,
                 flash=fl(cam, [15.2, U + 4.4, 11.4], 1.4, 0.5)), None)
shot("card", 120, s_card)

# 1a. "night 17: lily wanted to play hide and seek." her room by moonlight, the bed, the toys
def s_room(i, k):
    cam = add(lerp([14.2, U + EYE, 18.6], [16.0, U + EYE - 0.1, 19.4], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="lily", cam={"pos": cam, "look": [33.0, U + 3.0, 25.0], "fov": 62}, exposure=3.4, door=1.4, door2=0.0), None)
shot("lroom", 36, s_room)
# 1b. the upstairs hall, the torch along it (she counts, I go looking)
def s_count(i, k):
    cam = add(lerp([10.0, U + EYE, 20.0], [8.4, U + EYE, 20.6], ease(k)), hand(i, 0.7))
    tgt = lerp([-6.0, U + 3.0, 23.0], [4.0, U + 3.0, 6.0], ease(k))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": lerp([-6.0, U + 4.4, 23.0], [4.0, U + 4.6, 8.0], ease(k)), "fov": 60}, exposure=3.4, door=0.0,
                 flash=fl(cam, tgt, 9.0, 0.36)), None)
shot("count", 36, s_count)

# 2. "she always hid in her closet." her wardrobe, one door ajar, the dark inside; a slow push in
def s_lward(i, k):
    cam = add(lerp([19.6, U + 5.2, 19.0], [18.8, U + 5.0, 17.4], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="lily", cam={"pos": cam, "look": [14.6, U + 4.4, 11.3], "fov": 50}, exposure=3.0, door=1.4, door2=AJAR,
                 flash=fl(cam, [14.4, U + 4.4, 11.4], 1.2, 0.55)), None)
shot("lward", 33, s_lward)

# 3a. "night 18: "someone else is playing too."" her wardrobe ajar again, closer
def s_lward2(i, k):
    cam = add(lerp([18.0, U + 4.8, 16.4], [17.4, U + 4.7, 15.4], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="lily", cam={"pos": cam, "look": [14.4, U + 4.4, 11.0], "fov": 44}, exposure=3.0, door=1.4, door2=AJAR,
                 flash=fl(cam, [14.0, U + 4.6, 11.4], 1.0, 0.55)), None)
shot("lward2", 30, s_lward2)
# 3b. from her doorway: him standing in her far corner by the window, his back to the room; his head turns a little
CORNER = [34.5, U, 16.5]
def s_corner(i, k):
    cam = add([11.0, U + EYE, 19.8], hand(i, 0.25))
    cr = him(CORNER, facing(CORNER, [44.0, U, 12.0]), "Stare", t=2.0 + stop(i), Duck=0.3, Look=[0.35 * ease((i - 12) / 14), 0.0])
    return (dict(DARK, shot="lilyHall", cam={"pos": cam, "look": [CORNER[0], U + 5.2, CORNER[2]], "fov": 44}, exposure=3.4, door=1.4, door2=0.0, glow=1.2), cr)
shot("corner", 30, s_corner)
# 3c. back in the hall: empty
def s_hall(i, k):
    cam = add(lerp([6.0, U + EYE, 18.0], [5.2, U + EYE, 18.4], ease(k)), hand(i, 0.6))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [-6.0, U + 4.2, 23.4], "fov": 58}, exposure=2.6, door=0.0,
                 flash=fl(cam, [-6.0, U + 3.4, 23.4], 7.0, 0.34)), None)
shot("hall", 30, s_hall)

# 4a. "tonight it was my turn to hide." my wardrobe, its left door open
def s_mward(i, k):
    cam = add(lerp([-11.5, U + EYE, 19.0], [-12.6, U + EYE - 0.1, 20.6], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-17.6, U + 4.2, 26.8], "fov": 54}, exposure=3.2, door=0.6, door2=-1.3,
                 flash=fl(cam, [-17.2, U + 4.2, 26.6], 1.2, 0.55)), None)
shot("mward", 30, s_mward)
# 4b. from inside it, through the crack: my dark room
EYEIN = json.loads(os.environ.get("EYEIN", "[-16.75, 20.2, 27.1]"))
def crackview(i, look=None, door=0.6, crack=CRACK, extra=None):
    cam = add(EYEIN, hand(i, 0.12))
    lk = look or [-19.5, U + 4.2, 17.0]
    if os.environ.get("LOOKIN"): lk = json.loads(os.environ["LOOKIN"])
    fr = dict(DARK, shot="roomHall", cam={"pos": cam, "look": lk, "fov": 62}, exposure=3.4, door=door, door2=crack)
    if extra: fr.update(extra)
    return fr
def s_in(i, k):
    return (crackview(i, crack=CRACK * (1.6 - 0.6 * ease(i / 12))), None)
shot("in", 30, s_in)

# 5a. "someone started counting." through the crack: my room, the moonlight on the floor
def s_dopen(i, k):
    return (crackview(i, look=lerp([-19.5, U + 4.2, 17.0], [-20.5, U + 3.6, 17.5], ease(k)), door=1.7), None)
shot("dopen", 30, s_dopen)
# 5b. a shadow crosses the floor, far off, by the bed
def s_dway(i, k):
    p = lerp([-30.0, U, 14.0], [-24.0, U, 12.0], k)
    return (crackview(i, look=[-21.0, U + 3.6, 17.0], door=1.7, extra={"glow": 0.2}),
            him(p, facing(p, [-20.0, U, 11.0]), "Walk", phase=k * 1.6 * TAU, t=1.0 + i / FPS) if 6 <= i <= 26 else None)
shot("dway", 30, s_dway)

# 6a. "but lily was asleep." her door ajar from the hall, her bed beyond it, the duvet over her
def s_asleep(i, k):
    cam = add(lerp([9.0, U + EYE, 21.6], [9.6, U + EYE, 21.0], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="lilyHall", cam={"pos": cam, "look": [34.0, U + 3.2, 25.4], "fov": 42}, exposure=3.2, door=0.7, door2=0.0), None)
shot("asleep", 30, s_asleep)
# 6b. through the crack again: nothing, the door open, the hall black
def s_nothing(i, k):
    return (crackview(i, door=1.7), None)
shot("nothing", 30, s_nothing)

# 7a. "so who was counting?" through the crack: his legs go past, close, left to right
def s_legs(i, k):
    p = lerp([-18.5, U, 23.0], [-9.5, U, 22.4], k)
    cam = add(EYEIN, hand(i, 0.12))
    return (crackview(i, look=[-17.0, U + 3.4, 20.0], door=1.7, extra={"glow": 1.6, "flash": fl(cam, [p[0], U + 2.0, p[2]], 1.2, 0.6)}),
            him(p, facing(p, [-8.0, U, 23.6]), "Walk", phase=k * 3.0 * TAU, t=2.0 + i / FPS))
shot("legs", 25, s_legs)
# 7b. the crack, nothing... silence... then the door is torn open and he's stooped right there; on frame 39 (slot frame 64,
# 22.15 s) he comes at you
OUTSIDE = [-15.9, U, 22.0]
def s_found(i, k):
    cam = add(EYEIN, hand(i, 0.12 if i < 34 else 1.2))
    if i < 34:
        return (crackview(i, door=1.7), None)
    w = ease((i - 34) / 2)
    open_ = CRACK + (-0.9 - CRACK) * w
    lunge = ease((i - 39) / 5)
    p = lerp(OUTSIDE, [-16.15, U, 23.15], lunge)
    cr = him(p, facing(p, cam), "Stare", t=3.0 + i / FPS, Duck=1.5, Scream=0.3 + 0.7 * lunge, Look=[0.0, -0.6])
    camw = add(cam, [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    return (dict(DARK, shot="roomHall", cam={"pos": camw, "look": lerp([-19.5, U + 4.2, 17.0], [p[0], U + 6.4 + 1.6 * lunge, p[2]], w), "fov": 62 + 10 * lunge},
                 exposure=3.0, door=1.7, door2=open_, glow=4.0, flash=fl(camw, [p[0], U + 6.4, p[2]], 4.0 * w, 0.5)), cr)
shot("found", 50, s_found)

# RUN: out of my room and down the hall, looking back: him after you on all fours
def s_run(i, k):
    cam = [-2.0 + 6.0 * k + 0.25 * math.sin(i * 1.7), U + 5.0 + 0.2 * math.sin(i * 2.3), 23.6 - 4.0 * k]
    hp = lerp([-14.5, U, 23.0], [-6.0, U, 23.0], k)
    return (dict(DARK, shot="roomHall", cam={"pos": cam, "look": [hp[0], U + 2.8, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)}, door=1.75,
                 door2=-1.6, flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), U + 3.2, hp[2]], 16.0, 0.36), ambient=0.01, exposure=2.0, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/propcache"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
