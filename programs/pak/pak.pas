(*=s7,s8,p-,t-,m-,y+,a1,l1*)
program pak(output, (*=s1*) paszero (*=s0*));
% Source recovery from 2053:0437-0442, also 2048:0034-0037.
% Recompiled recovery: 02026-07231, 29 routines and the main.
% The preliminary lift pak.decomp is retained as working evidence.
% Build: python3 tools/build.py pak.pas --compiler pascal
% Most names are invented; BUFB survives in its file initializer.
% Runtime under the original DISPAK environment is not yet tested.
% S1 names the common PASZERO*; S0 leaves DECODEID without stars.
% Stock BESM takes one instruction and aligns every call to a word.
% READSYS keeps the original frame operands (DST=4, I=6, selector=7).
const channelhdr='   НУ ТОМ  ТИП  СТАТУС   ЧЗ';
type bits48=set of 0..47;
     maskarray=array[0..127] of bits48;
     maskrec=record case integer of
       0:(all:array[0..255] of bits48);
       1:(first,second:maskarray);
       2:(padm:array[0..511] of bits48;
          pages:array[0..30] of bits48;
          buffer:packed array[0..849] of 0..16777215);
       3:(pada:array[0..255] of bits48; archive:maskarray)
     end;
     maskpt=@maskrec;
     memory=record
       skip:array[0..191] of integer;
       banks:array[0..31] of bits48
     end;
     memptr=@memory;
     hexword=packed array[1..12] of 0..15;
     sysbuf=array[0..1023] of bits48;
     sysarray=packed array[0..4095] of 0..16777215;
     syspt=@sysrec;
     modeword=packed record
       skip:set of 0..33; flags:set of 0..2; tail:set of 0..10
     end;
     numword=packed record
       skip:0..15; n:0..4095; rest:set of 0..31 end;
     dateword=packed record
       unused:set of 0..23; d5,d4,d3,d2,d1,d0:0..15
     end;
     volumeheader=packed record
       b0,b1,b2,b3:boolean; number:0..4095
     end;
     volkind=(vk0,vk1,vk2,vk3);
     taskmode=(tm0,tm1,tm2,tm3,tm4,tm5,tm6,tm7);
     volumerec=packed record
       skip:set of 0..29; status:volkind; header:volumeheader
     end;
     packedvols=packed array[1..12] of volumeheader;
     word48=packed record case integer of
       83:(a83:set of 0..1; n2x7:0..127);
       84:(a84:set of 0..23; n24x6:0..63);
       85:(n0x6:0..63);
       86:(a86:set of 0..41; n42x6:0..63);
       81:(n0x24:0..16777215);
       68:(a68:set of 0..23; n24x3:0..7);
       69:(a69:set of 0..0; n1x23:0..8388607);
       70:(a70:set of 0..12; n13x2:0..3);
       71:(a71:set of 0..14; n15x4:0..15);
       72:(a72:set of 0..18; n19x1:0..1);
       73:(a73:set of 0..19; n20x4:0..15);
       74:(a74:set of 0..27; n28x4:0..15);
       75:(a75:set of 0..23; n24x4:0..15);
       76:(a76:set of 0..25; n26x10:0..1023);
       77:(a77:set of 0..41;
           m42x6:set of 0..5);
       78:(a78:set of 0..38;
           m39x2:set of 0..1);
       79:(a79:set of 0..17;
           m18x6:set of 0..5);
       67:(modeskip:0..15; mode4x3:taskmode);
       0:(raw:bits48);
       1:(n:integer);
       2:(h:hexword);
       3:(num:numword);
       4:(d:dateword);
       5:(header:volumeheader);
       6:(unused:set of 0..27; ticks:0..1048575);
       7:(fskip:set of 0..33; flags:set of 0..2;
          ftail:set of 0..10);
       8:(
         b0,b1,b2,b3,b4,b5,b6,b7:boolean;
         b8,b9,b10,b11,b12,b13,b14,b15:boolean;
         b16,b17,b18,b19,b20,b21,b22,b23:boolean;
         b24,b25,b26,b27,b28,b29,b30,b31:boolean;
         b32,b33,b34,b35,b36,b37,b38,b39:boolean;
         b40,b41,b42,b43,b44,b45,b46,b47:boolean);
       10:(n0x3:0..7);
       11:(n0x8:0..255);
       12:(n0x12:0..4095);
       14:(z14a:set of 0..0;
          n1x1:0..1);
       17:(z17a:set of 0..3;
          n4x3:0..7);
       22:(z22a:set of 0..6;
          n7x3:0..7);
       24:(z24a:set of 0..8;
          n9x3:0..7);
       26:(z26a:set of 0..9;
          n10x15:0..32767);
       27:(z27a:set of 0..10;
          n11x8:0..255);
       29:(z29a:set of 0..16;
          n17x1:0..1);
       30:(z30a:set of 0..18;
          n19x9:0..511);
       31:(z31a:set of 0..19; n20x7:0..127);
       32:(z32a:set of 0..23;
          n24x8:0..255);
       33:(z33a:set of 0..24;
          n25x6:0..63);
       40:(z40a:set of 0..32;
          n33x1:0..1);
       41:(z41a:set of 0..32;
          n33x5:0..31);
       43:(z43a:set of 0..13;
          m14x10:set of 0..9);
       50:(u50:set of 0..35;
          n36x12:0..4095);
       60:(x60:set of 0..44;
          n45x3:0..7);
       65:(a65:set of 0..15; n16x32:0..4294967295);
       66:(a66:set of 0..11; n12x12:0..4095)
     end;
     sysrec=record case integer of
       0:(half:sysarray);
       1:(w:array[0..2047] of word48)
     end;
% Type order preserves the pool coefficients for 8, 32 and 47 words.
     taskrec=record case integer of
       0:(words:array[0..5] of word48;
       f6:packed record
         skip:set of 0..13; flags:set of 0..9; tail:set of 0..23
       end;
       f7:packed record
         cl:0..7; skip:boolean; queue:0..7;
         skip1:set of 0..17; rank:0..63;
         skip2:set of 0..6; link:0..1023
       end);
       1:(w:array[0..7] of word48);
       2:(firstword:word48; volumes:packedvols)
     end;
     taskarray=array[0..127] of taskrec;
     taskpt=@taskarray;
     contextrec=record case integer of
       0:(w:array[0..31] of word48);
       1:(padctx:array[0..9] of word48;
          masks:array[1..3] of bits48)
     end;
     contextarray=array[0..15] of contextrec;
     contextpt=@contextarray;
     matrix=array[1..7,1..47] of integer;
     matrixpt=@matrix;
     intpt=@integer;
     optspt=@optsarray;
     optsarray=array[0..7] of bits48;
     statrec=record
       p:packed record count:0..255; ticks:0..1099511627775 end
     end;
     causecode=(rRun,rAll,rNoVol,rVolBusy,rNoChan,rReady,
       rForBudg,rNoBudg,rArchive,rWait,rCmd,rStop,rMach,
       rClass,rNoTerm,rOther);
     statarray=array[0..8,causecode] of statrec;
     statpt=@statdata;
     statdata=record case integer of
       0:(rows:statarray);
       1:(padstat:array[0..127] of integer;
          total:array[causecode] of statrec)
     end;

var
  g50,g51:taskpt;
  g52:maskpt;
  g53:syspt;
  буфб:text;
  g112:volumeheader;
  border:integer;
  width,column,nextcol:integer;
  g117:bits48;
  headtab:array[0..7,1..2] of integer;
  chains:matrixpt;
  heads:array[1..7] of integer;
  i,j,k,l:integer;
  passport:taskrec;
  g164:record case integer of
    0:(all:array[0..163] of word48);
    1:(pad1:array[0..140] of word48;
       channels:array[0..7] of word48);
    2:(pad2:array[0..132] of word48;
       classes:array[0..7] of word48);
    3:(pad3:array[0..162] of word48; tapechannels:boolean);
    4:(pad4:array[0..95] of word48;
       routes:array[0..15] of packed array[-2..3] of set of 0..7);
    5:(pad5:array[0..97] of word48;
       pending:array[0..63] of word48)
  end;
  catalog,hardware,summary:boolean;
  g433:bits48;
  g434:intpt;
  fresh:boolean;
  g436:optspt; g437:boolean;
  compact,details:boolean;
  g442:integer; g443:bits48; g444:causecode;
  g445:statpt; g446:bits48; g447,g450:boolean;
  g451:array[causecode] of packed array[1..12] of char;
  separator:char;
  g512,g513,g514:bits48;
  g515,g516,g517,g520,g521:integer; g522:contextpt;
  g523:memptr;
  g524:array[0..7] of alfa;
  g534:array[taskmode] of alfa;
  stamp,prevstamp:word48;
  counter:integer;
  outer,inner,lines,g552,g553,g554,g555:integer;
  paszero:char;

% The external wrapper is recovered in pak.pre (E50 0104).
procedure decodeid(w:hexword;
  var name:packed array[1..12] of char); fortran;

% Recovered E53/10 wrapper in pak.pre; its name is invented.
function systime:integer; fortran;

% Recovered monitor-control wrappers in pak.pre.
procedure savemask(w:integer); fortran;
procedure setbyte(w,addr:integer); fortran;

procedure setbank(a,b:integer); fortran;

% 02026-02303. Rebuild the class queues and their passport links.
procedure relink(a:taskpt);
var prev:array[0..7] of integer;
    next,last:integer;
begin
  if g442=1 then
    for i:=1 to 7 do begin
      heads[i]:=0;
      for l:=1 to 47 do chains@[i,l]:=0
    end;
  for k:=0 to 7 do begin
    headtab[k,g442]:=0; prev[k]:=0
  end;
  if g442=1 then
    for j:=1 to 127 do
      with a@[j] do
        if (3 in f6.flags) and (g52@.all[j]<>[]) then begin
          i:=f7.cl;
          heads[i]:=j;
          chains@[i,f7.rank]:=j
        end;
  if g442=1 then
    for i:=1 to 7 do
      if heads[i]<>0 then begin
        heads[i]:=0; last:=0;
        for l:=47 downto 1 do
          if chains@[i,l]<>0 then begin
            j:=chains@[i,l];
            if heads[i]=0 then heads[i]:=j;
            a@[j].f7.link:=0;
            if last<>0 then a@[last].f7.link:=j;
            last:=j
          end
      end;
  j:=a@[0].f7.link div 8;
  while j<>0 do
    with a@[j] do begin
      next:=f7.link div 8;
      k:=f7.queue;
      last:=prev[k];
      if last<>0 then a@[last].f7.link:=j;
      if headtab[k,g442]=0 then headtab[k,g442]:=j;
      if (next<>0) and (a@[next].f7.queue=k) then begin
        prev[k]:=0; f7.link:=next
      end else begin
        prev[k]:=j; f7.link:=0
      end;
      j:=next
    end
end;

% 02304-02324. Read system words through extracode 065.
% DST names the first word of a contiguous COUNT-word destination.
procedure readsys(n:integer; var dst:word48; count:integer);
var i,selector,last:integer;
begin
  selector:=g53@.half[n];
  last:=count-1;
  for i:=0 to last do begin
    besm(12300006B); besm(62400000B);
    besm(12300007B); besm(60650000B);
    besm(12300004B); besm(60000000B)
  end
end;

% 02325-02336: hardware print compression, not a Pascal FOR loop.
procedure repeatc(c:char; n:integer);
begin
  if n>0 then write(c, '_174', chr(n-1))
end;

% 02337-02356: clear a newly opened page or finish a line.
procedure newline(n:integer);
var i,last:integer;
begin
  if fresh then rewrite(output) else begin
    writeln;
    if not compact then begin
      last:=n-1;
      for i:=0 to last do writeln(' ')
    end
  end
end;

% 02357-02364.
procedure rule(n:integer);
begin
  write('*':n);
  newline(0)
end;

% 02365-02376.
procedure blank(n:integer);
begin
  repeatc(' ',border-1);
  repeatc('*',n);
  newline(0)
end;

% 02377-02407.
procedure endrule(n:integer);
begin
  if not compact then begin
    write('*':border);
    rule(n-1)
  end
end;

% 02410-02422. Twelve hexadecimal digits packed into one 48-bit word.
procedure print12(a:hexword);
begin
  for counter to 12 do write(chr(a[counter]))
end;

% 02423-02443. The 12-bit integer at bits 4..15 (MSB first).
function digits(w:volumeheader):integer;
var n:integer;
begin
  n:=w.number;
  select
    n>999:digits:=4;
    n>99:digits:=3;
    n>9:digits:=2;
    true:digits:=1
  end
end;

% 02444-02472. Decimal nibbles contain GOST digit codes.
procedure date(w:dateword);
begin
  write(chr(w.d1),chr(w.d0),' ЧАС ',chr(w.d5),chr(w.d4),
        '.',chr(w.d3),chr(w.d2))
end;

% 02473-02531. Clock ticks are fiftieths of a second.
procedure time(t:integer; flags:bits48);
var n:integer;
begin
  t:=t div 50;
  paszero:='_000';
  if 0 in flags then n:=3 else n:=2;
  write(t div 3600:n,'.',(t mod 3600) div 60:2);
  if 3 in flags then write('.',t mod 60:2);
  write(' ');
  paszero:=' '
end;

% 02532-02567. Elapsed time in seconds.
procedure duration(t:integer);
var h,m,s:integer;
begin
  h:=t div 3600;
  m:=(t mod 3600) div 60;
  s:=t mod 60;
  if h=0 then write('   ') else begin
    write(h:2,'.'); paszero:='_000'
  end;
  write(m:2,'.'); paszero:='_000';
  write(s:2,' '); paszero:=' '
end;

% 02577-02702. Device/status flags, rendered into the work file.
procedure status(s,t:bits48);
  procedure flag(v:boolean);
  begin
    write(буфб,'-',ord(v):1);
    separator:=','
  end;
begin
  separator:=' ';
  if 0 in s then begin
    write(буфб,separator,'ГП'); separator:=','
  end;
  if 1 in s then begin
    write(буфб,separator,'СLC');
    flag(0 in g164.all[131].flags);
  end;
  if 2 in s then begin
    write(буфб,separator,'ПЛ');
    flag(2 in g164.all[131].flags);
  end;
  if 3 in s then begin
    write(буфб,separator,'А-1'); separator:=','
  end;
  if 4 in s then begin
    write(буфб,separator,'ПИ');
    flag(1 in g164.all[131].flags);
  end;
  if 5 in s then begin
    write(буфб,separator,'А-0'); separator:=','
  end;
  if 1 in t then begin
    write(буфб,separator,'УВВ-0'); separator:=','
  end;
  if 0 in t then write(буфб,separator,'УВВ-1');
  write(буфб,'.')
end;

% 02703-02732.
procedure octstat(w:integer);
begin
  write(буфб,w:4 oct,' ЗОН');
  if w div 8 mod 8<>1 then
    case w mod 8 of
    1:write(буфб,'А');
    2,3,4:write(буфб,'Ы')
    end
end;

% 02733-02746. Copy buffered text with one leading blank.
procedure flush;
begin
  reset(буфб);
  while not eof(буфб) do begin
    write(буфб@:2); get(буфб)
  end;
  newline(1);
  rewrite(буфб)
end;

% 02747-02765. Pad buffered text to the report width.
procedure pad;
var n:integer;
begin
  reset(буфб);
  n:=0;
  while not eof(буфб) do begin
    write(буфб@); get(буфб); n:=n+1
  end;
  rule(width-n);
  rewrite(буфб)
end;

% 02766-03143. Three-line heading, depending on the report switches.
procedure heading;
begin
  write('*':border);
  write('  НОМ       ШИФР    П');
  repeatc(' ',42);
  if catalog then begin
    repeatc(' ',5);
    if hardware then repeatc(' ',9)
  end else write('К  ');
  write('   З А К А З А Н О      Т  ');
  if catalog then write('М ');
  write('НАЧАЛО');
  if catalog then write('    ЖДЕТ     ');
  if summary then write('    ');
  rule(1);
  write('*':border);
  repeatc(' ',20);
  write('О  ФАМИЛИЯ   Т О М А  В  П А С П О Р Т Е   ');
  if catalog then begin
    write('ПРИЧ');
    if hardware then write('  БЮДЖЕТ ')
  end else write('А ');
  repeatc(' ',23);
  write('  Е ');
  if catalog then write(' А');
  repeatc(' ',7);
  if catalog then repeatc(' ',13);
  if summary then write('П/К ');
  rule(1);
  write('*':border);
  if catalog then write(' ГРУППА    ') else write(' КЛАСС     ');
  write('ЗАДАЧИ   В');
  repeatc(' ',42);
  if catalog then begin
    repeatc(' ',5);
    if hardware then repeatc(' ',9)
  end else write('Н  ');
  write(' ВРЕМЯ ОЗУ ТРА СЕГ АЦП  Р  ');
  if catalog then write('Ш ');
  write('ВВОДА ');
  if catalog then write(' ШИФР/ВРЕМЯ  ');
  if summary then write('    ');
  rule(1)
end;

% 03144-04407. Detailed passport line, with its nested helpers.
% Packed numeric names nAxB denote B bits starting at MSB position A.
% Reason selection preserves the historical branch order.
procedure task;
var name:packed array[1..12] of char;
    volumes:array[1..12] of volumerec;
    v,other:volumeheader;
    kind:volkind;
    idx,otheridx,volno,count,pos,cl,tty,term:integer;
    busy,mt,md:boolean;
    reason:boolean;
    budget:bits48;

  procedure mark(cause:causecode);
  begin
    with g445@.rows[cl,cause].p do begin
      count:=count+1;
      ticks:=ticks+passport.w[0].ticks
    end;
    g443:=g443+[cause];
    g446:=g446+[cl]
  end;

  procedure volume(w:volumeheader);
  begin
    if kind=vk0 then begin
      if w.b3 then mt:=true else md:=true;
      write(буфб,'-')
    end else if pos<>1 then write(буфб,' ');
    if w.b2 and details then write(буфб,'АРХ')
    else write(буфб,w.number:1);
    if w.b2 then write(буфб,'.') else
      if w.b0 then write(буфб,'*') else;
  end;

  procedure volist;
  begin
    nextcol:=0; column:=0;
    while (count>=pos) and (nextcol<30) do
    with volumes[pos] do begin
      v:=header; kind:=status;
      if v.b2 and details then nextcol:=3
      else nextcol:=digits(v);
      nextcol:=nextcol+column;
      if (kind<>vk0) and (pos=1) then else nextcol:=nextcol+1;
      if v.b0 then nextcol:=nextcol+1;
      if 30>=nextcol then begin
        column:=nextcol; volume(v); pos:=pos+1
      end
    end;
    reset(буфб);
    nextcol:=(30-column) div 2;
    repeatc(' ',nextcol);
    while not eof(буфб) do begin write(буфб@); get(буфб) end;
    repeatc(' ',30-column-nextcol);
    rewrite(буфб)
  end;

begin
  write('*':border);
  if 5 in passport.w[6].m14x10 then write(' Ф') else write(' В');
  write(passport.w[0].n0x8:3 oct);
  cl:=passport.w[7].n4x3;
  if catalog then
    write('/',chr(passport.w[7].n7x3),' ')
  else write('-',chr(cl),' ');
  stamp.raw:=g52@.all[passport.w[0].n0x8+(g442-1)*128];
  print12(stamp.h);
  if 4 in passport.w[6].m14x10 then write('+') else write(' ');
  decodeid(stamp.h,name);
  write(name);
  g117:=[2]; pos:=1; count:=0; mt:=g447; md:=g450;
  for idx:=1 to 12 do begin
    v:=passport.volumes[idx]; volno:=v.number;
    if v.b3 then begin
      for otheridx:=idx+1 to 12 do begin
        other:=passport.volumes[otheridx];
        if other.b3 and (other.number=volno) then begin
          other.b3:=false; passport.volumes[otheridx]:=other;
          v.b0:=v.b0 or other.b0
        end
      end;
      v.b3:=(volno<2048) or (g164.all[156].n16x32<volno);
      if catalog then begin
        kind:=vk0;
        (find) for otheridx:=0 to 95 do
          with g164.all[otheridx] do
            if n36x12=volno then begin
              select
                b7:kind:=vk2;
                b6 or b29:kind:=vk1;
                true:kind:=vk2
              end;
              if not b6 and (n20x7<99) then n20x7:=n20x7+1;
              exit find
            end
      end else kind:=vk2;
      count:=count+1;
      g117:=g117+[kind];
      with volumes[count] do begin header:=v; status:=kind end
    end
  end;
  volist;
  tty:=passport.w[0].n11x8; term:=;
  if catalog then begin
    reason:=0 in g117;
    stamp.raw:=g52@.second[passport.w[0].n0x8];
    besm(650006B); budget:=;
    if passport.w[0].b10 then begin
      term:=g555+tty;
      besm(400014B); besm(60650000B);
      besm(360026B); besm(360152B); besm(4150011B);
      term:=;
    end;
    busy:=passport.w[4].n33x1=1;
    (q);
    if busy then begin
      idx:=heads[g164.all[151].n45x3];
      (search) while idx<>0 do
        with g50@[idx] do begin
          if g52@.all[words[0].n0x8]=stamp.raw then begin
            busy:=false; exit search
          end;
          idx:=f7.link
        end
    end;
    (why) begin
    select
      g442=2:begin write('     '); mark(rOther); exit why end;
      2 in passport.w[6].m14x10:begin
        reason:=false;
        if passport.w[5].b32 then begin
          write('ЗУПР '); mark(rCmd)
        end else begin
          select
          stamp.raw=prevstamp.raw:write('ТЕЛЕ ');
          stamp.raw*[0:23]=[]:write(' ВРЕ ');
          true:write('ЖДЕТ ')
        end;
        mark(rWait)
        end; exit why
      end;
      busy:begin write('ГЛАВ '); mark(rWait); exit why end;
      ((4 in budget) or (passport.w[3].n33x1=1)) and
        (passport.w[7].n0x3<>g164.all[151].n45x3):
          begin write(' МАШ '); mark(rMach); exit why end
    end;
      if not g164.all[131].b27 and
        (not g164.all[132].b31 or (passport.w[1].n33x1=1))
      then else begin
        write('СТОП '); mark(rStop); exit why
      end;
    if (9 in passport.w[6].m14x10) or passport.w[0].b8 then begin
      write('ЗАРХ '); mark(rArchive); exit why
    end;
    if (g164.channels[cl].n9x3<>0) and
      (not g164.all[130].b5 or (cl<>5) or
      (passport.w[0].n11x8=0))
    then else begin write('ЗКЛА '); mark(rClass); exit why end;
    if reason then begin write('НТОМ '); mark(rNoVol); exit why end;
    if (1 in g117) and not passport.w[5].b32 then begin
      write('ЗТОМ '); mark(rVolBusy); exit why
    end;
    if hardware and (7 in passport.w[6].m14x10) then begin
      if (0 in (passport.w[6].raw*[0,1])) and
        (passport.w[5].n33x5=0) then begin
          write('НБЮД '); mark(rNoBudg)
        end else begin write('ЗБЮД '); mark(rForBudg) end;
      exit why
    end;
    if (tty<>0) and
      ((term=0) or
      (term-1 in (g164.all[149].raw+g164.all[150].raw))) then begin
        write('НТЕР '); mark(rNoTerm); exit why
      end;
    select
      (g164.channels[cl].b2) or (g164.classes[cl].raw=[]):begin
        write('НКАН '); mark(rNoChan)
      end;
      true:begin
        mark(rReady);
        write(g524[passport.w[2].n1x1*4+
          passport.w[2].n17x1*2+passport.w[2].n33x1])
      end
    end;
    end;
    mark(rAll);
    if hardware then begin
      write(g534[passport.w[6].mode4x3]);
      if 7 in passport.w[6].m14x10 then begin
        select
          passport.w[6].raw*[0,1]=[0,1]:write('БЛОК ');
          passport.w[6].raw*[0,1]=[1]:write('ШТР. ');
          passport.w[6].raw*[0,1]=[0]:write('ЗМОР ');
          true:write('ЗАПР ')
        end
      end else write('     ')
    end
  end else begin
    write(passport.w[7].n25x6:2 oct,' ');
    mark(rRun)
  end;
  duration((passport.w[0].ticks*32+17) div 50);
  write(passport.w[6].n36x12+1:2,passport.w[0].n19x9:4);
  if passport.w[7].n33x5<>0 then
    write(passport.w[7].n33x5:3) else write('   ');
  write(passport.w[5].n24x8:4);
  if tty<>0 then begin
    if passport.w[0].b10 then write(' А') else write('  ');
    write(tty:2 oct,' ')
  end else repeatc(' ',5);
  if catalog then begin
    select
      passport.w[3].n33x1=1:write(passport.w[7].n0x3:1);
      hardware and (passport.w[5].n33x5<>0):
        write(passport.w[5].n33x5:1);
      passport.w[7].n0x3<>0:write(passport.w[7].n0x3:1);
      true:write(' ')
    end;
    write(' ');
  end;
  time(passport.w[7].n10x15*1024,[1,2]);
  if catalog then begin
    if (stamp.raw<>[]) and (stamp.raw<>prevstamp.raw) then begin
      if stamp.raw*[0:23]=[] then date(stamp.d)
      else print12(stamp.h);
      write(' ')
    end else repeatc(' ',13)
  end;
  if summary then begin
    if passport.w[5].n0x12<>0 then
      write(passport.w[5].n0x12:3,' ') else write('    ')
  end;
  rule(1);
  while count>=pos do begin
    lines:=0;
    write('*':border,' ':33);
    volist;
    rule(width-33-30-1)
  end;
  if catalog then begin
    otheridx:=0;
    for idx to count do
      if volumes[idx].status=vk0 then begin
        otheridx:=otheridx+1;
        passport.volumes[otheridx]:=volumes[idx].header
      end;
    passport.w[5].n12x12:=otheridx;
    passport.w[6].b2:=reason;
    if reason then begin g447:=mt; g450:=md end
  end
end;

% 04410-04637. Mounted volumes by class and free drive numbers.
procedure mounts(tape:boolean);
var printed:boolean;

  procedure install(first,last:integer; blocked:boolean);
  begin
    for counter:=first to last do
      with g164.all[counter] do
        if n36x12<>0 then
        if not b6 then
        if not b1 then
        if ((n20x7<>0) or b29)=blocked then begin
          write(separator);
          if tape then write(counter+24:2 oct)
          else write(counter-32:2 oct);
          if blocked then write('К');
          separator:=','
        end
  end;

begin
  for k:=7 downto 0 do begin
    j:=headtab[k,1]; printed:=false;
    while j<>0 do
      with g50@[j] do begin
        if w[6].b2 then
          for counter to w[5].n12x12 do begin
            g112:=volumes[counter];
            if g112.b3=tape then begin
              if not printed then begin
                column:=9; separator:=' ';
                write('КЛАСС',k:2,' :'); printed:=true
              end;
              nextcol:=digits(g112)+1;
              if g112.b0 then nextcol:=nextcol+1;
              column:=column+nextcol;
              if column>127 then begin
                newline(0); repeatc(' ',9); separator:=' ';
                column:=9+nextcol
              end;
              write(separator,g112.number:1);
              if g112.b0 then write('*');
              separator:=','
            end
          end;
        j:=f7.link
      end;
    if printed then begin write('.'); newline(0) end
  end;
  write('СВОБОДНЫЕ ');
  if tape then write('НМЛ :') else write('НМД :');
  separator:=' ';
  if tape then install(0,31,false) else install(32,95,false);
  if separator<>' ' then separator:=';';
  if tape then install(0,31,true) else install(32,95,true);
  if separator=' ' then write(' НЕТ');
  write('.'); newline(1)
end;

% 04640-05073. Device channel and drive status.
procedure channels(drive:integer);
begin
  if g164.tapechannels then begin
    repeatc(' ',3); outer:=(drive+24) div 8
  end else begin
    repeatc(' ',8); outer:=(drive-32) div 8
  end;
  if g164.tapechannels or
    (7-(drive mod 8) in g164.routes[outer div 4,outer mod 4])
  then write(chr(outer),chr(drive mod 8),' ')
  else write('   ');
  with g164.all[drive] do begin
    if n36x12=0 then begin
      if g164.tapechannels then repeatc(' ',26) else repeatc(' ',21);
      exit
    end;
    write(n36x12:4);
    if b9 then write('!') else write(' ');
    select
      b1:write('СИС ');
      b30:write('АРХ ');
      b7:write('ОБЩ ');
      b29:write('УПР ');
      true:write('ИНД ')
    end;
    select
      b8:begin
        write('ВЫКЛЮ');
        if g164.tapechannels then write('ЧЕНА ') else write('ЧЕН  ')
      end;
      b6:write('В РЕШЕНИИ ');
      b29 or b1:begin
        write('ЗАНЯТ');
        if g164.tapechannels then write('А    ') else write('     ')
      end;
      n20x7<>0:write('В КАТ(',n20x7:2,') ');
      true:begin
        write('СВОБО');
        if g164.tapechannels then write('ДНА  ') else write('ДЕН  ')
      end
    end;
    if b32 then write('-') else write('+');
    if b31 then write('-') else write('+');
    if g164.tapechannels then begin
      write(' ');
      if b35 then write('<ЕС>') else begin
        g552:=g164.pending[drive].n36x12;
        if g552<8 then write('ПРЕД')
        else write((g552-8) div 2:4 oct)
      end
    end
  end
end;

% 05074-05421. Machine clock, operating modes and free resources.
procedure machine;
var opened,closed,openextra,closedextra:bits48;
begin
  repeatc('*',36);
  write(' СМ',chr(g164.all[131].n24x3),'П:');
  time((g164.all[152].n1x23+g164.all[162].n1x23)*2,[1,2]);
  write('ЭВМ-',chr(g164.all[151].n45x3),'  ДАТА:',
    chr(g164.all[151].n13x2),chr(g164.all[151].n15x4),'.',
    chr(g164.all[151].n19x1),chr(g164.all[151].n20x4),'.',
    chr(g164.all[151].n28x4),chr(g164.all[151].n24x4),
    ' ВРЕМЯ:');
  counter:=systime;
  time(counter,[1:3]); write(' ');
  time(g164.all[155].n16x32+g164.all[157].n16x32,[0:2]);
  repeatc('*',36); newline(0); endrule(width);
  write(буфб,'*',' РЕЖИМ РАБОТЫ : ');
  if g164.all[131].b27 then write(буфб,'СТОП; ');
  if g164.all[132].b31 then write(буфб,'СПЕЦ; ');
  if g164.all[130].b5 then write(буфб,'НЕТ ДИА; ');
  if g164.all[132].b30 then write(буфб,'НЕТ ФОР; ');
  if g164.all[132].b28 then write(буфб,'НЕТ АРХ; ');
  if g164.all[132].b29 then write(буфб,'НЕТ КПИ; ');
  if g164.all[131].b33 then write(буфб,'СТК; ');
  if g164.all[131].b32 then write(буфб,'ОТЛ РЕЖ.')
  else write(буфб,'СЧЕТ.');
  pad;
  write(буфб,'*',' БУФЕР ВВОДА-ВЫВОДА : ВВОД-');
  octstat(g553);
  write(буфб,'; ВЫВОД-'); octstat(g164.all[161].n26x10);
  write(буфб,'; СВОБОДНЫ '); octstat(g554); write(буфб,'.');
  if g164.all[161].m42x6<>[] then begin
    write(буфб,' ИДЕТ ВЫВОД НА'); status(g164.all[161].m42x6,[])
  end;
  pad;
  closed:=g164.all[131].m42x6; opened:=closed / [0:5];
  closedextra:=g164.all[131].m39x2;
  openextra:=closedextra / [0,1];
  if not g164.all[132].b11 then begin
    opened:=opened-[1]; closed:=closed-[1]
  end;
  if not g164.all[132].b12 then begin
    opened:=opened-[0]; closed:=closed-[0]
  end;
  write(буфб,'*',' УСТРОЙСТВА ВВОДА-ВЫВОДА :');
  if (opened<>[]) or (openextra<>[]) then begin
    write(буфб,' ОТКРЫТЫ'); status(opened,openextra)
  end;
  if (closed<>[]) or (closedextra<>[]) then begin
    write(буфб,' ЗАКРЫТЫ'); status(closed,closedextra)
  end;
  if g164.all[160].m18x6<>[] then begin
    write(буфб,' СБОЙ'); status(g164.all[160].m18x6,[])
  end;
  pad;
  write(буфб,'*',' СВОБОДНЫЕ РЕСУРСЫ : ОЗУ - ',
    g164.all[158].n16x32:1,', ТРАКТЫ - ',
    g164.all[159].n16x32:1,', СЕГМЕНТЫ МД - ',
    card(g164.all[154].raw):1,'.');
  pad; endrule(width); blank(width)
end;

% 05422-05460. Decimal ruler for the 48 resource bits.
procedure bits(tens:boolean);
var n:integer;
begin
  repeatc(' ',15);
  for n:=48 downto 1 do begin
    if n=24 then write('  ');
    if tens then begin
      if n mod 5=0 then write(n div 10:2) else write('  ')
    end else write(n mod 10:2)
  end;
  newline(0)
end;

% 05461-05564. Allocation of one memory bank; names are inferred.
procedure bank(n:integer);
var i,count:integer; data:bits48;
begin
  data:=g523@.banks[n];
  count:=card(data);
  select
    n=g516:write('    ИНФОР --> ');
    n=g517:write('    ПРОГР --> ');
    count=0:exit;
    true:repeatc(' ',14)
  end;
  g520:=g520+count; g521:=g521+1;
  write(n:2 oct);
  for i:=0 to 31 do begin
    select
      n=g517:if i in data then write(' ХХ') else write(' ОС');
      n=g516:select
        i in (data / [1,2,10:15,22:29]):write(' ХХ');
        i in data:write(' ..'); true:write(' ОС') end;
      true:if i in data then write(' ..') else write(' ХХ')
    end
  end;
  write(' ',n:2 oct);
  newline(0)
end;

% 05565-05720. Print and update queued passports by class.
procedure queue(list:taskpt);
begin
  summary:=not hardware;
  if hardware then begin width:=127; border:=0 end
  else begin width:=122; border:=3 end;
  write(буфб,'ЗАДАЧИ  В  КАТАЛОГЕ':40,g442:2); flush;
  blank(width); endrule(width); heading;
  for k:=7 downto 0 do
    if headtab[k,g442]<>0 then begin
      endrule(width); write('*':border);
      counter:=(width-18) div 2;
      repeatc('_131',counter);
      write('< К Л А С С',k:3,' >');
      repeatc('_131',width-18-counter);
      rule(1); endrule(width);
      j:=headtab[k,g442]; lines:=0;
      while j<>0 do begin
        passport:=list@[j];
        if lines=5 then begin endrule(width); lines:=1 end
        else lines:=lines+1;
        task;
        list@[j]:=passport;
        j:=passport.f7.link
      end
    end;
  endrule(width); blank(width); newline(1)
end;

% 05721-07231. Monitor snapshot and all report selections.
begin
  counter:=g434@;
  if counter in [0:7] then g433:=g436@[counter]
  else g433:=[0:8];
  compact:=47 in g433;
  details:=46 in g433;
  if g433=[] then g433:=[0,1];
  savemask(176128); setbyte(31,176606);
  readsys(62,g164.all[98],32);
  readsys(34,g164.all[0],96);
  for counter:=0 to 95 do g164.all[counter].n20x7:=0;
  readsys(21,g164.all[133],8);
  readsys(224,g164.all[141],8);
  readsys(16,g164.all[132],1);
  readsys(55,g164.all[130],1);
  readsys(8,g164.all[131],1);
  readsys(52,g164.all[153],1);
  readsys(81,g164.all[156],1);
  readsys(4,g164.all[151],1);
  readsys(18,g164.all[161],1);
  readsys(27,g164.all[157],1);
  readsys(5,g164.all[158],1);
  readsys(7,g164.all[159],1);
  readsys(22,g164.all[154],1);
  counter:=g53@.w[14].n0x24+33;
  besm(400014B); besm(60650000B); g164.all[152].n:=;
  readsys(29,g164.all[155],1);
  readsys(30,g164.all[162],1);
  readsys(82,g164.all[160],1);
  readsys(83,g164.all[96],2);
  readsys(61,g164.all[149],1);
  g555:=g53@.w[78].n0x24;
  readsys(227,g164.all[150],1);
  setbyte(0,176485); setbyte(31,176486);
  for counter:=0 to 849 do
    if g52@.buffer[counter]<>0 then g553:=g553+1;
  for counter:=0 to 30 do
    g554:=g554+32-card(g52@.pages[counter]);
  (catalogue) for counter to 127 do
    if g52@.archive[counter]<>[] then begin
      g437:=true; setbyte(30,176487); exit catalogue
    end;
  relink(g50);
  (* The Y+ record constructor clears the packed counters together. *)
  for k:=0 to 8 do
    for g444:=rRun to rOther do
      g445@.rows[k,g444]:=[0C];
  fresh:=not (0 in g433);
  newline(1);
  write(буфб,'ЗАДАЧИ  В  РЕШЕНИИ':40); flush;
  blank(width); endrule(width); heading; endrule(width);
  for i:=1 to 7 do
    if heads[i]<>0 then begin
      write('*':border); repeatc('_131',46);
      write('< Э В М  ',chr(i),' >');
      repeatc('_131',45); write('*'); newline(0); endrule(width);
      j:=heads[i];
      while j<>0 do begin
        passport:=g50@[j]; task; j:=passport.f7.link
      end;
      endrule(width)
    end;
  blank(width); newline(1);
  fresh:=not (1 in g433);
  catalog:=true; hardware:=g164.all[132].b16;
  queue(g50);
  if g437 then begin
    hardware:=false; g442:=2; relink(g51); queue(g51)
  end;
  fresh:=false;
  if 2 in g433 then begin
    width:=128; border:=0;
    write(буфб,'СОСТОЯНИЕ  ЭВМ  И  ВВОДА - ВЫВОДА':48); flush;
    machine; newline(1)
  end;
  if 3 in g433 then begin
    write(буфб,'РАСПРЕДЕЛЕНИЕ  КАНАЛОВ  КЛАССАМ ЗАДАЧ':50); flush;
    width:=107; border:=11; blank(width);
    write('*':11); repeatc(' ',10);
    for l:=47 downto 1 do
      if l mod 8=7 then write(l div 8:2) else write('  ');
    rule(2); write('*':11,'   КЛАСС  ');
    for l:=47 downto 1 do write(' ',chr(l mod 8));
    rule(2); endrule(width);
    for k:=0 to 7 do begin
      write('*':11,k:2,' (',chr(g164.channels[k].n9x3),') ');
      if 47-k in g164.all[153].raw then write('МИН')
      else write('КВА');
      for l:=47 downto 1 do
        if l-1 in g164.classes[k].raw then write(' *')
        else write('  ');
      rule(2)
    end;
    endrule(width); blank(width); newline(1)
  end;
  if 4 in g433 then begin
    write(буфб,'СТРУКТУРА  ВХОДНОЙ  ОЧЕРЕДИ  ЗАДАЧ':48); flush;
    g444:=rOther;
    while card(g443)>8 do begin
      g443:=g443-[g444]; g444:=pred(g444)
    end;
    width:=card(g443)*11+8; border:=(128-width) div 2+1;
    blank(width); endrule(width); write('*':border,'КЛАСС':6);
    for g444:=rRun to rOther do
      if g444 in g443 then write(g451[g444]);
    rule(1); endrule(width); blank(width); endrule(width);
    for k:=0 to 8 do
      if k in g446 then begin
        if k=8 then endrule(width);
        write('*':border);
        if k=8 then write('ИТОГ ':6) else write(k:3,'   ');
        for g444:=rRun to rOther do
          if g444 in g443 then
            with g445@.rows[k,g444].p do
              if count<>0 then begin
                write(count:3,':'); time(ticks*32,[0:2]);
                g445@.total[g444].p.count:=
                  g445@.total[g444].p.count+count;
                g445@.total[g444].p.ticks:=
                  g445@.total[g444].p.ticks+ticks
              end else repeatc(' ',11);
        rule(1)
      end;
    endrule(width); blank(width); newline(1)
  end;
  if 5 in g433 then begin
    if g447 then begin
      write(буфб,'УСТАНОВКА  МАГНИТНЫХ  ЛЕНТ':44); flush; mounts(true)
    end;
    if g450 then begin
      write(буфб,'УСТАНОВКА  ПАКЕТОВ  ДИСКОВ':44); flush; mounts(false)
    end
  end;
  if 6 in g433 then begin
    for counter:=0 to 31 do
      if g164.all[counter].n36x12<>0 then
        g512:=g512+[counter div 8];
    if g512<>[] then begin
      write(буфб,'СОСТОЯНИЕ  ЛЕНТОПРОТЯЖЕК':44); flush;
      border:=(128-card(g512)*32) div 2-3;
      for counter:=-1 to 7 do begin
        repeatc(' ',border);
        for inner:=0 to 3 do
          if inner in g512 then
            if counter<0 then
              write(channelhdr,' ЗОНА')
            else channels(inner*8+counter);
        newline(0)
      end
    end;
    newline(1); g512:=[]; g164.tapechannels:=false;
    for counter:=0 to 7 do
      if g164.routes[counter div 4,counter mod 4]<>[] then
        g512:=g512+[counter];
    write(буфб,'СОСТОЯНИЕ  ДИСКОВОДОВ':42); flush;
    repeat
      border:=(128-card(g512)*32) div 2-8;
      for counter:=-1 to 7 do begin
        repeatc(' ',border); g513:=g512;
        for inner to 4 do
          if minel(g513)<>-1 then begin
            if counter<0 then
              write(channelhdr:32)
            else channels(minel(g513)*8+counter+32);
            g513:=g513-[minel(g513)]
          end;
        newline(0)
      end;
      g512:=g512*g513; newline(1)
    until g512=[]
  end;
  if 7 in g433 then begin
    write(буфб,'ТУМБЛЕРНЫЕ  РЕГИСТРЫ':42); flush;
    bits(true); bits(false);
    for outer:=1 to 7 do begin
      counter:=outer;
      besm(400014B); besm(60650000B); g514:=;
      write(outer:15);
      for counter:=0 to 47 do begin
        if counter=24 then write(outer:2);
        if counter in g514 then write(' Х') else write(' -')
      end;
      write(outer:2); newline(0)
    end;
    bits(false); bits(true); newline(1)
  end;
  if 8 in g433 then begin
    write(буфб,'МАГНИТНЫЕ  БАРАБАНЫ':42); flush;
    setbyte(31,176616);
    besm(650002B); besm(360054B); besm(360154B);
    besm(4150011B); counter:=;
    if counter=0 then counter:=1;
    outer:=1;
    (variant) for inner:=0 to 15 do
      if g522@[inner].w[14].n45x3=g164.all[151].n45x3 then
        if outer=counter then exit variant
        else outer:=outer+1;
    if inner>15 then begin
      writeln('НЕТ ВАРИАНТА ',counter:2 oct); besm(740000B)
    end;
    with g522@[inner] do begin
      g516:=w[7].n42x6; g517:=w[8].n42x6;
      if 32 in w[10].raw then begin
        g515:=32;
        for counter to 3 do
          g515:=card(masks[counter]*[0:31])*32+g515
      end else g515:=w[14].n2x7+1;
      setbank(0,g516);
      repeatc(' ',16);
      for counter:=0 to 31 do write(' ',counter:2 oct);
      newline(0);
      for counter:=8 to 23 do bank(counter);
      newline(1);
      write('РЕСУРСЫ РАБОЧЕЙ ПАМЯТИ : ОЗУ:':43,g515:1,
        'К; ЧИСЛО МБ:',g521:1,'; ТРАКТЫ НА МБ:',g520:1,
        '; ТРАКТЫ НА МД:',w[20].n24x6*32:1,
        '; СЕГМЕНТЫ МД:',w[20].n0x6:1,'.');
      newline(0)
    end
  end
end.DATA
% Initial words M1:050-053 and M1:112-556, edition 2053/2048/2248.
% Text words contain six GOST characters; _143 is kept as a code.

% System pointers.
  g50 := 76000C, 74000C, 0C, 76000C;

% Initial state and report options.
  g112 := 0C, 12, 105, 0C:19, 1000C, 0C:182,
    1C, 0C:2, 1C, 0C, 100C, 0C, 76000C,
    0C:3, 1, 0C:2, 1000C, 10000000000000C, 0C:2,

% Queue-state headings: two six-character words per heading.
    '_143 В РЕ', 'ШЕНИИ ',
    '_143 В КА', 'ТАЛОГЕ',
    '_143 НЕТ ', 'ТОМОВ ',
    '_143 ЗАН.', 'ТОМА  ',
    '_143 НЕТ ', 'КАНАЛА',
    '_143  НЕТ', ' РЕС. ',
    '_143 ЗАПР', '.БЮДЖ ',
    '_143 НЕТ ', 'БЮДЖ. ',
    '_143 ЗАПР', '.АРХ  ',
    '_143  ЖДУ', 'ЩИЕ   ',
    '_143 УПРЯ', 'ТАНЫ  ',
    '_143   СТ', 'ОП    ',
    '_143 ДРУГ', 'АЯ ЭВМ',
    '_143 ЗАПР', '.КЛАСС',
    '_143 ЗАН.', 'ТЕРМ. ',
    '_143 КАТА', 'Л. N2 ',

% Resource counters and labels.
    0C:7, 0:2, 76000C, 0C,
    '.... _143',
    ' ОЗУ _143',
    ' МБ  _143',
    ' СЕГ _143',
    ' АРХ _143',
    '.... _143':3,

% Task-mode labels.
    'НЕТ _143_143',
    'ЭКС _143_143',
    'ЛИМ _143_143',
    'Э/Л _143_143',
    'ДЕЖ _143_143',
    'Э!Д _143_143',
    'Л/Д _143_143',
    'Э/Д _143_143',

% Remaining state and working counters.
    0C, 4631463146314631C, 0C:5, 0:2, 0C:2;
END
