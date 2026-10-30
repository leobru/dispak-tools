#!/usr/bin/env python3
"""Find runtime candidates using a reference image and its final loader map.

Usage: libmatch.py ref.img ref.img.lst target.bin [base] [--json]
ENTRY aliases stay with their module. Matches require identical words except
for consistent address relocation in addressing instructions; numeric operands
and indexed short offsets must agree exactly. Ambiguities are never resolved
by taking the first hit. These remain candidates, not recovered relocation
records. Output uses C for code and D for data (I means ISO text in disbesm6).
"""

import argparse
from dataclasses import dataclass
import json
from pathlib import Path
import re
import sys


@dataclass(frozen=True)
class Symbol:
    name: str
    address: int
    kind: str


def words(filename):
    data = Path(filename).read_bytes()
    if len(data) % 6:
        raise ValueError(f'{filename}: incomplete 48-bit word')
    return [int.from_bytes(data[i:i + 6], 'big')
            for i in range(0, len(data), 6)]


def load_symbols(filename):
    symbols = []
    active = False
    for line in Path(filename).read_text(encoding='utf-8-sig').splitlines():
        if re.search(r'\bPASCODER\s+01000\b', line):
            active = True
        if not active:
            continue
        if not line.strip() and symbols:
            break
        for name, kind, address in re.findall(
                r'(\S+)\s+(?:([EC])\s+)?([0-7]{5})\b', line):
            if re.fullmatch(r'[A-Z*/][A-Z0-9*/]*', name):
                symbols.append(Symbol(name, int(address, 8), kind or 'M'))
        free = re.search(r'\s[CС][BВ][OО][БB][OО][ДD]\s+([0-7]{5})', line)
        if free:
            symbols.append(Symbol('FREE', int(free[1], 8), 'Z'))
    if not symbols:
        raise ValueError(f'{filename}: final PASCODER loader map not found')
    return sorted(set(symbols), key=lambda s: (s.address, s.name))


def loadmap(filename):
    return {s.name: s.address for s in load_symbols(filename)}


DATA_MODULES = {'P/00', 'P/01', 'P/02', 'P/03', 'P/04', 'P/06',
                'P/07', 'P/08', 'P/0П', 'PASTENS'}


def sections(symbols, base, size):
    modules = [s for s in symbols if s.kind == 'M' and base <= s.address < base + size]
    result = []
    for index, module in enumerate(modules):
        if module.name in {'P/BOOT', 'P/CODER', 'PASCODER'}:
            continue
        if not (module.name.startswith(('P/', 'PAS', 'RT'))
                or module.name in {'STOP*', 'L5523', 'L5546'}):
            continue
        end = modules[index + 1].address if index + 1 < len(modules) else base + size
        ends = [s.address for s in symbols
                if s.kind in ('C', 'Z') and module.address < s.address < end]
        if ends:
            end = min(ends)
        aliases = [s for s in symbols if s.kind == 'E'
                   and module.address <= s.address < end]
        if end > module.address:
            result.append((module, end, aliases))
    return result


def operand(half):
    reg = half >> 20
    if half & 0o2000000:
        return reg, (half >> 15) & 0o37, half & 0o77777, True
    address = (half & 0o7777) | (0o70000 if half & 0o1000000 else 0)
    return reg, (half >> 12) & 0o77, address, False


def address_operand(half, base, limit):
    reg, opcode, address, long = operand(half)
    if not base <= address < limit:
        return False
    if long:
        return opcode in (0o22, 0o23, 0o24, 0o26, 0o27, 0o30,
                          0o31, 0o34, 0o35, 0o36, 0o37)
    return reg == 0 and (opcode <= 0o27 or opcode in (0o64, 0o70, 0o71))


def mask(word):
    """Fingerprint for lookup only; acceptance checks every operand."""
    result = 0
    for shift in (24, 0):
        half = (word >> shift) & 0xffffff
        result = (result << 24) | (half & (
            0o77700000 if half & 0o2000000 else 0o77770000))
    return result


def match_at(reference, target, start, end, position, base):
    relocation, reverse, changed = {}, {}, []
    for index, rw in enumerate(reference[start - base:end - base]):
        tw = target[position + index]
        for side, shift in (('L', 24), ('R', 0)):
            rh, th = (rw >> shift) & 0xffffff, (tw >> shift) & 0xffffff
            if rh == th:
                if address_operand(rh, base, base+len(reference)):
                    ra=operand(rh)[2]
                    if start<=ra<end and ra!=position+base+ra-start:
                        return None
                    if relocation.setdefault(ra,ra)!=ra or reverse.setdefault(ra,ra)!=ra:
                        return None
                continue
            if mask(rh << 24) != mask(th << 24):
                return None
            if not (address_operand(rh, base, base + len(reference)) and
                    address_operand(th, base, base + len(target))):
                return None
            ra, ta = operand(rh)[2], operand(th)[2]
            if start <= ra < end:
                if ta != position + base + ra - start:
                    return None
            elif position + base <= ta < position + base + end - start:
                return None
            if relocation.setdefault(ra, ta) != ta or reverse.setdefault(ta, ra) != ra:
                return None
            changed.append(dict(word=f'{position + base + index:05o}',
                                half=side, reference=f'{ra:05o}', target=f'{ta:05o}'))
    return changed


def find_candidates(ref, symbols, target, base=0o2000, fragments=False):
    by_head = {}
    for i, word in enumerate(target):
        by_head.setdefault(mask(word), []).append(i)
    results = []
    regions = sections(symbols, base, len(ref))
    if fragments:
        regions = [(entry, following, [])
                   for module, end, aliases in regions
                   for entry, following in zip(
                       [module] + sorted(aliases, key=lambda a: a.address),
                       [a.address for a in sorted(aliases, key=lambda a: a.address)] + [end])
                   if following > entry.address]
    for module, end, aliases in regions:
        pattern = ref[module.address - base:end - base]
        if not pattern or not any(pattern):
            continue
        matches = []
        for position in by_head.get(mask(pattern[0]), []):
            if position + len(pattern) > len(target):
                continue
            changes = match_at(ref, target, module.address, end, position, base)
            if changes is not None:
                matches.append(dict(address=f'{base + position:05o}', relocation=changes))
        results.append(dict(name=module.name, reference=f'{module.address:05o}',
                            words=len(pattern),
                            type='D' if module.name in DATA_MODULES else 'C',
                            fragment=fragments,
                            aliases=[dict(name=a.name, offset=a.address-module.address)
                                     for a in aliases], matches=matches))
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('reference')
    parser.add_argument('listing')
    parser.add_argument('target')
    parser.add_argument('base', nargs='?', default='2000')
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    results = find_candidates(words(args.reference), load_symbols(args.listing),
                              words(args.target), int(args.base, 8))
    if args.json:
        print(json.dumps(results, indent=2))
        return
    for result in results:
        matches = result['matches']
        if len(matches) > 1:
            print(f'{result["name"]}: ambiguous: ' +
                  ', '.join(m['address'] for m in matches), file=sys.stderr)
        elif matches:
            addr = int(matches[0]['address'], 8)
            print(f'{addr:o} {result["type"]} {result["name"]}')
            for alias in result['aliases']:
                kind='D' if alias['name'] in DATA_MODULES else result['type']
                print(f'{addr + alias["offset"]:o} {kind} {alias["name"]}')


if __name__ == '__main__':
    main()
