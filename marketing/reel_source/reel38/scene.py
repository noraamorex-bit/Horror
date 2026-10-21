# Reel 38 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 3)", the gameplay series. The owner on
# Part 2: "too much text… reduce text, increase gameplay and scares. Try using actual Roblox characters
# instead of your blocky thing." So: real Roblox avatars dressed in Roblox's own catalog items (film2
# avatar_rbx.js: Riley in Pal Hair, the Blue and Black Motorcycle Shirt and Black Jeans; Jamie in the
# Orange Beanie with Black Hair, the Denim Jacket with White Hoodie and Black Jeans with White Shoes;
# classic faces), four scares instead of one, and no HUD text (edit.py). On #2's track, #2's lengths.
#   hook (105)  the dark kitchen, your flashlight on Riley and Jamie walking ahead to the island
#   card (120)  his head rises over the far side of the island; he climbs onto it... and pounces (jolt)
#   72          the front hall, running, looking back: Jamie, Riley, him on all fours; he grabs Riley (jolt)
#   33          up the stairs after Jamie
#   90          the master bedroom: under the bed, Jamie squeezed in beside you; the door swings open
#   60          his legs cross the room to the foot of the bed and stop
#   60          his hand comes in... and drags Jamie out (jolt)
#   60          gone. The empty foot of the bed. You crawl out
#   75          up, the dark room, the door... turn round: he's on you (the scare at 22.15 s)
#   30          RUN: out of the bedroom, him after you
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

COLD, MOON = "#3d4f7a", "#6f86c4"
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.5, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}
DARK = {"ambient": 0.03, "bg": 0x010102}

# --- the kitchen: the island x -28..-22, z 12.5..17.4 (top G + 3.8), stools on its south side (z 18.6);
# the arch to the front hall in the x = -8 wall at z = 26; the arch to the living room at x = -24, z = 2
ISLAND_TOP = G + 3.8
KITCHEN = [{"p": [-38, 9, 14], "col": COLD, "b": 1.6, "r": 18}, {"p": [-24, 9, 29], "col": COLD, "b": 1.1, "r": 14},
           {"p": [-25, 9, 6], "col": MOON, "b": 1.8, "r": 16, "decay": 1.1}, {"p": [-14, 8, 22], "col": "#5d72a8", "b": 0.8, "r": 12}]
# --- the front hall (x -8..6) and the stairs (x about -5: the bottom at z -5.3, the top at z 17 upstairs)
HALL = [{"p": [-1, G + 9, 26], "col": "#5d72a8", "b": 2.2, "r": 22}, {"p": [0, G + 9, 6], "col": COLD, "b": 1.6, "r": 18},
        {"p": [-5, 8, -2], "col": COLD, "b": 1.4, "r": 18}, {"p": [-5, U + 6, 22], "col": "#2c3d6e", "b": 1.3, "r": 26}]
# --- the master bedroom (x -40..-8, z -30..0): the bed's head on the west wall, foot at x -30.15, z
# -18.25..-10.75, skirts on three sides (you see out of the foot end only), the door in the x = -8 wall
# (hinged at z -12.42, swinging into the room)
BED_NAMES = ["BedFrame", "RailLip", "BedPost", "PostCap", "Finial", "Headboard", "HeadboardPanel", "HeadRail",
             "Footboard", "FootRail", "Mattress", "Duvet", "DuvetDrape", "DuvetFoot", "Turndown", "Pillow",
             "AccentPillow", "Throw", "ThrowDrape", "ThrowFold", "ThrowStripe", "Fringe", "BedSkirt"]
DOOR_RIG = {"near": [-8.0, U + 4.7, -10.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, -12.42], "axis": "y"}
ROOM = [{"p": [-24, U + 9, -33], "col": MOON, "b": 3.4, "r": 36, "decay": 1.0}, {"p": [-14, U + 6, -20], "col": COLD, "b": 1.8, "r": 20},
        {"p": [-4.5, U + 7, -10], "col": "#5d72a8", "b": 3.0, "r": 18},
        {"p": [-22, U + 3.5, -13.5], "col": MOON, "b": 1.6, "r": 12}]          # (the moonlit floor in front of the bed)
UNDER = [-32.2, U + 0.8, -15.2]          # your eye under the bed, two studs in from the foot
UNDER_LOOK = [-8.0, U + 2.0, -13.6]      # (out of the foot end, at the door)
SHOTS = {
    "kitchen": {"center": [-20, 6, 18], "radius": 36, "lampRadius": 0, "maxLamps": 0, "lights": KITCHEN},
    "hall": {"center": [-2, 6, 10], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": HALL},
    "room": {"center": [-24, U + 4, -15], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": DOOR_RIG, "lights": ROOM},
    "under": {"center": [-24, U + 3, -14], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": DOOR_RIG,
              "lights": ROOM + [{"p": [-31.0, U + 1.1, -13.8], "col": "#8ea2d8", "b": 1.0, "r": 7}]},
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

# 1. (hook) in through the arch from the front hall: your flashlight on Riley and Jamie's backs as they
# walk ahead to the island
# (round the south end of the dining table, x -17..-9, z 12..23.5, to the stools' side of the island)
CAM0, CAM1 = [-9.0, G + EYE, 26.2], [-12.6, G + EYE, 26.0]
R0, R1 = [-19.4, G, 23.2], [-22.6, G, 20.6]      # Riley, on the right
J0, J1 = [-24.0, G, 25.8], [-27.6, G, 22.6]      # Jamie, on the left
def kids_walk(w, ph, look=(0, 0), face=SMILE):
    pr, pj = lerp(R0, R1, w), lerp(J0, J1, w)
    return [player(0, pr, facing(R0, R1), ph, False, gait(ph, False, look), face=face),
            player(1, pj, facing(J0, J1), ph + 2.2, False, gait(ph + 2.2, False, (-look[0], look[1])), face=face)]
def s_hook(i, k):
    w = ease(k)
    cam = add(lerp(CAM0, CAM1, 0.8 * w), hand(i))
    tgt = lerp([-17.0, G + 3.0, 25.0], [-24.0, G + 3.4, 19.0], ease(k))
    return (dict(DARK, shot="kitchen", cam={"pos": cam, "look": lerp([-22.0, G + 4.0, 23.0], [-25.0, G + 4.4, 16.0], ease(k)), "fov": 72},
                 flash=fl(cam, tgt), exposure=2.1, av=kids_walk(w, w * 7 * TAU / 3)), None)
shot("hook", 105, s_hook)

# 2. (card) they stop at the island. On its far side his head rises out of the dark... he climbs up onto
# it on all fours, and pounces at them (frame 84: the jolt); they bolt back past you
BEHIND = [-25.0, G, 8.0]                 # crouched behind the island's north side (z 11)
ON_TOP = [-25.0, ISLAND_TOP, 14.2]
LAND = [-21.0, G, 21.6]
def s_card(i, k):
    cam = add(lerp(CAM0, CAM1, 0.8 + 0.2 * ease(i / 30)), hand(i, 0.7 + (1.5 if 84 <= i < 96 else 0)))
    if 84 <= i < 92:
        cam = add(cam, run_shake(i, 0.6))
    tgt = lerp([-24.0, G + 3.4, 19.0], [-25.0, G + 4.2, 12.0], ease((i - 20) / 24))
    if 50 <= i < 84:
        tgt = lerp([-25.0, G + 4.2, 12.0], [-25.0, G + 5.5, 14.2], ease((i - 50) / 14))
    look = lerp([-25.0, G + 4.4, 16.0], [-25.0, G + 5.0, 14.0], ease((i - 26) / 30))
    if i >= 84:
        look = lerp(look, [-20.5, G + 4.6, 21.0], ease((i - 84) / 10))
    # the kids: at the island, then frozen, then running back past you (one each side)
    if i < 30:
        av = kids_walk(1.0, 7 * TAU / 3)
    elif i < 84:
        tu = ease((i - 30) / 14)
        av = [player(0, R1, facing(R1, ON_TOP), 0, False, dict(AFRAID, neckX=-0.25 * tu), face=SCARED if i > 52 else UHOH),
              player(1, J1, facing(J1, ON_TOP), 0, False, dict(AFRAID, neckX=-0.3 * tu), face=SCARED if i > 50 else SMILE)]
    else:
        r = (i - 84) / 22
        er, ej = [cam[0] - 1.0, G, cam[2] - 4.8], [cam[0] - 0.5, G, cam[2] + 4.6]
        pr, pj = lerp(R1, er, min(1.0, r)), lerp(J1, ej, min(1.0, r * 1.15))
        av = [player(0, pr, facing(R1, er), r * 7 * TAU, True, face=SCARED), player(1, pj, facing(J1, ej), r * 7 * TAU + 1.5, True, face=SCARED)]
        av = [a for a, pp in zip(av, [pr, pj]) if math.hypot(pp[0] - cam[0], pp[2] - cam[2]) > 1.8]
    # him: rising behind the island (frames 26-50), climbing onto it (50-70), crouched there (70-84), the pounce
    if i < 26:
        cr = None
    elif i < 50:
        rise = ease((i - 26) / 24)
        p = [BEHIND[0], BEHIND[1] - 4.6 + 4.6 * rise, BEHIND[2]]
        cr = {"pos": p, "yaw": facing(BEHIND, cam), "gait": "Stare", "t": stop(i), "neck": [0.2, 0.0, -0.5], "jaw": 0.05 + 0.3 * rise}
    elif i < 70:
        c = ease((i - 50) / 20)
        p = lerp(BEHIND, ON_TOP, c)
        p[1] = BEHIND[1] + (ISLAND_TOP - BEHIND[1]) * ease((i - 50) / 12)
        cr = {"pos": p, "yaw": facing(BEHIND, ON_TOP), "gait": "Chase", "phase": c * 3 * RUN, "t": stop(i), "jaw": 0.5}
    elif i < 84:
        cr = {"pos": ON_TOP, "yaw": facing(ON_TOP, R1), "gait": "Chase", "phase": 0.6, "t": stop(i), "jaw": 0.6 + 0.4 * ease((i - 76) / 6),
              "neck": [0.0, 0.0, 0.08 * math.sin(i * 0.8)]}
    else:
        c = clamp((i - 84) / 10)
        p = lerp(ON_TOP, LAND, c)
        p[1] += 3.2 * math.sin(math.pi * c) - (ISLAND_TOP - G) * c
        if i >= 94:
            c2 = ease((i - 94) / 26)
            p = lerp(LAND, [cam[0] - 1.0, G, cam[2] - 5.5], c2 * 0.7)
        cr = {"pos": p, "yaw": facing(ON_TOP, LAND), "gait": "Chase", "phase": (i - 84) / 30 * 5 * RUN, "t": stop(i), "jaw": 1.0,
              "pitch": -0.35 * math.sin(math.pi * c) if i < 94 else 0.0}
    return (dict(DARK, shot="kitchen", cam={"pos": cam, "look": look, "fov": 70}, flash=fl(cam, tgt, 14.0, 0.28), exposure=2.1, glow=(0.25 if 50 <= i < 92 else 1.2) if i < 92 else 4, av=av), cr)
shot("card", 120, s_card)

# 3. the front hall, running north to the stairs, looking back: Jamie right behind you, Riley behind
# them, him out of the kitchen arch on all fours; he catches Riley and lifts them off the floor (jolt)
def s_hall(i, k):
    zc = 12.0 - 10.0 * k
    cam = add([2.4, G + 5.2, zc], run_shake(i))
    look = [1.8, G + 3.6, zc + 14.0]
    zj, zr = zc + 9.0, zc + 14.0
    grab = 46
    # him: out of the kitchen arch (x -8, z 26) and after them up the hall
    if i < grab:
        a = ease(i / grab)
        hp = lerp([-9.0, G, 28.0], [3.2, G, zr + 2.2], a)
    else:
        hp = [3.2, G, zr + 2.0]
    p_him = hp
    av = [player(1, [1.4, G, zj], facing([0, 0, zj], [0, 0, zj - 5]), k * 9 * TAU, True, face=SCARED)]
    if i < grab:
        av.append(player(0, [3.4, G, zr], facing([0, 0, zr], [0, 0, zr - 5]), k * 9 * TAU + 1.3, True, face=SCARED))
        cr = {"pos": p_him, "yaw": facing(lerp([-9.0, G, 28.0], [3.2, G, zr + 2.2], max(0.0, ease(i / grab) - 0.05)), p_him) if i > 2 else facing(p_him, [3, G, 20]),
              "gait": "Chase", "phase": k * 14 * RUN, "t": stop(i), "jaw": 0.9}
    else:
        # lifted: Riley's feet off the floor, kicking, in his reach
        lift = ease((i - grab) / 8)
        rp = [3.4, G + 2.4 * lift, zr + 0.4]
        av.append(player(0, rp, facing([0, 0, zr], [0, 0, zr - 5]), 0, False, FLAIL if (i // 2) % 2 else dict(FLAIL, lHip=-0.3, rHip=0.6), pitch=0.25 * lift, face=SCARED))
        cr = {"pos": p_him, "yaw": facing(p_him, [p_him[0], G, p_him[2] - 5]), "gait": "Reach", "t": (i - grab) / 30, "jaw": 1.0}
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 72, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [1.8, G + 3.5, zc + 10.0], 18.0, 0.42), exposure=2.1, glow=8, av=av), cr)
shot("hall", 72, s_hall)

# 4. up the stairs after Jamie
def sy(z): return max(G, min(U, 2.05 + 0.625 * (z + 5.3) - 1.0))
def s_stairs(i, k):
    zc = -4.0 + 13.0 * k
    cam = add([-5.2, sy(zc) + 5.2, zc], run_shake(i, 0.9))
    zj = zc + 9.0
    av = [player(1, [-5.4, sy(zj), zj], facing([0, 0, zj], [0, 0, zj + 5]), k * 5 * TAU, True, pitch=0.25, face=SCARED)]
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [-5.2, sy(zc + 8) + 4.6, zc + 9.0], "fov": 72, "roll": 0.04 * math.sin(i * 0.9)},
                 flash=fl(cam, [-5.2, sy(zj) + 3.0, zj + 2.0], 9.0, 0.42), exposure=2.0, av=av), None)
shot("stairs", 33, s_stairs)

# 5. the master bedroom: you get down and slide under the bed; across the room Jamie ducks down by the
# dresser, in the moonlight, looking back at you; then a shape in the doorway
JAMIE_HIDE = [-19.0, U, -16.6]
CROUCH = {"lHip": 1.5, "rHip": 1.5, "lKnee": -2.3, "rKnee": -2.3, "waist": 0.35, "lShoulder": [0.9, 0, -0.3], "rShoulder": [0.9, 0, 0.3],
          "lElbow": 1.4, "rElbow": 1.4, "neckX": -0.2}
def jamie_crouched(i, look=0.0, face=SCARED):
    p = dict(CROUCH, neckY=look, neckX=-0.2 + 0.04 * math.sin(i * 0.5))
    return {"i": 1, "pos": [JAMIE_HIDE[0], U + AV - 1.25 + 0.02 * math.sin(i * 0.9), JAMIE_HIDE[2]], "yaw": facing(JAMIE_HIDE, UNDER), "pose": p, "face": face}
def s_bed(i, k):
    if i < 30:
        # in at the doorway, across the room to the foot of the bed; Jamie peels off to the dresser
        cam = add(lerp([-13.2, U + EYE, -11.0], [-26.5, U + EYE - 0.5, -14.8], ease(i / 30)), run_shake(i, 0.7))
        look = lerp([-24.0, U + 4.0, -14.0], [-34.0, U + 1.0, -14.5], ease(i / 30))
    else:
        a = ease((i - 30) / 22)
        cam = lerp([-26.5, U + EYE - 0.5, -14.8], UNDER, a)
        cam[1] = U + EYE - 0.5 - (EYE - 0.5 - 0.8) * ease((i - 30) / 12)
        look = lerp([-34.0, U + 1.0, -14.5], UNDER_LOOK, ease((i - 34) / 18))
        if i >= 52:
            cam = add(UNDER, [0.02 * math.sin(i * 0.4), 0.015 * math.sin(i * 0.7), 0.0])
    if i < 40:
        r = ease(i / 40)
        jp = lerp([-17.5, U, -15.0], JAMIE_HIDE, r)
        av = [player(1, jp, facing([-17.5, U, -15.0], JAMIE_HIDE), i / 30 * 5 * TAU, True, face=SCARED)]
    else:
        av = [jamie_crouched(i)]
    cr = None
    if i >= 72:
        cr = {"pos": [-9.4, U, -10.8], "yaw": facing([-9.4, U, -10.8], [-24, U, -14]), "gait": "Stare", "t": stop(i), "jaw": 0.3}
    return (dict(DARK, shot="under" if i >= 30 else "room", cam={"pos": cam, "look": look, "fov": 64}, exposure=3.0, door=1.45,
                 flash=fl(cam, [-30.0, U + 1.0, -13.0], 6.0 * (1 - ease((i - 26) / 8)), 0.5), av=av), cr)
shot("bed", 90, s_bed)

def under(i, extra=None):
    fr = dict(DARK, shot="under", cam={"pos": add(UNDER, [0.02 * math.sin(i * 0.4), 0.015 * math.sin(i * 0.7), 0.0]), "look": UNDER_LOOK, "fov": 64},
              exposure=3.0, door=1.45, glow=2)
    if extra: fr.update(extra)
    return fr

# 6. his legs come in and across the room, right up to the foot of the bed... and stop. Jamie, frozen
FOOT = [-26.8, U, -13.8]
def s_legs(i, k):
    c = ease(i / 44)
    p = lerp([-10.5, U, -11.0], FOOT, c)
    cr = {"pos": p, "yaw": facing([-10.5, U, -11.0], FOOT), "gait": "Walk" if i < 44 else "Stare", "phase": c * 4 * math.tau / 6.2, "t": stop(i), "jaw": 0.4}
    return (under(i, {"av": [jamie_crouched(i, 0.4 * ease((i - 10) / 20))]}), cr)
shot("legs", 60, s_legs)

# 7. he turns... to Jamie. Two strides and he has them (the jolt at 16): lifted off the floor, legs
# kicking, up out of sight; he carries them out
def s_grab(i, k):
    to = [JAMIE_HIDE[0] + 1.2, U, JAMIE_HIDE[2] + 1.6]
    if i < 14:
        c = ease(i / 14)
        p = lerp(FOOT, to, c)
        cr = {"pos": p, "yaw": facing(FOOT, to), "gait": "Chase", "phase": c * 2 * RUN, "t": stop(i), "jaw": 0.9}
        av = [jamie_crouched(i, -0.3, SCARED)]
    else:
        j = i - 14
        lift = ease(j / 10)
        out = ease((j - 18) / 24)
        p = lerp(to, [-9.6, U, -10.8], out)
        cr = {"pos": p, "yaw": facing(to, JAMIE_HIDE) if out <= 0 else facing(to, [-9.6, U, -10.8]), "gait": "Reach" if out <= 0 else "Walk",
              "t": j / 30, "phase": out * 5 * math.tau / 6.2, "jaw": 1.0}
        jp = lerp(JAMIE_HIDE, [p[0] - 0.9, U, p[2] - 0.8], 0.5 + 0.5 * out)
        kick = dict(FLAIL) if (i // 2) % 2 else dict(FLAIL, lHip=-0.3, rHip=0.6, lKnee=-0.2, rKnee=-1.0)
        av = [{"i": 1, "pos": [jp[0], U + AV + 0.2 + 3.6 * lift, jp[2]], "yaw": facing(jp, UNDER), "pose": kick, "pitch": 0.2, "face": SCARED}]
    return (under(i, {"av": av, "glow": 3}), cr)
shot("grab", 60, s_grab)

# (Jamie's flashlight, dropped on the floor, pointing at the bed: shown in shot 8 only)
LAMP_AT = [-17.6, U + 0.26, -15.6]
LAMP = [{"shape": "cyl", "pos": [LAMP_AT[0] + 0.25, LAMP_AT[1], LAMP_AT[2]], "rot": [0, 0, math.pi / 2], "s": [0.32, 1.1, 0.32], "col": [28, 28, 34], "rough": 0.4},
        {"shape": "cyl", "pos": [LAMP_AT[0] - 0.33, LAMP_AT[1], LAMP_AT[2]], "rot": [0, 0, math.pi / 2], "s": [0.36, 0.06, 0.36], "col": [255, 246, 220],
         "emissive": [255, 240, 200], "ei": 4.0}]
LAMP_HIDE = [[e["pos"][0], e["pos"][1] - 0.22, e["pos"][2]] for e in LAMP]
# 8. gone. Only Jamie's flashlight, rolling to a stop on the floor; you crawl out towards the foot
def s_empty(i, k):
    a = ease((i - 24) / 36)
    cam = lerp(UNDER, [-29.6, U + 0.9, -14.6], a)
    return (dict(under(i), cam={"pos": add(cam, [0.0, 0.05 * math.sin(i * 0.5) * a, 0.0]), "look": lerp(UNDER_LOOK, [-14.0, U + 1.0, -15.5], a), "fov": 64},
                 av=[], flash={"i": 9.0, "pos": [LAMP_AT[0] - 0.7, U + 0.3, LAMP_AT[2]], "target": [-30.0, U + 0.2, -14.6], "angle": 0.42}), None)
shot("empty", 60, s_empty)

# 9. up on your feet: the dark room, the open door... you turn round: he's right there (22.15 s: frame 64)
TURN_EYE = [-27.4, U + EYE, -14.4]
def s_turn(i, k):
    if i < 64:
        up = ease(i / 18)
        cam = add(lerp([-29.0, U + 0.9, -14.6], TURN_EYE, up), hand(i, 0.6))
        t = ease((i - 26) / 34)
        look = lerp([-10.0, U + 4.6, -11.2], [-33.0, U + 5.6, -24.0], t)
        look[0] += 6.0 * math.sin(math.pi * t)       # (round through the room)
        return (dict(DARK, shot="room", cam={"pos": cam, "look": look, "fov": 60}, exposure=3.0, door=1.45, glow=0, av=[]), None)
    j = i - 64
    cam = TURN_EYE
    p = lerp([-31.0, U, -21.0], [-30.0, U, -19.4], ease(j / 4.0))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [p[0], U + 7.6, p[2]], "fov": 64}, exposure=2.8, glow=12, door=1.45, av=[]),
            {"pos": p, "yaw": facing(p, cam), "gait": "Reach", "t": i / 30, "duck": 0.8, "jaw": 1.0, "neck": [0.0, 0.0, 0.1 * math.sin(i * 0.9)]})
shot("turn", 75, s_turn)

# 10. RUN: out of the bedroom into the upstairs hall, looking back: him through the doorway after you
def s_run(i, k):
    cam = add([-6.0 + 6.0 * k, U + 4.8, -11.0 + 1.5 * k], run_shake(i))
    p = lerp([-17.0, U, -13.0], [-9.0, U, -11.0], k)
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [p[0], U + 4.6, p[2]], "fov": 66, "roll": 0.05 * math.sin(i * 0.9)},
                 flash={"i": 16.0, "pos": [cam[0] - 0.5, cam[1] - 0.5, cam[2]], "target": [p[0], U + 4.0, p[2]], "angle": 0.4},
                 exposure=1.8, glow=8, door=1.45, av=[]),
            {"pos": p, "yaw": facing(p, cam), "gait": "Chase", "phase": k * 15 * RUN, "t": stop(i), "jaw": 0.9})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
empty0 = next(sh["start"] for sh in shots if sh["name"] == "empty")
for fr in frames:
    if not (empty0 <= fr["f"] < empty0 + 60):
        fr["hideExtras"] = LAMP_HIDE
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": AVS, "extras": LAMP,
           "props": {"cache": f"{S}/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
