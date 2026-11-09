# Reel 72 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 10)": the PEAK run on #2's track, the v148 creature (his
# sculpted porcelain face). The basement: down the stairs with the flashlight; in the far corner, by the child's chair that
# faces the wall, him crouched facing the wall too; his head turns right round; light off, down behind the dust-sheeted
# furniture, his legs go past; peek over: the corner empty, the stairs empty; down again; turn... he's beside you (22.15 s). RUN.
#   hook (105)  down the basement stairs, the flashlight on the concrete
#   card (120)  across the basement: the boiler, the sheeted furniture... the far corner: the chair, him facing the wall
#   72          closer: his long back, his hair, the doll on the little chair beside him
#   33          his head turns right round: the face in the torchlight
#   90          down behind the sheeted furniture, light off: his legs go past the gap
#   60          peek over: the corner's empty, the chair
#   60          turn to the stairs: nobody
#   60          down again: the sheet, breathing
#   75          turn to the left... his face right there, down at you (22.15 s)
#   30          RUN for the stairs, him after you on all fours
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau + mask.json), shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
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

COLD, MOON = "#3d4f7a", "#6f86c4"
HIDE = ["CandyWrap", "CandyBody"]
B = -13.0
# the basement (floor B): x -40..12, z -30..30; the stairs come down along x 9 from z 21 (the ground floor) to z 0.3;
# dust-sheeted furniture x -28.7..-19.3, z -15.7..-10.3 (2.7 high); the child's chair facing the north wall at (-26.5, -28.9)
BASE = [{"p": [-39, B + 10, -10], "col": MOON, "b": 1.2, "r": 22, "decay": 1.0}, {"p": [-39, B + 10, -24], "col": MOON, "b": 1.2, "r": 22, "decay": 1.0},
        {"p": [-10, B + 9, 0], "col": COLD, "b": 0.5, "r": 26}, {"p": [9, B + 13, 22], "col": "#ffd8a8", "b": 0.9, "r": 14},
        {"p": [-24, B + 9, -21], "col": MOON, "b": 0.9, "r": 14}, {"p": [-20, B + 8, -6], "col": COLD, "b": 0.6, "r": 12}]
SHOTS = {"base": {"center": [-14, B + 5, -6], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": BASE}}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + HIDE
DARK = {"ambient": 0.02, "bg": 0x010102}
CORNER = [-24.6, B, -27.4]
WALLWARD = facing(CORNER, [-24.6, B, -40.0])

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

# 1. (hook) down the basement stairs, the torch on the concrete below
def s_hook(i, k):
    w = ease(k)
    cam = add(lerp([9.0, B + 13.0 + 4.6, 21.0], [9.0, B + 5.6, 3.0], w), hand(i, 0.6))
    look = lerp([9.0, B + 4.0, 8.0], [-6.0, B + 2.5, -6.0], ease((i - 30) / 75))
    return (dict(DARK, shot="base", cam={"pos": cam, "look": look, "fov": 66}, exposure=3.6, flash=fl(cam, look, 13.0, 0.4)), None)
shot("hook", 105, s_hook)

# 2. (card) across the basement, the torch sweeping: the boiler side, the sheeted furniture, then the far corner: him facing the wall
def s_card(i, k):
    cam = add(lerp([6.0, B + 5.6, 0.0], [-12.0, B + 5.5, -6.0], ease(k)), hand(i, 0.4))
    a = ease(i / 70)
    look = lerp([-20.0, B + 3.0, 14.0], [-24.0, B + 2.4, -12.0], a) if i < 70 else lerp([-24.0, B + 2.4, -12.0], [CORNER[0], B + 6.0, CORNER[2]], ease((i - 70) / 40))
    return (dict(DARK, shot="base", cam={"pos": cam, "look": look, "fov": 60}, exposure=3.6, flash=fl(cam, look, 14.0, 0.34), glow=0.6),
            him(CORNER, WALLWARD, "Stare", t=1.0 + stop(i)))
shot("card", 120, s_card)

# 3. closer: his long back, the hair, the doll on the little chair beside him
def s_close(i, k):
    cam = add(lerp([-21.0, B + 5.6, -16.5], [-22.4, B + 5.6, -19.6], ease(k)), hand(i, 0.3))
    look = [CORNER[0] - 0.4, B + 6.4 + 0.8 * ease(k), CORNER[2]]
    return (dict(DARK, shot="base", cam={"pos": cam, "look": look, "fov": 50}, exposure=3.4, flash=fl(cam, look, 12.0, 0.3), glow=0.6),
            him(CORNER, WALLWARD, "Stare", t=2.0 + stop(i)))
shot("close", 72, s_close)

# 4. his head turns right round: the face in the torchlight
CAM4 = [-22.4, B + 5.6, -19.6]
def s_turn(i, k):
    cam = add(CAM4, hand(i, 0.25))
    turn = ease((stop(i, 12) * 30 - 2) / 10)
    yaw = wrap(facing(CORNER, CAM4) - WALLWARD)
    look = [CORNER[0], B + 8.0, CORNER[2]]
    return (dict(DARK, shot="base", cam={"pos": cam, "look": look, "fov": 46 - 8 * ease(k)}, exposure=3.4, flash=fl(cam, look, 12.0, 0.26), glow=2.0),
            him(CORNER, WALLWARD, "Stare", t=2.6 + stop(i), Look=[yaw * turn * 1.6, 0.12 * turn]))
shot("turn", 33, s_turn)

# 5. torch off, down behind the sheeted furniture: through the gap at its end, his legs go past
HID = [-21.0, B + 2.2, -8.4]
def s_hide(i, k):
    w = ease(i / 16)
    cam = add(lerp([-20.5, B + 4.8, -12.5], HID, w), hand(i, 0.2))
    m = ease((i - 20) / 66)
    p = lerp([-24.0, B, -22.0], [-16.5, B, -11.5], m)
    look = lerp([-24.0, B + 3.0, -20.0], [-17.0, B + 2.4, -13.0], ease((i - 20) / 60))
    return (dict(DARK, shot="base", cam={"pos": cam, "look": look, "fov": 58}, exposure=6.5, glow=1.2), him(p, facing(p, [-12, B, -6]), "Walk", phase=m * 3.0 * TAU, t=3.0 + stop(i)))
shot("hide", 90, s_hide)

# 6. peek over the sheet: the corner's empty, the chair alone
OVER = [-22.0, B + 4.4, -9.4]
def s_peek(i, k):
    w = ease(i / 30)
    cam = add(lerp(HID, OVER, w), hand(i, 0.2))
    return (dict(DARK, shot="base", cam={"pos": cam, "look": lerp([-17.0, B + 2.4, -13.0], [-25.5, B + 2.8, -28.0], w), "fov": 54}, exposure=6.5), None)
shot("peek", 60, s_peek)

# 7. turn to the stairs: nobody
def s_stairs(i, k):
    w = ease(i / 45)
    cam = add(OVER, hand(i, 0.22))
    return (dict(DARK, shot="base", cam={"pos": cam, "look": lerp([-25.5, B + 1.6, -28.0], [8.0, B + 4.0, 6.0], w), "fov": 56}, exposure=6.5), None)
shot("stairs", 60, s_stairs)

# 8. down again behind the sheet: the folds, breathing
def s_down(i, k):
    w = ease(i / 18)
    cam = add(lerp(OVER, HID, w), hand(i, 0.12 + 0.08 * math.sin(i * 0.3) ** 2))
    return (dict(DARK, shot="base", cam={"pos": cam, "look": lerp([8.0, B + 4.0, 6.0], [-24.0, B + 1.6, -10.6], w), "fov": 56}, exposure=6.5), None)
shot("down", 60, s_down)

# 9. turn to the left... on 22.15 s (frame 65) he's right there beside you, bent down to your level
BESIDE = [-28.4, B, -5.4]
def s_last(i, k):
    if i < 65:
        w = ease(i / 55)
        cam = add(HID, hand(i, 0.12))
        return (dict(DARK, shot="base", cam={"pos": cam, "look": lerp([-24.0, B + 1.6, -10.6], [-30.0, B + 2.2, -6.0], w), "fov": 56}, exposure=6.5), None)
    w = ease((i - 65) / 4)
    cam = add(HID, [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    p = lerp(BESIDE, [-27.2, B, -6.4], w)
    return (dict(DARK, shot="base", cam={"pos": cam, "look": [p[0], B + 5.4 - 0.4 * w, p[2]], "fov": 62 + 8 * w}, exposure=4.0, glow=6.0,
                 flash=fl(cam, [p[0], B + 3.6, p[2]], 1.2 * w, 0.5)),
            him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Duck=1.9, Look=[0.0, 0.3]))
shot("last", 75, s_last)

# 10. RUN: for the stairs, looking back: he comes after you on all fours
def s_run(i, k):
    c = lerp([-16.0, 0, -6.0], [4.0, 0, 1.0], k)
    cam = [c[0] + 0.25 * math.sin(i * 1.7), B + 5.0 + 0.2 * math.sin(i * 2.3), c[2]]
    hp = lerp([-24.0, B, -8.0], [-12.0, B, -5.0], k)
    return (dict(DARK, shot="base", cam={"pos": cam, "look": [hp[0], B + 2.6, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), B + 2.8, hp[2]], 14.0, 0.36), exposure=2.6, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": [],
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
