#!/usr/bin/env python3
"""Check a change of mypas.b6: self-compilation fixpoint and the tests.

Usage: python3 py/fixpoint.py [base-revision]

Works on private copies of volume 77 under build/fixpoint; the
installed ~/.besm6/77 is only read.
- base: mypas.b6 of base-revision (default HEAD) compiled by the installed
  compiler, then by itself, so that it is that revision's own fixpoint;
- g1: the working mypas.b6 compiled by base, g2 by g1, g3 by g2.
The fixpoint holds when g2 and g3 are the same volume. Then tests/*.pas
and test.pas are built with base and with g3 (buildimg.sh), and the
images that differ are listed: those are the effects of the change.
"""
from pathlib import Path
import os
import re
import shutil
import subprocess
import sys

from paths import ROOT, TOOLS, COMPILER, BUILD

WORK = BUILD/'fixpoint'
INSTALLED = Path.home()/'.besm6/77'


def compile_compiler(source_text, compiler_dir, target_dir):
    """Compile source_text with the 77 of compiler_dir into target_dir/77."""
    target_dir.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(compiler_dir/'77', target_dir/'77')
    prefix, marker, _ = source_text.partition('*end record\n')
    if not marker:
        sys.exit('compiler deck has no overlay record terminator')
    deck = target_dir/'compiler.b6'
    deck.write_text(prefix + marker + '*call ocatalog:670000\n*system\n'
                    '*end file\n``````\nЕКОНЕЦ\n')
    path = f'{target_dir}:{Path.home()}/.besm6:/usr/local/share/besm6'
    listing = target_dir/'compiler.lst'
    with listing.open('w') as out:
        subprocess.run(['dispak', '--path='+path, '-l', str(deck)],
                       env=dict(os.environ, BESM6_PATH=path),
                       stdin=subprocess.DEVNULL, stdout=out,
                       stderr=subprocess.STDOUT, timeout=300, check=True)
    text = listing.read_text(encoding='utf-8-sig', errors='replace')
    if (re.search(r'\bIN\s+\d+\s+LINES\s+[1-9]\d*\s+ERRORS', text)
            or 'LINES STRUCTURE' not in text):
        sys.exit(f'compiler build failed; see {listing}')


def build_tests(compiler_dir, out_dir):
    out_dir.mkdir(parents=True, exist_ok=True)
    path = f'{compiler_dir}:{Path.home()}/.besm6:/usr/local/share/besm6'
    images = {}
    for src in sorted((COMPILER/'tests').glob('*.pas')) + [ROOT/'test.pas']:
        shutil.copyfile(src, out_dir/src.name)
        pre = src.with_suffix('.pre')
        if pre.exists():
            shutil.copyfile(pre, out_dir/pre.name)
        subprocess.run([str(TOOLS/'buildimg.sh'), src.name], cwd=out_dir,
                       env=dict(os.environ, BESM6_PATH=path),
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        img = out_dir/(src.stem + '.img')
        images[src.name] = img.read_bytes() if img.exists() else None
    return images


def main():
    base_rev = sys.argv[1] if len(sys.argv) > 1 else 'HEAD'
    before = INSTALLED.read_bytes()
    base_text = subprocess.run(['git', 'show', f'{base_rev}:{(COMPILER/"mypas.b6").relative_to(ROOT)}'], cwd=ROOT,
                               capture_output=True, text=True).stdout
    if not base_text:
        # Revisions before the move kept the compiler at the root.
        base_text = subprocess.run(['git', 'show', f'{base_rev}:mypas.b6'], cwd=ROOT,
                                   capture_output=True, text=True, check=True).stdout
    new_text = (COMPILER/'mypas.b6').read_text()
    compile_compiler(base_text, INSTALLED.parent, WORK/'base0')
    compile_compiler(base_text, WORK/'base0', WORK/'base')
    previous = WORK/'base'
    for gen in ('g1', 'g2', 'g3'):
        compile_compiler(new_text, previous, WORK/gen)
        previous = WORK/gen
    if INSTALLED.read_bytes() != before:
        sys.exit('the installed volume 77 changed')
    same = (WORK/'g2/77').read_bytes() == (WORK/'g3/77').read_bytes()
    print('fixpoint: g3 == g2' if same else 'NO FIXPOINT: g3 != g2')
    old = build_tests(WORK/'base', WORK/'tests-base')
    new = build_tests(WORK/'g3', WORK/'tests-new')
    for name in old:
        status = ('no image' if old[name] is None or new[name] is None else
                  'same' if old[name] == new[name] else 'DIFFERS')
        print(f'{name}: {status}')
    sys.exit(0 if same else 1)


if __name__ == '__main__':
    main()
