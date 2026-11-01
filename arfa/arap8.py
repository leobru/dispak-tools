#!/usr/bin/env python3
"""Print a file of the АРАП text archive (8-bit БЕМШ code) as text.

Usage: arap8.py FILE.bin
  FILE.bin: zones dumped with besmtool, e.g. the file ЗАПАР:
  besmtool dump 2248 --start=03124 --length=1 --to-file=z3124.bin

Each line is a record that starts on a word boundary.  Byte 0 of its
first word is 0100, bytes 1-2 are the line number, byte 5 is the
number of leading spaces.  The text follows up to a zero byte and is
padded with words that start with 0 or 1; bytes
001-077 stand for that many spaces, 0100-0137 and 0240-0337 are
characters (KOI-7 code + 040 and + 0140, as in besmtool --encoding=b).
The file ends at the first word that is not a record header or has
line number 0.
"""
import sys

KOI7 = {c: chr(c) for c in range(0o40, 0o140)}
KOI7.update({c: ch for c, ch in zip(range(0o140, 0o177),
                                    'ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЫЗШЭЩЧ')})


def char(b):
    if 0o100 <= b <= 0o137:
        return KOI7[b - 0o40]
    if 0o240 <= b <= 0o336:
        return KOI7[b - 0o140]
    return '<%o>' % b


def main():
    d = open(sys.argv[1], 'rb').read()
    i = 0
    while i + 6 <= len(d) and d[i] == 0o100:
        num = d[i + 1] << 8 | d[i + 2]
        if not num:
            break
        s = [' ' * d[i + 5]]
        j = i + 6
        while j < len(d) and d[j]:
            s.append(' ' * d[j] if d[j] < 0o100 else char(d[j]))
            j += 1
        print('%4d %s' % (num, ''.join(s).rstrip()))
        i = (j // 6 + 1) * 6
        while i + 6 <= len(d) and d[i] in (0, 1):
            i += 6


if __name__ == '__main__':
    main()
