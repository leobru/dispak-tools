#!/usr/bin/env python3
"""Annotate original KOMPON routines: disassemble.py NAME [NAME ...]."""
from pathlib import Path
import json
import sys

HERE=Path(__file__).resolve().parent
sys.path[:0]=[str(HERE.parent),str(HERE.parents[1])]
from corpus import read_words
from libmatch import operand

F1=('ATX STX MOD XTS A+X A-X X-A AMX XTA AAX AEX ARX AVX AOX A/X A*X '
    'APX AUX ACX ANX E+X E-X ASX XTR RTE YTA *32 EXT E+N E-N ASN NTR '
    'ATI STI ITA ITS MTJ J+M *46 *47').split()
F2={0o22:'UTC',0o23:'WTC',0o24:'VTM',0o25:'UTM',0o26:'UZA',0o27:'U1A',
    0o30:'UJ',0o31:'VJM',0o34:'VZM',0o35:'V1M',0o36:'*36',0o37:'VLM'}


def literal(v):
    if v>>41==0o150:
        n=v&((1<<41)-1)
        return str(n-(1<<41) if n&(1<<40) else n)
    raw=v.to_bytes(6,'big')
    if all(b in [0,4,10,12] or 32<=b<127 or b>=0o300 for b in raw) and any(raw):
        return '"'+''.join(chr(b) if 32<=b<127 else
            bytes([b]).decode('koi8-r') if b>=0o300 else f'_{b:03o}' for b in raw)+'"'
    return f'{v:016o}C'


def main():
    rows=json.loads((HERE/'inventory.json').read_text())
    services=json.loads((HERE/'services.json').read_text())
    names={int(r['entry'],8):r['name'] for r in rows}
    names.update({int(k,8):v[0][0] for k,v in services.items()})
    # Reviewed entries; alignment votes can confuse the two prologue calls.
    names.update({0o27473:'P/SC',0o27600:'P/DA',0o27765:'P/LNGPAR',
                  0o30723:'P/WX',0o27430:'*OUTPUT*',0o27466:'PADCHAR*'})
    words=read_words(HERE.parent/'build/kompon3/original.bin')
    def varname(vs,offset):
        for v in vs:
            base=int(v['offset'],8)
            if base<=offset<base+v['storage_words']:
                return v['name']+(f'+{offset-base:o}' if offset!=base else '')
        return f'{offset:o}'
    for row in rows:
        if sys.argv[1:] and row['name'] not in sys.argv[1:]:
            continue
        print('\n;',row['entry'],row['name'],'frame',row['frame'],'PMD line',row['line'])
        for a in range(int(row['entry'],8),int(row['end'],8)):
            parts=[]
            for h in [words[a-0o2000]>>24,words[a-0o2000]&0xffffff]:
                r,o,v,long=operand(h)
                mnemonic=F2.get(o,f'Z{o:o}') if long else F1[o] if o<len(F1) else f'*{o:o}'
                arg=f'{v:o}'
                if r==0o10 and not long and o<=0o27:
                    off=v if v<0o70000 else v-0o100000
                    arg='='+literal(words[0o22300+off-0o2000])
                elif not long and o<=0o27 and r==row['level']:
                    arg=varname(row['variables'],v)
                elif not long and o<=0o27 and r==1:
                    arg=varname(rows[-1]['variables'],v)
                elif long and v in names:
                    arg=names[v]
                parts.append(f'{r:02o},{mnemonic},{arg}')
            print(f'{a:05o} '+ ' / '.join(parts))


if __name__=='__main__':
    main()
