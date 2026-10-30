#!/usr/bin/env python3
"""Packed-record field reads in a range of an АСС3 part.

Usage: python3 programs/acc3/fields.py ov1|ov2|head lo hi [reg]

NEWPASC reads a packed field of word k of a record addressed by Mreg as
`сч|счм k(Mreg)` followed by one of
- `сда 64-s; счмр [; и mask]`: the top s bits, then the low bits of mask;
- `сда 64+s; и mask`: shifted right by s, then masked;
- `и mask`: the low bits.
A store of a packed field is
`[сда 64-s]; мода k(Mreg); уиа (М16); счм (М16); нтж -1(М17); и mask; ...`:
the field is where mask has zeros.
Prints each access as `addr read|store word k: bits from the left
offset..offset+width-1` (bit 48 is offset 0), which gives the layout of the
packed record. reg defaults to 4 (М4, the base of `with` and of pointer
dereference).
"""
from pathlib import Path
import re
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
import paths
from corpus import read_words

BUILD = paths.BUILD/'acc3'
POOL = {'head': 0o2031, 'ov1': 0o17731, 'ov2': 0o31346}
BASE = {'head': 0o2000, 'ov1': 0o4000, 'ov2': 0o4000}
LINE = re.compile(r'^(?: ?([0-7]{4,5})[: ]| {6})[0-7 ]{11,13}\t[^\t]*\t(\S+)\t?(\S*)')


def operand(text):
    m = re.match(r"(-?\d+|'-?[0-7]+')?\((М\d+)\)$|^(-?\d+|'[0-7]+')$", text)
    if not m:
        return None, None
    num = m[1] or m[3]
    value = 0 if num is None else int(num.strip("'"), 8) if "'" in num else int(num)
    return value, m[2]


def main():
    part, lo, hi = sys.argv[1], int(sys.argv[2], 8), int(sys.argv[3], 8)
    reg = f'М{sys.argv[4] if len(sys.argv) > 4 else 4}'
    words = read_words(BUILD/f'{part}.bin')
    pool = lambda off: words[POOL[part] + off - BASE[part]]
    insns, address = [], None
    for line in (BUILD/f'{part}.dis').read_text().splitlines():
        m = LINE.match(line)
        if not m:
            continue
        address = int(m[1], 8) if m[1] else address
        if lo <= address < hi:
            insns.append((address, m[2], m[3]))
    for k, (a, op, arg) in enumerate(insns):
        word, r = operand(arg)
        nxt = insns[k+1:k+5]
        if (op == 'мода' and r == reg and [x[1] for x in nxt] == ['уиа', 'счм', 'нтж', 'и']
                and nxt[2][2] == '-1(М17)'):
            mask = pool(operand(nxt[3][2])[0])
            zeros = [b for b in range(48) if not mask >> (47-b) & 1]
            print(f'{a:05o} store word {word}: bits {zeros[0]}..{zeros[-1]}'
                  f' (width {len(zeros)})')
            continue
        if op not in ('сч', 'счм') or r != reg:
            continue
        nxt = insns[k+1:k+4]
        ops = [x[1] for x in nxt]
        width = offset = None
        if ops[:2] == ['сда', 'счмр']:
            s = 64 - int(nxt[0][2].split('-')[1]) if '-' in nxt[0][2] else None
            if s is None:
                continue
            s = 64 - s
            top = s
            if ops[2:3] == ['и']:
                mask = pool(operand(nxt[2][2])[0])
                width = bin(mask).count('1')
                offset = top - width
            else:
                offset, width = 0, top
        elif ops[:2] == ['сда', 'и'] and '+' in nxt[0][2]:
            s = int(nxt[0][2].split('+')[1])
            mask = pool(operand(nxt[1][2])[0])
            width = bin(mask).count('1')
            offset = 48 - s - width
        elif ops[:1] == ['и']:
            mask = pool(operand(nxt[0][2])[0])
            width = bin(mask).count('1')
            offset = 48 - width
        else:
            print(f'{a:05o} read word {word}: whole word')
            continue
        print(f'{a:05o} read word {word}: bits {offset}..{offset+width-1} (width {width})')


if __name__ == '__main__':
    main()
