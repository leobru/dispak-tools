(*=s7,s8,p-,t-*)
program RTPACK(output);
var a:packed array[0..11] of 0..15;
    i,sum:integer; s:set of 0..47;
_(
  sum:=0;
  for i:=0 to 11 do a[i]:=i;
  for i:=0 to 11 do sum:=sum+a[i];
  s:=[sum mod 47];
  if 19 in s then writeln('PACKED ',sum:2)
  else writeln('FAILED')
_).
