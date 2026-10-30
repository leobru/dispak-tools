program t(output);
% .data takes a string longer than 6 characters as all of its words,
% between one-word values and with a repeat count.
type msg = packed array [1..12] of char;
var i: integer; a: array [1..4] of msg; w: array [1..4] of integer;
_( for i := 1 to 4 do writeln(a[i]);
   for i := 1 to 4 do writeln(w[i]:20 oct)
_).data
a[1] := 'HELLO, WORLD';
a[2] := 'ABCDEF', 'GHIJKL', 'ONE-WORD-ONE':2;
w := 1, 'abcdefgh', 77C
end
