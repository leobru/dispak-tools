(*=y+,p-,t-,o-*)
program BOX(input, output);
% BOX, volume 4001 zones 0066-0067; application 02012-03030.
% Build: python3 runtime/box/build.py (private compiler and disks).
% All 527 application words and 604 runtime words match literally.
% Full image: 2047/2048 words match; only 02010.L is a loader value.
% Names are reconstructed; shared lexer names follow MTD's PMD.
% S3 and comment padding preserve the historical check line numbers.
% mypas.b6 preserves VTM's numeric 71717 operand in the PRO command.
% The build dumps the image without executing BOX commands.
const lf = '_012';
type charset = set of '_000'..'_057';
     prompt = packed array [1..2] of char;
     line = packed array [1..84] of char;
     bitset = set of 0..47;
var PAЗДEЛ: charset; ДЛEKC: integer; command: alfa;
    CMDLINE [55B]: line;
procedure READLINE(var f: text); fortran;

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
    if CMDLINE[i] = lf then exit done;
    write(f, CMDLINE[i]);
  end;
  reset(f);
end;

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

procedure USAGE(cmd: alfa; status: integer);
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
begin
  i := 1;
  while (6 >= i) and (cmd[i] <> ' ') do begin
    write(output, cmd[i]);
    i := i + 1; (q);
  end;
  write(output, '_077'); writeln(output);
  writeln(output, 'USAGE: BOX <WHAT>');
  writeln(output,
    "<WHAT> ::= BЫД, ПPO, COX, ЛИCT, HOBKAT <БИБ>");
  besm(100000B:status, 3000002B); (q);
end;

procedure NEWCATALOG;
type memory = array [0..1023] of alfa;
var cw, i: integer;
    table [20B]: memory;
    buffer [74000B]: memory;
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
begin
  ПPOБ;
  BЛEKC(command);
  (found) begin
    for i := 0 to 30 do
      if table[i] = command then exit found;
    USAGE(command, 2);
  end;
  cw := integer(bitset(table[i+1]) * bitset(777777C));
  rewrite(input);
  write(input, command, ' : ', cw:6 oct, ' (Y/N)_077 ');
  if not READAGRE then exit;
    for i := 0 to 1023 do begin
      buffer[i] := alfa(0C); (q);
    end;
    (q);
    buffer[0] := alfa(7760000000000001C);
    buffer[2] := alfa(1C);
    buffer[512] := alfa(1C);
    cw := integer(bitset(cw) + bitset(0000360000000000C));
    besm(700000B:cw); (q);
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
begin
  PAЗДEЛ := [' '];
  GETCMDLI(input);
  if eof(input) then USAGE('BOX   ', 1);
  BЛEKC(command);
  if CЛEKC(command, "ПPO   ", 3) then begin
    besm(14440014B, 16471717B, 501212B); (q);
    besm(60440003B);
  end else if CЛEKC(command, "BЫД   ", 3) then begin
    besm(620042B); (q);
  end else if CЛEKC(command, "ЛИCT  ", 3) then begin
    besm(66402000B, 660200B); (q);
  end else if CЛEKC(command, "ЭXO   ", 1) then begin
    ПPOБ;
    while not eof(input) do (q) begin
      write(output, input@); get(input); (q);
    end;
    writeln;
  end else if CЛEKC(command, 'COX   ', 3) then begin
    besm(620043B); (q);
  end else if CЛEKC(command, 'HOBKAT', 6) then NEWCATALOG
  else USAGE(command, 2);
  writeln(output, " ECTЬ.");
  besm(100000B:(0), 3000002B); (q);
end.
