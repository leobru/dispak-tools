# COMP ERROR disassembly

[error.madlen](error.madlen) covers COMP `07036–07240`, inclusive: 131 words.
The entry name comes from COPY's `ERROR(KO,TOШ)` call. All addresses and machine
constants below are octal unless explicitly marked decimal.

| COMP range | Contents | Words, decimal |
|---|---|---:|
| `07036–07053` | Instructions | 14 |
| `07054–07104` | Status/message-address table | 25 |
| `07105–07230` | Messages terminated by LF | 84 |
| `07231–07234` | Masks, spaces, LF | 4 |
| `07235–07240` | Default message | 4 |

## Calling sequence and instructions

The observed interface is consistent with a procedure taking an integer status
and a destination passed by reference. The original formal declaration remains
unavailable. On entry A holds the destination address and the stack holds the
status. Register numbers in the following explanation are **Madlen decimal**:

- `07036`: M8 receives the module base. `STI 14B` puts the destination in M12
  and pops the status into A. `07037` saves it at stack offset 3.
- `07037–07043`: M14 starts at -24 decimal. The loop scans 25 entries ending
  at `07104`, comparing `(status << 24)` against each entry under the high-half
  mask. A match branches to `07045`; exhaustion selects `07235`.
- `07045`: `WTC` reads the matched table word, and its following `VTM` loads
  the message pointer into M14.
- `07046–07053`: copy words to the buffer at M12. For each source word `w`,
  store `w OR ((w + six_spaces) AND byte_high_bits)`. On these text bytes this
  sets bit `0200` for the KOI-7 Cyrillic characters while retaining ASCII bytes.
  The low byte is compared with LF (`012`). Return through M13 after copying
  the word containing LF; otherwise increment both pointers and continue.

Thus the destination receives the message including its terminating LF and
any padding within that final word. The routine does not clear the rest of the
84-character destination. Its scratch storage is on the caller's stack; there
are no writable data cells inside this module.

The text copy uses the byte mask at COMP `20027`, represented by
`DBPASC+25B`. It does not call `DBENTER` or `DBLEAVE`.

The table format is `(status << 24) | message_address`. Madlen emits each
pair using an `ATX` high half and a `Z00` address half, following the existing
runtime's address-table convention. These pairs are data, not executable
instructions. Each address half has a 15-bit linker relocation.

## Decoded messages

Status values are shown in decimal and octal. Display padding is omitted below,
except for the unusual internal gap in status 1, which exists in the binary.
The Madlen source preserves all bytes, including padding and LF, using `ISO`.

| Status, decimal | Octal | Message address | Text |
|---:|---|---|---|
| 0 | `0` | `07105` | Five spaces, then LF |
| 1 | `1` | `07106` | `ТОМ НЕ УСТАНО     ВЛЕН` |
| 2 | `2` | `07112` | ТОМ ЗАНЯТ |
| 3 | `3` | `07114` | ВИРТ. НОМЕР ЗАНЯТ |
| 4 | `4` | `07117` | НЕТ ЛОГ. ИМЕНИ БИБЛИОТЕКИ |
| 5 | `5` | `07124` | ЛОГ. ИМЯ БИБЛИОТЕКИ УЖЕ ЕСТЬ |
| 6 | `6` | `07131` | НЕДОПУСТИМОЕ РАСШИРЕНИЕ |
| 7 | `7` | `07135` | НЕТ МЕСТА В АРХИВЕ |
| 8 | `10` | `07141` | НЕТ ФАЙЛА |
| 9 | `11` | `07143` | ОШИБКА В ПАРАМЕТРАХ |
| 10 | `12` | `07147` | ВИРТ. НОМЕР ПУСТ |
| 11 | `13` | `07152` | УЖЕ ЕСТЬ ТАКОЙ ФАЙЛ |
| 12 | `14` | `07156` | НЕКОРР. ДЛИНА ФАЙЛА |
| 13 | `15` | `07162` | КАТАЛОГ ИСПОРЧЕН |
| 14 | `16` | `07165` | НЕТ МЕСТА В КАТАЛОГЕ |
| 15 | `17` | `07171` | НЕТ ФАЙЛОВ ДЛЯ ШАБЛОНА |
| 16 | `20` | `07175` | ОШИБКА В СДВИГЕ |
| 41 | `51` | `07200` | ТАКОГО ИМЕНИ НЕТ |
| 42 | `52` | `07203` | НЕВЕРНОЕ ИМЯ ОБЛАСТИ |
| 48 | `60` | `07207` | ОБЛАСТЬ ЗАНЯТА |
| 50 | `62` | `07212` | НЕ УСТАНОВЛЕН ТОМ |
| 54 | `66` | `07215` | ОШ. В НОМЕРЕТОМА |
| 59 | `73` | `07220` | НЕТ ПОЛНОМОЧИЙ |
| 60 | `74` | `07223` | ОБЛАСТЬ/КАТАЛОГ |
| 66 | `102` | `07226` | ВИРТ. НОМЕР ЗАНЯТ |

An unlisted status selects `07235`: **НЕДОПУСТИМЫЙ КОД ОТВЕТА**.

## Independent copies and relocation

The complete 131-word region agrees after relocation in eight volume-4001
images. There are six instruction relocations and 25 table-pointer relocations.
The generator reconstructs and compares all 131 words for every accepted copy.

| Image | Loaded ERROR entry |
|---|---|
| `0002-monitr-pascal` | `04573` |
| `0023-kanal` | `05266` |
| `0030-proz` | `05544` |
| `0051-print` | `06556` |
| `0075-recod` | `05316` |
| `0101-mtcopy` | `04406` |
| `0106-copy` | `03736` |
| `0315-comp` | `07036` |

Regenerate the Madlen and the `ERROR` section of
[relocations.json](relocations.json) with `python3 runtime/file-access.py`.
The JSON also records decoded messages and the default text. This addition has
been disassembled and compared across images; the earlier
[assembly.json](assembly.json) records the preceding four-module build.

## Equivalents outside the eight copies

An expanded search of all 34 inventoried `.bin` files found two additional
equivalents. It uses the 14-word instruction structure, independent message-byte
searches, and the packed status/address table pattern. The other 24 inputs have
no equivalent found by these searches; this does not exclude a completely
different implementation with different text and code structure.

| Image | Entry | State | Table entries, decimal | Module words, decimal |
|---|---|---|---:|---:|
| `0063-fprint` | `05420` | Complete equivalent | 22 | 121 |
| `0034-more` | `03765` | First 11 instruction words survive | Expects 22 | Incomplete |

FPRINT's complete range is `05420–05610`. Its 14 instruction-word opcode
patterns equal COMP's. The loop bound, table-end offset, mask offsets, and
relocated addresses account for the different layout. All 22 selected messages,
including their original padding, are byte-identical to the corresponding COMP
messages. The default text and conversion algorithm are also shared.

MORE has the same 22-entry loop bound and relative layout parameters as FPRINT.
Its following `04000–05777` address interval is entirely zero. This is already
true of logical zone `0035` in the original volume 4001, so the absent code and
table were not lost by extraction. The fragment identifies the smaller family;
it cannot establish the missing messages or the full implementation.

### Which revision looks later?

**The 25-entry family shared by COMP and the other seven complete matches is
the likely later revision.** Compared with FPRINT, its table adds:

| Status, decimal | Octal | Text | Evidence in FPRINT |
|---:|---|---|---|
| 14 | `16` | НЕТ МЕСТА В КАТАЛОГЕ | Text exists at `05544`, but has no table entry |
| 15 | `17` | НЕТ ФАЙЛОВ ДЛЯ ШАБЛОНА | Neither entry nor text found |
| 16 | `20` | ОШИБКА В СДВИГЕ | Neither entry nor text found |

The larger revision makes the existing status-14 message selectable and adds
two messages, retaining all 22 shared messages unchanged. Three extra table
words and seven extra text words explain the ten-word size increase exactly.

This is a relative ordering inferred from the extension, not a dated release
history. A deliberately reduced build cannot be excluded. No date string was
found inside the complete ERROR regions. COPY's source-deck date, 08.02.89,
does not date its linked ERROR revision. The eight larger-family copies are
identical after relocation and supply no basis for ranking one above another.

Regenerate the search evidence with:

```sh
python3 runtime/file-access.py
python3 runtime/error-variants.py
```

[ERROR-VARIANTS.json](ERROR-VARIANTS.json) inventories all inputs, matching
groups, decoded messages, text and table search hits, the missing MORE code,
and the source-volume hash and zero-zone observation. The grouping retains
relative operands and data bytes while normalizing only absolute code addresses
and table pointers.
