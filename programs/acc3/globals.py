#!/usr/bin/env python3
"""Table of the globals that АСС3's head and overlays share through M1.

Usage: python3 programs/acc3/globals.py [lo hi]   (octal M1 offsets, default 050 1177)

For every offset it lists how the code of the head, overlay 1 and overlay 2
reaches it (`n(М1)` short addressing): the mnemonics with their counts, and
whether an index modifier (мод/мода) precedes the access. The last column is
the head's initial word (P/1D is 02044 in the head) as octal and KOI-8 text.
Run programs/acc3/parts.py first.
"""
from collections import Counter, defaultdict
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'runtime' for p in HERE.parents
                            if (p/'runtime/paths.py').exists())))
import paths
from corpus import read_words

BUILD = paths.BUILD/'acc3'
P1D = 0o2044
CODE = {'head': (0o2000, 0o2013, 0o2031), 'ov1': (0o4000, 0o4014, 0o17731),
        'ov2': (0o4000, 0o4014, 0o31346)}
SHORT = ['зп', 'зпм', 'рег', 'счм', 'сл', 'вч', 'вчоб', 'вчаб', 'сч', 'и', 'нтж', 'слц',
         'знак', 'или', 'дел', 'умн', 'сбр', 'рзб', 'чед', 'нед', 'слп', 'вчп', 'сд',
         'рж', 'счр', 'счмр', '*32', 'увв', 'слпа', 'вчпа', 'сда', 'ржа', 'уи', 'уим',
         'счи', 'счим', 'уии', 'сли', '*46', '*47']


def uses(words, base, lo, hi):
    table = defaultdict(Counter)
    for a in range(lo, hi):
        w = words[a-base]
        previous = words[a-base-1] & 0xffffff if a > lo else 0
        for half in (w >> 24, w & 0xffffff):
            reg, long = half >> 20, half & (1 << 19)
            if reg == 1 and long:
                op = (half >> 15) & 0o17
                name = {0o2: 'мода', 0o3: 'мод', 0o4: 'уиа', 0o5: 'слиа'}.get(op, f'L{0o20+op:o}')
                table[half & 0o77777][name] += 1
            elif reg == 1 and not long:
                op = (half >> 12) & 0o77
                offset = half & 0o7777
                if half & (1 << 18):
                    offset -= 0o10000
                name = SHORT[op] if op < len(SHORT) else f'*{op:o}'
                indexed = (previous >> 15) & 0o37 in (0o22, 0o23) and previous & (1 << 19)
                table[offset][name + ('[]' if indexed else '')] += 1
            previous = half
    return table


def main():
    lo, hi = (int(a, 8) for a in sys.argv[1:3]) if len(sys.argv) > 2 else (0o50, 0o1177)
    head = read_words(BUILD/'head.bin')
    tables = {}
    for part, (base, start, end) in CODE.items():
        tables[part] = uses(read_words(BUILD/f'{part}.bin'), base, start, end)
    for offset in range(lo, hi):
        cells = []
        for part in CODE:
            use = tables[part].get(offset)
            cells.append(' '.join(f'{k}{"" if n == 1 else "×"+str(n)}'
                                  for k, n in sorted(use.items())) if use else '-')
        value = head[P1D+offset-0o2000]
        koi = ''.join(chr(b) if 32 <= b < 127 else (bytes([b]).decode('koi8_r') if b >= 0o300 else '.')
                      for b in value.to_bytes(6, 'big'))
        init = f'{value:016o} {koi!r}' if value else ''
        if any(c != '-' for c in cells) or value:
            print(f'{offset:04o} {P1D+offset:05o} | ' + ' | '.join(cells) + f' | {init}')


if __name__ == '__main__':
    main()
