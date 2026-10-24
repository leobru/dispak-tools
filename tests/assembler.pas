(*=L2*)program t(output); var i, j: integer;
function orx(a, b: integer): integer; assembler;
procedure setv(var v: integer; x: integer); assembler;
procedure nop; assembler;
procedure lev2;
var k: integer;
_( k := 0; setv(k, orx(4, 2)); writeln(k) _);
_( i := orx(1, 2); writeln(i);
   setv(j, 40); nop; writeln(j);
   lev2; writeln(orx(i, j))
_).
*assem
 ORX:,NAME,
 15,XTA,-2
 15,AOX,-1
 15,UTM,-2
 13,UJ,
 ,END,
 SETV:,NAME,
 15,XTA,-1
 15,WTC,-2
 ,ATX,
 15,UTM,-2
 13,UJ,
 ,END,
 NOP:,NAME,
 13,UJ,
 ,END,
