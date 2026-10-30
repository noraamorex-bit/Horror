# Reel 56 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #9" (30 Oct; the owner's screenshot: #7, mom's texts, at 115K; the
# doorbell #8 12.6K; the family map #8 5K). #2's exact format, look, music and slot lengths; the sequel to #7, the hit: mom
# texts again. "are you awake?" ... "let me in." ... "i'm upstairs." But mom works nights. So i called her. It rang under my
# bed. Someone picked up. He wears the porcelain mask, as in the game, and shows himself twice before the scare (#7's dose):
# in the yard looking up at my window, and at the end of the upstairs hall.
#   hook (105)  Jamie's room, lamps on, cosy
#   card (120)  the same room in the moonlight, a slow push to the bed
#   72  "night 36: mom texted "are you awake?""  in bed: the phone by the pillow lights up, two bubbles
#   33  "night 37: "let me in.""                   from my window, lightning: him on the lawn, looking up at me
#   90  "night 38: "i'm upstairs.""                from my doorway: him standing at the far end of the dark hall
#   60  "mom works nights."                        her room: the bed made, nobody in it
#   60  "so i called her."                         my phone in my hand: calling mom
#   60  "it rang under my bed."                    my room from the door: light under the foot of the bed
#   75  "someone picked up."                       down on the floor, under the bed: her phone lit... his mask behind it, on its
#                                                  side, looking at me; it comes out at me (22.15 s)
#   30  "RUN."                                     down the hall, him after me on all fours
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
NOCANDY = ["CandyWrap", "CandyBody"]
def glowAt(p, b=1.4, r=5.0): return {"p": [p[0], p[1] + 0.7, p[2]], "col": SCREEN, "b": b, "r": r, "decay": 1.6}
# my phone in my hand (the "texted back" shots): the camera stands still at HANDCAM looking down the hall
HANDCAM = [4.2, U + 5.3, 26.4]
# --- the back yard (ground y 0.5; reel 55): from Jamie's back window (the glass at z 30, x -27..-21)
YARD = [-24.5, 0.5, 52.0]
YARDL = [{"p": [-24, 14, 46], "col": MOON, "b": 2.4, "r": 30, "decay": 1.0}, {"p": [-30, U + 8, 24], "col": MOON, "b": 1.6, "r": 14}]
# --- mom's room (the master bedroom, reel 48): the bed's foot at x ~-30.9, z -14.5; her door in the x = -8 wall at z -10
MDOOR = {"near": [-8.0, U + 4.7, -10.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, -12.43], "axis": "y"}
MROOM = [{"p": [-32, U + 8.5, -27.6], "col": MOON, "b": 3.4, "r": 24, "decay": 1.0}, {"p": [-32, U + 9.0, -11.0], "col": MOON, "b": 3.2, "r": 14, "decay": 1.0},
         {"p": [-12, U + 7, -14], "col": COLD, "b": 1.4, "r": 14}]
# --- under my bed (Jamie's): the frame's underside at y 16.6, the floor at U; skirts on three sides, open at the foot (x -31.4)
UNDERPHONE = [-33.2, U + 0.05, 15.6]
UNDERGLOW = {"p": [-33.0, U + 0.45, 15.7], "col": SCREEN, "b": 2.4, "r": 6, "decay": 1.4}
MASKUNDER = [-36.3, U + 0.85, 15.8]
SHOTS = {
    "lit": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 30, "maxLamps": 8, "door": JDOOR},
    "dark": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT, "door": JDOOR},
    "bedPhone": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + [glowAt(BEDPHONE, 0.8, 4)], "door": JDOOR},
    "stairs": {"center": [-5, G + 8, 4], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": STAIRS},
    "below": {"center": [5, U + 6, 14], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD,
              "lights": HALL + [{"p": [6, 31, 10], "col": WARM, "b": 0.5, "r": 10}]},
    "hand": {"center": [4, U + 6, 16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH,
             "lights": HALL + [glowAt([4.3, U + 4.8, 25.1], 1.0, 3.5)]},
    "hall": {"center": [4, U + 6, 16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "lights": HALL},
    "yard": {"center": [-24, 6, 38], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": YARDL},
    "hallEnd": {"center": [0, U + 6, 22], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": JDOOR, "hide": NO_CORD,
                "lights": HALL + [{"p": [10, U + 7, 24], "col": MOON, "b": 1.6, "r": 12}]},
    "mom": {"center": [-26, U + 5, -16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": MDOOR, "lights": MROOM},
    "under": {"center": [-30, U + 4, 18], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + [UNDERGLOW], "door": JDOOR},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}

# --- props (film2 extras): the phones (my dark one and lit one, mom's ringing under my bed, mine calling her)
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
BED_OFF, BED_ON, KPH, HPH = [], [], [], []
BODY = [18, 18, 20]
def phone(group, p, rot, lit, bubbles=False, call=False):
    # a phone (real size: ~0.25 x 0.47 studs) and its screen, on the face its normal points to (rot about x tilts it
    # toward the camera); a lit screen is a dim blue with, if asked, two message bubbles, or a call
    th = rot[0]
    n = [0.0, math.cos(th), math.sin(th)]
    zl = [0.0, -math.sin(th), math.cos(th)]          # (the phone's own length axis: its top is toward -zl)
    def at(dx, dz, h): return [p[0] + dx + n[0] * h + zl[0] * dz, p[1] + n[1] * h + zl[1] * dz, p[2] + n[2] * h + zl[2] * dz]
    ex(group, {"pos": p, "s": [0.25, 0.03, 0.47], "rot": rot, "col": BODY, "rough": 0.3})
    if lit:
        ex(group, {"pos": at(0, 0, 0.017), "s": [0.22, 0.004, 0.42], "rot": rot, "col": [30, 44, 78], "emissive": [40, 62, 120], "ei": 0.55, "rough": 0.2})
        if call:
            # (calling: a grey name bar up top, a red end-call button low)
            ex(group, {"pos": at(0, -0.12, 0.021), "s": [0.15, 0.003, 0.04], "rot": rot, "col": [200, 204, 214], "emissive": [190, 196, 210], "ei": 0.7})
            ex(group, {"pos": at(0, 0.13, 0.021), "s": [0.06, 0.003, 0.06], "rot": rot, "col": [255, 60, 60], "emissive": [255, 50, 50], "ei": 1.1})
        elif bubbles:
            ex(group, {"pos": at(-0.03, -0.11, 0.021), "s": [0.13, 0.003, 0.05], "rot": rot, "col": [200, 204, 214], "emissive": [190, 196, 210], "ei": 0.7})
            ex(group, {"pos": at(0.035, -0.03, 0.021), "s": [0.11, 0.003, 0.045], "rot": rot, "col": [60, 130, 255], "emissive": [60, 130, 255], "ei": 0.9})
        else:
            ex(group, {"pos": at(0, -0.1, 0.021), "s": [0.17, 0.003, 0.05], "rot": rot, "col": [200, 204, 214], "emissive": [190, 196, 210], "ei": 0.7})
    else:
        ex(group, {"pos": at(0, 0, 0.017), "s": [0.22, 0.004, 0.42], "rot": rot, "col": [8, 8, 10], "rough": 0.15})
phone(BED_OFF, BEDPHONE, [0.0, 0.0, 0.0], False)
phone(BED_ON, BEDPHONE, [0.0, 0.0, 0.0], True, True)
phone(KPH, UNDERPHONE, [0.0, 0.0, 0.0], True, False, True)      # (mom's phone, ringing under my bed)
# (in my hand, tilted to face the camera)
HP = [HANDCAM[0] + 0.1, HANDCAM[1] - 0.3, HANDCAM[2] - 1.25]      # (mid-frame, clear of the caption at ~75% down)
phone(HPH, HP, [math.atan2(HANDCAM[2] - HP[2], HANDCAM[1] - HP[1]), 0.0, 0.0], True, False, True)
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

# 3. "night 36: mom texted "are you awake?"" in bed, the phone by the pillow lights up in the dark
def s_text(i, k):
    cam = add([-38.6, U + 5.3, 13.0], hand(i, 0.2))
    on = i >= 14
    return (dict(DARK, shot="bedPhone" if on else "dark", cam={"pos": cam, "look": [-36.6, U + 3.8, 15.1], "fov": 40}, exposure=2.8, lamps=0,
                 door=0.0, hideIdx=only(BED_ON if on else BED_OFF)), None)
shot("door", 72, s_text)

# 4. "night 37: "let me in."" from my back window, lightning: him on the lawn by the swings, looking up at me
CAMY = [-24.2, U + 6.0, 29.2]
def s_yard(i, k):
    cam = add(lerp(CAMY, [-24.3, U + 6.0, 29.0], ease(k)), hand(i, 0.25))
    strike = 1.0 if (4 <= i < 7 or 10 <= i < 12) else 0.0
    return (dict(DARK, shot="yard", cam={"pos": cam, "look": [-24.5, 4.5, 52.0], "fov": 40}, exposure=2.4, lamps=0, glow=1.4,
                 bg=0x0d1424 if strike else 0x010102,
                 flash={"i": 40.0 * strike + 6.0, "pos": [-24.0, 30.0, 40.0], "target": [-24.5, 0.5, 52.0], "angle": 0.6}),
            him(YARD, facing(YARD, cam), "Stare", t=2.0 + stop(i), Look=[0.0, 0.5]))
shot("prints", 33, s_yard)

# 5. "night 38: "i'm upstairs."" from my doorway, my door easing open: him standing at the far end of the dark hall
HALLHIM = [10.0, U, 23.8]
def s_hallend(i, k):
    cam = add(lerp([-10.8, U + 5.4, 24.0], [-9.6, U + 5.4, 24.0], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="hallEnd", cam={"pos": cam, "look": [10.0, U + 4.6, 23.8], "fov": 44}, exposure=2.6, lamps=0,
                 door=0.45 + 1.2 * ease(i / 24), glow=1.2, flash=fl(cam, [10.0, U + 4.0, 23.8], 3.0 * ease((i - 14) / 16), 0.3)),
            him(HALLHIM, facing(HALLHIM, cam), "Stare", t=3.0 + stop(i), Duck=0.2, Look=[0.0, -0.1 + 0.25 * ease((i - 50) / 30)]))
shot("photo", 90, s_hallend)

# 6. "mom works nights." her room from the door: the bed made, nobody in it
def s_mom(i, k):
    cam = add(lerp([-9.5, U + 5.6, -11.5], [-12.5, U + 5.4, -12.5], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="mom", cam={"pos": cam, "look": [-34.0, U + 2.6, -14.5], "fov": 52}, exposure=2.8, lamps=0, door=1.6), None)
shot("setup", 60, s_mom)

# 7. "so i called her." my phone in my hand: calling mom, the hall dark behind it
def s_call(i, k):
    cam = add(HANDCAM, hand(i, 0.08))
    return (dict(DARK, shot="hand", cam={"pos": cam, "look": [4.6, U + 4.0, 20.0], "fov": 58}, exposure=2.4, lamps=0, door=0.0, hideIdx=only(HPH)), None)
shot("open", 60, s_call)

# 8. "it rang under my bed." back in my room, from the door: a light under the foot of the bed, on the floor
def s_rang(i, k):
    cam = add(lerp([-12.0, U + 5.4, 23.0], [-14.5, U + 5.0, 21.5], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="under", cam={"pos": cam, "look": [-32.5, U + 0.8, 15.8], "fov": 50}, exposure=3.0, lamps=0, door=1.7,
                 hideIdx=only(KPH, BED_OFF)), None)
shot("stood", 60, s_rang)

# 9. "someone picked up." down on the floor at the foot of the bed, looking under it: her phone lit on the floor... and behind
# it, his mask on its side, looking at me. On 22.15 s (frame 64) it comes out at me
CAM9 = [-29.6, U + 0.85, 15.8]
def s_under(i, k):
    cam = add(lerp([-29.4, U + 1.6, 16.0], CAM9, ease(i / 18)), hand(i, 0.12 if i < 64 else 0.6))
    look = [-36.0, U + 0.8, 15.8]
    cr = him([-36.0, U, 0.0], 0.0, "Stare", t=3.0 + stop(i), Scream=0.12 * ease((i - 54) / 10))
    if i < 64:
        p = MASKUNDER
        glow = 0.3 + 0.6 * ease((i - 30) / 20)
    else:
        w = ease((i - 64) / 4)
        p = lerp(MASKUNDER, [cam[0] - 1.3, cam[1] + 0.05, cam[2]], w)
        cr = him([-36.0, U, 0.0], 0.0, "Reach", t=3.0 + i / FPS, Scream=1.0)
        glow = 4.0
    cr["head"] = {"pos": p, "look": [cam[0], cam[1], cam[2]], "roll": 1.45}
    cr["noSkin"] = True
    return (dict(DARK, shot="under", cam={"pos": cam, "look": look, "fov": 58 + (8 * ease((i - 64) / 4) if i >= 64 else 0)}, exposure=2.6,
                 lamps=0, door=1.7, glow=glow, hideIdx=only(KPH, BED_OFF)), cr)
shot("knew", 75, s_under)

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
