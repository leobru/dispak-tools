#!/usr/bin/env python3
"""Turn a range of a BESM-6 memory image into Madlen source text.

Usage: img2madlen.py image.bin BASE LO HI CODE [@ADDR,...] [NAME:ADDR ...]

  image.bin  6-byte words loaded from address BASE (octal)
  LO HI      the module, LO inclusive, HI exclusive (octal)
  CODE       code ranges, e.g. 3341-3425,3471-3616 (octal, end exclusive);
             everything else in LO..HI is data
  @ADDR,...  data words that hold addresses (exchange words, address
             tables); they are written as two instruction halves
  NAME:ADDR  names for addresses (octal); the first one at LO is the
             module name (,NAME,), others on code are entry points
             (,ENTRY,) when written with a '!' (USED!:3517); the module
             name is not a label, so LO gets its own

Addresses inside LO..HI become labels (L<addr> in code, D<addr> in data,
or label+offset inside a run of zero words, which become ,BSS,); others
stay absolute.  Data words are ,LOG, octal.  A UTC 0 filler after an
unconditional jump in a left half is left to the assembler; any other
filler is written as ,UTC,.  The output is a draft to be renamed and
commented by hand.
"""
import sys

F1 = ['ATX', 'STX', 'MOD', 'XTS', 'A+X', 'A-X', 'X-A', 'AMX',
      'XTA', 'AAX', 'AEX', 'ARX', 'AVX', 'AOX', 'A/X', 'A*X',
      'APX', 'AUX', 'ACX', 'ANX', 'E+X', 'E-X', 'ASX', 'XTR',
      'RTE', 'YTA', '*32', 'EXT', 'E+N', 'E-N', 'ASN', 'NTR',
      'ATI', 'STI', 'ITA', 'ITS', 'MTJ', 'J+M', '*46', '*47']
F2 = {0o20: '*20', 0o21: '*21', 0o22: 'UTC', 0o23: 'WTC', 0o24: 'VTM',
      0o25: 'UTM', 0o26: 'UZA', 0o27: 'U1A', 0o30: 'UJ', 0o31: 'VJM',
      0o32: 'IJ', 0o33: 'STOP', 0o34: 'VZM', 0o35: 'V1M', 0o36: '*36',
      0o37: 'VLM'}
FILLER = 0o02200000


def decode(h):
    """(reg, mnemonic, address, long format) of a 24-bit half."""
    reg = h >> 20
    if h >> 19 & 1:
        return reg, F2[h >> 15 & 0o37], h & 0o77777, True
    op = h >> 12 & 0o77
    addr = (h & 0o7777) + (0o70000 if h >> 18 & 1 else 0)
    name = F1[op] if op < 0o50 else '*%o' % op
    return reg, name, addr, False


def main():
    args = sys.argv[1:]
    data = open(args[0], 'rb').read()
    base, lo, hi = (int(a, 8) for a in args[1:4])
    code = []
    for r in args[4].split(','):
        a, b = r.split('-')
        code.append((int(a, 8), int(b, 8)))
    names, entries, pairs, modname = {}, set(), set(), None
    for n in args[5:]:
        if n.startswith('@'):
            pairs.update(int(x, 8) for x in n[1:].split(','))
            continue
        name, addr = n.split(':')
        if name.endswith('!'):
            name = name[:-1]
            entries.add(int(addr, 8))
        if int(addr, 8) == lo and not modname:
            modname = name
            continue
        names[int(addr, 8)] = name

    def word(a):
        i = a - base
        return int.from_bytes(data[6 * i:6 * i + 6], 'big')

    def is_code(a):
        return any(x <= a < y for x, y in code)

    # Runs of zero data words become BSS blocks.
    bss = {}
    a = lo
    while a < hi:
        if not is_code(a) and word(a) == 0:
            b = a
            while b < hi and not is_code(b) and word(b) == 0:
                b += 1
            bss[a] = b - a
            a = b
        else:
            a += 1

    def bss_of(x):
        for s, n in bss.items():
            if s <= x < s + n:
                return s
        return None

    # Collect the referenced addresses.
    refs = set()
    for a in range(lo, hi):
        w = word(a)
        if is_code(a) or a in pairs:
            for h in (w >> 24, w & 0o77777777):
                _, _, addr, _ = decode(h)
                if lo <= addr < hi:
                    s = bss_of(addr)
                    refs.add(addr if s is None else s)

    def label(x):
        if x in names:
            return names[x]
        return ('L%o' if is_code(x) else 'D%o') % x

    def operand(addr):
        if addr == 0:
            return ''
        if lo <= addr < hi:
            s = bss_of(addr)
            if s is not None and s != addr:
                return '%s+%oB' % (label(s), addr - s)
            return label(addr)
        return '%oB' % addr

    def half(h):
        reg, name, addr, _ = decode(h)
        r = str(reg) if reg else ''
        return '%s,%s,%s' % (r, name, operand(addr))

    out = []
    for a in range(lo, hi):
        lab = ''
        if a in refs or a in names:
            lab = label(a)
        if a == lo:
            out.append(' %s:,NAME,' % modname)
        if a in entries:
            out.append(' %s:,ENTRY,' % label(a))
            lab = ''
        w = word(a)
        if a in bss:
            out.append(' %s:,BSS,%d' % (lab, bss[a]) if lab else ' ,BSS,%d' % bss[a])
            continue
        if bss_of(a) is not None:
            continue
        if not is_code(a) and a not in pairs:
            out.append(' %s:,LOG,%016o' % (lab, w) if lab else ' ,LOG,%016o' % w)
            continue
        left, right = w >> 24, w & 0o77777777
        lines = [half(left)]
        _, lname, _, _ = decode(left)
        if a in pairs:
            lines.append(half(right))
        elif right == FILLER and lname in ('UJ', 'IJ', 'STOP'):
            pass
        else:
            lines.append(half(right))
        if lab:
            lines[0] = lab + ':' + lines[0]
        out.extend(' ' + x for x in lines)
    out.append(' ,END,')
    print('\n'.join(out))


if __name__ == '__main__':
    main()
