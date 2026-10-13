# CONTRIBUTING.md

This documentation is written in an extended form of markdown called ASCIIdoc. Home page: https://asciidoctor.org/

The markdown editor used is AsciiDocFX. Home page: https://asciidocfx.com/

A single file with (admittedly slightly esoteric) markup can generate multiple output formats.

It's suggested you generate the `.html` version (which I think looks the best right now, until I figure out nicer looking PDF stylesheets).

I plan on using sections from the Image 1.2b and 2.0 documentation to save some effort. Still learning about ASCIIdoc, pull requests encouraged!

## Building

From the top of the repository, `make pdf` builds the Programmer's Reference Guide as `build/prg-master.pdf`.
It needs the `asciidoctor-pdf` and `asciidoctor-lists` gems.

Or, from `docs/`: `asciidoctor-pdf prg-master.adoc`

### Table headings

`extensions/table-heading-widths.rb` keeps table headings, and short values like `$42f2` or `&,16,255`, on one line: Prawn, which lays out the PDF's tables, will otherwise squeeze a column down to one character, so a heading like "`Function`" wraps mid-word.
A value counts as short if it has no spaces and is up to 100 points wide; if a table is too narrow for all of them, only its headings are kept whole.
`make pdf` loads it; building by hand, add `-r ./extensions/table-heading-widths.rb`.

### Syntax highlighting

BASIC listings are colored by Pygments, through the `pygments.rb` gem (`gem install --user-install pygments.rb`; Python Pygments must be installed too).
Without the gem the guide still builds, just without colors.

Listings use `[source,imagebasic]` (the default in `prg-master.adoc`): `tools/pygments/imagebbs_lexer.py`, Pygments' CBM BASIC V2 lexer plus `&` calls, `$hex` and `%binary` numbers, and C64List's `{...}` tokens and `'` comments.
`make pdf` finds it by setting `PYTHONPATH` to `tools/pygments`; building by hand, do the same:

`PYTHONPATH=../tools/pygments asciidoctor-pdf prg-master.adoc`

### Theming the PDF

`asciidoctor-pdf -a pdf-theme=basic prg-master.adoc`

## PDF Theme Examples

https://github.com/asciidoctor/asciidoctor-pdf/tree/main/examples
