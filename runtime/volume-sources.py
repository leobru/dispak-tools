#!/usr/bin/env python3
"""Extract the file-access include and COPY source from volume 4001.

Usage: python3 runtime/volume-sources.py [--volume /path/to/4001]
Reads logical zone 0005 and zones 0006-0007 without modifying the volume.
Outputs UTF-8 decks and sources.json under runtime/sources/4001. Space runs are
expanded, right padding is stripped, and KOI-7 control characters are retained.
The first *END FILE terminates each deck; trailing records are inventoried.
"""

import argparse
import json
from pathlib import Path

import sys
sys.path.insert(0, str(next(p/'py' for p in Path(__file__).resolve().parents
                            if (p/'py/paths.py').exists())))
from paths import RUNTIME
from corpus import find_volume, pack, sha, volume_words

KOI7 = ''.join(chr(i) for i in range(96)) + 'ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЫЗШЭЩЧ' + chr(127)


def decode(words, first, last):
    records = []
    line = []
    start = first * 1024
    for address in range(first * 1024, last * 1024):
        word = words[address].to_bytes(6, 'big')
        for index, value in enumerate(word):
            if value == 0:
                if line or any(words[address+1:last*1024]):
                    raise ValueError('unexpected zero in source records')
                return records
            if value == 10:
                if word[index+1:].strip(b' \n'):
                    raise ValueError('non-padding bytes after source line')
                records.append(dict(start=start, end=address+1,
                                    value=''.join(line).rstrip(' ')))
                start, line = address+1, []
                break
            if value > 128:
                line.extend(' ' * (value & 127))
            elif value == 128:
                raise ValueError('unsupported source byte 0200')
            else:
                line.append(KOI7[value])
    if line:
        raise ValueError('incomplete source line at end of selected zones')
    return records


def location(address):
    zone, word = divmod(address, 1024)
    return f'{zone:04o}.{word:04o}'


def extract(volume):
    raw, words = volume_words(volume)
    digest = sha(raw)
    output = RUNTIME/'sources/4001'
    output.mkdir(parents=True, exist_ok=True)
    files = []
    for name,first,last in [('dbf.inc.b6',5,6),('copy.b6',6,8)]:
        records = decode(words, first, last)
        end = next(i for i,r in enumerate(records,1)
                   if r['value'].strip().upper() == '*END FILE')
        deck, tail = records[:end], records[end:]
        text = '\n'.join(r['value'] for r in deck) + '\n'
        path = output/name
        if path.exists() and path.read_text() != text:
            raise FileExistsError(f'refusing to overwrite a different source: {path}')
        path.write_text(text)
        duplicate = None
        if tail:
            values = [r['value'] for r in tail]
            for i in range(len(deck)-len(tail)+1):
                if [r['value'] for r in deck[i:i+len(tail)]] == values:
                    duplicate = [i+1, i+len(tail)]
                    break
        controls = [dict(line=i,byte=f'{ord(c):03o}')
                    for i,r in enumerate(deck,1) for c in r['value'] if ord(c)<32]
        files.append(dict(path=name,zone_range=[f'{first:04o}',f'{last-1:04o}'],
                          packed_zone_sha256=sha(pack(words[first*1024:last*1024])),
                          utf8_sha256=sha(text.encode()),lines=len(deck),
                          start=location(deck[0]['start']),
                          end_exclusive=location(deck[-1]['end']),
                          line_locations=[location(r['start']) for r in deck],
                          controls=controls,trailing_records=len(tail),
                          trailing_duplicate_source_lines=duplicate))
        print(f'{name}: {len(deck)} lines, end {location(deck[-1]["end"])}; '
              f'{len(tail)} trailing records')
    if sha(volume.read_bytes()) != digest:
        raise RuntimeError('source volume changed during extraction')
    manifest=dict(volume='4001',sha256=digest,encoding='COSY space runs with KOI-7 characters',
                  notation='octal zone.word locations; decimal source line numbers',files=files)
    (output/'sources.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--volume',type=Path)
    args=parser.parse_args()
    extract(args.volume or find_volume())
