#!/usr/bin/env python3
"""Compare complete BESM-6 images byte for byte, without normalization.

Usage: python3 programs/pak/compare-image.py [--edition 2053|2113]
       [--reference FILE] [--candidate FILE]
Writes [2113-]image-comparison.md and build/pak/[2113-]full-image-comparison.json.
Exit status 1 means that bytes or file lengths differ.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import ROOT, BUILD
WORK = BUILD / 'pak'
BASE = 0o2000
ZONE_BYTES = 1024 * 6
REGIONS = [
    (0o2000, 0o2012, 'Загрузчик PASCODER'),
    (0o2012, 0o2026, 'Вход и инициализация файлов'),
    (0o2026, 0o5721, 'Пользовательские подпрограммы'),
    (0o5721, 0o7232, 'Основной блок'),
    (0o7232, 0o7237, 'Запуск Pascal'),
    (0o7237, 0o10120, 'Константы и строки эталона'),
    (0o10120, 0o10736, 'Данные и файлы эталона'),
    (0o10736, 0o11547, 'Библиотека эталона'),
    (0o11547, 0o12000, 'Хвост четвёртой зоны'),
]


def metadata(path, data):
    return dict(path=str(path), bytes=len(data), words=len(data) // 6,
                zones=len(data) // ZONE_BYTES,
                sha256=hashlib.sha256(data).hexdigest())


def word(data, index):
    part = data[index * 6:(index + 1) * 6]
    return f'{int.from_bytes(part, "big"):016o}' if part else None


def compare(reference, candidate):
    common = min(len(reference), len(candidate))
    prefix_bytes = sum(a != b for a, b in zip(reference, candidate))
    differing = []
    for i in range(max(len(reference), len(candidate)) // 6):
        if reference[i * 6:(i + 1) * 6] != candidate[i * 6:(i + 1) * 6]:
            differing.append(dict(address=f'{BASE + i:05o}',
                                  reference=word(reference, i),
                                  candidate=word(candidate, i)))
    regions = []
    for lo, hi, name in REGIONS:
        a, b = (lo - BASE) * 6, (hi - BASE) * 6
        if b > common:
            continue
        regions.append(dict(first=f'{lo:05o}', last=f'{hi - 1:05o}',
            name=name, words=hi - lo,
            differing_words=sum(reference[i:i + 6] != candidate[i:i + 6]
                                for i in range(a, b, 6)),
            differing_bytes=sum(x != y for x, y in
                                zip(reference[a:b], candidate[a:b]))))
    extra = candidate[common:] if len(candidate) > common else reference[common:]
    return dict(equal=reference == candidate, common_bytes=common,
        common_differing_bytes=prefix_bytes,
        length_difference_bytes=abs(len(reference) - len(candidate)),
        differing_bytes=prefix_bytes + abs(len(reference) - len(candidate)),
        differing_words=len(differing), extra_nonzero_bytes=sum(x != 0 for x in extra),
        regions=regions, word_differences=differing)


def main():
    global REGIONS
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--edition',choices=['2053','2113'],default='2053')
    p.add_argument('--reference', type=Path, default=None)
    p.add_argument('--candidate', type=Path,
                   default=None)
    args = p.parse_args()
    new=args.edition=='2113'
    stem='pak-2113' if new else 'pak'
    if args.reference is None: args.reference=WORK/(stem+'.bin')
    if args.candidate is None:
        args.candidate=WORK/(stem+('-newpasc' if new else '-pascal'))/'image.bin'
    report_stem='2113-image-comparison' if new else 'image-comparison'
    json_name='2113-full-image-comparison.json' if new else 'full-image-comparison.json'
    reference_label='2113:1246-1251' if new else '2053/2048/2248'
    compiler_label='NEWPASC с профилем pak-2113' if new else '*PASCAL'
    if new:
        REGIONS=[(0o2000,0o2012,'Загрузчик PASCODER'),
            (0o2012,0o2013,'Вход'),
            (0o2013,0o5675,'Пользовательские подпрограммы'),
            (0o5675,0o5710,'Инициализация файлов'),
            (0o5710,0o7250,'Основной блок'),
            (0o7250,0o7255,'Запуск Pascal'),
            (0o7255,0o10136,'Константы и строки эталона'),
            (0o10136,0o10752,'Данные и файлы эталона'),
            (0o10752,0o11563,'Библиотека эталона'),
            (0o11563,0o12000,'Хвост четвёртой зоны')]
    reference = args.reference.read_bytes()
    candidate = args.candidate.read_bytes()
    for path, data in [(args.reference, reference), (args.candidate, candidate)]:
        if not data or len(data) % ZONE_BYTES:
            raise ValueError(f'{path}: expected complete 6144-byte zones')
    report = compare(reference, candidate)
    report['reference'] = metadata(args.reference.resolve().relative_to(ROOT), reference)
    report['candidate'] = metadata(args.candidate.resolve().relative_to(ROOT), candidate)
    output = WORK / json_name
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')

    r, c = report['reference'], report['candidate']
    lines = [
        '# Побайтовое сравнение полного образа ПАК', '',
        '**Образы совпали.**' if report['equal'] else '**Образы не совпали.**', '',
        'Сравнение выполнено без перемещения адресов, замены констант,',
        'перестановки библиотеки и исключения нулевых слов. Лишние байты',
        'учтены как различия, включая нули за концом более короткого файла.', '',
        '| Образ | Зоны | Байты | SHA-256 |',
        '|---|---:|---:|---|',
        f'| Эталон {reference_label} | {r["zones"]} | {r["bytes"]} | `{r["sha256"]}` |',
        f'| Пересборка `{compiler_label}` | {c["zones"]} | {c["bytes"]} | `{c["sha256"]}` |', '',
        f'В общей части ({report["common_bytes"]} байт) отличаются '
        f'{report["common_differing_bytes"]} байт. Разница длин — '
        f'{report["length_difference_bytes"]} байт; в добавочном участке '
        f'{report["extra_nonzero_bytes"]} ненулевых байт.', '',
        f'Всего отличаются **{report["differing_bytes"]} байт** и '
        f'**{report["differing_words"]} 48-битных слов**, включая '
        'отсутствующие в одном из файлов.', '',
        '## Общая часть по адресам эталона', '',
        'Все адреса восьмеричные. Границы данных и библиотеки пересборки',
        'могут отличаться; строки таблицы используют границы эталона.', '',
        '| Адреса | Область | Слов | Различных слов | Различных байт |',
        '|---|---|---:|---:|---:|',
    ]
    for row in report['regions']:
        lines.append(f'| `{row["first"]}–{row["last"]}` | {row["name"]} | '
                     f'{row["words"]} | {row["differing_words"]} | '
                     f'{row["differing_bytes"]} |')
    if report['word_differences']:
        lines += ['', '## Первые различия', '',
                  '| Адрес слова | Эталон | Пересборка |', '|---|---|---|']
        for row in report['word_differences'][:12]:
            lines.append(f'| `{row["address"]}` | `{row["reference"]}` | '
                         f'`{row["candidate"]}` |')
    lines += ['', '## Повторение', '', '```sh', 'python3 programs/pak/extract.py',
              'python3 programs/pak/build.py pak.pas --compiler pascal',
              'python3 programs/pak/compare-image.py', '```', '',
              'При различиях последняя команда завершается с кодом 1.',
              'Полный список отличающихся слов записан в',
              '`build/pak/full-image-comparison.json`. Бинарные файлы в Git не входят.', '']
    if new:
        i=lines.index('python3 programs/pak/extract.py')
        lines[i:i+3]=['python3 programs/pak/extract.py --edition 2113',
            'python3 programs/pak/build.py pak-2113.pas --compiler newpasc \\',
            '  --compiler-source compiler/mypas.b6 --compiler-profile pak-2113',
            'python3 programs/pak/compare-image.py --edition 2113']
        lines=[line.replace('build/pak/full-image-comparison.json','build/pak/'+json_name) for line in lines]
    (HERE / (report_stem+'.md')).write_text('\n'.join(lines))
    print(f'Equal: {report["equal"]}; differing bytes: {report["differing_bytes"]}; '
          f'differing words: {report["differing_words"]}')
    print(HERE / (report_stem+'.md'))
    raise SystemExit(0 if report['equal'] else 1)


if __name__ == '__main__':
    main()
