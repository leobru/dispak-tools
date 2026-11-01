#!/usr/bin/env python3
"""Indent a decompiled NEWPASC source without moving its line numbers.

Usage: pasindent.py src.pas [out.pas]   (in place without out.pas)

`_(` and `_)` stand for begin and end and are kept as written; comments
in bodies (options such as (*=m-*)) stay before the statement they
precede.

The compiler encodes the line of each routine's `begin` (counting `%`
lines, not empty ones).  These lines are anchors: every anchor keeps its
number.  Between two anchors lie the previous body, the declarations
before the next body and lines that are only `%` (padding).  The body is
laid out one statement per line with indentation; it may use the padding
lines, and is compressed (adjacent lines joined) when it does not fit;
the last body (the main program) is never compressed.
Leftover padding goes after the body, then the declarations,
indented by nesting level.  Text before the first anchor is
copied unchanged.  Each anchor `begin` is followed by a comment with its
line number, (*169*); old markers are dropped and written anew.  Rebuild
afterwards and compare the image.
"""
import re
import sys

W = 72
STEP = 2
KEYWORDS = {'begin', 'end', 'if', 'then', 'else', 'while', 'do', 'for',
            'repeat', 'until', 'case', 'of', 'select', 'with', 'record',
            'procedure', 'function', 'fortran', 'external', 'forward'}
TOKEN = re.compile(r"""\s+|^%[^\n]*|'(?:[^']|'')*'|\(\*.*?\*\)|_\(|_\)|
                       :=|<=|>=|<>|\.\.|
                       [A-Za-zА-Яа-яЁё_][\wА-Яа-яЁё]*|[0-9][0-9A-Za-z]*|.""",
                   re.X | re.S | re.M)


class Tok:
    def __init__(self, text, pos, line):
        self.text, self.pos, self.line = text, pos, line
        self.low = {'_(': 'begin', '_)': 'end'}.get(text, text.lower())
        self.end = pos + len(text)


def tokenize(text):
    toks, line = [], 1
    for m in TOKEN.finditer(text):
        s = m.group()
        # Comments are kept (options, notes), except the line markers.
        if not s.isspace() and not s.startswith('%') and \
                not re.fullmatch(r'\(\*\d+\*\)', s):
            toks.append(Tok(s, m.start(), line))
        line += s.count('\n')
    return toks


class Body:
    """Lays out the statements of one body as (indent, text) lines."""

    def __init__(self, src, toks, i):
        self.src, self.t, self.i, self.out = src, toks, i, []

    def peek(self, k=0):
        return self.t[self.i + k].low if self.i + k < len(self.t) else ''

    def span(self, a, b):
        """Source text of tokens a..b-1, whitespace collapsed."""
        if a >= b:
            return ''
        s = self.src[self.t[a].pos:self.t[b - 1].end]
        return ''.join(p if p.startswith("'") else re.sub(r'\s+', ' ', p)
                       for p in re.split(r"('(?:[^']|'')*')", s))

    def scan(self, stops, colon=False):
        """Advance to a stop word at bracket depth 0; return the start."""
        a, depth = self.i, 0
        while self.i < len(self.t):
            w = self.peek()
            if w in '([':
                depth += 1
            elif w in ')]':
                depth -= 1
            elif depth == 0 and (w in stops or (colon and w == ':')):
                break
            self.i += 1
        return a

    def emit(self, ind, text):
        self.out.append([ind, text])

    def attach(self, text):
        if self.out[-1][1].endswith(':='):
            text = ' ' + text
        self.out[-1][1] += text

    def label(self):
        if self.peek() == '(' and self.peek(2) == ')':
            self.i += 3
            return self.span(self.i - 3, self.i) + ' '
        return ''

    def stmt(self, ind, head):
        """One statement; head is text that precedes it on its line."""
        while self.peek().startswith('(*'):
            head += self.t[self.i].text + ' '
            self.i += 1
        head += self.label()
        w = self.peek()
        if w == 'begin':
            self.emit(ind, head + self.t[self.i].text)
            self.i += 1
            self.seq(ind + STEP, {'end'})
            self.emit(ind, self.t[self.i].text)
            self.i += 1
        elif w in ('if', 'while', 'for', 'with'):
            stop = 'then' if w == 'if' else 'do'
            a = self.scan({stop})
            self.i += 1
            self.branch(ind, head + self.span(a, self.i))
            if w == 'if' and self.peek() == 'else':
                self.i += 1
                if self.peek() == 'if':
                    self.stmt(ind, 'else ')
                else:
                    self.branch(ind, 'else')
        elif w == 'repeat':
            self.i += 1
            self.emit(ind, head + 'repeat')
            self.seq(ind + STEP, {'until'})
            a = self.i
            self.i += 1
            self.scan({';', 'end', 'else', 'until'})
            self.emit(ind, self.span(a, self.i))
        elif w in ('case', 'select'):
            if w == 'case':
                a = self.scan({'of'})
                self.i += 1
            else:
                a, self.i = self.i, self.i + 1
            self.emit(ind, head + self.span(a, self.i))
            while self.peek() != 'end':
                if self.peek() == ';':
                    self.i += 1
                    self.attach(';')
                    continue
                a = self.scan({';', 'end'}, colon=True)
                self.i += 1
                self.stmt(ind + STEP, self.span(a, self.i) + ' ')
            self.emit(ind, self.t[self.i].text)
            self.i += 1
        elif w in (';', 'end', 'else', 'until', ''):
            if head.strip():
                self.emit(ind, head.rstrip())
        else:
            a = self.scan({';', 'end', 'else', 'until'})
            self.emit(ind, head + self.span(a, self.i))

    def branch(self, ind, head):
        """head ends with then/do/else: a block stays on its line."""
        save = self.i
        lab = self.label()
        if self.peek() == 'begin':
            self.stmt(ind, head + ' ' + lab)
        elif self.peek() in (';', 'end', 'else', 'until'):
            self.emit(ind, head + (' ' + lab.rstrip() if lab else ''))
        else:
            self.i = save
            self.emit(ind, head)
            k = len(self.out)
            self.stmt(ind + STEP, '')
            # A single-line statement goes on the line of its head.
            if len(self.out) == k + 1 and \
                    ind + len(head) + 1 + len(self.out[k][1]) <= W:
                self.out[k - 1][1] += ' ' + self.out.pop()[1]

    def seq(self, ind, stops):
        while self.peek() not in stops:
            if self.peek() == ';':
                self.i += 1
                self.attach(';')
                continue
            self.stmt(ind, '')


def wrap(ind, text, w=W):
    """Split a line longer than w at spaces outside strings."""
    orig, lines, pre = text, [], ' ' * ind
    while len(pre) + len(text) > w:
        # Cut late, at a small bracket depth: the score is 20 per level
        # minus the position.
        q, depth, cut, best = False, 0, -1, None
        for k, c in enumerate(text[:w - len(pre) + 1]):
            if c == "'":
                q = not q
            elif q:
                continue
            elif c in '([':
                depth += 1
            elif c in ')]':
                depth -= 1
            elif c == ' ' and k > 0 and (best is None or
                                         20 * depth - k <= best):
                cut, best = k, 20 * depth - k
        if cut <= 0:
            break
        lines.append(pre + text[:cut])
        text = text[cut + 1:]
        if len(lines) == 1:
            pre += ' ' * STEP
    lines.append(pre + text)
    # Do not leave a lone "then" or "do": cut earlier.
    if len(lines) > 1 and ' ' not in text and w > W - 20:
        return wrap(ind, orig, w - 4)
    return lines


OPENS = ('begin', 'then', 'do', 'else', 'of', 'repeat', 'select')


def norm(l):
    """The line with _( and _) read as begin and end."""
    return re.sub(r'_\(', ' begin ', re.sub(r'_\)', ' end ', l)).lower()


def indent(l):
    return len(l) - len(l.lstrip())


def lastword(l):
    return (re.split(r'\W+', norm(l).rstrip(' ;')) or [''])[-1]


def cost(a, b):
    """Preference for joining line b to a: smaller is better."""
    ia, ib = len(a) - len(a.lstrip()), len(b) - len(b.lstrip())
    last, blast, first = lastword(a), lastword(b), norm(b).split()[0]
    if last in ('then', 'do', 'else') and ib > ia:
        return 0
    if first in ('end', 'until'):
        return 1
    if ia == ib and last not in OPENS + ('end',) and blast not in OPENS:
        return 2
    if last == 'begin' and ib > ia and blast not in OPENS:
        return 3
    return 4


def fit(rows, budget):
    """Render rows into at most budget lines, joining when needed."""
    lines = [l for ind, t in rows for l in wrap(ind, t)]
    while len(lines) > budget:
        # First whole blocks "... begin" .. "end" and single statements
        # after then/do/else go onto one line, the shortest first.
        best = None
        for k in range(len(lines) - 1):
            ik = indent(lines[k])
            last = lastword(lines[k])
            m = None
            if last == 'begin':
                for m in range(k + 1, len(lines)):
                    if indent(lines[m]) <= ik:
                        break
                if not (indent(lines[m]) == ik and
                        norm(lines[m]).split()[0].startswith('end')):
                    continue
            elif last in ('then', 'do', 'else'):
                m = k + 1
                if indent(lines[m]) <= ik or (m + 1 < len(lines) and
                                              indent(lines[m + 1]) > ik and
                                              not norm(lines[m + 1])
                                              .split()[0] == 'else'):
                    continue
            else:
                continue
            j = ' '.join([lines[k]] + [l.lstrip() for l in lines[k + 1:m + 1]])
            if len(j) <= W and (best is None or len(j) < best[0]):
                best = (len(j), k, m, j)
        if best is None:
            break
        lines[best[1]:best[2] + 1] = [best[3]]
    while len(lines) > budget:
        best = None
        for k in range(len(lines) - 1):
            j = lines[k] + ' ' + lines[k + 1].lstrip()
            c = (cost(lines[k], lines[k + 1]), len(j))
            if len(j) <= W and (best is None or c < best[0]):
                best = (c, k)
        if best is None:
            return None
        k = best[1]
        lines[k:k + 2] = [lines[k] + ' ' + lines[k + 1].lstrip()]
    # A body squeezed to "begin s" + "end": one line if it fits.
    if len(lines) == 2 and norm(lines[0]).split()[0] == 'begin' and \
            len(norm(lines[0]).split()) > 1 and \
            norm(lines[1]).split()[0].startswith('end') and \
            len(lines[0]) + len(lines[1].lstrip()) < W:
        lines = [lines[0] + ' ' + lines[1].lstrip()]
    return lines


def main():
    path = sys.argv[1]
    src = open(path, encoding='utf-8').read()
    lines = src.split('\n')
    toks = tokenize(src)
    # Find bodies: (anchor line, end line, nesting level).
    bodies, level, i, heads = [], 0, 0, {}
    while i < len(toks):
        w = toks[i].low
        if w in ('procedure', 'function'):
            heads[toks[i].line] = level + 1
            depth = 0
            while not (toks[i].low == ';' and depth == 0):
                depth += toks[i].low == '('
                depth -= toks[i].low == ')'
                i += 1
            if toks[i + 1].low in ('fortran', 'external', 'forward'):
                i += 2
            else:
                level += 1
        elif w == 'record':
            depth = 1
            while depth:
                i += 1
                depth += toks[i].low in ('record', 'case')
                depth -= toks[i].low == 'end'
        elif w == 'begin':
            b = Body(src, toks, i)
            b.stmt(0, '')
            end = toks[b.i - 1]
            bodies.append((toks[i], end, level, b.out, b.i))
            i = b.i
            level -= 1
        i += 1
    out = lines[:bodies[0][0].line - 1]
    fails = []
    for n, (beg, end, lev, rows, ti) in enumerate(bodies):
        base = STEP * max(lev - 1, 0)
        rows = [[base + ind, t] for ind, t in rows]
        num = sum(1 for l in lines[:beg.line] if l.strip())
        rows[0][1] += ' (*%d*)' % num
        tail = lines[end.line - 1][end.end - (src.rfind('\n', 0, end.pos) + 1):]
        if n + 1 < len(bodies):
            assert not re.search(r'\w', tail), (end.line, tail)
        rows[-1][1] += tail.rstrip()
        nxt = bodies[n + 1][0].line if n + 1 < len(bodies) else len(lines) + 1
        between = lines[end.line:nxt - 1]
        decl, lev = [], None
        for k, l in enumerate(between):
            if l.strip() not in ('', '%'):
                lev = heads.get(end.line + 1 + k, lev)
                decl.append([lev, l.strip()])
        for d in reversed(decl):
            lev = d[0] = d[0] or lev
        pad = sum(l.strip() == '%' for l in between)
        budget = end.line - beg.line + 1 + pad
        if n + 1 == len(bodies):
            budget = 10 ** 6    # nothing after the last anchor
        body = fit(rows, budget)
        if body is None:
            fails.append(beg.line)
            body = lines[beg.line - 1:end.line]
        depth, ds = 0, []
        for lv, l in decl:
            pre = ' ' * (STEP * max((lv or 1) - 1, 0) + 4 * (depth > 0))
            ds.append(pre + l)
            plain = re.sub(r"'[^']*'", '', l)
            depth += plain.count('(') - plain.count(')')
        decl = ds
        decl = [l if len(l) <= W else l.lstrip() for l in decl]
        if n + 1 < len(bodies):
            body += ['%'] * (budget - len(body))
        out += body
        if n + 1 < len(bodies):
            out += decl
        else:
            out += between
    open(sys.argv[2] if len(sys.argv) > 2 else path, 'w',
         encoding='utf-8').write('\n'.join(out))
    if fails:
        print('kept as is (no fit): lines', fails)


if __name__ == '__main__':
    main()
