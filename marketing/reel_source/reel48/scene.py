# Reel 48 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #3" (the new run, after #2 = reel 47): #2's exact format, look,
# music and slot lengths. The chapter after the camera: he has learned our voices (the game's mimic). Mom called me
# downstairs, but mom was asleep; it called Lily in my voice and her bed was empty, her bear on the stairs; tonight it
# was mom's voice again, from the kitchen: "i made you something." ... mom doesn't cook at 3 am: him at the stove.
#   hook (105)  the kitchen, lamps on, cosy
#   card (120)  the same kitchen in the dark, a slow push to the stove
#   72  "night 13: mom called me downstairs."      the top of the stairs, the flashlight down into the black
#   33  "mom was asleep."                          the master bedroom from the door: mom asleep in bed
#   90  "night 14: it called lily. in my voice."   her door open from the hall, the night light, her bed empty
#   60  "her bear was on the stairs."              the flashlight down the stairs: her teddy on a step
#   60  "tonight it was mom's voice again."        the dark hall, the kitchen arch at the end glowing
#   60  "\"i made you something.\""                close: a pot on the blue flame, the oven light on
#   75  "mom doesn't cook at 3 am."                him at the stove, his back to you... his head turns right round...
#                                                  he comes at you (22.15 s)
#   30  "RUN."                                     back out of the arch into the hall, him after you on all fours
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau), shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.5
TAU = math.tau
S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")

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

COLD, MOON, WARM, PINK, GAS = "#3d4f7a", "#6f86c4", "#ffb766", "#ff9fc4", "#5d8cff"
# --- the kitchen (ground floor): the range x -39.9..-35.9, z 21..25 against the x = -40 wall (cooktop y 4.6, its oven
# door facing +x at x -36.5, the hood at y 9.8); the island x -28..-22, z 12.5..17.4; the fridge at x -29.6..-27.1,
# its door at z 25.95; the dining table x -17..-9, z 12..23.5; the arch to the hall in the x = -8 wall at z 26
OVEN = [{"p": [-35.0, 2.8, 23.0], "col": WARM, "b": 2.6, "r": 13, "decay": 1.3}]
FLAME = [{"p": [-38.4, 5.4, 24.1], "col": GAS, "b": 1.4, "r": 6, "decay": 1.6}]
KITCHEN = [{"p": [-38, 9, 14], "col": COLD, "b": 1.2, "r": 16}, {"p": [-24, 9, 29], "col": COLD, "b": 0.9, "r": 14},
           {"p": [-32, 9, 31], "col": MOON, "b": 1.8, "r": 18, "decay": 1.2}, {"p": [-16, 9, 18], "col": MOON, "b": 1.4, "r": 18}]
GHALL = [{"p": [2, G + 8, 26], "col": COLD, "b": 1.4, "r": 18}, {"p": [-2, G + 8, 12], "col": MOON, "b": 1.0, "r": 18}]
# --- the stairs (x ~-5, from the front hall at z -5.3 up to the landing at z 17); the master bedroom (reel 45); Lily's
# room (x 12..40, z 10..31, upstairs; her door in the x = 12 wall at z 20, hinged at z 17.55; her bed x 32..38.5,
# z 21.5..28.5, pillows at +z)
def sy(z): return max(G, min(U, 2.05 + 0.625 * (z + 5.3) - 1.0))
STAIRS = [{"p": [-5, U + 6, 22], "col": "#2c3d6e", "b": 1.3, "r": 26}, {"p": [-5, 8, -2], "col": COLD, "b": 0.8, "r": 18}]
MDOOR = {"near": [-8.0, U + 4.7, -10.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, -12.43], "axis": "y"}
MROOM = [{"p": [-32, U + 8.5, -27.6], "col": MOON, "b": 3.4, "r": 24, "decay": 1.0}, {"p": [-32, U + 9.0, -11.0], "col": MOON, "b": 4.2, "r": 14, "decay": 1.0},
         {"p": [-4.5, U + 7, -10], "col": COLD, "b": 2.0, "r": 14}]
LILYDOOR = {"near": [12.0, U + 4.7, 20.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [12.0, 0, 17.55], "axis": "y"}
LROOM = [{"p": [13.6, U + 2.2, 27.5], "col": PINK, "b": 1.6, "r": 16, "decay": 1.3}, {"p": [26.0, U + 8.0, 31.5], "col": MOON, "b": 3.4, "r": 24, "decay": 1.1},
         {"p": [30.0, U + 8.0, 12.0], "col": COLD, "b": 1.2, "r": 16}, {"p": [6, U + 8, 20], "col": COLD, "b": 1.0, "r": 14}]
SHOTS = {
    "lit": {"center": [-24, G + 5, 20], "radius": 32, "lampRadius": 32, "maxLamps": 8},
    "kitchen": {"center": [-24, G + 5, 20], "radius": 32, "lampRadius": 0, "maxLamps": 0, "lights": KITCHEN},
    "cooking": {"center": [-24, G + 5, 22], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": KITCHEN + OVEN + FLAME + GHALL},
    "stairs": {"center": [-5, G + 8, 6], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": STAIRS},
    "mom": {"center": [-24, U + 5, -15], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": MDOOR, "lights": MROOM},
    "lily": {"center": [20, U + 5, 20], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR, "lights": LROOM},
}
NOCANDY = ["CandyWrap", "CandyBody"]     # (the Halloween hunt's candies: not in this story)
for _s in SHOTS.values(): _s["hide"] = NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}

# --- props (film2 extras): mom asleep, Lily's blanket on the floor, her bear on the stairs, the pot and the flame and
# the oven's light
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
MOM, BLANKET, BEAR, COOK = [], [], [], []
ex(MOM, {"pos": [-33.4, U + 3.75, -12.7], "s": [5.0, 0.8, 2.2], "shape": "ball", "col": [66, 80, 116], "rough": 0.95})      # under the duvet
ex(MOM, {"pos": [-36.4, U + 3.85, -12.9], "s": [1.6, 0.75, 2.0], "shape": "ball", "col": [66, 80, 116], "rough": 0.95})      # her shoulder
ex(MOM, {"pos": [-37.75, U + 4.35, -12.6], "s": [1.05, 1.0, 1.15], "shape": "ball", "col": [92, 62, 44], "rough": 0.7})    # her hair
ex(BLANKET, {"pos": [30.6, U + 0.35, 24.2], "s": [2.6, 0.5, 3.4], "rot": [0.1, 0.3, 0.15], "shape": "ball", "col": [235, 160, 195], "rough": 0.95})
ex(BLANKET, {"pos": [31.6, U + 1.6, 23.6], "s": [0.3, 2.4, 2.8], "rot": [0, 0.2, -0.2], "col": [230, 155, 190], "rough": 0.95})
BZ = 12.0
BY = sy(BZ)
BROWN = [150, 104, 66]
ex(BEAR, {"pos": [-5.0, BY + 0.45, BZ], "s": [0.8, 0.9, 0.7], "shape": "ball", "col": BROWN, "rough": 0.95})
ex(BEAR, {"pos": [-5.0, BY + 1.1, BZ + 0.05], "s": [0.66, 0.62, 0.6], "shape": "ball", "col": BROWN, "rough": 0.95})
for sx in (-1, 1):
    ex(BEAR, {"pos": [-5.0 + sx * 0.26, BY + 1.38, BZ], "s": [0.22, 0.22, 0.12], "shape": "ball", "col": BROWN, "rough": 0.95})   # ears
    ex(BEAR, {"pos": [-5.0 + sx * 0.38, BY + 0.2, BZ + 0.35], "s": [0.26, 0.26, 0.42], "shape": "ball", "col": BROWN, "rough": 0.95})   # feet
    ex(BEAR, {"pos": [-5.0 + sx * 0.12, BY + 1.16, BZ + 0.34], "s": [0.07, 0.07, 0.04], "shape": "ball", "col": [10, 10, 10], "rough": 0.2})  # eyes
ex(BEAR, {"pos": [-5.0, BY + 1.0, BZ + 0.33], "s": [0.26, 0.2, 0.16], "shape": "ball", "col": [200, 170, 130], "rough": 0.9})   # snout
POT = [-38.45, 4.62, 24.1]
ex(COOK, {"pos": [POT[0], POT[1] + 0.05, POT[2]], "s": [1.1, 0.04, 1.1], "shape": "cyl", "col": [70, 120, 255], "emissive": [60, 110, 255], "ei": 2.2, "rough": 0.3})
ex(COOK, {"pos": [POT[0], POT[1] + 0.5, POT[2]], "s": [1.25, 0.8, 1.25], "shape": "cyl", "col": [60, 62, 68], "rough": 0.35})
ex(COOK, {"pos": [POT[0], POT[1] + 0.93, POT[2]], "s": [1.3, 0.06, 1.3], "shape": "cyl", "col": [80, 82, 88], "rough": 0.3})
ex(COOK, {"pos": [POT[0], POT[1] + 1.02, POT[2]], "s": [0.2, 0.12, 0.2], "shape": "cyl", "col": [20, 20, 22], "rough": 0.4})
ex(COOK, {"pos": [-36.43, 2.5, 23.0], "s": [0.02, 1.0, 2.7], "col": [255, 170, 90], "emissive": [255, 160, 80], "ei": 1.6, "rough": 0.3})
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
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}

# 1. (hook) the kitchen, lamps on: cosy
def s_hook(i, k):
    cam = add(lerp([-11.0, G + 6.2, 24.8], [-13.5, G + 6.0, 24.6], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([-34.0, G + 3.8, 20.0], [-34.5, G + 3.6, 20.6], ease(k)), "fov": 62}, hideIdx=only()), None)
shot("hook", 105, s_hook)

# 2. (card) the same kitchen in the dark, a slow push to the stove
def s_card(i, k):
    cam = add(lerp([-11.5, G + 6.2, 24.9], [-16.5, G + 5.8, 24.7], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="kitchen", cam={"pos": cam, "look": [-35.5, G + 3.4, 22.0], "fov": 60}, exposure=3.6, lamps=0, hideIdx=only()), None)
shot("card", 120, s_card)

# 3. "night 13: mom called me downstairs." the top of the stairs, the flashlight down into the black
def s_down(i, k):
    cam = add(lerp([-5.2, U + 5.5, 20.4], [-5.1, U + 5.4, 19.6], ease(k)), hand(i, 0.5))
    look = lerp([-5.0, G + 4.0, -4.0], [-5.0, G + 3.0, -6.0], ease(k))
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": look, "fov": 54}, exposure=2.4, lamps=0, hideIdx=only(),
                 flash=fl(cam, lerp([-5.0, sy(4.0), 4.0], [-5.0, G, -4.0], ease(k)), 12.0, 0.34)), None)
shot("door", 72, s_down)

# 4. "mom was asleep." the master bedroom from the door: mom asleep, turned away
def s_mom(i, k):
    cam = add(lerp([-21.0, U + 7.0, -9.6], [-22.0, U + 6.9, -9.9], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="mom", cam={"pos": cam, "look": [-35.0, U + 3.9, -13.0], "fov": 44}, exposure=2.6, lamps=0, door=1.35, hideIdx=only(MOM)), None)
shot("prints", 33, s_mom)

# 5. "night 14: it called lily. in my voice." from the hall, through her open door: the night light, her bed empty,
# her blanket on the floor
def s_lily(i, k):
    cam = add(lerp([4.5, U + 5.4, 19.4], [10.6, U + 5.1, 19.6], ease(k)), hand(i, 0.4))
    look = lerp([30.0, U + 2.6, 23.0], [33.0, U + 2.4, 24.5], ease(k))
    return (dict(DARK, shot="lily", cam={"pos": cam, "look": look, "fov": 52}, exposure=2.6, lamps=0, door=1.25, hideIdx=only(BLANKET)), None)
shot("photo", 90, s_lily)

# 6. "her bear was on the stairs." a step down from the top, the flashlight finds it
def s_bear(i, k):
    cam = add(lerp([-5.6, U + 5.0, 18.4], [-5.3, sy(15.4) + 3.4, 15.4], ease(k)), hand(i, 0.5))
    tgt = [-5.0, BY + 0.8, BZ]
    look = lerp([-5.0, BY + 0.4, BZ - 3.0], tgt, ease(k * 1.4))
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": look, "fov": 44 - 10 * ease(k)}, exposure=2.4, lamps=0, hideIdx=only(BEAR),
                 flash=fl(cam, lerp([-5.0, BY, BZ - 4.0], tgt, ease(k * 1.6)), 9.0, 0.3)), None)
shot("setup", 60, s_bear)

# 7. "tonight it was mom's voice again." the dark hall: the kitchen arch at its end, glowing
def s_arch(i, k):
    cam = add(lerp([6.0, G + 5.5, 26.2], [3.0, G + 5.4, 26.0], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="cooking", cam={"pos": cam, "look": [-20.0, G + 3.6, 24.6], "fov": 52}, exposure=2.6, lamps=0, hideIdx=only(COOK)), None)
shot("open", 60, s_arch)

# 8. "i made you something." close: a pot on the blue flame, the oven light on
def s_pot(i, k):
    cam = add(lerp([-33.2, G + 6.6, 26.2], [-34.4, G + 6.3, 25.6], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="cooking", cam={"pos": cam, "look": lerp([-38.0, G + 3.8, 23.6], [-38.3, G + 3.9, 23.9], ease(k)), "fov": 48}, exposure=1.5,
                 lamps=0, hideIdx=only(COOK)), None)
shot("stood", 60, s_pot)

# 9. "mom doesn't cook at 3 am." him at the stove, his back to you, bent over the pot... his head turns right round
# (13 poses a second)... and he comes at you on 22.15 s (frame 64)
STOVE = [-34.2, G, 23.4]
AWAY = facing(STOVE, [-40.0, G, 23.6])
def s_knew(i, k):
    cam = add(lerp([-12.0, G + 5.4, 25.0], [-17.5, G + 5.3, 24.8], ease(k * 1.15)), hand(i, 0.4))
    if i < 64:
        turn = ease((stop(i) * 30 - 20) / 22)
        cr = him(STOVE, AWAY, "Stare", t=4.0 + stop(i), Duck=0.55 - 0.4 * turn, Look=[3.3 * turn, 0.25 * turn], Scream=0.15 * ease((i - 54) / 10))
        return (dict(DARK, shot="cooking", cam={"pos": cam, "look": [-34.5, G + 5.6, 23.4], "fov": 50}, exposure=2.4, lamps=0, glow=1.2 + 1.4 * turn,
                     hideIdx=only(COOK), flash=fl(cam, [-34.5, G + 6.0, 23.4], 5.0, 0.3)), cr)
    w = ease((i - 64) / 5)
    near = add(cam, [-4.2, 0, -0.3])
    p = lerp(STOVE, [near[0], G, near[2]], w)
    shake = [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0]
    cr = him(p, facing(p, cam), "Reach", t=4.0 + i / FPS, Scream=1.0, Look=[0.0, 0.0])
    return (dict(DARK, shot="cooking", cam={"pos": add(cam, shake), "look": lerp([-34.5, G + 5.6, 23.4], [p[0], G + 8.4, p[2]], w), "fov": 50 + 12 * w},
                 exposure=2.4, lamps=0, glow=6.0, hideIdx=only(COOK), flash=fl(cam, [p[0], G + 7.5, p[2]], 9.0, 0.4)), cr)
shot("knew", 75, s_knew)

# 10. RUN: back out of the arch into the hall, looking back: he comes after you on all fours
def s_run(i, k):
    cam = [-6.0 + 9.0 * k + 0.25 * math.sin(i * 1.7), G + 5.0 + 0.2 * math.sin(i * 2.3), 26.0]
    hp = lerp([-25.0, G, 24.8], [-14.0, G, 25.6], k)
    return (dict(DARK, shot="cooking", cam={"pos": cam, "look": [hp[0], G + 2.8, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), G + 3.2, hp[2]], 16.0, 0.36), ambient=0.01, exposure=2.0, glow=6, hideIdx=only(COOK)),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
