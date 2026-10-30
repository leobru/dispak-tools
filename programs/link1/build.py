#!/usr/bin/env python3
"""Compile recovered LINK1 routines and compare them with 4001/0175.

Usage: python3 programs/link1/build.py [--source candidate.pas]
       python3 programs/link1/build.py --disassemble-only

This builds the combined link1.pas in the original routine order.
The base compiler defaults to mypas.b6; a generated copy changes only
TRUNC emission and INPUT/OUTPUT allocation order for historical matching.
Real runtime modules are selected from runtime/linker-runtime. The library,
its public entries, constants, globals and file blocks are compared literally.
The compiled linker is not executed.
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
SOURCE_NAME = 'link1.pas'
PROGRAM_NAME = 'LINK1'
SCRATCH_ZONE = 0o175
COMPILER_SOURCE = None
NAMEKEY_LITERALS = [(0o20017, 'KOMПOH-1'),
                    (0o20201, 'CИCBЫB'), (0o20203, 'CИCBBOД')]
sys.path.insert(0, str(next(p/'runtime' for p in HERE.parents
                            if (p/'runtime/paths.py').exists())))
from paths import ROOT, TOOLS, COMPILER, RUNTIME, PROGRAMS, BUILD
sys.path.insert(0, str(TOOLS))
WORK = BUILD/'link1'
from corpus import read_words, sha
from libmatch import load_symbols, operand
spec = importlib.util.spec_from_file_location('link1analyze', HERE/'analyze.py')
analyze = importlib.util.module_from_spec(spec)
spec.loader.exec_module(analyze)
spec = importlib.util.spec_from_file_location('linker_historical_names',
                               RUNTIME/'linker-runtime/historical_names.py')
historical = importlib.util.module_from_spec(spec)
spec.loader.exec_module(historical)

ENTRIES = [('ENTRY',0o2012), ('ПEЧBPE',0o2013), ('ПEЧИMЯOБ',0o2042), ('ДЛИПOЛИM',0o2070),
           ('CTATИCT',0o2113), ('ПOИCKИME',0o2125), ('BHECИИMЯ',0o2172),
           ('SFILE',0o2312), ('ASSIGN',0o2353),
           ('OШИБKИHA',0o4475), ('OШИБKИBM',0o4541),
           ('KOOPД',0o4562), ('OTKPOЙOФ',0o4612), ('ЗAKPOЙOФ',0o4635),
           ('ПEЧДЛФAЙ',0o4647), ('ПEЧALF0',0o4666), ('ДAЙЗAП',0o4707),
           ('ДAЙЗAПИC',0o4735), ('ДAЙTEЛЗA',0o4761), ('ПPOПЗAП',0o5003),
           ('ПEPEKYБ',0o5016), ('ЗAПBФOM',0o5044), ('BИCOKOC',0o5066),
           ('ПEЧДATY',0o5100), ('YЧET',0o5170),
           ('ДAЙЛИT',0o2426), ('OШCKAH',0o2463),
           ('BOЗЛИT',0o2752), ('CИMBOЛИM',0o2761), ('ПPOПPAЗД',0o2765),
           ('ДAЙPAЗД',0o2775), ('ЦEЛOE',0o3006), ('ДAЙЦEЛOE',0o3034),
           ('ДAЙЧИCЛO',0o3153), ('ДAЙИMЯФA',0o3176), ('ДAЙYKФAЙ',0o3230),
           ('ДAЙИMЯ',0o3312), ('CKAHEP',0o3335), ('CKAHPAЗД',0o3455),
           ('BHECИOФ',0o3466), ('YTOЧHEHИ',0o3541),
           ('PEЖПEЧ',0o3641), ('PAЗБOPЗA',0o3717),
           ('AHAЛИЗTO',0o5232), ('OШMOД',0o5276), ('ПEPEBPИ',0o5472),
           ('HOBЭЛTOБ',0o6063), ('HOBЭЛTAC',0o6101), ('HOBЭЛTCC',0o6121),
           ('БAЗЫBKYБ',0o6135), ('ATPBKYБ',0o6155), ('KИHФBKYБ',0o6175),
           ('BЫPBKYБ',0o6204), ('ИMЯBTOБ',0o6223), ('CБOPOБЬE',0o6247),
           ('PAЗPEШИC',0o7221), ('TAБHEPAC',0o7316), ('BЫPABAДP',0o7403),
           ('SECTID',0o7420), ('OШCOПP',0o7444), ('HACTPOЙH',0o7516),
           ('ПEЧИMЯCE',0o7661), ('ПEЧCEKЦИ',0o7722), ('ПEЧИMЯЛO',0o10146),
           ('DUMPCTEK',0o10162), ('OШMAШ',0o10203), ('CЛOBOBPA',0o10432),
           ('ЗAПBPAЗД',0o10447), ('ДAЙMИKPO',0o10473), ('ДAЙOПEP',0o10542),
           ('БAЙTЫBCT',0o10571), ('ДEЛЬTAC',0o10614), ('ЗHAЧCOБ',0o10645),
           ('ЗHAЧBHEШ',0o10706), ('ATPCOБ',0o10771), ('ATPBHEШ',0o11050),
           ('ЗABEPШИO',0o11152), ('CИCПPOГ',0o11317), ('ГPYЗЧИK',0o11413),
           ('ГPYППA10',0o11552), ('ГPYППA20',0o11724), ('MAШИHA',0o12131),
           ('OШBЫЧ',0o13634), ('BЫЧИCЛEH',0o13665),
           ('OШЗAГP',0o14113), ('ЗAГPYЗИM',0o14153),
           ('OБXOДЛEC',0o14333), ('ГEHMETKИ',0o14605),
           ('ГPYППABP',0o15044), ('ПEЧCTATИ',0o15063),
           ('INITFILES',0o15221), ('MAIN',0o15233), ('STARTUP',0o16624)]
ENDS = {'ASSIGN':0o2426, 'YЧET':0o5232, 'PAЗБOPЗA':0o4475,
        'CБOPOБЬE':0o7221, 'ПEЧИMЯЛO':0o10162, 'STARTUP':0o16631}
ENTRIES.sort(key=lambda entry: entry[1])
EXTERNALS = {'HASHNAME':0o21540,'CMPNAME':0o21545,'NAMELEN':0o21563,
             'GETSTAMP':0o21675,'NEWKEY':0o22232,'OBJREAD':0o22234,
             'OBJEDIT':0o22236,'FILEEDIT':0o22237,'NUMOBJS':0o22254,
             'POSITION':0o22252,'SETPOS':0o22250,
             'READPAIR':0o22240,'WRITPAIR':0o22241,'PUTTEMP':0o22243,
             'CLOSE':0o22721, 'GETFILED':0o22244,'PUTFILED':0o22245,
             'ATTACH':0o23062, 'GETDATE':0o23165,
             'TABREAD':0o22235, 'TABGET':0o22246, 'TABPUT':0o22247,
             'INITVEC':0o23126, 'UNPACKNM':0o21600,
             'UNPACKKY':0o21625, 'PACKKEY':0o21613,
             'PUTDEF':0o22247, 'PUTSECT':0o22247, 'PUTREF':0o22247,
             'GETPAIR':0o22244, 'PUTPAIR':0o22245, 'TABPAIR':0o22246, 'TABFILE':0o22246,
             'PACKVAL':0o23263, 'UNPACKVL':0o23302,
             'TABSAVE':0o22247,
             'KEYPAIR':0o21641, 'KEYCODE':0o21650, 'GETTEMP':0o22242,
             'READNEXT':0o22230, 'NEWTAB':0o22233,
             'MEMINIT':0o24135, 'MEMALLOC':0o24254,
             **{f'B{n}':int(n,8) for n in
                ['23312','23330','23336','23347','23361','24130',
                 '23414','24127','23525','23434','23375','24133','23423']}}


def reference_address(address):
    """Translate LINK1 reference addresses for a related linker image."""
    return address


def prepare_compiler(source_path=None):
    spec = importlib.util.spec_from_file_location('linker_compiler_patches',
                               RUNTIME/'linker-runtime/patch_compiler.py')
    patches = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(patches)
    return patches.prepare(WORK, source_path or COMPILER/'mypas.b6')


def runtime_library():
    spec = importlib.util.spec_from_file_location('linker_runtime_library',
                               RUNTIME/'linker-runtime/library.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def run_job(name, cards, env, timeout=180):
    job = WORK/(name+'.b6')
    listing = WORK/(name+'.lst')
    job.write_text('user 419900зс5^\n'
                   'dis 31(2113)32(77)33(2148-440)34(2048)66(3776-wr)67(3777-wr)^\n'
                   'eeb1a3\n*name\n'+cards)
    with listing.open('w') as stream:
        result = subprocess.run(['dispak','--path='+env['BESM6_PATH'],'-l',str(job)],
                                env=env, stdin=subprocess.DEVNULL, stdout=stream,
                                stderr=subprocess.STDOUT, timeout=timeout)
    text = listing.read_text(encoding='utf-8-sig',errors='replace')
    errors = re.findall(r'(?m)^\s*\*{6}.*$|^\s*OTCYTCTBYET.*$|'
                        r'^.*NO GLOBAL MEMORY.*$', text)
    folded = text.translate(str.maketrans('ABCEHKMOPTXY','АВСЕНКМОРТХУ'))
    fatal = any(message in folded for message in
                ['ПЕРЕПОЛНЕНА ТАБЛИЦА ОПИСАНИЙ','ЗАПРЕЩ.КОМАНДА'])
    if (result.returncode or errors or
            fatal or 'КОНЕЦ ЗАДАЧИ' not in text or
            re.search(r'IN\s+\d+\s+LINES\s+[1-9]\d*\s+ERRORS',text)):
        raise RuntimeError(str(listing)+'\n'+'\n'.join(errors))
    return listing


def compiler(env):
    source_path = COMPILER_SOURCE or COMPILER/'mypas.b6'
    source = source_path.read_text()
    fingerprint = sha(source.encode())
    stamp = WORK/'compiler.json'
    if stamp.exists() and (WORK/'77').exists():
        if json.loads(stamp.read_text()).get('source_sha256') == fingerprint:
            return
    for other in ['link1','blink1','link','blink','acc3/try','fprint','proz','mt']:
        directory = BUILD/other
        if directory == WORK:
            continue
        saved = directory/'compiler.json'
        if (saved.exists() and (directory/'77').exists() and
                json.loads(saved.read_text()).get('source_sha256') == fingerprint):
            shutil.copyfile(directory/'77',WORK/'77')
            for filename in ['compiler.b6','compiler.lst']:
                if (directory/filename).exists():
                    shutil.copyfile(directory/filename,WORK/filename)
            stamp.write_text(json.dumps(dict(source=str(source_path.relative_to(ROOT)),
                                             source_sha256=fingerprint),indent=2)+'\n')
            return
    spec = importlib.util.spec_from_file_location('morebuild', PROGRAMS/'more/build.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    saved_env = os.environ.copy()
    try:
        os.environ.update(env)
        module.rebuild_compiler(WORK, compiler_source=source)
    finally:
        os.environ.clear()
        os.environ.update(saved_env)
    stamp.write_text(json.dumps(dict(source=str(source_path.relative_to(ROOT)),
                                     source_sha256=fingerprint),indent=2)+'\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source',type=Path,default=HERE/SOURCE_NAME)
    parser.add_argument('--compiler-source',type=Path,default=COMPILER/'mypas.b6',
                        help='base compiler deck (default: working-tree mypas.b6)')
    parser.add_argument('--disassemble-only', action='store_true',
                        help='use the existing helpers.img and compiler listing')
    parser.add_argument('--explore',action='store_true',
                        help='record runtime differences during reconstruction')
    args = parser.parse_args()
    args.source = args.source.resolve()
    WORK.mkdir(parents=True,exist_ok=True)
    env = os.environ.copy()
    # Preserve installed disk lookup before assigning the private HOME.
    env['BESM6_PATH'] = str(WORK)+':'+env.get('BESM6_PATH',
                            f'{Path.home()}/.besm6:/usr/local/share/besm6')
    env['HOME'] = str(WORK/'home')
    Path(env['HOME']).mkdir(exist_ok=True)
    listing = WORK/'helpers.lst'
    image = WORK/'helpers.img'
    if not args.disassemble_only:
        global COMPILER_SOURCE
        COMPILER_SOURCE = prepare_compiler(args.compiler_source.resolve())
        compiler(env)
        source = args.source.read_text()
        for n,line in enumerate(source.splitlines(),1):
            if len(line)>72:
                raise ValueError(f'{args.source}:{n}: card exceeds 72 columns')
        lines = source.splitlines()
        for n,line in enumerate(lines,1):
            loop = re.match(
                r'\s*(?:(\(q\)|\(\*q\*\))\s*)?(?:for|while)\b',
                line,re.IGNORECASE)
            if loop:
                if not loop[1] and not (
                        n>1 and lines[n-2].strip() in ('(q)', '(*q*)')):
                    raise ValueError(f'{args.source}:{n}: loop requires (q) '
                                     'or explicit (*q*) exception')
                body = re.search(r'\bdo\b(.*)',line,re.IGNORECASE)
                tail = body[1].strip() if body else ''
                following = lines[n].lstrip() if n<len(lines) else ''
                if not body or not (tail.startswith('(r)') or
                        not tail and following.startswith('(r)')):
                    raise ValueError(f'{args.source}:{n}: loop do requires (r)')
        metadata, runtime = runtime_library().sources(PROGRAM_NAME.lower())
        (WORK/'runtime.madlen').write_text(runtime)
        # Both scratch disks are mounted by every job, the library job included.
        (WORK/'3776').write_bytes(b'')
        (WORK/'3777').write_bytes(b'')
        run_job('library','*assem\n'+runtime+'*to perso:660100\n'
                '*end file\n``````\nеконец\n',env)
        cards = ('*libra:13\n*call yesmemory\n'
                 '*trans:newpasc,,320000\n'+source+'\n'
                 '*perso:311160,cont\n*perso:320200,cont\n'
                 '*perso:660100,cont\n'
                 f'*table:p/coder(w*67{SCRATCH_ZONE:04o},l*12)\n'
                 '*main pascoder\n*execute\n'
                 '*end file\n``````\nеконец\n')
        listing = run_job('helpers',cards,env)
        subprocess.run(['besmtool','dump','3777',f'--start=0{SCRATCH_ZONE:o}','--length=10',
                        '--to-file='+str(image)],env=env,check=True,stdout=subprocess.DEVNULL)
    symbols = {s.name:s.address for s in load_symbols(listing)}
    analyze.ensure_images()
    old, new = read_words(analyze.IMAGE), read_words(image)
    library_report = runtime_library().compare(PROGRAM_NAME.lower(),old,new,symbols)
    (WORK/'library-comparison.json').write_text(json.dumps(library_report,indent=2)+'\n')
    runtime_library().disassemble(PROGRAM_NAME.lower(),old,new,symbols,WORK,
                                  analyze.F1,analyze.F2)
    if not args.explore and (not library_report['bit_identical'] or
                            not library_report['placement_matches'] or
                            library_report['free'] != library_report['rebuilt_free'] or
                            any(not r['bit_identical'] for r in library_report['regions'][1:]) or
                            any(d['reason']=='unexplained' for d in library_report['header_differences'])):
        raise ValueError('runtime mismatch; see '+str(WORK/'library-comparison.json'))
    if args.source == (HERE/SOURCE_NAME).resolve():
        (HERE/'library.json').write_text(json.dumps(library_report,indent=2)+'\n')
    target_pool = new[symbols['PROGRAM']-0o2000] >> 24 & 0o77777
    old_names = analyze.load_helpers()
    old_names.update({a:n for n,a in ENTRIES})
    old_names.update({a:n for n,a in EXTERNALS.items()})
    old_names.update({reference_address(address):name for address,name in {
        0o22244:'GETFILED',0o22245:'PUTFILED',0o22246:'TABGET',
        0o22247:'TABPUT',0o23256:'P/UN',0o20574:'CЛOBO',
        0o21425:'PADCHAR*',0o21253:'CTATЭTAП',0o16611:'ABORTJOB',
        0o23000:'P/WO',0o23001:'P/WH',0o22615:'P/08',0o22670:'P/4',
        0o22600:'P/EL',0o22706:'P/5',0o22704:'P/42',0o22712:'P/52',
        0o23244:'P/MD',0o23253:'P/41',0o24307:'P/LV'}.items()})
    old_names[analyze.POOL] = 'POOL'
    names = {a:('TABPUT' if n in ('PUTDEF','PUTSECT','PUTREF','TABSAVE') else n)
             for n,a in symbols.items()}
    for alias,original in [('GETPAIR','GETFILED'), ('PUTPAIR','PUTFILED'),
                           ('TABPAIR','TABGET'), ('TABFILE','TABGET')]:
        names[symbols[alias]] = original
    aliases = dict(GETPAIR='GETFILED', PUTPAIR='PUTFILED', TABPAIR='TABGET',
                   TABFILE='TABGET', PUTDEF='TABPUT', PUTSECT='TABPUT',
                   PUTREF='TABPUT', TABSAVE='TABPUT')
    names.update({symbols[n]:aliases.get(n,n) for n in EXTERNALS})
    names[symbols['P/1D']+0o113] = 'CЛOBO'
    names[target_pool] = 'POOL'
    names[symbols['P/1D']+0o572] = 'CTATЭTAП'
    for offset,name in [(0o123,'TEKOФ'), (0o545,'ФAЙЛPAЗД'),
                        (0o547,'ФAЙЛCXEM'), (0o551,'ФAЙЛMET'),
                        (0o133,'ЭЛTACП')]:
        old_names[analyze.GLOBALS+offset] = name
        names[symbols['P/1D']+offset] = name

    # These ten-character namekey literals are addressed through M16,
    # rather than the M13/length convention used by printer strings.
    for address, name in NAMEKEY_LITERALS:
        address = reference_address(address)
        literal = old[address-0o2000:address-0o2000+2]
        matches = [a for a in range(target_pool, symbols['P/1D']-1)
                   if new[a-0o2000:a-0o2000+2] == literal]
        if len(matches) != 1:
            raise ValueError(f'expected one namekey literal for {name}')
        old_names[address] = names[matches[0]] = 'namekey:'+name

    def insns(words,lo,hi,pool,known,keep_padding=False):
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
            if keep_padding and address != lo and address in known:
                result.append(('define_symbol',known[address]))
            if address in labels:
                result.append(('define_label',labels[address]))
            for shift in (24,0):
                h = words[address-0o2000] >> shift & 0xffffff
                reg,op,value,long = operand(h)
                if h == 0o2200000 and not keep_padding:
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
        decl = re.match(r'(?:PROCEDURE|FUNCTION|PROGRAM)\s+(\w+)',text)
        if decl:
            pending[depth] = historical.routine(decl[1])
        elif text.startswith('9999:'):
            names[symbols['PROGRAM']+int(offset,8)] = 'ABORTJOB'
        elif text.startswith('BEGIN') and depth-2 in pending:
            compiled[pending.pop(depth-2)] = symbols['PROGRAM']+int(offset,8)
    compiled.update(ENTRY=symbols['PROGRAM'], INITFILES=compiled[PROGRAM_NAME],
                    MAIN=compiled[PROGRAM_NAME]+0o12, STARTUP=target_pool-5)
    new_starts = [compiled[name] for name,_ in ENTRIES]
    names.update({a:n for (n,_),a in zip(ENTRIES,new_starts)})
    old_names = {a:historical.symbol(n) for a,n in old_names.items()}
    names = {a:historical.symbol(n) for a,n in names.items()}
    def disassembly(instructions):
        for instruction in instructions:
            if instruction[0] == 'define_label':
                yield f'L{instruction[1]:03d}:'
                continue
            if instruction[0] == 'define_symbol':
                yield instruction[1]+':'
                continue
            reg,op,long,arg = instruction
            mnemonic = (analyze.F2[op] if long else
                        analyze.F1[op] if op < len(analyze.F1) else f'*{op:o}')
            if isinstance(arg,tuple):
                kind,value = arg
                if kind == 'pool':
                    arg = '='+value+'C'
                elif kind == 'text':
                    raw = bytes.fromhex(value)
                    text = ''.join(chr(b) if 32 <= b < 127 else
                                   bytes([b]).decode('koi8-r') if b >= 0o300 else
                                   f'_{b:03o}' for b in raw)
                    arg = "=ISO'"+text.replace("'", "''")+"'"
                elif kind == 'label':
                    arg = f'L{value:03d}'
                else:
                    arg = value
            else:
                value = arg if long or arg < 0o70000 else arg-0o100000
                arg = f'{value:o}'
            yield f'    {reg:02o},{mnemonic:<4},{arg}'

    header = (f'; {PROGRAM_NAME} Pascal application: symbolic instruction disassembly.\n'
              '; One line per half-word; all instructions, including UTC 0, retained.\n'
              '; Region headings give actual word addresses (octal).\n'
              '; Numeric operands and raw pool words are octal; Lnnn labels are local.\n'
              '; M10 constants, literal addresses and named calls are resolved.\n'
              '; Runtime/service bodies and loader stub are outside this listing.\n')
    listings = [header,header]
    rows = []
    for k,(name,start) in enumerate(ENTRIES):
        display_name = historical.routine(name)
        end = ENDS.get(name, ENTRIES[k+1][1] if k+1<len(ENTRIES) else analyze.POOL)
        actual = new_starts[k]
        actual_end = min((a for a in new_starts if a>actual),default=target_pool)
        padded = []
        for side,words,lo,hi,pool,known in [
                (0,old,start,end,analyze.POOL,old_names),
                (1,new,actual,actual_end,target_pool,names)]:
            listings[side] += (f'\n; {display_name}: {lo:05o}-{hi-1:05o} '
                               f'({hi-lo} words)\n{display_name}:\n')
            padded.append(insns(words,lo,hi,pool,known,keep_padding=True))
            listings[side] += '\n'.join(disassembly(padded[-1]))+'\n'
        before = insns(old,start,end,analyze.POOL,old_names)
        after = insns(new,actual,actual_end,target_pool,names)
        changes = [dict(tag=tag,original=[i,j],rebuilt=[m,n],
                        old=before[i:j],new=after[m:n])
                   for tag,i,j,m,n in difflib.SequenceMatcher(None,before,after,autojunk=False).get_opcodes()
                   if tag!='equal']
        rows.append(dict(name=display_name,original=f'{start:05o}',rebuilt=f'{actual:05o}',
                         original_words=end-start,rebuilt_words=actual_end-actual,
                         normalized_identical=before==after,
                         padded_identical=padded[0]==padded[1],
                         padded_edit_cost=sum(max(j-i,n-m)
                             for tag,i,j,m,n in difflib.SequenceMatcher(
                                 None,padded[0],padded[1],autojunk=False).get_opcodes()
                             if tag!='equal'), changes=changes))
        print(f'{display_name:8} {start:05o}/{actual:05o} '
              f'{end-start}/{actual_end-actual} words; {len(changes)} differing blocks')
    global_changes = [dict(offset=f'{offset:04o}',
                           original=f'{old[analyze.GLOBALS+offset-0o2000]:016o}',
                           rebuilt=f'{new[symbols["P/1D"]+offset-0o2000]:016o}')
                      for offset in range(0o50, 0o650)
                      if old[analyze.GLOBALS+offset-0o2000] !=
                      new[symbols['P/1D']+offset-0o2000]]
    report = dict(scope='complete Pascal application linked with real runtime modules',
                  source=str(args.source.relative_to(ROOT)),
                  method='constants, strings, named calls, and ordered local labels resolved; UTC padding omitted',
                  original_pool=f'{analyze.POOL:05o}',rebuilt_pool=f'{target_pool:05o}',
                  original_application_words=analyze.POOL-0o2012,
                  recovered_words=sum(r['original_words'] for r in rows),
                  rebuilt_application_words=sum(r['rebuilt_words'] for r in rows),
                  compiled_routines=len(rows),
                  normalized_identical_routines=sum(r['normalized_identical'] for r in rows),
                  padded_identical_routines=sum(r['padded_identical'] for r in rows),
                  padded_edit_cost=sum(r['padded_edit_cost'] for r in rows),
                  global_words=0o650-0o50,global_changes=global_changes,
                  procedures=rows,linked_program_executed=False,
                  complete_linker=True,external_services_stubbed=False,
                  library_bit_identical=library_report['bit_identical'],
                  library_report=str((HERE/'library.json').relative_to(ROOT)),
                  bit_identical_rebuild=False)
    (WORK/'comparison.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    if args.source == (HERE/SOURCE_NAME).resolve():
        (HERE/'recovery.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    for filename,text in zip(['original.dis','rebuilt.dis'],listings):
        path = WORK/filename
        path.write_text(text)
        print(f'Disassembly: {path.relative_to(ROOT)}')
    print(f'Listing: {listing.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
