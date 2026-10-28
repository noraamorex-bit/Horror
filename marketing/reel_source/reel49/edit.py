# Reel 49 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #4" (the new run): he gets closer every night (#12's recipe, the v112 look).
# #2's format, look and music, all-new shots (scene.py, rendered to reel49/raw) with the v112 creature (no mask: the pale body and the maw). Every
# clip keeps #2's length, so the cut times are identical and #2's audio.py lands on the same beats and hits.
# Writes edit.json for tools/comp_cantplay.mjs.
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
shots = {s["name"]: s["start"] for s in json.load(open(f"{S}/reel49/shots.json"))}
R = "reel49"
# (source reel, first source frame, number of frames, section, caption)
CLIPS = [
    (R, shots["hook"], 105, "hook", ""),                                          # the master bedroom, lamps on: cosy
    (R, shots["card"], 120, "card", ""),                                          # the same room in the moonlight
    (R, shots["door"], 72, "clip", "night 15: he was at the end of the hall."),
    (R, shots["prints"], 33, "clip", "night 16: closer."),
    (R, shots["photo"], 90, "clip", "night 17: at my door."),
    (R, shots["setup"], 60, "clip", "night 18: at the foot of my bed."),
    (R, shots["open"], 60, "clip", "so tonight i stayed awake."),
    (R, shots["stood"], 60, "clip", "the hall was empty."),
    (R, shots["knew"], 75, "clip", "he was already in here."),
    (R, shots["run"], 30, "clip", "RUN."),
    (R, shots["card"], 180, "end", ""),
]
out = []
for reel, start, n, section, cap in CLIPS:
    for i in range(n):
        src = start + i
        if section == "card":
            src = start + int(i * 0.64)              # slow motion
        if section == "end":
            p = i % 180
            src = start + 20 + (p if p < 90 else 179 - p)    # the dark room, drifting slowly back and forth
        fr = {"src": f"{S}/{reel}/raw/{src:04d}.png", "section": section, "cap": cap, "k": i / max(1, n - 1), "i": i}
        if start == shots["photo"] and section == "clip":
            fr["bright"] = 2.3                       # (him in the doorway, moonlit: as reel 43's same shot)
        if start in (shots["door"], shots["prints"], shots["stood"]) and section == "clip":
            fr["bright"] = 1.7                       # (the dark hall: lifted so a phone shows him)
        out.append(fr)
print(len(out), "frames =", len(out) / FPS, "s")
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
assert [c[2] for c in CLIPS] == [105, 120, 72, 33, 90, 60, 60, 60, 75, 30, 180], "the clips keep #2's lengths"
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 4, "next": "#5 next week...",
           "text": {"hook4": "(bring a friend. or two.)", "stamp": "he's closer", "squad": "1 - 4 players", "goal": "survive the night"}},
          open("edit.json", "w"))
