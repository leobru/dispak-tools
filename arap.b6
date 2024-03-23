user 419900зс5^
dis 31(2113)32(77)33(2148-440)34(2048)37(1234-wr)^
eeb1a3
*name
*libra:13
*call ficmemory
*trans:newpasc,,320000
(*=y+,u-,p-,s5,a4,l1*)program АРАП(input, output);
label 1745;
const
  sp = ' ';
  eqs = '====';
  lf = '_012';
  hash = '_043';
  eofMark1 = '*READ_201';
  eofMark2 = 'OLD_312_012_012';
  ctx = 750000B;
  uj = 3000000B;
type bitset = set of 0..47;
word = packed record case integer of
0:(a:alfa);
1:(i:integer);
2:(s:bitset);
3:(c:char)
end;
%
err = (unordered, badline, nolocation, badfirst, defined,
nodirective, notdubna, badparam, unclear); 
% 
% 
% Aligning line numbers to the executable
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
var line:array [1..85] of char;
page36 [74000B] : array[1..1024] of word;
page37 [76000B] : array[1..1024] of word;
pos,
rdPos,
wrPos,
lineNum,
upto,
reached,
source,
drum:integer;
done,
first:boolean;
cmd:integer;
% 
% 
% Reading a zone to page 36
% 
%
procedure rd;
var t:bitset;
_(
  t := bitset(source) * [30..47] + [13..16] + [8];
 besm(700000b : t);
 source := source + 1;
 rdPos := 1;
_);
%
%
% Writing a zone from page 37
%
%
procedure wr;
var t:bitset;
_(
  t := bitset(drum) * [30..47] + [13..17];
 besm(700000b : t);
 drum := drum + 1;
 if drum = 10040B then drum := 20000B;
 (q) exit q;
 wrPos := 1;
_);
%
%
%
%
%
%
%
% Checks if the end of file is reached.
% If false is returned, but the argument is equal to
% eofMark1, it needs to be copied to the output file.
% BUG: "a" is not initialized; lines starting with
% *READ<any char> will be affected.
%
function iseof(var a:alfa):boolean;
_( (* fixme: Must be ASN 64+8 instead of negation *)
  if alfa(-page36[rdPos].i) # '_000*READ' then iseof := false
  else _( a := eofMark1; rdPos := rdPos + 1;
    if rdPos = 1025 _then rd;
% fixme: Must be ASN 64+24 instead of negation
    iseof := alfa(-page36[rdPos].i) = '_000_000_000OLD';
  _)
_);
%
%
%
%
%
%
% The error "defined" is not used.
%
%
procedure error(e:err);
begin
case e of
unordered: writeln('*** РЕДАКЦИИ НЕ УПОРЯДОЧЕНЫ ***');
nolocation: writeln('*** НЕТ КООРДИНАТ ФАЙЛА     ***');
badline: _(
    writeln('*** НОМЕР СТРОКИ ВНЕ ФАЙЛА ***');
    writeln(line)
    _);
badfirst: _(
    writeln('*** ПЕРВАЯ СТРОКА - НЕ ДИРЕКТИВА ***');
    writeln(line)
    _);
defined: _(
    writeln('*** ФАЙЛ УЖЕ ОПРЕДЕЛЕН ***');
    writeln(line)
    _);
nodirective: writeln('*** НЕТ ЗАДАНИЯ ТРАНСЛЯТОРУ  ***');
notdubna: writeln('*** ФАЙЛ - НЕ ДУБНА ***');
badparam: _(
    writeln('*** ОШИБКА В ПАРАМЕТРАХ ДИРЕКТИВЫ ***');
    writeln(line)
    _);
unclear: _(
    writeln('*** НЕПОНЯТНАЯ СТРОКА ***');
    writeln(line)
    _)
end;
goto 1745
end;
%
% In line range specifications, line numbers may be
% separated by blanks or dashes.
procedure skipBlanks;
_(
  while (line[pos] = ' ') or (line[pos] = '-') do
    pos := pos + 1;
_);
%
%
%
%
%
%
%
%
%
function isdigit(l2a1z:char):boolean;
_(
  isdigit :=  ('9' >= l2a1z) and (l2a1z >= '0');
_);
%
%
%
%
%
%
%
%
%
%
function getInt(base:integer):integer;
var i:integer;
_(
  i := 0;
  while isdigit(line[pos]) do
  _(
    i := i*base + ord(line[pos]) - ord('0');
    pos := pos + 1;
  _);
  getInt := i;
_);
%
%
function toKOI8(c:char):char;
_(
 if (c >= '_140') and (c < '_200') then
    toKOI8 := chr(ord(c) + 128)
 else
     toKOI8 := c;
_);
%
%
%
%
%
%
%
%
%
%
%
%
function word2KOI8(w:alfa):alfa;
var i:integer; a:array[1..6] of char;
_(
  unpck(a[1], w);
  for i := 1 to 6 do _(
   w[i] := toKOI8(a[i]);
  _);
  word2KOI8 := w
_);
%
%
%
%
%
%
%
%
%
%
%
procedure readLine;
_(
  pos := 1;
  while not eoln(input) do
  _(
    line[pos] := input@;
    pos := pos + 1;
    get(input);
  _);
  get(input);
  line[pos] := lf;
  pos := 1;
_);
%
%
%
%
%
%
%
%
%
%
%
%
%
%
procedure copyLine;
var a:alfa;
_(
  if wrPos = 1025 then
    wr
  else
  _(
    page37[wrPos].i := lineNum;
    page37[wrPos].a[1] := '_377';
    wrPos := wrPos + 1;
  _);
  if wrPos = 1025 then
    wr;
  repeat a := page36[rdPos].a;
    page37[wrPos].a := word2KOI8(page36[rdPos].a);
    wrPos := wrPos + 1;
    rdPos := rdPos + 1;
    if wrPos = 1025 then
      wr;
    if rdPos = 1025 then
      rd;
  until a[6] = lf;
  lineNum := lineNum + 1;
_);
%
%
%
%
%
%
%
%
%
%
%
%
procedure takeLines(silent:boolean);
var a:alfa;
_(
  (loop) while lineNum < upto do _(
    if iseof(a) then exit loop;
    if a = eofMark1 then
    _(
      if wrPos = 1025 then
        wr;
      page37[wrPos].a := eofMark1;
      wrPos := wrPos + 1;
    _);
    copyLine;
  _);
  if lineNum = upto then
    exit;
  if not silent then
    error( badline );
_);
%
%
%
%
%
%
%
%
%
procedure skipLines(last:integer);
var a:alfa;
%
%
%
%
%
%
procedure printCOSY(a:alfa);
var i, j, n:integer;
_(
  for i := 1 to 6 do
  _(
    if a[i] = lf then _( writeln; exit _);
    if a[i] < '_200' then write(toKOI8(a[i]))
    else _(
      n := ord(a[i])-128;
      for j := 1 to n do write(sp);       
    _)
  _)
_);
%
%
_( (* skipLines *)
 while lineNum <= last do
 _(
   if rdPos = 1025 then
     rd;
   if iseof(a) then
     error( badline );
   write(lineNum:8, ' : ');
   if a = eofMark1 then
     printCOSY( a );
%
   repeat
     a := page36[rdPos].a;
     printCOSY (page36[rdPos].a);
     rdPos := rdPos + 1;
     if rdPos = 1025 then
       (q) rd;
   until a[6] = lf;
   lineNum := lineNum + 1;
  _);
  writeln(eqs, eqs, eqs, eqs);
_);
%
%
%
%
%
%
%
%
%
%
%
 procedure literal;
var a:alfa;
c:char; i:integer;
%
%
%
%
%
function compress:char;
var c:char;
_(
 c := '_200';
 while (line[pos] = sp) do _(
   c := succ(c);
   pos := pos + 1;
 _);
 compress := c;
 _);
%
%
%
_( (* literal *)
  if first then
    error( badfirst );
%
%
(loop) _(
  for i := 1 to 6 do
  _(
   c := line[pos];
   (q) if c = lf then _(
     a[i] := lf;
   _) else if c = sp then _(
     a[i] := compress;
   _) else _(
     a[i] := c;
     pos := pos + 1;
   _)
 _);
 if wrPos = 1025 then
    wr;
%
 page37[wrPos].a := a;
 wrPos := wrPos + 1;
 if c = lf then exit loop;
 goto loop;
 _);
 writeln(line);
_);
%
%
%
%
%
%
%
%
%
procedure setFile;
%
%
%
%
%
%
%
%
function isDubna:boolean;
var i:integer;
_(
  isDubna := true;
  for i := 1 to 15 do
    if page36[i].a[6] = lf then
      exit;
  isDubna := false;
_);
_( (* setFile *)
  skipBlanks;
  source := getInt(8);
  if source = 0 then
    error( badparam );
  lineNum := 1;
  rd;
  wrPos := 1;
  drum := 10000B;
  if not isDubna then
    error( notdubna );
  writeln('====', line);
  reached := 0;
_);
%
%
%
%
%
%
%
%
%
%
%
%
procedure insert;
_(
 first := false;
 skipBlanks;
 upto :=   getInt( 10 );
 if upto = 0 then
   error( badparam );
 if source = 0 then
   error( nolocation );
 if upto < reached then
   error( unordered );
 reached := upto;
 writeln('====', line);
 takeLines( false );
 _);
%
%
%
%
%
%
%
procedure replace;
var i:integer;
_(
  first := false;
  skipBlanks;
  upto := getInt( 10 );
  if upto = 0 then
    error( badparam );
  if upto < reached then
    error( unordered );
  if source = 0 then
    error( nolocation );
  reached := upto;
  skipBlanks;
  i :=   getInt( 10 );
  if i = 0 then
    i := upto;
  takeLines( false );
  writeln('====', line);
  skipLines( i );
_);
%
%
%
%
%
%
procedure translate;
_(
  writeln('====', line);
  done := true;
  upto := 99999;
  takeLines( true );
  if wrPos = 1025 then wr;
  page37[wrPos].a := eofMark1;
  wrPos := wrPos + 1;
  (q) if wrPos = 1025 then wr;
  page37[wrPos].a := eofMark2;
  wr;
_);
%
%
%
%
%
%
%
%
%
%
%
%
%
procedure parse;
var c:char; i:integer;
_(
  writeln(eqs, eqs, eqs, eqs);
  c := line[pos];
  while (line[pos] <> sp) and (line[pos] <> lf) do
  	pos := pos + 1;
  case c of
    'B':
       insert;
    'З':
       replace;
    'T':
       translate;
    'Ф':
       setFile;
    others:
       error ( unclear )
  end;
_);
% The next function is for code alignment only
function fileInit(a:integer):alfa;
_(
 fileInit := '_052_233_260_327_102_200';
 fileInit := '_000_000_051_273_015_164';
 fileInit := '_052_375_164_303_135_012';
 fileInit := '_000_013_365_323_015_164'; (q)exit q;(q)exit q;
_);
begin
 drum := 0;
 done := false;
 first := true;
 get(INPUT);
%
%
 while not eof(INPUT) and not done do
 _(
  readLine;
  skipBlanks;
  if line[pos] = hash then _(
    pos := pos + 1;
    literal;
  _) else if line[pos] = lf then
    error ( unclear )
  else
    parse;
  _); (* 3310 *)
  if not done then
    error ( nodirective );
  cmd := 1706002C;
  (q) besm(ctx : page37[1]);
  cmd := 110600203002000C;
  (q) besm(ctx : page37[2]);
  cmd := 10010000310000C;
  (q) besm(ctx : page37[3]);
  (q) besm(uj : page37); (* fixme *)
1745: (q)exit q;(q)exit q;(q)exit q;
end.
*perso:311160,cont
*perso:320200,cont
*no li
*assem
 Р/ВООТ:,NАМЕ,DТRАN  /01.06.84/
 Р/СОDЕR:,SUВР,
 РRОGRАМ:,SUВР,
 ,WТС,P/CODER+2
 1,VТМ,
 *1:1,UTM,-1
 1,VZМ,РRОGRАМ
 ,ARX,=100 0000 0001
 ,АТХ,P/CODER
 ,*70,P/CODER
 ,XTA,P/CODER
 ,UJ,*1
 ,END,
*table:p/coder(w*370000,l*2)
*main pascoder
*execute
*end file
``````
еконец
