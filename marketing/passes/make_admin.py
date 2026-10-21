# The "Admin panel" pass icon (512x512): a dark control panel with his mask on the screen.
# python3 make_admin.py -> admin_panel.png
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
F = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../fonts/")
def font(n, s): return ImageFont.truetype(F + n, s)
im = Image.new("RGB", (512, 512), (10, 10, 14))
d = ImageDraw.Draw(im)
for r in range(360, 0, -4):
    k = r / 360
    c1, c2 = (10, 10, 14), (70, 52, 18)
    d.ellipse([256 - r, 220 - r, 256 + r, 220 + r], fill=tuple(int(c2[i] * (1 - k) + c1[i] * k) for i in range(3)))
# the panel
d.rounded_rectangle([86, 92, 426, 352], 22, fill=(18, 18, 22), outline=(255, 200, 120), width=6)
d.rounded_rectangle([108, 114, 404, 128 + 24], 8, fill=(255, 200, 120))
f = font("Outfit-Bold.ttf", 22)
d.text((122, 117), "ADMIN", font=f, fill=(20, 18, 14))
# rows of buttons
for i, (x, y) in enumerate([(108, 170), (262, 170), (108, 226), (262, 226), (108, 282), (262, 282)]):
    d.rounded_rectangle([x, y, x + 142, y + 44], 8, fill=(40, 40, 48))
    d.rounded_rectangle([x + 12, y + 16, x + 12 + 90 - (i % 3) * 18, y + 28], 4, fill=(200, 196, 188) if i != 3 else (255, 120, 110))
# a red dot: live
glow = Image.new("RGBA", (512, 512), (0, 0, 0, 0)); g = ImageDraw.Draw(glow)
g.ellipse([370, 118, 394, 142], fill=(255, 60, 50, 255))
im.paste(glow.filter(ImageFilter.GaussianBlur(5)), (0, 0), glow.filter(ImageFilter.GaussianBlur(5)))
d.ellipse([374, 122, 390, 138], fill=(255, 90, 80))
lf = font("Outfit-Bold.ttf", 62)
t = "ADMIN PANEL"
w = d.textlength(t, font=lf)
d.text(((512 - w) / 2 + 3, 405 + 3), t, font=lf, fill=(0, 0, 0))
d.text(((512 - w) / 2, 405), t, font=lf, fill=(255, 205, 120))
im.save(os.path.join(os.path.dirname(os.path.abspath(__file__)), "admin_panel.png"))
print("admin_panel.png")
