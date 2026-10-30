#!/usr/bin/env python3
"""Analyze the extracted corpus with strict module and entry-fragment matching.

Usage: python3 runtime/analyze.py [--disassembler ./disbesm6]
Produces analysis.json, ANALYSIS.md, and per-image .sym/.dis files. No match is
promoted to a recovered linkable module merely because its opcode mask agrees.
"""

import argparse
from collections import defaultdict
import json
from pathlib import Path
import subprocess
import sys

from paths import ROOT, TOOLS, RUNTIME
from corpus import BASE, decode_text, read_words, sha, pack
sys.path.insert(0, str(TOOLS))
import libmatch


def layout(words, record):
    entry = record['entries'][0]
    const, start = int(entry['constants'], 8), int(entry['start'], 8)
    calls = []
    for addr in range(int(entry['address'], 8), min(const, BASE + len(words))):
        for half in (words[addr-BASE] >> 24, words[addr-BASE] & 0xffffff):
            reg, op, operand, long = libmatch.operand(half)
            if long and op == 0o31 and operand >= const:
                calls.append((addr, reg, operand))
    startup = []
    for addr, reg, operand in calls:
        if start <= addr < start + 8 and reg == 14:
            startup.append(operand)
    m1 = []
    for address in startup:
        for word in words[max(0, address-BASE):max(0, address-BASE)+24]:
            for half in (word >> 24, word & 0xffffff):
                reg, op, operand, long = libmatch.operand(half)
                if long and reg == 1 and op == 0o24 and BASE <= operand < BASE+len(words):
                    m1.append(operand)
    valid_calls = [a for _, _, a in calls if const <= a < BASE+len(words)]
    return dict(constants=f'{const:05o}', start=f'{start:05o}',
                runtime_start_candidate=f'{min(valid_calls):05o}' if valid_calls else None,
                startup_candidates=[f'{a:05o}' for a in sorted(set(startup))],
                m1_candidates=[f'{a:05o}' for a in sorted(set(m1))],
                calls_outside_extract=sorted({f'{a:05o}' for _, _, a in calls
                                             if a >= BASE+len(words)}))


def analyze(directory, disassembler):
    corpus = json.loads((directory / 'corpus.json').read_text())
    references = []
    profiles=json.loads((directory/'profiles.json').read_text())
    for label,profile in profiles.items():
        reference=read_words(ROOT/profile['source'])
        symbols=[libmatch.Symbol(c['name'],int(c['start'],8),'M')
                 for c in profile['chunks']]
        for index,(before,after) in enumerate(zip(profile['chunks'],profile['chunks'][1:])):
            if int(before['end'],8)<int(after['start'],8):
                symbols.append(libmatch.Symbol(f'GAP{index}',int(before['end'],8),'M'))
        symbols += [libmatch.Symbol(name,int(address,8),'E')
                    for name,address in profile['exports'].items()]
        symbols += [libmatch.Symbol('FREE',int(profile['runtime'][1],8),'Z')]
        symbols.sort(key=lambda s:(s.address,s.name))
        references.append((label,reference,symbols))
    for stem in ('test', 'тестац'):
        image, listing = ROOT / (stem + '.img'), ROOT / (stem + '.img.lst')
        if image.exists() and listing.exists():
            references.append((stem, libmatch.words(image), libmatch.load_symbols(listing)))
    out = directory / 'analysis'
    out.mkdir(exist_ok=True)
    records = []
    for record in corpus['roots'] + corpus['images']:
        source = ROOT / record['path'] if record['source'] == 'workspace' else directory / record['path']
        words = read_words(source)
        if sha(pack(words)) != record['sha256']:
            raise ValueError(f'{source}: hash differs from corpus manifest')
        matches = []
        names = defaultdict(set)
        kinds = {}
        for label, reference, symbols in references:
            for fragment in (False, True):
                for candidate in libmatch.find_candidates(reference, symbols, words,
                                                           fragments=fragment):
                    if not candidate['matches']:
                        continue
                    matches.append(dict(reference_image=label, **candidate))
                    if len(candidate['matches']) != 1:
                        continue
                    address = int(candidate['matches'][0]['address'], 8)
                    if not candidate['name'].startswith('RT'):
                        names[candidate['name']].add(address)
                        kinds[candidate['name']] = candidate['type']
                    for alias in candidate['aliases']:
                        names[alias['name']].add(address + alias['offset'])
                        kinds[alias['name']] = ('D' if alias['name'] in libmatch.DATA_MODULES
                                                else candidate['type'])
        reviewed=[]
        for label,profile in profiles.items():
            if sha(pack(read_words(ROOT/profile['source'])))==record['sha256']:
                reviewed.append(label)
                for name,address in profile['exports'].items():
                    names[name]={int(address,8)}
                    kinds[name]=('C' if any(int(begin,8)<=int(address,8)<int(end,8)
                                            for begin,end in profile['code']) else 'D')
        symbols = [dict(name=name, address=f'{next(iter(addresses)):05o}', type=kinds[name])
                   for name, addresses in names.items() if len(addresses) == 1]
        symbols.sort(key=lambda s: (int(s['address'], 8), s['name']))
        sym = out / (record['id'] + '.sym')
        sym.write_text(''.join(f'{s["address"]} {s["type"]} {s["name"]}\n' for s in symbols))
        args = [str(disassembler), '-b', '-a2000', '-n' + str(sym)]
        args += ['-e' + e['address'] for e in record['entries']]
        dis = out / (record['id'] + '.dis')
        with dis.open('w') as stream:
            subprocess.run(args + [str(source)], stdout=stream, check=True)
        records.append(dict(id=record['id'], source=record['path'],
                            sha256=record['sha256'], layout=layout(words, record),
                            reviewed_profiles=reviewed,
                            symbols=symbols, candidates=matches,
                            conflicts={name: [f'{a:05o}' for a in sorted(addresses)]
                                       for name, addresses in names.items() if len(addresses)>1},
                            symbol_file=str(sym.relative_to(directory)),
                            disassembly=str(dis.relative_to(directory))))
    result = dict(format_version=1, address_notation='octal',
                  matching='exact words or consistent address-operand relocation; candidates only',
                  references=[name for name, _, _ in references], images=records)
    (directory / 'analysis.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
    report(directory, corpus, records, profiles)
    print(f'Analyzed {len(records)} image records; wrote runtime/ANALYSIS.md')


def report(directory, corpus, records, profiles):
    by_id = {r['id']: r for r in records}
    lines = ['# Pascal runtime corpus analysis', '',
             'Generated by `python3 runtime/analyze.py`. All addresses and zone ranges are octal.', '',
             f'Volume 4001 SHA-256: `{corpus["volume"]["sha256"]}`.', '',
             f'Extracted {len(corpus["images"])} images; the four root binaries bring the corpus to '
             f'{len({r["sha256"] for r in corpus["images"]+corpus["roots"]})} distinct images.', '',
             'Catalog lengths come from descriptor bits 11–16, not the next file start. '
             'In particular, МТСОРУ occupies 0101–0103; the image at 0104 is uncatalogued. '
             'Allocated ranges may contain padding or overlays and do not imply one contiguous program.', '',
             '| Image | Zones | Pascal entry | M10 | Candidate symbols | Duplicate |',
             '|---|---|---|---|---:|---|']
    for r in corpus['images']:
        a = by_id[r['id']]
        end = int(r['end_zone_exclusive'],8)-1
        lines.append(f'| [{r["name"]}]({r["path"]}) | {r["zone"]}–{end:04o} '
                     f'| {r["entries"][0]["address"]} | {r["entries"][0]["constants"]} '
                     f'| {len(a["symbols"])} | {", ".join(r["duplicates"])} |')
    lines += ['', '## Recovered libraries', '',
              'The four reviewed profiles have generated Madlen sources and explicit instruction/data '
              'relocation records under `profiles/`. Application FORTRAN routines are excluded.', '',
              '| Profile | Source | Runtime words | Public entries |',
              '|---|---|---:|---:|']
    for name,p in profiles.items():
        count=sum(int(c['end'],8)-int(c['start'],8) for c in p['chunks'])
        source='README.md' if p.get('split_sources') else 'runtime.madlen'
        lines.append(f'| [{name}](profiles/{name}/{source}) | {p["source"]} '
                     f'| {count} | {len(p["exports"])} |')
    lines += ['', 'The default monitor profile also offers the six words of P/3 and P/6A '
              'recovered from тестац.bin. Their frame and string-helper dependencies agree with '
              'the monitor profile; their linked words are checked separately. Other helpers '
              'are never silently supplied by the installed Pascal runtime.', '',
              '## Identification evidence', '',
              'The old matcher discarded every operand and accepted 90% of opcode words. '
              'It could mistake P/2 for P/3 and zero-filled commons for executable routines. '
              'The current matcher preserves numeric operands, checks internal relocation, '
              'keeps ENTRY aliases with their modules, and reports ambiguous locations.', '',
              'Whole-module matches and shorter entry-fragment matches are recorded separately '
              'in `analysis.json`. A fragment identifies an entry candidate; it does not establish '
              'the boundary or dependencies of its original object module. Names found by '
              'different references at conflicting addresses are omitted from `.sym` files.', '',
              'Symbol files use C for code and D for data. The adjacent disassemblies retain '
              'all extracted words. Unnamed words and out-of-extract calls require recovery '
              'before further runtime profiles can be declared linkable. The reviewed profiles '
              'override candidate names only for their own byte-identical source images.', '',
              '## Startup and overlay boundaries', '',
              '| Image | Runtime start candidate | P/1 candidates | M1 candidates | Calls beyond extract |',
              '|---|---|---|---|---|']
    for r in records:
        a=r['layout']
        lines.append(f'| {r["id"]} | {a["runtime_start_candidate"] or ""} '
                     f'| {", ".join(a["startup_candidates"])} | {", ".join(a["m1_candidates"])} '
                     f'| {", ".join(a["calls_outside_extract"])} |')
    (directory / 'ANALYSIS.md').write_text('\n'.join(lines)+'\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, default=RUNTIME)
    parser.add_argument('--disassembler', type=Path, default=TOOLS / 'disbesm6')
    args = parser.parse_args()
    analyze(args.directory.resolve(), args.disassembler.resolve())


if __name__ == '__main__':
    main()
