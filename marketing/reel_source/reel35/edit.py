# Reel 35 — the story format (#3) on #2's track. Every rendered frame in order (the clips keep #2's
# lengths, so #2's cuts and hits land), marked for tools/comp_story.mjs: the hook's two lines appearing
# chunk by chunk on the music box notes (0-3.5 s), the card's two lines typed on the track's first and
# third pops after the drop (3.85 / 5.25 s), one typed line per clip after that, the scare when the
# his face comes into the tent flap (22.15 s), "RUN." on the last clip, and the black end card (23.5-29.5 s), with
# the brand banner (NEW ROBLOX HORROR GAME + the name) throughout (comp_story's default).
# Writes edit.json (and the cut times audio.py reads).
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
shots = json.load(open(f"{S}/reel35/shots.json"))
SCARE = 664  # (frame 64 of the 9th clip: 22.15 s)

def line(*chunks):
    return [[c, False] if isinstance(c, str) else [c[0], True] for c in chunks]
RED = lambda s: (s,)
HOOK = [line("my ", "little ", "sister"), line("set a place ", "for a ", RED("guest."))]
HOOK_TIMES = [0.25, 0.7, 1.15, 1.6, 2.05, 2.6]
CAPS = {
    "out": [line("her music box ", RED("opened."))],
    "prints": [line("the door ", RED("creaked."))],
    "far": [line("he came for ", RED("tea."))],
    "smile": [line("and he ", RED("saw"), " me.")],
    "in": [line("so i hid in her ", RED("tent."))],
    "past": [line("he ", RED("knew"), " i was there.")],
    "tear": [line("don't. ", RED("move."))],
}
out = []
for s in shots:
    for i in range(s["n"]):
        f = s["start"] + i
        t = f / FPS
        fr = {"src": f"{S}/reel35/raw/{f:04d}.png", "section": "hook" if s["name"] == "hook" else "clip", "i": i}
        name = s["name"]
        if name == "hook":
            fr.update(cap=HOOK, capT=i / FPS, chunkTimes=HOOK_TIMES)
        elif name == "card":
            # "we laughed at her." on the drop's first pop, "every night." on the third
            if t >= 3.85:
                lines = [line("we thought he was")]
                if t >= 5.25:
                    lines.append(line(RED("imaginary.")))
                # (the second line types from its own pop)
                fr.update(cap=lines, capT=(t - 3.85) if t < 5.25 else (len("we thought he was") / 34 + (t - 5.25)))
        elif name in CAPS:
            # each clip's line types in from its start (the last line goes just before the scare)
            if not (name == "tear" and f >= SCARE - 6):
                fr.update(cap=CAPS[name], capT=i / FPS, capSpeed=34)
                if name == "tear" and f >= SCARE - 14:
                    fr["capFade"] = max(0.0, (SCARE - 6 - f) / 8)
        if name == "tear" and f >= SCARE:
            fr.update(scare=True, scareI=f - SCARE)
        if name == "run":
            fr.update(run=True, runI=i)
        out.append(fr)
# the end card: 6 s
for i in range(180):
    out.append({"src": None, "section": "end", "i": i})
print(len(out), "frames =", round(len(out) / FPS, 2), "s")
cuts, t = [], 0
for n in [105, 120, 72, 33, 90, 60, 60, 60, 75, 30, 180]:
    cuts.append(round(t / FPS, 3)); t += n
assert [s["n"] for s in shots] == [105, 120, 72, 33, 90, 60, 60, 60, 75, 30], "the clips keep #2's lengths"
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "text": {}}, open("edit.json", "w"))
