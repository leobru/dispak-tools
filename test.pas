program TEST(input, output);
% Restored from test.bin (memory image from 02000) by disassembly;
% builds an identical program part with buildimg.sh.  The % lines
% keep line numbers equal to those in the binary (they are passed
% to P/SC and to the bounds checks): GETCMDLINE begins at line 82,
% and (*=S3*) restarts the count so that the main block begins at
% line 12.  Names are from the post-mortem dump table, which keeps
% 8 characters (GETCMDLI, ACTIVELI).  The type of ACTIVELINE (one
% word, array) and of BS (one word, not scalar/array) is a guess.
% The external function below is not called; something like it is
% needed for the unused multiplier constant 4000000000000001 that a
% non-packed array type with integer index adds; its name and
% parameters are unknown.
type bitset = set of 0..47;
var
  activeline [3B] : alfa;
  bs [50B] : bitset;
  i [51B] : integer;
  cmdline [55B] : packed array [1..84] of char;
procedure getcmdline(var f: text);
var i: integer;
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
%
_(
  rewrite(f);
  (q) for i := 1 to 80 do
  _(
    if cmdline[i] = '_012' then exit q;
    write(f, cmdline[i]);
  _);
  reset(f);
_);
(*=S3*)
% Main program: copy the command line to INPUT and print it.
%
%
%
%
%
%
%
%
function f(var a: array [1..2] of integer): integer; external;
_(
  getcmdline(input);
  while not eof(input) do (q) _(
    write(input@);
    get(input);
  _);
  writeln;
_).

