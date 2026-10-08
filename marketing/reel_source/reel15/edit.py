# Reel 15 — "WOULD YOU SURVIVE THIS ROBLOX HORROR GAME?": a new quiz format. Four rounds: a situation, two
# choices and a countdown, then the answer (the last one: neither). Electric-blue game-show palette
# (blue, white, green = right, red = wrong). Caption markup: *blue* _green_ ^red^. Writes edit.json for comp14.mjs.
import json
S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
FPS = 30
# (reel, start, frames, speed, section, data)
CLIPS = [
    ("reel", 0, 90, 1.0, "hook", {}),                                   # him on the stairs, turning
    ("reel", 300, 135, 0.8, "quiz", {"n": 1, "q": "he's at the end of the hall.", "a": "RUN", "b": "LIGHT OFF", "ok": "b",
                                       "why": "he can't see in the dark. *he hears you run.*"}),
    ("reel2", 150, 135, 1.0, "quiz", {"n": 2, "q": "he's right outside your closet.", "a": "HOLD YOUR BREATH", "b": "RUN PAST HIM", "ok": "a",
                                       "why": "not a sound. *he's listening.*"}),
    ("reel3", 0, 135, 0.85, "quiz", {"n": 3, "q": "the attic hatch is open.", "a": "GO UP", "b": "CLOSE IT", "ok": "a",
                                       "why": "the clues are up there. ^so is his bed.^"}),
    ("reel8", 210, 135, 0.85, "quiz", {"n": 4, "q": "you wake up. he's over your bed.", "a": "SCREAM", "b": "PRETEND TO SLEEP", "ok": "",
                                       "why": "neither. ^he already knows.^"}),
    ("reel", 592, 30, 1.0, "scare", {}),
    ("reel", 96, 180, 1.0, "end", {}),
]
out = []
for reel, start, n, speed, section, data in CLIPS:
    for i in range(n):
        src = start + int(i * speed)
        if section == "end": src = 96 + (i % 66)
        out.append({"src": f"{S}/{reel}/raw/{src:04d}.png", "section": section, "d": data, "k": i / max(1, n - 1), "i": i})
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
scare = cuts[5]
print(len(out), "frames; cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "scare": scare, "silentFrom": round(scare - 0.55, 3), "end": cuts[6],
           "dur": round(len(out) / FPS, 3)}, open("edit.json", "w"))
