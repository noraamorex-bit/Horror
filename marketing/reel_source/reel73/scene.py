# Reel 73 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 11)": the PEAK run on #2's track, the v148 creature (his
# sculpted porcelain face). The living room in the storm: lightning, his face pressed to the front window; the next flash, gone;
# he crawls in from the hall; behind the long curtains you watch him through the gap; peek round: he's bent over the armchair;
# his head turns to the curtain; back behind it; one more peek... his face right at the edge (22.15 s). RUN.
#   hook (105)  the dark living room from the hall door, rain on the windows, the storm
#   card (120)  lightning: his face pressed to the front window, looking in
#   72          the next flash: the window, nobody
#   33          the hall door: him low in it, crawling in
#   90          behind the curtains: through the gap, he crawls across the rug
#   60          peek round the curtain: he's bent over the armchair
#   60          his head turns to the curtain
#   60          back behind it: the fabric, breathing
#   75          one more peek... his face right at the edge (22.15 s)
#   30          RUN for the hall, him after you
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau + mask.json), shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
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

COLD, MOON = "#3d4f7a", "#6f86c4"
HIDE = ["CandyWrap", "CandyBody"]
# the living room (ground floor, G): x -40..-10, z -30..-10; front windows in the z -30 wall at x -34 and -14 (glass 4.5..10),
# the TV between them, the side window in the x -40 wall at z -22; the hedge outside at z -32..-33. The long curtain we hide
# behind: x -38.4..-36.4 at z -29.08, beside the west front window; the armchair at (-34, -21.5) facing +x
ROOM = [{"p": [-24, G + 9, -12], "col": COLD, "b": 0.6, "r": 26}, {"p": [-36, G + 7, -27.5], "col": MOON, "b": 1.0, "r": 18, "decay": 1.0},
        {"p": [-12, G + 7, -27.5], "col": MOON, "b": 1.0, "r": 18, "decay": 1.0}, {"p": [-38.5, G + 7, -22], "col": MOON, "b": 0.8, "r": 14, "decay": 1.0},
        {"p": [-34, G + 8, -23], "col": COLD, "b": 0.9, "r": 13}]
SHOTS = {"room": {"center": [-24, G + 5, -20], "radius": 36, "lampRadius": 0, "maxLamps": 0, "lights": ROOM}}
for _s in SHOTS.values(): _s["hide"] = _s.get("hide", []) + HIDE
DARK = {"ambient": 0.02, "bg": 0x010102}
def sky(lt):
    c = lerp([10, 13, 22], [120, 132, 168], lt)
    return (int(c[0]) << 16) | (int(c[1]) << 8) | int(c[2])
def bolt(lt, tgt):
    # lightning outside: a cold light from high up over the front lawn, on him at the glass (not the room)
    return {"i": 90.0 * lt, "pos": [-14.0, G + 34.0, -60.0], "target": tgt, "angle": 0.45} if lt > 0 else {"i": 0}
OUTSIDE = [-14.0, 0.5, -31.3]
CHAIR = [-31.2, G, -19.2]  # (him by the coffee table, his back to the curtain)
GAP = [-36.55, G + 5.2, -29.4]     # behind the curtain, at its edge: the room through the gap
PEEKP = [-36.15, G + 5.15, -28.8]  # leaning round it

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
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}

# 1. (hook) the dark living room from the hall door, the storm at the windows
def s_hook(i, k):
    cam = add(lerp([-10.5, G + 5.9, -11.0], [-15.0, G + 5.7, -15.0], ease(k)), hand(i, 0.5))
    lt = 0.8 if 70 <= i <= 73 else (0.45 if 77 <= i <= 79 else 0.0)
    return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp([-24.0, G + 5.0, -29.0], [-20.0, G + 5.5, -29.5], ease(k)), "fov": 66}, exposure=5.0,
                 flash=bolt(lt, [-24.0, G + 6.0, -30.0]), bg=sky(lt)), None)
shot("hook", 105, s_hook)

# 2. (card) lightning: his face pressed to the front window, looking in
def s_card(i, k):
    cam = add(lerp([-16.5, G + 5.6, -21.0], [-15.6, G + 5.8, -24.0], ease(k)), hand(i, 0.35))
    lt = 1.0 if 18 <= i <= 22 else (0.6 if 26 <= i <= 28 else (0.9 if 70 <= i <= 74 else (0.5 if 78 <= i <= 80 else 0.0)))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-14.0, G + 7.2, -30.0], "fov": 52}, exposure=3.4,
                 flash=bolt(lt, [OUTSIDE[0], 8.5, OUTSIDE[2]]), bg=sky(lt), glow=2.4),
            him(OUTSIDE, facing(OUTSIDE, cam), "Stare", t=1.0 + stop(i), Duck=0.7, Look=[0.0, -0.25]))
shot("card", 120, s_card)

# 3. the next flash: the window, nobody
def s_gone(i, k):
    cam = add([-15.6, G + 5.8, -24.0], hand(i, 0.3))
    lt = 1.0 if 30 <= i <= 34 else (0.5 if 38 <= i <= 40 else 0.0)
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [-14.0, G + 7.0, -30.0], "fov": 52}, exposure=3.4, flash=bolt(lt, [-14.0, 6.0, -31.0]), bg=sky(lt)), None)
shot("gone", 72, s_gone)

# 4. the hall door: him low in it, crawling in
DOORW = [-10.6, G, -16.0]
def s_door(i, k):
    cam = add([-17.0, G + 5.5, -23.0], hand(i, 0.35))
    p = lerp(DOORW, [-13.0, G, -17.0], ease(k))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [p[0], G + 2.6, p[2]], "fov": 56}, exposure=4.0, glow=2.0),
            him(p, facing(p, cam), "Chase", phase=k * 1.2 * TAU, t=2.0 + stop(i)))
shot("crawl", 33, s_door)

# 5. behind the curtains: through the gap, he crawls across the rug towards the armchair
def s_gap(i, k):
    w = ease(i / 14)
    cam = add(lerp([-37.0, G + 5.2, -29.6], GAP, w), hand(i, 0.15))
    m = ease((i - 10) / 76)
    p = lerp([-16.0, G, -18.0], [CHAIR[0] + 2.0, G, CHAIR[2] + 1.0], m)
    look = lerp([-22.0, G + 2.8, -18.0], [-32.0, G + 2.6, -21.0], ease((i - 10) / 70))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": look, "fov": 56}, exposure=4.6, glow=1.6),
            him(p, facing(p, [CHAIR[0], G, CHAIR[2]]), "Chase", phase=m * 2.6 * TAU, t=3.0 + stop(i)))
shot("gap", 90, s_gap)

# 6. peek round the curtain: he's bent over the armchair, his back to you
def s_peek(i, k):
    w = ease(i / 30)
    cam = add(lerp(GAP, PEEKP, w), hand(i, 0.2))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp([-32.0, G + 2.6, -21.0], [CHAIR[0], G + 5.6, CHAIR[2]], w), "fov": 54, "roll": -0.08 * math.sin(w * math.pi)}, exposure=4.6, glow=1.6),
            him(CHAIR, facing(CHAIR, [CHAIR[0] + 1.5, G, CHAIR[2] + 4]), "Stare", t=4.0 + stop(i), Duck=0.7))
shot("peek", 60, s_peek)

# 7. his head turns to the curtain
def s_turn(i, k):
    cam = add(PEEKP, hand(i, 0.2))
    turn = ease((stop(i, 12) * 30 - 6) / 16)
    base = facing(CHAIR, [CHAIR[0] + 1.5, G, CHAIR[2] + 4])
    yaw = wrap(facing(CHAIR, PEEKP) - base)
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [CHAIR[0], G + 7.0, CHAIR[2]], "fov": 46 - 6 * ease(k)}, exposure=4.6, glow=2.4),
            him(CHAIR, base, "Stare", t=4.6 + stop(i), Duck=0.7, Look=[yaw * turn * 1.5, 0.1 * turn]))
shot("turn", 60, s_turn)

# 8. back behind it: the fabric, breathing
def s_back(i, k):
    w = ease(i / 12)
    cam = add(lerp(PEEKP, [-37.1, G + 5.2, -29.55], w), hand(i, 0.12 + 0.08 * math.sin(i * 0.3) ** 2))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp([CHAIR[0], G + 4.4, CHAIR[2]], [-37.3, G + 5.0, -27.0], w), "fov": 56}, exposure=5.0), None)
shot("back", 60, s_back)

# 9. one more peek... on 22.15 s (frame 65) his face right at the curtain's edge
EDGE = [-33.3, G, -22.3]
def s_last(i, k):
    if i < 65:
        w = ease(i / 55)
        cam = add(lerp([-37.1, G + 5.2, -29.55], PEEKP, w), hand(i, 0.12))
        return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp([-37.3, G + 5.0, -27.0], [-30.0, G + 3.0, -21.0], w), "fov": 56}, exposure=4.8), None)
    w = ease((i - 65) / 4)
    cam = add(PEEKP, [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    p = lerp(EDGE, [-33.9, G, -23.6], w)
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [p[0], G + 6.9 - 0.4 * w, p[2]], "fov": 62 + 8 * w}, exposure=4.0, glow=6.0,
                 flash=fl(cam, [p[0], G + 6.0, p[2]], 1.2 * w, 0.5)),
            him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Duck=1.2, Look=[0.0, 0.25]))
shot("last", 75, s_last)

# 10. RUN: out from behind the curtain for the hall, looking back: he comes after you
def s_run(i, k):
    c = lerp([-32.0, 0, -26.0], [-14.0, 0, -15.0], k)
    cam = [c[0] + 0.25 * math.sin(i * 1.7), G + 5.0 + 0.2 * math.sin(i * 2.3), c[2]]
    hp = lerp([-36.0, G, -25.0], [-26.0, G, -21.0], k)
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [hp[0], G + 2.8, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)},
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), G + 3.0, hp[2]], 14.0, 0.36), exposure=2.6, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": [],
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
