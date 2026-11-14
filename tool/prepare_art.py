"""Prepares opaque art (planet surface textures, backgrounds) for the game.

Usage:
  python3 tool/prepare_art.py texture SRC assets/art/planet_tex_{id}.jpg
  python3 tool/prepare_art.py background SRC assets/art/bg_{id}.jpg

texture:    makes the image tile seamlessly left-to-right (the planet wraps
            it around a turning globe), then saves 1600x800 JPEG.
            AI "seamless" textures usually still show a seam; this blends a
            10% band at the right edge into the left edge so it disappears.
background: centre-crops to a square and saves 1080x1080 JPEG.

Opaque images are stored as JPEG to keep the app and browser build small.
(Transparent sprites use tool/clean_sprite.py and stay PNG.)
"""
import sys

from PIL import Image


def seam_diff(im):
    """Mean colour difference across the wrap seam (0 = invisible)."""
    w, h = im.size
    a = im.crop((w - 1, 0, w, h)).tobytes()
    b = im.crop((0, 0, 1, h)).tobytes()
    return sum(abs(x - y) for x, y in zip(a, b)) / len(a)


def make_seamless(im, band_ratio=0.10):
    """Blends the last `band` columns into the first ones.

    Output width is W - band: column x < band is a crossfade from
    I[W-band+x] (t=0) to I[x] (t=1), so the output's last column I[W-band-1]
    sits next to I[W-band] at the wrap, which is continuous in the source.
    """
    w, h = im.size
    band = int(w * band_ratio)
    out = Image.new('RGB', (w - band, h))
    out.paste(im.crop((band, 0, w - band, h)), (band, 0))
    for x in range(band):
        t = x / band
        left = im.crop((x, 0, x + 1, h))
        right = im.crop((w - band + x, 0, w - band + x + 1, h))
        out.paste(Image.blend(right, left, t), (x, 0))
    return out


def main():
    kind, src, dst = sys.argv[1:4]
    im = Image.open(src).convert('RGB')
    if kind == 'texture':
        before = seam_diff(im)
        im = make_seamless(im)
        im = im.resize((1600, 800), Image.LANCZOS)
        print(f'{dst}: seam {before:.1f} -> {seam_diff(im):.1f}')
    elif kind == 'background':
        w, h = im.size
        s = min(w, h)
        im = im.crop(((w - s) // 2, (h - s) // 2, (w + s) // 2, (h + s) // 2))
        im = im.resize((1080, 1080), Image.LANCZOS)
        print(f'{dst}: 1080x1080')
    else:
        raise SystemExit(f'unknown kind {kind}')
    im.save(dst, quality=85, optimize=True, progressive=True)


if __name__ == '__main__':
    main()
