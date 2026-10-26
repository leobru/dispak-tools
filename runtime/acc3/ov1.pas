(*=p-,t-,s8,y+,o-,a4,w+*)
program ov1(input, output,
    c20634, c20635, c20636, c20637, c20640, c20641, c20643,
    c20644, c20652, c20653, c20654, c20655, c22331, c22551,
    c22552, c22553, c22554, c22555, c22556);
type bitset = set of 0..47;
     a4 = packed array [1..4] of char;
     s5 = set of 0..4;
     digits = array [0..23] of char;
     long = record hi, lo: integer end;
     word3 = record ext, lib, name: alfa end;
     name12 = packed array [0..20] of char;
     pt = @entry;
     words = array [0..3] of integer;
     pw = @words;
     t0 = array [0..5] of alfa;
     t1 = array [1..58] of t0;
     r2 = packed record f1: 0..1023; f2: 0..31; f3: 0..4095;
                 f4: 0..2097151; f5: integer end;
     t2 = array [1..23] of r2;
     entry = packed record case integer of
          0: (w: integer);
          1: (sa: 0..3; sb, sc: 0..31; sd, se: boolean; sf: 0..127;
              sg: 0..134217727; s1x: boolean; sh: 0..3; si, sj: boolean;
              sk: 0..31; sl, sm: boolean; s1y: 0..3; sn: boolean;
              s1z: 0..1; s16: boolean; s1w: 0..15; so: 0..134217727;
              sx: 0..15);
          2: (va: boolean; vb, vc: 0..1023; vd: 0..134217727;
              ve: 0..1023; vf, vg, vh, vi, v1x, vj: boolean; v1y: 0..15;
              vk: boolean;
              case integer of
              0: (vl: 0..134217727; vp: 0..65535; v2x: 0..255;
                  vq: 0..16777215);
              1: (v1z: 0..8191; vm, vn: 0..127);
              2: (v1w: 0..32767; vo: 0..4095));
          3: (ba: 0..16777215; bb: 0..1023; b0x, bc: boolean;
              bd, be: 0..4095; b1x: 0..16777215; bf: 0..4095);
          4: (na: 0..31; nb: 0..127; nc: 0..4095);
          5: (bs: set of 0..23)
         end;
     lbits = packed record lv: 0..15; l4: 0..2097151;
                    lb, l26, l27, l28: boolean; l1: 0..524287 end;
     sect = packed record sa: 0..3; sb, sc: 0..31; sd, se: boolean;
              sf: 0..127; sg: 0..134217727; s1x: boolean; sh: 0..3;
              si, sj: boolean; sk: s5; sl, sm: boolean; s1y: 0..3;
              sn: boolean; s1z: 0..1; s16: boolean; s1w: 0..15;
              so: 0..134217727 end;
const banner = 'ACCEMБЛEP  Э1-KБ';
var g0050: bitset;
    g0051: t1;
    g0605: integer;
    g0606: pt;
    g0607, g0610: integer;
    g0611, g0612: pt;
    g0613: integer;
    g0614, g0617: entry;
    g0622: integer;
    g0623: pt;
    g0624, g0625, g0626: integer;
    g0627, g0630, g0631, g0632: pt;
    g0633, g0634, g0635: integer;
    g0636: t2;
    g0714: integer;
    g0715: pt;
    g0716: integer;
    g0717, g0720: pt;
    g0721: integer;
    g0722: pw;
    g0723: pt;
    g0724: array [0..63] of integer;
    g1024: pt;
    g1025: integer;
    g1026: word3;
    g1031, g1032, g1033, g1034: integer;
    g1035: pt;
    g1036, g1037, g1040: integer;
    g1041: pt;
    g1042: integer;
    g1043: pt;
    g1044, g1045: bitset;
    g1046, g1047, g1050, g1051, g1052, g1053, g1054: integer;
    g1055, g1056, g1057: integer;
    g1060: boolean;
    g1061, g1062, g1063, g1064, g1065, g1066, g1067: integer;
    g1070, g1071: integer;
    g1072, g1073, g1074, g1075, g1076, g1077, g1100: alfa;
    g1101, g1102, g1103, g1104, g1105, g1106, g1107: alfa;
    g1110, g1111, g1112, g1113, g1114, g1115, g1116: alfa;
    g1117, g1120, g1121, g1122, g1123, g1124, g1125: alfa;
    g1126, g1127: integer;
    g1130, g1131, g1132: a4;
    g1133: pt;
    g1134: integer;
    g1135: entry;
    g1140, g1141, g1142, g1143, g1144, g1145, g1146: integer;
    g1147, g1150, g1151, g1152, g1153, g1154, g1155: integer;
    g1156, g1157, g1160, g1161, g1162, g1163: integer;
    g1164: boolean;
    g1165, g1166, g1167: integer;
    g1170, g1171, g1172: boolean;
    g1173, g1174: integer;
    g1175, g1176: s5;
    c20634, c20635, c20636, c20637, c20640: integer;
    c20641: array [0..1] of integer;
    c20643: integer;
    c20644: array [0..5] of integer;
    c20652: integer;
    c20653: lbits;
    c20654: integer;
    c20655: array [0..1453B] of integer;
    c22331: array [1..144] of char;
    c22551, c22552: boolean;
    c22553: char;
    c22554, c22555, c22556: integer;
%
function x22563(n: integer): integer; assembler;
function x22567(w, n: integer): a4; assembler;
function x22570(w, n: integer): a4; assembler;
procedure x23460(a: pt; b: integer); fortran;
procedure x23461(a: pt; b: integer); fortran;
procedure x23470(a: pt; b: integer; var e: entry); fortran;
procedure x26567(a, b: integer; s: alfa; t: pt); fortran;
procedure x23734; assembler;
function x23752(c: char): boolean; assembler;
procedure x23761(n: integer); assembler;
procedure x23762(n: integer); assembler;
function x24033: integer; assembler;
procedure x24236(var a: digits; n, b: integer; var r: long);
   assembler;
function x24543(var r: long): integer; assembler;
procedure x23675(n: integer); assembler;
function x23745: boolean; assembler;
function x24336(s: alfa): integer; assembler;
function MKNAME(var name: name12; lib, ext: alfa;
                var dest: word3): integer; assembler;
function x26502(n: integer): pt; assembler;
function x26516: integer; assembler;
procedure x26626(a, b: integer); assembler;
procedure x24156(var a: alfa; var n: integer); assembler;
procedure x24222(var a: alfa); assembler;
procedure x24227(var a: alfa); assembler;
procedure x24172(var a: alfa); assembler;
function OPENF(var name: word3; writing: boolean;
               var descriptor: integer): integer; assembler;
%
procedure p04014(n: integer);
_( write(x22567(4, n)); write(x22570(4, n));
   write('_000' : 9 - x22563(n)) _);
%
function p04031(x: bitset): integer;
_( if 4 in x then p04031 := 46
   else if 5 in x then p04031 := 47
   else if 7 in x then p04031 := 30
   else if 6 in x then p04031 := 45
   else p04031 := 1 _);
%
procedure p04051;
var p: @integer; i: integer;
_( if 28 in g0050 then writeln;
   if g1060 then
      if (34 in g1044) and (g1057 + 3 <= g1047 div 2) then _(
         (q) for i := g1057 to g1047 div 2 + 2 do writeln(' ');
         g1057 := g1047 div 2 + 3
      _) else g1057 := g1047;
   if g1057 = g1047 then _( g1056 := g1056 + 1; g1057 := 0 _);
   if (g1057 = 0) or g1060 then _(
      if g1057 <> 0 then write(' ') else write('_014');
      write(g1130, g1131, g1132, ' ');
      if g1166 = 3 then _(
         x23460(g0606, g0607); p := ; p04014(p@);
         write('  CEKЦИЯ:');
         x23460(g0612, g0613); p := ; p04014(p@);
         write('  БЛOK:');
         p04014(g0636[g0635].f5)
      _) else write(' ':40);
      write(-g1056:4, '- M', g1071:1);
      if g1046 >= 76 then write(' ', g1102, g1103);
      writeln;
      write(g1072, g1073, ' ', g1104, g1105, g1106, g1107,
            g1110, g1111, g1112, g1113, g1114);
      if g1046 >= 76 then _(
         write(' БИБЛ: ', g1026.lib);
         if g1046 >= 91 then _(
            write('   ', g1076, g1077);
            if g1046 >= 110 then write('   ', banner)
         _)
      _);
      writeln;
      write(g1074, g1075, ' ', g1115, g1116, g1117, g1120,
            g1121, g1122, g1123, g1124, g1125);
      if g1046 >= 76 then _(
         write(' ', g1026.name, '.', g1026.ext);
         if g1046 >= 91 then _(
            write('   ', g1100, g1101);
            if g1046 >= 110 then
               write('   ', '5.04', ' OT ', '10.11.89')
         _)
      _);
      writeln;
      g1057 := g1057 + 3; g1060 := false; g1070 := -1
   _);
   g1057 := g1057 + 1
_);
%
procedure p04347(s: alfa);
var i: integer; p: @entry; j: integer;
%
function p04341(b: boolean): char;
_( if b then p04341 := '*' else p04341 := ' ' _);
%
_( besm(630004B, 150000B : 0); i := ;
   i := i - g1061;
   writeln('_014', '******', s, g1166:2, i div 50:5);
   writeln('ЭЛ MOД', g0607:5, g0605:5);
   if 40 in g0050 then _(
      (q) for i := 1 to g0605 do _(
         x23460(g0606, i); p := ;
         write(i:5, ' ':4); p04014(p@.w); writeln
      _);
      writeln(' ')
   _);
   writeln('CEKЦИИ', g0613:5, g0610:5);
   if 41 in g0050 then _(
      writeln('====CEKЦИЯ====ПAM=ГPA=ГЛ.=COПP=ФИK==ЭM=ИCX.=TEK.',
              '====AДPECA====');
      (q) for i := 16 to g0610 do _(
         x23460(g0612, i); p := ;
         write(i:4, ' '); p04014(p@.w);
         x23460(g0611, i); p := ;
         with p@ do
            writeln(sa:3, sb:4, p04341(sn):4, sh:5, p04341(si):4, sf:5,
                    p04341(sd):2, sc:2 oct, p04341(se):1,
                    p04341(sl):2, sk:2 oct, p04341(sm):1,
                    sg:7 hex, '-', so:7 hex, p04341(sj):1)
      _);
      writeln(' ')
   _);
   writeln('ЗHAЧ. ', g0624:5, g0622:5);
   if 42 in g0050 then _(
      write('=HOM.=OПP.=БЛOЧOK=CEKЦИЯ==ЗHAЧEHИE==ГЛ.=BX.=BH.=ДBA===');
      if g1166 = 1 then writeln('N TИ=') else _(
         write('=ATPИБYT=');
         if 37 in g1044 then writeln('=CTPOПP=ПOCЛ=') else writeln
      _);
      (q) for i := 1 to g0622 do _(
         x23460(g0623, i); p := ;
         with p@ do _(
            write(i:5, vb:5, vc:6, ve:7, ' ', p04341(vj), vd:9 hex,
                  p04341(va), p04341(vf):3, p04341(vh):4, p04341(vi):4,
                  p04341(vg):4);
            if g1166 = 1 then writeln(vo:8) else _(
               if vk then write(vm:8, vn:3, ' ':2)
               else write(' ':4, vl:9 hex);
               if 37 in g1044 then writeln(vp:6, vq:6) else writeln
            _)
         _)
      _)
   _);
   writeln('ДЛ.ЗH.', g0626:10);
   if 43 in g0050 then _(
      writeln('=HOM.====ЗHAЧEHИE====');
      (q) for i := 1 to g0626 do _(
         x23460(g0627, i); p := ;
         writeln(i:5, ' ', p@.w:12 hex)
      _);
      writeln(' ')
   _);
   writeln('YPOBHИ', g0635:5);
   if 44 in g0050 then _(
      writeln('==YPOBEHЬ=N БЛOKA=KOHTEKCT=HOM.TЗH==');
      (q) for i := 1 to g0635 + 1 do
         with g0636[i] do writeln(i:6, f1:9, f2:8, f3:9);
      writeln(' ')
   _);
   writeln('БЛOKИ ', g0714:10);
   if 45 in g0050 then _(
      writeln('==БЛOK==OTEЦ==ГЛ.==ПOДKЛЮЧ.==N TИ==', 'N ПФ==NOБM=');
      (q) for i := 1 to g0714 do _(
         x23460(g0715, i); p := ;
         with p@ do
            writeln(i:6, bb:6, p04341(bc):4, ' ':3, ba:8 oct, bd:6,
                    be:6, bf:6)
      _);
      writeln(' ')
   _);
   writeln('ИMEHA ', g0716:10);
   if 46 in g0050 then _(
      writeln('===ИMЯ OБ''EKTA===YP.==ПEPEДAHO=N TЗH=PEЗ.=');
      (q) for i := 1 to g0716 + 1 do _(
         x23460(g0720, i); p := ;
         write(i:6, ' '); p04014(p@.w);
         x23460(g0717, i); p := ;
         with p@ do writeln(na:4, ' ':2, p@.w:8 oct, nc:6, nb:5)
      _);
      writeln(' ')
   _);
   writeln('*KOHEЦ')
_);
%
procedure p17650;
label 1, 2;
var d3: integer;
    d4: integer;
    d5: array [5..28] of integer;
    d35: integer;
    d36: array [30..38] of integer;
    d47, d50: integer;
    d51: pt;
    d52: array [42..44] of integer;
    d55: array [0..9] of long;
    d101: integer;
    d102: integer;
    d103: array [0..2] of word3;
    d114: integer;
    d115: word3;
    d120, d121, d122, d123, d124: integer;
%
procedure p05214(k: integer);
var j: integer;
_( if g1166 = 0 then _(
      writeln('@':c22555);
      (q) for j := 0 to 5 do write(g0051[k][j]);
      writeln;
      goto 1
   _);
   if 1 in g0050 then _(
      writeln('@':c22555 + 7);
      writeln(c22553:3 oct, c22555:3, c22554:3 oct, c22556:3,
              ' П:', c22551:1 oct, ' M:', c22552:1 oct)
   _);
   c20643 := g1040;
   x23762(300); x23761(k); x23761(c22555);
   g1167 := g1167 + 1;
   g1164 := k <> 58;
   goto 2
_);
%
procedure p05306(c: char; k: integer);
_( if c22553 = c then x23734 else p05214(k) _);
%
function p05317: boolean;
_( p05317 := false;
   if x23752('-') then p05317 := true
   else if x23752('+') then
_);
%
function p05331(n: integer): alfa;
var i: integer; s: packed array [0..5] of char;
_( s := '      ';
   (q) for i := 0 to n - 1 do (r) _(
      if c20653.lb then s[i] := c22553 else p05214(6);
      x23734
   _);
   while c20653.lb do (q) x23734;
   p05331 := alfa(s)
_);
%
function p05365: integer;
var v: integer;
_( v := x24033; p05365 := ;
   if v = 7777777777777777C then p05214(6)
_);
%
procedure p05375(var r: long);
var col, n, d, b, cnt: integer; a: digits;
_( col := c22555; n := 0; b := 0; cnt := 0;
   (q) repeat
      if c20653.l28 then
      else if c20653.l27 then b := b + 1
      else if c20653.l26 then cnt := cnt + 1
      else exit q;
      d := c20653.lv;
      if n > 23 then p05214(31);
      a[n] := chr(d); n := n + 1; x23734; (r)
   until false;
   if n = 0 then p05214(31)
   else if (c22553 = 'H') or (c22553 = 'X') then _( x23734; b := 16 _)
   else if (cnt = 1) and (b = 0) and (d = 11) then _(
      b := 8; n := n - 1 _)
   else if cnt = 0 then b := 10 else p05214(31);
   x24236(a, n, b, r)
_);
%
function p05475: integer;
var v: long;
_( p05375(v); p05475 := x24543(v) _);
%
procedure p05506;
var p: @sect;
_( if g0613 = 0 then exit;
   x23460(g0611, g0613); p := ;
   with p@ do _( sm := g1170; sk := g1175; sl := g1171; s16 := g1172 _)
_);
%
procedure p05542;
var p: @sect;
_( x23460(g0611, g0613); p := ;
   with p@ do _(
      g1170 := sm; g1175 := sk; g1176 := ; g1171 := sl; g1172 := s16;
      g0607 := sf
   _)
_);
%
procedure p05566;
var i: integer; s: alfa; j: integer; nm: name12;
_( repeat
      i := 1;
      (q) repeat
         get(input); c22331[i] := input@; i := i + 1;
         if input@ = '_012' then exit q
      until false;
      write(c22331:144); writeln(output);
      c22551 := false; c22552 := ; x23675(1);
      c22551 := true; x23675(c22555);
      if not x23745 then _(
         i := x24336(p05331(3));
         c22551 := false; x23675(c22555);
         case i of
         1: g1044 := g1044 - [35];
         2: if c20653.l28 then _(
               g1126 := 0; g1127 := ;
               (q) for i := 0 to 5 do (r) _(
                  if not c20653.l28 then p05214(31);
                  g1126 := g1126 * 8 + c20653.lv; x23734
               _);
               p05306(',', 8);
               while c20653.l28 do (q) _(
                  g1127 := g1127 * 8 + c20653.lv; x23734
               _)
            _) else _(
               i := 0;
               while (i < 20) and not x23745 do _(
                  nm[i] := c22553; x23734; i := i + 1
               _);
               nm[i] := '_012';
               i := MKNAME(nm, 'MOДYЛИ', 'MOД   ', d115);
               if i = 0 then i := OPENF(d115, true, g1126);
               if i <> 0 then p05214(3);
               g1127 := g1126 div 262144;
               g1126 := g1126 mod 262144
            _);
         4: repeat g0050 := [p05475] / g0050 until not x23752(',');
         5: _( g1046 := p05475;
               if x23752('*') then g1047 := p05475 _);
         6: g1044 := g1044 + [34];
         7: _( if p05317 then d3 := -1 else d3 := 1;
               if x23752('*') then d3 := d3 * 99999999
               else d3 := d3 * p05475 _);
         8: _( g1044 := g1044 - [10..14];
               repeat
                  s := p05331(1);
                  case s[1] of
                  'Y': i := 12; 'E': i := 13; 'M': i := 11;
                  'Л': i := 10; 'K': i := 14; '$': i := 0;
                  others: p05214(32)
                  end;
                  g1044 := [i] + g1044
               until not x23752(',') _);
         9: _( g1044 := g1044 - [0..6];
               repeat
                  s := p05331(1);
                  case s[1] of
                  'И': i := 0; 'A': i := 1; 'K': i := 2; 'З': i := 3;
                  'H': i := 4; 'T': i := 5; 'П': i := 6;
                  others: p05214(32)
                  end;
                  g1044 := [i] + g1044
               until not x23752(',') _);
         10: _( g1050 := p05475; p05306(',', 8);
               g1051 := p05475 + g1050; p05306(',', 8);
               g1052 := p05475 + g1051 _);
         11: g1044 := g1044 + [36];
         12: g1044 := g1044 + [30];
         13: g1044 := g1044 + [32];
         14: if x23745 then g1044 := g1044 - [24..29] + [26, 28, 37]
            else _(
               g1044 := g1044 + [37] - [24..29];
               repeat
                  s := p05331(1);
                  case s[1] of
                  'A': g1044 := g1044 + [25];
                  'C': g1044 := g1044 + [26];
                  'O': g1044 := g1044 + [27];
                  '_363': g1044 := g1044 + [28];
                  'H': g1044 := g1044 + [29];
                  'Л': g1044 := g1044 + [24]
                  end
               until not x23752(',')
            _);
         16: _( besm(640001B); (q) _);
         17: g1044 := g1044 + [38];
         18: g1044 := g1044 + [39];
         19: _( i := 0;
               repeat
                  d55[i].hi := p05475; p05306(':', 11);
                  d55[i].lo := p05475; i := i + 1
               until not x23752(',');
               d101 := i _);
         20: exit;
         21: if c20653.l28 then _(
               g1026.ext := '*****_000'; g1026.lib := '******';
               g1031 := 0;
               (q) for i := 0 to 5 do (r) _(
                  if not c20653.l28 then p05214(31);
                  g1031 := g1031 * 8 + c20653.lv
               _);
               mapia(g1031, g1026.name)
            _) else _(
               i := 0;
               while (i < 20) and not x23745 do _(
                  nm[i] := c22553; x23734; i := i + 1
               _);
               nm[i] := '_012';
               i := MKNAME(nm, 'TEKCTЫ', 'TEKCT ', g1026);
               if i = 0 then i := OPENF(g1026, false, g1031);
               if i <> 0 then p05214(3);
               g1031 := g1031 mod 262144;
               g1026.ext[6] := '_000'
            _);
         22: g1044 := g1044 + [31];
         others: p05214(12)
         end;
         if not x23745 then p05214(6)
      _)
   until eof(input)
_);
%
procedure p06413;
var b, j: integer; p: pt;
_( b := ord(x26502(1105));
   g1034 := x26516;
   g1133 := ptr(b + 273);
   if 37 in g1044 then g0723 := x26502(1024);
   g0606 := ptr(b + 0);
   x26567(1, 127, 'ЭЛ.MOД', g0606);
   g0605 := 0; g0607 := 0;
   g0611 := ptr(b + 8);
   x26567(3, 1023, 'CEKЦИИ', g0611);
   g0612 := ptr(b + 28);
   x26567(1, 1023, 'CEKЦ 1', g0612);
   g0610 := 15; g0613 := 0;
   (q) for j := 1 to 15 do (r) _(
      g0614.sx := j; x23470(g0611, j, g0614)
   _);
   g0623 := ptr(b + 39);
   x26567(ord(37 in g1044) + 2, 4095, 'ЗHAЧ. ', g0623);
   g0622 := 1; g0625 := 0;
   x23461(g0623, 1); p := ;
   with p@ do _(
      va := false; vb := 0; vc := 1; vd := 0; ve := 1023;
      vf := false; vg := false; vh := false; vi := true; vo := 1;
      if 37 in g1044 then _( vp := 0; vq := 0 _)
   _);
   g0627 := ptr(b + 95);
   x26567(2, 1023, 'ДЛИЗHA', g0627);
   g0626 := 0;
   g0632 := ptr(b + 110); g0634 := 0; g0633 := 1;
   g0630 := ptr(b + 189); g0631 := ptr(b + 174);
   g0635 := 1;
   g0636[1].f3 := 1; g0636[1].f2 := 1; g0636[1].f1 := 1;
   g0715 := ptr(b + 258);
   x26567(2, 1023, 'БЛOKИ ', g0715);
   g0714 := 1;
   x23461(g0715, 1); d51 := ;
   with d51@ do _( bs := []; bb := 0; bc := true; bd := 1 _);
   g0717 := ptr(b + 212);
   x26567(1, 4095, 'ИMEHA ', g0717);
   g0720 := ptr(b + 235);
   x26567(1, 4095, 'ИMEHA1', g0720);
   g0716 := 1;
(*=c-*)
   x23470(g0720, 1, 2443270500000000C); x23470(g0717, 1, 0C);
(*=c+*)
   g1025 := 0;
   g1024 := ptr(b + 273); g0721 := 1;
   g0722 := ptr(b + 337);
   g0722@[2] := 0544273443440000C; g0722@[3] := 0;
   d47 := -1; d4 := 0; d35 := 0;
   x26626(g1031, g1034);
   d115 := g1026;
   d123 := 0; d124 := 0; g1033 := 0; d120 := 0; g1042 := 0;
   g1035 := ptr(b + 849); c20652 := ;
   g1041 := ptr(b + 593);
   x26567(1, 63743, 'ПPOMП ', g1041);
   g1043 := ptr(b + 337);
   g1056 := 0; g1057 := g1047;
   g1130 := '    '; g1131 := ; g1132 := ;
   if d3 >= 0 then g1044 := g1044 + [21, 33];
   if d101 <> 0 then g1044 := g1044 + [33];
   if 37 in g1044 then g1044 := g1044 + [22];
   g1167 := 0; g1045 := g1044;
   g1053 := g1050; g1054 := g1051; g1055 := g1052;
   g1104 := '      '; g1105 := ; g1106 := ; g1107 := ; g1110 := ;
   g1111 := ; g1112 := ; g1113 := ; g1114 := ;
   x24156(g1072, g1071); x24222(g1100); x24227(g1076); x24172(g1102);
   g1074 := '  :  :'; g1075 := '  _000_000_000_000';
   besm(530010B, 150000B : 0); b := ;
   b := b div 50;
   g1074[1] := chr(b div 36000 + 48);
   g1074[2] := chr(b mod 36000 div 3600 + 48);
   g1074[4] := chr(b mod 3600 div 600 + 48);
   g1074[5] := chr(b mod 600 div 60 + 48);
   g1075[1] := chr(b mod 60 div 10 + 48);
   g1075[2] := chr(b mod 10 + 48)
_);
%
_( 1: p05306('-', p05365); g1102 := p05331(3); g1060 := p05317;
   2:
_);
%
_( p17650; p04347(g1102); p04051; p04014(1); g1071 := p04031([]) _).
