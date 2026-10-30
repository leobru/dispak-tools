"""Read the final loader map of either PASCODER or PAKWRITE builds."""
from pathlib import Path
import re
from typing import NamedTuple


class Symbol(NamedTuple):
    name: str
    address: int
    kind: str


def load_symbols(filename):
    symbols = []
    active = False
    for line in Path(filename).read_text(encoding='utf-8-sig').splitlines():
        if re.search(r'\b(?:PASCODER|PAKWRITE)\s+01000\b', line):
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
        raise ValueError(f'{filename}: final loader map not found')
    return sorted(set(symbols), key=lambda s: (s.address, s.name))
