#!/usr/bin/env python3
"""Recover the four linker runtime libraries as relocatable Madlen modules.

Usage: python3 runtime/linker-runtime/recover.py [link1|blink1|link|blink ...]
Existing Pascal modules are reused from the Monitor recovery and libpas.
Linker-specific bundles are decoded from their original images; module names
for those bundles describe their public interface, not historical object names.
Normal builds read the resulting sources and do not regenerate them.
"""
from collections import deque
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from paths import ROOT, TOOLS, RUNTIME, PROGRAMS, BUILD, IMAGES
sys.path.insert(0, str(TOOLS))
from corpus import read_words, find_volume
from libmatch import operand
from recover import LONG, SHORT

LIBPAS = Path('/home/leob/git/besm6/mesm6/toolchain/libpas')
MONITOR = RUNTIME/'profiles/monitor'
BASE = 0o2000


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def configuration(name):
    a = load(name+'_runtime_analysis', PROGRAMS/name/'analyze.py')
    if name == 'link1':
        b = load('link1_runtime_builder', PROGRAMS/name/'build.py')
        externals, translate = b.EXTERNALS, lambda address: address
    else:
        externals, translate = a.profile()['externals'], a.reference_address
    a.ensure_images()
    return a, externals, translate


# End points are derived from module starts, not guessed function lengths.
# None selects a linker-specific source recovered below.
MODULES = [
    ('P/2', 0o21426, 'p_2.madlen'),
    ('P/WI', 0o21432, 'p_wi.madlen'),
    ('P/CW', 0o21513, 'p_cw.madlen'),
    ('P/EF', 0o21515, 'p_ef.madlen'),
    ('P/7A', 0o21523, 'p_7a.madlen'),
    ('KEYS', 0o21540, None),
    ('GETSTAMP', 0o21675, None),
    ('P/LNGPAR', 0o21721, 'libpas/p_lngpar.madlen'),
    ('DBIO', 0o21727, None),
    ('TABLEIO', 0o22244, None),
    ('P/3', 0o22256, 'p_3.madlen'),
    ('P/SYS', 0o22262, 'p_sys.madlen'),
    ('P/08', 0o22615, 'p_08.madlen'),
    ('P/STAR', 0o22644, 'libpas/p_star.madlen'),
    ('P/6A', 0o22656, 'p_6a.madlen'),
    ('P/LDAR', 0o22660, 'p_ldar.madlen'),
    ('P/4', 0o22670, 'libpas/p_4.madlen'),
    ('P/IN', 0o22674, 'libpas/p_in.madlen'),
    ('P/42', 0o22704, 'libpas/p_42.madlen'),
    ('P/5', 0o22706, 'libpas/p_5.madlen'),
    ('P/52', 0o22712, 'libpas/p_52.madlen'),
    ('P/SS', 0o22715, 'libpas/p_ss.madlen'),
    ('P/31', 0o22717, None),
    ('CLOSE', 0o22721, None),
    ('P/A7', 0o22772, 'p_a7.madlen'),
    ('P/WO', 0o23000, 'p_wo.madlen'),
    ('ATTACH', 0o23062, None),
    ('GETDATE', 0o23165, None),
    ('P/RC', 0o23221, 'p_rc.madlen'),
    ('P/WC', 0o23237, 'libpas/p_wc.madlen'),
    ('P/MD', 0o23244, 'libpas/p_md.madlen'),
    ('P/41', 0o23253, None),
    ('P/UN', 0o23256, 'libpas/p_un.madlen'),
    ('VALUES', 0o23263, None),
    ('MEMORY', 0o24135, None),
    ('P/HT', 0o24275, 'p_ht.madlen'),
    ('P/1', 0o24307, 'p_1.madlen'),
    ('P/SP', 0o24315, 'p_sp.madlen'),
    ('PASCHARS', 0o24323, None),
    ('P/HIDE', 0o24325, 'p_hide.madlen'),
    ('RTCONST', 0o24333, None),
    ('RTERROR', 0o24457, None),
    ('STOP*', 0o24500, 'stop.madlen'),
    ('MONOUT', 0o24501, 'monout.madlen'),
    ('MONIN', 0o24573, 'monin.madlen'),
    ('P/PRINT', 0o24643, 'p_print.madlen'),
    ('*TTIO*', 0o24662, 'ttio.madlen'),
    ('P/PUTERR', 0o24711, 'p_puterr.madlen'),
    ('RTSTATE', 0o24712, None),
]


def starts(a, externals, translate, words):
    helpers = {n:p for p,n in a.load_helpers().items()}
    result = {}
    # The Pascal entry maps already distinguish the native value services.
    for name, old, _ in MODULES:
        try:
            result[old] = translate(old)
        except KeyError:
            if name in helpers:
                result[old] = helpers[name]
    result.update({0o21426:a.RUNTIME, 0o21540:externals['HASHNAME'],
                   0o21675:externals['GETSTAMP'],
                   0o21727:operand(words[externals['READNEXT']-BASE] & 0xffffff)[2],
                   0o22244:externals['GETFILED'],
                   0o22262:helpers['P/CO']-0o25,
                   0o22721:externals['CLOSE'], 0o23062:externals['ATTACH'],
                   0o23165:externals['GETDATE'], 0o23263:externals['PACKVAL'],
                   0o24135:externals['MEMINIT']})
    # These last blocks have identical lengths in all four linkers.
    for old in [0o24323,0o24333,0o24457,0o24500,0o24501,0o24573,
                0o24643,0o24662,0o24711,0o24712]:
        result[old] = old+a.FREE-0o24716
    # Restore helpers omitted by entry-only analysis, using adjacent bounds.
    result.setdefault(0o21721, result[0o21727]-6)
    result.setdefault(0o22256, result[0o22262]-4)
    result.setdefault(0o24275, result[0o24307]-10)
    result.setdefault(0o24325, result[0o24333]-6)
    result.setdefault(0o24315, result[0o24323]-6)
    if set(result) != {old for _,old,_ in MODULES}:
        missing = [name for name,old,_ in MODULES if old not in result]
        raise ValueError(f'missing module anchors: {missing}')
    if list(result[old] for _,old,_ in MODULES) != sorted(result.values()):
        raise ValueError('runtime module anchors are not in address order')
    return result


def literal(word, text=False):
    raw = word.to_bytes(6, 'big')
    # ISO text is unambiguous only when all six bytes are printable.
    if text or all(32 <= b < 127 for b in raw):
        value = ''.join(chr(b) if (65 <= b <= 90 or 48 <= b <= 57 or
                                  b in b' +-*/.,:;!?()=<>_') else
                        f"'{b:o}'" for b in raw).rstrip(' ')
        return ',ISO,6H'+value
    return f',LOG,{word:016o}'


def custom(words, module, modules, symbols, error):
    """Decode reachable code, leaving masks, templates and tables as data.

    All public entries seed traversal. Absolute internal calls and branches,
    plus M8-relative branches with the observed bundle base, extend it.
    The value bundle's thirteen dispatch veneers are additional roots.
    """
    lo, hi, name = module['start'], module['end'], module['name']
    data_only = name in ('PASCHARS', 'RTCONST', 'RTSTATE')
    code, text, queue = set(), set(), deque()
    forced_data = set()
    if not data_only:
        queue.extend(2*a for a in {lo, *module['entries'], *module.get('extra_roots',[])})
    if name == 'MEMORY':
        alloc = next(p for p,names in module['entries'].items() if 'MEMALLOC' in names)
        forced_data.update(range(alloc-8,alloc))
    if name == 'DBIO':
        for p in range(lo,hi):
            left,right = operand(words[p-BASE] >> 24), operand(words[p-BASE] & 0xffffff)
            if (left[3] and left[0:2] == (0o14,0o24) and left[2] < 0o100 and
                    right[3] and right[0:2] == (0,0o30) and lo <= right[2] < hi):
                queue.append(2*p)
    if name == 'VALUES':
        queue.extend(2*(lo+i) for i in range(13))
        queue.extend(2*p for p in range(hi-6,hi))
        marker = ((0o42400000 | lo) << 24) | 0o2200000
        markers = [p for p in range(lo,hi-6) if words[p-BASE] == marker]
        if markers:
            table = max(markers)+1
        else:
            table = next(p for p in range(hi-120,hi-6)
                         if words[p-BASE] == (1<<48)-1)
        forced_data.update(range(table,hi-6))
        for p in range(lo,table):
            left,right = operand(words[p-BASE] >> 24), operand(words[p-BASE] & 0xffffff)
            if (left[3] and left[1] in (0o34,0o35) and lo <= left[2] < hi and
                    right[3] and right[0:2] == (0o10,0o30)):
                queue.append(2*p)
    error_calls = {error}
    for p in range(lo, hi-1):
        tail = operand(words[p+1-BASE] & 0xffffff)
        if tail == (0, 0o30, error, True):
            error_calls.add(p)
    # M8 is loaded at each public value/name entry. GETDATE uses entry+1.
    bases = {0o10:lo+1 if name == 'GETDATE' else lo}
    for a in range(lo, hi):
        r,o,v,l = operand(words[a-BASE] >> 24)
        if l and r == 0o10 and o == 0o24 and v >= BASE:
            if lo <= v < hi:
                bases[r] = v
            if not data_only:
                queue.append(2*a)
    while queue:
        pos = queue.popleft()
        a, right = divmod(pos, 2)
        if not lo <= a < hi or pos in code or a in text or a in forced_data:
            continue
        code.add(pos)
        r,o,v,l = operand(words[a-BASE] >> (0 if right else 24) & 0xffffff)
        target = (v+bases.get(r, 0) if r in bases and v < BASE else v)
        if l and o in (0o26,0o27,0o30,0o31,0o34,0o35,0o37):
            if (r == 0 or o in (0o31,0o34,0o35,0o37) or r in bases) and lo <= target < hi:
                queue.append(2*target)
            if o == 0o30:
                continue
            if o == 0o31:
                # RTERROR consumes the ISO message directly after its caller.
                following = a+1
                if target in error_calls:
                    while following < hi:
                        raw = words[following-BASE].to_bytes(6,'big')
                        text.add(following)
                        following += 1
                        if 4 in raw:
                            break
                queue.append(2*following)
                continue
        if l and o == 0o24 and r in (0o13,0o15,0o16) and lo <= v < hi:
            queue.append(2*v)
        if not l and o >= 0o50 and o != 0o60:
            if o == 0o74:
                continue
            queue.append(2*(a+1))
        else:
            queue.append(pos+1)

    externals = set()
    stores = set()

    def address(v, entry=False):
        if lo <= v < hi:
            if entry:
                roots = module.setdefault('extra_roots',[])
                if v not in roots:
                    roots.append(v)
            return 'RBASE'+(f'+{v-lo:o}B' if v != lo else '')
        if v in symbols:
            externals.add(symbols[v])
            return symbols[v]
        owner = next((m for m in modules if m['start'] <= v < m['end']), None)
        if owner:
            if entry:
                roots = owner.setdefault('extra_roots',[])
                if v not in roots:
                    roots.append(v)
            externals.add(owner['name'])
            return owner['name']+f'+{v-owner["start"]:o}B'
        return f'{v:o}B' if v else ''

    def instruction(h):
        r,o,v,l = operand(h)
        mnemonic = ('Z31' if l and o == 0o31 and not r else LONG.get(o)) if l else (
            SHORT[o] if o < len(SHORT) else f'*{o:o}')
        if mnemonic is None:
            raise ValueError(f'{name}: unsupported opcode in reachable code')
        reloc = l and v >= BASE or not l and not r and v >= BASE and (
            o <= 0o27 or o in (0o64,0o70,0o71))
        entry = l and o in (0o26,0o27,0o30,0o31,0o34,0o35,0o37)
        argument = address(v,entry) if reloc else (f'{v:o}B' if v else '')
        if not l and o in (0,1):
            dest = v+bases.get(r,0) if r in bases else v if r == 0 else -1
            if lo <= dest < hi:
                stores.add(dest)
        return f'{r if r else ""},{mnemonic},{argument}'

    body = []
    for a in range(lo, hi):
        word = words[a-BASE]
        if a in text or not ({2*a,2*a+1} & code):
            if name == 'MEMORY' and lo <= word >> 24 < hi:
                # Packed descriptor: relocatable 24-bit entry, raw low half.
                body.append((a,[',Z00,'+address(word >> 24,True),
                                instruction(word & 0xffffff)]))
            else:
                body.append((a,[literal(word,a in text)]))
        else:
            left, right = word >> 24, word & 0xffffff
            lines = [instruction(left)]
            r,o,_,l = operand(left)
            aligns = l and o in (0o30,0o31) or not l and o >= 0o50 and o != 0o60
            if aligns and right == 0o2200000:
                lines.append(',BSS,0')
            else:
                lines.append(instruction(right))
            body.append((a,lines))
    lines = [f'C Recovered from {module["image"]}, {lo:05o}-{hi-1:05o}.',
             f' {name}:,NAME,']
    lines += [f' {n}:,SUBP,' for n in sorted(externals) if n != name]
    for a, cards in body:
        for alias in module['entries'].get(a,[]):
            if alias != name or a != lo:
                lines.append(f' {alias}:,ENTRY,')
        label = ' RBASE:' if a == lo else ' '
        if words[a-BASE] == 0 and a in stores and not ({2*a,2*a+1} & code):
            cards = [',BSS,1']
        if name == 'RTSTATE' or name == 'RTCONST' and words[a-BASE] == 0:
            cards = [',BSS,1']
        lines.append(label+cards[0])
        lines.extend(' '+c for c in cards[1:])
    lines.append(' ,END,')
    module['code_words'] = sum(bool({2*a,2*a+1} & code) for a in range(lo,hi))
    module['code_addresses'] = [f'{a:05o}' for a in range(lo,hi) if {2*a,2*a+1} & code]
    return '\n'.join(lines)+'\n'


def source_for(origin):
    if origin.startswith('libpas/'):
        return (LIBPAS/origin[7:]).read_text()
    if origin.startswith('proz/'):
        return (PROGRAMS/origin).read_text()
    return (MONITOR/origin).read_text()


def prepare(name):
    a, externals, translate = configuration(name)
    comp_image = IMAGES/'4001/0315-comp.bin'
    if not comp_image.exists():
        volume = find_volume()
        env = {**os.environ,'BESM6_PATH':str(volume.parent)}
        subprocess.run(['besmtool','dump','4001','--start=0315','--length=8',
                        '--to-file='+str(comp_image)],env=env,check=True,
                       stdout=subprocess.DEVNULL)
    words = read_words(a.IMAGE)
    positions = starts(a, externals, translate, words)
    modules = []
    for k,(label,old,origin) in enumerate(MODULES):
        lo = positions[old]
        hi = positions[MODULES[k+1][1]] if k+1 < len(MODULES) else a.FREE
        modules.append(dict(name=label, start=lo, end=hi, origin=origin,
                            entries={}, image=str(a.IMAGE.relative_to(ROOT))))
    symbols = {v:k for k,v in externals.items()}
    # Prefer the API names used in the existing symbolic comparison.
    symbols.update({externals[n]:n for n in ['GETFILED','PUTFILED','TABGET','TABPUT']})
    symbols.update({a.GLOBALS:'P/1D', a.GLOBALS+0o650:'*INPUT*',
                    a.GLOBALS+0o706:'*OUTPUT*', a.RUNTIME-1:'PADCHAR*'})
    for m in modules:
        symbols.setdefault(m['start'],m['name'])
    for old,label in [(0o21520,'P/E'),(0o21525,'P/7AD'),(0o22600,'P/EL'),
                      (0o23001,'P/WH'),(0o24307,'P/LV')]:
        try:
            target = translate(old)
        except KeyError:
            owner = max(p for _,p,_ in MODULES if p <= old)
            target = positions[owner]+old-owner
        symbols[target] = label
    helpers = a.load_helpers()
    for addr,label in helpers.items():
        if a.RUNTIME <= addr < a.FREE and label.startswith('P/'):
            symbols.setdefault(addr,label)
    # Shared state and character constants whose object boundaries differ
    # from the generic Monitor profile.
    symbols.update({positions[0o24323]:'PASZERO*',positions[0o24323]+1:'PASMINS*',
                    a.FREE-4:'VALSTATE',a.FREE-3:'BANKREG',
                    a.FREE-2:'MEMSTATE',a.FREE-1:'PASPMDAD'})
    for label,addr in externals.items():
        owner = next(m for m in modules if m['start'] <= addr < m['end'])
        owner['entries'].setdefault(addr,[]).append(label)
    for addr,label in symbols.items():
        owner = next((m for m in modules if m['start'] <= addr < m['end']),None)
        if owner and (label.startswith('P/') or label in
                      ['PASZERO*','PASMINS*','VALSTATE','BANKREG','MEMSTATE','PASPMDAD']):
            owner['entries'].setdefault(addr,[]).append(label)
    # Public names in copied modules already have their own ENTRY cards.
    out = HERE/name
    out.mkdir(parents=True,exist_ok=True)
    for m in modules:
        origin = m['origin']
        if origin:
            source = source_for(origin)
            if origin == 'p_sys.madlen':
                source = source.replace(' 9,VTM,*TTIO*+26B',
                                        ' P/EL:,ENTRY,\n 9,VTM,*TTIO*+26B')
                deps = re.findall(r'^ ([^ :,]+):,SUBP,$',source,re.M)
                order = ['STOP*','MONOUT','MONIN','P/PRINT','*TTIO*','P/PUTERR']
                ordered = [n for n in order if n in deps]+[n for n in deps if n not in order]
                cards = iter(f' {n}:,SUBP,' for n in ordered)
                source = re.sub(r'^ [^ :,]+:,SUBP,$',lambda _:next(cards),source,flags=re.M)
            elif origin == 'p_wo.madlen':
                source = source.replace(' 14,VTM,R03373',
                                        ' P/WH:,ENTRY,\n 14,VTM,R03373')
            elif origin == 'p_1.madlen':
                source = source.replace(',WTC,2007B',',WTC,2010B')
                cards = source.splitlines()
                init = next(i for i,line in enumerate(cards) if line.startswith(' INI'))
                cards[init+0o46] = ' ,LOG,0000000000100000'
                source = '\n'.join(cards)+'\n'
            elif origin == 'p_sp.madlen':
                source = source.replace('SPACE*','PADCHAR*')
            elif origin == 'p_ht.madlen':
                source = source.replace(' P/HT:,NAME,',' P/HT:,NAME,\n PASPMDAD:,SUBP,')
                source = source.replace('14,VTM,R03532','14,VTM,PASPMDAD')
                source = source.replace(' PASPMDAD:,ENTRY,\n R03532:,LOG,0000000000000000\n','')
            elif origin == 'monout.madlen':
                source = source.replace('0401053141407416','0401053141407417')
                source = source.replace('0705613303607417','0705613303607416')
            elif origin == 'monin.madlen':
                comp = read_words(IMAGES/'4001/0315-comp.bin')
                extra = ''.join(f' ,LOG,{w:016o}\n' for w in comp[0o10606-BASE:0o10616-BASE])
                source = source.replace(' R03314:',extra+' R03314:')
            m['provenance'] = ('besm6/mesm6/toolchain/libpas/'+origin[7:]
                               if origin.startswith('libpas/') else
                               str((PROGRAMS/origin if origin.startswith('proz/')
                                    else MONITOR/origin).relative_to(ROOT)))
        else:
            source = custom(words,m,modules,symbols,positions[0o24457])
            m['provenance'] = m['image']
        filename = re.sub(r'[^a-z0-9]+','_',m['name'].lower()).strip('_')+'.madlen'
        source = '\n'.join(line.rstrip() for line in source.splitlines()
                           if line.strip())+'\n'
        (out/filename).write_text(source)
        m['source'] = name+'/'+filename
    # References to private entries in other bundles seed their decoding too.
    for _ in range(len(modules)):
        count = sum(len(m.get('extra_roots',[])) for m in modules)
        for m in modules:
            if m['origin'] is None:
                source = custom(words,m,modules,symbols,positions[0o24457])
                (HERE/m['source']).write_text(source)
        if sum(len(m.get('extra_roots',[])) for m in modules) == count:
            break
    manifest = dict(profile=name,image=str(a.IMAGE.relative_to(ROOT)),
                    runtime=f'{a.RUNTIME:05o}',free=f'{a.FREE:05o}',
                    globals=f'{a.GLOBALS:05o}',modules=[
                        {**m,'start':f'{m["start"]:05o}','end':f'{m["end"]:05o}',
                         'extra_roots':[f'{p:05o}' for p in sorted(set(m.get('extra_roots',[])))],
                         'entries':{f'{p:05o}':sorted(set(v)) for p,v in m['entries'].items()}}
                        for m in modules])
    (out/'modules.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(name,len(modules),'modules',a.FREE-a.RUNTIME,'words')


def share():
    """Keep one source for each real variant instead of four copied libraries."""
    profiles, groups = {}, {}
    for name in ['link1','blink1','link','blink']:
        path = HERE/name/'modules.json'
        if not path.exists():
            continue
        data = json.loads(path.read_text())
        profiles[name] = data
        for m in data['modules']:
            source = (HERE/m['source']).read_text()
            body = '\n'.join(line for line in source.splitlines()
                             if not line.startswith('C'))+'\n'
            groups.setdefault(m['name'],{}).setdefault(body,[]).append((name,m,source))
    directory = HERE/'common'
    directory.mkdir(exist_ok=True)
    moved = []
    for module,variants in groups.items():
        for body,uses in variants.items():
            first,m,source = uses[0]
            stem = re.sub(r'[^a-z0-9]+','_',module.lower()).strip('_')
            if len(variants) > 1:
                if module == 'VALUES':
                    suffix = '48' if first in ['link1','blink1'] else '64'
                else:
                    suffix = 'full' if first in ['link1','link'] else 'short'
                stem += '-'+suffix
            filename = stem+'.madlen'
            shared = directory/filename
            shared.write_text('C Linker runtime source; provenance and placements in modules.json.\n'+body)
            for profile,entry,_ in uses:
                previous = HERE/entry['source']
                if previous.parent == HERE/profile:
                    moved.append((profile,previous))
                entry['source'] = 'common/'+filename
    for name,data in profiles.items():
        (HERE/name/'modules.json').write_text(json.dumps(data,indent=2)+'\n')
    # Retain the temporary per-image sources as build artifacts, not sources.
    for profile,path in moved:
        archive = BUILD/'linker-runtime/unshared'/profile/path.name
        archive.parent.mkdir(parents=True,exist_ok=True)
        path.replace(archive)
    print(sum(len(v) for v in groups.values()),'shared source variants')


if __name__ == '__main__':
    for name in sys.argv[1:] or ['link1','blink1','link','blink']:
        prepare(name)
    share()
