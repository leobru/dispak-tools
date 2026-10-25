(*=p-,t-,m-*)
program mulpow2(output);
% Under (*=m-*) x * 2**k (k > 0, either operand a constant) is
% compiled as an exponent add: ржа 0; слпа 64+k; ржа 7; сл 9(М1).
% This is right for negative x too, unlike the m- умн; счмр 64.
const k = 16384;
var i, x, y, bad: integer;
    v: array [1..8] of integer;
_(
  v[1] := 0; v[2] := 1; v[3] := 5; v[4] := -3;
  v[5] := 12345; v[6] := -77777; v[7] := 1023; v[8] := -1;
  bad := 0;
  for i := 1 to 8 do _(
    x := v[i];
    y := x;
    if x * 16384 <> y * 8192 * 2 then bad := bad + 1;
    if k * x + 1 <> 16384 * y + 1 then bad := bad + 1;
    if x * 2 <> x + x then bad := bad + 1;
    if x * 1048576 <> x * 1024 * 1024 then bad := bad + 1;
    if x * 4 <> x + x + x + x then bad := bad + 1;
    if x >= 0 then _( (* m- умн is wrong for negative x *)
      if x * 1 <> x then bad := bad + 1;
      if x * 6 <> x * 4 + x * 2 then bad := bad + 1;
    _);
    writeln(x:8, x * 8:10, (x + 1) * 16384:14);
  _);
  if 3 * 16 <> 48 then bad := bad + 1;
  writeln('ERRORS:', bad:3);
_).
