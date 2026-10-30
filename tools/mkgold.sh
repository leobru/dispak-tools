#!/bin/sh
opt=
if [ -f entry.$1 ]; then opt="$opt -E entry.$1"; fi
if [ -f gost.$1 ]; then opt="$opt -G gost.$1"; fi
if [ -f iso.$1 ]; then opt="$opt -A iso.$1"; fi
if [ -f itm.$1 ]; then opt="$opt -I itm.$1"; fi
if [ -f text.$1 ]; then opt="$opt -T text.$1"; fi

./dtran -c -R8 -n $opt $1.o > golden.$1
ln -s -f routines.$1 routines.txt
ln -s -f globals.$1 globals.txt
./dtran -d $opt $1.o > predecomp.$1 
if [ -f rename.$1 ]; then replace `cat rename.$1` -- predecomp.$1 golden.$1; fi

grep -v -e ---------- predecomp.$1 | ./decomp.pl > disasm
perl -i -pe 's/smc/;/g;' disasm golden.$1
