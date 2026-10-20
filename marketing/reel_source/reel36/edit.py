# Reel 36 — "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS (Part 1)", the gameplay series. Every rendered
# frame in order (the clips keep #2's lengths, so #2's cuts and hits land), marked for tools/comp_peak.mjs:
# the hook word by word on the music box notes, the card's lines with the track's four pops after the
# drop, the brand tag throughout (comp_peak's default), and the game's HUD as you'd see it playing:
# the objective, the hotbar (flashlight, taser), the sprint bar in the chase, your friends in the chat,
# "Riley was caught!", the heartbeat minigame while he's at the crack ("He's moving away..."), then the
# scare when the doors are torn open (22.15 s), the glitch line on RUN, and the branded end card.
# Writes edit.json (and the cut times audio.py reads).
import json, os

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
shots = json.load(open(f"{S}/reel36/shots.json"))
start = {s["name"]: s["start"] for s in shots}
CARD_POPS = [3.85, 4.55, 5.25, 5.95]
SCARE = start["tear"] + 64          # 664: 22.15 s
GLITCH = (677, 691)
RILEY, JAMIE = "#62b0ff", "#74de84"   # (the blue and the green hoodie)
CHAT = [(0.5, "Riley", RILEY, "did u guys hear that"), (1.9, "Jamie", JAMIE, "its downstairs"),
        (4.7, "Jamie", JAMIE, "WHAT IS THAT"), (5.7, "Riley", RILEY, "RUNNNN"),
        (10.4, "Jamie", JAMIE, "hide hide hide"), (12.1, "Riley", RILEY, "HELP"), (14.6, "Jamie", JAMIE, "riley??")]
HB0 = start["fold"]                 # the heartbeat minigame opens as he folds down to the crack
HB_HINT = "He's listening. Tap LEFT or RIGHT as each half reaches the heart."

def hud(f, name, i):
    # (no hotbar on the hook: "(Part 1)" sits where it does)
    t = f / FPS
    h = {"sel": 1 if name != "hook" else 0, "chat": [[n, c, m] for (tt, n, c, m) in CHAT if t >= tt][-3:]}
    h["obj"] = "Find the noise downstairs" if t < 7.5 else ("<b>!</b> Hide from him" if name != "run" else "<b>!</b> Get out of the house")
    if name == "chase":
        h["stam"] = 1.0 - 0.55 * i / 72
    elif name == "in":
        h["stam"] = 0.45 + 0.05 * i / 33
    elif name == "run":
        h["stam"] = 0.9 - 0.25 * i / 30
    if name == "caught" and i >= 44:
        h["notice"] = "Riley was caught!"
    if HB0 <= f < start["tear"] + 46:
        h["hb"] = (f - HB0) / FPS
        h["hbHint"] = HB_HINT if f < start["tear"] + 26 else "He's moving away..."
        h["chat"] = []          # (the minigame takes the screen)
    return h

out = []
for s in shots:
    for i in range(s["n"]):
        f = s["start"] + i
        t = f / FPS
        fr = {"src": f"{S}/reel36/raw/{f:04d}.png", "section": "hook" if s["name"] == "hook" else "clip", "i": i, "hud": hud(f, s["name"], i)}
        if s["name"] != "hook":
            fr["cardLines"] = sum(1 for p in CARD_POPS if t >= p)
        if SCARE <= f < SCARE + 12: fr.update(scare=True, scareI=f - SCARE)
        if GLITCH[0] <= f < GLITCH[1]: fr["glitchText"] = True
        out.append(fr)
# the end card: 6 s (black, a noise burst on the way in, then the name and the search bar)
for i in range(180):
    out.append({"src": None, "section": "end", "i": i})
print(len(out), "frames =", round(len(out) / FPS, 2), "s")
cuts, t = [], 0
for n in [105, 120, 72, 33, 90, 60, 60, 60, 75, 30, 180]:
    cuts.append(round(t / FPS, 3)); t += n
assert [s["n"] for s in shots] == [105, 120, 72, 33, 90, 60, 60, 60, 75, 30], "the clips keep #2's lengths"
assert SCARE == 664
print("cuts", cuts)
json.dump({"frames": out, "cuts": cuts, "text": {"part": "(Part 1)", "glitch": "he found you", "hookTimes": [0.25, 0.7, 1.15, 1.6, 2.05, 2.6]}},
          open("edit.json", "w"))
