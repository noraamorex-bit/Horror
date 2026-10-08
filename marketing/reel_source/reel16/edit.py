# Reel 16 — "ROBLOX HORROR GAMES TO PLAY WITH FRIENDS #8": the story format in a new crimson + violet + bone palette,
# with a new case-file card (scream meter, how he hunts, hiding spots). A new story: the babysitter.
#
# Caption markup: *crimson* _bone_ ^violet^. Writes edit.json for comp15.mjs.
import json
S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
FPS = 30
CLIPS = [
    ("reel6", 110, 105, "hook", ""),                                   # him coming out of the hatch above the kid's bed
    ("reel3", 330, 120, "card", ""),                                   # the nest in the attic (slow)
    ("reel", 180, 72, "clip", "our babysitter said the house was ^totally fine.^"),
    ("reel", 115, 60, "clip", "then she *saw him* in the window."),
    ("reel3", 0, 60, "clip", "the attic hatch was _unlocked._"),
    ("reel", 330, 60, "clip", "she told us to hide. *NOW.*"),
    ("reel2", 150, 60, "clip", "he walked *right past* our closet."),
    ("reel8", 210, 60, "clip", "he found ^her^ first."),
    ("reel", 500, 75, "clip", "now he's looking *for us.*"),
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
json.dump({"frames": out, "cuts": cuts, "num": 8, "next": "#9 next week..."}, open("edit.json", "w"))
