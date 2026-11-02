# ПАК and БРЕГЕТ: disassembly

Zones **2053/0713–0714** hold two BEMSH programs in one image loaded at
0–03777. rukava.be calls them «КАТАЛОГ БРЕГЕТ (ПАК) (СТ. ПАСПОРТ 99)».
The selector in zone 0616 reads both zones with parameter 1 and jumps
to address 1.

[breget.be](breget.be) is the commented source. It was first produced
by `../../tools/disbesm6 -s -a0 -e1 -n breget.sym breget.bin` and
`../../py/relabel.py`. Then these were fixed by hand:

- numbers that disbesm6 had taken for labels (`слиа 1(М12)`, the
  shifts 8…48 in `ptab`/`putw`, offsets into the catalog pages);
- `мода` fillers after each `пб` of `sectab`;
- the zeros of the buffer collapsed into `line пам 879`;
- `экв` names for the resident cells that БРЕГЕТ reads with Э65;
- numeric constants written as `в'…'` rather than as text.

After that the `.be` itself is the source.
[breget.sym](breget.sym) keeps the names. The names in ПАК are
invented; those in БРЕГЕТ come from `re-dispak/breget.sym`.

```sh
make breget      # assemble with ГП (НАЗ 1) and compare with the zones
make breget.bin  # dump the two zones
```

`make breget` runs `../../arfa/zongp.pl` and compares the result with
`../../arfa/textdump.sh 2053 0713 2 1856 2` (lines 2–1856 are words
1–03477). `textdump.sh` now takes the number of zones as an optional
fifth argument. The assembled program is identical to the zones word
for word.

`../../py/cmpdd.py breget.gold breget.be.silver` lists the differing
words if the comparison fails.

[breget.b6](breget.b6) runs ПАК under dispak: a loader at 04000 reads
both zones from drive 41 (2053) and jumps to 1. On the 2053 image it
prints the heading (`К А Т А Л О Г  dd.mm.yy  В Р Е М Я  hh.mm.ss`)
and all four sections with their column headings. The catalogs on that
image are empty, so no job lines appear, and every total is zero. The
run takes under a second.

## ПАК (1–02777)

ПАК prints the input catalog of the OS. It reads zones 0545–0547 of
device 041 into 04000–11777:

- 0545 is the small catalog («каталог шифров и зон ввода»), one word per
  job, at 04000 for catalog 1 and 04400 for catalog 2;
- 0546–0547 are the big catalog, 8 words per job, at 06000 and 010000.

The output has a heading with the date (Э50 '114') and the time (Э53
'10'), then these sections:

| Digit of `secord` | Section | Selection |
|---|---|---|
| 1 | ЗАДАЧИ В РЕШЕНИИ | each used entry of catalog 1 with bit 31 of word 6 |
| 2 | ЗАДАЧИ В КАТАЛОГЕ 1 | the chain through word 7 of catalog 1, jobs not in solution |
| 3 | ЗАДАЧИ В КАТАЛОГЕ 2 | the same for catalog 2 |
| 4 | ЗАДАЧИ С РАЗДЕЛОМ <ЖДЕМ> | catalog 1 jobs with bit 32 of word 6 and without bit 16 of word 5 |
| 0 | ИТОГО ЗАКАЗАНО ВРЕМЕНИ ЦП | end of the job |

Every section ends with the CPU time ordered by its jobs. A job line has the columns of the heading: N, ВК, БЮД,
ШИФР, ФИО (Э50 '104'), ПРИО, ВР.ВВОДА, ТЕР, Ф, ЗАК.ВРЕМ, ТРА, Э, NК,
ЗАКАЗ МЛ/МД, СП, А, ОЗУ. The routines are named after the column
headings. Which catalog field each column shows was read from the code
and not checked against the OS. Some fields are taken differently
when М16 after Э50 '165' (the OS version) is 0402, which is 102 if М16
is binary-coded decimal, as the extracode manual says.

The lines collect in a buffer from 01221 and are printed with Э64 when
it reaches 03740. Before that, the buffer overwrites БРЕГЕТ.

Oddities of the original:

- If bits 32–25 of the job's own шифр (Э50 '100') are not zero, `secord`
  is masked with `m374`, which would leave sections 1 and 2. The result
  is never stored (`nxtsec` loads `secord` again), so all sections are
  printed.
- `ctime` starts with `уиа 14` (word 0454, `0240001600…`). This loads
  M0, so M16 is not cleared. It was probably meant as `уиа (М16)`, as in
  `ctra` and `cozu`.

## БРЕГЕТ (03000–03477)

These words are the same as `re-dispak/breget.bin`. БРЕГЕТ reads the
console switch registers (Э61) and does one of three things:

- If bit 2 of the third switch register is set and the resident cell
  ВРЕМЯ (01345) is in the window [МИНВРЕ, МАХВРЕ), it looks for volume
  МД2054 in the tables ТЗНМЛ and ТЗНМД (0623–0763; the addresses of the
  resident cells are from `re-dispak/disp70.lst`). If the volume is
  there, it forms a job with Э50 '7701'. The job reads zones 0510 and
  0521 of drive 30 (2054) into 02000–05777 and jumps to 02000. If the
  volume is missing, it shows «3 ПОСТАВЬ МД» on the console (Э71),
  pauses and looks again.
- Otherwise, if bit 3 of that register is set, it ends.
- Otherwise it prints an АЦПУ test, a table of the tracts of the drums
  МБ 10–27 and «СИСТЕМА ВЫЗВАНА С ТРАКТА nn МБ nn». Tracts are marked
  by the bits of words 0710–0727. Those words are presumably filled by
  Э72 with bits 48–43 = 071, which the extracode manual does not list.
  The tract and drum in the last line come from physical cell 7,
  presumably the boot tract.

Cells 04652–04655 of the job's memory replace the window, the pause and
the volume number. Two things were not found:

- where the values in those cells come from;
- what loads БРЕГЕТ with entry 03000. The ПАК selector enters at 1, and
  «СТ. ПАСПОРТ 99» was not traced.

The constants ЗПЗ710…ТНЕТОБ are not used.
