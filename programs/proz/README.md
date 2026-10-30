# ПРОЗ recovery

ПРОЗ is the interactive file viewer and editor in volume **4001**, catalog
zones **0030–0033** (octal). Its Pascal application, PMD and runtime survive
intact. The recovered banner reads `<?> ЭТО ХИТРЫЙ ПРОЗ. ВЕР ??.?? <?>`;
the question marks are present in the original image.

## Build

From the repository root:

```sh
python3 programs/proz/build.py
```

The builder recompiles `mypas.b6` on a private volume 77, assembles a private
PERSO library and compiles Pascal. PASCODER writes the linked image to private
volume 3777; the builder compares all four zones with the original extract.
It does not execute ПРОЗ's file viewing or editing operations. Original volume
4001 and installed volume 77 are checked for changes. Private writable volumes
are neither hashed nor included in Git.

Missing reference images for ПРОЗ, MORE and COMP are extracted from volume
4001 with `besmtool` and checked against the corpus and source disk words.
The build uses the same DISPAK, system disks and `BESM6_PATH` setup as the
other recovered programs. All temporary files are in `runtime/build/proz/`.

- [proz.pas](proz.pas): exact reconstruction with historical line numbers.
- [proz-readable.pas](proz-readable.pas): source without line padding.
- [proz.sym](proz.sym): recovered application and runtime addresses.
- [reconstruction.json](reconstruction.json): full comparison and build inputs.

The readable source also compiles. Its code layout, initial globals and
runtime are unchanged; 86 application words differ only in source-line numbers
in bounds checks, procedure entry checks and PMD. Rebuild it with:

```sh
python3 programs/proz/build.py --explore --source programs/proz/proz-readable.pas
```

`--explore` writes its report only in the build directory. Run the default
command again to restore the exact image and tracked report.

## Rebuild result

Addresses are octal; word counts are decimal. A BESM-6 word has 48 bits.

| Region | Inclusive addresses | Words | Result |
|---|---|---:|---|
| Pascal code | `02012–04075` | 1076 | Bit identical |
| Constants and PMD | `04076–04632` | 349 | Bit identical |
| Initial globals and files | `04633–05057` | 149 | Bit identical |
| Runtime | `05060–10334` | 1709 | Bit identical |
| Allocation padding | `10335–11777` | 803 | Bit identical |

All **1574 application words** match literally, with no runtime fixups.
The complete image matches in **4095 of 4096 words**. Only `02010.L`, the
loader's symbol-table length field, differs. The right half retains the
identical initial stack/free address **10335**. The builder rejects any other
difference. No linked instructions or constants are patched.

## Recovered behavior

The program resolves the active library from cell `00003`, takes a file name
from the command line at `00055` or prompts for it, and uses `MKNAME` and
`OPENF` to obtain its descriptor. The default file extension is `КОД`.
It prints the descriptor and asks for a hexadecimal base address before
entering the `ВЫДАТЬ-` command loop.

| Input at `ВЫДАТЬ-` | Action |
|---|---|
| Hexadecimal address or `first-last` | Display the requested range |
| Empty line | Continue displaying from the current address |
| `К` | Select the decoded code view |
| `Ш` | Select hexadecimal bytes and character view |
| `ЗАМ` | Replace a word, one half or text |
| `ЗАП` | Write the currently loaded zone |
| `КНЦ` | Terminate through Э74 |
| `A.` | Toggle TTIO mode mask `1` |
| `V.` | Toggle TTIO mode mask `2` |

The command spellings follow the original mixed Latin/Cyrillic KOI-8
literals. Numeric input is hexadecimal except for backslash character
escapes, which accept up to three octal digits. Cyrillic lookalikes of
`B`, `C`, `D` and `F` are converted before numeric decoding. The original
decimal digit predicate accepts its upper boundary; that behavior is retained.

The program uses a zone buffer at **74000**. Each displayed logical word
occupies two BESM-6 words, with a 32-bit payload at the top of each word.
The code view splits a payload into 4, 8, 8 and 12-bit fields; when the
8-bit operation field differs from octal `77`, the last two fields are
displayed together as a 20-bit address. The hexadecimal view prints four
bytes from each half and eight characters in total. Six additional bits of
the first buffer word are printed as flags.

For replacement, an address without a suffix selects the full logical word;
`Л` and `П` select its left and right halves. A replacement beginning with
`T` selects text input; backslash escapes permit character codes. The
file-relative address selects zone `address div 512` and buffer position
`address * 2 mod 1024`. Edits change the buffer; the explicit `ЗАП` command
writes it. The original range checks and numeric limits are retained.

These behaviors are recovered from the code. The comparison verifies
compilation and image identity; interactive viewing and editing have not
been exercised.

## Source and library evidence

PMD supplies procedure names, nesting, local/global offsets and source-line
numbers. The parser shares the routines already recovered in MTD and MT.
The names `descriptor`, `view`, `READLINE`, record fields and numeric labels
are reconstruction choices. The source retains the unused `READAGRE` and
confirmation helpers because their code and PMD are present in the image.

| Entry | Address | Role |
|---|---|---|
| `GETCMDLI` | `02013` | Copy the command line to a Pascal text file |
| `WRITEERR` | `02052` | Decode a file-library status and print it |
| `DIGIT`, `DECODE`, `SCANNUM` | `02270`, `02343`, `02404` | Numeric input |
| `ЗПЗ`, `ЧТ`, `ЗАПИСЬ` | `02477`, `02524`, `02551` | Zone writes, reads and flush |
| `WRITECOD`, `WRITEHEX`, `WRITECHA` | `02564`, `02637`, `02670` | Nested output views |
| `ПЕЧСЛОВО` | `02731` | Display a logical word |
| `BBOД64`, `ЗАМЕНА` | `03047`, `03137` | Recursive numeric input and replacement |
| `СМЕАЦП`, `СМЕЭКР` | `03553`, `03565` | TTIO mode toggles |
| Main body | `03611` | File selection and command loop |

The private library reuses MT's Monitor/file-access sources, COMP's newer
conversion tables and MONIN extension. `OPENF` is exposed at offset `31`
in `LIB`; `P/WH` is exposed at offset `1` in `P/WO`. The display-restoration
helper at `06221` has the same two words as COMP's `P/31`.

Three extra Madlen sources complete the runtime:

| Source | Original range | Words | Origin |
|---|---|---:|---|
| [p_ldarin.madlen](p_ldarin.madlen) | `06115–06124` | 8 | Standard libpas packed-array reader |
| [p_4.madlen](p_4.madlen) | `06215–06220` | 4 | Standard libpas level-4 frame entry |
| [p_a7.madlen](p_a7.madlen) | `10325–10334` | 8 | ПРОЗ's character-array output revision |

`P/A7` restores M7 from `P/1D+3` before transferring to `P/7AD` when the
requested width equals the array length. The older module reused by MT
branches directly and is two words shorter. This difference is preserved.

Two compiler changes are required: the `HEX` output specifier selects `P/WH`,
and compatibility mode `Y+` accepts another declaration part after a routine
body. Placing `BUFFER` and `TTIO` after `GETCMDLI` reproduces the constant
table and external-name order. `S3` resets and comment padding in `proz.pas`
restore all historical PMD and check-line values, including program end 545.
