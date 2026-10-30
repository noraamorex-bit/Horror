# Reel 56 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #9": mom texts again (the sequel to #7, 115K; the masked v114 look, as in the game).
# #2's format, look and music, all-new shots (scene.py, rendered to reel56/raw) with the v114 creature (the porcelain mask). Every
# clip keeps #2's length, so the cut times are identical and #2's audio.py lands on the same beats and hits.
# Writes edit.json for tools/comp_cantplay.mjs.
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
shots = {s["name"]: s["start"] for s in json.load(open(f"{S}/reel56/shots.json"))}
R = "reel56"
# (source reel, first source frame, number of frames, section, caption)
CLIPS = [
    (R, shots["hook"], 105, "hook", ""),                                          # Jamie's room, the lamps on: cosy
    (R, shots["card"], 120, "card", ""),                                          # the same room in the dark
    (R, shots["door"], 72, "clip", "night 36: mom texted \"are you\u00a0awake?\""),
    (R, shots["prints"], 33, "clip", "night 37: \"let me\u00a0in.\""),
    (R, shots["photo"], 90, "clip", "night 38: \"i'm\u00a0upstairs.\""),
    (R, shots["setup"], 60, "clip", "mom works\u00a0nights."),
    (R, shots["open"], 60, "clip", "so i called\u00a0her."),
    (R, shots["stood"], 60, "clip", "it rang under my\u00a0bed."),
    (R, shots["knew"], 75, "clip", "someone picked\u00a0up."),
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
        if start in (shots["prints"], shots["setup"], shots["stood"]) and section == "clip":
            fr["bright"] = 1.8                       # (the dark house: lifted so a phone shows it)
        out.append(fr)
print(len(out), "frames =", len(out) / FPS, "s")
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
assert [c[2] for c in CLIPS] == [105, 120, 72, 33, 90, 60, 60, 60, 75, 30, 180], "the clips keep #2's lengths"
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 9, "next": "#10 next week...",
           "text": {"hook4": "(bring a friend. or two.)", "stamp": "don't call her", "squad": "1 - 4 players", "goal": "survive the night"}},
          open("edit.json", "w"))
