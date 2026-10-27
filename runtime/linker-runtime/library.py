#!/usr/bin/env python3
"""Assemble and audit the source-selected runtime for one recovered linker."""
import json
from pathlib import Path
import re

from libmatch import operand

HERE = Path(__file__).resolve().parent


def sources(profile):
    metadata = json.loads((HERE/profile/'modules.json').read_text())
    return metadata, ''.join((HERE/m['source']).read_text()
                             for m in metadata['modules'])


def compare(profile, original, actual, symbols):
    metadata, _ = sources(profile)
    lo, hi = int(metadata['runtime'],8), int(metadata['free'],8)
    differences = [dict(address=f'{p:05o}', original=f'{original[p-0o2000]:016o}',
                        rebuilt=f'{actual[p-0o2000]:016o}')
                   for p in range(lo,hi)
                   if original[p-0o2000] != actual[p-0o2000]]
    modules = []
    for m in metadata['modules']:
        start, end = int(m['start'],8), int(m['end'],8)
        entries = {n:p for p,names in m['entries'].items() for n in names}
        if m['name'] in symbols:
            entries[m['name']] = m['start']
        placements = [dict(name=n,original=p,
                           rebuilt=f'{symbols[n]:05o}' if n in symbols else None)
                      for n,p in entries.items()]
        changes = [d for d in differences if start <= int(d['address'],8) < end]
        modules.append(dict(name=m['name'],source=m['source'],
                            start=m['start'],end=m['end'],words=end-start,
                            identical_words=end-start-len(changes),
                            bit_identical=not changes,
                            placement_matches=all(p['rebuilt']==p['original'] for p in placements),
                            entries=placements))
    globals = int(metadata['globals'],8)
    pool = original[0o2012-0o2000] >> 24 & 0o77777
    regions = []
    for name,start,end in [('application',0o2012,pool),('constants',pool,globals),
                           ('P/1D',globals,globals+0o50),
                           ('application_globals',globals+0o50,globals+0o650),
                           ('file_blocks_and_parameters',globals+0o650,lo),
                           ('library',lo,hi)]:
        changes = [dict(address=f'{p:05o}',original=f'{original[p-0o2000]:016o}',
                        rebuilt=f'{actual[p-0o2000]:016o}') for p in range(start,end)
                   if original[p-0o2000] != actual[p-0o2000]]
        regions.append(dict(name=name,start=f'{start:05o}',end=f'{end:05o}',
                            words=end-start,identical_words=end-start-len(changes),
                            bit_identical=not changes,differences=changes))
    header = []
    for p in range(0o2000,0o2012):
        old,new = original[p-0o2000],actual[p-0o2000]
        if old == new:
            continue
        if p == 0o2010 and (old ^ new) & 0xffffff == 0:
            reason = 'environment-dependent PASCODER descriptor left half'
        elif p == 0o2007 and old ^ new == 0o5000 and profile.startswith('b'):
            reason = 'original exchange zone field contains additional octal 05000'
        else:
            reason = 'unexplained'
        header.append(dict(address=f'{p:05o}',original=f'{old:016o}',
                           rebuilt=f'{new:016o}',reason=reason))
    return dict(profile=profile,runtime=metadata['runtime'],free=metadata['free'],
                rebuilt_free=f'{symbols["FREE"]:05o}',words=hi-lo,
                identical_words=hi-lo-len(differences),bit_identical=not differences,
                placement_matches=all(m['placement_matches'] for m in modules),
                modules=modules,differences=differences,regions=regions,
                header_differences=header,services_stubbed=False,
                linked_program_executed=False)


def data_words(source):
    """Locate data cards in the copied Madlen modules for readable listings."""
    pos, data, initialized = 0, set(), False
    for line in source.splitlines():
        if line.startswith(('C','c')):
            continue
        m = re.match(r'^\s*([^ ,:]*:)?\s*([^,]*),([^,]*),(.*)$',line)
        if not m:
            continue
        label,_,op,arg = m.groups()
        op,arg = op.strip().upper(),arg.strip()
        if op == 'DATA':
            initialized = True
        if initialized:
            continue
        if op in ['NAME','SUBP','LC','END','EQU','SET']:
            continue
        if label or op == 'ENTRY':
            pos += pos % 2
        if op == 'ENTRY':
            continue
        if op in ['LOG','OCT','INT','REAL','ISO','GOST','BSS']:
            pos += pos % 2
            if op in ['ISO','GOST']:
                length = re.match(r'(\d+)H',arg,re.I)
                size = (int(length[1])+5)//6 if length else 1
            elif op == 'BSS':
                size = int(arg.rstrip('Bb'),8 if arg.lower().endswith('b') else 10)
            else:
                size = 1
            data.update(range(pos//2,pos//2+size))
            pos += 2*size
        else:
            pos += 1
            if pos % 2 and (op in ['UJ','VJM','Z31'] or re.fullmatch(r'\*[5-7][0-7]',op)):
                pos += 1
    return data


def disassemble(profile, original, actual, symbols, work, f1, f2):
    metadata,_ = sources(profile)
    names = {int(p,8):n for m in metadata['modules']
             for p,entries in m['entries'].items() for n in entries}
    names.update({int(m['start'],8):m['name'] for m in metadata['modules']})
    for side,words in [('original',original),('rebuilt',actual)]:
        lines = [f'; {profile.upper()} {side} library, addresses and words octal.']
        for m in metadata['modules']:
            lo,hi = int(m['start'],8),int(m['end'],8)
            code = set(m.get('code_addresses',[]))
            data = data_words((HERE/m['source']).read_text())
            lines.append(f'\n; {m["name"]}: {lo:05o}-{hi-1:05o}; {m["source"]}')
            for p in range(lo,hi):
                value = words[p-0o2000]
                if p in names:
                    lines.append(names[p]+':')
                if (code and f'{p:05o}' not in code or not code and p-lo in data or
                        m['name'] in ['RTCONST','RTSTATE','PASCHARS','*TTIO*','P/08']):
                    parts = [f'WORD {value:016o}']
                else:
                    parts = []
                    for shift in (24,0):
                        r,o,v,long = operand(value >> shift & 0xffffff)
                        mnemonic = f2.get(o,f'Z{o:o}') if long else (
                            f1[o] if o < len(f1) else f'*{o:o}')
                        arg = names.get(v,f'{v:o}') if long else f'{v:o}'
                        parts.append(f'{r:02o},{mnemonic},{arg}')
                lines.append(f'{p:05o} {value:016o}  '+ ' / '.join(parts))
        (work/f'{side}-runtime.dis').write_text('\n'.join(lines)+'\n')
