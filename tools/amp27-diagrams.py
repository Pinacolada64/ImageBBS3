#!/usr/bin/env python3
"""amp27-diagrams.py: draw the &,27 / &,28 diagrams in prg-ampersand-calls.adoc

    tools/amp27-diagrams.py docs/images

writes amp27-save-table.svg (what a level holds, and where the 8 levels go
from $13d0) and amp27-levels-example.svg (&,27,3 / dim tt$ / &,27,4 / dim tt$
again / &,28,4 / &,28,3, step by step). Plain SVG attributes, no CSS or
markers, so asciidoctor-pdf's prawn-svg draws them as browsers do.
Image 128's PROGRAMMING.md uses the same two files."""
import sys
from html import escape

OUT = sys.argv[1]
SANS = 'Helvetica, Arial, sans-serif'
MONO = 'Courier New, Courier, monospace'
INK, GRAY, RED, LINE = '#1a1a1a', '#555555', '#b3261e', '#444444'
C_PRG, C_VAR, C_ARR, C_TT, C_N9, C_FREE = '#e6e6e6', '#c9d6e3', '#8fb3d9', '#f2b36b', '#c9a6e3', '#ffffff'


def text(x, y, s, size=11, anchor='start', fill=INK, mono=False, bold=False):
    w = ' font-weight="bold"' if bold else ''
    return (f'<text x="{x}" y="{y}" font-family="{MONO if mono else SANS}" font-size="{size}" '
            f'text-anchor="{anchor}" fill="{fill}"{w}>{escape(s)}</text>')


def rect(x, y, w, h, fill, stroke=LINE, sw=1, dash=None):
    d = f' stroke-dasharray="{dash}"' if dash else ''
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{d}/>'


def line(x1, y1, x2, y2, stroke=LINE, sw=1, dash=None):
    d = f' stroke-dasharray="{dash}"' if dash else ''
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{stroke}" stroke-width="{sw}"{d}/>'


def svg(w, h, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n'
            f'<rect x="0" y="0" width="{w}" height="{h}" fill="#ffffff"/>\n' + '\n'.join(body) + '\n</svg>\n')


def dim_line(x1, x2, y, label, sub=None):
    """a dimension line |----| with its label above"""
    out = [line(x1, y, x2, y), line(x1, y - 5, x1, y + 5), line(x2, y - 5, x2, y + 5),
           text((x1 + x2) / 2, y - 5, label, 11, 'middle', mono=True)]
    return out


# ---------------------------------------------------------------- figure 1
b = []
b.append(text(20, 20, 'What a level holds: two offsets from VARTAB', 13, bold=True))
b += dim_line(170, 330, 44, 'a = ARYTAB - VARTAB')
b += dim_line(170, 520, 66, 's = STREND - VARTAB')
y, h = 78, 34
for x0, x1, fill, l1, l2 in [(20, 170, C_PRG, 'program (im + module)', None),
                             (170, 330, C_VAR, 'simple variables', '7 bytes each'),
                             (330, 520, C_ARR, 'arrays', None),
                             (520, 620, C_FREE, 'free', None),
                             (620, 740, C_PRG, 'strings', None)]:
    b.append(rect(x0, y, x1 - x0, h, fill))
    if l2:
        b.append(text((x0 + x1) / 2, y + 15, l1, 11, 'middle'))
        b.append(text((x0 + x1) / 2, y + 28, l2, 10, 'middle', GRAY))
    else:
        b.append(text((x0 + x1) / 2, y + 21, l1, 11, 'middle'))
for x, name, addr, anchor, col in [(20, 'TXTTAB', None, 'start', GRAY), (170, 'VARTAB', 'C64 $2d, 128 $2f', 'middle', INK),
                                   (330, 'ARYTAB', 'C64 $2f, 128 $31', 'middle', INK),
                                   (520, 'STREND', 'C64 $31, 128 $33', 'middle', INK),
                                   (620, 'FRETOP', None, 'middle', GRAY), (740, 'MEMSIZ', None, 'end', GRAY)]:
    b.append(line(x, y + h, x, y + h + 7))
    b.append(text(x, 133, name, 11, anchor, col, mono=True, bold=(col == INK)))
    if addr:
        b.append(text(x, 147, addr, 10, anchor, GRAY, mono=True))

b.append(text(20, 182, '&,27,n stores s and a at $13d0 + 4 * (n AND 7)', 13, bold=True))
b.append(text(20, 199, '&,28,n puts them back: STREND = VARTAB + s, ARYTAB = VARTAB + a, and moves the saved '
              'arrays down to the new ARYTAB.', 11))
b.append(text(20, 213, 'Everything made since, simple variables and arrays alike, is dropped.', 11))

# brackets over the slots
def bracket(x1, x2, y, label, col):
    return [line(x1 + 2, y, x2 - 2, y, col), line(x1 + 2, y, x1 + 2, y + 6, col), line(x2 - 2, y, x2 - 2, y + 6, col),
            text((x1 + x2) / 2, y - 5, label, 10.5, 'middle', col, bold=True)]

sy = 250
b += bracket(20, 380, sy - 12, 'arryptrs $13d0-$13df: 16 bytes reserved', INK)
b += bracket(380, 650, sy - 12, 'daysofm $13e0-$13eb: days in each month', RED)
b += bracket(650, 740, sy - 12, 'emptym2', GRAY)
uses = [['im 304: after', 'the 1.2 arrays'], ['boot; &,28,1 at', 'main prompt', 'and low memory'],
        ['i/MM.load'], ['idle screen,', 'i/IM.modem'],
        ['overwrites', 'Jan-Apr'], ['overwrites', 'May-Aug'], ['overwrites', 'Sep-Dec'], ['sub.menus', '(4 spare bytes)']]
for i in range(8):
    x = 20 + 90 * i
    bad = 4 <= i <= 6
    fill = '#f6d5d1' if bad else '#e3eedd' if i == 7 else '#dbe8f5'
    b.append(rect(x, sy, 90, 44, fill, RED if bad else LINE, 1.5 if bad else 1))
    b.append(text(x + 45, sy + 18, f'level {i}', 12, 'middle', RED if bad else INK, bold=True))
    b.append(text(x + 45, sy + 34, f'${0x13d0 + 4 * i:04x}', 11, 'middle', GRAY, mono=True))
    for j, u in enumerate(uses[i]):
        b.append(text(x + 45, sy + 60 + 13 * j, u, 10, 'middle', RED if bad else GRAY))

dy = 372
b.append(text(20, dy, 'Each level: 4 bytes, low byte first', 12, bold=True))
for j, lab in enumerate(['+0  s low', '+1  s high', '+2  a low', '+3  a high']):
    b.append(rect(20 + 95 * j, dy + 8, 95, 28, C_VAR if j < 2 else C_ARR))
    b.append(text(20 + 95 * j + 47.5, dy + 27, lab, 11, 'middle', mono=True))
notes = ['Offsets, not addresses: when a module of another',
         'length loads, the variables move and VARTAB with',
         'them, and the saved levels still fit.',
         '&,27 with no level is level 0; only n AND 7 counts.']
for j, n in enumerate(notes):
    b.append(text(420, dy + 4 + 14 * j, n, 10.5, fill=GRAY))
open(f'{OUT}/amp27-save-table.svg', 'w').write(svg(760, 440, b))

# ---------------------------------------------------------------- figure 2
b = []
BX, BW = 250, 490   # the bar: VARTAB at BX


def legend(x, y, fill, label):
    return [rect(x, y - 10, 14, 12, fill), text(x + 19, y, label, 10.5)]

b += legend(20, 18, C_VAR, 'simple variables')
b += legend(140, 18, C_ARR, 'arrays made earlier')
b += legend(275, 18, C_TT, 'tt$()')
b += legend(335, 18, C_N9, 'n9 (7 bytes)')
b += legend(440, 18, C_FREE, 'free')
b.append(text(500, 18, 'V VARTAB   A ARYTAB   S STREND', 10.5, mono=True, fill=GRAY))

V, N9, ARR, TT = 100, 16, 160, 80   # widths


def bar(y, segs, marks, bad=None):
    """segs: (kind, width); marks: letters for VARTAB/ARYTAB/STREND"""
    out, x = [], BX
    fills = {'var': C_VAR, 'n9': C_N9, 'arr': C_ARR, 'tt': C_TT}
    labels = {'var': 'simple variables', 'n9': 'n9', 'arr': 'arrays made earlier', 'tt': 'tt$()'}
    pos = {}
    for kind, w in segs:
        out.append(rect(x, y, w, 24, fills[kind], RED if bad == kind else LINE, 2.5 if bad == kind else 1))
        out.append(text(x + w / 2, y + 16, labels[kind], 9.5 if kind == 'n9' else 11, 'middle', mono=kind in ('tt', 'n9')))
        if kind == 'var':
            pos['V'] = x
        if kind == 'arr':
            pos['A'] = x
        x += w
        pos['S'] = x
    out.append(rect(x, y, BX + BW - x, 24, C_FREE))
    out.append(text((x + BX + BW) / 2, y + 16, 'free', 11, 'middle', GRAY))
    for m in 'VAS':
        out.append(line(pos[m], y + 24, pos[m], y + 31))
        out.append(text(pos[m], y + 42, m, 10.5, 'middle', mono=True, bold=True))
    return out, pos

rows = [
    ('&,27,3', ['level 3 saved: a and s of this moment'], [('var', V), ('arr', ARR)], None),
    ('dim tt$(10)', ['BASIC puts tt$() after the last array'], [('var', V), ('arr', ARR), ('tt', TT)], None),
    ('&,27,4', ['level 4 saved: its s ends after tt$().', 'Nothing is copied: still one tt$()'],
     [('var', V), ('arr', ARR), ('tt', TT)], None),
    ('n9=9', ['a new simple variable: BASIC moves', 'every array up 7 bytes'],
     [('var', V), ('n9', N9), ('arr', ARR), ('tt', TT)], None),
    ('dim tt$(10)', ['?REDIM\'D ARRAY ERROR: BASIC finds the', 'tt$() above. A level hides nothing'],
     [('var', V), ('n9', N9), ('arr', ARR), ('tt', TT)], 'tt'),
    ('&,28,4', ['arrays copied down 7 bytes over n9:', 'n9 dropped, tt$() kept'], [('var', V), ('arr', ARR), ('tt', TT)], None),
    ('&,28,3', ['STREND back to level 3\'s: tt$() dropped,', 'its bytes free again'], [('var', V), ('arr', ARR)], None),
]
y0 = 40
for i, (code, notes, segs, bad) in enumerate(rows):
    y = y0 + 64 * i
    if i:
        b.append(line(20, y - 8, 740, y - 8, '#bbbbbb', 0.5))
    b.append(text(20, y + 16, f'{i + 1}', 12, fill=GRAY, bold=True))
    b.append(text(38, y + 16, code, 12.5, fill=RED if bad else INK, mono=True, bold=True))
    for j, n in enumerate(notes):
        b.append(text(38, y + 32 + 13 * j, n, 10, fill=RED if bad else GRAY))
    out, pos = bar(y + 2, segs, None, bad)
    b += out
    # a level's saved STREND, as a flag above the bar
    if code in ('&,27,3', '&,27,4'):
        lv = code[-1]
        b.append(line(pos['S'], y - 3, pos['S'], y + 26, RED if False else '#2a6f2a', 2))
        b.append(text(pos['S'] + 4, y + 4, f'level {lv}: s', 9.5, fill='#2a6f2a', bold=True))
yb = y0 + 64 * len(rows) + 2
b.append(line(20, yb - 8, 740, yb - 8, '#bbbbbb', 0.5))
b.append(text(20, yb + 8, 'One tt$(), not two: a level saves where the arrays end, not the arrays. '
              'Tested: i.test arrays (Image 3.0), arrays27 (Image 128).', 11, bold=True))
open(f'{OUT}/amp27-levels-example.svg', 'w').write(svg(760, yb + 18, b))
