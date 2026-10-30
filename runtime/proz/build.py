#!/usr/bin/env python3
"""Rebuild PROZ on private disks and compare all four original image zones.

Usage: python3 runtime/proz/build.py [--explore] [--source file.pas]
--explore records differences during reconstruction instead of rejecting them.
Artifacts are kept under runtime/build/proz. PROZ's file operations are not
executed. No original volume is written; no linked instruction is patched.
"""
from pathlib import Path
import argparse
import importlib.util
import json
import os
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'runtime' for p in HERE.parents
                            if (p/'runtime/paths.py').exists())))
from paths import ROOT, COMPILER, PROGRAMS, BUILD, IMAGES, CORPUS
from corpus import BASE, pack, read_words, sha, find_volume, volume_words
from build import job, environment
from libmatch import load_symbols, operand

spec = importlib.util.spec_from_file_location('compbuild', PROGRAMS/'comp/build.py')
comp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(comp)
ORIGINAL = IMAGES/'4001/0030-proz.bin'
WORK = BUILD/'proz'


def library_sources():
    spec = importlib.util.spec_from_file_location('mtbuild', PROGRAMS/'mt/build.py')
    mt = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mt)
    spec = importlib.util.spec_from_file_location('monitrbuild', PROGRAMS/'monitr/build.py')
    monitr = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(monitr)
    text = monitr.add_entries(mt.library_sources(), 'LIB', {0o31:'OPENF'})
    text = monitr.add_entries(text, 'P/WO', {1:'P/WH'})
    text, count = re.subn(r' P/A7:,NAME,.*? ,END,\n',
                         (HERE/'p_a7.madlen').read_text(), text, flags=re.S)
    if count != 1:
        raise ValueError('expected one P/A7 module in the inherited runtime')
    for name in ['p_ldarin.madlen', 'p_4.madlen']:
        text += (HERE/name).read_text()
    return text


def references(volume, disk):
    """Extract missing reference binaries with besmtool; never rewrite one."""
    manifest = json.loads((CORPUS).read_text())
    env = os.environ.copy()
    env['BESM6_PATH'] = str(volume.parent)
    for stem, zone, count in [('0030-proz', 0o30, 4),
                              ('0034-more', 0o34, 3),
                              ('0315-comp', 0o315, 8)]:
        path = ORIGINAL.parent/(stem+'.bin')
        if not path.exists():
            path.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(['besmtool', 'dump', '4001', f'--start=0{zone:o}',
                            f'--length={count}', '--to-file='+str(path)],
                           env=env, check=True, stdout=subprocess.DEVNULL)
        entry = next(e for e in manifest['images'] if e['id']=='4001-'+stem)
        if (sha(path.read_bytes()) != entry['sha256'] or
                pack(disk[zone*1024:(zone+count)*1024]) != path.read_bytes()):
            raise ValueError('reference differs from the corpus/source volume: '+str(path))


def compare(image, listing):
    ref, actual = read_words(ORIGINAL), read_words(image)
    symbols = {s.name:s.address for s in load_symbols(listing)}
    names = {}
    for row in (HERE/'proz.sym').read_text().splitlines():
        addr, kind, name = row.split()
        if int(addr,8) >= 0o5060:
            names[int(addr,8)] = name
    differences, fixups = [], []
    pool = (actual[symbols['PROGRAM']-BASE] >> 24) & 0o77777
    for a in range(0o2012, 0o5060):
        old = ref[a-BASE]
        new = actual[a-BASE] if a-BASE<len(actual) else 0
        if old == new:
            continue
        expected = old
        pending = []
        if a < 0o4076:
            for shift in (24,0):
                before = old >> shift & 0xffffff
                _,_,target,long = operand(before)
                name = names.get(target)
                if long and name in symbols:
                    expected = (expected & ~(0o77777<<shift)) | (symbols[name]<<shift)
                    if symbols[name] != target:
                        pending.append(dict(word=f'{a:05o}',half='L' if shift else 'R',
                                            name=name,original=f'{target:05o}',
                                            rebuilt=f'{symbols[name]:05o}'))
        if expected == new:
            fixups += pending
        else:
            differences.append(dict(word=f'{a:05o}',original=f'{old:016o}',
                                    rebuilt=f'{new:016o}'))
    full = [dict(word=f'{a:05o}',original=f'{ref[a-BASE]:016o}',
                 rebuilt=f'{actual[a-BASE] if a-BASE<len(actual) else 0:016o}')
            for a in range(BASE,BASE+len(ref))
            if ref[a-BASE] != (actual[a-BASE] if a-BASE<len(actual) else 0)]
    regions = []
    for name, lo, hi in [('code',0o2012,0o4076), ('constants_and_pmd',0o4076,0o4633),
                          ('initial_globals_and_files',0o4633,0o5060),
                          ('runtime',0o5060,0o10335), ('padding',0o10335,0o12000)]:
        equal = sum(ref[a-BASE] == actual[a-BASE] for a in range(lo,hi))
        regions.append(dict(name=name, range=[f'{lo:05o}',f'{hi-1:05o}'],
                            words=hi-lo, identical_words=equal,
                            bit_identical=equal==hi-lo))
    unexplained = []
    for difference in full:
        a = int(difference['word'],8)
        if a == 0o2010 and (ref[a-BASE] ^ actual[a-BASE]) & 0xffffff == 0:
            difference['cause'] = 'loader descriptor left half; right half FREE is identical'
        else:
            difference['cause'] = 'unexplained'
            unexplained.append(difference)
    placement = {'PROGRAM':0o2012, 'P/1D':0o4633, '*INPUT*':0o4764,
                 '*OUTPUT*':0o5022, '*TTIO*':0o5515, 'LIB':0o6223,
                 'OPENF':0o6254, 'P/LDARIN':0o6115, 'P/4':0o6215,
                 'P/A7':0o10325, 'FREE':0o10335}
    return dict(range=['02012','05057'], words=1574, code_words=1076,
                rebuilt_pool=f'{pool:05o}', globals=f'{symbols["P/1D"]:05o}',
                mismatches=len(differences), differences=differences,
                runtime_fixups=fixups, full_image_different_words=len(full),
                full_image_differences=full, full_image_words=len(ref),
                full_image_identical_words=len(ref)-len(full),
                unexplained_differences=len(unexplained), regions=regions,
                application_bit_identical=all(r['bit_identical'] for r in regions[:3]),
                placement={n:f'{symbols[n]:05o}' for n in placement},
                placement_matches=all(symbols[n]==a for n,a in placement.items()))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--explore', action='store_true')
    parser.add_argument('--source', type=Path, default=HERE/'proz.pas')
    args = parser.parse_args()
    args.source = args.source.resolve()
    for number, line in enumerate(args.source.read_text().splitlines(),1):
        if len(line)>72:
            raise ValueError(f'{args.source}:{number}: exceeds 72-column source card')
    WORK.mkdir(parents=True,exist_ok=True)
    original_disk = find_volume()
    raw, disk = volume_words(original_disk)
    expected = json.loads((CORPUS).read_text())['volume']['sha256']
    if sha(raw) != expected:
        raise ValueError('volume 4001 differs from the cataloged reference')
    references(original_disk, disk)
    search = os.environ.get('BESM6_PATH',f'{Path.home()}/.besm6:/usr/local/share/besm6')
    installed77 = next(Path(d)/'77' for d in search.split(':')
                       if (Path(d)/'77').is_file() and
                       (Path(d)/'77').resolve() != (WORK/'77').resolve())
    installed77_hash = sha(installed77.read_bytes())
    # Reuse the private-compiler build; cache only while mypas.b6 is unchanged.
    stamp = WORK/'compiler.json'
    compiler_hash = sha((COMPILER/'mypas.b6').read_bytes())
    compiler = json.loads(stamp.read_text()) if stamp.exists() else {}
    if compiler.get('source_sha256') != compiler_hash or not (WORK/'77').exists():
        compiler = comp.more.rebuild_compiler(WORK)
        stamp.write_text(json.dumps(compiler,indent=2)+'\n')
    sources = library_sources()
    lib = WORK/'runtime.madlen'
    if not lib.exists() or lib.read_text() != sources or not (WORK/'3776').exists():
        lib.write_text(sources)
        job(WORK,'library','*call ficmemory\n*assem\n'+sources+
            '*to perso:670100\n*end file\n``````\nеконец\n')
    (WORK/'3777').write_bytes(b'')
    header = comp.helper(read_words(ORIGINAL), 'P/BOOT', BASE, 0o2007,
                         data=[(0o2003,0o2004),(0o2006,0o2007)],
                         externals={0o2007:'P/CODER',0o2012:'PROGRAM'})
    header = header.replace(' P/BOOT:,NAME,', ' P/BOOT:,NAME,\n'
                            ' P/1D:,LC,89\n *INPUT*:,LC,30\n *OUTPUT*:,LC,30')
    # Assemble P/BOOT after PERSO selection so its LC declaration order wins.
    # P/CODER is a separate three-word loader common, not an ENTRY in P/BOOT.
    cards = '*libra:13\n*call ficmemory\n*trans:newpasc,,320000\n'
    cards += args.source.read_text()+'\n'
    cards += '*perso:311160,cont\n*perso:320200,cont\n*perso:670100,cont\n'
    cards += '*assem\n'+header
    cards += ('*table:p/coder(w*660000,l*4)\n*main pascoder\n'
              '*execute\n*end file\n``````\nеконец\n')
    listing = job(WORK,'proz',cards)
    if re.search(r'\bIN\s+\d+\s+LINES\s+[1-9]\d*\s+ERRORS',listing.read_text()):
        raise ValueError('Pascal compilation failed; see '+str(listing))
    image = WORK/'proz.img'
    subprocess.run(['besmtool','dump','3777','--start=0','--length=4',
                    '--to-file='+str(image)],env=environment(WORK),check=True,
                   stdout=subprocess.DEVNULL)
    data = image.read_bytes()
    if len(data)>24576 or len(data)%6:
        raise ValueError('rebuilt PROZ does not fit its four-zone extent')
    image.write_bytes(data+bytes(24576-len(data)))
    report = compare(image,listing)
    if sha(original_disk.read_bytes()) != sha(raw):
        raise ValueError('original volume changed')
    if sha(installed77.read_bytes()) != installed77_hash:
        raise ValueError('installed volume 77 changed')
    report.update(source=str(args.source.relative_to(ROOT)),
                  source_sha256=sha(args.source.read_bytes()),compiler=compiler,
                  build_source_sha256={str(p.relative_to(ROOT)):sha(p.read_bytes())
                      for p in [HERE/'build.py', HERE/'p_a7.madlen',
                                HERE/'p_ldarin.madlen', HERE/'p_4.madlen',
                                HERE/'proz.sym', HERE/'proz-readable.pas',
                                PROGRAMS/'mt/build.py',
                                PROGRAMS/'mtd/build.py',
                                PROGRAMS/'monitr/build.py',
                                comp.HERE/'build.py', comp.more.HERE/'build.py']},
                  library_source_sha256=sha(sources.encode()),
                  image=str(image.relative_to(ROOT)),
                  image_sha256=sha(image.read_bytes()),
                  original=str(ORIGINAL.relative_to(ROOT)), original_zones=['0030','0031','0032','0033'],
                  original_sha256=sha(ORIGINAL.read_bytes()),
                  original_volume_sha256=sha(raw),original_volume_unchanged=True,
                  installed_volume77_sha256=installed77_hash,
                  installed_volume77_unchanged=True,
                  interactive_execution=False)
    (WORK/'reconstruction.json').write_text(json.dumps(report,indent=2)+'\n')
    print(f'Compiled: pool={report["rebuilt_pool"]}, P/1D={report["globals"]}; '
          f'{report["mismatches"]} application mismatches, '
          f'{len(report["runtime_fixups"])} runtime fixups')
    if (not args.explore and (report['mismatches'] or report['runtime_fixups'] or
            report['unexplained_differences'] or not report['placement_matches'])):
        raise ValueError('image differs beyond 02010.L; see runtime/build/proz/reconstruction.json')
    if not args.explore:
        (HERE/'reconstruction.json').write_text(json.dumps(report,indent=2)+'\n')
        print(f'{report["full_image_identical_words"]}/4096 complete image words identical; '
              'only the loader descriptor left half may differ')


if __name__ == '__main__':
    main()
