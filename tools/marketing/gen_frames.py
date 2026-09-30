import json, math, os
M = os.environ['M']
FPS = 24

def lerp(a, b, t): return a + (b - a) * t
def ease(t): return t * t * (3 - 2 * t)

# ---------- video 1: the hallway ----------
hall = []
for f in range(int(9.0 * FPS)):
    t = f / FPS
    wob = math.sin(t * 1.7) * 0.08
    bob = math.sin(t * 5.2) * 0.05
    if t < 8.0:
        z = lerp(16, 7, ease(min(t / 8.0, 1)))
    else:
        z = 7
    v = {"name": "h%04d" % f, "mode": "inside", "pos": [3 + wob, 20.4 + bob, z], "look": [3 + wob * 3, 19.6, -20],
         "fov": 60, "ambient": 0.015, "moon": 0.0, "lightRadius": 1, "maxLights": 0, "flashlight": 40, "figures": []}
    # flicker: 4.0-4.9s
    if 4.0 <= t < 4.9:
        k = int((t - 4.0) * 24)
        v["flashlight"] = 0 if (k % 3 == 1 or t > 4.45) else 40
    if 4.9 <= t < 8.0:
        v["figures"] = [{"pos": [3, 15, -17], "face": [3, 20], "sack": True, "scale": 1.05}]
    if 8.0 <= t < 8.3:
        # he's suddenly right there
        v["figures"] = [{"pos": [3, 15, 0.5], "face": [3, 20], "sack": True, "scale": 1.05}]
        v["pos"][0] += math.sin(f * 2.3) * 0.25
        v["pos"][1] += math.cos(f * 3.1) * 0.2
        v["exposure"] = 1.6
    if t >= 8.3:
        v["flashlight"] = 0
        v["figures"] = []
    hall.append(v)
json.dump(hall, open(M + '/vid/views_hall.json', 'w'))

# ---------- video 2: the house from the street ----------
house = []
base_glow = [{"p": [-14, 7.2, -29.4], "w": 6.2, "h": 5.7, "col": "#b5652a"}]
for f in range(int(10.5 * FPS)):
    t = f / FPS
    z = lerp(-96, -70, ease(min(t / 10.5, 1)))
    y = lerp(6, 7.5, t / 10.5)
    v = {"name": "s%04d" % f, "mode": "outside", "pos": [2 + math.sin(t * 0.6) * 0.3, y, z], "look": [2, 16, -30],
         "fov": 42, "fog": [55, 210], "bg": "#0b1016", "ambient": 0.14, "moon": 0.28, "lightRadius": 170, "maxLights": 24,
         "hide": ["Glass", "Pole", "Crossarm", "Insulator", "Transformer"], "glow": list(base_glow), "figures": [], "lights": []}
    if t >= 5.0:
        # the upstairs light comes on
        v["glow"] = base_glow + [{"p": [2, 21.2, -25.5], "w": 7, "h": 6.5, "col": "#ffa347"}]
        v["lights"] = [{"p": [2, 21, -26.5], "col": "#ffa347", "b": 6, "r": 14}]
    if 7.0 <= t < 9.0:
        v["figures"] = [{"pos": [2, 15, -28.2], "face": [2, -90], "scale": 1.05}]
    if 9.0 <= t < 9.25:
        v["exposure"] = 3.0  # lightning
        v["ambient"] = 1.2
        v["moon"] = 2.5
    house.append(v)
json.dump(house, open(M + '/vid/views_house.json', 'w'))
print(len(hall), len(house))
