(*=y+,p-,t-,s7,s8,o-,m-*)
program LINK1(input, output, PADCHAR);
label 9999;
% LINK1, 4001/0175: recovered Pascal application, 02012-16630.
% Build: python3 programs/link1/build.py (compile and compare only).
% Linked with the recovered runtime; linker is not run by build.
% Remaining compiler differences are listed in README.md/recovery.json.
% Shared names follow KOMPON 2.02/3 PMD on volume 2248.
% Other names describe behavior; these images have no PMD.
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
    13: (data0, data1: packed record high: uint8;
                        value: uint24; low: uint16 end)
  end;
  phash = @hashtable;
  hashtable = array [0..127] of pkey;
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
  evalform = (POБK, POБПФK, POБCЛ, POБПCЛ);
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
  metric = (ЦП, KOM, ACTP);
  stamp = array [metric] of integer;
  stage = (CYMMA, ШAГИHИЦ, ШAГЗAДAH, ШAГCБOPK, ШAГPAЗPE, ШAГPAЗME,
           ШAГBЫЧ, ШAГЗAГP, ШAГГEHME, stend);
  evalstate = (evnone, evdone, evmixed, evwait);
  ordering = (PB, БЛ, MH);
  charclass = (БYKBA, ЦИФPA, PAЗЛИT, CПEЦЛИT, ЗAПPЛИT);
  dateparts = array [0..3] of integer;
var
  HMOД, HAЧCTAC, ЧИCЛOMOД, CTCEГ, CTAC, CЧAДPAЗД, CЧAKCEГM, CPAЗД,
  ЗOHA, AДBЗOHE, AЗBЗOHE, HAЗCEГM, g0064, HAЧMTAC: integer;
  HAЧMTCC: integer;
  KOHMTAC,
  KOHMTCC, HAЧMTOБ, KOHMTOБ, g0073, HOMEPOБЬ, HOMEPПPE, AДEC, I,
  CBЫP, CKOHBЫP, CTEKCT, CKOHTEK: integer;
  CЧAC: integer;
  HAЧAЛOЗA, NЗAП: integer;
  ИHДEKCTO,
  ЗHAЧOK: integer;
  PEГOБ: evalform;
  ГЛTEГИ: integer;
  CЛOBO: pair;
  ФПPABC: boolean;
  PAЗPEШИЛ: boolean;
  БЫЛИOШЭT: boolean;
  БЫЛИOШMO: boolean;
  BKЛЮЧEHO, g0122: boolean;
  TEKOФ: filerec;
  YKTAC: psect;
  YKTCEГ: psegment;
  YKДИM: pprefix;
  YKTOБ: pdef;
  ЭЛTACП: sectrec;
  ИMЯTEKCE: pprefix;
  BEKXEШ: phash;
  HAЧAЛOДИ: pprefix;
  MTИЛ: array [char] of charclass;
  PEЖИMЫ: bitset;
  DEBUG: integer;
  ФAЙЛPAЗД, ФAЙЛCXEM, ФAЙЛMET: objecthead;
  TИПPAЗД: boolean;
  TИMEH, ДИM, TЛФ, TOФ, TCEГ, TOБ, TCC,
  TAC, TПPE, TЭM, KYБA, ФOM, PAЗД: integer;
  TEKЭTAП: stage;
  CTATЭTAП: array [CYMMA..ШAГГEHME] of stamp;
  HAЧAЛOME: array [1..13] of integer;
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
procedure ПEЧBPE(BPEMЯ: integer);
begin
  PADCHAR := '0';
  write(BPEMЯ div 3000 mod 100:2, ':', BPEMЯ div 50 mod 60:2,
        '.', BPEMЯ * 2 mod 100:2);
  PADCHAR := ' ';
end;

% 02042: collect namespace components, print in reverse order.
procedure ПEЧИMЯOБ(YKДИM: pprefix);
var BHYTPИMЯ: array [1..12] of pkey;
    YPИM: integer;
begin
  YPИM := 0;
  (q) while (YKДИM <> HAЧAЛOДИ) and (YKДИM <> ptr(0)) do (r) begin
    YPИM := YPИM + 1;
    BHYTPИMЯ[YPИM] := YKДИM@.name;
    YKДИM := YKДИM@.next;
  end;
  (q) for YPИM := YPИM downto 1 do (r) write(BHYTPИMЯ[YPИM]@.text);
end;

% 02070: length of the same qualified name.
function ДЛИПOЛИM(YKДИM: pprefix): integer;
var ДЛИHA: integer;
begin
  ДЛИHA := 0;
  (q) while (YKДИM <> HAЧAЛOДИ) and (YKДИM <> ptr(0)) do (r) begin
    ДЛИHA := NAMELEN(YKДИM@.name@) + ДЛИHA;
    YKДИM := YKДИM@.next;
  end;
  ДЛИПOЛИM := ДЛИHA;
end;

% 02113: save accounting values at the start of a linker phase.
procedure CTATИCT(ЭTAП: stage);
begin
  GETSTAMP(CTATЭTAП[ЭTAП]);
  TEKЭTAП := succ(ЭTAП);
  БЫЛИOШЭT := false;
end;

% 02125: lookup in one sorted hash bucket. CMPNAME returns raw 0/1/2.
function ПOИCKИME(ИMЯ: namekey): pkey;
var YKИMЯ: pkey;
begin
  YKИMЯ := BEKXEШ@[HASHNAME(ИMЯ)];
  ПOИCKИME := ptr(0);
  (q) while YKИMЯ <> ptr(0) do (r)
    case CMPNAME(ИMЯ, YKИMЯ@) of
      PB: begin ПOИCKИME := YKИMЯ; exit end;
      БЛ: YKИMЯ := YKИMЯ@.next;
      MH: exit
    end;
end;

% 02172: insert a name, preserving the sorted bucket chain.
function BHECИИMЯ(HOBИMЯ: namekey): pkey;
var CXEШ: integer;
    YKИMЯ, YKИMЯT, YKИMЯП: pkey;
begin
  CXEШ := HASHNAME(HOBИMЯ);
  YKИMЯT := BEKXEШ@[CXEШ];
  if YKИMЯT = ptr(0) then begin
    NEWKEY(TИMEH); YKИMЯ := ;
    BEKXEШ@[CXEШ] := ;
    with YKИMЯ@ do begin text := HOBИMЯ; next := ptr(0) end;
  end else begin
    YKИMЯП := ptr(0);
    (search) repeat
      case CMPNAME(HOBИMЯ, YKИMЯT@) of
        PB: begin BHECИИMЯ := YKИMЯT; exit end;
        БЛ: begin YKИMЯП := YKИMЯT; YKИMЯT := YKИMЯT@.next end;
        MH: exit search
      end;
    until YKИMЯT = ptr(0);
    NEWKEY(TИMEH); YKИMЯ := ;
    with YKИMЯ@ do begin text := HOBИMЯ; next := YKИMЯT end;
    if YKИMЯП = ptr(0) then BEKXEШ@[CXEШ] := YKИMЯ
    else YKИMЯП@.next := YKИMЯ;
  end;
  BHECИИMЯ := YKИMЯ;
end;

% 02312: lookup an object by its interned name.
procedure SFILE(ЛOГ: namekey; var ФИЗ: objecthead);
var YKTЛФ: pobj;
    CTЛФ: integer;
    YKИMЯ: pkey;
    LAST: integer;
begin
% Historical compiler loaded the first word of the value parameter
% again after P/LNGPAR; the current compiler omits that unused load.
  besm(010100005B);
  YKИMЯ := ПOИCKИME(ЛOГ);
  ФИЗ.name := ptr(0);
  if YKИMЯ = ptr(0) then exit;
  LAST := NUMOBJS(TЛФ);
  (*q*) for CTЛФ := 0 to LAST do (r) begin
    OBJREAD(TЛФ, CTЛФ); YKTЛФ := ;
    if YKTЛФ@.head.name = YKИMЯ then begin
      ФИЗ := YKTЛФ@.head;
      exit;
    end;
  end;
end;

% 02353: associate an interned name with a module number.
procedure ASSIGN(ИMЯ: namekey; ФИMЯ: integer);
var YKTЛФ: pobj;
    YKИMЯ: pkey;
    CTЛФ, LAST: integer;
begin
% Same historical value-parameter load as in SFILE.
  besm(010100005B);
  YKИMЯ := BHECИИMЯ(ИMЯ);
  (x);
  LAST := NUMOBJS(TЛФ);
  (*q*) for CTЛФ := 0 to LAST do (r) begin
    OBJEDIT(TЛФ, CTЛФ); YKTЛФ := ;
    with YKTЛФ@ do if head.name = YKИMЯ then begin
      head.attr.module := ФИMЯ;
      exit;
    end;
  end;
  (x);
  OBJEDIT(TЛФ, NUMOBJS(TЛФ)+1); YKTЛФ := ;
  with YKTЛФ@ do begin
    head.name := YKИMЯ;
    head.attr.module := ФИMЯ;
  end;
end;

% Recovered link-job parser PAЗБOPЗA (03717) and its nested scanner.
procedure PAЗБOPЗA;
type
  charbits = set of '_000'..'_057';
  tokentype = (ИMЯ, ФAЙЛ, YKФAЙЛ, ЦEЛOE, ЧИCЛO, PAЗД);
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
var ЛИT, БYФЛИT: char;
    ЧCTPOK, HAЧЛEKC, KOHЛEKC, HЛИT: integer;
    ЧФAЙЛOB, HAЗCEГ, HAДCEГ, MДЛИCEГ, CHAЧCEГ, CTOФ: integer;
    TИЛ: charclass;
    ЛEKC: token;
    БYФЛEKC: namekey;
    TИЛEKC: tokentype;
    ФИЗБYФ: boolean;
    ФOTHAД, CONCAT, ПOCXEME, БЫЛBЫXФ, БЫЛИOФ,
    БЫЛИKBAЛ: boolean;
    MACФЛ: fileflags;
    ДECФAЙЛA: objecthead;
    YKTOФ: pfile;
    CTPOKA: packed array [1..120] of char;
    LIMIT: integer;

% 02426. Preserve the common GET even when returning a saved character.
procedure ДAЙЛИT;
begin
  if ФИЗБYФ then begin
    ЛИT := БYФЛИT; ФИЗБYФ := false;
  end else if eoln(input) then ЛИT := '_037'
  else if eof(input) then begin
    ЛИT := '_012';
    CTPOKA[HЛИT] := ЛИT;
    HЛИT := 0;
    ЧCTPOK := ЧCTPOK + 1;
  end else begin
    ЛИT := input@;
    CTPOKA[HЛИT] := ЛИT;
  end;
  if ЛИT <> '_037' then begin get(input); HЛИT := HЛИT + 1 end;
  TИЛ := MTИЛ[ЛИT];
end;

% 02463. Message selection is inserted from the image's ISO literals.
procedure OШCKAH(HOMOШ: integer);
var I, LIMIT: integer;
begin
  writeln("* * *  OШИБKA B ЗAДAHИИ KOMПOHOBЩИKY * * *");
  write('CTPOKA ', ЧCTPOK:1, ' : ');
  case HOMOШ of
    0: writeln("OШИБKA B ЦEЛOM");
    1: writeln("HEДOПYCTИMЫЙ BИPTYAЛЬHЫЙ HOMEP");
    2: writeln("HEДOПYCTИMЫЙ HOMEP ЗOHЫ");
    3: writeln("HEBEPHAЯ ДЛИHA ФAЙЛA");
    4: writeln("OTCYTCTBYET ДЛИHA ФAЙЛA");
    5: writeln("BCTPETИЛCЯ KOHEЦ BBOДHOГO ФAЙЛA");
    6: begin HЛИT := HЛИT + 1;
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
    others: writeln("OШCИC=", HOMOШ:1, '!!!')
  end;
  if ЛИT <> '_037' then begin
    KOHЛEKC := HЛИT - 1;
    (q) while ЛИT <> '_012' do (r) ДAЙЛИT;
    HЛИT := 1;
    (q) while CTPOKA[HЛИT] <> '_012' do (r) begin
      write(CTPOKA[HЛИT]); HЛИT := HЛИT + 1;
    end;
    writeln;
    if HAЧЛEKC >= KOHЛEKC then KOHЛEKC := HЛИT;
    (q) for I := 2 to HAЧЛEKC do (r) write(' ');
    LIMIT := KOHЛEKC - 1;
    (*q*) for I := HAЧЛEKC to LIMIT do (r) write('^');
    (x);
    writeln;
  end else writeln('<EOF>');
  besm(0740000B);
end;

% 03335's helpers are nested one level deeper than OШCKAH/ДAЙЛИT.
procedure CKAHEP(CЛEKC: bitset);

% 02752.
procedure BOЗЛИT(ЛИTC: char);
begin
  БYФЛИT := ЛИT; ФИЗБYФ := true; ЛИT := ЛИTC; TИЛ := MTИЛ[ЛИT];
end;

% 02761.
function CИMBOЛИM(TИЛ: charclass): boolean;
begin
  CИMBOЛИM := TИЛ in [БYKBA, ЦИФPA];
end;

% 02765.
procedure ПPOПPAЗД;
begin
  (q) while TИЛ = PAЗЛИT do (r) begin ДAЙЛИT; (q); end;
end;

% 02775.
procedure ДAЙPAЗД;
begin
  (q) while not (TИЛ in [PAЗЛИT, CПEЦЛИT, ЗAПPЛИT]) do (r) begin
    ДAЙЛИT; (q);
  end;
end;

% 03034. Numeric suffixes H/B/З/C/Д select hex, octal, 1024-scaled
% octal, 256-scaled octal and decimal. Unsuffixed numbers are octal.
procedure ДAЙЦEЛOE(var ЧИC: integer);
var ЧC, I, KOД, MACШTAБ: integer;
    БYФ: array [1..12] of char;
    TИПЦ: char;
    LIMIT: integer;

% 03006.
  function ЦEЛOE(OCH: integer): integer;
  var I, J, LIMIT: integer;
  begin
    J := 0;
    (x);
    LIMIT := ЧC - 1;
    (*q*) for I to LIMIT do (r) begin
      KOД := ord(БYФ[I]) - 48;
      if (KOД < 0) or (KOД >= OCH) then OШCKAH(0);
      J := J * OCH + KOД;
    end;
    (x);
    ЦEЛOE := J;
  end;

begin
  ЧC := 1;
  repeat
    if ЧC > 12 then OШCKAH(0);
    БYФ[ЧC] := ЛИT;
    ЧC := ЧC + 1;
    ДAЙЛИT;
  until TИЛ in [PAЗЛИT, CПEЦЛИT, ЗAПPЛИT];
  (x);
  ЧC := ЧC - 1;
  TИПЦ := БYФ[ЧC];
  ЧИC := 0;
  MACШTAБ := 1;
  if TИПЦ = 'H' then begin
    LIMIT := ЧC - 1;
    (*q*) for I to LIMIT do (r) begin
      KOД := ord(БYФ[I]) - 31;
      if KOД in [17..26] then KOД := KOД - 17
      else if KOД in [34..39] then KOД := KOД - 34 + 10
      else OШCKAH(0);
      ЧИC := ЧИC * 16 + KOД;
    end;
    (x);
  end else if TИПЦ = 'B' then ЧИC := ЦEЛOE(8)
  else if TИПЦ = "_372" then begin
    MACШTAБ := 1024; ЧИC := ЦEЛOE(8);
  end else if TИПЦ = 'C' then begin
    MACШTAБ := 256; ЧИC := ЦEЛOE(8);
  end else if TИПЦ = "_344" then ЧИC := ЦEЛOE(10)
  else begin ЧC := ЧC + 1; ЧИC := ЦEЛOE(8) end;
  ЧИC := ЧИC * MACШTAБ;
end;

% 03153. Decimal parser used where the grammar requests decimal input.
procedure ДAЙЧИCЛO(var ЧИC: integer);
var I: integer;
begin
  I := 0; ЧИC := ;
  repeat
    ЧИC := ЧИC * 10 + ord(ЛИT) - 48;
    I := I + 1;
    if I > 12 then OШCKAH(0);
    ДAЙЛИT;
  until TИЛ <> ЦИФPA;
  (x);
end;

% 03176.
procedure ДAЙИMЯФA;
var I: integer;
begin
%  with VALUE do begin
%    first6 := '      '; last6 := '    _000_000';
%  end;
  ЛEKC := [ '      ', '    _000_000' ];
  I := 1;
  (q) while CИMBOЛИM(TИЛ) and (I <= 10) do (r) begin
    ЛEKC.text[I] := ЛИT;
    I := I + 1;
    ДAЙЛИT;
    (q);
  end;
  ДAЙPAЗД;
  if ЛИT = '.' then begin ДAЙЛИT; ДAЙPAЗД end;
end;

% 03230. Packed disk address: virtual drive 16..55, zone 0..3995.
procedure ДAЙYKФAЙ;
var I, HY, ЗЗ: integer;
begin
  ДAЙЦEЛOE(I);
  HY := I div 4096;
  ЗЗ := I mod 4096;
  if (HY < 16) or (HY > 55) then OШCKAH(1);
  if ЗЗ > 3995 then OШCKAH(2);
  ЛEKC.disk.address := I;
  ПPOПPAЗД;
  if ЛИT = ':' then begin
    ДAЙЛИT; ПPOПPAЗД;
    if TИЛ = ЦИФPA then begin
      ДAЙЦEЛOE(I);
      if I > 127 then OШCKAH(3);
      ЛEKC.disk.length := I;
    end else OШCKAH(4);
  end else ЛEKC.disk.length := 127;
end;

% 03312.
procedure ДAЙИMЯ;
var I: integer;
begin
  ЛEKC.a6 := '      '; I := 1;
  repeat
    ЛEKC.text[I] := ЛИT;
    ДAЙЛИT; I := I + 1;
    (x);
  until not CИMBOЛИM(TИЛ) or (I > 6);
  ДAЙPAЗД;
end;

% 03335. CKAHPAЗД bits 0..5 select the token representations accepted.
begin
  ПPOПPAЗД;
  if ЛИT = '(' then begin
    ДAЙЛИT;
    if ЛИT = '*' then begin
      (comment) repeat
        ДAЙЛИT;
        if ЛИT = '*' then begin
          ДAЙЛИT;
          if ЛИT = ')' then begin ДAЙЛИT; exit comment end;
        end;
      until ЛИT = '_037';
      if ЛИT = '_037' then OШCKAH(5);
      ПPOПPAЗД;
    end else BOЗЛИT('(');
  end;
  HAЧЛEKC := HЛИT - 1;
  if TИЛ = БYKBA then
    if 1 in CЛEKC then begin ДAЙИMЯФA; TИЛEKC := ФAЙЛ end
    else if 0 in CЛEKC then begin ДAЙИMЯ; TИЛEKC := ИMЯ end
    else OШCKAH(6)
  else if TИЛ = ЦИФPA then
    if 2 in CЛEKC then begin ДAЙYKФAЙ; TИЛEKC := YKФAЙЛ end
    else if 3 in CЛEKC then begin ДAЙЦEЛOE(ЛEKC.number);
      TИЛEKC := ЦEЛOE end
    else if 4 in CЛEKC then begin ДAЙЧИCЛO(ЛEKC.number);
      TИЛEKC := ЧИCЛO end
    else OШCKAH(6)
  else if TИЛ = CПEЦЛИT then
    if 5 in CЛEKC then begin
      if ЛИT = '*' then begin
        ДAЙЛИT;
        if ЛИT = '/' then ЛИT := '_037' else BOЗЛИT('*');
      end;
      ЛEKC.symbol := chr(ord(ЛИT) - 31);
      TИЛEKC := PAЗД;
      ДAЙЛИT;
    end else OШCKAH(6)
  else if TИЛ = ЗAПPЛИT then OШCKAH(6);
end;

% 03455. Punctuation is represented as ord(character)-31.
procedure CKAHPAЗД(MPAЗ: charbits);
begin
  CKAHEP([5]);
  if not (ЛEKC.symbol in MPAЗ) then OШCKAH(7);
end;

% 03466. Intern an object-file entry and refresh its module number.
function BHECИOФ(ДECФAЙЛA: objecthead): integer;
label 1;
var CTOФ: integer;
    YKTOФ: pfile;
begin
  (*q*) for CTOФ := 0 to NUMOBJS(TOФ) do (r) begin
    FILEEDIT(TOФ, CTOФ); YKTOФ := ;
    if YKTOФ@.name = ДECФAЙЛA.name then goto 1;
  end;
  CTOФ := NUMOBJS(TOФ) + 1;
  FILEEDIT(TOФ, CTOФ); YKTOФ := ;
  YKTOФ@ := [0C, 0C, 0C, 0C];
  1: with YKTOФ@ do begin
    name := ДECФAЙЛA.name; module := shift(integer(ДECФAЙЛA.attr), 18);
  end;
  BHECИOФ := CTOФ;
end;

% 03541. Apply one per-file flag to a list of named object files.
procedure YTOЧHEHИ(ФЛAГ: integer);
var CTOФ: integer;
    YKTOФ: pfile;
    ДECФAЙЛA: objecthead;
    LIMIT: integer;
begin
  if ЛEKC.symbol = '_016' then MACФЛ := MACФЛ + [ФЛAГ];
  repeat
    CKAHEP([1]);
    SFILE(ЛEKC.text, ДECФAЙЛA);
    if ДECФAЙЛA.name = ptr(0) then OШCKAH(10);
    (search) begin
      LIMIT := NUMOBJS(TOФ);
      (*q*) for CTOФ := 0 to LIMIT do (r) begin
        FILEEDIT(TOФ, CTOФ); YKTOФ := ;
        if YKTOФ@.name = ДECФAЙЛA.name then exit search;
      end;
      FILEEDIT(TOФ, NUMOBJS(TOФ)+1); YKTOФ := ;
      YKTOФ@ := [0C, 0C, 0C, 0C];
      YKTOФ@.name := ДECФAЙЛA.name;
    end;
    with YKTOФ@ do flags := flags + [ФЛAГ];
    CKAHPAЗД(['_000','_015','_034']);
    (x);
  until ЛEKC.symbol in ['_000','_034'];
  (x);
end;

% 03641. Select the listing sections requested by the link job.
procedure PEЖПEЧ;
begin
  CKAHEP([0,5]);
  if TИЛEKC = PAЗД then begin
    if ЛEKC.symbol in ['_000','_015','_034'] then begin
      PEЖИMЫ := PEЖИMЫ + [0..3]; exit;
    end;
    if ЛEKC.symbol = '_036' then CKAHEP([0]) else OШCKAH(7);
  end;
  repeat
    if ЛEKC.a6 = "CEKЦИИ" then PEЖИMЫ := PEЖИMЫ + [1]
    else if ЛEKC.a6 = "PAЗДEЛ" then PEЖИMЫ := PEЖИMЫ + [2]
    else if ЛEKC.a6 = 'CTAT  ' then PEЖИMЫ := PEЖИMЫ + [3]
    else if ЛEKC.a6 = "MOДYЛИ" then PEЖИMЫ := PEЖИMЫ + [0]
    else if ЛEKC.a6 = "METKИ " then PEЖИMЫ := PEЖИMЫ + [4]
    else OШCKAH(8);
    CKAHPAЗД(['_015','_034']);
    if ЛEKC.symbol = '_034' then exit;
    CKAHEP([0]);
    (x);
  until false;
end;

% 03717. File declarations, load list and optional explicit layout.
begin
  ЧCTPOK := 0; HЛИT := 1; ФИЗБYФ := false;
  ДAЙЛИT;
  PEЖИMЫ := [2]; MACФЛ := [];
  CKAHEP([0]);
  if ЛEKC.a6 <> "ФAЙЛЫ " then OШCKAH(11);
  repeat
    CKAHEP([1]); БYФЛEKC := ЛEKC.text;
    CKAHPAЗД(['_036']); CKAHEP([2]);
    ASSIGN(БYФЛEKC, ЛEKC.filecode.module);
    CKAHPAЗД(['_015','_034']);
  until ЛEKC.symbol = '_034';
  (x);
  CKAHEP([0]);
  if ЛEKC.a6 <> "ЗAГP  " then OШCKAH(12);
  ПOCXEME := false; БЫЛBЫXФ := ;
  БЫЛИOФ := ; БЫЛИKBAЛ := ;
  ЧФAЙЛOB := 0; CHAЧCEГ := ; SETPOS(TCEГ, 2);
  repeat
    CKAHEP([1]); SFILE(ЛEKC.text, ДECФAЙЛA);
    if ДECФAЙЛA.name = ptr(0) then OШCKAH(10);
    CKAHPAЗД(['_000','_015','_020','_034']);
    if ЛEKC.symbol = '_020' then begin
      БЫЛИKBAЛ := true; CKAHEP([0]);
      if ЛEKC.a6 = "PAЗДEЛ" then begin
        if БЫЛBЫXФ then OШCKAH(13);
        if ПOCXEME then OШCKAH(16);
        if not БЫЛИOФ then OШCKAH(9);
        БЫЛBЫXФ := true; ФAЙЛPAЗД := ДECФAЙЛA;
        TИПPAЗД := false; HAЗCEГ := 1;
        CKAHPAЗД(['_000','_015','_034']);
      end else if ЛEKC.a6 = "CИC   " then begin
        if БЫЛBЫXФ then OШCKAH(13);
        if not БЫЛИOФ and not ПOCXEME then OШCKAH(9);
        БЫЛBЫXФ := true; ФAЙЛPAЗД := ДECФAЙЛA; TИПPAЗД := true;
        if БЫЛИOФ then begin
          CKAHPAЗД(['_036']); CKAHEP([3]); HAЗCEГ := ЛEKC.number;
        end;
        CKAHPAЗД(['_000','_015','_034']);
      end else if ЛEKC.a6 = "ЛИCT  " then PEЖПEЧ
      else if ЛEKC.a6 = 'CXEMA ' then begin
        if БЫЛИOФ then OШCKAH(16);
        ФAЙЛCXEM := ДECФAЙЛA; ПOCXEME := true;
        CKAHPAЗД(['_000','_015','_034']);
      end else if ЛEKC.a6 = "METKИ " then begin
        ФAЙЛMET := ДECФAЙЛA;
        CKAHPAЗД(['_000','_015','_016','_034','_036']);
        if ЛEKC.symbol in ['_016','_036'] then YTOЧHEHИ(1C)
        else MACФЛ := MACФЛ + [1];
      end else OШCKAH(17);
    end else if ЛEKC.symbol = '_015' then begin
      if ПOCXEME or БЫЛИKBAЛ then OШCKAH(19);
      ЧФAЙЛOB := ЧФAЙЛOB + 1; БЫЛИOФ := true;
      NEWKEY(TCEГ); YKTCEГ := ;
      with YKTCEГ@ do begin
        fileindex := BHECИOФ(ДECФAЙЛA); limit := false;
      end;
    end;
  until ЛEKC.symbol in ['_000','_034'];
  (x);
  if not БЫЛBЫXФ then OШCKAH(18);
  if ПOCXEME then begin
    if ЛEKC.symbol = '_000' then OШCKAH(5);
    CKAHEP([1,5]);
    if TИЛEKC = PAЗД then
      if ЛEKC.symbol = '_000' then OШCKAH(5) else OШCKAH(7);
    (layout) repeat
      HAЗCEГ := 1; HAДCEГ := 0; MДЛИCEГ := 377777B;
      ФOTHAД := true; CONCAT := false; ЧФAЙЛOB := 0;
      SETPOS(TCEГ, CHAЧCEГ + 2);
      (objects) repeat
        SFILE(ЛEKC.text, ДECФAЙЛA);
        if ДECФAЙЛA.name = ptr(0) then OШCKAH(10);
        ЧФAЙЛOB := ЧФAЙЛOB + 1;
        NEWKEY(TCEГ); YKTCEГ := ;
        with YKTCEГ@ do begin
          fileindex := BHECИOФ(ДECФAЙЛA); limit := false;
        end;
        CKAHPAЗД(['_000','_014','_033','_034']);
        if ЛEKC.symbol <> '_014' then exit objects;
        CKAHEP([1]); (q);
      until false;
      if ЛEKC.symbol = '_033' then
        (quals) repeat
          (onequal) begin
            CKAHEP([0,3]);
            if TИЛEKC = ЦEЛOE then HAЗCEГ := ЛEKC.number
            else if ЛEKC.a6 = "HAЗ   " then begin
              CKAHPAЗД(['_036']); CKAHEP([3]); HAЗCEГ := ЛEKC.number;
            end else if ЛEKC.a6 = "HAД   " then begin
              CKAHPAЗД(['_014','_036']);
              ФOTHAД := ЛEKC.symbol = '_014';
              CKAHEP([3]); HAДCEГ := ЛEKC.number;
              CKAHPAЗД(['_000','_015','_017','_034']);
              CONCAT := ЛEKC.symbol = '_017';
              if not CONCAT then begin
                if ЛEKC.symbol = '_015' then exit onequal;
                exit quals;
              end else;
            end else if ЛEKC.a6 = "ДЛИ   " then begin
              CKAHPAЗД(['_036']); CKAHEP([3]); MДЛИCEГ := ЛEKC.number;
            end else begin OШCKAH(14); (q) exit q end;
            CKAHPAЗД(['_000','_015','_034']);
          end;
        until ЛEKC.symbol in ['_000','_034'];
      OBJEDIT(TCEГ, CHAЧCEГ); YKTCEГ := ;
      with YKTCEГ@ do begin
        if HAДCEГ > 7777777B then OШCKAH(21);
        diskbase := HAДCEГ;
        if HAЗCEГ >= 100000B then OШCKAH(20);
        loadbase := HAЗCEГ;
      end;
      NEWKEY(TCEГ); YKTCEГ := ;
      with YKTCEГ@ do begin
        above := ФOTHAД; concatenate := CONCAT;
        if MДЛИCEГ > 377777B then OШCKAH(22);
        length := MДЛИCEГ; count := ЧФAЙЛOB;
      end;
      CHAЧCEГ := NUMOBJS(TCEГ) + 1;
      if ЛEKC.symbol = '_000' then exit layout;
      CKAHEP([1,5]);
    until TИЛEKC = PAЗД;
  end else begin
    if not БЫЛИOФ then OШCKAH(9);
    OBJEDIT(TCEГ, CHAЧCEГ); YKTCEГ := ;
    with YKTCEГ@ do begin
      diskbase := 0;
      if HAЗCEГ >= 100000B then OШCKAH(20);
      loadbase := HAЗCEГ;
    end;
    NEWKEY(TCEГ); YKTCEГ := ;
    with YKTCEГ@ do begin
      above := false; concatenate := false;
      length := ФAЙЛPAЗД.attr.filelen * 1024;
      count := ЧФAЙЛOB;
    end;
  end;
  if MACФЛ <> [] then begin
    (x);
    LIMIT := NUMOBJS(TOФ);
    (*q*) for CTOФ := 0 to LIMIT do (r) begin
      FILEEDIT(TOФ, CTOФ); YKTOФ := ;
      with YKTOФ@ do flags := flags mod MACФЛ;
    end;
  end;
  CLOSE(TЛФ);
end;

% 04475: print a phase heading once before its first diagnostic.
procedure OШИБKИHA;
begin
  if not БЫЛИOШЭT then begin
    write("> > >  OШИБKИ HA ЭTAПE ");
    case TEKЭTAП of
      ШAГCБOPK: write("CБOPKИ OПPEДEЛEHИЙ И CCЫЛOK");
      ШAГPAЗPE: write("PAЗPEШEHИЯ CCЫЛOK");
      ШAГPAЗME: write("PACПPEДEЛEHИЯ ПAMЯTИ");
      ШAГBЫЧ: write("BЫЧИCЛEHИЯ ЗHAЧEHИЙ OБ'EKTOB");
      ШAГЗAГP: write("ФOPMИPOBAHИЯ PAЗДEЛA")
    end;
    writeln(' < < <'); БЫЛИOШЭT := true;
  end;
end;

% 04541: module heading, likewise emitted once per input module.
procedure OШИБKИBM(YKTOФ: pfile);
begin
  OШИБKИHA;
  if not БЫЛИOШMO then begin
    writeln("* * * MOДYЛЬ ", YKTOФ@.name@.text:1, ' * * *');
    БЫЛИOШMO := true;
  end;
end;

% 04562: identify the input record and its position in the module.
procedure KOOPД(TИПЗ: integer);
begin
  write("ЗAПИCЬ TИПA <", TИПЗ:2 hex, '> (N=', NЗAП:1);
  write(", AДPEC - ", HAЧAЛOЗA * 2 div 1024:2 oct, ':',
        HAЧAЛOЗA * 2 mod 1024:4 oct, ')');
end;

% 04612 and 04635: preserve the file-table descriptor around input.
procedure OTKPOЙOФ(CTOФ: integer);
begin
  GETFILED(TOФ, CTOФ, TEKOФ);
  ATTACH(2, TEKOФ.filedata.address,
         TEKOФ.filedata.length,
         TEKOФ.name@.first6, ФOM);
  NЗAП := 0; БЫЛИOШMO := false;
end;

procedure ЗAKPOЙOФ(CTOФ: integer);
begin
  PUTFILED(TOФ, CTOФ, TEKOФ); CLOSE(ФOM);
end;

% 04647: report the size in bytes and in 1024-byte blocks, in octal.
procedure ПEЧДЛФAЙ(ДЛ: integer);
begin
  ДЛ := (ДЛ + 1) * 2;
  write(ДЛ:5 oct, 'B (', (ДЛ + 1024 - 1) div 1024:3 oct, ')');
end;

% 04666: four-byte translator identifier, with NULs blanked.
procedure ПEЧALF0(A: code4);
var I: integer;
begin
  (q) for I := 0 to 3 do (r)
    if A[I] = '_000' then write(' ') else write(A[I]);
end;

% 04707: read N pairs; retain input position and record number.
procedure ДAЙЗAП(var BUFFER: pairs; L: integer);
var I, LAST: integer;
begin
  HAЧAЛOЗA := POSITION(ФOM);
  (x);
  LAST := L - 1;
  (*q*) for I := 0 to LAST do (r) READPAIR(ФOM, BUFFER[I]);
  (x);
  NЗAП := NЗAП + 1;
end;

% 04735: read the body following an already-read record header.
procedure ДAЙЗAПИC(var BUFFER: pairs);
var I, LAST: integer;
begin
  with BUFFER[0] do begin
    (x);
    LAST := BUFFER[0].count - 1;
  end;
  (*q*) for I := 1 to LAST do (r) READPAIR(ФOM, BUFFER[I]);
  (x);
end;

% 04761: read a slice into a larger pair buffer.
procedure ДAЙTEЛЗA(var BUFFER: pairs; N, L: integer);
var I, LAST: integer;
begin
  (x);
  LAST := L - 1;
  (*q*) for I := 0 to LAST do (r) READPAIR(ФOM, BUFFER[N+I]);
  (x);
end;

% 05003: skip the unread tail of a record.
procedure ПPOПЗAП(var BUFFER: pairs);
begin
  SETPOS(ФOM, POSITION(ФOM) + BUFFER[0].count - 1);
end;

% 05016: save input pairs in the temporary file, return its first index.
function ПEPEKYБ(ЧИCЛOCЛO: integer): integer;
var I: integer;
    V: pair;
begin
  I := NUMOBJS(KYБA) + 1;
  ПEPEKYБ := ;
  SETPOS(KYБA, I);
  (q) for I to ЧИCЛOCЛO do (r) begin
    READPAIR(ФOM, V);
    PUTTEMP(KYБA, V);
  end;
end;

% 05044: write N pairs to the current object stream.
procedure ЗAПBФOM(var BUFFER: pairs; L: integer);
var I, LAST: integer;
begin
  (x);
  LAST := L - 1;
  (*q*) for I := 0 to LAST do (r) WRITPAIR(ФOM, BUFFER[I]);
  (x);
end;

% 05066: calendar correction after February in a leap year.
function BИCOKOC(ГOД, MEC: integer): integer;
begin
  if (ГOД mod 4 = 0) and (MEC > 2) then BИCOKOC := 1
  else BИCOKOC := 0;
end;

% 05100: timestamp counts seconds since the beginning of 1981.
procedure ПEЧДATY(BPEMЯ: integer);
var CEKYHДЫ, CYTKИ, ЧИCЛO, MECЯЦ, ГOД: integer;
begin
  PADCHAR := '0';
  CYTKИ := BPEMЯ div 86400;
  CEKYHДЫ := BPEMЯ mod 86400;
  ГOД := CYTKИ div 365;
  CYTKИ := CYTKИ mod 365 - ГOД div 4;
  if CYTKИ < 0 then begin
    ГOД := ГOД - 1;
    CYTKИ := CYTKИ + 365;
  end;
  ГOД := ГOД + 81;
  MECЯЦ := CYTKИ div 31 + 2;
  if HAЧAЛOME[MECЯЦ] + BИCOKOC(ГOД, MECЯЦ) > CYTKИ then
    MECЯЦ := MECЯЦ - 1;
  ЧИCЛO := CYTKИ - HAЧAЛOME[MECЯЦ] - BИCOKOC(ГOД, MECЯЦ) + 1;
  write(ЧИCЛO:2, '.', MECЯЦ:2, '.', ГOД:2, ' ',
        CEKYHДЫ div 3600:2, ':', CEKYHДЫ div 60 mod 60:2);
  PADCHAR := ' ';
end;

% 05170: stamp an object with account, weekday and creation time.
procedure YЧET(REC: pobj);
var БYДA: dateparts;
    BPE: integer;
    ШИФP: bitset;
begin
  besm(0530010B); besm(04150011B);
  BPE := ;
  besm(0500100B); (q);
  ШИФP := ;
  GETDATE(БYДA);
  with REC@ do begin
    owner.account := ШИФP;
    calendar.weekday := БYДA[3];
    created.seconds :=
      BPE div 50 + (HAЧAЛOME[БYДA[1]] +
       ((БYДA[2]-81) * 365 + (БYДA[2]-81) div 4) +
       BИCOKOC(БYДA[2], БYДA[1]) + БYДA[0] - 1) * 86400;
  end;
end;

% Definition/reference pass of LINK1, beginning at 05232.
procedure CБOPOБЬE(CMOДTOФ: integer);
type
  namecode = packed record
    first6, second6, third6: alfa;
    high: uint15; indexed: boolean; index, low: uint16
  end;
var l4, l5: integer;
    HAЧMTOБ, ЧЗTOБ, HAЧMTAC, ЧЗTAC, HAЧMTCC, ЧЗTCC: integer;
    ЧЗTПPE, ЧЗTЭM, CTAC, CTACПPEД, CTACHOB, CTOБHOB, CTCCHOB: integer;
    I, ЧИCЛOCЛO, ЧИCЛOBЫP, ЧИCЛOATP, ЧИCЛOБAЗ: integer;
    ЭЛTAC: sectrec;
    YKTAC, QSEC: psect;
    DEFINITION: defrec;
    PD: pdef;
    REFERENCE: refrec;
    ЭЛTПPE: pref;
    ЭЛTЭM: pprefix;
    YKДИMTEK: pprefix;
    NAME: pprefix;
    ЗAП: record case integer of
      0: (data: pairs);
      1: (head: pair; code: namecode; pad: array [1..8] of integer)
    end;
    ЗAПЗAГ, ЗAПPAБ: pairs;
    TOЧHAДЛИ, HYЖHЫMET: boolean;

function UNPACKNM(var CODE: namecode; var FIRST: char): integer;
  fortran;

% 05276. Fatal object-file diagnostics return to the main abort label.
procedure OШMOД(HOMOШ: integer);
var HOBOПP, ПPEДOПP: defkind;
    YKTOБ: pdef;
    YKTOФПPE: pfile;

% 05232. Print the definition class, return its precedence.
function AHAЛИЗTO(YKTOБ: pdef; ПAДEЖ: boolean): defkind;
begin
  with YKTOБ@ do
    if c.entry then begin
      if ПAДEЖ then write("BXOДA") else write("BXOД");
      AHAЛИЗTO := entryval;
    end else begin
      if not c.resolved then begin
        write("BЫЧ."); AHAЛИЗTO := computed
      end
      else if c.scope <> 0 then begin
        write("ПEP."); AHAЛИЗTO := reloc
      end
      else begin write("AБC."); AHAЛИЗTO := absolute end;
      if ПAДEЖ then write("ЗHAЧEHИЯ") else write("ЗHAЧEHИE");
    end;
end;

begin
  OШИБKИBM(ref(TEKOФ));
  case HOMOШ of
    0: begin
      KOOPД(ЗAП.data[0].header.kind);
      writeln(" : HEДOПYCTИMЫЙ HOMEP ПPEФИKCA");
    end;
    1: begin
      KOOPД(ЗAП.data[0].header.kind);
      writeln(" : HEДOПYCTИMЫЙ HOMEP ЭЛ.MOДYЛЯ");
    end;
    3: begin
      write("ПOBTOPHOE OПPEДEЛEHИE ГЛOБAЛЬHOГO ");
      HOBOПP := AHAЛИЗTO(ref(DEFINITION), true);
      write(' '''); ПEЧИMЯOБ(NAME); writeln(''',');
      write("PAHEE OПPEДEЛEHHOГO B MOДYЛE ");
      TABREAD(TOБ, NAME@.defindex); YKTOБ := ;
      OBJREAD(TOФ, YKTOБ@.b.fileindex); YKTOФПPE := ;
      write(YKTOФПPE@.name@.text:1, ' KAK ');
      ПPEДOПP := AHAЛИЗTO(YKTOБ, false); writeln('.');
      if HOBOПP >= ПPEДOПP then begin
        NAME@.defindex := CTOБHOB; YKTOФПPE := ref(TEKOФ);
      end;
      writeln("ИCПOЛЬ-HO OПPEДEЛEHИE ИЗ MOДYЛЯ ",
              YKTOФПPE@.name@.text:1, '.');
      exit;
    end;
    4: writeln("ИCПOPЧEH OБ'EKTHЫЙ MOДYЛЬ - ",
               "OTCYTCTBYET ЗAПИCЬ ЗAГOЛOBKA");
    5: begin
      KOOPД(ЗAП.data[0].header.kind);
      writeln(" HAXOДИTCЯ HE HA CBOEM MECTE");
    end;
    6: begin
      KOOPД(ЗAП.data[0].header.kind);
      writeln(" : HEДOПYCTИMЫЙ TИП ЗAПИCИ");
    end;
    others: begin
      KOOPД(ЗAП.data[0].header.kind);
      writeln(" OШCИC=", HOMOШ:1, '!!!');
    end
  end;
  goto 9999;
end;

% 05472. Expand an indexed name and intern its dotted components.
function ПEPEBPИ(TИПOБ: integer; KBAHT: namecode): pprefix;
var HПPE, ДЛKBAHTA, HAЧYP, ЧYPИM, ДЛKBA, YPИM, I: integer;
    PEЗ: ordering;
    БYФИMЯ: array [1..24] of char;
    БYФИMЯOБ: namekey;
    BHYTPИMЯ: array [1..12] of pkey;
    YKДИM, YKГЛABA, YKПPEДOK: pprefix;
    YKYPИM: pkey;
    YKTOБ: pdef;
    YKTCC: pref;
    YKTAC: psect;
begin
  HПPE := KBAHT.index; ДЛKBAHTA := 0;
  if HПPE = 0 then YKДИM := HAЧAЛOДИ
  else begin
    if KBAHT.indexed then
      case TИПOБ of
        4,6: begin
          if HПPE > ЧЗTOБ then OШMOД(0);
          TABREAD(TOБ, HAЧMTOБ+HПPE-1); YKTOБ := ;
          YKДИM := YKTOБ@.a.name;
        end;
        8: begin
          if HПPE > ЧЗTCC then OШMOД(0);
          TABREAD(TCC, HAЧMTCC+HПPE-1); YKTCC := ;
          YKДИM := YKTCC@.name;
        end;
        3: begin
          if HПPE > ЧЗTПPE then OШMOД(0);
          TABGET(TПPE, HПPE-1, YKДИM);
        end;
        1: begin
          if HПPE > ЧЗTЭM then OШMOД(1);
          TABGET(TЭM, HПPE-1, YKДИM);
        end;
        2: begin
          if HПPE > ЧЗTAC then OШMOД(0);
          TABREAD(TAC, HAЧMTAC+HПPE-1); YKTAC := ;
          YKДИM := YKTAC@.name;
        end;
        others: OШMOД(2)
      end
    else begin
      if HПPE > ЧЗTПPE then OШMOД(0);
      TABGET(TПPE, HПPE-1, YKДИM);
    end;
    if KBAHT.first6[1] <> '.' then
      with YKДИM@ do begin
        ДЛKBAHTA := UNPACKKY(name@, БYФИMЯ[1]); YKДИM := next;
      end;
  end;
  ДЛKBAHTA := UNPACKNM(KBAHT, БYФИMЯ[ДЛKBAHTA+1]) + ДЛKBAHTA;
  if ДЛKBAHTA = 0 then begin ПEPEBPИ := ptr(0); exit end;
  HAЧYP := 1; ЧYPИM := ;
  (q) for I := 2 to ДЛKBAHTA do (r) begin
    ДЛKBA := I-HAЧYP;
    if (БYФИMЯ[I] <> '.') and (ДЛKBA <= 10) then begin
    end else begin
      PACKKEY(БYФИMЯ[HAЧYP], ДЛKBA, БYФИMЯOБ);
      BHYTPИMЯ[ЧYPИM] := BHECИИMЯ(БYФИMЯOБ);
      ЧYPИM := ЧYPИM+1; HAЧYP := I;
    end;
  end;
  PACKKEY(БYФИMЯ[HAЧYP], ДЛKBAHTA-HAЧYP+1, БYФИMЯOБ);
  BHYTPИMЯ[ЧYPИM] := BHECИИMЯ(БYФИMЯOБ);
  (q) for YPИM to ЧYPИM do (r) begin
    YKГЛABA := YKДИM; YKДИM := YKДИM@.children; YKYPИM :=
  BHYTPИMЯ[YPИM];
    (newnode) begin
    if YKДИM = ptr(0) then begin
      NEWKEY(ДИM); YKДИM := ;
      YKГЛABA@.children := YKДИM;
    end else begin
      (search) repeat
        YKПPEДOK := YKДИM;
        with YKДИM@ do
        PEЗ := CMPNAME(YKYPИM@.text, name@);
        case PEЗ of
          PB: exit search;
          БЛ: YKДИM := YKДИM@.right;
          MH: YKДИM := YKДИM@.left
        end;
      until YKДИM = ptr(0);
      if PEЗ = PB then exit newnode;
      NEWKEY(ДИM); YKДИM := ;
      with YKПPEДOK@ do
        if PEЗ = БЛ then right := YKДИM else left := YKДИM;
    end;
    YKДИM@ := [0C, 0C];
    with YKДИM@ do begin next := YKГЛABA; name := YKYPИM end;
    end;
  end;
  ПEPEBPИ := YKДИM;
  if (TИПOБ = 6) or (TИПOБ = 4) then
    with YKДИM@ do begin kind := TИПOБ; hidden := not HYЖHЫMET end;
end;

% 06063, 06101, 06121. Initialize the next table record and index.
procedure HOBЭЛTOБ;
begin
  CTOБHOB := NUMOBJS(TOБ)+1;
  if ЧЗTOБ = 0 then HAЧMTOБ := CTOБHOB;
  ЧЗTOБ := ЧЗTOБ+1; DEFINITION := [0C, 0C, 0C];
end;

procedure HOBЭЛTAC;
begin
  CTACHOB := NUMOBJS(TAC)+1;
  if ЧЗTAC = 0 then HAЧMTAC := CTACHOB;
  ЧЗTAC := ЧЗTAC+1; ЭЛTAC := [0C, 0C, 0C, 0C, 0C];
end;

procedure HOBЭЛTCC;
begin
  CTCCHOB := NUMOBJS(TCC)+1;
  if ЧЗTCC = 0 then HAЧMTCC := CTCCHOB;
  ЧЗTCC := ЧЗTCC+1; REFERENCE := [0C];
end;

% 06135, 06155, 06175, 06204. Preserve variable record tails.
procedure БAЗЫBKYБ(ЧИCЛOБAЗ: integer);
var I: integer;
begin
  if ЧИCЛOБAЗ <> 0 then begin
    DEFINITION.a.count := ЧИCЛOБAЗ; DEFINITION.a.first :=
  ПEPEKYБ(ЧИCЛOБAЗ);
  end;
end;

procedure ATPBKYБ(ЧИCЛOATP: integer);
var I: integer;
begin
  if ЧИCЛOATP <> 0 then begin
    DEFINITION.b.count := ЧИCЛOATP; DEFINITION.b.first :=
  ПEPEKYБ(ЧИCЛOATP);
  end;
end;

procedure KИHФBKYБ(ЧИCЛOCЛO: integer);
var I: integer;
begin
  if ЧИCЛOCЛO <> 0 then I := ПEPEKYБ(ЧИCЛOCЛO);
end;

procedure BЫPBKYБ(ДЛИHABЫP: integer);
var I: integer;
begin
  if ДЛИHABЫP <> 0 then begin
    DEFINITION.c.data.count := ДЛИHABЫP;
    DEFINITION.c.data.first := ПEPEKYБ(ДЛИHABЫP);
  end;
end;

% 06223. Bind a global definition to its namespace node.
function ИMЯBTOБ(CTOБHOB: integer; var KBAHT: namecode): pprefix;
begin
  NAME := ПEPEBPИ(6, KBAHT); ИMЯBTOБ := ;
  with NAME@ do
    if defindex <> 0 then OШMOД(3) else defindex := CTOБHOB;
end;

% 06247. Read the object stream and gather its table records.
begin
  OTKPOЙOФ(CMOДTOФ);
  HAЧMTAC := 0; HAЧMTCC := ; HAЧMTOБ := ; ЧЗTAC := ;
  ЧЗTCC := ; ЧЗTOБ := ; ЧЗTПPE := ; ЧЗTЭM := ;
  TOЧHAДЛИ := true; HYЖHЫMET := 1 in TEKOФ.flags;
  ДAЙЗAП(ЗAПЗAГ, 1);
  if (ЗAПЗAГ[0].header.kind <> 0) or
     (ЗAПЗAГ[0].signature.magic <> 11259375) then OШMOД(4);
  ДAЙЗAПИC(ЗAПЗAГ);
  (records) repeat
    ДAЙЗAП(ЗAП.data, 1);
    case ЗAП.data[0].header.kind of
      0: OШMOД(5);
      10: ПPOПЗAП(ЗAП.data);
      2: begin
        ДAЙЗAПИC(ЗAП.data); HOBЭЛTAC;
        ЭЛTAC.header := ЗAП.data[0];
        ЭЛTAC.links := ЗAП.data[3];
        ЭЛTAC.name := ПEPEBPИ(2, ЗAП.code);
        if ЗAП.data[0].numbers.entry <> 0 then begin
          if ЗAП.data[0].numbers.entry > ЧЗTЭM then OШMOД(1);
          TABGET(TЭM, ЗAП.data[0].numbers.entry-1, YKДИMTEK);
          ЭЛTAC.entry := YKДИMTEK;
        end else ЭЛTAC.entry := ptr(0);
        ЭЛTAC.fileindex := CMOДTOФ;
        CTAC := HAЧCTAC;
        repeat
          CTACПPEД := CTAC;
          TABREAD(TAC, CTAC); YKTAC := ;
          CTAC := YKTAC@.next;
        until (CTAC = HAЧCTAC) or (YKTAC@.name = ЭЛTAC.name);
        TABREAD(TAC, CTAC); QSEC := ;
        (q) while (QSEC@.name = ЭЛTAC.name) and (CTAC <> HAЧCTAC) do
          (r)
        begin
          CTACПPEД := CTAC; CTAC := YKTAC@.next; YKTAC := QSEC;
          TABREAD(TAC, CTAC); QSEC := ;
        end;
        ЭЛTAC.next := CTAC; ЭЛTAC.previous := CTACПPEД;
        YKTAC@.next := CTACHOB; QSEC@.previous := CTACHOB;
        PUTSECT(TAC, CTACHOB, ЭЛTAC);
      end;
      1: begin
        ДAЙЗAПИC(ЗAП.data);
        if ЧЗTЭM = 0 then INITVEC(1, 256, "T ЭMOД", TЭM);
        YKДИMTEK := ПEPEBPИ(1, ЗAП.code);
        ЧЗTЭM := ЧЗTЭM+1;
        TABPUT(TЭM, ЧЗTЭM-1, YKДИMTEK);
      end;
      3: begin
        ДAЙЗAПИC(ЗAП.data);
        if ЧЗTПPE = 0 then INITVEC(1, 512, "T ПPEФ", TПPE);
        ЭЛTЭM := ПEPEBPИ(3, ЗAП.code);
        ЧЗTПPE := ЧЗTПPE+1; TABPUT(TПPE, ЧЗTПPE-1, ЭЛTЭM);
      end;
      4: begin
        HOBЭЛTOБ;
        DEFINITION.c.entry := true; DEFINITION.c.resolved := true;
        DEFINITION.b.fileindex := CMOДTOФ;
        DEFINITION.a.tags := ЗAП.data[0].definition.tags;
        ЧИCЛOCЛO := ЗAП.data[0].numbers.count;
        ЧИCЛOБAЗ := ЗAП.data[0].header.prefcount;
        ЧИCЛOATP := ЗAП.data[0].header.datacount;
        if ЗAП.data[0].header.hasname then begin
          ДAЙTEЛЗA(ЗAП.data, 1, 2);
          DEFINITION.a.name := ИMЯBTOБ(CTOБHOB, ЗAП.code);
          ЧИCЛOCЛO := ЧИCЛOCЛO-2;
        end;
        ДAЙTEЛЗA(ЗAПPAБ, 0, 1);
        DEFINITION.c.scope := ЗAПPAБ[0].scopeword.count;
        DEFINITION.c.data.value := ЗAПPAБ[0].value.high;
        БAЗЫBKYБ(ЧИCЛOБAЗ); ATPBKYБ(ЧИCЛOATP);
        KИHФBKYБ(ЧИCЛOCЛO-ЧИCЛOБAЗ-ЧИCЛOATP-2);
        PUTDEF(TOБ, CTOБHOB, DEFINITION);
      end;
      5: ПPOПЗAП(ЗAП.data);
      6: begin
        HOBЭЛTOБ; DEFINITION.b.fileindex := CMOДTOФ;
        ЧИCЛOCЛO := ЗAП.data[0].numbers.count;
        ЧИCЛOBЫP := ЗAП.data[0].numbers.entry;
        ЧИCЛOATP := ЗAП.data[0].header.datacount;
        if ЗAП.data[0].header.hasname then begin
          ДAЙTEЛЗA(ЗAП.data, 1, 2);
          DEFINITION.a.name := ИMЯBTOБ(CTOБHOB, ЗAП.code);
          ЧИCЛOCЛO := ЧИCЛOCЛO-2;
        end;
        if ЧИCЛOBЫP <> 0 then BЫPBKYБ(ЧИCЛOBЫP)
        else begin
          DEFINITION.c.resolved := true; ЧИCЛOCЛO := ЧИCЛOCЛO-1;
          ДAЙTEЛЗA(ЗAПPAБ, 0, 1);
          DEFINITION.c.scope := ЗAПPAБ[0].scopeword.count;
          DEFINITION.c.data.value := ЗAПPAБ[0].value.high;
        end;
        ATPBKYБ(ЧИCЛOATP);
        KИHФBKYБ(ЧИCЛOCЛO-ЧИCЛOBЫP-ЧИCЛOATP-1);
        PUTDEF(TOБ, CTOБHOB, DEFINITION);
      end;
      7: ПPOПЗAП(ЗAП.data);
      8: begin
        ДAЙTEЛЗA(ЗAП.data, 1, 2); HOBЭЛTCC;
        REFERENCE.name := ПEPEBPИ(8, ЗAП.code);
        ЧИCЛOATP := ЗAП.data[0].numbers.count-3;
        if ЧИCЛOATP <> 0 then begin
          REFERENCE.count := ЧИCЛOATP;
          REFERENCE.first := ПEPEKYБ(ЧИCЛOATP);
        end;
        PUTREF(TCC, CTCCHOB, REFERENCE);
      end;
      9: begin TOЧHAДЛИ := false; exit records end;
      255: exit records;
      others: OШMOД(6)
    end;
  until false;
  TEKOФ.n1.firstsect := HAЧMTAC;
  TEKOФ.n1.nsects := ЧЗTAC;
  TEKOФ.n0.firstdef := HAЧMTOБ; TEKOФ.n0.ndefs := ЧЗTOБ;
  TEKOФ.n2.firstref := HAЧMTCC; TEKOФ.n2.nrefs := ЧЗTCC;
  if 0 in PEЖИMЫ then begin
    write(' ', TEKOФ.name@.text, ' [',
          TEKOФ.filedata.address:6 oct, '] ');
    ПEЧALF0(ЗAПЗAГ[2].firstcode.text);
    ПEЧALF0(ЗAПЗAГ[2].lastcode.text);
    ПEЧALF0(ЗAПЗAГ[3].firstcode.text);
    write(' .', ЗAПЗAГ[0].version.number:1);
    if TOЧHAДЛИ then write(' ') else write('*');
    ПEЧДЛФAЙ(NUMOBJS(ФOM)); write(' ');
    ПEЧДATY(ЗAПЗAГ[5].time.seconds);
    write(' ',
          shift(integer(bitset(ЗAПЗAГ[4].hi)*[0..31]), 24):6 hex,
          " ЭBM-",
          ЗAПЗAГ[5].date.weekday:1, '  ');
    ПEЧALF0(ЗAПЗAГ[1].firstcode.text);
    ПEЧALF0(ЗAПЗAГ[1].lastcode.text);
    writeln(ЧЗTAC:6, ЧЗTOБ:9, ЧЗTCC:8, ЧЗTЭM:5, ЧЗTПPE:5);
  end;
  if ЧЗTПPE <> 0 then CLOSE(TПPE);
  if ЧЗTЭM <> 0 then CLOSE(TЭM);
  ЗAKPOЙOФ(CMOДTOФ);
end;
% Reference resolution and section placement, from 07221.
function PAЗPEШИC(CTOФ: integer): boolean;
var HAЧTCC, ЧЗTCC, CTCC, CCЫЛTOБ, CHAЧHEP, CHEPA: integer;
    YKTOФ: pfile;
    YKTCC, YKTCCП: pref;
    SPARE14, LIMIT: integer;
begin
  OBJEDIT(TOФ, CTOФ); YKTOФ := ;
  with YKTOФ@ do begin HAЧMTCC := n2.firstref; ЧЗTCC := n2.nrefs end;
  PAЗPEШИC := true; CHAЧHEP := 0; CHEPA := ;
  (x);
  LIMIT := HAЧMTCC+ЧЗTCC-1;
  (q) for CTCC := HAЧMTCC to LIMIT do (r) begin
    FILEEDIT(TCC, CTCC); YKTCC := ;
    with YKTCC@ do CCЫЛTOБ := name@.defindex;
    if CCЫЛTOБ = 0 then begin
      PAЗPEШИЛ := false; PAЗPEШИC := ;
      if CHEPA = 0 then CHAЧHEP := CTCC
      else begin
        FILEEDIT(TCC, CHEPA); YKTCCП := ; YKTCCП@.link := CTCC;
      end;
      CHEPA := CTCC;
    end else begin YKTCC@.resolved := true; YKTCC@.link := CCЫЛTOБ end;
  end;
  YKTOФ@.unresolved.first := CHAЧHEP;
end;

% 07316. Print the unresolved-reference chain, wrapping at column 128.
procedure TAБHEPAC(CTOФ: integer);
var CHEPA, ЗAHЯЛ, ДЛИHAИM: integer;
    YKTOФ: pfile;
    YKTCC: pref;
    ПEPBOE: boolean;
begin
  TABREAD(TOФ, CTOФ); YKTOФ := ;
  with YKTOФ@ do begin
    CHEPA := unresolved.first;
    write("MOДYЛЬ ", name@.text, ' : ');
  end;
  ЗAHЯЛ := 18; ПEPBOE := true;
  (q) while CHEPA <> 0 do (r) begin
    TABREAD(TCC, CHEPA); YKTCC := ;
    with YKTCC@ do ДЛИHAИM := ДЛИПOЛИM(YKTCC@.name)+2;
    if ЗAHЯЛ+ДЛИHAИM > 128 then begin
      writeln; write(' ':20); ЗAHЯЛ := 18; ПEPBOE := true;
    end;
    if not ПEPBOE then write(', ') else ПEPBOE := false;
    ПEЧИMЯOБ(YKTCC@.name);
    ЗAHЯЛ := ЗAHЯЛ+ДЛИHAИM; CHEPA := YKTCC@.link;
  end;
  writeln;
end;

% 07403. Round START upward to a multiple of 2**POWER.
function BЫPABAДP(AДPEC, ГPAHЬ: integer): integer;
var M, P: integer;
begin
  P := trunc(exp(ГPAHЬ * 0.69314718056));
  M := AДPEC+P-1; BЫPABAДP := M-M mod P;
end;

% 07516. Append compatible section records or overlap equal-sized ones.
procedure HACTPOЙH(YKTAC: psect);
var HACEK: integer;

% 07444. Fatal section-joining diagnostics.
procedure OШCOПP(HOMOШ: integer);

% 07420. Identify a section and its originating module.
procedure SECTID(REC: psect);
var RESERVED: integer;
    F: pfile;
begin
  with REC@ do begin
    ПEЧИMЯOБ(name); write(' (');
    TABREAD(TOФ, fileindex); F := ;
    write(F@.name@.text, ')');
  end;
end;

begin
  writeln("* * *  OШИБKA ПPИ ", "COПPЯЖEHИИ CEKЦИЙ   * * *");
  case HOMOШ of
    0: begin
      write("HECOBMECTИMЫE ATPИБYTЫ CEKЦИЙ ");
      SECTID(YKTAC); write(" И "); SECTID(ref(ЭЛTACП));
    end;
    1: begin
      write("HECOOTBETCTBИE ДЛИH CEKЦИЙ ");
      SECTID(YKTAC); write(" И "); SECTID(ref(ЭЛTACП));
    end;
    2: begin
      write("ЗAПPEЩEHHЫЙ ATPИБYT CEKЦИИ "); SECTID(YKTAC);
    end;
    3: begin
      write("HEДOПYCTИMЫЙ ATPИБYT CEKЦИИ "); SECTID(YKTAC);
    end
  end;
  writeln; goto 9999;
end;

begin
  with YKTAC@ do begin
    if length = 0 then exit;
    if name = ЭЛTACП.name then begin
      if (space <> ЭЛTACП.space) or
         (alignment <> ЭЛTACП.alignment) or
         (join <> ЭЛTACП.join) or
         (rights <> ЭЛTACП.rights) then OШCOПP(0);
      case join of
        jmoverlap: begin
          if length <> ЭЛTACП.length then OШCOПP(1);
          YKTAC@.base := ЭЛTACП.base; offset := ЭЛTACП.offset;
        end;
        jmconcat: begin
          HACEK := BЫPABAДP(CЧAC, alignment);
          CЧAC := length+HACEK; YKTAC@.base := HACEK;
          offset := HACEK;
        end;
        jmforbid: OШCOПP(2);
        others: OШCOПP(3)
      end;
    end else begin
      HACEK := BЫPABAДP(CЧAC, alignment);
      CЧAC := length+HACEK;
      YKTAC@.base := HACEK; offset := HACEK;
      ЭЛTACП := YKTAC@;
    end;
  end;
end;

% 07661. Qualified section/elementary-module name, padded to 17 columns.
procedure ПEЧИMЯCE(YKTAC: psect);
var ЗAHЯЛ: integer;
begin
  with YKTAC@ do begin
    ЗAHЯЛ := ДЛИПOЛИM(YKTAC@.name); ПEЧИMЯOБ(YKTAC@.name);
    if entry <> ptr(0) then begin
      ЗAHЯЛ := ДЛИПOЛИM(entry)+ЗAHЯЛ+1;
      write('.'); ПEЧИMЯOБ(entry);
    end;
    if ЗAHЯЛ > 17 then begin writeln; write(' ':17) end
    else if ЗAHЯЛ < 17 then write(' ':17-ЗAHЯЛ);
  end;
end;

% 07722. List a placed section and its storage/protection attributes.
procedure ПEЧCEKЦИ(YKTAC: psect);
var YKTOФ: pfile;
begin
  with YKTAC@ do begin
    if length = 0 then exit;
    ПEЧИMЯCE(YKTAC); write(' ');
    TABREAD(TOФ, fileindex); YKTOФ := ;
    write(YKTOФ@.name@.text, ' ', base:9 oct, ' ',
          length+base-1:9 oct, ' ', length:9 oct);
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

% 10146. Introduce a global object name or a local object number.
procedure ПEЧИMЯЛO(ИMЯ: pprefix);
begin
  if ИMЯ <> ptr(0) then begin
    write("ГЛOБAЛЬHЫЙ OБ'EKT "); ПEЧИMЯOБ(ИMЯ);
  end else write("ЛOKAЛЬHЫЙ OБ'EKT N", ИHДEKCTO:1);
end;
% Expression evaluator and its nested helpers, 10162-13633.
function MAШИHA(ФЛATEP: boolean): boolean;
label 100, 200;
type
  stackval = packed record case integer of
    0: (word: integer); 1: (bits: bitset);
    2: (halves: packed record high, low: uint24 end);
    3: (index: packed record high: uint32; low: uint16 end)
  end;
  opcodeval = packed record case integer of
    0: (word: integer);
    1: (fields: packed record high: set of 0..39; final: 0..1;
          group: 0..7; low: uint4 end);
    2: (low7: packed record high: set of 0..40; value: 0..127 end)
  end;
  cmdword = packed record case integer of
    0: (word: integer); 1: (bits: bitset);
    2: (data: packed record high: uint8;
              value: uint24; low: uint16 end);
    3: (longinst: packed record high: uint8; reg: uint4;
          longform: boolean; opcode: uint4;
          address: uint15; low: uint16 end);
    4: (shortins: packed record high: uint8; reg: uint4;
          longform, negative: boolean; opcode: uint6;
          address: 0..4095; low: uint16 end);
    5: (instr: packed record high: uint8; code: 0..4095;
               low: 0..1777777777B end);
    6: (count: packed record high: uint32;
               low: uint16 end);
    7: (header: packed record high: uint16; kind, length: uint8;
                low: uint16 end)
  end;
  cmdpair = record left, right: cmdword end;
var CTEK: array [1..12] of stackval;
    YKACT, REFNO, CTOБ, CTAC, CЧБYФOП, PAДP, ГЛEB,
    ГПPAB, BITCOUNT: integer;
    LOOKOK: boolean;
    SPARE27: integer;
    YKTAC: psect;
    DEF: pdef;
    REFERENCE: pref;
    TEKOП: opcodeval;
    CЛEДOП, ЛOKTEГИ: integer;
    ЛPEГOБ: evalform;
    ПOЛYOПEP: integer;
    BYTEPAIR, WORDPAIR: pair;
    БYФTEKCT: cmdpair;
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

% 10162. Diagnostic dump of the twelve-word operand stack.
procedure DUMPCTEK;
var I: integer;
begin
  write('CTEK');
  (q) for I to YKACT do (r) write(' ', I:1, ' = ', CTEK[I].word:16 oct);
  writeln;
end;

% 10203. Fatal expression/relocation diagnostics.
procedure OШMAШ(HOMOШ: integer);
begin
  OШИБKИBM(ref(TEKOФ));
  case HOMOШ of
    0: writeln("ПPEBЫШEHA ДЛИHA CEГMEHTA");
    1: writeln("ИCЧEPПAHЫ OПEPAЦИИ B BЫPAЖEHИИ");
    17: writeln(
      "AДPECHAЯ ЧATЬ KOMAHДЫ BHE ДOПYCTИMOГO ДИAПAЗOHA");
    2: writeln(
      "HEДOПYCTИMЫЙ AДPEC B KOMAHДE ", "BTOPOЙ CTPYKTYPЫ");
    3: writeln(
      "HEДOПYCTИMЫЙ AДPEC B KOMAHДE ", "ПEPBOЙ CTPYKTYPЫ");
    4: writeln("HEДOПYCTИMЫЙ HOMEP CEKЦИИ");
    5: writeln("CTEK OПEPAHДOB ПYCT");
    6: writeln("B KOHЦE BЫPAЖEHИЯ CTEK HE ПYCT");
    7: writeln("ИCЧEPПAHЫ OПEPAHДЫ B OПEPATOPE");
    8: writeln("HEBEPHЫЙ KOП ПФ-KOMAHДЫ");
    9: writeln("HEPEAЛИЗOBAHHAЯ MИKPOOПEPAЦИЯ ", TEKOП.word:2 hex);
    10: writeln("HEДOПYCTИMAЯ MИKPOOПEPAЦИЯ ", TEKOП.word:2 hex);
    11: writeln(
      "HEBEPHOE ИCПOЛЬЗOBAHИE MИKPOOПEPAЦИИ ", TEKOП.word:2 hex);
    12: writeln("HEBEPHAЯ CCЫЛKA HA BHEШHИЙ OБ'EKT : ", REFNO:0,
                ' (MAX=', KOHMTCC:0, ')');
    13: writeln("HEBEPHЫЙ HOMEP OБ'EKTA : ", CTOБ:0,
                ' (MAX=', KOHMTOБ:0, ')');
    15: writeln("HEДOПYCTИMЫE ГPAHИЦЫ ПOЛЯ : ", 48+ГПPAB:1,
                '..', BITCOUNT+ГПPAB+1:1);
    16: writeln("HEBEPHЫЙ HOMEP ATPИБYTA : ", I:0);
    others: writeln("OШCИC=", HOMOШ:1, '!!!')
  end;
  if ФЛATEP then begin
    write("CEKЦИЯ "); ПEЧИMЯOБ(ИMЯTEKCE);
    write(' : ', CЧAC:9 oct, ', '); KOOPД(10);
  end else ПEЧИMЯЛO(ИMЯTEKCE);
  writeln; goto 9999;
end;

% 10432. Store a packed output pair and advance its word address.
procedure CЛOBOBPA;
begin
  if CPAЗД >= CЧAKCEГM then OШMAШ(0);
  PUTPAIR(PAЗД, CPAЗД, CЛOBO);
  CPAЗД := CPAЗД+1; CЧAC := CЧAC+1;
end;

% 10447. Pack successive 24-bit values into the output pair.
procedure ЗAПBPAЗД(ПCЛ: integer);
begin
  if ФПPABC then begin
    CЛOBO.hi := integer(bitset(CЛOBO.hi)+bitset(ПCЛ)*[24..31]);
    CЛOBO.lo := shift(ПCЛ, -32);
  end else CЛOBO.hi := shift(ПCЛ, -24);
  if ФПPABC then begin CЛOBOBPA; ФПPABC := false end
  else begin
    CЛOBO.packedout.tag := shift(ЛOKTEГИ, 43); ФПPABC := true;
  end;
end;

% 10473. Expand four bytes from each half of each two-word input record.
% Refill up to 128 bytes, or stop at the end of the expression stream.
% UNPCK stores six characters: the extra two overlap the next group.
% Its final two stores reach LOOP172/LOOP173, just as in the image.
function ДAЙMИKPO: integer;
begin
  if CЧБYФOП > 128 then begin
    if CBЫP >= CKOHBЫP then OШMAШ(1);
    CЧБYФOП := 1;
    repeat
      if ФЛATEP then GETPAIR(ФOM, CBЫP, BYTEPAIR)
      else TABPAIR(KYБA, CBЫP, BYTEPAIR);
      CBЫP := CBЫP+1;
      unpck(BYTES[CЧБYФOП], BYTEPAIR.first6);
      CЧБYФOП := CЧБYФOП+4;
      unpck(BYTES[CЧБYФOП], BYTEPAIR.last6);
      CЧБYФOП := CЧБYФOП+4;
      (x);
    until (CЧБYФOП > 128) or (CBЫP = CKOHBЫP);
    CЧБYФOП := 1;
  end;
  ДAЙMИKPO := ord(BYTES[CЧБYФOП]); CЧБYФOП := CЧБYФOП+1;
end;

% 10542. Read alternate 24-bit values in the high 32 bits of two words.
function ДAЙOПEP: integer;
begin
  if ПOЛYOПEP = 0C then begin
    if CTEKCT >= CKOHTEK then OШMAШ(7);
    GETPAIR(ФOM, CTEKCT, WORDPAIR); CTEKCT := CTEKCT+1;
    ДAЙOПEP := WORDPAIR.data0.value;
    ПOЛYOПEP := 1C;
  end else begin
    ДAЙOПEP := WORDPAIR.data1.value;
    ПOЛYOПEP := 0C;
  end;
end;

% 10571. Push N big-endian bytes, right aligned in a stack word.
procedure БAЙTЫBCT(ЧБ: integer);
var I: integer;
begin
  YKACT := YKACT+1; CTEK[YKACT] := [0C];
  with CTEK[YKACT] do
    (q) for I := 7-ЧБ to 6 do (r)
      bits := bitset(shift(word, -8))+bitset(chr(ДAЙMИKPO));
end;

% 10614. Convert the current value to an integer, add the section delta,
% and convert it back with the original external value service.
procedure ДEЛЬTAC(HOMCEK: integer);
var YKTAC: psect;
begin
  HOMCEK := HOMCEK+HAЧMTAC-1;
  if HOMCEK >= KOHMTAC then OШMAШ(4);
  TABREAD(TAC, HOMCEK); YKTAC := ;
  with YKTAC@ do
    PACKVAL(UNPACKVL(CTEK[YKACT])+(base-high2), CTEK[YKACT]);
end;

% 10645. Push the resolved address of a definition, reduced to 15 bits.
function ЗHAЧCOБ(CTOБ: integer): boolean;
begin
  CTOБ := CTOБ+HAЧMTOБ-1;
  if CTOБ >= KOHMTOБ then OШMAШ(13);
  FILEEDIT(TOБ, CTOБ); DEF := ; YKACT := YKACT+1;
  with DEF@ do
    if c.ready then begin
      ЗHAЧCOБ := true;
      CTEK[YKACT].word := c.data.value mod 100000B;
      PACKVAL(CTEK[YKACT].word, CTEK[YKACT]); DEF@.c.used := true;
    end else ЗHAЧCOБ := false;
end;

% 10706. Push zero for reference zero, or use its bound definition.
% As in the image, an early exit does not assign the Boolean result.
function ЗHAЧBHEШ(CTCC: integer): boolean;
begin
  YKACT := YKACT+1; CTEK[YKACT] := [0C];
  if CTCC = 0 then exit;
  CTCC := CTCC+HAЧMTCC-1;
  if CTCC >= KOHMTCC then OШMAШ(12);
  FILEEDIT(TCC, CTCC); REFERENCE := ;
  with REFERENCE@ do begin
    used := true;
    if not resolved then exit;
    FILEEDIT(TOБ, link); DEF := ;
  end;
  with DEF@ do
    if c.ready then begin
      ЗHAЧBHEШ := true;
      CTEK[YKACT].word := c.data.value mod 100000B;
      PACKVAL(CTEK[YKACT].word, CTEK[YKACT]); DEF@.c.used := true;
    end else ЗHAЧBHEШ := false;
end;

% 10771. Push a 48-bit attribute from saved definition pair records.
function ATPCOБ(CTOБ, CЛOBOATP: integer): boolean;
var CKYБA: integer;
begin
  CTOБ := CTOБ+HAЧMTOБ-1;
  if CTOБ >= KOHMTOБ then OШMAШ(13);
  FILEEDIT(TOБ, CTOБ); DEF := ;
  with DEF@ do
    if c.ready then begin
      ATPCOБ := true;
      if CЛOBOATP >= b.count then OШMAШ(16);
      CKYБA := b.first+CЛOBOATP; c.used := true;
    end else begin ATPCOБ := false; exit end;
  TABPAIR(KYБA, CKYБA, TEMPPAIR); YKACT := YKACT+1;
  CTEK[YKACT].bits := bitset(chr(TEMPPAIR.data1.value));
  CTEK[YKACT].bits := CTEK[YKACT].bits+
                    bitset(shift(TEMPPAIR.data0.value, -24));
end;

% 11050. Corresponding attribute lookup through the reference table.
% Zero/unbound references retain the original unassigned-result exits.
function ATPBHEШ(CTCC, CЛOBOATP: integer): boolean;
var CKYБA: integer;
begin
  YKACT := YKACT+1; CTEK[YKACT] := [0C];
  if CTCC = 0 then exit;
  CTCC := CTCC+HAЧMTCC-1;
  if CTCC >= KOHMTCC then OШMAШ(12);
  FILEEDIT(TCC, CTCC); REFERENCE := ;
  with REFERENCE@ do begin
    used := true;
    if not resolved then exit;
    FILEEDIT(TOБ, link); DEF := ;
  end;
  with DEF@ do
    if c.ready then begin
      ATPBHEШ := true;
      if CЛOBOATP >= b.count then OШMAШ(16);
      CKYБA := b.first+CЛOBOATP; c.used := true;
    end else begin ATPBHEШ := false; exit end;
  TABPAIR(KYБA, CKYБA, TEMPPAIR);
  CTEK[YKACT].bits := bitset(chr(TEMPPAIR.data1.value));
  CTEK[YKACT].bits := CTEK[YKACT].bits+
                    bitset(shift(TEMPPAIR.data0.value, -24));
end;

% 11152. Consume exactly N stack values and emit the requested form.
procedure ЗABEPШИO(ГЛYБИHA: integer);
var PAДP, OCT: integer;
begin
  if YKACT-ГЛYБИHA < 0 then OШMAШ(5)
  else if YKACT-ГЛYБИHA > 0 then OШMAШ(6);
  (q) for YKACT := YKACT downto 1 do (r)
    case ЛPEГOБ of
      POБK, POБПФK: begin
        PAДP := UNPACKVL(CTEK[YKACT]);
        if (PAДP < -100000B) or (PAДP >= 100000B) then OШMAШ(17);
        PAДP := (PAДP+100000B) mod 100000B;
        if ЛPEГOБ = POБПФK then begin
          OCT := PAДP mod 100000B; PAДP := PAДP-OCT;
        end;
        if not БYФTEKCT.left.longinst.longform then begin
          if PAДP >= 70000B then begin
            БYФTEKCT.left.shortins.negative := true;
            PAДP := PAДP-70000B;
          end;
          if PAДP >= 4096 then OШMAШ(3);
        end;
        if ЛPEГOБ = POБПФK then begin
          БYФTEKCT.right.bits := БYФTEKCT.right.bits+
                                bitset(shift(OCT, -16));
          ЗAПBPAЗД(БYФTEKCT.right.data.value);
        end;
        БYФTEKCT.left.bits := БYФTEKCT.left.bits+
                             bitset(shift(PAДP, -16));
        ЗAПBPAЗД(БYФTEKCT.left.data.value);
      end;
      POБПCЛ: ЗAПBPAЗД(CTEK[YKACT].word);
      POБCЛ:
        if ФЛATEP then begin
          ЗAПBPAЗД(CTEK[YKACT].halves.high);
          ЗAПBPAЗД(CTEK[YKACT].halves.low);
        end else if YKACT = ГЛYБИHA then ЗHAЧOK := UNPACKVL(CTEK[YKACT])
        else begin
          TEMPPAIR.hi := shift(CTEK[YKACT].halves.high, -16);
          TEMPPAIR.lo := shift(CTEK[YKACT].word, -16);
          TABSAVE(KYБA, CTEKCT, TEMPPAIR); CTEKCT := CTEKCT+1;
        end;
      others: ;
    end;
end;

% 11317. Emit a saved operator block, binding its initial reference.
procedure CИCПPOГ;
var PAБOTA: integer;
    GOOD: boolean;
    LIMIT: integer;
begin
  БYФTEKCT.left.word := ДAЙOПEP;
  PAДP := БYФTEKCT.left.count.low;
  PAБOTA := БYФTEKCT.left.header.kind;
  ГЛEB := БYФTEKCT.left.header.length;
  БYФTEKCT.left.word := 0C; ЛPEГOБ := POБK;
  case PAБOTA of
    1, 3: begin
      GOOD := ЗHAЧCOБ(PAДP); БYФTEKCT.left.instr.code := 3528;
      ЗABEPШИO(1);
    end;
    2, 4: begin
      GOOD := ЗHAЧBHEШ(PAДP); БYФTEKCT.left.instr.code := 3528;
      ЗABEPШИO(1);
    end;
    5: begin БYФTEKCT.left.instr.code := 3520; ЗABEPШИO(1) end;
    others: ;
  end;
  LIMIT := ГЛEB-1;
  (*q*) for I to LIMIT do (r) ЗAПBPAЗД(ДAЙOПEP);
  (x);
end;

% 11413. Load an instruction address or raw operand into slot one.
procedure ГPYЗЧИK;
begin
  case ЛPEГOБ of
    POБK: begin
      БYФTEKCT.left.word := shift(ДAЙOПEP, -16);
      if БYФTEKCT.left.longinst.longform then begin
        CTEK[1].word := БYФTEKCT.left.longinst.address;
        БYФTEKCT.left.bits := БYФTEKCT.left.bits*
                            bitset(0017760000000000C);
      end else begin
        CTEK[1].word := БYФTEKCT.left.shortins.address;
        if БYФTEKCT.left.shortins.negative then
          CTEK[1].word := CTEK[1].word-4096;
        БYФTEKCT.left.bits := БYФTEKCT.left.bits*
                            bitset(0017776000000000C);
      end;
      PACKVAL(CTEK[1].word, CTEK[1]);
    end;
    POБПФK: begin
      БYФTEKCT.right.word := shift(ДAЙOПEP, -16);
      БYФTEKCT.left.word := shift(ДAЙOПEP, -16);
      if БYФTEKCT.right.longinst.longform then begin
        if БYФTEKCT.right.longinst.opcode = 2 then
          PAДP := БYФTEKCT.right.longinst.address
        else OШMAШ(8);
        БYФTEKCT.right.bits := БYФTEKCT.right.bits*
                             bitset(0017760000000000C);
      end else OШMAШ(8);
      if БYФTEKCT.left.longinst.longform then begin
        CTEK[1].word := БYФTEKCT.left.longinst.address+PAДP;
        БYФTEKCT.left.bits := БYФTEKCT.left.bits*
                            bitset(0017760000000000C);
      end else begin
        CTEK[1].word := БYФTEKCT.left.shortins.address+PAДP;
        if БYФTEKCT.left.shortins.negative then
          CTEK[1].word := CTEK[1].word-4096;
        БYФTEKCT.left.bits := БYФTEKCT.left.bits*
                            bitset(0017776000000000C);
      end;
      if CTEK[1].word >= 400000000B then
        CTEK[1].word := CTEK[1].word-100000B;
      PACKVAL(CTEK[1].word, CTEK[1]);
    end;
    POБПCЛ: CTEK[1].bits := bitset(chr(ДAЙOПEP));
    POБCЛ: begin
      CЛEДOП := ДAЙOПEP;
      CTEK[1].bits := bitset(chr(ДAЙOПEP));
% The code overwrites the low word here; retain it literally.
      CTEK[1].word := shift(CЛEДOП, -24);
    end;
    others: ;
  end;
  YKACT := 1;
end;

% 11552. Binary micro-operations. External names retain their addresses
% pending recovery of the value-arithmetic module itself.
procedure ГPYППA10(KOП: integer);
begin
  if YKACT < 2 then OШMAШ(5);
  YKACT := YKACT-1;
  case KOП of
    0: B23312(CTEK[YKACT], CTEK[YKACT+1], CTEK[YKACT]);
    1: B23330(CTEK[YKACT], CTEK[YKACT+1], CTEK[YKACT]);
    2: B23336(CTEK[YKACT], CTEK[YKACT+1], CTEK[YKACT]);
    3: B23347(CTEK[YKACT], CTEK[YKACT+1], CTEK[YKACT]);
    4: B23361(CTEK[YKACT], CTEK[YKACT+1], CTEK[YKACT]);
    5: B24130(CTEK[YKACT], CTEK[YKACT+1], CTEK[YKACT]);
    6: B23414(CTEK[YKACT], CTEK[YKACT+1], CTEK[YKACT]);
    7: B24127(CTEK[YKACT], CTEK[YKACT+1], CTEK[YKACT]);
    8: OШMAШ(9);
    others: OШMAШ(10)
  end;
end;

% 11724. Field operations, shifts and remaining unary micro-operations.
procedure ГPYППA20(KOП: integer);
begin
  case KOП of
    0: begin
      if YKACT < 3 then OШMAШ(5);
      B23525(CTEK[YKACT], CTEK[YKACT-1].word, CTEK[YKACT-2].word,
             CTEK[YKACT-2]);
      YKACT := YKACT-2;
    end;
    1: begin
      ГПPAB := ДAЙMИKPO; BITCOUNT := ДAЙMИKPO;
      B23525(CTEK[YKACT], ГПPAB, BITCOUNT, CTEK[YKACT]);
    end;
    2: begin
      if YKACT < 2 then OШMAШ(5);
      ГПPAB := ДAЙMИKPO; BITCOUNT := ДAЙMИKPO;
      B23525(CTEK[YKACT], ГПPAB, BITCOUNT, CTEK[YKACT]);
      B23414(CTEK[YKACT], CTEK[YKACT-1], CTEK[YKACT-1]); YKACT :=
  YKACT-1;
    end;
    3: begin
      ГПPAB := ДAЙMИKPO-48; BITCOUNT := ДAЙMИKPO-ГПPAB-1;
      if ГПPAB > 0 then OШMAШ(15)
      else if ГПPAB <> 0 then
        B23434(CTEK[YKACT], ГПPAB, CTEK[YKACT]);
      if BITCOUNT <> 0 then B23434(CTEK[YKACT], BITCOUNT, CTEK[YKACT]);
    end;
    4: B23375(CTEK[YKACT], CTEK[YKACT]);
    5: B24133(CTEK[YKACT], CTEK[YKACT]);
    6: B23434(CTEK[YKACT], 12, CTEK[YKACT]);
    7: CTEK[YKACT].word := B23423(CTEK[YKACT], 4095);
    others: OШMAШ(10)
  end;
end;

% 12131. Process a section stream, or one definition expression.
begin
  CЧБYФOП := 129;
  if ФЛATEP then begin
    CPAЗД := CЧAC-HAЗCEГM+CЧAДPAЗД; ПOЛYOПEP := 0C;
    if ФПPABC then begin
      GETPAIR(PAЗД, CPAЗД, CЛOBO); TEKOП.word := ДAЙOПEP;
    end;
  end else PEГOБ := POБCЛ;
  MAШИHA := true;
  repeat
    repeat TEKOП.word := ДAЙMИKPO until TEKOП.word <> 0;
    (x);
    ЛOKTEГИ := ГЛTEГИ; ЛPEГOБ := evalform(PEГOБ); YKACT := 0;
    if (TEKOП.word >= 130) and (TEKOП.word <= 143) then begin
      if ((TEKOП.fields.low in [7..9, 11..13]) and ФПPABC) or
         not ФЛATEP then OШMAШ(11);
      case TEKOП.fields.low of
        2: begin
          TEKOП.word := ДAЙMИKPO;
          ГЛTEГИ := integer(bitset(shift(TEKOП.word, -43))*[0..4]);
        end;
        3: CИCПPOГ;
        4: PEГOБ := POБK;
        5: PEГOБ := POБПФK;
        6: PEГOБ := POБПCЛ;
        7: PEГOБ := POБCЛ;
        8: begin
          if ДAЙMИKPO <> 0 then OШMAШ(9);
          GETPAIR(PAЗД, CPAЗД-1, CЛOBO);
          LOOP172 := ДAЙMИKPO;
          (q) for I := 0 to LOOP172 do (r) CЛOBOBPA;
        end;
        9: begin
          PAДP := ДAЙMИKPO*256; PAДP := (ДAЙMИKPO)+PAДP;
          if PAДP <> 0 then OШMAШ(9);
          GETPAIR(PAЗД, CPAЗД-1, CЛOBO);
          PAДP := ДAЙMИKPO*256; LOOP173 := (ДAЙMИKPO)+PAДP;
          (*q*) for I := 0 to LOOP173 do (r) CЛOBOBPA;
          (x);
        end;
        10: begin
          LOOP174 := ДAЙMИKPO;
          (q) for I := 0 to LOOP174 do (r) ЗAПBPAЗД(ДAЙOПEP);
        end;
        11: begin
          CЛOBO.hi := 0C; CЛOBO.lo := ;
          CЛOBO.packedout.tag := shift(ЛOKTEГИ, 43);
          LOOP175 := ДAЙMИKPO;
          (q) for I := 0 to LOOP175 do (r) CЛOBOBPA;
        end;
        12: begin
          CЛOBO.hi := 0C; CЛOBO.lo := ;
          CЛOBO.packedout.tag := shift(ЛOKTEГИ, 43);
          PAДP := ДAЙMИKPO*256; LOOP176 := (ДAЙMИKPO)+PAДP;
          (*q*) for I := 0 to LOOP176 do (r) CЛOBOBPA;
          (x);
        end;
        13: begin
          БYФTEKCT.left.data.value := ДAЙOПEP;
          LOOKOK := ЗHAЧBHEШ(БYФTEKCT.left.shortins.address);
          CЛOBO.hi := integer(
            bitset(shift(БYФTEKCT.left.instr.code, -36))+
            bitset(shift(CTEK[1].word, -16)));
          CЛOBO.packedout.tag := shift(ЛOKTEГИ, 43);
          I := ДAЙOПEP; CЛOBO.lo := 0C; CЛOBOBPA;
        end;
        14: OШMAШ(10);
        15: exit
      end;
      goto 100;
    end;
    if (TEKOП.low7.value >= 106) and
       (TEKOП.low7.value <= 108) then begin
      if not ФЛATEP then OШMAШ(11);
      200: case TEKOП.fields.low of
        10: begin
          if ФПPABC then OШMAШ(11);
          ЛOKTEГИ := integer(bitset(ЛOKTEГИ)-[1]);
        end;
        11: begin
          if ФПPABC then OШMAШ(11);
          CЛEДOП := ДAЙMИKPO;
          ЛOKTEГИ := integer(bitset(shift(CЛEДOП, -43))*[0..4]);
        end;
        12: ЛPEГOБ := POБПФK
      end;
      if TEKOП.fields.final = 1 then begin
        case ЛPEГOБ of
          POБK, POБПCЛ: ЗAПBPAЗД(ДAЙOПEP);
          POБПФK, POБCЛ: begin
            ЗAПBPAЗД(ДAЙOПEP); ЗAПBPAЗД(ДAЙOПEP)
          end;
          others: ;
        end;
        goto 100;
      end;
      TEKOП.word := ДAЙMИKPO;
      if (TEKOП.low7.value = 106) or (TEKOП.low7.value = 107) then
        goto 200;
    end;
    if ФЛATEP then ГPYЗЧИK;
    (expr) repeat
      case TEKOП.fields.group of
        0:
          if TEKOП.fields.final = 0 then
            case TEKOП.fields.low of
              0: ;
              1: БAЙTЫBCT(1);
              2: БAЙTЫBCT(2);
              3: БAЙTЫBCT(3);
              4: БAЙTЫBCT(4);
              5: БAЙTЫBCT(5);
              6: БAЙTЫBCT(6);
              7: OШMAШ(9);
              8: OШMAШ(9);
              9: begin
                YKACT := YKACT+1; CTEK[YKACT].word :=
  CTEK[YKACT-1].word;
              end;
              10: begin
                if YKACT < 2 then OШMAШ(5);
                CTEK[11].word := CTEK[YKACT-1].word;
                CTEK[YKACT-1].word := CTEK[YKACT].word;
                CTEK[YKACT].word := CTEK[11].word;
              end;
              11: begin
                if YKACT < 3 then OШMAШ(5);
                CTEK[12].word := CTEK[YKACT-2].word;
                CTEK[YKACT-2].word := CTEK[YKACT-1].word;
                CTEK[YKACT-1].word := CTEK[12].word;
              end;
              12: begin
                if YKACT < 3 then OШMAШ(5);
                CTEK[12].word := CTEK[YKACT-2].word;
                CTEK[11].word := CTEK[YKACT-1].word;
                CTEK[YKACT-2].word := CTEK[YKACT].word;
                CTEK[YKACT-1].word := CTEK[12].word;
                CTEK[YKACT].word := CTEK[11].word;
              end;
              13: begin
                if YKACT < 3 then OШMAШ(5);
                CTEK[12].word := CTEK[YKACT-2].word;
                CTEK[11].word := CTEK[YKACT-1].word;
                CTEK[YKACT-1].word := CTEK[YKACT].word;
                CTEK[YKACT-2].word := CTEK[11].word;
                CTEK[YKACT].word := CTEK[12].word;
              end;
              14: begin
                if YKACT < 3 then OШMAШ(5);
                CTEK[12].word := CTEK[YKACT-2].word;
                CTEK[YKACT-2].word := CTEK[YKACT].word;
                CTEK[YKACT].word := CTEK[12].word;
              end;
              15: OШMAШ(10)
            end
          else begin
            case TEKOП.fields.low of
              0: ЗABEPШИO(1);
              1: begin CЛEДOП := ДAЙMИKPO; ЗABEPШИO(CЛEДOП) end;
              others: OШMAШ(11)
            end;
            exit expr;
          end;
        1: ГPYППA10(TEKOП.fields.low);
        2: ГPYППA20(TEKOП.fields.low);
        3:
          case TEKOП.fields.low of
            0: if not ЗHAЧCOБ(ДAЙMИKPO) then begin
                 MAШИHA := false; exit
               end;
            1: begin
              PAДP := ДAЙMИKPO*256;
              if not ЗHAЧCOБ((ДAЙMИKPO)+PAДP) then begin
                MAШИHA := false; exit
              end;
            end;
            2: begin
              if YKACT < 1 then OШMAШ(5); YKACT := YKACT-1;
              if not ЗHAЧCOБ(CTEK[YKACT+1].index.low) then begin
                MAШИHA := false; exit
              end;
            end;
            3: OШMAШ(10);
            4: if not ЗHAЧBHEШ(ДAЙMИKPO) then begin
                 MAШИHA := false; exit
               end;
            5: begin
              PAДP := ДAЙMИKPO*256;
              if not ЗHAЧBHEШ((ДAЙMИKPO)+PAДP) then begin
                MAШИHA := false; exit
              end;
            end;
            6: begin
              if YKACT < 1 then OШMAШ(5); YKACT := YKACT-1;
              if not ЗHAЧBHEШ(CTEK[YKACT+1].index.low) then begin
                MAШИHA := false; exit
              end;
            end;
            7: OШMAШ(10);
            8: OШMAШ(9);
            9: OШMAШ(10);
            10: OШMAШ(9);
            11, 12, 13, 14, 15: OШMAШ(10)
          end;
        4:
          case TEKOП.fields.low of
            0: begin
              PAДP := ДAЙMИKPO; CTOБ := ДAЙMИKPO;
              if not ATPCOБ(CTOБ, PAДP) then begin
                MAШИHA := false; exit
              end;
            end;
            1: begin
              PAДP := ДAЙMИKPO; CTOБ := ДAЙMИKPO*256;
              if not ATPCOБ((ДAЙMИKPO)+CTOБ, PAДP) then begin
                MAШИHA := false; exit
              end;
            end;
            2: begin
              if YKACT < 1 then OШMAШ(5); YKACT := YKACT-1;
              if not ATPCOБ(CTEK[YKACT+1].index.low, ДAЙMИKPO) then
              begin MAШИHA := false; exit end;
            end;
            3: OШMAШ(10);
            4: begin
              PAДP := ДAЙMИKPO;
              if not ATPBHEШ(ДAЙMИKPO, PAДP) then begin
                MAШИHA := false; exit
              end;
            end;
            5: begin
              PAДP := ДAЙMИKPO; CTOБ := ДAЙMИKPO*256;
              if not ATPBHEШ((ДAЙMИKPO)+CTOБ, PAДP) then begin
                MAШИHA := false; exit
              end;
            end;
            6: begin
              if YKACT < 1 then OШMAШ(5); YKACT := YKACT-1;
              if not ATPBHEШ(CTEK[YKACT+1].index.low, ДAЙMИKPO) then
              begin MAШИHA := false; exit end;
            end;
            7: OШMAШ(10);
            8: begin
              if YKACT < 1 then OШMAШ(5); YKACT := YKACT-1;
              if not ATPCOБ(ДAЙMИKPO, CTEK[YKACT+1].index.low) then
              begin MAШИHA := false; exit end;
            end;
            9: begin
              if YKACT < 1 then OШMAШ(5); CTOБ := ДAЙMИKPO*256;
              YKACT := YKACT-1;
              if not ATPCOБ((ДAЙMИKPO)+CTOБ,
                            CTEK[YKACT+1].index.low) then
              begin MAШИHA := false; exit end;
            end;
            10: begin
              if YKACT < 2 then OШMAШ(5); YKACT := YKACT-2;
              if not ATPCOБ(CTEK[YKACT+2].index.low,
                            CTEK[YKACT+1].index.low) then
              begin MAШИHA := false; exit end;
            end;
            11: OШMAШ(10);
            12: begin
              if YKACT < 1 then OШMAШ(5); YKACT := YKACT-1;
              if not ATPBHEШ(ДAЙMИKPO, CTEK[YKACT+1].index.low) then
              begin MAШИHA := false; exit end;
            end;
            13: begin
              if YKACT < 1 then OШMAШ(5); CTOБ := ДAЙMИKPO*256;
              YKACT := YKACT-1;
              if not ATPBHEШ((ДAЙMИKPO)+CTOБ,
                            CTEK[YKACT+1].index.low) then
              begin MAШИHA := false; exit end;
            end;
            14: begin
              if YKACT < 2 then OШMAШ(5); YKACT := YKACT-2;
              if not ATPBHEШ(CTEK[YKACT+2].index.low,
                            CTEK[YKACT+1].index.low) then
              begin MAШИHA := false; exit end;
            end;
            15: OШMAШ(10)
          end;
        5: OШMAШ(10);
        6:
          case TEKOП.fields.low of
            0: begin
              if YKACT < 1 then OШMAШ(5);
              CTAC := CTEK[YKACT].index.low+HAЧMTAC-1;
              if CTAC >= KOHMTAC then OШMAШ(4);
              TABREAD(TAC, CTAC); YKTAC := ;
              CTEK[YKACT].word := YKTAC@.base mod 100000B;
              PACKVAL(CTEK[YKACT].word, CTEK[YKACT]);
            end;
            1: ДEЛЬTAC(1);
            2: ДEЛЬTAC(2);
            3: ДEЛЬTAC(3);
            4: ДEЛЬTAC(4);
            5: ДEЛЬTAC(5);
            6: ДEЛЬTAC(6);
            7: ДEЛЬTAC(7);
            8: begin CTAC := ДAЙMИKPO; ДEЛЬTAC(CTAC) end;
            9: begin
              CTAC := ДAЙMИKPO;
              CTAC := CTAC*8+(ДAЙMИKPO); ДEЛЬTAC(CTAC);
              (q);
            end;
            10, 11, 12: OШMAШ(11);
            13, 14, 15: OШMAШ(10)
          end;
        7: OШMAШ(10)
      end;
      if TEKOП.fields.final = 1 then begin ЗABEPШИO(1); exit expr end;
      TEKOП.word := ДAЙMИKPO;
    until false;
    if not ФЛATEP then exit;
    100: ;
  until false;
end;
% 13634-14112. Evaluate the definitions gathered from one input module.
% The return state records completed and pending work in this pass.
function BЫЧИCЛEH(CTOФ: integer): evalstate;
var ЧЗTOБ, CCЫЛTAC, ЧЗTAC: integer;
    YKTOБ: pdef;
    YKTAC: psect;
    STATE: evalstate;

% 13634. Fatal definition-value diagnostics.
procedure OШBЫЧ(HOMOШ: integer);
begin
  OШИБKИBM(ref(TEKOФ)); ПEЧИMЯЛO(ИMЯTEKCE);
  case HOMOШ of
    0: writeln(" - HEBEPHЫЙ HOMEP CEKЦИИ : ", CCЫЛTAC:1);
    1: writeln(" - AДPEC BHE ДOПYCTИMOГO ДИAПAЗOHA");
    others: ;
  end;
  goto 9999;
end;

begin
  TABFILE(TOФ, CTOФ, TEKOФ);
  with TEKOФ do begin
    HAЧMTOБ := n0.firstdef; ЧЗTOБ := n0.ndefs;
    KOHMTOБ := HAЧMTOБ+ЧЗTOБ;
    HAЧMTCC := n2.firstref; KOHMTCC := n2.nrefs+HAЧMTCC;
    HAЧMTAC := n1.firstsect; ЧЗTAC := n1.nsects;
    KOHMTAC := HAЧMTAC+ЧЗTAC;
  end;
  БЫЛИOШMO := false; STATE := evnone;
  (q) for ИHДEKCTO to ЧЗTOБ do (r) begin
    FILEEDIT(TOБ, HAЧMTOБ+ИHДEKCTO-1); YKTOБ := ;
    with YKTOБ@ do
      if not c.ready then begin
        ИMЯTEKCE := a.name;
        if c.resolved then begin
          CCЫЛTAC := c.scope;
          if CCЫЛTAC <> 0 then begin
            if CCЫЛTAC > ЧЗTAC then OШBЫЧ(0);
            CCЫЛTAC := HAЧMTAC+CCЫЛTAC-1; c.scope := ;
            TABREAD(TAC, CCЫЛTAC); YKTAC := ;
            with YKTAC@ do
              YKTOБ@.c.data.value :=
                YKTOБ@.c.data.value+(base-high2);
          end;
          YKTOБ@.c.ready := true;
          case STATE of
            evnone: STATE := evdone;
            evwait: STATE := evmixed;
          end;
        end else begin
          CBЫP := YKTOБ@.c.data.first;
          CKOHBЫP := YKTOБ@.c.data.count+CBЫP;
          CTEKCT := NUMOBJS(KYБA)+1; CKOHTEK := ;
          if not MAШИHA(false) then
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
            if (ЗHAЧOK < -100000B) or (ЗHAЧOK >= 100000B) then
              OШBЫЧ(1);
            YKTOБ@.c.data.value := ЗHAЧOK;
            YKTOБ@.c.resolved := true;
            YKTOБ@.c.ready := true;
            if CKOHTEK < CTEKCT then begin
              YKTOБ@.b.first := CKOHTEK;
% Retain the original signed difference in the five-bit field.
              YKTOБ@.b.count := CKOHTEK-CTEKCT;
            end;
          end;
        end;
      end;
  end;
  BЫЧИCЛEH := STATE;
end;
% 14113-14332. Evaluate section records in one input module.
procedure ЗAГPYЗИM(CMOДTOФ: integer);
var ЗAП: pairs;
    CTAC, ДЛBЫP, ДЛTEKCT: integer;
    YKTAC: psect;
    GOOD: boolean;

% 14113. Fatal section-output diagnostics.
procedure OШЗAГP(HOMOШ: integer);
begin
  OШИБKИBM(ref(TEKOФ)); KOOPД(ЗAП[0].header.kind);
  case HOMOШ of
    0: writeln(" : HEBEPHЫЙ HOMEP CEKЦИИ");
    1: writeln(" : HEДOПYCTИMЫЙ TИП ЗAПИCИ");
    others: writeln("OШCИC=", HOMOШ:1, '!!!')
  end;
  goto 9999;
end;

begin
  OTKPOЙOФ(CMOДTOФ);
  with TEKOФ do begin
    HAЧMTAC := n1.firstsect; KOHMTAC := n1.nsects+HAЧMTAC;
    HAЧMTCC := n2.firstref; KOHMTCC := n2.nrefs+HAЧMTCC;
    HAЧMTOБ := n0.firstdef; KOHMTOБ := n0.ndefs+HAЧMTOБ;
  end;
  (records) repeat
    ДAЙЗAП(ЗAП, 1);
    case ЗAП[0].header.kind of
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9: ПPOПЗAП(ЗAП);
      10: begin
% The section index is the following 16-bit field in the header word.
        CTAC := ЗAП[0].scopeword.count+HAЧMTAC-1;
        if CTAC >= KOHMTAC then OШЗAГP(0);
        OBJEDIT(TAC, CTAC); YKTAC := ;
        CBЫP := HAЧAЛOЗA+1;
        CTEKCT := ЗAП[0].numbers.entry+HAЧAЛOЗA+1; CKOHBЫP := ;
        CKOHTEK := ЗAП[0].numbers.count+HAЧAЛOЗA;
        with YKTAC@ do begin
          PEГOБ := state.mode;
          ГЛTEГИ := integer(bitset(shift(raw0, -19))*[0..4]);
          ФПPABC := state.half; CЧAC := offset; ИMЯTEKCE := name;
        end;
        GOOD := MAШИHA(true);
        with YKTAC@ do begin
          state.mode := PEГOБ; rights := bitset(ГЛTEГИ);
          state.half := ФПPABC; offset := CЧAC;
        end;
        if ФПPABC then PUTPAIR(PAЗД, CPAЗД, CЛOBO);
        SETPOS(ФOM, CKOHTEK);
      end;
      255: exit records;
      others: OШЗAГP(1)
    end;
  until false;
  ЗAKPOЙOФ(CMOДTOФ);
end;
% 14333-15043. Emit an object-format file describing the linked names.
procedure ГEHMETKИ;
type
  namecode = packed record
    first6, second6, third6: alfa;
    high: uint15; indexed: boolean; index, low: uint16
  end;
  LABELREC = record case integer of
       0: (data: pairs);
       1: (head: pair; code: namecode)
     end;
var ЗAПЗAГ, ЗAППPEФ, ЗAПЗHAЧ: LABELREC;
    YKTOБ: pdef;
    БYФИMЯ: namekey;
    TEMPPAIR: pair;
    ЧИCЛOATP, I: integer;

procedure KEYPAIR(var KEY: namekey; var RESULT: pair); fortran;
procedure KEYCODE(var KEY: namekey; var RESULT: namecode); fortran;
procedure GETTEMP(POOL: integer; var RESULT: pair); fortran;

% 14333. Traverse namespace children and their search trees.
procedure OБXOДЛEC(YЗEЛ: pprefix);
begin
  if YЗEЛ = ptr(0) then exit;
  with YЗEЛ@ do
    if (kind = 6) and not hidden then begin
      KEYCODE(name@.text, ЗAПЗHAЧ.code);
      ЗAПЗHAЧ.code.index := YЗEЛ@.next@.defindex;
      ЗAПЗHAЧ.code.indexed := YЗEЛ@.next@.kind = 6;
      if YЗEЛ@.defindex <> 0 then begin
        TABREAD(TOБ, YЗEЛ@.defindex); YKTOБ := ;
        with YKTOБ@ do begin
          ЗAПЗHAЧ.data[3].value.high := c.data.value;
          ЧИCЛOATP := b.count; ЗAПЗHAЧ.data[0].header.datacount := ;
          if ЧИCЛOATP <> 0 then begin
            ЗAПЗHAЧ.data[0].count := ЧИCЛOATP+4; SETPOS(KYБA, b.first);
          end else ЗAПЗHAЧ.data[0].count := 4;
        end;
        ЗAПBФOM(ЗAПЗHAЧ.data, 4);
        (q) for I to ЧИCЛOATP do (r) begin
          GETTEMP(KYБA, TEMPPAIR); WRITPAIR(ФOM, TEMPPAIR);
        end;
      end else begin
        ЗAПЗHAЧ.data[0].count := 4; ЗAПЗHAЧ.data[3].value.high := 0;
        ЗAПЗHAЧ.data[0].header.datacount := 0;
        ЗAПBФOM(ЗAПЗHAЧ.data, 4);
      end;
      YЗEЛ@.defindex := HOMEPOБЬ; HOMEPOБЬ := HOMEPOБЬ+1;
    end else if YЗEЛ@.children <> ptr(0) then begin
      KEYCODE(YЗEЛ@.name@.text, ЗAППPEФ.code);
      if YЗEЛ@.next <> HAЧAЛOДИ then begin
        ЗAППPEФ.code.index := YЗEЛ@.next@.defindex;
        ЗAППPEФ.code.indexed := true;
      end;
      ЗAПBФOM(ЗAППPEФ.data, 3);
      YЗEЛ@.defindex := HOMEPПPE; HOMEPПPE := HOMEPПPE+1;
    end;
  OБXOДЛEC(YЗEЛ@.children); OБXOДЛEC(YЗEЛ@.left); OБXOДЛEC(YЗEЛ@.right);
end;

begin
  ATTACH(2, ФAЙЛMET.attr.disk.address, ФAЙЛMET.attr.disk.length,
         ФAЙЛMET.name@.first6, ФOM);
  ЗAПЗAГ := [0C, 0C, 0C, 0C, 0C, 0C, 0C, 0C, 0C, 0C, 0C, 0C];
  ЗAПЗAГ.data[0].signature.kind := 0;
  ЗAПЗAГ.data[0].signature.magic := 11259375;
  ЗAПЗAГ.data[0].version.number := 2; ЗAПЗAГ.data[0].count := 6;
  БYФИMЯ := "KOMПOH-1  "; KEYPAIR(БYФИMЯ, ЗAПЗAГ.data[1]);
  KEYPAIR(ФAЙЛMET.name@.text, ЗAПЗAГ.data[2]);
  ЗAПЗAГ.data[3].firstcode.text := '    ';
  YЧET(ref(ЗAПЗAГ)); ЗAПBФOM(ЗAПЗAГ.data, 6);
  ЗAППPEФ := [0C, 0C, 0C, 0C, 0C, 0C];
  ЗAППPEФ.data[0].signature.kind := 3; ЗAППPEФ.data[0].count := 3;
  ЗAПЗHAЧ := [0C, 0C, 0C, 0C, 0C, 0C, 0C, 0C];
  ЗAПЗHAЧ.data[0].signature.kind := 6;
  ЗAПЗHAЧ.data[0].header.hasname := true;
  OБXOДЛEC(HAЧAЛOДИ@.children);
  ЗAППPEФ := [0C, 0C, 0C, 0C, 0C, 0C];
  ЗAППPEФ.data[0].signature.kind := 255; ЗAППPEФ.data[0].count := 1;
  ЗAПBФOM(ЗAППPEФ.data, 1);
% The remaining lines print the output-file summary.
  writeln(' ');
  write("ЗAПИCAH OБ'EKTHЫЙ MOДYЛЬ <");
  write(ФAЙЛMET.name@.text);
  writeln(">, COДEPЖAЩИЙ ГЛOБAЛЬHЫE OПPEДEЛEHИЯ");
  write("ФAЙЛ : ");
  write(ФAЙЛMET.name@.text, ' [', ФAЙЛMET.attr.disk.address:6 oct);
  write("], ДЛИHA : "); ПEЧДЛФAЙ(NUMOBJS(ФOM));
  writeln(", OБ'EKTOB : ", HOMEPOБЬ-1:1);
  CLOSE(ФOM);
end;
% 15044-15220. Convert saved cumulative stamps to per-phase timings.
procedure ПEЧCTATИ;
var BИД: metric;
    БYФCTAT: stamp;
    ЭTAП: stage;

procedure ГPYППABP(ЭTAП: stage);
begin
  (q) for BИД := ЦП to ACTP do (r) begin
    write(' '); ПEЧBPE(CTATЭTAП[ЭTAП][BИД]);
  end;
  writeln;
end;

begin
  БYФCTAT := CTATЭTAП[pred(TEKЭTAП)];
  (q) for ЭTAП := pred(TEKЭTAП) downto ШAГИHИЦ do (r)
    (q) for BИД := ЦП to ACTP do (r)
      CTATЭTAП[ЭTAП][BИД] :=
  CTATЭTAП[ЭTAП][BИД]-CTATЭTAП[pred(ЭTAП)][BИД];
  (q) for BИД := ЦП to ACTP do (r)
    CTATЭTAП[CYMMA][BИД] := БYФCTAT[BИД]-CTATЭTAП[CYMMA][BИД];
  writeln(' ');
  writeln("CTATИCTИKA ПO PAБOTE KOMПOHOBЩИKA":48);
  writeln(' ');
  write("ИHИЦИAЛИЗAЦИЯ ...................."); ГPYППABP(ШAГИHИЦ);
  write("PAЗБOP ЗAДAHИЯ ..................."); ГPYППABP(ШAГЗAДAH);
  if TEKЭTAП > ШAГCБOPK then begin
    write("CБOPKA OПPEДEЛEHИЙ И CCЫЛOK ......"); ГPYППABP(ШAГCБOPK);
  end;
  if TEKЭTAП > ШAГPAЗPE then begin
    write("PAЗPEШEHИE CCЫЛOK ................"); ГPYППABP(ШAГPAЗPE);
  end;
  if TEKЭTAП > ШAГPAЗME then begin
    write("PACПPEДEЛEHИE ПAMЯTИ ............."); ГPYППABP(ШAГPAЗME);
  end;
  if TEKЭTAП > ШAГBЫЧ then begin
    write("BЫЧИCЛEHИE ЗHAЧEHИЙ OБ'EKTOB ....."); ГPYППABP(ШAГBЫЧ);
  end;
  if TEKЭTAП > ШAГЗAГP then begin
    write("ЗAПИCЬ BЫПOЛHЯEMOГO PAЗДEЛA ......"); ГPYППABP(ШAГЗAГP);
  end;
  if TEKЭTAП > ШAГГEHME then begin
    write("ПOPOЖДEHИE ФAЙЛA METOK ..........."); ГPYППABP(ШAГГEHME);
  end;
  writeln('-------- -------- --------':61);
  write(' ':34); ГPYППABP(CYMMA);
end;
% Main linker driver; service sources are in linker-runtime.
procedure MEMINIT(PAGES, MODE, FLAGS: integer); assembler;
function MEMALLOC(SIZE: integer): phash; assembler;
procedure READNEXT(POOL: integer); fortran;
procedure NEWTAB(POOL: integer); fortran;

begin
  writeln("_014 -= KOMПOHOBЩИK ЭЛЬБPYC-Б : BEPCИЯ 2.40/1 =-");
  GETSTAMP(CTATЭTAП[CYMMA]);
  MEMINIT(32, 3, 0);
  AДEC := ord(MEMALLOC(512)); BEKXEШ := ;
  AДEC := AДEC+127+1; TИMEH := ;
  AДEC := AДEC+31+8; ДИM := ;
  AДEC := AДEC+31+8; TЛФ := ;
  AДEC := AДEC+0+8; TOФ := ;
  AДEC := AДEC+3+8; TCEГ := ;
  AДEC := AДEC+1+8; TOБ := ;
  AДEC := AДEC+96+8; TCC := ;
  AДEC := AДEC+63+8; TAC := ;
  AДEC := AДEC+7+8; TПPE := ;
  AДEC := AДEC+1+8; TЭM := ;
  AДEC := AДEC+0+8; KYБA := ;
  AДEC := AДEC+15+8; ФOM := ;
  AДEC := AДEC+8; PAЗД := ; AДEC := AДEC+8;
  AДEC := AДEC-ord(BEKXEШ);
  if AДEC > 512 then begin writeln('LDES=', AДEC:4 oct); halt end;
  INITVEC(2, 4095, " TИMEH", TИMEH);
  INITVEC(2, 4095, " ДИM  ", ДИM);
  INITVEC(2, 99, " TЛФ  ", TЛФ);
  INITVEC(4, 255, " TOФ  ", TOФ);
  INITVEC(1, 511, " TCEГ ", TCEГ);
  INITVEC(3, 8191, " TOБ  ", TOБ);
  INITVEC(1, 37777B, ' TCC  ', TCC);
  INITVEC(5, 399, ' TAC  ', TAC);
  INITVEC(2, 2047, " KYБA ", KYБA);
  (q) for I := 0 to 127 do (r) BEKXEШ@[I] := ptr(0);
  OBJEDIT(ДИM, 0); YKДИM := ; HAЧAЛOДИ := ;
  YKДИM@ := [0C, 0C];
  FILEEDIT(TOБ, 0); YKTOБ := ; YKTOБ@ := [0C, 0C, 0C];
  FILEEDIT(TCC, 0);
  ASSIGN("CИCBЫB    ", 1); ASSIGN("CИCBBOД   ", 2);
  CTATИCT(ШAГИHИЦ); PAЗБOPЗA; CTATИCT(ШAГЗAДAH);
  if 0 in PEЖИMЫ then begin
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
  SETPOS(TCEГ, 0);
  repeat
    HAЧCTAC := NUMOBJS(TAC)+1;
    NEWTAB(TAC); YKTAC := ; YKTAC@ := [0C, 0C, 0C, 0C, 0C];
    with YKTAC@ do begin next := HAЧCTAC; previous := HAЧCTAC end;
    OBJEDIT(TCEГ, POSITION(TCEГ)+1); YKTCEГ := ;
    YKTCEГ@.low := HAЧCTAC;
    (x); g0643 := YKTCEГ@.count;
    (q) for HMOД to g0643 do (r) begin
      READNEXT(TCEГ); YKTCEГ := ; CБOPOБЬE(YKTCEГ@.fileindex);
    end;
  until POSITION(TCEГ) > NUMOBJS(TCEГ);
  CTATИCT(ШAГCБOPK); SETPOS(TCEГ, 0);
  repeat
    OBJREAD(TCEГ, POSITION(TCEГ)+1); YKTCEГ := ;
    (x); g0644 := YKTCEГ@.count;
    (q) for HMOД to g0644 do (r) begin
      NEWKEY(TCEГ); YKTCEГ := ;
      with YKTCEГ@ do limit := PAЗPEШИC(YKTCEГ@.fileindex);
    end;
  until POSITION(TCEГ) > NUMOBJS(TCEГ);
  if not PAЗPEШИЛ then begin
    writeln(' ');
    writeln('  ---------------------------------------------');
    writeln("  !  H E P A З P E Ш E H H Ы E   C C Ы Л K И  !");
    writeln('  ---------------------------------------------');
    writeln(' ');
    SETPOS(TCEГ, 0);
    repeat
      OBJREAD(TCEГ, POSITION(TCEГ)+1); YKTCEГ := ;
      (x); g0645 := YKTCEГ@.count;
      (q) for HMOД to g0645 do (r) begin
        READNEXT(TCEГ); YKTCEГ := ;
        with YKTCEГ@ do if not limit then TAБHEPAC(fileindex);
      end;
    until POSITION(TCEГ) > NUMOBJS(TCEГ);
  end;
  CTATИCT(ШAГPAЗPE); SETPOS(TCEГ, 0);
  ЭЛTACП := [0C, 0C, 0C, 0C, 0C];
  repeat
    READNEXT(TCEГ); YKTCEГ := ;
    HAЗCEГM := YKTCEГ@.loadbase; CЧAC := ;
    READNEXT(TCEГ); YKTCEГ := ;
    with YKTCEГ@ do SETPOS(TCEГ, POSITION(TCEГ)+count);
    HAЧCTAC := YKTCEГ@.low;
    TABREAD(TAC, HAЧCTAC); YKTAC := ; CTAC := YKTAC@.next;
    (q) while CTAC <> HAЧCTAC do (r) begin
      FILEEDIT(TAC, CTAC); YKTAC := ; HACTPOЙH(YKTAC);
      CTAC := YKTAC@.next;
    end;
    TABREAD(TAC, CTAC); YKTAC := ;
    YKTAC@.length := CЧAC-HAЗCEГM;
  until POSITION(TCEГ) > NUMOBJS(TCEГ);
  if 1 in PEЖИMЫ then begin
    writeln('_014');
    writeln("CBEДEHИЯ O ПPOГPAMMHЫX CEKЦИЯX":60);
    writeln('------------------------------':60); writeln(' ');
    write("    ИMЯ CEKЦИИ      MOДYЛЬ    HAЧAЛO     KOHEЦ     ДЛИHA");
    writeln("   BЫPAB.     ATPИБYTЫ");
    write('    --- ------      ------    ------     -----     -----');
    writeln('   ------     --------');
    SETPOS(TCEГ, 1);
    repeat
      READNEXT(TCEГ); YKTCEГ := ;
      with YKTCEГ@ do SETPOS(TCEГ, POSITION(TCEГ)+count+1);
      HAЧCTAC := YKTCEГ@.low;
      TABREAD(TAC, HAЧCTAC); YKTAC := ; CTAC := YKTAC@.next;
      (q) while CTAC <> HAЧCTAC do (r) begin
        TABREAD(TAC, CTAC); YKTAC := ; ПEЧCEKЦИ(YKTAC);
        CTAC := YKTAC@.next;
      end;
    until POSITION(TCEГ) > NUMOBJS(TCEГ);
  end;
  CTATИCT(ШAГPAЗME);
  (values) repeat
    SETPOS(TCEГ, 0); BKЛЮЧEHO := true; g0122 := false;
    repeat
      OBJREAD(TCEГ, POSITION(TCEГ)+1); YKTCEГ := ;
      (x); g0646 := YKTCEГ@.count;
      (q) for HMOД to g0646 do (r) begin
        READNEXT(TCEГ); YKTCEГ := ;
        with YKTCEГ@ do
          if not flags.ready then begin
            g0642 := BЫЧИCЛEH(YKTCEГ@.fileindex);
            YKTCEГ@.flags.ready := g0642 in [evnone, evdone];
            g0122 := g0122 or (g0642 in [evdone, evmixed]);
            BKЛЮЧEHO := BKЛЮЧEHO and not (g0642 in [evmixed, evwait]);
          end;
      end;
    until POSITION(TCEГ) > NUMOBJS(TCEГ);
    if BKЛЮЧEHO then exit values;
    if not g0122 then begin
      SETPOS(TCEГ, 0);
      repeat
        OBJREAD(TCEГ, POSITION(TCEГ)+1); YKTCEГ := ;
        (x); g0647 := YKTCEГ@.count;
        (q) for HMOД to g0647 do (r) begin
          READNEXT(TCEГ); YKTCEГ := ;
          with YKTCEГ@ do
            if not flags.ready then begin
              TABFILE(TOФ, fileindex, TEKOФ);
              HAЧMTOБ := TEKOФ.n0.firstdef;
              g0073 := TEKOФ.n0.ndefs;
              (q) for ИHДEKCTO to g0073 do (r) begin
                TABREAD(TOБ, HAЧMTOБ+ИHДEKCTO-1); YKTOБ := ;
                with YKTOБ@ do
                  if not c.ready then begin
                    OШИБKИBM(ref(TEKOФ)); ПEЧИMЯЛO(a.name);
                    writeln(" - HEBOЗMOЖHO BЫЧИCЛИTЬ ЗHAЧEHИE");
                    goto 9999;
                  end;
              end;
            end;
        end;
      until POSITION(TCEГ) > NUMOBJS(TCEГ);
    end;
  until false;
  CTATИCT(ШAГBЫЧ);
  if 2 in PEЖИMЫ then begin
    writeln('_014');
    writeln("CBEДEHИЯ O CEГMEHTAX":38);
    writeln('-------- - ---------':38); writeln(' ');
    writeln(
"  ИMEHA CEKЦИЙ     HAЧAЛO     KOHEЦ   PAЗMEЩEHИE HA ДИCKE");
    writeln(
'  ----- ------     ------     -----   ---------- -- -----');
  end;
  ATTACH(2, ФAЙЛPAЗД.attr.disk.address, ФAЙЛPAЗД.attr.disk.length,
         ФAЙЛPAЗД.name@.first6, PAЗД);
  CЧAДPAЗД := 0; SETPOS(TCEГ, 0);
  repeat
    READNEXT(TCEГ); YKTCEГ := ;
    with YKTCEГ@ do begin g0064 := diskbase; HAЗCEГM := loadbase end;
    READNEXT(TCEГ); YKTCEГ := ;
    with YKTCEГ@ do begin
      if above then CЧAДPAЗД := CЧAДPAЗД+g0064 else CЧAДPAЗД := g0064;
      if not concatenate then begin
        ЗOHA := CЧAДPAЗД div 1024; AДBЗOHE := CЧAДPAЗД mod 1024;
        AЗBЗOHE := HAЗCEГM mod 1024;
        if AЗBЗOHE < AДBЗOHE then ЗOHA := ЗOHA+1;
        CЧAДPAЗД := ЗOHA*1024+AЗBЗOHE;
      end;
      HAЧCTAC := low; ЧИCЛOMOД := count; CЧAKCEГM := length+CЧAДPAЗД;
    end;
    (q) for HMOД to ЧИCЛOMOД do (r) begin
      READNEXT(TCEГ); YKTCEГ := ; ЗAГPYЗИM(YKTCEГ@.fileindex);
    end;
    TABREAD(TAC, HAЧCTAC); YKTAC := ;
    with YKTAC@ do begin CTAC := next; CЧAKCEГM := length+HAЗCEГM-1 end;
    AДBЗOHE := CЧAДPAЗД; CЧAДPAЗД := YKTAC@.length+CЧAДPAЗД;
    CЛOBO.hi := 7777777777777777C; CЛOBO.lo := ;
    PUTPAIR(PAЗД, CЧAДPAЗД, CЛOBO);
    if 2 in PEЖИMЫ then begin
      PAЗPEШИЛ := true;
      (q) while CTAC <> HAЧCTAC do (r) begin
        TABREAD(TAC, CTAC); YKTAC := ;
        with YKTAC@ do begin ИMЯTEKCE := name; CTAC := next end;
        ПEЧИMЯCE(YKTAC);
        if PAЗPEШИЛ then begin
          writeln(' ', HAЗCEГM:9 oct, ' ', CЧAKCEГM:9 oct, ' ',
            AДBЗOHE*2 div 1024:4 oct, ':', AДBЗOHE*2 mod 1024:4 oct,
  '-',
            CЧAДPAЗД*2 div 1024:4 oct, ':', CЧAДPAЗД*2 mod 1024:4 oct);
          PAЗPEШИЛ := false;
        end else writeln;
        TABREAD(TAC, CTAC); YKTAC := ;
        (q) while YKTAC@.name = ИMЯTEKCE do (r) begin
          CTAC := YKTAC@.next;
          TABREAD(TAC, CTAC); YKTAC := ;
        end;
      end;
    end;
  until POSITION(TCEГ) > NUMOBJS(TCEГ);
  writeln(' ');
  write("CИCTEMHЫЙ BЫПOЛHЯEMЫЙ PAЗДEЛ ЗAПИCAH B ФAЙЛ ");
  write(ФAЙЛPAЗД.name@.text, ' [', ФAЙЛPAЗД.attr.disk.address:6 oct);
  write("], ДЛИHA : "); ПEЧДЛФAЙ(CPAЗД); writeln;
  CLOSE(PAЗД); CTATИCT(ШAГЗAГP);
  if ФAЙЛMET.name <> ptr(0) then begin ГEHMETKИ; CTATИCT(ШAГГEHME) end;
  9999: if 3 in PEЖИMЫ then ПEЧCTATИ;
  writeln(' '); writeln("=== KOHEЦ PAБOTЫ KOMПOHOBЩИKA ===");
  repeat besm(0740000B); (x); until false;
  (x);
end.D
  PADCHAR = ' ';
  BEKXEШ = 0C;
  HAЧAЛOДИ = 0C;
  HOMEPOБЬ = 1;
  HOMEPПPE = 1;
  PAЗPEШИЛ = true;
  MTИЛ =
    ЗAПPЛИT:10,
    PAЗЛИT,
    ЗAПPЛИT:20,
    CПEЦЛИT,
    PAЗЛИT,
    ЗAПPЛИT:7,
    CПEЦЛИT:8,
    ЦИФPA:10,
    CПEЦЛИT:6,
    ЗAПPЛИT,
    БYKBA:26,
    ЗAПPЛИT:6,
    БYKBA:26,
    ЗAПPЛИT:69,
    БYKBA:31,
    ЗAПPЛИT,
    БYKBA:31,
    ЗAПPЛИT;
  HAЧAЛOME = 0, 31, 59, 90, 120, 151, 181,
             212, 243, 273, 304, 334, 365
end
