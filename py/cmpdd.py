#!/usr/bin/env python3
"""Compare two dispak drum dumps (or zongp.pl .silver files) word by word.

Usage: cmpdd.py gold silver
  Both are text lines "... ; с oooo oooo oooo oooo ; addr" or "с 0 ; addr"
  as dispak --drum-dump prints them.  Prints the number of differing
  words and the first 40 of them (address, gold, silver).
"""
import re
import sys


def load(path):
    m = {}
    for line in open(path, encoding='utf-8'):
        r = re.search(r'с (\d{4} \d{4} \d{4} \d{4}|0) ; (\d+)\s*$', line)
        if r:
            v = r.group(1)
            m[int(r.group(2), 8)] = 0 if v == '0' else int(v.replace(' ', ''), 8)
    return m


def main():
    g, s = load(sys.argv[1]), load(sys.argv[2])
    bad = [a for a in sorted(set(g) | set(s)) if g.get(a, 0) != s.get(a, 0)]
    print(len(bad), 'differ')
    for a in bad[:40]:
        print('%05o %016o %016o' % (a, g.get(a, 0), s.get(a, 0)))


if __name__ == '__main__':
    main()
