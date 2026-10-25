(*=p-,t-*)
program divpow2(output);
% x div 2**k (k > 0) is compiled as an exponent subtract:
% вчпа 64+k; сл 9(М1).  It rounds down, so that with the mask
% x mod 2**k: x = (x div 2**k) * 2**k + x mod 2**k, x mod 2**k >= 0.
const k = 1024;
var i, x, bad: integer;
    v: array [1..10] of integer;
_(
  v[1] := 0; v[2] := 5; v[3] := 8; v[4] := 1024; v[5] := 77777;
  v[6] := -1; v[7] := -8; v[8] := -9; v[9] := -1024; v[10] := -77777;
  bad := 0;
  for i := 1 to 10 do _(
    x := v[i];
    if (x div 8) * 8 + x mod 8 <> x then bad := bad + 1;
    if (x div k) * k + x mod k <> x then bad := bad + 1;
    if (x div 2) * 2 + x mod 2 <> x then bad := bad + 1;
    if x div 1 <> x then bad := bad + 1;
    if (x * 8) div 8 <> x then bad := bad + 1;
    writeln(x:8, x div 8:8, x mod 8:3, x div k:6);
  _);
  if (-24 div 8 <> -3) or (100 div 4 <> 25) then bad := bad + 1;
  writeln('ERRORS:', bad:3);
_).
