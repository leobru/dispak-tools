#!/usr/bin/env python3
"""Replace automatic labels inside named ranges by name+offset.

Usage: relabel.py file.sym file.be > out.be

disbesm6 -s still invents labels GNNNNN/DNNNNN for words that a .sym
file covers with a '-' range ("165-170 D -" after "164 D gline").  This
rewrites every reference to such a label as gline+1 etc., and drops the
label from the line that defines it.  Other automatic labels stay.
"""
import re
import sys


def main():
    names = {}            # address -> (name, offset)
    base = None
    for line in open(sys.argv[1], encoding='utf-8'):
        f = line.split()
        if len(f) < 3:
            continue
        lo, _, hi = f[0].partition('-')
        lo = int(lo, 8)
        hi = int(hi, 8) if hi else lo
        if f[2] == '-':
            if base is None:
                continue
            for a in range(lo, hi + 1):
                names[a] = (base[0], a - base[1])
        else:
            base = (f[2], lo)
    label = re.compile(r'\b[GDC](\d{5})\b')

    def sub(m):
        a = int(m.group(1), 8)
        if a not in names:
            return m.group(0)
        n, k = names[a]
        return '%s+%d' % (n, k)

    for line in open(sys.argv[2], encoding='utf-8'):
        head, tab, rest = line.partition('\t')
        m = label.fullmatch(head)
        if m and int(m.group(1), 8) in names:
            head = ''
        line = head + tab + label.sub(sub, rest)
        # name+k+j, as disbesm6 writes an offset from a label
        line = re.sub(r'(\w+)\+(\d+)\+(\d+)',
                      lambda m: '%s+%d' % (m.group(1),
                                           int(m.group(2)) + int(m.group(3))),
                      line)
        sys.stdout.write(line)


if __name__ == '__main__':
    main()
