# The Starter Pack product icon (512x512): a gift box with the bow, gold on dark green. python3 make_starter.py
from make_icons import base, label  # noqa (make_icons draws its own icons on import too)
from PIL import ImageDraw
im = base((4, 14, 8), (20, 90, 50))
d = ImageDraw.Draw(im)
d.rectangle([126, 200, 386, 380], fill=(200, 40, 40))
d.rectangle([110, 160, 402, 210], fill=(225, 55, 50))
d.rectangle([236, 160, 276, 380], fill=(255, 210, 90))
d.rectangle([110, 178, 402, 194], fill=(255, 210, 90))
d.ellipse([170, 96, 254, 168], outline=(255, 210, 90), width=16)
d.ellipse([258, 96, 342, 168], outline=(255, 210, 90), width=16)
d.ellipse([240, 146, 272, 176], fill=(255, 224, 120))
label(im, "STARTER PACK", 60, (255, 225, 140))
im.save("starter_pack.png")
