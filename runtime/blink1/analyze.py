#!/usr/bin/env python3
"""Map BLINK1 to LINK1 and inspect its original instructions.

Usage: python3 runtime/blink1/analyze.py [lo hi]  (octal addresses)
Without bounds, write the routine inventory and symbols. Inputs are extracted
from volume 4001 by the existing LINK1 extraction helper.
"""
from collections import Counter, defaultdict
import difflib
from functools import lru_cache
import importlib.util
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import paths
from paths import ROOT, TOOLS, PROGRAMS, IMAGES
sys.path.insert(1, str(TOOLS))
from corpus import read_words
from libmatch import operand
sys.path.insert(0,str(paths.RUNTIME/'linker-runtime'))
import historical_names as historical


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


LINK = load_module('blink1_link_reference', PROGRAMS/'link1/build.py')
SK = load_module('blink1_frames', PROGRAMS/'acc3/skeleton.py')
BASE, POOL, GLOBALS, RUNTIME, FREE = 0o2000, 0o16704, 0o20540, 0o21505, 0o24736
IMAGE = IMAGES/'4001/0255-blink1.bin'
F1, F2 = LINK.analyze.F1, LINK.analyze.F2
ensure_images = LINK.analyze.ensure_images


def instruction_keys(words, lo, hi, pool):
    instructions, keys = [], []
    for address in range(lo, hi):
        for shift in (24, 0):
            reg, op, value, long = operand(words[address-BASE] >> shift & 0xffffff)
            instructions.append((reg, op, value, long))
            if reg == 0o10 and not long and op <= 0o27:
                offset = value if value < 0o70000 else value-0o100000
                argument = ('pool', words[pool+offset-BASE])
            else:
                argument = None if long and value >= BASE else value
            keys.append((reg, op, long, argument))
    return instructions, keys


@lru_cache(maxsize=1)
def profile():
    """Infer relocations from corresponding frame entries and aligned code.

    Long operands are omitted only while finding matching instructions.
    A named relocation is accepted only when all aligned uses agree.
    Literal arrays are matched by their complete two-word contents.
    """
    ensure_images()
    old, new = read_words(LINK.analyze.IMAGE), read_words(IMAGE)
    before = SK.procedures(old, BASE, 0o2013, 0o16624)
    after = SK.procedures(new, BASE, 0o2013, 0o16677)
    if len(before) != len(after) or any(a[1:4] != b[1:4]
                                      for a, b in zip(before, after)):
        raise ValueError('BLINK1 no longer has LINK1-compatible procedure frames')
    frames = {a[0]:b[0] for a, b in zip(before, after)}

    def code_address(address):
        anchor = max((a for a in frames if a <= address), default=BASE)
        return address + frames.get(anchor, anchor)-anchor

    entries = [(name, code_address(address)) for name, address in LINK.ENTRIES]
    ends = {name:code_address(address) for name, address in LINK.ENDS.items()}
    ends['STARTUP'] = POOL
    uses = defaultdict(Counter)
    for k, ((name, start), (_, actual)) in enumerate(zip(LINK.ENTRIES, entries)):
        end = LINK.ENDS.get(name, LINK.ENTRIES[k+1][1]
                            if k+1 < len(entries) else LINK.analyze.POOL)
        actual_end = min((a for _, a in entries if a > actual), default=POOL)
        old_insns, old_keys = instruction_keys(old, start, end, LINK.analyze.POOL)
        new_insns, new_keys = instruction_keys(new, actual, actual_end, POOL)
        for match in difflib.SequenceMatcher(None, old_keys, new_keys,
                                             autojunk=False).get_matching_blocks():
            for index in range(match.size):
                _, _, address, long = old_insns[match.a+index]
                target = new_insns[match.b+index][2]
                if long and address >= BASE:
                    uses[address][target] += 1
    relocations = {address:next(iter(targets)) for address, targets in uses.items()
                   if len(targets) == 1}
    relocations.update({address:code_address(address) for _, address in LINK.ENTRIES})
    for address in [0o20017, 0o20201, 0o20203]:
        literal = old[address-BASE:address-BASE+2]
        if address == 0o20017:
            raw = b''.join(word.to_bytes(6, 'big') for word in literal)
            raw = raw.replace(b'-1', b'-2')
            literal = [int.from_bytes(raw[i:i+6], 'big') for i in (0, 6)]
        hits = [a for a in range(POOL, GLOBALS-1)
                if new[a-BASE:a-BASE+2] == literal]
        if len(hits) != 1:
            raise ValueError(f'ambiguous namekey literal {address:05o}')
        relocations[address] = hits[0]
    externals = {name:relocations[address] for name, address in LINK.EXTERNALS.items()}
    return dict(entries=entries, ends=ends, externals=externals,
                relocations=relocations, frames=after)


def reference_address(address):
    if LINK.analyze.GLOBALS <= address < LINK.analyze.RUNTIME:
        return address+GLOBALS-LINK.analyze.GLOBALS
    if address == 0o16611:  # Abort label in the otherwise unchanged main body.
        return 0o16664
    return profile()['relocations'][address]


def load_helpers():
    data = profile()
    result = {int(address, 8):name for address, _, name in
              (line.split() for line in
               (paths.RUNTIME/'analysis/4001-0255-blink1.sym').read_text().splitlines())}
    for address, name in LINK.analyze.load_helpers().items():
        if address in data['relocations']:
            result[data['relocations'][address]] = name
    result.update({address:name for name, address in data['entries']})
    result.update({address:name for name, address in data['externals'].items()})
    result.update({GLOBALS:'P/1D', GLOBALS+0o650:'*INPUT*',
                   GLOBALS+0o706:'*OUTPUT*', POOL:'POOL'})
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
                    note = ' ['+LINK.analyze.describe(words[POOL+offset-BASE])+']'
                elif value in names and (long or reg == 0):
                    note = ' ['+names[value]+']'
                halves.append(f'{reg:02o},{mnemonic},{value:05o}'+note)
            print(f'{address:05o} {halves[0]:72} {halves[1]}')
        return
    inventory = dict(image=str(IMAGE.relative_to(paths.RUNTIME)),
                     basis=str((PROGRAMS/'link1/link1.pas').relative_to(ROOT)), pool=f'{POOL:05o}',
                     globals=f'{GLOBALS:05o}', runtime=f'{RUNTIME:05o}',
                     free=f'{FREE:05o}', code_words=POOL-0o2012,
                     entries=[dict(name=historical.routine(n), address=f'{a:05o}') for n, a in data['entries']],
                     external_entries={n:f'{a:05o}' for n, a in data['externals'].items()},
                     framed_procedures=len(data['frames']))
    (HERE/'inventory.json').write_text(json.dumps(inventory, ensure_ascii=False, indent=2)+'\n')
    (HERE/'names.json').write_text(json.dumps(
        {f'{a:05o}':historical.routine(n) for n,a in data['entries']}, ensure_ascii=False, indent=2)+'\n')
    (HERE/'blink1.sym').write_text(''.join(
        f'{a:05o} {"D" if POOL<=a<RUNTIME or n.startswith("*") else "C"} {n}\n'
        for a, n in sorted(names.items())))
    print(f"{len(data['entries'])} regions, {len(data['frames'])} frames, "
          f'{POOL-0o2012} application words')


if __name__ == '__main__':
    main()
