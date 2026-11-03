# Reel 63 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #16" (3 Nov; #7, mom's texts, 115K: everyday things with a quoted twist
# win). #2's exact format, look, music and slot lengths; a new everyday hook: Lily's walkie-talkies (one by her bed, one by mine).
# Mine crackled at 3 am: "is she asleep?" The next night: "which bed is hers?" So I took her walkie. Tonight mine crackled
# again: "i can see you." ... "turn around." He wears the porcelain mask, as in the game, and shows himself twice before the scare.
#   hook (105)  Lily's room, the light on, cosy
#   card (120)  the same room in the dark, a slow push to her bed
#   72  "night 55: my walkie-talkie crackled."   in bed: the walkie by my pillow, its red light on
#   33  ""is she asleep?""                        Lily's room from her door: him standing at the foot of her bed
#   90  "night 56: "which bed is hers?""          him bent over her bed... his head comes round to me
#   60  "so i took lily's walkie."                 her walkie in my hand in the upstairs hall
#   60  "tonight mine crackled again."             in bed: the walkie by my pillow, the red light, closer
#   60  ""i can see you.""                         the walkie lowered: the empty upstairs hall, a slow step
#   75  ""turn around.""                           turn round: he's right behind me; he comes on 22.15 s
#   30  "RUN."                                     down the hall, him after me on all fours
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau + mask.json), shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.6
TAU = math.tau
S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
SIGN = float(os.environ.get("SIGN", "-1"))       # (his head turns round to his right with a negative yaw: reel 51)

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]
def wrap(a): return ((a + math.pi) % TAU) - math.pi
def stop(i, fps=13): return math.floor(i * fps / 30) / fps
def him(pos, yaw, gait="Stare", phase=0.0, t=0.0, **opts):
    return {"pos": {"x": pos[0], "y": pos[1], "z": pos[2]}, "yaw": yaw, "gait": gait, "phase": phase, "t": t, "seed": 4, "opts": opts}

COLD, MOON, PINK, WARM, RED = "#3d4f7a", "#6f86c4", "#ff9fc4", "#ffd9a0", "#ff3a2a"
NOCANDY = ["CandyWrap", "CandyBody"]
# --- Lily's room (reels 51/58): x 12..40, z 8.5..29.3; her door in the x = 12 wall at z 20 (hinged at z 17.55); her bed x 32..38.5,
# z 22.2..29.1 (headboard at z 29.1)
LILYDOOR = {"near": [12.0, U + 4.7, 20.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [12.0, 0, 17.55], "axis": "y"}
ROOM = [{"p": [13.6, U + 2.2, 27.5], "col": PINK, "b": 1.6, "r": 16, "decay": 1.3},          # her night light
        {"p": [26.0, U + 8.0, 31.5], "col": MOON, "b": 3.4, "r": 24, "decay": 1.1},           # the window
        {"p": [30.0, U + 8.0, 12.0], "col": COLD, "b": 1.2, "r": 16}]
LHALL = [{"p": [6, U + 8, 18], "col": COLD, "b": 1.6, "r": 16}]
# --- my room (Jamie's; reels 56/58/61): the bed x -39.15..-31.35, z 13.3..18.3; the door in the x = -8 wall at z 24
JDOOR = {"near": [-8.0, U + 4.7, 24.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, 21.57], "axis": "y"}
MOONLIT = [{"p": [-24, U + 8.5, 28.6], "col": MOON, "b": 3.4, "r": 24, "decay": 1.0}, {"p": [-38.5, U + 8, 12], "col": MOON, "b": 2.2, "r": 18},
           {"p": [-14, U + 8, 14], "col": COLD, "b": 1.2, "r": 16}]
WT = [-36.7, U + 4.22, 15.0]                 # my walkie, standing on the bed by the pillow
def ledAt(p, b=0.1, r=1.6): return {"p": [p[0], p[1] + 0.3, p[2] + 0.3], "col": RED, "b": b, "r": r, "decay": 2.0}
# --- the upstairs hall (reels 52/56)
HATCH = {"near": [6.0, 28.0, 11.0], "r": 4.5, "names": ["HatchPanel"], "hinge": [6.0, 28.15, 8.05], "axis": "x"}
NO_CORD = ["Cord", "CordHandle"]
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [4, U + 8, 4], "col": COLD, "b": 1.2, "r": 16}]
HANDCAM = [4.2, U + 5.3, 26.4]
HW = [HANDCAM[0] + 0.1, HANDCAM[1] - 0.35, HANDCAM[2] - 1.2]   # her walkie, held up in front of me
SHOTS = {
    "lit": {"center": [26, U + 5, 19], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR,
            "lights": [{"p": [26, U + 11.0, 19], "col": WARM, "b": 4.2, "r": 32, "decay": 1.0}] + ROOM},
    "room": {"center": [26, U + 5, 19], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR, "hide": ["Bulb", "Globe", "Base", "Finial"],
             "lights": ROOM + LHALL},
    "jdark": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT, "door": JDOOR},
    "jled": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + [ledAt(WT)], "door": JDOOR},
    "hand": {"center": [4, U + 6, 16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD,
             "lights": HALL + [{"p": [HANDCAM[0], HANDCAM[1] + 0.6, HANDCAM[2] - 0.3], "col": COLD, "b": 1.3, "r": 3.2}]},
    "hall": {"center": [4, U + 6, 16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "lights": HALL},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 0}

# --- props (film2 extras): a kid's walkie-talkie (yellow and black, a stubby antenna, a speaker grille, a red light)
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
W_OFF, W_ON, H_ON = [], [], []
YEL, BLK = [228, 182, 40], [24, 24, 26]
def walkie(group, p, rot, lit, upright=False):
    # local axes: the body's face points along its local +z when upright; lying flat, the face points up (+y)
    yaw, pitch = rot
    def at(dx, dy, dz):
        # rotate (dx, dy, dz) by pitch about x, then yaw about y
        cy, sy = math.cos(pitch), math.sin(pitch)
        y1, z1 = dy * cy - dz * sy, dy * sy + dz * cy
        cyw, syw = math.cos(yaw), math.sin(yaw)
        return [p[0] + dx * cyw + z1 * syw, p[1] + y1, p[2] - dx * syw + z1 * cyw]
    r = [pitch, yaw, 0.0]
    ex(group, {"pos": at(0, 0, 0), "s": [0.34, 0.72, 0.16], "rot": r, "col": YEL, "rough": 0.55})
    ex(group, {"pos": at(0, -0.08, 0.085), "s": [0.26, 0.3, 0.02], "rot": r, "col": BLK, "rough": 0.7})            # the grille
    for j in range(4):
        ex(group, {"pos": at(0, -0.18 + 0.07 * j, 0.097), "s": [0.2, 0.02, 0.006], "rot": r, "col": [70, 70, 74]})
    ex(group, {"pos": at(0, 0.22, 0.085), "s": [0.2, 0.1, 0.02], "rot": r, "col": BLK, "rough": 0.4})              # the little display
    ex(group, {"shape": "cyl", "pos": at(0.11, 0.55, 0), "s": [0.06, 0.4, 0.06], "rot": r, "col": BLK, "rough": 0.6})   # the antenna
    led = [255, 50, 36] if lit else [60, 14, 12]
    e = {"pos": at(-0.1, 0.3, 0.09), "s": [0.04, 0.04, 0.01], "rot": r, "col": led}
    if lit:
        e.update({"emissive": [255, 50, 36], "ei": 1.4})
    ex(group, e)
    if lit:
        ex(group, {"pos": at(0, 0.22, 0.097), "s": [0.17, 0.07, 0.004], "rot": r, "col": [120, 160, 90], "emissive": [120, 170, 90], "ei": 0.5})
WYAW = math.atan2(-38.6 - WT[0], 13.0 - WT[2])     # (its face turned to my pillow)
walkie(W_OFF, WT, [WYAW, 0.0], False)
walkie(W_ON, WT, [WYAW, 0.0], True)
walkie(H_ON, HW, [math.atan2(HANDCAM[0] - HW[0], HANDCAM[2] - HW[2]), 0.08], True)
ALL = set(range(len(extras)))
def only(*groups):
    keep = set().union(*[set(g) for g in groups]) if groups else set()
    return sorted(ALL - keep)

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
        fr.setdefault("hideIdx", only())
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}

# 1. (hook) Lily's room, the light on: the tea party and her bed
def s_hook(i, k):
    cam = add(lerp([13.8, U + EYE, 21.5], [16.5, U + EYE - 0.1, 20.8], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([28.0, U + 2.4, 18.5], [33.0, U + 2.6, 22.5], ease(k)), "fov": 62}, door=1.2), None)
shot("hook", 105, s_hook)

# 2. (card) the same room in the dark, a slow push to her bed
def s_card(i, k):
    cam = add(lerp([13.8, U + EYE, 21.5], [18.5, U + EYE - 0.4, 21.0], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [34.0, U + 2.4, 24.0], "fov": 58}, exposure=2.6, door=1.2), None)
shot("card", 120, s_card)

# 3. "night 55: my walkie-talkie crackled." in bed: the walkie by my pillow, its red light comes on
def s_on(i, k):
    cam = add([-38.6, U + 5.3, 13.0], hand(i, 0.2))
    on = i >= 14 and not (20 <= i < 24)          # (a flicker as it crackles)
    return (dict(DARK, shot="jled" if on else "jdark", cam={"pos": cam, "look": [WT[0], WT[1] + 0.1, WT[2]], "fov": 38}, exposure=2.8, lamps=0,
                 door=0.0, hideIdx=only(W_ON if on else W_OFF)), None)
shot("door", 72, s_on)

# 4. ""is she asleep?"" Lily's room from her door: him standing at the foot of her bed, looking down at her
STAND = [36.4, U, 19.6]
def s_stand(i, k):
    cam = add(lerp([14.6, U + 5.4, 21.0], [15.4, U + 5.3, 20.9], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [33.5, U + 5.0, 21.5], "fov": 44}, exposure=2.6, door=1.2, glow=1.6),
            him(STAND, facing(STAND, [35.0, U, 25.0]), "Stare", t=2.0 + stop(i), Duck=0.2, Look=[0.0, -0.45]))
shot("prints", 33, s_stand)

# 5. "night 56: "which bed is hers?"" him bent over the foot of her bed... his head comes round to me
BEDFOOT = [35.2, U, 20.6]
def s_bent(i, k):
    cam = add(lerp([16.0, U + 5.3, 20.8], [18.4, U + 5.1, 20.9], ease(k)), hand(i, 0.25))
    turn = ease((stop(i) * 30 - 46) / 24)
    cr = him(BEDFOOT, facing(BEDFOOT, [35.2, U, 26.0]), "Stare", t=2.0 + stop(i), Duck=0.85 - 0.25 * turn,
             Look=[SIGN * 1.25 * turn, -0.45 + 0.45 * turn])
    return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp([33.0, U + 4.0, 22.0], [34.0, U + 5.0, 21.0], ease(k)), "fov": 42 - 8 * ease(k)},
                 exposure=2.6, door=1.2, glow=1.4 + 1.4 * turn), cr)
shot("photo", 90, s_bent)

# 6. "so i took lily's walkie." her walkie in my hand in the upstairs hall, the dark behind it
def s_hand(i, k):
    cam = add(HANDCAM, hand(i, 0.08))
    return (dict(DARK, shot="hand", cam={"pos": cam, "look": [4.4, U + 4.4, 20.0], "fov": 56}, exposure=2.4, lamps=0, door=0.0, hideIdx=only(H_ON)), None)
shot("setup", 60, s_hand)

# 7. "tonight mine crackled again." the walkie by my pillow, the red light comes on, closer
def s_again(i, k):
    cam = add(lerp([-38.3, U + 5.0, 13.7], [-38.0, U + 4.8, 14.1], ease(k)), hand(i, 0.2))
    on = i >= 10 and not (16 <= i < 19)
    return (dict(DARK, shot="jled" if on else "jdark", cam={"pos": cam, "look": [WT[0], WT[1] + 0.1, WT[2]], "fov": 30}, exposure=2.8, lamps=0,
                 door=0.0, hideIdx=only(W_ON if on else W_OFF)), None)
shot("open", 60, s_again)

# 8. ""i can see you."" the walkie lowered: the empty upstairs hall, a slow step forward
def s_where(i, k):
    cam = add(lerp([4.4, U + 5.4, 25.0], [4.9, U + 5.4, 21.6], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [5.8, U + 4.4, 2.0], "fov": 56}, exposure=2.6, lamps=0, door=0.0,
                 flash=fl(cam, [6.0, U + 2.5, 8.0], 4.0, 0.4)), None)
shot("stood", 60, s_where)

# 9. ""turn around."" turn round: he's right behind me, the mask tilted... and he comes on 22.15 s (frame 64)
CAM9 = [5.2, U + 5.4, 19.0]
BEHIND = [5.0, U, 24.4]
def s_behind(i, k):
    cam = add(CAM9, hand(i, 0.3 if i < 64 else 1.0))
    t = ease((i - 12) / 26)
    y0, y1 = facing(cam, [5.8, U, 2.0]), facing(cam, BEHIND)
    yaw = y0 + wrap(y1 - y0) * t
    ly = (U + 4.6) + ((U + 8.3) - (U + 4.6)) * ease((i - 26) / 18)
    look = [cam[0] - math.sin(yaw) * 6.0, ly, cam[2] - math.cos(yaw) * 6.0]
    torch = fl(cam, [look[0], look[1] - 0.6, look[2]], 6.0, 0.4)
    if i < 64:
        return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 64}, exposure=2.6, lamps=0, door=0.0, flash=torch,
                     glow=2.2 if t > 0.5 else 0.4),
                him(BEHIND, facing(BEHIND, cam), "Stare", t=3.0 + stop(i), Duck=0.2, Look=[0.0, -0.3], Scream=0.15 * ease((i - 54) / 10)))
    w = ease((i - 64) / 4)
    near = [cam[0] + 0.1, U, cam[2] + 4.6]
    p = lerp(BEHIND, near, w)
    shake = [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0]
    return (dict(DARK, shot="hall", cam={"pos": add(cam, shake), "look": lerp(look, [p[0], U + 8.8, p[2]], w), "fov": 64 + 10 * w}, exposure=2.6,
                 lamps=0, door=0.0, glow=6.0, flash=fl(cam, [p[0], U + 7.5, p[2]], 12.0, 0.45)),
            him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Duck=1.0 * w, Look=[0.0, -0.45]))
shot("knew", 75, s_behind)

# 10. RUN: down the hall, looking back: he comes after me on all fours
def s_run(i, k):
    cam = [5.6 + 0.25 * math.sin(i * 1.7), U + 5.0 + 0.2 * math.sin(i * 2.3), 13.0 - 6.0 * k]
    hp = lerp([5.2, U, 23.0], [5.6, U, 15.5], k)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [hp[0], U + 2.8, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)}, door=0.0,
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), U + 3.2, hp[2]], 16.0, 0.36), ambient=0.01, exposure=2.0, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
