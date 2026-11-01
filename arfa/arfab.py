#!/usr/bin/env python3
"""Disassemble the batch ARFA object module (2113/1723-1725) with names.

Usage: arfab.py b1723.bin > arfab.mad
  b1723.bin: besmtool dump 2113 --start=01723 --length=3 --to-file=b1723.bin
  (make arfab.mad does both)

The zones hold a Dubna Monitor System object module ARFA: the main part
of the terminal ARFA (arfa.be, zone 1707) built as a subroutine, without
the terminal module.  The script

* decodes the commands as the loader would (address fields 04000-07777
  of short and 074000-077777 of long instructions refer to the symbol
  table, 040000-073777 of long ones are local offsets);
* aligns the decoded words with arfa.bin by instruction skeletons
  (address fields masked out) and checks that every aligned word is the
  same up to the shift of the addresses it refers to;
* runs dtran -F dms with the code entries and texts of arfa.sym moved to
  the module's offsets, and renames dtran's *NNNNB labels to the
  arfa.sym names (upper case) or LNNNN.

The comparison and the texts of the module go to the head of the
output as comments.
"""
import difflib
import os
import re
import subprocess
import sys
import tempfile

here = os.path.dirname(os.path.abspath(__file__))

# Labels of the part that the terminal ARFA does not have.
BATCH = {0o1: 'PRTIW', 0o452: 'BEGIN', 0o453: 'SAVLP', 0o457: 'PROMPT',
         0o500: 'TNOCMD', 0o1053: 'SAY', 0o1465: 'FINISH', 0o1467: 'RSTLP'}
BATCH_TEXT = [0o420, 0o425, 0o426, 0o500, 0o501, 0o502]
# Their counterparts in arfa.bin, for the address check.
PAIRS = {0o3: 0o21, 0o41: 0o55, 0o436: 0o452, 0o440: 0o457, 0o464: 0o500,
         0o1040: 0o1053, 0o1452: 0o1465}


GOST = {}
for _l in open(os.path.join(here, '..', 'tools', 'gost10859.h'), encoding='utf-8'):
    _m = re.match(r'#define\s+GOST_(\w+)\s+(0[0-7]+)\s*(?:/\*\s*(.*?)\s*\*/)?', _l)
    if _m:
        _n, _c, _ch = _m.groups()
        GOST.setdefault(int(_c, 8), (_ch or ('_' if _n.startswith('SPACE') else '.'))[0])


def gost_word(w):
    return ''.join('_' if c == 0o17 else GOST.get(c, '.')
                   for c in w.to_bytes(6, 'big'))


def words(path):
    b = open(path, 'rb').read()
    return [int.from_bytes(b[6 * i:6 * i + 6], 'big') for i in range(len(b) // 6)]


def decode(m):
    """Memory image of a packed-header DMS module, loaded at 0."""
    head_len, sym_len = m[0] & 0o7777, (m[0] >> 12) & 0o7777
    set_len, data_len = m[1] & 0o77777, (m[1] >> 15) & 0o77777
    cmd_len, const_len = m[2] & 0o77777, (m[2] >> 30) & 0o77777
    table = 3 + cmd_len + const_len + data_len + set_len
    val = {}
    for i in range(head_len + sym_len):
        w = m[table + i]
        if w >> 15 in (0o400, 0o410):       # absolute value, local offset
            val[i] = w & 0o77777

    def half(h):
        if h & 0o2000000:
            a = h & 0o77777
            if a >= 0o74000:
                return (h & ~0o77777) | val.get(a & 0o3777, 0)
            if a >= 0o40000:
                return (h & ~0o77777) | (a - 0o40000)
            return h
        a = h & 0o7777
        if a >= 0o4000:
            v = val.get(a & 0o3777, 0)
            if v >= 0o70000:
                return (h & ~0o7777) | 0o1000000 | (v - 0o70000)
            return (h & ~0o7777) | v
        return h
    img = [(half(w >> 24) << 24) | half(w & 0xffffff)
           for w in m[3:3 + cmd_len]]
    return img + m[3 + cmd_len:3 + cmd_len + const_len], cmd_len


def skel(w):
    def half(h):
        return h & (0o77700000 if h & 0o2000000 else 0o77770000)
    return half(w >> 24), half(w & 0xffffff)


def addr(h):
    if h & 0o2000000:
        return h & 0o77777
    return (h & 0o7777) | (0o70000 if h & 0o1000000 else 0)


def main():
    obj, cmd_len = decode(words(sys.argv[1]))
    img = words(os.path.join(here, 'arfa.bin'))[:0o1540]
    sm = difflib.SequenceMatcher(None, [skel(w) for w in img],
                                 [skel(w) for w in obj],
                                 autojunk=False)
    amap, diffs = {}, []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == 'equal':
            for k in range(i2 - i1):
                amap[i1 + k] = j1 + k
        else:
            diffs.append('%-7s 1707 %04o-%04o  1723 %04o-%04o'
                         % (tag, i1, i2 - 1, j1, j2 - 1))
    known = dict(amap)
    known.update(PAIRS)
    shifted, other = 0, []
    for i, j in sorted(amap.items()):
        if img[i] == obj[j]:
            continue
        ok = True
        for s in (24, 0):
            ha, ho = (img[i] >> s) & 0xffffff, (obj[j] >> s) & 0xffffff
            if ha != ho and known.get(addr(ha), -1) != addr(ho):
                ok = False
        if ok:
            shifted += 1
        else:
            other.append('%04o/%04o' % (i, j))
    report = ['Aligned with arfa.bin (1707): %d words, %d of them differ'
              % (len(amap), shifted), 'only by shifted addresses; others'
              ' (1707/1723): ' + ' '.join(other), 'Unaligned blocks:'] + diffs

    names, code, text = dict(BATCH), set(), set(BATCH_TEXT)
    base = None
    for line in open(os.path.join(here, 'arfa.sym'), encoding='utf-8'):
        f = line.split()
        if len(f) < 3:
            continue
        lo, _, hi = f[0].partition('-')
        lo = int(lo, 8)
        for a in range(lo, int(hi, 8) + 1 if hi else lo + 1):
            if a not in amap:
                continue
            if f[1] == 'G':
                text.add(amap[a])
            if f[2] != '-' and not hi:
                names.setdefault(amap[a], f[2].upper())
                if f[1] == 'C':
                    code.add(amap[a])
    code |= {a for a in BATCH if a >= 0o452}
    with tempfile.NamedTemporaryFile('w', suffix='.cmd', delete=False) as t:
        t.write('code:' + ','.join('%o' % c for c in sorted(code)) + '\n')
        t.write('gost:' + ','.join('%o' % c for c in sorted(text)) + '\n')
    out = subprocess.run(['dtran', '-F', 'dms', '-D', t.name, sys.argv[1]],
                         capture_output=True, text=True).stdout
    os.unlink(t.name)

    def sub(m):
        a = int(m.group(1), 8)
        return names.get(a, 'L%04o' % a)
    lines = out.split('\n')
    head = ['', 'Made by arfab.py from 2113/1723-1725.'] + report
    head += ['', 'Texts (offset, GOST):']
    for a in sorted(text):
        head.append('%04o %s' % (a, gost_word(obj[a])))
    lines[1:1] = ['C ' + h if h else 'C' for h in head]
    sys.stdout.write(re.sub(r'\*([0-7]{4})B', sub, '\n'.join(lines)))


if __name__ == '__main__':
    main()
