# The icon, take 3: a kid sitting up in bed, lit by their phone, smiling, facing us.
# Right behind and above them, out of the attic hatch, he hangs head first and reaches.
import json, math

CEIL = 28.0
TOP = 18.62            # top of the duvet on Jamie's bed (x -39.15..-31.35, z 13.3..18.3)
SKIN = [240, 196, 158]
SHIRT = [196, 44, 52]  # a red hoodie: the warm thing in a cold picture
PANTS = [36, 40, 52]
HAIR = [52, 36, 26]
BLACK = [8, 8, 10]
ex = []
def box(pos, s, col, rot=(0, 0, 0), **kw):
    e = {"shape": "box", "pos": pos, "s": s, "col": col, "rot": list(rot)}
    e.update(kw); ex.append(e)

Z = 15.8
# --- the hatch over the head of the bed
HX, HW, HD = -38.0, 3.2, 4.4
box([HX, CEIL - 0.02, Z], [HW, 0.06, HD], BLACK, rough=1)
for dx in (-1, 1):
    box([HX + dx * (HW / 2 + 0.15), CEIL - 0.08, Z], [0.3, 0.16, HD + 0.6], [226, 222, 212])
for dz in (-1, 1):
    box([HX, CEIL - 0.08, Z + dz * (HD / 2 + 0.15)], [HW + 0.6, 0.16, 0.3], [226, 222, 212])

# --- the kid, sitting up against the pillows, facing +x (us)
KX = -37.0
box([KX, TOP + 1.25, Z], [1.0, 2.0, 2.0], SHIRT, rot=(0, 0, 0.12))                 # torso, leaning back a little
HEAD = [KX - 0.12, TOP + 2.95, Z]
box(HEAD, [1.25, 1.25, 1.25], SKIN, face=0, rot=(0, 0, 0.1))                      # head, face toward +x
box([HEAD[0] - 0.12, HEAD[1] + 0.62, HEAD[2]], [1.4, 0.32, 1.38], HAIR, rot=(0, 0, 0.1))     # hair on top
box([HEAD[0] - 0.62, HEAD[1] + 0.1, HEAD[2]], [0.3, 1.15, 1.38], HAIR, rot=(0, 0, 0.1))      # and at the back
box([KX - 0.05, TOP + 2.25, Z], [1.1, 0.35, 2.05], SHIRT)                          # hood bunched at the neck
# arms forward, hands around the phone
for dz in (-0.95, 0.95):
    box([KX + 0.62, TOP + 1.6, Z + dz * 0.78], [1.4, 0.72, 0.72], SHIRT, rot=(0, -dz * 0.22, 0.3))
# the phone held upright in both hands: dark back to us, the screen glowing on the kid's face
PH = [KX + 1.32, TOP + 2.0, Z]
box(PH, [0.09, 1.05, 0.62], [14, 14, 18], rot=(0, 0, -0.22), rough=0.4)
box([PH[0] - 0.06, PH[1], PH[2]], [0.02, 0.97, 0.54], [215, 232, 255], rot=(0, 0, -0.22), emissive=[215, 232, 255], ei=2.6)
box([PH[0] + 0.05, PH[1] + 0.33, PH[2] - 0.17], [0.02, 0.12, 0.12], [40, 40, 46], rot=(0, 0, -0.22))   # the camera bump
for dz in (-1, 1):
    box([PH[0] - 0.02, PH[1] - 0.12, PH[2] + dz * 0.4], [0.42, 0.5, 0.22], SKIN, rot=(0, 0, -0.22))      # hands on the sides
# legs under the duvet
box([-34.4, TOP + 0.45, Z], [5.0, 0.9, 2.3], [34, 52, 98], rough=0.95)

# --- him: hanging head first from the hatch, behind and over the kid, facing us, reaching
cr = {"f": 0, "pos": [-39.5, 31.3, Z + 0.55], "yaw": math.pi / 2, "pitch": math.pi, "gait": "Reach", "t": 0.3, "neck": [0.0, 0.0, 0.28]}

SHOTS = {
    "room": {"center": [-33, 22, 18], "radius": 40, "lampRadius": 0, "maxLamps": 0,
             "lights": [
                 {"p": [KX + 1.0, TOP + 1.7, Z], "col": "#b4cfff", "b": 3.0, "r": 6, "decay": 1.8},   # the phone, up into the kid's face
                 {"p": [-36.6, 23.6, Z + 1.0], "col": "#a6c2ff", "b": 1.8, "r": 6, "decay": 1.6},     # (just reaching him)
                 {"p": [-36, 25, 26], "col": "#34507f", "b": 2.6, "r": 30},                            # moonlight from the window
                 {"p": [-30, 23, 9], "col": "#2a3a60", "b": 1.4, "r": 24},
                 {"p": [-33.8, 20.6, 16.6], "col": "#ffb59a", "b": 0.9, "r": 7, "decay": 1.6},          # a warm bedside glow on the kid
                 {"p": [-34.5, 25.5, 14.0], "col": "#8fa8d8", "b": 1.0, "r": 8, "decay": 1.6},          # cold light on his face
             ]},
}
CAMS = [
    ([-29.6, 21.6, 17.6], [-37.4, 22.6, 15.9], 50),
    ([-29.0, 20.9, 19.4], [-37.4, 22.8, 15.6], 52),
    ([-30.4, 22.4, 16.2], [-37.6, 22.9, 15.8], 48),
]
frames, crs = [], []
SETS = [("Stare", [-30.2, 22.2, 17.6], [-37.6, 23.4, 16.1], 46),
        ("Stare", [-30.8, 22.6, 18.4], [-37.6, 23.6, 16.0], 44),
        ("Stare", [-29.4, 21.6, 17.0], [-37.6, 23.2, 16.2], 48)]
for i, (gait, cam, look, fov) in enumerate(SETS):
    frames.append({"f": i, "shot": "room", "cam": {"pos": cam, "look": look, "fov": fov}, "creature": True,
                   "ambient": 0.06, "exposure": 1.85, "bg": 0x020203, "glow": 9})
    c = dict(cr); c["f"] = i; c["gait"] = gait; crs.append(c)
json.dump(crs, open("frames_in.json", "w"))
json.dump({"W": 1024, "H": 1024, "shots": SHOTS, "frames": frames, "extras": ex}, open("spec.json", "w"))
print("ok", len(ex))
