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

# --- rocket launcher: an olive tube on the shoulder, a rocket leaving it in a fireball
def launcher(im, flame=True):
    d = ImageDraw.Draw(im)
    a = -0.42
    c, s_ = math.cos(a), math.sin(a)
    cx, cy = 206, 300  # the tube's centre
    def P(u, v):  # u along the tube, v across it
        return (cx + u * c - v * s_, cy + u * s_ + v * c)
    def poly(pts, col):
        d.polygon([P(u, v) for u, v in pts], fill=col)
    glow = Image.new("RGBA", (512, 512), (0, 0, 0, 0)); g = ImageDraw.Draw(glow)
    if flame:
        x, y = P(250, 0)
        g.ellipse([x - 70, y - 70, x + 70, y + 70], fill=(255, 150, 30, 230))
        g.ellipse([x - 40, y - 40, x + 40, y + 40], fill=(255, 235, 140, 255))
    x, y = P(-215, 0)
    g.ellipse([x - 70, y - 40, x + 50, y + 40], fill=(200, 200, 200, 120))
    blur = glow.filter(ImageFilter.GaussianBlur(14))
    im.paste(blur, (0, 0), blur)
    poly([(-185, -32), (185, -32), (185, 32), (-185, 32)], (78, 92, 52))
    poly([(-185, -32), (185, -32), (185, -16), (-185, -16)], (110, 128, 74))
    poly([(185, -40), (215, -40), (215, 40), (185, 40)], (40, 44, 30))
    poly([(-215, -38), (-185, -38), (-185, 38), (-215, 38)], (40, 44, 30))
    poly([(-55, 32), (-23, 32), (-33, 112), (-65, 112)], (30, 30, 30))
    poly([(35, 32), (61, 32), (55, 90), (29, 90)], (30, 30, 30))
    poly([(-25, -48), (45, -48), (45, -32), (-25, -32)], (30, 30, 30))
    if flame:
        # the rocket, just out of the tube
        poly([(232, -11), (288, -11), (312, 0), (288, 11), (232, 11)], (225, 225, 230))
        poly([(288, -11), (312, 0), (288, 11)], (210, 40, 30))
        poly([(232, -11), (244, -11), (236, -22), (226, -22)], (180, 180, 185))
        poly([(232, 11), (244, 11), (236, 22), (226, 22)], (180, 180, 185))
im = base((24, 6, 0), (150, 60, 10))
launcher(im)
label(im, "ROCKET LAUNCHER", 56, (255, 230, 200))
im.save("rocket.png")
im = base((24, 6, 0), (150, 60, 10))
launcher(im)
label(im, "1 ROCKET · TONIGHT", 52, (255, 230, 200))
im.save("rocket_tonight.png")
print("ok")
