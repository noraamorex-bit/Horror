# Reel 52 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #7" (the new run): mom's texts (a new hook; the masked v114 look, as in the game).
# #2's format, look and music, all-new shots (scene.py, rendered to reel55/raw) with the v114 creature (the porcelain mask). Every
# clip keeps #2's length, so the cut times are identical and #2's audio.py lands on the same beats and hits.
# Writes edit.json for tools/comp_cantplay.mjs.
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
shots = {s["name"]: s["start"] for s in json.load(open(f"{S}/reel55/shots.json"))}
R = "reel55"
# (source reel, first source frame, number of frames, section, caption)
CLIPS = [
    (R, shots["hook"], 105, "hook", ""),                                          # Jamie's room, the lamps on: cosy
    (R, shots["card"], 120, "card", ""),                                          # the same room in the dark
    (R, shots["door"], 72, "clip", "night 33: someone joined our family\u00a0map."),
    (R, shots["prints"], 33, "clip", "night 34: his dot was in our\u00a0yard."),
    (R, shots["photo"], 90, "clip", "night 35: in our\u00a0kitchen."),
    (R, shots["setup"], 60, "clip", "tonight his dot was on\u00a0mine."),
    (R, shots["open"], 60, "clip", "i checked my\u00a0room."),
    (R, shots["stood"], 60, "clip", "i checked the\u00a0hall."),
    (R, shots["knew"], 75, "clip", "then i looked\u00a0up."),
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
        if start in (shots["prints"], shots["photo"], shots["open"], shots["stood"]) and section == "clip":
            fr["bright"] = 1.8                       # (the dark house: lifted so a phone shows it)
        if start == shots["door"] and section == "clip":
            fr["bright"] = 0.95                      # (the lit phone on the white sheet: held down or it blows out)
        out.append(fr)
print(len(out), "frames =", len(out) / FPS, "s")
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
assert [c[2] for c in CLIPS] == [105, 120, 72, 33, 90, 60, 60, 60, 75, 30, 180], "the clips keep #2's lengths"
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 8, "next": "#9 next week...",
           "text": {"hook4": "(bring a friend. or two.)", "stamp": "he's on our map", "squad": "1 - 4 players", "goal": "survive the night"}},
          open("edit.json", "w"))
