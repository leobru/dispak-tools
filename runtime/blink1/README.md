# BLINK1: recovered Pascal application

BLINK1 is version **2.40/2** of the Elbrus-B linker, extracted from volume
4001 zones `0255–0274`. [blink1.pas](blink1.pas) was recovered using the
complete [LINK1 source](../link1/link1.pas), version 2.40/1, as its basis.
Shared routine and variable names follow the older KOMPON PMD tables;
unmapped names remain descriptive. This image contains no PMD tables.

The source covers all **6586 application words**, `02012–16703`.
It compiles, and all **93 code regions** have their original entry addresses
and word counts. **87 regions match instructions including UTC padding**
after resolving calls, branches, constants and literal addresses.
All **924 constant words**, P/1D, globals and file blocks match exactly.
The [real runtime](../linker-runtime/README.md) reproduces all **1689 library
words** and their placements literally. The linker is not executed during
the build. [library.json](library.json) records the full comparison.

Shared PMD-backed identifiers were mirrored from
[KOMPON 2.02/3](../kompon3/README.md); the
[correspondence table](../linker-runtime/historical-names.json) records
the names and scopes. Rebuilding after the renames produced an image
byte-for-byte identical to the pre-rename build.

## Build and inspect

```sh
python3 runtime/blink1/analyze.py
python3 runtime/blink1/build.py
python3 runtime/blink1/analyze.py 10645 11162
tkdiff runtime/build/blink1/original.dis runtime/build/blink1/rebuilt.dis
```

The build shares LINK1's compiler, symbolic comparison and loop-marker
checks. It uses private scratch disks and HOME under `runtime/build/blink1`.
The source images are extracted with `besmtool` when absent; no extracted
`.bin`, generated `.dis`, or private volume belongs in Git.

- [inventory.json](inventory.json): original routine and external addresses.
- [blink1.sym](blink1.sym), [names.json](names.json): recovered symbols.
- [recovery.json](recovery.json): comparison of each rebuilt code region.

The analyzer pairs the 87 corresponding procedure frames and derives
external relocations from aligned uses in the original LINK1 and BLINK1
images. Every accepted external target has a single consistent relocation.
The build checks BLINK1 against its own original image.

## Original image layout

Addresses and zones are octal; word counts are decimal.

| Region | Address / size |
|---|---|
| Allocation | `0255–0274`, 16 zones |
| P/BOOT loaded pages | `012`, ten zones |
| Pascal application | `02012–16703`, 6586 words |
| Startup | `16677` |
| Constant pool | `16704–20537` |
| P/1D and globals | `20540` |
| INPUT / OUTPUT | `21410` / `21446` |
| Runtime | `21505` |
| FREE | `24736` |

## Changes from LINK1

BLINK1 extends address handling to 27 bits. The input-job checks accept
load addresses below `134217728` instead of `32768`. Definition results and
section base addresses are sign-extended from 27 bits before passing to
the value-arithmetic services. Expression output accepts values in
`[-134217728, 134217728)` and reduces them modulo `134217728`.
BЫЧИCЛEH applies the same wider bounds to computed definitions.

Five routines account for the entire **43-word** increase:

| Routine | BLINK1 entry | LINK1 words | BLINK1 words | Recovered change |
|---|---|---:|---:|---|
| ЗHAЧCOБ | `10645` | 33 | 37 | Replaced the 15-bit reduction with 27-bit sign extension |
| ЗHAЧBHEШ | `10712` | 51 | 55 | Applied the same conversion through a bound reference |
| ЗABEPШИO | `11162` | 101 | 116 | Added wider range checks, long-address checks and opcode-10 prefix splitting |
| ГPYЗЧИK | `11442` | 95 | 111 | Sign-extended long instruction addresses and accepted opcode-10 prefixes |
| MAШИHA | `12200` | 835 | 839 | Sign-extended the section base instead of retaining its low 15 bits |

ГPYЗЧИK accepts prefix opcode 2 directly and opcode 10 with its address
multiplied by 4096. ЗABEPШИO's corresponding split uses division and remainder
by 4096; the original tests the opcode in `COMMAND.left` at this point.
This detail is preserved in the Pascal source.

The output header identifies its producer as `КОМПОН-2`, and the opening
banner reports version `2.40/2`. The main driver and output format otherwise
reuse the recovered LINK1 structure. External `B…` identifiers retain their
LINK1 names; their actual BLINK1 targets are listed in the inventory.

## Remaining differences

These are the same six differences documented for LINK1; they do not
change region lengths or entry addresses:

| Routine | Difference |
|---|---|
| ДAЙЦEЛOE | A restore-helper call replaces a tail call, and one redundant jump is omitted |
| CKAHEP | Three redundant jumps are omitted |
| PEЖПEЧ | One redundant jump is omitted |
| YЧET | Integer zero comes from P/1D instead of the constant pool |
| CБOPOБЬE | One redundant NTR 7 before ПEЧДЛФAЙ is omitted |
| ГEHMETKИ | One redundant NTR 7 before ПEЧДЛФAЙ is omitted |

The loop pattern and 15 explicit `(*q*)` exceptions are inherited from
LINK1. All 56 loops retain `(r)`. Empty pointers use `ptr(0)`.

The current comparison has a padded symbolic edit cost of **12**; this is
an instruction/label alignment measure, not a count of differing image words.
All 924 constant words now match literally. Declaring the hash-array type
before the pair-array type restored their original order. BЫPABAДP uses the
compiler's inline truncation and matches without a padding jump.
The separate runtime disassemblies are `original-runtime.dis` and
`rebuilt-runtime.dis`. Real link jobs remain unexercised.
