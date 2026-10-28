# Reel 50 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #5" (the new run, after #4 = reel 49): #2's exact format, look,
# music and slot lengths, and #12's recipe (46.7K: the v112 look, no mask, him in almost every clip). The chapter: he wants
# the bathroom, the room with the house's one bar of signal (the game's 911 call). On the roof outside its window, then at
# the glass, then standing in the shower behind the curtain, then in its doorway... so tonight i locked the door and hid
# in the shower: he was in here with me.
#   hook (105)  the upstairs bathroom, the light on, cosy
#   card (120)  the same room in the dark, a slow push to the shower
#   72  "night 19: someone was on the roof."     from the window: lightning, him standing on the garage roof in the rain
#   33  "night 20: at the window."               his face right at the glass
#   90  "night 21: in the shower."               the curtain drawn: his shape behind it, his head turning
#   60  "night 22: in the doorway."              from the sink: him in the bathroom doorway, leaning in
#   60  "so tonight i locked the door."          the light on, the door shut
#   60  "and hid in the shower."                 inside, through the curtain: the dark room, empty
#   75  "he was in here with me."                turn round in the shower: he's crouched in its corner; the maw tears open
#                                                and he comes (22.15 s)
#   30  "RUN."                                   down the hall, him out of the bathroom after you on all fours
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau), shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.6
TAU = math.tau
S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]
def wrap(a): return ((a + math.pi) % TAU) - math.pi
def stop(i, fps=13): return math.floor(i * fps / 30) / fps
def him(pos, yaw, gait="Stare", phase=0.0, t=0.0, **opts):
    return {"pos": {"x": pos[0], "y": pos[1], "z": pos[2]}, "yaw": yaw, "gait": gait, "phase": phase, "t": t, "seed": 4, "opts": opts}

COLD, MOON, WARM = "#3d4f7a", "#6f86c4", "#ffd9a0"
# --- the upstairs bathroom (World): x 12..39.5, z -6..8; the hall door in the x = 12 wall at z = 1 (hinged at z = -1.42, it
# swings into the bathroom); the window in the x = 40 wall at z = 1 (sill 19.9, the glass 20..24) over the garage's flat roof
# (y 16.8); the shower stall x 33.4..39.1, z 2.9..7.6, open on its x = 33.3 side (the curtain, hinged at z = 7.6: 0 = drawn);
# the vanity + mirror at x 17.5, z -4.3 (reels 27 and 37)
BATH_DOOR = {"near": [12.0, U + 4.7, 1.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [12.0, 0, -1.42], "axis": "y"}
CURTAIN_NAMES = ["ShowerCurtain", "CurtainFold"]
CURTAIN = {"near": [33.3, U + 5.5, 5.3], "r": 3.6, "names": CURTAIN_NAMES, "hinge": [33.3, 0, 7.6], "axis": "y"}
SEE_THROUGH = {"names": CURTAIN_NAMES, "near": [33.3, U + 5.5, 5.3], "r": 3.6, "opacity": 0.42}
ROOF = 16.8
NOCANDY = ["CandyWrap", "CandyBody"]
BATH_DARK = [{"p": [43.0, U + 8, 1.0], "col": MOON, "b": 2.8, "r": 34, "decay": 1.0},       # the moon through the window
             {"p": [8.5, U + 4.5, 1.0], "col": "#5d72a8", "b": 1.8, "r": 10},               # the hall, behind the door
             {"p": [26.0, U + 4.0, 1.0], "col": COLD, "b": 0.6, "r": 14}]
INSHOWER = [{"p": [38.4, U + 9.0, 5.3], "col": "#8094cc", "b": 1.8, "r": 9, "decay": 1.2}]  # (behind him: his shape on the curtain)
SHOTS = {
    "lit": {"center": [26, U + 5, 1], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": BATH_DOOR, "hide": NOCANDY,
            "lights": [{"p": [25, U + 10, 1.5], "col": WARM, "b": 4.0, "r": 30, "decay": 1.0}] + BATH_DARK},
    "bath": {"center": [26, U + 5, 1], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": BATH_DOOR, "lights": BATH_DARK, "hide": ["Globe"] + NOCANDY},
    "window": {"center": [42, U + 4, 1], "radius": 40, "lampRadius": 0, "maxLamps": 0, "hide": ["Globe", "Glass"] + NOCANDY,
               "lights": [{"p": [50, U + 12, -4], "col": MOON, "b": 2.0, "r": 40, "decay": 1.0}, {"p": [34, U + 6, 2], "col": COLD, "b": 0.6, "r": 12}]},
    "shut": {"center": [28, U + 5, 3], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": CURTAIN, "translucent": SEE_THROUGH,
             "lights": BATH_DARK + INSHOWER, "hide": ["Globe"] + NOCANDY},
    "inside": {"center": [30, U + 5, 3], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": CURTAIN, "translucent": SEE_THROUGH,
               "lights": BATH_DARK + [{"p": [36.5, U + 9.5, 5.3], "col": "#8094cc", "b": 1.6, "r": 8, "decay": 1.2}, {"p": [24.0, U + 8.0, 1.0], "col": MOON, "b": 2.2, "r": 18}], "hide": ["Globe"] + NOCANDY},
    "hallRun": {"center": [4, U + 6, 6], "radius": 34, "lampRadius": 0, "maxLamps": 0, "hide": NOCANDY,
                "lights": [{"p": [2, U + 11, 24], "col": MOON, "b": 1.8, "r": 30, "decay": 1.1}, {"p": [14, U + 7, 1], "col": COLD, "b": 1.6, "r": 16}]},
}
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 0}
extras = []

frames, crs, shots = [], [], []
f = 0
def shot(name, n, fn):
    global f
    shots.append({"name": name, "start": f, "n": n})
    dense = dict((d.split(":")[0], d.split(":")[1:]) for d in os.environ.get("DENSE", "").split(",") if d)
    if name in dense:
        a = dense[name]
        idx = list(range(int(a[1]) if len(a) > 1 else 0, n, int(a[0]) if a else 8))
    else:
        idx = [0, n // 2, n - 1]
    idx = idx if PREVIEW else range(n)
    for i in idx:
        k = i / max(1, n - 1)
        fr, cr = fn(i, k)
        fr["f"] = f + i
        fr["creature"] = cr is not None
        fr.setdefault("hideIdx", [])
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}
def sky(lt):
    c = lerp([10, 13, 22], [120, 132, 168], lt)
    return (int(c[0]) << 16) | (int(c[1]) << 8) | int(c[2])
def bolt(lt, tgt):
    # lightning seen through the window: a cold light from high outside, on the roof (not in the room)
    return {"i": 110.0 * lt, "pos": [58.0, U + 40.0, 8.0], "target": tgt, "angle": 0.55} if lt > 0 else {"i": 0}

# 1. (hook) the bathroom, the light on: cosy
def s_hook(i, k):
    cam = add(lerp([15.0, U + EYE, -3.8], [17.5, U + EYE - 0.1, -3.0], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([36.0, U + 4.0, 4.0], [36.0, U + 4.0, 4.6], ease(k)), "fov": 62}, door=1.4), None)
shot("hook", 105, s_hook)

# 2. (card) the same room in the dark, a slow push to the shower
def s_card(i, k):
    cam = add(lerp([15.0, U + EYE, -3.8], [20.0, U + EYE - 0.2, -2.0], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="bath", cam={"pos": cam, "look": [36.0, U + 4.2, 4.8], "fov": 60}, exposure=3.2, door=1.4), None)
shot("card", 120, s_card)

# 3. "night 19: someone was on the roof." from the window: lightning, him on the garage roof in the rain
FAR = [53.0, ROOF, -1.5]
def s_roof(i, k):
    cam = add(lerp([37.6, U + EYE + 0.1, 1.9], [38.2, U + EYE, 1.9], ease(k)), hand(i, 0.5))
    lt = 1.0 if 10 <= i <= 13 else (0.6 if 16 <= i <= 18 else (0.85 if 44 <= i <= 47 else 0.0))
    return (dict(DARK, shot="window", cam={"pos": cam, "look": [46.0, U + 5.6, 0.6], "fov": 56}, exposure=2.2, flash=bolt(lt, [53.0, ROOF + 4, -1.5]),
                 lightning=0.12 * lt, moon=0.25, glow=2.6, bg=sky(lt)),
            him(FAR, facing(FAR, cam), "Stare", t=2.0 + stop(i), Look=[0.0, -0.1]))
shot("door", 72, s_roof)

# 4. "night 20: at the window." his face right at the glass
GLASS = [44.2, ROOF, 1.95]
def s_glass(i, k):
    cam = add([37.4, U + EYE, 1.9], hand(i, 0.3))
    lt = 0.7 if 3 <= i <= 5 else 0.0
    return (dict(DARK, shot="window", cam={"pos": cam, "look": [42.0, U + 7.8, 1.95], "fov": 58}, exposure=2.2, flash=bolt(lt, [42.6, ROOF + 6, 1.9]),
                 lightning=0.12 * lt, moon=0.25, glow=3.0, bg=sky(lt)),
            him(GLASS, facing(GLASS, cam), "Stare", t=3.0 + stop(i), Duck=1.0, Look=[0.0, -0.45]))
shot("prints", 33, s_glass)

# 5. "night 21: in the shower." the curtain drawn: his shape behind it, his head turning to us
INSIDE = [36.4, U, 5.3]
def s_shape(i, k):
    cam = add(lerp([20.0, U + EYE, -2.2], [25.5, U + EYE - 0.2, 0.2], ease(k)), hand(i, 0.4))
    turn = ease((stop(i) * 30 - 38) / 26)
    y0, y1 = facing(INSIDE, [39.0, U, 5.3]), facing(INSIDE, cam)
    return (dict(DARK, shot="shut", cam={"pos": cam, "look": [34.0, U + 6.2, 5.0], "fov": 52}, exposure=2.6, door=0.0, glow=1.6),
            him(INSIDE, y0 + wrap(y1 - y0) * turn, "Stare", t=2.0 + stop(i), Duck=0.3, Look=[0.0, -0.2]))
shot("photo", 90, s_shape)

# 6. "night 22: in the doorway." from the sink: him in the bathroom doorway, leaning in
DOORWAY = [13.8, U, 1.0]
SINK = [22.5, U + EYE - 0.3, -1.2]
def s_doorway(i, k):
    cam = add(SINK, hand(i, 0.3))
    return (dict(DARK, shot="bath", cam={"pos": cam, "look": lerp([13.2, U + 6.0, 0.9], [13.2, U + 6.8, 0.9], ease(k)), "fov": 50}, exposure=3.0, door=1.4,
                 glow=2.0),
            him(DOORWAY, facing(DOORWAY, cam), "Stare", t=4.0 + stop(i), Duck=0.6, Look=[0.6, -0.3]))
shot("setup", 60, s_doorway)

# 7. "so tonight i locked the door." the light on, the door shut
def s_locked(i, k):
    cam = add(lerp([27.0, U + EYE, 2.2], [25.5, U + EYE, 1.8], ease(k)), hand(i, 0.3))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": [12.0, U + 4.4, 0.6], "fov": 60}, door=0.0), None)
shot("open", 60, s_locked)

# 8. "and hid in the shower." inside, through the drawn curtain: the dark room, nobody
EYEIN = [33.8, U + 5.0, 3.6]
def s_hid(i, k):
    cam = [EYEIN[0], EYEIN[1] + 0.03 * math.sin(i * 0.31), EYEIN[2]]
    return (dict(DARK, shot="inside", cam={"pos": cam, "look": [22.0, U + 4.4, 2.0], "fov": 62}, exposure=3.2, door=0.0), None)
shot("stood", 60, s_hid)

# 9. "he was in here with me." turn round in the shower: he's crouched in its back corner, his face level with mine; the
# maw tears open and he comes (the hit at 22.15 s is frame 64)
CORNER = [38.7, U, 7.0]
def s_corner(i, k):
    cam = add([EYEIN[0], EYEIN[1], EYEIN[2]], hand(i, 0.25))
    t = ease((i - 22) / 22)
    y0, y1 = facing(cam, [22.0, U, 2.0]), facing(cam, CORNER)
    yaw = y0 + wrap(y1 - y0) * t
    ly = (U + 4.4) + ((U + 8.6) - (U + 4.4)) * ease((i - 30) / 22)
    look = [cam[0] - math.sin(yaw) * 6.0, ly, cam[2] - math.cos(yaw) * 6.0]
    if i < 64:
        fr = dict(DARK, shot="inside", cam={"pos": cam, "look": look, "fov": 70}, exposure=2.8, door=0.0, glow=2.4 if t > 0.5 else 0.6)
        return (fr, him(CORNER, facing(CORNER, cam), "Stare", t=3.0 + stop(i), Duck=0.9, Look=[0.0, -0.55], Scream=0.2 * ease((i - 54) / 10)))
    w = ease((i - 64) / 4)
    near = [cam[0] + 3.0, U, cam[2] + 1.6]
    p = lerp(CORNER, near, w)
    camw = add(cam, [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    fr = dict(DARK, shot="inside", cam={"pos": camw, "look": lerp(look, [p[0], U + 7.8, p[2]], w), "fov": 70 + 6 * w}, exposure=2.8, door=0.0, glow=7.0,
              flash=fl(camw, [p[0], U + 6.0, p[2]], 12.0, 0.5))
    return (fr, him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Look=[0.0, -0.3]))
shot("knew", 75, s_corner)

# 10. RUN: down the hall, looking back: he comes out of the bathroom after you on all fours
def s_run(i, k):
    cam = [3.0 + 0.25 * math.sin(i * 1.7), U + 4.8 + 0.2 * math.sin(i * 2.3), 14.0 + 4.0 * k]
    hp = lerp([12.5, U, 1.0], [6.0, U, 8.5], k)
    return (dict(DARK, shot="hallRun", cam={"pos": cam, "look": [hp[0], U + 2.8, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), U + 3.2, hp[2]], 16.0, 0.36), ambient=0.01, exposure=2.0, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
