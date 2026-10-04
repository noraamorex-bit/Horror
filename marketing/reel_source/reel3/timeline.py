# Reel 3 — "someone lives in our attic." (30 s, 1080x1920)
# hook at the hatch -> the signs (kitchen, the ceiling over the bed, the hatch again) -> up the
# ladder -> his nest, his photos of us, 19 tally marks -> turn around -> he's right there -> end card
import json, math, random, glob

FPS, DUR = 30, 30.0
U, A = 15, 29
W, H = 1080, 1920
random.seed(3)

def clamp(x, a, b): return max(a, min(b, x))
def lerp(a, b, t): return a + (b - a) * t
def lerp3(a, b, t): return [lerp(a[i], b[i], t) for i in range(3)]
def ease(t): t = clamp(t, 0, 1); return t * t * (3 - 2 * t)
def seg(t, a, b): return clamp((t - a) / (b - a), 0, 1)
def add(a, b): return [a[i] + b[i] for i in range(3)]
def hand(t, amp=1.0, speed=1.0):
    s = speed
    return [amp * (0.04 * math.sin(t * 1.3 * s) + 0.02 * math.sin(t * 3.1 * s + 1.7)),
            amp * (0.035 * math.sin(t * 1.7 * s + 0.4) + 0.015 * math.sin(t * 4.3 * s)),
            amp * (0.03 * math.sin(t * 1.1 * s + 2.2))]
def yaw_to(frm, to):
    return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def dirlook(pos, yaw, pitch=0.0, d=10):
    return [pos[0] - math.sin(yaw) * math.cos(pitch) * d, pos[1] + math.sin(pitch) * d, pos[2] - math.cos(yaw) * math.cos(pitch) * d]

HATCH = {"near": [6, 28.2, 11], "r": 4.5, "names": ["HatchPanel", "Cord", "CordHandle"], "hinge": [0, 28.3, 8.05], "axis": "x"}
SHOTS = {
    "hall": {"center": [6, 24, 9], "radius": 40, "lampRadius": 0, "maxLamps": 0, "door": HATCH,
             "lights": [{"p": [-4, 20, 4], "col": "#3b4766", "b": 1.0, "r": 22}]},
    "hallOpen": {"center": [4, 27, 8], "radius": 46, "lampRadius": 0, "maxLamps": 0, "hide": ["HatchPanel", "Cord", "CordHandle"],
                 "lights": [{"p": [-4, 20, 4], "col": "#3b4766", "b": 1.0, "r": 22}]},
    "kitchen": {"center": [-25, 6, 20], "radius": 34, "lampRadius": 0, "maxLamps": 0,
                "lights": [{"p": [-27, 6, 25.5], "col": "#cfe0ff", "b": 2.2, "r": 12}, {"p": [-36, 9, 10], "col": "#33405e", "b": 1.2, "r": 26}]},
    "bedroom": {"center": [-28, 22, 19], "radius": 30, "lampRadius": 0, "maxLamps": 0,
                "lights": [{"p": [-38, 22, 26], "col": "#5a6c9e", "b": 3.0, "r": 30}, {"p": [-28, 26, 18], "col": "#2c3654", "b": 1.5, "r": 16}]},
    "attic": {"center": [-12, 32, 3], "radius": 60, "lampRadius": 14, "maxLamps": 2,
              "lights": [{"p": [-19, 30.4, -4], "col": "#ffb066", "b": 2.4, "r": 18}]},
    "black": {"center": [0, -500, 0], "radius": 1, "lampRadius": 0, "maxLamps": 0},
}

class Walker:
    def __init__(self): self.phase = 0.0
    def step(self, speed, gait, dt):
        self.phase += speed * dt * 2 * math.pi / (7.5 if gait == "Chase" else 5.2)
        return self.phase
walk = Walker()

# the camera's path through the attic
NEST_CAM0 = [0.5, 32.4, 10.0]
NEST_CAM1 = [-15.0, 32.2, 5.0]
WALL_CAM = [-22.0, 32.0, 2.6]
WALL_LOOK = [-28.3, 31.9, 1.6]
TALLY = [-28.2, 31.9, 4.5]
HIM = [-14.2, A, 5.0]  # behind you, by the time you turn round

frames, cin, markers = [], [], {}
n = int(DUR * FPS)
for f in range(n):
    t = f / FPS
    fr = {"f": f, "shot": "black", "door": 0.0}
    cam, look, fov, cr, flash = [0, -500, 0], [0, -500, 10], 60, None, None
    fr.update(ambient=0.05, exposure=1.6, bg=0x020203, glow=6)

    if t < 3.4:
        # 1 — the hook: the hatch in the ceiling. It moves.
        s = t
        fr["shot"] = "hall"
        cam = add(lerp3([7.2, 19.0, 21.5], [6.9, 19.6, 18.6], ease(s / 3.4)), hand(t, 0.8))
        look = [5.8, 27.4, 11.0]
        fov = 52
        jolt = 0.0
        if s >= 2.3:
            k = s - 2.3
            jolt = 0.16 * math.exp(-k * 3.5) * abs(math.cos(k * 11)) + 0.05 * seg(k, 0, 0.3)
        fr["door"] = jolt
        flash = {"i": 3.2, "pos": add(cam, [0.3, -0.4, 0.3]), "target": [6, 28.3, 11.5], "angle": 0.3}
        fr.update(ambient=0.04, exposure=1.7)
        markers.setdefault("hatch_jolt", 2.3)
    elif t < 5.0:
        # 2a — food keeps going missing (the fridge light in the dark kitchen)
        s = t - 3.4
        fr["shot"] = "kitchen"
        cam = add(lerp3([-21.5, 6.6, 13.5], [-22.5, 6.4, 15.0], ease(s / 1.6)), hand(t, 0.5))
        look = [-27.0, 5.2, 27.0]
        fov = 60
        fr.update(ambient=0.06, exposure=1.7)
    elif t < 6.8:
        # 2b — footsteps above my bed. every night. (lying in bed, looking up)
        s = t - 5.0
        fr["shot"] = "bedroom"
        cam = add([-34.0, 18.8, 15.8], hand(t, 0.25))
        look = lerp3([-27.0, 28.3, 18.0], [-24.0, 28.3, 22.5], ease(s / 1.8))
        fov = 70
        fr.update(ambient=0.14, exposure=2.1)
        markers.setdefault("thumps", 5.1)
    elif t < 8.6:
        # 2c — and the hatch is never closed (now it's open: black)
        s = t - 6.8
        fr["shot"] = "hallOpen"
        cam = add(lerp3([6.6, 19.8, 17.0], [6.3, 20.4, 15.0], ease(s / 1.8)), hand(t, 0.6))
        look = [5.8, 28.6, 11.0]
        fov = 50
        flash = {"i": 4.6, "pos": add(cam, [0.3, -0.4, 0.3]), "target": [6, 29.5, 11.2], "angle": 0.28}
        fr.update(ambient=0.05, exposure=2.0)
    elif t < 11.0:
        # 3 — so tonight i went up. Up through the hatch, into the dark.
        s = t - 8.6
        fr["shot"] = "hallOpen" if s < 1.3 else "attic"
        k = ease(s / 2.4)
        cam = add(lerp3([6.0, 21.5, 12.0], [5.6, 32.0, 11.2], k), hand(t, 0.5 + 0.8 * k))
        # looking straight up, then levelling out toward the far end of the attic
        up = lerp(1.35, 0.0, ease(seg(s, 1.0, 2.4)))
        yaw = yaw_to([0, 0, 0], [-1, 0, -0.35])
        look = dirlook(cam, yaw, up)
        fov = 62
        flash = {"i": 4.0, "pos": add(cam, [0.2, -0.3, 0.2]), "target": dirlook(cam, yaw, up, 12), "angle": 0.4}
        fr.update(ambient=0.03, exposure=1.7)
        markers.setdefault("climb", 8.6)
    elif t < 17.0:
        # 4 — his nest. The sleeping bag. The wrappers. Then the wall: photos of us. 19 marks.
        s = t - 11.0
        fr["shot"] = "attic"
        if s < 2.6:
            k = ease(s / 2.6)
            cam = add(lerp3(NEST_CAM0, NEST_CAM1, k), hand(t, 1.0, 1.4))
            target = lerp3([-20.0, 29.5, -1.5], [-24.5, 29.6, -0.5], k)  # sweeping the bed and the mess
        elif s < 4.6:
            k = ease(seg(s, 2.6, 4.6))
            cam = add(lerp3(NEST_CAM1, WALL_CAM, k), hand(t, 0.6))
            target = lerp3([-24.5, 29.6, -0.5], WALL_LOOK, ease(seg(s, 2.6, 3.4)))
        else:
            k = ease(seg(s, 4.6, 6.0))
            cam = add(WALL_CAM, hand(t, 0.5))
            target = lerp3(WALL_LOOK, TALLY, k)  # to the tally marks
        look = target
        fov = 58
        flash = {"i": 4.5, "pos": add(cam, [0.25, -0.35, 0.2]), "target": target, "angle": 0.38}
        fr.update(ambient=0.05, exposure=1.85)
    elif t < 20.4:
        # 5 — a creak behind you. You turn round, slowly. He's right there.
        s = t - 17.0
        fr["shot"] = "attic"
        cam = add(WALL_CAM, hand(t, 0.45))
        yaw0 = yaw_to(WALL_CAM, TALLY)
        yaw1 = yaw_to(WALL_CAM, HIM)
        k = ease(seg(s, 0.9, 2.5))
        # (the long way round, over your shoulder)
        if yaw1 < yaw0:
            yaw1 += 2 * math.pi
        yaw = lerp(yaw0, yaw1, k)
        look = dirlook(cam, yaw, lerp(0.0, 0.3, k))
        fov = 58
        flash = {"i": 4.2, "pos": add(cam, [0.25, -0.35, 0.2]), "target": dirlook(cam, yaw, lerp(0.0, 0.33, k), 6), "angle": 0.36}
        neck = [0.15, 0.0, 0.25]
        if s >= 2.9: neck = [0.15, 0.0, -0.35]  # the head snaps the other way
        cr = {"pos": HIM, "yaw": yaw_to(HIM, WALL_CAM), "gait": "Stare", "t": t, "duck": 1.6, "neck": neck}
        fr.update(ambient=0.05, exposure=1.9, glow=8)
        markers.setdefault("creak_behind", 17.6)
        markers.setdefault("reveal", 19.4)
        markers.setdefault("snap", 19.9)
    elif t < 21.4:
        # 6 — he lunges
        s = t - 20.4
        fr["shot"] = "attic"
        cam = add(WALL_CAM, hand(t, 3 + 6 * s, 4))
        k = ease(seg(s, 0.0, 0.55)) ** 0.7
        p = lerp3(HIM, add(WALL_CAM, [3.2, -32.0 + A, 1.0]), k)
        p[1] = A
        ph = walk.step(26, "Chase", 1 / FPS)
        cr = {"pos": p, "yaw": yaw_to(p, WALL_CAM), "gait": "Chase" if k < 0.9 else "Reach", "phase": ph, "t": t, "duck": 1.8, "neck": [0.35, 0.0, 0.1]}
        face = add(p, [0, 6.6, 0])
        look = lerp3(dirlook(WALL_CAM, yaw_to(WALL_CAM, HIM), 0.3), face, ease(seg(s, 0, 0.3)))
        fov = lerp(58, 48, k)
        flash = {"i": 5.0, "pos": add(cam, [0.25, -0.35, 0.2]), "target": face, "angle": 0.4}
        fr.update(ambient=0.04, exposure=1.75, glow=12)
        if s >= 0.55:
            fr["shot"] = "black"; cr = None; flash = None
            cam, look = [0, -500, 0], [0, -500, 10]
        markers.setdefault("lunge", 20.4)
        markers.setdefault("cut", 20.95)

    fr["cam"] = {"pos": cam, "look": look, "fov": fov}
    if flash: fr["flash"] = flash
    if cr is not None:
        cr["f"] = f
        cin.append(cr)
        fr["creature"] = True
    frames.append(fr)

photos = sorted(glob.glob("photos/p*.png"))
json.dump(cin, open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": SHOTS, "frames": frames, "photos": [__import__("os").path.abspath(p) for p in photos]}, open("spec_reel.json", "w"))
json.dump({"fps": FPS, "dur": DUR, "markers": markers}, open("cues.json", "w"))
print("frames", len(frames), "creature", len(cin), markers)
