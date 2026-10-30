#!/usr/bin/env python3
"""Print the .data section of АСС3's head (initialised globals and commons).

Usage: python3 programs/acc3/headdata.py > data.inc

Reads build/acc3/head.bin (made by parts.py). DATA lists each
initialised variable with its address and the form of its words: a
'string' is one literal of 6 characters per word (KOI-8, as under a4),
'text' words become 6-character literals, 'int' words integers, the rest
raw octal C words. A run of equal words is written as
`value:count`. Paste the output after the main program of head.pas,
between `_).data` and `end`.
"""
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import BUILD
from corpus import read_words

BASE = 0o2000
# (lvalue, first address, number of words, form)
DATA = [(f'g0051[{k + 1}]', 0o2115 + 6*k, 6, 'string')  # 58 messages
     for k in range(58)] + [
    ('g0614', 0o2660, 2, 'raw'),
    ('g0617', 0o2663, 2, 'raw'),
    ('g0724', 0o2770, 0o100, 'raw'),    # packed array [0..255] of w12
    ('g1134', 0o3200, 1, 'raw'),
    ('g1140.hi', 0o3204, 1, 'raw'),
    ('g1142.lo', 0o3207, 1, 'raw'),
    ('g1144.hi', 0o3210, 1, 'raw'),
    ('g1146.hi', 0o3212, 1, 'raw'),
    ('g1150', 0o3214, 12, 'int'),       # days before each month
    ('zh', 0o3347, 6, 'int'),
]


def text(word):
    data = word.to_bytes(6, 'big')
    if not all(32 <= b < 127 or b >= 0o300 for b in data):
        return None
    return "'" + ''.join("''" if b == 39 else chr(b) if b < 127 else
                         bytes([b]).decode('koi8_r') for b in data) + "'"


def literal(word, form):
    if form == 'text' and text(word):
        return text(word)
    if form == 'int' and word >> 40 == 0o320:
        return str(word & (1 << 40) - 1)
    return f'{word:o}C'


def main():
    words = read_words(BUILD/'acc3/head.bin')
    for name, addr, n, form in DATA:
        items = []
        values = [words[addr - BASE + k] for k in range(n)]
        if form == 'string':
            # One literal for a packed array of characters.
            print(f"{name} := '" + ''.join(text(v)[1:-1] for v in values) + "';")
            continue
        k = 0
        while k < n:
            run = 1
            while k + run < n and values[k + run] == values[k]:
                run += 1
            item = literal(values[k], form)
            items.append(item + (f':{run}' if run > 1 else ''))
            k += run
        lines, line = [], f'{name} := '
        for i, item in enumerate(items):
            piece = item + (',' if i + 1 < len(items) else ';')
            if len(line) + len(piece) + 1 > 70:
                lines.append(line.rstrip())
                line = '    '
            line += piece + ' '
        lines.append(line.rstrip())
        print('\n'.join(lines))


if __name__ == '__main__':
    main()
