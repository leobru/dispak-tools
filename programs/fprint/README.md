# FPRINT recovery

FPRINT is the Pascal line-printer utility in volume **4001**, catalog zones
**0063–0065** (octal). Its PMD names the program **PRINTFIL**. The application,
conversion tables and runtime survive intact.

## Build

From the repository root:

```sh
python3 programs/fprint/build.py
```

The builder recompiles `mypas.b6` on a private volume 77, assembles a private
PERSO library and compiles the recovered Pascal. PASCODER dumps the linked
image to private volume 3777, zones `0063–0065`, preserving the original
loader's output-zone field. All three zones are compared word by word.
FPRINT's file and printer operations are not executed by the build.

Missing reference extracts for FPRINT, MORE and COMP are obtained from volume
4001 with `besmtool` and checked against the corpus and source disk words.
The build uses the same DISPAK, system volumes and `BESM6_PATH` setup as the
other recovered utilities. Artifacts remain under `build/fprint/`.
Original volume 4001 and installed volume 77 are checked for changes. Private
writable volumes are neither hashed nor included in Git.

- [fprint.pas](fprint.pas): exact reconstruction with historical line padding.
- [fprint-readable.pas](fprint-readable.pas): source without line padding.
- [fprint.sym](fprint.sym): application and runtime symbols.
- [reconstruction.json](reconstruction.json): full comparison and build inputs.
- [exercise.py](exercise.py): disk-reading and printer-output emulator scenarios.
- [execution.json](execution.json): results for the original and rebuilt images.
- [KOI-8 overstrikes](overstrikes.md): both printer glyphs for all 59 input codes
  requiring a second printing pass.

## File reading and printer execution

After building, run:

```sh
python3 programs/fprint/exercise.py
```

All **22 emulator runs passed**: eleven scenarios on each image. Original and
rebuilt FPRINT produced **byte-identical raw printer streams and decoded text**
in every scenario. Both input images remained unchanged.

| Scenario | Verified behavior |
|---|---|
| Empty command | Usage text and return through Monitor address `00002` |
| Missing file | `OPENF` status `010`, decoded error and return |
| Empty file | Real zone read; no text printed |
| NUL and EOT | Each terminates input; subsequent bytes are ignored |
| TAB and CR | Eight-position tab stops; CR ignored |
| Form feed | Second logical page starts at printer column 63 |
| Long line | Wrap after 63 characters, preserving the overflow character |
| 150 numbered lines | Two sheets, two input zones, exact rows and columns |
| Backspace | Overprinting retains both characters at the same position |
| Letter conversion | Conversion and secondary printing pass |

The test creates a private Monitor library `TEST`, containing a TXT file
named `123`, on private disk 1234. It supplies the shared Monitor cells and
command line, loads all three program zones from private disk 1235, and enters
the original PASCODER loader at `02000`. No application or runtime word is
patched: `MKNAME`, `OPENF`, zone reads and printer extracodes execute normally.
The `KEYE72` exit handler only saves the final buffer/globals and ends the test
job. This exercises FPRINT itself; the interactive МОНИТР command loop is not
part of the harness.

DISPAK runs with `-x`, using the supervisor's printer extracode, and a private
`HOME`, following the `run-dispak.sh` launcher pattern. This keeps its input
queue inside the writable build directory. `BESM6_PATH` retains access to the
installed system disks. Each run saves `input.txt`, `job.b6`, `trace.txt`,
`print.raw`, `print.txt`, independently decoded `decoded.txt`, and a memory
snapshot under `build/fprint/exercise/{original,rebuilt}/<scenario>/`.
The checks verify the actual input-zone sequence, image-loader reads, printer
call count, exit status, and exact printed rows/columns. Raw output is decoded
again with DISPAK and compared byte for byte with its original text output.
Private writable disk images are not hashed.

One historical printing detail is observable in both images: EOF reached in
the left column leaves its blank tail to column 128. The supervisor printer's
line wrap adds blank rows before processing the explicit line-feed markers.
The numeric left-column fixtures produce 137 physical rows for 69 logical
rows; filling the right column produces 69. Letter and backspace overprinting
can add further passes in the decoded listing. The tests preserve and check
these effects.

The readable source also compiles. Its layout, initialized data and runtime
are unchanged; **77 application words** differ only in source-line numbers
in PMD and checks. To rebuild it:

```sh
python3 programs/fprint/build.py --explore --source programs/fprint/fprint-readable.pas
```

`--explore` keeps its report in the build directory. Run the default command
again to restore the exact image and tracked report.

## Rebuild result

Addresses are octal; word counts are decimal. Each word has 48 bits.

| Region | Inclusive addresses | Words | Result |
|---|---|---:|---|
| Pascal code | `02012–03406` | 765 | Bit identical |
| Constants and PMD | `03407–04026` | 272 | Bit identical |
| Initial globals and files | `04027–04404` | 238 | Bit identical |
| Runtime | `04405–07411` | 1541 | Bit identical |
| Allocation padding | `07412–07777` | 246 | Bit identical |

All **1275 application words** and the complete runtime match literally,
without address tolerances or patched linked words. The complete image
matches in **3071 of 3072 words**. Only `02010.L`, the loader's symbol-table
length field, differs. The right half retains the initial stack/free address
**07412**. The builder rejects every other difference.

## Recovered behavior

The program takes the first filename from the Monitor command line, resolves
it with `MKNAME` using the active library and default extension `TXT`, and
opens it with `OPENF`. File-library errors are decoded by `ERROR` and printed
before returning to Monitor through address `00002`. An empty command line
prints `USAGE: FPRINT <FILE> [-<OPTIONS>]` and returns.

The surviving main body reads only the filename. Although the usage message
mentions options, this image does not parse them. The common lexical, numeric
input and confirmation routines remain present but are unused by the main
printing path.

The initialized defaults are two logical pages per sheet, starting at columns
0 and 63. Each page accepts 63 character positions and 69 lines (indices
`0..62` and `0..68`). The working sheet at **30000** is an unpacked character
array `[0..70,0..128]`, occupying 9159 words. The packed output buffer at
**52000** holds up to 40000 bytes. Input is read by zone into **74000**, then
split into six bytes per BESM-6 word, with an eight-character pushback buffer.

| Input character | Action in `FILLPAGE` |
|---|---|
| NUL or EOT (`000`, `004`) | Mark the end of the source |
| Backspace (`010`) | Move one position left when possible |
| Tab (`011`) | Advance to the next multiple of eight, wrapping if necessary |
| Line feed (`012`) | Start a new line |
| Form feed (`014`) | Finish the current logical page |
| Carriage return (`015`) | Leave the position unchanged |
| Other character | Store it, wrapping when the column limit is exceeded |

Several characters in one sheet cell are retained as packed overstrikes.
`XLAT` scans each line, translates through `CODETAB`, and emits a second pass
when a character needs the additional glyph from `CODETAB1`. The two tables
cover input bytes `32..255` and occupy 38 words each at `04171` and `04237`.
`PRINTSHE` sends the packed output through Э64; three small FORTRAN-callable
wrappers perform the additional Э64 operations before and after each sheet.

These behaviors are recovered from the source and identical machine code.
The rebuild verifies compilation and image identity; file reading and printer
output have not been exercised interactively.

## Source and runtime evidence

PMD supplies procedure names, nesting, local/global offsets and source-line
numbers. `DIGIT` and `DECODE` are nested in `SCANNUM`; `PUTC` is nested in
`XLAT`, and `NEWLINE` is nested in `FILLPAGE`. `S3` resets and comment padding
restore all PMD and check-line values, including program end line 335.
The options `B1` and `S7` reproduce the file initialization and unchecked
pointer accesses. `O-` retains loads after stores.

| Entry | Address | Role |
|---|---|---|
| `ПРОГОН`, `ПОДГОН`, `ПРОБ` | `02013`, `02031`, `02047` | Common parser |
| `BЛEKC`, `CЛEKC` | `02100`, `02145` | Lexeme extraction and comparison |
| `SCANNUM` | `02276` | Numeric input with nested digit helpers |
| `GETCMDLI` | `02372` | Copy the command line to Pascal text |
| `GETWORD`, `UNGETCH`, `GETCH` | `02431`, `02464`, `02506` | Input and pushback |
| `INITSHEE` | `02540` | Clear the sheet and install line terminators |
| `XLAT` | `02643` | Translate and pack printer output |
| `PRINTSHE` | `03021` | Issue the buffer's Э64 operation |
| `FILLPAGE` | `03062` | Fill one logical page |
| `FORMATSH` | `03173` | Fill the logical pages of a sheet |
| `INIT` | `03227` | Initialize printing defaults |
| Main body | `03272` | Resolve the file and print sheets |

The builder reuses MTD's Monitor runtime. `P/WO` precedes the character
constants in the external-name list, and `PASPMDAD` is the separate common at
**07072**, immediately after `DBCORE`. Six Madlen sources preserve the
additional printer wrappers and this image's earlier file-access library:

| Source | Module | Original inclusive range | Words |
|---|---|---|---:|
| [printer.madlen](printer.madlen) | `PRINTER` | `05222–05233` | 10 |
| [mkname.madlen](mkname.madlen) | `MKNAME` | `05234–05417` | 116 |
| [error.madlen](error.madlen) | `ERROR` | `05420–05610` | 121 |
| [lib.madlen](lib.madlen) | `LIB`, entry `OPENF` | `05611–06205` | 253 |
| [dbpasc.madlen](dbpasc.madlen) | `DBPASC` | `06662–06734` | 43 |
| [dbcore.madlen](dbcore.madlen) | `DBCORE` | `06735–07071` | 93 |

The library names `MKNAME`, `OPENF` and `ERROR` follow their interfaces and
identified file-service roles. `DB*`, `PRINTER`, `READLINE`, `E64ONE`, `E64TEXT`, `E64ZERO`
and assembler labels are recovery names. Stored instruction templates retain
symbolic references; writable zero cells use `BSS`. Lowercase KOI-7 bytes in
the error messages use quoted octal ISO escapes so Madlen does not uppercase
them while assembling the source.
