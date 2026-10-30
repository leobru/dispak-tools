#!/usr/bin/env python3
"""Compile BLINK1 recovered from 4001/0255 and compare all Pascal regions.

Usage: python3 programs/blink1/build.py [--source candidate.pas]
       python3 programs/blink1/build.py --disassemble-only

Uses the shared LINK1 builder with BLINK1's original routine and service map.
The real runtime is compared literally; the linker itself is not executed.
"""
from pathlib import Path
import analyze
from paths import PROGRAMS, BUILD

HERE = Path(__file__).resolve().parent


def main():
    data = analyze.profile()
    shared = analyze.load_module('blink1_shared_build', PROGRAMS/'link1/build.py')
    shared.__doc__ = __doc__
    shared.HERE = HERE
    shared.WORK = BUILD/'blink1'
    shared.SOURCE_NAME = 'blink1.pas'
    shared.PROGRAM_NAME = 'BLINK1'
    shared.SCRATCH_ZONE = 0o255
    shared.NAMEKEY_LITERALS = [(address, name.replace('-1', '-2'))
                               for address, name in shared.NAMEKEY_LITERALS]
    shared.analyze = analyze
    shared.ENTRIES = data['entries']
    shared.ENDS = data['ends']
    shared.EXTERNALS = data['externals']
    shared.reference_address = analyze.reference_address
    shared.main()


if __name__ == '__main__':
    main()
