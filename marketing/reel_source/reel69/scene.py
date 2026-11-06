# Reel 69 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 7)": the PEAK run on #2's track, the first reel of the v145
# house (Doors' hotel look: walnut wainscoting in raised panels, burgundy damask, brass chandeliers, the walnut stair). The
# front hall at night, its chandeliers on; past the family photos to Grandma's portrait, her face gouged out. The lights
# stutter out. At the top of the stairs he's crouched on the last step, head cocked. He comes down the stairs head first.
# Backing down the hall, him after you. Down by the bench in the foyer: he crawls into the moonlight at the foot of the
# stairs, stops, his head turns... he goes into the living room. Silence. Look up: he's standing over you (22.15 s). RUN.
#   hook (105)  the front hall, chandeliers and sconces on: the walnut, the damask, the photos
#   card (120)  along the family photos to Grandma's gouged portrait (played at 0.64)
#   72          the lights stutter out; the stairs: him crouched on the top step, head cocked
#   33          he comes down the stairs head first
#   90          backing down the hall: him after you
#   60          down by the foyer bench, the hall in moonlight, empty
#   60          he crawls into the moonlight at the foot of the stairs, sniffing
#   60          he stops; his head comes round; he goes off into the living room
#   75          silence; look up: he's over you, bent down (22.15 s)
#   30          RUN for the back hall, him after you
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
# the main stair: x -8..-2, from z -6 (y 1) up to z 16.4 (y 15)
def stairY(z): return G + max(0.0, min(1.0, (z + 6.0) / 22.4)) * 14.0

COLD, MOON = "#3d4f7a", "#6f86c4"
HIDE = ["CandyWrap", "CandyBody"]
# the front hall: x -8..12, z -30..30; the front door at x 2 in the z -30 wall (its side lights let the moon in)
HALLD = [{"p": [2, G + 8, -33], "col": MOON, "b": 2.8, "r": 34, "decay": 1.0}, {"p": [-5, U + 6, 20], "col": COLD, "b": 1.4, "r": 22},
         {"p": [0, G + 9, 27], "col": "#2c3d6e", "b": 1.2, "r": 20}, {"p": [9, G + 7, -3], "col": COLD, "b": 0.7, "r": 14},
         {"p": [-1.0, G + 7, -9.0], "col": MOON, "b": 1.6, "r": 18}, {"p": [6.5, G + 6, -20.0], "col": COLD, "b": 0.8, "r": 12}]
SHOTS = {
    "lit": {"center": [1, G + 5, -6], "radius": 40, "lampRadius": 40, "maxLamps": 14},
    "photos": {"center": [3, G + 6, 8], "radius": 30, "lampRadius": 30, "maxLamps": 12, "hide": [{"near": [4.4, 8.2], "r": 0.8}]},
    "hall": {"center": [0, G + 5, -4], "radius": 42, "lampRadius": 0, "maxLamps": 0, "lights": HALLD},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + HIDE
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.2, "lamps": 1}

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

# 1. (hook) the front hall from the foyer, lit: the chandeliers, the walnut stair, the runner, the photos
def s_hook(i, k):
    cam = add(lerp([3.6, G + 5.6, -27.0], [3.2, G + 5.5, -22.0], ease(k)), hand(i, 0.5))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([0.5, G + 5.6, 6.0], [0.0, G + 5.4, 10.0], ease(k)), "fov": 64}), None)
shot("hook", 105, s_hook)

# 2. (card) along the family photos on the stairwell wall (x = 6) to Grandma's portrait, her face gouged out
def s_card(i, k):
    cam = add(lerp([1.6, G + 7.6, 1.0], [2.2, G + 7.7, 11.6], ease(k)), hand(i, 0.4))
    look = lerp([5.6, G + 7.2, 6.0], [5.6, G + 7.0, 16.4], ease(k))
    return (dict(LIT, shot="photos", cam={"pos": cam, "look": look, "fov": 50 - 6 * ease(k)}), None)
shot("card", 120, s_card)

# 3. the lights stutter out; turn to the stair: at the top he's crouched on the last step, head cocked, quite still
TOP = [-5.0, stairY(14.6), 14.6]
CAM3 = [2.2, G + 5.4, -5.0]
FLICK = [(0, 8, True), (8, 11, False), (11, 13, True), (13, 18, False), (18, 20, True)]
def s_far(i, k):
    cam = add(lerp(CAM3, [1.6, G + 5.3, -3.6], ease(k)), hand(i, 0.3))
    on = any(a <= i < b and v for a, b, v in FLICK)
    look = lerp([4.6, G + 6.6, 14.0], [-4.8, TOP[1] + 2.4, 13.8], ease((i - 10) / 22))
    cr = him(TOP, facing(TOP, cam), "Chase", phase=0.9 + 0.04 * math.sin(i * 0.2), t=2.0 + stop(i))
    if on:
        return (dict(LIT, shot="lit", cam={"pos": cam, "look": look, "fov": 56}), cr)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 56 - 10 * ease((i - 24) / 40)}, exposure=2.8, glow=2.2,
                 flash=fl(cam, [-4.8, TOP[1] + 2.0, 13.8], 14.0 * ease((i - 20) / 8), 0.2)), cr)
shot("far", 72, s_far)

# 4. he comes down the stairs head first, fast
def s_comes(i, k):
    cam = add([1.6, G + 5.3, -3.6], [0.08 * math.sin(i * 1.9) * k, 0.06 * math.sin(i * 2.3) * k, 0])
    z = 14.6 - 17.5 * k
    p = [-5.0, stairY(z), z]
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [p[0], p[1] + 2.6, p[2]], "fov": 48 + 10 * k}, exposure=2.8, glow=3.0,
                 flash=fl(cam, [p[0], p[1] + 2.2, p[2]], 14.0, 0.24)),
            him(p, facing(p, [p[0], p[1], p[2] - 4]), "Chase", phase=0.9 + k * 3.2 * TAU, t=4.0 + i / FPS))
shot("comes", 33, s_comes)

# 5. backing down the hall towards the foyer, looking at him: he comes off the stair and after you along the runner
def s_chase(i, k):
    cz = -6.0 - 15.0 * k
    cam = [1.8 + 0.22 * math.sin(i * 1.7), G + 5.0 + 0.18 * math.sin(i * 2.3), cz]
    hz = lerp([0, 0, -2.8], [0, 0, -15.0], k)[2]
    hx = lerp([-4.6, 0, 0], [1.4, 0, 0], ease(k * 1.6))[0]
    hp = [hx, stairY(hz), hz]
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [hp[0], G + 2.6, hp[2]], "fov": 66, "roll": 0.05 * math.sin(i * 0.9)}, exposure=2.4,
                 glow=4.0, flash=fl(cam, [hp[0] + 0.5 * math.sin(i * 1.3), G + 2.6, hp[2]], 14.0, 0.36)),
            him(hp, facing(hp, cam), "Chase", phase=k * 9.0 * TAU, t=5.0 + i / FPS))
shot("chase", 90, s_chase)

# 6. down by the foyer bench: the hall up to the stair foot in moonlight, empty
CORNER = [9.4, G + 2.5, -23.4]
LOOK6 = [-1.5, G + 2.4, -5.0]
def s_corner(i, k):
    cam = add(CORNER, hand(i, 0.25 + 0.2 * math.sin(i * 0.3) ** 2))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": LOOK6, "fov": 60}, exposure=6.0), None)
shot("corner", 60, s_corner)

# 7. he crawls into the moonlight at the foot of the stairs, sniffing, low
def s_door(i, k):
    cam = add(CORNER, hand(i, 0.3))
    w = ease(i / 59)
    p = lerp([-5.0, G, -3.0], [-2.2, G, -8.6], w)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": lerp(LOOK6, [p[0], G + 2.2, p[2]], 0.6), "fov": 58}, exposure=6.0, glow=1.8),
            him(p, facing(p, [p[0] + 1.5, G, p[2] - 4]), "Chase", phase=w * 1.6 * TAU, t=6.0 + stop(i)))
shot("door", 60, s_door)

# 8. he stops; his head comes round towards the foyer... then he turns and goes off through the arch into the living room
MID = [-2.2, G, -8.6]
def s_in(i, k):
    cam = add(CORNER, hand(i, 0.3))
    look = [MID[0], G + 2.4, MID[2]]
    if i < 34:
        turn = ease((stop(i) * 30 - 6) / 16)
        y0, y1 = facing(MID, [MID[0] + 1.5, G, MID[2] - 4]), facing(MID, CORNER)
        cr = him(MID, y0 + wrap(y1 - y0) * turn * 0.8, "Chase", phase=1.6 * TAU, t=7.0 + stop(i))
    else:
        w = ease((i - 34) / 25)
        p = lerp(MID, [-9.5, G, -12.6], w)
        cr = him(p, facing(MID, [-9.5, G, -12.6]), "Chase", phase=1.6 * TAU + w * 2.2 * TAU, t=8.0 + i / FPS)
        look = lerp(look, [-7.0, G + 2.4, -11.8], w * 0.7)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 58}, exposure=6.0, glow=1.6), cr)
shot("in", 60, s_in)

# 9. silence, the hall empty; a creak; look up: he's standing over you, bent down, his mask at your face; on 22.15 s
# (frame 65) he comes
OVER = [5.7, G, -18.9]
def s_over(i, k):
    cam = add(CORNER, hand(i, 0.3))
    t = ease((i - 26) / 20)
    look = lerp([-6.0, G + 2.4, -11.0], [OVER[0] + 0.3, G + 6.0, OVER[2] - 0.3], t)
    if i < 65:
        cr = him(OVER, facing(OVER, cam), "Stare", t=3.0 + stop(i), Duck=2.1, Look=[0.0, -0.6], Scream=0.15 * ease((i - 55) / 10)) if t > 0.15 else None
        return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 64}, exposure=5.0, glow=2.4 if t > 0.5 else 0.5), cr)
    w = ease((i - 65) / 5)
    camw = add(cam, [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    return (dict(DARK, shot="hall", cam={"pos": camw, "look": lerp(look, [OVER[0] + 0.6, G + 3.8, OVER[2] - 0.6], w), "fov": 64 + 8 * w}, exposure=3.6, glow=6.0,
                 flash=fl(camw, [OVER[0], G + 4.6, OVER[2]], 8.0, 0.5)),
            him(lerp(OVER, [6.0, G, -19.3], w), facing(OVER, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Duck=2.1 + 0.3 * w, Look=[0.0, -0.6]))
shot("knew", 75, s_over)

# 10. RUN: up the hall for the back hall, looking back: he comes after you
def s_run(i, k):
    c = lerp([5.0, 0, -15.0], [8.4, 0, -8.0], k)
    cam = [c[0] + 0.25 * math.sin(i * 1.7), G + 5.0 + 0.2 * math.sin(i * 2.3), c[2]]
    hp = lerp([7.6, G, -22.5], [7.0, G, -16.5], k)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [hp[0], G + 2.6, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), G + 2.8, hp[2]], 14.0, 0.36), exposure=2.2, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": [],
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
