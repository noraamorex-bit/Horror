# v158 store art: players kept calling the old cover AI ("you should make the background NON AI", "Bro don't use ai for the game
# cover", "AI slop" downvotes). The v100 art was a graded, painterly render with a serif title and no players in it. This one is
# plainly a Roblox game: two real Roblox avatars in Roblox's own catalog clothes (film2 avatar_rbx.js, as in reels 38-41) running
# down the dark upstairs hall with a flashlight, him (the v156 gaunt man, the game's own SkinPose) coming after them; a plain bold
# title, no bloom or paint (post.py).
#   python3 scene.py thumb|thumb2|icon  -> spec.json + frames_in.json (tools/creature/skin_frames.luau) here
#   thumb  (1920x1080) the upstairs hall: Riley and Jamie running at you, Riley looking back, him behind them in Riley's beam
#   thumb2 (1920x1080) the front hall: the kids at the front door, him crouched on the stairs above them
#   icon   (1024)      Riley close, ZOMG face, him right behind over the shoulder
import json, math, os, sys
kind = sys.argv[1] if len(sys.argv) > 1 else "thumb"
G, U = 1.0, 15.0
SCALE = 1.2
AV = 2.2 * SCALE
TAU = math.tau
S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
C = f"{S}/avcache"
def facing(frm, to): return math.atan2(-(to[0] - frm[0]), -(to[2] - frm[2]))
def him(pos, yaw, gait="Stare", phase=0.0, t=0.0, **opts):
    return {"f": 0, "pos": {"x": pos[0], "y": pos[1], "z": pos[2]}, "yaw": yaw, "gait": gait, "phase": phase, "t": t, "seed": 4, "opts": opts}
COLD, MOON, WARM, TORCH = "#3d4f7a", "#6f86c4", "#ffb766", "#fff1d6"
RILEY = {"cache": C, "skin": "#f5cd30", "shirt": "144076357", "pants": "382537568", "faces": ["144080495", "8329421", "7074932"], "hats": ["63690008"]}
JAMIE = {"cache": C, "skin": "#9b6a48", "shirt": "398633582", "pants": "398633811", "faces": ["144080495", "7317691", "8329421"], "hats": ["1103003368"]}
AVS = [{"pos": [0, -200, 0], "yaw": 0, "rbx": RILEY, "scale": SCALE}, {"pos": [0, -200, 0], "yaw": 0, "rbx": JAMIE, "scale": SCALE}]
SCARED = 1
def gait(phase, look=(0, 0), run=True):
    s, c = math.sin(phase), math.cos(phase)
    a = 0.85 if run else 0.45
    kn = 1.25 if run else 0.5
    return {"lHip": a * s, "rHip": -a * s, "lKnee": -kn * max(0.0, -c) - 0.1, "rKnee": -kn * max(0.0, c) - 0.1,
            "lShoulder": [-a * 0.9 * s + 0.3, 0, -0.05], "rShoulder": [a * 0.9 * s + 0.3, 0, 0.05], "lElbow": 1.2, "rElbow": 1.2,
            "waist": -0.2, "neckX": 0.1, "neckY": look[0], "neckZ": look[1]}
def player(i, pos, yaw, pose, face=SCARED, pitch=0.0, bob=0.1):
    return {"i": i, "pos": [pos[0], pos[1] + AV + bob, pos[2]], "yaw": yaw, "pose": pose, "pitch": pitch, "face": face}
NOCANDY = ["CandyWrap", "CandyBody"]
JDOOR = {"near": [-8.0, U + 4.7, 24.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-8.0, 0, 21.57], "axis": "y"}
FDOOR = {"near": [2.0, 5.7, -30.0], "r": 3.2, "names": ["Panel", "Inset", "Knob"], "hinge": [-0.43, 0, -30.0], "axis": "y"}
def sy(z): return max(G, min(U, 2.05 + 0.625 * (z + 5.3) - 1.0))

if kind == "thumb":
    W, H = 1920, 1080
    cam = [2.4, U + 4.8, -29.0]
    look = [2.6, U + 5.0, -8.0]
    rp, jp = [6.4, U, -17.6], [-1.8, U, -15.6]
    hp = [2.4, U, -5.4]
    hand = [rp[0] + 0.9, U + 4.2, rp[2] + 0.4]
    av = [player(0, rp, facing(rp, cam) + 0.25, dict(gait(1.2, (2.3, 0.15)), rShoulder=[2.2, 0.0, 0.5], rElbow=0.2)),
          player(1, jp, facing(jp, cam) - 0.1, gait(4.0, (0.2, 0.0)), bob=0.2)]
    cr = him(hp, facing(hp, cam), "Chase", phase=1.6, t=2.0, Scream=0.55, Look=[0.0, 0.15])
    lights = [{"p": [2, U + 11, 24], "col": MOON, "b": 1.6, "r": 40, "decay": 1.0}, {"p": [3, U + 9, -26], "col": COLD, "b": 1.2, "r": 20},
              {"p": [-4, U + 8, -10], "col": MOON, "b": 1.2, "r": 16},
              {"p": [2.4, U + 6.5, -24.0], "col": "#c9d6ff", "b": 2.6, "r": 14, "decay": 1.2}]       # (a soft front light on the kids)
    fr = {"f": 0, "shot": "s", "cam": {"pos": cam, "look": look, "fov": 48}, "exposure": 2.3, "ambient": 0.03, "bg": 0x020203, "lamps": 0, "glow": 3.5,
          "flash": {"i": 14.0, "pos": hand, "target": [hp[0], U + 4.0, hp[2]], "angle": 0.42}, "av": av, "door": 0.0}
    shots = {"s": {"center": [2, U + 6, -10], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": lights, "door": JDOOR, "hide": NOCANDY}}
elif kind == "thumb2":
    W, H = 1920, 1080
    cam = [6.6, G + 5.0, -29.2]
    look = [-1.6, G + 7.0, -2.0]
    rp, jp = [4.6, G, -20.6], [-1.4, G, -17.6]
    hp = [-5.0, sy(6.0), 6.0]
    av = [player(0, rp, facing(rp, hp) + 0.2, dict(gait(0.0, (0.0, 0.3), run=False), lShoulder=[0.6, 0, -0.4], rShoulder=[1.4, 0, 0.3], rElbow=0.3), bob=0.0),
          player(1, jp, facing(jp, hp) - 0.3, dict(gait(0.0, (0.0, 0.25), run=False), lShoulder=[0.6, 0, -0.35], rShoulder=[0.6, 0, 0.35],
                                                     lElbow=1.5, rElbow=1.5), bob=0.0)]
    cr = him(hp, facing(hp, [0.6, G, -21.6]), "Stare", t=3.0, Duck=1.1, Look=[0.0, -0.35], Scream=0.3)
    lights = [{"p": [2, G + 6, -34], "col": MOON, "b": 2.0, "r": 18, "decay": 1.1}, {"p": [2, G + 9, -20], "col": COLD, "b": 1.1, "r": 18},
              {"p": [-5, U + 6, 10], "col": "#2c3d6e", "b": 1.2, "r": 24},
              {"p": [6.0, G + 7.0, -26.0], "col": "#c9d6ff", "b": 2.6, "r": 14, "decay": 1.2}]
    hand = [rp[0] + 0.8, G + 4.4, rp[2] + 0.2]
    fr = {"f": 0, "shot": "s", "cam": {"pos": cam, "look": look, "fov": 54}, "exposure": 2.3, "ambient": 0.03, "bg": 0x020203, "lamps": 0, "glow": 3.0,
          "flash": {"i": 14.0, "pos": hand, "target": [hp[0], hp[1] + 4.5, hp[2]], "angle": 0.4}, "av": av, "door": 0.0}
    shots = {"s": {"center": [0, G + 7, -10], "radius": 40, "lampRadius": 0, "maxLamps": 0, "lights": lights, "door": FDOOR, "hide": NOCANDY}}
else:
    W, H = 1024, 1024
    cam = [1.6, U + 5.8, -24.4]
    rp = [1.4, U, -17.4]
    hp = [4.4, U, -12.4]
    look = [2.6, U + 6.4, -14.0]
    av = [player(0, rp, facing(rp, cam), dict(gait(0.0, (0.0, 0.0), run=False), lShoulder=[0.5, 0, -0.45], rShoulder=[0.5, 0, 0.45],
                                                lElbow=1.6, rElbow=1.6, neckX=0.05), bob=0.0)]
    av[0]["yaw"] = facing(rp, cam) - 0.35
    cr = him(hp, facing(hp, cam), "Stare", t=3.0, Duck=0.9, Look=[0.0, -0.25], Scream=0.45)
    lights = [{"p": [3, U + 9, -22], "col": "#cfdcff", "b": 2.6, "r": 10, "decay": 1.4}, {"p": [2, U + 11, 10], "col": MOON, "b": 1.4, "r": 30},
              {"p": [7, U + 6, -9], "col": "#ff3b30", "b": 1.6, "r": 9}]
    fr = {"f": 0, "shot": "s", "cam": {"pos": cam, "look": look, "fov": 40}, "exposure": 2.2, "ambient": 0.03, "bg": 0x020203, "lamps": 0, "glow": 4.0,
          "flash": {"i": 12.0, "pos": [cam[0] + 0.5, cam[1] - 0.8, cam[2]], "target": [3.4, U + 6.6, -13.0], "angle": 0.5}, "av": av, "door": 0.0}
    shots = {"s": {"center": [3, U + 6, -12], "radius": 34, "lampRadius": 0, "maxLamps": 0, "lights": lights, "door": JDOOR, "hide": NOCANDY}}

fr["creature"] = True
json.dump([cr], open("frames_in.json", "w"))
json.dump({"W": W, "H": H, "shots": shots, "frames": [fr], "avatars": AVS, "extras": [], "props": {"cache": f"{S}/propcache"}, "skinCache": f"{S}/mc"},
          open("spec.json", "w"))
print("ok", kind, W, H)
