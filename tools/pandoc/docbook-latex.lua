-- pandoc filter for the lualatex PDFs (make lua-pdf): fixes up the DocBook
-- that asciidoctor makes from the manuals before pandoc turns it into LaTeX.

-- icon:name[] comes through as an image of images/icons/name.png, which
-- doesn't exist; use a symbol instead
local icons = {
  check = '\\textcolor{green!50!black}{✔}',
  ['times-circle'] = '\\textcolor{red!75!black}{✖}',
  question = '\\textcolor{blue!75!black}{?}',
  bug = '🐛',
}

function Image(img)
  local name = img.src:match('images/icons/([%w-]+)%.png$')
  if name then
    return pandoc.RawInline('latex', icons[name] or name)
  end
end

-- longtable can't nest, so a table inside a table cell (an a| cell in
-- AsciiDoc) becomes a plain tabular: no caption, no repeated header
local function to_tabular(tbl)
  tbl = tbl:walk({ Image = Image, Div = Div })
  local tex = pandoc.write(pandoc.Pandoc({tbl}), 'latex')
  tex = tex:gsub('\\begin{longtable}%[%]', '\\begin{tabular}')
           :gsub('\\end{longtable}', '\\bottomrule\\noalign{}\n\\end{tabular}')
           :gsub('\\caption.-\\tabularnewline\n', '')
           :gsub('\\endfirsthead.-\\endhead\n', '')
           :gsub('\\endhead\n', '')
           :gsub('\\bottomrule\\noalign{}\n\\endlastfoot\n', '')
           :gsub('\\columnwidth', '\\linewidth')
  return pandoc.RawBlock('latex', tex)
end

-- Column widths for a table with none given (an [%autowidth] table: see
-- autowidth.rb), from its contents, as a browser lays out an auto-width
-- table: if every column fits on one line, each gets its natural width (the
-- table can be narrower than the page); otherwise each gets at least its
-- longest word, and the room left over goes to the columns in proportion
-- to how much more they'd need to fit. Widths are estimated from character
-- counts, in ems of the 10pt body font.

local TEXT_WIDTH = 45.0   -- A4 less 1in margins: 450.7pt
local TABCOLSEP = 0.6     -- 6pt each side of a column
local EM_TEXT = 0.5       -- average character in Latin Modern Roman
local EM_CODE = 0.525     -- every character in Latin Modern Mono

local measure_blocks

-- natural (one-line) and minimum (longest word) width of some inlines
local function measure_inlines(inlines)
  local lines, line, word, min = {}, 0, 0, 0
  local function end_word() min = math.max(min, word); word = 0 end
  local function end_line() end_word(); lines[#lines + 1] = line; line = 0 end
  local function add(text, em)
    for _, c in utf8.codes(text) do
      if c == 32 then end_word() else word = word + em end
      line = line + em
    end
  end
  pandoc.Inlines(inlines):walk({
    Str = function(s) add(s.text, EM_TEXT) end,
    Code = function(c) add(c.text, EM_CODE) end,
    Space = function() add(' ', EM_TEXT) end,
    SoftBreak = function() add(' ', EM_TEXT) end,
    LineBreak = end_line,
  })
  end_line()
  return math.max(table.unpack(lines)), min
end

local function cells(tbl)
  local rows = {}
  for _, r in ipairs(tbl.head.rows) do rows[#rows + 1] = r end
  for _, body in ipairs(tbl.bodies) do
    for _, r in ipairs(body.head) do rows[#rows + 1] = r end
    for _, r in ipairs(body.body) do rows[#rows + 1] = r end
  end
  for _, r in ipairs(tbl.foot.rows) do rows[#rows + 1] = r end
  local result = {}
  for _, row in ipairs(rows) do
    local col = 1
    for _, cell in ipairs(row.cells) do
      result[#result + 1] = { col = col, cell = cell }
      col = col + cell.col_span
    end
  end
  return result
end

-- natural and minimum widths of each column
local function measure_columns(tbl)
  local nat, min = {}, {}
  for i = 1, #tbl.colspecs do nat[i], min[i] = 0, 0 end
  for _, c in ipairs(cells(tbl)) do
    if c.cell.col_span == 1 then
      local n, m = measure_blocks(c.cell.contents)
      nat[c.col] = math.max(nat[c.col], n)
      min[c.col] = math.max(min[c.col], m)
    end
  end
  return nat, min
end

function measure_blocks(blocks)
  local nat, min = 0, 0
  for _, b in ipairs(blocks) do
    local n, m = 0, 0
    if b.t == 'Para' or b.t == 'Plain' then
      n, m = measure_inlines(b.content)
    elseif b.t == 'CodeBlock' then
      for line in (b.text .. '\n'):gmatch('(.-)\n') do
        n = math.max(n, utf8.len(line) * EM_CODE)
      end
      m = n
    elseif b.t == 'Table' then
      local ns, ms = measure_columns(b)
      local pad = 2 * TABCOLSEP * (#ns - 1)
      for i = 1, #ns do n, m = n + ns[i], m + ms[i] end
      n, m = n + pad, m + pad
    elseif b.content then
      n, m = measure_blocks(b.content)
    end
    nat, min = math.max(nat, n), math.max(min, m)
  end
  return nat, min
end

-- set widths on a table with none, for a table width of `width` ems
local function fit_columns(tbl, width)
  for _, spec in ipairs(tbl.colspecs) do
    if spec[2] then return end
  end
  local nat, min = measure_columns(tbl)
  local room = width - 2 * TABCOLSEP * (#nat - 1)
  local total_nat, total_min = 0, 0
  for i = 1, #nat do
    nat[i] = math.max(nat[i], 1)
    min[i] = math.min(math.max(min[i], 1), nat[i])
    total_nat, total_min = total_nat + nat[i], total_min + min[i]
  end
  local widths = {}
  for i = 1, #nat do
    if total_nat <= room then
      widths[i] = nat[i]
    elseif total_min >= room then
      widths[i] = min[i] * room / total_min
    else
      widths[i] = min[i] + (nat[i] - min[i]) * (room - total_min) / (total_nat - total_min)
    end
  end
  for i, spec in ipairs(tbl.colspecs) do
    tbl.colspecs[i] = { spec[1], widths[i] / room }
  end
end

-- size a table's columns, then any tables inside its cells for the width of
-- the cell, and make those plain tabulars
local function fit_table(tbl, width, nested)
  fit_columns(tbl, width)
  local room = width - 2 * TABCOLSEP * (#tbl.colspecs - 1)
  for _, c in ipairs(cells(tbl)) do
    local w = 0
    for i = c.col, c.col + c.cell.col_span - 1 do
      w = w + (tbl.colspecs[i][2] or 1 / #tbl.colspecs) * room
    end
    w = w + 2 * TABCOLSEP * (c.cell.col_span - 1)
    c.cell.contents = c.cell.contents:walk({
      Table = function(inner) return fit_table(inner, w, true), false end,
      traverse = 'topdown',
    })
  end
  if nested then return to_tabular(tbl) end
  return tbl
end

function Table(tbl)
  return fit_table(tbl, TEXT_WIDTH, false)
end

-- outer tables first, so that a table in a cell is sized for the cell
traverse = 'topdown'

-- admonitions (NOTE: and so on) come through as a bare Div: start them with
-- their label, in bold, and the block's title if it has one
local admonitions = {
  note = 'Note', tip = 'Tip', important = 'Important',
  warning = 'Warning', caution = 'Caution',
}

function Div(div)
  local label = admonitions[div.classes[1]]
  if not label then return end
  local blocks = div.content
  local title = blocks[1]
  if title and title.t == 'Div' and title.classes:includes('title') then
    blocks:remove(1)
    label = label .. ': ' .. pandoc.utils.stringify(title)
  end
  blocks:insert(1, pandoc.Para({pandoc.Strong(label)}))
  return pandoc.BlockQuote(blocks)
end

-- pandoc writes a cross-reference to an appendix (<xref> with no text) as
-- "appendix_title": use the appendix's heading instead
function Pandoc(doc)
  local titles = {}
  doc:walk({ Header = function(h) titles[h.identifier] = h.content end })
  return doc:walk({ Link = function(link)
    local id = link.target:match('^#(.+)')
    if id and titles[id] and pandoc.utils.stringify(link.content) == 'appendix_title' then
      link.content = titles[id]
      return link
    end
  end })
end
