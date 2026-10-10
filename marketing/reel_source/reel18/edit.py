# Reel 18 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #7": #2's format, look and music (#2 got 115k views),
# with new clips from the trailer renders (reel17). Every clip keeps #2's length, so the cut times are
# identical and #2's audio.py lands on the same beats and hits. Writes edit.json for comp6.mjs.
import json

S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
FPS = 30
R = "reel17"
# (source reel, first source frame, number of frames, section, caption)
CLIPS = [
    (R, 150, 105, "hook", ""),                                          # the three of them in the living room... then the lights go
    (R, 345, 120, "card", ""),                                          # the attic nest, slow
    (R, 255, 72, "clip", "night 1: a light under the attic hatch."),
    (R, 484, 33, "clip", "night 3: something dropped into the garage."),
    (R, 651, 90, "clip", "night 6: it walked right past my bed."),
    (R, 20, 60, "clip", "night 11: someone in the attic window."),
    (R, 771, 60, "clip", "night 15: it waited outside our rooms."),
    (R, 849, 60, "clip", "night 19: my brother didn't come back."),
    (R, 575, 75, "clip", "and tonight he's coming down."),
    (R, 954, 30, "clip", ""),                                           # he runs at you
    (R, 0, 180, "end", ""),
]
out = []
for reel, start, n, section, cap in CLIPS:
    for i in range(n):
        src = start + i
        if section == "card":
            src = start + int(i * 0.64)              # slow motion
        if section == "end":
            p = i % 180
            src = 10 + (p if p < 90 else 179 - p)    # the house at night, rocking slowly back and forth
        out.append({"src": f"{S}/{reel}/raw/{src:04d}.png", "section": section, "cap": cap, "k": i / max(1, n - 1), "i": i})
print(len(out), "frames =", len(out) / FPS, "s")
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 7, "next": "#8 next week..."}, open("edit.json", "w"))
