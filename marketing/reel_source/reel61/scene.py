# Reel 61 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #14" (2 Nov; #7, mom's texts, 115K: quoted texts with a twist win). #2's exact
# format, look, music and slot lengths; the texts again, a new twist: someone called "dad" joins our family group chat, and we don't
# have a dad. "which room is lily's?" Mom blocked him. Tonight he texted me: "you look so peaceful." ... "goodnight, son." He wears the
# porcelain mask, as in the game, and shows himself twice before the scare (#7's dose).
#   hook (105)  my room (Jamie's), the lamps on, cosy
#   card (120)  the same room in the moonlight, a slow push to the bed
#   72  "night 51: "dad" joined our family chat."   in bed: my phone by the pillow lights up, two bubbles
#   33  "we don't have a dad."                       from the top of the stairs: him at the bottom, looking up
#   90  "night 52: "which room is lily's?""          from Lily's bed: him stooped in her doorway
#   60  "so mom blocked him."                         my phone in my hand in the upstairs hall
#   60  "tonight he texted me."                       in bed: my phone by the pillow lights up again
#   60  ""you look so peaceful.""                     from my pillow: my door, open a crack
#   75  ""goodnight, son.""                           turn to the side of the bed: he's crouched right there (22.15 s)
#   30  "RUN."                                        down the hall, him after me on all fours
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
NOCANDY = ["CandyWrap", "CandyBody"]
# --- the front hall (reels 53/57): the front door at x 2 in the z = -30 wall (hinged at x -0.43); the wall's inside face at
# z -29.41 right of the door (the light switch at x 5.5); the keypad beside the switch
FDOOR = {"near": [2.0, 5.7, -30.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-0.43, 0, -30.0], "axis": "y"}
INSIDE = [{"p": [2, G + 9, -20], "col": COLD, "b": 1.0, "r": 18}, {"p": [2, G + 6, -34], "col": MOON, "b": 2.2, "r": 18, "decay": 1.1},
          {"p": [-5, U + 6, 10], "col": "#2c3d6e", "b": 1.0, "r": 22}]
KP = [6.7, G + 5.2, -29.36]
KPRED = {"p": [KP[0], KP[1] + 0.2, KP[2] + 0.5], "col": "#ff3030", "b": 0.35, "r": 2.6, "decay": 2.0}
KPGREEN = {"p": [KP[0], KP[1] + 0.2, KP[2] + 0.5], "col": "#40ff70", "b": 0.25, "r": 2.4, "decay": 2.0}
# --- the stairs (reel 52): from the landing, him at the bottom
STAIRS = [{"p": [-5, U + 6, 22], "col": "#2c3d6e", "b": 1.3, "r": 26}, {"p": [-5, 8, -2], "col": COLD, "b": 0.8, "r": 18},
          {"p": [-5, G + 7, -11], "col": MOON, "b": 1.4, "r": 14}]
# --- my room (Jamie's; reels 56/58): the bed x -39.15..-31.35, z 13.3..18.3; the door in the x = -8 wall at z 24
JDOOR = {"near": [-8.0, U + 4.7, 24.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, 21.57], "axis": "y"}
MOONLIT = [{"p": [-24, U + 8.5, 28.6], "col": MOON, "b": 3.4, "r": 24, "decay": 1.0}, {"p": [-38.5, U + 8, 12], "col": MOON, "b": 2.2, "r": 18},
           {"p": [-14, U + 8, 14], "col": COLD, "b": 1.2, "r": 16}]
BEDPHONE = [-36.6, U + 3.86, 15.2]
def glowAt(p, b=1.4, r=5.0): return {"p": [p[0], p[1] + 0.7, p[2]], "col": SCREEN, "b": b, "r": r, "decay": 1.6}
# --- Lily's room (reel 51): her door in the x = 12 wall at z 20 (hinged at z 17.55)
LILYDOOR = {"near": [12.0, U + 4.7, 20.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [12.0, 0, 17.55], "axis": "y"}
LROOM = [{"p": [13.6, U + 2.2, 27.5], "col": "#ff9fc4", "b": 1.6, "r": 16, "decay": 1.3},
         {"p": [26.0, U + 8.0, 31.5], "col": MOON, "b": 3.4, "r": 24, "decay": 1.1},
         {"p": [30.0, U + 8.0, 12.0], "col": COLD, "b": 1.2, "r": 16}]
# --- the upstairs hall (reel 56)
HATCH = {"near": [6.0, 28.0, 11.0], "r": 4.5, "names": ["HatchPanel"], "hinge": [6.0, 28.15, 8.05], "axis": "x"}
NO_CORD = ["Cord", "CordHandle"]
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [4, U + 8, 4], "col": COLD, "b": 1.2, "r": 16}]
SHOTS = {
    "lit": {"center": [2, G + 5, -16], "radius": 30, "lampRadius": 30, "maxLamps": 8, "door": FDOOR},
    "hallDark": {"center": [2, G + 5, -16], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": INSIDE},
    "kpRed": {"center": [2, G + 5, -16], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": INSIDE + [KPRED]},
    "kpGreen": {"center": [2, G + 5, -16], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": INSIDE + [KPGREEN]},
    "stairs": {"center": [-5, G + 8, 4], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": STAIRS},
    "hallEnd": {"center": [0, U + 6, 22], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": JDOOR, "hide": NO_CORD,
                "lights": HALL + [{"p": [10, U + 7, 24], "col": MOON, "b": 1.6, "r": 12}]},
    "bedDark": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT, "door": JDOOR},
    "bedPhone": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + [glowAt(BEDPHONE, 0.8, 4)], "door": JDOOR},
    "hall": {"center": [4, U + 6, 16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "lights": HALL},
    "jlit": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 30, "maxLamps": 8, "door": JDOOR},
    "hand": {"center": [4, U + 6, 16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH,
             "lights": HALL + [glowAt([4.3, U + 4.8, 25.1], 1.0, 3.5)]},
    "lily": {"center": [26, U + 5, 19], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR, "hide": ["Bulb", "Globe", "Base", "Finial"],
             "lights": LROOM + [{"p": [6, U + 8, 18], "col": COLD, "b": 1.6, "r": 16}]},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}

# --- props (film2 extras): my phone by the pillow (dark / lit with two bubbles), my phone in my hand
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
BED_OFF, BED_ON, HPH = [], [], []
BODY = [18, 18, 20]
def phone(group, p, rot, lit):
    th = rot[0]
    n = [0.0, math.cos(th), math.sin(th)]
    zl = [0.0, -math.sin(th), math.cos(th)]
    def at(dx, dz, h): return [p[0] + dx + n[0] * h + zl[0] * dz, p[1] + n[1] * h + zl[1] * dz, p[2] + n[2] * h + zl[2] * dz]
    ex(group, {"pos": p, "s": [0.25, 0.03, 0.47], "rot": rot, "col": BODY, "rough": 0.3})
    if lit:
        ex(group, {"pos": at(0, 0, 0.017), "s": [0.22, 0.004, 0.42], "rot": rot, "col": [30, 44, 78], "emissive": [40, 62, 120], "ei": 0.55, "rough": 0.2})
        # (the group chat: a grey bubble, then a blue one)
        ex(group, {"pos": at(-0.03, -0.11, 0.021), "s": [0.13, 0.003, 0.05], "rot": rot, "col": [200, 204, 214], "emissive": [190, 196, 210], "ei": 0.7})
        ex(group, {"pos": at(-0.035, -0.03, 0.021), "s": [0.11, 0.003, 0.045], "rot": rot, "col": [200, 204, 214], "emissive": [190, 196, 210], "ei": 0.7})
    else:
        ex(group, {"pos": at(0, 0, 0.017), "s": [0.22, 0.004, 0.42], "rot": rot, "col": [8, 8, 10], "rough": 0.15})
phone(BED_OFF, BEDPHONE, [0.0, 0.0, 0.0], False)
phone(BED_ON, BEDPHONE, [0.0, 0.0, 0.0], True)
HANDCAM = [4.2, U + 5.3, 26.4]
HP = [HANDCAM[0] + 0.1, HANDCAM[1] - 0.3, HANDCAM[2] - 1.25]
phone(HPH, HP, [math.atan2(HANDCAM[2] - HP[2], HANDCAM[1] - HP[1]), 0.0, 0.0], True)
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
        fr.setdefault("hideIdx", only(BED_OFF))
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}

# 1. (hook) my room, lamps on: cosy
def s_hook(i, k):
    cam = add(lerp([-12.5, U + 6.2, 21.0], [-14.0, U + 6.0, 20.6], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="jlit", cam={"pos": cam, "look": lerp([-34.0, U + 3.4, 17.0], [-34.5, U + 3.3, 16.8], ease(k)), "fov": 60}, door=0.0), None)
shot("hook", 105, s_hook)

# 2. (card) the same room in the moonlight, a slow push to the bed
def s_card(i, k):
    cam = add(lerp([-12.0, U + 6.4, 21.5], [-16.0, U + 6.0, 20.2], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="bedDark", cam={"pos": cam, "look": [-35.0, U + 3.2, 16.4], "fov": 60}, exposure=3.6, lamps=0, door=0.0), None)
shot("card", 120, s_card)

# 3. "night 51: "dad" joined our family chat." in bed, the phone by the pillow lights up in the dark
def s_text(i, k):
    cam = add([-38.6, U + 5.3, 13.0], hand(i, 0.2))
    on = i >= 14
    return (dict(DARK, shot="bedPhone" if on else "bedDark", cam={"pos": cam, "look": [-36.6, U + 3.8, 15.1], "fov": 40}, exposure=2.8, lamps=0,
                 door=0.0, hideIdx=only(BED_ON if on else BED_OFF)), None)
shot("door", 72, s_text)

# 4. "we don't have a dad." from the top of the stairs: him standing at the bottom, looking up
FOOT = [-5.0, G, -9.5]
def s_down(i, k):
    cam = add(lerp([-5.2, U + 5.5, 20.4], [-5.1, U + 5.4, 19.8], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, G + 5.0, -6.0], "fov": 40}, exposure=2.4, lamps=0, glow=1.6,
                 flash=fl(cam, [-5.0, G + 5.0, -8.5], 14.0, 0.2)),
            him(FOOT, facing(FOOT, cam), "Stare", t=2.0 + stop(i), Look=[0.0, 0.45]))
shot("prints", 33, s_down)

# 5. "night 52: "which room is lily's?"" from Lily's bed: him stooped in her doorway, the hall's light behind him
LDOORWAY = [13.0, U, 20.0]
def s_lily(i, k):
    cam = add([33.4, U + 4.4, 24.4], hand(i, 0.3))
    return (dict(DARK, shot="lily", cam={"pos": cam, "look": lerp([13.2, U + 6.0, 20.0], [13.2, U + 6.6, 20.0], ease(k)), "fov": 40}, exposure=2.6,
                 glow=2.4, door=1.25),
            him(LDOORWAY, facing(LDOORWAY, cam), "Stare", t=4.0 + stop(i), Duck=0.55, Look=[0.5 * ease((i - 30) / 30), -0.2]))
shot("photo", 90, s_lily)

# 6. "so mom blocked him." my phone in my hand in the upstairs hall, the dark behind it
def s_hand(i, k):
    cam = add(HANDCAM, hand(i, 0.08))
    return (dict(DARK, shot="hand", cam={"pos": cam, "look": [4.6, U + 4.0, 20.0], "fov": 58}, exposure=2.4, lamps=0, door=0.0, hideIdx=only(HPH)), None)
shot("setup", 60, s_hand)

# 7. "tonight he texted me." in bed: my phone by the pillow lights up again, closer
def s_again(i, k):
    cam = add(lerp([-38.4, U + 5.0, 13.6], [-38.1, U + 4.8, 14.0], ease(k)), hand(i, 0.2))
    on = i >= 10
    return (dict(DARK, shot="bedPhone" if on else "bedDark", cam={"pos": cam, "look": [-36.6, U + 3.8, 15.1], "fov": 34}, exposure=2.8, lamps=0,
                 door=0.0, hideIdx=only(BED_ON if on else BED_OFF)), None)
shot("open", 60, s_again)

# 8. ""you look so peaceful."" from my pillow: my door, open a crack onto the dark hall
BEDEYE = [-37.9, U + 4.7, 16.2]
DOORLOOK = [-8.6, U + 5.0, 23.6]
def s_door(i, k):
    cam = add(BEDEYE, hand(i, 0.25))
    return (dict(DARK, shot="bedPhone", cam={"pos": cam, "look": lerp(DOORLOOK, [-9.0, U + 4.6, 23.2], ease(k)), "fov": 44}, exposure=2.8, lamps=0,
                 door=0.7, hideIdx=only(BED_ON)), None)
shot("stood", 60, s_door)

# 9. ""goodnight, son."" still looking at my door... turn to the side of the bed: he's crouched right there,
# his face level with mine; he comes at me on 22.15 s (frame 64)
SIDE = [-35.2, U, 24.8]
def s_knew(i, k):
    cam = add(BEDEYE, hand(i, 0.3))
    t = ease((i - 20) / 22)
    y0, y1 = facing(cam, DOORLOOK), facing(cam, SIDE)
    yaw = y0 + wrap(y1 - y0) * t
    ly = DOORLOOK[1] + ((U + 8.2) - DOORLOOK[1]) * ease((i - 26) / 22)
    dist = 20.0 - 11.0 * t
    look = [cam[0] - math.sin(yaw) * dist, ly, cam[2] - math.cos(yaw) * dist]
    hide = only(BED_ON)
    if i < 64:
        fr = dict(DARK, shot="bedPhone", cam={"pos": cam, "look": look, "fov": 52}, exposure=2.6, lamps=0, door=0.7, glow=2.4 if t > 0.5 else 0.8,
                  flash=fl(cam, look, 6.0 * t, 0.4), hideIdx=hide)
        return (fr, him(SIDE, facing(SIDE, cam), "Stare", t=3.0 + stop(i), Duck=1.0, Look=[0.0, -0.2], Scream=0.2 * ease((i - 54) / 10)))
    w = ease((i - 64) / 4)
    near = [cam[0] + 0.9, U, cam[2] + 3.8]
    p = lerp(SIDE, near, w)
    camw = add(cam, [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    fr = dict(DARK, shot="bedPhone", cam={"pos": camw, "look": lerp(look, [p[0], U + 9.4, p[2]], w), "fov": 52 + 10 * w}, exposure=2.6, lamps=0,
              door=0.7, glow=7.0, flash=fl(camw, [p[0], U + 6.5, p[2]], 14.0, 0.5), hideIdx=hide)
    return (fr, him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Look=[0.0, -0.3]))
shot("knew", 75, s_knew)

# 10. RUN: down the hall, looking back: he comes after me on all fours
def s_run(i, k):
    cam = [5.6 + 0.25 * math.sin(i * 1.7), U + 5.0 + 0.2 * math.sin(i * 2.3), 13.0 - 6.0 * k]
    hp = lerp([5.2, U, 23.0], [5.6, U, 15.5], k)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [hp[0], U + 2.8, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)}, door=0.0,
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), U + 3.2, hp[2]], 16.0, 0.36), ambient=0.01, exposure=2.0, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
