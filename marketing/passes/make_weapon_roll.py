# v161 "Weapon Roll" developer product icon (512x512): four weapons fanned out, one per tier colour (bat grey, katana blue,
# scythe purple, the slap glove gold), a die. python3 make_weapon_roll.py -> weapon_roll.png
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
F = "/mnt/skills/examples/canvas-design/canvas-fonts/"
def font(n, s): return ImageFont.truetype(F + n, s)
im = Image.new("RGB", (512, 512), (10, 8, 14))
d = ImageDraw.Draw(im)
for r in range(380, 0, -4):
    k = r / 380
    col = tuple(int(c2 * (1 - k) + c1 * k) for c1, c2 in zip((10, 8, 14), (90, 60, 20)))
    d.ellipse([256 - r, 220 - r, 256 + r, 220 + r], fill=col)
glow = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
gd.ellipse([120, 70, 392, 342], fill=(255, 200, 80, 90))
im.paste(Image.alpha_composite(im.convert("RGBA"), glow.filter(ImageFilter.GaussianBlur(40))).convert("RGB"))
d = ImageDraw.Draw(im)
CX, CY = 256, 330
def rot(pts, a, c=(CX, CY)):
    ca, sa = math.cos(a), math.sin(a)
    return [(c[0] + x * ca - y * sa, c[1] + x * sa + y * ca) for x, y in pts]
def blade(a, length, width, col, hilt=(40, 30, 24), curve=0.0, tip=1.0):
    # a long thing pointing up from the fan's centre, rotated by a
    h = [(-width * 0.35, 0), (width * 0.35, 0), (width * 0.35, -length * 0.32), (-width * 0.35, -length * 0.32)]
    b = [(-width / 2, -length * 0.32), (width / 2, -length * 0.32), (width / 2 + curve, -length * (1 - 0.08 * tip)),
         (curve * 0.6, -length), (-width / 2 + curve * 0.3, -length * 0.92)]
    d.polygon(rot(h, a), fill=hilt)
    d.polygon(rot(b, a), fill=col, outline=(0, 0, 0))
# the bat (grey), the katana (blue), the scythe (purple), the glove (gold)
blade(-0.75, 250, 34, (170, 170, 176), hilt=(70, 50, 34), curve=6)
blade(-0.25, 280, 22, (90, 150, 255), hilt=(30, 30, 40), curve=14)
# scythe: a pole and a curved blade at the top
pole = [(-7, 0), (7, 0), (7, -270), (-7, -270)]
d.polygon(rot(pole, 0.25), fill=(60, 40, 30))
sc = [(0, -270), (-10, -250), (-120, -230), (-170, -200), (-100, -260), (-20, -290)]
d.polygon(rot(sc, 0.25), fill=(176, 90, 255), outline=(0, 0, 0))
# glove: a big open hand
gx = rot([(0, -205)], 0.8)[0]
d.rounded_rectangle([gx[0] - 48, gx[1] - 40, gx[0] + 48, gx[1] + 50], 28, fill=(255, 196, 40), outline=(0, 0, 0), width=3)
for i, (fx, fl) in enumerate([(-36, 46), (-12, 58), (12, 56), (36, 44)]):
    d.rounded_rectangle([gx[0] + fx - 10, gx[1] - 40 - fl, gx[0] + fx + 10, gx[1] - 30], 10, fill=(255, 196, 40), outline=(0, 0, 0), width=3)
d.rounded_rectangle([gx[0] - 76, gx[1] - 6, gx[0] - 40, gx[1] + 22], 12, fill=(255, 196, 40), outline=(0, 0, 0), width=3)
# the die
dx, dy = 256, 360
d.rounded_rectangle([dx - 46, dy - 46, dx + 46, dy + 46], 16, fill=(245, 242, 236), outline=(0, 0, 0), width=4)
for px, py in [(-22, -22), (22, 22), (0, 0), (22, -22), (-22, 22)]:
    d.ellipse([dx + px - 8, dy + py - 8, dx + px + 8, dy + py + 8], fill=(200, 30, 30))
f = font("BigShoulders-Bold.ttf", 70)
t = "WEAPON ROLL"
w = d.textlength(t, font=f)
d.text(((512 - w) / 2 + 3, 418 + 3), t, font=f, fill=(0, 0, 0))
d.text(((512 - w) / 2, 418), t, font=f, fill=(255, 226, 150))
im.save("weapon_roll.png")
print("ok")
