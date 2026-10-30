#!/usr/bin/env python3
"""Map the runtime entries that overlay 2 calls to the same code in overlay 1.

Usage: python3 programs/acc3/rtmap.py [window]
       python3 programs/acc3/rtmap.py --names

The runtime areas of the two overlays hold relocated copies of the same
modules. For every target of a call from the user code of overlay 2 (as
calls.py finds them), looks for a place in overlay 1's runtime area whose
next `window` words (default 6) are the same, ignoring the 15-bit address
of long-format instructions; when that is ambiguous (tables of jumps), the
words before the entry are compared too. Prints `ov2-entry ov1-entry kind
calls`, with `-` when there is no unique match, and the declaration ov1.pas
gives the ov1 entry, so that it can be reused.
With --names it prints instead names.txt lines for overlay 2: the ov1 names
of names.txt moved to the matching addresses of overlay 2's runtime.
"""
from pathlib import Path
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
import paths
from corpus import read_words

BUILD = paths.BUILD/'acc3'
RT1 = (0o22557, 0o32000)


def mask(word):
    out = 0
    for half in (word >> 24, word & 0o77777777):
        if half & (1 << 19):
            half &= ~0o77777
        out = out << 24 | half
    return out


def find(src, dst, x, lo, hi, window=6):
    """The unique y in [lo, hi) where dst has the words of src at x."""
    for before in range(0, 16):
        key = src[x - 0o4000 - before:x - 0o4000 + window]
        hits = [y for y in range(lo, hi)
                if dst[y - 0o4000 - before:y - 0o4000 + window] == key]
        if len(hits) <= 1:
            break
    return hits


def main():
    window = int(sys.argv[1]) if sys.argv[1:2] not in ([], ['--names']) else 6
    w1 = [mask(w) for w in read_words(BUILD/'ov1.bin')]
    w2 = [mask(w) for w in read_words(BUILD/'ov2.bin')]
    if '--names' in sys.argv:
        for line in (HERE/'names.txt').read_text().splitlines():
            f = line.split()
            if len(f) == 3 and f[0] == 'ov1' and int(f[1], 8) >= RT1[0]:
                hits = find(w1, w2, int(f[1], 8), 0o33027, 0o40000)
                if len(hits) == 1:
                    print(f'ov2 {hits[0]:05o} {f[2]}')
        return
    calls = subprocess.run([sys.executable, str(HERE/'calls.py'), 'ov2'],
                           capture_output=True, text=True, check=True).stdout
    src = (HERE/'ov1.pas').read_text()
    for line in calls.splitlines():
        f = line.split()
        x, kind, n = int(f[0], 8), f[1], f[3]
        # An entry in a table of jumps needs the words before it as well.
        hits = find(w2, w1, x, *RT1, window)
        y = f'{hits[0]:05o}' if len(hits) == 1 else '-' if not hits else f'{len(hits)}?'
        decl = ''
        if len(hits) == 1:
            m = re.search(rf'^(?:procedure|function) x{y}\b.*$', src, re.M)
            decl = m[0] if m else ''
        print(f'{x:05o} {y:>5} {kind} {n:>3} {decl}')


if __name__ == '__main__':
    main()
