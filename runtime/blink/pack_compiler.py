#!/usr/bin/env python3
"""Prepare the linkers' private compiler with an 11-word instruction node.

Usage: python3 runtime/blink/pack_compiler.py
The source is regenerated from mypas.b6 under the selected build directory.
Linker compatibility also restores inline TRUNC and INPUT-before-OUTPUT
common allocation.
The original source and its K9 heap option are preserved.
"""
from collections import Counter
from pathlib import Path
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
WORK = HERE.parent/'build/blink'
FIELDS = {'ilm', 'zeroTest', 'signTest', 'bitTest'}
TOKENS = re.compile(r"\(\*.*?\*\)|\{.*?\}|%[^\n]*|'(?:''|[^'])*'|"
                    r'[A-Za-z_][A-Za-z_0-9]*', re.DOTALL)


def prepare(work=None, linker_compat=False):
    source = (ROOT/'mypas.b6').read_text()
    start = source.index('insnltyp  = record\n')
    end = source.index('\nend;', start)+len('\nend;')
    node = source[start:end]
    head, tail = node.split('    zeroTest: boolean', 1)
    flags = ['zeroTest']+re.findall(r'\b(\w+): boolean', tail)
    if set(flags) not in ({'zeroTest'}, FIELDS-{'ilm'}):
        raise ValueError('unexpected insnltyp control field declarations')
    comments = dict(zeroTest='A <> 0, logical test',
                    signTest='A < 0, additive test',
                    bitTest='A has at most one bit')
    control = '    control: packed record\n        ilm: ilmode;\n'
    for index, flag in enumerate(flags):
        separator = ';' if index+1 < len(flags) else ''
        control += f'        {flag}: boolean{separator} (* {comments[flag]} *)\n'
    control += '    end;'
    active_fields = {'ilm', *flags}
    node = head.replace('    ilm: ilmode;', control)+'end;'
    # The declarations above keep their field names; qualify only accesses.
    counts = Counter()

    def access(match):
        token = match.group()
        if token in active_fields:
            counts[token] += 1
            return 'control.'+token
        return token

    prefix = TOKENS.sub(access, source[:start])
    suffix = TOKENS.sub(access, source[end:])
    if set(counts) != active_fields:
        raise ValueError('missing instruction control field accesses')
    packed = prefix+node+suffix
    if linker_compat:
        old = '                        addToInsnList(getHelperProc(58)); (*"P/TR"*)'
        new = ('                        addToInsnList(370007B);\n'
               '                        addToInsnList(KATX+SP);\n'
               '                        addToInsnList(KAMX+ZERO);\n'
               '                        addToInsnList(KAVX+SP);')
        if packed.count(old) != 1:
            raise ValueError('expected one TRUNC helper emission')
        packed = packed.replace(old,new)
        old = '\t    curVal.i := 1257656460656412C(*"*OUTPUT*"*);'
        new = ('\t    curVal := inName;\n'
               '\t    curVal.m := makeNameWithStars(false);\n'
               '\t    l3var7z@.value := allocExtSymbol(filePattern.m);\n'+old)
        if packed.count(old) != 1:
            raise ValueError('expected one OUTPUT file descriptor allocation')
        packed = packed.replace(old,new)
    # The compiler deck uses U-: cards have 120 columns.
    for n, line in enumerate(packed.splitlines(), 1):
        if len(line) > 120:
            raise ValueError(f'private compiler:{n}: card exceeds 120 columns')
    work = work or WORK
    work.mkdir(parents=True, exist_ok=True)
    path = work/'mypas-packed.b6'
    path.write_text(packed)
    return path


if __name__ == '__main__':
    print(prepare(linker_compat=True).relative_to(ROOT))
