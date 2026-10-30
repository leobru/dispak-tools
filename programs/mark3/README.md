# MARK3: recovery

MARK3 marks ЕС tapes on СВС (Э1-К2) by driving the IOP (ПВВ) directly
(`< ПРОГРАММА РАЗМЕТКИ  М Л = (ВЕРСИЯ ОТ 88/11/02) >`). Its image is on
volume 2113 at zones **1243–1245** (`mark3.bin` in the root) and, the
same, on volume 2153 at zone 0421, from which [run.b6](run.b6) runs it.

[mark3.pas](mark3.pas) is the Pascal part, recovered from the image; the
names are invented. [inp.bemsh](inp.bemsh) is the BEMSH module with the
`fortran` routines E5143, E5165, E5215, E5223 and E5265.

```sh
python3 programs/mark3/build.py
```

The builder runs the original job: BEMSH assembles `inp.bemsh`,
NEWPASC of `mypas.b6` rebuilt on a private volume 77 compiles
`mark3.pas`, and both are linked with the standard library of volume
2113 (PERSO 311160, 320100). PASCODER writes three zones from 02000 to
zone 0421 of a scratch disk on drive 67. The original is dumped
read-only from 2113 into `build/mark3/original.bin`; the build checks
that volumes 2113 and 77 are unchanged.
[reconstruction.json](reconstruction.json) lists every differing word
with its cause; the build fails if one has none. `--explore` writes the
report to `build/mark3` without that check, and `--source` builds
another text.

Result:

| Region | Words | Identical |
|---|---:|---:|
| stub 02000–02011 | 10 | 0 |
| code 02012–04114 | 1091 | 1091 |
| constants 04115–04506 | 250 | 250 |
| globals and files 04507–04754 | 166 | 148 |
| library 04755–05572 | 398 | 362 |
| above FREE 05573–07777 | 1157 | 114 |

- The user code, the constant pool and the globals are the same word
  for word.
- The original was linked with another version of the library: the
  PASCODER stub (exchange words and zone count), 18 library constants
  of P/1D and parts of the library differ.

The source uses `(*=o-*)`: the compiler of the original kept the load
right after a store and kept all constants in one table, with its
replications. The one load it did not repeat is written as an
accumulator assignment, `g40z.a[5] := ;`. The file initialization
(no `s5`) is the code before the main program (03477–03511).
