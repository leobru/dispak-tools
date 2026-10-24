#!/usr/bin/env python3
"""Compare Monitor modules with every volume-4001 extract.

Usage: python3 runtime/consistency.py
Writes monitor-consistency.json and MONITOR-CONSISTENCY.md. Only fields in the
reviewed relocation records may differ; no opcode-only or similarity matches
are accepted. A missing match does not distinguish an absent routine, a variant,
or an overlay whose load address differs from its position in the extract.
"""

from collections import Counter, defaultdict
import json
from pathlib import Path

from corpus import BASE, ROOT, pack, read_words, sha

DIRECTORY = Path(__file__).resolve().parent
WORD_MASK = (1 << 48) - 1


def fields(record):
    if record['half'] == 'data':
        return record['shift'], record['width']
    return (24 if record['half'] == 'L' else 0), record['width']


def matches(reference, words, chunk, relocations):
    start, end = int(chunk['start'], 8), int(chunk['end'], 8)
    pattern = reference[start - BASE:end - BASE]
    records = defaultdict(list)
    masks = [WORD_MASK] * len(pattern)
    for r in relocations:
        address = int(r['word'], 8)
        if start <= address < end:
            records[address - start].append(r)
            shift, width = fields(r)
            masks[address - start] &= ~(((1 << width) - 1) << shift)
    result = []
    for pos in range(len(words) - len(pattern) + 1):
        if words[pos] & masks[0] != pattern[0] & masks[0]:
            continue
        forward, reverse = {}, {}
        valid = True
        for index, original in enumerate(pattern):
            actual = words[pos + index]
            if actual & masks[index] != original & masks[index]:
                valid = False
                break
            for r in records[index]:
                shift, width = fields(r)
                target = (actual >> shift) & ((1 << width) - 1)
                old = int(r['target'], 8)
                if start <= old < end:
                    valid = target == BASE + pos + old - start
                else:
                    valid = (not BASE + pos <= target < BASE + pos + len(pattern)
                             and forward.setdefault(old, target) == target
                             and reverse.setdefault(target, old) == old)
                if not valid:
                    break
            if not valid:
                break
        if valid:
            result.append(f'{BASE + pos:05o}')
    return result


def analyze():
    corpus = json.loads((DIRECTORY / 'corpus.json').read_text())
    profile = json.loads((DIRECTORY / 'profiles/monitor/relocations.json').read_text())
    reference = read_words(ROOT / profile['source'])
    if sha(pack(reference)) != profile['sha256']:
        raise ValueError('Monitor reference hash differs from relocation metadata')
    startup = next(c for c in profile['chunks'] if c['name'] == 'P/1')
    alternate = list(reference)
    index = int(startup['start'], 8) - BASE
    alternate[index] = (alternate[index] & ~0o77777) | 0o2010
    images = []
    extracts = {}
    for record in corpus['images']:
        words = read_words(DIRECTORY / record['path'])
        if sha(pack(words)) != record['sha256']:
            raise ValueError(f'{record["id"]}: extract hash differs from manifest')
        extracts[record['id']] = words
        modules = [dict(name=c['name'], words=int(c['end'], 8)-int(c['start'], 8),
                        addresses=matches(reference, words, c, profile['relocations']))
                   for c in profile['chunks']]
        images.append(dict(id=record['id'], name=record['name'], zone=record['zone'],
                           sha256=record['sha256'], modules=modules,
                           startup_02010=matches(alternate, words, startup,
                                                  profile['relocations'])))
    # Check the concrete examples before using them in the prose report.
    examples = [('4001-0061-test', '02774', 0o0037000302302007),
                ('4001-0016-tar', '10545', 0o0037000302302010),
                ('4001-0057-testats', '04254', 0o0037000300102007)]
    for ident, address, expected in examples:
        if extracts[ident][int(address, 8) - BASE] != expected:
            raise ValueError(f'{ident}: counterexample instruction changed')
    if extracts['4001-0061-test'] != reference:
        raise ValueError('4001 TEST differs from Monitor reference')
    configs = json.loads((DIRECTORY / 'profiles.json').read_text())
    if extracts['4001-0057-testats'] != read_words(ROOT / configs['svs']['source']):
        raise ValueError('4001 TESTATS differs from SVS reference')
    result = dict(reference=profile['source'], sha256=profile['sha256'],
                  matching='Only reviewed address fields may differ; internal targets must relocate together.',
                  limitations='Missing matches are not proof of variants. Overlay matches require separate load-address review. Small data and stub matches are not identification evidence alone.',
                  images=images)
    (DIRECTORY / 'monitor-consistency.json').write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    lines = ['# Monitor runtime consistency on volume 4001', '',
             'Generated by `python3 runtime/consistency.py`.', '',
             '**The runtime is not uniform across all images.** `ТЕSТ` is byte-identical',
             'to the Monitor reference; `ТЕСТАЦ` is byte-identical to the SVS reference.',
             'Monitor-style images also contain startup variants.', '',
             '## Direct counterexamples', '',
             '| Image | P/1 address | First word | Instructions |',
             '|---|---|---|---|',
             '| ТЕSТ, zone 0061 | 02774 | `0037000302302007` | `NTR 3; WTC 02007` |',
             '| ТАR, zone 0016 | 10545 | `0037000302302010` | `NTR 3; WTC 02010` |',
             '| ТЕСТАЦ, zone 0057 | 04254 | `0037000300102007` | `NTR 3; XTA 02007` |', '',
             'The first two use different fixed PASCODER descriptor addresses. This is',
             'a loader-interface variant, not ordinary relocation of a runtime module.',
             'The SVS startup changes the instruction sequence: it reads the stack',
             'pointer with `XTA` and then assigns M17, while Monitor uses `WTC` and',
             '`VTM`. Its P/GF file helper is also different from Monitor.', '',
             '## Full-module comparison', '',
             'Every word of each of the 31 modules is compared against every extract.',
             'Only fields explicitly marked in `profiles/monitor/relocations.json`',
             'may change; internal branch and data targets must keep their offsets.',
             'Other instruction fields, indexed offsets, fixed addresses and literal',
             'data must agree exactly. External target mappings must be consistent',
             'and one-to-one within each candidate module.', '',
             'Counts include shared data and one-word stubs. Several matches mean',
             'multiple candidates, possibly overlay copies; they are not discarded.',
             'An absent match can mean an omitted module, changed code/data, or an',
             'overlay loaded at another address. It does not by itself prove a variant.',
             'The supplemental P/3 and P/6A helpers are outside this comparison.', '',
             '| Image | Zone | Modules with a match / 31 | P/SYS | P/1 |',
             '|---|---|---:|---|---|']
    for image in images:
        modules = {m['name']:m for m in image['modules']}
        count = sum(bool(m['addresses']) for m in image['modules'])
        sys = ', '.join(modules['P/SYS']['addresses']) or 'no full match'
        startup = ', '.join(modules['P/1']['addresses']) or 'no full match'
        if image['startup_02010']:
            startup = '02010 variant: ' + ', '.join(image['startup_02010'])
        lines.append(f'| {image["name"]} | {image["zone"]} | {count} | {sys} | {startup} |')
    lines += ['', '## Module coverage', '',
              '| Module | Images with a full match / 26 |', '|---|---:|']
    counts = Counter(m['name'] for image in images for m in image['modules'] if m['addresses'])
    for c in profile['chunks']:
        lines.append(f'| {c["name"]} | {counts[c["name"]]} |')
    lines += ['', 'The address matrix is in [monitor-consistency.json](monitor-consistency.json).',
              'This static comparison establishes shared recovered blocks and concrete',
              'differences; it does not establish equivalent runtime behavior.']
    (DIRECTORY / 'MONITOR-CONSISTENCY.md').write_text('\n'.join(lines) + '\n')
    for image in images:
        print(image['id'], sum(bool(m['addresses']) for m in image['modules']))


if __name__ == '__main__':
    analyze()
