(*=W+*)program t(output);
(* Code as in АСС3: records of 2 and 3 words are copied without a loop,
   [i] is not ORed with [], and the address of a global is
   мода off(М1); уиа (Мk), not P/1D+off. *)
type r2 = record a, b: integer end;
     r3 = record a, b, c: integer end;
     r4 = record a, b, c, d: integer end;
var x2, y2: r2; x3, y3: r3; x4, y4: r4; s: set of 0..47; i: integer;
procedure inc(var k: integer); _( k := k + 1 _);
_( x2.a := 1; x2.b := 2; y2 := x2;
   x3.a := 3; x3.b := 4; x3.c := 5; y3 := x3;
   x4.a := 6; x4.b := 7; x4.c := 8; x4.d := 9; y4 := x4;
   i := 5; s := [i] + s; s := s + [i, 7]; inc(i); inc(y4.b);
   writeln(y2.a, y2.b, y3.a, y3.b, y3.c, y4.a, y4.b, y4.c, y4.d, i)
_).
