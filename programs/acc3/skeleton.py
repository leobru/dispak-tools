#!/usr/bin/env python3
"""List the procedures of a NEWPASC code range: entry, level, frame, nesting.

Usage: python3 programs/acc3/skeleton.py image.bin base lo hi

A procedure is entered by `[зп k(М17);] пв(л) P/n(М16); слиа N(М17)`, where
P/n is a runtime routine whose second instruction is `уии Mn(М17)`; n is the
level. The parameter store `зп k(М17)` means k-3+1 parameters (the last one
arrives in the accumulator); so does `зп (М17); слиа -k(М17)` before the
call, with k-3 parameters (the caller pushed them above 3 reserved words). The procedure ends where the next one begins; a
procedure's nested procedures precede it, so the parent of a level-n
procedure is the first later procedure of level n-1. Prints one line per
procedure: entry, level, parameters, the слиа operand, length in words,
parent entry. All addresses octal.
"""
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from corpus import read_words


def half(words, base, a, side):
    w = words[a-base]
    return w >> 24 if side == 0 else w & 0xffffff


def long_op(h):
    return (h >> 20, (h >> 15) & 0o37, h & 0o77777) if h & (1 << 19) else None


def short_op(h):
    if h & (1 << 19):
        return None
    off = h & 0o7777
    if h & (1 << 18):
        off -= 0o10000
    return (h >> 20, ((h >> 12) & 0o77) | (0o100 if h & (1 << 18) else 0), off)


def level_of(words, base, target):
    """n if the routine at target is `ржа 3; счи М7; уии М7(М17); уии Mn(М17)`."""
    seq = [half(words, base, target + k//2, k % 2) for k in range(4)]
    if (seq[0] >> 12) != 0o37 or any((h >> 20) != 0o17 or ((h >> 12) & 0o177) != 0o44
                                    for h in seq[2:4]) or (seq[2] & 0o17) != 7:
        return None
    return seq[3] & 0o17


def procedures(words, base, lo, hi):
    halves = [(a, s, half(words, base, a, s)) for a in range(lo, hi) for s in (0, 1)]
    found = []
    for i, (a, s, h) in enumerate(halves):
        op = long_op(h)
        if not op or op[0] != 0o16 or op[1] != 0o31:
            continue
        level = level_of(words, base, op[2])
        if level is None:
            continue
        params, entry = 0, a
        prev = halves[i-1][2] if i else 0
        p = short_op(prev)
        q = long_op(prev)
        before = short_op(halves[i-2][2]) if i > 1 else None
        if p and p[0] == 0o17 and p[1] == 0:
            params, entry = p[2]-2, halves[i-1][0]
        elif (q and q[0] == 0o17 and q[1] == 0o25 and q[2] > 0o70000
              and before == (0o17, 0, 0)):
            # `зп (М17); слиа -N(М17)`: the caller pushed 3+params words
            params, entry = 0o100000 - q[2] - 3, halves[i-2][0]
        nxt = [x[2] for x in halves[i+1:i+3] if x[2] != 0o2200000]
        n = nxt[0] if nxt else 0
        frame = n & 0o77777 if long_op(n) and long_op(n)[1] == 0o25 and (n >> 20) == 0o17 else None
        found.append([entry, level, params, frame])
    for k, p in enumerate(found):
        end = found[k+1][0] if k+1 < len(found) else hi
        parent = next((q[0] for q in found[k+1:] if q[1] == p[1]-1), None)
        p += [end-p[0], parent]
    return found


def main():
    image, base, lo, hi = sys.argv[1], *(int(a, 8) for a in sys.argv[2:5])
    for entry, level, params, frame, length, parent in procedures(read_words(image), base, lo, hi):
        print(f'{entry:05o} L{level} p{params} f{frame if frame is None else oct(frame)[2:]}'
              f' len{length:o} parent {"-" if parent is None else f"{parent:05o}"}')


if __name__ == '__main__':
    main()
