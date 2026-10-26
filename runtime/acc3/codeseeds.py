#!/usr/bin/env python3
"""Find code entry points of an image for disbesm6 by iterated flow analysis.

Usage: python3 runtime/acc3/codeseeds.py image.bin base entry lo hi > seeds.sym

disbesm6 follows control flow from one entry and stops at returns, so code
reached only through calls whose targets it did not decode stays data. This
runs disbesm6 repeatedly, adding every jump, branch and call target in
[lo, hi) found in decoded instructions (and the word after a procedure's
final jump) as an unnamed code seed ("addr C -"), until nothing new appears.
All addresses are octal.
"""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BRANCH = {'26', '27', '30', '31', '34', '35', '37'}


def decode(image, base, entry, seeds):
    with tempfile.NamedTemporaryFile('w', suffix='.sym', delete=False) as f:
        f.write(''.join(f'{a:05o} C -\n' for a in sorted(seeds)))
        name = f.name
    out = subprocess.run([str(ROOT/'disbesm6'), '-b', f'-a{base:o}', f'-e{entry:o}',
                          '-n', name, str(image)], capture_output=True, text=True)
    Path(name).unlink()
    return out.stdout


def targets(listing, lo, hi):
    found, address = set(), None
    for line in listing.splitlines():
        m = re.match(r'^ ?([0-7]{4,5})[: ]', line)
        if m:
            address = int(m[1], 8)
        m = re.match(r'^(?: ?[0-7]{4,5}[: ]| {6})([0-7]{2}) ([0-7]{2}) ([0-7]{5}) \t', line)
        if not m:
            continue
        op, value = m[2], int(m[3], 8)
        if op in BRANCH and lo <= value < hi:
            found.add(value)
        # A procedure ends with a jump; the next word may start another one.
        if op == '30' and address is not None and address + 1 < hi:
            found.add(address + 1)
    return found


def main():
    image, base, entry, lo, hi = sys.argv[1], *(int(a, 8) for a in sys.argv[2:6])
    seeds = {entry}
    while True:
        new = targets(decode(image, base, entry, seeds), lo, hi) - seeds
        if not new:
            break
        seeds |= new
    sys.stdout.write(''.join(f'{a:05o} C -\n' for a in sorted(seeds)))


if __name__ == '__main__':
    main()
