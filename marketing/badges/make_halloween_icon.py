# The Halloween game icon: the normal icon (marketing/attic/icon_1024.png) with a glowing
# jack-o'-lantern in the corner and a HALLOWEEN banner. python3 make_halloween_icon.py (from marketing/badges)
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
F = "/mnt/skills/examples/canvas-design/canvas-fonts/"
base = Image.open("../attic/icon_1024.png").convert("RGBA")
W = base.size[0]
layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
d = ImageDraw.Draw(layer)
ORANGE, DARK = (255, 132, 30), (24, 14, 8)
# the jack-o'-lantern, bottom right, with a warm glow around it
cx, cy, R = 812, 842, 150
glow = Image.new("RGBA", base.size, (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
gd.ellipse([cx - R * 1.9, cy - R * 1.7, cx + R * 1.9, cy + R * 1.7], fill=(255, 120, 20, 120))
glow = glow.filter(ImageFilter.GaussianBlur(70))
for dx, w, col in [(-0.62, 1.0, (214, 100, 22)), (0.62, 1.0, (214, 100, 22)), (-0.3, 1.1, (238, 118, 28)), (0.3, 1.1, (238, 118, 28)), (0, 1.16, ORANGE)]:
    d.ellipse([cx + (dx - w / 2) * R, cy - 0.82 * R, cx + (dx + w / 2) * R, cy + 0.82 * R], fill=col)
d.rounded_rectangle([cx - 0.09 * R, cy - 1.1 * R, cx + 0.11 * R, cy - 0.72 * R], radius=8, fill=(84, 104, 54))
FACE = (255, 214, 90)
for side in (-1, 1):
    ex = cx + side * 0.42 * R
    d.polygon([(ex - 0.22 * R, cy - 0.02 * R), (ex + 0.22 * R, cy - 0.02 * R), (ex + side * 0.06 * R, cy - 0.42 * R)], fill=FACE)
d.polygon([(cx - 0.1 * R, cy + 0.15 * R), (cx + 0.1 * R, cy + 0.15 * R), (cx, cy - 0.03 * R)], fill=FACE)
low = [(cx + (-0.66 + 1.32 * i / 12) * R, cy + (0.3 + 0.24 * math.sin(math.pi * i / 12)) * R) for i in range(13)]
up = [(cx + (-0.66 + 1.32 * i / 12) * R, cy + (0.27 + 0.05 * math.sin(math.pi * i / 12)) * R + (0.1 * R if i in (4, 8) else 0)) for i in range(13)]
d.polygon(up + low[::-1], fill=FACE)
# the banner across the top-left corner
f = ImageFont.truetype(F + "BigShoulders-Bold.ttf", 92)
band = Image.new("RGBA", (900, 130), (0, 0, 0, 0))
bd = ImageDraw.Draw(band)
bd.rectangle([0, 0, 900, 130], fill=ORANGE + (255,))
t = "HALLOWEEN"
tw = bd.textlength(t, font=f) + 10 * (len(t) - 1)
x = 450 - tw / 2
for ch in t:
    bd.text((x, 8), ch, font=f, fill=DARK)
    x += bd.textlength(ch, font=f) + 10
band = band.rotate(45, expand=True, resample=Image.BICUBIC)
out = Image.alpha_composite(base, glow)
out = Image.alpha_composite(out, layer)
out.alpha_composite(band, (-band.size[0] // 2 + 205, -band.size[1] // 2 + 205))
out = out.convert("RGB")
out.save("../attic/icon_halloween_1024.png")
out.resize((512, 512), Image.LANCZOS).save("../attic/icon_halloween_512.png")
print("ok")
