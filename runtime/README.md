# Recovered NEWPASC runtime libraries

The corpus contains 26 memory images extracted from volume 4001, plus the four
root `*.bin` files. Two extracts duplicate `test.bin` and `тестац.bin`, giving
28 distinct images. [ANALYSIS.md](ANALYSIS.md) lists their locations, startup
layouts, symbol candidates, and generated disassemblies.

[MONITOR-CONSISTENCY.md](MONITOR-CONSISTENCY.md) compares the Monitor modules
across all 26 volume extracts. Regenerate it with `python3 runtime/consistency.py`.
The volume contains several runtime variants; missing module matches are kept
separate from confirmed instruction differences.

[COMPAR.md](COMPAR.md) uses the `compar.b6` decompilation to identify additional
helpers, shared TTIO state, conversion-table variants, and external services.
Run `python3 runtime/compar.py` to regenerate its machine-readable evidence and
supplementary symbols.

[FILE-ACCESS.md](FILE-ACCESS.md) records the include and COPY source decks
extracted from volume 4001 zones `0005–0007`, including the `MKNAME` and `OPENF`
signatures that identify COMP's previously address-named services.
The [recovered Madlen bundles](file-access/README.md) for these two services
and their shared helpers include relocation evidence from independently linked
copies in the volume 4001 corpus.

[MORE recovery](more/README.md) reconstructs the intact Pascal application and
rebuilds its erased runtime with the recovered Monitor helpers and COMP's
file-access library. `python3 runtime/more/build.py` produces a complete image
and a private repaired volume 4001, preserving every zone outside MORE's
three-zone allocation and leaving the original volume unchanged.

[MTD recovery](mtd/README.md) restores the small tape-to-disk copier from
volume 4001 zones `0047–0050`. `python3 runtime/mtd/build.py` rebuilds it on
private disks: all 677 application words and the complete runtime match the
original literally. The full two-zone image differs only in the loader value
at `02010.L`.

[BOX recovery](box/README.md) restores the Monitor utility from volume 4001
zones `0066–0067`. `python3 runtime/box/build.py` reproduces all 527 application
words and the full runtime literally; only `02010.L` differs in the complete
two-zone image. The build dumps the image without executing BOX commands.

[MT recovery](mt/README.md) restores the tape-control utility from volume 4001
zones `0172–0174`. `python3 runtime/mt/build.py` reproduces all 771 application
words and all 1333 runtime words literally; only `02010.L` differs in the
complete image. The uncatalogued MT at `0104–0105` corroborates the common
parser and service modules after relocation.

[МОНИТР recovery](monitr/README.md) restores the Pascal part of the Monitor's
command interpreter, volume 4001 zones `0002–0010`. `python3
runtime/monitr/build.py` reproduces the application, constants, globals and
runtime (`02000–07431`) literally, except `02010.L`. The memory above FREE
held buffers left in core when the image was written and is not reproduced.

[ПРОЗ recovery](proz/README.md) restores the interactive file viewer/editor
from volume 4001 zones `0030–0033`. `python3 runtime/proz/build.py` reproduces
all 1574 application words and all 1709 runtime words literally. The complete
four-zone image differs only in `02010.L`; file operations are not executed
during the build.

[FPRINT recovery](fprint/README.md) restores the line-printer utility PRINTFIL
from volume 4001 zones `0063–0065`. `python3 runtime/fprint/build.py` reproduces
all 1275 application words and all 1541 runtime words literally, including
its earlier file-access library. The complete three-zone image differs only
in `02010.L`; printer and file operations are not executed during the build.
`python3 runtime/fprint/exercise.py` exercises both images on private disks:
all 22 runs passed, including multi-zone input and two-sheet printing, with
byte-identical raw printer streams. See [execution results](fprint/execution.json).

[LINK1 recovery](link1/README.md) reconstructs the Elbrus-B linker from volume
4001 zones `0175–0214`. The current partial source covers 42 routines and
1679 of 6543 application words, including the complete link-job parser.
`python3 runtime/link1/build.py` compiles these routines; 34 match after
structural normalization. This is not yet a runnable rebuilt linker.

[PASCODER and overlays](pascoder/README.md) disassembles the library image writer
and its separate `P/BOOT` reader. It describes the three TABLE fields, computed
zone count, saved stack override, and АСС3's independently implemented overlay
loading and return convention.

[КАНАЛ: purpose and interface](kanal/README.md) records the preliminary analysis
of 4001/0023 before decompilation: multiplex-channel registers, the 16-bit data
protocol with parity and synchronization, operator commands, file transfers
and disk requests.

[PRINT: purpose and interface](print/README.md) analyzes 4001/0051: wildcard
selection through FIRSTF/NEXTF, line-printer output, enlarged filename banners,
alternative PC encoding, uppercase overprinting, and command-line parameters.
The character tables are decoded statically; this image has not been exercised
or rebuilt.

Four selectable libraries have been recovered as relocatable Madlen:

| Profile | Source binary | Runtime words | Public entries |
|---|---|---:|---:|
| [`monitor`](profiles/monitor/README.md) (default) | `test.bin` | 878 | 44 |
| `svs` | `тестац.bin` | 282 | 36 |
| `mark3` | `mark3.bin` | 294 | 38 |
| `pak` | `pak.bin` | 364 | 43 |

The Monitor entry count includes seven named shared data words introduced by
the module split; the recovered instruction and data word count is unchanged.

The libraries contain the routines present in those images. They are not complete
implementations of every NEWPASC helper. Unsupported helpers stop the build before
execution; for example, the validation suite checks rejection of `P/4`. The volume
images extend the analysis corpus; they are not all recovered library profiles.

## Compile and run a new Pascal program

Run these commands from the repository root. They require the existing DISPAK,
`besmtool`, NEWPASC on volume 77, and system volumes available on `BESM6_PATH`.

```sh
python3 runtime/build.py run runtime/examples/smoke.pas
python3 runtime/build.py run runtime/examples/nested.pas --profile svs
python3 runtime/build.py run runtime/examples/packed.pas --profile pak
```

`run` builds a private PERSO library, compiles the program, checks the loader map
and every relocated runtime word, then executes the linked memory image. Its
printing output appears on stdout. Compilation listings, images, and execution
output are retained under `runtime/build/PROFILE/run-PROGRAM/`.

The SVS profiles supply `(*=a1*)` before the Pascal source, as required by their
historical I/O routines. Options explicitly written in the source take effect
normally. The Monitor profile uses the compiler's normal defaults.

The default profile also contains `P/3` and `P/6A` from `тестац.bin`, in
[p_3.madlen](profiles/monitor/p_3.madlen) and
[p_6a.madlen](profiles/monitor/p_6a.madlen). These frame and ALFA helpers use the
same dependencies as the Monitor implementation; all six words are checked
against their source when linked. The I/O and startup variants remain separately
selectable.

The runner accepts an adjacent `.pre` file for application externals. It currently
runs with standard input closed; the examples exercise local text files.
Large programs can exceed the short absolute address range of a recovered
profile. Such links are rejected instead of expanding instructions or changing
the recovered runtime.

## Build the library for another launch deck

```sh
python3 runtime/build.py library --profile monitor
```

This creates `runtime/build/monitor/3776`, with the PERSO library at zone `0100`.
Put that directory first on `BESM6_PATH`, mount `67(3776)` read-only, and load
`*perso:670100,cont` after the Pascal program. The runner's generated job shows a
complete example, including the PASCODER stack descriptor at core address `02007`
required by the original startup code. The PERSO output is a private library;
the build does not install it into volume 77.

The Monitor sources are split into individual Madlen files under
[`profiles/monitor/`](profiles/monitor/README.md), following the standard Pascal
library's routine groups and ENTRY aliases. Each module declares its actual
dependencies, so the loader can select the modules a program needs. The other
profiles use `profiles/PROFILE/runtime.madlen`; their `RT` module names and
grouping are recovery choices made to fit Madlen's entry tables. Explicit address
fixups are in each profile's `relocations.json`. Application FORTRAN code between
runtime modules is excluded. Raw constants, strings, and original instruction
packing are preserved.

## Reproduce the extraction and analysis

Binary inputs are not stored in Git. Extract the four root `*.bin` images from
volume 2113 with `besmtool`; the command below regenerates the volume 4001 images.

```sh
python3 runtime/corpus.py
python3 runtime/analyze.py
```

`corpus.py` locates volume 4001 on `BESM6_PATH`; `--volume PATH` selects an exact
image. It reads the physical DISPAK format, removes service words and convolution
bits, and writes six big-endian bytes per word, loaded at `02000`.
[corpus.json](corpus.json) records hashes, catalog descriptors, zone ranges,
loader variants, and duplicate identities. Existing extracts with different
contents are never overwritten.

Catalog lengths are decoded from their descriptors. In particular, `МТСОРУ`
occupies `0101–0103`; the image at `0104` is uncatalogued. The other embedded image
starts at `0002` inside `МОНИТР`. Allocated files can contain overlays and padding.

The matcher reads the loader's final table, distinguishes commons and ENTRY
aliases, and requires exact operands except for consistent address relocation.
Ambiguous matches remain explicit candidates. Generated symbol files use `C`
for code and `D` for data. The reviewed profile names are also used as references
when analyzing the volume images. This analysis identifies candidates; it does
not recover missing object-module relocation information automatically.

`profiles.json` holds reviewed code/data ranges, entries, commons, and pointer
fields. `reviewed.py` regenerates the three SVS layouts in it; `recover.py PROFILE`
generates the corresponding Madlen and fixups. `P/08` and other packed-field
tables have explicit data-pointer relocations, rather than guessed instruction
operands.

## Validation

```sh
python3 runtime/build.py check
```

The suite performs nine regression checks, exact comparisons of all four
libraries at their original addresses, and eleven compiler/emulator scenarios:
text-file round trips, integer formatting, nested frames at different layouts,
packed arrays and sets, a bounds error, and rejection of an unsupported helper.
Golden layouts use padding in place of excluded application routines; that padding
is absent from the reusable libraries. Each program link checks all runtime words
against the explicit relocation records and checks that public entries resolve
to the recovered modules. Installed Pascal helpers are rejected even if a helper
has the same name.

[validation.json](validation.json) records the last successful run and source
hashes. The suite confirms that the source volume, installed disks, and root
binaries remain unchanged. Hardware-specific SVS device operations and every
error branch have not been exercised; successful smoke tests do not establish
those behaviors.
