#!/usr/bin/env python3
"""Compile LINK1 helpers and compare them structurally with 4001/0175.

Usage: python3 runtime/link1/build.py [--source candidate.pas]

This currently builds only helpers.pas, not the whole linker. FORTRAN
externals have inert link stubs; the compiled helpers are not executed.
Private disks, HOME and all compilation artifacts stay in runtime/build/link1.
The comparison resolves constant-pool operands and named call relocations;
it does not claim bit identity of the original and candidate images.
"""
import argparse
import difflib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
WORK = HERE.parent/'build/link1'
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(ROOT))
from corpus import read_words, sha
from libmatch import load_symbols, operand
spec = importlib.util.spec_from_file_location('link1analyze', HERE/'analyze.py')
analyze = importlib.util.module_from_spec(spec)
spec.loader.exec_module(analyze)

ENTRIES = [('PUTTIME',0o2013), ('PUTPATH',0o2042), ('PATHLEN',0o2070),
           ('NEWPHASE',0o2113), ('FINDKEY',0o2125), ('ENTERKEY',0o2172),
           ('FINDOBJ',0o2312), ('BINDOBJ',0o2353),
           ('PUTSIZE',0o4647), ('PUTCODE',0o4666), ('READREC',0o4707),
           ('READBODY',0o4735), ('READPART',0o4761), ('SKIPREC',0o5003),
           ('SAVEREC',0o5016), ('WRITREC',0o5044), ('LEAPDAY',0o5066),
           ('PUTDATE',0o5100), ('NEXTCHAR',0o2426), ('BADJOB',0o2463),
           ('PUSHCHAR',0o2752), ('INNAME',0o2761), ('SKIPWS',0o2765),
           ('SKIPTAIL',0o2775), ('CONVERT',0o3006), ('SCANINT',0o3034),
           ('SCANDEC',0o3153), ('SCANNAME',0o3176), ('SCANFILE',0o3230),
           ('SCANALFA',0o3312), ('GETTOKEN',0o3335), ('EXPECT',0o3455),
           ('PRINTSEL',0o3641)]
ENDS = {'BINDOBJ':0o2426, 'PUTDATE':0o5170, 'EXPECT':0o3466, 'PRINTSEL':0o3717}
EXTERNALS = {'HASHNAME':0o21540,'CMPNAME':0o21545,'NAMELEN':0o21563,
             'GETSTAMP':0o21675,'NEWKEY':0o22232,'OBJREAD':0o22234,
             'OBJEDIT':0o22236,'NUMOBJS':0o22254,
             'POSITION':0o22252,'SETPOS':0o22250,
             'READPAIR':0o22240,'WRITPAIR':0o22241,'PUTTEMP':0o22243}


def run_job(name, cards, env, timeout=180):
    job = WORK/(name+'.b6')
    listing = WORK/(name+'.lst')
    job.write_text('user 419900зс5^\n'
                   'dis 31(2113)32(77)33(2148-440)34(2048)67(3777-wr)^\n'
                   'eeb1a3\n*name\n'+cards)
    with listing.open('w') as stream:
        result = subprocess.run(['dispak','--path='+env['BESM6_PATH'],'-l',str(job)],
                                env=env, stdin=subprocess.DEVNULL, stdout=stream,
                                stderr=subprocess.STDOUT, timeout=timeout)
    text = listing.read_text(encoding='utf-8-sig',errors='replace')
    errors = re.findall(r'(?m)^ .*ERROR.*$|^ \*{6}.*$', text)
    if result.returncode or re.search(r'IN\s+\d+\s+LINES\s+[1-9]\d*\s+ERRORS',text):
        raise RuntimeError(str(listing)+'\n'+'\n'.join(errors))
    return listing


def compiler(env):
    fingerprint = sha((ROOT/'mypas.b6').read_bytes())
    stamp = WORK/'compiler.json'
    if stamp.exists() and (WORK/'77').exists():
        if json.loads(stamp.read_text()).get('source_sha256') == fingerprint:
            return
    for other in ['acc3/try','fprint','proz','mt']:
        directory = HERE.parent/'build'/other
        saved = directory/'compiler.json'
        if (saved.exists() and (directory/'77').exists() and
                json.loads(saved.read_text()).get('source_sha256') == fingerprint):
            shutil.copyfile(directory/'77',WORK/'77')
            stamp.write_text(json.dumps(dict(source='mypas.b6',source_sha256=fingerprint),indent=2)+'\n')
            return
    spec = importlib.util.spec_from_file_location('morebuild', HERE.parent/'more/build.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    saved_env = os.environ.copy()
    try:
        os.environ.update(env)
        module.rebuild_compiler(WORK)
    finally:
        os.environ.clear()
        os.environ.update(saved_env)
    stamp.write_text(json.dumps(dict(source='mypas.b6',source_sha256=fingerprint),indent=2)+'\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source',type=Path,default=HERE/'helpers.pas')
    args = parser.parse_args()
    args.source = args.source.resolve()
    WORK.mkdir(parents=True,exist_ok=True)
    env = os.environ.copy()
    # Preserve installed disk lookup before assigning the private HOME.
    env['BESM6_PATH'] = str(WORK)+':'+env.get('BESM6_PATH',
                            f'{Path.home()}/.besm6:/usr/local/share/besm6')
    env['HOME'] = str(WORK/'home')
    Path(env['HOME']).mkdir(exist_ok=True)
    compiler(env)
    source = args.source.read_text()
    source = source.replace('% SCANNER_INCLUDE', (HERE/'scanner.pas').read_text())
    for n,line in enumerate(source.splitlines(),1):
        if len(line)>72:
            raise ValueError(f'{args.source}:{n}: card exceeds 72 columns')
    stubs = ''.join(f' {name}:,NAME,\n 13,UJ,\n ,END,\n' for name in EXTERNALS)
    (WORK/'3777').write_bytes(b'')
    cards = ('*assem\n'+stubs+'*libra:13\n*call ficmemory\n'
             '*trans:newpasc,,320000\n'+source+'\n'
             '*perso:311160,cont\n*perso:320200,cont\n'
             '*table:p/coder(w*670175,l*12)\n*main pascoder\n*execute\n'
             '*end file\n``````\nеконец\n')
    listing = run_job('helpers',cards,env)
    symbols = {s.name:s.address for s in load_symbols(listing)}
    image = WORK/'helpers.img'
    subprocess.run(['besmtool','dump','3777','--start=0175','--length=10',
                    '--to-file='+str(image)],env=env,check=True,stdout=subprocess.DEVNULL)
    analyze.ensure_images()
    old, new = read_words(analyze.IMAGE), read_words(image)
    target_pool = new[symbols['PROGRAM']-0o2000] >> 24 & 0o77777
    old_names = analyze.load_helpers()
    old_names.update({a:n for n,a in ENTRIES})
    old_names.update({a:n for n,a in EXTERNALS.items()})
    old_names[0o21425] = 'PADCHAR*'
    old_names[analyze.POOL] = 'POOL'
    old_names[0o21253] = 'TIMES'
    old_names.update({0o23000:'P/WO',0o23001:'P/WH',0o22615:'P/08',
                      0o22670:'P/4',0o22600:'P/EL',0o22706:'P/5',
                      0o22704:'P/42',0o22712:'P/52'})
    names = {a:n for n,a in symbols.items()}
    names[target_pool] = 'POOL'
    names[symbols['P/1D']+0o572] = 'TIMES'

    def insns(words,lo,hi,pool,known):
        result = []
        targets = set()
        for address in range(lo,hi):
            for shift in (24,0):
                reg,op,value,long = operand(words[address-0o2000] >> shift & 0xffffff)
                if long and (op in (0o26,0o27,0o30,0o34,0o35,0o37) or
                             op==0o24 and reg in (0o13,0o15)) and lo<=value<hi:
                    targets.add(value)
        labels = {a:n for n,a in enumerate(sorted(targets))}
        for address in range(lo,hi):
            if address in labels:
                result.append(('define_label',labels[address]))
            for shift in (24,0):
                h = words[address-0o2000] >> shift & 0xffffff
                reg,op,value,long = operand(h)
                if h == 0o2200000:
                    continue
                arg = value
                if reg == 0o10 and not long and op <= 0o27:
                    offset = value if value < 0o70000 else value-0o100000
                    arg = ('pool',f'{words[pool+offset-0o2000]:016o}')
                elif long and op==0o24 and reg==0o13 and value>=pool and value not in known:
                    # Literal arrays are passed as M13 address, M12 length.
                    flat = [words[a-0o2000] >> s & 0xffffff
                            for a in range(address,min(address+3,hi)) for s in (24,0)]
                    pos = 0 if shift==24 else 1
                    following = [operand(x) for x in flat[pos+1:pos+4]]
                    length = next((v for r,o,v,l in following if l and r==0o12 and o==0o24),None)
                    if length is not None:
                        raw = b''.join(x.to_bytes(6,'big') for x in words[value-0o2000:value-0o2000+(length+5)//6])
                        arg = ('text',raw[:length].hex())
                elif long and value in known:
                    arg = ('symbol',known[value])
                elif long and (op in (0o26,0o27,0o30,0o34,0o35,0o37) or
                               op==0o24 and reg in (0o13,0o15)) and lo <= value < hi:
                    arg = ('label',labels[value])
                result.append((reg,op,long,arg))
        return result

    # The compiler listing retains procedure offsets even under P-.
    # This also covers the frameless character reader omitted by skeleton.py.
    compiled, pending = {}, {}
    for line in listing.read_text(encoding='utf-8-sig').splitlines():
        row = re.match(r'^ ([0-7]{5})\s+\d+\s+(\d+)\s+(.*)$',line)
        if not row:
            continue
        offset,depth,text = row[1],int(row[2]),row[3]
        decl = re.match(r'(?:PROCEDURE|FUNCTION)\s+(\w+)',text)
        if decl:
            pending[depth] = decl[1]
        elif text.startswith('BEGIN') and depth-2 in pending:
            compiled[pending.pop(depth-2)] = symbols['PROGRAM']+int(offset,8)
    new_starts = [compiled[name] for name,_ in ENTRIES]
    names.update({a:n for (n,_),a in zip(ENTRIES,new_starts)})
    rows = []
    for k,(name,start) in enumerate(ENTRIES):
        end = ENDS.get(name, ENTRIES[k+1][1] if k+1<len(ENTRIES) else analyze.POOL)
        actual = new_starts[k]
        actual_end = new_starts[k+1] if k+1<len(ENTRIES) else compiled['READJOB']
        before = insns(old,start,end,analyze.POOL,old_names)
        after = insns(new,actual,actual_end,target_pool,names)
        changes = [dict(tag=tag,original=[i,j],rebuilt=[m,n],
                        old=before[i:j],new=after[m:n])
                   for tag,i,j,m,n in difflib.SequenceMatcher(None,before,after,autojunk=False).get_opcodes()
                   if tag!='equal']
        rows.append(dict(name=name,original=f'{start:05o}',rebuilt=f'{actual:05o}',
                         original_words=end-start,rebuilt_words=actual_end-actual,
                         normalized_identical=before==after,changes=changes))
        print(f'{name:8} {start:05o}/{actual:05o} '
              f'{end-start}/{actual_end-actual} words; {len(changes)} differing blocks')
    report = dict(scope='initial helpers only; not a rebuilt LINK1 executable',
                  source=str(args.source.relative_to(ROOT)),
                  method='constants, strings, named calls, and ordered local labels resolved; UTC padding omitted',
                  original_pool=f'{analyze.POOL:05o}',rebuilt_pool=f'{target_pool:05o}',
                  original_application_words=analyze.POOL-0o2012,
                  recovered_words=sum(r['original_words'] for r in rows),
                  compiled_routines=len(rows),
                  normalized_identical_routines=sum(r['normalized_identical'] for r in rows),
                  procedures=rows,linked_program_executed=False,
                  complete_linker=False,bit_identical_rebuild=False)
    (WORK/'comparison.json').write_text(json.dumps(report,indent=2)+'\n')
    if args.source == (HERE/'helpers.pas').resolve():
        (HERE/'recovery.json').write_text(json.dumps(report,indent=2)+'\n')
    print(f'Listing: {listing.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
