# Reel 8 (#4): three fresh shots. S1 the friends in the upstairs hall with him right behind them,
# S2 him standing over the friend who went to bed first, S3 him in the corner of the parents' room.
import json, math
S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
src = open(f'{S}/icon4/scene.py').read()
exec(src[:src.index('# --- the avatar')])                 # the bedroom set: hatch, panel, cord (-> ex)
ex_room = ex
t3 = {}
exec(open(f'{S}/thumbs/t3/scene.py').read().split('SHOTS =')[0].replace('import json, math', ''), {'math': math}, t3)
spec_reel = json.load(open(f'{S}/reel/spec_reel.json'))
SHOTS = {
    "hall": {"center": [6, 22, 8], "radius": 44, "lampRadius": 0, "maxLamps": 0,
             "lights": [{"p": [6.5, 21.5, 21.0], "col": "#dfe8ff", "b": 2.0, "r": 12},
                        {"p": [6, 22, -6], "col": "#4b5f96", "b": 2.0, "r": 22},
                        {"p": [5.0, 24.0, 6.0], "col": "#b8c8ff", "b": 0.8, "r": 6, "decay": 1.6},
                        {"p": [12, 21, 10], "col": "#4a5c90", "b": 1.2, "r": 14}]},
    "room": {"center": [-33, 22, 18], "radius": 40, "lampRadius": 0, "maxLamps": 0,
             "lights": [{"p": [-36, 25, 26], "col": "#3a5688", "b": 2.6, "r": 30},
                        {"p": [-30, 23, 9], "col": "#2a3a60", "b": 1.4, "r": 24},
                        {"p": [-35.0, 23.0, 17.5], "col": "#9fb6e6", "b": 1.1, "r": 7, "decay": 1.6}]},   # moonlight across the bed
    "master": dict(spec_reel["shots"]["master"]),
}
SHOTS["master"]["lights"] = SHOTS["master"]["lights"] + [{"p": [-13, 21, -5], "col": "#8ea4d6", "b": 0.6, "r": 7, "decay": 1.6}]
AVS = list(t3["AVS"])
AVS.append({"pos": [-35.6, 19.25, 15.8], "yaw": -math.pi / 2, "pitch": math.pi / 2,
            "pose": {"neckX": 0.1}, "colors": {"hoodie": "#f0a020", "hoodieDark": "#c07a10", "hair": "#6b4423"}})
ex = [e for e in ex_room if not (e["shape"] == "box" and e["s"] == [5.2, 1.3, 2.9])]
ex.append({"shape": "box", "pos": [-32.4, 19.35, 15.8], "s": [5.4, 1.2, 3.2], "col": [40, 58, 104], "rot": [0, 0, 0], "rough": 0.95})
frames, crs = [], []
f = 0
for i in range(195):
    k = i / 194
    frames.append({"f": f, "shot": "hall", "cam": {"pos": [6.3 - 0.5 * math.sin(k * 2), 22.0, 24.4 - 1.6 * k], "look": [6.0, 20.0, 6.0], "fov": 72},
                   "creature": True, "ambient": 0.1, "exposure": 2.0, "bg": 0x020203, "glow": 8})
    crs.append({"f": f, "pos": [5.0, 15.0, 3.0], "yaw": math.pi + 0.1, "gait": "Stare", "t": 0.5, "duck": 0.4, "neck": [0.15, 0.04 * math.sin(i / 25), 0.35]})
    f += 1
for i in range(135):
    k = i / 134
    frames.append({"f": f, "shot": "room", "cam": {"pos": [-29.0 - 0.7 * k, 24.6, 19.6 - 0.4 * k], "look": [-35.8, 20.0, 14.4], "fov": 70},
                   "creature": True, "ambient": 0.07, "exposure": 1.8, "bg": 0x020203, "glow": 6})
    crs.append({"f": f, "pos": [-34.6, 14.9, 12.2], "yaw": math.pi, "gait": "Stare", "t": 0.4, "neck": [0.5, 0.0, 0.0]})
    f += 1
for i in range(140):
    k = i / 139
    frames.append({"f": f, "shot": "master", "cam": {"pos": [-24.0 + 1.0 * k, 19.6, -27.2 + 1.0 * k], "look": [-20 + 2.0 * k, 19.6, -10], "fov": 64},
                   "creature": True, "ambient": 0.08, "moon": 0.3, "xl": 1.6, "exposure": 1.6, "bg": 0x030303, "glow": 10})
    crs.append({"f": f, "pos": [-11.5, 14.9, -3.0], "yaw": 0.25, "gait": "Stare", "t": 0.3, "neck": [0.0, 0.03 * math.sin(i / 20), 0.25]})
    f += 1
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": 1080, "H": 1920, "shots": SHOTS, "frames": frames, "extras": ex, "avatars": AVS}, open("spec.json", "w"))
print("ok", f)
