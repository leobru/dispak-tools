# Monitor runtime modules

The 878 words recovered from `test.bin` are split into 31 Madlen modules.
The six additional words recovered from `тестац.bin` are in `p_3.madlen` and
`p_6a.madlen`. All addresses below are octal; range ends are exclusive.

The grouping follows the standard Pascal runtime library (`libpas` in the
BESM-6 toolchain): frame routines, file helpers, formatting, diagnostics and
character conversion. Standard multi-entry groups remain together:
`P/EF` with `P/E`, `P/7A` with `P/7AD`, `P/HIDE` with `P/EDIH`,
`P/WX` with `P/WXD`, `P/WR` with `PASTENS`, and `PASPMD` with `P/PMDSET`.

This is a source organization for the recovered Monitor variant. It does not
establish the original object boundaries. `MONOUT`, `MONIN`, `PASCHARS` and
`PASWRCHR` are recovery names. The file helpers share one `P/SYS` module, as in
the standard library; their Monitor instructions and tables remain unchanged.

| Source | Module | Original range | Contents |
|---|---|---|---|
| [p_2.madlen](p_2.madlen) | `P/2` | `02310–02314` | Level-2 frame entry |
| [p_sc.madlen](p_sc.madlen) | `P/SC` | `02314–02330` | Stack checks and diagnostic text |
| [p_sys.madlen](p_sys.madlen) | `P/SYS` | `02330–02663` | Monitor file helpers: P/CO, P/TF, P/RF, P/IT, P/RET, P/PF, P/WOLN, P/WL, P/GF, P/EO |
| [p_da.madlen](p_da.madlen) | `P/DA` | `02663–02676` | Range-error diagnostic |
| [p_08.madlen](p_08.madlen) | `P/08` | `02676–02725` | Packed-character descriptor and masks |
| [p_ldar.madlen](p_ldar.madlen) | `P/LDAR` | `02725–02735` | Packed-array element access |
| [p_cw.madlen](p_cw.madlen) | `P/CW` | `02735–02737` | Character output |
| [p_ef.madlen](p_ef.madlen) | `P/EF` | `02737–02745` | Frame exit, including P/E |
| [ttio.madlen](ttio.madlen) | `*TTIO*` | `02745–02774` | Shared Monitor file state and constants |
| [p_1.madlen](p_1.madlen) | `P/1` | `02774–03002` | Runtime startup, P/LV alias, and P/1D initialization |
| [paspmd.madlen](paspmd.madlen) | `PASPMD` | `03002–03150` | Post-mortem dump, including P/PMDSET |
| [p_er.madlen](p_er.madlen) | `P/ER` | `03150–03162` | Error reporting and PASCELUP stack-limit word |
| [stop.madlen](stop.madlen) | `STOP*` | `03162–03163` | Termination extracode |
| [monout.madlen](monout.madlen) | `MONOUT` | `03163–03255` | Monitor output conversion and table (recovery name) |
| [monin.madlen](monin.madlen) | `MONIN` | `03255–03315` | Monitor input conversion and table (recovery name) |
| [p_print.madlen](p_print.madlen) | `P/PRINT` | `03315–03334` | ETX-terminated diagnostic text |
| [p_wo.madlen](p_wo.madlen) | `P/WO` | `03334–03416` | Octal/hexadecimal formatting and tables |
| [paschars.madlen](paschars.madlen) | `PASCHARS` | `03416–03421` | Shared PASZERO*, PASMINS*, SPACE* words (recovery grouping) |
| [p_puterr.madlen](p_puterr.madlen) | `P/PUTERR` | `03421–03422` | Monitor output callback stub |
| [p_7a.madlen](p_7a.madlen) | `P/7A` | `03422–03437` | ALFA/string output, including P/7AD |
| [p_wi.madlen](p_wi.madlen) | `P/WI` | `03437–03520` | Integer output |
| [p_ht.madlen](p_ht.madlen) | `P/HT` | `03520–03533` | HALT and PASPMDAD callback word |
| [p_wx.madlen](p_wx.madlen) | `P/WX` | `03533–03560` | Word output, including P/WXD |
| [p_wr.madlen](p_wr.madlen) | `P/WR` | `03560–03772` | Real output, including PASTENS |
| [p_sp.madlen](p_sp.madlen) | `P/SP` | `03772–04000` | Output padding |
| [p_hide.madlen](p_hide.madlen) | `P/HIDE` | `04000–04006` | Register save/restore, including P/EDIH |
| [p_rc.madlen](p_rc.madlen) | `P/RC` | `04006–04024` | Frame cleanup |
| [pasisoxt.madlen](pasisoxt.madlen) | `PASISOXT` | `04024–04053` | Internal-character conversion and table |
| [paswrchr.madlen](paswrchr.madlen) | `PASWRCHR` | `04053–04055` | PASPERID and PASPLUS* words (recovery grouping) |
| [p_tr.madlen](p_tr.madlen) | `P/TR` | `04055–04060` | Real truncation |
| [p_a7.madlen](p_a7.madlen) | `P/A7` | `04060–04066` | Width-adjusted ALFA/string output |
| [p_3.madlen](p_3.madlen) | `P/3` | `04016–04022` in `тестац.bin` | Level-3 frame entry |
| [p_6a.madlen](p_6a.madlen) | `P/6A` | `04037–04041` in `тестац.bin` | ALFA helper |

## Regeneration and building

From the repository root:

```sh
python3 runtime/recover.py monitor
python3 runtime/build.py library --profile monitor
```

`profiles.json` defines the reviewed ranges, files, aliases and relocations.
Regeneration writes the 31 image-derived sources and `relocations.json`.
The two supplemental helper files are maintained as recovered source.

`relocations.json` lists source files in original address order and records
each module's subprogram and common dependencies. Cross-module operands name
reviewed entries where available. Private targets retain a module-relative
offset. Each file declares only its own dependencies; `P/1` initializes the
runtime constants in `P/1D`. The builder assembles these files into the private
PERSO library and the loader chooses the required modules.

Program image comparisons cover every word and public entry of each selected
module. The `golden` action explicitly requests all modules for an
original-placement comparison. The last recorded full validation in
[validation.json](../../validation.json) predates this source split.
