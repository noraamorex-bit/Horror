# Reel 19 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #8": the secret ending. #2's format, look and music
# (#2 got 115k views), all-new shots under the house (scene.py here, rendered to reel19/raw), plus the
# boiler-room shot from the trailer (reel17). Every clip keeps #2's length, so the cut times are identical
# and #2's audio.py lands on the same beats and hits. Writes edit.json for comp7.mjs.
import json

S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
FPS = 30
shots = {s["name"]: s["start"] for s in json.load(open(f"{S}/reel19/shots.json"))}
R = "reel19"
# (source reel, first source frame, number of frames, section, caption)
CLIPS = [
    (R, shots["wide"], 105, "hook", ""),                                       # the dinner, him at the head of the table
    (R, shots["photos"], 120, "card", ""),                                     # the photo wall, slow
    ("reel17", 849, 72, "clip", "what if everyone gets caught at once?"),      # a friend zip-tied in the boiler room
    (R, shots["ladder"], 33, "clip", "he doesn't take you to the boiler room."),
    (R, shots["table"], 90, "clip", "there's a table under the house."),
    (R, shots["place"], 60, "clip", "set for the whole family."),
    (R, shots["turn"], 60, "clip", "don't move when he turns around."),
    (R, shots["note"], 60, "clip", "the way out is in his notes."),
    (R, shots["down"], 75, "clip", "but he always comes back down."),
    (R, shots["run"], 30, "clip", "RUN."),
    (R, shots["wide"], 180, "end", ""),
]
out = []
for reel, start, n, section, cap in CLIPS:
    for i in range(n):
        src = start + i
        if section == "card":
            src = start + int(i * 0.64)              # slow motion
        if section == "end":
            p = i % 180
            src = start + 10 + (p if p < 90 else 179 - p)    # the dinner, rocking slowly back and forth
        out.append({"src": f"{S}/{reel}/raw/{src:04d}.png", "section": section, "cap": cap, "k": i / max(1, n - 1), "i": i})
print(len(out), "frames =", len(out) / FPS, "s")
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 8, "next": "can you find the secret ending?",
           "text": {"hook4": "(it has a secret ending)", "stamp": "under the house.", "squad": "2 - 4 players", "goal": "all get caught.", "nextSize": 62}},
          open("edit.json", "w"))
