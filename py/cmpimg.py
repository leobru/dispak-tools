#!/usr/bin/env python3
# Compare the user part of two memory images word by word.
#
# Usage: cmpimg.py ref.bin img [lo [hi [base]]]   (addresses in octal)
#   Compares words lo..hi-1 (default 2011..first library routine of ref,
#   see -h) of images loaded at base (default 2000).  Instructions whose
#   address fields differ only by a consistent relocation (the same ref
#   address always maps to the same img address, addresses inside lo..hi
#   map to themselves, and addresses below base are plain numbers that
#   must be equal) are treated as equal, so a different
#   library layout does not hide differences in the compiled program.
#   Prints every mismatching word and the number of mismatches.

import sys

def words(fn):
    d = open(fn, 'rb').read()
    return [int.from_bytes(d[i:i+6], 'big') for i in range(0, len(d), 6)]

def halves(w):
    return (w >> 24) & 0o77777777, w & 0o77777777

def split(h):
    # (opcode/register part, address); long format has a 15-bit address
    if h & 0o2000000:
        return h & 0o77700000, h & 0o77777
    return h & 0o77770000, h & 0o7777

a = sys.argv[1:]
ref, img = words(a[0]), words(a[1])
lo = int(a[2], 8) if len(a) > 2 else 0o2011
hi = int(a[3], 8) if len(a) > 3 else lo + len(ref)
base = int(a[4], 8) if len(a) > 4 else 0o2000
hi = min(hi, base + len(ref), base + len(img))
reloc = {}
bad = 0
for addr in range(lo, hi):
    r, i = ref[addr - base], img[addr - base]
    if r == i:
        continue
    ok = True
    for hr, hi_ in zip(halves(r), halves(i)):
        (orr, ar), (oi, ai) = split(hr), split(hi_)
        if orr != oi:
            ok = False
        elif ar != ai:
            # only long-format addresses are relocatable here
            if (not hr & 0o2000000 or lo <= ar < hi or lo <= ai < hi
                    or ar < base or ai < base):
                ok = False
            elif reloc.setdefault(ar, ai) != ai:
                ok = False
    if not ok:
        bad += 1
        print('%05o %016o %016o' % (addr, r, i))
print('%d mismatches in %05o..%05o' % (bad, lo, hi))
