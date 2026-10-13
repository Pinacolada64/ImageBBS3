# Asciidoctor PDF extension: keep table headings, and short values, on one
# line.
#
# Prawn shares a table's width out between its columns by their contents,
# and when it has to squeeze a table it will shrink a column down to one
# character, so a short heading like "Range" or "Function" wraps, even
# mid-word, and so does a value like "$42f2". After Prawn has worked out the
# column widths (from cols= or from the contents), this widens any column
# that's too narrow for its heading or for its longest short value (a body
# cell with no spaces, up to SHORT_VALUE_MAX points wide), taking the
# difference from the columns with the most room to spare. If a table can't
# fit both, only its headings are kept on one line; if it can't fit even
# those, it's left as it was.
#
# Loaded by "make pdf" (asciidoctor -r ./extensions/table-heading-widths.rb).

require 'prawn/table'

module ImageBBSTableHeadingWidths
  # widest body value (in points, without padding) still kept on one line
  SHORT_VALUE_MAX = 100

  def column_widths
    return @column_widths if @heading_widths_fitted
    widths = super.dup
    @heading_widths_fitted = true
    rows = number_of_header_rows

    heading = Array.new(widths.size, 0.0)
    short = Array.new(widths.size, 0.0)
    cells.each do |c|
      next unless c.is_a?(Prawn::Table::Cell::Text) && c.colspan == 1
      text = c.content.to_s.gsub(/<[^>]*>/, '')
      if c.row < rows
        width = heading
      elsif text =~ /[ \t\n]/ || text.empty?
        next
      else
        width = short
      end
      w = c.natural_content_width
      next if width.equal?(short) && w > SHORT_VALUE_MAX
      n = w + c.padding_left + c.padding_right
      width[c.column] = n if n > width[c.column]
    end

    need = heading.each_index.map { |i| [heading[i], short[i]].max }
    need = heading if need.sum > widths.sum
    return @column_widths = widths if need.sum > widths.sum

    fit(widths, need)
    @column_widths = widths
  end

  private

  # widen each column to need[i], taking from the columns with most to spare
  def fit(widths, need)
    widths.each_index do |i|
      short = need[i] - widths[i]
      while short > 0.01
        donor = (widths.each_index.to_a - [i]).max_by { |k| widths[k] - need[k] }
        spare = widths[donor] - need[donor]
        break unless donor && spare > 0.01
        take = [short, spare].min
        widths[donor] -= take
        widths[i] += take
        short -= take
      end
    end
  end
end

Prawn::Table.prepend ImageBBSTableHeadingWidths
