#!/usr/bin/env python3
"""Compile recovered MORE to private scratch disks; dump without running MORE.

Usage: python3 runtime/more/build.py
The link uses recovered Monitor helpers and COMP's file-access library.
Artifacts live in runtime/build/more. Reference disks are read-only.
"""

from pathlib import Path
import json
import os
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from build import BOOT, dump, environment, expected_word, job
from corpus import BASE, ROOT, find_volume, pack, read_words, sha, volume_words
from recover import LONG, SHORT
from libmatch import load_symbols, operand

HELPERS = [
    ('P/STAR', '0315-comp', 0o6320, 0o6332, {}),
    ('P/IN', '0034-more', 0o3567, 0o3577, {}),
]


def extra_helpers():
    lines = []
    for name, image, start, end, externals in HELPERS:
        words = read_words(HERE.parent/'images/4001'/f'{image}.bin')
        lines += [f' {name}:,NAME,']+[f' {v}:,SUBP,' for v in externals.values()]
        for address in range(start, end):
            for shift in (24, 0):
                if shift == 0:
                    _, left_op, left_arg, left_long = operand(words[address-BASE] >> 24)
                    if left_long and left_op in (0o30, 0o31) and left_arg:
                        if words[address-BASE] & 0xffffff != 0o02200000:
                            raise ValueError('unexpected helper alignment word')
                        # Madlen supplies this right-half filler itself.
                        continue
                reg, op, value, long = operand((words[address-BASE] >> shift) & 0xffffff)
                arg = externals.get(value, f'X{value:05o}' if start <= value < end
                                    else f'{value:o}B' if value else '')
                mnemonic = LONG[op] if long else SHORT[op]
                label = f' X{address:05o}:' if shift == 24 else ' '
                lines.append(label+f'{reg if reg else ""},{mnemonic},{arg}')
        lines += [' ,END,']
    return '\n'.join(lines)+'\n'


def runtime_sources():
    directory = HERE.parent/'profiles/monitor'
    meta = json.loads((directory/'relocations.json').read_text())
    sources = []
    for name in meta['sources']+meta['helper_sources']:
        source = (directory/name).read_text()
        if name == 'p_sys.madlen':
            # This Monitor calls its EOLN entry P/EO. The compiler uses P/EL
            # for EOLN and P/EO for EOF; supply the latter in extra_helpers.
            source = source.replace(' P/EO:,ENTRY,', ' P/EL:,ENTRY,')
            source = source.replace(' 9,VTM,*TTIO*+26B\n ,UJ,R02644',
                                    ' P/EO:,ENTRY,\n 9,VTM,*TTIO*+26B\n ,UJ,R02644')
            # Call the historical accumulator/stack entry as ASSEMBLER.
            source = source.replace(' ,STI,14B\n ,ITA,15B\n 9,VTM,*TTIO*',
                ' READLINE:,ENTRY,\n ,STI,14B\n ,ITA,15B\n 9,VTM,*TTIO*')
        elif name == 'monout.madlen':
            source = source.replace('0401053141407416', '0401053141407417')
            source = source.replace('0705613303607417', '0705613303607416')
        elif name == 'monin.madlen':
            comp = read_words(HERE.parent/'images/4001/0315-comp.bin')
            extension = ''.join(f' ,LOG,{w:016o}\n' for w in comp[0o10606-BASE:0o10616-BASE])
            source = source.replace(' R03314:', extension+' R03314:')
        elif name == 'p_1.madlen':
            # Retain MORE's Monitor loader with its descriptor at 02010.
            source = source.replace(',WTC,2007B', ',WTC,2010B')
            lines = source.splitlines()
            first = next(i for i, line in enumerate(lines) if line.startswith(' INI'))
            lines[first+0o46] = ' ,LOG,0000000000100000'
            source = '\n'.join(lines)+'\n'
        sources.append(source)
    files = HERE.parent/'file-access'
    api = json.loads((files/'relocations.json').read_text())
    sources += [(files/module['source']).read_text() for module in api['modules']]
    return ''.join(sources)+extra_helpers()


def compare_link(image, listing):
    """Audit the recovered words in the final, independently relocated image."""
    symbols = {s.name: s.address for s in load_symbols(listing)}
    actual = read_words(image)
    # These four calls pass their last VAR argument as ITS 14, with no final
    # ATX (SP). Every return must restore the caller's M8 constant-pool base.
    constants = (actual[symbols['PROGRAM']-BASE] >> 24) & 0o77777
    targets = {symbols[name]: name for name in ('MKNAME', 'OPENF', 'ERROR')}
    calls = dict.fromkeys(targets.values(), 0)
    for address in range(symbols['PROGRAM'], constants):
        for shift in (24, 0):
            _, op, target, is_long = operand((actual[address-BASE] >> shift) & 0xffffff)
            if not (is_long and op == 0o31 and target in targets):
                continue
            previous = (actual[address-BASE-1] & 0xffffff if shift == 24
                        else actual[address-BASE] >> 24)
            if previous != 0o00430016:
                raise ValueError('last ASSEMBLER argument is not left in A')
            if actual[address+1-BASE] >> 24 != (0o42400000 | constants):
                raise ValueError('ASSEMBLER caller does not restore M8')
            calls[targets[target]] += 1
    if calls != {'MKNAME': 1, 'OPENF': 1, 'ERROR': 2}:
        raise ValueError('unexpected ASSEMBLER calls in MORE')
    helper_words = 0
    for name, reference, start, end, externals in HELPERS:
        source = read_words(HERE.parent/'images/4001'/f'{reference}.bin')
        for address in range(start, end):
            expected = source[address-BASE]
            for shift in (24, 0):
                _, _, target, is_long = operand((expected >> shift) & 0xffffff)
                if target in externals:
                    value = symbols[externals[target]]
                elif start <= target < end:
                    value = symbols[name]+target-start
                else:
                    continue
                mask = 0o77777 if is_long else 0o7777
                expected = (expected & ~(mask << shift)) | (value << shift)
            if actual[symbols[name]+address-start-BASE] != expected:
                raise ValueError(f'{name}: different helper word {address:05o}')
            helper_words += 1
    comp = read_words(HERE.parent/'images/4001/0315-comp.bin')
    api = json.loads((HERE.parent/'file-access/relocations.json').read_text())
    count = 0
    for module in api['modules']:
        fields = {}
        for r in module['relocations']:
            fields.setdefault(int(r['word'], 8), []).append(r)
        for address in range(int(module['start'], 8), int(module['end'], 8)):
            expected = comp[address-BASE]
            for r in fields.get(address, []):
                target = int(r['target'], 8)
                if r['target'] in api['externals']:
                    value = symbols[api['externals'][r['target']]]
                else:
                    owner = next(m for m in api['modules']
                                 if int(m['start'], 8) <= target < int(m['end'], 8))
                    value = symbols[owner['name']]+target-int(owner['start'], 8)
                shift = 24 if r['half'] == 'L' else 0
                expected = (expected & ~(0o77777 << shift)) | (value << shift)
            location = symbols[module['name']]+address-int(module['start'], 8)
            if actual[location-BASE] != expected:
                raise ValueError(f'{module["name"]}: different recovered word {address:05o}')
            count += 1
        for name, entry in module['entries'].items():
            if symbols[name] != symbols[module['name']]+int(entry, 8)-int(module['start'], 8):
                raise ValueError('external entry mismatch: '+name)
    # Check the Monitor chunks, accounting for MORE's loader descriptor slot.
    meta = json.loads((HERE.parent/'profiles/monitor/relocations.json').read_text())
    monitor = read_words(ROOT/meta['source'])
    monitor_words = 0
    for chunk in meta['chunks']:
        if chunk['name'] not in symbols or chunk['name'] in ('MONOUT', 'MONIN'):
            continue
        for address in range(int(chunk['start'], 8), int(chunk['end'], 8)):
            expected = expected_word(monitor[address-BASE], address, meta, symbols)
            if address == 0o2774:
                expected = (expected & ~0o77777) | 0o2010
            location = symbols[chunk['name']]+address-int(chunk['start'], 8)
            if actual[location-BASE] != expected:
                raise ValueError(f'{chunk["name"]}: different Monitor word {address:05o}')
            monitor_words += 1
    # Converters use COMP's tables, including its eight extra MONIN words.
    for name, lo, hi in [('MONOUT', 0o10455, 0o10547), ('MONIN', 0o10547, 0o10617)]:
        for address in range(lo, hi):
            expected = comp[address-BASE]
            for shift in (24, 0):
                _, op, target, long = operand((expected >> shift) & 0xffffff)
                if address < (0o10501 if name == 'MONOUT' else 0o10556) and long and lo <= target < hi:
                    expected = (expected & ~(0o77777 << shift)) | ((symbols[name]+target-lo) << shift)
            if actual[symbols[name]+address-lo-BASE] != expected:
                raise ValueError(f'{name}: different COMP converter word {address:05o}')
    original = read_words(HERE.parent/'images/4001/0034-more.bin')
    # Both images reserve the same 0117-word global area before the TEXT files.
    original_globals = original[0o2701-BASE:0o3020-BASE]
    rebuilt_globals = actual[symbols['P/1D']-BASE:symbols['P/1D']-BASE+len(original_globals)]
    if rebuilt_globals != original_globals:
        raise ValueError('rebuilt global constants/state differ')
    if actual[0o2010-BASE] & 0o77777 != symbols['FREE']:
        raise ValueError('PASCODER stack descriptor does not match the rebuilt image')
    if actual[2] >> 24 != 0o17400000 | symbols['PROGRAM']:
        raise ValueError('saved loader does not transfer control to PROGRAM')
    return dict(comp_file_library_words=count, monitor_words=monitor_words,
                additional_helper_words=helper_words,
                assembler_calls_checked=calls,
                comp_converter_words=98, global_words=len(original_globals),
                entry=f'{symbols["PROGRAM"]:05o}', free=f'{symbols["FREE"]:05o}',
                globals=f'{symbols["P/1D"]:05o}')


def restored_volume(work, image):
    source = find_volume()
    target = work/'4001'
    if source.resolve() == target.resolve():
        raise ValueError('source volume must be distinct from the private restored copy')
    raw, original_words = volume_words(source)
    expected_sha = json.loads((HERE.parent/'corpus.json').read_text())['volume']['sha256']
    if sha(raw) != expected_sha:
        raise ValueError('source volume differs from the cataloged 4001')
    data = image.read_bytes()
    if len(data) != 3*1024*6:
        raise ValueError('rebuilt image no longer fits MORE\'s three-zone catalog extent')
    target.write_bytes(raw)
    subprocess.run(['besmtool', 'write', '4001', '--start=034', '--length=3',
                    '--from-file='+str(image)], env=environment(work), check=True,
                   stdout=subprocess.DEVNULL)
    new_raw, new_words = volume_words(target)
    lo, hi = 0o34*1024, 0o37*1024
    if (new_words[:lo] != original_words[:lo] or new_words[hi:] != original_words[hi:]
            or pack(new_words[lo:hi]) != data):
        raise ValueError('private volume replacement changed unexpected payload words')
    physical_lo, physical_hi = (0o34+4)*1032*8, (0o37+4)*1032*8
    if new_raw[:physical_lo] != raw[:physical_lo] or new_raw[physical_hi:] != raw[physical_hi:]:
        raise ValueError('private volume changed outside MORE\'s physical zones')
    if sha(source.read_bytes()) != expected_sha:
        raise ValueError('source volume changed during reconstruction')
    # No volume hash: every zone written by dispak carries a time stamp.
    return dict(path=str(target.relative_to(ROOT)),
                source_sha256=expected_sha, replaced_zones=['0034', '0035', '0036'],
                zone_0035_nonzero_words=sum(w != 0 for w in new_words[0o35*1024:0o36*1024]),
                other_payload_words_unchanged=True, other_physical_zones_unchanged=True,
                source_unchanged=True)


def compare_pascal(image, listing):
    """Require the original application words, allowing named runtime fixups."""
    symbols = {s.name: s.address for s in load_symbols(listing)}
    names = {}
    aliases = {'READLN': 'READLINE', 'EOLN': 'P/EL', 'EOF': 'P/EO'}
    for line in (HERE/'more.sym').read_text().splitlines():
        address, kind, name = line.split()
        address = int(address, 8)
        if 0o3114 <= address < 0o74000:
            names[address] = aliases.get(name, name)
    original = read_words(HERE.parent/'images/4001/0034-more.bin')
    actual = read_words(image)
    if (symbols['PROGRAM'], symbols['P/1D'], symbols['*INPUT*'], symbols['*OUTPUT*']) != (
            0o2012, 0o2701, 0o3020, 0o3056):
        raise ValueError('Pascal application/data placement differs from MORE')
    fixups = []
    changed_words = 0
    for address in range(0o2012, 0o3114):
        expected, rebuilt = original[address-BASE], actual[address-BASE]
        if expected == rebuilt:
            continue
        changed_words += 1
        if address >= 0o2516:
            raise ValueError(f'Pascal data mismatch at {address:05o}')
        for shift in (24, 0):
            before = (expected >> shift) & 0xffffff
            after = (rebuilt >> shift) & 0xffffff
            if before == after:
                continue
            _, _, target, is_long = operand(before)
            name = names.get(target)
            if (not is_long or name not in symbols or
                    after != ((before & ~0o77777) | symbols[name])):
                raise ValueError(f'Pascal instruction mismatch at {address:05o}')
            fixups.append(dict(word=f'{address:05o}', half='L' if shift else 'R',
                               name=name, original=f'{target:05o}',
                               rebuilt=f'{symbols[name]:05o}'))
    return dict(range=['02012', '03113'], words=578, code_words=324,
                pool_pmd_words=115, initial_data_words=139,
                raw_identical_words=578-changed_words,
                raw_different_words=changed_words,
                code_identical_after_runtime_relocation=True,
                pool_pmd_bit_identical=True, initial_data_bit_identical=True,
                mismatches_after_runtime_relocation=0, runtime_fixups=fixups,
                saved_readable_source='runtime/more/more-readable.pas',
                saved_readable_sha256=sha((HERE/'more-readable.pas').read_bytes()))


def intactness():
    path = HERE.parent/'images/4001/0034-more.bin'
    words = read_words(path)
    manifest = json.loads((HERE.parent/'corpus.json').read_text())
    entry = next(e for e in manifest['images'] if e['id'] == '4001-0034-more')
    if sha(path.read_bytes()) != entry['sha256']:
        raise ValueError('original MORE extract differs from the corpus')
    _, disk = volume_words(find_volume())
    if disk[0o34*1024:0o37*1024] != words:
        raise ValueError('MORE extract differs from its source volume')
    if any(words[0o4000-BASE:0o6000-BASE]):
        raise ValueError('expected the erased zone to be entirely zero')
    return dict(image=str(path.relative_to(ROOT)), sha256=entry['sha256'],
                entry='02012', application_code=['02012', '02515'],
                application_code_words=0o2516-0o2012,
                constants_and_pmd=['02516', '02700'],
                constants_and_pmd_words=0o2701-0o2516,
                globals_and_file_blocks=['02701', '03113'],
                globals_and_file_words=0o3114-0o2701,
                erased_addresses=['04000', '05777'], erased_words=1024,
                erased_volume_zone='0035', application_before_erasure=True)


def rebuild_compiler(work):
    """Build mypas.b6 on a private 77, without its trailing example job."""
    target = work/'77'
    search = os.environ.get('BESM6_PATH',
                            f'{Path.home()}/.besm6:/usr/local/share/besm6')
    source = next((Path(d)/'77' for d in search.split(':')
                   if (Path(d)/'77').is_file() and
                   (Path(d)/'77').resolve() != target.resolve()), None)
    if source is None:
        raise FileNotFoundError('installed volume 77 is not on BESM6_PATH')
    raw = source.read_bytes()
    target.write_bytes(raw)
    compiler_source = (ROOT/'mypas.b6').read_text()
    prefix, marker, _ = compiler_source.partition('*end record\n')
    if not marker:
        raise ValueError('compiler deck has no overlay record terminator')
    deck = work/'compiler.b6'
    deck.write_text(prefix+marker+'*call ocatalog:670000\n*system\n'
                    '*end file\n``````\nЕКОНЕЦ\n')
    listing = work/'compiler.lst'
    with listing.open('w') as stream:
        subprocess.run(['dispak', '--path='+environment(work)['BESM6_PATH'],
                        '-l', str(deck)], env=environment(work),
                       stdin=subprocess.DEVNULL, stdout=stream,
                       stderr=subprocess.STDOUT, timeout=180, check=True)
    text = listing.read_text(encoding='utf-8-sig')
    # The volume may be unchanged when the installed compiler is the fixpoint.
    if (re.search(r'\bIN\s+\d+\s+LINES\s+[1-9]\d*\s+ERRORS', text) or
            'КОНЕЦ ЗАДАЧИ' not in text or 'LINES STRUCTURE' not in text):
        raise ValueError('compiler rebuild failed; see '+str(listing))
    if source.read_bytes() != raw:
        raise ValueError('installed compiler volume changed')
    return dict(source='mypas.b6', source_sha256=sha((ROOT/'mypas.b6').read_bytes()),
                volume=str(target.relative_to(ROOT)),
                installed_volume_sha256=sha(raw), installed_volume_unchanged=True,
                translator_zone='0000', assembler_last_argument='accumulator',
                assembler_constant_base_restored_by_caller=True)


def main():
    work = HERE.parent/'build/more'
    original_evidence = intactness()
    sources = runtime_sources()
    work.mkdir(parents=True, exist_ok=True)
    compiler = rebuild_compiler(work)
    (work/'runtime.madlen').write_text(sources)
    job(work, 'library', '*call ficmemory\n*assem\n'+sources+
        '*to perso:670100\n*end file\n``````\nеконец\n')
    cards = '*libra:13\n*call ficmemory\n'
    cards += '*trans:newpasc,,320000\n'+(HERE/'more.pas').read_text()+'\n'
    cards += '*perso:311160,cont\n*perso:670100,cont\n'
    boot = BOOT
    boot = boot.replace(' P/CODER:,SUBP,',
                        ' P/1D:,LC,79\n *INPUT*:,LC,30\n *OUTPUT*:,LC,30\n P/CODER:,SUBP,')
    boot = boot.replace(' ,UJ,*1\n ,END,', ' ,UJ,*1\n DUMPEND:,*74,\n ,END,')
    boot = boot.replace('1,VZM,PROGRAM', '1,VZM,DUMPEND')
    listing = job(work, 'more', cards+boot)
    if re.search(r'\bIN\s+\d+\s+LINES\s+[1-9]\d*\s+ERRORS', listing.read_text()):
        raise ValueError('Pascal compilation failed; see '+str(listing))
    image = dump(work, 'more', listing)
    # The build stops after dumping. Use MORE's original Monitor loader in the
    # saved image, retaining the catalog location and updating its stack base.
    symbols = {s.name: s.address for s in load_symbols(listing)}
    words = read_words(image)
    if symbols['PROGRAM'] != 0o2012:
        raise ValueError('unexpected application placement')
    original = read_words(HERE.parent/'images/4001/0034-more.bin')
    words[:0o12] = original[:0o12]
    words[0o10] = (words[0o10] & ~0o77777) | symbols['FREE']
    image.write_bytes(pack(words))
    report = compare_link(image, listing)
    report.update(original=original_evidence, compiler=compiler,
                  pascal_comparison=compare_pascal(image, listing),
                  source_sha256=sha((HERE/'more.pas').read_bytes()),
                  build_source_hashes={p: sha((HERE/p).read_bytes())
                                      for p in ('more.pas', 'build.py')},
                  image=str(image.relative_to(ROOT)), image_sha256=sha(image.read_bytes()),
                  image_words=len(read_words(image)), application_bit_identical=False,
                  interactive_execution=False,
                  volume=restored_volume(work, image))
    evidence = json.dumps(report, indent=2)+'\n'
    (work/'reconstruction.json').write_text(evidence)
    (HERE/'reconstruction.json').write_text(evidence)
    print(image)
    print('Recovered library words and globals agree; restored private volume:', work/'4001')


if __name__ == '__main__':
    main()
