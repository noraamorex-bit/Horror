# Reel 65 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 3)" (4 Nov; the PEAK format restarted at Part 1 on #2's
# track, the owner: "Bring back the peak Roblox game thing with this sound."). Parts 1-2 were cut from reels 61-64 (all
# upstairs); Part 3 is new footage, downstairs: the kitchen at 3 am. The fridge door is open a crack, light leaking... it swings
# open by itself, and he's bent into it, his back to me; his head turns right round. I drop behind the island. His legs go by.
# I look over the counter: gone. I crawl for the arch: he's standing in it. Back behind the island, I look up: he's leaning
# over the counter right above me (22.15 s). RUN. The masked v114 look, as in the game; him in five of the ten clips.
#   hook (105)  the dark kitchen, the flashlight sliding to the fridge: its door open a crack, light leaking out
#   card (120)  closer: the fridge door swings open by itself, the light floods out (played at 0.64)
#   72          from behind the island: him bent into the open fridge, his back to me; his head turns right round
#   33          down behind the island, fast
#   90          crouched at the island's foot: his legs come round its end, stop, and go on
#   60          rising over the counter: the kitchen's empty, the fridge still open
#   60          crawling for the hall arch, under the edge of the dining table
#   60          he's standing in the arch, the hall's moonlight behind him; backing away
#   75          back behind the island; look up: he's leaning over the counter above me... he comes over it (22.15 s)
#   30          RUN for the arch, looking back: him round the island on all fours
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
def stop(i, fps=13): return math.floor(i * fps / 30) / fps
def him(pos, yaw, gait="Stare", phase=0.0, t=0.0, **opts):
    return {"pos": {"x": pos[0], "y": pos[1], "z": pos[2]}, "yaw": yaw, "gait": gait, "phase": phase, "t": t, "seed": 4, "opts": opts}

COLD, MOON, FRIDGE_LIGHT = "#3d4f7a", "#6f86c4", "#dfeaff"
# --- the kitchen (ground floor, reel 48): the range against the x = -40 wall (z 21..25); the island x -28..-22, z 12.5..17.4
# (its top at y 4.8); the fridge at x -29.6..-27.1, its doors at z 25.95 (the left leaf hinged at x -29.58); the dining table
# x -17..-9, z 12..23.5; the arch to the hall in the x = -8 wall at z 26
FRIDGE = {"near": [-28.36, 7.8, 25.95], "r": 1.3, "names": ["FridgeDoor", "FridgeHandle"], "hinge": [-29.58, 0, 25.95], "axis": "y"}
FX = -28.36
KITCHEN = [{"p": [-38, 9, 14], "col": COLD, "b": 1.2, "r": 16}, {"p": [-24, 9, 29], "col": COLD, "b": 0.9, "r": 14},
           {"p": [-32, 9, 31], "col": MOON, "b": 1.8, "r": 18, "decay": 1.2}, {"p": [-16, 9, 18], "col": MOON, "b": 1.4, "r": 18}]
def flight(b): return {"p": [FX, 7.6, 24.6], "col": FRIDGE_LIGHT, "b": b, "r": 12, "decay": 1.4}
GHALL = [{"p": [-2, G + 8, 26], "col": MOON, "b": 2.4, "r": 16, "decay": 1.1}, {"p": [-2, G + 8, 12], "col": COLD, "b": 1.0, "r": 18}]
NOCANDY = ["CandyWrap", "CandyBody"]
SHOTS = {
    "ajar": {"center": [-22, G + 5, 19], "radius": 34, "lampRadius": 0, "maxLamps": 0, "door": FRIDGE, "lights": KITCHEN + [flight(1.1)]},
    "open": {"center": [-22, G + 5, 19], "radius": 34, "lampRadius": 0, "maxLamps": 0, "door": FRIDGE, "lights": KITCHEN + [flight(3.0)]},
    "low": {"center": [-22, G + 3, 16], "radius": 34, "lampRadius": 0, "maxLamps": 0, "door": FRIDGE,
            "lights": KITCHEN + [flight(2.4), {"p": [-13, 7, 9], "col": MOON, "b": 2.6, "r": 20, "decay": 1.1}, {"p": [-21, 3, 21], "col": COLD, "b": 1.2, "r": 10}]},
    "arch": {"center": [-16, G + 5, 21], "radius": 34, "lampRadius": 0, "maxLamps": 0, "door": FRIDGE, "lights": KITCHEN + [flight(3.0)] + GHALL},
}
for _s in SHOTS.values(): _s["hide"] = NOCANDY
DARK = {"ambient": 0.02, "bg": 0x010102}
OPEN = 1.9

# --- props (film2 extras): inside the fridge (the game hides its insides while it's shut): a white liner, shelves, a dish
# licked clean, the milk, the juice
extras = []
WHITE, GLASS, FOIL = [232, 238, 240], [200, 222, 230], [196, 200, 206]
extras.append({"pos": [FX, 7.8, 26.12], "s": [2.3, 6.6, 0.05], "rot": [0, 0, 0], "col": WHITE, "rough": 0.5})
for y in (5.9, 7.7, 9.4):
    extras.append({"pos": [FX, y, 25.75], "s": [2.2, 0.07, 0.75], "rot": [0, 0, 0], "col": GLASS, "rough": 0.2})
extras.append({"pos": [FX + 0.1, 7.92, 25.72], "s": [1.6, 0.32, 0.72], "rot": [0, 0.08, 0], "col": FOIL, "rough": 0.3})
extras.append({"pos": [FX + 0.1, 8.0, 25.72], "s": [1.4, 0.2, 0.6], "rot": [0, 0.08, 0], "col": [150, 60, 40], "rough": 0.6})
extras.append({"pos": [FX - 0.8, 6.3, 25.75], "s": [0.6, 0.7, 0.5], "rot": [0, 0, 0], "col": [245, 245, 240], "rough": 0.5})
extras.append({"pos": [FX + 0.8, 9.75, 25.75], "s": [0.5, 0.65, 0.45], "rot": [0, 0, 0], "col": [240, 150, 40], "rough": 0.5})
# (the milk on its side on the floor in front of the fridge, a white puddle)
extras.append({"shape": "cyl", "pos": [-27.4, G + 0.32, 23.6], "s": [0.6, 0.9, 0.6], "rot": [0, 0, math.pi / 2], "col": [245, 245, 240], "rough": 0.5})
extras.append({"shape": "cyl", "pos": [-26.5, G + 0.012, 23.2], "s": [2.2, 0.02, 1.5], "rot": [0, 0.4, 0], "col": [236, 238, 240], "rough": 0.1})

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
def crawl(i, amt=1.0):
    return [0.06 * amt * math.sin(i * 0.21), 0.09 * amt * abs(math.sin(i * 0.21)), 0.04 * amt * math.sin(i * 0.13 + 1)]

# 1. (hook) the dark kitchen from the arch side: the flashlight slides along the counters to the fridge, open a crack
def s_hook(i, k):
    cam = add(lerp([-11.5, G + EYE, 21.5], [-16.5, G + EYE - 0.1, 20.0], ease(k)), hand(i))
    tgt = lerp([-36.0, G + 4.2, 23.0], [-28.0, G + 6.2, 25.8], ease(min(1.0, k * 1.25)))
    look = lerp([-31.0, G + 4.6, 24.0], [-28.0, G + 6.0, 25.8], ease(k))
    return (dict(DARK, shot="ajar", cam={"pos": cam, "look": look, "fov": 58}, flash=fl(cam, tgt, 10.0, 0.3), exposure=2.0, door=0.28, glow=0), None)
shot("hook", 105, s_hook)

# 2. (card) closer, from past the island: the fridge door swings open by itself, the light floods out (the card plays it
# at 0.64: the door's open by frame ~60)
def s_card(i, k):
    cam = add(lerp([-20.6, G + EYE, 18.2], [-22.2, G + EYE + 0.1, 19.6], ease(k)), hand(i, 0.6))
    d = 0.28 + (OPEN - 0.28) * ease((i - 12) / 40)
    look = [-27.9, G + 5.6, 25.8]
    return (dict(DARK, shot="open" if i >= 18 else "ajar", cam={"pos": cam, "look": look, "fov": 54}, exposure=1.6, door=d,
                 flash=fl(cam, look, 5.0, 0.3)), None)
shot("card", 120, s_card)

# 3. from behind the island: him bent into the open fridge, his back to me, the light all round him... his head turns
# right round (13 poses a second)
FRIDGEHIM = [-28.2, G, 22.9]
INTO = facing(FRIDGEHIM, [-28.2, G, 30.0])
CAM3 = [-20.4, G + EYE, 12.2]
def s_fridge(i, k):
    cam = add(lerp(CAM3, [-20.7, G + EYE - 0.1, 12.8], ease(k)), hand(i, 0.3))
    turn = ease((stop(i) * 30 - 24) / 26)
    return (dict(DARK, shot="open", cam={"pos": cam, "look": [-27.6, G + 5.8, 22.6], "fov": 48}, exposure=2.1, door=OPEN, glow=0.6 + 1.6 * turn,
                 flash=fl(cam, [-28.0, G + 6.0, 22.9], 3.0, 0.3)),
            him(FRIDGEHIM, INTO, "Stare", t=3.0 + stop(i), Duck=0.75 - 0.55 * turn, Look=[-3.0 * turn, 0.2 * turn]))
shot("turn", 72, s_fridge)

# 4. down behind the island, fast: the view drops and swings to the floor along the island's foot
CROUCH = [-21.2, G + 2.3, 11.6]
EYE5 = [-24.2, G + 2.2, 11.2]
def s_drop(i, k):
    w = ease(min(1.0, i / 12))
    cam = add(lerp([-20.7, G + EYE - 0.1, 12.8], CROUCH, w), [0.1 * math.sin(i * 1.3) * (1 - w), 0.08 * math.sin(i * 1.9) * (1 - w), 0])
    cam = lerp(cam, EYE5, ease((i - 12) / 18))
    look = lerp([-27.6, G + 5.8, 22.6], [-17.5, G + 3.0, 13.6], ease(i / 16))
    return (dict(DARK, shot="low", cam={"pos": add(cam, hand(i, 0.6)), "look": look, "fov": 62, "roll": 0.06 * (1 - w)}, exposure=3.2, door=OPEN), None)
shot("hide", 33, s_drop)

# 5. crouched at the island's foot, looking along its end: his legs come round from the fridge side, slow, stop by the
# corner (the head lowers, listening), then go on toward the front of the house
P5 = [[-20.1, G, 21.5], [-20.1, G, 13.6], [-16.0, G, 5.0]]
def s_legs(i, k):
    cam = add(EYE5, hand(i, 0.25))
    if i < 40:
        w = ease(i / 40) * 0.9 + 0.1 * (i / 40)
        p, yaw, d = lerp(P5[0], P5[1], w), facing(P5[0], P5[1]), w * 7.9
        cr = him(p, yaw, "Search", phase=d * 0.85, t=i / FPS, Duck=0.3)
    elif i < 64:
        p, yaw = P5[1], facing(P5[0], P5[1])
        lk = ease((i - 42) / 10) * (1 - ease((i - 56) / 8))
        cr = him(p, yaw, "Stare", t=2.0 + stop(i), Duck=0.3 + 0.5 * lk, Look=[-0.9 * lk, -0.4 * lk])
    else:
        w = ease((i - 64) / 26)
        p, yaw = lerp(P5[1], P5[2], w), facing(P5[1], P5[2])
        cr = him(p, yaw, "Search", phase=(7.9 + w * 9.5) * 0.85, t=i / FPS, Duck=0.3)
    return (dict(DARK, shot="low", cam={"pos": cam, "look": [-17.5, G + 3.0, 13.6], "fov": 62}, exposure=3.4, door=OPEN, glow=1.4), cr)
shot("legs", 90, s_legs)

# 6. rising slowly over the counter: the kitchen's empty, the fridge still open, its light on the floor
def s_peek(i, k):
    cam = add(lerp([-24.6, G + 3.0, 11.6], [-24.7, G + 4.75, 11.8], ease(k * 1.3)), hand(i, 0.25))
    return (dict(DARK, shot="open", cam={"pos": cam, "look": lerp([-25.5, G + 3.8, 22.0], [-28.0, G + 4.4, 24.0], ease(k)), "fov": 56},
                 exposure=2.0, door=OPEN), None)
shot("peek", 60, s_peek)

# 7. crawling for the hall arch, along the island's end, under the edge of the dining table
def s_crawl(i, k):
    cam = add(lerp([-20.2, G + 1.9, 13.0], [-19.6, G + 1.9, 21.8], ease(k)), crawl(i))
    look = lerp([-19.6, G + 1.6, 30.0], [-8.0, G + 3.2, 25.8], ease((k - 0.3) / 0.7))
    return (dict(DARK, shot="arch", cam={"pos": cam, "look": look, "fov": 62, "roll": 0.03 * math.sin(i * 0.21)}, exposure=3.6, door=OPEN), None)
shot("crawl", 60, s_crawl)

# 8. he's standing in the arch, stooped under it, the hall's moonlight behind him, looking down at me... I back away
ARCH = [-9.6, G, 25.7]
def s_arch(i, k):
    back = ease((i - 30) / 30)
    cam = add(lerp([-19.6, G + 1.9, 21.8], [-19.8, G + 1.85, 20.7], back), hand(i, 0.6 + 0.6 * back))
    return (dict(DARK, shot="arch", cam={"pos": cam, "look": [-10.0, G + 4.6, 25.6], "fov": 54}, exposure=2.6, door=OPEN, glow=1.8),
            him(ARCH, facing(ARCH, cam), "Stare", t=4.0 + stop(i), Duck=0.85, Look=[0.0, -0.35]))
shot("stood", 60, s_arch)

# 9. back behind the island, against its side, breathing, looking out... then up over my shoulder: he's leaning over the
# counter right above me, looking down... and on 22.15 s (frame 65) he comes over it at me
EYE9 = [-25.0, G + 2.4, 9.4]
OVER = [-25.0, G, 19.0]
def s_over(i, k):
    if i < 65:
        cam = add(EYE9, hand(i, 0.35))
        up = ease((i - 18) / 30)
        look = lerp([-21.0, G + 2.6, 2.0], [-25.0, G + 6.4, 16.0], up)
        return (dict(DARK, shot="low", cam={"pos": cam, "look": look, "fov": 60 - 6 * up}, exposure=3.2, door=OPEN, glow=1.0 + 1.8 * up),
                him(OVER, facing(OVER, cam), "Stare", t=3.0 + stop(i), Duck=1.25, Look=[0.0, -0.55], Scream=0.15 * ease((i - 55) / 10)))
    w = ease((i - 65) / 5)
    cam = add(EYE9, [0.14 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0])
    p = lerp(OVER, [-25.0, G, 15.2], w)
    return (dict(DARK, shot="low", cam={"pos": cam, "look": lerp([-25.0, G + 6.4, 16.0], [-25.0, G + 5.0, 13.0], w), "fov": 54 + 10 * w},
                 exposure=3.2, door=OPEN, glow=4.0, flash=fl(cam, [-25.0, G + 5.6, 14.0], 6.0 * w, 0.5)),
            him(p, facing(p, cam), "Reach", t=3.0 + i / FPS, Scream=1.0, Duck=1.25 + 1.1 * w, Look=[0.0, -0.5 * w]))
shot("knew", 75, s_over)

# 10. RUN: for the arch past the table's end, looking back: he's round the island and after me on all fours
def s_run(i, k):
    cam = [lerp([-19.0, 0, 20.5], [-13.0, 0, 25.0], k)[0] + 0.25 * math.sin(i * 1.7), G + 5.0 + 0.2 * math.sin(i * 2.3),
           lerp([-19.0, 0, 20.5], [-13.0, 0, 25.0], k)[2]]
    hp = lerp([-21.0, G, 12.0], [-20.0, G, 17.5], k)
    return (dict(DARK, shot="arch", cam={"pos": cam, "look": [hp[0], G + 2.8, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)}, door=OPEN,
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), G + 3.2, hp[2]], 14.0, 0.36), exposure=2.0, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
