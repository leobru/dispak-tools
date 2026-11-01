#!/usr/bin/env python3
"""Linear disassembly: every word in LO..HI as two instructions.

Usage: lindis.py image BASE LO HI   (octal; image of words from BASE)
Unlike disbesm6 it does not follow the control flow, so code that is
reached only through a case table or a call from elsewhere is shown too.
Mnemonics are Madlen's (img2madlen.py).
"""
import sys
from img2madlen import decode

d = open(sys.argv[1], 'rb').read()
base, lo, hi = (int(a, 8) for a in sys.argv[2:5])
for a in range(lo, hi):
    w = int.from_bytes(d[6 * (a - base):6 * (a - base) + 6], 'big')
    out = []
    for h in (w >> 24, w & 0o77777777):
        reg, name, addr, _ = decode(h)
        out.append('%-2s %-4s %o' % (reg or '', name, addr))
    print('%05o  %-22s %s' % (a, out[0], out[1]))
