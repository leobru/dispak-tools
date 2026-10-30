#!/usr/bin/env python3
"""Inventory KOMPON 2.02/3 and map a debug build of LINK onto its scopes.

Usage: python3 programs/kompon3/analyze.py
Requires runtime/build/kompon3/reference.img and reference.lst for mapping.
The historical image is extracted read-only from 2248/2560-2577.
"""
from bisect import bisect_right
from collections import Counter, defaultdict
import difflib
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'runtime' for p in HERE.parents
                            if (p/'runtime/paths.py').exists())))
from paths import TOOLS, RUNTIME, PROGRAMS, BUILD
sys.path.insert(1, str(TOOLS))
WORK = BUILD/'kompon3'
from corpus import read_words
from libmatch import load_symbols, operand


def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    result=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


CMP = module('kompon_comparison',RUNTIME/'linker-runtime/compare2248.py')
SK = module('kompon_frames',PROGRAMS/'acc3/skeleton.py')


def scopes(words, tables, pool):
    entry = 0o2011 if words[0]==0o0230201006400000 else 0o2012
    startup=words[entry-0o2000]&0o77777
    frames=SK.procedures(words,0o2000,entry+1,pool)
    main=next((operand(h)[2] for w in reversed(words[startup-0o2000:pool-0o2000])
              for h in (w&0xffffff,w>>24)
              if operand(h)[1]==0o30 and operand(h)[3] and
              entry < operand(h)[2] < startup),startup)
    result=[]
    enum_starts={pool+((int(v['descriptor'],8)&((1<<33)-1))>>18)
                 for t in tables for v in t['variables']
                 if (int(v['descriptor'],8)>>15)&7==3}
    boundaries=enum_starts|{int(t['table'],8) for t in tables}
    enum_names={}
    for start in sorted(enum_starts):
        limit=min((p for p in boundaries if p>start),default=pool+4096)
        names=[]
        for p in range(start,min(limit,start+128)):
            name=CMP.text(words[p-0o2000])
            if not re.fullmatch('[A-ZА-Я][A-ZА-Я0-9]*',name):
                break
            names.append(name)
        enum_names[start]=names
    for index,table in enumerate(tables):
        p=int(table['reference'],8)
        if index+1 == len(tables):
            start,level,params,frame=main,1,0,0
        else:
            start,level,params,frame,*_=max(f for f in frames if f[0]<=p)
            if p-start>6:
                raise ValueError(f'PMD reference too far from frame: {p:o}/{start:o}')
        variables=[]
        for v in table['variables']:
            d=int(v['descriptor'],8)
            hint=['real','integer','char','enum','array','set_or_record','file','unknown'][(d>>15)&7]
            indirect=bool(d>>47)
            size=(d>>33)&0o37777
            variable=dict(name=v['name'],offset=f'{d&0o77777:04o}',
                                  size=(d>>33)&0o37777,kind=(d>>15)&7,
                                  indirect=indirect,descriptor=v['descriptor'],
                                  type_hint=hint,storage_words=1 if indirect else size)
            if hint=='enum':
                p=pool+((d&((1<<33)-1))>>18)
                variable.update(enum_table=f'{p:05o}',enumerators=enum_names[p])
            variables.append(variable)
        result.append(dict(name=table['name'],entry=f'{start:05o}',
                           level=level,parameters=params,frame=frame,
                           line=table['line'],pmd=table['table'],variables=variables))
    ordered=sorted(result,key=lambda x:int(x['entry'],8))
    for i,row in enumerate(ordered):
        end=int(ordered[i+1]['entry'],8) if i+1<len(ordered) else startup
        row['end']=f'{end:05o}'
        row['words']=end-int(row['entry'],8)
    return ordered


def instructions(words,entry,pool,hi=None,wild_offsets=False):
    keys,positions=[],[]
    for a in range(entry,pool if hi is None else hi):
        for side,h in enumerate((words[a-0o2000]>>24,words[a-0o2000]&0xffffff)):
            if h==0o2200000:
                continue
            r,o,v,l=operand(h)
            if r==0o10 and not l and o<=0o27:
                off=v if v<0o70000 else v-0o100000
                v=('constant',words[pool+off-0o2000])
            elif wild_offsets and not l and 1<=r<=7 and o<=0o27:
                v='frame-offset'
            elif l and v>=0o2000:
                v='address'
            elif l and r==0o16 and o==0o24:
                v='line'
            keys.append((r,o,v,l));positions.append((a,side))
    return keys,positions


def main():
    WORK.mkdir(parents=True,exist_ok=True)
    image=WORK/'original.bin'
    subprocess.run(['besmtool','dump','2248','--start=02560','--length=16',
                    '--to-file='+str(image)],check=True,stdout=subprocess.DEVNULL)
    old=read_words(image)
    original_tables=json.loads((RUNTIME/'linker-runtime/2248-mode3-pmd.json').read_text())
    old_scopes=scopes(old,original_tables,0o22300)
    (HERE/'inventory.json').write_text(json.dumps(old_scopes,ensure_ascii=False,indent=2)+'\n')
    reference=WORK/'reference.img'
    if not reference.exists():
        print('Historical inventory written; reference build is absent.')
        return
    new=read_words(reference)
    symbols={s.name:s.address for s in load_symbols(WORK/'reference.lst')}
    pool=new[0o12]>>24&0o77777
    tables=CMP.pmd(new,pool,symbols['P/1D'])
    new_scopes=scopes(new,tables,pool)
    (WORK/'reference-pmd.json').write_text(json.dumps(new_scopes,ensure_ascii=False,indent=2)+'\n')
    a,pa=instructions(old,0o2012,0o22300)
    b,pb=instructions(new,0o2013,pool)
    oa=[int(x['entry'],8) for x in old_scopes]
    nb=[int(x['entry'],8) for x in new_scopes]
    votes=defaultdict(Counter)
    for block in difflib.SequenceMatcher(None,a,b,autojunk=False).get_matching_blocks():
        if block.size<4:
            continue
        for i,j in zip(range(block.a,block.a+block.size),range(block.b,block.b+block.size)):
            x,y=bisect_right(oa,pa[i][0])-1,bisect_right(nb,pb[j][0])-1
            if x>=0 and y>=0:
                votes[new_scopes[y]['name']][old_scopes[x]['name']]+=1
    mapping=[]
    for row in new_scopes:
        candidates=votes[row['name']].most_common(3)
        mapping.append(dict(modern=row['name'],candidates=candidates))
        print(row['name'],candidates)
    (HERE/'mapping.json').write_text(json.dumps(mapping,ensure_ascii=False,indent=2)+'\n')
    global_votes=defaultdict(Counter)
    local_votes={}
    service_votes=defaultdict(Counter)
    symbol_names={s.address:s.name for s in load_symbols(WORK/'reference.lst')}
    def owner(vs,offset):
        return next((v['name'] for v in vs if int(v['offset'],8)<=offset<
                     int(v['offset'],8)+(1 if v['indirect'] else v['size'])),None)
    for row in mapping:
        if not row['candidates'] or row['modern']=='SECTID':
            continue
        n=next(x for x in new_scopes if x['name']==row['modern'])
        o=next(x for x in old_scopes if x['name']==row['candidates'][0][0])
        aa,pp=instructions(old,int(o['entry'],8),0o22300,int(o['end'],8),True)
        bb,qq=instructions(new,int(n['entry'],8),pool,int(n['end'],8),True)
        locals=defaultdict(Counter)
        for block in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_matching_blocks():
            for i,j in zip(range(block.a,block.a+block.size),range(block.b,block.b+block.size)):
                ap,aside=pp[i];bp,bside=qq[j]
                r,op,av,long=operand(old[ap-0o2000]>>(24 if aside==0 else 0)&0xffffff)
                _,_,bv,_=operand(new[bp-0o2000]>>(24 if bside==0 else 0)&0xffffff)
                if long and op in [0o30,0o31] and av>=0o27467 and bv in symbol_names:
                    service_votes[f'{av:05o}'][symbol_names[bv]]+=1
                if long or op>0o27:
                    continue
                if r==1:
                    an=owner(old_scopes[-1]['variables'],av)
                    bn=owner(new_scopes[-1]['variables'],bv)
                    if an and bn:global_votes[bn][an]+=1
                elif r==n['level']==o['level']:
                    an=owner(o['variables'],av);bn=owner(n['variables'],bv)
                    if an and bn:locals[bn][an]+=1
        local_votes[row['modern']]={k:v.most_common() for k,v in locals.items()}
    bindings=dict(globals={k:v.most_common() for k,v in global_votes.items()},locals=local_votes)
    (HERE/'bindings.json').write_text(json.dumps(bindings,ensure_ascii=False,indent=2)+'\n')
    (HERE/'services.json').write_text(json.dumps({k:v.most_common() for k,v in service_votes.items()},ensure_ascii=False,indent=2)+'\n')


if __name__=='__main__':
    main()
