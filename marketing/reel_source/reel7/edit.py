# Reel 5 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #3": the little brother.
# Cut from clean gameplay renders of reels 1-3. Writes edit.json: one entry per output frame.
import json

S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
FPS = 30
# (source reel, first source frame, number of frames, section, caption)
CLIPS = [
    ("reel6", 110, 105, "hook", ""),                                  # the kid on their phone. the hatch above.
    ("reel6", 0, 120, "card", ""),                                    # the living room, him at the window, slow
    ("reel2", 0, 72, "clip", "my brother says someone talks to him at night."),
    ("reel3", 150, 33, "clip", "we thought it was a dream."),
    ("reel2", 240, 90, "clip", "then we heard him walk past our door."),
    ("reel6", 50, 60, "clip", "he watches us from outside."),
    ("reel2", 330, 60, "clip", "we hid. we didn't breathe."),
    ("reel", 0, 60, "clip", "he waits at the end of the hall."),
    ("reel6", 140, 75, "clip", "and tonight he's right above you."),
    ("reel2", 640, 30, "clip", ""),
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
json.dump({"frames": out, "cuts": cuts, "num": 3, "next": "#4 next week..."}, open("edit.json", "w"))
