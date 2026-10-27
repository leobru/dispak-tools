# BLINK: recovered Pascal application

BLINK comes from volume 4001 zones `0275–0314`. Its Pascal application is
the same version **2.40/3** as [LINK](../link/README.md), with producer stamp
`КОМПОН-3`. [blink.pas](blink.pas) is based on LINK's complete source.
Routine and variable names are inherited descriptive names; there are no
original PMD tables.

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

## Private compiler copy

[pack_compiler.py](pack_compiler.py) prepares
`runtime/build/blink/mypas-packed.b6` from the current `mypas.b6`.
In `insnltyp`, `control` is a one-word packed record containing the two-bit
`ilm` and the three flags `zeroTest`, `signTest`, `bitTest`. It replaces
the old `ilm` word and the three separate boolean words: the node occupies
**11 words instead of 14**. Field accesses, including those inside `with`,
refer to `control`; whole-node assignments still copy all fields.

The compiler keeps its original **K9** heap. It also emits the original
inline TRUNC sequence and allocates INPUT before OUTPUT. This packed copy successfully
compiles EVALUATE and the complete application, whereas the current
unpacked compiler exhausts its heap in EVALUATE. `mypas.b6` is not edited.
The generated private source is fingerprinted for compiler-cache reuse;
private volumes are not hashed by this build.

## Compilation comparison

All **93 entries and sizes match**, **85 regions match normalized
instructions including UTC padding**, and the padded symbolic edit cost
is **17**. All **926 constant words** and **384 application global words**
match literally at their original addresses.

The remaining eight differences are the same ones documented for LINK:
SCANINT, GETTOKEN, PRINTSEL, STAMPOBJ, GATHER, ALIGNUP, PUTWORD, FIRSTVAL and
LABELS. See [LINK's instruction differences](../link/README.md#remaining-instruction-differences).
All loop markers, explicit `(*q*)` exceptions and padding are inherited
from LINK. Empty pointers use `ptr(0)`; large binary-round integer
constants retain their octal `B` notation.

All **1741 library words**, public entries and FREE now match literally.
P/1D, globals, file blocks and constants also match at their original
addresses. [library.json](library.json) records the full comparison.
Separate `original-runtime.dis` and `rebuilt-runtime.dis` listings cover the
library. The build does not execute BLINK as a linker.
