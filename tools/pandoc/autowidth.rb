# Asciidoctor extension for the lualatex PDFs (make lua-pdf): DocBook has no
# autowidth, so asciidoctor gives a [%autowidth] table's columns equal widths.
# This blanks them instead (colwidth="*"), which pandoc reads as "no width",
# and tools/pandoc/docbook-latex.lua sizes those columns by their contents.
#
# Loaded by "make lua-pdf" (asciidoctor -r ../tools/pandoc/autowidth.rb).

Asciidoctor::Extensions.register do
  treeprocessor do
    process do |doc|
      doc.find_by(context: :table, traverse_documents: true) {|t| t.option? 'autowidth' }.each do |table|
        table.columns.each do |col|
          col.set_attr 'colpcwidth', ''
          col.set_attr 'colabswidth', ''
        end
      end
      nil
    end
  end
end
