# COMP rebuild

[build.py](build.py) rebuilds the whole COMP image (volume 4001, zones
`0315–0324`, eight zones loaded at `02000`) from [comp.pas](../../comp.pas)
and a private PERSO library, and compares it with
[0315-comp.bin](../images/4001/0315-comp.bin) word by word:

```sh
python3 runtime/comp/build.py
```

8189 of 8192 words are identical. The remaining three are listed in
[reconstruction.json](reconstruction.json):

| Word | Cause |
|---|---|
| `02010` left half | The loader's own value in the PASCODER descriptor; it depends on the build environment. The right half (FREE = `21050`) agrees. |
| `02202–02203` | RDBUF: the original compiler loaded `LIS` before `AФ*[30:47]`. |

## Layout

Addresses are octal; ranges are inclusive–exclusive.

| Range | Module | Source |
|---|---|---|
| `02000–02012` | PASCODER stub | standard PERSO 311160; table `w*370250` as originally |
| `02012–05663` | COMP: code, pool, PMD, P/1D, globals, INPUT/OUTPUT | `comp.pas` |
| `05663–06320` | P/2, P/SC, P/SYS, P/DA, P/08, P/LDAR, P/CW, P/EF | Monitor runtime ([../profiles/monitor](../profiles/monitor)) |
| `06320–06332` | P/STAR | libpas |
| `06332–06361` | *TTIO* | Monitor runtime |
| `06361–06365` | P/3 | Monitor helper |
| `06365–06502` | E6365, E6444 (reader 1) | COMP words |
| `06502–06600` | P/7A, P/WI | Monitor runtime |
| `06600–06602` | P/31, accumulator-preserving variant (`wtc 2; vtm`; libpas has `xta 2; ati 2`) | COMP words |
| `06602–06717` | E6602, E6661 (reader 2) | COMP words |
| `06717–06724` | P/WC | libpas |
| `06724–06743` | P/EQ, P/GE (15 words; libpas p_eq is 12) | COMP words (also in ACC3/ACC2) |
| `06743–06754` | P/6A, P/A6 | Monitor helper, libpas |
| `06754–07036` | P/WO | Monitor runtime |
| `07036–07241` | ERROR | file-access ([../file-access](../file-access)) |
| `07241–07244` | P/MI | libpas |
| `07244–10266` | DBNAME (MKNAME), DBFILE (OPENF) | file-access |
| `10266–10655` | P/1, PASPMD, P/ER, STOP*, MONOUT, MONIN, P/PRINT, PASCHARS, P/PUTERR, P/HT | Monitor runtime, COMP converter tables |
| `10655–14002` | common E6365B: padding, buffer `12000–13777`, state `14000–14001` | zero |
| `14002–14056` | COZYTISO | system permanent library |
| `14056–14076` | DRUMTAP* | COMP words |
| `14076–14112` | P/HIDE, P/SP | Monitor runtime |
| `14112–20002` | common E6602B: padding, buffer `16000–17777`, state `20000–20001` | zero |
| `20002–20175` | DBPASC, DBCORE | file-access |
| `20175` | common PASPMDAD | zero |
| `20176–20453` | P/WX, P/WR, P/RC | Monitor runtime |
| `20453–20543` | MONREAD* | COMP words |
| `20543` | common CHKWORD* | zero |
| `20544–20551` | PRINT8 | COMP words |
| `20551–20613` | PASISOXT, PASWRCHR, P/TR, P/A7 | Monitor runtime |
| `20613–20625` | CLEARLEX | system permanent library |
| `20625–21047` | LUN*MON (with the terminal output and MON*ITOR code of this version) | COMP words |
| `21047` | common TSTATE* | zero |

The Э70 buffers of the readers must start on a page boundary. The padding in
front of them is inferred from the placement and folded into the commons
E6365B and E6602B; their names are invented. The Monitor-80 module versions
in COMP differ from those in dispak's permanent library, except COZYTISO and
CLEARLEX, which the loader takes from the system (checked with a deck
without `*perso`). The module boundaries and the names PRINT8 and LUN*MON in the
`20453–21047` region follow the system versions; within LUN*MON the original
boundaries are not recovered.

## Load order

The loader keeps one list of names. It starts with the program's external
names in symbol-table order. Each loaded module appends its `SUBP` and `LC`
names in declaration order. Modules and commons are placed in the order of
that list, so commons land among the modules. `build.py` sets the declaration
order where it decides the layout (`ORDER`, the `subp` lists of `HELPERS`).
Two things are inferred from the layout:

- the `SPACE*` reference in P/SYS that places PASCHARS;
- `PASPMDAD` being a common declared first by PASPMD.

In the program, `*TTIO*` follows P/STAR because COMP declares `TTIO` as a
program parameter in a later `var` part, after ВВЛЕКСЕМ. `TTIO[3] := c`
compiles to the same words as the `TTIO(c)` built-in.
