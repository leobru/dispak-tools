#!/usr/bin/env python3
"""Assemble formes.be, write one ЗОНГП zone and compare with 2053/0616."""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess
import build

HERE = Path(__file__).resolve().parent
WORK = HERE.parent/'build/formes'

def main():
    source = (HERE/'formes.be').read_text()
    for number, line in enumerate(source.splitlines(), 1):
        if len(line)>72:
            raise ValueError(f'formes.be:{number}: source card exceeds 72 columns')
        if line and not line[0].isspace() and not line.startswith('*'):
            if len(line.split()[0])>6:
                raise ValueError(f'formes.be:{number}: label exceeds six characters')
    WORK.mkdir(parents=True, exist_ok=True)
    (WORK/'home/.besm6').mkdir(parents=True, exist_ok=True)
    search = os.environ.get('BESM6_PATH', f'{Path.home()}/.besm6:/usr/local/share/besm6')
    env = dict(os.environ, HOME=str(WORK/'home'), BESM6_PATH=f'{WORK}:{search}')
    (WORK/'1234').write_bytes(b'')
    original = WORK/'2053-0616.bin'
    original.unlink(missing_ok=True)
    subprocess.run(['besmtool','dump','2053','--start=0616','--length=1',
                    '--to-file='+str(original)], env=env, check=True,
                   stdout=subprocess.DEVNULL)
    deck = WORK/'formes.b6'
    tail = build.TAIL.replace('ЗОНГП 430001  000002','ЗОНГП 430001  000001')
    deck.write_text(build.HEADER+''.join(line+'^\n' for line in source.splitlines())+tail)
    listing = WORK/'formes.lst'
    with listing.open('w') as output:
        result = subprocess.run(['dispak','--path='+env['BESM6_PATH'],'-l',str(deck)],
                                env=env, cwd=WORK, stdin=subprocess.DEVNULL,
                                stdout=output, stderr=subprocess.STDOUT, timeout=240)
    text = listing.read_text(encoding='utf-8-sig')
    normalized = text.translate(str.maketrans('ABCEHKMOPTXY','АВСЕНКМОРТХУ'))
    errors = re.findall(r'ОШИБОК\s*=\s*([0-9]+)', normalized)
    if result.returncode or not errors or any(int(n) for n in errors):
        raise RuntimeError('BEMSH failed; see '+str(listing))
    if not re.search(r'ЗОНГП\s*=\s*430001\s+СВ[.]ЗОНА\s*=\s*430002\b', normalized):
        raise RuntimeError('ЗОНГП did not write one zone; see '+str(listing))
    image = WORK/'formes.img'
    image.unlink(missing_ok=True)
    subprocess.run(['besmtool','dump','1234','--start=01','--length=1',
                    '--to-file='+str(image)], env=env, check=True,
                   stdout=subprocess.DEVNULL)
    old,new = original.read_bytes(),image.read_bytes()
    assert len(old)==len(new)==6144, 'Expected a full 6144-byte zone'
    differences = [dict(address=f'{i//6:05o}',
                        original=f'{int.from_bytes(old[i:i+6],"big"):016o}',
                        rebuilt=f'{int.from_bytes(new[i:i+6],"big"):016o}')
                   for i in range(0,len(old),6) if old[i:i+6]!=new[i:i+6]]
    report = dict(source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                  original='2053/0616', original_sha256=hashlib.sha256(old).hexdigest(),
                  rebuilt_sha256=hashlib.sha256(new).hexdigest(), bytes=6144,words=1024,
                  identical_words=1024-len(differences),different_words=len(differences),
                  differences=differences,bemsh_errors=[int(n) for n in errors])
    (WORK/'comparison.json').write_text(json.dumps(report,indent=2)+'\n')
    if differences:
        raise RuntimeError(f'{len(differences)} differing words; see {WORK}/comparison.json')
    print('BEMSH: ЧИСЛО ОШИБОК=0000; ЗОНГП 430001 000001 completed.')
    print('1024/1024 words; 6144/6144 bytes identical to 2053/0616.')
    print('SHA-256: '+report['rebuilt_sha256'])
    print('Deck, listing, image and comparison: '+str(WORK))

if __name__=='__main__':
    main()
