#!/usr/bin/env python3
"""Regenerate the FORMAT listing; check every displayed instruction's raw bits."""
from pathlib import Path
import hashlib
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
EXPECTED = 'dba126cd84c17f0298b412a5582cdd1a681b0717185e2b31fdbff9fcb7516b74'

def main():
    raw = (HERE / 'format.bin').read_bytes()
    assert len(raw) == 12288
    assert hashlib.sha256(raw).hexdigest() == EXPECTED
    words = [int.from_bytes(raw[i:i+6], 'big') for i in range(0, len(raw), 6)]
    result = subprocess.run(
        [str(ROOT / 'tools/disbesm6'), '-a0', '-e23', '-e1', '-e20',
         '-nformat/format.sym', 'format/format.bin'], cwd=ROOT,
        text=True, capture_output=True, check=True)
    if result.stderr:
        raise RuntimeError(result.stderr)
    listing = result.stdout.replace('Code: 12288 (04000) words',
                                    'Code: 2048 (04000) words; 12288 bytes')
    # disbesm6 suppresses address zero. Preserve that word explicitly in the header.
    listing = '* Word 00000: %016o (not emitted by disbesm6)\n' % words[0] + listing
    addr = None
    checked = 0
    covered = set()
    for line in listing.splitlines():
        left = re.match(r'^\s*([0-7]+)[: ]([0-7]{2} [0-7]{2,3} [0-7]{4,5})\s', line)
        right = re.match(r'^      ([0-7]{2} [0-7]{2,3} [0-7]{4,5})\s', line)
        compact = re.match(r'^      ([0-7]{8})\s', line)
        if left:
            addr = int(left[1], 8)
            fields, half = left[2].split(), words[addr] >> 24
            covered.add(addr)
        elif right and addr is not None:
            fields, half = right[1].split(), words[addr] & 0xffffff
        elif compact and addr is not None:
            assert int(compact[1], 8) == words[addr] & 0xffffff, line
            checked += 1
            continue
        else:
            continue
        reg, op, off = map(lambda s: int(s, 8), fields)
        if len(fields[1]) == 2:
            encoded = (reg << 20) | (op << 15) | off
        else:
            encoded = (reg << 20) | ((op & 0o77) << 12) | off
            if op & 0o100:
                encoded |= 1 << 18
        assert encoded == half, line
        checked += 1
    for line in (HERE / 'format.sym').read_text().splitlines():
        span, kind, _ = line.split()
        if kind == 'C' and '-' in span:
            first, last = [int(s, 8) for s in span.split('-')]
            assert set(range(first, last+1)) <= covered, span
    (HERE / 'format.dis').write_text(listing)
    print(f'{len(words)} words; SHA-256 OK; {checked} instruction halves checked')

if __name__ == '__main__':
    main()
