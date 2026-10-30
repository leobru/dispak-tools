"""Where the parts of the project are.

Every script finds files through these names rather than through its own
location, so that moving a part means changing one line here. A script in
another directory finds this module by searching upwards from its own place:

    sys.path.insert(0, str(next(p/'py' for p in HERE.parents
                                if (p/'py/paths.py').exists())))

ROOT      the repository
TOOLS     disbesm6, buildimg.sh and the other C, shell and Perl tools
PY        the shared Python modules: this one, corpus.py, libmatch.py,
          recover.py, build.py and check.py (the runtime builds),
          gostdump.py, cmpimg.py, regress.py, fixpoint.py
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
TOOLS = ROOT/'tools'
PY = ROOT/'py'
COMPILER = ROOT/'compiler'
RUNTIME = ROOT/'runtime'
PROGRAMS = ROOT/'programs'
BUILD = ROOT/'build'
IMAGES = RUNTIME/'images'
CORPUS = RUNTIME/'corpus.json'
