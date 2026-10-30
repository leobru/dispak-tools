#!/bin/sh -x
./pascompl $1.pas $1.mo
../pascal-re/dtran -l $1.mo > $1.asm
cat > $1.tmp << EOF
user 419900зс5^
dis 31(2113)32(77)34(2048)67(1234-wr)^
eeb1a3
*name
*      call lditm*:340424
*no list
*libra:32
*libra:13
*assem
EOF
cat $1.asm >> $1.tmp
cat >> $1.tmp << EOF
 program:,name,
 компарат:,subp,
 ,end,
 e6444:,name,
 ,utc,
 e6661:,entry,
 ,utc,
 e6365:,entry,
 ,utc,
 e6602:,entry,
 ,utc,
 e7036:,entry,
 ,utc,
 e7443:,entry,
 ,utc,
 e7667:,entry,
 ,utc,
  ,end,
*perso:311160,cont
*perso:320200,cont
*table:p/coder(w*670315,l*10)
*main pascoder
*execute
*end file
\`\`\`\`\`\`
еконец
EOF
dispak -l $1.tmp | tee $1.lst | ./mksyms.pl > symtab.$1
