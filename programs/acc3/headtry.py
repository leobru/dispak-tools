#!/usr/bin/env python3
"""Compile the АСС3 head source and compare its image with zone 0132.

Usage: python3 programs/acc3/headtry.py [programs/acc3/head.pas]

The source is compiled by NEWPASC built from mypas.b6 (the compiler of
ovtry.py, in its work directory build/acc3/try) and linked in the
original layout: P/BOOT at 02000-02006, P/CODER at 02007-02012 (its S
parameter sets FREE to 040000, above both overlays), an empty HROOT that
holds the PROGRAM entry, the head program at 02013, then the
commons P/1D, *INPUT*, *OUTPUT* (declared by the empty module HCOM before
the program declares them) and the program parameters, then the
services X03606 and X03612 and the library modules P/EF and P/1. The two
services are assembler modules taken word for word from the image (they
are not Pascal). As in the original, PASCODER writes through drive 040,
which gives the exchange word 02007. Prints the compiler errors, the placement and every word
of 02000-03777 that differs from the original.
"""
from pathlib import Path
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import BUILD
import ovtry
from corpus import read_words

BASE = 0o2000
BOOT = '''\
 P/BOOT:,NAME,
 P/CODER:,SUBP,
 HROOT:,SUBP,
 X02000:2,VTM,P/CODER
 2,WTC,2B
 3,VTM,77777B
 ,UTC,
 X02002:3,VZM,HROOT
 ,UTC,X02006
 ,LOG,0013000010000000
 3,UTM,77777B
 2,*70,
 2,XTA,
 ,UJ,X02002
 X02006:,LOG,0000010000000001
 ,END,
 HROOT:,NAME,
 HCOM:,SUBP,
 {program}:,SUBP,
 PROGRAM:,ENTRY,
 ,END,
 HCOM:,NAME,
 P/1D:,LC,1177B
 *INPUT*:,LC,36B
 *OUTPUT*:,LC,36B
 ,END,
'''


def services(words):
    """X03606 (reads cell 052) and X03612 (reads one zone and jumps to it)."""
    return (ovtry.comp.helper(words, 'X03606', 0o3606, 0o3612,
                              data=[(0o3607, 0o3612)]) +
            ovtry.comp.helper(words, 'X03612', 0o3612, 0o3620,
                              data=[(0o3616, 0o3620)]))


def main():
    source = Path(sys.argv[1] if len(sys.argv) > 1 else HERE/'head.pas').resolve()
    text = source.read_text()
    name = re.search(r'^program\s+(\S+?)\s*[(;]', text, re.M|re.I)[1].upper()
    words = read_words(BUILD/'acc3/head.bin')
    work = ovtry.WORK
    ovtry.compiler()
    disk = work/'3777'
    disk.write_bytes(b'')
    deck = ('user 419900зс5^\n'
            'dis 31(2113)32(77)33(2148-440)34(2048)40(3777-wr)^\n'
            'eeb1a3\n*name\n*assem\n' + services(words) +
            '*libra:13\n*call ficmemory\n*trans:newpasc,,320000\n' + text +
            '\n*perso:311160,cont\n*perso:320200,cont\n'
            '*assem\n' + BOOT.format(program=name) +
            '*table:p/coder(w*400000,l*3,s*40000)\n*main pascoder\n'
            '*execute\n*end file\n``````\nеконец\n')
    job = work/'head.b6'
    job.write_text(deck)
    path = f'{work}:{Path.home()}/.besm6:/usr/local/share/besm6'
    listing = work/'head.lst'
    with listing.open('w') as out:
        subprocess.run(['dispak', '--path='+path, '-l', str(job)], stdout=out,
                       stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, timeout=120)
    log = listing.read_text(encoding='utf-8-sig', errors='replace')
    for line in log.splitlines():
        if (line.startswith(' ****') or re.search(r'IN\s+\d+\s+LINES', line)
                or 'HEBEPH' in line and not re.match(r'\s*\d{5}\s+\d+\s', line)):
            print(line)
    for m in re.finditer(r'(HROOT|' + name + r'|P/1D|\*INPUT\*|\*OUTPUT\*|ZA|ZL|'
                         r'X03606|X03612|P/EF|P/1|CBOБOД)\s+[EC]?\s*([0-7]{5})', log):
        print(m[1], m[2])
    image = work/'head.img'
    image.unlink(missing_ok=True)
    if not disk.stat().st_size:
        sys.exit('PASCODER did not write the image (see the listing)')
    subprocess.run(['besmtool', 'dump', '3777', '--start=0', '--length=1',
                    '--to-file='+str(image)], env={'BESM6_PATH': str(work),
                    'PATH': '/usr/local/bin:/usr/bin:/bin'}, check=True,
                   stdout=subprocess.DEVNULL)
    built = read_words(image)
    diff = [a for a in range(BASE, BASE + len(words))
            if words[a - BASE] != (built[a - BASE] if a - BASE < len(built) else None)]
    print(f'{len(diff)} of {len(words)} words differ')
    for a in diff:
        print(f'{a:05o} {words[a - BASE]:016o} {built[a - BASE]:016o}')


if __name__ == '__main__':
    main()
