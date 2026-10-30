#!/usr/bin/env python3
"""Extract and cross-check PAK copies, without writing to source volumes.

Usage: python3 programs/pak/extract.py [--edition 2053|2113]
The copies go to build/pak/original, the reference to build/pak;
only the provenance JSON is kept in programs/pak/original.
Volumes are resolved by besmtool through BESM6_PATH/default search paths.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import BUILD
WORK=BUILD/'pak'
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--edition',choices=['2053','2113'],default='2053')
args=parser.parse_args()
new=args.edition=='2113'
out=WORK/'original'
out.mkdir(parents=True,exist_ok=True)
copies=[]
for disk,zone in ([(2113,'01246')] if new else [(2053,'0437'),(2048,'0034'),(2248,'03044')]):
    filename=out/f'pak-{disk}.bin'
    subprocess.run(['besmtool','dump',str(disk),'--start='+zone,
                    '--length=4','--to-file='+str(filename)],check=True)
    data=filename.read_bytes()
    if len(data)!=4*1024*6:
        raise ValueError(f'{filename}: expected four zones, got {len(data)} bytes')
    copies.append(dict(volume=disk,first_zone=zone,zones=4,
                       bytes=len(data),sha256=hashlib.sha256(data).hexdigest()))
if len({row['sha256'] for row in copies})!=1:
    raise ValueError('PAK copies differ; investigate rather than choosing one')
(WORK/('pak-2113.bin' if new else 'pak.bin')).write_bytes(
    (out/('pak-2113.bin' if new else 'pak-2053.bin')).read_bytes())
(HERE/'original'/('2113-provenance.json' if new else 'provenance.json')).write_text(json.dumps(copies,indent=2)+'\n')
print('Extracted edition 2113:' if new else 'All three copies match:',copies[0]['sha256'])
