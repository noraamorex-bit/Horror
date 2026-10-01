# Builds the reel's per-frame spec (camera, lights, creature) for film.mjs and the creature
# pose requests for creature_frames.luau. Times in seconds, 30 fps.
import json, math, random

FPS = 30
DUR = 27.0
U, G = 15, 1
W, H = 1080, 1920
random.seed(7)

def clamp(x, a, b): return max(a, min(b, x))
def lerp(a, b, t): return a + (b - a) * t
def lerp3(a, b, t): return [lerp(a[i], b[i], t) for i in range(3)]
def ease(t): t = clamp(t, 0, 1); return t * t * (3 - 2 * t)
def ease_in(t): t = clamp(t, 0, 1); return t * t
def seg(t, a, b): return clamp((t - a) / (b - a), 0, 1)

def hand(t, amp=1.0, speed=1.0, seed=0.0):
    # handheld camera drift: smooth, layered sines
    s = speed
    return [
        amp * (0.05 * math.sin(t * 1.3 * s + seed) + 0.025 * math.sin(t * 3.1 * s + 1.7 + seed)),
        amp * (0.04 * math.sin(t * 1.7 * s + 0.4 + seed) + 0.02 * math.sin(t * 4.3 * s + seed)),
        amp * (0.03 * math.sin(t * 1.1 * s + 2.2 + seed)),
    ]

def add(a, b): return [a[i] + b[i] for i in range(3)]

def yaw_to(frm, to):
    dx, dz = to[0] - frm[0], to[2] - frm[2]
    return math.atan2(-dx, -dz)

frames, cin = [], []
markers = {}  # sound / comp cues (seconds)

SHOTS = {
    "hall_up": {"center": [2, U + 5, -10], "radius": 70, "lampRadius": 0, "maxLamps": 0},
    "ext": {"center": [2, 12, -30], "radius": 420, "lampRadius": 40, "maxLamps": 14,
            "lights": [{"p": [2, U + 6, -23], "col": "#ffb36b", "b": 3.5, "r": 16}]},
    "living": {"center": [-24, 6, -14], "radius": 48, "lampRadius": 30, "maxLamps": 12},
    "hall_down": {"center": [2, 5, -4], "radius": 70, "lampRadius": 0, "maxLamps": 0},
    "master": {"center": [-24, U + 4, -15], "radius": 45, "lampRadius": 0, "maxLamps": 0,
               "hide": ["WardrobeDoors", "DoorSeam", "DoorPanel", "PanelInset", "Handle", "WardrobeBack", "WardrobeSide", "WardrobeTop", "Crown", "CrownLip", "Plinth"],
               "lights": [{"p": [-34, U + 8, -2], "col": "#6b80b0", "b": 2.0, "r": 45}, {"p": [-20, U + 7, -10], "col": "#3a4866", "b": 1.2, "r": 25}]},
    "black": {"center": [0, -500, 0], "radius": 1, "lampRadius": 0, "maxLamps": 0},
}

# creature state carried across frames of a shot
class Walker:
    def __init__(self): self.phase = 0.0
    def step(self, speed, gait, dt):
        rate = 2 * math.pi / (7.5 if gait == "Chase" else 5.2)
        self.phase += speed * dt * rate
        return self.phase

walk = Walker()
flick_state = {}

def flicker(t, rate, key):
    # deterministic random flicker: returns brightness multiplier for this frame
    r = random.Random(int(t * FPS) * 7919 + hash(key) % 1000)
    return 0.08 if r.random() < rate else 1.0

n = int(DUR * FPS)
for f in range(n):
    t = f / FPS
    fr = {"f": f}
    cr = None

    # S1 — hook: upstairs hall, he's standing at the end of it -------------------------------
    if t < 2.6:
        s = t
        fr["shot"] = "hall_up"
        cam = [2, U + 5.6, lerp(-24, -20.5, ease(s / 2.6))]
        cam = add(cam, hand(t, 1.2))
        fr["cam"] = {"pos": cam, "look": [2 + 0.3 * math.sin(t * 0.7), U + 6.0, -2], "fov": 55}
        # the beam starts low on the stairs, swings up onto him
        k = ease(seg(s, 0.7, 1.35))
        tgt = lerp3([-3, U + 1.2, -10], [2, U + 6.6, -2], k)
        fl = 14 * flicker(t, 0.0 if s < 1.9 else 0.35, "s1")
        fr["flash"] = {"i": fl, "pos": add(cam, [0.6, -0.5, 0]), "target": tgt, "angle": 0.34}
        fr["ambient"] = 0.025; fr["exposure"] = 1.2; fr["bg"] = 0x030303
        neck = [0, 0, 0]
        if 1.62 <= s < 1.8: neck = [0.0, 0.35, 0.45]      # the head snaps
        elif s >= 1.8: neck = [0.0, 0.12, 0.25]
        cr = {"pos": [2, U, -2], "yaw": 0, "gait": "Stare", "t": 0.25, "neck": neck}
    # S2 — the house from the street, lightning, a figure in the window ---------------------
    elif t < 5.4:
        s = t - 2.6
        fr["shot"] = "ext"
        cam = [2, lerp(7.6, 8.8, ease(s / 2.8)), lerp(-92, -82, ease(s / 2.8))]
        fr["cam"] = {"pos": add(cam, hand(t, 0.6)), "look": [2, 16.2, -30], "fov": 46}
        L = 0.0
        if 0.38 <= s < 0.5: L = 0.65
        elif 0.5 <= s < 0.6: L = 0.2
        elif 0.66 <= s < 0.76: L = 0.5
        elif 0.76 <= s < 1.1: L = 0.5 * (1 - seg(s, 0.76, 1.1))
        fr.update(lamps=1, ambient=0.13, moon=0.22, lightning=L, bg=0x0a0f15, fog=[70, 320], xl=1)
        cr = {"pos": [2, U, -28.0], "yaw": 0, "gait": "Stare", "t": 0.4 + s * 0.2}
    # S3 — cozy: warm living room, Mom texts -------------------------------------------------
    elif t < 8.7:
        s = t - 5.4
        fr["shot"] = "living"
        cam = lerp3([-11, 7, -4], [-13.5, 6.6, -7.5], ease(s / 4.5))
        fr["cam"] = {"pos": add(cam, hand(t, 0.5)), "look": [-30, 3.6, -22], "fov": 70}
        lamps = 1.0
        if t >= 8.5: lamps = 0.0 if (f % 3 == 0) else 0.35   # the lights stutter
        fr.update(lamps=lamps, ambient=0.22 * lamps + 0.02, exposure=1.0)
    # S4 — blackout, then a flashlight clicks on ----------------------------------------------
    elif t < 10.0:
        s = t - 8.7
        fr["shot"] = "living"
        cam = lerp3([-11, 7, -4], [-13.5, 6.6, -7.5], ease((t - 5.4) / 4.5))
        fr["cam"] = {"pos": add(cam, hand(t, 0.8)), "look": [-30, 3.6, -22], "fov": 70}
        fr.update(lamps=0, ambient=0.006, exposure=1.2, bg=0x020202)
        if t >= 9.4:
            k = ease(seg(t, 9.4, 9.9))
            fr["flash"] = {"i": 10, "pos": add(cam, [0.6, -0.6, 0]), "target": lerp3([-20, 1.5, -10], [-28, 3.5, -20], k), "angle": 0.38}
    # S5 — the hunt: front hall, he sees you, he runs ------------------------------------------
    elif t < 14.4:
        s = t - 10.0
        fr["shot"] = "hall_down"
        back = lerp(16, 18.5, ease(seg(s, 1.6, 3.6)))
        cam = [2, G + 5.6, back]
        shake_amt = 0.6 + 4.0 * ease_in(seg(s, 1.4, 3.5))
        cam = add(cam, hand(t, shake_amt, 1.0 + 2.5 * seg(s, 1.4, 3.5)))
        # creature path
        z0 = -24.0
        if s < 1.2:
            cz, gait, speed = z0, "Stare", 0
        else:
            u = s - 1.2
            # accelerate to 18 studs/s over 0.5 s
            dist = 18 * (u - 0.25) if u > 0.5 else 18 * u * u
            cz = z0 + dist
            gait, speed = "Chase", (36 * u if u < 0.5 else 18)
        stop = back - 3.2
        lunge = cz >= stop
        cz = min(cz, stop)
        ph = walk.step(speed, gait, 1 / FPS)
        neck = [0, 0, 0]
        if 0.95 <= s < 1.2: neck = [0.0, -0.4, -0.5]
        cr = {"pos": [2, G, cz], "yaw": math.pi, "gait": ("Reach" if lunge else gait), "phase": ph, "t": 0.3 + s * 0.5, "neck": neck}
        look_z = lerp(-20, cz, ease(seg(s, 1.4, 3.4)))
        fr["cam"] = {"pos": cam, "look": [2, G + 4.6, min(look_z, back - 1)], "fov": 66, "roll": 0.02 * math.sin(t * 9) * seg(s, 1.5, 3.5)}
        near = clamp(1 - (back - cz) / 30, 0, 1)
        fl = 20 * flicker(t, 0.0 if near < 0.4 else 0.25 + 0.4 * near, "s5")
        fr["flash"] = {"i": fl, "pos": add(cam, [0.6, -0.5, 0]), "target": [2 + 0.6 * math.sin(t * 5) * near, G + 5.5, cz], "angle": 0.3}
        fr.update(ambient=0.06, exposure=1.45, bg=0x030303, glow=9)
        if s >= 3.55:
            fr["shot"] = "black"; cr = None; fr["flash"] = None
            fr["cam"] = {"pos": [0, -500, 0], "look": [0, -500, 10], "fov": 60}
        markers.setdefault("chase_go", 10.0 + 1.2)
        markers.setdefault("chase_cut", 10.0 + 3.55)
    # S6 — hiding: through the gap in the wardrobe doors -------------------------------------
    elif t < 19.0:
        s = t - 14.4
        fr["shot"] = "master"
        cam = add([-24, U + 4.6, -27.2], hand(t, 0.35, 0.6))
        fr["cam"] = {"pos": cam, "look": [-24, U + 4.9, -10], "fov": 64}
        fr.update(ambient=0.08, moon=0.3, xl=1.6, exposure=1.6, bg=0x030303, glow=10)
        # he walks in from the door, stops in front of the wardrobe, listens, steps closer
        p0, p1, p2 = [-11.5, U, -9.5], [-23.5, U, -15.5], [-24, U, -19.5]
        if s < 0.4:
            cr = None
        elif s < 2.4:
            k = seg(s, 0.4, 2.4)
            p = lerp3(p0, p1, k)
            ph = walk.step(6.5, "Search", 1 / FPS)
            cr = {"pos": p, "yaw": yaw_to(p0, p1), "gait": "Search", "phase": ph, "t": s}
        elif s < 3.6:
            k = ease(seg(s, 2.4, 2.9))
            yaw = lerp(yaw_to(p0, p1), 0, k)
            neck = [0.0, 0.25 * math.sin((s - 2.4) * 2.2), 0.3 * ease(seg(s, 3.0, 3.5))]
            cr = {"pos": p1, "yaw": yaw, "gait": "Stare", "t": s, "neck": neck}
        else:
            k = seg(s, 3.6, 4.6)
            p = lerp3(p1, p2, ease(k))
            ph = walk.step(3.5 if k < 1 else 0, "Walk", 1 / FPS)
            cr = {"pos": p, "yaw": 0, "gait": "Walk" if k < 1 else "Stare", "phase": ph, "t": s, "neck": [0.05, 0, 0.45]}
    # S7 — the doors are ripped open ------------------------------------------------------------
    elif t < 20.6:
        s = t - 19.0
        fr["shot"] = "master"
        fr.update(ambient=0.05, moon=0.2, xl=1, exposure=1.5, bg=0x030303)
        head = [-24, U + 7.7, -20.6]
        if s < 0.9:
            k = ease(seg(s, 0.1, 0.9))
            cam = lerp3([-24, U + 4.6, -27.2], [-24, U + 5.6, -25.2], k)
            cam = add(cam, hand(t, 1.5 + 4 * k, 3))
            fr["cam"] = {"pos": cam, "look": lerp3([-24, U + 4.9, -10], head, k), "fov": lerp(64, 50, k)}
            cr = {"pos": lerp3([-24, U, -19.5], [-24, U, -22.2], ease(seg(s, 0.0, 0.6))), "yaw": 0, "gait": "Reach", "t": t, "neck": [0.25, 0, 0.35]}
        else:
            # the jump scare: right in his face
            k = seg(s, 0.9, 1.6)
            cr = {"pos": [-24, U, -22.4], "yaw": 0, "gait": "Reach", "t": t, "neck": [0.25, 0.0, -0.1 + 0.25 * math.sin(s * 40) * (1 - k)]}
            face = [-24, U + 7.55, -23.25]
            cam = add([face[0], face[1] + 0.05, face[2] - lerp(3.2, 2.3, ease(k))], hand(t, 5, 6))
            fr["cam"] = {"pos": cam, "look": face, "fov": 48}
            fr["flash"] = {"i": 6, "pos": add(cam, [0.4, -0.3, 0]), "target": face, "angle": 0.5}
        markers.setdefault("doors_open", 19.0)
        markers.setdefault("scare", 19.9)
    # S8 — end card ------------------------------------------------------------------------------
    else:
        fr["shot"] = "black"
        fr["cam"] = {"pos": [0, -500, 0], "look": [0, -500, 10], "fov": 60}
        fr["ambient"] = 0

    fr.setdefault("bg", 0x050505)
    if cr is not None:
        cr["f"] = f
        cin.append(cr)
        fr["creature"] = True
    frames.append(fr)

json.dump(cin, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames}, open("spec_reel.json", "w"))
json.dump({"fps": FPS, "dur": DUR, "markers": markers}, open("cues.json", "w"))
print("frames", len(frames), "creature frames", len(cin))
