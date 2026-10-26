# LINK1: Pascal recovery in progress

LINK1 identifies itself as **«КОМПОНОВЩИК ЭЛЬБРУС-Б: ВЕРСИЯ 2.40/1»**.
Its application is written in NEWPASC, with FORTRAN interfaces to its
buffered files and name helpers. There are no PMD tables; recovered procedure,
type and variable names are descriptive, not original source names.

**This is not yet a complete decompilation or a runnable rebuilt LINK1.**
The sources currently cover **33 routines, 1066 of 6543 application words
(16.3%)**. The link-job driver, most object processing and the main program
remain to be recovered. Both main bodies in the compilation harness are
explicitly marked as incomplete.

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
inferred from the phase messages and call sequence; the corresponding bodies
are not yet restored as Pascal.

| Entry | Role |
|---|---|
| `03717` | Parse the link job |
| `06247` | Gather object definitions and references |
| `07221` | Resolve references |
| `07516`, `07722` | Join sections and allocate segments |
| `12131`, `13665` | Evaluate objects/sections |
| `14153` | Write executable segments |
| `14605` | Produce the label file |
| `15063` | Print statistics |
| `15233` | Main driver, after file initialization |

## Recovered Pascal

- [helpers.pas](helpers.pas): qualified-name output, name interning, object
  bindings, record I/O wrappers, time/date formatting and shared declarations.
- [scanner.pas](scanner.pas): the nested scanner of READJOB, its 23 error
  messages, token representations and listing-option parser. It is inserted
  into `helpers.pas` by the builder; it is not a separate Pascal program.
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

The listing selector recognizes the literal words `CEKЦИИ`, `PAЗДEЛ`,
`CTAT`, `MOДYЛИ`, and `METKИ`, setting five separate bits. The all/default
path sets only the first four bits. The enclosing command dispatch remains
unrecovered, so this is not yet a complete command grammar.

Date values count seconds from the beginning of 1981. `PUTDATE` reconstructs
day/month/year and hours/minutes using the original four-year leap correction
and saved cumulative-month table. `PUTTIME` prints time measured in
fiftieths of a second as `MM:SS.cc`.

One detail is deliberately retained literally: NEXTCHAR calls the entry
corresponding to P/EL before P/EO, assigning the sentinel in the first branch
and LF in the second. Its common GET also runs after a saved character is
returned. These sequences match the image. Their behavior with LINK1's native
input setup has not been exercised; substituting a more familiar input loop
would change the surviving code.

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

The build compiles the recovered helpers and writes a scratch image with
PASCODER. Its FORTRAN externals have inert link stubs. **Neither the recovered
helpers nor LINK1's file/link operations are executed.** A successful build
therefore establishes compilation and the static comparisons below, not
functional equivalence of a restored linker.

[recovery.json](recovery.json) records the comparison. **27 of 33 routines**
have identical normalized instruction sequences. The comparison resolves
constant values, literal strings and named external addresses, removes UTC
padding, and retains both local branch targets and their definitions.
It does not establish literal word identity or reconstruct a complete runtime.

The remaining six routines have the following observed differences:

| Routine | Difference |
|---|---|
| SKIPREC | The current compiler evaluates the cursor query before the header field; the sum is unchanged |
| BADJOB | Call versus tail-call form for the final newline |
| SCANINT | Restore-helper call versus tail call, and an omitted jump to the following block |
| SCANNAME | Direct frame-relative stores instead of materializing a base in M11 |
| GETTOKEN | Three redundant jumps omitted |
| PRINTSEL | One redundant jump omitted |

Two historical unused loads of a composite value parameter are retained as
explicit BESM inserts in FINDOBJ/BINDOBJ. The arithmetic option `M-` reproduces
the original inline variable multiplication. Extra empty labels in scanner
loops retain calls that the current compiler otherwise turns into tail calls.

Listings, the combined job, scratch image and full comparison stay under
`runtime/build/link1`. No `.bin`, generated `.dis`, or private disk is needed
in the source tree's Git history.

## Work remaining

Recover the remaining READJOB helpers (`03466`, `03541`) and its driver
(`03717`), then the definition/reference pass (`05233–07220`), section and
segment placement, expression evaluator, output and label passes, statistics
and main. The FORTRAN services and the complete runtime also need source
reconstruction before a full LINK1 rebuild can be claimed.
