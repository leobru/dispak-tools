#!/usr/bin/env python3
"""Compare ACC2 on 4001/0215-0254 and 2248/2440-2477, read-only.

Usage: python3 programs/acc2/compare.py
Extracts stay in build/acc2/compare; no volume is repaired or written.
Zone and memory addresses in the report are octal; counts are decimal.
"""
from pathlib import Path
import json
import os
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import BUILD
from corpus import find_volume, read_words, volume_words

WORK = BUILD/'acc2/compare'


def main():
    WORK.mkdir(parents=True, exist_ok=True)
    search = os.environ.get('BESM6_PATH',
                            f'{Path.home()}/.besm6:/usr/local/share/besm6')
    paths = {'4001': find_volume()}
    paths['2248'] = next(Path(d)/'2248' for d in search.split(':')
                         if (Path(d)/'2248').is_file())
    images, layouts = {}, {}
    for vol, start in [('4001', 0o215), ('2248', 0o2440)]:
        path = WORK/f'{vol}-{start:04o}-acc2.bin'
        env = {**os.environ, 'BESM6_PATH': str(paths[vol].parent)}
        subprocess.run(['besmtool', 'dump', vol, f'--start=0{start:o}',
                        '--length=32', '--to-file='+str(path)], env=env,
                       check=True, stdout=subprocess.DEVNULL)
        words = images[vol] = read_words(path)
        assert len(words) == 32*1024
        parts = []
        for name, offset, base in [('head', 0, 0o2000),
                                   ('ov1', 4, 0o4000),
                                   ('ov2', 0o20, 0o4000)]:
            count = words[offset*1024+0o11]
            entry = words[offset*1024+0o13]
            pool, startup = entry >> 24 & 0o77777, entry & 0o77777
            parts.append(dict(name=name, first_zone=f'{start+offset:04o}',
                              last_zone=f'{start+offset+count-1:04o}',
                              loaded_zones=count, base=f'{base:05o}',
                              pool=f'{pool:05o}', startup=f'{startup:05o}',
                              application_words=pool-base-0o14))
        layouts[vol] = parts
    a, b = images['4001'], images['2248']
    zones = []
    for z in range(32):
        x, y = a[z*1024:(z+1)*1024], b[z*1024:(z+1)*1024]
        zones.append(dict(zone4001=f'{0o215+z:04o}',
                          zone2248=f'{0o2440+z:04o}',
                          nonzero4001=sum(v != 0 for v in x),
                          nonzero2248=sum(v != 0 for v in y),
                          equal_words=sum(u == v for u,v in zip(x,y)),
                          equal_nonzero_words=sum(u == v and u != 0
                                                  for u,v in zip(x,y))))
    assert all(v == 0 for v in a[8*1024:9*1024])
    # Search the full physical 2248 payload, excluding service words.
    # This looks for real surviving code, never a zero-filled needle.
    _, disk = volume_words(paths['2248'])
    anchors = []
    for address in [0o12000, 0o13740, 0o16000, 0o17000]:
        offset = 4*1024+address-0o4000
        needle = a[offset:offset+16]
        assert any(needle)
        hits = [dict(zone=f'{p//1024:04o}', offset=f'{p%1024:04o}')
                for p in range(len(disk)-15)
                if disk[p] == needle[0] and disk[p:p+16] == needle]
        anchors.append(dict(address4001=f'{address:05o}', words=16, hits=hits))
    report = dict(volumes={k:str(v) for k,v in paths.items()},
                  allocations={'4001':['0215','0254'], '2248':['2440','2477']},
                  layouts=layouts, zones=zones,
                  missing=dict(volume='4001', zone='0225', words=1024,
                               overlay='ov1', addresses=['14000','15777']),
                  full_2248_exact_anchor_search=anchors,
                  direct_zone_recovery_established=False,
                  replacement_written=False)
    (HERE/'comparison.json').write_text(json.dumps(report, indent=2)+'\n')
    print('Image layouts (octal addresses; decimal counts):')
    for vol, parts in layouts.items():
        for p in parts:
            print(vol, p)
    print('Missing: 4001/0225, overlay 1 addresses 14000-15777')
    print('Exact 16-word anchors elsewhere on 2248:',
          sum(len(x['hits']) for x in anchors))


if __name__ == '__main__':
    main()
