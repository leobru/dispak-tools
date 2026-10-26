#!/usr/bin/env python3
"""Print the var section of the globals shared by АСС3's parts (M1 050-01176).

Usage: python3 runtime/acc3/genvars.py > vars.inc

TYPES gives the type of each global by its octal M1 offset; arrays take
their whole extent. Every other word is an integer named g<offset>. The
declarations keep the original order, hence the offsets. Paste the output
into the var section of head.pas, ov1.pas and ov2.pas.

With --common it prints instead the program parameters that follow
*OUTPUT* (01723 words; overlay 1 has them at 20634): each is its own common
block, typed by COMMON and named z<letter> in address order (za is at
20634), with the address in a comment. The names are that short because
NEWPASC keeps at most 89 external names longer than four letters, and a
common block's name gets a star on each side (*ZA*). The first lines are
the list for the program heading, the rest their var declarations.
"""
import sys
TYPES = {
    0o50: ('bitset', 1), 0o51: ('t1', 0o534),
    0o606: ('pt', 1), 0o611: ('pt', 1), 0o612: ('pt', 1),
    0o614: ('entry', 3), 0o617: ('entry', 3),
    0o623: ('pt', 1), 0o627: ('pt', 1), 0o630: ('pt', 1), 0o631: ('pt', 1),
    0o632: ('p10', 1), 0o715: ('pt', 1), 0o717: ('pt', 1), 0o720: ('pt', 1),
    0o722: ('pw', 1), 0o723: ('pt', 1), 0o1024: ('po', 1),
    0o1035: ('pint', 1), 0o1036: ('hx', 1), 0o1041: ('pt', 1), 0o1043: ('pt', 1),
    0o1133: ('pt', 1), 0o1135: ('entry', 3),
    0o1140: ('long', 2), 0o1142: ('long', 2), 0o1144: ('long', 2),
    0o1146: ('long', 2), 0o1104: ('array [0..8] of a6', 9),
    0o636: ('t2', 0o56),
    0o724: ('packed array [0..1023] of c3', 0o100),
    0o1026: ('word3', 3),
    0o1044: ('bitset', 1), 0o1045: ('bitset', 1), 0o1060: ('boolean', 1), 0o1164: ('boolean', 1),
    0o1170: ('boolean', 1), 0o1171: ('boolean', 1), 0o1172: ('boolean', 1),
    0o1175: ('r5', 1), 0o1176: ('s5', 1),
    **{a: ('alfa', 1) for a in range(0o1072, 0o1126) if not 0o1104 <= a < 0o1115},
    0o1130: ('a4', 1), 0o1131: ('a4', 1), 0o1132: ('a4', 1),
}


COMMON = {
    0o20635: ('bitset', 1),
    0o20641: ('array [0..1] of integer', 2),
    0o20644: ('array [5..10] of integer', 6),
    0o20653: ('lbits', 1),
    0o20655: ('array [0..255] of integer', 0o400),
    0o21255: ('array [0..63] of h2', 0o100),
    0o21355: ('array [1..246] of op2', 0o754),
    0o22331: ('buf', 0o220),
    0o22551: ('boolean', 1), 0o22552: ('boolean', 1), 0o22553: ('char', 1),
    0o22554: ('char', 1),
}


def declarations(types, lo, hi, name):
    decls, a = [], lo
    while a <= hi:
        typ, size = types.get(a, ('integer', 1))
        decls.append((name(a, len(decls)), typ, a))
        a += size
    return decls


def main():
    if '--common' in sys.argv:
        decls = declarations(COMMON, 0o20634, 0o22556,
                             lambda a, k: 'z' + 'abcdefghijklmnopqrstuvwxy'[k])
        names = [n for n, _, _ in decls]
        print(',\n'.join('    ' + ', '.join(names[k:k+11])
                         for k in range(0, len(names), 11)))
        for name, typ, a in decls:
            print(f'    {name}: {typ}; (* {a:o} *)')
        return
    decls = declarations(TYPES, 0o50, 0o1176, lambda a, k: f'g{a:04o}')
    print('\n'.join(format_lines([d[:2] for d in decls], '    ')))


def format_lines(decls, indent):
    lines, names, typ = [], [], None
    for name, t in decls + [(None, None)]:
        if names and (t != typ or len(', '.join(names + [name or ''])) > 50):
            lines.append(f'{indent}{", ".join(names)}: {typ};')
            names = []
        names.append(name)
        typ = t
    return lines


if __name__ == '__main__':
    main()
