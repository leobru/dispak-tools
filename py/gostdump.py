#!/usr/bin/env python3
# Dump words of a memory image with their GOST-10859 text (6 chars/word).
#
# Usage: gostdump.py image lo hi [base]   (addresses in octal, base 2000)
#   The character table is taken from gost10859.h next to this script.

import os, re, sys

here = os.path.dirname(os.path.abspath(__file__))
gost = {}
for line in open(os.path.join(here, '..', 'tools', 'gost10859.h'), encoding='utf-8'):
    m = re.match(r'#define\s+GOST_(\w+)\s+(0[0-7]+)\s*(?:/\*\s*(.*?)\s*\*/)?', line)
    if m:
        name, code, ch = m.groups()
        if not ch:
            ch = ' ' if name.startswith('SPACE') else '.'
        gost.setdefault(int(code, 8), ch[0] if name != 'DIAMOND' else '◊')

img, lo, hi = sys.argv[1], int(sys.argv[2], 8), int(sys.argv[3], 8)
base = int(sys.argv[4], 8) if len(sys.argv) > 4 else 0o2000
d = open(img, 'rb').read()
for a in range(lo, hi):
    b = d[(a - base) * 6:(a - base) * 6 + 6]
    w = int.from_bytes(b, 'big')
    print('%05o %016o %s' % (a, w, ''.join(gost.get(c, '.') for c in b)))
