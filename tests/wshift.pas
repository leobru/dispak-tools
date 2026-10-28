(*=W+*)program t(output);
(* shift under W+, as in АСС3: any one-word value can be shifted, the
   result has the type of x, and an integer shifted right or by a
   variable is ORed with the integer 0, so that a bit pattern (e.g. a
   set taken as an integer) becomes an integer. *)
type bitset = set of 0..47;
var x, n: integer; s, t: bitset;
_( s := [40, 47]; t := shift(s, -40); writeln(minel(t):3, card(t):3);
   x := integer([44..47]); n := 1;
   writeln(shift(x, 2):5, shift(x, n):5);
   n := -1; writeln(shift(x, n):5)
_).
