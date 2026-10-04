import json, math
HEAD = [5.45, 23.75, 12.6]
PIV = [HEAD[0] + 0.63, HEAD[1] + 7.33, HEAD[2] - 0.38]
cr = {"f": 0, "pos": PIV, "yaw": 0.0, "pitch": math.pi, "gait": "Stare", "t": 0.3, "neck": [0.0, 0.0, -0.32]}
AV = {"pos": [6.1, 17.91, 15.3], "yaw": math.pi + 0.12, "face": "scared",
      "pose": {"neckX": 0.05, "neckY": 0.0, "neckZ": -0.06,
               "rShoulder": [0.55, 0.0, -0.12], "rElbow": 0.5, "lShoulder": [0.2, 0, 0.1], "lElbow": 0.35,
               "lHip": 0.0, "rHip": 0.0},
      "colors": {"hoodie": "#2f7de0", "hoodieDark": "#215ca8", "pants": "#2a2a33", "hair": "#e0b25a"},
      "flashlight": {"target": [9.0, 15.0, 24.0], "intensity": 12}}
SHOTS = {"hall": {"center": [6, 24, 9], "radius": 44, "lampRadius": 0, "maxLamps": 0, "hide": ["HatchPanel", "Cord", "CordHandle"],
                  "lights": [
                      {"p": [9.5, 21, 24], "col": "#8fb0ff", "b": 2.2, "r": 18},          # cold fill from the camera side
                      {"p": [6.0, 19.5, 11.5], "col": "#ff2a2a", "b": 1.6, "r": 7, "decay": 1.6},  # red rim from behind them
                      {"p": [6.4, 21.0, 18.6], "col": "#dfe8ff", "b": 2.6, "r": 6, "decay": 1.6},  # key light on the face
                      {"p": [6, 26.6, 15.2], "col": "#c8d6ff", "b": 1.4, "r": 6, "decay": 1.6},   # on his mask
                      {"p": [-4, 20, 4], "col": "#3b4766", "b": 1.2, "r": 24},
                      {"p": [6, 22, 2], "col": "#5a6ea8", "b": 2.4, "r": 22},              # the hall beyond, cold
                      {"p": [10, 21, 14], "col": "#4a5c90", "b": 1.6, "r": 14},
                  ]}}
frames = [{"f": 0, "shot": "hall", "cam": {"pos": [7.4, 19.9, 21.6], "look": [5.9, 21.8, 13.4], "fov": 48}, "creature": True,
           "ambient": 0.12, "exposure": 2.2, "bg": 0x020203, "glow": 9}]
cr["f"] = 0
json.dump([cr], open("frames_in.json", "w"))
json.dump({"W": 1920, "H": 1080, "shots": SHOTS, "frames": frames, "avatars": [AV]}, open("spec.json", "w"))
print("ok", PIV)
