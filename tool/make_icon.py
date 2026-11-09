"""Generates the app icon (assets/icon/*.png). Run: python3 tool/make_icon.py"""
import math, random
from PIL import Image, ImageDraw, ImageFilter

S = 2048  # draw at 2x, downsample for anti-aliasing
NAVY_TOP, NAVY_BOTTOM = (16, 30, 72), (5, 10, 28)
PLANET = (79, 163, 224)
RING = (79, 195, 247)
ORE = (255, 200, 87)


def background():
    img = Image.new('RGB', (S, S))
    d = ImageDraw.Draw(img)
    for y in range(S):
        t = y / S
        d.line([(0, y), (S, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(NAVY_TOP, NAVY_BOTTOM)))
    rnd = random.Random(4)
    for _ in range(90):
        x, y, r = rnd.randrange(S), rnd.randrange(S), rnd.uniform(2, 6)
        a = rnd.randint(90, 230)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(a, a, min(255, a + 20)))
    return img


def foreground(scale=1.0):
    """Planet + ring on transparent canvas. scale<1 keeps it in the adaptive safe zone."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    cx, cy = S / 2, S / 2 + 40 * scale
    r = 560 * scale

    # glow
    glow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([cx - r * 1.25, cy - r * 1.25, cx + r * 1.25, cy + r * 1.25],
                                 fill=PLANET + (110,))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(90 * scale)))

    ring_box = [cx - r * 1.62, cy - r * 0.48, cx + r * 1.62, cy + r * 0.48]
    w = int(34 * scale)
    # back half of ring
    back = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(back).arc(ring_box, 180, 360, fill=RING + (150,), width=w)
    img.alpha_composite(back)

    # planet body with lighting (radial shading)
    body = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    px = body.load()
    lx, ly = cx - r * 0.38, cy - r * 0.42
    for y in range(int(cy - r), int(cy + r) + 1):
        for x in range(int(cx - r), int(cx + r) + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 > r * r:
                continue
            dist = math.hypot(x - lx, y - ly) / (r * 1.55)
            t = min(1.0, dist)
            if t < 0.35:
                k = t / 0.35
                c = [int(255 * (1 - k) * 0.55 + v * (0.45 + 0.55 * k)) for v in PLANET]
            else:
                k = (t - 0.35) / 0.65
                c = [int(v * (1 - 0.82 * k)) for v in PLANET]
            # surface bands
            band = math.sin((y - cy) / r * 7.5) * 0.06
            c = [max(0, min(255, int(v * (1 - band)))) for v in c]
            px[x, y] = tuple(c) + (255,)
    img.alpha_composite(body)

    # mining structures on top arc
    d = ImageDraw.Draw(img)
    for i, col in enumerate([(184, 164, 140), ORE, (128, 222, 234)]):
        ang = -math.pi / 2 + (i - 1) * 0.36
        bx, by = cx + math.cos(ang) * r, cy + math.sin(ang) * r
        h, hw = (150 if i == 1 else 110) * scale, 34 * scale
        rot = ang + math.pi / 2
        pts = [(-hw, 0), (hw, 0), (hw, -h), (-hw, -h)]
        pts = [(bx + px_ * math.cos(rot) - py * math.sin(rot), by + px_ * math.sin(rot) + py * math.cos(rot)) for px_, py in pts]
        d.polygon(pts, fill=col)
        tx = bx + math.sin(ang + math.pi / 2) * 0 + math.cos(ang) * (h + 30 * scale)
        ty = by + math.sin(ang) * (h + 30 * scale)
        d.ellipse([tx - 16 * scale, ty - 16 * scale, tx + 16 * scale, ty + 16 * scale], fill=(255, 255, 255))

    # front half of ring + drones
    front = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    fd = ImageDraw.Draw(front)
    fd.arc(ring_box, 0, 180, fill=RING + (255,), width=w)
    for a in (25, 85, 150):
        t = math.radians(a)
        x, y = cx + math.cos(t) * r * 1.62, cy + math.sin(t) * r * 0.48
        dr = 44 * scale
        fd.ellipse([x - dr, y - dr, x + dr, y + dr], fill=(178, 255, 89))
    img.alpha_composite(front)
    return img


def save(img, path, size):
    img.resize((size, size), Image.LANCZOS).save(path)


full = background().convert('RGBA')
full.alpha_composite(foreground(1.0))
save(full.convert('RGB'), 'assets/icon/icon.png', 1024)          # iOS / legacy Android
save(foreground(0.72), 'assets/icon/icon_foreground.png', 1024)  # Android adaptive
print('ok')


def status_icon(px):
    """White-on-transparent planet+ring silhouette for the Android status bar."""
    big = px * 8
    im = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c, r = big / 2, big * 0.27
    d.ellipse([c - r, c - r, c + r, c + r], fill=(255, 255, 255, 255))
    w = max(2, big // 14)
    d.ellipse([c - r * 1.75, c - r * 0.55, c + r * 1.75, c + r * 0.55], outline=(255, 255, 255, 255), width=w)
    # cut the ring behind the planet's top half so the shape reads as a ringed planet
    d.chord([c - r * 1.05, c - r * 1.05, c + r * 1.05, c + r * 1.05], 180, 360, fill=(255, 255, 255, 255))
    return im.resize((px, px), Image.LANCZOS)


import os
for name, px in [('mdpi', 24), ('hdpi', 36), ('xhdpi', 48), ('xxhdpi', 72), ('xxxhdpi', 96)]:
    d = f'android/app/src/main/res/drawable-{name}'
    os.makedirs(d, exist_ok=True)
    status_icon(px).save(f'{d}/ic_stat_orbit.png')
print('status icons ok')
