#!/usr/bin/env python3
"""List the code of family overlays side by side around given addresses.

Usage: python3 programs/acc2/famctx.py NAME addr [NAME addr ...] [-n N]

NAME is acc3, acc2, r3 or r2 (overlay 1, from family.py) or NAME/ov2;
addr octal. N words (default 12) are listed from each address, with the
pool values of `'k'(М10)` operands (see ctx.py).
"""
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import BUILD
import ctx
from corpus import read_words

FAMILY = BUILD/'acc-family'


def main():
    args = sys.argv[1:]
    n = 12
    if '-n' in args:
        k = args.index('-n')
        n = int(args[k+1])
        del args[k:k+2]
    for name, addr in zip(args[::2], args[1::2]):
        image = FAMILY/(name if '/' in name else name + '/ov1')
        image = image.with_suffix('.bin')
        w = read_words(image)
        pool = w[0o13] >> 24 & 0o77777
        print(f'=== {name}')
        print('\n'.join(ctx.listing(image, 0o4000, int(addr, 8), n, pool, w, 0o4000)))


if __name__ == '__main__':
    main()
