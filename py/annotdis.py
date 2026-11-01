#!/usr/bin/env python3
"""Annotate a disbesm6 listing of a Pascal-Монитор program.

Usage: annotdis.py listing image BASE M10 M1 [names.txt] > out
  listing  output of disbesm6 for image (loaded at BASE, octal)
  M10      the constant pool address (from `уиа X(М10)` at 01000)
  M1       the P/1D address; n(М1) with n >= 050 is global n
  names.txt optional lines "offset name" (octal M1 offsets) for globals

Each instruction with an n(М10) operand gets a comment with the pool word:
an integer (exponent 64), a raw octal word, or its ISO text.  n(М1)
operands with n >= 050 are shown as gNNN or the given name.
"""
import re
import sys

K7 = 'юабцдефгхийклмнопярстужвьызшэщчъ'


def iso(w):
    s = ''
    for i in range(6):
        c = (w >> (40 - 8 * i)) & 0x7f
        if 0x60 <= c <= 0x7e:
            s += K7[c - 0x60].upper()
        elif 0x20 <= c < 0x60:
            s += chr(c)
        else:
            s += '·'
    return s


def value(w):
    m = w & ((1 << 41) - 1)
    if w >> 41 == 0o150:
        return '%d' % (m - (1 << 41) if m >> 40 else m)
    t = iso(w)
    if sum(c != '·' for c in t) >= 3:
        return "'%s' %016o" % (t, w)
    return '%oC' % w


def main():
    lst, img, base, m10, m1 = sys.argv[1:6]
    base, m10, m1 = int(base, 8), int(m10, 8), int(m1, 8)
    names = {}
    if len(sys.argv) > 6:
        for line in open(sys.argv[6], encoding='utf-8'):
            p = line.split()
            if len(p) >= 2 and not line.startswith('#'):
                names[int(p[0], 8)] = p[1]
    d = open(img, 'rb').read()

    def word(a):
        i = a - base
        return int.from_bytes(d[6 * i:6 * i + 6], 'big')

    def num(s):
        s = s.strip("'")
        return int(s, 8) if "'" in s or s.startswith('0') else int(s)

    out = []
    for line in open(lst, encoding='utf-8'):
        line = line.rstrip('\n')
        note = ''
        m = re.search(r"\t(-?'[0-7]+'|-?[0-9]+|)\(М10\)", line)
        if m and m.group(1):
            t = m.group(1)
            n = int(t.strip("'"), 8) if "'" in t else int(t)
            note = value(word(m10 + n))
        m = re.search(r"\t('[0-7]+'|[0-9]+|[A-ZА-Я][\w/*]*[+-]?\d*)\(М1\)", line)
        if m:
            t = m.group(1)
            n = None
            if "'" in t:
                n = int(t.strip("'"), 8)
            elif t.isdigit():
                n = int(t)
            else:
                mm = re.match(r'[A-ZА-Я][\w/*]*?(\d{5})([+-]\d+)?$', t)
                if mm:
                    n = int(mm.group(1), 8) + int(mm.group(2) or 0)
            if n is not None and n >= 0o50:
                g = names.get(n, 'g%o' % n)
                line = line[:m.start(1)] + g + line[m.end(1):]
        out.append(line + ('\t; ' + note if note else ''))
    print('\n'.join(out))


if __name__ == '__main__':
    main()
