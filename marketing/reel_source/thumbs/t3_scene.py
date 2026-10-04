import json, math
cr = {"f": 0, "pos": [5.0, 15.0, 3.0], "yaw": math.pi + 0.1, "gait": "Stare", "t": 0.5, "duck": 0.4, "neck": [0.15, 0.0, 0.35]}
STAND = {"lHip": 0.0, "rHip": 0.0}
AVS = [
    {"pos": [3.9, 17.91, 14.2], "yaw": math.pi - 0.35, "face": "scared",
     "pose": dict(STAND, neckY=0.25, rShoulder=[0.4, 0, -0.1], rElbow=0.4, lShoulder=[0.25, 0, 0.1], lElbow=0.3),
     "colors": {"hoodie": "#2f7de0", "hoodieDark": "#215ca8", "pants": "#2a2a33", "hair": "#e0b25a"}},
    {"pos": [6.4, 17.91, 15.2], "yaw": math.pi + 0.05, "face": "scared",
     "pose": dict(STAND, neckX=0.05, rShoulder=[0.35, 0, -0.1], rElbow=0.6, lShoulder=[0.3, 0, 0.1], lElbow=0.5),
     "colors": {"hoodie": "#d6363c", "hoodieDark": "#a8262d", "pants": "#2b3b5c", "hair": "#3b2416"},
     "flashlight": {"target": [5.0, 22.5, 3.0], "intensity": 18}},
    {"pos": [8.8, 17.91, 14.0], "yaw": math.pi + 0.4, "face": "scared",
     "pose": dict(STAND, neckY=-0.3, rShoulder=[0.2, 0, -0.1], rElbow=0.3, lShoulder=[0.5, 0, 0.3], lElbow=1.2),
     "colors": {"hoodie": "#3fae5a", "hoodieDark": "#2c8043", "pants": "#3a3a40", "hair": "#141012", "skin": "#8d5a3b"}},
]
SHOTS = {"hall": {"center": [6, 22, 8], "radius": 44, "lampRadius": 0, "maxLamps": 0,
                  "lights": [
                      {"p": [6.5, 21.5, 21.0], "col": "#dfe8ff", "b": 2.4, "r": 12},       # key on their faces
                      {"p": [6, 20, 9], "col": "#ff2a2a", "b": 1.6, "r": 9, "decay": 1.6}, # red rim from behind
                      {"p": [6, 22, -6], "col": "#4b5f96", "b": 2.0, "r": 22},
                      {"p": [5.0, 24.0, 7.0], "col": "#b8c8ff", "b": 1.6, "r": 6, "decay": 1.6},
                      {"p": [12, 21, 10], "col": "#4a5c90", "b": 1.2, "r": 14},
                  ]}}
frames = [{"f": 0, "shot": "hall", "cam": {"pos": [6.3, 22.4, 24.2], "look": [6.0, 20.8, 6.0], "fov": 46}, "creature": True,
           "ambient": 0.12, "exposure": 2.2, "bg": 0x020203, "glow": 9}]
cr["f"] = 0
json.dump([cr], open("frames_in.json", "w"))
json.dump({"W": 1920, "H": 1080, "shots": SHOTS, "frames": frames, "avatars": AVS}, open("spec.json", "w"))
print("ok")
