# Reel 58 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #11" (31 Oct; #7, mom's texts, 115K: everyday things with a quoted twist
# win). #2's exact format, look, music and slot lengths; a new everyday hook: Lily's baby monitor (mom works nights, #9, so I
# keep it by my pillow). It turns on by itself; someone hums to her; "shh. go back to sleep." So Lily sleeps in my room now.
# Tonight it turned on again, and it was showing my room. He wears the porcelain mask, as in the game; the monitor's views go
# through comp_cantplay's camera overlay (edit.py: fr.cam, "LILY'S ROOM").
#   hook (105)  Lily's room, the light on, cosy
#   card (120)  the same room in the dark, a slow push to her bed
#   72  "night 42: lily's baby monitor turned on."  in bed: the monitor by my pillow lights up
#   33  "night 43: someone was humming to her."      the monitor's view: him standing in her room by the bed
#   90  "night 44: "shh. go back to sleep.""         the monitor's view: him bent over her bed... his head turns to the lens
#   60  "so lily sleeps in my room now."             my room: her blanket, her pillow and her bear on the floor by my bed
#   60  "tonight it turned on again."                the monitor by my pillow, lit
#   60  "it was showing my room."                    the monitor's view: my bed, Lily asleep on the floor... him over her
#   75  ""shh. go back to sleep.""                   in bed, turn from the monitor: he's crouched right beside my bed (22.15 s)
#   30  "RUN."                                       down the hall, him after me on all fours
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

COLD, MOON, PINK, WARM, SCREEN = "#3d4f7a", "#6f86c4", "#ff9fc4", "#ffd9a0", "#bcd8c8"
NOCANDY = ["CandyWrap", "CandyBody"]
# --- Lily's room (reel 51): x 12..40, z 8.5..29.3; her door in the x = 12 wall at z 20 (hinged at z 17.55); her bed x 32..38.5,
# z 22.2..29.1 (headboard at z 29.1); the tea table at (24, 15.2); the dresser with the music box at (18.9, 28.1)
LILYDOOR = {"near": [12.0, U + 4.7, 20.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [12.0, 0, 17.55], "axis": "y"}
ROOM = [{"p": [13.6, U + 2.2, 27.5], "col": PINK, "b": 1.6, "r": 16, "decay": 1.3},          # her night light
        {"p": [26.0, U + 8.0, 31.5], "col": MOON, "b": 3.4, "r": 24, "decay": 1.1},           # the window
        {"p": [30.0, U + 8.0, 12.0], "col": COLD, "b": 1.2, "r": 16}]
LHALL = [{"p": [6, U + 8, 18], "col": COLD, "b": 1.6, "r": 16}]
LCAM = [17.6, U + 6.6, 27.6]                 # the baby monitor's camera, up on her dresser shelf, looking across at her bed
LLOOK = [32.6, U + 2.6, 20.0]
# --- Jamie's room (my room; reel 56): x -40..-8, z 10..30; the bed x -39.15..-31.35, z 13.3..18.3 (pillows at x -38.1,
# mattress top ~U + 3.8); the door in the x = -8 wall at z 24 (hinged at z 21.57)
JDOOR = {"near": [-8.0, U + 4.7, 24.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, 21.57], "axis": "y"}
MOONLIT = [{"p": [-24, U + 8.5, 28.6], "col": MOON, "b": 3.4, "r": 24, "decay": 1.0}, {"p": [-38.5, U + 8, 12], "col": MOON, "b": 2.2, "r": 18},
           {"p": [-14, U + 8, 14], "col": COLD, "b": 1.2, "r": 16}]
MON = [-35.9, U + 3.8, 13.9]                 # the monitor's parent unit, propped up on my bed by the pillow
JCAM = [float(v) for v in os.environ.get("JCAM", "-22.0,23.8,12.6").split(",")]   # (the camera, moved: up on my room's door-side wall, looking across my bed)
JLOOK = [-33.4, U + 3.0, 21.6]
LILYBED = [-34.4, U, 20.6]                   # her blanket on my floor, beside my bed
def glowAt(p, b=1.4, r=5.0): return {"p": [p[0], p[1] + 0.5, p[2]], "col": SCREEN, "b": b, "r": r, "decay": 1.6}
# --- the upstairs hall (reel 56's RUN)
HATCH = {"near": [6.0, 28.0, 11.0], "r": 4.5, "names": ["HatchPanel"], "hinge": [6.0, 28.15, 8.05], "axis": "x"}
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [4, U + 8, 4], "col": COLD, "b": 1.2, "r": 16}]
SHOTS = {
    "lit": {"center": [26, U + 5, 19], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR,
            "lights": [{"p": [26, U + 11.0, 19], "col": WARM, "b": 4.2, "r": 32, "decay": 1.0}] + ROOM},
    "room": {"center": [26, U + 5, 19], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR, "hide": ["Bulb", "Globe", "Base", "Finial"],
             "lights": ROOM + LHALL},
    "jdark": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT, "door": JDOOR},
    "jmon": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + [glowAt(MON, 0.45, 3.5)], "door": JDOOR},
    "jlily": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": JDOOR,
              "lights": MOONLIT + [{"p": [-30.0, U + 7.0, 22.5], "col": MOON, "b": 1.8, "r": 12, "decay": 1.2}]},
    "hall": {"center": [4, U + 6, 16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "lights": HALL},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 0}

# --- props (film2 extras): the monitor's parent unit (dark / lit), Lily's bed on my floor (blanket over her, pillow, bear)
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
MON_OFF, MON_ON, LILY = [], [], []
def monitor(group, p, lit, figure=False):
    # a white plastic baby monitor (~0.62 x 0.46 studs) on a little foot, its screen turned to my pillow; lit: a dim
    # grey-green night-vision picture of a bed (and, if asked, a dark figure standing over it), the green power light and the
    # sound lights
    yaw = math.atan2(-37.9 - p[0], 16.4 - p[2])      # (its face, local +z, turned toward the pillow)
    fx, fz = math.sin(yaw), math.cos(yaw)            # (the face's normal)
    rx, rz = math.cos(yaw), -math.sin(yaw)           # (its own right, along the screen)
    def at(dx, dy, h): return [p[0] + rx * dx + fx * h, p[1] + dy, p[2] + rz * dx + fz * h]
    rot = [0.0, yaw, 0.0]
    ex(group, {"pos": [p[0], p[1] + 0.04, p[2]], "s": [0.42, 0.08, 0.26], "rot": rot, "col": [214, 214, 206], "rough": 0.5})
    ex(group, {"pos": at(0, 0.32, 0), "s": [0.62, 0.48, 0.13], "rot": rot, "col": [224, 224, 216], "rough": 0.45})
    ex(group, {"shape": "cyl", "pos": at(0.24, 0.66, -0.02), "s": [0.06, 0.26, 0.06], "rot": rot, "col": [210, 210, 202], "rough": 0.5})
    if lit:
        ex(group, {"pos": at(0, 0.34, 0.068), "s": [0.5, 0.34, 0.006], "rot": rot, "col": [70, 92, 82], "emissive": [96, 128, 112], "ei": 0.55, "rough": 0.2})
        ex(group, {"pos": at(0.04, 0.27, 0.073), "s": [0.3, 0.07, 0.004], "rot": rot, "col": [36, 46, 42], "emissive": [30, 40, 36], "ei": 0.3})
        if figure:
            ex(group, {"pos": at(-0.02, 0.37, 0.074), "s": [0.06, 0.15, 0.004], "rot": rot, "col": [8, 10, 9]})
            ex(group, {"pos": at(-0.02, 0.465, 0.077), "s": [0.045, 0.055, 0.003], "rot": rot, "col": [235, 240, 236], "emissive": [235, 240, 236], "ei": 0.9})
        ex(group, {"pos": at(-0.22, 0.13, 0.068), "s": [0.03, 0.03, 0.006], "rot": rot, "col": [60, 255, 120], "emissive": [60, 255, 120], "ei": 1.2})
        for j, c in enumerate([[60, 255, 120], [60, 255, 120], [255, 170, 40]]):
            ex(group, {"pos": at(0.1 + 0.06 * j, 0.13, 0.068), "s": [0.04, 0.02, 0.006], "rot": rot, "col": c, "emissive": c, "ei": 1.0})
    else:
        ex(group, {"pos": at(0, 0.34, 0.068), "s": [0.5, 0.34, 0.006], "rot": rot, "col": [10, 10, 12], "rough": 0.15})
monitor(MON_OFF, MON, False)
MON_ON1 = []
monitor(MON_ON1, MON, True, False)
monitor(MON_ON, MON, True, True)
# Lily asleep on my floor: her blanket (pink) over her, her pillow, her bear sitting at her feet
PINKC, BEAR = [196, 120, 152], [128, 86, 52]
ex(LILY, {"pos": [LILYBED[0], U + 0.12, LILYBED[2]], "s": [4.6, 0.24, 2.3], "col": PINKC, "rough": 0.9})
ex(LILY, {"shape": "ball", "pos": [LILYBED[0] + 0.2, U + 0.32, LILYBED[2] - 0.05], "s": [3.2, 0.8, 1.35], "col": PINKC, "rough": 0.9})
ex(LILY, {"pos": [LILYBED[0] - 2.6, U + 0.3, LILYBED[2]], "s": [0.9, 0.36, 1.5], "col": [226, 226, 232], "rough": 0.8})
ex(LILY, {"shape": "ball", "pos": [LILYBED[0] - 2.35, U + 0.55, LILYBED[2] - 0.1], "s": [0.62, 0.62, 0.62], "col": [150, 104, 70], "rough": 0.9})
BP = [LILYBED[0] + 2.75, U, LILYBED[2] + 0.6]
ex(LILY, {"shape": "ball", "pos": [BP[0], U + 0.32, BP[2]], "s": [0.5, 0.62, 0.44], "col": BEAR, "rough": 0.95})
ex(LILY, {"shape": "ball", "pos": [BP[0], U + 0.78, BP[2]], "s": [0.42, 0.4, 0.4], "col": BEAR, "rough": 0.95})
for dx in (-0.15, 0.15):
    ex(LILY, {"shape": "ball", "pos": [BP[0] + dx, U + 0.97, BP[2]], "s": [0.14, 0.14, 0.1], "col": BEAR, "rough": 0.95})
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
def moncam(camp, look, shotname, fov, extra=None, ir=4.0):
    # the baby monitor's camera: perfectly still, a wide lens, its own infrared light (the comp makes it grey night vision)
    beam = {"i": ir, "pos": [camp[0], camp[1] - 0.3, camp[2]], "target": look, "angle": 1.05}
    fr = dict(DARK, shot=shotname, cam={"pos": camp, "look": look, "fov": fov}, exposure=2.4, lamps=0, flash=beam)
    if extra: fr.update(extra)
    return fr

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

# 3. "night 42: lily's baby monitor turned on." in my bed: the monitor by my pillow lights up in the dark
def s_on(i, k):
    cam = add([-38.3, U + 5.2, 17.4], hand(i, 0.2))
    on = i >= 14
    return (dict(DARK, shot="jmon" if on else "jdark", cam={"pos": cam, "look": [MON[0], MON[1] + 0.3, MON[2]], "fov": 50}, exposure=2.8, lamps=0,
                 door=0.0, hideIdx=only(MON_ON1 if on else MON_OFF)), None)
shot("door", 72, s_on)

# 4. "night 43: someone was humming to her." the monitor's view: him standing in her room, by the foot of her bed
STAND = [36.4, U, 17.4]
def s_hum(i, k):
    return (moncam(LCAM, LLOOK, "room", 96, {"glow": 1.6, "door": 0.0}),
            him(STAND, facing(STAND, [35.0, U, 25.0]), "Stare", t=2.0 + stop(i), Duck=0.2, Look=[0.0, -0.45]))
shot("prints", 33, s_hum)

# 5. "night 44: "shh. go back to sleep."" the monitor's view: him bent over the foot of her bed... his head comes round to the lens
BEDFOOT = [35.2, U, 20.6]
def s_shh(i, k):
    turn = ease((stop(i) * 30 - 46) / 24)
    cr = him(BEDFOOT, facing(BEDFOOT, [35.2, U, 26.0]), "Stare", t=2.0 + stop(i), Duck=0.85 - 0.25 * turn,
             Look=[SIGN * 1.25 * turn, -0.45 + 0.45 * turn])
    return (moncam(LCAM, lerp(LLOOK, [34.0, U + 4.0, 21.0], ease(k)), "room", 96 - 14 * ease(k), {"glow": 1.4 + 1.2 * turn, "door": 0.0}), cr)
shot("photo", 90, s_shh)

# 6. "so lily sleeps in my room now." my room from the door: her blanket over her on my floor, her pillow, her bear
def s_lily(i, k):
    cam = add(lerp([-21.0, U + 5.4, 25.0], [-22.6, U + 5.1, 24.2], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="jlily", cam={"pos": cam, "look": [-33.6, U + 1.2, 20.4], "fov": 50}, exposure=3.4, lamps=0, door=1.7,
                 hideIdx=only(LILY, MON_OFF)), None)
shot("setup", 60, s_lily)

# 7. "tonight it turned on again." the monitor by my pillow lights up (on its screen: a bed, and a dark shape over it)
def s_again(i, k):
    cam = add(lerp([-38.0, U + 5.0, 16.9], [-37.7, U + 4.9, 16.4], ease(k)), hand(i, 0.2))
    on = i >= 10
    return (dict(DARK, shot="jmon" if on else "jdark", cam={"pos": cam, "look": [MON[0], MON[1] + 0.34, MON[2]], "fov": 34}, exposure=2.8, lamps=0,
                 door=0.0, hideIdx=only(LILY, MON_ON if on else MON_OFF)), None)
shot("open", 60, s_again)

# 8. "it was showing my room." the monitor's view, now in my room's corner: my bed, Lily asleep on the floor... him bent over her
OVER = [-33.8, U, 23.9]
def s_mine(i, k):
    return (moncam(JCAM, JLOOK, "jlily", 76, {"glow": 1.6, "door": 0.0, "hideIdx": only(LILY, MON_ON)}),
            him(OVER, facing(OVER, [-33.8, U, 18.0]), "Stare", t=3.0 + stop(i), Duck=0.85, Look=[0.0, -0.6]))
shot("stood", 60, s_mine)

# 9. ""shh. go back to sleep."" in bed, the monitor lit by my pillow... turn to the side of the bed: he's crouched right there,
# his face level with mine; he comes at me on 22.15 s (frame 64)
BEDEYE = [-37.9, U + 4.7, 16.2]
SIDE = [-35.2, U, 24.8]
def s_knew(i, k):
    cam = add(BEDEYE, hand(i, 0.3))
    mon = [MON[0], MON[1] + 0.34, MON[2]]
    t = ease((i - 20) / 22)
    y0, y1 = facing(cam, mon), facing(cam, SIDE)
    yaw = y0 + wrap(y1 - y0) * t
    ly = mon[1] + ((U + 7.4) - mon[1]) * ease((i - 26) / 22)
    dist = 3.0 + 5.6 * t
    look = [cam[0] - math.sin(yaw) * dist, ly, cam[2] - math.cos(yaw) * dist]
    hide = only(LILY, MON_ON)
    if i < 64:
        fr = dict(DARK, shot="jmon", cam={"pos": cam, "look": look, "fov": 52}, exposure=2.6, lamps=0, door=0.0, glow=2.4 if t > 0.5 else 0.8,
                  flash=fl(cam, look, 6.0 * t, 0.4), hideIdx=hide)
        return (fr, him(SIDE, facing(SIDE, cam), "Stare", t=3.0 + stop(i), Duck=1.0, Look=[0.0, -0.2], Scream=0.2 * ease((i - 54) / 10)))
    w = ease((i - 64) / 4)
    near = [cam[0] + 0.9, U, cam[2] + 3.8]
    p = lerp(SIDE, near, w)
    camw = add(cam, [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    fr = dict(DARK, shot="jmon", cam={"pos": camw, "look": lerp(look, [p[0], U + 8.8, p[2]], w), "fov": 52 + 10 * w}, exposure=2.6, lamps=0,
              door=0.0, glow=7.0, flash=fl(camw, [p[0], U + 6.5, p[2]], 14.0, 0.5), hideIdx=hide)
    return (fr, him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Look=[0.0, -0.3]))
shot("knew", 75, s_knew)

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
