(*=y+,o-,b4*)
% Recovered PROZ, volume 4001, zones 0030-0033.
% Build: python3 programs/proz/build.py
% All 1574 application words and all 1709 runtime words match exactly.
% Only the loader descriptor at 02010.L differs in the complete image.
% S3 and comment padding preserve the original PMD source-line numbers.
% The version without line padding is proz-readable.pas.
(*=s3*)
program ПPOЗ(input, output, TTIO);
% Volume 4001, catalog ПРОЗ, zones 0030-0033.
% Names follow the surviving PMD; types and labels are reconstructed.
label 1, 2, 3, 4, 5, 6;
const lf = '_012';
type charset = set of '_000'..'_057';
     line = packed array [1..84] of char;
     bitset = set of 0..47;
     descriptor = packed record
       flags: 0..2097151; length: 0..511; zone: 0..262143
     end;
     word3 = record ext, lib, name: alfa end;
     view = packed record case integer of
       0: (reg: 0..15; op: 0..255; base: 0..255;
           addr: 0..4095; rest: 0..65535);
       1: (reg1: 0..15; op1: 0..255; longaddr: 0..1048575;
           rest1: 0..65535);
       2: (bytes: packed array [0..5] of 0..255);
       3: (chars: alfa);
       4: (value: 0..4294967295; rest32: 0..65535);
       5: (bits: bitset)
     end;
var I, J, HYЗЗЗЗ: integer;
    NAMELIB: alfa;
    CMDLINE [55B]: line;
    FILENAME: line;
    NAME3: word3;
    TEKCT: line;
    FILETYPE: alfa;
    DESCR: descriptor;
    MAXЗOHA: integer;
    ДИP: alfa;
    FORMAT: (CODE, HEX);
    HAЧAЛO, AДPEC, KOHAДPEC, BHYTAДPE, CЛOBO, ЗOHA,
      CЧИTЗOHA: integer;
    PAЗДEЛ: charset;
    ДЛEKC: integer;
    ACTIVELI [3B]: alfa;
procedure READLINE(var F: text); fortran;
procedure ERROR(status: integer; var message: line); assembler;
function LIB(name: alfa; var unitno: integer): integer; assembler;
function MKNAME(var name: line; lib, ext: alfa;
                var dest: word3): integer; assembler;
function OPENF(var name: word3; writing: boolean;
               var dest: descriptor): integer; assembler;
procedure GETCMDLI(var F: text);
var I: integer;
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
begin
  rewrite(F);
  (done) for I := 1 to 80 do begin
%
    if CMDLINE[I] = lf then exit done;
    write(F, CMDLINE[I]);
  end;
  reset(F);
end;
var BUFFER [74000B]: array [0..1777B] of view;
    TTIO: record T0, T1, T2: integer; mode: bitset end;
procedure WRITEERR(I: integer);
(*=s3*)
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
begin
  if I = 0 then else begin
    ERROR(I, TEKCT);
    writeln(output, TEKCT);
  end;
end;
procedure ПPOГOH(MCИM: charset);
%
%
%
%
%
%
%
%
%
%
%
%
%
begin
  while not eof(input) and (input@ in MCИM) do get(input);
end;
procedure ПOДГOH(MCИM: charset);
%
%
begin
  while not eof(input) and not (input@ in MCИM) do get(input);
end;
procedure ПPOБ;
%
%
begin
  ПPOГOH([' ']);
end;
function COГЛACEH: boolean;
%
begin
  ПPOБ;
  COГЛACEH := eof(input) or (input@ = "_344") or (input@ = 'Y');
end;
procedure BЛEKC(var ЛEKC: alfa);
var CNT: integer;
%
begin
  ЛEKC := '_000     ';
  ДЛEKC := 0;
  (done) for CNT to 6 do begin
    if eof(input) then exit done;
    if input@ in PAЗДEЛ then exit done;
%
%
%
%
    ЛEKC[CNT] := input@;
    ДЛEKC := CNT;
    get(input);
  end;
  ПOДГOH(PAЗДEЛ);
end;
function CЛEKC(ЛEKC, OБPAЗ: alfa; ДЛ: integer): boolean;
var CNT: integer;
begin
  if ДЛEKC < ДЛ then CЛEKC := false else begin
    CЛEKC := true;
    for CNT to 6 do begin
%
%
      if (ЛEKC[CNT] = ' ') or (OБPAЗ[CNT] = ' ') then exit;
%
      if ЛEKC[CNT] <> OБPAЗ[CNT] then begin CЛEKC := false; exit end;
    end;
  end;
end;
function DIGIT(RADIX: integer): boolean;
var C: char;
%
%
begin
  C := input@;
  case C of
    "_342": C := 'B'; "_343": C := 'C';
    "_344": C := 'D'; "_346": C := 'F'
  end;
  if RADIX <= 10 then
    DIGIT := not eof(input) and (C >= '0') and
             (C <= chr(ord('0') + RADIX))
  else DIGIT := DIGIT(10) or ((C >= 'A') and (C <= 'F'));
end;
function DECODE(RADIX: integer): integer;
var C: char;
%
%
%
%
%
begin
  C := input@;
  case C of
    "_342": C := 'B'; "_343": C := 'C';
    "_344": C := 'D'; "_346": C := 'F'
  end;
  if (RADIX <= 10) or (C < 'A') then
    DECODE := ord(C) - ord('0')
  else DECODE := ord(C) - ord('A') + 10;
end;
function SCANNUM(RADIX: integer; FLAG: boolean): integer;
var NUMBER: integer;
%
%
%
%
%
begin
  ПPOБ;
  NUMBER := 0;
  if not DIGIT(RADIX) and not eof(input) then SCANNUM := -1
  else begin
    (done) while true do begin
      if not DIGIT(RADIX) then
        if not FLAG or (input@ <> ' ') then exit done;
      if input@ <> ' ' then NUMBER := NUMBER * RADIX + DECODE(RADIX);
      get(input);
    end;
    SCANNUM := NUMBER;
  end;
end;
function READNUM(RADIX: integer): integer;
%
begin
  READLINE(input);
  READNUM := SCANNUM(RADIX, false);
end;
function READAGRE: boolean;
%
begin
  READLINE(input);
  READAGRE := COГЛACEH;
end;
procedure ЗПЗ(ЗOHA: integer);
var INFCЛOBO: integer;
%
%
begin
  if ЗOHA >= MAXЗOHA then begin
    writeln(output, "BЫXOД ЗA ГPAHИЦY ФAЙЛA"); goto 1;
  end;
  ЗOHA := ЗOHA;
  besm(04120011B, 150000B:(0000360000000000C));
  INFCЛOBO := ;
  besm(10700004B);
  writeln(output, "ЗAПИCЬ=", INFCЛOBO:17 oct);
end;
procedure ЧT(ЗOHA: integer);
var INFCЛOBO: integer;
%
%
%
%
%
%
begin
  if ЗOHA >= MAXЗOHA then begin
    writeln(output, "BЫXOД ЗA ГPAHИЦY ФAЙЛA"); goto 1;
  end;
  CЧИTЗOHA := ЗOHA;
  besm(04120011B, 150000B:(0010360000000000C));
  INFCЛOBO := ;
  besm(10700004B);
  writeln(output, "ЧTEHИE=", INFCЛOBO:17 oct);
end;
procedure ЗAПИCЬ;
%
%
%
%
%
begin
  if CЧИTЗOHA <> 777777B then ЗПЗ(CЧИTЗOHA);
end;
procedure ПEЧCЛOBO;
var I: integer;
  procedure WRITECOD(AДPC: integer);
%
%
%
%
%
%
  begin
    with BUFFER[AДPC] do begin
      write(output, reg:1 hex, ' ', op:2 hex, ' ');
      if op = 77B then write(output, base:2 hex, ' ', addr:3 hex)
      else write(output, ' ', longaddr:5 hex);
    end;
  end;
  procedure WRITEHEX(AДPC: integer);
  var I: integer;
%
%
%
  begin
    with BUFFER[AДPC] do
%
      for I := 0 to 3 do write(output, bytes[I]:2 hex, ' ');
  end;
  procedure WRITECHA(AДPC: integer);
  var I: integer; C: char;
%
%
%
  begin
    with BUFFER[AДPC] do
      for I := 0 to 3 do begin
        C := chars[I+1B];
        if ((C > '_037') and (C <= 'Ч')) or
           ((C > "_277") and (C < "_377")) then write(output, C:1)
        else write(output, '.');
      end;
  end;
%
%
%
begin
  write(output, AДPEC:7 hex, ') ');
  case FORMAT of
    CODE: begin
      WRITECOD(CЛOBO); write(output, '  ');
      WRITECOD(CЛOBO+1);
    end;
    HEX: begin
      WRITEHEX(CЛOBO); write(output, ' '); WRITEHEX(CЛOBO+1);
      write(output, ' '); WRITECHA(CЛOBO); WRITECHA(CЛOBO+1);
    end
  end;
  write(output, ' : ');
  for I := 42 to 47 do
%
%
%
%
%
    write(output, ord(I in BUFFER[CЛOBO].bits):1);
  writeln;
end;
procedure ЗAMEHA;
var AДPEC, BHYTAДPE, CЛOBO, ИЗMCЛOBO, ЗOHA, I, J, K, K1, K2,
    A, B: integer;
    ФЛAГ: boolean;
    TEKCT: packed array [1..8] of char;
    C: char;
label 2;
  procedure BBOД64(var A, B: integer);
  var C: char;
    function DECODE(RADIX: integer): integer;
%
%
%
%
%
%
    begin
      case C of
        "_342": C := 'B'; "_343": C := 'C';
        "_344": C := 'D'; "_346": C := 'F'
      end;
      if (RADIX <= 10) or (C < 'A') then DECODE := ord(C)-ord('0')
      else DECODE := ord(C)-ord('A')+10;
    end;
%
%
%
%
  begin
    ПPOБ;
    if not eof(input) and DIGIT(16) then begin
        C := input@; get(input);
        BBOД64(A, B);
        K := K+1;
        if 8 >= K then K1 := K1*16
        else if 16 >= K then K2 := K2*16
        else begin
          writeln(output, "CЛИШKOM MHOГO ЦИФP B ЧИCЛE"); goto 2;
        end;
      end else exit;
        if 8 >= K then B := B + DECODE(16)*K1 div 16
        else A := A + DECODE(16)*K2 div 16;
  end;
%
%
%
%
%
%
begin
  if eof(input) then begin
    rewrite(input); write(input, "AДPEC CЛOBA- "); READLINE(input);
  end;
  AДPEC := SCANNUM(16, false);
  if AДPEC < 0 then begin
    writeln(output, "HEДOПYCTИMЫЙ AДPEC"); exit;
  end;
  BHYTAДPE := AДPEC-HAЧAЛO;
  if BHYTAДPE < 0 then goto 1;
  CЛOBO := BHYTAДPE*2 mod 1024;
  ЗOHA := integer(bitset(DESCR)*bitset(777777B)) + BHYTAДPE div 512;
  if ЗOHA <> CЧИTЗOHA then ЧT(ЗOHA);
  ФЛAГ := false;
  if eof(input) then ФЛAГ := true else
    if input@ = "_354" then ИЗMCЛOBO := CЛOBO else
    if input@ = "_360" then ИЗMCЛOBO := CЛOBO+1 else begin
      writeln(output, "HEДOПYCTИMЫЙ AДPEC"); exit;
    end;
  rewrite(input); write(input, "ЗAMEHA- "); READLINE(input);
  if eof(input) then goto 1;
  if input@ = 'T' then begin
    get(input);
    if (input@ = ' ') and not eof(input) then get(input);
    TEKCT := '_000_000_000_000_000_000_000_000';
    I := 1;
    (textdone) while not eof(input) and
          (I <= ord(ФЛAГ)*4+4) do begin
      C := input@; get(input);
      if C = '_134' then begin
        if (input@ = '_134') and not eof(input) then begin
%
%
%
%
%
%
%
%
%
%
          TEKCT[I] := input@; get(input); I := I+1;
        end else if not DIGIT(8) or eof(input) then begin
          TEKCT[I] := C; I := I+1;
        end else begin
          J := 0;
          (octdone) for K := 1 to 3 do begin
            if eof(input) or not DIGIT(8) then exit octdone;
            J := J*8+DECODE(8); get(input);
          end;
%
%
%
%
          TEKCT[I] := chr(J); I := I+1;
        end;
%
      end else begin TEKCT[I] := C; I := I+1 end;
    end;
    if ФЛAГ then begin
      ИЗMCЛOBO := CЛOBO;
%
%
      for I := 1 to 4 do BUFFER[ИЗMCЛOBO].chars[I] := TEKCT[I];
%
      for I := 1 to 4 do BUFFER[ИЗMCЛOBO+1].chars[I] := TEKCT[I+4B];
    end else
%
      for I := 1 to 4 do BUFFER[ИЗMCЛOBO].chars[I] := TEKCT[I];
  end else if ФЛAГ then begin
    ИЗMCЛOBO := CЛOBO; K := 0; K1 := 1; K2 := 1; A := 0; B := 0;
    BBOД64(A, B);
%
%
%
%
    BUFFER[ИЗMCЛOBO].value := A;
    BUFFER[ИЗMCЛOBO+1B].value := B;
  end else begin
    I := SCANNUM(16, true);
    if I < 0 then writeln(output, "HEДOПYCTИMAЯ ЗAMEHA")
%
%
%
    else BUFFER[ИЗMCЛOBO].value := I mod 4294967295;
  end;
2:rewrite(input);
  write(input, AДPEC:5 hex, chr(55B), AДPEC:5 hex, '  ');
end;
procedure CMEAЦП;
%
begin
  TTIO.mode := TTIO.mode / bitset(1C);
  goto 1;
end;
procedure CMEЭKP;
%
begin
  TTIO.mode := TTIO.mode / bitset(2C);
  goto 1;
end;
%
begin
  writeln(output,
    "<_077> ЭTO XИTPЫЙ ПPOЗ. BEP _077_077._077_077 <_077>");
  NAMELIB := ACTIVELI;
  I := LIB(NAMELIB, HYЗЗЗЗ);
  if I <> 5 then begin WRITEERR(I); besm(740000B) end;
  writeln(output, NAMELIB, chr(32), HYЗЗЗЗ:6 oct);
  GETCMDLI(input);
  if not eof(input) then goto 2;
3:
      rewrite(input); write(input, "ФAЙЛ _077"); READLINE(input);
      if eof(input) then besm(740000B);
2:  I := 1;
    while not eof(input) do begin
%
%
%
%
%
%
%
%
%
%
%
%
%
%
      FILENAME[I] := input@; get(input); I := I+1;
    end;
%
%
    for J := I to 84 do FILENAME[J] := lf;
    I := MKNAME(FILENAME, NAMELIB, FILETYPE, NAME3);
    WRITEERR(I);
    if I <> 0 then goto 3;
4:I := OPENF(NAME3, false, DESCR); WRITEERR(I);
  if I <> 0 then goto 3;
5:writeln(output, 'DESCRIPTOR :', integer(DESCR):17 oct);
  MAXЗOHA := DESCR.zone + DESCR.length;
  repeat
    rewrite(input); write(input, "HAЧAЛЬHЫЙ AДPEC _077");
    HAЧAЛO := READNUM(16);
  until HAЧAЛO >= 0;
1:repeat
    rewrite(input); write(input, "BЫДATЬ- "); READLINE(input);
    if eof(input) then goto 6;
    BЛEKC(ДИP);
    if CЛEKC(ДИP, '_000     ', 1) then goto 1
    else if CЛEKC(ДИP, "ЗAM   ", 3) then ЗAMEHA
    else if CЛEKC(ДИP, "KHЦ   ", 3) then besm(740000B)
    else if CЛEKC(ДИP, 'K     ', 1) then
      begin FORMAT := CODE; goto 1 end
    else if CЛEKC(ДИP, "Ш     ", 1) then begin FORMAT := HEX; goto 1 end
    else if CЛEKC(ДИP, 'A.    ', 2) then CMEAЦП
    else if CЛEKC(ДИP, 'V.    ', 2) then CMEЭKP
    else if CЛEKC(ДИP, "ЗAП   ", 2) then ЗAПИCЬ;
    reset(input);
    AДPEC := SCANNUM(16, false);
    if AДPEC < 0 then goto 1;
    if input@ = chr(55B) then begin
      get(input); KOHAДPEC := SCANNUM(16, false);
      if KOHAДPEC < 0 then goto 1;
    end else KOHAДPEC := 777777777B;
6:  repeat
      BHYTAДPE := AДPEC-HAЧAЛO;
      if BHYTAДPE < 0 then goto 1;
      ЗOHA := integer(bitset(DESCR)*bitset(777777B)) + BHYTAДPE div 512;
      if ЗOHA <> CЧИTЗOHA then ЧT(ЗOHA);
      CЛOBO := BHYTAДPE*2 mod 1024;
      ПEЧCЛOBO;
      AДPEC := AДPEC+1;
      if KOHAДPEC < AДPEC then goto 1;
      if TTIO.T2 >= 23 then
        if boolean(TTIO.mode*bitset(2C)) then goto 1;
    until false;
  until false;
  besm(740000B);
%
%
%
%
%
%
%
end.D
 HYЗЗЗЗ = 0; FILETYPE = "KOД   "; AДPEC = -1;
 CЧИTЗOHA = 777777B; PAЗДEЛ = [' ']
end
