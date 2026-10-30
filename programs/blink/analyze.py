#!/usr/bin/env python3
"""Map BLINK to LINK and inspect its original instructions.

Usage: python3 programs/blink/analyze.py [lo hi]  (octal addresses)
Without bounds, write the routine inventory and symbols. Missing images are
extracted from volume 4001 with besmtool, without changing the volume.
"""
from collections import Counter, defaultdict
from functools import lru_cache
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'runtime' for p in HERE.parents
                            if (p/'runtime/paths.py').exists())))
import paths
from paths import ROOT, TOOLS, PROGRAMS, IMAGES
sys.path.insert(1, str(TOOLS))
from corpus import read_words, find_volume
from libmatch import operand
sys.path.insert(0,str(paths.RUNTIME/'linker-runtime'))
import historical_names as historical


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


LINK = load_module('blink_link_reference', PROGRAMS/'link/analyze.py')
BASE, POOL, GLOBALS, RUNTIME, FREE = 0o2000, 0o17345, 0o21203, 0o22150, 0o25465
IMAGE = IMAGES/'4001/0275-blink.bin'
F1, F2 = LINK.F1, LINK.F2


def ensure_images():
    LINK.ensure_images()
    if IMAGE.exists():
        return
    volume = find_volume()
    env = os.environ.copy()
    env['BESM6_PATH'] = str(volume.parent)
    subprocess.run(['besmtool', 'dump', '4001', '--start=0275', '--length=16',
                    '--to-file='+str(IMAGE)], env=env, check=True,
                   stdout=subprocess.DEVNULL)


@lru_cache(maxsize=1)
def profile():
    """Accept only runtime address substitutions at identical code positions.

    Every changed half-word must keep its opcode and register. Each source
    address must have one consistent target across all application uses.
    The constant pool and global words must be literally identical to LINK.
    """
    ensure_images()
    basis = LINK.profile()
    old, new = read_words(LINK.IMAGE), read_words(IMAGE)
    for index in (8, 10):
        expected = FREE if index == 8 else old[index]
        actual = new[index] & 0o77777 if index == 8 else new[index]
        if actual != expected:
            raise ValueError(f'unexpected BLINK header word {BASE+index:05o}')
    before = LINK.SK.procedures(old, BASE, 0o2013, 0o17340)
    after = LINK.SK.procedures(new, BASE, 0o2013, 0o17340)
    if before != after:
        raise ValueError('BLINK procedure frames differ from LINK')
    if old[POOL-BASE:RUNTIME-BASE] != new[POOL-BASE:RUNTIME-BASE]:
        raise ValueError('BLINK constants or globals differ from LINK')
    uses = defaultdict(Counter)
    changed_words, changed_halves = 0, 0
    for address in range(0o2012, POOL):
        first, second = old[address-BASE], new[address-BASE]
        changed_words += first != second
        for shift in (24, 0):
            a = operand(first >> shift & 0xffffff)
            b = operand(second >> shift & 0xffffff)
            if a != b:
                if (a[:2] != b[:2] or not a[3] or not b[3] or
                        min(a[2], b[2]) < RUNTIME):
                    raise ValueError(f'non-runtime code change at {address:05o}')
                changed_halves += 1
            if a[3] and a[2] >= BASE:
                uses[a[2]][b[2]] += 1
    ambiguous = {f'{a:05o}':dict(hits) for a, hits in uses.items()
                 if len(hits) != 1}
    if ambiguous:
        raise ValueError(f'ambiguous BLINK relocations: {ambiguous}')
    relocations = {a:next(iter(hits)) for a, hits in uses.items()}
    externals = {name:relocations[address]
                 for name, address in basis['externals'].items()}
    return dict(entries=basis['entries'], ends=basis['ends'],
                externals=externals, relocations=relocations, frames=after,
                changed_words=changed_words, changed_halves=changed_halves,
                changed_relocations=[dict(original=f'{a:05o}',
                                          blink=f'{b:05o}', uses=uses[a][b])
                                     for a, b in sorted(relocations.items())
                                     if a != b])


def reference_address(address):
    """Compose LINK1 -> LINK -> BLINK for the shared compilation builder."""
    target = LINK.reference_address(address)
    if BASE <= target < RUNTIME:
        return target
    return profile()['relocations'][target]


def load_helpers():
    data = profile()
    result = {int(address, 8):name for address, _, name in
              (line.split() for line in
               (paths.RUNTIME/'analysis/4001-0275-blink.sym').read_text().splitlines())
              if int(address, 8) < FREE}
    for address, name in LINK.load_helpers().items():
        if BASE <= address < RUNTIME:
            result[address] = name
        elif address in data['relocations']:
            result[data['relocations'][address]] = name
    result.update({address:name for name, address in data['entries']})
    result.update({address:name for name, address in data['externals'].items()})
    result.update({GLOBALS:'P/1D', GLOBALS+0o650:'*INPUT*',
                   GLOBALS+0o706:'*OUTPUT*', POOL:'POOL',
                   reference_address(0o23000):'P/WO'})
    return {a:historical.symbol(n) for a,n in result.items()}


def main():
    data = profile()
    names = load_helpers()
    words = read_words(IMAGE)
    if len(sys.argv) == 3:
        lo, hi = (int(value, 8) for value in sys.argv[1:])
        for address in range(lo, hi):
            halves = []
            for shift in (24, 0):
                reg, op, value, long = operand(words[address-BASE] >> shift & 0xffffff)
                mnemonic = F2[op] if long else F1[op] if op < len(F1) else f'*{op:o}'
                note = ''
                if reg == 0o10 and not long and op <= 0o27:
                    offset = value if value < 0o70000 else value-0o100000
                    note = ' ['+LINK.LINK.analyze.describe(words[POOL+offset-BASE])+']'
                elif value in names and (long or reg == 0):
                    note = ' ['+names[value]+']'
                halves.append(f'{reg:02o},{mnemonic},{value:05o}'+note)
            print(f'{address:05o} {halves[0]:72} {halves[1]}')
        return
    inventory = dict(image=str(IMAGE.relative_to(paths.RUNTIME)),
                     basis=str((PROGRAMS/'link/link.pas').relative_to(ROOT)), pool=f'{POOL:05o}',
                     globals=f'{GLOBALS:05o}', runtime=f'{RUNTIME:05o}',
                     free=f'{FREE:05o}', code_words=POOL-0o2012,
                     entries=[dict(name=historical.routine(n), address=f'{a:05o}') for n, a in data['entries']],
                     external_entries={n:f'{a:05o}' for n, a in data['externals'].items()},
                     framed_procedures=len(data['frames']),
                     link_comparison=dict(changed_words=data['changed_words'],
                                          changed_halves=data['changed_halves'],
                                          constants_identical=True,
                                          globals_identical=True,
                                          relocations=data['changed_relocations']))
    (HERE/'inventory.json').write_text(json.dumps(inventory, ensure_ascii=False, indent=2)+'\n')
    (HERE/'names.json').write_text(json.dumps(
        {f'{a:05o}':historical.routine(n) for n,a in data['entries']}, ensure_ascii=False, indent=2)+'\n')
    (HERE/'blink.sym').write_text(''.join(
        f'{a:05o} {"D" if POOL<=a<RUNTIME or n.startswith("*") else "C"} {n}\n'
        for a, n in sorted(names.items())))
    print(f"{len(data['entries'])} regions, {len(data['frames'])} frames, "
          f'{POOL-0o2012} application words; '
          f"{data['changed_words']} words with runtime relocations from LINK")


if __name__ == '__main__':
    main()
