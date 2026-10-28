(*=p-,t-,s8,y+,o-,a4,w+*)
program ov2(input, output,
    za, zb, zc, zd, ze, zf, zg, zh, zi, zj, zk,
    zo, zp, zq, zr, zs, zt, zu);
% Оверлей 2 ассемблера АСС3 (том 4001, зоны 0152-0167), восстанавливаемый
% по коду. Сборка и сравнение с оригиналом:
%   python3 runtime/acc3/ovtry.py ov2 runtime/acc3/ov2.pas --full --pads
% Таблиц PMD нет, все имена придуманы, как в ov1.pas: по адресам
% процедур, глобалов, локалов драйвера и входов в область рантайма
% (адреса оверлея 2). Общие блоки za..zu - параметры программы после
% *OUTPUT* (32560-33026), с именами блоков оверлея 1 того же назначения.
% Весь код пользователя (04014-31340) и пул (650 слов) совпадают с
% оригиналом, кроме одного слова: 16305 (p16210, -(48 - m)) в оригинале
% знак 20(М1) (все единицы), mypas дает знак 15(М1) (-1), как и сам
% оригинал для -x34423(d83) в 25127; конструкции, дающей первое, нет.
type bitset = set of 0..47;
     a4 = packed array [0..3] of char;
     a6 = packed array [0..5] of char;
     a8 = array [0..7] of integer;
     s5 = set of 0..4;
     u2 = 0..3; u4 = 0..15; u5 = 0..31; u7 = 0..127; u8 = 0..255;
     u10 = 0..1023; u12 = 0..4095; u16 = 0..65535; u20 = 0..1048575;
     u24 = 0..16777215; u27 = 0..134217727;
     long = packed record case integer of
          0: (hi, lo: integer);
          2: (h2: integer; lw: u16; lf: boolean);
          3: (h3: integer; m0: u20; mb: boolean; m1: 0..8191;
              ms, mu: u7);
          4: (h4: integer; m2: 0..2097151; mx: u27);
          5: (h5: integer; n20: u20; ls: set of 1..27)
         end;
     word3 = record ext, lib, name: alfa end;
     pt = @entry;
     t0 = array [0..5] of alfa;
     t1 = array [1..58] of t0;
     r2 = packed record f1: u10; f2: u5; f3: u12;
                 f4: 0..2097151; f5: integer end;
     t2 = array [1..23] of r2;
     nv = record nm: alfa; v: integer end;
     nvs = array [0..255] of nv;
     pw = @nvs;
     entry = packed record case integer of
          0: (w: integer);
          1: (sa: u2; sb, sc: u5; sd, se: boolean; sf: u7;
              sg: u27; s1x: boolean; sh: u2; si, sj: boolean;
              sk: u5; sl, sm: boolean; s1y: u2; sn: boolean;
              s1z: boolean; s16: boolean; s1w: u4; so: u27;
              sx: u4);
          2: (va: boolean; vb, vc: u10; vd: u27;
              ve: u10; vf, vg, vh, vi, v1x, vj: boolean; v1y: u4;
              vk: boolean;
              case integer of
              0: (vl: u27; vp: u16; v2x: u8;
                  vq: u24);
              1: (v1z: 0..8191; vm, vn: u7);
              2: (v1w: 0..32767; vo: u12);
              3: (v1v: u12; vr: 0..32767));
          3: (ba: u24; bb: u10; b0x, bc: boolean;
              bd, be: u12; b1x: u24; bf: u12);
          4: (na: u5; nb: u7; nc: u12; nd, ne: u12);
          5: (bs: set of 0..23);
          7: (e0: integer; el: long);
          8: (t0: u7; tc: s5; t1: 0..68719476735;
              t2: u5; tk: s5);
          10: (ww: array [0..2] of integer);
          11: (n0: u24; bt: set of 0..23);
          12: (ka: u16; kb: u8; kc: 0..63; kd: 0..262143);
          9: (u0: u7; ua: u2; ub: 0..1; uc: boolean; ud: 0..1);
          13: (w13: integer; y20: u20; vs: set of 1..27)
         end;
     ops = array [0..511] of integer;
     po = @ops;
     buf = array [1..144] of char;
     hx = packed array [0..11] of u4;
     hb = packed record case integer of
           0: (hw: bitset);
           1: (hk: u8; case integer of
               0: (ha: u24);
               1: (hc: u8; case integer of
                   0: (hd: u16);
                   1: (hm: u8; hbit: boolean));
               2: (x2: u2; x5: u5; xb, xc: boolean;
                   xd: u2; xs: s5);
               3: (h4a, h4b: u4));
           2: (hn: a4);
           3: (hg: u24);
           4: (hy: u16);
           5: (h32: 0..4294967295);
           6: (h4: u4; hv: set of 1..27)
          end;
     ahb = array [0..4095] of hb;
     ints = array [0..4095] of integer;
     r5 = packed record case integer of
          0: (s: bitset);
          1: (f01: u2; f2, f3, f4: 0..1);
          2: (fi: u5);
          3: (fs: s5)
         end;
     w12 = packed record case integer of
           0: (wa, wb, wc, wd, we, wf: boolean; wg, wh: 0..7);
           1: (wi: u12)
          end;
     w10 = packed record fa: u10; fc: 0..2047; fd: u27 end;
     a10 = array [0..4095] of w10;
     p10 = @a10;
     pint = @ints;
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
    g0627, g0630, g0631: pt;
    g0632: p10;
    g0633, g0634, g0635: integer;
    g0636: t2;
    g0714: integer;
    g0715: pt;
    g0716: integer;
    g0717, g0720: pt;
    g0721: integer;
    g0722: pw;
    g0723: pt;
    g0724: packed array [0..255] of w12;
    g1024: po;
    g1025: integer;
    g1026: word3;
    g1031, g1032, g1033, g1034: integer;
    g1035: pint;
    g1036: hx;
    g1037, g1040: integer;
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
    g1101, g1102, g1103: alfa;
    g1104: array [0..8] of a6;
    g1115, g1116: alfa;
    g1117, g1120, g1121, g1122, g1123, g1124, g1125: alfa;
    g1126, g1127: integer;
    g1130, g1131, g1132: a4;
    g1133: @ahb;
    g1134: a4;
    g1135: entry;
    g1140, g1142, g1144, g1146: long;
    g1150: array [1..12] of integer;
    g1164: boolean;
    g1165, g1166, g1167: integer;
    g1170, g1171, g1172: boolean;
    g1173: boolean;
    g1174: integer;
    g1175: r5;
    g1176: r5;
    za: char; (* 32560 *)
    zb: bitset; (* 32561 *)
    zc: integer; (* 32562 *)
    zd: integer; (* 32563 *)
    ze: integer; (* 32564 *)
    zf: array [0..1] of integer; (* 32565 *)
    zg: integer; (* 32567 *)
    zh: array [5..10] of integer; (* 32570 *)
    zi: pint; (* 32576 *)
    zj: integer; (* 32577 *)
    zk: integer; (* 32600 *)
    zo: buf; (* 32601 *)
    zp: boolean; (* 33021 *)
    zq: boolean; (* 33022 *)
    zr: char; (* 33023 *)
    zs: char; (* 33024 *)
    zt: integer; (* 33025 *)
    zu: integer; (* 33026 *)
%
function x33033(n: integer): integer; assembler;
function x33034(a, b: alfa): boolean; assembler;
function x33037(n: integer): a4; assembler;
function x33040(n: integer): a4; assembler;
procedure x33726(a: pt); fortran;
procedure x33727(a: pt; b: integer); fortran;
procedure x33730(a: pt; b: integer); fortran;
procedure x33731(a: pt; b: integer); fortran;
procedure x33735(a: pt; var b: hx); fortran;
procedure x33736(a: pt; var b: hx); fortran;
function x34423(a: pt): integer; fortran;
procedure x34465(a: pt; b: integer); fortran;
procedure x34751(n: integer; var r: long); assembler;
procedure x33732(a: pt; b: integer); fortran;
procedure x36036(a: pt; b: integer); fortran;
procedure x36070(a: pt); fortran;
procedure x34421(a: pt; b: integer); fortran;
procedure x34427(a: pt); fortran;
function x33036(a, b, c: integer): integer; assembler;
procedure x35701(var a, b, c: long); assembler;
procedure x35705(var a, b: long); assembler;
procedure x35702(var a, b, c: long); assembler;
procedure x35703(var a, b, c: long); assembler;
procedure x35704(var a, b: long; n: integer; var c: long); assembler;
procedure x35224(var a: long; b, c: integer; var d: long); assembler;
procedure x33740(a: pt; b: integer; var r: long); fortran;
procedure x33741(a: pt; b: integer; var r: long); fortran;
procedure x33742(a: pt; b: integer; var r: long); fortran;
procedure x34127(a, b: integer); assembler;
function x34246(var a: buf; var v: integer): boolean; assembler;
function x34323: integer; assembler;
procedure x34327(n: integer); assembler;
procedure x34513(n: integer); assembler;
procedure x34552; assembler;
function x34563: boolean; assembler;
procedure x34576(n: integer); assembler;
procedure x34577(n: integer); assembler;
procedure x34600(n: integer); assembler;
procedure x34601(a, b: integer); assembler;
procedure x34602(a, b: integer); assembler;
procedure x34603(a, b: integer); assembler;
procedure x34604(a, b, c: integer); assembler;
procedure x34643(var r: long); assembler;
procedure x34646(s: bitset); assembler;
procedure x34647(n: integer); assembler;
function x34770(var r: long): integer; assembler;
function x35706(var r: long): bitset; assembler;
function x34772(var r: long): integer; assembler;
procedure x35002(var a, b, c: long); assembler;
procedure x35020(var a, b, c: long); assembler;
procedure x35026(var a, b, c: long); assembler;
procedure x35037(var a, b, c: long); assembler;
procedure x35051(var a, b, c: long); assembler;
procedure x35065(var a, b: long); assembler;
procedure x35104(var a, b, c: long); assembler;
procedure x35120(var a: long; n: integer; var c: long); assembler;
procedure x35125(var a: long; n: integer; var c: long); assembler;
function x35114(var a: long; n: integer): integer; assembler;
function x33035(var a: long; var b: a8): integer; assembler;
procedure x35231(var a, b, c, d: long); assembler;
procedure x35733(a, b, c: integer; s: alfa; t: pt); fortran;
procedure x35777(a, b: integer; s: alfa; t: pt); fortran;
%
procedure p04014(n: integer);
_( write(x33037(n):4); write(x33040(n):4);
   write('_000' : 9 - x33033(n)) _);
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
         x33730(g0606, g0607); p := ; p04014(p@);
         write('  CEKЦИЯ:');
         x33730(g0612, g0613); p := ; p04014(p@);
         write('  БЛOK:');
         p04014(g0636[g0635].f5)
      _) else write(' ':40);
      write(-g1056:4, '- M', g1071:1);
      if g1046 >= 76 then write(' ', g1102, g1103);
      writeln;
      write(g1072, g1073, ' ', g1104[0], g1104[1], g1104[2],
            g1104[3], g1104[4], g1104[5], g1104[6], g1104[7],
            g1104[8]);
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
         x33730(g0606, i); p := ;
         write(i:5, ' ':4); p04014(p@.w); writeln
      _);
      writeln(' ')
   _);
   writeln('CEKЦИИ', g0613:5, g0610:5);
   if 41 in g0050 then _(
      writeln('====CEKЦИЯ====ПAM=ГPA=ГЛ.=COПP=ФИK==ЭM=ИCX.=TEK.',
              '====AДPECA====');
      (q) for i := 16 to g0610 do _(
         x33730(g0612, i); p := ;
         write(i:4, ' '); p04014(p@.w);
         x33730(g0611, i); p := ;
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
         x33730(g0623, i); p := ;
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
         x33730(g0627, i); p := ;
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
         x33730(g0715, i); p := ;
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
         x33730(g0720, i); p := ;
         write(i:6, ' '); p04014(p@.w);
         x33730(g0717, i); p := ;
         with p@ do writeln(na:4, ' ':2, p@.w:8 oct, nc:6, nb:5)
      _);
      writeln(' ')
   _);
   writeln('*KOHEЦ')
_);
%
procedure p31255;
label 1, 2, 3, 4;
type rec11 = record el: long; c: array [0..8] of integer end;
     arr11 = array [0..19] of rec11;
     prec11 = @rec11;
     b6 = record case integer of
          0: (bw: bitset); 1: (by: packed array [0..5] of u8) end;
     sect = packed record sa: u2; sb: u5; sc: s5; sd, se: boolean;
              sf: u7; sg: u27; s1x: boolean; sh: u2;
              si, sj: boolean; sk: s5; sl, sm: boolean; s1y: u2;
              sn: boolean; s1z: 0..1; s16: boolean; s1w: u4;
              so: u27; sx: u4; f4: 0..131071; sz: u27 end;
var d3, d4, d5, d6, d7: integer;
    d8: boolean;
    d9, d10, d11: integer;
    d12: array [0..3] of integer;
    d16: array [0..3] of word3;
    d28: array [0..16] of word3;
    d79, d80: integer; d81: hx; d82: integer;
    d83, d84: pt;
    d85: array [85..92] of integer;
    d93: boolean;
    d94, d95, d96: integer;
    d97: b6;
    d98, d99: integer;
    d100: boolean;
    d101: integer;
    d102: boolean;
    d103: array [0..8] of integer;
    d112: integer;
    d113: @arr11;
    d114, d115, d116, d117: integer;
    d118, d119, d120: integer;
    d121: boolean;
    d122: hx;
    d123, d124, d125: integer;
    d126: integer;
%
procedure p10227(a, b: integer); forward;
%
procedure p05214;
var v: integer;
_( while x34246(zo, v) do
      if d9 <> 0 then _( x34327(d12[d9]); d9 := d9 - 1 _)
      else p10227(58, 301);
   if d8 then d8 := false
   else if d7 <> 0 then d7 := d7 + 1
   else d6 := d6 + 1;
   d117 := d117 + 1
_);
%
procedure p05247;
var p: @sect;
_( if g0613 = 0 then exit;
   x33730(g0611, g0613); p := ;
   with p@ do _(
      so := d101; sj := d102; sm := g1170; s1y := g1174;
      (*=c-*) sk := g1175.s; (*=c+*) sl := g1171; s16 := g1172
   _)
_);
%
procedure p05320;
var p: @sect;
_( x33730(g0611, g0613); p := ;
   with p@ do _(
      d101 := so; d102 := sj; g1170 := sm; g1174 := s1y;
      g1172 := s16; (*=c-*) g1175.s := sk; (*=c+*) g1176 := ;
      g1171 := sl; g0607 := sf; g1173 := si
   _)
_);
%
function p05356(n: integer): integer;
var i, v: integer;
_( d79 := 0; d82 := d82 - n;
   (q) for i := 1 to n do _(
      d79 := d79 * 16 + g1036[g1042];
      if g1042 = 11 then _(
         g1042 := 0; x33735(g1041, g1036);
         v := x34423(g1041);
         if v mod 256 = 0 then x34465(g1041, v - 1)
      _) else g1042 := g1042 + 1
   _);
   p05356 := d79;
   if 10 * g1166 - 9 in g0050 then
      write('(', d79:n hex, ':', g1036[g1042]:1 hex, ') ');
   d79 := g1036[g1042]
_);
%
procedure p05442(a, b: integer);
var v: integer;
_( g1167 := g1167 + 1; zg := g1040;
   x34600(300); x34577(a); x34600(b);
   if d82 < 2 then _( g1164 := true; goto 2 _);
   while d82 <> 2 do (q) v := p05356(1);
   goto 1
_);
%
procedure p05472(var r: long);
var i: integer;
_( r := g1135.el;
   (q) for i := zh[p05356(1)] downto 1 do _(
      x35125(r, -4, r); x35120(r, p05356(1), r); (r)
   _)
_);
%
function p05525: integer;
var v: long;
_( p05472(v); p05525 := v.hi _);
%
procedure p05533(k: integer);
var p: pt;
_( x33730(g0623, k); p := ;
   with p@ do vl := d101 - vd + ord(d102)
_);
%
procedure p05551;
_( if d102 then _( d102 := false; d101 := d101 + 1 _)
   else d102 := true
_);
%
procedure p05561(a, b: integer);
_( if g1166 = 2 then p05442(a, b) else p10227(a, b) _);
%
function p05574(x: integer): integer;
var i: integer;
_( (q) for i := 0 to d112 do
      if d103[i] = x then _( p05574 := i; exit _);
   if d112 = 8 then p05561(42, 501);
   d112 := d112 + 1; d103[d112] := x;
   (q) for i := 0 to d114 - 1 do _( d113@[i].c[d112] := 0; (r) _);
   p05574 := d112
_);
%
procedure p05636(k: integer);
var i: integer;
_( if d114 = 20 then p05561(42, 502);
   with d113@[d114] do _(
      el := g1135.el; x34751(k, el);
      (q) for i := 0 to d112 do _( c[i] := 0; (r) _)
   _);
   d114 := d114 + 1
_);
%
procedure p05673(k: integer);
_( if d113@[d114 - 1].el.mb then
      case k of
      2: k := d113@[d114 - 1].el.ms;
      6: k := d113@[d114 - 1].el.mu;
      4: k := d113@[d114 - 1].el.mu - 1;
      5: k := d113@[d114 - 1].el.mu + d113@[d114 - 1].el.ms - 1;
      3: k := 64 - d113@[d114 - 1].el.mu - d113@[d114 - 1].el.ms + 1;
      1: k := 0;
      7: k := 64 - d113@[d114 - 1].el.ms;
      others: p05561(1, 503)
      end
   else
      case k of
      1: k := d113@[d114 - 1].el.mx;
      others: _( zb := zb + [7]; k := 0 _)
      end;
   d114 := d114 - 1; p05636(k)
_);
%
procedure p06047;
var i: integer;
_( with d113@[d114 - 1] do _(
      x35705(el, el);
      (q) for i := 0 to d112 do
         if c[i] <> 0 then _( zb := zb + [3]; exit _)
   _)
_);
%
procedure p06077;
var i: integer;
_( with d113@[d114 - 1] do _(
      x35065(el, el);
      (q) for i := 0 to d112 do c[i] := -c[i]
   _)
_);
%
procedure p06126(k: integer);
var i: integer;
_( with d113@[d114 - 1] do _(
      if k = 1 then x35125(el, 12, el) else x35701(el, g1140, el);
      (q) for i := 0 to d112 do
         if c[i] <> 0 then _( zb := zb + [3]; exit _)
   _)
_);
%
procedure p06166;
var i: integer; t: array [4..7] of integer; q: prec11;
_( q := ref(d113@[d114 - 2]);
   if not q@.el.mb then zb := zb + [7];
   x35224(d113@[d114 - 1].el, q@.el.ms + q@.el.mu - 1, q@.el.mu, q@.el);
   with d113@[d114 - 1] do
      (q) for i := 0 to d112 do
         if c[i] <> 0 then _( zb := zb + [3]; exit q _)
         else q@.c[i] := 0;
   d114 := d114 - 1
_);
%
procedure p06252;
var i: integer;
_( with d113@[d114 - 2] do _(
      x35703(d113@[d114 - 1].el, el, el);
      (q) for i := 0 to d112 do
         if (c[i] <> 0) or (d113@[d114 - 1].c[i] <> 0) then _(
            zb := zb + [3]; exit q
         _)
   _);
   d114 := d114 - 1
_);
%
procedure p06320;
var i: integer;
_( with d113@[d114 - 2] do _(
      x35702(el, d113@[d114 - 1].el, el);
      (q) for i := 0 to d112 do
         if (c[i] <> 0) or (d113@[d114 - 1].c[i] <> 0) then _(
            zb := zb + [3]; exit q
         _)
   _);
   d114 := d114 - 1
_);
%
procedure p06366;
var i: integer;
_( with d113@[d114 - 2] do _(
      x35104(el, d113@[d114 - 1].el, el);
      (q) for i := 0 to d112 do
         if (c[i] <> 0) or (d113@[d114 - 1].c[i] <> 0) then _(
            zb := zb + [3]; exit q
         _)
   _);
   d114 := d114 - 1
_);
%
procedure p06434;
var i: integer;
_( with d113@[d114 - 2] do _(
      x35701(el, d113@[d114 - 1].el, el);
      (q) for i := 0 to d112 do
         if (c[i] <> 0) or (d113@[d114 - 1].c[i] <> 0) then _(
            zb := zb + [3]; exit q
         _)
   _);
   d114 := d114 - 1
_);
%
procedure p06502(k: integer);
var i: integer;
_( with d113@[d114 - 2] do _(
      x35704(el, d113@[d114 - 1].el, k, el);
      (q) for i := 0 to d112 do _( c[i] := 0; (r) _)
   _);
   d114 := d114 - 1
_);
%
procedure p06536;
var i: integer;
_( with d113@[d114 - 2] do _(
      x35002(el, d113@[d114 - 1].el, el);
      (q) for i := 0 to d112 do c[i] := c[i] + d113@[d114 - 1].c[i]
   _);
   d114 := d114 - 1
_);
%
procedure p06601;
var i: integer;
_( with d113@[d114 - 2] do _(
      x35020(el, d113@[d114 - 1].el, el);
      (q) for i := 0 to d112 do c[i] := c[i] - d113@[d114 - 1].c[i]
   _);
   d114 := d114 - 1
_);
%
procedure p06644;
var i: integer;
_( with d113@[d114 - 3] do _(
      x35231(d113@[d114 - 1].el, el, d113@[d114 - 2].el, el);
      (q) for i := 0 to d112 do
         if (c[i] <> 0) or (d113@[d114 - 1].c[i] <> 0) or
            (d113@[d114 - 2].c[i] <> 0) then _(
            zb := zb + [3]; exit q
         _)
   _);
   d114 := d114 - 2
_);
%
procedure p06725(k: integer);
var i, t: integer;
_( with d113@[d114 - 2] do
      case k of
      1: _(
         x35026(el, d113@[d114 - 1].el, el); t := 0;
         (q) for i := 0 to d112 do
            if (d113@[d114 - 1].c[i] <> 0) or (c[i] <> 0) then
               if (d113@[d114 - 1].c[i] = 0) and (t <> 2) then _(
                  t := 1; c[i] := x34770(d113@[d114 - 1].el) * c[i]
               _) else if (c[i] = 0) and (t <> 1) then _(
                  t := 2; c[i] := d113@[d114 - 1].c[i] * x34770(el)
               _) else _( zb := zb + [3]; exit q _)
      _);
      2: _(
         x35037(el, d113@[d114 - 1].el, el);
         (q) for i := 0 to d112 do
            if (d113@[d114 - 1].c[i] = 0) and
               (c[i] mod x34770(d113@[d114 - 1].el) = 0) then
               c[i] := c[i] div x34770(d113@[d114 - 1].el)
            else _( zb := zb + [3]; exit q _)
      _);
      3: _(
         x35051(el, d113@[d114 - 1].el, el);
         (q) for i := 0 to d112 do
            if (c[i] <> 0) or (d113@[d114 - 1].c[i] <> 0) then _(
               zb := zb + [3]; exit q
            _)
      _)
      end;
   d114 := d114 - 1
_);
%
procedure p07246(a: boolean; b, c, d: integer; e: boolean);
var v8, v9, v10: integer; v11: pt; v12: boolean;
%
procedure p07177;
_( p04051; v9 := 0 _);
%
procedure p07204;
_( v9 := v9 + 1;
   if v9 = g1046 then _( writeln; p04051; write(' ':v8); v9 := v8 _)
_);
%
procedure p07217;
_( write(zr); if zr = '''' then v12 := not v12;
   x34552; p07204
_);
%
procedure p07232(k: integer);
_( if k < v9 then _( writeln; p07177 _);
   if k <> v9 then _( write(' ':k - v9); v9 := k _)
_);
%
_( if e then _( d118 := d118 + 1; if 33 in g1044 then p05214 _);
   if not (21 in g1044) then exit;
   if 5 in g1044 then _(
      if not e and ([2, 11] * g1044 <> [2, 11]) then exit
   _) else if (b <> 1) and (b <> 3) then exit;
   if e and (20 in g1044) then g1044 := g1044 - [20, 21];
   p07177;
   if e and (d11 <> d10) then _(
      za := '*';
      writeln(g1026.lib:(g1046 - 19) div 2 + 6, '/', g1026.name, '.',
            g1026.ext, '*':(g1046 - 19) div 2);
      za := ' '; p07177; d10 := d11
   _);
   if b = 99 then g1070 := -1
   else _(
      if not (5 in g1044) and not (b in [1, 3]) then writeln;
      if 1 in g1044 then _(
         if a and ((d101 <> g1070) or (b = 3) and not d102) then _(
            write(d101:7 hex); g1070 := d101;
            if d102 then write('+ ') else write('  ')
         _) else write(' ':9);
         v9 := v9 + 7 + 2
      _);
      if 2 in g1044 then _(
         v9 := v9 + 17;
         case b of
         0, 7: write(' ':17);
         1: write(c:4 hex, d:12 hex, ' ');
         2: if d = 0 then write('= ':9, c:7 hex, ' ')
            else write(' ':7, d:1 hex, '/', c:7 hex, ' ');
         3: _(
            if c = -1 then write(' 0 3A      ')
            else _(
               write(' '); v10 := x33036(c, 0, 268435456);
               write(v10:1 hex, ' ');
               v10 := x33036(c, 268435456, 1048576);
               if v10 <> 63 then write(v10:2 hex, ' ', c:5 hex)
               else write(c div 4096:4 hex, ' ', c:3 hex)
            _);
            if 3 in g1044 then _( write(' ':2); v9 := v9 - 4 _)
            else write(' ':6)
         _);
         4: write(alfa(c), d:4, ' ':7);
         5: if d < 0 then _(
               write(' ':7, -d:1 hex, ':');
               za := '-'; write('-':7, ' '); za := ' '
            _) else write(' ':7, d:1 hex, ':', c:7 hex, ' ');
         6: write(c:13, ':', d:2, ' ')
         end
      _);
      if 3 in g1044 then _(
         v9 := v9 + 7 + 1;
         if b = 3 then
            if d <> 0 then write(d:7 hex, ' ') else write(' ':8)
         else if 2 in g1044 then _( write(' ':4); v9 := v9 - 4 _)
         else if b = 2 then write(c:7 hex, ' ')
         else if b = 4 then write(d:7, ' ')
         else if b = 6 then write(c:4, ':', d:2, ' ')
         else write(' ':8)
      _);
      if not e then _( writeln; exit _);
      if 0 in g1044 then _(
         if d126 < 2 then write(' ':9)
         else _(
            x33730(g0715, d126); v11 := ;
            x33730(g0720, v11@.bd); v11 := ;
            p04014(v11@.w); write(' '); d126 := 0
         _);
         v9 := v9 + 8 + 1
      _)
   _);
   if 4 in g1044 then _(
      if d7 <> 0 then _( za := '.'; write(d7:g1032); za := ' ' _)
      else write(d6:g1032);
      if b = 7 then write('-') else write(' ');
      v9 := v9 + g1032 + 1
   _);
   if (5 in g1044) or (6 in g1044) then _(
      zp := true; zq := true; x34513(1); v8 := v9;
      if (zr = '*') or (zr = '!') then
         repeat p07217 until zr = '_012'
      else _(
         if 5 in g1044 then _(
            while (zr <> ' ') and (zr <> '_011') and (zr <> ':') and
                  not x34563 do _( p07217; (r) _);
            while (zr = '_011') or (zr = ' ') do _( x34552; (r) _);
            if zr = ':' then p07217 else _( write(' '); p07204 _);
            while (zr = '_011') or (zr = ' ') do _( x34552; (r) _);
            if not x34563 then _(
               v8 := v8 + g1050; p07232(v8);
               while (zr <> '_011') and (zr <> ' ') and not x34563 do
                  _( p07217; (r) _);
               write(' '); p07204; v8 := v8 - g1050
            _);
            while (zr = '_011') or (zr = ' ') do _( x34552; (r) _);
            if not x34563 then _(
               v12 := false; v8 := v8 + g1051; p07232(v8); v10 := 0;
               while (zr <> '_012') and (v12 or (zr <> ';')) do
                  if (zr = '_011') or (zr = ' ') then _(
                     v10 := v10 + 1; x34552
                  _) else _(
                     if v10 <> 0 then _(
                        v9 := v9 + v10;
                        if v9 < g1046 then write(' ':v10)
                        else _(
                           writeln; p07177; write(' ':v8); v9 := v8
                        _);
                        v10 := 0
                     _);
                     p07217
                  _);
               v8 := v8 - g1051
            _)
         _) else while not x34563 do _( x34552; (r) _);
         if (zr <> '_012') and (6 in g1044) then _(
            v8 := v8 + g1052 + 1; p07232(v8 - 1);
            while zr <> '_012' do _( p07217; (r) _)
         _)
      _)
   _);
   writeln
_);
%
procedure p10104(a: boolean; b: integer);
var t: boolean;
_( t := (21 in g1044) and not a;
   if t then g1044 := g1044 - [21];
   p07246(false, b, 0, 0, true);
   if t then g1044 := g1044 + [21]
_);
%
procedure p10127(a, b: integer; c: char);
var i: integer;
_( if g1047 - 1 = g1057 then _( p04051; writeln(' ') _);
   p04051; za := c;
   write('<':(g1046 - 36) div 2);
   (q) for i := 0 to 5 do write(g0051[a, i]);
   writeln('>', b:(g1046 - 36) div 2 - 1);
   za := ' '; g1070 := -1
_);
%
procedure p10173(a, b: integer);
_( p10127(a, b, '=');
   if a = 58 then exit;
   if 21 in g1044 then p07246(false, 0, 0, 0, true)
   else _(
      while d117 <> d118 do (q) _( p05214; (r) _);
      g1044 := g1044 + [21, 33]; p07246(false, 0, 0, 0, true);
      g1044 := g1044 - [21]
   _)
_);
%
procedure p10227;
var v: integer;
_( if d82 < 2 then goto 4;
   p10173(a, b);
   while d82 <> 2 do (q) v := p05356(1);
   g1167 := g1167 + 1;
   goto 3
_);
%
procedure p10251(a, b: integer);
_( d119 := d119 + 1;
   if 39 in g1044 then exit;
   p10127(a, b, '-');
   if 21 in g1044 then exit;
   while d117 <> d118 do (q) _( p05214; (r) _);
   g1044 := g1044 + [20, 21, 33]
_);
%
procedure p10275;
var i, j, k, l, n: integer; p, q: pt; m: integer; r: pt;
_( x35777(1, 63743, 'ПPOMП2', g1043);
   x35777(2, 1023, 'ГT.ЛИT', g0631); d125 := 0;
   x35777(1, 4095, 'ЛИTEPЛ', g0630); d124 := 0; d123 := 0;
   d121 := false;
   n := ord(37 in g1044) + 1;
   k := g0622 div 2;
   while k > 0 do _(
      (q) for i := k + 1 to g0622 do _(
         j := i - k;
         while j > 0 do (q) _(
            x33730(g0623, j); p := ;
            x33730(g0623, j + k); q := ;
            if q@.vo < p@.vo then _(
               (q) for l := 0 to n do _(
                  m := p@.ww[l]; p@.ww[l] := q@.ww[l]; q@.ww[l] := m
               _);
               j := j - k
            _) else j := -1
         _)
      _);
      k := k div 2
   _);
   i := 1;
   while i <= g0622 do (q) _(
      x33732(g0623, i); r := ;
      with r@ do _( l := vo; n := vb; vl := 0 _);
      x33732(g0717, l); p := ;
      if p@.nc = 0 then p@.nc := i;
      j := i + 1; x33732(g0623, j); p := ;
      while (p@.vo = l) and (j <= g0622) do (q) _(
         if p@.vb = n then _( p@.vg := true; r@.vg := true _);
         j := j + 1; x33732(g0623, j); p := ; (r)
      _);
      i := i + 1
   _);
   x33731(g0717, g0716 + 1); p := ;
   p@.nc := g0622 + 1;
   x33732(g0717, 1); p := ;
   p@.bt := [1]; p@.na := 1;
   j := 0;
   (q) for i := g0716 + 1 downto 1 do _(
      x33730(g0717, i); p := ;
      p@.bt := [];
      if p@.nc = 0 then p@.nc := j else j := p@.nc
   _);
   if 10 in g0050 then p04347('ПEPEД ');
   x36070(g0612); x36070(g0720); x34421(g1041, 0);
   g1042 := 0; d80 := 0; x33735(g1041, g1036);
   d79 := g1036[0];
   if 37 in g1044 then _(
      x35777(1, 260607, 'TПC   ', g0723); d4 := 1;
      (*=c-*) x33736(g0723, g1135) (*=c+*)
   _);
   g0613 := 16; p05320; d100 := false;
   g0635 := 1; d3 := 0; g0624 := ; d115 := ; g0634 := 1;
   if g1032 < 1000 then g1032 := 3
   else if g1032 < 10000 then g1032 := 4
   else g1032 := 5;
   d6 := 0; d7 := ; d11 := ; d12[0] := ; d9 := ; d8 := false;
   d16[0] := g1026; d28[0] := g1026; g1060 := true;
   g1115 := '      '; g1116 := ; g1117 := ' O  Г ';
   g1120 := ' Л  A '; g1121 := ' B  Л '; g1122 := ' E  H ';
   g1123 := ' И  E '; g1124 := '      '; g1125 := ;
_);
%
   procedure p16001;
   var k, w: integer; e: pt;
%
      function p10676(a, b: integer): integer;
      label 1, 2;
      var i, j, u, v, l, m, n: integer; q: pt; s: set of 0..23;
          p, r: pt;
      _( if 16 in g0050 then _(
            writeln(a:5, b:6); p04347('BЫЧИC.') _);
         x33730(g0717, a); p := ;
         with p@ do _( n := na; s := bt; m := g0636[b].f2; u := nc _);
         x33730(g0717, a + 1); q := ; v := q@.nc - 1;
         (q) for l := b downto m do
            if (n = l) or (l in s) then _(
               j := p@.nb + u; p10676 := ;
               x33730(g0623, j); e := ; goto 2
            _) else
               (q) for j := u to v do _(
                  x33730(g0623, j); r := ;
                  if r@.vb = g0636[l].f1 then _( e := r; goto 1 _)
               _);
         (q) for l := m to b do (r) _(
            j := 0;
            for i := u to v do _(
               x33730(g0623, i); r := ;
               x33730(g0715, r@.vb); q := ;
               if (l in q@.bs) and r@.vf then
                  if j <> 0 then exit r else j := i
            _);
            if j <> 0 then _( x33730(g0623, j); e := ; goto 1 _)
         _);
         p10676 := 0; exit;
      1: p@.na := l; p@.nb := j - u; p10676 := j;
      2: p@.bt := [l + 1 .. b] + s
      _);
%
      function p11073(a: integer): integer;
      var k, i: integer; p, q, r: pt;
      _( if 16 in g0050 then _(
            writeln(a:6); p04347('BЫЧCЛ.') _);
         k := e@.vc;
         x33730(g0717, a); p := ; x33730(g0717, a + 1); q := ;
         (q) for i := p@.nc to q@.nc - 1 do _(
            x33730(g0623, i); r := ;
            if r@.vb = k then _( p11073 := i; e := r; exit _)
         _);
         p11073 := 0
      _);
%
      procedure p11144(a: integer);
      _( if a = 0 then p05442(21, 201);
         if a < 256 then x34602(1, a) else x34603(2, a)
      _);
%
      procedure p11162(a: integer);
      var i: integer;
      _( (q) for i := zg - 1 downto g1037 do _(
            g1035@[i + 5] := g1035@[i]; (r)
         _);
         i := zg + 5; zg := g1037;
         x34601(0, 5); x34600(a + 450);
         g1037 := g1037 + 5; g1040 := g1040 + 5; zg := i; p05551
      _);
%
      procedure p11217;
      _( if d102 then p11162(0)
      _);
%
      function p11225: integer;
      var j, k: integer; p: pt;
      _( k := p05356(1);
         d120 := p05356(3 - ord(odd(k)));
         j := p10676(d120, g0635);
         while k in [1, 2] do (q) _(
            if j = 0 then p05442(21, 202);
            k := p05356(1);
            d120 := p05356(3 - ord(odd(k)));
            j := p11073(d120); (r)
         _);
         p11225 := j;
         with e@ do _(
            if (d11 <> 0) and (27 in g1044) and (d5 <> 0) then exit;
            if d5 <> 0 then _( v1x := true; d116 := d116 + 1 _);
            if 37 in g1044 then
               if (d5 = 0) and (vp = 0) then _( vp := d6; v2x := d11 _)
               else if (22 in g1044) or (d5 = 0) then _(
                  x33726(g0723); p := ;
                  p@.ka := d6; p@.kb := d11; p@.kd := vq; p@.kc := d5;
                  vq := d4; d4 := d4 + 1
               _)
         _)
      _);
%
      procedure p11370;
      var k: integer;
      _( if d79 = 0 then _( k := p05356(1); p11217 _)
         else _(
            d5 := 0; k := p11225; d5 := 4; p11217;
            with e@ do _(
               if vg then p05442(22, 203);
               va := true; vd := d101
            _);
            if g0624 <> 0 then p05533(g0624);
            g0624 := k
         _)
      _);
%
      procedure p11432(var a: rec11);
      var arr: arr11; k, i, m: integer; r: long; m5, m6: integer;
      _( d112 := -1; d114 := 0; d113 := ref(arr); zb := []; m := zg;
         (q) repeat
            if d79 in [1, 2, 3, 4] then _(
               k := p11225; m5 := zg; p11144(k);
               with e@ do _(
                  p05636(vd);
                  with arr[d114 - 1] do
                     if ve = 1023 then zb := zb + [2]
                     else _(
                        if not va then zb := zb + [1]
                        else if vj then x33741(g0627, vd, el);
                        el.ls := vs;
                        if ve <> 0 then c[p05574(ve)] := 1
                     _)
               _)
            _) else if d79 in [5..10] then _(
               p05472(r); x34643(r); p05636(0); arr[d114 - 1].el := r
            _) else if d79 = 11 then _(
               x34576(p05356(1)); p05636(d101);
               with arr[d114 - 1] do c[p05574(g0613)] := 1
            _) else if d79 = 14 then _(
               x34576(p05356(1));
               if d114 = 0 then p05442(1, 204);
               k := p05356(1); x34576(k);
               case k of
               1: _( g1035@[m5] := g1035@[m5] + 3 - 1;
                     k := p05356(1); x34576(k); p05673(k) _);
               2: p06047;
               3: p06077;
               4: _( k := p05356(1); x34576(k); p06126(k) _);
               5: _( g1035@[m6] := g1035@[m6] + 3 - 1; p06166 _);
               6: p06252;
               7: p06320;
               8: p06366;
               9: p06434;
               10: _( k := p05356(1); x34576(k); p06502(k) _);
               11: p06536;
               12: p06601;
               13: _( k := p05356(1); x34576(k); p06725(k) _);
               14: p06644;
               15: _( m6 := m5; zg := zg - 2 _);
               others: p05442(1, 205)
               end
            _) else p05442(1, 206);
            if 17 in g0050 then _(
               if 11 in g0050 then writeln;
               with arr[d114 - 1] do _(
                  write(d114 - 1:3, ': ', el.lw:4 hex, el.hi:12 hex);
                  if el.mb then write(el.mu + el.ms - 1:5, el.mu:3)
                  else write(' ', el.mx:7 hex);
                  (q) for k := 0 to d112 do write(c[k]:4)
               _);
               writeln(zb:17 oct)
            _)
         until d79 = 15;
         if d114 <> 1 then p05442(1, 207);
         if zb = [] then (q) _(
            for k := 0 to d112 do if arr[0].c[k] <> 0 then exit q;
            d112 := -1
         _);
         if (d112 = -1) and (zb = []) then _(
            zg := m; x34643(arr[0].el)
         _);
         x34576(p05356(1));
         a := arr[0];
         if (zb <> []) and (zb * [1, 2, 3, 8] = []) then
            p05442(p04031(zb), 208)
      _);
%
      function p12115(a: integer): integer;
      var r: rec11; m: integer;
      _( m := zg; p11432(r); zg := m;
         if zb <> [] then p05442(a, 209);
         (q) for m := 0 to d112 do
            if r.c[m] <> 0 then p05442(a, 210);
         p12115 := x34770(r.el)
      _);
%
      function p12146: integer;
      var k: integer;
      _( k := p12115(49); p12146 := ;
         if (k < 0) or (k > 15) then p05442(49, 211)
      _);
%
      procedure p12163;
      var i: integer;
      _( (q) for i := zh[d79] downto 0 do _( x34576(p05356(1)); (r) _)
      _);
%
      procedure p12200(a: integer);
      _( za := '.'; write(d6:60 - a); za := ' ';
         if d7 <> 0 then write('.', d7:1);
         writeln
      _);
%
      procedure p12236(a: integer; var b: rec11);
      var i: integer; p: @long; n: integer;
%
         procedure p12216(a: integer);
         _( d122[d123] := a;
            if d123 = 11 then _( x33736(g0630, d122); d123 := 0 _)
            else d123 := d123 + 1
         _);
%
      _( if (zb = []) and (d112 = -1) then _(
            (q) _(
               for i := 1 to d125 do _(
                  x33730(g0631, i); p := ;
                  if (p@.hi = b.el.hi) and (p@.lw = b.el.lw) then exit q
               _);
               d125 := d125 + 1; i := ; x33740(g0631, d125, b.el)
            _);
            i := i * 2
         _) else _(
            i := zg - a + 5;
            p12216(i div 16); p12216(i mod 16);
            p12216(1); p12216(12); p12216(5);
            n := zg - 1;
            (q) for i := a to n do p12216(g1035@[i]);
            d124 := d124 + 1;
            i := d124 * 2 - 1
         _);
         zg := a;
         if i < 256 then x34602(12, i) else x34603(13, i);
         x34576(15);
         d112 := 0; zb := [1];
         d103[0] := g0632@[g0634].fa;
         b.el := g1135.el; b.c[0] := 1
      _);
%
      procedure p12357;
      _( if g0635 <> 1 then p05442(25, 212);
         if d124 + d125 <> 0 then p05442(57, 213);
         g1164 := false; goto 2
      _);
%
      procedure p12423;
      var j: integer; p: pt;
%
         function p12375: boolean;
         _( case p@.sa of
            1: p12375 := j < 4096;
            2: p12375 := (j < 524288) or (j >= 133693440);
            3: p12375 := true
            end
         _);
%
      _( if g0624 <> 0 then _( p05533(g0624); g0624 := 0 _);
         p05247;
         g0613 := p05356(3); x34600(g0613);
         x33730(g0611, g0613); p := ;
         with p@ do
            if 36 in bitset(k) then _(
               j := p12115(39);
               if (j >= 0) and (j < 134217728) and p12375 then
                  g1035@[g1040] := 1
               else _( g1035@[g1040] := 9; j := 0 _);
               vd := j; vl := j; tk := tc; vf := sd; vg := se;
               s16 := s1z
            _);
         p05320
      _);
%
      procedure p12534;
      var j, i, m: integer; r: rec11; p: pt;
      _( j := p05356(3); x34600(j);
         x33730(g0611, j); p := ;
         with p@ do
            if not (36 in bitset(k)) then sx := 0
            else _(
               m := p12146; x34576(m);
               if sx <> 0 then p05442(20, 214);
               if 37 in bitset(k) then _(
                  p11432(r);
                  if zb - [1, 8] <> [] then p05442(50, 215);
                  i := p05574(j); r.c[i] := r.c[i] - 1;
                  (q) for i := 0 to d112 do
                     if r.c[i] <> 0 then p05442(50, 216)
               _);
               sx := m
            _)
      _);
%
      procedure p12631;
      var k: integer;
      _( repeat
            k := p05356(1); x34576(k);
            case k of
            1: g1170 := false;
            2: g1170 := true;
            13: _( p05247; g0613 := p05356(3); x34600(g0613); p05320;
                   x34600(p05356(3));
                   k := p05356(1); x34576(k); g1170 := k = 1 _);
            14: g1172 := true;
            15: g1172 := false;
            0: exit
            end
         until false
      _);
%
      procedure p12713;
      _( if d102 then p05551
         else _( zg := g1040; x34600(299) _)
      _);
%
      procedure p12724;
      _( if not d102 then p05551
         else _( zg := g1040; x34600(299) _)
      _);
%
      procedure p12735;
      var w3: w12; i, m, j, kq, n, t: integer; s, s2: bitset;
          u: integer;
          r: rec11; p: pt; v: integer; c9: array [0..8] of integer;
          a: array [0..12] of integer; f: boolean;
      _( if not (36 in bitset(k)) then _(
            g1035@[g1040] := 0; w3 := g0724[w]
         _) else _(
            w3.wi := p05356(3); g1035@[g1040] := 8; x34600(w3.wi)
         _);
         if 37 in bitset(k) then _(
            p11370; v := 2048; g1035@[g1040] := g1035@[g1040] + 4
         _) else v := 0;
         m := zg; x34576(0);
         if d79 = 15 then _( f := true; i := p05356(1) _)
         else f := false;
         d5 := w3.wg;
         p11432(r); s := zb; n := d112;
         (q) for j := 0 to n do c9[j] := d103[j];
         if not (38 in bitset(k)) then _(
            d5 := w3.wh; g1035@[m] := p12146; kq := ;
         _) else kq := 0;
         if f and g1172 and (w3.we or w3.wf) and (s - [1] = []) then _(
            j := 0;
            (q) for i := 0 to n do
               if r.c[i] = 1 then _(
                  x33730(g0611, c9[i]); p := ;
                  if p@.sa = 3 then _( j := -1; exit _) else j := 1
               _) else if r.c[i] <> 0 then _( j := -1; exit _);
            if j = 1 then s2 := [46, 47]
            else if (j = 0) and (s = []) then s2 := x35706(r.el)
            else s2 := [];
            if (47 in s2) and w3.we then f := false
            else if (46 in s2) and w3.wf then _(
               if w = 131 then w := 129 else if w = 136 then w := 128;
               f := false
            _);
            if not f then _(
               w := w + 64; w3 := g0724[w];
               i := zg; zg := g1040 + 1; x34577(w); zg := i
            _)
         _);
         if f then _(
            (q) for i := 0 to n do d103[i] := c9[i];
            zb := s; d112 := n; p12236(m + 1, r);
            s := zb; n := d112;
            for i := 0 to n do c9[i] := d103[i]
         _);
         if (s - [1, 8] = []) and g1170 then _(
            if (kq <> 0) or w3.wc then _( u := 1; a[0] := 0 _)
            else u := 0;
            t := 1;
            (q) for j := 0 to n do _(
               kq := r.c[j];
               if kq <> 0 then _(
                  x33730(g0611, c9[j]); p := ;
                  with p@ do
                     if s1x then
                        if (sx <> 0) and (kq > 0) then _(
                           if u + kq > 12 then p05442(42, 217);
                           (q) for m := u to u + kq - 1 do
                              a[m] := c9[j];
                           u := u + kq; r.c[j] := 0
                        _) else p05442(52, 218)
                     else if sa > t then t := sa else r.c[j] := 0
               _)
            _);
            if ((t = 2) and (w < 128)) or (t = 3) then
               if u = 1 then _( u := 2; a[1] := 0 _)
               else if u = 0 then
                  (q) for j := 0 to n do _(
                     kq := r.c[j];
                     if kq = 0 then exit;
                     x33730(g0611, c9[j]); p := ;
                     with p@ do _(
                        if sa = 1 then exit;
                        if (u = 0) and (kq = 1) and (sx <> 0) then _(
                           u := 1; a[0] := c9[j]
                        _) else _(
                           if u = 0 then a[0] := 0;
                           u := 2; a[1] := 0
                        _)
                     _)
                  _);
            if u = 0 then _(
               u := 1;
               if s - [8] = [] then _(
                  m := x34770(r.el) mod 134217728;
                  if ((w < 128) and (m >= 4096)) or
                     ((m >= 524288) and (m < 133693440)) then _(
                     u := 2; x34604(1, 5, 0); x34601(5, 0);
                     g1035@[g1040] := g1035@[g1040] + 2
                  _)
               _)
            _) else if (u <> 1) or (a[0] <> 0) then _(
               g1035@[g1040] := g1035@[g1040] + 2;
               x34576(u - 1);
               (q) for m := u - 1 downto 0 do _( x34647(a[m]); (r) _)
            _)
         _) else u := 1;
         d101 := d101 + u div 2;
         if odd(u) then p05551;
         if w3.wa and not d102 then p11162(v);
         if w3.wb and d102 then _(
            g1035@[g1037] := (zg - g1037) div 16;
            g1035@[g1037 + 1] := (zg - g1037) mod 16;
            g1037 := zg; g1040 := g1037 + 2;
            x34601(0, 0); x34600(450); p05551
         _)
      _);
%
      procedure p13507;
      _( w := 34; p12735;
         if d102 then p11162(2048);
         g1035@[g1040 + 1] := 11; g1035@[g1040 + 2] := 14
      _);
%
      procedure p13532;
      var j: integer;
      _( if 36 in bitset(k) then p11370;
         if 37 in bitset(k) then _(
            d5 := 1; j := p11225; x34600(j);
            with e@ do _(
               if not vk and not vi then p05442(30, 238);
               j := 7;
               if va then _(
                  j := 6;
                  if vn = 1 then _(
                     if vm = 64 then j := 1
                     else if vm < 20 then j := 2
                     else if vm < 27 then j := 4
                  _) else if vn + vm = 65 then j := 3
                  else if vm < 20 then j := 5
               _)
            _);
            x34576(j);
            d101 := d101 + j div 4;
            if j div 2 = 1 then p05551
         _) else p05442(2, 239)
      _);
%
      procedure p13640;
      var j, i: integer; r: rec11;
      _( if 36 in bitset(k) then p11370 else p11217;
         if 37 in bitset(k) then _(
            j := p12115(39);
            if j <= 0 then p05442(40, 219)
         _) else j := 1;
         x34647(j);
         if d79 = 15 then _(
            i := p05356(1); i := zg; p11432(r); p12236(i, r)
         _) else p11432(r);
         d101 := d101 + j
      _);
%
      procedure p13706;
      var i: integer; r: rec11;
      _( if 36 in bitset(k) then p11370;
         if d79 = 15 then _(
            i := p05356(1); i := zg; p11432(r); p12236(i, r)
         _) else p11432(r);
         p05551
      _);
%
      procedure p13736;
      var j, i, m: integer;
      _( if 36 in bitset(k) then p11370 else p11217;
         j := p05356(2); x34577((j + 7) div 8);
         (q) for i := 1 to j do _( x34577(p05356(2)); (r) _);
         m := p12115(39);
         if (m < 0) or (m > 255) then p05442(33, 220);
         (q) for i := (j + 7) mod 8 to 6 do _( x34577(m); (r) _);
         d101 := d101 + (j + 7) div 8
      _);
%
      procedure p14010;
      var j: integer;
      _( if 36 in bitset(k) then p11370 else p11217;
         j := p12115(39);
         if j < 0 then p05442(40, 221);
         d101 := d101 + j; x34647(j)
      _);
%
      procedure p14032;
      var i: integer; p: @long;
      _( if 36 in bitset(k) then p11370 else p11217;
         with g0632@[g0634] do _( fd := d101; fc := d125 _);
         (q) for i := 1 to d125 do _(
            x33730(g0631, i); p := ; x34643(p@); (r)
         _);
         x34576(15);
         d101 := d101 + d125 + d124; g0633 := g0633 + d125 + d124;
         d125 := 0; d121 := true; d124 := 0; g0634 := g0634 + 1
      _);
%
      procedure p14104;
      _( if 36 in bitset(k) then p11370
      _);
%
      procedure p14112;
      var j, i, m: integer; r: rec11; p: pt;
      _( d5 := 0; j := p11225; d5 := 4; x34600(j);
         if e@.vg then p05442(22, 222);
         p := e;
         if not (36 in bitset(k)) then _(
            p11432(r);
            with p@ do _(
               j := x34772(r.el);
               if zb = [] then
                  if j >= 0 then vd := j
                  else _(
                     vj := true; g0626 := g0626 + 1; vd := ;
                     x33742(g0627, g0626, r.el)
                  _);
               j := 0; m := 0;
               (q) for i := 0 to d112 do
                  if r.c[i] = 1 then _( j := d103[i]; m := m + 1 _)
                  else if r.c[i] <> 0 then m := 2;
               if m <= 1 then _(
                  ve := j; va := true; vl := 0;
                  zg := g1037 + 2 + 3 + 3; g1035@[g1040] := 9
               _);
               if 37 in bitset(k) then _(
                  if (ve <> 0) or vj then p05442(43, 223);
                  ve := p12146
               _);
               if not va then _(
                  d3 := d3 + 1; vr := d3;
                  if vh then g0625 := g0625 - 1
               _)
            _)
         _)
      _);
%
      procedure p14277;
      var j, i: integer; p: pt;
      _( j := g0624; p11370; x34600(g0624); p := e; g0624 := j;
         if not (36 in bitset(k)) then _(
            j := p12115(45); i := p12115(45);
            if (j > 64) or (j < i) or (i < 1) then p05442(45, 224);
            p@.vn := i; p@.vm := j - i + 1
         _) else _(
            j := p11225;
            if e@.va then _(
               if e@.vk then _( p@.vn := e@.vn; p@.vm := e@.vm _)
               else p05442(30, 225);
               g1035@[g1040] := 1
            _) else p@.va := false
         _)
      _);
%
      procedure p14403;
      var j: integer;
      _( d5 := 0; j := p11225; d5 := 4;
         with e@ do _(
            if vg then p05442(22, 226);
            if vh then p05442(28, 227);
            d115 := d115 + 1; vr := ;
         _);
         j := p05356(2); x34577(j);
         (q) for j := j downto 1 do _( x34577(p05356(2)); (r) _)
      _);
%
      procedure p14451;
      var j: integer;
      _( (q) repeat
            j := p05356(1);
            if j = 15 then exit q;
            x34600(p05356(3 - ord(odd(j)))); (r)
         until false;
         x34600(0);
         (q) repeat
            d5 := 0; j := p11225; d5 := 4;
            with e@ do _(
               if vg then p05442(22, 228);
               d115 := d115 + 1; vr := ; v1v := d120
            _);
            x34600(d120); (r)
         until d79 = 15;
         j := p05356(1); x34600(0)
      _);
%
      procedure p14530;
      var j, i, m, n: integer; p: pt; r: rec11;
      _( j := g0635 + 1;
         if d100 then _(
            (q) for i := 1 to g0714 do _(
               x33730(g0715, i); p := ;
               with p@ do bs := bs - [j..23]; (r)
            _);
            (q) for i := 1 to g0716 do _(
               x33730(g0717, i); p := ;
               with p@ do _(
                  bt := bt - [j..23];
                  if na > g0635 then na := 0
               _)
            _);
            d100 := false
         _);
         p11370;
         with g0636[j] do _(
            f1 := e@.vc; f2 := g0636[g0635].f2; f3 := g0624
         _);
         x34600(e@.vc);
         if (31 in g1044) and (21 in g1044) then _(
            x33730(g0715, e@.vc); p := ;
            x33730(g0720, p@.ne); p := ;
            p04051;
            write(' ', d101:7 hex, ' ':j * 2);
            p04014(p@.w);
            p12200(j * 2 + 7 + 8 + 1)
         _);
         (q) repeat
            case p05356(1) of
            5: _(
               i := p11225; n := e@.vc; m := j;
               while g0636[m].f1 <> n do (q) _(
                  m := m - 1;
                  if m = 0 then p05442(24, 229)
               _);
               g0636[j].f2 := m;
               if m < g0636[g0635].f2 then p05442(25, 230);
               while d79 in [3, 4] do (q) _(
                  i := p05356(p05356(1) + 2 - 3);
                  m := p10676(i, j);
                  if m <> 0 then p05442(27, 231);
                  m := p10676(i, g0635);
                  if m = 0 then p05442(21, 232);
                  if 22 in g1044 then _(
                     with e@ do _( m := vq; vq := d4 _);
                     d4 := d4 + 1;
                     x33726(g0723); p := ;
                     with p@ do _(
                        ka := d6; kd := m; kc := 4; kb := d11
                     _)
                  _);
                  x33730(g0717, i); p := ;
                  p@.bt := p@.bt + [j]; (r)
               _)
            _);
            6: while d79 in [1, 2, 3, 4] do (q) _(
                  i := p11225; i := e@.vc;
                  if i = 0 then p05442(23, 233);
                  x33730(g0715, i); p := ;
                  p@.bs := p@.bs + [j]; (r)
               _);
            10: exit q;
            others: p05442(1, 234)
            end
         until false;
         g0635 := j; g0624 := 0
      _);
%
      procedure p15132;
      var p: pt; m: integer;
      _( with g0636[g0635] do _(
            x33730(g0623, f3); p := ;
            if p@.ve = g0613 then p05533(f3)
         _);
         if 22 in g1044 then _(
            m := p@.vq; p@.vq := d4; d4 := d4 + 1;
            x33726(g0723); p := ;
            p@.ka := d6; p@.kd := m; p@.kc := 4; p@.kb := d11
         _);
         d100 := true;
         if g0635 > 1 then g0635 := g0635 - 1
      _);
%
      procedure p15220;
      var i: integer;
      _( if not (36 in bitset(k)) then _(
            p12163;
            d6 := p05356(zh[p05356(1)]);
            d7 := p05356(zh[p05356(1)])
         _)
      _);
%
      procedure p15246;
      var i, j, c, n, m: integer; b: boolean;
      _( b := (36 in g1044) and (21 in g1044);
         if 36 in bitset(k) then _(
            m := 2;
            if b then _( p04051; writeln(' ') _)
         _) else m := 1;
         (q) for i := 1 to m do _(
            n := p05356(2); x34577(n);
            if n <> 0 then _(
               if b then p04051;
               (q) for j := 1 to n do _(
                  c := p05356(2); x34577(c);
                  if b then write(chr(c))
               _);
               if b then p12200(n)
            _)
         _)
      _);
%
      procedure p15325;
      _( p12163; p12163
      _);
%
      procedure p15331;
      var i: integer;
      _( g1044 := bitset(p05525); x34646(g1044);
         p12163; p12163; p12163
      _);
%
      procedure p15342;
      var u: word3;
      _( d12[0] := d12[0] + 1; d11 := ;
         d9 := d9 + 1;
         (*=c-*)
         d16[d9].ext := p05525; d16[d9].lib := p05525;
         d16[d9].name := p05525;
         x34646(d16[d9].ext); x34646(d16[d9].lib); x34646(d16[d9].name);
         (*=c+*)
         if 36 in g1044 then _(
            p04051; writeln(' ');
            p04051;
            write(' ФАЙЛ', d11:3, ':', ' ':d9 * 2 + 1, d16[d9].lib, '/',
                  d16[d9].name, '.', d16[d9].ext);
            p12200(d9 * 2 + 29);
            p04051; writeln(' ')
         _);
         x34647(p05356(zh[p05356(1)]));
         d16[d9].ext[6] := chr(d11);
         d28[d11] := d16[d9]; d6 := 0; d7 := 0
      _);
%
      procedure p15514;
      var j: integer;
      _( j := p05356(2); x34577(j); x34600(p05356(2) + 100);
         g1164 := j <> 58; goto 2
      _);
%
      procedure p15534;
      var j: integer;
      _( if 37 in bitset(k) then _( p11370; j := 2048 _) else j := 0;
         if not d102 then p11162(2048);
         p05551;
         d101 := d101 + 1;
         if not (38 in bitset(k)) then _(
            d5 := 1; j := p11225;
            if not e@.vi then p05442(29, 235)
         _) else j := 0;
         x34647(j);
         if w = 293 then d5 := 1 else d5 := 2;
         x34576(p12146)
      _);
%
      procedure p15601;
      var j: integer;
      _( j := p05356(zh[p05356(1)]); x34647(j);
         d6 := p05356(zh[p05356(1)]); d7 := p05356(zh[p05356(1)]);
         d8 := true;
         x34647(d6); x34647(d7);
         if j <> 0 then _(
            d9 := d9 - j;
            d11 := ord(d16[d9].ext[6]);
            if 36 in g1044 then _(
               d16[d9].ext[6] := '_000';
               p04051; writeln(' ');
               p04051;
               write(' ФАЙЛ', d11:3, ':', ' ':d9 * 2 + 1, d16[d9].lib,
                     '/', d16[d9].name, '.', d16[d9].ext, ' (ПРОД.)');
               p12200(d9 * 2 + 37);
               p04051; writeln(' ');
               d16[d9].ext[6] := chr(d11)
            _)
         _)
      _);
%
      procedure p15742;
      var j, i: integer; s: bitset;
      _( (q) repeat
            j := p05356(1);
            if j <> 0 then _(
               s := bitset(p05525);
               if j = 6 then g0050 := g0050 + s
               else if j = 2 then g0050 := g0050 - s
               else _( x34576(j); x34646(s) _)
            _)
         until j = 0;
         x34576(0);
         if 0 in g0050 then _( p04347('ПРОХОД'); g0050 := g0050 - [0] _)
      _);
%
   _( g1037 := 0; zg := 2; d82 := p05356(2); g1040 := zg;
      k := p05356(3); w := k mod 512; x34600(k);
      if w <= 447 then
         if d8 then d8 := false
         else if d7 <> 0 then d7 := d7 + 1
         else d6 := d6 + 1;
      if w <= 255 then p12735
      else if w <= 383 then
         case w of
         257: ;
         258: p12357;
         259: p12423;
         260: p12534;
         261: p12631;
         262: p12713;
         263: p12724;
         301: p13532;
         264: p13640;
         265, 266, 267: p13706;
         268: p13736;
         269: p14010;
         270: p14032;
         271: p14104;
         273: ;
         274: p14112;
         275: p14277;
         276: p14403;
         297: p14451;
         277: p14530;
         278: p15132;
         279, 280: ;
         281, 282, 283, 284: p15220;
         285, 286: ;
         287, 288: p15246;
         289: p15325;
         290, 291, 292: p15331;
         293, 294: p15534;
         298: p15742;
         295, 296, 299: ;
         300: p15514;
         272: p15342;
         others: p05442(1, 236)
         end
      else if w <= 447 then p13507
      else
         case w of
         454: p15601;
         449: _( g1164 := false; goto 2 _);
         451, 452: ;
         others: p05442(1, 237)
         end
   _);
   procedure p16210;
   var i, m: integer; p: @hx;
   _( g1035@[g1037] := (zg - g1037) div 16;
      g1035@[g1037 + 1] := (zg - g1037) mod 16;
      if not g1164 then _( x34601(0, 5); x34600(449) _);
      if 18 in g0050 then _(
         (q) for i := 0 to zg - 1 do write(' ', g1035@[i]:1 hex);
         writeln
      _);
      (q) for i := 0 to zg - 1 do _(
         d81[d80] := g1035@[i];
         if d80 = 11 then _( x33736(g1043, d81); d80 := 0 _)
         else d80 := d80 + 1
      _);
      if d121 then _(
         m := d80 * 4;
         (*=c-*)
         d81 := shift(shift(d81, 48 - m), -(48 - m));
         (q) for i := 0 to x34423(g0630) - 1 do _(
            x33730(g0630, i); p := ;
            p := shift(p@, m);
            besm(310000B, 30000B : p, 150000B : d81, 10000B : p);
            d81 := ;
            x33736(g1043, p)
         _);
         (*=c+*)
         (q) for i := 0 to d123 - 1 do _(
            d81[d80] := d122[i];
            if d80 = 11 then _( x33736(g1043, d81); d80 := 0 _)
            else d80 := d80 + 1
         _);
         d121 := false; d123 := 0;
         x34421(g0630, 0)
      _);
      if g1164 then goto 1;
      if d80 <> 0 then x33736(g1043, d81);
      if g0624 <> 0 then p05533(g0624);
      p05247;
      x34427(g1041);
      if 19 in g0050 then p04347('ПОСЛЕ ')
   _);
%
   procedure p16420;
   type hdr = record case integer of 0: (hp: pt); 1: (b: hb) end;
        dt = packed record d0: 0..8191; dd1: u2; dd0: u4;
                mm1: 0..1; mm0, yy0, yy1: u4; d1: 0..8191;
                wd: 0..7 end;
   var i, v4, v5, v6: integer; r: hdr; v8: pt; v9: @sect;
       v10, v11, v12: pt; v13: dt;
   _( x34427(g0630); x34427(g0631);
      if (38 in g1044) and (g1167 <> 0) then g1126 := 0;
      if g1126 = 0 then d83 := ptr(0) else _(
         d83 := ref(d85);
         x35733(1, g1126, g1127, 'MOДYЛЬ', d83) _);
      d84 := d83;
      r.b.hw := []; r.b.hk := 0; r.b.ha := 11259375;
      (*=c-*) x33736(d83, r) (*=c+*);
      r.b.hw := []; r.b.hc := 1; r.b.hd := 6;
      (*=c-*) x33736(d83, r) (*=c+*);
      r.b.hw := []; r.b.hn := 'ACC-'; (*=c-*) x33736(d83, r) (*=c+*);
      r.b.hw := []; r.b.hn := '5.04'; (*=c-*) x33736(d83, r) (*=c+*);
      r.b.hw := []; r.b.hn := g1130; (*=c-*) x33736(d83, r) (*=c+*);
      r.b.hw := []; r.b.hn := g1131; (*=c-*) x33736(d83, r) (*=c+*);
      r.b.hw := []; r.b.hn := g1132; (*=c-*) x33736(d83, r) (*=c+*);
      r.b.hw := []; (*=c-*) x33736(d83, r) (*=c+*);
      r.b.hw := []; besm(500100B); (r); besm(360130B, 150000B : 0);
      r.b.hg := ; (*=c-*) x33736(d83, r) (*=c+*);
      r.b.hw := []; (*=c-*) x33736(d83, r) (*=c+*);
      besm(500114B); (r); v13 := ;
      r.b.hw := []; r.b.hy := v13.wd; (*=c-*) x33736(d83, r) (*=c+*);
      r.b.hw := []; besm(530010B); (r); besm(150000B : 0); i := ;
      v4 := v13.yy1 * 10 + 1900 + v13.yy0 - 1;
      v5 := v4 * 365 + v4 div 4 - v4 div 100 + v4 div 400
          + g1150[v13.mm1 * 10 + v13.mm0]
          + v13.dd1 * 10 + v13.dd0 - 723181;
      v4 := v4 + 1;
      if ((v4 mod 4 = 0) and (v4 mod 100 <> 0) or (v4 mod 400 = 0))
         and (v13.mm0 > 2) then v5 := v5 + 1;
      r.b.h32 := v5 * 86400 + i div 50; (*=c-*) x33736(d83, r) (*=c+*);
      (q) for i := 1 to g0605 do _(
         x33730(g0606, i); v10 := ;
         r.b.hw := []; r.b.hk := 1; (*=c-*) x33736(d83, r) (*=c+*);
         r.b.hw := []; r.b.hd := 3; (*=c-*) x33736(d83, r) (*=c+*);
         r.b.hw := []; r.b.hn := x33037(v10@.w);
         (*=c-*) x33736(d83, r) (*=c+*);
         r.b.hw := []; r.b.hn := x33040(v10@.w);
         (*=c-*) x33736(d83, r) (*=c+*);
         r.b.hw := []; (*=c-*) x33736(d83, r) (*=c+*);
         r.b.hw := []; (*=c-*) x33736(d83, r) (*=c+*)
      _);
      (q) for i := 16 to g0610 do _(
         x33730(g0611, i); v9 := ;
         with v9@ do _(
            r.b.hw := []; r.b.hk := 2; r.b.x2 := sa; r.b.x5 := sb;
            r.b.xb := s1x; r.b.xc := sn; r.b.xd := sh;
            r.b.xs := sc mod [0, 1, 2, 4];
            (*=c-*) x33736(d83, r) (*=c+*);
            r.b.hw := []; r.b.hy := sf; r.b.hd := 4;
            (*=c-*) x33736(d83, r) (*=c+*);
            x33727(g0612, i); v10 := ;
            r.b.hw := []; r.b.hn := x33037(v10@.w);
            (*=c-*) x33736(d83, r) (*=c+*);
            r.b.hw := []; r.b.hn := x33040(v10@.w);
            (*=c-*) x33736(d83, r) (*=c+*);
            r.b.hw := []; (*=c-*) x33736(d83, r) (*=c+*);
            r.b.hw := []; (*=c-*) x33736(d83, r) (*=c+*);
            x36036(g0612, i);
            r.b.hw := []; r.b.h32 := sg; (*=c-*) x33736(d83, r) (*=c+*);
            r.b.hw := []; if not si then r.b.h32 := so - sg + ord(sj);
            (*=c-*) x33736(d83, r) (*=c+*);
            sx := 0; sz := 0; so := sg; sj := false;
            sk := sc; sl := sd; sm := se; s1y := 0
         _)
      _);
      v6 := 0; d3 := 0;
      (q) for i := 2 to g0714 do _(
         x33730(g0715, i); v11 := ;
         with v11@ do
         if bc then _(
            x33730(g0717, bd); r.hp := ;
            v5 := r.hp@.nc - 1;
            (q) repeat v5 := v5 + 1; x33730(g0623, v5); v12 := ; (r)
            until v12@.vc = i;
            with v12@ do _(
               r.b.hw := []; r.b.hk := 6; r.b.hm := 1; r.b.hbit := true;
               (*=c-*) x33736(d83, r) (*=c+*);
               r.b.hw := []; r.b.hd := 5;
               (*=c-*) x33736(d83, r) (*=c+*);
               r.b.hw := []; if v11@.bb > 1 then r.b.hn := g1134;
               (*=c-*) x33736(d83, r) (*=c+*);
               x33730(g0720, v11@.bd); v10 := ;
               r.b.hw := []; r.b.hn := x33037(v10@.w);
               (*=c-*) x33736(d83, r) (*=c+*);
               r.b.hw := []; r.b.hn := x33040(v10@.w);
               (*=c-*) x33736(d83, r) (*=c+*);
               r.b.hw := [];
               if v11@.bb > 1 then _(
                  x33730(g0715, v11@.bb); v8 := ;
                  r.b.xb := true; r.b.hd := v8@.be _);
               (*=c-*) x33736(d83, r) (*=c+*);
               r.b.hw := []; r.b.hd := ve - 15;
               (*=c-*) x33736(d83, r) (*=c+*);
               r.b.hw := []; r.b.h32 := vd;
               (*=c-*) x33736(d83, r) (*=c+*);
               r.b.hw := []; (*=c-*) x33736(d83, r) (*=c+*);
               r.b.hw := []; r.b.hv := vs;
               (*=c-*) x33736(d83, r) (*=c+*);
               v6 := v6 + 1; v11@.be := ;
            _)
         _)
      _);
      i := 1;
      (q) for v4 := 1 to g0622 do _(
         x33730(g0623, v4); v12 := ;
         with v12@ do
         if vh and va and (vc = 0) then _(
            r.b.hw := []; r.b.hk := 6; r.b.hm := 1; r.b.hbit := true;
            (*=c-*) x33736(d83, r) (*=c+*);
            r.b.hw := []; r.b.hd := 5; (*=c-*) x33736(d83, r) (*=c+*);
            (q) repeat x33730(g0717, i); v8 := ; i := i + 1
            until v8@.nc > v4;
            i := i - 2;
            r.b.hw := []; if vb > 1 then r.b.hn := g1134;
            (*=c-*) x33736(d83, r) (*=c+*);
            x33730(g0720, i); v10 := ;
            r.b.hw := []; r.b.hn := x33037(v10@.w);
            (*=c-*) x33736(d83, r) (*=c+*);
            r.b.hw := []; r.b.hn := x33040(v10@.w);
            (*=c-*) x33736(d83, r) (*=c+*);
            r.b.hw := [];
            if vb > 1 then _(
               x33730(g0715, vb); v8 := ;
               with v8@ do _( r.b.xb := true; r.b.hd := be _) _);
            (*=c-*) x33736(d83, r) (*=c+*);
            r.b.hw := [];
            if ve < 16 then r.b.h4b := ve else r.b.hd := ve - 15;
            (*=c-*) x33736(d83, r) (*=c+*);
            r.b.hw := []; r.b.h32 := vd; (*=c-*) x33736(d83, r) (*=c+*);
            r.b.hw := []; (*=c-*) x33736(d83, r) (*=c+*);
            r.b.hw := []; r.b.hv := vs; (*=c-*) x33736(d83, r) (*=c+*)
         _) else if not vi and not va then _(
            vr := vr + g0625;
            (q) repeat x33730(g0717, i); v8 := ; i := i + 1
            until v8@.nc > v4;
            v1v := i - 2
         _)
      _);
      if 20 in g0050 then p04347('ПEPEД ');
      g1041 := g1043; x34421(g1041, 0); g1042 := 0;
      x33735(g1041, g1036); d79 := g1036[0];
      x34127(g1031, g1034);
      d6 := 0; d7 := ; d9 := ; d117 := ; d118 := ; d8 := false;
      g1070 := -1; g1060 := true; d119 := 0;
      g1044 := g1045; g1050 := g1053; g1051 := g1054; g1052 := g1055;
      d12[0] := 0; d11 := ; d10 := ;
      g1115 := '      '; g1116 := ; g1117 := ; g1120 := ; g1121 := ;
      g1122 := ; g1123 := ; g1124 := ; g1125 := ;
      if g1167 + d119 <> 0 then g1044 := g1044 + [33];
      g0635 := 1; g0613 := 16; p05320; d93 := false; g0634 := 1;
      d124 := 0
   _);
   procedure p27034;
   var k3, k4, w5, w6, w7, w8: integer; w9: long;
      procedure p20145;
      var r: hb;
      _( if not d93 then _(
            if g1173 then d83 := ptr(0);
            r.hw := []; r.hk := 10; r.hd := g0613 - 15;
            (*=c-*) x33736(d83, r) (*=c+*);
            d94 := x34423(d83);
            r.hw := []; (*=c-*) x33736(d83, r) (*=c+*);
            d93 := true; d95 := 0; d97.bw := [];
            d96 := 1; d98 := 0;
            if d102 then _( d99 := 1; g1133@[0].h32 := 0 _)
            else d99 := 0;
            if 28 in g0050 then write('<< ')
         _)
      _);
      procedure p20224(a: integer);
      _( if not d93 then _( p10227(1, 304) _);
         d97.by[d95] := a mod 256;
         if d95 = 3 then _(
            (*=c-*) x33736(d83, d97) (*=c+*);
            d97.bw := []; d95 := 0; d96 := d96 + 1
         _) else d95 := d95 + 1
      _);
      procedure p20253;
      var r: hb; i: integer;
      _( if not d93 then exit;
         if d98 = 1 then p20224(128)
         else if d98 > 1 then _( p20224(138); p20224(d98 - 1) _);
         p20224(143);
         if d95 = 0 then d96 := d96 - 1
         else (*=c-*) x33736(d83, d97) (*=c+*);
         if odd(d96) then _(
            (*=c-*) x33736(d83, g1135) (*=c+*); d96 := d96 + 1 _);
         if odd(d99) then _( g1133@[d99].h32 := 0; d99 := d99 + 1 _);
         if d94 > 0 then _(
            (q) for i := 0 to d99 - 1 do
               (*=c-*) x33736(d83, g1133@[i]) (*=c+*)
         _) else d94 := -d94;
         i := x34423(d83);
         x34421(d83, d94);
         r.hw := []; r.hy := d96 div 2; r.hd := (d96 + d99) div 2 + 1;
         (*=c-*) x33736(d83, r) (*=c+*);
         x34421(d83, i);
         d93 := false; d83 := d84;
         if 28 in g0050 then writeln(' >>')
      _);
      procedure p20410(var a: long);
      var n, i: integer; b: a8;
      _( n := x33035(a, b) - 1;
         x34576(1 + n);
         (q) for i := 0 to n do _( x34576(b[i]); (r) _)
      _);
      procedure p20431(a, b, c: integer);
      _( if c = 3 then _(
            g1133@[d99].h32 := b; d99 := d99 + 1;
            if 28 in g0050 then write('[', b:8 hex, ']') _);
         g1133@[d99].h32 := a; d99 := d99 + 1;
         if 28 in g0050 then write('[', a:8 hex, ']')
      _);
      procedure p20474(a: integer);
      _( if 28 in g0050 then write('[', a:8 hex, ']');
         g1133@[d99].h32 := a; d99 := d99 + 1
      _);
      procedure p20515(var a: long);
      var r: long;
      _( if 28 in g0050 then write('[', a.lw:4 hex, a.hi:12 hex, ']');
         x35125(a, 32, r);
         g1133@[d99].h32 := x34770(r);
         g1133@[d99 + 1].h32 := x35114(a, 4294967295);
         d99 := d99 + 2
      _);
      procedure p20564(a: integer; b: boolean);
      var u, v: boolean;
      _( if d99 + 1 + a mod 2 > 63 then _( p20253; p20145 _);
         u := ((g1175.s = g1176.s) or d102) and not b;
         v := (g1174 = 0) and (a = 1);
         if (a = g1174) and u then d98 := d98 + 1 + a mod 2
         else _(
            if d98 = 1 then p20224(128)
            else if d98 > 1 then _( p20224(138); p20224(d98 - 1) _);
            d98 := 0;
            if u then _(
               if v then p20224(236)
               else _( p20224(132 + a); g1174 := a;
                       d98 := a mod 2 + 1 _)
            _) else if v then p20224(108)
            else if a <> g1174 then _( p20224(132 + a); g1174 := a _);
            if (g1175.s <> g1176.s) and not d102 then _(
               if g1176.s * [0..4] = g1175.s * [0..4] + [1] then
                  p20224(ord(not b) * 128 + 106)
               else _( p20224(ord(not b) * 128 + 107);
                       p20224(g1176.fi) _);
               g1176 := g1175
            _)
         _);
         if 28 in g0050 then write(' </> ')
      _);
      procedure p20711(var a: rec11);
      var v4, v5: integer; v6, v7: pt; t: arr11;
      _( if (27 in g0050) and (28 in g0050) then writeln;
         zg := 0; w5 := ; d114 := ; d126 := ;
         d113 := ref(t); d112 := -1; zb := [];
         (q) repeat
         if d79 in [1, 2] then _(
            v4 := p05356(p05356(1) + 2 - 1);
            x33730(g0623, v4); v6 := ;
            with v6@ do _(
               p05636(vd);
               if d126 < 2 then d126 := vb;
               with t[d114 - 1] do
               if ve = 1023 then _(
                  zb := zb + [2];
                  if w5 = 0 then _(
                     x34751(vr, w9);
                     if vi then w6 := 54 else w6 := 50 _);
                  if vr < 256 then v4 := 0 else v4 := 1;
                  w7 := zg;
                  if vi then x34576(52 + v4) else x34576(48 + v4);
                  if v4 = 0 then x34576(vr)
                  else _( x34601(vr div 256, vr mod 256); v4 := 0 _);
                  if w5 = 0 then w5 := zg
               _) else _(
                  if vj then x33741(g0627, vd, el);
                  w7 := zg; p20410(el);
                  v4 := ve;
                  if w5 = 0 then _( w9 := el; w6 := 0; w5 := zg _);
                  if v4 <> 0 then _(
                     x33730(g0611, v4); v7 := ;
                     if not v7@.si then _(
                        w7 := zg; v5 := v4 - 15;
                        if v5 < 8 then x34576(97 + v5 - 1)
                        else if v5 < 256 then x34601(104, v5)
                        else x34604(105, v5 div 256, v5 mod 256)
                     _) else if v4 < 16 then zb := zb + [8]
                  _);
                  el.ls := vs; c[p05574(v4)] := 1
               _)
            _)
         _) else if d79 in [3, 4] then _(
            v4 := p05356(p05356(1) + 2 - 3);
            x33730(g0623, v4); v6 := ;
            with v6@ do _(
               p05636(vl);
               if d126 < 2 then d126 := vb;
               with t[d114 - 1] do
               if ve = 1023 then _(
                  el.lf := false; zb := zb + [2];
                  if w5 = 0 then _(
                     x34751(vr, w9);
                     if vi then w6 := 17920 else w6 := 16896 _);
                  if vr < 256 then v4 := 0 else v4 := 1;
                  w7 := zg;
                  if vi then x34576(68 + v4) else x34576(64 + v4);
                  x34576(0);
                  if v4 = 0 then x34576(vr)
                  else x34601(vr div 256, vr mod 256);
                  if w5 = 0 then w5 := zg
               _) else _( el.lf := true; el.ls := vs _)
            _)
         _) else if d79 in [5..10] then _(
            p05636(0);
            with t[d114 - 1] do _(
               p05472(el); w7 := zg; p20410(el);
               if w5 = 0 then _( w9 := el; w6 := 0; w5 := zg _)
            _)
         _) else if d79 in [12, 13] then _(
            v5 := p05356(p05356(1) + 2 - 12);
            with g0632@[g0634] do _(
               if odd(v5) then v5 := v5 div 2 + fc
               else v5 := v5 div 2 - 1;
               p05636(fd + v5);
               with t[d114 - 1] do _(
                  w7 := zg; p20410(el);
                  if w5 = 0 then _( w9 := el; w6 := 0; w5 := zg _);
                  c[p05574(fa)] := 1
               _);
               x33730(g0611, fa); v7 := ; v4 := fa - 15;
               if not v7@.si then _(
                  w7 := zg;
                  if v4 < 8 then x34576(97 + v4 - 1)
                  else if v4 < 256 then x34601(104, v4)
                  else x34604(105, v4 div 256, v4 mod 256)
               _)
            _)
         _) else if d79 = 11 then _(
            v5 := p05356(1); p05636(d101);
            with t[d114 - 1] do _(
               c[p05574(g0613)] := 1;
               w7 := zg; p20410(el);
               if w5 = 0 then _( w9 := el; w6 := 0; w5 := zg _)
            _);
            x33730(g0611, g0613); v7 := ; v4 := g0613 - 15;
            if not v7@.si then _(
               w7 := zg;
               if v4 < 8 then x34576(97 + v4 - 1)
               else if v4 < 256 then x34601(104, v4)
               else x34604(105, v4 div 256, v4 mod 256)
            _)
         _) else if d79 = 14 then _(
            v4 := p05356(1); w7 := zg;
            case p05356(1) of
            1: _( v4 := p05356(1);
                  with t[d114 - 1] do
                  if el.lf then _(
                     p05673(v4); p20410(el);
                     if w5 = 0 then _( w9 := el; w6 := 0; w5 := zg _)
                  _) else _(
                     case v4 of
                     1: x34604(35, 27, 1);
                     2: x34604(35, 14, 8);
                     6: x34604(35, 7, 1);
                     4: _( x34604(35, 7, 1); x34601(1, 1);
                           w7 := zg; x34576(17) _);
                     5: _( x34604(9, 35, 14); x34604(8, 10, 35);
                           x34604(7, 1, 16); x34601(1, 1);
                           w7 := zg; x34576(17) _);
                     3: _( x34604(9, 35, 14); x34604(8, 10, 35);
                           x34604(7, 1, 16); x34604(1, 65, 10);
                           w7 := zg; x34576(17) _);
                     7: _( x34604(35, 14, 8); x34604(1, 64, 10);
                           w7 := zg; x34576(17) _);
                     others: p10227(1, 306)
                     end;
                     p05673(v4)
                  _)
               _);
            2: _( x34576(37); p06047 _);
            3: _( x34576(36); p06077 _);
            4: _( v4 := p05356(1); x34576(38 + v4 - 1); p06126(v4) _);
            5: _( with t[d114 - 2] do
                  if el.lf then x34604(33, el.ms + el.mu - 1, el.mu)
                  else _(
                     x34601(10, 9); x34604(35, 7, 1); x34601(9, 13);
                     x34604(35, 14, 8); x34604(16, 1, 1);
                     x34601(17, 13); w7 := zg; x34576(32) _);
                  p06166 _);
            6: _( x34604(1, 64, 10); w7 := zg; x34576(32); p06252 _);
            7: _( x34576(21); p06320 _);
            8: _( x34576(22); p06366 _);
            9: _( x34576(23); p06366 _);
            10: _( v4 := p05356(1); x34576(26 + v4 - 1); p06502(v4) _);
            11: _( x34576(16); p06536 _);
            12: _( x34576(17); p06601 _);
            13: _( v4 := p05356(1); x34576(18 + v4 - 1); p06725(v4) _);
            14: _( x34576(11); w7 := zg; x34576(32); p06644 _);
            others: p10227(1, 307)
            end
         _) else p10227(1, 308);
         if 27 in g0050 then
            with t[d114 - 1] do _(
               write(d114 - 1:3, ': ', el.lw:4 hex, el.hi:12 hex);
               if el.mb then write(el.mu + el.ms - 1:5, el.mu:3)
               else write(' ', el.mx:7 hex);
               (q) for v4 := 0 to d112 do write(c[v4]:4);
               writeln(zb:17 oct)
            _)
         until d79 = 15;
         v4 := p05356(1); w8 := zg; x34576(144);
         if d114 <> 1 then p10227(1, 309);
         a := t[0];
         if (zb <> []) and (zb * [1, 2, 3, 8] = []) then
            p10227(p04031(zb), 310)
      _);
      procedure p22235;
      var v: integer;
      _( if w7 < w5 then _(
            if w6 = 0 then _( w6 := 128; v := 0 _) else v := 128
         _) else _( v := 0; g1035@[w7] := g1035@[w7] + 128 _);
         if w6 > 255 then _( p20224(w6 div 256 + v); v := 0 _);
         p20224(w6 + v)
      _);
      procedure p22266;
      _( g1070 := -1; p07246(true, 0, 0, 0, true) _);
      procedure p22275;
      var v: integer;
      _( p05247; p20253; g0613 := p05356(3); p05320; g1070 := -1;
         if 36 in bitset(k3) then p10227(51, 311);
         (*=c-*) p07246(true, 4, 'CEKЦИЯ', g0613 - 15, true) (*=c+*)
      _);
      procedure p22322;
      var v: integer; r: rec11; p: @sect;
      _( v := p05356(3); x33730(g0611, v); p := ;
         with p@ do _(
            if not (36 in bitset(k3)) then _(
               v := -sx; sx := 0; sz := 0 _)
            else _(
               v := p05356(1); sx := ;
               if not (37 in bitset(k3)) then sz := sg
               else _(
                  p20711(r);
                  if zb <> [] then _( sz := sg; p10227(50, 312) _);
                  sz := x34772(r.el)
               _)
            _);
            p07246(false, 5, sz, v, true)
         _)
      _);
      procedure p22424;
      var v: integer;
      _( g1176 := g1175;
         (q) repeat
            v := p05356(1);
            case v of
            1: g1170 := false;
            2: g1170 := true;
            3: g1175.f2 := 0;
            4: g1175.f2 := 1;
            5: g1175.f4 := 0;
            6: g1175.f4 := 1;
            7, 8, 9, 10, 11: _(
                  g1175.f01 := v - 7 - ord(v > 8); g1171 := v = 9 _);
            12: ;
            13: _(
                  p20253; p05247; g0613 := p05356(3); p05320;
                  g1175.fi := p05356(2); g1171 := p05356(1) = 1;
                  g1170 := p05356(1) = 1 _);
            others:
            end
         until v = 0;
         if g1175.s <> g1176.s then _(
            p20145; p20224(130); p20224(g1175.fi); g1176 := g1175 _);
         g1070 := -1;
         (*=c-*) p07246(true, 4, 'CEKЦИЯ', g0613 - 15, true) (*=c+*)
      _);
      procedure p22600;
      _( p20145; p20564(0, false); p20474(60817408);
         p07246(true, 3, -1, 0, true); p05551
      _);
      procedure p23147;
      var v3, v4, v5, v6, v7, v8: integer; v9: boolean; t: long;
          wv: w12; p13: @sect; r: rec11; v25: boolean;
         procedure p22616(a: integer);
         var t: long;
         _( a := p05574(a); r.c[a] := r.c[a] - 1;
            x34751(p13@.sz, t); x35020(r.el, t, r.el)
         _);
         procedure p22641(var a, b: integer; var c: rec11; d: integer);
         var i, j, v9, v10, v11, v12, v13: integer; v14: boolean;
             p: @sect;
         _( if 27 in g0050 then writeln(a:10, b:10, d:20 oct);
            v12 := x34770(c.el);
            v14 := (v12 < -134217728) or (v12 >= 134217728);
            v13 := ord(d = 3);
            if 27 in g0050 then writeln(v12:10, v14:8, v13:20 oct);
            if not v14 then _(
               v12 := (v12 + 134217728) mod 134217728;
               case d of
               1: v14 := v12 >= 4096;
               2: _( v14 := (v12 >= 524288) and (v12 < 133693440);
                     v12 := v12 mod 1048576 _);
               3: _( b := b + v12 div 4096; v12 := v12 mod 4096 _);
               others:
               end
            _);
            if v14 then _(
               if v13 = 1 then d101 := d101 + 1 else p05551;
               p10227(51, 313)
            _);
            a := a + v12; v12 := 0;
            (q) for i := 0 to d112 do _(
               v9 := c.c[i];
               if v9 <> 0 then _(
                  v11 := d103[i] - 15;
                  x33730(g0611, v11 + 15); p := ;
                  if not p@.si then _(
                     if v12 = 0 then _(
                        p20564(v13, true); p20431(a, b, d) _)
                     else if v12 < 0 then p20224(-v12)
                     else if v12 < 256 then _(
                        p20224(104); p20224(v12) _)
                     else _( p20224(105); p20224(v12 div 256);
                        p20224(v12) _);
                     if v9 < 0 then _( p20224(1); p20224(0); v12 := 1 _)
                     else v12 := 2;
                     v10 := abs(v9);
                     if v11 < 8 then _(
                        (q) for j := v12 to v10 do p20224(97 + v11 - 1);
                        v12 := -(97 + v11 - 1) _)
                     else if v11 < 256 then _(
                        (q) for j := v12 to v10 do _(
                           p20224(104); p20224(v11) _);
                        v12 := v11 _)
                     else _(
                        (q) for j := v12 to v10 do _(
                           p20224(105); p20224(v11 div 256);
                           p20224(v11) _);
                        v12 := v11 _);
                     if v9 < 0 then v12 := -17
                  _)
               _)
            _);
            if v12 = 0 then _( p20564(v13, false); p20431(a, b, d) _)
            else if v12 < 0 then p20224(128 - v12)
            else if v12 < 256 then _( p20224(232); p20224(v12) _)
            else _( p20224(233); p20224(v12 div 256); p20224(v12) _)
         _);
      _( if not (36 in bitset(k3)) then wv := g0724[k4]
         else wv.wi := p05356(3);
         p20145;
         v3 := p05356(1);
         p20711(r);
         v8 := x34770(r.el);
         if k4 < 128 then _( k4 := 16128 + k4; v25 := true _)
         else _( k4 := (k4 - 128) * 256; v25 := false _);
         if (37 in bitset(k3)) and g1171 then
            g1176.fs := g1176.fs + [1];
         if 38 in bitset(k3) then v4 := p05356(1) + 1
         else v4 := 0;
         if wv.wc and (v3 = 0) then p10251(48, 401);
         if wv.wd and (zb - [1, 8] = []) then
            (q) for v5 := 0 to d112 do
               if r.c[v5] <> 0 then _( p10251(38, 402); exit _);
         if v4 <> 0 then _(
            if zb - [8] <> [] then _(
               d101 := d101 + v4 div 2;
               if odd(v4) then p05551;
               p10227(51, 314) _);
            v9 := true;
            (q) for v6 := v4 downto 3 do _(
               v5 := p05356(zh[p05356(1)]);
               x33730(g0611, v5); p13 := ;
               v7 := p13@.sx * 268435456 + 60817408;
               p20564(0, false); p20474(v7);
               p07246(true, 3, v7, v8, v9);
               v9 := false; v8 := 0;
               p05551;
               p22616(v5)
            _);
            v5 := p05356(zh[p05356(1)]);
            if v5 <> 0 then _(
               x33730(g0611, v5); p13 := ; p22616(v5); v5 := p13@.sx _);
            if v4 <> 1 then _(
               v4 := v5 * 268435456 + 60817408; v7 := 3;
               v5 := p05356(zh[p05356(1)]);
               if v5 <> 0 then _(
                  x33730(g0611, v5); p13 := ; p22616(v5);
                  v5 := p13@.sx _)
               else v5 := v3
            _) else v7 := 2 - ord(v25);
            v3 := v5 * 268435456 + k4 * 4096;
            p22641(v3, v4, r, v7);
            if v7 = 3 then _(
               p07246(true, 3, v4, v8, v9); v9 := false; v8 := 0;
               p05551 _);
            p07246(true, 3, v3, v8, v9)
         _) else if zb - [8] = [] then _(
            v9 := (v3 = 0) and not wv.wc;
            (q) for v4 := 0 to d112 do _(
               v5 := r.c[v4];
               if v5 <> 0 then _(
                  x33730(g0611, d103[v4]); p13 := ;
                  with p13@ do
                  if s1x or (sa = 2) and v25 or (sa = 3) then
                     if (sx <> 0) and (v5 = 1) and v9 then _(
                        v3 := sx; r.c[v4] := 0;
                        x34751(sz, t); x35020(r.el, t, r.el);
                        v9 := false _)
                     else if d103[v4] < 16 then _(
                        p05551; p10227(43, 315) _)
                     else if s1x then _( p05551; p10227(52, 316) _)
                     else _( p05551; p10227(51, 317) _)
               _)
            _);
            v7 := v3 * 268435456 + k4 * 4096;
            p22641(v7, v5, r, 2 - ord(v25));
            p07246(true, 3, v7, v8, true)
         _) else if 8 in zb then p10227(43, 318)
         else _(
            v3 := v3 * 268435456 + k4 * 4096;
            p20564(0, true);
            if (w9.lw = 0) and (bitset(w9.hi) * [0..35] = []) then _(
               v4 := x34770(w9) + v3; p20474(v4); p22235;
               v4 := w5; v5 := w8 - 1 _)
            else _( p20474(v3); v4 := 0; v5 := w8 _);
            (q) for v4 := v4 to v5 do _( p20224(g1035@[v4]); (r) _);
            v3 := v8 mod 4096 + v3;
            p07246(true, 3, v3, v8, true)
         _);
         p05551;
         if g1171 and wv.wb then g1176.fs := g1176.fs + [1]
      _);
      procedure p23701;
      var v3, v4: integer; v5: pt;
      _( if (36 in bitset(k3)) and g1171 then
            g1176.fs := g1176.fs + [1];
         if 37 in bitset(k3) then _(
            v3 := p05356(3); x33730(g0623, v3); v5 := ;
            v3 := p05356(1);
            p20145;
            with v5@ do _(
               d126 := vb;
               case v3 of
               1: p07246(true, 0, 0, 0, true);
               2: _( p20564(0, false); v3 := vm; v4 := 48 - v3;
                     v4 := shift(integer(shift([0..47], v3)
                        mod [0..47]), v4);
                     v3 := 76546048 + v4; p20474(v3);
                     p07246(true, 3, v3, v4, true); p05551 _);
               3: _( p20564(0, false); v4 := vn - 1;
                     v3 := 66151424 + v4; p20474(v3);
                     p07246(true, 3, v3, v4, true); p05551 _);
               4: _( p20564(0, false); v3 := vm - 12; v4 := 48 - v3;
                     v4 := shift(integer(shift([0..47], v3)
                        mod [0..47]), v4);
                     v3 := 60817408 + v4; p20474(v3);
                     p07246(true, 3, v3, v4 * 4096 + 4095, true);
                     p05551;
                     p20564(0, false); p20474(76550143);
                     p07246(true, 3, 76550143, 0, false); p05551 _);
               5: _( p20564(0, false); v4 := vn - 1;
                     v3 := 66151424 + v4; p20474(v3);
                     p07246(true, 3, v3, v4, true); p05551;
                     p20564(0, false); v3 := vm; v4 := 48 - v3;
                     v4 := shift(integer(shift([0..47], v3)
                        mod [0..47]), v4);
                     v3 := 76546048 + v4; p20474(v3);
                     p07246(true, 3, v3, v4, false); p05551 _);
               6: _( p20564(0, false); v4 := 65 - vm - vn;
                     v3 := 66184192 + v4; p20474(v3);
                     p07246(true, 3, v3, v4, true); p05551;
                     p20564(0, false); v4 := 64 - vm;
                     v3 := 66151424 + v4; p20474(v3);
                     p07246(true, 3, v3, v4, false); p05551 _);
               7: _( p20564(0, true); v4 := vr;
                     p20474(66183168 + v4);
                     p20224(70); p20224(0); p20224(9); p20224(35);
                     p20224(14); p20224(8); p20224(10); p20224(35);
                     p20224(7); p20224(1); p20224(16); p20224(2);
                     p20224(4); p20224(65); p20224(145);
                     p07246(true, 3, 66183168, 0, true); p05551;
                     p20564(0, true); p20474(66150400 + v4);
                     p20224(70); p20224(0); p20224(35); p20224(14);
                     p20224(8); p20224(2); p20224(4); p20224(64);
                     p20224(10); p20224(145);
                     p07246(true, 3, 66150400, 0, false); p05551 _);
               others:
               end
            _)
         _) else p10227(2, 303)
      _);
      procedure p24313;
      var v3, v4, v5: integer; r: rec11; v: a8;
      _( v3 := p05356(zh[p05356(1)]); p20711(r);
         if 8 in zb then p10227(43, 319);
         p07246(true, 1, r.el.lw, r.el.h2, true);
         p20145;
         if (d112 = -1) and (zb = []) then _(
            p20564(3, false); p20515(r.el) _)
         else _(
            p20564(3, true); p20515(w9); p22235;
            (q) for v4 := w5 to w8 - 1 do _( p20224(g1035@[v4]); (r) _)
         _);
         if v3 <> 1 then _(
            p20564(g1174, true); v3 := v3 - 2;
            if v3 < 256 then _( p20224(136); p20224(0); p20224(v3) _)
            else _(
               p20224(137); p20224(0); p20224(0);
               p20224(v3 div 256); p20224(v3) _);
            v3 := v3 + 2
         _);
         d101 := d101 + v3
      _);
      procedure p24434;
      var v3, v4: integer; r: rec11; v: array [16..23] of integer;
      _( p20711(r);
         if 8 in zb then p10227(43, 320);
         v3 := x34770(r.el);
         if v3 < 0 then v3 := v3 + 4294967295 + 1;
         if (4294967295 < v3) or (v3 < 0) then _(
            p05551; p10227(46, 321) _);
         p07246(true, 3, v3, 0, true);
         p20145;
         if (d112 = -1) and (zb = []) then _(
            p20564(2, false); p20474(v3) _)
         else _(
            p20564(2, true);
            if (w9.lw = 0) and (bitset(w9.hi) * [0..15] = []) then _(
               p20474(x34770(w9)); p22235; v3 := w5; v4 := w8 - 1 _)
            else _( p20474(0); v3 := 0; v4 := w8 _);
            for v3 := v3 to v4 do _( p20224(g1035@[v3]); (r) _)
         _);
         p05551
      _);
      procedure p24543;
      var v3, v4, v5: integer; r: long;
      _( p20145;
         (q) for v3 := 1 to p05356(2) do _(
            r := g1135.el; p20564(3, false);
            (q) for v4 := 0 to 7 do _(
               x35125(r, -8, r); x35120(r, p05356(2), r); (r) _);
            p20515(r);
            p07246(true, 1, r.lw, r.h2, v3 = 1);
            d101 := d101 + 1; (r)
         _)
      _);
      procedure p24622;
      var v3, v4: integer;
      _( p20145; v4 := p05356(zh[p05356(1)]);
         p07246(true, 2, v4, 0, true);
         d101 := d101 + v4; v4 := v4 - 1;
         if v4 < 0 then else _(
            g1176 := g1175; p20564(g1174, true);
            if v4 < 256 then _( p20224(139); p20224(v4) _)
            else if v4 < 65536 then _(
               p20224(140); p20224(v4 div 256); p20224(v4) _)
         _)
      _);
      procedure p24672;
      var v3: integer; r: long;
      _( p20145; p07246(true, 0, 0, 0, true);
         while d79 <> 15 do (q) _(
            p05472(r); p20564(3, false); p20515(r);
            p07246(true, 1, r.lw, r.h2, false);
            d101 := d101 + 1; (r)
         _);
         g0634 := g0634 + 1; v3 := p05356(1)
      _);
      procedure p24733;
      var v: boolean;
      _( v := 36 in bitset(k3);
         if v and g1171 then g1176.fs := g1176.fs + [1];
         p07246(v, 0, 0, 0, true)
      _);
      procedure p24753;
      type h3 = record case integer of
                0: (b: hb); 1: (l: @long) end;
      var v3: h3; v4: pt; v5, v6, v7: integer; v8: pt; r: rec11;
          v20: pt;
      _( v7 := p05356(3); x33730(g0623, v7); v8 := ;
         if not (36 in bitset(k3)) then _(
            p20253;
            with v8@ do _(
               p20711(r);
               v3.b.hw := []; v3.b.hk := 6; v3.b.hbit := vh;
               (*=c-*) x33736(d83, v3.b) (*=c+*);
               v5 := x34772(r.el);
               if zb = [] then _(
                  if v5 >= 0 then vd := v5
                  else _(
                     vj := true; g0626 := g0626 + 1; vd := ;
                     x33742(g0627, g0626, r.el) _);
                  v5 := 0; v7 := 0;
                  (q) for v6 := 0 to d112 do _(
                     if r.c[v6] = 1 then _(
                        v5 := d103[v6]; v7 := v7 + 1 _)
                     else if r.c[v6] <> 0 then v7 := 2;
                     (r) _);
                  if v7 <= 1 then _(
                     ve := v5; vl := 0; va := true;
                     v3.b.hw := []; v3.b.hd := ord(vh) * 2 + 2;
                     (*=c-*) x33736(d83, v3.b) (*=c+*) _)
               _);
               if not va then _(
                  d94 := -x34423(d83); d97.bw := [];
                  d95 := 0; d98 := ; d99 := ord(vh) * 4;
                  d96 := 1; d93 := true;
                  v3.b.hw := []; (*=c-*) x33736(d83, v3.b) (*=c+*) _);
               if vh then _(
                  g0625 := g0625 + 1; v3.b.hw := [];
                  if vb > 1 then v3.b.hn := g1134;
                  (*=c-*) x33736(d83, v3.b) (*=c+*);
                  x33730(g0720, v1v); v20 := ;
                  v3.b.hw := []; v3.b.hn := x33037(v20@.w);
                  (*=c-*) x33736(d83, v3.b) (*=c+*);
                  v3.b.hw := []; v3.b.hn := x33040(v20@.w);
                  (*=c-*) x33736(d83, v3.b) (*=c+*);
                  v3.b.hw := [];
                  if vb > 1 then _(
                     x33730(g0715, vb); v4 := ;
                     v3.b.xb := true; v3.b.hd := v4@.be _);
                  (*=c-*) x33736(d83, v3.b) (*=c+*) _);
               if va then _(
                  v3.b.hw := [];
                  if ve < 16 then v3.b.h4b := ve
                  else v3.b.hd := ve - 15;
                  (*=c-*) x33736(d83, v3.b) (*=c+*);
                  v3.b.hw := []; v3.b.h32 := vd;
                  (*=c-*) x33736(d83, v3.b) (*=c+*) _)
               else if 8 in zb then p10227(43, 322)
               else _(
                  g1035@[w7] := g1035@[w7] + 128;
                  (q) for v7 := 0 to w8 - 1 do _(
                     p20224(g1035@[v7]); (r) _);
                  p20253 _)
            _)
         _);
         if v8@.vj then _(
            x33730(g0627, v8@.vd); v3.l := ;
            p07246(false, 1, v3.l@.lw, v3.l@.hi, true) _)
         else _(
            if v8@.ve < 16 then v7 := v8@.ve else v7 := 0;
            p07246(false, 2, v8@.vd, v7, true) _)
      _);
      procedure p25412;
      var v3: integer; v4: pt;
      _( v3 := p05356(3); x33730(g0623, v3); v4 := ;
         if 36 in bitset(k3) then p10227(2, 323);
         p07246(true, 6, v4@.vn + v4@.vm - 1, v4@.vn, true)
      _);
      procedure p25442;
      type hc = record case integer of
                0: (b: hb); 1: (c: packed array [0..5] of char) end;
      var v3, v4, v5, v6: integer; v7: hc;
      _( p20253; v3 := p05356(2); v4 := 0;
         while v3 > 12 do (q) _(
            v7.b.hw := []; v7.b.hk := 3;
            (*=c-*) x33736(d83, v7.b) (*=c+*);
            v7.b.hw := []; v7.b.hd := 3;
            (*=c-*) x33736(d83, v7.b) (*=c+*);
            (q) for v6 := 1 to 3 do _(
               v7.b.hw := [];
               (q) for v5 := 0 to 3 do v7.c[v5] := chr(p05356(2));
               (*=c-*) x33736(d83, v7.b) (*=c+*)
            _);
            v7.b.hw := []; v7.b.xb := false; v7.b.hd := v4;
            (*=c-*) x33736(d83, v7.b) (*=c+*);
            d3 := d3 + 1; v4 := d3; v3 := v3 - 12
         _);
         v7.b.hw := []; v7.b.hk := 8;
         (*=c-*) x33736(d83, v7.b) (*=c+*);
         v7.b.hw := []; v7.b.hd := 3;
         (*=c-*) x33736(d83, v7.b) (*=c+*);
         v6 := 1; v5 := 0; v7.b.hw := [];
         (q) for v3 := v3 downto 1 do _(
            if v5 = 4 then _(
               (*=c-*) x33736(d83, v7.b) (*=c+*);
               v6 := v6 + 1; v5 := 0; v7.b.hw := [] _);
            v7.c[v5] := chr(p05356(2)); v5 := v5 + 1; (r)
         _);
         (*=c-*) x33736(d83, v7.b) (*=c+*);
         (q) for v6 := v6 to 2 do _(
            v7.b.hw := []; (*=c-*) x33736(d83, v7.b) (*=c+*) _);
         v7.b.hw := []; v7.b.xb := false; v7.b.hd := v4;
         (*=c-*) x33736(d83, v7.b) (*=c+*);
         p07246(false, 0, 0, 0, true)
      _);
      procedure p25662;
      var v3: hb; v4, v5: integer; v6: pt;
      _( p20253; v4 := 0;
         (q) repeat
            v5 := p05356(3);
            if v5 = 0 then exit q;
            v3.hw := []; v3.hk := 3; (*=c-*) x33736(d83, v3) (*=c+*);
            v3.hw := []; v3.hd := 3; (*=c-*) x33736(d83, v3) (*=c+*);
            x33730(g0720, v5); v6 := ;
            v3.hw := []; v3.hn := x33037(v6@.w);
            (*=c-*) x33736(d83, v3) (*=c+*);
            v3.hw := []; v3.hn := x33040(v6@.w);
            (*=c-*) x33736(d83, v3) (*=c+*);
            v3.hw := []; v3.hn := g1134;
            (*=c-*) x33736(d83, v3) (*=c+*);
            v3.hw := []; v3.hd := v4; (*=c-*) x33736(d83, v3) (*=c+*);
            d3 := d3 + 1; v4 := ;
         until false;
         (r) repeat
            v5 := p05356(3);
            if v5 = 0 then exit r;
            v3.hw := []; v3.hk := 8; (*=c-*) x33736(d83, v3) (*=c+*);
            v3.hw := []; v3.hd := 3; (*=c-*) x33736(d83, v3) (*=c+*);
            x33730(g0720, v5); v6 := ;
            v3.hw := []; v3.hn := x33037(v6@.w);
            (*=c-*) x33736(d83, v3) (*=c+*);
            v3.hw := []; v3.hn := x33040(v6@.w);
            (*=c-*) x33736(d83, v3) (*=c+*);
            v3.hw := []; (*=c-*) x33736(d83, v3) (*=c+*);
            v3.hw := []; v3.hd := v4; (*=c-*) x33736(d83, v3) (*=c+*);
         until false;
         p07246(false, 0, 0, 0, true)
      _);
      procedure p26105;
      var v3, v4: integer; v5, v6: pt;
      _( if g1171 then g1176.fs := g1176.fs + [1];
         (*=c-*) p07246(true, 4, ' BЛOЖ.', g0635, true) (*=c+*);
         g0635 := g0635 + 1;
         x33730(g0715, p05356(3)); v5 := ;
         x33730(g0720, v5@.bd); v6 := ;
         g0636[g0635].f5 := v6@.w
      _);
      procedure p26145;
      _( if g0635 > 1 then g0635 := g0635 - 1;
         (*=c-*) p07246(true, 4, ' BЛOЖ.', g0635, true) (*=c+*)
      _);
      procedure p26157;
      var v3, v4: integer;
      _( p10104(13 in g1044, 0);
         if not (36 in bitset(k3)) then _(
            (q) for v3 := p05356(zh[p05356(1)]) downto 2 do
               p10104(12 in g1044, 7);
            p10104(13 in g1044, 0)
         _)
      _);
      procedure p26265;
      type a9 = array [0..8] of a6;
         procedure p26213(var a: a9);
         var v4, v5, v6: integer;
         _( (q) for v4 := 0 to 8 do _( a[v4] := '      '; (r) _);
            v6 := p05356(2);
            if v6 = 0 then exit;
            v5 := (54 - v6) div 2; v4 := v5 div 6; v5 := v5 mod 6;
            repeat
               a[v4][v5] := chr(p05356(2)); v5 := v5 + 1;
               if v5 = 6 then _( v5 := 0; v4 := v4 + 1 _);
               v6 := v6 - 1; (r)
            until v6 = 0
         _);
      _( if 36 in bitset(k3) then p26213(g1104);
         (*=c-*) p26213(g1115) (*=c+*);
         p10104(10 in g1044, 0)
      _);
      procedure p26300;
      _( if 21 in g1044 then g1060 := true;
         p26265
      _);
      procedure p26306;
      var v3, v4: integer;
      _( v3 := p05356(zh[p05356(1)]); v4 := p05356(zh[p05356(1)]);
         p10104(10 in g1044, 0);
         if 21 in g1044 then
            if g1057 + v3 + v4 > g1047 then g1060 := true
            else for v3 := v3 downto 1 do _( p04051; writeln(' ') _)
      _);
      procedure p26354;
      var v3, v4: integer;
      _( v4 := p05525;
         g1044 := g1044 * [33] + bitset(v4);
         g1050 := p05356(zh[p05356(1)]);
         g1051 := p05356(zh[p05356(1)]);
         g1052 := p05356(zh[p05356(1)]);
         p10104(10 in g1044, 0)
      _);
      procedure p26416;
      var v3: integer;
      _( p07246(false, 0, 0, 0, true);
         d12[0] := d12[0] + 1; d11 := ; d9 := d9 + 1;
         (*=c-*) g1026.ext := p05525; g1026.lib := p05525;
         g1026.name := p05525; (*=c+*)
         d16[d9] := g1026; d16[d9].ext[6] := chr(d11);
         d12[d9] := x34323;
         v3 := p05356(zh[p05356(1)]); x34127(v3, g1034);
         d6 := 0; d7 := 0
      _);
      procedure p26476;
      _( if (36 in bitset(k3)) and g1171 then
            g1176.fs := g1176.fs + [1];
         p20145; p20564(0, false); p20474(60817408);
         p07246(true, 3, -1, 0, false); p05551
      _);
      procedure p26524;
      _( p10173(p05356(2), p05356(3)) _);
      procedure p26535;
      var v3: integer; v4: pt;
      _( p20145; p20564(0, false); p20474(334606360);
         p07246(true, 3, 334606360, 0, true); p05551;
         p20564(g1174, true); p20224(141);
         v3 := p05356(zh[p05356(1)]);
         if v3 <> 0 then _(
            x33730(g0623, v3); v4 := ; v3 := v4@.vr _);
         v3 := p05356(1) * 268435456 +
            (24 + k4 - 293) * 8 * 1048576 + v3;
         p20474(v3); p20474(0);
         p07246(true, 3, v3, 0, false);
         d101 := d101 + 1;
         if g1171 then g1176.fs := g1176.fs + [1]
      _);
      procedure p26635;
      var v3: integer; r: rec11;
      _( p20711(r);
         if 8 in zb then p10227(43, 324);
         p07246(true, 1, r.el.lw, r.el.h2, false);
         if (d112 = -1) and (zb = []) then _(
            p20564(3, false); p20515(w9) _)
         else _(
            p20564(3, true); p20515(w9); p22235;
            (q) for v3 := w5 to w8 - 1 do _( p20224(g1035@[v3]); (r) _)
         _);
         d101 := d101 + 1
      _);
      procedure p26712;
      var v3: integer;
      _( v3 := p05356(zh[p05356(1)]);
         if v3 <> 0 then _(
            d9 := d9 - v3; d11 := ord(d16[d9].ext[6]);
            x34327(d12[d9 + 1]);
            g1026 := d16[d9]; g1026.ext[6] := '_000'
         _);
         d6 := p05356(zh[p05356(1)]); d7 := p05356(zh[p05356(1)]);
         d8 := true
      _);
      procedure p26775;
      var v3, v4, v5: integer;
      _( p07246(false, 0, 0, 0, true); v3 := p05356(1);
         while v3 <> 0 do (q) _(
            v5 := p05525;
            if v3 = 7 then g0050 := g0050 + bitset(v5)
            else g0050 := g0050 - bitset(v5);
            v3 := p05356(1)
         _);
         if 0 in g0050 then _( p04347('ПPOXOД'); g0050 := g0050 - [0] _)
      _);
   _( d82 := p05356(2); k3 := p05356(3); k4 := k3 mod 512; d126 := 0;
      if k4 <= 255 then p23147
      else if k4 <= 383 then
         case k4 of
         258: p22266;
         259: p22275;
         260: p22322;
         261: p22424;
         262, 263: p22600;
         301: p23701;
         264: p24313;
         265, 266, 267: p24434;
         268: p24543;
         269: p24622;
         270: p24672;
         271: p24733;
         274: p24753;
         275: p25412;
         276: p25442;
         297: p25662;
         277: p26105;
         278: p26145;
         281, 282, 283, 284: p26157;
         285: p10104(13 in g1044, 0);
         288: p26265;
         287: p26300;
         289: p26306;
         290, 291, 292: p26354;
         257, 273, 279, 280, 286: p07246(false, 0, 0, 0, true);
         293, 294: p26535;
         299: p07246(false, 0, 0, 0, true);
         295: p10104(14 in g1044, 99);
         296: p10104(14 in g1044, 0);
         272: p26416;
         300: p26524;
         298: p26775;
         others: p10227(1, 325)
         end
      else
         case k4 of
         449: _( p20253; goto 4 _);
         450: p26476;
         451: g1044 := g1044 + [21];
         452: g1044 := g1044 - [21];
         454: p26712;
         453: p26635;
         others: p10227(1, 326)
         end
   _);
   procedure p27254;
   var v: hb;
   _( v.hw := []; v.hk := 255; (*=c-*) x33736(d83, v) (*=c+*);
      v.hw := []; v.hd := 1; (*=c-*) x33736(d83, v) (*=c+*);
      x34427(d83); x34427(g1043); x34427(g0630); p05247;
      if 29 in g0050 then p04347('ПOCЛE ')
   _);
   procedure p27356;
   var i, j, k, v6, v7, v8, v9, v10, v11, v12, v13: integer;
       p14: record case integer of 0: (p: pt); 1: (l: @long) end;
       p15, p16, p17, p18, p19: pt; v20, v21: integer;
       v22, v23: a4; a, b: array [1..8] of integer; c: char;
      procedure p27320(var a, b: integer; c: integer);
      var v6: integer; v7: pt;
      _( while c <> 0 do (q) _(
            x33730(g0717, a); v7 := ;
            v6 := v7@.ne - v7@.nc - b;
            if v6 >= c then _( b := b + c; c := 0 _)
            else _( a := a + 1; b := 0; c := c - v6 - 1 _)
         _)
      _);
   _( x33730(g0717, 1); p15 := ;
      (q) for i := 2 to g0716 + 1 do _(
         x33730(g0717, i); p16 := ;
         p15@.ne := p16@.nc - 1; p15 := p16
      _);
      k := g0716 div 2;
      while k > 0 do _(
         (q) for i := k + 1 to g0716 do _(
            j := i - k;
            while j > 0 do (q) _(
               x33731(g0720, j + k); p18 := ;
               x33731(g0720, j); p19 := ;
               if (*=c-*) x33034(p18@.w, p19@.w) (*=c+*) then _(
                  v21 := p19@.w; p19@.w := p18@.w; p18@.w := v21;
                  x36036(g0720, j + k); x36036(g0720, j);
                  x33732(g0717, j + k); p15 := ;
                  x33732(g0717, j); p16 := ;
                  v20 := p16@.w; p16@.w := p15@.w; p15@.w := v20;
                  j := j - k
               _) else j := -1
            _)
         _);
         k := k div 2
      _);
      if 32 in g1044 then _(
         g1060 := true;
         g1115 := '      '; g1116 := '    T '; g1117 := ' A  Б ';
         g1120 := ' Л  И '; g1121 := ' Ц  A '; g1122 := '    И ';
         g1123 := ' M  E '; g1124 := 'H     '; g1125 := '      ';
         v8 := (g1046 + 1) div 18; v9 := g0622; k := 1;
         if (34 in g1044) and (g1057 + 3 <= g1047 div 2) then
            v6 := g1047 - (g1047 div 2 + 3)
         else v6 := g1047;
         a[1] := 1; b[1] := 0;
         while v9 > 0 do (q) _(
            v7 := v6 - 3;
            if v7 * v8 > v9 then v7 := (v9 + v8 - 1) div v8;
            v6 := g1047;
            (q) for j := 2 to v8 do _(
               k := k + v7;
               if k <= g0622 then _(
                  a[j] := a[j - 1]; b[j] := b[j - 1];
                  p27320(a[j], b[j], v7) _)
            _);
            k := k + v7 - v7 * v8;
            (q) for i := 1 to v7 do _(
               p04051;
               (q) for j := 1 to v8 do _(
                  if k <= g0622 then _(
                     x33730(g0720, a[j]); p18 := ;
                     p04014(p18@.w);
                     x33730(g0717, a[j]); p15 := ;
                     x33730(g0623, p15@.nc + b[j]); p17 := ;
                     with p17@ do _(
                        if vh then c := '+' else if vi then c := '-'
                        else if vf then c := ':' else c := ' ';
                        write(c);
                        if vj then c := '>' else if ve = 0 then c := '='
                        else if ve = 1023 then c := '*'
                        else if ve < 16 then c := '/' else c := ' ';
                        write(c, vd:7 hex, ' ')
                     _);
                     p27320(a[j], b[j], 1)
                  _);
                  k := k + v7; (r)
               _);
               k := k - v8 * v7 + 1;
               writeln
            _);
            k := k - v7 + v7 * v8;
            v9 := v9 - v7 * v8;
            a[1] := a[v8]; b[1] := b[v8]
         _)
      _);
      if 37 in g1044 then _(
         g1060 := true;
         g1115 := '      '; g1116 := ' T  A '; g1117 := ' Б  Л ';
         g1120 := ' И  Ц '; g1121 := ' A    '; g1122 := ' C  C ';
         g1123 := ' Ы  Л '; g1124 := ' O  K '; g1125 := '      ';
         if 25 in g1044 then v6 := 34 else v6 := 8;
         g1032 := g1032 + 1; v12 := g1032 + 1;
         v10 := 6 div v12 + 1; v11 := 0;
         for i := 1 to g0716 do _(
            x33730(g0720, i); p18 := ;
            j := x33033(p18@.w); v22 := x33037(p18@.w);
            v23 := x33040(p18@.w);
            x33730(g0717, i); p15 := ;
            (q) for k := p15@.nc to p15@.ne do _(
               x33730(g0623, k); p17 := ;
               if not ((not p17@.v1x or (28 in g1044)) and
                  (p17@.v1x or (29 in g1044)) and
                  (p17@.v1x or (p17@.v2x = 0) or not (27 in g1044)))
               then else _(
                  p04051;
                  write(v22:4, v23:4, '_000':9 - j);
                  if 25 in g1044 then with p17@ do _(
                     if vh then c := '+' else if vi then c := '-'
                     else if vf then c := ':' else c := ' ';
                     write(c);
                     if ve = 0 then write('= ':9)
                     else if ve = 1023 then write('* ':9)
                     else if ve < 16 then _(
                        write(' ':7, ve:1 hex, '/') _)
                     else _(
                        x33730(g0612, ve); p18 := ;
                        write('_000':9 - x33033(p18@.w),
                           x33037(p18@.w):4, x33040(p18@.w):4, ' ')
                     _);
                     if vj then _(
                        x33730(g0627, vd); p14.l := ;
                        write(p14.l@.lw:4 hex, p14.l@.hi:12 hex) _)
                     else _(
                        write(vd:7 hex);
                        if (vl = 0) or not va then write(' ':9)
                        else if vk then _(
                           write('[', vn + vm - 1:2, ':', vn:2, ']');
                           if 5 < 7 then write(' ':2) _)
                        else _(
                           write('(', vl:7 hex, ')') _)
                     _)
                  _);
                  v13 := v6;
                  if 26 in g1044 then _(
                     if d12[0] <> 0 then _(
                        if p17@.v2x = 0 then _(
                           write(' ':7); v11 := 0 _)
                        else _(
                           write(' ', d28[p17@.v2x].name:6);
                           v11 := -1 _);
                        v13 := v13 + 7
                     _);
                     write(p17@.vp:g1032, '  ');
                     v13 := v13 + g1032 + 2;
                     v8 := p17@.vq;
                     while v8 <> 0 do (q) _(
                        x33730(g0723, v8); p14.p := ;
                        v8 := p14.p@.kb;
                        if v8 <> v11 then v13 := v13 + v10 * v12;
                        v13 := v13 + v12;
                        if v13 >= g1046 then _(
                           writeln; p04051;
                           v13 := v13 - (v13 - 10) div v12 * v12;
                           write(' ':v13); v13 := v13 + v12;
                           if v10 <> 0 then _(
                              v11 := v8;
                              write(' ':v10 * v12 - 6, d28[v11].name:6);
                              v13 := v13 + v10 * v12 _)
                        _) else if v8 <> v11 then _(
                           v11 := v8;
                           write(' ':v10 * v12 - 6, d28[v11].name:6) _);
                        with p14.p@ do _(
                           case kc of
                           0: c := '=';
                           1: c := ' ';
                           2: c := '*';
                           3: c := ':';
                           4: c := 'A';
                           others: c := '_077'
                           end;
                           write(ka:g1032, c); v8 := kd
                        _)
                     _)
                  _);
                  writeln
               _)
            _)
         _)
      _)
   _);
   procedure p30443;
   var i, j, k: integer; p: pt; c: char;
   _( g1060 := true;
      g1115 := '      '; g1116 := ' T  A '; g1117 := ' Б  Л ';
      g1120 := ' И  Ц '; g1121 := ' A    '; g1122 := ' C  E ';
      g1123 := ' K  Ц '; g1124 := ' И  Й '; g1125 := '      ';
      (q) for j := 1 to g0605 do _(
         p04051; writeln(' '); p04051;
         write(' ':23, 'ЭЛEM.MOДYЛЬ ');
         x33730(g0606, j); p := ; p04014(p@.w); writeln;
         (q) for i := 16 to g0610 do _(
            x33730(g0611, i); p := ;
            if p@.sf = j then _(
               p04051; write(i - 15:4, ' ');
               x33730(g0612, i); p := ; p04014(p@.w);
               write('  ');
               x33730(g0611, i); p := ;
               with p@ do _(
                  k := so + ord(sj);
                  writeln(sg:7 hex, ':', k - 1:7 hex, '=', k - sg:7 hex)
               _);
               p04051; write(' ':15);
               case p@.sa of
               1: write('П12,');
               2: write('П20,');
               3: write('П27,')
               end;
               case p@.sb of
               0: write('     ');
               8: write('CEKT,');
               10: write('ЛИCT,');
               others: write('(', p@.sb:2, '),')
               end;
               if p@.si then write('ФИKT,') else write('ЗAГP,');
               if p@.sn then write('ГЛOБ,') else write('ЛOK, ');
               case p@.sh of
               1: write('ПOCЛ,');
               2: write('COBM,');
               others: write('****,')
               end;
               if p@.s1x then write('CBOБ,') else write('ПOЗ, ');
               if p@.ub = 1 then write('_376') else write('*');
               if p@.ud = 1 then write('_372') else write('*');
               case p@.ua of
               0: c := '*';
               1: c := '_360';
               2: if p@.sd then c := 'B' else c := '_354';
               3: c := 'M'
               end;
               write(c, ',');
               if p@.se then write('ПPEФ,') else write('HПP, ');
               if p@.s1z then write('ЛKOM,') else write('HЛK, ');
               writeln
            _)
         _)
      _)
   _);
   procedure p31025;
   var v3, v4: integer;
      procedure p31010(a: integer);
      _( write(a div 50:3, '.', a mod 50 * 2:2, '  ') _);
   _( g1060 := true; g1115 := '      '; g1116 := ;
      g1117 := ' C  T '; g1120 := ' A  T '; g1121 := ' И  C ';
      g1122 := ' T  И '; g1123 := ' K  A '; g1124 := '      ';
      g1125 := ;
      if g1046 < 111 then _(
         p04051;
         writeln(banner, ': BEPCИЯ ', '5.04', ' OT ', '10.11.89')
      _);
      if g1167 + d119 <> 0 then _(
         p04051; writeln(' '); p04051;
         writeln('ЧИCЛO OШИБOK', g1167:4, ', ПPEДYПPEЖДEHИЙ', d119:4);
         p04051; writeln(' ')
      _);
      if g1126 <> 0 then _(
         p04051;
         writeln('MOДYЛЬ ЗAПИCAH B ЗOHЫ ', g1126:6 oct, '-',
            g1126 + x34423(d83) div 1024:6 oct)
      _);
      p04051; writeln(' '); p04051;
      writeln(
'ПEPEM.  ЭM  CEKЦИЙ  БЛOKOB  OБ''EKTOB  ИCПOЛЬЗ.  ЛИTEPAЛOB');
      p04051;
      writeln(g0721:4, g0605:6, g0610 - 15:6, g0714:8, g0622:10,
         d116:10, g0633 - 1:10);
      p04051; writeln(' '); p04051;
      writeln(' ФAЙЛOB  CTPOK  BXOДHЫX  BHEШHИX  ПPEФ.  ДЛ.ЗH');
      p04051;
      writeln(d12[0] + 1:5, g1033:8, g0625:8, d115:9, d3:7, g0626:7);
      p04051; writeln(' '); p04051;
      writeln(
'BPEMЯ   PAЗБOP   CИHT.   COPT.   ЛEKC.   ЗAГЛ.  ГEHEP.  ПEЧATЬ');
      p04051;
      writeln(
'(CEK)   ПAPAM.  AHAЛИЗ  TAБЛИЦ  AHAЛИЗ  MOДYЛЯ  MOДYЛЯ  TAБЛИЦ');
      p04051;
      besm(630004B); (r); besm(150000B : 0); v3 := ;
      p31010(v3 - g1061); p31010(g1062 - g1061);
      p31010(g1063 - g1062); p31010(g1064 - g1063);
      p31010(g1065 - g1064); p31010(g1066 - g1065);
      p31010(g1067 - g1066); p31010(v3 - g1067);
      writeln
   _);
_( zi := g1035; g1166 := 2;
   p10275; besm(630004B); (r); besm(150000B : 0); g1064 := ;
1: p16001;
   g1164 := true;
2: besm(630004B); (r); besm(150000B : 0); g1065 := ;
   p16210; g1166 := 3; p16420;
   besm(630004B); (r); besm(150000B : 0); g1066 := ;
3: p27034; goto 3;
4: besm(630004B); (r); besm(150000B : 0); g1067 := ;
   p27254; g1166 := 4; g1026 := d16[0]; g1026.ext[6] := '_000';
   if 30 in g1044 then p30443;
   if [32, 37] * g1044 <> [] then p27356;
   if (g1167 <> 0) or (35 in g1044) then p31025
_);
%
_( p31255 _).
