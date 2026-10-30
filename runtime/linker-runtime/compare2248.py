#!/usr/bin/env python3
"""Compare 2248's KOMPON executables with the four 4001 linkers.

Usage: python3 runtime/linker-runtime/compare2248.py
Read-only besmtool extraction; binaries stay in runtime/build/linker-2248.
Addresses/zones in JSON are octal; sizes and source line numbers are decimal.
"""
from pathlib import Path
import difflib
import importlib.util
import json
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'runtime' for p in HERE.parents
                            if (p/'runtime/paths.py').exists())))
from paths import TOOLS, PROGRAMS, BUILD
sys.path.insert(1, str(TOOLS))
from corpus import read_words
from libmatch import operand

WORK = BUILD/'linker-2248'
PROFILES = [('kompon2','2248','02540'), ('kompon3','2248','02560'),
            ('link1','4001','0175'), ('blink1','4001','0255'),
            ('link','4001','0112'), ('blink','4001','0275')]
TEXT = ([' ','.','Б','Ц','Д','Ф','Г','И','(',')','*','Й','Л','Я','Ж','/']+
        list('0123456789')+['Ь',',','П','-','+','Ы','З']+
        list('ABCDEFGHIJKLMNOPQRSTUVWXYZ')+['Ш','Э','Щ','Ч','Ю'])


def text(word):
    return ''.join(TEXT[word >> s & 63] for s in range(42,-1,-6)).strip()


def pmd(words, pool, globals):
    halves = [h for w in words for h in (w >> 24, w & 0xffffff)]
    result = []
    for i in range(2*(pool-0o2000)-1):
        r,o,a,l = operand(halves[i])
        r2,o2,a2,l2 = operand(halves[i+1])
        if not (l and (r,o)==(0o16,0o24) and
                l2 and (r2,o2)==(0o16,0o25)):
            continue
        address = a+a2
        if not pool <= address < globals-1:
            continue
        name = text(words[address-0o2000])
        line = words[address+1-0o2000]-0o6400000000000000
        if not re.fullmatch('[A-ZА-Я][A-ZА-Я0-9]*',name) or not 0 <= line < 10000:
            continue
        variables = []
        p = address+2
        while p+1 < globals and words[p-0o2000]:
            variables.append(dict(name=text(words[p-0o2000]),
                                  descriptor=f'{words[p+1-0o2000]:016o}'))
            p += 2
        result.append(dict(reference=f'{0o2000+i//2:05o}',
                           table=f'{address:05o}',name=name,line=line,
                           variables=variables))
    return result


def keys(words, entry, pool):
    result = []
    for w in words[entry-0o2000:pool-0o2000]:
        for h in (w >> 24, w & 0xffffff):
            if h == 0o2200000:
                continue
            r,o,a,l = operand(h)
            if r==0o10 and not l and o <= 0o27:
                offset = a if a < 0o70000 else a-0o100000
                a = ('constant', words[pool+offset-0o2000])
            elif l and a >= 0o2000:
                a = 'address'
            result.append((r,o,a,l))
    return result


def main():
    WORK.mkdir(parents=True,exist_ok=True)
    spec = importlib.util.spec_from_file_location('frames', PROGRAMS/'acc3/skeleton.py')
    frames = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(frames)
    images, sequences = {}, {}
    for name,volume,zone in PROFILES:
        path = WORK/(name+'.bin')
        subprocess.run(['besmtool','dump',volume,'--start='+zone,'--length=16',
                        '--to-file='+str(path)],check=True,stdout=subprocess.DEVNULL)
        w = read_words(path)
        idx = 9 if w[0]==0o0230201006400000 else 10
        entry = 0o2000+idx
        pool,startup = w[idx] >> 24 & 0o77777, w[idx] & 0o77777
        free,count = w[idx-2] & 0o77777, w[idx-1]
        runtime = next(operand(h)[2] for v in w[idx+1:idx+5]
                       for h in (v >> 24,v & 0xffffff)
                       if operand(h)[:2]==(0o16,0o31))
        p1 = w[startup-0o2000] >> 24 & 0o77777
        globals = next(operand(h)[2] for v in w[p1-0o2000:p1-0o2000+10]
                       for h in (v >> 24,v & 0xffffff)
                       if operand(h)[:2]==(1,0o24) and operand(h)[3])
        active_text = path.read_bytes()[(pool-0o2000)*6:(globals-0o2000)*6].decode('koi8-r')
        version = re.search(r'BEPCИЯ\s+([0-9.]+/[0-9]+)',active_text)[1]
        stamp = re.search(r'KOMПOH-[0-9]',active_text)[0]
        tables = pmd(w,pool,globals)
        bounds = []
        for address in range(entry+1,pool):
            for side,h in enumerate((w[address-0o2000] >> 24,
                                     w[address-0o2000] & 0xffffff)):
                r,o,a,l = operand(h)
                if r==0o10 and not l and o <= 0o27:
                    offset = a if a < 0o70000 else a-0o100000
                    value = w[pool+offset-0o2000]
                    for bit in (15,27):
                        if value == (0o6400000000000000 | (1 << bit)):
                            bounds.append(dict(address=f'{address:05o}',
                                               half='L' if side==0 else 'R',
                                               opcode=f'{o:o}',power=bit))
        images[name] = dict(volume=volume,first_zone=f'{int(zone,8):04o}',
            last_zone=f'{int(zone,8)+15:04o}',version=version,producer_stamp=stamp,
            entry=f'{entry:05o}',pool=f'{pool:05o}',globals=f'{globals:05o}',
            runtime=f'{runtime:05o}',free=f'{free:05o}',loaded_zones=count,
            loaded_end_exclusive=f'{0o2000+count*1024:05o}',
            application_words=pool-entry,constant_area_words=globals-pool,
            framed_procedures=len(frames.procedures(w,0o2000,entry+1,pool)),
            pmd_scopes=len(tables),power_bound_uses=bounds)
        if tables:
            (HERE/'2248-mode3-pmd.json').write_text(json.dumps(tables,ensure_ascii=False,indent=2)+'\n')
        sequences[name] = keys(w,entry,pool)
    comparisons = []
    for old in ['kompon2','kompon3']:
        for new in ['link1','blink1','link','blink']:
            a,b = sequences[old],sequences[new]
            matcher = difflib.SequenceMatcher(None,a,b,autojunk=False)
            comparisons.append(dict(old=old,new=new,
                instruction_similarity=round(matcher.ratio(),6),
                matched_instructions=sum(x.size for x in matcher.get_matching_blocks()),
                old_instructions=len(a),new_instructions=len(b)))
    result = dict(images=images,comparisons=comparisons,
        normalization='UTC 0 omitted; M10 operands resolved to raw constants; long operands >=02000 replaced by address marker; other operands retained',
        limitation='Similarity measures structural resemblance, not semantic equivalence or valid relocations.')
    (HERE/'comparison2248.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    for name,row in images.items():
        print(name,row['version'],row['application_words'],'application words;',
              row['pmd_scopes'],'PMD scopes')
    for row in comparisons:
        print(row['old'],row['new'],row['instruction_similarity'])


if __name__ == '__main__':
    main()
