# FORMAT analysis

Regenerate the addressed disassembly from the repository root:

```sh
make -C tools disbesm6
python3 format/disassemble.py
```

The script checks the original image hash, all displayed instruction halves,
and coverage of the code ranges declared in format.sym. The analysis is in
README.md. English symbols are assigned names, not historical source labels.
Use the binary's thresholds when describing this version: OS documentation
in re-dispak/rukava.be describes different thresholds and extension limits.

Reassemble the authoritative BEMSH source and compare the actual ЗОНГП output:

```sh
python3 format/build.py
```

This uses private HOME and output volume 1234 under build/format. It must
report zero BEMSH errors and compare both complete 6144-byte zones with
format.bin. Keep the explicit right-half МОДА filler at 00111;
the label at 00321 now provides alignment after the jump at 00320.
УХО means Усилитель Хранения Ошибки.

Write СДА operands as 64+N or 64-N. Write GOST text as КОНД П'текст';
use positioned numeric components for control and special graphic codes.
Write near-0100000 УИА and СЛИА constants as decimal negative numbers
(e.g. '77777' as -1, '76001' as -1023, '66170' as -5000).
Write each Э64 text pointer as two relocatable КОНК А(метка) halves.
Do not emit МОДА 0 padding immediately before labels; labels align words.
Combine consecutive full-word КОНД П literals into ТЕКСТ П literals,
up to six words per card, without crossing labels.
Addresses loaded into М11 must use relocatable labels or label expressions.
ПВ is placed in the right half by BEMSH; omit МОДА 0 padding before it.
Extracodes also need no МОДА 0 padding before them; preserve nonzero modifiers.
Do not quote single-digit numeric instruction operands.
Use ОПРЕ for the Е48–Е1 single-bit constants, and refer to them by Е names.
Name constants with a contiguous range of two or more set bits Е<high>П<low>,
using decimal bit numbers (e.g. 0777777777777770 is Е45П4).
Keep duplicate words at their original addresses; use the canonical name
plus an address displacement where needed to retain exact instruction bits.
Writable cells retain their semantic names even when their initial value
has this bit pattern.
Declare zero-valued writable cells and arrays as ПАМ <number of words>,
including an explicit 1 for a single cell. Account for indexed stores and
OS-written service words; split mixed writable/constant zero blocks.

РАЗ/РЗЕ formation and read-only volume checks are documented in directives.md.
The verified 2053 selector uses 0 for РАЗ and 3 for РЗЕ; prik3.be's comment
claiming 4 for РЗЕ is stale. РАЗ loads 0612–0613 and enters at 00030.

Rebuild the disassembly of 2053/0616 (formes.be) with:

```sh
python3 format/build-formes.py
```

This writes one ЗОНГП zone and compares all 1024 words with 2053/0616.
Artifacts and comparison.json are kept in build/formes, with a private HOME.
The source contains both the selector at 00101 and the ЕС tape formatter
at 00131; it is not executed by this build. Zone 0617 is entirely zero.

Reassemble the disk formatter from 2053/0614-0615 with:

```sh
python3 format/build-formmd.py
```

The authoritative source is formmd.be. The build checks the original image
hash, zero BEMSH errors, and two complete ЗОНГП zones (2048 words, 12288 bytes).
It uses private HOME and volume 1234 under build/formmd, without executing
the formatter. formmd.sym records code ranges; all remaining words are data.
Entries are 00021 (normal), 00022 (mode 3), and 00020 (termination).
