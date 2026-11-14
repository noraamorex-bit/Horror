# Reel 77 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #4" (14 Nov), #4 of the new run (74-76 = #1-#3): the doorbell camera (the
# second-best everyday hook, 12.6K) turned round: it doesn't catch him coming in, it catches him LEAVING, every morning, and coming
# back at night with his own key. Tonight he didn't leave. #2's exact format, look, music and slot lengths, cut fast; the v157
# house and his v156 body (the gaunt man).
#   hook (105)  the front hall, lamps on, cosy
#   card (120)  the same hall in the dark, a slow push to the front door
#   72  "night 15: the doorbell cam. 6 am."     the camera: our front door opens from inside | him walking away down the walk
#   33  "he left every morning."                the camera: the empty walk in the grey morning
#   90  "night 16: 11 pm. he came back."        the camera: him at the end of the walk, coming | on the steps | at the door
#   60  "with his own key."                     the knob, close: a key in the lock, turning | the door shutting behind him
#   60  "tonight he didn't leave."              my phone in my hand: the doorbell's still | the camera: the empty porch, morning
#   60  "he's still inside."                    from the hall: the front door shut, nobody | the stairs going up into the dark
#   75  "he's been upstairs all day."           the bottom of the stairs, looking up: nothing | the torch up again: he's crouched
#                                               on the stairs... and comes down at you on 22.15 s (slot frame 64)
#   30  "RUN."                                  out the front door onto the porch, looking back: him through the door after you
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

COLD, MOON, WARM, SCREEN = "#3d4f7a", "#6f86c4", "#ffb766", "#bcd2ff"
# the front of the house (reel 53): the front door at x 2 in the z = -30 wall (x -0.4..4.4, hinged at x -0.43, it swings in);
# the porch deck x -5..9, z -38..-30.6 (top y 1.0), its steps down at z -38.5..-39; the walk x 0..4 from z -40 to the sidewalk
# at z -62 (top y 0.6). The front hall inside: x -8..12, z -30..-0.4, floor G; the stairs at x -5 climb from z -5.3 to z 17.
FDOOR = {"near": [2.0, 5.7, -30.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-0.43, 0, -30.0], "axis": "y"}
DOORCAM = [4.9, 6.0, -30.95]
CAMLOOK = [2.0, 3.6, -42.0]
PORCHLAMP = {"p": [-1.2, 7.3, -31.5], "col": WARM, "b": 1.6, "r": 14, "decay": 1.3}
OUTSIDE = [PORCHLAMP, {"p": [2, 30, -60], "col": MOON, "b": 2.0, "r": 70, "decay": 0.8}, {"p": [12, 6, -50], "col": COLD, "b": 1.0, "r": 24}]
DAWN = [{"p": [2, 40, -70], "col": "#8a97b8", "b": 3.0, "r": 120, "decay": 0.6}, {"p": [12, 8, -46], "col": "#6c7898", "b": 1.4, "r": 30}]
INSIDE = [{"p": [2, G + 9, -20], "col": COLD, "b": 1.0, "r": 18}, {"p": [2, G + 6, -34], "col": MOON, "b": 2.2, "r": 18, "decay": 1.1},
          {"p": [-5, U + 6, 10], "col": "#2c3d6e", "b": 1.0, "r": 22}]
STAIRL = [{"p": [-5, U + 6, 22], "col": "#2c3d6e", "b": 1.3, "r": 26}, {"p": [-5, 8, -2], "col": COLD, "b": 0.8, "r": 18},
          {"p": [-5, G + 7, -11], "col": MOON, "b": 1.4, "r": 14}]
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [4, U + 8, 4], "col": COLD, "b": 1.2, "r": 16}]
def sy(z): return max(G, min(U, 2.05 + 0.625 * (z + 5.3) - 1.0))
NOCANDY = ["CandyWrap", "CandyBody"]
def glowAt(p, b=1.4, r=5.0): return {"p": [p[0], p[1] + 0.7, p[2]], "col": SCREEN, "b": b, "r": r, "decay": 1.6}
HANDCAM = [4.2, U + 5.3, 26.4]
SHOTS = {
    "lit": {"center": [2, G + 5, -16], "radius": 30, "lampRadius": 30, "maxLamps": 8, "door": FDOOR},
    "hallDark": {"center": [2, G + 5, -16], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": INSIDE},
    "porch": {"center": [2, G + 4, -42], "radius": 40, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": OUTSIDE},
    "dawn": {"center": [2, G + 4, -42], "radius": 40, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": DAWN},
    "hand": {"center": [4, U + 6, 16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": HALL + [glowAt([4.3, U + 4.8, 25.1], 1.0, 3.5)]},
    "openDoor": {"center": [0, G + 6, -14], "radius": 40, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": INSIDE + OUTSIDE},
    "stairs": {"center": [-5, G + 8, 4], "radius": 40, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": STAIRL + INSIDE},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}
OPENDOOR = 1.45
NIGHTFOG = {"fog": [30, 90], "bg": 0x0b0d12}
MORNFOG = {"fog": [24, 80], "bg": 0x3a4050}

# --- props (film2 extras): my phone in my hand (the doorbell's still on it); his key in our lock
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
HPH, KEY = [], []
BODY = [18, 18, 20]
HP = [HANDCAM[0] + 0.1, HANDCAM[1] - 0.3, HANDCAM[2] - 1.25]
TH = math.atan2(HANDCAM[2] - HP[2], HANDCAM[1] - HP[1])
N = [0.0, math.cos(TH), math.sin(TH)]
ZL = [0.0, -math.sin(TH), math.cos(TH)]
def at(dx, dz, h): return [HP[0] + dx + N[0] * h + ZL[0] * dz, HP[1] + N[1] * h + ZL[1] * dz, HP[2] + N[2] * h + ZL[2] * dz]
ROT = [TH, 0.0, 0.0]
ex(HPH, {"pos": HP, "s": [0.25, 0.03, 0.47], "rot": ROT, "col": BODY, "rough": 0.3})
ex(HPH, {"pos": at(0, 0, 0.017), "s": [0.22, 0.004, 0.42], "rot": ROT, "col": [30, 44, 78], "emissive": [40, 62, 120], "ei": 0.5, "rough": 0.2})
ex(HPH, {"pos": at(0, -0.06, 0.021), "s": [0.2, 0.003, 0.15], "rot": ROT, "col": [96, 98, 102], "emissive": [90, 92, 96], "ei": 0.6})
ex(HPH, {"pos": at(-0.075, -0.12, 0.024), "s": [0.025, 0.003, 0.025], "rot": ROT, "col": [255, 40, 40], "emissive": [255, 40, 40], "ei": 1.4})
ex(HPH, {"pos": at(0, 0.07, 0.021), "s": [0.17, 0.003, 0.04], "rot": ROT, "col": [200, 204, 214], "emissive": [190, 196, 210], "ei": 0.7})
# the key in the lock, under the knob on the outside face: the bow (turns), the blade into the door
LOCK = [3.75, 4.15, -30.32]
BRASS = [168, 136, 70]
def key_bow(a):
    return {"pos": [LOCK[0], LOCK[1], LOCK[2] - 0.22], "s": [0.2, 0.17, 0.03], "rot": [0, 0, a], "col": BRASS, "rough": 0.3, "metal": 0.8}
ex(KEY, key_bow(0.0)); KEYBOW = KEY[-1]
ex(KEY, {"pos": [LOCK[0], LOCK[1], LOCK[2] - 0.08], "s": [0.05, 0.04, 0.2], "col": BRASS, "rough": 0.3, "metal": 0.8})
ex(KEY, {"shape": "cyl", "pos": [LOCK[0], LOCK[1], LOCK[2] - 0.01], "s": [0.14, 0.03, 0.14], "rot": [math.pi / 2, 0, 0], "col": [120, 100, 60], "rough": 0.3, "metal": 0.8})
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
def doorcam(i, extra=None, look=None, morning=False):
    # the doorbell camera: a wide lens, perfectly still; at night its own infrared light on the porch (the comp makes it grey)
    lk = look or CAMLOOK
    cp = PORCHCAM if look is DOORVIEW else DOORCAM
    tg = lk if look is DOORVIEW else [lk[0], 2.0, lk[2] + 4.0]
    ir = {"i": 3.0 if morning else 9.0, "pos": [cp[0], cp[1] - 0.3, cp[2] - 0.2], "target": tg, "angle": 1.0}
    fr = dict(DARK, shot="dawn" if morning else "porch", cam={"pos": cp, "look": lk, "fov": 80 if look is DOORVIEW else 98}, exposure=2.4, lamps=0, door=0.0, flash=ir,
              **(MORNFOG if morning else NIGHTFOG))
    if morning: fr["ambient"] = 0.08
    if extra: fr.update(extra)
    return fr

# hook: the front hall, lamps on, cosy
def s_hook(i, k):
    cam = add(lerp([6.5, G + 5.8, -6.0], [5.5, G + 5.6, -9.0], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([1.0, G + 4.2, -30.0], [1.6, G + 4.2, -30.0], ease(k)), "fov": 60}, door=0.0), None)
shot("hook", 105, s_hook)
# card: the same hall in the dark, a slow push to the front door
def s_card(i, k):
    cam = add(lerp([6.0, G + 5.8, -6.5], [4.4, G + 5.5, -13.0], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="hallDark", cam={"pos": cam, "look": [2.0, G + 4.2, -30.0], "fov": 58}, exposure=3.2, lamps=0, door=0.0), None)
shot("card", 120, s_card)

# 1a. the doorbell camera, 6 am: our front door opens from inside (the camera looks across the porch at it)
DOORVIEW = [1.6, 3.4, -30.0]
PORCHCAM = [8.2, 9.0, -37.8]       # (the porch camera, up in the porch corner: it sees the door)
def s_dopen(i, k):
    d = OPENDOOR * ease(i / 14)
    st = ease((i - 10) / 14)
    p = lerp([1.8, G, -27.0], [2.2, 1.0, -32.6], st)
    cr = him(p, facing(p, [2.2, 1.0, -45.0]), "Walk", phase=st * 1.4 * TAU, t=1.0 + i / FPS, Duck=0.25) if i >= 10 else None
    return (doorcam(i, {"door": d, "glow": 0.0}, look=DOORVIEW, morning=True), cr)
shot("dopen", 24, s_dopen)
# 1b. him walking away down the walk, his back to the camera, into the morning fog
def s_away(i, k):
    p = lerp([2.2, 1.0, -33.4], [2.0, 0.6, -50.0], k)
    return (doorcam(i, {"door": OPENDOOR, "glow": 0.0}, morning=True), him(p, facing(p, [2.0, 0.6, -70.0]), "Walk", phase=k * 5.0 * TAU, t=2.0 + i / FPS))
shot("away", 48, s_away)

# 2. "he left every morning." the camera: the empty walk, the grey morning
def s_walk(i, k):
    return (doorcam(i, {"door": 0.0}, morning=True), None)
shot("walk", 33, s_walk)

# 3a. 11 pm: him at the end of the walk, coming (the rain)
def s_come(i, k):
    p = lerp([2.0, 0.6, -56.0], [2.0, 0.6, -50.0], k)
    return (doorcam(i, {"glow": 2.4}), him(p, facing(p, DOORCAM), "Walk", phase=k * 2.0 * TAU, t=2.0 + i / FPS, Look=[0.0, 0.1]))
shot("come", 30, s_come)
# 3b. on the steps
def s_steps(i, k):
    p = lerp([2.4, 1.0, -39.6], [2.4, 1.0, -37.4], k)
    return (doorcam(i, {"glow": 2.0}, [2.2, 6.0, -42.0]), him(p, facing(p, [2.0, 1.0, -30.0]), "Walk", phase=k * 1.2 * TAU, t=3.0 + i / FPS, Look=[0.0, 0.2]))
shot("steps", 30, s_steps)
# 3c. at the door, his back to the camera, bent to the lock
AT = [2.8, 1.0, -32.1]
def s_at(i, k):
    return (doorcam(i, {"glow": 1.0}, look=DOORVIEW), him(AT, facing(AT, [3.4, 1.0, -29.0]), "Stare", t=4.0 + stop(i), Duck=0.5, Look=[0.0, -0.4]))
shot("at", 30, s_at)

# 4a. "with his own key." the knob, close: a key in the lock, turning
def s_key(i, k):
    cam = add(lerp([3.1, 4.5, -31.9], [3.3, 4.35, -31.4], ease(k)), hand(i, 0.15))
    a = 1.5 * ease((i - 8) / 10)
    return (dict(DARK, shot="porch", cam={"pos": cam, "look": LOCK, "fov": 36}, exposure=2.4, lamps=0, door=0.0, hideIdx=only(KEY),
                 extrasOver={str(KEYBOW): key_bow(a)}, flash=fl(cam, LOCK, 3.0, 0.4), **NIGHTFOG), None)
shot("key", 30, s_key)
# 4b. the camera: the door shutting behind him, the hall black beyond it
def s_shut(i, k):
    return (doorcam(i, {"door": OPENDOOR * (1 - ease(i / 22))}, look=DOORVIEW), None)
shot("shut", 30, s_shut)

# 5a. "tonight he didn't leave." my phone in my hand: the doorbell's still on it
def s_notify(i, k):
    cam = add(HANDCAM, hand(i, 0.08))
    return (dict(DARK, shot="hand", cam={"pos": cam, "look": HP, "fov": 30}, exposure=2.4, lamps=0, hideIdx=only(HPH)), None)
shot("notify", 30, s_notify)
# 5b. the camera, morning: the empty porch, the door shut
def s_empty(i, k):
    return (doorcam(i, {"door": 0.0}, look=DOORVIEW, morning=True), None)
shot("empty", 30, s_empty)

# 6a. "he's still inside." from the hall: the front door shut, nobody
def s_hall(i, k):
    cam = add(lerp([4.0, G + 5.6, -14.0], [3.4, G + 5.5, -16.4], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="hallDark", cam={"pos": cam, "look": [2.0, G + 4.2, -30.0], "fov": 56}, exposure=3.0, lamps=0, door=0.0,
                 flash=fl(cam, [2.0, G + 4.0, -30.0], 6.0, 0.36)), None)
shot("inhall", 30, s_hall)
# 6b. the stairs going up into the dark
BOTTOM = [-5.0, G + 5.5, -10.0]
def s_up(i, k):
    cam = add(lerp(BOTTOM, [-5.0, G + 5.5, -8.6], ease(k)), hand(i, 0.6))
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, sy(12.0) + 3.0, 12.0], "fov": 58}, exposure=2.4, lamps=0, door=0.0,
                 flash=fl(cam, lerp([-5.0, sy(2.0), 2.0], [-5.0, sy(14.0), 14.0], ease(k)), 12.0, 0.34)), None)
shot("stairs", 30, s_up)

# 7a. the bottom of the stairs, looking up: nothing
def s_look(i, k):
    cam = add(BOTTOM, hand(i, 0.4))
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, sy(10.0) + 3.0, 10.0], "fov": 56}, exposure=2.4, lamps=0, door=0.0,
                 flash=fl(cam, [-5.0, sy(12.0) + 1.0, 12.0], 10.0, 0.3)), None)
shot("look", 25, s_look)
# 7b. the torch up again: he's crouched on the stairs, head cocked... and on frame 39 (slot frame 64, 22.15 s) he comes down at you
ON = [-5.0, sy(4.0), 4.0]
def s_on(i, k):
    cam = add(BOTTOM, hand(i, 0.5 if i < 39 else 1.4))
    if i < 39:
        sweep = ease(i / 6)
        look = lerp([-5.0, sy(10.0) + 3.0, 10.0], [ON[0], ON[1] + 5.0, ON[2]], sweep)
        cr = him(ON, facing(ON, cam), "Stare", t=3.0 + stop(i), Duck=1.1, Look=[0.0, -0.4], Scream=0.15 * ease((i - 30) / 9))
        return (dict(DARK, shot="stairs", cam={"pos": cam, "look": look, "fov": 56}, exposure=2.4, lamps=0, door=0.0, glow=2.2,
                     flash=fl(cam, [ON[0], ON[1] + 4.6, ON[2]], 11.0, 0.32)), cr)
    w = ease((i - 39) / 5)
    pz = 4.0 + (-5.4 - 4.0) * w
    p = [-5.0, sy(pz), pz]
    cr = him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Duck=0.6)
    camw = add(cam, [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    return (dict(DARK, shot="stairs", cam={"pos": camw, "look": [p[0], p[1] + 7.6, p[2]], "fov": 56 + 12 * w}, exposure=2.4, lamps=0, door=0.0, glow=6.0,
                 flash=fl(camw, [p[0], p[1] + 6.4, p[2]], 14.0, 0.45)), cr)
shot("on", 50, s_on)

# RUN: out onto the porch, looking back: he comes through the front door after me
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
           "props": {"cache": f"{S}/propcache"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
