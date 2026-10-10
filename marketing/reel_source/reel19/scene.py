# Reel 19 — "YOU CAN'T PLAY ALONE #8": the secret ending, under the house (World/Burrow). All-new shots
# rendered from the built game (film2.mjs, world_b.json), each the exact length of #2's clip in that
# slot so #2's music lands on the same cuts. python3 scene.py [preview]  (3 frames a shot, 360x640)
# Writes spec.json, frames_in.json (his pose per frame) and shots.json.
import json, math, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
TAU = math.pi * 2
Y = -30.0                                   # the burrow floor

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
WALK = TAU / 5.2
RUN = TAU / 7.5

CANDLES = [{"p": [-32.5, Y + 5.6, 17], "col": "#ffb066", "b": 2.0, "r": 9, "decay": 1.5},
           {"p": [-27.0, Y + 5.6, 18.7], "col": "#ffb066", "b": 2.0, "r": 9, "decay": 1.5},
           {"p": [-21.5, Y + 5.6, 17], "col": "#ffb066", "b": 2.0, "r": 9, "decay": 1.5}]
SHOTS = {
    "dining": {"center": [-27, Y + 4, 17], "radius": 34, "lampRadius": 22, "maxLamps": 4,
               "lights": CANDLES + [{"p": [-19, Y + 4, 25.5], "col": "#7f9cff", "b": 1.4, "r": 8}]},       # the camp stove
    "photos": {"center": [-27, Y + 4, 24], "radius": 26, "lampRadius": 18, "maxLamps": 3,
               "lights": CANDLES + [{"p": [-27, Y + 6, 23], "col": "#ffb066", "b": 1.6, "r": 10}]},
    "pantry": {"center": [22, Y + 4, 16], "radius": 22, "lampRadius": 16, "maxLamps": 3, "lights": []},
    "tunnel": {"center": [4, Y + 4, 30], "radius": 30, "lampRadius": 22, "maxLamps": 5, "lights": []},
}
# four friends tied to the dining chairs: arms behind the back, heads down (one looking up)
SEATS = [([-31, Y, 20.4], [0, 0, -1]), ([-23, Y, 20.4], [0, 0, -1]), ([-31, Y, 13.6], [0, 0, 1]), ([-23, Y, 13.6], [0, 0, 1])]
COLS = [{"hoodie": "#2f7de0", "hoodieDark": "#215ca8", "pants": "#2a2a33", "hair": "#e0b25a"},
        {"hoodie": "#d6363c", "hoodieDark": "#a8262d", "pants": "#2b3b5c", "hair": "#3b2416"},
        {"hoodie": "#3fae5a", "hoodieDark": "#2c8043", "pants": "#3a3a40", "hair": "#141012", "skin": "#8d5a3b"},
        {"hoodie": "#f0a020", "hoodieDark": "#c07a10", "pants": "#2a2a33", "hair": "#6b4423"}]
AVS = []
for i, (p, d) in enumerate(SEATS):
    pos = [p[0] - d[0] * 0.15, Y + 2.3, p[2] - d[2] * 0.15]
    tgt = [p[0] + d[0], 0, p[2] + d[2]]
    AVS.append({"pos": pos, "yaw": facing(p, tgt), "face": "scared",
                "pose": {"lHip": 1.5, "rHip": 1.5, "lKnee": -1.45, "rKnee": -1.45,
                         "rShoulder": [-0.55, 0, 0.3], "lShoulder": [-0.55, 0, -0.3], "rElbow": 0.7, "lElbow": 0.7,
                         "neckX": 0.15 if i == 1 else 0.42, "neckY": 0.2 if i == 3 else 0.0},
                "colors": COLS[i]})

HEAD = [-35.2, Y, 17.0]                     # his chair at the head of the table
STOVE = [-19.5, Y, 22.6]
LADDER = [-34.0, Y, 25.4]

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

DIN = {"lamps": 0.55, "ambient": 0.03, "exposure": 1.55, "bg": 0x020203, "glow": 3}

# 1. (hook, also the end card) the dinner, wide: four of them tied at the table, him standing at the head
def s_wide(i, k):
    e = ease(k)
    return (dict(DIN, shot="dining", cam={"pos": lerp([-16.9, Y + 7.8, 17.0], [-17.6, Y + 7.4, 17.0], e), "look": [-33.0, Y + 3.6, 17.0], "fov": 56}),
            {"pos": [HEAD[0] - 1.2, Y, HEAD[2]], "yaw": facing(HEAD, [-27, 0, 17]), "gait": "Stare", "t": i / 30, "neck": [0.12, 0.0, 0.15 * math.sin(i / 25)]})
shot("wide", 105, s_wide)

# 2. (case file, slow) the photo wall above the table: nineteen days of them
def s_photos(i, k):
    return (dict(DIN, shot="photos", exposure=1.75, cam={"pos": lerp([-19.5, Y + 5.4, 21.5], [-31.5, Y + 5.6, 21.8], ease(k)), "look": lerp([-23, Y + 5.2, 27.5], [-35, Y + 5.4, 27.5], k), "fov": 52}), None)
shot("photos", 80, s_photos)

# 3. down the ladder: what you see coming down into the burrow
def s_ladder(i, k):
    e = ease(k)
    return (dict(DIN, shot="dining", cam={"pos": lerp([-33.6, Y + 9.2, 25.4], [-33.4, Y + 6.4, 24.6], e), "look": lerp([-28, Y + 1.5, 18], [-27, Y + 3, 17], e), "fov": 70, "roll": 0.06 * (1 - e)}), None)
shot("ladder", 33, s_ladder)

# 4. along the table at plate height, candles going by, to him at the head
def s_table(i, k):
    e = ease(k)
    return (dict(DIN, shot="dining", cam={"pos": lerp([-18.4, Y + 5.6, 15.6], [-24.5, Y + 5.4, 15.8], e), "look": [HEAD[0], Y + 6.0, HEAD[2]], "fov": 48}),
            {"pos": [HEAD[0] - 1.2, Y, HEAD[2]], "yaw": facing(HEAD, [-20, 0, 17]), "gait": "Stare", "t": i / 30, "neck": [0.2, 0.0, 0.0]})
shot("table", 90, s_table)

# 5. a place set for one of them: the plate, the glass, the friend behind it, head down
def s_place(i, k):
    return (dict(DIN, shot="dining", exposure=1.7, cam={"pos": lerp([-23.0, Y + 5.3, 15.4], [-23.0, Y + 5.1, 16.3], ease(k)), "look": [-23.0, Y + 4.3, 20.4], "fov": 44}), None)
shot("place", 60, s_place)

# 6. at the stove, his back to you... and he turns round
def s_turn(i, k):
    turn = ease((k - 0.45) / 0.3)
    yaw = facing(STOVE, [-19.5, 0, 30]) * (1 - turn) + facing(STOVE, [-24.5, 0, 16.5]) * turn
    return (dict(DIN, shot="dining", cam={"pos": lerp([-24.6, Y + 5.2, 16.2], [-24.2, Y + 5.3, 16.8], k), "look": [-19.5, Y + 6.2, 22.8], "fov": 50}),
            {"pos": STOVE, "yaw": yaw, "gait": "Search" if turn < 0.5 else "Stare", "t": i / 30, "neck": [0.1 + 0.15 * turn, 0.0, 0.0]})
shot("turn", 60, s_turn)

# 7. the note in the pantry, in a flashlight beam
NOTE = [26.0, Y + 3.05, 12.0]
def s_note(i, k):
    cam = lerp([19.6, Y + 5.6, 17.2], [23.4, Y + 5.0, 14.4], ease(k))
    return ({"shot": "pantry", "cam": {"pos": cam, "look": lerp([24, Y + 3.5, 13.5], NOTE, ease(k)), "fov": 56},
             "flash": {"i": 16.0, "pos": [cam[0] + 0.6, cam[1] - 0.6, cam[2]], "target": NOTE, "angle": 0.3},
             "lamps": 0.35, "ambient": 0.02, "exposure": 1.6, "bg": 0x020203}, None)
shot("note", 60, s_note)

# 8. he comes back down the ladder, his back to you, and at the bottom he turns his head (the flash)
def s_down(i, k):
    drop = ease(min(1.0, k / 0.7))
    y = Y + 7.5 * (1 - drop)
    look = ease((k - 0.78) / 0.12)
    yaw = facing(LADDER, [-34, 0, 30]) * (1 - look) + facing(LADDER, [-27.0, 0, 22.6]) * look
    return (dict(DIN, shot="dining", cam={"pos": [-27.0, Y + 5.6, 22.6], "look": lerp([-34, Y + 9, 25.5], [-34, Y + 6.5, 25.4], drop), "fov": 52}),
            {"pos": [LADDER[0], y, LADDER[2]], "yaw": yaw, "gait": "Stare", "t": i / 30, "neck": [0.25 * look, 0.0, 0.0]})
shot("down", 75, s_down)

# 9. RUN: down the north tunnel, straight at you, the flashlight shaking
def s_run(i, k):
    z = 38.0 + (25.5 - 38.0) * k
    cam = [4.0 + 0.25 * math.sin(i * 1.7), Y + 5.4 + 0.2 * math.sin(i * 2.3), 23.4]
    return ({"shot": "tunnel", "cam": {"pos": cam, "look": [4.0, Y + 5.2, 40.0], "fov": 62, "roll": 0.05 * math.sin(i * 0.9)},
             "flash": {"i": 18.0, "pos": [cam[0] + 0.6, cam[1] - 0.6, cam[2]], "target": [4.0 + 1.2 * math.sin(i * 1.3), Y + 4.5, z], "angle": 0.36},
             "lamps": 0.5, "ambient": 0.01, "exposure": 1.7, "bg": 0x020203, "glow": 8},
            {"pos": [4.0, Y, z], "yaw": math.pi, "gait": "Chase", "phase": (38.0 - z) * RUN, "t": i / 30, "duck": 0.3})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": AVS, "extras": []}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / 30, 1), "s;", "preview" if PREVIEW else "full")
