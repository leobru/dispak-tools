# File-access library sources on volume 4001

The source records at `0005–0007` supply names and declarations for the file
services used by COMP. They are separate from Pascal's `P/...` runtime helpers.

## Extracted files

| Zones | Saved source | Contents |
|---|---|---|
| `0005` | [dbf.inc.b6](sources/4001/dbf.inc.b6) | 60-line include deck for the ДБ file-access library |
| `0006–0007` | [copy.b6](sources/4001/copy.b6) | 432-line COPY deck, including macro definitions and a version banner dated 08.02.89 |

Regenerate them with:

```sh
python3 runtime/volume-sources.py
python3 runtime/compar.py
```

[sources.json](sources/4001/sources.json) records the volume and extract hashes
and every source line's disk location. The COPY deck ends with `*END FILE` at
`0007.0704`; the first word after it is `0007.0706`. The 173 following records
are an exact duplicate of COPY source lines 136–308. They are inventoried as
trailing data and are not appended to the extracted deck.

The files expand COSY space runs, decode KOI-7 to UTF-8, and remove right-hand
line padding. Original control bytes `026` and `031` are retained in `copy.b6`,
including the macro definitions. No syntax or spelling has been modernized.

## Names and signatures for COMP

The include defines:

```pascal
PSTR_LEN = 84;
WORD3 = RECORD
  TИПФ: ALFA;
  NL: ALFA;
  NF: ALFA;
END;
PSTRING = PACKED ARRAY [1..PSTR_LEN] OF CHAR;
```

This matches the layout of `compar.b6`'s `filedesc`: extension/type, library
name, file name, in that order. The include supplies the following identities:

| COMP entry | Library name | Formal parameters | Result |
|---|---|---|---|
| `07443` / `E7443` | `MKNAME` | `VAR PSTRING`, `ALFA` library, `ALFA` extension, `VAR WORD3` result | `INT` status |
| `07667` / `E7667` | `OPENF` | `VAR WORD3`, `BOOL` access, `VAR INT` descriptor | `INT` status |

COMP's instructions corroborate the declarations: the `MKNAME` call at
`04447.R` supplies four arguments (string address, two ALFA values, descriptor
address). `OPENF` at `04526.R` supplies a descriptor address, a zero value, and
an output address. COPY calls `OPENF(NAME,FALSE,DR)` for reading and
`OPENF(NAME_W,TRUE,DW)` for writing. This resolves the integer placeholder for
the second parameter in the COMP decompilation to Boolean access mode.

COPY's `OШMOH` calls `ERROR(KO,TOШ)` and prints the resulting `PSTRING`, matching
COMP's wrapper around `E7036` at `07036`. This supplies the source name `ERROR`;
its declaration is absent from the include, so a complete formal signature
cannot yet be quoted from this material.

[compar.sym](compar.sym) retains the address-based names and adds `MKNAME`,
`OPENF`, and the source-backed `ERROR` alias. [compar-evidence.json](compar-evidence.json)
records the declarations separately from the inferred ERROR interface.

## Wider API

Zone 5 declares `LIB`, `DLIB`, `OPENF`, `MAKEF`, `CLOSEF`, `DELF`, `MKNAME`,
`ДOЗAK`, `APAGE`, `PSWRD`, and `OTKAЗ`. The COPY source adds declarations for
`FIRSTF(VAR PSTRING,ALFA,ALFA,VAR WORD3):INT` and
`NEXTF(VAR WORD3):INT`, plus external `PASBIND(VAR TEXT)`.

These names give concrete targets for the remaining file-service modules.
The declarations alone do not locate every routine in COMP or prove that
COPY's library revision is byte-identical to COMP's.

## Recovered MKNAME and OPENF code

[file-access/README.md](file-access/README.md) locates the entry fingerprints
in 14 and 15 images respectively and separates the different revisions.
COMP's complete `MKNAME` bundle matches eight images after 55 relocations;
its `OPENF` bundle matches four after 80 relocations. Four reconstructed Madlen
modules include their shared Pascal bridge and file helpers, totaling 653 words
and 177 empirically witnessed relocation fields. The additional
[ERROR disassembly](file-access/ERROR.md) contributes 131 words, including its
25-message table, and 31 relocation fields. Run
`python3 runtime/file-access.py` to regenerate the sources and evidence.

## Descriptor and status evidence from COPY

COPY uses returned descriptors as follows:

- `descriptor DIV 1000000B` gives file length: `1000000B` is 2^18.
- `descriptor MOD 10000B` gives the zone shown in copy progress: `10000B` is 2^12.
- Its exchange-word construction retains the low 18 descriptor bits, adds the
  I/O fields, and advances the descriptor by one for each zone.

The source establishes these status cases without guessing error-table text:

| Call | Status | Source handling |
|---|---:|---|
| `LIB` | 5 | Comment says no logical library name; this case is tolerated |
| `OPENF` on destination | 13 | Reports a damaged destination catalog and offers initialization |
| `MAKEF` | 11 | Treats destination as already existing, opens it, and checks its length |

COPY also shows how `FIRSTF`/`NEXTF` iterate matching files and how `MKNAME`
parses the destination. Its `POCПИCЬ` routine writes catalog data directly;
the extracted deck has not been executed.

## Effect on recovery

Use these formal declarations when restoring the argument lists in a working
copy of `compar.b6`. Recover `MKNAME` and `OPENF` under their source names,
retaining the COMP instruction sequences and relocation evidence. Recover the
remaining file services independently of the Pascal helper library. The COPY
program supplies source-level examples for read/write access, allocation,
iteration, and status handling once those modules are ready to execute.
