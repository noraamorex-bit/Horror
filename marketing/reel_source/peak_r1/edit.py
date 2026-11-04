# "PEAK ROBLOX HORROR GAME TO PLAY WITH FRIENDS" restarted at (Part 1) and (Part 2) (4 Nov; the owner: "Bring back the peak
# Roblox game thing with this sound. Start from part 1."): reel 25's format (tools/comp_peak.mjs) on #2's track, cut from the
# full-size renders of reels 61-64 (their raw frames: the masked v114 creature). No story text: the hook word by word, the
# three-line card, OUT NOW, the pixelated scare on 22.15 s, the glitch line on RUN, the black end card.
#   python3 edit.py 1|2  -> edit.json in the current folder
import json, os, sys

S = os.environ.get("REEL_SCRATCH", "/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad")
FPS = 30
PART = int(sys.argv[1]) if len(sys.argv) > 1 else 1
def starts(r): return {s["name"]: s["start"] for s in json.load(open(f"{S}/reel{r}/shots.json"))}
SH = {r: starts(r) for r in (61, 62, 63, 64)}
# (reel, shot, first frame in it, speed, dark): every slot keeps #2's length
if PART == 1:
    # the hiding night: Lily's dark room, him in her doorway, at the end of the hall, bent over my bed; the lamp on, then
    # dark, my door ajar... the wardrobe creaks open: his mask in the gap (reel 62's scare); RUN.
    SLOTS = [(63, "card", 0, 1.0, False), (64, "card", 0, 0.64, False), (61, "photo", 0, 1.0, True), (64, "prints", 0, 1.0, True),
             (64, "photo", 0, 1.0, True), (64, "setup", 0, 1.0, False), (64, "open", 0, 1.0, True), (62, "stood", 0, 1.0, True),
             (62, "knew", 0, 1.0, False), (62, "run", 0, 1.0, False)]
    TEXT = {"part": "(Part 1)", "glitch": "he was in the closet"}
else:
    # Lily's room: him at the foot of her bed, bent over her, his head comes round; the stairs; my lamp, my door ajar; the
    # empty upstairs hall... turn round: he's right behind you (reel 63's scare); RUN.
    SLOTS = [(63, "stood", 0, 0.57, True), (61, "card", 0, 0.64, False), (63, "prints", 0, 0.46, True), (61, "prints", 0, 1.0, True),
             (63, "photo", 0, 1.0, True), (64, "hook", 20, 1.0, False), (61, "stood", 0, 1.0, True), (63, "stood", 0, 1.0, True),
             (63, "knew", 0, 1.0, False), (63, "run", 0, 1.0, False)]
    TEXT = {"part": "(Part 2)", "glitch": "don't turn around"}
LENS = [105, 120, 72, 33, 90, 60, 60, 60, 75, 30]
CARD_POPS = [3.85, 4.55, 5.25, 5.95]
SCARE = (665, 675)
GLITCH = (677, 691)
out, g = [], 0
for (r, name, first, speed, dark), n in zip(SLOTS, LENS):
    for i in range(n):
        src = SH[r][name] + first + int(i * speed)
        t = g / FPS
        fr = {"src": f"{S}/reel{r}/raw/{src:04d}.png", "section": "hook" if g < 105 else "clip", "i": i}
        if g >= 105:
            fr["cardLines"] = sum(1 for p in CARD_POPS if t >= p)
        if dark:
            fr["bright"] = 1.6
        if SCARE[0] <= g < SCARE[1]: fr["scare"] = True
        if GLITCH[0] <= g < GLITCH[1]: fr["glitchText"] = True
        out.append(fr)
        g += 1
for i in range(180):
    out.append({"src": None, "section": "end", "i": i})
cuts, t = [], 0
for n in LENS + [180]:
    cuts.append(round(t / FPS, 3)); t += n
TEXT["hookTimes"] = [0.25, 0.7, 1.15, 1.6, 2.05, 2.6]
print(len(out), "frames =", round(len(out) / FPS, 2), "s; part", PART)
json.dump({"frames": out, "cuts": cuts, "text": TEXT}, open("edit.json", "w"))
