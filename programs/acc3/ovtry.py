#!/usr/bin/env python3
"""Compile a candidate АСС3 overlay source and diff its code with the original.

Usage: python3 programs/acc3/ovtry.py ov1|ov2 source.pas [--full] [--pads]
                                     [--range lo hi] [--dis]

The source is compiled by NEWPASC built from mypas.b6 into the work
directory (rebuilt when mypas.b6 changes) and linked with
the standard Monitor library in the original layout: P/1D at 02044, the
overlay's stub at 04000, its program at 04013, then the stack cell,
*INPUT* and *OUTPUT* (see BOOT). The runtime is not АСС3's, but
insdiff.py hides long addresses, so the user code compares structurally.
Prints the compiler errors, the placement of the stub and commons, how
many words of the constant pool differ, and the
insdiff --shift of the user code (all of it with --full, else the first
differing blocks; blocks that differ only in `мода` fillers are counted
but shown only with --pads; --range keeps the blocks whose original
addresses fall in lo..hi-1, octal; --dis also writes the disassembly of
the built overlay to <part>.dis there). Work files are kept under
build/acc3/try.
Every `assembler` or `fortran` external of the source gets an empty stub
module, so that the program links; their code is not compared. P/WH
(write ... hex), which the standard library lacks, comes with its module
P/WO from the PROZ runtime (build/proz/runtime.madlen, made by
programs/proz/build.py).
"""
from pathlib import Path
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import TOOLS, COMPILER, PROGRAMS, BUILD
from corpus import pack, read_words, sha
import importlib.util
import json

spec = importlib.util.spec_from_file_location('compbuild', PROGRAMS/'comp/build.py')
comp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(comp)

WORK = BUILD/'acc3/try'
PROZ_RUNTIME = BUILD/'proz/runtime.madlen'
INSDIFF = Path.home()/'.claude/skills/besm6-pascal-decompile/scripts/insdiff.py'
# Original layout of each overlay: user code range and number of zones.
LAYOUT = {'ov1': (0o4014, 0o17731, 0o13), 'ov2': (0o4014, 0o31346, 0o16)}
# End of the constant pool (the first common after it).
POOL_END = {'ov1': 0o20537, 'ov2': 0o32560}
# The overlay stub's exchange word: read page 2 from drive 040, zone +4 or +020.
EXCHANGE = {'ov1': 0o0000020000400004, 'ov2': 0o0000020000400020}
# The loader places the modules of P/BOOT's list level by level and, after
# each level, the commons declared so far. The module with the PROGRAM entry
# comes first. So OVROOT (the PROGRAM, 02012-02043) is followed by P/1D,
# declared in P/BOOT with the head's length; OVPAD fills up to 04000, where
# OVBOOT holds the overlay's stub and its P/CODER words. The overlay program,
# referenced by its module name, follows at 04013 and is followed by the
# commons OVBOOT declares, in that order.
BOOT = '''\
 P/BOOT:,NAME,
 P/1D:,LC,1177B
 P/CODER:,SUBP,
 OVROOT:,SUBP,
 X02000:2,VTM,P/CODER
 2,WTC,2B
 3,VTM,77777B
 ,UTC,
 X02002:3,VZM,OVROOT
 ,UTC,X02006
 ,LOG,0013000010000000
 3,UTM,77777B
 2,*70,
 2,XTA,
 ,UJ,X02002
 X02006:,LOG,0000010000000001
 ,END,
 OVROOT:,NAME,
 OVPAD:,SUBP,
 OVBOOT:,SUBP,
 {program}:,SUBP,
 ,BSS,1
 PROGRAM:,ENTRY,
 ,BSS,31B
 ,END,
 OVPAD:,NAME,
 ,BSS,535B
 ,END,
 OVBOOT:,NAME,
 OVSTK:,LC,1
 *INPUT*:,LC,36B
 *OUTPUT*:,LC,36B
 {program}:,SUBP,
 X04000:2,VTM,X04007
 2,WTC,2B
 3,VTM,77777B
 ,UTC,
 X04002:3,VZM,{program}
 ,UTC,X04006
 ,LOG,0013000010000000
 3,UTM,77777B
 2,*70,
 2,XTA,
 ,UJ,X04002
 X04006:,LOG,0000010000000001
 X04007:,LOG,{exchange:016o}
 ,LOG,0000000000000000
 ,LOG,{count:016o}
 ,LOG,0000000000000000
 ,END,
'''


def module(madlen, name):
    """The module `name:,NAME,` ... `,END,` of a Madlen text, without comments."""
    lines = [l for l in madlen.splitlines() if not l.startswith('C')]
    start = lines.index(f' {name}:,NAME,')
    end = lines.index(' ,END,', start)
    return '\n'.join(lines[start:end+1]) + '\n'


def stubs(text):
    """*assem cards with an empty module for each assembler/fortran external."""
    names = re.findall(r'\b(?:procedure|function)\s+(\w+)\s*(?:\([^)]*\))?[^;]*;'
                       r'\s*(?:assembler|fortran)\s*;', text, re.I)
    cards = ''.join(f' {n.upper()}:,NAME,\n 13,UJ,\n ,END,\n' for n in names)
    if re.search(r':\s*\d+\s+hex\b', text, re.I):
        cards += module(PROZ_RUNTIME.read_text(), 'P/WO')
    return '*assem\n' + cards if cards else ''


def compiler():
    """Rebuild NEWPASC into WORK/77 when mypas.b6 has changed."""
    WORK.mkdir(parents=True, exist_ok=True)
    stamp = WORK/'compiler.json'
    built = json.loads(stamp.read_text()) if stamp.exists() else {}
    if (built.get('source_sha256') != sha((COMPILER/'mypas.b6').read_bytes())
            or not (WORK/'77').exists()):
        built = comp.more.rebuild_compiler(WORK)
        stamp.write_text(json.dumps(built, indent=2) + '\n')


def main():
    part, source = sys.argv[1], Path(sys.argv[2]).resolve()
    lo, hi, zones = LAYOUT[part]
    name = re.search(r'^program\s+(\S+?)\s*[(;]', source.read_text(), re.M|re.I)[1].upper()
    compiler()
    disk = WORK/'3777'
    disk.write_bytes(b'')
    deck = ('user 419900зс5^\n'
            'dis 31(2113)32(77)33(2148-440)34(2048)67(3777-wr)^\n'
            'eeb1a3\n*name\n' + stubs(source.read_text()) + '*libra:13\n*call ficmemory\n*trans:newpasc,,320000\n'
            + source.read_text() + '\n*perso:311160,cont\n*perso:320200,cont\n'
            '*assem\n' + BOOT.format(exchange=EXCHANGE[part], count=zones, program=name) +
            f'*table:p/coder(w*670000,l*{zones+2:o})\n*main pascoder\n'
            '*execute\n*end file\n``````\nеконец\n')
    job = WORK/f'{part}.b6'
    job.write_text(deck)
    path = f'{WORK}:{Path.home()}/.besm6:/usr/local/share/besm6'
    listing = WORK/f'{part}.lst'
    with listing.open('w') as out:
        subprocess.run(['dispak', '--path='+path, '-l', str(job)], stdout=out,
                       stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, timeout=120)
    text = listing.read_text(encoding='utf-8-sig', errors='replace')
    for line in text.splitlines():
        if (line.startswith(' ****') or re.search(r'IN\s+\d+\s+LINES', line)
                or 'HEBEPH' in line):
            print(line)
    for m in re.finditer(r'(OVBOOT|OVSTK|P/1D|\*INPUT\*|\*OUTPUT\*)\s+[EC]?\s*([0-7]{5})', text):
        print(m[1], m[2])
    image = WORK/f'{part}.img'
    image.unlink(missing_ok=True)
    if not disk.stat().st_size:
        sys.exit('PASCODER did not write the image (see the listing)')
    subprocess.run(['besmtool', 'dump', '3777', '--start=0', f'--length={zones+2}',
                    '--to-file='+str(image)], env={'BESM6_PATH': str(WORK),
                    'PATH': '/usr/local/bin:/usr/bin:/bin'}, check=True,
                   stdout=subprocess.DEVNULL)
    ref = WORK/f'{part}-ref.bin'
    words = read_words(BUILD/'acc3'/f'{part}.bin')
    ref.write_bytes(pack([0]*1024 + words))
    diff = subprocess.run([sys.executable, str(INSDIFF), str(ref), str(image),
                           f'{lo:o}', f'{hi:o}', '--shift'],
                          capture_output=True, text=True).stdout
    built = read_words(image)
    pool = (built[0o4013 - 0o2000] >> 24) & 0o77777
    end = POOL_END.get(part, hi)
    bad = [k for k in range(end - hi)
           if words[hi - 0o4000 + k] != (built[pool - 0o2000 + k]
                                          if pool - 0o2000 + k < len(built) else None)]
    if '--dis' in sys.argv:
        seeds = subprocess.run([sys.executable, str(HERE/'codeseeds.py'), str(image),
                                '2000', '4013', '4000', f'{pool:o}'],
                               capture_output=True, text=True, check=True).stdout
        (WORK/f'{part}.seeds').write_text(seeds)
        listing = subprocess.run([str(TOOLS/'disbesm6'), '-b', '-a2000', '-e4013',
                                  '-n', str(WORK/f'{part}.seeds'), str(image)],
                                 capture_output=True, text=True).stdout
        (WORK/f'{part}.dis').write_text(listing)
    print(f'pool: {len(bad)} of {end - hi} words differ' +
          (f', first at +{bad[0]:o}' if bad else ''))
    blocks = diff.split('--- ')
    head, blocks = blocks[0], blocks[1:]
    pads = [b for b in blocks
            if all(line.endswith('00 22 00000') for line in b.splitlines()[1:])]
    if '--pads' not in sys.argv:
        blocks = [b for b in blocks if b not in pads]
    if '--range' in sys.argv:
        k = sys.argv.index('--range')
        rlo, rhi = int(sys.argv[k+1], 8), int(sys.argv[k+2], 8)
        def inside(block):
            t = [int(l.split()[1], 8) for l in block.splitlines()[1:] if l.startswith('T ')]
            m = [int(l.split()[1], 8) for l in block.splitlines()[1:] if l.startswith('M ')]
            return any(rlo <= a < rhi for a in t) or not t and any(rlo <= a < rhi for a in m)
        blocks = [b for b in blocks if inside(b)]
    print(f'{len(blocks)} differing blocks, {len(pads)} only in мода fillers')
    print(head + ''.join('--- ' + b for b in (blocks if '--full' in sys.argv else blocks[:6])))


if __name__ == '__main__':
    main()
