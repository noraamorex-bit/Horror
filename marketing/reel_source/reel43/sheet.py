# python3 sheet.py rawdir out.png [cols]: a contact sheet of every frame in rawdir, labelled with its number
import os, sys
from PIL import Image, ImageDraw
src, out = sys.argv[1], sys.argv[2]
cols = int(sys.argv[3]) if len(sys.argv) > 3 else 9
names = sorted(n for n in os.listdir(src) if n.endswith(".png"))
ims = [Image.open(os.path.join(src, n)).convert("RGB") for n in names]
w, h = 240, int(240 * ims[0].height / ims[0].width) if ims else 426
rows = (len(ims) + cols - 1) // cols
sheet = Image.new("RGB", (cols * w, rows * (h + 18)), (20, 20, 24))
d = ImageDraw.Draw(sheet)
for k, (n, im) in enumerate(zip(names, ims)):
    x, y = (k % cols) * w, (k // cols) * (h + 18)
    sheet.paste(im.resize((w, h)), (x, y + 18))
    d.text((x + 4, y + 3), n[:-4], fill=(255, 220, 120))
sheet.save(out)
print("sheet", len(ims), "frames ->", out)
