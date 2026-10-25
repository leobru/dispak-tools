#!/usr/bin/env python3
"""Rebuild the Pascal part of МОНИТР (volume 4001 zones 0002-0010) and compare it.

Usage: python3 runtime/monitr/build.py [--explore] [--source file.pas]

monitr.pas is compiled with mypas.b6 rebuilt on a private volume 77 and linked
with a private PERSO library: BOX's Monitor runtime and the file-access bundles,
with the extra public entries МОНИТР calls, and four small services taken from
the image words. PASCODER dumps the seven zones from 02000; they are compared
word by word with runtime/images/4001/0002-monitr-pascal.bin. Only the loader
value in 02010.L and the memory above FREE (07432) may differ: the original
image was written with whatever the previous jobs had left there.
--explore records differences instead of rejecting them. Artifacts are kept
under runtime/build/monitr; no original volume is written.
"""
from pathlib import Path
import argparse
import importlib.util
import json
import os
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from corpus import BASE, ROOT, pack, read_words, sha, find_volume, volume_words
import build
from build import job, environment
from libmatch import load_symbols

spec = importlib.util.spec_from_file_location('boxbuild', HERE.parent/'box/build.py')
box = importlib.util.module_from_spec(spec)
spec.loader.exec_module(box)
comp = box.comp
ORIGINAL = HERE.parent/'images/4001/0002-monitr-pascal.bin'
WORK = HERE.parent/'build/monitr'
UNIT, ZONE, ZONES = 0o44, 0o2, 7
FREE = 0o7432
# Public entries of the file-access bundles that МОНИТР calls, as word
# offsets from the bundle start. The names other than those of the volume
# 4001 include deck (LIB, DLIB, OPENF, MAKEF, CLOSEF, DELF, MKNAME) and COPY
# (FIRSTF, NEXTF) are invented.
ENTRIES = {
    'DBFILE': {0o0: 'LIB', 0o20: 'DLIB', 0o173: 'SETDESCR', 0o174: 'RUN',
               0o222: 'MAKEF', 0o340: 'CLOSEF', 0o366: 'DELF', 0o412: 'RENAMEF'},
    'DBNAME': {0o0: 'FIRSTF', 0o142: 'NEXTF'},
    'DBCORE': {0o27: 'SETBUF', 0o137: 'KOI8'},
}
# Services that have no recovered source, taken from the image words. DBTOM
# (a bundle with base 06164 in M10, like DBFILE's) mounts and releases
# volumes; DBLINK stores the caller's return address in cell 5. The module
# names are invented.
DB = {0o7101: 'DBENTER', 0o7106: 'DBLEAVE', 0o7115: 'DBPASC+14B',
      0o7116: 'DBPASC+15B', 0o7126: 'DBPASC+25B', 0o6430: 'DBCORE+112B',
      0o6434: 'DBCORE+116B', 0o6442: 'DBCORE+124B', 0o7143: 'MONOUT'}
HELPERS = [
    dict(name='DBTOM', start=0o6164, end=0o6306,
         entries={0o6173: 'DOZAK', 0o6271: 'OTKAZ', 0o6274: 'MONTOM'},
         data=[(0o6256, 0o6271)], subp=['DBENTER', 'DBLEAVE', 'DBPASC', 'DBCORE',
                                         'MONOUT'], externals=DB),
    dict(name='DBLINK', start=0o7050, end=0o7054, entries={0o7051: 'SVJAZ'},
         data=[(0o7050, 0o7051), (0o7053, 0o7054)]),
]
# Addresses in 02000-07431 that may differ, with their causes.
RESIDUES = {
    0o2010: 'left half of the PASCODER descriptor: a loader value of the build',
}
REGIONS = [('code', 0o2012, 0o4101), ('constants', 0o4101, 0o4325),
           ('globals_and_files', 0o4325, 0o4545), ('runtime', 0o4545, FREE)]


def card_offsets(lines):
    """Word offset of each instruction card of a Madlen module, as Madlen packs it."""
    pos, out = 0, {}
    for i, line in enumerate(lines):
        m = re.match(r'^ ?([^ ,:]*:)?([^,]*),([^,]*),(.*)$', line)
        if line.startswith('C') or not m:
            continue
        label, _, op, arg = m.groups()
        op = op.strip()
        if op in ('NAME', 'SUBP', 'LC', 'ENTRY', 'END'):
            continue
        if label and pos % 2:
            pos += 1
        if op in ('LOG', 'ISO', 'GOST', 'BSS'):
            pos += pos % 2
            out[i] = pos
            pos += 2*(int(arg.rstrip('B'), 8 if arg.endswith('B') else 10)
                      if op == 'BSS' else 1)
            continue
        out[i] = pos
        pos += 1
        # Madlen ends the word after a jump, call or extracode in a left half.
        if pos % 2 and (op in ('UJ', 'VJM', 'Z31') or re.fullmatch(r'\*[5-7][0-7]', op)):
            pos += 1
    return out


def add_entries(text, module, entries):
    start = text.index(f' {module}:,NAME,\n')
    end = text.index(' ,END,\n', start)
    lines = text[start:end].split('\n')
    at = {pos//2: i for i, pos in card_offsets(lines).items() if pos % 2 == 0}
    for offset, name in sorted(entries.items(), reverse=True):
        if offset not in at:
            raise ValueError(f'{module}+{offset:o} is not a word start')
        lines.insert(at[offset], f' {name}:,ENTRY,')
    return text[:start]+'\n'.join(lines)+text[end:]


def library_sources():
    text = box.library_sources()
    # МОНИТР names its EOLN entry P/EL and its EOF entry P/EO, as the
    # compiler does; COMP's renaming (inherited through MTD and BOX) is undone.
    for old, new in [(' P/EO:,ENTRY,', ' P/EL:,ENTRY,'),
                     (' 9,VTM,*TTIO*+26B', ' P/EO:,ENTRY,\n 9,VTM,*TTIO*+26B')]:
        if text.count(old) != 1:
            raise ValueError('unexpected runtime source: '+old)
        text = text.replace(old, new)
    # МОНИТР has COMP's later converter tables and the MONIN extension that
    # MTD's profile lacks.
    cw = read_words(comp.ORIGINAL)
    extension = ''.join(f' ,LOG,{w:016o}\n' for w in cw[0o10606-BASE:0o10616-BASE])
    for old, new in [('0401053141407416', '0401053141407417'),
                     ('0705613303607417', '0705613303607416'),
                     (' R03314:,LOG,0000000000000377\n',
                      extension+' R03314:,LOG,0000000000000377\n'),
                     # P/WI is loaded before P/HT.
                     (' P/ER:,NAME,\n P/HT:,SUBP,\n P/PRINT:,SUBP,\n P/WI:,SUBP,\n',
                      ' P/ER:,NAME,\n P/PRINT:,SUBP,\n P/WI:,SUBP,\n P/HT:,SUBP,\n')]:
        if text.count(old) != 1:
            raise ValueError('unexpected runtime source: '+old)
        text = text.replace(old, new)
    for module, entries in ENTRIES.items():
        text = add_entries(text, module, entries)
    words = read_words(ORIGINAL)
    text += ''.join(comp.helper(words, **h) for h in HELPERS)
    return text


def compare(image):
    ref, actual = read_words(ORIGINAL), read_words(image)
    full = []
    for a in range(BASE, BASE+len(ref)):
        if ref[a-BASE] == actual[a-BASE]:
            continue
        if a in RESIDUES:
            cause = RESIDUES[a]
        elif a >= FREE:
            cause = 'memory above FREE at the time of the original dump'
        else:
            cause = 'unexplained'
        full.append(dict(word=f'{a:05o}', original=f'{ref[a-BASE]:016o}',
                         rebuilt=f'{actual[a-BASE]:016o}', cause=cause))
    regions = []
    for name, lo, hi in REGIONS:
        equal = sum(ref[a-BASE] == actual[a-BASE] for a in range(lo, hi))
        regions.append(dict(name=name, range=[f'{lo:05o}', f'{hi-1:05o}'],
                            words=hi-lo, identical_words=equal,
                            bit_identical=equal == hi-lo))
    above = sum(ref[a-BASE] != 0 for a in range(FREE, BASE+len(ref)))
    unexplained = [d for d in full if d['cause'] == 'unexplained']
    free_ok = ref[0o2010-BASE] & 0o77777777 == actual[0o2010-BASE] & 0o77777777
    return dict(full_image_words=len(ref),
                identical_words_below_free=FREE-BASE-sum(int(d['word'], 8) < FREE
                                                         for d in full),
                differences_below_free=[d for d in full if int(d['word'], 8) < FREE],
                nonzero_original_words_above_free=above,
                rebuilt_words_above_free_nonzero=sum(actual[a-BASE] != 0 for a in
                                                     range(FREE, BASE+len(ref))),
                unexplained_differences=len(unexplained), regions=regions,
                free_matches=free_ok)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--explore', action='store_true')
    parser.add_argument('--source', type=Path, default=HERE/'monitr.pas')
    args = parser.parse_args()
    args.source = args.source.resolve()
    for number, line in enumerate(args.source.read_text().splitlines(), 1):
        if len(line) > 72:
            raise ValueError(f'{args.source}:{number}: exceeds 72-column source card')
    WORK.mkdir(parents=True, exist_ok=True)
    original_disk = find_volume()
    raw, disk = volume_words(original_disk)
    expected = json.loads((HERE.parent/'corpus.json').read_text())['volume']['sha256']
    if sha(raw) != expected:
        raise ValueError('volume 4001 differs from the cataloged reference')
    if pack(disk[ZONE*1024:(ZONE+ZONES)*1024]) != ORIGINAL.read_bytes():
        raise ValueError('reference differs from the source volume: '+str(ORIGINAL))
    box.references(original_disk, disk)
    search = os.environ.get('BESM6_PATH', f'{Path.home()}/.besm6:/usr/local/share/besm6')
    installed77 = next(Path(d)/'77' for d in search.split(':')
                       if (Path(d)/'77').is_file() and
                       (Path(d)/'77').resolve() != (WORK/'77').resolve())
    installed77_hash = sha(installed77.read_bytes())
    # Reuse the private-compiler build; cache only while mypas.b6 is unchanged.
    stamp = WORK/'compiler.json'
    compiler_hash = sha((ROOT/'mypas.b6').read_bytes())
    compiler = json.loads(stamp.read_text()) if stamp.exists() else {}
    if compiler.get('source_sha256') != compiler_hash or not (WORK/'77').exists():
        compiler = comp.more.rebuild_compiler(WORK)
        stamp.write_text(json.dumps(compiler, indent=2)+'\n')
    sources = library_sources()
    lib = WORK/'runtime.madlen'
    if not lib.exists() or lib.read_text() != sources or not (WORK/'3776').exists():
        lib.write_text(sources)
        job(WORK, 'library', '*call ficmemory\n*assem\n'+sources +
            '*to perso:670100\n*end file\n``````\nеконец\n')
    (WORK/'3777').write_bytes(b'')
    header = comp.helper(read_words(ORIGINAL), 'P/BOOT', BASE, 0o2007,
                         data=[(0o2003, 0o2004), (0o2006, 0o2007)],
                         externals={0o2007: 'P/CODER', 0o2012: 'PROGRAM'})
    header = header.replace(' P/BOOT:,NAME,', ' P/BOOT:,NAME,\n'
                            ' P/1D:,LC,75B\n *INPUT*:,LC,36B\n *OUTPUT*:,LC,36B')
    # Assemble P/BOOT after PERSO selection so its LC declaration order wins.
    cards = '*libra:13\n*call ficmemory\n*trans:newpasc,,320000\n'
    cards += args.source.read_text()+'\n'
    cards += '*perso:311160,cont\n*perso:320200,cont\n*perso:670100,cont\n'
    cards += '*assem\n'+header
    cards += (f'*table:p/coder(w*{UNIT:o}{ZONE:04o},l*{ZONES})\n*main pascoder\n'
              '*execute\n*end file\n``````\nеконец\n')
    # The exchange word in 02007 names the drive: the original was written
    # to drive 044, so the private volume is mounted there for this job.
    header = build.HEADER
    if header.count('66(3777-wr)') != 1:
        raise ValueError('unexpected job header')
    build.HEADER = header.replace('66(3777-wr)', f'{UNIT:o}(3777-wr)')
    try:
        listing = job(WORK, 'monitr', cards)
    finally:
        build.HEADER = header
    if re.search(r'\bIN\s+\d+\s+LINES\s+[1-9]\d*\s+ERRORS', listing.read_text()):
        raise ValueError('Pascal compilation failed; see '+str(listing))
    image = WORK/'monitr.img'
    image.unlink(missing_ok=True)
    subprocess.run(['besmtool', 'dump', '3777', f'--start=0{ZONE:o}',
                    f'--length={ZONES}', '--to-file='+str(image)],
                   env=environment(WORK), check=True, stdout=subprocess.DEVNULL)
    data = image.read_bytes()
    if len(data) > ZONES*6144 or len(data) % 6:
        raise ValueError('rebuilt МОНИТР does not fit its seven zones')
    # PASCODER writes up to FREE; the catalog extent is seven zones.
    data += bytes(ZONES*6144-len(data))
    image.write_bytes(data)
    report = compare(image)
    symbols = {s.name: f'{s.address:05o}' for s in load_symbols(listing)}
    if sha(original_disk.read_bytes()) != sha(raw):
        raise ValueError('original volume changed')
    if sha(installed77.read_bytes()) != installed77_hash:
        raise ValueError('installed volume 77 changed')
    report.update(source=str(args.source.relative_to(ROOT)),
                  source_sha256=sha(args.source.read_bytes()), compiler=compiler,
                  build_source_sha256={str(p.relative_to(ROOT)): sha(p.read_bytes()) for p in
                                       [HERE/'build.py', box.HERE/'build.py',
                                        box.mtd.HERE/'build.py', comp.HERE/'build.py',
                                        comp.more.HERE/'build.py']},
                  library_source_sha256=sha(sources.encode()),
                  image=str(image.relative_to(ROOT)), image_sha256=sha(data),
                  original=str(ORIGINAL.relative_to(ROOT)),
                  original_zones=[f'{ZONE:04o}', f'{ZONE+ZONES-1:04o}'],
                  original_sha256=sha(ORIGINAL.read_bytes()),
                  original_volume_sha256=sha(raw), original_volume_unchanged=True,
                  installed_volume77_sha256=installed77_hash,
                  installed_volume77_unchanged=True, symbols=symbols,
                  interactive_execution=False)
    (WORK/'reconstruction.json').write_text(json.dumps(report, indent=2,
                                                       ensure_ascii=False)+'\n')
    below = report['differences_below_free']
    print(f'{len(below)} differing words below FREE, '
          f'{report["unexplained_differences"]} unexplained')
    if not args.explore and (report['unexplained_differences'] or
                             not report['free_matches']):
        raise ValueError('image differs beyond the residues; see '
                         'runtime/build/monitr/reconstruction.json')
    if not args.explore:
        (HERE/'reconstruction.json').write_text(json.dumps(report, indent=2,
                                                           ensure_ascii=False)+'\n')


if __name__ == '__main__':
    main()
