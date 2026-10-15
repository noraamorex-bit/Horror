# Reel 26 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 4)": Parts 2-3's format on #2's track
# (every clip keeps #2's length, so the track's cuts and hits land). The story this time: hiding under
# the master bed, watching him through the slit between the bed and the floor.
#   hook (105)  the master bedroom in the dark, the flashlight finding the bed
#   card (120)  downstairs: the fire burning low in the living room, nobody there
#   72          out of the bedroom window, a lightning flash: someone on the front lawn, looking up
#   33          the bedroom lamp flickers and dies
#   90          down on the floor and under the bed: the slit of the room between the frame and the floor
#   60          from under the bed: the bedroom door swings open, someone in the doorway
#   60          his feet come across the room, right up to the bed
#   60          they turn and walk round the side, out of sight
#   75          nothing... creeping to the edge... and the bed is torn up off you (the scare at 22.15 s)
#   30          RUN: from the bottom of the stairs, and he's coming down them
# python3 scene.py [preview]. Writes spec.json, frames_in.json, shots.json.
import json, math, sys
PREVIEW = len(sys.argv) > 1 and sys.argv[1] == "preview"
FPS = 30
G, U = 1.0, 15.0
EYE = 5.6
WALK = math.tau / 5.2
RUN = math.tau / 7.5

def lerp(a, b, k): return [a[i] + (b[i] - a[i]) * k for i in range(len(a))]
def ease(k): k = max(0.0, min(1.0, k)); return k * k * (3 - 2 * k)
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def hand(i, amt=1.0):
    return [0.05 * amt * math.sin(i * 0.11), 0.04 * amt * math.sin(i * 0.17 + 1), 0.03 * amt * math.sin(i * 0.07 + 2)]
def add(a, b): return [a[j] + b[j] for j in range(3)]

COLD = "#3d4f7a"
MOON = "#6f86c4"
# the master bed: head against the west wall (x = -39.15), foot at x = -30.15, z -18.25..-10.75; the
# frame's underside is 1.6 above the floor; skirts close the head and the two long sides, so from
# under it you see out of the foot end only
BED_NAMES = ["BedFrame", "RailLip", "BedPost", "PostCap", "Finial", "Headboard", "HeadboardPanel", "HeadRail",
             "Footboard", "FootRail", "Mattress", "Duvet", "DuvetDrape", "DuvetFoot", "Turndown", "Pillow",
             "AccentPillow", "Throw", "ThrowDrape", "ThrowFold", "ThrowStripe", "Fringe", "BedSkirt"]
BED_RIG = {"near": [-34.7, U + 2.5, -14.5], "r": 7.2, "names": BED_NAMES, "hinge": [-39.3, U, 0], "axis": "z"}
# the bedroom door: hinged at its south edge (z = -12.42), swings into the room (-x)
DOOR_RIG = {"near": [-8.0, U + 4.7, -10.0], "r": 3.0, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, -12.42], "axis": "y"}
UNDER = [-32.4, U + 0.78, -14.5]          # the eye under the bed, a couple of studs in from the foot
UNDER_LOOK = [-8.0, U + 1.9, -12.6]
ROOM_LIGHTS = [{"p": [-24, U + 9, -33], "col": MOON, "b": 2.6, "r": 34, "decay": 1.1},   # moonlight through the front windows
               {"p": [-14, U + 6, -20], "col": COLD, "b": 1.1, "r": 18}]
HALL_SPILL = {"p": [-4.5, U + 7, -10], "col": "#5d72a8", "b": 2.6, "r": 16}            # the hall behind the door
SHOTS = {
    "room": {"center": [-24, U + 5, -15], "radius": 30, "lampRadius": 0, "maxLamps": 0, "lights": ROOM_LIGHTS},
    "roomOn": {"center": [-24, U + 5, -15], "radius": 30, "lampRadius": 30, "maxLamps": 4, "lights": ROOM_LIGHTS},
    "fire": {"center": [-28, G + 5, -12], "radius": 30, "lampRadius": 0, "maxLamps": 0,
             "lights": [{"p": [-36.6, G + 2.4, -12], "col": "#ff8a3c", "b": 7.0, "r": 26, "decay": 1.3},
                        {"p": [-24, G + 8, -30], "col": COLD, "b": 0.6, "r": 20}]},
    "window": {"center": [-28, U, -38], "radius": 140, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [-26, U + 12, -55], "col": MOON, "b": 1.6, "r": 40, "decay": 1.0}]},
    "under": {"center": [-24, U + 3, -14], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": DOOR_RIG,
              "lights": ROOM_LIGHTS + [HALL_SPILL]},
    "torn": {"center": [-24, U + 3, -14], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": BED_RIG,
             "lights": ROOM_LIGHTS + [{"p": [-26, U + 9, -14], "col": "#7f93cc", "b": 1.4, "r": 18}]},
    "stairs": {"center": [-5, G + 6, 2], "radius": 36, "lampRadius": 0, "maxLamps": 0,
               "lights": [{"p": [-5, U + 6, 14], "col": "#2c3d6e", "b": 1.5, "r": 26}, {"p": [-5, G + 7, -8], "col": COLD, "b": 1.0, "r": 16}]},
}
DARK = {"ambient": 0.02, "bg": 0x010102}
frames, crs, shots = [], [], []
f = 0
def shot(name, n, fn):
    global f
    shots.append({"name": name, "start": f, "n": n})
    idx = [0, n // 2, n - 1] if PREVIEW else range(n)
    for i in idx:
        k = i / max(1, n - 1)
        fr, cr = fn(i, k)
        fr["f"] = f + i
        fr["creature"] = cr is not None
        frames.append(fr)
        if cr: cr["f"] = f + i; crs.append(cr)
    f += n

# 1. (hook) into the master bedroom: a slow push, the flashlight finding the bed, then the dark under it
def s_hook(i, k):
    cam = add(lerp([-11.0, U + EYE, -11.0], [-19.5, U + EYE - 0.3, -13.0], ease(k)), hand(i))
    tgt = lerp([-30.0, U + 4.0, -14.5], [-30.2, U + 1.1, -14.5], ease(min(1.0, k * 1.3)))
    return (dict(DARK, shot="room", cam={"pos": cam, "look": lerp([-34.0, U + 3.0, -14.5], [-31.5, U + 2.3, -14.5], ease(k)), "fov": 62},
                 flash={"i": 13.0, "pos": [cam[0], cam[1] - 0.6, cam[2] + 0.5], "target": tgt, "angle": 0.34}, exposure=1.9), None)
shot("hook", 105, s_hook)

# 2. (card) downstairs: the fire burning low, the living room empty
def s_fire(i, k):
    cam = add(lerp([-22.5, G + EYE, -5.0], [-25.0, G + EYE - 0.3, -7.0], ease(k)), hand(i, 0.6))
    flick = 0.82 + 0.12 * math.sin(i * 0.9) + 0.06 * math.sin(i * 2.3 + 1)
    return (dict(DARK, shot="fire", cam={"pos": cam, "look": [-37.5, G + 3.0, -12.0], "fov": 60}, exposure=1.9, xl=flick), None)
shot("card", 120, s_fire)

# 3. out of the bedroom window: a lightning flash, and someone on the front lawn, looking up
HIM_LAWN = [-25.0, 0.5, -47.0]
def s_window(i, k):
    cam = add([-31.6, U + EYE + 0.3, -29.1], hand(i, 0.4))
    lt = 1.0 if 18 <= i <= 21 else (0.6 if 49 <= i <= 51 else 0.0)
    return (dict(DARK, shot="window", cam={"pos": cam, "look": [-25.5, 3.0, -47.0], "fov": 46}, exposure=1.7, lightning=lt, glow=6, moon=0.12),
            {"pos": HIM_LAWN, "yaw": facing(HIM_LAWN, cam), "gait": "Stare", "t": i / 30, "neck": [-0.35, 0.0, 0.2]})
shot("window", 72, s_window)

# 4. the bedroom lamp flickers and dies
def s_out(i, k):
    on = i < 9 and (i * 7919) % 5 < 3
    return (dict(DARK, shot="roomOn" if on else "room", cam={"pos": [-20.0, U + EYE, -6.0], "look": [-32.0, U + 2.5, -16.0], "fov": 62},
                 lamps=1 if on else 0, ambient=0.07 if on else 0.03, exposure=1.3 if on else 2.1, lightning=0), None)
shot("out", 33, s_out)

# 5. down on the floor and under the bed, turning round to look out of the foot end
def s_under(i, k):
    a = ease(min(1.0, k / 0.45))
    cam = lerp([-24.0, U + EYE, -15.5], [-29.2, U + 1.0, -14.6], a)        # crouch down at the foot
    cam = lerp(cam, UNDER, ease((k - 0.45) / 0.3))                         # slide in
    turn = ease((k - 0.62) / 0.33)
    ang = math.pi * (1 - turn)                                            # facing in (-x), then out (+x)
    look = [cam[0] + 6 * math.cos(ang), U + (1.0 if k < 0.45 else 0.9) + 0.6 * turn, cam[2] - 0.8 * math.sin(ang)]
    if k < 0.35:
        look = lerp([-31.0, U + 1.2, -14.5], look, ease(k / 0.35))
    fl = {"i": 10.0 * (1 - ease((k - 0.5) / 0.25)), "pos": [cam[0], cam[1] - 0.3, cam[2] + 0.4], "target": [cam[0] + 6 * math.cos(ang), U + 0.6, cam[2]], "angle": 0.5}
    return (dict(DARK, shot="under", cam={"pos": add(cam, hand(i, 0.6)), "look": look, "fov": 64}, exposure=2.2, flash=fl), None)
shot("in", 90, s_under)

def under(i, extra=None, door=0.0):
    fr = dict(DARK, shot="under", cam={"pos": [UNDER[0], UNDER[1] + 0.02 * math.sin(i * 0.31), UNDER[2]], "look": UNDER_LOOK, "fov": 60},
              exposure=2.4, glow=4, door=door)
    if extra: fr.update(extra)
    return fr

# 6. from under the bed: the door swings open; someone in the doorway
DOORWAY = [-9.6, U, -10.6]
def s_door(i, k):
    d = -1.45 * ease(min(1.0, k / 0.55))
    cr = {"pos": DOORWAY, "yaw": facing(DOORWAY, UNDER), "gait": "Stare", "t": i / 30, "neck": [0.1, 0.0, 0.25]} if k > 0.35 else None
    return (under(i, {"glow": 5}, door=d), cr)
shot("door", 60, s_door)

# 7. his feet come across the room, right up to the foot of the bed
FOOT = [-28.3, U, -14.2]
def s_cross(i, k):
    w = ease(min(1.0, k * 1.08))
    p = lerp(DOORWAY, FOOT, w)
    return (under(i, {"glow": 5}, door=-1.45), {"pos": p, "yaw": facing(p, FOOT if w < 0.98 else UNDER), "gait": "Walk" if w < 0.97 else "Stare",
                                                "phase": w * 19 * WALK / 1.0, "t": i / 30})
shot("cross", 60, s_cross)

# 8. they turn and walk off round the side of the bed (out of the slit)
def s_side(i, k):
    turn = ease(min(1.0, k / 0.3))
    w = ease((k - 0.25) / 0.75)
    p = lerp(FOOT, [-28.6, U, -6.0], w)
    yaw = facing(FOOT, UNDER) + (facing(FOOT, [-28.6, U, -6.0]) - facing(FOOT, UNDER)) * turn
    return (under(i, {"glow": 4}, door=-1.45), {"pos": p, "yaw": yaw, "gait": "Walk" if 0.25 < k < 0.97 else "Stare", "phase": w * 8 * WALK, "t": i / 30})
shot("side", 60, s_side)

# 9. nothing... creep to the edge... and the bed is torn up off you (22.15 s: frame 64 of this shot)
REVEAL = [-28.2, U, -13.4]
def s_tear(i, k):
    if i < 64:
        c = ease(i / 60)
        cam = lerp(UNDER, [-31.0, U + 0.75, -14.4], c)
        fr = under(i, {"glow": 3, "exposure": 2.5}, door=-1.45)
        fr["cam"] = {"pos": add(cam, [0, 0.015 * math.sin(i * 0.5), 0]), "look": lerp(UNDER_LOOK, [-8.0, U + 2.6, -11.5], c), "fov": 60}
        return (fr, None)
    j = i - 64
    lift = 1.05 * ease(j / 2.5) + 0.05 * ease((j - 3) / 8)
    cam = [-31.0, U + 0.75, -14.4]
    fr = dict(DARK, shot="torn", cam={"pos": cam, "look": [-27.4, U + 7.8, -13.4], "fov": 66}, exposure=2.6, glow=10, door=lift)
    return (fr, {"pos": REVEAL, "yaw": facing(REVEAL, cam), "gait": "Reach", "t": i / 30, "duck": 1.0, "neck": [0.0, 0.0, 0.45 + 0.1 * math.sin(i * 0.9)]})
shot("tear", 75, s_tear)

# 10. RUN: at the bottom of the stairs, looking back up, and he's coming down them
def s_run(i, k):
    cam = [-5.0 + 0.25 * math.sin(i * 1.7), G + 4.8 + 0.2 * math.sin(i * 2.3), -10.5]
    z = 12.0 - 13.0 * k
    y = max(G, 2.05 + 0.625 * (z + 5.3) - 1.0)
    return (dict(DARK, shot="stairs", cam={"pos": cam, "look": [-5.0, G + 7.5 - 2.5 * k, 6.0], "fov": 62, "roll": 0.05 * math.sin(i * 0.9)},
                 flash={"i": 18.0, "pos": [cam[0] + 0.6, cam[1] - 0.6, cam[2]], "target": [-5.0 + 1.2 * math.sin(i * 1.3), y + 4.0, z], "angle": 0.36},
                 ambient=0.01, exposure=1.7, glow=8),
            {"pos": [-5.0, y, z], "yaw": facing([-5.0, y, z], [-5.0, y, z - 10]), "gait": "Chase", "phase": k * 15 * RUN, "t": i / 30})
shot("run", 30, s_run)

W, H = (360, 640) if PREVIEW else (1080, 1920)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "avatars": [], "extras": [],
           "props": {"cache": "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/assets"}}, open("spec.json", "w"))
json.dump(shots, open("shots.json", "w"))
print("ok", f, "frames", round(f / FPS, 2), "s;", "preview" if PREVIEW else "full")
