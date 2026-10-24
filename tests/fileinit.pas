(*=L2*)program t(output); var f: file of integer; i: integer;
procedure p(x: integer);
var g: text;
_( rewrite(g); writeln(g, x); writeln(x) _);
procedure q;
_( p(2) _);
_( rewrite(f); f@ := 7; put(f); reset(f); i := f@;
   p(1); q; writeln(i)
_).
