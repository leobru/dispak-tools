# LINK1: Pascal recovery in progress

LINK1 identifies itself as **«КОМПОНОВЩИК ЭЛЬБРУС-Б: ВЕРСИЯ 2.40/1»**.
Its application is written in NEWPASC, with FORTRAN interfaces to its
buffered files and name helpers. There are no PMD tables; recovered procedure,
type and variable names are descriptive, not original source names.

**This is not yet a complete decompilation or a runnable rebuilt LINK1.**
The sources currently cover **54 routines, 2694 of 6543 application words
(41.2%)**. The complete link-job parser and definition/reference gathering
pass are recovered. Resolution, placement, evaluation, output and the main
program remain to be recovered; the compilation harness has an inert main.
The recovered routines cover the contiguous original region `02013–07220`.

## Image and structure

Addresses and zones are octal; word counts are decimal.

| Region | Addresses / value |
|---|---|
| Volume 4001 allocation | `0175–0214`, 16 zones |
| P/BOOT pages | `012`, ten zones; only `0175–0206` are loaded |
| Program entry, startup | `02012`, `16624` |
| Application code | `02012–16630`, 6543 words |
| Constant pool | `16631–20460` |
| P/1D and globals | from `20461` |
| INPUT, OUTPUT | `21331`, `21367` |
| Runtime | from `21426` |
| FREE | `24716` |

[inventory.json](inventory.json) lists **87 framed entries**, their lexical
levels and frame sizes. The frameless character reader is identified
separately. Some entries with several parameters have an argument-store word
before the frame call; the inventory's frame-call address does not always
include that preceding word. Following-entry distances include nested
procedures and must not be summed as independent function sizes.

The driver calls establish the following broad phase map. These names are
inferred from the phase messages and call sequence. Recovered bodies are
marked explicitly.

| Entry | Role |
|---|---|
| `03717` | Parse the link job (recovered) |
| `06247` | Gather object definitions and references (recovered) |
| `07221` | Resolve references |
| `07516`, `07722` | Join sections and allocate segments |
| `12131`, `13665` | Evaluate objects/sections |
| `14153` | Write executable segments |
| `14605` | Produce the label file |
| `15063` | Print statistics |
| `15233` | Main driver, after file initialization |

## Recovered Pascal

- [helpers.pas](helpers.pas): qualified-name output, name interning, object
  bindings, phase/module diagnostics, input and record I/O wrappers,
  time/date formatting, object timestamps and shared declarations.
- [scanner.pas](scanner.pas): READJOB, its nested scanner, 23 error
  messages, token representations and listing-option parser. It is inserted
  into `helpers.pas` by the builder; it is not a separate Pascal program.
- [gather.pas](gather.pas): GATHER and eleven nested routines for names,
  definition diagnostics, table initialization and record-tail preservation.
  It is also inserted into `helpers.pas` by the builder.
- [link1.sym](link1.sym), [names.json](names.json): recovered symbols and the
  address-to-name map used during analysis.

Name interning uses 128 hash buckets with **sorted singly linked chains**.
The comparison helper returns raw ordinal values for equal, after and before.
The two-word name record has ten text bytes, a flag and a 15-bit chain link;
its Pascal variant record overlays these fields explicitly. Empty references
use `ptr(0)`, not the current compiler's default NIL value `74000`.
Object records refer to these interned names. Namespace records form another
chain, which is collected and printed in reverse order.

The scanner accepts `(* ... *)` comments, names, punctuation and numbers.
Its numeric parser allows at most twelve characters and recognizes:

| Suffix | Interpretation |
|---|---|
| none, `B` | Octal |
| `H` | Hexadecimal |
| `З` (KOI-8 `372`) | Octal multiplied by 1024 |
| `C` | Octal multiplied by 256 |
| `Д` (KOI-8 `344`) | Decimal |

Disk-file tokens contain a packed virtual-drive/zone address and optional
`:length`. The drive is checked against decimal `16–55`, zone against
`0–3995`, and length against `0–127`; the default length is 127. Longer names
are skipped after the retained ten characters. The scanner also recognizes
`*/` as an input terminator.

READJOB first requires `ФAЙЛЫ`, followed by name/address bindings terminated
by a semicolon, then `ЗAГP` and the load list. File qualifiers recognized in
the image are `PAЗДEЛ`, `CИC`, `ЛИCT`, `CXEMA`, and `METKИ`. It checks output
file uniqueness and the ordering of object files and qualifiers. The file
table uses four-word records with a name pointer, a 30-bit module/file code
and two selection flags; new entries are cleared with record constructors.
The name-list selector and the final common flags operate on these flags.

The listing selector recognizes the literal words `CEKЦИИ`, `PAЗДEЛ`,
`CTAT`, `MOДYЛИ`, and `METKИ`, setting five separate bits. The all/default
path sets only the first four bits.

The explicit layout parser accepts object names joined by `+`, then optional
`:` parameters: a bare load address, `HAЗ=`, `HAД=` or `HAД+`, and `ДЛИ=`.
It retains the original punctuation handling, including `.` after `HAД`.
Load addresses must be below 32768, disk addresses at most 2097151, and
segment lengths at most 131071 (decimal). Each segment has a header, its
file-index entries and a final packed length/count record. The implicit
layout takes its length from the output-file descriptor. These are recovered
parser operations; the complete input setup and linking workflow have not
been executed.

Date values count seconds from the beginning of 1981. `PUTDATE` reconstructs
day/month/year and hours/minutes using the original four-year leap correction
and saved cumulative-month table. `PUTTIME` prints time measured in
fiftieths of a second as `MM:SS.cc`. STAMPOBJ obtains the account with
`Э50 100`, time since midnight with `Э53 10`, and the date with GETDATE.
Its packed object fields retain the account bits, weekday and creation time.

One detail is deliberately retained literally: NEXTCHAR calls the entry
corresponding to P/EL before P/EO, assigning the sentinel in the first branch
and LF in the second. Its common GET also runs after a saved character is
returned. These sequences match the image. Their behavior with LINK1's native
input setup has not been exercised; substituting a more familiar input loop
would change the surviving code.

## Definition and reference gathering

GATHER opens one input file, requires a type-zero header with signature
`ABCDEF` (hexadecimal), and dispatches the subsequent record types:

| Type (decimal) | Recovered action |
|---|---|
| 0 | Report a header in the wrong position |
| 1 | Intern an elementary-module name and append it to its local vector |
| 2 | Add a section to the linked section table |
| 3 | Intern a prefix and append it to its local vector |
| 4 | Store an entry definition, its optional name, value and saved tails |
| 5, 7, 10 | Skip the record |
| 6 | Store a definition with an expression or an explicit value |
| 8 | Store a reference and its saved tail |
| 9, 255 | End the input; type 9 adds an asterisk in the module listing |
| other | Report an invalid record type |

RESNAME expands indexed names through the definition, reference, section,
prefix or elementary-module tables. It splits and interns the resulting
components, preserving the original dot handling and length checks.
Each namespace has a binary search tree of its children; each child also
links back to the enclosing namespace for qualified-name output.

BADOBJ reports duplicate global definitions, prints both definition classes
and module names, and chooses the definition with the higher class value:
entry, computed, relocatable, absolute. Equal classes select the later
definition. Other errors perform the original nonlocal jump to `16611`, the
main driver's final statistics/termination block. That main block is still
unrecovered: label `9999` supplies only its destination in the compilation
harness.

GATHER preserves prefix/data/expression tails in the temporary stream and
stores their indices and lengths in the original packed fields. At the end
it updates the input-file descriptor with the first index and count of each
table, prints the optional module listing, and closes the local vectors and
input file. The three local pair buffers each occupy fourteen words.

## Compile and compare the recovered routines

```sh
python3 runtime/link1/analyze.py
python3 runtime/link1/build.py
```

Missing reference images are extracted read-only from volume 4001 with
`besmtool`. They remain under `runtime/images/4001` and are not source files.
The builder uses a private compiler volume 77 and private HOME following the
existing DISPAK launcher pattern. Installed disk lookup is preserved before
HOME is changed. No original disk is mounted for writing. Private writable
volumes are not hashed.

The build compiles the recovered routines and writes a scratch image with
PASCODER. P/WO and its P/WH hexadecimal-output entry use the recovered Monitor
module, also present in `runtime/build/proz/runtime.madlen`. The builder
recreates that module from tracked `profiles/monitor/p_wo.madlen` and exports
P/WH at P/WO+1, as the PROZ builder does; no prior PROZ build is required.
The remaining external services have inert link stubs. **Neither the recovered
helpers nor LINK1's file/link operations are executed.** A successful build
therefore establishes compilation and the static comparisons below, not
functional equivalence of a restored linker.

[recovery.json](recovery.json) records the comparison. **45 of 54 routines**
have identical normalized instruction sequences. The comparison resolves
constant values, literal strings and named external addresses, removes UTC
padding, and retains both local branch targets and their definitions.
It does not establish literal word identity or reconstruct a complete runtime.

The remaining nine routines have the following observed differences:

| Routine | Difference |
|---|---|
| SKIPREC | The current compiler evaluates the cursor query before the header field; the sum is unchanged |
| BADJOB | Call versus tail-call form for the final newline |
| SCANINT | Restore-helper call versus tail call, and an omitted jump to the following block |
| SCANNAME | Direct frame-relative stores instead of materializing a base in M11 |
| GETTOKEN | Three redundant jumps omitted |
| PRINTSEL | One redundant jump omitted |
| GETFILE | Two extra instructions normalize a packed field before storing it |
| STAMPOBJ | Integer zero is read from P/1D rather than the constant pool |
| GATHER | One redundant NTR 7 is omitted; the account field is normalized and OUTPUT reloaded before hexadecimal output |

Two historical unused loads of a composite value parameter are retained as
explicit BESM inserts in FINDOBJ/BINDOBJ. The arithmetic option `M-` reproduces
the original inline variable multiplication. Extra empty labels in scanner
loops retain calls that the current compiler otherwise turns into tail calls.
READJOB also retains a redundant jump using `(q) exit q;`. Its complete
366-word original body has an identical normalized instruction sequence;
the rebuilt body occupies 365 words because of instruction packing.
All eleven GATHER helpers have identical normalized sequences. GATHER itself
occupies 490 words in both images, with the listing-only differences above.
PUTDEF, PUTSECT and PUTREF are typed Pascal declarations of the same original
table-copy entry; the comparison maps all three to TABPUT.

Listings, the combined job, scratch image and full comparison stay under
`runtime/build/link1`. No `.bin`, generated `.dis`, or private disk is needed
in the source tree's Git history.

## Work remaining

Recover resolution (`07221`), section and segment placement, the expression
evaluator, output and label passes, statistics
and main. The FORTRAN services and the complete runtime also need source
reconstruction before a full LINK1 rebuild can be claimed.
