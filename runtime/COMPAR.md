# What compar.b6 adds to runtime recovery

`compar.b6` is a working decompilation of the COMP image at volume 4001,
zones `0315–0324`. It gives source operations and external call sites that help
identify code not named by the original corpus analysis. The extract's SHA-256
is `4a448553b9499d719f770c33e32a0cab200ca718557493e44c067a8df0858d34`.

Run `python3 runtime/compar.py` to reproduce the static comparisons and write
[compar-evidence.json](compar-evidence.json) and [compar.sym](compar.sym).
Addresses and range ends below are octal; ends are exclusive. Word counts are
decimal. These are identification results, not new linkable runtime modules.

## Helpers absent from the Monitor profile

| Helper | COMP range | Words | Source evidence | Binary evidence |
|---|---|---:|---|---|
| `P/STAR` | `06320–06332` | 10 | Assigning characters to packed arrays in `ВВЛЕКСЕМ`, `RDCAR1`, `RDCAR2`, and the `EMPTY` loop | Matches the reviewed SVS `P/STAR` exactly; seven direct user-code calls |
| `P/31` | `06600–06602` | 2 | Nested-frame restore convention | COMP has an accumulator-preserving variant; no direct call from the main user-code region |
| `P/WC` | `06717–06724` | 5 | `write('I':61)` and similar field-width character output | Matches the reviewed mark3 implementation after relocation; three direct user-code calls |
| `P/EQ` equality entry | `06724–06731` | 5 | `A[TKI] <> B[TKJ]`, `A[KI] = B[JJ]`, and related comparisons | Standard word-comparison loop; five direct user-code calls |
| `P/A6` | `06745–06754` | 7 | `ИMЯФ1.ext:5` and other width-qualified ALFA output | Matches the reviewed mark3 implementation after relocation; four direct user-code calls |
| `P/MI` | `07241–07244` | 3 | `K := K * 10 + ord(ЛEKCEMA[i]) - ord('0')` in `GETNUM` | Exactly the three standard `p_mi.madlen` words; call at `04360.R` |

These six entries account for 32 words, before any additional shared entry such
as the ordering comparison after `P/EQ`. They provide a small, concrete next
extension to the library. `P/STAR`, `P/WC`, and `P/A6` already have reviewed code
in other profiles; COMP establishes their use with the Monitor file runtime.

The following code at `06731–06743` is an ordering-comparison entry resembling
standard `P/GE`. Its complete boundary and arithmetic-mode behavior need review
before assigning that public name or treating it as recovered `P/EQ` module data.

The compiler sources explain the dispatch: `prepStore` in `pascompl.cc` selects
`P/STAR` for packed stores; `genComparison` selects `P/EQ` for multiword comparisons;
`checkElementForReadWrite` selects `P/WC`, `P/A6`, and `P/WO` according to type and
field width. `mypas.b6`'s `mcMULTI` expansion selects `P/MI`. A reduced native
compiler probe also emitted named `P/EQ`, `P/WC`, `P/A6`, `P/WO`, and `P/MI`
references. That probe identifies helper selection; it does not reproduce COMP.

### Existing supplemental helpers are corroborated

COMP `P/3` at `06361–06365` matches the four words borrowed from `тестац.bin`.
COMP `P/6A` at `06743–06745` matches the two borrowed words after relocating its
`P/7A` target. COMP `P/WO` at `06754–07036` matches the existing Monitor module.

### P/31 has a real variant

The SVS and mark3 bodies are:

```text
7,MTJ,3; 3,XTA,2
 ,ATI,2; 13,UJ,
```

COMP has:

```text
7,MTJ,3; 3,WTC,2
2,VTM,; 13,UJ,
```

Both restore M3 and M2, but the COMP sequence preserves the accumulator. This
difference must remain explicit when recovering the Monitor version.

## TTIO explains a shared control word

The two source calls are compiled directly into stores to `*TTIO*+3`, address
`06335` in COMP:

| Source | Constant | Instructions |
|---|---|---|
| `TTIO(1C)` in `SRAVN` | `04732 = 1` | `03775.L: 8,XTA,24B`; `03775.R: UTC,06332`; `03776.L: ATX,3` |
| `TTIO(6C)` before `FINITA` | `05407 = 6` | `04672.L: 8,XTA,501B`; `04672.R: UTC,06332`; `04673.L: ATX,3` |

Here the instruction modifier `8` is decimal M10. `mypas.b6`'s standard-procedure
case 29 emits a `UTC` reference to `*TTIO*` followed by the raw instruction `3`,
which is `ATX 3`. This establishes the field used by TTIO without inventing an
additional callable runtime routine. The meanings of its individual flag bits
still require tracing their uses in the file helpers.

## Character-conversion variants become bounded

The failed whole-module matches can now be explained precisely:

- **MONOUT:** COMP `10455–10547` has the same instruction sequence as Monitor
  after relocation. Two table words differ: reference `03214` / COMP `10506`
  changes `0401053141407416` to `0401053141407417`; reference `03217` / COMP
  `10511` changes `0705613303607417` to `0705613303607416`.
- **MONIN:** COMP `10547–10617` has the same code. Its first 24 table words
  (`10556–10606`) equal the reference table (`03264–03314`), followed by eight
  additional words. The `377` mask moves to `10616`, and its code reference moves
  with it. This is a table extension rather than a different conversion loop.
- **Startup:** COMP `P/1` at `10266` uses `WTC 02010`; the current Monitor reference
  uses `WTC 02007`. Its M1 base is `05457`.

The `a4` option in `compar.b6` provides an encoding setting to investigate with
the historical compiler. It is not, by itself, proof of the cause of each table
difference. The first 050 words of `P/1D` also differ at offset `046`: COMP has
`0100000`, while the reference has zero. Its role must be established before
copying the entire initialization table into a new profile.

## Externals are separate recovery targets

| Source name | Entry | Source use |
|---|---|---|
| `E6365` | `06365` | Read a line from the first legacy text stream; Boolean result is treated as EOF |
| `E6444` | `06444` | Initialize that stream for an address passed by reference |
| `E6602` | `06602` | Read a line from the second stream |
| `E6661` | `06661` | Initialize the second stream |
| `E7036` | `07036` | Convert an error code into the text printed by `OШMOH` |
| `E7443` | `07443` | Parse a file specification using library, extension, and destination arguments |
| `E7667` | `07667` | Resolve a file descriptor to a file address, returning a status code |

The two reader/initializer pairs share code and state: `E6444` is an interior
entry in the first reader block, and `E6661` is an interior entry in the second.
They must not be split merely because their source declarations have different
names. The argument lists for `E7036`, `E7443`, and `E7667` are partly commented
out in the decompilation; their exact ABI still needs the original call sequences.

**Source update:** the include at volume 4001 zone `0005` identifies `E7443` as
`MKNAME(VAR PSTRING,ALFA,ALFA,VAR WORD3):INT` and `E7667` as
`OPENF(VAR WORD3,BOOL,VAR INT):INT`. The COPY source at `0006–0007` corroborates
these uses and names `E7036`'s error-formatting operation `ERROR`, although its
formal declaration is not in the include. See [FILE-ACCESS.md](FILE-ACCESS.md)
for the extracted source and argument evidence.

**ERROR disassembly:** [file-access/ERROR.md](file-access/ERROR.md) now separates
the 14 instruction words at `07036–07053` from the 25-entry status/address
table, messages, and masks. Its 131 words match eight images after 31 fixups.
[error.madlen](file-access/error.madlen) preserves the packed pointer table and
original text bytes; the notes explain the observed argument handling.

The source's `RDBUF` is different: it directly constructs an exchange word and
executes `*70`. Its `074000` and `072000` buffers are absolute application
workspace. They should not become runtime commons or runtime module boundaries.

## Recovery order

1. Recover `P/STAR`, `P/WC`, `P/A6`, `P/MI`, and the equality entry of `P/EQ`,
   preserving COMP's actual dependencies and shared-constant offsets. Recover
   the accumulator-preserving `P/31` separately.
2. Keep the startup descriptor and conversion-table differences as explicit
   Monitor variants. Reuse the common instructions and preserve variant data.
3. Recover the paired readers and monitor filename services as separate external
   modules, retaining interior entry points and their application workspace.
4. Rebuild a private copy of the decompilation with the historical NEWPASC and a
   loader map. Use the map to refine boundaries, then compare the selected helper
   words against the original image before making them linkable.

The current source is not a word-for-word reconstruction oracle. For example,
`GЕТСМDLI` ends with `writeln(f)` in the text, while the binary tail-calls `P/RF`
at `02051` (reset); the source also contains commented external arguments and
debugging output in `GETNUM`. A direct attempt with the checked-in native compiler
reported four errors, including its unsupported `a4`/TTIO dialect. The original
deck mounts writable volume 1234 and asks the loader to execute the program;
future compilation must use private scratch volumes and stop after dumping the
image. These limitations do not invalidate the source-to-call correspondences
above, which are checked against the original instructions.
