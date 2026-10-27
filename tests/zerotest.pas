(*=W+*)program t(output);
(* Under W+, the value of a scalar = or <> is computed without jumps:
   нтж b; счм 025(М1); рзб (М17); чед [; нтж 8(М1)], as in АСС3. *)
var i, j: integer; c: char; b, d: boolean; s: set of 0..47;
_( i := 3; j := 5; c := 'A'; s := [1, 3];
   b := i = j; d := i <> j; write(ord(b), ord(d));
   b := i = 3; d := c <> 'A'; write(ord(b), ord(d));
   b := s = [1, 3]; d := 3 in s; write(ord(b), ord(d)); (* in: jumps *)
   b := i < j; d := (i = 3) and (j = 5); writeln(ord(b), ord(d))
_).
