#!/bin/sh
# Build a memory image of a Pascal program the way arap.b6/compar.b6 do
# (NEWPASC + the PASCODER stub writing core from 02000 to disk) and
# compare it with a reference binary.
#
# Usage: buildimg.sh prog.pas [ref.bin [nzones]]
#   Produces prog.img (nzones*1024 words from address 02000, default 2)
#   and prog.img.lst (the compilation listing).  With ref.bin, compares
#   the image with it and prints differing words via disbesm6 listings.
#   NEWPASC is taken from disk 77 on the usual path ($BESM6_PATH or
#   ~/.besm6:/usr/local/share/besm6); the image goes to a scratch disk.
#   $PERSO lists the library zones to load (default "311160 320200").
#   If prog.pre exists, its cards (e.g. *assem stubs for externals) are
#   put into the job before the Pascal program.
#   With LIBCODER=1 the library PASCODER is used (as in compar.b6; its stub
#   is 10 words, user code from 02012) instead of the 9-word inline one.
#   $ZONE (4 octal digits, default 0000) is the scratch-disk zone written.

if [ $# -lt 1 ]; then echo "Usage: $0 prog.pas [ref.bin [nzones]]"; exit 1; fi
src=$1; ref=$2; nz=${3:-2}
base=${src%.pas}
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
: > "$work/3777"
BESM6_PATH=$work:${BESM6_PATH:-$HOME/.besm6:/usr/local/share/besm6}
export BESM6_PATH

{
cat <<EOF
user 419900зс5^
dis 31(2113)32(77)33(2148-440)34(2048)67(3777-wr)^
eeb1a3
*name
EOF
if [ -f "$base.pre" ]; then cat "$base.pre"; fi
cat <<EOF
*libra:13
*call ficmemory
*trans:newpasc,,320000
EOF
cat "$src"
for z in ${PERSO:-311160 320200}; do echo "*perso:$z,cont"; done
if [ -z "$LIBCODER" ]; then cat <<EOF
*no li
*assem
 Р/ВООТ:,NАМЕ,DТRАN  /01.06.84/
 Р/СОDЕR:,SUВР,
 РRОGRАМ:,SUВР,
 ,WТС,P/CODER+2
 1,VТМ,
 *1:1,UTM,-1
 1,VZМ,РRОGRАМ
 ,ARX,=100 0000 0001
 ,АТХ,P/CODER
 ,*70,P/CODER
 ,XTA,P/CODER
 ,UJ,*1
 ,END,
EOF
fi
cat <<EOF
*table:p/coder(w*67${ZONE:-0000},l*$(printf %o $nz))
*main pascoder
*execute
*end file
\`\`\`\`\`\`
еконец
EOF
} > "$work/job.b6"

dispak --path="$BESM6_PATH" -l "$work/job.b6" > "$base.img.lst" 2>&1
besmtool dump 3777 --start=0${ZONE:-0} --length="$nz" --to-file="$base.img" >/dev/null || exit 1

if [ -n "$ref" ]; then
    if cmp -s "$base.img" "$ref"; then
        echo "$base.img matches $ref"
    else
        "$here/disbesm6" -b -a2000 -e2000 "$ref" > "$work/ref.dis"
        "$here/disbesm6" -b -a2000 -e2000 "$base.img" > "$work/img.dis"
        diff "$work/ref.dis" "$work/img.dis"
        exit 1
    fi
fi
