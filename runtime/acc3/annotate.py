#!/usr/bin/env python3
"""Annotated disassembly of a range of an АСС3 part, for decompiling it.

Usage: python3 runtime/acc3/annotate.py ov1|ov2|head lo hi

Reads runtime/build/acc3/<part>.dis (made by disbesm6 with the codeseeds
seeds) and appends to each instruction what its operand is:
- `n(М10)`: the pool word, as an integer, a set of bits or KOI-8 text;
- `n(М1)`: the global, by the name in names.txt;
- other addresses: the names in names.txt (runtime entries, procedures,
  file blocks).

names.txt lines are `part address name` (octal) or `* m1offset name`.
"""
from pathlib import Path
import re
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import paths
from corpus import read_words

BUILD = paths.BUILD/'acc3'
BASE = {'head': 0o2000, 'ov1': 0o4000, 'ov2': 0o4000}
POOL = {'head': 0o2031, 'ov1': 0o17731, 'ov2': 0o31346}


def koi(v):
    return ''.join(chr(b) if 32 <= b < 127 else
                   (bytes([b]).decode('koi8_r') if b >= 0o300 else '.')
                   for b in v.to_bytes(6, 'big'))


def describe(v):
    if v >> 41 == 0o150:
        n = v & ((1 << 41) - 1)
        return f'={n - (1 << 41) if v & (1 << 40) else n}'
    if v and bin(v).count('1') <= 4:
        # As a Pascal set: element 0 is bit 48.
        return '=[' + ','.join(str(b) for b in range(48) if v >> (47-b) & 1) + ']'
    text = koi(v)
    if sum(c != '.' for c in text) >= 3:
        return f'={text!r}'
    return f'={v:o}C'


def main():
    part, lo, hi = sys.argv[1], int(sys.argv[2], 8), int(sys.argv[3], 8)
    words = read_words(BUILD/f'{part}.bin')
    base, pool = BASE[part], POOL[part]
    names, globals_ = {}, {}
    for line in (HERE/'names.txt').read_text().splitlines() if (HERE/'names.txt').exists() else []:
        f = line.split()
        if len(f) >= 3 and not line.startswith('#'):
            if f[0] == '*':
                globals_[int(f[1], 8)] = f[2]
            elif f[0] in (part, 'any'):
                names[int(f[1], 8)] = f[2]
    address = None
    for line in (BUILD/f'{part}.dis').read_text().splitlines():
        m = re.match(r'^ ?([0-7]{4,5})[: ]', line)
        if m:
            address = int(m[1], 8)
        if address is None or not lo <= address < hi:
            continue
        note = ''
        m = re.search(r'\t(-?\d+|\'-?[0-7]+\')?\(М10\)$', line)
        if m and 'уиа' not in line:
            off = int(m[1].strip("'"), 8 if "'" in m[1] else 10) if m[1] else 0
            if 0 <= pool + off - base < len(words):
                note = describe(words[pool + off - base])
        m = re.search(r'\t(-?\d+|\'-?[0-7]+\')?\(М1\)$', line)
        if m:
            off = int(m[1].strip("'"), 8 if "'" in m[1] else 10) if m[1] else 0
            note = globals_.get(off, f'g{off:o}')
        m = re.search(r'\b[GD]([0-7]{5})(\+\d+)?\b', line)
        if m and not note:
            target = int(m[1], 8) + (int(m[2]) if m[2] else 0)
            note = names.get(target, '')
        print(line + (f'   ; {note}' if note else ''))


if __name__ == '__main__':
    main()
