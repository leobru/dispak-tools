#!/usr/bin/env python3
"""Apply loop alignment markers, preserving explicit (*q*) exceptions.

Usage: python3 runtime/link1/align.py [--body]
Both forms apply the complete mandatory pattern and rebuild once.
Explicit (*q*) exceptions are preserved; their do still requires (r).
"""
import argparse
from pathlib import Path
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
WORK = HERE.parent/'build/link1'
LOOP = re.compile(r'(\s*)(?:(\(q\)|\(\*q\*\))\s*)?(?:for|while)\b')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--body', action='store_true',
                        help='compatibility alias; the same marker rules apply')
    parser.parse_args()
    count = 0
    for path in [HERE/'link1.pas']:
        lines = path.read_text().splitlines()
        output = []
        for i,line in enumerate(lines):
            match = LOOP.match(line)
            if match:
                count += 1
                indent = match[1]
                if not match[2] and not (
                        i and lines[i-1].strip() in ('(q)', '(*q*)')):
                    line = indent+'(q) '+line[len(indent):]
                body = re.search(r'\bdo\b',line)
                if body is None:
                    raise ValueError(f'{path}:{i+1}: expected do on loop header')
                pos = body.end()
                tail = line[pos:].lstrip()
                following = lines[i+1].lstrip() if i+1<len(lines) else ''
                if not tail.startswith('(r)') and not (
                        not tail and following.startswith('(r)')):
                    labelled = line[:pos]+' (r)'+line[pos:]
                    line = (labelled if len(labelled)<=72 else
                            (line[:pos]+'\n'+indent+'  (r) '+tail).rstrip())
                if len(line.splitlines()[0])>72:
                    marker = match[2] or '(q)'
                    line = indent+marker+'\n'+line.replace(marker+' ', '', 1)
            output.append(line)
        path.write_text('\n'.join(output)+'\n')
    WORK.mkdir(parents=True,exist_ok=True)
    with (WORK/'pattern.log').open('w') as stream:
        subprocess.run([sys.executable,str(HERE/'build.py')],cwd=ROOT,
                       stdout=stream,stderr=subprocess.STDOUT,check=True)
    print(f'Applied markers to {count} loops, preserving (*q*) exceptions; '
          'build completed.')


if __name__ == '__main__':
    main()
