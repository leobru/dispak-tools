#!/usr/bin/env python3
"""Rebuild the lost zone 0225 of АСС2 (4001/0215) from ov1.pas.

Usage: python3 programs/acc2/zone.py   (after ovtry.py ov1 ov1.pas)

Overlay 1 of АСС2 lost its zone +4 of the overlay (file zone 0225,
addresses 014000-015777): it reads as zeros. ov1.pas, compiled by
ovtry.py, gives the same code as the surviving words of the overlay and
the same constant pool, so the zone is taken from the build: the halves
of the built code are aligned with the original (as insdiff.py does,
long addresses >= 02000 hidden), and every long address of the built
zone is translated to the original's by the pairs of addresses that the
aligned surviving code gives (calls of the runtime, jumps into the user
code); an external xNNNNN of the source (an empty stub in the build)
is the routine of АСС3 at NNNNN, found in АСС2 by aligning the two
runtimes (after the pools). The user code of the build is at the
original's addresses, so the original word at a is the built word at a.

Checks: the surviving words 013755-013777 and 016000-016066 next to the
zone equal the built ones after translation, every address in the zone
has a translation, no translation is ambiguous, and every global the
zone uses (`n(М1)`) is used by the surviving code too, so that its
place is confirmed (АСС2 has the globals of АСС3 moved by 5 words). Writes
build/acc-family/acc2/zone0225.bin (the 1024 words),
ov1-restored.bin and all-restored.bin (the overlay and the whole file
with the zone put back), and prints a summary. The volume is not touched.
"""
from collections import Counter, defaultdict
from pathlib import Path
import difflib
import re
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import BUILD
import ovtry
from corpus import pack, read_words

OUT = BUILD/'acc-family/acc2'
LO, HI = 0o14000, 0o16000        # the lost zone
START = 0o17347                  # start address of the original overlay


def halves(w, base, lo, hi):
    out = []
    for a in range(lo, hi):
        x = w[a - base]
        for h in (x >> 24, x & 0o77777777):
            long = h & 0o2000000 and (h & 0o77777) >= 0o2000
            out.append((a, h, (h >> 15, 'A') if long else h))
    return out


def globals_used(w, lo, hi):
    """The offsets n >= 050 of `n(М1)` operands (short and long) in lo..hi-1."""
    out = set()
    for a in range(lo, hi):
        for h in (w[a - 0o4000] >> 24, w[a - 0o4000] & 0o77777777):
            if h >> 20 != 1 or not h & 0o2000000 and h >> 12 & 0o100:
                continue
            off = h & (0o77777 if h & 0o2000000 else 0o7777)
            if 0o50 <= off < 0o2000:
                out.add(off)
    return out


def runtime_map():
    """{АСС3 address: АСС2 address} of the words of the runtimes (after the
    pools) whose left halves align."""
    def code(name, lo):
        w = read_words(BUILD/f'acc-family/{name}/ov1.bin')
        hi = len(w) + 0o4000
        while not w[hi - 1 - 0o4000]:
            hi -= 1
        return halves(w, 0o4000, lo, hi)
    a3, a2 = code('acc3', 0o20537), code('acc2', 0o20160)
    sm = difflib.SequenceMatcher(None, [x[2] for x in a3], [x[2] for x in a2],
                                 autojunk=False)
    rt = {}
    for i, j, n in sm.get_matching_blocks():
        for k in range(n):
            if (i + k) % 2 == 0 and (j + k) % 2 == 0:
                rt[a3[i+k][0]] = a2[j+k][0]
    return rt


def main():
    orig = read_words(ovtry.IMAGE['ov1'])
    built = read_words(ovtry.WORK/'ov1.img')
    o = halves(orig, 0o4000, 0o4014, START)
    b = halves(built, 0o2000, 0o4014, START)
    sm = difflib.SequenceMatcher(None, [x[2] for x in o], [x[2] for x in b],
                                 autojunk=False)
    seen = defaultdict(Counter)
    for i, j, n in sm.get_matching_blocks():
        for k in range(n):
            if b[j+k][2] != b[j+k][1]:       # a long address
                seen[b[j+k][1] & 0o77777][o[i+k][1] & 0o77777] += 1
    table = {t: v.most_common(1)[0][0] for t, v in seen.items()}
    # The user code is in place.
    code = {t: t for t in range(0o4014, START)}
    # The externals xNNNNN (empty stubs in the build) are the routines of
    # АСС3 at NNNNN, which АСС2 has at the address aligned with it.
    rt = runtime_map()
    text = (ovtry.WORK/'ov1.lst').read_text(encoding='utf-8-sig',
                                                errors='replace')
    for m in re.finditer(r'\bX([0-7]{5})\s+([0-7]{5})\b', text):
        if int(m[1], 8) in rt:
            code[int(m[2], 8)] = rt[int(m[1], 8)]
    for t, u in code.items():
        if t in seen and set(seen[t]) != {u}:
            sys.exit(f'code target {t:05o}: seen {dict(seen[t])}, expected {u:05o}')

    def translate(h, where):
        if not (h & 0o2000000 and (h & 0o77777) >= 0o2000):
            return h
        t = h & 0o77777
        if t >= 0o2000 + len(built):
            return h                     # a constant such as -1
        if t in code:
            u = code[t]
        elif t in table:
            if len(seen[t]) > 1:
                sys.exit(f'{where:05o}: ambiguous target {t:05o}: {dict(seen[t])}')
            u = table[t]
        else:
            sys.exit(f'{where:05o}: no translation for {t:05o}')
        return h & ~0o77777 | u

    zone = []
    for a in range(LO, HI):
        x = built[a - 0o2000]
        zone.append(translate(x >> 24, a) << 24 | translate(x & 0o77777777, a))
    for a in list(range(0o13755, LO)) + list(range(HI, 0o16067)):
        x = built[a - 0o2000]
        y = translate(x >> 24, a) << 24 | translate(x & 0o77777777, a)
        if y != orig[a - 0o4000]:
            sys.exit(f'{a:05o}: surviving word {orig[a - 0o4000]:016o} '
                     f'!= rebuilt {y:016o}')
    assert not any(orig[LO - 0o4000:HI - 0o4000])
    ov1 = orig[:LO - 0o4000] + zone + orig[HI - 0o4000:]
    inside = globals_used(ov1, LO, HI)
    outside = globals_used(ov1, 0o4014, LO) | globals_used(ov1, HI, START)
    if inside - outside:
        sys.exit('globals used only in the zone: ' +
                 ' '.join(f'{g:04o}' for g in sorted(inside - outside)))
    whole = read_words(OUT/'all.bin')
    at = (0o4 + (LO - 0o4000) // 1024) * 1024
    whole = whole[:at] + zone + whole[at + 1024:]
    (OUT/'zone0225.bin').write_bytes(pack(zone))
    (OUT/'ov1-restored.bin').write_bytes(pack(ov1))
    (OUT/'all-restored.bin').write_bytes(pack(whole))
    used = Counter(table.get(h & 0o77777, h & 0o77777) for x in zone
                   for h in (x >> 24, x & 0o77777777)
                   if h & 0o2000000 and (h & 0o77777) >= 0o2000)
    print(f'zone 0225: {sum(1 for x in zone if x)} non-zero words of 1024, '
          f'{sum(used.values())} long addresses, {len(used)} targets; '
          f'surviving neighbours match')


if __name__ == '__main__':
    main()
