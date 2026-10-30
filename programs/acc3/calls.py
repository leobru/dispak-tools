#!/usr/bin/env python3
"""Calls from the user code of an АСС3 part into its runtime area.

Usage: python3 programs/acc3/calls.py ov1|ov2 [runtime-start]

For every target of `пв X(М15)` at or above the runtime start (P/2), prints
how many calls there are and how many of them are followed by
`уиа pool(М10)`. That reload marks a call of an `assembler` external
declared in the source (mypas.b6 reloads M8 after those); a library routine
is called without it. Also prints the first calling address.
"""
from collections import defaultdict
from pathlib import Path
import re
import sys

sys.path.insert(0, str(next(p/'py' for p in Path(__file__).resolve().parents
                            if (p/'py/paths.py').exists())))
import paths

BUILD = paths.BUILD/'acc3'
RUNTIME = {'ov1': 0o22557, 'ov2': 0o33027}
POOL = {'ov1': '17731', 'ov2': '31346'}
INSN = re.compile(r'^(?: ?([0-7]{4,5})[: ]| {6})([0-7]{2}) ([0-7]{2,3}) ([0-7]{4,5}) \t')


def main():
    part = sys.argv[1]
    start = int(sys.argv[2], 8) if len(sys.argv) > 2 else RUNTIME[part]
    insns, address = [], None
    for line in (BUILD/f'{part}.dis').read_text().splitlines():
        m = INSN.match(line)
        if m:
            address = int(m[1], 8) if m[1] else address
            insns.append((address, m[2], m[3], m[4]))
    calls = defaultdict(lambda: [0, 0, None])
    for k, (a, reg, op, addr) in enumerate(insns):
        if op != '31' or reg != '15' or int(addr, 8) < start or a >= start:
            continue
        c = calls[int(addr, 8)]
        c[0] += 1
        c[2] = c[2] or a
        nxt = insns[k+1] if k+1 < len(insns) else None
        if nxt and nxt[1:] == ('10', '24', POOL[part]):
            c[1] += 1
    for target, (n, reload, first) in sorted(calls.items()):
        kind = 'asm' if reload else 'lib'
        print(f'{target:05o} {kind} calls {n} reloads {reload} first {first:05o}')


if __name__ == '__main__':
    main()
