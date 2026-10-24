(*=L2*)program t(output); var x, y, z: integer;
_( x := 5; y := 3;
besm(0100000B : x, 0150000B : y, 0360100B, 0 : z);
writeln(z);
besm(0100000B : y);
besm(0360100B, 0 : z);
writeln(z)
_).
