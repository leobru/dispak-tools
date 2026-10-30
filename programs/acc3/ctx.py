#!/usr/bin/env python3
"""Show the original and the built overlay side by side around an address.

Usage: python3 programs/acc3/ctx.py PART taddr [maddr] [n]

PART is a part of ovtry.py (ov1, ov2); run ovtry.py
with --dis first. taddr is the original (T) address, maddr the built (M)
one (default taddr), both octal; n words (default 12) are listed from
each. Every `'k'(М10)` operand is followed by the value of its pool word.
"""
from pathlib import Path
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
import ovtry
from paths import TOOLS
from corpus import read_words

DIS = TOOLS/'disbesm6'


def seeds(image, base, pool):
    """Code seeds of image (codeseeds.py), cached beside it."""
    path = image.with_suffix('.ctxseeds')
    if not path.exists() or path.stat().st_mtime < image.stat().st_mtime:
        path.write_text(subprocess.run(
            [sys.executable, str(HERE/'codeseeds.py'), str(image), f'{base:o}',
             '4013', '4000', f'{pool:o}'], capture_output=True, text=True,
            check=True).stdout)
    return path


def listing(image, base, lo, n, pool, words, origin):
    text = subprocess.run([str(DIS), '-b', f'-a{base:o}', '-e4013',
                           '-n', str(seeds(image, base, pool)), str(image)],
                          capture_output=True, text=True).stdout.splitlines()
    out, keep = [], False
    for line in text:
        m = re.match(r'\s*([0-7]{4,5})[ :]', line)
        if m:
            a = int(m[1], 8)
            keep = lo <= a < lo + n
        if keep:
            k = re.search(r"\t(?:'(-?[0-7]+)'|(\d+))?\(М10\)", line)
            if k and (k[1] or k[2] is not None):
                off = int(k[1], 8) if k[1] else int(k[2] or 0)
                if 0 <= pool - origin + off < len(words):
                    line += f'   [{words[pool - origin + off]:016o}]'
            out.append(line)
    return out


def main():
    part = sys.argv[1]
    t = int(sys.argv[2], 8)
    m = int(sys.argv[3], 8) if len(sys.argv) > 3 else t
    n = int(sys.argv[4]) if len(sys.argv) > 4 else 12
    ref = ovtry.IMAGE[part]
    built = ovtry.WORK/f'{part}.img'
    rw, bw = read_words(ref), read_words(built)
    tp = ovtry.LAYOUT[part][1]
    mp = bw[0o4013 - 0o2000] >> 24 & 0o77777
    print('=== original')
    print('\n'.join(listing(ref, 0o4000, t, n, tp, rw, 0o4000)))
    print('=== built')
    print('\n'.join(listing(built, 0o2000, m, n, mp, bw, 0o2000)))


if __name__ == '__main__':
    main()
