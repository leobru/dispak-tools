(*=a2,y+*)
program TYPEFILE(input, output);
% Recovered from volume 4001, catalog MORE, zones 0034-0036.
% Application 02012-03113 survives; runtime zone 04000-05777 is erased.
% Names come from the surviving PMD tables, except descriptive type names.
% Build: python3 runtime/more/build.py (COMP library, private disks).
% Rebuild differs in PMD line numbers, padding and increment constants.
% GETWORD uses the original raw load with its redundant check omitted.
% The compiler uses the original last-argument-in-A ASSEMBLER convention.
const lf = '_012'; esc = '_033';
type
  bitset = set of 0..47;
  line = packed array [1..84] of char;
  word3 = record ext, lib, name: alfa end;
var
  activeline [3B]: alfa;
  errtxt: line;
  cmdline [55B]: line;
  filename: line;
  fullname: word3;
  filedesc, i, result, lines: integer;
  ch: char;
  pchr: integer;
  sixbytes: alfa;
  pword: integer;

function MKNAME(var name: line; lib, ext: alfa;
                var dest: word3): integer; assembler;
procedure ERROR(status: integer; var text: line); assembler;
function OPENF(var name: word3; writing: boolean;
               var descriptor: integer): integer; assembler;

procedure GETCMDLINE(var f: text);
var i: integer;
begin
  rewrite(f);
  (done) for i := 1 to 80 do begin
    if cmdline[i] = lf then exit done;
    write(f, cmdline[i]);
  end;
  reset(f);
end;

procedure WASCTTY(var f: text);
var cw, cw1, i: integer;
    buff: packed array [0..255] of char;
    creg: boolean;

  procedure PUTCHAR(c: char);
  begin
    buff[i] := c;
    i := i + 1;
  end;

  procedure SETUPP;
  begin
    if creg = false then begin
      PUTCHAR(esc); PUTCHAR('_151'); creg := true;
    end;
  end;

  procedure SETLOW;
  begin
    if creg = true then begin
      PUTCHAR(esc); PUTCHAR('_150'); creg := false;
    end;
  end;

begin
  reset(f);
  i := 0;
  creg := false;
  SETUPP;
  while not eof(f) and not eoln(f) do begin
    if (f@ >= '_140') and (f@ <= '_176') then begin
      SETLOW; PUTCHAR(char(bitset(f@) mod bitset(40C)));
    end else if f@ = esc then begin
      PUTCHAR(esc); get(f); PUTCHAR(f@);
    end else if f@ < '_140' then begin
      SETUPP; PUTCHAR(f@);
    end else if (f@ >= '_300') and (f@ < '_340') then begin
      SETLOW; PUTCHAR(char(bitset(f@) mod bitset(240C)));
    end else if (f@ >= '_340') and (f@ < '_377') then begin
      SETUPP; PUTCHAR(char(bitset(f@) mod bitset(200C)));
    end else begin
      SETUPP; PUTCHAR(f@);
    end;
    get(f);
  end;
  SETUPP;
  if eoln(f) then PUTCHAR('_015');
  PUTCHAR(lf); PUTCHAR('_000');
  cw1 := 0120000001000000C;
  (* BUFF is at offset 7 in the level-2 frame. *)
  besm(12200007B, 66400000B, 4710024B);
  besm(230000B, 360064B);
  cw := ;
  cw := integer(bitset(cw) + bitset(6421000064000052C));
  besm(710000B: cw);
  rewrite(f);
end;

function GETWORD: alfa;
var temp: bitset;
begin
  if (pword < 1) or (pword > 1024) then begin
    temp := bitset(filedesc) * [30..47] + bitset(0010360000000000C);
    besm(700000B: temp);
    filedesc := filedesc + 1;
    pword := 1;
  end;
  besm(100000B: pword, 400016B, 72200000B, 1103777B);
  GETWORD := ;
  pword := pword + 1;
end;

procedure GETCH;
begin
  if not (pchr in [1..6]) then begin
    sixbytes := GETWORD;
    pchr := 1;
  end;
  ch := sixbytes[pchr];
  pchr := pchr + 1;
end;

begin
  GETCMDLINE(input);
  if eoln(input) then begin
    rewrite(input);
    write(input, 'FILE= ');
    readln(input);
  end;
  i := 1;
  while not eoln(input) and (i < 84) do begin
    filename[i] := input@;
    get(input);
    i := i + 1;
  end;
  filename[i] := lf;
  result := MKNAME(filename, activeline, 'TXT   ', fullname);
  if result <> 0 then begin
    ERROR(result, errtxt); writeln(output, errtxt);
    besm(100000B: result, 3000002B);
  end;
  result := OPENF(fullname, false, filedesc);
  if result <> 0 then begin
    ERROR(result, errtxt); writeln(output, errtxt);
    besm(100000B: result, 3000002B);
  end;
  lines := 0; pchr := 0; pword := 0;
  while true do begin
    GETCH;
    case ch of
      '_000', '_004': begin
        write(output, '<EOF>'); writeln(output);
        besm(100000B: result, 3000002B);
      end;
      '_012': begin
        if lines < 23 then begin
          write(output, lf); WASCTTY(output);
          lines := lines + 1;
        end else begin
          rewrite(input); write(input, '- MORE - '); readln(input);
          if not eoln(input) then besm(3000002B);
          write(output, lf); WASCTTY(output); lines := 1;
        end;
      end;
      '_015': ;
      others: write(output, ch)
    end;
  end;
end.
