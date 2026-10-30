#!/usr/bin/env python3
"""Structural diff of two builds of an assembler overlay (ACC family).

Usage: python3 programs/acc2/verdiff.py A B [lo hi] [--m1 A:B] [--all]
                                       [--range lo hi] [--map addr...]

A and B are names under build/acc-family (acc3, acc2, r3, r2,
made by family.py), compared overlay 1 (or `name/ov2`). Every half-word
of the code (04014 up to the start address, or lo..hi-1 of A, octal) is
reduced to "reg op operand": long addresses >= 02000 become A, an
`n(М10)` operand becomes the value of its pool word, and with --m1 an
`n(М1)` operand of B at 050 <= n < 02000 is moved by the given difference
(e.g. --m1 0:5 for АСС3 against АСС2, whose globals are 5 words further).
The two sequences are aligned with difflib; the differing blocks are
printed with their addresses on both sides (A, B), blocks of `мода`
fillers only with --all; --range keeps the blocks with A addresses in
lo..hi-1. With --map, prints instead for each given address of A the
first aligned pair of addresses (A, B) at or after it.
"""
from pathlib import Path
import difflib
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import BUILD
from corpus import read_words

FAMILY = BUILD/'acc-family'
PAD = '00 22 00000'


def load(name):
    if '/' not in name:
        name += '/ov1'
    w = read_words(FAMILY/f'{name}.bin')
    head = w[0o13]
    return w, head >> 24 & 0o77777, head & 0o77777


def halves(w, pool, lo, hi, m1=0):
    out = []
    for a in range(lo, hi):
        x = w[a - 0o4000]
        for h in (x >> 24, x & 0o77777777):
            reg, off = h >> 20, h & 0o77777
            if h & 0o2000000:
                if reg == 1 and m1 and 0o50 <= off < 0o2000:
                    off -= m1
                s = '%02o %02o %s' % (reg, h >> 15 & 0o37,
                                     'A' if off >= 0o2000 else '%05o' % off)
            else:
                op, off = h >> 12 & 0o177, h & 0o7777
                if op & 0o100:
                    off -= 0o10000
                if reg == 0o10 and 0 <= pool + off - 0o4000 < len(w):
                    s = '10 %03o =%016o' % (op, w[pool + off - 0o4000])
                elif reg == 1 and m1 and off >= 0o50:
                    s = '01 %03o %04o' % (op, off - m1)
                else:
                    s = '%02o %03o %04o' % (reg, op, off & 0o7777)
            out.append((a, s))
    return out


def main():
    argv = sys.argv[:sys.argv.index('--map')] if '--map' in sys.argv else sys.argv
    args = [a for a in argv[1:] if not a.startswith('--')]
    m1 = 0
    if '--m1' in sys.argv:
        x, y = sys.argv[sys.argv.index('--m1') + 1].split(':')
        m1 = int(y) - int(x)
        args.remove(sys.argv[sys.argv.index('--m1') + 1])
    rng = None
    if '--range' in sys.argv:
        k = sys.argv.index('--range')
        rng = int(sys.argv[k+1], 8), int(sys.argv[k+2], 8)
        args = [a for a in args if a not in sys.argv[k+1:k+3]]
    wa, pa, sa = load(args[0])
    wb, pb, sb = load(args[1])
    lo, hi = (int(args[2], 8), int(args[3], 8)) if len(args) > 3 else (0o4014, sa)
    ha = halves(wa, pa, lo, hi)
    hb = halves(wb, pb, 0o4014, sb, m1)
    sm = difflib.SequenceMatcher(None, [s for _, s in ha], [s for _, s in hb],
                                 autojunk=False)
    if '--map' in sys.argv:
        blocks = sm.get_matching_blocks()
        for q in sys.argv[sys.argv.index('--map') + 1:]:
            t = int(q, 8)
            pair = next(((ha[i+k][0], hb[j+k][0]) for i, j, n in blocks
                         for k in range(n) if ha[i+k][0] >= t), None)
            print(f'{t:05o} ->', '%05o %05o' % pair if pair else '-')
        return
    n = 0
    for op, i1, i2, j1, j2 in sm.get_opcodes():
        if op == 'equal':
            continue
        lines = [f'A {ha[i][0]:05o} {ha[i][1]}' for i in range(i1, i2)] + \
                [f'B {hb[j][0]:05o} {hb[j][1]}' for j in range(j1, j2)]
        if '--all' not in sys.argv and all(l.endswith(PAD) for l in lines):
            continue
        a0 = ha[i1][0] if i1 < len(ha) else hi
        if rng and not rng[0] <= a0 < rng[1]:
            continue
        n += 1
        print(f'--- {op}')
        print('\n'.join(lines))
    print(f'{n} differing blocks', file=sys.stderr)


if __name__ == '__main__':
    main()
