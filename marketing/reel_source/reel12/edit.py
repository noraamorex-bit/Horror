# Reel 12 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #6": the #2 format and #2's colours (orange + white),
# a new night-by-night story: the cheap house, the vents, the tally marks. Caption markup: *orange* ^amber^ _cream_.
# Writes edit.json for comp11.mjs.
import json
S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
FPS = 30
CLIPS = [
    ("reel8", 0, 105, "hook", ""),                                     # the three of them in the hall, him in the doorway behind
    ("reel3", 330, 120, "card", ""),                                   # the nest in the attic (slow)
    ("reel", 92, 72, "clip", "we got this house *way too cheap.*"),
    ("reel3", 150, 33, "clip", "the vents ^breathed^ at night."),
    ("reel6", 120, 90, "clip", "she said someone *watched her sleep.*"),
    ("reel10", 0, 60, "clip", "we told her it was ^just a dream.^"),
    ("reel3", 450, 60, "clip", "then we found *19 tally marks.*"),
    ("reel8", 340, 60, "clip", "one for every night *he'd been here.*"),
    ("reel9", 25, 75, "clip", "tonight he ^stopped hiding.^"),
    ("reel", 592, 30, "clip", ""),
    ("reel", 96, 180, "end", ""),
]
out = []
for reel, start, n, section, cap in CLIPS:
    for i in range(n):
        src = start + i
        if section == "card": src = start + int(i * 0.64)
        if section == "end": src = 96 + (i % 66)
        out.append({"src": f"{S}/{reel}/raw/{src:04d}.png", "section": section, "cap": cap, "k": i / max(1, n - 1), "i": i})
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
print(len(out), "frames; cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 6, "next": "#7 next week..."}, open("edit.json", "w"))
