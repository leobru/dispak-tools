% Recovered nested scanner of READJOB (03717). The READJOB driver
% below remains a compilation harness; it does not parse a link job.
procedure READJOB;
var CH, SAVED: char;
    LINENO, FIRSTCOL, LASTCOL, COLUMN: integer;
    l11, l12, l13, l14, l15, l16: integer;
    CLASS: charclass;
    VALUE: token;
    l22, l23: integer;
    KIND: tokentype;
    PUSHED: boolean;
    l26, l27, l30, l31, l32, l33, l34, l35, l36, l37: integer;
    LINEBUF: packed array [1..120] of char;
    l64: integer;

% 02426. Preserve the common GET even when returning a saved character.
procedure NEXTCHAR;
begin
  if PUSHED then begin
    CH := SAVED; PUSHED := false;
  end else if eoln(input) then CH := '_037'
  else if eof(input) then begin
    CH := '_012';
    LINEBUF[COLUMN] := CH;
    COLUMN := 0;
    LINENO := LINENO + 1;
  end else begin
    CH := input@;
    LINEBUF[COLUMN] := CH;
  end;
  if CH <> '_037' then begin get(input); COLUMN := COLUMN + 1 end;
  CLASS := XLATTAB[CH];
end;

% 02463. Message selection is inserted from the image's ISO literals.
procedure BADJOB(ERROR: integer);
var I, LIMIT: integer;
begin
  writeln('* * *  OШИБKA B ЗAДAHИИ KOMПOHOBЩИKY * * *');
  write('CTPOKA ', LINENO:1, ' : ');
  case ERROR of
    0: writeln('OШИБKA B ЦEЛOM');
    1: writeln('HEДOПYCTИMЫЙ BИPTYAЛЬHЫЙ HOMEP');
    2: writeln('HEДOПYCTИMЫЙ HOMEP ЗOHЫ');
    3: writeln('HEBEPHAЯ ДЛИHA ФAЙЛA');
    4: writeln('OTCYTCTBYET ДЛИHA ФAЙЛA');
    5: writeln('BCTPETИЛCЯ KOHEЦ BBOДHOГO ФAЙЛA');
    6: begin COLUMN := COLUMN + 1;
      writeln('HEДOПYCTИMЫЙ CИMBOЛ') end;
    7: writeln('HEBEPHЫЙ PAЗДEЛИTEЛЬ');
    15: writeln('HEДOПYCTИMЫЙ OTЛAДOЧHЫЙ ФЛAГ');
    8: writeln('HEДOПYCTИMЫЙ PEЖИM ПEЧATИ');
    10: writeln('ФAЙЛ HE OПPEДEЛEH');
    11: writeln('OTCYTCTBYET PAЗДEЛ ''ФAЙЛЫ''');
    12: writeln('HEДOПYCTИMAЯ KOMAHДA');
    13: writeln('ПOBTOPHOE OПPEДEЛEHИE BЫXOДHOГO ФAЙЛA');
    16: writeln('ЗAПPEЩEHHЫЙ KBAЛИФИKATOP ФAЙЛA');
    17: writeln('HEДOПYCTИMЫЙ KBAЛИФИKATOP ФAЙЛA');
    9: writeln('HET OБ''EKTHЫX ФAЙЛOB');
    14: writeln('HEДOПYCTИMЫЙ KBAЛИФИKATOP CEГMEHTA');
    18: writeln('HE OПPEДEЛEH BЫXOДHOЙ ФAЙЛ');
    19: writeln('HAPYШEHA ПOCЛEДOBATEЛЬHOCTЬ ПAPAMETPOB');
    20: writeln('AДPEC ЗAГPYЗKИ БOЛЬШE MAKCИMAЛЬHO ДOПYCTИMOГO');
    21: writeln('AДPEC HA ДИCKE БOЛЬШE MAKCИMAЛЬHO ДOПYCTИMOГO');
    22: writeln('ДЛИHA CEГMEHTA БOЛЬШE MAKCИMAЛЬHO ДOПYCTИMOЙ');
    others: writeln('OШCИC=', ERROR:1, '!!!')
  end;
  if CH <> '_037' then begin
    LASTCOL := COLUMN - 1;
    while CH <> '_012' do NEXTCHAR;
    COLUMN := 1;
    while LINEBUF[COLUMN] <> '_012' do begin
      write(LINEBUF[COLUMN]); COLUMN := COLUMN + 1;
    end;
    writeln;
    if FIRSTCOL >= LASTCOL then LASTCOL := COLUMN;
    for I := 2 to FIRSTCOL do write(' ');
    LIMIT := LASTCOL - 1;
    for I := FIRSTCOL to LIMIT do write('^');
    writeln;
  end else writeln('<EOF>');
  besm(0740000B);
end;

% 03335's helpers are nested one level deeper than BADJOB/NEXTCHAR.
procedure GETTOKEN(EXPECT: bitset);

% 02752.
procedure PUSHCHAR(C: char);
begin
  SAVED := CH; PUSHED := true; CH := C; CLASS := XLATTAB[CH];
end;

% 02761.
function INNAME(C: charclass): boolean;
begin
  INNAME := C in [letter, digit];
end;

% 02765.
procedure SKIPWS;
begin
  while CLASS = white do begin NEXTCHAR; (q); end;
end;

% 02775.
procedure SKIPTAIL;
begin
  while not (CLASS in [white, punct, atend]) do begin
    NEXTCHAR; (q);
  end;
end;

% 03034. Numeric suffixes H/B/З/C/Д select hex, octal, 1024-scaled
% octal, 256-scaled octal and decimal. Unsuffixed numbers are octal.
procedure SCANINT(var RESULT: integer);
var COUNT, I, DIGIT, SCALE: integer;
    BUFFER: array [1..12] of char;
    TAIL: char;
    LIMIT: integer;

% 03006.
  function CONVERT(BASE: integer): integer;
  var I, ACCUM, LIMIT: integer;
  begin
    ACCUM := 0;
    LIMIT := COUNT - 1;
    for I to LIMIT do begin
      DIGIT := ord(BUFFER[I]) - 48;
      if (DIGIT < 0) or (DIGIT >= BASE) then BADJOB(0);
      ACCUM := ACCUM * BASE + DIGIT;
    end;
    CONVERT := ACCUM;
  end;

begin
  COUNT := 1;
  repeat
    if COUNT > 12 then BADJOB(0);
    BUFFER[COUNT] := CH;
    COUNT := COUNT + 1;
    NEXTCHAR;
  until CLASS in [white, punct, atend];
  COUNT := COUNT - 1;
  TAIL := BUFFER[COUNT];
  RESULT := 0;
  SCALE := 1;
  if TAIL = 'H' then begin
    LIMIT := COUNT - 1;
    for I to LIMIT do begin
      DIGIT := ord(BUFFER[I]) - 31;
      if DIGIT in [17..26] then DIGIT := DIGIT - 17
      else if DIGIT in [34..39] then DIGIT := DIGIT - 34 + 10
      else BADJOB(0);
      RESULT := RESULT * 16 + DIGIT;
    end;
  end else if TAIL = 'B' then RESULT := CONVERT(8)
  else if TAIL = '_372' then begin
    SCALE := 1024; RESULT := CONVERT(8);
  end else if TAIL = 'C' then begin
    SCALE := 256; RESULT := CONVERT(8);
  end else if TAIL = '_344' then RESULT := CONVERT(10)
  else begin COUNT := COUNT + 1; RESULT := CONVERT(8) end;
  RESULT := RESULT * SCALE;
end;

% 03153. Decimal parser used where the grammar requests decimal input.
procedure SCANDEC(var RESULT: integer);
var COUNT: integer;
begin
  COUNT := 0; RESULT := ;
  repeat
    RESULT := RESULT * 10 + ord(CH) - 48;
    COUNT := COUNT + 1;
    if COUNT > 12 then BADJOB(0);
    NEXTCHAR;
  until CLASS <> digit;
end;

% 03176.
procedure SCANNAME;
var I: integer;
begin
  with VALUE do begin
    first6 := '      '; last6 := '    _000_000';
  end;
  I := 1;
  while INNAME(CLASS) and (I <= 10) do begin
    VALUE.text[I] := CH;
    I := I + 1;
    NEXTCHAR;
    (q);
  end;
  SKIPTAIL;
  if CH = '.' then begin NEXTCHAR; SKIPTAIL end;
end;

% 03230. Packed disk address: virtual drive 16..55, zone 0..3995.
procedure SCANFILE;
var ADDRESS, UNIT, ZONE: integer;
begin
  SCANINT(ADDRESS);
  UNIT := ADDRESS div 4096;
  ZONE := ADDRESS mod 4096;
  if (UNIT < 16) or (UNIT > 55) then BADJOB(1);
  if ZONE > 3995 then BADJOB(2);
  VALUE.disk.address := ADDRESS;
  SKIPWS;
  if CH = ':' then begin
    NEXTCHAR; SKIPWS;
    if CLASS = digit then begin
      SCANINT(ADDRESS);
      if ADDRESS > 127 then BADJOB(3);
      VALUE.disk.length := ADDRESS;
    end else BADJOB(4);
  end else VALUE.disk.length := 127;
end;

% 03312.
procedure SCANALFA;
var I: integer;
begin
  VALUE.a6 := '      '; I := 1;
  repeat
    VALUE.text[I] := CH;
    NEXTCHAR; I := I + 1;
  until not INNAME(CLASS) or (I > 6);
  SKIPTAIL;
end;

% 03335. EXPECT bits 0..5 select the token representations accepted.
begin
  SKIPWS;
  if CH = '(' then begin
    NEXTCHAR;
    if CH = '*' then begin
      (comment) repeat
        NEXTCHAR;
        if CH = '*' then begin
          NEXTCHAR;
          if CH = ')' then begin NEXTCHAR; exit comment end;
        end;
      until CH = '_037';
      if CH = '_037' then BADJOB(5);
      SKIPWS;
    end else PUSHCHAR('(');
  end;
  FIRSTCOL := COLUMN - 1;
  if CLASS = letter then begin
    if 1 in EXPECT then begin SCANNAME; KIND := kname end
    else if 0 in EXPECT then begin SCANALFA; KIND := kalfa end
    else BADJOB(6);
  end else if CLASS = digit then begin
    if 2 in EXPECT then begin SCANFILE; KIND := kfile end
    else if 3 in EXPECT then begin SCANINT(VALUE.number);
      KIND := knumber end
    else if 4 in EXPECT then begin SCANDEC(VALUE.number);
      KIND := kdecimal end
    else BADJOB(6);
  end else if CLASS = punct then begin
    if 5 in EXPECT then begin
      if CH = '*' then begin
        NEXTCHAR;
        if CH = '/' then CH := '_037' else PUSHCHAR('*');
      end;
      VALUE.symbol := chr(ord(CH) - 31);
      KIND := kpunct;
      NEXTCHAR;
    end else BADJOB(6);
  end else if CLASS = atend then BADJOB(6);
end;

% 03455. Punctuation is represented as ord(character)-31.
procedure EXPECT(PUNCTS: charbits);
begin
  GETTOKEN([5]);
  if not (VALUE.symbol in PUNCTS) then BADJOB(7);
end;

% 03641. Select the listing sections requested by the link job.
procedure PRINTSEL;
begin
  GETTOKEN([0,5]);
  if KIND = kpunct then begin
    if VALUE.symbol in ['_000','_015','_034'] then begin
      PRINTOPT := PRINTOPT + [0..3]; exit;
    end;
    if VALUE.symbol = '_036' then GETTOKEN([0]) else BADJOB(7);
  end;
  repeat
    if VALUE.a6 = 'CEKЦИИ' then PRINTOPT := PRINTOPT + [1]
    else if VALUE.a6 = 'PAЗДEЛ' then PRINTOPT := PRINTOPT + [2]
    else if VALUE.a6 = 'CTAT  ' then PRINTOPT := PRINTOPT + [3]
    else if VALUE.a6 = 'MOДYЛИ' then PRINTOPT := PRINTOPT + [0]
    else if VALUE.a6 = 'METKИ ' then PRINTOPT := PRINTOPT + [4]
    else BADJOB(8);
    EXPECT(['_015','_034']);
    if VALUE.symbol = '_034' then exit;
    GETTOKEN([0]);
  until false;
end;

begin
% Only the scanner's containing frame is built here. READJOB's driver
% and initialization of its working state remain to be recovered.
  LINENO := 0; COLUMN := 1; CH := ' '; PUSHED := false;
end;
