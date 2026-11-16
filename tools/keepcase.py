#!/usr/bin/env python3
"""keepcase.py: keep $61-$7a capitals in "strings" as they are (for detok.sh)

    tools/keepcase.py <orig.prg> < listing.lbl > listing.lbl

C64List (-alpha:alt) writes a capital letter in a "string" as an ASCII
capital, whether the program has it as $c1-$da (the usual capitals) or as
$61-$7a (which also show as capitals, in lower/upper case mode). Both build
as $c1-$da, and {$64} builds as $44 too, so a program with $61-$7a capitals
in its strings wouldn't rebuild as it was.

Under {alpha:ascii}, C64List builds each character in a string as its own
byte (keywords and variable names build as under {alpha:alt}). So a line
whose strings have $61-$7a capitals is put between {alpha:ascii} and
{alpha:alt}, with a comment, and its strings written as the program's bytes:
$41-$5a (lower case on the C64) as A-Z, $61-$7a (capitals) as a-z, and
$c1-$da as {$xx}. Those strings read with their case swapped.

A {name} token in a string is one byte, {name:n} is n bytes, and is kept.
Text after rem is left alone. A line whose strings don't line up with the
original's is left as it is; detok.sh's rebuild check catches anything wrong.
"""

import re
import sys

REM = 0x8F
TOKEN = re.compile(rb'\{([^}:]*)(?::(\d+))?\}')
NOTE = (b"' (next line, {alpha:ascii}: its strings use $61-$7a capitals; here they're in",
        b"' lower case, and the strings' lower case letters are capitals)")


def prg_strings(path):
    """line number -> list of the line's strings (bytes), up to rem"""
    p = open(path, 'rb').read()
    out = {}
    i = 2
    while i + 4 <= len(p) and (p[i] or p[i + 1]):
        num = p[i + 2] | p[i + 3] << 8
        i += 4
        segs = []
        cur = None
        rem = False
        while p[i]:
            c = p[i]
            if not rem:
                if cur is not None:
                    if c == 0x22:
                        segs.append(bytes(cur))
                        cur = None
                    else:
                        cur.append(c)
                elif c == 0x22:
                    cur = bytearray()
                elif c == REM:
                    rem = True
            i += 1
        if cur is not None:
            segs.append(bytes(cur))
        out[num] = segs
        i += 1
    return out


def is_letter(c):
    return 0x41 <= c <= 0x5A or 0x61 <= c <= 0x7A


def raw(b):
    """how to write byte b in a string under {alpha:ascii}"""
    if 0x41 <= b <= 0x5A or 0x61 <= b <= 0x7A:
        return bytes([b])
    return b'{$%02x}' % b


def fix_line(line, segs):
    """line: bytes, without the line end. Returns the line written for
    {alpha:ascii}, or None if it doesn't need it (or doesn't line up)"""
    if not any(0x61 <= b <= 0x7A for s in segs for b in s):
        return None
    m = re.match(rb'\s*\d+', line)
    if not m:
        return None
    out = bytearray(line[:m.end()])
    i = m.end()
    k = 0
    while i < len(line):
        c = line[i]
        if c == 0x22:
            if k >= len(segs):
                return None
            seg = segs[k]
            k += 1
            out.append(c)
            i += 1
            j = 0
            while i < len(line) and line[i] != 0x22:
                t = TOKEN.match(line, i)
                if t:
                    out += t.group(0)
                    i = t.end()
                    j += int(t.group(2)) if t.group(2) else 1
                    continue
                if j >= len(seg):
                    return None
                ch, b = line[i], seg[j]
                if is_letter(ch) and (is_letter(b) or 0xC1 <= b <= 0xDA) and b & 0x1F == ch & 0x1F:
                    out += raw(b)           # a letter: the original's byte
                else:
                    out.append(ch)
                i += 1
                j += 1
            if j != len(seg):
                return None
            if i < len(line):
                out.append(line[i])
                i += 1
            continue
        if line[i:i + 3].lower() == b'rem':
            out += line[i:]
            break
        out.append(c)
        i += 1
    if k != len(segs):
        return None
    return bytes(out)


def main():
    segs = prg_strings(sys.argv[1])
    out = []
    for line in sys.stdin.buffer.read().split(b'\n'):
        cr = b'\r' if line.endswith(b'\r') else b''
        body = line[:-1] if cr else line
        m = re.match(rb'\s*(\d+)', body)
        new = fix_line(body, segs[int(m.group(1))]) if m and int(m.group(1)) in segs else None
        if new is None:
            out.append(line)
        else:
            out += [n + cr for n in NOTE] + [b'{alpha:ascii}' + cr, new + cr, b'{alpha:alt}' + cr]
    sys.stdout.buffer.write(b'\n'.join(out))


if __name__ == '__main__':
    main()
