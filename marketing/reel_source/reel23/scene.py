# Reel 23 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS": the owner's reference (a 19 s reel of slow
# first-person gameplay under a game card, one jumpscare) rebuilt from our game. First person only, slow
# handheld moves, dark; cuts on audio.py's bars (112 BPM): the front door at night (the hook), the dark
# living room in a flashlight, the flashlight finding him at the top of the stairs, THE SCARE (he charges
# you down the hall), hiding in the closet as he leans in, him in the bathroom doorway behind you, a
# glitch, the moonlit bedroom, the garage under a cold tube light. python3 scene.py [preview]
import json, math, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
BAR = 60 / 112 * 4 * FPS                 # 64.29 frames
def at(bars): return round(bars * BAR)

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
G, U = 1.0, 15.0
EYE = 5.6                                # first-person eye height above the floor
def hand(i, amt=1.0):                    # a slow handheld drift
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]

PORCH_LIGHT = {"p": [2, 10.2, -32.2], "col": "#ffb066", "b": 4.5, "r": 18, "decay": 1.3}
SHOTS = {
    "porch": {"center": [2, 6, -34], "radius": 44, "lampRadius": 0, "maxLamps": 0,
              "lights": [PORCH_LIGHT, {"p": [-2.6, 8.6, -30.6], "col": "#ffb066", "b": 2.4, "r": 9}, {"p": [6.6, 8.6, -30.6], "col": "#ffb066", "b": 2.4, "r": 9},
                         {"p": [-30, 30, -90], "col": "#46557a", "b": 0.8, "r": 120, "decay": 0.5}]},
    "living": {"center": [-22, 6, -14], "radius": 40, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [-34, 8.5, -35], "col": "#3d4f7a", "b": 1.6, "r": 14}]},
    "bedroom": {"center": [-24, 20, -14], "radius": 30, "lampRadius": 0, "maxLamps": 0,
                "lights": [{"p": [-24, 22, -29], "col": "#8fa8e0", "b": 5.0, "r": 22}, {"p": [-38, 22, -22], "col": "#6a84c4", "b": 3.0, "r": 18}, {"p": [-20, 22, -6], "col": "#2c3d6e", "b": 1.4, "r": 14}]},
    "stairs": {"center": [-5, 10, 4], "radius": 34, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [-4, 22, 24], "col": "#33467a", "b": 1.4, "r": 18}]},
    "chase": {"center": [2, 21, -4], "radius": 44, "lampRadius": 0, "maxLamps": 0,
              "lights": [{"p": [2, 23, 18], "col": "#2c3d6e", "b": 1.2, "r": 24}]},
    "closet": {"center": [4, 20, -6], "radius": 30, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [0, 23, -6], "col": "#6a80bc", "b": 6.0, "r": 22},
                          {"p": [4, 21, -16], "col": "#3d5287", "b": 2.0, "r": 16},
                          {"p": [4, 21, 4], "col": "#3d5287", "b": 1.6, "r": 14}]},
    "bathdark": {"center": [24, 20, 0], "radius": 34, "lampRadius": 0, "maxLamps": 0, "hide": [{"near": [12, 1], "r": 2.4}],
                 "lights": [{"p": [43, 22, 1], "col": "#7f97cf", "b": 2.4, "r": 26, "decay": 1.2},
                            {"p": [20, 24, 0], "col": "#5a6fa8", "b": 1.4, "r": 14},
                            {"p": [16.5, 22, 1], "col": "#9fb4e8", "b": 2.2, "r": 8, "decay": 1.3},
                            {"p": [8, 19, 1], "col": "#2c3d6e", "b": 1.2, "r": 12}]},
    "garage": {"center": [52, 7, -12], "radius": 34, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [52, 13.5, -14], "col": "#d8ffe8", "b": 4.0, "r": 26, "decay": 1.1}, {"p": [52, 13.5, 0], "col": "#c8f0d8", "b": 2.0, "r": 18}]},
}
frames, crs, shots = [], [], []
def shot(name, b0, bars, fn):
    f0, f1 = at(b0), at(b0 + bars)
    n = f1 - f0
    shots.append({"name": name, "start": f0, "n": n})
    idx = [0, n // 2, n - 1] if PREVIEW else range(n)
    for i in idx:
        k = i / max(1, n - 1)
        fr, cr = fn(i, k)
        fr["f"] = f0 + i
        fr["creature"] = cr is not None
        frames.append(fr)
        if cr: cr["f"] = f0 + i; crs.append(cr)

DARK = {"ambient": 0.02, "bg": 0x010102}

# 1. (the hook) the front door at night, from the walk: a slow walk up to it
def s_porch(i, k):
    cam = add(lerp([2.0, EYE + 0.2, -52.0], [2.0, EYE + 0.9, -43.0], ease(k)), hand(i))
    return (dict(DARK, shot="porch", cam={"pos": cam, "look": [2.0, 6.6, -30.0], "fov": 52}, exposure=1.5, moon=0.15, fog=[30, 120], bg=0x02030a), None)
shot("porch", 0, 2, s_porch)

# 2. the dark living room, a flashlight sweeping slowly across it
def s_living(i, k):
    cam = add([-12.0, G + EYE, -6.0], hand(i))
    tgt = lerp([-30.0, 3.0, -2.0], [-24.0, 3.5, -24.0], ease(k))
    return (dict(DARK, shot="living", cam={"pos": cam, "look": lerp([-28, 4.5, -4], [-24, 4.5, -22], ease(k)), "fov": 62},
                 flash={"i": 14.0, "pos": [cam[0] + 0.5, cam[1] - 0.6, cam[2]], "target": tgt, "angle": 0.38}, exposure=1.8), None)
shot("living", 2, 1, s_living)

# 3. the stairs from below: the flashlight finds him at the top
def s_stairs(i, k):
    cam = add([-4.6, 5.6, -12.2], hand(i, 0.5))
    sweep = ease(min(1.0, k / 0.5))
    tgt = lerp([-7.5, 10.0, 6.0], [-5.0, 19.5, 19.5], sweep)
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": lerp([-5, 13, 10], [-5, 17.5, 18], ease(k)), "fov": 46},
                 flash={"i": 16.0, "pos": [cam[0] + 0.7, cam[1] - 0.7, cam[2]], "target": tgt, "angle": 0.28},
                 ambient=0.015, exposure=1.7, glow=8),
            {"pos": [-5.0, U, 19.6], "yaw": 0.0, "gait": "Stare", "t": i / 30, "duck": 0.25, "neck": [0.3, 0.0, 0.25 if k > 0.7 else 0.0]})
shot("stairs", 3, 1, s_stairs)

# 4. THE SCARE: he charges down the upstairs hall, right into you
RUN = math.tau / 7.5
def s_scare(i, k):
    z = -11.0 + (-17.0 + 11.0) * k
    cam = [2.0 + 0.3 * math.sin(i * 1.7), U + 4.8 + 0.25 * math.sin(i * 2.3), -22.0]
    return (dict(DARK, shot="chase", cam={"pos": cam, "look": [2.0, U + 5.6 + 3.6 * ease(k), 10.0], "fov": 64, "roll": 0.06 * math.sin(i * 0.9)},
                 flash={"i": 20.0, "pos": [cam[0] + 0.6, cam[1] - 0.6, cam[2]], "target": [2.0, U + 7.5, z], "angle": 0.4},
                 ambient=0.01, exposure=1.8, glow=10),
            {"pos": [2.0, U, z], "yaw": 0.0, "gait": "Chase", "phase": (16.0 - z) * RUN, "t": i / 30})
shot("scare", 4, 0.3, s_scare)

# 5. hiding in the hall closet: he walks in, stops right outside the gap, and leans in
CLOSET_CAM = [8.95, U + 6.2, -6.0]
OUTSIDE = [4.2, U, -6.0]
def s_closet(i, k):
    fr = dict(DARK, shot="closet", cam={"pos": [CLOSET_CAM[0], CLOSET_CAM[1] + 0.03 * math.sin(i * 0.31), CLOSET_CAM[2]], "look": [-2.0, U + 6.0, -6.0], "fov": 58},
              ambient=0.05, exposure=2.5, glow=4)
    walk = ease(min(1.0, k / 0.42))
    p = lerp([4.2, U, 3.0], OUTSIDE, walk)
    turn = ease((k - 0.36) / 0.16)
    yaw = facing(p, [4.2, 0, -20]) * (1 - turn) + facing(OUTSIDE, CLOSET_CAM) * turn
    lean = ease((k - 0.58) / 0.42)
    if lean > 0:
        p = lerp(OUTSIDE, [5.3, U, -6.0], lean)
        yaw = facing(p, CLOSET_CAM)
        fr["glow"] = 4 + 3 * lean
    return (fr, {"pos": p, "yaw": yaw, "gait": "Walk" if walk < 1 else "Stare", "phase": (3.0 - p[2]) * (math.tau / 5.2), "t": i / 30,
                 "duck": 0.25 * lean, "neck": [0.25 * lean, 0.0, 0.45 * lean]})
shot("closet", 4.3, 1.2, s_closet)

# 6. the bathroom in the moonlight... and him, standing in the doorway behind you
DOOR_AT = [12.9, U, 1.0]
def s_bath(i, k):
    cam = add(lerp([31.5, 21.6, -0.4], [29.5, 21.4, -0.8], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="bathdark", cam={"pos": cam, "look": [15.0, 19.8, -1.0], "fov": 50}, ambient=0.03, exposure=2.1, glow=6),
            {"pos": DOOR_AT, "yaw": facing(DOOR_AT, [30, 0, -0.6]), "gait": "Stare", "t": i / 30, "neck": [0.1, 0.0, 0.25]})
shot("bath", 5.5, 1, s_bath)

# 8. (the glitch: comp only, over the end of the boiler shot) — 9. the moonlit bedroom, a slow pan
def s_bed(i, k):
    cam = add([-12.0, U + EYE, -10.0], hand(i, 0.6))
    return (dict(DARK, shot="bedroom", cam={"pos": cam, "look": lerp([-30.0, U + 4.0, -28.0], [-36.0, U + 4.0, -14.0], ease(k)), "fov": 60}, exposure=2.6), None)
shot("bedroom", 6.5, 1, s_bed)

# 10. the garage under a cold tube light
def s_garage(i, k):
    cam = add(lerp([43.0, G + EYE, -26.0], [44.5, G + EYE, -22.0], ease(k)), hand(i, 0.6))
    return (dict(DARK, shot="garage", cam={"pos": cam, "look": [56.0, 5.0, -2.0], "fov": 60}, exposure=1.6), None)
shot("garage", 7.5, 0.5, s_garage)

# 11. (the end card is black: comp only, from bar 8) — the garage keeps running under it, faded out
shot("tail", 8, 1, lambda i, k: (dict(DARK, shot="garage", cam={"pos": [44.5, G + EYE, -22.0], "look": [56.0, 5.0, -2.0], "fov": 60}, exposure=1.6), None))

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
EXTRAS = [{"shape": "box", "pos": [8.35, U + 5, -7.23], "s": [0.12, 12, 2.3], "col": [38, 30, 24], "rough": 0.9},   # the closet door edges: a slit to look through
          {"shape": "box", "pos": [8.35, U + 5, -4.77], "s": [0.12, 12, 2.3], "col": [38, 30, 24], "rough": 0.9}]
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": EXTRAS}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", at(9), "frames", round(at(9) / FPS, 2), "s;", "preview" if PREVIEW else "full")
