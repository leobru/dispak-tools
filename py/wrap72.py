#!/usr/bin/env python3
"""Wrap a Pascal source to 72-column cards in place.

Usage: wrap72.py src.pas

Each line longer than 72 characters is split at the last space that is
outside a quoted string and still within column 72; the rest goes to a
new line, and so on.  Line numbers change, so realign them afterwards
(linefix.py of the besm6-pascal-decompile skill adds or removes '%'
lines).
"""
import sys


def wrap(line):
    out = []
    while len(line) > 72:
        quoted, cut = False, -1
        for i, c in enumerate(line[:73]):
            if c == "'":
                quoted = not quoted
            if c == ' ' and not quoted:
                cut = i
        if cut <= 0:
            break
        out.append(line[:cut])
        line = line[cut + 1:]
    out.append(line)
    return out


def main():
    path = sys.argv[1]
    lines = open(path, encoding='utf-8').read().split('\n')
    result = []
    for line in lines:
        result.extend(wrap(line))
    open(path, 'w', encoding='utf-8').write('\n'.join(result))


if __name__ == '__main__':
    main()
