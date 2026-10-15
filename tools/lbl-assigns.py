#!/usr/bin/env python3
"""lbl-assigns.py: resolve named {assign:} labels for C64List 4.04

    tools/lbl-assigns.py <in.lbl> <out.lbl>
    tools/lbl-assigns.py --test                  run the doctests

C64List 4.06 lets a listing jump to a line outside the file by name:

    {assign:im.rel_record=1}
    ...
    gosub {:im.rel_record}

but 4.06 rejects the numeric assigns in 3_0-preface.lbl ({assign:1=1}), so the
Makefile uses 4.04, which can't find a named assign: it warns "Can't locate
target line" and builds the label as text (gosub [:im.rel_record]).

This replaces each {:name} that names an {assign:} (in the file, or in a file
it pulls in with {uses:} or {include:}, and so on) with its number, and adds
{assign:N=N} for each number at the end of the file, which 4.04 understands.
It leaves alone labels of lines in the file itself ({:name} at the start of a
line), text in "quotes" and rem text.

Exit status: 0 if it wrote <out.lbl>; 3 if there was nothing to replace (no
file written: build <in.lbl> as it is); 1 on an error.

Files are handled as bytes (CR/LF line ends and PETSCII are kept as they are).
"""

import re
import sys
from pathlib import Path

ASSIGN = re.compile(rb'\{assign:([^=}]*)=([^}]*)\}', re.IGNORECASE)
PULLS_IN = re.compile(rb'\{(?:uses|include):([^}]*)\}', re.IGNORECASE)
LABEL = re.compile(rb'\{:([^}]*)\}')
LINE_LABEL = re.compile(rb'^[ \t]*\{:([^}]*)\}[ \t]*$')


def key(name: bytes) -> bytes:
    """C64List labels ignore case, and spaces or tabs around the name.

    >>> key(b'im.Rel_Record\\t')
    b'im.rel_record'
    """
    return name.strip().lower()


def named_assigns(path: Path, seen=None) -> dict:
    """The named assigns in a file and the files it pulls in, as
    {key: number}. Numeric ones ({assign:1=1}) are left out.

    >>> import tempfile, os
    >>> d = Path(tempfile.mkdtemp())
    >>> _ = (d / 'a.lbl').write_bytes(b'{assign:im.get_key\\t=7}\\r\\n{assign:3=3}\\r\\n')
    >>> _ = (d / 'm.lbl').write_bytes(b'{uses:a.lbl}\\r\\n{assign:here=40}\\r\\n')
    >>> sorted(named_assigns(d / 'm.lbl').items())
    [(b'here', 40), (b'im.get_key', 7)]
    """
    if seen is None:
        seen = set()
    path = path.resolve()
    if path in seen:
        return {}
    seen.add(path)
    found = {}
    for line in path.read_bytes().splitlines():
        for m in PULLS_IN.finditer(line):
            other = path.parent / m.group(1).strip().decode('latin-1')
            if other.exists():
                found.update(named_assigns(other, seen))
        for m in ASSIGN.finditer(line):
            name, value = key(m.group(1)), m.group(2).strip()
            if name and not name.isdigit() and value.isdigit():
                found[name] = int(value)
    return found


def code_parts(line: bytes):
    """Splits a line into (text, is_code) pieces: "quoted strings" and
    everything from rem on aren't code.

    >>> code_parts(b'a$="{:x}":gosub {:x}:rem {:x}')
    [(b'a$=', True), (b'"{:x}"', False), (b':gosub {:x}:', True), (b'rem {:x}', False)]
    """
    parts, start, i, quoted = [], 0, 0, False
    while i < len(line):
        c = line[i:i + 1]
        if c == b'"':
            if quoted:
                parts.append((line[start:i + 1], False))
                start = i + 1
            else:
                if i > start:
                    parts.append((line[start:i], True))
                start = i
            quoted = not quoted
        elif not quoted and line[i:i + 3].lower() == b'rem':
            if i > start:
                parts.append((line[start:i], True))
            parts.append((line[i:], False))
            return parts
        i += 1
    if start < len(line):
        parts.append((line[start:], not quoted))
    return parts


def resolve(data: bytes, assigns: dict) -> tuple:
    """Replaces {:name} for each named assign, unless it's a line label in
    this file. Returns the new text and the numbers used.

    >>> resolve(b'{:top}\\r\\n10 gosub {:IM.x}:goto {:top}\\r\\n', {b'im.x': 1, b'top': 9})
    (b'{:top}\\r\\n10 gosub 1:goto {:top}\\r\\n', [1])
    >>> resolve(b'10 print "{:im.x}"\\r\\n', {b'im.x': 1})
    (b'10 print "{:im.x}"\\r\\n', [])
    """
    lines = data.splitlines(keepends=True)
    own = {key(m.group(1)) for line in lines
           if (m := LINE_LABEL.match(line.rstrip(b'\r\n')))}
    used = []

    def number(m):
        k = key(m.group(1))
        if k in assigns and k not in own:
            used.append(assigns[k])
            return str(assigns[k]).encode()
        return m.group(0)

    out = []
    for line in lines:
        if LINE_LABEL.match(line.rstrip(b'\r\n')):
            out.append(line)
            continue
        out.append(b''.join(LABEL.sub(number, text) if is_code else text
                            for text, is_code in code_parts(line)))
    return b''.join(out), sorted(set(used))


def main(argv) -> int:
    if argv[1:] == ['--test']:
        import doctest
        return 1 if doctest.testmod().failed else 0
    if len(argv) != 3:
        print(__doc__.split('\n\n')[1], file=sys.stderr)
        return 1
    src, dst = Path(argv[1]), Path(argv[2])
    data = src.read_bytes()
    new, used = resolve(data, named_assigns(src))
    if not used:
        return 3
    eol = b'\r\n' if b'\r\n' in data else b'\n'
    if not new.endswith(eol):
        new += eol
    new += b"' added by tools/lbl-assigns.py: the numbers of the named assigns used" + eol
    new += b''.join(b'{assign:%d\t=%d\t}' % (n, n) + eol for n in used)
    dst.write_bytes(new)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
