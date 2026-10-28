(*=p-,t-*)
program shift(output);
% shift(x, n) of an integer by a constant n is сда 64+n (n < 0 shifts
% left); АСС3 takes the low 16 bits of a word to the top of a set as
% bitset(shift(x, -32)).  A shift by a variable n is мод n; сда 64,
% as the old compiler did (P/II does not exist).
type bitset = set of 0..47;
var x, n: integer; s: bitset;
_(
  x := 5;
  s := bitset(shift(x, -32));
  writeln(minel(s):3, card(s):3);
  s := bitset(shift(shift(x, -32), 2));
  writeln(minel(s):3, card(s):3);
  n := -34; s := bitset(shift(x, n));
  writeln(minel(s):3, card(s):3);
_).
