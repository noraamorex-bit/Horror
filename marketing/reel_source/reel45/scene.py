# Reel 45 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #14": the chapter after #13 ("he doesn't want us to leave"), in
# #2's exact format, look, music and slot lengths. He sleeps where we hide now: the hall closet left open with a
# blanket inside, him in the bedroom doorway at night, him bent down at the bed looking under it, and tonight I hid
# in mom's closet... it was still warm in there. The v114 creature (the sculpted body with the porcelain mask); in
# the scare only his mask, in the dark at the back of the closet between the coats (skin_frames "head" + "noSkin").
#   hook (105)  the master bedroom, lamps on, cosy
#   card (120)  the same room in the moonlight, a slow push
#   72  "night 19: the hall closet was open."     the upstairs linen closet, one door open, the flashlight inside
#   33  "night 20: someone sleeps in there."      close: a blanket and a pillow on its floor
#   90  "night 21: he was in our doorway."        from the bed: the bedroom door open, him standing in it, lit from the hall
#   60  "night 22: he checks every hiding spot."  across the room: him bent down at the bed, looking under it
#   60  "so tonight i hid in mom's closet."       inside the master wardrobe: the dark room through the crack
#   60  "it was still warm in here."              the flashlight down: the same blanket, at my feet
#   75  "he sleeps where we hide."                looking out... turning round to the back of the closet: his mask (22.15 s)
#   30  "RUN."                                    across the room to the door, him crawling out of the closet after you
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau), shots.json.
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
def him(pos, yaw, gait="Stare", phase=0.0, t=0.0, **opts):
    return {"pos": {"x": pos[0], "y": pos[1], "z": pos[2]}, "yaw": yaw, "gait": gait, "phase": phase, "t": t, "seed": 4, "opts": opts}

COLD, MOON, WARM = "#3d4f7a", "#6f86c4", "#ffb766"
# --- the master bedroom (World/Interior): x -40..-8, z -30..0, floor U; the bed x -39.15..-30.15, z -18.25..-10.75
# (headboard at -x, you crawl under it from +x); the door in the x = -8 wall at z -10 (hinge z -12.43, it swings into
# the room); the wardrobe x -27.5..-20.5, z -29.15..-26.35, its doors facing +z, the two leaves meeting at x -24
# (the right one hinged at x -20.65); windows at z -30 (x -32, -16) and x -40 (z -24)
MDOOR = {"near": [-8.0, U + 4.7, -10.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, -12.43], "axis": "y"}
WLEAF = {"near": [-21.8, U + 4.5, -26.47], "r": 2.5, "names": ["WardrobeLeaf", "DoorPanel", "PanelInset"], "hinge": [-20.65, 0, -26.47], "axis": "y"}
# the upstairs linen closet: x 9.2..11.35, z -8.5..-3.5, doors facing -x; the near leaf hinged at z -3.6
HLEAF = {"near": [9.32, U + 4.5, -4.2], "r": 2.5, "names": ["WardrobeLeaf", "DoorPanel", "PanelInset"], "hinge": [9.32, 0, -3.6], "axis": "y"}
MOONLIT = [{"p": [-32, U + 8.5, -27.6], "col": MOON, "b": 3.6, "r": 24, "decay": 1.0}, {"p": [-16, U + 8.5, -27.6], "col": MOON, "b": 2.6, "r": 22, "decay": 1.0},
           {"p": [-37.6, U + 8.0, -24], "col": MOON, "b": 2.2, "r": 18}, {"p": [-20, U + 9, -6], "col": COLD, "b": 1.1, "r": 18}]
HALLGLOW = [{"p": [-3.5, U + 8, -10], "col": COLD, "b": 2.4, "r": 14, "decay": 1.2}]
INSIDE = [{"p": [-23.0, U + 7.6, -24.5], "col": MOON, "b": 0.9, "r": 8, "decay": 1.4}, {"p": [-26.0, U + 9.0, -17.0], "col": MOON, "b": 3.2, "r": 18, "decay": 1.0},
          {"p": [-22.0, U + 6.0, -14.0], "col": COLD, "b": 1.6, "r": 14}]
BEDLIGHT = [{"p": [-25.5, U + 8.5, -19.0], "col": MOON, "b": 2.6, "r": 15, "decay": 1.0}]
UHALL = [{"p": [4, U + 9, -10], "col": MOON, "b": 2.6, "r": 22, "decay": 1.0}, {"p": [2, U + 8, 2], "col": COLD, "b": 1.4, "r": 18}]
SHOTS = {
    "lit": {"center": [-24, U + 5, -15], "radius": 30, "lampRadius": 30, "maxLamps": 6},
    "dark": {"center": [-24, U + 5, -15], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT},
    "bed": {"center": [-24, U + 5, -15], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + BEDLIGHT},
    "doorway": {"center": [-22, U + 5, -12], "radius": 32, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + HALLGLOW, "door": MDOOR},
    "ward": {"center": [-24, U + 5, -22], "radius": 26, "lampRadius": 0, "maxLamps": 0, "lights": MOONLIT + INSIDE, "door": WLEAF, "hide": ["Handle"]},
    "hall": {"center": [6, U + 5, -6], "radius": 24, "lampRadius": 0, "maxLamps": 0, "lights": UHALL, "door": HLEAF, "hide": ["Handle"]},
}
DARK = {"ambient": 0.02, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1}

# --- props (film2 extras): his blanket and pillow (in the hall closet, then in the wardrobe), the wardrobe's coats
BLUE, PILLOW, RAIL = [52, 60, 84], [150, 146, 136], [150, 150, 154]
extras = []
def ex(group, e):
    group.append(len(extras)); extras.append(e)
HNEST, WNEST, COATS = [], [], []
def nest(group, x, z, yaw):
    c, s = math.cos(yaw), math.sin(yaw)
    def at(dx, dz): return [x + dx * c - dz * s, z + dx * s + dz * c]
    for (dx, dz, w, d, h, a) in [(0.0, 0.0, 1.8, 1.5, 0.22, 0.2), (0.35, -0.25, 1.1, 0.9, 0.4, -0.5), (-0.4, 0.3, 0.9, 0.8, 0.32, 0.9)]:
        p = at(dx, dz)
        ex(group, {"pos": [p[0], U + 0.6 + h / 2, p[1]], "s": [w, h, d], "rot": [0.08, yaw + a, 0.05], "col": BLUE, "rough": 0.95})
    p = at(-0.55, -0.45)
    ex(group, {"pos": [p[0], U + 0.85, p[1]], "s": [0.9, 0.35, 0.6], "rot": [0, yaw + 0.3, 0.1], "col": PILLOW, "rough": 0.9})
nest(HNEST, 10.3, -6.0, 0.0)
nest(WNEST, -24.6, -27.8, 1.57)
ex(COATS, {"pos": [-24.0, U + 7.35, -27.75], "s": [6.2, 0.1, 0.1], "col": RAIL, "rough": 0.3})
for (x, w, h, col) in [(-27.0, 0.3, 4.4, [28, 28, 32]), (-26.75, 0.3, 4.0, [46, 38, 34]), (-21.6, 0.5, 4.2, [36, 40, 46]), (-21.1, 0.4, 3.8, [30, 30, 30])]:
    ex(COATS, {"pos": [x, U + 7.3 - h / 2, -27.8], "s": [w, h, 1.5], "col": col, "rough": 0.95})
ALL = set(range(len(extras)))
def only(*groups):
    keep = set().union(*[set(g) for g in groups]) if groups else set()
    return sorted(ALL - keep)

frames, crs, shots = [], [], []
f = 0
def shot(name, n, fn):
    global f
    shots.append({"name": name, "start": f, "n": n})
    dense = dict((d_.split(":")[0], d_.split(":")[1:]) for d_ in os.environ.get("DENSE", "").split(",") if d_)
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
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}

# 1. (hook) the master bedroom, lamps on: cosy
def s_hook(i, k):
    cam = add(lerp([-11.5, U + 6.4, -6.5], [-12.6, U + 6.2, -8.0], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([-26.0, U + 3.6, -19.0], [-25.5, U + 3.5, -20.0], ease(k)), "fov": 60}, hideIdx=only()), None)
shot("hook", 105, s_hook)

# 2. (card) the same room in the moonlight, a slow push
def s_card(i, k):
    cam = add(lerp([-11.0, U + 6.6, -6.0], [-13.4, U + 6.2, -8.6], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="dark", cam={"pos": cam, "look": [-25.5, U + 3.6, -20.0], "fov": 60}, exposure=3.0, lamps=0, hideIdx=only()), None)
shot("card", 120, s_card)

# 3. "night 19: the hall closet was open." the upstairs linen closet, one door open, the flashlight into it
def s_hall(i, k):
    cam = add(lerp([-0.5, U + 5.8, -6.6], [1.4, U + 5.6, -6.3], ease(k)), hand(i, 0.5))
    tgt = lerp([8.6, U + 5.6, -4.0], [10.3, U + 1.2, -6.0], ease((i - 10) / 40))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": lerp([9.6, U + 4.2, -5.6], [10.0, U + 3.2, -6.0], ease(k)), "fov": 52}, exposure=2.3, lamps=0,
                 door=1.35, hideIdx=only(HNEST), flash=fl(cam, tgt, 4.5, 0.42)), None)
shot("open", 72, s_hall)

# 4. "night 20: someone sleeps in there." close: the blanket and the pillow on its floor
def s_nest(i, k):
    cam = add(lerp([6.6, U + 4.6, -6.0], [6.9, U + 4.4, -6.0], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [10.3, U + 0.8, -6.0], "fov": 50}, exposure=2.6, lamps=0, door=1.35, hideIdx=only(HNEST),
                 flash=fl(cam, [10.3, U + 0.8, -6.0], 4.0, 0.42)), None)
shot("nest", 33, s_nest)

# 5. "night 21: he was in our doorway." from the bed (lying down), the bedroom door open, him standing in it
DOORWAY = [-9.4, U, -10.2]
def s_doorway(i, k):
    cam = add([-36.4, U + 3.9, -14.0], hand(i, 0.25))
    look = lerp([-8.5, U + 5.2, -10.5], [-8.8, U + 6.0, -10.3], ease(k))
    return (dict(DARK, shot="doorway", cam={"pos": cam, "look": look, "fov": 44}, exposure=3.0, lamps=0, door=1.3, glow=2.4, hideIdx=only()),
            him(DOORWAY, facing(DOORWAY, cam), "Stare", t=2.0 + i / FPS, Duck=0.7, Look=[0.0, -0.1]))
shot("doorway", 90, s_doorway)

# 6. "night 22: he checks every hiding spot." across the room: him bent down at the bed, looking under it
BEDSIDE = [-28.3, U, -14.2]
def s_check(i, k):
    cam = add(lerp([-18.6, U + 5.4, -21.6], [-19.2, U + 5.3, -21.0], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="bed", cam={"pos": cam, "look": [-29.0, U + 3.2, -14.4], "fov": 52}, exposure=3.2, lamps=0, glow=3.2, hideIdx=only()),
            him(BEDSIDE, facing(BEDSIDE, [-34.0, U, -14.5]), "Stare", t=5.0 + i / FPS, Duck=1.6, Look=[0.0, -0.7]))
shot("check", 60, s_check)

# 7. "so tonight i hid in mom's closet." inside the wardrobe: the dark room through the crack
EYE_IN = [-23.5, U + 4.9, -27.35]
OUT = [-23.4, U + 4.3, -16.0]
CRACK = 0.5
def ward(i, look, extra=None, door=CRACK):
    cam = [EYE_IN[0], EYE_IN[1] + 0.03 * math.sin(i * 0.31), EYE_IN[2]]
    fr = dict(DARK, shot="ward", cam={"pos": cam, "look": look, "fov": 62}, exposure=3.2, lamps=0, glow=1.0, door=door, hideIdx=only(WNEST, COATS))
    if extra: fr.update(extra)
    return fr
def s_hide(i, k):
    return (ward(i, lerp(OUT, [-24.0, U + 4.2, -16.0], ease(k))), None)
shot("hide", 60, s_hide)

# 8. "it was still warm in here." the flashlight down: the same blanket, at my feet
def s_warm(i, k):
    look = lerp([-24.4, U + 0.9, -27.2], [-24.8, U + 0.7, -27.7], ease(k))
    cam = add(EYE_IN, hand(i, 0.9))
    return (ward(i, look, {"cam": {"pos": cam, "look": look, "fov": 60}, "flash": fl(cam, look, 8.0, 0.4)}), None)
shot("warm", 60, s_warm)

# 9. "he sleeps where we hide." looking out through the crack... turning round to the back of the closet: between
# the coats, his mask. Still... then on 22.15 s (frame 64) he comes at you, jaw dropping (only the mask: the body is
# the dark behind the coats)
FACE0 = [-26.25, U + 5.3, -27.85]
def s_scare(i, k):
    cam = add(EYE_IN, hand(i, 0.3 if i < 40 else 0.7))
    a0, a1 = facing(cam, OUT), facing(cam, [-27.0, U, -28.0])
    yaw = a0 + wrap(a1 - a0) * ease((i - 24) / 24)
    ly = lerp([U + 4.4], [U + 5.4], ease((i - 30) / 18))[0]
    look = [cam[0] - math.sin(yaw) * 3.0, ly, cam[2] - math.cos(yaw) * 3.0]
    torch = None if i < 50 else fl(cam, look, 4.5 * ease((i - 50) / 3), 0.42)
    if i < 64:
        extra = {"cam": {"pos": cam, "look": look, "fov": 66}, "glow": 0.6 + 1.4 * ease((i - 50) / 10)}
        if torch: extra["flash"] = torch
        cr = him([-26.0, U, -28.4], 0.0, "Stare", t=3.0 + i / FPS, Scream=0.15 * ease((i - 56) / 8))
        cr["head"] = {"pos": FACE0, "look": [cam[0], cam[1] + 0.2, cam[2]], "roll": 0.2}
        cr["noSkin"] = True
        return (ward(i, look, extra), cr if i >= 34 else None)
    w = ease((i - 64) / 4)
    p = lerp(FACE0, [-24.2, U + 5.0, -27.5], w)
    extra = {"cam": {"pos": cam, "look": lerp(look, p, 0.6), "fov": 66 + 6 * w}, "glow": 4.0, "flash": fl(cam, p, 9.0, 0.5)}
    cr = him([-26.0, U, -28.4], 0.0, "Reach", t=3.0 + i / FPS, Scream=1.0)
    cr["head"] = {"pos": p, "look": [cam[0], cam[1] + 0.1, cam[2]], "roll": 0.2 * (1 - w)}
    cr["noSkin"] = True
    return (ward(i, look, extra), cr)
shot("scare", 75, s_scare)

# 10. RUN: out of the closet and across the room to the door, looking back: he crawls out after you on all fours
def s_run(i, k):
    cam = [-21.5 + 8.0 * k + 0.25 * math.sin(i * 1.7), U + 5.0 + 0.2 * math.sin(i * 2.3), -22.0 + 8.0 * k]
    hp = lerp([-23.6, U, -26.0], [-20.8, U, -20.6], k)
    return (dict(DARK, shot="ward", cam={"pos": cam, "look": [hp[0], U + 2.6, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)}, door=1.6,
                 flash=fl(cam, [hp[0] + 0.8 * math.sin(i * 1.3), U + 3.0, hp[2]], 16.0, 0.36), ambient=0.01, exposure=2.0, glow=6, hideIdx=only(COATS)),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
