# Reel 71 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 9)": the PEAK run on #2's track, in the v146 house, the
# first with the v147 creature (long arms and neck, the cracked mask with the mismatched eyes) and the game's new PEEK.
# Hiding in the master bedroom's wardrobe: he comes in; you peek out at him, his head snaps round; back in, he walks past;
# peek again, the room's empty, the door's empty; back in, nothing; one more peek... he's right there (22.15 s). RUN.
#   hook (105)  the dark bedroom from the doorway, pushing in on the wardrobe
#   card (120)  through the crack: the bedroom door eases open, him stooped in the doorway
#   72          PEEK: the door eases out, you lean: him at the foot of the bed, back turned, long arms hanging
#   33          his head snaps right round to you
#   90          back in, the door pulled to: he walks across the room towards the crack, and past
#   60          peek again: empty, the bed
#   60          lean further, turn to the door: open, nobody
#   60          back in: the crack, nothing
#   75          one more peek... his mask right there in the gap (22.15 s)
#   30          RUN for the door, him after you on all fours
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau + mask.json), shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
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

COLD, MOON, LAMP = "#3d4f7a", "#6f86c4", "#ffc48a"
HIDE = ["CandyWrap", "CandyBody"]
# the master bedroom (upstairs, floor U): x -39.3..-8.5, z -29.3..-0.5. The wardrobe stands against the back wall
# (x -27.5..-20.5, z -29.15..-26.35), its doors facing +z; each leaf hinged at its outer edge. The bed
# against the west wall (x -39..-30, z -18..-11), the room's door in the east wall (x -8, z -12.4..-7.6, into the room).
# (the left leaf, hinged at x -27.4: its gap opens towards the room's door; the rig turns it outward with a negative angle,
# so every `door` value below is flipped at the end)
WLEAF = {"near": [-25.71, U + 4.5, -26.47], "r": 1.9, "names": ["WardrobeLeaf", "DoorPanel", "PanelInset", "Handle"], "hinge": [-27.4, 0, -26.47], "axis": "y"}
RDOOR = {"near": [-8.0, U + 4.7, -10.0], "r": 3.2, "names": ["Panel", "Knob"], "hinge": [-8.0, 0, -12.4], "axis": "y"}
ROOM = [{"p": [-32, U + 7, -27.5], "col": MOON, "b": 2.2, "r": 26, "decay": 1.0}, {"p": [-16, U + 7, -27.5], "col": MOON, "b": 2.0, "r": 26, "decay": 1.0},
        {"p": [-38, U + 7, -24], "col": MOON, "b": 1.6, "r": 20, "decay": 1.0}, {"p": [-24, U + 8, -8], "col": COLD, "b": 0.9, "r": 22},
        {"p": [-5, U + 7, -10], "col": "#ffd8a8", "b": 0.9, "r": 12}]
SHOTS = {
    "room": {"center": [-24, U + 5, -15], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": ROOM, "door": WLEAF, "door2": RDOOR},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + HIDE
DARK = {"ambient": 0.02, "bg": 0x010102}

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

# 1. (hook) the dark bedroom from its doorway, pushing in on the wardrobe against the back wall
def s_hook(i, k):
    cam = add(lerp([-9.6, U + 6.0, -9.0], [-14.0, U + 5.6, -14.5], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp([-22.0, U + 5.0, -26.0], [-24.0, U + 4.4, -27.0], ease(k)), "fov": 66}, exposure=4.2, door=0.0, door2=0.0), None)
shot("hook", 105, s_hook)

# 2. (card) inside the wardrobe, through the crack: the room's door eases open, he's in the doorway, stooped
CR = [-24.05, U + 5.3, -26.28]
LOOK = [-17.0, U + 4.4, -12.0]
CRACK = 0.38
DOORWAY = [-10.6, U, -10.0]
def s_card(i, k):
    cam = add(CR, hand(i, 0.15))
    d2 = 1.35 * ease((i - 15) / 50)
    cr = him(DOORWAY, facing(DOORWAY, [-24, U, -20]), "Stare", t=1.0 + stop(i), Duck=1.4) if i > 40 else None
    return (dict(DARK, shot="room", cam={"pos": cam, "look": LOOK, "fov": 54}, exposure=6.5, door=CRACK, door2=d2, glow=1.2), cr)
shot("card", 120, s_card)

# 3. PEEK: the door eases open, you lean out: he's at the foot of the bed, his back to you, his long arms hanging
BEDFOOT = [-19.0, U, -15.5]  # (in the middle of the room: the bed side is behind the open leaf)
OUT = [-24.35, U + 5.2, -25.45]
def s_peek(i, k):
    w = ease(i / 40)
    cam = add(lerp(CR, OUT, w), hand(i, 0.2))
    look = lerp(LOOK, [BEDFOOT[0], U + 5.0, BEDFOOT[2]], w)
    return (dict(DARK, shot="room", cam={"pos": cam, "look": look, "fov": 54, "roll": -0.12 * math.sin(w * math.pi) - 0.04 * w}, exposure=6.0, door=CRACK + 0.35 * w, door2=1.35, glow=1.2),
            him(BEDFOOT, facing(BEDFOOT, [-35, U, -12.0]), "Stare", t=2.0 + stop(i)))
shot("peek", 72, s_peek)

# 4. his head snaps right round to you
def s_snap(i, k):
    cam = add(OUT, hand(i, 0.25))
    turn = ease((stop(i, 12) * 30 - 3) / 9)
    back = facing(BEDFOOT, [-35, U, -12.0])
    to = facing(BEDFOOT, OUT)
    yaw = wrap(to - back)
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [BEDFOOT[0], U + 6.2, BEDFOOT[2]], "fov": 50 - 8 * ease(k), "roll": -0.04}, exposure=6.0, door=CRACK + 0.35, door2=1.35, glow=2.2),
            him(BEDFOOT, back, "Stare", t=2.5 + stop(i), Look=[yaw * turn * 1.6, 0.1 * turn]))
shot("snap", 33, s_snap)

# 5. back in, the door pulled to: through the crack, he walks slowly across the room towards you, and past
def s_back(i, k):
    w = ease(i / 18)
    cam = add(lerp(OUT, CR, w), hand(i, 0.15))
    door = CRACK + 0.35 * (1 - w)
    m = ease((i - 14) / 74)
    p = lerp([-19.0, U, -15.5], [-14.0, U, -23.5], m)
    return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp([BEDFOOT[0], U + 5.0, BEDFOOT[2]], [-19.0, U + 4.0, -19.0], ease(i / 40)), "fov": 54}, exposure=6.5, door=door, door2=1.35, glow=1.4),
            him(p, facing(p, [-14, U, -24]), "Walk", phase=m * 3.0 * TAU, t=3.0 + stop(i)))
shot("back", 90, s_back)

# 6. peek again: the room's empty, the bed
def s_empty(i, k):
    w = ease(i / 30)
    cam = add(lerp(CR, OUT, w), hand(i, 0.2))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp(LOOK, [BEDFOOT[0], U + 4.4, BEDFOOT[2]], w), "fov": 54, "roll": -0.1 * math.sin(w * math.pi) - 0.04 * w}, exposure=6.0, door=CRACK + 0.35 * w, door2=1.35), None)
shot("empty", 60, s_empty)

# 7. lean further, turn to the door: open, nobody
OUT2 = [-24.6, U + 5.1, -24.9]
def s_door(i, k):
    w = ease(i / 50)
    cam = add(lerp(OUT, OUT2, w), hand(i, 0.25))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp([BEDFOOT[0], U + 4.4, BEDFOOT[2]], [-9.0, U + 4.6, -10.5], w), "fov": 54, "roll": -0.04}, exposure=6.0, door=CRACK + 0.35 + 0.15 * w, door2=1.35), None)
shot("door", 60, s_door)

# 8. back in. The crack. Nothing. Breathing
def s_wait(i, k):
    w = ease(i / 16)
    cam = add(lerp(OUT2, CR, w), hand(i, 0.12 + 0.08 * math.sin(i * 0.3) ** 2))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": LOOK, "fov": 54}, exposure=6.5, door=CRACK + 0.5 * (1 - w), door2=1.35), None)
shot("wait", 60, s_wait)

# 9. one more look: the door eases out... on 22.15 s (frame 65) he's right there in the gap, bent down to you
GAPAT = [-23.4, U, -18.4]
def s_last(i, k):
    if i < 65:
        w = ease(i / 50)
        cam = add(lerp(CR, OUT, 0.55 * w), hand(i, 0.15))
        return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp(LOOK, [-21.0, U + 4.6, -16.0], w), "fov": 54, "roll": -0.06 * w}, exposure=6.2, door=CRACK + 0.18 * w, door2=1.35), None)
    w = ease((i - 65) / 4)
    cam = add(lerp(CR, OUT, 0.55), [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    p = lerp(GAPAT, [-23.5, U, -19.9], w)
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [p[0], U + 4.2 - 0.6 * w, p[2]], "fov": 60 + 8 * w}, exposure=4.0, door=CRACK + 0.18 + 1.2 * w, door2=1.35, glow=6.0,
                 flash=fl(cam, [p[0], U + 4.6, p[2]], 1.2 * w, 0.5)),
            him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Duck=1.7, Look=[0.0, 0.35]))
shot("last", 75, s_last)

# 10. RUN: out of the wardrobe for the door, looking back: he comes after you on all fours
def s_run(i, k):
    c = lerp([-19.0, 0, -22.0], [-11.0, 0, -12.0], k)
    cam = [c[0] + 0.25 * math.sin(i * 1.7), U + 5.0 + 0.2 * math.sin(i * 2.3), c[2]]
    hp = lerp([-24.5, U, -23.0], [-18.0, U, -18.0], k)
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [hp[0], U + 2.6, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)}, door=1.6, door2=1.35,
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), U + 2.8, hp[2]], 14.0, 0.36), exposure=2.6, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

for _fr in frames:
    if "door" in _fr: _fr["door"] = -_fr["door"]
W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": [],
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
