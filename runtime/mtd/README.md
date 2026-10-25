# MTD / MTDSK recovery

MTD is a small NEWPASC tape-to-disk copier from volume **4001**, catalog zones
**0047–0050** (octal). Its Pascal program name is `MTDSK`. Both zones survive.
The reconstructed source retains the command-line lexer, numeric input with
operator prompts, tape positioning, block reads, disk writes and confirmation
loop. No copy operation is executed during reconstruction.

## Build

From the repository root:

```sh
python3 runtime/mtd/build.py
```

The builder requires DISPAK, `besmtool` and the installed system volumes. It
rebuilds `mypas.b6` on a private volume 77, assembles a private PERSO library,
compiles the source and lets PASCODER dump the linked image. The private
compiler and library are reused while their source remains unchanged.
Missing MTD, MORE and COMP
reference extracts are obtained from volume 4001 with `besmtool`; existing
extracts must agree with both the corpus hashes and disk words.

Sources:

- [mtd.pas](mtd.pas): source with historical line numbers and instruction packing.
- [mtd-readable.pas](mtd-readable.pas): the same reconstruction without line
  padding, retained for reading and further study.
- [tapeio.madlen](tapeio.madlen): the original 26-word tape service, with explicit
  self relocation and `BSS` for its two zero words.
- [mtd.sym](mtd.sym): original procedure, data and runtime addresses.
- [reconstruction.json](reconstruction.json): source/image hashes and comparison.

The source, listing and image used for comparison are recorded in the report.
All temporary decks, writable volumes, listings and images are under
`runtime/build/mtd/`. Neither the source volume 4001 nor the installed volume 77
is changed; their hashes are checked before and after building. Binary images
and generated disassemblies are build/reference artifacts, not source files.

To compile the readable version while reporting its expected line-number
and layout differences:

```sh
python3 runtime/mtd/build.py --explore --source runtime/mtd/mtd-readable.pas
```

`--explore` writes its report only under the build directory. Run the default
command again to restore the final comparison image and listing.

## Rebuild comparison

All addresses are octal; word counts are decimal. Each word has 48 bits.

| Region | Addresses, inclusive | Words | Result |
|---|---|---:|---|
| Pascal code | `02012–02637` | 406 | Bit identical |
| Constants and PMD | `02640–03075` | 158 | Bit identical |
| Initial globals and files | `03076–03256` | 113 | Bit identical |
| Runtime | `03257–05121` | 931 | Bit identical |
| Trailing allocation padding | `05122–05777` | 430 | Bit identical |

**All 677 application words match literally**, with no runtime relocations
needed. Across both zones, **2047 of 2048 words match**. The only difference is
`02010.L`, a value supplied by the loader. Its right half, the initial stack/free
address `05122`, is identical. The builder does not patch application or runtime
words after linking. It pads the dumped file with zero words to the original
catalog extent and compares every word, including that padding.

The default build rejects any other difference, a changed address in the
reviewed layout, or even a named runtime relocation. The report distinguishes
literal equality from the more permissive relocation comparison available
during reconstruction. Repeated final builds must have identical image hashes.

## Source and library evidence

PMD supplies the names and frame offsets of `ПPOГOH`, `ПOДГOH`, `ПPOБ`,
`COГЛACEH`, `BЛEKC`, `CЛEKC`, `DIGIT`, `DECODE`, `SCANNUM`, `READNUM`,
`READAGRE`, `GETCMDLI`, and the program globals. The unused `CЛEKC` routine is
also restored. Type names and structured labels are reconstructed; `TAPEIO`
and `READLINE` are descriptive aliases for entries `04045` and `03427`.

The four initially unidentified entries are:

| Original address | Identity / convention |
|---|---|
| `03427` | Monitor line input, immediately after `P/RET`; called as FORTRAN |
| `04040` | `P/MI`, integer product completion |
| `04045` | Tape exchange service; ASSEMBLER, final argument in A |
| `04077` | Monitor `P/WO`, octal output |

The source uses `o-` to retain loads after stores, `S3` plus comment padding to
restore line numbers, and empty labels to preserve packing and inhibit tail
calls where the historical code used an ordinary call. Two increments retain
the original `P/1D+21B` instruction sequences. The two-character `- ` prompt is
expressed through a packed two-character type to preserve its exact word.
No compiler change or duplicate variable declaration was needed.

The private library reuses the recovered Monitor modules and the existing
COMP/MORE builders. For MTD it restores the original MONOUT table values,
removes COMP's eight extra MONIN words, and uses MTD's ten-word `P/HT` with a
separate `PASPMDAD` common at `04602`. The P/SYS reference order puts TTIO
before P/PUTERR. A seven-word P/BOOT fixes common ordering: `P/1D` at `03076`,
INPUT at `03163`, OUTPUT at `03221`; the loader allocates its separate
three-word P/CODER block at `02007`.

At the source level MTD reads tape unit 42 into memory page 30, checks the low
five status bits, expects 6144-byte blocks and writes them to disk unit 43 using
`Э70`. A nonzero file number causes rewind and file positioning. The program
prints block diagnostics and asks whether to copy another file. These are
recovered code paths; interactive tape/disk execution has not been exercised.
