# Reel 52 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #7" (the new run, after #6 = reel 51): #2's exact format, look,
# music and slot lengths. A new hook, not a new monster (29 Oct: #4-#6 with the v112 look sat at ~1.4K; #3, the voices,
# did 5.3K): mom's texts. Every night mom texts me from downstairs... but mom's phone was in the kitchen. So i texted
# back: "where are you?" ... "behind you." He wears the porcelain mask, as in the game, and shows himself twice before
# the scare (#3's dose): at the bottom of the stairs, and his mask in the attic hatch.
#   hook (105)  Jamie's room, lamps on, cosy
#   card (120)  the same room in the moonlight, a slow push to the bed
#   72  "night 27: mom texted "you up?""     in bed: the phone by the pillow lights up in the dark
#   33  "night 28: "come downstairs.""       the top of the stairs: something standing at the bottom, looking up
#   90  "night 29: "i'm in the attic.""      under the open hatch, the ladder down: his mask in the dark above
#   60  "mom's phone was in the kitchen."    her phone face up on the island, the screen lit
#   60  "so i texted back."                  my phone in my hand, the upstairs hall dark behind it
#   60  "\"where are you?\""                 the phone lowered: the empty hall
#   75  "\"behind you.\""                    turn round: him right behind me, the mask tilted; he comes (22.15 s)
#   30  "RUN."                               down the hall, him after me on all fours
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
KPHONE = [-23.0, 4.83, 16.7]       # (on the overhang, clear of the bowl and the boards on the island)
KITCHEN = [{"p": [-38, 9, 14], "col": COLD, "b": 1.2, "r": 16}, {"p": [-24, 9, 29], "col": COLD, "b": 0.9, "r": 14},
           {"p": [-32, 9, 31], "col": MOON, "b": 1.8, "r": 18, "decay": 1.2}, {"p": [-16, 9, 18], "col": MOON, "b": 1.4, "r": 18}]
NOCANDY = ["CandyWrap", "CandyBody"]
def glowAt(p, b=1.4, r=5.0): return {"p": [p[0], p[1] + 0.7, p[2]], "col": SCREEN, "b": b, "r": r, "decay": 1.6}
# my phone in my hand (the "texted back" shots): the camera stands still at HANDCAM looking down the hall
HANDCAM = [4.2, U + 5.3, 26.4]
SHOTS = {
    "lit": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 30, "maxLamps": 8, "door": JDOOR},
    "dark": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT, "door": JDOOR},
    "bedPhone": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + [glowAt(BEDPHONE, 0.8, 4)], "door": JDOOR},
    "stairs": {"center": [-5, G + 8, 4], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": STAIRS},
    "below": {"center": [5, U + 6, 14], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD,
              "lights": HALL + [{"p": [6, 31, 10], "col": WARM, "b": 0.5, "r": 10}]},
    "kitchen": {"center": [-24, G + 5, 18], "radius": 32, "lampRadius": 0, "maxLamps": 0, "lights": KITCHEN + [glowAt(KPHONE, 1.8, 6)]},
    "hand": {"center": [4, U + 6, 16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH,
             "lights": HALL + [glowAt([4.32, U + 4.7, 25.3], 1.0, 3.5)]},
    "hall": {"center": [4, U + 6, 16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "lights": HALL},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}

# --- props (film2 extras): the phones (a dark one and a lit one where the screen turns on), the hatch ladder
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
BED_OFF, BED_ON, KPH, HPH, LADDER = [], [], [], [], []
BODY = [18, 18, 20]
def phone(group, p, rot, lit, bubbles=False):
    # a phone (real size: ~0.25 x 0.47 studs) and its screen, on the face its normal points to (rot about x tilts it
    # toward the camera); a lit screen is a dim blue with, if asked, two message bubbles on it
    th = rot[0]
    n = [0.0, math.cos(th), math.sin(th)]
    zl = [0.0, -math.sin(th), math.cos(th)]          # (the phone's own length axis: its top is toward -zl)
    def at(dx, dz, h): return [p[0] + dx + n[0] * h + zl[0] * dz, p[1] + n[1] * h + zl[1] * dz, p[2] + n[2] * h + zl[2] * dz]
    ex(group, {"pos": p, "s": [0.25, 0.03, 0.47], "rot": rot, "col": BODY, "rough": 0.3})
    if lit:
        ex(group, {"pos": at(0, 0, 0.017), "s": [0.22, 0.004, 0.42], "rot": rot, "col": [70, 96, 150], "emissive": [70, 100, 170], "ei": 1.1, "rough": 0.2})
        if bubbles:
            ex(group, {"pos": at(-0.03, -0.11, 0.021), "s": [0.13, 0.003, 0.05], "rot": rot, "col": [230, 232, 238], "emissive": [220, 224, 235], "ei": 1.2})
            ex(group, {"pos": at(0.035, -0.03, 0.021), "s": [0.11, 0.003, 0.045], "rot": rot, "col": [90, 160, 255], "emissive": [80, 150, 255], "ei": 1.4})
        else:
            ex(group, {"pos": at(0, -0.1, 0.021), "s": [0.17, 0.003, 0.05], "rot": rot, "col": [230, 232, 238], "emissive": [220, 224, 235], "ei": 1.2})
    else:
        ex(group, {"pos": at(0, 0, 0.017), "s": [0.22, 0.004, 0.42], "rot": rot, "col": [8, 8, 10], "rough": 0.15})
phone(BED_OFF, BEDPHONE, [0.0, 0.0, 0.0], False)
phone(BED_ON, BEDPHONE, [0.0, 0.0, 0.0], True)
phone(KPH, KPHONE, [0.0, 0.0, 0.0], True)
# (in my hand, tilted to face the camera)
HP = [HANDCAM[0] + 0.1, HANDCAM[1] - 0.42, HANDCAM[2] - 1.15]
phone(HPH, HP, [math.atan2(HANDCAM[2] - HP[2], HANDCAM[1] - HP[1]), 0.0, 0.0], True, True)
WOOD = [150, 118, 80]
TOP, BOT = [9.2, 28.2], [14.3, U]
L = math.hypot(TOP[0] - BOT[0], TOP[1] - BOT[1])
RX = -math.atan2(BOT[0] - TOP[0], TOP[1] - BOT[1])
for x in (5.1, 6.9):
    ex(LADDER, {"pos": [x, (TOP[1] + BOT[1]) / 2, (TOP[0] + BOT[0]) / 2], "s": [0.22, L, 0.45], "rot": [RX, 0, 0], "col": WOOD})
for j in range(1, 12):
    k = j / 12
    ex(LADDER, {"pos": [6.0, BOT[1] + (TOP[1] - BOT[1]) * k, BOT[0] + (TOP[0] - BOT[0]) * k], "s": [1.8, 0.16, 0.5], "rot": [RX, 0, 0], "col": WOOD})
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

# 3. "night 27: mom texted "you up?"" in bed, the phone by the pillow lights up in the dark
def s_text(i, k):
    cam = add([-38.6, U + 5.3, 13.0], hand(i, 0.2))
    on = i >= 14
    return (dict(DARK, shot="bedPhone" if on else "dark", cam={"pos": cam, "look": [-36.6, U + 3.8, 15.1], "fov": 40}, exposure=2.8, lamps=0,
                 door=0.0, hideIdx=only(BED_ON if on else BED_OFF)), None)
shot("door", 72, s_text)

# 4. "night 28: "come downstairs."" the top of the stairs: something standing at the bottom, looking up
FOOT = [-5.0, G, -9.5]
def s_down(i, k):
    cam = add(lerp([-5.2, U + 5.5, 20.4], [-5.1, U + 5.4, 19.8], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, G + 5.0, -6.0], "fov": 40}, exposure=2.4, lamps=0, glow=1.6,
                 flash=fl(cam, [-5.0, G + 5.0, -8.5], 14.0, 0.2)),
            him(FOOT, facing(FOOT, cam), "Stare", t=2.0 + stop(i), Look=[0.0, 0.45]))
shot("prints", 33, s_down)

# 5. "night 29: "i'm in the attic."" under the open hatch, the ladder down, the flashlight climbing it: his mask in the
# dark above, looking down (only the mask: his body is the dark of the attic)
CAM5 = [5.8, U + 5.3, 18.2]
def s_attic(i, k):
    cam = add(lerp([5.6, U + 5.4, 20.5], CAM5, ease(k)), hand(i, 0.35))
    look = lerp([6.0, U + 6.0, 13.0], [6.0, 27.0, 11.6], ease(k * 1.3))
    tgt = lerp([6.0, U + 2.0, 14.0], [6.0, 28.6, 10.8], ease(k * 1.4))
    p = lerp([6.0, 30.0, 10.2], [6.0, 29.2, 10.7], ease(k))
    cr = him([6.0, U, 0.0], 0.0, "Stare", t=3.0 + stop(i))
    cr["head"] = {"pos": p, "look": [cam[0], cam[1], cam[2]], "roll": 0.35}
    cr["noSkin"] = True
    return (dict(DARK, shot="below", cam={"pos": cam, "look": look, "fov": 60}, exposure=2.3, door=OPEN, hideIdx=only(LADDER),
                 flash=fl(cam, tgt, 11.0, 0.3), glow=0.4 + 1.4 * ease((k - 0.45) / 0.4)), cr)
shot("photo", 90, s_attic)

# 6. "mom's phone was in the kitchen." her phone face up on the island, the screen lit
def s_kphone(i, k):
    cam = add(lerp([-19.6, G + 6.3, 19.6], [-20.4, G + 5.9, 19.0], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="kitchen", cam={"pos": cam, "look": [-23.4, G + 3.4, 16.4], "fov": 42}, exposure=2.4, lamps=0, hideIdx=only(KPH)), None)
shot("setup", 60, s_kphone)

# 7. "so i texted back." my phone in my hand, the upstairs hall dark behind it
def s_reply(i, k):
    cam = add(HANDCAM, hand(i, 0.08))
    return (dict(DARK, shot="hand", cam={"pos": cam, "look": [4.6, U + 4.0, 20.0], "fov": 58}, exposure=2.4, lamps=0, door=0.0, hideIdx=only(HPH)), None)
shot("open", 60, s_reply)

# 8. "where are you?" the phone lowered: the empty hall, a slow step forward
def s_where(i, k):
    cam = add(lerp([4.4, U + 5.4, 25.0], [4.9, U + 5.4, 21.6], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [5.8, U + 4.4, 2.0], "fov": 56}, exposure=2.6, lamps=0, door=0.0,
                 flash=fl(cam, [6.0, U + 2.5, 8.0], 4.0, 0.4)), None)
shot("stood", 60, s_where)

# 9. "behind you." turn round: he's right behind me, the mask tilted... and he comes on 22.15 s (frame 64)
CAM9 = [5.2, U + 5.4, 19.0]
BEHIND = [5.0, U, 24.4]
def s_behind(i, k):
    cam = add(CAM9, hand(i, 0.3 if i < 64 else 1.0))
    t = ease((i - 12) / 26)
    y0, y1 = facing(cam, [5.8, U, 2.0]), facing(cam, BEHIND)
    yaw = y0 + wrap(y1 - y0) * t
    ly = (U + 4.6) + ((U + 8.3) - (U + 4.6)) * ease((i - 26) / 18)
    look = [cam[0] - math.sin(yaw) * 6.0, ly, cam[2] - math.cos(yaw) * 6.0]
    torch = fl(cam, [look[0], look[1] - 0.6, look[2]], 6.0, 0.4)
    if i < 64:
        return (dict(DARK, shot="hall", cam={"pos": cam, "look": look, "fov": 64}, exposure=2.6, lamps=0, door=0.0, flash=torch,
                     glow=2.2 if t > 0.5 else 0.4),
                him(BEHIND, facing(BEHIND, cam), "Stare", t=3.0 + stop(i), Duck=0.2, Look=[0.0, -0.3], Scream=0.15 * ease((i - 54) / 10)))
    w = ease((i - 64) / 4)
    near = [cam[0] + 0.1, U, cam[2] + 4.6]
    p = lerp(BEHIND, near, w)
    shake = [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0]
    return (dict(DARK, shot="hall", cam={"pos": add(cam, shake), "look": lerp(look, [p[0], U + 8.8, p[2]], w), "fov": 64 + 10 * w}, exposure=2.6,
                 lamps=0, door=0.0, glow=6.0, flash=fl(cam, [p[0], U + 7.5, p[2]], 12.0, 0.45)),
            him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Duck=1.0 * w, Look=[0.0, -0.45]))
shot("knew", 75, s_behind)

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
