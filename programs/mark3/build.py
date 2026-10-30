#!/usr/bin/env python3
"""Rebuild MARK3 (2113/1243-1245) on private disks and compare it with the original.

Usage: python3 programs/mark3/build.py [--explore] [--source file.pas]

The job is the original one: inp.bemsh is assembled by BEMSH, mark3.pas
is compiled by NEWPASC of mypas.b6 rebuilt on a private volume 77 (the
original job called it as *PASCOM through the catalog of 77), and
both are linked with the standard library of volume 2113 (PERSO 311160,
320100); PASCODER writes three zones from 02000 to a scratch disk. The
original is dumped read-only from volume 2113 into build/mark3/original.bin.
The two images are compared word by word; --explore records the
differences instead of rejecting them. Artifacts are kept under
build/mark3. No original volume is written.
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
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import ROOT, COMPILER, PROGRAMS, BUILD
from corpus import BASE, read_words, sha
import build
from build import job, environment
from libmatch import load_symbols

spec = importlib.util.spec_from_file_location('morebuild', PROGRAMS/'more/build.py')
more = importlib.util.module_from_spec(spec)
spec.loader.exec_module(more)

WORK = BUILD/'mark3'
ORIGINAL = WORK/'original.bin'
VOLUME, ZONE, ZONES = '2113', 0o1243, 3
SCRATCH = 0o421
# The original link: the standard library, written by PASCODER to zone 0421
# of drive 67, the scratch disk 3777.
LINK = '''*no li
*assem
*stand
*perso:311160,cont
*perso:320100,cont
*table:p/coder(w*670421,l*3)
*main pascoder
*execute
*end file
``````
еконец
'''


def volume(name):
    search = os.environ.get('BESM6_PATH', f'{Path.home()}/.besm6:/usr/local/share/besm6')
    return next(Path(d)/name for d in search.split(':')
                if (Path(d)/name).is_file() and (Path(d)/name).resolve() !=
                (WORK/name).resolve())


def reference(source):
    """Dump the original from the volume (read-only)."""
    WORK.mkdir(parents=True, exist_ok=True)
    subprocess.run(['besmtool', 'dump', VOLUME, f'--start=0{ZONE:o}',
                    f'--length={ZONES}', '--to-file='+str(ORIGINAL)],
                   env=dict(os.environ, BESM6_PATH=str(source.parent)),
                   check=True, stdout=subprocess.DEVNULL)


def cause(a, symbols):
    """Why the word at a differs, or None if that is not known."""
    if a < symbols['PROGRAM']:
        return 'PASCODER stub (exchange words, zone count) of the other library version'
    if symbols['P/1D'] <= a < symbols['P/1D'] + 0o50:
        return 'P/1D library constants of the other library version'
    if a >= symbols['P/2']:
        return 'library code and memory above it: other library version'
    return None


def compare(image, listing):
    ref, new = read_words(ORIGINAL), read_words(image)
    symbols = {s.name: s.address for s in load_symbols(listing)}
    pool = (new[symbols['PROGRAM']-BASE] >> 24) & 0o77777
    bounds = [('stub', BASE, symbols['PROGRAM']), ('code', symbols['PROGRAM'], pool),
              ('constants', pool, symbols['P/1D']),
              ('globals_and_files', symbols['P/1D'], symbols['P/2']),
              ('library', symbols['P/2'], symbols['FREE']),
              ('above_free', symbols['FREE'], BASE+len(ref))]
    regions = []
    for name, lo, hi in bounds:
        same = sum(ref[a-BASE] == new[a-BASE] for a in range(lo, hi))
        regions.append(dict(name=name, range=[f'{lo:05o}', f'{hi-1:05o}'],
                            words=hi-lo, identical_words=same,
                            bit_identical=same == hi-lo))
    differences, unexplained = [], []
    for k, (a, b) in enumerate(zip(ref, new)):
        if a == b:
            continue
        why = cause(BASE+k, symbols)
        differences.append(dict(word=f'{BASE+k:05o}', original=f'{a:016o}',
                                rebuilt=f'{b:016o}', cause=why or 'unexplained'))
        if why is None:
            unexplained.append(differences[-1])
    application = [d for d in differences if int(d['word'], 8) < symbols['P/2']
                   and 'library' not in d['cause']]
    return dict(placement={n: f'{symbols[n]:05o}' for n in
                           ('PROGRAM', 'P/1D', '*OUTPUT*', 'P/2', 'FREE')},
                rebuilt_pool=f'{pool:05o}', regions=regions,
                image_words=len(ref), identical_words=len(ref)-len(differences),
                different_words=len(differences),
                application_differences=len(application),
                unexplained_differences=len(unexplained), differences=differences)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--explore', action='store_true')
    parser.add_argument('--source', type=Path, default=HERE/'mark3.pas')
    args = parser.parse_args()
    args.source = args.source.resolve()
    for number, line in enumerate(args.source.read_text().splitlines(), 1):
        if len(line) > 72:
            raise ValueError(f'{args.source}:{number}: exceeds 72-column source card')
    source_volume = volume(VOLUME)
    volume_hash = sha(source_volume.read_bytes())
    reference(source_volume)
    installed77 = volume('77')
    installed77_hash = sha(installed77.read_bytes())
    # Reuse the private-compiler build; cache only while mypas.b6 is unchanged.
    stamp = WORK/'compiler.json'
    compiler_hash = sha((COMPILER/'mypas.b6').read_bytes())
    compiler = json.loads(stamp.read_text()) if stamp.exists() else {}
    if compiler.get('source_sha256') != compiler_hash or not (WORK/'77').exists():
        compiler = more.rebuild_compiler(WORK)
        stamp.write_text(json.dumps(compiler, indent=2)+'\n')
    (WORK/'3777').write_bytes(b'')
    cards = ('*bemsh\n' + (HERE/'inp.bemsh').read_text() +
             '*libra:13\n*call ficmemory\n*trans:newpasc,,320000\n' +
             args.source.read_text() + '\n' + LINK)
    header = build.HEADER
    build.HEADER = header.replace('66(3777-wr)67(3776-wr)', '67(3777-wr)')
    try:
        listing = job(WORK, 'mark3', cards)
    finally:
        build.HEADER = header
    if re.search(r'\bIN\s+\d+\s+LINES\s+[1-9]\d*\s+ERRORS', listing.read_text()):
        raise ValueError('Pascal compilation failed; see '+str(listing))
    image = WORK/'mark3.img'
    image.unlink(missing_ok=True)
    subprocess.run(['besmtool', 'dump', '3777', f'--start=0{SCRATCH:o}',
                    f'--length={ZONES}', '--to-file='+str(image)],
                   env=environment(WORK), check=True,
                   stdout=subprocess.DEVNULL)
    # The scratch disk ends after the last zone written; the rest is zero.
    data = image.read_bytes()
    if len(data) > ZONES*6144 or len(data) % 6:
        raise ValueError('rebuilt MARK3 does not fit its three-zone extent')
    image.write_bytes(data + bytes(ZONES*6144 - len(data)))
    report = compare(image, listing)
    if sha(source_volume.read_bytes()) != volume_hash:
        raise ValueError(f'volume {VOLUME} changed')
    if sha(installed77.read_bytes()) != installed77_hash:
        raise ValueError('installed volume 77 changed')
    report.update(source=str(args.source.relative_to(ROOT) if
                             args.source.is_relative_to(ROOT) else args.source),
                  source_sha256=sha(args.source.read_bytes()), compiler=compiler,
                  build_source_sha256={str(p.relative_to(ROOT)): sha(p.read_bytes())
                                       for p in (HERE/'build.py', HERE/'inp.bemsh',
                                                 more.HERE/'build.py')},
                  image=str(image.relative_to(ROOT)),
                  image_sha256=sha(image.read_bytes()),
                  original=str(ORIGINAL.relative_to(ROOT)),
                  original_zones=[f'{ZONE:04o}', f'{ZONE+ZONES-1:04o}'],
                  original_sha256=sha(ORIGINAL.read_bytes()),
                  original_volume_sha256=volume_hash, original_volume_unchanged=True,
                  installed_volume77_sha256=installed77_hash,
                  installed_volume77_unchanged=True, execution=False)
    (WORK/'reconstruction.json').write_text(json.dumps(report, indent=2)+'\n')
    print(' '.join(f'{r["name"]} {r["identical_words"]}/{r["words"]}'
                   for r in report['regions']))
    print(f'{report["application_differences"]} application words differ, '
          f'{report["unexplained_differences"]} differences unexplained')
    if not args.explore:
        if report['unexplained_differences']:
            raise ValueError('image differs; see build/mark3/reconstruction.json')
        (HERE/'reconstruction.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
