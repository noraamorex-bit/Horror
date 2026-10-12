# Reel 22 — "AMAZING NEW ROBLOX HORROR GAME TO PLAY WITH YOUR FRIENDS": every rendered frame in order
# (scene.py cuts on the bar / half bar of audio.py's 128 BPM track), with a short caption per clip
# (*word* = the accent colour). Writes edit.json for tools/comp_gameplay.mjs.
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
BAR = 60 / 128 * 4
shots = json.load(open(f"{S}/reel22/shots.json"))
CAPS = {
    "living": "chill with your *friends*",
    "pizza": "the pizza guy is... *weird*",
    "out": "then the lights *go out*",
    "stairs": "and *HE* shows up",
    "explore": "explore the *dark house*",
    "run": "*RUN*",
    "pov": "don't get *caught*",
    "hide": "*hide*",
    "tied": "he takes your *friends*",
    "free": "*save* them",
    "dinner": "find the *secret ending*",
    "escape": "escape *together*",
    "survive": "survive the *night*",
}
END_AT = round(12 * BAR * FPS)                       # the end card from bar 13
out, cuts = [], []
for s in shots:
    cuts.append(round(s["start"] / FPS, 4))
    for i in range(s["n"]):
        f = s["start"] + i
        section = "hook" if s["name"] == "hook" else ("end" if f >= END_AT else "clip")
        out.append({"src": f"{S}/reel22/raw/{f:04d}.png", "section": section, "cap": CAPS.get(s["name"], ""),
                    "i": f - END_AT if section == "end" else i, "k": i / max(1, s["n"] - 1)})
cuts = [c for c in cuts if c * FPS < END_AT]
print(len(out), "frames =", round(len(out) / FPS, 2), "s; cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "bpm": 128, "drop": round(2 * BAR, 4), "text": {}}, open("edit.json", "w"))
