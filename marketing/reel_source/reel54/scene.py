# Reel 54 — "FIND HIM": a completely new format (30 Oct, the owner: "completely different than everything else... the maximum
# possible amount of views... <35 secs"). Not a story: a spot-the-monster challenge, the kind people rewatch, pause, comment on
# ("found him on 3!") and send to a friend ("bet you can't get level 4"). Four still, dark rooms of the house, each with him
# hidden in it, harder each time; a timer runs out, a red ring snaps onto him and the shot punches in. Level 4 is IMPOSSIBLE:
# only his mask in the black gap of the attic hatch... the ring finds it, and the mask drops at you. Then the end card:
# the game, SEARCH IT ON ROBLOX, "what level did you get to?". The comp is tools/comp_find.mjs; the music reel54/audio.py.
#   L1 EASY        (135)  the front hall: him standing in the dark by the front door
#   L2 MEDIUM      (150)  the bottom of the stairs: him crouched on the landing at the top, looking down
#   L3 HARD        (165)  Lily's room: only the top of his mask over her tent, in the dark corner
#   L4 IMPOSSIBLE  (225)  the upstairs hall: the hatch an inch open, his mask in the gap... it drops at you (the scare)
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau + mask.json), shots.json and
# targets.json (where his face is on screen, per frame: the comp's ring and zoom).
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
TAU = math.tau
S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
W, H = (360, 640) if PREVIEW else (1080, 1920)

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def drift(i, amt=1.0):
    # (almost still: a held phone)
    return [0.025 * amt * math.sin(i * 0.07), 0.02 * amt * math.sin(i * 0.11 + 1), 0.015 * amt * math.sin(i * 0.05 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]
def stop(i, fps=13): return math.floor(i * fps / 30) / fps
def him(pos, yaw, gait="Stare", phase=0.0, t=0.0, **opts):
    return {"pos": {"x": pos[0], "y": pos[1], "z": pos[2]}, "yaw": yaw, "gait": gait, "phase": phase, "t": t, "seed": 4, "opts": opts}

def project(cam, look, fov, p):
    # world point -> screen pixels (three.js PerspectiveCamera: vertical fov, up = +y), or None if behind
    f = [look[i] - cam[i] for i in range(3)]
    fl = math.sqrt(sum(v * v for v in f)); f = [v / fl for v in f]
    r = [f[2] * 0 - f[1] * 0, 0, 0]
    # right = f x up(0,1,0)
    r = [-f[2], 0.0, f[0]]
    rl = math.sqrt(sum(v * v for v in r)); r = [v / rl for v in r]
    u = [r[1] * f[2] - r[2] * f[1], r[2] * f[0] - r[0] * f[2], r[0] * f[1] - r[1] * f[0]]
    d = [p[i] - cam[i] for i in range(3)]
    x, y, z = sum(d[i] * r[i] for i in range(3)), sum(d[i] * u[i] for i in range(3)), sum(d[i] * f[i] for i in range(3))
    if z <= 0.01:
        return None
    t = math.tan(math.radians(fov) / 2)
    nx, ny = x / z / (t * (1080 / 1920)), y / z / t
    return [(nx + 1) / 2 * 1080, (1 - ny) / 2 * 1920]

COLD, MOON, WARM, PINK = "#3d4f7a", "#6f86c4", "#ffb766", "#ff9fc4"
NOCANDY = ["CandyWrap", "CandyBody"]
def sy(z): return max(G, min(U, 2.05 + 0.625 * (z + 5.3) - 1.0))
# --- L1: the front hall (reel 53): x -8..12, z -30..-0.4, floor G; the front door at x 2 in the z = -30 wall
FDOOR = {"near": [2.0, 5.7, -30.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-0.43, 0, -30.0], "axis": "y"}
HALL1 = [{"p": [2, G + 9, -18], "col": COLD, "b": 1.8, "r": 22}, {"p": [8, G + 6, -8], "col": MOON, "b": 2.4, "r": 20},
         {"p": [-6, G + 7, -24], "col": COLD, "b": 0.7, "r": 10}]
# --- L2: the stairs (x ~-5, from the front hall at z -5.3 up to the landing at z 17)
STAIRS = [{"p": [-5, U + 6, 22], "col": "#2c3d6e", "b": 1.3, "r": 26}, {"p": [-5, 8, -2], "col": COLD, "b": 0.9, "r": 18},
          {"p": [2, G + 6, -10], "col": MOON, "b": 1.4, "r": 18}]
# --- L3: Lily's room (reel 51): x 12..40, z 8.5..29.3; her tent at (20.2, 10.6), her night light by the door
LROOM = [{"p": [13.6, U + 2.2, 27.5], "col": PINK, "b": 1.6, "r": 16, "decay": 1.3}, {"p": [26.0, U + 8.0, 31.5], "col": MOON, "b": 3.0, "r": 24, "decay": 1.1},
         {"p": [30.0, U + 8.0, 12.0], "col": COLD, "b": 0.8, "r": 16}]
# --- L4: the upstairs hall and the attic hatch (reel 46): the hole x 4..8, z 8..14 in the ceiling (y 28.15), the panel hinged at z 8
HATCH = {"near": [6.0, 28.0, 11.0], "r": 4.5, "names": ["HatchPanel"], "hinge": [6.0, 28.15, 8.05], "axis": "x"}
HALL4 = [{"p": [2, U + 10, 24], "col": MOON, "b": 3.0, "r": 30, "decay": 1.1}, {"p": [4, U + 8, 17], "col": COLD, "b": 2.0, "r": 14}]
SHOTS = {
    "hall1": {"center": [2, G + 5, -16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": HALL1},
    "stairs": {"center": [-5, G + 8, 4], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": STAIRS},
    "lily": {"center": [24, U + 5, 19], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": LROOM, "hide": ["Bulb", "Globe", "Base", "Finial"]},
    "hall4": {"center": [5, U + 6, 14], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "lights": HALL4, "hide": ["Cord", "CordHandle", "HatchPanel"]},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}

frames, crs, shots, targets = [], [], [], {}
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
    for i in range(n):
        k = i / max(1, n - 1)
        fr, cr, tgt = fn(i, k)
        # (where his face is on screen: every frame, for the comp's ring)
        if tgt is not None:
            pt = project(fr["cam"]["pos"], fr["cam"]["look"], fr["cam"]["fov"], tgt)
            if pt: targets[f + i] = [round(pt[0], 1), round(pt[1], 1)]
        if PREVIEW and i not in idx:
            continue
        fr["f"] = f + i
        fr["creature"] = cr is not None
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n

# L1 EASY: the front hall, him standing in the dark corner by the front door, facing you
L1 = [-2.6, G, -25.0]
def s_l1(i, k):
    cam = add([5.6, G + 5.6, -6.5], drift(i))
    look = [0.6, G + 4.6, -30.0]
    return (dict(DARK, shot="hall1", cam={"pos": cam, "look": look, "fov": 58}, exposure=2.9, door=0.0, glow=0.7),
            him(L1, facing(L1, cam), "Stare", t=2.0 + stop(i), Look=[0.0, -0.1]), [L1[0] + 0.3, G + 8.8, L1[2]])
shot("L1", 135, s_l1)

# L2 MEDIUM: from the bottom of the stairs: him crouched at the top, only his head and shoulders over the top step
L2 = [-5.0, U, 18.4]
def s_l2(i, k):
    cam = add([-5.2, G + 5.4, -8.5], drift(i))
    look = [-5.0, U + 1.5, 14.0]
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": look, "fov": 56}, exposure=2.4, glow=0.6),
            him(L2, facing(L2, cam), "Stare", t=3.0 + stop(i), Duck=1.4, Look=[0.0, -0.5]), [L2[0], U + 7.2, L2[2] - 1.0])
shot("L2", 150, s_l2)

# L3 HARD: Lily's room from her door: the top of his mask over her tent, in the far dark corner (no glow)
L3 = [19.6, U, 8.9]
def s_l3(i, k):
    cam = add([14.2, U + 5.4, 24.0], drift(i))
    look = [21.5, U + 3.6, 12.0]
    return (dict(DARK, shot="lily", cam={"pos": cam, "look": look, "fov": 60}, exposure=2.9, glow=0.0),
            him(L3, facing(L3, cam), "Stare", t=4.0 + stop(i), Duck=1.0, Look=[0.0, -0.2]), [L3[0], U + 7.8, L3[2] + 0.4])
shot("L3", 165, s_l3)

# L4 IMPOSSIBLE: the upstairs hall under the open hatch: his mask far up in the black of the attic, unlit (only the mask: his body is the attic)
CAM4 = [4.8, U + 5.4, 23.0]
LOOK4 = [6.0, U + 14.5, 4.0]
GAP = [7.2, 30.2, 10.0]
def s_l4(i, k):
    cam = add(CAM4, drift(i) if i < 195 else [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    look = LOOK4
    if i < 195:
        # (it hangs there, looking down at you; the comp's ring finds it at 165, then punches in)
        cr = him([6.0, U, 0.0], 0.0, "Stare", t=3.0 + stop(i))
        cr["head"] = {"pos": GAP, "look": [cam[0], cam[1], cam[2]], "roll": 0.5}
        cr["noSkin"] = True
        return (dict(DARK, shot="hall4", cam={"pos": cam, "look": look, "fov": 56}, exposure=2.8, door=-math.pi / 2, glow=0.0), cr, GAP)
    # the drop: the mask falls out of the gap and lunges at you, jaw open
    w = ease((i - 195) / 6)
    p = lerp(GAP, [cam[0] + 0.05, cam[1] + 0.15, cam[2] - 1.6], w)
    cr = him([6.0, U, 0.0], 0.0, "Reach", t=3.0 + i / FPS, Scream=1.0)
    cr["head"] = {"pos": p, "look": [cam[0], cam[1] + 0.1, cam[2]], "roll": 0.5 * (1 - w)}
    cr["noSkin"] = True
    return (dict(DARK, shot="hall4", cam={"pos": cam, "look": lerp(look, p, 0.8 * w), "fov": 56 + 10 * w}, exposure=2.4, door=-math.pi / 2,
                 glow=4.0, flash={"i": 10.0, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": p, "angle": 0.45}), cr, None)
shot("L4", 225, s_l4)

json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": [],
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
json.dump(targets, open("targets.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
