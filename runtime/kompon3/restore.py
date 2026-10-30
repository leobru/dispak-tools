#!/usr/bin/env python3
"""Prepare a working historical-name source from LINK and PMD bindings.

Usage: python3 runtime/kompon3/restore.py
Writes a draft under runtime/build/kompon3; never overwrites edited recovery.
The draft is a starting point, not a claim that the two versions are equal.
"""
from collections import defaultdict
import json
from pathlib import Path
import re

import sys

HERE=Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'runtime' for p in HERE.parents
                            if (p/'runtime/paths.py').exists())))
from paths import PROGRAMS, BUILD
WORK=BUILD/'kompon3'
TOKENS=re.compile(r'\(\*.*?\*\)|\{.*?\}|%[^\n]*|"(?:""|[^"])*"|'
                  r"'(?:''|[^'])*'|[A-Za-zА-Яа-я_][A-Za-zА-Яа-я_0-9]*|"
                  r':=|\S',re.S)


def parse(source):
    tokens=[m for m in TOKENS.finditer(source)
            if not m[0].startswith(('(*','{','%'))]
    root=dict(name='LINK',parent=None,children=[],tokens=[],record_tokens=set(),start=0,end=len(source),external=False)
    nodes=[root];scope=root;blocks=[];pending=False
    for i,t in enumerate(tokens):
        word=t[0].lower()
        if any(kind=='record' for kind,_ in blocks):
            scope['record_tokens'].add(t.start())
        if word in ['procedure','function']:
            name=tokens[i+1][0]
            node=dict(name=name,parent=scope,children=[],tokens=[t],record_tokens=set(),
                      start=t.start(),end=None,external=False,body=False)
            scope['children'].append(node);nodes.append(node);scope=node
            continue
        scope['tokens'].append(t)
        if word in ['fortran','assembler','external','forward']:
            scope['external']=True;pending=True
        elif word==';' and pending:
            scope['end']=t.end();scope=scope['parent'];pending=False
        elif word in ['begin','record','select','repeat']:
            kind=word
            if word=='begin' and scope is not root and not scope['body']:
                scope['body']=True;kind='routine'
            blocks.append((kind,scope))
        elif word=='case' and not (blocks and blocks[-1][0]=='record'):
            blocks.append(('case',scope))
        elif word=='until':
            assert blocks and blocks[-1][0]=='repeat',(t.start(),word)
            blocks.pop()
        elif word=='end':
            if not blocks and scope is root:
                continue  # final END after the program's END.D data part
            assert blocks,(t.start(),word)
            kind,owner=blocks.pop()
            if kind=='routine':
                assert owner is scope
                scope['end']=t.end();scope=scope['parent']
    assert scope is root
    return root,nodes,tokens


def choose(newvars,oldvars,votes):
    result={};used=set();old={v['name']:v for v in oldvars}
    candidates=[]
    for v in newvars:
        for name,count in votes.get(v['name'],[]):
            if name in old:
                distance=abs(int(v['offset'],8)-int(old[name]['offset'],8))
                candidates.append((count,-distance,v['name'],name))
    for count,_,modern,historic in sorted(candidates,reverse=True):
        if modern not in result and historic not in used:
            result[modern]=historic;used.add(historic)
    for v in newvars:
        if v['name'] in result:
            continue
        options=[o for o in oldvars if o['name'] not in used and
                 o['offset']==v['offset'] and o['size']==v['size'] and
                 o['kind']==v['kind'] and o['indirect']==v['indirect']]
        if len(options)==1:
            result[v['name']]=options[0]['name'];used.add(options[0]['name'])
    return result


def cards(source):
    result=[]
    for line in source.splitlines():
        while len(line)>72:
            spans=[(m.start(),m.end()) for m in TOKENS.finditer(line)
                   if m[0].startswith(('"',"'",'(*','{','%'))]
            points=[i for i,c in enumerate(line[:73]) if i>0 and
                    (c.isspace() or line[i-1] in ',;') and
                    not any(a<i<b for a,b in spans)]
            if not points:
                raise ValueError('Cannot wrap source card: '+line)
            split=max(points)
            result.append(line[:split].rstrip())
            line='  '+line[split:].lstrip()
        result.append(line)
    return '\n'.join(result)+'\n'


def main():
    source=(PROGRAMS/'link/link.pas').read_text()
    if 'procedure ПEЧBPE(' in source:
        # LINK already carries the PMD-backed names. Keep the original
        # legacy correspondence files as evidence; do not apply them twice.
        source=source.replace('(*=y+,p-,','(*=y+,p+,',1)
        source=source.replace(', stend)',')')
        source=source.replace('program LINK(', 'program ЗAГPYЗ(',1)
        source=source.replace('BEPCИЯ 2.40/3','BEPCИЯ 2.02/3')
        source=source.replace('KOMПOH-3','KOMПOH-1')
        (WORK/'historical-draft.pas').write_text(cards(source))
        print('Wrote draft from LINK with existing historical names')
        return
    old=json.loads((HERE/'inventory.json').read_text())
    new=json.loads((WORK/'reference-pmd.json').read_text())
    mapping=json.loads((HERE/'mapping.json').read_text())
    bindings=json.loads((HERE/'bindings.json').read_text())
    root,nodes,tokens=parse(source)
    previous={t.start():tokens[i-1][0] if i else '' for i,t in enumerate(tokens)}
    oldby={r['name']:r for r in old};newby={r['name']:r for r in new}
    routine={r['modern']:r['candidates'][0][0] for r in mapping if r['candidates']}
    routine.pop('SECTID',None)
    globals=choose(new[-1]['variables'],old[-1]['variables'],bindings['globals'])
    # Confirmed globals whose offsets differ only through removed storage.
    for v in new[-1]['variables']:
        a=int(v['offset'],8)
        if a in [0o64,0o73,0o122] or a>=0o642:
            continue
        delta=(0 if a<0o64 else 1 if a<0o73 else 2 if a<0o122 else 3)
        expected=next((o['name'] for o in old[-1]['variables']
                       if int(o['offset'],8)==a-delta),None)
        if expected:globals[v['name']]=expected
    globals.update(G0544='DEBUG',MONTHDAY='HAЧAЛOME')
    renames={}
    for node in nodes:
        key=node['name'].upper()[:8]
        if node is root:
            node['renames']=globals
        elif not node['external'] and key in routine:
            n,o=newby[key],oldby[routine[key]]
            node['renames']=choose(n['variables'],o['variables'],bindings['locals'].get(key,{}))
        else:
            node['renames']={}
        renames[node['name']]=node['renames']
    replacements={}
    # Enum spellings are supplied by PMD, rather than guessed translations.
    enums=dict(zip(['stzero','stinit','stparse','stgather','stresolve','stplace',
                    'steval','stoutput','stlabels'],
                   ['CYMMA','ШAГИHИЦ','ШAГЗAДAH','ШAГCБOPK','ШAГPAЗPE',
                    'ШAГPAЗME','ШAГBЫЧ','ШAГЗAГP','ШAГГEHME']))
    enums.update(zip(['fmshort','fmprefix','fmword','fmhalf'],
                     ['POБK','POБПФK','POБCЛ','POБПCЛ']))
    enums.update(zip(['same','after','before'],['PB','БЛ','MH']))
    enums.update(zip(['letter','digit','white','punct','atend'],
                     ['БYKBA','ЦИФPA','PAЗЛИT','CПEЦЛИT','ЗAПPЛИT']))
    enums.update(zip(['kalfa','kname','kfile','knumber','kdecimal','kpunct'],
                     ['ИMЯ','ФAЙЛ','YKФAЙЛ','ЦEЛOE','ЧИCЛO','PAЗД']))
    enums.update(zip(['mtcpu','mtwait','mttotal'],['ЦП','KOM','ACTP']))
    for node in nodes:
        for token in node['tokens']:
            word=token[0]
            if token.start() in node['record_tokens']:
                continue
            if not re.fullmatch(r'[A-Za-zА-Яа-я_][A-Za-zА-Яа-я_0-9]*',word):
                continue
            prior=previous[token.start()]
            if prior=='.' and not source[:token.start()].rstrip().endswith('..'):
                continue
            target=None;scope=node
            # Do not rename lowercase record fields under WITH as variables.
            while scope and target is None:
                key=word.upper()[:8]
                if (word.isupper() or re.fullmatch('g[0-7]{4}',word) or
                        word in [t[0] for t in scope['tokens'][:30]]):
                    target=scope['renames'].get(key)
                scope=scope['parent']
            if target is None and word.isupper():
                target=routine.get(word.upper()[:8])
            if target is None:
                target=enums.get(word)
            if target is not None:
                replacements[token.start()]=(token.end(),target)
    for start,(end,text) in sorted(replacements.items(),reverse=True):
        source=source[:start]+text+source[end:]
    source=source.replace('(*=y+,p-,','(*=y+,p+,',1)
    source=source.replace(', stend)',')')
    source=source.replace('BEPCИЯ 2.40/3','BEPCИЯ 2.02/3').replace('KOMПOH-3','KOMПOH-1')
    source=source.replace('% Based on recovered LINK1; names are descriptive (no PMD).',
                          '% Historical names follow 2248 PMD; working reconstruction.')
    (WORK/'historical-draft.pas').write_text(cards(source))
    (HERE/'renames.json').write_text(json.dumps(renames,ensure_ascii=False,indent=2)+'\n')
    print('Wrote historical-name draft; routines',len(nodes),'token replacements',len(replacements))


if __name__=='__main__':
    main()
