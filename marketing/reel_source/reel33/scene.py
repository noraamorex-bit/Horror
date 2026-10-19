# Reel 33 — a new format (not "PEAK ... Part N"): a short first-person story told in typed lines on #2's
# track (every clip keeps #2's length, so the track's cuts and hits land), and the first reel of the v99
# creature: nearly ten feet of black jointed limbs, a porcelain grin, played in stop-motion.
#   hook (105)  the upstairs hall in the dark, the flashlight climbing to the attic hatch
#                 "my sister kept saying / someone lives in our attic."
#   card (120)  downstairs, the fire, warm and safe          "we laughed at her." / "every night."
#   72          the upstairs hall lights on... flicker... out  "then the power went out."
#   33          the flashlight on the floor: his wet footprints "those aren't our footprints."
#   90          down the hall: something standing at the far end, head on one side   "that's not a man."
#   60          closer: its back to you... its head turns all the way round          "and it heard me."
#   60          into the linen closet, the doors pulled almost shut                   "so I hid."
#   60          through the crack: it walks past, stop-motion jerky                  "I didn't breathe."
#   75          it stops. leans down to the crack... backs off... the doors torn open (22.15 s)  "it stopped."
#   30          RUN: up the stairs after you, on all fours                           "RUN."
# python3 scene.py [preview]. Writes spec.json, frames_in.json, shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.6
WALK = math.tau / 6.2     # (CreaturePose.phaseRate, v99)
RUN = math.tau / 8.5

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]
def stop(i, fps=13):
    # his pose time in stop-motion steps (the game plays him back at 12-18 poses a second)
    return math.floor(i * fps / 30) / fps

COLD = "#3d4f7a"
MOON = "#6f86c4"
HATCH = {"near": [6.0, 28.0, 11.0], "r": 4.5, "names": ["HatchPanel"], "hinge": [6.0, 28.15, 8.05], "axis": "x"}
CLOSET_EYE = [10.38, U + 4.9, -5.66]
CLOSET_LOOK = [2.0, U + 7.3, -6.8]
DOOR = {"near": [9.25, U + 4.5, -4.8], "r": 2.3, "names": ["WardrobeLeaf", "DoorPanel", "PanelInset"], "hinge": [9.32, 0, -3.6], "axis": "y"}
CRACK = 0.45
HALL_LIGHTS = [{"p": [2, U + 11, -29], "col": MOON, "b": 3.2, "r": 30, "decay": 1.1},
               {"p": [2.5, U + 9, -9], "col": "#5d72a8", "b": 3.0, "r": 20},
               {"p": [5, U + 7, -3], "col": COLD, "b": 1.2, "r": 12}]
SHOTS = {
    "hall": {"center": [3, U + 6, 2], "radius": 40, "lampRadius": 0, "maxLamps": 0, "door": HATCH,
             "lights": [{"p": [2, U + 11, -29], "col": MOON, "b": 2.4, "r": 30, "decay": 1.1}, {"p": [2, U + 11, 24], "col": MOON, "b": 1.4, "r": 24, "decay": 1.1}]},
    "hallOn": {"center": [3, U + 6, 2], "radius": 40, "lampRadius": 40, "maxLamps": 8, "lights": []},
    "fire": {"center": [-28, G + 5, -12], "radius": 30, "lampRadius": 0, "maxLamps": 0,
             "lights": [{"p": [-36.6, G + 2.4, -12], "col": "#ff8a3c", "b": 7.0, "r": 26, "decay": 1.3},
                        {"p": [-24, G + 8, -30], "col": COLD, "b": 0.6, "r": 20}]},
    "hallFar": {"center": [2, U + 6, -4], "radius": 46, "lampRadius": 0, "maxLamps": 0,
                "lights": [{"p": [2, U + 11, -29], "col": MOON, "b": 1.8, "r": 26, "decay": 1.1}]},
    "closet": {"center": [6, U + 5, -6], "radius": 30, "lampRadius": 0, "maxLamps": 0, "hide": ["Handle"], "door": DOOR, "lights": HALL_LIGHTS},
    "stairs": {"center": [-5, U - 2, 8], "radius": 40, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [-5, U + 6, 22], "col": "#2c3d6e", "b": 1.3, "r": 26}, {"p": [-5, 8, -2], "col": COLD, "b": 1.2, "r": 18}]},
}
DARK = {"ambient": 0.02, "bg": 0x010102}

# his footprints (World/Signs, exactly as the game lays them at the blackout)
WET = [30, 25, 21]
extras = []
FROM, TO, STRIDE = [6.0, 10.5], [4.0, -7.6], 2.3
dx, dz = TO[0] - FROM[0], TO[1] - FROM[1]
L = math.hypot(dx, dz); fx, fz = dx / L, dz / L
rx, rz = -fz, fx
yaw = math.atan2(-fx, -fz)
def rot(x, z, a):  # (local x, z) turned by yaw a -> world offsets (Roblox: CFrame.Angles(0, a, 0))
    return [x * math.cos(a) + z * math.sin(a), -x * math.sin(a) + z * math.cos(a)]
d, n = 0.6, 0
while d < L - 0.3:
    side = -1 if n % 2 == 0 else 1
    cx, cz = FROM[0] + fx * d + rx * side * 0.38, FROM[1] + fz * d + rz * side * 0.38
    for (lx, lz, sx, sz, ta) in [(0, 0.05, 0.32, 0.85, 0), (0, 0.42, 0.38, 0.32, 0)]:
        o = rot(lx, lz, yaw)
        extras.append({"pos": [cx + o[0], U + 0.011, cz + o[1]], "s": [sx, 0.02, sz], "rot": [0, yaw, 0], "col": WET, "rough": 0.35})
    for k2, a in enumerate([-0.32, 0.0, 0.32]):
        o = rot(0, -0.62 - (0.06 if k2 == 1 else 0), yaw - a)
        extras.append({"pos": [cx + o[0], U + 0.011, cz + o[1]], "s": [0.08, 0.02, 0.42], "rot": [0, yaw - a, 0], "col": WET, "rough": 0.35})
    d += STRIDE; n += 1

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

# 1. (hook) the upstairs hall: a slow push, the flashlight climbing to the attic hatch
def s_hook(i, k):
    cam = add(lerp([3.0, U + EYE, -14.0], [3.4, U + EYE - 0.2, -6.0], ease(k)), hand(i))
    tgt = lerp([2.0, U + 0.5, 2.0], [6.0, U + 12.6, 11.0], ease(min(1.0, k * 1.2)))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": lerp([3.0, U + 4.0, 8.0], [5.6, U + 9.5, 11.0], ease(k)), "fov": 62},
                 flash={"i": 13.0, "pos": [cam[0] + 0.5, cam[1] - 0.6, cam[2]], "target": tgt, "angle": 0.34}, exposure=1.9, door=0.0), None)
shot("hook", 105, s_hook)

# 2. (card) downstairs: the fire, warm, safe
def s_fire(i, k):
    cam = add(lerp([-22.5, G + EYE, -5.0], [-25.0, G + EYE - 0.3, -7.0], ease(k)), hand(i, 0.6))
    flick = 0.82 + 0.12 * math.sin(i * 0.9) + 0.06 * math.sin(i * 2.3 + 1)
    return (dict(DARK, shot="fire", cam={"pos": cam, "look": [-37.5, G + 3.0, -12.0], "fov": 60}, exposure=1.9, xl=flick), None)
shot("card", 120, s_fire)

# 3. the hall lights on... they stutter... out
def s_out(i, k):
    on = i < 34 or (i < 50 and (i * 7919) % 5 < 3)
    return (dict(DARK, shot="hallOn" if on else "hall", cam={"pos": add([3.0, U + EYE, 16.0], hand(i, 0.4)), "look": [3.5, U + 4.0, -20.0], "fov": 62},
                 lamps=1 if on else 0, ambient=0.08 if on else 0.02, exposure=1.3 if on else 2.3, door=0.0), None)
shot("out", 72, s_out)

# 4. the flashlight on the floor: the wet footprints, from under the attic hatch
def s_prints(i, k):
    cam = add([4.8, U + 5.3, -11.5], hand(i, 0.5))
    tgt = lerp([4.4, U, -6.0], [5.6, U, 5.0], ease(k))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": lerp([4.6, U + 0.4, -3.0], [5.2, U + 1.2, 6.0], ease(k)), "fov": 56},
                 flash={"i": 15.0, "pos": [cam[0] + 0.4, cam[1] - 0.5, cam[2]], "target": tgt, "angle": 0.32}, exposure=2.0, door=0.0), None)
shot("prints", 33, s_prints)

# 5. down the hall: something at the far end, head laid over, dead still
HIM = [2.6, U, -25.0]
def s_far(i, k):
    cam = add([2.5, U + EYE, 12.0 - 2.0 * ease(k)], hand(i, 0.5))
    lt = 1.0 if 20 <= i <= 22 else (0.5 if 58 <= i <= 60 else 0.0)
    return (dict(DARK, shot="hallFar", cam={"pos": cam, "look": [2.6, U + 5.6, -25.0], "fov": 40},
                 flash={"i": 9.0, "pos": [cam[0] + 0.4, cam[1] - 0.5, cam[2]], "target": [2.6, U + 4.0, -24.0], "angle": 0.18},
                 exposure=1.9, lightning=lt, glow=6),
            {"pos": HIM, "yaw": facing(HIM, cam), "gait": "Stare", "t": stop(i, 8) + 1.0})
shot("far", 90, s_far)

# 6. closer: its back to you... and its head turns all the way round to look at you
def s_turn(i, k):
    cam = add([2.8, U + EYE, -7.0], hand(i, 0.6))
    back = facing(HIM, cam) + math.pi
    # the head turns round in jerks (stop-motion), from the wall in front of it to you
    steps = math.floor(ease(min(1.0, max(0.0, (k - 0.15) / 0.7))) * 7) / 7
    return (dict(DARK, shot="hallFar", cam={"pos": cam, "look": [2.6, U + 7.4, -25.0], "fov": 30},
                 flash={"i": 12.0, "pos": [cam[0] + 0.4, cam[1] - 0.5, cam[2]], "target": [2.6, U + 7.0, -25.0], "angle": 0.16},
                 exposure=2.0, glow=7),
            {"pos": HIM, "yaw": back, "gait": "Stare", "t": stop(i, 8) + 3.0, "neck": [0.0, math.pi * steps, -0.4 * steps]})
shot("turn", 60, s_turn)

# 7. into the linen closet: step in, turn round, pull the doors almost shut
def s_in(i, k):
    a = ease(min(1.0, k / 0.45))
    cam = lerp([4.0, U + EYE, -4.8], [10.3, U + EYE - 0.5, -4.9], a)
    cam = lerp(cam, CLOSET_EYE, ease((k - 0.45) / 0.35))
    turn = ease((k - 0.25) / 0.4)
    ang = math.pi * turn
    look = [cam[0] + 6 * math.cos(ang), U + 4.4 + 1.6 * turn, cam[2] + 6 * math.sin(ang) - 1.1 * turn]
    door = 1.75 if k < 0.6 else 1.75 + (CRACK - 1.75) * ease((k - 0.6) / 0.3)
    fl = {"i": 11.0 * (1 - ease((k - 0.45) / 0.3)), "pos": [cam[0] + 0.4, cam[1] - 0.5, cam[2]], "target": [cam[0] + 6 * math.cos(ang), U + 3, cam[2] + 6 * math.sin(ang)], "angle": 0.45}
    return (dict(DARK, shot="closet", cam={"pos": add(cam, hand(i, 0.7)), "look": look, "fov": 64}, exposure=2.2, door=door, flash=fl), None)
shot("in", 60, s_in)

def crack(i, extra=None, door=CRACK):
    fr = dict(DARK, shot="closet", cam={"pos": [CLOSET_EYE[0], CLOSET_EYE[1] + 0.03 * math.sin(i * 0.31), CLOSET_EYE[2]], "look": CLOSET_LOOK, "fov": 62},
              exposure=2.3, glow=4, door=door)
    if extra: fr.update(extra)
    return fr

# 8. through the crack: it walks past (towards the stairs), hunched, head lolling, jerky
def s_past(i, k):
    z = -12.5 + 12.0 * ease(min(1.0, k * 1.05))
    p = [3.6, U, z]
    return (crack(i), {"pos": p, "yaw": facing(p, [3.6, U, z + 10]), "gait": "Walk", "phase": (z + 18) * WALK, "t": stop(i)})
shot("past", 60, s_past)

# 9. it stops. turns. folds down to the crack... backs off into the dark... and the doors are torn
# open (22.15 s: frame 64 of this clip)
STOPAT = [3.6, U, -6.6]
PEEK = [1.4, U, -6.0]      # (tipped forward from his feet here, his face comes down level with the crack)
SCARE = [0.9, U, -5.9]
def s_tear(i, k):
    if i < 64:
        if i < 18:
            turn = ease(i / 12)
            yaw = facing(STOPAT, [3.6, U, 10]) + (facing(STOPAT, CLOSET_EYE) - facing(STOPAT, [3.6, U, 10])) * turn
            return (crack(i, {"glow": 5}), {"pos": STOPAT, "yaw": yaw, "gait": "Stare", "t": stop(i), "neck": [0.2 * turn, 0.0, -0.6 * turn]})
        if i < 44:
            # folding down from the hips towards the crack, the head coming up to look in, in jerks
            w = math.floor(ease((i - 18) / 20) * 9) / 9
            p = lerp(STOPAT, PEEK, w)
            return (crack(i, {"glow": 6}), {"pos": p, "yaw": facing(p, CLOSET_EYE), "gait": "Stare", "t": stop(i), "pitch": -0.97 * w,
                                            "neck": [0.97 * w, 0.0, -0.55 * w - 0.3]})
        # (and then he's just gone from the crack: nothing, for a second and a half)
        return (crack(i), None)
    d = ease((i - 64) / 2.0)
    fr = crack(i, {"glow": 10, "exposure": 2.4, "flash": {"i": 10.0, "pos": [CLOSET_EYE[0] - 0.3, CLOSET_EYE[1] - 0.6, CLOSET_EYE[2]], "target": [7.5, U + 5.4, -5.9], "angle": 0.5}},
               door=CRACK + (2.1 - CRACK) * d)
    fr["cam"]["look"] = [2.0, U + 5.3, -5.9]
    return (fr, {"pos": SCARE, "yaw": facing(SCARE, CLOSET_EYE), "gait": "Stare", "t": stop(i), "pitch": -0.97, "neck": [0.97, 0.0, -0.5 + 0.35 * math.sin(i * 1.3)]})
shot("tear", 75, s_tear)

# 10. RUN: from the top of the stairs, and it's coming up them on all fours
def s_run(i, k):
    cam = [-5.0 + 0.25 * math.sin(i * 1.7), U + 4.6 + 0.2 * math.sin(i * 2.3), 21.5]
    z = -3.0 + 14.0 * k
    y = 2.05 + 0.625 * (z + 5.3)
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, U - 1.5 + 3.0 * k, 4.0], "fov": 62, "roll": 0.05 * math.sin(i * 0.9)},
                 flash={"i": 18.0, "pos": [cam[0] + 0.6, cam[1] - 0.6, cam[2]], "target": [-5.0 + 1.2 * math.sin(i * 1.3), y + 4.0, z], "angle": 0.36},
                 ambient=0.01, exposure=1.7, glow=8),
            {"pos": [-5.0, y, z], "yaw": facing([-5.0, y, z], [-5.0, y, z + 10]), "gait": "Chase", "phase": k * 14 * RUN, "t": stop(i), "pitch": -0.25})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
