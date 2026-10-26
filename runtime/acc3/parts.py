#!/usr/bin/env python3
"""Split АСС3 (volume 4001 zones 0132-0171) into its head and overlays.

Usage: python3 runtime/acc3/parts.py [image.bin] [outdir]

The head (zone +0) is loaded by the Monitor at 02000. It reads overlay 1
(zones +4..+016) and then overlay 2 (zones +020..+035) to 04000, each with
one Э70 of its first zone; the overlay's own PASCODER stub reads the rest.
Writes head.bin (base 02000), ov1.bin and ov2.bin (base 04000) to outdir
(default runtime/build/acc3) and prints the zone map.
"""
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from corpus import pack, read_words

ORIGINAL = HERE.parent/'images/4001/0132-acc3.bin'
ZONE = 0o132
# name, first zone (relative), zones, load address
PARTS = [('head', 0, 1, 0o2000), ('ov1', 0o4, 0o13, 0o4000), ('ov2', 0o20, 0o16, 0o4000)]
UNUSED = [(0o1, 3), (0o17, 1), (0o36, 2)]


def split(words):
    return {name: words[z*1024:(z+n)*1024] for name, z, n, _ in PARTS}


def main():
    image = Path(sys.argv[1]) if len(sys.argv) > 1 else ORIGINAL
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else HERE.parent/'build/acc3'
    out.mkdir(parents=True, exist_ok=True)
    words = read_words(image)
    for name, z, n, base in PARTS:
        part = words[z*1024:(z+n)*1024]
        (out/f'{name}.bin').write_bytes(pack(part))
        count = part[0o11]
        print(f'{name:5} zones {ZONE+z:04o}-{ZONE+z+n-1:04o} -> '
              f'{base:05o}-{base+n*1024-1:05o}, stub count {count}')
    for z, n in UNUSED:
        print(f'unused zones {ZONE+z:04o}-{ZONE+z+n-1:04o}')


if __name__ == '__main__':
    main()
