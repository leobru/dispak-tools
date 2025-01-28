#!/bin/sh

if [ $# -ne 4 ] ; then echo Usage: textdump.sh vol zone startline endline; exit 1; fi
cat <<EOF > batch$$
шифр 419900^ЛЕН 30($1)^ВРЕ 1^ВХО 1^ОЗУ 2^
ЕВ1
К 00 070 0010
К 00 070 0011
К 00 074 0000
В10
С 0010 0100 0030 $2
C 0000 0100 0027 0000
ЕКОНЕЦ
EOF
dispak --drum-dump=dump$$ batch$$ > /dev/null
sed -n "$3,$4p" < dump$$
rm batch$$ dump$$
