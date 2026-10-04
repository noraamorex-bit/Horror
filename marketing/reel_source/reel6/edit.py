# Reel 6 — "CAN YOU SPOT HIM?": three rounds, easy / hard / impossible, then he finds you.
# Rounds 1-2 are fresh renders (raw/), round 3 and the scare come from reel 1. Writes edit.json.
import json

S = "/tmp/claude-0/-home-user-Horror/84f4b59f-d9bd-5c4a-9b16-ad5ba90d0af8/scratchpad"
R6 = f"{S}/reel6/raw"
R1 = f"{S}/reel/raw"
# where he is on the last frame of each hidden round (1080x1920 px), for the reveal circle
SPOT1 = [450, 480]
SPOT2 = [715, 790]
# (section, frames, source(i) -> path, extra)
SEGS = [
    ("round", 110, lambda i: f"{R6}/{110 + i:04d}.png", {"round": 1, "level": "EASY"}),
    ("reveal", 40, lambda i: f"{R6}/0219.png", {"spot": SPOT1, "say": "too easy."}),
    ("round", 110, lambda i: f"{R6}/{i:04d}.png", {"round": 2, "level": "HARD"}),
    ("reveal", 50, lambda i: f"{R6}/0109.png", {"spot": SPOT2, "say": "he was watching the whole time."}),
    ("round", 96, lambda i: f"{R1}/{300 + int(i * 0.6):04d}.png", {"round": 3, "level": "IMPOSSIBLE"}),
    ("scare", 30, lambda i: f"{R1}/{592 + i:04d}.png", {}),
    ("end", 165, lambda i: f"{R1}/{96 + i % 66:04d}.png", {}),
]
out, cuts, t = [], [], 0
for sec, n, src, extra in SEGS:
    cuts.append(round(t / 30, 3))
    for i in range(n):
        e = {"src": src(i), "section": sec, "i": i, "n": n, "k": i / max(1, n - 1)}
        e.update(extra)
        out.append(e)
    t += n
print(len(out), "frames =", len(out) / 30, "s; cuts", cuts)
json.dump({"frames": out, "cuts": cuts}, open("edit.json", "w"))
