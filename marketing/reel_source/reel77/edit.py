# Reel 77 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #4" (the new run): the doorbell camera; he has a key. #2's format, look and
# music; every slot keeps #2's length, so the cut times are identical and #2's audio.py lands on the same beats and hits. Inside a
# slot the shots cut fast (scene.py's sub-shots), each inner cut a jolt (fr.jolt). The doorbell and porch cameras' views go through
# comp_cantplay's camera overlay (fr.cam: grey night vision, the label, a running clock).
# Writes edit.json for tools/comp_cantplay.mjs.
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
R = "reel77"
shots = {s["name"]: (s["start"], s["n"]) for s in json.load(open(f"{S}/{R}/shots.json"))}
SLOTS = [
    (["hook"], "hook", ""),
    (["card"], "card", ""),
    (["dopen", "away"], "clip", "night 15: the doorbell cam. 6\u00a0am."),
    (["walk"], "clip", "he left every\u00a0morning."),
    (["come", "steps", "at"], "clip", "night 16: 11 pm. he came\u00a0back."),
    (["key", "shut"], "clip", "with his own\u00a0key."),
    (["notify", "empty"], "clip", "tonight he didn't\u00a0leave."),
    (["inhall", "stairs"], "clip", "he's still\u00a0inside."),
    (["look", "on"], "clip", "he's been upstairs all\u00a0day."),
    (["run"], "clip", "RUN."),
    (["card"], "end", ""),
]
BRIGHT = {"key": 1.3, "inhall": 1.6, "stairs": 1.5, "look": 1.5, "on": 1.3, "notify": 1.2}
# (the cameras: label, clock, rain, date)
CAM = {"dopen": ("FRONT DOOR", [6, 2, 14], False, "NOV 14"), "away": ("FRONT DOOR", [6, 2, 15], False, "NOV 14"),
       "walk": ("FRONT DOOR", [6, 4, 40], False, "NOV 15"), "come": ("FRONT DOOR", [23, 1, 8], True, "NOV 15"),
       "steps": ("FRONT DOOR", [23, 1, 30], True, "NOV 15"), "at": ("PORCH", [23, 1, 41], True, "NOV 15"),
       "shut": ("PORCH", [23, 2, 3], True, "NOV 15"), "empty": ("PORCH", [6, 31, 12], False, "NOV 16")}
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
            lab, clock, rain, date = CAM[x]
            fr["cam"] = {"label": lab, "clock": clock, "rain": rain, "date": date}
            fr["bright"] = 1.05
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
json.dump({"frames": out, "cuts": cuts, "num": 4, "next": "#5 next week...",
           "text": {"hook4": "(bring a friend. or two.)", "stamp": "he has a key", "squad": "1 - 4 players", "goal": "survive the night"}},
          open("edit.json", "w"))
