# Reel 14 — "RULES TO SURVIVE THIS ROBLOX HORROR GAME": a new format (a numbered rule per shot, each
# with a RULE n tape label) in a caution-tape palette (hazard yellow, black, danger red, white).
# Caption markup: *yellow* _white_ ^red^. Writes edit.json for comp13.mjs.
import json
S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
FPS = 30
CLIPS = [
    ("reel", 300, 105, "hook", "", 0),                                          # the hall in the flashlight, him at the end
    ("reel3", 330, 120, "card", "", 0),                                         # the nest in the attic (slow)
    ("reel10", 0, 72, "clip", "never *run* near him.", 1),
    ("reel3", 120, 60, "clip", "*crouch.* he can't hear you.", 2),
    ("reel2", 330, 75, "clip", "hide. then ^hold your breath.^", 3),
    ("reel2", 450, 60, "clip", "he stops outside? *stay calm.*", 4),
    ("reel8", 195, 60, "clip", "never sleep ^alone.^", 5),
    ("reel9", 15, 75, "clip", "and *never* look up.", 6),
    ("reel", 500, 75, "clip", "hear him running? ^too late.^", 7),
    ("reel", 592, 30, "clip", "", 0),
    ("reel", 96, 180, "end", "", 0),
]
out = []
for reel, start, n, section, cap, rule in CLIPS:
    for i in range(n):
        src = start + i
        if section == "card": src = start + int(i * 0.64)
        if section == "end": src = 96 + (i % 66)
        out.append({"src": f"{S}/{reel}/raw/{src:04d}.png", "section": section, "cap": cap, "rule": rule, "k": i / max(1, n - 1), "i": i})
cuts, t = [], 0
for c in CLIPS:
    cuts.append(round(t / FPS, 3)); t += c[2]
print(len(out), "frames; cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "num": 7, "next": "rule 8 is in the game..."}, open("edit.json", "w"))
