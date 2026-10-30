#!/usr/bin/env python3
"""Run every build and analysis of runtime/ and fingerprint what they write.

Usage: python3 runtime/regress.py run [STEP ...]
       python3 runtime/regress.py compare A.json B.json

`run` executes the steps below in order (or only the named ones) from the
repository root, keeps each log in runtime/build/regress/NAME.log and
writes runtime/build/regress/manifest.json: the SHA-256 of every file under
runtime/ (build output included, logs and __pycache__ excluded), with the
repository path replaced by <ROOT> first, so that runs in two checkouts are
comparable. `compare` lists the files that differ between two manifests.
Use it to check that a restructuring leaves every result unchanged.
"""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import time

from paths import ROOT, RUNTIME, BUILD

OUT = BUILD/'regress'

STEPS = [
    ('analyze', 'runtime/analyze.py'),
    ('compar', 'runtime/compar.py'),
    ('consistency', 'runtime/consistency.py'),
    ('file-access', 'runtime/file-access.py'),
    ('error-variants', 'runtime/error-variants.py'),
    ('volume-sources', 'runtime/volume-sources.py'),
    ('reviewed', 'runtime/reviewed.py'),
    ('recover', 'runtime/recover.py'),
    ('more', 'runtime/more/build.py'),
    ('comp', 'runtime/comp/build.py'),
    ('mtd', 'runtime/mtd/build.py'),
    ('mt', 'runtime/mt/build.py'),
    ('mt-variants', 'runtime/mt/variants.py'),
    ('box', 'runtime/box/build.py'),
    ('monitr', 'runtime/monitr/build.py'),
    ('monitr-starter', 'runtime/monitr/build-starter.py'),
    ('proz', 'runtime/proz/build.py'),
    ('fprint', 'runtime/fprint/build.py'),
    ('fprint-exercise', 'runtime/fprint/exercise.py'),
    ('print', 'runtime/print/analyze.py'),
    ('pascoder', 'runtime/pascoder/extract.py'),
    ('link1-analyze', 'runtime/link1/analyze.py'),
    ('link1', 'runtime/link1/build.py'),
    ('link-analyze', 'runtime/link/analyze.py'),
    ('link', 'runtime/link/build.py'),
    ('blink1-analyze', 'runtime/blink1/analyze.py'),
    ('blink1', 'runtime/blink1/build.py'),
    ('blink-analyze', 'runtime/blink/analyze.py'),
    ('blink', 'runtime/blink/build.py'),
    ('compare2248', 'runtime/linker-runtime/compare2248.py'),
    ('linker-runtime', 'runtime/linker-runtime/recover.py'),
    ('kompon3-reference', 'runtime/kompon3/build.py --reference'),
    ('kompon3', 'runtime/kompon3/build.py'),
    ('kompon3-analyze', 'runtime/kompon3/analyze.py'),
    ('kompon3-compare', 'runtime/kompon3/compare.py'),
    ('acc3-parts', 'runtime/acc3/parts.py'),
    ('acc3-head', 'runtime/acc3/headtry.py'),
    ('acc3-ov1', 'runtime/acc3/ovtry.py ov1 runtime/acc3/ov1.pas'),
    ('acc3-ov2', 'runtime/acc3/ovtry.py ov2 runtime/acc3/ov2.pas'),
    ('check', 'runtime/build.py check'),
]


def fingerprint():
    root = str(ROOT).encode()
    out = {}
    for p in sorted(RUNTIME.rglob('*')):
        if not p.is_file() or '__pycache__' in p.parts or OUT in p.parents:
            continue
        out[str(p.relative_to(ROOT))] = hashlib.sha256(
            p.read_bytes().replace(root, b'<ROOT>')).hexdigest()
    return out


def run(names):
    OUT.mkdir(parents=True, exist_ok=True)
    steps = [s for s in STEPS if not names or s[0] in names]
    for name, command in steps:
        start = time.time()
        with (OUT/f'{name}.log').open('w') as log:
            code = subprocess.run([sys.executable, *command.split()], cwd=ROOT,
                                  stdout=log, stderr=subprocess.STDOUT,
                                  stdin=subprocess.DEVNULL).returncode
        print(f'{name:20} {"ok" if code == 0 else f"exit {code}":8} '
              f'{time.time() - start:6.0f}s', flush=True)
    (OUT/'manifest.json').write_text(json.dumps(fingerprint(), indent=1))


def compare(a, b):
    x, y = (json.loads(Path(p).read_text()) for p in (a, b))
    for k in sorted(x.keys() | y.keys()):
        if x.get(k) != y.get(k):
            print(('only in A ' if k not in y else 'only in B ' if k not in x
                   else 'differs   ') + k)


if __name__ == '__main__':
    if sys.argv[1:2] == ['compare']:
        compare(*sys.argv[2:4])
    else:
        run(sys.argv[2:])
