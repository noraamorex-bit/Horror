# Reel 20 — "YOU CAN'T PLAY ALONE #9": the pizza man ("Is it just you kids in there?"), then the 911 call
# from the upstairs bathroom's one bar of signal. All-new shots rendered from the built game (film2.mjs,
# world_b.json), each the exact length of #2's clip in that slot so #2's music lands on the same cuts.
# python3 scene.py [preview]  (3 frames a shot, 360x640). Writes spec.json, frames_in.json, shots.json.
import json, math, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
TAU = math.pi * 2

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
WALK = TAU / 5.2
RUN = TAU / 7.5
G, U = 1.0, 15.0                      # floor tops: ground, upstairs
AV = 3.0                              # an avatar's origin above its feet

PORCH_LIGHT = {"p": [2, 10.2, -32.2], "col": "#ffb066", "b": 4.5, "r": 18, "decay": 1.3}
DOOR = {"near": [2, -30], "r": 2.4}   # (the front door leaf: hidden, so it stands open)
SHOTS = {
    "porch": {"center": [2, 6, -40], "radius": 120, "lampRadius": 40, "maxLamps": 4, "hide": [DOOR],
              "lights": [PORCH_LIGHT, {"p": [-30, 30, -90], "col": "#5a6fa0", "b": 1.2, "r": 120, "decay": 0.5}]},
    "doorway": {"center": [2, 6, -30], "radius": 60, "lampRadius": 0, "maxLamps": 0, "hide": [DOOR],
                "lights": [PORCH_LIGHT, {"p": [2, 11, -14], "col": "#c9a36a", "b": 1.6, "r": 14}]},
    "hatch": {"center": [6, 22, 8], "radius": 34, "lampRadius": 0, "maxLamps": 0,
              "lights": [{"p": [6, 27.6, 11], "col": "#ffb066", "b": 2.4, "r": 7, "decay": 1.4},
                         {"p": [6, 21, 2], "col": "#4a62a0", "b": 2.6, "r": 20},
                         {"p": [10, 24, 16], "col": "#3d5287", "b": 1.6, "r": 16}]},
    "living": {"center": [-22, 6, -14], "radius": 46, "lampRadius": 30, "maxLamps": 8,
               "hide": [{"near": [-17.6, -15.6], "r": 1.3}],
               "lights": [{"p": [-34, 8.5, -35], "col": "#5a6fa0", "b": 1.2, "r": 8, "decay": 1.6}]},
    "bath": {"center": [26, 20, 1], "radius": 40, "lampRadius": 0, "maxLamps": 0, "hide": [{"near": [12, 1], "r": 2.4}],   # (its door stands open)
            
             "lights": [{"p": [43, 22, 1], "col": "#7f97cf", "b": 2.6, "r": 26, "decay": 1.2},        # moonlight through the window
                        {"p": [8, 19, 1], "col": "#2c3d6e", "b": 1.6, "r": 14},
                        {"p": [22, 24, 1], "col": "#5a6fa0", "b": 0.8, "r": 16},
                        {"p": [16, 21.5, 1], "col": "#8fa4d8", "b": 0.7, "r": 8}]},          # (just enough to find him in the doorway)                   # the dark hall beyond the door
    "hall": {"center": [3, 21, 0], "radius": 40, "lampRadius": 0, "maxLamps": 0,
             "lights": [{"p": [4, 25.5, 6], "col": "#d9c39a", "b": 5.0, "r": 16},
                        {"p": [5, 22, 12.5], "col": "#c9a36a", "b": 2.4, "r": 10},
                        {"p": [3, 21, -24], "col": "#2c3d6e", "b": 1.6, "r": 24},
                        {"p": [3, 21, 16], "col": "#2c3d6e", "b": 1.2, "r": 16}]},
}
KIDS = [{"hoodie": "#2f7de0", "hoodieDark": "#215ca8", "pants": "#2a2a33", "hair": "#e0b25a"},
        {"hoodie": "#3fae5a", "hoodieDark": "#2c8043", "pants": "#3a3a40", "hair": "#141012", "skin": "#8d5a3b"},
        {"hoodie": "#f0a020", "hoodieDark": "#c07a10", "pants": "#2a2a33", "hair": "#6b4423"},
        {"hoodie": "#7a7f8c", "hoodieDark": "#5a5e68", "pants": "#2b3b5c", "hair": "#3b2416"}]
AVS = []
# the pizza man on the porch: red Tony's shirt, two boxes held out, his head tilted at the door
PIZZA_AT = [2.0, G + AV, -34.6]
AVS.append({"pos": PIZZA_AT, "yaw": facing(PIZZA_AT, [2, 0, -20]), "face": "blank",
            "pose": {"rShoulder": [0.3, 0, 0.12], "lShoulder": [0.3, 0, -0.12], "rElbow": 1.15, "lElbow": 1.15, "neckZ": 0.32, "neckX": 0.08},
            "colors": {"hoodie": "#c8262a", "hoodieDark": "#9a1c20", "pants": "#26262c", "hair": "#1a1512", "skin": "#e6c3a3"}})
# two of them at the open door, from behind
for x, col, ny in ((0.7, KIDS[0], 0.15), (3.4, KIDS[1], -0.2)):
    p = [x, G + AV, -27.6]
    AVS.append({"pos": p, "yaw": facing(p, [2, 0, -40]), "pose": {"neckY": ny}, "colors": col})
# the living room: three of them by the couch, one on their phone
LIVING_CAM = [-13.6, 8.0, -28.2]
for pos, col, pose, phone in (([-16.6, G + AV, -12.4], KIDS[0], {"neckY": 0.25}, None),
                              ([-19.2, G + AV, -14.4], KIDS[3], {"rShoulder": [0.9, 0, -0.1], "rElbow": 1.1, "lShoulder": [0.9, 0, 0.1], "lElbow": 1.1, "neckX": 0.35}, {"hand": "both", "light": 3.0}),
                              ([-21.8, G + AV, -16.4], KIDS[1], {"neckY": -0.35}, None)):
    a = {"pos": pos, "yaw": facing(pos, LIVING_CAM), "pose": pose, "colors": col}
    if phone: a["phone"] = phone
    AVS.append(a)
# upstairs bathroom: at the window, the phone held up high for the one bar of signal
CALLER = [34.6, U + AV, 0.2]
AVS.append({"pos": CALLER, "yaw": facing(CALLER, [45, 0, 0.6]), "face": "scared",
            "pose": {"rShoulder": [2.5, 0, 0.15], "rElbow": 0.5, "neckX": -0.25},
            "phone": {"hand": "r", "light": 4.0}, "colors": KIDS[2]})

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

NIGHT = {"ambient": 0.03, "bg": 0x04060c, "exposure": 1.5}

# 1. (hook, also the end card) the porch at night from the lawn: the pizza man, his back to us, waiting
def s_porch(i, k):
    e = ease(k)
    return (dict(NIGHT, shot="porch", cam={"pos": lerp([10.0, 5.0, -54.0], [7.5, 5.4, -48.5], e), "look": [1.8, 6.8, -33.0], "fov": 44},
                 lamps=0.9, moon=0.3, fog=[40, 200]), None)
shot("porch", 105, s_porch)

# 2. (case file, slow) the attic hatch from below: something warm up there
def s_hatch(i, k):
    return ({"shot": "hatch", "cam": {"pos": lerp([6.5, 16.6, 0.5], [6.2, 17.4, 4.5], ease(k)), "look": [6.0, 28.6, 11.0], "fov": 56, "roll": 0.04},
             "ambient": 0.06, "exposure": 1.9, "bg": 0x020203}, None)
shot("hatch", 80, s_hatch)

# 3. his face, from inside the open door: a slow push in
HEAD = [PIZZA_AT[0], PIZZA_AT[1] + 3.6, PIZZA_AT[2]]
def s_face(i, k):
    return (dict(NIGHT, shot="doorway", exposure=1.6, cam={"pos": lerp([2.05, 8.0, -28.6], [2.0, 8.0, -30.2], ease(k)), "look": [HEAD[0], HEAD[1] - 0.6, HEAD[2]], "fov": 46}), None)
shot("face", 72, s_face)

# 4. the two of them at the door, from behind; him outside under the porch light
def s_door(i, k):
    return (dict(NIGHT, shot="doorway", exposure=2.1, cam={"pos": lerp([2.0, 7.2, -20.5], [2.0, 7.1, -21.5], k), "look": [2.0, 6.4, -34.0], "fov": 50}), None)
shot("door", 33, s_door)

# 5. the living room: warm... then the lights go
def s_living(i, k):
    lamps = 1.0
    if i > 50:
        lamps = 0.0 if i > 66 else (1.0 if (i * 7919) % 11 < 4 else 0.08)
    cam = lerp([LIVING_CAM[0] + 0.8, LIVING_CAM[1] + 0.3, LIVING_CAM[2] - 0.8], LIVING_CAM, ease(k))
    return ({"shot": "living", "cam": {"pos": cam, "look": [-19.2, 4.6, -14.4], "fov": 40},
             "lamps": lamps, "ambient": 0.2 if lamps > 0.5 else 0.015, "exposure": 1.05 if lamps > 0.5 else 1.9, "bg": 0x050506, "xl": 1.0,
             "lightning": 0.6 if 74 <= i <= 76 else 0}, None)
shot("living", 90, s_living)

# 6. the bathroom window from behind: the phone held up at the glass, one bar
def s_signal(i, k):
    return ({"shot": "bath", "cam": {"pos": lerp([29.0, 20.4, 3.4], [30.2, 20.6, 3.0], ease(k)), "look": [39.5, 22.2, -0.8], "fov": 48},
             "ambient": 0.03, "exposure": 1.7, "bg": 0x020203, "lightning": 0.5 if 40 <= i <= 42 else 0}, None)
shot("signal", 60, s_signal)

# 7. the caller's face from the window, lit by the phone... and in the doorway behind them, him
DOORWAY = [12.9, U, 1.0]
def s_call(i, k):
    return ({"shot": "bath", "cam": {"pos": lerp([39.4, 21.3, -1.6], [39.3, 21.2, -1.4], k), "look": [24.0, 20.2, 2.6], "fov": 56},
             "ambient": 0.02, "exposure": 1.7, "bg": 0x020203, "glow": 6},
            {"pos": DOORWAY, "yaw": facing(DOORWAY, [37, 0, 1]), "gait": "Stare", "t": i / 30, "neck": [0.1, 0.0, 0.2]})
shot("call", 60, s_call)

# 8. the upstairs hall: he crosses at the far end
def s_hall(i, k):
    x = 10.0 + (1.5 - 10.0) * k
    return ({"shot": "hall", "cam": {"pos": [3.0, 20.6, -27.0], "look": [3.0, 19.8, 20.0], "fov": 34, "roll": -0.07},
             "ambient": 0.07, "exposure": 2.2, "bg": 0x020203, "glow": 6},
            {"pos": [x, U, 15.0], "yaw": math.pi / 2, "gait": "Walk", "phase": (10.0 - x) * WALK, "t": i / 30})
shot("hall", 60, s_hall)

# 9. he steps into the bathroom and stops; his head snaps round to you (the flash at 2.15 s)
def s_enter(i, k):
    walk = ease(min(1.0, k / 0.62))
    x = 10.0 + (17.5 - 10.0) * walk
    snap = ease((k - 0.84) / 0.06)
    p = [x, U, 1.0]
    return ({"shot": "bath", "cam": {"pos": [39.3, 20.8, -2.6], "look": lerp([16, 19.5, 1.2], [18, 20.5, 1.0], ease(k)), "fov": 38},
             "ambient": 0.05, "exposure": 2.3, "bg": 0x020203, "glow": 4 + 6 * snap},
            {"pos": p, "yaw": facing(p, [37, 0, 1]), "gait": "Walk" if walk < 1 else "Stare", "phase": (x - 10.0) * WALK, "t": i / 30,
             "neck": [0.25 * snap, 0.0, 0.35 * (1 - snap)]})
shot("enter", 75, s_enter)

# 10. RUN: across the bathroom, straight at you, the flashlight shaking
def s_run(i, k):
    x = 18.0 + (32.5 - 18.0) * k
    z = 1.0 + (-1.8 - 1.0) * k
    cam = [39.2 + 0.15 * math.sin(i * 2.3), 20.6 + 0.2 * math.sin(i * 1.7), -2.7 + 0.2 * math.sin(i * 1.3)]
    return ({"shot": "bath", "cam": {"pos": cam, "look": [20.0, 20.0, 0.6], "fov": 62, "roll": 0.05 * math.sin(i * 0.9)},
             "flash": {"i": 18.0, "pos": [cam[0] - 0.6, cam[1] - 0.6, cam[2] + 0.4], "target": [x, 19.0 + 1.0 * math.sin(i * 1.1), z + 1.2 * math.sin(i * 1.3)], "angle": 0.36},
             "ambient": 0.01, "exposure": 1.7, "bg": 0x020203, "glow": 8},
            {"pos": [x, U, z], "yaw": facing([x, 0, z], [39.2, 0, -2.7]), "gait": "Chase", "phase": (x - 18.0) * RUN, "t": i / 30, "duck": 0.3})
shot("run", 30, s_run)

# the two pizza boxes in his hands (Tony's: white card, a red band)
EXTRAS = [{"shape": "box", "pos": [2.0, 4.75, -33.4], "s": [2.3, 0.36, 2.3], "col": [236, 228, 210], "rough": 0.9},
          {"shape": "box", "pos": [2.0, 5.12, -33.4], "s": [2.3, 0.36, 2.3], "col": [236, 228, 210], "rough": 0.9},
          {"shape": "box", "pos": [2.0, 5.31, -33.4], "s": [1.1, 0.03, 1.1], "col": [200, 50, 40], "rough": 0.8}]
W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": AVS, "extras": EXTRAS}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / 30, 1), "s;", "preview" if PREVIEW else "full")
