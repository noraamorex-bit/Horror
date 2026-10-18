# Reel 31 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 9)": Parts 2-8's format on #2's track
# (every clip keeps #2's length, so the track's cuts and hits land). The boiler room: what happens
# when he catches you. Zip-tied to a pipe in the basement, your friend at the next one.
#   hook (105)  the boiler room from the doorway: the boiler's glow, your friend zip-tied to a pipe
#   card (120)  your view, tied to the pipe: the boiler, then your friend, terrified
#   72          the door opens: him in the doorway, watching, then he goes
#   33          struggle (the view shakes)
#   90          the zip tie snaps: you're up; your friend shakes their head, looking at the door
#   60          footsteps: hide behind the boiler, peek round it at the door
#   60          he comes back in and walks to your pipe
#   60          your empty pipe: he stands there, then his head turns slowly towards the boiler
#   75          nothing... and he's over the boiler at you (the scare at 22.15 s)
#   30          RUN: out the door into the basement, he comes after you
# python3 scene.py [preview]. Writes spec.json, frames_in.json, shots.json.
import json, math, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
B = -13.0                # the basement floor
AV = 3.0                 # an avatar's origin above its feet
WALK = math.tau / 5.2
RUN = math.tau / 7.5

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]

ORANGE = "#ff8a3c"
# the boiler room (World): x -40..-20, z 10..30; pipes on the west wall; the boiler at (-24.5, 14.8)
# (its burner door faces +x), the water heater at (-23.8, 26.2), the door at x = -20, z 17.6..22.4
ME = [-37.2, B, 13.0]             # zip-tied to the pipe, facing +x
FRIEND = [-37.2, B, 19.0]         # at the next pipe
EYE = [ME[0] + 0.3, B + 5.4, ME[2]]
DOORWAY = [-18.6, B, 20.0]
HIDE = [-28.4, B + 3.0, 17.9]     # crouched at the boiler's back corner, peeking round its north edge
DOOR = {"near": [-20.0, B + 4.7, 20.0], "r": 3.4, "names": ["Panel", "Inset", "Knob"], "hinge": [-20.0, 0, 17.55], "axis": "y"}
OPEN = 1.35
TIED = {"lShoulder": [-0.55, 0, 0.2], "rShoulder": [-0.55, 0, -0.2], "lElbow": -0.4, "rElbow": -0.4, "neckX": 0.15}
KID = {"hoodie": "#2f7de0", "hoodieDark": "#215ca8", "pants": "#2a2a33", "hair": "#e0b25a"}
FRIEND_YAW = facing(FRIEND, [-29.0, B, 12.0])   # (tied to the pipe, turned towards you)
AVS = [{"pos": [FRIEND[0], B + AV, FRIEND[2]], "yaw": FRIEND_YAW, "pose": TIED, "face": "scared", "colors": KID}]
def friend(pose=None):
    return [{"i": 0, "pos": [FRIEND[0], B + AV, FRIEND[2]], "yaw": FRIEND_YAW, "pose": dict(TIED, **(pose or {}))}]

LIGHTS = [{"p": [-21.4, B + 1.6, 14.8], "col": ORANGE, "b": 3.0, "r": 18, "decay": 1.2},     # the boiler's burner window
          {"p": [-33.0, B + 7.0, 19.0], "col": ORANGE, "b": 0.8, "r": 18, "decay": 1.0},     # its glow on our side of the room
          {"p": [-30.0, B + 11.6, 20.0], "col": "#ffcf95", "b": 1.5, "r": 26, "decay": 1.1}, # the bare bulb, dim
          {"p": [-30.0, B + 11.5, 20.0], "col": "#6a7ea8", "b": 0.5, "r": 18},               # a little cold light from the high windows
          {"p": [-14.0, B + 8.0, 20.0], "col": "#ffd2a0", "b": 1.0, "r": 12}]                # the basement beyond the door
SHOTS = {"boiler": {"center": [-30, B + 5, 20], "radius": 28, "lampRadius": 0, "maxLamps": 0, "lights": LIGHTS, "door": DOOR},
         "out": {"center": [-18, B + 5, 18], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": LIGHTS, "door": DOOR}}
DARK = {"ambient": 0.03, "bg": 0x020101}

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

def room(i, cam, look, fov, door=0.0, extra=None, av=None):
    fr = dict(DARK, shot="boiler", cam={"pos": cam, "look": look, "fov": fov}, exposure=2.6, door=door, av=av or friend())
    if extra: fr.update(extra)
    return fr

# 1. (hook) the boiler room from the doorway: the boiler's glow, your friend zip-tied to a pipe
def s_hook(i, k):
    cam = add(lerp([-21.0, B + 5.6, 21.5], [-27.0, B + 5.3, 20.5], ease(k)), hand(i))
    return (room(i, cam, lerp([-34.0, B + 3.2, 16.0], [-37.0, B + 3.8, 18.5], ease(k)), 58, OPEN), None)
shot("hook", 105, s_hook)

# 2. (card) your view, tied to the pipe: the boiler, then your friend, terrified
def s_card(i, k):
    look = lerp([-24.0, B + 3.6, 15.5], [FRIEND[0] + 0.5, B + 4.9, FRIEND[2]], ease((k - 0.35) / 0.5))
    return (room(i, add(EYE, hand(i, 0.4)), look, 58), None)
shot("card", 120, s_card)

# 3. the door opens: him in the doorway, watching, then he goes
def s_door(i, k):
    d = OPEN * ease(k / 0.3)
    if k < 0.75:
        cr = {"pos": DOORWAY, "yaw": facing(DOORWAY, EYE), "gait": "Stare", "t": i / 30, "neck": [0.1, 0.0, 0.2]}
    else:
        w = ease((k - 0.75) / 0.25)
        p = lerp(DOORWAY, [-16.0, B, 24.0], w)
        cr = {"pos": p, "yaw": facing(p, [-14.0, B, 28.0]), "gait": "Walk", "phase": w * 5 * WALK, "t": i / 30}
    return (room(i, add(EYE, hand(i, 0.3)), [-19.5, B + 5.2, 20.0], 40, d, {"glow": 7}), cr)
shot("door", 72, s_door)

# 4. struggle (the view shakes)
def s_struggle(i, k):
    sh = 0.11 * math.sin(i * 2.9) + 0.06 * math.sin(i * 4.3)
    cam = [EYE[0] + sh * 0.3, EYE[1] - 0.3 + 0.07 * math.sin(i * 3.7), EYE[2] + sh]
    fr = room(i, cam, [-30.0, B + 1.0, 13.4], 62, OPEN * 0.6)
    fr["cam"]["roll"] = 0.05 * math.sin(i * 2.1)
    return (fr, None)
shot("struggle", 33, s_struggle)

# 5. the zip tie snaps: you're up; your friend shakes their head, looking at the door
def s_free(i, k):
    cam = add(lerp(EYE, [-34.0, B + 5.6, 14.8], ease(k / 0.45)), hand(i, 0.6))
    look = lerp([-31.0, B + 4.0, 14.0], [FRIEND[0] + 0.3, B + 4.9, FRIEND[2]], ease((k - 0.25) / 0.4))
    shake = 0.5 * math.sin(i * 0.5) * ease((k - 0.55) / 0.2)
    return (room(i, cam, look, 54, OPEN * 0.6, av=friend({"neckY": shake, "neckX": 0.05})), None)
shot("free", 90, s_free)

# hiding behind the boiler, peeking round its north edge at the door
def hide(i, look, extra=None):
    return room(i, [HIDE[0], HIDE[1] + 0.03 * math.sin(i * 0.31), HIDE[2]], look, 56, OPEN, dict({"exposure": 2.8, "glow": 6}, **(extra or {})))

# 6. footsteps: hide behind the boiler, peek at the door
def s_hide(i, k):
    w = ease(k / 0.6)
    cam = lerp([-33.0, B + 5.4, 16.0], HIDE, w)
    look = lerp([-29.0, B + 2.4, 14.0], [-20.5, B + 5.0, 20.5], ease((k - 0.4) / 0.5))
    return (room(i, add(cam, hand(i, 0.7)), look, 56, OPEN, {"exposure": 2.8}), None)
shot("hide", 60, s_hide)

# 7. he comes back in and walks to your pipe
PIPE = [-35.4, B, 13.2]
def s_back(i, k):
    w = ease(min(1.0, k * 1.05))
    # (round past the water heater, well clear of the boiler where you're hiding)
    MID = [-31.5, B, 22.2]
    p = lerp(lerp([-17.5, B, 20.6], MID, min(1, w * 2)), PIPE, max(0, w * 2 - 1))
    tgt = MID if w < 0.5 else PIPE
    return (hide(i, lerp([-21.0, B + 5.0, 20.5], [-33.0, B + 5.2, 16.0], ease((k - 0.2) / 0.7))),
            {"pos": p, "yaw": facing(p, tgt), "gait": "Walk", "phase": w * 14 * WALK, "t": i / 30})
shot("back", 60, s_back)

# 8. your empty pipe: he stands there, then his head turns slowly towards the boiler
def s_pipe(i, k):
    turn = ease((k - 0.35) / 0.6)
    yaw0 = facing(PIPE, [-40.0, B, 13.2])
    yaw1 = facing(PIPE, HIDE)
    d = ((yaw1 - yaw0 + math.pi) % math.tau) - math.pi
    return (hide(i, [-34.6, B + 6.6, 13.6]),
            {"pos": PIPE, "yaw": yaw0 + d * 0.25 * turn, "gait": "Stare", "t": i / 30, "neck": [0.35 * (1 - turn), 1.1 * turn, 0.2]})
shot("pipe", 60, s_pipe)

# 9. nothing... and he's over the boiler at you (22.15 s: frame 64 of this shot)
def s_lunge(i, k):
    if i < 64:
        look = lerp([-34.6, B + 6.4, 13.6], [-22.0, B + 5.0, 21.0], ease((i - 30) / 30))
        return (hide(i, look), None if i > 30 else
                {"pos": PIPE, "yaw": facing(PIPE, HIDE), "gait": "Stare", "t": i / 30, "neck": [0.0, 0.0, 0.3]})
    j = i - 64
    p = lerp([-25.4, B, 21.6], [-26.2, B, 20.6], ease(j / 4.0))
    return (dict(DARK, shot="boiler", cam={"pos": HIDE, "look": [p[0], B + 8.0, p[2]], "fov": 62}, exposure=3.0, glow=12, door=OPEN, av=friend()),
            {"pos": p, "yaw": facing(p, HIDE), "gait": "Reach", "t": i / 30, "duck": 0.9, "neck": [0.0, 0.0, 0.3 * math.sin(i * 0.9)]})
shot("lunge", 75, s_lunge)

# 10. RUN: out the door into the basement, looking back: he comes after you
def s_run(i, k):
    cam = [-21.5 + 6.0 * k + 0.2 * math.sin(i * 1.7), B + 4.8 + 0.2 * math.sin(i * 2.3), 19.8 + 0.6 * k]
    p = lerp([-29.0, B, 17.6], [-24.0, B, 19.4], k)
    return (dict(DARK, shot="out", cam={"pos": cam, "look": [p[0], B + 4.4, p[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash={"i": 16.0, "pos": [cam[0] - 0.5, cam[1] - 0.5, cam[2]], "target": [p[0], B + 4.0, p[2]], "angle": 0.4},
                 exposure=1.7, glow=8, door=OPEN, av=friend()),
            {"pos": p, "yaw": facing(p, cam), "gait": "Chase", "phase": k * 15 * RUN, "t": i / 30})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": AVS, "extras": [],
           "props": {"cache": "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
