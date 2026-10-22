# Reel 40 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 5)", the gameplay series in reel 38's style
# (real Roblox avatars, little text, scares). This one is BECOME HIM (the 25 R$ product: 4 of 76 bought
# it at 25, 0 of 49 at 50): you play him, the camera behind him as in the game (client Monster), the
# dark lit up pink for you, the YOU ARE HIM bar, and every noise they make a red ping. Then the last
# two clips from Jamie's eyes, in the closet, for the scare. On #2's track, every clip at #2's length.
#   hook (105)  behind him, down the dark upstairs hall: Riley and Jamie ahead, their backs to him
#   card (120)  Riley's flashlight swings round onto him; they scream and split; he lunges (jolt)
#   72          after Riley into the bathroom; Riley dives into the shower, the curtain pulled shut
#   33          a red ping behind the curtain: Riley's breathing
#   90          he walks up to the curtain, Riley's shape behind it... and rips it open (jolt)
#   60          Riley lifted off the floor, kicking
#   60          he turns: across the hall, the linen closet door eases shut
#   60          out to the closet; he stands in front of it
#   75          Jamie's eyes, through the crack: he folds down to it... backs off... the doors torn open
#               on 22.15 s
#   30          RUN: down the stairs, him after you
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

WALK = math.tau / 6.2
COLD, MOON = "#3d4f7a", "#6f86c4"
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.5, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}
DARK = {"ambient": 0.03, "bg": 0x010102}

def fwd(yaw): return [-math.sin(yaw), 0.0, -math.cos(yaw)]
def right(yaw): return [math.cos(yaw), 0.0, -math.sin(yaw)]
def follow(p, yaw, back=6.0, up=12.2, side=1.2, ahead=15.0, look_y=1.5):
    # Become Him's camera: behind him, up under the ceiling (U + 13) the way Roblox's camera ends up indoors
    # with a 10-ft body, looking down past his shoulders the way he faces
    f, r = fwd(yaw), right(yaw)
    cam = [p[0] - f[0] * back + r[0] * side, p[1] + up, p[2] - f[2] * back + r[2] * side]
    look = [p[0] + f[0] * ahead, p[1] + look_y, p[2] + f[2] * ahead]
    return cam, look

# --- the upstairs hall (x -8..12; the stair opening on its west side) and the upstairs bathroom
# (x 12..40, z -6..8; its door in the x = 12 wall at z 1; the shower stall x 33.4..39.1, z 2.9..7.6,
# open on its x = 33.3 side behind a curtain hinged at z 7.6); the linen closet in the hall's east side
# (x 9.3..11.4, z -3.6..-7.8), its left leaf hinged at z -3.6
BATH_DOOR = {"near": [12.0, U + 4.7, 1.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [12.0, 0, -1.42], "axis": "y"}
BATH_DOOR_GONE = {"names": ["Panel", "Inset", "Knob"], "near": [12.0, 0.4], "r": 2.6}
CURTAIN_NAMES = ["ShowerCurtain", "CurtainFold"]
CURTAIN = {"near": [33.3, U + 5.5, 5.3], "r": 3.6, "names": CURTAIN_NAMES, "hinge": [33.3, 0, 7.6], "axis": "y"}
SEE_THROUGH = {"names": CURTAIN_NAMES, "near": [33.3, U + 5.5, 5.3], "r": 3.6, "opacity": 0.34}
CLOSET = {"near": [9.25, U + 4.5, -4.8], "r": 2.3, "names": ["WardrobeLeaf", "DoorPanel", "PanelInset"], "hinge": [9.32, 0, -3.6], "axis": "y"}
HALL = [{"p": [2, U + 11, -29], "col": MOON, "b": 3.2, "r": 30, "decay": 1.1}, {"p": [2.5, U + 9, -9], "col": "#5d72a8", "b": 3.0, "r": 20},
        {"p": [5, U + 7, -3], "col": COLD, "b": 1.4, "r": 14}, {"p": [2, U + 8, 10], "col": "#5d72a8", "b": 2.0, "r": 18},
        {"p": [3.0, U + 8, -7.5], "col": "#5d72a8", "b": 1.6, "r": 12}]
BATH = [{"p": [43.0, U + 8, 1.0], "col": MOON, "b": 3.2, "r": 34, "decay": 1.0},       # the moon through the window
        {"p": [8.5, U + 4.5, 1.0], "col": "#5d72a8", "b": 1.8, "r": 10},
        {"p": [26.0, U + 6.0, 1.0], "col": COLD, "b": 1.2, "r": 16}, {"p": [30.0, U + 8, 3], "col": COLD, "b": 1.0, "r": 12}]
STAIR_LIGHTS = [{"p": [-5, U + 6, 22], "col": "#2c3d6e", "b": 1.3, "r": 26}, {"p": [-5, 8, -2], "col": COLD, "b": 1.4, "r": 18},
                {"p": [-5, G + 7, -12], "col": COLD, "b": 1.0, "r": 16}]
SHOTS = {
    "hall": {"center": [3, U + 5, -8], "radius": 40, "lampRadius": 0, "maxLamps": 0, "door": BATH_DOOR,
             "lights": HALL + [{"p": [13.5, U + 6, 1.0], "col": MOON, "b": 2.2, "r": 13}]},   # (moonlight through the bathroom door)
    "bath": {"center": [24, U + 5, 1], "radius": 34, "lampRadius": 0, "maxLamps": 0, "door": CURTAIN, "translucent": SEE_THROUGH,
             "hide": ["Globe", BATH_DOOR_GONE], "lights": BATH},
    "out": {"center": [8, U + 5, -3], "radius": 36, "lampRadius": 0, "maxLamps": 0, "door": CLOSET, "hide": [BATH_DOOR_GONE], "lights": HALL + [{"p": [6.0, U + 9, -4.0], "col": MOON, "b": 2.2, "r": 14}]},
    "closet": {"center": [6, U + 5, -6], "radius": 30, "lampRadius": 0, "maxLamps": 0, "hide": ["Handle", BATH_DOOR_GONE], "door": CLOSET, "lights": HALL},
    "stairs": {"center": [-5, 8, 4], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": STAIR_LIGHTS},
}

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

def him_frame(i, cam_look, shot_name, extra=None, fov=68):
    cam, look = cam_look
    fr = dict(DARK, shot=shot_name, cam={"pos": add(cam, hand(i, 0.6)), "look": look, "fov": fov}, exposure=2.4, glow=1.2, door=1.4, him=True)
    if extra: fr.update(extra)
    return fr

# 1. (hook) behind him, down the dark upstairs hall; Riley and Jamie ahead, their backs to him
H0, H1 = [3.4, U, -21.0], [3.4, U, -15.0]
SOUTH = facing(H0, [3.4, U, 10.0])
R0, R1 = [1.8, U, -7.5], [1.8, U, -2.4]
J0, J1 = [5.2, U, -6.8], [5.2, U, -1.8]
def riley_light(pr, tgt, i=11.0):
    return {"i": i, "pos": [pr[0] + 0.5, U + 3.6, pr[2] + 0.4], "target": tgt, "angle": 0.42}
def s_hook(i, k):
    w = ease(k)
    p = lerp(H0, H1, w)
    pr, pj = lerp(R0, R1, w), lerp(J0, J1, w)
    av = [player(0, pr, SOUTH, w * 6 * TAU / 3, False), player(1, pj, SOUTH, w * 6 * TAU / 3 + 2.2, False)]
    cr = {"pos": p, "yaw": SOUTH, "gait": "Walk", "phase": w * 4 * WALK, "t": stop(i), "jaw": 0.15}
    return (him_frame(i, follow(p, SOUTH), "hall", {"av": av, "flash": riley_light(pr, [pr[0], U + 1.5, pr[2] + 9.0]), "door": 0.0}), cr)
shot("hook", 105, s_hook)

# 2. (card) they stop; Riley turns round, the flashlight swings onto him; screams; they split (Riley for
# the bathroom door, Jamie down the hall) and he lunges after Riley (the jolt at 56)
BATH_IN = [10.6, U, 0.9]
LUNGE = 56
def s_card(i, k):
    if i < LUNGE:
        p, yaw = H1, SOUTH
        turn = ease((i - 26) / 12)
        tgt = lerp([R1[0], U + 1.5, R1[2] + 9.0], [H1[0], U + 7.2, H1[2]], turn)
        av = [player(0, R1, SOUTH + math.pi * turn, 0, False, AFRAID if i > 40 else None, face=SCARED if i > 40 else SMILE),
              player(1, J1, SOUTH + math.pi * ease((i - 34) / 10), 0, False, AFRAID if i > 44 else None, face=SCARED if i > 44 else SMILE)]
        cr = {"pos": p, "yaw": yaw, "gait": "Stare", "t": stop(i), "neck": [0.15, 0.0, -0.5 * ease((i - 30) / 10)], "jaw": 0.15 + 0.8 * ease((i - 40) / 12)}
        fr = him_frame(i, follow(p, yaw), "hall", {"av": av, "flash": riley_light(R1, tgt, 13.0), "door": 0.0, "glow": 2.5})
        return (fr, cr)
    j = i - LUNGE
    c = ease(j / 60)
    p = lerp(H1, [BATH_IN[0] - 2.0, U, BATH_IN[2] - 1.0], c)
    yaw = facing(H1, BATH_IN)
    yaw_cam = SOUTH + (yaw - SOUTH) * ease(j / 18)
    rr = clamp(j / 28)
    rp = lerp(R1, [12.8, U, 1.0], rr)
    jp = lerp(J1, [4.6, U, 16.0], clamp(j / 40))
    av = []
    if rr < 1.0:
        av.append(player(0, rp, facing(R1, [12.8, U, 1.0]), j / 30 * 7 * TAU, True, face=SCARED))
    if j < 40:
        av.append(player(1, jp, facing(J1, [4.6, U, 16.0]), j / 30 * 7 * TAU + 1.4, True, face=SCARED))
    door = 1.4 * ease((j - 8) / 6)
    cr = {"pos": p, "yaw": yaw, "gait": "Chase", "phase": c * 8 * RUN, "t": stop(i), "jaw": 1.0}
    cam, look = follow(p, yaw_cam)
    if j < 8:
        cam = add(cam, run_shake(i, 0.7))
    extra = {"av": av, "door": door, "glow": 2.5}
    if rr < 1.0:
        extra["flash"] = riley_light(rp, [rp[0] + 3.0, U + 1.0, rp[2] + 4.0], 13.0)   # (Riley's light bouncing as they run)
    return (him_frame(i, (cam, look), "hall", extra), cr)
shot("card", 120, s_card)

# 3. after Riley into the bathroom: Riley dives into the shower and pulls the curtain shut
EAST = facing([0, U, 0], [10, U, 0])
B0, B1 = [12.6, U, 0.6], [21.5, U, 1.6]
SHOWER_IN = [36.2, U, 5.3]
def s_bath(i, k):
    c = ease(k)
    p = lerp(B0, B1, c)
    rr = clamp(i / 30)
    rp = lerp([20.0, U, 1.4], [32.4, U, 4.6], rr) if rr < 1 else lerp([32.4, U, 4.6], SHOWER_IN, clamp((i - 30) / 8))
    av = [player(0, rp, facing([20.0, U, 1.4], [32.4, U, 4.6]) if rr < 1 else facing([32.4, U, 4.6], SHOWER_IN), i / 30 * 7 * TAU, True, face=SCARED)]
    curtain = 1.4 * (1 - ease((i - 40) / 14))
    cr = {"pos": p, "yaw": facing(B0, B1), "gait": "Chase", "phase": c * 6 * RUN, "t": stop(i), "jaw": 1.0}
    cam, look = follow(p, facing(B0, B1))
    cam[0] = max(cam[0], 12.9)
    return (him_frame(i, (cam, look), "bath", {"av": av, "door": curtain, "glow": 2.0}), cr)
shot("bath", 72, s_bath)

# 4. he stops; a red ping behind the curtain: Riley's breathing
AFRAID_IN = dict(AFRAID, neckX=-0.05)
def riley_in(i, face=SCARED, pose=None):
    return player(0, SHOWER_IN, facing(SHOWER_IN, [20, U, 2.0]), 0, False, pose or dict(AFRAID_IN, waist=0.25, neckY=0.1 * math.sin(i * 0.3)), face=face)
def s_ping(i, k):
    cr = {"pos": B1, "yaw": facing(B1, SHOWER_IN), "gait": "Stare", "t": stop(i), "neck": [0.2, 0.0, -0.5 * ease(i / 10)], "jaw": 0.3}
    return (him_frame(i, follow(B1, facing(B1, SHOWER_IN)), "bath", {"av": [riley_in(i)], "door": 0.0, "glow": 1.5}), cr)
shot("ping", 33, s_ping)

# 5. he walks up to the curtain, Riley's shape behind it... and rips it open (frame 70: the jolt)
CURT_AT = [30.6, U, 4.4]
RIP = 70
def s_curtain(i, k):
    yaw = facing(CURT_AT, SHOWER_IN)
    if i < 50:
        w = ease(i / 50)
        p = lerp(B1, CURT_AT, w)
        cr = {"pos": p, "yaw": facing(B1, CURT_AT), "gait": "Walk", "phase": w * 4 * WALK, "t": stop(i), "jaw": 0.3}
    elif i < RIP:
        p = CURT_AT
        cr = {"pos": p, "yaw": yaw, "gait": "Stare", "t": stop(i), "neck": [0.3, 0.0, -0.7], "jaw": 0.3 + 0.5 * ease((i - 54) / 12)}
    else:
        p = CURT_AT
        cr = {"pos": p, "yaw": yaw, "gait": "Reach", "t": (i - RIP) / 30, "jaw": 1.0}
    curtain = 1.6 * ease((i - RIP) / 4) if i >= RIP else 0.0
    cam, look = follow(p, facing(B1, CURT_AT) if i < 50 else yaw)
    if RIP <= i < RIP + 8:
        cam = add(cam, run_shake(i, 0.5))
    return (him_frame(i, (cam, look), "bath", {"av": [riley_in(i, SCARED, dict(AFRAID_IN, lShoulder=[1.2, 0, -0.6], rShoulder=[1.2, 0, 0.6]) if i >= RIP else None)],
                                               "door": curtain, "glow": 1.5 if i < RIP else 3.5}), cr)
shot("curtain", 90, s_curtain)

# 6. Riley lifted off the floor in his hands, kicking
def s_lift(i, k):
    yaw = facing(CURT_AT, SHOWER_IN)
    lift = ease(i / 10)
    rp = lerp(SHOWER_IN, [33.6, U, 4.8], ease(i / 12))
    kick = dict(FLAIL) if (i // 2) % 2 else dict(FLAIL, lHip=-0.3, rHip=0.6, lKnee=-0.2, rKnee=-1.0)
    av = [{"i": 0, "pos": [rp[0], U + AV + 2.8 * lift, rp[2]], "yaw": facing(rp, CURT_AT), "pose": kick, "pitch": 0.15, "face": SCARED}]
    cr = {"pos": CURT_AT, "yaw": yaw, "gait": "Reach", "t": 0.8 + i / 30, "jaw": 1.0, "duck": 0.2}
    cam, look = follow(CURT_AT, yaw, back=5.0, ahead=6.0, look_y=4.0)
    return (him_frame(i, (cam, add(look, [0.0, 0.2 * math.sin(i * 0.5), 0.0])), "bath", {"av": av, "door": 1.6, "glow": 3.0}), cr)
shot("lift", 60, s_lift)

# 7. out in the hall: he looks down the hall for Jamie... and turns: the linen closet door eases shut
TURN_AT = [5.4, U, 2.2]
CLOSET_FRONT = [9.3, U, -5.7]
def s_turn(i, k):
    yaw0 = facing(TURN_AT, [4.6, U, 16.0])
    yaw1 = facing(TURN_AT, CLOSET_FRONT)
    t = ease((i - 14) / 16)
    d = ((yaw1 - yaw0 + math.pi) % TAU) - math.pi
    yaw = yaw0 + d * t
    cr = {"pos": TURN_AT, "yaw": yaw, "gait": "Stare", "t": stop(i), "neck": [0.15, 0.0, -0.4 * ease((i - 30) / 10)], "jaw": 0.4}
    closet = 0.55 * (1 - ease((i - 30) / 12))
    cam, look = follow(TURN_AT, yaw1, back=6.5, ahead=10.0)
    return (him_frame(i, (cam, look), "out", {"av": [], "door": closet, "glow": 1.2}), cr)
shot("turn", 60, s_turn)

# 8. out of the bathroom to the closet; he stands in front of it
STAND = [5.6, U, -5.6]
def s_closet(i, k):
    a = TURN_AT
    if i < 40:
        w = ease(i / 40)
        p = lerp(a, STAND, w)
        yaw = facing(a, STAND)
        cr = {"pos": p, "yaw": yaw, "gait": "Walk", "phase": w * 5 * WALK, "t": stop(i), "jaw": 0.3}
    else:
        p = STAND
        y0, y1 = facing(TURN_AT, STAND), facing(STAND, [10.4, U, -5.6])
        d = ((y1 - y0 + math.pi) % TAU) - math.pi
        yaw = y0 + d * ease((i - 40) / 10)
        cr = {"pos": p, "yaw": yaw, "gait": "Stare", "t": stop(i), "neck": [0.3, 0.0, -0.6], "jaw": 0.4}
    cam, look = follow(p, yaw)
    return (him_frame(i, (cam, look), "out", {"av": [], "door": 0.0, "glow": 1.2}), cr)
shot("closet", 60, s_closet)

# 9. Jamie's eyes, in the closet: he folds down to the crack... backs off... nothing... and the doors are
# torn open (22.15 s: frame 64)
CLOSET_EYE = [10.38, U + 4.9, -5.66]
CLOSET_LOOK = [2.0, U + 7.0, -6.8]
CRACK = 0.45
PEEK = [1.4, U, -6.0]
SCARE = [0.9, U, -5.0]
def crack(i, extra=None, door=CRACK):
    fr = dict(DARK, shot="closet", cam={"pos": [CLOSET_EYE[0], CLOSET_EYE[1] + 0.03 * math.sin(i * 0.31), CLOSET_EYE[2]], "look": CLOSET_LOOK, "fov": 62},
              exposure=2.3, glow=3, door=door, av=[])
    if extra: fr.update(extra)
    return fr
def s_tear(i, k):
    if i < 64:
        if i < 26:
            w = math.floor(ease(i / 20) * 9) / 9
            p = lerp(STAND, PEEK, w)
            return (crack(i, {"glow": 0.3}), {"pos": p, "yaw": facing(p, CLOSET_EYE), "gait": "Stare", "t": stop(i), "pitch": -0.97 * w,
                                            "neck": [0.97 * w, 0.0, -0.55 * w - 0.3], "jaw": 0.1 + 0.4 * w})
        if i < 40:
            return (crack(i, {"glow": 0.3}), {"pos": PEEK, "yaw": facing(PEEK, CLOSET_EYE), "gait": "Stare", "t": stop(i), "pitch": -0.97,
                                            "neck": [0.97, 0.0, -0.85 + 0.5 * ease((i - 26) / 10)], "jaw": 0.5})
        if i < 56:
            w = math.floor(ease((i - 40) / 14) * 8) / 8
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
def sy(z): return max(G, min(U, 2.05 + 0.625 * (z + 5.3) - 1.0))
def s_run(i, k):
    zc = 2.0 - 7.0 * k
    cam = [-5.0 + 0.25 * math.sin(i * 1.7), sy(zc) + 5.0 + 0.2 * math.sin(i * 2.3), zc]
    zh = 17.0 - 9.0 * k
    hy = sy(zh) if zh < 15.5 else U
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, hy + 3.0, zh], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [-5.0 + 1.2 * math.sin(i * 1.3), hy + 4.0, zh], 18.0, 0.36), ambient=0.01, exposure=1.8, glow=9, av=[]),
            {"pos": [-5.0, hy, zh], "yaw": facing([-5.0, hy, zh], [-5.0, hy, zh - 10]), "gait": "Chase", "phase": k * 15 * RUN, "t": stop(i),
             "pitch": 0.3 if zh < 15.5 else 0.0, "jaw": 0.9})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": AVS, "extras": [],
           "props": {"cache": f"{S}/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
