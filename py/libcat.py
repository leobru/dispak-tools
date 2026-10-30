#!/usr/bin/env python3
"""List a Dubna monitor library catalog and extract its object modules.

Usage:
  libcat.py VOLUME ZONE                 list the catalog at ZONE (octal)
  libcat.py VOLUME ZONE NAME [out.obj]  extract module NAME (object words)
  libcat.py VOLUME --find NAME          find catalogs that list NAME

VOLUME is a volume number (dumped read-only with besmtool from the usual
BESM6_PATH) or a file of 6-byte words dumped from zone 0.  The catalog
format follows besm6.github.io/wiki/2248-recovery/libr1/recover.py: from
word 2, pairs (name in TEXT code, descriptor); a descriptor with bits
above 15 gives the module start (zone base + bits 40-31 - 01040, word
32 * bits 45-42) and its loaded length (bits 30-16); a small descriptor
is an additional entry of the preceding module; (0, -1) ends the catalog.
The object starts with three header words that give its size.
"""
import os
import subprocess
import sys
import tempfile

TEXT = ' .БЦДФГИ()*ЙЛЯЖ/0123456789Ь,П-+ЫЗABCDEFGHIJKLMNOPQRSTUVWXYZШЭЩЧЮ'
MASK48 = (1 << 48) - 1


def text(word):
    return ''.join(TEXT[(word >> s) & 63] for s in range(42, -1, -6)).rstrip()


def encode(name):
    name = name.ljust(8)[:8]
    w = 0
    for c in name:
        w = w << 6 | TEXT.index(c)
    return w


def load(volume):
    if os.path.isfile(volume):
        data = open(volume, 'rb').read()
    else:
        with tempfile.TemporaryDirectory() as tmp:
            out = os.path.join(tmp, 'v.bin')
            subprocess.run(['besmtool', 'dump', volume, '--start=0',
                            '--length=10000', '--to-file=' + out],
                           check=True, stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL)
            data = open(out, 'rb').read()
    return [int.from_bytes(data[i:i + 6], 'big') for i in range(0, len(data), 6)]


def object_size(a, b, c):
    return (3 + (a >> 36) + ((a >> 12) & 4095) + (a & 4095)
            + ((b >> 30) & 32767) + ((b >> 15) & 32767) + (b & 32767)
            + ((c >> 30) & 32767) + (c & 32767))


def catalog(words, base):
    """Modules of the catalog at zone base, or None if it is not one."""
    modules = []
    i = base * 1024 + 2
    while i + 1 < len(words):
        name, d = words[i], words[i + 1]
        i += 2
        if name == 0 and d == MASK48:
            return modules
        if name == 0:
            return None
        if d >> 15:
            zone = base + ((d >> 30) & 0o3777) - 0o1040
            start = zone * 1024 + ((d >> 41) & 31) * 32
            if not 0 <= start < len(words) - 3:
                return None
            modules.append(dict(name=text(name), start=start,
                                length=(d >> 15) & 32767, entries=[]))
        elif modules:
            modules[-1]['entries'].append((text(name), d))
        else:
            return None
    return None


def extract(words, module):
    a, b, c = words[module['start']:module['start'] + 3]
    size = object_size(a, b, c)
    return words[module['start']:module['start'] + size]


def main():
    args = sys.argv[1:]
    words = load(args[0])
    if args[1] == '--find':
        want = args[2]
        for z in range(len(words) // 1024):
            mods = catalog(words, z)
            if not mods:
                continue
            for m in mods:
                names = [m['name']] + [e[0] for e in m['entries']]
                if want in names:
                    obj = extract(words, m)
                    print(f'{z:04o} {m["name"]:8} {m["start"] // 1024:04o}:'
                          f'{m["start"] % 1024:04o} length {m["length"]:o} '
                          f'object {len(obj):o} words')
        return
    base = int(args[1], 8)
    mods = catalog(words, base)
    if mods is None:
        sys.exit(f'no catalog at zone {base:04o}')
    if len(args) == 2:
        for m in mods:
            extra = ' '.join(e[0] for e in m['entries'])
            print(f'{m["name"]:8} {m["start"] // 1024:04o}:{m["start"] % 1024:04o} '
                  f'{m["length"]:6o} {extra}')
        return
    m = next(m for m in mods if m['name'] == args[2])
    obj = extract(words, m)
    out = args[3] if len(args) > 3 else args[2].replace('*', '_') + '.obj'
    with open(out, 'wb') as f:
        f.write(b''.join(w.to_bytes(6, 'big') for w in obj))
    print(f'{m["name"]}: {len(obj):o} words to {out}')


if __name__ == '__main__':
    main()
