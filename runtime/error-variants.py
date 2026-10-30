#!/usr/bin/env python3
"""Compare ERROR equivalents beyond the eight complete COMP-revision copies.

Usage: python3 runtime/error-variants.py
Writes file-access/ERROR-VARIANTS.json. Searches all inputs inventoried by
file-access.py using instruction structure, table layout, and message bytes.
No application is executed; chronological ordering is an inference.
"""

from collections import defaultdict
import json
from pathlib import Path
import re
import sys

sys.path.insert(0, str(next(p/'py' for p in Path(__file__).resolve().parents
                            if (p/'py/paths.py').exists())))
from paths import ROOT, IMAGES
from corpus import BASE, find_volume, pack, read_words, sha, volume_words
from libmatch import mask, operand

HERE = Path(__file__).resolve().parent
DEST = HERE/'file-access'
REFERENCE = IMAGES/'4001/0315-comp.bin'
KOI7 = ''.join(chr(i) for i in range(96)) + 'ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЫЗШЭЩЧ' + chr(127)
LOOKALIKES = str.maketrans('ABCEHKMOPTXY', 'АВСЕНКМОРТХУ')


def message(words, position, limit):
    data = bytearray()
    for i in range(position, limit):
        data.extend(words[i].to_bytes(6, 'big'))
        if 10 in data[-6:]:
            text = bytes(data).split(b'\n', 1)[0]
            return dict(words=i-position+1, hex=data.hex(),
                        text=''.join(KOI7[b] for b in text).translate(LOOKALIKES))
    raise ValueError('message has no LF terminator')


def main():
    inventory = json.loads((DEST/'relocations.json').read_text())
    ref = read_words(REFERENCE)
    signature = [mask(w) for w in ref[0o7036-BASE:0o7054-BASE]]
    found, no_match, text_hits, table_hits = [], [], {}, {}
    complete_data = {}
    for source in inventory['scanned']:
        words = read_words(ROOT/source['path'])
        if sha(pack(words)) != source['sha256']:
            raise ValueError(f'input changed: {source["path"]}')
        raw = pack(words)
        fingerprints = [mask(w) for w in words]
        hits = []
        # Independent searches prevent the entry fingerprint being the sole
        # basis for claiming that no other copy was found.
        for name, lo, hi in [('default', 0o7235, 0o7241),
                             ('no_file', 0o7141, 0o7143),
                             ('damaged_catalog', 0o7162, 0o7165)]:
            needle = pack(ref[lo-BASE:hi-BASE])
            start = 0
            while (start := raw.find(needle, start)) >= 0:
                text_hits.setdefault(source['path'], []).append(
                    dict(pattern=name, file_address=f'{BASE+start//6:05o}', byte=start % 6))
                start += len(needle)
        for i in range(len(words)-4):
            block = words[i:i+5]
            if ([w >> 24 for w in block] == list(range(5))
                    and all(0 < (w & 0o77777) < 0o70000 and not w & 0xff8000 for w in block)):
                table_hits.setdefault(source['path'], []).append(f'{BASE+i:05o}')
        for i in range(len(words)-14+1):
            reg, op, load, long = operand(words[i] >> 24)
            if (reg, op, long) != (8, 0o24, True) or words[i] & 0xffffff != 0o00410014:
                continue
            score = sum(a == b for a, b in zip(fingerprints[i:i+14], signature))
            if score < 9:
                continue
            count = 1-((words[i+1] & 0o77777)-0o100000)
            last = operand(words[i+7] >> 24)[2]
            first = last-count+1
            if not 1 <= count <= 100 or first-load != 14:
                continue
            default = operand(words[i+5] & 0xffffff)[2]
            item = dict(path=source['path'], sha256=source['sha256'],
                        file_entry=f'{BASE+i:05o}', load_entry=f'{load:05o}',
                        matching_code_words=score, expected_code_words=14,
                        expected_table_entries=count, table_start=f'{first:05o}',
                        table_end=f'{last:05o}', default_start=f'{default:05o}')
            if score != 14:
                different = [k for k, (a, b) in enumerate(zip(fingerprints[i:i+14], signature)) if a != b]
                item.update(complete=False,
                            missing_code_words=[f'{load+k:05o}' for k in different],
                            missing_code_is_zero=all(words[i+k] == 0 for k in different),
                            table_is_zero=all(w == 0 for w in words[i+14:i+14+count]))
                hits.append(item)
                continue
            table = words[i+14:i+14+count]
            if any(w & 0xff8000 for w in table):
                raise ValueError('table pointer has unexpected upper bits')
            default_position = i+default-load
            default_message = message(words, default_position, min(default_position+20, len(words)))
            end = default_position+default_message['words']
            if not i+14+count <= end <= len(words):
                raise ValueError('ERROR region extends beyond extract')
            messages = []
            for word in table:
                pointer = word & 0o77777
                position = i+pointer-load
                if not i+14+count <= position < default_position:
                    raise ValueError('message pointer is outside text pool')
                messages.append(dict(status=word >> 24, status_octal=f'{word >> 24:o}',
                                     address=f'{pointer:05o}',
                                     **message(words, position, default_position)))
            normalized = words[i:end].copy()
            # Only absolute code references and table pointers are normalized;
            # relative offsets, loop bounds, message bytes, and masks are kept.
            for offset in range(14):
                for shift in (24, 0):
                    half = (words[i+offset] >> shift) & 0xffffff
                    _, opcode, address, is_long = operand(half)
                    if not is_long:
                        continue
                    value = None
                    if load <= address < load+end-i:
                        value = address-load
                    elif opcode == 0o22 and offset == 10 and shift == 0:
                        mask_pos = i+address-load
                        if not 0 <= mask_pos < len(words) or words[mask_pos] != 0o377:
                            raise ValueError('external byte-mask dependency differs')
                        value = 0  # external byte mask, not an internal offset
                    if value is not None:
                        normalized[offset] = (normalized[offset] & ~(0o77777 << shift)) | (value << shift)
            for offset, word in enumerate(table, 14):
                normalized[offset] = (word & ~0o77777) | ((word & 0o77777)-load)
            item.update(complete=True, words=end-i, end_exclusive=f'{load+end-i:05o}',
                        normalized_sha256=sha(pack(normalized)),
                        messages=messages, default_message=default_message,
                        ascii_date_strings=[m.group().decode('ascii') for m in re.finditer(
                            rb'\d{1,2}[./-]\d{1,2}[./-]\d{2,4}', pack(words[i:end]))])
            complete_data[source['path']] = (words, i, load, end)
            hits.append(item)
        if not hits:
            no_match.append(source['path'])
        found.extend(hits)
    groups = defaultdict(list)
    for item in found:
        if item['complete']:
            groups[item['normalized_sha256']].append(item)
    reference = next(x for x in found if x['path'] == str(REFERENCE.relative_to(ROOT)))
    comparisons = []
    for digest, copies in groups.items():
        sample = copies[0]
        statuses = {m['status']: m for m in sample['messages']}
        missing = []
        words, pos, load, end = complete_data[sample['path']]
        pool = pack(words[pos+14+sample['expected_table_entries']:end])
        for m in reference['messages']:
            if m['status'] in statuses:
                if m['hex'] != statuses[m['status']]['hex']:
                    raise ValueError(f'common status text differs: {m["status"]}')
            else:
                offset = pool.find(bytes.fromhex(m['hex']))
                missing.append(dict(status=m['status'], status_octal=m['status_octal'], text=m['text'],
                    text_present_without_entry=offset >= 0,
                    text_address=(f'{load+14+sample["expected_table_entries"]+offset//6:05o}'
                                  if offset >= 0 else None)))
        comparisons.append(dict(normalized_sha256=digest,
                                copies=[dict(path=x['path'], load_entry=x['load_entry']) for x in copies],
                                table_entries=sample['expected_table_entries'], words=sample['words'],
                                missing_comp_statuses=missing))
    # Confirm that MORE's missing zone is already zero in the source volume.
    volume = find_volume()
    disk_data, disk_words = volume_words(volume)
    zero_zone = dict(volume=str(volume), logical_zone='0035',
                     sha256=sha(disk_data),
                     all_payload_words_zero=not any(disk_words[0o35*1024:0o36*1024]))
    result = dict(address_notation='octal', counts_notation='decimal',
                  scanned=inventory['scanned'], found=found, complete_groups=comparisons,
                  no_equivalent_found=no_match, message_pattern_hits=text_hits,
                  table_pattern_hits=table_hits, more_source_zone=zero_zone,
                  chronology=dict(likely_later_family='COMP: 25 table entries',
                      basis='Added statuses 14, 15, 16 decimal; common messages are byte-identical. '
                            'The 22-entry family already contains status-14 text without a table entry.',
                      absolute_date_established=False))
    (DEST/'ERROR-VARIANTS.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
    for group in comparisons:
        print(f'{group["table_entries"]} entries, {group["words"]} words: {len(group["copies"])} complete copies')
    for item in found:
        if not item['complete']:
            print(f'{item["path"]}: incomplete at {item["load_entry"]}, expects {item["expected_table_entries"]} entries')
    print(f'{len(no_match)} inputs: no equivalent found; MORE source zone 0035 zero: {zero_zone["all_payload_words_zero"]}')


if __name__ == '__main__':
    main()
