# АСС3: structure of the overlays

АСС3 is the Эльбрус-1КБ assembler (native mode) in the Monitor's system
library on volume **4001**, catalog zones **0132–0171** (040 zones). It is not
one core image but a NEWPASC head and two NEWPASC overlays that run one after
the other in the same memory. Addresses and zone numbers are octal.

`python3 programs/acc3/parts.py` splits the image into `head.bin`, `ov1.bin`
and `ov2.bin` under `build/acc3/`.

## Zone map

| Zones | Part | Loaded at | Loaded by |
|---|---|---|---|
| 0132 | head | 02000–03777 | the Monitor's RUN (stub count 1) |
| 0133–0135 | unused | — | — |
| 0136–0150 | overlay 1 | 04000–31777 | head (first zone), then its own stub (count 013) |
| 0151 | unused | — | — |
| 0152–0167 | overlay 2 | 04000–37777 | head (first zone), then its own stub (count 016) |
| 0170–0171 | unused | — | — |

An `-t` trace of an assembly (`re-dvs/jobs/asm-tables.b6` on a private copy
of 4001) shows exactly these exchanges. The unused zones are never read, and
no zone of АСС3 is written. The unused zones hold fragments of the same
runtime library at other addresses (zone 0133 from 0403 matches overlay 1 at
30116 for 765 words; zone 0151 likewise). They are most likely left over from
earlier builds.

## Head (zone 0132)

The head is the only part the Monitor loads. It occupies 02000–03633: 924
words, 508 of them non-zero.

| Addresses | Words | Contents |
|---|---:|---|
| 02000–02012 | 11 | PASCODER stub; `02006`/`02007` exchange words (drive 040), `02010` FREE = 040000, `02011` count 1 (P/CODER is 02007–02012) |
| 02013–02030 | 14 | main program |
| 02031–02043 | 11 | constant pool (M10) |
| 02044–02113 | 40 | P/1D |
| 02114–03605 | 826 | globals shared with both overlays |
| 03606–03633 | 22 | services: cell-052 read, overlay loader, P/1 |

The main program takes the running file's descriptor from cell 052 (set by
the Monitor's SETDESCR). It keeps the low 18 bits and sets a read of one zone
into page 2 (`0010020000000000`). Then it calls the loader at `03612` with
zone +4, and again with zone +020. The loader does one `Э70` and jumps to
04000. After the second overlay returns, the head ends with `Э74`.

P/1 (`03626`) is the NEWPASC P/1 word for word, with M1 = 02044. FREE =
040000 puts the stack above both overlays.

Globals at 02115–02650 hold message texts. No part stores there; overlay
stores begin at M1+0605 (02651). The texts are therefore initialised data of
the head source. Further initialised words are at 03214–03227 and
03347–03354.

### Head source

`programs/acc3/head.pas` is the recovered source of the head. It is built
and compared with
```
python3 programs/acc3/headtry.py
```
All 1024 words of the zone (02000–03777) match. P/CODER is four words
(02007–02012): `*TABLE:P/CODER(W*400000,L*3,S*40000)` gives the exchange
word for drive 040 and FREE = 040000, above both overlays.

- The options are those of the overlays plus `s5`: there is no file
  initialisation, so the start code is only `пвл P/1(М16); пб main`.
- The main program is
  `besm(630004B); (r); besm(150000B : 0); g1061 := ;`, then
  `g1165 := x03606` and `besm(110000B : 777777C, 150000B :
  0010020000000000C); g1165 := ;` (the mask is applied to the accumulator,
  without a load), then `x03612(g1165 + 4C)`, `x03612(g1165 + 20C)` and
  `besm(740000B)`. The jump after `Э74` is the usual jump to P/E.
- The pool holds the array multipliers 1, 6 and 2 of the shared types and
  the unused `banner` constant, so the head declares the same types as
  the overlays.
- x03606 (`сч 52; пб (М15)`, then three data words) and x03612 (stores the
  exchange word, does one `Э70` and jumps to the loaded code) are
  assembler modules. `headtry.py` builds them from the image words. P/EF
  and P/1 of the current library are the same word for word.
- Initialised data, printed by `programs/acc3/headdata.py` into the
  `.data` section: the 58 messages (`g0051[k] := '...'`, one 36-character
  string each; the head declares `t0` as `packed array [0..35] of char`,
  the overlays, which write a message word by word, as six `alfa`), g0614 and g0617, the 64-word
  table g0724, single words of g1134 and of the `long` records
  g1140–g1146, the days before each month in g1150–g1163, and
  `zh = 1, 2, 3, 4, 8, 16` in the parameter commons. Under `w+` the
  address of `g0051[k]` takes two instructions (error 48), so the source
  sets `w-` before `.data`.
- The program parameters are the overlays' commons za..zk and a 150-word
  zl. It ends where the services begin (03606), and every word up to
  there is zero, so its real length is not known.
- The link puts the head program on the second level, under an empty
  root HROOT that holds the PROGRAM entry. An empty module HCOM
  of the same level declares P/1D, *INPUT* and *OUTPUT* in that order,
  before the program does; the program alone would declare *OUTPUT*
  first.

## Overlays

Both overlays start with an 11-word stub. The entry is at `04013`, not
`04012`, and the FREE word `04010` is 0. Neither overlay has PMD tables or line
numbers: every `уиа n(М16)` loads 0.

| | Overlay 1 | Overlay 2 |
|---|---|---|
| Entry `04013` | pool 17731, start 17724 | pool 31346, start 31341 |
| User code | 04014–17723 (about 6100 words) | 04014–31340 (about 11000 words) |
| Runtime | 22557–31777 (P/2 at 22557) | from 33027 (P/2) |
| Init | 27331, keeps M1 = 02044 | 36246, same code |

Globals are reached as `n(М1)` with offsets up to 01176 in both overlays, so
the three sources declare the same global variables. Overlay 1 also has seven
absolute references into the head's globals (02000–03600); overlay 2 has none.

The runtime is an older library version that is not available as source.
Against current builds, `libmatch.py` finds only P/1, STOP*, PASCHARS and
P/SP. Overlay 1's runtime matches overlay 2's in 2101 of 3729 words, after
relocation, in eight blocks. These relocated copies, and the fragments in
the unused zones, give module boundaries and relocation bits for a
relocatable reconstruction.

## Link layout

The head's P/1D is 02044–03242 (length 01177: the 050 runtime words and the
shared globals). *INPUT* is 03243 and *OUTPUT* 03301. A common follows that
both overlays also have after their *OUTPUT*, initialised differently. It is
a program parameter, like МОНИТР's *TTIO*, and the code reaches it by
absolute addresses.

Each overlay has, after its pool:
- a one-word common (overlay 1: 20537) where the overlay's P/1 saves M17;
- its own *INPUT* (20540) and *OUTPUT* (20576);
- the same parameter common;
- then the runtime.

The overlay's P/1 keeps the head's M1. It sets the program's exit address
(`1(М1)`) to a routine that restores M17 and returns to the head. No copy of
P/1D is in the overlays.

The loader (`sources/dubna/dis705/loader.txt`) accepts a common declaration
only if it is not longer than the block already allocated. It places the
modules of P/BOOT's list level by level, the module with the PROGRAM entry
first. After each level it places the commons declared so far.
`programs/acc3/ovtry.py` reproduces the overlay layout this way:
- P/BOOT declares P/1D with the head's length;
- a 032-word root module holds PROGRAM at 02013, so P/1D lands at 02044;
- a filler reaches 04000;
- OVBOOT there carries the overlay stub and its P/CODER words, and declares
  the stack cell, *INPUT* and *OUTPUT*;
- the overlay program, named by its module name, follows at 04013, and those
  commons come right after it.

## Decompiling overlay 1

`programs/acc3/ov1.pas` is the recovered source. `ovtry.py` builds it with
NEWPASC compiled from `mypas.b6` and compares the user code:
```
python3 programs/acc3/ovtry.py ov1 programs/acc3/ov1.pas --full --pads
```
All of the user code (04014–17723) and the whole constant pool (390 words)
match, except for the differences listed at the end of this section. The
names are invented: the overlay has no PMD tables. Procedures, globals and
locals are named by their address (`p17204`, `g1035`, the driver's locals
`d<offset>`), the externals of the runtime area by their entry (`x23762`).

Structure: the driver p17650 (level 2) holds every other procedure. Its
body initialises the state and calls p17204 for each statement of the
source text, then p17534; the four labels of the driver (17700, 17706,
17707, 17710) are the targets of the `goto`s of the error and end paths.
p17204 (level 3) reads the mnemonic and dispatches by its code: below 256
p14021, 257–301 a `case` over the level-4 procedures, up to 447 p14157.

Tools:
- `annotate.py` and `names.txt` give a listing with pool values, globals
  and runtime names;
- `calls.py` lists the runtime entries the code calls;
- `fields.py` lists packed-field reads and stores;
- `poolstr.py` prints pool strings as literals;
- `skeleton.py` lists the procedures;
- `genvars.py` and `splice.py` generate the shared declarations.

NEWPASC keeps at most 89 external names longer than four letters (error 51
otherwise; pascompl.cc has the same limit). The overlay calls about 65
runtime externals (`x24030` is six letters), and a common block's name gets
a star on each side. Hence the 21 parameter commons are named `za`…`zu` in
address order (`*ZA*` is four letters); `genvars.py --common` prints them
with their addresses.

Established so far:
- The options are `(*=p-,t-,s8,y+,o-,a4,w+*)` (`w+` for items 2-4 and 6
  below); the start code matches mypas.
- The globals at M1 are the same in all three parts (`genvars.py`). The
  message table at 051 is `array [1..58] of array [0..5] of alfa`, which
  gives the multiplier 6 in the pool.
- 20634–22556 are separate common blocks, program parameters after
  *OUTPUT*; the runtime's assembler modules use them too.
- The runtime area holds about 70 `assembler` externals (calls followed by
  `уиа pool(М10)`) and one `fortran` procedure (23460), whose result is
  taken from the accumulator (`x23460(a, b); p := ;`).
- `Э63 4; или 0` is `besm(630004B, 150000B : 0); x := ;`.
- Library: 23146 P/CW, 23150 P/6A, 23473 P/7A, 23510 P/WI, 23575 P/WO,
  23576 P/WH (`write(x:n hex)`), 22600 P/WC, 22773 P/WOLN, 22774 P/WL.

The compiler that built АСС3 differs from mypas in the ways below. MONITR,
COMP and the other matched programs show none of them. Items 2 and 3 save
relocatable expressions, of which the compiler has a limited number.
1. Each `for` statement starts and ends on a word boundary (`мода`
   fillers). So does the jump back of `repeat ... until false`. The
   source puts a structural label `(q)` before each `for` and on the
   bodies that need it (`do (r) _(...`, `while c do (q) ...`,
   `...; (r) until false`). The step of a `for` (the load of the
   variable after the body) and the jump back of a `while` also start
   a word; the source ends such bodies with an empty `(r)`
   (`do _( ...; (r) _)`). Alignment is only ever made by such labels,
   never by mypas.
2. The address of a global is formed as `мода off(М1); уиа|слиа (Мk)`,
   not as an absolute P/1D address (mypas.b6 `P4621`, case
   `l4var4z = indexreg[1]`): for an indexed global in `with`, and for a
   global passed to a `var` parameter (MKNAME, OPENF, x23470, x24156).
   mypas does so under `(*=w+*)`; then the overlay code has no P/1D
   addresses and does not depend on where P/1D is.
3. A boolean value of a scalar `=` or `<>` is computed without jumps:
   `нтж b; счм 025(М1); рзб (М17); чед`, followed by `нтж 8(М1)` for `=`
   (P/1D[025] is 4000000000000000). mypas does so under `(*=w+*)`, also
   for `=` and `<>` of sets. Overlay 2 shows two more forms: an integer
   `<`, `>`, `<=`, `>=` is the sign of the difference (`вч b; и [7];
   чед`), and `c in s` with a constant `c` is `и [c]; чед`. Both keep
   the jumps as the argument of `ord`; an `in` with a variable element
   calls P/IN (06475).
4. A one-element set `[e]` is `сч e; пв P/SS`; mypas adds
   `счм []; или (М17)` unless `(*=w+*)` is set.
5. A constant may be an actual of a `var` parameter of a `fortran`
   procedure; it is passed as the address of its pool word (06413:
   `x23470(..., 0C)` and `x23470(..., 2443270500000000C)`). The third
   parameter of x23470 also takes variables of any type. mypas does both
   under `(*=c-*)`, which the source puts around such calls.
6. A 3-word record assignment is unrolled into three `сч`/`зп` pairs;
   mypas does so for 2 and 3 words under `(*=w+*)`, which the source sets.
7. `shift(x, n)` of an integer by a constant is `сда 64+n`. mypas called
   the undefined helper P/II for it; now it gives the shift. 10637,
   `minel(bitset(shift(r.lw, -32)))` with `lw` a 16-bit integer field, is
   `сда 64-16; счмр; нтж 9(М1); сда 64-32; нед 9(М1)`. A shift by a
   variable is `мод n; сда 64`. Under `(*=w+*)` (overlay 2) any one-word
   value can be shifted, the result has the type of `x`, and an integer
   shifted right or by a variable is ORed with the integer 0 (`или
   '55'(М10)`), which turns a bit pattern into an integer.

A store of 0C without a shift (06653) is not a difference: it is `bs := []`
into a set field, which is left-aligned and needs no shift; reads of the same
bits as an integer (`ba`) belong to another variant of `entry`.

Overlay 1 is the same as the original word for word: all of the user code
and the pool (`ovtry.py ov1 programs/acc3/ov1.pas --full --pads` shows no
differing blocks). A `besm` extracode in a left half needs a `(r)` after it
(p17534 and the driver), else the next instruction lands in the right half,
which an extracode never returns to.

## Decompiling overlay 2

`programs/acc3/ov2.pas` is the recovered source, built and compared the same
way:
```
python3 programs/acc3/ovtry.py ov2 programs/acc3/ov2.pas --full --pads
```
All of the user code (04014–31340) and the pool (650 words, up to the
first common at 32560) match except one word. At 16305 (p16210,
`shift(shift(d81, 48 - m), -(48 - m))`) the original negates by
`знак 20(М1)` (P/1D[024], all ones), mypas by `знак 15(М1)` (-1). The same
original negates `-x34423(d83)` (25127) by `знак 15(М1)`, and no construct
of mypas gives the first form.

Structure: the driver p31255 calls p10275 (start), p16001 and p16210 (the
first pass), p16420 (the module header), then p27034 in a loop
(`3: p27034; goto 3`) until the end statement jumps to label 4. p27034
(level 3) reads the mnemonic and dispatches by its code like p17204 of
overlay 1: below 256 p23147 (machine instructions), 257–301 and 449–454
two `case` statements over the level-4 directive procedures. After the
loop p27254 closes the module, p30443 lists the sections, p27356 the
cross-reference table (sorted by Shell's method) and p31025 the
statistics with the version line `ACCEMБЛEP  Э1-KБ: BEPCИЯ 5.04 OT
10.11.89`.

Notes for the source:
- `exit` leaves the procedure; a loop is left by `exit q` of a labelled
  `(q) repeat`.
- Under `(*=o-*)` mypas keeps a load right after a store, so where the
  original stores the accumulator twice without a load the source has
  `x := ;` (`g0626 := g0626 + 1; vd := ;`).
- A frame slot used with two types is a local variant record
  (`record case integer of 0: (b: hb); 1: (l: @long) end`).
- Under `(*=a4*)` the source character `?` is 031; the original's 077 is
  written `'_077'`, and the codes 0354, 0360, 0372, 0376 as `'_354'` etc.
- Strings longer than about 60 characters go on a line of their own: a
  card has 72 columns.
- `ovtry.py` compares the pool of overlay 2 up to 32560.

АСС2, the compatibility-mode build of the same program, is in
[../acc2](../acc2/README.md).
