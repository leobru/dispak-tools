#!/usr/bin/env python3
"""Rebuild MT on private disks, without executing its tape/disk operations.

Usage: python3 programs/mt/build.py [--explore] [--source file.pas]
--explore records differences during reconstruction instead of rejecting them.
Artifacts are kept under runtime/build/mt. No original volume is written.
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
import build
from build import job, environment
from libmatch import load_symbols, operand

spec = importlib.util.spec_from_file_location('compbuild', PROGRAMS/'comp/build.py')
comp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(comp)
ORIGINAL = IMAGES/'4001/0172-mt.bin'
WORK = BUILD/'mt'
SERVICES = ['lib.madlen', 'tapeio.madlen', 'dbpasc.madlen', 'dbcore.madlen']


def library_sources():
    spec = importlib.util.spec_from_file_location('mtdbuild', PROGRAMS/'mtd/build.py')
    mtd = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mtd)
    text = mtd.library_sources()
    # MT uses COMP's newer conversion tables, unlike MTD.
    text = text.replace('0401053141407416', '0401053141407417')
    text = text.replace('0705613303607417', '0705613303607416')
    cw = read_words(comp.ORIGINAL)
    extension = ''.join(f' ,LOG,{w:016o}\n' for w in cw[0o10606-BASE:0o10616-BASE])
    text = text.replace(' R03314:', extension+' R03314:')
    for module in ('TAPEIO', 'DBFILE', 'DBPASC', 'DBCORE'):
        start = text.index(' '+module+':,NAME,')
        end = text.index(' ,END,', start)+len(' ,END,\n')
        text = text[:start]+text[end:]
    return text+''.join((HERE/name).read_text() for name in SERVICES)


def references(volume, disk):
    """Extract missing reference binaries with besmtool; never rewrite one."""
    manifest = json.loads((CORPUS).read_text())
    env = os.environ.copy()
    env['BESM6_PATH'] = str(volume.parent)
    for stem, zone, count in [('0172-mt', 0o172, 3),
                              ('0104-orphan-0104', 0o104, 2),
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
    for row in (HERE/'mt.sym').read_text().splitlines():
        addr, kind, name = row.split()
        if int(addr,8) >= 0o3415:
            names[int(addr,8)] = name
    differences, fixups = [], []
    pool = (actual[symbols['PROGRAM']-BASE] >> 24) & 0o77777
    for a in range(0o2012, 0o3415):
        old = ref[a-BASE]
        new = actual[a-BASE] if a-BASE<len(actual) else 0
        if old == new:
            continue
        expected = old
        pending = []
        if a < 0o2753:
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
    for name, lo, hi in [('code',0o2012,0o2753), ('constants_and_pmd',0o2753,0o3240),
                          ('initial_globals_and_files',0o3240,0o3415),
                          ('runtime',0o3415,0o6102), ('padding',0o6102,0o10000)]:
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
    placement = {'PROGRAM':0o2012, 'P/1D':0o3240, '*INPUT*':0o3321,
                 '*OUTPUT*':0o3357, 'LIB':0o4203, 'TAPEIO':0o4622,
                 'DBPASC':0o5367, 'DBCORE':0o5422, 'PASPMDAD':0o5562,
                 'FREE':0o6102}
    return dict(range=['02012','03414'], words=771, code_words=481,
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
    parser.add_argument('--source', type=Path, default=HERE/'mt.pas')
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
                            ' P/1D:,LC,49\n *INPUT*:,LC,30\n *OUTPUT*:,LC,30')
    # Assemble P/BOOT after PERSO selection so its LC declaration order wins.
    # P/CODER is a separate three-word loader common, not an ENTRY in P/BOOT.
    cards = '*libra:13\n*call ficmemory\n*trans:newpasc,,320000\n'
    cards += args.source.read_text()+'\n'
    cards += '*perso:311160,cont\n*perso:320200,cont\n*perso:670100,cont\n'
    cards += '*assem\n'+header
    cards += ('*table:p/coder(w*660172,l*3)\n*main pascoder\n'
              '*execute\n*end file\n``````\nеконец\n')
    listing = job(WORK,'mt',cards)
    if re.search(r'\bIN\s+\d+\s+LINES\s+[1-9]\d*\s+ERRORS',listing.read_text()):
        raise ValueError('Pascal compilation failed; see '+str(listing))
    image = WORK/'mt.img'
    subprocess.run(['besmtool','dump','3777','--start=0172','--length=3',
                    '--to-file='+str(image)],env=environment(WORK),check=True,
                   stdout=subprocess.DEVNULL)
    data = image.read_bytes()
    if len(data)>18432 or len(data)%6:
        raise ValueError('rebuilt MT does not fit its three-zone extent')
    image.write_bytes(data+bytes(18432-len(data)))
    report = compare(image,listing)
    from variants import compare_variants
    report['variant_comparison'] = compare_variants()
    if sha(original_disk.read_bytes()) != sha(raw):
        raise ValueError('original volume changed')
    if sha(installed77.read_bytes()) != installed77_hash:
        raise ValueError('installed volume 77 changed')
    report.update(source=str(args.source.relative_to(ROOT)),
                  source_sha256=sha(args.source.read_bytes()),compiler=compiler,
                  build_source_sha256={str(p.relative_to(ROOT)):sha(p.read_bytes()) for p in
                      [HERE/'build.py', *(HERE/name for name in SERVICES), HERE/'mt.sym',
                       HERE/'variants.py',
                       HERE/'mt-readable.pas', PROGRAMS/'mtd/build.py', comp.HERE/'build.py',
                       comp.more.HERE/'build.py']},
                  library_source_sha256=sha(sources.encode()),
                  image=str(image.relative_to(ROOT)),
                  image_sha256=sha(image.read_bytes()),
                  original=str(ORIGINAL.relative_to(ROOT)), original_zones=['0172','0173','0174'],
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
        raise ValueError('image differs beyond 02010.L; see runtime/build/mt/reconstruction.json')
    if not args.explore:
        (HERE/'variants.json').write_text(
            json.dumps(report['variant_comparison'],indent=2)+'\n')
        (HERE/'reconstruction.json').write_text(json.dumps(report,indent=2)+'\n')
        print(f'{report["full_image_identical_words"]}/3072 complete image words identical; '
              'only the loader descriptor left half may differ')


if __name__ == '__main__':
    main()
