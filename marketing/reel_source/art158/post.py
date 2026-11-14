# v158 store art: lift the film2 renders (raw/*.png) a little and set a plain bold title. No bloom, no paint, no serif: the
# old cover read as AI-made to players. python3 post.py
#   -> ../../attic/thumbnail_v158_1.png, thumbnail_v158_2.png (1920x1080), icon_v158_512.png, icon_v158_1024.png
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "attic")
FONT = os.path.join(HERE, "..", "..", "fonts", "Outfit-Bold.ttf")

def lift(img, gain=1.35, gamma=0.85):
    a = np.asarray(img.convert("RGB")).astype(np.float32) / 255.0
    a = np.clip(a * gain, 0, 1) ** gamma
    return Image.fromarray((a * 255).astype(np.uint8))

def title(img, text, size, y, red=None):
    d = ImageDraw.Draw(img)
    f = ImageFont.truetype(FONT, size)
    w = d.textlength(text, font=f)
    x = (img.width - w) / 2
    st = max(4, size // 12)
    if red:
        # (the last word in red)
        head, tail = text[: -len(red)], red
        d.text((x, y), head, font=f, fill=(255, 255, 255), stroke_width=st, stroke_fill=(0, 0, 0))
        d.text((x + d.textlength(head, font=f), y), tail, font=f, fill=(228, 32, 32), stroke_width=st, stroke_fill=(0, 0, 0))
    else:
        d.text((x, y), text, font=f, fill=(255, 255, 255), stroke_width=st, stroke_fill=(0, 0, 0))

t1 = lift(Image.open(os.path.join(HERE, "raw", "thumb.png")))
title(t1, "someone lives in our attic.", 118, 48, red="attic.")
t1.save(os.path.join(OUT, "thumbnail_v158_1.png"))
t2 = lift(Image.open(os.path.join(HERE, "raw", "thumb2.png")), 1.5)
title(t2, "1-4 PLAYERS · SURVIVE THE NIGHT", 92, 900)
t2.save(os.path.join(OUT, "thumbnail_v158_2.png"))
ic = lift(Image.open(os.path.join(HERE, "raw", "icon.png")), 1.3)
ic.save(os.path.join(OUT, "icon_v158_1024.png"))
ic.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, "icon_v158_512.png"))
print("ok")
