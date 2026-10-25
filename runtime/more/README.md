# MORE recovery

MORE's Pascal application is intact. The completely zeroed zone is part of
its linked runtime. [more.pas](more.pas) reproduces the application words;
only nine runtime call-address fields differ in the current link. The build
uses the recovered Monitor runtime and COMP's later file-access library.

The earlier readable reconstruction was saved unchanged as
[more-readable.pas](more-readable.pas), with its original build report in
[readable-reconstruction.json](readable-reconstruction.json). The new source
keeps the historical line numbers, bounds checks and instruction packing.

## Surviving application

The catalog allocation on volume 4001 is `0034–0036`, loaded at `02000`.
The extract agrees with the original disk payload, including the erased zone.
Addresses and zones below are octal; word counts are decimal.

| Original addresses, inclusive | Contents | Words |
|---|---|---:|
| `02000–02011` | Monitor loader and descriptors | 10 |
| `02012–02515` | Pascal entry, procedures, main program, startup | 324 |
| `02516–02700` | Constants and PMD tables | 115 |
| `02701–03113` | Runtime constants, globals and two TEXT file blocks | 139 |
| `03114–03777` | Surviving runtime prefix | 436 |
| `04000–05777` | Entirely erased runtime zone `0035` | 1,024 |
| `06000–06103` | Surviving runtime tail | 68 |

The PMD tables identify the program as `TYPEFILE`, with procedures
`GETCMDLINE`, `WASCTTY`, its nested `PUTCHAR`, `SETUPP`, `SETLOW`, and
`GETWORD`, `GETCH`. Variable names were recovered from the same tables;
descriptive type names are reconstruction choices.
[more.sym](more.sym) labels the surviving application and identified helpers
in the original extract.

The program obtains a filename from the Monitor command line at `55B`, or
prompts with `FILE= `. It uses the active library at address `3`, defaults to
extension `TXT`, opens the file for reading, and reads zones into `74000`.
It handles CR/LF and NUL/EOT, converts characters for terminal output, and
pauses after 23 lines with `- MORE - `.

## Rebuild

From the repository root, with DISPAK, `besmtool`, NEWPASC on volume 77 and the
usual system volumes on `BESM6_PATH`:

```sh
python3 runtime/corpus.py
python3 runtime/more/build.py
```

The second command first rebuilds `mypas.b6` on a private copy of volume 77.
It then builds a private PERSO library, compiles the Pascal source,
dumps the image, audits its relocated library words, and creates these artifacts:

| Path | Contents |
|---|---|
| `runtime/build/more/more.img` | Complete rebuilt MORE, three zones of six-byte words |
| `runtime/build/more/4001` | Private physical volume with MORE replaced |
| `runtime/build/more/3776` | Private PERSO library |
| `runtime/build/more/77` | Compiler rebuilt with the last-argument-in-A ABI |
| `runtime/build/more/more.lst` | Compiler listing and link map |
| [reconstruction.json](reconstruction.json) | Original ranges, comparison counts and hashes |

The source volume is checked against the corpus hash and remains unchanged.
The installed compiler volume 77 also remains unchanged.
The private volume replaces all three MORE zones, `0034–0036`, because the
newly linked runtime has a different layout. All other physical zones remain
byte identical, including the catalog. No source disk is mounted for writing.
Binary artifacts are regenerated locally and are not intended for Git.

The output retains the original Monitor loader at `02000–02011`, entry at
`02012`, and disk descriptor for unit `66`, zone `0034`. Its stack descriptor
is updated for the new link. Use the private `4001` through the existing Monitor
launch setup with that disk mounted on unit `66`.

## Library selection and compiler compatibility

The private library includes all five recovered COMP file-access modules:
`ERROR`, `DBNAME`/`MKNAME`, `DBFILE`/`OPENF`, `DBPASC`, and `DBCORE`.
`MONIN` and `MONOUT` use COMP's conversion tables. Additional helpers are
recovered from COMP and MORE. The build does not depend on recovering MORE's
older, partly erased versions of these routines.

The build makes these local compatibility adjustments:

- The Monitor entry named `P/EO` tests **EOLN**. It is exported as `P/EL` for
  the current compiler. The existing following EOF entry is exported as `P/EO`.
- The original READLN entry is exported as `READLINE`, and called with the
  historical accumulator/stack convention through an `ASSEMBLER` declaration.
- `P/1` reads the stack descriptor at `02010`, matching MORE's loader.
- `P/1D+46B` is initialized to `100000B`, as in MORE and COMP.

The dump loader declares the commons in the original order: `P/1D` at `02701`,
INPUT at `03020`, OUTPUT at `03056`. Its temporary stop instruction occupies
a loader word that is replaced by the saved Monitor header, so it adds no word
between the application's constant pool and globals.

`mypas.b6` now leaves the last `ASSEMBLER` argument in A and restores M8 after
the call. Earlier arguments remain on the stack, with no frame header; the
callee consumes those arguments and preserves M1–M7. MORE calls COMP's public
entries directly, using their recovered declarations. No call adapters are
needed. The build checks all four calls for the argument in A and M8 restoration.

The compiler also handles ordinary absolute upper-bank variables as literal
addresses instead of confusing `74000B` with an external-symbol index. This
allows `GETWORD` to use an array at `74000B`, with the original `1..1024` bounds
check and indexed load. External file references retain their relocation.

The runtime adjustments affect build-local copies. The reusable recovered library
sources retain their original words.

## Comparison and limits

The final link audit checks 784 COMP file-library words, 98 converter words,
788 Monitor words (including the changed loader-descriptor operand), and 18
additional helper words.
The original source disk hash and every physical zone outside MORE's allocation
are checked after writing the private volume.

The strict application comparison covers all 578 words at their original
addresses, `02012–03113`:

| Part | Words | Result |
|---|---:|---|
| Pascal code, `02012–02515` | 324 | 315 literal matches; nine named runtime relocations |
| Constants and PMD, `02516–02700` | 115 | Bit identical |
| Initial globals and file blocks, `02701–03113` | 139 | Bit identical |

Every local branch target, constant-pool reference, frame offset, source line
number and non-address instruction bit matches. The checker permits changes
only in long address fields that resolve to explicitly named runtime entries;
it does not mask arbitrary address differences. There are **zero mismatches
after those nine runtime relocations**. The exact fields are listed in
`pascal_comparison.runtime_fixups` in [reconstruction.json](reconstruction.json).

The remaining call-site words are `02402`, `02407`, `02412`, `02417`, `02424`,
`02427`, `02451`, `02505`, and `02514`: calls to `MKNAME`, `ERROR`, `P/7A`,
`OPENF`, `P/1`, and `P/PMDSET`. Their targets differ because the current library
has a different layout.

The fidelity source restores the two identical absolute `ACTIVELI` bindings
recorded in the PMD table, uses `S3` plus comment padding for line numbers,
retains the compiler-generated bounds-check thunks, and uses labelled empty
statements to retain the historical packing and otherwise omitted loads/jumps.
The PUTCHAR increment uses the original short BESM sequence with `P/1D+21B`.
Comparison also recovered the terminal-output grouping: CR and LF are both
conditional on EOLN; the terminating NUL is unconditional.

Compilation, application comparison and link audits have succeeded. Interactive
execution of the pager under the Monitor has not been exercised.
