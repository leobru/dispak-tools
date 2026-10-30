#!/usr/bin/env python3
"""Run the restored АСС2 on ЭЛФ.ТЕКСТ and compare ЭЛФ.МОД with the volume's.

Usage: python3 programs/acc2/elf.py [--probe]   (after zone.py)

On a private copy of volume 4001 (under build/acc-family/elf)
the file АСС2 (zone 0215) is replaced by all-restored.bin of zone.py
and the monitor runs `$АСС2` of ЭЛФ.ТЕКСТ into ЭЛФ.МОД (01070), as the
.ЭЛФ deck of ппуск.txt (re-dvs jobs/elf-4001.b6 without the linking).
The new ЭЛФ.МОД is compared with the volume's, word by word, ignoring
the user code (word 8) and the date (word 11) of the header and the low
16 bits of the words (070707 on the volume; a fresh АСС3 run leaves 0
there too). Prints the differences that remain.

With --probe, for each handler of the case of p17204 that starts in
the lost area (013755-016066) one more run is made with an
`Э74` (end of task) at the handler's entry: when ЭЛФ.МОД is then not
written (its header keeps the volume's user code), the handler was
called. Prints each entry with the name of the
handler in ov1.pas (its АСС3 address) and whether it was called.
"""
from pathlib import Path
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import BUILD
from corpus import pack, read_words

FAMILY = BUILD/'acc-family'
WORK = FAMILY/'elf'
VOLUME = Path('/usr/local/share/besm6/4001')
FILE, MOD = 0o215, 0o1070          # АСС2 and ЭЛФ.МОД on the volume
TABLE, SIZE = 0o17007, 45         # the case table of p17204
NAME = 0o14337 - 0o13755           # АСС3 address (name) - АСС2 address
LO, HI = 0o13755, 0o16067          # handlers that lie in the lost zone
JOB = '''ШИФР 419900^ОЗУ 32^ТРА 10^ВРЕ 700^АЦП 128^ВХО 7^
ДИС 30(4001-ЗП)^
ЕВ7 К 00 070 0010 С 0010 0000 0030 0001
ЕВ1А5
$БИБ МОДУЛИ 301000
$БИБ ТЕКСТЫ 300400
$АСС2
МОД      ЭЛФ
ИСХ      ЭЛФ
ПОЛЯ     АДР,НОМ,ТЕКСТ,ПР
ПОЗ      14,7,20
НСТА
ЛИСТ     -1
КОНЕЦ
$КНЦ
``````
ЕКОНЕЦ
'''


def besmtool(*args, path=None):
    subprocess.run(['besmtool', *args], check=True, stdout=subprocess.DEVNULL,
                   env={'BESM6_PATH': str(path or WORK/'disks'),
                        'PATH': '/usr/local/bin:/usr/bin:/bin'})


def run(program):
    """ЭЛФ.МОД after `$АСС2` with the file АСС2 = program (words)."""
    (WORK/'disks').mkdir(parents=True, exist_ok=True)
    disk = WORK/'disks/4001'
    shutil.copyfile(VOLUME, disk)
    disk.chmod(0o644)
    (WORK/'acc2.bin').write_bytes(pack(program))
    besmtool('write', '4001', f'--start=0{FILE:o}', f'--length={len(program)//1024}',
             '--from-file=' + str(WORK/'acc2.bin'))
    (WORK/'job.b6').write_text(JOB)
    with (WORK/'out.lst').open('w') as out:
        subprocess.run(['dispak', f'--path={WORK/"disks"}:{Path.home()}/.besm6:'
                        f'{VOLUME.parent}', str(WORK/'job.b6')],
                       stdout=out, stderr=subprocess.STDOUT,
                       stdin=subprocess.DEVNULL, timeout=600)
    besmtool('dump', '4001', f'--start=0{MOD:o}', '--length=4',
             '--to-file=' + str(WORK/'elf.bin'))
    return read_words(WORK/'elf.bin')


def main():
    WORK.mkdir(parents=True, exist_ok=True)
    restored = read_words(FAMILY/'acc2/all-restored.bin')
    besmtool('dump', '4001', f'--start=0{MOD:o}', '--length=4',
             '--to-file=' + str(WORK/'elf-orig.bin'), path=VOLUME.parent)
    orig = read_words(WORK/'elf-orig.bin')
    new = run(restored)
    if new[8] == orig[8]:
        sys.exit('ЭЛФ.МОД was not written (see out.lst)')
    diff = [k for k in range(len(orig)) if k not in (8, 11)
            and orig[k] >> 16 != new[k] >> 16]
    print(f'ЭЛФ.МОД: {len(diff)} words differ above the low 16 bits '
          '(header words 8 and 11 ignored)')
    for k in diff[:20]:
        print(f'  {k:05o} {orig[k]:016o} {new[k]:016o}')
    if '--probe' not in sys.argv:
        return
    ov1 = 4*1024
    entries = sorted({restored[ov1 + TABLE + k - 0o4000] & 0o77777
                      for k in range(SIZE)} & set(range(LO, HI)))
    for t in entries:
        trapped = list(restored)
        k = ov1 + t - 0o4000
        trapped[k] = 0o0740000 << 24 | trapped[k] & 0o77777777
        called = run(trapped)[8] == orig[8]
        print(f'{t:05o} p{t + NAME:05o} {"called" if called else "-"}')


if __name__ == '__main__':
    main()
