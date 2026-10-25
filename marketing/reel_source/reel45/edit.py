# Reel 45 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #14": the chapter after #13 ("he doesn't want us to leave").
# #2's format, look and music, all-new shots (scene.py, rendered to reel45/raw) with the v114 creature (the porcelain mask). Every
# clip keeps #2's length, so the cut times are identical and #2's audio.py lands on the same beats and hits.
# Writes edit.json for tools/comp_cantplay.mjs.
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
shots = {s["name"]: s["start"] for s in json.load(open(f"{S}/reel45/shots.json"))}
R = "reel45"
# (source reel, first source frame, number of frames, section, caption)
CLIPS = [
    (R, shots["hook"], 105, "hook", ""),                                          # the master bedroom, lamps on: cosy
    (R, shots["card"], 120, "card", ""),                                          # the same room in the moonlight
    (R, shots["open"], 72, "clip", "night 19: the hall closet was open."),
    (R, shots["nest"], 33, "clip", "night 20: someone sleeps in there."),
    (R, shots["doorway"], 90, "clip", "night 21: he was in our doorway."),
    (R, shots["check"], 60, "clip", "night 22: he checks every hiding spot."),
    (R, shots["hide"], 60, "clip", "so tonight i hid in mom's closet."),
    (R, shots["warm"], 60, "clip", "it was still warm in here."),
    (R, shots["scare"], 75, "clip", "he sleeps where we hide."),
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
        if start in (shots["doorway"], shots["check"], shots["hide"]) and section == "clip":
            fr["bright"] = 1.6                       # (moonlight: lifted so a phone shows him)
        out.append(fr)
print(len(out), "frames =", len(out) / FPS, "s")
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
assert [c[2] for c in CLIPS] == [105, 120, 72, 33, 90, 60, 60, 60, 75, 30, 180], "the clips keep #2's lengths"
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 14, "next": "#15 next week...",
           "text": {"hook4": "(bring a friend. or two.)", "stamp": "he sleeps where we hide", "squad": "1 - 4 players", "goal": "survive the night"}},
          open("edit.json", "w"))
