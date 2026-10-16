# The Halloween 2026 badge icon (512x512, the same look as the other badges: dark disc, coloured ring,
# a glyph and one word). python3 make_halloween.py
from PIL import Image, ImageDraw, ImageFont
import math
F = "/mnt/skills/examples/canvas-design/canvas-fonts/"
S = 4  # supersample
W = 512 * S
im = Image.new("RGBA", (W, W), (0, 0, 0, 0))
d = ImageDraw.Draw(im)
ORANGE, DARK = (255, 140, 40), (22, 22, 26)
d.ellipse([16 * S, 16 * S, W - 16 * S, W - 16 * S], fill=ORANGE)
d.ellipse([30 * S, 30 * S, W - 30 * S, W - 30 * S], fill=DARK)
# a soft lift in the middle, like the others
for r in range(200, 0, -4):
    a = int(10 * (1 - r / 200))
    d.ellipse([W / 2 - r * S, 220 * S - r * S, W / 2 + r * S, 220 * S + r * S], fill=(22 + a, 22 + a, 28 + a))
# the jack-o'-lantern: ribs, stem, carved face
cx, cy = W / 2, 228 * S
for dx, w, col in [(-58, 96, (226, 110, 26)), (58, 96, (226, 110, 26)), (-28, 104, (244, 126, 32)), (28, 104, (244, 126, 32)), (0, 110, ORANGE)]:
    d.ellipse([cx + (dx - w / 2) * S, cy - 78 * S, cx + (dx + w / 2) * S, cy + 78 * S], fill=col)
d.rounded_rectangle([cx - 8 * S, cy - 104 * S, cx + 10 * S, cy - 70 * S], radius=5 * S, fill=(90, 110, 60))
for side in (-1, 1):
    ex = cx + side * 42 * S
    d.polygon([(ex - 20 * S, cy - 4 * S), (ex + 20 * S, cy - 4 * S), (ex + side * 6 * S, cy - 40 * S)], fill=DARK)
d.polygon([(cx - 10 * S, cy + 14 * S), (cx + 10 * S, cy + 14 * S), (cx, cy - 2 * S)], fill=DARK)
pts = []
for i in range(0, 13):
    t = i / 12
    x = cx + (-64 + 128 * t) * S
    y = cy + (30 + 22 * math.sin(math.pi * t)) * S
    pts.append((x, y))
upper = [(cx + (-64 + 128 * (i / 12)) * S, cy + (26 + 4 * math.sin(math.pi * i / 12)) * S + (10 * S if i in (4, 8) else 0)) for i in range(0, 13)]
d.polygon(upper + pts[::-1], fill=DARK)
f = ImageFont.truetype(F + "BigShoulders-Bold.ttf", 54 * S)
txt = "HALLOWEEN"
tw = d.textlength(txt, font=f) + 6 * S * (len(txt) - 1)
x = cx - tw / 2
for ch in txt:
    d.text((x, 346 * S), ch, font=f, fill=(244, 236, 222))
    x += d.textlength(ch, font=f) + 6 * S
im.resize((512, 512), Image.LANCZOS).save("Halloween2026.png")
print("ok")
