#!/usr/bin/env python3
"""Run every build and analysis of the project and fingerprint what they write.

Usage: python3 py/regress.py run [STEP ...]
       python3 py/regress.py compare A.json B.json [--detail]

`run` executes the steps below in order (or only the named ones) from the
repository root, keeps each log in BUILD/regress/NAME.log and writes
BUILD/regress/manifest.json: the SHA-256 of every file of the build
output, the extracted images, the program directories and the runtime
(logs and __pycache__ excluded). Files are keyed by part, not by their
place, and in their contents the repository path and the place of each
part are replaced by its name (<ROOT>, <BUILD>/, <PROGRAMS>/NAME/ ...).
So two runs are comparable across checkouts and across a move of any
part named in paths.py. `compare` lists the files that differ between
two manifests; with --detail (the two trees still in place) it says how:
which JSON fields, only source hashes and times, only order, or how many
bytes. Use it to check that a restructuring leaves every result unchanged.
"""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import time

from paths import ROOT, PY, COMPILER, RUNTIME, PROGRAMS, BUILD, IMAGES

OUT = BUILD/'regress'
# The program directories under PROGRAMS (the others belong to the runtime).
PROGRAM_DIRS = ['acc2', 'acc3', 'arap', 'blink', 'blink1', 'box', 'comp',
                'fprint', 'kanal', 'kompon3', 'link', 'link1', 'monitr', 'more',
                'mt', 'mtd', 'print', 'proz']

STEPS = [
    ('analyze', '{RUNTIME}/analyze.py'),
    ('compar', '{RUNTIME}/compar.py'),
    ('consistency', '{RUNTIME}/consistency.py'),
    ('file-access', '{RUNTIME}/file-access.py'),
    ('error-variants', '{RUNTIME}/error-variants.py'),
    ('volume-sources', '{RUNTIME}/volume-sources.py'),
    ('reviewed', '{RUNTIME}/reviewed.py'),
    ('recover', '{PY}/recover.py'),
    ('more', '{PROGRAMS}/more/build.py'),
    ('comp', '{PROGRAMS}/comp/build.py'),
    ('mtd', '{PROGRAMS}/mtd/build.py'),
    ('mt', '{PROGRAMS}/mt/build.py'),
    ('mt-variants', '{PROGRAMS}/mt/variants.py'),
    ('box', '{PROGRAMS}/box/build.py'),
    ('monitr', '{PROGRAMS}/monitr/build.py'),
    ('monitr-starter', '{PROGRAMS}/monitr/build-starter.py'),
    ('proz', '{PROGRAMS}/proz/build.py'),
    ('fprint', '{PROGRAMS}/fprint/build.py'),
    ('fprint-exercise', '{PROGRAMS}/fprint/exercise.py'),
    ('print', '{PROGRAMS}/print/analyze.py'),
    ('pascoder', '{RUNTIME}/pascoder/extract.py'),
    ('link1-analyze', '{PROGRAMS}/link1/analyze.py'),
    ('link1', '{PROGRAMS}/link1/build.py'),
    ('link-analyze', '{PROGRAMS}/link/analyze.py'),
    ('link', '{PROGRAMS}/link/build.py'),
    ('blink1-analyze', '{PROGRAMS}/blink1/analyze.py'),
    ('blink1', '{PROGRAMS}/blink1/build.py'),
    ('blink-analyze', '{PROGRAMS}/blink/analyze.py'),
    ('blink', '{PROGRAMS}/blink/build.py'),
    ('compare2248', '{RUNTIME}/linker-runtime/compare2248.py'),
    ('linker-runtime', '{RUNTIME}/linker-runtime/recover.py'),
    ('kompon3-reference', '{PROGRAMS}/kompon3/build.py --reference'),
    ('kompon3', '{PROGRAMS}/kompon3/build.py'),
    ('kompon3-analyze', '{PROGRAMS}/kompon3/analyze.py'),
    ('kompon3-compare', '{PROGRAMS}/kompon3/compare.py'),
    ('acc3-parts', '{PROGRAMS}/acc3/parts.py'),
    ('acc3-head', '{PROGRAMS}/acc3/headtry.py'),
    ('acc3-ov1', '{PROGRAMS}/acc3/ovtry.py ov1 {PROGRAMS}/acc3/ov1.pas'),
    ('acc3-ov2', '{PROGRAMS}/acc3/ovtry.py ov2 {PROGRAMS}/acc3/ov2.pas'),
    ('acc-family', '{PROGRAMS}/acc2/family.py'),
    ('acc2-ov1', '{PROGRAMS}/acc2/ovtry.py ov1 {PROGRAMS}/acc2/ov1.pas'),
    ('acc2-zone', '{PROGRAMS}/acc2/zone.py'),
    ('acc2-elf', '{PROGRAMS}/acc2/elf.py'),
    ('acc2-compare', '{PROGRAMS}/acc2/compare.py'),
    ('arap', '{PROGRAMS}/arap/build.py'),
    ('check', '{PY}/build.py check'),
]


def parts():
    """(name, directory) of every fingerprinted part, innermost first."""
    found = [('<BUILD>/', BUILD), ('<IMAGES>/', IMAGES)]
    found += [(f'<PROGRAMS>/{d}/', PROGRAMS/d) for d in PROGRAM_DIRS]
    return found + [('<RUNTIME>/', RUNTIME)]


def replacements():
    """The place of each part and the label that replaces it in file contents."""
    # Longest places first, so that programs/link1/ is not taken for runtime/.
    places = sorted(((str(d.relative_to(ROOT)) + '/', n) for n, d in parts()),
                    key=lambda x: -len(x[0]))
    if COMPILER != ROOT:
        places.append((str(COMPILER.relative_to(ROOT)) + '/', ''))
    return [(str(ROOT) + '/', '<ROOT>/'), (str(ROOT), '<ROOT>')] + [
        ('<ROOT>/' + place, label or '<ROOT>/') for place, label in places] + places


def normalized(data, table):
    for old, label in table:
        data = data.replace(old.encode(), label.encode())
    return data


def fingerprint():
    named = parts()
    table = replacements()
    hashes, places = {}, {}
    for name, directory in named:
        for p in sorted(directory.rglob('*')):
            if (not p.is_file() or '__pycache__' in p.parts or OUT in p.parents
                    or any(directory in d.parents and d in p.parents
                           for _, d in named)):
                continue
            key = name + str(p.relative_to(directory))
            hashes[key] = hashlib.sha256(normalized(p.read_bytes(), table)).hexdigest()
            places[key] = str(p.relative_to(ROOT))
    return dict(root=str(ROOT), replacements=table, places=places, hashes=hashes)


def run(names):
    OUT.mkdir(parents=True, exist_ok=True)
    steps = [s for s in STEPS if not names or s[0] in names]
    where = {k: str(v.relative_to(ROOT)) for k, v in
             dict(PY=PY, RUNTIME=RUNTIME, PROGRAMS=PROGRAMS).items()}
    for name, command in steps:
        start = time.time()
        with (OUT/f'{name}.log').open('w') as log:
            code = subprocess.run([sys.executable, *command.format(**where).split()],
                                  cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                                  stdin=subprocess.DEVNULL).returncode
        print(f'{name:20} {"ok" if code == 0 else f"exit {code}":8} '
              f'{time.time() - start:6.0f}s', flush=True)
    (OUT/'manifest.json').write_text(json.dumps(fingerprint(), indent=1))


def leaves(x, path=''):
    if isinstance(x, dict):
        for k, v in x.items():
            yield from leaves(v, f'{path}/{k}')
    elif isinstance(x, list):
        for i, v in enumerate(x):
            yield from leaves(v, f'{path}[{i}]')
    else:
        yield path, x


def explain(key, a, b):
    """Say how two normalized versions of a file differ."""
    if key.endswith('.json'):
        try:
            x, y = json.loads(a), json.loads(b)
        except ValueError:
            pass
        else:
            lx, ly = dict(leaves(x)), dict(leaves(y))
            paths = [k for k in lx.keys() | ly.keys() if lx.get(k) != ly.get(k)]
            noise = ('sha256', 'checked_at', 'hash')
            real = sorted(k for k in paths if not any(n in k for n in noise))
            if not real:
                return 'hashes and times'
            if sorted(map(json.dumps, lx.values())) == sorted(map(json.dumps, ly.values())):
                return 'order'
            return 'fields ' + ' '.join(real[:3]) + (' ...' if len(real) > 3 else '')
    if Path(key).suffix in ('.py', '.md', '.pas', '.pre', '.sh'):
        return 'source'
    if len(a) == len(b):
        return f'{sum(p != q for p, q in zip(a, b))} bytes'
    return f'length {len(a)} -> {len(b)}'


def compare(a, b, detail=False):
    """List the files that differ; with detail, say how (both trees must exist)."""
    x, y = (json.loads(Path(p).read_text()) for p in (a, b))
    hx, hy = x['hashes'], y['hashes']
    for k in sorted(hx.keys() | hy.keys()):
        if hx.get(k) == hy.get(k):
            continue
        if k not in hy or k not in hx:
            print(('only in A ' if k not in hy else 'only in B ') + k)
            continue
        how = ''
        if detail:
            na, nb = (normalized((Path(m['root'])/m['places'][k]).read_bytes(),
                                 m['replacements']) for m in (x, y))
            how = ': ' + explain(k, na, nb)
        print('differs   ' + k + how)


if __name__ == '__main__':
    if sys.argv[1:2] == ['compare']:
        compare(*[a for a in sys.argv[2:] if a != '--detail'],
                detail='--detail' in sys.argv)
    else:
        run(sys.argv[2:])
