# Reel 13 — "ROBLOX HORROR GAMES TO PLAY WITH YOUR FRIENDS #7": the #2 format in a new neon palette
# (hot magenta + electric cyan + acid lime). The story is the new mechanic: he can't see in the dark,
# he hunts by sound, and he stops outside your hiding spot to listen for your heartbeat.
# Caption markup: *magenta* _cyan_ ^lime^. Writes edit.json for comp12.mjs.
import json
S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
FPS = 30
CLIPS = [
    ("reel", 450, 105, "hook", ""),                                    # a dark room, a door... and he walks in
    ("reel8", 330, 120, "card", ""),                                   # the parents' room, him in the corner (slow)
    ("reel10", 90, 72, "clip", "we killed ^every light^ in the house."),
    ("reel", 300, 33, "clip", "he *can't see* in the dark."),
    ("reel9", 15, 90, "clip", "but he _hears_ *everything.*"),
    ("reel2", 330, 60, "clip", "so we hid. ^not one sound.^"),
    ("reel2", 450, 60, "clip", "he stopped *right outside.*"),
    ("reel8", 195, 60, "clip", "listening for our _heartbeats._"),
    ("reel", 500, 75, "clip", "mine was *way too loud.*"),
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
json.dump({"frames": out, "cuts": cuts, "num": 7, "next": "#8 next week..."}, open("edit.json", "w"))
