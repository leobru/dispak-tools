# КОМПОН.РЕЖИМ3, version 2.02/3

This recovery uses volume 2248, zones `02560–02577`, with the later
LINK/BLINK sources as a starting point. It is **in progress**. The complete
`kompon3.pas` still contains later-version bodies and globals requiring
comparison; it is not yet a rebuilt historical executable.

The original has 100 PMD scopes (99 routines and the program) and 386
variable descriptors. `inventory.json` records their names, offsets, kinds,
sizes, indirection and enum tables. Names are the eight-character PMD
spellings. Record field names are descriptive: PMD does not supply them.

## Recovered differences from LINK

The ten early table-dump routines have been restored in their original
order. The `OTЛ` parser `PEЖOTЛ` and the debug output in `BHECИИMЯ` have
also been recovered. The older load-list parser has no later LINK
concatenation option. Its frame is again 50 words and its code 384 words.

PMD distinguishes `БYФЛEKC`, a two-word record, from an array of characters;
the copied token therefore uses its `.text` view when passed to ASSIGN.
`CTPOKA` occupies 20 words. `ФЛAГ` has the enumerators `ФЛOTЛ, ФЛMET`.
`DEBUG` is a set; `TИПPAЗД` has enumerators `BЫП, CИC`. The table handles
are indirect real scalars, declared as `@real`.

The dump code establishes the older segment packing: the relative-address
flag belongs with the 20-bit disk address and 27-bit load address in the
first header word; length occupies 24 bits in the second word. Separate
variant views preserve the exact fields printed by the historical dumps.

## Build and compare

From the repository root:

```sh
python3 runtime/kompon3/analyze.py
python3 runtime/kompon3/build.py
python3 runtime/kompon3/compare.py
python3 runtime/kompon3/disassemble.py DUMPTAC PEЖOTЛ
```

The full source compiles and links with the current working-tree compiler,
producing 101 PMD scopes. All original scope names are present; the extra
`SECTID` helper still needs reconciliation with the older implementation.
Currently **39 routines, 1901 words**, agree in normalized bodies, word
counts, frames and PMD variable declarations. This includes all ten early
dumps, `BHECИИMЯ`, `YTOЧHEHИ`, `PEЖOTЛ` and `PAЗБOPЗA`.
Bounds checks remain enabled through the recovered parser; their later
use still needs recovery. `--through PAЗБOPЗA` builds just the first 37
routines and an empty main for focused comparison.

Compilation starts from working-tree `mypas.b6` by default;
`--compiler-source` selects another base deck. The shared linker script
patches only inline TRUNC and INPUT-before-OUTPUT allocation in the build
copy, leaving instruction-node layout and heap options unchanged.
The earlier `NO GLOBAL MEMORY` failure at `DUMPCTEK` is resolved with the
current compiler. The successful listing is `runtime/build/kompon3/candidate.lst`;
`full-current.lst` and `full-link1.lst` retain earlier failed attempts.

External services are inert stubs for **static comparison**. The image is
not a runnable linker. `READSEG` aliases the historical READPAIR entry;
GETSECT/GETDEF/GETREF alias TABGET with the appropriate Pascal record type.
The seven accumulator-returning services remain FORTRAN procedures with
`:= ;` assignments.

`comparison.json` reports per-routine frames, sizes, PMD declaration
differences and normalized body equality. Bodies are compared after
resolving constants, text, service entries and global addresses. Local
branch targets retain their word offsets within the routine. PMD entry
metadata, M16 line/address loads and padding are omitted; equality here
does **not** establish whole-image byte identity. Unresolved addresses
remain visible. A failed or unfinished build cannot reuse an older image.

Images, compiler decks, listings and disassembly stay under
`runtime/build/kompon3`. The original volumes are read only.

## Remaining work

Resolve the remaining prefix differences (diagnostics, scanner and
file-table insertion), restore older bodies and debug calls beyond the
parser, reconcile the remaining global slots and evaluator types, and
link compatible real runtime modules. Match PMD metadata and literal
addresses after the instruction bodies agree.
