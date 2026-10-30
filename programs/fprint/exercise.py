#!/usr/bin/env python3
"""Exercise original and rebuilt FPRINT with real disk reads and printer output.

Usage: python3 programs/fprint/exercise.py
Run build.py first. All disks, input queues and printer artifacts are private.
"""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'runtime' for p in HERE.parents
                            if (p/'runtime/paths.py').exists())))
from paths import ROOT, BUILD, IMAGES
from corpus import BASE, GOST, pack, read_words
from build import environment

ZONE = 6144


def iso(text):
    return int.from_bytes(text.encode('ascii').ljust(6, b' '), 'big')


def gost(text):
    return int.from_bytes(bytes(GOST.index(c) for c in text.ljust(6)), 'big')


def sheet(left=(), right=None):
    """Expected native printer rows, with the second column starting at 63.

    EOF in the left column leaves its 128-column blank tail intact. The
    historical printer wraps there before processing the line-feed marker,
    adding blank rows (the final pending blank is suppressed at end-of-buffer).
    """
    rows = [(left[i] if i < len(left) else '').ljust(63) +
            (right[i] if right is not None and i < len(right) else '')
            for i in range(69)]
    return rows if right is not None else [r for row in rows for r in (row, '')][:-1]


def cases():
    numbered = [f'{i:03d}' + str(i % 10) * 57 for i in range(1, 151)]
    return [
        dict(name='usage', command='', payload=b'\0', message='USAGE: FPRINT',
             reads=0, prints=0, status=None),
        dict(name='missing-file', command='999', payload=b'\0',
             message='HET ФAЙЛA', reads=0, prints=0, status=0o10),
        dict(name='empty-file', payload=b'\0', pages=[sheet()], reads=1),
        dict(name='nul-terminator', payload=b'123\0' + b'999\n',
             pages=[sheet(['123'])], reads=1),
        dict(name='eot-terminator', payload=b'456\4' + b'999\n',
             pages=[sheet(['456'])], reads=1),
        dict(name='tabs-cr', payload=b'1\t2\r\n\t3\n\0',
             pages=[sheet(['1       2', '        3'])], reads=1),
        dict(name='formfeed-columns', payload=b'111\n222\f333\n444\0',
             pages=[sheet(['111', '222'], ['333', '444'])], reads=1),
        dict(name='wrap-at-63', payload=b'1' * 63 + b'2' * 64 + b'\0',
             pages=[sheet(['1' * 63, '2' * 63, '2'])], reads=1),
        dict(name='two-sheets-two-zones',
             payload=('\n'.join(numbered) + '\n').encode() + b'\0',
             pages=[sheet(numbered[:69], numbered[69:138]), sheet(numbered[138:])],
             reads=2),
        # The text decoder represents overprinting as separate passes. Keep
        # their positions and backslash marker; raw streams are compared too.
        dict(name='backspace-overstrike', payload=b'12\b3\n\0',
             nonblank=['13\\', ' 2'], reads=1),
        dict(name='letter-conversion', payload=b'ABCabc\n\0',
             nonblank=['ABCABC', 'ABC'], reads=1),
    ]


def write_fixture(directory, payload, env):
    """One real Monitor catalog zone and a TXT file, starting at zone 2.

    Catalog names are GOST. The second half of the same zone holds parallel
    type/attribute entries (name at 1, descriptor at 2, attributes at 01002).
    TXT's type code is 010. Both recovered MKNAME and OPENF execute unchanged.
    """
    zones = max(1, (len(payload) + ZONE - 1) // ZONE)
    catalog = [0] * 1024
    catalog[0] = 0o7760000000000000 | (zones + 2)
    catalog[1] = gost('123')
    catalog[2] = (zones << 10) | 2
    catalog[0o1002] = 0o10 << 36
    data = pack(catalog) + bytes(ZONE) + payload.ljust(zones * ZONE, b'\0')
    fixture = directory / 'fixture.bin'
    fixture.write_bytes(data)
    (directory / '1234').write_bytes(b'')
    command(['besmtool', 'write', '1234', '--start=0', f'--length={zones + 2}',
             '--from-file=' + str(fixture)], directory, env)
    readback = directory / 'fixture-readback.bin'
    command(['besmtool', 'dump', '1234', '--start=0', f'--length={zones + 2}',
             '--to-file=' + str(readback)], directory, env)
    if readback.read_bytes() != data:
        raise AssertionError('Fixture disk does not match its input')


def deck(command_line):
    cards = ['шифр 419999^', 'врем 30^', 'ацпу 100^',
             'лента 30(1234-ЗП)66(1235)^', 'росп 0^', 'вход 70000^', 'е']

    def area(address, words):
        cards.append(f'в {address:o}')
        for word in words:
            text = f'{word:016o}'
            cards.append('с ' + ' '.join(text[i:i+4] for i in range(0, 16, 4)))

    # Minimal Monitor shared cells. Error returns through 2 and normal *74
    # exits through KEYE72 reach the same snapshot/termination handler.
    area(2, [0o0307001002200000, iso('TEST')])
    area(0o21, [iso('TEST'), 0o300000])
    area(0o53, [0o76000, iso('KEYMON')])
    line = (command_line + '\n').encode().ljust(84, b' ')
    area(0o55, [int.from_bytes(line[i:i+6], 'big') for i in range(0, 84, 6)])
    area(0o70030, [0, iso('KEYE72'), 0o0010010000660063])
    # Save the final PBUFF (seven zones) and globals to the fixture disk.
    area(0o70040, [((0o25 + i) << 30) | (0o30 << 12) | (0o100 + i)
                   for i in range(7)] + [0o0000020000300107])
    cards += ['в 70010', 'к 00 100 0030']
    cards += [f'к 00 170 {0o40+i:04o}' for i in range(8)]
    cards += ['к 00 110 0030', 'к 00 062 0000',
              'в 70000', 'к 00 110 0031', 'к 00 172 0010',
              'к 00 170 0032', 'к 00 30 02000', 'еконец']
    return '\n'.join(cards) + '\n'


def command(argv, directory, env):
    result = subprocess.run(argv, cwd=directory, env=env, stdin=subprocess.DEVNULL,
                            capture_output=True, text=True, timeout=30)
    if result.returncode:
        raise RuntimeError(f'{argv[0]} failed: {result.stdout}\n{result.stderr}')
    return result


def printer_pages(text):
    pages = text.split('\f')
    if pages[0] or pages[-1] != '\n':
        raise AssertionError('Missing initial/final printer formfeed')
    return [part.removeprefix('\n').removesuffix('\n').split('\n')
            for part in pages[1:-1]]


def run_case(output, image, case):
    directory = output / case['name']
    directory.mkdir(parents=True, exist_ok=True)
    env = environment(directory)
    # Same pattern as re-pult/tools/run-dispak.sh: a writable, private HOME
    # keeps DISPAK away from the user's input queue. Set BESM6_PATH first.
    env['HOME'] = str(directory / 'home')
    Path(env['HOME']).mkdir(exist_ok=True)
    env.pop('BESM6_SMALL_DISKS', None)
    write_fixture(directory, case['payload'], env)
    (directory / '1235').write_bytes(b'')
    command(['besmtool', 'write', '1235', '--start=063', '--length=3',
             '--from-file=' + str(image)], directory, env)
    (directory / 'job.b6').write_text(deck(case.get('command', '123')))
    (directory / 'input.txt').write_bytes(case['payload'])
    result = command(['dispak', '--no-insn-check', '-x', '-p', '-l', '-t',
                      '--output=' + str(directory / 'print.txt'),
                      '--output-raw=' + str(directory / 'print.raw'),
                      str(directory / 'job.b6')], directory, env)
    (directory / 'stdout.txt').write_text(result.stdout)
    (directory / 'trace.txt').write_text(result.stderr)
    if 'КОНЕЦ ЗАДАЧИ' not in result.stdout or '70022' not in result.stdout:
        raise AssertionError('FPRINT did not return through the exit handler')
    status = re.search(r'70022: \*62 0 .*acc=([0-7]+)', result.stderr)
    expected_status = (None if 'status' in case and case['status'] is None else
                       (0o6400000000000000 | case['status'] if case.get('status') else 0))
    if not status or (expected_status is not None and int(status[1], 8) != expected_status):
        raise AssertionError('Unexpected exit status: ' + str(status))
    reads = re.findall(r'02445: \*70 .*\(=001036000030([0-7]{4})\)', result.stderr)
    if [int(x, 8) for x in reads] != list(range(2, 2 + case['reads'])):
        raise AssertionError('Wrong disk read sequence: ' + str(reads))
    prints = len(re.findall(r'03027: \*64 ', result.stderr))
    if prints != case.get('prints', len(case.get('pages', [None]))):
        raise AssertionError('Wrong number of printer calls')
    loader_reads = re.findall(r'\*70 .*\(=00100[123]000066([0-7]{4})\)', result.stderr)
    if loader_reads != ['0063', '0064', '0065']:
        raise AssertionError('The three-zone image was not loaded unchanged')
    command(['dispak', '-l', '--decode-output', str(directory / 'print.raw'),
             '--output=' + str(directory / 'decoded.txt')], directory, env)
    printed = (directory / 'print.txt').read_bytes()
    if printed != (directory / 'decoded.txt').read_bytes():
        raise AssertionError('Raw printer stream does not reproduce printed text')
    text = printed.decode('utf-8-sig').replace('\r\n', '\n').replace('\r', '\n')
    if 'pages' in case:
        actual = printer_pages(text)
        expected = [[row.rstrip() for row in page] for page in case['pages']]
        if actual != expected:
            (directory / 'expected.json').write_text(json.dumps(expected, indent=2))
            (directory / 'actual.json').write_text(json.dumps(actual, indent=2))
            raise AssertionError('Printed rows/columns differ: ' + str(directory))
    if 'nonblank' in case:
        rows = [row for row in text.replace('\f', '').split('\n') if row.strip()]
        if rows != case['nonblank']:
            raise AssertionError('Wrong conversion/overstrike passes: ' + repr(rows))
    if 'message' in case and case['message'] not in text:
        raise AssertionError('Missing diagnostic: ' + repr(text))
    snapshot = directory / 'snapshot.bin'
    command(['besmtool', 'dump', '1234', '--start=0100', '--length=8',
             '--to-file=' + str(snapshot)], directory, env)
    return dict(name=case['name'], passed=True, input_bytes=len(case['payload']),
                data_zones_read=reads, printer_calls=prints,
                exit_status_octal=(None if case.get("status", 0) is None else
                                   f'{case.get("status", 0):o}'),
                artifacts=str(directory.relative_to(ROOT)),
                _text=printed, _raw=(directory / 'print.raw').read_bytes())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rebuilt', type=Path, default=BUILD / 'fprint/fprint.img')
    parser.add_argument('--output', type=Path, default=BUILD / 'fprint/exercise')
    args = parser.parse_args()
    original = IMAGES / '4001/0063-fprint.bin'
    rebuilt = args.rebuilt.resolve()
    old, new = read_words(original), read_words(rebuilt)
    differences = [BASE+i for i, (a, b) in enumerate(zip(old, new)) if a != b]
    if len(old) != 3072 or len(new) != 3072 or differences != [0o2010]:
        raise ValueError('Run build.py first: expected the exact reconstruction')
    report = dict(checked_at=datetime.now(timezone.utc).isoformat(),
                  dispak=subprocess.run(['dispak', '--version'], capture_output=True,
                                        text=True, check=True).stdout.strip(),
                  private_home=True, images_unpatched=True, scenarios=[])
    source_images = {path: path.read_bytes() for path in (original, rebuilt)}
    for case in cases():
        records = [run_case(args.output.resolve() / version, image, case)
                   for version, image in [('original', original), ('rebuilt', rebuilt)]]
        if records[0]['_text'] != records[1]['_text'] or records[0]['_raw'] != records[1]['_raw']:
            raise AssertionError('Original/rebuilt printer output differs: ' + case['name'])
        for record in records:
            del record['_text'], record['_raw']
        report['scenarios'].append(dict(name=case['name'], passed=True,
                                        printer_streams_identical=True, runs=records))
        print(case['name'] + ': original/rebuilt passed; printer streams identical', flush=True)
    report['passed_runs'] = len(report['scenarios']) * 2
    if any(path.read_bytes() != data for path, data in source_images.items()):
        raise AssertionError('An input image changed during execution')
    report['input_images_unchanged'] = True
    (HERE / 'execution.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(f'{report["passed_runs"]} emulator runs passed; {HERE / "execution.json"}')


if __name__ == '__main__':
    main()
