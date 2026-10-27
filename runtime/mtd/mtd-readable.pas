(*=y+,o-*)
program MTDSK(input, output);
% Readable MTD reconstruction. PMD names and control flow are preserved.
% mtd.pas adds historical line-number padding for a word-exact rebuild.
% Build this version: python3 runtime/mtd/build.py --explore
%   --source runtime/mtd/mtd-readable.pas
% TAPEIO and READLINE are aliases for the original machine entries.
const lf = '_012';
type charset = set of '_000'..'_057';
     prompt = packed array [1..2] of char;
     line = packed array [1..84] of char;
var
  CMDLINE [55B]: line;
  PAЗДEЛ: charset;
  ДЛEKC, HYЧT, HYЗП, TEMP, BLKNO, CURZONE, CNT, RESULT, FNO: integer;
  LIBIN, LIBOUT: alfa;
  ACTIVELI [3B]: alfa;
procedure READLINE(var f: text); fortran;
function TAPEIO(unitno, operation, page, flag: integer): integer;
  assembler;

procedure ПPOГOH(MCИM: charset);
begin
  while not eof(input) and (input@ < '0') and (input@ in MCИM) do begin
    (q) get(input); (q);
  end;
end;

procedure ПOДГOH(MCИM: charset);
begin
  while not eof(input) and not (input@ in MCИM) do begin
    (q) get(input); (q);
  end;
end;

procedure ПPOБ;
begin
  ПPOГOH([' ']);
end;

function COГЛACEH: boolean;
begin
  ПPOБ;
  COГЛACEH := eof(input) or (input@ = "_344") or (input@ = 'Y');
end;

procedure BЛEKC(var ЛEKC: alfa);
var CNT: integer;
label 1;
begin
1:ЛEKC := '_000     ';
  ДЛEKC := 0;
  (done) for CNT to 6 do begin
    if eof(input) then exit done;
    if input@ = '>' then begin get(input); goto 1 end;
    if input@ in PAЗДEЛ then exit done;
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
      if (ЛEKC[CNT] = ' ') or (OБPAЗ[CNT] = ' ') then exit;
      if ЛEKC[CNT] <> OБPAЗ[CNT] then begin CЛEKC := false; exit end;
    end;
  end;
end;

function SCANNUM(RADIX: integer): integer;
var NUMBER: integer;

  function DIGIT(RADIX: integer): boolean;
  begin
    if RADIX <= 10 then
      DIGIT := not eof(input) and (input@ >= '0') and
               (input@ < chr(ord('0') + RADIX))
    else
      DIGIT := DIGIT(10) or ((input@ >= 'A') and (input@ <= 'F'));
  end;

  function DECODE(RADIX: integer): integer;
  begin
    if (RADIX <= 10) or (input@ < 'A') then
      DECODE := ord(input@) - ord('0')
    else DECODE := ord(input@) - ord('A') + 10;
  end;

begin
  ПPOБ;
  NUMBER := 0;
  while not DIGIT(RADIX) do begin
    writeln(output, "TPEБYETCЯ ЧИCЛO ПO OCHOBAHИЮ", RADIX:3);
    rewrite(input);
    write(input, prompt(1320400000000000C));
    READLINE(input);
    ПPOБ; (q);
  end;
  while DIGIT(RADIX) do begin
    NUMBER := NUMBER * RADIX + DECODE(RADIX);
    get(input); (q);
  end;
  SCANNUM := NUMBER;
end;

function READNUM(RADIX: integer): integer;
begin
  READLINE(input);
  READNUM := SCANNUM(RADIX);
end;

function READAGRE: boolean;
begin
  READLINE(input);
  READAGRE := COГЛACEH;
end;

procedure GETCMDLI(var f: text);
var i: integer;
begin
  rewrite(f);
  (done) for i := 1 to 80 do begin
    if CMDLINE[i] = lf then exit done;
    write(f, CMDLINE[i]);
  end;
  reset(f);
end;

begin
  PAЗДEЛ := [' '];
  GETCMDLI(input);
  BЛEKC(LIBIN);
  ПPOБ;
  BЛEKC(LIBOUT);
  writeln(output, LIBIN, ' -> ', LIBOUT);
  HYЧT := 42; HYЗП := 43;
  repeat
    rewrite(input); write(input, 'FILE NUMBER=');
    FNO := READNUM(10);
    if FNO <> 0 then begin
      RESULT := TAPEIO(HYЧT, 6C, 0, 0);
      for CNT := 1 to FNO - 1 do RESULT := TAPEIO(HYЧT, 4C, 0, 0);
    end;
    rewrite(input); write(input, 'ZONE NUMBER=');
    CURZONE := READNUM(8);
    BLKNO := 0;
    (finished) while true do begin
      (ready) begin
        for CNT := 1 to 15 do begin
          RESULT := TAPEIO(HYЧT, 1C, 30, 1);
          if ((RESULT mod 32) = 0) or ((RESULT mod 32) = 3) then
            exit ready;
          RESULT := TAPEIO(HYЧT, 3C, 0, 0);
        end;
        RESULT := TAPEIO(HYЧT, 1C, 30, 1);
      end;
      if (RESULT mod 32) = 3 then exit finished;
      if (RESULT mod 32) <> 0 then
        writeln(output, 'BLOCK ', BLKNO:4 oct, ' IO RESULT ',
                RESULT:5 oct);
      if RESULT div 32768 <> 6144 then
        writeln(output, 'BLOCK ', BLKNO:4 oct, ' BLKSIZE=',
                RESULT div 32768:1);
      besm(100000B:(30), 360056B, 150000B:HYЗП, 360064B,
           150000B:CURZONE, 4120011B);
      TEMP := ;
      besm(700000B:TEMP); (q);
      besm(100000B:CURZONE, 4040021B, 0B:CURZONE,
           100000B:BLKNO, 4040021B, 0B:BLKNO);
    end;
    writeln(output, BLKNO:4 oct, ' BLOCKS COPIED.');
    rewrite(input); write(input, 'COPY ANOTHER FILE', '_077');
    if not READAGRE then exit; (q);
  until false;
end.
