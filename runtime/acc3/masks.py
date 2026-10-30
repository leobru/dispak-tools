"""Print the pool words of ov1/ov2 at M10 offsets as field ranges.

Usage: python3 runtime/acc3/masks.py ov2 540 561 ...   (octal offsets)
For a keep-mask of a packed field store (old ^ ((old ^ new) & mask) ^ ...)
the field is the complement: printed as 'field' bit ranges (1 = LSB).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from paths import BUILD
POOL = {'ov1': 0o17731, 'ov2': 0o31346}
part = sys.argv[1]
d = (BUILD/'acc3'/(part + '.bin')).read_bytes()
def ranges(v):
    out, i = [], 1
    while i <= 48:
        if v >> (i - 1) & 1:
            j = i
            while j < 48 and v >> j & 1: j += 1
            out.append(f'{i}-{j}' if j > i else str(i)); i = j + 1
        else: i += 1
    return ' '.join(out)
for o in sys.argv[2:]:
    a = POOL[part] + int(o, 8); k = (a - 0o4000) * 6
    v = int.from_bytes(d[k:k+6], 'big')
    print(o, format(v, '016o'), 'set:', ranges(v), '| field:', ranges(~v & (1 << 48) - 1))
