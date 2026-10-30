#!/usr/bin/env python3
"""Regenerate the complete preliminary, non-compilable Pascal/assembler lift.

Usage: python3 programs/pak/lift.py
Requires dtran (make -C tools dtran) and tools/decomp.pl; decomp.pl reads
routines.txt and globals.txt of this directory.
The output deliberately retains unresolved instructions; pak.pas contains
only the separately recompiled and compared recovery.
"""
from pathlib import Path
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                            if (p/'py/paths.py').exists())))
from paths import TOOLS, BUILD
work=BUILD/'pak'
work.mkdir(parents=True,exist_ok=True)
run=subprocess.run([str(TOOLS/'dtran'),'-d','-f','02000',str(work/'pak.bin')],
                   check=True,capture_output=True,text=True)
(work/'dtran.log').write_text(run.stderr)
(work/'pak.dtran').write_text(run.stdout)
# The pool begins at absolute 07237 = decimal 3743 in dtran's data labels.
s=run.stdout.split(' /3743:',1)[0]
s='\n'.join(line for line in s.splitlines() if not line.startswith('C '))+'\n'
for line in (HERE/'pak.sym').read_text().splitlines():
    if not line or line.startswith('#'):
        continue
    address,kind,name=line.split()
    s=re.sub(r'\bL'+address.lstrip('0')+r'\b',lambda _:name,s)
s=s.replace('12,VTM,4543','12,VTM,OUTPUT').replace('12,VTM,4220','12,VTM,IO')
s=s.replace(',YTA,64+0',',YTA,64')
run=subprocess.run(['perl',str(TOOLS/'decomp.pl')],cwd=HERE,input=s,
                   check=True,capture_output=True,text=True)
(work/'lift.log').write_text(run.stderr)
header=('PRELIMINARY LIFT OF THE COMPLETE USER CODE 02012-07236\n'
        'Not compilable Pascal. Unresolved instructions and tentative types\n'
        'are retained explicitly. Labels are octal, gNNz/frame offsets are\n'
        'decimal in this older tool. Guessed strings can have wrong encoding.\n'
        'The verified source recovery is in pak.pas.\n\n')
(HERE/'pak.decomp').write_text(header+run.stdout)
print(HERE/'pak.decomp')
