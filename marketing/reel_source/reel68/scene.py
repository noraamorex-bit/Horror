# Reel 68 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 6)": the PEAK run on #2's track. The first reel of the v143
# house (World/Furnish: the upstairs hall's console, lamp, paintings and sconces; the master bedroom's reading corner) and
# his v143 run (SkinPose Chase: low and splayed like a spider, elbows up, head cocked). The upstairs hall, lamps on; they
# stutter out. At the far end he's crouched low, head cocked. He scuttles at you. Down the hall, him after you. Into the
# master bedroom, down in the corner by the armchair. The door creaks open: he's low in the doorway. He crawls in, stops,
# listens. Silence... he's right beside you (22.15 s). RUN.
#   hook (105)  the upstairs hall, lamps and sconces on: warm
#   card (120)  the lights stutter and die: the hall in moonlight (played at 0.64)
#   72          the far end: him crouched low on all fours, head cocked, still
#   33          he scuttles at you
#   90          backing down the hall: him scuttling after you
#   60          down in the master bedroom's corner, the door across the room
#   60          the door creaks open: him low in the doorway
#   60          he crawls in and stops in the middle of the room, head turning
#   75          silence; turn: he's right beside you, his mask at your level (22.15 s)
#   30          RUN out of the door, him after you
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau + mask.json), shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.5
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

COLD, MOON = "#3d4f7a", "#6f86c4"
NOCANDY = ["CandyWrap", "CandyBody"]
# --- the upstairs hall: x -8..12, z -30..30 (the stair hole x -8..-2, z -6..16.4); the window at its south end (z -30)
HALLD = [{"p": [2, U + 8, -31.5], "col": MOON, "b": 2.6, "r": 30, "decay": 1.0}, {"p": [4, U + 8, 12], "col": COLD, "b": 1.1, "r": 22},
         {"p": [2, U + 9, 26], "col": "#2c3d6e", "b": 1.2, "r": 18}]
# --- the master bedroom: x -40..-8, z -30..0; its door in the x = -8 wall at z -10 (hinged at z -12.43, it swings in)
MDOOR = {"near": [-8.0, U + 4.7, -10.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, -12.43], "axis": "y"}
ROOM = [{"p": [-24, U + 9, -33], "col": MOON, "b": 3.4, "r": 36, "decay": 1.0}, {"p": [-16, U + 8, -31], "col": MOON, "b": 2.4, "r": 24}, {"p": [-14, U + 6, -20], "col": COLD, "b": 1.2, "r": 18},
        {"p": [-3.5, U + 7, -10], "col": MOON, "b": 3.6, "r": 16}, {"p": [-26, U + 9, -12], "col": COLD, "b": 0.9, "r": 16}]
SHOTS = {
    "lit": {"center": [2, U + 5, -10], "radius": 36, "lampRadius": 36, "maxLamps": 10},
    "hall": {"center": [2, U + 5, -6], "radius": 38, "lampRadius": 0, "maxLamps": 0, "lights": HALLD},
    "room": {"center": [-18, U + 5, -10], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": MDOOR, "lights": ROOM},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}

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
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}

# 1. (hook) the upstairs hall, lamps and sconces on
def s_hook(i, k):
    cam = add(lerp([6.0, U + 5.6, -28.0], [5.0, U + 5.5, -25.0], ease(k)), hand(i, 0.5))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([-7.0, U + 4.8, -19.0], [-6.5, U + 4.6, -16.0], ease(k)), "fov": 62}), None)
shot("hook", 105, s_hook)

# 2. (card) the lights stutter and die: the hall in moonlight
FLICK = [(0, 20, True), (20, 23, False), (23, 26, True), (26, 31, False), (31, 33, True)]
def s_card(i, k):
    cam = add(lerp([5.0, U + 5.5, -25.0], [4.0, U + 5.5, -22.5], ease(k)), hand(i, 0.5))
    on = any(a <= i < b and v for a, b, v in FLICK)
    look = lerp([-6.5, U + 4.6, -16.0], [-3.0, U + 4.2, 4.0], ease((i - 30) / 50))
    if on:
        return (dict(LIT, shot="lit", cam={"pos": cam, "look": look, "fov": 62}), None)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 62}, exposure=3.4, flash=fl(cam, look, 7.0 * ease((i - 40) / 20), 0.3)), None)
shot("card", 120, s_card)

# 3. the far end: him crouched low on all fours, head cocked, quite still (his Chase pose, held), the flashlight on him
FAR = [3.2, U, 23.0]
CAM3 = [2.3, U + 5.4, -20.5]
def s_far(i, k):
    cam = add(lerp(CAM3, [2.3, U + 5.4, -18.5], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [3.0, U + 2.6, 22.0], "fov": 40 - 6 * ease(k)}, exposure=2.6, glow=2.2,
                 flash=fl(cam, [3.2, U + 2.2, 22.0], 14.0, 0.18)),
            him(FAR, facing(FAR, cam), "Chase", phase=0.9 + 0.04 * math.sin(i * 0.2), t=2.0 + stop(i)))
shot("far", 72, s_far)

# 4. he scuttles at you, fast
def s_comes(i, k):
    cam = add([2.3, U + 5.4, -18.5], [0.08 * math.sin(i * 1.9) * k, 0.06 * math.sin(i * 2.3) * k, 0])
    p = lerp(FAR, [2.8, U, 4.0], k)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [p[0], U + 2.8, p[2]], "fov": 44}, exposure=2.6, glow=3.0,
                 flash=fl(cam, [p[0], U + 2.2, p[2]], 14.0, 0.22)),
            him(p, facing(p, cam), "Chase", phase=0.9 + k * 3.0 * TAU, t=4.0 + i / FPS))
shot("comes", 33, s_comes)

# 5. backing down the hall, looking at him: he scuttles after you, the paintings and the console going past
def s_chase(i, k):
    cz = -12.0 - 13.0 * k
    cam = [1.2 + 0.22 * math.sin(i * 1.7), U + 5.0 + 0.18 * math.sin(i * 2.3), cz]
    hz = lerp([0, 0, 3.0], [0, 0, -15.5], k)[2]
    hp = [2.0 + 0.6 * math.sin(i * 0.15), U, hz]
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [hp[0], U + 2.6, hp[2]], "fov": 66, "roll": 0.05 * math.sin(i * 0.9)}, exposure=2.4,
                 glow=4.0, flash=fl(cam, [hp[0] + 0.5 * math.sin(i * 1.3), U + 2.6, hp[2]], 14.0, 0.36)),
            him(hp, facing(hp, cam), "Chase", phase=k * 9.0 * TAU, t=5.0 + i / FPS))
shot("chase", 90, s_chase)

# 6. down in the master bedroom's corner, by the plant: the door across the room, shut
CORNER = [-11.9, U + 2.6, -3.9]
DOORLOOK = [-8.6, U + 4.0, -10.4]
def s_corner(i, k):
    cam = add(CORNER, hand(i, 0.25 + 0.2 * math.sin(i * 0.3) ** 2))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": DOORLOOK, "fov": 64}, exposure=4.0, door=0.0), None)
shot("corner", 60, s_corner)

# 7. the door creaks open: him low in the doorway, the hall's moonlight behind him
DOORWAY = [-6.2, U, -10.2]
def s_door(i, k):
    cam = add(CORNER, hand(i, 0.3))
    d = 1.3 * ease((i - 4) / 30)
    return (dict(DARK, shot="room", cam={"pos": cam, "look": DOORLOOK, "fov": 60}, exposure=4.0, door=d, glow=1.8 * ease((i - 20) / 15)),
            him(DOORWAY, facing(DOORWAY, CORNER), "Chase", phase=0.9, t=6.0 + stop(i)))
shot("door", 60, s_door)

# 8. he crawls in and stops in the middle of the room; his head comes round towards the corner
MID = [-12.0, U, -15.5]
def s_in(i, k):
    cam = add(CORNER, hand(i, 0.3))
    w = ease(min(1.0, i / 34))
    p = lerp([-9.8, U, -10.4], MID, w)
    look = lerp([-10.0, U + 2.8, -10.6], [-12.0, U + 2.6, -15.0], w)
    if i < 36:
        cr = him(p, facing([-9.8, U, -10.4], MID), "Chase", phase=w * 2.2 * TAU, t=7.0 + i / FPS)
    else:
        turn = ease((stop(i) * 30 - 42) / 14)
        y0, y1 = facing([-9.8, U, -10.4], MID), facing(MID, CORNER)
        cr = him(MID, y0 + wrap(y1 - y0) * turn * 0.6, "Chase", phase=2.2 * TAU, t=8.2 + stop(i))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": look, "fov": 60}, exposure=4.0, door=1.3, glow=1.6), cr)
shot("in", 60, s_in)

# 9. silence, looking at where he was... gone. Turn right: he's beside you, his mask down at your level; on 22.15 s
# (frame 65) he comes
BESIDE = [-8.7, U, -9.0]
def s_beside(i, k):
    cam = add(CORNER, hand(i, 0.3))
    t = ease((i - 24) / 22)
    y0, y1 = facing(cam, MID), facing(cam, BESIDE)
    yaw = y0 + wrap(y1 - y0) * t
    look = [cam[0] - math.sin(yaw) * 6.0, U + 2.6 + 3.6 * ease((i - 30) / 18), cam[2] - math.cos(yaw) * 6.0]
    if i < 65:
        cr = him(BESIDE, facing(BESIDE, cam), "Stare", t=3.0 + stop(i), Duck=2.1, Look=[0.0, -0.55], Scream=0.15 * ease((i - 55) / 10)) if t > 0.2 else None
        return (dict(DARK, shot="room", cam={"pos": cam, "look": look, "fov": 62}, exposure=3.8, door=1.3, glow=2.4 if t > 0.5 else 0.5), cr)
    w = ease((i - 65) / 5)
    p = lerp(BESIDE, [-9.5, U, -7.9], w)
    camw = add(cam, [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    return (dict(DARK, shot="room", cam={"pos": camw, "look": lerp(look, [p[0], U + 4.8, p[2]], w), "fov": 62 + 8 * w}, exposure=3.0, door=1.3, glow=6.0,
                 flash=fl(camw, [p[0], U + 4.6, p[2]], 8.0, 0.5)),
            him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Duck=2.1 + 0.5 * w, Look=[0.0, -0.6]))
shot("knew", 75, s_beside)

# 10. RUN: out of the door into the hall, looking back: he scuttles out after you
def s_run(i, k):
    c = lerp([0.5, 0, -15.0], [5.0, 0, -21.0], k)
    cam = [c[0] + 0.25 * math.sin(i * 1.7), U + 5.0 + 0.2 * math.sin(i * 2.3), c[2]]
    hp = lerp([-7.0, U, -10.6], [-2.2, U, -13.4], k)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [hp[0], U + 2.6, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)}, door=1.3,
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), U + 2.8, hp[2]], 14.0, 0.36), exposure=2.2, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": [],
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
