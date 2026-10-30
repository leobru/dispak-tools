# MT recovery

MT is the NEWPASC tape-control utility on volume **4001**, catalog zones
**0172–0174** (octal). The application and its runtime survive intact.

## Build

From the repository root:

```sh
python3 programs/mt/build.py
```

The builder rebuilds `mypas.b6` on a private volume 77, assembles the recovered
library into a private PERSO volume, compiles Pascal and dumps the linked image
through PASCODER. It does not execute MT's tape commands. Missing reference
extracts are obtained from volume 4001 with `besmtool` and checked against the
corpus and original disk words. All build artifacts are in `build/mt/`.
Original volume 4001 and installed volume 77 are checked for changes. Private
writable volumes are neither hashed nor included in Git.

- [mt.pas](mt.pas): exact reconstruction with historical source-line padding.
- [mt-readable.pas](mt-readable.pas): the same source without line padding.
- [mt.sym](mt.sym): recovered application and final runtime addresses.
- [reconstruction.json](reconstruction.json): full-image comparison and inputs.
- [variants.json](variants.json): comparison with the uncatalogued MT revision.

The readable source also compiles. Its code layout is unchanged; 33 application
words differ because it omits the original line numbers. To rebuild it:

```sh
python3 programs/mt/build.py --explore --source programs/mt/mt-readable.pas
```

`--explore` keeps the report in the build directory. Run the default command
again to restore the exact comparison image and tracked report.

## Rebuild result

Addresses are octal; word counts are decimal. Each word has 48 bits.

| Region | Inclusive addresses | Words | Result |
|---|---|---:|---|
| Pascal code | `02012–02752` | 481 | Bit identical |
| Constants and PMD | `02753–03237` | 181 | Bit identical |
| Initial globals and files | `03240–03414` | 109 | Bit identical |
| Runtime | `03415–06101` | 1333 | Bit identical |
| Allocation padding | `06102–07777` | 958 | Bit identical |

All **771 application words** match literally, with no runtime fixups.
The complete three-zone image matches in **3071 of 3072 words**. Only the left
half of `02010`, a value supplied by the loader, differs; the right half is the
identical initial stack/free address `06102`. The builder rejects any other
difference. No linked word is patched; a short dump is padded with zero words
to the original catalog extent before comparison.

## Recovered behavior

MT takes an optional `-T device` prefix, followed by a command and optional
decimal repetition count. The default ALFA device name is `MT`. `LIB` must
return status **5**; otherwise MT prints `NO TAPE SPECIFIED` and exits with 1.
It extracts the six-bit device number from the returned descriptor. Unsupported
commands also exit with 1. Recognized commands invoke the tape service with
page **30** and flag **0**, repeat exchanges whose low five result bits equal
4, and print the result in octal. Normal completion exits with 0.

| Command | English alias | Service operation |
|---|---|---:|
| `ЗB` | `FSR` | 2 |
| `ЗH` | `BSR` | 3 |
| `ФB` | `FSF` | 4 |
| `ФH` | `BSF` | 5 |
| `ПH` | `REW` | 6 |
| `TM` | `WTM` | 7 |
| `П8` | `D8` | 8 |
| `П32` | `D32` | 9 |
| `П63` | `D63` | 10 |
| `CT` | `ERG` | 11 |

Command spelling follows the recovered KOI-8 literals, including Latin letters
in mixed Russian spellings. `variants.json` records the actual minimum lengths
passed to `CЛEKC`. The PMD enum also contains `ЗAП` and `ЧT` (operations 0 and 1),
but the command dispatcher does not select them. These behaviors are recovered
from the code; interactive tape execution has not been exercised.

## Source and library evidence

PMD supplies the program name, globals, procedure names, frame offsets and
source-line numbers. The common parser is the one recovered in MTD, with
`GETCMDLI` placed first. The unused confirmation and numeric-input helpers are
retained. `READLINE` and `TAPEIO` are descriptive aliases; `LIB` is identified
by the [DBF include](../../runtime/sources/4001/dbf.inc.b6) in zone `0005`.

MT uses COMP's newer MONOUT tables and eight-word MONIN extension, MTD's
ten-word `P/HT`, and a separate `PASPMDAD` common. Its file-access module differs
from COMP's revision. The original MT services are reconstructed separately:

| Source | Original range | Words |
|---|---|---:|
| [lib.madlen](lib.madlen) | `04203–04621` | 271 |
| [tapeio.madlen](tapeio.madlen) | `04622–04653` | 26 |
| [dbpasc.madlen](dbpasc.madlen) | `05367–05421` | 27 |
| [dbcore.madlen](dbcore.madlen) | `05422–05561` | 96 |

`DBPASC` and `DBCORE` are recovery names. Complete modules, including unused
entry paths and data, are retained. Writable zero cells use `BSS`, and known
text constants use `GOST` or `ISO`. P/BOOT declares commons in their original
order: P/1D, INPUT, OUTPUT. ASSEMBLER calls leave the last argument in A and
restore the caller's constant-pool register afterward. No compiler changes were
needed for MT.

## Uncatalogued revision at 0104

Zones **0104–0105** contain another intact program named `MT`. It has 409 code
words, versus 481 in the catalogued revision. It looks up literal device `MT`
before reading the command line and supports the ten original command names.
The catalogued revision adds `-T device` and ten English aliases. That indicates
a feature extension; neither image provides a build date proving chronology.

[variants.py](variants.py) checks all 282 common parser/file-init words and all
420 words of the four service modules against the independently linked image.
They agree after consistent address relocation; numeric operands and indexed
offsets must agree exactly. The comparison also extracts the command literals
and minimum lengths from the actual calls. The uncatalogued revision is used
as supporting evidence; the rebuilt target is the catalogued `0172` revision.

```sh
python3 programs/mt/variants.py
```
