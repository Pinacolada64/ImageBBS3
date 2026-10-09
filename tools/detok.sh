#!/bin/bash
# detok.sh: turn a tokenized BASIC module into a readable .lbl listing
#
#   tools/detok.sh "<C64 filename>" <out.lbl>   take the file from the release disk
#   tools/detok.sh <file.prg> <out.lbl>          or from a .prg file
#
#   e.g. tools/detok.sh "i/MM.load" core/i_MM.load.lbl
#
# The listing keeps the original line numbers, and is spaced out for reading
# (C64List -autospace). It starts with {uses:3_0-preface.lbl} so jumps into im
# resolve, {alpha:alt}, and {crunch:on} so the build removes the added spaces
# again (the Makefile passes -crunch for files using {crunch:on}).
#
# Shifted PETSCII capitals ($c1-$da) in rem text are copied by C64List as raw
# bytes, which editors can't show; they're converted to ASCII A-Z. C64List
# builds those as $61-$7a, which also look like capitals in lower/upper case
# mode, so the rebuilt rems differ from the original in those bytes only.
#
# Afterwards, the listing is built again and compared with the original (with
# the same rem capitals changed to $61-$7a): the script fails unless the two
# are byte-for-byte identical, or differ only by trailing ":"s, which C64List's
# -crunch removes.
#
# Environment (defaults as in the Makefile): C64LIST, WINE, C1541, RELEASE_ZIP,
# RELEASE_D81

set -euo pipefail

C64LIST=${C64LIST:-$HOME/bin/c64list4_04.exe}
WINE=${WINE:-wine}
C1541=${C1541:-c1541}
RELEASE_ZIP=${RELEASE_ZIP:-$HOME/Documents/c64/image30-231231.zip}
RELEASE_D81=${RELEASE_D81:-MASTER D1 231231.d81}

if [ $# -ne 2 ]; then
	echo "usage: $0 \"<C64 filename>\"|<file.prg> <out.lbl>" >&2
	exit 2
fi
src=$1
out=$2
[ -e "$out" ] && { echo "$out already exists; not overwriting it" >&2; exit 1; }

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

c64list() { (cd "$tmp" && WINEDEBUG=-all "$WINE" "$C64LIST" "$@" -ovr); }

# -autospace puts a space before each ":"; turn " :" into ":" in program code,
# but not inside "quoted strings" or after rem, where it would change the text.
# In rem text, also turn PETSCII capitals ($c1-$da) into ASCII A-Z.
tidy_listing() {
	python3 -I -c '
import sys
for line in sys.stdin.buffer:
    out = bytearray(); quoted = False; i = 0
    while i < len(line):
        c = line[i]
        if not quoted and line[i:i+3].lower() == b"rem":
            out += bytes(b - 0x80 if 0xc1 <= b <= 0xda else b for b in line[i:]); break
        if c == 0x22:
            quoted = not quoted
        if not quoted and c == 0x20 and line[i+1:i+2] == b":":
            i += 1; continue
        if c in (0x0d, 0x0a):
            quoted = False
        out.append(c); i += 1
    sys.stdout.buffer.write(bytes(out))
'
}

# 1. get the tokenized program
if [ -f "$src" ]; then
	cp "$src" "$tmp/orig.prg"
	origin="$(basename "$src")"
else
	unzip -p "$RELEASE_ZIP" "$RELEASE_D81" > "$tmp/release.d81"
	"$C1541" -attach "$tmp/release.d81" -read "$src" "$tmp/orig.prg" > /dev/null 2>&1 \
		|| { echo "\"$src\" not found on $RELEASE_D81" >&2; exit 1; }
	origin="the release disk ($RELEASE_D81), \"$src\""
fi

# 2. detokenize: C64List writes jumps to lines outside this file as [n];
#    the brackets would be kept as text when tokenizing, so remove them
c64list orig.prg -txt:orig.txt -autospace -keycase -varcase -alpha:alt > "$tmp/detok.log" 2>&1 \
	|| { cat "$tmp/detok.log" >&2; exit 1; }

{
	printf '%s\r\n' \
		"' imported from $origin with:" \
		"'   tools/detok.sh (C64List4_04.exe -txt -autospace -keycase -varcase -alpha:alt)" \
		"' line numbers are kept as they were; jumps to lines in im (gosub 3, goto 5, ...)" \
		"' resolve through 3_0-preface.lbl. unchanged, this builds a program identical" \
		"' to the original, except that capitals in rem text are \$61-\$7a, not \$c1-\$da." \
		"" \
		"{uses:3_0-preface.lbl}" \
		"{alpha:alt}" \
		"{crunch:on}" \
		""
	sed -E 's/\[([0-9]+)\]/\1/g' "$tmp/orig.txt" | tidy_listing
} > "$tmp/new.lbl"

# the original, with capitals in rem text changed the way C64List builds them
# ($c1-$da -> $61-$7a); prints how many were changed
remcaps() {
	python3 -I -c '
import sys
src, dst = sys.argv[1], sys.argv[2]
p = bytearray(open(src, "rb").read()); i = 2; n = 0
while i + 4 <= len(p) and (p[i] or p[i+1]):
    i += 4; quoted = rem = False
    while p[i]:
        c = p[i]
        if rem:
            if 0xc1 <= c <= 0xda:
                p[i] = c - 0x60; n += 1
        elif c == 0x22:
            quoted = not quoted
        elif c == 0x8f and not quoted:
            rem = True
        i += 1
    i += 1
open(dst, "wb").write(p); print(n)
' "$1" "$2"
}

# 3. build it again and compare
cp "$repo/core/3_0-preface.lbl" "$tmp/"
c64list new.lbl -prg:new.prg -crunch > "$tmp/build.log" 2>&1 \
	|| { cat "$tmp/build.log" >&2; exit 1; }
# C64List's -crunch drops a line's trailing ":" (an empty statement), which
# shifts every later byte. If that is the only difference (compared as
# listings, with trailing colons ignored), the program still behaves the same.
caps=$(remcaps "$tmp/orig.prg" "$tmp/want.prg")
same="rebuilds byte-for-byte identical"
if ! cmp -s "$tmp/want.prg" "$tmp/new.prg"; then
	listing() { petcat -2 -o /dev/stdout -- "$1" 2> /dev/null; }
	if ! command -v petcat > /dev/null \
		|| ! diff -q <(listing "$tmp/want.prg" | sed 's/:*$//') \
			<(listing "$tmp/new.prg" | sed 's/:*$//') > /dev/null; then
		echo "The listing doesn't rebuild identically ($(cmp -l "$tmp/want.prg" "$tmp/new.prg" 2>/dev/null | wc -l) bytes differ); not writing $out" >&2
		exit 1
	fi
	n=$(diff <(listing "$tmp/want.prg") <(listing "$tmp/new.prg") | grep -c '^<' || true)
	same="rebuilds identically except for $n trailing \":\" removed by -crunch"
fi
[ "$caps" -gt 0 ] && same="$caps capitals in rem text converted to ASCII; otherwise $same"

cp "$tmp/new.lbl" "$out"
echo "$out: $(grep -c '' "$out") lines; $same"
