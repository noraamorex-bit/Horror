# Reel 17 — the cinematic trailer. A slow, quiet film-trailer cut: serif title cards on black between
# all-new shots (scene.py), building to a fast montage, silence, the hero close-up, then the title.
# Writes edit.json for comp16.mjs (and the cue times audio.py scores to).
import json
S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
FPS = 30
shots = {s["name"]: s for s in json.load(open("shots.json"))}
def raw(f): return f"{S}/reel17/raw/{f:04d}.png"

# per-shot grade: brightness lift for the dark ones
GRADE = {"ext": 1.2, "living": 1.0, "hatch": 1.35, "attic": 1.1, "garage": 1.45, "stairs": 1.15,
         "underbed": 1.55, "hall": 1.75, "boiler": 1.35, "chase": 1.25, "hero": 1.1}
EDIT = [
    ("card", ["14 ALDER LANE"], 42, "small"),
    ("shot", "ext", 0, 95),
    ("card", ["IT WAS SUPPOSED TO BE", "A NORMAL NIGHT."], 56, ""),
    ("shot", "living", 0, 150),
    ("card", ["BUT SOMEONE ELSE", "LIVES HERE."], 56, ""),
    ("shot", "hatch", 10, 80),
    ("shot", "attic", 0, 95),
    ("card", ["HE'S BEEN UP THERE", "FOR NINETEEN DAYS."], 62, ""),
    ("shot", "garage", 0, 105),
    ("card", ["TONIGHT,", "HE COMES DOWN."], 56, ""),
    ("shot", "stairs", 0, 96),
    ("card", ["HE HUNTS BY SOUND."], 46, ""),
    ("shot", "underbed", 10, 110),
    ("shot", "hall", 0, 78),
    ("card", ["IF HE FINDS YOU..."], 46, ""),
    ("shot", "boiler", 8, 97),
    ("card", ["BRING YOUR FRIENDS."], 42, "italic"),
    # the montage: quick hits, white flashes, a frame of his face, then he runs at you
    ("shot", "stairs", 80, 6),
    ("flash", 2),
    ("shot", "garage", 92, 5),
    ("shot", "hero", 90, 2),
    ("shot", "underbed", 92, 5),
    ("flash", 2),
    ("shot", "boiler", 50, 4),
    ("shot", "hall", 40, 4),
    ("flash", 1),
    ("shot", "chase", 0, 30),
    ("black", 24),
    ("shot", "hero", 0, 96),
    ("title", 96),
    ("end", 96),
]
frames, cues, t = [], [], 0
for e in EDIT:
    kind = e[0]
    start_t = t / FPS
    if kind == "shot":
        _, name, a, n = e
        s = shots[name]
        assert a + n <= s["n"], (name, a, n, s["n"])
        for i in range(n):
            frames.append({"kind": "shot", "name": name, "src": raw(s["start"] + a + i), "i": i, "n": n, "g": GRADE[name]})
        cues.append({"t": round(start_t, 3), "kind": "shot", "name": name, "len": round(n / FPS, 3)})
        t += n
    elif kind == "card":
        _, lines, n, style = e
        for i in range(n):
            frames.append({"kind": "card", "lines": lines, "style": style, "i": i, "n": n})
        cues.append({"t": round(start_t, 3), "kind": "card", "text": " ".join(lines), "len": round(n / FPS, 3)})
        t += n
    else:
        n = e[1]
        for i in range(n):
            frames.append({"kind": kind, "i": i, "n": n})
        cues.append({"t": round(start_t, 3), "kind": kind, "len": round(n / FPS, 3)})
        t += n
print(len(frames), "frames =", round(len(frames) / FPS, 2), "s")
json.dump({"frames": frames, "cues": cues, "fps": FPS, "dur": round(len(frames) / FPS, 3),
           "icon": "/home/user/Horror/marketing/attic/icon_512.png"}, open("edit.json", "w"))
