# Reel 21 — "YOU CAN'T PLAY ALONE #10": bedtime. Brushing your teeth upstairs, the lights go, something
# comes up the stairs, you hide in the hall closet, and he stops right outside. All-new shots rendered
# from the built game (film2.mjs, world_b.json), each the exact length of #2's clip in that slot so #2's
# music lands on the same cuts. python3 scene.py [preview]. Writes spec.json, frames_in.json, shots.json.
import json, math, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
TAU = math.pi * 2

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
WALK = TAU / 5.2
RUN = TAU / 7.5
U = 15.0                              # upstairs floor top
AV = 3.0                              # an avatar's origin above its feet

DOORWAY = {"near": [12, 1], "r": 2.4}                     # the bathroom door, open
CLOSET = []
SHOTS = {
    "bath": {"center": [24, 20, 0], "radius": 34, "lampRadius": 0, "maxLamps": 0, "hide": [DOORWAY],
             "lights": [{"p": [19, 27, -1], "col": "#ffcf96", "b": 3.2, "r": 22, "decay": 1.2},       # the bathroom light
                        {"p": [17.5, 23.5, -3.4], "col": "#ffe2b8", "b": 1.4, "r": 7},                 # the vanity bulbs
                        {"p": [8, 19, 1], "col": "#2c3d6e", "b": 1.4, "r": 12}]},                       # the dark hall
    "bathdark": {"center": [24, 20, 0], "radius": 34, "lampRadius": 0, "maxLamps": 0, "hide": [DOORWAY],
                 "lights": [{"p": [43, 22, 1], "col": "#7f97cf", "b": 2.4, "r": 26, "decay": 1.2},    # moonlight through the window
                            {"p": [20, 24, 0], "col": "#5a6fa8", "b": 1.4, "r": 14},
                            {"p": [8, 19, 1], "col": "#2c3d6e", "b": 1.2, "r": 12},
                            {"p": [15, 21.5, 1], "col": "#8fa4d8", "b": 0.6, "r": 8}]},
    "hall": {"center": [3, 21, 0], "radius": 40, "lampRadius": 0, "maxLamps": 0,
             "lights": [{"p": [11.6, 15.8, 1], "col": "#ffcf96", "b": 3.0, "r": 7, "decay": 1.4},      # light under the bathroom door
                        {"p": [3, 22, -24], "col": "#3d5287", "b": 2.6, "r": 26},
                        {"p": [3, 22, -4], "col": "#3d5287", "b": 1.8, "r": 18},
                        {"p": [3, 21, 16], "col": "#2c3d6e", "b": 1.2, "r": 16}]},
    "stairs": {"center": [-5, 10, 4], "radius": 34, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [-4, 22, 24], "col": "#33467a", "b": 1.4, "r": 18}]},
    "closet": {"center": [4, 20, -6], "radius": 30, "lampRadius": 0, "maxLamps": 0, "hide": CLOSET,
               "lights": [{"p": [0, 23, -6], "col": "#6a80bc", "b": 6.0, "r": 22},                      # moonlight in the hall
                          {"p": [4, 21, -16], "col": "#3d5287", "b": 2.0, "r": 16},
                          {"p": [4, 21, 4], "col": "#3d5287", "b": 1.6, "r": 14}]},
    "chase": {"center": [2, 21, -4], "radius": 44, "lampRadius": 0, "maxLamps": 0,
              "lights": [{"p": [2, 23, 18], "col": "#2c3d6e", "b": 1.2, "r": 24}]},
}
KID = {"hoodie": "#2f7de0", "hoodieDark": "#215ca8", "pants": "#2a2a33", "hair": "#e0b25a"}
SINK = [17.5, U + AV, -2.7]
AVS = [{"pos": SINK, "yaw": facing(SINK, [17.5, 0, -10]),            # at the sink, facing the mirror, brushing
        "pose": {"rShoulder": [1.5, 0, -0.3], "rElbow": 1.7, "neckX": 0.12}, "colors": KID}]
# the closet door's edges, right in front of the camera: a narrow slit to look through
EXTRAS = [{"shape": "box", "pos": [8.35, U + 5, -7.23], "s": [0.12, 12, 2.3], "col": [38, 30, 24], "rough": 0.9},
          {"shape": "box", "pos": [8.35, U + 5, -4.77], "s": [0.12, 12, 2.3], "col": [38, 30, 24], "rough": 0.9}]
# (and a toothbrush)
EXTRAS.append({"shape": "box", "pos": [17.0, U + 6.35, -3.75], "s": [0.12, 0.12, 0.9], "col": [90, 200, 220]})

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

DOOR_AT = [12.9, U, 1.0]
# 1. (hook, also the end card) brushing your teeth at the sink... and in the doorway behind you, him
def s_hook(i, k):
    return ({"shot": "bath", "cam": {"pos": lerp([31.5, 21.6, -0.4], [29.5, 21.4, -0.8], ease(k)), "look": [15.0, 19.8, -1.0], "fov": 50},
             "ambient": 0.06, "exposure": 1.85, "bg": 0x020203, "glow": 6},
            {"pos": DOOR_AT, "yaw": facing(DOOR_AT, [17.5, 0, -2.7]), "gait": "Stare", "t": i / 30, "neck": [0.1, 0.0, 0.25]})
shot("hook", 105, s_hook)

# 2. (case file, slow) the dark upstairs hall, light under the bathroom door
def s_hall(i, k):
    return ({"shot": "hall", "cam": {"pos": lerp([2.0, 20.4, -20.0], [3.0, 20.2, -12.0], ease(k)), "look": [11.5, 17.5, 1.0], "fov": 46},
             "ambient": 0.06, "exposure": 2.3, "bg": 0x020203}, None)
shot("hall", 80, s_hall)

# 3. at the sink, brushing (warm, cozy), from behind the shoulder
def s_brush(i, k):
    return ({"shot": "bath", "cam": {"pos": lerp([30.0, 21.4, -1.0], [28.4, 21.3, -1.4], ease(k)), "look": [16.5, 20.6, -2.6], "fov": 40},
             "ambient": 0.08, "exposure": 1.3, "bg": 0x020203}, None)
shot("brush", 72, s_brush)

# 4. the same, and the lights go (a flicker, then the dark and a flash of lightning)
def s_out(i, k):
    on = i < 10 and (i * 7919) % 5 < 3
    sh = "bath" if on else "bathdark"
    return ({"shot": sh, "cam": {"pos": [28.4, 21.3, -1.4], "look": [16.5, 20.6, -2.6], "fov": 40},
             "ambient": 0.08 if on else 0.02, "exposure": 1.3 if on else 1.9, "bg": 0x020203,
             "lightning": 0.8 if 18 <= i <= 20 else 0}, None)
shot("out", 33, s_out)

# 5. the stairs from below: a flashlight finds him at the top
def s_stairs(i, k):
    cam = [-4.6, 5.6, -12.2]
    sweep = ease(min(1.0, k / 0.55))
    tgt = lerp([-7.5, 10.0, 6.0], [-5.0, 19.5, 19.5], sweep)
    return ({"shot": "stairs", "cam": {"pos": cam, "look": lerp([-5, 13, 10], [-5, 17.5, 18], ease(k)), "fov": 46},
             "flash": {"i": 16.0, "pos": [cam[0] + 0.7, cam[1] - 0.7, cam[2]], "target": tgt, "angle": 0.28},
             "ambient": 0.015, "exposure": 1.7, "bg": 0x020203, "glow": 8},
            {"pos": [-5.0, U, 19.6], "yaw": 0.0, "gait": "Stare", "t": i / 30, "duck": 0.25, "neck": [0.3, 0.0, 0.25 if k > 0.7 else 0.0]})
shot("stairs", 90, s_stairs)

# the closet: looking out through the gap in the door, across the dark hall
CLOSET_CAM = [8.95, U + 6.2, -6.0]
def closet_frame(i, extra=None):
    fr = {"shot": "closet", "cam": {"pos": [CLOSET_CAM[0], CLOSET_CAM[1] + 0.03 * math.sin(i * 0.31), CLOSET_CAM[2]], "look": [-2.0, U + 6.0, -6.0], "fov": 58},
          "ambient": 0.05, "exposure": 2.5, "bg": 0x010102, "glow": 4}
    if extra: fr.update(extra)
    return fr

# 6. hiding: the hall through the slit, empty
def s_hide(i, k):
    return (closet_frame(i), None)
shot("hide", 60, s_hide)

# 7. he walks in from the side and stops right outside, facing the door
OUTSIDE = [4.2, U, -6.0]
def s_stop(i, k):
    walk = ease(min(1.0, k / 0.7))
    p = lerp([4.2, U, 4.0], OUTSIDE, walk)
    turn = ease((k - 0.6) / 0.25)
    yaw = facing(p, [4.2, 0, -20]) * (1 - turn) + facing(OUTSIDE, CLOSET_CAM) * turn
    return (closet_frame(i), {"pos": p, "yaw": yaw, "gait": "Walk" if walk < 1 else "Stare", "phase": (4.0 - p[2]) * WALK, "t": i / 30})
shot("stop", 60, s_stop)

# 8. don't breathe: he leans in to the gap, his head tilting
def s_lean(i, k):
    p = lerp(OUTSIDE, [5.3, U, -6.0], ease(k))
    return (closet_frame(i, {"glow": 7}), {"pos": p, "yaw": facing(p, CLOSET_CAM), "gait": "Stare", "t": i / 30, "duck": 0.25 * ease(k), "neck": [0.25, 0.0, 0.45 * ease(k)]})
shot("lean", 60, s_lean)

# 9. he turns away... and snaps back to the gap (the flash at 2.15 s)
def s_knew(i, k):
    away = ease(min(1.0, k / 0.4))
    snap = ease((k - 0.84) / 0.06)
    p = [5.2, U, -6.0]
    yaw_away = facing(p, [-5, 0, -6])
    yaw = facing(p, CLOSET_CAM) * (1 - away) + yaw_away * away
    if snap > 0:
        yaw = yaw_away * (1 - snap) + facing(p, CLOSET_CAM) * snap
    return (closet_frame(i, {"glow": 4 + 6 * snap}), {"pos": p, "yaw": yaw, "gait": "Stare", "t": i / 30, "duck": 0.3 * snap, "neck": [0.3 * snap, 0.0, 0.2 * (1 - snap)]})
shot("knew", 75, s_knew)

# 10. RUN: down the upstairs hall, straight at you, the flashlight shaking
def s_run(i, k):
    z = 16.0 + (-17.0 - 16.0) * k
    cam = [2.0 + 0.25 * math.sin(i * 1.7), U + 4.6 + 0.2 * math.sin(i * 2.3), -22.0]
    return ({"shot": "chase", "cam": {"pos": cam, "look": [2.0, U + 4.2, 10.0], "fov": 62, "roll": 0.05 * math.sin(i * 0.9)},
             "flash": {"i": 18.0, "pos": [cam[0] + 0.6, cam[1] - 0.6, cam[2]], "target": [2.0 + 1.5 * math.sin(i * 1.3), U + 4.0, z], "angle": 0.36},
             "ambient": 0.01, "exposure": 1.7, "bg": 0x020203, "glow": 8},
            {"pos": [2.0, U, z], "yaw": 0.0, "gait": "Chase", "phase": (16.0 - z) * RUN, "t": i / 30})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": AVS, "extras": EXTRAS}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / 30, 1), "s;", "preview" if PREVIEW else "full")
