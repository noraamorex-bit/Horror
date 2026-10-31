# Reel 57 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #10" (31 Oct; #7, mom's texts, at 115K: quoted texts with a twist win).
# #2's exact format, look, music and slot lengths; the mom thread again: "don't open the door." ... someone knocked ... "honey,
# open the door." But mom has a key. So I looked through the peephole: nobody. "i'm not outside, sweetie." He wears the porcelain
# mask, as in the game, and shows himself once before the scare (on the front lawn, looking up at mom's window).
#   hook (105)  the front hall, the lamps on, cosy
#   card (120)  the same hall in the dark, a slow push to the front door
#   72  "night 39: mom texted "don't open the door.""  in bed: the phone by the pillow lights up
#   33  "night 40: someone knocked."                     from the stairs: the front door rattling in its frame
#   90  "night 41: "honey, open the door.""              from mom's window, lightning: him on the front lawn, looking up
#   60  "mom has a key."                                 close on the front door's knob, the porch light at its edge
#   60  "so i looked through the peephole."              walking up to the door, to the little brass peephole
#   60  "nobody was there."                              the peephole: the empty porch in the rain (comp fr.peep)
#   75  ""i'm not outside, sweetie.""                    turn round from the door: him in the hall behind me (22.15 s)
#   30  "RUN."                                           out the front door onto the porch, him after me
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
# --- the front of the house (reel 53): the front door at x 2 in the z = -30 wall (x -0.4..4.4, hinged at x -0.43, it swings in);
# the porch deck x -5..9, z -38..-30.6 (top y 1.0); the porch lamp at (-1.2, 8, -31.3). The front hall inside: x -8..12,
# z -30..-0.4, floor G; the stairs at x -5 climb from z -5.3 to the landing at z 17.
FDOOR = {"near": [2.0, 5.7, -30.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-0.43, 0, -30.0], "axis": "y"}
PORCHLAMP = {"p": [-1.2, 7.3, -31.5], "col": WARM, "b": 1.6, "r": 14, "decay": 1.3}
OUTSIDE = [PORCHLAMP, {"p": [2, 30, -60], "col": MOON, "b": 2.0, "r": 70, "decay": 0.8}, {"p": [12, 6, -50], "col": COLD, "b": 1.0, "r": 24}]
INSIDE = [{"p": [2, G + 9, -20], "col": COLD, "b": 1.0, "r": 18}, {"p": [2, G + 6, -34], "col": MOON, "b": 2.2, "r": 18, "decay": 1.1},
          {"p": [-5, U + 6, 10], "col": "#2c3d6e", "b": 1.0, "r": 22}]
def sy(z): return max(G, min(U, 2.05 + 0.625 * (z + 5.3) - 1.0))
NOCANDY = ["CandyWrap", "CandyBody"]
def glowAt(p, b=1.4, r=5.0): return {"p": [p[0], p[1] + 0.7, p[2]], "col": SCREEN, "b": b, "r": r, "decay": 1.6}
# --- Jamie's room (reel 56): the bed's pillows at x -38.1; the phone by the pillow
JDOOR = {"near": [-8.0, U + 4.7, 24.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, 21.57], "axis": "y"}
MOONLIT = [{"p": [-24, U + 8.5, 28.6], "col": MOON, "b": 3.4, "r": 24, "decay": 1.0}, {"p": [-38.5, U + 8, 12], "col": MOON, "b": 2.2, "r": 18},
           {"p": [-14, U + 8, 14], "col": COLD, "b": 1.2, "r": 16}]
BEDPHONE = [-36.6, U + 3.86, 15.2]
# --- mom's room (the master bedroom, reel 26): its front windows in the z = -30 wall; him out on the front lawn
LAWN = [-25.0, 0.5, -47.0]
MOMWIN = [-31.6, U + EYE + 0.3, -29.1]
PEEP = [2.0, G + 5.5, -30.0]                  # the peephole, in the door at eye height
SHOTS = {
    "lit": {"center": [2, G + 5, -16], "radius": 30, "lampRadius": 30, "maxLamps": 8, "door": FDOOR},
    "hallDark": {"center": [2, G + 5, -16], "radius": 32, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": INSIDE},
    "hallGap": {"center": [0, G + 6, -14], "radius": 40, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": INSIDE + [PORCHLAMP]},
    "porch": {"center": [2, G + 4, -42], "radius": 40, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": OUTSIDE},
    "openDoor": {"center": [0, G + 6, -14], "radius": 40, "lampRadius": 0, "maxLamps": 0, "door": FDOOR, "lights": INSIDE + OUTSIDE},
    "bedPhone": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + [glowAt(BEDPHONE, 0.8, 4)], "door": JDOOR},
    "bedDark": {"center": [-26, U + 5, 20], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT, "door": JDOOR},
    "window": {"center": [-28, U, -38], "radius": 140, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [-26, U + 12, -55], "col": MOON, "b": 1.6, "r": 40, "decay": 1.0},
                          {"p": [-30, U + 8, -24], "col": COLD, "b": 1.0, "r": 12}]},
}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}
OPENDOOR = 1.45
NIGHTFOG = {"fog": [30, 90], "bg": 0x0b0d12}

# --- props (film2 extras): the phone by my pillow (dark / lit with mom's text), the door's brass peephole
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
BED_OFF, BED_ON, PEEPHOLE = [], [], []
BODY = [18, 18, 20]
def phone(group, p, rot, lit):
    th = rot[0]
    n = [0.0, math.cos(th), math.sin(th)]
    zl = [0.0, -math.sin(th), math.cos(th)]
    def at(dx, dz, h): return [p[0] + dx + n[0] * h + zl[0] * dz, p[1] + n[1] * h + zl[1] * dz, p[2] + n[2] * h + zl[2] * dz]
    ex(group, {"pos": p, "s": [0.25, 0.03, 0.47], "rot": rot, "col": BODY, "rough": 0.3})
    if lit:
        ex(group, {"pos": at(0, 0, 0.017), "s": [0.22, 0.004, 0.42], "rot": rot, "col": [30, 44, 78], "emissive": [40, 62, 120], "ei": 0.55, "rough": 0.2})
        # (mom's text: one long grey bubble)
        ex(group, {"pos": at(-0.02, -0.1, 0.021), "s": [0.16, 0.003, 0.06], "rot": rot, "col": [200, 204, 214], "emissive": [190, 196, 210], "ei": 0.7})
    else:
        ex(group, {"pos": at(0, 0, 0.017), "s": [0.22, 0.004, 0.42], "rot": rot, "col": [8, 8, 10], "rough": 0.15})
phone(BED_OFF, BEDPHONE, [0.0, 0.0, 0.0], False)
phone(BED_ON, BEDPHONE, [0.0, 0.0, 0.0], True)
# the peephole: a brass ring on the inside face of the door with a dark lens in it (the door's inside face is at z ~-29.8)
ex(PEEPHOLE, {"shape": "cyl", "pos": [PEEP[0], PEEP[1], -29.8], "s": [0.2, 0.08, 0.2], "rot": [math.pi / 2, 0.0, 0.0], "col": [176, 140, 70], "rough": 0.3})
ex(PEEPHOLE, {"shape": "cyl", "pos": [PEEP[0], PEEP[1], -29.76], "s": [0.09, 0.02, 0.09], "rot": [math.pi / 2, 0.0, 0.0], "col": [30, 26, 22], "emissive": [70, 56, 34], "ei": 0.4})
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
def knock(i, at, amt=0.035):
    # the door jumping in its frame: three quick knocks every ~second
    p = (i - at) % 30
    return amt if (p in (0, 1, 5, 6, 10, 11) and i >= at) else 0.0

# 1. (hook) the front hall, lamps on: cosy
def s_hook(i, k):
    cam = add(lerp([6.5, G + 5.8, -6.0], [5.5, G + 5.6, -9.0], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([1.0, G + 4.2, -30.0], [1.6, G + 4.2, -30.0], ease(k)), "fov": 60}, door=0.0), None)
shot("hook", 105, s_hook)

# 2. (card) the same hall in the dark, a slow push to the front door
def s_card(i, k):
    cam = add(lerp([6.0, G + 5.8, -6.5], [4.4, G + 5.5, -13.0], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="hallDark", cam={"pos": cam, "look": [2.0, G + 4.2, -30.0], "fov": 58}, exposure=3.2, lamps=0, door=0.0), None)
shot("card", 120, s_card)

# 3. "night 39: mom texted "don't open the door."" in bed, the phone by the pillow lights up in the dark
def s_text(i, k):
    cam = add([-38.6, U + 5.3, 13.0], hand(i, 0.2))
    on = i >= 14
    return (dict(DARK, shot="bedPhone" if on else "bedDark", cam={"pos": cam, "look": [-36.6, U + 3.8, 15.1], "fov": 40}, exposure=1.3, lamps=0,
                 door=0.0, hideIdx=only(BED_ON if on else BED_OFF)), None)
shot("door", 72, s_text)

# 4. "night 40: someone knocked." from the stairs: the front door jumping in its frame, the porch light at its edge
def s_knock(i, k):
    cam = add(lerp([-4.8, sy(4.0) + 5.4, 4.0], [-4.8, sy(2.5) + 5.4, 2.5], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="hallGap", cam={"pos": cam, "look": [1.8, G + 4.4, -30.0], "fov": 46}, exposure=2.8, lamps=0, door=knock(i, 4),
                 flash=fl(cam, [1.8, G + 3.4, -28.0], 3.0, 0.3)), None)
shot("prints", 33, s_knock)

# 5. "night 41: "honey, open the door."" from mom's window, lightning: him on the front lawn, looking up at me
def s_lawn(i, k):
    cam = add(lerp(MOMWIN, add(MOMWIN, [0.0, 0.0, 0.25]), ease(k)), hand(i, 0.3))
    strike = 1.0 if (16 <= i < 19 or 22 <= i < 24 or 58 <= i < 60) else 0.0
    return (dict(DARK, shot="window", cam={"pos": cam, "look": [-25.2, 5.2, -47.0], "fov": 30 - 3 * ease(k)}, exposure=2.6, lamps=0, glow=1.6,
                 bg=0x0d1424 if strike else 0x010102,
                 flash={"i": 40.0 * strike + 6.0, "pos": [-26.0, 30.0, -38.0], "target": LAWN, "angle": 0.6}),
            him(LAWN, facing(LAWN, cam), "Stare", t=2.0 + stop(i), Look=[0.0, 0.45 + 0.1 * ease((i - 40) / 30)]))
shot("photo", 90, s_lawn)

# 6. "mom has a key." close on the front door's knob, the porch light at the door's edge; it turns, slowly
def s_key(i, k):
    cam = add(lerp([2.6, G + 4.5, -26.4], [2.9, G + 4.3, -27.2], ease(k)), hand(i, 0.15))
    return (dict(DARK, shot="hallGap", cam={"pos": cam, "look": [3.7, G + 3.4, -30.0], "fov": 40}, exposure=3.0, lamps=0,
                 door=0.012 * ease((i - 20) / 10) * (1 if i < 48 else 0), flash=fl(cam, [3.7, G + 3.4, -30.0], 2.4, 0.3)), None)
shot("setup", 60, s_key)

# 7. "so i looked through the peephole." walking up to the door, to the little brass peephole at eye height
def s_walk(i, k):
    cam = add(lerp([2.2, G + 5.4, -23.5], [2.0, G + 5.5, -28.1], ease(k)), hand(i, 0.3 * (1 - k)))
    return (dict(DARK, shot="hallGap", cam={"pos": cam, "look": [PEEP[0], PEEP[1] - 0.2 * (1 - k), -30.0], "fov": 52 - 8 * ease(k)}, exposure=2.8,
                 lamps=0, door=0.0, flash=fl(cam, [PEEP[0], PEEP[1] - 0.6, -30.0], 3.0, 0.3), hideIdx=only(PEEPHOLE)), None)
shot("open", 60, s_walk)

# 8. "nobody was there." the peephole's fisheye: the porch, the lamp, the rain, nobody
def s_peep(i, k):
    cam = add([PEEP[0], PEEP[1], -30.45], hand(i, 0.04))
    return (dict(DARK, shot="porch", cam={"pos": cam, "look": [2.0, G + 3.2, -42.0], "fov": 118}, exposure=4.2, lamps=0, door=0.0,
                 glow=0.0, **NIGHTFOG), None)
shot("stood", 60, s_peep)

# 9. ""i'm not outside, sweetie."" at the door, turn round: he's in the hall behind me... and he comes on 22.15 s (frame 64)
CAM9 = [2.1, G + 5.4, -27.6]
BEHIND = [1.8, G, -21.8]
def s_behind(i, k):
    cam = add(CAM9, hand(i, 0.3 if i < 64 else 1.0))
    t = ease((i - 12) / 26)
    y0, y1 = facing(cam, [2.0, G, -40.0]), facing(cam, BEHIND)
    yaw = y0 + wrap(y1 - y0) * t
    ly = (G + 4.6) + ((G + 8.3) - (G + 4.6)) * ease((i - 26) / 18)
    look = [cam[0] - math.sin(yaw) * 6.0, ly, cam[2] - math.cos(yaw) * 6.0]
    torch = fl(cam, [look[0], look[1] - 0.6, look[2]], 1.5 + 4.5 * t, 0.4)
    if i < 64:
        return (dict(DARK, shot="hallDark", cam={"pos": cam, "look": look, "fov": 64}, exposure=2.6, lamps=0, door=0.0, flash=torch,
                     glow=2.2 if t > 0.5 else 0.4, hideIdx=only(PEEPHOLE)),
                him(BEHIND, facing(BEHIND, cam), "Stare", t=3.0 + stop(i), Duck=0.2, Look=[0.0, -0.3], Scream=0.15 * ease((i - 54) / 10)))
    w = ease((i - 64) / 4)
    near = [cam[0] - 0.1, G, cam[2] + 4.6]
    p = lerp(BEHIND, near, w)
    shake = [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0]
    return (dict(DARK, shot="hallDark", cam={"pos": add(cam, shake), "look": lerp(look, [p[0], G + 8.8, p[2]], w), "fov": 64 + 10 * w}, exposure=2.6,
                 lamps=0, door=0.0, glow=6.0, flash=fl(cam, [p[0], G + 7.5, p[2]], 12.0, 0.45), hideIdx=only(PEEPHOLE)),
            him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Duck=1.0 * w, Look=[0.0, -0.45]))
shot("knew", 75, s_behind)

# 10. RUN: out the front door onto the porch, looking back: he comes through the door after me
def s_run(i, k):
    cam = [2.0 + 0.25 * math.sin(i * 1.7), 1.0 + 4.8 + 0.2 * math.sin(i * 2.3), -32.5 - 6.0 * k]
    hp = lerp([2.0, G, -22.0], [2.0, 1.0, -30.5], k)
    return (dict(DARK, shot="openDoor", cam={"pos": cam, "look": [hp[0], G + 3.0, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 door=OPENDOOR, flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), G + 3.2, hp[2]], 16.0, 0.36), ambient=0.01, exposure=2.0, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
