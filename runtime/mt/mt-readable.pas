(*=a4,y+,o-*)
program MT(input, output);
% Recovered MT, volume 4001, zones 0172-0174.
% Build: python3 runtime/mt/build.py
% mt-readable.pas omits historical source-line padding.
% READLINE and TAPEIO are descriptive entry aliases.
% LIB and parser/global names are backed by include or PMD.
const lf = '_012';
type charset = set of '_000'..'_057';
     prompt = packed array [1..2] of char;
     line = packed array [1..84] of char;
     bitset = set of 0..47;
     operation = (ЗAП, ЧT, ЗB, ЗH, ФB, ФH, ПH, TM, П8, П32, П63, CT);
var PAЗДEЛ: charset;
    ДЛEKC, I, REPT, RESULT, MTDEV: integer;
    MTDEVNAM, LEX: alfa;
    OPTN: operation;
    ACTIVELI [3B]: alfa;
    CMDLINE [55B]: line;
procedure READLINE(var f: text); fortran;
function LIB(name: alfa; var unitno: integer): integer; assembler;
function TAPEIO(unitno, operation, page, flag: integer): integer;
  assembler;

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
  COГЛACEH := eof(input) or (input@ = '_344') or (input@ = 'Y');
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
    writeln(output, 'TPEБYETCЯ ЧИCЛO ПO OCHOBAHИЮ', RADIX:3);
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

begin
  PAЗДEЛ := [' '];
  GETCMDLI(input);
  ПPOБ;
  BЛEKC(LEX);
  if CЛEKC(LEX, '-T    ', 2) then begin
    ПPOБ;
    BЛEKC(MTDEVNAM);
  end else begin
    MTDEVNAM := 'MT    ';
    reset(input);
  end;
  MTDEV := 0C;
  RESULT := LIB(MTDEVNAM, MTDEV);
  if RESULT <> 5 then begin
    writeln(output, 'NO TAPE SPECIFIED');
    besm(100000B:(1), 3000002B); (q);
  end else begin
    besm(100000B:MTDEV, 360114B, 110000B:(77C), 4150011B,
         0B:MTDEV); (q);
  end;
  ПPOБ;
  BЛEKC(LEX);
  select
    CЛEKC(LEX, 'ЗB    ', 2): OPTN := ЗB;
    CЛEKC(LEX, 'ЗH    ', 2): OPTN := ЗH;
    CЛEKC(LEX, 'ФB    ', 2): OPTN := ФB;
    CЛEKC(LEX, 'ФH    ', 2): OPTN := ФH;
    CЛEKC(LEX, 'ПH    ', 2): OPTN := ПH;
    CЛEKC(LEX, 'TM    ', 2): OPTN := TM;
    CЛEKC(LEX, 'П8    ', 2): OPTN := П8;
    CЛEKC(LEX, 'П32   ', 2): OPTN := П32;
    CЛEKC(LEX, 'П63   ', 2): OPTN := П63;
    CЛEKC(LEX, 'CT    ', 2): OPTN := CT;
    CЛEKC(LEX, 'FSR   ', 3): OPTN := ЗB;
    CЛEKC(LEX, 'BSR   ', 3): OPTN := ЗH;
    CЛEKC(LEX, 'FSF   ', 3): OPTN := ФB;
    CЛEKC(LEX, 'BSF   ', 3): OPTN := ФH;
    CЛEKC(LEX, 'REW   ', 3): OPTN := ПH;
    CЛEKC(LEX, 'WTM   ', 3): OPTN := TM;
    CЛEKC(LEX, 'D8    ', 2): OPTN := П8;
    CЛEKC(LEX, 'D32   ', 3): OPTN := П32;
    CЛEKC(LEX, 'D63   ', 3): OPTN := П63;
    CЛEKC(LEX, 'ERG   ', 2): OPTN := CT;
    true: begin
      writeln(output, LEX, ' NOT SUPPORTED.');
      besm(100000B:(1), 3000002B);
      (q);
    end
  end;
  ПPOБ;
  if eof(input) then REPT := 1 else REPT := SCANNUM(10);
  for I := 1 to REPT do begin
    repeat
      RESULT := TAPEIO(MTDEV, integer(OPTN), 30, 0);
    until (bitset(RESULT) * bitset(31)) <> bitset(4);
    if REPT <> 1 then write(output, I:4, ' : ');
    writeln(output, 'RESULT = ', RESULT:5 oct);
  end;
  (q) besm(100000B:(0), 3000002B); (q);
end.
