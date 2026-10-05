# Reel 9 (group chat): Maya's video call (her in bed, him lowering out of the hatch behind her),
# and the photo she sends of the open hatch.
import json, math
S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
src = open(f'{S}/icon4/scene.py').read()
exec(src[:src.index('# --- the avatar')])          # bedroom set: hatch, panel, cord (-> ex, cr, OFF_HEAD)
box([-34.2, TOP + 0.95, 15.95], [5.2, 1.3, 2.9], [34, 52, 100], rough=0.95)    # duvet
MAYA = {"pos": [-36.9, 19.32, 15.95], "yaw": -math.pi / 2 - 0.08, "face": "scared",
        "pose": {"waist": -0.05, "neckX": -0.12, "neckY": 0.0, "neckZ": 0.0,
                 "lShoulder": [0.25, 0, 0.12], "lElbow": 0.6, "rShoulder": [1.25, 0, -0.25], "rElbow": 0.25,
                 "lHip": math.pi / 2, "rHip": math.pi / 2, "lKnee": 0.0, "rKnee": 0.0},
        "colors": {"hoodie": "#2f7de0", "hoodieDark": "#215ca8", "pants": "#2a2a33", "hair": "#e0b25a"}}
SHOTS = {"room": {"center": [-33, 22, 18], "radius": 40, "lampRadius": 0, "maxLamps": 0,
                  "lights": [{"p": [-36, 25, 26], "col": "#3a5688", "b": 2.4, "r": 30},
                             {"p": [-30, 23, 9], "col": "#2a3a60", "b": 1.2, "r": 24},
                             {"p": [-34.0, 21.0, 16.0], "col": "#cfe0ff", "b": 1.3, "r": 6, "decay": 1.8},     # her phone screen
                             {"p": [-35.8, 25.6, 13.6], "col": "#9fb6e6", "b": 0.45, "r": 6, "decay": 1.6}]}}
def creature(f, head_y):
    head = [-38.3, head_y, 14.25]
    piv = [head[0] - OFF_HEAD[0], head[1] - OFF_HEAD[1], head[2] - OFF_HEAD[2]]
    c = dict(cr); c["f"] = f; c["pos"] = piv; return c
frames, crs = [], []
N = 105
for i in range(N):                   # the call: he's peeking, then lowers himself toward her
    k = max(0.0, (i - 25) / (N - 26))
    hy = 27.1 - 2.9 * (k * k * (3 - 2 * k))
    sh = 0.02
    cam = [-33.9 + sh * math.sin(i * 1.7), 21.4 + sh * math.sin(i * 2.3 + 1), 16.0 + sh * math.sin(i * 1.1 + 2)]
    frames.append({"f": i, "shot": "room", "cam": {"pos": cam, "look": [-37.6, 24.3, 15.3], "fov": 80},
                   "creature": True, "ambient": 0.07, "exposure": 1.55, "bg": 0x020203, "glow": 6})
    crs.append(creature(i, hy))
# the photo: looking up at the open hatch from the bed
frames.append({"f": N, "shot": "room", "cam": {"pos": [-35.2, 21.2, 15.0], "look": [-38.4, 27.6, 14.3], "fov": 64},
               "creature": True, "ambient": 0.07, "exposure": 1.6, "bg": 0x020203, "glow": 6})
crs.append(creature(N, 27.6))
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": 1080, "H": 1920, "shots": SHOTS, "frames": frames, "extras": ex, "avatars": [MAYA]}, open("spec.json", "w"))
print("ok", len(frames))
