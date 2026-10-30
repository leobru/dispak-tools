#!/usr/bin/env python3
"""Compile LINK recovered from 4001/0112 and compare all Pascal regions.

Usage: python3 runtime/link/build.py [--source candidate.pas]
       python3 runtime/link/build.py --disassemble-only

Uses the shared LINK1 builder with LINK's original routine and service map.
The real runtime is compared literally; the linker itself is not executed.
"""
from pathlib import Path
import analyze
from paths import PROGRAMS, BUILD

HERE = Path(__file__).resolve().parent


def main():
    data = analyze.profile()
    shared = analyze.load_module('link_shared_build', PROGRAMS/'link1/build.py')
    shared.__doc__ = __doc__
    shared.HERE = HERE
    shared.WORK = BUILD/'link'
    shared.SOURCE_NAME = 'link.pas'
    shared.PROGRAM_NAME = 'LINK'
    shared.SCRATCH_ZONE = 0o112
    shared.NAMEKEY_LITERALS = [(address, name.replace('-1', '-3'))
                               for address, name in shared.NAMEKEY_LITERALS]
    shared.analyze = analyze
    shared.ENTRIES = data['entries']
    shared.ENDS = data['ends']
    shared.EXTERNALS = data['externals']
    shared.reference_address = analyze.reference_address
    shared.main()


if __name__ == '__main__':
    main()
