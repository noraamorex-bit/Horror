# v99 store art with the new creature, rendered with film2 like the reel: python3 stills.py icon|thumb
#   icon  (1024x1024): his face tipping down into the gap of the closet doors, the grin, in the dark
#   thumb (1920x1080): down the upstairs hall in a flashlight beam: him at the end, head laid over
# Writes spec.json + frames_in.json in the current folder (then creature_frames2 + film2, as for a reel).
import json, math, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
kind = sys.argv[1] if len(sys.argv) > 1 else "icon"
U = 15.0
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
COLD, MOON = "#3d4f7a", "#6f86c4"
EYE = [10.38, U + 4.9, -5.66]
DOOR = {"near": [9.25, U + 4.5, -4.8], "r": 2.3, "names": ["WardrobeLeaf", "DoorPanel", "PanelInset"], "hinge": [9.32, 0, -3.6], "axis": "y"}
HALL = [{"p": [2, U + 11, -29], "col": MOON, "b": 3.2, "r": 30, "decay": 1.1}, {"p": [2.5, U + 9, -9], "col": "#5d72a8", "b": 3.0, "r": 20},
        {"p": [5, U + 7, -3], "col": COLD, "b": 1.2, "r": 12}]
if kind == "icon":
    W, H = 1024, 1024
    feet = [0.2, U, -6.2]
    shots = {"closet": {"center": [6, U + 5, -6], "radius": 30, "lampRadius": 0, "maxLamps": 0, "hide": ["Handle"], "door": DOOR, "lights": HALL}}
    frames = [{"f": 0, "shot": "closet", "door": 1.0, "creature": True, "ambient": 0.02, "bg": 0x010102, "exposure": 2.3, "glow": 8,
               "cam": {"pos": EYE, "look": [7.3, U + 5.5, -6.1], "fov": 36},
               "flash": {"i": 6.0, "pos": [EYE[0] - 0.2, EYE[1] - 0.8, EYE[2] + 0.3], "target": [7.3, U + 5.5, -6.1], "angle": 0.35}}]
    crs = [{"f": 0, "pos": feet, "yaw": facing(feet, EYE), "gait": "Stare", "t": 1.0, "pitch": -0.92, "neck": [0.92, 0.0, -0.75]}]
else:
    W, H = 1920, 1080
    him = [2.6, U, -14.0]
    cam = [3.6, U + 5.2, 3.0]
    shots = {"hallFar": {"center": [2, U + 6, -6], "radius": 46, "lampRadius": 0, "maxLamps": 0,
                         "lights": [{"p": [2, U + 11, -29], "col": MOON, "b": 1.8, "r": 26, "decay": 1.1}]}}
    frames = [{"f": 0, "shot": "hallFar", "creature": True, "ambient": 0.02, "bg": 0x010102, "exposure": 1.7, "glow": 7,
               "cam": {"pos": cam, "look": [2.5, U + 5.6, -14.0], "fov": 44},
               "flash": {"i": 14.0, "pos": [cam[0] + 0.5, cam[1] - 0.6, cam[2]], "target": [2.6, U + 6.2, -14.0], "angle": 0.17}}]
    crs = [{"f": 0, "pos": him, "yaw": facing(him, cam), "gait": "Stare", "t": 1.0, "neck": [0.0, 0.0, 0.0]}]
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": shots, "frames": frames, "avatars": [], "extras": [],
           "props": {"cache": "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad/assets"}}, open("spec.json", "w"))
print("ok", kind, W, H)
