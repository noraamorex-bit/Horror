# Reel 44 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #13": the chapter after #12 ("he's not hiding anymore"), in
# #2's exact format, look, music and slot lengths. He wants a place in the family now: an extra plate at the
# table, him tucking the little sister in, him sitting at the head of the table, the car keys on his plate, and
# at the front door with the bags packed: he's right behind you. The v114 creature (the sculpted body with the
# porcelain mask: tools/creature/skin_frames.luau with tools/harness/mask_dump.luau's mask.json).
#   hook (105)  the dining table, lamps on, cosy
#   card (120)  the same table in the dark, a slow push
#   72  "night 15: five plates. there's four of us."   the flashlight finds the fifth place, at the head
#   33  "night 16: someone ate from it."               close on the plate, licked clean
#   90  "night 17: he tucked my sister in."            Lily's room: him bent over her bed
#   60  "night 18: he sat at the head of the table."   down the table: him in the chair at the end, watching
#   60  "so tonight we're leaving."                    the front hall, lamps on, the bags by the door
#   60  "the car keys were on his plate."              the flashlight on the fifth plate: the keys
#   75  "he doesn't want us to leave."                 at the front door... turn round: he's right there (22.15 s)
#   30  "RUN."                                         up the stairs, him after you on all fours
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
def him(pos, yaw, gait="Stare", phase=0.0, t=0.0, **opts):
    return {"pos": {"x": pos[0], "y": pos[1], "z": pos[2]}, "yaw": yaw, "gait": gait, "phase": phase, "t": t, "seed": 4, "opts": opts}

COLD, MOON, WARM, PINK = "#3d4f7a", "#6f86c4", "#ffb766", "#ff9ec4"
TABLE = [-15.0, G, 17.5]          # the dining table (long along z; places at x -13 / -17, z 15.4 / 19.6)
HEAD = [-15.0, G, 21.2]           # the fifth place, at its far end
SEATED = [-15.0, G, 23.25]        # his chair at the head
DOOR = [2.0, G, -29.6]            # the front door
DIN_DARK = [{"p": [-15, G + 9.5, 11], "col": MOON, "b": 4.5, "r": 26, "decay": 1.0}, {"p": [-23, G + 7, 22], "col": COLD, "b": 2.2, "r": 18},
            {"p": [-8, G + 7, 20], "col": COLD, "b": 1.6, "r": 16}]
CANDLE = [{"p": [-15, G + 4.9, 19.0], "col": "#ff9a4a", "b": 2.4, "r": 11, "decay": 1.4}]
LILY = [{"p": [13.6, U + 2.2, 27.5], "col": PINK, "b": 1.8, "r": 16, "decay": 1.3}, {"p": [26.0, U + 8.0, 31.5], "col": MOON, "b": 3.8, "r": 24, "decay": 1.1},
        {"p": [30.0, U + 8.0, 12.0], "col": COLD, "b": 1.4, "r": 16}]
HALL_DARK = [{"p": [2, G + 9, -22], "col": MOON, "b": 4.0, "r": 26, "decay": 1.0}, {"p": [-4, G + 7, -12], "col": COLD, "b": 1.8, "r": 18}]
STAIRS = [{"p": [-5, U + 6, 22], "col": "#2c3d6e", "b": 1.3, "r": 26}, {"p": [-5, 8, -2], "col": COLD, "b": 1.4, "r": 18},
          {"p": [-5, G + 7, -12], "col": COLD, "b": 1.0, "r": 16}]
BIN = [{"near": [-14.2, 27.0], "r": 1.4}]  # (the kitchen's pedal bin, right behind the head of the table)
SHOTS = {
    "dinLit": {"center": [-15, G + 5, 17], "radius": 32, "lampRadius": 30, "maxLamps": 6, "hide": BIN},
    "dinDark": {"center": [-15, G + 5, 17], "radius": 32, "lampRadius": 0, "maxLamps": 0, "lights": DIN_DARK, "hide": BIN},
    "dinner": {"center": [-15, G + 5, 17], "radius": 32, "lampRadius": 0, "maxLamps": 0, "lights": DIN_DARK + CANDLE, "hide": BIN},
    "lily": {"center": [26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": LILY},
    "hallLit": {"center": [1, G + 5, -20], "radius": 30, "lampRadius": 30, "maxLamps": 5},
    "hallDark": {"center": [1, G + 5, -20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": HALL_DARK},
    "stairs": {"center": [-5, G + 6, 4], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": STAIRS},
}
DARK = {"ambient": 0.02, "bg": 0x010102}

# --- props for the shoot (film2 extras)
MAT, PLATE, SCRAP, KEY, WOOD = [214, 196, 160], [244, 242, 236], [92, 30, 26], [196, 170, 92], [96, 64, 40]
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
PLACE, SCRAPS, KEYS, CHAIR, BAGS = [], [], [], [], []
ex(PLACE, {"pos": [HEAD[0], 4.835, HEAD[2]], "s": [1.9, 0.02, 1.4], "col": MAT, "rough": 0.9})
ex(PLACE, {"pos": [HEAD[0], 4.88, HEAD[2]], "s": [0.86, 0.05, 0.86], "shape": "cyl", "col": PLATE, "rough": 0.25})
for (dx, dz, a, s) in [(-0.15, 0.1, 0.4, 0.13), (0.18, -0.12, -0.7, 0.09), (0.05, 0.22, 1.2, 0.07), (-0.05, -0.2, 2.0, 0.06)]:
    ex(SCRAPS, {"pos": [HEAD[0] + dx, 4.912, HEAD[2] + dz], "s": [s, 0.01, s * 0.6], "rot": [0, a, 0], "col": SCRAP, "rough": 0.2})
ex(KEYS, {"pos": [HEAD[0] - 0.05, 4.93, HEAD[2] + 0.05], "s": [0.32, 0.02, 0.32], "shape": "cyl", "col": KEY, "rough": 0.3})
for (dx, dz, a) in [(0.2, -0.05, 0.3), (0.14, 0.18, -0.6)]:
    ex(KEYS, {"pos": [HEAD[0] + dx, 4.935, HEAD[2] + dz], "s": [0.38, 0.03, 0.09], "rot": [0, a, 0], "col": KEY, "rough": 0.25})
ex(KEYS, {"pos": [HEAD[0] - 0.22, 4.94, HEAD[2] + 0.02], "s": [0.22, 0.05, 0.14], "col": [20, 20, 22], "rough": 0.5})
# his chair at the head: seat, back, four legs
ex(CHAIR, {"pos": [SEATED[0], G + 2.2, SEATED[2]], "s": [2.0, 0.2, 1.9], "col": WOOD, "rough": 0.8})
ex(CHAIR, {"pos": [SEATED[0], G + 3.8, SEATED[2] + 0.9], "s": [2.0, 3.0, 0.18], "col": WOOD, "rough": 0.8})
for sx in (-0.85, 0.85):
    for sz in (-0.8, 0.8):
        ex(CHAIR, {"pos": [SEATED[0] + sx, G + 1.05, SEATED[2] + sz], "s": [0.16, 2.1, 0.16], "col": WOOD, "rough": 0.8})
# the bags by the front door
ex(BAGS, {"pos": [4.6, G + 0.55, -27.6], "s": [2.3, 1.1, 1.1], "col": [36, 48, 82], "rough": 0.85})
ex(BAGS, {"pos": [-0.9, G + 1.15, -28.3], "s": [1.6, 2.3, 0.7], "col": [104, 30, 34], "rough": 0.6})
ex(BAGS, {"pos": [5.2, G + 1.45, -27.7], "s": [1.2, 0.7, 0.8], "col": [70, 60, 44], "rough": 0.9})
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
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}

# 1. (hook) the dining table, lamps on: cosy (the fifth place isn't there yet)
def s_hook(i, k):
    cam = add(lerp([-22.0, G + 6.3, 9.5], [-20.8, G + 6.0, 11.0], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="dinLit", cam={"pos": cam, "look": lerp([-15.0, G + 3.4, 18.0], [-15.0, G + 3.3, 18.6], ease(k)), "fov": 60}, hideIdx=only()), None)
shot("hook", 105, s_hook)

# 2. (card) the same table in the dark, a slow push
def s_card(i, k):
    cam = add(lerp([-22.5, G + 6.6, 9.0], [-20.5, G + 6.2, 11.5], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="dinDark", cam={"pos": cam, "look": [-15.0, G + 3.4, 19.0], "fov": 60}, exposure=3.2, lamps=0, hideIdx=only(PLACE)), None)
shot("card", 120, s_card)

# 3. "night 15: five plates. there's four of us." the flashlight runs up the table to the fifth place
def s_open(i, k):
    cam = add(lerp([-15.0, G + 8.4, 10.0], [-15.0, G + 8.0, 11.2], ease(k)), hand(i, 0.5))
    tgt = lerp([-15.0, G + 3.8, 15.0], [HEAD[0], G + 3.85, HEAD[2]], ease((i - 6) / 40))
    return (dict(DARK, shot="dinDark", cam={"pos": cam, "look": lerp([-15.0, G + 3.8, 16.5], [-15.0, G + 3.8, 19.5], ease(k)), "fov": 58}, exposure=2.6, lamps=0,
                 hideIdx=only(PLACE), flash=fl(cam, tgt, 14.0, 0.3)), None)
shot("open", 72, s_open)

# 4. "night 16: someone ate from it." close on the plate: licked clean but for the scraps
def s_ate(i, k):
    cam = add([HEAD[0] - 0.5, G + 6.0, HEAD[2] - 2.6], hand(i, 0.4))
    return (dict(DARK, shot="dinDark", cam={"pos": cam, "look": [HEAD[0], G + 3.9, HEAD[2]], "fov": 46}, exposure=2.6, lamps=0, hideIdx=only(PLACE, SCRAPS),
                 flash=fl(cam, [HEAD[0], G + 3.9, HEAD[2]], 12.0, 0.32)), None)
shot("prints", 33, s_ate)

# 5. "night 17: he tucked my sister in." Lily's room: him bent over her bed in the night light
BEDSIDE = [33.4, U, 21.0]
def s_tuck(i, k):
    cam = add(lerp([15.0, U + 5.4, 19.6], [17.4, U + 5.2, 20.6], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="lily", cam={"pos": cam, "look": [33.0, U + 5.2, 22.8], "fov": 44}, exposure=3.0, glow=3.0, hideIdx=only()),
            him(BEDSIDE, facing(BEDSIDE, [35.4, U, 25.8]), "Stare", t=2.0 + i / FPS, Duck=1.1, Look=[-1.25, -0.25]))
shot("door", 90, s_tuck)

# 6. "night 18: he sat at the head of the table." down the table: him in the chair at the end, by candlelight
def s_sat(i, k):
    cam = add(lerp([-14.2, G + 5.1, 11.0], [-14.3, G + 5.2, 12.4], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="dinner", cam={"pos": cam, "look": [-15.0, G + 5.6, 22.0], "fov": 50}, exposure=2.4, lamps=0, glow=1.8, hideIdx=only(PLACE, SCRAPS, CHAIR)),
            him(SEATED, facing(SEATED, [-15.0, G, 10.0]), "Sit", t=4.0 + i / FPS, Look=[0.0, -0.1]))
shot("beside", 60, s_sat)

# 7. "so tonight we're leaving." the front hall, lamps on, the bags by the door
def s_pack(i, k):
    cam = add(lerp([1.4, G + 5.8, -16.5], [1.7, G + 5.7, -18.0], ease(k)), hand(i, 0.4))
    return (dict(LIT, shot="hallLit", cam={"pos": cam, "look": [2.2, G + 3.2, -29.5], "fov": 56}, hideIdx=only(BAGS)), None)
shot("nailed", 60, s_pack)

# 8. "the car keys were on his plate." the flashlight on the fifth plate: the keys
def s_keys(i, k):
    cam = add(lerp([HEAD[0] + 0.9, G + 6.6, HEAD[2] - 3.4], [HEAD[0] + 0.5, G + 6.1, HEAD[2] - 2.5], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="dinDark", cam={"pos": cam, "look": [HEAD[0], G + 3.9, HEAD[2]], "fov": 46}, exposure=2.6, lamps=0, hideIdx=only(PLACE, KEYS),
                 flash=fl(cam, [HEAD[0], G + 3.9, HEAD[2]], 12.0, 0.3)), None)
shot("nails", 60, s_keys)

# 9. "he doesn't want us to leave." at the front door with the flashlight... turn round: he's right behind you
# (the hit at 22.15 s is frame 64): the mask's jaw drops and he comes at you
CAMD = [2.0, G + EYE, -25.8]
BEHIND = [1.6, G, -19.6]
def s_behind(i, k):
    cam = add(CAMD, hand(i, 0.4))
    if i < 26:
        look = [2.0, G + 4.6, -30.0]
        return (dict(DARK, shot="hallDark", cam={"pos": cam, "look": look, "fov": 58}, exposure=3.2, lamps=0, hideIdx=only(BAGS), flash=fl(cam, look, 14.0, 0.36)), None)
    t = ease((i - 26) / 24)
    y0, y1 = facing(cam, [2.0, G, -30.0]), facing(cam, BEHIND)
    yaw = y0 + wrap(y1 - y0) * t
    ly = (G + 4.6) + ((G + 8.0) - (G + 4.6)) * ease((i - 34) / 16)
    look = [cam[0] - math.sin(yaw) * 6.0, ly, cam[2] - math.cos(yaw) * 6.0]
    if i < 64:
        fr = dict(DARK, shot="hallDark", cam={"pos": cam, "look": look, "fov": 58}, exposure=2.4, lamps=0, hideIdx=only(BAGS), glow=2.4,
                  flash=fl(cam, look if t < 0.98 else [BEHIND[0], G + 8.0, BEHIND[2]], 12.0, 0.42))
        return (fr, him(BEHIND, facing(BEHIND, cam), "Stare", t=3.0 + i / FPS, Look=[0.0, -0.2], Scream=0.2 * ease((i - 54) / 10)))
    w = ease((i - 64) / 4)
    p = lerp(BEHIND, [1.8, G, -21.9], w)
    fr = dict(DARK, shot="hallDark", cam={"pos": cam, "look": [1.8, G + 8.2 + 1.7 * w, -21.0], "fov": 58 + 10 * w}, exposure=2.6, lamps=0, hideIdx=only(BAGS),
              glow=7.0, flash=fl(cam, [p[0], G + 8.0, p[2]], 14.0, 0.5))
    return (fr, him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Look=[0.0, -0.3]))
shot("behind", 75, s_behind)

# 10. RUN: up the stairs, looking back: he comes up after you on all fours
def sy(z): return max(G, min(U, 2.05 + 0.625 * (z + 5.3) - 1.0))
def s_run(i, k):
    zc = -2.0 + 9.0 * k
    cam = [-5.0 + 0.25 * math.sin(i * 1.7), sy(zc) + 5.0 + 0.2 * math.sin(i * 2.3), zc]
    zh = -12.0 + 9.0 * k
    hy = sy(zh)
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, hy + 2.6, zh], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [-5.0 + 1.2 * math.sin(i * 1.3), hy + 3.0, zh], 18.0, 0.36), ambient=0.01, exposure=1.8, glow=6, hideIdx=only()),
            him([-5.0, hy, zh], facing([-5.0, hy, zh], [-5.0, hy, zh + 10]), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
