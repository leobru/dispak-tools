#!/usr/bin/env python3
"""Find the procedure of overlay 1 most like each procedure of overlay 2.

Usage: python3 programs/acc3/procmatch.py [min-ratio]

Splits the user code of both overlays into procedures (skeleton.py) and
compares each pair by the sequence of their instructions without the
address fields (register and opcode only), with difflib. Prints, for each
procedure of overlay 2, its entry, level and length, the best procedure of
overlay 1 with its length and the similarity ratio (only those at or above
min-ratio, default 0.6), and the name ov1.pas gives it, if any. Same code
in both overlays means a shared source text, which ov1.pas then gives as a
draft.
"""
from difflib import SequenceMatcher
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
import paths
from corpus import read_words

BUILD = paths.BUILD/'acc3'
PARTS = {'ov1': (0o4014, 0o17724), 'ov2': (0o4014, 0o31341)}


def opcodes(words, lo, hi):
    out = []
    for a in range(lo, hi):
        w = words[a - 0o4000]
        for h in (w >> 24, w & 0o77777777):
            out.append(h >> 15 if h & (1 << 19) else h >> 12)
    return out


def procs(part):
    lo, hi = PARTS[part]
    text = subprocess.run([sys.executable, str(HERE/'skeleton.py'),
                           str(BUILD/f'{part}.bin'), '4000', f'{lo:o}', f'{hi:o}'],
                          capture_output=True, text=True, check=True).stdout
    rows = [l.split() for l in text.splitlines()]
    starts = [int(r[0], 8) for r in rows] + [hi]
    words = read_words(BUILD/f'{part}.bin')
    return [(starts[k], rows[k][1], starts[k+1] - starts[k],
             opcodes(words, starts[k], starts[k+1])) for k in range(len(rows))]


def main():
    limit = float(sys.argv[1]) if len(sys.argv) > 1 else 0.6
    one, two = procs('ov1'), procs('ov2')
    src = (HERE/'ov1.pas').read_text()
    for a, level, n, ops in two:
        best = (0, None)
        for b, _, m, ops1 in one:
            if not 0.5 <= m / n <= 2:
                continue
            sm = SequenceMatcher(None, ops, ops1, autojunk=False)
            if sm.real_quick_ratio() < best[0] or sm.quick_ratio() < best[0]:
                continue
            r = sm.ratio()
            if r > best[0]:
                best = (r, (b, m))
        if best[1] and best[0] >= limit:
            b, m = best[1]
            name = f'p{b:05o}' if f'p{b:05o}' in src else ''
            print(f'{a:05o} {level} {n:4o}  {b:05o} {m:4o}  {best[0]:.2f} {name}')
        else:
            print(f'{a:05o} {level} {n:4o}  -')


if __name__ == '__main__':
    main()
