"""Where the parts of the project are.

Every script finds files through these names rather than through its own
location, so that moving a part means changing one line here. A script in
runtime/NAME/ imports this module after `sys.path.insert(0, str(HERE.parent))`.

ROOT      the repository
TOOLS     disbesm6, libmatch.py, gostdump.py, cmpimg.py, buildimg.sh
COMPILER  mypas.b6, mylib.b6, pascompl.cc
RUNTIME   the recovered runtime: profiles/, linker-runtime/, file-access/,
          analysis/, sources/ and the reports
PROGRAMS  one directory per recovered program (monitr/, comp/, acc3/, ...)
BUILD     generated output; never tracked
IMAGES    the images extracted from the volumes by corpus.py; never tracked
CORPUS    the inventory of IMAGES
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT
COMPILER = ROOT
RUNTIME = ROOT/'runtime'
PROGRAMS = RUNTIME
BUILD = RUNTIME/'build'
IMAGES = RUNTIME/'images'
CORPUS = RUNTIME/'corpus.json'
