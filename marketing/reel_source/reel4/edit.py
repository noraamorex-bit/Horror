# Reel 4 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 1)": the recommendation format.
# Cut from clean gameplay renders of reels 1-3. Writes edit.json: one entry per output frame.
import json

S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
FPS = 30
# (source reel, first source frame, number of frames, section, caption)
CLIPS = [
    ("reel3", 0, 105, "hook", ""),
    ("reel", 0, 120, "card", ""),
    ("reel", 300, 72, "clip", "he knows where you are."),
    ("reel", 372, 33, "clip", "RUN."),
    ("reel2", 150, 90, "clip", "hide."),
    ("reel2", 459, 60, "clip", "hold your breath."),
    ("reel", 470, 60, "clip", "he checks every closet."),
    ("reel3", 400, 60, "clip", "he has photos of you."),
    ("reel3", 555, 75, "clip", ""),
    ("reel2", 640, 30, "clip", ""),
    ("reel", 96, 180, "end", ""),     # (the house in the rain, looped behind the end card)
]
out = []
for reel, start, n, section, cap in CLIPS:
    for i in range(n):
        src = start + i
        if section == "end":
            src = 96 + (i % 66)   # 96..161: the exterior shots
        if section == "card":
            src = int(i * 0.64)   # him at the end of the hall, in slow motion (0..76)
        out.append({"src": f"{S}/{reel}/raw/{src:04d}.png", "section": section, "cap": cap, "k": i / max(1, n - 1), "i": i})
print(len(out), "frames =", len(out) / FPS, "s")
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts}, open("edit.json", "w"))
