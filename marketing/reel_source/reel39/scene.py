# Reel 39 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 4)", the gameplay series, in reel 38's
# style (the owner: less text, more gameplay and scares, real Roblox characters): Riley and Jamie in
# Roblox's own catalog items (film2 avatar_rbx.js), no HUD text, several scares, and this time the
# ROCKET LAUNCHER pass in action. On #2's track, every clip at #2's length.
#   hook (105)  the upstairs hall in the dark, your flashlight on Riley and Jamie walking ahead
#   card (120)  Jamie opens the linen closet... he's folded up inside; he bursts out at you (jolt)
#   72          running down the hall, looking back: he's after you; you stop, turn, the rocket
#               launcher: the shot, the blast, he's blown off his feet
#   33          he's down in the smoke, twitching; you run for Lily's room
#   90          into her play tent; through the flap: Riley ducks down beside her bed
#   60          he comes in through her door, hunched, sniffing across the rug
#   60          he finds Riley: lifted off the floor, legs kicking (jolt), carried out
#   60          quiet... then he comes back, straight to the tent
#   75          he folds down to the flap... gone... his face at the gap (the scare at 22.15 s)
#   30          RUN: out in the hall, he comes through her door after you on all fours
# python3 scene.py [preview]. Writes spec.json, frames_in.json, shots.json (in the current directory).
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.5
SCALE = 1.2              # the avatars (taller players)
AV = 2.2 * SCALE         # an avatar's origin (its LowerTorso) above its feet
RUN = math.tau / 8.5
TAU = math.tau
S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
C = f"{S}/avcache"

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def clamp(k): return max(0.0, min(1.0, k))
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]
def stop(i, fps=13): return math.floor(i * fps / 30) / fps
def run_shake(i, amt=1.0): return [0.2 * amt * math.sin(i * 1.7), 0.2 * amt * math.sin(i * 2.3), 0.12 * amt * math.sin(i * 1.1)]
def wrap(a): return ((a + math.pi) % TAU) - math.pi

# --- your friends: real Roblox avatars (avatar_rbx.js; poses: avatar.js joint names)
RILEY = {"cache": C, "skin": "#f5cd30", "shirt": "144076357", "pants": "382537568", "faces": ["144080495", "8329421", "7074932"], "hats": ["63690008"]}
JAMIE = {"cache": C, "skin": "#9b6a48", "shirt": "398633582", "pants": "398633811", "faces": ["144080495", "7317691", "8329421"], "hats": ["1103003368"]}
AVS = [{"pos": [0, -200, 0], "yaw": 0, "rbx": RILEY, "scale": SCALE}, {"pos": [0, -200, 0], "yaw": 0, "rbx": JAMIE, "scale": SCALE}]
SMILE, SCARED, UHOH = 0, 1, 2

def gait(phase, run=False, look=(0, 0)):
    s, c = math.sin(phase), math.cos(phase)
    a = 0.85 if run else 0.45
    kn = 1.25 if run else 0.5
    return {"lHip": a * s, "rHip": -a * s,
            "lKnee": -kn * max(0.0, -c) - 0.1, "rKnee": -kn * max(0.0, c) - 0.1,
            "lShoulder": [-a * 0.9 * s + (0.3 if run else 0), 0, -0.05], "rShoulder": [a * 0.9 * s + (0.3 if run else 0), 0, 0.05],
            "lElbow": 1.2 if run else 0.2, "rElbow": 1.2 if run else 0.2,
            "waist": -0.2 if run else 0.0, "neckX": 0.1 if run else 0.0, "neckY": look[0], "neckZ": look[1]}
def player(i, pos, yaw, phase=0.0, run=False, pose=None, pitch=0.0, face=SMILE):
    bob = 0.14 * abs(math.sin(phase)) if run else 0.04 * abs(math.sin(phase))
    return {"i": i, "pos": [pos[0], pos[1] + AV + bob, pos[2]], "yaw": yaw, "pose": pose or gait(phase, run), "pitch": pitch, "face": face}
AFRAID = {"lShoulder": [0.55, 0, -0.35], "rShoulder": [0.55, 0, 0.35], "lElbow": 1.5, "rElbow": 1.5, "neckX": -0.1, "waist": 0.05}
FLAIL = {"lShoulder": [2.6, 0, -0.5], "rShoulder": [2.2, 0, 0.6], "lElbow": 0.4, "rElbow": 0.9, "neckX": -0.35, "lHip": 0.5, "rHip": -0.3, "lKnee": -0.9, "rKnee": -0.3}

CROUCH = {"lHip": 1.5, "rHip": 1.5, "lKnee": -2.3, "rKnee": -2.3, "waist": 0.35, "lShoulder": [0.9, 0, -0.3], "rShoulder": [0.9, 0, 0.3],
          "lElbow": 1.4, "rElbow": 1.4, "neckX": -0.2}
REACH_OUT = {"rShoulder": [1.6, 0, 0.1], "rElbow": 0.2, "lShoulder": [0.2, 0, -0.05], "neckX": 0.0}

COLD, MOON, PINK = "#3d4f7a", "#6f86c4", "#ff9fc4"
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.5, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}
DARK = {"ambient": 0.03, "bg": 0x010102}

# --- the upstairs hall (x -8..12): the linen closet in its east side (x 9.3..11.4, z -3.6..-7.8), its
# left leaf hinged at z -3.6; Lily's door in the x = 12 wall at z 20 (hinged at z 17.55)
CLOSET = {"near": [9.25, U + 4.5, -4.8], "r": 2.3, "names": ["WardrobeLeaf", "DoorPanel", "PanelInset"], "hinge": [9.32, 0, -3.6], "axis": "y"}
LILYDOOR = {"near": [12.0, U + 4.7, 20.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [12.0, 0, 17.55], "axis": "y"}
HALL = [{"p": [2, U + 11, -29], "col": MOON, "b": 3.2, "r": 30, "decay": 1.1}, {"p": [2.5, U + 9, -9], "col": "#5d72a8", "b": 3.0, "r": 20},
        {"p": [5, U + 7, -3], "col": COLD, "b": 1.4, "r": 14}, {"p": [2, U + 8, 10], "col": "#5d72a8", "b": 2.0, "r": 18},
        {"p": [4, U + 8, 22], "col": COLD, "b": 1.4, "r": 16}]
# --- Lily's room (x 12..40, z 8..30): her play tent at (20.2, 10.6), the tea table at (24, 15.2), her bed
# x 32..38.4, z 22.2..29.1 (open at its foot, z 22.2)
TENT = [20.2, U, 10.6]
TENT_EYE = [20.25, U + 1.75, 11.7]
TENT_LOOK = [22.8, U + 1.9, 16.5]
RILEY_HIDE = [25.2, U, 21.6]
ROOM = [{"p": [13.6, U + 2.2, 27.5], "col": PINK, "b": 1.8, "r": 16, "decay": 1.3},          # her night light
        {"p": [26.0, U + 8.0, 31.5], "col": MOON, "b": 3.6, "r": 26, "decay": 1.1},           # the open window
        {"p": [30.0, U + 8.0, 12.0], "col": COLD, "b": 1.4, "r": 18}, {"p": [27.0, U + 3.0, 21.0], "col": MOON, "b": 1.0, "r": 12}]
SHOTS = {
    "hall": {"center": [3, U + 5, 2], "radius": 36, "lampRadius": 0, "maxLamps": 0, "door": CLOSET, "lights": HALL},
    "hall2": {"center": [5, U + 5, 12], "radius": 36, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR, "lights": HALL},
    "room": {"center": [26, U + 5, 19], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR, "lights": ROOM},
}
# the flap of her tent, from inside (the store tipi's walls are one-sided: seen from inside they'd vanish)
CANVAS = [226, 214, 190]
EXTRAS = []
for sx in (-1, 1):
    EXTRAS.append({"pos": [TENT[0] + sx * 1.05, U + 1.8, TENT[2] + 1.75], "s": [0.9, 3.6, 0.05], "rot": [0.0, sx * 0.25, sx * 0.16], "col": CANVAS, "rough": 0.95})

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

# 1. (hook) the upstairs hall in the dark: your flashlight on Riley and Jamie walking ahead, north
CAM0, CAM1 = [0.8, U + EYE, 13.0], [1.2, U + EYE, 9.0]
R0, R1 = [-0.6, U, 1.8], [0.4, U, -3.0]           # Riley, on the left
J0, J1 = [3.6, U, 0.4], [5.6, U, -3.6]            # Jamie, on the right
def kids_walk(w, ph, face=SMILE):
    pr, pj = lerp(R0, R1, w), lerp(J0, J1, w)
    return [player(0, pr, facing(R0, R1), ph, False, face=face), player(1, pj, facing(J0, J1), ph + 2.2, False, face=face)]
def s_hook(i, k):
    w = ease(k)
    cam = add(lerp(CAM0, CAM1, w), hand(i))
    tgt = lerp([1.0, U + 3.0, 2.0], [4.0, U + 3.4, -3.0], w)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": lerp([1.8, U + 4.2, -4.0], [5.0, U + 4.2, -6.0], w), "fov": 72},
                 flash=fl(cam, tgt), exposure=2.1, door=0.0, av=kids_walk(w, w * 7 * TAU / 3)), None)
shot("hook", 105, s_hook)

# 2. (card) Jamie goes to the linen closet and opens it... he's folded up inside, looking out; he bursts
# out at you (frame 60: the jolt); they bolt back past you
JAMIE_AT = [7.4, U, -4.6]
INSIDE = [10.6, U, -5.0]
BURST_TO = [5.4, U, -0.8]
def s_card(i, k):
    cam = add(lerp(CAM1, [1.2, U + EYE, 7.0], ease(i / 40)), hand(i, 0.7 + (1.6 if 60 <= i < 72 else 0)))
    if 60 <= i < 68:
        cam = add(cam, run_shake(i, 0.6))
    look = lerp([5.0, U + 4.2, -6.0], [8.6, U + 4.6, -5.0], ease((i - 10) / 30))
    if i >= 60:
        look = lerp(look, [5.4, U + 5.4, -0.8], ease((i - 60) / 8))
    if i >= 104:
        # (and you turn and run)
        t = ease((i - 104) / 12)
        look = lerp([5.4, U + 5.4, -0.8], [2.0, U + 4.6, 20.0], t)
        look[0] += -7.0 * math.sin(math.pi * t)
    tgt = lerp([4.0, U + 3.4, -3.0], [9.6, U + 4.4, -5.0], ease((i - 10) / 30))
    door = 1.7 * ease((i - 34) / 8)
    # Jamie: to the closet, reaching for the handle; then back, falling over themselves to get away
    if i < 30:
        jp = lerp(J1, JAMIE_AT, ease(i / 30))
        jv = player(1, jp, facing(J1, JAMIE_AT), i / 30 * 3 * TAU / 3, False)
    elif i < 60:
        jv = player(1, JAMIE_AT, facing(JAMIE_AT, INSIDE), 0, False, REACH_OUT if i < 44 else dict(AFRAID, neckX=-0.2),
                    face=SMILE if i < 44 else SCARED)
    else:
        r = (i - 60) / 26
        e = [cam[0] + 3.0, U, cam[2] + 4.5]
        jp = lerp(JAMIE_AT, e, min(1.0, r))
        jv = player(1, jp, facing(JAMIE_AT, e), r * 7 * TAU, True, face=SCARED)
    # Riley: by the stair rail, turning to watch, then running too
    if i < 60:
        rv = player(0, R1, facing(R1, JAMIE_AT) + (0.0 if i < 46 else 0.0), 0, False, AFRAID if i >= 46 else None, face=UHOH if i >= 46 else SMILE)
    else:
        r = (i - 60) / 22
        e = [cam[0] - 2.8, U, cam[2] + 4.5]
        rp = lerp(R1, e, min(1.0, r))
        rv = player(0, rp, facing(R1, e), r * 7 * TAU + 1.4, True, face=SCARED)
    av = [a for a in (rv, jv) if math.hypot(a["pos"][0] - cam[0], a["pos"][2] - cam[2]) > 1.8]
    if i < 36:
        cr = None
    elif i < 60:
        cr = {"pos": INSIDE, "yaw": facing(INSIDE, [0, U, -5.0]), "gait": "Stare", "t": stop(i), "duck": 1.0, "jaw": 0.1 + 0.5 * ease((i - 46) / 12),
              "neck": [0.3, 0.0, -0.7 + 0.1 * math.sin(i * 0.7)]}
    else:
        c = ease((i - 60) / 18)
        p = lerp(INSIDE, BURST_TO, c)
        cr = {"pos": p, "yaw": facing(INSIDE, BURST_TO), "gait": "Chase" if i < 80 else "Stare", "phase": c * 5 * RUN, "t": stop(i), "jaw": 1.0,
              "neck": [0.0, 0.0, 0.0] if i < 80 else [0.1, 0.0, -0.5]}
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 70}, flash=fl(cam, tgt, 14.0, 0.3), exposure=2.1,
                 door=door, glow=1.5 if i < 60 else 5, av=av), cr)
shot("card", 120, s_card)

# 3. down the hall, running south, looking back: Jamie and Riley behind you, him after them; they dive
# aside; you stop, turn: the rocket launcher. The shot (46), the blast (53): he's blown off his feet
FIRE, HIT = 46, 53
KNOCK = 1.45            # (blown onto his back)
def hall_run_cam(i):
    zc = 2.0 + 8.0 * ease(min(1.0, i / 40))
    return [2.2, U + 5.2, zc]
def him_hall(i):
    # out of the closet and down the hall after you; blown back at HIT
    if i < HIT:
        c = i / HIT
        return lerp([4.4, U, -10.0], [2.6, U, 2.0], c), "Chase"
    b = ease((i - HIT) / 8)
    return [2.6 + 0.3 * b, U, 2.0 - 4.5 * b], "Stunned"
def s_hall(i, k):
    zc_cam = hall_run_cam(i)
    still = i >= 40
    cam = add(zc_cam, run_shake(i, 1.0 if not still else 0.15))
    if HIT <= i < HIT + 10:
        cam = add(cam, run_shake(i * 3, 0.9 * (1 - (i - HIT) / 10)))
    hp, g = him_hall(i)
    look = [2.4, U + 4.2, zc_cam[2] - 12.0]
    if still:
        look = lerp(look, [hp[0], U + 4.6, hp[2]], ease((i - 40) / 6))
    zc = zc_cam[2]
    # Jamie and Riley: running behind you, then diving to the walls to clear the shot
    jz, rz = zc - 8.5, zc - 12.5
    dive = ease((i - 34) / 10)
    jp = [lerp([-1.6], [-5.6], dive)[0], U, jz + 2.0 * dive]
    rp = [lerp([6.0], [9.4], dive)[0], U, rz + 4.0 * dive]
    face_j = facing([0, 0, 0], [0, 0, 1]) if dive < 0.5 else facing(jp, [-8, U, jz])
    face_r = facing([0, 0, 0], [0, 0, 1]) if dive < 0.5 else facing(rp, [12, U, rz])
    av = [player(1, jp, face_j, k * 9 * TAU, dive < 1.0, face=SCARED) if dive < 1.0 else player(1, jp, facing(jp, hp), 0, False, CROUCH, face=SCARED),
          player(0, rp, face_r, k * 9 * TAU + 1.3, dive < 1.0, face=SCARED) if dive < 1.0 else player(0, rp, facing(rp, hp), 0, False, CROUCH, face=SCARED)]
    for a in av:
        if a["pose"] is CROUCH or a["pose"] == CROUCH:
            a["pos"][1] -= 1.25
    if g == "Chase":
        cr = {"pos": hp, "yaw": facing(hp, cam), "gait": "Chase", "phase": i / 30 * 14 * RUN, "t": stop(i), "jaw": 0.95}
    else:
        cr = {"pos": hp, "yaw": facing(hp, cam), "gait": "Stunned", "t": (i - HIT) / 30, "jaw": 0.9, "pitch": KNOCK * ease((i - HIT) / 6)}
    chest = [hp[0], U + 5.4, hp[2]]
    burst = {"pos": [chest[0], chest[1], chest[2] + 1.0], "col": "#ffa04a", "i": 60.0 * max(0.0, 1 - (i - HIT) / 9), "r": 46} if i >= HIT else None
    fr = dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 70, "roll": 0.05 * math.sin(i * 0.9) if not still else 0.0},
              flash=fl(cam, [hp[0], U + 4.0, hp[2]], 14.0, 0.4), exposure=2.1, glow=6, door=1.7, av=av,
              lightning=0.35 * max(0.0, 1 - (i - HIT) / 6) if i >= HIT else 0.0)
    if burst: fr["burst"] = burst
    return (fr, cr)
shot("hall", 72, s_hall)

# 4. he's down in the smoke, twitching; you turn and run for Lily's room, Jamie and Riley ahead of you
def s_down(i, k):
    hp, _ = him_hall(72 + i)
    cam0 = hall_run_cam(72)
    t = ease(i / 20)
    look = lerp([hp[0], U + 2.6, hp[2]], [12.0, U + 4.6, 22.0], t)
    look[0] += 6.0 * math.sin(math.pi * t)
    cam = add(lerp(cam0, [4.0, U + EYE, 14.0], ease((i - 10) / 23)), run_shake(i, 0.3 + 0.7 * t))
    jp = lerp([-4.0, U, 9.0], [11.0, U, 20.4], ease(i / 33))
    rp = lerp([8.0, U, 7.0], [12.6, U, 19.4], ease(i / 26))
    av = [player(1, jp, facing(jp, [12, U, 20.4]), i / 30 * 7 * TAU, True, face=SCARED), player(0, rp, facing(rp, [13, U, 19.4]), i / 30 * 7 * TAU + 1, True, face=SCARED)]
    return (dict(DARK, shot="hall2", cam={"pos": cam, "look": look, "fov": 70}, exposure=2.1, glow=4, door=1.6, av=av,
                 flash=fl(cam, look, 12.0, 0.4)),
            {"pos": hp, "yaw": facing(hp, cam0), "gait": "Stunned", "t": (72 + i - HIT) / 30, "jaw": 0.8, "pitch": KNOCK})
shot("down", 33, s_down)

# 5. Lily's room: across the rug and into her play tent, turning round to the flap; through it, Riley
# ducks down beside her bed
RILEY_CROUCHED = lambda i, look=0.0, face=SCARED: {"i": 0, "pos": [RILEY_HIDE[0], U + AV - 1.25 + 0.02 * math.sin(i * 0.9), RILEY_HIDE[2]],
                                                    "yaw": facing(RILEY_HIDE, TENT_EYE), "pose": dict(CROUCH, neckY=look), "face": face}
def s_tent(i, k):
    if i < 30:
        cam = add(lerp([13.0, U + EYE, 20.0], [22.4, U + EYE - 0.6, 15.0], ease(i / 30)), run_shake(i, 0.6))
        look = lerp([22.0, U + 3.0, 17.0], [20.6, U + 1.6, 9.0], ease(i / 30))
    else:
        j = (i - 30) / 60
        a = ease(min(1.0, j / 0.55))
        cam = lerp([22.4, U + EYE - 0.6, 15.0], [20.4, U + 2.2, 11.2], a)
        cam = lerp(cam, TENT_EYE, ease((j - 0.55) / 0.3))
        turn = ease((j - 0.25) / 0.5)
        look = lerp([19.6, U + 1.4, 8.0], TENT_LOOK, turn)
        cam = add(cam, hand(i, 0.7))
    if i < 40:
        rp = lerp([23.0, U, 22.8], RILEY_HIDE, ease(i / 40))
        av = [player(0, rp, facing([23.0, U, 22.8], RILEY_HIDE), i / 30 * 6 * TAU, True, face=SCARED)]
    else:
        av = [RILEY_CROUCHED(i)]
    return (dict(DARK, shot="room", cam={"pos": cam, "look": look, "fov": 64 if i >= 30 else 70}, exposure=2.3, door=1.6, av=av,
                 flash=fl(cam, look, 9.0 * (1 - ease((i - 50) / 20)), 0.45)), None)
shot("tent", 90, s_tent)

def tent(i, extra=None):
    fr = dict(DARK, shot="room", cam={"pos": [TENT_EYE[0], TENT_EYE[1] + 0.03 * math.sin(i * 0.31), TENT_EYE[2]], "look": TENT_LOOK, "fov": 66},
              exposure=2.6, glow=4, door=1.6)
    if extra: fr.update(extra)
    return fr

# 6. he comes in through her door, hunched, sniffing across the rug; Riley frozen by the bed
DOORIN = [13.4, U, 20.0]
NEARR = [23.8, U, 20.0]
def s_in(i, k):
    w = ease(i / 60)
    p = lerp(DOORIN, [22.6, U, 18.6], w)
    return (tent(i, {"av": [RILEY_CROUCHED(i, 0.3 * math.sin(i * 0.05))]}),
            {"pos": p, "yaw": facing(DOORIN, [22.6, U, 18.6]), "gait": "Search", "phase": w * 6 * math.tau / 6.2, "t": stop(i), "duck": 0.5, "jaw": 0.25})
shot("in", 60, s_in)

# 7. his head turns to the bed; two strides and he has Riley (the jolt at 16): lifted, kicking, carried out
def s_grab(i, k):
    a = [22.6, U, 18.6]
    if i < 16:
        c = ease(i / 16)
        p = lerp(a, NEARR, c)
        cr = {"pos": p, "yaw": facing(a, NEARR), "gait": "Chase", "phase": c * 2 * RUN, "t": stop(i), "jaw": 0.9}
        av = [RILEY_CROUCHED(i, -0.2)]
    else:
        j = i - 16
        lift = ease(j / 9)
        out = ease((j - 16) / 28)
        p = lerp(NEARR, DOORIN, out)
        cr = {"pos": p, "yaw": facing(NEARR, RILEY_HIDE) if out <= 0 else facing(NEARR, DOORIN), "gait": "Reach" if out <= 0 else "Walk",
              "t": j / 30, "phase": out * 5 * math.tau / 6.2, "jaw": 1.0}
        rp = lerp(RILEY_HIDE, [p[0] + 0.8, U, p[2] + 0.9], 0.55 + 0.45 * out)
        kick = dict(FLAIL) if (i // 2) % 2 else dict(FLAIL, lHip=-0.3, rHip=0.6, lKnee=-0.2, rKnee=-1.0)
        av = [{"i": 0, "pos": [rp[0], U + AV + 0.2 + 3.4 * lift, rp[2]], "yaw": facing(rp, TENT_EYE), "pose": kick, "pitch": 0.2, "face": SCARED}]
    return (tent(i, {"av": av, "glow": 5}), cr)
shot("grab", 60, s_grab)

# 8. quiet. The empty room through the flap... then he comes back in, slowly, straight for the tent
VIEW = [TENT_LOOK[0] - TENT_EYE[0], 0, TENT_LOOK[2] - TENT_EYE[2]]
VL = math.hypot(VIEW[0], VIEW[2]); VD = [VIEW[0] / VL, VIEW[2] / VL]
STOPAT = [TENT_EYE[0] + VD[0] * 12.0, U, TENT_EYE[2] + VD[1] * 12.0]
LEAN = [TENT_EYE[0] + VD[0] * 11.0, U, TENT_EYE[2] + VD[1] * 11.0]
def s_back(i, k):
    if i < 26:
        return (tent(i, {"av": []}), None)
    w = ease((i - 26) / 34)
    p = lerp(DOORIN, STOPAT, w)
    return (tent(i, {"av": []}), {"pos": p, "yaw": facing(DOORIN, STOPAT), "gait": "Walk", "phase": w * 5 * math.tau / 6.2, "t": stop(i), "jaw": 0.3})
shot("back", 60, s_back)

# 9. he folds down to the flap... his face at the gap; gone; and there on the hit (frame 64: 22.15 s)
def s_tear(i, k):
    if i < 64:
        if i < 14:
            return (tent(i, {"glow": 5, "av": []}), {"pos": STOPAT, "yaw": facing(STOPAT, TENT_EYE), "gait": "Stare", "t": stop(i),
                                                     "neck": [0.2, 0.0, -0.6 * ease(i / 10)], "jaw": 0.2})
        if i < 42:
            w = math.floor(ease((i - 14) / 20) * 9) / 9
            p = lerp(STOPAT, LEAN, w)
            return (tent(i, {"glow": 6, "av": []}), {"pos": p, "yaw": facing(p, TENT_EYE), "gait": "Stare", "t": stop(i), "pitch": -1.33 * w,
                                                     "neck": [1.33 * w, 0.0, -0.5 * w - 0.2], "jaw": 0.2 + 0.4 * w})
        return (tent(i, {"av": []}), None)
    face = [TENT_EYE[0] + VD[0] * 1.6, U + 1.9, TENT_EYE[2] + VD[1] * 1.6]
    fr = tent(i, {"glow": 10, "exposure": 2.6, "av": [], "flash": {"i": 10.0, "pos": [TENT_EYE[0], TENT_EYE[1] - 0.4, TENT_EYE[2] + 0.2], "target": face, "angle": 0.5}})
    fr["cam"]["look"] = face
    fr["cam"]["fov"] = 72
    near = [TENT_EYE[0] + VD[0] * 10.5, U, TENT_EYE[2] + VD[1] * 10.5]
    return (fr, {"pos": near, "yaw": facing(near, TENT_EYE), "gait": "Stare", "t": stop(i), "pitch": -1.36,
                 "neck": [1.36, 0.0, -0.4 + 0.35 * math.sin(i * 1.3)], "jaw": 1.0})
shot("tear", 75, s_tear)

# 10. RUN: out in the hall, looking back: he comes through her door after you on all fours
def s_run(i, k):
    cam = add([3.0, U + 4.6, 6.0 - 2.0 * k], run_shake(i))
    p = lerp([14.5, U, 20.0], [7.5, U, 15.0], ease(min(1.0, k * 1.2)))
    return (dict(DARK, shot="hall2", cam={"pos": cam, "look": [p[0], U + 3.4, p[2]], "fov": 66, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [p[0], U + 3.5, p[2]], 18.0, 0.36), exposure=1.9, glow=8, door=1.6, av=[]),
            {"pos": p, "yaw": facing(p, cam), "gait": "Chase", "phase": k * 14 * RUN, "t": stop(i), "jaw": 0.9})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
tent0 = next(sh["start"] for sh in shots if sh["name"] == "tent")
run0 = next(sh["start"] for sh in shots if sh["name"] == "run")
for fr in frames:
    # (the tent's canvas only for the shots inside it)
    if not (tent0 + 30 <= fr["f"] < run0):
        fr["hideExtras"] = [[e["pos"][0], e["pos"][1] - 0.22, e["pos"][2]] for e in EXTRAS]
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": AVS, "extras": EXTRAS,
           "props": {"cache": f"{S}/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
