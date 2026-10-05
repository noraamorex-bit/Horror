# Reel 11 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #5": the #2 format (night-by-night story, case file),
# cut from the newest renders. Caption markup: *red* _green_ ^yellow^. Writes edit.json for comp10.mjs.
import json
S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
FPS = 30
CLIPS = [
    ("reel10", 90, 105, "hook", ""),                                   # lights flicker, out, flashlight: him
    ("reel8", 330, 120, "card", ""),                                   # the parents' room, him in the corner (slow)
    ("reel10", 0, 72, "clip", "it was supposed to be a ^normal^ sleepover."),
    ("reel3", 120, 33, "clip", "then the food started *going missing.*"),
    ("reel6", 110, 90, "clip", "the attic hatch kept *opening* by itself."),
    ("reel8", 195, 60, "clip", "she woke up. he was *standing over her.*"),
    ("reel8", 105, 60, "clip", "so we searched the house. _together._"),
    ("reel6", 50, 60, "clip", "he was outside. *watching us.*"),
    ("reel9", 30, 75, "clip", "then she ^called us^ from her room."),
    ("reel", 592, 30, "clip", ""),
    ("reel", 96, 180, "end", ""),
]
out = []
for reel, start, n, section, cap in CLIPS:
    for i in range(n):
        src = start + i
        if section == "hook": src = min(start + i, 185)                 # hold on him at the end
        if section == "card": src = start + int(i * 0.64)
        if section == "end": src = 96 + (i % 66)
        out.append({"src": f"{S}/{reel}/raw/{src:04d}.png", "section": section, "cap": cap, "k": i / max(1, n - 1), "i": i})
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
print(len(out), "frames; cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 5, "next": "#6 next week..."}, open("edit.json", "w"))
