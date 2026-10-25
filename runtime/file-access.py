#!/usr/bin/env python3
"""Recover COMP's ERROR/MKNAME/OPENF bundles using independently linked copies.

  python3 runtime/file-access.py            # scan *.bin, emit evidence and Madlen
  python3 runtime/file-access.py --assemble # also assemble/link the recovered cards

Only changed long address fields in reviewed code ranges and explicitly reviewed
table pointers become relocations.
Opcode fingerprints locate candidates; every accepted copy must then agree in
every bit after applying the measured relocations. Other revisions are reported
as candidates, never accepted by a more permissive operand mask.
"""

import argparse
from collections import defaultdict
import json
from pathlib import Path
import sys

from corpus import BASE, ROOT, pack, read_words, sha
from recover import LONG, SHORT
sys.path.insert(0, str(ROOT))
from libmatch import mask, operand

HERE = Path(__file__).resolve().parent
DEST = HERE / 'file-access'
REFERENCE = ROOT / 'runtime/images/4001/0315-comp.bin'
# Keep the complete M8-relative bundles: entry points alone omit their pools,
# parser, and other routines sharing the same base. Ends are exclusive.
MODULES = [
    dict(name='ERROR', file='error.madlen', start=0o7036, end=0o7241,
         anchor=0o7036, entries={}, code=[(0o7036, 0o7054)],
         pointers=list(range(0o7054, 0o7105)),
         text=[(0o7105, 0o7231), (0o7235, 0o7241)]),
    dict(name='DBNAME', file='mkname.madlen', start=0o7244, end=0o7636,
         anchor=0o7443, entries={'MKNAME': 0o7443},
         text=[(0o7523, 0o7542)],
         bss=[(0o7373, 0o7401), (0o7404, 0o7406)],
         code=[(0o7244, 0o7373), (0o7406, 0o7515), (0o7573, 0o7625)]),
    dict(name='DBFILE', file='openf.madlen', start=0o7636, end=0o10266,
         anchor=0o7667, entries={'OPENF': 0o7667},
         code=[(0o7636, 0o10013), (0o10032, 0o10172), (0o10176, 0o10266)]),
    dict(name='DBPASC', file='dbpasc.madlen', start=0o20002, end=0o20035,
         anchor=0o20002, entries={'DBENTER': 0o20002, 'DBLEAVE': 0o20007},
         bss=[(0o20031, 0o20035)],
         code=[(0o20002, 0o20016), (0o20017, 0o20021)]),
    dict(name='DBCORE', file='dbcore.madlen', start=0o20035, end=0o20175,
         anchor=0o20035, entries={},
         bss=[(0o20060, 0o20061), (0o20173, 0o20174)],
         code=[(0o20035, 0o20057), (0o20064, 0o20066),
               (0o20067, 0o20140), (0o20141, 0o20171), (0o20174, 0o20175)]),
]
EXTERNALS = {0o10455: 'MONOUT', 0o10547: 'MONIN'}
GOST_LITERALS = {
    0o0160340701603407: '777777',
    0o1242547515620060: 'КЛЮЧАР',
}
RELOC_OPS = {0o22, 0o23, 0o24, 0o26, 0o27, 0o30, 0o31,
             0o34, 0o35, 0o36, 0o37}


def code_at(module, address):
    return any(lo <= address < hi for lo, hi in module['code'])


def compare(ref, target, module, position):
    """Return the address map only when all differences are relocatable code."""
    start, end = module['start'], module['end']
    mapping = {}
    for offset, address in enumerate(range(start, end)):
        rw, tw = ref[address-BASE], target[position+offset]
        for side, shift in [('L', 24), ('R', 0)]:
            rh, th = (rw >> shift) & 0xffffff, (tw >> shift) & 0xffffff
            reg, op, arg, long = operand(rh)
            pointer = address in module.get('pointers', []) and side == 'R'
            if pointer:
                arg = rh & 0o77777
            eligible = pointer or (code_at(module, address) and long and op in RELOC_OPS)
            if rh != th and (not eligible or (rh ^ th) & ~0o77777):
                return None
            if eligible and arg >= BASE:
                value = th & 0o77777
                if mapping.setdefault(arg, value) != value:
                    return None
    deltas = {value-arg for arg, value in mapping.items() if start <= arg < end}
    if len(deltas) != 1:
        return None
    delta = deltas.pop()
    return mapping, delta


def expression(target, module):
    if target in EXTERNALS:
        return EXTERNALS[target]
    for owner in MODULES:
        if owner['start'] <= target < owner['end']:
            if owner is module:
                return f'R{target:05o}'
            for name, address in owner['entries'].items():
                if target == address:
                    return name
            offset = target-owner['start']
            return owner['name'] + (f'+{offset:o}B' if offset else '')
    raise ValueError(f'unresolved target {target:05o}')


def recover():
    ref = read_words(REFERENCE)
    binaries = []
    for path in sorted(ROOT.rglob('*.bin')):
        # Generated assembly artifacts are not independent historical witnesses.
        if '.git' in path.parts or 'build' in path.relative_to(ROOT).parts:
            continue
        try:
            words = read_words(path)
        except ValueError:
            continue
        binaries.append((path, words, [mask(w) for w in words]))
    result = dict(format_version=1, address_notation='octal',
                  reference=str(REFERENCE.relative_to(ROOT)),
                  reference_sha256=sha(pack(ref)),
                  scanned=[dict(path=str(p.relative_to(ROOT)), words=len(w),
                                sha256=sha(pack(w))) for p, w, _ in binaries],
                  modules=[], externals={f'{a:05o}': n for a, n in EXTERNALS.items()})
    for module in MODULES:
        start, end, anchor = (module[k] for k in ('start', 'end', 'anchor'))
        signature = [mask(w) for w in ref[anchor-BASE:anchor-BASE+12]]
        matches, candidates, fields = [], [], set()
        for path, words, fingerprints in binaries:
            for pos in range(len(words)-len(signature)+1):
                if fingerprints[pos:pos+12] != signature:
                    continue
                begin = pos-(anchor-start)
                if begin < 0 or begin+end-start > len(words):
                    continue
                item = dict(path=str(path.relative_to(ROOT)),
                            file_anchor=f'{pos+BASE:05o}')
                if module['entries'].get('MKNAME') or module['entries'].get('OPENF'):
                    item['encoded_base'] = f'{operand(words[pos] >> 24)[2]:05o}'
                match = compare(ref, words, module, begin)
                if match is None:
                    run = 0
                    while (pos+run < len(words) and anchor-BASE+run < len(ref)
                           and fingerprints[pos+run] == mask(ref[anchor-BASE+run])):
                        run += 1
                    item.update(status='different bundle; entry fingerprint only',
                                matching_opcode_prefix_words=run)
                    candidates.append(item)
                    continue
                mapping, delta = match
                item.update(file_start=f'{begin+BASE:05o}', load_start=f'{start+delta:05o}',
                            load_anchor=f'{anchor+delta:05o}',
                            file_to_load_delta=f'{start+delta-begin-BASE:+o}',
                            targets={f'{a:05o}': f'{v:05o}' for a, v in sorted(mapping.items())})
                matches.append(item)
                for offset, address in enumerate(range(start, end)):
                    for side, shift in [('L', 24), ('R', 0)]:
                        if (ref[address-BASE] >> shift) & 0xffffff != (words[begin+offset] >> shift) & 0xffffff:
                            fields.add((address, side))
        if len(matches) < 2:
            raise ValueError(f'{module["name"]}: no independent relocation witness')
        relocations = []
        for address, side in sorted(fields):
            shift = 24 if side == 'L' else 0
            target = (ref[address-BASE] >> shift) & 0o77777
            kind = 'data' if address in module.get('pointers', []) and side == 'R' else side
            relocations.append(dict(word=f'{address:05o}', half=kind, width=15,
                                    target=f'{target:05o}', expression=expression(target, module),
                                    witnesses=sum(m['targets'][f'{target:05o}'] != f'{target:05o}'
                                                  for m in matches)))
        # Reconstruct every complete copy, including unchanged fields and data.
        for item in matches:
            words = next(w for p, w, _ in binaries if str(p.relative_to(ROOT)) == item['path'])
            begin = int(item['file_start'], 8)-BASE
            byword = defaultdict(list)
            for r in relocations:
                byword[int(r['word'], 8)].append(r)
            for offset, address in enumerate(range(start, end)):
                expected = ref[address-BASE]
                for r in byword[address]:
                    shift = 24 if r['half'] == 'L' else 0
                    value = int(item['targets'][r['target']], 8)
                    expected = (expected & ~(0o77777 << shift)) | (value << shift)
                if expected != words[begin+offset]:
                    raise ValueError(f'{item["path"]}: unexplained word {address:05o}')
            item['exact_words_after_relocation'] = end-start
        result['modules'].append(dict(name=module['name'], source=module['file'],
            start=f'{start:05o}', end=f'{end:05o}', words=end-start,
            entries={n: f'{a:05o}' for n, a in module['entries'].items()},
            code=[[f'{a:05o}', f'{b:05o}'] for a, b in module['code']],
            relocations=relocations, copies=matches, other_candidates=candidates))
        if module.get('text'):
            result['modules'][-1]['text'] = [
                dict(start=f'{lo:05o}', end=f'{hi:05o}', encoding='iso')
                for lo, hi in module['text']]
        if module.get('bss'):
            result['modules'][-1]['bss'] = [
                dict(start=f'{lo:05o}', end=f'{hi:05o}', words=hi-lo)
                for lo, hi in module['bss']]
        if module.get('pointers'):
            result['modules'][-1]['pointer_words'] = [f'{a:05o}' for a in module['pointers']]
    # Cross-check referenced helper addresses against independently matched copies.
    # Different revisions may coexist in an image, so only assert an owner where
    # its complete recovered bundle was actually found in that same image.
    for module in result['modules']:
        for copy in module['copies']:
            for target, value in copy['targets'].items():
                address = int(target, 8)
                owner = next((m for m in result['modules']
                              if int(m['start'], 8) <= address < int(m['end'], 8)), None)
                if owner is None:
                    continue
                owners = [c for c in owner['copies'] if c['path'] == copy['path']]
                if not any(int(c['load_start'], 8)+address-int(owner['start'], 8) == int(value, 8)
                           for c in owners):
                    raise ValueError(f'{copy["path"]}: dependency {target} is not backed by a recovered copy')
    DEST.mkdir(exist_ok=True)
    for module, evidence in zip(MODULES, result['modules']):
        emit(ref, module, evidence, result['reference_sha256'])
    error = result['modules'][0]
    koi7 = ''.join(chr(i) for i in range(96)) + 'ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЫЗШЭЩЧ' + chr(127)
    lookalikes = str.maketrans('ABCEHKMOPTXY', 'АВСЕНКМОРТХУ')

    def message(start, end):
        data = pack(ref[start-BASE:end-BASE]).split(b'\n', 1)[0]
        return ''.join(koi7[b] for b in data).translate(lookalikes)

    error['messages'] = []
    for address in MODULES[0]['pointers']:
        word = ref[address-BASE]
        start = word & 0o77777
        error['messages'].append(dict(status=word >> 24, status_octal=f'{word >> 24:o}',
            table=f'{address:05o}', start=f'{start:05o}',
            text=message(start, 0o7231)))
    error['default_message'] = dict(start='07235', text=message(0o7235, 0o7241))
    (DEST/'relocations.json').write_text(json.dumps(result, indent=2)+'\n')
    for module in result['modules']:
        print(f'{module["name"]}: {module["words"]} words, '
              f'{len(module["relocations"])} relocations, {len(module["copies"])} exact copies, '
              f'{len(module["other_candidates"])} other candidates')
    return result


def emit(ref, module, evidence, digest):
    relocations = {(int(r['word'], 8), r['half']): r for r in evidence['relocations']}
    targets = {int(r['target'], 8) for r in evidence['relocations']}
    dependencies = {r['expression'].split('+')[0] for r in evidence['relocations']
                    if not r['expression'].startswith('R')}
    body = []
    # Reserve reviewed writable cells; zero entries in constant tables stay LOG.
    bss = {a for lo, hi in module.get('bss', []) for a in range(lo, hi)}
    for address in bss:
        if (not module['start'] <= address < module['end']
                or code_at(module, address) or ref[address-BASE] != 0):
            raise ValueError(f'invalid writable BSS cell at {address:05o}')
    # UJ does not always force a word boundary in Madlen. Name the next word
    # explicitly when its right half was only a UTC filler in the binary.
    for address in range(module['start'], module['end']):
        left, right = ref[address-BASE] >> 24, ref[address-BASE] & 0xffffff
        reg, op, _, long = operand(left)
        if code_at(module, address) and long and op == 0o30 and right == 0o2200000:
            targets.add(address+1)
    boundaries = targets | set(module['entries'].values())
    for address in range(module['start'], module['end']):
        if address in bss and address-1 in bss and address not in boundaries:
            continue
        for name, entry in module['entries'].items():
            if address == entry and name != module['name']:
                body.append(f' {name}:,ENTRY,')
        if module['name'] == 'ERROR':
            comment = {
                0o7036: 'Entry: A = destination; stack top = status. Registers are decimal.',
                0o7040: 'Scan 25 packed table entries, comparing their high 24 status bits.',
                0o7045: 'Match: load the selected message address into register 14.',
                0o7046: 'Copy: set bit 0200 on KOI-7 Cyrillic bytes; stop after newline.',
                0o7054: 'Data pairs: high half = status, low half = message address.',
                0o7105: 'Messages, retained byte for byte; LF is ISO escape 12.',
                0o7231: 'High-24 mask, six spaces, per-byte high-bit mask, LF.',
                0o7235: 'Default message for a status absent from the table.',
            }.get(address)
            if comment:
                body.append('C '+comment)
        label = f' R{address:05o}:' if address in targets else ' '
        word = ref[address-BASE]
        if address in bss:
            end = address+1
            while end in bss and end not in boundaries:
                end += 1
            body.append(label+f',BSS,{end-address}')
            continue
        if address in module.get('pointers', []):
            # Packed table data: status in the high 24 bits, address in the low.
            # ATX encodes the unchanged high half; Z00 supplies a linker fixup.
            value = word >> 24
            body.append(label+f',ATX,{value:o}B')
            body.append(' ,Z00,'+expression(word & 0o77777, module))
            continue
        if not code_at(module, address):
            if word == 0o1002004010020040 or any(
                    lo <= address < hi for lo, hi in module.get('text', [])):
                data = word.to_bytes(6, 'big').rstrip(b' ')
                # ISO pads to six bytes; escape only nonprinting/high-bit bytes.
                literal = ''.join(chr(b) if 32 <= b <= 95 and b != 39
                                  else f"'{b:o}'" for b in data)
                body.append(label+f',ISO,6H{literal}')
            elif word in GOST_LITERALS:
                body.append(label+f',GOST,6H{GOST_LITERALS[word]}')
            else:
                body.append(label+f',LOG,{word:016o}')
            continue
        for side, shift in [('L', 24), ('R', 0)]:
            half = (word >> shift) & 0xffffff
            reg, op, arg, long = operand(half)
            mnemonic = LONG[op] if long else SHORT[op] if op < len(SHORT) else f'*{op:o}'
            r = relocations.get((address, side))
            value = r['expression'] if r else f'{arg:o}B' if arg else ''
            body.append((label if side == 'L' else ' ')+f'{reg if reg else ""},{mnemonic},{value}')
            aligns = (long and op in (0o30, 0o31)) or (not long and op >= 0o50 and op != 0o60)
            if side == 'L' and aligns and word & 0xffffff == 0o2200000:
                break
    lines = ['C Recovered by runtime/file-access.py from COMP on volume 4001.',
             f'C Reference SHA256 {digest[:32]}', f'C                  {digest[32:]}',
             f'C Original range {module["start"]:05o}..{module["end"]-1:05o}; octal.',
             'C DB* names are recovery names. ERROR/MKNAME/OPENF are source names.',
             f' {module["name"]}:,NAME,']
    lines += [f' {name}:,SUBP,' for name in sorted(dependencies)]
    lines += body+[' ,END,']
    (DEST/module['file']).write_text('\n'.join(lines)+'\n')


def assemble(evidence):
    # Link/dump only; PROGRAM immediately halts and never calls the recovered API.
    from build import BOOT, dump, job
    from libmatch import load_symbols
    work = HERE/'build/file-access'
    sources = ''.join((DEST/m['source']).read_text() for m in evidence['modules'])
    cards = '*libra:13\n*call ficmemory\n*assem\n'
    cards += ' PROGRAM:,NAME,\n'
    cards += ''.join(f' {m["name"]}:,SUBP,\n' for m in evidence['modules'])
    cards += ' ,*74,\n ,END,\n'
    # These stubs resolve the two converters for an assembly-only link. The API
    # is never executed; real programs must supply their appropriate converters.
    cards += ' MONOUT:,NAME,\n 15,UJ,\n ,END,\n MONIN:,NAME,\n 15,UJ,\n ,END,\n'
    cards += sources+'*perso:311160,cont\n'+BOOT
    listing = job(work, 'assembled', cards)
    image = dump(work, 'assembled', listing)
    symbols = {s.name: s.address for s in load_symbols(listing)}
    ref, actual = read_words(REFERENCE), read_words(image)
    count = 0
    for module in evidence['modules']:
        fields = defaultdict(list)
        for r in module['relocations']:
            fields[int(r['word'], 8)].append(r)
        for address in range(int(module['start'], 8), int(module['end'], 8)):
            expected = ref[address-BASE]
            for r in fields[address]:
                target = int(r['target'], 8)
                if target in EXTERNALS:
                    value = symbols[EXTERNALS[target]]
                else:
                    owner = next(m for m in evidence['modules']
                                 if int(m['start'], 8) <= target < int(m['end'], 8))
                    value = symbols[owner['name']]+target-int(owner['start'], 8)
                shift = 24 if r['half'] == 'L' else 0
                expected = (expected & ~(0o77777 << shift)) | (value << shift)
            location = symbols[module['name']]+address-int(module['start'], 8)
            if expected != actual[location-BASE]:
                raise ValueError(f'assembled word differs at {address:05o} -> {location:05o}')
            count += 1
        for name, address in module['entries'].items():
            if symbols[name] != symbols[module['name']]+int(address, 8)-int(module['start'], 8):
                raise ValueError(f'assembled entry differs: {name}')
    report = dict(words=count, listing=str(listing.relative_to(ROOT)),
                  image=str(image.relative_to(ROOT)),
                  loaded={m['name']: f'{symbols[m["name"]]:05o}' for m in evidence['modules']},
                  converter_stubs=True, api_executed=False)
    (DEST/'assembly.json').write_text(json.dumps(report, indent=2)+'\n')
    print(f'Assembled and linked {count} words exactly after relocation; API not executed')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--assemble', action='store_true')
    args = parser.parse_args()
    evidence = recover()
    if args.assemble:
        assemble(evidence)
