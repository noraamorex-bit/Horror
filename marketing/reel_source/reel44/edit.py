# Reel 44 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #13": the chapter after #12 ("he's not hiding anymore").
# #2's format, look and music, all-new shots (scene.py, rendered to reel44/raw) with the v114 creature (the porcelain mask). Every
# clip keeps #2's length, so the cut times are identical and #2's audio.py lands on the same beats and hits.
# Writes edit.json for tools/comp_cantplay.mjs.
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
shots = {s["name"]: s["start"] for s in json.load(open(f"{S}/reel44/shots.json"))}
R = "reel44"
# (source reel, first source frame, number of frames, section, caption)
CLIPS = [
    (R, shots["hook"], 105, "hook", ""),                                          # the dining table, lamps on: cosy
    (R, shots["card"], 120, "card", ""),                                          # the same table in the dark
    (R, shots["open"], 72, "clip", "night 15: five plates. there's four of us."),
    (R, shots["prints"], 33, "clip", "night 16: someone ate from it."),
    (R, shots["door"], 90, "clip", "night 17: he tucked my sister in."),
    (R, shots["beside"], 60, "clip", "night 18: he sat at the head of the table."),
    (R, shots["nailed"], 60, "clip", "so tonight we're leaving."),
    (R, shots["nails"], 60, "clip", "the car keys were on his plate."),
    (R, shots["behind"], 75, "clip", "he doesn't want us to leave."),
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
        if start == shots["door"] and section == "clip":
            fr["bright"] = 2.2                       # (her night light: lifted so a phone shows him by the bed)
        out.append(fr)
print(len(out), "frames =", len(out) / FPS, "s")
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
assert [c[2] for c in CLIPS] == [105, 120, 72, 33, 90, 60, 60, 60, 75, 30, 180], "the clips keep #2's lengths"
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 13, "next": "#14 next week...",
           "text": {"hook4": "(bring a friend. or two.)", "stamp": "he wants a family", "squad": "1 - 4 players", "goal": "survive the night"}},
          open("edit.json", "w"))
