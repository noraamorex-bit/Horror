# Reel 51 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #6" (the new run, after #5 = reel 50): #2's exact format, look,
# music and slot lengths, and #12's recipe (46.7K: the v112 look, no mask, him in almost every clip). The chapter: Lily's
# new friend. Every night he's in my little sister's room: in the corner, at her dollhouse, bent over her bed, saying
# goodnight from her doorway... so tonight i slept in her room. 3 am her music box opened, and someone was at her tea party.
#   hook (105)  Lily's room, the light on: the tea party, her bed, cosy
#   card (120)  the same room in the dark, a slow push to the tea table
#   72  "night 23: lily said she made a friend."  from her bed: lightning, him standing in the far corner
#   33  "night 24: he played with her dollhouse."  him folded down at her dollhouse, looking in its windows
#   90  "night 25: he watched her sleep."         him bent over her bed in the moonlight, his head laid over
#   60  "night 26: he said goodnight."            from her bed: him stooped in her doorway
#   60  "so tonight i slept in her room."         on the floor by her bed, her night light, the door shut
#   60  "3 am. her music box opened."             the lid lifts by itself
#   75  "someone was at her tea party."           sit up, turn: him hunched over her little table, his back to you; his head
#                                                 turns right round, the maw tears open and he comes (22.15 s)
#   30  "RUN."                                    out in the hall, him through her door after you on all fours
# python3 scene.py [preview]. Writes spec.json, frames_in.json (tools/creature/skin_frames.luau), shots.json.
import json, math, os, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.6
TAU = math.tau
S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
SIGN = float(os.environ.get("SIGN", "-1"))       # (his head turns round to his right, over the shoulder: probed)

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

COLD, MOON, PINK, WARM = "#3d4f7a", "#6f86c4", "#ff9fc4", "#ffd9a0"
# --- Lily's room (World, the v101 lived-in layer; reel 35): x 12..40, z 8.5..29.3, ceiling ~U+12.7. Her door in the x = 12
# wall at z = 20 (hinged at z = 17.55); the window in the z = 29.3 wall at x = 26; her bed x 32..38.5, z 22.2..29.1 (the
# headboard at z = 29.1, its open side at x = 32); the tea table at (24, 15.2) with three little chairs (W, N, E: the south
# side is open); her tent at (20.2, 10.6); the dollhouse at (30.4, 9.8), its front at z = 10.9; the closet at x 13.7..17.7,
# z 11.5; the music box on the dresser at (18.9, U + 3.09, 28.1)
TABLE = [24.0, U, 15.2]
MUSICBOX = {"near": [18.9, U + 3.09, 28.1], "r": 0.8, "names": ["MusicBoxLid"], "hinge": [0, U + 3.09, 28.53], "axis": "x"}
LILYDOOR = {"near": [12.0, U + 4.7, 20.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [12.0, 0, 17.55], "axis": "y"}
NOCANDY = ["CandyWrap", "CandyBody"]
ROOM = [{"p": [13.6, U + 2.2, 27.5], "col": PINK, "b": 1.6, "r": 16, "decay": 1.3},          # her night light
        {"p": [26.0, U + 8.0, 31.5], "col": MOON, "b": 3.4, "r": 24, "decay": 1.1},           # the window
        {"p": [30.0, U + 8.0, 12.0], "col": COLD, "b": 1.2, "r": 16}]
HALL = [{"p": [6, U + 8, 18], "col": COLD, "b": 1.6, "r": 16}]
SHOTS = {
    "lit": {"center": [26, U + 5, 19], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR, "hide": NOCANDY,
            "lights": [{"p": [26, U + 11.0, 19], "col": WARM, "b": 4.2, "r": 32, "decay": 1.0}] + ROOM},
    "room": {"center": [26, U + 5, 19], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR, "hide": ["Bulb", "Globe", "Base", "Finial"] + NOCANDY,
             "lights": ROOM + HALL},
    "box": {"center": [24, U + 4, 22], "radius": 28, "lampRadius": 0, "maxLamps": 0, "door": MUSICBOX, "hide": ["Bulb"] + NOCANDY, "lights": ROOM},
    # (her dollhouse: a light on inside it, on his face from below)
    "doll": {"center": [28, U + 4, 13], "radius": 26, "lampRadius": 0, "maxLamps": 0, "hide": ["Bulb"] + NOCANDY,
             "lights": ROOM + [{"p": [30.4, U + 1.6, 10.4], "col": WARM, "b": 1.6, "r": 7, "decay": 1.4}, {"p": [30.4, U + 3.4, 12.2], "col": WARM, "b": 1.1, "r": 6, "decay": 1.4}]},
    # (the tea party with the music box still open: one rig per shot, so her door stays as the world has it)
    "tea": {"center": [24, U + 5, 19], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": MUSICBOX, "hide": ["Bulb", "Globe", "Base", "Finial"] + NOCANDY, "lights": ROOM},
    "hallRun": {"center": [6, U + 6, 15], "radius": 34, "lampRadius": 0, "maxLamps": 0, "door": LILYDOOR, "hide": NOCANDY,
                "lights": [{"p": [2, U + 11, -10], "col": MOON, "b": 1.8, "r": 26, "decay": 1.1}, {"p": [6, U + 8, 18], "col": COLD, "b": 1.6, "r": 16},
                           {"p": [18, U + 3, 20], "col": PINK, "b": 1.4, "r": 14}]},
}
DARK = {"ambient": 0.03, "bg": 0x010102}
LIT = {"ambient": 0.1, "bg": 0x0a0a0c, "exposure": 1.25, "lamps": 0}
extras = []

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
        fr.setdefault("hideIdx", [])
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n
def fl(cam, tgt, i=13.0, angle=0.36):
    return {"i": i, "pos": [cam[0] + 0.4, cam[1] - 0.6, cam[2]], "target": tgt, "angle": angle}

# 1. (hook) her room, the light on: the tea party and her bed
def s_hook(i, k):
    cam = add(lerp([13.8, U + EYE, 21.5], [16.5, U + EYE - 0.1, 20.8], ease(k)), hand(i, 0.6))
    return (dict(LIT, shot="lit", cam={"pos": cam, "look": lerp([26.0, U + 2.4, 15.5], [30.0, U + 2.6, 20.0], ease(k)), "fov": 62}, door=1.2), None)
shot("hook", 105, s_hook)

# 2. (card) the same room in the dark, a slow push to the tea table
def s_card(i, k):
    cam = add(lerp([13.8, U + EYE, 21.5], [18.0, U + EYE - 0.4, 19.6], ease(k)), hand(i, 0.5))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [24.5, U + 1.8, 15.0], "fov": 58}, exposure=2.6, door=1.2), None)
shot("card", 120, s_card)

# 3. "night 23: lily said she made a friend." from her bed: lightning, him standing in the far corner by her closet
BEDEYE = [35.6, U + 4.6, 26.2]
CORNER = [16.2, U, 14.0]
def s_corner(i, k):
    cam = add(BEDEYE, hand(i, 0.4))
    lt = 1.0 if 12 <= i <= 14 else (0.55 if 17 <= i <= 18 else (0.8 if 46 <= i <= 48 else 0.0))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp([18.0, U + 4.8, 14.5], [17.2, U + 5.4, 14.3], ease(k)), "fov": 44}, exposure=2.4,
                 lightning=0.9 * lt, glow=2.2, door=0.0),
            him(CORNER, facing(CORNER, cam), "Stare", t=2.0 + stop(i), Look=[0.0, -0.1]))
shot("door", 72, s_corner)

# 4. "night 24: he played with her dollhouse." him folded down at its front, looking in its windows
DOLL = [30.4, U, 13.7]
def s_doll(i, k):
    cam = add(lerp([22.4, U + 3.2, 13.8], [22.9, U + 3.2, 13.6], k), hand(i, 0.3))
    return (dict(DARK, shot="doll", cam={"pos": cam, "look": [30.4, U + 4.4, 11.8], "fov": 56}, exposure=2.6, glow=1.6),
            him(DOLL, facing(DOLL, [30.4, U, 9.8]), "Stare", t=3.0 + stop(i), Duck=1.0, Look=[0.15, -0.8]))
shot("prints", 33, s_doll)

# 5. "night 25: he watched her sleep." him bent over her bed in the moonlight, his head laid over
# (at the foot of her bed, bent over it, seen from beside her pillow)
BEDFOOT = [35.2, U, 20.4]
def s_sleep(i, k):
    cam = add(lerp([31.0, U + 4.6, 28.0], [31.3, U + 4.5, 27.3], ease(k)), hand(i, 0.4))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [35.6, U + 7.0, 20.6], "fov": 60}, exposure=2.6, glow=2.0, door=0.0),
            him(BEDFOOT, facing(BEDFOOT, [35.2, U, 26.0]), "Stare", t=2.0 + stop(i), Duck=0.85, Look=[0.0, -0.45]))
shot("photo", 90, s_sleep)

# 6. "night 26: he said goodnight." from her bed: him stooped in her doorway, the hall's light behind him
DOORWAY = [13.0, U, 20.0]
def s_night(i, k):
    cam = add([33.4, U + 4.4, 24.4], hand(i, 0.3))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp([13.2, U + 6.0, 20.0], [13.2, U + 6.6, 20.0], ease(k)), "fov": 40}, exposure=2.6,
                 glow=2.4, door=1.25),
            him(DOORWAY, facing(DOORWAY, cam), "Stare", t=4.0 + stop(i), Duck=0.55, Look=[0.5, -0.2]))
shot("setup", 60, s_night)

# 7. "so tonight i slept in her room." on the floor by her bed: her night light, the door shut
FLOOR = [30.0, U + 1.6, 20.6]
def s_slept(i, k):
    cam = add(lerp([30.4, U + 1.7, 20.8], FLOOR, ease(k)), hand(i, 0.2))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": [12.5, U + 3.6, 20.0], "fov": 54}, exposure=3.0, door=0.0), None)
shot("open", 60, s_slept)

# 8. "3 am. her music box opened." the lid lifts by itself
def s_box(i, k):
    cam = add(FLOOR, hand(i, 0.25))
    lid = 1.4 * ease(min(1.0, max(0.0, (i - 8) / 26)))
    return (dict(DARK, shot="box", cam={"pos": cam, "look": [18.9, U + 3.0, 28.1], "fov": 36}, door=lid, exposure=3.0,
                 flash=fl(cam, [18.9, U + 3.0, 28.1], 3.0, 0.2)), None)
shot("stood", 60, s_box)

# 9. "someone was at her tea party." sit up and turn from the music box: him hunched over her little table, his back to you
# (13 poses a second)... his head turns right round... and he comes at you on 22.15 s (frame 64)
HUNCH = [24.0, U, 17.5]
AWAY = facing(HUNCH, TABLE)
def s_knew(i, k):
    up = ease(i / 30)
    cam = add([FLOOR[0] + 1.6 * up, FLOOR[1] + 1.8 * up, FLOOR[2] + 0.6 * up], hand(i, 0.35))
    pan = ease(i / 26)
    look0 = [18.9, U + 3.0, 28.1]
    look1 = [24.0, U + 7.0, 17.0]
    look = lerp(look0, look1, pan)
    if i < 64:
        turn = ease((stop(i) * 30 - 32) / 20)
        cr = him(HUNCH, AWAY, "Stare", t=4.0 + stop(i), Duck=0.9 - 0.4 * turn, Look=[SIGN * 2.4 * turn, -0.5 + 0.6 * turn], Scream=0.15 * ease((i - 54) / 10))
        return (dict(DARK, shot="tea", cam={"pos": cam, "look": look, "fov": 52}, exposure=2.6, glow=1.0 + 1.6 * turn, door=1.4,
                     flash=fl(cam, [24.0, U + 7.0, 17.2], 3.0 * pan, 0.3)), cr)
    w = ease((i - 64) / 5)
    near = [cam[0] - 3.4, U, cam[2] - 1.2]
    p = lerp(HUNCH, near, w)
    shake = [0.12 * math.sin(i * 2.1), 0.1 * math.sin(i * 1.7), 0]
    cr = him(p, facing(p, cam), "Reach", t=4.0 + i / FPS, Scream=1.0, Look=[0.0, -0.2])
    return (dict(DARK, shot="tea", cam={"pos": add(cam, shake), "look": lerp(look1, [p[0], U + 8.4, p[2]], w), "fov": 52 + 18 * w}, exposure=2.6,
                 glow=6.0, door=1.4, flash=fl(cam, [p[0], U + 7.0, p[2]], 9.0, 0.45)), cr)
shot("knew", 75, s_knew)

# 10. RUN: out in the hall, looking back: he comes through her door after you on all fours
def s_run(i, k):
    cam = [4.0 + 0.25 * math.sin(i * 1.7), U + 4.8 + 0.2 * math.sin(i * 2.3), 15.0 - 4.0 * k]
    hp = lerp([12.8, U, 20.0], [7.0, U, 17.0], k)
    return (dict(DARK, shot="hallRun", cam={"pos": cam, "look": [hp[0], U + 2.8, hp[2]], "fov": 64, "roll": 0.05 * math.sin(i * 0.9)}, door=1.3,
                 flash=fl(cam, [hp[0] + 0.6 * math.sin(i * 1.3), U + 3.2, hp[2]], 16.0, 0.36), ambient=0.01, exposure=2.0, glow=6),
            him(hp, facing(hp, cam), "Chase", phase=k * 4.5 * TAU, t=i / FPS))
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": extras,
           "props": {"cache": f"{S}/assets"}, "skinCache": f"{S}/mc"}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
