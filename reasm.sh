#!/bin/sh -x
/u/leob/area/scratch/mybesm6/dispak/besmtool/besmtool dump 1234 --start=0315 --length=8 --to-file=re-$1.o
opt=
if [ -f entry.$1 ]; then opt="$opt -E entry.$1"; fi
if [ -f gost.$1 ]; then opt="$opt -G gost.$1"; fi
if [ -f iso.$1 ]; then opt="$opt -A iso.$1"; fi
if [ -f itm.$1 ]; then opt="$opt -I itm.$1"; fi
if [ -f text.$1 ]; then opt="$opt -T text.$1"; fi

./dtran -c -R8 -n $opt re-$1.o > re-$1.asm

perl -i -pe 's/smc/;/g;' re-$1.asm

if [ -f symtab.$1 ]; then replace `cat symtab.$1` -- re-$1.asm; fi
