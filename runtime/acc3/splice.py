#!/usr/bin/env python3
"""Replace the generated declarations in an АСС3 source with genvars.py output.

Usage: python3 runtime/acc3/splice.py runtime/acc3/ov1.pas

The globals run from `var g0050` to the line declaring g1176. The common
parameters are listed in the program heading after `input, output,` up to
`);` and declared after the globals, from c20634 to the line declaring
c22556.
"""
from pathlib import Path
import subprocess
import sys

GEN = Path(__file__).resolve().parent/'genvars.py'


def gen(*args):
    return subprocess.run([sys.executable, str(GEN), *args], capture_output=True,
                          text=True, check=True).stdout


def main():
    path = Path(sys.argv[1])
    s = path.read_text()
    start = s.index('var g0050')
    end = s.index('\n', s.index('g1176: '))+1
    s = s[:start] + 'var' + gen()[3:] + s[end:]
    lines = gen('--common').splitlines(keepends=True)
    k = next(i for i, line in enumerate(lines) if not line.rstrip().endswith(','))
    heading, decls = ''.join(lines[:k+1]).rstrip(), ''.join(lines[k+1:])
    start = s.index('(input, output,') + len('(input, output,')
    s = s[:start] + '\n' + heading + s[s.index(');', start):]
    if '    c20634' in s[s.index('var g0050'):]:
        start = s.index('\n    c20634', s.index('var g0050')) + 1
        end = s.index('\n', s.index('c22556: ', start)) + 1
        s = s[:start] + decls + s[end:]
    else:
        end = s.index('\n', s.index('g1176: ')) + 1
        s = s[:end] + decls + s[end:]
    path.write_text(s)


if __name__ == '__main__':
    main()
