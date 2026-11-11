"""Cleans an AI-generated 'transparent' PNG for use as a game sprite.

- alpha < 16 -> 0 (removes faint background haze)
- alpha >= 192 -> 255 (bodies are opaque; AI cut-outs are often ~95% opaque)
- removes specks: connected components smaller than min_area (at full res)
- crops to content (base stays on the bottom edge) and scales to max height
Usage: clean_sprite.py SRC DST [max_h=512] [min_area=400]
"""
import sys
from collections import deque
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
max_h = int(sys.argv[3]) if len(sys.argv) > 3 else 512
min_area = int(sys.argv[4]) if len(sys.argv) > 4 else 400

im = Image.open(src).convert('RGBA')
r, g, b, a = im.split()
a = a.point(lambda v: 0 if v < 16 else (255 if v >= 192 else v))

# Connected components on a downscaled mask for speed.
s = 4
w, h = im.size
small = a.resize((w // s, h // s), Image.NEAREST)
sw, sh = small.size
sp = small.load()
seen = bytearray(sw * sh)
drop = []
for y in range(sh):
    for x in range(sw):
        if sp[x, y] == 0 or seen[y * sw + x]:
            continue
        comp = []
        q = deque([(x, y)]); seen[y * sw + x] = 1
        while q:
            cx, cy = q.popleft(); comp.append((cx, cy))
            for nx in (cx - 1, cx, cx + 1):
                for ny in (cy - 1, cy, cy + 1):
                    if 0 <= nx < sw and 0 <= ny < sh and sp[nx, ny] and not seen[ny * sw + nx]:
                        seen[ny * sw + nx] = 1; q.append((nx, ny))
        if len(comp) * s * s < min_area:
            drop.extend(comp)
ap = a.load()
for cx, cy in drop:
    for yy in range(cy * s, min(h, cy * s + s)):
        for xx in range(cx * s, min(w, cx * s + s)):
            ap[xx, yy] = 0

out = Image.merge('RGBA', (r, g, b, a))
bbox = a.getbbox()
out = out.crop(bbox)
if out.height > max_h:
    out = out.resize((round(out.width * max_h / out.height), max_h), Image.LANCZOS)
out.save(dst, optimize=True)
print(f'{dst.split("/")[-1]}: {out.size}, removed {len(drop) * s * s} px of specks')
