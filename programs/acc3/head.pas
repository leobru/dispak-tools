(*=p-,t-,s5,s8,y+,o-,a4,w+*)
program head(input, output,
    za, zb, zc, zd, ze, zf, zg, zh, zi, zj, zk, zl);
% Головная часть ассемблера АСС3 (том 4001, зона 0132), восстановленная
% по коду. Сборка и сравнение с оригиналом:
%   python3 programs/acc3/headtry.py
% Совпадают все 1024 слова зоны (02000-03777). FREE = 040000 (стек выше
% обоих оверлеев) задан параметром S*40000 в *TABLE:P/CODER.
%
% Имена придуманы, как в ov1.pas: типы и глобалы те же, что у оверлеев.
% Главная программа читает дескриптор запущенного файла (x03606, ячейка
% 052), ставит чтение одной зоны на страницу 2 и загружает оверлеи
% (x03612) с зон +4 и +020. x03606 и x03612 - ассемблерные модули,
% сборщик берёт их из слов образа.
% Без файловой инициализации (s5). Параметры программы - общие блоки
% za..zl после *OUTPUT*, как у оверлеев, но zl короче (150 слов): за ним
% сразу идут x03606 и x03612 (03606); все слова до них нулевые.
% Начальные значения глобалов - раздел .data (его печатает
% programs/acc3/headdata.py). Сообщения (t0 = packed array [0..35] of
% char) записаны строками целиком, это требует mypas, где .data
% принимает многословные строки. Под w+ адрес g0051[k] не помещается в
% одну команду (ошибка 48), поэтому перед .data стоит w-. В оверлеях t0
% - шесть alfa: они печатают сообщение по словам.
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
     t0 = packed array [0..35] of char;
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
          9: (u0: 0..127; ua: 0..3; ub: 0..1; uc: boolean; ud: 0..1)
         end;
     lbits = packed record lv, lx: 0..15; lc1, lc2: char; ly: boolean;
                    lb, l26, l27, l28: boolean; lz: 0..7;
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
    zl: array [0..149] of integer; (* 20655 *)
%
function x03606: integer; assembler;
procedure x03612(z: integer); assembler;
_( besm(630004B); (r); besm(150000B : 0); g1061 := ;
   g1165 := x03606;
   besm(110000B : 777777C, 150000B : 0010020000000000C); g1165 := ;
   x03612(g1165 + 4C);
   x03612(g1165 + 20C);
   besm(740000B)
_)(*=w-*).data
g0051[1] := '    OШИБKA AЛГOPИTMOB TPAHCЛЯЦИИ    ';
g0051[2] := '  B TEKYЩEЙ BEPCИИ HE PEAЛИЗOBAHO   ';
g0051[3] := '    ФAЙЛOBAЯ CИCTEMA HEДOBOЛЬHA     ';
g0051[4] := '  HEДOПYCTИMAЯ BЛOЖEHHOCTЬ ФAЙЛOB   ';
g0051[5] := '  ПEPEПOЛHEHИE TAБЛИЦ TPAHCЛЯTOPA   ';
g0051[6] := '        HEДOПYCTИMЫЙ CИMBOЛ         ';
g0051[7] := '          TPEБYETCЯ CKOБKA          ';
g0051[8] := '         TPEБYETCЯ ЗAПЯTAЯ          ';
g0051[9] := '          TPEБYETCЯ PABHO           ';
g0051[10] := '         TPEБYETCЯ AПOCTPOФ         ';
g0051[11] := '        TPEБYETCЯ ДBOETOЧИE         ';
g0051[12] := '       HEBEPHOE ИMЯ ПAPAMETPA       ';
g0051[13] := '       HEДOПYCTИMЫЙ MHEMOKOД        ';
g0051[14] := 'HEПPABИЛЬHO HAЧИHAETCЯ ИДEHTИФИKATOP';
g0051[15] := '       OTCYTCTBYET ПOЛE METKИ       ';
g0051[16] := '     OTCYTCTBYET ПOЛE OПEPAHДA      ';
g0051[17] := '   ЛИШHИE CИMBOЛЫ B ПOЛE OПEPAHДA   ';
g0051[18] := '     HEOПPEДEЛEHHAЯ ПEPEMEHHAЯ      ';
g0051[19] := ' HEOПPEДEЛEHHOE OБOЗHAЧEHИE CEKЦИИ  ';
g0051[20] := '       ПOBTOPHOE OПPEДEЛEHИE        ';
g0051[21] := '   OTCYTCTBYET OПPEДEЛEHИE ИMEHИ    ';
g0051[22] := '   MHOГOKPATHOE OПPEДEЛEHИE ИMEHИ   ';
g0051[23] := '    ИMЯ HE ЯBЛЯETCЯ ИMEHEM БЛOKA    ';
g0051[24] := ' HET OTKPЫTOГO БЛOKA C TAKИM ИMEHEM ';
g0051[25] := '    HAPYШEHA ПOCЛ.BЛOЖEHHЫX ИMEH    ';
g0051[26] := '     COCTABHOE ИMЯ HEДOПYCTИMO      ';
g0051[27] := '    ИMЯ HE ЯBЛЯETCЯ HEДOCTYПHЫM     ';
g0051[28] := ' BHEШHEE ИMЯ HE MOЖET БЫTЬ BXOДHЫM  ';
g0051[29] := '       TPEБYETCЯ BHEШHEE ИMЯ        ';
g0051[30] := '    ИMЯ HE ЯBЛЯETCЯ ИMEHEM ПOЛЯ     ';
g0051[31] := '      OШИБKA B ЗAДAHИИ ЦEЛOГO       ';
g0051[32] := '     HEДOПYCTИMЫЙ TИП KOHCTAHTЫ     ';
g0051[33] := '   HEДOПYCTИMAЯ TEKCTOBAЯ ЛИTEPA    ';
g0051[34] := '    OШИБKA B TEKCTOBOЙ KOHCTAHTE    ';
g0051[35] := '      HEBEPHЫЙ ЗHAK OTHOШEHИЯ       ';
g0051[36] := 'TPEБYETCЯ CAMOOПPEДEЛEHHOE BЫPAЖEHИE';
g0051[37] := '  TPEБYETCЯ BЫЧИCЛЯEMOE BЫPAЖEHИE   ';
g0051[38] := '   TPEБYETCЯ AБCOЛЮTHOE BЫPAЖEHИE   ';
g0051[39] := 'TPEБYETCЯ BЫЧИCЛЯEMOE AБC.BЫPAЖEHИE ';
g0051[40] := ' OTPИЦATEЛЬHOE ЗHAЧEHИE HEДOПYCTИMO ';
g0051[41] := ' ИCПOЛЬЗOBAHИE ЛИTEPAЛA B BЫPAЖEHИИ ';
g0051[42] := '     CЛИШKOM CЛOЖHOE BЫPAЖEHИE      ';
g0051[43] := ' HEKOPP.ИCПOЛЬЗOBAHИE AДPECHOЙ ПAPЫ ';
g0051[44] := '  TPEБYETCЯ ПEPEMEЩAEMOE BЫPAЖEHИE  ';
g0051[45] := '     HEKOPPEKTHAЯ ГPAHИЦA ПOЛЯ      ';
g0051[46] := '    ПEPEПOЛHEHИE PAЗPЯДHOЙ CETKИ    ';
g0051[47] := '          ДEЛEHИE HA HOЛЬ           ';
g0051[48] := '      HE ЗAДAH ИHДEKC-PEГИCTP       ';
g0051[49] := 'HEKOPPEKTHOE ЗAДAHИE ИHДEKC-PEГИCTPA';
g0051[50] := '     HEKOPPEKTHOE ЗHAЧEHИE БAЗЫ     ';
g0051[51] := '  AДPEC BHE ДOПYCTИMOГO ДИAПAЗOHA   ';
g0051[52] := 'HAPYШEHИE ПOЗИЦИOHHOЙ HEЗABИCИMOCTИ ';
g0051[53] := ' HEДOПYCTИMЫЙ ЧИCЛOBOЙ KOД OПEPAЦИИ ';
g0051[54] := 'HEBEPHOE BЛOЖEHИE YCЛOBHЫX OПEPAЦИЙ ';
g0051[55] := ' OШИБKA B PAБOTE CO CTEKOM ЛИCTИHГA ';
g0051[56] := ' OШИБKA B PAБOTE CO CTEKOM PEЖИMOB  ';
g0051[57] := '       HE PAЗMEЩEHЫ ЛИTEPAЛЫ        ';
g0051[58] := '       BCTPETИЛCЯ KOHEЦ ФAЙЛA       ';
g0614 := 2000000000000000C, 5400000000000000C;
g0617 := 4025400000000000C, 1000000000000000C;
g0724 := 31203300110433C, 11001100210011C, 11001100110011C:2,
    11041100110011C, 411001104110011C, 433043304110411C,
    411041104110411C, 421042104110411C, 1421142114211412C,
    421042104112411C, 1421243124312431C, 2021202124112011C,
    433043304112011C, 421201120112031C, 433202104110411C, 0C:4,
    41100000000C, 411000004110000C, 433043304110000C,
    411041104110411C, 4110411C, 0C, 4110000C, 0C:2, 433043304110000C,
    421000000000000C, 433000004110411C, 21002101110311C,
    111011101110111C, 311021102110211C, 111021100110111C,
    211021102110211C, 11001100110011C, 11301210121012C, 110000C,
    1011101110111011C, 1011101100000000C, 11001100110011C:2,
    11002100310031C, 21002100210021C, 412003100310011C,
    1032103240110000C, 11001100110011C:3, 11001100000011C,
    11001100110011C:2, 11000000000000C, 11000000000011C,
    1422142214121412C, 1412141214121412C:4, 1412141214120000C,
    1412142214321432C, 1422142214121422C;
g1134 := 1340000000000000C;
g1140.hi := 7777C;
g1142.lo := 2000000000000C;
g1144.hi := 40000000000000C;
g1146.hi := 1C;
g1150 := 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334;
zh := 1, 2, 3, 4, 8, 16;
end
