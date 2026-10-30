#!/usr/bin/env python3
"""Compare the two surviving MT revisions; run after build.py extraction.

Usage: python3 programs/mt/variants.py
Checks every operand in the common code with libmatch.match_at. Only a
consistent relocation of address operands is accepted; numeric operands and
indexed offsets must agree. No writable disk image is read or hashed here.
"""
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import ROOT, IMAGES
from corpus import BASE, read_words, sha
from libmatch import match_at, operand

REFERENCE = IMAGES/'4001/0172-mt.bin'
VARIANT = IMAGES/'4001/0104-orphan-0104.bin'
KOI7 = (''.join(chr(i) for i in range(96)) +
        'ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЫЗШЭЩЧ' + chr(127))


def commands(words, pool, lo, hi):
    """Recover the actual ALFA argument and minimum length at CЛEKC calls."""
    result = []
    for address in range(lo, hi):
        reg, op, target, long = operand(words[address-BASE] >> 24)
        if not (long and op == 0o31 and target == 0o2206):
            continue
        args = words[address-1-BASE]
        offsets = []
        for shift in (24, 0):
            reg, op, offset, long = operand(args >> shift & 0xffffff)
            if long or reg != 8 or op != 0o3:
                raise ValueError(f'unexpected CЛEKC arguments at {address:05o}')
            offsets.append(offset)
        name, minimum = (words[pool+offset-BASE] for offset in offsets)
        name = ''.join(KOI7[b & 127] for b in name.to_bytes(6, 'big')).rstrip()
        result.append(dict(command=name, minimum_length=minimum & 0xffffff))
    return result


def compare_variants():
    reference, variant = read_words(REFERENCE), read_words(VARIANT)
    # The procedure boundaries are supplied by their surviving PMD records.
    parser = [(0o2013, 'GETCMDLI'), (0o2052, 'ПPOГOH'),
              (0o2072, 'ПOДГOH'), (0o2110, 'ПPOБ'),
              (0o2120, 'COГЛACEH'), (0o2141, 'BЛEKC'),
              (0o2206, 'CЛEKC'), (0o2261, 'DIGIT'),
              (0o2316, 'DECODE'), (0o2337, 'SCANNUM'),
              (0o2403, 'READNUM'), (0o2417, 'READAGRE'),
              (0o2433, 'INITFILES')]
    regions = [(name, lo, hi, lo) for (lo, name), (hi, _) in
               zip(parser, parser[1:])]
    regions += [('INITFILES', 0o2433, 0o2445, 0o2433),
                ('LIB', 0o4203, 0o4622, 0o4055),
                ('TAPEIO', 0o4622, 0o4654, 0o4474),
                ('DBPASC', 0o5367, 0o5422, 0o5241),
                ('DBCORE', 0o5422, 0o5562, 0o5274)]
    matches = []
    for name, lo, hi, target in regions:
        changes = match_at(reference, variant, lo, hi, target-BASE, BASE)
        if changes is None:
            raise ValueError('MT variants differ in common region '+name)
        matches.append(dict(name=name, reference_range=[f'{lo:05o}', f'{hi-1:05o}'],
                            variant_range=[f'{target:05o}', f'{target+hi-lo-1:05o}'],
                            words=hi-lo, address_fixups=len(changes),
                            equal_after_relocation=True))
    modern = commands(reference, 0o2753, 0o2503, 0o2705)
    earlier = commands(variant, 0o2643, 0o2467, 0o2575)
    if len(modern) != 20 or len(earlier) != 10 or modern[:10] != earlier:
        raise ValueError('unexpected MT command tables')
    return dict(reference=str(REFERENCE.relative_to(ROOT)),
                reference_sha256=sha(REFERENCE.read_bytes()),
                reference_zones=['0172', '0173', '0174'],
                variant=str(VARIANT.relative_to(ROOT)),
                variant_sha256=sha(VARIANT.read_bytes()),
                variant_zones=['0104', '0105'], variant_cataloged=False,
                reference_code_words=0o2753-0o2012,
                variant_code_words=0o2643-0o2012,
                common_regions=matches, reference_commands=modern,
                variant_commands=earlier,
                device_selection={
                    '0172': 'Parses optional -T and an ALFA device name; default MT',
                    '0104': 'Calls LIB with the literal MT before reading commands'},
                chronology='0172 has additional features; neither image supplies a build date')


if __name__ == '__main__':
    report = compare_variants()
    (HERE/'variants.json').write_text(json.dumps(report, indent=2)+'\n')
    print('MT variants: 282 common parser/file-init words and 420 service words '
          'match after relocation; 20 versus 10 commands')
