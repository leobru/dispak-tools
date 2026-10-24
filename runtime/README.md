# Recovered NEWPASC runtime libraries

The corpus contains 26 memory images extracted from volume 4001, plus the four
root `*.bin` files. Two extracts duplicate `test.bin` and `тестац.bin`, giving
28 distinct images. [ANALYSIS.md](ANALYSIS.md) lists their locations, startup
layouts, symbol candidates, and generated disassemblies.

[MONITOR-CONSISTENCY.md](MONITOR-CONSISTENCY.md) compares the Monitor modules
across all 26 volume extracts. Regenerate it with `python3 runtime/consistency.py`.
The volume contains several runtime variants; missing module matches are kept
separate from confirmed instruction differences.

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
