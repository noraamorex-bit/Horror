# Icon, take 4: a real-looking Roblox avatar (avatar.js) sitting up in bed on their phone,
# and him hanging head-first out of the open attic hatch right behind them.
import json, math, sys

CEIL = 28.0
TOP = 18.62
BLACK = [6, 6, 8]
TRIM = [226, 222, 212]
ex = []
def box(pos, s, col, rot=(0, 0, 0), **kw):
    e = {"shape": "box", "pos": pos, "s": s, "col": col, "rot": list(rot)}
    e.update(kw); ex.append(e)

# --- him: feet up in the attic, hanging head first through the hatch, facing us
HEAD = [-38.3, 23.7, 14.25]                       # where his head should be
OFF_HEAD = [0.38, -7.34, 0.61]                     # (measured: head relative to his pivot, this pose)
PIV = [HEAD[0] - OFF_HEAD[0], HEAD[1] - OFF_HEAD[1], HEAD[2] - OFF_HEAD[2]]
cr = {"f": 0, "pos": PIV, "yaw": math.pi / 2, "pitch": math.pi, "gait": "Stare", "t": 0.3, "neck": [0.0, 0.0, 0.3]}

# --- the hatch: an opening cut where his legs go up, a lip of trim, the panel hanging open
HX0, HX1 = -39.85, -37.0
HZ0, HZ1 = PIV[2] - 1.9, PIV[2] + 1.9
hx, hz = (HX0 + HX1) / 2, (HZ0 + HZ1) / 2
box([hx, CEIL - 0.03, hz], [HX1 - HX0, 0.05, HZ1 - HZ0], BLACK, rough=1)                  # the dark inside
for z in (HZ0 - 0.14, HZ1 + 0.14):                                                         # trim, front and back
    box([hx, CEIL - 0.12, z], [HX1 - HX0 + 0.56, 0.24, 0.28], TRIM)
box([HX1 + 0.14, CEIL - 0.12, hz], [0.28, 0.24, HZ1 - HZ0 + 0.56], TRIM)                  # trim, the side toward us
for z in (HZ0, HZ1):                                                                        # inner edges (depth)
    box([hx, CEIL - 0.1, z], [HX1 - HX0, 0.2, 0.04], [30, 28, 26])
box([HX1, CEIL - 0.1, hz], [0.04, 0.2, HZ1 - HZ0], [30, 28, 26])
# the panel, hinged on the far (-z) edge, swung down
PANEL_ANG = 1.25
pl = HZ1 - HZ0 - 0.1
pc = [hx, CEIL - math.sin(PANEL_ANG) * pl / 2, HZ0 - math.cos(PANEL_ANG) * pl / 2]
box(pc, [HX1 - HX0 - 0.1, 0.2, pl], TRIM, rot=(-PANEL_ANG, 0, 0))
# its pull cord, hanging from the free end
fend = [hx + 0.6, CEIL - math.sin(PANEL_ANG) * pl, HZ0 - math.cos(PANEL_ANG) * pl]
box([fend[0], fend[1] - 0.9, fend[2]], [0.06, 1.8, 0.06], [200, 196, 186])
ex.append({"shape": "ball", "pos": [fend[0], fend[1] - 1.85, fend[2]], "s": [0.3, 0.3, 0.3], "col": [200, 196, 186]})

# --- the avatar, sitting up against the headboard, facing us
AV = {"pos": [-36.9, 19.32, 15.95], "yaw": -math.pi / 2 - 0.18,
      "pose": {"waist": -0.08, "neckX": -0.26, "neckY": -0.12, "neckZ": 0.03,
               "lShoulder": [0.25, 0, 0.12], "lElbow": 0.55, "rShoulder": [0.5, 0, -0.5], "rElbow": 1.75,
               "lHip": math.pi / 2, "rHip": math.pi / 2, "lKnee": 0.0, "rKnee": 0.0},
      "colors": {"hoodie": "#d6363c", "hoodieDark": "#a8262d", "hair": "#3b2416"},
      "phone": {"hand": "r", "offset": [0.0, 0.42, 0.0], "light": 3.2}}
# the duvet over the legs
box([-34.2, TOP + 0.95, 15.95], [5.2, 1.3, 2.9], [34, 52, 100], rough=0.95)

SHOTS = {"room": {"center": [-33, 22, 18], "radius": 40, "lampRadius": 0, "maxLamps": 0,
                  "lights": [
                      {"p": [-36, 25, 26], "col": "#4466a8", "b": 3.4, "r": 32},                      # moonlight, from the window
                      {"p": [-30, 23, 9], "col": "#2a3a60", "b": 1.4, "r": 24},
                      {"p": [-33.0, 21.0, 18.5], "col": "#ffb48f", "b": 0.7, "r": 7, "decay": 1.6},   # a little warm bedside glow
                      {"p": [-35.6, 25.4, 13.4], "col": "#9fb6e6", "b": 1.2, "r": 6, "decay": 1.6},   # cold light on his mask
                  ]}}
CAMS = [([-30.6, 21.6, 19.6], [-37.4, 23.4, 13.9], 46),
        ([-31.2, 21.8, 19.0], [-37.4, 23.5, 13.7], 44)]
frames, crs = [], []
for i, (cam, look, fov) in enumerate(CAMS):
    frames.append({"f": i, "shot": "room", "cam": {"pos": cam, "look": look, "fov": fov}, "creature": True,
                   "ambient": 0.10, "exposure": 2.2, "bg": 0x020203, "glow": 8})
    c = dict(cr); c["f"] = i; crs.append(c)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": 1920, "H": 1080, "shots": SHOTS, "frames": frames, "extras": ex, "avatars": [AV]}, open("spec.json", "w"))
print("ok", PIV)
