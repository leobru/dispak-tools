(*=p-,t-,s8,y+,o-,a4,w+*)
program acc2ov1(input, output,
    za, zb, zc, zd, ze, zf, zg, zh, zi, zj, zk,
    zl, zm, zn, zo, zp, zq, zr, zs, zt, zu);
% Оверлей 1 ассемблера АСС2 (режим совместимости; том 4001, файл
% 0215, зоны 0221-0232), восстановленный по коду и по тексту оверлея 1
% АСС3 (programs/acc3/ov1.pas). Сборка и сравнение с оригиналом:
%   cd programs/acc2; python3 ovtry.py ov1 ov1.pas --full
% Имена те же, что у АСС3, то есть по адресам АСС3; новые глобалы
% h0050..h0054 стоят перед g0050 (глобалы АСС2 дальше на 5 слов).
% Отличия от АСС3: слова по 48 разрядов вместо 64 (восьмеричная печать,
% пределы 48, 6 символов, константы 'K' и 'Ч'), значения режима в
% h0050..h0054 и обработчик 401 (p14157). Весь уцелевший код
% пользователя (04014-17346) и весь пул констант (388 слов) совпадают
% слово в слово.
%
% Зона 0225 (адреса 14000-15777) на томе утрачена (нули). Её
% обработчики (p14337..p16336) взяты из АСС3 с изменениями, которые
% показывает сравнение ранних сборок АССЕМБЛЕР.РЕЖИМ3 и
% АССЕМБЛЕР.РЕЖИМ2 (том 2248, verdiff.py): в p14406
% позиции полей команды 48-разрядного режима. Проверки: адреса входов
% всех обработчиков в таблице case (17007-17044), уцелевшие слова по
% краям зоны, пул и места глобалов совпадают; символ '_044' из
% РЕЖИМ2 в p15565 пул отвергает. Зону собирает zone.py;
% elf.py транслирует восстановленным АСС2 ЭЛФ.ТЕКСТ и
% получает ЭЛФ.МОД тома (обработчики p14337, p14626, p14645, p14665,
% p14676, p15152, p15251, p15472, p16336 при этом вызываются, прочие
% проверены только размерами, входами и пулом).
%
% Пустые метки (x), (y), (z) в p10442 и в ветви 'K' p11151 дают
% выравнивания `мода` и `ржа 7` оригинала (шаг цикла for с нового слова,
% метка после if-else).
type bitset = set of 0..47;
     a4 = packed array [0..3] of char;
     a6 = packed array [0..5] of char;
     s5 = set of 0..4;
     digits = array [0..23] of char;
     long = packed record case integer of
          0: (hi, lo: integer);
          1: (hs: bitset; lt: 0..65535; lb: 0..4294967295);
          2: (h2: integer; lw: 0..65535)
         end;
     word3 = record ext, lib, name: alfa end;
     name12 = packed array [0..20] of char;
     pt = @entry;
     t0 = array [0..5] of alfa;
     t1 = array [1..58] of t0;
     r2 = packed record f1: 0..1023; f2: 0..31; f3: 0..4095;
                 f4: 0..2097151; f5: integer end;
     t2 = array [1..23] of r2;
     nv = record nm: alfa; v: integer end;
     nvs = array [0..255] of nv;
     pw = @nvs;
     entry = packed record case integer of
          0: (w, w1, w2: integer);
          1: (sa: 0..3; sb, sc: 0..31; sd, se: boolean; sf: 0..127;
              sg: 0..134217727; s1x: boolean; sh: 0..3; si, sj: boolean;
              sk: 0..31; sl, sm: boolean; s1y: 0..3; sn: boolean;
              s1z: boolean; s16: boolean; s1w: 0..15; so: 0..134217727;
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
          4: (na: 0..31; nb: 0..127; nc: 0..4095; nd, ne: 0..4095);
          5: (bs: set of 0..23);
          6: (nm: alfa);
          7: (e0: integer; el: long);
          8: (t0: 0..127; tc: s5; t1: 0..68719476735;
              t2: 0..31; tk: s5);
          9: (u0: 0..127; ua: 0..3; ub: 0..1; uc: boolean; ud: 0..1);
          10: (x0: integer; xt: 0..65535)
         end;
     lbits = packed record lv, lx: 0..15; lc1, lc2: char; ly: boolean;
                    lb, l26, l27, l28, l29: boolean; lz: 0..3;
                    ld, le: char end;
     h2 = packed record ha, hb: 0..16777215 end;
     op2 = packed record nm: alfa; case integer of
           0: (f0, fl, fr: 0..511; fk: 0..4095; fc: 0..511);
           1: (q0: 0..33554431; qb: boolean; qa, qa2: 0..1;
               qb2, qc, qd: boolean; q31: 0..3; qe, qf: 0..7);
           2: (r0: 0..134217727; r27: boolean)
          end;
     ops = array [0..255] of op2;
     po = @ops;
     buf = array [1..144] of char;
     hx = packed array [0..11] of 0..15;
     ints = array [0..4095] of integer;
     r5 = packed record case integer of
          0: (s: bitset);
          1: (f01: 0..3; f2, f3, f4: 0..1);
          2: (fi: 0..31)
         end;
     dr = packed record e0, e1, e2: boolean; ea: 0..1023; es: s5 end;
     w12 = packed record case integer of
           0: (wa, wb, wc, wd, we, wf: boolean; wg, wh: 0..7);
           1: (wi: 0..4095)
          end;
     sv = packed record s: bitset; i: integer; ca, cb, cc: 0..65535 end;
     w10 = packed record fa: 0..1023; fc: 0..2047; fd: 0..134217727 end;
     a10 = array [0..4095] of w10;
     p10 = @a10;
     pint = @ints;
     sect = packed record sa: 0..3; sb, sc: 0..31; sd, se: boolean;
              sf: 0..127; sg: 0..134217727; s1x: boolean; sh: 0..3;
              si, sj: boolean; sk: s5; sl, sm: boolean; s1y: 0..3;
              sn: boolean; s1z: 0..1; s16: boolean; s1w: 0..15;
              so: 0..134217727 end;
const banner = 'ACCEMБЛEP  Э1-KБ';
var h0050, h0051, h0052, h0053, h0054: integer;
    g0050: bitset;
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
    g1133: pt;
    g1134: integer;
    g1135: entry;
    g1140, g1142, g1144, g1146: long;
    g1150, g1151, g1152, g1153, g1154, g1155: integer;
    g1156, g1157, g1160, g1161, g1162, g1163: integer;
    g1164: boolean;
    g1165, g1166, g1167: integer;
    g1170, g1171, g1172: boolean;
    g1173, g1174: integer;
    g1175: r5;
    g1176: s5;
    za: integer; (* 20634 *)
    zb: bitset; (* 20635 *)
    zc: integer; (* 20636 *)
    zd: integer; (* 20637 *)
    ze: integer; (* 20640 *)
    zf: array [0..1] of integer; (* 20641 *)
    zg: integer; (* 20643 *)
    zh: array [5..10] of integer; (* 20644 *)
    zi: integer; (* 20652 *)
    zj: lbits; (* 20653 *)
    zk: integer; (* 20654 *)
    zl: array [0..255] of integer; (* 20655 *)
    zm: array [0..63] of h2; (* 21255 *)
    zn: array [1..246] of op2; (* 21355 *)
    zo: buf; (* 22331 *)
    zp: boolean; (* 22551 *)
    zq: boolean; (* 22552 *)
    zr: char; (* 22553 *)
    zs: char; (* 22554 *)
    zt: integer; (* 22555 *)
    zu: integer; (* 22556 *)
%
function x22563(n: integer): integer; assembler;
function x22567(n: integer): a4; assembler;
function x22570(n: integer): a4; assembler;
procedure x23460(a: pt; b: integer); fortran;
procedure x23461(a: pt; b: integer); fortran;
procedure x23470(a: pt; b: integer; var e: entry); fortran;
procedure x23472(a: pt; b: integer; var r: long); fortran;
procedure x23466(a: pt; var b: hx); fortran;
procedure x26567(a, b: integer; s: alfa; t: pt); fortran;
procedure x23734; assembler;
function x23752(c: char): boolean; assembler;
procedure x23761(n: integer); assembler;
procedure x23762(n: integer); assembler;
procedure x27233(a, b, c: integer); assembler;
function x24033: integer; assembler;
procedure x24236(var a: digits; n, b: integer; var r: long);
   assembler;
function x24543(var r: long): integer; assembler;
function x24545(var r: long): integer; assembler;
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
function x24276(n: alfa): integer; assembler;
function x24067: alfa; assembler;
procedure x23760(n: integer); assembler;
procedure x23764(a, b: integer); assembler;
procedure x23765(a, b: integer); assembler;
function x22564(a, b: alfa): boolean; assembler;
function x26745(var a: buf; var v: integer): boolean; assembler;
procedure x27026(n: integer); assembler;
function x27022: integer; assembler;
procedure x27115(var a, b, c: long); assembler;
procedure x27116(var a, b, c: long); assembler;
procedure x27117(var a, b, c: long); assembler;
procedure x27120(var a, b: long; n: integer; var c: long); assembler;
procedure x27121(var a, b: long); assembler;
procedure x24555(var a, b, c: long); assembler;
procedure x24573(var a, b, c: long); assembler;
procedure x24601(var a, b, c: long); assembler;
procedure x24612(var a, b, c: long); assembler;
procedure x24624(var a, b, c: long); assembler;
procedure x25004(var a, b, c, d: long); assembler;
procedure x23763(a, b: integer); assembler;
procedure x23766(a, b, c: integer); assembler;
function x24324(s: alfa): integer; assembler;
function x24421(s: alfa): integer; assembler;
function x24400(s: alfa): integer; assembler;
function x24305(s: alfa): integer; assembler;
function x24366(s: alfa): integer; assembler;
procedure x24030(s: bitset); assembler;
function x24317(s: alfa): integer; assembler;
procedure x24025(var r: long); assembler;
procedure x24031(n: integer); assembler;
procedure x24466(var a, b, c: long); assembler;
procedure x24524(n: integer; var r: long); assembler;
procedure x24640(var a, b: long); assembler;
procedure x24657(var a, b, c: long); assembler;
procedure x24673(var a: long; n: integer; var c: long); assembler;
procedure x24700(var a: long; n: integer; var c: long); assembler;
function OPENF(var name: word3; writing: boolean;
               var descriptor: integer): integer; assembler;
%
procedure p04014(n: integer);
_( write(x22567(n):4); write(x22570(n):4);
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
                    sg:h0050 hex, '-', so:h0050 hex, p04341(sj):1)
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
         writeln(i:5, ' ', p@.xt:4 hex, p@.w:16 oct)
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
label 1, 2, 3, 4;
var d3: integer;
    d4: integer;
    d5: array [1..8] of sv;
    d35: integer;
    d36: array [1..8] of dr;
    d46: bitset;
    d47: integer;
    d50: boolean;
    d51: pt;
    d52: boolean;
    d53, d54: integer;
    d55: array [0..9] of long;
    d101: integer;
    d102: integer;
    d103: boolean;
    d104: array [0..2] of array [1..3] of integer;
    d115: word3;
    d120, d121, d122, d123, d124: integer;
%
procedure p05214(k: integer);
var j: integer;
_( if g1166 = 0 then _(
      writeln('@':zt);
      (q) for j := 0 to 5 do write(g0051[k][j]);
      writeln;
      goto 1
   _);
   if 1 in g0050 then _(
      writeln('@':zt + 7);
      writeln(zr:3 oct, zt:3, zs:3 oct, zu:3,
              ' П:', zp:1 oct, ' M:', zq:1 oct)
   _);
   zg := g1040;
   x23762(300); x23761(k); x23761(zt);
   g1167 := g1167 + 1;
   g1164 := k <> 58;
   goto 4
_);
%
procedure p05306(c: char; k: integer);
_( if zr = c then x23734 else p05214(k) _);
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
      if zj.lb then s[i] := zr else p05214(6);
      x23734
   _);
   while zj.lb do (q) x23734;
   p05331 := alfa(s)
_);
%
function p05365: alfa;
var v: integer;
_( v := x24033; p05365 := ;
   if v = 7777777777777777C then p05214(6)
_);
%
procedure p05375(var r: long);
var col, n, d, b, cnt: integer; a: digits;
_( col := zt; n := 0; b := 0; cnt := 0;
   (q) repeat
      if zj.l28 then
      else if zj.l27 then b := b + 1
      else if zj.l26 then cnt := cnt + 1
      else exit q;
      d := zj.lv;
      if n > 23 then p05214(31);
      a[n] := chr(d); n := n + 1; x23734; (r)
   until false;
   if n = 0 then p05214(31)
   else if (zr = 'H') or (zr = 'X') then _( x23734; b := 16 _)
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
   with p@ do _(
      sm := g1170; (*=c-*) sk := g1175.s; (*=c+*) sl := g1171;
      s16 := g1172
   _)
_);
%
procedure p05542;
var p: @sect;
_( x23460(g0611, g0613); p := ;
   with p@ do _(
      g1170 := sm; (*=c-*) g1175.s := sk; (*=c+*) g1176 := ;
      g1171 := sl; g1172 := s16;
      g0607 := sf
   _)
_);
%
procedure p05566;
var i: integer; s: alfa; j: integer; nm: name12;
_( repeat
      i := 1;
      (q) repeat
         get(input); zo[i] := input@; i := i + 1;
         if input@ = '_012' then exit q
      until false;
      write(zo:144); writeln(output);
      zp := false; zq := ; x23675(1);
      zp := true; x23675(zt);
      if not x23745 then _(
         i := x24336(p05331(3));
         zp := false; x23675(zt);
         case i of
         1: g1044 := g1044 - [35];
         2: if zj.l28 then _(
               g1126 := 0; g1127 := ;
               (q) for i := 0 to 5 do (r) _(
                  if not zj.l28 then p05214(31);
                  g1126 := g1126 * 8 + zj.lv; x23734
               _);
               p05306(',', 8);
               while zj.l28 do (q) _(
                  g1127 := g1127 * 8 + zj.lv; x23734
               _)
            _) else _(
               i := 0;
               while (i < 20) and not x23745 do _(
                  nm[i] := zr; x23734; i := i + 1
               _);
               nm[i] := '_012';
               i := MKNAME(nm, 'MOДYЛИ', 'MOД   ', d115);
               if i = 0 then i := OPENF(d115, true, g1126);
               if i <> 0 then p05214(3);
               g1127 := g1126 div 262144;
               g1126 := g1126 mod 262144
            _);
         3: _( h0050 := 9; h0051 := 1000000000B; h0054 := 3200000B;
               h0052 := 777770000B; h0053 := 777740000B _);
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
         21: if zj.l28 then _(
               g1026.ext := '*****_000'; g1026.lib := '******';
               g1031 := 0;
               (q) for i := 0 to 5 do (r) _(
                  if not zj.l28 then p05214(31);
                  g1031 := g1031 * 8 + zj.lv
               _);
               mapia(g1031, g1026.name)
            _) else _(
               i := 0;
               while (i < 20) and not x23745 do _(
                  nm[i] := zr; x23734; i := i + 1
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
(*=c-*)
   g0722@[1].nm := 0544273443440000C; g0722@[1].v := 0;
(*=c+*)
   d47 := -1; d4 := 0; d35 := 0;
   x26626(g1031, g1034);
   d115 := g1026;
   d123 := 0; d124 := 0; g1033 := 0; d120 := 0; g1042 := 0;
   g1035 := ptr(b + 849); zi := ;
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
   g1104[0] := '      '; g1104[1] := ; g1104[2] := ; g1104[3] := ;
   g1104[4] := ; g1104[5] := ; g1104[6] := ; g1104[7] := ;
   g1104[8] := ;
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
procedure p17204;
var k, w: integer; e: pt;
%
function p07120(k: integer): integer;
var v, j: integer;
_( if zr = '''' then _(
      x23734;
      if zj.l28 then _(
         v := 0;
         while zj.l28 do (q) _(
            v := v * 8 + zj.lv; x23734; (r)
         _);
         if v > 255 then p05214(33);
         p05306('''', 33);
         p07120 := v; exit
      _);
      if zr <> '''' then _( p07120 := -1; exit _)
   _);
   if zr = '_012' then p05214(10);
   if k = 14 then zr := zj.lc1
   else if k = 15 then zr := zj.lc2;
   p07120 := ord(zr); x23734
_);
%
procedure p07205;
_( if g0607 = 0 then _(
      x23470(g0606, 1, g1135); g0607 := 1; g0605 := 1
   _)
_);
%
procedure p07220;
var j: integer;
_( p07205;
   if g0613 = 0 then _(
      x23470(g0612, 16, g1135);
      g0617.sf := g0607;
      x23470(g0611, 16, g0617);
      g0610 := 16; g0613 := ;
      p05542
   _)
_);
%
function p07246(k: alfa): integer;
var i: integer; p: pt;
_( (q) for i := g0605 downto 1 do (r) _(
      x23460(g0606, i); p := ;
      if p@.nm = k then _( p07246 := i; exit _)
   _);
   g0605 := g0605 + 1; p07246 := ;
(*=c-*) x23470(g0606, g0605, k) (*=c+*)
_);
%
function p07273(k: alfa; l: integer): integer;
var i: integer; p: pt;
_( (q) for i := g0610 downto 16 do (r) _(
      x23460(g0612, i); p := ;
      if p@.nm = k then _(
         x23460(g0611, i); p := ;
         if p@.sf = l then _( p07273 := i; exit _)
         else if p@.sf = 0 then _( p07273 := -i; exit _)
      _)
   _);
   p07273 := 0
_);
%
function p07331(n: alfa): integer;
var i: integer; p, q: pt;
_( i := zm[x24276(n)].ha;
   if i <> 0 then _(
      repeat
         x23460(g0720, i); p := ;
         if p@.nm = n then _( p07331 := i; exit _);
         x23460(g0717, i); q := ;
         if x22564(n, p@.nm) then i := q@.nd else i := q@.ne
      until i = 0; (r);
      g0716 := g0716 + 1; p07331 := ;
      if x22564(n, p@.nm) then q@.nd := g0716 else q@.ne := g0716
   _) else _(
      g0716 := g0716 + 1; p07331 := ;
      zm[x24276(n)].ha := g0716
   _);
(*=c-*) x23470(g0720, g0716, n); (*=c+*)
   x23470(g0717, g0716, g1135)
_);
%
function p07440(n: alfa): integer;
var i: integer;
_( i := zm[x24276(n)].hb;
   while i <> 0 do (q) _(
      if zn[i].nm = n then _( p07440 := i; exit _);
      if x22564(n, zn[i].nm) then i := zn[i].fl
      else i := zn[i].fr
   _);
   (q) for i := 1 to g1025 do (r) _(
      if g1024@[i].nm = n then _( p07440 := 511 + i; exit _)
   _);
   p07440 := 0
_);
%
function p07524: integer;
var v: integer;
_( d122 := 1;
   while x26745(zo, v) do _(
      if d120 <> 0 then _(
         x27026(d104[0][d120]);
         d123 := d104[1][d120]; d124 := d104[2][d120];
         d120 := d120 - 1; d122 := d122 + 1
      _) else _( p07524 := 0; exit _)
   _);
   if d122 = 1 then d122 := 0;
   g1033 := g1033 + 1;
   if v = -1 then _(
      if d124 = 0 then d123 := d123 + 1 else d124 := d124 + 1
   _) else _(
      if d122 = 0 then d122 := 1;
      if v = 0 then d124 := 1 else _( d124 := 0; d123 := v _)
   _);
   p07524 := ;
_);
%
function p07577: integer;
var n: integer; s: alfa;
_( n := p07524;
   if n = 0 then p05214(58);
   if 1 in g0050 then _(
      write(n:5, '. ');
      write(zo:144); writeln(output)
   _);
   if g1032 < n then g1032 := n;
   zp := true; zq := false; x23675(1);
   d52 := false;
   if zr = '*' then _( p07577 := -1; exit _);
   if zr = '!' then _( p07577 := -2; exit _);
   if (zj.ld = ' ') or (zr = ':') then _(
      d52 := zr = ':';
      repeat x23734; (r) until zj.ld <> ' '
   _) else if not x23745 then _(
      d52 := true;
      repeat x23734; (r)
      until (zj.ld = ' ') or (zr = ':') or x23745;
      while (zj.ld = ' ') or (zr = ':') do _( x23734; (r) _)
   _);
   d53 := zt;
   if x23745 then _( d54 := d53; p07577 := 14; exit _);
   s := x24067;
   if (s = '_000_000_000_000_000_000') or
      not ((zj.ld = ' ') or x23745) then _( p07577 := 0; exit _);
   d54 := zt;
   p07577 := p07440(s)
_);
%
procedure p07736;
_( if d52 then p05214(6) _);
%
function p07744: integer;
var a, i, j: integer; n: alfa; q, r: pt; ad: @r2;
_( if zr <> ':' then _(
      if not zj.ly then p05214(14);
      n := p05365;
      if zr = '.' then _(
         (q) _(
            for i := g0635 downto 1 do _(
               x23460(g0715, g0636[i].f1); r := ;
               j := r@.bd;
               x23460(g0720, j); q := ;
               if q@.nm = n then _( a := i; exit q _)
            _);
            p05214(24)
         _);
         (q) repeat
            x23734;
            if j < 256 then x23764(1, j) else x23765(2, j);
            if not zj.ly then p05214(14);
            n := p05365;
            if zr <> '.' then exit q;
            if a = g0635 then p05214(25);
            a := a + 1;
            x23460(g0715, g0636[a].f1); r := ;
            j := r@.bd;
            x23460(g0720, j); q := ;
            if q@.nm <> n then p05214(25)
         until false
      _) else a := g0635;
      if (w = 277) and (a <> g0635) then p05214(26);
      while zj.ld = ' ' do _( x23734; (r) _);
      j := p07331(n);
      g0622 := g0622 + 1;
      if g0622 = 4095 then p05214(5);
      x23461(g0623, g0622); q := ; e := ;
      q@.w := g1135.w; q@.w1 := ;
      if 37 in g1044 then q@.w2 := g1135.w;
      with q@ do _(
         ad := ref(g0636[a]);
         x23460(g0715, ad@.f1); r := ;
         q@.vb := ad@.f1;
         q@.vf := x23752(':');
         if q@.vf and r@.bc then _(
            g0625 := g0625 + 1; q@.vh := true
         _);
         q@.ve := g0613;
         q@.vo := j
      _);
      p07744 := g0622;
      if j < 256 then x23764(3, j) else x23765(4, j)
   _) else _(
      p07744 := 0; x23760(0); x23734
   _);
   zp := false; x23675(zt);
   if zt <> d53 then p05214(6);
   x23675(d54)
_);
%
function p10230: boolean;
var v: integer;
_( p10230 := d52; p07220;
   if d52 then v := p07744
_);
%
procedure p10240(b: boolean);
var k, j: integer;
_( repeat
      if not zj.ly then p05214(6);
      j := p07331(p05365);
      if zr = '.' then _(
         x23734; k := 1;
         if b then p05214(26)
      _) else k := 3;
      if j < 256 then x23764(k, j) else x23765(k + 1, j)
   until k = 3; (r)
_);
%
function p10277: integer;
var i: integer; n: alfa;
_( p05306('_043', 14);
   if not zj.lb then p10277 := 0
   else _(
      n := p05365;
      (q) _(
         for i := 1 to g0721 do
            if g0722@[i].nm = n then _( p10277 := i; exit q _);
         p05214(18)
      _);
      while zj.ld = ' ' do _( x23734; (r) _)
   _)
_);
%
function p10337: integer;
var k: integer; n: alfa;
_( if not zj.ly then p05214(14);
   n := p05365;
   if zr = '.' then _( x23734; k := p07246(n) _)
   else _( p07205; k := g0607 _);
   k := p07273(n, k); p10337 := ;
   if k = 0 then p05214(19)
_);
%
procedure p11736;
var st: array [0..10] of integer; q, v, p, n: integer;
%
procedure p11151;
label 1;
var i, k, j, n, u: integer; r: long; b: boolean;
    a: array [0..6] of integer;
%
procedure p10373(k: integer);
var i, v: integer; a: array [0..48] of char; r: long;
_( x23734;
   if not (k in [2, 4, 8, 10, 16]) then p05214(32);
   i := 0;
   repeat
      if not zj.l26 or (i > 48) then p05214(31);
      v := zj.lv;
      if v >= k then p05214(31);
      a[i] := chr(v); i := i + 1; x23734; (r)
   until not zj.l26; (r);
(*=c-*) x24236(a, i, k, r); (*=c+*)
   x24025(r)
_);
%
procedure p10442;
var r: real; t: long; b: boolean; e, d, m: integer;
_( x23734; x23734; b := p05317;
   r := 0.0;
   while zj.l27 do (q) _( r := r * 10.0 + zj.lv; x23734 _);
   if x23752('.') then _(
      e := 10;
      while zj.l27 do (q) _(
         r := r + zj.lv / e; e := e * 10; x23734
      _)
   _);
   if b then r := -r;
   if x23752('E') then _(
      b := p05317; e := p05475; m := 1;
      for e := e downto 1 do _( m := m * 10; (x) _);
      (y) if b then r := r / m else r := r * m;
      (z)
   _);
   t := g1135.el; t.hi := integer(r);
   p05306('''', 10);
   x24025(t)
_);
%
_( n := 0;
1: if zj.ly then _(
      if (zs = '@') and (zj.lx in [1..7]) then _(
         j := zj.lx; x23734; x23734; p10240(false);
         d50 := false; x23766(14, 1, j)
      _) else if zs = '''' then _(
         if zj.lx in [13, 14, 15] then _(
            j := zj.lx; x23734;
            zp := true; zq := ; x23675(zt + 1);
            i := 0; r := g1135.el;
            (q) repeat
               k := p07120(j);
               if k = -1 then exit q;
               x24700(r, -8, r); x24673(r, k, r); i := i + 1
            until false;
            if (i = 0) or (i > 6) then p05214(34);
            zp := false; zq := ; x23675(zt);
            x24025(r)
         _) else if zr = 'K' then _(
            x23734; x23734;
            case zr of '0': i := 0; '1': i := 32; others: p05214(6) end;
            x23734;
            if not zj.l28 then p05214(6);
            i := i + zj.lv * 4; x23734;
            if not zj.l29 then p05214(6);
            i := i + zj.lv; x23734;
            (q) for k := 1 to 6 do _(
               if not zj.l28 then p05214(6);
               i := i * 8 + zj.lv; x23734; (x)
            _);
            x24031(i);
            p05306('''', 10)
         _) else if zr = 'Ч' then p10442
         else if zr = 'Ц' then _(
            x23734; x23734; b := p05317; p05375(r);
            p05306('''', 10);
            if b and (r <> g1135.el) then x24640(r, r);
            r.hs := r.hs - [0..6] + [0, 1, 3];
            x24025(r)
         _) else p05214(6)
      _) else _( p10240(false); d50 := false _)
   _) else if zj.l27 then _(
      p05375(r);
      if zr = '@' then p10373(x24543(r)) else x24025(r)
   _) else if zr = '_043' then _(
      i := p10277;
      if i = 0 then _( x23760(11); d50 := false _)
      else x24031(g0722@[i].v)
   _) else if zr = '.' then _(
      x23734;
      if zj.l27 then _(
         p05375(r); x24025(r); x23763(5, 1); x23763(14, 6)
      _) else if zr = '@' then _(
         x23734; p10240(false); x23763(14, 15); x23766(5, 0, 14);
         x23766(2, 14, 5); d50 := false
      _) else if zj.ly then _(
         p10240(false); d50 := false; x23763(5, 1); x23763(14, 6)
      _) else if (zr = '(') or (zr = '[') then _(
         b := zr = '(';
         j := 0;
         repeat
            x23734;
            if zr = '@' then _(
               x23734; p10240(false); x23763(14, 15);
               x23766(5, 0, 14); x23766(2, 14, 5); d50 := false
            _) else _(
               if b then x23764(6, 48);
               p11736;
               if b then x23763(14, 12);
               if x23752(':') then _(
                  if b then x23764(6, 48);
                  p11736;
                  if b then x23763(14, 12);
                  x23766(5, 0, 14); x23766(2, 14, 14)
               _) else _( x23763(5, 1); x23763(14, 6) _)
            _);
            j := j + 1; (r)
         until zr <> ',';
         if b then p05306(')', 7) else p05306(']', 7);
         (q) for j := j downto 2 do _( x23763(14, 8); (r) _)
      _) else p05214(7)
   _) else if (zr = '/') and (zs = '(') then _(
      x23734; x23734; p11736; p05306(')', 7); p05306('/', 7)
   _) else if zr = '=' then p05214(41)
   else if zr = '+' then _( x23734; goto 1 _)
   else _(
      if zr = '-' then j := 3
      else if zr = '/' then j := -1
      else if zr = '%' then j := -2
      else if zr = '^' then j := 2
      else if zr = '[' then _(
         x23734;
         if zr = '@' then _(
            x23734; p10240(false); x23763(14, 15); j := 5
         _) else _(
            p11736;
            if zr = ':' then _( x23734; p11736; j := 14 _)
            else j := 6
         _);
         if zr <> ']' then p05214(7)
      _) else p05214(6);
      x23734;
      if n > 6 then p05214(42);
      a[n] := j; n := n + 1; goto 1
   _);
   if n <> 0 then
      (q) for i := n - 1 downto 0 do _(
         j := a[i];
         if j > 0 then x23763(14, j) else x23766(14, 4, -j)
      _)
_);
%
_( n := 0;
   repeat
      p11151;
      case zr of
      '!': _( p := 112; q := ; _);
      '^': _( p := 128; q := 112 _);
      '&': _( p := 144; q := ; _);
      '=': _( p := 161; q := 160 _);
      '[': _(
         x23734; q := x24324(p05331(2));
         if q = 7 then q := 3 else if q = 8 then q := 5;
         if (q = 0) or (zr <> ']') then p05214(35);
         p := 160 + q; q := 160
      _);
      '+': _( p := 176; q := ; _);
      '-': _( p := 192; q := 176 _);
      '*': _( p := 209; q := 208 _);
      '/': _( p := 210; q := 208 _);
      '%': _( p := 211; q := 208 _);
      others: _( p := 0; q := ; _)
      end;
      while (n <> 0) and (st[n - 1] >= q) do _(
         n := n - 1; v := st[n];
         x23763(14, v div 16); v := v mod 16;
         if v <> 0 then x23760(v)
      _);
      if p <> 0 then _(
         if n > 10 then p05214(42);
         x23734; st[n] := p; n := n + 1
      _)
   until p = 0; (r)
_);
%
procedure p12075;
_( d50 := true; p11736; x23760(15) _);
%
procedure p12104(var r: long; var pos: integer);
var st: array [0..20] of long; n, i, k: integer; v: long;
_( k := pos; n := 0; zb := [];
   if 7 in g0050 then _(
      (q) for i := k to zg - 1 do write(g1035@[i]:1 hex, ' ');
      writeln
   _);
   repeat
      i := g1035@[k];
      if i in [5..10] then _(
         v := g1135.el;
         (q) for i := zh[i] downto 1 do _(
            k := k + 1; x24700(v, -4, v); x24673(v, g1035@[k], v); (r)
         _);
         if n > 20 then p05214(42);
         st[n] := v; n := n + 1; i := 0
      _) else if i = 14 then _(
         k := k + 1;
         case g1035@[k] of
         2: x27121(st[n-1], st[n-1]);
         3: x24640(st[n-1], st[n-1]);
         4: _( k := k + 1;
               case g1035@[k] of
               1: x24700(st[n-1], 12, st[n-1]);
               2: x27115(st[n-1], g1140, st[n-1])
               end _);
         6: _( n := n - 1; x27117(st[n], st[n-1], st[n-1]) _);
         7: _( n := n - 1; x27116(st[n-1], st[n], st[n-1]) _);
         8: _( n := n - 1; x24657(st[n-1], st[n], st[n-1]) _);
         9: _( n := n - 1; x27115(st[n-1], st[n], st[n-1]) _);
         10: _( k := k + 1; n := n - 1;
                x27120(st[n-1], st[n], g1035@[k], st[n-1]) _);
         11: _( n := n - 1; x24555(st[n-1], st[n], st[n-1]) _);
         12: _( n := n - 1; x24573(st[n-1], st[n], st[n-1]) _);
         13: _( k := k + 1; n := n - 1;
                case g1035@[k] of
                1: x24601(st[n-1], st[n], st[n-1]);
                2: x24612(st[n-1], st[n], st[n-1]);
                3: x24624(st[n-1], st[n], st[n-1])
                end _);
         14: _( n := n - 2; x25004(st[n+1], st[n-1], st[n], st[n-1]) _);
         others: p05214(1)
         end
      _) else if i = 15 then else p05214(1);
      k := k + 1;
      if 7 in g0050 then
         with st[n-1] do
            writeln(n - 1:3, ': ', hi:16 oct, zb:17 oct)
   until i = 15; (r);
   if n <> 1 then p05214(1);
   if zb <> [] then p05214(p04031(zb));
   r := st[0]; zg := pos
_);
%
procedure p12667;
var k, d, c: integer; b: boolean;
_( d := 0; c := 0;
   repeat
      k := p07577;
      if k > 0 then k := zn[k].f0;
      c := c + 1; b := false;
      case k of
      281: d := d + 1;
      285: d := d - 1;
      284: b := true;
      282: b := d47 in d46;
      283: b := not (d47 in d46)
      end;
      if b and (d = 0) then d := -1
   until d = -1; (r);
   if k = 285 then d47 := d47 - 1;
   x24031(c)
_);
%
procedure p12754;
var i, v: integer;
_( p07736;
   if zr = '''' then _(
      zp := true; zq := ; x23675(zt + 1)
   _) else p05214(10);
   g1130 := '    '; g1131 := ; g1132 := ;
   i := 0;
   repeat
      v := p07120(13);
      if v <> -1 then _(
         if i < 4 then g1130[i] := chr(v)
         else if i < 8 then g1131[i - 4] := chr(v)
         else if i < 12 then g1132[i - 8] := chr(v);
         i := i + 1
      _)
   until v = -1; (r);
   zp := false; zq := ; x23675(zt)
_);
%
procedure p13032;
_( p07736;
   if not x23745 then p05214(6);
   if d47 <> -1 then p05214(54);
   if d4 <> 0 then p05214(55);
   if d35 <> 0 then p05214(56);
   g1164 := false;
   goto 4
_);
%
procedure p13057;
var k: integer; p: pt; n: alfa;
_( p05506;
   if not d52 then _( k := p10337; g0613 := ; x23762(k) _)
   else _(
      if not zj.ly then p05214(14);
      n := p05365;
      if x23752('.') then _(
         k := p07246(n);
         if not zj.ly then p05214(14);
         n := p05365
      _) else _( p07205; k := g0607 _);
      zp := false; x23675(zt);
      if zt <> d53 then p05214(6);
      x23675(d54);
      k := p07273(n, k);
      if k <> 0 then p05214(20);
      g0610 := g0610 + 1; k := ;
(*=c-*) x23470(g0612, g0610, n); (*=c+*)
      x23762(k);
      g1035@[g1040] := 9;
      if x23745 then x23766(5, 0, 15) else p12075;
      g0613 := k;
      x23461(g0611, k); p := ;
      with p@ do _( p@ := g0617; sf := g0607 _);
      while x23752(',') do _(
         k := x24421(p05331(3));
         case k of
         1: p@.sa := 1;
         2: p@.sa := 2;
         3: if h0050 = 5 then p05214(51) else p@.sa := 3;
         4: p@.sb := 0;
         5: p@.sb := 8;
         6: p@.sb := 10;
         7: _( p05306('=', 9); k := p05475;
               if k > 26 then p05214(32);
               p@.sb := k _);
         8: p@.ub := 0;
         9: p@.ub := 1;
         10: p@.ud := 0;
         11: p@.ud := 1;
         12, 13, 14, 15, 16: _(
               p@.ua := k - 12 - ord(k > 14); p@.sd := k = 15 _);
         17: p@.sh := 1;
         18: p@.sh := 2;
         19: p@.si := false;
         20: p@.si := true;
         21: p@.sn := false;
         22: p@.sn := true;
         23: p@.s1x := false;
         24: p@.s1x := true;
         25: p@.se := false;
         26: p@.se := true;
         27: p@.s1z := true;
         28: p@.s1z := false;
         others: p05214(12)
         end
      _);
      p@.tk := p@.tc; p@.sl := p@.sd; p@.sm := p@.se;
      p@.s16 := p@.s1z
   _);
   p05542
_);
%
procedure p13544;
var k: integer;
_( p07736; k := p10337; x23762(k);
   if not x23745 then _(
      p05306(':', 11);
      g1035@[g1040] := 9; p12075;
      if x23752(':') then _( g1035@[g1040] := 13; p12075 _)
   _)
_);
%
procedure p13574;
var k: integer;
_( p07736; p07220;
   repeat
      k := x24400(p05331(3)); x23760(k);
      case k of
      0: p05214(12);
      1: g1170 := false;
      2: g1170 := true;
      3: g1175.f2 := 0;
      4: g1175.f2 := 1;
      5: g1175.f4 := 0;
      6: g1175.f4 := 1;
      7, 8, 9, 10, 11: _(
            g1175.f01 := k - 7 - ord(k > 9); g1171 := k = 10 _);
      12: _(
            if d35 = 8 then p05214(56);
            d35 := d35 + 1;
            with d36[d35] do _(
               ea := g0613; es := g1175.s; e1 := g1171; e0 := g1170;
               e2 := g1172
            _)
         _);
      13: _(
            if d35 = 0 then p05214(56);
            p05506;
            with d36[d35] do _(
               g0613 := ea; x23762(g0613); p05542;
               g1175.s := d36[d35].es; x23761(g1175.fi);
               g1171 := d36[d35].e1; x23760(ord(g1171));
               g1170 := d36[d35].e0; x23760(ord(g1170));
               g1172 := d36[d35].e2; d35 := d35 - 1
            _)
         _);
      14: g1172 := true;
      15: g1172 := false
      end
   until not x23752(',');
   x23760(0)
_);
%
procedure p14015;
_( p07220; p07736 _);
%
procedure p14021;
var a: integer; b, c: boolean; x6, x7, x8: integer;
_( if p10230 then g1035@[g1040] := g1035@[g1040] + 4;
   if g1035@[g1040] >= 8 then
      with g1024@[k] do _( a := qa; b := qb; c := qc _)
   else
      with zn[k] do _( a := qa2; b := qb2; c := g0724[w].wc _);
   if b and not x23745 then p05214(17);
   if (zr = '(') or x23745 then _(
      x24031(a * 64); x23760(15)
   _) else if a <> 0 then _(
      x24031(64); p11736; x23766(14, 11, 15)
   _) else if zr = '=' then _(
      x23760(15); x23734; p12075;
      if not c and (zr = '(') then p05214(41)
   _) else p12075;
   if zr = '(' then _( x23734; p12075; p05306(')', 7) _)
   else g1035@[g1040] := g1035@[g1040] + 2
_);
%
procedure p14157;
var v, s: integer;
_( if w = 401 then zg := zg + 3;
   if p10230 then v := 1024 else v := 0;
   s := zg; zg := g1040;
   if w = 401 then _( x23762(2248 + v); x23762(2570) _)
   else p05214(2);
   zg := s;
   if (zr = '(') or x23745 then x23766(5, 0, 15) else p12075;
   if x23752('(') then _( p12075; p05306(')', 7) _)
   else g1035@[g1040] := g1035@[g1040] + 2
_);
%
procedure p14302;
_( p05214(13) _);
%
procedure p14337;
_( if p10230 then g1035@[g1040] := 9;
   if x23752('(') then _(
      g1035@[g1040] := g1035@[g1040] + 4; p12075; p05306(')', 7)
   _);
   if x23752('=') then x23760(15);
   p12075
_);
%
procedure p14371;
_( if p10230 then g1035@[g1040] := 9;
   if x23752('=') then x23760(15);
   p12075
_);
%
procedure p14406;
var b: boolean;
_( if p10230 then g1035@[g1040] := 9;
   b := w = 266;
   x23764(6, 20);
   if b then x23763(5, 13) else x23764(6, 16);
   p11736; x23763(14, 14); p05306(',', 8);
   if zr <> '(' then _(
      if b then x23763(5, 12) else x23764(5, 15);
      x23763(5, 1); p11736; x23763(14, 14); x23763(14, 8)
   _);
   if x23752('(') then _(
      x23764(6, 24); x23764(6, 21); p11736; x23763(14, 14);
      x23763(14, 8); p05306(')', 7)
   _);
   x23760(15)
_);
%
procedure p14502;
var c, n, v, j: integer;
_( if p10230 then g1035@[g1040] := 9;
   if zr = '''' then j := 13
   else _(
      j := zj.lx; x23734;
      if not (j in [13, 14, 15]) then p05214(32)
   _);
   c := zt;
   p05306('''', 10);
   zp := true; zq := ; x23675(c + 1);
   c := zg;
   x23761(0);
   n := 0;
   (q) repeat
      v := p07120(j);
      if v = -1 then exit q;
      x23761(v); n := n + 1
   until false;
   if n = 0 then p05214(6);
   g0722@[1].v := n;
   zp := false; zq := ; x23675(zt);
   v := zg; zg := c; x23761(n); zg := v;
   if x23752(',') then p12075
   else _(
      x23760(6);
      case j of
      13: x23761(0);
      14: x23761(0);
      15: x23761(99)
      end;
      x23760(15)
   _)
_);
%
procedure p14626;
_( if p10230 then g1035@[g1040] := 9;
   if x23745 then x23766(5, 1, 15) else p12075
_);
%
procedure p14645;
_( if p10230 then g1035@[g1040] := 9;
   g0634 := g0634 + 1;
   g0632@[g0634].fa := g0613
_);
%
procedure p14665;
var b: boolean;
_( if d52 then _( b := p10230; g1035@[g1040] := 9 _) _);
%
procedure p14676;
var k: integer; r: long;
_( if not d52 then p05214(15);
   if x23745 then p05214(16);
   k := p07744; k := zg;
   p12075;
   with e@ do
      if zr <> '(' then _(
         if d50 then _(
            p12104(r, k); k := x24545(r); e@.va := true;
            if k >= 0 then e@.vd := k
            else _(
               e@.vj := true; g0626 := g0626 + 1; e@.vd := ;
               x23472(g0627, g0626, r)
            _);
            e@.ve := 0;
            g1035@[g1040] := g1035@[g1040] + 8
         _) else e@.ve := 1023
      _) else _(
         x23734; p12075; p05306(')', 7);
         g1035@[g1040] := g1035@[g1040] + 4
      _)
_);
%
procedure p15022;
_( if not p10230 then p05214(15);
   if x23745 then p05214(16);
   e@.vk := true;
   if x23752('@') then _( p10240(false); g1035@[g1040] := 9 _)
   else _( p12075; p05306(':', 11); p12075 _)
_);
%
procedure p15061;
var k, n, v: integer;
_( if not d52 then p05214(15);
   k := p07744;
   with e@ do _( vi := true; ve := 1023 _);
   if zr = '''' then _(
      zp := true; zq := ; x23675(zt + 1)
   _) else p05214(10);
   k := zg; x23761(0); n := 0;
   repeat
      v := p07120(13);
      if v <> -1 then _( x23761(v); n := n + 1 _)
   until v = -1; (r);
   if n = 0 then p05214(34);
   zp := false; zq := ; x23675(zt);
   v := zg; zg := k; x23761(n); zg := v
_);
%
procedure p15152;
var q: pt; j: integer;
_( if d52 then _( p10240(false); zp := false; x23675(d54) _);
   x23760(15);
   repeat
      j := p07331(p05365);
      g0622 := g0622 + 1;
      if g0622 = 4095 then p05214(5);
      x23461(g0623, g0622); q := ;
      q@.w := g1135.w; q@.w1 := ;
      if 37 in g1044 then q@.w2 := g1135.w;
      with q@ do _(
         vb := g0636[g0635].f1; ve := 1023; vo := j; vi := true
      _);
      if j < 256 then x23764(3, j) else x23765(4, j)
   until not x23752(',');
   x23760(15)
_);
%
procedure p15251;
var q: pt; b1, b2: boolean;
_( if not p10230 then p05214(15);
   g0714 := g0714 + 1;
   x23461(g0715, g0714); q := ;
   with q@ do _(
      e@.vc := g0714;
      bb := g0636[g0635].f1;
      bd := e@.vo;
      bc := e@.vf and d51@.bc;
      bs := [];
      bf := 0; be := 0
   _);
   if g0635 = 23 then p05214(5);
   g0635 := g0635 + 1; d51 := q;
   with g0636[g0635] do _( f1 := g0714; f3 := g0622; f2 := 1 _);
   if x23745 then x23760(10)
   else _(
      b1 := false; b2 := ;
      repeat
(*=c-*)  q := p05331(3);
         if q = 'OГP   ' then _(
            if b1 then p05214(12);
            b1 := true; x23760(5); p05306('=', 9); p10240(false);
            if x23752('+') then
               if x23752('(') then _(
                  repeat p10240(true); (r) until not x23752(',');
                  p05306(')', 7)
               _) else p10240(true)
         _) else if q = 'BKЛ   ' then _(
(*=c+*)     if b2 then p05214(12);
            b2 := true; x23760(6); p05306('=', 9);
            if x23752('(') then _(
               repeat p10240(false); (r) until not x23752(',');
               p05306(')', 7)
            _) else p10240(false)
         _) else p05214(12)
      until not x23752(',');
      x23760(10)
   _)
_);
%
procedure p15472;
var v: integer; q: pt;
_( if g0635 < 2 then p05214(25);
   p07736;
   if not x23745 then _(
      v := zg; p10240(true); zg := v;
      v := g1035@[zg + 1] * 16 + g1035@[zg + 2];
      if g1035@[zg] = 4 then v := v * 16 + g1035@[zg + 3];
      x23460(g0715, g0636[g0635].f1); q := ;
      if q@.bd <> v then p05214(25)
   _);
   g0635 := g0635 - 1;
   x23460(g0715, g0636[g0635].f1); d51 := ;
_);
%
procedure p15565;
var i: integer; n: alfa;
_( p07736;
   repeat
      p05306('_043', 14);
      n := p05365;
      (q) for i := 1 to g0721 do
         if g0722@[i].nm = n then p05214(20);
      if n = '_000_000_000_000_000_000' then p05214(20);
      g0721 := g0721 + 1;
      with g0722@[g0721] do _( nm := n; v := 0 _)
   until not x23752(',')
_);
%
procedure p15631;
var i, c, x5: integer; r: long;
_( if not d52 then p05214(15);
   i := p10277;
   if zt <> d53 then p05214(6);
   zp := false; x23675(d54);
   if i = 0 then p05214(6);
   c := zg; p12075;
   if not d50 then p05214(36);
   p12104(r, c);
   g0722@[i].v := x24545(r)
_);
%
procedure p15700;
var c, x4, x5, x6: integer; r: long;
_( p07736;
   c := zg; p12075;
   if not d50 then p05214(36);
   if not x23745 then p05214(6);
   p12104(r, c);
   d47 := d47 + 1;
   if d47 = 48 then p05214(5);
   if r <> g1135.el then _(
      d46 := [d47] + d46; g1035@[g1040] := 9
   _) else _(
      d46 := d46 - [d47]; p12667; x24031(d123); x24031(d124); goto 3
   _)
_);
%
procedure p15753;
_( p07736;
   if not x23745 then p05214(6);
   if d47 = -1 then p05214(54);
   if (w = 282) and not (d47 in d46) or (w = 283) and (d47 in d46)
   then _( p12667; x24031(d123); x24031(d124); goto 3 _);
   g1035@[g1040] := 9; (r)
_);
%
procedure p16012;
_( p07736; if d47 = -1 then p05214(54); d47 := d47 - 1 _);
%
procedure p16022;
var k: integer; n: alfa;
_( if not d52 then p05214(15);
   n := x24067;
   if n = '_000_000_000_000_000_000' then p05214(13);
   while zj.ld = ' ' do _( x23734; (r) _);
   if zt <> d53 then p05214(6);
   zp := false; x23675(d54);
   if g1025 = 31 then p05214(5);
   if p07440(n) <> 0 then p05214(20);
   g1025 := g1025 + 1;
   with g1024@[g1025] do _(
      nm := n;
      k := p05475;
      if k > 255 then p05214(53);
      fc := k; fk := 0; qa := 0; qb := false;
      while x23752(',') do _(
         k := x24305(p05331(3));
         case k of
         0: p05214(12);
         1: r27 := true;
         2: qb2 := true;
         3: qd := true;
         4: qc := true;
         5: _( p05306('=', 9); k := x24317(p05331(3));
               if k = 0 then p05214(12);
               qe := k _);
         6: _( p05306('=', 9); k := x24317(p05331(3));
               if k = 0 then p05214(12);
               qf := k _);
         7: qa := 1;
         8: qb := true
         end
      _)
   _)
_);
%
procedure p16336;
var i, j, n, c: integer;
%
function p16265: integer;
var n, c, v: integer;
_( zp := true; zq := ; x23675(zt + 1);
   c := zg; p16265 := ;
   x23761(0); n := 0;
   repeat
      v := p07120(13);
      if v <> -1 then _( x23761(v); n := n + 1 _)
   until (v = -1) or (n = 54);
   while v <> -1 do (q) _( v := p07120(13) _);
   v := zg; zg := c; x23761(n); zg := v;
   zp := false; zq := ; x23675(zt)
_);
%
_( p07736;
   if zr = '''' then _(
      c := p16265;
      if zr = ',' then _(
         g1035@[g1040] := 9;
         n := g1035@[c] * 16 + g1035@[c + 1];
         c := c + 2;
         (q) for i := 0 to 8 do (r) g1104[i] := '      ';
         j := (54 - n) div 2;
         i := j div 6; j := j mod 6;
         repeat
            g1104[i][j] := chr(g1035@[c] * 16 + g1035@[c + 1]);
            c := c + 2; j := j + 1;
            if j = 6 then _( j := 0; i := i + 1 _);
            n := n - 1; (r)
         until n = 0; (r);
         x23734;
         if zr = '''' then c := p16265 else x23763(0, 0)
      _)
   _) else x23763(0, 0)
_);
%
procedure p16451;
_( p07736;
   if x23745 then _( x23763(5, 1); x23763(5, 0) _)
   else _(
      x24031(p05475);
      if x23752(',') then x24031(p05475) else x23763(5, 0)
   _)
_);
%
procedure p16536;
%
procedure p16500(var v: integer; d: integer);
_( v := v + d;
   if x23752('+') then v := v + p05475
   else if x23752('-') then v := v - p05475
   else if zj.l27 then v := d + p05475;
   if v < 0 then p05214(40)
_);
%
_( p07736;
   g1052 := g1052 - g1051; g1051 := g1051 - g1050;
   p16500(g1050, 0); p05306(',', 8);
   p16500(g1051, g1050); p05306(',', 8);
   p16500(g1052, g1051);
   zg := g1040; x23762(291);
   x24030(g1044); x24031(g1050); x24031(g1051); x24031(g1052)
_);
%
procedure p16577;
var k: integer; b: boolean;
_( p07736;
   b := w = 291;
   if x23745 then _(
      if b then _(
         d3 := d3 + 1;
         if d3 >= 0 then _(
            g1044 := g1044 + [21, 33]; g1045 := g1045 + [33]
         _)
      _) else _(
         d3 := d3 - 1;
         if (d3 < 0) and not d103 then g1044 := g1044 - [21]
      _)
   _) else
      repeat
         (q) _(
            case x24366(p05331(3)) of
            1: _(
                  if d4 = 8 then p05214(55);
                  d4 := d4 + 1;
                  with d5[d4] do _(
                     s := g1044; ca := g1050; cb := g1051; cc := g1052;
                     i := d3
                  _);
                  exit q
               _);
            2: _(
                  if d4 = 0 then p05214(55);
                  with d5[d4] do _(
                     g1044 := g1044 * [33] + s;
                     g1050 := ca; g1051 := cb; g1052 := cc; d3 := i;
                     if d103 then g1044 := g1044 + [21]
                  _);
                  d4 := d4 - 1; exit q
               _);
            3: if 37 in g1044 then k := 22 else exit q;
            4: k := 10;
            5: k := 13;
            6: k := 12;
            7: k := 11;
            8: k := 14;
            others: p05214(12)
            end;
            if b then g1044 := [k] + g1044 else g1044 := g1044 - [k]
         _)
      until not x23752(',');
   x24030(g1044); x24031(g1050); x24031(g1051); x24031(g1052)
_);
%
procedure p16770;
var n: name12; i, f: integer;
_( if d120 = 3 then p05214(4);
   p07736;
   i := 0;
   while not x23745 and (i < 23) do (q) _(
      n[i] := zr; i := i + 1; x23734; (r)
   _);
   n[i] := '_012';
   i := MKNAME(n, d115.lib, 'TEKCT ', d115);
   if i = 0 then i := OPENF(d115, false, f);
   if i <> 0 then p05214(3);
   f := f mod 262144;
   d120 := d120 + 1; d121 := d121 + 1;
   d115.ext[6] := '_000';
   d104[0][d120] := x27022;
   d104[1][d120] := d123; d104[2][d120] := d124;
(*=c-*) x24030(d115.ext); x24030(d115.lib); x24030(d115.name);
(*=c+*) x24031(f);
   x26626(f, g1034);
   d123 := 0; d124 := 0
_);
%
procedure p17072;
_( p07220;
   if p10230 then g1035@[g1040] := g1035@[g1040] + 4;
   if zr <> '(' then p10240(false)
   else g1035@[g1040] := g1035@[g1040] + 2;
   if x23752('(') then _( p12075; p05306(')', 7) _)
   else x23766(5, 0, 15)
_);
%
procedure p17132;
var n: integer; b: boolean; s: bitset;
_( p07736;
   repeat
      s := [];
      n := p05475;
      b := not p05317;
      repeat s := [p05475] + s until not x23752(',');
      if n = 1 then
         if b then g0050 := g0050 + s else g0050 := g0050 - s
      else _( x23760(n + ord(b) * 4); x24030(s) _)
   until not x23752(';');
   x23760(0);
   if 0 in g0050 then _( p04347('ПPOXOД'); g0050 := g0050 - [0] _)
_);
%
_( k := p07577;
   zg := 0;
   if d122 <> 0 then _(
      x23763(0, 0); x23762(454);
      x24031(d122 - 1); x24031(d123); x24031(d124);
      g1035@[0] := zg div 16; g1035@[1] := zg mod 16
   _);
   if d120 = 0 then
      if not d103 and (d102 <> d101) and (d55[d102].hi <= d123) then _(
         d103 := true;
         if d3 < 0 then _(
            g1044 := g1044 + [21]; x23763(0, 5); x23762(451)
         _)
      _) else if d103 and (d55[d102].lo < d123) then _(
         d103 := false; d102 := d102 + 1;
         if d3 < 0 then _(
            g1044 := g1044 - [21]; x23763(0, 5); x23762(452)
         _)
      _);
   g1037 := zg; zg := zg + 2;
   if d52 then _( zp := true; x23675(1) _)
   else _( zp := false; x23675(d54) _);
   g1040 := zg;
   if k = 0 then p05214(13);
   if k = -1 then _( x23762(296); goto 3 _);
   if k = -2 then _( x23762(295); goto 3 _);
   if k < 511 then _( w := zn[k].f0; x23762(w) _)
   else _(
      k := k - 511; w := g1024@[k].fc;
      x23762(w + 2048); x23762(g1024@[k].fk)
   _);
   if w <= 255 then p14021
   else if w <= 383 then case w of
      257: p12754; 258: p13032; 259: p13057; 260: p13544;
      261: p13574; 262, 263: p14015; 301: p14302; 264: p14337;
      265: p14371; 266, 267: p14406; 268: p14502; 269: p14626;
      270: p14645; 271: p14665; 273: p05214(2); 274: p14676;
      275: p15022; 276: p15061; 297: p15152; 277: p15251;
      278: p15472; 279: p15565; 280: p15631; 281: p15700;
      282, 283, 284: p15753; 285: p16012; 286: p16022;
      287, 288: p16336; 289: p16451; 290: p16536;
      291, 292: p16577; 293, 294: p17072; 298: p17132;
      272: p16770; 295, 296, 299, 300: p05214(1);
      others: p05214(1)
   end else if w <= 447 then p14157
   else p05214(1);
   if not x23745 then p05214(17)
_);
%
procedure p17534;
var i: integer;
_( g1035@[g1037] := (zg - g1037) div 16;
   g1035@[g1037 + 1] := (zg - g1037) mod 16;
   if not g1164 then _( x23763(0, 5); x23762(449) _);
   if 8 in g0050 then _(
      (q) for i := 0 to zg - 1 do write(' ', g1035@[i]:1 hex);
      writeln
   _);
   (q) for i := 0 to zg - 1 do _(
      g1036[g1042] := g1035@[i];
      if g1042 = 11 then _( x23466(g1041, g1036); g1042 := 0 _)
      else g1042 := g1042 + 1
   _);
   if g1164 then goto 2;
   if g1042 <> 0 then x23466(g1041, g1036);
   g1044 := g1045; g1051 := g1054; g1050 := g1053; g1052 := g1055;
   if 9 in g0050 then p04347('ПOCЛE ');
   besm(630004B); (r); besm(150000B : 0); g1063 := ;
_);
%
_( g1166 := 0;
   h0050 := 5; h0051 := 100000B; h0052 := 70000B; h0053 := 40000B;
   h0054 := 2200000B; g0050 := [40..47];
   d115.ext := '*****_000'; d115.lib := '******'; d115.name := ;
   g1026 := d115;
   g1031 := 4096; g1126 := 0;
   g1044 := [1, 2, 4, 5, 6, 11, 12, 13, 14, 35];
   d3 := 0; d101 := 0; d102 := 0; d103 := false;
   g1046 := 78; g1047 := 66; g1050 := 9; g1051 := 16; g1052 := 28;
   p05566;
1: x27233(32, 2, 0); g1166 := 1; p06413;
   besm(630004B); (r); besm(150000B : 0); g1062 := ;
2: p17204;
3: g1164 := true;
4: p17534
_);
%
_( p17650 _).
