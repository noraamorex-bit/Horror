# Game pass / product icons (512x512): the taser, "become him", VIP. python3 make_icons.py
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math, random
F = "/mnt/skills/examples/canvas-design/canvas-fonts/"
def font(n, s): return ImageFont.truetype(F + n, s)
def base(c1, c2):
    im = Image.new("RGB", (512, 512), c1)
    d = ImageDraw.Draw(im)
    for r in range(360, 0, -4):
        k = r / 360
        col = tuple(int(c2[i] * (1 - k) + c1[i] * k) for i in range(3))
        d.ellipse([256 - r, 236 - r, 256 + r, 236 + r], fill=col)
    return im
def label(im, text, size=64, col=(255, 255, 255)):
    d = ImageDraw.Draw(im)
    f = font("BigShoulders-Bold.ttf", size)
    w = d.textlength(text, font=f)
    d.text(((512 - w) / 2 + 3, 430 + 3), text, font=f, fill=(0, 0, 0))
    d.text(((512 - w) / 2, 430), text, font=f, fill=col)

# --- taser: a yellow-and-black taser, an electric arc from the prongs
im = base((8, 10, 18), (30, 60, 120))
d = ImageDraw.Draw(im)
d.polygon([(110, 200), (380, 200), (400, 215), (400, 265), (380, 280), (250, 280), (225, 380), (160, 380), (175, 280), (110, 280)], fill=(25, 25, 28))
d.polygon([(250, 205), (378, 205), (395, 218), (395, 262), (378, 275), (250, 275)], fill=(250, 200, 30))
d.rectangle([118, 212, 240, 268], fill=(40, 40, 46))
d.rectangle([168, 300, 214, 370], fill=(45, 45, 50))
d.rectangle([150, 280, 190, 300], fill=(25, 25, 28))
for y in (222, 258):
    d.rectangle([400, y - 4, 418, y + 4], fill=(190, 190, 200))
random.seed(4)
glow = Image.new("RGBA", (512, 512), (0, 0, 0, 0)); g = ImageDraw.Draw(glow)
for k in range(3):
    pts = [(420, 240)]
    x, y = 420, 240
    while x < 505:
        x += random.randint(10, 22); y += random.randint(-28, 28)
        pts.append((x, y))
    g.line(pts, fill=(120, 200, 255, 255), width=10 - k * 3)
im.paste(glow.filter(ImageFilter.GaussianBlur(6)), (0, 0), glow.filter(ImageFilter.GaussianBlur(6)))
d.line([(420, 240), (440, 225), (455, 252), (472, 230), (490, 248), (510, 236)], fill=(230, 245, 255), width=4)
label(im, "TASER")
im.save("taser.png")

# --- become him: his white mask on blood red
im = base((20, 0, 0), (140, 10, 12))
d = ImageDraw.Draw(im)
d.ellipse([146, 70, 366, 360], fill=(236, 232, 224))
d.ellipse([186, 150, 236, 240], fill=(10, 10, 10))
d.ellipse([276, 150, 326, 240], fill=(10, 10, 10))
d.ellipse([232, 258, 280, 336], fill=(10, 10, 10))
for x in (196, 300):
    d.line([(x, 250), (x - 6, 300)], fill=(40, 40, 40), width=5)
label(im, "BECOME HIM", 60, (255, 230, 230))
im.save("become_him.png")

# --- VIP
im = base((10, 8, 2), (90, 70, 10))
d = ImageDraw.Draw(im)
f = font("BigShoulders-Bold.ttf", 200)
w = d.textlength("VIP", font=f)
d.text(((512 - w) / 2 + 5, 125 + 5), "VIP", font=f, fill=(0, 0, 0))
d.text(((512 - w) / 2, 125), "VIP", font=f, fill=(255, 205, 70))
d.polygon([(256, 50), (270, 90), (312, 90), (278, 114), (291, 154), (256, 130), (221, 154), (234, 114), (200, 90), (242, 90)], fill=(255, 225, 120))
label(im, "ALL PERKS", 60, (255, 225, 140))
im.save("vip.png")
print("ok")
