#!/usr/bin/env python3
"""Prepare a compiler with the two historical linker compatibility changes.

Usage: python3 runtime/linker-runtime/patch_compiler.py [--source compiler.b6]
Only TRUNC emission and INPUT/OUTPUT common allocation order are changed.
The instruction-node declaration, heap option and source deck are preserved.
"""
import argparse
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
WORK = HERE.parent/'build/link1'


def patch(source):
    replacements = [
        ('                        addToInsnList(getHelperProc(58)); (*"P/TR"*)',
         '                        addToInsnList(370007B);\n'
         '                        addToInsnList(KATX+SP);\n'
         '                        addToInsnList(KAMX+ZERO);\n'
         '                        addToInsnList(KAVX+SP);'),
        ('\t    curVal.i := 1257656460656412C(*"*OUTPUT*"*);',
         '\t    curVal := inName;\n'
         '\t    curVal.m := makeNameWithStars(false);\n'
         '\t    l3var7z@.value := allocExtSymbol(filePattern.m);\n'
         '\t    curVal.i := 1257656460656412C(*"*OUTPUT*"*);'),
    ]
    for old, new in replacements:
        # An explicitly selected deck may already contain either change.
        if source.count(new) == 1:
            continue
        if source.count(old) != 1:
            raise ValueError('Expected one compiler patch site: '+old.strip())
        source = source.replace(old, new, 1)
    return source


def prepare(work=WORK, source_path=None):
    source_path = source_path or ROOT/'mypas.b6'
    source = patch(source_path.read_text())
    for n, line in enumerate(source.splitlines(), 1):
        if len(line) > 120:
            raise ValueError(f'Compiler card {n} exceeds 120 columns')
    work.mkdir(parents=True, exist_ok=True)
    path = work/'mypas-linker.b6'
    path.write_text(source)
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=ROOT/'mypas.b6')
    parser.add_argument('--work', type=Path, default=WORK)
    args = parser.parse_args()
    print(prepare(args.work, args.source))


if __name__ == '__main__':
    main()
