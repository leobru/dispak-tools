#!/usr/bin/env python3
"""Export PAK's historical Pascal runtime as relocatable Madlen source.

Usage: python3 programs/pak/recover-runtime.py [--edition 2053|2113]
Reads pak[‑2113].bin/.sym and writes pak[‑2113].pre. This is an archival extraction,
not a build step: subsequent builds assemble the saved text without pak.bin.
Three (2053) or four (2113) objects group the recovered runtime; original object
boundaries are not asserted. Data ranges and embedded address words are
explicitly distinguished from executable instructions.
"""
import argparse
from collections import defaultdict
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import BUILD
from libmatch import operand, words

BASE, LO, HI = 0o2000, 0o10736, 0o11547
SHORT = ['ATX', 'STX', 'MOD', 'XTS', 'A+X', 'A-X', 'X-A', 'AMX',
         'XTA', 'AAX', 'AEX', 'ARX', 'AVX', 'AOX', 'A/X', 'A*X',
         'APX', 'AUX', 'ACX', 'ANX', 'E+X', 'E-X', 'ASX', 'XTR',
         'RTE', 'YTA', '*32', 'EXT', 'E+N', 'E-N', 'ASN', 'NTR',
         'ATI', 'STI', 'ITA', 'ITS', 'MTJ', 'J+M', '*46', '*47']
LONG = {0o22: 'UTC', 0o23: 'WTC', 0o24: 'VTM', 0o25: 'UTM',
        0o26: 'UZA', 0o27: 'U1A', 0o30: 'UJ', 0o31: 'VJM',
        0o32: 'IJ', 0o33: 'STOP', 0o34: 'VZM', 0o35: 'V1M',
        0o36: '*36', 0o37: 'VLM'}
DATA = [(0o10757, 0o10772), (0o11023, 0o11074),
        (0o11150, 0o11157), (0o11213, 0o11214),
        (0o11264, 0o11302), (0o11335, 0o11364),
        (0o11402, 0o11404), (0o11420, 0o11422),
        (0o11437, 0o11440), (0o11445, 0o11450),
        (0o11461, 0o11462), (0o11465, 0o11467),
        (0o11475, 0o11476), (0o11506, 0o11513),
        (0o11526, 0o11533), (0o11535, 0o11542),
        (0o11546, 0o11547)]


def main():
    global LO,HI,DATA
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--edition',choices=['2053','2113'],default='2053')
    args=parser.parse_args()
    stem='pak' if args.edition=='2053' else 'pak-2113'
    if args.edition=='2113':
        LO,HI=0o10752,0o11563
        DATA=[(0o10764,0o10777),(0o11030,0o11101),
              (0o11155,0o11164),(0o11220,0o11221),
              (0o11271,0o11307),(0o11342,0o11371),
              (0o11416,0o11420),(0o11434,0o11436),
              (0o11453,0o11454),(0o11472,0o11474),
              (0o11477,0o11501),(0o11507,0o11511),
              (0o11521,0o11526),(0o11536,0o11537),
              (0o11542,0o11547),(0o11551,0o11556),
              (0o11562,0o11563)]
    image = words(BUILD / 'pak' / (stem+'.bin'))
    entries = defaultdict(list)
    all_symbols={}
    for line in (HERE / (stem+'.sym')).read_text().splitlines():
        if not line or line.startswith('#'):
            continue
        address, _, name = line.split()
        address = int(address, 8)
        all_symbols[name]=address
        if LO <= address < HI:
            entries[address].append(name)
    chunks=([(LO,0o11157),(0o11157,0o11364),(0o11364,HI)]
            if args.edition=='2053' else
            [(LO,0o11164),(0o11164,0o11371),(0o11371,0o11454),(0o11454,HI)])
    module_names=[None,'P/CO','P/3','SYSTIME'] if args.edition=='2053' else [None,'P/2','P/3','SYSTIME','P/1']
    external = {all_symbols[n]:n for n in ['P/1D','*OUTPUT*','PASZERO*']}
    external[0o2007]='P/CODER+1'
    out=[]
    for chunk,(lo,hi) in enumerate(chunks,1):
        labels={a for a in entries if lo<=a<hi}
        dependencies=set()
        def address(value):
            if value in external:
                return external[value]
            if lo<=value<hi:
                labels.add(value)
                return f'R{value:05o}'
            for other,(start,end) in enumerate(chunks,1):
                if start<=value<end:
                    dependencies.add(other)
                    return f'PAKRT{other}'+(f'+{value-start:o}B' if value!=start else '')
            return f'{value:o}B' if value else ''
        def instruction(half):
            reg,op,value,long=operand(half)
            mnemonic=LONG[op] if long else SHORT[op] if op<len(SHORT) else f'*{op:o}'
            if long and op==0o31 and not reg:
                mnemonic='Z31'
            relocatable=long or (not reg and (op<=0o27 or op in (0o64,0o70,0o71)))
            arg=address(value) if relocatable else f'{value:o}B' if value else ''
            return f'{reg if reg else ""},{mnemonic},{arg}'
        body=[]
        for a in range(lo,hi):
            word=image[a-BASE]
            if any(start<=a<end for start,end in DATA):
                if LO<=word<HI:
                    lines=[',ATX,',',Z00,'+address(word)]
                else:
                    lines=[f',LOG,{word:016o}']
            else:
                left,right=word>>24,word&0xffffff
                lines=[instruction(left)]
                _,op,_,long=operand(left)
                aligns=(long and op in (0o30,0o31)) or (not long and op>=0o50 and op!=0o60)
                if aligns and right==0o2200000:
                    labels.add(a+1)
                else:
                    lines.append(instruction(right))
            body.append((a,lines))
        out += ['*assem',f'C Pascal runtime: original {lo:05o}-{hi-1:05o}.',
                'C PAKRT grouping is new; original object boundaries are unknown.',
                f' {module_names[chunk]}:,NAME,',' P/1D:,LC,40',' *OUTPUT*:,LC,30',
                ' PASZERO*:,LC,1',' P/CODER:,SUBP,']
        out += [f' PAKRT{other}:,SUBP,' for other in sorted(dependencies)]
        out += [f' PAKRT{chunk}:,ENTRY,']
        for a,lines in body:
            out += [f' {name}:,ENTRY,' for name in entries[a]
                    if not (a==lo and name==module_names[chunk])]
            prefix=f' R{a:05o}:' if a in labels else ' '
            out.append(prefix+lines[0])
            out += [' '+line for line in lines[1:]]
        if chunk==len(chunks):
            out += ['C Standard P/1D constants and original PASZERO* value.',' ,DATA,']
            for off in range(0o50):
                prefix=' INIT:' if not off else ' '
                out.append(prefix+f',LOG,{image[all_symbols['P/1D']+off-BASE]:016o}')
            out += [f' ZEROCHAR:,LOG,{image[all_symbols['PASZERO*']-BASE]:016o}',
                    ' 40,SET,INIT',' 1,,P/1D',
                    ' 1,SET,ZEROCHAR',' 1,,PASZERO*']
        out += [' ,END,','']
    (HERE/(stem+'.pre')).write_text('\n'.join(out))
    print(f'Wrote {HI - LO} runtime words and P/1D initialization to {stem}.pre')


if __name__ == '__main__':
    main()
