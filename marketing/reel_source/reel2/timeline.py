# Reel 2 — "POV: you hid under the bed". One locked-off camera under the master bed (the game's
# own under-bed view), the door straight ahead. He comes in, checks the wardrobe off-screen,
# comes to the bed, leaves... then his face drops into the gap, upside down.
import json, math, random

FPS = 30
DUR = 26.0
U = 15
W, H = 1080, 1920
random.seed(11)

def clamp(x, a, b): return max(a, min(b, x))
def lerp(a, b, t): return a + (b - a) * t
def lerp3(a, b, t): return [lerp(a[i], b[i], t) for i in range(3)]
def ease(t): t = clamp(t, 0, 1); return t * t * (3 - 2 * t)
def seg(t, a, b): return clamp((t - a) / (b - a), 0, 1)
def add(a, b): return [a[i] + b[i] for i in range(3)]
def yaw_to(frm, to):
    dx, dz = to[0] - frm[0], to[2] - frm[2]
    return math.atan2(-dx, -dz)
def breathe(t, amp):
    # lying still, holding your breath: the tiniest drift
    return [0, amp * 0.012 * math.sin(t * 1.9), amp * 0.008 * math.sin(t * 1.3 + 1)]

SHOTS = {
    "under": {"center": [-22, U + 4, -13], "radius": 46, "lampRadius": 0, "maxLamps": 0,
              "door": {"near": [-8, U + 4.7, -10], "r": 3.4, "names": ["Panel", "Inset", "Knob"], "hinge": [-8, 0, -12.43]},
              "lights": [
                  {"p": [-3.5, U + 7, -10], "col": "#8ea2d4", "b": 6.0, "r": 26},     # cold light in the hall
                  {"p": [-24, U + 9, -27], "col": "#5a6c9a", "b": 2.6, "r": 30},      # the window by the wardrobe
                  {"p": [-16, U + 9, -27], "col": "#4b5a86", "b": 2.0, "r": 26},
              ]},
    "black": {"center": [0, -500, 0], "radius": 1, "lampRadius": 0, "maxLamps": 0},
}

CAM = [-32.6, U + 0.75, -14.5]
LOOK = [-8, U + 1.6, -11.0]

class Walker:
    def __init__(self): self.phase = 0.0
    def step(self, speed, gait, dt):
        rate = 2 * math.pi / (7.5 if gait == "Chase" else 5.2)
        self.phase += speed * dt * rate
        return self.phase

walk = Walker()

# his route: hall -> doorway -> middle of the room -> wardrobe (off to the left) -> the bed -> out
HALL, DOORWAY, MID, WARD, BED, OUT = [-3.0, U, -10.0], [-9.8, U, -10.2], [-19.5, U, -12.6], [-23.5, U, -24.0], [-27.6, U, -14.4], [-2.0, U, -10.0]

def path(points, k):
    # piecewise-linear along a polyline by arc length
    lens = [math.dist(points[i], points[i + 1]) for i in range(len(points) - 1)]
    total = sum(lens); d = k * total
    for i, L in enumerate(lens):
        if d <= L or i == len(lens) - 1:
            u = clamp(d / L, 0, 1)
            return lerp3(points[i], points[i + 1], u), yaw_to(points[i], points[i + 1])
        d -= L

frames, cin, markers = [], [], {}
n = int(DUR * FPS)
for f in range(n):
    t = f / FPS
    fr = {"f": f, "shot": "under"}
    cr = None
    cam = add(CAM, breathe(t, 1.0))
    look = LOOK
    fr.update(ambient=0.2, xl=1.0, exposure=2.0, bg=0x020203, glow=5)
    door = 0.0
    dt = 1 / FPS

    if t < 3.0:
        pass                                          # the empty room, the closed door
    elif t < 4.7:
        door = -1.85 * ease(seg(t, 3.0, 4.5)) ** 1.4   # it swings in, slowly
        markers.setdefault("door_creak", 3.0)
    else:
        door = -1.85
    # he comes in
    if 4.7 <= t < 8.2:
        s = t - 4.7
        if s < 1.2:
            p, yaw = path([HALL, DOORWAY], seg(s, 0, 1.2))
            cr = {"pos": p, "yaw": yaw, "gait": "Walk", "phase": walk.step(5.6, "Walk", dt), "t": t}
        elif s < 2.0:
            cr = {"pos": DOORWAY, "yaw": yaw_to(HALL, DOORWAY), "gait": "Stare", "t": t, "neck": [0, 0.3 * math.sin(s * 3), 0]}
        else:
            p, yaw = path([DOORWAY, MID], ease(seg(s, 2.0, 3.5)))
            cr = {"pos": p, "yaw": yaw, "gait": "Search", "phase": walk.step(6.5, "Search", dt), "t": t}
        markers.setdefault("steps_in", 4.7)
    # listening in the middle of the room
    elif 8.2 <= t < 9.8:
        s = t - 8.2
        yaw = yaw_to(DOORWAY, MID)
        neck = [0.0, 0.0, 0.0]
        if 0.7 <= s < 0.85: neck = [0.0, 0.5, 0.5]        # the head snaps round
        elif s >= 0.85: neck = [0.0, 0.35, 0.3]
        cr = {"pos": MID, "yaw": yaw + 0.4 * ease(seg(s, 0.2, 0.7)), "gait": "Stare", "t": t, "neck": neck}
        markers.setdefault("snap", 8.9)
    # to the wardrobe (off to the left of the gap)
    elif 9.8 <= t < 11.3:
        p, yaw = path([MID, WARD], ease(seg(t, 9.8, 11.3)))
        cr = {"pos": p, "yaw": yaw, "gait": "Walk", "phase": walk.step(7.5, "Walk", dt), "t": t}
    elif 11.3 <= t < 12.9:
        cr = None                                      # off-screen: the doors ripped open
        markers.setdefault("yank", 11.75)
    # back across the room, straight to the bed
    elif 12.9 <= t < 15.3:
        p, yaw = path([WARD, add(MID, [-3, 0, -1.5]), BED], ease(seg(t, 12.9, 15.3)))
        cr = {"pos": p, "yaw": yaw, "gait": "Walk", "phase": walk.step(6.0, "Walk", dt), "t": t}
        markers.setdefault("steps_back", 12.9)
    # standing at the foot of the bed. right there.
    elif 15.3 <= t < 17.4:
        s = t - 15.3
        cr = {"pos": BED, "yaw": yaw_to([-20, U, -14.4], BED) + 0.06 * math.sin(s * 1.4), "gait": "Stare", "t": t,
              "neck": [0.35 * ease(seg(s, 0.4, 1.2)), 0, 0.2]}
        markers.setdefault("at_bed", 15.3)
    # he turns and goes
    elif 17.4 <= t < 19.6:
        p, yaw = path([BED, add(MID, [3, 0, 1.5]), DOORWAY, OUT], seg(t, 17.4, 19.6) ** 0.9)
        cr = {"pos": p, "yaw": yaw, "gait": "Walk", "phase": walk.step(10.0, "Walk", dt), "t": t}
        markers.setdefault("leaves", 17.4)
    # silence. you start to crawl out...
    if 19.6 <= t < 21.1:
        k = ease(seg(t, 19.9, 21.1))
        cam = add(lerp3(CAM, [-31.35, U + 0.72, -14.5], k), breathe(t, 2.5))
    # ...and he drops into the gap, upside down, right in front of you
    if 21.1 <= t < 22.2:
        s = t - 21.1
        cam = add([-31.35, U + 0.72, -14.5], [0, 0.07 * math.sin(s * 47) * (1 - seg(s, 0, 0.9)), 0.07 * math.sin(s * 39) * (1 - seg(s, 0, 0.9))])
        drop = ease(seg(s, 0.0, 0.16))
        head_y = lerp(U + 4.6, U + 1.0, drop) + 0.12 * math.sin(s * 9) * seg(s, 0.2, 1.0)
        # hanging from above, upside down, face toward you
        cr = {"pos": [-26.45, head_y + 6.75, -14.0], "yaw": -math.pi / 2, "pitch": math.pi, "gait": "Reach", "t": t,
              "neck": [0.0, 0.0, 0.12 + 0.3 * math.sin(s * 38) * (1 - seg(s, 0.15, 0.7))]}
        look = lerp3(LOOK, [-28.8, U + 1.0, -14.5], ease(seg(s, 0.05, 0.3)) * 0.8)
        fr.update(glow=3, exposure=1.9)
        markers.setdefault("scare", 21.1)
    # you click your flashlight on to look
    if 20.55 <= t < 22.2:
        k = ease(seg(t, 20.55, 20.75))
        fr["flash"] = {"i": (9 if t < 21.1 else 3.2) * k, "pos": add(cam, [0.2, -0.15, 0.25]), "target": [-22, U + 1.2, -13.5] if t < 21.1 else [-28.8, U + 1.6, -14.3], "angle": 0.45 if t < 21.1 else 0.3}
        markers.setdefault("click", 20.55)
    if t >= 22.2:
        fr["shot"] = "black"
        cam, look = [0, -500, 0], [0, -500, 10]
        cr = None
    fr["cam"] = {"pos": cam, "look": look, "fov": 58}
    fr["door"] = door
    if cr is not None:
        cr["f"] = f
        cin.append(cr)
        fr["creature"] = True
    frames.append(fr)

json.dump(cin, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames}, open("spec_reel.json", "w"))
json.dump({"fps": FPS, "dur": DUR, "markers": markers}, open("cues.json", "w"))
print("frames", len(frames), "creature frames", len(cin), markers)
