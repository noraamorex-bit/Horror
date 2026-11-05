# Reel 66 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 4)": the PEAK run on #2's track (Parts 1-3: reels 61-65).
# New footage, the living room at 3 am: the TV turns on by itself. In its static he's standing right in front of it, his
# back to me; his head turns right round. Down behind the sofa. His legs come round its end. Over the back: the room's
# empty, the static still on. I crawl for the hall door: he's crouched in it. Back behind the sofa... the TV goes off. I turn
# round: he's right behind me (22.15 s). RUN. The masked v114 look, as in the game; him in five of the ten clips.
#   hook (105)  the dark living room from the hall side, the flashlight sliding over the sofa to the dead TV
#   card (120)  from behind the sofa: the TV clicks on by itself, static, the room lit blue (played at 0.64)
#   72          in the static: him standing right in front of the TV, his back to me; his head turns right round
#   33          down behind the sofa, fast
#   90          crouched behind the sofa: his legs come round its far end, stop, and go on
#   60          rising over the sofa back: the static, the room empty
#   60          crawling along the back of the sofa for the hall door
#   60          he's crouched in the doorway, the hall's moonlight behind him; backing away
#   75          back behind the sofa; the TV goes dark... turn round: he's right behind me, down at my level (22.15 s)
#   30          RUN for the door, looking back: him round the sofa on all fours
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

COLD, MOON, TVB = "#3d4f7a", "#6f86c4", "#9fb8ff"
# --- the living room (ground floor, reel 43): x -40..-8, z -30..2; the TV on the front wall at x -24, z -28.6 (screen
# 6.4 x 3.7, its middle at y 5.5); the coffee table x -26.6..-21.4, z -22.4..-19.6; the sofa x -29..-19, z -17.4..-13.6, its
# back at z -13.9 (top y 4.9), facing the TV; armchairs at x -15.2 / -34, z ~-22; the fireplace on the x = -40 wall at z -12;
# the doorway to the front hall in the x = -8 wall, z -22..-14
LIVD = [{"p": [-24, G + 9, -4], "col": MOON, "b": 5.0, "r": 34, "decay": 1.0}, {"p": [-36, G + 7, -20], "col": COLD, "b": 2.4, "r": 20},
        {"p": [-12, G + 7, -24], "col": COLD, "b": 1.5, "r": 18}]
TVL = [{"p": [-24, G + 4.4, -26.5], "col": TVB, "b": 3.2, "r": 26, "decay": 1.2}]
HALLL = [{"p": [-3, G + 8, -18], "col": MOON, "b": 3.0, "r": 16, "decay": 1.1}]
LOWFILL = [{"p": [-24, G + 3, -8], "col": COLD, "b": 1.4, "r": 12}]
NOCANDY = ["CandyWrap", "CandyBody"]
SHOTS = {
    "dark": {"center": [-24, G + 5, -14], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": LIVD + HALLL},
    "tv": {"center": [-24, G + 5, -14], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": LIVD + TVL + HALLL},
    "low": {"center": [-24, G + 3, -12], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": LIVD + TVL + HALLL + LOWFILL},
    "lowDark": {"center": [-24, G + 3, -12], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": LIVD + HALLL + LOWFILL},
}
for _s in SHOTS.values(): _s["hide"] = NOCANDY
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
def static(i): return only([STATIC[(i // 2 * 7) % 3]])

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
def crawl(i, amt=1.0):
    return [0.06 * amt * math.sin(i * 0.21), 0.09 * amt * abs(math.sin(i * 0.21)), 0.04 * amt * math.sin(i * 0.13 + 1)]

# 1. (hook) the dark living room from the hall side: the flashlight slides over the sofa to the dead TV
def s_hook(i, k):
    cam = add(lerp([-12.5, G + EYE + 0.4, -2.0], [-17.0, G + EYE + 0.2, -6.0], ease(k)), hand(i))
    tgt = lerp([-30.0, G + 3.0, -14.0], [-24.0, G + 5.0, -28.4], ease(min(1.0, k * 1.2)))
    look = lerp([-28.0, G + 3.4, -17.0], [-24.0, G + 4.6, -28.0], ease(k))
    return (dict(DARK, shot="dark", cam={"pos": cam, "look": look, "fov": 60}, flash=fl(cam, tgt, 11.0, 0.3), exposure=2.6, lamps=0), None)
shot("hook", 105, s_hook)

# 2. (card) from behind the sofa: the TV clicks on by itself, static, the room lit blue
def s_card(i, k):
    cam = add(lerp([-24.6, G + EYE + 0.3, -8.5], [-24.3, G + EYE, -10.6], ease(k)), hand(i, 0.4))
    on = i >= 16
    return (dict(DARK, shot="tv" if on else "dark", cam={"pos": cam, "look": [-24.0, G + 3.9, -28.4], "fov": 56}, exposure=1.9 if on else 3.0,
                 hideIdx=static(i) if on else only()), None)
shot("card", 120, s_card)

# 3. in the static: him standing right in front of the TV, his back to me... his head turns right round
TVHIM = [-24.0, G, -24.8]
def s_turn(i, k):
    cam = add(lerp([-23.2, G + EYE + 0.2, -10.4], [-23.4, G + EYE + 0.1, -11.4], ease(k)), hand(i, 0.3))
    turn = ease((stop(i) * 30 - 24) / 26)
    return (dict(DARK, shot="tv", cam={"pos": cam, "look": [-24.0, G + 5.6, -25.0], "fov": 50}, exposure=1.9, glow=0.4 + 1.8 * turn,
                 hideIdx=static(i)),
            him(TVHIM, facing(TVHIM, [-24.0, G, -30.0]), "Stare", t=3.0 + stop(i), Duck=0.35, Look=[3.2 * turn, 0.2 * turn]))
shot("turn", 72, s_turn)

# 4. down behind the sofa, fast: the view drops and swings along its back to the far end
EYE5 = [-20.6, G + 2.2, -11.4]
def s_drop(i, k):
    w = ease(min(1.0, i / 12))
    cam = add(lerp([-23.4, G + EYE + 0.1, -11.4], [-22.0, G + 2.3, -11.2], w), [0.1 * math.sin(i * 1.3) * (1 - w), 0.08 * math.sin(i * 1.9) * (1 - w), 0])
    cam = lerp(cam, EYE5, ease((i - 12) / 18))
    look = lerp([-24.0, G + 5.6, -25.0], [-31.5, G + 3.0, -12.4], ease(i / 16))
    return (dict(DARK, shot="low", cam={"pos": add(cam, hand(i, 0.6)), "look": look, "fov": 62, "roll": 0.06 * (1 - w)}, exposure=3.0,
                 hideIdx=static(i)), None)
shot("hide", 33, s_drop)

# 5. crouched behind the sofa: his legs come round its far end from the TV side, slow, stop at the corner (the head
# lowers, listening), then go on toward the fireplace
P5 = [[-31.0, G, -21.0], [-31.0, G, -12.4], [-35.0, G, -4.0]]
def s_legs(i, k):
    cam = add(EYE5, hand(i, 0.25))
    if i < 40:
        w = ease(i / 40) * 0.9 + 0.1 * (i / 40)
        p, yaw, d = lerp(P5[0], P5[1], w), facing(P5[0], P5[1]), w * 8.6
        cr = him(p, yaw, "Search", phase=d * 0.85, t=i / FPS, Duck=0.3)
    elif i < 64:
        p, yaw = P5[1], facing(P5[0], P5[1])
        lk = ease((i - 42) / 10) * (1 - ease((i - 56) / 8))
        cr = him(p, yaw, "Stare", t=2.0 + stop(i), Duck=0.3 + 0.5 * lk, Look=[-0.9 * lk, -0.4 * lk])
    else:
        w = ease((i - 64) / 26)
        p, yaw = lerp(P5[1], P5[2], w), facing(P5[1], P5[2])
        cr = him(p, yaw, "Search", phase=(8.6 + w * 9.3) * 0.85, t=i / FPS, Duck=0.3)
    return (dict(DARK, shot="low", cam={"pos": cam, "look": [-31.0, G + 3.0, -12.6], "fov": 62}, exposure=3.2, glow=1.4, hideIdx=static(i)), cr)
shot("legs", 90, s_legs)

# 6. rising slowly over the sofa back: the static, the room empty
def s_peek(i, k):
    cam = add(lerp([-24.6, G + 3.2, -12.4], [-24.6, G + 5.4, -12.5], ease(k * 1.3)), hand(i, 0.25))
    return (dict(DARK, shot="tv", cam={"pos": cam, "look": lerp([-24.4, G + 3.4, -24.0], [-24.0, G + 4.4, -28.4], ease(k)), "fov": 56}, exposure=2.0,
                 hideIdx=static(i)), None)
shot("peek", 60, s_peek)

# 7. crawling along the back of the sofa for the hall door
def s_crawl(i, k):
    cam = add(lerp([-24.0, G + 1.9, -11.6], [-16.5, G + 1.9, -12.4], ease(k)), crawl(i))
    look = lerp([-10.0, G + 1.6, -11.0], [-8.4, G + 3.2, -18.0], ease((k - 0.3) / 0.7))
    return (dict(DARK, shot="low", cam={"pos": cam, "look": look, "fov": 62, "roll": 0.03 * math.sin(i * 0.21)}, exposure=3.2, hideIdx=static(i)), None)
shot("crawl", 60, s_crawl)

# 8. he's crouched in the doorway, the hall's moonlight behind him, looking down at me... I back away
DOOR = [-9.8, G, -18.0]
def s_door(i, k):
    back = ease((i - 30) / 30)
    cam = add(lerp([-16.5, G + 1.9, -12.4], [-17.6, G + 1.85, -11.6], back), hand(i, 0.6 + 0.6 * back))
    return (dict(DARK, shot="low", cam={"pos": cam, "look": [-10.2, G + 4.4, -17.6], "fov": 54}, exposure=2.8, glow=1.8, hideIdx=static(i)),
            him(DOOR, facing(DOOR, cam), "Stare", t=4.0 + stop(i), Duck=1.1, Look=[0.0, -0.4]))
shot("stood", 60, s_door)

# 9. back behind the sofa, the static over its back... the TV goes dark. Turn round: he's right behind me, down at my
# level, looking at me... and on 22.15 s (frame 65) he comes
EYE9 = [-24.0, G + 2.3, -11.4]
BEHIND = [-24.4, G, -4.7]
def s_behind(i, k):
    cam = add(EYE9, hand(i, 0.3))
    tvon = i < 22
    t = ease((i - 26) / 22)
    y0, y1 = facing(cam, [-24.0, G, -28.4]), facing(cam, BEHIND)
    yaw = y0 + wrap(y1 - y0) * t
    ly = (G + 3.6) + ((G + 6.4) - (G + 3.6)) * ease((i - 34) / 16)
    look = [cam[0] - math.sin(yaw) * 6.0, ly, cam[2] - math.cos(yaw) * 6.0]
    sh = "low" if tvon else "lowDark"
    hid = static(i) if tvon else only()
    if i < 65:
        cr = him(BEHIND, facing(BEHIND, cam), "Stare", t=3.0 + stop(i), Duck=2.1, Look=[0.0, -0.6], Scream=0.15 * ease((i - 55) / 10)) if t > 0.2 else None
        return (dict(DARK, shot=sh, cam={"pos": cam, "look": look, "fov": 62}, exposure=3.0, glow=2.4 if t > 0.5 else 0.6, hideIdx=hid), cr)
    w = ease((i - 65) / 5)
    p = lerp(BEHIND, [-24.2, G, -6.5], w)
    camw = add(cam, [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    return (dict(DARK, shot="lowDark", cam={"pos": camw, "look": lerp(look, [p[0], G + 4.4, p[2]], w), "fov": 62 + 8 * w}, exposure=3.0, glow=6.0,
                 flash=fl(camw, [p[0], G + 5.0, p[2]], 8.0, 0.5), hideIdx=only()),
            him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Duck=2.1 + 0.5 * w, Look=[0.0, -0.6]))
shot("knew", 75, s_behind)

# 10. RUN: for the door past the sofa's end, looking back: he's round the sofa and after me on all fours
def s_run(i, k):
    c = lerp([-15.5, 0, -13.0], [-10.8, 0, -17.2], k)
    cam = [c[0] + 0.25 * math.sin(i * 1.7), G + 5.0 + 0.2 * math.sin(i * 2.3), c[2]]
    hp = lerp([-23.5, G, -9.8], [-18.6, G, -12.2], k)
    return (dict(DARK, shot="dark", cam={"pos": cam, "look": [hp[0], G + 2.8, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), G + 3.2, hp[2]], 14.0, 0.36), exposure=2.2, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
