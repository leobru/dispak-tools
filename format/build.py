#!/usr/bin/env python3
"""Assemble format.be, write two zones with ЗОНГП and compare format.bin."""
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
WORK = ROOT / 'build/format'
HEADER = '''шифр 419999^
трак 64^
лент 30(2048-6200)^
лент 42(2099)^
лент 43(1234-ЗП)^
ацп 40^
росп 0^
врем 240^
лист 0-37^
вход 4000^
е
в 4000
к 00 010 4003
к 15 24 04000
к 00 066 0001 00 000 0100
с 3000 67
в 14000
а1
ВВД$$$^
'''
TAIL = '''КВЧ$$$^
ТРН$$$^
0-0^
ЧТКОМП420070^
НАЗ   000001^
ЗОНГП 430001  000002^
КНЦ$$$^
_$ЕКОНЕЦ
'''

def main():
    source = (HERE/'format.be').read_text()
    for number, line in enumerate(source.splitlines(), 1):
        if len(line) > 72:
            raise ValueError(f'format.be:{number}: source card exceeds 72 columns')
        if line and not line[0].isspace() and not line.startswith('*'):
            if len(line.split()[0]) > 6:
                raise ValueError(f'format.be:{number}: label exceeds six characters')
    WORK.mkdir(parents=True, exist_ok=True)
    private_home = WORK/'home'
    (private_home/'.besm6').mkdir(parents=True, exist_ok=True)
    search = os.environ.get('BESM6_PATH', f'{Path.home()}/.besm6:/usr/local/share/besm6')
    env = dict(os.environ, HOME=str(private_home), BESM6_PATH=f'{WORK}:{search}')
    (WORK/'1234').write_bytes(b'')
    deck = WORK/'format.b6'
    deck.write_text(HEADER+''.join(line+'^\n' for line in source.splitlines())+TAIL)
    listing = WORK/'format.lst'
    with listing.open('w') as output:
        result = subprocess.run(['dispak', '--path='+env['BESM6_PATH'], '-l', str(deck)],
                                env=env, stdin=subprocess.DEVNULL, stdout=output,
                                stderr=subprocess.STDOUT, timeout=240, cwd=WORK)
    text = listing.read_text(encoding='utf-8-sig')
    normalized = text.translate(str.maketrans('ABCEHKMOPTXY', 'АВСЕНКМОРТХУ'))
    errors = re.findall(r'ОШИБОК\s*=\s*([0-9]+)', normalized)
    if result.returncode or not errors or any(int(n) for n in errors):
        raise RuntimeError('BEMSH failed; see '+str(listing))
    if not re.search(r'ЗОНГП\s*=\s*430001\s+СВ[.]ЗОНА\s*=\s*430003\b', normalized):
        raise RuntimeError('ЗОНГП did not report writing zone 430001; see '+str(listing))
    target = WORK/'format.img'
    target.unlink(missing_ok=True)
    subprocess.run(['besmtool', 'dump', '1234', '--start=01', '--length=2',
                    '--to-file='+str(target)], env=env, check=True,
                   stdout=subprocess.DEVNULL, cwd=WORK)
    original, rebuilt = (HERE/'format.bin').read_bytes(), target.read_bytes()
    if len(original) != 12288 or len(rebuilt) != 12288:
        raise RuntimeError('Expected two complete 6144-byte zones')
    differences = [f'{i//6:05o}: {original[i:i+6].hex()} -> {rebuilt[i:i+6].hex()}'
                   for i in range(0, len(original), 6) if original[i:i+6] != rebuilt[i:i+6]]
    report = dict(source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                  original_sha256=hashlib.sha256(original).hexdigest(),
                  rebuilt_sha256=hashlib.sha256(rebuilt).hexdigest(),
                  bytes=len(rebuilt), words=2048, identical_words=2048-len(differences),
                  different_words=len(differences),
                  different_bytes=sum(a != b for a, b in zip(original, rebuilt)),
                  zones=[dict(offset=f'{zone*1024:05o}', bytes=6144,
                              bit_identical=original[zone*6144:(zone+1)*6144] ==
                                            rebuilt[zone*6144:(zone+1)*6144])
                         for zone in range(2)],
                  zones_written='430001-430002',
                  bemsh_errors=[int(n) for n in errors], differences=differences)
    (WORK/'comparison.json').write_text(json.dumps(report, indent=2)+'\n')
    if differences:
        raise RuntimeError(f'{len(differences)} differing words; see {WORK}/comparison.json')
    print('BEMSH: ЧИСЛО ОШИБОК=0000; ЗОНГП 430001 000002 completed.')
    print('2048/2048 words; 12288/12288 bytes identical to format/format.bin.')
    print('SHA-256: '+report['rebuilt_sha256'])
    print('Deck, listing, image and comparison: '+str(WORK))

if __name__ == '__main__':
    main()
