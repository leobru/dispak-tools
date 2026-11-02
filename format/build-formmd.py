#!/usr/bin/env python3
"""Assemble formmd.be, write two ЗОНГП zones and compare with 2053/0614-0615."""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess
import build

HERE = Path(__file__).resolve().parent
WORK = HERE.parent/'build/formmd'
EXPECTED = 'c4984c50f7b4467bcacc754d0dc25ec4c579ec5b3def00f07d45118e3f17218e'

def main():
    source = (HERE/'formmd.be').read_text()
    for number, line in enumerate(source.splitlines(), 1):
        if len(line)>72:
            raise ValueError(f'formmd.be:{number}: source card exceeds 72 columns')
        if line and not line[0].isspace() and not line.startswith('*'):
            if len(line.split()[0])>6:
                raise ValueError(f'formmd.be:{number}: label exceeds six characters')
    WORK.mkdir(parents=True, exist_ok=True)
    (WORK/'home/.besm6').mkdir(parents=True, exist_ok=True)
    search = os.environ.get('BESM6_PATH', f'{Path.home()}/.besm6:/usr/local/share/besm6')
    env = dict(os.environ, HOME=str(WORK/'home'), BESM6_PATH=f'{WORK}:{search}')
    (WORK/'1234').write_bytes(b'')
    original = WORK/'2053-0614-0615.bin'
    original.unlink(missing_ok=True)
    subprocess.run(['besmtool','dump','2053','--start=0614','--length=2',
                    '--to-file='+str(original)], env=env, check=True,
                   stdout=subprocess.DEVNULL)
    if hashlib.sha256(original.read_bytes()).hexdigest() != EXPECTED:
        raise RuntimeError('2053/0614-0615 differs from the recovered image')
    deck = WORK/'formmd.b6'
    tail = build.TAIL
    deck.write_text(build.HEADER+''.join(line+'^\n' for line in source.splitlines())+tail)
    listing = WORK/'formmd.lst'
    with listing.open('w') as output:
        result = subprocess.run(['dispak','--path='+env['BESM6_PATH'],'-l',str(deck)],
                                env=env, cwd=WORK, stdin=subprocess.DEVNULL,
                                stdout=output, stderr=subprocess.STDOUT, timeout=240)
    text = listing.read_text(encoding='utf-8-sig')
    normalized = text.translate(str.maketrans('ABCEHKMOPTXY','АВСЕНКМОРТХУ'))
    errors = re.findall(r'ОШИБОК\s*=\s*([0-9]+)', normalized)
    if result.returncode or not errors or any(int(n) for n in errors):
        raise RuntimeError('BEMSH failed; see '+str(listing))
    if not re.search(r'ЗОНГП\s*=\s*430001\s+СВ[.]ЗОНА\s*=\s*430003\b', normalized):
        raise RuntimeError('ЗОНГП did not write two zones; see '+str(listing))
    image = WORK/'formmd.img'
    image.unlink(missing_ok=True)
    subprocess.run(['besmtool','dump','1234','--start=01','--length=2',
                    '--to-file='+str(image)], env=env, check=True,
                   stdout=subprocess.DEVNULL)
    old,new = original.read_bytes(),image.read_bytes()
    if len(old) != 12288 or len(new) != 12288:
        raise RuntimeError('Expected two complete 6144-byte zones')
    differences = [dict(address=f'{i//6:05o}',
                        original=f'{int.from_bytes(old[i:i+6],"big"):016o}',
                        rebuilt=f'{int.from_bytes(new[i:i+6],"big"):016o}')
                   for i in range(0,len(old),6) if old[i:i+6]!=new[i:i+6]]
    report = dict(source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                  original='2053/0614-0615', original_sha256=hashlib.sha256(old).hexdigest(),
                  rebuilt_sha256=hashlib.sha256(new).hexdigest(), bytes=12288,words=2048,
                  identical_words=2048-len(differences),different_words=len(differences),
                  different_bytes=sum(a != b for a,b in zip(old,new)),
                  zones=[dict(original=f'2053/{0o614+i:04o}', bytes=6144,
                              bit_identical=old[i*6144:(i+1)*6144] ==
                                            new[i*6144:(i+1)*6144])
                         for i in range(2)],
                  differences=differences,bemsh_errors=[int(n) for n in errors])
    (WORK/'comparison.json').write_text(json.dumps(report,indent=2)+'\n')
    if differences:
        raise RuntimeError(f'{len(differences)} differing words; see {WORK}/comparison.json')
    print('BEMSH: ЧИСЛО ОШИБОК=0000; ЗОНГП 430001 000002 completed.')
    print('2048/2048 words; 12288/12288 bytes identical to 2053/0614-0615.')
    print('SHA-256: '+report['rebuilt_sha256'])
    print('Deck, listing, image and comparison: '+str(WORK))

if __name__=='__main__':
    main()
