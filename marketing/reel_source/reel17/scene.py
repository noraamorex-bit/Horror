# Reel 17 — the cinematic trailer: all-new shots rendered from the built game (film2.mjs), cut with
# title cards in comp16.mjs. python3 scene.py [preview]  (preview: 3 frames a shot at 360x640)
# Writes spec.json (camera, lights, avatars per frame), frames_in.json (his pose per frame) and
# shots.json (each shot's first frame and length, for the edit).
import json, math, sys
S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
rl = json.load(open(f"{S}/reel/spec_reel.json"))
TAU = math.pi * 2

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
WALK = TAU / 5.2      # stride phase per stud (CreaturePose.phaseRate)
RUN = TAU / 7.5

SHOTS = {
    "ext": dict(rl["shots"]["ext"], radius=150, maxLamps=6),   # (the whole street with 14 lamps renders far too slowly)
    "living": {"center": [-22, 6, -14], "radius": 46, "lampRadius": 30, "maxLamps": 12,
               "lights": [{"p": [-34, 8.5, -35], "col": "#5a6fa0", "b": 1.2, "r": 8, "decay": 1.6}]},
    "hatch": {"center": [6, 22, 8], "radius": 34, "lampRadius": 0, "maxLamps": 0,
              "lights": [{"p": [6, 27.6, 11], "col": "#ffb066", "b": 2.4, "r": 7, "decay": 1.4},   # a glow round the hatch
                         {"p": [6, 21, 2], "col": "#4a62a0", "b": 2.6, "r": 20},
                         {"p": [10, 24, 16], "col": "#3d5287", "b": 1.6, "r": 16}]},
    "attic": {"center": [-18, 31, 0], "radius": 34, "lampRadius": 40, "maxLamps": 3,
              "lights": [{"p": [-19, 30.1, -4], "col": "#ffb066", "b": 3.0, "r": 18, "decay": 1.3},
                         {"p": [-6, 33, 2], "col": "#2c3a66", "b": 1.0, "r": 16}]},
    "garage": {"center": [52, 7, -6], "radius": 34, "lampRadius": 0, "maxLamps": 0, "hide": ["GarageHatchCover"],
               "lights": [{"p": [52, 17.5, -1], "col": "#ffb066", "b": 2.6, "r": 10, "decay": 1.3},       # the attic, through the hatch
                          {"p": [44, 6, -24], "col": "#3a4f86", "b": 1.6, "r": 26}]},
    "stairs": {"center": [-5, 10, 4], "radius": 34, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [-4, 22, 24], "col": "#33467a", "b": 1.4, "r": 18}]},
    "underbed": {"center": [-26, 17, -14], "radius": 26, "lampRadius": 0, "maxLamps": 0,
                 "lights": [{"p": [-24, 20, -29], "col": "#7f97cf", "b": 1.6, "r": 18},               # moonlight from the front window
                            {"p": [-10, 18, -10], "col": "#c9a36a", "b": 1.2, "r": 10}]},             # the hall light through the door
    "hall": {"center": [3, 21, 0], "radius": 40, "lampRadius": 0, "maxLamps": 0,
             "lights": [{"p": [4, 25.5, 6], "col": "#d9c39a", "b": 5.0, "r": 16},                      # one bulb mid-hall
                        {"p": [5, 22, 12.5], "col": "#c9a36a", "b": 2.4, "r": 10},
                        {"p": [3, 21, -24], "col": "#2c3d6e", "b": 1.6, "r": 24},
                        {"p": [3, 21, 16], "col": "#2c3d6e", "b": 1.2, "r": 16}]},
    "boiler": {"center": [-30, -8, 19], "radius": 26, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [-30, -3.5, 20], "col": "#ffae5c", "b": 4.2, "r": 18, "decay": 1.3},   # the bare bulb
                          {"p": [-22, -8, 12], "col": "#1f2a4a", "b": 1.0, "r": 14}]},
    "chase": {"center": [2, 6, -4], "radius": 44, "lampRadius": 0, "maxLamps": 0,
              "hide": ["Head", "Hair", "HairSide", "HairBack", "Neck", "Eye", "Mouth", "Brow"],   # (spare NPC heads parked at the origin)
              "lights": [{"p": [2, 9, 18], "col": "#2c3d6e", "b": 1.2, "r": 24}]},
    "black": {"center": [0, -200, 0], "radius": 1, "lampRadius": 0, "maxLamps": 0,
              "lights": [{"p": [-1.5, 8.6, -3.5], "col": "#c9d4ff", "b": 2.2, "r": 9, "decay": 1.2},      # the hero close-up: a cold key
                         {"p": [2.4, 8.0, 1.2], "col": "#ff4a2a", "b": 1.6, "r": 6, "decay": 1.3},       # a red rim
                         {"p": [-2.4, 7.4, 1.2], "col": "#5a7cff", "b": 1.0, "r": 6, "decay": 1.3}]},
}
FLOOR_U = 15.0
AVS = []
LIVING_CAM = [-13.6, 8.0, -28.2]
# the three friends in the living room (two standing by the couch, one on their phone)
FRIENDS = [
    ([-16.6, 4.0, -12.4], {"hoodie": "#2f7de0", "hoodieDark": "#215ca8", "pants": "#2a2a33", "hair": "#e0b25a"}, {"neckY": 0.25}, None),
    ([-19.2, 4.0, -14.4], {"hoodie": "#d6363c", "hoodieDark": "#a8262d", "pants": "#2b3b5c", "hair": "#3b2416"},
     {"rShoulder": [0.9, 0, -0.1], "rElbow": 1.1, "lShoulder": [0.9, 0, 0.1], "lElbow": 1.1, "neckX": 0.35}, {"hand": "both", "light": 3.0}),
    ([-21.8, 4.0, -16.4], {"hoodie": "#3fae5a", "hoodieDark": "#2c8043", "pants": "#3a3a40", "hair": "#141012", "skin": "#8d5a3b"}, {"neckY": -0.35}, None),
]
for pos, col, pose, phone in FRIENDS:
    a = {"pos": pos, "yaw": facing(pos, LIVING_CAM), "pose": pose, "colors": col}
    if phone: a["phone"] = phone
    AVS.append(a)
# the captive in the boiler room: zip-tied to the pipes, arms back, head down
AVS.append({"pos": [-37.0, -10.0, 19.0], "yaw": -math.pi / 2, "pose": {"rShoulder": [-0.5, 0, 0.35], "lShoulder": [-0.5, 0, -0.35], "rElbow": 0.6, "lElbow": 0.6, "neckX": 0.45},
            "colors": {"hoodie": "#f0a020", "hoodieDark": "#c07a10", "pants": "#2a2a33", "hair": "#6b4423"}})

frames, crs, shots = [], [], []
f = 0
def shot(name, n, fn):
    """fn(i, k) -> (frame dict without f, creature dict or None)"""
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

# 1. the house from the street, at night, a slow push; someone in the upstairs window
def s_ext(i, k):
    e = ease(k)
    return ({"shot": "ext", "cam": {"pos": lerp([-9, 3.2, -84], [-4, 5.2, -70], e), "look": lerp([2, 13, -30], [2, 15, -30], e), "fov": 48},
             "lamps": 1.0, "ambient": 0.05, "moon": 0.35, "exposure": 1.35, "bg": 0x04060c, "fog": [60, 260], "glow": 4},
            {"pos": [2.0, FLOOR_U, -27.6], "yaw": 0.0, "gait": "Stare", "t": i / 30, "neck": [0.05, 0, 0.1]})
shot("ext", 105, s_ext)

# 2. the living room: warm, the three of them... then the lights go (and stay out)
def s_living(i, k):
    lamps = 1.0
    if i > 96:
        lamps = 0.0 if i > 128 else (1.0 if (i * 7919) % 11 < 4 else 0.08)
    cam = lerp([LIVING_CAM[0] + 0.8, LIVING_CAM[1] + 0.3, LIVING_CAM[2] - 0.8], LIVING_CAM, ease(k))
    return ({"shot": "living", "cam": {"pos": cam, "look": [-19.2, 4.6, -14.4], "fov": 40},
             "lamps": lamps, "ambient": 0.2 if lamps > 0.5 else 0.015, "exposure": 1.05 if lamps > 0.5 else 1.9, "bg": 0x050506, "xl": 1.0}, None)
shot("living", 150, s_living)

# 3. the attic hatch from below: something warm up there
def s_hatch(i, k):
    return ({"shot": "hatch", "cam": {"pos": lerp([6.5, 16.6, 0.5], [6.2, 17.4, 4.5], ease(k)), "look": [6.0, 28.6, 11.0], "fov": 56, "roll": 0.04},
             "ambient": 0.06, "exposure": 1.9, "bg": 0x020203}, None)
shot("hatch", 90, s_hatch)

# 4. the nest: a dolly along the walkway past the tally marks and the photos
def s_attic(i, k):
    return ({"shot": "attic", "cam": {"pos": lerp([-7.5, 32.0, -1.0], [-14.5, 31.4, -0.6], ease(k)), "look": lerp([-24, 30.4, 1.0], [-26, 30.2, -1.5], k), "fov": 58},
             "lamps": 0.6, "ambient": 0.03, "exposure": 1.6, "bg": 0x020203}, None)
shot("attic", 105, s_attic)

# 5. the garage: he comes down through the hatch
def s_garage(i, k):
    drop = min(1.0, k / 0.62)
    y = 14.2 + (1.0 - 14.2) * (drop * drop)
    return ({"shot": "garage", "cam": {"pos": lerp([46.8, 2.6, -15.5], [47.2, 2.8, -14.0], k), "look": lerp([52, 12.5, -1], [52, 6.2, -1], ease(min(1, k * 1.2))), "fov": 56},
             "ambient": 0.02, "exposure": 1.8, "bg": 0x020203, "glow": 7},
            {"pos": [52.0, y, -1.0], "yaw": facing([52, 0, -1], [47, 0, -15]), "gait": "Stare", "t": i / 30,
             "duck": 0.35 if drop >= 1 else 0.0, "neck": [0.25 if drop >= 1 else -0.2, 0, 0.15]})
shot("garage", 105, s_garage)

# 6. the stairs: a flashlight finds him at the top
def s_stairs(i, k):
    cam = [-4.6, 5.6, -12.2]
    sweep = ease(min(1.0, k / 0.55))
    tgt = lerp([-7.5, 10.0, 6.0], [-5.0, 19.5, 19.5], sweep)
    return ({"shot": "stairs", "cam": {"pos": cam, "look": lerp([-5, 13, 10], [-5, 17.5, 18], ease(k)), "fov": 46},
             "flash": {"i": 16.0, "pos": [cam[0] + 0.7, cam[1] - 0.7, cam[2]], "target": tgt, "angle": 0.28},
             "ambient": 0.015, "exposure": 1.7, "bg": 0x020203, "glow": 8},
            {"pos": [-5.0, FLOOR_U, 19.6], "yaw": 0.0, "gait": "Stare", "t": i / 30, "duck": 0.25, "neck": [0.3, 0.0, 0.25 if k > 0.7 else 0.0]})
shot("stairs", 96, s_stairs)

# 7. under the bed: his feet come in, and stop
P0, P1 = [-10.5, FLOOR_U, -11.0], [-27.0, FLOOR_U, -14.0]
def s_underbed(i, k):
    walk = min(1.0, k / 0.7)
    p = lerp(P0, P1, ease(walk))
    dist = math.hypot(p[0] - P0[0], p[2] - P0[2])
    stopped = walk >= 1
    return ({"shot": "underbed", "cam": {"pos": [-32.2, 15.75, -14.6], "look": [-20, 16.3, -13.4], "fov": 66},
             "ambient": 0.02, "moon": 0.2, "exposure": 1.8, "bg": 0x020203, "glow": 4},
            {"pos": p, "yaw": facing(P0, P1), "gait": "Search" if stopped else "Walk", "phase": dist * WALK, "t": i / 30})
shot("underbed", 120, s_underbed)

# 8. the upstairs hall: he crosses at the far end (a long lens, a tilted frame)
def s_hall(i, k):
    x = 10.0 + (-1.0 - 10.0) * k
    return ({"shot": "hall", "cam": {"pos": [3.0, 20.6, -27.0], "look": [3.0, 19.8, 20.0], "fov": 34, "roll": -0.07},
             "ambient": 0.05, "exposure": 1.8, "bg": 0x020203, "glow": 6},
            {"pos": [x, FLOOR_U, 15.0], "yaw": math.pi / 2, "gait": "Walk", "phase": (10.0 - x) * WALK, "t": i / 30})
shot("hall", 78, s_hall)

# 9. the boiler room: someone zip-tied to the pipes; he walks past, close, in silhouette
def s_boiler(i, k):
    z = 26.0 + (12.0 - 26.0) * k
    return ({"shot": "boiler", "cam": {"pos": lerp([-24.5, -7.4, 18.0], [-25.2, -7.6, 18.4], k), "look": [-36.5, -9.6, 19.2], "fov": 54},
             "ambient": 0.02, "exposure": 1.5, "bg": 0x020203, "glow": 3},
            {"pos": [-28.6, -13.0, z], "yaw": 0.0, "gait": "Walk", "phase": (26.0 - z) * WALK, "t": i / 30})
shot("boiler", 105, s_boiler)

# 10. the chase: down the front hall, straight at you, flashlight shaking
def s_chase(i, k):
    z = 18.0 + (-17.5 - 18.0) * k
    cam = [2.0 + 0.25 * math.sin(i * 1.7), 5.6 + 0.2 * math.sin(i * 2.3), -22.0]
    return ({"shot": "chase", "cam": {"pos": cam, "look": [2.0, 5.2, 10.0], "fov": 62, "roll": 0.05 * math.sin(i * 0.9)},
             "flash": {"i": 18.0, "pos": [cam[0] + 0.6, cam[1] - 0.6, cam[2]], "target": [2.0 + 1.5 * math.sin(i * 1.3), 5.0, z], "angle": 0.36},
             "ambient": 0.01, "exposure": 1.7, "bg": 0x020203, "glow": 8},
            {"pos": [2.0, 1.0, z], "yaw": 0.0, "gait": "Chase", "phase": (18.0 - z) * RUN, "t": i / 30})
shot("chase", 30, s_chase)

# 11. the hero close-up: his head turns to you
def s_hero(i, k):
    turn = ease(min(1.0, max(0.0, (k - 0.15) / 0.6)))
    return ({"shot": "black", "cam": {"pos": lerp([0.0, 7.5, -9.0], [0.0, 7.6, -7.0], ease(k)), "look": [0.0, 7.45, 0.0], "fov": 28},
             "ambient": 0.0, "exposure": 1.4, "bg": 0x000000, "glow": 9 * turn},
            {"pos": [0.0, 0.0, 0.0], "yaw": 1.25 * (1 - turn), "gait": "Stare", "t": i / 30, "neck": [0.05, 0.0, 0.0]})
shot("hero", 96, s_hero)

# the underside of the bed, right over the camera, and the edge of its frame
EXTRAS = [{"shape": "box", "pos": [-34.4, 16.95, -14.5], "s": [6.4, 0.35, 7.8], "col": [26, 24, 22], "rough": 0.95},
          {"shape": "box", "pos": [-31.0, 16.55, -14.5], "s": [0.35, 0.8, 7.8], "col": [40, 32, 26], "rough": 0.8},
          {"shape": "box", "pos": [-33.4, 15.4, -18.3], "s": [0.4, 0.8, 0.4], "col": [40, 32, 26]},
          {"shape": "box", "pos": [-33.4, 15.4, -10.7], "s": [0.4, 0.8, 0.4], "col": [40, 32, 26]}]
W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": AVS, "extras": EXTRAS}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / 30, 1), "s;", "preview" if PREVIEW else "full")
