from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 1024
felt_deep = (5, 15, 10)
felt = (11, 29, 20)
gold = (212, 175, 55)
gold_hi = (246, 211, 103)
gold_deep = (143, 114, 32)
cream = (245, 240, 224)

img = Image.new("RGB", (SIZE, SIZE), felt)
draw = ImageDraw.Draw(img)

# felt vignette
for i in range(SIZE // 2, 0, -4):
    t = i / (SIZE / 2)
    c = tuple(int(felt_deep[k] + (felt[k] - felt_deep[k]) * (1 - t)) for k in range(3))
    draw.ellipse([SIZE/2 - i, SIZE/2 - i, SIZE/2 + i, SIZE/2 + i], fill=c)

cx, cy = SIZE / 2, SIZE / 2

def octagon(cx, cy, r, rot=math.pi / 8):
    return [(cx + r * math.cos(rot + i * math.pi / 4),
             cy + r * math.sin(rot + i * math.pi / 4)) for i in range(8)]

# drop shadow
sh = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
shd = ImageDraw.Draw(sh)
shd.polygon(octagon(cx, cy + 26, 402), fill=(0, 0, 0, 140))
img.paste(Image.alpha_composite(img.convert("RGBA"), sh).convert("RGB"), (0, 0))
draw = ImageDraw.Draw(img)

# gold plaque: layered octagons for a bevel effect
draw.polygon(octagon(cx, cy, 400), fill=gold_deep)
draw.polygon(octagon(cx, cy, 386), fill=gold)
# top-light gradient: overlay lighter gold on the upper half via clipped ellipse trick
grad = Image.new("L", (SIZE, SIZE), 0)
gd = ImageDraw.Draw(grad)
for y in range(SIZE):
    v = max(0, 150 - int(y * 0.35))
    gd.line([(0, y), (SIZE, y)], fill=v)
lighter = Image.new("RGB", (SIZE, SIZE), gold_hi)
mask = Image.new("L", (SIZE, SIZE), 0)
md = ImageDraw.Draw(mask)
md.polygon(octagon(cx, cy, 386), fill=255)
grad2 = Image.composite(grad, Image.new("L", (SIZE, SIZE), 0), mask)
img = Image.composite(lighter, img, grad2.point(lambda p: p * 0.9))
draw = ImageDraw.Draw(img)

# inner cream keyline octagons (plaque detailing)
def ring(r, width, color):
    pts = octagon(cx, cy, r)
    draw.line(pts + [pts[0]], fill=color, width=width, joint="curve")

ring(340, 8, cream)
ring(300, 4, (245, 240, 224))

# corner pips: small felt dots at each octagon vertex between the rings
for (px, py) in octagon(cx, cy, 320):
    draw.ellipse([px - 11, py - 11, px + 11, py + 11], fill=felt_deep)

# center monogram "A" in deep felt, serif
font = None
for path in [
    "/System/Library/Fonts/Supplemental/Georgia Bold.ttf",
    "/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf",
    "/System/Library/Fonts/NewYork.ttf",
]:
    try:
        font = ImageFont.truetype(path, 430)
        break
    except OSError:
        continue
if font is None:
    font = ImageFont.load_default(430)

bbox = draw.textbbox((0, 0), "A", font=font)
tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
draw.text((cx - tw / 2 - bbox[0], cy - th / 2 - bbox[1]), "A", font=font, fill=felt_deep)

img.save("AppIcon-octagon-1024.png")
print("wrote AppIcon-octagon-1024.png")
