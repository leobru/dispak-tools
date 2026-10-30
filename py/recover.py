#!/usr/bin/env python3
"""Emit relocatable Madlen and explicit relocation records from reviewed profiles.

Usage: python3 py/recover.py [profile]  (default: monitor)
Instruction/data ranges and entry names are reviewed in profiles.json; the
generator does not guess that a data word is an instruction or a pointer.
"""

import argparse
from collections import defaultdict
import json
from pathlib import Path
import sys

from paths import ROOT, RUNTIME
from corpus import BASE, read_words, pack, sha
from libmatch import operand

SHORT = ['ATX','STX','MOD','XTS','A+X','A-X','X-A','AMX',
         'XTA','AAX','AEX','ARX','AVX','AOX','A/X','A*X',
         'APX','AUX','ACX','ANX','E+X','E-X','ASX','XTR',
         'RTE','YTA','*32','EXT','E+N','E-N','ASN','NTR',
         'ATI','STI','ITA','ITS','MTJ','J+M','*46','*47']
LONG = {0o22:'UTC',0o23:'WTC',0o24:'VTM',0o25:'UTM',0o26:'UZA',
        0o27:'U1A',0o30:'UJ',0o31:'VJM',0o32:'IJ',0o33:'STOP',
        0o34:'VZM',0o35:'V1M',0o36:'*36',0o37:'VLM'}


def generate(profile, directory):
    config = json.loads((directory/'profiles.json').read_text())[profile]
    words = read_words(ROOT/config['source'])
    lo, hi = (int(a,8) for a in config['runtime'])
    code = {a for begin,end in config['code'] for a in range(int(begin,8),int(end,8))}
    commons = {name:(int(c['address'],8),c['words']) for name,c in config['common'].items()}
    names = defaultdict(list)
    for name, address in config['exports'].items():
        names[int(address,8)].append(name)
    relocation = []
    alignment_labels=set()
    chunks = config['chunks']
    current_chunk = None
    dependencies = set()
    used_commons = set()
    module_dependencies = {}

    def expression(address):
        if lo <= address < hi:
            for chunk in chunks:
                start,end=int(chunk['start'],8),int(chunk['end'],8)
                if start<=address<end:
                    if chunk is current_chunk:
                        return f'R{address:05o}'
                    # Refer to a public entry when possible, retaining private
                    # offsets only for targets without a reviewed name.
                    for name in names[address] if config.get('split_sources') else ():
                        dependencies.add(name)
                        return name
                    dependencies.add(chunk['name'])
                    offset=address-start
                    return chunk['name']+(f'+{offset:o}B' if offset else '')
            raise ValueError(f'address {address:05o} is outside recovery chunks')
        for name,(start,size) in commons.items():
            if start <= address < start+size:
                used_commons.add(name)
                offset = address-start
                return name+(f'+{offset:o}B' if offset else '')
        if address in [int(a,8) for a in config['fixed_addresses']]:
            return None
        raise ValueError(f'{profile}: unresolved absolute address {address:05o}')

    def instruction(half, address, side):
        reg,op,arg,long = operand(half)
        if long:
            if op not in LONG:
                raise ValueError(f'{profile}: undefined long opcode at {address:05o}.{side}; review code/data annotation')
            mnemonic = LONG[op]
            reloc = op in (0o22,0o23,0o24,0o26,0o27,0o30,0o31,0o34,0o35,0o36,0o37)
        else:
            mnemonic = SHORT[op] if op < len(SHORT) else f'*{op:o}'
            reloc = (reg == 0 and (op <= 0o27 or op in (0o64,0o70,0o71)))
        value = None
        if reloc and BASE <= arg < 0o70000:
            try:
                value = expression(arg)
            except ValueError as exc:
                raise ValueError(f'{exc} at {address:05o}.{side}') from exc
            if value:
                relocation.append(dict(word=f'{address:05o}',half=side,
                                       target=f'{arg:05o}',expression=value,
                                       width=15 if long else 12))
        if value is None:
            value = f'{arg:o}B' if arg else ''
        return f'{reg if reg else ""},{mnemonic},{value}'

    data_reloc = {int(r['word'],8):r for r in config.get('data_relocations',[])}
    text = {}
    text_continuations = set()
    for block in config.get('text',[]):
        if block['encoding'] != 'iso':
            raise ValueError('unsupported text encoding')
        start = int(block['start'],8)
        data = block['value'].encode('ascii')
        end = start + len(data)//6
        if (not data or len(data)%6 or
                pack(words[start-BASE:end-BASE]) != data or
                any(a in code or a in data_reloc for a in range(start,end)) or
                not any(int(c['start'],8)<=start<end<=int(c['end'],8) for c in chunks)):
            raise ValueError(f'{profile}: invalid text annotation at {start:05o}')
        # Quote control bytes and trailing padding explicitly. Madlen's ISO
        # directive accepts octal byte escapes, for example '4' for ETX.
        trailing = len(data.rstrip(b' '))
        literal = ''.join(chr(b) if 32<=b<=95 and b!=39 and i<trailing
                          else f"'{b:o}'" for i,b in enumerate(data))
        text[start] = f',ISO,{len(data)}H{literal}'
        text_continuations.update(range(start+1,end))
    provenance = [f'C Recovered from {config["source"]}.',
                  f'C SHA256 {sha(pack(words))}',
                  'C Generated by py/recover.py; all original addresses are octal.']
    lines = []
    for index,chunk in enumerate(chunks):
        current_chunk=chunk
        dependencies=set()
        used_commons=set()
        first_line=len(lines)
        for addr in range(int(chunk['start'],8),int(chunk['end'],8)):
            if addr in text_continuations:
                continue
            for name in names[addr]:
                if name != chunk['name']:
                    lines.append(f' {name}:,ENTRY,')
            w = words[addr-BASE]
            label = f' R{addr:05o}:'
            if addr in text:
                lines.append(label+text[addr])
            elif addr in data_reloc:
                r = data_reloc[addr]
                if r['shift'] != 0 or r['width'] != 15 or w != int(r['target'],8):
                    raise ValueError('unsupported data relocation')
                lines.append(label+',ATX,')
                lines.append(' ,Z00,'+expression(int(r['target'],8)))
                relocation.append(dict(**r,expression=expression(int(r['target'],8)),half='data'))
            elif addr not in code:
                lines.append(label+f',LOG,{w:016o}')
            else:
                left,right=w>>24,w&0xffffff
                lines.append(label+instruction(left,addr,'L'))
                reg,op,_,long=operand(left)
                # Madlen's *60 pseudo-op does not insert the right-half filler.
                aligns = (long and op in (0o30,0o31)) or (not long and op>=0o50 and op!=0o60)
                if long and op==0o30 and reg and right==0o2200000:
                    alignment_labels.add(addr+1)
                if not (aligns and right==0o2200000):
                    lines.append(' '+instruction(right,addr,'R'))
        if chunk['name']==config.get('initialization_module',chunks[0]['name']):
            lines.append(' ,DATA,')
            initialization=[]
            for name,c in config['common'].items():
                count=c.get('initialize',0)
                if count:
                    used_commons.add(name)
                    start=int(c['address'],8)
                    label=f'INI{len(lines)%10000:04d}'
                    lines.append(f' {label}:,LOG,{words[start-BASE]:016o}')
                    lines += [f' ,LOG,{w:016o}' for w in words[start-BASE+1:start-BASE+count]]
                    initialization += [f' {count},SET,{label}',f' 1,,{name}']
            lines+=initialization
        lines.append(' ,END,')
        if not config.get('split_sources'):
            # Preserve the existing all-module loading policy of SVS profiles.
            dependencies.update(c['name'] for c in chunks if c is not chunk)
            used_commons.update(commons)
        headers=[f' {chunk["name"]}:,NAME,']
        headers += [f' {name}:,SUBP,' for name in sorted(dependencies)]
        headers += [f' {name}:,LC,{config["common"][name].get("reserve",commons[name][1])}'
                    for name in commons if name in used_commons]
        lines[first_line:first_line]=headers
        module_dependencies[chunk['name']]=dict(subprograms=sorted(dependencies),
                                               commons=sorted(used_commons))
    # Madlen has a small description table. Name only actual address targets,
    # rather than consuming one descriptor for every word in the image.
    targets = {int(r['target'],8) for r in relocation}
    targets.update(alignment_labels)
    targets.update(int(c['start'],8) for c in chunks)
    if text_continuations & (targets | set(names)):
        raise ValueError('split text annotations at referenced interior words')
    compact=[]
    for line in lines:
        if line.startswith(' R') and line[2:7].isdigit() and line[7:8]==':':
            label,rest=line.split(':',1)
            if int(label[2:],8) not in targets:
                line=' '+rest
        compact.append(line)
    lines=compact
    destination=directory/'profiles'/profile
    destination.mkdir(parents=True,exist_ok=True)
    if config.get('split_sources'):
        sources=[]
        first=0
        for chunk in chunks:
            begin=lines.index(f' {chunk["name"]}:,NAME,',first)
            end=lines.index(' ,END,',begin)+1
            (destination/chunk['file']).write_text('\n'.join(provenance+lines[begin:end])+'\n')
            sources.append(chunk['file'])
            first=end
    else:
        sources=['runtime.madlen']
        (destination/'runtime.madlen').write_text('\n'.join(provenance+lines)+'\n')
    metadata=dict(profile=profile,source=config['source'],sha256=sha(pack(words)),
                  module=chunks[0]['name'],chunks=chunks,runtime=config['runtime'],
                  exports=config['exports'],common=config['common'],
                  core_helpers=config.get('core_helpers',[]),
                  compiler_prefix=config.get('compiler_prefix',''),
                  relocations=relocation,notes=config['notes'])
    if config.get('split_sources'):
        metadata.update(sources=sources,dependencies=module_dependencies,
                        helper_sources=config.get('helper_sources',[]))
    if config.get('text'):
        metadata['text']=config['text']
    (destination/'relocations.json').write_text(json.dumps(metadata,indent=2)+'\n')
    count=sum(int(c['end'],8)-int(c['start'],8) for c in chunks)
    print(f'{profile}: emitted {count} words, {len(config["exports"])} entries, '
          f'{len(relocation)} relocations')
    return metadata


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('profile',nargs='?',default='monitor')
    args=parser.parse_args()
    generate(args.profile,RUNTIME)


if __name__=='__main__':
    main()
