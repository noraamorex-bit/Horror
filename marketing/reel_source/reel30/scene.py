# Reel 30 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 8)": Parts 2-7's format on #2's track
# (every clip keeps #2's length, so the track's cuts and hits land). The secret ending: the family
# dinner under the house. Zip-tied at his table with your friends; struggle while his back is
# turned, don't move while he watches.
#   hook (105)  under the house: the candlelit table, place cards, your friends tied to their chairs
#   card (120)  your seat: your friend across the table, terrified; behind them, him at the stove
#   72          him at the camping stove, his back to the table, the blue flame
#   33          he stops stirring (your friend's face)
#   90          he turns round, slowly, and watches the table
#   60          he walks round the table, behind your friends' chairs
#   60          he stops behind your friend and leans down, looking right at you
#   60          back at the stove: struggle (the view shakes, the plate, the zip tie)
#   75          the stove... he's not there. He's beside you (the scare at 22.15 s)
#   30          RUN: through the door into the tunnels, he comes round the table after you
# python3 scene.py [preview]. Writes spec.json, frames_in.json, shots.json.
import json, math, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
Y = -30.0                # the burrow's floor
WALK = math.tau / 5.2
RUN = math.tau / 7.5

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]

WARM = "#ffb070"
# the dining room (World/Burrow): table centre (-27, 17); the four chairs; his chair at the head
SEAT_ME = [-23.0, Y, 13.6]       # facing +z, across from the stove
SEAT_OPP = [-23.0, Y, 20.4]      # your friend, facing -z (towards you)
SEAT_DIAG = [-31.0, Y, 20.4]     # another friend
STOVE_STAND = [-19.5, Y, 22.9]   # where he stands, back to the table, facing the stove (+z)
STOVE_LOOK = [-19.5, Y, 30.0]
EYE = [SEAT_ME[0] - 1.2, Y + 4.6, SEAT_ME[2] - 0.2]   # sitting, zip-tied (leaning left: the candle's out of the way)
DOOR = {"near": [-16.0, Y + 4, 17.0], "r": 3.2, "names": ["DiningDoor"], "hinge": [-16.0, 0, 14.5], "axis": "y"}

# your friends, zip-tied to their chairs (arms behind them), scared faces
SIT = {"lHip": 1.5, "rHip": 1.5, "lKnee": -1.5, "rKnee": -1.5, "lShoulder": [-0.45, 0, 0.18], "rShoulder": [-0.45, 0, -0.18], "lElbow": -0.5, "rElbow": -0.5, "neckX": 0.12}
AVS = [
    {"pos": [SEAT_OPP[0], Y + 2.35, SEAT_OPP[2] + 0.15], "yaw": facing(SEAT_OPP, [SEAT_OPP[0], Y, 10]), "pose": SIT, "face": "scared",
     "colors": {"hoodie": "#2f7de0", "hoodieDark": "#215ca8", "pants": "#2a2a33", "hair": "#e0b25a"}},
    {"pos": [SEAT_DIAG[0], Y + 2.35, SEAT_DIAG[2] + 0.15], "yaw": facing(SEAT_DIAG, [SEAT_DIAG[0], Y, 10]), "pose": dict(SIT, neckY=0.35, neckX=0.25), "face": "scared",
     "colors": {"hoodie": "#3fae5a", "hoodieDark": "#2c8043", "pants": "#30303a", "hair": "#2b1a10"}},
]
LIGHTS = [{"p": [-27.0, Y + 6.0, 17.0], "col": WARM, "b": 1.6, "r": 16},             # the candles
          {"p": [-18.5, Y + 4.5, 25.0], "col": "#7ea6ff", "b": 2.2, "r": 10},          # the stove flame
          {"p": [-27.0, Y + 9.0, 17.0], "col": "#ffcf9a", "b": 0.6, "r": 20}]          # the bare bulb
NOCARDS = ["PlaceCard"]  # (their names are SurfaceGui text, which the render can't draw: blank cards look wrong)
SHOTS = {
    "dinner": {"center": [-27, Y + 4, 17], "radius": 30, "lampRadius": 22, "maxLamps": 10, "lights": LIGHTS, "hide": NOCARDS},
    "run": {"center": [-20, Y + 4, 17], "radius": 34, "lampRadius": 22, "maxLamps": 10, "lights": LIGHTS, "door": DOOR, "hide": NOCARDS},
}
DARK = {"ambient": 0.04, "bg": 0x020101}

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

def at_stove(i, extra=None):
    cr = {"pos": STOVE_STAND, "yaw": facing(STOVE_STAND, STOVE_LOOK), "gait": "Stare", "t": i / 30, "neck": [0.35, 0.0, 0.0]}
    if extra: cr.update(extra)
    return cr

# 1. (hook) under the house: the candlelit table, the place cards, your friends tied to their chairs
def s_hook(i, k):
    cam = add(lerp([-36.0, Y + 7.6, 10.5], [-31.5, Y + 6.6, 12.0], ease(k)), hand(i))
    return (dict(DARK, shot="dinner", cam={"pos": cam, "look": lerp([-25.0, Y + 3.2, 19.0], [-22.0, Y + 3.6, 21.0], ease(k)), "fov": 58},
                 exposure=1.5, lamps=0.45), at_stove(i))
shot("hook", 105, s_hook)

# 2. (card) your seat: your friend across the table, terrified; behind them, him at the stove
def s_card(i, k):
    cam = add(EYE, hand(i, 0.5))
    look = lerp([SEAT_OPP[0], Y + 4.4, SEAT_OPP[2]], [-21.0, Y + 4.8, 22.5], ease((k - 0.35) / 0.5))
    return (dict(DARK, shot="dinner", cam={"pos": cam, "look": look, "fov": 56}, exposure=1.5, lamps=0.45), at_stove(i))
shot("card", 120, s_card)

# 3. him at the camping stove, his back to the table, the blue flame
def s_stove(i, k):
    cam = add(EYE, hand(i, 0.4))
    return (dict(DARK, shot="dinner", cam={"pos": cam, "look": [-19.4, Y + 5.6, 23.5], "fov": 30}, exposure=2.3, lamps=0.45),
            at_stove(i, {"neck": [0.35, 0.12 * math.sin(i * 0.12), 0.0]}))
shot("stove", 72, s_stove)

# 4. he stops stirring: your friend's face
def s_friend(i, k):
    cam = add(EYE, hand(i, 0.3))
    return (dict(DARK, shot="dinner", cam={"pos": cam, "look": [SEAT_OPP[0], Y + 4.9, SEAT_OPP[2]], "fov": 26}, exposure=1.6, lamps=0.45),
            at_stove(i, {"neck": [0.0, 0.0, 0.0]}))
shot("friend", 33, s_friend)

# 5. he turns round, slowly, and watches the table
def s_turn(i, k):
    cam = add(EYE, hand(i, 0.35))
    turn = ease((k - 0.1) / 0.55)
    yaw0 = facing(STOVE_STAND, STOVE_LOOK)
    yaw1 = facing(STOVE_STAND, EYE)
    d = (yaw1 - yaw0 + math.pi) % math.tau - math.pi
    return (dict(DARK, shot="dinner", cam={"pos": cam, "look": [-20.0, Y + 6.2, 22.8], "fov": 36}, exposure=1.6, lamps=0.45, glow=4 + 4 * turn),
            {"pos": STOVE_STAND, "yaw": yaw0 + d * turn, "gait": "Stare", "t": i / 30, "neck": [0.1 * turn, 0.0, 0.2 * turn]})
shot("turn", 90, s_turn)

# 6. he walks round the table, behind your friends' chairs
ROUND = [STOVE_STAND, [-23.0, Y, 23.6], [-28.0, Y, 23.4]]
def s_round(i, k):
    w = ease(k)
    seg = min(1, int(w * 2))
    kk = w * 2 - seg
    p = lerp(ROUND[seg], ROUND[seg + 1], kk) if w < 1 else ROUND[-1]
    nxt = ROUND[min(seg + 1, 2)]
    cam = add(EYE, hand(i, 0.35))
    return (dict(DARK, shot="dinner", cam={"pos": cam, "look": lerp([-21.5, Y + 5.2, 22.0], [-26.5, Y + 5.2, 22.5], w), "fov": 50}, exposure=1.6, lamps=0.45, glow=6),
            {"pos": p, "yaw": facing(p, nxt) if w < 0.98 else facing(p, EYE), "gait": "Walk", "phase": w * 12 * WALK, "t": i / 30})
shot("round", 60, s_round)

# 7. he stops behind your friend and leans down, looking right at you
BEHIND = [-23.0, Y, 22.7]
def s_lean(i, k):
    w = ease(min(1.0, k * 1.6))
    p = lerp([-26.0, Y, 23.4], BEHIND, w)
    cam = add(EYE, hand(i, 0.3))
    return (dict(DARK, shot="dinner", cam={"pos": cam, "look": [-23.0, Y + 5.6, 21.5], "fov": 40}, exposure=1.6, lamps=0.45, glow=7),
            {"pos": p, "yaw": facing(p, EYE), "gait": "Walk" if w < 0.98 else "Stare", "phase": w * 4 * WALK, "t": i / 30,
             "duck": 0.8 * ease((k - 0.5) / 0.5), "neck": [0.25, 0.0, 0.3 * ease((k - 0.6) / 0.4)]})
shot("lean", 60, s_lean)

# 8. back at the stove: struggle (the view shakes down at the plate)
def s_struggle(i, k):
    sh = 0.09 * math.sin(i * 2.7) + 0.05 * math.sin(i * 4.1)
    cam = [EYE[0] + sh, EYE[1] - 0.2 + 0.05 * math.sin(i * 3.3), EYE[2]]
    look = lerp([-23.0, Y + 3.8, 15.4], [-20.5, Y + 5.6, 23.0], ease((k - 0.55) / 0.35))
    return (dict(DARK, shot="dinner", cam={"pos": cam, "look": look, "fov": 50, "roll": 0.03 * math.sin(i * 1.9)}, exposure=1.6, lamps=0.45),
            at_stove(i))
shot("struggle", 60, s_struggle)

# 9. the stove... he's not there. He's beside you (22.15 s: frame 64 of this shot)
BESIDE = [-26.6, Y, 11.0]   # (a step away: his mask fills the frame, not his chest)
def s_gone(i, k):
    if i < 64:
        look = lerp([-20.0, Y + 5.2, 23.0], [-26.0, Y + 4.8, 15.0], ease((i - 34) / 26))
        return (dict(DARK, shot="dinner", cam={"pos": add(EYE, hand(i, 0.4)), "look": look, "fov": 50}, exposure=1.6, lamps=0.45), None)
    j = i - 64
    p = lerp([-27.6, Y, 10.2], BESIDE, ease(j / 4.0))
    return (dict(DARK, shot="dinner", cam={"pos": EYE, "look": [p[0], Y + 7.4, p[2]], "fov": 62}, exposure=1.9, lamps=0.45, glow=12),
            {"pos": p, "yaw": facing(p, EYE), "gait": "Reach", "t": i / 30, "duck": 0.9, "neck": [0.0, 0.0, 0.3 * math.sin(i * 0.9)]})
shot("gone", 75, s_gone)

# 10. RUN: through the door into the tunnels, looking back: he comes round the table after you
def s_run(i, k):
    cam = [-19.5 + 4.5 * k + 0.2 * math.sin(i * 1.7), Y + 4.8 + 0.2 * math.sin(i * 2.3), 16.2 + 0.4 * k]
    p = lerp([-26.6, Y, 11.4], [-21.5, Y, 15.6], k)
    return (dict(DARK, shot="run", cam={"pos": cam, "look": [p[0], Y + 4.6, p[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 exposure=1.6, lamps=0.45, glow=8, door=-1.66),
            {"pos": p, "yaw": facing(p, cam), "gait": "Chase", "phase": k * 15 * RUN, "t": i / 30})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": AVS, "extras": [],
           "props": {"cache": "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
