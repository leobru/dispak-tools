#!/usr/bin/env python3
"""Compile the KOMPON recovery for static comparison; never execute it.

Usage: python3 programs/kompon3/build.py [--source file.pas]
       python3 programs/kompon3/build.py --reference
The initial comparison link uses inert external-service entries. It is not
a runnable replacement for the historical executable.
The compiler copy changes only inline TRUNC and INPUT/OUTPUT allocation order.
"""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
from analyze import module, scopes, CMP
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import COMPILER, PROGRAMS, BUILD
WORK=BUILD/'kompon3'
from corpus import read_words
from libmatch import load_symbols, operand


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source',type=Path,default=HERE/'kompon3.pas')
    parser.add_argument('--reference',action='store_true')
    parser.add_argument('--compiler-source',type=Path,
                        help='base compiler deck (default: working-tree mypas.b6)')
    parser.add_argument('--through',help='compile the declaration prefix ending '
                        'with this top-level routine, with an empty main')
    args=parser.parse_args()
    WORK.mkdir(parents=True,exist_ok=True)
    name='reference' if args.reference else 'candidate'
    compiler_source=(args.compiler_source or COMPILER/'mypas.b6').resolve()
    provenance=dict(compiler_source=str(compiler_source),
                    compiler_patches=['inline_trunc','input_before_output'])
    state=WORK/(name+'-build.json')
    state.write_text(json.dumps(dict(status='building',through=args.through,
                                    **provenance))+'\n')
    (WORK/(name+'.img')).unlink(missing_ok=True)
    (WORK/(name+'-pmd.json')).unlink(missing_ok=True)
    shared=module('kompon_shared_builder',PROGRAMS/'link1/build.py')
    shared.WORK=WORK
    env=os.environ.copy()
    env['BESM6_PATH']=str(WORK.resolve())+':'+env.get('BESM6_PATH',
                            f'{Path.home()}/.besm6:/usr/local/share/besm6')
    env['HOME']=str((WORK/'home').resolve())
    Path(env['HOME']).mkdir(exist_ok=True)
    shared.COMPILER_SOURCE=shared.prepare_compiler(compiler_source)
    shared.compiler(env)
    if args.reference:
        source=(PROGRAMS/'link/link.pas').read_text().replace('p-,','p+,',1)
        name='reference'
    else:
        source=args.source.read_text();name='candidate'
    if args.through:
        from restore import parse
        root,nodes,_=parse(source)
        selected=[n for n in nodes if n['name']==args.through and
                  n['parent'] is root and not n['external']]
        if len(selected)!=1:
            raise ValueError('Not one top-level routine: '+args.through)
        source=source[:selected[0]['end']]+';\nbegin 9999: end.\n'
        source=source.replace('y+,','s5,y+,',1)
    (WORK/(name+'-source.pas')).write_text(source)
    for n,line in enumerate(source.splitlines(),1):
        if len(line)>72:
            raise ValueError(f'Source card {n} exceeds 72 columns')
    stubs=''.join(f' {n}:,NAME,\n 13,UJ,\n ,END,\n'
                  for n in [*shared.EXTERNALS,'P/WH','READSEG',
                            'GETSECT','GETDEF','GETREF'])
    for disk in ['3776','3777']:
        (WORK/disk).write_bytes(b'')
    listing=shared.run_job(name,'*assem\n'+stubs+'*libra:13\n*call yesmemory\n'
        '*trans:newpasc,,320000\n'+source+'\n*perso:311160,cont\n'
        '*perso:320200,cont\n*table:p/coder(w*670112,l*20)\n'
        '*main pascoder\n*execute\n*end file\n``````\nеконец\n',env)
    text=listing.read_text(encoding='utf-8-sig')
    linked=text[text.rfind('*MAIN PASCODER'):]
    if 'HEBEPHAЯ ДЛИHA' in linked or not (WORK/'3777').stat().st_size:
        raise ValueError('Link did not dump an image; see '+str(listing))
    image=WORK/(name+'.img')
    image.unlink(missing_ok=True)
    subprocess.run(['besmtool','dump','3777','--start=0112','--length=16',
                    '--to-file='+str(image)],env=env,check=True,stdout=subprocess.DEVNULL)
    words=read_words(image)
    symbols={s.name:s.address for s in load_symbols(listing)}
    pool=words[0o12]>>24&0o77777
    tables=CMP.pmd(words,pool,symbols['P/1D'])
    inventory=scopes(words,tables,pool)
    if args.through:
        # File/startup metadata can lie between the final declared routine
        # and MAIN. Do not attribute it to that routine's body.
        last=inventory[-2]
        end=max(a+1 for a in range(int(last['entry'],8),int(last['end'],8))
                if any(operand(h)[1:]==(0o30,symbols['P/E'],True)
                       for h in (words[a-0o2000]>>24,
                                 words[a-0o2000]&0xffffff)))
        # The empty main consists of its line/stack check and UJ P/E.
        check=words[end-2-0o2000]
        if (operand(check>>24)[:2]==(0o16,0o24) and
                operand(check&0xffffff)==(0o15,0o31,symbols['P/SC'],True)):
            end-=2
        last['end']=f'{end:05o}'
        last['words']=end-int(last['entry'],8)
    (WORK/(name+'-pmd.json')).write_text(json.dumps(inventory,ensure_ascii=False,indent=2)+'\n')
    state.write_text(json.dumps(dict(status='complete',through=args.through,
                                    **provenance))+'\n')
    print(f'{len(inventory)} scopes; pool {pool:05o}; P/1D {symbols["P/1D"]:05o}')
    print('Image:',image)


if __name__=='__main__':
    main()
