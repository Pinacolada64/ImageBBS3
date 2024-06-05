# CONTRIBUTING.md

This documentation is written in an extended form of markdown called ASCIIdoc. Home page: https://asciidoctor.org/

The markdown editor used is AsciiDocFX. Home page: https://asciidocfx.com/

A single file with (admittedly slightly esoteric) markup can generate multiple output formats.

It's suggested you generate the `.html` version (which I think looks the best right now, until I figure out nicer looking PDF stylesheets).

I plan on using sections from the Image 1.2b and 2.0 documentation to save some effort. Still learning about ASCIIdoc, pull requests encouraged!

## Building

`asciidoctor-pdf prg-master.adoc`

### Theming the PDF

`asciidoctor-pdf -a pdf-theme=basic prg-master.adoc`

## PDF Theme Examples

https://github.com/asciidoctor/asciidoctor-pdf/tree/main/examples
