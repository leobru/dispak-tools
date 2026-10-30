# АРАП: recovery

АРАП is the program in the catalog of volume 2248 at zones **2600–2601**
(`АРАП /999999`, two zones). `parse` dispatches the directive lines of
its input: `B` insert, `З` replace, `T` translate, `Ф` set the file;
`rd` reads zones into page 36 and `wr` writes them from page 37.
Addresses and zones are octal.

[arap.pas](arap.pas) is the Pascal source recovered from the memory
image. The names are invented.

```sh
python3 programs/arap/build.py
```

The builder compiles `arap.pas` with `mypas.b6` rebuilt on a private
volume 77 and links it with the standard library of volume 2113 (PERSO
311160, 320200) and the original P/BOOT stub (`DTRAN /01.06.84/`).
PASCODER writes two zones from 02000 through drive 37, as in the
original job. The original is dumped read-only from 2248 into
`build/arap/original.bin`; the build checks that volumes 2248
and 77 are unchanged. [reconstruction.json](reconstruction.json) lists
every differing word with its cause; the build fails if one has none.
`--explore` writes the report to `build/arap` without that check, and
`--source` builds another text.

Result:

| Region | Words | Identical |
|---|---:|---:|
| stub 02000–02010 | 9 | 8 |
| code 02011–03326 | 718 | 597 |
| constants 03327–03476 | 104 | 104 |
| globals and files 03477–04002 | 196 | 195 |
| library 04003– | 473 | 45 |

- The code differs in four words, 02626, 02662, 03223 and 03276:
  `pos := pos + 1` and `rdPos := rdPos + 1` add `17(М1)` (the 1 of
  P/1D) instead of a pool constant. No construct of mypas gives that.
  The other 117 differing code words call the library at other
  addresses.
- The original was linked with another version of the library: its
  module set and sizes differ (no P/SC after P/2, for example), and so
  do P/1D[046] and FREE in the P/CODER word 02007.

The source uses `(*=o-*)`: the original compiler kept the load right
after a store. The code has line numbers (`уиа n(М16)` before the
calls), so the `%` lines keep each statement on its line. The final
`пб 76000` (a jump into page 37) is `besm(3076000B)`; mypas keeps such
a long address since this recovery.
