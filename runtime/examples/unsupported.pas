(*=s7,s8,p-,t-*)
program RTUNSUP(output);
procedure p(x:integer);
  procedure q(y:integer);
    procedure r(z:integer);
    _( writeln(z) _);
  _( r(y) _);
_( q(x) _);
_( p(1) _).
