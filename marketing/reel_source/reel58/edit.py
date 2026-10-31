# Reel 58 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #11": Lily's baby monitor (an everyday thing with a quoted twist, after #7's
# mom's texts, 115K; the masked v114 look). #2's format, look and music; all-new shots (scene.py, rendered to reel58/raw). Every clip
# keeps #2's length, so the cut times are identical and #2's audio.py lands on the same beats and hits. The monitor's views go
# through comp_cantplay's camera overlay (fr.cam: grey night vision, "LILY'S ROOM", a running clock).
# Writes edit.json for tools/comp_cantplay.mjs.
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
shots = {s["name"]: s["start"] for s in json.load(open(f"{S}/reel58/shots.json"))}
R = "reel58"
# (source reel, first source frame, number of frames, section, caption)
CLIPS = [
    (R, shots["hook"], 105, "hook", ""),                                          # Lily's room, the light on: cosy
    (R, shots["card"], 120, "card", ""),                                          # the same room in the dark
    (R, shots["door"], 72, "clip", "night 42: lily's baby monitor turned\u00a0on."),
    (R, shots["prints"], 33, "clip", "night 43: someone was humming to\u00a0her."),
    (R, shots["photo"], 90, "clip", "night 44: \"shh. go back to\u00a0sleep.\""),
    (R, shots["setup"], 60, "clip", "so lily sleeps in my room\u00a0now."),
    (R, shots["open"], 60, "clip", "tonight it turned on\u00a0again."),
    (R, shots["stood"], 60, "clip", "it was showing my\u00a0room."),
    (R, shots["knew"], 75, "clip", "\"shh. go back to\u00a0sleep.\""),
    (R, shots["run"], 30, "clip", "RUN."),
    (R, shots["card"], 180, "end", ""),
]
# the monitor's views: (date, clock at the clip's first frame, brightness)
CAM = {shots["prints"]: ("OCT 28", [3, 12, 4], 1.05), shots["photo"]: ("OCT 29", [3, 14, 40], 1.05), shots["stood"]: ("OCT 31", [3, 12, 0], 1.3)}
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
        if start in (shots["setup"],) and section == "clip":
            fr["bright"] = 1.7                       # (the dark house: lifted so a phone shows it)
        if start in (shots["door"], shots["open"]) and section == "clip":
            fr["bright"] = 1.25
        if start in CAM and section == "clip":
            date, clock, br = CAM[start]
            fr["cam"] = {"label": "LILY'S ROOM", "clock": clock, "date": date, "rain": False}
            fr["bright"] = br
        out.append(fr)
print(len(out), "frames =", len(out) / FPS, "s")
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
assert [c[2] for c in CLIPS] == [105, 120, 72, 33, 90, 60, 60, 60, 75, 30, 180], "the clips keep #2's lengths"
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 11, "next": "#12 next week...",
           "text": {"hook4": "(bring a friend. or two.)", "stamp": "don't check the monitor", "squad": "1 - 4 players", "goal": "survive the night"}},
          open("edit.json", "w"))
