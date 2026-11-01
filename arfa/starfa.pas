(*=p-,t-,k1,y+*)program STAT(output, БУФ, СЛОВО, ГОСТИСО, ИСОГОСТ);
% STAT (СТАРФА): статистика архива АРФА по каталогу, (*06.12.88*).
% Восстановлено по оверлею 2113/1710-1717 (образ 0770-022001, make
% starfa.bin); имена придуманы. Модуль ТЕРМ (терминал, ключ
% администратора) - в starfa.pre.
% Сборка: ./buildovl.sh starfa.pas STAT starfa.bin - штатный
% компилятор 15.0 под ЗСХ, *perso:311160 и 330000, *call overlay.
% Совпадают слово в слово: код, пул, глобалы, таблицы ГОСТИСО и
% ИСОГОСТ (0770-013607, кроме слова 0776 заглушки, как у БЮСТ) и
% модули ТЕРМ и ПЕРЕКОД. Библиотека - другой версии: в оригинале
% PASEOF/READ* короче на 5 слов и 2 слова текста сообщений иные.
% Программа после начальных присваиваний вызывает однословную пустую
% процедуру (в образе 15624). Здесь это модуль ПЕРЕКОД из starfa.pre:
% он же задаёт начальные значения таблиц ГОСТИСО и ИСОГОСТ. Нынешний
% библиотечный PASISOCD на этом месте добавил бы после P/EDIH таблицы
% ISOPGOST..ISOPRESV (0115 слов), которых в оригинале нет; его
% ISOPGOST отличается от ИСОГОСТ тремя словами. Модуль с именем
% PASISOCD в starfa.pre загрузчик не берёт: берёт библиотечный.
% Особенности текста под компилятор 15.0:
% - если аргумент начинается с not, результат f(not a ...) тоже
%   инвертируется (ошибка компилятора), поэтому в фильтре для
%   признака СТР стоит not xor(not ...): это и даёт код оригинала;
% - exit без метки выходит из процедуры; выходы из циклов записаны
%   структурными метками (q) и exit q;
% - цепочки приказов - select с последним вариантом true: (переход
%   на конец есть и после последней ветки);
% - номера строк выровнены строками %; неиспользуемые слова
%   глобалов названы по смещению (пNNN). Отступы - py/pasindent.py
%   (строки begin процедур не сдвинуты).
type ссылка = packed record л: 0..77777777B; зона: 0..177777B;
квант: 0..255 end;
пара = record а, б: integer end;
имя = packed array [1..9] of char;
тстек = array [1..7] of имя;
зоны = array [0..511] of integer;
заг0 = packed record след: 0..177777B; р: 0..177777B;
ключ: 0..177777B end;
связь = packed record отец: 0..177777B; эл: 0..7; кв: 0..31;
р: 0..77777777B end;
дата = packed record а: 0..3; б: 0..15; в: 0..1; г: 0..15;
д: 0..15 end;
цифры = packed array [1..6] of 0..15;
вид = 0..3;
шифры = packed array [1..6] of цифры;
виды = packed array [1..6] of вид;
элемент = packed record им: имя;
хоз: цифры; ф1: 0..1; тп: 0..63; ф2: 0..1; вд: вид; ф3: 0..37777B;
пч, пз: 0..7777B; ф4: 0..255; длина: 0..177777B;
зона: 0..177777B; флаг: 0..1; ф5: 0..1777777B; вв: виды;
шб: цифры; бв, боб: 0..7777B;
друзья: шифры;
дз: дата; ссыл: 0..77777777B; время: 0..777B;
дч, дс: дата; ф6: 0..777777B;
кол: 0..77777777B; ф7: 0..255; тд: 0..177777B;
ф8, ф9: 0..77777777B end;
квант = record э: array [0..2] of элемент; связи: связь end;
зона = record з0: заг0; заг: array [1..23] of integer;
к: array [0..24] of квант end;
узел = packed record ключ: integer; зк: 0..7777B; где: 0..1777B;
след: ^узел; ост: 0..3777B end;
стр = packed array [1..504] of char;
тответ = packed array [1..80] of char;
тимена = array [1..7] of имя;
тбуф = array [1..82] of char;
тколонки = array [1..26] of integer;
флаги = array [1..25] of boolean;
тмаска = record пч, пз: boolean; имена: тимена; есть, стр: boolean;
ним, ч1, ч2, т1, т2, дл1, дл2, з1, з2, к1, к2, б1, б2, в1, в2,
тд1, тд2, бв1, бв2: integer; дс1, дс2, дз1, дз2, дч1, дч2: дата;
хоз, шб, друг, шзп: цифры; зк1, зк2, где1, где2: integer end;
var
новкэш: boolean;
шифрзп: цифры;
ушифр: ^цифры;
права: boolean;
сорт: boolean;
сортп: boolean;
усвязь: ^связь;
уэл: ^элемент;
сссзп: ссылка;
позиц: integer;
позицр: integer;
стрсохр: boolean;
кодст: integer;
колво: integer;
колво2: integer;
времязп: integer;
адрзоны: integer;
элем: элемент;
заново: boolean;
печать: boolean;
экран: boolean;
вывод: boolean;
смотр: boolean;
естьимя: boolean;
имягост: имя;
сбой: boolean;
итог: boolean;
натерм: boolean;
блдлин: boolean;
слэш: boolean;
естьуст: boolean;
былпеч: boolean;
тзона: integer;
слзона: integer;
нкв: integer;
нэл: integer;
узона: ^зона;
маска: тмаска;
маска2: тмаска;
копия: тмаска;
ФАЙЛ: text;
ширстр: integer;
максшир: integer;
частота: integer;
STR: text;
приказ: alfa;
парам2: alfa;
парам: alfa; неравно: флаги;
ключадм: integer;
кончить: boolean;
былдруг: boolean;
скип: char;
новскип: char;
п523: array [1..1] of integer;
нк: integer;
поз: integer;
ндруг: integer;
файлов: integer;
тдлина: integer;
зон: integer;
использ: integer;
обращ: integer;
шаг: integer;
строк: integer;
задан, задан2, задан3, неравно2, неравно3: флаги;
глуб: integer;
вершина: integer;
показано: integer;
взоне: integer;
структ: boolean;
стек, путь: тстек;
колонки, к2: тколонки;
годен: boolean;
конкат: boolean;
и1: integer;
и2: integer;
и3: integer;
и4: integer;
п1066: array [1..1] of integer;
и5: integer;
список: ^узел;
тек: ^узел;
пред: ^узел;
новый: ^узел;
кл: integer;
место: boolean;
уэл2: ^элемент;
БУФ: зоны; СЛОВО: integer;
ГОСТИСО, ИСОГОСТ: packed array ['_000'..'_203'] of char;
procedure ТПЕЧ(var с: стр; var р: real); fortran;
procedure ТВЫВ(var с: стр); fortran;
procedure ТВВОД(var о: тответ; п: integer); fortran;
procedure ТЕРМ; fortran;
procedure ТПРО; fortran;
procedure ТПАР(var п: integer); fortran;
procedure ПЕРЕКОД; external;
function разд(c: char): boolean;
begin (*169*)
  разд := (c = ' ') or (c = ',') or (c = '=') or (c = '/') end;
function xor(b: boolean): boolean;
begin (*172*)
  xor := not неравно[нк] and b or неравно[нк] and not b end;
function чет(n: integer): boolean;
begin (*175*)
  чет := n mod 2 = 0 end;
function шир(n: integer): integer;
begin (*178*)
  case n of
    1: if not структ then шир := 12
    else шир := 18;
    13: шир := 13;
    14: шир := 10;
    7, 8, 9, 10: шир := 11;
    2, 5, 6, 18, 21: шир := 9;
    4, 15, 16, 19, 20: шир := 8;
    11, 22, 24: шир := 7;
    12: шир := 4;
    3: шир := 5;
    others: шир := 0
  end
end;
%
%
procedure пробел;
begin (*196*)
  write(ФАЙЛ, ' ') end;
procedure пропуск(var f: text);
begin (*199*)
  if not eof(f) then get(f)
end;
%
%
%
function пусто(r: ссылка): boolean;
begin (*206*)
  пусто := (r.зона = 0) and (r.квант = 0) end;
procedure втолкни(var r: имя);
begin (*209*)
  вершина := вершина + 1; стек[вершина] := r end;
procedure вытолкни;
begin (*212*)
  вершина := вершина - 1;
  if вершина < показано then показано := вершина
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
(*=m-*)procedure найди(ключ: integer; var а: зоны; var n: integer;
    var адр: integer; var нов: boolean);
var м: integer;
  function и(a, b: integer): integer;
  begin (*229*)
    besm(14100004B);
    besm(14110005B);
    и := ;
  end;
%
%
  function или(a, b: integer): integer;
  begin (*237*)
    besm(14100004B);
    besm(14150005B);
    или := ;
  end;
%
%
  procedure чит(л, з: integer);
  begin (*245*)
    з := л * 4096 + и(з, 7777C) + 10320000000000C;
    besm(14700004B)
  end;
%
%
%
%
  procedure пиши(л, з: integer);
  begin (*254*)
    з := л * 4096 + 320000000000C + и(з, 7777C);
    besm(14700004B)
  end;
%
%
%
%
  procedure откр(з: integer);
  var к: integer;
  begin (*264*)
    з := или(6500320000000000C, и(з, 177777C));
    к := 1242547515620060C;
    besm(100000B);
    besm(120000B);
    besm(14100004B);
    besm(14630003B)
  end;
%
%
%
%
%
%
  procedure вставь(var а: зоны; к: integer; var n, м: integer);
  var x: integer;
  begin (*280*)
    x := к * 4096 + n;
    м := n;
    if м <> 0 then
      while а[м - 1] > x do begin
        а[м] := а[м - 1];
        м := м - 1
      end;
    а[м] := x;
    n := n + 1
  end;
%
%
  procedure поиск(var а: зоны; n, к: integer; var м: integer);
  var л, п, x: integer;
  begin (*295*)
    (q) begin
      л := 0;
      п := n - 1;
      x := 0;
      while л <= п do begin
        м := (л + п) div 2;
        x := а[м] div 4096;
        if x = к then exit q;
        if к < x then п := м - 1
        else л := м + 1
      end;
      if x <> к then м := -1
    end
  end;
%
begin (*311*)
  адр := 26624;
  if нов then begin нов := false; n := 0 end;
  поиск(а, n, ключ, м);
  if м >= 0 then чит(36C, а[м])
  else begin
    откр(ключ);
    вставь(а, ключ, n, м);
    пиши(36C, а[м])
  end
end;
%
%
(*=m+*)
procedure перевод;
var i: integer; с: стр; р: real; о: тответ;
begin (*327*)
  reset(ФАЙЛ);
  i := 1;
  while not eof(ФАЙЛ) do begin
    с[i] := ИСОГОСТ[ФАЙЛ^];
    пропуск(ФАЙЛ);
    i := i + 1
  end;
  с[i] := '_172';
  rewrite(ФАЙЛ);
  if вывод then begin
    if (экран or итог) and натерм then begin
      ТПЕЧ(с, р);
      строк := строк + 1;
      if р = 4020000000000000C then вывод := false
    end;
    if печать then ТВЫВ(с)
  end;
  if строк = шаг then begin
    ТВВОД(о, 1202206212005777C);
    if о[1] = '-' then конкат := true;
    строк := 0
  end
end;
%
%
procedure зону(з: integer);
var адр: integer;
begin (*355*)
  if взоне <> з then begin
    взоне := з;
    найди(взоне, БУФ, СЛОВО, адр, новкэш)
  end
end;
%
procedure зонуссылки(r: ссылка);
begin (*363*)
  зону(r.зона) end;
procedure след(var э: элемент; var конец: boolean);
var адр: integer;
begin (*367*)
  конец := false;
  if тзона <> взоне then begin
    взоне := тзона;
    найди(тзона, БУФ, СЛОВО, адр, новкэш)
  end;
  if нэл = 2 then
    repeat
      нэл := 0;
      if нкв = 24 then begin
        if 0 < слзона then begin
          нкв := 0;
          найди(слзона, БУФ, СЛОВО, адр, новкэш);
          взоне := слзона;
          тзона := слзона;
          узона := ptr(адр);
          слзона := узона^.з0.след
        end
        else конец := true
      end
      else нкв := нкв + 1
    until (узона^.к[нкв].связи.отец = 0) or смотр
  else нэл := нэл + 1;
  э := узона^.к[нкв].э[нэл]
end;
%
%
%
%
%
procedure гостиз(var a, b: имя);
var i: integer;
begin (*399*)
  for i to 9 do
    if a[i] > '_177' then b[i] := '_077'
    else b[i] := ГОСТИСО[a[i]]
end;
%
%
procedure цифра(n: integer);
begin (*407*)
  if (n < 0) or (9 < n) then write(ФАЙЛ, '^')
  else write(ФАЙЛ, n:1)
end;
%
%
function ненуль(ц: цифры): boolean;
var i: integer; б: boolean;
begin (*415*)
  б := false; for i to 6 do б := б or (ц[i] > 0);
  ненуль := б
end;
procedure пишцифру(d: integer);
begin (*420*)
  if d = 14 then write(ФАЙЛ, '.')
  else цифра(d)
end;
%
procedure пишшифр(ц: цифры);
var i: integer;
begin (*427*)
  if ненуль(ц) then
    for i := 1 to 6 do
      if (ц[i] >= 0) and (ц[i] <= 9) then write(ФАЙЛ, ц[i]:1)
      else if ц[i] = 14 then write(ФАЙЛ, '.')
      else write(ФАЙЛ, '^')
  else write(ФАЙЛ, 'НЕТУ  ')
end;
%
%
%
%
%
%
procedure пишдату(д: дата);
var к: integer;
begin (*443*)
  if (д.б = 0) and (д.а = 0) and (д.г = 0) and (д.в = 0) and
    (д.д = 0) then
    write(ФАЙЛ, '   НЕТ  ')
  else begin
    цифра(д.а);
    цифра(д.б);
    write(ФАЙЛ, '.');
    цифра(д.в);
    цифра(д.г);
    write(ФАЙЛ, '.8');
    цифра(д.д) end
end;
procedure метка(p: integer);
begin (*457*)
  неравно[p] := STR^ = '<';
  if неравно[p] then пропуск(STR);
  пропуск(STR);
  задан[p] := (STR^ <> ' ') and (STR^ <> ',') and not eof(STR)
end;
%
procedure читслово(var s: alfa);
var i: integer;
begin (*466*)
  i := 1;
  s := '      ';
  while разд(STR^) and not eof(STR) do get(STR);
  while (STR^ <> '=') and (STR^ <> ' ') and (STR^ <> ',') and
    (STR^ <> '<') and not eof(STR) and (STR^ <> '/') do begin
    if i <= 3 then s[i] := STR^
    else if i <= 6 then s[i] := ' ';
    if not eof(STR) then пропуск(STR);
    i := i + 1
  end;
  слэш := STR^ = '/';
  while (STR^ <= ' ') and not eof(STR) do пропуск(STR)
end;
%
%
procedure естьнет(b: boolean);
begin (*483*)
  if b then write(ФАЙЛ, 'ЕСТЬ')
  else write(ФАЙЛ, 'НЕТ');
  перевод
end;
%
procedure есть(n: integer);
begin (*490*)
  if n = 0 then write(ФАЙЛ, '*  НЕТ  ')
  else write(ФАЙЛ, '* ЕСТЬ  ')
end;
%
procedure задай(p: integer; var b: boolean);
var s: alfa;
begin (*497*)
  метка(p);
  if задан[p] then begin
    читслово(s);
    if s = 'ЕСТ   ' then b := true
    else if s = 'НЕТ   ' then b := false
    else begin
      задан[p] := false;
      write(ФАЙЛ, ' НЕТ ЗНАЧ');
      перевод;
      exit
    end
  end
end;
function совп(a: integer; b: boolean): boolean;
begin (*512*)
  if b then совп := a <> 0
  else совп := a = 0;
end;
%
%
procedure вводстроки;
var а: тбуф; i, j, k: integer; о: тответ;
begin (*520*)
  ТВВОД(о, 521243603777417C);
  i := 0;
  rewrite(STR);
  j := 1;
  вывод := true;
  строк := 0;
  if о[1] = '_025' then j := 5;
  while о[j] <= '_177' do begin
    if i < 82 then i := i + 1;
    а[i] := ГОСТИСО[о[j]];
    if j < 82 then j := j + 1
  end;
  if печать then begin
    натерм := false;
    write(ФАЙЛ, '==> ');
    for j to i do write(ФАЙЛ, а[j]);
    перевод;
    натерм := true
  end;
  for j to i do
    if а[j] >= ' ' then begin STR^ := а[j]; put(STR) end;
  reset(STR);
  вывод := true
end;
%
procedure переключ(var b: boolean);
begin (*547*)
  if STR^ = 'Д' then b := true
  else if STR^ = 'Н' then b := false
  else begin b := not b; exit end
end;
%
%
procedure списокимен(var с: тимена; var есть: boolean; var n: integer);
var конец, все: boolean; k, l: integer;
  procedure читимя(var s: имя);
  var i: integer; б: boolean;
  begin (*558*)
    б := true;
    for i to 9 do
      if б then begin
        if (STR^ <> ',') and (STR^ <> '.') and (STR^ <> ' ') and not
          eof(STR) then begin
          s[i] := STR^;
          пропуск(STR)
        end
        else begin
          б := false;
          s[i] := ' '
        end
      end
      else s[i] := ' '
  end;
begin (*574*)
  конец := false;
  k := 1;
  есть := false;
  while not конец and (k <= 7) do begin
    if STR^ = '*' then begin
      с[k][1] := '*';
      repeat
        пропуск(STR)
      until (STR^ = '.') or разд(STR^) or eof(STR)
    end
    else читимя(с[k]);
    if (STR^ <> '.') or eof(STR) then begin
      конец := true;
      for l := k + 1 to 7 do с[l] := '         ';
      все := true;
      есть := 1 < k end
    else begin
      пропуск(STR);
      if разд(STR^) or eof(STR) then begin
        конец := true;
        все := false;
        for l := k + 1 to 7 do с[l][1] := '*';
        есть := true
      end
      else есть := true
    end;
    k := k + 1
  end;
  n := k - 1
end;
procedure пишзнак;
begin (*606*)
  if неравно[нк] then write(ФАЙЛ, '<>')
  else write(ФАЙЛ, '=')
end;
%
procedure число(var f: text; var n: integer; осн: integer);
begin (*612*)
  n := 0;
  while (STR^ >= '0') and ('9' >= STR^) and not eof(STR) do begin
    n := n * осн + ord(STR^) - 48; пропуск(STR) end
end;
procedure числоб(var f: text; var n: integer; в: integer);
begin (*618*)
  if в = 0 then число(f, n, 10)
  else число(f, n, 8)
end;
%
procedure задайч(p: integer; var n, m: integer; в: integer);
begin (*624*)
  метка(p);
  if задан[p] then begin
    числоб(STR, n, в);
    if (STR^ = '-') and not eof(STR) then begin
      пропуск(STR);
      числоб(STR, m, в)
    end
    else m := n
  end
end;
procedure обнули(var ц: цифры);
var i: integer;
begin (*637*)
  for i to 6 do ц[i] := 0
end;
procedure задайшифр(p: integer; var ц: цифры);
  procedure читшифр(var ц: цифры);
  var i: integer; б: boolean;
  begin (*643*)
    б := true;
    for i to 6 do
      if б then begin
        if STR^ = '.' then begin
          ц[i] := 14;
          пропуск(STR)
        end
        else if (STR^ >= '0') and ('9' >= STR^) then begin
          ц[i] := ord(STR^) - 48;
          if not eof(STR) then пропуск(STR)
        end
        else begin
          ц[i] := 14;
          б := false
        end
      end
      else ц[i] := 14
  end;
%
%
%
begin (*665*)
  метка(p);
  if задан[p] then читшифр(ц);
  if STR^ = 'Н' then begin
    обнули(ц);
    while not разд(STR^) and not eof(STR) do get(STR)
  end
end;
%
%
function цифрв(c: char; осн: integer): integer;
begin (*676*)
  цифрв := (ord(c) - 48) mod (осн + 1) end;
procedure читдату(var д: дата);
begin (*679*)
  with д do begin
    а := цифрв(STR^, 3); пропуск(STR);
    б := цифрв(STR^, 9);
    пропуск(STR); пропуск(STR);
    в := цифрв(STR^, 2); пропуск(STR);
    г := цифрв(STR^, 9);
    пропуск(STR); пропуск(STR);
    пропуск(STR); д := цифрв(STR^, 9);
    пропуск(STR) end
end;
procedure задайдату(p: integer; var д1, д2: дата);
begin (*691*)
  метка(p);
  if задан[p] then begin
    читдату(д1);
    if (STR^ = '-') and not eof(STR) then begin
      пропуск(STR);
      читдату(д2)
    end
    else д2 := д1
  end
end;
procedure пишдиап(a, b, ос: integer);
begin (*703*)
  if ос = 0 then begin
    write(ФАЙЛ, a:0);
    if a <> b then write(ФАЙЛ, '-', b:0)
  end
  else begin
    write(ФАЙЛ, a:4 oct);
    if a <> b then write(ФАЙЛ, '-', b:4 oct)
  end;
  перевод
end;
%
%
procedure пишдаты(д1, д2: дата);
begin (*717*)
  пишдату(д1);
  if д1 <> д2 then begin write(ФАЙЛ, '-'); пишдату(д2) end;
  перевод
end;
%
function совпимя(a, b: имя): boolean;
var i: integer; б: boolean;
begin (*725*)
  i := 1;
  б := true;
  if b[1] = '*' then совпимя := true
  else begin
    while б and (9 >= i) do begin
      if b[i] = скип then
      else if a[i] <> b[i] then б := false
      else;
      i := i + 1
    end;
    совпимя := б
  end
end;
function наш(с: тимена; все: boolean; n: integer): boolean;
var б: boolean; i: integer;
begin (*741*)
  if not все then наш := совпимя(стек[глуб], с[1])
  else begin
    if глуб < n then б := false
    else begin
      б := true;
      for i to глуб do б := б and совпимя(стек[i], с[i])
    end;
    наш := б
  end
end;
%
%
%
%
function совпшифр(ц1, ц2: цифры): boolean;
var i: integer; б: boolean;
begin (*758*)
  i := 1;
  б := true;
  while б and (6 >= i) do begin
    if ц2[i] = 14 then
    else if ц2[i] <> ц1[i] then б := false
    else;
    i := i + 1
  end;
  совпшифр := б
end;
function до(д1, д2: дата): boolean;
var б: boolean; к: integer;
begin (*771*)
  к := 0;
  (q) if д1.д <> д2.д then б := д1.д <= д2.д
  else if д1.в <> д2.в then б := д1.в <= д2.в
  else if д1.г <> д2.г then б := д1.г <= д2.г
  else if д1.а <> д2.а then б := д1.а <= д2.а
  else if д1.б <> д2.б then б := д1.б <= д2.б
  else begin б := true; exit q end;
  до := б
end;
%
function вдиап(д1, д, д2: дата): boolean;
begin (*783*)
  вдиап := до(д1, д) and до(д, д2)
end;
procedure звезда;
begin (*787*)
  write(ФАЙЛ, '* ') end;
procedure пишвид(n: вид);
begin (*790*)
  case n of
    0: write(ФАЙЛ, 'НЕТ');
    1: write(ФАЙЛ, ' ЧТ');
    2: write(ФАЙЛ, 'Ч/З');
    3: write(ФАЙЛ, 'ЗАХ')
  end
end;
procedure добавь(n: integer);
begin (*799*)
  колонки[нк] := n;
  if n = 1 then естьимя := true;
  if (0 < n) and (0 < нк) and (нк < 26) then ширстр := шир(n) + ширстр;
end;
%
%
procedure колонка(n: integer);
begin (*807*)
  if (1 < нк) and сорт and (n = колонки[1]) then
  else begin
    добавь(n);
    if not заново then begin нк := 0; заново := true; ширстр := 0 end;
    нк := нк + 1
  end;
  if (n in [5, 11, 21..23]) and not права and not сбой then begin
    write(ФАЙЛ, ' НЕ ИМЕЕТЕ ПРАВА');
    перевод;
    сбой := true
  end
end;
%
%
procedure пишшифры(ш: шифры; в: виды);
var i, j: integer;
begin (*824*)
  if ндруг < 6 then for i := ндруг + 1 to 6 do
      if ненуль(ш[i]) then begin
        и1 := 1;
        while колонки[и1] <> 13 do begin
          write(ФАЙЛ, '*');
          for j to шир(колонки[и1]) - 1 do пробел;
          и1 := и1 + 1
        end;
        звезда;
        пишшифр(ш[i]);
        write(ФАЙЛ, ' *');
        пишвид(в[i]);
        и1 := и1 + 1;
        while 0 < колонки[и1] do begin
          write(ФАЙЛ, '*');
          for j to шир(колонки[и1]) - 1 do пробел;
          и1 := и1 + 1
        end;
        write(ФАЙЛ, '*');
        перевод end
end;
procedure пишдн(s: alfa; b: boolean);
begin (*847*)
  write(ФАЙЛ, s);
  if b then write(ФАЙЛ, ' ДА')
  else write(ФАЙЛ, ' НЕТ');
  перевод
end;
procedure пишимена(с: тимена);
var j, i: integer; б: boolean;
begin (*855*)
  i := 7;
  б := true;
  while (0 < i) and ((с[i][1] = ' ') or (с[i][1] = '*') and б) do begin
    б := с[i][1] <> ' ';
    i := i - 1
  end;
  for j to i do begin
    if с[j][1] = '*' then write(ФАЙЛ, ' * ')
    else write(ФАЙЛ, с[j]);
    if j < i then write(ФАЙЛ, '.')
  end;
  if с[7][1] = '*' then write(ФАЙЛ, '.')
end;
%
procedure читвремя(var t: integer);
var ч, м, с: integer;
begin (*872*)
  м := 0; с := 0;
  числоб(STR, ч, 0);
  if (STR^ = '.') or (STR^ = ':') then begin
    пропуск(STR);
    числоб(STR, м, 0);
    if (STR^ = '.') or (STR^ = ':') then begin
      пропуск(STR);
      числоб(STR, с, 0) end
  end;
  t := (ч * 3600 + м * 60 + с) * 100
end;
procedure дв(n: integer);
begin (*885*)
  write(ФАЙЛ, n div 10:1, n mod 10:1) end;
procedure пишвремя(t: integer);
var м, с, ч: integer;
begin (*889*)
  м := t div 100; с := м mod 60; м := м div 60;
  ч := м mod 60; м := м div 60; дв(м);
  write(ФАЙЛ, ':'); дв(ч)
end;
procedure читтип(var а, б: integer);
  procedure ошибка;
  begin (*896*)
    if not сбой then write(ФАЙЛ, ' НЕВЕРНОЕ ЗНАЧЕНИЕ ТИПА');
    перевод; сбой := true
  end;
begin (*900*)
  if STR^ = скип then а := 14
  else begin
    а := ord(STR^) - 48;
    if not (а in [0..3]) then ошибка
  end;
  if разд(STR^) or eof(STR) then ошибка
  else begin
    пропуск(STR);
    if STR^ = скип then б := 14
    else begin
      б := ord(STR^) - 48;
      if not (б in [0..4]) then ошибка
    end
  end;
  пропуск(STR)
end;
%
%
%
%
%
function видсовп(x, а, б: integer): boolean;
var к, л: integer;
begin (*924*) к := x div 8; л := x mod 8;
  видсовп := ((а = 14) or (а = к)) and ((б = 14) or (б = л))
end;
procedure пишмаску;
begin (*928*)
  if скип <> '.' then begin write(ФАЙЛ, ' СКИП=', скип); перевод end;
  for нк to 25 do if задан[нк] and (нк <> 25) then case нк of
        1: begin
          write(ФАЙЛ, ' ИМЯ'); пишзнак;
          пишимена(маска.имена); перевод
        end;
        2: begin
          write(ФАЙЛ, ' ХОЗ'); пишзнак;
          пишшифр(маска.хоз); перевод
        end;
        3: begin
          write(ФАЙЛ, ' ТИП');
          пишзнак; пишцифру(маска.т1);
          пишцифру(маска.т2); перевод
        end;
        4: begin
          write(ФАЙЛ, ' ДЛИНА'); пишзнак;
          пишдиап(маска.дл1, маска.дл2, 1)
        end;
        5: begin
          write(ФАЙЛ, ' ЗОНА'); пишзнак;
          пишдиап(маска.з1, маска.з2, 1)
        end;
        6: begin
          write(ФАЙЛ, ' ШИФР Б'); пишзнак;
          пишшифр(маска.шб); перевод
        end;
        7: begin
          write(ФАЙЛ, ' ДАТА СОЗ');
          пишзнак;
          пишдаты(маска.дс1, маска.дс2)
        end;
        8: begin
          write(ФАЙЛ, ' ДАТА ЗАП');
          пишзнак;
          пишдаты(маска.дз1, маска.дз2)
        end;
        9: begin
          write(ФАЙЛ, ' ДАТА ЧТЕ');
          пишзнак;
          пишдаты(маска.дч1, маска.дч2)
        end;
        10: begin
          write(ФАЙЛ, ' КОЛ ОБР');
          пишзнак;
          пишдиап(маска.к1, маска.к2, 0)
        end;
        11: begin
          write(ФАЙЛ, ' БОБИНА');
          пишзнак;
          пишдиап(маска.б1, маска.б2, 0)
        end;
        24: begin
          write(ФАЙЛ, ' БОБИНА ВЫТ');
          пишзнак;
          пишдиап(маска.бв1, маска.бв2, 0)
        end;
        13: begin
          write(ФАЙЛ, ' ДРУГ'); пишзнак;
          пишшифр(маска.друг); перевод
        end;
        14: begin
          write(ФАЙЛ, ' ЧАСТОТА');
          пишзнак;
          пишдиап(маска.ч1, маска.ч2, 0)
        end;
        18: begin
          write(ФАЙЛ, ' ШИФР ЗАП');
          пишзнак;
          пишшифр(маска.шзп); перевод
        end;
        19: begin
          write(ФАЙЛ, ' ВРЕМЯ ЗАП');
          пишзнак; пишвремя(маска.в1);
          if маска.в2 <> маска.в1 then begin
            write(ФАЙЛ, '-');
            пишвремя(маска.в2)
          end;
          перевод
        end;
        20: begin
          write(ФАЙЛ, ' ТЕК ДЛИНА');
          пишзнак;
          пишдиап(маска.тд1, маска.тд2, 1)
        end;
        21: begin
          write(ФАЙЛ, ' ЗОНА КАТ');
          пишзнак;
          пишдиап(маска.зк1, маска.зк2, 1)
        end;
        22: begin
          write(ФАЙЛ, ' ГДЕ'); пишзнак;
          пишдиап(маска.где1, маска.где2, 1)
        end;
        17: begin
          write(ФАЙЛ, ' СТРУКТУР');
          пишзнак; естьнет(маска.стр)
        end;
        15: begin
          write(ФАЙЛ, ' ПАР ЧТ');
          пишзнак; естьнет(маска.пч)
        end;
        16: begin write(ФАЙЛ, ' ПАР ЗП'); пишзнак; естьнет(маска.пз) end
      end
end;
procedure команды;
var j: integer;
  procedure нельзя;
  begin (*1037*)
    if not права and not сбой then begin
      write(ФАЙЛ, ' НЕ ИМЕЕТЕ ПРАВА');
      перевод;
      сбой := true
    end
  end;
begin (*1044*)
  копия := маска;
  задан3 := задан;
  неравно3 := неравно;
  while not eof(STR) do begin
    читслово(парам2);
    if парам2 = 'СКИ   ' then begin
      метка(25);
      if not задан[25] then новскип := '.'
      else begin
        if разд(STR^) then begin
          write(ФАЙЛ, ' НЕВ. СКИП');
          сбой := true;
          перевод
        end
        else begin
          новскип := STR^;
          for и1 to 7 do
            for j to 9 do
              if маска.имена[и1][j] = скип then
                маска.имена[и1][j] := STR^;
          скип := новскип
        end;
        пропуск(STR)
      end
    end
    else if парам2 = 'ПОК   ' then пишмаску
    else if парам2 = 'ПЧТ   ' then задай(15, маска.пч)
    else if парам2 = 'ПЗП   ' then задай(16, маска.пз)
    else if парам2 = 'ШЗП   ' then задайшифр(18, маска.шзп)
    else if парам2 = 'ВЗП   ' then begin
      метка(19);
      if задан[19] then begin
        читвремя(маска.в1);
        if STR^ = '-' then begin пропуск(STR); читвремя(маска.в2) end
        else маска.в2 := маска.в1
      end
    end
    else if парам2 = 'ДРУ   ' then задайшифр(13, маска.друг)
    else if парам2 = 'СТР   ' then задай(17, маска.стр)
    else if парам2 = 'БОБ   ' then begin
      задайч(11, маска.б1, маска.б2, 0);
      нельзя
    end
    else if парам2 = 'БВТ   ' then begin
      задайч(24, маска.бв1, маска.бв2, 0);
      нельзя
    end
    else if парам2 = 'ТИП   ' then begin
      метка(3);
      if задан[3] then читтип(маска.т1, маска.т2)
    end
    else if парам2 = 'ДЛИ   ' then задайч(4, маска.дл1, маска.дл2, 1)
    else if парам2 = 'ТДЛ   ' then задайч(20, маска.тд1, маска.тд2, 1)
    else if парам2 = 'ЗКТ   ' then begin
      задайч(21, маска.зк1, маска.зк2, 1);
      нельзя
    end
    else if парам2 = 'ГДЕ   ' then begin
      задайч(22, маска.где1, маска.где2, 1);
      нельзя
    end
    else if парам2 = 'ЗОН   ' then begin
      задайч(5, маска.з1, маска.з2, 1);
      нельзя
    end
    else if парам2 = 'ИМЯ   ' then begin
      метка(1);
      if задан[1] then списокимен(маска.имена, маска.есть, маска.ним)
    end
    else if парам2 = 'ХОЗ   ' then задайшифр(2, маска.хоз)
    else if парам2 = 'ШФБ   ' then задайшифр(6, маска.шб)
    else if парам2 = 'ДСО   ' then задайдату(7, маска.дс1, маска.дс2)
    else if парам2 = 'ДЗП   ' then задайдату(8, маска.дз1, маска.дз2)
    else if парам2 = 'ДЧТ   ' then задайдату(9, маска.дч1, маска.дч2)
    else if парам2 = 'КОЛ   ' then задайч(10, маска.к1, маска.к2, 0)
    else if парам2 = 'ЧАС   ' then задайч(14, маска.ч1, маска.ч2, 0)
    else if парам2 = 'СБР   ' then for j to 25 do задан[j] := false
    else (q) begin
      write(ФАЙЛ, ' НЕТ УСТАН ', парам2);
      сбой := true;
      while (STR^ <> ' ') and (STR^ <> ',') and not eof(STR) do
        пропуск(STR);
      перевод;
      exit q
    end;
    while not eof(STR) and (разд(STR^) or (STR^ = '.') or
      (STR^ = скип)) do
      пропуск(STR)
  end;
  if сбой then begin
    задан := задан3;
    неравно := неравно3;
    маска := копия
  end
end;
%
%
procedure фильтр(э: элемент; б4, б5: boolean);
var ук2: ^элемент; сс: ссылка; ук: ^ссылка; i, к, x: integer;
  procedure пв(в: виды; n: integer);
  begin (*1145*)
    пишвид(в[n]) end;
  function числш(ц: цифры): integer;
  var r, i: integer;
  begin (*1149*)
    r := 0; for i to 6 do r := r * 15 + ц[i];
    числш := r
  end;
  function числд(д: дата): integer;
  begin (*1154*)
    числд := д.д * 372 + (д.в * 10 + д.г) * 31 + д.а * 10 + д.б
  end;
%
  function ключ(э: элемент; n: integer): integer;
  var i, t, r: integer;
  begin (*1160*)
    r := 0;
    case n of
      1: for i to 4 do begin
        t := ord(э.им[i]);
        r := r * 256 + t
      end;
      2: r := числш(э.хоз);
      3: r := э.тп;
      4: r := э.длина;
      5: r := э.зона;
      6: r := числш(э.шб);
      7: r := числд(э.дс);
      8: r := числд(э.дз);
      9: r := числд(э.дч);
      10: r := э.кол;
      11: r := э.боб;
      12: r := э.вд;
      14: r := частота;
      18: r := числш(шифрзп);
      19: r := времязп;
      20: r := тдлина;
      23: r := э.боб * 65537 + э.зона;
      others: r := 0
    end;
    ключ := r
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
begin (*1196*)
  ук := ptr(ord(ref(э)) + 1);
  сс := ук^;
  if б4 then
    if глуб = 0 then позиц := 40 * нкв + 24 + 13 * нэл
    else позиц := позицр;
  if (э.им[1] <> '_000') and not конкат then begin
    гостиз(э.им, имягост);
    годен := true;
    нк := 1;
    глуб := глуб + 1;
    втолкни(имягост);
    if э.длина > 0 then частота := э.кол div э.длина
    else частота := 0;
    if э.кол = 0 then тдлина := 0
    else тдлина := э.тд + 1;
    сссзп.л := э.ссыл;
    ушифр := ref(сссзп);
    шифрзп := ушифр^;
    времязп := ord(chr(э.время)) * 32768;
    if б4 then
      while годен and (24 >= нк) do begin
        if задан[нк] then
          case нк of
            1: годен := xor(наш(маска.имена, маска.есть, маска.ним));
            2: годен := xor(совпшифр(э.хоз, маска.хоз));
            3: годен := xor(видсовп(э.тп, маска.т1, маска.т2));
            4: годен := xor((э.длина >= маска.дл1) and
              (э.длина <= маска.дл2));
            5: годен := xor((э.зона >= маска.з1) and
              (э.зона <= маска.з2)) and (э.флаг mod 2 = 0);
            6: годен := xor(совпшифр(э.шб, маска.шб));
            7: годен := xor(вдиап(маска.дс1, э.дс, маска.дс2));
            8: годен := xor(вдиап(маска.дз1, э.дз, маска.дз2));
            9: годен := xor(вдиап(маска.дч1, э.дч, маска.дч2));
            10: годен := xor((э.кол >= маска.к1) and
              (э.кол <= маска.к2));
            11: годен := xor((э.боб >= маска.б1) and
              (э.боб <= маска.б2)) and пусто(сс);
            13: if not ненуль(маска.друг) then begin
              годен := true;
              i := 1;
              while годен and (6 >= i) do begin
                годен := not ненуль(э.друзья[i]);
                i := i + 1
              end
            end
            else begin
              годен := false;
              i := 1;
              while not годен and (6 >= i) do begin
                годен := совпшифр(маска.друг, э.друзья[i]) or
                  совпшифр(э.друзья[i], маска.друг);
                i := i + 1
              end;
              годен := xor(годен)
            end;
            14: годен := xor((частота >= маска.ч1) and
              (маска.ч2 >= частота));
            15: годен := xor(совп(э.пч, маска.пч));
            16: годен := xor(совп(э.пз, маска.пз));
            17: годен := not xor(not пусто(сс) = маска.стр);
            18: годен := xor(совпшифр(шифрзп, маска.шзп)) and
              (э.ссыл <> 0);
            19: годен := xor((времязп >= маска.в1) and
              (маска.в2 >= времязп)) and (э.ссыл <> 0);
            20: годен := xor((тдлина >= маска.тд1) and
              (маска.тд2 >= тдлина));
            21: годен := xor((взоне >= маска.зк1) and
              (маска.зк2 >= взоне));
            22: годен := xor((позиц >= маска.где1) and
              (маска.где2 >= позиц));
            24: годен := xor((э.бв >= маска.бв1) and
              (э.бв <= маска.бв2)) and пусто(сс)
          end;
        нк := нк + 1
      end
    else годен := true;
    if годен then begin
      if сорт then begin
        кл := ключ(э, колонки[1]);
        тек := список;
        место := false;
        пред := список;
        (q) while (тек <> nil) and not место do begin
          место := кл < тек^.ключ;
          if место then exit q;
          пред := тек;
          тек := тек^.след
        end;
        new(новый);
        новый^.ключ := кл;
        новый^.зк := взоне;
        новый^.где := позиц;
        if (тек = список) or (список = nil) then begin
          новый^.след := список;
          список := новый
        end
        else begin
          новый^.след := тек;
          пред^.след := новый
        end
      end;
      if б5 and сортп and структ then begin
        вершина := 0;
        x := (позиц - 24) div 40;
        (q) for нк to 7 do begin
          усвязь := ptr(адрзоны + 24 + x * 40 + 39);
          if усвязь^.отец = 0 then exit q
          else begin
            зону(усвязь^.отец);
            x := усвязь^.кв;
            уэл := ptr(адрзоны + 24 + 40 * x + усвязь^.эл * 13);
            вершина := вершина + 1;
            гостиз(уэл^.им, путь[вершина])
          end
        end;
        if 0 < вершина then
          for и2 := вершина downto 1 do begin
            нк := 1;
            while (0 < колонки[нк]) and (нк < 25) do begin
              if колонки[нк] = 1 then begin
                звезда;
                и4 := вершина - и2;
                if 0 < и4 then begin
                  for и3 to и4 - 1 do пробел;
                  write(ФАЙЛ, '.')
                end;
                write(ФАЙЛ, путь[и2]);
                for и3 to 7 - и4 do пробел
              end
              else begin
                звезда;
                for и3 to шир(колонки[нк]) - 2 do пробел
              end;
              нк := нк + 1
            end;
            write(ФАЙЛ, '*');
            перевод
          end
      end;
      if б5 and not сортп then begin
        нк := 1;
        поз := 0;
        if глуб = 1 then показано := 1;
        if структ and (1 < глуб) and естьимя then begin
          if вершина - 1 > показано then
            for i := показано + 1 to вершина - 1 do begin
              и5 := 1;
              while (и5 < 25) and (колонки[и5] <> 0) do begin
                if колонки[и5] = 1 then begin
                  звезда;
                  if 1 < i then begin
                    for и2 to i - 2 do пробел;
                    write(ФАЙЛ, '.')
                  end;
                  write(ФАЙЛ, стек[i]);
                  for и2 to 7 - i + 1 do пробел
                end
                else begin
                  звезда;
                  for и2 to шир(колонки[и5]) - 2 do пробел
                end;
                и5 := и5 + 1
              end;
              write(ФАЙЛ, '*');
              перевод;
              показано := показано + 1
            end;
          показано := показано + 1
        end
      end;
      if б5 then begin
        нк := 1;
        былдруг := false;
        файлов := файлов + 1;
        зон := зон + э.длина;
        использ := использ + тдлина;
        обращ := обращ + э.кол;
        if сортп then глуб := вершина + 1;
        while (0 < колонки[нк]) and (нк < 25) do begin
          case колонки[нк] of
            1: if структ then begin
              звезда;
              if 1 < глуб then begin
                for i to глуб - 2 do пробел;
                write(ФАЙЛ, '.')
              end
              else for i to глуб - 1 do пробел;
              write(ФАЙЛ, имягост);
              for i to 7 - глуб + 1 do пробел
            end
            else begin
              write(ФАЙЛ, '* ', имягост, ' ');
              поз := поз + 12
            end;
            2: begin
              звезда;
              пишшифр(э.хоз);
              пробел;
              поз := поз + 9
            end;
            3: begin
              звезда;
              write(ФАЙЛ, э.тп:2 oct);
              пробел;
              поз := поз + 4
            end;
            4: begin
              звезда;
              if э.длина = 0 then write(ФАЙЛ, ' КАТ  ')
              else write(ФАЙЛ, э.длина:6 oct);
              поз := поз + 8
            end;
            5: begin
              звезда;
              if э.длина = 0 then write(ФАЙЛ, ' КАТ  ')
              else write(ФАЙЛ, э.зона:6 oct);
              if чет(э.флаг) then пробел
              else write(ФАЙЛ, 'П');
              поз := поз + 9
            end;
            6: begin
              звезда;
              пишшифр(э.шб);
              пробел;
              поз := поз + 9
            end;
            7: begin
              звезда;
              пишдату(э.дс);
              пробел;
              поз := поз + 11
            end;
            8: begin
              звезда;
              пишдату(э.дз);
              пробел;
              поз := поз + 11
            end;
            9: begin
              звезда;
              пишдату(э.дч);
              пробел;
              поз := поз + 11
            end;
            10: begin
              write(ФАЙЛ, '* ', э.кол:8, ' ');
              поз := поз + 9
            end;
            11: if э.длина = 0 then write(ФАЙЛ, '*      ')
            else write(ФАЙЛ, '* ', э.боб:4, ' ');
            12: begin
              write(ФАЙЛ, '*');
              пишвид(э.вд);
              поз := поз + 5
            end;
            13: if былдруг then write(ФАЙЛ, '* СМ. РАНЕЕ  ')
            else begin
              былдруг := true;
              к := 0;
              (q) for поз to 6 do begin
                ндруг := поз;
                if ненуль(э.друзья[поз]) then begin
                  звезда;
                  пишшифр(э.друзья[поз]);
                  write(ФАЙЛ, ' *');
                  пв(э.вв, поз);
                  exit q
                end;
                к := поз
              end;
              if к = 6 then write(ФАЙЛ, '*     НЕТ    ')
            end;
            14: begin
              write(ФАЙЛ, '* ', частота:7, ' ');
              поз := поз + 10
            end;
            15: begin
              есть(э.пч);
              поз := поз + 8
            end;
            16: begin
              есть(э.пз);
              поз := поз + 8
            end;
            18: begin
              звезда;
              if э.ссыл = 0 then write(ФАЙЛ, '      ')
              else пишшифр(шифрзп);
              пробел
            end;
            19: begin
              звезда;
              if э.ссыл = 0 then write(ФАЙЛ, '     ')
              else пишвремя(времязп);
              пробел
            end;
            20: if э.длина <> 0 then write(ФАЙЛ, '* ', тдлина:6 oct)
            else write(ФАЙЛ, '*       ');
            21: write(ФАЙЛ, '* ', взоне:6 oct, ' ');
            22: write(ФАЙЛ, '* ', позиц:4 oct, ' ');
            24: if not пусто(сс) then write(ФАЙЛ, '*      ')
            else write(ФАЙЛ, '* ', э.бв:4, ' ');
            others:
          end;
          нк := нк + 1
        end;
        write(ФАЙЛ, '*');
        перевод;
        if сортп then глуб := глуб - 1;
        if былдруг then пишшифры(э.друзья, э.вв)
      end
    end
  end;
  if б4 and not пусто(сс) and структ then
    repeat
      зонуссылки(сс);
      for i to 3 do begin
        позицр := сс.квант * 40 + (i - 1) * 13 + 24;
        ук2 := ptr(позицр + адрзоны);
        фильтр(ук2^, true, not сортп);
        зонуссылки(сс)
      end;
      ук := ptr(сс.квант * 40 + адрзоны + 63);
      сс := ук^
    until пусто(сс);
  if э.им[1] <> '_000' then begin
    вытолкни;
    глуб := глуб - 1
  end
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
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
begin (*1600*)
  адрзоны := 26624;
  заново := true;
  ТЕРМ;
  смотр := false;
  структ := true;
  шаг := 14;
  права := false;
  печать := true;
  экран := true;
  вывод := true;
  былпеч := false;
  итог := true;
  натерм := true;
  блдлин := true;
  скип := '.';
  ПЕРЕКОД;
  for нк to 25 do задан[нк] := false;
  кончить := false;
  write(ФАЙЛ, 'СТАТИСТИКА А Р Ф Ы **(* 06.12.88 *)**');
  перевод;
  перевод;
  печать := false;
  новкэш := true;
  ТПАР(ключадм);
  права := ключадм = 15658734;
  repeat
    сбой := false;
    слэш := false;
    вводстроки;
    читслово(приказ);
    естьуст := слэш;
    select
      (приказ = 'КОН   ') or (приказ = 'КНЦ   '): begin
        кончить := true;
        if not былпеч then begin
          кодст := 1000000C;
          besm(620044B)
        end
      end;
      приказ = 'АДМ   ': begin
        новкэш := true;
        ТПАР(ключадм);
        права := ключадм = 15658734
      end;
      приказ = 'СМО   ': begin
        переключ(смотр);
        пишдн(' СМОТР', смотр)
      end;
      приказ = 'СТР   ': begin
        переключ(структ);
        пишдн('СТРУКТ', структ)
      end;
      приказ = 'ПЕЧ   ': begin
        переключ(печать);
        if печать then begin
          былпеч := true;
          нк := 0C;
          besm(620076B)
        end;
        пишдн('ПЕЧАТЬ', печать)
      end;
      приказ = 'ЭКР   ': begin
        переключ(экран);
        пишдн(' ЭКРАН', экран)
      end;
      приказ = 'БЛД   ': begin
        переключ(блдлин);
        пишдн('БЛДЛИН', блдлин)
      end;
      приказ = 'ШАГ   ': begin
        if eof(STR) then begin
          write(ФАЙЛ, ' ШАГ=', шаг:0);
          перевод
        end
        else число(STR, шаг, 10)
      end;
      приказ = 'СБР   ': begin
        for нк to 25 do задан[нк] := false;
        write(ФАЙЛ, ' СДЕЛАНО');
        перевод
      end;
      приказ = 'ИНК   ': begin
        select
          STR^ = 'Н': begin
            нк := 0C;
            besm(620076B)
          end;
          true: begin
            кодст := 1000000C;
            besm(620044B)
          end
        end
      end;
      приказ = 'ПРО   ': ТПРО;
      приказ = 'АЦП   ': begin
        и1 := 0C;
        besm(620042B)
      end;
      приказ = 'УСТ   ': begin
        команды;
        if not сбой then begin
          write(ФАЙЛ, ' СДЕЛАНО');
          перевод
        end
      end;
      приказ = 'ПОК   ': пишмаску;
      (приказ = 'СТА   ') or (приказ = 'СТП   '): begin
        if заново then нк := 1
        else нк := колво;
        файлов := 0;
        зон := 0;
        использ := 0;
        обращ := 0;
        к2 := колонки;
        колво2 := колво;
        сорт := приказ = 'СТП   ';
        список := nil;
        сортп := сорт;
        тзона := 0;
        взоне := 0;
        слзона := 1;
        нкв := 24;
        нэл := 2;
        if заново then ширстр := 0;
        естьимя := false;
        while not eof(STR) and not естьуст and (нк < 25) do begin
          читслово(парам);
          естьуст := слэш or естьуст;
          select
            парам = 'СВО   ': begin
              if сорт then колонка(23)
              else begin
                write(ФАЙЛ, ' НЕТ ПАРАМ СВО   ');
                перевод;
                сбой := true
              end
            end;
            парам = 'ЗАП   ': заново := false;
            парам = 'СБР   ': begin
              нк := 1;
              заново := true;
              ширстр := 0
            end;
            парам = 'ИМЯ   ': колонка(1);
            парам = 'ХОЗ   ': колонка(2);
            парам = 'ТИП   ': колонка(3);
            парам = 'ДЛИ   ': колонка(4);
            парам = 'ЗОН   ': колонка(5);
            парам = 'ШФБ   ': колонка(6);
            парам = 'ДСО   ': колонка(7);
            парам = 'ДЗП   ': колонка(8);
            парам = 'ДЧТ   ': колонка(9);
            парам = 'КОЛ   ': колонка(10);
            парам = 'БОБ   ': колонка(11);
            парам = 'ПРО   ': колонка(12);
            парам = 'ДРУ   ': колонка(13);
            парам = 'ЧАС   ': колонка(14);
            парам = 'ПЧТ   ': колонка(15);
            парам = 'ПЗП   ': колонка(16);
            парам = 'ШЗП   ': колонка(18);
            парам = 'ВЗП   ': колонка(19);
            парам = 'ТДЛ   ': колонка(20);
            парам = 'ЗКТ   ': колонка(21);
            парам = 'ГДЕ   ': колонка(22);
            парам = 'БВТ   ': колонка(24);
            парам = 'СИС   ': begin
              колонка(1);
              колонка(2);
              колонка(3);
              колонка(11);
              колонка(5);
              колонка(4);
              колонка(21);
              колонка(22)
            end;
            парам = 'ВСЕ   ': begin
              if структ then и1 := 13
              else и1 := 14;
              for и2 to и1 do
                select
                  права: колонка(и2);
                  и2 = 3:;
                  и2 = 5: колонка(20);
                  и2 = 11: колонка(18);
                  true: колонка(и2)
                end
            end;
            (парам = 'ОДИ   ') or (парам = '111   '): begin
              колонка(1);
              колонка(2);
              колонка(4);
              колонка(20);
              колонка(7);
              колонка(8)
            end;
            true: begin
              write(ФАЙЛ, ' НЕТ ПАРАМ ', парам);
              сбой := true;
              перевод
            end
          end;
          while разд(STR^) and not eof(STR) do пропуск(STR);
          if нк = 25 then begin
            write(ФАЙЛ, ' МНОГО ПАРАМЕТРОВ.');
            перевод;
            сбой := true
          end
        end;
        if естьуст then begin
          маска2 := маска;
          задан2 := задан;
          неравно2 := неравно;
          if STR^ = '/' then пропуск(STR);
          команды
        end;
        if заново then
          if (нк = 1) and not сорт or сорт and (2 >= нк) then begin
            колонка(1);
            колонка(2);
            колонка(4);
            колонка(20);
            колонка(7);
            колонка(8)
          end;
        добавь(0);
        нк := 1;
        ширстр := ширстр + 1;
        if сорт then
          if колонки[1] in [13, 15, 16] then begin
            write(ФАЙЛ, ' НЕ ИМЕЕТ СМЫСЛА');
            перевод;
            сбой := true
          end
          else if колонки[1] in [21, 22] then begin
            write(ФАЙЛ, ' ВОСПОЛЬЗУЙТЕСЬ ПРИКАЗОМ "СТА"');
            перевод;
            сбой := true
          end;
        if экран then максшир := 79
        else максшир := 127;
        if (максшир < ширстр) and блдлин then begin
          write(ФАЙЛ, ' МНОГО ПАРАМ. ПРЕВЫШ.= ', ширстр - максшир:0,
            ' ПОЗ.');
          перевод;
          сбой := true
        end;
        if сбой then begin
          колонки := к2;
          колво := колво2
        end
        else begin
          итог := false;
          while (0 < колонки[нк]) and (нк < 25) do begin
            case колонки[нк] of
              1: begin
                write(ФАЙЛ, '* ИМЯ ФАЙЛА ');
                if структ then for и1 to 6 do пробел
              end;
              2: write(ФАЙЛ, '* ХОЗЯИН ');
              3: write(ФАЙЛ, '* ТИП');
              4: write(ФАЙЛ, '* ДЛИНА ');
              5: write(ФАЙЛ, '*  ЗОНА  ');
              6: write(ФАЙЛ, '* ШИФР Б ');
              7: write(ФАЙЛ, '* ДАТА СОЗ ');
              8: write(ФАЙЛ, '* ДАТА ЗАП ');
              9: write(ФАЙЛ, '* ДАТА ЧТЕ ');
              10: write(ФАЙЛ, '* КОЛИЧ ОБР');
              11: write(ФАЙЛ, '*БОБИНА');
              12: write(ФАЙЛ, '*ПРО');
              13: write(ФАЙЛ, '* ДРУЗЬЯ *ПРА');
              14: write(ФАЙЛ, '* ЧАСТОТА ');
              15: write(ФАЙЛ, '* ПАРЧТ ');
              16: write(ФАЙЛ, '* ПАРЗП ');
              18: write(ФАЙЛ, '* ШИФ ЗП ');
              19: write(ФАЙЛ, '* ВР ЗП ');
              20: write(ФАЙЛ, '*ТЕКДЛИН');
              21: write(ФАЙЛ, '*ЗОНА КАТ');
              22: write(ФАЙЛ, '*  ГДЕ ');
              24: write(ФАЙЛ, '*БОБВЫТ');
              others:
            end;
            нк := нк + 1
          end;
          write(ФАЙЛ, '*');
          перевод;
          конкат := false;
          if сорт and структ and (колонки[1] = 1) then begin
            стрсохр := true;
            структ := false
          end
          else стрсохр := структ;
          while not конкат do begin
            след(элем, конкат);
            глуб := 0;
            вершина := 0;
            показано := 0;
            фильтр(элем, true, not сорт)
          end;
          структ := стрсохр;
          конкат := false;
          if сорт then begin
            тек := список;
            сорт := false;
            while (тек <> nil) and not конкат do begin
              зону(тек^.зк);
              позиц := тек^.где;
              уэл2 := ptr(адрзоны + позиц);
              глуб := 0;
              показано := 0;
              вершина := 0;
              фильтр(уэл2^, false, true);
              тек := тек^.след
            end;
            while список <> nil do begin
              пред := список^.след;
              dispose(список);
              список := пред
            end
          end;
          вывод := true;
          if обращ = 0 then обращ := 0
          else обращ := обращ div использ;
          write(ФАЙЛ, ' ФАЙЛОВ=', файлов:5, '  ЗОН= ', зон:5 oct,
            ' ИСПОЛЬ-НО= ', использ:5 oct, ' ЧАСТОТА=', обращ:6);
          перевод;
          итог := true
        end;
        if естьуст then begin
          маска := маска2;
          неравно := неравно2;
          задан := задан2
        end
      end;
      true: begin
        write(ФАЙЛ, ' НЕТ ПРИКАЗА ', приказ);
        перевод
      end
    end
  until кончить
end.
