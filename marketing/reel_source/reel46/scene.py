# Reel 46 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #1": the series starts again from part one (the owner: "Start
# from part one again"). #2's exact format, look, music and slot lengths, and #2's own story (314K views): the attic
# mystery night by night, told again from the start with the v114 creature (the porcelain mask) and all-new shots.
#   hook (105)  the upstairs hall, lamps on, cosy: the attic hatch shut in the ceiling
#   card (120)  the same hall in the dark, a slow push under the hatch
#   72  "night 1: footsteps in the ceiling."        looking straight up, the flashlight following them across
#   33  "night 4: the food went missing."            the fridge open: the dish licked clean
#   90  "night 9: we found the hatch open."          the hatch down, the ladder out, the black hole above
#   60  "someone's been sleeping up here."           in the attic: his nest in his lantern's light
#   60  "photos. of us."                             his wall of the family's photos
#   60  "he's been counting the days."               the tally marks
#   75  "and tonight he's coming down."              under the open hatch, looking up... his mask comes down out of the
#                                                    dark, upside down... and drops at you (22.15 s)
#   30  "RUN."                                       back down the hall, him crawling after you from under the hatch
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
def add(a, b): return [a[j] + b[j] for j in range(3)]
def him(pos, yaw, gait="Stare", phase=0.0, t=0.0, **opts):
    return {"pos": {"x": pos[0], "y": pos[1], "z": pos[2]}, "yaw": yaw, "gait": gait, "phase": phase, "t": t, "seed": 4, "opts": opts}

COLD, MOON, WARM = "#3d4f7a", "#6f86c4", "#ffb766"
FRIDGE_LIGHT = "#dfeaff"
# the hatch: the hole is x 4..8, z 8..14 in the hall ceiling (y 28.15); the panel hinges down at z = 8
HATCH = {"near": [6.0, 28.0, 11.0], "r": 4.5, "names": ["HatchPanel"], "hinge": [6.0, 28.15, 8.05], "axis": "x"}
NO_CORD = ["Cord", "CordHandle"]
OPEN = math.pi / 2
# the fridge's left leaf, hinged at its outer edge
FRIDGE = {"near": [-28.36, 7.8, 25.95], "r": 1.3, "names": ["FridgeDoor", "FridgeHandle"], "hinge": [-29.58, 0, 25.95], "axis": "y"}
FX = -28.36
LANTERN = {"p": [-19.0, 31.2, -3.4], "col": WARM, "b": 3.6, "r": 26, "decay": 1.2}
ATTIC = [LANTERN, {"p": [6.0, 27.0, 11.0], "col": COLD, "b": 1.6, "r": 14}, {"p": [30.0, 36.0, 0.0], "col": "#2c3d6e", "b": 0.8, "r": 40, "decay": 1.0}]
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [4, U + 8, 4], "col": COLD, "b": 1.2, "r": 16}]
KITCHEN = [{"p": [-38, 9, 14], "col": COLD, "b": 1.4, "r": 16}, {"p": [-24, 9, 29], "col": COLD, "b": 1.0, "r": 14},
           {"p": [-32, 9, 31], "col": MOON, "b": 2.2, "r": 18, "decay": 1.2}, {"p": [FX, 9.6, 25.0], "col": FRIDGE_LIGHT, "b": 3.2, "r": 12, "decay": 1.4}]
SHOTS = {
    "hallLit": {"center": [5, U + 6, 14], "radius": 30, "lampRadius": 30, "maxLamps": 6, "door": HATCH},
    "hall": {"center": [5, U + 6, 14], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD, "lights": HALL},
    "hallShut": {"center": [5, U + 6, 14], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "lights": HALL},
    "below": {"center": [5, U + 6, 14], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD,
              "lights": HALL + [{"p": [6, 31, 10], "col": WARM, "b": 0.7, "r": 10}]},
    "fridge": {"center": [-24, 6, 22], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": FRIDGE, "lights": KITCHEN},
    "attic": {"center": [-14, 31, 2], "radius": 40, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD, "lights": ATTIC},
}
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}

# --- props (film2 extras): the folding ladder down from the hatch; inside the fridge (the game hides its insides)
WOOD = [150, 118, 80]
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
LADDER, FRIDGEIN = [], []
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

# 1. (hook) the upstairs hall, lamps on: cosy; the hatch shut in the ceiling
def s_hook(i, k):
    cam = add(lerp([3.4, U + EYE, 25.0], [4.4, U + EYE - 0.1, 21.5], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="hallLit", cam={"pos": cam, "look": lerp([5.6, U + 6.0, 11.0], [5.8, U + 7.2, 11.0], ease(k)), "fov": 62}, door=0.0, hideIdx=only()), None)
shot("hook", 105, s_hook)

# 2. (card) the same hall in the dark, a slow push under the hatch
def s_card(i, k):
    cam = add(lerp([3.0, U + EYE, 25.5], [4.6, U + EYE - 0.2, 19.0], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="hallShut", cam={"pos": cam, "look": lerp([5.6, U + 6.4, 11.0], [6.0, U + 9.0, 11.0], ease(k)), "fov": 62}, exposure=2.4, door=0.0,
                 hideIdx=only()), None)
shot("card", 120, s_card)

# 3. "night 1: footsteps in the ceiling." looking straight up, the flashlight following them across
def s_steps(i, k):
    cam = add([5.4, U + EYE, 15.6], hand(i, 0.4))
    tgt = lerp([2.0, 28.0, 21.0], [7.0, 28.0, 9.0], ease(k))
    look = lerp([4.0, 28.0, 18.0], [6.2, 28.0, 11.5], ease(k))
    return (dict(DARK, shot="hallShut", cam={"pos": cam, "look": look, "fov": 64}, exposure=2.3, door=0.0, hideIdx=only(), flash=fl(cam, tgt, 8.0, 0.32)), None)
shot("steps", 72, s_steps)

# 4. "night 4: the food went missing." the fridge open, the dish licked clean
def s_food(i, k):
    cam = add(lerp([-27.4, G + EYE + 0.9, 18.6], [-27.6, G + EYE + 0.9, 19.4], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="fridge", cam={"pos": cam, "look": [FX + 0.1, 7.6, 25.7], "fov": 46}, exposure=1.3, door=1.9, hideIdx=only(FRIDGEIN)), None)
shot("food", 33, s_food)

# 5. "night 9: we found the hatch open." the panel down, the ladder out, the black hole above
def s_open(i, k):
    cam = add(lerp([3.2, U + EYE, 24.0], [4.8, U + EYE - 0.2, 18.5], ease(k)), hand(i))
    look = lerp([5.4, U + 5.6, 12.0], [6.0, 27.4, 11.0], ease(k))
    tgt = lerp([5.2, U + 2.0, 14.0], [6.0, 28.6, 10.8], ease(min(1.0, k * 1.2)))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 62}, exposure=2.0, door=OPEN, hideIdx=only(LADDER), flash=fl(cam, tgt, 12.0, 0.34)), None)
shot("open", 90, s_open)

# 6. "someone's been sleeping up here." along the walkway, crouched: his nest in the lantern light
def s_nest(i, k):
    cam = add(lerp([-8.0, CROUCH, 8.8], [-12.5, CROUCH - 0.2, 6.6], ease(k)), hand(i, 0.8))
    tgt = lerp([-21.0, 29.6, 2.4], [-24.0, 29.8, 0.0], ease(k))
    return (dict(DARK, shot="attic", cam={"pos": cam, "look": [-23.0, 30.2, -0.5], "fov": 58}, exposure=2.0, door=OPEN, hideIdx=only(LADDER),
                 flash=fl(cam, tgt, 9.0, 0.36)), None)
shot("nest", 60, s_nest)

# 7. "photos. of us." his wall of the family's photos, then the portrait with the faces scratched out
def s_photos(i, k):
    a = ease(k / 0.55)
    b = ease((k - 0.55) / 0.4)
    cam = add(lerp(lerp([-23.0, CROUCH, 2.8], [-24.0, CROUCH - 0.1, 1.2], a), [-24.6, A + 2.0, -2.0], b), hand(i, 0.5))
    look = lerp(lerp([-28.3, 32.6, 2.2], [-28.3, 32.2, -0.4], a), [-27.9, 30.1, -3.3], b)
    return (dict(DARK, shot="attic", cam={"pos": cam, "look": look, "fov": 52 - 6 * b}, exposure=2.1, door=OPEN, hideIdx=only(LADDER),
                 flash=fl(cam, look, 10.0, 0.3)), None)
shot("photos", 60, s_photos)

# 8. "he's been counting the days." the tally marks, a slow push
def s_tally(i, k):
    cam = add(lerp([-22.2, CROUCH + 0.1, 5.6], [-23.6, CROUCH, 4.9], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="attic", cam={"pos": cam, "look": [-28.3, 32.2, 4.4], "fov": 54 - 6 * ease(k)}, exposure=2.1, door=OPEN, hideIdx=only(LADDER),
                 flash=fl(cam, [-28.3, 32.3, 4.5], 10.0, 0.3)), None)
shot("tally", 60, s_tally)

# 9. "and tonight he's coming down." under the open hatch, looking up into the black hole... his mask comes down out
# of the dark, upside down, slowly... and on 22.15 s (frame 64) it drops at you, jaw open (only the mask: his body is
# the dark of the attic above)
CAM9 = [5.8, U + 5.3, 17.6]
def s_down(i, k):
    cam = add(CAM9, hand(i, 0.35 if i < 64 else 1.2))
    look = lerp([6.0, 26.8, 12.0], [6.0, 26.4, 12.4], ease(i / 60))
    torch = fl(cam, [6.0, 28.6, 11.0], 9.0, 0.3)
    if i < 30:
        return (dict(DARK, shot="below", cam={"pos": cam, "look": look, "fov": 60}, exposure=2.3, door=OPEN, hideIdx=only(LADDER), flash=torch), None)
    if i < 64:
        w = ease((i - 30) / 32)
        p = lerp([6.0, 29.6, 10.6], [6.0, 26.7, 11.4], w)
        cr = him([6.0, U, 0.0], 0.0, "Stare", t=3.0 + i / FPS, Scream=0.12 * ease((i - 54) / 10))
        cr["head"] = {"pos": p, "look": [cam[0], cam[1], cam[2]], "roll": 0.55}
        cr["noSkin"] = True
        return (dict(DARK, shot="below", cam={"pos": cam, "look": look, "fov": 60}, exposure=2.3, door=OPEN, hideIdx=only(LADDER), flash=torch,
                     glow=0.8 + 1.2 * w), cr)
    w = ease((i - 64) / 4)
    p = lerp([6.0, 26.7, 11.4], [5.85, U + 5.45, 16.5], w)
    cr = him([6.0, U, 0.0], 0.0, "Reach", t=3.0 + i / FPS, Scream=1.0)
    cr["head"] = {"pos": p, "look": [cam[0], cam[1] + 0.1, cam[2]], "roll": 0.55 * (1 - w)}
    cr["noSkin"] = True
    return (dict(DARK, shot="below", cam={"pos": cam, "look": lerp(look, p, 0.7 * w), "fov": 60 + 8 * w}, exposure=2.4, door=OPEN, hideIdx=only(LADDER),
                 flash=fl(cam, p, 12.0, 0.45), glow=4.0), cr)
shot("down", 75, s_down)

# 10. RUN: back down the hall, looking back: he crawls after you from under the hatch, on all fours
def s_run(i, k):
    cam = [3.4 + 0.25 * math.sin(i * 1.7), U + 4.9 + 0.2 * math.sin(i * 2.3), 20.0 + 4.0 * k]
    p = lerp([6.0, U, 13.0], [5.0, U, 18.0], k)
    return (dict(DARK, shot="below", cam={"pos": cam, "look": [p[0], U + 2.8, p[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [p[0] + 0.6 * math.sin(i * 1.3), U + 3.2, p[2]], 16.0, 0.36), ambient=0.01, exposure=1.9, glow=6, door=OPEN, hideIdx=only(LADDER)),
            him(p, facing(p, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
