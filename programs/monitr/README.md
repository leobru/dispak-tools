# МОНИТР recovery

МОНИТР is the command interpreter of the ДВС cross-development Monitor on
volume **4001**. Its Pascal part is the NEWPASC image in catalog zones
**0002–0010** (octal), seven zones loaded from `02000`. Zone 0001, read first
by `ЕВ7`, is recovered separately as the [BEMSH starter](starter.md).
`python3 programs/monitr/build-starter.py` assembles it and runs `ЗОНГП` on a
private disk: all 1024 words match the original zone 0001.

The interpreter reads a command line, recognises `$`-commands and starts any
other name as a program from the current library:

| Command | Procedure | Command | Procedure |
|---|---|---|---|
| `БИБ` | `БИБ` | `НКТ` | `HKT` |
| `АРХ`, `АР`, `А` | `APXИB` | `Н`, `НФ`, `НФА` | `HФ` |
| `КТБ` | `KTБ` | `У`, `УН`, `УНЧ` | `YДAЛ` |
| `КТ`, `КТЛ` | `KATЛ` | `И`, `ИМ`, `ИМЯ` | `ПEPEИM` |
| `О`, `ОТ`, `ОТК` | `OTK` | `ДАЙ` | `ДAЙ` |
| `УСТ`, `УС` | `YCT` | `ЗАК` | `ЗAK` |
| `КНЦ` | ends the job | any other name | `ЗAПYCK` |

## Build

From the repository root:

```sh
python3 programs/monitr/build.py
```

The builder rebuilds the current `mypas.b6` on a private volume 77. It then
assembles a private Monitor library and links `monitr.pas` with PASCODER,
which writes the image to a private disk mounted as drive 044. The exchange
word at `02007` names that drive, and the original was written there. The
builder checks that volumes 4001 and 77 are unchanged. All writable volumes,
decks, listings and images are under `runtime/build/monitr/`. No Monitor
command is executed.

- [monitr.pas](monitr.pas): the source with historical line numbers.
- [monitr.sym](monitr.sym): application, runtime and absolute addresses for
  `disbesm6 -n`.
- [reconstruction.json](reconstruction.json): hashes and the comparison.

`--explore` writes the report under the build directory instead of failing
on differences.

## Comparison

Addresses are octal, word counts decimal.

| Region | Addresses, inclusive | Words | Result |
|---|---|---:|---|
| PASCODER stub | `02000–02011` | 10 | Identical except `02010.L` |
| Pascal code | `02012–04100` | 1079 | Bit identical |
| Constants | `04101–04324` | 148 | Bit identical |
| Globals and files | `04325–04544` | 144 | Bit identical |
| Runtime | `04545–07431` | 1461 | Bit identical |
| Above FREE | `07432–17777` | 4326 | Not reproduced |

**2841 of the 2842 words below FREE match.** Only `02010.L`, a value filled in
by the loader, differs, as in MTD and BOX. Its right half, FREE = `07432`, is
identical. No word is patched after linking.

The 4326 words above FREE belong to no program. They are memory that earlier
jobs left in core when the original image was written: 3293 of them are
non-zero, among them part of the volume 4001 include text for the file-access
library at `10000` and a job deck at `12000`. The rebuilt image has zeros
there.

## Reconstruction details

The image has no PMD tables (`p-`) and no range checks (`t-`). Its options are
`y+,p-,t-,o-`; double quotes select KOI-8 literals. Every identifier is
invented, apart from external entries known from the volume 4001 include
deck (`LIB`, `DLIB`,
`OPENF`, `MAKEF`, `CLOSEF`, `DELF`, `MKNAME`) or from COPY (`FIRSTF`,
`NEXTF`). Absolute variables name the Monitor's shared cells:
- `00003` is the active library;
- `00021` is the library table;
- `00051` is the busy-volume set;
- `00055` is the command line;
- `00073` and `00074` hold the running program's name and flag;
- `76000` and `77000` hold the catalog and its type table.

Comment padding reproduces the line numbers in the code. Blank lines are not
counted by the compiler, so the source has none. In `APXИB`, the
multiplication by 4096 is an exponent addition under `m+`, as mypas.b6 now
compiles `x * 2**k` in either `m` mode.

The constant pool matches only with the original compiler's single constant
table. Its duplicate ALFA constants come from non-transitive comparisons.
mypas.b6 now keeps one table under `(*=O-*)`.

The private library is BOX's (from MTD, COMP and MORE), with these changes:
- `P/EL` is the EOLN entry and `P/EO` the EOF entry, as the compiler names
  them. COMP's renaming is undone.
- COMP's later converter tables and the eight-word MONIN extension are
  restored.
- `P/ER` declares `P/WI` before `P/HT`, so `P/HT` and its `PASPMDAD` common
  are loaded last.
- The file-access bundles gain entries at their original offsets: `LIB`,
  `DLIB`, `SETDESCR`, `RUN`, `MAKEF`, `CLOSEF`, `DELF`, `RENAMEF`, `FIRSTF`,
  `NEXTF`, `SETBUF`, `KOI8`.
- Two services have no recovered source and are taken from the image words:
  - `DBTOM` (`06164`) mounts and releases volumes (`DOZAK`, `OTKAZ`,
    `MONTOM`);
  - `DBLINK` (`07050`) stores the caller's return address in cell `00005`
    (`SVJAZ`).

  Both module names and these entry names are invented.
