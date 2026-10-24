#!/usr/bin/env python3
"""Build private PERSO libraries, link new programs, and verify recovered words.

Usage:
  python3 runtime/build.py library [--profile monitor]
  python3 runtime/build.py run program.pas [--profile monitor]
  python3 runtime/build.py golden [--profile monitor]
  python3 runtime/build.py check

All writable volumes and job/listing/image artifacts live in runtime/build.
The standard Pascal library may provide the compiler and loader, but runtime
helpers selected from it are rejected by the loader-map audit.
"""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys

from corpus import ROOT, BASE, read_words
from recover import generate
sys.path.insert(0,str(ROOT))
from libmatch import load_symbols

DIRECTORY=Path(__file__).resolve().parent
HEADER='''user 419900зс5^
dis 31(2113)32(77)33(2148-440)34(2048)66(3777-wr)67(3776-wr)^
eeb1a3
*name
'''
BOOT='''*no li
*assem
 P/BOOT:,NAME,
 P/CODER:,SUBP,
 PROGRAM:,SUBP,
 ,WTC,P/CODER+2
 1,VTM,
 *1:1,UTM,-1
 1,VZM,PROGRAM
 ,ARX,=100 0000 0001
 ,ATX,P/CODER
 ,*70,P/CODER
 ,XTA,P/CODER
 ,UJ,*1
 ,END,
*table:p/coder(w*660000,l*20)
*main pascoder
*execute
*end file
``````
еконец
'''


def environment(work):
    env=os.environ.copy()
    default=f'{Path.home()}/.besm6:/usr/local/share/besm6'
    env['BESM6_PATH']=str(work)+':'+env.get('BESM6_PATH',default)
    return env


def job(work,name,cards):
    work.mkdir(parents=True,exist_ok=True)
    for volume in ('3776','3777'):
        p=work/volume
        if not p.exists():
            p.touch()
    path=work/(name+'.b6')
    path.write_text(HEADER+cards)
    listing=work/(name+'.lst')
    with listing.open('w') as stream:
        try:
            result=subprocess.run(['dispak','--path='+environment(work)['BESM6_PATH'],
                                   '-l',str(path)],stdin=subprocess.DEVNULL,
                                  stdout=stream,stderr=subprocess.STDOUT,
                                  env=environment(work),timeout=45)
        except subprocess.TimeoutExpired as exc:
            raise RuntimeError(f'DISPAK timed out: {listing}') from exc
    text=listing.read_text(encoding='utf-8-sig')
    fold=str.maketrans('ABCEHKMOPTXY','АВСЕНКМОРТХУ')
    errors=[]
    for line in text.splitlines():
        normalized=line.translate(fold)
        if 'ОШИБ' in normalized:
            m=re.search(r'(\d+)\s*$',normalized)
            if m and int(m[1]):
                errors.append(line)
    normalized=text.translate(fold)
    fatal=any(message in normalized for message in (
        'БЫЛИ ОШИБКИ ВВОДА','ПЕРЕПОЛНЕНА ТАБЛИЦА','ОТСУТСТВУЕТ',
        'НЕВЕРНАЯ ДЛИНА'))
    if result.returncode or errors or fatal or 'КОНЕЦ ЗАДАЧИ' not in text:
        raise RuntimeError(f'DISPAK failed: {listing}\n'+'\n'.join(errors))
    return listing


def library(profile,with_gaps=False):
    meta=generate(profile,DIRECTORY)
    work=DIRECTORY/'build'/profile
    directory=DIRECTORY/'profiles'/profile
    source=''.join((directory/name).read_text()
                   for name in meta.get('sources',['runtime.madlen']))
    if with_gaps:
        for index,(before,after) in enumerate(zip(meta['chunks'],meta['chunks'][1:])):
            gap=int(after['start'],8)-int(before['end'],8)
            if gap:
                filler=f' RTGAP{index}:,NAME,\n ,BSS,{gap}\n ,END,\n'
                source=source.replace(f' {after["name"]}:,NAME,',
                                      filler+f' {after["name"]}:,NAME,')
    if meta.get('helper_sources'):
        source+=''.join((directory/name).read_text() for name in meta['helper_sources'])
    cards='*call ficmemory\n*assem\n'+source+'*to perso:670100\n*end file\n``````\nеконец\n'
    job(work,'library',cards)
    print(f'Private PERSO: {work}/3776 zone 0100')
    return work,meta


def dump(work,name,listing):
    target=work/(name+'.img')
    symbols={s.name:s.address for s in load_symbols(listing)}
    zones=(symbols['FREE']-BASE+1023)//1024
    subprocess.run(['besmtool','dump','3777','--start=0','--length='+str(zones),
                    '--to-file='+str(target)],env=environment(work),check=True,
                   stdout=subprocess.DEVNULL)
    if target.stat().st_size!=zones*6144:
        raise ValueError(f'incomplete image dump: {target}')
    return target


def relocated_address(target,metadata,symbols):
    for chunk in metadata['chunks']:
        start,end=int(chunk['start'],8),int(chunk['end'],8)
        if start<=target<end:
            return symbols[chunk['name']]+target-start
    for name,c in metadata['common'].items():
        start=int(c['address'],8)
        if start<=target<start+c['words']:
            return symbols[name]+target-start
    raise ValueError(f'unknown relocation target {target:05o}')


def expected_word(original,address,metadata,symbols):
    value=original
    for r in metadata['relocations']:
        if int(r['word'],8)!=address:
            continue
        target=int(r['target'],8)
        relocated=relocated_address(target,metadata,symbols)
        if r['half']=='data':
            shift,width=r['shift'],r['width']
        else:
            shift=24 if r['half']=='L' else 0
            width=r['width']
        if width==12 and relocated>0o7777:
            raise ValueError(f'short address overflow at {address:05o}: {relocated:05o}')
        mask=((1<<width)-1)<<shift
        value=(value&~mask)|(relocated<<shift)
    return value


def check_image(image,listing,meta,original_placement=False):
    symbols={s.name:s.address for s in load_symbols(listing)}
    loaded=[c for c in meta['chunks'] if c['name'] in symbols]
    if not loaded:
        raise ValueError('recovered modules missing from loader map')
    if original_placement and len(loaded)!=len(meta['chunks']):
        raise ValueError('golden link omitted recovered modules')
    deltas={c['name']:symbols[c['name']]-int(c['start'],8) for c in loaded}
    if original_placement and any(deltas.values()):
        raise ValueError(f'golden placement differs: {deltas}')
    ref=read_words(ROOT/meta['source'])
    built=read_words(image)
    for name,address in meta['exports'].items():
        owner=next(c for c in meta['chunks']
                   if int(c['start'],8)<=int(address,8)<int(c['end'],8))
        if owner not in loaded:
            if name in symbols:
                raise ValueError(f'{name}: entry present without its recovered module')
            continue
        expected=relocated_address(int(address,8),meta,symbols)
        if symbols.get(name)!=expected:
            raise ValueError(f'{name}: public entry did not resolve to the recovered module')
    mismatches=[]
    addresses=[a for chunk in loaded
               for a in range(int(chunk['start'],8),int(chunk['end'],8))]
    for address in addresses:
        target=relocated_address(address,meta,symbols)
        expected=expected_word(ref[address-BASE],address,meta,symbols)
        actual=built[target-BASE]
        if expected!=actual:
            mismatches.append(f'{address:05o} -> {target:05o}: '
                              f'{expected:016o} != {actual:016o}')
    for name,c in meta['common'].items():
        if name not in symbols:
            if original_placement:
                raise ValueError(f'{name}: golden common missing')
            continue
        original=int(c['address'],8)
        if original_placement and symbols[name]!=original:
            raise ValueError(f'{name}: golden common address changed')
        count=c.get('initialize',0)
        if built[symbols[name]-BASE:symbols[name]-BASE+count] != ref[original-BASE:original-BASE+count]:
            raise ValueError(f'{name}: initial constants changed')
    core=read_words(ROOT/'тестац.bin')
    for name,start,count in [('P/3',0o4016,4),('P/6A',0o4037,2)]:
        if name not in meta.get('core_helpers',[]) or name not in symbols:
            continue
        expected=core[start-BASE:start-BASE+count]
        if name=='P/6A':
            expected[-1]=(expected[-1]&~0o77777)|symbols['P/7A']
        if built[symbols[name]-BASE:symbols[name]-BASE+count]!=expected:
            raise ValueError(f'{name}: recovered core helper changed')
    if mismatches:
        raise ValueError(f'{len(mismatches)} runtime word mismatches:\n'+'\n'.join(mismatches[:25]))
    print(f'Compared {len(addresses)} runtime words and common constants exactly; relocations '+
          ', '.join(f'{name} {delta:+o}' for name,delta in deltas.items()))
    return symbols,deltas


def audit(listing,meta):
    symbols=load_symbols(listing)
    names={s.name for s in symbols}
    allowed=(set(meta['exports'])|set(meta['common'])|set(meta.get('core_helpers',[]))|
             {c['name'] for c in meta['chunks']}|{'P/BOOT','P/CODER','PASCODER'})
    unexpected=sorted(n for n in names if (n.startswith('P/') or n.startswith('PAS')) and n not in allowed)
    # Even a same-named helper is a fallback if the loader fetched its object
    # from the installed library rather than from our PERSO.
    imported=[]
    active=False
    fold=str.maketrans('ABCEHKMOPTXY','АВСЕНКМОРТХУ')
    for line in listing.read_text(encoding='utf-8-sig').splitlines():
        if 'ПОДПРОГРАММЫ ИЗ БИБЛИОТЕКИ' in line.translate(fold):
            active=True
            continue
        if active and '====' in line:
            active=False
        elif active:
            imported.extend(n for n in line.split() if n.startswith(('P/','PAS')))
    unexpected=sorted(set(unexpected+imported))
    if unexpected:
        raise ValueError('unsupported helpers resolved from another library: '+', '.join(unexpected))


def golden(profile):
    work,meta=library(profile,True)
    ref=read_words(ROOT/meta['source'])
    config=json.loads((DIRECTORY/'profiles.json').read_text())[profile]
    common_start=min(int(c['address'],8) for c in config['common'].values())
    prefix=['*libra:13','*call ficmemory','*assem',' GOLDEN:,NAME,',
            ' PROGRAM:,ENTRY,']
    for name,c in config['common'].items():
        prefix.append(f' {name}:,LC,{c["words"]}')
    for index,chunk in enumerate(meta['chunks']):
        if index and int(chunk['start'],8)>int(meta['chunks'][index-1]['end'],8):
            prefix.append(f' RTGAP{index-1}:,SUBP,')
        prefix.append(f' {chunk["name"]}:,SUBP,')
    # P/BOOT occupies 02000..02010; reserve the original user-code/pool area.
    # Only the dummy PROGRAM's first word executes, after the image is dumped.
    prefix += [' ,*74,']
    prefix += [f' ,LOG,{w:016o}' for w in ref[0o2012-BASE:common_start-BASE]]
    prefix += [' ,END,','*perso:311160,cont','*perso:670100,cont']
    listing=job(work,'golden','\n'.join(prefix)+'\n'+BOOT)
    image=dump(work,'golden',listing)
    audit(listing,meta)
    check_image(image,listing,meta,True)


def run(profile,source):
    work,meta=library(profile)
    # Keep each link's artifacts and private disk images independent.
    runwork=work/('run-'+source.stem)
    runwork.mkdir(exist_ok=True)
    (runwork/'3776').write_bytes((work/'3776').read_bytes())
    pre=source.with_suffix('.pre')
    cards=pre.read_text() if pre.exists() else ''
    cards+='*libra:13\n*call ficmemory\n*trans:newpasc,,320000\n'
    if meta.get('compiler_prefix'):
        cards+=meta['compiler_prefix']+'\n'
    cards+=source.read_text()+'\n*perso:311160,cont\n*perso:670100,cont\n'
    listing=job(runwork,'program',cards+BOOT)
    image=dump(runwork,'program',listing)
    audit(listing,meta)
    check_image(image,listing,meta)
    text=execute(runwork,image,listing)
    print(f'Program listing: {listing}')
    return dict(listing=str(listing.relative_to(DIRECTORY)),
                image=str(image.relative_to(DIRECTORY)),output=text)


def execute(work,image,listing):
    symbols={s.name:s.address for s in load_symbols(listing)}
    entry=symbols['PROGRAM']
    limit=symbols['FREE']
    cards=['USER 419900^','BEG '+f'{entry:o}'+'^','E','B 2000']
    for word in read_words(image)[:limit-BASE]:
        octal=f'{word:016o}'
        cards.append('C '+' '.join(octal[i:i+4] for i in range(0,16,4)))
    cards += ['E','FINISH']
    deck=work/'execute.b6'
    deck.write_text('\n'.join(cards)+'\n')
    output=work/'execute.out'
    with output.open('w') as stream:
        result=subprocess.run(['dispak','--bootstrap','--no-insn-check','-l',str(deck)],
                              stdin=subprocess.DEVNULL,stdout=stream,stderr=subprocess.STDOUT,
                              env=environment(work),timeout=30)
    text=output.read_text(encoding='utf-8-sig')
    if result.returncode:
        raise RuntimeError(f'program failed: {output}\n{text[-2000:]}')
    print(text.rstrip())
    return text


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=['library','golden','run','check'])
    parser.add_argument('source',nargs='?',type=Path)
    parser.add_argument('--profile',default='monitor')
    args=parser.parse_args()
    if args.action=='run':
        if args.source is None:
            parser.error('run requires program.pas')
        run(args.profile,args.source.resolve())
    elif args.action=='golden':
        golden(args.profile)
    elif args.action=='check':
        from check import check
        check()
    else:
        library(args.profile)


if __name__=='__main__':
    main()
