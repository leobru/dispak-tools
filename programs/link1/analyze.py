#!/usr/bin/env python3
"""Inspect LINK1 while recovering Pascal: analyze.py [lo hi] (octal).

Without arguments, write inventory.json and print the procedure map.
With two addresses, print decoded instruction words with pool annotations.
The reference is extracted from volume 4001, zones 0175-0214, by corpus.py.
Only the ten pages loaded by P/BOOT are inspected as the executable.
"""
from collections import Counter
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
import paths
from paths import ROOT, PROGRAMS, IMAGES
from corpus import read_words, find_volume
from libmatch import operand, mask, match_at, DATA_MODULES
sys.path.insert(0,str(paths.RUNTIME/'linker-runtime'))
import historical_names as historical

BASE, POOL, GLOBALS, RUNTIME, FREE = 0o2000, 0o16631, 0o20461, 0o21426, 0o24716
IMAGE = IMAGES / '4001/0175-link1.bin'
F1 = ('ATX STX MOD XTS A+X A-X X-A AMX XTA AAX AEX ARX AVX AOX A/X A*X '
      'APX AUX ACX ANX E+X E-X ASX XTR RTE YTA *32 EXT E+N E-N ASN NTR '
      'ATI STI ITA ITS MTJ J+M *46 *47').split()
F2 = {0o22:'UTC', 0o23:'WTC', 0o24:'VTM', 0o25:'UTM',
      0o26:'UZA', 0o27:'U1A', 0o30:'UJ', 0o31:'VJM',
      0o32:'IJ', 0o33:'STOP', 0o34:'VZM', 0o35:'V1M',
      0o36:'*36', 0o37:'VLM'}


def ensure_images():
    volume = None
    for stem,zone in [('0175-link1',0o175),('0255-blink1',0o255)]:
        path = IMAGE.parent/(stem+'.bin')
        if path.exists():
            continue
        if volume is None:
            volume = find_volume()
        path.parent.mkdir(parents=True,exist_ok=True)
        env = os.environ.copy()
        env['BESM6_PATH'] = str(volume.parent)
        subprocess.run(['besmtool','dump','4001',f'--start=0{zone:o}',
                        '--length=16','--to-file='+str(path)],
                       env=env,check=True,stdout=subprocess.DEVNULL)


def load_helpers():
    ensure_images()
    ref = read_words(IMAGES/'4001/0255-blink1.bin')
    words = read_words(IMAGE)
    result = {}
    for line in (paths.RUNTIME/'analysis/4001-0255-blink1.sym').read_text().splitlines():
        address, kind, name = line.split()
        start = int(address, 8)
        hits = [BASE+pos for pos in range(RUNTIME-BASE, FREE-BASE-4)
                if mask(ref[start-BASE]) == mask(words[pos])
                and match_at(ref, words, start, start+4, pos, BASE) is not None]
        if len(hits) == 1:
            result[hits[0]] = name
    result.update({0o22644:'P/STAR', 0o22660:'P/LDAR',0o22615:'P/08',
                   0o21721:'P/LNGPAR', 0o22442:'P/WOLN', 0o20461:'P/1D',
                   0o21331:'*INPUT*', 0o21367:'*OUTPUT*',
                   0o22670:'P/4',0o22706:'P/5',0o22704:'P/42',
                   0o22712:'P/52',0o22600:'P/EL',
                   0o23000:'P/WO',0o23001:'P/WH'})
    if (HERE/'names.json').exists():
        result.update({int(k,8):v for k,v in json.loads((HERE/'names.json').read_text()).items()})
    return {a:historical.symbol(n) for a,n in result.items()}


def describe(value):
    if value >> 41 == 0o150:
        mantissa = value & ((1 << 41)-1)
        return str(mantissa-(1 << 41) if mantissa & (1 << 40) else mantissa)
    if value < 256:
        return f'{value:o}C' + (f' {chr(value)!r}' if 32 <= value < 127 else '')
    text = ''.join(chr(b) if 32 <= b < 127 else
                   bytes([b]).decode('koi8-r') if b >= 0o300 else '.'
                   for b in value.to_bytes(6, 'big'))
    return f'{value:016o}C {text!r}'


def main():
    ensure_images()
    words, names = read_words(IMAGE), load_helpers()
    if len(sys.argv) == 3:
        lo, hi = (int(x,8) for x in sys.argv[1:])
        for a in range(lo,hi):
            parts = []
            for shift in (24,0):
                h = words[a-BASE] >> shift & 0xffffff
                reg, op, value, long = operand(h)
                mnemonic = F2[op] if long else F1[op] if op < len(F1) else f'*{op:o}'
                arg = f'{value:05o}' if long else str(value if value<0o70000 else value-0o100000)
                note = ''
                if reg == 0o10 and not long and op <= 0o27:
                    offset = value if value < 0o70000 else value-0o100000
                    note = describe(words[POOL+offset-BASE])
                elif reg == 1 and value >= 0o50:
                    note = names.get(GLOBALS+value, f'g{value:04o}')
                elif value in names and (long or reg == 0):
                    note = names[value]
                parts.append(f'{reg:o},{mnemonic},{arg}' + (f' [{note}]' if note else ''))
            print(f'{a:05o} {parts[0]:68} {parts[1]}' +
                  (f'  <{names[a]}>' if a in names else ''))
        return
    spec = importlib.util.spec_from_file_location('skeleton', PROGRAMS/'acc3/skeleton.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    records = []
    for entry, level, params, frame, length, parent in module.procedures(words, BASE, 0o2013, 0o16624):
        records.append(dict(entry=f'{entry:05o}', level=level,
                            parameter_store_slots=params, frame_words=frame,
                            following_entry_distance=length,
                            parent=f'{parent:05o}' if parent else None))
    report = dict(image=str(IMAGE.relative_to(ROOT)),
                  addresses='octal, ends exclusive; counts decimal',
                  loader_pages=words[9], loaded_words=words[9]*1024,
                  pool=f'{POOL:05o}', globals=f'{GLOBALS:05o}',
                  runtime=f'{RUNTIME:05o}', free=f'{FREE:05o}',
                  code_words=POOL-0o2012, procedures=records,
                  runtime_entries={f'{a:05o}':n for a,n in sorted(names.items()) if a>=RUNTIME})
    (HERE/'inventory.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
    (HERE/'link1.sym').write_text(''.join(f'{a:05o} {"D" if n.startswith("*") or n in DATA_MODULES or POOL<=a<RUNTIME else "C"} {n}\n'
                                        for a,n in sorted(names.items())))
    print(f'{len(records)} framed entries; {POOL-0o2012} application code words')
    for row in records:
        print(f'{row["entry"]} level {row["level"]} frame {row["frame_words"]} '
              f'parent {row["parent"] or "-"}')


if __name__ == '__main__':
    main()
