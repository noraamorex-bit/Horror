# v108 pass icons (512x512): 2x Coins, Night Vision, Silent Steps. python3 make_v108.py
import os, math, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter
HERE = os.path.dirname(os.path.abspath(__file__))
F = os.path.join(HERE, "../fonts/")
def font(n, s): return ImageFont.truetype(F + n, s)

def base(c1, c2):
    im = Image.new("RGB", (512, 512), c1)
    d = ImageDraw.Draw(im)
    for r in range(380, 0, -4):
        k = r / 380
        d.ellipse([256 - r, 226 - r, 256 + r, 226 + r], fill=tuple(int(c2[i] * (1 - k) + c1[i] * k) for i in range(3)))
    return im

def label(im, text, size=66, col=(255, 255, 255)):
    d = ImageDraw.Draw(im)
    f = font("Outfit-Bold.ttf", size)
    w = d.textlength(text, font=f)
    d.text(((512 - w) / 2 + 3, 422 + 3), text, font=f, fill=(0, 0, 0))
    d.text(((512 - w) / 2, 422), text, font=f, fill=col)

def glow(im, draw_fn, blur=10):
    layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(layer))
    g = layer.filter(ImageFilter.GaussianBlur(blur))
    im.paste(g, (0, 0), g)
    im.paste(layer, (0, 0), layer)

# --- 2x COINS: a stack of gold coins and a big "2x"
im = base((14, 10, 2), (120, 88, 10))
d = ImageDraw.Draw(im)
def coin(cx, cy, r):
    d.ellipse([cx - r, cy - r * 0.42 + 10, cx + r, cy + r * 0.42 + 10], fill=(150, 98, 8))
    d.ellipse([cx - r, cy - r * 0.42, cx + r, cy + r * 0.42], fill=(250, 200, 40), outline=(190, 130, 10), width=5)
    d.ellipse([cx - r * 0.7, cy - r * 0.29, cx + r * 0.7, cy + r * 0.29], outline=(200, 140, 15), width=4)
for i in range(5):
    coin(150, 330 - i * 26, 92)
for i in range(3):
    coin(262, 345 - i * 26, 80)
f = font("Outfit-Bold.ttf", 210)
def two(dd):
    dd.text((268, 52), "2x", font=f, fill=(255, 236, 140, 255), stroke_width=10, stroke_fill=(60, 36, 0, 255))
glow(im, two, 14)
label(im, "2X COINS", 70, (255, 232, 140))
im.save(os.path.join(HERE, "double_coins.png"))

# --- NIGHT VISION: green goggles, the dark house in green through them
im = base((2, 10, 4), (16, 70, 30))
d = ImageDraw.Draw(im)
d.rounded_rectangle([96, 150, 416, 300], radius=50, fill=(22, 26, 24))
d.rectangle([232, 108, 280, 160], fill=(30, 34, 32))
for cx in (176, 336):
    d.ellipse([cx - 66, 158, cx + 66, 290], fill=(12, 14, 13))
def lenses(dd):
    for cx in (176, 336):
        dd.ellipse([cx - 50, 174, cx + 50, 274], fill=(80, 255, 110, 255))
        dd.ellipse([cx - 22, 196, cx + 8, 226], fill=(220, 255, 220, 255))
glow(im, lenses, 18)
d = ImageDraw.Draw(im)
d.line([(96, 225), (40, 210)], fill=(30, 34, 32), width=16)
d.line([(416, 225), (472, 210)], fill=(30, 34, 32), width=16)
label(im, "NIGHT VISION", 64, (150, 255, 160))
im.save(os.path.join(HERE, "night_vision.png"))

# --- SILENT STEPS: soft footprints fading, a "shh" finger
im = base((6, 6, 12), (40, 44, 80))
d = ImageDraw.Draw(im)
def foot(cx, cy, ang, a):
    layer = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    dd = ImageDraw.Draw(layer)
    col = (220, 226, 255, a)
    dd.ellipse([cx - 26, cy - 46, cx + 26, cy + 30], fill=col)
    dd.ellipse([cx - 20, cy + 34, cx + 20, cy + 66], fill=col)
    for k, (dx, r) in enumerate([(-18, 9), (-4, 8), (9, 7), (20, 6)]):
        dd.ellipse([cx + dx - r, cy - 70 + k * 3 - r, cx + dx + r, cy - 70 + k * 3 + r], fill=col)
    layer = layer.rotate(ang, center=(cx, cy))
    im.paste(layer, (0, 0), layer)
for i, (x, y, a) in enumerate([(150, 360, 70), (230, 280, 110), (300, 200, 160), (380, 120, 230)]):
    foot(x + (16 if i % 2 else -16), y, -32, a)
label(im, "SILENT STEPS", 62, (210, 220, 255))
im.save(os.path.join(HERE, "silent_steps.png"))
print("ok")
