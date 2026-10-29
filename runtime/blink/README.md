# BLINK: recovered Pascal application

BLINK comes from volume 4001 zones `0275–0314`. Its Pascal application is
the same version **2.40/3** as [LINK](../link/README.md), with producer stamp
`КОМПОН-3`. [blink.pas](blink.pas) is based on LINK's complete source.
Shared routine and variable names follow the older KOMPON PMD tables;
unmapped names remain descriptive. This image contains no PMD tables.

Shared PMD-backed identifiers were mirrored from
[KOMPON 2.02/3](../kompon3/README.md); the
[correspondence table](../linker-runtime/historical-names.json) records
the names and scopes. Rebuilding after the renames produced an image
byte-for-byte identical to the pre-rename build.

## Relationship to LINK

Both original images have the same **6875-word application** at
`02012–17344`, the same 87 procedure frames, and the same 93 region entries
and sizes. There are **583 changed half-words in 579 application words**.
Every change is a long address referring to the runtime or an external
service; opcodes and modifier registers are unchanged. All uses agree on
the mapping of **69 moved service addresses**. The **926-word constant
pool**, P/1D, file blocks and application globals are literally identical.

Accordingly, the recovered Pascal statements are unchanged from LINK.
The program name and recovery comments identify BLINK; its build uses
BLINK's own original image and service addresses. The inventory records
every moved address and its number of application uses. [Shared runtime sources](../linker-runtime/README.md) now reconstruct all
service bodies, including BLINK's timestamp and memory-manager variants.

Addresses and zones below are octal; word counts are decimal.

| Region | Address / size |
|---|---|
| Allocation | `0275–0314`, 16 zones |
| P/BOOT loaded pages | `012`, ten zones |
| Pascal application | `02012–17344`, 6875 words |
| Startup | `17340` |
| Constant pool | `17345–21202`, 926 words |
| P/1D and globals | `21203` |
| INPUT / OUTPUT | `22053` / `22111` |
| Runtime | `22150` |
| FREE | `25465` (31 words below LINK's `25524`) |

## Build and inspect

```sh
python3 runtime/blink/analyze.py
python3 runtime/blink/build.py
python3 runtime/blink/analyze.py 11165 11452
tkdiff runtime/build/blink/original.dis runtime/build/blink/rebuilt.dis
```

The build shares LINK1's compilation and comparison code. Missing original
images are extracted read-only with `besmtool`. Scratch disks, HOME,
compiler sources, listings, images and disassemblies stay under
`runtime/build/blink`; extracted binaries and private volumes are not
source artifacts.

- [inventory.json](inventory.json): original regions, services and LINK
  relocation evidence.
- [blink.sym](blink.sym), [names.json](names.json): recovered symbols.
- [recovery.json](recovery.json): per-region compilation comparison.

## Compiler

The shared builder starts from `mypas.b6`; `--compiler-source` selects
another base compiler deck. The [compatibility script](../linker-runtime/patch_compiler.py) changes only inline TRUNC emission
and INPUT-before-OUTPUT allocation in the generated build copy. It leaves
instruction-node layout and heap options unchanged. Compiler source is
fingerprinted for cache reuse; private volume 77 and HOME remain under the
build directory. Private writable volumes are not hashed.

## Compilation comparison

All **93 entries and sizes match**, **85 regions match normalized
instructions including UTC padding**, and the padded symbolic edit cost
is **17**. All **926 constant words** and **384 application global words**
match literally at their original addresses.

The remaining eight differences are the same ones documented for LINK:
ДAЙЦEЛOE, CKAHEP, PEЖПEЧ, YЧET, CБOPOБЬE, BЫPABAДP, ЗAПBPAЗД, ГPYЗЧИK and
ГEHMETKИ. See [LINK's instruction differences](../link/README.md#remaining-instruction-differences).
All loop markers, explicit `(*q*)` exceptions and padding are inherited
from LINK. Empty pointers use `ptr(0)`; large binary-round integer
constants retain their octal `B` notation.

All **1741 library words**, public entries and FREE now match literally.
P/1D, globals, file blocks and constants also match at their original
addresses. [library.json](library.json) records the full comparison.
Separate `original-runtime.dis` and `rebuilt-runtime.dis` listings cover the
library. The build does not execute BLINK as a linker.
