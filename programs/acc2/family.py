#!/usr/bin/env python3
"""Extract the four Эльбрус-1КБ assemblers into their head and overlays.

Usage: python3 programs/acc2/family.py

АСС3 (4001/0132) and АСС2 (4001/0215) are the native and compatibility
mode assemblers of the Monitor; АССЕМБЛЕР.РЕЖИМ3 (2248/2500) and
АССЕМБЛЕР.РЕЖИМ2 (2248/2440) are earlier builds of the same two programs.
Each file has 040 zones: the head in zone +0 (loaded at 02000), overlay 1
from zone +4 and overlay 2 from zone +020 (both loaded at 04000); the zone
count of an overlay is the word 04011 of its stub. The volumes are only
read (besmtool dump). Writes build/acc-family/<name>/head.bin,
ov1.bin, ov2.bin and prints for each part its zones, entry, pool and
start address (octal).
"""
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import BUILD
from corpus import pack, read_words

WORK = BUILD/'acc-family'
PROGRAMS = [('acc3', '4001', 0o132), ('acc2', '4001', 0o215),
            ('r3', '2248', 0o2500), ('r2', '2248', 0o2440)]


def parts(words):
    """{part: (first zone, zones, base, words)}."""
    result = {'head': (0, 1, 0o2000, words[:1024])}
    for name, zone in (('ov1', 0o4), ('ov2', 0o20)):
        count = words[zone*1024 + 0o11]
        result[name] = (zone, count, 0o4000, words[zone*1024:(zone+count)*1024])
    return result


def main():
    for name, volume, zone in PROGRAMS:
        out = WORK/name
        out.mkdir(parents=True, exist_ok=True)
        whole = out/'all.bin'
        subprocess.run(['besmtool', 'dump', volume, f'--start=0{zone:o}',
                        '--length=32', '--to-file='+str(whole)],
                       check=True, stdout=subprocess.DEVNULL)
        for part, (first, count, base, w) in parts(read_words(whole)).items():
            (out/f'{part}.bin').write_bytes(pack(w))
            entry = base + 0o13
            head = w[entry - base]
            pool, start = head >> 24 & 0o77777, head & 0o77777
            print(f'{name} {volume}/{zone+first:04o} {part}: {count} zones, '
                  f'entry {entry:05o}, pool {pool:05o}, start {start:05o}')


if __name__ == '__main__':
    main()
