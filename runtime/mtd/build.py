#!/usr/bin/env python3
"""Rebuild MTD on private disks, without executing its tape/disk operations.

Usage: python3 runtime/mtd/build.py [--explore] [--source file.pas]
--explore records differences during reconstruction instead of rejecting them.
Artifacts are kept under runtime/build/mtd. No original volume is written.
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
ORIGINAL = IMAGES/'4001/0047-mtd.bin'
WORK = BUILD/'mtd'


def library_sources():
    text = comp.library_sources()
    # MTD uses the earlier converter tables present in the Monitor profile.
    text = text.replace('0401053141407417', '0401053141407416')
    text = text.replace('0705613303607416', '0705613303607417')
    cw = read_words(comp.ORIGINAL)
    extension = ''.join(f' ,LOG,{w:016o}\n' for w in cw[0o10606-BASE:0o10616-BASE])
    if text.count(extension) != 1:
        raise ValueError('unexpected MONIN extension')
    text = text.replace(extension, '')
    # MTD's P/HT has ten words; PASPMDAD is a separate one-word common.
    if text.count(' R03532:,LOG,0000000000000000\n') != 1:
        raise ValueError('unexpected P/HT tail')
    text = text.replace(' R03532:,LOG,0000000000000000\n', '')
    start = text.index(' P/SYS:,NAME,')
    end = text.index(' ,END,',start)
    system = text[start:end].replace(' P/PUTERR:,SUBP,\n', '')
    system = system.replace(' *TTIO*:,SUBP,', ' *TTIO*:,SUBP,\n P/PUTERR:,SUBP,')
    text = text[:start]+system+text[end:]
    # MTD has the original P/EO name for EOLN, as in COMP. READLINE is a
    # FORTRAN call to the entry immediately after P/RET.
    # Its tape helper's historical symbol is not retained: TAPEIO is invented.
    text += (HERE/'tapeio.madlen').read_text()
    return text


def references(volume, disk):
    """Extract missing reference binaries with besmtool; never rewrite one."""
    manifest = json.loads((CORPUS).read_text())
    env = os.environ.copy()
    env['BESM6_PATH'] = str(volume.parent)
    for stem, zone, count in [('0047-mtd', 0o47, 2),
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
    for row in (HERE/'mtd.sym').read_text().splitlines():
        addr, kind, name = row.split()
        if int(addr,8) >= 0o3257:
            names[int(addr,8)] = name
    differences, fixups = [], []
    pool = (actual[symbols['PROGRAM']-BASE] >> 24) & 0o77777
    for a in range(0o2012, 0o3257):
        old = ref[a-BASE]
        new = actual[a-BASE] if a-BASE<len(actual) else 0
        if old == new:
            continue
        expected = old
        pending = []
        if a < 0o2640:
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
    for name, lo, hi in [('code',0o2012,0o2640), ('constants_and_pmd',0o2640,0o3076),
                          ('initial_globals_and_files',0o3076,0o3257),
                          ('runtime',0o3257,0o5122), ('padding',0o5122,0o6000)]:
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
    placement = {'PROGRAM':0o2012, 'P/1D':0o3076, '*INPUT*':0o3163,
                 '*OUTPUT*':0o3221, 'TAPEIO':0o4045, 'FREE':0o5122}
    return dict(range=['02012','03256'], words=677, code_words=406,
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
    parser.add_argument('--source', type=Path, default=HERE/'mtd.pas')
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
                            ' P/1D:,LC,53\n *INPUT*:,LC,30\n *OUTPUT*:,LC,30')
    # Assemble P/BOOT after PERSO selection so its LC declaration order wins.
    # P/CODER is a separate three-word loader common, not an ENTRY in P/BOOT.
    cards = '*libra:13\n*call ficmemory\n*trans:newpasc,,320000\n'
    cards += args.source.read_text()+'\n'
    cards += '*perso:311160,cont\n*perso:320200,cont\n*perso:670100,cont\n'
    cards += '*assem\n'+header
    cards += ('*table:p/coder(w*660047,l*2)\n*main pascoder\n'
              '*execute\n*end file\n``````\nеконец\n')
    listing = job(WORK,'mtd',cards)
    if re.search(r'\bIN\s+\d+\s+LINES\s+[1-9]\d*\s+ERRORS',listing.read_text()):
        raise ValueError('Pascal compilation failed; see '+str(listing))
    image = WORK/'mtd.img'
    subprocess.run(['besmtool','dump','3777','--start=047','--length=2',
                    '--to-file='+str(image)],env=environment(WORK),check=True,
                   stdout=subprocess.DEVNULL)
    data = image.read_bytes()
    if len(data)>12288 or len(data)%6:
        raise ValueError('rebuilt MTD does not fit its two-zone extent')
    image.write_bytes(data+bytes(12288-len(data)))
    report = compare(image,listing)
    if sha(original_disk.read_bytes()) != sha(raw):
        raise ValueError('original volume changed')
    if sha(installed77.read_bytes()) != installed77_hash:
        raise ValueError('installed volume 77 changed')
    report.update(source=str(args.source.relative_to(ROOT)),
                  source_sha256=sha(args.source.read_bytes()),compiler=compiler,
                  build_source_sha256={str(p.relative_to(ROOT)):sha(p.read_bytes()) for p in
                      [HERE/'build.py', HERE/'tapeio.madlen', HERE/'mtd.sym',
                       HERE/'mtd-readable.pas', comp.HERE/'build.py',
                       comp.more.HERE/'build.py']},
                  library_source_sha256=sha(sources.encode()),
                  image=str(image.relative_to(ROOT)),
                  image_sha256=sha(image.read_bytes()),
                  original=str(ORIGINAL.relative_to(ROOT)), original_zones=['0047','0050'],
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
        raise ValueError('image differs beyond 02010.L; see runtime/build/mtd/reconstruction.json')
    if not args.explore:
        (HERE/'reconstruction.json').write_text(json.dumps(report,indent=2)+'\n')
        print(f'{report["full_image_identical_words"]}/2048 complete image words identical; '
              'only the loader descriptor left half may differ')


if __name__ == '__main__':
    main()
