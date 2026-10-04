# icon + thumbnail stills for "someone lives in our attic."
import json, math, sys
U, A = 15, 29
HATCH = {"near": [6, 28.2, 11], "r": 4.5, "names": ["HatchPanel", "Cord", "CordHandle"], "hinge": [0, 28.3, 8.05], "axis": "x"}
OPEN = float(sys.argv[1]) if len(sys.argv) > 1 else 1.9
# creature lying in the attic, head over the hatch, face down through the gap
LIE = {"pos": [6.0, A - 0.35, 19.0], "yaw": 0.0, "pitch": -math.pi / 2, "gait": "Reach", "t": 0.4, "neck": [0.35, 0.0, 0.25]}
SHOTS = {
    "hall": {"center": [6, 24, 9], "radius": 40, "lampRadius": 0, "maxLamps": 0, "hide": ["HatchPanel", "Cord", "CordHandle"],
             "lights": [{"p": [6, 33, 13], "col": "#2b3550", "b": 0.6, "r": 10}]},
    "nest": {"center": [-22, 32, 1], "radius": 34, "lampRadius": 14, "maxLamps": 2,
             "lights": [{"p": [-19, 30.4, -4], "col": "#ffb066", "b": 2.6, "r": 20}, {"p": [-22, 31.5, 4], "col": "#ff9a4d", "b": 1.0, "r": 12}]},
}
frames, cin = [], []
def add(f, shot, cam, look, fov, flash=None, cr=None, **kw):
    fr = {"f": f, "shot": shot, "cam": {"pos": cam, "look": look, "fov": fov}, "door": kw.pop("door", OPEN)}
    fr.update(kw)
    if flash: fr["flash"] = flash
    if cr:
        c = dict(cr); c["f"] = f; cin.append(c); fr["creature"] = True
    frames.append(fr)
# 0: icon — straight up into the gap
add(0, "hall", [5.7, 22.4, 14.6], [5.35, 28.2, 11.55], 34,
    flash={"i": 2.6, "pos": [6.2, 22.0, 16.2], "target": [5.45, 28.4, 11.5], "angle": 0.22}, cr=LIE,
    ambient=0.02, exposure=1.8, bg=0x010101, glow=9)
# 1: thumbnail — the upstairs hall, the hatch hanging open, him looking down
add(1, "hall", [7.0, 20.4, 19.5], [5.4, 27.6, 11.2], 44,
    flash={"i": 4, "pos": [7.8, 19.0, 24.0], "target": [5.5, 28.4, 11.5], "angle": 0.2}, cr=LIE,
    ambient=0.03, exposure=1.7, bg=0x010101, glow=9)
# 2: thumbnail — the nest: him standing by the wall of photos, lantern light
add(2, "nest", [-15.2, 31.6, 7.0], [-25.5, 33.0, 0.8], 58,
    flash={"i": 2.5, "pos": [-15.8, 32.0, 6.2], "target": [-25, 33, 1], "angle": 0.5},
    cr={"pos": [-24.2, A, 3.6], "yaw": math.atan2(-(-15.5 + 24.2), -(6.5 - 3.6)), "gait": "Stare", "t": 0.7, "duck": 1.6, "neck": [0.1, 0.2, 0.35]},
    ambient=0.05, exposure=1.6, bg=0x020202, glow=7, door=0)
# 3: thumbnail — the wall of photos and the tally marks, close, in a flashlight beam
add(3, "nest", [-22.2, 32.0, 2.6], [-28.3, 31.9, 1.6], 50,
    flash={"i": 5, "pos": [-22.0, 31.6, 2.9], "target": [-28.2, 31.9, 1.4], "angle": 0.42},
    ambient=0.03, exposure=1.5, bg=0x020202, door=0)
json.dump(cin, open("frames_in.json", "w"))
json.dump({"W": 1024, "H": 1024, "shots": SHOTS, "frames": [frames[0]]}, open("spec_icon.json", "w"))
json.dump({"W": 1920, "H": 1080, "shots": SHOTS, "frames": frames[1:]}, open("spec_thumb.json", "w"))
print("ok")
