# Reel 61 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #14": the family group chat (quoted texts with a twist, after #7's mom's
# texts, 115K; the masked v114 look). #2's format, look and music; all-new shots (scene.py, rendered to reel61/raw). Every clip
# keeps #2's length, so the cut times are identical and #2's audio.py lands on the same beats and hits.
# Writes edit.json for tools/comp_cantplay.mjs.
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
shots = {s["name"]: s["start"] for s in json.load(open(f"{S}/reel61/shots.json"))}
R = "reel61"
# (source reel, first source frame, number of frames, section, caption)
CLIPS = [
    (R, shots["hook"], 105, "hook", ""),                                          # my room, the lamps on: cosy
    (R, shots["card"], 120, "card", ""),                                          # the same room in the dark
    (R, shots["door"], 72, "clip", "night 51: \"dad\" joined our family\u00a0chat."),
    (R, shots["prints"], 33, "clip", "we don't have a\u00a0dad."),
    (R, shots["photo"], 90, "clip", "night 52: \"which room is\u00a0lily's?\""),
    (R, shots["setup"], 60, "clip", "so mom blocked\u00a0him."),
    (R, shots["open"], 60, "clip", "tonight he texted\u00a0me."),
    (R, shots["stood"], 60, "clip", "\"you look so\u00a0peaceful.\""),
    (R, shots["knew"], 75, "clip", "\"goodnight,\u00a0son.\""),
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
        if start in (shots["prints"], shots["photo"], shots["setup"], shots["stood"]) and section == "clip":
            fr["bright"] = 1.7                       # (the dark house: lifted so a phone shows it)
        out.append(fr)
print(len(out), "frames =", len(out) / FPS, "s")
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
assert [c[2] for c in CLIPS] == [105, 120, 72, 33, 90, 60, 60, 60, 75, 30, 180], "the clips keep #2's lengths"
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 14, "next": "#15 next week...",
           "text": {"hook4": "(bring a friend. or two.)", "stamp": "we don't have a dad", "squad": "1 - 4 players", "goal": "survive the night"}},
          open("edit.json", "w"))
