(*=s7,s8,p-,t-,m-,y+,l1,o-*)
program main(output);(*=a1*)label 3230;
% Restored from тестац.bin (memory image from 02000) by disassembly,
% after the similar program MARK3 (programs/mark3); build with
%   PERSO="311160 320100" tools/buildimg.sh тестац.pas тестац.bin
% (тестац.pre gives stubs for the FORTRAN routines E4233, E4243).
% Names are invented (no post-mortem tables, p-); g... are globals
% named by their offsets.  The data, the globals and the constant
% pool contents match.  ord(not wr)*16384 in L2624 was computed by
% adding to the exponent (слпа 64+14), as this compiler does under m-.
% o- keeps the load right after a store and one constant table, as
% the original compiler did; the one load it dropped is written as
% `g40z.a[5] := ;` in termio.  The code matches except for
% differences caused by the compiler and library versions:
%  - the three i := i + 1 in vvod used the library constant 1
%    (17(M1)), as for loops do, not a pool constant;
%  - the library (from 03516) is a different version.
const
boilerplate='< ТЕСТ УСТРОЙСТВ ВВОДА-ВЫВОДА = (ВЕРСИЯ ОТ 88/11/11) >';
(*=a2*)c1='ЬЬЬЬЬЬЬ';(*=a1*) (* unused *)
type charset=set of '0'..'П';
bitset=set of 0..47;
line=array [0..80] of char;
mode=(m0,m1,m2,m3);
var g40z, g41z: packed record case integer of
0:(a:packed array [0..7] of 0..63);
1:(s1:set of 0..41; s2:set of 0..5);
2:(s3:set of 0..7; b,x,c:boolean)
end;
g42z, protocol, batch, g45z,
g46z, g47z, g48z, g49z, g50z, g51z:boolean;
g58z, g59z, tty, len:integer;
IO:text;
cmd:alfa;
skipSet:charset;
g130z, testmode, g132z:integer;
g133z:packed record vol, op:0..63; rest:set of 0..35 end;

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

procedure L2054(var a:alfa); label 2056;
var i:integer;
_(
2056: a := '_377     ';
for i to 6 do _(
if eof(IO) then exit;
if g48z and (IO@ = '>') then _( get(IO); goto 2056 _);
if IO@ in skipSet then exit;
a[i] := IO@;
len := i;
get(IO)
_);
(q);
skipUntil(skipSet);
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

procedure restart; _( besm(3000002B) _);

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
 l3a1z and g46z: _( write( '*' ); i := i + 1 _);
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
  if g50z and g49z and not g51z then GOTO 3230;
 _);

procedure L2250;
_(
  s := (s * [22,23]);
  g50z := false;
  select
  (s = []) or (s = [22,23]): restart;
   (m = m3) and (s = [23]): _(
   j := (j + 1);
   if (j = 2) then restart else termio( m3 );
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
      L2250
   _);
   if not g51z then rewrite(IO);
   g51z := false;
   _);
   m3: (L2413) _(
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
    _) _else _(
    toBuf;
    g40z.b := true;
    g40z.c := g46z;
      besm(710000B : g40z); (q);
      s := ;
      L2250;
      rewrite(IO);
      i := 0;
      while (buf[i] <> '_377') and (i <= 143) do _(
      write(IO, buf[i]);
      i := i + 1;
      _)
    _);
    if protocol then _( hardCopy(true); writeln _);
    if g47z and not g46z then _( g51z := true; termio(m2) _);
    reset(IO);
    L2054(cmd);
    if cmpAlfa(cmd, 'КНЦ   ', (3)) then restart else _(
       if (cmpAlfa( cmd, 'НАЧ   ', (3))) then
       GOTO 3230;
       if (cmpAlfa( cmd, 'Э.    ', 2)) then _(
       flip(g47z);
       goto L2413 _);
       if (cmpAlfa( cmd, 'А.    ', 2)) then _(
       flip( protocol );
       goto L2413 _);
       if (cmpAlfa( cmd, 'V.    ', 2)) then _(
        flip( g42z );
        goto L2413 _);
    _);
    reset(IO)
   _)
   end
_);

function getNum(l2a1z:integer):integer;
_var l2v1z:integer;
_(
 termio( m3 );
 skipsp;
 l2v1z := 0;
 while not eof(IO) and (ord(IO@) < l2a1z) do _(
 l2v1z := l2v1z * l2a1z + ord(IO@);
 get(IO);
 _);
 getNum := l2v1z;
_);

function confirm:boolean;
_(
 termio( m3 );
 confirm := isYes;
_);

function L2660(vol:integer):boolean;
label 2715;
var st:packed record x:set of 0..45; w, r:boolean end;
l2v2z:integer;

procedure L2624(rd, wr:boolean);
var pw:integer;
_(
 g46z := true;
 if rd then _(
  rewrite(IO);
  write(IO, 'ПАРОЛЬ ');
  if wr then write(IO, 'ЗАПИСИ: ') else write(IO, 'ЧТЕНИЯ: ');
  pw := getNum(8);
 _) else pw := 0;
 pw := ord(not wr) * 16384 + pw;
 besm(400015B);
 g133z := g133z;
 besm(500121B); (q);
 g46z := false;
_);

_(
 g133z := g133z;
 besm(500127B); st := ;
 l2v2z := vol;
 besm(360067B, 400016B, 70620777B);
 g133z.op := 63;
 g133z.vol := vol;
 besm(500131B); (q);
 besm(04150011B); l2v2z := ;
 rewrite(IO);
 case l2v2z of
 0: _( L2624(st.r, false); L2624(st.w, true); L2660 := true _);
 1: _( write(IO, ' ТОМА НЕТ!');
       2715: termio(m2); L2660 := false _);
 2: _( write(IO, ' ТОМ ЗАНЯТ!'); goto 2715 _);
 others: _( write(IO, ' НЕТ!'); goto 2715 _)
 end
_);

procedure kosoy;
var i, j:integer;
_(
 for i := 0 to 23 do _(
  for j := 0 to 78 do write(IO, chr((i + j) mod 96));
  termio(m2)
 _)
_);

procedure vvod;
var c, i:integer;
ok:boolean;
a:line;
_(
 for i := 0 to 78 do write(IO, chr(i mod 32 + 32));
 termio(m2);
 write(IO, 'ПОМЕСТИТЕ КУРСОР В КОНЕЦ ПРЕДЫДУЩЕЙ СТРОКИ');
 write(IO, ' И НАЖМИТЕ КЛАВИШУ "ВВОД"');
 termio(m3);
 i := 0;
 while not eof(IO) do _( a[i] := IO@; get(IO); i := i + 1 _);
 a[i] := '_377';
 rewrite(IO);
 write(IO, 'ПРИНЯТАЯ СТРОКА ИМЕЕТ ВИД:');
 termio(m2);
 i := 0;
 while a[i] <> '_377' do _( write(IO, a[i]); i := i + 1 _);
 termio(m2);
 ok := true;
 i := 0;
 repeat
  if i < 79 then c := i mod 32 + 32 else c := 255;
  ok := ok and (chr(c) = a[i]);
  if chr(c) <> a[i] then _(
   write(IO, 'В ПОЗИЦИИ ', i:2, ' ВМЕСТО КОДА ', c:3 oct, '(', chr(c),
         ') ОБНАРУЖЕН КОД ', ord(a[i]):3 oct, '(', a[i], ')');
   termio(m2)
  _);
  i := i + 1;
 until (a[i-1] = '_377') or (c = 255);
 if ok then _( write(IO, 'СТРОКИ СОВПАЛИ!'); termio(m2) _)
_);

procedure E4233; fortran;

procedure acpu;
var i, j:integer;
_(
 protocol := true;
 write(IO, '** ТЕСТ ПРОВЕРКИ РАБОТЫ  А Ц П У **':79);
 termio(m2);
 g42z := false;
 for j := 0 to 95 do _(
  for i := 0 to 127 do write(IO, chr((i + j) mod 96));
  termio(m2)
 _);
 write(IO, '_214', '_214', '_214', '_214');
 termio(m2);
 for j := 0 to 95 do _(
  if (j < 48) and (j in [0,10,35]) or
     (j > 47) and ((j - 48) in [15,23,40]) then
   E4233;
  write(IO, chr(j), '_174', '_177');
  termio(m2)
 _);
 besm(620042B);
 protocol := false;
 g42z := true
_);

procedure E4243; fortran;

_(
  termio(m0);
  rewrite(IO);
  write(IO, boilerplate);
  termio(m2);
  besm(14440015B, 16471717B, 501212B); (q);
  besm(64440003B);
  skipSet := [' '];
  E4243;
3230: if g45z then restart;
  testmode := 0;
  repeat
   rewrite(IO);
   write(IO, 'РЕЖИМ (КОСОЙ,ВВОД,АЦПУ,КНЦ) : ');
   termio(m3);
   L2054(cmd);
   if cmpAlfa(cmd, 'КОСОЙ ', 5) then testmode := 1
   else if cmpAlfa(cmd, 'ВВОД  ', 4) then testmode := 2
   else if cmpAlfa(cmd, 'АЦПУ  ', 4) then testmode := 3 else;
  until testmode <> 0;
  rewrite(IO);
  case testmode of
  1: kosoy;
  2: vvod;
  3: acpu
  end;
  goto 3230
_).data
g40z := 1024000410000033C, 120000001000000C;
g51z := true;
g58z := 777777777777B;
g59z := 0;
g132z := 76000C
end
