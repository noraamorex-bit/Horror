# Reel 53 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #8" (the new run, after #7 = reel 52, mom's texts: 50K). #2's exact format,
# music and slot lengths; another everyday hook in #7's spirit: the doorbell camera. Every night at 3 am it goes off, and every
# night he's closer: at the end of the walk, on the steps, bent down to the lens... tonight it went off again: the porch was
# empty, the front door was open, and he was already inside. The masked v114 look, as in the game; the camera shots go through
# comp_cantplay's doorbell-cam overlay (edit.py: fr.cam).
#   hook (105)  the front hall, the lamps on, cosy
#   card (120)  the same hall in the dark, a slow push to the front door
#   72  "night 30: the doorbell cam. 3 am."   the camera's view: him standing at the end of the front walk in the rain
#   33  "night 31: closer."                    the camera: him on the porch steps
#   90  "night 32: he looked right at it."     the camera: him bent down to the lens, his mask filling the top
#   60  "tonight it went off again."           my phone in my hand, the doorbell's notification on it
#   60  "the porch was empty."                 the camera: the empty porch, the rain
#   60  "the front door was open."             from the stairs: the door wide open on the night
#   75  "he was already inside."               turn round: him in the hall behind me; the mask lunges (22.15 s)
#   30  "RUN."                                 out onto the porch, him coming through the door after me
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

COLD, MOON, WARM, SCREEN = "#3d4f7a", "#6f86c4", "#ffb766", "#bcd2ff"
# --- the front of the house: the front door at x 2 in the z = -30 wall (x -0.4..4.4, hinged at x -0.43, it swings in); the porch
# deck x -5..9, z -38..-30.6 (top y 1.0), its steps down at z -38.5..-39; the walk x 0..4 from z -40 to the sidewalk at z -62
# (top y 0.6); the porch lamp at (-1.2, 8, -31.3). The front hall inside: x -8..12, z -30..-0.4, floor G; the stairs at x -5
# climb from z -5.3 to the landing at z 17.
FDOOR = {"near": [2.0, 5.7, -30.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-0.43, 0, -30.0], "axis": "y"}
DOORCAM = [4.9, 6.0, -30.95]                # the doorbell camera, beside the door
CAMLOOK = [2.0, 3.6, -42.0]
PORCHLAMP = {"p": [-1.2, 7.3, -31.5], "col": WARM, "b": 1.6, "r": 14, "decay": 1.3}
OUTSIDE = [PORCHLAMP, {"p": [2, 30, -60], "col": MOON, "b": 2.0, "r": 70, "decay": 0.8}, {"p": [12, 6, -50], "col": COLD, "b": 1.0, "r": 24}]
INSIDE = [{"p": [2, G + 9, -20], "col": COLD, "b": 1.0, "r": 18}, {"p": [2, G + 6, -34], "col": MOON, "b": 2.2, "r": 18, "decay": 1.1},
          {"p": [-5, U + 6, 10], "col": "#2c3d6e", "b": 1.0, "r": 22}]
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [4, U + 8, 4], "col": COLD, "b": 1.2, "r": 16}]
def sy(z): return max(G, min(U, 2.05 + 0.625 * (z + 5.3) - 1.0))
NOCANDY = ["CandyWrap", "CandyBody"]
def glowAt(p, b=1.4, r=5.0): return {"p": [p[0], p[1] + 0.7, p[2]], "col": SCREEN, "b": b, "r": r, "decay": 1.6}
HANDCAM = [4.2, U + 5.3, 26.4]              # (the upstairs hall, as in reel 52: my phone in my hand)
SHOTS = {
    "lit": {"center": [2, G + 5, -16], "radius": 30, "lampRadius": 30, "maxLamps": 8, "door": FDOOR},
    "hallDark": {"center": [2, G + 5, -16], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": INSIDE},
    "porch": {"center": [2, G + 4, -42], "radius": 40, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": OUTSIDE},
    "hand": {"center": [4, U + 6, 16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": HALL + [glowAt([4.3, U + 4.8, 25.1], 1.0, 3.5)]},
    "openDoor": {"center": [0, G + 6, -14], "radius": 40, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": INSIDE + OUTSIDE},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}
OPENDOOR = 1.45
NIGHTFOG = {"fog": [30, 90], "bg": 0x0b0d12}

# --- props (film2 extras): my phone in my hand, the doorbell's notification on it (a grey video still and a red dot)
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
HPH = []
BODY = [18, 18, 20]
HP = [HANDCAM[0] + 0.1, HANDCAM[1] - 0.3, HANDCAM[2] - 1.25]
TH = math.atan2(HANDCAM[2] - HP[2], HANDCAM[1] - HP[1])
N = [0.0, math.cos(TH), math.sin(TH)]
ZL = [0.0, -math.sin(TH), math.cos(TH)]
def at(dx, dz, h): return [HP[0] + dx + N[0] * h + ZL[0] * dz, HP[1] + N[1] * h + ZL[1] * dz, HP[2] + N[2] * h + ZL[2] * dz]
ROT = [TH, 0.0, 0.0]
ex(HPH, {"pos": HP, "s": [0.25, 0.03, 0.47], "rot": ROT, "col": BODY, "rough": 0.3})
ex(HPH, {"pos": at(0, 0, 0.017), "s": [0.22, 0.004, 0.42], "rot": ROT, "col": [30, 44, 78], "emissive": [40, 62, 120], "ei": 0.5, "rough": 0.2})
ex(HPH, {"pos": at(0, -0.06, 0.021), "s": [0.2, 0.003, 0.15], "rot": ROT, "col": [96, 98, 102], "emissive": [90, 92, 96], "ei": 0.6})       # the video still
ex(HPH, {"pos": at(-0.075, -0.12, 0.024), "s": [0.025, 0.003, 0.025], "rot": ROT, "col": [255, 40, 40], "emissive": [255, 40, 40], "ei": 1.4})  # its red dot
ex(HPH, {"pos": at(0, 0.07, 0.021), "s": [0.17, 0.003, 0.04], "rot": ROT, "col": [200, 204, 214], "emissive": [190, 196, 210], "ei": 0.7})   # "Front Door: someone's there"
ALL = set(range(len(extras)))
def only(*groups):
    keep = set().union(*[set(g) for g in groups]) if groups else set()
    return sorted(ALL - keep)

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
        fr.setdefault("hideIdx", only())
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}
def doorcam(i, extra=None, look=None):
    # the doorbell camera's frame: a wide lens, perfectly still, its own infrared light on the porch (the comp makes it grey)
    lk = look or CAMLOOK
    ir = {"i": 9.0, "pos": [DOORCAM[0], DOORCAM[1] - 0.3, DOORCAM[2] - 0.2], "target": [lk[0], 2.0, lk[2] + 4.0], "angle": 1.0}
    fr = dict(DARK, shot="porch", cam={"pos": DOORCAM, "look": lk, "fov": 98}, exposure=2.4, lamps=0, door=0.0, flash=ir, **NIGHTFOG)
    if extra: fr.update(extra)
    return fr

# 1. (hook) the front hall, lamps on: cosy
def s_hook(i, k):
    cam = add(lerp([6.5, G + 5.8, -6.0], [5.5, G + 5.6, -9.0], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([1.0, G + 4.2, -30.0], [1.6, G + 4.2, -30.0], ease(k)), "fov": 60}, door=0.0), None)
shot("hook", 105, s_hook)

# 2. (card) the same hall in the dark, a slow push to the front door
def s_card(i, k):
    cam = add(lerp([6.0, G + 5.8, -6.5], [4.4, G + 5.5, -13.0], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="hallDark", cam={"pos": cam, "look": [2.0, G + 4.2, -30.0], "fov": 58}, exposure=3.2, lamps=0, door=0.0), None)
shot("card", 120, s_card)

# 3. "night 30: the doorbell cam. 3 am." him at the end of the front walk, in the rain, looking at the house
FAR = [2.0, 0.6, -55.0]
def s_far(i, k):
    return (doorcam(i, {"glow": 2.6}), him(FAR, facing(FAR, DOORCAM), "Stare", t=2.0 + stop(i), Look=[0.0, 0.15]))
shot("door", 72, s_far)

# 4. "night 31: closer." on the porch steps
STEPS = [2.4, 1.0, -37.7]
def s_steps(i, k):
    return (doorcam(i, {"glow": 2.0}, [2.2, 6.0, -42.0]), him(STEPS, facing(STEPS, DOORCAM), "Stare", t=3.0 + stop(i), Look=[0.0, 0.3]))
shot("prints", 33, s_steps)

# 5. "night 32: he looked right at it." bent down to the lens, closer and closer, the head laid over
def s_lens(i, k):
    p = lerp([3.1, 1.0, -36.2], [3.7, 1.0, -35.1], ease(k))
    return (doorcam(i, {"glow": 1.6}, [3.0, 7.0, -42.0]),
            him(p, facing(p, DOORCAM), "Stare", t=4.0 + stop(i), Duck=1.5, Look=[0.0, -0.35 - 0.2 * ease(k)]))
shot("photo", 90, s_lens)

# 6. "tonight it went off again." my phone in my hand, the doorbell's notification on it
def s_notify(i, k):
    cam = add(HANDCAM, hand(i, 0.08))
    return (dict(DARK, shot="hand", cam={"pos": cam, "look": [4.6, U + 4.0, 20.0], "fov": 58}, exposure=2.4, lamps=0, hideIdx=only(HPH)), None)
shot("setup", 60, s_notify)

# 7. "the porch was empty." the camera: nobody, the rain
def s_empty(i, k):
    return (doorcam(i), None)
shot("open", 60, s_empty)

# 8. "the front door was open." from the stairs, the door wide open on the night
def s_open(i, k):
    cam = add(lerp([-4.8, sy(4.0) + 5.4, 4.0], [-4.8, sy(1.0) + 5.4, 1.0], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="openDoor", cam={"pos": cam, "look": [1.6, G + 4.6, -30.0], "fov": 50}, exposure=2.6, lamps=0, door=OPENDOOR,
                 flash=fl(cam, [1.6, G + 3.0, -26.0], 6.0, 0.3)), None)
shot("stood", 60, s_open)

# 9. "he was already inside." at the open door, turn round: he's in the hall behind me... and he comes on 22.15 s (frame 64)
CAM9 = [2.2, G + 5.4, -22.5]
BEHIND = [1.8, G, -17.0]
def s_behind(i, k):
    cam = add(CAM9, hand(i, 0.3 if i < 64 else 1.0))
    t = ease((i - 12) / 26)
    y0, y1 = facing(cam, [2.0, G, -40.0]), facing(cam, BEHIND)
    yaw = y0 + wrap(y1 - y0) * t
    ly = (G + 4.4) + ((G + 8.3) - (G + 4.4)) * ease((i - 26) / 18)
    look = [cam[0] - math.sin(yaw) * 6.0, ly, cam[2] - math.cos(yaw) * 6.0]
    torch = fl(cam, [look[0], look[1] - 0.6, look[2]], 6.0, 0.4)
    if i < 64:
        return (dict(DARK, shot="openDoor", cam={"pos": cam, "look": look, "fov": 64}, exposure=2.6, lamps=0, door=OPENDOOR, flash=torch,
                     glow=2.2 if t > 0.5 else 0.4),
                him(BEHIND, facing(BEHIND, cam), "Stare", t=3.0 + stop(i), Duck=0.2, Look=[0.0, -0.3], Scream=0.15 * ease((i - 54) / 10)))
    w = ease((i - 64) / 4)
    near = [cam[0] - 0.1, G, cam[2] + 4.6]
    p = lerp(BEHIND, near, w)
    shake = [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0]
    return (dict(DARK, shot="openDoor", cam={"pos": add(cam, shake), "look": lerp(look, [p[0], G + 8.8, p[2]], w), "fov": 64 + 10 * w}, exposure=2.6,
                 lamps=0, door=OPENDOOR, glow=6.0, flash=fl(cam, [p[0], G + 7.5, p[2]], 12.0, 0.45)),
            him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Duck=1.0 * w, Look=[0.0, -0.45]))
shot("knew", 75, s_behind)

# 10. RUN: out onto the porch, looking back: he comes through the door after me
def s_run(i, k):
    cam = [2.0 + 0.25 * math.sin(i * 1.7), 1.0 + 4.8 + 0.2 * math.sin(i * 2.3), -32.5 - 6.0 * k]
    hp = lerp([2.0, G, -22.0], [2.0, 1.0, -30.5], k)
    return (dict(DARK, shot="openDoor", cam={"pos": cam, "look": [hp[0], G + 3.0, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 door=OPENDOOR, flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), G + 3.2, hp[2]], 16.0, 0.36), ambient=0.01, exposure=2.0, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
