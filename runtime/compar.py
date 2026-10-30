#!/usr/bin/env python3
"""Record runtime recovery evidence from compar.b6 and volume-4001 COMP.

Usage: python3 runtime/compar.py
Writes compar-evidence.json and compar.sym. No application code is executed.
The symbol file supplements the corpus analysis with source-backed helpers and
external entries. See COMPAR.md for the interpretation and recovery priorities.
"""

from collections import defaultdict
import json
from pathlib import Path
import sys

sys.path.insert(0, str(next(p/'py' for p in Path(__file__).resolve().parents
                            if (p/'py/paths.py').exists())))
from paths import ROOT, RUNTIME, CORPUS
from corpus import BASE, pack, read_words, sha
from libmatch import match_at, operand



def main():
    profiles = json.loads((RUNTIME/'profiles.json').read_text())
    corpus = json.loads(CORPUS.read_text())
    record = next(r for r in corpus['images'] if r['id']=='4001-0315-comp')
    words = read_words(RUNTIME/record['path'])
    if sha(pack(words)) != record['sha256']:
        raise ValueError('COMP extract differs from corpus manifest')
    source = (ROOT/'compar.b6').read_text()
    source_lines = source.splitlines()

    def line(fragment):
        return next(i for i,s in enumerate(source_lines,1) if fragment in s)

    def compare(name, profile, lo, hi, target):
        reference = read_words(ROOT/profiles[profile]['source'])
        changes = match_at(reference,words,lo,hi,target-BASE,BASE)
        return dict(name=name,reference=profiles[profile]['source'],
                    reference_range=[f'{lo:05o}',f'{hi:05o}'],
                    range=[f'{target:05o}',f'{target+hi-lo:05o}'],
                    words=hi-lo,match=changes is not None,
                    relocations=changes)

    comparisons = [compare(*args) for args in [
        ('P/STAR','svs',0o3774,0o4006,0o6320),
        ('P/3','svs',0o4016,0o4022,0o6361),
        ('P/31','svs',0o4041,0o4043,0o6600),
        ('P/WC','mark3',0o5361,0o5366,0o6717),
        ('P/6A','svs',0o4037,0o4041,0o6743),
        ('P/A6','mark3',0o5366,0o5375,0o6745)]]

    # P/MI's three words are exactly the standard p_mi.madlen sequence.
    multiply = [0o7400000100310100,0o7412000104110013,0o7412000167000000]
    if words[0o7241-BASE:0o7244-BASE] != multiply:
        raise ValueError('P/MI instruction sequence differs')
    # The equality entry of P/EQ: compare words, advance both pointers,
    # return true on exhaustion and false on the first different word.
    equality = [0o6010000070120000,0o0270673062500001,
                0o7250000157706724,0o0410001067000000,
                0o0010000067000000]
    if words[0o6724-BASE:0o6731-BASE] != equality:
        raise ValueError('P/EQ equality entry differs')
    if words[0o6600-BASE:0o6602-BASE] != [0o3444000316300002,0o1240000067000000]:
        raise ValueError('COMP frame-restore variant differs')

    calls = defaultdict(list)
    for address in range(0o2012,0o4706):
        word = words[address-BASE]
        for side,half in [('L',word>>24),('R',word&0xffffff)]:
            reg,op,target,long = operand(half)
            if long and op==0o31 and target>=0o5663:
                calls[target].append(dict(address=f'{address:05o}',half=side,
                                          register=f'{reg:o}'))

    helpers = [
        ('P/STAR',0o6320,0o6332,'ЛEKCEMA[i] := lf','Packed-element assignment'),
        ('P/31',0o6600,0o6602,'procedure SRAVN','Nested-frame restore; preserves A in COMP'),
        ('P/WC',0o6717,0o6724,"write('I':61)",'Character output with field width'),
        ('P/EQ',0o6724,0o6731,'if A[TKI] <> B[TKJ]','Multiword array equality'),
        ('P/A6',0o6745,0o6754,'ИMЯФ1.name,','ALFA output with field width'),
        ('P/MI',0o7241,0o7244,'K := K * 10','Integer multiplication result')]
    externals = [
        ('E6365',0o6365,'CO := E6365','Read a line from the first legacy text stream'),
        ('E6444',0o6444,'E6444(i)','Initialize the first legacy text stream'),
        ('E6602',0o6602,'CO := E6602','Read a line from the second legacy text stream'),
        ('E6661',0o6661,'E6661(i)','Initialize the second legacy text stream'),
        ('E7036',0o7036,'E7036(* KO','Format a monitor error code into text'),
        ('E7443',0o7443,'KO := E7443','Parse a file specification; arguments are commented out'),
        ('E7667',0o7667,'KO := E7667','Resolve a file descriptor to an address; arguments are commented out')]
    helper_records = [dict(name=name,start=f'{start:05o}',end=f'{end:05o}',
                           words=end-start,source_line=line(fragment),role=role,
                           calls=calls[start])
                      for name,start,end,fragment,role in helpers]
    external_records = [dict(name=name,address=f'{address:05o}',
                             source_line=line(fragment),role=role,calls=calls[address])
                        for name,address,fragment,role in externals]
    api_sources = RUNTIME/'sources/4001'
    include = (api_sources/'dbf.inc.b6').read_text()
    copy = (api_sources/'copy.b6').read_text()
    api = {
        'E7443': dict(name='MKNAME',declaration_source='sources/4001/dbf.inc.b6',
                      declaration_line=43,
                      parameters=['VAR PSTRING','ALFA','ALFA','VAR WORD3'],result='INT',
                      evidence='Include declaration agrees with COMP argument setup and COPY use'),
        'E7667': dict(name='OPENF',declaration_source='sources/4001/dbf.inc.b6',
                      declaration_line=29,
                      parameters=['VAR WORD3','BOOL','VAR INT'],result='INT',
                      evidence='Include declaration agrees with COMP argument setup and COPY use'),
        'E7036': dict(name='ERROR',use_source='sources/4001/copy.b6',use_line=268,
                      declaration_recovered=False,
                      evidence='COPY calls ERROR(KO, TOШ) in the same error-printing wrapper; the include does not declare ERROR')}
    if 'FUNCTION  MKNAME' not in include or 'FUNCTION  OPENF' not in include or 'ERROR ( KO, TOШ )' not in copy:
        raise ValueError('Extracted file-access source anchors changed')
    for external in external_records:
        if external['name'] in api:
            external['api']=api[external['name']]

    ttio=[]
    for address,offset,value in [(0o3775,0o24,1),(0o4672,0o501,6)]:
        if (operand(words[address-BASE]&0xffffff)!=(0,0o22,0o6332,True) or
                words[address+1-BASE]>>24 != 3 or
                words[0o4706+offset-BASE]!=value):
            raise ValueError('TTIO store sequence changed')
        ttio.append(dict(instructions=[f'{address:05o}.L',f'{address:05o}.R',f'{address+1:05o}.L'],
                         constant=f'{0o4706+offset:05o}',value=value,destination='06335'))

    # MONOUT's code is unchanged under relocation; precisely two literal
    # table words differ. MONIN extends the original 24-word table to 32.
    reference = read_words(ROOT/profiles['monitor']['source'])
    for lo,hi,target in [(0o3163,0o3207,0o10455),(0o3255,0o3264,0o10547),
                         (0o3334,0o3416,0o6754)]:
        if match_at(reference,words,lo,hi,target-BASE,BASE) is None:
            raise ValueError('Converter code or P/WO differs beyond relocation')
    output_changes=[]
    for i in range(0o3255-0o3207):
        a,b=reference[0o3207+i-BASE],words[0o10501+i-BASE]
        if a!=b:
            output_changes.append(dict(reference=f'{0o3207+i:05o}',
                                       comp=f'{0o10501+i:05o}',
                                       before=f'{a:016o}',after=f'{b:016o}'))
    if len(output_changes)!=2:
        raise ValueError('Unexpected MONOUT table changes')
    if reference[0o3264-BASE:0o3314-BASE] != words[0o10556-BASE:0o10606-BASE]:
        raise ValueError('MONIN original table prefix differs')
    if words[0o10616-BASE]!=0o377:
        raise ValueError('MONIN mask differs')

    # Only shared runtime constants, excluding the following application globals.
    common_changes=[dict(offset=f'{i:03o}',before=f'{reference[0o2142-BASE+i]:016o}',
                         after=f'{words[0o5457-BASE+i]:016o}')
                    for i in range(40) if reference[0o2142-BASE+i]!=words[0o5457-BASE+i]]
    result=dict(image=record['path'],sha256=record['sha256'],
                source='compar.b6',source_sha256=sha(source.encode()),
                notation='octal addresses, exclusive range ends, decimal word counts',
                helpers=helper_records,externals=external_records,
                api_source_hashes={name:sha((api_sources/name).read_bytes())
                                   for name in ('dbf.inc.b6','copy.b6')},
                cross_profile_comparisons=comparisons,ttio=ttio,
                monout_table_changes=output_changes,
                monin_table=dict(reference=['03264','03314'],comp=['10556','10616'],
                                 shared_prefix_words=24,additional_words=8),
                common_constant_changes=common_changes)
    (RUNTIME/'compar-evidence.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    symbols={tuple(s.split()) for s in (RUNTIME/'analysis/4001-0315-comp.sym').read_text().splitlines()}
    for record in helper_records:
        symbols.add((record['start'],'C',record['name']))
    for record in external_records:
        symbols.add((record['address'],'C',record['name']))
        if 'api' in record:
            symbols.add((record['address'],'C',record['api']['name']))
    symbols.update([('06332','D','*TTIO*'),('06754','C','P/WO'),
                    ('10455','C','MONOUT'),('10547','C','MONIN')])
    (RUNTIME/'compar.sym').write_text(''.join(' '.join(s)+'\n' for s in sorted(symbols)))
    print('Recorded six helper anchors, seven external entries, TTIO stores and converter variants.')


if __name__=='__main__':
    main()
