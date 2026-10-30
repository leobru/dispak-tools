#!/usr/bin/env python3
"""Rebuild the whole COMP image (volume 4001 zones 0315-0324) and compare it.

Usage: python3 programs/comp/build.py

comp.pas (repository root) is compiled with the mypas.b6 compiler rebuilt on a
private volume 77 and linked with a private PERSO library. That library holds:
  - the recovered Monitor runtime and COMP's file-access modules, with the
    COMP substitutions of programs/more/build.py and those below;
  - P/MI, P/WC, P/A6 and P/STAR from the standard Pascal library (libpas);
  - modules taken from COMP's own words: the accumulator-preserving P/31
    (libpas p_31 differs), P/EQ with the P/GE entry (libpas p_eq is
    shorter), the readers E6365/E6444 and E6602/E6661, and the Monitor-80
    modules DRUMTAP*, MONREAD*, PRINT8 and LUN*MON in the version linked
    into COMP.
COZYTISO and CLEARLEX come from the system's permanent library. The loader
places modules and commons in the order of one name list: the program's
external names, then each loaded module's SUBP/LC names in declaration order.
The declaration orders below reproduce COMP's layout. The library PASCODER
writes the image to a scratch 3777 zone 0250, as it did originally. All eight
zones are compared word by word with runtime/images/4001/0315-comp.bin; only
the RESIDUES may differ. Artifacts are in runtime/build/comp; the report is
programs/comp/reconstruction.json.
"""

from pathlib import Path
import importlib.util
import json
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'runtime' for p in HERE.parents
                            if (p/'runtime/paths.py').exists())))
from paths import ROOT, COMPILER, PROGRAMS, BUILD, IMAGES
import build
from build import job, environment
from corpus import BASE, read_words, sha
from recover import LONG, SHORT
from libmatch import load_symbols, operand

spec = importlib.util.spec_from_file_location('morebuild', PROGRAMS/'more/build.py')
more = importlib.util.module_from_spec(spec)
spec.loader.exec_module(more)

ORIGINAL = IMAGES/'4001/0315-comp.bin'
ZONES = 8
LIBPAS = ['p_mi.madlen', 'p_wc.madlen', 'p_a6.madlen', 'p_star.madlen']
# Modules taken from the image. E6365B and E6602B are the zero commons in
# front of the page-aligned reader buffers: 1024 words for the zone read by
# Э70 and two words of reader state, padded to the next page boundary. The
# padding is inferred from the placement; the original sizes are not known.
# Modules taken from the image. 'subp' lists the external names in the
# order the module declares them: the loader appends a module's references to
# its queue in that order, which fixes where the modules after it are placed.
# 'externals' maps an original address to the expression that replaces it.
READER = {0o10454: 'STOP*', 0o14002: 'COZYTISO', 0o14056: 'DRUMTAP*'}
HELPERS = [
    dict(name='E6365', start=0o6365, end=0o6502, entries={0o6444: 'E6444'},
         data=[(0o6456, 0o6502)], subp=['E6365B', 'COZYTISO', 'DRUMTAP*', 'STOP*'],
         externals={**READER, 0o12000: 'E6365B+1123B', 0o14000: 'E6365B+3123B'},
         commons={'E6365B': 0o3125}),
    dict(name='P/31', start=0o6600, end=0o6602),
    dict(name='E6602', start=0o6602, end=0o6717, entries={0o6661: 'E6661'},
         data=[(0o6673, 0o6717)], subp=['E6602B', 'COZYTISO', 'DRUMTAP*', 'STOP*'],
         externals={**READER, 0o16000: 'E6602B+1666B', 0o20000: 'E6602B+3666B'},
         commons={'E6602B': 0o3670}),
    dict(name='P/EQ', start=0o6724, end=0o6743, entries={0o6731: 'P/GE'}),
    # Monitor-80 permanent-library modules in the version linked into COMP;
    # the system library of dispak has other versions of these. COZYTISO and
    # CLEARLEX are the same and are left to the permanent library.
    dict(name='DRUMTAP*', start=0o14056, end=0o14076, subp=['CHKWORD*', 'PRINT8'],
         externals={0o20543: 'CHKWORD*', 0o20544: 'PRINT8', 0o20546: 'PRINT8+2B'},
         commons={'CHKWORD*': 1}),
    dict(name='MONREAD*', start=0o20453, end=0o20543,
         entries={0o20530: 'READ*ERR'}, data=[(0o20525, 0o20530), (0o20534, 0o20543)],
         subp=['STOP*', 'CLEARLEX', 'DRUMTAP*', 'COZYTISO', 'PRINT8'],
         externals={0o10454: 'STOP*', 0o14002: 'COZYTISO', 0o14056: 'DRUMTAP*',
                    0o20613: 'CLEARLEX', 0o20546: 'PRINT8+2B'}),
    # The loader puts DRUMTAP*'s common CHKWORD* (20543) after MONREAD*.
    dict(name='PRINT8', start=0o20544, end=0o20551, data=[(0o20544, 0o20546)],
         subp=['STOP*', 'LUN*MON'],
         externals={0o10454: 'STOP*', 0o20630: 'LUN*MON+3B'}),
    dict(name='LUN*MON', start=0o20625, end=0o21047,
         data=[(0o20625, 0o20626), (0o20717, 0o20734), (0o20762, 0o20767)],
         externals={0o10455: 'MONOUT', 0o21047: 'TSTATE*'}, commons={'TSTATE*': 1}),
]
# SUBP declaration order of recovered modules where it decides placement
# (first names; the rest keep their order). SPACE* in P/SYS is inferred from
# the position of PASCHARS.
ORDER = {
    'P/SYS': ['STOP*', 'MONOUT', 'MONIN', 'P/PRINT', 'SPACE*', 'P/PUTERR'],
    'PASPMD': ['P/WXD', 'P/WR'],
    'P/WR': ['PASPERID', 'P/TR', 'P/A7'],
}
# The only words that differ from the original.
RESIDUES = {
    0o2010: 'left half of the PASCODER descriptor: a loader value of the build',
    0o2202: 'RDBUF operand order: compiler version',
    0o2203: 'RDBUF operand order: compiler version',
}
HEADER = '''user 419900зс5^
dis 31(2113)32(77)33(2148-440)34(2048)37(3777-wr)66(3776-wr)^
eeb1a3
*name
'''


def helper(words, name, start, end, entries={}, data=[], subp=[], externals={},
           commons={}):
    """Madlen for one module taken from the image, with relocatable labels."""
    def arg(value):
        if value in externals:
            return externals[value]
        if start <= value < end:
            targets.add(value)
            return f'X{value:05o}'
        return f'{value:o}B' if value else ''

    def insn(half):
        reg, op, value, long = operand(half)
        if long:
            # Madlen rejects VJM without a register; Z31 is the raw opcode.
            mnemonic = 'Z31' if op == 0o31 and not reg else LONG[op]
        else:
            mnemonic = SHORT[op] if op < len(SHORT) else f'*{op:o}'
        reloc = long or (reg == 0 and (op <= 0o27 or op in (0o64, 0o70, 0o71)))
        text = arg(value) if reloc else (f'{value:o}B' if value else '')
        return f'{reg if reg else ""},{mnemonic},{text}'

    targets = set(entries) | {start}
    body = []
    for address in range(start, end):
        w = words[address-BASE]
        if any(lo <= address < hi for lo, hi in data):
            body.append((address, [f',LOG,{w:016o}']))
            continue
        left, right = w >> 24, w & 0xffffff
        lines = [insn(left)]
        reg, op, _, long = operand(left)
        aligns = (long and op in (0o30, 0o31)) or (not long and op >= 0o50 and op != 0o60)
        if aligns and right == 0o2200000:
            # Madlen supplies the filler; label the next word to keep it aligned.
            targets.add(address+1)
        else:
            lines.append(insn(right))
        body.append((address, lines))
    names = list(subp)
    for e in [*externals.values(), *commons]:
        e = e.split('+')[0]
        if e not in names:
            names.append(e)
    out = [f' {name}:,NAME,']
    out += [f' {n}:,LC,{commons[n]:o}B' if n in commons else f' {n}:,SUBP,'
            for n in names]
    for address, lines in body:
        if address in entries:
            out.append(f' {entries[address]}:,ENTRY,')
        label = f' X{address:05o}:' if address in targets else ' '
        out.append(label+lines[0])
        out += [' '+line for line in lines[1:]]
    out.append(' ,END,')
    return '\n'.join(out)+'\n'


def reorder(source):
    """Apply ORDER to the SUBP lists of the modules in source."""
    lines = source.split('\n')
    for module, first in ORDER.items():
        start = lines.index(f' {module}:,NAME,')+1
        end = start
        while lines[end].endswith(',SUBP,'):
            end += 1
        subp = [line[1:-len(':,SUBP,')] for line in lines[start:end]]
        subp = first+[n for n in subp if n not in first]
        lines[start:end] = [f' {n}:,SUBP,' for n in subp]
    return '\n'.join(lines)


def libpas():
    # Copies of besm6/mesm6 toolchain/libpas (dtran /01.06.84/ sources).
    return ''.join((HERE/'libpas'/name).read_text() for name in LIBPAS)


def library_sources():
    words = read_words(ORIGINAL)
    text = reorder(more.runtime_sources())
    # MORE takes P/STAR from COMP's words; libpas has the same 10 words.
    start = text.index(' P/STAR:,NAME,\n')
    end = text.index(' ,END,\n', start)+len(' ,END,\n')
    text = text[:start]+text[end:]
    # In COMP, PASPMDAD is a one-word common placed by PASPMD, not a word of
    # P/HT; P/HT keeps its last word unused.
    for old, new in [(':14,VTM,R03532', ':14,VTM,PASPMDAD'),
                     (' PASPMDAD:,ENTRY,\n', ''),
                     (' P/HT:,NAME,\n', ' P/HT:,NAME,\n PASPMDAD:,LC,1\n'),
                     (' PASPMDAD:,SUBP,\n', ''),
                     (' PASPMD:,NAME,\n', ' PASPMD:,NAME,\n PASPMDAD:,LC,1\n'),
                     # COMP calls the Monitor's own P/EO; MORE's P/EL/P/EO
                     # renaming does not apply.
                     (' P/EO:,ENTRY,\n 9,VTM,*TTIO*+26B', ' 9,VTM,*TTIO*+26B'),
                     (' P/EL:,ENTRY,', ' P/EO:,ENTRY,')]:
        if text.count(old) != 1:
            raise ValueError('unexpected runtime source: '+old)
        text = text.replace(old, new)
    text += libpas()
    text += ''.join(helper(words, **h) for h in HELPERS)
    return text


def compare(image, listing):
    original = read_words(ORIGINAL)
    rebuilt = read_words(image)
    symbols = sorted((s.address, s.name) for s in load_symbols(listing))

    def owner(address):
        best = '?'
        for a, n in symbols:
            if a <= address:
                best = n
        return best

    diffs = [a for a in range(BASE, BASE+len(original))
             if original[a-BASE] != rebuilt[a-BASE]]
    runs = []
    for a in diffs:
        if runs and a-runs[-1][1] <= 2:
            runs[-1][1] = a
        else:
            runs.append([a, a])
    for lo, hi in runs:
        print(f'{lo:05o}-{hi:05o} {hi-lo+1:4} {owner(lo)}')
    report = []
    for a in diffs:
        o, r = original[a-BASE], rebuilt[a-BASE]
        report.append(dict(word=f'{a:05o}', original=f'{o:016o}', rebuilt=f'{r:016o}',
                           cause=RESIDUES.get(a, 'unexplained')))
    # The descriptor's right half (FREE) must agree; only its left half is
    # the loader's own value.
    if (sorted(diffs) != sorted(RESIDUES) or
            original[0o2010-BASE] & 0xffffff != rebuilt[0o2010-BASE] & 0xffffff):
        raise ValueError('rebuilt COMP differs beyond the known residues')
    return report


def main():
    work = BUILD/'comp'
    work.mkdir(parents=True, exist_ok=True)
    build.HEADER = HEADER
    compiler = more.rebuild_compiler(work)
    sources = library_sources()
    (work/'runtime.madlen').write_text(sources)
    job(work, 'library', '*call ficmemory\n*assem\n'+sources+
        '*to perso:660100\n*end file\n``````\nеконец\n')
    (work/'3777').write_bytes(b'')
    cards = '*libra:13\n*call ficmemory\n*trans:newpasc,,320000\n'
    cards += (ROOT/'comp.pas').read_text()+'\n'
    # PASCODER (the 10-word image writer) is in the standard PERSO 311160.
    cards += '*perso:311160,cont\n*perso:320200,cont\n*perso:660100,cont\n'
    cards += (f'*table:p/coder(w*370250,l*{ZONES:o})\n*main pascoder\n'
              '*execute\n*end file\n``````\nеконец\n')
    listing = job(work, 'comp', cards)
    if re.search(r'\bIN\s+\d+\s+LINES\s+[1-9]\d*\s+ERRORS', listing.read_text()):
        raise ValueError('Pascal compilation failed; see '+str(listing))
    image = work/'comp.img'
    subprocess.run(['besmtool', 'dump', '3777', '--start=0250', f'--length={ZONES}',
                    '--to-file='+str(image)], env=environment(work), check=True,
                   stdout=subprocess.DEVNULL)
    data = image.read_bytes()
    image.write_bytes(data+bytes(ZONES*6144-len(data)))
    residues = compare(image, listing)
    report = dict(image=str(image.relative_to(ROOT)), image_sha256=sha(image.read_bytes()),
                  original=str(ORIGINAL.relative_to(ROOT)),
                  original_sha256=sha(ORIGINAL.read_bytes()),
                  source_sha256={str(p.relative_to(ROOT)): sha(p.read_bytes())
                                 for p in (ROOT/'comp.pas', COMPILER/'mypas.b6', HERE/'build.py')},
                  compared=['02000', f'{BASE+ZONES*1024-1:05o}'],
                  identical_words=ZONES*1024-len(residues), residues=residues,
                  compiler=compiler)
    (HERE/'reconstruction.json').write_text(json.dumps(report, indent=2)+'\n')
    print(image, f'{len(residues)} differing words, all known residues')


if __name__ == '__main__':
    main()
