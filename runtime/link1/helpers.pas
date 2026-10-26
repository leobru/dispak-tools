(*=a4,y+,p-,t-,s7,s8,o-,m-*)
program LINK1(input, output, PADCHAR);
% LINK1, 4001/0175: initial reconstruction of the common helpers.
% This is NOT the complete linker: the job parser and linker passes
% have not yet been transcribed into Pascal. The empty main below is
% only for compiling and comparing the recovered helper procedures.
% Original names are unavailable (no PMD); names describe behavior.
type
  bitset = set of 0..47;
  charbits = set of '_000'..'_057';
  namekey = packed array [1..10] of char;
  pkey = @keynode;
  keynode = packed record case integer of
    0: (text: namekey);
    1: (word0: integer; upper: 0..4294967295;
        marked: boolean; next: pkey)
  end;
  pprefix = @prefix;
  prefix = packed record
    tag: integer;
    name: pkey;
    spare: 0..7;
    next: pprefix;
    low: 0..32767
  end;
  pobj = @objectrec;
  objecthead = record
    name: pkey;
    attr: packed record module: 0..1073741823; low: 0..262143 end;
  end;
  objectrec = record
    head: objecthead;
    rest: array [1..15] of integer
  end;
  phash = @hashtable;
  hashtable = array [0..127] of pkey;
  stamp = array [0..2] of integer;
  stage = (stzero, stinit, stparse, stgather, stresolve, stplace,
           steval, stoutput, stlabels, stend);
  ordering = (same, after, before);
  charclass = (letter, digit, white, punct, atend);
  tokentype = (kalfa, kname, kfile, knumber, kdecimal, kpunct);
  token = record case integer of
    0: (text: namekey);
    1: (number: integer);
    2: (symbol: char);
    3: (a6: alfa);
    5: (first6, last6: alfa);
    4: (disk: packed record length: 0..4095;
              address, spare: 0..262143 end)
  end;
  pair = packed record case integer of
    0: (hi, lo: integer);
    1: (first: integer; beforelen: 0..65535;
        count: 0..65535; afterlen: 0..65535)
  end;
  pairs = array [0..4095] of pair;
  code4 = packed array [0..3] of char;
var
  g0050, g0051, g0052, g0053, g0054, g0055, g0056, g0057,
  g0060, g0061, g0062, g0063, g0064, g0065, g0066, g0067,
  g0070, g0071, g0072, g0073, g0074, g0075, g0076, g0077,
  g0100, g0101, g0102, g0103, g0104, g0105, g0106, g0107,
  g0110, g0111, g0112, g0113, g0114, g0115, g0116: integer;
  PHASEERR: boolean;
  g0120, g0121, g0122, g0123, g0124, g0125, g0126, g0127,
  g0130, g0131, g0132, g0133, g0134, g0135, g0136, g0137,
  g0140: integer;
  NAMETAB: phash;
  ROOTPREF: pprefix;
  XLATTAB: array [char] of charclass;
  PRINTOPT: bitset;
  g0544, g0545, g0546, g0547, g0550, g0551, g0552,
  g0553: integer;
  KEYPOOL, g0555, OBJPOOL, g0557, g0560, g0561, g0562, g0563,
  g0564, g0565, g0566, g0567, g0570: integer;
  PHASE: stage;
  TIMES: array [stzero..stlabels] of stamp;
  MONTHDAY: array [1..13] of integer;
  g0642, g0643, g0644, g0645, g0646, g0647: integer;
  PADCHAR: char;

function HASHNAME(var KEY: namekey): integer; fortran;
function CMPNAME(var KEY: namekey; var NODE: keynode): ordering;
  fortran;
function NAMELEN(var KEY: keynode): integer; fortran;
procedure GETSTAMP(var RESULT: stamp); fortran;
procedure NEWKEY(POOL: integer); fortran;
procedure OBJREAD(POOL, INDEX: integer); fortran;
procedure OBJEDIT(POOL, INDEX: integer); fortran;
function NUMOBJS(POOL: integer): integer; fortran;
function POSITION(POOL: integer): integer; fortran;
procedure SETPOS(POOL, INDEX: integer); fortran;
procedure READPAIR(POOL: integer; var V: pair); fortran;
procedure WRITPAIR(POOL: integer; var V: pair); fortran;
procedure PUTTEMP(POOL: integer; var V: pair); fortran;

% 02013: time measured in fiftieths of a second, MM:SS.cc.
procedure PUTTIME(T: integer);
begin
  PADCHAR := '0';
  write(T div 3000 mod 100:2, ':', T div 50 mod 60:2,
        '.', T * 2 mod 100:2);
  PADCHAR := ' ';
end;

% 02042: collect namespace components, print in reverse order.
procedure PUTPATH(P: pprefix);
var PART: array [1..12] of pkey;
    COUNT: integer;
begin
  COUNT := 0;
  while (P <> ROOTPREF) and (P <> ptr(0)) do begin
    COUNT := COUNT + 1;
    PART[COUNT] := P@.name;
    P := P@.next;
  end;
  for COUNT := COUNT downto 1 do write(PART[COUNT]@.text);
end;

% 02070: length of the same qualified name.
function PATHLEN(P: pprefix): integer;
var COUNT: integer;
begin
  COUNT := 0;
  while (P <> ROOTPREF) and (P <> ptr(0)) do begin
    COUNT := NAMELEN(P@.name@) + COUNT;
    P := P@.next;
  end;
  PATHLEN := COUNT;
end;

% 02113: save accounting values at the start of a linker phase.
procedure NEWPHASE(N: stage);
begin
  GETSTAMP(TIMES[N]);
  PHASE := succ(N);
  PHASEERR := false;
end;

% 02125: lookup in one sorted hash bucket. CMPNAME returns raw 0/1/2.
function FINDKEY(KEY: namekey): pkey;
var CUR: pkey;
begin
  CUR := NAMETAB@[HASHNAME(KEY)];
  FINDKEY := ptr(0);
  while CUR <> ptr(0) do begin
    case CMPNAME(KEY, CUR@) of
      same: begin FINDKEY := CUR; exit end;
      after: CUR := CUR@.next;
      before: exit
    end;
  end;
end;

% 02172: insert a name, preserving the sorted bucket chain.
function ENTERKEY(KEY: namekey): pkey;
var BUCKET: integer;
    FRESH, CUR, PREV: pkey;
begin
  BUCKET := HASHNAME(KEY);
  CUR := NAMETAB@[BUCKET];
  if CUR = ptr(0) then begin
    NEWKEY(KEYPOOL); FRESH := ;
    NAMETAB@[BUCKET] := ;
    with FRESH@ do begin text := KEY; next := ptr(0) end;
  end else begin
    PREV := ptr(0);
    (search) repeat
      case CMPNAME(KEY, CUR@) of
        same: begin ENTERKEY := CUR; exit end;
        after: begin PREV := CUR; CUR := CUR@.next end;
        before: exit search
      end;
    until CUR = ptr(0);
    NEWKEY(KEYPOOL); FRESH := ;
    with FRESH@ do begin text := KEY; next := CUR end;
    if PREV = ptr(0) then NAMETAB@[BUCKET] := FRESH
    else PREV@.next := FRESH;
  end;
  ENTERKEY := FRESH;
end;

% 02312: lookup an object by its interned name.
procedure FINDOBJ(KEY: namekey; var RESULT: objecthead);
var REC: pobj;
    I: integer;
    NAME: pkey;
    LAST: integer;
begin
% Historical compiler loaded the first word of the value parameter
% again after P/LNGPAR; the current compiler omits that unused load.
  besm(010100005B);
  NAME := FINDKEY(KEY);
  RESULT.name := ptr(0);
  if NAME = ptr(0) then exit;
  LAST := NUMOBJS(OBJPOOL);
  for I := 0 to LAST do begin
    OBJREAD(OBJPOOL, I); REC := ;
    if REC@.head.name = NAME then begin
      RESULT := REC@.head;
      exit;
    end;
  end;
end;

% 02353: associate an interned name with a module number.
procedure BINDOBJ(KEY: namekey; MODULE: integer);
var REC: pobj;
    NAME: pkey;
    I, LAST: integer;
begin
% Same historical value-parameter load as in FINDOBJ.
  besm(010100005B);
  NAME := ENTERKEY(KEY);
  LAST := NUMOBJS(OBJPOOL);
  for I := 0 to LAST do begin
    OBJEDIT(OBJPOOL, I); REC := ;
    with REC@ do if head.name = NAME then begin
      head.attr.module := MODULE;
      exit;
    end;
  end;
  OBJEDIT(OBJPOOL, NUMOBJS(OBJPOOL)+1); REC := ;
  with REC@ do begin
    head.name := NAME;
    head.attr.module := MODULE;
  end;
end;

% 04647: report the size in bytes and in 1024-byte blocks, in octal.
procedure PUTSIZE(N: integer);
begin
  N := (N + 1) * 2;
  write(N:5 oct, 'B (', (N + 1024 - 1) div 1024:3 oct, ')');
end;

% 04666: four-byte translator identifier, with NULs blanked.
procedure PUTCODE(CODE: code4);
var I: integer;
begin
  for I := 0 to 3 do
    if CODE[I] = '_000' then write(' ') else write(CODE[I]);
end;

% 04707: read N pairs; retain input position and record number.
procedure READREC(var BUFFER: pairs; N: integer);
var I, LAST: integer;
begin
  g0105 := POSITION(g0567);
  LAST := N - 1;
  for I := 0 to LAST do READPAIR(g0567, BUFFER[I]);
  g0106 := g0106 + 1;
end;

% 04735: read the body following an already-read record header.
procedure READBODY(var BUFFER: pairs);
var I, LAST: integer;
begin
  with BUFFER[0] do LAST := BUFFER[0].count - 1;
  for I := 1 to LAST do READPAIR(g0567, BUFFER[I]);
end;

% 04761: read a slice into a larger pair buffer.
procedure READPART(var BUFFER: pairs; FIRST, N: integer);
var I, LAST: integer;
begin
  LAST := N - 1;
  for I := 0 to LAST do READPAIR(g0567, BUFFER[FIRST+I]);
end;

% 05003: skip the unread tail of a record.
procedure SKIPREC(var BUFFER: pairs);
begin
  SETPOS(g0567, BUFFER[0].count + POSITION(g0567) - 1);
end;

% 05016: save input pairs in the temporary file, return its first index.
function SAVEREC(LAST: integer): integer;
var I: integer;
    V: pair;
begin
  I := NUMOBJS(g0566) + 1;
  SAVEREC := ;
  SETPOS(g0566, I);
  for I to LAST do begin
    READPAIR(g0567, V);
    PUTTEMP(g0566, V);
  end;
end;

% 05044: write N pairs to the current object stream.
procedure WRITREC(var BUFFER: pairs; N: integer);
var I, LAST: integer;
begin
  LAST := N - 1;
  for I := 0 to LAST do WRITPAIR(g0567, BUFFER[I]);
end;

% 05066: calendar correction after February in a leap year.
function LEAPDAY(YEAR, MONTH: integer): integer;
begin
  if (YEAR mod 4 = 0) and (MONTH > 2) then LEAPDAY := 1
  else LEAPDAY := 0;
end;

% 05100: timestamp counts seconds since the beginning of 1981.
procedure PUTDATE(T: integer);
var SECS, DAYS, DAY, MONTH, YEAR: integer;
begin
  PADCHAR := '0';
  DAYS := T div 86400;
  SECS := T mod 86400;
  YEAR := DAYS div 365;
  DAYS := DAYS mod 365 - YEAR div 4;
  if DAYS < 0 then begin
    YEAR := YEAR - 1;
    DAYS := DAYS + 365;
  end;
  YEAR := YEAR + 81;
  MONTH := DAYS div 31 + 2;
  if MONTHDAY[MONTH] + LEAPDAY(YEAR, MONTH) > DAYS then
    MONTH := MONTH - 1;
  DAY := DAYS - MONTHDAY[MONTH] - LEAPDAY(YEAR, MONTH) + 1;
  write(DAY:2, '.', MONTH:2, '.', YEAR:2, ' ',
        SECS div 3600:2, ':', SECS div 60 mod 60:2);
  PADCHAR := ' ';
end;

% SCANNER_INCLUDE
begin
% Compilation harness only; no linker job is executed.
  writeln;
end.D
  NAMETAB = 0C;
  ROOTPREF = 0C;
  MONTHDAY = 0, 31, 59, 90, 120, 151, 181,
             212, 243, 273, 304, 334, 365
end
