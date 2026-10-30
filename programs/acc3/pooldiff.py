#!/usr/bin/env python3
"""Align the constant pool of a built overlay with the original's.

Usage: python3 programs/acc3/pooldiff.py PART   (after ovtry.py PART ...)

Prints the difflib opcodes over the pool words (original T, built M,
offsets octal), with the words, so that constants missing from the
build or extra in it can be read off.
"""
from pathlib import Path
import difflib
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
import ovtry
from corpus import read_words


def main():
    part = sys.argv[1]
    rw = read_words(ovtry.IMAGE[part])
    bw = read_words(ovtry.WORK/f'{part}.img')
    tp = ovtry.LAYOUT[part][1]
    mp = bw[0o4013 - 0o2000] >> 24 & 0o77777
    end = ovtry.POOL_END.get(part, tp)
    t = rw[tp - 0o4000:end - 0o4000]
    m = bw[mp - 0o2000:mp - 0o2000 + len(t) + 64]
    sm = difflib.SequenceMatcher(None, t, m, autojunk=False)
    for op, i1, i2, j1, j2 in sm.get_opcodes():
        if op == 'equal':
            continue
        print(f'{op} T+{i1:o}..{i2:o} M+{j1:o}..{j2:o}')
        for k in range(max(i2 - i1, j2 - j1)):
            a = f'{t[i1+k]:016o}' if i1 + k < i2 else ' '*16
            b = f'{m[j1+k]:016o}' if j1 + k < j2 else ''
            print(f'   {a}  {b}')


if __name__ == '__main__':
    main()
