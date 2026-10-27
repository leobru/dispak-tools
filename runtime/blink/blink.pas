(*=y+,p-,t-,s7,s8,o-,m-*)
program BLINK(input, output, PADCHAR);
label 9999;
% BLINK, 4001/0275: recovered Pascal application, 02012-17344.
% Build: python3 runtime/blink/build.py (compile and compare only).
% Linked with the recovered runtime; linker is not run by build.
% Remaining compiler differences are listed in README.md/recovery.json.
% Based on LINK; Pascal code is identical after service relocation.
% Names are inherited descriptive names (no PMD).
type
  uint8 = 0..255;
  uint16 = 0..177777B;
  uint24 = 0..77777777B;
  uint32 = 0..37777777777B;
  uint15 = 0..77777B;
  uint11 = 0..2047;
  uint5 = 0..31;
  uint4 = 0..15;
  uint6 = 0..63;
  bitset = set of 0..47;
  namekey = packed array [1..10] of char;
  pkey = @keynode;
  keynode = packed record case integer of
    0: (text: namekey);
    1: (word0: integer; upper: uint32;
        marked: boolean; next: pkey);
    2: (first6: alfa)
  end;
  code4 = packed array [0..3] of char;
  codeword = packed record case integer of
    0: (word: integer); 1: (text: code4)
  end;
  pair = packed record case integer of
    0: (hi, lo: integer);
    1: (first: integer; beforelen: uint16;
        count: uint16; afterlen: uint16);
    2: (header: packed record
          kind: uint8; flags, prefcount: uint4;
          datacount: uint8; hasname: boolean;
          spare: 0..127; low: uint16 end;
        numbers: packed record entry, count, low: uint16 end);
    3: (unused: integer;
        value: packed record high: uint32;
               low: uint16 end);
    4: (signature: packed record kind: uint8;
                   magic: uint24; low: uint16 end;
        lower: integer);
    5: (unused5: integer;
        definition: packed record tags: set of 0..12;
                    low: 0..377777777777B end);
    6: (firstcode, lastcode: codeword);
    7: (unused7: integer; version: packed record
          high, number: uint8; low: uint32 end);
    8: (account: packed record high, low: uint24 end;
        unused8: integer);
    9: (date: packed record weekday: uint16;
              low: uint32 end;
        time: packed record seconds: uint32;
              low: uint16 end);
    10: (scopeword: packed record high, count, low: uint16 end;
         unused10: integer);
    11: (packedout: packed record high: set of 0..42;
                         tag: uint5 end; unused11: integer);
    12: (first6, last6: alfa);
    13: (data0, data1: packed record value: uint32; low: uint16 end);
    14: (datawords: array [0..1] of integer)
  end;
  pairs = array [0..6] of pair;
  pprefix = @prefix;
  prefix = packed record case integer of
    0: (tag, rawname: integer);
    1: (children: pprefix; kind: uint5; defindex: 0..8191;
        left: pprefix; name: pkey; reserved, hidden, spare: boolean;
        next, right: pprefix)
  end;
  defword0 = packed record
    first: uint11; count: uint5; tags: set of 0..12;
    spare: uint4; name: pprefix
  end;
  defword1 = packed record
    high: uint16; count: uint5; first: uint11;
    spare: uint6; fileindex: 0..1023
  end;
  defword2 = packed record
    scope: 0..1023; spare: uint6; ready, unused, used: boolean;
    entry, resolved: boolean;
    data: packed record case integer of
      0: (value: 0..777777777B);
      1: (spare: uint11; count: uint5; first: uint11)
    end
  end;
  pdef = @defrec;
  defrec = packed record case integer of
    0: (raw0, raw1, raw2: integer);
    1: (a: defword0; b: defword1; c: defword2)
  end;
  sectspace = (spnone, spkp, spdp, sprp);
  joinmode = (jmnone, jmconcat, jmoverlap, jmforbid);
  evalform = (fmshort, fmprefix, fmword, fmhalf);
  psect = @sectrec;
  sectrec = packed record case integer of
    0: (raw0, raw1, raw2, raw3, raw4: integer);
    1: (recordtype: uint8; space: sectspace; alignment: uint5;
        free, global: boolean; join: joinmode; rights: set of 0..4;
        fileindex: 0..511; name: pprefix;
        base: integer; high2: uint32; next: uint16;
        length: uint32; previous: uint16;
        entry: pprefix; spare4: boolean; offset: uint32);
    2: (header, links: pair; lastword: integer);
    3: (state: packed record mode: evalform; half: boolean;
          spare: uint16; tag: uint5; low: uint24 end)
  end;
  pref = @refrec;
  refrec = packed record case integer of
    0: (raw: integer);
    1: (name: pprefix; used, resolved: boolean; count: uint4;
        first: uint11; link: uint16)
  end;
  defkind = (absolute, unused, reloc, computed, entryval);
  pobj = @objectrec;
  objecthead = record
    name: pkey;
    attr: packed record case integer of
      0: (module: 0..7777777777B; low: 0..777777B);
      1: (filelen: 0..4095; filerest: 0..777777777777B);
      2: (disk: packed record length: 0..4095;
                address, spare: 0..777777B end)
    end;
  end;
  fileflags = set of 0..1;
  pfile = @filerec;
  filerec = packed record case integer of
    0: (raw0, raw1, raw2, raw3: integer);
    1: (name: pkey; spare0: 0..77777777777B;
        word1, word2: integer; spare3: uint16;
        flags: fileflags; module: 0..7777777777B);
    2: (d0, d1, d2: integer;
        filedata: packed record high: 0..777777B;
                  length: 0..4095; address: 0..777777B end);
    3: (n0: packed record high: uint15; spare: boolean;
             ndefs, firstdef: uint16 end;
        n1: packed record nsects: uint16; high: uint16;
             firstsect: uint16 end;
        n2: packed record nrefs: uint16; high: uint16;
             firstref: uint16 end; w3: integer);
    4: (u0, u1, u2: integer;
        unresolved: packed record first: uint16;
                    low: uint32 end)
  end;
  psegment = @segmentrec;
  segmentrec = packed record case integer of
    0: (limit: boolean; spare0: 0..17777777777B;
        fileindex: uint16);
    1: (diskbase: 0..7777777B; loadbase: 0..777777777B);
    2: (above, concatenate: boolean; length: 0..7777777B;
        spare2: 0..127; count: uint8; low: 0..1023);
    3: (flags: packed record bound, ready: boolean;
          spare: 0..7777777777B; index: uint16 end)
  end;
  objectrec = record
    head: objecthead;
    before: array [2..7] of integer;
    owner: packed record account: set of uint5; low: uint16 end;
    w9: integer;
    calendar: packed record weekday: uint16; low: uint32 end;
    created: packed record seconds: uint32; low: uint16 end;
    after: array [12..16] of integer
  end;
  phash = @hashtable;
  hashtable = array [0..127] of pkey;
  metric = (mtcpu, mtwait, mttotal);
  stamp = array [metric] of integer;
  stage = (stzero, stinit, stparse, stgather, stresolve, stplace,
           steval, stoutput, stlabels, stend);
  evalstate = (evnone, evdone, evmixed, evwait);
  ordering = (same, after, before);
  charclass = (letter, digit, white, punct, atend);
  dateparts = array [0..3] of integer;
var
  g0050, g0051, g0052, g0053, g0054, g0055, g0056, g0057,
  g0060, g0061, g0062, g0063, g0064, g0065: integer;
  FIRSTREF: integer;
  g0067,
  g0070, g0071, g0072, g0073, g0074, g0075, g0076, g0077,
  g0100, g0101, g0102, g0103: integer;
  NEXTADDR: integer;
  BYTEPOS, RECNO: integer;
  g0107,
  g0110: integer;
  g0111: evalform;
  g0112: integer;
  OUTPAIR: pair;
  HALFOUT: boolean;
  ALLFOUND: boolean;
  PHASEERR: boolean;
  MODULEERR: boolean;
  g0121, g0122: boolean;
  CURRENTFILE: filerec;
  g0127: psect;
  SEGREC: psegment;
  g0131: pprefix;
  g0132: pdef;
  LASTSECT: sectrec;
  g0140: pprefix;
  NAMETAB: phash;
  ROOTPREF: pprefix;
  XLATTAB: array [char] of charclass;
  PRINTOPT: bitset;
  g0544: integer;
  OUTFILE, SCHEMAFILE, LABELFILE: objecthead;
  SYSTEMOUT: boolean;
  KEYPOOL, PATHPOOL, OBJPOOL, FILEPOOL, SEGPOOL, DEFPOOL, REFPOOL,
  SECTPOOL, PREFPOOL, ENTRYPOOL, g0566, g0567, g0570: integer;
  PHASE: stage;
  TIMES: array [stzero..stlabels] of stamp;
  MONTHDAY: array [1..13] of integer;
  g0642: evalstate;
  g0643, g0644, g0645, g0646, g0647: integer;
  PADCHAR: char;

function HASHNAME(var KEY: namekey): integer; fortran;
function CMPNAME(var KEY: namekey; var NODE: keynode): ordering;
  fortran;
function NAMELEN(var KEY: keynode): integer; fortran;
procedure GETSTAMP(var RESULT: stamp); fortran;
procedure NEWKEY(POOL: integer); fortran;
procedure OBJREAD(POOL, INDEX: integer); fortran;
procedure OBJEDIT(POOL, INDEX: integer); fortran;
procedure FILEEDIT(POOL, INDEX: integer); fortran;
procedure TABREAD(POOL, INDEX: integer); fortran;
procedure TABGET(POOL, INDEX: integer; var RESULT: pprefix);
  fortran;
procedure TABPUT(POOL, INDEX: integer; var VALUE: pprefix); fortran;
procedure PUTDEF(POOL, INDEX: integer; var VALUE: defrec); fortran;
procedure PUTSECT(POOL, INDEX: integer; var VALUE: sectrec); fortran;
procedure PUTREF(POOL, INDEX: integer; var VALUE: refrec); fortran;
procedure INITVEC(SIZE, LIMIT: integer; NAME: alfa; POOL: integer);
  fortran;
function UNPACKKY(var KEY: keynode; var FIRST: char): integer;
  fortran;
procedure PACKKEY(var FIRST: char; N: integer; var KEY: namekey);
  fortran;
function NUMOBJS(POOL: integer): integer; fortran;
function POSITION(POOL: integer): integer; fortran;
procedure SETPOS(POOL, INDEX: integer); fortran;
procedure READPAIR(POOL: integer; var V: pair); fortran;
procedure WRITPAIR(POOL: integer; var V: pair); fortran;
procedure PUTTEMP(POOL: integer; var V: pair); fortran;
procedure CLOSE(POOL: integer); fortran;
procedure GETFILED(POOL, INDEX: integer; var RESULT: filerec);
  fortran;
procedure PUTFILED(POOL, INDEX: integer; var VALUE: filerec);
  fortran;
procedure GETPAIR(POOL, INDEX: integer; var VALUE: pair); fortran;
procedure PUTPAIR(POOL, INDEX: integer; var VALUE: pair); fortran;
procedure TABPAIR(POOL, INDEX: integer; var VALUE: pair); fortran;
procedure TABFILE(POOL, INDEX: integer; var VALUE: filerec); fortran;
procedure ATTACH(MODE, ADDRESS, LENGTH: integer; NAME: alfa;
                 STREAM: integer); fortran;
procedure GETDATE(var RESULT: dateparts); assembler;


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
  (q) while (P <> ROOTPREF) and (P <> ptr(0)) do (r) begin
    COUNT := COUNT + 1;
    PART[COUNT] := P@.name;
    P := P@.next;
  end;
  (q) for COUNT := COUNT downto 1 do (r) write(PART[COUNT]@.text);
end;

% 02070: length of the same qualified name.
function PATHLEN(P: pprefix): integer;
var COUNT: integer;
begin
  COUNT := 0;
  (q) while (P <> ROOTPREF) and (P <> ptr(0)) do (r) begin
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
  (q) while CUR <> ptr(0) do (r)
    case CMPNAME(KEY, CUR@) of
      same: begin FINDKEY := CUR; exit end;
      after: CUR := CUR@.next;
      before: exit
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
  (*q*) for I := 0 to LAST do (r) begin
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
  (x);
  LAST := NUMOBJS(OBJPOOL);
  (*q*) for I := 0 to LAST do (r) begin
    OBJEDIT(OBJPOOL, I); REC := ;
    with REC@ do if head.name = NAME then begin
      head.attr.module := MODULE;
      exit;
    end;
  end;
  (x);
  OBJEDIT(OBJPOOL, NUMOBJS(OBJPOOL)+1); REC := ;
  with REC@ do begin
    head.name := NAME;
    head.attr.module := MODULE;
  end;
end;

% Recovered link-job parser READJOB (03717) and its nested scanner.
procedure READJOB;
type
  charbits = set of '_000'..'_057';
  tokentype = (kalfa, kname, kfile, knumber, kdecimal, kpunct);
  token = record case integer of
    0: (text: namekey);
    1: (number: integer);
    2: (symbol: char);
    3: (a6: alfa);
    5: (first6, last6: alfa);
    4: (disk: packed record length: 0..4095;
              address, spare: 0..777777B end);
    6: (filecode: packed record module: 0..7777777777B;
                 spare: 0..777777B end)
  end;
var CH, SAVED: char;
    LINENO, FIRSTCOL, LASTCOL, COLUMN: integer;
    NFILES, LOADADDR, DISKADDR, SEGLEN, SEGINDEX, FILEINDEX: integer;
    CLASS: charclass;
    VALUE: token;
    ALIAS: namekey;
    KIND: tokentype;
    PUSHED: boolean;
    LOADABOVE, CONCAT, HAVESCHEMA, HAVEOUTPUT, HAVEOBJECTS,
    HAVEQUAL: boolean;
    COMMONFLAGS: fileflags;
    CURRENT: objecthead;
    REC: pfile;
    LINEBUF: packed array [1..120] of char;
    LIMIT: integer;

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
  writeln("* * *  OШИБKA B ЗAДAHИИ KOMПOHOBЩИKY * * *");
  write('CTPOKA ', LINENO:1, ' : ');
  case ERROR of
    0: writeln("OШИБKA B ЦEЛOM");
    1: writeln("HEДOПYCTИMЫЙ BИPTYAЛЬHЫЙ HOMEP");
    2: writeln("HEДOПYCTИMЫЙ HOMEP ЗOHЫ");
    3: writeln("HEBEPHAЯ ДЛИHA ФAЙЛA");
    4: writeln("OTCYTCTBYET ДЛИHA ФAЙЛA");
    5: writeln("BCTPETИЛCЯ KOHEЦ BBOДHOГO ФAЙЛA");
    6: begin COLUMN := COLUMN + 1;
      writeln("HEДOПYCTИMЫЙ CИMBOЛ") end;
    7: writeln("HEBEPHЫЙ PAЗДEЛИTEЛЬ");
    15: writeln("HEДOПYCTИMЫЙ OTЛAДOЧHЫЙ ФЛAГ");
    8: writeln("HEДOПYCTИMЫЙ PEЖИM ПEЧATИ");
    10: writeln("ФAЙЛ HE OПPEДEЛEH");
    11: writeln("OTCYTCTBYET PAЗДEЛ 'ФAЙЛЫ'");
    12: writeln("HEДOПYCTИMAЯ KOMAHДA");
    13: writeln("ПOBTOPHOE OПPEДEЛEHИE BЫXOДHOГO ФAЙЛA");
    16: writeln("ЗAПPEЩEHHЫЙ KBAЛИФИKATOP ФAЙЛA");
    17: writeln("HEДOПYCTИMЫЙ KBAЛИФИKATOP ФAЙЛA");
    9: writeln("HET OБ'EKTHЫX ФAЙЛOB");
    14: writeln("HEДOПYCTИMЫЙ KBAЛИФИKATOP CEГMEHTA");
    18: writeln("HE OПPEДEЛEH BЫXOДHOЙ ФAЙЛ");
    19: writeln("HAPYШEHA ПOCЛEДOBATEЛЬHOCTЬ ПAPAMETPOB");
    20: writeln("AДPEC ЗAГPYЗKИ БOЛЬШE MAKCИMAЛЬHO ДOПYCTИMOГO");
    21: writeln("AДPEC HA ДИCKE БOЛЬШE MAKCИMAЛЬHO ДOПYCTИMOГO");
    22: writeln("ДЛИHA CEГMEHTA БOЛЬШE MAKCИMAЛЬHO ДOПYCTИMOЙ");
    others: writeln("OШCИC=", ERROR:1, '!!!')
  end;
  if CH <> '_037' then begin
    LASTCOL := COLUMN - 1;
    (q) while CH <> '_012' do (r) NEXTCHAR;
    COLUMN := 1;
    (q) while LINEBUF[COLUMN] <> '_012' do (r) begin
      write(LINEBUF[COLUMN]); COLUMN := COLUMN + 1;
    end;
    writeln;
    if FIRSTCOL >= LASTCOL then LASTCOL := COLUMN;
    (q) for I := 2 to FIRSTCOL do (r) write(' ');
    LIMIT := LASTCOL - 1;
    (*q*) for I := FIRSTCOL to LIMIT do (r) write('^');
    (x);
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
  (q) while CLASS = white do (r) begin NEXTCHAR; (q); end;
end;

% 02775.
procedure SKIPTAIL;
begin
  (q) while not (CLASS in [white, punct, atend]) do (r) begin
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
    (x);
    LIMIT := COUNT - 1;
    (*q*) for I to LIMIT do (r) begin
      DIGIT := ord(BUFFER[I]) - 48;
      if (DIGIT < 0) or (DIGIT >= BASE) then BADJOB(0);
      ACCUM := ACCUM * BASE + DIGIT;
    end;
    (x);
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
  (x);
  COUNT := COUNT - 1;
  TAIL := BUFFER[COUNT];
  RESULT := 0;
  SCALE := 1;
  if TAIL = 'H' then begin
    LIMIT := COUNT - 1;
    (*q*) for I to LIMIT do (r) begin
      DIGIT := ord(BUFFER[I]) - 31;
      if DIGIT in [17..26] then DIGIT := DIGIT - 17
      else if DIGIT in [34..39] then DIGIT := DIGIT - 34 + 10
      else BADJOB(0);
      RESULT := RESULT * 16 + DIGIT;
    end;
    (x);
  end else if TAIL = 'B' then RESULT := CONVERT(8)
  else if TAIL = "_372" then begin
    SCALE := 1024; RESULT := CONVERT(8);
  end else if TAIL = 'C' then begin
    SCALE := 256; RESULT := CONVERT(8);
  end else if TAIL = "_344" then RESULT := CONVERT(10)
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
  (x);
end;

% 03176.
procedure SCANNAME;
var I: integer;
begin
%  with VALUE do begin
%    first6 := '      '; last6 := '    _000_000';
%  end;
  VALUE := [ '      ', '    _000_000' ];
  I := 1;
  (q) while INNAME(CLASS) and (I <= 10) do (r) begin
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
    (x);
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
  if CLASS = letter then
    if 1 in EXPECT then begin SCANNAME; KIND := kname end
    else if 0 in EXPECT then begin SCANALFA; KIND := kalfa end
    else BADJOB(6)
  else if CLASS = digit then
    if 2 in EXPECT then begin SCANFILE; KIND := kfile end
    else if 3 in EXPECT then begin SCANINT(VALUE.number);
      KIND := knumber end
    else if 4 in EXPECT then begin SCANDEC(VALUE.number);
      KIND := kdecimal end
    else BADJOB(6)
  else if CLASS = punct then
    if 5 in EXPECT then begin
      if CH = '*' then begin
        NEXTCHAR;
        if CH = '/' then CH := '_037' else PUSHCHAR('*');
      end;
      VALUE.symbol := chr(ord(CH) - 31);
      KIND := kpunct;
      NEXTCHAR;
    end else BADJOB(6)
  else if CLASS = atend then BADJOB(6);
end;

% 03455. Punctuation is represented as ord(character)-31.
procedure EXPECT(PUNCTS: charbits);
begin
  GETTOKEN([5]);
  if not (VALUE.symbol in PUNCTS) then BADJOB(7);
end;

% 03466. Intern an object-file entry and refresh its module number.
function GETFILE(KEY: objecthead): integer;
label 1;
var I: integer;
    REC: pfile;
begin
  (*q*) for I := 0 to NUMOBJS(FILEPOOL) do (r) begin
    FILEEDIT(FILEPOOL, I); REC := ;
    if REC@.name = KEY.name then goto 1;
  end;
  I := NUMOBJS(FILEPOOL) + 1;
  FILEEDIT(FILEPOOL, I); REC := ;
  REC@ := [0C, 0C, 0C, 0C];
  1: with REC@ do begin
    name := KEY.name; module := shift(integer(KEY.attr), 18);
  end;
  GETFILE := I;
end;

% 03541. Apply one per-file flag to a list of named object files.
procedure SELECTFILES(FLAG: integer);
var I: integer;
    REC: pfile;
    OBJ: objecthead;
    LIMIT: integer;
begin
  if VALUE.symbol = '_016' then COMMONFLAGS := COMMONFLAGS + [FLAG];
  repeat
    GETTOKEN([1]);
    FINDOBJ(VALUE.text, OBJ);
    if OBJ.name = ptr(0) then BADJOB(10);
    (search) begin
      LIMIT := NUMOBJS(FILEPOOL);
      (*q*) for I := 0 to LIMIT do (r) begin
        FILEEDIT(FILEPOOL, I); REC := ;
        if REC@.name = OBJ.name then exit search;
      end;
      FILEEDIT(FILEPOOL, NUMOBJS(FILEPOOL)+1); REC := ;
      REC@ := [0C, 0C, 0C, 0C];
      REC@.name := OBJ.name;
    end;
    with REC@ do flags := flags + [FLAG];
    EXPECT(['_000','_015','_034']);
    (x);
  until VALUE.symbol in ['_000','_034'];
  (x);
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
    if VALUE.a6 = "CEKЦИИ" then PRINTOPT := PRINTOPT + [1]
    else if VALUE.a6 = "PAЗДEЛ" then PRINTOPT := PRINTOPT + [2]
    else if VALUE.a6 = 'CTAT  ' then PRINTOPT := PRINTOPT + [3]
    else if VALUE.a6 = "MOДYЛИ" then PRINTOPT := PRINTOPT + [0]
    else if VALUE.a6 = "METKИ " then PRINTOPT := PRINTOPT + [4]
    else BADJOB(8);
    EXPECT(['_015','_034']);
    if VALUE.symbol = '_034' then exit;
    GETTOKEN([0]);
    (x);
  until false;
end;

% 03717. File declarations, load list and optional explicit layout.
begin
  LINENO := 0; COLUMN := 1; PUSHED := false;
  NEXTCHAR;
  PRINTOPT := [2]; COMMONFLAGS := [];
  GETTOKEN([0]);
  if VALUE.a6 <> "ФAЙЛЫ " then BADJOB(11);
  repeat
    GETTOKEN([1]); ALIAS := VALUE.text;
    EXPECT(['_036']); GETTOKEN([2]);
    BINDOBJ(ALIAS, VALUE.filecode.module);
    EXPECT(['_015','_034']);
  until VALUE.symbol = '_034';
  (x);
  GETTOKEN([0]);
  if VALUE.a6 <> "ЗAГP  " then BADJOB(12);
  HAVESCHEMA := false; HAVEOUTPUT := ;
  HAVEOBJECTS := ; HAVEQUAL := ;
  NFILES := 0; SEGINDEX := ; SETPOS(SEGPOOL, 2);
  repeat
    GETTOKEN([1]); FINDOBJ(VALUE.text, CURRENT);
    if CURRENT.name = ptr(0) then BADJOB(10);
    EXPECT(['_000','_015','_020','_034']);
    if VALUE.symbol = '_020' then begin
      HAVEQUAL := true; GETTOKEN([0]);
      if VALUE.a6 = "PAЗДEЛ" then begin
        if HAVEOUTPUT then BADJOB(13);
        if HAVESCHEMA then BADJOB(16);
        if not HAVEOBJECTS then BADJOB(9);
        HAVEOUTPUT := true; OUTFILE := CURRENT;
        SYSTEMOUT := false; LOADADDR := 1;
        EXPECT(['_000','_015','_034']);
      end else if VALUE.a6 = "CИC   " then begin
        if HAVEOUTPUT then BADJOB(13);
        if not HAVEOBJECTS and not HAVESCHEMA then BADJOB(9);
        HAVEOUTPUT := true; OUTFILE := CURRENT; SYSTEMOUT := true;
        if HAVEOBJECTS then begin
          EXPECT(['_036']); GETTOKEN([3]); LOADADDR := VALUE.number;
        end;
        EXPECT(['_000','_015','_034']);
      end else if VALUE.a6 = "ЛИCT  " then PRINTSEL
      else if VALUE.a6 = 'CXEMA ' then begin
        if HAVEOBJECTS then BADJOB(16);
        SCHEMAFILE := CURRENT; HAVESCHEMA := true;
        EXPECT(['_000','_015','_034']);
      end else if VALUE.a6 = "METKИ " then begin
        LABELFILE := CURRENT;
        EXPECT(['_000','_015','_016','_034','_036']);
        if VALUE.symbol in ['_016','_036'] then SELECTFILES(1C)
        else COMMONFLAGS := COMMONFLAGS + [1];
      end else BADJOB(17);
    end else if VALUE.symbol = '_015' then begin
      if HAVESCHEMA or HAVEQUAL then BADJOB(19);
      NFILES := NFILES + 1; HAVEOBJECTS := true;
      NEWKEY(SEGPOOL); SEGREC := ;
      with SEGREC@ do begin
        fileindex := GETFILE(CURRENT); limit := false;
      end;
    end;
  until VALUE.symbol in ['_000','_034'];
  (x);
  if not HAVEOUTPUT then BADJOB(18);
  if HAVESCHEMA then begin
    if VALUE.symbol = '_000' then BADJOB(5);
    GETTOKEN([1,5]);
    if KIND = kpunct then
      if VALUE.symbol = '_000' then BADJOB(5) else BADJOB(7);
    (layout) repeat
      LOADADDR := 1; DISKADDR := 0; SEGLEN := 377777B;
      LOADABOVE := true; CONCAT := false; NFILES := 0;
      SETPOS(SEGPOOL, SEGINDEX + 2);
      (objects) repeat
        FINDOBJ(VALUE.text, CURRENT);
        if CURRENT.name = ptr(0) then BADJOB(10);
        NFILES := NFILES + 1;
        NEWKEY(SEGPOOL); SEGREC := ;
        with SEGREC@ do begin
          fileindex := GETFILE(CURRENT); limit := false;
        end;
        EXPECT(['_000','_014','_033','_034']);
        if VALUE.symbol <> '_014' then exit objects;
        GETTOKEN([1]); (q);
      until false;
      if VALUE.symbol = '_033' then
        (quals) repeat
          (onequal) begin
            GETTOKEN([0,3]);
            if KIND = knumber then LOADADDR := VALUE.number
            else if VALUE.a6 = "HAЗ   " then begin
              EXPECT(['_036']); GETTOKEN([3]); LOADADDR := VALUE.number;
            end else if VALUE.a6 = "HAД   " then begin
              EXPECT(['_014','_036']);
              LOADABOVE := VALUE.symbol = '_014';
              GETTOKEN([3]); DISKADDR := VALUE.number;
              EXPECT(['_000','_015','_017','_034']);
              CONCAT := VALUE.symbol = '_017';
              if not CONCAT then begin
                if VALUE.symbol = '_015' then exit onequal;
                exit quals;
              end else;
            end else if VALUE.a6 = "ДЛИ   " then begin
              EXPECT(['_036']); GETTOKEN([3]); SEGLEN := VALUE.number;
            end else begin BADJOB(14); (q) exit q end;
            EXPECT(['_000','_015','_034']);
          end;
        until VALUE.symbol in ['_000','_034'];
      OBJEDIT(SEGPOOL, SEGINDEX); SEGREC := ;
      with SEGREC@ do begin
        if DISKADDR > 7777777B then BADJOB(21);
        diskbase := DISKADDR;
        if LOADADDR >= 1000000000B then BADJOB(20);
        loadbase := LOADADDR;
      end;
      NEWKEY(SEGPOOL); SEGREC := ;
      with SEGREC@ do begin
        above := LOADABOVE; concatenate := CONCAT;
        if SEGLEN > 377777B then BADJOB(22);
        length := SEGLEN; count := NFILES;
      end;
      SEGINDEX := NUMOBJS(SEGPOOL) + 1;
      if VALUE.symbol = '_000' then exit layout;
      GETTOKEN([1,5]);
    until KIND = kpunct;
  end else begin
    if not HAVEOBJECTS then BADJOB(9);
    OBJEDIT(SEGPOOL, SEGINDEX); SEGREC := ;
    with SEGREC@ do begin
      diskbase := 0;
      if LOADADDR >= 1000000000B then BADJOB(20);
      loadbase := LOADADDR;
    end;
    NEWKEY(SEGPOOL); SEGREC := ;
    with SEGREC@ do begin
      above := false; concatenate := false;
      length := OUTFILE.attr.filelen * 1024;
      count := NFILES;
    end;
  end;
  if COMMONFLAGS <> [] then begin
    (x);
    LIMIT := NUMOBJS(FILEPOOL);
    (*q*) for FILEINDEX := 0 to LIMIT do (r) begin
      FILEEDIT(FILEPOOL, FILEINDEX); REC := ;
      with REC@ do flags := flags mod COMMONFLAGS;
    end;
  end;
  CLOSE(OBJPOOL);
end;

% 04475: print a phase heading once before its first diagnostic.
procedure PHASEMSG;
begin
  if not PHASEERR then begin
    write("> > >  OШИБKИ HA ЭTAПE ");
    case PHASE of
      stgather: write("CБOPKИ OПPEДEЛEHИЙ И CCЫЛOK");
      stresolve: write("PAЗPEШEHИЯ CCЫЛOK");
      stplace: write("PACПPEДEЛEHИЯ ПAMЯTИ");
      steval: write("BЫЧИCЛEHИЯ ЗHAЧEHИЙ OБ'EKTOB");
      stoutput: write("ФOPMИPOBAHИЯ PAЗДEЛA")
    end;
    writeln(' < < <'); PHASEERR := true;
  end;
end;

% 04541: module heading, likewise emitted once per input module.
procedure MODULEMSG(REC: pfile);
begin
  PHASEMSG;
  if not MODULEERR then begin
    writeln("* * * MOДYЛЬ ", REC@.name@.text:1, ' * * *');
    MODULEERR := true;
  end;
end;

% 04562: identify the input record and its position in the module.
procedure RECORDMSG(KIND: integer);
begin
  write("ЗAПИCЬ TИПA <", KIND:2 hex, '> (N=', RECNO:1);
  write(", AДPEC - ", BYTEPOS * 2 div 1024:2 oct, ':',
        BYTEPOS * 2 mod 1024:4 oct, ')');
end;

% 04612 and 04635: preserve the file-table descriptor around input.
procedure OPENIN(INDEX: integer);
begin
  GETFILED(FILEPOOL, INDEX, CURRENTFILE);
  ATTACH(2, CURRENTFILE.filedata.address,
         CURRENTFILE.filedata.length,
         CURRENTFILE.name@.first6, g0567);
  RECNO := 0; MODULEERR := false;
end;

procedure CLOSEIN(INDEX: integer);
begin
  PUTFILED(FILEPOOL, INDEX, CURRENTFILE); CLOSE(g0567);
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
  (q) for I := 0 to 3 do (r)
    if CODE[I] = '_000' then write(' ') else write(CODE[I]);
end;

% 04707: read N pairs; retain input position and record number.
procedure READREC(var BUFFER: pairs; N: integer);
var I, LAST: integer;
begin
  BYTEPOS := POSITION(g0567);
  (x);
  LAST := N - 1;
  (*q*) for I := 0 to LAST do (r) READPAIR(g0567, BUFFER[I]);
  (x);
  RECNO := RECNO + 1;
end;

% 04735: read the body following an already-read record header.
procedure READBODY(var BUFFER: pairs);
var I, LAST: integer;
begin
  with BUFFER[0] do begin
    (x);
    LAST := BUFFER[0].count - 1;
  end;
  (*q*) for I := 1 to LAST do (r) READPAIR(g0567, BUFFER[I]);
  (x);
end;

% 04761: read a slice into a larger pair buffer.
procedure READPART(var BUFFER: pairs; FIRST, N: integer);
var I, LAST: integer;
begin
  (x);
  LAST := N - 1;
  (*q*) for I := 0 to LAST do (r) READPAIR(g0567, BUFFER[FIRST+I]);
  (x);
end;

% 05003: skip the unread tail of a record.
procedure SKIPREC(var BUFFER: pairs);
begin
  SETPOS(g0567, POSITION(g0567) + BUFFER[0].count - 1);
end;

% 05016: save input pairs in the temporary file, return its first index.
function SAVEREC(LAST: integer): integer;
var I: integer;
    V: pair;
begin
  I := NUMOBJS(g0566) + 1;
  SAVEREC := ;
  SETPOS(g0566, I);
  (q) for I to LAST do (r) begin
    READPAIR(g0567, V);
    PUTTEMP(g0566, V);
  end;
end;

% 05044: write N pairs to the current object stream.
procedure WRITREC(var BUFFER: pairs; N: integer);
var I, LAST: integer;
begin
  (x);
  LAST := N - 1;
  (*q*) for I := 0 to LAST do (r) WRITPAIR(g0567, BUFFER[I]);
  (x);
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

% 05170: stamp an object with account, weekday and creation time.
procedure STAMPOBJ(REC: pobj);
var DATE: dateparts;
    TICKS: integer;
    ACCOUNT: bitset;
begin
  besm(0530010B); besm(04150011B);
  TICKS := ;
  besm(0500100B); (q);
  ACCOUNT := ;
  GETDATE(DATE);
  with REC@ do begin
    owner.account := ACCOUNT;
    calendar.weekday := DATE[3];
    created.seconds :=
      TICKS div 50 + (MONTHDAY[DATE[1]] +
       ((DATE[2]-81) * 365 + (DATE[2]-81) div 4) +
       LEAPDAY(DATE[2], DATE[1]) + DATE[0] - 1) * 86400;
  end;
end;

% Definition/reference pass of LINK1, beginning at 05232.
procedure GATHER(FILEIDX: integer);
type
  namecode = packed record
    first6, second6, third6: alfa;
    high: uint15; indexed: boolean; index, low: uint16
  end;
var l4, l5: integer;
    FIRSTDEF, NDEF, FIRSTSEC, NSEC, FIRSTREF, NREF: integer;
    NPREF, NENTRY, CURSEC, PREVSEC, NEWSEC, DEFIDX, REFIDX: integer;
    I, BODYLEN, EXTRALEN, DATALEN, PREFLEN: integer;
    SECTION: sectrec;
    PSEC, QSEC: psect;
    DEFINITION: defrec;
    PD: pdef;
    REFERENCE: refrec;
    PR: pref;
    PFNODE: pprefix;
    ENTRYNODE: pprefix;
    NAME: pprefix;
    BUFFER: record case integer of
      0: (data: pairs);
      1: (head: pair; code: namecode; pad: array [1..8] of integer)
    end;
    HEADER, TAIL: pairs;
    GOODEND, LABELSON: boolean;

function UNPACKNM(var CODE: namecode; var FIRST: char): integer;
  fortran;

% 05276. Fatal object-file diagnostics return to the main abort label.
procedure BADOBJ(ERROR: integer);
var NEWKIND, OLDKIND: defkind;
    OLDDEF: pdef;
    OLDFILE: pfile;

% 05232. Print the definition class, return its precedence.
function PUTKIND(REC: pdef; PLURAL: boolean): defkind;
begin
  with REC@ do
    if c.entry then begin
      if PLURAL then write("BXOДA") else write("BXOД");
      PUTKIND := entryval;
    end else begin
      if not c.resolved then begin
        write("BЫЧ."); PUTKIND := computed
      end
      else if c.scope <> 0 then begin
        write("ПEP."); PUTKIND := reloc
      end
      else begin write("AБC."); PUTKIND := absolute end;
      if PLURAL then write("ЗHAЧEHИЯ") else write("ЗHAЧEHИE");
    end;
end;

begin
  MODULEMSG(ref(CURRENTFILE));
  case ERROR of
    0: begin
      RECORDMSG(BUFFER.data[0].header.kind);
      writeln(" : HEДOПYCTИMЫЙ HOMEP ПPEФИKCA");
    end;
    1: begin
      RECORDMSG(BUFFER.data[0].header.kind);
      writeln(" : HEДOПYCTИMЫЙ HOMEP ЭЛ.MOДYЛЯ");
    end;
    3: begin
      write("ПOBTOPHOE OПPEДEЛEHИE ГЛOБAЛЬHOГO ");
      NEWKIND := PUTKIND(ref(DEFINITION), true);
      write(' '''); PUTPATH(NAME); writeln(''',');
      write("PAHEE OПPEДEЛEHHOГO B MOДYЛE ");
      TABREAD(DEFPOOL, NAME@.defindex); OLDDEF := ;
      OBJREAD(FILEPOOL, OLDDEF@.b.fileindex); OLDFILE := ;
      write(OLDFILE@.name@.text:1, ' KAK ');
      OLDKIND := PUTKIND(OLDDEF, false); writeln('.');
      if NEWKIND >= OLDKIND then begin
        NAME@.defindex := DEFIDX; OLDFILE := ref(CURRENTFILE);
      end;
      writeln("ИCПOЛЬ-HO OПPEДEЛEHИE ИЗ MOДYЛЯ ",
              OLDFILE@.name@.text:1, '.');
      exit;
    end;
    4: writeln("ИCПOPЧEH OБ'EKTHЫЙ MOДYЛЬ - ",
               "OTCYTCTBYET ЗAПИCЬ ЗAГOЛOBKA");
    5: begin
      RECORDMSG(BUFFER.data[0].header.kind);
      writeln(" HAXOДИTCЯ HE HA CBOEM MECTE");
    end;
    6: begin
      RECORDMSG(BUFFER.data[0].header.kind);
      writeln(" : HEДOПYCTИMЫЙ TИП ЗAПИCИ");
    end;
    others: begin
      RECORDMSG(BUFFER.data[0].header.kind);
      writeln(" OШCИC=", ERROR:1, '!!!');
    end
  end;
  goto 9999;
end;

% 05472. Expand an indexed name and intern its dotted components.
function RESNAME(MODE: integer; CODE: namecode): pprefix;
var INDEX, LENGTH, FIRST, NPARTS, J, ITER, K: integer;
    ORDER: ordering;
    CHARS: array [1..24] of char;
    KEY: namekey;
    PARTS: array [1..12] of pkey;
    NODE, PARENT, PREVIOUS: pprefix;
    KEYREF: pkey;
    DP: pdef;
    RP: pref;
    SP: psect;
begin
  INDEX := CODE.index; LENGTH := 0;
  if INDEX = 0 then NODE := ROOTPREF
  else begin
    if CODE.indexed then
      case MODE of
        4,6: begin
          if INDEX > NDEF then BADOBJ(0);
          TABREAD(DEFPOOL, FIRSTDEF+INDEX-1); DP := ;
          NODE := DP@.a.name;
        end;
        8: begin
          if INDEX > NREF then BADOBJ(0);
          TABREAD(REFPOOL, FIRSTREF+INDEX-1); RP := ;
          NODE := RP@.name;
        end;
        3: begin
          if INDEX > NPREF then BADOBJ(0);
          TABGET(PREFPOOL, INDEX-1, NODE);
        end;
        1: begin
          if INDEX > NENTRY then BADOBJ(1);
          TABGET(ENTRYPOOL, INDEX-1, NODE);
        end;
        2: begin
          if INDEX > NSEC then BADOBJ(0);
          TABREAD(SECTPOOL, FIRSTSEC+INDEX-1); SP := ;
          NODE := SP@.name;
        end;
        others: BADOBJ(2)
      end
    else begin
      if INDEX > NPREF then BADOBJ(0);
      TABGET(PREFPOOL, INDEX-1, NODE);
    end;
    if CODE.first6[1] <> '.' then
      with NODE@ do begin
        LENGTH := UNPACKKY(name@, CHARS[1]); NODE := next;
      end;
  end;
  LENGTH := UNPACKNM(CODE, CHARS[LENGTH+1]) + LENGTH;
  if LENGTH = 0 then begin RESNAME := ptr(0); exit end;
  FIRST := 1; NPARTS := ;
  (q) for K := 2 to LENGTH do (r) begin
    J := K-FIRST;
    if (CHARS[K] <> '.') and (J <= 10) then begin
    end else begin
      PACKKEY(CHARS[FIRST], J, KEY);
      PARTS[NPARTS] := ENTERKEY(KEY);
      NPARTS := NPARTS+1; FIRST := K;
    end;
  end;
  PACKKEY(CHARS[FIRST], LENGTH-FIRST+1, KEY);
  PARTS[NPARTS] := ENTERKEY(KEY);
  (q) for ITER to NPARTS do (r) begin
    PARENT := NODE; NODE := NODE@.children; KEYREF := PARTS[ITER];
    (newnode) begin
    if NODE = ptr(0) then begin
      NEWKEY(PATHPOOL); NODE := ;
      PARENT@.children := NODE;
    end else begin
      (search) repeat
        PREVIOUS := NODE;
        with NODE@ do
        ORDER := CMPNAME(KEYREF@.text, name@);
        case ORDER of
          same: exit search;
          after: NODE := NODE@.right;
          before: NODE := NODE@.left
        end;
      until NODE = ptr(0);
      if ORDER = same then exit newnode;
      NEWKEY(PATHPOOL); NODE := ;
      with PREVIOUS@ do
        if ORDER = after then right := NODE else left := NODE;
    end;
    NODE@ := [0C, 0C];
    with NODE@ do begin next := PARENT; name := KEYREF end;
    end;
  end;
  RESNAME := NODE;
  if (MODE = 6) or (MODE = 4) then
    with NODE@ do begin kind := MODE; hidden := not LABELSON end;
end;

% 06063, 06101, 06121. Initialize the next table record and index.
procedure NEWDEF;
begin
  DEFIDX := NUMOBJS(DEFPOOL)+1;
  if NDEF = 0 then FIRSTDEF := DEFIDX;
  NDEF := NDEF+1; DEFINITION := [0C, 0C, 0C];
end;

procedure NEWSECT;
begin
  NEWSEC := NUMOBJS(SECTPOOL)+1;
  if NSEC = 0 then FIRSTSEC := NEWSEC;
  NSEC := NSEC+1; SECTION := [0C, 0C, 0C, 0C, 0C];
end;

procedure NEWREF;
begin
  REFIDX := NUMOBJS(REFPOOL)+1;
  if NREF = 0 then FIRSTREF := REFIDX;
  NREF := NREF+1; REFERENCE := [0C];
end;

% 06135, 06155, 06175, 06204. Preserve variable record tails.
procedure SAVEPREF(N: integer);
var RESERVED: integer;
begin
  if N <> 0 then begin
    DEFINITION.a.count := N; DEFINITION.a.first := SAVEREC(N);
  end;
end;

procedure SAVEDATA(N: integer);
var RESERVED: integer;
begin
  if N <> 0 then begin
    DEFINITION.b.count := N; DEFINITION.b.first := SAVEREC(N);
  end;
end;

procedure SKIPDATA(N: integer);
var FIRST: integer;
begin
  if N <> 0 then FIRST := SAVEREC(N);
end;

procedure SAVEEXPR(N: integer);
var RESERVED: integer;
begin
  if N <> 0 then begin
    DEFINITION.c.data.count := N;
    DEFINITION.c.data.first := SAVEREC(N);
  end;
end;

% 06223. Bind a global definition to its namespace node.
function BINDDEF(INDEX: integer; var CODE: namecode): pprefix;
begin
  NAME := RESNAME(6, CODE); BINDDEF := ;
  with NAME@ do
    if defindex <> 0 then BADOBJ(3) else defindex := INDEX;
end;

% 06247. Read the object stream and gather its table records.
begin
  OPENIN(FILEIDX);
  FIRSTSEC := 0; FIRSTREF := ; FIRSTDEF := ; NSEC := ;
  NREF := ; NDEF := ; NPREF := ; NENTRY := ;
  GOODEND := true; LABELSON := 1 in CURRENTFILE.flags;
  READREC(HEADER, 1);
  if (HEADER[0].header.kind <> 0) or
     (HEADER[0].signature.magic <> 11259375) then BADOBJ(4);
  READBODY(HEADER);
  (records) repeat
    READREC(BUFFER.data, 1);
    case BUFFER.data[0].header.kind of
      0: BADOBJ(5);
      10: SKIPREC(BUFFER.data);
      2: begin
        READBODY(BUFFER.data); NEWSECT;
        SECTION.header := BUFFER.data[0];
        SECTION.links := BUFFER.data[3];
        SECTION.name := RESNAME(2, BUFFER.code);
        if BUFFER.data[0].numbers.entry <> 0 then begin
          if BUFFER.data[0].numbers.entry > NENTRY then BADOBJ(1);
          TABGET(ENTRYPOOL, BUFFER.data[0].numbers.entry-1, ENTRYNODE);
          SECTION.entry := ENTRYNODE;
        end else SECTION.entry := ptr(0);
        SECTION.fileindex := FILEIDX;
        CURSEC := g0051;
        repeat
          PREVSEC := CURSEC;
          TABREAD(SECTPOOL, CURSEC); PSEC := ;
          CURSEC := PSEC@.next;
        until (CURSEC = g0051) or (PSEC@.name = SECTION.name);
        TABREAD(SECTPOOL, CURSEC); QSEC := ;
        (q) while (QSEC@.name = SECTION.name) and (CURSEC <> g0051) do
          (r)
        begin
          PREVSEC := CURSEC; CURSEC := PSEC@.next; PSEC := QSEC;
          TABREAD(SECTPOOL, CURSEC); QSEC := ;
        end;
        SECTION.next := CURSEC; SECTION.previous := PREVSEC;
        PSEC@.next := NEWSEC; QSEC@.previous := NEWSEC;
        PUTSECT(SECTPOOL, NEWSEC, SECTION);
      end;
      1: begin
        READBODY(BUFFER.data);
        if NENTRY = 0 then INITVEC(1, 256, "T ЭMOД", ENTRYPOOL);
        ENTRYNODE := RESNAME(1, BUFFER.code);
        NENTRY := NENTRY+1;
        TABPUT(ENTRYPOOL, NENTRY-1, ENTRYNODE);
      end;
      3: begin
        READBODY(BUFFER.data);
        if NPREF = 0 then INITVEC(1, 512, "T ПPEФ", PREFPOOL);
        PFNODE := RESNAME(3, BUFFER.code);
        NPREF := NPREF+1; TABPUT(PREFPOOL, NPREF-1, PFNODE);
      end;
      4: begin
        NEWDEF;
        DEFINITION.c.entry := true; DEFINITION.c.resolved := true;
        DEFINITION.b.fileindex := FILEIDX;
        DEFINITION.a.tags := BUFFER.data[0].definition.tags;
        BODYLEN := BUFFER.data[0].numbers.count;
        PREFLEN := BUFFER.data[0].header.prefcount;
        DATALEN := BUFFER.data[0].header.datacount;
        if BUFFER.data[0].header.hasname then begin
          READPART(BUFFER.data, 1, 2);
          DEFINITION.a.name := BINDDEF(DEFIDX, BUFFER.code);
          BODYLEN := BODYLEN-2;
        end;
        READPART(TAIL, 0, 1);
        DEFINITION.c.scope := TAIL[0].scopeword.count;
        DEFINITION.c.data.value := TAIL[0].value.high;
        SAVEPREF(PREFLEN); SAVEDATA(DATALEN);
        SKIPDATA(BODYLEN-PREFLEN-DATALEN-2);
        PUTDEF(DEFPOOL, DEFIDX, DEFINITION);
      end;
      5: SKIPREC(BUFFER.data);
      6: begin
        NEWDEF; DEFINITION.b.fileindex := FILEIDX;
        BODYLEN := BUFFER.data[0].numbers.count;
        EXTRALEN := BUFFER.data[0].numbers.entry;
        DATALEN := BUFFER.data[0].header.datacount;
        if BUFFER.data[0].header.hasname then begin
          READPART(BUFFER.data, 1, 2);
          DEFINITION.a.name := BINDDEF(DEFIDX, BUFFER.code);
          BODYLEN := BODYLEN-2;
        end;
        if EXTRALEN <> 0 then SAVEEXPR(EXTRALEN)
        else begin
          DEFINITION.c.resolved := true; BODYLEN := BODYLEN-1;
          READPART(TAIL, 0, 1);
          DEFINITION.c.scope := TAIL[0].scopeword.count;
          DEFINITION.c.data.value := TAIL[0].value.high;
        end;
        SAVEDATA(DATALEN);
        SKIPDATA(BODYLEN-EXTRALEN-DATALEN-1);
        PUTDEF(DEFPOOL, DEFIDX, DEFINITION);
      end;
      7: SKIPREC(BUFFER.data);
      8: begin
        READPART(BUFFER.data, 1, 2); NEWREF;
        REFERENCE.name := RESNAME(8, BUFFER.code);
        DATALEN := BUFFER.data[0].numbers.count-3;
        if DATALEN <> 0 then begin
          REFERENCE.count := DATALEN;
          REFERENCE.first := SAVEREC(DATALEN);
        end;
        PUTREF(REFPOOL, REFIDX, REFERENCE);
      end;
      9: begin GOODEND := false; exit records end;
      255: exit records;
      others: BADOBJ(6)
    end;
  until false;
  CURRENTFILE.n1.firstsect := FIRSTSEC;
  CURRENTFILE.n1.nsects := NSEC;
  CURRENTFILE.n0.firstdef := FIRSTDEF; CURRENTFILE.n0.ndefs := NDEF;
  CURRENTFILE.n2.firstref := FIRSTREF; CURRENTFILE.n2.nrefs := NREF;
  if 0 in PRINTOPT then begin
    write(' ', CURRENTFILE.name@.text, ' [',
          CURRENTFILE.filedata.address:6 oct, '] ');
    PUTCODE(HEADER[2].firstcode.text);
    PUTCODE(HEADER[2].lastcode.text);
    PUTCODE(HEADER[3].firstcode.text);
    write(' .', HEADER[0].version.number:1);
    if GOODEND then write(' ') else write('*');
    PUTSIZE(NUMOBJS(g0567)); write(' ');
    PUTDATE(HEADER[5].time.seconds);
    write(' ',
          shift(integer(bitset(HEADER[4].hi)*[0..31]), 24):6 hex,
          " ЭBM-",
          HEADER[5].date.weekday:1, '  ');
    PUTCODE(HEADER[1].firstcode.text);
    PUTCODE(HEADER[1].lastcode.text);
    writeln(NSEC:6, NDEF:9, NREF:8, NENTRY:5, NPREF:5);
  end;
  if NPREF <> 0 then CLOSE(PREFPOOL);
  if NENTRY <> 0 then CLOSE(ENTRYPOOL);
  CLOSEIN(FILEIDX);
end;
% Reference resolution and section placement, from 07221.
function RESOLVE(FILEIDX: integer): boolean;
var SPARE5, COUNT, I, DEFNO, HEAD, LAST: integer;
    F: pfile;
    R, PREV: pref;
    SPARE14, LIMIT: integer;
begin
  OBJEDIT(FILEPOOL, FILEIDX); F := ;
  with F@ do begin FIRSTREF := n2.firstref; COUNT := n2.nrefs end;
  RESOLVE := true; HEAD := 0; LAST := ;
  (x);
  LIMIT := FIRSTREF+COUNT-1;
  (q) for I := FIRSTREF to LIMIT do (r) begin
    FILEEDIT(REFPOOL, I); R := ;
    with R@ do DEFNO := name@.defindex;
    if DEFNO = 0 then begin
      ALLFOUND := false; RESOLVE := ;
      if LAST = 0 then HEAD := I
      else begin
        FILEEDIT(REFPOOL, LAST); PREV := ; PREV@.link := I;
      end;
      LAST := I;
    end else begin R@.resolved := true; R@.link := DEFNO end;
  end;
  F@.unresolved.first := HEAD;
end;

% 07316. Print the unresolved-reference chain, wrapping at column 128.
procedure UNRESMSG(FILEIDX: integer);
var INDEX, COLUMN, WIDTH: integer;
    F: pfile;
    R: pref;
    FIRST: boolean;
begin
  TABREAD(FILEPOOL, FILEIDX); F := ;
  with F@ do begin
    INDEX := unresolved.first;
    write("MOДYЛЬ ", name@.text, ' : ');
  end;
  COLUMN := 18; FIRST := true;
  (q) while INDEX <> 0 do (r) begin
    TABREAD(REFPOOL, INDEX); R := ;
    with R@ do WIDTH := PATHLEN(R@.name)+2;
    if COLUMN+WIDTH > 128 then begin
      writeln; write(' ':20); COLUMN := 18; FIRST := true;
    end;
    if not FIRST then write(', ') else FIRST := false;
    PUTPATH(R@.name);
    COLUMN := COLUMN+WIDTH; INDEX := R@.link;
  end;
  writeln;
end;

% 07403. Round START upward to a multiple of 2**POWER.
function ALIGNUP(START, POWER: integer): integer;
var TOP, STEP: integer;
begin
  STEP := trunc(exp(POWER * 0.69314718056));
  TOP := START+STEP-1; ALIGNUP := TOP-TOP mod STEP;
end;

% 07516. Append compatible section records or overlap equal-sized ones.
procedure JOINSECT(REC: psect);
var STARTADDR: integer;

% 07444. Fatal section-joining diagnostics.
procedure BADSECT(ERROR: integer);

% 07420. Identify a section and its originating module.
procedure SECTID(REC: psect);
var RESERVED: integer;
    F: pfile;
begin
  with REC@ do begin
    PUTPATH(name); write(' (');
    TABREAD(FILEPOOL, fileindex); F := ;
    write(F@.name@.text, ')');
  end;
end;

begin
  writeln("* * *  OШИБKA ПPИ ", "COПPЯЖEHИИ CEKЦИЙ   * * *");
  case ERROR of
    0: begin
      write("HECOBMECTИMЫE ATPИБYTЫ CEKЦИЙ ");
      SECTID(REC); write(" И "); SECTID(ref(LASTSECT));
    end;
    1: begin
      write("HECOOTBETCTBИE ДЛИH CEKЦИЙ ");
      SECTID(REC); write(" И "); SECTID(ref(LASTSECT));
    end;
    2: begin
      write("ЗAПPEЩEHHЫЙ ATPИБYT CEKЦИИ "); SECTID(REC);
    end;
    3: begin
      write("HEДOПYCTИMЫЙ ATPИБYT CEKЦИИ "); SECTID(REC);
    end
  end;
  writeln; goto 9999;
end;

begin
  with REC@ do begin
    if length = 0 then exit;
    if name = LASTSECT.name then begin
      if (space <> LASTSECT.space) or
         (alignment <> LASTSECT.alignment) or
         (join <> LASTSECT.join) or
         (rights <> LASTSECT.rights) then BADSECT(0);
      case join of
        jmoverlap: begin
          if length <> LASTSECT.length then BADSECT(1);
          REC@.base := LASTSECT.base; offset := LASTSECT.offset;
        end;
        jmconcat: begin
          STARTADDR := ALIGNUP(NEXTADDR, alignment);
          NEXTADDR := length+STARTADDR; REC@.base := STARTADDR;
          offset := STARTADDR;
        end;
        jmforbid: BADSECT(2);
        others: BADSECT(3)
      end;
    end else begin
      STARTADDR := ALIGNUP(NEXTADDR, alignment);
      NEXTADDR := length+STARTADDR;
      REC@.base := STARTADDR; offset := STARTADDR;
      LASTSECT := REC@;
    end;
  end;
end;

% 07661. Qualified section/elementary-module name, padded to 17 columns.
procedure PUTSECTN(REC: psect);
var WIDTH: integer;
begin
  with REC@ do begin
    WIDTH := PATHLEN(REC@.name); PUTPATH(REC@.name);
    if entry <> ptr(0) then begin
      WIDTH := PATHLEN(entry)+WIDTH+1;
      write('.'); PUTPATH(entry);
    end;
    if WIDTH > 17 then begin writeln; write(' ':17) end
    else if WIDTH < 17 then write(' ':17-WIDTH);
  end;
end;

% 07722. List a placed section and its storage/protection attributes.
procedure LISTSECT(REC: psect);
var F: pfile;
begin
  with REC@ do begin
    if length = 0 then exit;
    PUTSECTN(REC); write(' ');
    TABREAD(FILEPOOL, fileindex); F := ;
    write(F@.name@.text, '  ', base:7 hex, '   ',
          length+base-1:7 hex, '   ', length:7 hex, ' ');
    case alignment of
      0: write("  CЛOBO");
      8: write("  AБЗAЦ");
      10: write("  ЛИCT ");
      others: write(alignment:5, '  ')
    end;
    case space of
      spkp: write(" KП,"); spdp: write(" ДП,"); sprp: write(" PП,")
    end;
    case join of
      jmconcat: write("ПOCЛ,"); jmoverlap: write('COBM,');
      jmforbid: write('    ,')
    end;
    if free then write("CBOБ,") else write(" ПOЗ,");
    if global then write("ГЛOБ,") else write(" ЛOK,");
    if 2 in rights then write("HЧT,") else write(" ЧT,");
    if 4 in rights then write("HЗП,") else write(" ЗП,");
    if not (0 in rights) then write(" BЫП.")
    else if 1 in rights then write("HBЫП.") else write("HЛИH.");
    writeln;
  end;
end;

% 10152. Introduce a global object name or a local object number.
procedure OBJWHERE(NAME: pprefix);
begin
  if NAME <> ptr(0) then begin
    write("ГЛOБAЛЬHЫЙ OБ'EKT "); PUTPATH(NAME);
  end else write("ЛOKAЛЬHЫЙ OБ'EKT N", g0107:1);
end;
% Expression evaluator and its nested helpers, 10166-14345.
function EVALUATE(INSECT: boolean): boolean;
label 100, 200;
type
  stackval = record case integer of
    0: (word: integer;
        upper: packed record high: uint16; low: uint32 end);
    1: (bits, upperbits: bitset);
    2: (halves: packed record high, low: uint24 end);
    3: (index: packed record high: uint32; low: uint16 end);
    4: (lowbytes: packed array [1..6] of char;
        highbytes: packed array [1..2] of char);
    5: (parts: packed record high: uint16; low: uint32 end)
  end;
  opcodeval = packed record case integer of
    0: (word: integer);
    1: (fields: packed record high: set of 0..39; final: 0..1;
          group: 0..7; low: uint4 end);
    2: (low7: packed record high: set of 0..40; value: 0..127 end)
  end;
  cmdword = packed record case integer of
    0: (word: integer); 1: (bits: bitset);
    2: (data: packed record value: uint32; low: uint16 end);
    3: (longinst: packed record reg: uint4; opcode: uint8;
          negative: boolean; address: 0..1777777B; low: uint16 end);
    4: (maininst: packed record reg: uint4; opcode, high: uint8;
          address: 0..4095; low: uint16 end);
    5: (instr: packed record code: 0..4095;
               low: 0..777777777777B end);
    6: (count: packed record high: uint32;
               low: uint16 end);
    7: (header: packed record high: uint16; kind, length: uint8;
                low: uint16 end)
  end;
  cmdpair = record left, right: cmdword end;
var STACK: array [1..12] of stackval;
    TOP, REFNO, DEFNO, SECTNO, CURSOR, COUNT, RESERVED,
    BITSTART, BITCOUNT: integer;
    LOOKOK: boolean;
    SPARE27: integer;
    SEC: psect;
    DEF: pdef;
    REFERENCE: pref;
    OPCODE: opcodeval;
    SPARE32, SAVETAG: integer;
    SAVEMODE: evalform;
    WORDHALF: integer;
    BYTEPAIR, WORDPAIR: pair;
    COMMAND: cmdpair;
    TEMPPAIR: pair;
    BYTES: array [1..128] of char;
    LOOP172, LOOP173, LOOP174, LOOP175, LOOP176: integer;

procedure PACKVAL(VALUE: integer; var WORD: stackval); fortran;
function UNPACKVL(var WORD: stackval): integer; fortran;
procedure B23312(var A, B, C: stackval); fortran;
procedure B23330(var A, B, C: stackval); fortran;
procedure B23336(var A, B, C: stackval); fortran;
procedure B23347(var A, B, C: stackval); fortran;
procedure B23361(var A, B, C: stackval); fortran;
procedure B24130(var A, B, C: stackval); fortran;
procedure B23414(var A, B, C: stackval); fortran;
procedure B24127(var A, B, C: stackval); fortran;
procedure B23525(var A: stackval; FIRST, COUNT: integer;
                 var RESULT: stackval); fortran;
procedure B23434(var A: stackval; N: integer;
                 var RESULT: stackval); fortran;
procedure B23375(var A, RESULT: stackval); fortran;
procedure B24133(var A, RESULT: stackval); fortran;
function B23423(var A: stackval; MASK: integer): integer; fortran;
procedure TABSAVE(POOL, INDEX: integer; var VALUE: pair); fortran;

% 10166. Diagnostic dump of the twelve two-word operand values.
procedure DUMPSTK;
var I: integer;
begin
  write('CTEK');
  (q) for I to TOP do (r)
    write(' ', I:1, ' = ', STACK[I].upper.high:4 hex,
          STACK[I].word:12 hex);
  writeln;
end;

% 10217. Fatal expression/relocation diagnostics.
procedure BADEXPR(ERROR: integer);
begin
  MODULEMSG(ref(CURRENTFILE));
  case ERROR of
    0: writeln("ПPEBЫШEHA ДЛИHA CEГMEHTA");
    1: writeln("ИCЧEPПAHЫ OПEPAЦИИ B BЫPAЖEHИИ");
    17: writeln(
      "AДPECHAЯ ЧATЬ KOMAHДЫ BHE ДOПYCTИMOГO ДИAПAЗOHA");
    2: writeln(
      "HEДOПYCTИMЫЙ AДPEC B KOMAHДE ", "OCHOBHOГO ФOPMATA");
    3: writeln(
      "HEДOПYCTИMЫЙ AДPEC B KOMAHДE ", "ДOПOЛHИTEЛЬHOГO ФOPMATA");
    4: writeln("HEДOПYCTИMЫЙ HOMEP CEKЦИИ");
    5: writeln("CTEK OПEPAHДOB ПYCT");
    6: writeln("B KOHЦE BЫPAЖEHИЯ CTEK HE ПYCT");
    7: writeln("ИCЧEPПAHЫ OПEPAHДЫ B OПEPATOPE");
    8: writeln("HEBEPHЫЙ KOП ПФ-KOMAHДЫ");
    9: writeln("HEPEAЛИЗOBAHHAЯ MИKPOOПEPAЦИЯ ", OPCODE.word:2 hex);
    10: writeln("HEДOПYCTИMAЯ MИKPOOПEPAЦИЯ ", OPCODE.word:2 hex);
    11: writeln(
      "HEBEPHOE ИCПOЛЬЗOBAHИE MИKPOOПEPAЦИИ ", OPCODE.word:2 hex);
    12: writeln("HEBEPHAЯ CCЫЛKA HA BHEШHИЙ OБ'EKT : ", REFNO:0,
                ' (MAX=', g0070:0, ')');
    13: writeln("HEBEPHЫЙ HOMEP OБ'EKTA : ", DEFNO:0,
                ' (MAX=', g0072:0, ')');
    15: writeln("HEДOПYCTИMЫE ГPAHИЦЫ ПOЛЯ : ", 64+BITSTART:1,
                '..', BITCOUNT+BITSTART+1:1);
    16: writeln("HEBEPHЫЙ HOMEP ATPИБYTA : ", g0077:0);
    others: writeln("OШCИC=", ERROR:1, '!!!')
  end;
  if INSECT then begin
    write("CEKЦИЯ "); PUTPATH(g0140);
    write(' : ', NEXTADDR:7 hex, ', '); RECORDMSG(10);
  end else OBJWHERE(g0140);
  writeln; goto 9999;
end;

% 10446. Store a packed output pair and advance its word address.
procedure FLUSHOUT;
begin
  if g0057 >= g0056 then BADEXPR(0);
  PUTPAIR(g0570, g0057, OUTPAIR);
  g0057 := g0057+1; NEXTADDR := NEXTADDR+1;
end;

% 10463. Pack successive 32-bit values into the output pair.
procedure PUTWORD(WORD: integer);
begin
  OUTPAIR.datawords[ord(HALFOUT)] := shift(WORD, -16);
  if HALFOUT then begin FLUSHOUT; HALFOUT := false end
  else begin
    OUTPAIR.packedout.tag := shift(SAVETAG, 43); HALFOUT := true;
  end;
end;

% 10504. Expand four bytes from each half of each two-word input record.
% Refill up to 128 bytes, or stop at the end of the expression stream.
% UNPCK stores six characters: the extra two overlap the next group.
% Its final two stores reach LOOP172/LOOP173, just as in the image.
function GETBYTE: integer;
begin
  if CURSOR > 128 then begin
    if g0100 >= g0101 then BADEXPR(1);
    CURSOR := 1;
    repeat
      if INSECT then GETPAIR(g0567, g0100, BYTEPAIR)
      else TABPAIR(g0566, g0100, BYTEPAIR);
      g0100 := g0100+1;
      unpck(BYTES[CURSOR], BYTEPAIR.first6);
      CURSOR := CURSOR+4;
      unpck(BYTES[CURSOR], BYTEPAIR.last6);
      CURSOR := CURSOR+4;
      (x);
    until (CURSOR > 128) or (g0100 = g0101);
    CURSOR := 1;
  end;
  GETBYTE := ord(BYTES[CURSOR]); CURSOR := CURSOR+1;
end;

% 10553. Read alternate 32-bit values in the high part of two words.
function GETWORD: integer;
begin
  if WORDHALF = 0C then begin
    if g0102 >= g0103 then BADEXPR(7);
    GETPAIR(g0567, g0102, WORDPAIR); g0102 := g0102+1;
    GETWORD := WORDPAIR.data0.value;
    WORDHALF := 1C;
  end else begin
    GETWORD := WORDPAIR.data1.value;
    WORDHALF := 0C;
  end;
end;

% 10602. Push up to eight big-endian bytes into a 64-bit value.
procedure PUSHLIT(N: integer);
var I: integer;
begin
  TOP := TOP+1; STACK[TOP] := [0C, 0C];
  with STACK[TOP] do begin
    (q) for I := 9-N to 2 do (r) begin
      highbytes[I] := chr(GETBYTE); N := N-1;
    end;
    (q) for I := 7-N to 6 do (r)
      bits := bitset(shift(word, -8))+bitset(chr(GETBYTE));
  end;
end;

% 10647. Convert the current value to an integer, add the section delta,
% and convert it back with the original external value service.
procedure RELOCATE(INDEX: integer);
var SEC: psect;
begin
  INDEX := INDEX+g0065-1;
  if INDEX >= g0067 then BADEXPR(4);
  TABREAD(SECTPOOL, INDEX); SEC := ;
  with SEC@ do
    PACKVAL(UNPACKVL(STACK[TOP])+(base-high2), STACK[TOP]);
end;

% 10703. Push a resolved definition as a signed 27-bit value.
function PUSHDEF(INDEX: integer): boolean;
begin
  INDEX := INDEX+g0071-1;
  if INDEX >= g0072 then BADEXPR(13);
  FILEEDIT(DEFPOOL, INDEX); DEF := ; TOP := TOP+1;
  with DEF@ do
    if c.ready then begin
      PUSHDEF := true;
      STACK[TOP].word := c.data.value;
      if STACK[TOP].word >= 400000000B then
        STACK[TOP].word := STACK[TOP].word-1000000000B;
      PACKVAL(STACK[TOP].word, STACK[TOP]); DEF@.c.used := true;
    end else PUSHDEF := false;
end;

% 10767. Push zero for reference zero, or use its bound definition.
% As in the image, an early exit does not assign the Boolean result.
function PUSHREF(INDEX: integer): boolean;
begin
  TOP := TOP+1; STACK[TOP] := [0C, 0C];
  if INDEX = 0 then exit;
  INDEX := INDEX+FIRSTREF-1;
  if INDEX >= g0070 then BADEXPR(12);
  FILEEDIT(REFPOOL, INDEX); REFERENCE := ;
  with REFERENCE@ do begin
    used := true;
    if not resolved then exit;
    FILEEDIT(DEFPOOL, link); DEF := ;
  end;
  with DEF@ do
    if c.ready then begin
      PUSHREF := true;
      STACK[TOP].word := c.data.value;
      if STACK[TOP].word >= 400000000B then
        STACK[TOP].word := STACK[TOP].word-1000000000B;
      PACKVAL(STACK[TOP].word, STACK[TOP]); DEF@.c.used := true;
    end else PUSHREF := false;
end;

% 11077. Push a 64-bit attribute from saved definition pair records.
function DEFATTR(INDEX, OFFSET: integer): boolean;
var FIRST: integer;
begin
  INDEX := INDEX+g0071-1;
  if INDEX >= g0072 then BADEXPR(13);
  FILEEDIT(DEFPOOL, INDEX); DEF := ;
  with DEF@ do
    if c.ready then begin
      DEFATTR := true;
      if OFFSET >= b.count then BADEXPR(16);
      FIRST := b.first+OFFSET; c.used := true;
    end else begin DEFATTR := false; exit end;
  TABPAIR(g0566, FIRST, TEMPPAIR); TOP := TOP+1;
  STACK[TOP].bits := bitset(chr(TEMPPAIR.data1.value));
  STACK[TOP].upperbits := bitset(shift(TEMPPAIR.data0.value, -32));
  STACK[TOP].bits :=
    STACK[TOP].bits+bitset(shift(shift(TEMPPAIR.data0.value, 16), -32));
end;

% 11177. Corresponding attribute lookup through the reference table.
% Zero/unbound references retain the original unassigned-result exits.
function REFATTR(INDEX, OFFSET: integer): boolean;
var FIRST: integer;
begin
  TOP := TOP+1; STACK[TOP] := [0C, 0C];
  if INDEX = 0 then exit;
  INDEX := INDEX+FIRSTREF-1;
  if INDEX >= g0070 then BADEXPR(12);
  FILEEDIT(REFPOOL, INDEX); REFERENCE := ;
  with REFERENCE@ do begin
    used := true;
    if not resolved then exit;
    FILEEDIT(DEFPOOL, link); DEF := ;
  end;
  with DEF@ do
    if c.ready then begin
      REFATTR := true;
      if OFFSET >= b.count then BADEXPR(16);
      FIRST := b.first+OFFSET; c.used := true;
    end else begin REFATTR := false; exit end;
  TABPAIR(g0566, FIRST, TEMPPAIR);
  STACK[TOP].bits := bitset(chr(TEMPPAIR.data1.value));
  STACK[TOP].upperbits := bitset(shift(TEMPPAIR.data0.value, -32));
  STACK[TOP].bits :=
    STACK[TOP].bits+bitset(shift(shift(TEMPPAIR.data0.value, 16), -32));
end;

% 11323. Consume exactly N stack values and emit the requested form.
procedure EMITVAL(N: integer);
var VALUE, LOWPART: integer;
begin
  if TOP-N < 0 then BADEXPR(5)
  else if TOP-N > 0 then BADEXPR(6);
  (q) for TOP := TOP downto 1 do (r)
    case SAVEMODE of
      fmshort, fmprefix: begin
        VALUE := UNPACKVL(STACK[TOP]);
        if (VALUE < -1000000000B) or (VALUE >= 1000000000B) then
          BADEXPR(17);
        VALUE := (VALUE+1000000000B) mod 1000000000B;
        if SAVEMODE = fmprefix then begin
          LOWPART := VALUE div 4096; VALUE := VALUE mod 4096;
        end;
        if COMMAND.left.longinst.opcode = 63 then begin
          if VALUE >= 4096 then BADEXPR(3);
        end else begin
          if (VALUE >= 2000000B) and (VALUE < 776000000B) then
            BADEXPR(2);
          VALUE := VALUE mod 4000000B;
        end;
        if SAVEMODE = fmprefix then begin
          COMMAND.right.bits := COMMAND.right.bits+
                                bitset(shift(LOWPART, -16));
          PUTWORD(COMMAND.right.data.value);
        end;
        COMMAND.left.bits := COMMAND.left.bits+
                             bitset(shift(VALUE, -16));
        PUTWORD(COMMAND.left.data.value);
      end;
      fmhalf: PUTWORD(STACK[TOP].word);
      fmword:
        if INSECT then begin
          PUTWORD(integer(bitset(shift(STACK[TOP].upper.high, -16))+
                          bitset(shift(STACK[TOP].parts.high, 0))));
          PUTWORD(STACK[TOP].parts.low);
        end else if TOP = N then g0110 := UNPACKVL(STACK[TOP])
        else begin
          TEMPPAIR.hi := integer(
            bitset(shift(STACK[TOP].upper.high, -32))+
            bitset(shift(STACK[TOP].parts.high, -16)));
          TEMPPAIR.lo := shift(STACK[TOP].word, -16);
          TABSAVE(g0566, g0102, TEMPPAIR); g0102 := g0102+1;
        end;
      others: ;
    end;
end;

% 11522. Emit a saved operator block, binding its initial reference.
procedure EMITOPER;
var KIND: integer;
    GOOD: boolean;
    LIMIT: integer;
begin
  COMMAND.left.word := GETWORD;
  COUNT := COMMAND.left.count.low;
  KIND := COMMAND.left.header.kind;
  RESERVED := COMMAND.left.header.length;
  COMMAND.left.word := 0C; SAVEMODE := fmshort;
  case KIND of
    1, 3: begin
      GOOD := PUSHDEF(COUNT); COMMAND.left.instr.code := 3353;
      EMITVAL(1);
    end;
    2, 4: begin
      GOOD := PUSHREF(COUNT); COMMAND.left.instr.code := 3353;
      EMITVAL(1);
    end;
    5: begin COMMAND.left.instr.code := 3352; EMITVAL(1) end;
    others: ;
  end;
  LIMIT := RESERVED-1;
  (*q*) for g0077 to LIMIT do (r) PUTWORD(GETWORD);
  (x);
end;

% 11616. Load an instruction address or raw operand into slot one.
procedure FIRSTVAL;
begin
  case SAVEMODE of
    fmshort: begin
      COMMAND.left.word := shift(GETWORD, -16);
      if COMMAND.left.longinst.opcode = 63 then begin
        STACK[1].word := COMMAND.left.maininst.address;
        COMMAND.left.bits := COMMAND.left.bits*
                            bitset(7777776000000000C);
      end else begin
        STACK[1].word := COMMAND.left.longinst.address;
        if COMMAND.left.longinst.negative then
          STACK[1].word := STACK[1].word-2000000B;
        COMMAND.left.bits := COMMAND.left.bits*
                            bitset(7777000000000000C);
      end;
      PACKVAL(STACK[1].word, STACK[1]);
    end;
    fmprefix: begin
      COMMAND.right.word := shift(GETWORD, -16);
      COMMAND.left.word := shift(GETWORD, -16);
      if (COMMAND.right.longinst.opcode = 58) or
         (COMMAND.right.longinst.opcode = 57) then begin
        COUNT := COMMAND.right.longinst.address*4096;
        COMMAND.right.bits := COMMAND.right.bits*
                             bitset(7777000000000000C);
      end else BADEXPR(8);
      if COMMAND.left.longinst.opcode = 63 then begin
        STACK[1].word := COMMAND.left.maininst.address+COUNT;
        COMMAND.left.bits := COMMAND.left.bits*
                            bitset(7777776000000000C);
      end else begin
        STACK[1].word := COMMAND.left.longinst.address+COUNT;
        if COMMAND.left.longinst.negative then
          STACK[1].word := STACK[1].word-2000000B;
        COMMAND.left.bits := COMMAND.left.bits*
                            bitset(7777000000000000C);
      end;
      if STACK[1].word >= 400000000B then
        STACK[1].word := STACK[1].word-1000000000B;
      PACKVAL(STACK[1].word, STACK[1]);
    end;
    fmhalf: STACK[1].bits := bitset(chr(GETWORD));
    fmword: begin
      SPARE32 := GETWORD;
      STACK[1].bits := bitset(chr(GETWORD));
      STACK[1].upperbits := bitset(shift(shift(SPARE32, 16), -32));
      STACK[1].bits := STACK[1].bits+bitset(shift(SPARE32, -32));
    end;
    others: ;
  end;
  TOP := 1;
end;

% 11764. Binary micro-operations. B-names are inherited from LINK1;
% inventory.json records their actual LINK entry addresses.
procedure BINARYOP(OP: integer);
begin
  if TOP < 2 then BADEXPR(5);
  TOP := TOP-1;
  case OP of
    0: B23312(STACK[TOP], STACK[TOP+1], STACK[TOP]);
    1: B23330(STACK[TOP], STACK[TOP+1], STACK[TOP]);
    2: B23336(STACK[TOP], STACK[TOP+1], STACK[TOP]);
    3: B23347(STACK[TOP], STACK[TOP+1], STACK[TOP]);
    4: B23361(STACK[TOP], STACK[TOP+1], STACK[TOP]);
    5: B24130(STACK[TOP], STACK[TOP+1], STACK[TOP]);
    6: B23414(STACK[TOP], STACK[TOP+1], STACK[TOP]);
    7: B24127(STACK[TOP], STACK[TOP+1], STACK[TOP]);
    8: BADEXPR(9);
    others: BADEXPR(10)
  end;
end;

% 12176. Field operations, shifts and remaining unary micro-operations.
procedure FIELDOP(OP: integer);
begin
  case OP of
    0: begin
      if TOP < 3 then BADEXPR(5);
      B23525(STACK[TOP], STACK[TOP-1].word, STACK[TOP-2].word,
             STACK[TOP-2]);
      TOP := TOP-2;
    end;
    1: begin
      BITSTART := GETBYTE; BITCOUNT := GETBYTE;
      B23525(STACK[TOP], BITSTART, BITCOUNT, STACK[TOP]);
    end;
    2: begin
      if TOP < 2 then BADEXPR(5);
      BITSTART := GETBYTE; BITCOUNT := GETBYTE;
      B23525(STACK[TOP], BITSTART, BITCOUNT, STACK[TOP]);
      B23414(STACK[TOP], STACK[TOP-1], STACK[TOP-1]); TOP := TOP-1;
    end;
    3: begin
      BITSTART := GETBYTE-64; BITCOUNT := GETBYTE-BITSTART-1;
      if BITSTART > 0 then BADEXPR(15)
      else if BITSTART <> 0 then
        B23434(STACK[TOP], BITSTART, STACK[TOP]);
      if BITCOUNT <> 0 then B23434(STACK[TOP], BITCOUNT, STACK[TOP]);
    end;
    4: B23375(STACK[TOP], STACK[TOP]);
    5: B24133(STACK[TOP], STACK[TOP]);
    6: B23434(STACK[TOP], 12, STACK[TOP]);
    7: STACK[TOP].word := B23423(STACK[TOP], 4095);
    others: BADEXPR(10)
  end;
end;

% 12445. Process a section stream, or one definition expression.
begin
  CURSOR := 129;
  if INSECT then begin
    g0057 := NEXTADDR-g0063+g0055; WORDHALF := 0C;
    if HALFOUT then begin
      GETPAIR(g0570, g0057, OUTPAIR); OPCODE.word := GETWORD;
    end;
  end else g0111 := fmword;
  EVALUATE := true;
  repeat
    repeat OPCODE.word := GETBYTE until OPCODE.word <> 0;
    (x);
    SAVETAG := g0112; SAVEMODE := evalform(g0111); TOP := 0;
    if (OPCODE.word >= 130) and (OPCODE.word <= 143) then begin
      if ((OPCODE.fields.low in [7..9, 11..13]) and HALFOUT) or
         not INSECT then BADEXPR(11);
      case OPCODE.fields.low of
        2: begin
          OPCODE.word := GETBYTE;
          g0112 := integer(bitset(shift(OPCODE.word, -43))*[0..4]);
        end;
        3: EMITOPER;
        4: g0111 := fmshort;
        5: g0111 := fmprefix;
        6: g0111 := fmhalf;
        7: g0111 := fmword;
        8: begin
          if GETBYTE <> 0 then BADEXPR(9);
          GETPAIR(g0570, g0057-1, OUTPAIR);
          LOOP172 := GETBYTE;
          (q) for g0077 := 0 to LOOP172 do (r) FLUSHOUT;
        end;
        9: begin
          COUNT := GETBYTE*256; COUNT := (GETBYTE)+COUNT;
          if COUNT <> 0 then BADEXPR(9);
          GETPAIR(g0570, g0057-1, OUTPAIR);
          COUNT := GETBYTE*256; LOOP173 := (GETBYTE)+COUNT;
          (*q*) for g0077 := 0 to LOOP173 do (r) FLUSHOUT;
          (x);
        end;
        10: begin
          LOOP174 := GETBYTE;
          (q) for g0077 := 0 to LOOP174 do (r) PUTWORD(GETWORD);
        end;
        11: begin
          OUTPAIR.hi := 0C; OUTPAIR.lo := ;
          OUTPAIR.packedout.tag := shift(SAVETAG, 43);
          LOOP175 := GETBYTE;
          (q) for g0077 := 0 to LOOP175 do (r) FLUSHOUT;
        end;
        12: begin
          OUTPAIR.hi := 0C; OUTPAIR.lo := ;
          OUTPAIR.packedout.tag := shift(SAVETAG, 43);
          COUNT := GETBYTE*256; LOOP176 := (GETBYTE)+COUNT;
          (*q*) for g0077 := 0 to LOOP176 do (r) FLUSHOUT;
          (x);
        end;
        13: begin
          COMMAND.left.data.value := GETWORD;
          LOOKOK := PUSHREF(COMMAND.left.longinst.address);
          OUTPAIR.hi := integer(
            bitset(shift(COMMAND.left.instr.code, -36))+
            bitset(shift(STACK[1].word, -24)));
          OUTPAIR.packedout.tag := shift(SAVETAG, 43);
          g0077 := GETWORD; OUTPAIR.lo := 0C; FLUSHOUT;
        end;
        14: BADEXPR(10);
        15: exit
      end;
      goto 100;
    end;
    if (OPCODE.low7.value >= 106) and
       (OPCODE.low7.value <= 108) then begin
      if not INSECT then BADEXPR(11);
      200: case OPCODE.fields.low of
        10: begin
          if HALFOUT then BADEXPR(11);
          SAVETAG := integer(bitset(SAVETAG)-[1]);
        end;
        11: begin
          if HALFOUT then BADEXPR(11);
          SPARE32 := GETBYTE;
          SAVETAG := integer(bitset(shift(SPARE32, -43))*[0..4]);
        end;
        12: SAVEMODE := fmprefix
      end;
      if OPCODE.fields.final = 1 then begin
        case SAVEMODE of
          fmshort, fmhalf: PUTWORD(GETWORD);
          fmprefix, fmword: begin
            PUTWORD(GETWORD); PUTWORD(GETWORD)
          end;
          others: ;
        end;
        goto 100;
      end;
      OPCODE.word := GETBYTE;
      if (OPCODE.low7.value = 106) or (OPCODE.low7.value = 107) then
        goto 200;
    end;
    if INSECT then FIRSTVAL;
    (expr) repeat
      case OPCODE.fields.group of
        0:
          if OPCODE.fields.final = 0 then
            case OPCODE.fields.low of
              0: ;
              1: PUSHLIT(1);
              2: PUSHLIT(2);
              3: PUSHLIT(3);
              4: PUSHLIT(4);
              5: PUSHLIT(5);
              6: PUSHLIT(6);
              7: PUSHLIT(7);
              8: PUSHLIT(8);
              9: begin
                TOP := TOP+1; STACK[TOP] := STACK[TOP-1];
              end;
              10: begin
                if TOP < 2 then BADEXPR(5);
                STACK[11] := STACK[TOP-1];
                STACK[TOP-1] := STACK[TOP];
                STACK[TOP] := STACK[11];
              end;
              11: begin
                if TOP < 3 then BADEXPR(5);
                STACK[12] := STACK[TOP-2];
                STACK[TOP-2] := STACK[TOP-1];
                STACK[TOP-1] := STACK[12];
              end;
              12: begin
                if TOP < 3 then BADEXPR(5);
                STACK[12] := STACK[TOP-2];
                STACK[11] := STACK[TOP-1];
                STACK[TOP-2] := STACK[TOP];
                STACK[TOP-1] := STACK[12];
                STACK[TOP] := STACK[11];
              end;
              13: begin
                if TOP < 3 then BADEXPR(5);
                STACK[12] := STACK[TOP-2];
                STACK[11] := STACK[TOP-1];
                STACK[TOP-1] := STACK[TOP];
                STACK[TOP-2] := STACK[11];
                STACK[TOP] := STACK[12];
              end;
              14: begin
                if TOP < 3 then BADEXPR(5);
                STACK[12] := STACK[TOP-2];
                STACK[TOP-2] := STACK[TOP];
                STACK[TOP] := STACK[12];
              end;
              15: BADEXPR(10)
            end
          else begin
            case OPCODE.fields.low of
              0: EMITVAL(1);
              1: begin SPARE32 := GETBYTE; EMITVAL(SPARE32) end;
              others: BADEXPR(11)
            end;
            exit expr;
          end;
        1: BINARYOP(OPCODE.fields.low);
        2: FIELDOP(OPCODE.fields.low);
        3:
          case OPCODE.fields.low of
            0: if not PUSHDEF(GETBYTE) then begin
                 EVALUATE := false; exit
               end;
            1: begin
              COUNT := GETBYTE*256;
              if not PUSHDEF((GETBYTE)+COUNT) then begin
                EVALUATE := false; exit
              end;
            end;
            2: begin
              if TOP < 1 then BADEXPR(5); TOP := TOP-1;
              if not PUSHDEF(STACK[TOP+1].index.low) then begin
                EVALUATE := false; exit
              end;
            end;
            3: BADEXPR(10);
            4: if not PUSHREF(GETBYTE) then begin
                 EVALUATE := false; exit
               end;
            5: begin
              COUNT := GETBYTE*256;
              if not PUSHREF((GETBYTE)+COUNT) then begin
                EVALUATE := false; exit
              end;
            end;
            6: begin
              if TOP < 1 then BADEXPR(5); TOP := TOP-1;
              if not PUSHREF(STACK[TOP+1].index.low) then begin
                EVALUATE := false; exit
              end;
            end;
            7: BADEXPR(10);
            8: BADEXPR(9);
            9: BADEXPR(10);
            10: BADEXPR(9);
            11, 12, 13, 14, 15: BADEXPR(10)
          end;
        4:
          case OPCODE.fields.low of
            0: begin
              COUNT := GETBYTE; DEFNO := GETBYTE;
              if not DEFATTR(DEFNO, COUNT) then begin
                EVALUATE := false; exit
              end;
            end;
            1: begin
              COUNT := GETBYTE; DEFNO := GETBYTE*256;
              if not DEFATTR((GETBYTE)+DEFNO, COUNT) then begin
                EVALUATE := false; exit
              end;
            end;
            2: begin
              if TOP < 1 then BADEXPR(5); TOP := TOP-1;
              if not DEFATTR(STACK[TOP+1].index.low, GETBYTE) then
              begin EVALUATE := false; exit end;
            end;
            3: BADEXPR(10);
            4: begin
              COUNT := GETBYTE;
              if not REFATTR(GETBYTE, COUNT) then begin
                EVALUATE := false; exit
              end;
            end;
            5: begin
              COUNT := GETBYTE; DEFNO := GETBYTE*256;
              if not REFATTR((GETBYTE)+DEFNO, COUNT) then begin
                EVALUATE := false; exit
              end;
            end;
            6: begin
              if TOP < 1 then BADEXPR(5); TOP := TOP-1;
              if not REFATTR(STACK[TOP+1].index.low, GETBYTE) then
              begin EVALUATE := false; exit end;
            end;
            7: BADEXPR(10);
            8: begin
              if TOP < 1 then BADEXPR(5); TOP := TOP-1;
              if not DEFATTR(GETBYTE, STACK[TOP+1].index.low) then
              begin EVALUATE := false; exit end;
            end;
            9: begin
              if TOP < 1 then BADEXPR(5); DEFNO := GETBYTE*256;
              TOP := TOP-1;
              if not DEFATTR((GETBYTE)+DEFNO,
                            STACK[TOP+1].index.low) then
              begin EVALUATE := false; exit end;
            end;
            10: begin
              if TOP < 2 then BADEXPR(5); TOP := TOP-2;
              if not DEFATTR(STACK[TOP+2].index.low,
                            STACK[TOP+1].index.low) then
              begin EVALUATE := false; exit end;
            end;
            11: BADEXPR(10);
            12: begin
              if TOP < 1 then BADEXPR(5); TOP := TOP-1;
              if not REFATTR(GETBYTE, STACK[TOP+1].index.low) then
              begin EVALUATE := false; exit end;
            end;
            13: begin
              if TOP < 1 then BADEXPR(5); DEFNO := GETBYTE*256;
              TOP := TOP-1;
              if not REFATTR((GETBYTE)+DEFNO,
                            STACK[TOP+1].index.low) then
              begin EVALUATE := false; exit end;
            end;
            14: begin
              if TOP < 2 then BADEXPR(5); TOP := TOP-2;
              if not REFATTR(STACK[TOP+2].index.low,
                            STACK[TOP+1].index.low) then
              begin EVALUATE := false; exit end;
            end;
            15: BADEXPR(10)
          end;
        5: BADEXPR(10);
        6:
          case OPCODE.fields.low of
            0: begin
              if TOP < 1 then BADEXPR(5);
              SECTNO := STACK[TOP].index.low+g0065-1;
              if SECTNO >= g0067 then BADEXPR(4);
              TABREAD(SECTPOOL, SECTNO); SEC := ;
              STACK[TOP].word := SEC@.base;
              if STACK[TOP].word >= 400000000B then
                STACK[TOP].word := STACK[TOP].word-1000000000B;
              PACKVAL(STACK[TOP].word, STACK[TOP]);
            end;
            1: RELOCATE(1);
            2: RELOCATE(2);
            3: RELOCATE(3);
            4: RELOCATE(4);
            5: RELOCATE(5);
            6: RELOCATE(6);
            7: RELOCATE(7);
            8: begin SECTNO := GETBYTE; RELOCATE(SECTNO) end;
            9: begin
              SECTNO := GETBYTE;
              SECTNO := SECTNO*8+(GETBYTE); RELOCATE(SECTNO);
              (q);
            end;
            10, 11, 12: BADEXPR(11);
            13, 14, 15: BADEXPR(10)
          end;
        7: BADEXPR(10)
      end;
      if OPCODE.fields.final = 1 then begin EMITVAL(1); exit expr end;
      OPCODE.word := GETBYTE;
    until false;
    if not INSECT then exit;
    100: ;
  until false;
end;
% 14346-14112. Evaluate the definitions gathered from one input module.
% The return state records completed and pending work in this pass.
function EVALDEFS(FILEIDX: integer): evalstate;
var NDEFS, SECNO, NSECTS: integer;
    DEFINITION: pdef;
    SECTION: psect;
    STATE: evalstate;

% 14346. Fatal definition-value diagnostics.
procedure BADVALUE(ERROR: integer);
begin
  MODULEMSG(ref(CURRENTFILE)); OBJWHERE(g0140);
  case ERROR of
    0: writeln(" - HEBEPHЫЙ HOMEP CEKЦИИ : ", SECNO:1);
    1: writeln(" - AДPEC BHE ДOПYCTИMOГO ДИAПAЗOHA");
    others: ;
  end;
  goto 9999;
end;

begin
  TABFILE(FILEPOOL, FILEIDX, CURRENTFILE);
  with CURRENTFILE do begin
    g0071 := n0.firstdef; NDEFS := n0.ndefs;
    g0072 := g0071+NDEFS;
    FIRSTREF := n2.firstref; g0070 := n2.nrefs+FIRSTREF;
    g0065 := n1.firstsect; NSECTS := n1.nsects;
    g0067 := g0065+NSECTS;
  end;
  MODULEERR := false; STATE := evnone;
  (q) for g0107 to NDEFS do (r) begin
    FILEEDIT(DEFPOOL, g0071+g0107-1); DEFINITION := ;
    with DEFINITION@ do
      if not c.ready then begin
        g0140 := a.name;
        if c.resolved then begin
          SECNO := c.scope;
          if SECNO <> 0 then begin
            if SECNO > NSECTS then BADVALUE(0);
            SECNO := g0065+SECNO-1; c.scope := ;
            TABREAD(SECTPOOL, SECNO); SECTION := ;
            with SECTION@ do
              DEFINITION@.c.data.value :=
                DEFINITION@.c.data.value+(base-high2);
          end;
          DEFINITION@.c.ready := true;
          case STATE of
            evnone: STATE := evdone;
            evwait: STATE := evmixed;
          end;
        end else begin
          g0100 := DEFINITION@.c.data.first;
          g0101 := DEFINITION@.c.data.count+g0100;
          g0102 := NUMOBJS(g0566)+1; g0103 := ;
          if not EVALUATE(false) then
            case STATE of
              evnone: STATE := evwait;
              evdone: STATE := evmixed;
              others: ;
            end
          else begin
            case STATE of
              evnone: STATE := evdone;
              evwait: STATE := evmixed;
            end;
            if (g0110 < -1000000000B) or (g0110 >= 1000000000B) then
              BADVALUE(1);
            DEFINITION@.c.data.value := g0110;
            DEFINITION@.c.resolved := true;
            DEFINITION@.c.ready := true;
            if g0103 < g0102 then begin
              DEFINITION@.b.first := g0103;
% Retain the original signed difference in the five-bit field.
              DEFINITION@.b.count := g0103-g0102;
            end;
          end;
        end;
      end;
  end;
  EVALDEFS := STATE;
end;
% 14625-14332. Evaluate section records in one input module.
procedure WRITESEG(FILEIDX: integer);
var BUFFER: pairs;
    SECNO, SPARE19, SPARE20: integer;
    SECTION: psect;
    GOOD: boolean;

% 14625. Fatal section-output diagnostics.
procedure BADOUT(ERROR: integer);
begin
  MODULEMSG(ref(CURRENTFILE)); RECORDMSG(BUFFER[0].header.kind);
  case ERROR of
    0: writeln(" : HEBEPHЫЙ HOMEP CEKЦИИ");
    1: writeln(" : HEДOПYCTИMЫЙ TИП ЗAПИCИ");
    others: writeln("OШCИC=", ERROR:1, '!!!')
  end;
  goto 9999;
end;

begin
  OPENIN(FILEIDX);
  with CURRENTFILE do begin
    g0065 := n1.firstsect; g0067 := n1.nsects+g0065;
    FIRSTREF := n2.firstref; g0070 := n2.nrefs+FIRSTREF;
    g0071 := n0.firstdef; g0072 := n0.ndefs+g0071;
  end;
  (records) repeat
    READREC(BUFFER, 1);
    case BUFFER[0].header.kind of
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9: SKIPREC(BUFFER);
      10: begin
% The section index is the following 16-bit field in the header word.
        SECNO := BUFFER[0].scopeword.count+g0065-1;
        if SECNO >= g0067 then BADOUT(0);
        OBJEDIT(SECTPOOL, SECNO); SECTION := ;
        g0100 := BYTEPOS+1;
        g0102 := BUFFER[0].numbers.entry+BYTEPOS+1; g0101 := ;
        g0103 := BUFFER[0].numbers.count+BYTEPOS;
        with SECTION@ do begin
          g0111 := state.mode;
          g0112 := integer(bitset(shift(raw0, -19))*[0..4]);
          HALFOUT := state.half; NEXTADDR := offset; g0140 := name;
        end;
        GOOD := EVALUATE(true);
        with SECTION@ do begin
          state.mode := g0111; rights := bitset(g0112);
          state.half := HALFOUT; offset := NEXTADDR;
        end;
        if HALFOUT then PUTPAIR(g0570, g0057, OUTPAIR);
        SETPOS(g0567, g0103);
      end;
      255: exit records;
      others: BADOUT(1)
    end;
  until false;
  CLOSEIN(FILEIDX);
end;
% 15045-15555. Emit an object-format file describing the linked names.
procedure LABELS;
type
  namecode = packed record
    first6, second6, third6: alfa;
    high: uint15; indexed: boolean; index, low: uint16
  end;
  LABELREC = record case integer of
       0: (data: pairs);
       1: (head: pair; code: namecode)
     end;
var HEADER, PREFBUF, DEFBUF: LABELREC;
    DEFINITION: pdef;
    MODNAME: namekey;
    TEMPPAIR: pair;
    COUNT, I: integer;

procedure KEYPAIR(var KEY: namekey; var RESULT: pair); fortran;
procedure KEYCODE(var KEY: namekey; var RESULT: namecode); fortran;
procedure GETTEMP(POOL: integer; var RESULT: pair); fortran;

% 15045. Traverse namespace children and their search trees.
procedure PUTLABEL(NODE: pprefix);
begin
  if NODE = ptr(0) then exit;
  with NODE@ do
    if (kind = 6) and not hidden then begin
      KEYCODE(name@.text, DEFBUF.code);
      DEFBUF.code.index := NODE@.next@.defindex;
      DEFBUF.code.indexed := NODE@.next@.kind = 6;
      if NODE@.defindex <> 0 then begin
        TABREAD(DEFPOOL, NODE@.defindex); DEFINITION := ;
        with DEFINITION@ do begin
          DEFBUF.data[3].value.high := c.data.value;
          COUNT := b.count; DEFBUF.data[0].header.datacount := ;
          if COUNT <> 0 then begin
            DEFBUF.data[0].count := COUNT+4; SETPOS(g0566, b.first);
          end else DEFBUF.data[0].count := 4;
        end;
        WRITREC(DEFBUF.data, 4);
        (q) for I to COUNT do (r) begin
          GETTEMP(g0566, TEMPPAIR); WRITPAIR(g0567, TEMPPAIR);
        end;
      end else begin
        DEFBUF.data[0].count := 4; DEFBUF.data[3].value.high := 0;
        DEFBUF.data[0].header.datacount := 0;
        WRITREC(DEFBUF.data, 4);
      end;
      NODE@.defindex := g0074; g0074 := g0074+1;
    end else if NODE@.children <> ptr(0) then begin
      KEYCODE(NODE@.name@.text, PREFBUF.code);
      if NODE@.next <> ROOTPREF then begin
        PREFBUF.code.index := NODE@.next@.defindex;
        PREFBUF.code.indexed := true;
      end;
      WRITREC(PREFBUF.data, 3);
      NODE@.defindex := g0075; g0075 := g0075+1;
    end;
  PUTLABEL(NODE@.children); PUTLABEL(NODE@.left); PUTLABEL(NODE@.right);
end;

begin
  ATTACH(2, LABELFILE.attr.disk.address, LABELFILE.attr.disk.length,
         LABELFILE.name@.first6, g0567);
  HEADER := [0C, 0C, 0C, 0C, 0C, 0C, 0C, 0C, 0C, 0C, 0C, 0C];
  HEADER.data[0].signature.kind := 0;
  HEADER.data[0].signature.magic := 11259375;
  HEADER.data[0].version.number := 2; HEADER.data[0].count := 6;
  MODNAME := "KOMПOH-3  "; KEYPAIR(MODNAME, HEADER.data[1]);
  KEYPAIR(LABELFILE.name@.text, HEADER.data[2]);
  HEADER.data[3].firstcode.text := '    ';
  STAMPOBJ(ref(HEADER)); WRITREC(HEADER.data, 6);
  PREFBUF := [0C, 0C, 0C, 0C, 0C, 0C];
  PREFBUF.data[0].signature.kind := 3; PREFBUF.data[0].count := 3;
  DEFBUF := [0C, 0C, 0C, 0C, 0C, 0C, 0C, 0C];
  DEFBUF.data[0].signature.kind := 6;
  DEFBUF.data[0].header.hasname := true;
  PUTLABEL(ROOTPREF@.children);
  PREFBUF := [0C, 0C, 0C, 0C, 0C, 0C];
  PREFBUF.data[0].signature.kind := 255; PREFBUF.data[0].count := 1;
  WRITREC(PREFBUF.data, 1);
% The remaining lines print the output-file summary.
  writeln(' ');
  write("ЗAПИCAH OБ'EKTHЫЙ MOДYЛЬ <");
  write(LABELFILE.name@.text);
  writeln(">, COДEPЖAЩИЙ ГЛOБAЛЬHЫE OПPEДEЛEHИЯ");
  write("ФAЙЛ : ");
  write(LABELFILE.name@.text, ' [', LABELFILE.attr.disk.address:6 oct);
  write("], ДЛИHA : "); PUTSIZE(NUMOBJS(g0567));
  writeln(", OБ'EKTOB : ", g0074-1:1);
  CLOSE(g0567);
end;
% 15556-15220. Convert saved cumulative stamps to per-phase timings.
procedure STATS;
var COUNTER: metric;
    SAVED: stamp;
    N: stage;

procedure PUTTIMES(S: stage);
begin
  (q) for COUNTER := mtcpu to mttotal do (r) begin
    write(' '); PUTTIME(TIMES[S][COUNTER]);
  end;
  writeln;
end;

begin
  SAVED := TIMES[pred(PHASE)];
  (q) for N := pred(PHASE) downto stinit do (r)
    (q) for COUNTER := mtcpu to mttotal do (r)
      TIMES[N][COUNTER] := TIMES[N][COUNTER]-TIMES[pred(N)][COUNTER];
  (q) for COUNTER := mtcpu to mttotal do (r)
    TIMES[stzero][COUNTER] := SAVED[COUNTER]-TIMES[stzero][COUNTER];
  writeln(' ');
  writeln("CTATИCTИKA ПO PAБOTE KOMПOHOBЩИKA":48);
  writeln(' ');
  write("ИHИЦИAЛИЗAЦИЯ ...................."); PUTTIMES(stinit);
  write("PAЗБOP ЗAДAHИЯ ..................."); PUTTIMES(stparse);
  if PHASE > stgather then begin
    write("CБOPKA OПPEДEЛEHИЙ И CCЫЛOK ......"); PUTTIMES(stgather);
  end;
  if PHASE > stresolve then begin
    write("PAЗPEШEHИE CCЫЛOK ................"); PUTTIMES(stresolve);
  end;
  if PHASE > stplace then begin
    write("PACПPEДEЛEHИE ПAMЯTИ ............."); PUTTIMES(stplace);
  end;
  if PHASE > steval then begin
    write("BЫЧИCЛEHИE ЗHAЧEHИЙ OБ'EKTOB ....."); PUTTIMES(steval);
  end;
  if PHASE > stoutput then begin
    write("ЗAПИCЬ BЫПOЛHЯEMOГO PAЗДEЛA ......"); PUTTIMES(stoutput);
  end;
  if PHASE > stlabels then begin
    write("ПOPOЖДEHИE ФAЙЛA METOK ..........."); PUTTIMES(stlabels);
  end;
  writeln('-------- -------- --------':61);
  write(' ':34); PUTTIMES(stzero);
end;
% Main linker driver; service sources are in linker-runtime.
procedure MEMINIT(PAGES, MODE, FLAGS: integer); assembler;
function MEMALLOC(SIZE: integer): phash; assembler;
procedure READNEXT(POOL: integer); fortran;
procedure NEWTAB(POOL: integer); fortran;

begin
  writeln("_014 -= KOMПOHOBЩИK ЭЛЬБPYC-Б : BEPCИЯ 2.40/3 =-");
  GETSTAMP(TIMES[stzero]);
  MEMINIT(32, 3, 0);
  g0076 := ord(MEMALLOC(512)); NAMETAB := ;
  g0076 := g0076+127+1; KEYPOOL := ;
  g0076 := g0076+31+8; PATHPOOL := ;
  g0076 := g0076+31+8; OBJPOOL := ;
  g0076 := g0076+0+8; FILEPOOL := ;
  g0076 := g0076+3+8; SEGPOOL := ;
  g0076 := g0076+1+8; DEFPOOL := ;
  g0076 := g0076+96+8; REFPOOL := ;
  g0076 := g0076+63+8; SECTPOOL := ;
  g0076 := g0076+7+8; PREFPOOL := ;
  g0076 := g0076+1+8; ENTRYPOOL := ;
  g0076 := g0076+0+8; g0566 := ;
  g0076 := g0076+15+8; g0567 := ;
  g0076 := g0076+8; g0570 := ; g0076 := g0076+8;
  g0076 := g0076-ord(NAMETAB);
  if g0076 > 512 then begin writeln('LDES=', g0076:4 oct); halt end;
  INITVEC(2, 4095, " TИMEH", KEYPOOL);
  INITVEC(2, 4095, " ДИM  ", PATHPOOL);
  INITVEC(2, 99, " TЛФ  ", OBJPOOL);
  INITVEC(4, 255, " TOФ  ", FILEPOOL);
  INITVEC(1, 511, " TCEГ ", SEGPOOL);
  INITVEC(3, 8191, " TOБ  ", DEFPOOL);
  INITVEC(1, 37777B, ' TCC  ', REFPOOL);
  INITVEC(5, 399, ' TAC  ', SECTPOOL);
  INITVEC(2, 2047, " KYБA ", g0566);
  (q) for g0077 := 0 to 127 do (r) NAMETAB@[g0077] := ptr(0);
  OBJEDIT(PATHPOOL, 0); g0131 := ; ROOTPREF := ;
  g0131@ := [0C, 0C];
  FILEEDIT(DEFPOOL, 0); g0132 := ; g0132@ := [0C, 0C, 0C];
  FILEEDIT(REFPOOL, 0);
  BINDOBJ("CИCBЫB    ", 1); BINDOBJ("CИCBBOД   ", 2);
  NEWPHASE(stinit); READJOB; NEWPHASE(stparse);
  if 0 in PRINTOPT then begin
    writeln(' ');
    writeln("CBEДEHИЯ OБ OБ'EKTHЫX MOДYЛЯX":74);
    writeln('-----------------------------':74); writeln(' ');
    write(
"      ИMЯ ФAЙЛA       MOДYЛЬ  BEPCИЯ     ДЛИHA       ИHФOPMAЦИЯ");
    writeln(
" O COЗДAHИИ    TPAHCЛЯTOP CEKЦИЙ OБ'EKTOB CCЫЛOK ПPEФИKCOB");
    write(
'      --- -----       ------  ------     -----       ----------');
    writeln(
' - --------    ---------- ------ -------- ------ ---------');
  end;
  SETPOS(SEGPOOL, 0);
  repeat
    g0051 := NUMOBJS(SECTPOOL)+1;
    NEWTAB(SECTPOOL); g0127 := ; g0127@ := [0C, 0C, 0C, 0C, 0C];
    with g0127@ do begin next := g0051; previous := g0051 end;
    OBJEDIT(SEGPOOL, POSITION(SEGPOOL)+1); SEGREC := ;
    SEGREC@.low := g0051;
    (x); g0643 := SEGREC@.count;
    (q) for g0050 to g0643 do (r) begin
      READNEXT(SEGPOOL); SEGREC := ; GATHER(SEGREC@.fileindex);
    end;
  until POSITION(SEGPOOL) > NUMOBJS(SEGPOOL);
  NEWPHASE(stgather); SETPOS(SEGPOOL, 0);
  repeat
    OBJREAD(SEGPOOL, POSITION(SEGPOOL)+1); SEGREC := ;
    (x); g0644 := SEGREC@.count;
    (q) for g0050 to g0644 do (r) begin
      NEWKEY(SEGPOOL); SEGREC := ;
      with SEGREC@ do limit := RESOLVE(SEGREC@.fileindex);
    end;
  until POSITION(SEGPOOL) > NUMOBJS(SEGPOOL);
  if not ALLFOUND then begin
    writeln(' ');
    writeln('  ---------------------------------------------');
    writeln("  !  H E P A З P E Ш E H H Ы E   C C Ы Л K И  !");
    writeln('  ---------------------------------------------');
    writeln(' ');
    SETPOS(SEGPOOL, 0);
    repeat
      OBJREAD(SEGPOOL, POSITION(SEGPOOL)+1); SEGREC := ;
      (x); g0645 := SEGREC@.count;
      (q) for g0050 to g0645 do (r) begin
        READNEXT(SEGPOOL); SEGREC := ;
        with SEGREC@ do if not limit then UNRESMSG(fileindex);
      end;
    until POSITION(SEGPOOL) > NUMOBJS(SEGPOOL);
  end;
  NEWPHASE(stresolve); SETPOS(SEGPOOL, 0);
  LASTSECT := [0C, 0C, 0C, 0C, 0C];
  repeat
    READNEXT(SEGPOOL); SEGREC := ;
    g0063 := SEGREC@.loadbase; NEXTADDR := ;
    READNEXT(SEGPOOL); SEGREC := ;
    with SEGREC@ do SETPOS(SEGPOOL, POSITION(SEGPOOL)+count);
    g0051 := SEGREC@.low;
    TABREAD(SECTPOOL, g0051); g0127 := ; g0054 := g0127@.next;
    (q) while g0054 <> g0051 do (r) begin
      FILEEDIT(SECTPOOL, g0054); g0127 := ; JOINSECT(g0127);
      g0054 := g0127@.next;
    end;
    TABREAD(SECTPOOL, g0054); g0127 := ;
    g0127@.length := NEXTADDR-g0063;
  until POSITION(SEGPOOL) > NUMOBJS(SEGPOOL);
  if 1 in PRINTOPT then begin
    writeln('_014');
    writeln("CBEДEHИЯ O ПPOГPAMMHЫX CEKЦИЯX":60);
    writeln('------------------------------':60); writeln(' ');
    write("    ИMЯ CEKЦИИ      MOДYЛЬ    HAЧAЛO     KOHEЦ     ДЛИHA");
    writeln("   BЫPAB.     ATPИБYTЫ");
    write('    --- ------      ------    ------     -----     -----');
    writeln('   ------     --------');
    SETPOS(SEGPOOL, 1);
    repeat
      READNEXT(SEGPOOL); SEGREC := ;
      with SEGREC@ do SETPOS(SEGPOOL, POSITION(SEGPOOL)+count+1);
      g0051 := SEGREC@.low;
      TABREAD(SECTPOOL, g0051); g0127 := ; g0054 := g0127@.next;
      (q) while g0054 <> g0051 do (r) begin
        TABREAD(SECTPOOL, g0054); g0127 := ; LISTSECT(g0127);
        g0054 := g0127@.next;
      end;
    until POSITION(SEGPOOL) > NUMOBJS(SEGPOOL);
  end;
  NEWPHASE(stplace);
  (values) repeat
    SETPOS(SEGPOOL, 0); g0121 := true; g0122 := false;
    repeat
      OBJREAD(SEGPOOL, POSITION(SEGPOOL)+1); SEGREC := ;
      (x); g0646 := SEGREC@.count;
      (q) for g0050 to g0646 do (r) begin
        READNEXT(SEGPOOL); SEGREC := ;
        with SEGREC@ do
          if not flags.ready then begin
            g0642 := EVALDEFS(SEGREC@.fileindex);
            SEGREC@.flags.ready := g0642 in [evnone, evdone];
            g0122 := g0122 or (g0642 in [evdone, evmixed]);
            g0121 := g0121 and not (g0642 in [evmixed, evwait]);
          end;
      end;
    until POSITION(SEGPOOL) > NUMOBJS(SEGPOOL);
    if g0121 then exit values;
    if not g0122 then begin
      SETPOS(SEGPOOL, 0);
      repeat
        OBJREAD(SEGPOOL, POSITION(SEGPOOL)+1); SEGREC := ;
        (x); g0647 := SEGREC@.count;
        (q) for g0050 to g0647 do (r) begin
          READNEXT(SEGPOOL); SEGREC := ;
          with SEGREC@ do
            if not flags.ready then begin
              TABFILE(FILEPOOL, fileindex, CURRENTFILE);
              g0071 := CURRENTFILE.n0.firstdef;
              g0073 := CURRENTFILE.n0.ndefs;
              (q) for g0107 to g0073 do (r) begin
                TABREAD(DEFPOOL, g0071+g0107-1); g0132 := ;
                with g0132@ do
                  if not c.ready then begin
                    MODULEMSG(ref(CURRENTFILE)); OBJWHERE(a.name);
                    writeln(" - HEBOЗMOЖHO BЫЧИCЛИTЬ ЗHAЧEHИE");
                    goto 9999;
                  end;
              end;
            end;
        end;
      until POSITION(SEGPOOL) > NUMOBJS(SEGPOOL);
    end;
  until false;
  NEWPHASE(steval);
  if 2 in PRINTOPT then begin
    writeln('_014');
    writeln("CBEДEHИЯ O CEГMEHTAX":38);
    writeln('-------- - ---------':38); writeln(' ');
    writeln(
"  ИMEHA CEKЦИЙ     HAЧAЛO     KOHEЦ   PAЗMEЩEHИE HA ДИCKE");
    writeln(
'  ----- ------     ------     -----   ---------- -- -----');
  end;
  ATTACH(2, OUTFILE.attr.disk.address, OUTFILE.attr.disk.length,
         OUTFILE.name@.first6, g0570);
  g0055 := 0; SETPOS(SEGPOOL, 0);
  repeat
    READNEXT(SEGPOOL); SEGREC := ;
    with SEGREC@ do begin g0064 := diskbase; g0063 := loadbase end;
    READNEXT(SEGPOOL); SEGREC := ;
    with SEGREC@ do begin
      if above then g0055 := g0055+g0064 else g0055 := g0064;
      if not concatenate then begin
        g0060 := g0055 div 1024; g0061 := g0055 mod 1024;
        g0062 := g0063 mod 1024;
        if g0062 < g0061 then g0060 := g0060+1;
        g0055 := g0060*1024+g0062;
      end;
      g0051 := low; g0052 := count; g0056 := length+g0055;
    end;
    (q) for g0050 to g0052 do (r) begin
      READNEXT(SEGPOOL); SEGREC := ; WRITESEG(SEGREC@.fileindex);
    end;
    TABREAD(SECTPOOL, g0051); g0127 := ;
    with g0127@ do begin g0054 := next; g0056 := length+g0063-1 end;
    g0061 := g0055; g0055 := g0127@.length+g0055;
    OUTPAIR.hi := 7777777777777777C; OUTPAIR.lo := ;
    PUTPAIR(g0570, g0055, OUTPAIR);
    if 2 in PRINTOPT then begin
      ALLFOUND := true;
      (q) while g0054 <> g0051 do (r) begin
        TABREAD(SECTPOOL, g0054); g0127 := ;
        with g0127@ do begin g0140 := name; g0054 := next end;
        PUTSECTN(g0127);
        if ALLFOUND then begin
          writeln('  ', g0063:7 hex, '   ', g0056:7 hex, '  ',
            g0061*2 div 1024:4 oct, ':', g0061*2 mod 1024:4 oct, '-',
            g0055*2 div 1024:4 oct, ':', g0055*2 mod 1024:4 oct);
          ALLFOUND := false;
        end else writeln;
        TABREAD(SECTPOOL, g0054); g0127 := ;
        (q) while g0127@.name = g0140 do (r) begin
          g0054 := g0127@.next;
          TABREAD(SECTPOOL, g0054); g0127 := ;
        end;
      end;
    end;
  until POSITION(SEGPOOL) > NUMOBJS(SEGPOOL);
  writeln(' ');
  write("CИCTEMHЫЙ BЫПOЛHЯEMЫЙ PAЗДEЛ ЗAПИCAH B ФAЙЛ ");
  write(OUTFILE.name@.text, ' [', OUTFILE.attr.disk.address:6 oct);
  write("], ДЛИHA : "); PUTSIZE(g0057); writeln;
  CLOSE(g0570); NEWPHASE(stoutput);
  if LABELFILE.name <> ptr(0) then begin LABELS; NEWPHASE(stlabels) end;
  9999: if 3 in PRINTOPT then STATS;
  writeln(' '); writeln("=== KOHEЦ PAБOTЫ KOMПOHOBЩИKA ===");
  repeat besm(0740000B); (x); until false;
  (x);
end.D
  PADCHAR = ' ';
  NAMETAB = 0C;
  ROOTPREF = 0C;
  g0074 = 1;
  g0075 = 1;
  ALLFOUND = true;
  XLATTAB =
    atend:10,
    white,
    atend:20,
    punct,
    white,
    atend:7,
    punct:8,
    digit:10,
    punct:6,
    atend,
    letter:26,
    atend:6,
    letter:26,
    atend:69,
    letter:31,
    atend,
    letter:31,
    atend;
  MONTHDAY = 0, 31, 59, 90, 120, 151, 181,
             212, 243, 273, 304, 334, 365
end
