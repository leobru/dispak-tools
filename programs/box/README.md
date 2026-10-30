# BOX recovery

BOX is a small NEWPASC Monitor utility from volume **4001**, catalog zones
**0066–0067** (octal). Both zones survive. Its commands include `ПРО`, `ВЫД`,
`ЛИСТ`, `ЭХО`, `СОХ` and `НОВКАТ`; the last locates a named library in the
Monitor's table, requests confirmation, then writes an empty catalog.

## Build

From the repository root:

```sh
python3 programs/box/build.py
```

The builder uses DISPAK and `besmtool`, rebuilds the current `mypas.b6` on a
private volume 77, assembles a private Monitor library and dumps the linked
image with PASCODER. It checks that the original volumes 4001 and 77 remain
unchanged. Missing reference extracts are obtained from 4001 with `besmtool`;
existing extracts must agree with the corpus hashes and the disk contents.
All writable volumes, decks, listings and images are under `build/box/`.
It stops after dumping and does not execute BOX's Monitor commands.

- [box.pas](box.pas): source with historical line numbers and packing.
- [box-readable.pas](box-readable.pas): the reconstruction without line padding.
- [box.sym](box.sym): application, runtime and shared-memory addresses.
- [reconstruction.json](reconstruction.json): hashes and strict comparison.

To compile the readable source and report its expected line-number differences:

```sh
python3 programs/box/build.py --explore --source programs/box/box-readable.pas
```

Exploration reports stay in the build directory. Run the default command again
to restore the final image, listing and strict comparison. Reference `.bin`
files and generated `.dis` files are artifacts and are not source deliverables.

## Comparison

Addresses are octal, word counts decimal. Each word has 48 bits.

| Region | Addresses, inclusive | Words | Result |
|---|---|---:|---|
| Pascal code | `02012–02564` | 363 | Bit identical |
| Constants | `02565–02661` | 61 | Bit identical |
| Initial globals and files | `02662–03030` | 103 | Bit identical |
| Runtime and its state | `03031–04164` | 604 | Bit identical |
| Trailing allocation padding | `04165–05777` | 907 | Bit identical |

**All 527 application words match literally**, with no runtime fixups.
Across both zones **2047 of 2048 words match**. Only `02010.L`, a value filled
by the loader, differs. The right half of that word, the initial stack/free
address `04165`, is identical. The builder rejects any other difference or
changed placement. Application and runtime words are not patched after linking;
the dump is padded with zeros to the original catalog extent.

## Reconstruction details

BOX was built with PMD and bounds checks disabled (`p-,t-`), but stack checks
remain. No original identifier table survives. Names of the shared command-line
reader, lexer, comparison and numeric-input routines follow their counterparts
in MTD. Other names, types and labels are reconstructed. The unused numeric
reader and its nested `DIGIT` / `DECODE` functions are included.

`o-` retains historical loads after stores; `S3` and comment padding reproduce
check line numbers. Empty labels preserve instruction packing, ordinary calls
and unreachable return words. KOI-8 literals retain the original Cyrillic
bytes; literal question marks use `_077`.

A compiler correction is needed for the `ПРО` command's raw `3,VTM,71717B`.
Previously the object loader treated its immediate operand as a local code
address and linked it as `33731`. The BESM parser now creates an absolute
symbol for large numeric VTM operands through the existing immediate-operand
helper. The final instruction remains `16471717`.

The private library reuses the MTD/COMP/MORE recovery builders and Monitor
sources. BOX's P- variant replaces the unused PMD module with a five-word
stack-state common at `03674`; P/SC's two state references point there.
P/HT's callback common is placed after P/RC, at `04164`. The resulting 604-word
runtime matches its original words, including the conversion tables.

The three user globals are the separator set (`02732`), lexeme length
(`02733`) and command ALFA (`02734`). `НОВКАТ` scans the table at `00020`,
uses the following word's low 18 bits as the disk exchange descriptor, and
constructs a 1024-word catalog in `074000–075777`. After confirmation it sets
word 0 to `7760000000000001`, words 2 and 512 to 1, and performs `Э70` with
page 30. This describes the recovered code; creation of a catalog has not
been exercised interactively.
