#!/usr/bin/env python3
"""Extract PASCODER and P/BOOT from PERSO 2113/1160 and recover Madlen.

Usage: python3 runtime/pascoder/extract.py [--extract]
--extract runs LIBPUNCH with a private HOME; otherwise reuse saved objects.
Objects, punch cards and listings stay in runtime/build/pascoder, outside Git.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'runtime' for p in HERE.parents
                            if (p/'runtime/paths.py').exists())))
from paths import ROOT, BUILD
WORK = BUILD / 'pascoder'
from build import environment
from corpus import GOST, pack, read_words

TEXT = " .БЦДФГИ()*ЙЛЯЖ/0123456789Ь,П-+ЫЗABCDEFGHIJKLMNOPQRSTUVWXYZШЭЩЧЮ"
SHORT = ('ATX STX *02 XTS A+X A-X X-A AMX XTA AAX AEX ARX AVX AOX A/X A*X '
         'APX AUX ACX ANX E+X E-X ASX XTR RTE YTA ATZ ZTA E+N E-N ASN NTR '
         'ATI STI ITA ITS MTJ J+M *46 *47 *50 *51 *52 *53 *54 *55 *56 *57 '
         '*60 *61 *62 *63 *64 *65 *66 *67 *70 *71 *72 *73 *74 *75 *76 *77').split()
LONG = dict(zip(range(0o20, 0o40),
                '*20 *21 UTC WTC VTM UTM UZA U1A UJ VJM IJ STOP VZM V1M *36 VLM'.split()))
LABELS = {0: 'PASCODER', 0o25: 'WRITE', 0o37: 'REPORT', 0o41: 'BADW',
          0o42: 'BADL', 0o43: 'SMALL', 0o44: 'CHKW', 0o45: 'GETW',
          0o46: 'CHKL', 0o47: 'GETL', 0o50: 'GETSTK', 0o51: 'ONE',
          0o52: 'MASK15', 0o53: 'DIGITS', 0o54: 'OFFFMT', 0o55: 'NEXT',
          0o56: 'FIRST', 0o57: 'PAGE', 0o60: 'OVRSTK', 0o61: 'LAST',
          0o62: 'PRINFO', 0o63: 'PRFMT', 0o64: 'OKTEXT', 0o70: 'BEGNO',
          0o72: 'ENDNO', 0o73: 'TAIL', 0o75: 'ERRW', 0o102: 'ERRL', 0o110: 'ERRN'}


def text48(word):
    return ''.join(TEXT[(word >> shift) & 63] for shift in range(42, -1, -6)).rstrip(' \0')


def unpack_punch(path):
    lines = path.read_text().splitlines()
    # A blank separator follows each twelve-row card. Skip the title card.
    if len(lines) % 13:
        raise ValueError('Incomplete punch card')
    words = []
    for start in range(13, len(lines), 13):
        card = lines[start:start+12]
        for x in (4, 8, 13, 17, 22, 26, 31, 35, 40, 44, 49, 53, 58, 62, 67, 71):
            cols = [sum((row[x+i] == 'O') << bit for bit, row in enumerate(card))
                    for i in range(4)]
            words.append((cols[0] << 36) | (cols[1] << 24) | (cols[2] << 12) | cols[3])
        if card[0][3] == 'O':
            break
    return b'BESM6\0' + pack(words)


def extract(name, stem):
    env = environment(WORK)
    env['HOME'] = str(WORK / 'home')
    Path(env['HOME']).mkdir(exist_ok=True)
    deck = WORK / (stem + '.b6')
    deck.write_text('шифр 419999 зс5^\nлен 31(2113)40(2048)41(2148)42(2248)^\n'
                    f'eeb1a3\n*name PASCODER\n*perso:311160\n'
                    f'*table:libpunch({name})\n*libpunch\n*end file\n``````\nеконец\n')
    punch = WORK / (stem + '.punch')
    punch.unlink(missing_ok=True)
    result = subprocess.run(['dispak', '-l', '--punch=' + str(punch), str(deck)],
                            cwd=WORK, env=env, stdin=subprocess.DEVNULL,
                            capture_output=True, text=True, timeout=45)
    (WORK / (stem + '.lst')).write_text(result.stdout + result.stderr)
    if result.returncode or not punch.exists():
        raise RuntimeError('LIBPUNCH failed for ' + name)
    (WORK / (stem + '.obj')).write_bytes(unpack_punch(punch))


class Object:
    def __init__(self, path):
        self.raw = path.read_bytes()
        words = read_words(path)
        if self.raw[:6] != b'BESM6\0':
            raise ValueError('Expected a BESM6 object')
        at = 1
        while words[at+1] >> 45:
            at += 2
        self.name = text48(words[1])
        self.head, self.nsyms, _, self.debug, self.nlong, self.ncode, self.nbss, \
            self.nconst, self.ndata, self.nset = words[at:at+10]
        begin = at + 10
        end = begin + self.ncode + self.nconst + self.ndata + self.nset
        self.body = words[begin:end]
        self.symbols = words[end+1:end+1+self.nsyms]
        self.longs = words[end+1+self.nsyms:end+1+self.nsyms+self.nlong]

    def symbol(self, address):
        item = self.symbols[(address & 0o3777)-1]
        kind, value, ref = (item >> 15) & 0o777, item & 0o77777, item >> 24
        if kind == 0o400:
            return f'{value:o}B', value
        if kind == 0o630:
            return text48(self.longs[ref - 0o4001 - self.nsyms]), None
        raise ValueError(f'Unhandled symbol {item:016o}')

    def instruction(self, half, labels):
        reg = half >> 20
        if half & 0o2000000:
            opcode, address = (half >> 15) & 0o37, half & 0o77777
            if address >= 0o74000:
                operand, _ = self.symbol(address)
            elif address >= 0o40000:
                operand = labels[address - 0o40000]
            else:
                operand = f'{address:o}B' if address else ''
            mnemonic = LONG[opcode]
        else:
            opcode = (half >> 12) & 0o77
            address = (half & 0o7777) | (0o70000 if half & 0o1000000 else 0)
            operand = f'{address:o}B' if address else ''
            mnemonic = SHORT[opcode]
        return f'{reg if reg else ""},{mnemonic},{operand}'


COMMENTS = {
    0: ['C 000-002: M8=self, M9=descriptor. Save optional third TABLE word.'],
    0o3: ['C 003-005: reject non-octal digits in the six-digit W and two-digit L.'],
    0o6: ['C 006-012: pack W; memory page comes from the location of P/CODER.'],
    0o13: ['C 013-021: pack L; copy cell 017; derive required pages from FREE.'],
    0o22: ['C 022-024: optional third word replaces only the saved stack word.',
           'C Its five octal digits occupy TEXT character positions 3 through 7.'],
    0o25: ['C 025-030: write successive memory pages to successive disk zones.'],
    0o31: ['C 031-040: format the zone/word range, print it, end the build job.'],
    0o44: ['C 044-055: masks and constants.'],
    0o56: ['C 056-061: writable scratch words; octal offsets retained in code.'],
    0o62: ['C 062-063: E64 descriptor; M1 points at a success or error message.'],
    0o64: ['C 064-114: GOST messages and writable fields in the success message.'],
}


def gost_literal(word):
    return ''.join(GOST[b] if b < len(GOST) else f"'{b:03o}'"
                   for b in word.to_bytes(6, 'big'))


def recover(obj):
    is_writer = obj.name == 'PASCODER'
    labels = LABELS if is_writer else {0: 'P/BOOT', 2: 'MORE', 6: 'NEXT'}
    dependencies = ['MACROBSS', 'P/BOOT', 'P/CODER', 'PROGRAM'] if is_writer else ['P/CODER', 'PROGRAM']
    lines = ['C Recovered from PERSO 2113/1160; labels and comments are new.',
             f' {obj.name}:,NAME,']
    lines += [f' {name}:,SUBP,' for name in dependencies]
    code_end = 0o44 if is_writer else 6
    for at, word in enumerate(obj.body):
        if is_writer:
            lines += COMMENTS.get(at, [])
        label = labels.get(at, '')
        prefix = ' ' + (label + ':' if label and at else '')
        if at < code_end:
            lines.append(prefix + obj.instruction(word >> 24, labels))
            lines.append(' ' + obj.instruction(word & 0xffffff, labels))
        elif is_writer and 0o64 <= at:
            lines.append(prefix + (',BSS,1' if not word else ',GOST,6H' + gost_literal(word)))
        elif not word:
            lines.append(prefix + ',BSS,1')
        elif is_writer and at in (0o45, 0o50, 0o52):
            # A LOG word can itself contain a relocatable symbol reference.
            _, value = obj.symbol(word & 0o77777)
            # The loader relocates two instruction halves even for LOG data.
            # At 052 the reference is a SHORT address: retain opcode bits
            # 070000, yielding 077777 rather than the symbol value 07777.
            mask = 0o77777 if word & 0o2000000 else 0o7777
            word = (word & ~mask) | value
            lines.append(prefix + f',LOG,{word:016o}')
        elif is_writer and at == 0o53:
            lines.append(prefix + ',GOST,6H777777')
        else:
            lines.append(prefix + f',LOG,{word:016o}')
    if obj.nbss:
        lines += ['C Fill the module to 01000 words; the next module starts on a page.',
                  f' PAD:,BSS,{obj.nbss:o}B']
    lines.append(' ,END,')
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--extract', action='store_true')
    args = parser.parse_args()
    WORK.mkdir(parents=True, exist_ok=True)
    modules = []
    for name, stem in [('PASCODER', 'pascoder'), ('P/BOOT', 'boot')]:
        if args.extract or not (WORK / (stem + '.obj')).exists():
            extract(name, stem)
        obj = Object(WORK / (stem + '.obj'))
        if obj.name != name:
            raise ValueError('Wrong object module: ' + obj.name)
        (HERE / (stem + '.madlen')).write_text(recover(obj))
        modules.append(dict(name=name, source_library='2113/1160',
                            object_sha256=hashlib.sha256(obj.raw).hexdigest(),
                            code_words=obj.ncode, constant_words=obj.nconst,
                            bss_words=obj.nbss,
                            total_words=obj.ncode + obj.nconst + obj.nbss,
                            artifact=str((WORK / (stem + '.obj')).relative_to(ROOT))))
        print(f'{name}: {obj.ncode} code-section words, {obj.nconst} constants, {obj.nbss} BSS')
    (HERE / 'modules.json').write_text(json.dumps(dict(modules=modules), indent=2) + '\n')


if __name__ == '__main__':
    main()
