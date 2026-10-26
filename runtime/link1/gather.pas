% Definition/reference pass of LINK1, beginning at 05232.
procedure GATHER(FILEIDX: integer);
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
      if PLURAL then write('BXOДA') else write('BXOД');
      PUTKIND := entryval;
    end else begin
      if not c.resolved then begin
        write('BЫЧ.'); PUTKIND := computed
      end
      else if c.scope <> 0 then begin
        write('ПEP.'); PUTKIND := reloc
      end
      else begin write('AБC.'); PUTKIND := absolute end;
      if PLURAL then write('ЗHAЧEHИЯ') else write('ЗHAЧEHИE');
    end;
end;

begin
  MODULEMSG(ref(CURRENTFILE));
  case ERROR of
    0: begin
      RECORDMSG(BUFFER.data[0].header.kind);
      writeln(' : HEДOПYCTИMЫЙ HOMEP ПPEФИKCA');
    end;
    1: begin
      RECORDMSG(BUFFER.data[0].header.kind);
      writeln(' : HEДOПYCTИMЫЙ HOMEP ЭЛ.MOДYЛЯ');
    end;
    3: begin
      write('ПOBTOPHOE OПPEДEЛEHИE ГЛOБAЛЬHOГO ');
      NEWKIND := PUTKIND(ref(DEFINITION), true);
      write(' '''); PUTPATH(NAME); writeln(''',');
      write('PAHEE OПPEДEЛEHHOГO B MOДYЛE ');
      TABREAD(DEFPOOL, NAME@.defindex); OLDDEF := ;
      OBJREAD(FILEPOOL, OLDDEF@.b.fileindex); OLDFILE := ;
      write(OLDFILE@.name@.text:1, ' KAK ');
      OLDKIND := PUTKIND(OLDDEF, false); writeln('.');
      if NEWKIND >= OLDKIND then begin
        NAME@.defindex := DEFIDX; OLDFILE := ref(CURRENTFILE);
      end;
      writeln('ИCПOЛЬ-HO OПPEДEЛEHИE ИЗ MOДYЛЯ ',
              OLDFILE@.name@.text:1, '.');
      exit;
    end;
    4: writeln('ИCПOPЧEH OБ''EKTHЫЙ MOДYЛЬ - ',
               'OTCYTCTBYET ЗAПИCЬ ЗAГOЛOBKA');
    5: begin
      RECORDMSG(BUFFER.data[0].header.kind);
      writeln(' HAXOДИTCЯ HE HA CBOEM MECTE');
    end;
    6: begin
      RECORDMSG(BUFFER.data[0].header.kind);
      writeln(' : HEДOПYCTИMЫЙ TИП ЗAПИCИ');
    end;
    others: begin
      RECORDMSG(BUFFER.data[0].header.kind);
      writeln(' OШCИC=', ERROR:1, '!!!');
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
    if CODE.indexed then begin
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
      end;
    end else begin
      if INDEX > NPREF then BADOBJ(0);
      TABGET(PREFPOOL, INDEX-1, NODE);
    end;
    if CODE.first6[1] <> '.' then begin
      with NODE@ do begin
        LENGTH := UNPACKKY(name@, CHARS[1]); NODE := next;
      end;
    end;
  end;
  LENGTH := UNPACKNM(CODE, CHARS[LENGTH+1]) + LENGTH;
  if LENGTH = 0 then begin RESNAME := ptr(0); exit end;
  FIRST := 1; NPARTS := ;
  for K := 2 to LENGTH do begin
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
  for ITER to NPARTS do begin
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
  (records) begin
  repeat
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
        while (QSEC@.name = SECTION.name) and (CURSEC <> g0051) do
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
        if NENTRY = 0 then INITVEC(1, 256, 'T ЭMOД', ENTRYPOOL);
        ENTRYNODE := RESNAME(1, BUFFER.code);
        NENTRY := NENTRY+1;
        TABPUT(ENTRYPOOL, NENTRY-1, ENTRYNODE);
      end;
      3: begin
        READBODY(BUFFER.data);
        if NPREF = 0 then INITVEC(1, 512, 'T ПPEФ', PREFPOOL);
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
  end;
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
    PUTDATE(HEADER[5].time.seconds); write(' ');
    write(HEADER[4].account.high:6 hex, ' ЭBM-',
          HEADER[5].date.weekday:1, '  ');
    PUTCODE(HEADER[1].firstcode.text);
    PUTCODE(HEADER[1].lastcode.text);
    writeln(NSEC:6, NDEF:9, NREF:8, NENTRY:5, NPREF:5);
  end;
  if NPREF <> 0 then CLOSE(PREFPOOL);
  if NENTRY <> 0 then CLOSE(ENTRYPOOL);
  CLOSEIN(FILEIDX);
end;
