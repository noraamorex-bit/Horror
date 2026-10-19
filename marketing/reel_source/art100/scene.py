# v100 store art (icon + thumbnails), rendered with film2 like the reels:
#   python3 scene.py icon|thumb|thumb2 [variant]  -> spec.json + frames_in.json here
#   icon   (1024): he hangs head-first out of the attic hatch over a kid looking up, mouth open
#   thumb  (1920x1080): the same, wide, room for the title on the right
#   thumb2 (1920x1080): the upstairs hall: a kid running at you with a flashlight, him behind on all fours
# then ../tools/creature_frames2.luau + film2.mjs, and post.py for the grade, the title and the sizes.
import json, math, sys
kind = sys.argv[1] if len(sys.argv) > 1 else "icon"
U = 15.0
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
COLD, MOON, WARM = "#3d4f7a", "#6f86c4", "#ffb766"
HATCH = {"near": [6.0, 28.0, 11.0], "r": 4.5, "names": ["HatchPanel"], "hinge": [6.0, 28.15, 8.05], "axis": "x"}
NO_CORD = ["Cord", "CordHandle"]
avatars, extras = [], []
# (the folding ladder down from the hatch, as in reel 28)
WOOD = [150, 118, 80]
TOP, BOT = [9.2, 28.2], [14.3, U]
L = math.hypot(TOP[0] - BOT[0], TOP[1] - BOT[1]); RX = math.atan2(TOP[0] - BOT[0], TOP[1] - BOT[1])
for x in (5.05, 6.95):
    extras.append({"pos": [x, (TOP[1] + BOT[1]) / 2, (TOP[0] + BOT[0]) / 2], "s": [0.22, L, 0.45], "rot": [RX, 0, 0], "col": WOOD})
for k in [0.08 + i * 0.105 for i in range(9)]:
    extras.append({"pos": [6.0, BOT[1] + (TOP[1] - BOT[1]) * k, BOT[0] + (TOP[0] - BOT[0]) * k], "s": [1.8, 0.16, 0.5], "rot": [RX, 0, 0], "col": WOOD})
# hanging: feet up in the attic, the body tipped right over (pitch about the feet), arms reaching down
HANG = {"Root": [0, 0, 0], "Waist": [-0.15, 0, 0.06], "LeftShoulder": [2.7, 0, -0.3], "RightShoulder": [2.6, 0, 0.36],
        "LeftElbow": [0.35, 0, 0], "RightElbow": [0.55, 0, 0], "LeftWrist": [-0.3, 0, 0], "RightWrist": [-0.45, 0, 0],
        "LeftHip": [0.15, 0, 0], "RightHip": [0.1, 0, 0], "LeftKnee": [-0.4, 0, 0], "RightKnee": [-0.3, 0, 0]}
if kind in ("icon", "thumb"):
    # the icon: big and simple. Him folded down over a kid in the dark upstairs hall, mask a foot
    # above their head, mouth wide open, the long fingers coming round; the kid hasn't seen him
    W, H = (1024, 1024) if kind == "icon" else (1920, 1080)
    extras = []
    feet = [2.9, U, -11.2]
    kid = [4.7, U + 2.35, -4.6]
    cam = [4.4, U + 4.9, 5.5]
    look = [3.85, U + 5.75, -6.0]
    shots = {"hall": {"center": [3, U + 6, -6], "radius": 34, "lampRadius": 0, "maxLamps": 0,
                      "lights": [{"p": [2, U + 11, -29], "col": MOON, "b": 1.4, "r": 26, "decay": 1.1},
                                 {"p": [5.5, U + 8.0, -2.0], "col": "#b9ccff", "b": 2.2, "r": 8, "decay": 1.5},
                                 {"p": [0.0, U + 6.5, -9.0], "col": "#ff3b30", "b": 2.2, "r": 8},
                                 {"p": [4.6, U + 5.2, -1.6], "col": "#dfe8ff", "b": 1.4, "r": 4.5, "decay": 1.5}]}}
    frames = [{"f": 0, "shot": "hall", "creature": True, "ambient": 0.03, "bg": 0x010102, "exposure": 2.0, "glow": 8,
               "cam": {"pos": cam, "look": look, "fov": 24}}]
    if kind == "thumb":
        # (wide: the two of them on the left, the title goes on the right)
        frames[0]["cam"] = {"pos": [5.6, U + 4.9, 6.2], "look": [6.9, U + 5.5, -6.0], "fov": 27}
    crs = [{"f": 0, "pos": feet, "yaw": facing(feet, cam), "gait": "Reach", "t": 0.4, "pitch": -0.2,
            "neck": [-0.45, 0.2, -0.5], "jaw": 1.0, "hideParts": ["Fringe"]}]
    avatars.append({"pos": kid, "yaw": facing(kid, cam) + 0.15, "face": "scared",
                    "pose": {"neckX": 0.0, "neckY": 0.35, "lShoulder": [0.4, 0, -0.15], "rShoulder": [0.6, 0, 0.15], "rElbow": 0.5},
                    "flashlight": {"target": [5.0, U + 1.0, 4.0], "intensity": 6}})
elif kind == "thumb3":
    # "it's right behind you": the kid faces you, scared, phone up; he hangs head-first out of the
    # hatch just behind them, upside down, mouth wide, his arms coming down either side of them
    kid = [6.9, U + 2.35, 12.4]
    head = [4.9, U + 6.2, 14.6]
    feet = [head[0], head[1] + 9.15, head[2]]
    if kind == "icon":
        W, H = 1024, 1024
        cam = [6.0, U + 5.0, 25.5]; look = [5.9, U + 5.4, 13.0]; fov = 29
    else:
        W, H = 1920, 1080
        cam = [8.4, U + 5.2, 21.5]; look = [3.7, U + 6.0, 12.6]; fov = 44
    shots = {"hatch": {"center": [5, U + 6, 12], "radius": 30, "lampRadius": 0, "maxLamps": 0, "door": HATCH, "hide": NO_CORD,
                       "lights": [{"p": [2, U + 11, 26], "col": MOON, "b": 1.0, "r": 30, "decay": 1.1},
                                  {"p": [6, 31, 11], "col": WARM, "b": 0.6, "r": 8},
                                  {"p": [5.2, U + 6.0, 17.0], "col": "#b9ccff", "b": 2.4, "r": 6.5, "decay": 1.6},
                                  {"p": [1.5, U + 5.0, 11.5], "col": "#ff3b30", "b": 1.8, "r": 7}]}}
    frames = [{"f": 0, "shot": "hatch", "door": 1.0, "creature": True, "ambient": 0.03, "bg": 0x010102, "exposure": 2.0, "glow": 8,
               "cam": {"pos": cam, "look": look, "fov": fov}}]
    j = dict(HANG)
    j["Neck"] = [0.6, 0.0, -0.2]
    crs = [{"f": 0, "pos": feet, "yaw": facing(head, cam) + math.pi, "gait": "Stare", "t": 1.0, "pitch": math.pi, "joints": j, "jaw": 1.0, "hideParts": ["Hair"]}]
    avatars.append({"pos": kid, "yaw": facing(kid, cam), "face": "scared",
                    "pose": {"neckX": -0.05, "neckY": -0.3, "lShoulder": [0.3, 0, -0.1], "rShoulder": [0.3, 0, 0.1]}})
else:
    # running down the upstairs hall at you, flashlight thrown back at him: he's on all fours
    # right behind, mouth wide open
    W, H = 1920, 1080
    kid = [5.5, U + 2.35, 5.2]
    cam = [3.6, U + 4.2, 13.5]
    him = [2.4, U, -2.0]
    shots = {"hall": {"center": [3, U + 6, 2], "radius": 40, "lampRadius": 0, "maxLamps": 0,
                      "lights": [{"p": [2, U + 11, -29], "col": MOON, "b": 1.4, "r": 26, "decay": 1.1},
                                 {"p": [6.2, U + 5.6, 9.0], "col": "#c9d8ff", "b": 2.6, "r": 6, "decay": 1.5},
                                 {"p": [-0.5, U + 4.0, -5.0], "col": "#ff3b30", "b": 2.0, "r": 8}]}}
    frames = [{"f": 0, "shot": "hall", "creature": True, "ambient": 0.03, "bg": 0x010102, "exposure": 1.9, "glow": 8,
               "cam": {"pos": cam, "look": [3.1, U + 4.3, -1.0], "fov": 42}}]
    crs = [{"f": 0, "pos": him, "yaw": facing(him, cam) - 0.15, "gait": "Chase", "phase": 1.1, "t": 1.0, "jaw": 1.0,
            "neck": [-0.2, 0, 0], "hideParts": ["Fringe"]}]
    avatars.append({"pos": kid, "yaw": facing(kid, cam) - 0.1, "face": "scared",
                    "pose": {"neckY": 0.7, "lShoulder": [0.5, 0, -0.1], "rShoulder": [-0.4, 0, 0.1], "lHip": 0.5, "rHip": -0.4, "rKnee": 0.5, "lElbow": 1.0, "rElbow": 1.0},
                    "flashlight": {"target": [2.2, U + 3.5, -3.5], "intensity": 18}})
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": shots, "frames": frames, "avatars": avatars, "extras": extras,
           "props": {"cache": "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/assets"}}, open("spec.json", "w"))
print("ok", kind, W, H)
