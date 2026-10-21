# Reel 37 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 2)", the gameplay series (reel 36 was
# Part 1). No story text: a night as you'd play it, in first person, on #2's track (every clip keeps
# #2's length, so its cuts and hits land); comp_peak draws the game's HUD over it. This one: the 911 call,
# the taser, hiding in the shower, your friend caught, cutting them free in the boiler room, and his voice.
#   hook (105)  at the upstairs bathroom window, the one bar: calling 911 (the call bar filling); a
#               lightning flash: him on the garage roof right outside, staring in
#   card (120)  the call goes through; the roof is empty; running footsteps; you turn round: the door
#               bursts open, him in the doorway
#   72          he charges across the bathroom; the taser: he drops, twitching
#   33          in the shower, the curtain yanked shut on him
#   90          through the curtain: he gets up; Riley makes a run for the door, he goes after them
#   60          the boiler room: Riley zip-tied to a pipe, Jamie running to them
#   60          "Cut free": the prompt filling, Riley looking up at you
#   60          Riley's free... and stares past you ("We're a family now.")
#   75          you turn round: the dark by the boiler... and he's in your face (the scare at 22.15 s)
#   30          RUN: out the door, Riley behind you, him after you both
# python3 scene.py [preview]. Writes spec.json, frames_in.json, shots.json (in the current directory).
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
U, B = 15.0, -13.0       # the upstairs floor, the basement floor
EYE = 5.4
AV = 3.0                 # an avatar's origin above its feet
WALK = math.tau / 6.2
RUN = math.tau / 8.5
TAU = math.tau
S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]
def stop(i, fps=13):
    return math.floor(i * fps / 30) / fps
def around(c, yaw, pitch=0.0, d=8.0):
    # a point d studs from c in the direction yaw (facing() convention), pitch up/down
    return [c[0] - math.sin(yaw) * math.cos(pitch) * d, c[1] + math.sin(pitch) * d, c[2] - math.cos(yaw) * math.cos(pitch) * d]

# --- your friends: Roblox avatars (avatar.js joints)
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
TIED = {"lShoulder": [-0.55, 0, 0.2], "rShoulder": [-0.55, 0, -0.2], "lElbow": -0.4, "rElbow": -0.4, "neckX": 0.15}
RILEY = {"hoodie": "#2f7de0", "hoodieDark": "#215ca8", "pants": "#2a2a33", "hair": "#e0b25a"}
JAMIE = {"hoodie": "#3fae5a", "hoodieDark": "#2c8043", "pants": "#3a3a40", "hair": "#141012", "skin": "#8d5a3b"}
AVS = [{"pos": [0, -200, 0], "yaw": 0, "face": "scared", "colors": RILEY},
       {"pos": [0, -200, 0], "yaw": 0, "face": "scared", "colors": JAMIE}]

COLD, MOON = "#3d4f7a", "#6f86c4"
# --- the upstairs bathroom (World): x 12..39.5, z -6..8; the hall door in the x = 12 wall at z = 1
# (hinged at z = -1.42, it swings into the bathroom); the window in the x = 40 wall at z = 1 (sill 19.9,
# the glass 20..24); the shower stall x 33.4..39.1, z 2.9..7.6, open on its x = 33.3 side (the curtain,
# hinged at z = 7.6); the vanity + mirror at x 17.5, z -4.3; the toilet at x 24, z -3.5; the linen
# cupboard (v105) x 18.1..22.4, z 5.3..8
BATH_DOOR = {"near": [12.0, U + 4.7, 1.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [12.0, 0, -1.42], "axis": "y"}
CURTAIN_NAMES = ["ShowerCurtain", "CurtainFold"]
CURTAIN = {"near": [33.3, U + 5.5, 5.3], "r": 3.6, "names": CURTAIN_NAMES, "hinge": [33.3, 0, 7.6], "axis": "y"}
SEE_THROUGH = {"names": CURTAIN_NAMES, "near": [33.3, U + 5.5, 5.3], "r": 3.6, "opacity": 0.34}
WIN_EYE = [36.6, U + EYE, 0.7]
DOORWAY = [13.4, U, 1.0]
BATH_DARK = [{"p": [43.0, U + 8, 1.0], "col": MOON, "b": 2.8, "r": 34, "decay": 1.0},       # the moon through the window
             {"p": [8.5, U + 4.5, 1.0], "col": "#5d72a8", "b": 1.8, "r": 10},               # the hall, behind the door
             {"p": [26.0, U + 4.0, 1.0], "col": COLD, "b": 0.5, "r": 14}]
SHOTS = {
    "window": {"center": [42, U + 4, 1], "radius": 40, "lampRadius": 0, "maxLamps": 0, "hide": ["Globe", "Glass"],
               "lights": [{"p": [50, U + 12, -4], "col": MOON, "b": 2.0, "r": 40, "decay": 1.0}, {"p": [34, U + 6, 2], "col": COLD, "b": 0.6, "r": 12}]},
    "bath": {"center": [26, U + 5, 1], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": BATH_DOOR, "lights": BATH_DARK, "hide": ["Globe"]},
    "shower": {"center": [28, U + 5, 3], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": CURTAIN, "translucent": SEE_THROUGH, "lights": BATH_DARK, "hide": ["Globe"]},
    "behind": {"center": [26, U + 5, 2], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": BATH_DOOR, "translucent": SEE_THROUGH, "hide": ["Globe"],
               "lights": BATH_DARK + [{"p": [30, U + 8, 3], "col": COLD, "b": 1.0, "r": 12}]},
}
# --- the boiler room (World): x -40..-20, z 10..30; pipes on the west wall; the boiler at (-24.5, 14.8)
# (its burner faces +x), the water heater at (-23.8, 26.2), the door at x = -20, z 17.6..22.4
ORANGE = "#ff8a3c"
PIPE_AT = [-37.2, B, 19.0]       # Riley, zip-tied to the pipe
RILEY_YAW = facing(PIPE_AT, [-29.0, B, 19.0])
BDOOR = {"near": [-20.0, B + 4.7, 20.0], "r": 3.4, "names": ["Panel", "Inset", "Knob"], "hinge": [-20.0, 0, 17.55], "axis": "y"}
OPEN = 1.35
BLIGHTS = [{"p": [-21.4, B + 1.6, 14.8], "col": ORANGE, "b": 3.0, "r": 18, "decay": 1.2},     # the boiler's burner window
           {"p": [-33.0, B + 7.0, 19.0], "col": ORANGE, "b": 0.9, "r": 18, "decay": 1.0},     # its glow on the pipes' side
           {"p": [-30.0, B + 11.6, 20.0], "col": "#ffcf95", "b": 1.5, "r": 26, "decay": 1.1}, # the bare bulb, dim
           {"p": [-30.0, B + 11.5, 20.0], "col": "#6a7ea8", "b": 0.5, "r": 18},               # cold light from the high windows
           {"p": [-14.0, B + 8.0, 20.0], "col": "#ffd2a0", "b": 1.0, "r": 12}]                # the basement beyond the door
SHOTS["boiler"] = {"center": [-30, B + 5, 20], "radius": 28, "lampRadius": 0, "maxLamps": 0, "lights": BLIGHTS, "door": BDOOR}
SHOTS["out"] = {"center": [-18, B + 5, 18], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": BLIGHTS, "door": BDOOR}
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

# 1. (hook) at the bathroom window, the one bar of signal: calling 911 (comp draws the call bar).
# Rain on the glass; the garage's flat roof 3 studs under the sill. A flash: nothing. Another: him,
# standing on the roof right outside, his face at the glass
ROOF = 16.8
ON_ROOF = [46.5, ROOF, 2.0]
def sky(lt):
    # the night sky through the window: storm-grey, white in a flash
    c = lerp([10, 13, 22], [120, 132, 168], lt)
    return (int(c[0]) << 16) | (int(c[1]) << 8) | int(c[2])
def bolt(lt):
    # lightning seen through the window: a cold light from high outside, on the roof (not in the room)
    return {"i": 110.0 * lt, "pos": [58.0, U + 40.0, 8.0], "target": [46.5, ROOF + 4, 2.0], "angle": 0.55} if lt > 0 else {"i": 0}
def s_hook(i, k):
    cam = add(lerp([38.0, U + EYE + 0.1, 1.95], [38.7, U + EYE, 1.9], ease(k)), hand(i, 0.5))
    lt = 0.8 if 30 <= i <= 32 else (1.0 if 78 <= i <= 81 else (0.55 if 84 <= i <= 86 else 0.0))
    cr = None
    if i >= 76:
        cr = {"pos": ON_ROOF, "yaw": facing(ON_ROOF, cam), "gait": "Stare", "t": stop(i), "neck": [0.25, 0.0, -0.45], "jaw": 0.1 + 0.4 * ease((i - 88) / 16)}
    return (dict(DARK, shot="window", cam={"pos": cam, "look": [44.0, U + 7.0, 1.95], "fov": 62}, exposure=2.1, flash=bolt(lt), lightning=0.12 * lt,
                 moon=0.25, glow=2, bg=sky(lt)), cr)
shot("hook", 105, s_hook)

# 2. (card) the call goes through; a flash: the roof's empty. Running footsteps in the hall; you turn
# round: the door bursts open, him in the doorway; Riley, between you and him, backing away
RILEY_BATH = [20.2, U, -1.6]
def s_card(i, k):
    turn = ease((i - 24) / 30)
    look = lerp([44.0, U + 7.0, 1.95], [13.0, U + 6.0, 1.0], turn)
    # (turning round through the room, not through the wall: the look swings out over the floor)
    look[2] += -7.0 * math.sin(math.pi * turn)
    cam = add(lerp([38.7, U + EYE, 1.9], WIN_EYE, ease((i - 20) / 20)), hand(i, 0.6 + 0.6 * turn))
    lt = 0.8 if 8 <= i <= 10 else (0.6 if 64 <= i <= 66 else (0.3 if i == 68 else 0.0))
    door = 0.05 + 1.35 * ease((i - 44) / 6)
    sh = "window" if i < 24 else "bath"
    fr = dict(DARK, shot=sh, cam={"pos": cam, "look": look, "fov": 58 - 12 * ease((i - 60) / 50)}, exposure=2.2, lightning=0.15 * lt, moon=0.22,
              door=door, glow=0.5, flash=bolt(lt) if i < 24 else {"i": 0})
    if i < 24: fr["bg"] = sky(lt)
    if i < 70:
        av = [player(0, RILEY_BATH, facing(RILEY_BATH, DOORWAY), 0, False, {"neckY": -0.3})]
    else:
        # Riley turns from him to you and backs away
        b = ease((i - 70) / 40)
        p = lerp(RILEY_BATH, [25.6, U, -1.4], b)
        av = [player(0, p, facing(RILEY_BATH, DOORWAY) + math.pi * 0.8 * ease((i - 70) / 12), (i - 70) * 0.35, False, SCARED)]
    fr["av"] = av if i >= 24 else []
    cr = None
    if i >= 44:
        jaw = 0.05 + 0.8 * ease((i - 86) / 24)
        cr = {"pos": DOORWAY, "yaw": facing(DOORWAY, WIN_EYE), "gait": "Stare", "t": stop(i), "neck": [0.0, 0.0, -0.55 * ease((i - 52) / 16)], "jaw": jaw}
    return (fr, cr)
shot("card", 120, s_card)

# 3. he charges across the bathroom at you; the taser (comp: the shot, the sparks): he drops, twitching
ZAP = 24
STUN = [24.0, U, 0.6]
def s_taser(i, k):
    cam = add(WIN_EYE, hand(i, 1.2))
    if ZAP <= i < ZAP + 6:
        j = i - ZAP
        cam = add(cam, [0.06 * math.sin(j * 3.1), 0.08 * math.cos(j * 2.3), 0.05 * math.sin(j * 4.0)])
    if i < ZAP:
        r = i / ZAP
        p = lerp(DOORWAY, STUN, r)
        cr = {"pos": p, "yaw": facing(p, WIN_EYE), "gait": "Chase", "phase": r * 7 * RUN, "t": stop(i), "jaw": 0.95}
    else:
        cr = {"pos": STUN, "yaw": facing(STUN, WIN_EYE), "gait": "Stunned", "t": (i - ZAP) / 30, "jaw": 0.9}
    look = lerp([16.0, U + 5.6, 1.0], [STUN[0], U + 3.4, STUN[2]], ease(i / ZAP))
    # Riley dives out of the way, to the left (the vanity side)
    r = ease(i / 18)
    rp = lerp([25.6, U, -1.4], [29.0, U, -5.0], r)
    av = [player(0, rp, facing([25.6, U, -1.4], [29.0, U, -5.0]), r * 4 * TAU, True)] if i < 22 else [player(0, [29.0, U, -5.0], facing([29.0, U, -5.0], STUN), 0, False, SCARED)]
    lt = 0.0
    return (dict(DARK, shot="bath", cam={"pos": cam, "look": look, "fov": 54}, exposure=2.3, door=1.4, moon=0.2, lightning=lt,
                 glow=1.5 if i < ZAP else (6 if i < ZAP + 4 else 1.5), av=av), cr)
shot("taser", 72, s_taser)

# 4. in the shower, looking back out: him on the floor, twitching, as the curtain is yanked shut
SHOWER_EYE = [37.2, U + 4.9, 5.3]
SHOWER_LOOK = [20.0, U + 4.4, 2.6]
def s_in(i, k):
    cam = lerp([35.6, U + EYE - 0.2, 4.6], SHOWER_EYE, ease(i / 10))
    sh = 0.09 * math.sin(i * 2.3) * (1 - ease(i / 24))
    curtain = 1.4 * (1 - ease((i - 12) / 18))
    look = lerp([22.0, U + 3.6, 1.6], SHOWER_LOOK, ease(i / 20))
    return (dict(DARK, shot="shower", cam={"pos": [cam[0], cam[1] + sh, cam[2] + sh * 0.5], "look": look, "fov": 60, "roll": 0.04 * math.sin(i * 0.9) * (1 - ease(i / 24))},
                 exposure=2.6, door=curtain, glow=2.5, av=[]),
            {"pos": STUN, "yaw": facing(STUN, WIN_EYE), "gait": "Stunned", "t": (i + 48) / 30, "jaw": 0.8})
shot("in", 33, s_in)

def behind(i, extra=None, door=1.4):
    fr = dict(DARK, shot="behind", cam={"pos": [SHOWER_EYE[0], SHOWER_EYE[1] + 0.03 * math.sin(i * 0.31), SHOWER_EYE[2]], "look": SHOWER_LOOK, "fov": 58},
              exposure=2.8, glow=4, door=door)
    if extra: fr.update(extra)
    return fr

# 5. through the curtain: he gets up off the floor; Riley makes a run for the door; he goes after them
RILEY_HIDE = [19.6, U, -2.6]
HALL = [6.5, U, 1.6]
def s_caught(i, k):
    if i < 22:
        cr = {"pos": STUN, "yaw": facing(STUN, WIN_EYE), "gait": "Stunned", "t": (i + 81) / 30, "jaw": 0.6}
    elif i < 40:
        cr = {"pos": STUN, "yaw": facing(STUN, WIN_EYE), "gait": "Stare", "t": stop(i), "neck": [0.2, 0.0, -0.4], "jaw": 0.3}
    else:
        # after Riley, out of the door into the hall
        r = (i - 40) / 26
        p = lerp(STUN, [13.6, U, 1.3], min(1.0, r)) if r <= 1 else lerp([13.6, U, 1.3], HALL, min(1.0, (r - 1) * 2.2))
        turn = ease((i - 40) / 5)
        y0, y1 = facing(STUN, WIN_EYE), facing(STUN, [13.6, U, 1.3])
        d = ((y1 - y0 + math.pi) % TAU) - math.pi
        cr = {"pos": p, "yaw": y0 + d * turn, "gait": "Chase", "phase": r * 8 * RUN, "t": stop(i), "jaw": 0.9}
        if r > 1.5: cr = None
    if i < 34:
        av = [player(0, RILEY_HIDE, facing(RILEY_HIDE, STUN), 0, False, dict(SCARED, waist=0.4, lKnee=-1.2, rKnee=-1.2, lHip=0.9, rHip=0.9))]
        av[0]["pos"][1] -= 1.1
    else:
        r = (i - 34) / 14
        p = lerp(RILEY_HIDE, [12.4, U, 1.4], min(1.0, r)) if r <= 1 else lerp([12.4, U, 1.4], [5.0, U, 2.0], min(1.0, (r - 1) * 1.5))
        av = [player(0, p, facing(RILEY_HIDE, [12.4, U, 1.4]) if r <= 1 else facing([12.4, U, 1.4], [5.0, U, 2.0]), r * 5 * TAU, True)] if r < 1.6 else []
    return (behind(i, {"av": av}), cr)
shot("caught", 90, s_caught)

# 6. the boiler room: Riley zip-tied to a pipe; Jamie runs in ahead of you
def riley_tied(pose=None, look=None):
    p = dict(TIED, **(pose or {}))
    return {"i": 0, "pos": [PIPE_AT[0], B + AV, PIPE_AT[2]], "yaw": RILEY_YAW if look is None else facing(PIPE_AT, look), "pose": p}
def room(i, cam, look, fov, extra=None, av=None):
    fr = dict(DARK, shot="boiler", cam={"pos": cam, "look": look, "fov": fov}, exposure=2.6, door=OPEN, av=av)
    if extra: fr.update(extra)
    return fr
def s_boiler(i, k):
    cam = add(lerp([-21.6, B + 5.6, 21.4], [-28.4, B + 5.3, 20.2], ease(k)), hand(i, 0.9))
    r = ease(i / 50)
    jp = lerp([-30.6, B, 23.2], [-34.8, B, 22.6], r)
    av = [riley_tied({"neckY": 0.35 * math.sin(i * 0.12)}), player(1, jp, facing(jp, PIPE_AT), r * 6 * TAU, r < 0.98)]
    return (room(i, cam, lerp([-34.0, B + 3.6, 17.5], [-37.0, B + 4.0, 19.0], ease(k)), 58, av=av), None)
shot("boiler", 60, s_boiler)

# 7. "Cut free": kneeling in front of Riley; the prompt filling; Riley looking up at you
CUT_EYE = [-31.6, B + 4.9, 18.6]
JAMIE_WATCH = [-34.0, B, 22.6]
def s_cut(i, k):
    cam = add(CUT_EYE, hand(i, 0.5))
    look = [PIPE_AT[0], B + 5.9, PIPE_AT[2] + 0.1]
    av = [riley_tied({"neckX": 0.25, "neckY": 0.1 * math.sin(i * 0.2)}, CUT_EYE),
          player(1, JAMIE_WATCH, facing(JAMIE_WATCH, [-20.0, B, 20.0]), 0, False, {"neckY": 0.25 * math.sin(i * 0.07)})]
    return (room(i, cam, look, 54, {"exposure": 2.8}, av), None)
shot("cut", 60, s_cut)

# 8. Riley's free: up on their feet... and staring past you at something behind you
def s_free(i, k):
    cam = add(lerp(CUT_EYE, [-31.2, B + 5.2, 18.6], ease(i / 14)), hand(i, 0.5))
    look = lerp([PIPE_AT[0], B + 5.9, PIPE_AT[2] + 0.1], [PIPE_AT[0] + 0.8, B + 6.1, PIPE_AT[2]], ease(i / 14))
    up = ease(i / 10)
    stand = {"lShoulder": [-0.55 * (1 - up), 0, 0.2], "rShoulder": [-0.55 * (1 - up), 0, -0.2], "lElbow": -0.4 * (1 - up), "rElbow": -0.4 * (1 - up)}
    rp = lerp(PIPE_AT, [-36.0, B, 19.0], ease((i - 6) / 14))
    stare = ease((i - 24) / 10)
    if i < 24:
        pose = dict(stand, neckX=0.1)
    else:
        pose = dict(SCARED, neckX=0.15 * stare, lShoulder=[0.5 * stare, 0, -0.35 * stare], rShoulder=[0.5 * stare, 0, 0.35 * stare])
    behind_you = [-24.6, B + 3.0, 14.4]   # (the boiler, over your shoulder)
    av = [{"i": 0, "pos": [rp[0], B + AV, rp[2]], "yaw": facing(rp, cam) + 0.35 * stare * (facing(rp, behind_you) - facing(rp, cam)), "pose": pose},
          player(1, JAMIE_WATCH, facing(JAMIE_WATCH, [-20.0, B, 20.0]) + 0.9 * ease((i - 30) / 10), 0, False, SCARED if i > 34 else None)]
    return (room(i, cam, look, 54, {"exposure": 2.8}, av), None)
shot("free", 60, s_free)

# 9. you turn round: the dark by the boiler... nothing... and he's in your face (22.15 s: frame 64 here)
TURN_EYE = [-31.2, B + 5.2, 18.6]
GAP = [-20.6, B + 5.0, 20.2]        # the open doorway
def s_turn(i, k):
    # (Riley and Jamie behind you now: out of the shot)
    if i < 64:
        t = ease(i / 34)
        look = lerp([PIPE_AT[0] + 0.8, B + 6.1, PIPE_AT[2]], GAP, t)
        look[2] += -4.0 * math.sin(math.pi * t)     # (round through the room, not the wall)
        cam = add(lerp(TURN_EYE, [-30.8, B + 5.2, 18.0], ease((i - 34) / 30)), hand(i, 0.4))
        return (room(i, cam, look, 56, {"exposure": 2.7, "glow": 0}, []), None)
    j = i - 64
    cam = [-31.4, B + 5.2, 18.0]
    p = lerp([-25.4, B, 19.0], [-26.2, B, 18.9], ease(j / 4.0))
    return (dict(DARK, shot="boiler", cam={"pos": cam, "look": [p[0], B + 7.8, p[2]], "fov": 64}, exposure=3.0, glow=13, door=OPEN, av=[]),
            {"pos": p, "yaw": facing(p, cam), "gait": "Reach", "t": i / 30, "duck": 0.9, "jaw": 1.0, "neck": [0.0, 0.0, 0.1 * math.sin(i * 0.9)]})
shot("turn", 75, s_turn)

# 10. RUN: out the door into the basement, looking back: Riley right behind you, him after you both
def s_run(i, k):
    cam = [-21.5 + 6.0 * k + 0.2 * math.sin(i * 1.7), B + 4.8 + 0.2 * math.sin(i * 2.3), 19.8 + 0.6 * k]
    p = lerp([-30.5, B, 17.2], [-25.0, B, 19.2], k)
    return (dict(DARK, shot="out", cam={"pos": cam, "look": [p[0], B + 4.4, p[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash={"i": 16.0, "pos": [cam[0] - 0.5, cam[1] - 0.5, cam[2]], "target": [p[0], B + 4.0, p[2]], "angle": 0.4},
                 exposure=1.7, glow=8, door=OPEN, av=[]),
            {"pos": p, "yaw": facing(p, cam), "gait": "Chase", "phase": k * 15 * RUN, "t": stop(i), "jaw": 0.9})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": AVS, "extras": [],
           "props": {"cache": f"{S}/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
