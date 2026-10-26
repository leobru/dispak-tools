#!/usr/bin/env python3
"""Print the var section of the globals shared by АСС3's parts (M1 050-01176).

Usage: python3 runtime/acc3/genvars.py > vars.inc

TYPES gives the type of each global by its octal M1 offset; arrays take
their whole extent. Every other word is an integer named g<offset>. The
declarations keep the original order, hence the offsets. Paste the output
into the var section of head.pas, ov1.pas and ov2.pas.

With --common it prints instead the program parameters that follow
*OUTPUT* (01723 words; overlay 1 has them at 20634): each is its own common
block, named c<address in overlay 1> and typed by COMMON. The first line
is the list for the program heading, the rest their var declarations.
"""
import sys
TYPES = {
    0o50: ('bitset', 1), 0o51: ('t1', 0o534),
    0o606: ('pt', 1), 0o611: ('pt', 1), 0o612: ('pt', 1),
    0o614: ('entry', 3), 0o617: ('entry', 3),
    0o623: ('pt', 1), 0o627: ('pt', 1), 0o630: ('pt', 1), 0o631: ('pt', 1),
    0o632: ('pt', 1), 0o715: ('pt', 1), 0o717: ('pt', 1), 0o720: ('pt', 1),
    0o722: ('pw', 1), 0o723: ('pt', 1), 0o1024: ('pt', 1),
    0o1035: ('pt', 1), 0o1041: ('pt', 1), 0o1043: ('pt', 1),
    0o1133: ('pt', 1), 0o1135: ('entry', 3),
    0o636: ('t2', 0o56),
    0o724: ('array [0..63] of integer', 0o100),
    0o1026: ('word3', 3),
    0o1044: ('bitset', 1), 0o1045: ('bitset', 1), 0o1060: ('boolean', 1), 0o1164: ('boolean', 1),
    0o1170: ('boolean', 1), 0o1171: ('boolean', 1), 0o1172: ('boolean', 1),
    0o1175: ('s5', 1), 0o1176: ('s5', 1),
    **{a: ('alfa', 1) for a in range(0o1072, 0o1126)},
    0o1130: ('a4', 1), 0o1131: ('a4', 1), 0o1132: ('a4', 1),
}


COMMON = {
    0o20641: ('array [0..1] of integer', 2),
    0o20644: ('array [0..5] of integer', 6),
    0o20653: ('lbits', 1),
    0o20655: ('array [0..1453B] of integer', 0o1454),
    0o22331: ('array [1..144] of char', 0o220),
    0o22551: ('boolean', 1), 0o22552: ('boolean', 1), 0o22553: ('char', 1),
}


def declarations(types, lo, hi, prefix, width):
    decls, a = [], lo
    while a <= hi:
        typ, size = types.get(a, ('integer', 1))
        decls.append((f'{prefix}{a:0{width}o}', typ))
        a += size
    return decls


def main():
    if '--common' in sys.argv:
        decls = declarations(COMMON, 0o20634, 0o22556, 'c', 5)
        names = [n for n, _ in decls]
        print(',\n'.join('    ' + ', '.join(names[k:k+7])
                         for k in range(0, len(names), 7)))
        print('\n'.join(format_lines(decls, '    ')))
        return
    print('\n'.join(format_lines(declarations(TYPES, 0o50, 0o1176, 'g', 4), '    ')))


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
