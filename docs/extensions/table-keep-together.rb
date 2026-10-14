# Asciidoctor PDF extension: don't split a table across pages if it fits
# on one.
#
# Prawn only moves a table to the next page when not even its header and
# first row fit, so a short table could leave its title, header and a row
# at the bottom of a page and the rest on the next. This makes every table
# unbreakable (as [%unbreakable] would): one that doesn't fit in the space
# left starts on the next page. Asciidoctor PDF treats an unbreakable block
# taller than a page as breakable, so a long table still starts where it
# is, its title kept with its first rows. [%breakable] on a table turns this
# off; tables nested in a cell are left alone.
#
# Loaded by "make pdf" (asciidoctor -r ./extensions/table-keep-together.rb).

require 'asciidoctor/pdf'

module ImageBBSTableKeepTogether
  def convert_table node
    # the copy Asciidoctor PDF wraps an unbreakable table in comes back here
    # with its option removed; the marker (copied with it) leaves it alone
    unless (node.attr? 'keep-together-checked') || node.document.nested? ||
        (node.option? 'breakable') || (node.option? 'unbreakable')
      node.set_attr 'keep-together-checked', ''
      node.set_option 'unbreakable'
    end
    super
  end
end

Asciidoctor::PDF::Converter.prepend ImageBBSTableKeepTogether
