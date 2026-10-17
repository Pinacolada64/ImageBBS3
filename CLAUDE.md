# Image BBS 3.0: notes for Claude

## BASIC listings (`.lbl`)

### Every buildable `.lbl` uses `{alpha:alt}`

Without it, C64List builds ASCII capitals as PETSCII `$41`-`$5A`, which show as
lowercase on the C64 and don't match keypress tests such as `an$="C"` the way
the release does (`$C1`-`$DA`). Put `{alpha:alt}` after a new file's header
comments. Not in include-only files (`3_0-preface.lbl`, `quoters.lbl`).

### Detokenizing a `.prg`: space it out for reading

Import BASIC programs with `tools/detok.sh` in its default mode, which
spaces out keywords (C64List `-autospace`: `gosub 3001:goto 300`, not
`gosub3001:goto300`) and adds `{crunch:on}` so the build takes the spaces
out again. Don't use `--keep-spaces` just to get past the rebuild check: if
the original has its own spaces in code, `detok.sh` accepts the listing, says
how many lines differ, and notes in the header that the rebuilt program runs
the same but isn't byte-for-byte identical. Say so when reporting the import.
Use `--keep-spaces` only when the original's exact bytes matter.

### Capital letters in `rem` text: use ASCII, not PETSCII bytes

C64List (`-txt -alpha:alt`, as used by `tools/detok.sh`) copies text after `rem` byte for
byte, so shifted PETSCII capitals (`$C1`-`$DA`) land in the `.lbl` as raw
bytes, which editors show as unknown/invalid characters. In code (strings
outside a `rem`), C64List already writes them as ASCII capitals.

`tools/detok.sh` now does this conversion itself on import. When editing an
older `.lbl` file, or one imported some other way, convert every raw byte `$C1`-`$DA`
in `rem` text to the ASCII capital `A`-`Z` (subtract `$80`), whether or not the
`rem` text is in quotes. Only do this in files that use `{alpha:alt}` (as
`detok.sh` output does): without it, C64List builds an ASCII capital in a `rem`
as `$41`-`$5A`, which shows as a lowercase letter. Leave other non-ASCII bytes alone: they're control
codes, which should become C64List `{...}` tokens if anything.

Effect on the built program: C64List tokenizes ASCII capitals after `rem` as
PETSCII `$61`-`$7A` (not `$C1`-`$DA`). Both display as capitals in
lower/upper case mode, and a `rem` doesn't run, so the program works the same;
but those bytes no longer match the original, so a converted file is no longer
"byte-for-byte identical" to the release. Say so when reporting a rebuild.

Use `{pound}`, not `£`, in BASIC code.

### Symbols in `&"..."` output strings: use the quoter tokens

For readability, write these symbols in strings printed with `&` as the
tokens defined in `core/quoters.lbl`, and include that file after
`{alpha:alt}` (`{include:quoters.lbl}`, or `{include:../quoters.lbl}` from
`core/tests/`):

| Symbol | Token |
|---|---|
| `,` | `{comma}` |
| `:` | `{colon}` |
| `"` | `{quotation}` |
| `*` | `{asterisk}` |
| `?` | `{question}` |
| `=` | `{equal}` |
| `^` | `{up_arrow}` |

Each token builds as an encoded f-key byte (`$85`-`$8C`), which `&` output
turns back into the symbol. That also goes for text assigned to a variable
that is only ever printed with `&` (e.g. `a$=a$+"{comma} hidden"`). Leave the
plain symbol in strings that are compared, used as filenames, sent to the disk,
or printed some other way, because the bytes differ.

### Variables in `&"..."` output strings: use MCI

To print a single-letter variable in an `&` string, use MCI instead of
`str$()`: `{pound}%u` for `u%`, `{pound}!x` for `x`, `{pound}$z` for `z$`
(e.g. `&"User {pound}%u's list"`, not `&"User"+str$(u%)+"'s list"`). MCI
reads just one letter after the command, so this only works for one-letter
names, and it prints no leading space as `str$()` does.

## Documentation (`docs/`)

### Link every `&,xx` mention to its section, with the call's name

In the manuals, write a mention of an `&` call as a cross-reference to the
section that documents it, with the call's name, as most mentions already
are: `<<position-cursor,`&,70` Position Terminal Cursor>>`. The target is
the anchor on the call's heading in `prg-ampersand-calls.adoc`
(`=== `&,70` Position Terminal Cursor [[position-cursor]]`), or Asciidoctor's
automatic ID for a heading without one (`_15_4` for `&,15,4`); add an anchor
if neither fits. From another file, name the file:
`<<prg-structures.adoc#scan-for-string,`&,60,11` Scan for String>>`.
Leave `&,xx` bare in code (listings and code spans of BASIC), in the call's
own heading, and when the same call comes up again in the same paragraph.
