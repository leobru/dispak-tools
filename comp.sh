#!/bin/sh -x
dispak -l $1.b6 | tee $1.lst | ./mksyms.pl > symtab.$1
cat $1.lst
