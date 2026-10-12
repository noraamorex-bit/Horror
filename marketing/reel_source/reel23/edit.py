# Reel 23 — the "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS" format: every rendered frame in order,
# marked for tools/comp_peak.mjs: the hook over the first two bars, the card after it, the scare, the
# game's thinking-out-loud lines in two shots, the glitch text (bar 6.5, like the reference's at ~13.6 s),
# the end card from bar 8. Writes edit.json.
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
BAR = 60 / 112 * 4 * FPS
shots = {s["name"]: s for s in json.load(open(f"{S}/reel23/shots.json"))}
total = sum(s["n"] for s in shots.values())
GLITCH = (round(6.5 * BAR) - 8, round(6.5 * BAR) + 12)       # (around the cut into the bedroom)
THOUGHTS = {}   # (the reference has no lines besides the card and the low one)
out = []
for f in range(total):
    name = next(n for n, s in shots.items() if s["start"] <= f < s["start"] + s["n"])
    s = shots[name]
    i = f - s["start"]
    section = "hook" if name == "porch" else ("end" if name == "tail" else "clip")
    fr = {"src": f"{S}/reel23/raw/{f:04d}.png", "section": section, "i": i}
    if name == "porch": fr["rain"] = True
    if name == "scare": fr["scare"] = True
    if name in THOUGHTS and i >= 6: fr["thought"] = THOUGHTS[name]; fr["ti"] = i - 6
    if GLITCH[0] <= f < GLITCH[1]: fr["glitchText"] = True
    out.append(fr)
print(total, "frames =", round(total / FPS, 2), "s")
json.dump({"frames": out, "text": {}}, open("edit.json", "w"))
