# Reel 43 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #12": the next chapter after #11 ("he isn't up there
# anymore"), in #2's exact format, look, music and slot lengths (#2: 314K views, 26K sends). He's out of the
# attic and living in the house with you now: the v112 creature (the real skinned mesh, posed by the game's own
# SkinPose: tools/creature/skin_frames.luau), never seen in a reel before. No HUD, no friends on screen.
#   hook (105)  the living room, lamps on, cosy
#   card (120)  the same room in the dark, a slow push past the sofa to the dead TV
#   72  "night 10: the tv turned on. by itself."   from behind the sofa: static, the room lit blue
#   33  "night 11: something on the stairs."         the flashlight up the stairs: a pale shape steps back
#   90  "night 12: it watched us sleep."             from my bed: him in the doorway, head laid over
#   60  "night 13: it learned to crawl."             the upstairs hall: on all fours, coming slowly
#   60  "so we all slept downstairs."                lamps on, the sofa, morning-safe
#   60  "night 14: the lights went out."             the same room: dark, then the flashlight clicks on
#   75  "he's not hiding anymore."                   from the sofa: turn round, he's right behind it (22.15 s)
#   30  "RUN."                                       down the stairs, him after you on all fours
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
def clamp(k): return max(0.0, min(1.0, k))
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]
def wrap(a): return ((a + math.pi) % TAU) - math.pi
def him(f, pos, yaw, gait="Stare", phase=0.0, t=0.0, **opts):
    return {"pos": {"x": pos[0], "y": pos[1], "z": pos[2]}, "yaw": yaw, "gait": gait, "phase": phase, "t": t, "seed": 4, "opts": opts}

COLD, MOON, WARM, TVB = "#3d4f7a", "#6f86c4", "#ffb766", "#9fb8ff"
# the master bedroom door (reel 42): in the x = -8 wall, hinged at z -12.42, swings into the room
DOOR_RIG = {"near": [-8.0, U + 4.7, -10.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, -12.42], "axis": "y"}
ROOM = [{"p": [-24, U + 9, -33], "col": MOON, "b": 2.6, "r": 34, "decay": 1.1}, {"p": [-14, U + 6, -20], "col": COLD, "b": 1.1, "r": 18},
        {"p": [-4.5, U + 7, -10], "col": "#6f86c4", "b": 4.0, "r": 18}, {"p": [-26, U + 9, -14], "col": COLD, "b": 0.8, "r": 16}]
HALL = [{"p": [2, U + 11, 24], "col": MOON, "b": 2.0, "r": 30, "decay": 1.1}, {"p": [5, U + 8, 4], "col": COLD, "b": 1.2, "r": 16},
        {"p": [2.5, U + 9, -9], "col": "#5d72a8", "b": 1.6, "r": 18}]
LIVD = [{"p": [-24, G + 9, -4], "col": MOON, "b": 6.0, "r": 34, "decay": 1.0}, {"p": [-36, G + 7, -20], "col": COLD, "b": 3.0, "r": 20},
        {"p": [-12, G + 7, -24], "col": COLD, "b": 1.5, "r": 18}, {"p": [-24, G + 8, -22], "col": "#4a5f92", "b": 1.4, "r": 20}]
TVL = [{"p": [-24, G + 4.4, -26.5], "col": TVB, "b": 3.2, "r": 26, "decay": 1.2}]
STAIRS = [{"p": [-5, U + 6, 22], "col": "#2c3d6e", "b": 1.3, "r": 26}, {"p": [-5, 8, -2], "col": COLD, "b": 1.4, "r": 18},
          {"p": [-5, G + 7, -12], "col": COLD, "b": 1.0, "r": 16}]
SHOTS = {
    "living": {"center": [-26, G + 5, -10], "radius": 34, "lampRadius": 34, "maxLamps": 5},
    "livDark": {"center": [-26, G + 5, -10], "radius": 34, "lampRadius": 34, "maxLamps": 5, "lights": LIVD},
    "livTV": {"center": [-26, G + 5, -10], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": LIVD + TVL},
    "room": {"center": [-24, U + 5, -15], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": DOOR_RIG, "lights": ROOM},
    "hall": {"center": [5, U + 6, 10], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": HALL},
    "stairs": {"center": [-5, G + 6, 4], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": STAIRS},
}
DARK = {"ambient": 0.02, "bg": 0x010102}

# the TV's static: three glowing planes just in front of its screen, swapped every frame or two
extras = []
STATIC = []
for b in (0.9, 1.35, 0.6):
    STATIC.append(len(extras))
    c = int(105 * b)
    extras.append({"pos": [-24.0, 5.55, -28.40 + 0.004 * len(STATIC)], "s": [6.05, 3.3, 0.01], "col": [c, c + 6, c + 16],
                   "emissive": [c, c + 8, c + 24], "ei": 0.75 * b, "rough": 0.3})
ALL = set(range(len(extras)))
def only(*groups):
    keep = set().union(*[set(g) for g in groups]) if groups else set()
    return sorted(ALL - keep)
def static(i):
    return only([STATIC[(i // 2 * 7) % 3]])

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

# 1. (hook) the living room, lamps on: cosy, a slow push
def s_hook(i, k):
    cam = add(lerp([-12.5, G + EYE + 0.6, -1.0], [-16.5, G + EYE + 0.2, -4.0], ease(k)), hand(i, 0.6))
    look = lerp([-30.0, G + 3.2, -13.0], [-31.0, G + 3.0, -14.0], ease(k))
    return ({"shot": "living", "cam": {"pos": cam, "look": look, "fov": 64}, "ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 1,
             "hideIdx": only()}, None)
shot("hook", 105, s_hook)

# 2. (card) the same room in the dark: a slow push past the sofa to the dead TV
def s_card(i, k):
    cam = add(lerp([-17.0, G + EYE + 0.4, -3.0], [-21.0, G + EYE, -8.0], ease(k)), hand(i, 0.5))
    look = lerp([-27.0, G + 3.0, -22.0], [-24.0, G + 4.4, -28.0], ease(k))
    return (dict(DARK, shot="livDark", cam={"pos": cam, "look": look, "fov": 60}, exposure=3.8, lamps=0, hideIdx=only()), None)
shot("card", 120, s_card)

# 3. "night 10: the tv turned on. by itself." from behind the sofa: static, the room lit blue
def s_tv(i, k):
    cam = add(lerp([-24.6, G + EYE + 0.3, -9.0], [-24.3, G + EYE, -11.2], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="livTV", cam={"pos": cam, "look": [-24.0, G + 3.9, -28.4], "fov": 54}, exposure=1.8, lamps=0, hideIdx=static(i)), None)
shot("open", 72, s_tv)

# 4. "night 11: something on the stairs." the flashlight up the stairs: a pale shape at the top steps back
TOP = [-5.0, U, 18.6]
def s_stairs(i, k):
    cam = add([-5.0, G + EYE, -8.5], hand(i, 0.7))
    p = lerp(TOP, [-5.0, U, 21.8], ease((i - 8) / 22))
    look = [-5.0, U + 4.5, 17.0]
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": look, "fov": 50}, exposure=2.2, glow=1.2, hideIdx=only(),
                 flash=fl(cam, [-5.0, U + 5.0, 18.0], 16.0, 0.3)),
            him(0, p, facing(p, cam), "Walk", phase=-0.9 * ease((i - 8) / 22) * 6, t=i / FPS, Look=[0.0, -0.35]))
shot("prints", 33, s_stairs)

# 5. "night 12: it watched us sleep." from my bed: him in the doorway, head laid over, watching
BEDEYE = [-36.4, U + 3.9, -14.0]
DOORWAY = [-10.3, U, -10.7]
def s_watch(i, k):
    cam = [BEDEYE[0], BEDEYE[1] + 0.02 * math.sin(i * 0.2), BEDEYE[2]]
    look = lerp([DOORWAY[0], U + 6.0, DOORWAY[2]], [DOORWAY[0], U + 7.2, DOORWAY[2]], ease(k))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": look, "fov": 40 - 6 * ease(k)}, exposure=3.2, door=-1.35, glow=1.8, hideIdx=only()),
            him(0, DOORWAY, facing(DOORWAY, BEDEYE), "Stare", t=2.0 + i / FPS, Duck=0.45, Look=[0.0, -0.15]))
shot("door", 90, s_watch)

# 6. "night 13: it learned to crawl." the upstairs hall: on all fours, coming slowly
def s_crawl(i, k):
    cam = add([3.6, U + EYE - 0.6, -6.5], hand(i, 0.5))
    p = lerp([4.6, U, 16.0], [4.4, U, 9.5], k)
    return (dict(DARK, shot="hall", cam={"pos": cam, "look": [4.4, U + 1.6, 10.0], "fov": 52}, exposure=2.3, glow=2.0, hideIdx=only(),
                 flash=fl(cam, [4.4, U + 1.0, 11.0], 12.0, 0.34)),
            him(0, p, facing(p, cam), "Chase", phase=k * 1.4 * TAU, t=i / FPS))
shot("beside", 60, s_crawl)

# 7. "so we all slept downstairs." lamps on, the sofa from the TV
def s_safe(i, k):
    cam = add(lerp([-14.8, G + EYE + 1.0, -24.6], [-15.6, G + EYE + 0.8, -23.6], ease(k)), hand(i, 0.4))
    return ({"shot": "living", "cam": {"pos": cam, "look": [-25.5, G + 3.0, -13.5], "fov": 60}, "ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25,
             "lamps": 1, "hideIdx": only()}, None)
shot("nailed", 60, s_safe)

# 8. "night 14: the lights went out." the same room: on, then dark, then the flashlight clicks on
def s_out(i, k):
    cam = add([-15.6, G + EYE + 0.8, -23.6], hand(i, 0.4))
    look = [-25.5, G + 3.0, -13.5]
    if i < 22:
        return ({"shot": "living", "cam": {"pos": cam, "look": look, "fov": 58}, "ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25,
                 "lamps": 1, "hideIdx": only()}, None)
    fr = dict(DARK, shot="livDark", cam={"pos": cam, "look": look, "fov": 58}, exposure=2.0, lamps=0, hideIdx=only())
    if i >= 42:
        fr["flash"] = fl(cam, lerp([-27.0, G + 2.0, -15.0], [-22.0, G + 3.0, -12.0], ease((i - 42) / 18)), 12.0, 0.34)
    return (fr, None)
shot("nails", 60, s_out)

# 9. "he's not hiding anymore." from the sofa: the flashlight on the dark TV... turn round: he's standing right
# behind the sofa (the hit at 22.15 s is frame 64): the maw splits open and he comes over it
SEAT = [-24.2, G + 4.3, -16.3]
BACK = [-24.0, G, -10.6]
def s_behind(i, k):
    cam = add(SEAT, hand(i, 0.4))
    if i < 26:
        look = [-24.0, G + 3.8, -28.4]
        return (dict(DARK, shot="livDark", cam={"pos": cam, "look": look, "fov": 58}, exposure=2.0, lamps=0, hideIdx=only(),
                     flash=fl(cam, look, 12.0, 0.32)), None)
    t = ease((i - 26) / 24)
    y0, y1 = facing(cam, [-24.0, G, -28.4]), facing(cam, BACK)
    yaw = y0 + wrap(y1 - y0) * t
    ly = (G + 3.8) + ((G + 8.6) - (G + 3.8)) * ease((i - 34) / 16)
    look = [cam[0] - math.sin(yaw) * 6.0, ly, cam[2] - math.cos(yaw) * 6.0]
    if i < 64:
        fr = dict(DARK, shot="livDark", cam={"pos": cam, "look": look, "fov": 58}, exposure=2.2, lamps=0, hideIdx=only(), glow=2.2,
                  flash=fl(cam, look if t < 0.98 else [BACK[0], G + 7.6, BACK[2]], 12.0, 0.42))
        return (fr, him(0, BACK, facing(BACK, cam), "Stare", t=3.0 + i / FPS, Look=[0.0, -0.25], Scream=0.25 * ease((i - 54) / 10)))
    w = ease((i - 64) / 4)
    p = lerp(BACK, [-24.0, G, -11.6], w)
    camw = lerp(cam, [-24.1, G + 4.7, -15.4], w)
    fr = dict(DARK, shot="livDark", cam={"pos": camw, "look": [-24.0, G + 7.4 - 0.8 * w, -11.4], "fov": 60 + 6 * w}, exposure=2.6, lamps=0,
              hideIdx=only(), glow=7.0, flash=fl(camw, [p[0], G + 7.0, p[2]], 14.0, 0.5))
    return (fr, him(0, p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Look=[0.0, -0.3]))
shot("behind", 75, s_behind)

# 10. RUN: down the stairs, looking back: he comes down after you on all fours
def sy(z): return max(G, min(U, 2.05 + 0.625 * (z + 5.3) - 1.0))
def s_run(i, k):
    zc = 2.0 - 7.0 * k
    cam = [-5.0 + 0.25 * math.sin(i * 1.7), sy(zc) + 5.0 + 0.2 * math.sin(i * 2.3), zc]
    zh = 17.0 - 9.0 * k
    hy = sy(zh) if zh < 15.5 else U
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, hy + 2.6, zh], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [-5.0 + 1.2 * math.sin(i * 1.3), hy + 3.0, zh], 18.0, 0.36), ambient=0.01, exposure=1.8, glow=6, hideIdx=only()),
            him(0, [-5.0, hy, zh], facing([-5.0, hy, zh], [-5.0, hy, zh - 10]), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
