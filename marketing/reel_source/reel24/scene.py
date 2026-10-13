# Reel 24 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 2)": reel 23's format (slow
# first-person shots, the hook word by word, the NAME / GAMEPLAY / GENRE card, a pixelated jumpscare,
# a glitch line, a black end card) cut to #2's track: every clip has #2's length, so #2's audio.py
# lands on the same beats and hits. The story: hiding under the dining table. The house has its
# Creator Store furniture now (the world is a stage.json; film2 places the props like the game).
#   hook (105)  the kitchen in the dark, a flashlight over the table and the new chairs
#   card (120)  the den, the worn leather sofa in the TV's glow
#   72          Dad's office in a lightning flash: someone standing by the bookcases
#   33          the living room lights flicker and die
#   90          getting down under the dining table
#   60          his legs walk past the end of the table
#   60          he stops, facing the table, fingers hanging past his knees
#   60          he turns and walks away
#   75          nothing... and he drops in upside down at the edge (the scare at 22.15 s)
#   30          RUN: he charges down the upstairs hall
# python3 scene.py [preview]. Writes spec.json, frames_in.json, shots.json.
import json, math, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.6
WALK = math.tau / 5.2
RUN = math.tau / 7.5

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]

TABLE = [-15.0, G, 17.5]                 # the dining table (long along z, 13..22)
UNDER_EYE = [-15.0, G + 1.4, 13.6]       # the game's under-the-table hiding view
UNDER_LOOK = [-15.0, G + 2.0, 3.0]
COLD = "#3d4f7a"
SHOTS = {
    "kitchen": {"center": [-18, 6, 14], "radius": 40, "lampRadius": 0, "maxLamps": 0,
                "lights": [{"p": [-38, 9, 14], "col": COLD, "b": 1.6, "r": 16}, {"p": [-24, 9, 29], "col": COLD, "b": 1.2, "r": 14}]},
    "den": {"center": [24, 6, 14], "radius": 36, "lampRadius": 0, "maxLamps": 0,
            "lights": [{"p": [21.5, G + 4.5, 6.6], "col": "#9fb6ff", "b": 9.0, "r": 28, "decay": 1.0},      # the TV's glow
                       {"p": [36, 9, 26], "col": COLD, "b": 1.0, "r": 14}]},
    "office": {"center": [28, 6, -20], "radius": 34, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [26, 9, -29], "col": COLD, "b": 1.2, "r": 16}]},
    "livingOn": {"center": [-24, 6, -14], "radius": 40, "lampRadius": 40, "maxLamps": 10, "lights": []},
    "livingDark": {"center": [-24, 6, -14], "radius": 40, "lampRadius": 0, "maxLamps": 0,
                   "lights": [{"p": [-24, 9, -28], "col": "#6f86c4", "b": 4.0, "r": 24, "decay": 1.1},     # moonlight through the windows
                              {"p": [-36, 8.5, -16], "col": COLD, "b": 2.0, "r": 16}]},
    "table": {"center": [-15, 4, 12], "radius": 34, "lampRadius": 0, "maxLamps": 0,
              "lights": [{"p": [-15, 8, 4], "col": "#5d72a8", "b": 2.6, "r": 18}, {"p": [-30, 8, 8], "col": COLD, "b": 1.2, "r": 14},
                         {"p": [-15, G + 2.4, 9.5], "col": "#8ea2d8", "b": 0.9, "r": 7},
                         {"p": [-24, 9, 18], "col": "#6f86c4", "b": 2.4, "r": 16, "decay": 1.2}]},             # moonlight from the kitchen window
    "chase": {"center": [2, 21, -4], "radius": 44, "lampRadius": 0, "maxLamps": 0,
              "lights": [{"p": [2, 23, 18], "col": "#2c3d6e", "b": 1.2, "r": 24}]},
}
DARK = {"ambient": 0.02, "bg": 0x010102}
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

# 1. (hook) the kitchen in the dark: a slow push towards the table, the flashlight drifting over it
def s_hook(i, k):
    cam = add(lerp([-15.0, G + EYE, 3.6], [-15.0, G + EYE - 0.4, 8.0], ease(k)), hand(i))
    tgt = lerp([-19.4, G + 2.0, 13.0], [-11.0, G + 2.5, 21.0], ease(k))
    return (dict(DARK, shot="kitchen", cam={"pos": cam, "look": lerp([-16.5, G + 2.4, 17], [-15, G + 2.6, 19], ease(k)), "fov": 62},
                 flash={"i": 13.0, "pos": [cam[0] + 0.5, cam[1] - 0.6, cam[2]], "target": tgt, "angle": 0.36}, exposure=1.9), None)
shot("hook", 105, s_hook)

# 2. (card) the den: the leather sofa in the TV's glow
def s_den(i, k):
    cam = add(lerp([24.5, G + EYE, 7.0], [23.0, G + EYE - 0.2, 9.2], ease(k)), hand(i, 0.6))
    flick = 0.85 + 0.15 * math.sin(i * 1.7) * math.sin(i * 0.37)
    return (dict(DARK, shot="den", cam={"pos": cam, "look": [21.5, G + 2.6, 18.5], "fov": 60}, exposure=2.7 * flick), None)
shot("card", 120, s_den)

# 3. Dad's office, lit only by lightning: someone by the bookcases
HIM_OFFICE = [37.2, G, -20.6]
def s_office(i, k):
    cam = add([17.5, G + EYE, -13.5], hand(i, 0.5))
    lt = 1.0 if 18 <= i <= 21 else (0.55 if 50 <= i <= 52 else 0.0)
    return (dict(DARK, shot="office", cam={"pos": cam, "look": [34.0, G + 4.6, -21.0], "fov": 52}, exposure=1.8, lightning=lt, glow=6),
            {"pos": HIM_OFFICE, "yaw": facing(HIM_OFFICE, cam), "gait": "Stare", "t": i / 30, "neck": [0.1, 0.0, 0.25]})
shot("office", 72, s_office)

# 4. the living room: the lights flicker and die
def s_out(i, k):
    on = i < 9 and (i * 7919) % 5 < 3
    return (dict(DARK, shot="livingOn" if on else "livingDark", cam={"pos": [-12.0, G + EYE, -4.0], "look": [-26.0, G + 3.0, -20.0], "fov": 62},
                 ambient=0.08 if on else 0.03, exposure=1.3 if on else 2.4, lightning=0.7 if 16 <= i <= 18 else 0), None)
shot("out", 33, s_out)

# 5. down under the dining table
def s_down(i, k):
    a = ease(min(1.0, k / 0.8))
    cam = lerp([-15.0, G + EYE, 8.0], UNDER_EYE, a)
    look = lerp([-15.0, G + 2.4, 16.0], UNDER_LOOK, ease((k - 0.35) / 0.65))
    # (the flashlight still on while you get down, then off: you're hiding)
    beam = 1.0 - ease((k - 0.7) / 0.25)
    fl = {"i": 12.0 * beam, "pos": [cam[0] + 0.5, cam[1] - 0.5, cam[2]], "target": lerp([-15.0, G + 3.0, 16.0], [-15.0, G + 0.5, 6.0], ease(k)), "angle": 0.42}
    return (dict(DARK, shot="table", cam={"pos": add(cam, hand(i, 0.8 * (1 - a))), "look": look, "fov": 70}, exposure=2.6, flash=fl), None)
shot("down", 90, s_down)

def under(i, extra=None):
    fr = dict(DARK, shot="table", cam={"pos": [UNDER_EYE[0], UNDER_EYE[1] + 0.03 * math.sin(i * 0.31), UNDER_EYE[2]], "look": UNDER_LOOK, "fov": 70},
              exposure=2.4, glow=4)
    if extra: fr.update(extra)
    return fr

# 6. his legs walk past the end of the table, left to right
def s_past(i, k):
    x = -25.0 + 10.6 * ease(k * 1.05)
    p = [x, G, 8.6]
    walking = k < 0.95
    return (under(i), {"pos": p, "yaw": facing(p, [x + 10, G, 8.6]), "gait": "Walk" if walking else "Stare", "phase": (x + 25) * WALK, "t": i / 30})
shot("past", 60, s_past)

# 7. he stops and turns to the table: his hands hang past his knees
STOP = [-14.4, G, 8.6]
def s_stop(i, k):
    turn = ease(min(1.0, k / 0.4))
    yaw = facing(STOP, [0, G, 8.6]) * (1 - turn) + facing(STOP, UNDER_EYE) * turn
    return (under(i, {"glow": 5}), {"pos": STOP, "yaw": yaw, "gait": "Stare", "t": i / 30, "neck": [0.35 * turn, 0.0, 0.3 * turn]})
shot("stop", 60, s_stop)

# 8. he turns away and walks off, slowly
def s_away(i, k):
    w = ease((k - 0.15) / 0.85)
    p = lerp(STOP, [-14.4, G, -3.0], w)
    yaw = facing(STOP, UNDER_EYE) if k < 0.12 else facing(p, [-14.4, G, -20])
    return (under(i), {"pos": p, "yaw": yaw, "gait": "Walk" if 0.15 < k < 0.98 else "Stare", "phase": (8.6 - p[2]) * WALK, "t": i / 30})
shot("away", 60, s_away)

# 9. nothing... then he drops in, upside down, right at the edge of the table (22.15 s: frame 64)
def s_drop(i, k):
    if i < 64:
        return (under(i), None)
    d = ease((i - 64) / 3.0)
    feet_y = G + 16.0 + (G + 9.2 - (G + 16.0)) * d       # head ends level with your eyes
    p = [-15.0, feet_y, 11.0]
    return (under(i, {"glow": 10, "exposure": 2.6}), {"pos": p, "yaw": 0.0, "pitch": math.pi, "gait": "Stare", "t": i / 30,
                                                     "neck": [0.0, 0.0, 0.35 * math.sin(i * 0.9)]})
shot("drop", 75, s_drop)

# 10. RUN: he charges down the upstairs hall, the flashlight shaking
def s_run(i, k):
    z = 16.0 + (-17.0 - 16.0) * k
    cam = [2.0 + 0.25 * math.sin(i * 1.7), U + 4.6 + 0.2 * math.sin(i * 2.3), -22.0]
    return (dict(DARK, shot="chase", cam={"pos": cam, "look": [2.0, U + 4.6 + 3.0 * k, 10.0], "fov": 62, "roll": 0.05 * math.sin(i * 0.9)},
                 flash={"i": 18.0, "pos": [cam[0] + 0.6, cam[1] - 0.6, cam[2]], "target": [2.0 + 1.5 * math.sin(i * 1.3), U + 5.0, z], "angle": 0.36},
                 ambient=0.01, exposure=1.7, glow=8),
            {"pos": [2.0, U, z], "yaw": 0.0, "gait": "Chase", "phase": (16.0 - z) * RUN, "t": i / 30})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": [],
           "props": {"cache": "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
