# Reel 49 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #4" (the new run, after #3 = reel 48): #2's exact format, look,
# music and slot lengths. The views (27 Oct): #12 (reel 43) 46.7K, every other reel since 1.5-3.8K. #12 was the only one
# with the v112 creature (the pale skinned body, the maw tearing open) and it showed him in four clips before the scare;
# the masked reels since show him once or twice. So #4 is #12's recipe: him in almost every clip, getting closer every
# night, in the v112 look (no mask), and the maw on the hit.
#   hook (105)  the master bedroom, lamps on, cosy
#   card (120)  the same room in the moonlight, a slow push to the bed
#   72  "night 15: he was at the end of the hall."   from my door: him far down the dark upstairs hall, standing still
#   33  "night 16: closer."                          the same view: halfway, his head laid over
#   90  "night 17: at my door."                      from my bed: him in the doorway, watching
#   60  "night 18: at the foot of my bed."           from my bed: him bent over the footboard
#   60  "so tonight i stayed awake."                 lamps on, from the bed: the doorway empty
#   60  "the hall was empty."                        from my door again: nobody, the flashlight down the hall
#   75  "he was already in here."                    back in bed, the flashlight on the door... turn: he's crouched right
#                                                    beside the bed; the maw tears open and he comes (22.15 s)
#   30  "RUN."                                       out into the hall, him after you on all fours
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau), shots.json.
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
# --- the master bedroom (World/Interior): x -40..-8, z -30..0, floor U; the bed x -39.15..-30.15, z -18.25..-10.75 (headboard at
# -x); the door in the x = -8 wall at z -10 (hinge z -12.42); the upstairs hall runs along z at x ~4 (reel 43's crawl shot)
DOOR_RIG = {"near": [-8.0, U + 4.7, -10.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, -12.42], "axis": "y"}
ROOM = [{"p": [-24, U + 9, -33], "col": MOON, "b": 2.6, "r": 34, "decay": 1.1}, {"p": [-14, U + 6, -20], "col": COLD, "b": 1.1, "r": 18},
        {"p": [-4.5, U + 7, -10], "col": MOON, "b": 4.0, "r": 18}, {"p": [-26, U + 9, -14], "col": COLD, "b": 0.8, "r": 16},
        {"p": [-30.0, U + 8.5, -16.0], "col": MOON, "b": 2.0, "r": 14, "decay": 1.0}]
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [5, U + 8, 4], "col": COLD, "b": 1.2, "r": 16},
        {"p": [2.5, U + 9, -9], "col": "#5d72a8", "b": 1.6, "r": 18}, {"p": [5, U + 9, 14], "col": MOON, "b": 1.4, "r": 16}]
NOCANDY = ["CandyWrap", "CandyBody"]     # (the Halloween hunt's candies: not in this story)
SHOTS = {
    "lit": {"center": [-24, U + 5, -15], "radius": 30, "lampRadius": 30, "maxLamps": 6, "door": DOOR_RIG, "hide": NOCANDY},
    "room": {"center": [-24, U + 5, -15], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": DOOR_RIG, "lights": ROOM, "hide": NOCANDY},
    "hall": {"center": [5, U + 6, 8], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": HALL, "hide": NOCANDY},
}
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}
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

BEDEYE = [-36.4, U + 3.9, -14.0]          # lying in bed, head on the pillow
DOORWAY = [-10.3, U, -10.7]
HALLCAM = [3.6, U + EYE - 0.6, -7.5]       # at my door, looking down the hall

# 1. (hook) the master bedroom, lamps on: cosy
def s_hook(i, k):
    cam = add(lerp([-11.5, U + 6.2, -6.0], [-13.5, U + 6.0, -7.0], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([-33.0, U + 3.2, -15.0], [-33.5, U + 3.0, -15.5], ease(k)), "fov": 62}, door=0.0), None)
shot("hook", 105, s_hook)

# 2. (card) the same room in the moonlight, a slow push to the bed
def s_card(i, k):
    cam = add(lerp([-11.5, U + 6.2, -6.0], [-16.0, U + 5.8, -8.5], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-34.0, U + 3.0, -15.0], "fov": 60}, exposure=3.4, lamps=0, door=0.0), None)
shot("card", 120, s_card)

# 3. "night 15: he was at the end of the hall." from my door: him far down the dark hall, standing still
FAR = [4.6, U, 21.0]
def s_far(i, k):
    cam = add(HALLCAM, hand(i, 0.4))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": lerp([4.4, U + 4.4, 14.0], [4.5, U + 4.8, 16.0], ease(k)), "fov": 44 - 6 * ease(k)},
                 exposure=2.6, glow=2.4, flash=fl(cam, [4.6, U + 4.5, 19.0], 7.0, 0.22)),
            him(FAR, facing(FAR, cam), "Stare", t=2.0 + stop(i), Look=[0.0, -0.1]))
shot("door", 72, s_far)

# 4. "night 16: closer." the same view: halfway down the hall, his head laid over
MID = [4.4, U, 8.5]
def s_mid(i, k):
    cam = add(HALLCAM, hand(i, 0.4))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [4.4, U + 5.0, 9.0], "fov": 44}, exposure=2.6, glow=2.6, flash=fl(cam, [4.4, U + 5.5, 8.6], 9.0, 0.26)),
            him(MID, facing(MID, cam), "Stare", t=3.0 + stop(i), Look=[0.5, -0.2], Duck=0.2))
shot("prints", 33, s_mid)

# 5. "night 17: at my door." from my bed: him in the doorway, watching (reel 43's shot)
def s_door(i, k):
    cam = [BEDEYE[0], BEDEYE[1] + 0.02 * math.sin(i * 0.2), BEDEYE[2]]
    look = lerp([DOORWAY[0], U + 6.0, DOORWAY[2]], [DOORWAY[0], U + 7.2, DOORWAY[2]], ease(k))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": look, "fov": 40 - 6 * ease(k)}, exposure=3.2, door=-1.35, glow=1.8),
            him(DOORWAY, facing(DOORWAY, BEDEYE), "Stare", t=2.0 + i / FPS, Duck=0.45, Look=[0.0, -0.15]))
shot("photo", 90, s_door)

# 6. "night 18: at the foot of my bed." from my bed: him bent over the footboard, looking down at me
FOOT = [-27.6, U, -14.2]
def s_foot(i, k):
    cam = [BEDEYE[0] + 0.3, BEDEYE[1] + 0.5 + 0.02 * math.sin(i * 0.2), BEDEYE[2]]
    return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp([-28.5, U + 6.0, -14.2], [-28.5, U + 6.6, -14.2], ease(k)), "fov": 46}, exposure=3.0,
                 door=-1.35, glow=2.2),
            him(FOOT, facing(FOOT, cam), "Stare", t=4.0 + stop(i), Duck=0.85, Look=[0.0, -0.5]))
shot("setup", 60, s_foot)

# 7. "so tonight i stayed awake." lamps on, from the bed, sitting up: the doorway empty
def s_awake(i, k):
    cam = add([-35.6, U + 5.4, -14.2], hand(i, 0.3))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([-12.0, U + 4.6, -10.8], [-12.0, U + 4.8, -11.0], ease(k)), "fov": 52}, door=-1.35), None)
shot("open", 60, s_awake)

# 8. "the hall was empty." from my door again: nobody; the flashlight goes down the hall
def s_empty(i, k):
    cam = add(HALLCAM, hand(i, 0.5))
    tgt = lerp([4.0, U + 1.0, 4.0], [4.8, U + 2.0, 20.0], ease(k))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [4.5, U + 4.0, 14.0], "fov": 48}, exposure=2.4, flash=fl(cam, tgt, 12.0, 0.3)), None)
shot("stood", 60, s_empty)

# 9. "he was already in here." back in bed, the flashlight on the doorway... turn to the side of the bed: he's crouched
# right there, his face level with mine; the maw tears open and he comes (the hit at 22.15 s is frame 64)
SIDE = [-34.8, U, -23.4]
def s_here(i, k):
    cam = add([BEDEYE[0] + 0.6, BEDEYE[1] + 0.6, BEDEYE[2]], hand(i, 0.3))
    door = [DOORWAY[0], U + 4.6, DOORWAY[2]]
    t = ease((i - 22) / 22)
    y0, y1 = facing(cam, door), facing(cam, SIDE)
    yaw = y0 + wrap(y1 - y0) * t
    ly = (U + 4.6) + ((U + 7.4) - (U + 4.6)) * ease((i - 30) / 22)
    look = [cam[0] - math.sin(yaw) * 6.0, ly, cam[2] - math.cos(yaw) * 6.0]
    if i < 64:
        fr = dict(DARK, shot="room", cam={"pos": cam, "look": look, "fov": 56}, exposure=2.4, door=-1.35, glow=2.4 if t > 0.5 else 0.8,
                  flash=fl(cam, look, 12.0, 0.4))
        return (fr, him(SIDE, facing(SIDE, cam), "Stare", t=3.0 + stop(i), Duck=1.0, Look=[0.0, -0.2], Scream=0.2 * ease((i - 54) / 10)))
    w = ease((i - 64) / 4)
    near = [cam[0] - 0.2, U, cam[2] - 4.6]
    p = lerp(SIDE, near, w)
    camw = add(cam, [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    fr = dict(DARK, shot="room", cam={"pos": camw, "look": lerp(look, [p[0], U + 6.6, p[2]], w), "fov": 56 + 8 * w}, exposure=2.6, door=-1.35, glow=7.0,
              flash=fl(camw, [p[0], U + 6.5, p[2]], 14.0, 0.5))
    return (fr, him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Look=[0.0, -0.3]))
shot("knew", 75, s_here)

# 10. RUN: out into the hall, looking back: he comes after you on all fours
def s_run(i, k):
    cam = [4.0 + 0.25 * math.sin(i * 1.7), U + 5.0 + 0.2 * math.sin(i * 2.3), -4.0 + 9.0 * k]
    hp = lerp([1.5, U, -13.0], [3.6, U, -1.5], k)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [hp[0], U + 2.8, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), U + 3.2, hp[2]], 16.0, 0.36), ambient=0.01, exposure=2.0, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
