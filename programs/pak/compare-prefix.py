#!/usr/bin/env python3
"""Compare recovered routines with PAK, resolving pool/library addresses.

Usage: python3 programs/pak/compare-prefix.py [--edition 2053|2113]
       [--routines-only | --main-end=OCTAL]
No instruction omissions or fuzzy subsequence matches are accepted.
"""
import argparse
import difflib
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import BUILD
WORK=BUILD/'pak'
from libmatch import words,operand
from pak_symbols import load_symbols

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--edition',choices=['2053','2113'],default='2053')
p.add_argument('--main-end',type=lambda s:int(s,8),default=None,
               help='compare a recovered main prefix up to this octal address')
p.add_argument('--routines-only',action='store_true',
               help='check the 29 complete routines and monitor wrappers')
args=p.parse_args()

NAMES=['relink','readsys','repeatc','newline','rule','blank','endrule','print12','digits',
       'date','time','duration','flag','status','octstat','flush','pad','heading','mark','volume','volist','task','install','mounts','channels','machine','bits','bank','queue']
STARTS=[0o2026,0o2304,0o2325,0o2337,0o2357,0o2365,0o2377,0o2410,0o2423,
        0o2444,0o2474,0o2532,0o2570,0o2577,0o2703,0o2733,0o2747,0o2766,0o3144,0o3202,0o3243,0o3334,0o4410,0o4455,0o4640,0o5074,0o5422,0o5461,0o5565]
new=args.edition=='2113'
mainstart,mainend,tpool,tfile=(0o5710,0o7250,0o7255,0o5675) if new else (0o5721,0o7232,0o7237,0o2013)
if args.main_end is None: args.main_end=mainend
if new:
    STARTS=[int(a,8) for a in '2013 2272 2310 2322 2342 2350 2362 2373 2406 2427 2457 2515 2553 2562 2655 2706 2722 2741 3117 3152 3213 3305 4355 4422 4605 5044 5372 5431 5540'.split()]
ENDS=STARTS[1:]+[tfile if new else mainstart]
stem='pak-2113' if new else 'pak'
work=WORK/(stem+('-newpasc' if new else '-pascal'))
cw=words(work/'image.bin');tw=words(WORK/(stem+'.bin'))
cs={s.name:s.address for s in load_symbols(work/'listing.txt')}
ts={line.split()[2]:int(line.split()[0],8)
    for line in (HERE/(stem+'.sym')).read_text().splitlines()
    if line and not line.startswith('#')}

def find_starts(w,symbols):
    out=[]
    for i,word in enumerate(w):
        for half,h in enumerate((word>>24,word&0xffffff)):
            r,op,a,l=operand(h)
            if l and r==0o16 and op==0o31 and a in (
                    symbols['P/2'],symbols['P/3']):
                # Parameter store, or ATX/UTM for multiple arguments.
                j=i*2+half-1
                if not half and operand(w[i-1]&0xffffff)[:2]==(0o17,0o25):
                    j-=1
                prev=operand((w[j//2]>>(0 if j%2 else 24))&0xffffff)
                if prev[0]==0o17 and prev[1]==0:
                    out.append(0o2000+j//2)
                else:
                    out.append(0o2000+i)
    return out

starts=find_starts(cw,cs)
if len(starts)!=len(NAMES):
    raise ValueError(f'Expected {len(NAMES)} routines, found {starts}')
pool=(cw[0o12]>>24)&0o77777
# Startup ends with UJ main; it gives the end of the QUEUE body.
lastend=cw[pool-1-0o2000]&0o77777
startup=cw[0o12]&0o77777
cfile=(cw[startup+1-0o2000]&0o77777) if new else 0o2013
cends=starts[1:]+[cfile if new else lastend]

def sequence(w,start,end,pool,syms,entries):
    reverse={v:k for k,v in syms.items() if not k.startswith('PAKRT')}
    if 'P/1' in syms:
        reverse[syms['P/1']]='P/1'
    reverse[syms['P/1D']+0o54]='IO'
    reverse[pool]="constants"
    reverse.update(entries)
    result=[]
    for a in range(start,end):
        word=w[a-0o2000]
        for side,h in enumerate((word>>24,word&0xffffff)):
            r,op,v,long=operand(h)
            val=v
            if (long and r==0o13 and op==0o24 and
                    pool<=v<syms['P/1D']):
                nr,no,nv,nl=operand((word&0xffffff) if side==0
                    else (w[a+1-0o2000]>>24))
                if nr==0o12 and no==0o24:
                    data=b''.join(q.to_bytes(6,'big') for q in
                                  w[v-0o2000:v-0o2000+(nv+5)//6])
                    val=('text',data[:nv].hex())
            elif r==0o10 and not long and op<=0o27:
                off=v if v<0o70000 else v-0o100000
                val=('pool',f'{w[pool+off-0o2000]:016o}')
            elif long and v in reverse and op in (0o22,0o24,0o26,0o27,0o30,0o31,0o37):
                val=reverse[v]
            elif long and start<=v<=end and op in (0o24,0o26,0o27,0o30,0o31,0o37):
                val=('local',v-start)
            if (long and isinstance(val,int) and
                    syms['P/1D']<=v<syms['*OUTPUT*']):
                val=('global',v-syms['P/1D'])
            result.append((f'{a:05o}{"LR"[side]}',(r,op,long,val)))
    return result

if not args.routines_only:
    startup=cw[0o12]&0o77777
    NAMES.append('main'); STARTS.append(mainstart)
    ENDS.append(args.main_end); starts.append(lastend)
    cends.append(startup if args.main_end==mainend else
                 lastend+args.main_end-mainstart)

report=[]
for name,tstart,tend,cstart,cend in zip(NAMES,STARTS,ENDS,starts,cends):
    t=sequence(tw,tstart,tend,tpool,ts,dict(zip(STARTS,NAMES)))
    c=sequence(cw,cstart,cend,pool,cs,dict(zip(starts,NAMES)))
    diffs=[]
    for tag,i,j,k,l in difflib.SequenceMatcher(None,
            [repr(x[1]) for x in t],[repr(x[1]) for x in c],
            autojunk=False).get_opcodes():
        if tag!='equal':
            diffs.append(dict(tag=tag,target=t[i:j],candidate=c[k:l]))
    row=dict(name=name,target=f'{tstart:05o}',candidate=f'{cstart:05o}',
             target_words=tend-tstart,candidate_words=cend-cstart,
             exact_normalized=not diffs,differences=diffs)
    report.append(row)
    print(f'{name:10s} {tstart:05o} {cstart:05o} '
          f'{tend-tstart:3d}/{cend-cstart:3d} '
          f'{"MATCH" if not diffs else str(len(diffs))+" differing blocks"}')

# These recovered extracode wrappers have no relocated operands.
for name,length in [('DECODEID',4),('SYSTIME',2)]:
    a=cs[name]-0o2000
    b=ts[name]-0o2000
    if cw[a:a+length]!=tw[b:b+length]:
        raise SystemExit(f'{name} differs from the original {length} words')
    print(f'{name.lower():10s} {ts[name]:05o} {cs[name]:05o} '
          f'{length:3d}/{length:3d} MATCH (raw)')

# Private labels of the recovered SETBYTE object. Its helper follows
# the entry and data in the reconstruction; the original places it first.
cs['main']=lastend
cs['FILEINIT']=cfile
ts['FILEINIT']=tfile
cs['startup']=pool-5
ts['startup']=mainend
cs['entry']=ts['entry']=0o2012
cs['SBPACK']=cs['SETBYTE']-4
cs['SBMASK']=cs['SETBYTE']+3
for name,length,baseoff in [('SAVEMASK',6,1),('SETBYTE',3,None),
                            ('SBPACK',4,None),('SETBANK',6,0),
                            ('FILEINIT',11 if new else 13,None),('startup',5,None),
                            ('entry',1,None)]:
    tp=tpool if baseoff is None else ts[name]+baseoff
    cp=pool if baseoff is None else cs[name]+baseoff
    t=sequence(tw,ts[name],ts[name]+length,tp,ts,{})
    c=sequence(cw,cs[name],cs[name]+length,cp,cs,{})
    diffs=[]
    for i,(left,right) in enumerate(zip(t,c)):
        if left[1]!=right[1]:
            diffs.append(dict(target=[left],candidate=[right]))
    report.append(dict(name=name.lower(),target=f'{ts[name]:05o}',
        candidate=f'{cs[name]:05o}',target_words=length,
        candidate_words=length,exact_normalized=not diffs,differences=diffs))
    print(f'{name.lower():10s} {ts[name]:05o} {cs[name]:05o} '
          f'{length:3d}/{length:3d} '+('MATCH' if not diffs else 'DIFF'))
for name,off,length in [('SAVEMASK',6,2),('SETBYTE',3,2),('SETBANK',6,1)]:
    a=cs[name]+off-0o2000
    b=ts[name]+off-0o2000
    if cw[a:a+length]!=tw[b:b+length]:
        raise SystemExit(f'{name} embedded constants differ')

# DATA is checked as raw words; IO and the library commons are separate.
data_diff=[]
checked=0
for lo,hi in [(0o50,0o54),(0o112,0o555 if new else 0o557)]:
    for off in range(lo,hi):
        t=tw[ts['P/1D']+off-0o2000]
        c=cw[cs['P/1D']+off-0o2000]
        checked+=1
        if t!=c:
            data_diff.append(dict(offset=f'{off:03o}',
                                  target=f'{t:016o}',candidate=f'{c:016o}'))
report.append(dict(name='initial-data',target_words=checked,
    candidate_words=checked,exact_normalized=not data_diff,
    differences=data_diff))
print(f'initial-data {checked}/{checked} '+('MATCH (raw)' if not data_diff else 'DIFF'))

(WORK/(('2113-' if new else '')+'prefix-comparison.json')).write_text(
    json.dumps(report,ensure_ascii=False,indent=2)+'\n')
if any(not row['exact_normalized'] for row in report):
    raise SystemExit('Recovered code differs; see build/pak/'+('2113-' if new else '')+'prefix-comparison.json')
