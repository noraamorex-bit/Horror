# Reel 36 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 1)", the new series (20 Oct, the owner:
# the peak format was better, "I want gameplay... just scenes like hiding, monster finding you, chasing
# you, scary jumpscare"). No story text: a night as you'd play it, in first person, with two friends,
# on #2's track (every clip keeps #2's length, so its cuts and hits land); comp_peak draws the game's
# HUD over it (objective, hotbar, SPRINT / CROUCH, the stamina bar, the heartbeat minigame, notices).
#   hook (105)  downstairs in the dark with your friends, flashlight on, walking into the living room
#   card (120)  the light finds him by the fireplace; your friends turn and bolt; he drops and charges
#   72          the chase: up the stairs, looking back: a friend scrambling behind you, him after them
#   33          into the linen closet upstairs, pulling the doors to a crack
#   90          through the crack: your friend runs past, he goes after them... and drags them back
#   60          he comes back up the hall and stops at the closet
#   60          he folds down to the crack (the heartbeat minigame)
#   60          his face at the crack, listening, the mouth opening
#   75          he backs off... nothing... and the doors are torn open (the scare at 22.15 s)
#   30          RUN: down the stairs, and he's coming down after you
# python3 scene.py [preview]. Writes spec.json, frames_in.json, shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.6
AV = 3.0                  # an avatar's origin above its feet
WALK = math.tau / 6.2     # (CreaturePose.phaseRate, v99)
RUN = math.tau / 8.5
TAU = math.tau

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]
def stop(i, fps=13):
    return math.floor(i * fps / 30) / fps

# --- your friends: Roblox avatars with a walk / run cycle (avatar.js joints)
def gait(phase, run=False, look=(0, 0)):
    s, c = math.sin(phase), math.cos(phase)
    a = 0.85 if run else 0.5
    kn = 1.25 if run else 0.6
    return {"lHip": a * s, "rHip": -a * s,
            "lKnee": -kn * max(0.0, -c) - 0.1, "rKnee": -kn * max(0.0, c) - 0.1,
            "lShoulder": [-a * 0.9 * s + (0.3 if run else 0), 0, -0.05], "rShoulder": [a * 0.9 * s + (0.3 if run else 0), 0, 0.05],
            "lElbow": 1.3 if run else 0.25, "rElbow": 1.3 if run else 0.25,
            "waist": -0.22 if run else 0.0, "neckX": 0.12 if run else 0.0, "neckY": look[0], "neckZ": look[1]}
def player(i, pos, yaw, phase=0.0, run=False, pose=None, pitch=0.0):
    bob = 0.14 * abs(math.sin(phase)) if run else 0.05 * abs(math.sin(phase))
    return {"i": i, "pos": [pos[0], pos[1] + AV + bob, pos[2]], "yaw": yaw, "pose": pose or gait(phase, run), "pitch": pitch}
SCARED = {"lShoulder": [0.5, 0, -0.35], "rShoulder": [0.5, 0, 0.35], "lElbow": 1.6, "rElbow": 1.6, "neckX": -0.1, "waist": 0.05}
KIDS = [{"hoodie": "#2f7de0", "hoodieDark": "#215ca8", "pants": "#2a2a33", "hair": "#e0b25a"},
        {"hoodie": "#3fae5a", "hoodieDark": "#2c8043", "pants": "#3a3a40", "hair": "#141012", "skin": "#8d5a3b"}]
AVS = [{"pos": [0, -200, 0], "yaw": 0, "face": "scared", "colors": KIDS[0]},
       {"pos": [0, -200, 0], "yaw": 0, "face": "scared", "colors": KIDS[1]}]

COLD, MOON = "#3d4f7a", "#6f86c4"
LIVING = [{"p": [-24, 9, -28], "col": MOON, "b": 4.2, "r": 26, "decay": 1.1}, {"p": [-36, 8.5, -16], "col": COLD, "b": 2.6, "r": 18},
          {"p": [-30, 8.5, -4], "col": COLD, "b": 1.4, "r": 16}, {"p": [-22, 8.5, 4], "col": COLD, "b": 1.0, "r": 14}]
# the linen closet upstairs: its left door swings on a hinge at z = -3.6; you look out through the gap
CLOSET_EYE = [10.38, U + 4.9, -5.66]
CLOSET_LOOK = [2.0, U + 7.0, -6.8]
DOOR = {"near": [9.25, U + 4.5, -4.8], "r": 2.3, "names": ["WardrobeLeaf", "DoorPanel", "PanelInset"], "hinge": [9.32, 0, -3.6], "axis": "y"}
CRACK = 0.45
HALL_LIGHTS = [{"p": [2, U + 11, -29], "col": MOON, "b": 3.2, "r": 30, "decay": 1.1},
               {"p": [2.5, U + 9, -9], "col": "#5d72a8", "b": 3.0, "r": 20},
               {"p": [5, U + 7, -3], "col": COLD, "b": 1.2, "r": 12}, {"p": [3.0, U + 8, -7.5], "col": "#5d72a8", "b": 1.6, "r": 12}]
STAIR_LIGHTS = [{"p": [-5, U + 6, 22], "col": "#2c3d6e", "b": 1.3, "r": 26}, {"p": [-5, 8, -2], "col": COLD, "b": 1.4, "r": 18},
                {"p": [-5, G + 7, -12], "col": COLD, "b": 1.0, "r": 16}]
SHOTS = {
    "living": {"center": [-26, 6, -8], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": LIVING},
    "stairs": {"center": [-5, 8, 4], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": STAIR_LIGHTS},
    "closet": {"center": [6, U + 5, -6], "radius": 30, "lampRadius": 0, "maxLamps": 0, "hide": ["Handle"], "door": DOOR, "lights": HALL_LIGHTS},
}
DARK = {"ambient": 0.03, "bg": 0x010102}

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

def fl(cam, tgt, i=12.0, angle=0.34):
    return {"i": i, "pos": [cam[0] + 0.5, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}

# 1. (hook) into the living room in the dark with your friends, your flashlight on their backs
HIM = [-31.0, G, -16.0]
A0, A1 = [-26.4, G, -3.5], [-30.2, G, -9.4]      # the blue hoodie, on the left
B0, B1 = [-21.4, G, -4.5], [-24.2, G, -11.0]     # the green one, on the right (he's between them)
CAM0, CAM1 = [-20.6, G + EYE, 6.5], [-22.4, G + EYE, 1.0]
def friends_walk(w, ph, look=(0, 0)):
    pa, pb = lerp(A0, A1, w), lerp(B0, B1, w)
    return [player(0, pa, facing(A0, A1), ph, False, gait(ph, False, look)), player(1, pb, facing(B0, B1), ph + 2.2, False, gait(ph + 2.2, False, (-look[0], look[1])))]
def s_hook(i, k):
    w = 0.62 * k
    cam = add(lerp(CAM0, CAM1, 0.62 * k), hand(i))
    tgt = lerp([-24.0, G + 3.2, -4.0], [-27.0, G + 3.0, -12.0], ease(k))
    return (dict(DARK, shot="living", cam={"pos": cam, "look": [-27.0, G + 3.6, -12.0], "fov": 62}, flash=fl(cam, tgt, 13.0, 0.38), exposure=2.0,
                 av=friends_walk(w, w * 9 * TAU / 3)), None)
shot("hook", 105, s_hook)

# 2. (card) the light finds him by the fireplace; your friends turn and bolt past you; he drops and charges
def s_card(i, k):
    t = i / FPS
    w = 0.62 + 0.38 * ease(min(1.0, i / 40))
    cam = add(lerp(CAM0, CAM1, w), hand(i, 0.8))
    # the flashlight sweeps right to left and lands on him at ~1.2 s
    tgt = lerp([-27.0, G + 3.0, -12.0], [-31.0, G + 5.0, -16.0], ease((i - 14) / 22))
    look = lerp([-27.0, G + 4.4, -12.0], [-30.0, G + 5.2, -15.0], ease((i - 20) / 30))
    av = []
    if i < 52:
        av = friends_walk(min(1.0, 0.62 + 0.38 * i / 40), (0.62 + 0.38 * min(1.0, i / 40)) * 9 * TAU / 3,
                          (0.0, 0.0)) if i < 40 else [player(0, A1, facing(A1, HIM), 0, False, SCARED), player(1, B1, facing(B1, HIM), 0, False, SCARED)]
    elif i < 64:
        # they turn round to you, frozen
        tu = ease((i - 52) / 8)
        av = [player(0, A1, facing(A1, HIM) + (math.pi * 0.9) * tu, 0, False, SCARED), player(1, B1, facing(B1, HIM) - (math.pi * 0.9) * tu, 0, False, SCARED)]
    else:
        # and run: past you, one each side
        r = (i - 64) / 30
        pa = lerp(A1, [cam[0] - 3.5, G, cam[2] + 2.5], min(1.0, r))
        pb = lerp(B1, [cam[0] + 3.0, G, cam[2] + 3.0], min(1.0, r * 1.1))
        av = [player(0, pa, facing(A1, [cam[0] - 3.5, G, cam[2] + 2.5]), r * 7 * TAU, True),
              player(1, pb, facing(B1, [cam[0] + 3.0, G, cam[2] + 3.0]), r * 7 * TAU + 1.5, True)]
        av = [a for a, pp in zip(av, [pa, pb]) if math.hypot(pp[0] - cam[0], pp[2] - cam[2]) > 1.6]
    if i < 76:
        cr = {"pos": HIM, "yaw": facing(HIM, cam), "gait": "Stare", "t": stop(i, 8) + 1.0, "jaw": 0.06 + 0.6 * ease((i - 50) / 20),
              "neck": [0.0, 0.0, -0.5 * ease((i - 30) / 16)]}
    else:
        c = ease((i - 76) / 44) * 0.85 + 0.15 * (i - 76) / 44
        p = lerp(HIM, [cam[0] - 1.6, G, cam[2] - 8.5], c)
        cr = {"pos": p, "yaw": facing(p, cam), "gait": "Chase", "phase": c * 14 * RUN, "t": stop(i), "jaw": 0.9}
    return (dict(DARK, shot="living", cam={"pos": cam, "look": look, "fov": 60}, flash=fl(cam, tgt, 14.0, 0.34), exposure=2.0, glow=7, av=av), cr)
shot("card", 120, s_card)

# 3. the chase: up the stairs, looking back: your friend scrambling up behind you, him right after them
def sy(z): return max(G, min(U, 2.05 + 0.625 * (z + 5.3) - 1.0))
def s_chase(i, k):
    zc = 3.0 + 9.0 * k
    cam = [-5.2 + 0.22 * math.sin(i * 1.7), sy(zc) + 5.2 + 0.22 * math.sin(i * 2.3), zc]
    zf = zc - 8.5
    zh = zf - 6.0
    hy = sy(zh)
    fr = dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, sy(zc - 8) + 3.2, zc - 9.0], "fov": 66, "roll": 0.05 * math.sin(i * 0.9)},
              flash=fl(cam, [-5.0 + 1.0 * math.sin(i * 1.3), hy + 4.0, zh], 18.0, 0.4), exposure=1.9, glow=9,
              av=[player(0, [-5.9, sy(zf), zf], facing([0, 0, zf], [0, 0, zf + 5]), k * 9 * TAU, True, pitch=-0.3)])
    fr["av"][0]["pose"]["neckX"] = -0.35
    return (fr, {"pos": [-4.6, hy, zh], "yaw": facing([-4.6, hy, zh], [-4.6, hy, zh + 10]), "gait": "Chase", "phase": k * 14 * RUN, "t": stop(i),
                 "pitch": -0.25 if zh > -5.3 else 0.0, "jaw": 0.9})
shot("chase", 72, s_chase)

# 4. into the linen closet: backing in, the doors pulled to a crack
def s_in(i, k):
    cam = lerp([7.2, U + EYE - 0.2, -5.4], CLOSET_EYE, ease(i / 12))
    door = 1.75 + (CRACK - 1.75) * ease((i - 8) / 12)
    sh = 0.08 * math.sin(i * 1.9) * (1 - ease(i / 26))
    return (dict(DARK, shot="closet", cam={"pos": [cam[0], cam[1] + sh, cam[2] + sh], "look": lerp([2.0, U + 5.0, -6.0], CLOSET_LOOK, ease(i / 20)), "fov": 62},
                 exposure=2.3, door=door, flash=fl(cam, [3.0, U + 3.0, -6.4], 9.0 * (1 - ease((i - 6) / 10)), 0.45)), None)
shot("in", 33, s_in)

def crack(i, extra=None, door=CRACK):
    fr = dict(DARK, shot="closet", cam={"pos": [CLOSET_EYE[0], CLOSET_EYE[1] + 0.03 * math.sin(i * 0.31), CLOSET_EYE[2]], "look": CLOSET_LOOK, "fov": 62},
              exposure=2.3, glow=5, door=door)
    if extra: fr.update(extra)
    return fr

# 5. through the crack: your friend runs up the hall and stops right outside, looking back for you...
# he comes out of the dark on all fours, rises, grabs them, and drags them away by the ankles
DRAG_POSE = {"lShoulder": [3.0, 0, -0.3], "rShoulder": [2.7, 0, 0.4], "lElbow": 0.3, "rElbow": 0.5, "neckX": -0.4, "lHip": 0.15, "rHip": -0.1}
SPOT = [4.0, U, -6.3]          # (right in the middle of the crack)
GRAB = [3.8, U, -10.2]
def s_caught(i, k):
    cr = None
    if i < 16:
        r = ease(i / 16)
        p = lerp([4.4, U, 2.0], SPOT, r)
        av = [player(0, p, facing(p, [4.0, U, -20]), r * 5 * TAU, True)]
    elif i < 40:
        # stopped: looking back down the hall, then round at him, frozen
        look = 0.6 * (1 - ease((i - 22) / 6))
        av = [player(0, SPOT, facing(SPOT, [6.0, U, -20]) if i < 26 else facing(SPOT, GRAB), 0, False,
                     dict(SCARED, neckY=look) if i >= 26 else {"neckY": 0.9, "lShoulder": [0.1, 0, -0.05], "rShoulder": [0.1, 0, 0.05]})]
    else:
        av = None
    if 14 <= i < 34:
        r = ease((i - 14) / 20)
        p = lerp([3.6, U, -18.0], GRAB, r)
        cr = {"pos": p, "yaw": facing(p, SPOT), "gait": "Chase", "phase": r * 8 * RUN, "t": stop(i), "jaw": 0.8}
    elif 34 <= i < 50:
        g = ease((i - 34) / 8)
        p = lerp(GRAB, [3.9, U, -8.8], g)
        cr = {"pos": p, "yaw": facing(p, SPOT), "gait": "Reach", "t": stop(i), "duck": 0.5, "jaw": 1.0}
        if i >= 40:
            # (snatched up off their feet)
            av = [{"i": 0, "pos": [SPOT[0], U + AV + 1.4 * g, SPOT[2] - 0.6 * g], "yaw": facing(SPOT, GRAB), "pitch": 0.5 * g,
                   "pose": dict(SCARED, lHip=0.6 * math.sin(i * 1.4), rHip=-0.6 * math.sin(i * 1.4), lKnee=-0.8, rKnee=-0.6)}]
    elif i >= 50:
        r = ease((i - 50) / 40)
        p = lerp([3.9, U, -8.8], [3.6, U, -22.0], r)
        y = facing(p, [3.6, U, -40])
        cr = {"pos": p, "yaw": y, "gait": "Walk", "phase": r * 13 * WALK, "t": stop(i)}
        # (by the ankles, face up, arms over the head, behind him)
        fp = [p[0] + 0.3, U + 0.6, p[2] + 4.6]
        av = [{"i": 0, "pos": fp, "yaw": y, "pitch": math.pi / 2, "pose": dict(DRAG_POSE, lShoulder=[3.0 + 0.3 * math.sin(i * 0.9), 0, -0.3])}]
    # (peeking out a little wider while your friend's still out there; level, so the floor's in view)
    fr = crack(i, {"exposure": 2.9, "glow": 7}, door=0.95)
    fr["cam"]["look"] = [2.0, U + 3.9, -6.6]
    fr["cam"]["pos"][0] -= 0.25
    fr["av"] = av or []
    return (fr, cr)
shot("caught", 90, s_caught)

# 6. he comes back up the hall, and stops right outside the closet
STOPAT = [3.6, U, -6.6]
def s_back(i, k):
    if i < 34:
        z = -15.0 + 8.4 * ease(i / 34)
        p = [3.6, U, z]
        return (crack(i), {"pos": p, "yaw": facing(p, [3.6, U, 20]), "gait": "Walk", "phase": (z + 15) * WALK, "t": stop(i)})
    turn = ease((i - 36) / 14)
    y0 = facing(STOPAT, [3.6, U, 20])
    d = ((facing(STOPAT, CLOSET_EYE) - y0 + math.pi) % TAU) - math.pi
    return (crack(i, {"glow": 6}), {"pos": STOPAT, "yaw": y0 + d * turn, "gait": "Stare", "t": stop(i), "neck": [0.2 * turn, 0.0, -0.6 * turn]})
shot("back", 60, s_back)

# 7. he folds down to the crack, in jerks (the heartbeat minigame)
PEEK = [1.4, U, -6.0]      # (tipped forward from his feet here, his face comes down level with the crack)
SCARE = [0.9, U, -5.0]
def s_fold(i, k):
    w = math.floor(ease(i / 40) * 9) / 9
    p = lerp(STOPAT, PEEK, w)
    return (crack(i, {"glow": 6}), {"pos": p, "yaw": facing(p, CLOSET_EYE), "gait": "Stare", "t": stop(i), "pitch": -0.97 * w,
                                    "neck": [0.97 * w, 0.0, -0.55 * w - 0.3], "jaw": 0.1})
shot("fold", 60, s_fold)

# 8. his face at the crack: listening, the head tilting, the mouth slowly opening
def s_face(i, k):
    tilt = math.floor(ease((i - 10) / 30) * 6) / 6
    jaw = math.floor(ease((i - 24) / 30) * 7) / 7
    return (crack(i, {"glow": 7}), {"pos": PEEK, "yaw": facing(PEEK, CLOSET_EYE), "gait": "Stare", "t": stop(i), "pitch": -0.97,
                                    "neck": [0.97, 0.0, -0.85 + 0.6 * tilt], "jaw": 0.1 + 0.6 * jaw})
shot("face", 60, s_face)

# 9. he unfolds and backs off into the dark... nothing... and the doors are torn open (22.15 s: frame 64)
def s_tear(i, k):
    if i < 64:
        if i < 30:
            w = math.floor(ease(i / 24) * 8) / 8
            p = lerp(PEEK, [2.4, U, -12.0], w)
            return (crack(i), {"pos": p, "yaw": facing(p, CLOSET_EYE), "gait": "Stare" if w < 0.3 else "Walk", "phase": w * 4, "t": stop(i),
                               "pitch": -0.97 * max(0.0, 1 - w * 2.5), "neck": [0.97 * max(0.0, 1 - w * 2.5), 0.0, -0.25], "jaw": 0.7 * (1 - w)})
        return (crack(i), None)
    d = ease((i - 64) / 2.0)
    fr = crack(i, {"glow": 12, "exposure": 2.5, "flash": {"i": 10.0, "pos": [CLOSET_EYE[0] - 0.3, CLOSET_EYE[1] - 0.6, CLOSET_EYE[2]], "target": [7.5, U + 5.4, -5.9], "angle": 0.5}},
               door=CRACK + (2.1 - CRACK) * d)
    fr["cam"]["look"] = [2.0, U + 5.5, -5.3]
    fr["cam"]["fov"] = 66
    return (fr, {"pos": SCARE, "yaw": facing(SCARE, CLOSET_EYE), "gait": "Stare", "t": stop(i), "pitch": -0.97,
                 "neck": [0.97, 0.0, -0.5 + 0.35 * math.sin(i * 1.3)], "jaw": 1.0})
shot("tear", 75, s_tear)

# 10. RUN: down the stairs, looking back, and he's coming down after you on all fours
def s_run(i, k):
    zc = 2.0 - 7.0 * k
    cam = [-5.0 + 0.25 * math.sin(i * 1.7), sy(zc) + 5.0 + 0.2 * math.sin(i * 2.3), zc]
    zh = 17.0 - 9.0 * k
    hy = sy(zh) if zh < 15.5 else U
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, hy + 3.0, zh], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [-5.0 + 1.2 * math.sin(i * 1.3), hy + 4.0, zh], 18.0, 0.36), ambient=0.01, exposure=1.8, glow=9),
            {"pos": [-5.0, hy, zh], "yaw": facing([-5.0, hy, zh], [-5.0, hy, zh - 10]), "gait": "Chase", "phase": k * 15 * RUN, "t": stop(i),
             "pitch": 0.3 if zh < 15.5 else 0.0, "jaw": 0.9})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": AVS, "extras": [],
           "props": {"cache": "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
