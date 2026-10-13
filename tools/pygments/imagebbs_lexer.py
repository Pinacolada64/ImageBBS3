"""Pygments lexer and style for Image BBS BASIC listings.

The lexer is "imagebasic"; the style, "imagebbs", is Manni with C64List
control tokens inside strings ({f6}, {white}, {clear}...) in reverse field,
as a C64 shows control codes in quote mode.


CBM BASIC V2 (Pygments' "cbmbas" lexer) plus what Image BBS listings use:
& calls, $hex and %binary numbers, the st/ti/ti$ variables, and C64List's
{...} tokens outside strings ({:label}, {f6}), [28]-style line references
and ' comment lines. Without these, cbmbas marks every & as an error.
Inside a string, a C64List token for a control code is String.Escape (shown
reversed by the imagebbs style); one for a printable character ({pound},
spaces, graphics, {$41}) is part of the string.

The Programmer's Reference Guide build finds it through PYTHONPATH (see the
Makefile's pdf target): imagebbs_lexer-1.0.dist-info registers it as a
Pygments plugin, so nothing has to be installed.
"""

from pygments.lexer import inherit
from pygments.lexers.basic import CbmBasicV2Lexer
from pygments.styles.manni import ManniStyle
from pygments.token import Comment, Keyword, Name, Number, String, Whitespace

# C64List tokens for printable characters: not shown reversed
PRINTABLE = (r'\{(pound|space|\d+ spaces|up ?arrow|back ?arrow|pi|'
             r'(shift|sh|cbm)[- ][^}]*|'
             r'\$([2-7][0-9a-f]|[a-f][0-9a-f]))(:\d+)?\}')


class ImageBasicLexer(CbmBasicV2Lexer):
    name = 'Image BBS BASIC'
    aliases = ['imagebasic']
    filenames = ['*.lbl']

    tokens = {
        'root': [
            (r'"', String, 'string'),
            (r"'.*\n", Comment.Single),         # C64List comment line
            (r'[&?]', Keyword.Reserved),         # & call, ? (print)
            (r'\$[0-9a-f]+', Number.Hex),        # $c000
            (r'%[01]+', Number.Bin),             # %1100
            (r'(ti\$?|st)(?![\w$%])', Name.Builtin),
            (r'\{[^}\n]*\}', Name.Label),        # C64List {:label}, {f6}
            (r'\[\d+\]', Name.Label),            # [28]
            inherit,
        ],
        'string': [
            (PRINTABLE, String),
            (r'\{[^}\n]*\}', String.Escape),   # control code: reversed
            (r'[^"{\n]+', String),
            (r'\{', String),
            (r'"', String, '#pop'),
            (r'\n', Whitespace, '#pop'),        # string left open at line end
        ],
    }


class ImageBBSStyle(ManniStyle):
    """Manni, with control codes in strings white on C64 blue."""
    name = 'imagebbs'
    styles = dict(ManniStyle.styles)
    styles[String.Escape] = 'bg:#40318d #ffffff'
