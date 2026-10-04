# Reel 5 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #2": the attic story, night by night.
# Cut from clean gameplay renders of reels 1-3. Writes edit.json: one entry per output frame.
import json

S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
FPS = 30
# (source reel, first source frame, number of frames, section, caption)
CLIPS = [
    ("reel", 180, 105, "hook", ""),                                   # the cosy living room... then the lights go
    ("reel3", 300, 120, "card", ""),                                  # the nest in the attic, slow
    ("reel3", 30, 72, "clip", "night 1: footsteps in the ceiling."),
    ("reel3", 120, 33, "clip", "night 4: the food goes missing."),
    ("reel3", 210, 90, "clip", "night 9: we found the hatch."),
    ("reel3", 330, 60, "clip", "someone's been sleeping up here."),
    ("reel3", 420, 60, "clip", "photos. of us."),
    ("reel3", 510, 60, "clip", "he's been counting the days."),
    ("reel", 450, 75, "clip", "and tonight he's coming down."),
    ("reel", 592, 30, "clip", ""),
    ("reel", 96, 180, "end", ""),
]
out = []
for reel, start, n, section, cap in CLIPS:
    for i in range(n):
        src = start + i
        if section == "end":
            src = 96 + (i % 66)              # the house in the rain, looped
        if section == "card":
            src = start + int(i * 0.64)      # slow motion
        out.append({"src": f"{S}/{reel}/raw/{src:04d}.png", "section": section, "cap": cap, "k": i / max(1, n - 1), "i": i})
print(len(out), "frames =", len(out) / FPS, "s")
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 2, "next": "#3 next week..."}, open("edit.json", "w"))
