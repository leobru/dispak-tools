#!/usr/bin/env python3
"""Extract and inventory NEWPASC memory images, including overlays, from 4001.

Usage: python3 runtime/corpus.py [--volume /path/to/4001] [--output runtime]
The volume is opened read-only. Missing root binaries (test.bin, тестац.bin,
mark3.bin, pak.bin) are first dumped from volumes 4001 and 2113 with besmtool. Addresses, zones and lengths in JSON are octal
strings; word counts are decimal. Binary outputs contain six big-endian bytes
per word, with core address 02000 at file offset zero.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess

ROOT = Path(__file__).resolve().parent.parent
BASE = 0o2000
ZONE_WORDS = 1024
PHYSICAL_ZONE_BYTES = 1032 * 8
WORD_MASK = (1 << 48) - 1
GOST = ('0123456789+-/,. ' '⏨↑()×=;[]*‘’≠<>:'
        'АБВГДЕЖЗИЙКЛМНОП' 'РСТУФХЦЧШЩЫЬЭЮЯD'
        'FGIJLNQRSUVWZ‾⩽⩾' '∨∧⊃¬÷≡%◇|―_!"Ъ°′')
SLUGS = {
    0o1: 'monitr', 0o11: 'unicop', 0o16: 'tar', 0o23: 'kanal',
    0o30: 'proz', 0o34: 'more', 0o37: 'kermit', 0o47: 'mtd',
    0o51: 'print', 0o57: 'testats', 0o61: 'test', 0o63: 'fprint',
    0o66: 'box', 0o70: 'tartar', 0o75: 'recod', 0o101: 'mtcopy',
    0o106: 'copy', 0o111: 'tabcod', 0o112: 'link', 0o132: 'acc3',
    0o172: 'mt', 0o175: 'link1', 0o215: 'acc2', 0o255: 'blink1',
    0o275: 'blink', 0o315: 'comp', 0o325: 'newker',
}
# Root binaries: volume, first zone (octal), number of zones.
ROOT_IMAGES = {
    'mark3.bin': ('2113', '01243', 3), 'pak.bin': ('2113', '01246', 4),
    'test.bin': ('4001', '0061', 2), 'тестац.bin': ('4001', '0057', 2),
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def read_words(path):
    data = Path(path).read_bytes()
    if len(data) % 6:
        raise ValueError(f'{path}: incomplete 48-bit word')
    return [int.from_bytes(data[i:i + 6], 'big')
            for i in range(0, len(data), 6)]


def pack(words):
    return b''.join(w.to_bytes(6, 'big') for w in words)


def decode_text(word):
    return ''.join(GOST[b] if b < len(GOST) else f'\\{b:03o}'
                   for b in word.to_bytes(6, 'big'))


def find_volume():
    search = os.environ.get('BESM6_PATH',
                            f'{Path.home()}/.besm6:/usr/local/share/besm6')
    for directory in search.split(':'):
        path = Path(directory) / '4001'
        if path.is_file():
            return path
    raise FileNotFoundError('volume 4001 is not on BESM6_PATH; use --volume')


def volume_words(path):
    data = path.read_bytes()
    if data[:4] == b'DISK' or len(data) % PHYSICAL_ZONE_BYTES:
        raise ValueError('expected a complete physical DISPAK disk image')
    zones = len(data) // PHYSICAL_ZONE_BYTES - 4
    if zones <= 0:
        raise ValueError('volume has no logical zones')
    words = []
    for zone in range(4, zones + 4):
        start = zone * PHYSICAL_ZONE_BYTES + 64
        words.extend(x[0] & WORD_MASK for x in struct.iter_unpack(
            '<Q', data[start:start + ZONE_WORDS * 8]))
    return data, words


def catalog(words):
    """4001 SYSLIB: header, then NAME/DESCRIPTOR pairs, zero-name terminator.

    Descriptor bits 1..10 hold the start, 11..16 the allocated zone count.
    Use the encoded length, not the next entry: there are real gaps.
    """
    result = []
    for i in range(1, ZONE_WORDS - 1, 2):
        if not words[i]:
            break
        name = decode_text(words[i]).strip()
        desc = words[i + 1]
        start, length = desc & 0o1777, (desc >> 10) & 0o77
        if not length or (start + length) * ZONE_WORDS > len(words):
            raise ValueError(f'invalid SYSLIB descriptor at {i + 1:04o}')
        result.append(dict(name=name, start=f'{start:04o}',
                           zones=f'{length:04o}', descriptor=f'{desc:016o}'))
    if not result:
        raise ValueError('empty or unrecognized SYSLIB catalog')
    return result


def loader_at(words, pos=0):
    a = words[pos:pos + 32]
    if len(a) < 12:
        return None
    if (a[0] == 0o0230201006400000 and
            a[2:5] == [0o0013200500002006, 0o0070200602200000,
                       0o0010200603002001]):
        family, transfer, count = 'pascoder', a[1] & 0o77777, a[8]
    elif (a[:2] == [0o1240200712300002, 0o1647777702200000] and
          a[3:6] == [0o0013000010000000, 0o1657777710700000,
                     0o1010000003002002]):
        family, transfer, count = 'alternate', (a[2] >> 24) & 0o77777, a[9]
    else:
        return None
    entries = []
    for i, w in enumerate(a[9:], 9):
        left, right = w >> 24, w & 0xffffff
        if (left & 0o77700000 == 0o42400000 and
                right & 0o77700000 == 0o03000000 and
                left & 0o77777 >= BASE and right & 0o77777 >= BASE):
            entries.append(dict(address=f'{BASE + i:05o}',
                                constants=f'{left & 0o77777:05o}',
                                start=f'{right & 0o77777:05o}'))
    if not entries:
        return None
    return dict(loader=family, load_address=f'{BASE:05o}',
                loader_transfer=f'{transfer:05o}',
                loader_count_word=f'{count:o}', entries=entries)


def root_record(path):
    words = read_words(path)
    info = loader_at(words)
    if not info:
        raise ValueError(f'{path}: no supported Pascal image header')
    return dict(id='root-' + path.stem, path=str(path.relative_to(ROOT)),
                source='workspace', sha256=sha(pack(words)), words=len(words),
                **info)


def fetch_roots():
    for name, (disk, zone, length) in ROOT_IMAGES.items():
        path = ROOT / name
        if path.exists():
            continue
        # besmtool does not truncate an existing file, so dump to a new one.
        part = path.with_name(name + '.part')
        part.unlink(missing_ok=True)
        subprocess.run(['besmtool', 'dump', disk, f'--start={zone}',
                        f'--length={length}', f'--to-file={part}'],
                       check=True, stdout=subprocess.DEVNULL)
        part.rename(path)


def extract(volume, output):
    raw, words = volume_words(volume)
    original_hash = sha(raw)
    entries = catalog(words)
    images = []
    target = output / 'images' / '4001'
    target.mkdir(parents=True, exist_ok=True)
    heads = [(i, loader_at(words, i)) for i, w in enumerate(words)
             if w in (0o0230201006400000, 0o1240200712300002)]
    heads = [(i, info) for i, info in heads if info]
    for i, info in heads:
        zone, offset = divmod(i, ZONE_WORDS)
        owners = [e for e in entries
                  if int(e['start'], 8) * ZONE_WORDS <= i <
                  (int(e['start'], 8) + int(e['zones'], 8)) * ZONE_WORDS]
        owner = owners[0] if owners else None
        direct = owner and offset == 0 and int(owner['start'], 8) == zone
        if direct:
            end = (zone + int(owner['zones'], 8)) * ZONE_WORDS
            slug, name = SLUGS.get(zone, f'zone-{zone:04o}'), owner['name']
            placement = 'catalog'
        else:
            # Keep the orphan or embedded image separate, stopping at the next
            # catalog file, enclosing allocation end, or loader header.
            bounds = [len(words)]
            bounds += [int(e['start'], 8) * ZONE_WORDS for e in entries
                       if int(e['start'], 8) * ZONE_WORDS > i]
            bounds += [j for j, _ in heads if j > i]
            if owner:
                bounds.append((int(owner['start'], 8) +
                               int(owner['zones'], 8)) * ZONE_WORDS)
            end = min(bounds)
            slug = 'monitr-pascal' if zone == 0o2 else f'orphan-{zone:04o}'
            name = owner['name'] + ' (embedded)' if owner else 'uncatalogued'
            placement = 'embedded' if owner else 'orphan'
        ident = f'{zone:04o}-{slug}'
        if offset:
            ident += f'-{offset:04o}'
        path = target / (ident + '.bin')
        binary = pack(words[i:end])
        if path.exists() and path.read_bytes() != binary:
            raise FileExistsError(f'refusing to overwrite different extract: {path}')
        path.write_bytes(binary)
        record = dict(id='4001-' + ident,
                      path=str(path.relative_to(output)), source='4001',
                      name=name, placement=placement, zone=f'{zone:04o}',
                      zone_word=f'{offset:04o}', words=(end-i),
                      end_zone_exclusive=f'{(end + 1023)//1024:04o}',
                      sha256=sha(binary), **info)
        if owner:
            record['catalog'] = owner
        images.append(record)
    fetch_roots()
    roots = [root_record(ROOT / n) for n in sorted(ROOT_IMAGES)]
    for record in images:
        record['duplicates'] = [r['path'] for r in roots
                                if r['sha256'] == record['sha256']]
    if sha(volume.read_bytes()) != original_hash:
        raise RuntimeError('source volume changed during extraction')
    manifest = dict(format_version=1, address_notation='octal',
                    volume=dict(number='4001', sha256=original_hash,
                                logical_zones=len(words)//1024,
                                storage='physical-le64-4-service-zones'),
                    catalog=entries, images=images, roots=roots)
    (output / 'corpus.json').write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    print(f'Extracted {len(images)} images; '
          f'{len({r["sha256"] for r in images + roots})} distinct images '
          'including root binaries')
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--volume', type=Path)
    parser.add_argument('--output', type=Path, default=ROOT / 'runtime')
    args = parser.parse_args()
    extract(args.volume or find_volume(), args.output.resolve())


if __name__ == '__main__':
    main()
