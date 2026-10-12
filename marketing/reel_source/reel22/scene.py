# Reel 22 — "AMAZING NEW ROBLOX HORROR GAME TO PLAY WITH YOUR FRIENDS": a new format (the owner's idea):
# gameplay-style footage cut to an upbeat track (audio.py, 128 BPM), the game's name always on top.
# Avatars walk and run (per-frame poses, film2.mjs "av"), the camera follows the player in third person
# like the real game. Every cut lands on a bar or half bar. python3 scene.py [preview]
# Writes spec.json, frames_in.json (his pose per frame), shots.json (each clip's first frame and length).
import json, math, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
TAU = math.pi * 2
FPS = 30
BAR = 60 / 128 * 4 * FPS                 # 56.25 frames
def at(bars): return round(bars * BAR)

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
WALK = TAU / 5.2      # (his stride phase per stud: CreaturePose)
RUN = TAU / 7.5
G, U, B = 1.0, 15.0, -30.0           # floors: ground, upstairs, the burrow
AV = 3.0

# --- the players: a walk / run cycle for the Roblox avatar (avatar.js joints)
def gait(phase, run=False, look=(0, 0)):
    s, c = math.sin(phase), math.cos(phase)
    a = 0.85 if run else 0.5
    k = 1.25 if run else 0.6
    return {"lHip": a * s, "rHip": -a * s,
            "lKnee": -k * max(0.0, -c) - 0.1, "rKnee": -k * max(0.0, c) - 0.1,
            "lShoulder": [-a * 0.9 * s + (0.3 if run else 0), 0, -0.05], "rShoulder": [a * 0.9 * s + (0.3 if run else 0), 0, 0.05],
            "lElbow": 1.3 if run else 0.25, "rElbow": 1.3 if run else 0.25,
            "waist": -0.22 if run else 0.0, "neckX": 0.12 if run else 0.0, "neckY": look[0], "neckZ": look[1]}
def idle(i, t, look=0.0):
    return {"neckY": look + 0.08 * math.sin(t * 0.9 + i), "neckX": 0.04 * math.sin(t * 0.7 + i * 2), "lShoulder": [0.05, 0, -0.04], "rShoulder": [0.05, 0, 0.04]}
def player(i, pos, yaw, phase=0.0, run=False, pose=None):
    bob = 0.14 * abs(math.sin(phase)) if run else 0.05 * abs(math.sin(phase))
    return {"i": i, "pos": [pos[0], pos[1] + AV + bob, pos[2]], "yaw": yaw, "pose": pose or gait(phase, run)}

KIDS = [{"hoodie": "#2f7de0", "hoodieDark": "#215ca8", "pants": "#2a2a33", "hair": "#e0b25a"},
        {"hoodie": "#d6363c", "hoodieDark": "#a8262d", "pants": "#2b3b5c", "hair": "#3b2416"},
        {"hoodie": "#3fae5a", "hoodieDark": "#2c8043", "pants": "#3a3a40", "hair": "#141012", "skin": "#8d5a3b"},
        {"hoodie": "#f0a020", "hoodieDark": "#c07a10", "pants": "#2a2a33", "hair": "#6b4423"}]
AVS = [{"pos": [0, -500, 0], "yaw": 0, "colors": c} for c in KIDS]
AVS.append({"pos": [0, -500, 0], "yaw": 0, "face": "blank",                      # 4: the pizza man
            "colors": {"hoodie": "#c8262a", "hoodieDark": "#9a1c20", "pants": "#26262c", "hair": "#1a1512", "skin": "#e6c3a3"}})
AVS[2]["face"] = "scared"
AVS[3]["face"] = "scared"

PORCH_LIGHT = {"p": [2, 10.2, -32.2], "col": "#ffb066", "b": 4.5, "r": 18, "decay": 1.3}
DOOR = {"near": [2, -30], "r": 2.4}
SHOTS = {
    "fronthall": {"center": [2, 6, -8], "radius": 50, "lampRadius": 34, "maxLamps": 8},
    "living": {"center": [-22, 6, -14], "radius": 46, "lampRadius": 30, "maxLamps": 8, "hide": [{"near": [-17.6, -15.6], "r": 1.3}],
               "lights": [{"p": [-34, 8.5, -35], "col": "#5a6fa0", "b": 1.2, "r": 8, "decay": 1.6}]},
    "doorway": {"center": [2, 6, -30], "radius": 60, "lampRadius": 0, "maxLamps": 0, "hide": [DOOR],
                "lights": [PORCH_LIGHT, {"p": [2, 11, -14], "col": "#c9a36a", "b": 1.6, "r": 14}]},
    "stairs": {"center": [-5, 10, 4], "radius": 34, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [-4, 22, 24], "col": "#33467a", "b": 1.4, "r": 18}]},
    "uphall": {"center": [3, 21, 0], "radius": 40, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [3, 22, -24], "col": "#4a64a8", "b": 4.0, "r": 26}, {"p": [3, 22, -4], "col": "#4a64a8", "b": 3.2, "r": 20},
                          {"p": [3, 22, 12], "col": "#3d5287", "b": 3.0, "r": 18}]},
    "closet": {"center": [4, 20, -6], "radius": 30, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [0, 23, -6], "col": "#6a80bc", "b": 6.0, "r": 22}, {"p": [4, 21, -16], "col": "#3d5287", "b": 2.0, "r": 16},
                          {"p": [4, 21, 4], "col": "#3d5287", "b": 1.6, "r": 14}]},
    "boiler": {"center": [-30, -8, 19], "radius": 26, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [-30, -3.5, 20], "col": "#ffae5c", "b": 4.2, "r": 18, "decay": 1.3}, {"p": [-22, -8, 12], "col": "#1f2a4a", "b": 1.0, "r": 14}]},
    "dining": {"center": [-27, B + 4, 17], "radius": 34, "lampRadius": 22, "maxLamps": 4,
               "lights": [{"p": [-32.5, B + 5.6, 17], "col": "#ffb066", "b": 2.0, "r": 9, "decay": 1.5}, {"p": [-27.0, B + 5.6, 18.7], "col": "#ffb066", "b": 2.0, "r": 9, "decay": 1.5},
                          {"p": [-21.5, B + 5.6, 17], "col": "#ffb066", "b": 2.0, "r": 9, "decay": 1.5}, {"p": [-19, B + 4, 25.5], "col": "#7f9cff", "b": 1.4, "r": 8}]},
    "porch": {"center": [2, 6, -38], "radius": 60, "lampRadius": 30, "maxLamps": 3, "hide": [DOOR],
              "lights": [PORCH_LIGHT, {"p": [-30, 30, -90], "col": "#5a6fa0", "b": 1.2, "r": 120, "decay": 0.5}]},
}
# the police: red and blue, swapping (two light rigs)
for name, col in (("police_r", "#ff2a2a"), ("police_b", "#3a5cff")):
    SHOTS[name] = dict(SHOTS["porch"], lights=[PORCH_LIGHT, {"p": [-30, 30, -90], "col": "#5a6fa0", "b": 1.2, "r": 120, "decay": 0.5},
                                                {"p": [-8, 6, -62], "col": col, "b": 7.0, "r": 60, "decay": 1.0}])

frames, crs, shots = [], [], []
def shot(name, start_bar, bars, fn):
    f0, f1 = at(start_bar), at(start_bar + bars)
    n = f1 - f0
    shots.append({"name": name, "start": f0, "n": n})
    idx = [0, n // 2, n - 1] if PREVIEW else range(n)
    for i in idx:
        k = i / max(1, n - 1)
        fr, cr = fn(i, k)
        fr["f"] = f0 + i
        fr["creature"] = cr is not None
        fr.setdefault("av", [])
        frames.append(fr)
        if cr: cr["f"] = f0 + i; crs.append(cr)

# 1. (hook) the four of them walking down the front hall, warm lamps; third person behind the player
def s_hook(i, k):
    t = i / FPS
    d = 10.0 * t                                                     # walking pace, 10 studs/s
    ph = d / 4.6 * TAU
    base = -17.0 + d
    group = [(0, 0.6, 0.0), (1, 3.6, 1.5), (2, -1.4, -2.6), (3, 2.2, -3.4)]
    av = [player(j, [x, G, base + dz], math.pi, ph + j * 1.3) for j, x, dz in group]
    cam = [1.8, G + 8.6, base - 10.5]
    return ({"shot": "fronthall", "cam": {"pos": cam, "look": [1.6, G + 4.5, base + 6], "fov": 62},
             "lamps": 1.0, "ambient": 0.2, "exposure": 1.15, "bg": 0x050506, "av": av}, None)
shot("hook", 0, 2, s_hook)

# 2a. the living room, cozy: three of them on their feet by the couch, chatting
LIVING_CAM = [-13.6, 8.0, -28.2]
def s_living(i, k):
    t = i / FPS
    pts = [(0, [-16.6, G, -12.4]), (1, [-19.2, G, -14.4]), (2, [-21.8, G, -16.4])]
    av = [{"i": j, "pos": [p[0], p[1] + AV, p[2]], "yaw": facing(p, LIVING_CAM), "pose": idle(j, t, 0.3 if j == 0 else -0.3 if j == 2 else 0)} for j, p in pts]
    cam = lerp([LIVING_CAM[0] + 0.8, LIVING_CAM[1] + 0.3, LIVING_CAM[2] - 0.8], LIVING_CAM, ease(k))
    return ({"shot": "living", "cam": {"pos": cam, "look": [-19.2, 4.6, -14.4], "fov": 40}, "lamps": 1.0, "ambient": 0.2, "exposure": 1.05, "bg": 0x050506, "av": av}, None)
shot("living", 2, 0.5, s_living)

# 2b. the pizza man at the open door, head tilted, a slow push in
PIZZA = [2.0, G, -34.6]
def s_pizza(i, k):
    av = [{"i": 4, "pos": [PIZZA[0], PIZZA[1] + AV, PIZZA[2]], "yaw": facing(PIZZA, [2, 0, -20]),
           "pose": {"rShoulder": [0.3, 0, 0.12], "lShoulder": [0.3, 0, -0.12], "rElbow": 1.15, "lElbow": 1.15, "neckZ": 0.32 + 0.06 * k, "neckX": 0.08}}]
    head = [2.0, G + AV + 3.0, -34.6]
    return ({"shot": "doorway", "cam": {"pos": lerp([2.05, 8.0, -28.6], [2.0, 8.0, -30.0], ease(k)), "look": head, "fov": 46},
             "ambient": 0.03, "exposure": 1.6, "bg": 0x04060c, "av": av}, None)
shot("pizza", 2.5, 0.5, s_pizza)

# 3a. the lights go (living room)
def s_out(i, k):
    t = i / FPS
    lamps = 1.0 if i < 5 else (0.08 if i < 9 else (1.0 if i < 11 else 0.0))
    pts = [(0, [-16.6, G, -12.4]), (1, [-19.2, G, -14.4]), (2, [-21.8, G, -16.4])]
    av = [{"i": j, "pos": [p[0], p[1] + AV, p[2]], "yaw": facing(p, LIVING_CAM), "pose": idle(j, t, 0.5 * (j - 1))} for j, p in pts]
    return ({"shot": "living", "cam": {"pos": LIVING_CAM, "look": [-19.2, 4.6, -14.4], "fov": 40}, "lamps": lamps,
             "ambient": 0.2 if lamps > 0.5 else 0.04, "exposure": 1.05 if lamps > 0.5 else 2.6, "bg": 0x050506, "lightning": 0.7 if i in (16, 17) else 0, "av": av}, None)
shot("out", 3, 0.5, s_out)

# 3b. the stairs: a flashlight finds him at the top
def s_stairs(i, k):
    cam = [-4.6, 5.6, -12.2]
    sweep = ease(min(1.0, k / 0.5))
    return ({"shot": "stairs", "cam": {"pos": cam, "look": lerp([-5, 13, 10], [-5, 17.5, 18], ease(k)), "fov": 46},
             "flash": {"i": 16.0, "pos": [cam[0] + 0.7, cam[1] - 0.7, cam[2]], "target": lerp([-7.5, 10.0, 6.0], [-5.0, 19.5, 19.5], sweep), "angle": 0.28},
             "ambient": 0.015, "exposure": 1.7, "bg": 0x020203, "glow": 8},
            {"pos": [-5.0, U, 19.6], "yaw": 0.0, "gait": "Stare", "t": i / 30, "duck": 0.25, "neck": [0.3, 0.0, 0.25]})
shot("stairs", 3.5, 0.5, s_stairs)

# 4. exploring the dark upstairs hall with a flashlight (third person); he crosses at the far end
def s_explore(i, k):
    t = i / FPS
    z = -20.0 + 6.5 * t                                              # (careful steps)
    ph = (z + 20) / 4.6 * TAU
    p = [2.0, U, z]
    cam = [2.4, U + 8.4, z - 10.0]
    x = 11.0 + (1.0 - 11.0) * k
    return ({"shot": "uphall", "cam": {"pos": cam, "look": [2.0, U + 4.6, z + 8], "fov": 60},
             "flash": {"i": 14.0, "pos": [p[0] + 1.2, U + 4.6, z - 0.4], "target": [2.0 + 1.2 * math.sin(t * 2), U + 4.0, z + 20], "angle": 0.42},
             "ambient": 0.06, "exposure": 2.3, "bg": 0x020203, "glow": 6,
             "av": [player(0, p, math.pi, ph, pose=dict(gait(ph), rShoulder=[1.3, 0, 0.1], rElbow=0.3))]},
            {"pos": [x, U, 15.0], "yaw": math.pi / 2, "gait": "Walk", "phase": (11.0 - x) * WALK, "t": t})
shot("explore", 4, 1, s_explore)

# 5. RUN: the player sprints straight at the camera, him charging behind
def s_run(i, k):
    t = i / FPS
    z = 14.0 - 13.5 * t                                              # (the camera backs off ahead of them, inside the hall)
    ph = (14.0 - z) / 6.5 * TAU
    hz = z + 9.0 - 1.5 * k                                           # (he gains a little)
    cam = [2.0, U + 5.2, z - 9.0 - 2.0 * k]
    return ({"shot": "uphall", "cam": {"pos": [cam[0] + 0.15 * math.sin(i * 1.3), cam[1] + 0.1 * math.sin(i * 2.1), cam[2]], "look": [2.0, U + 4.6, z + 4], "fov": 58},
             "flash": {"i": 4.0, "pos": [cam[0], cam[1] + 1.5, cam[2] - 1.0], "target": [2.0, U + 4.0, z + 6], "angle": 0.6},
             "ambient": 0.06, "exposure": 2.1, "bg": 0x020203, "glow": 9,
             "av": [player(0, [2.0, U, z], 0.0, ph, run=True, pose=dict(gait(ph, True), neckY=0.0))]},
            {"pos": [2.0, U, hz], "yaw": 0.0, "gait": "Chase", "phase": (14.0 - hz) * RUN, "t": t})
shot("run", 5, 1, s_run)

# 6. him running at you (first person, the flashlight shaking)
def s_pov(i, k):
    z = 16.0 + (-17.0 - 16.0) * k
    cam = [2.0 + 0.25 * math.sin(i * 1.7), U + 4.6 + 0.2 * math.sin(i * 2.3), -22.0]
    return ({"shot": "uphall", "cam": {"pos": cam, "look": [2.0, U + 4.2, 10.0], "fov": 62, "roll": 0.05 * math.sin(i * 0.9)},
             "flash": {"i": 18.0, "pos": [cam[0] + 0.6, cam[1] - 0.6, cam[2]], "target": [2.0 + 1.5 * math.sin(i * 1.3), U + 4.0, z], "angle": 0.36},
             "ambient": 0.01, "exposure": 1.7, "bg": 0x020203, "glow": 8},
            {"pos": [2.0, U, z], "yaw": 0.0, "gait": "Chase", "phase": (16.0 - z) * RUN, "t": i / 30})
shot("pov", 6, 1, s_pov)

# 7. hiding: through the gap in the closet door, he walks in and stops right outside
CLOSET_CAM = [8.95, U + 6.2, -6.0]
def s_hide(i, k):
    walk = ease(min(1.0, k / 0.65))
    p = lerp([4.2, U, 4.0], [4.2, U, -6.0], walk)
    turn = ease((k - 0.55) / 0.25)
    yaw = facing(p, [4.2, 0, -20]) * (1 - turn) + facing([4.2, 0, -6.0], CLOSET_CAM) * turn
    return ({"shot": "closet", "cam": {"pos": CLOSET_CAM, "look": [-2.0, U + 6.0, -6.0], "fov": 58},
             "ambient": 0.05, "exposure": 2.5, "bg": 0x010102, "glow": 5},
            {"pos": p, "yaw": yaw, "gait": "Walk" if walk < 1 else "Stare", "phase": (4.0 - p[2]) * WALK, "t": i / 30})
shot("hide", 7, 1, s_hide)

# 8a. a friend zip-tied in the boiler room
TIED = [-37.0, -13.0, 19.0]
TIED_POSE = {"rShoulder": [-0.5, 0, 0.35], "lShoulder": [-0.5, 0, -0.35], "rElbow": 0.6, "lElbow": 0.6, "neckX": 0.45}
def s_tied(i, k):
    t = i / FPS
    pose = dict(TIED_POSE, neckX=0.45 - 0.3 * ease(k), neckY=0.15 * math.sin(t * 3))
    return ({"shot": "boiler", "cam": {"pos": lerp([-26.5, -7.2, 15.5], [-27.6, -7.4, 16.0], k), "look": [-37.0, -9.4, 19.0], "fov": 52},
             "ambient": 0.03, "exposure": 1.6, "bg": 0x020203,
             "av": [{"i": 3, "pos": [TIED[0], TIED[1] + AV, TIED[2]], "yaw": -math.pi / 2, "pose": pose}]}, None)
shot("tied", 8, 0.5, s_tied)

# 8b. ...and another one runs in and cuts them free
def s_free(i, k):
    t = i / FPS
    run = min(1.0, k / 0.55)
    p = lerp([-30.0, -13.0, 26.0], [-35.2, -13.0, 20.2], ease(run))
    ph = run * 3 * TAU
    if run >= 1:
        pose = {"rShoulder": [1.2, 0, -0.3], "lShoulder": [1.0, 0, 0.3], "rElbow": 0.9, "lElbow": 0.9, "waist": -0.35, "neckX": 0.3,
                "lHip": 0.4, "rHip": 0.4, "lKnee": -0.6, "rKnee": -0.6}
    else:
        pose = gait(ph, True)
    freed = k > 0.8
    tied_pose = dict(TIED_POSE, neckX=0.0, neckY=0.4) if not freed else {"neckY": 0.5, "rShoulder": [0.3, 0, 0.1], "lShoulder": [0.3, 0, -0.1]}
    return ({"shot": "boiler", "cam": {"pos": [-27.6, -7.4, 16.0], "look": [-35.5, -9.4, 20.0], "fov": 54},
             "ambient": 0.03, "exposure": 1.6, "bg": 0x020203,
             "av": [{"i": 3, "pos": [TIED[0], TIED[1] + AV, TIED[2]], "yaw": -math.pi / 2, "pose": tied_pose},
                    {"i": 1, "pos": [p[0], p[1] + AV - (0.35 if run >= 1 else 0), p[2]], "yaw": facing(p, [-37.0, 0, 19.0]), "pose": pose}]}, None)
shot("free", 8.5, 0.5, s_free)

# 9. the secret ending: the four of them tied to the dinner table under the house, him at the head
SEATS = [([-31, B, 20.4], [0, 0, -1]), ([-23, B, 20.4], [0, 0, -1]), ([-31, B, 13.6], [0, 0, 1]), ([-23, B, 13.6], [0, 0, 1])]
HEAD = [-35.2, B, 17.0]
def s_dinner(i, k):
    av = []
    for j, (p, d) in enumerate(SEATS):
        av.append({"i": j, "pos": [p[0] - d[0] * 0.15, B + 2.3, p[2] - d[2] * 0.15], "yaw": facing(p, [p[0] + d[0], 0, p[2] + d[2]]),
                   "pose": {"lHip": 1.5, "rHip": 1.5, "lKnee": -1.45, "rKnee": -1.45, "rShoulder": [-0.55, 0, 0.3], "lShoulder": [-0.55, 0, -0.3],
                            "rElbow": 0.7, "lElbow": 0.7, "neckX": 0.15 if j == 1 else 0.42, "neckY": 0.2 * math.sin(i / 9 + j)}})
    return ({"shot": "dining", "cam": {"pos": lerp([-16.9, B + 7.8, 17.0], [-18.2, B + 7.2, 17.0], ease(k)), "look": [-33.0, B + 3.6, 17.0], "fov": 56},
             "lamps": 0.55, "ambient": 0.03, "exposure": 1.55, "bg": 0x020203, "glow": 3, "av": av},
            {"pos": [HEAD[0] - 1.2, B, HEAD[2]], "yaw": facing(HEAD, [-27, 0, 17]), "gait": "Stare", "t": i / 30, "neck": [0.12, 0.0, 0.15]})
shot("dinner", 9, 1, s_dinner)

# 10. out of the front door and off the porch, all four, running at the camera
def s_escape(i, k):
    t = i / FPS
    av = []
    for j, (x, delay) in enumerate(((2.0, 0.0), (0.2, 0.18), (3.8, 0.32), (1.0, 0.5))):
        tt = max(0.0, t - delay)
        z = -27.5 - 15.0 * tt
        ph = tt * 17.0 / 6.5 * TAU
        av.append(player(j, [x, G, max(z, -38.0)], facing([x, 0, z], [x, 0, z - 10]), ph, run=True))
    return ({"shot": "porch", "cam": {"pos": lerp([2.0, 5.2, -45.0], [2.0, 5.4, -47.0], k), "look": [2.0, 5.0, -30.0], "fov": 52},
             "lamps": 0.9, "moon": 0.3, "ambient": 0.04, "exposure": 1.6, "bg": 0x04060c, "fog": [40, 200], "av": av}, None)
shot("escape", 10, 1, s_escape)

# 11-13. survived: the four of them on the lawn, the police lights washing over the house (the end card too)
def s_survive(i, k):
    t = i / FPS
    av = []
    for j, (x, z) in enumerate(((-1.5, -46.0), (1.0, -47.0), (3.6, -46.4), (6.0, -47.2))):
        p = [x, 0.0, z]
        av.append({"i": j, "pos": [x, AV + 0.05, z], "yaw": facing(p, [2, 0, -30]) + 0.25 * math.sin(t * 0.8 + j), "pose": idle(j, t)})
    sh = "police_r" if (i // 8) % 2 == 0 else "police_b"
    return ({"shot": sh, "cam": {"pos": lerp([12.0, 5.6, -70.0], [9.0, 6.2, -65.0], ease(k)), "look": [2.0, 6.5, -36.0], "fov": 48},
             "lamps": 0.9, "moon": 0.3, "ambient": 0.05, "exposure": 1.6, "bg": 0x04060c, "fog": [40, 200], "av": av}, None)
shot("survive", 11, 3, s_survive)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": AVS, "extras": []}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", at(14), "frames", round(at(14) / FPS, 2), "s;", "preview" if PREVIEW else "full")
