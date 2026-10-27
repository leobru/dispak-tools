# LINK1: recovered Pascal application

LINK1 identifies itself as **«КОМПОНОВЩИК ЭЛЬБРУС-Б: ВЕРСИЯ 2.40/1»**.
Its application is written in NEWPASC, with FORTRAN interfaces to its
buffered files and name helpers. There are no PMD tables; recovered procedure,
type and variable names are descriptive, not original source names.

The Pascal source covers the complete **6543-word application region
`02012–16630`**, including the entry, file initialization and startup.
The build compares **93 routines and entry/startup regions**. The parser,
table passes, evaluator, executable output, label generation, statistics
and main driver are recovered.

The build links [real runtime modules](../linker-runtime/README.md).
All **1720 library words** at `21426–24715`, all entries and FREE match
literally. The 920 constant words, P/1D, application globals and file blocks
also match exactly. The linker is not executed during the build.

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
| `07221` | Resolve references (recovered) |
| `07516` | Join sections and assign addresses (recovered) |
| `07722` | List placed sections and attributes (recovered) |
| `12131` | Evaluate a section stream or one definition expression (recovered) |
| `13665` | Complete definitions in one input module (recovered; EVALDEFS) |
| `14153` | Write executable segments (recovered) |
| `14605` | Produce the label file (recovered) |
| `15063` | Print statistics (recovered) |
| `15233` | Main driver, after file initialization (recovered) |

## Recovered Pascal

- [link1.pas](link1.pas): complete combined source, used by the default build.
  Routine bodies follow the original binary's address order; READJOB and
  its nested scanner precede PHASEMSG and the later I/O helpers.

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
main driver's final statistics/termination block, recovered as label
`9999` in link1.pas.

GATHER preserves prefix/data/expression tails in the temporary stream and
stores their indices and lengths in the original packed fields. At the end
it updates the input-file descriptor with the first index and count of each
table, prints the optional module listing, and closes the local vectors and
input file. The three local pair buffers each occupy fourteen words.

## Resolution and section joining

RESOLVE looks up each reference's namespace node. A defined node supplies its
definition-table index and sets the reference's resolved bit. Undefined
references form a linked list in their low sixteen bits; its head is saved
in the input-file descriptor. The function returns false and clears the
shared ALLFOUND flag when it encounters an undefined reference. UNRESMSG
walks that list and prints qualified names, wrapping at column 128.

JOINSECT ignores zero-length sections. Consecutive sections with the same
qualified name must agree in storage class, alignment, joining mode and
protection bits. Concatenated sections receive the next aligned address;
overlapping sections must have equal lengths and reuse the first section's
base and offset. The other modes produce the original fatal diagnostics.
A new name starts another group and saves its complete five-word descriptor.
ALIGNUP reproduces the original calculation of a `2**alignment` boundary
using `exp(alignment * ln(2))`, integer truncation and a remainder operation.
The inline conversion after `exp` is the same `ATX; AMX 11(1); AVX` sequence
used by the loaded P/TR: save the real value, subtract integer zero from its
absolute value with normalization and rounding disabled, then restore its
sign. P/1D offset `11` contains `6400000000000000`. The initial NTR 7 versus
P/TR's NTR 3 has no effect on this conversion: the suppression bits agree,
and AMX replaces the differing mode bits.

The routine at `07722`, previously provisionally named ALLOCSEG, actually
prints an already-placed section. It is now named LISTSECT: its output
contains the section/module names, base, final address, length, alignment,
storage class, joining mode and attribute flags. PUTSECTN handles the
qualified-name column; BADSECT and its nested SECTID identify incompatible
sections and their source modules before jumping to the main abort label.

## Expression evaluator helpers

The seventeen routines at `10162–12130` occupy 999 original words. They are
nested in EVALUATE's 175-word frame, with twelve single-word operand slots,
a stack pointer, instruction/pair buffers and an unpacked 128-byte input
buffer. Slots eleven and twelve also provide scratch words for stack
permutations. The driver at `12131–13633` occupies another 835 words; its
Boolean return distinguishes a completed evaluation from a dependency
whose definition is not yet ready.

| Entry | Recovered operation |
|---|---|
| `10162`, `10203` | Dump the operand stack; print fatal expression diagnostics |
| `10432`, `10447` | Flush an output pair; pack successive 24-bit values |
| `10473`, `10542` | Read expression bytes; read alternating 24-bit operands |
| `10571` | Push a big-endian literal assembled from input bytes |
| `10614` | Add a section's placed-base minus saved-base delta |
| `10645`, `10706` | Push a definition address directly or through a reference |
| `10771`, `11050` | Fetch a 48-bit saved attribute directly or through a reference |
| `11152`, `11317` | Emit stack results; process a saved operator block |
| `11413` | Load an instruction address or raw operand into stack slot one |
| `11552`, `11724` | Dispatch binary and field/shift micro-operations |

The input reader consumes four bytes from each half of a two-word record.
It uses six-character UNPCK calls at four-byte intervals: the last two stores
of each call overlap the following group. At the end of a full 128-byte
refill they reach the following two loop-variable words. The recovered
layout and calls retain this observed behavior.

The four output forms distinguish a short instruction address, a prefixed
instruction address, a full word and a single 24-bit value. Instruction
handling extracts the long/short format flag, preserves register/opcode
bits and reconstructs signed short addresses. These routines operate on
BESM-6 instruction fields held sixteen bits above the bottom of their buffer
words.

Definition lookup tests a separate **ready** flag at bit 31 (counting from
zero), rather than the gathered-value flag at bit 27, and marks used definitions
at bit 29. References have a used flag at bit 32. Attribute lookup joins two
24-bit values from a temporary pair into one stack word. For zero or unbound
references, PUSHREF/REFATTR retain the original exits without assigning their
Boolean result. FIRSTVAL also retains the observed full-word sequence that
stores the low half and then overwrites it with the shifted high half.
These details have been checked against instructions, not by running LINK1.

PACKVAL/UNPACKVL describe the integer/value conversion calls at `23263` and
`23302`. The remaining value-arithmetic services retain address-based names
such as B23312; their bodies are not recovered here. Their typed FORTRAN
declarations reproduce the original calls. Their real relocatable Madlen
bodies are selected from the shared linker runtime sources.

## Evaluator driver and definition pass

EVALUATE has two modes. For a section stream it sets the output record index,
reads successive expressions and emits their values. For a definition it
selects the full-word form, evaluates one expression and returns. A failed
definition/reference lookup returns false; the caller can retain that
unfinished definition for a later pass. Fatal format errors use BADEXPR and
the nonlocal main abort destination.

An expression byte carries a low four-bit operation, a three-bit group and
a high completion bit. The recovered group dispatch is:

| Group (decimal) | Action |
|---|---|
| 0 | Literal pushes, duplication, stack permutations and explicit result output |
| 1 | Binary micro-operations |
| 2 | Field and shift micro-operations |
| 3 | Definition/reference addresses, with byte, two-byte or stack indices |
| 4 | Definition/reference attributes, with immediate or stack arguments |
| 5, 7 | Reject unsupported operations |
| 6 | Section base lookup and section-relative relocation |

The completion bit normally emits one result and ends the expression.
Group zero also supports an explicit output count. Immediate two-byte
object indices use a multiplier of 256; the section-index variant at
`13532` retains the original multiplier of **8**. The stack permutations
use slots eleven and twelve, and preserve the original depth checks.

Between section expressions the driver recognizes these controls; opcode
values in this table are **hexadecimal**:

| Opcode | Action |
|---|---|
| `82` | Read a new five-bit output tag |
| `83` | Process a saved operator block |
| `84–87` | Select instruction, prefixed instruction, half-word or full-word form |
| `88`, `89` | Repeat the previous output pair, with byte or two-byte count |
| `8A` | Copy raw input values to output |
| `8B`, `8C` | Emit zero pairs, with byte or two-byte count |
| `8D` | Form a reference-bearing output record |
| `8E` | Report an invalid operation |
| `8F` | Finish the section stream |

The counted output loops start at zero and include the supplied limit.
Modifiers `6A–6C` change the saved tag or select the prefixed form before
an expression; their high-bit variants copy the selected operand form
straight to output. The recovered code retains the original restrictions
on section mode and partially filled output pairs.

The routine at `13665`, formerly provisionally named EVALSECT, processes
module **definitions** and is now named EVALDEFS. It loads the module's
definition/reference/section ranges, skips ready definitions and handles
the remaining records in two ways:

- For a definition with an explicit value, translate its local section
  number, add the section's placed-base minus saved-base delta and mark it
  ready. A zero section number needs no relocation.
- For a computed definition, point EVALUATE at its saved expression. On
  success, check the signed address range `[-32768, 32768)`, store the value,
  set its value-present and ready flags, and record any saved attributes.

The return enum records whether the pass completed no new work, completed
work only, encountered both completed and pending work, or encountered
pending work only. Its raw values are respectively 0, 1, 2 and 3. The main
driver retries while definitions become ready, stops when all are ready,
and reports an unevaluable definition when a pass makes no progress.

The attribute count at `14100` is preserved as the low five bits of
`g0103 - g0102`, although the temporary-write cursor advances in the opposite
direction. This is the surviving instruction sequence; it has not been
replaced with a positive length. BADVALUE at `13634` reports invalid section
numbers or out-of-range addresses and takes the main abort path.

## Output, labels, statistics and main driver

WRITESEG at `14153` reads a module's records again. Types 0–9 are skipped;
type 10 restores the section's output form, tag, partial-pair state and
address, evaluates its stream, and saves the resulting state. Type 255
ends the loop and closes the input. BADOUT at `14113` reports invalid
section indices or record types through the main abort destination.

LABELS at `14605` writes an object-format header with signature `ABCDEF`,
version 2 and module name `KOMПOH-1`. PUTLABEL at `14333` walks namespace
children and their search trees. It emits definition records with saved
attributes and prefix records, assigns output indices, and finishes with
a type-255 record. The input name and temporary-pair services remain
external calls. STATS at `15063` converts saved timestamps into per-phase
differences and prints CPU, wait and total times through PUTTIMES.

The main driver initializes the table descriptors and built-in `CИCBЫB`
and `CИCBBOД` names, parses the job, gathers modules, resolves references,
places sections and repeatedly evaluates definitions. It then writes the
executable segments, optionally emits labels and prints statistics. Its
final loop invokes extracode `Э74`. These operations are recovered from
instructions; the reconstructed linker has not been run.

The static data includes the complete 256-entry character classification
table, cumulative month days, initial definition/prefix counters and the
ALLFOUND flag. All **384 application global words** match the reference
exactly after relocating the global base. Repeated table values use the
compiler's `value:count` initializer syntax to fit its existing heap.

## Compile and compare the recovered routines

```sh
python3 runtime/link1/analyze.py
python3 runtime/link1/build.py
```

The builder also writes `runtime/build/link1/original.dis` and `rebuilt.dis`
for inspection with tkdiff:

```sh
tkdiff runtime/build/link1/original.dis runtime/build/link1/rebuilt.dis
```

These symbolic listings cover the Pascal application, with one line per
instruction and all UTC padding retained. Routine headings give actual
addresses; constant-pool operands, literal addresses and named calls are
resolved to avoid relocation noise. Local labels belong to their routine.
Use `python3 runtime/link1/build.py --disassemble-only` to regenerate them
from the existing compiled image and listing without recompiling.

Missing reference images are extracted read-only from volume 4001 with
`besmtool`. They remain under `runtime/images/4001` and are not source files.
The builder uses a private compiler volume 77 and private HOME following the
existing DISPAK launcher pattern. Installed disk lookup is preserved before
HOME is changed. Shared unsigned field-range types avoid duplicate compiler
type descriptors; scanner-only and evaluator-only types and external
declarations stay in their own scopes. The private compiler packs its instruction flags into an
11-word node and keeps the existing K9 heap. YESMEMORY reports exhaustion explicitly if a future expansion exceeds
that limit. No original disk is mounted for writing. Private writable
volumes are not hashed.

The build compiles the recovered routines and writes a scratch image with
PASCODER. P/WO and its P/WH hexadecimal-output entry use the recovered Monitor
module, also present in `runtime/build/proz/runtime.madlen`. The builder
recreates that module from tracked `profiles/monitor/p_wo.madlen` and exports
P/WH at P/WO+1, as the PROZ builder does; no prior PROZ build is required.
All external services now have real bodies. [library.json](library.json)
records literal comparisons and every module placement. Separate
`original-runtime.dis` and `rebuilt-runtime.dis` files cover the library.
**LINK1's file/link operations are not executed.** A successful build
therefore establishes compilation and the static comparisons below, not
functional equivalence of a restored linker.

[recovery.json](recovery.json) records the comparison. **87 of 93 code regions**
have identical normalized instruction sequences. The comparison resolves
constant values, literal strings (including M16 namekey operands) and named
external addresses, removes UTC
padding, and retains both local branch targets and their definitions.
Application normalization does not establish literal word identity.
The independent library comparison requires literal identity.

The remaining six routines have the following observed differences:

| Routine | Difference |
|---|---|
| SCANINT | Restore-helper call versus tail call, and an omitted jump to the following block |
| GETTOKEN | Three redundant jumps omitted |
| PRINTSEL | One redundant jump omitted |
| STAMPOBJ | Integer zero is read from P/1D rather than the constant pool |
| GATHER | One redundant NTR 7 before PUTSIZE is omitted |
| LABELS | One redundant NTR 7 before the output-size query is omitted |

The three POSITION call blocks in SKIPREC and the two MAIN segment seeks
now follow the packed-field loads, matching the original instruction order.
Writing `POSITION(...) + count` in these expressions makes the compiler
emit the field extraction first. SKIPREC matches including padding. Empty
`(x);` statements after MAIN's final extracode and after its infinite loop
restore the original padding and unreachable P/EF jump; MAIN now also
matches including padding.

GETFILE now shifts the raw `KEY.attr` word before storing the module field,
avoiding two extra integer-normalization instructions. Its loop limit is
evaluated in the `for` header and saved in the compiler's temporary slot.
Its loop uses the explicit `(*q*)` exception: a real `(q)` would align the
loop exit and add two UTC fillers. GETFILE now matches the original 43 words,
including padding, after resolving relocations.

Two historical unused loads of a composite value parameter are retained as
explicit BESM inserts in FINDOBJ/BINDOBJ. The arithmetic option `M-` reproduces
the original inline variable multiplication. Extra empty labels in scanner
loops retain calls that the current compiler otherwise turns into tail calls.
READJOB also retains a redundant jump using `(q) exit q;`. Its complete
366-word original body has an identical normalized instruction sequence;
the rebuilt body occupies the same 366 words after explicit alignment.
All eleven GATHER helpers have identical normalized sequences. GATHER itself
occupies 490 words in both images, with the difference above. Its account
output masks the raw header word with `[0..31]`, shifts right by 24 bits,
and prints hexadecimal without integer normalization. The preceding space
belongs to the same `write`, preserving OUTPUT across the two items.
PUTDEF, PUTSECT and PUTREF are typed Pascal declarations of the same original
table-copy entry; the comparison maps all three to TABPUT. GETPAIR/PUTPAIR,
TABPAIR, TABFILE and TABSAVE similarly declare typed views of the original file/table
copy services. All seventeen evaluator helpers have identical normalized
sequences; explicit alignment preserves their original total of 999 words. The evaluator driver,
BADVALUE and EVALDEFS also match normalized instructions throughout; their
835, 25 and 150 original words compile to the same lengths.

### Loop alignment

Every `for` and `while` uses the `(q) ... do (r)` coding pattern unless an
explicit `(*q*)` comment replaces the opening label. There are 15 such
exceptions; the other 41 loops retain `(q)`, and all 56 retain `(r)`.
The builder accepts explicit exceptions and still checks `(r)`.

GETFILE's exception removes an extra word at the loop exit. Fourteen further
exceptions remove a UTC before the loop initializer: FINDOBJ, BINDOBJ,
BADJOB, CONVERT, SCANINT, SELECTFILES, READJOB, READREC, READBODY, READPART,
WRITREC, EMITOPER and two loops in EVALUATE (LOOP173 and LOOP176).
Where the original requires alignment after a loop, an explicit `(x);`
retains that boundary. SELECTFILES's search label now precedes the limit
assignment, preserving its exit target without aligning the initializer.
PATHLEN matches the original 19-word routine, including padding.

| Comparison | Before loop labels | Current source |
|---|---:|---:|
| Rebuilt application words (original: 6543) | 6489 | 6543 |
| Matching regions, UTC padding omitted | 79 | 87 |
| Matching regions, UTC padding retained | 51 | 87 |
| Padded symbolic instruction edit cost | 258 | 12 |

Empty `(x);` statements retain missing word boundaries before loop-limit
calculations, repeat conditions and other statement boundaries. ALIGNUP now uses the private compiler's historical inline truncation,
restoring its 13 words without a padding jump or P/TR dependency.
All 93 compared regions now have their original word counts, and both
constant pools begin at `16631`. The instruction differences listed above
remain; matching lengths do not establish literal word identity.

Both comparisons resolve relocations and constants. The padded edit cost
sums the larger side of each differing instruction/label block; it is not
a count of differing binary words. All 384 application global words still
match. The updated `original.dis` and `rebuilt.dis` retain padding for tkdiff.

`python3 runtime/link1/align.py` applies the loop markers and rebuilds once,
preserving explicit `(*q*)` exceptions. The former `--body` option is accepted
as an alias. There is no automatic marker selection or removal.

Listings, the combined job, scratch image and full comparison stay under
`runtime/build/link1`. No `.bin`, generated `.dis`, or private disk is needed
in the source tree's Git history.

## Work remaining

Exercise real link jobs to verify file and linking behavior. The build now
reconstructs every library word, but it does not establish functional
execution of the recovered linker.
