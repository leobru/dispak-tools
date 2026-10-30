#!/usr/bin/env python3
"""Mirror KOMPON PMD identifiers in the corresponding LINK-family scopes.

Usage: python3 runtime/linker-runtime/historical_names.py [--apply]
The checked-in correspondence table also names comparison/disassembly output.
Only identifier tokens change; record fields, literals and comments are kept.
"""
import argparse
import json
from pathlib import Path
import re
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'runtime' for p in HERE.parents
                            if (p/'runtime/paths.py').exists())))
from paths import PROGRAMS
NAMES = json.loads((HERE/'historical-names.json').read_text())
ROUTINES = NAMES['routines']
CANONICAL = {v:k for k,v in ROUTINES.items()}


def routine(name):
    return ROUTINES.get(name, name)


def canonical(name):
    return CANONICAL.get(name, name)


def symbol(name):
    return ROUTINES.get(name, NAMES['globals'].get(name.upper()[:8], name))


def declarations(node):
    """Collect formal/local declarations to respect unmapped shadowing."""
    tokens = node['tokens']
    result = set()
    for i,t in enumerate(tokens):
        if t[0].lower() == 'begin':
            break
        if t[0] != ':' or t.start() in node['record_tokens']:
            continue
        j = i-1
        while j>=0 and re.fullmatch(r'[A-Za-zА-Яа-я_][\w]*',tokens[j][0]):
            result.add(tokens[j][0].upper()[:8])
            j-=1
            if j<0 or tokens[j][0]!=',':
                break
            j-=1
    return result


def mirror(source):
    sys.path.insert(0,str(PROGRAMS/'kompon3'))
    from restore import parse, cards
    root,nodes,tokens = parse(source)
    previous = {t.start():tokens[i-1][0] if i else ''
                for i,t in enumerate(tokens)}
    for node in nodes:
        key = canonical(node['name'])
        node['renames'] = (NAMES['globals'] if node is root else
                           NAMES['locals'].get(key, {})
                           if key==node['name'] else {})
        node['declared'] = declarations(node)
    replacements = {}
    for node in nodes:
        if node['external']:
            continue
        for token in node['tokens']:
            word = token[0]
            if (token.start() in node['record_tokens'] or
                not re.fullmatch(r'[A-Za-zА-Яа-я_][\w]*',word)):
                continue
            if (previous[token.start()]=='.' and
                not source[:token.start()].rstrip().endswith('..')):
                continue
            target = None
            key = word.upper()[:8]
            if word.isupper() or re.fullmatch('g[0-7]{4}',word):
                scope = node
                while scope:
                    if key in scope['renames']:
                        target = scope['renames'][key]
                        break
                    if key in scope['declared']:
                        break
                    scope = scope['parent']
                if target is None and scope is None:
                    target = ROUTINES.get(word)
                # A routine's own declaration/result identifier is declared
                # in its frame, while its name belongs to the parent scope.
                if target is None and word == node['name']:
                    target = ROUTINES.get(word)
            if target is None:
                target = NAMES['enums'].get(word)
            if target is not None and target != word:
                replacements[token.start()] = (token.end(),target)
    for start,(end,text) in sorted(replacements.items(),reverse=True):
        source = source[:start]+text+source[end:]
    return cards(source), len(replacements)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply',action='store_true')
    args = parser.parse_args()
    for name in ['link1','blink1','link','blink']:
        path = PROGRAMS/name/(name+'.pas')
        before = path.read_text()
        after,count = mirror(before)
        if args.apply:
            path.write_text(after)
        print(f'{name}: {count} identifier replacements')


if __name__ == '__main__':
    main()
