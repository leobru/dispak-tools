(*=s7,s8,p-,t-*)
program RTSMOKE(output);
var f:text; i:integer;
procedure increment(var x:integer);
_( x:=x+1 _);
_(
  i:=40;
  increment(i);
  writeln('RUNTIME ',i:2);
  rewrite(f);
  write(f,'ABC');
  reset(f);
  while not eof(f) do _(
    write(f@);
    get(f)
  _);
  writeln
_).
