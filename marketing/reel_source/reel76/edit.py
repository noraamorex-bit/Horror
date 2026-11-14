# Reel 76 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #3" (the new run): mom's texts and the hall camera. #2's format, look and
# music; every slot keeps #2's length, so the cut times are identical and #2's audio.py lands on the same beats and hits. Inside a
# slot the shots cut fast (scene.py's sub-shots), each inner cut a jolt (fr.jolt). The hall camera's views go through
# comp_cantplay's camera overlay (fr.cam: grey night vision, the label, a running clock).
# Writes edit.json for tools/comp_cantplay.mjs.
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
R = "reel76"
shots = {s["name"]: (s["start"], s["n"]) for s in json.load(open(f"{S}/{R}/shots.json"))}
SLOTS = [
    (["hook"], "hook", ""),
    (["card"], "card", ""),
    (["txt", "crack"], "clip", "night 13: mom texted \"who's in the hall?\""),
    (["empty"], "clip", "nobody was."),
    (["hopen", "hole", "hshut"], "clip", "night 14: \"why is the hatch open?\""),
    (["hcam", "cview"], "clip", "mom watches the cameras at work."),
    (["txt2", "door"], "clip", "tonight: \"he's outside your door.\""),
    (["atdoor"], "clip", "\"don't open it.\""),
    (["gone", "turn"], "clip", "\"he's not in the hall anymore.\""),
    (["run"], "clip", "RUN."),
    (["card"], "end", ""),
]
BRIGHT = {"crack": 1.7, "empty": 1.6, "hopen": 1.6, "hole": 1.7, "hshut": 1.7, "hcam": 1.4, "door": 1.8, "turn": 1.4}
CAM = {"cview": [3, 12, 40], "atdoor": [3, 14, 2], "gone": [3, 16, 51]}
out, lens = [], []
for names, section, cap in SLOTS:
    n = 180 if section == "end" else sum(shots[x][1] for x in names)
    lens.append(n)
    seq = []
    for j, x in enumerate(names):
        a, m = shots[x]
        for q in range(m):
            seq.append((x, a, q, j > 0 and q == 0))
    for i in range(n):
        if section == "card":
            x, a, q, _ = seq[int(i * 0.64)]                      # slow motion
            src = a + q
        elif section == "end":
            a = shots["card"][0]; p = i % 180
            x, src = "card", a + 20 + (p if p < 90 else 179 - p)
        else:
            x, a, q, _ = seq[i]
            src = a + q
        fr = {"src": f"{S}/{R}/raw/{src:04d}.png", "section": section, "cap": cap, "k": i / max(1, n - 1), "i": i}
        if section == "clip" and x in BRIGHT:
            fr["bright"] = BRIGHT[x]
        if section == "clip" and x in CAM:
            fr["cam"] = {"label": "UPSTAIRS HALL", "clock": CAM[x], "rain": False, "date": "NOV 1" + str(3 + (x != "cview"))}
            fr["bright"] = 1.15
        if section == "clip" and len(names) > 1:
            starts = [sum(shots[y][1] for y in names[:j]) for j in range(1, len(names))]
            past = [i - s0 for s0 in starts if i >= s0]
            if past: fr["jolt"] = min(past)
        out.append(fr)
assert lens == [105, 120, 72, 33, 90, 60, 60, 60, 75, 30, 180], ("the slots keep #2's lengths", lens)
print(len(out), "frames =", len(out) / FPS, "s")
cuts, t = [], 0
for n in lens:
    cuts.append(round(t / FPS, 3)); t += n
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 3, "next": "#4 next week...",
           "text": {"hook4": "(bring a friend. or two.)", "stamp": "mom watches the cameras", "squad": "1 - 4 players", "goal": "survive the night"}},
          open("edit.json", "w"))
