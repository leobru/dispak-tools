#!/bin/sh
# Build a Pascal program the way BUST was built: the standard Pascal
# compiler (*call *pascal, PASCAL COMPILER 15.0) under passport ЗСХ, the
# 2113 library (*perso zones from $PERSO, default "311160 330000"; drive
# 33 is the Pascal library of 2148), then *call overlay writing the
# overlay to a scratch disk; the packed image is unpacked with
# tools/ovl2bin.  The ЗС5 monitor crashes on a multi-zone overlay; the
# ЗСХ one (МОНИТОР-80 3.6) runs with volumes 2048 and 2053 that are
# private copies of the standard 2148 and 2153.
#
# Usage: buildovl.sh prog.pas NAME [ref.bin]
#   NAME is the program name given to *call overlay (as in the source).
#   Produces prog.img (memory from 0770, as bust.bin), prog.img.lst (the
#   listing) and prog.cat (the overlay catalog zone).  With ref.bin,
#   reports whether the image is identical to it.  If prog.pre exists,
#   its cards (e.g. *assem modules for externals) go before the program.
#   The other volumes are taken from the usual path ($BESM6_PATH or
#   ~/.besm6:/usr/local/share/besm6).

if [ $# -lt 2 ]; then echo "Usage: $0 prog.pas NAME [ref.bin]"; exit 1; fi
src=$1; name=$2; ref=$3
base=${src%.pas}
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
: > "$work/3777"
path=${BESM6_PATH:-$HOME/.besm6:/usr/local/share/besm6}
for v in 2148:2048 2153:2053; do
    for d in $(echo "$path" | tr : ' '); do
        if [ -f "$d/${v%:*}" ]; then cp "$d/${v%:*}" "$work/${v#*:}"; break; fi
    done
    chmod u+w "$work/${v#*:}" || exit 1
done
BESM6_PATH=$work:$path
export BESM6_PATH

{
cat <<EOF
user 419900зсх^
dis 31(2113)32(77)33(2148-440)34(2048)67(3777-wr)^
eeb1a3
*name
EOF
if [ -f "$base.pre" ]; then cat "$base.pre"; fi
cat <<EOF
*call ficmemory
*call *pascal
EOF
cat "$src"
for z in ${PERSO:-311160 330000}; do echo "*perso:$z,cont"; done
cat <<EOF
*call overlay:670000
 $name
*end record
*end file
\`\`\`\`\`\`
еконец
EOF
} > "$work/job.b6"

dispak --path="$BESM6_PATH" -l "$work/job.b6" > "$base.img.lst" 2>&1
besmtool dump 3777 --start=0 --length=1 --to-file="$work/cat" >/dev/null || exit 1
besmtool dump 3777 --start=1 --length=7 --to-file="$work/ovl" >/dev/null || exit 1
cp "$work/cat" "$base.cat"
"$here/../tools/ovl2bin" < "$work/ovl" > "$base.img" || exit 1

if [ -n "$ref" ]; then
    if cmp -s "$base.img" "$ref"; then
        echo "$base.img matches $ref"
    else
        cmp "$base.img" "$ref"
        exit 1
    fi
fi
