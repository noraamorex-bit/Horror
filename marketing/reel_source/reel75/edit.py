# Reel 75 — "ROBLOX HORROR GAMES YOU CAN'T PLAY ALONE #2" (the sequel to reel 74; the owner: "the original reel style... high paced
# tension"). #2's format, look and music; every slot keeps #2's length, so the cut times are identical and #2's audio.py lands on
# the same beats and hits. Inside a slot the shots cut fast (scene.py's sub-shots), each inner cut a jolt (fr.jolt).
# Writes edit.json for tools/comp_cantplay.mjs.
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
R = "reel75"
shots = {s["name"]: (s["start"], s["n"]) for s in json.load(open(f"{S}/{R}/shots.json"))}
# (shots in the slot, section, caption)
SLOTS = [
    (["hook"], "hook", ""),
    (["card"], "card", ""),
    (["ceil", "jump"], "clip", "night 10: scratching above my\u00a0bed."),
    (["open"], "clip", "night 11: the hatch was open\u00a0again."),
    (["p1", "p2", "p3"], "clip", "night 12: wet footprints. to my\u00a0room."),
    (["nail", "nail2"], "clip", "so we nailed it\u00a0shut."),
    (["loose", "nails"], "clip", "tonight i heard the\u00a0nails."),
    (["open2", "hole"], "clip", "the hatch was\u00a0open."),
    (["up7", "turn"], "clip", "he was already down\u00a0here."),
    (["run"], "clip", "RUN."),
    (["card"], "end", ""),
]
BRIGHT = {"ceil": 1.6, "jump": 1.6, "open": 1.6, "p1": 1.7, "p2": 1.7, "p3": 1.6, "loose": 1.5, "nails": 1.6, "open2": 1.6, "hole": 1.7, "up7": 1.7, "turn": 1.4}
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
            first = False
        elif section == "end":
            a = shots["card"][0]; p = i % 180
            x, src, first = "card", a + 20 + (p if p < 90 else 179 - p), False
        else:
            x, a, q, first = seq[i]
            src = a + q
        fr = {"src": f"{S}/{R}/raw/{src:04d}.png", "section": section, "cap": cap, "k": i / max(1, n - 1), "i": i}
        if section == "clip" and x in BRIGHT:
            fr["bright"] = BRIGHT[x]
        if section == "clip" and len(names) > 1:
            # frames since the last inner cut (a jolt for the first few)
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
json.dump({"frames": out, "cuts": cuts, "num": 2, "next": "#3 next week...",
           "text": {"hook4": "(bring a friend. or two.)", "stamp": "found this upstairs", "squad": "1 - 4 players", "goal": "survive the night"}},
          open("edit.json", "w"))
