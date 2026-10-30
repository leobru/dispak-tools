#!/usr/bin/env python3
"""Assemble starter.be with BEMSH, run ЗОНГП and compare 4001 zone 0001.

Usage: python3 programs/monitr/build-starter.py
Generated deck, listing, private volume 1234 and zone extracts are kept in
runtime/build/monitr-starter. The starter itself is not executed.
"""
from pathlib import Path
import os
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'runtime' for p in HERE.parents
                            if (p/'runtime/paths.py').exists())))
from paths import BUILD
WORK = BUILD/'monitr-starter'
from corpus import find_volume, pack, read_words, volume_words


def main():
    source = (HERE/'starter.be').read_text()
    for number, line in enumerate(source.splitlines(), 1):
        if len(line)>72:
            raise ValueError(f'starter.be:{number}: source card exceeds 72 columns')
        if line and not line[0].isspace() and not line.startswith('*'):
            if len(line.split()[0])>6:
                raise ValueError(f'starter.be:{number}: label exceeds six characters')
    WORK.mkdir(parents=True, exist_ok=True)
    volume = find_volume()
    original_volume, disk = volume_words(volume)
    env = os.environ.copy()
    search = env.get('BESM6_PATH', f'{Path.home()}/.besm6:/usr/local/share/besm6')
    env['BESM6_PATH'] = str(WORK)+':'+search
    (WORK/'1234').write_bytes(b'')
    cards = '''шифр 419999^
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
    cards += ''.join(line+'^\n' for line in source.splitlines())
    cards += '''КВЧ$$$^
ТРН$$$^
0-0^
ЧТКОМП420070^
НАЗ   000001^
ЗОНГП 430001  000001^
КНЦ$$$^
_$ЕКОНЕЦ
'''
    deck = WORK/'starter.b6'
    deck.write_text(cards)
    listing = WORK/'starter.lst'
    with listing.open('w') as output:
        result = subprocess.run(['dispak', '--path='+env['BESM6_PATH'], '-l',
                                 str(deck)], env=env, stdin=subprocess.DEVNULL,
                                stdout=output, stderr=subprocess.STDOUT,
                                timeout=240)
    text = listing.read_text(encoding='utf-8-sig')
    fold = str.maketrans('ABCEHKMOPTXY', 'АВСЕНКМОРТХУ')
    normalized = text.translate(fold)
    summaries = re.findall(r'ОШИБОК\s*=\s*([0-9]+)', normalized)
    if result.returncode or not summaries or any(int(n) for n in summaries):
        raise RuntimeError('BEMSH assembly failed; see '+str(listing))
    if not re.search(r'ЗОНГП\s*=\s*430001\b', normalized):
        raise RuntimeError('ЗОНГП did not report writing zone 430001; see '+str(listing))
    for number, name in [('1234','starter.img'), ('4001','zone1.bin')]:
        subprocess.run(['besmtool','dump',number,'--start=01','--length=1',
                        '--to-file='+str(WORK/name)], env=env, check=True,
                       stdout=subprocess.DEVNULL)
    original = (WORK/'zone1.bin').read_bytes()
    if original != pack(disk[1024:2048]):
        raise ValueError('reference extract differs from original volume 4001')
    if volume.read_bytes() != original_volume:
        raise ValueError('original volume 4001 changed')
    rebuilt = (WORK/'starter.img').read_bytes()
    if len(rebuilt) != 6144 or len(original) != 6144:
        raise ValueError('expected a complete 1024-word zone')
    old, new = read_words(WORK/'zone1.bin'), read_words(WORK/'starter.img')
    differences = [(a, x, y) for a, (x, y) in enumerate(zip(old,new)) if x!=y]
    (WORK/'comparison.txt').write_text(
        f'4001/0001 -> 1234/0001: {1024-len(differences)}/1024 words identical\n'+
        ''.join(f'{a:05o}: {x:016o} -> {y:016o}\n' for a,x,y in differences))
    if differences:
        for a,x,y in differences[:20]:
            print(f'{a:05o}: {x:016o} -> {y:016o}')
        raise ValueError(f'{len(differences)} differing words; see {WORK}/comparison.txt')
    print('BEMSH: no errors; ЗОНГП 430001 000001 completed.')
    print('1024/1024 words match volume 4001 zone 0001; original unchanged.')
    print('Deck and listing: '+str(WORK))


if __name__ == '__main__':
    main()
