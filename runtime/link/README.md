# LINK: recovered Pascal application

LINK is version **2.40/3** of the Elbrus-B linker from volume 4001 zones
`0112–0131`. [link.pas](link.pas) was recovered using
[LINK1's complete Pascal source](../link1/link1.pas), version 2.40/1.
Shared routine and variable names follow the older KOMPON PMD tables;
unmapped names remain descriptive. This image contains no PMD tables.

The source compiles and covers the complete **6875-word application region
`02012–17344`**. All **93 compared regions** have their original entry
addresses and word counts. **85 regions match instructions including UTC
padding** after resolving calls, branches and constants. The entire
**926-word constant pool** and all **384 application global words** match
literally at their original addresses.

The [real runtime](../linker-runtime/README.md) reproduces all **1772 library
words**, their entries and FREE literally. P/1D and file blocks also match.
[library.json](library.json) records the complete comparison. The linker
is not executed during the build.

Shared PMD-backed identifiers were mirrored from
[KOMPON 2.02/3](../kompon3/README.md); the
[correspondence table](../linker-runtime/historical-names.json) records
the names and scopes. Rebuilding after the renames produced an image
byte-for-byte identical to the pre-rename build.

## Build and inspect

```sh
python3 runtime/link/analyze.py
python3 runtime/link/build.py
python3 runtime/link/analyze.py 10602 10647
tkdiff runtime/build/link/original.dis runtime/build/link/rebuilt.dis
```

The build reuses LINK1's compiler, symbolic comparison and loop checks.
Scratch disks, HOME, listings and images stay under `runtime/build/link`.
Missing original images are extracted with `besmtool`; extracted `.bin`
files, generated `.dis` files and private volumes are not source artifacts.

- [inventory.json](inventory.json): original routine and service addresses.
- [link.sym](link.sym), [names.json](names.json): recovered symbols.
- [recovery.json](recovery.json): per-region compilation comparison.

The analyzer pairs the same 87 procedure frames by nesting level and
parameter count. It infers consistent service relocations from aligned
original code. ПEЧBPE, ДEЛЬTAC and ГPYППA10 also provide corresponding
fixed-order call sequences, including the wider value conversions.
The build compares the recovered source against LINK's own original image.

## Original image layout

Addresses and zones are octal; sizes in words are decimal.

| Region | Address / size |
|---|---|
| Allocation | `0112–0131`, 16 zones |
| P/BOOT loaded pages | `012`, ten zones |
| Pascal application | `02012–17344`, 6875 words |
| Startup | `17340` |
| Constant pool | `17345–21202`, 926 words |
| P/1D and globals | `21203` |
| INPUT / OUTPUT | `22053` / `22111` |
| Runtime | `22150` |
| FREE | `25524` |

## Changes from LINK1

The parser, object gathering, reference resolution and section placement
retain the LINK1 structure. The principal changes are in the expression
evaluator and target instruction format:

- An operand occupies two BESM-6 words: a 48-bit low part and a 16-bit high
  part. DUMPCTEK prints four plus twelve hexadecimal digits. Stack shuffles
  copy the complete two-word values, and the arithmetic service declarations
  use the wider record type. MAШИHA's frame grows from 175 to 187 words.
- БAЙTЫBCT accepts up to eight bytes. Its first loop fills the two high bytes;
  its second loop shifts bytes into the low 48 bits. The micro-operation
  cases for seven- and eight-byte literals now call БAЙTЫBCT.
- ДAЙOПEP and ЗAПBPAЗД transfer 32-bit chunks in the high 32 bits of the
  two-word file records. Attribute loading and full-word expression output
  explicitly move the parts between file pairs and the operand representation.
- Load-address checks and definition results use the wider 27-bit bounds
  also seen in BLINK1. ЗHAЧCOБ, ЗHAЧBHEШ and section-base evaluation explicitly
  sign-extend bit 26 before calling the value conversion service.
- An instruction has a four-bit register and an eight-bit opcode. Opcode
  63 uses the main format's 12-bit address. The additional format has a
  signed 20-bit address: a sign bit plus 19 low bits. ГPYЗЧИK recognizes
  prefix opcodes 58 and 57 and multiplies their address by 4096. ЗABEPШИO
  splits a prefixed address by division and remainder by 4096 and applies
  the format-specific bounds.
- Diagnostic field boundaries are based on 64 bits. Section and segment
  addresses are printed in hexadecimal; the main listing's spacing changes
  accordingly. The producer stamp is `КОМПОН-3`, and the banner says 2.40/3.

These changes increase the application by **332 words**. The evaluator and
its helpers account for most of the increase; all recovered routine sizes
are recorded in the comparison report. External `B…` identifiers retain
their LINK1 names; the inventory records their actual LINK entry addresses.

The source retains the observed packing operations literally, including
the differing shift sequences used by attribute loading and ГPYЗЧИK.

## Remaining instruction differences

Six differences are inherited from the LINK1 recovery:

| Routine | Difference |
|---|---|
| ДAЙЦEЛOE | A restore-helper call replaces a tail call; one redundant jump is omitted |
| CKAHEP | Three redundant jumps are omitted |
| PEЖПEЧ | One redundant jump is omitted |
| YЧET | Integer zero comes from P/1D instead of the constant pool |
| CБOPOБЬE | One redundant NTR 7 before ПEЧДЛФAЙ is omitted |
| ГEHMETKИ | One redundant NTR 7 before ПEЧДЛФAЙ is omitted |

Two further compiler-generation differences remain:

- ЗAПBPAЗД normalizes `ord(ФПPABC)` with an extra `AOX 11(1)` before loading
  the index register. The lower index bits are unchanged; a call's UTC filler
  moves, keeping the original 17-word size.
- ГPYЗЧИK evaluates the shifted temporary before loading the existing low
  word for the final bitwise union. The original loads the low word first.
  Both produce the same union; the region retains its original 102 words.

The padded symbolic edit cost is **17**, an instruction/label comparison
measure rather than a count of differing image words. All loop labels and
explicit `(*q*)` exceptions are retained from LINK1; the new БAЙTЫBCT loop
uses `(q) ... do (r)`. Empty pointers use `ptr(0)`.

BЫPABAДP uses inline truncation without
P/TR or a padding jump. The separate runtime disassemblies are
`original-runtime.dis` and `rebuilt-runtime.dis`. Real link jobs remain
unexercised.
