# Reel 5 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #4": the sleepover.
# Cut from clean gameplay renders of reels 1-3. Writes edit.json: one entry per output frame.
import json

S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
FPS = 30
# (source reel, first source frame, number of frames, section, caption)
CLIPS = [
    ("reel8", 0, 105, "hook", ""),                                    # the friends upstairs. him, right behind them.
    ("reel8", 330, 120, "card", ""),                                  # the parents' room, him in the corner, slow
    ("reel", 180, 72, "clip", "sleepover at jake's. his parents were out."),
    ("reel3", 0, 33, "clip", "the attic hatch was open."),
    ("reel8", 105, 90, "clip", "so we went up to check."),
    ("reel8", 410, 60, "clip", "his parents' room wasn't empty."),
    ("reel2", 450, 60, "clip", "we hid in the closet."),
    ("reel8", 195, 60, "clip", "jake went to bed first."),
    ("reel8", 255, 75, "clip", "he wasn't alone."),
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
json.dump({"frames": out, "cuts": cuts, "num": 4, "next": "#5 next week..."}, open("edit.json", "w"))
