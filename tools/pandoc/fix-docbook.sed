# sed script for the lualatex PDFs (make lua-pdf): fixes up the DocBook that
# asciidoctor makes from the manuals, for things pandoc's reader drops.

# an anchor inside a code span ([[line-74]] in a `...` column): pandoc
# flattens <literal> to plain text, so move the anchor in front of it
s|<literal>((<anchor [^>]*/>)+)|\1<literal>|g

# pandoc ignores the ID of a table or a titled listing (formalpara): put it
# on an anchor in front
s|<(table\|informaltable\|formalpara) xml:id="([^"]*)"|<simpara><anchor xml:id="\2"/></simpara><\1|g
