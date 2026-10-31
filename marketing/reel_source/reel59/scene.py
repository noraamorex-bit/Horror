# Reel 59 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #12" (31 Oct; #7, mom's texts, 115K: everyday things with a quoted twist
# win). #2's exact format, look, music and slot lengths; a new everyday hook: the smart speaker on my nightstand. It turns on at
# 3 am; "goodnight, jamie."; "playing lily's lullaby." So I asked it who was home: "three people are home." Mom's at work (#9: she
# works nights): it's me and Lily. "the third one is behind you." He wears the porcelain mask, as in the game, and shows himself
# twice before the scare (#7's dose): in my doorway, and bent over Lily's bed.
#   hook (105)  my room (Jamie's), the lamps on, cosy
#   card (120)  the same room in the moonlight, a slow push to the bed
#   72  "night 45: our speaker turned on at 3 am."   in bed: the speaker on my nightstand lights up
#   33  "night 46: "goodnight, jamie.""              from my pillow: him in my doorway
#   90  "night 47: "playing lily's lullaby.""         Lily's room: him bent over her bed in the moonlight
#   60  "so i asked who was home."                    close on the speaker, its ring listening
#   60  ""three people are home.""                    its ring pulsing as it answers
#   60  "mom's at work."                              her room: the bed made, nobody in it
#   75  ""the third one is behind you.""              in my room at the speaker... turn round: him right there (22.15 s)
#   30  "RUN."                                        down the hall, him after me on all fours
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau + mask.json), shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.6
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

COLD, MOON, PINK, WARM, CYAN = "#3d4f7a", "#6f86c4", "#ff9fc4", "#ffd9a0", "#5ac8ff"
NOCANDY = ["CandyWrap", "CandyBody"]
NOLAPTOP = ["LaptopScreen", "LaptopLid", "Trackpad", "LaptopKeys", "LaptopBase"]
# --- my room (Jamie's; reels 47/56/58): x -40..-8, z 10..30; the bed x -39.15..-31.35, z 13.3..18.3 (pillows at x -38.1,
# mattress top ~U + 3.8); the nightstand beside its head at (-38.1, 20.4), top at U + 2.46; the door in the x = -8 wall at z 24
JDOOR = {"near": [-8.0, U + 4.7, 24.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, 21.57], "axis": "y"}
MOONLIT = [{"p": [-24, U + 8.5, 28.6], "col": MOON, "b": 3.4, "r": 24, "decay": 1.0}, {"p": [-38.5, U + 8, 12], "col": MOON, "b": 2.2, "r": 18},
           {"p": [-14, U + 8, 14], "col": COLD, "b": 1.2, "r": 16}]
SPK = [-38.1, U + 2.46, 20.4]                # the smart speaker, on the nightstand (the laptop hidden)
SPKTOP = [SPK[0], SPK[1] + 0.8, SPK[2]]
SPKGLOW = {"p": [SPK[0] + 0.2, SPK[1] + 1.1, SPK[2]], "col": CYAN, "b": 1.0, "r": 6, "decay": 1.5}
# --- Lily's room (reel 51)
LILYDOOR = {"near": [12.0, U + 4.7, 20.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [12.0, 0, 17.55], "axis": "y"}
ROOM = [{"p": [13.6, U + 2.2, 27.5], "col": PINK, "b": 1.6, "r": 16, "decay": 1.3},
        {"p": [26.0, U + 8.0, 31.5], "col": MOON, "b": 3.4, "r": 24, "decay": 1.1},
        {"p": [30.0, U + 8.0, 12.0], "col": COLD, "b": 1.2, "r": 16}]
# --- mom's room (reel 56)
MDOOR = {"near": [-8.0, U + 4.7, -10.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, -12.43], "axis": "y"}
MROOM = [{"p": [-32, U + 8.5, -27.6], "col": MOON, "b": 3.4, "r": 24, "decay": 1.0}, {"p": [-32, U + 9.0, -11.0], "col": MOON, "b": 3.2, "r": 14, "decay": 1.0},
         {"p": [-12, U + 7, -14], "col": COLD, "b": 1.4, "r": 14}]
# --- the upstairs hall (reel 56's RUN)
HATCH = {"near": [6.0, 28.0, 11.0], "r": 4.5, "names": ["HatchPanel"], "hinge": [6.0, 28.15, 8.05], "axis": "x"}
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [4, U + 8, 4], "col": COLD, "b": 1.2, "r": 16}]
SHOTS = {
    "lit": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 30, "maxLamps": 8, "door": JDOOR, "hide": NOLAPTOP},
    "dark": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT, "door": JDOOR, "hide": NOLAPTOP},
    "spk": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + [SPKGLOW], "door": JDOOR, "hide": NOLAPTOP},
    "lily": {"center": [26, U + 5, 19], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR, "hide": ["Bulb", "Globe", "Base", "Finial"],
             "lights": ROOM + [{"p": [6, U + 8, 18], "col": COLD, "b": 1.6, "r": 16}]},
    "mom": {"center": [-26, U + 5, -16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": MDOOR, "lights": MROOM},
    "hall": {"center": [4, U + 6, 16], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "lights": HALL},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}

# --- props (film2 extras): the smart speaker, dark / lit / its ring dimmed (it pulses while it talks)
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
SPK_OFF, SPK_ON, SPK_DIM = [], [], []
def speaker(group, ring):
    # a fabric-covered cylinder (~0.5 x 0.75 studs) with a light ring round its top
    ex(group, {"shape": "cyl", "pos": [SPK[0], SPK[1] + 0.375, SPK[2]], "s": [0.5, 0.75, 0.5], "col": [128, 130, 138], "emissive": [70, 74, 84], "ei": 0.35, "rough": 0.95})
    ex(group, {"shape": "cyl", "pos": [SPK[0], SPK[1] + 0.77, SPK[2]], "s": [0.47, 0.04, 0.47], "col": [24, 25, 28], "rough": 0.4})
    if ring:
        ex(group, {"shape": "cyl", "pos": [SPK[0], SPK[1] + 0.755, SPK[2]], "s": [0.53, 0.035, 0.53], "col": [60, 190, 255],
                   "emissive": [60, 190, 255], "ei": ring})
    else:
        ex(group, {"shape": "cyl", "pos": [SPK[0], SPK[1] + 0.755, SPK[2]], "s": [0.52, 0.03, 0.52], "col": [30, 32, 36], "rough": 0.4})
speaker(SPK_OFF, 0)
speaker(SPK_ON, 1.4)
speaker(SPK_DIM, 0.45)
ALL = set(range(len(extras)))
def only(*groups):
    keep = set().union(*[set(g) for g in groups]) if groups else set()
    return sorted(ALL - keep)
def pulse(i, rate=0.45):
    # talking: the ring breathes bright and dim
    return SPK_ON if math.sin(i * rate) > -0.2 else SPK_DIM

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
        fr.setdefault("hideIdx", only(SPK_OFF))
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}

# 1. (hook) my room, lamps on: cosy
def s_hook(i, k):
    cam = add(lerp([-12.5, U + 6.2, 21.0], [-14.0, U + 6.0, 20.6], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([-34.0, U + 3.4, 18.0], [-34.5, U + 3.3, 18.4], ease(k)), "fov": 60}, door=0.0), None)
shot("hook", 105, s_hook)

# 2. (card) the same room in the moonlight, a slow push to the bed
def s_card(i, k):
    cam = add(lerp([-12.0, U + 6.4, 21.5], [-16.0, U + 6.0, 20.2], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="dark", cam={"pos": cam, "look": [-35.0, U + 3.2, 17.6], "fov": 60}, exposure=3.6, lamps=0, door=0.0), None)
shot("card", 120, s_card)

# 3. "night 45: our speaker turned on at 3 am." in bed: the speaker on my nightstand lights up in the dark
PILLOW = [-38.0, U + 4.7, 16.2]
def s_on(i, k):
    cam = add(PILLOW, hand(i, 0.2))
    on = i >= 14
    return (dict(DARK, shot="spk" if on else "dark", cam={"pos": cam, "look": [SPK[0], SPK[1] + 0.5, SPK[2]], "fov": 44}, exposure=2.8, lamps=0,
                 door=0.0, hideIdx=only(pulse(i) if on else SPK_OFF)), None)
shot("door", 72, s_on)

# 4. "night 46: "goodnight, jamie."" from my pillow: him in my doorway, the hall's dark behind him
DOORWAY = [-9.4, U, 24.0]
def s_night(i, k):
    cam = add([PILLOW[0], PILLOW[1] + 0.2, PILLOW[2] + 0.4], hand(i, 0.2))
    return (dict(DARK, shot="spk", cam={"pos": cam, "look": [DOORWAY[0], U + 5.6, DOORWAY[2]], "fov": 34}, exposure=2.8, lamps=0, door=1.6, glow=2.2,
                 hideIdx=only(SPK_ON)),
            him(DOORWAY, facing(DOORWAY, cam), "Stare", t=3.0 + stop(i), Duck=0.55, Look=[0.0, -0.15]))
shot("prints", 33, s_night)

# 5. "night 47: "playing lily's lullaby."" Lily's room: him bent over the foot of her bed in the moonlight (reel 51's shot)
BEDFOOT = [35.2, U, 20.4]
def s_lily(i, k):
    cam = add(lerp([31.0, U + 4.6, 28.0], [31.3, U + 4.5, 27.3], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="lily", cam={"pos": cam, "look": [35.6, U + 7.0, 20.6], "fov": 60}, exposure=2.6, glow=2.0, door=0.0),
            him(BEDFOOT, facing(BEDFOOT, [35.2, U, 26.0]), "Stare", t=2.0 + stop(i), Duck=0.85, Look=[0.0, -0.45 + 0.35 * ease((i - 50) / 30)]))
shot("photo", 90, s_lily)

# 6. "so i asked who was home." close on the speaker, its ring lit, listening
def s_ask(i, k):
    cam = add(lerp([-35.6, U + 4.6, 21.4], [-36.2, U + 4.4, 21.1], ease(k)), hand(i, 0.2))
    return (dict(DARK, shot="spk", cam={"pos": cam, "look": [SPK[0], SPK[1] + 0.5, SPK[2]], "fov": 40}, exposure=2.8, lamps=0, door=0.0,
                 hideIdx=only(SPK_ON)), None)
shot("setup", 60, s_ask)

# 7. ""three people are home."" its ring pulsing as it answers, a slow push in
def s_answer(i, k):
    cam = add(lerp([-36.0, U + 4.3, 21.2], [-36.5, U + 4.1, 21.0], ease(k)), hand(i, 0.15))
    return (dict(DARK, shot="spk", cam={"pos": cam, "look": [SPK[0], SPK[1] + 0.5, SPK[2]], "fov": 40}, exposure=2.8, lamps=0, door=0.0,
                 hideIdx=only(pulse(i))), None)
shot("open", 60, s_answer)

# 8. "mom's at work." her room from the door: the bed made, nobody in it
def s_mom(i, k):
    cam = add(lerp([-9.5, U + 5.6, -11.5], [-12.5, U + 5.4, -12.5], ease(k)), hand(i, 0.3))
    return (dict(DARK, shot="mom", cam={"pos": cam, "look": [-34.0, U + 2.6, -14.5], "fov": 52}, exposure=2.8, lamps=0, door=1.6), None)
shot("stood", 60, s_mom)

# 9. ""the third one is behind you."" standing at the speaker in my room, its ring pulsing... turn round: him right behind me;
# the mask comes at me on 22.15 s (frame 64)
STAND = [-34.8, U + 5.4, 21.6]
BEHIND = [-28.6, U, 23.0]
def s_knew(i, k):
    cam = add(STAND, hand(i, 0.3 if i < 64 else 1.0))
    spk = [SPK[0], SPK[1] + 0.5, SPK[2]]
    t = ease((i - 22) / 20)
    y0, y1 = facing(cam, spk), facing(cam, BEHIND)
    yaw = y0 + wrap(y1 - y0) * t
    ly = spk[1] + ((U + 7.9) - spk[1]) * ease((i - 28) / 20)
    dist = 3.4 + 3.0 * t
    look = [cam[0] - math.sin(yaw) * dist, ly, cam[2] - math.cos(yaw) * dist]
    ring = only(pulse(i)) if i < 40 else only(SPK_ON)
    if i < 64:
        return (dict(DARK, shot="spk", cam={"pos": cam, "look": look, "fov": 58}, exposure=2.6, lamps=0, door=0.0, glow=2.4 if t > 0.5 else 0.8,
                     flash=fl(cam, look, 5.0 * t, 0.4), hideIdx=ring),
                him(BEHIND, facing(BEHIND, cam), "Stare", t=3.0 + stop(i), Duck=0.6, Look=[0.0, -0.3], Scream=0.15 * ease((i - 54) / 10)))
    w = ease((i - 64) / 5)
    near = [cam[0] + 5.2, U, cam[2] + 0.6]
    p = lerp(BEHIND, near, w)
    shake = [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0]
    return (dict(DARK, shot="spk", cam={"pos": add(cam, shake), "look": lerp(look, [p[0], U + 7.6, p[2]], w), "fov": 58 + 10 * w}, exposure=2.6,
                 lamps=0, door=0.0, glow=6.0, flash=fl(cam, [p[0], U + 7.5, p[2]], 12.0, 0.45), hideIdx=ring),
            him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Duck=1.0 * w, Look=[0.0, -0.45]))
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
