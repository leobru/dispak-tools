#!/usr/bin/env python3
"""Build Pascal image with *PASCAL or NEWPASC, using private writable disks.

Usage: python3 programs/pak/build.py pak.pas [--compiler pascal|newpasc]
       [--compiler-source compiler/mypas.b6 [--compiler-profile pak-2113]]
A source name without a directory is taken from programs/pak. The work
directory is build/pak/STEM-COMPILER.
"""
import argparse
import os
from pathlib import Path
import subprocess
import re
import hashlib
import json
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import BUILD
from pak_symbols import load_symbols
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('source', type=Path)
p.add_argument('--compiler', choices=['pascal', 'newpasc'], default='pascal')
p.add_argument('--compiler-profile',choices=['pak-2113'],help='use historical CARD instruction')
p.add_argument('--compiler-source',type=Path,help='rebuild NEWPASC privately from mypas.b6')
p.add_argument('--perso', nargs='+', default=['311160'],
               help='octal library addresses, in loader search order')
a = p.parse_args()
if not a.source.exists() and (HERE / a.source).exists():
    a.source = HERE / a.source
if a.compiler_profile and not a.compiler_source:
    p.error('--compiler-profile requires --compiler-source')
if any(len(value) != 6 or any(c not in '01234567' for c in value)
       for value in a.perso):
    p.error('--perso requires six-digit octal library addresses')
work = BUILD / 'pak' / (a.source.stem + '-' + a.compiler)
work.mkdir(parents=True, exist_ok=True)
(work / 'image.bin').unlink(missing_ok=True)
(work / 'home').mkdir(exist_ok=True)
(work / '3777').write_bytes(b'')
env = dict(os.environ, HOME=str(work / 'home'), BESM6_PATH=str(work) + ':' +
           os.environ.get('BESM6_PATH', f'{Path.home()}/.besm6:/usr/local/share/besm6'))
if a.compiler_source:
    if a.compiler!='newpasc': p.error('--compiler-source requires --compiler newpasc')
    target=work/'77'
    installed=next(Path(d)/'77' for d in env['BESM6_PATH'].split(':')
                   if (Path(d)/'77').is_file() and (Path(d)/'77')!=target)
    raw=installed.read_bytes()
    target.write_bytes(raw)
    compiler_text=a.compiler_source.read_text()
    original_compiler=compiler_text
    if a.compiler_profile=='pak-2113':
        original='add2InsnsToBuf(KACX, KAEX+ZERO);'
        if compiler_text.count(original)!=1: raise ValueError('CARD generator changed')
        compiler_text=compiler_text.replace(original,'addInsnToBuf(KACX+ZERO);')
    prefix,marker,_=compiler_text.partition('*end record\n')
    if not marker: raise ValueError('Compiler source has no overlay terminator')
    deck=work/'compiler.b6'
    deck.write_text(prefix+marker+'*call ocatalog:670000\n*system\n'
                    '*end file\n``````\nЕКОНЕЦ\n')
    with (work/'compiler-listing.txt').open('w') as out:
        result=subprocess.run(['dispak','-l',str(deck)],env=env,
                              stdout=out,stderr=subprocess.STDOUT,timeout=180)
    listing=(work/'compiler-listing.txt').read_text(encoding='utf-8-sig')
    if (result.returncode or 'LINES STRUCTURE' not in listing or
        re.search(r'IN\s+\d+\s+LINES\s+[1-9]\d*\s+ERRORS',listing)):
        raise SystemExit('Compiler rebuild failed; see '+str(work/'compiler-listing.txt'))
    if installed.read_bytes()!=raw: raise ValueError('Installed volume changed')
    (work/'compiler-provenance.json').write_text(json.dumps(dict(
        source=str(a.compiler_source), profile=a.compiler_profile,
        source_sha256=hashlib.sha256(original_compiler.encode()).hexdigest(),
        adapted_sha256=hashlib.sha256(compiler_text.encode()).hexdigest(),
        installed_volume_sha256=hashlib.sha256(raw).hexdigest(),
        installed_volume_unchanged=True),indent=2)+'\n')
compiler = '*pascal' if a.compiler == 'pascal' else '*trans:newpasc,,320000'
source = a.source.read_text()
pre = a.source.with_suffix('.pre')
prelude = pre.read_text() if pre.exists() else ''
loader = a.source.with_suffix('.loader.b6')
loader_source = loader.read_text() if loader.exists() else ''
if any(len(line) > 72 for line in source.splitlines()):
    raise ValueError('Source contains a card longer than 72 columns')
header = ('user 419900зс5^\n'
       'dis 31(2113)32(77)33(2148-440)34(2048)67(3777-wr)^\n'
       'eeb1a3\n*name\n')
if prelude or loader_source:
    library_job = header + prelude + loader_source + ('*to perso:670100\n'
                   '*end file\n``````\nеконец\n')
    (work / 'runtime-job.b6').write_text(library_job)
    with (work / 'runtime-listing.txt').open('w') as out:
        run = subprocess.run(['dispak', '-l', str(work / 'runtime-job.b6')],
                             env=env, stdout=out, stderr=subprocess.STDOUT,
                             timeout=60)
    runtime_listing = (work / 'runtime-listing.txt').read_text(encoding='utf-8-sig')
    errors = re.findall(r'ЧИ[CС]Л[OО]\s+[OО]ШИБ[^\n]*?([0-9]{4})', runtime_listing)
    if (run.returncode or not (work / '3777').stat().st_size or
            any(int(value) for value in errors) or
            re.search(r'^\s*\*{3,}', runtime_listing, re.M)):
        raise SystemExit('Runtime assembly failed; see ' + str(work / 'runtime-listing.txt'))
job = (header +
       '*libra:13\n*call ficmemory\n' + compiler + '\n' +
       source + '\n' + ''.join('*perso:' + addr + ',cont\n' for addr in a.perso) +
       ('*perso:670100,cont\n' if prelude or loader_source else '') +
       ('*table:p/coder(w*670315,l*04,s*01520)\n*main pakwrite\n'
        if loader_source else '*table:p/coder(w*670315,l*04)\n*main pascoder\n') +
       '*execute\n'
       '*end file\n``````\nеконец\n')
(work / 'job.b6').write_text(job)
with (work / 'listing.txt').open('w') as out:
    run = subprocess.run(['dispak', '-l', str(work / 'job.b6')], env=env,
                         stdout=out, stderr=subprocess.STDOUT, timeout=60)
listing=(work/'listing.txt').read_text(encoding='utf-8-sig')
if (run.returncode or not (work / '3777').stat().st_size or
        re.search(r'IN\s+\d+\s+LINES\s+[1-9]\d*\s+ERRORS',listing)):
    raise SystemExit('Build failed; see ' + str(work / 'listing.txt'))
# The saved reader descriptor stores the actual zone count at P/CODER+2.
header = work / 'loader-zone.bin'
subprocess.run(['besmtool', 'dump', '3777', '--start=0315', '--length=1',
                '--to-file=' + str(header)], env=env, check=True)
symbols = {symbol.name: symbol.address for symbol in load_symbols(work / 'listing.txt')}
count_offset = (symbols['P/CODER'] + 2 - 0o2000) * 6
zone_count = int.from_bytes(header.read_bytes()[count_offset:count_offset + 6], 'big')
if not 1 <= zone_count <= 64:
    raise SystemExit(f'Invalid PASCODER zone count: {zone_count}')
subprocess.run(['besmtool', 'dump', '3777', '--start=0315',
                '--length=' + str(zone_count),
                '--to-file=' + str(work / 'image.bin')], env=env, check=True)
print(work / 'image.bin')
