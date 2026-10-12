# Reel 21 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #10": bedtime, and the hall closet. #2's format,
# look and music (#2 got 115k views), all-new shots (scene.py, rendered to reel21/raw). Every clip keeps
# #2's length, so the cut times are identical and #2's audio.py lands on the same beats and hits.
# Writes edit.json for tools/comp_cantplay.mjs.
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
shots = {s["name"]: s["start"] for s in json.load(open(f"{S}/reel21/shots.json"))}
R = "reel21"
# (source reel, first source frame, number of frames, section, caption)
CLIPS = [
    (R, shots["hook"], 105, "hook", ""),                                         # brushing your teeth... him in the doorway behind
    (R, shots["hall"], 120, "card", ""),                                         # the dark hall, light under the bathroom door, slow
    (R, shots["brush"], 72, "clip", "mom said brush your teeth and go to bed."),
    (R, shots["out"], 33, "clip", "then the lights went out."),
    (R, shots["stairs"], 90, "clip", "something was at the top of the stairs."),
    (R, shots["hide"], 60, "clip", "i hid in the hall closet."),
    (R, shots["stop"], 60, "clip", "it stopped right outside."),
    (R, shots["lean"], 60, "clip", "don't breathe."),
    (R, shots["knew"], 75, "clip", "it knew."),
    (R, shots["run"], 30, "clip", "RUN."),
    (R, shots["hook"], 180, "end", ""),
]
out = []
for reel, start, n, section, cap in CLIPS:
    for i in range(n):
        src = start + i
        if section == "card":
            src = start + int(i * 0.64)              # slow motion
        if section == "end":
            p = i % 180
            src = start + 10 + (p if p < 90 else 179 - p)    # the bathroom, rocking slowly back and forth
        out.append({"src": f"{S}/{reel}/raw/{src:04d}.png", "section": section, "cap": cap, "k": i / max(1, n - 1), "i": i})
print(len(out), "frames =", len(out) / FPS, "s")
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 10, "next": "would you have held your breath?",
           "text": {"hook4": "(hold your breath)", "stamp": "in the closet.", "squad": "1 - 4 players", "goal": "hide.", "nextSize": 62}},
          open("edit.json", "w"))
