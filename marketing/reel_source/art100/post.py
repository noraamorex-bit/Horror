# v100 store art: grade the film2 renders (raw/*.png) and set the title. python3 post.py
#   -> ../../attic/icon_v100_1024.png, icon_v100_512.png, thumbnail_v100_1.png, thumbnail_v100_2.png
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "attic")
FONTS = os.path.join(HERE, "..", "..", "fonts")

def grade(img, lamp=None, vig=0.55):
    a = np.asarray(img.convert("RGB")).astype(np.float32) / 255.0
    h, w = a.shape[:2]
    if lamp:
        # (the hall's ceiling lamp: snuffed out, it pulls the eye away from his face)
        yy, xx = np.mgrid[0:h, 0:w]
        d = np.sqrt((xx - lamp[0]) ** 2 + (yy - lamp[1]) ** 2) / lamp[2]
        a *= np.clip(0.06 + d ** 2, 0, 1)[..., None]
    # bloom: what's bright (the mask, the beam) glows a little
    bright = np.clip((a - 0.62) / 0.38, 0, 1)
    glow = np.asarray(Image.fromarray((bright * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(w / 90))).astype(np.float32) / 255.0
    a = a + glow * 0.45
    # contrast (an S-curve), cold shadows, the reds kept warm
    a = np.clip(a, 0, 1)
    a = a * a * (3 - 2 * a) * 0.6 + a * 0.4
    lum = a.mean(axis=2, keepdims=True)
    shadow = np.clip(1 - lum * 2.2, 0, 1)
    a = a + shadow * np.array([-0.012, 0.0, 0.03])
    # vignette
    yy, xx = np.mgrid[0:h, 0:w]
    r = np.sqrt(((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2)
    a *= (1 - vig * np.clip(r - 0.45, 0, 1) ** 1.5)[..., None]
    # grain
    rng = np.random.default_rng(7)
    a += rng.normal(0, 0.018, a.shape[:2])[..., None]
    out = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))
    return out.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2))

def title(img, x, y, size, align="left", lines=("someone lives", "in our attic.")):
    d = ImageDraw.Draw(img)
    f = ImageFont.truetype(os.path.join(FONTS, "Lora-Bold.ttf"), size)
    tag = ImageFont.truetype(os.path.join(FONTS, "WorkSans-Bold.ttf"), int(size * 0.3))
    # (a soft dark backing so it reads on anything)
    shadow = Image.new("L", img.size, 0)
    sd = ImageDraw.Draw(shadow)
    yy = y
    for ln in lines:
        wdt = d.textlength(ln, font=f)
        xx = x - wdt if align == "right" else x
        sd.text((xx, yy), ln, font=f, fill=255)
        yy += int(size * 1.08)
    shadow = shadow.filter(ImageFilter.GaussianBlur(size / 6))
    img.paste(Image.new("RGB", img.size, (0, 0, 0)), (0, 0), shadow.point(lambda v: int(v * 0.85)))
    yy = y
    for i, ln in enumerate(lines):
        wdt = d.textlength(ln, font=f)
        xx = x - wdt if align == "right" else x
        if "attic." in ln:
            pre = ln[: ln.index("attic.")]
            d.text((xx, yy), pre, font=f, fill=(242, 238, 230))
            d.text((xx + d.textlength(pre, font=f), yy), "attic.", font=f, fill=(214, 30, 36))
        else:
            d.text((xx, yy), ln, font=f, fill=(242, 238, 230))
        yy += int(size * 1.08)
    t = "[ HORROR ]   1-4 PLAYERS"
    tw = d.textlength(t, font=tag)
    d.text((x - tw if align == "right" else x + 4, yy + size * 0.12), t, font=tag, fill=(170, 170, 176))
    return img

os.makedirs(OUT, exist_ok=True)
icon = grade(Image.open(os.path.join(HERE, "raw", "icon.png")), lamp=(588, 30, 210), vig=0.6)
icon.save(os.path.join(OUT, "icon_v100_1024.png"))
icon.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, "icon_v100_512.png"))
t1 = grade(Image.open(os.path.join(HERE, "raw", "thumb.png")), lamp=(585, 25, 260), vig=0.5)
title(t1, 1840, 400, 132, align="right").save(os.path.join(OUT, "thumbnail_v100_1.png"))
t2 = grade(Image.open(os.path.join(HERE, "raw", "thumb2.png")), lamp=(1025, 210, 150), vig=0.32)
title(t2, 70, 700, 104).save(os.path.join(OUT, "thumbnail_v100_2.png"))
print("ok")
