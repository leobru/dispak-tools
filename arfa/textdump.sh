#!/bin/sh
# Print lines startline..endline of the drum dump of nz zones (default 1)
# of volume vol starting at zone, as zongp.pl -v prints an assembled
# program: textdump.sh vol zone startline endline [nz]

if [ $# -lt 4 ] || [ $# -gt 5 ] ; then echo Usage: textdump.sh vol zone startline endline [nz]; exit 1; fi
nz=${5:-1}
{
echo "шифр 419900^ЛЕН 30($1)^ВРЕ 1^ВХО 1^ОЗУ $((nz + 1))^"
echo ЕВ1
i=0
while [ $i -lt $((2 * nz)) ]; do printf 'К 00 070 %04o\n' $((010 + i)); i=$((i + 1)); done
echo "К 00 074 0000"
printf 'В%o\n' 010
i=0
while [ $i -lt $nz ]; do printf 'С 0010 %04o 0030 %04o\n' $(((i + 1) * 0100)) $(($(printf '%d' 0$2) + i)); i=$((i + 1)); done
i=0
while [ $i -lt $nz ]; do printf 'C 0000 %04o 0027 %04o\n' $(((i + 1) * 0100)) $i; i=$((i + 1)); done
echo ЕКОНЕЦ
} > batch$$
dispak --drum-dump=dump$$ batch$$ > /dev/null
sed -n "$3,$4p" < dump$$
rm batch$$ dump$$
