# Reel 10 (gameplay trailer): fresh first-person gameplay shots.
# A: the sleepover — three friends in the lit living room (and, if you look, him at the window).
# B: the power cut — the upstairs hall lit, flickers, goes black; the flashlight clicks on and he's there.
import json, math, random
S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
rl = json.load(open(f"{S}/reel/spec_reel.json"))
SHOTS = {"living": {"center": [-24, 6, -14], "radius": 48, "lampRadius": 30, "maxLamps": 12,
                    "lights": [{"p": [-34, 8.5, -35], "col": "#6a7fae", "b": 1.3, "r": 7, "decay": 1.6}]},
         "hall_up": dict(rl["shots"]["hall_up"], lampRadius=40, maxLamps=10)}
FLOOR = 0.95
def face(pos, cam):
    return math.atan2(-(cam[0] - pos[0]), -(cam[2] - pos[2]))
CAM_A = [-11.6, FLOOR + 5.6, -5.0]
_d = (-0.646, -0.762); _p = (0.762, -0.646)
def at(dist, off): return [CAM_A[0] + _d[0] * dist + _p[0] * off, FLOOR + 3.0, CAM_A[2] + _d[1] * dist + _p[1] * off]
AVS = []
for pos, col, pose in [
    (at(9.6, -2.3), {"hoodie": "#2f7de0", "hoodieDark": "#215ca8", "pants": "#2a2a33", "hair": "#e0b25a"},
     {"rShoulder": [0, 0, 2.7], "rElbow": 0.3, "neckY": 0.1}),                     # waving
    (at(11.2, 0.0), {"hoodie": "#d6363c", "hoodieDark": "#a8262d", "pants": "#2b3b5c", "hair": "#3b2416"},
     {"rShoulder": [0.6, 0, -0.1], "rElbow": 1.2, "lShoulder": [0.6, 0, 0.1], "lElbow": 1.2}),                   # holding something
    (at(9.8, 2.2), {"hoodie": "#3fae5a", "hoodieDark": "#2c8043", "pants": "#3a3a40", "hair": "#141012", "skin": "#8d5a3b"},
     {"neckY": -0.2}),
]:
    AVS.append({"pos": pos, "yaw": face(pos, CAM_A), "pose": pose, "colors": col})
frames, crs = [], []
YAW_WIN = math.atan2(-0.64, -0.77)
f = 0
for i in range(90):
    k = i / 89
    cam = [CAM_A[0] - 0.8 * k, CAM_A[1] + 0.06 * math.sin(i / 9), CAM_A[2] - 0.9 * k]
    look = [-26 - 2.0 * k, FLOOR + 3.6, -22 + 0.6 * k]
    frames.append({"f": f, "shot": "living", "cam": {"pos": cam, "look": look, "fov": 74}, "lamps": 1.0, "ambient": 0.24, "exposure": 1.05, "bg": 0x050506, "creature": True})
    crs.append({"f": f, "pos": [-34.2, 0.4, -32.0], "yaw": YAW_WIN, "gait": "Stare", "t": 0.3, "neck": [0.0, 0.0, 0.15]})
    f += 1
B0 = f
base = rl["frames"][0]
random.seed(4)
for i in range(96):
    fr = json.loads(json.dumps(base)); fr["f"] = f
    fr["cam"]["pos"] = [2.0 + 0.04 * math.sin(i / 7), 20.6 + 0.03 * math.sin(i / 5), -23.97 + 0.012 * i]
    fr["cam"]["look"] = [2.0 + 0.15 * math.sin(i / 23), 20.6, -2]
    fr["cam"]["fov"] = 62
    if i < 28:   lamps, fl, crt = 1.0, 0, False
    elif i < 46: lamps, fl, crt = (1.0 if random.random() < 0.45 else 0.0), 0, False
    elif i < 58: lamps, fl, crt = 0.0, 0, False
    else:        lamps, fl, crt = 0.0, 14.0, True
    fr["lamps"] = lamps; fr["ambient"] = 0.18 if lamps else 0.02; fr["exposure"] = 1.15 if lamps else 1.6
    if fl:
        fr["flash"]["i"] = fl; fr["flash"]["pos"] = [fr["cam"]["pos"][0] + 0.6, fr["cam"]["pos"][1] - 0.5, fr["cam"]["pos"][2]]
        fr["flash"]["target"] = [2.0, 19.5, -2.0]
    else:
        fr["flash"]["i"] = 0
    fr["creature"] = crt
    frames.append(fr)
    crs.append({"f": f, "pos": [2, 15, -2], "yaw": 0, "gait": "Stare", "t": 0.25, "neck": [0, 0.05 * math.sin(i / 8), 0.2 if i > 75 else 0.0]})
    f += 1
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": 1080, "H": 1920, "shots": SHOTS, "frames": frames, "avatars": AVS}, open("spec.json", "w"))
print("ok", f, "B0", B0)
