# Real runtime libraries for LINK1, BLINK1, LINK and BLINK

The four recovered Pascal programs now link real library modules. Every
library word, public entry and FREE address matches its own original image
literally. No generated executable instruction is patched after linking.
The builds do not execute the linkers' file operations.

Addresses and range ends below are octal; ends are exclusive. Word counts
are decimal.

| Program | Original library region | Matching library words | Pascal regions matching with padding | Different application words |
|---|---|---:|---:|---:|
| LINK1 | `21426–24716` | 1720 / 1720 | 87 / 93 | 9 |
| BLINK1 | `21505–24736` | 1689 / 1689 | 87 / 93 | 9 |
| LINK | `22150–25524` | 1772 / 1772 | 85 / 93 | 16 |
| BLINK | `22150–25465` | 1741 / 1741 | 85 / 93 | 16 |

All four constant pools, P/1D areas, application globals, file blocks and
the initial padding character also match literally at their original
addresses. All 93 application entry addresses and sizes match in each build.
The remaining application differences are recorded in each program's
`recovery.json`; the library comparison uses no instruction normalization.

## Pascal service results

NEWKEY, OBJREAD, OBJEDIT, FILEEDIT, TABREAD, READNEXT and NEWTAB remain
FORTRAN procedures. Their accumulator results are assigned with `:= ;`,
as in the original reconstruction. This preserves the original argument
stack and the caller's constant-pool reload and `NTR 7`. No calling-convention
or discarded-function-result compiler extensions are needed.

## Source selection and recovery

Each image selects **49 modules** from **53 shared source variants** under
[common](common). The per-image `modules.json` files record bounds, aliases,
source selection, provenance and the code roots used during recovery.

- **23 modules** reuse the recovered Monitor profile, with reviewed changes
  for the actual linker variant. These include P/SYS, frames, formatted
  output, conversion tables, startup and file state.
- **11 modules** reuse the nearby
  `besm6/mesm6/toolchain/libpas` sources: P/LNGPAR, P/STAR, P/4, P/IN, P/42,
  P/5, P/52, P/SS, P/WC, P/MD and P/UN. Candidate matching against existing
  Monitor, COMP and PROZ builds preceded selection. Normal builds need no
  sibling checkout.
- **15 modules** recover the linkers' name helpers, timestamps, buffered
  file/table operations, attachment/vector operations, date conversion,
  value arithmetic, memory allocation, shared constants/state and the
  differing P/31 and P/41 revisions from their original images.

These are reviewed source groupings, not a claim that every historical
object boundary has survived. Madlen permits at most 20 entry names per
module: DBIO and TABLEIO therefore split the shared buffer manager before
its table/cursor veneers. All typed Pascal aliases remain real entry
aliases at the original addresses; no wrapper instructions are added.

The two timestamp variants occupy 20 and 6 words; the two memory-manager
variants occupy 96 and 79 words. ATTACH selects the corresponding private
memory entry. The value-arithmetic bundles occupy 426 words in LINK1/BLINK1
and 478 in LINK/BLINK. Each pair shares one relocatable source despite its
different placement, including private entry references and the memory
manager's packed dispatch descriptor.

Recovered code uses symbolic module references and relative offsets.
Masks and instruction templates remain data. Inline ISO messages preserve
lowercase KOI-7 bytes with octal escapes because Madlen folds ordinary
lowercase card text. Zero-valued writable storage uses `BSS`; `BSS,0` also
retains original halfword padding without introducing local symbols.

## Build and inspect

```sh
python3 runtime/link1/build.py
python3 runtime/blink1/build.py
python3 runtime/link/build.py
python3 runtime/blink/build.py
tkdiff runtime/build/link1/original-runtime.dis \
       runtime/build/link1/rebuilt-runtime.dis
```

The existing application listings remain `original.dis` and `rebuilt.dis`.
The separate runtime listings include word addresses, raw words, decoded
instructions and data. Each build writes a source-side `library.json`
with all module placements, literal differences, data-region comparisons
and loader-header differences. The complete build artifacts remain under
`runtime/build/<program>`.

Private PERSO libraries use scratch volume 3776, zone `0100`. The ordinary
compiler/loader libraries are searched before this private library, whose
modules take precedence. Reviewed SUBP ordering reproduces the original
placement of the converters, diagnostic printer, file state and callbacks.
Builds fail on any library, entry, FREE, constant-pool or initialized-data
mismatch. `--explore` records discrepancies during reconstruction.

### Private compiler and Pascal data

The shared builder prepares a private copy of `mypas.b6`, leaving that file
untouched. The instruction node packs `ilm` and its three boolean flags
into one word, occupying 11 words overall with the original K9 heap.
Linker compatibility emits the original NTR/ATX/AMX/AVX truncation sequence
inline and allocates INPUT before OUTPUT. ALIGNUP consequently needs no
P/TR module or extra padding jump and matches the original instructions.

P/1 initializes the linkers' actual P/1D words and uses descriptor `02010`.
The Pascal data initializes PADCHAR to a space. LINK1 and BLINK1 declare the
one-word hash array type before the pair-array type, restoring the original
constant-pool ordering without changing storage or instructions.

### Remaining differences

Six application routines differ in LINK1/BLINK1: SCANINT, GETTOKEN,
PRINTSEL, STAMPOBJ, GATHER and LABELS. LINK/BLINK additionally retain the
PUTWORD and FIRSTVAL compiler differences documented in their READMEs.

`02010.L` remains an environment-dependent PASCODER loader value; its right
half and FREE match. BLINK1 and BLINK also have additional octal `05000`
in the original exchange zone field at `02007`, absent from the generated
scratch descriptor. These header differences are reported separately.
Full original-to-rebuild differences below FREE are 10, 11, 17 and 18 words,
respectively; none are in the libraries or initialized data.

## Regeneration

```sh
python3 runtime/linker-runtime/recover.py
```

Regeneration requires the nearby libpas checkout and reference image extracts;
normal builds read only the checked-in source selections. Missing linker
images are extracted with `besmtool` by the existing analyzers. The generator
follows public/private code roots, distinguishes inline messages and data
tables, and retains cross-module relocations. Per-image intermediate sources
are retained under `runtime/build/linker-runtime/unshared`, while identical
variants share one source file.

Binary extracts, disassemblies, compiler volumes and scratch libraries are
build artifacts. Private volumes are not hashed. Matching these images
establishes compilation and reconstruction fidelity; real link jobs have
not been exercised.
