(*=s7,s8,p-,t-*)
program RTNEST(output);
var result:integer;
procedure outer;
var local:integer;
  procedure inner;
  _( local:=local+1; result:=result+local _);
_( local:=20; inner; inner _);
_( result:=0; outer; writeln('NESTED ',result:2) _).
