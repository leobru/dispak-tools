#!/usr/bin/env python3
"""Decode PRINT's tables: python3 runtime/print/analyze.py [image.bin].

This is a static model of 02502-02520 and 02564-02674, followed by
the TTIO output table used at 10122. It does not run the historical image.
Addresses and byte codes in the report are octal; counts are decimal.
"""
import json
from pathlib import Path
import sys

sys.path.insert(0, str(next(p/'runtime' for p in Path(__file__).resolve().parents
                            if (p/'runtime/paths.py').exists())))
from paths import ROOT, IMAGES
from corpus import GOST, pack, read_words

HERE = Path(__file__).resolve().parent
IMAGE = IMAGES / '4001/0051-print.bin'


def main():
    image = Path(sys.argv[1]) if len(sys.argv) > 1 else IMAGE
    words = read_words(image)

    def word(address):
        return words[address - 0o2000]

    def data(start, end):
        return pack(words[start - 0o2000:end - 0o2000])

    alternative = data(0o4217, 0o4245)[:128]
    special = {63: 25, 64: 22, 92: 29, 94: 31, 96: 39,
               123: 14, 124: 63, 125: 15, 126: 94, 223: 39, 255: 39}

    def convert(c):
        if c in special:
            return special[c]
        if 96 < c < 128:
            return c - 32
        if 191 < c < 224:
            return c - 96
        if 224 <= c < 255:
            return c - 128
        return c

    def gost(c):
        # Four reversed bytes and two space bytes per table word.
        return (word(0o10130 + c // 4) >> (16 + 8 * (c % 4))) & 255

    mappings = []
    for use_a in (False, True):
        for use_s in (False, True):
            for original in range(32, 256):
                c = alternative[original - 128] if use_a and original > 127 else original
                if use_s:
                    c = {159: 94, 190: 95}.get(c, c)
                out = convert(c)
                code = gost(out)
                repeat = 65 <= c <= 90 or 224 <= c <= 254
                mappings.append({
                    'A': use_a, 'S': use_s, 'input': f'{original:03o}',
                    'after_options': f'{c:03o}', 'output_byte': f'{out:03o}',
                    'gost': f'{code:03o}',
                    'glyph': GOST[code] if code < len(GOST) else None,
                    'additional_passes': repeat,
                })

    report = {
        'image': str(IMAGE.relative_to(ROOT)),
        'method': 'static decoding; no emulator execution',
        'usage': data(0o2737, 0o2753)[:68].decode('koi8-r'),
        'application_code': {'start': '02012', 'end_inclusive': '02714',
                             'words': 0o2715 - 0o2012},
        'global_base': '03033',
        'alternative_table': [f'{c:03o}' for c in alternative],
    }
    (HERE / 'analysis.json').write_text(
        json.dumps(report, ensure_ascii=False, indent=2)[:-2]
        + ',\n  "mappings": [\n'
        + ',\n'.join('    ' + json.dumps(row, ensure_ascii=False)
                     for row in mappings)
        + '\n  ]\n}\n')
    print(f"Decoded {len(alternative)} alternative-encoding bytes and "
          f"{len(mappings)} character mappings into runtime/print/analysis.json")


if __name__ == '__main__':
    main()
