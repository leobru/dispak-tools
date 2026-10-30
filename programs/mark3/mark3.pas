(*=s7,s8,p-,t-,m-,y+,l1,o-*)
program main(output);(*=a1*)label 3516, 3667;
% MARK3: volume 2113, zones 1243-1245, the program that marks ЕС
% tapes on СВС (Э1-К2) by driving the IOP (ПВВ) directly; the names
% are invented. The routines E5143... are in inp.bemsh (BEMSH);
% run.b6 runs the same image from volume 2153, zone 0421.
% Build and compare with the original:
%   python3 programs/mark3/build.py
% It assembles inp.bemsh, compiles this text with mypas.b6 and links
% both with the standard library of volume 2113 (PERSO 311160, 320100),
% as the original job did.
%
% The user code (02012-04114), the constant pool and the globals are
% the same word for word. The PASCODER stub (02000-02011) and the
% P/1D library constants differ: the original was linked with another
% version of the library.
% o- keeps the load right after a store and one constant table with
% its replications, as the compiler of the original did; the only
% load it dropped is written as `g40z.a[5] := ;` in termio.
% The file initialization (no s5) is the code before the main program.
const
boilerplate='< ПРОГРАММА РАЗМЕТКИ  М Л = (ВЕРСИЯ ОТ 88/11/02) >';
(*=a2*)c1='ЬЬЬЬЬЬЬ';(*=a1*) (* unused *)
c2='_32000001'; (* filler for const pool matching *)
type charset=set of '0'..'П';
bitset=set of 0..47;
three=packed array [0..2] of 0..65535;
alfa0=packed array[0..5] of char;
defdesc=packed record z:0..4095; ercnt:0..7; double:boolean end;
defarr=array [0..7] of defdesc;

t2=array [0..7] of packed record case integer of

99:(w1:bitset; w2:0..65535);

0:(e48p16:set of 0..32; e15p1:0..32767;
w2e48p47:0..3; w2e46:boolean; w2e45p34:set of 0..11; w2e33:boolean);

2:(e48p35:set of 0..13; e34, e33, e32: boolean; e31p29:0..7;
e28,e27:boolean;
e26p7:0..1048575; e6, e5, e4, e3, e2, e1:boolean;
w2e48:boolean; w2e47p33:@three);

3:(e48, e47:boolean; e46p41: set of 0..5; e40p38:0..7);

4:(e48p43:set of 0..5; e42p39:0..15; e38p31:0..255)
end;

t1=array [boolean] of integer;
mode=(m0,m1,m2,m3);
var g40z, g41z: packed record case integer of
0:(a:packed array [0..7] of 0..63);
1:(s1:set of 0..41; s2:set of 0..5);
2:(s3:set of 0..7; b,x,c:boolean)
end;
g42z, protocol, batch, g45z,
g46z, g47z, g48z, g49z, g50z, g51z,
dense, single, svsonly, g55z, g56z, setupDone:boolean;
g58z, g59z, tty, len, vol, unit:integer;
IO:text;
cmd:alfa;
status:(x0, x1, x2, x3);
g96z:integer;
skipSet:charset;
g98z, g99z, g100z:integer;

g101z:packed record
e48, e47:boolean;
e46e43:set of 0..3;
e42e31:set of 0..11;
e30e25:0..63;
e24e6:set of 0..19;
e4e1:0..15
end;

request:t2;
pattern:t1;
nblks:array [boolean,boolean] of integer;
g124z, g125z, zones, g127z:integer;
erasures, defects:integer;
g130z, g131z: packed record
case integer of 0:(p:@three); 1:(a:@alfa0)
end;
g132z:@defarr;
g133z:array[boolean] of char;

procedure skipWhile(s:charset);
_(
   while not eof(IO) _and (IO@ IN s) do get(IO);
_);

procedure skipUntil(s:charset);
_(
   while not eof(IO) _and not (IO@ IN s) do get(IO);
_);

procedure skipsp; _( skipWhile([' ']) _);

function isYes:boolean;
_( skipsp;
isYes := eof(IO) or (IO@ = 'Д') or (IO@ = 'Y');
_);

procedure L2055(var a:alfa); label 2057;
var i:integer;
_(
2057: a := '_377     ';
for i to 6 do _(
if eof(IO) then exit;
if g48z and (IO@ = '>') then _( get(IO); goto 2057 _);
if IO@ in skipSet then exit;
a[i] := IO@;
len := i;
get(IO)
_);
(q) skipUntil(skipSet);
_);

function cmpAlfa(a, b:alfa; n:integer):boolean;
var i:integer;
_(
if len < n then cmpAlfa := false else _(
cmpAlfa := true;
for i to 6 do _(
if (a[i] = ' ') or (b[i] = ' ') then exit;
if a[i] <> b[i] then _( cmpAlfa := false; exit _);
_)
_)
_);
procedure termio(m:mode);
_var buf:packed array[0..143] of char;
i,j:integer;
s:bitset;

procedure toBuf;
_(
reset(IO);
i := 0;
while not eof(IO) and (i < 143) do _(
buf[i] := IO@;
get(IO);
i := i + 1;
_);
buf[i] := '_377';
_);

procedure hardCopy(l3a1z:boolean);
 _(
 i := 0;
 reset(IO);
 while not eof(IO) do _(
 select
 l3a1z and g46z: _( write( '_031' ); i := i + 1 _);
 (IO@ = '_170'): write( '_173', chr(i - 1));
 true: _( write( IO@ ); i := (i + 1) _)
 end;
 get(IO);
 _);
_);
 
procedure again;
_(
  if g47z then exit;
  g59z := 1;
  rewrite(IO);
  write(IO, 'ЕЩЕ?');
  termio( m3 );
  g50z := not isYes;
  rewrite(IO);
  if g50z and g49z and not g51z then GOTO 3516;
 _);
 
procedure L2246;
_(
  s := (s * [22,23]);
  g50z := false;
  select
  (s = []) or (s = [22,23]): besm(740000C);
   (m = m3) and (s = [23]): _(
   j := (j + 1);
   if (j = 2) then besm(740000C) else termio( m3 );
 _);
 (m = m2): _(
  if (s = [23]) then again else
   if (g59z = g58z) then again _else 
    g59z := g59z + 1;
 _) end
_);

procedure flip(var flag:boolean);
_(
 while not eof(IO) do get(IO);
 if flag then  write(IO, 'ОТМ.') _else write(IO, 'УСТ.');
 flag := not flag;
 g51z := true;
 termio( m2 );
 rewrite(IO);
 write(IO, '-_170');
 _);

_( (* termio *)
   case m of
   m0: _(
          besm(4710024B); (q);
          besm(4230011B);
          tty := ;
          g40z.a[5] := ; g41z.a[7] := tty;
          g42z := tty <> 0;
          batch := not g42z;
          g45z := ;
   _);
   m1: _(
         g41z.s1 := [5,7,22,29];
         besm(710000B : g41z); (q);
         termio(m0);
   _);
   m2: _(
   if protocol then _( hardCopy (false); writeln _);
   if not batch and (g42z or g51z) then _(
      toBuf;
      g40z.b := false;
      besm(710000B : g40z); (q);
      s := ;
      L2246
   _); (* 2403 *)
   if not g51z then rewrite(IO);
   g51z := false;
   _);
   m3: (L2407) _(
    j := 0;
    g59z := 1;
    if protocol then hardCopy(false);
    if batch then _(
    besm(600000B : buf); (q);
    besm(420016B); s := ;
    rewrite(IO);
    if s = [] then write(IO, 'КНЦ') else _(
    i := 1;
    while buf[i] <> '_000' do _(
    write(IO, chr(ord(buf[i]) mod 128));
    i := i + 1;
    if i mod 6 = 0 then i := i + 1;
    _)
    _)
    _) _else _( (* 2447 *)
    toBuf;
    g40z.b := true;
    g40z.c := g46z;    
      besm(710000B : g40z); (q);
      s := ;
      L2246;
      rewrite(IO);
      i := 0;
      while (buf[i] <> '_377') and (i <= 143) do _(
      write(IO, buf[i]);
      i := i + 1;
      _)
    _); (* 2500 *)
    if protocol then _( hardCopy(true); writeln _);
    if g47z and not g46z then _( g51z := true; termio(m2) _);
    reset(IO);
    L2055(cmd);
    if cmpAlfa(cmd, 'КНЦ   ', (3)) then besm(740000B) else _(
       if (cmpAlfa( cmd, 'НАЧ   ', (3))) then
       GOTO 3516;
       if (cmpAlfa( cmd, 'Э.    ', 2)) then _(
       flip(g47z);
       goto L2407 _);
       if (cmpAlfa( cmd, 'А.    ', 2)) then _(
       flip( protocol );
       goto L2407 _);
       if (cmpAlfa( cmd, 'V.    ', 2)) then _(
        flip( g42z );
        goto L2407 _);
    _); (* 2554 *)
    reset(IO)
   _)
   end
_);

function isDigit(l2a1z:integer):boolean;
_(
  isDigit := not eof(IO) and (ord(IO@) < l2a1z);
_);

function getNum(l2a1z:integer):integer;
_var l2v1z:integer;
_(
 termio( m3 );
 l2v1z := 0;
 while isDigit(l2a1z) do _(
 l2v1z := l2v1z * l2a1z + ord(IO@);
 get(IO);
 _);
 getNum := l2v1z;
_);

function confirm:boolean;
_(
 termio( m3 );
 reset(IO);
 confirm :=   isYes;
 rewrite(IO);
_);

procedure L2632;
_(
zones := zones + ord(single or g55z);
g55z := not (single or g55z);
g127z := (zones + 4) *(ord(not single) + 1) + ord(g55z);
(q);
_);

procedure L2656(l2a1z, l2a2z, l2a3z:integer);
var l2v1z, l2v2z:integer;
l2v3z:array [0..2] of integer;
l2v6z:array [0..6] of char;
procedure E5215(l2a1z:integer; var l2a2z:array [0..2] of integer);
fortran;
procedure E5223(l2a1z:integer; var l2a2z:array [0..6] of char);
fortran;
_(
  if l2a3z = 1c then _(
   if svsonly then _( l2v1z := l2a2z * 4; _)
    else l2v1z := l2a2z * 7;
    _) else _( (*2672 *)
   if not svsonly then l2v1z := (l2a2z + 8) * 7 else
   if l2a2z < 256 then l2v1z := l2a2z * 12 + 67
    else _( l2v1z := (l2a2z - 256) * 4 + 64; _)
   _); (* 2707 *)
    if not svsonly then _(
     E5223(l2a1z, l2v6z);
     for l2v2z := 0 to 6 (* should it be to 5? *) do _(
     g130z.a@[l2v1z+l2v2z] := l2v6z[l2v2z];     
     _)
  _) _else _( (* 2727 *)
     E5215(l2a1z, l2v3z);
     if (l2a2z >= 256) or (l2a3z = 1c) then _(
     for l2v2z := 0 to 2 do
     g130z.p@[l2v1z + l2v2z] := l2v3z[l2v2z];
     _) _else _( 
     for l2v2z := 0 to 2 do _(
     g130z.p@[l2v1z] := l2v3z[l2v2z];
     l2v1z := (l2v1z + (4));
     _)
  _)_) (* 2766 *)
_);

procedure E5165(vol:integer; svsonly, single:boolean;
unit, g127z, p1, p2:integer;
var l2v1z: array [0..7] of integer); fortran;

procedure L2767;
_var l2v1z: array [0..7] of integer;
l2v9z:integer;
_(
 E5165(vol, svsonly, single, unit, g127z, g124z, g125z, l2v1z);
 for l2v9z := 0 to 7 do L2656( l2v1z[l2v9z], l2v9z, 1c );
 _);

procedure L3010(l2a1z:integer);
_var l2v1z:integer; _(
 g96z := l2a1z;
 for l2v1z := 0 to 7 do _(
 request[l2v1z].w1 := [];
 request[l2v1z].w2 := 0C;
 _);
 request[0].e15p1 := g100z;
 request[3].e48 := l2a1z <> 1;
 request[3].e40p38 := 6;
 if svsonly then _(
 request[2].w2e47p33 := g130z.p;
 request[2].e26p7 := 1045;
 request[2].e31p29 := 2; 
 _) _else _( (* 3073 *)
 request[2].w2e47p33 := g130z.p;
 request[2].e26p7 := 1204;
 _); (* 3105 *)
 request[4].e42p39 := g100z mod 16;
 request[4].e38p31 := l2a1z;
_);

procedure E5143(var x:t2); fortran;
procedure L3117; label 3127, 3147;
var retry:boolean;
function E5265(l2a1z:integer):integer; fortran;
_(
 retry := false;
 if E5265(1) <> 0 then  GOTO 3516;
 3127:
 E5143(request);
 if not request[5].w2e33 and not request[5].w2e46 then
 status := x0
 else _(
  if not setupDone and request[5].w2e46 then _(
   write(IO, ' УСТРОЙСТВО НЕ ИСКЛЮЧЕНО!');
   3147:  termio( m2 ); GOTO 3516;
  _);
  if request[6].e47 then _(
  write(IO, ' НЕТ ГОТОВНОСТИ УСТРОЙСТВА!':120);
  goto 3147
  _);
  if request[5].e1 then status := x1 else _(
  if request[6].e34 then _(
  write(IO, ' ЗАПРЕЩЕНА ЗАПИСЬ!':120);
  goto 3147;
  _) (* 3171 *);
  if request[6].e48 then status := x2
  else _( if request[5].w2e46 and retry then _(
  write(IO, 'НЕ ПРОХОДИТ ОБРАЩЕНИЕ К УСТРОЙСТВУ':120);
  goto 3147;
  _);
  if request[5].w2e46 then _(
  retry := true;
  L3010(request[4].e38p31);
  goto 3127;
  _); status := x3; (q) exit q;
 _)_)_); (* 3215 *)
_);
procedure L3216;
_var l2v1z, l2v2z, l2v3z, l2v4z:alfa;
date:packed record
filler:set of 0..12;
d1:0..3;
d2:0..9;
m1:0..1;
m2:0..9;
y2:0..9;
y1:0..9
end;
l2v6z:integer;
_(
 for g99z to 120 do write( '^' ); writeLN;
 writeln('ЭТИКЕТКА ДЛЯ КАТУШКИ':74);
 writeln(' ':50, '*^^^^^^^^^^^^^^^^^^^^^^^^^^^*');
 besm(500106B); (q); l2v1z := ;
 besm(500107B); (q); l2v2z := ;
 besm(500165B); (q); l2v3z := ;
 besm(310100B); l2v4z := ;
 besm(500114B); (q); date := ;
 l2v3z[1] := ' ';
 writeln('!':51, l2v3z, l2v4z, '  ', l2v1z, l2v2z, ' !');
 writeln('!':51, 'МЛ # ':14, vol:4, g133z[single]:3, g133z[svsonly],
    g133z[dense], '!':5);
 writeln( '!':51, 'ЗОН: ':14, zones-1:4 oct, '!':10);
 writeln('! РАЗМЕЧЕНА ':62, date.y1:1, date.y2:1,'.',
 date.m1:1, date.m2:1, '.', date.d1:1, date.d2:1,
 ' НМЛ ', unit:2 oct, ' !');
 writeln( '!':51, 'ТЕЛЕФОН: !':28);
 if (l2v2z = 'ВЦЕВ М') then  writeln( '!':51, '4-75   !':28)
 else writeln( '!':51, '!':28 );
 writeln('*^^^^^^^^^^^^^^^^^^^^^^^^^^^*':79);
 writeLN;
 writeLN;
 writeLN;
 if (defects = 0) then writeln('ДЕФЕКТОВ НЕ ОБНАРУЖЕНО':75)
 else _(
  writeln(' ':50, 'НОМЕР ДЕФ.ЗОНЫ   ЧИСЛО СТИРАНИЙ');
  l2v6z := (defects - 1);
  for g99z := 0 to l2v6z do with g132z@[g99z] do
   writeln(' ':56, z:4 oct, '.', ord(double):1, ercnt:15); 
  _) (* 3457 *)
_);

procedure setup;
_(
 besm(0100000B);  besm(0620123B); (q);
 g99z := 2011C;   besm(0500103B); (q); 
 g99z := 236C;    besm(0500137B); (q); 
 g99z := 234C;    besm(0500137B); (q); 
 cmd := 'Я-ТЕСТ'; besm(0470017B); (q); 
 skipSet := [' '];
 termio( m0 );
 rewrite(IO);
_);

_(
  if not setupDone then _( setup; write(IO, boilerplate) _);
  3516: termio( m2 );
  if g45z then _(  L3216; besm(0740000B) _);
  repeat
  repeat
  rewrite(IO);
  write(IO, 'НОМЕР ТОМА МЛ- ');
  vol :=   getNum( (10) );
  until (vol <> 0) and (vol < 4096);
  repeat
  rewrite(IO);
  write(IO, 'УСТРОЙСТВО- ');
  unit :=   getNum( (8) );
  until (0 <= unit) and (unit <= 63);
 rewrite(IO);
 write(IO, 'НУЖНА ЛИ СОВМЕСТИМОСТЬ С БЭСМ-6? ');
  svsonly := not confirm;
 write(IO, 'НУЖНЫ ЛИ ДУБЛЬ-ЗОНЫ? ');
 single := not confirm;
 write(IO, 'ПЛОТНОСТЬ ЗАПИСИ(32,63)- ');
 dense := getNum(10) = 63;
 rewrite(IO);
 write(IO, 'НЕ ЗАБУДЬТЕ ИСКЛЮЧИТЬ УСТРОЙСТВО ');
 write(IO, 'ИЗ КОНФИГУРАЦИИ!');
 termio( m2 );
 if svsonly then write(IO, ' НЕ');
 write(IO, 'СОВМЕСТИМАЯ С БЭСМ-6 РАЗМЕТКА ');
 if single then write(IO, 'БЕЗ ДУБЛЬ-ЗОН ') 
 else write(IO, 'С ДУБЛЬ-ЗОНАМИ ');
 termio( m2 );
 write(IO, 'ТОМА #', vol:1, ' НА УСТРОЙСТВЕ ', unit:2 oct,
       ' С ПЛОТНОСТЬЮ ');
 if dense then write(IO, '63 БИТ/ММ.') else write(IO, '32 БИТ/ММ');
 termio( m2 );
 write(IO, 'ВЕРНО?');
 until confirm;
 g101z.e48 := true;
 g101z.e46e43 := [0..3];
 g101z.e30e25 := unit;
 g101z.e4e1 := 2;
 besm(0470015B); (q); besm(04150011B); g100z := ;
 (q) if g100z = 0 then _(
  write(IO, ' УСТРОЙСТВА ', unit:2 oct, ' НЕТ!');
  3667: termio( m2 );
  goto 3516;
  _);
  L3010( (3) );
  L3117;
 rewrite(IO);
 write(IO, 'ТЕРМИНАЛ СВОБОДЕН.');
 termio( m2 );
 termio( m1 );
 L3010( (7) );
 L3117;
 if dense then  L3010( (195) ) else  L3010( (203) );
 L3117;
 if status = x2 then _(
  write(IO, ' НЕТ ЗАДАННОЙ ПЛОТНОСТИ!');
  goto 3667;
 _);
 L3010( (23) );
 L3117;
 for g99z := 0 to 1022 do 
    L2656(pattern[odd(g99z)], g99z, 0c);
 L2656( g125z, (1023), 0c );
 zones := (-2);
 g55z := not single;
 setupDone := true;
 (loop) while nblks[single,svsonly] > zones do _(
   L2632;
   erasures := 0;
   L2767;
   g56z := false;
 repeat
 L3010( (31) );
 L3117;
 if (status = x1) then exit loop;
 (f) for g99z to 2 do (iter) _(
 if dense then  L3010( (195) ) else  L3010( (203) );
 L3117;
 L3010( 1 );
 L3117;
 case status of
 x1: exit loop;
 x3: _( L3010( (39) ); L3117; exit iter_);
 x0: _( L3010( (39) ); L3117 _)
 end;
  L3010( 2 );
  request[2].w2e47p33 := g131z.p;
  L3117;
   case status of
   x3: _(  L3010( (39) ); L3117 _);
   x0: _( g56z := true; exit f _)
   end
 _);
 if not g56z then _(
  L3010( (47) );
  L3117;
  L3010( (23) );
  L3117;
  erasures := (erasures + 1);
  if (erasures > 7) then exit loop;
 _);
  until g56z;
  if erasures <> 0 then with g132z@[defects] do _(
     z := zones;
     double := g55z;
     ercnt := erasures;
     defects := defects + 1;
  _)
 _);
 select
 status = x1:  write(IO, 'КОНЕЦ ЛЕНТЫ':120);
 erasures > 7: write(IO, 'БОЛЬШЕ СЕМИ СТИРАНИЙ ПЕРЕД ЗОНОЙ':120);
 true: write(IO, 'РАЗМЕТКА ОКОНЧЕНА.':120)
 end;
 if erasures < 8 then for g99z to 10 do _( L3010 (31); L3117 _);
 L3010 (15);
 E5143(request);
 goto 3516;
_).data
g40z := 1024000410000033C, 120000001000000C;
protocol := true;
g51z := true;
g58z := 777777777777B;
g59z := 0;
pattern := 5252525252525252C, 2525252525252525C;
nblks := 520, 1032, 1032, 2056;
g124z := 4141414141414141C;
g125z := 6666666666666666C;
g130z := 70000T;
g131z := 74000T;
g132z := 30C; (* ??? *)
g133z := '-', '+';
defects := 0
end
