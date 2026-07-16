from PIL import Image, ImageDraw
import math

SIZE = 1024
felt_deep = (5, 15, 10)
felt = (11, 29, 20)
gold = (212, 175, 55)
gold_bright = (246, 211, 103)
cream = (245, 240, 224)

img = Image.new("RGB", (SIZE, SIZE), felt)
draw = ImageDraw.Draw(img)

# radial-ish felt vignette via concentric rects
for i in range(SIZE // 2, 0, -4):
    t = i / (SIZE / 2)
    r = int(felt_deep[0] + (felt[0] - felt_deep[0]) * (1 - t))
    g = int(felt_deep[1] + (felt[1] - felt_deep[1]) * (1 - t))
    b = int(felt_deep[2] + (felt[2] - felt_deep[2]) * (1 - t))
    draw.ellipse([SIZE / 2 - i, SIZE / 2 - i, SIZE / 2 + i, SIZE / 2 + i], fill=(r, g, b))

cx, cy = SIZE / 2, SIZE / 2
chip_r = 360

# chip base
draw.ellipse([cx - chip_r, cy - chip_r, cx + chip_r, cy + chip_r], fill=gold)

# dashed rim
dash_count = 16
rim_r = chip_r - 34
rim_w = 46
for i in range(dash_count):
    a0 = (360 / dash_count) * i
    a1 = a0 + (360 / dash_count) * 0.55
    draw.arc(
        [cx - rim_r, cy - rim_r, cx + rim_r, cy + rim_r],
        start=a0, end=a1, fill=cream, width=rim_w
    )

# inner ring
inner_r = chip_r - 120
draw.ellipse(
    [cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r],
    outline=cream, width=14
)

# center: bold alarm-clock glyph -- reads clearly at thumbnail size, unlike
# a literal bed illustration which turned out ambiguous at small sizes.
face_r = 155
# bells
bell_r = 46
for sign in (-1, 1):
    bx = cx + sign * 150
    by = cy - 190
    draw.ellipse([bx - bell_r, by - bell_r, bx + bell_r, by + bell_r], fill=felt_deep)
# feet
foot_r = 26
for sign in (-1, 1):
    fx = cx + sign * 118
    fy = cy + 168
    draw.ellipse([fx - foot_r, fy - foot_r, fx + foot_r, fy + foot_r], fill=felt_deep)
# clock face
draw.ellipse([cx - face_r, cy - face_r, cx + face_r, cy + face_r], fill=felt_deep)
draw.ellipse([cx - face_r + 16, cy - face_r + 16, cx + face_r - 16, cy + face_r - 16], fill=gold)
# clock hands (pointing to a "past due" 10:10-ish stance)
draw.line([cx, cy, cx, cy - 95], fill=felt_deep, width=20)
draw.line([cx, cy, cx + 70, cy + 30], fill=felt_deep, width=20)
draw.ellipse([cx - 14, cy - 14, cx + 14, cy + 14], fill=felt_deep)
# top strike/hammer between the bells
draw.rounded_rectangle([cx - 14, cy - 250, cx + 14, cy - 205], radius=8, fill=felt_deep)

img.save("AppIcon-1024.png")
print("wrote AppIcon-1024.png", img.size)
