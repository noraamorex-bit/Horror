# Reel 55 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #8" (the owner, 30 Oct: "just make the next reel #8", after the FIND HIM
# reel). #2's exact format, look, music and slot lengths; #7's recipe (50K: an everyday phone thing turned): the family
# location app. Someone new joined our family map... every night his dot was closer: the yard, the kitchen... tonight his
# dot was on mine. I checked my room. I checked the hall. Then I looked up. He wears the porcelain mask, as in the game, and
# shows himself twice before the scare (#7's dose): in the yard, and in the kitchen.
#   hook (105)  Jamie's room, lamps on, cosy
#   card (120)  the same room in the moonlight, a slow push to the bed
#   72  "night 33: someone joined our family map."   in bed: the phone by the pillow lights up, a map with a new dot
#   33  "night 34: his dot was in our yard."         from my window, lightning: him on the lawn by the swings, looking up
#   90  "night 35: in our kitchen."                  from the hall arch: him at the island, his back to me; his head turns
#   60  "tonight his dot was on mine."               my phone in my hand: two dots on one spot
#   60  "i checked my room."                         my door swings open: the moonlit room, empty
#   60  "i checked the hall."                        a slow step down the dark hall, the hatch shut above
#   75  "then i looked up."                          the hatch is open... his mask comes down out of the dark; it drops (22.15 s)
#   30  "RUN."                                       down the hall, him after me on all fours
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
# --- Jamie's room (reel 47): x -40..-8, z 10..30, floor U; the bed x -39.15..-31.35, z 13.3..18.3 (pillows at x -38.1,
# mattress top ~U + 3.8); the door in the x = -8 wall at z 24 (hinged at z 21.57)
JDOOR = {"near": [-8.0, U + 4.7, 24.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, 21.57], "axis": "y"}
MOONLIT = [{"p": [-24, U + 8.5, 28.6], "col": MOON, "b": 3.4, "r": 24, "decay": 1.0}, {"p": [-38.5, U + 8, 12], "col": MOON, "b": 2.2, "r": 18},
           {"p": [-14, U + 8, 14], "col": COLD, "b": 1.2, "r": 16}]
BEDPHONE = [-36.6, U + 3.86, 15.2]
# --- the stairs (x ~-5, from the front hall at z -5.3 up to the landing at z 17; reel 48)
def sy(z): return max(G, min(U, 2.05 + 0.625 * (z + 5.3) - 1.0))
STAIRS = [{"p": [-5, U + 6, 22], "col": "#2c3d6e", "b": 1.3, "r": 26}, {"p": [-5, 8, -2], "col": COLD, "b": 0.8, "r": 18},
          {"p": [-5, G + 7, -11], "col": MOON, "b": 1.4, "r": 14}]
# --- the attic hatch (reel 46): the hole is x 4..8, z 8..14 in the hall ceiling (y 28.15); the panel hinges down at z = 8
HATCH = {"near": [6.0, 28.0, 11.0], "r": 4.5, "names": ["HatchPanel"], "hinge": [6.0, 28.15, 8.05], "axis": "x"}
NO_CORD = ["Cord", "CordHandle"]
OPEN = math.pi / 2
# --- the upstairs hall: x -8..12, z 16.4..30, and x -2..12 down to z -6 (the stair hole at x -8..-2 below z 16.4)
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [4, U + 8, 4], "col": COLD, "b": 1.2, "r": 16}]
# --- the kitchen island (reel 48): x -28..-22, z 12.5..17.4, its top at y 4.8
KITCHEN = [{"p": [-38, 9, 14], "col": COLD, "b": 1.2, "r": 16}, {"p": [-24, 9, 29], "col": COLD, "b": 0.9, "r": 14},
           {"p": [-32, 9, 31], "col": MOON, "b": 1.8, "r": 18, "decay": 1.2}, {"p": [-16, 9, 18], "col": MOON, "b": 1.4, "r": 18}]
NOCANDY = ["CandyWrap", "CandyBody"]
def glowAt(p, b=1.4, r=5.0): return {"p": [p[0], p[1] + 0.7, p[2]], "col": SCREEN, "b": b, "r": r, "decay": 1.6}
# my phone in my hand (the "texted back" shots): the camera stands still at HANDCAM looking down the hall
HANDCAM = [4.2, U + 5.3, 26.4]
# --- the back yard (ground y 0.5): the patio x -30..-10, z 34..46; the swing set x -32..-19 at z 60. Jamie's back window: the
# glass at z 30, x -27..-21, its middle at y U + 6.2. Lightning seen through glass: a spot outside + a sky colour (reel 37)
YARD = [-24.5, 0.5, 52.0]
YARDL = [{"p": [-24, 14, 46], "col": MOON, "b": 2.4, "r": 30, "decay": 1.0}, {"p": [-30, U + 8, 24], "col": MOON, "b": 1.6, "r": 14}]
# --- the kitchen from the hall arch (x = -8 wall at z 26): him between the island (x -28..-22, z 12.5..17.4) and the fridge
KHIM = [-24.6, G, 19.6]
# --- Jamie's door from the upstairs hall (it swings in, hinged at z 21.57)
JHALL = [{"p": [-2, U + 8, 22], "col": MOON, "b": 2.2, "r": 16}]
SHOTS = {
    "lit": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 30, "maxLamps": 8, "door": JDOOR},
    "dark": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT, "door": JDOOR},
    "bedPhone": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + [glowAt(BEDPHONE, 0.8, 4)], "door": JDOOR},
    "stairs": {"center": [-5, G + 8, 4], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": STAIRS},
    "below": {"center": [5, U + 6, 14], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD,
              "lights": HALL + [{"p": [6, 31, 10], "col": WARM, "b": 0.5, "r": 10}]},
    "kitchen": {"center": [-24, G + 5, 18], "radius": 32, "lampRadius": 0, "maxLamps": 0, "lights": KITCHEN},
    "yard": {"center": [-24, 6, 38], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": YARDL},
    "room": {"center": [-22, U + 5, 20], "radius": 32, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + JHALL, "door": JDOOR, "hide": ["Globe", "Bulb", "Base", "Finial"]},
    "hand": {"center": [4, U + 6, 16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH,
             "lights": HALL + [glowAt([4.3, U + 4.8, 25.1], 1.0, 3.5)]},
    "hall": {"center": [4, U + 6, 16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "lights": HALL},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}

# --- props (film2 extras): the phones (a dark one and a lit one where the screen turns on)
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
BED_OFF, BED_ON, HPH = [], [], []
BODY = [18, 18, 20]
def phone(group, p, rot, lit, dots=None):
    # a phone (real size: ~0.25 x 0.47 studs) and its screen, on the face its normal points to (rot about x tilts it
    # toward the camera); a lit screen shows the family map with its dots (dx, dz, colour)
    th = rot[0]
    n = [0.0, math.cos(th), math.sin(th)]
    zl = [0.0, -math.sin(th), math.cos(th)]          # (the phone's own length axis: its top is toward -zl)
    def at(dx, dz, h): return [p[0] + dx + n[0] * h + zl[0] * dz, p[1] + n[1] * h + zl[1] * dz, p[2] + n[2] * h + zl[2] * dz]
    ex(group, {"pos": p, "s": [0.25, 0.03, 0.47], "rot": rot, "col": BODY, "rough": 0.3})
    if lit:
        # (a family map: a dim grey-green map, two pale roads, our house block, and the dots: blue = me, red = him)
        ex(group, {"pos": at(0, 0, 0.017), "s": [0.22, 0.004, 0.42], "rot": rot, "col": [44, 56, 50], "emissive": [52, 66, 58], "ei": 0.55, "rough": 0.2})
        ex(group, {"pos": at(0, 0.05, 0.019), "s": [0.22, 0.003, 0.018], "rot": rot, "col": [150, 156, 150], "emissive": [130, 136, 130], "ei": 0.6})
        ex(group, {"pos": at(-0.04, 0, 0.019), "s": [0.016, 0.003, 0.42], "rot": rot, "col": [150, 156, 150], "emissive": [130, 136, 130], "ei": 0.6})
        ex(group, {"pos": at(0.035, -0.04, 0.0195), "s": [0.07, 0.003, 0.06], "rot": rot, "col": [84, 96, 90], "emissive": [70, 82, 76], "ei": 0.6})
        ex(group, {"pos": at(0, -0.17, 0.0205), "s": [0.2, 0.003, 0.05], "rot": rot, "col": [220, 222, 226], "emissive": [200, 204, 210], "ei": 0.6})
        for dx, dz, col in (dots or []):
            ex(group, {"pos": at(dx, dz, 0.022), "s": [0.03, 0.003, 0.03], "rot": rot, "col": col, "emissive": col, "ei": 1.4})
    else:
        ex(group, {"pos": at(0, 0, 0.017), "s": [0.22, 0.004, 0.42], "rot": rot, "col": [8, 8, 10], "rough": 0.15})
phone(BED_OFF, BEDPHONE, [0.0, 0.0, 0.0], False)
ME, HIM = [70, 140, 255], [255, 40, 40]
phone(BED_ON, BEDPHONE, [0.0, 0.0, 0.0], True, [(0.035, -0.04, ME), (-0.07, 0.13, HIM)])
# (in my hand, tilted to face the camera)
HP = [HANDCAM[0] + 0.1, HANDCAM[1] - 0.3, HANDCAM[2] - 1.25]      # (mid-frame, clear of the caption at ~75% down)
phone(HPH, HP, [math.atan2(HANDCAM[2] - HP[2], HANDCAM[1] - HP[1]), 0.0, 0.0], True, [(0.035, -0.04, ME), (0.045, -0.032, HIM)])
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

# 1. (hook) Jamie's room, lamps on: cosy
def s_hook(i, k):
    cam = add(lerp([-12.5, U + 6.2, 21.0], [-14.0, U + 6.0, 20.6], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([-34.0, U + 3.4, 17.0], [-34.5, U + 3.3, 16.8], ease(k)), "fov": 60}, door=0.0,
                 hideIdx=only(BED_OFF)), None)
shot("hook", 105, s_hook)

# 2. (card) the same room in the moonlight, a slow push to the bed
def s_card(i, k):
    cam = add(lerp([-12.0, U + 6.4, 21.5], [-16.0, U + 6.0, 20.2], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="dark", cam={"pos": cam, "look": [-35.0, U + 3.2, 16.4], "fov": 60}, exposure=3.6, lamps=0, door=0.0,
                 hideIdx=only(BED_OFF)), None)
shot("card", 120, s_card)

# 3. "night 33: someone joined our family map." in bed, the phone by the pillow lights up: the map, a new red dot
def s_text(i, k):
    cam = add([-38.6, U + 5.3, 13.0], hand(i, 0.2))
    on = i >= 14
    return (dict(DARK, shot="bedPhone" if on else "dark", cam={"pos": cam, "look": [-36.6, U + 3.8, 15.1], "fov": 40}, exposure=2.8, lamps=0,
                 door=0.0, hideIdx=only(BED_ON if on else BED_OFF)), None)
shot("door", 72, s_text)

# 4. "night 34: his dot was in our yard." from my back window, lightning: him on the lawn by the swings, looking up at me
CAMY = [-24.2, U + 6.0, 29.2]
def s_yard(i, k):
    cam = add(lerp(CAMY, [-24.3, U + 6.0, 29.0], ease(k)), hand(i, 0.25))
    strike = 1.0 if (4 <= i < 7 or 10 <= i < 12) else 0.0
    return (dict(DARK, shot="yard", cam={"pos": cam, "look": [-24.5, 4.5, 52.0], "fov": 42}, exposure=2.4, lamps=0, glow=1.4,
                 bg=0x0d1424 if strike else 0x010102,
                 flash={"i": 40.0 * strike + 6.0, "pos": [-24.0, 30.0, 40.0], "target": [-24.5, 0.5, 52.0], "angle": 0.6}),
            him(YARD, facing(YARD, cam), "Stare", t=2.0 + stop(i), Look=[0.0, 0.5]))
shot("prints", 33, s_yard)

# 5. "night 35: in our kitchen." from the hall arch: him between the island and the fridge, his back to me, still...
# then his head turns right round (13 poses a second)
def s_kitchen(i, k):
    cam = add(lerp([-9.0, G + 5.5, 25.6], [-11.0, G + 5.4, 24.6], ease(k)), hand(i, 0.3))
    turn = ease((stop(i) * 30 - 42) / 30)
    away = facing(KHIM, [-40.0, G, 17.0])
    return (dict(DARK, shot="kitchen", cam={"pos": cam, "look": [-24.6, G + 5.4, 19.0], "fov": 46}, exposure=2.5, lamps=0, glow=0.6 + 1.4 * turn,
                 flash=fl(cam, [-24.6, G + 6.0, 19.6], 4.0, 0.3)),
            him(KHIM, away, "Stare", t=3.0 + stop(i), Duck=0.3, Look=[-2.9 * turn, 0.15 * turn]))
shot("photo", 90, s_kitchen)

# 6. "tonight his dot was on mine." my phone in my hand, the upstairs hall dark behind it
def s_reply(i, k):
    cam = add(HANDCAM, hand(i, 0.08))
    return (dict(DARK, shot="hand", cam={"pos": cam, "look": [4.6, U + 4.0, 20.0], "fov": 58}, exposure=2.4, lamps=0, door=0.0, hideIdx=only(HPH)), None)
shot("setup", 60, s_reply)

# 7. "i checked my room." from the hall: my door swings open on the moonlit room: nobody
def s_room(i, k):
    cam = add(lerp([-0.5, U + 5.4, 24.6], [-4.0, U + 5.4, 24.2], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-30.0, U + 3.6, 21.0], "fov": 56}, exposure=3.0, lamps=0,
                 door=1.7 * ease((i - 4) / 26), flash=fl(cam, [-24.0, U + 2.0, 20.0], 5.0 * ease((i - 12) / 14), 0.4)), None)
shot("open", 60, s_room)

# 8. "i checked the hall." a slow step down the dark hall, the hatch shut above
def s_where(i, k):
    cam = add(lerp([4.4, U + 5.4, 25.0], [4.9, U + 5.4, 21.6], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [5.8, U + 4.4, 2.0], "fov": 56}, exposure=2.6, lamps=0, door=0.0,
                 flash=fl(cam, [6.0, U + 2.5, 8.0], 4.0, 0.4)), None)
shot("stood", 60, s_where)

# 9. "then i looked up." under the hatch: the view tilts up... it's open, and his mask comes down out of the dark, upside down,
# slowly... and on 22.15 s (frame 64) it drops at me, jaw open (only the mask: his body is the dark of the attic)
CAM9 = [5.8, U + 5.3, 17.4]
def s_up(i, k):
    cam = add(CAM9, hand(i, 0.3 if i < 64 else 1.2))
    look = lerp([6.0, U + 4.6, 4.0], [6.0, 26.6, 12.2], ease((i - 6) / 26))
    torch = fl(cam, lerp([6.0, U + 3.0, 8.0], [6.0, 28.6, 11.0], ease((i - 6) / 26)), 9.0, 0.3)
    if i < 64:
        w = ease((i - 30) / 32)
        p = lerp([6.0, 29.8, 10.6], [6.0, 26.8, 11.4], w)
        cr = him([6.0, U, 0.0], 0.0, "Stare", t=3.0 + stop(i), Scream=0.12 * ease((i - 54) / 10))
        cr["head"] = {"pos": p, "look": [cam[0], cam[1], cam[2]], "roll": 0.55}
        cr["noSkin"] = True
        return (dict(DARK, shot="below", cam={"pos": cam, "look": look, "fov": 60}, exposure=2.3, door=OPEN, flash=torch,
                     glow=0.6 + 1.2 * w), cr)
    w = ease((i - 64) / 4)
    p = lerp([6.0, 26.8, 11.4], [5.85, U + 5.45, 15.4], w)
    cr = him([6.0, U, 0.0], 0.0, "Reach", t=3.0 + i / FPS, Scream=1.0)
    cr["head"] = {"pos": p, "look": [cam[0], cam[1] + 0.1, cam[2]], "roll": 0.55 * (1 - w)}
    cr["noSkin"] = True
    return (dict(DARK, shot="below", cam={"pos": cam, "look": lerp(look, p, 0.7 * w), "fov": 60 + 8 * w}, exposure=2.4, door=OPEN,
                 flash=fl(cam, p, 12.0, 0.45), glow=4.0), cr)
shot("knew", 75, s_up)

# 10. RUN: down the hall, away from the hatch, looking back: he's down and coming after me on all fours
def s_run(i, k):
    cam = [5.6 + 0.25 * math.sin(i * 1.7), U + 5.0 + 0.2 * math.sin(i * 2.3), 5.0 - 6.0 * k]
    hp = lerp([5.6, U, 13.5], [5.8, U, 7.0], k)
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
