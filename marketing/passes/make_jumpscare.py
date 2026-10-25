# The JUMPSCARE EVERYONE product icon (512x512, v115): his mask lunging out of the dark (a film2 still,
# jumpscare_src.png: the v114 creature, mouth open), vignette, a red glow, the title. python3 make_jumpscare.py
from PIL import Image, ImageDraw, ImageFilter
from make_icons import label  # noqa
src = Image.open("jumpscare_src.png").convert("RGB")
w, h = src.size
im = src.crop((int(w * 0.06), int(h * 0.12), int(w * 0.94), int(h * 1.0))).resize((512, 512), Image.LANCZOS)
# darken the room behind him, keep the mask: a radial vignette
v = Image.new("L", (512, 512), 0)
ImageDraw.Draw(v).ellipse([40, 10, 472, 470], fill=255)
v = v.filter(ImageFilter.GaussianBlur(70))
dark = Image.new("RGB", (512, 512), (6, 4, 6))
im = Image.composite(im, dark, v)
# a red glow at the edges
red = Image.new("RGB", (512, 512), (150, 10, 14))
ring = Image.eval(v, lambda x: int((255 - x) * 0.55))
im = Image.composite(red, im, ring)
label(im, "JUMPSCARE", 62, (255, 236, 230))
im.save("jumpscare_all.png")
print("jumpscare_all.png")
