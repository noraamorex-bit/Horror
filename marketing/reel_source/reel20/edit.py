# Reel 20 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #9": the pizza man, then the 911 call. #2's format,
# look and music (#2 got 115k views), all-new shots (scene.py, rendered to reel20/raw). Every clip keeps
# #2's length, so the cut times are identical and #2's audio.py lands on the same beats and hits.
# Writes edit.json for tools/comp_cantplay.mjs.
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
shots = {s["name"]: s["start"] for s in json.load(open(f"{S}/reel20/shots.json"))}
R = "reel20"
# (source reel, first source frame, number of frames, section, caption)
CLIPS = [
    (R, shots["porch"], 105, "hook", ""),                                        # the pizza man on the porch, his back to us
    (R, shots["hatch"], 120, "card", ""),                                        # the attic hatch, slow
    (R, shots["face"], 72, "clip", "the pizza guy asked if we were home alone."),
    (R, shots["door"], 33, "clip", "we said yes."),
    (R, shots["living"], 90, "clip", "an hour later the power went out."),
    (R, shots["signal"], 60, "clip", "one bar of signal. upstairs bathroom."),
    (R, shots["call"], 60, "clip", "911, what's your emergency?"),
    (R, shots["hall"], 60, "clip", "someone was already in the house."),
    (R, shots["enter"], 75, "clip", "and he heard the call."),
    (R, shots["run"], 30, "clip", "RUN."),
    (R, shots["porch"], 180, "end", ""),
]
out = []
for reel, start, n, section, cap in CLIPS:
    for i in range(n):
        src = start + i
        if section == "card":
            src = start + int(i * 0.64)              # slow motion
        if section == "end":
            p = i % 180
            src = start + 10 + (p if p < 90 else 179 - p)    # the porch, rocking slowly back and forth
        out.append({"src": f"{S}/{reel}/raw/{src:04d}.png", "section": section, "cap": cap, "k": i / max(1, n - 1), "i": i})
print(len(out), "frames =", len(out) / FPS, "s")
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 9, "next": "would you have said yes?",
           "text": {"hook4": "(don't tell the pizza guy you're alone)", "stamp": "on our porch.", "squad": "1 - 4 players", "goal": "call 911.", "nextSize": 68}},
          open("edit.json", "w"))
