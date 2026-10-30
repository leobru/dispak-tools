(*=L2*)program t(output); var i: integer; a: alfa;
function getv(var v: integer): integer; assembler;
procedure geta(var v: alfa; var r: alfa); assembler;
(* Under C- a constant is passed to a VAR parameter by address. *)
_( (*=c-*) i := getv(42); writeln(i);
   geta('ABCDEF', a); writeln(a) (*=c+*)
_).
*assem
 GETV:,NAME,
 ,ATI,14
 14,XTA,
 13,UJ,
 ,END,
 GETA:,NAME,
 ,ATI,14
 15,XTA,
 ,ATI,12
 12,XTA,
 14,ATX,
 13,UJ,
 ,END,
