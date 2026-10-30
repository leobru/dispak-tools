#!/usr/bin/env python3
"""Materialize reviewed SVS runtime layouts in profiles.json.

Usage: python3 runtime/reviewed.py
Ranges are half-open octal core addresses. The gaps are application FORTRAN
routines, not runtime modules. Symbol identifications combine corpus matching,
the recovered programs' call sites, and inspection of the routines themselves.
"""

import json
from pathlib import Path
import sys
sys.path.insert(0, str(next(p/'py' for p in Path(__file__).resolve().parents
                            if (p/'py/paths.py').exists())))
from paths import ROOT,RUNTIME
from corpus import BASE,read_words


def pairs(text):
    return [x.split('-') for x in text.split()]


def profile(image,tag,ranges,code,m1,output,exports,extra_common=None):
    words=read_words(ROOT/image)
    m1,output=int(m1,8),int(output,8)
    common={'P/1D':dict(address=f'{m1:05o}',words=output-m1,reserve=40,initialize=40),
            '*OUTPUT*':dict(address=f'{output:05o}',words=30)}
    common.update(extra_common or {})
    chunks=[dict(name=f'RT{tag}{i}',start=a,end=b)
            for i,(a,b) in enumerate(pairs(ranges),1)]
    names={}
    for item in exports.split():
        name,addr=item.split('=')
        names[name]=f'{int(addr,8):05o}'
    pointers=[]
    for name,address in names.items():
        if name in ('P/00','P/01','P/02','P/03','P/04','P/06','P/07','P/08'):
            table=int(address,8)
            pointers.extend(dict(word=f'{table+i:05o}',shift=0,width=15,
                                 target=f'{words[table+i-BASE]:05o}') for i in (3,4))
    return dict(image='root-'+Path(image).stem,source=image,
                runtime=[chunks[0]['start'],chunks[-1]['end']],chunks=chunks,
                common=common,code=pairs(code),exports=names,
                data_relocations=pointers,fixed_addresses=['02007'],core_helpers=[],
                compiler_prefix='(*=a1*)',
                notes=['Preserved the observed SVS I/O and startup implementation.',
                       'Excluded application FORTRAN routines between runtime chunks.',
                       'P/1D reserves only 050 words for new programs; golden layout reserves the original globals.',
                       'Word 02007 is the PASCODER stack descriptor supplied by the launch deck.'])


def main():
    path=RUNTIME/'profiles.json'
    profiles=json.loads(path.read_text())
    profiles['svs']=profile('тестац.bin','TS',
        '03710-03745 03745-04067 04067-04233 04245-04354',
        '''03710-03745 03774-04064 04067-04165 04174-04224
        04225-04233 04245-04263 04270-04302 04304-04306
        04310-04324 04330-04335 04336-04340 04345-04347''',
        '03516','03652',
        '''P/2=3710 P/IN=3714 P/EO=3724 P/GF=3725 P/EF=3737 P/E=3742
        P/08=3745 P/STAR=3774 P/LDAR=4006 P/3=4016 P/RF=4022 P/CW=4032
        P/TF=4034 P/6A=4037 P/31=4041 P/RC=4043 P/WOLN=4067 P/WL=4070
        P/7A=4076 P/7AD=4100 P/WI=4113 P/WO=4174 P/A7=4225
        P/CO=4245 P/IT=4252 P/1=4254 P/PF=4271 P/RET=4270
        P/PRINT=4304 P/HIDE=4310 P/EDIH=4313 P/SP=4316
        P/PUTADR=4331 P/PUTERR=4336 P/OVERFL=4345 STOP*=4330''')
    profiles['mark3']=profile('mark3.bin','MK',
        '04755-05012 05012-05134 05134-05143 05336-05507 05507-05616',
        '''04755-05012 05041-05131 05134-05143 05336-05447
        05456-05506 05507-05525 05532-05544 05546-05550
        05552-05566 05572-05577 05600-05602 05607-05611''',
        '04507','04717',
        '''P/2=4755 P/IN=4761 P/EO=4771 P/GF=4772 P/EF=5004 P/E=5007
        P/08=5012 P/STAR=5041 P/LDAR=5053 P/3=5063 P/RF=5067 P/CW=5077
        P/TF=5101 P/6A=5104 P/31=5106 P/RC=5110 P/WOLN=5134 P/WL=5135
        P/7A=5336 P/7AD=5340 P/A7=5353 P/WC=5361 P/A6=5366 P/WI=5375
        P/WO=5456 P/CO=5507 P/IT=5514 P/1=5516 P/PF=5533 P/RET=5532
        P/PRINT=5546 P/HIDE=5552 P/EDIH=5555 P/SP=5560
        P/PUTADR=5573 P/PUTERR=5600 P/OVERFL=5607 STOP*=5572''')
    profiles['pak']=profile('pak.bin','PK',
        '10752-11014 11014-11244 11244-11410 11436-11445 11454-11563',
        '''10752-10764 10777-11030 11101-11155 11164-11220 11221-11271 11307-11342 11373-11410
        11436-11445 11454-11472 11474-11477 11501-11507
        11511-11521 11526-11536 11537-11542 11547-11551 11556-11562''',
        '10136','10713',
        '''P/2=10752 P/EF=10756 P/E=10761 P/07=10764 P/LDARIN=10777 P/CW=11007
        P/TF=11011 P/WOLN=11014 P/WL=11015 P/WC=11023 P/04=11030 P/6A=11101 P/WI=11103
        P/3=11164 P/WO=11170 P/RF=11221 P/EO=11231 P/GF=11232
        P/7A=11244 P/7AD=11246 P/SS=11261 P/31=11263 P/00=11271 P/RR=11307 P/STAR=11320 P/IN=11332
        P/08=11342 P/A7=11373 P/CO=11401 P/IT=11406 P/A6=11436
        P/1=11454 P/PF=11461 P/RET=11474 P/PRINT=11475 P/SP=11501
        P/HIDE=11511 P/EDIH=11514 P/LDAR=11526 P/PUTERR=11540
        P/OVERFL=11547 P/PUTADR=11556 STOP*=11537''',
        {'PASEOLSY':dict(address='10751',words=1,initialize=1)})
    path.write_text(json.dumps(profiles,ensure_ascii=False,indent=2)+'\n')


if __name__=='__main__':
    main()
