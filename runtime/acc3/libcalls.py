#!/usr/bin/env python3
"""Check that a built overlay calls the same runtime entries as the original.

Usage: python3 runtime/acc3/libcalls.py ov1|ov2 [hi]

insdiff.py hides long addresses, so a call of one runtime entry for another
(P/WOLN for P/WL, P/WI for P/WC) looks the same. Where the user code of the
build already matches the original (up to the octal address hi, default
the end of the user code), the calls are at the same addresses. This pairs
every `пб`/`пв` above the user code in the original with the one at the
same address in the build that ovtry.py made last, named by its loader map,
and prints each original target that is paired with more than one name and
each name paired with more than one original target, with the places.
Data addresses in the runtime (`уиа D(М13)`, the descriptor of a packed
array element) are paired too: a pair whose first three words differ is
printed as well, with the names of the build.
"""
from collections import defaultdict
from pathlib import Path
import re
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'runtime' for p in HERE.parents
                            if (p/'runtime/paths.py').exists())))
import paths
from corpus import read_words

BUILD = paths.BUILD/'acc3'
LAYOUT = {'ov1': (0o4014, 0o17731), 'ov2': (0o4014, 0o31346)}


def calls(words, lo, hi, end, base, ops=(0o30, 0o31)):
    """{address: target} of the long jumps and calls in lo..hi-1 beyond end."""
    out = {}
    for a in range(lo, hi):
        w = words[a - base]
        for k, h in enumerate((w >> 24, w & 0o77777777)):
            if h & (1 << 19) and (h >> 15) & 0o37 in ops and h & 0o77777 >= end:
                out[a, k] = h & 0o77777
    return out


def near(names, t):
    """name+offset of t from the nearest name at or below it."""
    a = max((a for a in names if a <= t), default=None)
    return f'{names[a]}+{t - a:o}' if a is not None else f'{t:05o}'


def main():
    part = sys.argv[1]
    lo, end = LAYOUT[part]
    hi = int(sys.argv[2], 8) if len(sys.argv) > 2 else end
    lst = (BUILD/f'try/{part}.lst').read_text(encoding='utf-8-sig', errors='replace')
    names = {int(a, 8): n for n, a in
             re.findall(r'(\S+)\s+(?:[EC]\s+)?([0-7]{5})(?=\s|$)', lst)}
    mend = next(a for a, n in sorted(names.items()) if n == 'OVSTK')
    orig = calls(read_words(BUILD/f'{part}.bin'), lo, hi, end, 0o4000)
    mine = calls(read_words(BUILD/f'try/{part}.img'), lo, hi, mend, 0o2000)
    by_target, by_name = defaultdict(dict), defaultdict(dict)
    for place, t in orig.items():
        if place in mine:
            n = names.get(mine[place], f'{mine[place]:05o}')
            by_target[t].setdefault(n, []).append(place[0])
            by_name[n].setdefault(t, []).append(place[0])
    for t, ns in sorted(by_target.items()):
        if len(ns) > 1:
            print(f'{t:05o}: ' + '; '.join(f'{n} at ' + ' '.join(f'{a:05o}' for a in p[:6])
                                         for n, p in ns.items()))
    for n, ts in sorted(by_name.items()):
        if len(ts) > 1:
            print(f'{n}: ' + '; '.join(f'{t:05o} at ' + ' '.join(f'{a:05o}' for a in p[:6])
                                       for t, p in ts.items()))
    ow, mw = read_words(BUILD/f'{part}.bin'), read_words(BUILD/f'try/{part}.img')
    od = calls(ow, lo, hi, end, 0o4000, (0o24,))
    md = calls(mw, lo, hi, mend, 0o2000, (0o24,))
    seen = set()
    for place, t in sorted(od.items()):
        m = md.get(place)
        if m is None or m >= 0o77775 or (t, m) in seen:
            continue
        seen.add((t, m))
        a, b = ow[t - 0o4000:t - 0o4000 + 3], mw[m - 0o2000:m - 0o2000 + 3]
        if a != b:
            print(f'data at {place[0]:05o}: {t:05o} != {near(names, m)}: '
                  + ' '.join(f'{w:016o}' for w in a) + ' / '
                  + ' '.join(f'{w:016o}' for w in b))


if __name__ == '__main__':
    main()
