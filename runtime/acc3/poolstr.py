#!/usr/bin/env python3
"""Print strings of an АСС3 part as Pascal literals (KOI-8, as under a4).

Usage: python3 runtime/acc3/poolstr.py ov1|ov2|head addr:len [addr:len ...]

addr is octal, len decimal (the M12 of the P/7A call). Bytes outside the
printable range are written as '_ooo'; a quote is doubled.
"""
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'runtime' for p in HERE.parents
                            if (p/'runtime/paths.py').exists())))
from paths import BUILD
from corpus import read_words

BASE = {'head': 0o2000, 'ov1': 0o4000, 'ov2': 0o4000}


def main():
    part = sys.argv[1]
    words = read_words(BUILD/'acc3'/f'{part}.bin')
    for spec in sys.argv[2:]:
        addr, n = spec.split(':')
        addr, n = int(addr, 8), int(n)
        data = b''.join(words[addr - BASE[part] + k].to_bytes(6, 'big')
                        for k in range((n + 5)//6))[:n]
        text = ''.join("''" if b == 39 else chr(b) if 32 <= b < 127 else
                       bytes([b]).decode('koi8_r') if b >= 0o300 else f'_{b:03o}'
                       for b in data)
        print(f"{addr:05o}:{n} '{text}'")


if __name__ == '__main__':
    main()
