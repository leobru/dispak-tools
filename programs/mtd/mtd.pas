(*=y+,o-*)
program MTDSK(input, output);
% MTD (MTDSK), volume 4001, zones 0047-0050.
% Build: python3 programs/mtd/build.py (private compiler and disks).
% All 677 application words 02012-03256 match the original exactly.
% All 2048 image words match except the loader value at 02010.L.
% Names are from PMD; TAPEIO and READLINE are descriptive aliases.
% S3 and comment padding preserve historical source line numbers.
% The readable version without line padding is mtd-readable.pas.
% No tape or disk copy operation is executed by the build.
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
begin
  while not eof(input) and (input@ < '0') and (input@ in MCИM) do begin
    (q) get(input); (q);
  end;
end;

procedure ПOДГOH(MCИM: charset);
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
begin
  while not eof(input) and not (input@ in MCИM) do begin
    (q) get(input); (q);
  end;
end;

procedure ПPOБ;
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
begin
  ПPOГOH([' ']);
end;

function COГЛACEH: boolean;
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
begin
  ПPOБ;
  COГЛACEH := eof(input) or (input@ = "_344") or (input@ = 'Y');
end;

procedure BЛEKC(var ЛEKC: alfa);
var CNT: integer;
label 1;
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
begin
1:ЛEKC := '_000     ';
  ДЛEKC := 0;
  (done) for CNT to 6 do begin
    if eof(input) then exit done;
    if input@ = '>' then begin get(input); goto 1 end;
    if input@ in PAЗДEЛ then exit done;
%
%
%
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
begin
  if ДЛEKC < ДЛ then CЛEKC := false else begin
    CЛEKC := true;
    for CNT to 6 do begin
      if (ЛEKC[CNT] = ' ') or (OБPAЗ[CNT] = ' ') then exit;
%
%
      if ЛEKC[CNT] <> OБPAЗ[CNT] then begin CЛEKC := false; exit end;
    end;
  end;
end;

function SCANNUM(RADIX: integer): integer;
var NUMBER: integer;

  function DIGIT(RADIX: integer): boolean;
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
    if RADIX <= 10 then
      DIGIT := not eof(input) and (input@ >= '0') and
               (input@ < chr(ord('0') + RADIX))
    else
      DIGIT := DIGIT(10) or ((input@ >= 'A') and (input@ <= 'F'));
  end;

  function DECODE(RADIX: integer): integer;
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
    if (RADIX <= 10) or (input@ < 'A') then
      DECODE := ord(input@) - ord('0')
    else DECODE := ord(input@) - ord('A') + 10;
  end;

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
  READLINE(input);
  READNUM := SCANNUM(RADIX);
end;

function READAGRE: boolean;
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
  READLINE(input);
  READAGRE := COГЛACEH;
end;

procedure GETCMDLI(var f: text);
var i: integer;
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
  rewrite(f);
  (done) for i := 1 to 80 do begin
%
    if CMDLINE[i] = lf then exit done;
    write(f, CMDLINE[i]);
  end;
  reset(f);
end;

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
end.
