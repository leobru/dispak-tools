# АСС2: overlay 1 and its lost zone

The tools of this directory mirror those of [АСС3](../acc3/README.md):
`family.py` extracts the parts, `ovtry.py` builds an overlay source in the
original layout and compares it (`ctx.py` and `pooldiff.py` show a place
or the pool), `ov1.pas` is the recovered overlay 1. `zone.py` rebuilds the
lost zone, `elf.py` runs the restored АСС2; `verdiff.py` and `famctx.py`
compare the four builds of the family, `compare.py` АСС2 with its
2248 build zone by zone.

```
python3 programs/acc2/family.py
cd programs/acc2; python3 ovtry.py ov1 ov1.pas --full
python3 programs/acc2/zone.py
python3 programs/acc2/elf.py [--probe]
```

АСС2 (4001/0215) is the compatibility-mode build of the same program;
`family.py` extracts it, АСС3 and the earlier builds АССЕМБЛЕР.РЕЖИМ3
(2248/2500) and АССЕМБЛЕР.РЕЖИМ2 (2248/2440) into
`build/acc-family/<name>/{head,ov1,ov2}.bin`. Zone 0225 of the
file (overlay 1, addresses 14000–15777) reads as zeros on the volume, so
АСС2 aborts (ПЕРЕПОЛНЕНИЕ АУ at 16030) on any source.

`ov1.pas` is overlay 1 of АСС2: the text of АСС3's
[ov1.pas](../acc3/ov1.pas) with the
48-bit changes (globals h0050..h0054 before g0050, octal printing, limits
48 and 6 characters, the `'K'` and `'Ч'` constants, handler 401) found
front to back outside the zone. All surviving user code (04014–17346)
and the whole constant pool agree word for word (`ovtry.py ov1`);
the alignments of p10442 and of the `'K'` branch of p11151 come from
empty labels.

Inside the zone the 20 directive handlers p14337..p16336 are АСС3's. The
two 2248 builds have line numbers (`уиа n(М16)`) but no PMD; `verdiff.py`
compares any two of the four builds with pool operands replaced by their
values and the globals moved (`--m1 0:5`; `--map` prints aligned
addresses), `famctx.py` lists them side by side. In the area of the zone
РЕЖИМ2 differs from РЕЖИМ3, apart from line numbers and two globals that
do not follow the shift by 5 (an `уиа 617(М6)` and the `мода 1055(М1)` of
p15700, one word lower in РЕЖИМ2), in
- the field positions of p14406 (28, 21, 20, 32, 29 → 20, 16, 15, 24,
  21): taken over;
- p15152 (directive 297), absent from РЕЖИМ2: kept, since АСС2 has a
  handler of its size at its entry;
- the end of p15251, which АСС3 rewrote: АСС3's kept (same size);
- `'_044'` for `'_043'` in p15565: the pool of АСС2 has no 044 at that
  place, so `'_043'` is kept.

Checks: the case table of p17204 (17007–17044) gives the entry of every
handler in the zone, and all agree with the build; the constant pool
agrees word for word (`pooldiff.py` aligns pools); the surviving words
next to the zone agree; every global the zone uses is used by the
surviving code as well, so its place (АСС3's + 5) is confirmed.

`zone.py` takes the zone from the build: it aligns the built and the
original code, translates every long address (user code in place, the
externals xNNNNN through an alignment of the АСС3 and АСС2 runtimes, the
rest by the address pairs of the surviving code) and writes
`zone0225.bin`, `ov1-restored.bin` and `all-restored.bin` under
`build/acc-family/acc2`.

`elf.py` writes the restored file into a private copy of 4001 and
runs `$АСС2` of ЭЛФ.ТЕКСТ (the .ЭЛФ deck of ппуск.txt, `jobs/elf-4001.b6`
of re-dvs without the linking): it runs to the end and writes ЭЛФ.МОД
equal to the one on the volume in all words except the user code and
date of the header and the low 16 bits of the words (070707 on the
volume, 0 now). A fresh АСС3 run of ПРОЦ.ТЕКСТ leaves the same zeros
where ПРОЦ.МОД has 070707, so they come from the environment, not from
the zone. `elf.py --probe` puts an `Э74` at each handler entry in
turn: ЭЛФ calls p14337, p14626, p14645, p14665, p14676, p15152, p15251,
p15472 and p16336; p14371, p14406, p14502, p15022, p15061, p15565,
p15631, p15700, p15753, p16012 and p16022 (and so the field positions
of p14406) are checked only by the entries, the pool and the sizes.

## Comparison with АССЕМБЛЕР.РЕЖИМ2 (2248/2440)

The compatibility-mode assembler occupies **4001/0215–0254**. Its proposed
donor is **2248/2440–2477**. Both allocations contain 32 zones, with a Pascal
head and two overlays. Addresses and zone numbers below are octal; counts
are decimal.

Copying the corresponding zone of this build does not restore zone 0225:
it is a different revision, and its code does not line up even after
relocation. The zone was rebuilt from `ov1.pas` instead (above); the 2248
builds supplied the 48-bit changes of the handlers (`verdiff.py`).

### Layout and damage

| Part | 4001 loaded zones | 2248 loaded zones | 4001 pool | 2248 pool |
|---|---|---|---|---|
| Head | 0215 | 2440 | 02031 | 02025 |
| Overlay 1 | 0221–0232 | 2444–2454 | 17354 | 16711 |
| Overlay 2 | 0235–0251 | 2460–2474 | 30540 | 27072 |

Loaded lengths come from the P/BOOT count words, including each overlay's
first zone. The remaining allocated zones are not part of those loaded
extents; they must not be interpreted as continuations of the code.

Zone **0225** is entirely zero: **1024 words**, corresponding to overlay 1
addresses **14000–15777**. It is inside the loaded application code. The
same relative zone on 2248 is **2450**, but its code does not line up.

Between address 04014 and the pool, overlay 1 has 5856 words on 4001 versus
5565 on 2248, a difference of 291 words. Overlay 2 has 10580 versus 9774,
a difference of 806 words. These are layout counts, including startup code;
the missing zone is included in the 4001 count.

### Evidence of different revisions

- The head and both overlays contain `ACCEMБЛEP  Э1-KБ` on 4001 and
  ` BK ЭЛЬБPYC 1-KБ` on 2248, decoded as KOI-8.
- The 4001 diagnostic table includes `ФAЙЛOBAЯ CИCTEMA HEДOBOЛЬHA` and
  `HEДOПYCTИMAЯ BЛOЖEHHOCTЬ ФAЙЛOB`; the 2248 table proceeds directly
  from the unimplemented-feature diagnostic to table overflow. Other
  diagnostics have changed wording or membership as well.
- Surviving code has extensive matching opcode sequences, but procedure
  sizes, global offsets, constants, runtime addresses, and directive
  dispatch tables differ. Matching opcodes alone is not proof that the
  operands or semantics can be copied.
- For example, 4001 procedure 13755 has a matching body prefix in 2248
  procedure 13422. The global-offset pair 1042/1045 becomes 776/1001;
  the argument following the closing-parenthesis literal is 7 versus 5.
  The corresponding branch destination is 14001 versus 13450. Thus even
  immediately at the erased boundary, there is no single relocation delta.
- The intact 4001 dispatcher at 17007–17051 retains branch destinations
  into the missing area, including 14007, 14024, 14120, 14244, 14263,
  14303, 14314, 14440, 14477, 14570, 14667, 15110, 15203, 15247,
  15316, 15371, 15430, 15440 and 15754. A surviving call also targets
  15703. These constrain routine boundaries but do not supply their words.
- A search of the complete physical 2248 payload found no exact 16-word
  copies of the surviving 4001 blocks beginning at 12000, 13740, 16000,
  and 17000. This is a bounded anchor search, not proof that no smaller
  fragments occur elsewhere.

The additional file diagnostics suggest that 4001 is a later revision;
this is an inference, not a recovered version date.

### Reproduce

```sh
python3 programs/acc2/compare.py
```

[comparison.json](comparison.json) records layouts, every zone's nonzero
word count, same-offset literal matches, and the full-volume anchor search.
Equal zero words are reported separately from meaningful nonzero matches.
Extracted binaries stay under `build/acc2/compare/`; `besmtool`
recreates them from the source volumes. Both source volumes are read-only
inputs, and no whole-volume hashes are computed.
