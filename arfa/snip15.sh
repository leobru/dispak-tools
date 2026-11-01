#!/bin/sh
# Compile a Pascal snippet the way buildovl.sh builds BUST and STARFA
# (standard compiler 15.0 under ЗСХ, *call overlay) and print the user
# code: the disassembly from 01000 up to P/1D, then the loader map.
# Compiler errors are shown from the listing.
#
# Usage: snip15.sh x.pas [NAME]   (NAME as in *call overlay, default X)
if [ $# -lt 1 ]; then echo "Usage: $0 x.pas [NAME]"; exit 1; fi
here=$(cd "$(dirname "$0")" && pwd)
base=${1%.pas}
"$here/buildovl.sh" "$1" "${2:-X}" >/dev/null 2>&1
grep -a -E '^ *[0-9]{5} +[0-9]+ +[0-9]+ |ОШИБ|\*\*\*' "$base.img.lst" | grep -a -i -E 'ошиб|\*\*\*' 
p1d=$(grep -a -o -E 'P/1D +C [0-7]{5}' "$base.img.lst" | tail -1 | awk '{print $3}')
"$here/../tools/disbesm6" -b -a770 -e1000 "$base.img" |
    awk -v oct=$(printf '%d' "0$p1d") '
        { a = $1; sub(/:.*/, "", a) }
        a ~ /^[0-7]+$/ && length(a) >= 4 { v = 0; for (i = 1; i <= length(a); i++) v = v * 8 + substr(a, i, 1); if (v >= oct) exit }
        /^ *1000 / { f = 1 } f'
grep -a -A40 -E 'P/1D +C' "$base.img.lst" | sed -n '1,/^ *$/p'
