# Reel 32 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 10)": Parts 2-9's format on #2's track
# (every clip keeps #2's length, so the track's cuts and hits land). The garage: the car keys, the way
# out the game gives you, and him coming in after you.
#   hook (105)  the garage at night: the red car under a dim bulb, a slow push
#   card (120)  the flashlight on the pegboard: the car keys, hanging there
#   72          the door from the house creaks open (light from the hall)
#   33          duck down behind the car
#   90          crouched at the back of the car: he comes in from the house
#   60          he walks down the far side of the car
#   60          he stops at the back door and bends to look in through the window
#   60          his head comes up... and turns towards the back of the car
#   75          nothing... he's round the corner at you (the scare at 22.15 s)
#   30          RUN: out the side door, he comes round the car after you
# python3 scene.py [preview]. Writes spec.json, frames_in.json, shots.json.
import json, math, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G = 1.0
EYE = 5.6
WALK = math.tau / 5.2
RUN = math.tau / 7.5

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]

# the garage (World/Interior): x 40..66, z -30..5; the sedan at (53, -17), nose towards +z
# (body x 49.7..56.3, rear bumper z -24.6); the door from the house in the x = 40 wall at z -3
# (hinge z -5.45); the side door out in the x = 66 wall at z -2; the pegboard on the x = 66 wall
HIDE = [56.2, G + 3.1, -26.6]     # crouched behind the car's rear corner, eyes just over the trunk
ENTRY = {"near": [40.0, 5.7, -3.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [40.0, 0, -5.45], "axis": "y"}
SIDE = {"near": [66.0, 5.7, -2.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [66.0, 0, -4.45], "axis": "y"}
KEYS = [65.55, 7.4, -13.6]
extras = [
    {"pos": [KEYS[0], KEYS[1] + 0.35, KEYS[2]], "s": [0.06, 0.06, 0.06], "shape": "ball", "col": [160, 160, 168]},           # the hook
    {"pos": [KEYS[0] - 0.05, KEYS[1] + 0.1, KEYS[2]], "s": [0.05, 0.36, 0.36], "shape": "cyl", "rot": [0, 0, math.pi / 2], "col": [200, 200, 205], "rough": 0.3},  # the ring
    {"pos": [KEYS[0] - 0.06, KEYS[1] - 0.25, KEYS[2] - 0.08], "s": [0.04, 0.55, 0.16], "rot": [0.25, 0, 0], "col": [205, 185, 120], "rough": 0.3},  # a key
    {"pos": [KEYS[0] - 0.06, KEYS[1] - 0.22, KEYS[2] + 0.12], "s": [0.04, 0.5, 0.16], "rot": [-0.3, 0, 0], "col": [200, 200, 205], "rough": 0.3},   # a key
    {"pos": [KEYS[0] - 0.06, KEYS[1] - 0.2, KEYS[2] + 0.02], "s": [0.05, 0.3, 0.2], "col": [190, 30, 30], "rough": 0.5},  # the tag
]
LIGHTS = [{"p": [53.0, 13.4, -12.0], "col": "#ffcf95", "b": 1.0, "r": 26, "decay": 1.1},     # the bare bulb, dim
          {"p": [37.0, 7.0, -3.0], "col": "#ffd8a8", "b": 1.4, "r": 16},                     # the hall, through the door from the house
          {"p": [53.0, 9.0, -32.0], "col": "#6f86c4", "b": 0.5, "r": 20},                    # night through the garage door's windows
          {"p": [55.0, 6.0, -28.6], "col": "#ffcf95", "b": 0.5, "r": 9}]                     # a little of the bulb on the car's trunk
SHOTS = {"garage": {"center": [53, 6, -12], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": LIGHTS, "door": ENTRY},
         "side": {"center": [58, 6, -10], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": LIGHTS + [{"p": [70.0, 8.0, -2.0], "col": "#6f86c4", "b": 1.2, "r": 18}], "door": SIDE}}
DARK = {"ambient": 0.03, "bg": 0x020203}

frames, crs, shots = [], [], []
f = 0
def shot(name, n, fn):
    global f
    shots.append({"name": name, "start": f, "n": n})
    idx = [0, n // 2, n - 1] if PREVIEW else range(n)
    for i in idx:
        k = i / max(1, n - 1)
        fr, cr = fn(i, k)
        fr["f"] = f + i
        fr["creature"] = cr is not None
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n

def gar(cam, look, fov, door=0.0, extra=None):
    fr = dict(DARK, shot="garage", cam={"pos": cam, "look": look, "fov": fov}, exposure=2.4, door=door)
    if extra: fr.update(extra)
    return fr

# 1. (hook) the garage at night: the red car under a dim bulb, a slow push
def s_hook(i, k):
    cam = add(lerp([63.5, G + EYE + 1.2, 1.5], [60.5, G + EYE + 0.6, -4.5], ease(k)), hand(i))
    return (gar(cam, lerp([53.0, G + 2.6, -16.0], [52.5, G + 2.8, -19.0], ease(k)), 58,
                0.0, {"flash": {"i": 9.0, "pos": [cam[0] - 0.4, cam[1] - 0.6, cam[2]], "target": [53.0, G + 3.0, -15.0], "angle": 0.42}}), None)
shot("hook", 105, s_hook)

# 2. (card) the flashlight on the pegboard: the car keys, hanging there
def s_card(i, k):
    cam = add(lerp([60.0, G + EYE - 0.2, -11.0], [61.6, G + EYE - 0.4, -12.4], ease(k)), hand(i, 0.6))
    tgt = lerp([65.6, 8.4, -20.0], KEYS, ease((k - 0.15) / 0.5))
    return (gar(cam, lerp([65.6, 8.0, -18.0], KEYS, ease((k - 0.2) / 0.5)), 52, 0.0,
                {"flash": {"i": 10.0, "pos": [cam[0] - 0.3, cam[1] - 0.5, cam[2]], "target": tgt, "angle": 0.3}}), None)
shot("card", 120, s_card)

# 3. the door from the house creaks open (light from the hall)
def s_door(i, k):
    cam = add([58.0, G + EYE - 0.4, -10.0], hand(i, 0.4))
    return (gar(cam, [40.0, G + 4.6, -3.0], 34, -1.2 * ease((k - 0.15) / 0.7)), None)
shot("door", 72, s_door)

# 4. duck down behind the car
def s_duck(i, k):
    w = ease(k)
    cam = add(lerp([58.0, G + EYE - 0.4, -12.0], HIDE, w), hand(i, 1.2))
    return (gar(cam, lerp([50.0, G + 4.0, -6.0], [53.0, G + 2.2, -22.0], w), 60, -1.2), None)
shot("duck", 33, s_duck)

def hiding(i, look, extra=None):
    fr = gar([HIDE[0], HIDE[1] + 0.03 * math.sin(i * 0.31), HIDE[2]], look, 46, -1.2, dict({"glow": 6, "exposure": 2.8}, **(extra or {})))
    return fr

# 5. crouched at the back of the car: he comes in from the house
IN = [41.6, G, -3.0]
FAR = [46.6, G, -10.0]
def s_enter(i, k):
    w = ease(min(1.0, k * 1.1))
    p = lerp(IN, FAR, w)
    return (hiding(i, [44.0, G + 4.6, -6.0]), {"pos": p, "yaw": facing(p, [47.0, G, -20.0]), "gait": "Walk", "phase": w * 8 * WALK, "t": i / 30})
shot("enter", 90, s_enter)

# 6. he walks down the far side of the car
WINDOW = [47.6, G, -18.2]
def s_side(i, k):
    w = ease(k)
    p = lerp(FAR, WINDOW, w)
    return (hiding(i, lerp([45.5, G + 4.6, -11.0], [47.0, G + 4.6, -17.0], w)),
            {"pos": p, "yaw": facing(p, [47.6, G, -24.0]), "gait": "Search", "phase": w * 8 * WALK, "t": i / 30})
shot("side", 60, s_side)

# 7. he stops at the back door and bends to look in through the window
def s_look(i, k):
    bend = ease(k / 0.6)
    return (hiding(i, [48.2, G + 4.2, -18.0]),
            {"pos": WINDOW, "yaw": facing(WINDOW, [53.0, G, -18.0]), "gait": "Stare", "t": i / 30, "duck": 0.9 * bend,
             "pitch": 0.35 * bend, "neck": [0.3 * bend, 0.0, 0.2]})
shot("look", 60, s_look)

# 8. his head comes up... and turns towards the back of the car
def s_turn(i, k):
    up = 1 - ease(k / 0.4)
    turn = ease((k - 0.35) / 0.55)
    yaw0 = facing(WINDOW, [53.0, G, -18.0])
    yaw1 = facing(WINDOW, HIDE)
    d = ((yaw1 - yaw0 + math.pi) % math.tau) - math.pi
    return (hiding(i, [48.2, G + 5.6, -18.0]),
            {"pos": WINDOW, "yaw": yaw0 + d * 0.3 * turn, "gait": "Stare", "t": i / 30, "duck": 0.9 * up, "pitch": 0.35 * up,
             "neck": [0.3 * up, 0.9 * turn, 0.25]})
shot("turn", 60, s_turn)

# 9. nothing... he's round the corner at you (22.15 s: frame 64 of this shot)
def s_lunge(i, k):
    if i < 64:
        look = lerp([48.2, G + 5.4, -18.0], [50.5, G + 2.8, -25.5], ease((i - 26) / 30))
        cr = {"pos": WINDOW, "yaw": facing(WINDOW, HIDE), "gait": "Stare", "t": i / 30, "neck": [0.0, 0.0, 0.3]} if i < 24 else None
        return (hiding(i, look), cr)
    j = i - 64
    p = lerp([50.2, G, -26.4], [52.7, G, -26.9], ease(j / 4.0))
    return (gar(HIDE, [p[0], G + 7.6, p[2]], 62, -1.2, {"glow": 12, "exposure": 3.0}),
            {"pos": p, "yaw": facing(p, HIDE), "gait": "Reach", "t": i / 30, "duck": 0.9, "neck": [0.0, 0.0, 0.3 * math.sin(i * 0.9)]})
shot("lunge", 75, s_lunge)

# 10. RUN: out the side door, looking back: he comes round the car after you
def s_run(i, k):
    cam = [59.0 + 6.5 * k + 0.2 * math.sin(i * 1.7), G + 4.8 + 0.2 * math.sin(i * 2.3), -8.0 + 5.0 * k]
    p = lerp([54.0, G, -26.0], [57.5, G, -15.0], k)
    return (dict(DARK, shot="side", cam={"pos": cam, "look": [p[0], G + 4.4, p[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash={"i": 16.0, "pos": [cam[0] - 0.5, cam[1] - 0.5, cam[2]], "target": [p[0], G + 4.0, p[2]], "angle": 0.4},
                 exposure=1.8, glow=8, door=1.3),
            {"pos": p, "yaw": facing(p, cam), "gait": "Chase", "phase": k * 15 * RUN, "t": i / 30})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
