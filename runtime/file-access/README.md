# ERROR, MKNAME, and OPENF: recovered Madlen

The include at volume 4001 zone `0005` identifies COMP's entries `07443` as
`MKNAME` and `07667` as `OPENF`. These cards reconstruct COMP's revision from
independently linked copies, including the code and pools before and after the
public entries. The original Madlen labels and comments have not survived.

## Sources and boundaries

| Source | Module | COMP range, inclusive | Words | Relocations | Complete matching copies |
|---|---|---|---:|---:|---:|
| [error.madlen](error.madlen) | `ERROR` | `07036–07240` | 131 | 31 | 8 |
| [mkname.madlen](mkname.madlen) | `DBNAME`, entry `MKNAME` at offset `0177` | `07244–07635` | 250 | 55 | 8 |
| [openf.madlen](openf.madlen) | `DBFILE`, entry `OPENF` at offset `0031` | `07636–10265` | 280 | 80 | 4 |
| [dbpasc.madlen](dbpasc.madlen) | `DBPASC`, entries `DBENTER`, `DBLEAVE` | `20002–20034` | 27 | 3 | 15 |
| [dbcore.madlen](dbcore.madlen) | `DBCORE` | `20035–20174` | 96 | 39 | 11 |

Counts are decimal; addresses and offsets are octal. The five modules contain
784 words and 208 relocation fields. `DB*` names are recovery names.
`ERROR`, `MKNAME`, `OPENF`, `MONOUT`, and `MONIN` have source-backed identities here.
[ERROR.md](ERROR.md) explains the disassembly and decodes its 25 messages.
It also compares the smaller FPRINT equivalent and the incomplete MORE copy;
`python3 runtime/error-variants.py` regenerates that comparison.

The M8 base loaded at each public entry establishes the start of its larger
bundle. Other entries and mutable state share that base, so cutting the source
at `MKNAME` or `OPENF` would omit required code and data. Their other public
names are not assigned speculatively. These boundaries describe recovered
linkable bundles; they do not prove the original object-module partition.

`DBPASC` saves/restores the Pascal call frame and converts the status in M2 to
a Pascal integer result. `DBCORE` supplies shared lookup, name conversion,
catalog I/O, and character extraction helpers. Its conversion exits require
`MONOUT` and `MONIN`. A program must link converters appropriate to its image;
the Monitor and COMP converter tables have known differences.

## Located entries

All 34 workspace `.bin` inputs were scanned: the 26 volume extracts, four root
images, and four `arfa` images. Matches were found only in volume 4001 extracts.
The scan inventories paths and SHA256 hashes in [relocations.json](relocations.json).

| Image on 4001 | MKNAME loaded entry | OPENF loaded entry |
|---|---|---|
| `0002-monitr-pascal` | `06655` | `05547` |
| `0016-tar` | `07717` * | `10144` * |
| `0023-kanal` | `06402` * | `05622` * |
| `0030-proz` | `07041` | `06254` * |
| `0034-more` | `03601` * | — |
| `0037-kermit` | `14142` | `13336` |
| `0051-print` | `07336` | `06170` * |
| `0063-fprint` | `05234` * | — |
| `0070-tartar` | `07525` * | `07752` * |
| `0075-recod` | `06122` | `04717` |
| `0101-mtcopy` | — | `04642` * |
| `0104-orphan-0104` | — | `04106` * |
| `0106-copy` | `04336` * | `04561` * |
| `0132-acc3` | `25663` | `26107` * |
| `0172-mt` | — | `04234` * |
| `0215-acc2` | `24612` | `25036` * |
| `0315-comp` | `07443` | `07667` |

An asterisk marks an entry-fingerprint candidate with a different surrounding
bundle, not a complete COMP match. The twelve-word instruction fingerprint
includes argument handling and status logic, but does not establish that the
whole function has identical semantics. These revisions have not been emitted
as additional Madlen variants. A dash means no matching entry fingerprint.

ACC3 and ACC2 store these blocks `06000` words above their loaded addresses:
for example ACC3's `MKNAME` occurs at file offset plus `02000` = `33663`,
but its loaded entry is `25663` and its encoded base is `25464`. The JSON keeps
file positions separate from loaded addresses. Candidate entries in this table
use the same translation established by their matching shared helper blocks.

## Relocation evidence

Fingerprint masking is used only to locate candidates. A complete match requires:

1. Identical data words and instruction bits outside long address fields in
   explicitly reviewed code ranges.
2. Consistent mappings for every repeated target and one translation for all
   internal addresses.
3. Exact reconstruction of every word using the measured changed fields.
4. Shared-module targets resolving to independently matched bundles in the
   same image, using their loaded addresses.

Every relocation has at least one independently placed witness. For example:

| COMP field | COMP value | MONITR value | KERMIT value | Symbolic operand |
|---|---|---|---|---|
| `07443.L` | `07244` | `06456` | `13743` | local bundle base |
| `07443.R` | `20002` | `07101` | `15776` | `DBENTER` |
| `07446.R` | `07573` | `07005` | `14272` | local parser |
| `07667.L` | `07636` | `05516` | `13305` | local file bundle base |
| `07671.R` | `07731` | `05611` | `13400` | local helper |

The four MKNAME/OPENF support bundles have 177 fixups in long instructions.
ERROR adds six long instruction fixups and 25 data-pointer fixups. All use
15-bit fields; no short instruction relocation was required. M8-relative offsets,
including branch targets such as `0324`, remain numeric and unchanged.
`MKNAME`'s file-type names at `07523–07541` are emitted as six-byte `ISO`
literals, with octal escapes preserving high-bit characters and implicit space padding.
The words `0160340701603407` in `DBFILE` and `DBCORE` use `GOST,6H777777`.
`DBFILE`'s word `1242547515620060` at `10175` uses `GOST,6HКЛЮЧАР`.
Zero-valued writable cells use `BSS`: `DBNAME` reserves six words at `07373`
and two at `07404`, `DBPASC` reserves four at `20031`, and `DBCORE` reserves
one each at `20060` and `20173`. Reservations split at any interior labels;
all word offsets remain unchanged. The two zero constants in `DBNAME`'s
type-code table at `07556–07557` remain `LOG` values.
Other tables, instruction templates, initialized cells, and masks use compact
octal `LOG` words. In particular `20066 = 76000` is a fixed buffer-address word,
not a relocation inferred from its numerical value.

`20175` is excluded from `DBCORE`: the exit at `20174` already ends the bundle,
and several other images put the next module at the corresponding `20175`
position. Including COMP's zero at that address falsely reports a difference.

## Regenerate and assemble

From the repository root, with binary extracts present:

```sh
python3 runtime/file-access.py
python3 runtime/file-access.py --assemble
```

The first command regenerates the five Madlen files and relocation evidence.
The second assembles and links them using DISPAK/Madlen and PASCODER, dumps
the private linked image, and compares every recovered word and public entry
after relocation. Its artifacts are confined to `runtime/build/file-access/`.
Volumes 2113, 77, 2148, and 2048 are mounted read-only; writable scratch volumes
3776 and 3777 are private. DISPAK also needs access to its normal input queue.

The assembly deck supplies return-only `MONOUT`/`MONIN` stubs and a halt-only
`PROGRAM`. It never calls the recovered API. Thus this establishes assembly,
packing, and relocation fidelity, without claiming functional file-access
execution. [assembly.json](assembly.json) records the resulting placement.
The existing report predates the ERROR addition and covers the first four
recovered modules; ERROR's current evidence is documented in [ERROR.md](ERROR.md).
