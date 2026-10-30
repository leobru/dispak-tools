(*=p-,t-*)
program besmlong(output);
% A long-format literal with an address >= 040000 (here UJ 76000B)
% keeps its address.
var i: integer;
_(
  i := 1;
  if i = 2 then besm(3076000B);
  i := 3
_).
