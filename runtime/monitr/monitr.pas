(*=y+,p-,t-,o-*)
program MOHИTOP(input, output, TTIO);
% МОНИТР, паскалевская часть: том 4001, зоны 0002-0010 (02000-17777).
% Сборка: python3 runtime/monitr/build.py (свой компилятор и диски).
% Все слова 02000-07431 совпадают с оригиналом, кроме значения
% загрузчика в 02010.Л. Слова 07432-17777 лежат выше FREE: это буферы,
% оставшиеся в памяти при записи исходного образа (текст include
% с 10000 и колода задания с 12000), к программе они не относятся.
% Таблиц PMD нет (p-), поэтому идентификаторы придуманы. Имена
% внешних процедур взяты из include-колоды тома 4001 и из COPY, где
% они там есть; см. runtime/monitr/build.py и README.md.
% Строки-комментарии сохраняют исторические номера строк: пустые
% строки компилятор не считает, поэтому их нет.
% Для o- нужен mypas.b6 с единой таблицей констант, как в оригинале.
%
%
label 1, 2;
const lf = '_012';
type PSTRING = packed array [1..84] of char;
     WORD3 = record TИПФ, NL, NF: alfa end;
     bitset = set of 0..47;
     ЗAПБИБ = record ИMЯ: alfa; HЗ: integer end;
     ЗAПKAT = record ИMЯ: alfa;
       П: packed record PEЗ: 0..2147483647; ДЛ: 0..127; HЗ: 0..1023 end
     end;
     ЗAПATP = record X: alfa;
       П: packed record TИП: 0..4095; PEЗ: 0..68719476735 end
     end;
var ACTIVELI [3B]: alfa;
    CMDLINE [55B]: PSTRING;
    БИБЛ [21B]: array [1..12] of ЗAПБИБ;
    ЗAHЯT [51B]: bitset;
    ИMЯЗAП [73B]: alfa;
    ФЛAГ [74B]: boolean;
    KTЛ [76000B]: array [0..1023] of integer;
    OГЛKTЛ [76000B]: alfa;
    ПPИKTЛ [77000B]: integer;
    ФЗOH [76002B]: integer;
    KAT [76001B]: array [1..255] of ЗAПKAT;
    ATP [77001B]: array [1..255] of ЗAПATP;
    CИMB: char;
    X51: integer;
    TИXO: boolean;
    KOM: alfa;
    ЛEKC: alfa;
    I: integer;
    X56: integer;
    TOM: PSTRING;
    TTIO: record T0: integer; ФЛ: bitset; CTP: integer;
      PEЖ: bitset; T4: array [4..22] of integer end;
procedure READLINE(var F: text); external;
procedure ERROR(KO: integer; var TOШ: PSTRING); assembler;
function LIB(NAMELIB: alfa; var HYЗЗЗЗ: integer): integer; assembler;
function DLIB(NAMELIB: alfa): integer; assembler;
function OPENF(var ИMЯ: WORD3; ДOCTYП: boolean;
  var DESCR: integer): integer; assembler;
procedure SETDESCR(DESCR: integer); assembler;
procedure RUN(DESCR: integer); assembler;
function MAKEF(var ИMЯ: WORD3; L: integer;
  var DESCR: integer): integer; assembler;
function CLOSEF(var ИMЯ: WORD3; L: integer;
  var DESCR: integer): integer; assembler;
function DELF(var ИMЯ: WORD3): integer; assembler;
function RENAMEF(var ИMЯ1, ИMЯ2: WORD3): integer; assembler;
function DOZAK(var ФИЗTOM: PSTRING; HY, ПAPЧT, ПAPЗП: integer):
  integer; assembler;
procedure OTKAZ(HY: integer); assembler;
function MONTOM(HY, ПAPOЛЬ: integer): integer; assembler;
procedure SETBUF(AДP: integer); assembler;
function KOI8(C: char): char; assembler;
function FIRSTF(var NAME: PSTRING; LIBY, PACШИP: alfa;
  var ИMЯ: WORD3): integer; assembler;
function NEXTF(var ИMЯ: WORD3): integer; assembler;
function MKNAME(var NAME: PSTRING; NAMELIB, PACШИP: alfa;
  var ИMЯ: WORD3): integer; assembler;
procedure SVJAZ; assembler;
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
function ЦИФPA(C, MAX: char): boolean;
begin
  ЦИФPA := (C <= MAX) and (C >= '0');
end;
%
%
%
%
%
procedure OШMOH(KO: integer);
var TOШ: PSTRING;
begin
  if KO = 0 then exit;
  ERROR(KO, TOШ);
  writeln(TOШ);
  if TИXO then goto 1 else besm(3000004B);
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
end;
procedure ДAЙCИ;
begin
  if eoln(input) then begin CИMB := lf; exit end;
  CИMB := input@;
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
  get(input);
end;
function ПPOПYC: boolean;
begin
  if CИMB = lf then begin ПPOПYC := false; exit end;
  if CИMB <> ' ' then begin ПPOПYC := true; exit end;
  while CИMB = ' ' do ДAЙCИ;
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
  ПPOПYC := CИMB <> lf;
end;
function BBЛEKCEM(var ЛEKCEMA: PSTRING; PAЗД1, PAЗД2: char): boolean;
var I: integer;
begin
  if not ПPOПYC then begin BBЛEKCEM := false; exit end;
  I := 1; BBЛEKCEM := true;
  while CИMB <> lf do begin
    if (CИMB = PAЗД1) or (CИMB = PAЗД2) then begin
      ЛEKCEMA[I] := lf; exit
    end;
    ЛEKCEMA[I] := CИMB;
    I := I + 1;
    ДAЙCИ;
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
  end;
  ЛEKCEMA[I] := lf;
end;
function BBAЛФA(var A: alfa; PAЗД1, PAЗД2: char): boolean;
var I: integer;
begin
  if not ПPOПYC then begin BBAЛФA := false; exit end;
  A := '      ';
  (q) for I := 1 to 6 do begin
    if (CИMB = PAЗД1) or (CИMB = PAЗД2) or (CИMB = lf) then exit q;
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
    A[I] := CИMB;
    ДAЙCИ;
  end;
  BBAЛФA := (CИMB = PAЗД1) or (CИMB = PAЗД2) or (CИMB = lf);
end;
%
%
%
%
%
procedure ПOKAPX;
begin
  writeln("   APXИB: ", ACTIVELI);
end;
function BBOCT: integer;
var Ч, B: integer;
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
begin
  Ч := 0; B := 100000B;
  if not ПPOПYC then begin BBOCT := 0; exit end;
  while ЦИФPA(CИMB, '7') do begin
    if B <> 0 then begin
      Ч := Ч + B * (ord(CИMB) - ord('0'));
      B := B div 8;
    end;
    ДAЙCИ;
  end;
  BBOCT := Ч;
end;
function ЧИCЛO(OCH: integer): integer;
var Ч: integer;
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
begin
  Ч := 0; ЧИCЛO := 0;
  if not ПPOПYC then exit;
  while ЦИФPA(CИMB, chr(OCH - 1 + ord('0'))) do begin
    Ч := Ч * OCH + ord(CИMB) - ord('0');
    ДAЙCИ;
  end;
  ЧИCЛO := Ч;
end;
function ДAЛЬШE: boolean;
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
begin
  ДAЛЬШE := true;
  if not TИXO then exit;
  if 23 in TTIO.ФЛ then begin ДAЛЬШE := false; exit end;
  with TTIO do begin
    CTP := CTP + 1;
    if CTP < 16 then exit;
    CTP := 0;
  end;
  rewrite(input);
  write(input, '_077');
  READLINE(input);
  ДAЙCИ;
  if CИMB <> lf then ДAЛЬШE := false;
end;
function HAЙTИ(L: alfa; var K: integer): boolean;
var F: boolean;
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
begin
  K := 1;
  (l) while БИБЛ[K].ИMЯ <> alfa(0C) do begin
    F := БИБЛ[K].ИMЯ = L;
    if F then exit l;
    K := K + 1;
  end;
  HAЙTИ := F;
end;
procedure YCTБИБ(L: alfa);
var K: integer;
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
begin
  if HAЙTИ(L, K) then ACTIVELI := L else OШMOH(4);
end;
% $БИБ [ИМЯ [АДРЕС]]. Без операндов печатает активную библиотеку
% (ПOKAPX). С одним ИМЕНЕМ делает активной эту подключенную
% библиотеку. С восьмеричным адресом (300400 - том 30, зона 0400)
% подключает библиотеку ИМЯ по этому адресу (LIB), отмечает том как
% занятый и делает ИМЯ активной; если не TИXO, сообщает о подключении.
procedure БИБ;
var HY, X: integer; L: alfa;
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
begin
  if not BBAЛФA(L, ' ', ' ') then begin ПOKAPX; exit end;
  HY := BBOCT;
  if HY = 0 then begin YCTБИБ(L); exit end;
  if not TИXO then begin
    writeln('      ');
    writeln("    ****  БИБЛ: ", HY:6 oct, '  ', L, '  ****');
    writeln('      ');
  end;
  OШMOH(LIB(L, HY));
  ЗAHЯT := ЗAHЯT + [HY div 4096 - 24];
  ACTIVELI := L;
end;
% Любая другая команда, $ИМЯ или $БИБЛ/ИМЯ: запуск программы ИМЯ.КОД.
% С явной БИБЛ файл открывается в ней. Иначе ищется в активной
% библиотеке, затем в подключенных по порядку таблицы; если файла нет
% нигде, выдается ошибка для ******/ИМЯ. Остаток командной строки
% остается в CMDLINE как параметр программы. Имя библиотеки пишется
% в ячейку 073; RUN загружает код и передает ему управление.
procedure ЗAПYCK;
var ЯBHO: boolean; KO, K: integer; ИMЯ: WORD3; D: integer;
  procedure ПOKФAЙЛ;
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
  begin
    if not TИXO then begin
      writeln('      ');
      writeln("    ****  ФAЙЛ: ", ИMЯ.NL, '/', ИMЯ.NF, '  ****');
      writeln('      ');
    end;
  end;
%
%
%
%
begin
  ИMЯ.TИПФ := "KOД  _000";
  if CИMB = '/' then begin
    ЯBHO := true; ИMЯ.NL := ЛEKC;
    ДAЙCИ;
    if not BBAЛФA(ЛEKC, ' ', ' ') then OШMOH(9);
    ИMЯ.NF := ЛEKC;
  end else begin
    ЯBHO := false; ИMЯ.NF := ЛEKC; ИMЯ.NL := ACTIVELI;
  end;
  if not BBЛEKCEM(CMDLINE, lf, lf) then CMDLINE[1] := lf;
  if ЯBHO then begin
    ПOKФAЙЛ;
    OШMOH(OPENF(ИMЯ, false, D));
    ИMЯЗAП := ИMЯ.NL;
    SETDESCR(D);
    RUN(D);
  end else (done) begin
    KO := OPENF(ИMЯ, false, D);
    if KO = 0 then begin
      SETDESCR(D); ПOKФAЙЛ; ИMЯЗAП := ИMЯ.NL; RUN(D); exit done
    end;
    (l) for K := 1 to 12 do begin
      if БИБЛ[K].ИMЯ = alfa(0C) then exit l;
      ИMЯ.NL := БИБЛ[K].ИMЯ;
      KO := OPENF(ИMЯ, false, D);
      if KO = 0 then begin
        SETDESCR(D); ПOKФAЙЛ; ИMЯЗAП := ИMЯ.NL; RUN(D); exit done
      end;
    end;
    ИMЯ.NL := '******';
    ПOKФAЙЛ;
    OШMOH(KO);
  end;
end;
% $АРХ ИМЯ ТОМ [ПАРОЛЬ] или $АРХ ИМЯ ТОМ +Ч З ПАРОЛЬ (также $АР, $А).
% Дозаказывает физический ТОМ (DOZAK) на первый свободный
% виртуальный номер 31-70, пропуская занятые; после '+' идут
% параметры чтения и записи заказа. Затем монтирует том с ПАРОЛЕМ
% (MONTOM), подключает библиотеку ИМЯ с зоны 0 этого тома (LIB) и
% делает ее активной. С одним ИМЕНЕМ работает как $БИБ ИМЯ.
procedure APXИB;
var ПЧ, ПЗ, K, KO, J, П: integer; L: alfa; HY: integer;
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
begin
  if not BBAЛФA(L, ' ', ' ') then begin ПOKAPX; exit end;
  if not ПPOПYC then begin YCTБИБ(L); exit end;
  J := 1; ПЧ := 0; ПЗ := 0; П := 0;
  while (CИMB <> lf) and (CИMB <> ' ') and (CИMB <> '+') do begin
    TOM[J] := CИMB;
    ДAЙCИ;
    J := J + 1;
  end;
  TOM[J] := lf;
  (w) while true do
    case CИMB of
    lf: exit w;
    ' ': П := ЧИCЛO(8);
    '+': begin ДAЙCИ; ПЧ := ЧИCЛO(8); ПЗ := ЧИCЛO(8);
           П := ЧИCЛO(8); exit w end;
    others: exit w
    end;
  (l) for K := 1 to 32 do
    if not (K in ЗAHЯT) then begin
      KO := DOZAK(TOM, K + 24, ПЧ, ПЗ);
      if KO = 0 then exit l;
      if (KO <> 3) and (KO <> 66) then OШMOH(KO);
      ЗAHЯT := ЗAHЯT + [K];
    end;
  if K = 33 then OШMOH(16);
  HY := (K + 24) * 4096;
  OШMOH(MONTOM(HY, П));
  OШMOH(LIB(L, HY));
  ЗAHЯT := ЗAHЯT + [K];
  ACTIVELI := L;
end;
% $КТБ: список подключенных библиотек, по строке на библиотеку: имя и
% восьмеричный адрес; вывод по страницам (ДAЛЬШE).
procedure KTБ;
var K: integer;
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
begin
  K := 1;
  while БИБЛ[K].ИMЯ <> alfa(0C) do begin
    writeln('   ', БИБЛ[K].ИMЯ, '    ', БИБЛ[K].HЗ:6 oct);
    if not ДAЛЬШE then exit;
    K := K + 1;
  end;
end;
% $КТ [ИМЯ] или $КТЛ: читает каталог библиотеки ИМЯ (по умолчанию
% активной) в 76000 по Э70 и печатает ее файлы: имя (КОИ-8), тип,
% начальную зону НЗ и длину ДЛ в зонах. Каталог без признака 0377
% считается испорченным.
procedure KATЛ;
var K: integer; L: alfa; I, J: integer; ИCЧT: bitset;
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
begin
  if not BBAЛФA(L, ' ', ' ') then L := ACTIVELI;
  if not HAЙTИ(L, K) then OШMOH(4);
  ИCЧT := bitset(10370000000000C) + bitset(БИБЛ[K].HЗ);
  besm(700000B : ИCЧT);
  if OГЛKTЛ[1] <> "_377" then begin
    writeln("   KATAЛOГ ИCПOPЧEH");
    exit
  end;
  for I := 1 to 255 do begin
    if KAT[I].ИMЯ = alfa(0C) then exit;
    write("    ФAЙЛ : ");
    for J := 1 to 6 do write(KOI8(KAT[I].ИMЯ[J]));
    case ATP[I].П.TИП of
    0: write('.', "KOД  ");
    12: write('.', 'ISO  ');
    14: write('.', "KOИ7 ");
    8: write('.', 'TEKCT');
    13: write('.', "KOИ8 ");
    2: write('.', "MOД  ");
    others: write('.', '***')
    end;
    writeln('  ', "HЗ : ", KAT[I].П.HЗ:4 oct,
          '  ', "ДЛ : ", KAT[I].П.ДЛ:4 oct);
    if not ДAЛЬШE then exit;
  end;
end;
% $ОТК ИМЯ или $ОТК НОМЕР (также $О, $ОТ). С восьмеричным номером
% освобождает виртуальный том (OTKAZ) и убирает его из занятых. С
% именем библиотеки отключает ее (DLIB) и печатает виртуальный
% номер, который она занимала.
procedure OTK;
var L: alfa; KO, HY: integer;
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
begin
  if not ПPOПYC then OШMOH(9);
  if ЦИФPA(CИMB, '7') then begin
    HY := ЧИCЛO(8);
    OTKAZ(HY);
    ЗAHЯT := ЗAHЯT - [HY - 24];
    exit
  end;
  if not BBAЛФA(L, ' ', ' ') then OШMOH(9);
  KO := LIB(L, HY);
  if KO <> 5 then OШMOH(KO);
  HY := HY div 4096;
  OШMOH(DLIB(L));
  writeln(" OTKЛЮЧEHA БИБЛИOTEKA : ", L);
  writeln(" COXPAHEH BИPT. HOMEP : ", HY:6 oct);
end;
% $НКТ ИМЯ: записывает пустой каталог в подключенную библиотеку ИМЯ:
% читает ее зону 0, обнуляет все 1024 слова, ставит признак 0377,
% первую свободную зону 1 и заголовок таблицы типов и записывает
% зону обратно.
procedure HKT;
var KO, HY, I: integer; L: alfa; ИCЧT: bitset;
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
begin
  if not BBAЛФA(L, ' ', ' ') then OШMOH(9);
  HY := 0;
  KO := LIB(L, HY);
  if KO <> 5 then OШMOH(KO);
  ИCЧT := bitset(10370000000000C) +
    bitset(HY) * bitset(77777777C);
  besm(700000B : ИCЧT);
  for I := 0 to 1023 do KTЛ[I] := 0C;
  ПPИKTЛ := 1C;
  ФЗOH := 1C;
  OГЛKTЛ[1] := "_377";
  OГЛKTЛ[6] := '_001';
  ИCЧT := ИCЧT - [8];
  besm(700000B : ИCЧT); (q);
  writeln("  ECTЬ");
end;
% $НФ ИМЯ ДЛИНА (также $Н, $НФА): заводит в активной библиотеке
% файл ИМЯ.КОД длиной ДЛИНА зон (восьмерично) (MAKEF).
procedure HФ;
var NAME: PSTRING; ИMЯ: WORD3; L, D: integer;
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
begin
  if not BBЛEKCEM(NAME, ' ', ' ') then begin
    writeln("  HET ИMEHИ ФAЙЛA  "); exit
  end;
  OШMOH(MKNAME(NAME, ACTIVELI, "KOД  _000", ИMЯ));
  L := ЧИCЛO(8);
  OШMOH(MAKEF(ИMЯ, L, D));
  writeln("  ECTЬ");
end;
% $ЗАК ИМЯ ДЛИНА: закрывает файл ИМЯ.КОД активной библиотеки,
% устанавливая длину ДЛИНА зон (восьмерично) (CLOSEF).
procedure ЗAK;
var NAME: PSTRING; ИMЯ: WORD3; L, D: integer;
%
%
%
%
%
%
begin
  if not BBЛEKCEM(NAME, ' ', ' ') then begin
    writeln(" HET ФAЙЛA"); exit
  end;
  OШMOH(MKNAME(NAME, ACTIVELI, "KOД  _000", ИMЯ));
  L := ЧИCЛO(8);
  OШMOH(CLOSEF(ИMЯ, L, D));
  writeln("  ECTЬ");
end;
% $УНЧ ИМЯ (также $У, $УН): уничтожает файл ИМЯ.КОД в активной
% библиотеке (DELF).
procedure YДAЛ;
var NAME: PSTRING; ИMЯ: WORD3;
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
begin
  if not BBЛEKCEM(NAME, ' ', ' ') then begin
    writeln("  HET ИMEHИ ФAЙЛA "); exit
  end;
  OШMOH(MKNAME(NAME, ACTIVELI, "KOД  _000", ИMЯ));
  OШMOH(DELF(ИMЯ));
  writeln("  ECTЬ");
end;
% $ИМЯ СТАРОЕ НОВОЕ (также $И, $ИМ): переименовывает файл
% СТАРОЕ.КОД активной библиотеки в НОВОЕ (RENAMEF).
procedure ПEPEИM;
var ИMЯ1, ИMЯ2: WORD3; NAME: PSTRING;
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
begin
  if not BBЛEKCEM(NAME, ' ', ' ') then
    writeln("  HET ИMEHИ ФAЙЛA ");
  OШMOH(MKNAME(NAME, ACTIVELI, "KOД  _000", ИMЯ1));
  if not BBЛEKCEM(NAME, ' ', ' ') then
    writeln("  HET ИMEHИ ФAЙЛA ");
  OШMOH(MKNAME(NAME, ACTIVELI, "KOД  _000", ИMЯ2));
  OШMOH(RENAMEF(ИMЯ1, ИMЯ2));
  writeln("  ECTЬ");
end;
% $ДАЙ ИМЯ: перечисляет файлы, подходящие под ИМЯ (FIRSTF, NEXTF),
% с их восьмеричными дескрипторами от OPENF. Цикл кончается на
% первой ошибке, выданной через OШMOH.
procedure ДAЙ;
label 3;
var NAME: PSTRING; ИMЯ: WORD3; L, D: integer;
%
%
%
%
%
%
%
%
%
begin
  if not BBЛEKCEM(NAME, ' ', ' ') then begin
    writeln("  HET ИMEHИ ФAЙЛA "); exit
  end;
  OШMOH(FIRSTF(NAME, ACTIVELI, "KOД  _000", ИMЯ));
  writeln(ИMЯ.NL, '/', ИMЯ.NF, '.', ИMЯ.TИПФ);
3:OШMOH(NEXTF(ИMЯ));
  writeln(ИMЯ.NL, '/', ИMЯ.NF, '.', ИMЯ.TИПФ);
  OШMOH(OPENF(ИMЯ, true, D));
  writeln(D:24 oct);
  goto 3;
end;
% $УСТ АЦП (также $УС): подключает печать (SVJAZ) и ставит бит 47
% слова режима TTIO. О другом режиме сообщает, что его нет.
% Вызывается только включение; ветка выключения не используется.
procedure YCT(BKЛ: boolean);
var P: alfa;
%
%
%
%
%
%
%
%
begin
  if not BBAЛФA(P, ' ', ' ') then writeln("  HET PEЖИMA ");
  if P <> "AЦП   " then writeln("    HET PEЖИMA");
  if BKЛ then begin
    SVJAZ;
    TTIO.PEЖ := TTIO.PEЖ + [47];
  end else
    TTIO.PEЖ := TTIO.PEЖ - [47];
end;
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
begin
  TИXO := 45 in TTIO.PEЖ;
1:SETDESCR(0);
  SETBUF(76000B);
  while true do begin
2:ФЛAГ := false;
  rewrite(input);
  write(input, '$');
  READLINE(input);
  if eof(input) then besm(3000004B);
  ДAЙCИ;
  if CИMB = lf then goto 2;
  if CИMB = '$' then ДAЙCИ;
  if not BBAЛФA(ЛEKC, ' ', '/') then OШMOH(9);
  KOM := ЛEKC;
  for I := 4 to 6 do KOM[I] := ' ';
  if CИMB = '/' then ЗAПYCK;
  case KOM of
  "БИБ   ": БИБ;
  'APX   ': APXИB;
  'AP    ': APXИB;
  'A     ': APXИB;
  "KTБ   ": KTБ;
  'KT    ': KATЛ;
  "KTЛ   ": KATЛ;
  'O     ': OTK;
  'OT    ': OTK;
  'OTK   ': OTK;
  'HKT   ': HKT;
  "KHЦ   ": begin besm(3000004B); (q); end;
  'H     ': HФ;
  "HФ    ": HФ;
  "HФA   ": HФ;
  'Y     ': YДAЛ;
  'YH    ': YДAЛ;
  "YHЧ   ": YДAЛ;
  "И     ": ПEPEИM;
  "ИM    ": ПEPEИM;
  "ИMЯ   ": ПEPEИM;
  "ДAЙ   ": ДAЙ;
  'YCT   ': YCT(true);
  'YC    ': YCT(true);
  "ЗAK   ": ЗAK;
  others: ЗAПYCK
  end;
  end;
  besm(3000002B); (q);
end.
