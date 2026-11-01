#!/usr/bin/env python3
"""Print ISO-coded strings of a memory image as Pascal literals.

Usage: isolit.py image BASE ADDR:LEN ...

  image   6-byte words loaded from address BASE (octal)
  ADDR    word address of the string (octal), LEN its length in chars

Characters are 8 bits, six to a word, from the left.  Codes 0140-0176
are shown as Cyrillic capitals (КОИ-7), 040-0137 as themselves; the
apostrophe and every other code are written as '_ooo', as the compiler
accepts them.  Latin letters that look like Cyrillic ones stay Latin:
the compiler stores А, В, Е, К, М, Н, О, Р, С, Т, Х, У written in
Cyrillic with the same codes.
"""
import sys

K7 = 'юабцдефгхийклмнопярстужвьызшэщчъ'


def main():
    data = open(sys.argv[1], 'rb').read()
    base = int(sys.argv[2], 8)

    def char(k):
        word = int.from_bytes(data[6 * k:6 * k + 6], 'big')
        return word

    for arg in sys.argv[3:]:
        addr, length = arg.split(':')
        addr, length = int(addr, 8), int(length)
        text = ''
        for n in range(length):
            word = char(addr - base + n // 6)
            c = (word >> (40 - 8 * (n % 6))) & 0xff
            if 0x60 <= c <= 0x7e:
                text += K7[c - 0x60].upper()
            elif 0x20 <= c < 0x60 and c != 0x27:
                text += chr(c)
            else:
                text += '_%03o' % c
        print("%s '%s'" % (arg, text))


if __name__ == '__main__':
    main()
