"""Builds the subset Japanese font used by the web build.

The browser version cannot download fonts at runtime (the hosting sandbox
blocks it), so it bundles Noto Sans JP, subset to the characters the game
actually uses. Re-run after adding new UI text:

    python3 tool/make_web_font.py /path/to/NotoSansJP-400.ttf /path/to/NotoSansJP-700.ttf

Source fonts: https://fonts.google.com/noto/specimen/Noto+Sans+JP (SIL OFL 1.1).
Requires: pip install fonttools
"""
import pathlib, sys
from fontTools import subset

ROOT = pathlib.Path(__file__).resolve().parent.parent
chars = set()
for pattern in ('lib/**/*.dart', 'assets/config/*.json'):
    for p in ROOT.glob(pattern):
        chars.update(p.read_text(encoding='utf-8'))
# Safety margin: all printable ASCII, kana, CJK/fullwidth punctuation, symbols.
ranges = [(0x20, 0x7E), (0xA0, 0xFF), (0x2010, 0x2027), (0x2030, 0x203B),
          (0x2190, 0x2193), (0x2200, 0x221E), (0x25A0, 0x25CF), (0x2605, 0x2606),
          (0x3000, 0x303F), (0x3040, 0x30FF), (0xFF01, 0xFF60)]
for a, b in ranges:
    chars.update(chr(c) for c in range(a, b + 1))
chars = {c for c in chars if c.isprintable() or c == ' '}
text = ''.join(sorted(chars))

for src, out in zip(sys.argv[1:3], ['NotoSansJP-Subset-Regular.ttf', 'NotoSansJP-Subset-Bold.ttf']):
    opts = subset.Options()
    opts.layout_features = ['*']
    opts.name_IDs = ['*']
    opts.notdef_outline = True
    font = subset.load_font(src, opts)
    s = subset.Subsetter(opts)
    s.populate(text=text)
    s.subset(font)
    dest = ROOT / 'assets' / 'fonts' / out
    font.save(str(dest))
    print(f'{out}: {len(text)} chars, {dest.stat().st_size // 1024} KB')
