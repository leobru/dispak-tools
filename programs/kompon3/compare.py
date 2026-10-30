#!/usr/bin/env python3
"""Compare recovered KOMPON scopes, types and instructions after build.py.

Usage: python3 programs/kompon3/compare.py [ROUTINE ...]
Writes comparison.json and build/kompon3/comparison.txt. This is a
relocation-tolerant diagnostic, not a word-identity or execution check.
"""
from bisect import bisect_right
import difflib
import json
from pathlib import Path
import sys

HERE=Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'runtime' for p in HERE.parents
                            if (p/'runtime/paths.py').exists())))
from paths import TOOLS, BUILD
sys.path.insert(1,str(TOOLS))
WORK=BUILD/'kompon3'
from corpus import read_words
from libmatch import load_symbols, operand
from disassemble import F1, F2

# Typed Pascal aliases of the original generic table service entries.
ALIASES={
    'GETPAIR':'GETFILED','TABPAIR':'TABGET','TABFILE':'TABGET',
    'GETSECT':'TABGET','GETDEF':'TABGET','GETREF':'TABGET',
    'READSEG':'READPAIR','PUTPAIR':'PUTFILED','PUTDEF':'TABPUT',
    'PUTSECT':'TABPUT','PUTREF':'TABPUT','TABSAVE':'TABPUT',
}
KNOWN_ORIGINAL={0o27473:'P/SC',0o27600:'P/DA',
                0o27430:'*OUTPUT*',0o27466:'PADCHAR*',
                0o27765:'P/LNGPAR',0o30723:'P/WX',0o26527:'P/1D'}


def variable(vs, offset):
    for v in vs:
        base=int(v['offset'],8)
        if base<=offset<base+v['storage_words']:
            return v['name']+f'+{offset-base:o}'
    return f'{offset:o}'


def code(words,row,pool,scopes,symbols):
    start,end=int(row['entry'],8),int(row['end'],8)
    scope_names={int(s['entry'],8):s['name'] for s in scopes}
    starts=sorted(scope_names)
    globals_=scopes[-1]['variables']
    gbase=next(a for a,n in symbols.items() if n=='P/1D')
    glimit=max(int(v['offset'],8)+v['storage_words'] for v in globals_)
    # PMD setup and the entry source line are metadata, not body operations.
    body=start+6 if row['level']>1 else start
    keys=[];positions=[]
    for a in range(body,end):
        for side,h in enumerate((words[a-0o2000]>>24,
                                  words[a-0o2000]&0xffffff)):
            r,o,v,long=operand(h)
            if h==0o2200000:
                continue
            mnemonic=F2.get(o,f'Z{o:o}') if long else F1[o] if o<len(F1) else f'*{o:o}'
            arg=f'{v:o}'
            if r==0o10 and not long and o<=0o27:
                off=v if v<0o70000 else v-0o100000
                arg=f'={words[pool+off-0o2000]:016o}'
            elif long and o==0o24 and r==0o16:
                # Source line numbers and temporary address constants are
                # omitted here. The literal disassembly retains them.
                arg='line/address'
            elif long and v in scope_names:
                arg=scope_names[v]
            elif long and v in symbols:
                arg=ALIASES.get(symbols[v],symbols[v])
            elif long and gbase+0o50<=v<gbase+glimit:
                arg='&'+variable(globals_,v-gbase)
            elif long and o==0o24 and r==0o13 and pool<=v<0o70000:
                # Long text has its address in M13 and length in M12.
                halves=[h for w in words[a-0o2000:a-0o2000+3]
                        for h in (w>>24,w&0xffffff)]
                width=next((q for rr,oo,q,ll in map(operand,halves[side+1:])
                            if rr==0o12 and oo==0o24 and ll),None)
                if width is not None:
                    raw=b''.join(w.to_bytes(6,'big')
                          for w in words[v-0o2000:v-0o2000+(width+5)//6])
                    arg='text:'+raw[:width].hex()
            elif long and r==0o10 and o==0o24 and v==pool:
                arg='POOL'
            elif long and start<=v<end:
                arg=f'local+{v-start:o}'
            elif long and o in (0o22,0o23) and r==1:
                arg=variable(globals_,v)
            elif long and o in (0o22,0o23) and r==row['level']:
                arg=variable(row['variables'],v)
            elif not long and r==1 and o<=0o27:
                arg=variable(globals_,v)
            elif not long and r==row['level'] and o<=0o27:
                arg=variable(row['variables'],v)
            elif long and v>=0o2000:
                index=bisect_right(starts,v)-1
                if index>=0 and v<pool:
                    base=starts[index]
                    arg=scope_names[base]+f'+{v-base:o}'
                else:
                    # Keep unresolved addresses visible.
                    arg=f'@{v:05o}'
            keys.append(f'{r:02o},{mnemonic},{arg}')
            positions.append(f'{a:05o}.{"LR"[side]}')
    return keys,positions


def main():
    state=json.loads((WORK/'candidate-build.json').read_text())
    if state['status']!='complete':
        raise ValueError('Candidate build did not complete; comparison refused')
    old=json.loads((HERE/'inventory.json').read_text())
    new=json.loads((WORK/'candidate-pmd.json').read_text())
    ow=read_words(WORK/'original.bin');nw=read_words(WORK/'candidate.img')
    np=nw[0o12]>>24&0o77777
    services=json.loads((HERE/'services.json').read_text())
    osyms={int(a,8):ALIASES.get(v[0][0],v[0][0])
           for a,v in services.items()}
    osyms.update(KNOWN_ORIGINAL)
    nsyms={s.address:ALIASES.get(s.name,s.name)
           for s in load_symbols(WORK/'candidate.lst')}
    olds={s['name']:s for s in old};news={s['name']:s for s in new}
    report=dict(build=state,normalization='PMD entry metadata, padding, source lines, '
                'named services and variable offsets; local branches use '
                'word offsets from the routine entry; '
                'constant operands resolved to values. Not byte identity.',
                missing=[n for n in olds if n not in news],
                extra=[n for n in news if n not in olds],routines=[])
    output=[]
    for name,a in olds.items():
        if name not in news:
            continue
        b=news[name]
        ka,pa=code(ow,a,0o22300,old,osyms)
        kb,pb=code(nw,b,np,new,nsyms)
        sm=difflib.SequenceMatcher(None,ka,kb,autojunk=False)
        av={v['name']:v for v in a['variables']}
        bv={v['name']:v for v in b['variables']}
        types=[]
        for n,v in av.items():
            if n not in bv:
                types.append(dict(name=n,status='missing'));continue
            fields=['offset','kind','indirect','storage_words']
            changes={k:[v[k],bv[n][k]] for k in fields if v[k]!=bv[n][k]}
            if v.get('enumerators')!=bv[n].get('enumerators'):
                changes['enumerators']=[v.get('enumerators'),bv[n].get('enumerators')]
            if changes:
                types.append(dict(name=n,changes=changes))
        types.extend(dict(name=n,status='extra') for n in bv if n not in av)
        row=dict(name=name,original_entry=a['entry'],rebuilt_entry=b['entry'],
                 original_words=a['words'],rebuilt_words=b['words'],
                 frame=[a['frame'],b['frame']],type_differences=types,
                 normalized_body_equal=(ka==kb),
                 original_instructions=len(ka),rebuilt_instructions=len(kb),
                 equal_instructions=sum(m.size for m in sm.get_matching_blocks()))
        report['routines'].append(row)
        if sys.argv[1:] and name not in sys.argv[1:]:
            continue
        output.append(f'\n{name} {a["entry"]}/{b["entry"]}: '
                      f'{a["words"]}/{b["words"]} words; frame {row["frame"]}')
        for tag,i,j,k,l in sm.get_opcodes():
            if tag=='equal':
                continue
            output.extend('- '+p+' '+v for p,v in zip(pa[i:j],ka[i:j]))
            output.extend('+ '+p+' '+v for p,v in zip(pb[k:l],kb[k:l]))
    (HERE/'comparison.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    (WORK/'comparison.txt').write_text('\n'.join(output)+'\n')
    print('Missing:',report['missing'],'Extra:',report['extra'])
    for row in report['routines']:
        if not sys.argv[1:] or row['name'] in sys.argv[1:]:
            print(f'{row["name"]:10} {row["original_words"]:4}/{row["rebuilt_words"]:<4} '
                  f'words, {len(row["type_differences"])} declaration differences')


if __name__=='__main__':
    main()
