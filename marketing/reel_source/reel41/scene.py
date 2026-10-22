# Reel 41 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 6)", the gameplay series in reel 38's style
# (real Roblox avatars, little text, scares). The garage, and the TASER (the 39 R$ pass: 3 shots a night,
# a hit stuns him): Riley and Jamie at the locked side door, the door from the house creaks open behind
# you, he charges, the taser drops him; he gets up and goes over the car (his pounce), lands on Riley;
# you hide in the storage cabinet: the heartbeat minigame as he comes back... the doors torn open.
# On #2's track, every clip at #2's length.
#   hook (105)  the dark garage, the flashlight on Riley and Jamie at the side door (it won't open)
#   card (120)  Jamie's face; you turn round: the door from the house swings open, him in the doorway; he drops
#               to all fours and comes (jolt)
#   72          the taser up, he's on you... ZAP: he goes down, twitching
#   33          stunned on the floor, his head turns right round to you
#   90          run down the side of the car with Riley; he's up, along the far side... over the car (jolt: on Riley)
#   60          Riley lifted off the floor, kicking; he carries them off to the house
#   60          into the storage cabinet, the door pulled to: a crack of the garage
#   60          he comes back. Stops. His head turns to the cabinet (the heartbeat starts)
#   75          he leans down to the crack... nothing... the doors torn open on 22.15 s
#   30          RUN: out the side door, him round the car after you
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
EYE_Y = G + EYE

# --- the garage (World/Interior): x 40..66, z -30..6, ceiling 15; the sedan at (53, -17), nose to +z (body x 49.7..56.3,
# z -24.6..-9.4, roof 5.8); the door from the house in the x = 40 wall at z -3 (hinge z -5.45); the side door out in
# the x = 66 wall at z -2; the storage cabinet on the x = 40 wall (x 40.9..44, z -21.4..-16.1), its doors face +x, the
# left leaf hinged at z -16.1 (the gap at z -18.74); the workbench on the x = 66 wall at z -21.5
ENTRY = {"near": [40.0, 5.7, -3.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [40.0, 0, -5.45], "axis": "y"}
SIDE = {"near": [66.0, 5.7, -2.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [66.0, 0, -4.45], "axis": "y"}
CAB = {"near": [43.7, 5.5, -17.4], "r": 2.0, "names": ["WardrobeLeaf", "DoorPanel", "PanelInset"], "hinge": [43.82, 0, -16.1], "axis": "y"}
BULB = [{"p": [53.0, 13.4, -12.0], "col": "#ffcf95", "b": 1.0, "r": 26, "decay": 1.1},     # the bare bulb, dim
        {"p": [37.0, 7.0, -3.0], "col": "#ffd8a8", "b": 1.6, "r": 16},                     # the hall, through the door from the house
        {"p": [53.0, 9.0, -32.0], "col": "#6f86c4", "b": 0.5, "r": 20},                    # night through the garage door's windows
        {"p": [55.0, 6.0, -28.6], "col": "#ffcf95", "b": 0.5, "r": 9},
        {"p": [70.0, 8.0, -2.0], "col": "#6f86c4", "b": 1.0, "r": 16}]                     # the night at the side door's glass
SHOTS = {
    "garage": {"center": [53, 6, -12], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": BULB, "door": ENTRY},
    "side": {"center": [58, 6, -10], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": BULB, "door": SIDE},
    "cab": {"center": [48, 6, -14], "radius": 32, "lampRadius": 0, "maxLamps": 0, "lights": BULB + [{"p": [47.0, 11.0, -17.5], "col": "#ffcf95", "b": 2.4, "r": 13}, {"p": [52.0, 12.0, -6.0], "col": "#ffcf95", "b": 0.8, "r": 16},
                              {"p": [53.0, 11.0, -19.0], "col": "#ffcf95", "b": 2.0, "r": 18}, {"p": [61.0, 9.0, -19.0], "col": "#ffcf95", "b": 1.3, "r": 12}],
            "door": CAB, "hide": ["Handle"]},
}
DARK = {"ambient": 0.03, "bg": 0x020203}

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

def gar(cam, look, fov=64, extra=None, shot_name="garage"):
    fr = dict(DARK, shot=shot_name, cam={"pos": cam, "look": look, "fov": fov}, exposure=2.4, door=0.0, glow=2.0, av=[])
    if extra: fr.update(extra)
    return fr
def torch(cam, tgt, i=12.0, angle=0.4):
    return {"i": i, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}
def yaw_look(cam, yaw, dy=-0.6, d=10.0):
    return [cam[0] - math.sin(yaw) * d, cam[1] + dy, cam[2] - math.cos(yaw) * d]

# 1. (hook) the dark garage; the flashlight finds Riley and Jamie at the side door: Riley tries it, it won't go
RD = [64.4, G, -2.3]         # Riley at the side door
JD = [61.6, G, 0.6]          # Jamie beside, watching you come
EAST = facing([0, 0, 0], [1, 0, 0])
def rattle(i):
    s = 0.12 * math.sin(i * 1.9)
    return {"rShoulder": [1.45 + s, 0, 0.15], "rElbow": 0.35, "lShoulder": [0.3, 0, -0.1], "lElbow": 0.3, "neckX": -0.05, "waist": 0.05 * math.sin(i * 1.9)}
def friends_door(i, rface=SMILE, jface=SMILE, rturn=0.0, jlook=None):
    ry = EAST + (math.pi - 0.2) * rturn
    rp = rattle(i) if rturn < 0.3 else (AFRAID if rface == SCARED else None)
    jy = jlook if jlook is not None else facing(JD, [52.0, G, -2.6])
    return [player(0, RD, ry, 0, False, rp, face=rface), player(1, JD, jy, 0, False, AFRAID if jface == SCARED else None, face=jface)]
C0, C1 = [46.5, EYE_Y, -1.6], [52.0, EYE_Y, -2.6]
def s_hook(i, k):
    w = ease(k)
    cam = add(lerp(C0, C1, w), add(hand(i), [0, 0.06 * math.sin(i * 0.42), 0]))
    look = lerp([62.0, G + 4.6, -1.2], [63.5, G + 4.4, -1.2], w)
    return (gar(cam, look, 60, {"av": friends_door(i), "flash": torch(cam, [63.0, G + 3.8, -1.2], 12.0, 0.42)}, "side"), None)
shot("hook", 105, s_hook)

# 2. (card) Jamie's face changes; you turn round: the door from the house swings open, him in the doorway, lit from
# the hall... he drops to all fours and comes (the jolt at 96)
DOORWAY = [41.4, G, -3.1]
TURN0, TURN1 = 30, 54
CHARGE = 92
def s_card(i, k):
    cam = add(C1, hand(i, 0.6))
    y0 = facing(C1, [64.0, G, -3.2])
    y1 = facing(C1, DOORWAY)
    t = ease((i - TURN0) / (TURN1 - TURN0))
    yaw = y0 + wrap(y1 - y0) * t
    look = yaw_look(cam, yaw, -0.9 + 0.3 * t, 10.0)
    jscared = i >= 16
    av = friends_door(i, SCARED if i >= 26 else SMILE, SCARED if jscared else SMILE, ease((i - 20) / 10), facing(JD, [44.0, G, -3.0]) if jscared else None)
    door = -1.25 * ease((i - 44) / 16)
    fr = gar(cam, look, 60 - 8 * t, {"av": av, "door": door, "glow": 3.0, "flash": torch(cam, look, 12.0, 0.4)})
    if i < 44:
        return (fr, None)
    if i < CHARGE:
        cr = {"pos": DOORWAY, "yaw": facing(DOORWAY, C1), "gait": "Stare", "t": stop(i), "neck": [0.1, 0.0, -0.55 * ease((i - 62) / 10)],
              "jaw": 0.2 + 0.7 * ease((i - 70) / 14)}
        return (fr, cr)
    j = i - CHARGE
    p = lerp(DOORWAY, [44.6, G, -3.2], ease(j / 28))
    fr["cam"]["pos"] = add(fr["cam"]["pos"], run_shake(i, 0.3 * max(0.0, 1 - j / 10)))
    return (fr, {"pos": p, "yaw": facing(p, C1), "gait": "Chase", "phase": j / 30 * 4 * RUN, "t": stop(i), "jaw": 1.0})
shot("card", 120, s_card)

# 3. the taser up (bottom right), he's coming... ZAP (frame 24): he goes down, twitching
ZAP = 24
HIT = [47.4, G, -3.0]
BACK = [57.0, EYE_Y, -2.4]
def s_taser(i, k):
    cam = add(lerp(C1, BACK, ease(i / 30)), hand(i, 0.8))
    if i < ZAP:
        p = lerp([44.6, G, -3.2], HIT, i / ZAP)
        cr = {"pos": p, "yaw": facing(p, cam), "gait": "Chase", "phase": (28 + i) / 30 * 4 * RUN, "t": stop(i), "jaw": 1.0}
    else:
        j = i - ZAP
        p = lerp(HIT, [48.0, G, -3.0], ease(j / 8))
        cr = {"pos": p, "yaw": facing(HIT, C1) + 0.15 * math.sin(i * 2.7), "gait": "Stunned", "t": stop(i, 18), "jaw": 0.8 + 0.2 * math.sin(i * 3.1),
              "neck": [0.2 * math.sin(i * 2.3), 0.3 * math.sin(i * 1.7), 0.4 * math.sin(i * 2.9)]}
    look = [p[0], G + (4.6 if i < ZAP else 3.4), p[2]]
    fr = gar(cam, look, 64, {"glow": 3.5, "flash": torch(cam, look, 12.0, 0.4)})
    if ZAP <= i < ZAP + 6:
        fr["burst"] = {"pos": [p[0] + 0.5, G + 4.0, p[2]], "col": "#9fd4ff", "i": 9.0 * (1 - (i - ZAP) / 6), "r": 18}
        fr["cam"]["pos"] = add(fr["cam"]["pos"], run_shake(i, 0.35))
    return (fr, cr)
shot("taser", 72, s_taser)

# 4. stunned on the floor... his head turns right round to look at you
def s_stun(i, k):
    cam = add(BACK, hand(i, 0.5))
    p = [48.0, G, -3.0]
    turn = ease(i / 26)
    cr = {"pos": p, "yaw": facing(HIT, C1) + 0.1 * math.sin(i * 2.7), "gait": "Stunned", "t": stop(i, 18), "jaw": 0.9,
          "neck": [0.15 * math.sin(i * 2.3), math.pi * 0.9 * math.floor(turn * 6) / 6, 0.2 * math.sin(i * 2.9)]}
    look = [p[0], G + 3.4, p[2]]
    return (gar(cam, look, 50, {"glow": 4.0, "flash": torch(cam, look, 12.0, 0.36)}), cr)
shot("stun", 33, s_stun)

# 5. run down the car's east side with Riley; he's up, down the far side... and over the car, onto Riley (the jolt at 66)
LEAP0, LAND = 50, 66
L0, L1 = [46.8, G, -15.6], [58.0, G, -15.8]
def s_chase(i, k):
    w = ease(i / 44)
    cam = lerp([59.0, EYE_Y, -2.8], [60.3, EYE_Y, -29.2], w)   # (Riley runs along the car, you a lane further out)
    cam = add(cam, run_shake(i, 0.6 * (1 - ease((i - 40) / 10))))
    # look ahead down the side of the car, then back over your shoulder at the car
    back = ease((i - 22) / 16)
    ahead = [60.0, G + 4.0, -40.0]
    look = lerp(ahead, [56.4, G + 4.6, -15.4], back)
    rp = lerp([57.2, G, -1.0], [57.8, G, -15.8], ease(i / 52))   # (behind you: the slower one)
    run = i < 52
    av = [player(0, rp, facing([57.2, G, -1.0], [57.8, G, -15.8]) if run else facing(rp, L0), i / 30 * 7 * TAU, run, None if run else AFRAID, face=SCARED)]
    if i < LEAP0:
        w2 = ease(clamp((i - 10) / 40))
        p = lerp([48.0, G, -3.0], L0, w2)
        cr = {"pos": p, "yaw": facing(p, L0) if w2 < 0.95 else facing(L0, L1), "gait": "Stunned" if i < 10 else "Chase", "phase": i / 30 * 5 * RUN, "t": stop(i), "jaw": 1.0}
    elif i < LAND:
        t = (i - LEAP0) / (LAND - LEAP0)
        t = math.floor(t * 8) / 8                      # (stop-motion)
        p = lerp(L0, L1, t)
        p[1] = G + 6.8 * math.sin(math.pi * t)
        cr = {"pos": p, "yaw": facing(L0, L1), "gait": "Chase", "phase": 1.2, "t": stop(i), "pitch": 0.5 - 1.0 * t, "jaw": 1.0}
    else:
        p = L1
        cr = {"pos": p, "yaw": facing(L1, rp), "gait": "Reach", "t": (i - LAND) / 30, "jaw": 1.0, "duck": 0.6}
        av = [{"i": 0, "pos": [rp[0] + 0.3, G + 1.2, rp[2] - 0.6], "yaw": facing(rp, L0), "pose": FLAIL, "pitch": -1.3, "face": SCARED}]
    fr = gar(cam, look, 72, {"av": av, "glow": 3.0, "flash": torch(cam, look, 14.0, 0.42)})
    if LAND <= i < LAND + 6:
        fr["cam"]["pos"] = add(fr["cam"]["pos"], run_shake(i, 0.4))
    return (fr, cr)
shot("chase", 90, s_chase)

# 6. Riley lifted off the floor, kicking; he turns and carries them off towards the house
def s_carry(i, k):
    cam = add(lerp([60.3, EYE_Y, -29.2], [59.6, EYE_Y - 0.6, -29.4], ease(i / 40)), hand(i, 1.0))
    if i < 28:
        p, yaw = L1, facing(L1, [58.4, G, -17.0]) + wrap(facing(L1, [52.0, G, -4.0]) - facing(L1, [58.4, G, -17.0])) * ease((i - 14) / 14)
        cr = {"pos": p, "yaw": yaw, "gait": "Reach", "t": 0.8 + i / 30, "jaw": 1.0}
    else:
        w = ease((i - 28) / 32)
        p = lerp(L1, [55.0, G, -8.0], w)
        yaw = facing(L1, [52.0, G, -4.0])
        cr = {"pos": p, "yaw": yaw, "gait": "Walk", "phase": w * 4 * WALK, "t": stop(i), "jaw": 0.8}
    lift = ease(i / 12)
    fwd_ = [-math.sin(yaw), -math.cos(yaw)]
    rp = [p[0] + fwd_[0] * 1.6, G + AV + 3.0 * lift, p[2] + fwd_[1] * 1.6]
    kick = dict(FLAIL) if (i // 2) % 2 else dict(FLAIL, lHip=-0.3, rHip=0.6, lKnee=-0.2, rKnee=-1.0)
    av = [{"i": 0, "pos": rp, "yaw": yaw + math.pi, "pose": kick, "pitch": 0.15, "face": SCARED}]
    look = [p[0], G + 6.0, p[2]]
    return (gar(cam, look, 62, {"av": av, "glow": 2.5, "flash": torch(cam, look, 14.0, 0.42)}), cr)
shot("carry", 60, s_carry)

# 7. into the storage cabinet, the door pulled to: a crack of the garage
EYE_IN = [42.9, G + 5.0, -18.7]
LOOK_IN = [51.0, G + 6.0, -18.2]
CRACK = 0.36
def cab(i, extra=None, door=CRACK):
    fr = dict(DARK, shot="cab", cam={"pos": [EYE_IN[0], EYE_IN[1] + 0.03 * math.sin(i * 0.31), EYE_IN[2]], "look": LOOK_IN, "fov": 62},
              exposure=2.4, glow=1.0, door=door, av=[])
    if extra: fr.update(extra)
    return fr
def s_hide(i, k):
    # backing into the cabinet, facing out; the door pulled to in front of you
    w = ease(i / 26)
    cam = add(lerp([46.8, EYE_Y - 0.4, -17.6], EYE_IN, w), hand(i, 1.4 * (1 - w)))   # (in through the open side)
    look = lerp([53.0, G + 3.6, -14.0], LOOK_IN, w)
    t = ease((i - 22) / 18)
    fr = dict(DARK, shot="cab", cam={"pos": cam, "look": look, "fov": 62 + 4 * (1 - w)}, exposure=2.4, glow=1.0, door=1.5 + (CRACK - 1.5) * t, av=[])
    if i < 26:
        fr["flash"] = torch(cam, look, 9.0 * (1 - i / 26), 0.5)
    return (fr, None)
shot("hide", 60, s_hide)

# 8. he comes back down the aisle between the car and the cabinet... stops right in front of it, turns to it
# (the heartbeat starts)
BACK0, STOP = [47.6, G, -8.0], [48.4, G, -18.5]
def s_back(i, k):
    if i < 36:
        w = ease(i / 36)
        p = lerp(BACK0, STOP, w)
        cr = {"pos": p, "yaw": facing(BACK0, STOP), "gait": "Walk", "phase": w * 4 * WALK, "t": stop(i), "jaw": 0.3}
    else:
        p = STOP
        y0, y1 = facing(BACK0, STOP), facing(STOP, EYE_IN)
        cr = {"pos": p, "yaw": y0 + wrap(y1 - y0) * ease((i - 38) / 12), "gait": "Stare", "t": stop(i), "neck": [0.2, 0.0, -0.45 * ease((i - 44) / 10)], "jaw": 0.35}
    return (cab(i, {"glow": 2.0}), cr)
shot("back", 60, s_back)

# 9. he folds down to the crack (his mask fills it)... leans closer... rises and goes... nothing... the doors torn
# open (22.15 s: frame 64)
PEEK = [48.0, G, -18.7]
CLOSE = [47.5, G, -18.7]
SCARE = [47.6, G, -18.7]
DUCK = 3.4
def s_tear(i, k):
    if i < 64:
        if i < 22:
            w = math.floor(ease(i / 20) * 8) / 8                   # (stop-motion: folding down in jerks)
            p = lerp(STOP, PEEK, w)
            return (cab(i, {"glow": 2.0 + 1.0 * w}), {"pos": p, "yaw": facing(p, EYE_IN), "gait": "Stare", "t": stop(i), "duck": DUCK * w,
                                                      "neck": [0.9 * w, 0.0, -0.45 + 0.05 * w], "jaw": 0.3 + 0.3 * w})
        if i < 42:
            c = math.floor(ease((i - 30) / 10) * 4) / 4
            p = lerp(PEEK, CLOSE, c)
            return (cab(i, {"glow": 3.0}), {"pos": p, "yaw": facing(p, EYE_IN), "gait": "Stare", "t": stop(i), "duck": DUCK,
                                            "neck": [0.9, 0.12 * math.sin(i * 0.4), -0.4 + 0.15 * math.sin(i * 0.23)], "jaw": 0.6 + 0.3 * c})
        if i < 56:
            w = math.floor(ease((i - 42) / 12) * 7) / 7
            p = lerp(CLOSE, [48.6, G, -11.0], w)
            return (cab(i, {"glow": 2.0}), {"pos": p, "yaw": facing(p, EYE_IN) if w < 0.3 else facing(CLOSE, [48.6, G, -11.0]), "gait": "Stare" if w < 0.3 else "Walk",
                                            "phase": w * 4, "t": stop(i), "duck": DUCK * max(0.0, 1 - w * 2.5), "neck": [0.9 * max(0.0, 1 - w * 2.5), 0.0, -0.3], "jaw": 0.6 * (1 - w)})
        return (cab(i), None)
    d = ease((i - 64) / 2.0)
    fr = cab(i, {"glow": 10, "exposure": 2.6, "flash": {"i": 10.0, "pos": [EYE_IN[0] + 0.3, EYE_IN[1] - 0.6, EYE_IN[2]], "target": [45.5, G + 5.4, -18.6], "angle": 0.5}},
             door=CRACK + (2.1 - CRACK) * d)
    fr["cam"]["look"] = [51.0, G + 7.0, -17.0]
    fr["cam"]["fov"] = 68
    return (fr, {"pos": SCARE, "yaw": facing(SCARE, EYE_IN), "gait": "Stare", "t": stop(i), "duck": DUCK,
                 "neck": [0.9, 0.0, -0.4 + 0.35 * math.sin(i * 1.3)], "jaw": 1.0})
shot("tear", 75, s_tear)

# 10. RUN: out the side door, looking back: he comes round the car after you
def s_run(i, k):
    cam = [59.0 + 6.5 * k + 0.2 * math.sin(i * 1.7), G + 4.8 + 0.2 * math.sin(i * 2.3), -8.0 + 5.0 * k]
    p = lerp([47.0, G, -20.0], [50.0, G, -8.0], k)
    return (dict(DARK, shot="side", cam={"pos": cam, "look": [p[0], G + 4.4, p[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash={"i": 16.0, "pos": [cam[0] - 0.5, cam[1] - 0.5, cam[2]], "target": [p[0], G + 4.0, p[2]], "angle": 0.4},
                 exposure=1.8, glow=8, door=1.3, av=[]),
            {"pos": p, "yaw": facing(p, cam), "gait": "Chase", "phase": k * 15 * RUN, "t": stop(i), "jaw": 0.9})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": AVS, "extras": [],
           "props": {"cache": f"{S}/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
