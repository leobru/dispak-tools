(*=a4,y+,o-,b1,s7*)
program PRINTFIL(input, output, TTIO);
% FPRINT, volume 4001, zones 0063-0065; names retained from PMD.
% Build: python3 runtime/fprint/build.py
% fprint.pas preserves the historical source-line numbers.
% The builder dumps the image without printing or reading files.
const lf = '_012';
type charset = set of '_000'..'_057';
     bitset = set of 0..47;
     line = packed array [1..84] of char;
     word3 = record ext, lib, name: alfa end;
     codetable = packed array [0..223] of char;
var PAЗДEЛ: charset;
    ДЛEKC: integer;
    ERRTXT: line;
    CMDLINE [55B]: line;
    FILENAME: line;
    FULLNAME: word3;
    FILEDESC, I, RESULT: integer;
    CH: char;
    PCHR: integer;
    SIXBYTES: alfa;
    PWORD: integer;
    ENDOFSOU: boolean;
    ACTIVELI [3B]: alfa;
procedure READLINE(var F: text); fortran;
procedure E64ONE; fortran;
procedure E64TEXT; fortran;
procedure E64ZERO; fortran;
function MKNAME(var name: line; lib, ext: alfa;
                var dest: word3): integer; assembler;
procedure ERROR(status: integer; var message: line); assembler;
function OPENF(var name: word3; writing: boolean;
               var descriptor: integer): integer; assembler;

procedure ПPOГOH(MCИM: charset);
begin
  while not eof(input) and (input@ in MCИM) do begin
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
    ЛEKC[CNT] := input@; ДЛEKC := CNT; get(input);
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
               (input@ < chr(ord('0')+RADIX))
    else DIGIT := DIGIT(10) or ((input@ >= 'A') and (input@ <= 'F'));
  end;

  function DECODE(RADIX: integer): integer;
  begin
    if (RADIX <= 10) or (input@ < 'A') then
      DECODE := ord(input@)-ord('0')
    else DECODE := ord(input@)-ord('A')+10;
  end;

begin
  ПPOБ;
  NUMBER := 0;
  while not DIGIT(RADIX) do begin
    writeln(output, 'TPEБYETCЯ ЧИCЛO ПO OCHOBAHИЮ', RADIX:3);
    rewrite(input); write(input, '-_010'); READLINE(input); ПPOБ; (q);
  end;
  while DIGIT(RADIX) do begin
    NUMBER := NUMBER*RADIX+DECODE(RADIX); get(input);
  end;
  SCANNUM := NUMBER;
end;

function READNUM(RADIX: integer): integer;
begin
  READLINE(input); READNUM := SCANNUM(RADIX);
end;

function READAGRE: boolean;
begin
  READLINE(input); READAGRE := COГЛACEH;
end;

procedure GETCMDLI(var F: text);
var I: integer;
begin
  rewrite(F);
  (done) for I := 1 to 80 do begin
    if CMDLINE[I] = lf then exit done;
    write(F, CMDLINE[I]);
  end;
  reset(F);
end;

var CORNER: array [0..3] of integer;
    SHEET [30000B]: array [0..70, 0..128] of char;
    LINES, CHARS, PSHEET, MAXPSHEE, NUNG: integer;
    PBUFF [52000B]: packed array [0..39999] of char;
    UNGBUFF: array [1..8] of char;
    CODETAB, CODETAB1: codetable;
    PCT, PCT1: @codetable;
    W064, W164: integer;
    BUFFER [74000B]: array [1..1024] of bitset;

function GETWORD: bitset;
var TEMP: bitset;
begin
  if (PWORD < 1) or (1024 < PWORD) then begin
    TEMP := bitset(FILEDESC)*bitset(777777C)+bitset(0010360000000000C);
    besm(10700004B); (q);
    FILEDESC := FILEDESC+1; PWORD := 1;
  end;
  GETWORD := BUFFER[PWORD]; PWORD := PWORD+1;
end;

procedure UNGETCH(CH: char);
begin
  NUNG := NUNG+1; UNGBUFF[NUNG] := CH;
end;

procedure GETCH;
begin
  if 0 < NUNG then begin
    CH := UNGBUFF[NUNG]; NUNG := NUNG-1;
  end else begin
    if not (PCHR in [1..6]) then begin
      SIXBYTES := alfa(GETWORD); PCHR := 1;
    end;
    CH := SIXBYTES[PCHR]; PCHR := PCHR+1;
  end;
end;

procedure INITSHEE;
var S, P: integer;
begin
  for P := 0 to 70 do begin
    for S := 0 to 127 do begin SHEET[P,S] := ' '; (q) end; (q);
    SHEET[P,128] := lf;
  end; (q);
end;

procedure USAGE;
begin
  writeln(output, 'USAGE: FPRINT <FILE> [-<OPTIONS>]');
end;

procedure XLAT;
var P, S, CHI, BP, COL: integer;
    CH, CHW: char;
    DSTRIKE: boolean;

  procedure PUTC(C: char);
  begin
    PBUFF[BP] := C; BP := BP+1;
  end;

begin
  BP := 0;
  for P := 0 to LINES do begin
    COL := 0; DSTRIKE := false;
    (first) for S := 0 to 128 do begin
      CHW := SHEET[P,S];
      while CHW <> '_000' do (nextchar) begin
        (q);
        CH := char(bitset(CHW)*bitset(377C)); CHI := ord(CH);
% Preserve all packed overstrike bytes while shifting right.
        besm(100000B:CHW, 360110B); CHW := ;
        if CH = lf then exit first;
        if CHI < 32 then exit nextchar;
        PUTC(PCT@[ord(CH)-32]);
        DSTRIKE := DSTRIKE or (PCT1@[ord(CH)-32] <> '_017'); (q);
        if CHW <> '_000' then begin PUTC('_173'); PUTC(chr(COL)) end
        else COL := COL+1;
      end;
    end;
    if DSTRIKE then begin
      PUTC('_173'); PUTC('_000'); COL := 0;
      (second) for S := 0 to 128 do begin
        CHW := SHEET[P,S];
        while CHW <> '_000' do (nextchar) begin
          (q);
          CH := char(bitset(CHW)*bitset(377C)); CHI := ord(CH);
          besm(100000B:CHW, 360110B); CHW := ;
          if CH = lf then exit second;
          if CHI < 32 then exit nextchar;
          CH := PCT1@[ord(CH)-32]; PUTC(CH);
          if CHW <> '_000' then begin PUTC('_173'); PUTC(chr(COL)) end
          else COL := COL+1;
        end;
      end;
    end;
    PUTC('_214');
  end; (q);
  PUTC('_172'); (q);
end;

var TTIO: array [0..22] of bitset;

procedure PRINTSHE;
begin
  besm(66452000B, 4640260B);
end;

procedure FILLPAGE(STC, ML, MC: integer; LAST: boolean);
var TEMP, CC, CL: integer;
    PCC: @char;
label 1;

  function NEWLINE: boolean;
  begin
    if LAST then PCC@ := lf;
    CC := 0; CL := CL+1;
    NEWLINE := ML < CL;
    PCC := ref(SHEET[CL,STC+CC]);
  end;

begin
  CL := 0; CC := 0;
  (filled) while true do begin
    PCC := ref(SHEET[CL,STC+CC]); GETCH;
    case CH of
      '_015': ;
      '_012': 1: if NEWLINE then exit filled;
      '_010': if CC <> 0 then CC := CC-1;
      '_011': begin
        TEMP := (CC div 8+1)*8;
        if TEMP > MC then goto 1 else CC := TEMP;
      end;
      '_014': exit filled;
      '_000', '_004': begin ENDOFSOU := true; exit filled end;
      others: if MC < CC then begin
        UNGETCH(CH); goto 1;
      end else begin
        if PCC@ = ' ' then PCC@ := CH else begin
% Append CH to the packed overstrike bytes in this cell.
          besm(100000B:CH, 30000B:PCC@, 360070B, 74150000B);
          PCC@ := ;
        end;
        CC := CC+1;
      end
    end;
  end;
  if LAST then
    while ML >= CL do (q) TEMP := integer(NEWLINE);
end;

procedure FORMATSH;
begin
  PSHEET := 0;
  while (MAXPSHEE >= PSHEET) and not ENDOFSOU do begin
    (q); FILLPAGE(CORNER[PSHEET], LINES, CHARS, PSHEET = MAXPSHEE);
    PSHEET := PSHEET+1; (q);
  end;
end;

procedure INIT;
begin
  E64ONE; E64TEXT; E64ZERO;
  ENDOFSOU := false; MAXPSHEE := 1;
  CORNER[0] := 0; CORNER[1] := 63;
  PCT := ref(CODETAB); PCT1 := ref(CODETAB1);
  LINES := 68; CHARS := 62;
  PCHR := 0; PWORD := 0; NUNG := 0;
end;

begin
  INIT; GETCMDLI(input);
  if eof(input) then begin USAGE; besm(3000002B) end;
  I := 1;
  while not eof(input) and (input@ <> ' ') and (I < 84) do begin
    FILENAME[I] := input@; get(input); I := I+1; (q);
  end;
  FILENAME[I] := lf;
  RESULT := MKNAME(FILENAME, ACTIVELI, 'TXT   ', FULLNAME);
  if RESULT <> 0 then begin
    ERROR(RESULT, ERRTXT); writeln(output, ERRTXT);
    besm(100000B:RESULT, 3000002B);
  end;
  RESULT := OPENF(FULLNAME, false, FILEDESC);
  if RESULT <> 0 then begin
    ERROR(RESULT, ERRTXT); writeln(output, ERRTXT);
    besm(100000B:RESULT, 3000002B);
  end;
  TTIO[3] := bitset(1C);
  while not ENDOFSOU do begin
    INITSHEE; FORMATSH; XLAT; PRINTSHE;
    E64ONE; E64TEXT; E64ZERO;
  end;
end.D
 CODETAB = '_017_133_134_034_127_126',
   '_121_033_022_023_031_012',
   '_015_013_016_014_000_001',
   '_002_003_004_005_006_007',
   '_010_011_037_026_035_025',
   '_036_136_026_040_042_061',
   '_077_045_100_101_055_102',
   '_103_052_104_054_105_056',
   '_060_106_107_110_062_111',
   '_112_113_065_063_114_027',
   '_125_030_123_132_033_040',
   '_042_061_077_045_100_101',
   '_055_102_103_052_104_054',
   '_105_056_060_106_107_110',
   '_062_111_112_113_065_063',
   '_114_116_130_117_115_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_075_040',
   '_041_066_044_045_064_043',
   '_065_050_051_052_053_054',
   '_055_056_057_076_060_061',
   '_062_063_046_042_073_072',
   '_047_070_074_071_067_073',
   '_075_040_041_066_044_045',
   '_064_043_065_050_051_052',
   '_053_054_055_056_057_076',
   '_060_061_062_063_046_042',
   '_073_072_047_070_074_071',
   '_067_017_017_017_017_017';
 CODETAB1 = '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_040_042_061',
   '_077_045_100_101_055_102',
   '_103_052_104_054_105_056',
   '_060_106_107_110_062_111',
   '_112_113_065_063_114_017',
   '_017_017_017_017_016_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_017',
   '_017_017_017_017_017_033',
   '_075_040_041_066_044_045',
   '_064_043_065_050_051_052',
   '_053_054_055_056_057_076',
   '_060_061_062_063_046_042',
   '_073_072_047_070_074_071',
   '_067_017_017_017_017_017';
 W064 = 6400000064000000C;
 W164 = 0000000040000000C
end
